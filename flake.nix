{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    winboat.url = "github:TibixDev/winboat";
    winboat.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      winboat,
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations."desktop" = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        modules = [
          ./hosts/desktop
        ];
        specialArgs.inputs = inputs;
      };

      formatter.${system} = pkgs.nixfmt;
    };

}
