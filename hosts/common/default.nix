{ pkgs, ... }:

{
  imports = [
    ./programs.nix
    ./services.nix
    ./sops.nix
    ./mounts.nix
    ./bluetooth.nix
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
    useDefaultShell = true;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
  };

  environment.shellInit = ''
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  '';

  environment.systemPackages = with pkgs; [
    # Archives
    unzip
    zip
    p7zip

    # File utilities
    tree
    file
    fd
    ripgrep

    # Network
    wget
    curl

    # System monitoring
    htop
    btop

    # JSON/data processing
    jq
  ];
}
