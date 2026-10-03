{ den, ... }:

let
  inherit (import ../../../lib/nas-service-helpers.nix) mountSafety httpsRoute;
in
{
  den.aspects.seerr.includes = [ den.aspects.nas-ingress ];

  den.aspects.seerr.nixos =
    { lib, pkgs, ... }:
    {
      services.seerr = {
        enable = true;
        configDir = "/srv/seerr/config";
        stateRevision = 1;
        openFirewall = false;
      };
      services.traefik.dynamicConfigOptions.http = httpsRoute {
        router = "seerr";
        backend = "seerr";
        domain = "requests.sk4rd.com";
        url = "http://127.0.0.1:5055";
        exposure = "trustedNetworks";
      };

      users.groups.seerr = { };
      users.users.seerr = {
        isSystemUser = true;
        group = "seerr";
      };
      systemd.services.seerr = mountSafety [ "/srv/seerr" ] // {
        environment.HOST = "127.0.0.1";
        serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = "seerr";
          Group = "seerr";
          StateDirectory = lib.mkForce [ ];
          ReadWritePaths = [ "/srv/seerr" ];
          InaccessiblePaths = [
            "/srv/samba/media"
            "/srv/samba/torrents"
          ];
          UMask = "0077";
          ExecStartPre = "+${pkgs.coreutils}/bin/install -d -m 0700 -o seerr -g seerr /srv/seerr/config";
        };
      };
    };
}
