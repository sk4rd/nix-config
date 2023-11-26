{ config, pkgs, ... }:

{
  imports = [ ./programs ];

  home = {
    username = "miko";
    homeDirectory = "/home/miko";
    stateVersion = "23.05";
  };
}
