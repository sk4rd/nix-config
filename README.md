# Nix configuration

This is a feature-oriented [Den](https://den.denful.dev/) configuration for
multiple NixOS hosts and users. Every Nix file under `modules/` is a
flake-parts module discovered by `import-tree`.

## Inventory

- NixOS host: `desktop` (AMD CPU, Radeon RX 7900 XT, Plasma 6)
- NixOS host: `laptop` (ThinkPad Z13 Gen 1, Plasma 6)
- NixOS host: `vm` (network hostname `nixos`)
- NixOS host: `wsl` (NixOS-WSL with direct YubiKey attachment)
- User and standalone Home Manager configuration: `miko`

Hosts and their users are declared in `modules/inventory.nix`. Each host owns
its configuration and hardware under `modules/hosts/<host>/`, while each user
owns their configuration under `modules/users/<user>/`. Reusable behavior lives
under `modules/features/`; small role aspects such as `graphical` compose only
features that are genuinely shared by several hosts.

```text
modules/
├── inventory.nix        # hosts, users, and their relationships
├── defaults.nix         # policy shared by every configuration
├── hosts/               # machine-specific configuration
├── users/               # person-specific configuration
├── features/            # reusable, independently selectable behavior
├── profiles/            # thin bundles of related features
└── tooling/             # flake development outputs
```

## Development shell

Repository tooling, including OpenCode, `just`, Nix language tools, and static
analysis tools, is available through the flake:

```sh
nix develop
```

Start the repository-scoped coding agent with:

```sh
nix develop -c opencode
```

OpenCode reads the repository rules from `AGENTS.md`, project permissions from
`opencode.json`, and the Den-specific subagents from `.opencode/agents/`. The
default workflow for non-trivial changes is **Plan → Build → `just format` →
`just check` → `den-reviewer`**. Use `den-researcher` when current Den/Nix
behavior needs to be verified against primary documentation.

## Commands

```sh
just check
just lint
just build desktop
just build laptop
just build vm
just build wsl
just full

nix flake check
nix build .#nixosConfigurations.desktop.config.system.build.toplevel
nix build .#nixosConfigurations.laptop.config.system.build.toplevel
nix build .#nixosConfigurations.vm.config.system.build.toplevel
nix build .#nixosConfigurations.wsl.config.system.build.toplevel
sudo nixos-rebuild switch --flake .#desktop
sudo nixos-rebuild switch --flake .#vm
home-manager switch --flake .#miko
nix fmt .
```

## NixOS-WSL

The WSL host uses native systemd and Windows interoperability, with `miko` as
the default user. Install an upstream NixOS-WSL image, make this private
repository available through a Windows-side checkout, then apply:

```sh
sudo nixos-rebuild switch --flake /mnt/c/path/to/nix-config#wsl
```

The YubiKey is attached directly to the shared WSL2 VM so Linux `pcscd`,
`scdaemon`, and `gpg-agent` provide both GPG operations and outbound SSH. In an
elevated PowerShell session, install and bind `usbipd-win` once:

```powershell
wsl --update
winget install --interactive --exact dorssel.usbipd-win
usbipd list
usbipd bind --busid <BUSID>
```

Keep a WSL shell open and attach from ordinary PowerShell whenever the key is
needed in WSL:

```powershell
usbipd attach --wsl --busid <BUSID>
```

After attachment, verify inside NixOS-WSL:

```sh
lsusb
systemctl status pcscd
gpgconf --kill scdaemon
gpg --card-status
ssh-add -L
ssh -T git@github.com
printf test | gpg --clearsign
```

While attached, Windows applications cannot use the YubiKey. Return ownership
to Windows with:

```powershell
usbipd detach --busid <BUSID>
```

Attachment is deliberately manual because bus IDs can change after moving the
device. The public OpenPGP certificate must also be imported into WSL's GPG
keyring; the card contains private subkeys, not the full public certificate.

## Laptop installation

The laptop target replaces the entire internal NVMe drive at
`/dev/disk/by-id/nvme-eui.e8238fa6bf530001001b444a481737ed` with a 1 GiB EFI
partition and a LUKS2-encrypted ext4 root. Confirm that path resolves to the
expected WD SN740 before running the destructive command. Secure Boot must
remain disabled until signed boot artifacts and owner keys are configured
after the first successful boot:

```sh
bootctl status
readlink -f /dev/disk/by-id/nvme-eui.e8238fa6bf530001001b444a481737ed
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS
sudo nix run .#disko -- --mode destroy,format,mount --flake .#laptop
```

The laptop password is immutable and must decrypt before user creation.
Lanzaboote also requires its signing identity while installing boot artifacts.
Before reinstalling, preserve `/etc/ssh/ssh_host_ed25519_key` and
`/var/lib/sbctl` outside the disk being erased. After Disko mounts the new
system under `/mnt`, restore both identities and verify that the SSH public key
derives the recipient recorded in `.sops.yaml`:

```sh
sudo install -d -m 0700 /mnt/etc/ssh
sudo install -m 0600 /path/to/backup/ssh_host_ed25519_key \
  /mnt/etc/ssh/ssh_host_ed25519_key
sudo install -m 0644 /path/to/backup/ssh_host_ed25519_key.pub \
  /mnt/etc/ssh/ssh_host_ed25519_key.pub
sudo install -d -m 0755 /mnt/var/lib
sudo cp -a /path/to/backup/sbctl /mnt/var/lib/sbctl
nix develop -c ssh-to-age < /mnt/etc/ssh/ssh_host_ed25519_key.pub
sudo nixos-install --flake .#laptop
```

If the old host identity is unavailable, generate a new one under `/mnt`, add
its age recipient to `.sops.yaml`, and run `sops updatekeys` on the encrypted
password using the YubiKey before installing. A manual `passwd` change is not a
substitute because immutable-user activation will replace it.

If the old Lanzaboote bundle is unavailable, disable Secure Boot enforcement,
reset the firmware to Setup Mode without clearing `dbx`, and generate replacement
keys in the installer. Copy them into the target before `nixos-install`:

```sh
nix shell nixpkgs#sbctl -c sh -c \
  'sudo "$(command -v sbctl)" create-keys'
sudo install -d -m 0755 /mnt/var/lib
sudo cp -a /var/lib/sbctl /mnt/var/lib/sbctl
sudo nixos-install --flake .#laptop
```

Back up the replacement bundle and enroll its keys after boot; firmware that
still trusts the lost keys cannot enforce booting artifacts signed by the new
bundle.

### Laptop recovery

The declarative password configuration disables mutable users and intentionally
locks password login for `root`. Preserve the LUKS passphrase, YubiKey, and
access to the private repository. To recover from a broken credential or system
generation, boot the installer, clone a corrected or known-good revision, and
mount the existing encrypted layout without formatting it:

```sh
sudo nix run .#disko -- --mode mount --flake .#laptop
findmnt /mnt
findmnt /mnt/boot
sudo nixos-install --flake .#laptop
```

Never use Disko's `destroy` or `format` modes during recovery. Password changes
must be made in the encrypted SOPS secret because activation replaces mutable
shadow state.

### Secure Boot

Lanzaboote signs boot artifacts with owner keys stored outside the Nix store at
`/var/lib/sbctl`. Keep Secure Boot enforcement off for the initial signed-boot
deployment. On a ThinkPad, never select **Clear All Secure Boot Keys**, which
can remove the forbidden-signature database (`dbx`). If necessary, enable the
Secure Boot firmware toggle and select **Reset to Setup Mode** instead; Setup
Mode does not enforce signatures.

Confirm firmware state, create the signing keys, and back them up to encrypted
offline storage before the first Lanzaboote switch:

```sh
bootctl status
nix shell nixpkgs#sbctl -c sh -c \
  'sudo "$(command -v sbctl)" create-keys'
sudo find /var/lib/sbctl -maxdepth 3 -type f -ls
```

Build and switch while enforcement is still off, then verify that the
bootloader and generation stubs are signed:

```sh
just build laptop
sudo nixos-rebuild switch --flake .#laptop
sudo sbctl verify
findmnt /boot
```

Reboot once before enrollment to test the signed Lanzaboote generation. Then
return to NixOS in firmware Setup Mode and preserve Microsoft UEFI certificates
needed by common ThinkPad Option ROMs while enrolling the owner keys:

```sh
sudo sbctl enroll-keys --microsoft
sudo sbctl status
sudo reboot
```

After reboot, verify enforcement and perform one controlled boot-generation
test. Do not reboot if signing or verification fails:

```sh
bootctl status
sudo sbctl status
sudo sbctl verify
sudo sbctl list-enrolled-keys
journalctl -k -b --grep='[Ss]ecure [Bb]oot'
sudo nixos-rebuild boot --flake .#laptop
sudo sbctl verify
```

Expected status is Secure Boot enabled in firmware User Mode. Recovery media
may require disabling Secure Boot temporarily. After firmware updates, repeat
the status and signature checks.

`flake.nix` is generated from the input declarations in
`modules/dendritic.nix`:

```sh
nix run .#write-flake
```

## Secrets bootstrap

The SOPS NixOS module is available through `den.aspects.secrets`, and the
development shell includes `sops` and `ssh-to-age`. The laptop password is
encrypted to its persistent Ed25519 SSH host identity and the YubiKey OpenPGP
encryption subkey.

Derive a host's non-interactive age recipient with:

```sh
nix develop -c ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

Each additional host must be added to the SOPS recipient policy before it uses
the password aspect. Hosts decrypt during activation without requiring the
YubiKey, while the YubiKey remains the human editing and recovery identity.
Use a staged mutable-user deployment to test decryption and the password hash
before enabling immutable users on another host.

The initial `desktop` definition expects an ext4 root filesystem labelled
`nixos` and an EFI system partition labelled `ESP`. Before deploying, replace
those low-priority defaults with the filesystem and swap declarations generated
on the physical machine if its disk layout differs.

Until the migrated configuration has enabled flakes on the running system,
pass `--extra-experimental-features 'nix-command flakes'` to `nix` commands.

## Agent safety boundary

The checked-in OpenCode configuration allows ordinary inspection, evaluation,
formatting, and builds, while deployment and destructive Git operations are
blocked. `git commit`, `git push`, `nixos-rebuild switch`, `home-manager switch`,
and `nh os switch` must remain explicit human actions.
