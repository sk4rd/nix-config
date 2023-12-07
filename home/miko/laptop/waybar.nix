{ lib, ... }:

{
  # Waybar configuration
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        output = [ "eDP-1" ];
        modules-right = lib.mkAfter [ "battery" "tray" ];
        "temperature" = {
          hwmon-path =
            "/sys/devices/platform/thinkpad_hwmon/hwmon/hwmon5/temp1_input";
        };
        "battery" = {
          states = {
            warning = 25;
            critical = 10;
          };
          format = "{icon}  {capacity}%";
          format-icons = [ "" "" "" "" "" ];
        };
      };
    };
  };
}
