{ pkgs, ... }:

{
  imports = [
    ./emacs.nix
    ./firefox.nix
    ./git.nix
    ./github.nix
    ./hyprland
    ./kitty.nix
    ./lf
    ./mangohud.nix
    ./neofetch
    ./rofi.nix
    ./shell.nix
    ./swaylock.nix
    ./waybar.nix
  ];

  # Programs without configuration
  home.packages = with pkgs; [
    discord # Internet messaging platform
    element-desktop # Secure messaging app
    gimp # Advanced image editing tool
    imv # Wayland image viewer
    keepassxc # Secure password management
    lutris # Game launcher
    monero-gui # Cryptocurrency wallet for Monero
    mpv # Minimal video player
    mullvad-browser # Mullvad firefox based browser
    prismlauncher # Launcher for Minecraft
    protonup-qt # Proton version manager
    rnote # App for taking handwritten notes
    slurp # Area selection tool for wlroots
    swww # Wallpaper switcher
    wayshot # Screenshot tool for wlroots
  ];
}

