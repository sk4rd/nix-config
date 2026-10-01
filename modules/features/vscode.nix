{ den, ... }:

{
  den.aspects.vscode.includes = [
    (den.batteries.unfree [ "vscode" ])
  ];

  den.aspects.vscode.homeManager =
    { pkgs, ... }:
    {
      # Match the font families used by the portable Neon Flux settings.
      fonts.fontconfig.enable = true;
      home.packages = with pkgs.nerd-fonts; [
        jetbrains-mono
        blex-mono
      ];

      programs.vscode = {
        enable = true;
        package = pkgs.vscode;
        mutableExtensionsDir = false;
        profiles.default = {
          enableUpdateCheck = false;
          enableExtensionUpdateCheck = false;
          userSettings = builtins.fromJSON (builtins.readFile ./vscode/settings.json);
          userTasks =
            let
              taskConfig = builtins.fromJSON (builtins.readFile ./vscode/tasks.json);
            in
            builtins.removeAttrs taskConfig [ "problemMatcher" ]
            // {
              tasks = map (task: task // { inherit (taskConfig) problemMatcher; }) taskConfig.tasks;
            };
          keybindings = ./vscode/keybindings.jsonc;
          languageSnippets.rust = builtins.fromJSON (builtins.readFile ./vscode/rust-snippets.json);
          # remote-wsl is Windows-only; the other personal-profile extensions are portable.
          extensions = with pkgs.vscode-extensions; [
            christian-kohler.path-intellisense
            rust-lang.rust-analyzer
            tamasfe.even-better-toml
            usernamehw.errorlens
            vadimcn.vscode-lldb
            yzhang.markdown-all-in-one
          ];
        };
      };
    };
}
