{ den, ... }:

{
  den.aspects.desktop = {
    includes = [
      den.aspects.disko
      den.aspects.llama-cpp
      den.aspects.secure-boot
      den.aspects.zram
      den.aspects.plasma-workstation
      den.aspects.rustdesk-host
      den.aspects.single-gpu-passthrough
    ];

    # Adopt the existing desktop profile without moving its history/bookmarks.
    # Fresh machines use the reusable Firefox feature's default profile path.
    provides.to-users.homeManager.programs.firefox.profiles.default.path = "mygnli95.default";

    # Point each user's Hermes Agent at the local llama.cpp endpoint.
    provides.to-users.includes = [ den.aspects.llama-cpp ];

    nixos = {
      nix.settings.trusted-users = [ "miko" ];
      networking.hosts."192.168.178.3" = [ "silverbullet.sk4rd.com" ];

      # Only the desktop gets elevated game priority; the laptop keeps its
      # power-saving defaults from the shared gaming aspect.
      programs.gamemode.settings.general.renice = 10;
      programs.gamescope.capSysNice = true;
    };
  };
}
