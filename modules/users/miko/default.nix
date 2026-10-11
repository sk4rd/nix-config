{ den, lib, ... }:

{
  den.aspects.miko = {
    includes = [
      den.batteries.define-user
      den.aspects.development
      den.aspects.zsh
      ({ host, ... }: {
        includes = lib.optional (builtins.elem host.name [
          "desktop"
          "laptop"
        ]) den.aspects.syncthing;
      })
    ];

    user.extraGroups = [
      "wheel"
      "dialout"
      "plugdev"
    ];

    homeManager = {
      programs.home-manager.enable = true;

      programs.git.settings.user = {
        name = "Mikołaj Bajtkiewicz";
        email = "mikolaj.ba@pm.me";
      };
    };
  };
}
