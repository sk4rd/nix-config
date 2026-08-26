{ den, lib, ... }:

{
  den.default = {
    includes = [
      den.aspects.base
      den.aspects.locale
      den.aspects.secrets
    ];

    nixos.system.stateVersion = lib.mkDefault "26.05";
    homeManager.home.stateVersion = lib.mkDefault "26.05";
  };

  den.schema.user.classes = lib.mkDefault [
    "user"
    "homeManager"
  ];
}
