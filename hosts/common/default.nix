{ config, lib, pkgs, ... }:

{
  imports = [ ./programs.nix ];

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
    shell = pkgs.zsh;
    description = "Mikolaj Bajtkiewicz";
  };

  system.stateVersion = "23.05";
}
