{ pkgs, ... }:

{
  # Mako notification daemon configuration
  services.mako = {
    enable = true;
    anchor = "top-right";
    backgroundColor = "#282828d9";
    borderColor = "#b16286ff";
    borderRadius = 12;
    borderSize = 3;
    defaultTimeout = 8000;
    font = "Iosevka 12";
    height = 300;
    iconPath = "${pkgs.papirus-icon-theme}/share/icons/Papirus";
    padding = "10";
    textColor = "#ebdbb2ff";
    width = 400;
  };
}

