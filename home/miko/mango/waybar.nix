{ ... }:

{
  programs.waybar = {
    enable = true;
    systemd.enable = false;
    style = ./waybar/style.css;

    settings.main = {
      layer = "top";
      position = "top";
      height = 26;
      spacing = 8;
      modules-left = [ "ext/workspaces" ];
      modules-right = [
        "pulseaudio"
        "network"
        "battery"
        "clock"
        "tray"
      ];

      "ext/workspaces" = {
        "format" = "{icon}";
        "ignore-hidden" = true;
        "sort-by-id" = true;
        "all-outputs" = false;
        "on-click" = "activate";
        "on-click-right" = "deactivate";
      };

      pulseaudio = {
        "format" = "{icon} {volume}%";
        "format-muted" = "MUTED";
        "format-icons" = [
          "VOL"
          "VOL"
          "VOL"
        ];
        "scroll-step" = 5;
        "tooltip" = false;
      };

      network = {
        "format-wifi" = "WLAN {signalStrength}%";
        "format-ethernet" = "ETH";
        "format-disconnected" = "OFFLINE";
        "tooltip-format" = "{ifname} {ipaddr}";
      };

      battery = {
        "format" = "BAT {capacity}%";
        "format-charging" = "CHG {capacity}%";
        "format-plugged" = "AC";
        "states" = {
          "warning" = 25;
          "critical" = 12;
        };
      };

      clock = {
        "format" = "{:%a %Y-%m-%d %H:%M}";
        "tooltip" = false;
      };

      tray = {
        "icon-size" = 14;
        "spacing" = 6;
      };
    };
  };
}
