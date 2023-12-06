{ pkgs, ... }:

let
  cursorPackage = pkgs.graphite-cursors;
  cursorName = "graphite-dark";
  size = 16;
in {
  home.pointerCursor = {
    package = cursorPackage;
    name = cursorName;
    gtk.enable = true;
    size = size;
  };

  gtk = {
    enable = true;
    cursorTheme = {
      package = cursorPackage;
      name = cursorName;
      size = size;
    };
  };
}

