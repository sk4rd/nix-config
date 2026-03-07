{ lib, pkgs, ... }:

{
  imports = [
    ../common/emacs
  ];

  home.packages = with pkgs; [ wl-clipboard ];

  home.stateVersion = lib.mkDefault "25.05";
}
