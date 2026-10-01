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
        hermes = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
        hermesServe = pkgs.writeShellApplication {
          name = "hermes-serve";
          runtimeInputs = [ hermes ];
          text = ''
            cd ${workspaceDir}
            exec hermes serve --host 127.0.0.1 --port 9119 --skip-build
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
          restartUnits = [ "hermes-serve.service" ];
        };

        users.groups.hermes = { };
        users.users.hermes = {
          isSystemUser = true;
          group = "hermes";
          home = hermesHome;
          createHome = false;
          shell = "${pkgs.shadow}/bin/nologin";
        };

        environment.systemPackages = [ hermes ];

        services.traefik.dynamicConfigOptions.http = httpsRoute {
          router = "hermes";
          backend = "hermes";
          domain = "hermes.sk4rd.com";
          url = "http://127.0.0.1:9119";
          exposure = "trustedNetworks";
        };

        systemd.services.hermes-serve = lib.mkMerge [
          (mountSafety [ dataDir ])
          {
            description = "Shared Hermes Agent backend";
            wantedBy = [ "multi-user.target" ];
            after = [
              "network-online.target"
              "sops-install-secrets.service"
            ];
            wants = [ "network-online.target" ];
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
              ];
              Environment = [
                "HOME=${hermesHome}"
                "HERMES_HOME=${hermesHome}"
                "HERMES_DASHBOARD_HOST=127.0.0.1"
                "HERMES_DASHBOARD_PORT=9119"
                "HERMES_DASHBOARD_PUBLIC_URL=https://hermes.sk4rd.com"
              ];
              EnvironmentFile = config.sops.templates."hermes.env".path;
              ExecStart = lib.getExe hermesServe;
              Restart = "on-failure";
              RestartSec = 5;
              UMask = "0077";
              NoNewPrivileges = true;
              PrivateTmp = true;
              ProtectHome = true;
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
