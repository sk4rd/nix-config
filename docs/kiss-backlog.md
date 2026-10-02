# KISS review backlog

Follow-ups identified in the whole-repository review of revision `15392b4`.
This is a historical working backlog, not a statement of current repository
state or authorization to implement, deploy, commit, or push. Recheck each
open item against the current checkout before acting; source locations and
acceptance criteria may have gone stale. Owners are unassigned and no deadlines
have been set.

## How to use this backlog

- The current `AGENTS.md`, repository state, and pinned dependencies take
  precedence over this review snapshot. Follow the current repository workflow
  for implementation, verification, review, and authorization.
- Reassess an item's value and scope before doing it; close or revise work that
  has already been superseded instead of preserving obsolete steps for their own
  sake. Keep any change small and aligned with current Den patterns.
- Treat the listed safety constraints as task-specific cautions, not a complete
  substitute for current repository guidance. Do not weaken security or storage
  guarantees without an explicitly verified equivalent.

## Task index

P1 = first tranche; P2 = subsequent cleanup; P3 = investigation, not an agreed change.
Dependencies are task IDs; "none" means the work can be started independently.

| Done | ID | Priority | Task | Dependencies |
|---|---|---|---|---|
| [x] | KISS-01 | P1 | Restore a clean test/lint baseline | none |
| [x] | KISS-02 | P1 | Decouple SilverBullet theming from backend startup | none |
| [ ] | KISS-03 | P1 | Use upstream Hermes installation options | none |
| [ ] | KISS-04 | P1 | Remove redundant NixOS evaluation and batch builds | KISS-01 |
| [ ] | KISS-05 | P1 | Replace historical/source-spelling tests with current contracts | KISS-01 |
| [ ] | KISS-06 | P2 | Make service aspects own their identities | none |
| [x] | KISS-07 | P2 | Make consumers own their secret declarations | none |
| [x] | KISS-08 | P2 | Pass canonical SOPS paths to provisioning consumers | none |
| [ ] | KISS-09 | P2 | Merge mount-safety dependencies additively | none |
| [ ] | KISS-10 | P2 | Narrow Homepage ownership changes | KISS-05 |
| [ ] | KISS-11 | P2 | Separate SSH policy from personal authorization | none |
| [ ] | KISS-12 | P2 | Remove the unused password-SSH aspect | none |
| [ ] | KISS-13 | P3 | Validate a loopback-only shared Hermes backend | KISS-05 |
| [ ] | KISS-14 | P3 | Decide whether ZFS import/scrub lists should share metadata | none |
| [ ] | KISS-15 | P3 | Assess a native Homepage migration | KISS-05 |

The order below was suggested during the original review, not freshly checked.
Reassess dependencies and sequencing against the current checkout before use.
If KISS-15 is approved for implementation, reassess whether KISS-10 is still needed.

## KISS-01 — Restore a clean test/lint baseline

**Status:** complete. The fixture now substitutes paths in one pass and explicitly
uses a nested `srv/hermes/home` path to reproduce replacement collisions regardless
of `TMPDIR`. The empty Nix argument pattern was removed; production shell behavior
and host/user routing are unchanged.

**Verification:** the strengthened regression failed in both checkout subcases
before the fix and passed afterward. All seven launcher/workspace tests passed,
including argument handling, SSH failure propagation, and evaluated host scope.
`just format`, `just check`, and `just lint` passed. `just test` ran 105 tests with
no failures and the two known Homepage skips, still tracked under KISS-05.
Checks used a writable scratch `XDG_RUNTIME_DIR`; no production sandboxing changed.
No full system closure build or deployment was performed.

**Scope:** repository tooling; `scripts/test_nas_hermes_terminal.py:47–68`,
`modules/features/nas-hermes-terminal.nix:1`.

**Steps:**
1. Reproduce the workspace-shell fixture failure with scratch paths beneath
   `/srv/hermes/home`. Sequential replacements currently modify a path inserted
   by an earlier replacement.
2. Substitute fixture paths in one pass so replacement values are never processed
   again. Keep the production shell behavior unchanged; do not add production
   options solely to accommodate a test.
3. Remove the unnecessary empty argument pattern from the launcher aspect.

