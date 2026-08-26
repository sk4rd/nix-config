{
  den.aspects.home-assistant.nixos = {
    virtualisation = {
      docker.enable = true;
      oci-containers = {
        backend = "docker";
        containers.home-assistant = {
          image = "ghcr.io/home-assistant/home-assistant@sha256:14931c6b13756317849f46da1d01b45937a1150db66c081cfe529d48215943fe";
          pull = "missing";
          environment.TZ = "Europe/Berlin";
          volumes = [
            "/srv/home-assistant/config:/config"
            "/etc/localtime:/etc/localtime:ro"
          ];
          networks = [ "host" ];
          extraOptions = [ "--stop-timeout=60" ];
        };
      };
    };

    services.traefik.dynamicConfigOptions.http = {
      routers.homeassistant = {
        rule = "Host(`ha.sk4rd.com`)";
        entryPoints = [ "websecure" ];
        middlewares = [ "trustedNetworks" ];
        service = "homeassistant";
        tls.certResolver = "cloudflare";
      };
      services.homeassistant.loadBalancer.servers = [
        { url = "http://127.0.0.1:8123"; }
      ];
    };

    systemd.services.docker-home-assistant = {
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
      unitConfig = {
        RequiresMountsFor = [ "/srv/home-assistant" ];
        AssertPathIsMountPoint = [ "/srv/home-assistant" ];
      };
    };
  };
}
