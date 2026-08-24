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
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC4s+vM18hSyCDoHIGEfylsJ2sJUgUmgewzbslm6GlnegQlAtCS+d/cinNcXvrlUudxnpcVjEys8yEqd1tY0Une4ixefB5mJ/hgdxqnaII3StdPkAsWWlFBmyrVXrgTomKapTBfDQ0TC+cGEdZi9LVMtxA2ZaREZSjErSlMkanLokvHmSlz3a1nYEHPkh35EjMRJ2f4GF+wfi6zDOY6S4mII+38F1PdY4DgRirhweZnqjdM3BNXz4T0tLdMi5wIBgCdRAAhjYaAI6ngs/r0w4p5mJ6Mats3LmRzAJi635b7kM449fFdgum9y3SG5QucXpcTs9wYIWrh9TJWTAPv0qSDmZjdwn1Lzozij/XKAs3E5xXN2lvLoMGKRfY/nrEZ03l27EzN/T2kPKJRPryR8/WlCNUpoJoKvszGPqB5HpjJLhRB16dD0dFc65ToB1sp/FWtmWGT6qia4YPqeSx9o0kvUzdhXDHLVKStHec4hAzW2MUnqCgc7Ql054ljG5Ks8panQsH0yaOuRN/ztwZuSPiaC7fqIBCGcyYCIW3QMlx7z49pBMwfCZQTocQP9Mive3Pp6fVbI6CIQD7lhs0B6HhYstbfAl+k3V6uBiXx5H5cSAAMOBRqXxApeHvaYqzdPEJKUsvPLSqnMt0yOqw54U64sEFiZ59Rl/NRCBSKq7Zaww== openpgp:0x969EB784"
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
