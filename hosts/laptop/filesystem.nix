{ ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/2d62e3f8-faa5-43b1-8276-4503fae2aa94";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/80C1-6890";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/4b5ac6f6-db47-4435-abe3-a4797e069043"; }
  ];
}
