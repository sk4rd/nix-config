{
  den.aspects.cad.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.orca-slicer
        pkgs.freecad
        pkgs.kicad
        pkgs.openscad
      ];
    };
}
