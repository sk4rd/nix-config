{ pkgs, ... }:

{
  imports = [ ./git.nix ./hyprland.nix ./steam.nix ./thunar.nix ./zsh.nix ];

  # Programs that don't require configuration
  environment.systemPackages = with pkgs; [ virt-manager ];
}
