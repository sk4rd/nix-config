{
  den.aspects.prowlarr.nixos =
    { pkgs, ... }:
    let
      authScript = pkgs.writeShellApplication {
        name = "prowlarr-auth";
        runtimeInputs = [ pkgs.python3 ];
        text = ''
          exec python3 ${pkgs.writeText "prowlarr-auth.py" (builtins.readFile ./prowlarr/prowlarr-auth.py)}
        '';
      };
    in
    {
      virtualisation = {
        docker.enable = true;
        oci-containers = {
          backend = "docker";
          containers.prowlarr = {
            image = "lscr.io/linuxserver/prowlarr@sha256:ab91301778251f82a31bbfc87f0497376d59e84439d9a1ceff6a61d594d1e3d7";
            pull = "missing";
            dependsOn = [ "qbittorrent-vpn" ];
            environment = {
              PUID = "1003";
              PGID = "1003";
              TZ = "Europe/Berlin";
            };
            volumes = [ "/srv/prowlarr/config:/config" ];
            # Shares the Gluetun network namespace, so indexer traffic exits
            # through ProtonVPN and Prowlarr can reach qBittorrent locally.
            networks = [ "container:qbittorrent-vpn" ];
          };
        };
      };

      services.traefik.dynamicConfigOptions.http = {
        routers.prowlarr = {
          rule = "Host(`prowlarr.sk4rd.com`)";
          entryPoints = [ "websecure" ];
          middlewares = [ "trustedNetworks" ];
          service = "prowlarr";
          tls.certResolver = "cloudflare";
        };
        services.prowlarr.loadBalancer.servers = [
          { url = "http://127.0.0.1:9696"; }
        ];
      };

      systemd.services.docker-prowlarr = {
        after = [ "zfs-mount.service" ];
        requires = [ "zfs-mount.service" ];
        unitConfig = {
          RequiresMountsFor = [ "/srv/prowlarr" ];
          AssertPathIsMountPoint = [ "/srv/prowlarr" ];
        };
      };

      # Applies the declarative login via Prowlarr's API after each start.
      systemd.services.prowlarr-auth = {
        description = "Apply Prowlarr declarative authentication";
        after = [ "docker-prowlarr.service" ];
        requires = [ "docker-prowlarr.service" ];
        wantedBy = [ "docker-prowlarr.service" ];
        partOf = [ "docker-prowlarr.service" ];
        serviceConfig = {
          ExecStart = "${authScript}/bin/prowlarr-auth";
          Restart = "on-failure";
          RestartSec = "10s";
          Type = "oneshot";
        };
      };
    };
}
