{
  den.aspects.nas-service-identities.nixos.users = {
    groups = {
      miko.gid = 993;
      backup.gid = 1002;
      prowlarr.gid = 1003;
      silverbullet.gid = 1004;
      qbittorrent.gid = 2001;
    };
    users = {
      miko = {
        isSystemUser = true;
        uid = 995;
        group = "miko";
        extraGroups = [ "qbittorrent" ];
      };
      silverbullet = {
        isSystemUser = true;
        uid = 1004;
        group = "silverbullet";
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
