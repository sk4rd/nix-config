{ inputs, ... }:

{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager.users.miko = {
    home.stateVersion = "25.05";
  };
}
