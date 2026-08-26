# NAS migration

Historical record of the in-place Den migration completed on 2026-08-26.

## Strategy

Migrate the running installation in place. The system SSD is healthy, NixOS
generations provide system rollback, and reinstalling would add avoidable risk to the
three ZFS data disks. This configuration never partitions a disk, creates a
pool, creates a dataset, changes a pool feature, or changes an existing dataset
property.

Do not use Disko for this host. Do not run `zpool upgrade` during migration.
Never deploy remotely without working local console access.

The first activation intentionally keeps these paths on the ext4 system disk:

- `/srv/jellyfin`
- `/srv/qbittorrent`
- `/srv/firefox`
- `/var/lib/traefik`

The existing datasets remain mounted through their on-disk ZFS properties:

- `storage-pool/documents` at `/srv/samba/documents`
- `storage-pool/git` at `/srv/forgejo`
- `storage-pool/media` at `/srv/samba/media`
- `storage-pool/public` at `/srv/samba/public`
- `storage-pool/torrents` at `/srv/samba/torrents`

## Historical activation procedure

1. Keep copies of `/etc/ssh/ssh_host_ed25519_key` and
   `/etc/ssh/ssh_host_ed25519_key.pub`. The private key decrypts NAS SOPS
   secrets.
2. Record `zpool status -P storage-pool` and verify the pool is healthy.
3. Back up the ext4 service state listed above to another machine or removable
   disk.
4. Stop Jellyfin, Traefik, qBittorrent, Gluetun, Firefox, and their bootstrap
   units. Confirm they remain stopped before testing the foundation generation.
5. Build the NAS closure locally without deploying it.
6. Compare the fingerprint of the evaluated admin authorized key with the
   currently accepted key before replacing the SSH unit. Do not proceed if they
   differ. Both were verified as
   `SHA256:9DQg3tVofZQqO/pEcf1+H9niHx0CYJafEs7xhT9nN9Q` on 2026-08-25.
7. The first foundation generation suppressed all workload units before its
   closure was copied to the NAS and tested.
8. Verify SSH in a second session before closing the first session.
9. Verify the pool and every dataset mount before testing Jellyfin or the
   torrent stack.
10. Use `nixos-rebuild boot` only after the temporary foundation generation is
   verified.

Do not use `switch` for the first activation. A reboot into the previous
generation must remain available from the systemd-boot menu. Generation
rollback does not roll back application databases, configuration, container
state, ACLs, or ZFS properties.

After offline, restorable service-state backups were taken, the workload-enabled
generation was tested. The first workload start migrated application state,
particularly the Jellyfin database, so application rollback still requires the
corresponding backup or snapshot.

The NAS host pins the current `dbus` implementation. Moving to `broker` is a
separate post-migration reboot change and must not be forced through the
live-switch inhibitor.

The NAS admin has declarative passwordless sudo for remote rebuilds. This is
equivalent to the pre-migration manual sudoers rule; membership in the Docker
group already grants root-equivalent access.

Before enabling the torrent workload, verify that the encrypted
`nas/qbittorrent/webui_password` logs in to the restored qBittorrent `admin`
account. The pre-start configuration synchronizes qBittorrent's PBKDF2 hash
with that secret. The password must remain URL-form-safe because the API helpers
use form data without separate URL encoding; this constraint is validated before
qBittorrent starts.

The initial workload set omitted Samba, Forgejo, Home Assistant, AdGuard Home,
Syncthing, WSDD, and their Traefik routes. Samba, WSDD, and Home Assistant were
subsequently redesigned as Den aspects. The other omitted services remain
retired, but their ZFS data was not deleted.

## Service datasets

Create service datasets only after the new generation works with the existing
ext4 paths. Dataset creation and state copying are a separate maintenance
window and are not automated by Nix.

The service datasets were created and populated while workloads were stopped on
2026-08-26:

```text
storage-pool/services
storage-pool/services/jellyfin     -> /srv/jellyfin
storage-pool/services/qbittorrent  -> /srv/qbittorrent
storage-pool/services/firefox      -> /srv/firefox
storage-pool/services/traefik      -> /var/lib/traefik
storage-pool/services/home-assistant -> /srv/home-assistant
```

Use temporary mountpoints while copying. Stop each service, copy with ownership,
ACLs, xattrs, hard links, and sparse-file support preserved, verify the copy,
rename the old ext4 directory, and only then change the dataset mountpoint to
the final path. Keep the renamed ext4 directories until the services and a
reboot have been verified.

The cutovers followed that procedure. Exact `rsync --dry-run --delete`
comparisons passed, and every copied dataset has a
`@pre-workload-cutover-20260826` snapshot. The retained ext4 directories use
the suffix `.ext4-pre-zfs-20260826`.

The workload-enabled generation booted successfully on 2026-08-26. All service
datasets mounted automatically, mount assertions passed, and Jellyfin, Traefik,
DDNS, Gluetun, qBittorrent, Firefox, and both qBittorrent setup units started
without failures.

Do not recursively change ownership on `/srv/samba/media` or
`/srv/samba/torrents`. Existing numeric identities are intentionally preserved:

```text
miko        uid 995, gid 993
qbittorrent uid 2001, gid 2001
```

The qBittorrent download data already lives in
`storage-pool/torrents`; only its small configuration and Gluetun state need to
move.

Automatic ZFS snapshots are disabled during migration because a finite
retention policy can delete existing snapshots. Review the existing snapshot
history and retention requirements before re-enabling `autoSnapshot`.
The legacy policy retained 24 hourly, 30 daily, 8 weekly, and 12 monthly
snapshots; those values are historical input, not an automatically approved
future retention policy.

## Clean installation

A clean installation is not part of this migration. If the system SSD is later
replaced, physically disconnect all three ZFS disks before partitioning or
installing to the replacement SSD. Reconnect them only after NixOS boots with
the preserved `networking.hostId`, SSH host key, and ZFS support. Import
`storage-pool` without `-f` after confirming it is not active on another host.
