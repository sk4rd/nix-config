{ den, ... }:

{
  den.aspects.cad = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.freecad
          pkgs.kicad
          pkgs.openscad
        ];
      };
  };
}
