# Desktop: on-demand Windows GPU passthrough

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
4. Check available NVMe space, then create the 256 GiB **sparse** guest disk:
   `nix shell nixpkgs#qemu -c qemu-img create -f qcow2 /var/lib/libvirt/images/windows-gaming.qcow2 256G`.
   The XML references this path; change `--disk` if the location differs.
   Import with `virsh -c qemu:///system define /home/miko/windows-gaming.xml`.
   Do not enable VM autostart. The template uses the 7950X's host CPU features,
   8 cores/16 threads, 20 GiB of the system's 32 GiB RAM, VirtIO storage and
   network, Q35/UEFI, TPM 2.0, and both GPU PCI functions with `managed='yes'`.
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
It operates at libvirt `prepare/begin` and `release/end`. A failed preparation
attempts to restart the display manager; a failed GPU rebind deliberately
leaves the display stopped and logs an error instead of hiding the problem.
AMD reset/firmware-framebuffer behavior **cannot be validated from WSL or
Windows**: the first live test needs SSH recovery available. If startup or
shutdown fails, first confirm through SSH that `windows-gaming` is **shut off**
and the GPU and audio PCI functions are both back on their original host
drivers (`amdgpu` for the GPU; the audio driver's name is recorded in
`/run/single-gpu-passthrough-display-stopped`). Use the Linux PCI addresses
printed by the template generator to inspect both `driver` links under
`/sys/bus/pci/devices/`. Only then run `sudo systemctl start
display-manager.service`. Once it is active, remove the stale handoff marker
with `sudo rm /run/single-gpu-passthrough-display-stopped` before trying the VM
again. If a function remains on VFIO or unbound, inspect `journalctl -u
libvirtd` and the driver links; do **not** clear the marker or retry the VM.
A reboot is the last-resort recovery path.

No automatic deployment or guest creation is performed by this repository edit.
