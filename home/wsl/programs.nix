{ pkgs, ... }:

{
  programs.foot = {
    enable = true;
    settings.main = {
      font = "comic code ligatures:size=11";
    };
  };
}
