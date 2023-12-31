{ ... }:

{
  # Systemd-boot configuration
  boot.loader.systemd-boot = {
    enable = true;
    editor = false;
    configurationLimit = 50;
  };

  # Supported filesystems on boot
  boot.supportedFilesystems = [ "ntfs" ];
}
