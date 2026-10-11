{
  den.aspects.emacs = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        options.programs.emacs.notesDirectory = lib.mkOption {
          type = lib.types.str;
          default = "~/notes";
          description = "Root directory for Org notes, tasks, journal, and Org-roam knowledge notes.";
        };

        config = {
          programs.emacs = {
            enable = true;
            overrides = self: _super: {
              neon-flux-theme = pkgs.callPackage ../../../pkgs/emacs/neon-flux-theme {
                inherit (self) trivialBuild;
              };
            };
            extraPackages = epkgs: [
              epkgs.neon-flux-theme
              epkgs.breadcrumb
              epkgs.consult
              epkgs.corfu
              epkgs.cape
              epkgs.eldoc-box
              epkgs.gptel
              epkgs.gptel-agent
              epkgs.marginalia
              epkgs.markdown-mode
              epkgs.magit
              epkgs.orderless
              epkgs.vertico
              epkgs.vterm
              epkgs.nix-mode
              epkgs.org-roam
              epkgs.org-appear
              epkgs.org-modern
            ];
          };
          fonts.fontconfig.enable = true;
          home.packages = [
            pkgs.nerd-fonts.jetbrains-mono
            pkgs.ripgrep
            pkgs.nixd
            pkgs.nixfmt
          ];
          home.file.".emacs.d/init.el".text =
            builtins.replaceStrings
              [
                "\"@emacsCacheDirectory@\""
                "\"@emacsPandoc@\""
                "\"@emacsNotesDirectory@\""
              ]
              [
                (builtins.toJSON "${config.xdg.cacheHome}/emacs/")
                (builtins.toJSON "${pkgs.pandoc}/bin/pandoc")
                (builtins.toJSON config.programs.emacs.notesDirectory)
              ]
              (builtins.readFile ./init.el);
        };
      };
  };
}
