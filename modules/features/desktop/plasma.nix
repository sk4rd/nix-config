{
  den.aspects.plasma.nixos =
    { pkgs, ... }:
    {
      services.desktopManager.plasma6.enable = true;
      services.displayManager.sddm.enable = true;

      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        aurorae
        discover
        elisa
        khelpcenter
        krdp
        plasma-browser-integration
        plasma-keyboard
        plasma-workspace-wallpapers
        qrca
        qttools
        qtvirtualkeyboard
        union
      ];

      programs.kde-pim.enable = false;
    };
}
