{
  den.aspects.desktop.nixos =
    { lib, ... }:

    {
      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      boot.kernelModules = [ "kvm-amd" ];

      hardware = {
        enableRedistributableFirmware = true;
        cpu.amd.updateMicrocode = true;
        amdgpu.initrd.enable = true;
        graphics.enable = true;
      };

      services.xserver.videoDrivers = [ "amdgpu" ];
      # Spread device interrupts across the Ryzen's 32 logical CPUs.
      services.irqbalance.enable = true;

      # Bound writeback on the 32 GiB / NVMe desktop so large copies and
      # downloads cannot accumulate gigabytes of dirty pages before flushing.
      boot.kernel.sysctl = {
        "vm.dirty_background_bytes" = 134217728;
        "vm.dirty_bytes" = 536870912;
      };

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      swapDevices = lib.mkDefault [ ];
    };
}
