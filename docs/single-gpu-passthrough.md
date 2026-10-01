# Desktop: on-demand Windows GPU passthrough

For the verified Windows installation procedure, laptop SPICE/remote-viewer
connection, BIOS/DMA-protection findings, OpenRGB/Plasma handoff caveats, and
remaining physical-display issue, see [Windows gaming setup notes](windows-gaming-setup-notes.md).
The repository hook automates OpenRGB and local graphical-session shutdown.
This is not a claim that this hook version is installed: after deploying, verify
that the installed executable contains both the OpenRGB lifecycle and
`--user --machine="$name@.host"` graphical-target stop before relying on it.
No separate manual OpenRGB or graphical-session stop is needed once installed.
Save all graphical work first: handoff logs out local graphical users, and
rollback/release restores the login screen, **not their applications**.

The desktop normally uses the RX 7900 XT with `amdgpu`. The `windows-gaming`
libvirt guest can borrow it while running. Starting that guest **logs out the
local Plasma session** and blanks the monitor until the guest takes over. On
shutdown, the hook waits for libvirt to return the card to `amdgpu`, then starts
the login screen. Other guests are unaffected. This is not boot-time VFIO
binding; NixOS can still use the GPU for games and compute between VM sessions.

## Before the first VM start (on the physical NixOS desktop)

1. Enable SVM and IOMMU in the firmware. Have working SSH from another device
   and confirm you can log in **before** giving the only connected display to
   the guest. Do not set the VM to autostart.
2. Find the *Linux* PCI addresses (Windows bus numbers are not authoritative):
   `nix shell nixpkgs#pciutils -c lspci -nnk` should identify RX 7900 XT
   `[1002:744c]` and its HDMI/DP audio function `[1002:ab30]`. Check both
   `/sys/bus/pci/devices/0000:<address>/iommu_group` symlinks and list each
   group's `devices/`. Any unrelated devices in the groups need investigation;
   do not turn on ACS override just to conceal unsafe isolation.
3. Generate the template on the **physical NixOS desktop** (not in WSL):

   ```bash
   cd /home/miko/nix-config
   nix shell nixpkgs#python3 -c python3 scripts/windows-gaming-template.py \
     --output /home/miko/windows-gaming.xml \
     --windows-iso /var/lib/libvirt/images/windows.iso \
     --virtio-iso /var/lib/libvirt/images/virtio-win.iso
   ```

   Download the Windows and VirtIO driver ISOs yourself and adjust their paths;
   omit either ISO option if installing its media later through virt-manager.
   The generator discovers Linux PCI addresses and refuses missing IOMMU groups
   or groups containing unrelated devices. It only writes XML, never creates a
   disk, defines a VM, or starts one. Review the XML before importing it.
4. Check available NVMe space, then create the 512 GiB **sparse** guest disk:
   `nix shell nixpkgs#qemu -c qemu-img create -f qcow2 /var/lib/libvirt/images/windows-gaming.qcow2 512G`.
   The image grows as the guest writes data; 512 GiB is its virtual capacity,
   not its initial host disk usage. Keep enough free host space for that growth.
   Only run the creation command for a new disk; do not overwrite an existing image.
   The XML references this path; change `--disk` if the location differs.
   Import with `virsh -c qemu:///system define /home/miko/windows-gaming.xml`.
   Do not enable VM autostart. The template uses the 7950X's host CPU features,
   8 cores/16 threads, 20 GiB of the system's 32 GiB RAM, VirtIO storage and
   network, Q35/UEFI, TPM 2.0, and both GPU PCI functions with `managed='yes'`.
   The intended final setup passes through all peripherals. For initial testing,
   the template passes through only the Razer Viper V3 Pro (`1532:00c1`) and DISCIPLINE keyboard
   (`6b62:6869`) as whole USB devices, matched by vendor/product ID. They belong
   to Windows while the guest runs and return to Linux when it stops. The YubiKey,
   USB speakers, microphone, and hubs are not passed through. Missing mouse or
   keyboard devices do not prevent startup (`startupPolicy='optional'`); keep
   both connected for local control, or use remote SPICE for recovery. Reconnecting
   an omitted device may require attaching it through virt-manager or restarting
   the guest. Multiple devices with the same vendor/product ID need explicit
   selection rather than this ID-only configuration.
   It keeps a loopback-only SPICE console for installation and troubleshooting.
   These are sane starting values, not CPU pinning or a performance guarantee.
