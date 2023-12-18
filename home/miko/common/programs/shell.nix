{ pkgs, ... }:

{
  # Dependencies for the shell
  home.packages = with pkgs; [ fortune fzf lolcat thefuck ];

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
      plugins = [ "fzf" "git" "sudo" "thefuck" "z" ];
    };
    initExtra = ''
      date +'%a %d %B %Y' | lolcat -t -F 0.01
      fortune 60% humorists platitudes | lolcat -t -F 0.01
      echo ""
    '';
  };
}
