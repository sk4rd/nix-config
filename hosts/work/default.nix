{ config, ... }:

{
  sops = {
    defaultSopsFile = ../../secrets/work.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets."proxy_extra_hosts" = { };
  };

  networking.hostFiles = [ config.sops.secrets."proxy_extra_hosts".path ];

  system.stateVersion = "25.11";
  wsl.enable = true;
}
