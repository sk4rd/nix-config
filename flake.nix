{
  description = "Sk4rd's NixOS and Home-Manager Configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs = {
      url = "github:sk4rd/emacs.d";
      flake = false;
    };
  };

  outputs = { nixpkgs, home-manager, emacs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ ];
      };
    in {
      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          inherit pkgs;
          modules = [ ./hosts/desktop ];
        };
        laptop = nixpkgs.lib.nixosSystem {
          inherit pkgs;
          modules = [ ./hosts/laptop ];
        };
      };
      homeConfigurations = {
        "miko@desktop" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/miko ];
          extraSpecialArgs = { inherit emacs; };
        };
      };
    };
}
