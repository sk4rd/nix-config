{ den, ... }:

{
  den.aspects.nas = {
    includes = [
      den.batteries.hostname
      den.aspects.nas-server
    ];

    nixos = {
      nix.settings.trusted-users = [ "admin" ];
      users.users.backup.openssh.authorizedKeys.keys = [
        # Dedicated restic backup key: restrict disables forwarding/pty; the
        # user has a nologin shell, so the key can only be used for SFTP.
        "restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHfioCSbN/YcaKUzSrN8HPkFP1/DH0U+YI5tI7EtlyHW restic-backup"
      ];
      # Force every session for the backup user to run the in-process sftp
      # server, bypassing the nologin shell.
      services.openssh.extraConfig = ''
        Match User backup
          ForceCommand internal-sftp
          PasswordAuthentication no
      '';
      # The backup user owns the restic repository directory.
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
