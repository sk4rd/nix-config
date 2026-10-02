# SLOP DISCLAIMER - THIS IS MOSTLY SLOP
# Nix configuration

This is a feature-oriented [Den](https://den.denful.dev/) configuration for
multiple NixOS hosts and users. Every Nix file under `modules/` is a
flake-parts module discovered by `import-tree`.

## Inventory

- NixOS host: `desktop` (AMD CPU, Radeon RX 7900 XT, Plasma 6)
- NixOS host: `laptop` (ThinkPad Z13 Gen 1, Plasma 6)
- NixOS host: `nas` (ZFS storage, media, automation, SMB, and WireGuard)
- NixOS host: `wsl` (NixOS-WSL with direct YubiKey attachment)
- User and standalone Home Manager configuration: `miko`
- NAS administration user: `admin`

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

The flake provides `just`, Git, Nix language tools, static analysis, and common
agent tools: Python 3, `ripgrep`, `fd`, `tree`, `jq`, `curl`, `wget`, `file`,
`unzip`, `patch`, and `shellcheck`:

```sh
nix develop
```

## Zed workflow

Zed is installed with the workstation profile, and the repository is set up for
it:

```sh
zeditor ~/Documents/nix-config
```

- [`AGENTS.md`](AGENTS.md) is the project instruction file — always-on agent
  context.
- `.agents/skills/` holds on-demand guidance, shared with every clone:
  `den-research` verifies uncertain framework APIs against pinned dependencies;
  `nix-review` guides an independent reviewer for high-risk or requested changes;
  `neon-flux-theme` guides palette-based ports and rendered verification.
  Ordinary settings changes do not need a skill or another agent.
- The shared development aspect installs these common tools for Miko, so agents
  in Zed can use them without entering a repository shell after Home Manager
  activation. For an undeployed checkout, launch `nix develop -c zeditor .` to
  give Zed the repository shell's tools. Already-running editors must be restarted
  to pick up the new environment.
- `.zed/settings.json` formats Nix on save with `nixfmt`, the formatter
  `nix fmt .` uses; `.zed/tasks.json` puts `format` and `check` in
  `task: spawn`. Everything else in the Justfile runs in Zed's terminal after
  `nix develop`.

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
host/home closures. There is no separate Python regression suite; use targeted
inspection of generated values/files for the behavior being changed. Evaluation
and builds do not prove live service behavior.

For Git review, run `lazygit` inside any repository. Automatic remote fetching is disabled.

## NAS

The NAS runs Jellyfin, Home Assistant Container, authenticated Samba shares,
Traefik, Cloudflare DDNS, WireGuard, and a Gluetun-isolated qBittorrent/Firefox
stack. Desktop and laptop use encrypted CIFS credentials for on-demand Documents
and Torrents automounts. Machine-specific storage, networking, and migration
history are documented under `modules/hosts/nas/`.

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
