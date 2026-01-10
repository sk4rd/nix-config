{ ... }:

{
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/b6c024af-2e20-472a-bc60-ab93207abc8c";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/3CD7-717D";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/d2defb9c-dec4-4dfb-860f-4ebd39220504"; }
    ];
}
