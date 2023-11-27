{ pkgs, ... }:

{
  imports = [ ./git.nix ./steam.nix ./zsh.nix ];

  # Programs that don't require configuration
  environment.systemPackages = with pkgs; [ virt-manager ];
}
