{ ... }:

{
  # Systemd-boot configuration
  boot.loader.systemd-boot = {
    enable = true;
    editor = false;
    configurationLimit = 50;
  };
}
