{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          # Repository workflow
          just
          python3
          git
          ripgrep
          jq

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
