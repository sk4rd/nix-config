{ lib, ... }:

{
  # Default networking configuration
  networking.network = lib.mkDefault {
    hostname = "nixos";
    networkmanager.enable = true;
    firewall.enable = true;
  };
}
