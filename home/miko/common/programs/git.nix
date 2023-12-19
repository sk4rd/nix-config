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
      br = "branch";
      ci = "commit";
      co = "checkout";
      ps = "push";
      pl = "pull";
      rs = "restore";
      rst = "reset";
      s = "status";
    };
  };
}
