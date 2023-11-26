{ config, pkgs, ... }:

{
  imports = [ ./emacs.nix ./git.nix ];

  home = {
    username = "miko";
    homeDirectory = "/home/miko";
    stateVersion = "23.05";
  };
}
