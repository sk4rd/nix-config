{ ... }:

{
  wayland.windowManager.hyprland.extraConfig = ''
    # Autostart settings
    # Screen settings
    monitor = DP-1, 2560x1440@165, 1920x0, 1
    monitor = HDMI-A-1, 1920x1080@60, 0x0, 1

    # Input settings
    input {
      tablet {
        output = DP-1
      }
    }
  '';
}

