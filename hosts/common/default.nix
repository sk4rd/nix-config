{ ... }:

{
  imports = [
    ./boot.nix
    ./hardware
    ./networking.nix
    ./programs
    ./sound.nix
    ./users.nix
    ./virtualisation.nix
  ];

  time.timeZone = "Europe/Berlin";

  # Enable the new nix commands and flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "23.11";
}
