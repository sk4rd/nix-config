{ config, lib, pkgs, ... }: 

{
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
    };
  };

  system.stateVersion = "23.05";
}