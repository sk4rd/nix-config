{ pkgs, ... }:

{
  imports = [
    ../common/emacs
  ];

  home.packages = with pkgs; [ wl-clipboard ];

  home.stateVersion = "25.11";
}
