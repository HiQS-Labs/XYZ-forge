---
title: GH-496 Merge Churn, Telemetry Relocation, and Router Invariants — Recon Map
status: In progress — Phase 0 bounded source recon
created: 2026-09-10
updated: 2026-09-10
owner: Codex
goal: Trace existing readers, writers, and routing invariants for merge-churn telemetry and releases surfaces.
doc_type: research
roadmap_exempt: true
gh_issue: 496
source: https://github.com/HiQS-Labs/XYZ-forge/issues/496
---

# Recon Map — GH-496 Merge Churn, Telemetry Relocation, and Router Invariants

## Status

| What was just completed | What's next |
|---|---|
| Phase 0 source recon completed; readers, writers, seams, and routing invariants traced. | Execute PR 1 (Phase 1 telemetry isolation to host directory). |

Baseline SHA: `6261a789d411a78779ad4a630b2ff480ddaa552b`
Mode: Codebase Memory Graph + Source Grep Verification
Lanes: Phase 0 Grounding for PR 1 (Phases 0 & 1)

---

## 1. Executive Summary

Merge landing analysis across the last 40 first-parent commits on `development` demonstrated that 6 shared files accounted for the majority of merge collisions, gate inflations, and dirty-primary checkouts:
- `releases.sql` / `releases.db` (22/40)
- `ROADMAP-DASHBOARD.md` (19/40)
- `LEADERBOARD.md` (18/40)
- `harnesses.sql` / `harnesses.db` (7/40)

