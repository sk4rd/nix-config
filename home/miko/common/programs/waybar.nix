{ lib, ... }:

{
  # Waybar configuration
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;

        modules-left =
          [ "hyprland/workspaces" "wlr/taskbar" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [ "cpu" "temperature" "tray" ];

        "clock" = {
          format = "{:%H:%M %d.%m %a}";
          tooltip = true;
          tooltip-format = "{:%d-%m-%Y}";
        };

        "cpu" = {
          format = "{icon}  {usage}%";
          format-icons = [ "" ];
        };

        "temperature" = {
          critical-threshold = 90;
          format = "{icon} {temperatureC}°C";
          format-icons = [ "󱃃" "󰔏" "󱃂" ];
        };

        "tray" = {
          spacing = 10;
          reverse-direction = true;
        };

        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
        };
      };
    };
    style = ''
      * {
        border: none;
        font-family: Iosevka;
        font-size: 16px;
      }

      window#waybar {
        background: rgba(40, 40, 40, 1);
        color: rgba(235, 219, 178, 1);
        border-bottom: 4px solid rgba(142, 192, 124, 1);
        border-radius: 0px;
      }

      #clock {
        border: 2px solid white;
        border-radius: 12px 12px 0px 0px;
      }

      #tray, #temperature, #clock, #cpu, #workspaces {
        padding: 0px 20px;
        background: rgba(40, 40, 40, 1);
        border-bottom: 4px solid rgba(142, 192, 124, 1);
      }

      #tray {
        border-color: rgba(211, 134, 155, 1);
      }

      #cpu {
        border-color: rgba(250, 189, 47, 1);
      }

      #temperature {
        border-color: rgba(131, 165, 152, 1);
      }

      @keyframes blink {
        to {
          background: rgba(254, 128, 25, 1);
          color: black;
        }
      }

      #temperature.critical {
        animation: blink 1s linear infinite alternate;
      }

      #workspaces {
        padding: 0px;
      }

      #workspaces button.active {
        background: rgba(142, 192, 124, 1);
        border-radius: 12px 12px 0px 0px;
        color: rgba(40, 40, 40, 1);
      }
    '';
  };
}
