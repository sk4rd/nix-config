{
  den.aspects.jellyfin.nixos = {
    services.jellyfin = {
      enable = true;
      dataDir = "/srv/jellyfin";
      cacheDir = "/srv/jellyfin/cache";
      openFirewall = false;
    };

    users.users.jellyfin.extraGroups = [ "miko" ];

    systemd.services.jellyfin = {
      after = [ "zfs-mount.service" ];
      requires = [ "zfs-mount.service" ];
      unitConfig.RequiresMountsFor = [
        "/srv/jellyfin"
        "/srv/samba/media"
      ];
      unitConfig.AssertPathIsMountPoint = [
        "/srv/jellyfin"
        "/srv/samba/media"
      ];
    };
  };
}
