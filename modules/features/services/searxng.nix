{ den, ... }:

{
  den.aspects.searxng.includes = [ den.aspects.nas-ingress ];

  den.aspects.searxng.nixos =
    { config, ... }:
    {
      virtualisation = {
        docker.enable = true;
        oci-containers.containers.searxng = {
          image = "ghcr.io/searxng/searxng@sha256:b36af7984b87191b595bc5301418ed6432c047668a4547ab531a7439b816fac3";
          pull = "missing";
          environment = {
            SEARXNG_BASE_URL = "https://search.sk4rd.com";
          };
          # The image runs as the searxng user and FORCE_OWNERSHIP (default)
          # chowns the mounted volumes on start, so no host-side chown needed.
          environmentFiles = [ config.sops.templates."searxng.env".path ];
          volumes = [
            "/srv/searxng/config:/etc/searxng"
            "/srv/searxng/cache:/var/cache/searxng"
          ];
          ports = [ "127.0.0.1:8080:8080/tcp" ];
        };
      };

      services.traefik.dynamicConfigOptions.http = {
        routers.search = {
          rule = "Host(`search.sk4rd.com`)";
          entryPoints = [ "websecure" ];
          middlewares = [ "trustedNetworks" ];
          service = "searxng";
          tls.certResolver = "cloudflare";
        };
        services.searxng.loadBalancer.servers = [
          { url = "http://127.0.0.1:8080"; }
        ];
      };

      systemd.services.docker-searxng = {
        after = [ "zfs-mount.service" ];
        requires = [ "zfs-mount.service" ];
        unitConfig = {
          RequiresMountsFor = [ "/srv/searxng" ];
          AssertPathIsMountPoint = [ "/srv/searxng" ];
        };
      };
    };
}
