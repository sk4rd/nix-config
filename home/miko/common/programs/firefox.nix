{ ... }:

{
  # Firefox configuration
  programs.firefox = {
    enable = true;
    profiles."miko" = {
      search.engines = {
        # Nix Packages search
        "Nix Packages" = {
          urls = [{
            template = "https://search.nixos.org/packages";
            params = [
              {
                name = "type";
                value = "packages";
              }
              {
                name = "query";
                value = "{searchTerms}";
              }
            ];
          }];
          definedAliases = [ "@np" ];
        };

        # NixOS Wiki search
        "NixOS Wiki" = {
          urls = [{
            template = "https://nixos.wiki/index.php?search={searchTerms}";
          }];
          iconUpdateURL = "https://nixos.wiki/favicon.png";
          updateInterval = 24 * 60 * 60 * 1000; # every day
          definedAliases = [ "@nw" ];
        };

        # SearX meta search engine
        "SearX" = {
          urls = [{
            template =
              "https://searx.tiekoetter.com/search?q={searchTerms}&category_general=1&language=en-US&time_range=&safesearch=0&theme=simple";
            params = [
              {
                name = "category_general";
                value = "1";
              }
              {
                name = "language";
                value = "en-US";
              }
              {
                name = "safesearch";
                value = "0";
              }
              {
                name = "theme";
                value = "simple";
              }
            ];
          }];
          definedAliases = [ "@sx" ];
        };
      };

      # Set the default search engine
      search.default = "SearX";
    };
  };
}
