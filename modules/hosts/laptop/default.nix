{ den, ... }:

{
  den.aspects.laptop = {
    includes = [
      den.batteries.hostname
      den.aspects.disko
      den.aspects.laptop-power
      den.aspects.plasma-workstation
    ];

    nixos = { };
  };
}
