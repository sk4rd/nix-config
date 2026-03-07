{ pkgs, ... }:

{
  imports = [
    ./mango
  ];

  home.packages = with pkgs; [
    orca-slicer
    spotify
  ];

  home.stateVersion = "25.05";
}
