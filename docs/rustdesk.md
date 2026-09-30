# Remote control with RustDesk

The desktop includes RustDesk and a boot-enabled `rustdesk.service`. The laptop
includes the RustDesk application for connecting to it. Apply each machine's
updated NixOS configuration through your normal deployment workflow first.

## First connection

1. On the desktop, log into Plasma and open **RustDesk** from the application
   launcher. Check that it shows a ready connection status and note **Your ID**.
2. In RustDesk's **Settings → Security**, unlock the settings if prompted and
   set a strong permanent password for unattended access. Keep this password in
   your password manager; do not put it in the Nix configuration. Ensure keyboard
   and mouse control is enabled.
3. On the laptop, open **RustDesk**, enter the desktop's ID in the remote ID
   field, and connect using the permanent password. A temporary password or
   local approval can also be used for an attended first test.
4. Test a connection while you are still near the desktop before relying on
   remote access away from home.

This uses RustDesk's default public ID/relay infrastructure and can work across
different networks. There is no self-hosted relay in this configuration. No
inbound firewall ports are opened; use the desktop's RustDesk ID to connect.
Both machines need internet access, and the desktop must be awake.

## Plasma / Wayland

RustDesk's Wayland support is experimental. On the desktop, accept any Plasma
screen-sharing / remote-control portal prompt and select the display to share.
If offered, remember the selection. A permanent password alone does not bypass
the compositor's permission prompts.

Remote control of a Wayland login screen is not supported. For reliable
unattended access, test your existing logged-in session, including locking and
reconnecting. If it requires local approval or fails when locked, use a Plasma
X11 session if available; X11 support would need to be enabled separately if
your login screen does not offer it. The service does not automatically log you
in or prevent sleep.

The desktop's single-GPU passthrough setup gives the GPU to the Windows VM while
it is running. RustDesk on the NixOS host cannot control that Windows desktop;
install RustDesk inside the VM if you also want remote access to it.

## Troubleshooting

On the desktop:

```sh
systemctl status rustdesk.service
journalctl -u rustdesk.service -b
```

Check that RustDesk reports a ready connection, the desktop is awake, and the
screen-sharing permission has been granted. Configure passwords and connection
settings in RustDesk's UI rather than using its in-app service installer;
NixOS manages the service declaratively.
