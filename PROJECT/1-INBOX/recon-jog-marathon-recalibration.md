# Recon Map — Jog ↔ Marathon recalibration

Commit: `65efea9fae8e4680e78743b4a752d2f538d6eac8` (`origin/development`) · Mode: grep-only + direct reads · Lanes: A, B, C, D

## Subject and change class

Recalibrate Jog so it remains the serial queue supervisor while delegating each task's execution to
Marathon's existing single-phase driver. This is a cross-module state/authority and runtime-contract
change spanning the Releases DB, Swarm Preflight, Marathon, Relay, Tick, Git branches/PRs, and PDDA
reconciliation.

**Authority classification: Read projection.** `jog_queue` remains authoritative for serial order,
leases, and operator scheduling. Marathon remains authoritative for execution attempts, Tick tokens,
review/gate outcomes, branch/commit state, and PR creation. Jog projects Marathon's durable outcome
into its queue status; it must not become a dual-written execution peer.

**Real problem:** Jog was described as reusing Marathon but stopped at the lower-level Relay seam,
then independently rebuilt execution plumbing that Marathon already owns. **Smallest safe fix:** make
Jog a thin adapter around Swarm Preflight's resolved packet and `marathon-drive`, adding only the
machine-readable invocation/result contracts the supervisor needs.

**Overbuild to avoid:** moving serial queue state into Marathon, importing Marathon's nested Python
helpers as APIs, adding a builder-only Marathon mode, deleting Tick history during retry, or changing
ordinary Marathon success/PR semantics for all callers.

## The seams — where a change here escapes this file

| Seam | Location | Crosses | Breaks if |
|---|---|---|---|
| Jog CLI → queue | `utils/py/releases_app.py:3270-3675` | CLI, SQLite, journal, receipts, SQL dump | execution state is allowed to replace ordering/lease authority |
| Jog supervisor → executor | `utils/py/jog_run.py:263-374` | Relay, Tick, agent shims, environment | Jog continues calling `relay-drive` and duplicating Marathon policy |
| Capture → resolved run candidate | `utils/py/swarm_preflight.py:290-343,1499-1627` | PDDA contract, probes, artifacts, gate, target root | Jog reparses fenced JSON or consumes only an exit code |
| One-phase execution | `utils/py/marathon_drive.py:629-690,1394-1577,2052-2120` | reviewer, acceptance, gate, receipts, telemetry | Jog imports internal closures or weakens the reviewed phase contract |
| Attempts and token history | `utils/py/marathon_drive.py:717-772,2122-2239`; `relay-automation/marathon.sh:290-303` | `.tick/attempts`, append-only Tick events, retry identity | retry deletes history, reuses a spent token, or silently bypasses the cap |
| Branch and PR delivery | `utils/py/marathon_drive.py:2020-2050,2454-2576` | Git refs, protected branches, GitHub PRs | queue completion guesses a branch/PR or treats best-effort PR creation as proven |
| Merge → lifecycle closeout | `utils/py/wave_reconcile.py:680-805` | GitHub merge, issue state, docs, roadmap ledger | Jog duplicates the reconciler or marks completion before verifying reachability |
| Vendored installation | `utils/py/swarm_preflight.py:15-22`; `utils/py/marathon_drive.py:698-715` | root install versus `.xyz` target | a new root-relative lookup bypasses the canonical harness home |

## Call paths in

### Jog today

`releases jog run` (`utils/py/releases_app.py:4633-4638`)
→ `cmd_jog_run` (`utils/py/releases_app.py:3668-3675`)
→ `jog_run_main` (`utils/py/jog_run.py:430-596`)
→ promotion/probe lint (`utils/py/jog_run.py:175-260`)
→ Swarm Preflight subprocess, exit code only (`utils/py/jog_run.py:542-562`)
→ hand-built Relay/Tick/agent dispatch (`utils/py/jog_run.py:263-374`)
→ guessed `feat/gh<N>` landing (`utils/py/jog_run.py:377-427`)
→ receipt-backed queue status (`utils/py/releases_app.py:3599-3624`).

### Existing Marathon one-phase path

`marathon-drive.sh` → `utils/py/marathon_drive.py:629`
→ fail-fast issue/gate/agent/driver/write-set checks (`:1394-1577,2378-2452`)
→ protected-branch redirect (`:2454-2576`)
→ namespaced attempt gate and Tick reconciliation (`:717-772,2596-2632`)
→ rendered builder/reviewer relay + `relay-drive` (`:2291-2360,2645-2689`)
→ exit-3/timeout/terminal recovery (`:2696-2835`)
→ acceptance recheck + guarded gate + receipt (`:1943-2120`)
→ best-effort PR open (`:2020-2050`).

### Recalibrated path

`jog run` → lease next queue row → run Swarm Preflight into a deterministic packet directory → read
its structured candidate/invocation → invoke `marathon-drive` for one reviewed phase → read a durable
Marathon result receipt → project outcome into `jog_queue` → pause/merge according to Jog policy →
verify merge and delegate PDDA lifecycle work to `wave_reconcile.py`.

## State

- **Serial scheduling authority:** `jog_queue.position`, `status`, `lease_pid`, and queue attempt
  metadata in `releases.db`; all mutations go through `perform_write` and receipt regeneration
  (`utils/py/releases_app.py:841-858,1195-1255,3270-3665`).
- **Readiness authority:** the capture/working document plus Swarm Preflight's normalized contract,
  effective artifacts, probes, gate, target ref, and readiness verdict
  (`utils/py/swarm_preflight.py:290-343,399-459,1244-1547`).