**Done when:** both workspace-shell subcases pass with nested scratch paths;
launcher argument/SSH-failure/scope tests still pass; `just lint` passes; the
full regression suite has no unexpected failures. The two Homepage skips remain
tracked by KISS-05, not hidden as successful coverage.

**Review:** self-review unless implementation introduces a risk trigger.
A read-only inherited `XDG_RUNTIME_DIR` caused separate tooling errors during
review; use a writable scratch runtime directory for that test invocation only.
Do not change production sandboxing to fix the testing environment.

## KISS-02 — Decouple SilverBullet theming from backend startup

**Status:** complete. Container startup no longer checks the `notes` space or
installs the theme. The separate `silverbullet-theme.service` oneshot reuses the
dataset mount guard and runs as `silverbullet`. Missing spaces are logged and
skipped without creation; write failures fail only the theme unit. NAS setup
and theme documentation explain Space Manager creation and explicit theme-unit
restart/client reload after first-run setup.

**Verification:** the backend-independence regression failed before the change
and passed afterward. Five focused tests cover rendered NAS-only scope,
unprivileged mount guards, absent spaces, repeated installation with preserved
ownership/mode and untouched unrelated pages, and actual installation failure
at a directory target. Before/after evaluation preserves container identity,
image, volumes, ports, routing/DDNS and mount assertions; only the two
theme-related startup commands were removed. The theme-unit script built and
the rendered page matches the canonical palette. `just format`, `just check`,
`just lint`, and `just test` passed: 117 tests, no failures, two known Homepage
skips. Independent review found no substantive issues and reran all five
focused tests successfully. Live boot/configuration-switch behavior, NAS
permissions, first-run browser setup and theme synchronization remain untested;
no deployment, dataset changes, or full system closure builds were performed.

**Scope:** reusable service aspect; `modules/features/services/silverbullet.nix:44–51`;
setup documentation in `modules/hosts/nas/CONTEXT.md:71–78` and related SilverBullet docs.

**Steps:**
1. Move the theme write/check out of the container's blocking startup path into
   the smallest separate mount-guarded operation.
2. Run theme traversal/writes as `silverbullet`; retain protection against
   silently creating an unregistered `spaces/notes` directory.
3. Make a missing space visible without preventing the first-run UI from starting.
   Document how to install/refresh the theme after space creation.

**Done when:** evaluated container startup has no dependency on `spaces/notes`;
a safe fixture covers absent and existing spaces, including failed writes;
existing-space installation retains ownership/permissions; setup documentation
matches the new lifecycle. Record any untested live setup/theme-refresh behavior.

**Review:** required; service lifecycle, storage, and privileged setup are affected.
Do not create/delete datasets or deploy as part of this task without authorization.

## KISS-03 — Use upstream Hermes installation options

**Scope:** Home Manager feature; `modules/features/hermes-desktop.nix:7–14`.

**Steps:**
1. Recheck the pinned module's `programs.hermes-agent.enable` and
   `programs.hermes-agent.desktop.enable` behavior.
2. Replace direct CLI/desktop `home.packages` entries with those options;
   preserve existing settings and host/user scope.
3. Inspect the generated launcher and state/environment wiring, particularly
   `HERMES_HOME` and managed-configuration behavior.

**Done when:** desktop/laptop still receive CLI and desktop applications without
parallel manual installation; WSL/standalone scope is unchanged; intended model,
review, and trusted-project settings are unchanged; launcher/state behavior is
explicitly verified or recorded as awaiting runtime validation.

**Review:** required for launcher/state integration; do not silently change GUI
configuration ownership or remote-gateway selection.

## KISS-04 — Simplify evaluation and build orchestration

**Scope:** repository tooling; `Justfile:14–21,28–30,50–57`;
`scripts/test_tooling.py`.

**Steps:**
1. Remove the NixOS toplevel loop duplicated by `nix flake check --no-build`.
2. Retain explicit standalone Home Manager activation evaluation.
3. Collect discovered targets into shell arrays and batch manifest/closure
   builds where practical; do not replace the recipes with another framework.
4. Update tooling tests to assert coverage and failure propagation rather than
   requiring the old per-target process shape.

**Done when:** every current and synthetic newly discovered target is covered;
discovery failures remain fatal; `--no-link` and lockfile protection remain;
`just check` succeeds; full-build target coverage is verified by dry-run/fake-Nix
checks. Claim performance gains only if actually measured.

