# Phase 2 build — swarm brief (read this, then build your lane)

Two agents build in parallel, disjoint lanes, on `main` in
`/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm`. `tick` = `./bin/tick`.
Tasks are pre-seeded. **You were told which agent you are and which lane.** Claim
your **named** tasks (don't `take` — lanes are pre-assigned).

- **Copilot Codex (agent id `copilot-codex`) → Watchdog lane:** TASK-W1 then TASK-W2. Scope: `relay-automation/watchdog.sh`, `test/watchdog-liveness.sh`.
- **Codex (regular, agent id `codex`) → Runner lane:** TASK-R1 then TASK-R2. Scope: `relay-automation/runner.sh`, `test/runner-loop.sh`.

> Both builders are Codex variants — use the **distinct agent ids above** (`copilot-codex` vs `codex`) in every `tick` call and commit tag so the coordination log keeps the two lanes separable.

The two lanes are disjoint → you run concurrently and never collide. Within your
lane the two tasks share scope → do them **sequentially** (finish W1/R1, then W2/R2).
Do **not** touch `validate.sh` — the coordinator wires both new tests in at wrap-up
(avoids a shared-file collision).

```
XYZ MANTRA — recite before every action
1. VERIFY, DON'T ASSUME.  Run `./bin/tick info <TASK-ID>` to confirm your lane's exact paths.
2. TRACE THE REAL PATH.  Every claim about the code cites file:line you actually read.
3. FALSIFY YOUR HYPOTHESIS.  Try to DISPROVE each assumption against the source. Default "unverified".
4. STAY IN YOUR LANE / CODE TO THE CONTRACT.  Never edit outside your scope; code to the declared interface.
```

## Build loop (per task; lanes are pre-assigned, so CLAIM by name)
```
1. ./bin/tick claim <YOUR-TASK> --agent <you> --paths "<your lane scope>"
2. ./bin/tick info <YOUR-TASK>        # confirm paths; work ONLY inside them
3. build it: code + its test
4. ./bin/tick ping <YOUR-TASK> --agent <you>   # heartbeat after each edit
5. run the task's acceptance check (below) — must pass
6. git status --short ; git add <your exact files> ; git commit -m "[<you>] <YOUR-TASK> <summary>"
7. ./bin/tick done <YOUR-TASK> --agent <you> ; go to next task
```
Stop when both your tasks are done. **Initiative bound:** implement the thinnest
change that makes the stated acceptance pass — no behavior beyond it unless specified.

---

## WATCHDOG LANE (Copilot Codex, agent id `copilot-codex`) — proposal Phase 2: Liveness & self-healing

Current `watchdog.sh` already does JSON-driven parked detection (`tick analyze
--format json` → `parked_suspects[]`). Make escalation **real** (it's currently a
stub). Reap stays gated/stub — real reap is blocked on an authority decision (see
PHASE-2-PLAN.md), so do NOT wire real `tick reap`.

**TASK-W1 (pri 10) — real escalation.** In `relay-automation/watchdog.sh`, replace
the `escalate_to_human` stub with a **structured escalation record** per parked
suspect: a JSON line `{task, agent, max_gap_ms, heartbeats, evidence, ts}` written
to `--escalation-log <file>` (default: stdout), behind a `--channel stdout|file`
seam. Keep `--allow-reap` gating the reap **stub** (do not implement real reap).
- Accept: `bash -n relay-automation/watchdog.sh`; healthy live run → `no parked tasks detected` (no record); a parked-suspect JSON fixture → exactly one escalation record with the right fields.

**TASK-W2 (pri 8) — `test/watchdog-liveness.sh`.** A self-running test (source
`test/_setup.sh`) asserting: (a) a JSON fixture with one parked suspect → one
escalation record containing the task id + gap; (b) healthy (empty
`parked_suspects[]`) → no record, exit 0; (c) `--allow-reap` fires the reap stub
**only** on a real suspect, never on a healthy run.
- Accept: `bash test/watchdog-liveness.sh` passes.

---

## RUNNER LANE (Codex, regular, agent id `codex`) — proposal Phase 3: Termination & verdict gating

Current `runner.sh` has the claimability guard, artifact-scoped clean-tree gate,
`extract_verdict` (greps `VERDICT: PASS|FAIL|PARKED`), and a round-cap loop, but
`claim_task`/`resume_task` are stubs. Make the turn loop **real** — and keep the
agent invocation **injectable** so it's testable without real headless auth.

**TASK-R1 (pri 10) — real verdict-gated turn loop.** In `relay-automation/runner.sh`:
- `resume_task`/`claim_task` → run an **injectable** `--agent-cmd "<cmd>"`, capturing its stdout to `$LOG_FILE`. (Real headless `claude -p`/`codex exec` wiring is DEFERRED — `--agent-cmd` + a fake in tests is the contract for now.)
- Per round, after running the agent: `extract_verdict` → **PASS** → `./bin/tick done <task> --agent <agent>` + exit 0; **FAIL** → retry next round (within round cap); **PARKED** → exit 3 (watchdog territory). Keep the artifact-scoped clean-tree gate as the pre-run guard.
- Accept: `bash -n relay-automation/runner.sh`; a manual smoke with `--agent-cmd` that echoes `VERDICT: PASS` drives one round to `tick done` + exit 0.

**TASK-R2 (pri 8) — `test/runner-loop.sh`.** A self-running test (source
`test/_setup.sh`; point the runner at the test repo via `TICK_REPO_ROOT=$A` /
`TICK_BIN`) driving `runner.sh` with a **fake `--agent-cmd`** through: (a) PASS →
exit 0 + a `task.done` event; (b) FAIL-then-PASS → retries then done; (c)
round-cap-exceeded → non-zero exit, no `done`.
- Accept: `bash test/runner-loop.sh` passes.

---

## Notes
- Each test is **self-running**; the coordinator adds both to `validate.sh` at wrap-up (target: 15 tests).
- Start both windows together for maximum concurrency overlap (this round also produces the next work-bounded concurrency datapoint).
- Hard 60-min box. One slice only — do not flesh out Phases 4–5 or real reap/headless wiring.
