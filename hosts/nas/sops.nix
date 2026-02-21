{ ... }:

{
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets."nas/yubikey-pub" = {
      path = "/home/admin/.ssh/authorized_keys";
      owner = "admin";
      mode = "0600";
    };
  };
}
