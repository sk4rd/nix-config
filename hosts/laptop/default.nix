{ ... }:

{
  imports = [ ../common ./power-management.nix ./networking.nix ./hardware ];

  networking.hostName = "laptop";
}