**Review:** required for the structural tooling refactor. Building full system
closures is not necessary solely to prove recipe target discovery.

## KISS-05 — Test current generated contracts

**Scope:** repository tests/tooling; `scripts/test_nas_helpers.py:64–99,157–165`,
`scripts/test_feature_composition.py:118–124`, and `Justfile:test/full` if needed.

**Steps:**
1. Replace the completed Homepage migration comparator with current evaluated
   assertions for mount guards, secret ordering, and installer attachment.
2. Wire the safe fake-installer test into a documented runnable test path;
   preserve permission and failure-propagation checks before retiring old code.
3. Assert all three placeholder-backed assignments in `hermes.env` and the
   unit's matching `EnvironmentFile`, instead of checking source substrings.
4. Reuse the existing evaluation query where practical rather than adding
   redundant Nix processes.

**Done when:** supported test commands execute current Homepage artifact checks
instead of permanently skipping them; bad ownership/missing-input cases fail;
all three Hermes credential channels and their linkage are verified without
secret decryption; harmless source rearrangement does not invalidate the tests.

**Review:** required for authentication/permission regression coverage.
Do not retire a historical check until its still-relevant guarantees are covered.

## KISS-06 — Make service aspects own their identities

**Scope:** reusable NAS services; `nas-service-identities.nix:2–38`,
`modules/profiles/nas-server.nix:6`, and owning service aspects.

**Steps:**
1. Capture evaluated users/groups, UID/GID values, and memberships before editing.
2. Move unchanged service-specific identity declarations into their capabilities.
   Put the backup-server identity in an appropriate existing host/service concern,
   not in the client backup aspect; keep shared memberships explicit.
3. Derive container `PUID`/`PGID`/`user` strings from canonical account declarations.
   Firefox continues using the qBittorrent identity.
4. Remove the profile-wide bundle only after all responsibilities have owners.

**Done when:** the full NAS account/group matrix and container IDs match the
baseline; service aspects bring their required identities; profiles remain thin;
independent composition tests cover representative services without the old bundle.

**Review:** required; structural scope and persistent-data ownership are affected.
No ID changes, recursive chown, or data migration.

## KISS-07 — Make consumers own their secret declarations

**Status:** complete. `nas-secrets` now contains only shared file/decryption
policy. Torrenting owns its qBittorrent password declaration; NAS networking owns
its WireGuard declarations. Ingress retains the shared policy without pulling in
unrelated secrets. Dashboard explicitly includes torrenting for its authenticated
qBittorrent widget, following the existing Prowlarr composition pattern.

**Verification:** new ownership and dashboard-composition regressions failed
before their respective fixes and passed afterward. Native Den ingress-only
composition declares only the Cloudflare secret; dashboard-only composition
provides its widget credential. Before/after evaluation preserves all four hosts'
secret metadata and encrypted-file hashes, NAS WireGuard/NAT/firewall settings,
eight affected rendered units, and all NAS SOPS templates (normalizing only
repository source store prefixes). `just format`, `just check` (including SOPS
manifest builds), `just lint`, and `just test` passed: 107 tests, no failures,
two known Homepage skips. Independent review caught the dashboard dependency;
the focused follow-up found no substantive unresolved issues. No secrets were
decrypted, encrypted files changed, or systems deployed.

**Scope:** `modules/features/credentials/nas-secrets.nix:7–19`,
`modules/features/services/nas-ingress.nix:8`, torrenting, and NAS networking.

**Steps:**
1. Keep NAS secret-file/decryption defaults as a small policy concern.
2. Move torrent credentials into the torrent service and machine-specific
   WireGuard credential declarations into the NAS networking concern.
3. Remove ingress's accidental dependency on unrelated credential declarations,
   while preserving the policy needed by its Cloudflare secret.

**Done when:** full NAS secret names, file sources, modes, and restart relationships
are unchanged; ingress-only composition does not declare torrent/WireGuard secrets;
SOPS manifests build; inventory remains metadata-only.

**Review:** required; secrets and networking scope are affected.
Do not broaden recipient access or change encrypted files merely to move declarations.

## KISS-08 — Pass canonical SOPS paths to provisioning consumers

