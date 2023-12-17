{ pkgs, ... }:

let
  gruvbox = {
    bg = "282828";
    bg-hard = "1d2021";
    fg = "ebdbb2";
    red-bg = "cc241d";
    red-fg = "fb4934";
    green-bg = "98971a";
    green-fg = "b8bb26";
    yellow-bg = "d79921";
    yellow-fg = "fabd2f";
    blue-bg = "458588";
    blue-fg = "83a598";
    purple-bg = "b16286";
    purple-fg = "d3869b";
    aqua-bg = "689d6a";
    aqua-fg = "8ec07c";
    gray-bg = "a89984";
    gray-fg = "928374";
  };
in {
  # Swaylock-effects configuration
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      screenshots = true;
      clock = true;
      font = "Iosevka";
      datestr = "%a, %d.%m.%Y";
      grace = 5;

      # Indicator looks
      indicator = true;
      indicator-radius = 100;
      indicator-thickness = 10;

      # Effects
      effect-blur = "3x5";
      effect-vignette = "0.4:0.8";

      line-color = gruvbox.bg-hard;
      separator-color = gruvbox.bg-hard;
      key-hl-color = gruvbox.purple-fg;
      text-color = gruvbox.fg;

      # Inside circle colors
      inside-color = gruvbox.bg;
      inside-clear-color = gruvbox.yellow-bg;
      inside-ver-color = gruvbox.blue-bg;
      inside-wrong-color = gruvbox.red-bg;

      # Ring colors
      ring-color = gruvbox.aqua-bg;
      ring-clear-color = gruvbox.yellow-fg;
      ring-ver-color = gruvbox.blue-fg;
      ring-wrong-color = gruvbox.red-fg;

      # Keyboard layout box colors
      layout-bg-color = gruvbox.bg;
      layout-border-color = gruvbox.bg-hard;
      layout-text-color = gruvbox.fg;
    };
  };
}

