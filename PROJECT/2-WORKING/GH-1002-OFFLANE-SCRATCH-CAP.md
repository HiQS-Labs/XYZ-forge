---
gh_issue: 1002
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1002
title: "agy builder repeatedly writes probe scripts off-lane; one stray test_*.mjs discards a converging phase and burns the attempt cap"
status: In Progress
updated: 2026-10-08
owner: operator
goal: "Incidental builder scratch costs a warning, not a phase; a capped lane parks without a commit."
created: 2026-10-08
doc_type: bugfix
related:
  - PROJECT/2-WORKING/GH-1001-VENDORED-HARNESS-ROOT.md
effort: 2
complexity: 2
risk: 2
phases: 1
---

# GH-1002 — builder scratch probes fail the turn and burn the lane attempt cap

## Status

| What was just completed | What's next |
|---|---|
| Recon verified; intake rated 65/65/50/55; shared plan written (B1–B4). | Codex plan QA. |

Shared plan lives in [`GH-1001-VENDORED-HARNESS-ROOT.md`](GH-1001-VENDORED-HARNESS-ROOT.md) (one branch/PR, both touch
`utils/py/marathon_drive.py`).

## Asks (from the issue, refined by recon)

- Obvious untracked builder scratch (e.g. `test-satori.mjs`, `tools/spike/test_satori.mjs`) is relocated
  and reported in worktree mode instead of failing the whole turn with exit 6. Tracked-file edits and
  non-scratch creations still fail (GH-22 backstop unchanged).
- A lane that is at its attempt cap parks without first adding a relay-file commit.
- Dry-run shows the lane's attempts versus its cap.
- Containment failures keep counting toward the cap (GH-45); the issue's "don't count them" option is
  rejected because an outer re-fire loop would become unbounded.
