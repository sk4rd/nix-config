{
  description = "Sk4rd's NixOS and Home-Manager Configuration";

  # Definition of inputs (dependencies) for the flake
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs = {
      url = "github:sk4rd/emacs.d";
      flake = false;
    };
    wallpapers = {
      url = "github:sk4rd/wallpapers";
      flake = false;
    };
  };

  outputs = { emacs, home-manager, nixpkgs, wallpapers, ... }@inputs:
    let
      # Default system architecture
      system = "x86_64-linux";

      # Package set from nixpkgs with specific system and configuration      
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ ];
      };

      # Function to create a NixOS configuration for a given host
      mkHostConfig = host:
        nixpkgs.lib.nixosSystem {
          inherit pkgs;
          modules = [ ./hosts/${host} ];
        };

      # Function to create a Home Manager configuration for a given user and host
      mkHomeConfig = user: host:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/${user}/${host} ];
          extraSpecialArgs = { inherit (inputs) emacs wallpapers; };
        };
    in {
      # NixOS configurations for different hosts
      nixosConfigurations = {
        desktop = mkHostConfig "desktop";
        laptop = mkHostConfig "laptop";
      };

      # Home Manager configurations for different users and hosts
      homeConfigurations = {
        "miko@desktop" = mkHomeConfig "miko" "desktop";
        "miko@laptop" = mkHomeConfig "miko" "laptop";
      };
    };
}
