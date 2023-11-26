{ config, lib, pkgs, ... }:

{
  imports = [ ../common ./hardware ./networking.nix ];

  # Basic Plasma5 install
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
}
