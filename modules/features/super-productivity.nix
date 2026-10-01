{
  den.aspects.super-productivity.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.super-productivity ];
    };
}
