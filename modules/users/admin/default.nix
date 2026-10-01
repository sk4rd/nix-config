{ den, lib, ... }:

{
  den.aspects.admin = {
    includes = [ den.batteries.define-user ];

    user = {
      description = "NAS Admin";
      uid = 1000;
      extraGroups = [
        "docker"
        "wheel"
      ];
      openssh.authorizedKeys.keys = [
        (lib.removeSuffix "\n" (builtins.readFile ../miko/ssh.pub))
      ];
    };
  };
}
