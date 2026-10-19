# Documents syncing

One Syncthing folder, `documents`, syncs `/home/miko/Documents` between desktop
and laptop, including `notes/`. Emacs uses `~/Documents/notes`. The NAS stores
the relay copy on the ZFS dataset `storage-pool/syncthing-documents`, mounted at
`/storage-pool/documents`. This is separate from the Samba Documents share at
`/mnt/nas/documents`, backed by the existing `storage-pool/documents` dataset at
`/srv/samba/documents`. WSL and standalone Home Manager do not enable this sync.

The shared device IDs live in `lib/syncthing-devices.nix`; each device excludes
itself. Folder settings live in `lib/documents-syncthing.nix`. Changes and
deletions propagate in both directions; unlimited conflict copies are retained.
Hidden files and Git working trees are included. Only Emacs temporary files and
Org-roam database files under `notes/` are excluded. Syncthing file versioning
is not enabled.

## Migration from separate notes syncing

Configuration changes do not move existing data. Before deploying:

1. Let the existing folders finish syncing and retain a recovery copy. Pause
   the legacy `org-notes` folder in each GUI. Temporarily add `paused = true;`
   to `lib/documents-syncthing.nix` for the migration rebuilds; this keeps
   Documents paused when its new configuration is applied. Close Emacs and stop
   Syncthing while moving files. On workstations stop the user units; on the NAS
   stop the system units:

   ```sh
   systemctl --user stop syncthing.service syncthing-init.service
   # On the NAS instead:
   sudo systemctl stop syncthing.service syncthing-init.service
   ```

2. On each workstation, move existing `~/notes` into `~/Documents/notes` if it
   has not already been moved. If both paths exist, merge and verify their
   contents rather than nesting or overwriting a directory. Remove the old
   notes folder's `.stfolder` marker and `.stignore` from the nested `notes/`
   directory after saving any custom ignore rules; the Documents root now owns
   those files. Do not copy Syncthing identity or database files.

3. Deploy the new configurations with Documents still declaratively paused.
   Run the matching command on each machine:

   ```sh
   sudo nixos-rebuild switch --flake .#desktop
   sudo nixos-rebuild switch --flake .#laptop
   sudo nixos-rebuild switch --flake .#nas
   ```

4. The NAS dataset unit creates and mounts `storage-pool/syncthing-documents` if absent.
   Its required properties are `compression=zstd` and `atime=off`; an existing
   dataset must already match. The root is owned by the Syncthing user with mode
   `0700`. Existing `/storage-pool/notes` data and snapshots are left intact.
   Populate `/storage-pool/documents/notes` from the migrated workstation via
   Syncthing, or copy verified contents from the old dataset while syncing is
   stopped, excluding its `.stfolder` and `.stignore` and ensuring the copied
   files are writable by the Syncthing user. If the old Documents relay at
   `/var/lib/syncthing/documents` contains unique files, merge them into the new
   dataset before resuming. Do not destroy either old copy during migration.

5. Remove the legacy `org-notes` folder through each Syncthing GUI before
   resuming it. Undeclared folders are preserved (`overrideFolders = false`),
   so merely removing its Nix declaration does not remove the running folder.
   Remove that folder configuration while keeping files, then remove the
   temporary `paused = true;` from the Documents helper and rebuild all devices.
   Confirm its path and device IDs, and check its ignore list no longer
   excludes `/notes`. Wait for all devices to report **Up to Date**, then test
   an edit in `Documents/notes` in each direction and rebuild the Org-roam index.

## Status and storage

Workstation GUI: <http://127.0.0.1:8384>. For the NAS GUI, forward its loopback
port with `ssh -N -L 8385:127.0.0.1:8384 admin@192.168.178.3` and open
<http://127.0.0.1:8385>. GUI port 8384 is not exposed by the firewall.

```sh
systemctl --user status syncthing syncthing-init # workstation
sudo systemctl status documents-dataset syncthing syncthing-init # NAS
findmnt --mountpoint /storage-pool/documents # NAS
sudo zfs get mountpoint,compression,atime storage-pool/syncthing-documents
```

The NAS services require the mounted ZFS dataset and validate its source before
starting. The daemon pins it in its private mount namespace. Device identities
and the database remain in the existing persistent Syncthing state directories;
they are not part of Documents.

## Snapshots and recovery

The NAS runs `documents-snapshot-{hourly,daily,monthly}` timers, retaining 24
hourly, 30 daily, and 12 monthly snapshots of all Documents, including notes.
Snapshots use UTC calendar boundaries and the namespace
`storage-pool/syncthing-documents@documents-v1-<period>-<UTC timestamp>`. Pruning requires
both the exact name and `org.nix-config:documents-policy=v1`. Other datasets and
old notes snapshots are not pruned. Old notes snapshot timers are retired.

```sh
systemctl list-timers 'documents-snapshot-*'
sudo systemctl start documents-snapshot-hourly.service
sudo zfs list -t snapshot -r storage-pool/syncthing-documents
```

To recover a file, copy it from a chosen snapshot to a separate recovery
directory and inspect it before copying it into the live folder. For example:

```sh
mkdir -p ~/notes-recovery
sudo cp /storage-pool/documents/.zfs/snapshot/documents-v1-hourly-20261016T190000Z/notes/roam/example.org ~/notes-recovery/example.org
sudo chown "$(id -u):$(id -g)" ~/notes-recovery/example.org
```

Copying into the live folder distributes a new change. Pause sync while
investigating unwanted deletions. Test recovery with a disposable file rather
than rolling back the whole dataset. Live synchronization and recovery still
need verification after deployment.
