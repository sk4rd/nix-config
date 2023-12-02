{ config, pkgs, ... }:

{
  # Install font dependency
  home.packages = with pkgs;
    [ (nerdfonts.override { fonts = [ "IosevkaTerm" ]; }) ];

  # Rofi program launcher configuration
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    terminal = "${pkgs.kitty}/bin/kitty";
    extraConfig = {
      run-shell-command = "${pkgs.kitty}/bin/kitty --hold {cmd}";
    };
    theme = let inherit (config.lib.formats.rasi) mkLiteral;
    in {
      "*" = {
        font = "IosevkaTerm Nerd Font 12";

        gruvbox-dark0 = mkLiteral "#282828";
        gruvbox-dark1 = mkLiteral "#cc241d";
        gruvbox-dark2 = mkLiteral "#98971a";
        gruvbox-dark3 = mkLiteral "#d79921";
        gruvbox-dark4 = mkLiteral "#458588";
        gruvbox-dark5 = mkLiteral "#b16286";
        gruvbox-dark6 = mkLiteral "#689d6a";
        gruvbox-dark7 = mkLiteral "#a89984";

        gruvbox-dark8 = mkLiteral "#928374";
        gruvbox-dark9 = mkLiteral "#fb4934";
        gruvbox-dark10 = mkLiteral "#b8bb26";
        gruvbox-dark11 = mkLiteral "#fabd2f";
        gruvbox-dark12 = mkLiteral "#83a598";
        gruvbox-dark13 = mkLiteral "#d3869b";
        gruvbox-dark14 = mkLiteral "#8ec07c";

        gruvbox-dark15 = mkLiteral "#ebdbb2";

        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@gruvbox-dark15";
        accent-color = mkLiteral "@gruvbox-dark4";

        margin = mkLiteral "0px";
        padding = mkLiteral "0px";
        spacing = mkLiteral "0px";
      };
      "#window" = {
        background-color = mkLiteral "@gruvbox-dark0";
        border-color = mkLiteral "@gruvbox-dark5";

        location = mkLiteral "center";
        width = mkLiteral "300px";
        border = mkLiteral "3px";
      };
      "#inputbar" = {
        padding = mkLiteral "8px 12px";
        spacing = mkLiteral "12px";
        children = map mkLiteral [ "prompt" "entry" ];
      };
      "#prompt" = { text-color = mkLiteral "@gruvbox-dark14"; };
      "#listview" = {
        lines = 12;
        columns = 1;
        fixed-height = true;
      };
      "#element" = {
        padding = mkLiteral "8px";
        spacing = mkLiteral "8px";
      };
      "#element normal urgent" = { text-color = mkLiteral "@gruvbox-dark12"; };
      "#element normal active" = { text-color = mkLiteral "@gruvbox-dark12"; };
      "#element selected" = { text-color = mkLiteral "@gruvbox-dark0"; };
      "#element selected normal" = {
        background-color = mkLiteral "@gruvbox-dark11";
      };
      "#element selected urgent" = {
        background-color = mkLiteral "@gruvbox-dark12";
      };
      "#element selected active" = {
        background-color = mkLiteral "@gruvbox-dark8";
      };
      "#element-text" = { text-color = mkLiteral "inherit"; };
    };
  };
}

