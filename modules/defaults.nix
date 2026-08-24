{ den, lib, ... }:

{
  den.default = {
    includes = [
      den.aspects.base
      den.aspects.locale
      den.aspects.secrets
    ];

    nixos.system.stateVersion = "26.05";
    homeManager.home.stateVersion = "26.05";
  };

  den.schema.user.classes = lib.mkDefault [
    "user"
    "homeManager"
  ];
}
