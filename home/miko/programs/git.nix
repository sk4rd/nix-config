{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    lfs.enable = true;
    package = pkgs.gitFull;
    userName  = "Mikolaj Bajtkiewicz";
    userEmail = "mikolaj.bajtkiewicz@tutanota.de";
    config.init.defaultBranch = "main";
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
