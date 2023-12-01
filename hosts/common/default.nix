{ lib, pkgs, ... }:

{
  imports = [
    ./programs
    ./sound.nix
    ./networking.nix
    ./hardware
    ./virtualisation.nix
    ./boot.nix
    ./users.nix
  ];

  time.timeZone = "Europe/Berlin";

  # Enable the new nix commands and flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "23.05";
}
