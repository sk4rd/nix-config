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

  users.users.miko.extraGroups = [
    "libvirtd"
    "kvm"
    "dialout"
  ];

  environment.systemPackages = with pkgs; [
    brave
    vesktop
    vscode
    looking-glass-client
    vial
    ifuse
    usbutils
  ];

  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
  '';

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
