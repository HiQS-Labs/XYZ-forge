---
gh_issue: 93
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/93
title: "tick analyze: concurrency % spans the whole event log, not the run → reports 0% for a ~51% run"
status: Ready — promoted for Marathon Plan B Wave 1 (2026-07-04)
created: 2026-07-04
updated: 2026-07-04
owner: noel
doc_type: bugfix
goal: >
  Default tick analyze's printed concurrency percentage to the work-bounded window (first
  task.claimed -> last task.done), matching SKILL.md's existing prescribed metric, instead of the
  whole .tick/events/ log span — so a genuinely good, path-disjoint parallel run doesn't misreport
  as a failure because leftover events from a prior marathon widened the span.
complexity: 1
risk: 2
effort: 2
phases: 1
roadmap_exempt: false
non_goals:
  - Not building a tick archive / run-scoping mechanism for .tick/events/ (the issue's root-cause
    option 4) — that's a bigger, separate lift; this fix addresses the reporting-scope bug directly,
    which the issue itself says is the actual defect ("a reporting-scope bug, not a coordination bug").
  - Not adding a --since/--run CLI flag (option 2) — the work-bounded default (option 1) needs no
    new surface and directly matches what SKILL.md already tells operators to expect.
related:
  - src/analyze.js
  - bin/tick
  - test/analyze.js
---

## Status

| What was just completed | What's next |
|---|---|
| Promoted from GitHub issue capture, root cause confirmed against the live code (`src/analyze.js:435-438,442`). Not yet built. | Compute the work-bounded window, use it for the concurrency percentage, keep the whole-log span as a separate informational field, extend `test/analyze.js`, `validate.sh` green, close #93. |

## Problem (grounded in the current code)

`analyze()` (`src/analyze.js:394`) builds `window.earliest_event`/`window.latest_event` from the
**entire** sorted timestamp array of every event in `.tick/events/` (line 435-438):

```js
const eventTs = events.map(e => e.ts).sort();
// ...
earliest_event: eventTs[0] || null,
latest_event: eventTs[eventTs.length - 1] || null,
```

That whole-log span is then passed **directly** as the run window to `computeParallelism` (line 442:
`computeParallelism(windows, window.earliest_event, window.latest_event)`), which is what the
printed `concurrent_pct` is derived from. `.tick/events/` accumulates across every run with no
run-scoping, so leftover events from a prior marathon (hours or days old) widen `earliest_event`
far outside the actual run, collapsing the ratio toward 0% regardless of how concurrent the real
run was — confirmed live: a run that was actually ~51% work-bounded printed 0% because stale events
stretched the span to ~273 hours.

`SKILL.md` already documents the correct metric ("recompute work-bounded: first `claimed` → last
`done`") — but `src/analyze.js` never computes that window; it only has the whole-log span. The tool
and its own documentation disagree today.

## Fix

Compute a **work-bounded window** from the `task.*` events already available in `analyze()` (line
399 `events`, filtered to `task.*` types):

```js
const claimTs = events.filter(e => e.type === 'task.claimed').map(e => e.ts).sort();
const doneTs   = events.filter(e => e.type === 'task.done').map(e => e.ts).sort();
const workBoundStart = claimTs[0] || null;
const workBoundEnd   = doneTs[doneTs.length - 1] || null;
```

Pass `workBoundStart`/`workBoundEnd` to `computeParallelism` instead of the whole-log
`earliest_event`/`latest_event` — this is the number `concurrent_pct` and the PASS/FAIL verdict gate
(line 211-213, 221-222) key off. Keep `earliest_event`/`latest_event` in the report's `window` object
as-is (the whole-log span stays visible, informational) alongside the new work-bounded fields, so an
operator can see both and the discrepancy is never hidden — this also satisfies the issue's "at
minimum, caveat + work-bounded number alongside the raw one" fallback option as a side effect of the
main fix, at no extra cost.

If there is no `task.claimed` or no `task.done` event yet (a run still in progress, or a log with no
task activity), fall back to today's whole-log behavior for that edge case rather than computing a
window from a missing timestamp — `computeParallelism` already returns `null`/not-computable
gracefully when given no meaningful window (existing behavior, unchanged).

## Definition of done

- [ ] `analyze()`'s work-bounded window (first `task.claimed` → last `task.done`) replaces the
  whole-log span as the input to `computeParallelism` / `concurrent_pct` / the concurrency verdict
  gate.
- [ ] The report's `window` object keeps `earliest_event`/`latest_event` (whole-log, informational)
  **and** adds the new work-bounded start/end, both visible in text and JSON output.
- [ ] `test/analyze.js` gets a fixture: events spanning a wide whole-log range but a narrow, highly
  concurrent `claimed`→`done` window — asserts the printed percentage reflects the narrow window,
  not the wide one (the exact regression this issue reports).
- [ ] `bash validate.sh` green.

## Reversibility & blast radius

**Low.** Pure function-internal change to `analyze()`'s window computation; no event schema change,
no new `tick` verb, no change to how events are written — only how the existing `task.claimed`/
`task.done` events already in the log are read back for one derived statistic. Every other report
field is unaffected.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/analyze.js",
  "fix_probes": [
    { "type": "grep_absent", "path": "src/analyze.js", "pattern": "GH-93" }
  ],
  "artifacts": [
    "src/analyze.js",
    "test/analyze.js"
  ],
  "remediation": "In src/analyze.js's analyze() function, compute a work-bounded window from the first task.claimed event and the last task.done event (both already available in the task.*-filtered events array), and pass that window to computeParallelism() instead of the whole-log earliest_event/latest_event span. Keep earliest_event/latest_event in the report's window object as an informational field alongside the new work-bounded start/end -- do not remove them. Fall back to the existing whole-log behavior when there is no task.claimed or no task.done event yet. Add a test/analyze.js fixture with a wide whole-log span but a narrow, highly-concurrent claimed-to-done window, asserting the printed percentage reflects the narrow window. GH-93 marker comment near the fix.",
  "lanes": {
    "agy_safe": ["src/analyze.js", "test/analyze.js"],
    "orchestrator_only": [],
    "note": "Independent leaf lane (src/analyze.js, not bin/tick or the projection kernel). May also touch bin/tick's analyze dispatch if report fields need surfacing there -- if so, keep that touch additive-only (new fields, no removed/renamed ones). Parallel-safe with any other Wave 1 lane in Marathon Plan B; shares no file with #96 (which touches src/take.js, a different src/*.js file)."
  }
}
```

## Provenance

Found hands-on across two real marathons — the core coordination (atomic claims, heartbeats,
path-disjoint lanes) worked correctly; this is a reporting-scope bug, not a coordination bug.
Promoted to `2-WORKING` 2026-07-04 as part of Marathon Plan B Wave 1 (the 5 lanes cleared for firing
after #23/#61 removal and Plan A confirmation — see
[MARATHON-PLAN-2026-07-03-B-PARALLEL.md](MARATHON-PLAN-2026-07-03-B-PARALLEL.md)).
