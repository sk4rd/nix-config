{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          # Repository workflow
          just

          git
          ripgrep
          fd
          tree
          jq

          # Common agent scripting and inspection
          python3
          curl
          wget
          file
          unzip
          patch
          shellcheck

          # Nix development
          nixd
          nixfmt
          statix
          deadnix

          # Secrets
          sops
          ssh-to-age
        ];
      };
    };
}
