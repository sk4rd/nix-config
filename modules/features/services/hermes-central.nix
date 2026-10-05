{ den, inputs, ... }:

let
  inherit (import ../../../lib/nas-service-helpers.nix) httpsRoute;
in
{
  den.aspects.hermes-central = {
    includes = [ den.aspects.nas-ingress ];

    nixos =
      { config, pkgs, ... }:
      let
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
          unitConfig.RequiresMountsFor = [ "/var/lib/hermes" ];
        };
        systemd.services.hermes-backend = {
          path = shellTools;
          unitConfig.RequiresMountsFor = [ "/var/lib/hermes" ];
        };

        # Terminal login shells reset PATH; keep tools in the user's managed profile.
        users.users.hermes.packages = shellTools ++ [
          config.nix.package
          config.services.hermes-agent.package
          pkgs.openssh
          pkgs.nodejs_26
        ];

        services.hermes-agent = {
          enable = true;
          backend = {
            mode = "dashboard";
            host = "127.0.0.1";
            port = 9119;
          };
          settings = {
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

        systemd.services.hermes-backend.serviceConfig.EnvironmentFile =
          config.sops.secrets."nas/hermes/dashboard_env".path;
      };
  };
}
