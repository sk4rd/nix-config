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
        embark
        embark-consult
        corfu
        cape
        nerd-icons-corfu

        # Snippets
        yasnippet
        yasnippet-snippets

        # Git
        magit
        diff-hl

        # UI
        treemacs
        doom-themes
        doom-modeline
        nerd-icons
        which-key

        # Languages
        nix-mode

        # Formatters
        apheleia

        # Notes
        denote

        # Tree-sitter grammars
        (treesit-grammars.with-grammars (
          grammars: with grammars; [
            tree-sitter-javascript
            tree-sitter-typescript
            tree-sitter-tsx
            tree-sitter-json
            tree-sitter-css
            tree-sitter-nix
            tree-sitter-python
          ]
        ))

        # Editing
        multiple-cursors
        expand-region
        smartparens
        avy
        ace-window
        olivetti
        undo-fu

        # QoL
        rainbow-delimiters
        envrc
      ];
    extraConfig = builtins.readFile ./init.el;
  };

  home.packages = with pkgs; [
    # LSP servers
    typescript-language-server
    typescript
    nixd
    pyright

    # Formatters
    nixfmt-rfc-style
    nodePackages.prettier

    # Search tools
    ripgrep

    # Fonts
    nerd-fonts.symbols-only
    nerd-fonts.fira-code
  ];

  home.activation.createOrgDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/org/denote"
    touch "$HOME/org/tasks.org" "$HOME/org/notes.org" "$HOME/org/projects.org" "$HOME/org/journal.org"
  '';
}
