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
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      swapDevices = lib.mkDefault [ ];
    };
}
