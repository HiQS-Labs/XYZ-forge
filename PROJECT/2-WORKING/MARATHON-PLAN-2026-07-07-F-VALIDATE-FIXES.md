---
title: Marathon Plan F (2026-07-07) — validate.sh's 9 pre-existing failing tests
status: Ready to fire (2-WORKING) — doc authored + rated, not yet fired
created: 2026-07-07
updated: 2026-07-07
owner: noel
branch: main
doc_type: project
source: triaged 2026-07-07 during GH-158/161/162/164 housekeeping pass, when validate.sh's
  pre-existing 9 failures were confirmed (again) to be unrelated to that day's merges
generated_by: hand-authored (9 lanes under one umbrella issue, same-day triage, not ledger-ranked;
  Lane 10 added same day after live-reviewing GH-171's fix)
lanes: [170, 174]
execution: parallel Sonnet subagents, one per lane — independent write-sets, no builder/reviewer
  relay needed for any single lane
roadmap_exempt: true
goal: >
  Nine independent lanes, one per currently-failing validate.sh gate, all tracked under a single
  umbrella issue (#170) since none were substantial enough alone to warrant their own GH issue, but
  collectively are 9 real, independent, parallel-safe fixes. Two (analyze.sh, relay-token-
  collision.sh) are confirmed flaky and need multi-run verification, not just one green pass; the
  other seven are deterministic single- or few-assertion bugs in unrelated files. Lane 10 (#174) was
  added the same day: a Bash/Python parity gap found while reviewing GH-171's fix live — agy-turn.py
  never got the claim-before-launch guard agy-turn.sh just gained.
---

# Marathon Plan F — 2026-07-07 · validate.sh's 9 pre-existing failing tests

> Sibling of [Plan D](MARATHON-PLAN-2026-07-07-D-EXPLORE-IDEAS.md) and
> [Plan E](MARATHON-PLAN-2026-07-07-E-BUILD.md), but a different shape: all 10 lanes here fix
> **pre-existing test failures / coverage gaps**, not new features — the deliverable per lane is a
> passing `test/<file>.sh` plus (for the two flaky lanes) proof across repeated runs, not just one.
> Lanes 1-9 came from same-day triage of `validate.sh`'s red gates; Lane 10 was added same day after
> live-reviewing a real production fix (GH-171) surfaced a Bash/Python parity gap.

## Status

| What was just completed | What's next |
|---|---|
| All 9 failures triaged 2026-07-07 to concrete failure signatures, filed under umbrella issue [#170](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/170), doc authored with a fix direction per lane. Separately, GH-171 (a real production no-progress bug, found live in sleuth-app's marathon) was root-caused and fixed same day (branch `fix/gh-171-chain-root-cause`, commit `b00ee48`, independently verified: 60/0 on `test/marathon-drive.sh` incl. its new GH-171 regression, zero regressions across `codex-turn`/`agy-turn`/`aider-turn`/`claude-turn`) — reviewing it surfaced one parity gap, filed as [#174](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/174) and added here as Lane 10. Nothing in this plan's 10 lanes is fixed yet. | Fire all 10 lanes in parallel — each is scoped to its own test file (+ whatever source file its root cause turns out to live in), no shared write-set between any two. |

## Why this cluster, why now

`validate.sh` has carried these 9 red gates for a while — confirmed pre-existing via two
independent checks today (a parent-commit worktree comparison during the GH-165 review, and a
`git stash` comparison during the GH-158/161/162/164 housekeeping pass). None are urgent/blocking
anything, but they've been accumulating as untracked debt with no issue or plan behind them. This
plan captures and rates all 9 in one pass so they can be picked up as a normal marathon cluster
instead of staying invisible.

## The one safety rule

Two lanes are safe to run concurrently **iff their write-sets are disjoint**. Each lane here targets
a different, unrelated test file and (as far as triage could tell without doing the actual fix) a
different source area — see the collision map below.

## Collision map

| Zone (shared file) | Parallel-safe? | Lane |
|---|---|---|
| `test/analyze.sh` (+ its source) | ✅ only one lane touches this | Lane 1 |
| `test/cost.sh` (+ its source) | ✅ only one lane touches this | Lane 2 |
| `test/watchdog-relay.sh` (+ its source) | ✅ only one lane touches this | Lane 3 |
| `test/deep-research.sh` (+ its fixture) | ✅ only one lane touches this | Lane 4 |
| `test/relay-token-collision.sh` (+ its fixture) | ✅ only one lane touches this | Lane 5 |
| `test/new-relay.sh` (+ its source/assertion) | ✅ only one lane touches this | Lane 6 |
| `test/find-harness.sh` (+ its source) | ✅ only one lane touches this | Lane 7 |
| `test/transcript-audit.sh` (+ its source) | ✅ only one lane touches this | Lane 8 |
| `test/marathon-plan.sh` (+ `utils/marathon-plan.sh`) | ✅ only one lane touches this | Lane 9 |
| `utils/py/agy-turn.py` (+ its test) | ✅ only one lane touches this | Lane 10 |
| independent | ✅ parallel | all 10 — no shared file between any two |

Lanes 1-9 touch no kernel file at all. **Lane 10 is the one exception to "no kernel" in this plan**:
it edits `utils/py/agy-turn.py`, which is a turn-taker shim (zone `shim`, not `kernel` — it doesn't
touch `relay-turn-lib.sh`/`bin/tick` themselves), but it should still run alone relative to any
*other* agy-turn-touching work if one ever gets added to this plan later.

## Per-lane summary

| # | Test file | Symptom | Class | cx/risk/eff |
|---|-----------|---------|-------|-------------|
| 1 | `test/analyze.sh` | SIGPIPE flake, same family as GH-133 | flaky | 2/1/1 |
| 2 | `test/cost.sh` | cost-only agent leaks into `agents[]` | deterministic | 2/1/2 |
| 3 | `test/watchdog-relay.sh` | self-generated analysis JSON malformed | deterministic | 2/2/2 |
| 4 | `test/deep-research.sh` | fixture missing `searchContextSize` | deterministic | 1/1/1 |
| 5 | `test/relay-token-collision.sh` | fixture task-name collision | flaky | 2/1/2 |
| 6 | `test/new-relay.sh` | possible stale assertion vs. real template | deterministic | 1/1/1 |
| 7 | `test/find-harness.sh` | 2 failures, possible env-sensitivity | deterministic | 2/2/2 |
| 8 | `test/transcript-audit.sh` | stale-ref output/assertion mismatch | deterministic | 1/1/1 |
| 9 | `test/marathon-plan.sh` | 4 assertions, 1 shared root cause in "B:" scenario | deterministic | 2/2/2 |
| 10 | `utils/py/agy-turn.py` (+ test) | Python agy port missing GH-171's new claim-before-launch guard | deterministic (parity gap) | 2/1/2 |

Full diagnostic detail (exact failure output, fix direction per lane) lives in
[GH-170's doc](../1-INBOX/GH-170-VALIDATE-FAILING-TESTS.md#findings-2026-07-07-triage) for Lanes
1-9, and [GH-174's doc](../1-INBOX/GH-174-AGY-PY-CLAIM-GUARD.md) for Lane 10 — each lane should
read its own section before starting.

## Recommended waves

**Wave 1 — parallel (10 lanes ‖):** Lane 1 ‖ Lane 2 ‖ Lane 3 ‖ Lane 4 ‖ Lane 5 ‖ Lane 6 ‖ Lane 7 ‖
Lane 8 ‖ Lane 9 ‖ Lane 10

No kernel track. No lane blocks another.

## Execution contract

- **Path:** each lane fires as a worktree-isolated Sonnet subagent, scoped via `ALLOW_PATHS` to its
  own test file plus whatever source file its root cause turns out to live in (triage identified
  the symptom, not always the exact source line — the lane's first job is to finish that
  root-cause).
- **Per lane:** root-cause the failure, land the fix with the test passing, and leave a one-line
  status update in this doc's own Status table (or the umbrella GH-170 doc's Status table).
- **Lanes 1 and 5 (flaky) must verify across at least 5 repeated runs, not one green pass** — a
  single pass does not confirm a flake is fixed.
- **Lane 9 must check whether its fix interacts with the already-shipped GH-150 `docOf()` fix** in
  the same file (`utils/marathon-plan.sh`) — confirm it's an adjacent gap, not a partial
  reintroduction of GH-150's original bug.
- **Lane 7 must first confirm environment-sensitivity vs. a real bug** — if the failure only
  reproduces because of this device's local vendored `.xyz/` state, the actual bug is the test's
  fixture isolation, not the detection logic it's testing.
- **Lane 6 must diff the assertion's expected string against actual current output before changing
  anything** — confirm test drift vs. real regression first.
- **Rated:** all 10 lanes carry provisional cx/risk/eff (`ratings_provisional: true` in both source
  docs) — same-day triage/discovery, not yet validated against `pdda.sh doc-ready`.
- **Lane 10 is a direct port of an already-verified pattern**, not new design — mirror
  `utils/py/codex-turn.py`'s existing claim-before-launch logic (itself already fixed for GH-171's
  tick-bin resolution) into `utils/py/agy-turn.py`, and extend the GH-171 vendored-consumer
  regression fixture in `test/marathon-drive.sh` to cover it under `XYZ_PYTHON=1`.

## How to fire

```
utils/swarm-preflight.sh --gh-issue 170 --project-doc PROJECT/1-INBOX/GH-170-VALIDATE-FAILING-TESTS.md
utils/swarm-preflight.sh --gh-issue 174 --project-doc PROJECT/1-INBOX/GH-174-AGY-PY-CLAIM-GUARD.md
   → ready packet (candidate/freshness/fix-still-required + lane assignment)
relay-automation/marathon-drive.sh ...   # build→gate→review, contained, one invocation per lane
```

After all 10 land: re-run full `validate.sh` and confirm 104/104 (or document any gate still red
with a reason, same discipline as every other marathon in this repo).

---

*Source docs:* [GH-170](../1-INBOX/GH-170-VALIDATE-FAILING-TESTS.md) ·
[GH-174](../1-INBOX/GH-174-AGY-PY-CLAIM-GUARD.md) ·
siblings: [Plan D](MARATHON-PLAN-2026-07-07-D-EXPLORE-IDEAS.md) ·
[Plan E](MARATHON-PLAN-2026-07-07-E-BUILD.md).
