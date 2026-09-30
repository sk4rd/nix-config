{ lib, ... }:

let
  palette = builtins.fromJSON (builtins.readFile ./desktop/neon-flux-theme/palette.json);
  variables =
    ":root {\n"
    + lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: "  --${name}: ${value};") palette)
    + "\n}";
in
{
  den.aspects.firefox.homeManager =
    { pkgs, ... }:
    let
      startPage = "file://${
        pkgs.writeText "neon-flux-start.html" (
          builtins.replaceStrings [ "@palette@" ] [ variables ] (builtins.readFile ./firefox/start.html)
        )
      }";
    in
    {
      programs.firefox = {
        # Firefox has no preference for a custom new-tab URL. Use the wrapper's
        # AutoConfig hook to point it at the same immutable page as the homepage.
        package = pkgs.firefox.override {
          extraAutoConfig = ''
            pref("general.config.sandbox_enabled", false);
          '';
          extraPrefs = ''
            // Wait until browser initialization has finished setting up AboutNewTab.
            Services.obs.addObserver(() => {
              const { AboutNewTab } = ChromeUtils.importESModule(
                "resource:///modules/AboutNewTab.sys.mjs"
              );
              AboutNewTab.newTabURL = ${builtins.toJSON startPage};
            }, "browser-delayed-startup-finished");
          '';
        };
        profiles.default = {
          id = 0;
          isDefault = true;
          settings = {
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "browser.startup.page" = 1;
            "browser.startup.homepage" = startPage;
            "browser.uidensity" = 0;
            "browser.theme.content-theme" = 0;
            "browser.theme.toolbar-theme" = 0;
            "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
          };
          userChrome = variables + builtins.readFile ./firefox/userChrome.css;
          userContent = builtins.replaceStrings [ "@palette@" ] [ variables ] (
            builtins.readFile ./firefox/userContent.css
          );
        };

        enable = true;

        policies = {
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableTelemetry = true;
          PasswordManagerEnabled = false;

          ExtensionSettings."uBlock0@raymondhill.net" = {
            installation_mode = "normal_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          };

          ExtensionSettings."78272b6fa58f4a1abaac99321d503a20@proton.me" = {
            installation_mode = "normal_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/proton-pass/latest.xpi";
          };
        };
      };
    };
}
