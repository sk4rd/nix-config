{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShellNoCC {
        packages = with pkgs; [

          just

          git
          ripgrep
          fd
          tree
          jq

          python3
          curl
          wget
          file
          unzip
          patch
          shellcheck

          nixd
          nixfmt
          statix
          deadnix

          sops
          ssh-to-age
        ];
      };
    };
}
