{ den, ... }:

{
  den.aspects.laptop = {
    includes = [
      den.batteries.hostname
      den.aspects.disko
      den.aspects.laptop-power
      den.aspects.miko-password
      den.aspects.plasma-workstation
      den.aspects.secure-boot
      den.aspects.zram
    ];

    nixos = {
      nix.settings.trusted-users = [ "miko" ];
    };
  };
}
