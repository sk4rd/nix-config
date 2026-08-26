let
  shadowCopySettings = path: {
    "vfs objects" = "shadow_copy2";
    "shadow:mountpoint" = path;
    "shadow:snapdir" = ".zfs/snapshot";
    "shadow:snapprefix" = "^zfs-auto-snap_[[:alpha:]]*";
    "shadow:delimiter" = "-20";
    "shadow:format" = "-%Y-%m-%d-%Hh%M";
    "shadow:localtime" = "no";
    "shadow:sort" = "desc";
  };
  authenticatedShare = path: {
    inherit path;
    browseable = "yes";
    "read only" = "no";
    "guest ok" = "no";
    "valid users" = "miko";
    "create mask" = "0644";
    "directory mask" = "0755";
  };
in
{
  den.aspects.samba.nixos =
    { config, ... }:
    {
      services = {
        samba = {
          enable = true;
          openFirewall = false;
          smbd.enable = true;
          nmbd.enable = false;
          winbindd.enable = false;
          settings = {
            global = {
              workgroup = "WORKGROUP";
              "server string" = config.networking.hostName;
              "netbios name" = config.networking.hostName;
              security = "user";
              "invalid users" = [ "root" ];
              "map to guest" = "Never";
              "smb ports" = "445";
              "server min protocol" = "SMB3_00";
              "server signing" = "mandatory";
              "smb encrypt" = "required";
              "ea support" = "yes";
              "store dos attributes" = "yes";
            };
            Documents = authenticatedShare "/srv/samba/documents" // shadowCopySettings "/srv/samba/documents";
            Media = authenticatedShare "/srv/samba/media" // shadowCopySettings "/srv/samba/media";
            Torrents = authenticatedShare "/srv/samba/torrents" // shadowCopySettings "/srv/samba/torrents";
          };
        };
      };

      systemd.services.samba-smbd = {
        after = [ "zfs-mount.service" ];
        requires = [ "zfs-mount.service" ];
        unitConfig = {
          RequiresMountsFor = [
            "/srv/samba/documents"
            "/srv/samba/media"
            "/srv/samba/torrents"
          ];
          AssertPathIsMountPoint = [
            "/srv/samba/documents"
            "/srv/samba/media"
            "/srv/samba/torrents"
          ];
        };
      };
    };
}
