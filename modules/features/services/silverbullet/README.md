# SilverBullet Neon Flux

`neon-flux.md` is a Space Style page for the NAS's existing `notes` space.
The SilverBullet aspect substitutes the canonical tokens from
`../../desktop/neon-flux-theme/palette.json` and installs the rendered page at
`/srv/silverbullet/space/spaces/notes/Neon Flux.md` through the independent
`silverbullet-theme.service` oneshot, not the container's startup path.

The page is repository-owned: edits made in SilverBullet are replaced on the
next theme-unit restart. No other pages or space settings are changed. The copy
runs as the `silverbullet` user, not root, because the space tree is writable by
the service. The existing space must already exist; the installer does not
create a Space Manager registration. A missing `notes` space is logged and
skipped without blocking backend startup. Installation errors fail only the
theme unit, not the container.

The mount-guarded theme unit runs at boot and is refreshed when its rendered
theme/script changes on a configuration switch. After first-run account setup,
create `notes` using Space Manager, then run on the NAS:

```sh
sudo systemctl restart silverbullet-theme.service
journalctl -u silverbullet-theme.service
```

Use the same restart command to restore the managed page later. Restarting only
the container does not reinstall the theme. The unit remains active after a
successful or skipped install, so use `restart`, not `start`, to run it again.

The style uses SilverBullet 2.10.0's CSS variables. It renders Neon Flux under
light, dark, and automatic client preferences, without changing the user's
stored preference. Fonts use locally installed JetBrains Mono when available,
otherwise SilverBullet's bundled iA-Mono.

After deployment, let the new page sync, then reload the client or run
**System: Reload**. The page's `space-style` fence is indexed automatically;
there is no SETTINGS page edit or library import to perform.
