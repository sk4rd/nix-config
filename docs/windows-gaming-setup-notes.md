# Windows gaming VM: setup and troubleshooting handoff

## Where we are

- Repository: `/home/miko/Documents/nix-config` on the physical NixOS desktop.
- Guest: `windows-gaming`, libvirt connection `qemu:///system`.
- Windows 11 is installed. The user completed updates and installed AMD graphics drivers.
- The laptop's remote SPICE console works. Preserve it as the recovery route.
- Before AMD driver installation the Radeon showed Error 43. After installation/reboot it no longer showed an error, but **physical monitors are still black**.
- Advanced display shows `Display 1: Wired Display` and `Display 2: AMD vDisplay`; the latter reports connected to `AMD Radeon RX 7900 XT`, 1920 × 1080, 60 Hz. Extend mode was selected.
- AMD vDisplay may be a fallback output, not proof that the real monitor is detected. Cable reseating and monitor power cycling did not resolve this.
- Motherboard BIOS FC3.
- The user subsequently shut Windows down. Return-to-host stalled: `0000:03:00.0` bound to `amdgpu`, but audio `0000:03:00.1` remained on `vfio-pci`; display-manager and OpenRGB were inactive; the handoff marker remained and contained `snd_hda_intel`.
- Bounded `virsh domstate` calls timed out. Libvirt's `qemu-event` thread was in D state; no separate QEMU process was observed. Privileged kernel stack inspection was blocked because sudo required a password.
- Linux identified both RX 7900 XT DisplayPort connections as connected and read 384-byte/256-byte EDIDs. DP-1 advertised 3440 × 1440 modes; DP-2 only fallback modes starting at 1024 × 768. File stat sizes for DRM EDID files were zero despite readable data: read the bytes, do not infer absence from stat size.
- Kernel logs repeatedly reported `Error queueing DMUB command: status=2` and DMCUB diagnostics. Numerous kernel workers were in D state. This demonstrates a host GPU return/display-controller problem, but does not establish the cause of the earlier Windows black screen.
- The user rebooted the host. Recovery was verified: VM shut off, GPU on amdgpu, audio on snd_hda_intel, both monitors advertising correct native modes (3440 × 1440 and 2560 × 1440), SDDM active, no marker, normal DMUB initialization.
- Next controlled test: added only `features/hyperv/vendor_id state='on' value='0123456789ab'` and `features/kvm/hidden state='on'` to the persistent inactive domain. Independent read-only review and schema validation passed. Readback verified every original setting was preserved; libvirt merely reordered KVM/SMM entries.
- Original and proposed XML are saved under `/home/miko/.hermes/cache/scratch/windows-gaming-vdisplay-test/before.xml` and `test.xml`. Scratch files are subject to cache cleanup; retain a durable backup if this rollback remains needed long-term. Repository generator is unchanged until the test is proven.
- The user stopped OpenRGB. The graphical target was stopped and the VM started successfully; both Radeon functions bound to vfio-pci, SPICE remained `spice://127.0.0.1:5900`.
- **Test did not restore usable output:** physical monitors stayed black; SPICE remained on the same Windows boot splash across repeated captures (matching image hashes). Ctrl+Alt+Delete produced no visible change. Guest CPU registers showed kernel execution, but this does not establish a working desktop. A DHCP lease was present; ICMP probes received no replies (not alone proof of a hung guest).
- A graceful ACPI shutdown request was accepted, but the guest remained running. The user explicitly authorized force-stop through the clarification UI. `virsh destroy` then timed out during return-to-host; no separate QEMU process appeared in the subsequent thread listing, but libvirt queries were unresponsive, so shut-off state could not be confirmed through libvirt.
- GPU rebind again failed in the same way: GPU on amdgpu, audio still on vfio-pci, marker retained, recurring DMUB/DMCUB errors. Do not retry starts or manual unbinds in this state. Host reboot is the recommended recovery.
- The user rebooted again after the failed visibility test. Verified recovery: guest shut off, GPU on amdgpu, audio on snd_hda_intel, no handoff marker, SDDM and OpenRGB active.
- **The vendor-ID/KVM-hidden test has now been undone.** Before restoring, structural comparison confirmed these were the only differences from the original backup; `virsh define --validate before.xml` succeeded and full inactive XML readback matched the original. The guest remains shut off; Windows disk/TPM/NVRAM were not changed by this restoration.
- Next diagnostic candidate is a virtual-graphics-only recovery boot, but the current handoff hook requires both Radeon hostdevs and will reject simply removing them. Design and review an explicit recovery path before attempting that isolation; preserve disk/TPM/NVRAM and never run two guests on the same disk concurrently.
- The explicit SPICE-only recovery path now exists in the hook and its validator: it requires zero hostdevs **and zero interfaces**, so the recovery boot has **no guest networking**; the laptop SPICE tunnel stays the console, and the hook does not stop services or touch GPU ownership. Normal passthrough validation is unchanged. See `docs/single-gpu-passthrough.md`.
- Rationale: https://forum.level1techs.com/t/the-state-of-amd-rx-7000-series-vfio-passthrough-april-2024/210242 describes AMD vDisplay caused by VM identification and this targeted workaround. Treat that as a hypothesis, not proof. The source also describes separate reset/ROM issues; its latest comments caution against experimental vendor-reset routines and discuss maintained amdgpu reset behavior. Do not apply all historical workarounds indiscriminately.

