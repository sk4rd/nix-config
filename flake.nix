{
  description = "Sk4rd's NixOS and Home-Manager Configuration";

  # Definition of inputs (dependencies) for the flake
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs = {
      url = "github:sk4rd/emacs.d/dev";
      flake = false;
    };
    wallpapers = {
      url = "github:sk4rd/wallpapers";
      flake = false;
    };
    hyprland.url = "github:hyprwm/Hyprland";
    split-monitor-workspaces = {
      url = "github:Duckonaut/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
    };
  };

  outputs = { nixpkgs, home-manager, emacs, hyprland, split-monitor-workspaces
    , wallpapers, ... }@inputs:
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
          modules =
            [ ./home/${user}/${host} hyprland.homeManagerModules.default ];
          extraSpecialArgs = {
            inherit (inputs) emacs wallpapers split-monitor-workspaces;
          };
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
