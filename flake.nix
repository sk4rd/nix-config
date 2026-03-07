{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      nixos-wsl,
      home-manager,
      sops-nix,
      ...
    }:
    let
      lib = nixpkgs.lib;

      mkHost =
        _name:
        {
          hostPath,
          home ? null,
          extraModules ? [ ],
          extraHMModules ? [ ],
          system ? "x86_64-linux",
        }:
        lib.nixosSystem {
          inherit system;
          modules = [
            sops-nix.nixosModules.sops
            ./hosts
            hostPath
          ]
          ++ extraModules
          ++ lib.optionals (home != null) [
            home-manager.nixosModules.home-manager
            (
              { ... }:
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;

                home-manager.users.${home.username}.imports = [
                  ./home
                  home.path
                ];

                home-manager.sharedModules = extraHMModules;
              }
            )
          ];
        };

      hostDefinitions = {
        desktop = {
          hostPath = ./hosts/desktop;
          home = {
            username = "miko";
            path = ./home/miko;
          };
        };

        laptop = {
          hostPath = ./hosts/laptop;
          home = {
            username = "miko";
            path = ./home/miko;
          };
        };

        wsl = {
          hostPath = ./hosts/wsl;
          home = {
            username = "nixos";
            path = ./home/wsl;
          };
          extraModules = [ nixos-wsl.nixosModules.default ];
        };

        work = {
          hostPath = ./hosts/work;
          home = {
            username = "nixos";
            path = ./home/work;
          };
          extraModules = [ nixos-wsl.nixosModules.default ];
        };

        nas = {
          hostPath = ./hosts/nas;
        };
      };

      formatterPkgs = import nixpkgs { system = "x86_64-linux"; };
    in
    {
      nixosConfigurations = lib.mapAttrs mkHost hostDefinitions;
      formatter.x86_64-linux = formatterPkgs.nixfmt-tree;
    };
}
