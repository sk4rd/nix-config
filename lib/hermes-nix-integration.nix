{ package }:
let
  site = package.python.sitePackages;
  patchedVenv = package.hermesVenv.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      rm "$out/${site}/hermes_cli"
      cp -rL ${package.hermesVenv}/${site}/hermes_cli "$out/${site}/hermes_cli"
      chmod -R u+w "$out/${site}/hermes_cli"
      ${package.python}/bin/python3 ${./patch_hermes_nix_integration.py} "$out/${site}"
    '';
  });
in
package.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    for command in hermes hermes-agent hermes-acp; do
      substituteInPlace "$out/bin/$command" --replace-fail '${package.hermesVenv}' '${patchedVenv}'
    done
    substituteInPlace "$out/manifest.json" "$out/command-map.json" \
      --replace-fail '${package.hermesVenv}' '${patchedVenv}'
  '';
  passthru = (old.passthru or { }) // {
    hermesVenv = patchedVenv;
  };
})
