{ pkgs, ... }:

{
  # Kitty terminal emulator configuration
  programs.kitty = {
    enable = true;
    shellIntegration.enableZshIntegration = true;
    theme = "Gruvbox Dark";
    font = {
      package = pkgs.nerdfonts.override { fonts = [ "IosevkaTerm" ]; };
      name = "Iosevka";
      size = 11;
    };
    settings = {
      enable_audio_bell = false;
      window_margin_width = 8;
    };
  };
}

