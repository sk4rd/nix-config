{ den, ... }:

{
  den.aspects.wsl = {
    includes = [
      den.batteries.hostname
      den.aspects.yubikey-openpgp
    ];

    provides.to-users.includes = [ den.aspects.yubikey-openpgp ];

    wsl = {
      defaultUser = "miko";
      usbip.enable = true;
    };

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.usbutils ];
      };
  };
}
