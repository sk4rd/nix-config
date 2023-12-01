{ config, pkgs, ... }:

{
  wayland.windowManager.hyprland.extraConfig = ''
    # Keybindings
    $mod = SUPER
    bind = $mod, W, exec, firefox
    bind = $mod, R, exec, rofi -show run
  '';
}

