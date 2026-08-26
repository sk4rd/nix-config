{
  den.aspects.nas-service-identities.nixos.users = {
    groups = {
      miko.gid = 993;
      joplin.gid = 1001;
      backup.gid = 1002;
      prowlarr.gid = 1003;
      qbittorrent.gid = 2001;
    };
    users = {
      miko = {
        isSystemUser = true;
        uid = 995;
        group = "miko";
        extraGroups = [ "qbittorrent" ];
      };
      joplin = {
        isSystemUser = true;
        uid = 1001;
        group = "joplin";
      };
      backup = {
        isSystemUser = true;
        uid = 1002;
        group = "backup";
        shell = "/run/current-system/sw/bin/nologin";
      };
      prowlarr = {
        isSystemUser = true;
        uid = 1003;
        group = "prowlarr";
      };
      qbittorrent = {
        isSystemUser = true;
        uid = 2001;
        group = "qbittorrent";
      };
    };
  };
}
