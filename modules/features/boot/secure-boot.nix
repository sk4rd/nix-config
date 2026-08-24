{ inputs, ... }:

{
  den.aspects.secure-boot.nixos =
    { lib, pkgs, ... }:
    {
      imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

      environment.systemPackages = [ pkgs.sbctl ];

      boot = {
        loader.systemd-boot.enable = lib.mkForce false;

        lanzaboote = {
          enable = true;
          pkiBundle = "/var/lib/sbctl";
          configurationLimit = 5;
        };
      };
    };
}
