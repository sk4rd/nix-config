{ den, ... }:

let
  inherit (import ../../../lib/nas-service-helpers.nix) mountSafety httpsRoute;
in
{
  den.aspects.dashboard.includes = [
    den.aspects.nas-ingress
    den.aspects.torrenting
  ];

  den.aspects.dashboard.nixos =
    { config, pkgs, ... }:
    let
      settingsYaml = pkgs.writeText "homepage-settings.yaml" ''
        title: Sk4rd
        theme: dark
        color: slate
        showStats: true
      '';
      writeConfig = pkgs.writeShellApplication {
        name = "homepage-write-config";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          install -m 0600 ${settingsYaml} /srv/homepage/settings.yaml
          install -m 0600 ${config.sops.templates."homepage-services.yaml".path} /srv/homepage/services.yaml
          chown -R 1000:1000 /srv/homepage
        '';
      };
    in
    {
      sops.templates."homepage-services.yaml" = {
        content = ''
          - Media:
              - Jellyfin:
                  href: https://media.sk4rd.com
                  icon: sh-jellyfin
              - Requests:
                  href: https://requests.sk4rd.com
                  icon: sh-jellyseerr
              - Radarr:
                  href: https://radarr.sk4rd.com
                  icon: sh-radarr
              - Sonarr:
                  href: https://sonarr.sk4rd.com
                  icon: sh-sonarr
          - Downloading:
              - qBittorrent:
                  href: https://torrent.sk4rd.com
                  icon: sh-qbittorrent
                  widget:
                    type: qbittorrent
                    url: http://127.0.0.1:18080
                    username: admin
                    password: ${config.sops.placeholder."nas/qbittorrent/webui_password"}
              - Prowlarr:
                  href: https://prowlarr.sk4rd.com
                  icon: sh-prowlarr
              - Firefox:
                  href: https://firefox.sk4rd.com
                  icon: sh-firefox
          - Notes:
              - SilverBullet:
                  href: https://silverbullet.sk4rd.com
                  icon: sh-silverbullet
          - Smart Home:
              - Home Assistant:
                  href: https://ha.sk4rd.com
                  icon: sh-homeassistant
          - Tools:
              - SearXNG:
                  href: https://search.sk4rd.com
                  icon: sh-searxng
        '';
        mode = "0400";
        restartUnits = [ "docker-homepage.service" ];
      };

      virtualisation = {
        oci-containers.containers.homepage = {
          image = "ghcr.io/gethomepage/homepage@sha256:da9dca9ec258c628146bed1445da0853f2b88f0b10bafd97c091de807c363d60";
          pull = "missing";
          # Host networking lets the widgets reach every service on 127.0.0.1,
          # including the loopback-only torrent stack. The NAS firewall still
          # blocks direct access to port 3000, so Traefik remains the entry.
          extraOptions = [ "--network=host" ];
          environment = {
            TZ = "Europe/Berlin";
            HOMEPAGE_ALLOWED_HOSTS = "dashboard.sk4rd.com";
          };
          volumes = [ "/srv/homepage:/app/config" ];
        };
      };

      services.traefik.dynamicConfigOptions.http = httpsRoute {
        router = "dashboard";
        backend = "homepage";
        domain = "dashboard.sk4rd.com";
        url = "http://127.0.0.1:3000";
        exposure = "trustedNetworks";
      };

      systemd.services.docker-homepage = mountSafety [ "/srv/homepage" ] // {
        after = [
          "zfs-mount.service"
          "sops-install-secrets.service"
        ];
        serviceConfig.ExecStartPre = [ "${writeConfig}/bin/homepage-write-config" ];
      };
    };
}
