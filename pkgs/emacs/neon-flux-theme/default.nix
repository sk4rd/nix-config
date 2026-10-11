{ trivialBuild, writeText }:

let
  palette = builtins.fromJSON (builtins.readFile ../../../themes/neon-flux/palette.json);
  tokens = builtins.attrNames palette;
  theme = builtins.replaceStrings (map (token: "\"@${token}@\"") tokens) (map (
    token: builtins.toJSON palette.${token}
  ) tokens) (builtins.readFile ./neon-flux-theme.el);
in
trivialBuild {
  pname = "neon-flux-theme";
  version = "0.1.0";
  src = writeText "neon-flux-theme.el" theme;
  turnCompilationWarningToError = true;
}
