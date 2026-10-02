{ inputs, ... }:

{
  den.aspects.hermes-desktop.homeManager =
    { config, ... }:
    {
      imports = [ inputs.hermes-agent.homeManagerModules.default ];

      programs.hermes-agent = {
        enable = true;
        desktop = {
          enable = true;
          package = config.programs.hermes-agent.package.hermesDesktop.overrideAttrs (old: {
            # Keep ownership profile-scoped via .managed, not inherited by every local backend.
            postFixup = (old.postFixup or "") + ''
              substituteInPlace "$out/bin/hermes-desktop" \
                --replace-fail "export HERMES_MANAGED='home-manager'" ""
            '';
          });
        };
      };

      services.hermes-agent = {
        enable = true;
        settings = {
          model = {
            provider = "openai-codex";
            default = "gpt-6-luna";
            api_mode = "codex_responses";
          };
          agent.reasoning_effort = "medium";

          skills.trusted_project_dirs = [ "${config.home.homeDirectory}/Documents/nix-config" ];

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
    };
}
