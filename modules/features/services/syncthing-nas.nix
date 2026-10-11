let
  inherit (import ../../../lib/nas-service-helpers.nix) mountSafety;
  mountpoint = "/storage-pool/notes";
  dataset = "storage-pool/notes";
in
{
  den.aspects.syncthing-nas.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.syncthing;
      checkMount = ''
        # BindPaths can expose multiple records for the same mountpoint.
        test "$(findmnt --uniq -n -o SOURCE --mountpoint ${mountpoint})" = ${dataset}
        test "$(findmnt --uniq -n -o FSTYPE --mountpoint ${mountpoint})" = zfs
      '';
      safety = mountSafety [ mountpoint ];
      guardedService = safety // {
        path = [ pkgs.util-linux ];
        preStart = checkMount;
      };
      snapshot = pkgs.writeShellApplication {
        name = "org-notes-snapshot";
        runtimeInputs = [
          pkgs.zfs
          pkgs.coreutils
          pkgs.util-linux
        ];
        text = builtins.readFile ../../../lib/org-notes-snapshots.sh;
      };
      policies = {
        hourly = 24;
        daily = 30;
        monthly = 12;
      };
    in
    {
      services.syncthing = {
        enable = true;
        guiAddress = "127.0.0.1:8384";
        openDefaultPorts = true;
        overrideDevices = false;
        overrideFolders = false;
        settings = import ../../../lib/org-notes-syncthing.nix {
          inherit lib;
          hostName = "nas";
          path = mountpoint;
        };
      };

      systemd.services = {
        org-notes-dataset = {
          description = "Create and mount the Org notes ZFS dataset";
          after = [ "zfs-mount.service" ];
          requires = [ "zfs-mount.service" ];
          before = [
            "syncthing.service"
            "syncthing-init.service"
          ];
          path = [
            pkgs.zfs
            pkgs.util-linux
            pkgs.coreutils
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            set -euo pipefail
            zfs list storage-pool >/dev/null
            if ! zfs list -H -o name ${dataset} >/dev/null 2>&1; then
              zfs create -u -o mountpoint=${mountpoint} -o compression=zstd -o atime=off ${dataset}
            fi
            # Existing datasets are validated, never reconfigured or recreated.
            test "$(zfs get -H -o value mountpoint ${dataset})" = ${mountpoint}
            test "$(zfs get -H -o value compression ${dataset})" = zstd
            test "$(zfs get -H -o value atime ${dataset})" = off
            if test "$(zfs get -H -o value mounted ${dataset})" != yes; then
              zfs mount ${dataset}
            fi
            ${checkMount}
            chown ${cfg.user}:${cfg.group} ${mountpoint}
            chmod 0700 ${mountpoint}
          '';
        };
        syncthing = lib.mkMerge [
          guardedService
          {
            after = [ "org-notes-dataset.service" ];
            requires = [ "org-notes-dataset.service" ];
            serviceConfig = {
              UMask = "0077";
              ProtectSystem = "strict";
              ReadWritePaths = [
                mountpoint
                cfg.dataDir
              ];
              # Pin the mounted filesystem inside the service mount namespace.
              BindPaths = [ mountpoint ];
            };
          }
        ];
        syncthing-init = guardedService;
      }
      // lib.mapAttrs' (
        period: keep:
        lib.nameValuePair "org-notes-snapshot-${period}" (
          lib.mkMerge [
            safety
            {
              requires = [ "org-notes-dataset.service" ];
              after = [ "org-notes-dataset.service" ];
              startAt = "${period} UTC";
              serviceConfig = {
                Type = "oneshot";
                ExecStart = "${lib.getExe snapshot} ${period} ${toString keep}";
              };
            }
          ]
        )
      ) policies;

      systemd.timers = lib.mapAttrs' (
        period: _:
        lib.nameValuePair "org-notes-snapshot-${period}" {
          timerConfig.Persistent = true;
        }
      ) policies;
    };
}
