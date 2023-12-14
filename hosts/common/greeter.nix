{ pkgs, ... }:

let
  tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet";
  session = "${pkgs.hyprland}/bin/Hyprland";
in {
  # Greetd display manager configuration
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${tuigreet} -tr --cmd ${session}";
        user = "greeter";
      };
    };
  };
}

