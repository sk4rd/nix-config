{ den, ... }:

{
  den.aspects.nas = {
    includes = [
      den.aspects.nas-secrets
      den.aspects.nas-server
      den.aspects.hermes-central
    ];

    nixos = {
      nix.settings.trusted-users = [ "admin" ];
      users.users.backup.openssh.authorizedKeys.keys = [
        # Disable forwarding and PTY allocation; ForceCommand below limits sessions to SFTP.
        "restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHfioCSbN/YcaKUzSrN8HPkFP1/DH0U+YI5tI7EtlyHW restic-backup"
      ];
      # internal-sftp bypasses the backup user's nologin shell.
      services.openssh.extraConfig = ''
        Match User backup
          ForceCommand internal-sftp
          PasswordAuthentication no
      '';
      systemd.tmpfiles.rules = [
        "d /storage-pool/backups/restic 0750 backup backup -"
      ];
      security.sudo.extraRules = [
        {
          users = [ "admin" ];
          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
      system.stateVersion = "25.05";
    };
  };
}
