{ inputs, pkgs, ... }:

{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager.users.miko = {
    imports = [ ./programs.nix ];
    home.packages = with pkgs; [ logseq ];
    home.stateVersion = "25.05";
  };
}
