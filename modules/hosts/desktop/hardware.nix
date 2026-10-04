{
  den.aspects.desktop.nixos =
    { lib, ... }:

    {
      boot = {
        loader.efi.canTouchEfiVariables = true;
        kernelModules = [
          "kvm-amd"
          "vfio-pci"
        ];
        kernelParams = [
          "iommu=pt"
          # Keep firmware-selected BAR sizes for GPU passthrough.
          "amdgpu.rebar=0"
        ];

        # Prevent large transfers from accumulating gigabytes of dirty pages.
        kernel.sysctl = {
          "vm.dirty_background_bytes" = 134217728;
          "vm.dirty_bytes" = 536870912;
        };
      };

      hardware = {
        enableRedistributableFirmware = true;
        cpu.amd.updateMicrocode = true;
        amdgpu.initrd.enable = true;
        graphics.enable = true;
      };

      services.xserver.videoDrivers = [ "amdgpu" ];

      services.irqbalance.enable = true;

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      swapDevices = lib.mkDefault [ ];
    };
}
