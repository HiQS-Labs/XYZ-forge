---
title: "GH-123: Linux portability canary — remaining failure: gh358 lock contention on shared runners"
status: Active
created: 2026-08-24
updated: 2026-08-24
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
| capture doc + preflight contract written; dialed into 0.7.4 Linux-RC | Operator fires the marathon lane; builder executes ## Plan, reviewer verifies ## Acceptance |

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

- [ ] `test/gh358-lock-instrumentation.sh` passes on the hosted Ubuntu canary runner (qualifying run linked in #224 Phase 3).
- [ ] No remaining open assertion failures attributed to GH-123.
- [ ] Lock behavior for real drivers unchanged (existing lock suites stay green).

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
