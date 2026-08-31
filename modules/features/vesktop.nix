{
  den.aspects.vesktop.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.vesktop ];
    };
}
