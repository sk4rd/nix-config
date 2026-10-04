{ self, ... }:

{
  perSystem =
    { pkgs, ... }:
    let
      desktop = self.nixosConfigurations.desktop.config;
      launcher =
        pkgs.lib.findFirst (package: package.name == "windows-vm-start")
          (throw "windows-vm-start is missing from the desktop packages")
          desktop.environment.systemPackages;
    in
    {
      checks.windows-gaming =
        assert desktop.systemd.services.libvirtd.restartIfChanged;
        assert builtins.any (
          trigger:
          "${trigger}/bin/windows-gaming-gpu-hook"
          == desktop.virtualisation.libvirtd.hooks.qemu."50-windows-gaming"
        ) desktop.systemd.services.libvirtd.restartTriggers;
        pkgs.runCommand "windows-gaming-check" { nativeBuildInputs = [ pkgs.python3 ]; } ''
          cp -r ${../hosts/desktop/windows-vm} tests
          chmod -R u+w tests
          python3 -m unittest discover -s tests -p 'test_*.py'
          test -s ${desktop.environment.etc."libvirt/windows-gaming.xml".source}
          grep -Fq 'exec ${desktop.security.wrapperDir}/sudo /run/current-system/sw/bin/windows-vm-start' \
            ${launcher}/bin/windows-vm-start
          ! grep -Eq '/nix/store/[^": ]+-sudo-[^": ]*/bin' ${launcher}/bin/windows-vm-start
          touch "$out"
        '';
    };
}
