{ ... }:

{
  # Syncthing file sync configuration
  services.syncthing = {
    enable = true;
    tray.enable = true;
    extraOptions = [ "--no-default-folder" ];
  };
}