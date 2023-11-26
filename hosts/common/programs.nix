{ config, pkgs, ... }:

{
  programs.zsh.enable = true;

  programs.git = {
    enable = true;
    lfs.enable = true;
    config = { init.defaultBranch = "main"; };
  };
}
