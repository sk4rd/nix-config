{ den, lib, ... }:

{
  den.aspects.zed.includes = [ (den.batteries.unfree [ "antigravity-acp" ]) ];

  den.aspects.zed.homeManager =
    { pkgs, ... }:
    {
      programs.zed-editor = {
        enable = true;

        # extraPackages puts nixd on the editor's PATH for the Nix extension.
        extraPackages = [ pkgs.nixd ];

        # Auto-installed on first start; built-in languages need no extension entry.
        extensions = [
          "nix" # Nix syntax + nixd
          "just" # Justfile, the task runner this repository uses
          "toml" # Cargo.toml and friends
          "git-firefly" # inline blame in the gutter
          "color-highlight" # paints #RRGGBB literals inline
        ];

        # Keep default mutableUserSettings for GUI edits. Its shallow merge replaces
        # configured top-level keys wholesale and preserves other settings.
        userSettings = {
          agent_servers."Google Antigravity" = {
            type = "custom";
            command = lib.getExe pkgs.antigravity-acp;
            args = [ "--uid=" ];
            env = { };
          };
        };
      };
    };
}
