{
  den.aspects.emacs = {
    homeManager =
      { config, pkgs, ... }:
      {
        programs.emacs = {
          enable = true;
          overrides = self: _super: {
            neon-flux-theme = pkgs.callPackage ../../../pkgs/emacs/neon-flux-theme {
              inherit (self) trivialBuild;
            };
          };
          extraPackages = epkgs: [ epkgs.neon-flux-theme ];
        };
        fonts.fontconfig.enable = true;
        home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
        home.file.".emacs.d/init.el".text =
          builtins.replaceStrings
            [ "\"@emacsCacheDirectory@\"" ]
            [ (builtins.toJSON "${config.xdg.cacheHome}/emacs/") ]
            (builtins.readFile ./init.el);
      };
  };
}
