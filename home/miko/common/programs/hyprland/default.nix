{ wallpapers, pkgs, split-monitor-workspaces, ... }:

let
  terminal = "${pkgs.kitty}/bin/kitty";
  browser = "${pkgs.firefox}/bin/firefox";
  launcher = "${pkgs.rofi-wayland}/bin/rofi -show run";
  editor = "${pkgs.emacs29-pgtk}/bin/emacsclient -a '' -c";
  polkitAgent =
    "${pkgs.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1";
in {
  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.plugins = [
    split-monitor-workspaces.packages.${pkgs.system}.split-monitor-workspaces
  ];
  wayland.windowManager.hyprland.extraConfig = ''
     # Autostart settings
     exec-once = ${polkitAgent}
     exec-once = ${pkgs.emacs29-pgtk}/bin/emacs --daemon
     exec = ${
       pkgs.writeShellScriptBin "change-wallpaper"
       (builtins.readFile ./change-wallpaper.sh)
     }/bin/change-wallpaper ${wallpapers}/gruvbox
     exec = ${
       pkgs.writeShellScriptBin "waybar-launcher"
       (builtins.readFile ./waybar-launcher.sh)
     }/bin/waybar-launcher
     exec-once = ${pkgs.networkmanagerapplet}/bin/nm-applet
     exec-once = ${pkgs.mako}/bin/mako;

     # Keybindings
     $mod = SUPER
     bind = $mod, Q, exec, ${terminal}
     bind = $mod, W, exec, ${browser}
     bind = $mod, R, exec, ${launcher}
     bind = $mod, E, exec, ${editor}

     bind = $mod SHIFT, C, killactive
     bind = $mod, V, togglefloating,

     bind = $mod, h, movefocus, l
     bind = $mod, l, movefocus, r
     bind = $mod, k, movefocus, u
     bind = $mod, j, movefocus, d

     bind = $mod SHIFT, h, movewindow, l
     bind = $mod SHIFT, l, movewindow, r
     bind = $mod SHIFT, k, movewindow, u
     bind = $mod SHIFT, j, movewindow, d

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

     bind = $mod, RETURN, layoutmsg, swapwithmaster

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
     }

    # General Hyprland variables
    general {
      gaps_in = 5
      gaps_out = 20
      border_size = 3
      col.active_border = rgba(8ec07cee)
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

    plugin {
      split-monitor-workspaces {
          count = 3
      }
    }

    # Switch workspaces with mod + [1-3]
    bind = $mod, 1, split-workspace, 1
    bind = $mod, 2, split-workspace, 2
    bind = $mod, 3, split-workspace, 3

    # Move active window to a workspace with mod + SHIFT + [1-3]
    bind = $mod SHIFT, 1, split-movetoworkspacesilent, 1
    bind = $mod SHIFT, 2, split-movetoworkspacesilent, 2
    bind = $mod SHIFT, 3, split-movetoworkspacesilent, 3

    # Send window to the next monitor in line
    bind = $mod SHIFT, period, split-changemonitor, next
  '';
}

