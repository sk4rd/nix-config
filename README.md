# SLOP DISCLAIMER - THIS IS MOSTLY SLOP
# Nix configuration

This is a feature-oriented [Den](https://den.denful.dev/) configuration for
multiple NixOS hosts and users. Every Nix file under `modules/` is a
flake-parts module discovered by `import-tree`.

Hosts and users are declared in `modules/inventory.nix`. Repository architecture
and agent instructions are in [AGENTS.md](AGENTS.md).

## Development shell

Enter the repository's tool environment:

```sh
nix develop
```

## Zed workflow

Launch `nix develop -c zeditor .` to give Zed the repository shell's tools.
Restart an already-running editor to pick up environment changes.
`.zed/tasks.json` exposes `format` and `check` through `task: spawn`.

## Commands

```sh
just check
just lint
just format
just build desktop  # replace desktop with laptop, nas, or wsl
just full

sudo nixos-rebuild switch --flake .#desktop
home-manager switch --flake .#miko
```

## Verification

`just check` evaluates every host and standalone home and builds SOPS manifests.
`just lint` runs static Nix analysis. `just full` adds flake checks and builds all
host/home closures. Evaluation and builds do not prove live service behavior.

## NAS

See [NAS operating context](modules/hosts/nas/CONTEXT.md) for storage constraints
and retained migration data, and [media request setup](docs/media-requests.md)
for manual application integration.

## Installation and recovery

See [installation and recovery](docs/installation-and-recovery.md) for WSL
setup, desktop and laptop installation, Secure Boot, and secrets bootstrap.
Read the relevant procedure in full before acting; it includes destructive-disk
warnings and required identity backups.

## Generated flake

`flake.nix` is generated from the input declarations in
`modules/dendritic.nix`:

```sh
nix run .#write-flake
```

Deployment and Git commits are manual actions. Agents must follow the safety
boundary in [AGENTS.md](AGENTS.md) and read the
[operations policy](docs/agent-operations.md) before authorized operations.
