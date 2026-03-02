{ config, ... }:

{
  networking = {
    hostId = "6985f698";
    hostName = "nas";

    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "192.168.178.3";
          prefixLength = 24;
        }
      ];
    };

    defaultGateway = {
      address = "192.168.178.1";
      interface = "enp1s0";
    };

    firewall = {
      enable = true;
      allowPing = true;

      interfaces.enp1s0.allowedTCPPorts = [
        22 # ssh
        139 # smb
        445 # smb
        3000 # forgejo
        5357 # wsdd
      ];

      interfaces.enp1s0.allowedUDPPorts = [
        3702 # wsdd multicast
        51820 # wireguard
      ];

      # WireGuard interface allows the same internal services over VPN
      interfaces.wg0.allowedTCPPorts = [
        22 # ssh
        139 # smb
        445 # smb
        3000 # forgejo
        5357 # wsdd
      ];

      interfaces.wg0.allowedUDPPorts = [
        3702 # wsdd multicast
      ];
    };

    nat = {
      enable = true;
      internalInterfaces = [ "wg0" ];
      externalInterface = "enp1s0";
      enableIPv6 = true;
    };
  };

  services.samba = {
    openFirewall = false; # firewall is handled explicitly above
    settings.global = {
      "interfaces" = "lo enp1s0 wg0";
      "bind interfaces only" = "yes";
    };
  };

  networking.wg-quick.interfaces = {
    wg0 = {
      address = [
        "10.0.0.1/24"
        "fdc9:281f:04d7:9ee9::1/64"
      ];

      listenPort = 51820;
      privateKeyFile = config.sops.secrets."nas/wireguard/server_key".path;

      peers = [
        {
          # phone
          publicKey = "EckLuRfiD2Pyw0qk28miLHLBY0sT0pCB+Oks86MC7ms=";
          presharedKeyFile = config.sops.secrets."nas/wireguard/phone_psk".path;
          allowedIPs = [
            "10.0.0.2/32"
            "fdc9:281f:04d7:9ee9::2/128"
          ];
        }
        {
          # laptop
          publicKey = "qXYhv6Vbo9f86L/NiG0GlW5S23GIlvuh+vo+ypcdXSU=";
          presharedKeyFile = config.sops.secrets."nas/wireguard/laptop_psk".path;
          allowedIPs = [
            "10.0.0.3/32"
            "fdc9:281f:04d7:9ee9::3/128"
          ];
        }
      ];
    };
  };
}
