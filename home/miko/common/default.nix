{ ... }:

{
  imports = [ ./programs ./xdg.nix ./cursor.nix ./gtk.nix ];

  home = {
    username = "miko";
    homeDirectory = "/home/miko";
    stateVersion = "23.11";
  };

  # Enable the ssh-agent
  services.ssh-agent.enable = true;

  # Let fonts be managed by home-manager
  fonts.fontconfig.enable = true;
}
