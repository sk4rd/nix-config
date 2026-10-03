# NAS media requests

Seerr provides discovery and requests; Radarr manages movies and Sonarr manages
series. Prowlarr synchronizes indexers to both managers. Each manager connects to
qBittorrent itself, imports completed downloads, and keeps the original available
for seeding. Jellyfin plays the organized libraries. This is not unfinished-torrent
streaming, and requests are made in Seerr rather than inside Jellyfin clients.
Use only sources and content you are authorized to access.

## Infrastructure

All three new applications are native services from the locked nixpkgs input.
Their HTTP listeners bind to loopback and their HTTPS routes are restricted to
LAN (`192.168.178.0/24`) and WireGuard (`10.0.0.0/24`):

| Application | HTTPS name | Local API | State mount |
|---|---|---|---|
| Seerr | `requests.sk4rd.com` | `127.0.0.1:5055` | `/srv/seerr` |
| Radarr | `radarr.sk4rd.com` | `127.0.0.1:7878` | `/srv/radarr` |
| Sonarr | `sonarr.sk4rd.com` | `127.0.0.1:8989` | `/srv/sonarr` |

Each stores configuration beneath `config/` on its state mount. Services refuse
to start without their mounts. Creation of state directories runs after mount
assertions, not through activation-time directory creation. Seerr has no media
filesystem access; Jellyfin's media mount is read-only within its service.

The existing Gluetun namespace and loopback publications remain unchanged:
qBittorrent at port 18080, Prowlarr at 9696, and FlareSolverr at 8191. qBittorrent
and Prowlarr use ProtonVPN. Seerr and the native managers use the normal host
route. Prowlarr synchronization does **not** route all subsequent manager indexer
requests through the VPN; metadata, RSS, and download-link traffic from the
managers must not be assumed VPN-isolated. All-indexer VPN routing is a separate
networking change.

## Before deployment

Deployment and dataset creation require explicit authorization; this runbook is
not authorization to perform either. Follow `docs/agent-operations.md` first.

1. Inspect the pool, existing datasets, free space, and existing directory
   permissions. Do not replace existing data or recursively change ownership.
2. Provision missing state datasets only after confirming their names are unused:

   ```sh
   sudo zfs create -o mountpoint=/srv/radarr storage-pool/services/radarr
   sudo zfs create -o mountpoint=/srv/sonarr storage-pool/services/sonarr
   sudo zfs create -o mountpoint=/srv/seerr storage-pool/services/seerr
   ```

   Verify each mount with `findmnt --mountpoint /srv/radarr` (and likewise for the
   other two). No media dataset properties or existing pool features need change.
3. Add LAN/WireGuard DNS records for the three HTTPS names pointing to
   `192.168.178.3`. The configuration does not publish them through DDNS.
4. Review the scoped configuration diff and validation before an authorized switch.

The directory preparation unit creates missing `.downloads`, `.downloads/radarr`,
`.downloads/sonarr`, `Movies`, and `Shows` beneath `/srv/samba/media`, owned by
`miko:qbittorrent` with mode `2770`. It rejects symlinks and leaves existing
ownership and modes unchanged. Radarr/Sonarr join both shared groups. Existing
library directories must permit these services to import files; correct any
specific incompatible directory only after inspecting it. New subdirectories
should inherit a shared group through setgid and files should be group-writable.
Do not solve permission issues with a recursive `chown` or `chmod` of the dataset.

## First-run application integration

Infrastructure is repository-owned; application connections and quality/request
preferences are configured in the authenticated UIs and persist in application
state. API keys, indexer credentials, and passwords must not be committed or
copied into world-readable Nix settings.

### Radarr and Sonarr

1. Open their HTTPS endpoints from LAN/WireGuard and enable forms authentication
   with strong, distinct administrator credentials. Keep authentication required,
   including for local access; clients use API keys or downloader credentials.
2. Select final root folders:
   - Radarr: `/srv/samba/media/Movies`
   - Sonarr: `/srv/samba/media/Shows`
3. Choose quality profiles and monitoring preferences. Disable media-file chmod
   overrides that remove shared-group access; use group-writable files and
   setgid/group-writable directories. Enable **Use Hardlinks instead of Copy**
   and **Completed Download Handling**.
