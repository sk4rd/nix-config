{ den, ... }:

let
  inherit (import ../../../lib/nas-service-helpers.nix) mountSafety httpsRoute;
in
{
  den.aspects.silverbullet.includes = [ den.aspects.nas-ingress ];

  den.aspects.silverbullet.nixos =
    { pkgs, ... }:
    {
      virtualisation = {
        oci-containers = {
          backend = "docker";
          containers.silverbullet = {
            image = "ghcr.io/silverbulletmd/silverbullet@sha256:27b5724cc36798e7de82180ec9898ea9c157c4f15127f279834bca2897b91f37";
            pull = "missing";
            user = "1004:1004";
            environment.SB_SHELL_BACKEND = "off";
            volumes = [ "/srv/silverbullet/space:/space" ];
            ports = [ "127.0.0.1:13001:3000/tcp" ];
          };
        };
      };

      services.traefik.dynamicConfigOptions.http = httpsRoute {
        router = "silverbullet";
        backend = "silverbullet";
        domain = "silverbullet.sk4rd.com";
        url = "http://127.0.0.1:13001";
        exposure = "public";
      };

      services.ddclient.domains = [ "silverbullet.sk4rd.com" ];

      systemd.services.docker-silverbullet = mountSafety [ "/srv/silverbullet" ] // {
        serviceConfig.ExecStartPre = [
          "+${pkgs.coreutils}/bin/install -d -o silverbullet -g silverbullet /srv/silverbullet/space"
        ];
      };
    };
}
