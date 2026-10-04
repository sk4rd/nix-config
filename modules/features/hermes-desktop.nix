{ inputs, ... }:

{
  den.aspects.hermes-desktop.homeManager =
    { ... }:
    {
      imports = [ inputs.hermes-agent.homeManagerModules.default ];

      programs.hermes-agent = {
        enable = true;
        desktop.enable = true;
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
