{
  den.aspects.zed.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.zed-editor ];
    };
}
