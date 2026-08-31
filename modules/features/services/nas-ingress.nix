{ den, ... }:

{
  den.aspects.nas-ingress = {
    includes = [ den.aspects.nas-secrets ];

    nixos =
      { config, ... }:
      {
        services = {
          ddclient = {
            enable = true;
            interval = "5min";
            protocol = "cloudflare";
            username = "token";
            zone = "sk4rd.com";
            passwordFile = config.sops.secrets."nas/cloudflare/dns_api_token".path;
          };

          traefik = {
            enable = true;
            environmentFiles = [ config.sops.templates."traefik-cloudflare.env".path ];
            staticConfigOptions = {
              entryPoints = {
                web = {
                  address = ":80";
                  http.redirections.entryPoint = {
                    to = "websecure";
                    scheme = "https";
                  };
                };
                websecure.address = ":443";
              };
              certificatesResolvers.cloudflare.acme = {
                email = "mikolaj.ba@pm.me";
                storage = "/var/lib/traefik/acme.json";
                dnsChallenge = {
                  provider = "cloudflare";
                  resolvers = [ "192.168.178.1:53" ];
                  propagation = {
                    delayBeforeChecks = "60s";
                    disableANSChecks = true;
                  };
                };
              };
            };
            dynamicConfigOptions.http = {
              middlewares.trustedNetworks.ipAllowList.sourceRange = [
                "192.168.178.0/24"
                "10.0.0.0/24"
              ];
            };
          };
        };

        systemd.services.traefik = {
          after = [ "zfs-mount.service" ];
          requires = [ "zfs-mount.service" ];
          unitConfig = {
            RequiresMountsFor = [ "/var/lib/traefik" ];
            AssertPathIsMountPoint = [ "/var/lib/traefik" ];
          };
        };
      };
  };
}
