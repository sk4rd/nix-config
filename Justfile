set shell := ["bash", "-euo", "pipefail", "-c"]

# Default local quality gate for humans and agents.
check: eval secrets

# Format the repository. Inspect the resulting Git diff afterwards.
format:
    nix fmt .

# Evaluate all configurations without deploying or building their closures.
eval:
    #!/usr/bin/env bash
    set -euo pipefail
    nix flake check --no-build --show-trace --no-write-lock-file --option eval-cache false
    hosts=$(nix eval --raw --no-write-lock-file --option eval-cache false .#nixosConfigurations --apply 'cs: builtins.concatStringsSep " " (builtins.attrNames cs)')
    for host in $hosts; do
        nix eval --raw --no-write-lock-file --option eval-cache false ".#nixosConfigurations.$host.config.system.build.toplevel.drvPath" >/dev/null
    done
    homes=$(nix eval --raw --no-write-lock-file --option eval-cache false .#homeConfigurations --apply 'cs: builtins.concatStringsSep " " (builtins.attrNames cs)')
    for home in $homes; do
        nix eval --raw --no-write-lock-file --option eval-cache false ".#homeConfigurations.$home.activationPackage.drvPath" >/dev/null
    done

# Build every host's sops manifest: catches a secret whose name and sops file key do not line up.
secrets:
    #!/usr/bin/env bash
    set -euo pipefail
    hosts=$(nix eval --raw --no-write-lock-file --option eval-cache false .#nixosConfigurations --apply 'cs: builtins.concatStringsSep " " (builtins.attrNames cs)')
    for host in $hosts; do
        nix build ".#nixosConfigurations.$host.config.system.build.sops-nix-manifest" --no-link --no-write-lock-file --option eval-cache false
    done

# Static Nix analysis. Run from `nix develop` so statix/deadnix are available.
lint:
    statix check .
    deadnix --fail .


# Build one NixOS host without switching to it or creating a result symlink.
build host:
    nix build ".#nixosConfigurations.{{host}}.config.system.build.toplevel" --no-link --no-write-lock-file --option eval-cache false

# Refresh the persistent local source mirror without activating it.
sync:
    bash modules/tooling/pull-nix-config.sh

# Expensive pre-merge verification.
full: check lint
    #!/usr/bin/env bash
    set -euo pipefail
    nix flake check --show-trace --no-write-lock-file --option eval-cache false
    hosts=$(nix eval --raw --no-write-lock-file --option eval-cache false .#nixosConfigurations --apply 'cs: builtins.concatStringsSep " " (builtins.attrNames cs)')
    for host in $hosts; do
        nix build ".#nixosConfigurations.$host.config.system.build.toplevel" --no-link --no-write-lock-file --option eval-cache false
    done
    homes=$(nix eval --raw --no-write-lock-file --option eval-cache false .#homeConfigurations --apply 'cs: builtins.concatStringsSep " " (builtins.attrNames cs)')
    for home in $homes; do
        nix build ".#homeConfigurations.$home.activationPackage" --no-link --no-write-lock-file --option eval-cache false
    done
