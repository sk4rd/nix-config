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
  '';
}

