{ config, lib, pkgs, ... }:

{
  imports = [ ./programs.nix ./sound.nix ];

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

  # Enable the new nix commands and flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "23.05";
}
