{
  den.aspects.vm.nixos =
    { lib, ... }:

    {
      boot = {
        loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };
        initrd = {
          availableKernelModules = [
            "ata_piix"
            "ohci_pci"
            "ehci_pci"
            "ahci"
            "sd_mod"
            "sr_mod"
          ];
          kernelModules = [ ];
        };
        kernelModules = [ ];
        extraModulePackages = [ ];
      };

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      virtualisation.hypervGuest.enable = true;

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/1a06f158-7e95-498b-9c13-c7493a5412fb";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/451C-F7C6";
        fsType = "vfat";
        options = [
          "fmask=0022"
          "dmask=0022"
        ];
      };

      swapDevices = [ ];
    };
}
