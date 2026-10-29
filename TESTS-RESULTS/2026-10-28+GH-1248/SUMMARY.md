# GH-1248 — Rules-only checkpoint controls

- **Local run date:** 2026-10-28 (UTC timestamps cross midnight)
- **Run ID:** `checkpoint1`
- **Base:** `93f41cb8409068182f85dbc9352b2ab909427b7f` plus the uncommitted source tree hashed in `provenance.jsonl`
- **Platform:** macOS 15.6 arm64, Python 3.12.15, `/usr/bin/sandbox-exec`
- **Result:** 17/17 manual controls passed.

## Scope

This is a short manual-control matrix for the new rules-only outer-loop checkpoint, not a registered test suite, scheduler soak, model evaluation, or production-readiness result. The tracked scenario contains 27 inputs: three ordinary requests and 24 deterministic adversarial note canaries. The ordinary four-tick control consumes the first four inputs; the other 23 remain pending for their future slots.

## Observed controls

| Control | Observed result |
|---|---|
| Ordinary smoke | Slots 1–4 completed with verified note, summarize, probe, and note outputs |
| Malformed and disallowed decisions | Classified `invalid-output` and `rejected`; safe idle ran; requested action did not |
| New-file, existing-file, and instance-external escapes | Tool returned nonzero; `Operation not permitted` recorded; no escape file appeared and the canary stayed unchanged |
| Crash during `act` | Next tick recorded `uncertain`, quarantined the affected input, and did not repeat the attempt |
| Crash during intent and missing decision | Next tick recorded `unpersisted-intent-abort`, quarantined the snapshot input, and continued safely |
| Missing snapshot (crash or deleted records) | Next tick recorded `unpersisted-intent-abort`, paused the instance, and quarantined all 27 pending inputs |
| Missing receipt after tool output | Recovered as `uncertain`; one tool run only; input quarantined |
| Confirmed-unbilled adapter error | Reservation released; spend 0; no unknown-cost hold |
| Ambiguous timeout | Worst-case 0.1 reservation held; `unknown_cost=true`; `PAUSE` set |
| Budget cap | Second tick paused before snapshot or evaluation; only one agent-call event |
| Tool failure | Explicit failed receipt and tool run; input remained pending |
| Instance path guard | Path-like instance name rejected with exit 2 before initialization |

Expected nonzero exits are retained in the logs: 70 for simulated process crashes, 1 for tool/sandbox failures, and 2 for rejected CLI paths. Every case used a fresh runtime root beneath gitignored `temp/factory-primitive/`; no production Jog, scheduler, repository execution, GitHub-write, or model adapter was invoked.

## Artifacts

- `controls-checkpoint1.jsonl`: machine-readable case outcomes and exact CLI commands.
- `logs/checkpoint1-*.log`: nonempty stdout, stderr, exit codes, status, and database assertions for each case.
- `provenance.jsonl`: platform, base, source/scenario/prompt hashes, commands, outcomes, and log pointers.

## Not established

The one-hour rules-only run has not occurred. No watchdog, report generator, Claude/Codex adapter, two-hour run, 24-hour soak, scheduler invocation coverage, or independent review exists yet. The 24 canaries are seeded but have not all been executed in a long run. These controls do not establish factory, marathon, exactly-once, queue/lease, or production integration readiness.
