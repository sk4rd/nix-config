{ lib, ... }:

{
  den.aspects.gaming = {
    nixos =
      { pkgs, ... }:
      {
        # Steam is the only unfree package in this stack.
        nixpkgs.config.allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            "steam"
            "steam-original"
            "steam-run"
            "steam-unwrapped"
          ];

        programs = {
          steam = {
            enable = true;
            # In-home streaming and Remote Play Together.
            remotePlay.openFirewall = true;
            # Declarative Proton GE-Proton; newer versions can be added with
            # ProtonUp-Qt (in the Home Manager package set below).
            extraCompatPackages = [ pkgs.proton-ge-bin ];
          };

          gamemode.enable = true;
          # Per-game gamescope via `gamescope -f -- %command%` or Steam's toggle.
          gamescope.enable = true;
        };
      };

    homeManager =
      { pkgs, ... }:
      {
        programs.mangohud.enable = true;

        home.packages = [
          pkgs.protontricks
          pkgs.protonup-qt
        ];
      };
  };
}
