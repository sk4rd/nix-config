# SilverBullet Neon Flux

`neon-flux.md` is a Space Style page for the NAS's existing `notes` space.
The SilverBullet aspect substitutes the canonical tokens from
`../../desktop/neon-flux-theme/palette.json` and installs the rendered page at
`/srv/silverbullet/space/spaces/notes/Neon Flux.md` before each container start.

The page is repository-owned: edits made in SilverBullet are replaced on the
next service restart. No other pages or space settings are changed. The copy
runs as the `silverbullet` user, not root, because the space tree is writable by
the service. The existing space must already exist; the installer does not
create a Space Manager registration.

The style uses SilverBullet 2.10.0's CSS variables. It renders Neon Flux under
light, dark, and automatic client preferences, without changing the user's
stored preference. Fonts use locally installed JetBrains Mono when available,
otherwise SilverBullet's bundled iA-Mono.

After deployment, let the new page sync, then reload the client or run
**System: Reload**. The page's `space-style` fence is indexed automatically;
there is no SETTINGS page edit or library import to perform.
