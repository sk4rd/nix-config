{
  den.aspects.brave = {
    nixos.environment.etc."brave/policies/managed/browser.json".text = builtins.toJSON {
      PasswordManagerEnabled = false;
      MetricsReportingEnabled = false;
    };

    homeManager = {
      programs.brave = {
        enable = true;
        extensions = [
          { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
          { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } # Proton Pass
        ];
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = [ "brave-browser.desktop" ];
          "x-scheme-handler/http" = [ "brave-browser.desktop" ];
          "x-scheme-handler/https" = [ "brave-browser.desktop" ];
          "x-scheme-handler/about" = [ "brave-browser.desktop" ];
          "x-scheme-handler/unknown" = [ "brave-browser.desktop" ];
        };
      };
    };
  };
}
