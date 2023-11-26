{ lib, ... }:

{
  # Default networking configuration
  networking = lib.mkDefault {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall.enable = true;
  };
}
