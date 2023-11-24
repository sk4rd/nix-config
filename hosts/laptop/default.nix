{ config, lib, pkgs, ... }: 

{
  imports = [ ./common ];

  networking.hostName = "laptop";
}