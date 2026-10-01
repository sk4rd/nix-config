{ den, ... }:

{
  den.aspects.laptop = {
    includes = [
      den.aspects.disko
      den.aspects.laptop-power
      den.aspects.miko-password
      den.aspects.plasma-workstation
      den.aspects.rustdesk
      den.aspects.secure-boot
      den.aspects.zram
    ];

    nixos = {
      nix.settings.trusted-users = [ "miko" ];
    };
  };
}
