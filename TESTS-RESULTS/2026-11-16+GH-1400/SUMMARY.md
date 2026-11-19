# GH-1400 follow-up — task-local failure continuation, restart and global-stop controls

Runtime under test: `utils/py/jog_run.py` blob `70c085faa955aa200b67a9346c1aecb1f7ba6396`, identical
at implementation commit `720b9c9a5b959ee5b0864426e3a57525cf0e429e` and at the control commit
`7f946cd1d79fbd405b6c67ead1c638fd2fed709d` (later commits changed only the control script).
Baseline: `1d9658c3c63c1b1a8780ad26e4962f808b3c7625` (the dogfood runtime pin), blob recorded in
`smoke/results.json`. Plan QA: Claude (subscription, Sonnet 5.5, effort high) FAIL round 1, PASS
round 2/3, receipt `relay-system/2026-11-16/gh1400-followup-plan.claude.md`.

## What ran

`followup.py` drives the real `releases_app.py jog run` entrypoint with `--supervise-until` and
`--checkpoint-root` in synthetic fixtures (primary, local bare remote, execution clone, publication
clone, controlled preflight and worker). It reuses PR #1491's retained `check.py` helpers. No
provider, network, server, LTVera or real builder was involved. It ran from the disposable full
verify clone, whose HEAD, origin, `core.bare`, local identity and tracked status were recorded before
and after each run; completion is refused on drift or a missing, duplicate or failed check.

| Run | Result |
|---|---|
| attempt 1 (`720b9c9a5`) | 17/23, incomplete — fixture defects (restart budget expectation, a `kill`-prefixed mode name, a stopped child holding the worker pipe). Retained. |
| attempt 2 (`14d2f8932`) | 22/23, incomplete — fixture measured "unpublished" from HEAD instead of the working tree. Retained. |
| smoke (`7f946cd1d`) | 23/23, complete. |
| repeat variation (`7f946cd1d`) | 23/23, complete. |
| `test/gh280-jog-marathon-adapter.sh` | 227 pass, 0 fail. |

No failure was relabelled; both failed attempts were control-script defects, fixed by committed
script changes, with the runtime unchanged.

## Acceptance map

1. Task-local failure continues — `local-failure-continues`: A's `pre-advance-failed` gate-red
   receipt leaves A `failed` with reason and receipt path, attempt 1; B dispatched once in the same
   invocation; checkpoint published. `no-reentry-next-wake`: the next wake runs C, never A.
2. Dependent/held not selected, budgets kept — `budgets-held` (max-tasks 2 stops before C, C attempt
   0), `dependent-not-dispatched` (pre-parked B and preflight-refused D get no builder).
3. Restart before acknowledgement — `restart-adopts-once`: the worker writes an approved receipt and
   SIGKILLs the supervisor (exit -9, row `running`, journal `running`, no committed receipt, worker
   exited); restart adopts and publishes A with no builder, attempt 1, then B once.
   `restart-missing-holds`, `restart-corrupt-holds`: A held ("supervision held"), never rebuilt.
4. Shared unsafe stops all dispatch — `stop-owner-after-failure`: after A's task-local failure a
   SIGSTOPped peer owns the execution-clone lock; exit 4, B undispatched, lock untouched.
   `stop-owner-next-wake-publishes`: the stopped wake's unpublished failure is published by the next
   wake's journal recovery, then B once. `stop-checkpoint-contradiction`: a foreign primary commit
   against a running journal refuses before any dispatch. `local-failure-dirty-holds`: a lane left
   with tracked changes holds before B.
5. Red controls — `baseline-red`: the unfixed runtime leaves B pending and prints the stop line.
   Fail closed, each with B undispatched: `gate-killed` (gate red, exit 5), `post-approve-failed`,
   `refused`, `interrupted`, `lock-contention`, `crashed`, gate not run, missing receipt, corrupt
   receipt, mismatched execution id, clone ledger change.

## Limits

Exercised: the scoped guarantees above on the real entrypoint with synthetic workers. Unproven:
production providers and gates, whether a real red gate leaves the lane clean (a dirty lane holds),
classification of a shared-environment defect that still produces a `pre-advance-failed` gate red
(it costs later tasks one attempt each, bounded by max-tasks and deadline, never a retry), mid-wake
checkpoint contradiction between tasks (unchanged; `finish()` catches it afterwards), power loss,
context continuity, external exactly-once and PID reuse. The kill is a fixture worker signalling its
parent, not a host crash. Fixture logs contain local absolute temp paths.
