{ pkgs, ... }:

{
  imports = [
    ../common
    ./hardware.nix
    ./filesystem.nix
    ./boot.nix
    ./networking.nix
    ./services.nix
    ./virtualisation.nix
  ];

  users.users.miko.extraGroups = [
    "scanner"
  ];

  environment.systemPackages = with pkgs; [
    brave
    vesktop
    vscode
    freerdp
    wireguard-tools
  ];

  system.stateVersion = "25.05";
}
