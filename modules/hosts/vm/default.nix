{ den, ... }:

{
  den.aspects.vm = {
    includes = [
      den.batteries.hostname
      den.aspects.graphical
      den.aspects.libvirt
      den.aspects.openssh-password
      den.aspects.xfce
    ];

    nixos = { };
  };
}
