{ ... }:

{
  # Filesystem support configuration
  boot.supportedFilesystems = [ "ntfs" ];

  # Enable udisks2
  services.udisks2.enable = true;

  # Enable gvfs
  services.gvfs.enable = true;
}

