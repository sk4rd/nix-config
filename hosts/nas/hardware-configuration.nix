{
  config,
  lib,
  pkgs,
  ...
}:

{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/dcd6f5e6-1ce1-4142-8064-ead7dd3eb1d5";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/5089-594B";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  hardware.enableAllFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
}
