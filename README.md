# nix-config

My NixOS configurations.

## Hosts

- `desktop` — GPU passthrough setup with native GPU boot specialisation
- `laptop`
- `wsl`
- `work` — work-specific WSL host
- `nas`

## Structure

```
├── flake.nix
├── hosts/
│   ├── default.nix       # Global NixOS baseline + shared sops defaults
│   ├── common/           # Shared desktop/laptop config
│   ├── desktop/
│   ├── laptop/
│   ├── wsl/
│   ├── work/
│   └── nas/
├── home/
│   ├── default.nix       # Shared Home Manager baseline
│   ├── common/           # Shell/git/editor shared modules
│   ├── miko/
│   ├── wsl/
│   └── work/
└── secrets/              # Encrypted with sops
```

## Usage

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

## Secrets

Managed with [sops-nix](https://github.com/Mic92/sops-nix). GPG (Yubikey) for editing, age (SSH host keys) for decryption.

```bash
# Edit secrets
sops secrets/secrets.yaml
# Add new machine
cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
# Add key to .sops.yaml, then:
sops updatekeys secrets/secrets.yaml
```
