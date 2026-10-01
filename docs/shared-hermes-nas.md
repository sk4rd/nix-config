# Shared Hermes backend on the NAS

The NAS runs one Hermes backend and stores its configuration, sessions, skills,
authentication state, and workspace on a dedicated ZFS dataset mounted at
`/srv/hermes`. Desktop and laptop connect to that backend; terminal tools
execute on the NAS in `/srv/hermes/workspace`.

The backend listens on loopback TCP 9119, behind Traefik's HTTPS route. Hermes is
configured with that HTTPS public URL so its auth gate remains enabled despite
its loopback bind. The route allows only the home LAN and existing WireGuard
subnet; the Hermes port itself is not opened to the LAN or internet. Do not
create a public route for Hermes. Its Basic Auth environment file is rendered
from the encrypted `secrets/hermes.yaml` by SOPS; it is not stored on the data
dataset or checked in as plaintext.

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
4. Start the service with `sudo systemctl start hermes-serve` and check
   `sudo systemctl status hermes-serve`.
5. On desktop, open **Settings → Gateways → Remote gateway** and add
   `https://hermes.sk4rd.com`. The Nix host entries resolve that name to the NAS
   LAN address on desktop and to `10.0.0.1` on the laptop. Connect WireGuard
   before using the laptop backend. On each device, sign in with the backend
   credentials from step 2, then save/reconnect.

The NixOS configuration creates the service account, SOPS-rendered Basic Auth
environment file, service directories, Traefik's trusted-network HTTPS route, and
host-name mappings. It does not create the ZFS dataset, activate a rebuild, or
sign in to the provider accounts; those remain deliberate user-controlled steps.
