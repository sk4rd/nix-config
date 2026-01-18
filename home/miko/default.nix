{ pkgs, ... }:
{
  home-manager.users.miko = {
    imports = [ ./programs.nix ];
    home.packages = with pkgs; [
      logseq
      orca-slicer
    ];
    home.stateVersion = "25.05";
  };
}
