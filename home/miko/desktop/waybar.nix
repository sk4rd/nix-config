{ ... }:

{
  # Waybar configuration
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        output = [ "DP-1" ];
        "temperature" = { hwmon-path = "/sys/class/hwmon/hwmon5/temp1_input"; };
      };
    };
  };
}
