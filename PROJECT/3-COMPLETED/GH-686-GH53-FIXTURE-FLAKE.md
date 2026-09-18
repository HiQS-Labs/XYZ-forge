---
gh_issue: 686
source: https://github.com/HiQS-Labs/XYZ-forge/issues/686
title: "test/gh53-releases-merge-resolve.sh is a coin-flip: the fixture's union keeps two 'generation' settings rows when the sides straddle a second boundary"
status: Complete
created: 2026-09-18
updated: 2026-09-18
owner: operator (fresh-clone PR lane, shared with GH-684)
goal: >
  test/gh53-releases-merge-resolve.sh passes deterministically: the fixture keeps one settings row per key
  and exercises the second-boundary shape every run; the resolver's refusal is unchanged.
doc_type: bugfix
branch: fix/gh684-hosted-reconcile-lane
shares_pr_with: [684]
plan: PROJECT/2-WORKING/GH-684-HOSTED-RECONCILE-LANE.md
---

# GH-686 — gh53 fixture flake (shares the GH-684 PR; plan item S3)

## Status

| What was just completed | What's next |
|---|---|
| Fix landed on the shared branch (S3 of the GH-684 plan): `union_dump` keeps one `settings` row per key, `mk_diverged` forces the second boundary, the fixture asserts distinct timestamps; resolver comment names the row. Disposable-clone evidence: 10/10 green at the PR head; base `ba1f58e8` 33/40 (7 red) witnessed; dedupe-only revert deterministically red. | PR review (final Codex relay QA) → merge. |

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

## Merge evidence

- (recorded at landing)

## Lessons Learned (For Future Agents)

- **A byte-level dedupe is not a per-key dedupe.** `settings` is one row per key and every write stamps `updated_at`; two sides that wrote the same `generation` value in different seconds are two different lines. The union procedure must know the schema's uniqueness, not just the file's text.
- **A flaky gate suite is a lane outage in disguise.** One 17 % coin-flip in a 393-suite gate that must be 100 % green fails roughly one full run in six — locally, in `/express`, and in the hosted qualification — and each hosted failure cost an hour of macOS runner time before it was even noticed.
- **Make the racy shape deterministic, then assert it.** `sleep 1.1` alone would have fixed the symptom by accident; the fixture now asserts the two timestamps differ before unioning, so the control cannot quietly degrade back to luck.
