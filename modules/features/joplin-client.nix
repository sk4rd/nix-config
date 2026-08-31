{
  den.aspects.joplin-client.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.joplin-desktop ];
    };
}
