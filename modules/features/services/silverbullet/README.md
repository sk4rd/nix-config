# SilverBullet Neon Flux

`neon-flux.md` supplies the managed Space Style page at
`/srv/silverbullet/space/spaces/notes/Neon Flux.md`. Edits made in SilverBullet
are replaced on the next theme-unit restart; edit the repository template instead.

After first-run account setup, create `notes` using Space Manager, then run on
the NAS:

```sh
sudo systemctl restart silverbullet-theme.service
journalctl -u silverbullet-theme.service
```

A missing `notes` space is logged and skipped without blocking backend startup.
Use the same restart command to restore the managed page later. Restarting only
the container does not reinstall the theme. The unit remains active after a
successful or skipped install, so use `restart`, not `start`, to run it again.

After deployment, let the new page sync, then reload the client or run
**System: Reload**. The page's `space-style` fence is indexed automatically;
there is no SETTINGS page edit or library import to perform.
