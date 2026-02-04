{ pkgs, ... }:

{
  home.packages = with pkgs; [
    logseq
    orca-slicer
    spotify
  ];

  programs.claude-code.enable = true;

  home.stateVersion = "25.05";
}
