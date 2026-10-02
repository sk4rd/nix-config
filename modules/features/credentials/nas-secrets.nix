{
  den.aspects.nas-secrets.nixos = {
    sops = {
      defaultSopsFile = ../../../secrets/nas.yaml;
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
  };
}
