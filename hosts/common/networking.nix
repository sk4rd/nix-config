{ lib, ... }:

{
  # Default networking configuration
  networking = lib.mkDefault {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall.enable = true;
    firewall.allowedTCPPorts = [
      22 # ssh
      22000 # Syncthing TCP
    ];
    firewall.allowedUDPPorts = [
      22000 # Syncthing QUIC
      21027 # Syncthing discovery broadcast
      51820 # WireGuard
    ];
  };
}
