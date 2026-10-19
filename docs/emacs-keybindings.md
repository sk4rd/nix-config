# Emacs keybindings

The most important bindings to learn, based on this repository's Emacs config.
Plain-letter editing keys apply in **Meow Normal mode**.

**Notation:** `C-` = Ctrl, `M-` = Alt, `SPC` = Space. `C-x C-f` means
press Ctrl+x, then Ctrl+f.

## 1. Everyday essentials

| Binding | Action |
|---|---|
| `C-g` | Cancel a command or escape a prompt |
| `M-x` | Run any command by name |
| `C-x C-f` | Open/create a file |
| `C-x C-s` | Save the current file |
| `C-x b` | Switch buffers with Consult |
| `C-x k` | Close a buffer |
| `C-x C-r` | Open a recent file |
| `C-h k` | Press a key to see what it does |
| `SPC ?` | Show your Meow cheatsheet |

**Discovery tip:** pause after a prefix such as `C-c`, `C-x p`, or `C-c n`—Which-key
shows available continuations.

## 2. Meow editing

| Binding | Action |
|---|---|
| `i` / `a` | Enter Insert mode before/after the cursor |
| `Esc` | Return from Insert to Normal mode |
| `h j k l` | Move left/down/up/right |
| `b` / `e` | Move backward/forward by word |
| `w` | Select a word; repeat to extend |
| `x` | Select a line; repeat to extend |
| `H J K L` | Extend the selection left/down/up/right |
| `y` | Copy the selection |
| `s` | Cut the selection |
| `d` | Delete the selection |
| `c` | Replace the selection by typing |
| `p` | Paste |
| `u` | Undo |
| `g` | Cancel the selection |
| `A` / `I` | Open a new line below/above and insert |

A useful practice loop: **`w` → `y` → move → `p`** to copy a word, or
**`w` → `c` → type → `Esc`** to replace it.

## 3. Search and projects

| Binding | Action |
|---|---|
| `M-s r` | Search file contents with ripgrep |
| `M-s l` | Search lines in the current buffer |
| `C-s` / `C-r` | Incremental search forward/backward |
| `C-x p p` | Switch projects |
| `C-x p f` | Find a file in the project |
| `C-x p b` | Switch to a project buffer |
| `C-x p g` | Project ripgrep search |
| `SPC p` | Switch projects from Meow Normal mode |

Inside search/completion prompts:

| Binding | Action |
|---|---|
| `C-n` / `C-p` | Next/previous result |
| `M-p` / `M-n` | Previous/next query in history |
| `RET` | Accept the selected result |
| `C-.` | Open Embark actions for the selected item |

Results wrap around. Ripgrep results preview automatically after 0.3 seconds.
To reopen a closed search: **`M-x consult-resume`**.

## 4. Windows

An Emacs *window* is a pane; a *buffer* holds a file or other content.

| Binding | Action |
|---|---|
| `C-x 2` | Split into top/bottom panes |
| `C-x 3` | Split into left/right panes |
| `C-c` + arrow | Move to the pane in that direction |
| `C-x 0` | Close the current pane |
| `C-x 1` | Keep only the current pane |

## 5. Coding, Git, and terminal

| Binding | Action |
|---|---|
| `M-.` | Jump to definition |
| `M-,` | Return from a definition jump |
| `C-c e a` | Code actions |
| `C-c e r` | Rename a symbol |
| `C-c e d` | Search current-buffer diagnostics |
| `C-c e f` | Format the buffer |
| `C-x g` | Open Magit status |
| `C-c t` | Open Ghostel terminal |
| `C-x p t` | Open a project terminal |

The code-navigation and editing features require language-server support; Nix
buffers start Eglot automatically.

## 6. Notes and AI shortcuts

| Binding | Action |
|---|---|
| `C-c n c` | Capture an inbox item, task, learning session, or journal entry |
| `C-c n a` | Open the learning agenda |
| `C-c n t` | Start the selected learning session |
| `C-c n x` | Stop the session timer |
| `C-c n f` | Find/create an Org-roam note |
| `C-c n i` | Insert a link to an Org-roam note |
| `C-c n s` | Search all notes |
| `C-c n d` | Open today's journal |
| `C-c g` | Open the project AI chat |
| `C-c a` | Attach a file to that chat |
| `C-c RET` | Send to the AI |
| `C-c r` | Rewrite selected text with AI |

**Start with sections 1–3.** File opening, buffer switching, Meow selections, and
ripgrep give the biggest immediate payoff.
