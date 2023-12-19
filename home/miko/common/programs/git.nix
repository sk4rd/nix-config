{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    lfs.enable = true;
    package = pkgs.gitFull;
    userName = "Mikolaj Bajtkiewicz";
    userEmail = "mikolaj.bajtkiewicz@tutanota.de";
    signing = {
      key = "013305C22DC1923F";
      signByDefault = true;
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
