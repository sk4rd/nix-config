{ den, ... }:

let
  inherit (import ../../../lib/nas-service-helpers.nix) mountSafety;
in

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
      services.samba.settings.HermesWorkspace = {
        path = "/var/lib/hermes/workspace";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "miko";
        "force user" = "hermes";
        "force group" = "hermes";
        "follow symlinks" = "no";
        "wide links" = "no";
        "create mask" = "0660";
        "directory mask" = "0770";
      };
      systemd.services.samba-smbd = mountSafety [ "/var/lib/hermes" ];
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
