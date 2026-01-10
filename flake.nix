{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
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
          ];
          specialArgs.inputs = inputs;
        };

        "laptop" = nixpkgs.lib.nixosSystem {
          inherit pkgs;
          modules = [
            ./hosts/laptop
            ./home/miko
          ];
          specialArgs.inputs = inputs;
        };
      };

      formatter.${system} = pkgs.nixfmt;
    };

}
