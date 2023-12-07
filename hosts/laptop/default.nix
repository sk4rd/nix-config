{ lib, ... }:

{
  imports =
    [ ../common ./power-management.nix ./networking.nix ./hardware ./boot.nix ];

  # Enable sddm display manager
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.power-profiles-daemon.enable = lib.mkForce false;
  services.xserver.desktopManager.plasma5.enable = true;
}
