{ pkgs, ... }:

{
  imports = [
    ../common
    ./hardware.nix
    ./filesystem.nix
    ./boot.nix
    ./programs.nix
    ./networking.nix
    ./services.nix
    ./virtualisation.nix
  ];

  environment.systemPackages = with pkgs; [
    looking-glass-client
    vial
    ifuse
    usbutils
  ];

  systemd.tmpfiles.settings = {
    "10-shmem" = {
      "/dev/shm/looking-glass" = {
        f = {
          group = "kvm";
          mode = "0660";
          user = "miko";
        };
      };
    };
  };

  system.stateVersion = "25.05";
}
