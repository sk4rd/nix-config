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
      programs.ssh = {
        extraConfig = ''
          Match host 192.168.178.3 user backup
            IdentityFile /run/secrets/backup/ssh_key
            IdentitiesOnly yes
        '';
        # Pin the NAS host key so headless restic runs never prompt; the key is
        # verified against this entry instead of the user's known_hosts.
        knownHosts.nas = {
          hostNames = [ "192.168.178.3" ];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILArnumluz/iLq+plACTbdY83uVZGw+B0T8TNeCINHD5 root@nixos";
        };
      };

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
