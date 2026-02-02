{ ... }:

{
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

      clipboard.enable = true;
      clipboard.providers.wl-copy.enable = true;

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
}
