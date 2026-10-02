{ den, ... }:

{
  den.aspects.desktop = {
    includes = [
      den.aspects.disko
      den.aspects.secure-boot
      den.aspects.zram
      den.aspects.plasma-workstation
      den.aspects.rustdesk
    ];

    nixos = {
      nix.settings.trusted-users = [ "miko" ];
      networking.hosts."192.168.178.3" = [
        "silverbullet.sk4rd.com"
        "hermes.sk4rd.com"
      ];
      users.users.miko.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChk5TMfXC0ElhLHLofXdnjyXqI1zb3eDOjdHGK5aT/u hermes@nas"
      ];

      # Only the desktop gets elevated game priority; the laptop keeps its
      # power-saving defaults from the shared gaming aspect.
      programs.gamemode.settings.general.renice = 10;
      programs.gamescope.capSysNice = true;
    };
  };
}
