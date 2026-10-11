{
  den.aspects.emacs = {
    homeManager =
      { config, ... }:
      {
        programs.emacs.enable = true;
        home.file.".emacs.d/init.el".text =
          builtins.replaceStrings
            [ "\"@emacsCacheDirectory@\"" ]
            [ (builtins.toJSON "${config.xdg.cacheHome}/emacs/") ]
            (builtins.readFile ./init.el);
      };
  };
}
