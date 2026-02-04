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
          username ? null,
          extraModules ? [ ],
          extraHMModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit pkgs;

          modules =
            extraModules
            ++ [
              ./hosts
              hostPath
            ]
            ++ (
              if homePath != null then
                assert username != null;
                [
                  home-manager.nixosModules.home-manager
                  (
                    { ... }:
                    {
                      home-manager.useGlobalPkgs = true;
                      home-manager.useUserPackages = true;

                      home-manager.users.${username} = {
                        imports = [
                          ./home
                          homePath
                        ];
                      };

                      home-manager.sharedModules = [ nvf.homeManagerModules.nvf ] ++ extraHMModules;
                    }
                  )
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
          username = "miko";
        };

        "laptop" = mkHost {
          hostPath = ./hosts/laptop;
          homePath = ./home/miko;
          username = "miko";
        };

        "wsl" = mkHost {
          hostPath = ./hosts/wsl;
          homePath = ./home/wsl;
          username = "nixos";
          extraModules = [
            nixos-wsl.nixosModules.default
          ];
        };
      };

      formatter.${system} = pkgs.nixfmt-tree;
    };
}
