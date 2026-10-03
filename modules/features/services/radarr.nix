{ den, ... }:

let
  inherit (import ../../../lib/nas-service-helpers.nix) mountSafety httpsRoute;
in
{
  den.aspects.radarr.includes = [ den.aspects.torrenting ];

  den.aspects.radarr.nixos =
    { lib, pkgs, ... }:
    {
      services.radarr = {
        enable = true;
        dataDir = "/srv/radarr/config";
        openFirewall = false;
        settings.server.bindaddress = "127.0.0.1";
      };
      services.traefik.dynamicConfigOptions.http = httpsRoute {
        router = "radarr";
        backend = "radarr";
        domain = "radarr.sk4rd.com";
        url = "http://127.0.0.1:7878";
        exposure = "trustedNetworks";
      };

      users.users.radarr.extraGroups = [
        "miko"
        "qbittorrent"
      ];
      # Create state only after the dataset assertion, not during activation.
      systemd.tmpfiles.settings."10-radarr" = lib.mkForce { };
      systemd.services.radarr =
        mountSafety [
          "/srv/radarr"
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
            ExecStartPre = "+${pkgs.coreutils}/bin/install -d -m 0700 -o radarr -g radarr /srv/radarr/config";
            UMask = lib.mkForce "0002";
          };
        };
    };
}
