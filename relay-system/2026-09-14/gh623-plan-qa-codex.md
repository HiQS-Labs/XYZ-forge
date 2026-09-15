---
Goal: Plan QA — GH-623 merge-cleanup resilience (soft edges, fetch retry, resume loop)
Date: 2026-09-14
NEXT: Reviewer
STATUS: Open
---

# Context

You are the plan reviewer for GH-623. The canonical plan is
`PROJECT/1-INBOX/GH-623-MERGE-CLEANUP-RESILIENCE.md` (committed at HEAD of this worktree).
The issue it implements: HiQS-Labs/XYZ-forge#623 — a /merge-cleanup run where one PR handoff
cascaded "NOT attempted" through collision-adjacent PRs, one DNS failure aborted the rest of
the queue, and the operator had to re-drive the run 4x.

Read the plan doc in full, then verify its claims against the actual code:
- skills/merge-cleanup/scripts/toposort_prs.py  (collision edges -> dep_graph -> `_deps`)
- skills/merge-cleanup/scripts/merge_cleanup.py (`land_prs` blocking, `prepare_landing_clone`, main's pre-queue + post-merge fetches)
- skills/merge-cleanup/scripts/attempt_record.py (reserve/finish, MAX_REPAIRS ceiling)
- skills/merge-cleanup/SKILL.md (Phase 5 dependents bullet, capability table, option list)
- test/gh534_phase_b_tests.py + test/gh534_phase_c_tests.py (fixture + pinned dependents-blocked test + TestParityGuard)
- test/gh436-merge-cleanup.py (toposort ordering tests)

## Operational envelope

Grade against the plan's stated requirements and commensurate complexity. Do NOT demand
unrequested machinery (circuit breakers, speculative frameworks, enterprise fail-safes) — the
plan's non-goals section is deliberate scope, not omission.

## Questions to adjudicate (cite file:line)

1. Grounding: is every code claim in the plan's Problem Statement true of the actual sources?
   Name any wrong line reference or overstated claim.
2. Requirement coverage: does the design satisfy the issue's acceptance bullets
   (hard/soft split, 3x-backoff retry + defer-and-continue, --resume, SKILL.md drive loop +
   Done rule + classifier-retry)? Are the two deliberate non-deferral sites the right call —
   pre-queue fetch exhaustion still refuses (R2-1 stale-verdict guard) and post-merge fetch
   exhaustion still stops (reconciliation is gating)?
3. Pinned guarantees: does the hard/soft split keep
   `test_dependent_of_a_handed_off_pr_is_not_attempted_and_an_independent_pr_proceeds` green
   (it uses an explicit "Depends on #2" annotation)? Does defer-and-continue preserve the E
   guarantee (a PR whose state is unknown is never merged) and the exit-code shape (0/2/3)?
4. Resume safety: can `--resume` as designed ever bypass the two-repair ceiling, given reserve()
   re-checks budget under the lock? Is "unreadable record -> warn and proceed" acceptable when
   reserve() still gates?
5. Blast radius: name any consumer of toposort output or `_deps` the plan missed (note:
   `utils/py/_marathon_plan.py::_deps_of` is a different, unrelated function).
6. Red controls: would each new test in the plan's test scope actually fail on the current
   code? Is the test footprint commensurate with the change?

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete.

Write your verdict below and change the STATUS to Approved/Closed if it passes.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
