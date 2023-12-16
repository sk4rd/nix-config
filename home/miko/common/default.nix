{ ... }:

{
  # Imports for all common config directories
  imports = [ ./misc ./programs ./services ];

  # Default home configuration
  home = {
    username = "miko";
    homeDirectory = "/home/miko";
    stateVersion = "23.11";
  };

  # Let fonts be managed by home-manager
  fonts.fontconfig.enable = true;
}
