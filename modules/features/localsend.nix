{
  den.aspects.localsend = {
    nixos.networking.firewall = {
      allowedTCPPorts = [ 53317 ];
      allowedUDPPorts = [ 53317 ];
    };

    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.localsend ];
    };
  };
}
