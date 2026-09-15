---
Goal: Final QA — GH-623 implementation (soft edges, fetch retry, resume loop)
Date: 2026-09-14
NEXT: Reviewer
STATUS: Open
---

# Context

You are the FINAL implementation reviewer for GH-623. The approved plan is
`PROJECT/1-INBOX/GH-623-MERGE-CLEANUP-RESILIENCE.md` (Codex plan QA passed in 4 rounds —
see `relay-system/2026-09-14/gh623-plan-qa-codex.md`). The implementation is committed at HEAD
of this worktree (commits after the approval record): red controls + implementation + SKILL.md
+ CHANGELOG. The issue: HiQS-Labs/XYZ-forge#623.

Read: the plan, then the diff surface —
- skills/merge-cleanup/scripts/toposort_prs.py  (hard/soft edges, FetchError, bounded discovery)
- skills/merge-cleanup/scripts/scan_clones.py   (run_git additive timeout, default unbounded)
- skills/merge-cleanup/scripts/merge_cleanup.py (_transient/_retry_call/_net_git, defer-and-continue, refresh/discovery retry, --resume, exit-2 discovery refusal)
- skills/merge-cleanup/SKILL.md                 (drive loop, Done rule, classifier retry, parity rows)
- test/gh534_phase_b_tests.py                   (stub: files passthrough, view_fail/list_fail injectors)
- test/gh534_phase_c_tests.py                   (TestGh623Resilience + updated parity control)

Evidence so far: 13 red controls failed on pre-change code; after the change the full
merge-cleanup unit suite is 156/156 green (`bash test/gh436-merge-cleanup.sh`), including
TestParityGuard with the three new capability rows.

## Operational envelope

Grade against the approved plan's stated requirements and commensurate complexity. Do NOT
demand unrequested machinery — the plan's non-goals (no circuit breaker, B1 second-clone/push
stay unbounded, /unstuck self-trigger rejected) are deliberate scope.

## Questions to adjudicate (cite file:line)

1. Per-issue acceptance: does each of the issue's five acceptance bullets have committed
   code + a test that would fail without it (a) soft edges never block, (b) bounded calls +
   3x transient retry + defer-and-continue, (c) `--resume` skips landed/parked, (d) SKILL.md
   drive loop + Done rule, (e) classifier-block retry guidance?
2. Codepath fidelity: does the implementation match the approved plan's design section —
   including the round-3 reordering (refresh BEFORE the exhausted-record skip), the exact
   retry contract (3 calls, sleeps [2,4]), `_deps` kept as union, and the two deliberate
   non-deferral sites (pre-queue refusal with `--allow-unready-primary` unchanged; post-merge
   stop)?
3. Duplicates/writers: did any parallel subsystem or second writer slip in? Is `_deps` still
   serialized for `toposort_prs.py --json` consumers?
4. Checks: do the tests substantiate the claims — would each new control catch a regression
   of the behavior it pins? Is any assertion vacuous or empty-input-passing?
5. SKILL.md: do the new sections contradict any code behavior (parity guard aside)? Is the
   Done rule consistent with `--prs-only`/`--scan-only` legitimate uses?

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete.

Write your verdict below and change the STATUS to Approved/Closed if it passes.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
