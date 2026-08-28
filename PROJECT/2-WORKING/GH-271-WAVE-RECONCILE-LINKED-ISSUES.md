---
title: "wave_reconcile.py: linked-issue extraction is mention-greedy; rollback leaves regenerated artifacts behind"
status: Active
created: 2026-08-26
updated: 2026-08-26
owner: orchestrator (Claude Code)
gh_issue: 271
source: https://github.com/HiQS-Labs/XYZ-forge/issues/271
doc_type: bugfix
effort: 2
complexity: 2
risk: 2
phases: 1
related:
  - "GH-202 — open-issue doc stays active by design; extraction feeds that decision"
  - "GH-168 — prior rollback hardening (pre-existing state)"
  - "GH-220 — exit-code whitelist fix (shipped); this issue is the rollback remainder"
goal: >
  Make extract_linked_issues honor GitHub closing-keyword semantics so prose mentions stop
  acting as links, and make rollback's completeness claim verifiable (porcelain-empty assert).
---

# GH-271 · wave_reconcile: closing-keyword extraction + rollback completeness

## Status

| What was just completed | What's next |
|---|---|
| Implementation + QA complete: Agy relay rounds 1-2 findings implemented (URL-fragment lookbehind pinned; gh202 31/0); full validate.sh green 283/283 | PR into development (fix/gh271-273-quick-wins); merge closes the issue |

Spun off from the #260 assessment (improvement items 2 and 3). Both defects live in
`utils/py/wave_reconcile.py` and ship as one fix.

## Part A — mention-greedy linked-issue extraction

`extract_linked_issues()` (utils/py/wave_reconcile.py:271) runs `\b[Gg][Hh]-([0-9]{1,6})\b`
over the entire PR title+body, so every prose `GH-N` mention becomes a "linked" issue the
reconciler acts on (ROADMAP entry moves, PROJECT/2-WORKING doc relocation). Observed
2026-08-23 on PR #185: body yielded `[18, 141, 156, 174, 180, 181, 183, 184, 430, 509]`,
including two live active lanes.

Fix:

- closing-keyword-only extraction (`close/closes/closed/fix/fixes/fixed/resolve/resolves/resolved`, case-insensitive)
- `#`/`GH-` prefix mandatory — bare "closes 5 issues" must not match
- comma lists supported ("Closes #1, #2, fixes GH-3")
- `GH-N` accepted behind a keyword (repo convention; PRs merge into `development` so the
  reconciler parses rather than relying on GitHub auto-close)
- title trailer tags (`(#123)` / `(GH-123)` at title end) stay linked — title only, never body
- fenced code blocks in the body ignored

## Part B — rollback claims completeness it does not have

`rollback()` (utils/py/wave_reconcile.py:90) unlinks `created_files` and restores `backups`,
but subprocess-generated outputs the journal never tracked escaped it: a failed 2026-08-23 run
left regenerated dashboards and a stray `MARATHON-PLAN-<date>.md` after reporting success.

Fix: after restore, assert `git status --porcelain` clean via the existing
`check_porcelain_cleanliness` helper; on leftovers, name them and exit nonzero. Pin with a test.

## Verification

- `bash test/gh202-wave-reconcile-issue-state.sh` (extended) green
- Full `./validate.sh` green
