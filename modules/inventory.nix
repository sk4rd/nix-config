{
  den = {
    hosts.x86_64-linux = {
      desktop = {
        hostName = "desktop";
        users.miko = { };
      };
      laptop = {
        hostName = "laptop";
        users.miko = { };
      };
      nas = {
        hostName = "nas";
        users.admin.classes = [ "user" ];
        zfs.pools = [ "storage-pool" ];
      };
      vm = {
        # Preserve the current network identity while using `vm` as the flake target.
        hostName = "nixos";
        users.miko = { };
      };
      wsl = {
        hostName = "wsl";
        users.miko = { };
        wsl.enable = true;
      };
    };

    # The same user aspect can also be activated outside NixOS.
    homes.x86_64-linux.miko = { };
  };
}
