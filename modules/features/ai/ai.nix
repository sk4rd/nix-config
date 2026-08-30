{ inputs, ... }:

{
  den.aspects.ai = {
    nixos =
      { pkgs, ... }:
      {
        services.ollama = {
          enable = true;
          package = pkgs.ollama-rocm;
          # Unload the model after 30 minutes idle so the GPU is free for
          # gaming, while agent sessions don't pay a cold start per request.
          environmentVariables.OLLAMA_KEEP_ALIVE = "30m";
          # Pull on service start; not loaded into VRAM until a request arrives.
          loadModels = [ "qwen3.8:27b" ];
        };
      };

    homeManager =
      { pkgs, ... }:
      {
        imports = [ inputs.hermes-agent.homeManagerModules.default ];

        programs.hermes-agent.enable = true;

        services.hermes-agent = {
          enable = true;
          # Core agent only; the full package bundles every optional integration.
          package = inputs.hermes-agent.packages.${pkgs.system}.minimal;
          settings.model = {
            base_url = "http://127.0.0.1:11434/v1";
            default = "qwen3.8:27b";
          };
        };
      };
  };
}
