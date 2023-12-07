{ config, ... }:

{
  # Waybar configuration
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        output = [ "eDP-1" ];
        "temperature" = { hwmon-path = "/sys/class/hwmon/hwmon2/temp1_input"; };
      };
    };
  };
}
