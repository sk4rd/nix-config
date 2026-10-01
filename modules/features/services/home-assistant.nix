{ den, ... }:

let
  inherit (import ../../../lib/nas-service-helpers.nix) mountSafety httpsRoute;
in
{
  den.aspects.home-assistant.includes = [ den.aspects.nas-ingress ];

  den.aspects.home-assistant.nixos = {
    virtualisation = {
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

    services.traefik.dynamicConfigOptions.http = httpsRoute {
      router = "homeassistant";
      backend = "homeassistant";
      domain = "ha.sk4rd.com";
      url = "http://127.0.0.1:8123";
      exposure = "trustedNetworks";
    };

    systemd.services.docker-home-assistant = mountSafety [ "/srv/home-assistant" ];
  };
}
