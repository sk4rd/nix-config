{ den, ... }:

let
  inherit (import ../../../lib/nas-service-helpers.nix) mountSafety httpsRoute;
in
{
  den.aspects.prowlarr.includes = [
    den.aspects.nas-ingress
    den.aspects.torrenting
  ];

  den.aspects.prowlarr.nixos =
    { pkgs, ... }:
    let
      configureScript = pkgs.writeShellApplication {
        name = "prowlarr-configure";
        runtimeInputs = [ pkgs.python3 ];
        text = ''
          exec python3 ${pkgs.writeText "prowlarr-configure.py" (builtins.readFile ./prowlarr/prowlarr-configure.py)}
        '';
      };
    in
    {
      sops.secrets."nas/prowlarr/username" = {
        mode = "0400";
        restartUnits = [ "docker-prowlarr.service" ];
      };
      sops.secrets."nas/prowlarr/password" = {
        mode = "0400";
        restartUnits = [ "docker-prowlarr.service" ];
      };

      virtualisation = {
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
              # The VPN netns is IPv4-only; DNS returns AAAA records and .NET does
              # not fall back, so force IPv4 to avoid EAGAIN on indexer connections.
              DOTNET_SYSTEM_NET_DISABLEIPV6 = "1";
            };
            volumes = [ "/srv/prowlarr/config:/config" ];
            # Shares the Gluetun network namespace, so indexer traffic exits
            # through ProtonVPN and Prowlarr can reach qBittorrent locally.
            networks = [ "container:qbittorrent-vpn" ];
          };

          containers.flaresolverr = {
            image = "ghcr.io/flaresolverr/flaresolverr@sha256:139dfee1c6f89249c8d665d1333a42e8ec74ec0a86bc6bb1c8461e10d3a66a47";
            pull = "missing";
            dependsOn = [ "qbittorrent-vpn" ];
            # Solves Cloudflare challenges for Prowlarr; shares the VPN netns so
            # it presents the same exit IP the indexer sees.
            networks = [ "container:qbittorrent-vpn" ];
          };
        };
      };

      services.traefik.dynamicConfigOptions.http = httpsRoute {
        router = "prowlarr";
        backend = "prowlarr";
        domain = "prowlarr.sk4rd.com";
        url = "http://127.0.0.1:9696";
        exposure = "trustedNetworks";
      };

      systemd.services = {
        docker-prowlarr = mountSafety [ "/srv/prowlarr" ] // {
          bindsTo = [ "docker-qbittorrent-vpn.service" ];
          partOf = [ "docker-qbittorrent-vpn.service" ];
        };

        docker-flaresolverr = {
          bindsTo = [ "docker-qbittorrent-vpn.service" ];
          partOf = [ "docker-qbittorrent-vpn.service" ];
        };

        # Applies the declarative login and qBittorrent client via the API.
        prowlarr-configure = {
          description = "Apply Prowlarr declarative configuration";
          after = [ "docker-prowlarr.service" ];
          requires = [ "docker-prowlarr.service" ];
          wantedBy = [ "docker-prowlarr.service" ];
          partOf = [ "docker-prowlarr.service" ];
          serviceConfig = {
            ExecStart = "${configureScript}/bin/prowlarr-configure";
            Restart = "on-failure";
            RestartSec = "10s";
            Type = "oneshot";
          };
        };
      };
    };
}
