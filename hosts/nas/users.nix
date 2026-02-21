{ ... }:

{
  users.users.admin = {
    isNormalUser = true;
    description = "NAS Admin";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  users.groups.miko = { };
  users.groups.smbpublic = { };

  users.users.miko = {
    isSystemUser = true;
    group = "miko";
    description = "Samba User";
  };

  users.users.smbpublic = {
    isSystemUser = true;
    group = "smbpublic";
    description = "Public Samba User";
  };
}
