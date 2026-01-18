{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    userEmail = "mikolaj.ba@pm.me";
    signing.key = "047E2967169C053A";
    extraConfig.commit.gpgsign = true;
  };
}
