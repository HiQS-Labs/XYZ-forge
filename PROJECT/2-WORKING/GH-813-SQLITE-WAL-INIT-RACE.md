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
| Plan revised after Codex plan-QA round 1 (test-seam, receipts, latency wording); base receipt and provenance committed: 29/200 rounds fail, all at the WAL pragma. | Codex plan-QA round 3, then implement Phase 1. |

## Problem (observed)

Ten `harness_app.py log` processes against a **fresh** DB (the `test/gh496-telemetry-isolation.sh` concurrency case #9) sometimes lose a worker with `sqlite3.OperationalError: database is locked`, raised at `utils/py/harness_app.py:171`, `conn.execute("PRAGMA journal_mode = WAL;")`, inside `init_db`. Seen as #800 M4 Pro trial 3, a full-gate refusal at `0ae3452a`.

## Recon (base `0ae3452a`)

- `init_db` (`utils/py/harness_app.py:165-288`) is the only connect/initialize path. Every subcommand calls it (`:460` check, `:539` init, `:547-622` log/eval/and others). Order: `sqlite3.connect` (default 5 s busy timeout), `PRAGMA foreign_keys`, `PRAGMA journal_mode = WAL`, `CREATE TABLE IF NOT EXISTS …`, migration `ALTER` (GH-450 already tolerates its concurrent `duplicate column` race at `:276-283`), then seed if `harnesses` is empty.
- Production caller: turn shims use `HarnessTurnLogger.__exit__` (`utils/py/harness_turn_logger.py:90-147`), which spawns `harness_app.py log`. A non-zero exit is non-fatal and prints `telemetry row NOT written` (GH-346), so this race drops one audit row.
- Characterization receipt `TESTS-RESULTS/2026-09-25+GH-813/base-200.txt` with its provenance row in `provenance.jsonl` (`base-concurrent-init-200`: exact command, UTC start/end, exit 0, `runtime_equivalent: true` via `git diff --quiet 0ae3452a -- utils/py`, Python 3.14.7, SQLite 3.53.4). It was made with the committed probe `repro-concurrent-init.sh` (200 rounds × 10 workers, fresh DB per round). **29/200 rounds failed, 35 errors, all `database is locked` raised at `harness_app.py:171`**, and exactly 29 rounds lack 10 rows. No other error class appeared (schema, seed, ALTER, insert). Every failure returned in **0.06–0.07 s**, so these failures never used the default 5 s busy handler. SQLite returned SQLITE_BUSY immediately on this lock upgrade, so a larger `busy_timeout` would not fix them. Three earlier runs of the same loop are exploratory and have no provenance: 30/200 (33 errors), 24/200 (31 errors), and a 29/200 run whose provenance write failed. All their errors were at `:171`.
- Observed rates by harness: 1 failed gate trial in 3 on the M4 Pro (#800, one sample); 1/30 in the lighter loop in the #813 issue body; 24/200 and 30/200 under the timing probe above, which adds contention. No per-gate-run probability is claimed.
- Exploratory prototype (bounded retry of only the WAL pragma on `database is locked`, jittered sleep, at most 50 attempts), same loop: 0/200 failed rounds, and all 200 DBs held exactly 10 rows. That run was not retained; the implementation's receipt will be `TESTS-RESULTS/2026-09-25+GH-813/fixed-200.txt` from the same probe.
- There is no shared SQLite open/WAL helper to reuse. `src/flightdeck/connectors.py:268` sets its own `busy_timeout`, and `releases_app.py` uses its own journal/lock protocol. This change stays local to `init_db`.

## Rating (2026-09-25): `rated 60/45/50/90`

- **Severity 45:** consequences are recoverable. The full gate goes red at random (seen once in three M4 Pro trials, #800), costing a 15-minute rerun and polluting timing campaigns. In runtime, one telemetry row is dropped with a warning. No user data is corrupted and no turn fails.
- **Priority 60:** severity-led. It blocks gate reliability and the #800 campaign, and the fix is cheap.
- **Appeal 50:** neutral; the user gave none.
- **Effort 90:** about ten lines in one function plus a focused test.
- **Recurrence:** query `gh issue list --state all --search "created:2026-08-28..2026-09-25 (flaky OR \"passes alone\" OR \"under load\" OR \"parallel load\" OR \"database is locked\")"`, run 2026-09-25, with results hand-classified. These are **examples, not an exhaustive count.**
  - Exact class (`database is locked` / gh496): one incident, #813 (created 2026-09-25T04:06Z).
  - Adjacent test-flake class, last 14 days (2026-09-11 to 09-25): #793 (09-24T20:53Z), #807 (09-25T02:24Z), #813.
  - Adjacent class, prior 14 days (2026-08-28 to 09-10): #345 (08-31T16:09Z), #541 (09-10T03:14Z), #558 (09-10T20:15Z).
  - 3 against 3. Selected examples alone do not establish a trend, so it is recorded as unknown. Same-function precedent: GH-450's concurrent `ALTER` race (`harness_app.py:276-283`).

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

1. In `init_db`, wrap only `conn.execute("PRAGMA journal_mode = WAL;")` in a bounded loop: at most 50 attempts, retrying only when the message contains `database is locked`, sleeping 20–50 ms with jitter between attempts, and re-raising on the last attempt or on any other error. The 49 sleeps add at most 2.45 s of deliberate delay to an immediate-BUSY failure. That is not a wall-clock cap, since each attempt may also spend time inside SQLite. Add `import random` and `import time`, plus a GH-813 comment explaining why the busy handler does not cover this case. The import lines shift `harness_app.py`'s connect from :168 to :170; the GH-777 ratchet tolerates same-file line shifts (`utils/pdda/check_inventory_ratchet.py:118-120`), so no baseline change is needed. Verify: `bash test/gh496-telemetry-isolation.sh` exits 0 with zero `FAIL:` lines.
2. In `test/gh496-telemetry-isolation.sh` case #9, redirect each worker's stderr to `$WORK/concur_test/err_<i>` instead of `/dev/null`, and include the non-empty stderr in the `fail` message. Verify: temporarily breaking a worker argument prints its stderr, then revert.
3. Add case #14 to the same suite, a deterministic red control. `init_db` has no connection parameter and calls `sqlite3.connect(db_path)` (`harness_app.py:168`), so the inline Python process saves the real `sqlite3.connect` and patches `sqlite3.connect` (the module object `harness_app` imports) with a wrapper that forwards to it with `factory=LockingConnection`. That `sqlite3.Connection` subclass's `execute` counts WAL-pragma attempts and raises a configured error for the first K of them. No production injection API is added.
   - (a) K=3 locks: `init_db` succeeds, the `harnesses` table exists, and the count shows exactly 4 attempts.
   - (b) a non-lock `OperationalError("disk I/O error")`: it propagates after exactly 1 attempt.
   - (c) locks on every attempt: `init_db` raises `database is locked` after exactly 50 attempts. The case runs under an outer `timeout 30` so an unbounded mutant fails instead of hanging.

   Verify: case 14 fails on base `0ae3452a` (14a raises after 1 attempt) and passes with step 1. Record both outputs in `TESTS-RESULTS/2026-09-25+GH-813/`, each with a `provenance.jsonl` row (command, commit, UTC times, exit code).
4. Acceptance probe, not added to the gate: `repro-concurrent-init.sh … 200` on the branch reports 0/200 failed rounds and 0 rounds with a row count other than 10. Commit it as `fixed-200.txt` with a `provenance.jsonl` row, in the same shape as the base row.
5. Run the full parallel gate `./validate.sh` once on the final approved commit, in a separate disposable full clone, with identity checked before and after. This is a full self-check, not the `ci-local.sh` qualifying record (`ROUTER.md:110-111`), which is not claimed. The pre-push gate also runs on push.

**QA:** R1 by the 0/200 probe; R2 by cases 14b and 14c; R3 by the updated case #9 and its manual stderr check; R4 because case 14a is red on base.

## Risk and rollback

Easy. The change is local to one pragma call. An unwinnable immediate-BUSY lock now adds at most 2.45 s of deliberate sleep before the error is raised, plus whatever time each attempt spends inside SQLite. Roll back by reverting the commit.
