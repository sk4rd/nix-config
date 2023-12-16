{ lib, ... }:

{
  # Waybar configuration
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        output = [ "DP-1" ];
        modules-right = lib.mkAfter [ "tray" ];

        "temperature" = {
          hwmon-path =
            "/sys/devices/platform/PNP0C14:00/wmi_bus/wmi_bus-PNP0C14:00/DEADBEEF-2001-0000-00A0-C90629100000/hwmon/hwmon5/temp3_input";
        };
      };
    };
  };
}
