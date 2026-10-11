{ den, ... }:

{
  den.aspects.development = {
    includes = [ (den.batteries.unfree [ "antigravity-cli" ]) ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          btop
          curl
          deadnix
          duf
          fd
          file
          gcc
          jq
          just
          ncdu
          nixd
          nixfmt
          opencode
          patch
          python3
          ripgrep
          rustup
          shellcheck
          statix
          tree
          unzip
          wget
          yazi
          zellij
        ];

        programs.git = {
          enable = true;
          settings = {
            init.defaultBranch = "main";
            pull.rebase = true;
          };
        };

        programs.lazygit = {
          enable = true;
          # Reviewing local changes should not automatically fetch remotes.
          settings.git.autoFetch = false;
        };
      };
  };
}
