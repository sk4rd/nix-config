# Neovim

The `neovim` aspect is enabled beside Emacs for desktop and laptop users. It
sets Neovim as `$EDITOR` and `$VISUAL`, without changing `vi` or `vim`. Plugins,
parsers and tools
are pinned through nixpkgs; there is no startup plugin manager or Mason download.

## Editing

Neon Flux reads `themes/neon-flux/palette.json`, matching the Emacs syntax roles,
UI surfaces, diagnostics and Git colors. Terminal Neovim inherits its font from
the terminal; GUI clients request JetBrainsMono NFM.

Native Vim modal editing and default navigation/LSP bindings are retained (not
an emulation of Meow). Window navigation remains `Ctrl-w h/j/k/l`, `gd` retains
its native local-declaration behavior, and Neovim's `gr*` bindings are unchanged.
Space is the leader for additional plugin actions; which-key shows shortcuts.
Completion provides LSP, paths and
buffer words, with automatic pairs and native snippet expansion. Tree-sitter
covers Nix, Lua, shell, JSON, Python, Markdown, Vim and help. Nix uses nixd with
nixfmt formatting on save; other language servers can be provided by project
shells and configured through `vim.lsp.config` / `vim.lsp.enable`. Direnv loads
only environments already authorized with `direnv allow`. Completion uses
`Ctrl-n`/`Ctrl-p` to select, `Tab` or `Ctrl-y` to accept the selected item and
`Ctrl-e` to cancel; `Ctrl-Space` requests completion. Without a selected item,
Tab keeps its normal indentation behavior. Enter remains a newline, not completion accept.

| Key | Action |
| --- | --- |
| `Space ff` / `fr` | Find files / recent files |
| `Space bb` | Buffers |
| `Space sp` / `sb` | Search project / current buffer |
| `Space pf` / `pd` | Git project files / change to project root |
| `Space fe` | Toggle persistent Neo-tree sidebar |
| `Space fd` | Yazi directory browser at current file |
| `Space cg` / `cR` | Telescope definitions / references |
| `grr` / `K` | Native Neovim references / documentation |
| `Space ca` / `cr` / `cf` / `cd` | Code action / rename / format / diagnostics |
| `Space cv` | Reload direnv |
| `Space gg` | Magit-style Neogit status tab |
| `Space gd` / `gh` | Diffview working-tree diff / current-file history |
| `[h` / `]h` | Previous / next Git hunk |
| `Space gp` / `gs` / `gr` / `gb` | Preview / stage / reset hunk / blame |
| `Space tv` | Terminal split (`Esc Esc` returns to normal mode) |
| `Ctrl-w h/j/k/l` | Native adjacent-window navigation |

Persistent undo and recovery state stay in Neovim's XDG state/data directories.
Neogit provides the Magit-style Git workflow described below. Emacs's gptel
OAuth chats and agent presets are not ported; no credentials are copied.

## Sidebar and project directories

`Space fe` toggles Neo-tree on the right; `Space fd` keeps floating Yazi.
Yazi selections use MIME detection: text/code opens in Neovim, while PDFs,
images and other non-text files use the desktop default application through
`vim.ui.open`/`xdg-open`. This is a chooser-mode adaptation, not a copy of every
standalone Yazi opener rule. Explicit split/tab actions still target Neovim.
Neo-tree follows the tab-local cwd, without competing with Yazi's directory
handling. In the tree, Enter expands a directory or opens a file, Backspace
moves to the parent root, and `.` makes the selected directory the root and
sets this tab's working directory. Use `?` for tree help and `q` to close it.

For another project in a separate tab, use `:tabnew`, then `:tcd /path/to/project`
and `Space fe`. Other tabs keep their directories. Existing buffers and LSP
workspaces are not reset. A prior window-local `:lcd` can still override a tab's
cwd; use `:tcd` from that editing window to return it to tab scope.

## Git: Neogit and Diffview

`Space gg` opens Neogit inside Neovim, with expandable status sections and
Magit-like action popups. Gitsigns remains available while editing. Telescope
handles Neogit's selection dialogs; Diffview provides larger diff/history views.
Opening status does not fetch; fetch-after-checkout is explicitly disabled.

