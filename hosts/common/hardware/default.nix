{ ... }:

{
  imports = [ ./sennheiser-gsx-1000.nix ./xbox-controller.nix ];

  # Enable firmware with redistribution license
  hardware.enableRedistributableFirmware = true;
}
