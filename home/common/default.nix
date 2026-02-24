{ ... }:

{
  imports = [
    ./neovim.nix
    ./git.nix
    ./zsh.nix
    ./direnv.nix
    ./foot.nix
    ./niri
    ./emacs
  ];

  fonts.fontconfig.enable = true;
}
