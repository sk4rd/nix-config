{
  den.aspects.hardware.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.lm_sensors
      ];

    };
}
