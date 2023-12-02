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

     bind = $mod SHIFT, C, killactive
     bind = $mod, V, togglefloating,

     bind = $mod, h, movefocus, l
     bind = $mod, l, movefocus, r
     bind = $mod, k, movefocus, u
     bind = $mod, j, movefocus, d

     bind = $mod, 1, workspace, 1
     bind = $mod, 2, workspace, 2
     bind = $mod, 3, workspace, 3
     bind = $mod, 4, workspace, 4
     bind = $mod, 5, workspace, 5
     bind = $mod, 6, workspace, 6
     bind = $mod, 7, workspace, 7
     bind = $mod, 8, workspace, 8
     bind = $mod, 9, workspace, 9
     bind = $mod, 0, workspace, 10

     bind = $mod SHIFT, 1, movetoworkspace, 1
     bind = $mod SHIFT, 2, movetoworkspace, 2
     bind = $mod SHIFT, 3, movetoworkspace, 3
     bind = $mod SHIFT, 4, movetoworkspace, 4
     bind = $mod SHIFT, 5, movetoworkspace, 5
     bind = $mod SHIFT, 6, movetoworkspace, 6
     bind = $mod SHIFT, 7, movetoworkspace, 7
     bind = $mod SHIFT, 8, movetoworkspace, 8
     bind = $mod SHIFT, 9, movetoworkspace, 9
     bind = $mod SHIFT, 0, movetoworkspace, 10

     bind = $mod, S, togglespecialworkspace, magic
     bind = $mod SHIFT, S, movetoworkspace, special:magic

     bindm = $mod, mouse:272, movewindow
     bindm = $mod, mouse:273, resizewindow

     # Input device settings
     input {
       kb_layout = us,de
       kb_options=grp:win_space_toggle
       follow_mouse = 1
       accel_profile = flat

       touchpad {
         disable_while_typing = true
         natural_scroll = true
         clickfinger_behavior = true
         tap-to-click = true
       }
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

    # Animation settings
    animations {
      enabled = true
      bezier = myBezier, 0.05, 0.9, 0.1, 1.05

      animation = windows, 1, 7, myBezier
      animation = windowsOut, 1, 7, default, popin 80%
      animation = border, 1, 10, default
      animation = borderangle, 1, 8, default
      animation = fade, 1, 7, default
      animation = workspaces, 1, 6, default
    }


  '';
}

