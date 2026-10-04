{ lib, ... }:

let
  palette = builtins.fromJSON (builtins.readFile ./desktop/neon-flux-theme/palette.json);

  # Append alpha to #RRGGBB for Zed's #RRGGBBAA format. Alpha values follow
  # bundled One Dark: 0d/1a guides/tints, 4c/66 scrollbars/matches, 59/cc word diffs.
  alpha = value: token: "${token}${value}";

  # Match Konsole's faint (SGR 2) blend: halfway to the canvas for dim ANSI
  # slots and badge borders.
  channels =
    hex:
    map (offset: lib.fromHexString (builtins.substring offset 2 hex)) [
      1
      3
      5
    ];
  byte =
    value:
    let
      hex = lib.toHexString value;
    in
    if builtins.stringLength hex == 1 then "0${hex}" else hex;
  faint =
    token:
    "#"
    + lib.concatMapStrings byte (
      lib.zipListsWith (channel: canvas: builtins.div (channel + canvas) 2) (channels token) (
        channels palette.canvas
      )
    );

  # Match existing terminal ports; use their bright row where palette tokens are absent.
  ansi = {
    black = palette.surface;
    red = palette.error;
    green = palette.success;
    yellow = palette.warning;
    blue = palette.info;
    magenta = palette.purple;
    cyan = palette.accent;
    white = palette.text;
  };
  ansiBright = {
    black = "#53607A";
    red = "#FF6B81";
    green = "#6FFFD4";
    yellow = "#FFF28A";
    blue = "#74C0FF";
    magenta = "#D19CFF";
    cyan = palette.accentBright;
    white = "#FFFFFF";
  };
  ansiStyles = lib.listToAttrs (
    lib.mapAttrsToList (slot: colour: lib.nameValuePair "terminal.ansi.${slot}" colour) ansi
    ++ lib.mapAttrsToList (
      slot: colour: lib.nameValuePair "terminal.ansi.bright_${slot}" colour
    ) ansiBright
    ++ lib.mapAttrsToList (slot: colour: lib.nameValuePair "terminal.ansi.dim_${slot}" colour) (
      lib.mapAttrs (_: faint) ansi
    )
  );

  # Bundled themes use hue, 10% background tint and a dim border for status roles.
  badge = name: colour: {
    "${name}" = colour;
    "${name}.background" = alpha "1a" colour;
    "${name}.border" = faint colour;
  };
  badges = lib.mergeAttrsList [
    (badge "error" palette.error)
    (badge "warning" palette.warning)
    (badge "info" palette.info)
    (badge "hint" palette.muted)
    (badge "success" palette.success)
    (badge "conflict" palette.hot)
    (badge "created" palette.success)
    (badge "modified" palette.warning)
    (badge "renamed" palette.info)
    (badge "deleted" palette.error)
    # Keep non-diagnostic states muted rather than assigning diagnostic hues.
    (badge "hidden" palette.muted)
    (badge "ignored" palette.muted)
    (badge "unreachable" palette.comment)
    (badge "predictive" palette.comment)
  ];

  # Zed deserializes syntax entries as objects, not bare colours.
  fg = colour: { color = colour; };

  # Token names and style keys follow bundled One Dark in the pinned Zed version.
  syntax = {
    attribute = fg palette.warning;
    boolean = fg palette.hot;
    comment = {
      color = palette.comment;
      font_style = "italic";
    };
    # Distinguish doc comments using secondary text, without adding a palette token.
    "comment.doc" = {
      color = palette.muted;
      font_style = "italic";
    };
    constant = fg palette.hot;
    constructor = fg palette.info;
    embedded = fg palette.text;
    emphasis = {
      color = palette.text;
      font_style = "italic";
    };
    "emphasis.strong" = {
      color = palette.text;
      font_weight = 700;
    };
    enum = fg palette.info;
    function = fg palette.accent;
    hint = fg palette.muted;
    keyword = fg palette.purple;
    label = fg palette.hot;
    link_text = fg palette.structure;
    link_uri = fg palette.accentBright;
    namespace = fg palette.info;
    number = fg palette.hot;
    operator = fg palette.accentBright;
    predictive = {
      color = palette.comment;
      font_style = "italic";
    };
    preproc = fg palette.purple;
    primary = fg palette.text;
    property = fg palette.accentBright;
    punctuation = fg palette.muted;
    "punctuation.bracket" = fg palette.comment;
    "punctuation.delimiter" = fg palette.muted;
    "punctuation.list_marker" = fg palette.purple;
    "punctuation.markup" = fg palette.comment;
    "punctuation.special" = fg palette.hot;
    selector = fg palette.hot;
    "selector.pseudo" = fg palette.purple;
    string = fg palette.warning;
    "string.escape" = fg palette.hot;
    "string.regex" = fg palette.error;
    "string.special" = fg palette.warning;
    "string.special.symbol" = fg palette.hot;
    tag = fg palette.hot;
    "text.literal" = fg palette.warning;
    title = {
      color = palette.accent;
      font_weight = 700;
    };
    type = fg palette.info;
    variable = fg palette.text;
    "variable.parameter" = fg palette.text;
    "variable.special" = fg palette.hot;
    variant = fg palette.hot;
    "diff.plus" = fg palette.success;
    "diff.minus" = fg palette.error;
  };

  # Zed expects literal dotted style keys, not nested objects.
  style = lib.mergeAttrsList [
    {
      background = palette.canvas;
      "surface.background" = palette.surface;
      "elevated_surface.background" = palette.raised;

      "element.background" = palette.raised;
      "element.hover" = palette.border;
      "element.active" = palette.selection;
      "element.selected" = palette.selection;
      "element.disabled" = palette.surface;
      "ghost_element.background" = "#00000000";
      "ghost_element.hover" = palette.border;
      "ghost_element.active" = palette.selection;
      "ghost_element.selected" = palette.selection;
      "ghost_element.disabled" = palette.surface;
      "drop_target.background" = alpha "66" palette.structure;

      inherit (palette) border;
      "border.variant" = palette.raised;
      "border.focused" = palette.accent;
      "border.selected" = palette.structure;
      "border.disabled" = palette.raised;
      "border.transparent" = "#00000000";

      inherit (palette) text;
      "text.muted" = palette.muted;
      "text.placeholder" = palette.comment;
      "text.disabled" = palette.lineNumber;
      "text.accent" = palette.accent;
      icon = palette.text;
      "icon.muted" = palette.muted;
      "icon.disabled" = palette.lineNumber;
      "icon.placeholder" = palette.comment;
      "icon.accent" = palette.accent;

      "status_bar.background" = palette.surface;
      "title_bar.background" = palette.surface;
      "title_bar.inactive_background" = palette.canvas;
      "toolbar.background" = palette.canvas;
      "tab_bar.background" = palette.canvas;
      "tab.inactive_background" = palette.surface;
      "tab.active_background" = palette.canvas;
      "panel.background" = palette.surface;

      "search.match_background" = palette.selectionTranslucent;
      "search.active_match_background" = alpha "66" palette.hot;

      "scrollbar.thumb.background" = alpha "4c" palette.muted;
      "scrollbar.thumb.hover_background" = palette.selection;
      "scrollbar.thumb.border" = palette.raised;
      "scrollbar.track.background" = "#00000000";
      "scrollbar.track.border" = palette.surface;

      "editor.foreground" = palette.text;
      "editor.background" = palette.canvas;
      "editor.gutter.background" = palette.canvas;
      "editor.subheader.background" = palette.surface;
      "editor.active_line.background" = palette.currentLine;
      "editor.highlighted_line.background" = palette.currentLine;
      "editor.line_number" = palette.lineNumber;
      "editor.active_line_number" = palette.accent;
      "editor.hover_line_number" = palette.muted;
      "editor.invisible" = palette.lineNumber;
      "editor.wrap_guide" = alpha "0d" palette.border;
      "editor.active_wrap_guide" = alpha "1a" palette.border;
      "editor.document_highlight.read_background" = alpha "1a" palette.accent;
      "editor.document_highlight.write_background" = palette.selection;

      "terminal.background" = palette.canvas;
      "terminal.foreground" = palette.text;
      "terminal.bright_foreground" = "#FFFFFF";
      "terminal.dim_foreground" = palette.muted;

      "link_text.hover" = palette.accentBright;

      "version_control.added" = palette.success;
      "version_control.modified" = palette.warning;
      "version_control.deleted" = palette.error;
      "version_control.word_added" = alpha "59" palette.success;
      "version_control.word_deleted" = alpha "cc" palette.error;
      "version_control.conflict_marker.ours" = alpha "1a" palette.success;
      "version_control.conflict_marker.theirs" = alpha "1a" palette.info;
    }
    # Explicit focus borders avoid the inherited "no focus" appearance.
    {
      "panel.focused_border" = palette.structure;
      "pane.focused_border" = palette.structure;
    }
    ansiStyles
    badges
    {
      players =
        map
          (colour: {
            cursor = colour;
            background = colour;
            selection = alpha "3d" colour;
          })
          [
            palette.accent
            palette.hot
            palette.purple
            palette.info
            palette.success
            palette.warning
            palette.accentBright
            palette.error
          ];
    }
    { inherit syntax; }
  ];

  theme = {
    name = "Neon Flux";
    author = "miko";
    themes = [
      {
        name = "Neon Flux";
        appearance = "dark";
        inherit style;
      }
    ];
  };
