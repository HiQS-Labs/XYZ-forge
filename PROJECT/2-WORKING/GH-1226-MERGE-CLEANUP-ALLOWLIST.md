---
gh_issue: 1226
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1226
title: "merge-cleanup --execute lands PRs opened after the dry run (denylist, not allowlist) and merges with checks pending"
status: Active
created: 2026-10-26
updated: 2026-10-27
owner: claude
doc_type: bugfix
complexity: 3
risk: 3
effort: 3
phases: 1
non_goals:
  - Unbounded waiting on CI inside the run (pending required checks are polled, bounded, then deferred)
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
| Implemented the `--prs` allowlist, dry-run head pins (record or inline `N@sha`), a bounded required-check gate, `--match-head-commit` with pinned-head confirmation, and the merged ⊆ list assertion. Consolidated #1231. Kimi K3 and Agy reviewed it; smoke is green (`TESTS-RESULTS/2026-10-26+GH-1226/`). | Run the qualifying macOS full gate, then merge PR #1227 to `development`; after merge the reconciler closes the doc. |

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

## Bet check (pre-consolidation; superseded in part by the 2026-10-27 consolidation below)

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

## Plan QA (2026-10-26)

Codex relay is unavailable in this cloud session; the plan was reviewed by an independent
fresh-context Claude reviewer instead. Verdict: Approved with changes. Dispositions:

- Merge-time live head == pin (covers B1 heads whose checks are not registered yet): **Accepted.**
- Unknown/unreadable check output defers, never proceeds: **Accepted.**
- Per-PR refresh instead of list discovery (30-item default limit): **Accepted in part** —
  `gh pr list --limit 1000` + `headRefOid`, one call instead of N.
- Dry run must apply the `--prs` deferral: **Accepted**; a dry run without `--prs` stays a full preview.
- GH-1066 count / resume compare / group batch on listed PRs only: **Accepted** (early block filters to pins).
- Persist the allowlist through the batch save merge and render it for 2+ batches: **Accepted**
  (`allowlist` + `_allowlist_touched`).
- Separate count for check/pin deferrals: **Accepted.**
- Stacked retargeting keeps covering unlisted PRs: **Accepted** (commented in code).
- Sanitize `/` in the pin filename: **Accepted.**
- Suite edits in shared helpers; repurpose the two exclude-PR pins; parity guard row + `--prs`: **Accepted.**

## Lessons Learned

- A denylist chosen at execute time cannot bound a run: whatever opens between preview and
  execute is in scope. Pin the vetted set at preview and refuse on drift.

## Consolidation with PR #1231 (2026-10-27)

PR #1231 implemented the same issue in parallel. At the operator's request, #1227 now carries the
strengths of both. #1227 keeps:
- the record-file pin;
- deferral, not a stop, when a head moves mid-run;
- `--match-head-commit`, with the pinned-head check on both merge-confirmation paths;
- the required-only checks gate;
- `--limit 1000` discovery.

From #1231 it adopts:
- inline `--prs N@sha` pins, which need no record;
- the printed `Pinned for --execute` line;
- the bounded wait for pending checks (`MERGE_CLEANUP_CHECKS_WAIT_S` / `_POLL_S`), applied to required checks only;
- unit coverage of the parser, the pin verifier, the checks reader and the merge confirmation, now in `TestGh1226AllowlistHelpers` in the existing suite.

#1231 checked *any* running check and stopped on a moved head. #1227 keeps the issue's required-check
scope and defers a moved head, so the rest of the queue continues.
