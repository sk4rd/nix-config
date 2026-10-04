{ den, lib, ... }:

let

  palette = builtins.fromJSON (builtins.readFile ./neon-flux-theme/palette.json);

  # KColorScheme and Konsole require decimal `r,g,b` channels.
  channels =
    hex:
    map (offset: lib.fromHexString (builtins.substring offset 2 hex)) [
      1
      3
      5
    ];
  toRgb = hex: lib.concatMapStringsSep "," toString (channels hex);
  rgb = lib.mapAttrs (_: toRgb) palette;

  # SGR 2 (faint) blends each ANSI colour halfway toward the canvas.
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

  # ANSI order matches the Neon Flux Windows Terminal port (parts/terminal/install.ps1).
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
    # Konsole requires a separate KConfig section with a Color key for each slot.
    lib.mapAttrs (_: value: { Color = value; }) (
      (lib.mapAttrs (_: toRgb) {

        Background = palette.canvas;
        BackgroundIntense = palette.canvas;
        BackgroundFaint = palette.canvas;
        Foreground = palette.text;
        ForegroundIntense = "#FFFFFF";
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

  # Profile keys/groups are defined in Konsole's Profile.cpp.
  konsoleProfile = lib.generators.toINI { } {
    General = {
      Name = "Neon Flux";
      # %h = hostname; %d = working directory basename.
      LocalTabTitleFormat = "%h : %d";
      # %U adds user@ when SSH specifies a user; %h is the remote host.
      RemoteTabTitleFormat = "%U%h";
    };
    Appearance = {
      ColorScheme = "Neon Flux";

      Font = "BlexMono Nerd Font Mono,10,-1,5,50,0,0,0,0,0";
      TabColor = toRgb palette.accent;
    };
    "Cursor Options" = {
      UseCustomCursorColor = true;
      CursorShape = 1; # I-beam
      CustomCursorColor = toRgb palette.accent;
      CustomCursorTextColor = toRgb palette.canvas;
    };
  };
in
{
  den.aspects = {
    plasma-neon-flux-theme = {
      includes = [ den.aspects.plasma ];

      homeManager.qt.kde.settings = {
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
      };
      homeManager.xdg.dataFile."color-schemes/NeonFlux.colors".text =
        lib.generators.toINI { }
          colorScheme;
    };

    konsole-neon-flux-theme.homeManager =
      { pkgs, ... }:
      {
        fonts.fontconfig.enable = true;
        home.packages = [
          pkgs.nerd-fonts.blex-mono
          pkgs.kdePackages.konsole
        ];

        xdg.dataFile = {
          # Konsole resolves scheme/profile names by filename ("Neon Flux", not "NeonFlux").
          # Its editor can replace these files; force keeps activation authoritative.
          "konsole/Neon Flux.colorscheme" = {
            force = true;
            text = konsoleScheme;
          };
          "konsole/Neon Flux.profile" = {
            force = true;
            text = konsoleProfile;
          };
        };

        # Keep the hostname visible with one tab; use the tab title as the window caption.
        qt.kde.settings.konsolerc = {
          "Desktop Entry".DefaultProfile = "Neon Flux.profile";
          TabBar = {
            TabBarVisibility = "AlwaysShowTabBar";
            TabBarPosition = "Top";
          };
          KonsoleWindow.ShowWindowTitleOnTitleBar = false;
        };
      };

    sddm-neon-flux-theme.nixos = { pkgs, ... }: {
      services.displayManager.sddm = {
        enable = true;
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

    wallpaper-neon-flux-theme = {
      includes = [ den.aspects.plasma ];

      homeManager =
        { pkgs, ... }:
        {
          # Plasma's API avoids hardcoding mutable containment/monitor IDs.
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

          xdg.dataFile."wallpapers/NeonFlux/neon-flux-desktop-3840x2160.png".source =
            ./neon-flux-theme/neon-flux-desktop-3840x2160.png;
        };
    };

    lockscreen-neon-flux-theme = {
      includes = [ den.aspects.plasma ];

      homeManager =
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
          xdg.dataFile."wallpapers/NeonFlux/neon-flux-lockscreen-3840x2160.png".source = lockscreenWallpaper;

          # kwriteconfig6 leaves unrelated KDE preferences writable.
          # Install palette values too: activation may run without Plasma.
          qt.kde.settings.kscreenlockerrc = {
            # Preserve the stock unlock UI and Daemon/PAM settings; it inherits Complementary colors.
            Greeter.WallpaperPlugin = "org.kde.image";
            Greeter.Wallpaper."org.kde.image".General = {
              Image = "file://${lockscreenWallpaper}";
              FillMode = 2; # PreserveAspectCrop
            };
          };
        };
    };
  };
}
