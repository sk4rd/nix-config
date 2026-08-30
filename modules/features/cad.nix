{
  den.aspects.cad.homeManager =
    { pkgs, ... }:
    let
      orca-slicer =
        if pkgs.orca-slicer.version == "2.4.2" then
          pkgs.orca-slicer.overrideAttrs (oldAttrs: {
            # Work around https://github.com/NixOS/nixpkgs/pull/557126.
            buildInputs = builtins.filter (input: input != pkgs.gcc-unwrapped) oldAttrs.buildInputs;

            preFixup = oldAttrs.preFixup + ''
              gappsWrapperArgs+=(
                --set SSL_CERT_FILE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              )
            '';
          })
        else
          pkgs.orca-slicer;
    in
    {
      home.packages = [
        orca-slicer
        pkgs.freecad
        pkgs.kicad
        pkgs.openscad
      ];
    };
}
