{ config, pkgs, ... }:

{
  imports = [ ./programs ./xdg.nix ];

  home = {
    username = "miko";
    homeDirectory = "/home/miko";
    stateVersion = "23.05";
  };
}