5. Load the VirtIO storage driver from the VirtIO ISO during Windows setup if
   no disk is shown; then install VirtIO network and AMD GPU drivers. Set the
   physical GPU output as the primary Windows display. Keep a monitor connected
   to the RX 7900 XT for the guest and use SSH/remote virt-manager for recovery.
6. Before first handoff, verify the physical GPU is bound to `amdgpu`, its audio
   function is present, and the VM's devices match the IOMMU groups. Launch
   from SSH or another device for the first test, not from a terminal that
   disappears when Plasma logs out. Shut down Windows normally; don't suspend
   or save the guest until return-to-host has been tested.

The hook is in `modules/features/virtualisation/single-gpu-passthrough.nix`.
It operates at libvirt `prepare/begin` and `release/end`. Before managed GPU
detach, it records whether `openrgb.service` was active, stops it if active, and
verifies it is stopped. A failed stop or uncertain service state aborts handoff.
On safe preparation rollback or successful release, it restarts OpenRGB only
if it was originally active, after verifying both GPU and audio host drivers.
Initially inactive or uninstalled OpenRGB stays untouched. Before stopping SDDM,
the hook snapshots and deduplicates loginctl session owners with a nonempty seat,
`Remote=no`, class `user`/`user-early`, and type `x11`/`wayland`. Session-list or
property-query failure (including a disappearing session) aborts before stopping
services. It stops the display manager first to prevent greeter/session relaunch,
then uses `systemctl --user --machine="<name>@.host"` to stop each owner's
`graphical-session.target`. A successful explicit `ActiveState=inactive` read is
required for the display manager and every graphical target; stop/query errors,
transitions or unexpected states abort handoff. No graphical users still means
stopping SDDM, but no user-manager operations. It never terminates an SSH session
or a whole user manager, and never starts a graphical target on rollback/release.
All loginctl/systemctl clients are bounded to 30 seconds with a 5-second kill
grace. Timing out a client does not cancel its systemd job. Before each display
manager or user graphical-target stop, the hook writes an unresolved guard at
`/run/single-gpu-passthrough-display-stopped-unresolved` naming the exact unit and
manager. It removes this guard only after the synchronous stop succeeds **and**
a successful explicit query reports `ActiveState=inactive`. Stop errors/timeouts,
query errors/timeouts, transitions and unexpected states retain all markers;
rollback and even `release/end` refuse to restart SDDM/OpenRGB. A later vanished
loginctl session does not prove the job completed and cannot permit a retry.
There is no automatic job cancellation or user-manager termination.

Safe rollback remains available before any graphical stop was submitted, or
after all submitted graphical stops were proven complete. With both host drivers
bound, it restores SDDM and the prior OpenRGB state, not logged-out applications.
The original audio-driver marker remains compatible; the auxiliary
`/run/single-gpu-passthrough-display-stopped-openrgb` marker records that OpenRGB
needs restarting. Stale markers block preparation, including recovery mode;
otherwise recovery remains a no-op on all services. An unsafe GPU/audio rebind
also leaves services stopped and markers retained.
AMD reset/firmware-framebuffer behavior **cannot be validated from WSL or
Windows**: the first live test needs SSH recovery available. If startup or
shutdown fails, first confirm through SSH that `windows-gaming` is **shut off**
and the GPU and audio PCI functions are both back on their original host
drivers (`amdgpu` for the GPU; the audio driver's name is recorded in
`/run/single-gpu-passthrough-display-stopped`). Use the Linux PCI addresses
printed by the template generator to inspect both `driver` links under
`/sys/bus/pci/devices/`. **Driver bindings alone are not enough when the
`-unresolved` guard exists.** Read that guard over SSH to identify the affected
unit and manager, then use bounded successful checks in that same manager. For
example, for the display manager use:

```bash
sudo timeout --kill-after=5s 30s systemctl list-jobs --no-pager
sudo timeout --kill-after=5s 30s systemctl show --property=ActiveState --value display-manager.service
```

