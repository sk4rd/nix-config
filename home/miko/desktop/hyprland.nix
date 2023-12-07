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

    # Workspace settings
    workspace = 1, monitor:DP-1
    workspace = 2, monitor:DP-1
    workspace = 3, monitor:DP-1
    workspace = 4, monitor:HDMI-A-1
    workspace = 5, monitor:HDMI-A-1
    workspace = 6, monitor:HDMI-A-1
  '';
}

