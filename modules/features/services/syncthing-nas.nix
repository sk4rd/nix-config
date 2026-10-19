let
  inherit (import ../../../lib/nas-service-helpers.nix) mountSafety;
  mountpoint = "/storage-pool/documents";
  # storage-pool/documents already backs the Samba share.
  dataset = "storage-pool/syncthing-documents";
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
        after = safety.after ++ [ "documents-dataset.service" ];
        requires = safety.requires ++ [ "documents-dataset.service" ];
        path = [ pkgs.util-linux ];
        preStart = checkMount;
      };
      snapshot = pkgs.writeShellApplication {
        name = "documents-snapshot";
        runtimeInputs = [
          pkgs.zfs
          pkgs.coreutils
          pkgs.util-linux
        ];
        text = builtins.readFile ../../../lib/documents-snapshots.sh;
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
        settings = {
          devices = import ../../../lib/syncthing-devices.nix {
            inherit lib;
            hostName = "nas";
          };
          folders = {
            documents = import ../../../lib/documents-syncthing.nix {
              path = mountpoint;
              devices = builtins.attrNames cfg.settings.devices;
            };
            hermes-profiles = import ../../../lib/hermes-profiles-syncthing.nix {
              path = "${cfg.dataDir}/hermes-profiles";
              devices = builtins.attrNames cfg.settings.devices;
            };
          };
        };
      };

      systemd.services = {
        documents-dataset = {
          description = "Create and mount the Documents ZFS dataset";
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
            require_property() {
              actual=$(zfs get -H -o value "$1" ${dataset})
              if test "$actual" != "$2"; then
                printf 'Dataset %s: expected %s=%s, found %s\n' ${dataset} "$1" "$2" "$actual" >&2
                exit 1
              fi
            }
            require_property mountpoint ${mountpoint}
            require_property compression zstd
            require_property atime off
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
        lib.nameValuePair "documents-snapshot-${period}" (
          lib.mkMerge [
            safety
            {
              requires = [ "documents-dataset.service" ];
              after = [ "documents-dataset.service" ];
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
        lib.nameValuePair "documents-snapshot-${period}" {
          timerConfig.Persistent = true;
        }
      ) policies;
    };
}