Inside Neogit (buffer-local bindings, not replacements for normal editing):

| Key | Action |
| --- | --- |
| `Tab` | Expand/collapse a file or hunk |
| `s` / `u` | Stage / unstage selection |
| `c` | Commit popup; choose `c` again for a normal commit |
| `b` | Branch popup |
| `l` | Log popup |
| `Z` | Stash popup |
| `p` / `P` | Pull / push popup (explicit network actions) |
| `?` | Available actions and help |
| `q` | Close status |

Use `:DiffviewClose` to close a diff view. Destructive actions such as discard,
reset and force-push remain explicit plugin actions; configuration does not run
them automatically. The standalone Lazygit development tool is unchanged, but
Neovim no longer launches it as its primary Git interface.

## Markdown notes

The maintained `obsidian-nvim/obsidian.nvim` plugin provides linked Markdown
notes with Telescope as its picker. The Obsidian desktop app is not required.
`programs.neovim.notesDirectory` defaults independently to `~/Documents/notes`.
Changing it does not move any files. Documents sync/backup rules remain unchanged;
see [Documents sync](documents-sync.md).

```text
notes/
├── inbox.md
├── daily/          # YYYY-MM-DD.md
├── projects/
├── knowledge/      # default destination for new notes
├── templates/      # knowledge, project and daily
└── attachments/
```

Startup creates missing folders, inbox and starter templates exclusively: existing
Markdown and templates are never overwritten. Existing Org files and Emacs's
configuration remain untouched; there is no automatic conversion. Neovim no longer
installs orgmode or org-roam. Old Org notes remain editable as plain text or in Emacs.

Notes use ordinary headings, code fences, checkboxes and relative Markdown links.
Automatic YAML frontmatter, decorative plugin UI, footer and statusline are disabled.
No database or Obsidian-only query language is required to read your notes.
Markdown buffers wrap, spell-check and hide code line numbers.

| Key | Action |
| --- | --- |
| `Space nc` | Open inbox for quick capture |
| `Space nn` | Create knowledge note from template |
| `Space nd` | Open/create today's daily note from template |
| `Space nf` | Telescope note quick switch |
| `Space ns` | Telescope note-content search |
| `Space no` | Telescope Markdown file browser |
| `Space na` | Telescope daily-note browser (not an Org agenda) |
| `Space ni` | Insert a note link |
| `Space nb` | Show backlinks |
| `Space nt` | Choose and insert a template |
| `Space nl` | Follow link |
| `Space nx` | Toggle task checkbox |

Normal-mode Enter is not remapped. Use native editing and `:write` to save;
there is no special capture finalization. Link/reference completion is supplied by
obsidian.nvim's in-process LSP through the existing nvim-cmp LSP source.
`:Obsidian new projects/my-project` creates a project note; use `Space nt` to
insert the project template (replace the initial knowledge headings if unwanted).

Start in the inbox or daily log; promote reusable explanations into knowledge
notes and project-specific decisions into project notes. Link related notes rather
than building deep folder trees. Markdown checkboxes are lightweight tasks, not
an Org-style scheduler, recurring-task system or clocking agenda.

## Verification and activation

Use `just format` and `just check` for repository checks. Run the isolated runtime
test with:

```sh
python3 modules/features/neovim/test.py
```

It builds the evaluated desktop wrapper and plugin pack, generates its actual XDG
configuration, and runs `test.lua` in a temporary HOME. It verifies preservation
of existing Org/Markdown notes, theme colors, Markdown templates, parsers, completion,
keymaps, real nixd attachment and nixfmt-on-save without touching live notes.
It also creates real knowledge and daily notes, requests real Nix identifier
completions, exercises project and Obsidian Telescope pickers, and checks that
default navigation bindings and normal-mode Enter survive.

New files must be tracked before Git-backed flake commands include them. A
`path:/absolute/path/to/nix-config` flake includes untracked files for validation.
Activate through the normal NixOS/Home Manager rebuild, then run `nvim`.
