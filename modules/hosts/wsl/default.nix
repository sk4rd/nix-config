{ den, ... }:

{
  den.aspects.wsl = {
    includes = [
      den.batteries.hostname
      den.aspects.yubikey-openpgp
    ];

    provides.to-users.includes = [ den.aspects.yubikey-openpgp ];

    wsl.defaultUser = "miko";

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.usbutils ];
      };
  };
}
