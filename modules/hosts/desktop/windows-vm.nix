{
  den.aspects.desktop.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hook = pkgs.writeShellApplication {
        name = "windows-gaming-gpu-hook";
        runtimeInputs = with pkgs; [
          python3
          systemd
          kmod
          psmisc
          libvirt
        ];
        text = ''
          exec python3 ${./windows-vm/gpu-hook.py} "$@"
        '';
      };
      domain = pkgs.runCommand "windows-gaming.xml" { nativeBuildInputs = [ pkgs.libvirt ]; } ''
        substitute ${./windows-vm/domain.xml} "$out" \
          --replace-fail @FIRMWARE@ ${pkgs.OVMFFull.firmware} \
          --replace-fail @VARIABLES@ ${pkgs.OVMFFull.variablesMs}
        virt-xml-validate "$out" domain
      '';
      setup = pkgs.writeShellApplication {
        name = "windows-vm-setup";
        runtimeInputs = with pkgs; [
          libvirt
          qemu
          coreutils
          gnugrep
        ];
        text = ''
          if (( EUID != 0 )) || (( $# != 0 )); then
            echo 'Usage: sudo windows-vm-setup' >&2
            exit 1
          fi
          umask 077
          vm=windows-gaming
          uri=qemu:///system
          active=$(virsh --connect "$uri" list --name)
          if grep -Fxq "$vm" <<< "$active"; then
            echo 'Shut down Windows before changing its definition.' >&2
            exit 1
          fi
          domains=$(virsh --connect "$uri" list --all --name)
          if grep -Fxq "$vm" <<< "$domains"; then
            if [[ "$(virsh --connect "$uri" domuuid "$vm")" != 9ed40d76-ad6e-4080-b345-6d7d2aece0a1 ]]; then
              echo 'An unrelated VM uses this name; refusing to overwrite it.' >&2
              exit 1
            fi
            info=$(LC_ALL=C virsh --connect "$uri" dominfo "$vm")
            if ! grep -Eq '^Managed save: +no$' <<< "$info"; then
              echo 'Cannot confirm absence of saved memory state; resume and shut down the VM first.' >&2
              exit 1
            fi
            backup=/var/lib/libvirt/windows-gaming-original.xml
            if [[ ! -e "$backup" ]]; then
              temporary=$(mktemp /var/lib/libvirt/windows-gaming-original.XXXXXX.xml)
              trap 'rm -f "$temporary"' EXIT
              virsh --connect "$uri" dumpxml --inactive "$vm" > "$temporary"
              mv -n "$temporary" "$backup"
            fi
          fi
          disk=/var/lib/libvirt/images/windows-gaming.qcow2
          install -d -m 0755 /var/lib/libvirt/images
          if [[ ! -e "$disk" ]]; then
            temporary=$(mktemp /var/lib/libvirt/images/windows-gaming.XXXXXX.qcow2)
            trap 'rm -f "$temporary"' EXIT
            qemu-img create -f qcow2 -o preallocation=metadata "$temporary" 256G
            chown qemu-libvirtd:qemu-libvirtd "$temporary"
            chmod 0600 "$temporary"
            mv -n "$temporary" "$disk"
          fi
          for media in windows.iso virtio-win.iso; do
            if [[ ! -r "/var/lib/libvirt/images/$media" ]]; then
              echo "Place the local installation ISO at /var/lib/libvirt/images/$media first." >&2
              exit 1
            fi
          done
          virsh --connect "$uri" net-info default >/dev/null
          virsh --connect "$uri" net-autostart default
          networks=$(virsh --connect "$uri" net-list --name)
          if ! grep -Fxq default <<< "$networks"; then
            virsh --connect "$uri" net-start default
          fi
          virsh --connect "$uri" define --validate /etc/libvirt/windows-gaming.xml
          virsh --connect "$uri" autostart --disable "$vm"
          echo 'Windows VM configured; disk, TPM and existing NVRAM preserved.'
          echo 'Save your work, then run windows-vm-start to hand off the GPU.'
        '';
      };
      start = pkgs.writeShellApplication {
        name = "windows-vm-start";
        runtimeInputs = [ pkgs.systemd ];
        text = ''
          if (( $# != 0 )); then
            echo 'Usage: windows-vm-start' >&2
            exit 1
          fi
          if (( EUID != 0 )); then
            exec ${config.security.wrapperDir}/sudo /run/current-system/sw/bin/windows-vm-start
          fi
          echo 'This closes local graphical sessions and their user services, including unsaved work.'
          echo 'The login screen returns after Windows shuts down. Save your work first.'
          read -r -p 'Type start to continue: ' response
          [[ "$response" == start ]] || exit 1
          # Survive the originating terminal and user manager being stopped by the hook.
          systemd-run --unit=windows-gaming-start --collect --no-block \
            ${pkgs.libvirt}/bin/virsh --connect qemu:///system start windows-gaming
          echo 'Start queued. Errors: journalctl -u windows-gaming-start -u libvirtd'
        '';
      };
      recover = pkgs.writeShellApplication {
        name = "windows-vm-recover";
        text = ''
          if (( EUID != 0 )) || (( $# != 0 )); then
            echo 'Usage: sudo windows-vm-recover' >&2
            exit 1
          fi
          exec ${hook}/bin/windows-gaming-gpu-hook recover
        '';
      };
    in
    {
      virtualisation.libvirtd = {

        hooks.qemu."50-windows-gaming" = "${hook}/bin/windows-gaming-gpu-hook";
        onBoot = "ignore";
        onShutdown = "shutdown";
      };

      # The config oneshot installs hooks; a running daemon otherwise keeps its old hook cache.
      systemd.services.libvirtd = {
        restartIfChanged = lib.mkForce true;
        restartTriggers = [ hook ];
      };

      environment.etc."libvirt/windows-gaming.xml".source = domain;
      environment.systemPackages = [
        setup
        start
        recover
        (pkgs.makeDesktopItem {
          name = "windows-gaming";
          desktopName = "Windows 11 (GPU passthrough)";
          exec = "${start}/bin/windows-vm-start";
          icon = "computer";
          terminal = true;
          categories = [ "System" ];
        })
      ];
    };
}
