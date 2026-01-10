{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    userEmail = "mikolaj.ba@pm.me";
    signing.key = "047E2967169C053A";
    extraConfig.commit.gpgsign = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    extraPackages = with pkgs; [
      nixd
      nixfmt
    ];
    plugins = with pkgs.vimPlugins; [
      coc-tsserver
      coc-prettier
    ];
    coc = {
      enable = true;
      settings = {
        "coc.preferences.formatOnSaveFiletypes" = [
          "css"
          "markdown"
          "javascript"
          "nix"
        ];
        languageserver = {
          nixd = {
            command = "nixd";
            rootPatterns = [ ".nixd.json" ];
            filetypes = [ "nix" ];
          };
        };
        "coc.preferences.formatters" = {
          nix = {
            command = "nixfmt";
            args = [ "-" ];
          };
        };
      };
      pluginConfig = ''
        inoremap <silent><expr> <cr> coc#pum#visible() ? coc#_select_confirm() : "\<C-g>u\<CR>"

        " use <tab> to trigger completion and navigate to the next complete item
        function! CheckBackspace() abort
          let col = col('.') - 1
          return !col || getline('.')[col - 1]  =~# '\s'
        endfunction

        inoremap <silent><expr> <Tab>
          \ coc#pum#visible() ? coc#pum#next(1) :
          \ CheckBackspace() ? "\<Tab>" :
          \ coc#refresh()
      '';
    };

    extraConfig = ''
      set nu
      set rnu
    '';
  };
}
