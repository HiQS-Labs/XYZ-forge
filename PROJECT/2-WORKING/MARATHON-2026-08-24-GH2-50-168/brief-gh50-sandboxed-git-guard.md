---
title: Lane brief — GH-50: guard sandboxed git branch mutations before they half-apply
status: Active (2-WORKING)
created: 2026-08-24
updated: 2026-08-24
owner: noel
branch: development
doc_type: project
roadmap_exempt: true
goal: >
  Lane brief for marathon phase gh50-sandboxed-git-guard.
---

# Lane brief — GH-50: guard sandboxed git branch mutations before they half-apply

## Status

| What was just completed | What's next |
|---|---|
| Brief authored. | Phase execution. |

Execution surface of record: `PROJECT/2-WORKING/GH-50-SANDBOXED-GIT-HALF-APPLY.md`
(issue: https://github.com/HiQS-Labs/XYZ-forge/issues/50)

## Task

Inside a sandbox that blocks `.git/config` writes, `git switch --track` updates the index and
working tree, then fails the config write and leaves HEAD behind — the tree holds another
branch's content while HEAD points at the old branch (an uncommitted modification to
`test/ballast-release.sh` was lost this way). The fatal line
(`error: could not lock config file .git/config: Operation not permitted`) is easy to
truncate away; the visible symptom is only a misleading upstream hint.

1. `utils/git-sandbox-guard.sh` (new): a preflight primitive that probes `.git/config`
   writability and refuses tracking/branch-mutation operations up front with a named error,
   for harness scripts that switch branches (relay/marathon drivers).
2. Adopt the guard at the harness call sites that perform `switch --track` / `branch -D`.
3. `test/gh50-sandboxed-git-guard.sh` (new): simulate a read-only `.git/config` and assert the
   guard refuses before any tree mutation; register in validate.sh TESTS.
4. `AGENTS.md`: one-paragraph note naming the failure shape (do not truncate git stderr on
   branch operations).

## Definition of done

- With `.git/config` unwritable, a guarded `switch --track` refuses with a named error before
  any tree mutation.
- The working tree is byte-identical to its pre-attempt state after the refusal.
- `test/gh50-sandboxed-git-guard.sh` green and registered in validate.sh.
- `bash validate.sh` green.
