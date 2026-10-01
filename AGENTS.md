# Repository architecture

This is a Nix configuration built with Den, flake-parts, import-tree,
Home Manager, and nixpkgs.

Den is aspect-oriented. Prefer reusable aspects over host-first configuration.

## Important rules

- `flake.nix` is generated. Never edit it directly.
- Flake inputs are declared in `modules/dendritic.nix`.
- After intentionally changing flake inputs, regenerate `flake.nix` with
  `nix run .#write-flake`.
- Every Nix file below `modules/` is automatically discovered by import-tree.
  Do not manually add normal flake-parts module imports.
- Do not manually construct `lib.nixosSystem` for normal hosts. Hosts are
  declared through `den.hosts` in `modules/inventory.nix`; Den generates
  `nixosConfigurations`.

## Directory responsibilities

### `modules/inventory.nix`

Declare hosts, homes, users, and entity metadata here. Do not put ordinary
NixOS or Home Manager configuration here.

### `modules/features/`

Reusable capabilities such as networking, PipeWire, desktop environments, and
development tools. A feature should normally expose a `den.aspects.<name>`
aspect.

Put configuration here when it can reasonably be reused by multiple hosts or
users.

### `modules/profiles/`

Thin compositions of reusable features. Profiles should mostly contain
`includes`; avoid implementing substantial configuration directly in them.

### `modules/hosts/<host>/`

Configuration that genuinely belongs to one physical or virtual machine.
`default.nix` defines the host aspect and composes reusable aspects.
`hardware.nix` contains machine-specific hardware, filesystems, boot settings,
and similar configuration.

Do not copy reusable application or service configuration into host files.

### `modules/users/<user>/`

User-specific aspects and Home Manager configuration.

### `modules/tooling/`

Flake development outputs such as formatters, packages, checks, and development
shells. These are repository tooling, not Den host/user aspects.

## Den design

The ideas and principles documented at https://den.denful.dev/ are mandatory
for future edits to this repository, not optional style suggestions.

- Consult the relevant Den documentation and the pinned Den source before
  implementing framework plumbing; do not assume APIs from another version.
- Prefer existing `den.batteries.*` over handwritten equivalents for common
  patterns (for example, `den.batteries.unfree` for package permissions).
- Keep each reusable concern in one aspect across its relevant classes;
  compose capabilities rather than duplicating them across hosts or users.
- Use Den's context-aware dispatch and mutual providers for routing. Keep
  profiles thin and inventory limited to entity declarations and metadata.
- Do not add parallel host-first wiring, custom `specialArgs`, or manual system
  construction to bypass Den. Document any necessary exception and why the
  framework's supported mechanism cannot cover it.
- Self-review and any required independent review must check these principles
  and battery reuse, not just whether Nix evaluates.

Prefer aspect composition:

```nix
den.aspects.foo.includes = [
  den.aspects.bar
];
```

over file-level NixOS imports for composing repository features.

A concern that affects both NixOS and Home Manager should normally stay in one
aspect:

```nix
den.aspects.foo = {
  nixos = { ... };
  homeManager = { ... };
};
```

Use Den context arguments such as `{ host, user, ... }` when behavior depends
on entity metadata rather than constructing custom `specialArgs`.

## Change workflow

For every repository change, including small changes:

1. Inspect the relevant existing aspects and inventory declarations.
2. Decide whether the change is a feature, profile, host concern, user concern,
   or repository-tooling concern.
3. For Den APIs or behavior that is unclear, load the `den-research` project
   skill and research the pinned Den source instead of guessing.
4. Implement the smallest coherent change.
5. For configuration changes, run `just format`, then `just check`, plus
   targeted verification of generated values/files and intended host/user scope.
   Documentation-only changes need diff and consistency checks, not Nix builds.
6. Self-review the task's diff for correctness, Den principles, battery reuse,
   and the directory responsibilities above. Evaluation alone is not sufficient.
7. Classify the change using the review policy below. For changes that require
   independent review, invoke Hermes `/review` with the `nix-review` skill loaded;
   do not invoke it automatically for every edit.
8. Resolve substantive findings and rerun checks affected by any fixes. Request
   another independent pass only for substantive fixes or unresolved risks.

### Risk-based independent review

Hermes project skills are enabled only for the trusted repository root. Load
`den-research` for uncertain Den behavior and `nix-review` only for required or
requested independent reviews.

Independent review is required for:

- new shared aspects, host/user routing or scope changes, structural refactors,
  and dependency changes;
- security, secrets, storage, boot, networking, or privileged activation logic;
- unclear Den behavior or unresolved correctness/architecture concerns.

Independent review is not required for documentation, colors, ordinary
application settings, or established battery usage when none of the triggers
above apply. Assess mechanism and impact, not merely diff size. Self-review and
appropriate executable verification remain mandatory.

When delegating, provide the task-specific diff, relevant dependencies, and
specific risks to check. Exclude unrelated pre-existing working-tree changes
unless they interact with the task. The reviewer must check correctness, Den
principles, battery reuse, directory responsibilities, and verification quality.
Do not repeat full reviews or checks unchanged by a fix.

For new files under `modules/`, remember that flakes backed by Git only expose
files that are part of the Git source. If evaluation cannot see a newly created
file, use `git add -N <file>` to make it visible without staging its contents.

Use `just full` for expensive pre-merge verification.

## Safety

Do not deploy, commit, or push without explicit user instruction for that operation
in the current conversation. A specific request authorizes that operation, but not
unrelated changes or other external side effects.

For an explicitly authorized deployment:

- Identify the target host and exact change scope. Never deploy a mixed dirty
  checkout: isolate the requested changes in a clean worktree or otherwise
  ensure unrelated pending changes are excluded. Do not infer that "deploy"
  means "deploy everything in the worktree."
- Run the required evaluation, build, and secret-manifest checks; inspect the
  rendered artifacts and state any missing runtime prerequisites before switching.
- After switching, verify the active generation and the specific service/config
  effect on the target. Report partial activation accurately.

For an explicitly authorized commit:

- Review the full diff and stage only the changes in the requested scope. When
  asked for multiple commits, split them into small, coherent commits in logical
  dependency order and verify each commit's contents.
- Never commit plaintext credentials, private keys, or decrypted SOPS data.
  Preserve unrelated user staging and working-tree changes.

Do not push unless the user explicitly requests a push. Do not run destructive
Git commands such as `git reset --hard` or `git clean` unless the user explicitly
authorizes that exact operation.

Building and evaluating configurations is allowed. Hermes approval and tool
permissions are configured in Hermes itself; these repository instructions do
not replace those runtime controls.

Do not update `flake.lock` unless the task explicitly requires dependency
changes.
