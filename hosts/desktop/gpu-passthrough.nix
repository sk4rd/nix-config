{ pkgs, ... }:

{
  # CHANGE: intel_iommu enables iommu for intel CPUs with VT-d
  # use amd_iommu if you have an AMD CPU with AMD-Vi
  boot.kernelParams = [ "amd_iommu=on" ];

  # These modules are required for PCI passthrough, and must come before early modesetting stuff
  boot.kernelModules = [ "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];

  # CHANGE: Don't forget to put your own PCI IDs here
  boot.extraModprobeConfig = "options vfio-pci ids=1002:744c,1002:ab30";

  environment.systemPackages = with pkgs; [ virt-manager qemu OVMF ];

  virtualisation.libvirtd.enable = true;

  # CHANGE: add your own user here
  users.groups.libvirtd.members = [ "root" "miko" ];

  virtualisation.libvirtd.qemu.verbatimConfig = ''
    nvram = [ "${pkgs.OVMF}/FV/OVMF.fd:${pkgs.OVMF}/FV/OVMF_VARS.fd" ]
  '';

}
