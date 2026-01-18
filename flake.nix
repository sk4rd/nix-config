{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nvf.url = "github:notashelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-wsl,
      home-manager,
      nvf,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      mkHost =
        {
          hostPath,
          homePath ? null,
          extraModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit pkgs;
          modules =
            extraModules
            ++ [
              hostPath
              ./modules
              nvf.nixosModules.nvf
            ]
            ++ (
              if homePath != null then
                [
                  home-manager.nixosModules.home-manager
                  homePath
                ]
              else
                [ ]
            );
        };
    in
    {
      nixosConfigurations = {
        "desktop" = mkHost {
          hostPath = ./hosts/desktop;
          homePath = ./home/miko;
        };

        "laptop" = mkHost {
          hostPath = ./hosts/laptop;
          homePath = ./home/miko;
        };

        "wsl" = mkHost {
          hostPath = ./hosts/wsl;
          homePath = ./home/wsl;
          extraModules = [
            nixos-wsl.nixosModules.default
          ];
        };
      };

      formatter.${system} = pkgs.nixfmt-tree;
    };
}
