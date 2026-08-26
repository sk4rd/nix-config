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
          "nas/wireguard/server_key" = {
            mode = "0400";
            restartUnits = [ "wg-quick-wg0.service" ];
          };
          "nas/wireguard/phone_psk" = {
            mode = "0400";
            restartUnits = [ "wg-quick-wg0.service" ];
          };
          "nas/wireguard/laptop_psk" = {
            mode = "0400";
            restartUnits = [ "wg-quick-wg0.service" ];
          };
        };

        templates = {
          "traefik-cloudflare.env" = {
            content = ''
              CF_DNS_API_TOKEN=${config.sops.placeholder."nas/cloudflare/dns_api_token"}
            '';
            owner = "traefik";
            group = "traefik";
            mode = "0400";
          };

          "qbittorrent-protonvpn.env" = {
            content = ''
              VPN_SERVICE_PROVIDER=protonvpn
              VPN_TYPE=wireguard
              WIREGUARD_PRIVATE_KEY=${config.sops.placeholder."nas/protonvpn/wireguard_private_key"}
              SERVER_COUNTRIES=Netherlands
              PORT_FORWARD_ONLY=on
              VPN_PORT_FORWARDING=on
              VPN_PORT_FORWARDING_STATUS_FILE=/gluetun/forwarded_port
              VPN_PORT_FORWARDING_UP_COMMAND=/scripts/portforward-up.sh {{PORT}} {{VPN_INTERFACE}}
              VPN_PORT_FORWARDING_DOWN_COMMAND=/scripts/portforward-down.sh
              TZ=Europe/Berlin
              FIREWALL_INPUT_PORTS=18080,3000
            '';
            mode = "0400";
          };
        };
      };
    };
}
