---
gh_issue: 1193
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1193
title: "merge-cleanup: --retire-published-pr refuses start-task's sibling task clones when the primary is outside DEFAULT_SAFE_ROOTS"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-24
doc_type: bugfix
complexity: 1
risk: 2
effort: 1
phases: 1
---

# GH-1193 — `--retire-published-pr` refuses sibling task clones outside DEFAULT_SAFE_ROOTS

`merge_cleanup.py --retire-published-pr` (GH-1059, start-task Step 9) checks every `--checkout`
against the four hard-coded `DEFAULT_SAFE_ROOTS` in
`skills/2-daily/merge-cleanup/scripts/scan_clones.py`. start-task's GH-970 rule puts task clones
and their `-gate`/`-verify` helpers next to the primary clone, so on a machine whose primary is
`~/Documents/GitHub-Repos/XYZ-forge` the mode refuses everything start-task creates
(`Refusing: path is not strictly within SAFE_ROOTS`). Seen 2026-10-24 closing out PR #1190.

## Asks

- For published-PR retirement only, also accept the `--primary` clone's parent folder as a safe
  root, unless that parent is a `NEVER_DELETE` root (`~`, `~/Documents`, `~/Desktop`, …).
- Keep every other fail-closed check (absolute non-symlink checkout, not the primary or its
  ancestor, same origin, live published-PR head proof, fresh re-inspection, NEVER_DELETE).

## Acceptance

- [ ] The PR #1190 preview command no longer refuses on SAFE_ROOTS.
- [ ] A primary whose parent is a NEVER_DELETE root does not widen the roots.
- [ ] `DEFAULT_SAFE_ROOTS` and WORKTREE-SAFETY.md §16.1 stay identical (parity test green);
      the derived root is documented beside the list.
- [ ] No new tests (GH-831); existing merge-cleanup suites stay green.

Related: #722 (same root cause in the default audit scan; stays open), #1059, #970.
