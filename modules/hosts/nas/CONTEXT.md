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
- `silverbullet` (UID/GID 1004): SilverBullet container service identity.
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
| `services/homepage` | `/srv/homepage` |
| `services/searxng` | `/srv/searxng` |
| `services/silverbullet` | `/srv/silverbullet` |
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
  Gluetun/ProtonVPN and Firefox, Docker, SilverBullet, SearXNG, and a monthly
  ZFS scrub.
- Internal-only HTTPS names (`ha`, `torrent`, `firefox`) resolve to
  `192.168.178.3`; `media` and `vpn` resolve to the public address.
- Retired: Forgejo, Joplin, Logseq, AdGuard Home, Syncthing, WSDD, and the
  torrent health dashboard. Retired note-service datasets have been removed.

## SilverBullet

Before deploying the SilverBullet aspect, create the
`storage-pool/services/silverbullet` dataset with mountpoint
`/srv/silverbullet`. The service creates `/srv/silverbullet/space` for UID/GID
1004 and refuses to start unless the dataset is mounted.

Open `https://silverbullet.sk4rd.com` and use the first-run Space Manager flow
to create the account. The authenticated service is available through the
public HTTPS endpoint. Install the PWA on each device for offline access.
SilverBullet synchronizes browser replicas with the NAS-hosted space and
creates conflict copies rather than merging simultaneous edits to one file.

The authoritative space is under `/srv/silverbullet/space`. It is not
independently backed up while automatic ZFS snapshots remain disabled.

## SearXNG

`/srv/searxng/config/settings.yml` is repository-owned: `docker-searxng`
reinstalls it before every start from the SOPS secret `nas/searxng/secret_key`,
so a host-side edit is discarded rather than merged. Change settings in
`sops.templates."searxng.settings.yml"` in `modules/features/services/searxng.nix`;
an edit there restarts the unit on switch (`restartUnits`), because a re-render
reuses the same `/run/secrets` path.

The container entrypoint only writes that file when it is missing, which it now
never is, and a `server.secret_key` left at the image's `ultrasecretkey`
placeholder is fatal — `searx/webapp.py` exits the worker — so the unit
restart-loops and Traefik answers 502 instead of naming the cause. The key comes
from SOPS; rotating it restarts the unit via `restartUnits`.

The instance serves `json` alongside `html` (`search.formats`). SearXNG answers
403 for every format that is not listed there, which is what refused API clients
asking for `/search?format=json`. Confirm with
`curl -o /dev/null -w '%{http_code}\n' 'https://search.sk4rd.com/search?q=test&format=json'`.

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
