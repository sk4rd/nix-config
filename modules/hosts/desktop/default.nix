{ den, ... }:

{
  den.aspects.desktop = {
    includes = [
      den.aspects.disko
      den.aspects.secure-boot
      den.aspects.zram
      den.aspects.plasma-workstation
      den.aspects.rustdesk
    ];

    nixos =
      { pkgs, ... }:
      {
        services.fprintd.enable = false;
        services.displayManager.sddm.settings.X11.DisplayCommand =
          "${pkgs.xrandr}/bin/xrandr --output DP-1 --primary";
        nix.settings.trusted-users = [ "miko" ];
        networking.hosts."192.168.178.3" = [ "silverbullet.sk4rd.com" ];

        # Only the desktop gets elevated game priority; the laptop keeps its
        # power-saving defaults from the shared gaming aspect.
        programs.gamemode.settings.general.renice = 10;
        programs.gamescope.capSysNice = true;
      };
  };
}
