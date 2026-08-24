{
  den.aspects.laptop-power.nixos = {
    services.power-profiles-daemon.enable = true;

    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 50;
    };
  };
}
