# Emacs notes

The existing Emacs aspect provides Org, Org-capture, and Org-agenda from Emacs,
plus Org-roam, Org-modern, Org-appear, and Consult through Nix.

## Notes directory

Set the Home Manager option `programs.emacs.notesDirectory` in your user aspect:

```nix
homeManager.programs.emacs.notesDirectory = "~/notes";
```

The default is `~/notes`; `~` is expanded by Emacs. Rebuild your configuration
and restart Emacs after changing it. All note paths derive from this option.
Changing it selects a new directory; it does not move existing notes.

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
The Org files are authoritative; rebuild the index with `M-x org-roam-db-sync`
(use a prefix argument to force a rebuild). Notes can be backed up or opened
independently of this index.

Org buffers use visual wrapping, indented headings, Org-modern presentation,
and Org-appear to reveal hidden emphasis markers while editing. These display
settings do not alter the Org file format.

## Syncthing deployment and pairing

Syncthing is enabled for `miko` on `desktop` and `laptop` through `miko`'s
user aspect, and as the module-provided dedicated `syncthing` identity on
`nas`. WSL and standalone Home Manager are excluded. The folder ID is
`org-notes`, with send-and-receive synchronization and unlimited conflict copies.
Workstations expand `~/` against their Home Manager home directory; absolute
paths are passed through. Other relative paths are rejected. Changing
`programs.emacs.notesDirectory` selects a different Syncthing folder path too;
it does not migrate data. Pause the folder on all devices before changing its
path by temporarily setting `folders.org-notes.paused = true` in the shared
settings helper and rebuilding all participants. Copy and verify notes yourself,
then remove that declarative pause and rebuild to resume. A GUI pause alone does
not survive reapplication of the declared folder configuration.

The NAS dataset unit creates `storage-pool/notes` only if absent, with
`compression=zstd`, `atime=off`, the default recordsize, and no quota. Existing
datasets must already have the expected mountpoint, compression, and atime;
otherwise startup fails for operator investigation, without changing properties.
The mounted dataset root is owned by `syncthing` with mode `0700`; ownership
is not changed recursively. Both `syncthing.service` and `syncthing-init.service`
assert the mountpoint and verify the ZFS source. The daemon pins that mount in
its private mount namespace so an unmount cannot redirect writes to the root
filesystem. SilverBullet's `/srv/silverbullet/space` is separate.

Before deploying, review `docs/agent-operations.md`, inspect current NAS datasets,
snapshot policies, and the generated host diff. Deployment requires explicit
authorization and console access. To stage rollout, temporarily disable the
three `org-notes-snapshot-{hourly,daily,monthly}` timers in the NAS configuration
until pairing and disposable-note tests are complete, then remove that override.

1. Deploy the NAS configuration first. Check:

   ```bash
   sudo systemctl status org-notes-dataset syncthing syncthing-init
   sudo zfs get mountpoint,compression,atime,recordsize,quota storage-pool/notes
   findmnt --mountpoint /storage-pool/notes
   sudo stat -c '%U:%G %a' /storage-pool/notes
   systemctl cat syncthing.service syncthing-init.service
   ```

2. Open the NAS GUI through an SSH tunnel:

   ```bash
   ssh -N -L 8385:127.0.0.1:8384 admin@192.168.178.3
   ```

   Browse `http://127.0.0.1:8385`. Workstation GUIs use
   `http://127.0.0.1:8384`. Set GUI authentication locally. Only transfer ports
   TCP/UDP 22000 and discovery UDP 21027 are opened; GUI port 8384 is not opened.

3. Deploy desktop and log in as `miko`. Check
   `systemctl --user status syncthing syncthing-init`. The user service starts
   with the user manager, normally at login; no lingering is enabled. Use each
   GUI's **Actions → Show ID** to obtain its independently generated device ID.
   Take and verify an independent recovery copy of existing notes before adding
   peers. Set `folders.org-notes.paused = true` in the shared helper and rebuild
   both devices before proceeding; keep this declarative pause while collecting
   IDs. Do not rely on a GUI pause surviving a rebuild.

4. Populate the shared `peers` map in `lib/org-notes-syncthing.nix`, using real
   public IDs, for example:

   ```nix
   peers = {
     nas = {
       id = "<NAS device ID>";
       addresses = [ "tcp://192.168.178.3:22000" "dynamic" ];
     };
     desktop.id = "<desktop device ID>";
   };
   ```

   Rebuild both hosts. Each device excludes itself and shares `org-notes` with
   the declared peers. IDs are not credentials; never commit `key.pem`, API
   keys, passwords, or generated state. The map contains this installation's
   public IDs; update an entry if its identity is replaced. Confirm IDs on both
   ends and confirm the folder ID/path before resuming. Since the folder is
   already declared on each end, accepting an offer must reuse `org-notes`, not create
   a second folder. Automatic folder acceptance and introducers are not enabled.

5. With the verified recovery copy already available, remove the declarative
   pause and rebuild NAS and desktop. Wait for both to become **Up to Date**, then
   use a disposable Org note to test edits in each direction. Never use
   **Override Changes** or **Revert Local Changes** during pairing. Syncthing is a merge of existing
   folder contents, not a guarantee against remote deletions after pairing.

