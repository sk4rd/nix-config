{ ... }:
let home = "/home/miko";
in {
  xdg = {
    enable = true;
    cacheHome = "${home}/.local/cache";
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${home}/dsktp";
      documents = "${home}/docs";
      download = "${home}/dwnld";
      music = "${home}/music";
      pictures = "${home}/pics";
      publicShare = "${home}/dsktp";
      templates = "${home}/dsktp";
      videos = "${home}/vids";
      extraConfig = { XDG_SCREENSHOTS_DIR = "${home}/pics/screenshots"; };
    };
  };
}
