---
gh_issue: 3
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/3
title: Parked-claim threshold is a false-positive for autonomous agents (long atomic tool calls)
status: Shipped (2026-07-03 — Plan A lane 2, PR pending)
created: 2026-07-03
updated: 2026-07-03
owner: noel
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
related:
  - src/analyze.js
  - test/analyze.sh
  - test/heartbeat.sh
non_goals:
  - No git/filesystem mtime signal (issue fix 3) — the parked detector is deliberately events-only (reads only `.tick/events/`, no git author/timestamp dependency); a git dependency would break its portability. Deferred.
  - No DISQUALIFIES→WARN semantic change on completed claims (issue fix 4) — bigger blast radius (changes what `watchdog.sh` reaps on + reworks `heartbeat.sh`'s intent). Deferred as a follow-up if the events-only fix proves insufficient.
---

# GH-3 · Parked-claim threshold false-positive for autonomous agents

## Status

| Most recently completed | What's next |
|---|---|
| **✅ SHIPPED (Plan A lane 2).** `tick analyze`'s parked-claim detector (`src/analyze.js`) flagged a fully-active 90%-concurrency run as parked because its liveness signal was **`task.heartbeat` only** and the fixed **10-min** threshold is human-paced — an autonomous subagent in one long atomic tool call can't interleave a `tick ping`, so it looked parked. Fixed (events-only, least-code): **(2)** liveness is now **any `task.*` event from the agent** (claim/scope_changed/commented/ping/done), and **(1)** the threshold is operator-tunable via **`TICK_PARKED_THRESHOLD_MS`** (default unchanged at 10 min). `parked_suspects` shape/semantics unchanged (safe for `watchdog.sh` reap + `poll.sh`); a new `activity` count is added alongside `heartbeats`. `test/heartbeat.sh` +3 (scope_changed = liveness; env override raises + suppresses the flag); existing `heartbeat`/`chaos-midturn-kill`/`watchdog-liveness` green. | Merge PR. (3)/(4) — git-mtime signal + DISQUALIFIES→WARN — deferred (see non_goals). |

## Problem

`tick analyze` reported **2 parked-claim suspects → "DISQUALIFIES run"** on a run where both agents worked continuously (5 files + 17 passing tests). The detector fires when an agent shows no `task.heartbeat` for > 10 min within a claim window. That threshold is calibrated for human-paced windows; an autonomous subagent's single tool call ("write the module, then run `node --test`") can run > 10 min with **no yield point to `tick ping`**, so a fully-active agent looks parked. A false positive on a hard gate trains operators to ignore it — defeating its purpose (Guiding Principle #10 "Done means verified", #8 "Honest").

## Design (events-only, least code)

Two additive changes to `findParkedClaims` in `src/analyze.js`, keeping the detector's "reads only `.tick/events/` — no git" invariant:

1. **Broaden the liveness signal (issue fix 2).** Activity points become the claim open, the window close, **and every `task.*` event the agent emitted for that task inside the window** — not just `task.heartbeat`. A `task.scope_changed`, a `task.commented`, a mid-window re-claim ping: all prove the agent is alive. The truest events-only proxy for "work happening." The reported `heartbeats` count stays the real `task.heartbeat` count (for the human message); a new `activity` count reports total liveness points.
2. **Operator-tunable threshold (issue fix 1).** `TICK_PARKED_THRESHOLD_MS` env override (default unchanged, 10 min) so an autonomous-agent marathon can set e.g. 20–30 min without a code change.

Both are safe for the live consumers (`watchdog.sh` reap, `poll.sh` count): the `parked_suspects` **shape and semantics are unchanged** — a suspect is still "a window with an activity gap over the threshold"; the gap is just measured against a truer, tunable signal. Existing tests (`heartbeat.sh` TASK-2, `chaos-midturn-kill.sh` TASK-KILL) stay green because those gaps contain genuinely zero intermediate agent events.

## QA gate

- [x] `test/heartbeat.sh`: a window where the agent emits a **non-heartbeat** `task.*` event (`scope_changed`) inside an otherwise-heartbeat-less 18-min window is **NOT** flagged parked (proves fix 2).
- [x] `TICK_PARKED_THRESHOLD_MS` override: a 15-min-gap window is flagged at the default but **not** when the threshold is raised to 30 min (proves fix 1).
- [x] Existing `heartbeat.sh` (TASK-2 parked) and `chaos-midturn-kill.sh` (TASK-KILL parked) stay green — no false-negative regression on genuinely idle/orphaned claims.
- [x] `validate.sh` green (85/85).
