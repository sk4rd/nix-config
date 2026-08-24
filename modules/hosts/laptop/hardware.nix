{ inputs, ... }:

{
  den.aspects.laptop.nixos =
    { lib, ... }:
    {
      imports = [ inputs.nixos-hardware.nixosModules.lenovo-thinkpad-z13-gen1 ];

      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usb_storage"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];

      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    };
}
