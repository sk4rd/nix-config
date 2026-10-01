{ lib, ... }:

{
  den.aspects.openssh-key-only = {
    nixos.services.openssh = {
      enable = true;
      authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
      settings = {
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    provides.to-users =
      { user, ... }:
      lib.optionalAttrs (user.name == "miko") {
        user.openssh.authorizedKeys.keys = [
          (lib.removeSuffix "\n" (builtins.readFile ../users/miko/ssh.pub))
        ];
      };
  };

  den.aspects.openssh-password.nixos.services.openssh = {
    enable = true;
    settings = {
      KbdInteractiveAuthentication = true;
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };
}
