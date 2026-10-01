{ lib, ... }:

let
  # Keep exact Neon Flux hex tokens in one place; KColorScheme and Konsole both
  # want decimal RGB.
  palette = builtins.fromJSON (builtins.readFile ./neon-flux-theme/palette.json);

  # KColorScheme and Konsole both read colours as decimal `r,g,b` — that is what
  # every *.colors, kdeglobals and *.colorscheme entry on disk looks like. The
  # arithmetic below stays integer for the same reason.
  channels =
    hex:
    map (offset: lib.fromHexString (builtins.substring offset 2 hex)) [
      1
      3
      5
    ];
  toRgb = hex: lib.concatMapStringsSep "," toString (channels hex);
  rgb = lib.mapAttrs (_: toRgb) palette;

  # Faint (SGR 2) variants are derived, not a second palette: every ANSI colour
  # stepped half-way back to the canvas.
  faint =
    hex:
    lib.concatMapStringsSep "," toString (
      lib.zipListsWith (channel: canvas: builtins.div (channel + canvas) 2) (channels hex) (
        channels palette.canvas
      )
    );

  colors = background: alternate: {
    BackgroundNormal = background;
    BackgroundAlternate = alternate;
    DecorationFocus = rgb.accent;
    DecorationHover = rgb.accentBright;
    ForegroundNormal = rgb.text;
    ForegroundInactive = rgb.muted;
    ForegroundActive = rgb.accent;
    ForegroundLink = rgb.info;
    ForegroundVisited = rgb.purple;
    ForegroundNegative = rgb.error;
    ForegroundNeutral = rgb.warning;
    ForegroundPositive = rgb.success;
  };

  colorScheme = {
    General = {
      Name = "Neon Flux";
      ColorScheme = "NeonFlux";
      shadeSortColumn = true;
    };
    KDE.contrast = 4;

    "Colors:View" = colors rgb.canvas rgb.currentLine;
    "Colors:Window" = colors rgb.surface rgb.raised;
    "Colors:Button" = colors rgb.raised rgb.border;
    "Colors:Selection" = colors rgb.selection rgb.border;
    "Colors:Tooltip" = colors rgb.raised rgb.surface;
    "Colors:Complementary" = colors rgb.canvas rgb.surface;
    "Colors:Header" = colors rgb.surface rgb.canvas;

    "ColorEffects:Disabled" = {
      Color = rgb.muted;
      ColorAmount = 0;
      ColorEffect = 0;
      ContrastAmount = 0.65;
      ContrastEffect = 1;
      IntensityAmount = 0.1;
      IntensityEffect = 2;
    };
    "ColorEffects:Inactive" = {
      Enable = false;
      ChangeSelectionColor = false;
      Color = rgb.surface;
      ColorAmount = 0;
      ColorEffect = 0;
      ContrastAmount = 0;
      ContrastEffect = 0;
      IntensityAmount = 0;
      IntensityEffect = 0;
    };
    WM = {
      activeBackground = rgb.surface;
      activeBlend = rgb.structure;
      activeForeground = rgb.text;
      inactiveBackground = rgb.canvas;
      inactiveBlend = rgb.border;
      inactiveForeground = rgb.muted;
    };
  };

  # Konsole keeps its terminal palette in *.colorscheme files (a KConfig with one
  # section per ANSI slot), never in the application colour scheme above. The
  # ANSI table is the one the Windows Terminal port ships
  # (parts/terminal/install.ps1 in the neon-flux repo); slots that are palette
  # roles are named here instead of being repeated as literals.
  ansi = [
    palette.surface # black
    palette.error # red
    palette.success # green
    palette.warning # yellow
    palette.info # blue
    palette.purple # purple
    palette.accent # cyan
    palette.text # white
  ];
  ansiBright = [
    "#53607A"
    "#FF6B81"
    "#6FFFD4"
    "#FFF28A"
    "#74C0FF"
    "#D19CFF"
    palette.accentBright
    "#FFFFFF"
  ];

  numbered =
    prefix: suffix: entries:
    lib.listToAttrs (
      lib.imap0 (index: hex: lib.nameValuePair "${prefix}${toString index}${suffix}" hex) entries
    );

  konsoleScheme = lib.generators.toINI { } (
    # Every ANSI slot ends up as `Color = <r>,<g>,<b>`; the values are converted
    # once, before the sections are built.
    lib.mapAttrs (_: value: { Color = value; }) (
      (lib.mapAttrs (_: toRgb) {
        # Neon Flux paints exactly one terminal background, so every background
        # variant is the canvas.
        Background = palette.canvas;
        BackgroundIntense = palette.canvas;
        BackgroundFaint = palette.canvas;
        Foreground = palette.text;
        ForegroundIntense = "#FFFFFF"; # bold text: the ANSI bright white
        ForegroundFaint = palette.muted;
      })
      // numbered "Color" "" (map toRgb ansi)
      // numbered "Color" "Intense" (map toRgb ansiBright)
      // numbered "Color" "Faint" (map faint ansi)
    )
    // {
      General = {
        Description = "Neon Flux";
        Opacity = 1;
        Blur = false;
        Wallpaper = "";
      };
    }
  );

  # Profile keys and their groups come from Profile.cpp in the Konsole sources.
  # This theme's NixOS component installs the font (nerd-fonts.blex-mono);
  # Konsole falls back silently if only the Home Manager component is used
  # without the font installed separately.
  konsoleProfile = lib.generators.toINI { } {
    General = {
      Name = "Neon Flux";
      # The hostname leads the tab title, and with ShowWindowTitleOnTitleBar
      # disabled the window caption follows it, so "desktop : nix-config" is what
      # the tab, KWin and the taskbar all show.
      LocalTabTitleFormat = "%h : %d";
      # A remote tab has no local working directory to report: "%U%h" is
      # "user@host", or the bare host when ssh was given no user.
      RemoteTabTitleFormat = "%U%h";
    };
    Appearance = {
      ColorScheme = "Neon Flux";
      # BlexMono at one point below the Windows Terminal profile's 11.
      Font = "BlexMono Nerd Font Mono,10,-1,5,50,0,0,0,0,0";
      TabColor = toRgb palette.accent; # bar drawn across the top of the tab
    };
    "Cursor Options" = {
      UseCustomCursorColor = true;
      CursorShape = 1; # I-beam, i.e. the bar cursor the theme asks for
      CustomCursorColor = toRgb palette.accent;
      CustomCursorTextColor = toRgb palette.canvas;
    };
  };
