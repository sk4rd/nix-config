{ ... }:

{
  imports = [ ../common ./power-management.nix ./networking.nix ./hardware ];

  # Enable sddm display manager
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
}
