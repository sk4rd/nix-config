{ lib, pkgs, ... }:

{
  imports = [
    ./programs
    ./sound.nix
    ./networking.nix
    ./hardware
    ./virtualisation.nix
    ./boot.nix
  ];

  time.timeZone = "Europe/Berlin";

  # System user
  users.users."miko" = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
    description = "Mikolaj Bajtkiewicz";
  };

  # Enable the new nix commands and flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "23.05";
}
