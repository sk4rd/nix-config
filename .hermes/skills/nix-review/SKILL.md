---
name: nix-review
description: "Use when an independent review is required or requested for a Nix/Den change. Review the scoped diff for substantive correctness and architecture issues; do not edit files."
---

# Nix and Den change review

Review the task-specific diff and relevant dependencies supplied by the parent. Do not modify files. Exclude unrelated pre-existing changes unless they interact with the task.

Evaluate, in order:

1. Correctness and Nix module semantics.
2. Den architecture: reusable aspects, correct host/user scope, thin profiles, inventory limited to entity declarations, and composition through `includes` when appropriate.
3. Reuse of existing Den batteries and repository patterns.
4. Unnecessary complexity and whether the change respects `AGENTS.md`.
5. Whether verification actually covers the changed behavior and intended host/user scope.

Run only read-only inspection and safe checks explicitly authorized by the parent. Never deploy, commit, push, or perform destructive Git operations.

Report only substantive findings. For each finding, state the issue, why it matters, and the smallest reasonable correction. If there are no substantive findings, say so explicitly.
