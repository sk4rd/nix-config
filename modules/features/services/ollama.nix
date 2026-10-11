{
  den.aspects.ollama.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.ollama-vulkan ];
    };
}
