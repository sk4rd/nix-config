{ ... }:

{
  programs.waybar = {
    enable = true;
    systemd.enable = false;
    style = ./waybar/style.css;

    settings.main = {
      layer = "top";
      position = "top";
      height = 30;
      spacing = 0;
      modules-left = [ "ext/workspaces" ];
      modules-right = [
        "cpu"
        "memory"
        "temperature"
        "pulseaudio"
        "network"
        "clock"
      ];

      "ext/workspaces" = {
        "format" = "{id}";
        "ignore-hidden" = true;
        "sort-by-id" = true;
        "all-outputs" = false;
        "on-click" = "activate";
        "on-click-right" = "deactivate";
        "tooltip" = false;
      };

      cpu = {
        "interval" = 2;
        "format" = "CPU {usage}%";
        "states" = {
          "warning" = 70;
          "critical" = 90;
        };
        "tooltip" = false;
      };

      memory = {
        "interval" = 5;
        "format" = "RAM {percentage}%";
        "states" = {
          "warning" = 75;
          "critical" = 90;
        };
        "tooltip" = false;
      };

      temperature = {
        "interval" = 5;
        "format" = "TMP {temperatureC}°C";
        "format-warning" = "TMP {temperatureC}°C";
        "format-critical" = "TMP {temperatureC}°C";
        "warning-threshold" = 75;
        "critical-threshold" = 85;
        "hwmon-path-abs" = [
          "/sys/devices/pci0000:00/0000:00:18.3/hwmon"
        ];
        "input-filename" = "temp1_input";
        "tooltip" = false;
      };

      pulseaudio = {
        "format" = "VOL {volume}%";
        "format-muted" = "MUTED";
        "scroll-step" = 5;
        "tooltip" = false;
      };

      network = {
        "format-wifi" = "WLAN {signalStrength}%";
        "format-ethernet" = "ETH";
        "format-disconnected" = "OFFLINE";
        "tooltip-format" = "{ifname} {ipaddr}";
      };

      clock = {
        "format" = "{:%a %Y-%m-%d %H:%M}";
        "tooltip" = false;
      };
    };
  };
}
