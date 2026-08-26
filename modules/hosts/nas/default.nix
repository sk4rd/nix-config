{ den, ... }:

{
  den.aspects.nas = {
    includes = [
      den.batteries.hostname
      den.aspects.nas-server
    ];

    nixos = {
      nix.settings.trusted-users = [ "admin" ];
      security.sudo.extraRules = [
        {
          users = [ "admin" ];
          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
      system.stateVersion = "25.05";
    };
  };
}
