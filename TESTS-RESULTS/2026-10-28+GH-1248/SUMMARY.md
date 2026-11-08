# GH-1248 — Rules-only checkpoint controls

- **Local run date:** 2026-10-28 (UTC timestamps cross midnight)
- **Current run ID:** `checkpoint2`; `checkpoint1` is retained evidence for the superseded standalone layout
- **Source state:** `503a1ca5eae538941497f1cd543014a90eaef782` plus the uncommitted corrected tree; `provenance.jsonl` records the exact harness and data hashes
- **Harness SHA-256:** `bf2e626ff2411f607423b0cb2d599eec651f0979ede73ec549a44964bdea6cc9`
- **Platform:** macOS 15.6 arm64, Python 3.12.15, `/usr/bin/sandbox-exec`
- **Result:** 17/17 manual controls passed against `python3 utils/py/harness.py factory-primitive`

## Scope

This is a short manual-control matrix for the new rules-only outer-loop checkpoint, not a registered test suite, scheduler soak, model evaluation, or production-readiness result. The tracked scenario contains 27 inputs: three ordinary requests and 24 deterministic adversarial note canaries. The ordinary four-tick control consumes the first four inputs; the other 23 remain pending for their future slots.

The corrected layout preserves the existing registry-launcher fallback, routes the experiment through `utils/py/harness.py factory-primitive`, accesses state through `releases_app.connect(path, must_exist=False)`, and limits `utils/py/factory_primitive/` to prompts, schemas, and scenarios. Runtime state remains beneath gitignored `temp/factory-primitive/`.

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

## Full-gate outcome

The initial full `./validate.sh` run at `503a1ca5` in disposable clone `temp/XYZ-forge-gh1248-gate-503a1ca5` hit the 300-second tool limit before producing a complete result. It is **incomplete and not a pass**. Its 129 retained result lines include:

- **GH-777 inventory ratchet:** failed on seven new loose Python modules and a direct SQLite connection. This was caused by the initial layout. The corrected tree removes those modules, uses the existing launcher and canonical gateway, and the standalone `python3 utils/pdda/check_inventory_ratchet.py --check` reports clean with zero new scripts/connects.
- **GH-666 `agy-turn` model-probe caller preservation:** the initial parallel gate ran 14 tests with 11 failures dominated by one-second probe timeouts and missing records. Separate sequential runs then passed all 14 model-probe tests and all 65 `agy-turn` checks on both base `93f41cb8` and candidate `833c87c8`. The candidate's Python segment took 8.359 seconds. This clears the focused sequential comparison, not the incomplete parallel full gate.

The exact aggregate output and both failed-suite logs are retained under `logs/gate-503a1ca5-*.log`. The base output and before/after clone identity are retained under `logs/base-93f41cb8-*.log`. The Python dependency preflight also found `pytest` missing from the active Python 3.12.15 environment, while `requests` and `yaml` imported successfully; no dependency installation was attempted.

## Focused existing suites at `833c87c8`

All five selected existing suites passed sequentially in the disposable full clone `temp/XYZ-forge-gh1248-focused-833c87c8`:

| Existing suite | Result |
|---|---|
| `gh777-inventory-ratchet.sh` | Inventory ratchet enforcement and negative controls passed |
| `gh174-harness-registry.sh` | 8 pass, 0 fail |
| `gh496-telemetry-isolation.sh` | 15 pass, 0 fail |
| `gh788-python-path-space.sh` | 11 pass, 0 fail |
| `agy-turn.sh` | 65 pass, 0 fail; 14 model-probe tests passed |

The candidate clone remained at `833c87c86428abe885a00736bd48d48875113a77`, with `core.bare=false`, its original local remote, and no local user-email mutation before or after the run. Logs and provenance use the `focused-833c87c8` prefix/run ID. These are focused checks, not a substitute for the full gate or the one-hour soak.

## Artifacts

- `controls-checkpoint1.jsonl` and `controls-checkpoint2.jsonl`: historical and current machine-readable case outcomes with exact CLI commands.
- `logs/checkpoint1-*.log` and `logs/checkpoint2-*.log`: nonempty stdout, stderr, exit codes, status, and database assertions for each case and driver run.
- `provenance.jsonl`: cumulative platform, base, source/scenario/prompt hashes, commands, outcomes, and log pointers. The current run includes the harness SHA-256; the data-tree hash no longer represents executable code.
- `logs/gate-503a1ca5-*.log`: incomplete aggregate gate and its two failed-suite outputs, retained as historical failure evidence.

## Not established

The one-hour rules-only run has not occurred. No watchdog, report generator, Claude/Codex adapter, two-hour run, 24-hour soak, scheduler invocation coverage, or independent review exists yet. The 24 canaries are seeded but have not all been executed in a long run. These controls do not establish factory, marathon, exactly-once, queue/lease, or production integration readiness.
