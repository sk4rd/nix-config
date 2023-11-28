{ config, lib, pkgs, ... }:

let
  cfg = config;
  image = ./icon.png;
in with lib; {
  # Neofetch configuration
  home.packages = with pkgs; [ neofetch ];
  xdg.configFile."neofetch/config.conf".text = mkIf cfg.programs.kitty.enable ''
    image_backend="kitty"
    image_source="${image}"
    image_size="none"
  '';
}

