{ pkgs, ... }:

{
  imports = [
    ../common
    ./hardware.nix
    ./filesystem.nix
    ./boot.nix
    ./networking.nix
    ./services.nix
  ];

  users.users.miko.extraGroups = [
    "scanner"
  ];

  environment.systemPackages = with pkgs; [
    freerdp
    wireguard-tools
  ];

  system.stateVersion = "25.05";
}
