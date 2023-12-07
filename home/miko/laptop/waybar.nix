{ lib, ... }:

{
  # Waybar configuration
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        output = [ "eDP-1" ];
        modules-right = lib.mkAfter [ "battery" ];
        "temperature" = { hwmon-path = "/sys/class/hwmon/hwmon2/temp1_input"; };
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
