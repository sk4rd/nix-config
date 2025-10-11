{ ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/83f5238f-2028-416c-a56c-425b50956309";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C985-5CD8";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/1fd755b3-af5d-44f7-a7d3-7d7ae6f7f9af"; }
  ];
}
