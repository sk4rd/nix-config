# Nix configuration

This is a feature-oriented [Den](https://den.denful.dev/) configuration for
multiple NixOS hosts and users. Every Nix file under `modules/` is a
flake-parts module discovered by `import-tree`.

## Inventory

- NixOS host: `desktop` (AMD CPU, Radeon RX 7900 XT, Plasma 6)
- NixOS host: `vm` (network hostname `nixos`)
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
just build vm
just full

nix flake check
nix build .#nixosConfigurations.desktop.config.system.build.toplevel
nix build .#nixosConfigurations.vm.config.system.build.toplevel
sudo nixos-rebuild switch --flake .#desktop
sudo nixos-rebuild switch --flake .#vm
home-manager switch --flake .#miko
nix fmt .
```

`flake.nix` is generated from the input declarations in
`modules/dendritic.nix`:

```sh
nix run .#write-flake
```

## Secrets bootstrap

The SOPS NixOS module is available through `den.aspects.secrets`, and the
development shell includes `sops` and `ssh-to-age`. Password management is not
enabled until each installed host has a persistent Ed25519 SSH host key.

After installing a host, derive its non-interactive age recipient with:

```sh
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

The future SOPS policy should encrypt the password hash to each host recipient
and to the YubiKey's OpenPGP encryption subkey. This lets hosts decrypt during
activation without requiring the YubiKey, while the YubiKey remains the human
editing and recovery identity. Enable `users.mutableUsers = false` only after
runtime decryption and login have been tested on every host.

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
