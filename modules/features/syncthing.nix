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
      let
        directory = config.programs.emacs.notesDirectory;
        path =
          if lib.hasPrefix "~/" directory then
            "${config.home.homeDirectory}/${lib.removePrefix "~/" directory}"
          else
            directory;
      in
      {
        services.syncthing = {
          enable = true;
          guiAddress = "127.0.0.1:8384";
          overrideDevices = false;
          overrideFolders = false;
          settings = import ../../lib/org-notes-syncthing.nix {
            inherit lib path;
            hostName = host.name;
          };
        };
      };
  };
}
