{
  den.aspects.nas-secrets.nixos = {
    sops = {
      defaultSopsFile = ../../../secrets/nas.yaml;
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

      secrets = {
        "nas/qbittorrent/webui_password" = {
          mode = "0400";
          restartUnits = [ "docker-qbittorrent-vpn.service" ];
        };
        "nas/wireguard/server_key" = {
          mode = "0400";
          restartUnits = [ "wg-quick-wg0.service" ];
        };
        "nas/wireguard/phone_psk" = {
          mode = "0400";
          restartUnits = [ "wg-quick-wg0.service" ];
        };
      };
    };
  };
}
