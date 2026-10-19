# Emacs notes

The Emacs aspect provides Org, Org-capture, and Org-agenda from Emacs, plus
Org-roam, Org-modern, Org-appear, and Consult through Nix.

## Notes directory

The default is `~/Documents/notes`; `~` is expanded by Emacs. All note paths
derive from the Home Manager option `programs.emacs.notesDirectory`:

```nix
homeManager.programs.emacs.notesDirectory = "~/Documents/notes";
```

Rebuild and restart Emacs after changing it. Changing the option does not move
existing files. Notes sync as ordinary contents of Documents; selecting a path
outside Documents does not automatically sync that path. See
[Documents syncing](documents-sync.md) for migration, deployment, and recovery.

On startup, Emacs creates missing `inbox.org`, `tasks.org`, `journal.org`,
`roam/concepts/`, `roam/references/`, `roam/projects/`, and `archive/` without
overwriting existing files. These are ordinary writable Org files, outside the
Nix store. The roam subdirectories are optional organizational suggestions;
new knowledge notes are created directly under `roam/`.

## Capture and tasks

Use `C-c n c`, then select:

- `i`: an unprocessed entry in `inbox.org`.
- `t`: a `TODO` entry in `tasks.org`.
- `j`: a timestamped journal entry under today's date tree in `journal.org`.

Finish capture with `C-c C-c`, or cancel with `C-c C-k`.
`C-c n d` opens today's date tree in that same journal.

`C-c n a` opens the standard agenda dispatcher. The agenda reads `tasks.org`
and actionable TODO entries in `inbox.org`, including scheduled tasks and
deadlines. Ordinary inbox entries are excluded. Use standard Org commands
such as `C-c C-t` for TODO/DONE, `C-c C-s` for scheduling, and `C-c C-d` for
deadlines. Journal and knowledge notes are outside the primary agenda.
Org's archive command stores archived entries under `archive/`.

## Knowledge and navigation

| Key | Command |
| --- | --- |
| `C-c n c` | Capture inbox, task, or journal entry |
| `C-c n a` | Org-agenda |
| `C-c n f` | Find or create an Org-roam note |
| `C-c n i` | Insert an Org-roam link |
| `C-c n b` | Toggle the Org-roam backlinks buffer |
| `C-c n d` | Open today's journal |
| `C-c n s` | Consult search across all notes |
| `C-x b` | Consult buffer navigation |
| `C-x C-r` | Consult recent files |
| `M-s l` | Consult search in the current buffer |
| `M-s r` | Consult ripgrep search in a chosen directory |

Org-roam prompts for a title and creates a timestamp/slug filename with a
unique Org ID. Follow links using `C-c C-o`; backlinks show notes linking to
the current note. No categories or extra metadata are required.

Org-roam's SQLite database lives in the configured Emacs cache directory.
The Org files are authoritative. After synced notes arrive, run
`M-x org-roam-db-sync` if a node or backlink is missing; use
`C-u M-x org-roam-db-sync` to force a rebuild. The index stays local.

Org buffers use visual wrapping, indented headings, Org-modern presentation,
and Org-appear to reveal hidden emphasis markers while editing. These display
settings do not alter the Org file format.

## Syncing and backup

The `documents` Syncthing folder includes `notes/`, with the NAS copy at
`/storage-pool/documents/notes`. Ignore rules scoped to `notes/` exclude Emacs
autosaves, lock files, backups, SQLite WAL/SHM files, and `org-roam.db`;
conflicting copies are retained. Notes moved to another subdirectory may need
corresponding ignore-rule changes in `lib/documents-syncthing.nix`.

Documents-wide ZFS snapshots retain 24 hourly, 30 daily, and 12 monthly copies.
Desktop and laptop Restic configurations include `/home/miko`, including
Documents and notes, subject to their existing exclusions and `CACHEDIR.TAG`.
Verify stored notes with `restic ls latest /home/miko/Documents/notes` using
the existing backup credentials, and restore a disposable file separately.

Syncthing mirrors deletions. Snapshots and Restic repositories on the same NAS
do not protect against loss of that NAS.
