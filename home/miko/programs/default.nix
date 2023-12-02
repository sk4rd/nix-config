{ pkgs, ... }:

{
  imports = [
    ./emacs.nix
    ./firefox.nix
    ./git.nix
    ./github.nix
    ./kitty.nix
    ./lf
    ./mangohud.nix
    ./neofetch
    ./shell.nix
    ./syncthing.nix
    ./rofi.nix
    ./hyprland.nix
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
    swww # Wallpaper switcher
    wayshot # Screenshot tool for wlroots
    slurp # Area selection tool for wlroots
    imv # Wayland image viewer
    mpv # Minimal video player
  ];
}

