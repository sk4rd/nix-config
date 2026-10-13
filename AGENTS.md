# Repository guide

This repository is an aspect-oriented Nix configuration built with Den,
flake-parts, import-tree, Home Manager, and nixpkgs.

## Structure

- `modules/dendritic.nix`: flake inputs and top-level configuration. `flake.nix`
  is generated; regenerate it with `nix run .#write-flake` after input changes.
- `modules/inventory.nix`: host, home, user, and entity declarations. Den creates
  systems from `den.hosts`; do not construct systems with `lib.nixosSystem`.
- `modules/features/`: reusable capabilities defined as `den.aspects.<name>`.
- `modules/profiles/`: compositions of aspects, primarily through `includes`.
- `modules/hosts/<host>/`: host-specific configuration; `default.nix` composes
  aspects and `hardware.nix` defines hardware and storage.
- `modules/users/<user>/`: user-specific aspects and Home Manager configuration.
- `modules/tooling/`: flake checks, packages, and development shells.

Nix files under `modules/` are discovered by import-tree. Do not add manual
imports for ordinary flake-parts modules.

## Design conventions

- Follow existing repository patterns and the [Den documentation](https://den.denful.dev/).
- Keep reusable concerns in a single aspect across applicable classes (such as
  `nixos` and `homeManager`); compose with `includes`, not file-level imports.
- Prefer built-in `den.batteries.*` over custom implementations.
- Use Den context (`{ host, user, ... }`), context-aware dispatch, and mutual
  providers for routing; avoid parallel host-first wiring and custom `specialArgs`.
- Put configuration in the narrowest appropriate owner. Avoid redundant
  abstractions and duplication.
- Keep comments and documentation concise; explain non-obvious decisions rather
  than restating code.

## Working with changes

1. Inspect the affected aspects, inventory, and nearby examples before proposing
   a design or change.
2. Prefer the smallest coherent solution. Explain any departure from established
   Den conventions.
3. Check version-sensitive framework behavior against pinned sources or primary
   documentation rather than guessing.
4. For configuration changes, use `just format` and `just check` where applicable;
   verify the intended host/user scope. Reserve `just full` for expensive
   pre-merge verification.
5. Review the diff for correctness, ownership, unnecessary complexity, and
   unintended changes. Report checks actually run and any remaining uncertainty.

Git-backed flakes may not see newly created, untracked files under `modules/`;
account for this when evaluating new modules.

For changes involving boot, storage, secrets, networking, security, or Den routing,
review the impact especially carefully.
