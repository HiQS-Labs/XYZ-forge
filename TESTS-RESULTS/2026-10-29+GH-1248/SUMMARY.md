# GH-1248 — 12-hour rules-only scheduled run

- **Run date:** 2026-10-29 14:05 UTC to 2026-10-30 02:00 UTC
- **Source:** `9da920e47a3f6904b7fa36bdd5a95fb69562b72b`, a clean checkout of `feat/gh1248-outer-loop-primitive` equal to origin
- **Harness SHA-256:** `bf2e626ff2411f607423b0cb2d599eec651f0979ede73ec549a44964bdea6cc9` (unchanged from `checkpoint2`)
- **Scenario SHA-256:** `bed30bb1ac9ffe5f6ff5283b21b84eb2eb8630402ba78f13152157736963bf70` (`soak-v1.jsonl`, matches the manifest)
- **Platform:** macOS 15.6.1 arm64, Python 3.14.7 (`/opt/homebrew/bin/python3`), `/usr/bin/sandbox-exec`
- **Result:** run 2 completed all 144 five-minute slots. 137 ticks completed, 1 was reconciled to `uncertain` after the injected crash, 6 were deliberately skipped, and none failed. The one-hour gate passed in both runs.

## Scope

This is the first half of the issue's §8 slot schedule (slots 1–144 of 288), run at real protocol cadence with the rules arm only. It is **not** the 24-hour soak, a multi-arm comparison, or a model evaluation. The Claude and Codex adapters, the watchdog, the scenario generator and the report generator (Phases 2–3) are not built, so only the faults that fall in slots 1–144 and need no watchdog were exercised:

| §8 fault | Slots | Exercised here |
|---|---|---|
| Kill during act | 37 | Yes |
| Scheduler stop | 85–90 | Yes |
| PAUSE | 145–156 | No (second half) |
| Tool failures | 193–216 | No (second half) |
| Malformed adapter output | 241–243 | No (second half; rules arm cannot emit it) |

A gitignored driver (`driver.py`, copied here) fired `python3 utils/py/harness.py factory-primitive tick` at `t0 + 300·(slot−1)` with a 240-second timeout, called `status` after each tick, and stopped with exit 3 on any unexpected exit code or outcome, any failed tick, an unexplained `uncertain` count, unknown cost, a changed canary, an unexpected top-level instance file, or an escape file.

## Run 1 — stopped at slot 13 (retained as failed evidence)

Run 1 started at 13:05:04 UTC. The one-hour gate passed: slots 1–12 completed, each inbox item was consumed in its slot, there were no failures and spend was 0. At slot 13 the driver stopped on an unexpected instance file, `.claude`. The operator's Claude Code shell had created `.claude/.cc-writes` while inspecting `state.db` from inside the instance directory. The containment check worked as intended, and the loop itself was clean, but the run was no longer uncontaminated, so it was abandoned rather than resumed. Log: `driver-run1-STOPPED.jsonl`.

## Run 2 — completed

| Measure | Observed |
|---|---|
| Slots | 1–144; 138 ticks recorded in `state.db`, 6 injected misses |
| Tick outcomes | 137 `completed`, 1 `uncertain`, 0 `failed` |
| Tools | 100 idle, 25 note, 11 probe (1 requested + 10 hourly periodic), 1 summarize; 1 idle intent with no tool run (slot 37) |
| Inbox | 27/27 consumed, each in its available slot (1–27) |
| Budget | 138 reservations, all reported, actual cost 0.0; `unknown_cost` never set |
| Timing | tick duration 0.117–0.274 s; maximum start lateness 0.032 s; no drift across 12 hours |
| Containment | canary unchanged; no unauthorized or external files; `tmp/<tool>` empty at the end |
| One-hour gate | Passed at slot 12 |

**Slot 37, kill during act.** The tick exited 70 after persisting an `idle` intent with `tool_started_at` set and no tool-run row. Slot 38 reconciled it to `uncertain` with the error "nonterminal tick recovered; no automatic retry", and the tool was not run again. Quarantine was not exercised: every inbox item had already been consumed, so there was nothing to quarantine.

**Slots 85–90, scheduler stop.** The driver skipped six ticks. Slot 91 completed normally, 0.029 s late, without trying to catch up. The harness itself recorded nothing for the skipped slots; only the driver log shows them.

## Gaps this run exposed

1. **The scenario front-loads every input.** All 27 items arrive in slots 1–27, so from slot 28 onwards the loop only idles and probes. The crash at slot 37 could not test quarantine, and the later fault windows will see an empty inbox too. Spreading items across all 288 slots would make the faults meaningful.
2. **No missed-tick record.** With no watchdog, the scheduler stop is visible only in the driver log, so criterion 10 cannot be measured (Phase 2).
3. **`status` is thinner than §7 asks for.** It omits heartbeat age and stage, lock state, the last receipt or error, and quarantined IDs.
4. **A verification failure after the tool runs is recorded as `failed`, not quarantined.** This run never hit that path, but the contract treats it as ambiguous.
5. **Running inside the instance directory contaminates it.** Inspect `state.db` by absolute path only; never `cd` into an instance.

## Artifacts

- `driver-run2.jsonl`: per-slot driver log for the completed run, including `status` after every tick
- `driver-run1-STOPPED.jsonl`: the stopped run
- `driver.py`: the driver used by both runs (SHA-256 `a6e74850…`)
- `instance-config.json`: the instance configuration (cap 1.0, maximum call cost 0.0, probe target `local://health`)
- `provenance.jsonl`: run, gate and fault records with exact hashes

The runtime roots (`state.db`, outputs, heartbeat) remain under the gitignored `temp/factory-primitive/rules-12h-2026-10-29-run{1-STOPPED,2}/`.
