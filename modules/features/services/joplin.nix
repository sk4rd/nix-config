{
  den.aspects.joplin.nixos =
    { config, ... }:
    {
      virtualisation = {
        docker.enable = true;
        oci-containers = {
          backend = "docker";
          containers.joplin = {
            # Pinned to 3.5.2: Joplin Server 3.6.x/3.7.x break SQLite logins with a
            # knex connection-pool deadlock (github.com/laurent22/joplin#15226,
            # fixed upstream by PR #16244, not yet released). Upgrade once a tag
            # carrying the fix ships.
            image = "docker.io/joplin/server@sha256:5d9e7f9d31b436cb1b99d1a6a65d8c5bf760829094617e8ad1e956fd925de888";
            pull = "missing";
            environmentFiles = [ config.sops.templates."joplin.env".path ];
            environment = {
              APP_BASE_URL = "https://joplin.sk4rd.com";
              DB_CLIENT = "sqlite3";
              SQLITE_DATABASE = "/home/joplin/data/db.sqlite";
              # COOKIES_SECURE must stay off: Joplin does not set app.proxy, so
              # behind Traefik the backend connection is plain HTTP and setting a
              # secure cookie aborts login. Traefik redirects HTTP to HTTPS, so
              # cookies still only travel over TLS.
            };
            volumes = [ "/srv/joplin/data:/home/joplin/data" ];
            ports = [ "127.0.0.1:22300:22300/tcp" ];
          };
        };
      };

      services.traefik.dynamicConfigOptions.http = {
        routers.joplin = {
          rule = "Host(`joplin.sk4rd.com`)";
          entryPoints = [ "websecure" ];
          middlewares = [ "trustedNetworks" ];
          service = "joplin";
          tls.certResolver = "cloudflare";
        };
        services.joplin.loadBalancer.servers = [
          { url = "http://127.0.0.1:22300"; }
        ];
      };

      systemd.services.docker-joplin = {
        after = [ "zfs-mount.service" ];
        requires = [ "zfs-mount.service" ];
        unitConfig = {
          RequiresMountsFor = [ "/srv/joplin" ];
          AssertPathIsMountPoint = [ "/srv/joplin" ];
        };
      };
    };
}
