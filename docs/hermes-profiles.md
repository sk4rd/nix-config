# Hermes profile syncing

The `syncthing` aspect syncs `~/.hermes/profiles` between miko's desktop and
laptop using the `hermes-profiles` folder. The NAS stores a copy at
`/var/lib/syncthing/hermes-profiles`, allowing either workstation to sync while
the other is offline. This is separate from the NAS Hermes service's profiles;
the NAS only stores and relays this content.

After rebuilding all three machines, their existing Syncthing services manage
the folder automatically. The NAS service already has write access to its data
directory.

The folder uses an allowlist:

- All Markdown (`*.md`) files anywhere within profiles, including `SOUL.md`,
  `AGENTS.md`, and shared reference documents.
- All contents of directories named `skills`, including scripts and assets.

Other files, such as profile configuration, credentials, and session databases,
stay local unless placed inside a skills directory. Markdown memories and
session exports are included if present. Creating a profile on the other machine
may still require local setup; this shares profile content rather than a complete
Hermes installation.

Syncthing retains conflicting copies for manual resolution. Check folder status
at <http://127.0.0.1:8384> or service status with
`systemctl --user status syncthing syncthing-init`.
