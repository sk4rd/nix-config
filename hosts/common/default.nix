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

  # System user
  users.users."miko" = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [ "wheel" ];
    description = "Mikolaj Bajtkiewicz";
  };

  system.stateVersion = "23.05";
}
