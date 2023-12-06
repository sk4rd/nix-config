{ config, pkgs, ... }:

let
  cfg = config;
  userDirs = cfg.xdg.userDirs;
in {
  # ctpv dependency
  home.packages = with pkgs; [ ctpv ];

  # LF terminal file manager configuration
  programs.lf = {
    enable = true;
    keybindings = {
      "." = "set hidden!";
      gr = "cd /";
      gh = "cd ${cfg.home.homeDirectory}";
      gdl = "cd ${userDirs.download}";
      gdo = "cd ${userDirs.documents}";
      gp = "cd ${userDirs.pictures}";
      gv = "cd ${userDirs.videos}";
      gm = "cd /run/media/${cfg.home.username}";
    };
    settings = {
      drawbox = true;
      icons = true;
    };
    extraConfig = ''
      set previewer ctpv
      set cleaner ctpvclear
      &ctpv -s $id
      &ctpvquit $id
    '';
  };

  # Link icon file to config directory
  xdg.configFile."lf/icons".source = ./icons;
}

