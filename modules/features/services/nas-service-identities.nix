{
  den.aspects.nas-service-identities.nixos.users = {
    groups = {
      miko.gid = 993;
      qbittorrent.gid = 2001;
    };
    users = {
      miko = {
        isSystemUser = true;
        uid = 995;
        group = "miko";
        extraGroups = [ "qbittorrent" ];
      };
      qbittorrent = {
        isSystemUser = true;
        uid = 2001;
        group = "qbittorrent";
      };
    };
  };
}
