{ den, ... }:

{
  den.aspects.media-indexer-relay.includes = [
    den.aspects.prowlarr
    den.aspects.radarr
    den.aspects.sonarr
  ];

  den.aspects.media-indexer-relay.nixos =
    { pkgs, ... }:
    let
      relayImage = pkgs.dockerTools.buildLayeredImage {
        name = "media-indexer-relay";
        tag = "nix";
        config = {
          Entrypoint = [ "${pkgs.socat}/bin/socat" ];
          User = "1003:1003";
        };
      };
      managers = {
        radarr = {
          hostPort = 7878;
          relayPort = 17878;
        };
        sonarr = {
          hostPort = 8989;
          relayPort = 18989;
        };
      };
    in
    {
      # Unix sockets cross the netns boundary without opening host TCP ports.
      systemd.sockets =
        builtins.mapAttrs
          (name: _: {
            wantedBy = [ "sockets.target" ];
            listenStreams = [ "/run/media-indexer-relay/${name}.sock" ];
            socketConfig = {
              Accept = true;
              SocketUser = "prowlarr";
              SocketGroup = "prowlarr";
              SocketMode = "0600";
              DirectoryMode = "0755";
              RemoveOnStop = true;
            };
          })
          {
            "radarr-indexer-relay" = null;
            "sonarr-indexer-relay" = null;
          };

      systemd.services = builtins.listToAttrs (
        builtins.concatLists (
          builtins.attrValues (
            builtins.mapAttrs (name: ports: [
              {
                name = "${name}-indexer-relay@";
                value = {
                  requires = [ "${name}.service" ];
                  after = [ "${name}.service" ];
                  serviceConfig = {
                    ExecStart = "${pkgs.socat}/bin/socat STDIO TCP:127.0.0.1:${toString ports.hostPort}";
                    StandardInput = "socket";
                    StandardOutput = "socket";
                    StandardError = "journal";
                    DynamicUser = true;
                    NoNewPrivileges = true;
                    ProtectSystem = "strict";
                    ProtectHome = true;
                    PrivateTmp = true;
                    PrivateDevices = true;
                    CapabilityBoundingSet = "";
                    RestrictAddressFamilies = [
                      "AF_UNIX"
                      "AF_INET"
                    ];
                  };
                };
              }
              {
                name = "docker-${name}-indexer-relay";
                value = {
                  requires = [ "${name}-indexer-relay.socket" ];
                  after = [ "${name}-indexer-relay.socket" ];
                  bindsTo = [ "docker-qbittorrent-vpn.service" ];
                  partOf = [ "docker-qbittorrent-vpn.service" ];
                };
              }
            ]) managers
          )
        )
      );

      virtualisation.oci-containers.containers =
        builtins.mapAttrs
          (name: ports: {
            image = "media-indexer-relay:nix";
            imageFile = relayImage;
            pull = "never";
            dependsOn = [ "qbittorrent-vpn" ];
            networks = [ "container:qbittorrent-vpn" ];
            volumes = [ "/run/media-indexer-relay:/relay:ro" ];
            cmd = [
              "TCP-LISTEN:${toString ports.relayPort},bind=127.0.0.1,reuseaddr,fork"
              "UNIX-CONNECT:/relay/${name}.sock"
            ];
            extraOptions = [
              "--cap-drop=ALL"
              "--security-opt=no-new-privileges"
              "--read-only"
            ];
          })
          {
            "radarr-indexer-relay" = managers.radarr;
            "sonarr-indexer-relay" = managers.sonarr;
          };
    };
}
