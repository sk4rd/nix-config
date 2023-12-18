{ pkgs, ... }:

{
  # GitHub CLI configuration
  programs.gh = {
    enable = true;
    extensions = with pkgs; [ gh-dash gh-eco gh-markdown-preview ];
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
  };
}
