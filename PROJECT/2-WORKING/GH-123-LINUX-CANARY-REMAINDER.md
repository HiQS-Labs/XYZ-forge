---
title: "GH-123: Linux portability canary — remaining failure: gh358 lock contention on shared runners"
status: Active
created: 2026-08-24
updated: 2026-08-27
owner: orchestrator (Claude Code)
goal: the last live GH-123 assertion failure (gh358 lock instrumentation under shared-runner CPU load) passes deterministically on the hosted Ubuntu canary
gh_issue: 123
source: https://github.com/HiQS-Labs/XYZ-forge/issues/123
branch: gh-123/linux-canary-remainder
doc_type: bugfix
effort: 2
complexity: 2
risk: 2
release: 0.7.4 Linux-RC (dialed in 2026-08-24, mfi-01M0V6HCYDY36TSAEYSEB8QA64)
related:
  - "#224 — Linux MVP RC umbrella (Phase 2 exit item)"
  - "#209 — external PR resolves 3/5 of the original GH-123 suites (gh103, gh69, gh382); ShellCheck shebangs also resolved"
non_goals:
  - Re-fixing the four GH-123 suites already resolved on development or in PR #209
  - Changing lock semantics for real (non-test) drivers
---

# GH-123 — Linux canary remainder: gh358 lock contention

## Status

| What was just completed | What's next |
|---|---|
| root cause isolated to the writer's lock bound and fixed on `fix/gh123-lock-contention`; new `test/gh123-lock-progress-bound.sh` makes the race deterministic (6 pass; 3 fail against the pre-fix tree) | reviewer weighs the non-goal deviation below, then the hosted Ubuntu canary in #224 Phase 3 confirms the contention half |

Isolated per Agy's empirical review on #224 (2026-08-24): of the 7 failing assertions across
5 suites in the original canary run, only `test/gh358-lock-instrumentation.sh` remains —
CI-runner lock contention under shared CPU load. The rest are fixed on `development` or land
with PR #209.

## Plan

1. Reproduce the gh358 failure shape under constrained CPU (hosted Ubuntu canary logs from the
   GH-123 run are the evidence base).
2. Fix inside the suite/harness seam: tune `XYZ_LOCK_WAIT_S` for the instrumented path or add
   bounded lock retry under contention — deterministic, no sleeps-as-sync.
3. Assert the tuned path in `test/gh358-lock-instrumentation.sh` itself (no new suite unless a
   separate regression shape emerges).

## Acceptance

- [ ] `test/gh358-lock-instrumentation.sh` passes on the hosted Ubuntu canary runner (qualifying run linked in #224 Phase 3). — NOT yet confirmable: the contention does not reproduce on a 4-core dev box, where gh358 already passes.
- [ ] No remaining open assertion failures attributed to GH-123. — pending the same hosted run.
- [x] Existing lock suites stay green (`gh358-lock-instrumentation.sh`, `xyz-completion.sh`, `registry-lock-concurrency.sh`, `gh14-atomic-append.sh`).

## Acceptance — deviations from the plan

- [changed] `## Plan` step 2 scoped the fix to "the suite/harness seam" and `non_goals` excluded
  "Changing lock semantics for real (non-test) drivers". The fix instead lands in
  `utils/telemetry/append-xyz-completion.sh`, the real writer. — reason: the defect IS the writer's
  bound semantics. `XYZ_LOCK_WAIT_S` is documented as the wait for the lock, but was implemented as
  a single wall-clock deadline covering the entire queue. With 16 concurrent appenders on a throttled
  runner the queue is long but MOVING, and writers past the deadline exit 75 reporting starvation for
  a system that is merely slow. Tuning the value in the test seam cannot fix that conflation, and
  cannot be done anyway: `test/xyz-completion.sh` mirrors the 30s default and
  `test/gh358-lock-instrumentation.sh` asserts `test wait=60s` and `(default=30s)` verbatim, so
  changing any default breaks the suite this issue exists to fix.
- [blast radius] Real-driver behavior changes in exactly one direction: a writer that previously gave
  up at `XYZ_LOCK_WAIT_S` while the lock was actively changing hands now keeps waiting, bounded by
  `XYZ_LOCK_TOTAL_MAX_S` (default `4 × XYZ_LOCK_WAIT_S` = 120s). A stuck holder is unaffected — it
  still exits 75 at exactly `XYZ_LOCK_WAIT_S`, asserted by case A of the new suite. No default changes.
- [added] `test/gh123-lock-progress-bound.sh`, registered in validate.sh. — reason: `## Plan` step 3
  allows a new suite when "a separate regression shape emerges". It did: the CI failure is a race that
  does not reproduce on an idle box, so the regression is pinned by driving the lock directly
  (held vs. changing hands) rather than by reproducing CPU starvation.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "grep_absent", "path": "test/gh358-lock-instrumentation.sh", "pattern": "GH-123 canary tuning" } ],
  "artifacts":     [ "test/gh358-lock-instrumentation.sh" ],
  "artifacts_new": [],
  "remediation":   { "source": "self#plan", "criteria": "gh358 suite deterministic under shared-runner CPU load; hosted Ubuntu canary green" },
  "lanes":         { "agy_safe": [ "test/gh358-lock-instrumentation.sh" ], "orchestrator_only": [ "relay-automation/", ".tick/" ] }
}
```
