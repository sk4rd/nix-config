{ den, lib, ... }:

let
  palette = builtins.fromJSON (builtins.readFile ../../themes/neon-flux/palette.json);
  variables =
    ":root {\n"
    + lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: "  --${name}: ${value};") palette)
    + "\n}";
in
{
  den.aspects.librewolf-neon-flux-theme.includes = [ den.aspects.librewolf ];

  den.aspects.librewolf-neon-flux-theme.homeManager =
    { pkgs, ... }:
    let
      startPage = "file://${
        pkgs.writeText "neon-flux-start.html" (
          builtins.replaceStrings [ "@palette@" ] [ variables ] (builtins.readFile ./librewolf/start.html)
        )
      }";
    in
    {
      fonts.fontconfig.enable = true;
      home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

      programs.librewolf = {
        # Custom new-tab URLs require AutoConfig; Firefox exposes no preference.
        package = pkgs.librewolf.override {
          extraAutoConfig = ''
            pref("general.config.sandbox_enabled", false);
          '';
          extraPrefs = ''
            // AboutNewTab must finish initializing before overriding its URL.
            Services.obs.addObserver(() => {
              const { AboutNewTab } = ChromeUtils.importESModule(
                "resource:///modules/AboutNewTab.sys.mjs"
              );
              AboutNewTab.newTabURL = ${builtins.toJSON startPage};
            }, "browser-delayed-startup-finished");
          '';
        };
        profiles.default = {
          settings = {
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "browser.startup.page" = 1;
            "browser.startup.homepage" = startPage;
            "browser.theme.content-theme" = 0;
            "browser.theme.toolbar-theme" = 0;
            "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
          };
          userChrome = variables + builtins.readFile ./librewolf/userChrome.css;
          userContent = builtins.replaceStrings [ "@palette@" ] [ variables ] (
            builtins.readFile ./librewolf/userContent.css
          );
        };
      };
    };
}
