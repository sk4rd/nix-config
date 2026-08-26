{
  den.aspects.torrenting.nixos =
    { config, pkgs, ... }:
    let
      portForwardLib = pkgs.writeTextFile {
        name = "qbittorrent-lib.sh";
        text = builtins.readFile ./torrenting/qbittorrent-lib.sh;
      };
      portForwardUp = pkgs.writeTextFile {
        name = "qbittorrent-portforward-up.sh";
        executable = true;
        text = builtins.readFile ./torrenting/gluetun-portforward-up.sh;
      };
      portForwardDown = pkgs.writeTextFile {
        name = "qbittorrent-portforward-down.sh";
        executable = true;
        text = builtins.readFile ./torrenting/gluetun-portforward-down.sh;
      };
      configure = pkgs.writeShellApplication {
        name = "qbittorrent-configure";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.python3
        ];
        text = builtins.readFile ./torrenting/qbittorrent-configure.sh;
      };
      bootstrap = pkgs.writeShellApplication {
        name = "qbittorrent-bootstrap";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.docker
        ];
        text = builtins.readFile ./torrenting/qbittorrent-bootstrap.sh;
      };
    in
    {
      boot.kernelModules = [ "tun" ];

      virtualisation = {
        docker.enable = true;
        oci-containers = {
          backend = "docker";
          containers = {
            qbittorrent-vpn = {
              image = "ghcr.io/qdm12/gluetun@sha256:725d3e51091dde4ca43e3e3f26e2e6d3d0ccc66821e92d505c3da04958f7d472";
              pull = "missing";
              environmentFiles = [ config.sops.templates."qbittorrent-protonvpn.env".path ];
              volumes = [
                "/srv/qbittorrent/gluetun:/gluetun"
                "${portForwardLib}:/scripts/qbittorrent-lib.sh:ro"
                "${portForwardUp}:/scripts/portforward-up.sh:ro"
                "${portForwardDown}:/scripts/portforward-down.sh:ro"
                "${
                  config.sops.secrets."nas/qbittorrent/webui_password".path
                }:/run/secrets/qbittorrent-webui-password:ro"
              ];
              ports = [
                "127.0.0.1:18080:18080/tcp"
                "127.0.0.1:13000:3000/tcp"
                "127.0.0.1:9696:9696/tcp"
              ];
              capabilities.NET_ADMIN = true;
              devices = [ "/dev/net/tun:/dev/net/tun" ];
            };

            qbittorrent = {
              image = "lscr.io/linuxserver/qbittorrent@sha256:3679a75dd2304b695525d83a4ff14c458708b5da4a7ce53044240932139590e1";
              pull = "missing";
              dependsOn = [ "qbittorrent-vpn" ];
              environment = {
                PUID = "2001";
                PGID = "2001";
                TZ = "Europe/Berlin";
                UMASK = "002";
                WEBUI_PORT = "18080";
                TORRENTING_PORT = "6881";
              };
              volumes = [
                "/srv/qbittorrent/config:/config"
                "/srv/samba/media:/media"
                "/srv/samba/torrents/qbittorrent:/downloads"
              ];
              networks = [ "container:qbittorrent-vpn" ];
            };

            firefox = {
              image = "lscr.io/linuxserver/firefox@sha256:5077213d6be79cb4bdb6d9b96ad5e8be981ed566f02eff53b832a5e21aa4c706";
              pull = "missing";
              dependsOn = [ "qbittorrent-vpn" ];
              environment = {
                PUID = "2001";
                PGID = "2001";
                TZ = "Europe/Berlin";
                TITLE = "Torrent Browser";
                SELKIES_UI_TITLE = "Torrent Browser";
                START_DOCKER = "false";
                HARDEN_DESKTOP = "true";
                HARDEN_OPENBOX = "true";
                DISABLE_SUDO = "true";
                DISABLE_TERMINALS = "true";
                SELKIES_ENABLE_SHARING = "false|locked";
              };
              volumes = [ "/srv/firefox:/config" ];
              networks = [ "container:qbittorrent-vpn" ];
              extraOptions = [ "--shm-size=1gb" ];
            };
          };
        };
      };

      systemd.services = {
        docker-qbittorrent-vpn = {
          after = [ "zfs-mount.service" ];
          requires = [ "zfs-mount.service" ];
          unitConfig = {
            RequiresMountsFor = [ "/srv/qbittorrent" ];
            AssertPathIsMountPoint = [ "/srv/qbittorrent" ];
          };
        };

        docker-qbittorrent = {
          bindsTo = [ "docker-qbittorrent-vpn.service" ];
          partOf = [ "docker-qbittorrent-vpn.service" ];
          restartTriggers = [ configure ];
          after = [
            "docker-qbittorrent-vpn.service"
            "qbittorrent-config.service"
            "zfs-mount.service"
          ];
          requires = [
            "docker-qbittorrent-vpn.service"
            "qbittorrent-config.service"
            "zfs-mount.service"
          ];
          unitConfig.RequiresMountsFor = [
            "/srv/qbittorrent"
            "/srv/samba/media"
            "/srv/samba/torrents"
          ];
          unitConfig.AssertPathIsMountPoint = [
            "/srv/qbittorrent"
            "/srv/samba/media"
            "/srv/samba/torrents"
          ];
        };

        docker-firefox = {
          bindsTo = [ "docker-qbittorrent-vpn.service" ];
          partOf = [ "docker-qbittorrent-vpn.service" ];
          after = [
            "docker-qbittorrent-vpn.service"
            "zfs-mount.service"
          ];
          requires = [
            "docker-qbittorrent-vpn.service"
            "zfs-mount.service"
          ];
          unitConfig = {
            RequiresMountsFor = [ "/srv/firefox" ];
            AssertPathIsMountPoint = [ "/srv/firefox" ];
          };
        };

        qbittorrent-config = {
          description = "Prepare qBittorrent configuration";
          after = [ "zfs-mount.service" ];
          before = [ "docker-qbittorrent.service" ];
          requires = [ "zfs-mount.service" ];
          unitConfig = {
            RequiresMountsFor = [ "/srv/qbittorrent" ];
            AssertPathIsMountPoint = [ "/srv/qbittorrent" ];
          };
          serviceConfig = {
            ExecStart = "${configure}/bin/qbittorrent-configure";
            Type = "oneshot";
          };
        };

        qbittorrent-bootstrap = {
          description = "Configure qBittorrent through its authenticated API";
          after = [
            "docker-qbittorrent-vpn.service"
            "docker-qbittorrent.service"
          ];
          requires = [
            "docker-qbittorrent-vpn.service"
            "docker-qbittorrent.service"
          ];
          wantedBy = [ "docker-qbittorrent.service" ];
          partOf = [ "docker-qbittorrent.service" ];
          serviceConfig = {
            ExecStart = "${bootstrap}/bin/qbittorrent-bootstrap";
            Restart = "on-failure";
            RestartSec = "30s";
            TimeoutStartSec = "infinity";
            Type = "oneshot";
          };
        };
      };
    };
}
