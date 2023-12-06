{ ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/3e9034b9-9b69-47fc-b224-48c46c61f7c0";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/533E-9112";
    fsType = "vfat";
  };

  swapDevices = [{
    device = "/.swapfile";
    size = 32 * 1024;
  }];
}

