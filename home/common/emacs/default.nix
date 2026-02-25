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
            tree-sitter-tsx
            tree-sitter-json
            tree-sitter-css
            tree-sitter-nix
          ]
        ))

        # Editing
        multiple-cursors

        # QoL
        rainbow-delimiters
        envrc
      ];
    extraConfig = builtins.readFile ./init.el;
  };

  home.packages = with pkgs; [
    # org-roam dependencies
    sqlite
    graphviz

    # LSP servers
    typescript-language-server
    typescript
    nil

    # Fonts
    nerd-fonts.symbols-only
    nerd-fonts.fira-code
  ];

  home.activation.createOrgDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/org/roam"
  '';
}
