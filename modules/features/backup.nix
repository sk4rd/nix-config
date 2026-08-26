{
  den.aspects.backup.nixos =
    { config, pkgs, ... }:
    {
      sops.secrets = {
        "restic/password" = {
          sopsFile = ../../secrets/nas-cifs.yaml;
          owner = "miko";
          mode = "0400";
        };
        "backup/ssh_key" = {
          sopsFile = ../../secrets/nas-cifs.yaml;
          owner = "miko";
          mode = "0600";
        };
      };

      environment.systemPackages = [ pkgs.restic ];

      # Scope the dedicated backup key to exactly backup@the-NAS. Interactive
      # SSH as admin is unaffected (no Match), so it keeps using the YubiKey.
      programs.ssh.extraConfig = ''
        Match host 192.168.178.3 user backup
          IdentityFile /run/secrets/backup/ssh_key
          IdentitiesOnly yes
      '';

      services.restic.backups.home = {
        repository = "sftp:backup@192.168.178.3:/storage-pool/backups/restic/${config.networking.hostName}";
        passwordFile = config.sops.secrets."restic/password".path;
        initialize = true;
        user = "miko";
        paths = [ "/home/miko" ];
        exclude = [
          ".cache"
          "**/.cache"
          ".local/share/Trash"
          ".vscode-server"
          ".vscode-remote-containers"
          ".copilot"
          ".npm"
          "**/node_modules"
          "**/.venv"
          "**/target"
          "**/__pycache__"
          # Steam game installs are re-downloadable; userdata (saves) stays.
          "**/steamapps/common"
          "**/steamapps/downloading"
          "**/steamapps/workshop"
          "**/steamapps/shadercache"
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
