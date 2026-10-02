{ den, inputs, ... }:

let
  inherit (import ../../../lib/nas-service-helpers.nix) httpsRoute mountSafety;
in
{
  den.aspects.hermes-shared = {
    includes = [ den.aspects.nas-ingress ];

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        dataDir = "/srv/hermes";
        hermesHome = "${dataDir}/home";
        workspaceDir = "${dataDir}/workspace";
        hermesUid = 986; # Preserve the NAS account UID used by its user manager.
        hermes = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
        hermesWorkspaceShell = pkgs.writeShellApplication {
          name = "hermes-workspace-shell";
          runtimeInputs = [
            pkgs.bashInteractive
            pkgs.coreutils
            pkgs.git
            pkgs.openssh
            pkgs.nix
          ];
          text =
            let
              palette = builtins.fromJSON (builtins.readFile ../desktop/neon-flux-theme/palette.json);
            in
            builtins.replaceStrings [ "@accent@" "@structure@" ] [ palette.accent palette.structure ] (
              builtins.readFile ./hermes-workspace-shell.sh
            );
        };
        hermesDashboard = pkgs.writeShellApplication {
          name = "hermes-dashboard";
          runtimeInputs = [ hermes ];
          text = ''
            cd ${workspaceDir}
            exec hermes dashboard --host 0.0.0.0 --port 9119 --skip-build --no-open
          '';
        };
      in
      {
        sops.secrets = {
          "hermes/basic_auth/username" = {
            sopsFile = ../../../secrets/hermes.yaml;
            mode = "0400";
          };
          "hermes/basic_auth/password" = {
            sopsFile = ../../../secrets/hermes.yaml;
            mode = "0400";
          };
          "hermes/basic_auth/signing_secret" = {
            sopsFile = ../../../secrets/hermes.yaml;
            mode = "0400";
          };
        };

        sops.templates."hermes.env" = {
          content = ''
            HERMES_DASHBOARD_BASIC_AUTH_USERNAME=${config.sops.placeholder."hermes/basic_auth/username"}
            HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=${config.sops.placeholder."hermes/basic_auth/password"}
            HERMES_DASHBOARD_BASIC_AUTH_SECRET=${config.sops.placeholder."hermes/basic_auth/signing_secret"}
          '';
          mode = "0400";
          restartUnits = [ "hermes-dashboard.service" ];
        };

        users.groups.hermes = { };
        users.users.hermes = {
          isSystemUser = true;
          uid = hermesUid;
          linger = true;
          group = "hermes";
          home = hermesHome;
          createHome = false;
          shell = "${pkgs.shadow}/bin/nologin";
        };

        environment.systemPackages = [
          hermes
          hermesWorkspaceShell
        ];

        services.traefik.dynamicConfigOptions.http = httpsRoute {
          router = "hermes";
          backend = "hermes";
          domain = "hermes.sk4rd.com";
          url = "http://127.0.0.1:9119";
          exposure = "trustedNetworks";
        };

        systemd.services.hermes-dashboard = lib.mkMerge [
          (mountSafety [ dataDir ])
          {
            description = "Shared Hermes Agent dashboard and backend";
            wantedBy = [ "multi-user.target" ];
            after = [
              "network-online.target"
              "user@${toString hermesUid}.service"
            ];
            requires = [ "user@${toString hermesUid}.service" ];
            wants = [ "network-online.target" ];
            # Terminal runners need an executable shell, not the account's nologin.
            path = [ pkgs.bash ];
            unitConfig.ConditionPathExists = config.sops.templates."hermes.env".path;
            serviceConfig = {
              Type = "simple";
              User = "hermes";
              Group = "hermes";
              WorkingDirectory = dataDir;
              ExecStartPre = [
                "+${pkgs.coreutils}/bin/install -d -o hermes -g hermes -m 0750 ${dataDir}"
                "+${pkgs.coreutils}/bin/install -d -o hermes -g hermes -m 0700 ${hermesHome}"
                "+${pkgs.coreutils}/bin/install -d -o hermes -g hermes -m 0750 ${workspaceDir}"
                # Grant SFTP workspace access as hermes, never recurse as root.
                "${pkgs.acl}/bin/setfacl -m u:admin:--x ${dataDir}"
                "${pkgs.acl}/bin/setfacl -m u:admin:r-X,m::r-X,d:u:admin:r-X,d:m::r-x ${workspaceDir}"
                "${pkgs.acl}/bin/setfacl -R -m u:admin:r-X,m::r-X ${workspaceDir}"
                "${pkgs.findutils}/bin/find ${workspaceDir} -type d -exec ${pkgs.acl}/bin/setfacl -m d:u:admin:r-X,d:m::r-x {} +"
              ];
              Environment = [
                "HOME=${hermesHome}"
                "HERMES_HOME=${hermesHome}"
                "SHELL=${pkgs.bash}/bin/bash"
                "XDG_RUNTIME_DIR=/run/user/${toString hermesUid}"
                "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${toString hermesUid}/bus"
                "HERMES_DASHBOARD_HOST=0.0.0.0"
                "HERMES_DASHBOARD_PORT=9119"
                "HERMES_DASHBOARD_PUBLIC_URL=https://hermes.sk4rd.com"
              ];
              EnvironmentFile = config.sops.templates."hermes.env".path;
              ExecStart = lib.getExe hermesDashboard;
              Restart = "on-failure";
              RestartSec = 5;
              RestartPreventExitStatus = "78";
              UMask = "0077";
              NoNewPrivileges = true;
              PrivateTmp = true;
              ProtectHome = "read-only";
              ProtectSystem = "strict";
              ReadWritePaths = [ dataDir ];
              RestrictAddressFamilies = [
                "AF_UNIX"
                "AF_INET"
                "AF_INET6"
              ];
            };
          }
        ];
      };
  };
}
