{ ... }:

{
  programs.git = {
    enable = true;
    signing.key = "047E2967169C053A";
    settings = {
      user.email = "mikolaj.ba@pm.me";
      commit.gpgsign = true;
    };
  };
}
