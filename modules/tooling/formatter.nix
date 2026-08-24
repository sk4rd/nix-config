{
  perSystem =
    { pkgs, ... }:
    {
      formatter = pkgs.writeShellApplication {
        name = "nixfmt-tree";
        runtimeInputs = [ pkgs.nixfmt-tree ];
        text = ''
          exec treefmt --tree-root "$PWD" "$@"
        '';
      };
    };
}
