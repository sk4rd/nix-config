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
      networking.hosts."10.0.0.1" = [ "hermes.sk4rd.com" ];
      users.users.miko.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChk5TMfXC0ElhLHLofXdnjyXqI1zb3eDOjdHGK5aT/u hermes@nas"
      ];
    };
  };
}
