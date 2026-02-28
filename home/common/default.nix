{ ... }:

{
  imports = [
    ./neovim.nix
    ./git.nix
    ./zsh.nix
    ./direnv.nix
    ./foot.nix
    ./emacs
  ];

  fonts.fontconfig.enable = true;
}
