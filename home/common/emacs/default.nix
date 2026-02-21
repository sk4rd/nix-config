{ pkgs, lib, ... }:

{
  programs.emacs = {
    enable = true;
    extraPackages =
      epkgs: with epkgs; [
        # Completion
        vertico
        orderless
        marginalia
        consult
        corfu
        cape

        # Org
        org-roam

        # Git
        magit

        # UI
        modus-themes
        doom-modeline
        nerd-icons
        which-key

        # Languages
        nix-mode
        js2-mode

        # Tree-sitter grammars
        (treesit-grammars.with-grammars (
          grammars: with grammars; [
            tree-sitter-javascript
            tree-sitter-typescript
            tree-sitter-json
            tree-sitter-css
            tree-sitter-nix
          ]
        ))

        # QoL
        rainbow-delimiters
        envrc
      ];
    extraConfig = builtins.readFile ./init.el;
  };

  home.packages = with pkgs; [
    # org-roam dependency
    sqlite

    # LSP servers
    typescript-language-server
    typescript
    nil

    # Fonts for doom-modeline
    nerd-fonts.symbols-only
  ];

  home.activation.createOrgDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/org/roam"
  '';
}