**Status:** complete. Provisioning units pass canonical SOPS file paths through
environment variables; the scripts read those files at runtime rather than
hardcoding host secret paths. Backup SSH uses the quoted canonical key path.
The Gluetun container-local secret destination is unchanged. Prowlarr now rejects
an empty username as well as empty passwords before making API calls.

**Verification:** fixture-only regressions cover nondefault paths with spaces,
missing environment/files, empty credentials, unsafe qBittorrent passwords,
authenticated Prowlarr API configuration, and PBKDF2/idempotence. Actual Den
composition verifies overridden paths in rendered units, container mounts, and
SSH configuration on desktop/laptop/WSL, without adding backup policy to NAS.
Before/after evaluation preserves secret metadata, ownership/modes, restart
policy, lifecycle/mount guards, and Gluetun mounts; expected changes are path-only
unit environment entries and SSH path quoting. `just format`, `just check`
(including SOPS manifests), `just lint`, and `just test` passed: 112 tests,
no failures, two known Homepage skips. Both provisioning packages built
successfully. Independent review found no substantive issues and reran all five
focused tests successfully. No live credentials/APIs, secret decryption,
deployment, or full system closure builds were involved.

**Scope:** `modules/features/services/prowlarr/prowlarr-configure.py:12–15`,
`torrenting/qbittorrent-configure.sh:15`, their Nix unit wiring, and
`modules/features/backup.nix:25`.

**Steps:**
1. Pass file paths through minimal arguments/environment using
   `config.sops.secrets.<name>.path`; never pass plaintext secret values.
2. Use the canonical path in the backup SSH configuration.
3. Retain the intentional container-local secret destination used by Gluetun.

**Done when:** default behavior/permissions/restart policy are unchanged;
fixtures prove the scripts accept nondefault paths and reject missing/empty
credentials appropriately; generated units/SSH configuration use canonical paths;
no secret values appear in the store or logs.

**Review:** required; secret handling and authentication are affected.

## KISS-09 — Merge mount-safety dependencies additively

**Scope:** `modules/features/services/torrenting.nix:166–184`,
`dashboard.nix:91–96`; existing pattern in `hermes-shared.nix:99–109`.

**Steps:** use `lib.mkMerge` for `mountSafety` plus additional unit configuration;
remove manually repeated helper-owned dependencies from those fragments.

**Done when:** normalized evaluated `After`/`Requires` relationships retain the
original requirements without accidental duplication; explicit mount lists,
`RequiresMountsFor`, and `AssertPathIsMountPoint` are unchanged; relevant tests pass.

**Review:** required; storage safety and service ordering are affected.
This is not permission to remove the mount helper or its assertions.

## KISS-10 — Narrow Homepage ownership changes

**Scope:** `modules/features/services/dashboard.nix:18–24`;
installer regression checks in `scripts/test_nas_helpers.py`.

**Steps:**
1. Determine whether ancillary persistent files currently depend on blanket
   ownership repair. If unavailable, record that runtime prerequisite rather
   than assuming the directory contains only generated files.
2. Set owner/group explicitly on the two generated files; handle the top-level
   directory if necessary; remove recursive ownership changes only when safe.
3. Update installer fixtures to verify unrelated content remains untouched.

**Done when:** generated YAML remains readable by the intended application identity
with restrictive modes; repeated installation is safe; failures propagate;
unrelated fixture files keep their ownership/content; any production ownership
prerequisite is documented before activation.

**Review:** required; privileged activation and persistent-data permissions.
Do not perform a recursive ownership migration as a substitute.

## KISS-11 — Separate SSH policy from personal authorization

**Scope:** `modules/features/openssh.nix:15–20`, relevant user aspects/providers,
and `modules/users/admin/default.nix:14–15`.

**Steps:** move personal key contribution out of generic daemon policy using the
smallest Den user/context composition that preserves its exact targets. Reuse
the existing public-key file; do not introduce a fleet-wide authorization registry.

**Done when:** the operator key is present only on desktop/laptop `miko` and NAS
`admin`, not WSL or unrelated accounts; standalone scope is unchanged; key-only
authentication, root-login policy, and the restriction to declarative authorized-key
files remain intact; the existing key-scope regression passes.

**Review:** required; security and host/user routing.
Do not put the key unconditionally on global `miko` or all workstation users.

## KISS-12 — Remove the unused password-SSH aspect

**Scope:** `modules/features/openssh.nix:24–31`.

