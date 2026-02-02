{ pkgs, ... }:

{
  imports = [ ./programs.nix ];

  home.packages = with pkgs; [
    logseq
    orca-slicer
    spotify
  ];

  home.stateVersion = "25.05";
}
