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
        device = "/dev/disk/by-uuid/34081e1f-fcb9-43d8-98ba-4d653cbc535f";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/C997-5D94";
        fsType = "vfat";
        options = [
          "fmask=0022"
          "dmask=0022"
        ];
      };

      swapDevices = [ ];
    };
}
