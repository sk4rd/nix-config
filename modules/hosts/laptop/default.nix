{ den, ... }:

{
  den.aspects.laptop = {
    includes = [
      den.batteries.hostname
      den.aspects.plasma-workstation
    ];

    nixos = { };
  };
}
