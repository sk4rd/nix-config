{ config, ... }:

{
  # GnuPG configurtion
  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.dataHome}/gnupg";
  };
}

