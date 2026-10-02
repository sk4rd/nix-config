{
  den.aspects.rustdesk.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.rustdesk-flutter ];
    };
}
