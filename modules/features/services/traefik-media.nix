{
  den.aspects.traefik-media.nixos =
    { config, ... }:
    {
      services = {
        ddclient = {
          enable = true;
          interval = "5min";
          protocol = "cloudflare";
          zone = "sk4rd.com";
          domains = [
            "media.sk4rd.com"
            "vpn.sk4rd.com"
          ];
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
            routers = {
              jellyfin = {
                rule = "Host(`media.sk4rd.com`)";
                entryPoints = [ "websecure" ];
                service = "jellyfin";
                tls.certResolver = "cloudflare";
              };
              qbittorrent = {
                rule = "Host(`torrent.sk4rd.com`)";
                entryPoints = [ "websecure" ];
                middlewares = [ "trustedNetworks" ];
                service = "qbittorrent";
                tls.certResolver = "cloudflare";
              };
              firefox = {
                rule = "Host(`firefox.sk4rd.com`)";
                entryPoints = [ "websecure" ];
                middlewares = [ "trustedNetworks" ];
                service = "firefox";
                tls.certResolver = "cloudflare";
              };
            };
            middlewares.trustedNetworks.ipAllowList.sourceRange = [
              "192.168.178.0/24"
              "10.0.0.0/24"
            ];
            services = {
              jellyfin.loadBalancer.servers = [ { url = "http://127.0.0.1:8096"; } ];
              qbittorrent.loadBalancer = {
                servers = [ { url = "http://127.0.0.1:18080"; } ];
                passHostHeader = false;
              };
              firefox.loadBalancer.servers = [ { url = "http://127.0.0.1:13000"; } ];
            };
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
}
