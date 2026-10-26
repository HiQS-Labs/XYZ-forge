---
gh_issue: 1226
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1226
title: "merge-cleanup --execute lands PRs opened after the dry run (denylist, not allowlist) and merges with checks pending"
status: Active
created: 2026-10-26
updated: 2026-10-26
owner: claude
doc_type: bugfix
complexity: 3
risk: 3
effort: 3
phases: 1
non_goals:
  - Waiting on CI inside the run (a pending check defers the PR; the operator re-runs)
  - New test suites or registry entries (GH-831)
  - Changing teardown, reconcile, or retire-published-pr behaviour
goal: >
  merge-cleanup takes a bounded PR allowlist at the start of the process and can never merge a PR
  outside it, never merges a PR whose head moved since the dry run, and never merges while a
  required check is pending.
---

## Key concepts

- `--prs` allowlist, required for any merging `--execute`
- Dry run pins listed PR heads; execute refuses on drift
- Required checks must be green at merge time

# merge-cleanup PR allowlist and required-check gate

## Status

| What was just completed | What's next |
|---|---|
| Captured GH-1226 with the operator's scope comment; recon traced Phase 4 selection and the Phase 5 merge loop. | Implement `--prs` + head pins + required-check gate in `merge_cleanup.py`, update the existing suites that pinned `--exclude <PR#>`, smoke the dry-run → execute path. |

## Problem (observed)

`merge_cleanup.py` picks PRs at `--execute` time from `gh pr list --state open`, minus a
`--exclude <PR#>` denylist. A PR opened between the dry run and the execute is sequenced and merged
without vetting. The merge loop never consults required checks, so a B1 ledger repair pushes a new
head and merges it while that head's checks are still pending (BinoidCBD/LTVera-Pandas batch #842:
#841 landed unvetted, before "pytest db fast" finished).

## Requirements (issue + operator comment)

1. `--prs 783,811` is required for any run that merges. Without it `--execute` refuses; teardown-only,
   scan-only, prs-only and reconcile modes still run.
2. The dry run records the listed PRs and their head SHAs. `--execute` refuses if a listed PR's head
   moved, or it closed or went draft, since then. It never adds an unlisted PR.
3. Unlisted open PRs log `not in --prs; not sequenced` and are never merged; B1 repair pushes only
   touch listed PRs.
4. After the run assert merged ⊆ list; record the list in the batch issue.
5. `--exclude` filters checkouts/teardown only. SKILL.md example 6 is updated.
6. Refuse to merge while required checks are pending.

## Plan

Extends the existing writer (`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`) and record root
(`.tick/merge-cleanup/<slug>/`, the attempt-record coordinator). No new module.

1. `--prs` (comma list, repeatable). A merging `--execute` without it exits 2 before any mutation.
2. Dry run with `--prs`: every listed PR must be open and not a draft in Phase 4 discovery; pin
   `{pr: headRefOid}` to `.tick/merge-cleanup/<slug>/selection-<integration>.json`.
3. Execute (in the pre-mutation checkpoint block): load the pin; refuse if missing, if `--prs` names a
   PR the pin does not, or if any listed PR is no longer open, is a draft, or has a different head.
   `--prs` may narrow the pinned set (drop landed PRs on `--resume`) but never widen it.
4. Phase 4 sequences all open PRs for dependency edges, then defers every unlisted PR and,
   transitively, any listed PR with a hard dependency on one (reusing the checkpoint deferral loop).
   PR-number `--exclude` filtering is removed.
5. Before each merge: `gh pr checks <n> --required --json name,bucket`. pending → defer (exit 3);
   fail/cancel → not merged; "no required checks reported" → proceed. A B1-repaired head is therefore
   deferred until its checks finish; re-run the dry run to re-pin, then `--execute`.
6. Track merged PRs in the run; after Phase 5 refuse (exit 2) if any is outside `--prs`. The batch
   issue renders the pinned list.
7. SKILL.md: document `--prs`, the pin, the check gate; rewrite example 6; update the
   `exclude-drops-pr` table row and CLI option list.

Verification: existing suites `test/gh436-merge-cleanup.py`, `test/gh534_phase_{a,b,c}_tests.py`
(edited only where they pinned the old denylist / un-gated execute), plus a manual smoke receipt
under `TESTS-RESULTS/2026-10-26+GH-1226/`.

Rollback: revert the PR; no schema or ledger format change. The pin file is untracked `.tick/` state.

## Bet check

- Outcome sought: nothing outside the operator's vetted list ever lands; nothing lands on red/pending CI.
- Smallest bet: one flag, one JSON pin, one `gh pr checks` call. No CI wait loop.
- Alternative rejected: pin SHAs inside the flag (`--prs 783@sha`) — the operator asked for the dry
  run to record them; a file pin keeps the two commands identical.
- Containment: refusals all happen before the first mutation; revert restores old behaviour.

## Rating (2026-10-26)

`rated 85/85/50/45` (pri/sev/appeal/effort). Severity: unvetted code (25 files) merged to the
integration branch ahead of its required check — a work-integrity failure needing manual revert or
audit. Priority follows severity plus the operator's explicit scoping. Recurrence: one incident in the
last 14 days (LTVera-Pandas batch #842); prior 14 days unknown. Appeal neutral. Effort: one script plus
existing-suite edits.
