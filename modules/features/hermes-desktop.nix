{ inputs, ... }:

{
  den.aspects.hermes-desktop.homeManager =
    { config, pkgs, ... }:
    let
      driverArchive = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.pm-cua-driver;
      cuaDriver = pkgs.stdenv.mkDerivation {
        pname = "hermes-cua-driver";
        inherit (driverArchive) version;
        src = driverArchive;
        nativeBuildInputs = [
          pkgs.autoPatchelfHook
          pkgs.makeWrapper
        ];
        buildInputs = [
          pkgs.libx11
          pkgs.libxi
          pkgs.libxkbcommon
          pkgs.stdenv.cc.cc.lib
        ];
        dontBuild = true;
        installPhase = ''
          runHook preInstall
          mkdir -p "$out/libexec/cua-driver" "$out/bin"
          cp -r . "$out/libexec/cua-driver/"
          ln -s "$out/libexec/cua-driver/cua-driver" "$out/bin/cua-driver"
          runHook postInstall
        '';
        # The driver invokes gdbus for accessibility and Wayland diagnostics.
        postFixup = ''
          wrapProgram "$out/bin/cua-driver" \
            --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.glib.bin ]}
        '';
        doInstallCheck = true;
        installCheckPhase = ''
          runHook preInstallCheck
          "$out/bin/cua-driver" --version
          "$out/bin/cua-driver" manifest
          runHook postInstallCheck
        '';
        meta.mainProgram = "cua-driver";
      };
      driverCommand = "${cuaDriver}/bin/cua-driver";
      # The driver's manifest points Hermes at its unwrapped executable.
      driverWrapperArgs = ''
        --set HERMES_CUA_DRIVER_CMD ${driverCommand} \
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.glib.bin ]}
      '';
    in
    {
      imports = [ inputs.hermes-agent.homeManagerModules.default ];

      home.packages = [ cuaDriver ];
      services.hermes-agent.extraDependencyGroups = [ "computer-use" ];

      programs.hermes-agent = {
        enable = true;
        package =
          (config.services.hermes-agent.package.override {
            inherit (config.services.hermes-agent) extraDependencyGroups extraPythonPackages;
          }).overrideAttrs
            (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
              postFixup = (old.postFixup or "") + ''
                for command in hermes hermes-agent hermes-acp; do
                  wrapProgram "$out/bin/$command" ${driverWrapperArgs}
                done
              '';
            });
        desktop = {
          enable = true;
          # The upstream module supplies extraEnv itself; wrap afterwards so
          # application-menu launches also receive the pinned driver path.
          package = config.programs.hermes-agent.package.hermesDesktop.overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
            postFixup = (old.postFixup or "") + ''
              wrapProgram "$out/bin/hermes-desktop" \
                ${driverWrapperArgs}
            '';
          });
        };
      };
    };
}
