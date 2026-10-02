# Repository contract

This is an aspect-oriented Nix configuration using Den, flake-parts,
import-tree, Home Manager, and nixpkgs.

## Architecture

- `flake.nix` is generated; never edit it directly. Inputs belong in
  `modules/dendritic.nix`. After intentional input changes, regenerate with
  `nix run .#write-flake`.
- Every Nix file under `modules/` is discovered by import-tree. Do not manually
  import normal flake-parts modules.
- `modules/inventory.nix` declares hosts, homes, users, and entity metadata only.
  Den generates systems from `den.hosts`; do not construct `lib.nixosSystem`.
- `modules/features/`: reusable capabilities exposing `den.aspects.<name>`.
- `modules/profiles/`: thin compositions, mostly `includes`.
- `modules/hosts/<host>/`: genuinely machine-specific configuration;
  `default.nix` composes the host aspect, `hardware.nix` owns hardware and storage.
- `modules/users/<user>/`: user-specific aspects and Home Manager configuration.
- `modules/tooling/`: flake outputs such as checks, packages, and development shells.

Follow the principles at https://den.denful.dev/:

- Keep a reusable concern in one aspect across its relevant classes (for example,
  `nixos` and `homeManager`); compose aspects through `includes`, not file-level
  NixOS imports of repository features.
- Prefer existing `den.batteries.*` over handwritten equivalents, such as
  `den.batteries.unfree` for package permissions.
- Use context arguments (`{ host, user, ... }`), context-aware dispatch, and mutual
  providers for routing. Do not bypass Den with custom `specialArgs` or parallel
  host-first wiring. Document any necessary exception and why supported routing
  cannot cover it.
- For new or changed framework plumbing, verify relevant APIs against pinned
  source and primary docs. Follow established local patterns for ordinary settings;
  load `den-research` when behavior is uncertain rather than guessing.

## Change workflow

1. Inspect relevant files and, for configuration changes, aspects and inventory.
   Choose the owning directory above; implement the smallest coherent change.
2. For configuration changes, run `just format`, then `just check`, plus targeted
   verification of generated values/files and intended host/user scope.
   Documentation-only changes need diff and consistency checks, not Nix builds.
3. Self-review the scoped diff for correctness, Den principles, battery reuse,
   ownership, and unnecessary complexity. Evaluation alone is not sufficient.
4. Apply the review policy below. Resolve substantive findings and rerun affected
   checks; repeat independent review only for substantive fixes or unresolved risks.
5. Report changes and actual validation, including failures or checks not run.

Use `just full` for expensive pre-merge verification. New files under `modules/`
may be invisible to Git-backed flakes; use `git add -N <file>` if needed to expose
one without staging its contents, subject to tool permissions.

## Independent review and skills

Independent review is required for:

- New shared aspects, host/user routing or scope changes, structural refactors,
  or dependency changes.
- Security, secrets, storage, boot, networking, or privileged activation logic.
- Unclear Den behavior or unresolved correctness/architecture concerns.

Documentation, colors, ordinary application settings, and established battery
usage do not need independent review unless a trigger above applies. Assess
mechanism and impact, not diff size.

For required or requested review, use `nix-review` in a separate agent thread.
Supply the task-specific diff, relevant dependencies, verification results, and
risks; exclude unrelated pending changes unless they interact with the task.

Load project skills from trusted worktrees only:

- `den-research`: version-sensitive framework research; no edits.
- `nix-review`: scoped independent review; no edits.
- `neon-flux-theme`: theme design, canonical references, and port verification.

## Safety

- Preserve unrelated working-tree and staged changes.
- Do not deploy, commit, or push without explicit instruction for that operation
  in the current conversation. Authorization covers only the requested scope.
- Before authorized deployment, commit, or push, read
  [docs/agent-operations.md](docs/agent-operations.md). Never deploy unrelated
  pending changes or commit plaintext credentials, private keys, or decrypted SOPS data.
- Do not run destructive Git commands such as `git reset --hard` or `git clean`
  without explicit authorization for that exact operation.
- Do not update `flake.lock` unless the task explicitly requires dependency changes.
- Building and evaluating are allowed; repository guidance does not replace tool
  permissions or approval prompts.
