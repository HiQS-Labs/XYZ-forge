---
gh_issue: 813
source: https://github.com/HiQS-Labs/XYZ-forge/issues/813
title: "harness_app init_db: concurrent first-use races on PRAGMA journal_mode=WAL"
status: In progress
created: 2026-09-25
updated: 2026-09-25
owner: claude
phases: 1
doc_type: bugfix
goal: Concurrent first use of a fresh harness telemetry DB never fails on the WAL switch, and the gh496 concurrency case explains its own failures.
---

# GH-813 — harness_app init_db WAL race

## Status

| What was just completed | What's next |
|---|---|
| Recon and a falsified prototype: all 33 failures in 200 rounds were the WAL pragma; bounded retry took failures from 30/200 to 0/200. | Codex plan review, then implement Phase 1. |

## Problem (observed)

Ten `harness_app.py log` processes against a **fresh** DB (the `test/gh496-telemetry-isolation.sh` concurrency case #9) sometimes lose a worker with `sqlite3.OperationalError: database is locked`, raised at `utils/py/harness_app.py:171`, `conn.execute("PRAGMA journal_mode = WAL;")`, inside `init_db`. Seen as #800 M4 Pro trial 3, a full-gate refusal at `0ae3452a`.

## Recon (base `0ae3452a`)

- `init_db` (`utils/py/harness_app.py:165-288`) is the only connect/initialize path. Every subcommand calls it (`:460` check, `:539` init, `:547-622` log/eval/and others). Order: `sqlite3.connect` (default 5 s busy timeout), `PRAGMA foreign_keys`, `PRAGMA journal_mode = WAL`, `CREATE TABLE IF NOT EXISTS …`, migration `ALTER` (GH-450 already tolerates its concurrent `duplicate column` race at `:276-283`), then seed if `harnesses` is empty.
- Production caller: turn shims use `HarnessTurnLogger.__exit__` (`utils/py/harness_turn_logger.py:90-147`), which spawns `harness_app.py log`. A non-zero exit is non-fatal and prints `telemetry row NOT written` (GH-346), so this race drops one audit row.
- Characterization, 200 rounds × 10 workers on a fresh DB each round: **30/200 rounds failed, 33 errors, all `database is locked` at `:171`**. No other error class appeared (schema, seed, ALTER, insert). Every failure returned in **0.06–0.07 s**, so the 5 s busy handler was never used. SQLite returns SQLITE_BUSY immediately on this lock upgrade, which means a larger `busy_timeout` cannot fix it.
- Prototype (bounded retry of only the WAL pragma on `database is locked`, 20–50 ms jittered sleep, at most 50 attempts), same loop: **0/200 rounds failed**, and all 200 DBs held exactly 10 `invocation_logs` rows.
- There is no shared SQLite open/WAL helper to reuse. `src/flightdeck/connectors.py:268` sets its own `busy_timeout`, and `releases_app.py` uses its own journal/lock protocol. This change stays local to `init_db`.

## Rating (2026-09-25): `rated 60/45/50/90`

- **Severity 45:** consequences are recoverable. The gate goes red at random (roughly 3% of full runs in normal gate load, 15% under the heavier repro loop), costing a 15-minute rerun and polluting timing campaigns (#800). In runtime, one telemetry row is dropped with a warning. No user data is corrupted and no turn fails.
- **Priority 60:** severity-led. It blocks gate reliability and the #800 campaign, and the fix is cheap.
- **Appeal 50:** neutral; the user gave none.
- **Effort 90:** about ten lines in one function plus a focused test.
- **Recurrence (2026-08-28 to 2026-09-25):** exact class, one incident (#813). Adjacent gate-flake class: 3 in the last 14 days (#793, #807, #813) against 3 in the prior 14 (#541, #558, #345), so the trend is flat. Same-function precedent: GH-450's concurrent `ALTER` race.

## Requirements

1. R1: concurrent first use of a fresh DB never fails on the WAL switch, so the #813 repro reports 0/200.
2. R2: every other `OperationalError` still raises immediately, and a lock that outlasts a bounded budget still raises. The retry must not hang.
3. R3: the gh496 concurrency case keeps ten workers on a fresh DB and prints worker stderr when any worker fails.
4. R4: a deterministic red control that fails on the base code.

## Non-goals

- No shared SQLite helper module, no change to `busy_timeout`, and no retries around other statements (the characterization shows no other error class).
- No read-back assertion that the mode is `wal`. The base does not check it, and requiring it would newly fail filesystems without WAL support. This declines the issue's "confirm the mode" suggestion as unneeded scope.
- No pre-creating the DB in the test, which would hide the race. No soak/loop test added to the gate.

## Phase 1 — Fix and focused tests

1. In `init_db`, wrap only `conn.execute("PRAGMA journal_mode = WAL;")` in a bounded loop: at most 50 attempts, retrying only when the message contains `database is locked`, sleeping 20–50 ms with jitter between attempts (worst case about 2.5 s), and re-raising on the last attempt or on any other error. Add `import random` and `import time`, plus a GH-813 comment explaining why the busy handler does not cover this case. Verify: `bash test/gh496-telemetry-isolation.sh` passes 14/14.
2. In `test/gh496-telemetry-isolation.sh` case #9, redirect each worker's stderr to `$WORK/concur_test/err_<i>` instead of `/dev/null`, and include the non-empty stderr in the `fail` message. Verify: temporarily breaking a worker argument prints its stderr, then revert.
3. Add case #14 to the same suite, a deterministic red control. An inline Python process passes a `sqlite3.Connection` subclass through `sqlite3.connect(factory=…)` whose `execute` raises `database is locked` for the WAL pragma a set number of times:
   - (a) three locks, then `init_db` succeeds and the `harnesses` table exists;
   - (b) a non-lock `OperationalError` on the pragma propagates after exactly one attempt;
   - (c) a lock on every attempt raises after the bounded budget, not forever.

   Verify: the case fails on base `0ae3452a` and passes with step 1.
4. Acceptance probe, not added to the gate: the #813 ten-worker loop reports 0/200 on the branch.
5. Run the full qualifying `./validate.sh` once on the final approved commit, in a separate disposable full clone.

**QA:** R1 by the 0/200 probe; R2 by cases 14b and 14c; R3 by the updated case #9 and its manual stderr check; R4 because case 14a is red on base.

## Risk and rollback

Easy. The change is local to one pragma call. At worst, an unwinnable lock now delays the failure by about 2.5 s. Roll back by reverting the commit.
