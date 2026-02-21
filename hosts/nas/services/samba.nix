{ ... }:

{

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "SMB NixOS NAS";
        "netbios name" = "NAS";
        "security" = "user";
        "hosts allow" = "192.168.178.0/24 127.0.0.1";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      public = {
        "path" = "/storage-pool/Shared";
        "browseable" = "yes";
        "read only" = "yes";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "write list" = "miko";
        "force user" = "smbpublic";
        "force group" = "smbpublic";
      };
      private = {
        "path" = "/storage-pool/Private/miko";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "miko";
        "force group" = "miko";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
}
