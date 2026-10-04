{ den, ... }:

{
  den.aspects.development = {
    includes = [ (den.batteries.unfree [ "antigravity-cli" ]) ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          tree
          antigravity-cli

          btop
          duf
          fd
          jq
          ncdu
          ripgrep
          yazi
          zellij

          python3
          curl
          wget
          file
          unzip
          patch
          shellcheck
          just

          rustup
          gcc

          nixd
          nixfmt
          statix
          deadnix
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
