{ den, ... }:

let
  inherit (import ../../../lib/nas-service-helpers.nix) mountSafety;
in
{
  den.aspects.silverbullet-neon-flux-theme.includes = [ den.aspects.silverbullet ];

  den.aspects.silverbullet-neon-flux-theme.nixos =
    { pkgs, lib, ... }:
    let
      palette = builtins.fromJSON (builtins.readFile ../desktop/neon-flux-theme/palette.json);
      theme = pkgs.writeText "silverbullet-neon-flux.md" (
        lib.replaceStrings (map (name: "@${name}@") (
          builtins.attrNames palette
        )) (builtins.attrValues palette) (builtins.readFile ./silverbullet/neon-flux.md)
      );
    in
    {
      systemd.services.silverbullet-theme = mountSafety [ "/srv/silverbullet" ] // {
        description = "Install the SilverBullet Neon Flux theme";
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.coreutils ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "silverbullet";
          Group = "silverbullet";
        };
        script = ''
          space=/srv/silverbullet/space/spaces/notes
          if [ ! -d "$space" ]; then
            echo 'SilverBullet theme skipped: create the notes space in Space Manager, then restart silverbullet-theme.service.' >&2
            exit 0
          fi
          install -T -m 0644 ${theme} "$space/Neon Flux.md"
        '';
      };
    };
}