6. Initialize laptop and make a verified recovery copy of its existing notes.
   Declaratively pause the folder on all participants, collect its unique ID,
   add `laptop.id` to the same map, and rebuild all three. Confirm paths and IDs,
   remove the declarative pause, rebuild, and verify NAS-to-laptop and
   laptop-to-desktop changes.
   Disconnect a workstation, edit the disposable note, reconnect, and verify
   convergence. Test simultaneous offline edits and retain the generated
   `sync-conflict` copy for manual comparison.

The modules merge declared devices/folders without deleting undeclared ones
(`overrideDevices` and `overrideFolders` are false). However, declared folder
settings, including its peer list and ignore patterns, are replaced on startup;
omitted folder settings reset to Syncthing defaults, including `paused=false`.
Record a new peer in Nix before sharing it in the GUI; GUI-only sharing of
`org-notes` is not persistent across rebuilds. To remove a device, pause it,
remove its map entry, rebuild the remaining hosts, and remove the stale device
in their GUIs. Removal disconnects it and does not delete any device's note files.

NAS identities and database use the NixOS module's persistent state directory,
`/var/lib/syncthing/.config/syncthing`. Home Manager uses
`${XDG_STATE_HOME:-$HOME/.local/state}/syncthing`, retaining an older
`~/.config/syncthing` installation when its config exists. Preserve these writable
directories across rebuilds/reinstallations; do not copy one identity to another
device. They are outside the synchronized notes folder.

## Ignore patterns and local indexing

Patterns exclude Emacs `#note.org#` autosaves, `.#note.org` locks, `note.org~`
backups, SQLite `*.db-wal`/`*.db-shm` (also `.sqlite` and `.sqlite3` variants),
and an accidentally placed `org-roam.db`. The first pattern explicitly preserves
`*sync-conflict-*`. Ordinary `.org` files, `roam/` files, attachments, and hidden
files such as `.project` are included. Ignore files are machine-local and
declaratively reapplied; there is no broad hidden-file exclusion or automatic
deletion of ignored files.

The Org-roam database remains in the Emacs cache directory on each workstation.
Existing autosync is unchanged. After notes arrive, test `C-c n f` and `C-c n b`
using disposable ID-bearing roam notes with a link between them. External file
arrival must not be assumed to trigger all Emacs save hooks: run
`M-x org-roam-db-sync` if a node or backlink is missing, or `C-u M-x
org-roam-db-sync` to force an index rebuild. This operates on local authoritative
Org files, never a shared SQLite database. Live arrival/search/backlink behavior
must be verified on both workstations.

## Notes snapshots and recovery

Global `services.zfs.autoSnapshot` stays disabled. Notes-only systemd timers
retain the newest 24 hourly, 30 daily, and 12 monthly snapshots. They run at UTC
calendar boundaries, with one catch-up snapshot after downtime rather than
fabricated snapshots for missed periods. Names are
`storage-pool/notes@org-notes-v1-<period>-<UTC timestamp>`.

Creation and pruning are serialized. Re-running a policy within the same UTC
period reuses that period's snapshot. Pruning requires both an exact dataset/name
match and the snapshot user property `org.nix-config:notes-policy=v1`; other
datasets, descendants, unmanaged names, and migration history are excluded.
Standard ZFS tooling is wrapped by a small dedicated script because the pinned
Sanoid module does not provide a policy-specific naming/ownership namespace.
Do not manually reuse this namespace and marker for unmanaged snapshots.

After pairing tests, enable the timers and check:

```bash
systemctl list-timers 'org-notes-snapshot-*'
sudo systemctl start org-notes-snapshot-hourly.service
sudo zfs list -t snapshot -r storage-pool/notes
sudo zfs get org.nix-config:notes-policy storage-pool/notes@<snapshot-name>
```

To recover one file, choose a snapshot and copy to a separate recovery directory
first (replace the example snapshot name and relative file path):

```bash
mkdir -p ~/notes-recovery
sudo cp /storage-pool/notes/.zfs/snapshot/org-notes-v1-hourly-20261011T190000Z/roam/example.org ~/notes-recovery/example.org
sudo chown "$(id -u):$(id -g)" ~/notes-recovery/example.org
```

Inspect the recovered file before copying it into the live folder; that copy is
a new change Syncthing will distribute. Pause synchronization while investigating
an unwanted deletion or conflict. Do not roll back the whole dataset to restore
one file. Validate restoration with a disposable note before relying on it.

## Backup coverage and limitations

Desktop and laptop Restic configurations include `/home/miko`; their exclusions
do not exclude `/home/miko/notes`. `--exclude-caches` still excludes directories
with a valid `CACHEDIR.TAG`. Moving notes outside the home directory (or into an
excluded cache/build directory) requires a separate backup coverage review.
Repositories and schedules are unchanged. Verify actual stored notes with the
existing backup credentials and `restic ls latest /home/miko/notes`, then restore
a disposable file to a separate directory. Configuration inclusion alone is not
proof of a successful backup.

Syncthing mirrors deletions; snapshots and any separately enabled Syncthing
versioning are local recovery mechanisms. The Restic repositories and notes
snapshots live on the same NAS, so NAS loss can destroy both. Independent/off-site
storage remains a separate task.

During rollout, verify unmounted-service refusal and identity persistence across
rebuilds as well as the synchronization, indexing, recovery, and backup checks
above. Repository checks and host builds do not establish live behavior.
