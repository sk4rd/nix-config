{
  den.aspects.syncthing = {
    nixos.networking.firewall = {
      allowedTCPPorts = [ 22000 ];
      allowedUDPPorts = [
        22000
        21027
      ];
    };

    homeManager =
      {
        config,
        lib,
        host,
        ...
      }:
      {
        services.syncthing = {
          enable = true;
          guiAddress = "127.0.0.1:8384";
          overrideDevices = false;
          overrideFolders = false;
          settings = {
            devices = import ../../lib/syncthing-devices.nix {
              inherit lib;
              hostName = host.name;
            };
            folders = {
              documents = import ../../lib/documents-syncthing.nix {
                path = "${config.home.homeDirectory}/Documents";
                devices = builtins.attrNames config.services.syncthing.settings.devices;
              };
              hermes-profiles = import ../../lib/hermes-profiles-syncthing.nix {
                path = "${config.home.homeDirectory}/.hermes/profiles";
                devices = builtins.attrNames config.services.syncthing.settings.devices;
              };
            };
          };
        };
      };
  };
}
