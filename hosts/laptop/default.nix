{ ... }:

{
  imports = [ ../common ./power-management.nix ./networking.nix ];

  networking.hostName = "laptop";
}
