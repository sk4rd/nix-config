{
  den.aspects.backup.nixos =
    { config, pkgs, ... }:
    {
      sops.secrets."restic/password" = {
        sopsFile = ../../secrets/nas-cifs.yaml;
        owner = "miko";
        mode = "0400";
      };

      environment.systemPackages = [ pkgs.restic ];

      services.restic.backups.home = {
        repository = "sftp:admin@192.168.178.3:/storage-pool/backups/restic/${config.networking.hostName}";
        passwordFile = config.sops.secrets."restic/password".path;
        initialize = true;
        user = "miko";
        paths = [ "/home/miko" ];
        exclude = [
          ".cache"
          "**/.cache"
          ".local/share/Trash"
          "**/node_modules"
          "**/.venv"
          "**/target"
          "**/__pycache__"
        ];
        extraBackupArgs = [ "--exclude-caches" ];
        timerConfig = {
          # Devices are usually off at night, so back up shortly after boot
          # and again every 24h of continuous uptime, instead of a fixed time.
          OnBootSec = "15min";
          OnUnitActiveSec = "24h";
          RandomizedDelaySec = "10min";
        };
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 6"
        ];
      };
    };
}
