{ lib, ... }:

{
  imports =
    [ ../common ./power-management.nix ./networking.nix ./hardware ./boot.nix ];
}
