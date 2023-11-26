{ pkgs, ... }:

{
  # Dependencies for the shell
  home.packages = with pkgs; [ fortune lolcat fzf thefuck ];

  # ZSH configuration
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    dotDir = ".config/zsh";
    # Oh-My-Zsh configuration
    oh-my-zsh = {
      enable = true;
      theme = "candy";
      plugins = [
        "fzf" # Requires 'fzf' to be installed
        "git"
        "sudo" # Key bindings (ESC)
        "thefuck" # Requires 'thefuck' to be installed
        "z"
      ];
    };
    initExtra = ''
      date +'%a %d %B %Y' | lolcat -t -F 0.01
      fortune 60% humorists platitudes | lolcat -t -F 0.01
      echo ""
    '';
  };
}