4. Add qBittorrent to each manager:
   - Host `127.0.0.1`, port `18080`, SSL off for this loopback connection.
   - Username `admin`; password is the existing NAS qBittorrent WebUI credential.
   - Category `radarr` or `sonarr`, respectively.
5. Add a remote-path mapping to each manager:
   - Host: exactly `127.0.0.1`, matching the download-client host.
   - Remote path: `/media/`
   - Local path: `/srv/samba/media/`
6. Test the download-client connection. Keep existing torrents and categories
   unchanged; do not bulk import or reclassify them.

The bootstrap creates the new categories with destinations
`/media/.downloads/radarr` and `/media/.downloads/sonarr`. The existing bootstrap
continues to enforce `Movies` → `/media/Movies` and `Shows` → `/media/Shows`; these
repository-owned destinations are unchanged by this integration. Custom UI edits
to those category destinations are overwritten on bootstrap, as before. The global incomplete directory
remains `/downloads/incomplete/` on the torrents dataset to avoid changing manual
workflows. Completion may copy data across datasets, but completed automation
files and final libraries share the media dataset and can be hardlinked.

### Prowlarr

In **Settings → Apps**, add Radarr and Sonarr with their respective API keys.

- Prowlarr server URL: `http://127.0.0.1:9696`.
- Radarr server URL: `http://127.0.0.1:17878`.
- Sonarr server URL: `http://127.0.0.1:18989`.
- Select the indexers/tags and synchronization level deliberately; full sync makes
  Prowlarr authoritative for the synchronized indexer settings.

Prowlarr runs inside Gluetun, so its own loopback is **not** the host loopback.
Two minimal Nix-built socat containers listen on ports 17878/18989 exclusively on
loopback inside that namespace. They connect through protected Unix sockets under
`/run/media-indexer-relay` to socket-activated host relays, which forward to the
native manager APIs. No relay TCP ports are published on the host. Relay containers
run as UID/GID 1003 without capabilities or writable root filesystems, and their
Unix sockets are accessible only to the Prowlarr identity. The normal manager
ports 7878/8989 are used by Seerr and the host, not by Prowlarr.

### Seerr and Jellyfin

1. Complete Seerr setup with Jellyfin at `http://127.0.0.1:8096`; use
   `https://media.sk4rd.com` as the externally accessible Jellyfin URL where offered.
2. Select and synchronize the movie/series libraries. Their Jellyfin folders must
   be `/srv/samba/media/Movies` and `/srv/samba/media/Shows`, not the media parent
   directory: `.downloads` must not be part of a library.
3. Add Radarr at port 7878 and Sonarr at port 8989, host `127.0.0.1`, with SSL off
   on loopback, their API keys, root folders, and chosen profiles. Mark them as the
   default servers and test both connections.
4. Allow requests only for the intended accounts. Enable automatic approval only
   for trusted users; configure quotas/approval for others. Disable unneeded signup
   paths and enable reverse-proxy support if required by the application settings.
5. Verify Jellyfin library scanning; optionally configure manager notifications
   using a dedicated Jellyfin API key for faster refresh after import.

## End-to-end verification after deployment

- Confirm listeners with `ss -ltn`: 5055, 7878, and 8989 must bind only to
  `127.0.0.1`. Public requests to the new HTTPS names must be denied; LAN/WireGuard
  requests must reach authenticated application pages.
- Check the new units and mount guards. Inspect generated directory modes and
  verify each manager can read the download files and write its library.
- Request authorized sample content and verify category, download, completion,
  import, Jellyfin scan, and playback. Use `stat -c '%d %i %h %n'` on the completed
  download and imported file: matching device/inode and a link count of at least
  two confirm a hardlink. Confirm seeding still works.
- Verify existing manual categories and unfinished downloads remain unchanged.
- In a controlled maintenance window, verify downloader connectivity is blocked
  during VPN failure. This must not be inferred from successful normal downloads.

Automatic snapshots remain disabled in this repository; these application state
mounts need an explicit backup policy. No runtime tests are implied by a successful
Nix evaluation.
