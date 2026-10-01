{ inputs, ... }:

{
  den.aspects.hermes-desktop.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
        inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.desktop
      ];
    };
}
