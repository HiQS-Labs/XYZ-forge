---
gh_issue: 1480
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1480
title: "refactor: decompose merge-cleanup entry point and landing loop after #1475"
status: "Held 2026-11-27 (1-INBOX): blocked by #1475, not enqueued, not started"
created: 2026-11-27
updated: 2026-11-27
owner: Conveyor preparation (Flywheel Run A held item; ledger #1658)
doc_type: refactor
ratings_provisional: true
non_goals:
  - Any build contract before #1475 closes (Conveyor: a held item gets no pretend build contract)
  - A competing branch against the lines #1475 still owns
goal: >
  After the #1475 remediation lane lands, split merge_cleanup.py main() and _land_prs_loop() into
  typed, behavior-preserving stages (issue #1480). Held until then.
---

# GH-1480 · Decompose merge-cleanup entry point and landing loop (held)

**HELD:** Blocked by #1475 (open) and its implementation PR, as the issue body records ("Blocked on https://github.com/HiQS-Labs/XYZ-forge/issues/1475 and its implementation PR. Do not create a competing branch against the same lines."). Released only when #1475 closes; the owner of that release is the #1475 lane or the operator.

## Status

| What was just completed | What's next |
|---|---|
| Held capture and PRS row prepared 2026-11-27 at `6142128d9c43` so Jog refuses admission before the lease (`hold_refusal`). No build contract, no implementation, no queue admission. | Stays held until #1475 closes. Then a full Conveyor preparation (recon, Preflight Contract with `prepared_commit`, review) replaces this held capture. |

## Acceptance (from the issue, for the later build)

- [ ] `merge_cleanup.py` `main()` and `_land_prs_loop()` are split into typed, behavior-preserving stages, extending the static-analysis baseline of the first modernization PR.
- [ ] Pinned heads, merge/gate behavior, recovery state, batch records and all exit codes are preserved.
- [ ] Verified with existing merge-cleanup suites and recorded main/resume smoke comparisons; no new suite.

## Recon note (parent-only)

- **Baseline:** `origin/development` at `6142128d9c433d6b12972c6cd9a6f864f0ed9da2` (2026-11-27).
- **Prerequisite:** #1475 is OPEN. Its Phase 1 (PR 1478) and Phase 2A (PR #1490) landed; Phase 2B and Phase 3 remain in scope (`PROJECT/2-WORKING/GH-1475-MERGE-CLEANUP-REMEDIATION.md`, roadmap row "In progress"), and they edit the same `merge_cleanup.py` landing code this refactor would split.
- **Why held, not prepared:** the dependency is recorded in the issue body by its author, not invented here. A build contract now would be grounded at lines #1475 is still changing, so it would go stale and would compete with that lane.
- **Admission behavior:** Jog's `hold_refusal` (`utils/py/jog_run.py`, GH-1476) reads this capture through Kickstart's `issue_hold_reason`; the `HELD:` line above (and "Blocked by #1475") refuses before the lease with `hold: capture body HELD: marker`. The issue body's "Blocked on <URL>" wording alone does not match the recognizer, which is why the hold is restated here.
- **Next owner:** the #1475 lane (close #1475), then Conveyor for a full preparation.

## Attempt and retry history (read 2026-11-27, nothing reset)

- No `roadmap_items` row, no `jog_queue` row, no capture, no branch or PR for #1480 before this preparation. Attempts consumed: 0.

## Rating rationale

`rated 70/65/50/40` (sum 225): the issue's own rating proposal, written through `roadmap pickup` on 2026-11-27; `ratings_provisional` stays true until the operator confirms. Effort 40: a substantial multi-checkpoint refactor.

## Merge evidence

- PR #1675 merged 2026-11-27 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
