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
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations = {
        "desktop" = nixpkgs.lib.nixosSystem {
          inherit pkgs;
          modules = [
            ./hosts/desktop
            ./home/miko
            ./modules
            nvf.nixosModules.nvf
          ];
          specialArgs.inputs = inputs;
        };

        "laptop" = nixpkgs.lib.nixosSystem {
          inherit pkgs;
          modules = [
            ./hosts/laptop
            ./home/miko
            ./modules
          ];
          specialArgs.inputs = inputs;
        };

        "wsl" = nixpkgs.lib.nixosSystem {
          inherit pkgs;
          modules = [
            ./hosts/wsl
            ./home/wsl
            ./modules
            nixos-wsl.nixosModules.default
          ];
          specialArgs.inputs = inputs;
        };
      };

      formatter.${system} = pkgs.nixfmt-tree;
    };
}
