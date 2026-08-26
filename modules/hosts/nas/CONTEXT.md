# NAS context

Background and operating notes for the NAS host. This is reference context for
agents and operators, not a runbook.

## Host and storage

- NixOS on an ext4 root SSD, systemd-boot, static address `192.168.178.3/24`,
  hostId `6985f698`.
- ZFS pool `storage-pool`: three-disk RAIDZ1. This configuration never creates
  a pool, partitions a disk, changes a pool feature, or changes an existing
  dataset property. Do not run `zpool upgrade` or automatic expansion here.
- Do not use Disko for this host.
- Never deploy without working local console access; remote `nixos-rebuild`
  as `admin` is the normal path.

## Identities

- `admin` (UID 1000): operator. SSH, `docker` + `wheel`, declarative
  passwordless sudo, Nix trusted-user. Root-equivalent by design.
- `miko` (UID 995, GID 993): system identity that owns the Samba-shared ZFS
  datasets and is the Samba account. Not a login user.
- `qbittorrent` (UID/GID 2001): container service identity.
- Do not recursively `chown` `/srv/samba/media` or `/srv/samba/torrents`;
  the numeric identities are load-bearing.
- `/etc/ssh/ssh_host_ed25519_key` decrypts the NAS SOPS secrets; never
  replace it without a recovery copy.

## Datasets

`storage-pool` datasets mount through their on-disk ZFS properties:

| Dataset | Mountpoint |
|---|---|
| `services/jellyfin` | `/srv/jellyfin` |
| `services/qbittorrent` | `/srv/qbittorrent` |
| `services/firefox` | `/srv/firefox` |
| `services/traefik` | `/var/lib/traefik` |
| `services/home-assistant` | `/srv/home-assistant` |
| `documents` | `/srv/samba/documents` |
| `media` | `/srv/samba/media` |
| `torrents` | `/srv/samba/torrents` |
| `git` | `/srv/forgejo` |
| `public` | `/srv/samba/public` |

Service units assert their dataset mountpoints before starting; a missing ZFS
mount fails startup rather than writing into the root filesystem.

## Services

- Jellyfin, Home Assistant (Container, host network), Samba (SMB3, port 445
  only), Traefik, Cloudflare DDNS, WireGuard server, qBittorrent with
  Gluetun/ProtonVPN and Firefox, Docker, SMART, and a monthly ZFS scrub.
- Internal-only HTTPS names (`ha`, `torrent`, `firefox`) resolve to
  `192.168.178.3`; `media` and `vpn` resolve to the public address.
- Retired: Forgejo, AdGuard Home, Syncthing, WSDD, and the torrent health
  dashboard. Their data remains on the pool.

## Rollback inventory

The following are retained from the 2026-08-26 migration; keep them until an
external backup exists and a retention period is chosen:

- ext4 originals under `*.ext4-pre-zfs-20260826` in `/srv` and `/var/lib`.
- `storage-pool/migration-backup-20260825`.
- Snapshots `@pre-den-migration-20260825` and `@pre-workload-cutover-20260826`.

## Snapshots

Automatic ZFS snapshots are disabled. The legacy retention was 24 hourly, 30
daily, 8 weekly, and 12 monthly; re-enable only with an explicit policy that
will not prune the retained migration snapshots.

## D-Bus

The NAS uses the repository default `dbus-broker`.

## Clean installation

If the system SSD is ever replaced: physically disconnect the three ZFS disks
first, install to the replacement, then reconnect them only after NixOS boots
with the preserved `networking.hostId`, SSH host key, and ZFS support. Import
`storage-pool` without `-f` after confirming it is not active elsewhere.