For a recorded user graphical target, replace `<name>` with the recorded owner:

```bash
sudo timeout --kill-after=5s 30s systemctl --user --machine="<name>@.host" list-jobs --no-pager
sudo timeout --kill-after=5s 30s systemctl --user --machine="<name>@.host" show --property=ActiveState --value graphical-session.target
```

Require **no pending stop jobs for the affected unit or its dependencies**, and
an explicit `inactive` result. A missing loginctl session, false `is-active`,
inaccessible user bus, failed/transitioning state, or timed-out check is not
proof. Keep the markers and services closed while uncertain; do not cancel
unrelated jobs, terminate the user manager, or start graphical targets. If you
cannot establish completion reliably, recover by a deliberate host reboot
rather than guessing or deleting markers. A reboot clears `/run` state; verify
the guest is shut off and both original host drivers are bound before a retry.

Only after these checks establish completion may you remove the unresolved
guard and run `sudo systemctl start display-manager.service`. If the auxiliary
OpenRGB marker exists, restart `openrgb.service` as well. Only after the required
restarts succeed, remove the auxiliary marker (if present) and then the
audio-driver handoff marker before trying the VM again. **Never blindly delete
markers to bypass a refused retry or recovery boot.** Do not restart OpenRGB
merely because an older audio-only marker exists: older hooks did not record
its prior state.
If a function remains on VFIO or unbound, inspect `journalctl -u
libvirtd` and the driver links; do **not** clear the marker or retry the VM.
A reboot is the last-resort recovery path.

## Explicit SPICE-only recovery of the existing guest

This mode lets `windows-gaming` boot without a GPU handoff. It is **the same
VM**, with the same name, UUID, disks, CPU, TPM and NVRAM; never rename, clone or
undefine it as a workaround. It does not fix AMD physical-display, detach,
reset or return-to-host problems. Live recovery still needs a separate test.

The opt-in is this exact domain metadata (other unrelated metadata is retained):

```xml
<metadata>
  <recovery:recovery xmlns:recovery="urn:nix-config:windows-gaming" mode="spice-only"/>
</metadata>
```

The hook validates libvirt's stdin XML before GPU discovery or driver checks.
Recovery is a **virtual-device-only diagnostic boot**: the guest gets no host
device and **no network at all**. It requires zero hostdevs of any kind
(including PCI and USB), zero interfaces of any type (including
`type='hostdev'` and a network interface with a hostdev `<actual>` backend), no
`qemu:commandline`/`qemu:override` or other QEMU namespace extension, only
virtual input (`keyboard`/`mouse`/`tablet` — never `evdev`/`passthrough`), only
the `emulator` TPM backend, only file-backed `disk`/`cdrom` entries (no LUN,
block, network or volume disk and no `dev=` source), no `filesystem`/`redirdev`
or host `source` path, no `gl`/`rendernode`/`acceleration`, exactly one
explicitly loopback-bound SPICE console, and an emulated video model.

The identity devices are preserved rather than replaced: the existing disks,
the TPM emulator together with its NVRAM, and the loopback SPICE console stay
as they are. Windows therefore has no networking, but the laptop's
remote-viewer/SPICE tunnel still reaches the guest, which is the point of this
diagnostic. Missing, unknown or malformed recovery intent never grants a
bypass; normal XML still requires both original managed GPU functions and is
**unaffected** by these rules — they apply only to XML carrying the recovery
opt-in. An existing handoff marker
blocks preparation even in recovery mode. Do not clear it merely to bypass the
check: resolve the interrupted handoff using the driver checks above first.
Valid recovery neither stops services nor creates a handoff marker or changes
GPU ownership; release without a marker is a no-op.

### User-operated procedure (not run by repository tooling)

1. Verify the guest is **shut off**, not paused or saved, and keep autostart off:
   `virsh -c qemu:///system domstate windows-gaming`.
   Preserve your original saved inactive XML in a durable location, not a
   temporary/scratch directory. Do not use the fresh-install template as a
   recovery source: it does not contain the existing guest UUID/NVRAM identity.
