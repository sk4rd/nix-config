{ pkgs, ... }:

{
  imports = [
    ./emacs.nix
    ./firefox.nix
    ./git.nix
    ./github.nix
    ./mangohud.nix
    ./shell.nix
    ./syncthing.nix
    ./kitty.nix
    ./lf
    ./neofetch
  ];

  # Programs without configuration
  home.packages = with pkgs; [
    discord # Internet messaging platform
    element-desktop # Secure messaging app
    gimp # Advanced image editing tool
    keepassxc # Secure password management
    lutris # Game launcher
    monero-gui # Cryptocurrency wallet for Monero
    prismlauncher # Launcher for Minecraft
    protonup-qt # Proton version manager
    xournalpp # App for taking handwritten notes
  ];
}

