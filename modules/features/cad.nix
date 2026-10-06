{
  den.aspects.cad = {
    homeManager =
      { lib, pkgs, ... }:
      {
        home.packages = [
          pkgs.freecad
          pkgs.kicad
          pkgs.openscad
          (pkgs.orca-slicer.overrideAttrs (old: {
            # Avoid embedding libstdc++.a alongside the Bambu plugin's shared C++ runtime.
            buildInputs = map (
              input: if input == pkgs.gcc-unwrapped then lib.getLib pkgs.gcc-unwrapped else input
            ) old.buildInputs;
            preFixup = (old.preFixup or "") + ''
              gappsWrapperArgs+=(--set SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt)
            '';
          }))
        ];
      };
  };
}
