{ inputs, ... }:

{
  den.aspects.hermes-desktop.homeManager =
    { config, pkgs, ... }:
    {
      imports = [ inputs.hermes-agent.homeManagerModules.default ];

      home.packages = [
        inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
        inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.desktop
      ];

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
