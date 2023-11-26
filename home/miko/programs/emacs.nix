{ emacs, pkgs, ... }:

{
  # Install Emacs version 29
  programs.emacs = {
    enable = true;
    package = pkgs.emacs29;
  };

  # Install some optional dependencies
  home.packages = with pkgs; [
    iosevka # Sleek, monospaced font optimized for coding
    fortune # Random quotation display
  ];

  # Put Emacs config files in the right place
  home.file = {
    ".emacs.d/init.el".source = "${emacs}/init.el";
    ".emacs.d/early-init.el".source = "${emacs}/early-init.el";
  };
}
