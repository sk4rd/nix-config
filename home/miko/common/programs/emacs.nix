{ emacs, pkgs, ... }:

{
  # Install Emacs version 29
  programs.emacs = {
    enable = true;
    package = pkgs.emacs29-pgtk;
  };

  # Install some optional dependencies
  home.packages = with pkgs; [
    fortune # Random quotation display
    iosevka # Sleek, monospaced font optimized for coding
    nil # Nix language server
    nixfmt # Nix formatter
  ];

  # Put Emacs config files in the right place
  home.file = {
    ".emacs.d/init.el".source = "${emacs}/init.el";
    ".emacs.d/early-init.el".source = "${emacs}/early-init.el";
  };
}
