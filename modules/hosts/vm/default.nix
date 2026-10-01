{ den, ... }:

{
  den.aspects.vm = {
    includes = [
      den.aspects.graphical
      den.aspects.openssh-password
      den.aspects.plasma
    ];

  };
}
