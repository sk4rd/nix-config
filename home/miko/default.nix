{ ... }:

{
  imports = [ ./programs ./xdg.nix ];

  home = {
    username = "miko";
    homeDirectory = "/home/miko";
    stateVersion = "23.05";
  };

  # Enable the ssh-agent
  services.ssh-agent.enable = true;
}
