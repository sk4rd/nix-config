{ den, ... }:

{
  den.aspects.zsh = {
    includes = [ (den.batteries.user-shell "zsh") ];

    homeManager =
      { lib, pkgs, ... }:
      {
        programs.zsh = {
          autosuggestion.enable = true;
          syntaxHighlighting.enable = true;

          initContent = lib.mkMerge [
            (lib.mkOrder 500 ''
              fpath+=(${pkgs.zsh-completions}/share/zsh/site-functions)
              source ${pkgs.nix-zsh-completions}/share/zsh/plugins/nix/nix-zsh-completions.plugin.zsh
            '')
            (lib.mkOrder 600 ''
              eval "$(${lib.getExe pkgs.fzf} --zsh)"
            '')
            (lib.mkOrder 650 ''
              source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
            '')
            (lib.mkOrder 800 ''
              autoload -U colors && colors
              setopt prompt_subst
              ZSH_THEME_GIT_PROMPT_DIRTY="*"
              ZSH_THEME_GIT_PROMPT_CLEAN=""
              zstyle ':omz:alpha:lib:git' async-prompt no
              source ${pkgs.oh-my-zsh}/share/oh-my-zsh/lib/git.zsh
              source ${pkgs.oh-my-zsh}/share/oh-my-zsh/themes/lambda.zsh-theme
            '')
          ];
        };

        programs.fzf = {
          enable = true;
          enableZshIntegration = false;
        };

        programs.direnv = {
          enable = true;
          enableZshIntegration = true;
          nix-direnv.enable = true;
        };

        programs.zoxide = {
          enable = true;
          enableZshIntegration = true;
        };

        programs.nix-index = {
          enable = true;
          enableZshIntegration = true;
        };

        programs.eza = {
          enable = true;
          enableZshIntegration = true;
        };

        programs.bat.enable = true;
      };
  };
}
