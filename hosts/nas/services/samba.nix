{ ... }:

{
  services.samba = {
    enable = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "NAS";
        "netbios name" = "NAS";

        "security" = "user";

        "hosts allow" = "192.168.178.0/24 127.0.0.1";
        "hosts deny" = "0.0.0.0/0";

        "map to guest" = "Bad User";
        "guest account" = "nobody";

        # Modern protocol only
        "server min protocol" = "SMB2_10";
        "client min protocol" = "SMB2_10";
        "server signing" = "mandatory";

        # ZFS compatibility
        "ea support" = "yes";
        "store dos attributes" = "yes";
      };

      Documents = {
        "path" = "/srv/samba/documents";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "miko";
        "create mask" = "0644";
        "directory mask" = "0755";
      };

      Media = {
        "path" = "/srv/samba/media";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "miko";
        "create mask" = "0644";
        "directory mask" = "0755";
      };

      Torrents = {
        "path" = "/srv/samba/torrents";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "miko";
        "create mask" = "0644";
        "directory mask" = "0755";
      };

      Public = {
        "path" = "/srv/samba/public";
        "browseable" = "yes";
        "read only" = "yes";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";

        # Allow only user miko to write
        "write list" = "miko";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = false;
  };
}
