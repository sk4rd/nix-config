{ config, emacs, pkgs, ... }:

{
  programs.emacs = {
    enable = true;
    package = pkgs.emacs29;
  };

  home.packages = with pkgs; [
    iosevka # Sleek, monospaced font optimized for coding
  ];

  home.file = {
    ".emacs.d/init.el".source = "${emacs}/init.el";
    ".emacs.d/early-init.el".source = "${emacs}/early-init.el";
  };
}
