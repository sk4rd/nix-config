{ ... }:

{
  imports = [
    ../common
    ./boot.nix
    ./gpu-passthrough.nix
    ./hardware
    ./networking.nix
    ./ssh.nix
  ];
}
