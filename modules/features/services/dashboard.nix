{ den, ... }:

{
  den.aspects.dashboard.includes = [ den.aspects.nas-ingress ];

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
      virtualisation = {
        docker.enable = true;
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

      services.traefik.dynamicConfigOptions.http = {
        routers.dashboard = {
          rule = "Host(`dashboard.sk4rd.com`)";
          entryPoints = [ "websecure" ];
          middlewares = [ "trustedNetworks" ];
          service = "homepage";
          tls.certResolver = "cloudflare";
        };
        services.homepage.loadBalancer.servers = [
          { url = "http://127.0.0.1:3000"; }
        ];
      };

      systemd.services = {
        homepage-config = {
          description = "Write Homepage dashboard configuration";
          after = [ "zfs-mount.service" ];
          before = [ "docker-homepage.service" ];
          requires = [ "zfs-mount.service" ];
          unitConfig = {
            RequiresMountsFor = [ "/srv/homepage" ];
            AssertPathIsMountPoint = [ "/srv/homepage" ];
          };
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${writeConfig}/bin/homepage-write-config";
          };
        };

        docker-homepage = {
          after = [
            "zfs-mount.service"
            "homepage-config.service"
          ];
          requires = [
            "zfs-mount.service"
            "homepage-config.service"
          ];
          unitConfig = {
            RequiresMountsFor = [ "/srv/homepage" ];
            AssertPathIsMountPoint = [ "/srv/homepage" ];
          };
        };
      };
    };
}
