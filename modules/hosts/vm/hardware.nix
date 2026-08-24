{
  den.aspects.vm.nixos =
    { lib, ... }:

    {
      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      virtualisation.virtualbox.guest.enable = true;

      # VirtualBox 7.2.14 still tries to build its external vboxvideo module
      # against kernels where the in-kernel driver is sufficient. Preserve the
      # workaround from the pre-Den VM configuration until upstream/Nixpkgs no
      # longer needs it for this pinned kernel/package combination.
      nixpkgs.overlays = [
        (_final: previous: {
          linuxPackages = previous.linuxPackages.extend (
            _kernelFinal: kernelPrevious: {
              virtualboxGuestAdditions = kernelPrevious.virtualboxGuestAdditions.overrideAttrs (oldAttrs: {
                postPatch = (oldAttrs.postPatch or "") + ''
                  substituteInPlace src/vboxguest-*/Makefile \
                    --replace-fail \
                      'KERN_MAJ = $(shell uname -r | cut -d . -f1)' \
                      'KERN_MAJ = 7'
                '';
              });
            }
          );
        })
      ];

      boot.initrd.availableKernelModules = [
        "ata_piix"
        "ohci_pci"
        "ehci_pci"
        "ahci"
        "sd_mod"
        "sr_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ ];
      boot.extraModulePackages = [ ];

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
