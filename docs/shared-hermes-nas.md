# Shared Hermes backend on the NAS

The NAS runs one Hermes backend and stores its configuration, sessions, skills,
authentication state, and workspace on a dedicated ZFS dataset mounted at
`/srv/hermes`. Desktop and laptop connect to that backend; terminal tools
execute on the NAS in `/srv/hermes/workspace`.

Hermes runs its authenticated dashboard and backend on TCP 9119. The process
binds to `0.0.0.0` so Hermes Desktop's remote-gateway WebSocket checks accept
remote clients; the NAS firewall does not open port 9119, and the proxy connects
to it through loopback only. Traefik serves the dashboard over HTTPS and allows
only the home LAN and existing WireGuard subnet. Do not create a public route or
open port 9119. Hermes' Basic Auth environment file is rendered from the
encrypted `secrets/hermes.yaml` by SOPS; it is not stored on the data dataset or
checked in as plaintext.

## First-time setup (after the NAS rebuild)

1. Create the dedicated dataset on the NAS, with mountpoint `/srv/hermes`:
   `sudo zfs create -o mountpoint=/srv/hermes storage-pool/services/hermes`.
   This is a new dataset; do not use it to replace or modify an existing one.
2. Basic Auth credentials are held in `secrets/hermes.yaml` and rendered into a
   root-readable, mode-`0400` systemd environment file by SOPS after the NixOS
   rebuild. Do not create `/srv/hermes/home/.env`. To retrieve the client login
   locally, decrypt only the needed fields (requires an authorized SOPS key):
   `nix run nixpkgs#sops -- --decrypt --extract '["hermes"]["basic_auth"]["username"]' secrets/hermes.yaml`
   and replace `username` with `password` for the password value. Avoid sharing
   the decrypted output.
3. Authenticate the NAS Hermes instance to your subscriptions in an interactive
   NAS shell:
   - `sudo -u hermes -H hermes auth add openai-codex` — sign in with your
     ChatGPT account/subscription.
   - `sudo -u hermes -H hermes auth add nous` — complete Nous Portal sign-in.
   Then run `sudo -u hermes -H hermes model` to select either OpenAI Codex or
   Nous as the active model provider. Don't add API keys, local-model endpoints,
   or other providers.
4. Start the service with `sudo systemctl start hermes-dashboard` and check
   `sudo systemctl status hermes-dashboard`.
5. Open `https://hermes.sk4rd.com` in a browser and sign in with the dashboard
   username/password from step 2. The dashboard can manage configuration,
   credentials, sessions, and run chats/tools on the NAS.
6. In Hermes Desktop, open **Settings → Gateways → Remote gateway**, add
   `https://hermes.sk4rd.com`, and sign in with the same dashboard credentials.
   The Nix host entries resolve that name to the NAS LAN address on desktop and
   to `10.0.0.1` on the laptop. Connect WireGuard before using the laptop backend.

The NixOS configuration creates the service account, SOPS-rendered Basic Auth
environment file, service directories, Traefik's trusted-network HTTPS route, and
host-name mappings. It does not create the ZFS dataset, activate a rebuild, or
sign in to the provider accounts; those remain deliberate user-controlled steps.

## One-click interactive workspace terminal

After applying the NAS and workstation configurations, launch **NAS Hermes
Terminal** from Plasma's application launcher on desktop or laptop. The same
launcher is available as `nas-hermes-terminal` inside Hermes Desktop's local
Terminal pane. It connects using the existing admin SSH identity, then uses
admin's existing sudo access to open an unprivileged shell as `hermes`.

The shell starts in `/srv/hermes/workspace/nix-config` when that checkout exists,
otherwise `/srv/hermes/workspace`. Git, SSH, Nix, and Bash are available without
per-command `nix run` or `sudo -u` prefixes. Git uses Hermes's home and GitHub SSH
identity. Nothing is pulled or downloaded automatically; type `git status` or
`git pull --ff-only` yourself, and use `exit` to close the session.

The default SSH endpoint is `192.168.178.3`. If the laptop's WireGuard route only
reaches the NAS VPN address, run `nas-hermes-terminal 10.0.0.1` instead. The
`NAS_HERMES_HOST` environment variable can also select a different host. Host-key
verification remains strict; verify and enroll the NAS host key for the chosen
address before first use. Existing laptop/desktop SSH credentials must be
available; the launcher does not copy keys or forward the SSH agent to NAS.

This is an interactive human-operated shell, separate from the model terminal
runner and its systemd sandbox. It has Hermes's account permissions, not admin
or root privileges. It does not grant sudo to Hermes; NAS deployment remains a
separate admin operation. Files explicitly created with restrictive permissions
can still require ACL/mode adjustments before shared SFTP editing.

The NAS `hermes-workspace-shell` helper must be deployed before the workstation
shortcut works. Merely building the helpers or adding the desktop entry does
not activate either machine's configuration.
