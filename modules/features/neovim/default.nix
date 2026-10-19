{
  den.aspects.neovim.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      palette = builtins.fromJSON (builtins.readFile ../../../themes/neon-flux/palette.json);
      luaTable = value: "vim.json.decode(${builtins.toJSON (builtins.toJSON value)})";
    in
    {
      options.programs.neovim.notesDirectory = lib.mkOption {
        type = lib.types.str;
        default = "~/Documents/notes";
        description = "Writable Markdown vault for Neovim; existing Org files are left untouched.";
      };

      config = {
        programs.neovim = {
          enable = true;
          defaultEditor = true;
          withPython3 = false;
          withRuby = false;
          extraPackages = with pkgs; [
            ripgrep
            fd
            git
            direnv
            nixd
            nixfmt
            wl-clipboard
            yazi
            file
            xdg-utils
          ];
          plugins = with pkgs.vimPlugins; [
            plenary-nvim
            telescope-nvim
            yazi-nvim
            neo-tree-nvim
            vim-sleuth
            nvim-cmp
            cmp-nvim-lsp
            cmp-buffer
            cmp-path
            gitsigns-nvim
            neogit
            diffview-nvim
            which-key-nvim
            nvim-autopairs
            nvim-web-devicons
            lualine-nvim
            direnv-nvim
            obsidian-nvim
            (nvim-treesitter.withPlugins (
              p: with p; [
                nix
                lua
                bash
                json
                python
                markdown
                markdown_inline
                vim
                vimdoc
                query
              ]
            ))
          ];
          initLua = builtins.readFile ./init.lua;
        };
        fonts.fontconfig.enable = true;
        home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
        xdg.configFile = {
          "nvim/colors/neon-flux.lua".source = ./colors/neon-flux.lua;
          "nvim/lua/neon-flux-palette.lua".text = "return ${luaTable palette}\n";
          "nvim/lua/neon-flux-settings.lua".text = "return ${
            luaTable { notesDirectory = config.programs.neovim.notesDirectory; }
          }\n";
        };
      };
    };
}
