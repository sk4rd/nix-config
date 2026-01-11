{ ... }:

{
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    kernelModules = [ "kvm-amd" ];
    kernelParams = [
      "iommu=pt"
      "vfio-pci.ids=1002:744c,1002:ab30"
      "allow_unsafe_interrupts=1"
    ];
    initrd.kernelModules = [
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"
    ];
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
  };
}
