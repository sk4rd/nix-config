{ den, ... }:

{
  den.aspects.desktop = {
    includes = [
      den.batteries.hostname
      den.aspects.plasma-workstation
    ];

    nixos = { };
  };
}
