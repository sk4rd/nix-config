{
  den.aspects.miko-password.nixos =
    { config, ... }:
    {
      sops = {
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        gnupg.sshKeyPaths = [ ];

        secrets.miko-password = {
          sopsFile = ../../../secrets/miko-password.yaml;
          neededForUsers = true;
        };
      };

      users.mutableUsers = false;
      users.users.miko.hashedPasswordFile = config.sops.secrets.miko-password.path;
    };
}
