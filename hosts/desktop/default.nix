{ pkgs, ... }:

{
  imports = [
    ../common
    ./hardware.nix
    ./filesystem.nix
    ./boot.nix
    ./networking.nix
    ./virtualisation.nix
  ];

  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  services.usbmuxd.enable = true;

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
