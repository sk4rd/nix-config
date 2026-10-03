{ den, ... }:

let
  inherit (import ../../../lib/nas-service-helpers.nix) mountSafety httpsRoute;
in
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
      traefik.dynamicConfigOptions.http = httpsRoute {
        router = "jellyfin";
        backend = "jellyfin";
        domain = "media.sk4rd.com";
        url = "http://127.0.0.1:8096";
        exposure = "public";
      };
    };

    users.users.jellyfin.extraGroups = [
      "miko"
      "qbittorrent"
    ];

    systemd.services.jellyfin =
      mountSafety [
        "/srv/jellyfin"
        "/srv/samba/media"
      ]
      // {
        serviceConfig.ReadOnlyPaths = [ "/srv/samba/media" ];
      };
  };
}
