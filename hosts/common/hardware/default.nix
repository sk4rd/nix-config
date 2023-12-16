{ ... }:

{
  imports = [ ./xbox-controller.nix ];

  # Enable firmware with redistribution license
  hardware.enableRedistributableFirmware = true;

  # Enable support for 32bit libs that steam uses
  hardware.opengl.driSupport32Bit = true;
}
