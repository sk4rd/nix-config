# Agent operations

Read this before an authorized deployment, commit, or push. This document does
not grant authorization: each operation needs explicit user instruction in the
current conversation, limited to the requested scope. Follow `AGENTS.md` for
architecture, verification, review, and safety requirements.

## Deployment

- Identify the target host and exact change scope. Never deploy a mixed dirty
  checkout: isolate the requested changes in a clean worktree or otherwise
  ensure unrelated pending changes are excluded. “Deploy” does not mean
  “deploy everything in the worktree.”
- Read the relevant [installation and recovery procedure](installation-and-recovery.md)
  when installation, recovery, boot enrollment, or secrets bootstrap is involved.
- Run the required evaluation, build, and secret-manifest checks; inspect the
  rendered artifacts and state any missing runtime prerequisites before switching.
- After switching, verify the active generation and the specific service/config
  effect on the target. Report partial activation accurately.

## Commit

- Review the full diff and stage only the changes in the requested scope.
  Preserve unrelated user staging and working-tree changes.
- When asked for multiple commits, split them into small, coherent commits in
  logical dependency order and verify each commit's contents.
- Never commit plaintext credentials, private keys, or decrypted SOPS data.

## Push

- A commit or deployment request does not authorize a push.
- Confirm the intended remote, branch, and outgoing commits match the requested
  scope before pushing; do not include unrelated commits.

Tool permissions and approval prompts remain separate from user authorization.
Do not use destructive Git commands without explicit authorization for that
exact operation.
