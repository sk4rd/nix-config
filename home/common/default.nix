{ ... }:

{
  imports = [
    ./git.nix
    ./zsh.nix
    ./emacs
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.home-manager.enable = true;
  programs.foot.enable = true;

  fonts.fontconfig.enable = true;
}