in
{
  den.aspects.neon-flux-theme.nixos = { pkgs, ... }: {
    services.displayManager.sddm = {
      theme = "neon-flux";
      extraPackages = [ pkgs.qt6.qtdeclarative ];
    };
    environment.systemPackages = [
      (pkgs.runCommand "sddm-neon-flux" { } ''
        theme="$out/share/sddm/themes/neon-flux"
        mkdir -p "$theme"
        cp ${./neon-flux-theme/sddm/Main.qml} "$theme/Main.qml"
        cp ${./neon-flux-theme/sddm/metadata.desktop} "$theme/metadata.desktop"
        cp ${./neon-flux-theme/neon-flux-desktop-3840x2160.png} "$theme/background.png"
        cp ${
          pkgs.writeText "neon-flux-sddm.conf" (lib.generators.toINI { } { General = palette; })
        } "$theme/theme.conf"
      '')
    ];
    fonts.packages = [ pkgs.nerd-fonts.blex-mono ];
  };

  den.aspects.neon-flux-theme.homeManager =
    { pkgs, ... }:
    let
      # A mirrored composition distinguishes the lock screen from the desktop.
      lockscreenWallpaper =
        pkgs.runCommand "neon-flux-lockscreen.png"
          {
            nativeBuildInputs = [ (pkgs.python3.withPackages (ps: [ ps.pillow ])) ];
          }
          ''
            python -c 'from PIL import Image, ImageOps; import sys; ImageOps.mirror(Image.open(sys.argv[1])).save(sys.argv[2], format="PNG")' ${./neon-flux-theme/neon-flux-desktop-3840x2160.png} "$out"
          '';
    in
    {
      # Apply through Plasma's supported API, rather than hardcoding mutable
      # containment/monitor IDs in plasma-org.kde.plasma.desktop-appletsrc.
      # The user unit runs after plasmashell on every graphical login; its store
      # image path also changes the unit when a new wallpaper is generated.
      systemd.user.services.neon-flux-wallpaper = {
        Unit = {
          Description = "Neon Flux desktop wallpaper";
          After = [ "plasma-plasmashell.service" ];
          Requisite = [ "plasma-plasmashell.service" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-wallpaperimage --fill-mode preserveAspectCrop ${./neon-flux-theme/neon-flux-desktop-3840x2160.png}";
        };
        Install.WantedBy = [ "plasma-workspace.target" ];
      };

      xdg.dataFile = {
        "wallpapers/NeonFlux/neon-flux-desktop-3840x2160.png".source =
          ./neon-flux-theme/neon-flux-desktop-3840x2160.png;
        "wallpapers/NeonFlux/neon-flux-lockscreen-3840x2160.png".source = lockscreenWallpaper;
        "color-schemes/NeonFlux.colors".text = lib.generators.toINI { } colorScheme;

        # Konsole reads its terminal palette and its profiles from
        # ~/.local/share/konsole, and in Konsole a colour scheme's name *is* its
        # file name — so this artifact is "Neon Flux" while the application scheme
        # above is "NeonFlux". Both files are generated from palette.json and are
        # named the way Konsole names them itself ("<Name>.profile"), so they stay
        # theme artifacts: the profile editor writes its own copy to these paths,
        # and force keeps the module's copy authoritative instead of failing the
        # next activation over a clobbered file.
        "konsole/Neon Flux.colorscheme" = {
          force = true;
          text = konsoleScheme;
        };
        "konsole/Neon Flux.profile" = {
          force = true;
          text = konsoleProfile;
        };
      };

      # Modify only these keys via Home Manager's kwriteconfig6 activation, not
      # immutable config symlinks. KDE can keep writing unrelated preferences.
      # Install the palette as well as its name: activation may run without Plasma.
      qt.kde.settings = {
        # Keep KDE's stock secure unlock UI, which inherits the Complementary
        # palette below. Only appearance keys are touched: no Daemon/PAM changes.
        kscreenlockerrc = {
          Greeter.WallpaperPlugin = "org.kde.image";
          Greeter.Wallpaper."org.kde.image".General = {
            Image = "file://${lockscreenWallpaper}";
            FillMode = 2; # PreserveAspectCrop
          };
        };

        kdeglobals = (builtins.removeAttrs colorScheme [ "General" ]) // {
          General = {
            ColorScheme = "NeonFlux";
            AccentColor = rgb.accent;
            shadeSortColumn = true;
          };
          KDE = colorScheme.KDE // {
            widgetStyle = "Breeze";
          };
        };

        # Adaptive Breeze follows kdeglobals; breeze-dark has fixed upstream colors.
        plasmarc.Theme.name = "default";
        kwinrc."org.kde.kdecoration2" = {
          library = "org.kde.breeze";
          theme = "Breeze";
        };

        # The hostname indicator lives in the tab title, so the tab bar must not
        # hide itself in a single-tab window. The window caption is the tab title.
        konsolerc = {
          "Desktop Entry".DefaultProfile = "Neon Flux.profile";
          TabBar = {
            TabBarVisibility = "AlwaysShowTabBar";
            TabBarPosition = "Top";
          };
          KonsoleWindow.ShowWindowTitleOnTitleBar = false;
        };
      };
    };
}
