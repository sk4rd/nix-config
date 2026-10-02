{ lib, ... }:

let
  # The canonical Neon Flux tokens, shared with every other surface in this
  # repository (KDE, Konsole, Firefox, SilverBullet).
  palette = builtins.fromJSON (builtins.readFile ./desktop/neon-flux-theme/palette.json);

  # Zed colours are 8-digit `#RRGGBBAA` and the palette is 6-digit, so a
  # translucent variant appends an alpha byte instead of hand-mixing a colour.
  # The alphas below are the ones the bundled One Dark theme uses for the same
  # kinds of surface: 0d/1a for guides and tints, 4c/66 for scrollbars and
  # match highlights, 59/cc for word-level diffs.
  alpha = value: token: "${token}${value}";

  # Half-way back to the canvas: the same derivation the Konsole palette uses
  # for its faint (SGR 2) slots. Zed wants a dim value for the terminal's
  # `dim_*` slots and for the border of a tinted badge, where the full-strength
  # hue would shout.
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

  # The ANSI table of the existing terminal ports (Windows Terminal scheme,
  # Konsole colour scheme): palette roles where one exists, the terminal
  # scheme's own bright row where the palette has no token for it (the spec's
  # bright black is the raised grey, the rest are lighter takes on the hues
  # above).
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

  # A status/badge colour is three keys — the hue, a 10% tint behind it, and a
  # border derived back towards the canvas — the shape the bundled themes use
  # for the status, version-control and diagnostic roles.
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
    # These four are not diagnostics: hidden, ignored, unreachable and
    # predictive are deliberately quiet, so they stay on the muted ramp
    # instead of taking a hue of their own.
    (badge "hidden" palette.muted)
    (badge "ignored" palette.muted)
    (badge "unreachable" palette.comment)
    (badge "predictive" palette.comment)
  ];

  # A syntax entry is an object, never a bare colour: the bundled One Dark theme
  # writes `{ color, font_style, font_weight }` for all 46 tokens, and that is
  # the shape the theme deserializer reads. `fg` is the colour-only form of it.
  fg = colour: { color = colour; };

  # Syntactic roles. The names are Zed's own token vocabulary — taken from the
  # bundled One Dark theme of the pinned Zed version, which is also the only
  # authority for the style keys above — and the colours follow the role
  # mapping the VS Code port uses (decorators yellow, keywords violet, functions
  # cyan, properties accent-bright, literals hot pink, comments italic grey).
  syntax = {
    attribute = fg palette.warning;
    boolean = fg palette.hot;
    comment = {
      color = palette.comment;
      font_style = "italic";
    };
    # Doc comments step up to the secondary text grey rather than a comment
    # variant of their own, so the palette keeps its single comment colour.
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

  # Key names are literal Zed style keys (`surface.background`, not a nested
  # object), which is why the dotted names are quoted rather than nested.
  style = lib.mergeAttrsList [
    {
      background = palette.canvas;
      "surface.background" = palette.surface;
      "elevated_surface.background" = palette.raised;

      # Interactive chrome: raised fills, hover one step up, selection the
      # theme's selection blue, focus cyan.
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

      # The title bar, the tab bar and the panels carry the chrome; the editor
      # keeps the canvas to itself.
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
    # Focus rings are the exception the bundled themes also make: an inherited
    # border reads as "no focus" and the pane keeps its own outline.
    {
      "panel.focused_border" = palette.structure;
      "pane.focused_border" = palette.structure;
    }
    ansiStyles
    badges
    {
      # Multiplayer cursor colours, in accent order.
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
      # The theme asks for JetBrainsMono NFM in the editor and BlexMono in the
      # terminal — the same two families every other Neon Flux surface uses, so
      # install them for this home rather than relying on the machine.
      fonts.fontconfig.enable = true;
      home.packages = with pkgs.nerd-fonts; [
        jetbrains-mono
        blex-mono
      ];

      programs.zed-editor = {
        enable = true;

        # `nixd` is the language server the `nix` extension talks to (it also
        # accepts `nil`). extraPackages wraps the editor with a PATH that
        # carries it, so no machine-level install is needed for the LSP.
        extraPackages = [ pkgs.nixd ];

        # Installed on Zed's first start (auto_install_extensions). Rust,
        # Python, Markdown, YAML, JSON, TypeScript, Bash, C/C++, CSS and Go are
        # built in and need no entry here.
        extensions = [
          "nix" # Nix syntax + nixd
          "just" # Justfile, the task runner this repository uses
          "toml" # Cargo.toml and friends
          "git-firefly" # inline blame in the gutter
          "color-highlight" # paints #RRGGBB literals inline
        ];

        # One theme, not two: the family carries a single dark appearance and
        # both mode slots point at it, so nothing falls back to a stock theme.
        themes.neon-flux = theme;

        # Zed's own GUI also writes settings.json, so the module keeps its
        # impure merge (mutableUserSettings stays at its default). That merge is
        # shallow by top-level key: the `theme`, `terminal` and `buffer_font_*`
        # objects below replace whatever the GUI put in those same objects,
        # while every other key in the file survives.
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
