{ pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ./filesystem.nix
    ./boot.nix
    ./programs.nix
    ./networking.nix
    ./services.nix
    ./virtualisation.nix
  ];

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  users.users.miko = {
    isNormalUser = true;
    description = "Mikolaj Bajtkiewicz";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "libvirtd"
      "kvm"
      "dialout"
    ];
  };

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

  environment.shellInit = ''
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  '';

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.05";
}
