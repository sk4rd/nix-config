{
  description = "Sk4rd's NixOS and Home-Manager Configuration";

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
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ ];
      };
      # Function for creating a host configuration
      mkHostConfig = host:
        nixpkgs.lib.nixosSystem {
          inherit pkgs;
          modules = [ ./hosts/${host} ];
        };
      # Function for creating a home configuration
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
      nixosConfigurations = {
        desktop = mkHostConfig "desktop";
        laptop = mkHostConfig "laptop";
      };
      homeConfigurations = {
        "miko@desktop" = mkHomeConfig "miko" "desktop";
        "miko@laptop" = mkHomeConfig "miko" "laptop";
      };
    };
}
