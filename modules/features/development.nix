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

        # Media utilities
        yt-dlp
        mpv
        ffmpeg
        localsend

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
