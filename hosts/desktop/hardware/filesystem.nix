{ ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/1ee9b589-24ea-4f21-825c-d4c3cca84bc3";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C0B8-1169";
    fsType = "vfat";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/c7a68e54-9b6c-4fec-aaa0-c83f84d2ed00"; }];
}
