{ den, lib, ... }:

let
  palette = builtins.fromJSON (builtins.readFile ../../themes/neon-flux/palette.json);
  # Override Dark Reader's source-color variables, not arbitrary page elements.
  # Its background pole only anchors white; grays otherwise become brighter blue
  # and warm off-whites retain their yellow/brown hue. Keep two navy surface levels.
  grayHex =
    value:
    let
      hex = lib.toLower (lib.toHexString value);
    in
    lib.optionalString (value < 16) "0" + hex;
  neutralColors = builtins.genList (
    value:
    let
      hex = grayHex value;
    in
    {
      source = hex + hex + hex;
      target = if value >= 224 || value < 128 then palette.surface else palette.raised;
    }
  ) 256;
  warmWhites =
    map
      (source: {
        inherit source;
        target = palette.surface;
      })
      [
        "f6f3ec"
        "f6f3ed"
        "f5f5dc"
        "f4f2e9"
        "fffaf0"
        "fff8dc"
        "faf0e6"
        "fdf5e6"
        "fffff0"
      ];
  neutralOverrides = lib.concatMapStringsSep "\n" (color: ''
    --darkreader-background-${color.source}: ${color.target} !important;
    --darkreader-border-${color.source}: ${palette.border} !important;
  '') (neutralColors ++ warmWhites);
  variables =
    ":root {\n"
    + lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: "  --${name}: ${value};") palette)
    + "\n}";
in
{
  den.aspects.brave-neon-flux-theme = {
    includes = [ den.aspects.brave ];

    homeManager =
      { pkgs, ... }:
      let
        startPage = pkgs.writeText "neon-flux-start.html" (
          builtins.replaceStrings [ "@palette@" ] [ variables ] (builtins.readFile ./brave/start.html)
        );
        launchpad = pkgs.runCommand "neon-flux-launchpad" { } ''
          mkdir -p "$out"
          cp ${./brave/manifest.json} "$out/manifest.json"
          cp ${startPage} "$out/start.html"
          cp ${./brave/start.js} "$out/start.js"
        '';
      in
      {
        fonts.fontconfig.enable = true;
        home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

        programs.brave.commandLineArgs = [
          "--force-dark-mode"
          "--homepage=file://${launchpad}/start.html"
          "--load-extension=${launchpad}"
        ];

        # Chromium extension storage is browser-owned; import these via Dark Reader's settings.
        xdg.configFile."BraveSoftware/neon-flux-dark-reader.json".text = builtins.toJSON {
          schemeVersion = 2;
          enabled = true;
          enabledByDefault = true;
          detectDarkTheme = false;
          syncSettings = false;
          theme = {
            mode = 1;
            brightness = 100;
            contrast = 100;
            grayscale = 0;
            sepia = 0;
            useFont = false;
            fontFamily = "Open Sans";
            textStroke = 0;
            engine = "dynamicTheme";
            darkSchemeBackgroundColor = palette.canvas;
            darkSchemeTextColor = palette.text;
            lightSchemeBackgroundColor = "#dcdad7";
            lightSchemeTextColor = "#181a1b";
            selectionColor = palette.selection;
            scrollbarColor = palette.border;
            styleSystemControls = false;
            lightColorScheme = "Default";
            darkColorScheme = "Default";
            immediateModify = false;
            stylesheet = "";
          };
        };

        # Dynamic mode reads custom CSS from Developer Tools fixes, not theme.stylesheet.
        xdg.configFile."BraveSoftware/neon-flux-dark-reader.css".text = ''
          /* BEGIN NEON FLUX — replace this whole block when updating. */
          :root {
            ${neutralOverrides}
          }
          html, body {
            background-color: ${palette.canvas} !important;
            color: ${palette.text} !important;
          }
          a:link {
            color: ${palette.accent} !important;
          }
          a:visited {
            color: ${palette.purple} !important;
          }
          a:any-link:hover {
            color: ${palette.accentBright} !important;
          }
          input:is(:not([type]), [type="text"], [type="search"], [type="email"],
            [type="password"], [type="url"], [type="tel"], [type="number"]),
          textarea, select {
            background-color: ${palette.raised} !important;
            color: ${palette.text} !important;
            border-color: ${palette.border} !important;
            caret-color: ${palette.accent} !important;
          }
          input::placeholder, textarea::placeholder {
            color: ${palette.muted} !important;
            opacity: 1 !important;
          }
          button, input:is([type="button"], [type="submit"], [type="reset"]) {
            background-color: ${palette.surface} !important;
            color: ${palette.accent} !important;
            border-color: ${palette.border} !important;
          }
          button:enabled:hover,
          input:is([type="button"], [type="submit"], [type="reset"]):enabled:hover {
            background-color: ${palette.raised} !important;
            border-color: ${palette.accent} !important;
          }
          :is(button, input, textarea, select):disabled {
            color: ${palette.muted} !important;
          }
          :focus-visible {
            outline: 2px solid ${palette.accent} !important;
            outline-offset: 2px !important;
          }
          dialog, [role="dialog"] {
            background-color: ${palette.surface} !important;
            color: ${palette.text} !important;
            border-color: ${palette.structure} !important;
          }
          pre, code, kbd, samp {
            background-color: ${palette.surface} !important;
            color: ${palette.text} !important;
            border-color: ${palette.border} !important;
          }
          pre :is(code, samp) {
            background-color: transparent !important;
          }
          ::selection {
            background-color: ${palette.selection} !important;
            color: ${palette.text} !important;
          }
          /* END NEON FLUX */
        '';
      };
  };
}
