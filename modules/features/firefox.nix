{
  den.aspects.firefox.homeManager = {
    programs.firefox = {
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
