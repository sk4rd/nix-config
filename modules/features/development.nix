{
  den.aspects.development.homeManager =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        tree

        # Terminal utilities
        btop
        duf
        fd
        jq
        ncdu
        ripgrep
        yazi
        zellij

        # Rust
        rustup
        gcc

        # Nix
        nixd
        nixfmt
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
}
