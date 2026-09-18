---
gh_issue: 686
source: https://github.com/HiQS-Labs/XYZ-forge/issues/686
title: "test/gh53-releases-merge-resolve.sh is a coin-flip: the fixture's union keeps two 'generation' settings rows when the sides straddle a second boundary"
status: Proposed (1-INBOX — not yet active)
created: 2026-09-18
doc_type: bugfix
branch: fix/gh684-hosted-reconcile-lane
shares_pr_with: [684]
plan: PROJECT/1-INBOX/GH-684-HOSTED-RECONCILE-LANE.md
---

# GH-686 — gh53 fixture flake (shares the GH-684 PR; plan item S3)

## Capture

`bash test/gh53-releases-merge-resolve.sh` fails about one run in two at the same commit (`FAIL pass` at `55d8ab47`, `4af5bcfc`, `ba1f58e8`; 2026-09-18) with `refused: rule=dump-duplicate-setting: settings key 'generation' appears more than once`. The fixture's `union_dump` keeps one `-- generation:` header and dedupes every other line byte-for-byte; each side's `settings` row `('generation', '2', <updated_at>)` differs by one second whenever the two `releases add` calls straddle a wall-clock second, so both rows survive and the resolver refuses — correctly. Reproduced by hand (side A `02:46:59Z`, side B `02:47:00Z`, same value).

It was the one red suite (392/393) in the hosted wave-reconcile qualification on 2026-09-18 01:41Z, and it makes every full `validate.sh` (local pre-push, `/express`, hosted `--qualify`) a coin-flip.

## Requirements (→ GH-684 plan, item S3)

- Fixture keeps one `settings` row per key (for `generation`: higher value, then later `updated_at`), the same way it keeps one header.
- The previously flaky shape (sides across a second boundary) is exercised deterministically every run.
- The resolver's procedure comment names the row as well as the header.
- The resolver's refusal is **not** changed — it is the correct signal.
- Acceptance: 10/10 green in a disposable clone at the PR head; ≥1 red witnessed in the same loop at the base.

## RELEASES rating (2026-09-18)

`rated 70/70/50/85` — **pri 70**: it is the current blocker of the hosted qualification and randomly fails every full gate on the machine. **sev 70**: work-blocking (false-red gates, wasted hour-long hosted runs), no data loss, recoverable by re-running. **appeal 50**: neutral. **effort 85**: a few fixture lines and a comment. Recurrence: 3 of 6 local runs red on 2026-09-18; hosted 2026-09-18 01:41Z; earlier hosted "validate.sh --sequential returned non-zero" failures (09-13→09-16) not attributed to this suite — unknown, not assumed.
