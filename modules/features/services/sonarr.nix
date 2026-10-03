{ den, ... }:

let
  inherit (import ../../../lib/nas-service-helpers.nix) mountSafety httpsRoute;
in
{
  den.aspects.sonarr.includes = [ den.aspects.torrenting ];

  den.aspects.sonarr.nixos =
    { lib, pkgs, ... }:
    {
      services.sonarr = {
        enable = true;
        dataDir = "/srv/sonarr/config";
        openFirewall = false;
        settings.server.bindaddress = "127.0.0.1";
      };
      services.traefik.dynamicConfigOptions.http = httpsRoute {
        router = "sonarr";
        backend = "sonarr";
        domain = "sonarr.sk4rd.com";
        url = "http://127.0.0.1:8989";
        exposure = "trustedNetworks";
      };

      users.users.sonarr.extraGroups = [
        "miko"
        "qbittorrent"
      ];
      systemd.services.sonarr =
        mountSafety [
          "/srv/sonarr"
          "/srv/samba/media"
        ]
        // {
          requires = [
            "media-download-directories.service"
            "zfs-mount.service"
          ];
          after = [
            "media-download-directories.service"
            "zfs-mount.service"
          ];
          serviceConfig = {
            ExecStartPre = "+${pkgs.coreutils}/bin/install -d -m 0700 -o sonarr -g sonarr /srv/sonarr/config";
            UMask = lib.mkForce "0002";
          };
        };
    };
}
