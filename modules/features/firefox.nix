{
  den.aspects.firefox.homeManager = {
    programs.firefox = {
      profiles.default = {
        id = 0;
        isDefault = true;
        settings = {
          "browser.uidensity" = 0;
          "general.autoScroll" = true;
          "media.ffmpeg.vaapi.enabled" = true;
          "media.hardware-video-decoding.enabled" = true;
        };
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