**Steps:** recheck repository consumers and any known external usage; remove only
`den.aspects.openssh-password`, whose legacy VM consumer was retired.

**Done when:** no current consumer is broken; all host SSH settings and key grants
match the baseline; checks pass; no replacement compatibility abstraction is added.

**Review:** required because the file defines security policy, even though this
specific removal is expected to leave current outputs unchanged.

## KISS-13 — Validate a loopback-only shared Hermes backend

**Type:** investigation first; optional subsequent implementation.
**Scope:** `modules/features/services/hermes-shared.nix:45,132–134`,
`docs/shared-hermes-nas.md:8–13`, and dashboard regression tests.

**Steps:**
1. Recheck pinned Hermes auth, HTTP Host/Origin, and WebSocket peer guards.
2. Confirm a loopback listener with the declared public URL preserves Basic Auth
   and authenticated remote access. Use a safe isolated test before proposing a
   production change.
3. If supported, propose consistent `127.0.0.1` CLI/environment binding and remove
   only the obsolete compatibility rationale.

**Done when:** the decision is recorded with pinned-source evidence and executed
checks; any implementation preserves authentication, signing-secret handling,
Traefik's trusted-network restriction, and the closed direct port. Live authenticated
browser/Desktop WebSockets through Traefik remain an explicit acceptance step for
an authorized deployment; source inspection alone does not satisfy that step.

**Review:** required; networking/authentication. Do not remove auth or open port 9119.

## KISS-14 — Decide whether ZFS import/scrub lists should share metadata

**Type:** policy clarification first; do not assume the lists must always match.
**Scope:** `modules/inventory.nix:15`, `modules/hosts/nas/hardware.nix:22`,
`modules/features/storage/zfs.nix:23`.

**Steps:** establish whether boot-imported and scrubbed pools intentionally share
one policy. If yes, reuse existing `host.zfs.pools` for NAS boot import; if not,
retain distinct declarations and briefly document why.

**Done when:** the policy decision is recorded; any consolidation evaluates to the
same imported/scrubbed pool lists; no pool/dataset properties or retention policy
change; no new schema/abstraction is introduced just to remove one literal.

**Review:** required for configuration changes; boot/storage are affected.
No ZFS commands, force imports, upgrades, expansion, or dataset provisioning.

## KISS-15 — Assess a native Homepage migration

**Type:** optional feasibility task, not an approved migration.
**Scope:** `modules/features/services/dashboard.nix` and pinned nixpkgs
`services.homepage-dashboard` implementation.

**Steps:** compare native and current container behavior: application version,
loopback widget access, secret substitution, allowed hosts, port/firewall,
identity, writable state, and ZFS mount safety. Decide whether the migration
actually reduces maintenance without losing required behavior.

**Done when:** a concise equivalence/gaps comparison and go/no-go decision exist.
If approved, create a separately scoped migration with rollback and artifact/runtime
checks. Do not remove the dataset or current installer on the basis of option names.

**Review:** required for any implementation; identity/storage/service structure change.

## Deliberately out of scope

- Replacing Den with host-first wiring or merging files merely to reduce file count.
- Removing `mountSafety`, mandatory route exposure choices, VPN lifecycle propagation,
  GPU recovery guards, or initialization ordering without equivalent guarantees.
- Changing fixed NAS identities, ZFS migration protections, datasets, or snapshot policy.
- Removing custom theme/Firefox behavior simply because it takes code to implement.
- Replacing the torrent/Prowlarr stack with native services without proving equivalent
  VPN isolation, runtime-secret provisioning, and database-backed API configuration.

## Historical verification baseline

These results are from the review of `15392b4`, not fresh checks of future changes:

- `just check` passed with a writable scratch runtime directory.
- All four NixOS toplevel derivations and standalone Home Manager activation evaluated.
- Full regression run: 105 tests; two failing workspace-shell subtests and two
  skipped Homepage artifact tests. The scratch-path fixture failure is KISS-01;
  permanently skipped artifact coverage is KISS-05.
- `just lint` failed on the empty argument pattern in `nas-hermes-terminal.nix:1`.
  `deadnix --fail .` passed separately.
- No full system closures were built or deployed; live NAS/proxy/GPU behavior was
  not verified. Do not infer runtime success from evaluation or mocked tests.
