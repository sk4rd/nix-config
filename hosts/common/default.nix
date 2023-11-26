{ config, lib, pkgs, ... }:

{
  imports = [ ./programs ./sound.nix ./networking.nix./hardware ./virtualisation.nix ];

  boot.loader = lib.mkDefault {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
    };
  };

  time.timeZone = "Europe/Berlin";

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
