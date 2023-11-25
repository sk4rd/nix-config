{ config, pkgs, ... }:

{
  imports = [ ./emacs.nix ];

  home = {
    username = "miko";
    homeDirectory = "/home/miko";
    stateVersion = "23.05";
  };
}
