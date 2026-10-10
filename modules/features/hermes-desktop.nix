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
          delegation = {
            max_concurrent_children = 2;
            max_spawn_depth = 1;
            orchestrator_enabled = false;
          };
        };
      };
    };
}
