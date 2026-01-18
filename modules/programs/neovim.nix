{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.profiles.editor.neovim;
in
{
  options.profiles.editor.neovim.enable = mkEnableOption "my neovim (nvf) setup";

  config = mkIf cfg.enable {
    programs.nvf = {
      enable = true;
      settings.vim = {
        options = {
          tabstop = 2;
          shiftwidth = 2;
        };

        theme = {
          enable = true;
          name = "onedark";
          style = "warm";
        };

        ui.breadcrumbs.enable = true;

        telescope.enable = true;

        autopairs.nvim-autopairs.enable = true;

        terminal.toggleterm = {
          enable = true;
          setupOpts.direction = "float";
        };

        lineNumberMode = "relative";

        lsp = {
          enable = true;
          formatOnSave = true;
        };

        languages = {
          enableFormat = true;
          ts.enable = true;
          nix = {
            enable = true;
            format.type = [ "nixfmt" ];
          };
        };
        autocomplete.blink-cmp.enable = true;
      };
    };
  };
}
