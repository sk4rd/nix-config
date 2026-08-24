{
  den.aspects.printing-scanning = {
    nixos =
      { pkgs, ... }:
      {
        services.printing.enable = true;

        services.avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };

        hardware.sane = {
          enable = true;
          extraBackends = [ pkgs.sane-airscan ];
        };
      };

    provides.to-users.user.extraGroups = [
      "lp"
      "scanner"
    ];
  };
}
