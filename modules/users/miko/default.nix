{ den, ... }:

{
  den.aspects.miko = {
    includes = [
      den.batteries.define-user
      den.aspects.development
      den.aspects.firefox
      den.aspects.lf
      den.aspects.zsh
    ];

    user.extraGroups = [ "wheel" ];

    homeManager = {
      programs.home-manager.enable = true;

      programs.git.settings.user = {
        name = "Mikołaj Bajtkiewicz";
        email = "mikolaj.ba@pm.me";
      };
    };
  };
}
