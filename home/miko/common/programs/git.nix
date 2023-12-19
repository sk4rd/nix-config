{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    lfs.enable = true;
    package = pkgs.gitFull;

    userEmail = "mikolaj.bajtkiewicz@tutanota.de";
    userName = "Mikolaj Bajtkiewicz";

    signing = {
      signByDefault = true;
      key = "013305C22DC1923F";
    };

    aliases = {
      a = "add";
      b = "branch";
      c = "commit";
      ch = "checkout";
      p = "push";
      pl = "pull";
      res = "restore";
      s = "status";
    };
  };
}
