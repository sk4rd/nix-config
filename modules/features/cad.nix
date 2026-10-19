{
  den.aspects.cad = {
    homeManager =
      { pkgs, ... }:
      let
        # Temporary: nixpkgs#557126 drops gcc-unwrapped from orca-slicer, whose
        # static libstdc++ is linked into the executable and makes the Bambu
        # networking plugin abort with "free(): invalid size". Remove once the
        # pinned nixpkgs contains that commit.
        orcaSlicer = pkgs.orca-slicer.overrideAttrs (old: {
          buildInputs = builtins.filter (package: (package.outPath or "") != pkgs.gcc-unwrapped.outPath) (
            old.buildInputs or [ ]
          );
        });
      in
      {
        home.packages = [
          pkgs.freecad
          pkgs.kicad
          pkgs.openscad
          orcaSlicer
        ];
      };
  };
}