## Verified isolated recovery boot

- Recovery implementation passed 40 Python tests, Nix checks/build and independent review after closing alternative-device/QEMU-extension bypasses. This is a same-domain opt-in, not a cloned guest.
- User ran `nixos-rebuild switch`; the new libvirtd-config unit was installed but its inactive oneshot did not rerun, leaving the old hook symlink. User then ran `sudo systemctl start libvirtd-config.service`. Readback confirmed the reviewed recovery-aware executable `/nix/store/bd8a9pvp0qn047pwqb721d2arcajlshc-single-gpu-passthrough/bin/single-gpu-passthrough` was installed.
- Durable original XML: `/home/miko/.local/state/windows-gaming-recovery/original.xml`.
- Active recovery definition source: `/home/miko/.local/state/windows-gaming-recovery/recovery-isolated.xml`. The earlier `recovery.xml` is superseded and must not be used: it still includes networking.
- Defined recovery only while guest shut off after original comparison, then verified exact intended XML. It removes four hostdevs and one network interface, adds recovery metadata, preserves domain identity, disk, TPM/NVRAM and SPICE.
- **Live recovery boot succeeded to Windows lock/PIN screen**, with no visible error. Physical GPU stayed on amdgpu, audio on snd_hda_intel; SDDM and OpenRGB stayed active, no handoff marker. SPICE remains `spice://127.0.0.1:5900` on desktop, forwarded to laptop port 5901.
- User must sign in through remote-viewer; physical keyboard/mouse remain on Linux. Guest networking is intentionally absent. Do not interpret offline status as another missing driver.
- User signed in and confirmed the recovery desktop looks normal, then shut down the VM (not the host; user clarified). Clean recovery shutdown verified: libvirt promptly reported shut off; SDDM and OpenRGB stayed active; GPU/audio remained amdgpu/snd_hda_intel; no handoff marker or Radeon errors in the preceding ten-minute kernel-log check. Thus recovery boot, desktop and normal shutdown all work without physical passthrough.
- Read from guest PowerShell screenshots: Radeon PCI VEN_1002 DEV_744C saved device uses driver `32.0.31041.1004`, package date August 17, 2026. Older `31.0.14000.58004` packages remain in the driver store but are not the Radeon device's selected version. Virtual display PCI VEN_1AF4 DEV_1050 reports driver `10.0.26100.1`.
- Win32_DeviceGuard reports VirtualizationBasedSecurityStatus=0, SecurityServicesConfigured={0}, and the full output showed SecurityServicesRunning={0}. VBS is not enabled in this recovery boot. This does not establish every Hyper-V component's installation state; no security settings were changed.
- These observations confirm a usable Windows recovery desktop and newer Radeon driver selection, but do not distinguish AMD driver behavior, GPU state/reset or guest PCI/firmware initialization causes.
- Current VM configuration is persistently recovery mode until explicitly restored while shut off. Do not restore GPU passthrough automatically after this test.

## Laptop console: SSH tunnel and remote-viewer

The working connection uses a loopback-only SPICE server on the desktop. From a laptop terminal, replace `<desktop-address>` with the address used for SSH:

    ssh -N -L 5901:127.0.0.1:5900 miko@<desktop-address>

Keep that terminal open. In another laptop terminal:

    remote-viewer spice://127.0.0.1:5901

Alternatively enter `spice://127.0.0.1:5901` in the viewer's connection dialog. The user confirmed this worked. No laptop viewer installation method was established here.

If it stops working after a new guest start, check the current SPICE address on the desktop:

    virsh -c qemu:///system domdisplay windows-gaming

If the guest uses a different port, update the tunnel's destination port. Keep SPICE loopback-only; do not expose it publicly.

## Windows setup and drivers

