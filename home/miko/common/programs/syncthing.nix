{ ... }:

{
  # Syncthing file sync configuration
  services.syncthing = {
    enable = true;
    extraOptions = [ "--no-default-folder" ];
  };
}
