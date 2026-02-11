{ ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Enable A2DP sink for high-quality audio (needed for AirPods)
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };
}
