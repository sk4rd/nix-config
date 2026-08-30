{ den, ... }:

{
  den.aspects.desktop = {
    includes = [
      den.batteries.hostname
      den.aspects.plasma-workstation
      den.aspects.ai
    ];

    provides.to-users.includes = [ den.aspects.ai ];

    nixos = {
      nix.settings.trusted-users = [ "miko" ];
    };
  };
}
