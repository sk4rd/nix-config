{ lib, ... }:

{
  # Default networking configuration
  networking = lib.mkDefault {
    hostname = "nixos";
    networkmanager.enable = true;
    firewall.enable = true;
  };
}