Under Phase 0, we traced the exact call paths, readers, writers, and routing invariants that govern these surfaces. We confirmed that `harnesses.db` is an unmapped path in `utils/ci-route.sh`, causing automatic escalation to Tier 3 (the full 367-suite gate, 10–13 minutes) even when accompanying a trivial docs or skill change (e.g. the 13-line edit in PR #531).

---

## 2. Telemetry Writers, Readers, and Seams

### Writers
Every agent turn shim (`claude-turn.py`, `codex-turn.py`, `agy-turn.py`, `deepseek-turn.py`, `aider-turn.py`, `pi-turn.py`, `muse-turn.py`, `commandcode-turn.py`) initializes a `HarnessTurnLogger` from `utils/py/harness_turn_logger.py`:
1. **`HarnessTurnLogger.__exit__`**:
   - Executes `python3 utils/py/harness_app.py log ...`
   - `harness_app.py` resolves `db_path = get_db_path()`
   - Inserts row into `invocation_logs`
   - Executes `dump_sql(conn, sql_p)`
2. **`HarnessTurnLogger.record_evaluation`**:
   - Executes `python3 utils/py/harness_app.py eval ...`
   - Inserts row into `evaluations`
   - Executes `dump_sql(conn, sql_p)`
   - Executes `generate_markdown(conn, md_p)`

### Readers
- `utils/py/harness_app.py` CLI: `check` (integrity check), `dump` (dump to SQL), `gen` (markdown view generation), `blog gen` (case study synthesis).
- Test suites: `test/gh174-harness-registry.sh`, `test/gh346-telemetry-row-written.sh`, `test/gh450-model-catalog-pin.sh`.

### The Seam Defect
When `XYZ_HARNESS_DB` is unset, `get_db_path()` defaults to:
`os.path.join(get_repo_root(), "harnesses.db")`
This causes every turn to write into the tracked checkout, dirtying `harnesses.db` and dumping `harnesses.sql`.

---

## 3. Router Invariants and Replay Verification

In `utils/ci-route.sh`:
- `subsystem_of()` maps known subsystem files.
- `harnesses.db` and `harnesses.sql` are **unmapped**.
- Non-doc unmapped files fall through to:
  `tier=3`
  `tier_reason="unmapped path: $unmapped"`

### Witnessed Replay Controls:
```bash
$ printf "skills/unstuck/SKILL.md\n" | bash utils/ci-route.sh push
docs_only=true
route=docs
tier=1
tier_reason=docs-only

$ printf "harnesses.db\n" | bash utils/ci-route.sh push
docs_only=false
route=fast
tier=3
tier_reason=unmapped path: harnesses.db

$ printf "skills/unstuck/SKILL.md\nharnesses.db\n" | bash utils/ci-route.sh push
docs_only=false
route=fast
tier=3
tier_reason=unmapped path: harnesses.db
```
**Finding:** Relocating `harnesses.db` out of the working tree immediately prevents this unmapped escalation, allowing skill edits to remain at Tier 1 (docs-only).

---

## 4. Established Runtime Hierarchy & Path Precedence

The repository already establishes `~/.xyz/` as the host-local, out-of-tree runtime hierarchy (`~/.xyz/device_config.json`, `~/.xyz/board_sync_state.json`, `~/.xyz/salvage/`).

`skills/agent-chorus/scripts/agent_chorus.py` establishes the canonical pattern for stable repository identity:
- Normalizes canonical repository root via `git rev-parse --show-toplevel` and `--git-common-dir` (worktree-aware).
- Extracts remote origin URL and computes a 12-char SHA-256 suffix: `f"{slugify(name)}--{short_id}"` (e.g., `xyz-forge--d67b89424bc7`).

### Target Out-of-Tree Resolution Order for `harness_app.py`:
1. `XYZ_HARNESS_DB` environment variable (if set, always wins).
2. Stable macOS default: `~/.xyz/projects/<stable-project-key>/telemetry/harnesses.db`.
3. Fallback: repo-relative `./harnesses.db` if home directory is unavailable.

### SQL Dump and View Resolution:
- `XYZ_HARNESS_SQL` > alongside DB (`base + ".sql"`).
- `XYZ_HARNESS_GENERATED_MD` > alongside DB or `HARNESS-MODELS-REGISTRY.generated.md`.
- `XYZ_HARNESS_DOCS_DIR` > `docs/` or override.

### Fixture Containment Invariant:
All test suites and harnesses running in test mode must explicitly set `XYZ_HARNESS_DB` to a fixture-contained path, asserting:
- Zero writes to user `~/.xyz/`.
- Zero writes to tracked working tree.

---

## 5. Curated Registry vs Runtime Telemetry Split

The SQLite database contains two distinct classes of data:
1. **Curated Versioned Registry**:
   - `devices`, `user_configs`, `harnesses`, `models`.
   - Seeded from `seed_canonical_registry()`.
   - Deliberate edits (e.g. Model-catalog pins in GH-450) can be dumped to versioned git assets.
2. **Live Runtime Telemetry**:
   - `invocation_logs`, `evaluations`, `blog_stories`.
   - Live turn outputs that append to the shared host runtime DB.

When initializing an out-of-tree database for the first time:
`harness_app.py init` or auto-init will seed the canonical registry tables from the committed baseline (or `seed_canonical_registry()`), ensuring foreign keys to `harnesses` and `models` succeed on the first turn without requiring manual bootstrapping.

---

## 6. PR 1 Scope Boundary (Phases 0 & 1)

- **In Scope for PR 1**:
  - Out-of-tree telemetry path resolution in `utils/py/harness_app.py`.
  - Auto-initialization / seeding of the out-of-tree DB so turns never fail foreign key checks.
  - Verification that ordinary turn shims leave git status 100% clean.
  - Hermetic fixture test suite validating zero home writes, row preservation, and idempotent import.
- **Out of Scope for PR 1 (Deferred to PR 2 & Beyond per Consensus)**:
  - PR 2: Modifying `githooks/dashboard-staleness-guard.sh` or `wave_reconcile.py` view generation.
  - PR 3: Untracking `releases.db` (conditional spike).
  - PR 4: Adding four profile classifications to `utils/ci-route.sh`.
  - PR 5: Contention serialization & benchmarking.

## Merge evidence

- PR #550 merged 2026-09-11 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
- PR #553 merged 2026-09-11 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
