{
  den.aspects.nas-secrets.nixos =
    { config, ... }:
    {
      sops = {
        defaultSopsFile = ../../../secrets/nas.yaml;
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

        secrets = {
          "nas/cloudflare/dns_api_token" = {
            mode = "0400";
            restartUnits = [
              "ddclient.service"
              "traefik.service"
            ];
          };
          "nas/protonvpn/wireguard_private_key" = {
            mode = "0400";
            restartUnits = [ "docker-qbittorrent-vpn.service" ];
          };
          "nas/qbittorrent/webui_password" = {
            mode = "0400";
            restartUnits = [ "docker-qbittorrent-vpn.service" ];
          };
          "nas/prowlarr/username" = {
            mode = "0400";
            restartUnits = [ "docker-prowlarr.service" ];
          };
          "nas/prowlarr/password" = {
            mode = "0400";
            restartUnits = [ "docker-prowlarr.service" ];
          };
          "nas/wireguard/server_key" = {
            mode = "0400";
            restartUnits = [ "wg-quick-wg0.service" ];
          };
          "nas/wireguard/phone_psk" = {
            mode = "0400";
            restartUnits = [ "wg-quick-wg0.service" ];
          };
          "nas/searxng/secret_key" = {
            mode = "0400";
            restartUnits = [ "docker-searxng.service" ];
          };
        };
      };
    };
}
