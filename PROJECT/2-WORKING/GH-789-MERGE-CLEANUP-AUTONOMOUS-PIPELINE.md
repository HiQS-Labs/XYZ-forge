---
title: "GH-789 (+ GH-965): merge-cleanup bounded repairs — port of the approved phase-one implementation"
status: In Progress
gh_issue: 789
source: https://github.com/HiQS-Labs/XYZ-forge/issues/789
doc_type: enhancement
created: 2026-09-24
updated: 2026-10-05
owner: operator
goal: "merge-cleanup stops less on mechanical cases: drafts are skipped (not a failed landing), additive CHANGELOG conflicts resolve inside B1, and a stale REBASE_HEAD no longer blocks the primary."
branch: fix/gh789-merge-cleanup-repairs
complexity: 3
risk: 3
effort: 3
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Port planned onto `development` `442ea913`; trial three-way apply sized the conflicts (2 files). | Codex plan QA, then port, verify, final QA, PR. |

## Why this is a port

The original phase-one implementation was built and Codex-approved on 2026-09-24 in clone `XYZ-forge-gh789`
(branch `fix/gh789-gh786-merge-cleanup`, head `08bb0655`, base `f1321d6d`):
`relay-drive: attest RELAY-GH789-FINAL-R3 approved by codex (reviewed df6a1f126656)`. It was never published:
its full gate failed 416/417 on an upstream inventory ratchet (`github_labels.py`, from #723), not on its own
code, and the clone then sat unpushed. `/merge-cleanup-deep` (2026-10-05) found it PR-WORTHY: `union_changelog`,
`read_changelog_union` and `prepare_primary_landing` have 0 hits on `development`, and #789 is open with no PR.
The clone is backed up at `_backups/XYZ-forge/2026-10-05_085604/zips/XYZ-forge-gh789.zip`; its full original
plan, recon (`recon-gh789.md`) and relay threads are in that commit history.

**Still needed now (recurrence, 2026-10-04):** merge-cleanup handed off PR #930 on
`code/doc conflict outside the ledger set: CHANGELOG.md` (an additive changelog conflict), and stopped a whole
run on draft PR #948 (`GraphQL: Pull Request is still a draft`) — filed as #965, which this port also closes.

## Scope (phase one only)

Port the three approved behaviours from `08bb0655` (diff `f1321d6d..08bb0655 -- skills/2-daily/merge-cleanup/`):

1. **Drafts (GH-789 item 2 + #965).** `toposort_prs.fetch_open_prs` and `merge_cleanup.refresh_pr` request
   `isDraft`. A live draft is `SKIPPED (draft)` before repair or merge, rechecked after UNKNOWN polling, after a
   B1 refresh and before a repaired-head push (`ledger_merge` refuses to push a repaired head for a draft or
   closed PR). A draft is a non-landed **hard** predecessor (explicit dependents wait; soft/independent PRs
   continue). A run whose only non-landings are drafts is a success; drafts are named in one
   `Skipped draft PR(s): …` summary line. Never marks a PR ready.
   **Added for #965:** the Phase 4 sequence table gets a `Draft` column (`toposort_prs.py` table render).
2. **CHANGELOG in B1 (GH-789 item 3).** `ledger_merge.union_changelog` / `read_changelog_union` accept only
   newly prepended complete `## YYYY-MM-DD …` blocks on both sides of a unique merge base, with identical preamble
   and unchanged base history; exact duplicate blocks deduplicate; divergent same-heading bodies, fenced/HTML
   additions, conflict markers, empty input or a base edit hand off. Classified before any mutation; staged in the
   existing B1 commit; downstream second-clone validation and gates unchanged.
3. **Stale REBASE_HEAD (GH-789 item 1).** `scan_clones.inspect_primary_landing` distinguishes a lone
   `REBASE_HEAD` from a real `rebase-merge`/`rebase-apply`/sequencer operation (paths via `git rev-parse --git-path`).
   Only in execute landing/reconcile mode, after all other readiness checks pass, `prepare_primary_landing`
   deletes a stale one with compare-and-delete (`git update-ref -d REBASE_HEAD <observed-oid>`) and re-inspects.
   Audit modes never prune.

**Conflict resolution against today's `development`** (from the trial apply):
- `merge_cleanup.py`: keep dev's `PUSH_GATE_TIMEOUT_S` constant; keep dev's GH-851 post-push head wait **and**
  add the port's post-repair draft recheck after it; add the port's pre-repair draft skip next to dev's hold-label skip.
- `SKILL.md`: keep dev's capability rows; add the port's draft and CHANGELOG prose but **not** its two new
  capability rows (they name tests that GH-831 forbids adding; the parity guard requires a named test per row).

## Non-goals

GH-786 phase two (batch records) — plan-only in the old clone, stays queued on #786. No new tests or capability
rows (GH-831). No changelog support for repos without a ledger. No auto-ready of drafts. GH-785 (hold-label
dependency gap) stays separate. No change to repair budgets, the attempt record or hosted reconcile.

## Verification (no new suites — GH-831)

- **Existing suites, in a disposable full clone** with pre/post identity checks: `test/gh436-merge-cleanup.sh`
  (includes `gh534_phase_b/c` and the parity guard) must stay green; the push route will run the full gate
  (merge-cleanup is a core skill).
- **Manual matrix** `TESTS-RESULTS/2026-10-05+GH-789/manual_matrix.py` (evidence script, not registered, same
  pattern as GH-898): real-git fixtures for (a) changelog-only additive → resolved, (b) ledger + changelog →
  resolved, (c) base-history edit → handoff, (d) divergent same heading → handoff, (e) empty/marker input →
  handoff; (f) draft PR in a mocked queue → skipped, zero merge calls, independent PR lands, hard dependent waits,
  exit 0; (g) lone REBASE_HEAD → cleaned in execute mode, untouched in dry run; real `rebase-merge` dir → refused.
  Each case asserts on non-empty extracted data.
- **Red controls:** run the matrix against unported `development` (drafts and changelog cases must fail), and
  with `union_changelog` forced to accept a base edit (case c must fail).
- Live check (operator, optional): `merge_cleanup.py --prs-only` shows the Draft column on today's queue.

## Risk

**Costly** (merge automation writes PR heads; a wrong changelog classification could drop release notes).
Shield: classification before mutation, hand off on anything ambiguous, existing second-clone validation and
guarded push. Rollback: revert the PR commit. Blast radius: merge-cleanup only (`scan_clones`, `toposort_prs`,
`merge_cleanup`, `ledger_merge`); `merge-cleanup-deep` consumes `scan_clones --json` — the REBASE_HEAD change
only adds fields, so its intake is unaffected (checked in final QA).

## Rating (2026-10-05)

GH-789 `rated 75/70/50/50`: severity 70 — work-blocking landing stops (whole run stopped on a draft; CHANGELOG
handoffs), recoverable, no data loss; priority 75 — recurs each batch (2026-10-04: #930 handoff, #948 stop; Sep:
GH-555/623/624/736 same tool); appeal 50 neutral; effort 50 — port of approved code with two conflicts, not new
design (the 2026-09-24 proposal had 65 for a fresh build). GH-965 `rated 60/50/50/85`: the draft stop alone,
fully covered by item 1.
