{ pkgs, ... }:

{
  hardware = {
    enableAllFirmware = true;
    cpu.amd.updateMicrocode = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
