{ ... }:

{
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    gnupg = {
      home = "/home/miko/.gnupg";
      sshKeyPaths = [ ];
    };

    secrets."nas/credentials" = {
      mode = "0600";
    };
  };
}