- Template: `scripts/windows-gaming-template.py`.
- Existing guest disk path documented by the template guide: `/var/lib/libvirt/images/windows-gaming.qcow2`. **Do not recreate or overwrite the installed disk.**
- Template ISO paths: `/var/lib/libvirt/images/windows.iso` and `/var/lib/libvirt/images/virtio-win.iso`; verify actual guest media before changing them.
- Template configuration: Q35/UEFI, TPM 2.0, VirtIO storage/network, host CPU features, 8 cores/16 threads, 20 GiB RAM.
- The virtual VirtIO display is deliberately retained as primary for setup/recovery. Initial setup appeared in SPICE rather than on physical monitors.
- We booted the Windows installation ISO using libvirt key injection, then the user completed installation through remote-viewer.
- If a new installation cannot see its disk, load the storage driver matching the actual VirtIO disk/controller configuration from the driver ISO. The exact storage-driver folder was not established in these notes.
- Windows initially lacked networking. The **verified** Windows 11 x64 network-driver path on the attached VirtIO ISO is:

      NetKVM\w11\amd64\netkvm.inf

- The user initially tried `amd64\win11`, received a reboot request, then saw another driver prompt. Use the NetKVM path above for networking rather than repeating that unrelated path.
- The user subsequently completed Windows setup, updates and AMD GPU-driver installation. The remaining physical-display problem is separate from reaching the Windows desktop in SPICE.

## Startup blockers and what fixed them

### 1. Default network inactive

Error: `network 'default' is not active`.

The existing network had autostart enabled but was inactive. Starting it fixed this blocker:

    virsh -c qemu:///system net-start default

Check with `virsh -c qemu:///system net-info default` before another VM start.

### 2. Hook symlink pointed at a package directory

The installed `/var/lib/libvirt/hooks/qemu.d/single-gpu-passthrough` pointed at the directory produced by `pkgs.writeShellApplication`, not its executable. Thus the intended display handoff did not run.

Repository fix: wrap the application with `lib.getExe (...)` in `modules/features/virtualisation/single-gpu-passthrough.nix`, adding `lib` to module arguments. Evaluation verified an executable `/nix/store/.../bin/single-gpu-passthrough` path and correct installer symlink generation, with no hook on unrelated hosts. Formatting/checks and independent review passed. Recheck the installed link when debugging deployment; a repository fix alone does not prove the running system has it.

### 3. OpenRGB prevented GPU driver removal

A blocked libvirt process was in `amdgpu_pci_remove` / `i2c_del_adapter`; no QEMU guest process had started. Root `fuser` diagnostics showed OpenRGB holding `/dev/i2c-*` open.

Stopping it released the hang and SDDM returned:

    sudo systemctl stop openrgb.service

`fuser` was not on the default command path; psmisc supplied it through Nix. Do not rely on a historical store hash when obtaining it again.

The tested startup also required stopping the graphical user session:

    systemctl --user stop graphical-session.target

**Repository update, not yet an installation claim:** the hook now stops an active
`openrgb.service` before managed GPU detach and verifies it is stopped. It restores
OpenRGB only if originally active, on safe preparation rollback or successful
release after both GPU/audio host drivers are back. An unsafe return leaves it
stopped and retains the markers. Initially inactive/uninstalled OpenRGB is not
started. It also discovers local seat-based X11/Wayland login users before
stopping SDDM, then stops and verifies each user's `graphical-session.target`
through that user's systemd manager. SSH sessions and user managers are not
terminated; greeter/manager/remote sessions are excluded. Recovery mode does not
touch services. The manual stops above are diagnostic history, not prerequisites
once this updated hook is installed.

### 4. Firmware required mandatory direct mappings

Kernel error:

> Firmware has requested this device have a 1:1 IOMMU mapping, rejecting configuring the device without a 1:1 mapping.

Both GPU functions had firmware-requested mandatory direct mappings. Read-only IVRS investigation found three 4 KiB exclusion entries covering PCI devices `00:00.0` through `0f:1f.7`, including the GPU. This was not resolved by a ReBAR change.

Motherboard: Gigabyte B650 AORUS ELITE AX **revision 1.2**, confirmed from the board by the user.

- BIOS started at FB8.
- We downloaded the revision-appropriate FC3 firmware, copied `B650AORUSELITEAX12.FC3` to the inserted microSD card, and the user flashed the BIOS.
- **Updating to FC3 alone did not fix the direct mappings.**
- The user then set BIOS **`Kernel DMA Protection Indicator` = Off**.
- After that change, both GPU functions no longer had mandatory direct mappings, and the VM successfully started with the GPU assigned.
- Keep SVM and IOMMU enabled. No ACPI override or ACS override was applied.
- The DMA-protection setting has a security trade-off; it should not be described as harmless or as disabling IOMMU itself.

