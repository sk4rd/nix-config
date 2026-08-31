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
3. For Den APIs or behavior that is unclear, delegate research to the
   `den-researcher` subagent instead of guessing.
4. Implement the smallest coherent change.
5. Run `just format`, then `just check`.
6. Inspect `git diff`.
7. Delegate a second pass to the `den-reviewer` subagent.
8. Resolve substantive findings.
9. Run `just format` and `just check` again.

Never skip the `den-reviewer` pass because a change appears simple. The review
must explicitly check the complete diff against Den's aspect-oriented design,
the directory responsibilities above, and the distinction between reusable
features, profiles, hosts, users, and repository tooling.

For new files under `modules/`, remember that flakes backed by Git only expose
files that are part of the Git source. If evaluation cannot see a newly created
file, use `git add -N <file>` to make it visible without staging its contents.

Use `just full` for expensive pre-merge verification.

## Safety

Never deploy automatically.

Do not run:

- `nixos-rebuild switch`
- `home-manager switch`
- `nh os switch`
- `git commit`
- `git push`
- destructive Git commands such as `git reset --hard` or `git clean`

Building and evaluating configurations is allowed. The checked-in OpenCode
configuration uses a deny-by-default shell whitelist and prevents agents from
editing the harness/control files that define those permissions.

Do not update `flake.lock` unless the task explicitly requires dependency
changes.