2. **Deploy the new hook before defining recovery XML.** The old hook rejects a
   hostdev-free guest. Review all pending repository edits first: the deployment
   includes them, not only this feature. Deployment is a deliberate user step:

   ```bash
   sudo nixos-rebuild switch --flake /home/miko/Documents/nix-config#desktop
   ```

   Verify `/var/lib/libvirt/hooks/qemu.d/single-gpu-passthrough` resolves to an
   executable script containing the `--mode` validation before GPU discovery,
   and that its referenced validator has the recovery namespace. Do not start
   the guest if the deployed hook is still the older version.
3. If you do not already have a trusted original backup, save the current
   **normal** inactive definition without overwriting any previous backup:

   ```bash
   (set -o noclobber; virsh -c qemu:///system dumpxml --inactive windows-gaming \
     > /home/miko/windows-gaming-original.xml)
   ```

   Stop if that command fails; check the backup is complete and contains the
   original UUID, TPM, NVRAM, disks and hostdevs. An XML backup preserves
   references, not disk/TPM/NVRAM contents; maintain your normal data backups.
4. Generate a **new** recovery file offline:

   ```bash
   cd /home/miko/Documents/nix-config
   python3 scripts/windows-gaming-recovery.py \
     --source /home/miko/windows-gaming-original.xml \
     --output /home/miko/windows-gaming-recovery.xml
   python3 modules/features/virtualisation/validate-windows-gaming.py --mode \
     < /home/miko/windows-gaming-recovery.xml
   virt-xml-validate /home/miko/windows-gaming-recovery.xml domain
   diff -u /home/miko/windows-gaming-original.xml /home/miko/windows-gaming-recovery.xml
   ```

   Validation must print `recovery`. The writer removes **all** hostdevs and
   **all** interfaces — recovery deliberately has no guest networking — adds
   the opt-in, and retains the identity devices (disks, TPM emulator, NVRAM,
   loopback SPICE console) and other settings; it refuses an unsafe or missing
   console rather than inventing one, and it **rejects** any other host-backed
   device (evdev/passthrough input, non-emulator TPM, non-file disk, host
   source, render dependency, QEMU namespace extension) instead of silently
   stripping it. XML prefix, quoting and whitespace can change. Existing output
   files (including symlinks) are never overwritten; the source stays
   unchanged. The script does not call virsh or touch any VM state. Keep the
   original backup for rollback.
5. Reconfirm `shut off`, then explicitly replace only this guest's definition:

   ```bash
   virsh -c qemu:///system define /home/miko/windows-gaming-recovery.xml
   virsh -c qemu:///system dumpxml --inactive windows-gaming
   ```

   Check the same UUID/name, no hostdevs and no interfaces before deliberately running
   `virsh -c qemu:///system start windows-gaming`. Connect through virt-manager
   or a tunneled SPICE viewer as described in the setup notes; never expose
   SPICE on `0.0.0.0`. The physical monitor and USB peripherals remain with
   Linux, so use the virtual console for Windows input/display.

### Rollback

Shut down Windows normally and confirm `virsh -c qemu:///system domstate
windows-gaming` reports **shut off**. **Only while stopped**, restore the saved
original definition:

```bash
virsh -c qemu:///system define /home/miko/windows-gaming-original.xml
virsh -c qemu:///system dumpxml --inactive windows-gaming
```

Verify the original UUID, TPM/NVRAM paths and managed GPU hostdevs are back, with
no recovery metadata. Do not undefine the guest, delete TPM/NVRAM, or regenerate
it. Restoring XML does not undo guest disk changes made during recovery. The
new hook can stay installed: without the opt-in it follows the normal handoff
path. Restoring the definition does **not** authorize another hardware handoff;
the existing AMD handoff/display failures remain unresolved.

Offline regression checks (no VM operations):

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s scripts -p 'test_*.py' -v
bash -n modules/features/virtualisation/single-gpu-passthrough.sh
```

The executable hook tests rewrite host paths in a scratch copy and mock
`systemctl`; they never run the privileged hook against real sysfs. Build the
rendered `writeShellApplication` derivation as well to exercise shellcheck.

No automatic deployment or guest creation is performed by this repository edit.
