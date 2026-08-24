{
  den.aspects.laptop.nixos =
    { lib, ... }:
    {
      # Evaluation-only placeholders. Do not deploy before replacing this file
      # with the laptop's generated hardware configuration.
      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      fileSystems."/" = {
        device = "/dev/disk/by-label/NIXOS_ROOT";
        fsType = "ext4";
      };
    };
}
