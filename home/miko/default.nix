{ pkgs, ... }:

{
  home.packages = with pkgs; [
    orca-slicer
    spotify
  ];

  home.stateVersion = "25.05";
}
