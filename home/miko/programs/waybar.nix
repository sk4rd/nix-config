{ pkgs, ... }:

{
  # Waybar configuration
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        output = [ "DP-1" ];
        modules-left =
          [ "hyprland/workspaces" "wlr/taskbar" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [ "temperature" "tray" ];
        "clock" = { format = "{:%H:%M %d.%m %a}"; };
        "temperature" = { hwmon-path = "/sys/class/hwmon/hwmon4/temp1_input"; };
        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
        };
      };
    };
  };
}

