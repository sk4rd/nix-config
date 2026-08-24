{
  den.aspects.development.homeManager =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        tree

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
    };
}
