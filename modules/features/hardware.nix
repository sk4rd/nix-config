{
  den.aspects.hardware.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.lm_sensors
        pkgs.openrgb
      ];

      services.hardware.openrgb = {
        enable = true;
      };
    };
}
