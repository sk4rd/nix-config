{ ... }:

{
  # MangoHud settings
  programs.mangohud = {
    enable = true;
    settings = {
      # GPU
      gpu_core_clock = true;
      gpu_temp = true;
      # CPU
      cpu_mhz = true;
      cpu_temp = true;
      # RAM
      ram = true;
    };
  };
}
