# GH-1251 manual smoke: marathon planner fails closed on unknown preflight exits, missing dependencies and unplaceable lanes

- **Date:** 2026-10-29
- **Platform:** macOS (Darwin arm64), Python 3
- **Base commit:** `93f41cb8409068182f85dbc9352b2ab909427b7f` (`development`), worktree HEAD `bb8c9d4cd427e4470c58c6873869f52a54a56bc3`
- **Target surface:** `utils/py/_marathon_plan.py` (`Engine.run`, `Engine._render_queue_doc`)
- **No new test suite added** (GH-831).

## Phase 0

1. **Planner fixtures grep (`test/marathon-plan.sh`, `test/gh418-planner-ledger-source.sh`, `test/gh362-marathon-plan-link-bullets.sh`, `test/gh423-roadmap-render.sh`):**
   - `test/marathon-plan.sh` Scenario A (`:117`) tests a ready dependency (`GH-104` after `GH-100`, both in the ledger).
   - `test/marathon-plan.sh` Scenario G (`:234-250`) tests a dependency on a **present-but-held** ledger item (`GH-701` depends on `GH-710`, which is in the ledger and unrated), not a missing ledger row.
   - `test/marathon-plan.sh` Scenario H (`:255-272`) tests Oxford-comma dependencies (`GH-802` depends on `GH-800`, `GH-801`, `GH-803`, all present in the ledger).
   - `test/marathon-plan.sh` Scenario T (`:629-725`) has neither a dependency cycle, a missing dependency, nor `--deep` delegation, so cross-lane parity (`70 passed, 0 failed, 2 skipped`) is unaffected; the GH-698 rendered-table skip (`:688-697`) is untouched.
   - None of the existing planner suites (`test/marathon-plan.sh`, `test/gh418-planner-ledger-source.sh`, `test/gh362-marathon-plan-link-bullets.sh`, `test/gh423-roadmap-render.sh`) pin the old advisory behaviour on missing dependencies, unknown `--deep` preflight exits, or unplaceable wave cycles. Zero test files required edits.

## Case 1 — Deep delegation unknown/invalid preflight exits (`2`, `3`, `127`)

### On the fix (`utils/py/_marathon_plan.py`)
Running `Engine.run` (`--dry-run --deep`) with a stub `SWARM_PREFLIGHT` exiting `2`, `3`, and `127`:

- **Exit 2 (usage / unexpected failure):**
  ```
  FLAGS (deterministic signals — never auto-resolved)
    WARN [preflight-error]  GH-100 · preflight test
          unknown/failed preflight exit 2 — hold; rerun swarm-preflight directly
          → rerun swarm-preflight directly

  SUMMARY [marathon-plan] items=1 active=0 waves=0 drift=false held=1 (exit 5)
  ```
  Rendered under `### ⚠️ Not yet sequenceable — rate / add doc / add contract` as `- #100 GH-100 · preflight test — \`preflight-error\``. Planner exits `5`.

- **Exit 3 (invalid contract):**
  ```
  FLAGS (deterministic signals — never auto-resolved)
    INFO [needs-contract]  GH-100 · preflight test
          swarm-preflight --dry-run → invalid contract (exit 3)
          → fix the ## Swarm Preflight Contract json block

  SUMMARY [marathon-plan] items=1 active=0 waves=0 drift=false held=1 (exit 5)
  ```
  Rendered under `### ⚠️ Not yet sequenceable — rate / add doc / add contract` as `- #100 GH-100 · preflight test — \`needs-contract\``. Planner exits `5`.

- **Exit 127 (command not found / signal / other nonzero):**
  ```
  FLAGS (deterministic signals — never auto-resolved)
    WARN [preflight-error]  GH-100 · preflight test
          unknown/failed preflight exit 127 — hold; rerun swarm-preflight directly
          → rerun swarm-preflight directly

  SUMMARY [marathon-plan] items=1 active=0 waves=0 drift=false held=1 (exit 5)
  ```
  Rendered under `### ⚠️ Not yet sequenceable — rate / add doc / add contract` as `- #100 GH-100 · preflight test — \`preflight-error\``. Planner exits `5`.

### Base Red Control (`93f41cb8`)
At `93f41cb8`, all three stub exits (`2`, `3`, `127`) leave `r["state"] == "ready"` and pack `#100` into **Wave 1** with `exit 0`:
```
SUMMARY [marathon-plan] items=1 active=1 waves=1 drift=false held=0 (exit 0)
  DOC: **Wave 1:** #100
```

## Case 2 — Dependency on a missing issue (`#200` depends on `#999` not in ledger)

### On the fix (`utils/py/_marathon_plan.py`)
```
FLAGS (deterministic signals — never auto-resolved)
  INFO [blocked-dep]  GH-200 · depends on missing
        depends on a held/unbuildable item (#999) — excluded from active waves until the dependency is sequenceable
        → rate/unblock the dependency first
  INFO [dep-not-found]  GH-200 · depends on missing
        lists a dependency on #999, which is not in the ledger
        → fix the issue number or add a ledger pointer

SUMMARY [marathon-plan] items=1 active=0 waves=0 drift=false held=1 (exit 5)
```
`#200` is held as `blocked-dep` (rendered under `### ⛔ Blocked on a held dependency`), `active=0`, `waves=0`, `held=1`, and the planner exits `5`.

### Base Red Control (`93f41cb8`)
At `93f41cb8`, `#200` gets only the `dep-not-found` info flag, remains `ready`, and is packed into **Wave 1** with `exit 0`:
```
SUMMARY [marathon-plan] items=1 active=1 waves=1 drift=false held=0 (exit 0)
  DOC: **Wave 1:** #200
```

## Case 3 — Unplaceable lanes (two ready items in a dependency cycle: `#300` ↔ `#301`)

### On the fix (`utils/py/_marathon_plan.py`)
```
FLAGS (deterministic signals — never auto-resolved)
  WARN [unplaceable]  GH-300 · cycA
        could not be placed in any wave (dependency cycle / zero zone cap) — hold, do not co-wave
        → break the dependency cycle or raise the zone cap
  WARN [unplaceable]  GH-301 · cycB
        could not be placed in any wave (dependency cycle / zero zone cap) — hold, do not co-wave
        → break the dependency cycle or raise the zone cap

SUMMARY [marathon-plan] items=2 active=0 waves=0 drift=false held=2 (exit 5)
```
- Neither `#300` nor `#301` is placed in a wave (`active=0`, `waves=0`, `held=2`, planner exits `5`).
- `active` is recomputed from placed waves, so the per-item scoring table renders `| (no active, ready, rated items) | — | — | — | — | — |` rather than reporting the held lanes as both active and held.
- Both items render under `### ⚠️ Not yet sequenceable — rate / add doc / add contract` with state `` `unplaceable` ``.

### Base Red Control (`93f41cb8`)
At `93f41cb8`, the no-progress fallback appends all deferred lanes together into **Wave 1** (`#300 ‖ #301`) with `exit 0`:
```
SUMMARY [marathon-plan] items=2 active=2 waves=1 drift=false held=0 (exit 0)
  DOC: **Wave 1:** #300 ‖ #301
```

## Verdict

PASS.
