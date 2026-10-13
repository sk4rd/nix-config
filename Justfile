
set shell := ["bash", "-euo", "pipefail", "-c"]

# Evaluate the flake without building.
check:
    nix flake check --no-build --no-write-lock-file

# Format Nix files.
format:
    nix fmt .

# Run static analysis.
lint:
    statix check .
    deadnix --fail .

# Validate sops-nix manifests for all hosts.
secrets:
    #!/usr/bin/env bash
    set -euo pipefail
    hosts=$(nix eval --json .#nixosConfigurations --apply 'cs: builtins.attrNames cs' | jq -r '.[]')
    for host in $hosts; do
        nix build ".#nixosConfigurations.$host.config.system.build.sops-nix-manifest" \
            --no-link --no-write-lock-file
    done

# Build a specific host without activating it.
build host:
    nix build ".#nixosConfigurations.{{host}}.config.system.build.toplevel" \
        --no-link --no-write-lock-file
