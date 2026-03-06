{ config, ... }:

{
  sops = {
    defaultSopsFile = ../../secrets/work.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets."proxy_extra_hosts" = { };
  };

  networking.proxy.default = "http://127.0.0.1:3128";
  networking.hostFiles = [ config.sops.secrets."proxy_extra_hosts".path ];

  wsl = {
    enable = true;
    wslConf.network.generateHosts = false;
  };

  system.stateVersion = "25.11";
}
