{ pkgs, ... }:

{
  imports = [
    ./waybar.nix
  ];

  home.packages = with pkgs; [
    cliphist
    fuzzel
    grim
    mako
    slurp
    swayidle
    swaylock
    wl-clipboard
  ];

  xdg.configFile."mango/config.conf".source = ./config.conf;
}
