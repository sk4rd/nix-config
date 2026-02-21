{ pkgs, ... }:

{
  networking = {
    hostId = "6985f698";
    hostName = "nas";
    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [ 8080 ];
    };
    networkmanager = {
      enable = true;
      ensureProfiles.profiles = {
        "Wired Connection 1" = {
          connection.type = "ethernet";
          connection.id = "Wired Connection 1";
          connection.interface-name = "enp1s0";
          connection.autoconnect = true;
          ipv4.method = "manual";
          ipv4.addresses = "192.168.178.3/24";
          ipv4.gateway = "192.168.178.1";
        };
      };
    };
    nat = {
      enable = true;
      internalInterfaces = [ "wg0" ];
      externalInterface = "enp1s0";
      enableIPv6 = true;
    };
  };
  networking.wg-quick.interfaces = {
    wg0 = {
      # Determines the IP/IPv6 address and subnet of the client's end of the tunnel interface
      address = [
        "10.0.0.1/24"
        "fdc9:281f:04d7:9ee9::1/64"
      ];
      # The port that WireGuard listens to - recommended that this be changed from default
      listenPort = 51820;
      # Path to the server's private key
      privateKeyFile = "/home/admin/wireguard-keys/server.key";

      # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
      postUp = ''
        ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.0.0.1/24 -o enp1s0 -j MASQUERADE
        ${pkgs.iptables}/bin/ip6tables -A FORWARD -i wg0 -j ACCEPT
        ${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s fdc9:281f:04d7:9ee9::1/64 -o enp1s0 -j MASQUERADE
      '';

      # Undo the above
      preDown = ''
        ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.0.0.1/24 -o enp1s0 -j MASQUERADE
        ${pkgs.iptables}/bin/ip6tables -D FORWARD -i wg0 -j ACCEPT
        ${pkgs.iptables}/bin/ip6tables -t nat -D POSTROUTING -s fdc9:281f:04d7:9ee9::1/64 -o enp1s0 -j MASQUERADE
      '';

      peers = [
        {
          # phone
          publicKey = "OS2CPzfaiJn1uQc+CxFl6JF5PuR1hqoMWOwpkS5U2Rg=";
          presharedKeyFile = "/home/admin/wireguard-keys/phone.psk";
          allowedIPs = [
            "10.0.0.2/32"
            "fdc9:281f:04d7:9ee9::2/128"
          ];
        }
      ];
    };
  };
}
