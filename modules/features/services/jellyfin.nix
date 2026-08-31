{ den, ... }:

{
  den.aspects.jellyfin.includes = [ den.aspects.nas-ingress ];

  den.aspects.jellyfin.nixos = {
    services = {
      ddclient.domains = [ "media.sk4rd.com" ];
      jellyfin = {
        enable = true;
        dataDir = "/srv/jellyfin";
        cacheDir = "/srv/jellyfin/cache";
        openFirewall = false;
      };
      traefik.dynamicConfigOptions.http = {
        routers.jellyfin = {
          rule = "Host(`media.sk4rd.com`)";
          entryPoints = [ "websecure" ];
          service = "jellyfin";
          tls.certResolver = "cloudflare";
        };
        services.jellyfin.loadBalancer.servers = [ { url = "http://127.0.0.1:8096"; } ];
      };
    };

    users.users.jellyfin.extraGroups = [ "miko" ];

    systemd.services.jellyfin = {
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
      unitConfig.RequiresMountsFor = [
        "/srv/jellyfin"
        "/srv/samba/media"
      ];
      unitConfig.AssertPathIsMountPoint = [
        "/srv/jellyfin"
        "/srv/samba/media"
      ];
    };
  };
}
