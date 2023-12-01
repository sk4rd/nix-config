{ pkgs, ... }:

{
  users.users."miko" = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
    description = "Mikolaj Bajtkiewicz";
  };
}

