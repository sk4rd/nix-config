{ pkgs, ... }:

let swaylock = "${pkgs.swaylock-effects}/bin/swaylock";
in {
  # Swayidle configuration
  services.swayidle = {
    enable = true;
    systemdTarget = "hyprland-session.target";

    timeouts = [
      {
        timeout = 300;
        command = "${swaylock}";
      }
      {
        timeout = 420;
        command = "hyprctl dispatch dpms off";
        resumeCommand = "hyprctl dispatch dpms on";
      }
      {
        timeout = 600;
        command = "systemctl suspend";
      }
    ];
  };
}

