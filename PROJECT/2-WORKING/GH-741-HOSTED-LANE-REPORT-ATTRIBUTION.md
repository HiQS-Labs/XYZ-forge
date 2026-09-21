---
gh_issue: 741
source: https://github.com/HiQS-Labs/XYZ-forge/issues/741
title: "hosted_lane_report.py blames the last 'wave-reconcile: ERROR' line — on a --qualify run that is a unit test's expected output (#735 named 'invalid merged_at timestamp'; the run failed on the push step)"
status: In progress
updated: 2026-09-21
created: 2026-09-21
owner: Claude Code (start-task, one group with GH-740)
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
phases: 1
non_goals:
  - changing what makes the lane red (job.status stays the verdict); this issue is attribution only
related:
  - GH-740-HOSTED-LANE-PUSH-RACE.md
goal: >
  TODO: one-paragraph statement of what "done" looks like for this idea.
---

## Key concepts

- `hosted_lane_report.py` picks `errors[-1]` from the tee'd reconcile log; on `--qualify` runs that log holds the whole test suite's output
- #735 blamed `invalid merged_at timestamp` — gh421's fixture, followed by `ok`; the run failed on the push step
- Fix: attribute by step outcome (`steps.reconcile.outcome`, `steps.publish.outcome`), not by last line
- Canonical plan, acceptance and ordering: [GH-740-HOSTED-LANE-PUSH-RACE.md](GH-740-HOSTED-LANE-PUSH-RACE.md) (one group, one PR)

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# hosted_lane_report.py blames the last 'wave-reconcile: ERROR' line — on a --qualify run that is a unit test's expected output (#735 named 'invalid merged_at timestamp'; the run failed on the push step)

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-09-21 from radar run 4; promoted into the GH-740 group plan the same day; rated `70/55/50/80`. | Implement step 1 of the group plan (`terminal_error()` + gh684 cases), then ride the shared PR. |

## Idea

Sub-issue of umbrella #591 · radar run 4 target `RADAR-class-hosted-reconcile-lane` (#293).

## What happened

#735 (auto-filed by `utils/py/hosted_lane_report.py` for run [35623940059](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/35623940059)) reported:

> Terminal error: `Malformed merged-PR recovery response: invalid merged_at timestamp`

That line exists in the log, but it is **not the run's failure**. In the tee'd `reconcile.log` it appears at 17:21:59Z inside the qualification's unit-test output and is immediately followed by `ok`:

```
wave-reconcile: ERROR — Malformed merged-PR recovery response: pull request lacks merged_at or base.ref
wave-reconcile: ERROR — Malformed merged-PR recovery response: invalid merged_at timestamp
ok
```

`test/gh421-auto-wave-reconcile.sh`'s Python cases exercise `wave_reconcile.py:1210/:1229` on purpose, and the driver prints its error prefix to the shared stream. The `Reconcile merged PR or catch up` step **succeeded**. The job went red in the *next* step, `Commit declared artifacts and push`, on a non-fast-forward `git push` (sibling issue filed for that race). `summarize()` (`hosted_lane_report.py:53-57`) takes `errors[-1]` over every line of the log, so on any `--qualify` run — i.e. every PR-closed run — the "terminal error" is whichever test printed last, and the real cause (a different step, not tee'd) is invisible. An operator reading #735 would go fix `merged_at` parsing; radar run 4 nearly recorded it as a new failure class.

The same log, under `--log-failed`, also *echoes* the push step's script source (`raise SystemExit('Refusing undeclared reconciliation artifacts: …')`), which reads like a refusal and is not one.

## Fix shape (surgical; one of these, not both)
- Separate the driver's own diagnostics from qualification output: `wave_reconcile.py` writes its `ERROR —` / `Refusing` / `SKIP` lines to a dedicated file (or a distinct prefix such as `wave-reconcile[driver]:`) that the tests' subprocesses do not share, and `--log` points there; **or**
- make the report step aware of *which step failed* (`steps.<id>.outcome`) and, when the reconcile step is green, report the failing step's name and its `git` error instead of scanning the reconcile log at all.

Keep the self-closing behaviour and the single labelled issue (GH-684) unchanged.

## Acceptance
- Replaying run 35623940059's `reconcile.log` with `job.status=failure` and reconcile-step outcome `success` through `hosted_lane_report.py` yields a body naming the push-step failure (`[rejected] … (fetch first)`), **not** `invalid merged_at timestamp`.
- Red control: a green reconcile log containing test-emitted `wave-reconcile: ERROR —` lines with `job.status=success` yields no issue (today's `summarize()` still finds an "error" there).
- A genuine reconcile-step `die(...)` is still reported verbatim as the terminal error.

## Why

TODO: why this matters now -- what prompted it, what breaks or slows without it.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
