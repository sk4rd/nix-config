{ den, ... }:

{
  den.aspects.silverbullet.includes = [ den.aspects.nas-ingress ];

  den.aspects.silverbullet.nixos =
    { pkgs, lib, ... }:
    let
      palette = builtins.fromJSON (builtins.readFile ../desktop/neon-flux-theme/palette.json);
      theme = pkgs.writeText "silverbullet-neon-flux.md" (
        lib.replaceStrings (map (name: "@${name}@") (
          builtins.attrNames palette
        )) (builtins.attrValues palette) (builtins.readFile ./silverbullet/neon-flux.md)
      );
    in
    {
      virtualisation = {
        docker.enable = true;
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

      services.traefik.dynamicConfigOptions.http = {
        routers.silverbullet = {
          rule = "Host(`silverbullet.sk4rd.com`)";
          entryPoints = [ "websecure" ];
          service = "silverbullet";
          tls.certResolver = "cloudflare";
        };
        services.silverbullet.loadBalancer.servers = [
          { url = "http://127.0.0.1:13001"; }
        ];
      };

      services.ddclient.domains = [ "silverbullet.sk4rd.com" ];

      systemd.services.docker-silverbullet = {
        after = [ "zfs-mount.service" ];
        requires = [ "zfs-mount.service" ];
        serviceConfig.ExecStartPre = [
          "+${pkgs.coreutils}/bin/install -d -o silverbullet -g silverbullet /srv/silverbullet/space"
          # The Space Manager stores each space below spaces/<name>, not at /space.
          # Fail rather than silently creating an unregistered or misspelled space.
          # Drop privileges before traversing the service-owned space tree.
          "+${pkgs.util-linux}/bin/runuser -u silverbullet -- ${pkgs.coreutils}/bin/test -d /srv/silverbullet/space/spaces/notes"
          "+${pkgs.util-linux}/bin/runuser -u silverbullet -- ${pkgs.coreutils}/bin/install -m 0644 ${theme} '/srv/silverbullet/space/spaces/notes/Neon Flux.md'"
        ];
        unitConfig = {
          RequiresMountsFor = [ "/srv/silverbullet" ];
          AssertPathIsMountPoint = [ "/srv/silverbullet" ];
        };
      };
    };
}
