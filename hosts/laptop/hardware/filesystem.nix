{ ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/820b17f3-91f8-4100-bd70-082a698b9782";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/8A27-AE16";
    fsType = "vfat";
  };

  swapDevices = [{
    device = "/.swapfile";
    size = 32 * 1024;
  }];
}

