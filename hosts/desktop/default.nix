{ config, lib, pkgs, ... }:

{
  imports = [ ../common ./hardware ];

  networking.hostName = "desktop";
}
