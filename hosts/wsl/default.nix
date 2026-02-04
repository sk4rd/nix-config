{ ... }:

{
  imports = [ ./programs.nix ];
  system.stateVersion = "25.05";
  wsl.enable = true;
}
