{ inputs, ... }:

{
  den.aspects.laptop.nixos =
    { lib, ... }:
    {
      imports = [ inputs.nixos-hardware.nixosModules.lenovo-thinkpad-z13-gen1 ];

      boot = {
        loader.efi.canTouchEfiVariables = true;
        initrd = {
          availableKernelModules = [
            "nvme"
            "xhci_pci"
            "thunderbolt"
            "usb_storage"
            "sd_mod"
          ];
          kernelModules = [ ];
        };
        kernelModules = [ "kvm-amd" ];
        extraModulePackages = [ ];
      };

      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    };
}