in
{
  den.aspects.zed.homeManager =
    { pkgs, ... }:
    {
      fonts.fontconfig.enable = true;
      home.packages = with pkgs.nerd-fonts; [
        jetbrains-mono
        blex-mono
      ];

      programs.zed-editor = {
        enable = true;

        # extraPackages puts nixd on the editor's PATH for the Nix extension.
        extraPackages = [ pkgs.nixd ];

        # Auto-installed on first start; built-in languages need no extension entry.
        extensions = [
          "nix" # Nix syntax + nixd
          "just" # Justfile, the task runner this repository uses
          "toml" # Cargo.toml and friends
          "git-firefly" # inline blame in the gutter
          "color-highlight" # paints #RRGGBB literals inline
        ];

        themes.neon-flux = theme;

        # Keep default mutableUserSettings for GUI edits. Its shallow merge replaces
        # configured top-level keys wholesale and preserves other settings.
        userSettings = {
          theme = {
            mode = "dark";
            dark = "Neon Flux";
            light = "Neon Flux";
          };

          buffer_font_family = "JetBrainsMono NFM";
          buffer_font_fallbacks = [
            "BlexMono Nerd Font Mono"
            "monospace"
          ];
          # JetBrains Mono keeps its ligatures in `calt`, not `liga`.
          buffer_font_features = {
            calt = 1;
            zero = 1;
          };

          terminal = {
            font_family = "BlexMono Nerd Font Mono";
            font_fallbacks = [
              "JetBrainsMono NFM"
              "monospace"
            ];
          };
        };
      };
    };
}
