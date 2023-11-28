{ config, ... }:

{
  hardware.cpu.amd.updateMicrocode =
    config.hardware.enableRedistributableFirmware;
}
