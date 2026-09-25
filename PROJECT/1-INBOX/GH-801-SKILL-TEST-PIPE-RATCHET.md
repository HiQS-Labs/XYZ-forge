---
title: GH-801 — GH-798 skill tests violate pipe-to-grep ratchet
status: Parked
created: 2026-09-24
updated: 2026-09-24
owner: noel
gh_issue: 801
goal: Restore full-gate eligibility without weakening the pipe-to-grep or skill severity controls.
doc_type: bugfix
effort: 1
complexity: 1
risk: 2
---

## Status

| What was just completed | What's next |
|---|---|
| Observed and attributed full-gate blocker to GH-798; separate issue filed | Held for separate work; replace ten pipeline sites, verify controls and full gate before resuming GH-796 |

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/801.

`test/gh139-pipe-grep-guard.sh` reports that `test/gh798-status-skill.sh` grew from zero to ten prohibited pipeline sites. Source and ratchet baseline are identical on development `a08f30e9` and merge candidate `0852e43c`; introduction is `e9a0420d` (GH-798), not PR #794. Focused GH-798 evidence alone did not establish the full gate. The combined full run completed 419/420 with only this failure and unchanged clone identity. Independent pristine-development reproduction fails; pre-GH-798 `337813e0` passes 3/3.

Evidence: `TESTS-RESULTS/2026-09-24+GH-796/gh801-pipe-ratchet-red.log` and committed provenance. Reproduce only in a disposable full clone: `bash test/gh139-pipe-grep-guard.sh`.

## Acceptance criteria

- [ ] Use existing capture-then-match convention for the ten new sites; do not expand the baseline.
- [ ] GH-139 and GH-798 suites pass with severity negative controls preserved.
- [ ] Full macOS gate passes on the final candidate in an isolated full clone.

## Rating and scope

2026-09-24: rated 80/75/50/90. Blocks the merge workflow with a directly observed deterministic check failure; appeal neutral; ten mechanical replacements are inexpensive. Existing GH-139 and GH-788 history show recurrence of this shape, but no exhaustive frequency comparison was performed (trend unknown). No data loss or observed intermittent SIGPIPE is claimed. This capture authorizes no implementation: operator requested unrelated discoveries be ticketed and held.
