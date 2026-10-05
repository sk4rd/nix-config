{ den, inputs, ... }:

let
  inherit (import ../../../lib/nas-service-helpers.nix) httpsRoute;
in
{
  den.aspects.hermes-central = {
    includes = [ den.aspects.nas-ingress ];

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # The pinned upstream flake otherwise stamps the runtime as 0.0.0.
        hermesPackage = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
          version = "0.21.5";
          distance = 6831;
        };
        homeassistantPlugin = pkgs.fetchFromGitHub {
          name = "homeassistant";
          owner = "NousResearch";
          repo = "hermes-homeassistant";
          rev = "ba30cb0cf86c52bdb5cde98974bc062e97966529";
          hash = "sha256-Pg4smvkiVpmcmUola0rziMBfq5V7UjzX8864Dem76pI=";
        };
        homeassistantEnvironmentFile = "-/var/lib/hermes/.hermes/homeassistant.env";
        shellTools = with pkgs; [
          bashInteractive
          coreutils
          curl
          file
          findutils
          git
          gnugrep
          gnused
          jq
          just
          python3
          ripgrep
          gnutar
          unzip
          util-linux
          wget
          which
          zip
        ];
      in
      {
        imports = [ inputs.hermes-agent.nixosModules.default ];

        fileSystems."/var/lib/hermes" = {
          device = "storage-pool/services/hermes";
          fsType = "zfs";
        };

        systemd.services.hermes-agent = {
          path = shellTools;
          environment.HASS_URL = "http://127.0.0.1:8123";
          serviceConfig.EnvironmentFile = lib.mkAfter [ homeassistantEnvironmentFile ];
          unitConfig.RequiresMountsFor = [ "/var/lib/hermes" ];
        };
        systemd.services.hermes-backend = {
          path = shellTools;
          environment.HASS_URL = "http://127.0.0.1:8123";
          serviceConfig.EnvironmentFile = [
            config.sops.secrets."nas/hermes/dashboard_env".path
            homeassistantEnvironmentFile
          ];
          unitConfig.RequiresMountsFor = [ "/var/lib/hermes" ];
        };

        programs.bash.interactiveShellInit = ''
          if [ "$USER" = hermes ] && [ -n "$SSH_CONNECTION" ]; then
            cd -- ${lib.escapeShellArg config.services.hermes-agent.workingDirectory}
          fi
        '';

        users.users.hermes.openssh.authorizedKeys.keys = [
          (lib.removeSuffix "\n" (builtins.readFile ../../users/miko/ssh.pub))
        ];

        # Terminal login shells reset PATH; keep tools in the user's managed profile.
        users.users.hermes.packages = shellTools ++ [
          config.nix.package
          config.services.hermes-agent.package
          pkgs.openssh
          pkgs.nodejs_26
        ];

        services.hermes-agent = {
          enable = true;
          package = hermesPackage;
          extraPlugins = [ homeassistantPlugin ];
          backend = {
            mode = "dashboard";
            host = "127.0.0.1";
            port = 9119;
          };
          settings = {
            plugins.enabled = [ "homeassistant" ];
            platforms.homeassistant.enabled = false;
            dashboard = {
              public_url = "https://hermes.sk4rd.com";

            };
            model = {
              provider = "openai-codex";
              default = "gpt-6-luna";
              api_mode = "codex_responses";
            };
            agent.reasoning_effort = "medium";
            delegation = {
              max_concurrent_children = 2;
              max_spawn_depth = 1;
              orchestrator_enabled = false;
            };
            auxiliary.review = {
              provider = "openai-codex";
              model = "gpt-6-sol";
            };
          };
        };

        services.traefik.dynamicConfigOptions.http = httpsRoute {
          router = "hermes";
          backend = "hermes";
          domain = "hermes.sk4rd.com";
          url = "http://127.0.0.1:9119";
          exposure = "trustedNetworks";
        };

        sops.secrets."nas/hermes/dashboard_env" = {
          mode = "0400";
          restartUnits = [ "hermes-backend.service" ];
        };

        sops.secrets."nas/hermes/homeassistant_env" = {
          path = "/var/lib/hermes/.hermes/homeassistant.env";
          owner = "hermes";
          mode = "0400";
          restartUnits = [
            "hermes-agent.service"
            "hermes-backend.service"
          ];
        };

      };
  };
}
