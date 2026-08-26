{
  den.aspects.nas.nixos =
    { config, ... }:
    {
      networking = {
        enableIPv6 = false;
        useDHCP = false;
        nameservers = [ "192.168.178.1" ];

        interfaces.enp1s0 = {
          useDHCP = false;
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

        nat = {
          enable = true;
          internalInterfaces = [ "wg0" ];
          externalInterface = "enp1s0";
        };

        wg-quick.interfaces.wg0 = {
          address = [ "10.0.0.1/24" ];
          listenPort = 51820;
          privateKeyFile = config.sops.secrets."nas/wireguard/server_key".path;
          peers = [
            {
              publicKey = "tdO3kv2ijT2Aw2EYcZSqMfg6z+XN545s2eotEHdB2kY=";
              presharedKeyFile = config.sops.secrets."nas/wireguard/phone_psk".path;
              allowedIPs = [ "10.0.0.2/32" ];
            }
          ];
        };

        firewall = {
          enable = true;
          allowPing = true;
          interfaces = {
            enp1s0 = {
              allowedTCPPorts = [
                22
                80
                443
                445
              ];
              allowedUDPPorts = [ 51820 ];
            };
            wg0.allowedTCPPorts = [
              22
              80
              443
              445
            ];
          };
        };
      };

      services.openssh.openFirewall = false;

      services.samba.settings.global = {
        "hosts allow" = "192.168.178.0/24 10.0.0.0/24 127.0.0.1";
        "hosts deny" = "0.0.0.0/0";
      };
    };
}
