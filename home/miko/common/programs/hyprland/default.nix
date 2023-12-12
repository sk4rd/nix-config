{ wallpapers, pkgs, ... }:

let
  # PolicyKit authentication daemon
  polkitAgent =
    "${pkgs.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1";

  # Wallpaper slideshow daemon
  wallpaperTheme = "gruvbox";
  wallpaperChanger = "${
      pkgs.writeShellScriptBin "change-wallpaper"
      (builtins.readFile ./change-wallpaper.sh)
    }/bin/change-wallpaper ${wallpapers}/${wallpaperTheme}";

  # Emacs daemon and client for editing files
  emacsDaemon = "${pkgs.emacs29-pgtk}/bin/emacs --daemon";
  emacsClient = "${pkgs.emacs29-pgtk}/bin/emacsclient -a '' -c";

  # Wayland status bar
  waybar = "${pkgs.waybar}/bin/waybar";

  # Notification daemon
  mako = "${pkgs.mako}/bin/mako";

  # Network manager applet
  nm-applet = "${pkgs.networkmanagerapplet}/bin/nm-applet";

  # Programs
  kitty = "${pkgs.kitty}/bin/kitty";
  firefox = "${pkgs.firefox}/bin/firefox";
  rofi = "${pkgs.rofi-wayland}/bin/rofi -show run";
in {
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    settings = {
      # Autostarted programs
      exec-once =
        [ polkitAgent emacsDaemon wallpaperChanger waybar mako nm-applet ];

      # Modifier key set to SUPER
      "$mod" = "SUPER";

      # Keybindings
      bind = [
        # Programs
        "$mod, Q, exec, ${kitty}"
        "$mod, R, exec, ${rofi}"
        "$mod, W, exec, ${firefox}"
        "$mod, E, exec, ${emacsClient}"

        # Workspace navigation/window movement
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"
        "$mod, S, togglespecialworkspace, magic"

        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"
        "$mod SHIFT, S, movetoworkspace, special:magic"

        # Window navigation/movement
        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"

        "$mod SHIFT, h, movewindow, l"
        "$mod SHIFT, l, movewindow, r"
        "$mod SHIFT, k, movewindow, u"
        "$mod SHIFT, j, movewindow, d"

        # Window management
        "$mod SHIFT, C, killactive"
        "$mod, V, togglefloating,"
        "$mod, RETURN, layoutmsg, swapwithmaster"
      ];

      # Mouse bindings
      bindm = [
        # Window resizing
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Input device configuration
      input = {
        kb_layout = "us,de";
        kb_options = "grp:win_space_toggle"; # Toggle layout with SUPER + Space
        follow_mouse = 1;
        accel_profile = "flat"; # Disable pointer acceleration
      };

      # Settings regarding looks
      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 3;
        "col.active_border" = "rgba(8ec07cee)";
        "col.inactive_border" = "rgba(282828aa)";
        cursor_inactive_timeout = 5;
        layout = "master";
        allow_tearing = false;
      };

      # Settings regarding decoration
      decoration = {
        rounding = 10;

        # Enable blurring of transparent elements
        blur = {
          enabled = true;
          size = 4;
          passes = 1;
          vibrancy = "0.17";
        };
      };

      # Settings regarding animation
      animations = {
        enabled = true;
        # Bezier curve definition
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

        # Animation defintions
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };
    };
  };
}

