set shell := ["bash", "-euo", "pipefail", "-c"]

# Default local quality gate for humans and agents.
check: eval

# Format the repository. Inspect the resulting Git diff afterwards.
format:
    nix fmt .

# Evaluate all configurations without deploying or building their closures.
eval:
    nix flake check --no-build --show-trace
    nix eval --raw .#nixosConfigurations.desktop.config.system.build.toplevel.drvPath >/dev/null
    nix eval --raw .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath >/dev/null
    nix eval --raw .#nixosConfigurations.vm.config.system.build.toplevel.drvPath >/dev/null
    nix eval --raw .#nixosConfigurations.wsl.config.system.build.toplevel.drvPath >/dev/null
    nix eval --raw .#homeConfigurations.miko.activationPackage.drvPath >/dev/null

# Static Nix analysis. Run from `nix develop` so statix/deadnix are available.
lint:
    statix check .
    deadnix --fail .

# Build one NixOS host without switching to it or creating a result symlink.
build host:
    nix build ".#nixosConfigurations.{{host}}.config.system.build.toplevel" --no-link

# Expensive pre-merge verification.
full: check lint
    nix flake check --show-trace
    nix build .#nixosConfigurations.desktop.config.system.build.toplevel --no-link
    nix build .#nixosConfigurations.laptop.config.system.build.toplevel --no-link
    nix build .#nixosConfigurations.nas.config.system.build.toplevel --no-link
    nix build .#nixosConfigurations.vm.config.system.build.toplevel --no-link
    nix build .#nixosConfigurations.wsl.config.system.build.toplevel --no-link
    nix build .#homeConfigurations.miko.activationPackage --no-link
