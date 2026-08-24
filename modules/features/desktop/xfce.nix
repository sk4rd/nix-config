{
  den.aspects.xfce.nixos = {
    services.xserver = {
      enable = true;
      desktopManager = {
        xterm.enable = false;
        xfce.enable = true;
      };
    };

    services.displayManager.defaultSession = "xfce";
  };
}
