{
  den.aspects.chromium.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.ungoogled-chromium ];
    };
}
