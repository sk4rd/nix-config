{ pkgs, ... }:

{
  boot = {
    kernelModules = [ "kvm-intel" ];
    zfs.extraPools = [ "storage-pool" ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
      supportedFilesystems = {
        zfs = true;
      };
    };
  };
}
