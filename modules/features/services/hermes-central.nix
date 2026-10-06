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
        hermesBasePackage =
          inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default.override
            {
              version = "0.21.5";
              distance = 6831;
            };
        mkHindsightWheel =
          pname: sha256:
          hermesBasePackage.python.pkgs.buildPythonPackage {
            inherit pname;
            version = "0.10.1";
            format = "wheel";
            src = pkgs.fetchPypi {
              pname = lib.replaceStrings [ "-" ] [ "_" ] pname;
              inherit sha256;
              version = "0.10.1";
              format = "wheel";
              dist = "py3";
              python = "py3";
              abi = "none";
              platform = "any";
            };
            # Dependencies are already supplied by Hermes' sealed environment.
            PYTHONPATH = "${hermesBasePackage.hermesVenv}/${hermesBasePackage.python.sitePackages}";
            pythonImportsCheck = [ (lib.replaceStrings [ "-" ] [ "_" ] pname) ];
          };
        hermesPackage = hermesBasePackage.override {
          extraPythonPackages = [
            (mkHindsightWheel "hindsight-client" "04e03353a0f9dcfa7b1b1000cccc8f077a93a788b27af62cc5e014b2dd3b960c")
            (mkHindsightWheel "hindsight-embed" "6cf2294ea94113dcf13b2ca61010d571673d2bca6245cd2c3a714fd760cdb8c0")
          ];
        };
        hindsightSource = pkgs.fetchFromGitHub {
          owner = "vectorize-io";
          repo = "hindsight";
          rev = "d56c4acdf59c41957613d399094cdf8c489b060c";
          hash = "sha256-L5HjVF64foSslizP6FPvEcnzorK4LY78YnuuP8rfEcA=";
        };
        hindsightPlugin = pkgs.runCommand "hindsight" { } ''
          mkdir -p "$out"
          cp -r ${hindsightSource}/hindsight-integrations/hermes/. "$out/"
        '';
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

        # Memory-provider discovery requires the canonical directory name.
        systemd.tmpfiles.rules = [
          "L+ ${config.services.hermes-agent.stateDir}/.hermes/plugins/hindsight - - - - ${hindsightPlugin}"
        ];

        virtualisation.oci-containers = {
          backend = "docker";
          containers.hindsight = {
            image = "ghcr.io/vectorize-io/hindsight@sha256:d1840062a5b79940ab7a9f4809ceb90fc776d4ad737cd9329e9b5836cc64ab70";
            pull = "missing";
            environment = {
              CODEX_HOME = "/home/hindsight/.codex";
              HINDSIGHT_API_LLM_PROVIDER = "openai-codex";
              HINDSIGHT_API_LLM_MODEL = "gpt-6-luna";
              HINDSIGHT_API_LLM_REASONING_EFFORT = "low";
              HINDSIGHT_API_WORKER_ID = "hermes-nas";
            };
            volumes = [
              "hindsight-data:/home/hindsight/.pg0"
              "/var/lib/hindsight/codex:/home/hindsight/.codex"
            ];
            ports = [
              "127.0.0.1:8888:8888/tcp"
              "127.0.0.1:9999:9999/tcp"
            ];
            extraOptions = [
              "--shm-size=1g"
              "--stop-timeout=60"
            ];
          };
        };
        systemd.services.docker-hindsight = {
          unitConfig.RequiresMountsFor = [ "/var/lib/hermes" ];
          serviceConfig = {
            StateDirectory = "hindsight";
            StateDirectoryMode = "0700";
            TimeoutStartSec = lib.mkForce 900;
          };
          preStart = ''
            ${pkgs.coreutils}/bin/install -d -m 0700 -o 1000 -g 1000 /var/lib/hindsight/codex
            # Seed once; the service owns its rotating tokens from then on.
            if [ ! -f /var/lib/hindsight/codex/auth.json ]; then
              ${pkgs.coreutils}/bin/install -m 0600 -o 1000 -g 1000 \
                /var/lib/hermes/.hindsight/codex/auth.json /var/lib/hindsight/codex/auth.json
            fi
          '';
          postStart = ''
            ${pkgs.curl}/bin/curl --fail --silent --show-error \
              --retry 120 --retry-delay 2 --retry-all-errors --max-time 5 \
              http://127.0.0.1:8888/health >/dev/null
          '';
        };

        systemd.services.hermes-agent = {
          wants = [ "docker-hindsight.service" ];
          after = [ "docker-hindsight.service" ];
          path = shellTools;
          environment.HASS_URL = "http://127.0.0.1:8123";
          serviceConfig.EnvironmentFile = lib.mkAfter [ homeassistantEnvironmentFile ];
          unitConfig.RequiresMountsFor = [ "/var/lib/hermes" ];
        };
        systemd.services.hermes-backend = {
          wants = [ "docker-hindsight.service" ];
          after = [ "docker-hindsight.service" ];
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
          hermesHomeFiles."hindsight/config.json" = builtins.toJSON {
            mode = "local_external";
            api_url = "http://127.0.0.1:8888";
            bank_id = "hermes-default";
            bank_id_template = "hermes-{profile}";
            memory_mode = "hybrid";
            auto_recall = true;
            auto_retain = true;
          };
          backend = {
            mode = "dashboard";
            host = "127.0.0.1";
            port = 9119;
          };
          settings = {
            plugins.enabled = [
              "homeassistant"
              "hindsight"
            ];
            memory.provider = "hindsight";
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

        services.traefik.dynamicConfigOptions.http =
          (httpsRoute {
            router = "hermes";
            backend = "hermes";
            domain = "hermes.sk4rd.com";
            url = "http://127.0.0.1:9119";
            exposure = "trustedNetworks";
          })
          // (httpsRoute {
            router = "hindsight";
            backend = "hindsight";
            domain = "hindsight.sk4rd.com";
            url = "http://127.0.0.1:8888";
            exposure = "trustedNetworks";
          });

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