- **Execution authority:** namespaced Marathon phase files, relay terminal state, Tick token family,
  lane-attempt record, acceptance/gate receipts, branch HEAD, and PR result.
- **Lifecycle authority:** GitHub merge/issue state and `wave_reconcile.py` for docs and roadmap. Jog
  may record the verified landing in its queue but must not reproduce lifecycle mutations.
- **Current overlap:** Jog and Marathon both attempt to own relay rendering, tokens, environment,
  retries, terminal interpretation, and branches. Their counters have different meanings: a Jog
  attempt is a queue lease; a Marathon attempt is a consecutive execution fire.
- **Cold start:** Jog repairs dead queue leases; Marathon repairs/recognizes relay and token state.
  A restarted Jog must consult the Marathon receipt/terminal state before starting another execution.

## Contracts

- `releases jog ...` is the public queue contract. Preserve ordering, leasing, receipt-backed writes,
  and hermetic dry-run behavior.
- Swarm Preflight's `run-candidate@1` packet is the existing machine boundary. Extend it additively
  with a structured Marathon invocation artifact rather than parsing `marathon-invocation.txt` shell.
- `marathon-drive.sh` is the supported one-phase process boundary. Preserve existing flags and exit
  codes; do not import closures nested inside `main()`.
- Marathon requires a builder, a distinct reviewer, bounded artifacts, and a runnable gate. Jog must
  not silently weaken those requirements.
- Marathon PR creation is deliberately best-effort. Add an opt-in/durable result receipt carrying
  outcome, reason, phase/lane identity, token, base/head branches, HEAD SHA, gate receipt, and PR
  URL/number. Do not make a transient GitHub failure retroactively turn ordinary Marathon green red.
- Retry must distinguish: resume/reconcile existing state, re-run only a failed gate, and rebuild the
  artifact on a fresh token. `jog retry` currently collapses all three.
- A completed queue row requires verified delivery evidence, not relay status alone.

## Build, failure, and rollback today

Targeted evidence in a disposable full clone at the mapped commit:

- `bash test/jog-queue.sh` → **34 passed, 0 failed**. The suite exercises queue CRUD, receipts,
  locks, orphan leases, dry-run, and a simulated runner only; it never drives a real vendored relay,
  branch, PR, retry token, or landing boundary.
- `bash test/marathon-drive.sh` → **152 passed, 0 failed**. It covers vendored root resolution,
  builder/reviewer routing, allowlists, attempts, terminal recovery, gates, containment, and branch
  behavior.
- Issue #279's four-task run remains the production reproduction: all four tasks eventually landed,
  but six operator-side interventions were required around the duplicated Jog plumbing.

Failure behavior to preserve: fail closed before spending a turn when preflight, binaries, gate, or
write scope is invalid; never commit on a shared branch; never delete append-only Tick history; never
mark delivery complete without a reachable merged PR/commit.

Safe rollout/rollback: first add the structured Marathon contracts with no default behavior change;
then add an opt-in Marathon executor to Jog and dogfood it; then flip Jog's default while retaining
the legacy Relay executor for one bounded compatibility window. Rollback is the explicit executor
selection, not history rewriting or queue/event deletion.

## Debug-mantra breadcrumb ledger

| Observation/run | Result | Ruled in/out |
|---|---|---|
| Raw issue #279 timeline | Six repeatable operator-side failures across four ultimately landed tasks | Rules in a supervisor/plumbing failure rather than bad model output or containment failure |
| Source trace: Jog executor | Direct `relay-drive`, manual Tick/env/status/landing; no Marathon call | Rules in genuine architectural drift |
| Source trace: Marathon driver | Existing one-phase review, gate, retry, branch, PR, and vendored machinery | Rules out reimplementing those fixes in Jog |
| Jog focused suite | 34/0 while real run failed | Rules in a coverage gap: simulated execution cannot validate integration plumbing |
| Marathon driver suite | 152/0 including vendored and recovery cases | Supports reuse of the existing phase boundary |
| Hypothesis: one call replacement fixes all six | Fails against intake and post-merge state ownership; Marathon also lacks a structured result | Rules out a blind substitution |
| Hypothesis: Jog queue should move into Marathon | Marathon has no serial scheduling/lease concern; Releases receipts already own it | Rules out an authority migration |

## Unknowns

| Unknown | Why it matters | What would settle it |
|---|---|---|
| Reviewer selection for Jog | Marathon requires an independent reviewer; this changes cost and CLI defaults | Maintainer decision plus an explicit `--reviewer`/policy contract |
| Retry intent | Gate-only retry must not rebuild; artifact retry needs a fresh token; restart may need neither | Define separate `resume`, `retry-gate`, and `retry-build` semantics before schema/CLI work |
| Branch naming | Jog assumes `feat/gh<N>`; Marathon derives a suggested/lane branch | Choose one convention or make Jog consume receipt identity only |
| PR adoption | An existing PR may be legitimate or unrelated/stale | Specify repo, base, head, issue linkage, SHA, and gate checks for adoption |
| Cross-system atomicity | GitHub merge, queue receipt, and PDDA reconciliation cannot share one transaction | Define an idempotency key and replay order for `jog land/reconcile` |
| Queue attempt meaning | It may be historical lease count or a second policy cap | Choose one; only Marathon should cap execution retries |

## Current-state radius, one line

The change reaches the Jog CLI and Releases ledger, Swarm Preflight packets, Marathon/Relay/Tick
execution and retry state, turn-shim containment, protected Git branches and GitHub PRs, test fixtures,
vendored `.xyz` consumers, and post-merge PDDA reconciliation.
