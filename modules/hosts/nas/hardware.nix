{ lib, ... }:

{
  den.aspects.nas.nixos =
    { config, ... }:
    {
      boot = {
        initrd.availableKernelModules = [
          "xhci_pci"
          "ahci"
          "usb_storage"
          "usbhid"
          "sd_mod"
        ];
        kernelModules = [ "kvm-intel" ];
        loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };
        supportedFilesystems = [ "zfs" ];
        zfs = {
          extraPools = [ "storage-pool" ];
          forceImportAll = false;
          forceImportRoot = false;
        };
      };

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-uuid/dcd6f5e6-1ce1-4142-8064-ead7dd3eb1d5";
          fsType = "ext4";
        };
        "/boot" = {
          device = "/dev/disk/by-uuid/5089-594B";
          fsType = "vfat";
          options = [
            "fmask=0077"
            "dmask=0077"
          ];
        };
      };

      hardware = {
        enableRedistributableFirmware = true;
        cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      };

      networking.hostId = "6985f698";
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      swapDevices = [ ];
    };
}
