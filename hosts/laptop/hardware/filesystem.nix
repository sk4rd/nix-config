{ ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/d31d586f-79f0-400f-afc0-cdd9fc49b28c";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/DCE3-C594";
    fsType = "vfat";
  };

  swapDevices = [{
    device = "/.swapfile";
    size = 32 * 1024;
  }];
}

