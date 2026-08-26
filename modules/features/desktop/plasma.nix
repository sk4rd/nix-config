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

  den.aspects.plasma.homeManager =
    { lib, pkgs, ... }:
    let
      kdeglobals = pkgs.writeText "kdeglobals" ''
        [General]
        ColorScheme=BreezeDark
        [KDE]
        widgetStyle=Breeze
        LookAndFeelPackage=org.kde.breezedark.desktop
        [Icons]
        Theme=breeze-dark
      '';
      kcminputrc = pkgs.writeText "kcminputrc" ''
        [Libinput][Defaults][Touchpad]
        NaturalScroll=true
      '';
    in
    {
      # KDE rewrites these files during the session (color scheme hash, touchpad
      # changes), so they must be writable regular files, not read-only store
      # symlinks. Seed them from the store at activation.
      home.activation.seedPlasmaLook = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.coreutils}/bin/install -m 0600 -D ${kdeglobals} "$HOME/.config/kdeglobals"
        ${pkgs.coreutils}/bin/install -m 0600 -D ${kcminputrc} "$HOME/.config/kcminputrc"
      '';
    };
}