## Startup with the updated hook

After deploying and verifying the installed hook includes both the OpenRGB
lifecycle and user-routed graphical-target stop, **one VM start performs the
normal handoff**: no separate manual OpenRGB or graphical-session stop. A
repository edit/build alone does not update libvirt's hook; the older installed
hook still needs the diagnostic workaround above until it is replaced.

Save all local graphical work first. The hook logs out local X11/Wayland users;
safe rollback and successful release return to the login screen, **not the
previous applications**. SSH sessions and user managers are not terminated.
From SSH, after confirming the normal passthrough definition is deliberately
restored while the guest is shut off and the default network is active:

    virsh -c qemu:///system start windows-gaming

The guest currently remains in persistent recovery mode; that mode does not
perform a GPU handoff. Restoring normal passthrough is a separate authorized
step, not part of installing this hook. The updated hook's live normal handoff
remains to be verified; it does not fix the unresolved Windows physical-output
or AMD return-to-host problem.

Prefer a normal Windows Shut down action. Before restoring host GPU consumers, verify the guest is off and both GPU functions have returned to their original host drivers. GPU driver: `amdgpu`; consult the hook's recorded audio-driver state. Follow `single-gpu-passthrough.md` for handoff-marker recovery. Do not clear the marker or restart display services while the GPU remains assigned/unbound.

## Peripherals and PCI identifiers

GPU functions used in this setup:

- RX 7900 XT `1002:744c`: `0000:03:00.0`.
- GPU audio `1002:ab30`: `0000:03:00.1`.

Both are passed through as managed PCI hostdevs. Reverify addresses and IOMMU isolation after hardware/firmware changes.

The final intent is to pass through all peripherals; the current mouse/keyboard pair is only the initial test set:

- Razer Viper V3 Pro: `1532:00c1`.
- DISCIPLINE keyboard: `6b62:6869`.

We added these to the template and persistent VM XML as whole-device USB hostdevs, matched by vendor/product ID, with `startupPolicy='optional'` and no ephemeral host bus/device address. An absent peripheral therefore does not block startup. Duplicate devices with identical IDs require explicit selection. Full reconnect behavior remains to be tested.

Other observed devices, not yet passed through:

- EDIFIER M60: `2d99:a094`.
- RODE NT-USB: `19f7:0003`.
- YubiKey: `1050:0407` — **keep on the host**.

Observed peripheral controller: `0000:13:00.4`, IOMMU group 35, buses 7/8. Do not pass the entire controller blindly: that would also transfer devices needed on the host, potentially including the YubiKey. Reverify topology before expanding passthrough.

## Verification and open work

- Five template tests plus three hook-validator tests passed after mouse/keyboard additions. Independent repository review found no substantive issue with the USB change or hook executable-path fix.
- Changes were not committed during this session; other unrelated repository edits exist. Do not stage or revert them as part of VM work.
- Preserve SPICE until physical output is verified.
- Do not infer guest-agent availability; verify its configuration before relying on guest commands.
- Injected keys must follow the guest layout. The German layout required different Y/Z and punctuation scancodes when opening `ms-settings:display`.
- Still open: physical monitor output, deployment/live verification of the automated host-service handoff, complete peripheral/reconnect testing, and full return-to-Linux verification.

## References

- [Main repository handoff guide](single-gpu-passthrough.md)
- [Gigabyte revision 1.2 support](https://www.gigabyte.com/Motherboard/B650-AORUS-ELITE-AX-rev-12/support)
- [Linux AMD IVRS handling](https://raw.githubusercontent.com/torvalds/linux/v6.18/drivers/iommu/amd/init.c)
- [Linux IOMMU implementation](https://raw.githubusercontent.com/torvalds/linux/v6.18/drivers/iommu/iommu.c)
- [Microsoft DMA-protection context](https://learn.microsoft.com/en-us/windows/security/hardware-security/kernel-dma-protection-for-thunderbolt)
- [Community AMD vDisplay discussion](https://forum.level1techs.com/t/amd-vdisplay-vfio-bar-restore-when-running-games-in-fullscreen/182160)
- [Similar no-monitor report on a different platform](https://forum.qubes-os.org/t/gpu-passthrough-passthrough-works-but-no-monitor-recognized-only-vdisplay/31306)

Community reports are troubleshooting leads, not verified solutions to the remaining physical-output issue.
