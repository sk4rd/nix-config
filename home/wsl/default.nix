{ inputs, ... }:

{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager.users.nixos = {
    imports = [ ./programs.nix ];
    home.stateVersion = "25.05";
  };
}
