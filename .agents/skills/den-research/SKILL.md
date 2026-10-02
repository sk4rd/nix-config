---
name: den-research
description: "Use when Den, flake-parts, or NixOS/Home Manager framework behavior is unclear. Verify against the pinned implementation and primary docs; do not edit files."
---

# Den and Nix framework research

Use this skill when an implementation depends on an unfamiliar or version-sensitive Den, flake-parts, NixOS, or Home Manager API.

1. Read the relevant repository aspects, inventory, and `flake.lock` first.
2. Check the pinned dependency source from this checkout before relying on remembered APIs or current upstream docs.
3. Prefer primary documentation, then pinned source when docs are silent or ambiguous.
4. Separate documented behavior, behavior inferred from source, and recommendation.
5. Check for existing Den batteries, context dispatch, providers, and composition patterns before proposing new plumbing.
6. Do not edit repository files or change dependencies.
7. Return only the findings needed to unblock implementation, with source paths/links and version context.
