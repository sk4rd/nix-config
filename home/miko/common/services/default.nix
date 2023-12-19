{ ... }:

{
  # Imports for all service configurations
  imports = [
    ./gpg-agent.nix
    ./mako.nix
    ./ssh-agent.nix
    ./swayidle.nix
    ./syncthing.nix
  ];
}

