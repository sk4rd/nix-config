{ config, pkgs, ... }:

let
  terminal = "${pkgs.kitty}/bin/kitty";
  browser = "${pkgs.firefox}/bin/firefox";
  launcher = "${pkgs.rofi-wayland}/bin/rofi -show run";
in {
  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.extraConfig = ''
     # Screen settings
     monitor = DP-1, 2560x1440@165, 1920x0, 1
     monitor = HDMI-A-1, 1920x1080@60, 0x0, 1

     # Keybindings
     $mod = SUPER
     bind = $mod, Q, exec, ${terminal}
     bind = $mod, W, exec, ${browser}
     bind = $mod, R, exec, ${launcher}

     # Input device settings
     input {
       kb_layout = us
       follow_mouse = 1
       accel_profile = flat
     }

    # General Hyprland variables
    general {
      gaps_in = 5
      gaps_out = 20
      border_size = 3
      col.active_border = rgba(fabd2fee) rgba(fe8019ee) 90deg
      col.inactive_border = rgba(282828aa)
      cursor_inactive_timeout = 5
      layout = master
      allow_tearing = false
    }

    # Decoration and blur settings
    decoration {
      rounding = 10

      blur {
        enabled = true
        size = 4
        passes = 1
        vibrancy = 0.17
      }
    }
  '';
}

