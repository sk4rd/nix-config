{ ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/ceb50ec2-c675-4bbf-a003-65039d0945bf";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/3255-7FFF";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/9f34f5b0-a2d7-4e42-9d2b-86b37e432e8d"; }
  ];
}
