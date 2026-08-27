---
title: "Jog: serial immediate-queue execution engine and skill (Phase 1)"
status: Proposed (1-INBOX — not yet active)
created: 2026-08-26
owner: noel
gh_issue: 259
source: https://github.com/HiQS-Labs/XYZ-forge/issues/259#issuecomment-5433577198
doc_type: feature
complexity: 3
risk: 2
effort: 3
phases: 1
ratings_provisional: true
related:
  - GH-259 (parent issue: User Guide and Skills)
  - GH-27 (Roadmap Dashboard)
  - GH-32 (Releases App / SQLite Ledger)
  - GH-354 (Driver Lock Matrix)
  - GH-564 (Fixture Containment & Clone Isolation)
goal: >
  Implement jog (Phase 1) as a strictly serial immediate execution queue reusing the releases DB,
  driver lock, single-phase drive, and swarm-preflight without wave planning or concurrency tax.
---

# GH-259 · Jog: Serial Immediate-Queue Execution Engine and Skill (Phase 1)

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Why

Jog addresses task dispatch latency when an operator has an immediate, obvious queue of tasks
to run *today* without requiring the heavy ceremony of marathon wave planning.

### Structural Speed Rationale

1. **Faster firing without parallelism tax:** A marathon's setup cost stems largely from
   calculating collision-safe parallel waves (`marathon-plan.sh`), analyzing write-set disjointness,
   enforcing zone caps, and coordinating concurrent lanes. Jog is **strictly serial** — one task at
   a time, no lanes, no waves, and no concurrency — so all wave-planning computation is skipped.
2. **Overlap check as an advisory sort hint and re-anchor signal:** Write-set collision analysis
   exists solely to protect parallel lanes from stomping each other. In a serial queue, overlap
   serves as:
   - A **sort hint**: grouping adjacent tasks touching the same seam to minimize context reload.
   - A **re-anchor signal**: requiring a clean `merge-before-advance` boundary into `development`
     for same-seam tasks so task N+1 executes directly against task N's landed state rather than
     accumulating deferred merge conflicts.
   - A **staleness flag**: warning if an earlier task's modifications warrant refreshing a
     subsequent task's brief before dispatch.

## Architectural Boundaries: Re-use vs. New Surface

Jog is **not** a parallel pipeline or separate unindexed state store. It re-uses proven harness machinery:

- **`swarm-preflight` per task**: runs the cheap `already-landed` probe (`exit 4`) and readiness checks
  at pop time to guarantee no already-shipped work is rebuilt.
- **Driver lock (`relay-driver.lock`)**: preserves the one-driver-per-clone invariant (GH-42, GH-354).
  Jog serializes internally while actively excluding concurrent marathons or relays on the same clone.
- **Single-phase drive**: executes tasks via degenerate single-phase `relay-drive`/`marathon-drive`
  invocations with existing containment shims, turn protocols, and transcripts.
- **Ledger closeout**: uses `manifest ship --evidence` and post-merge reconcilers (`wave_reconcile.py`).

## Key Concepts & Review Adjudications

> **Revised after Codex QA (`relay-system/2026-08-26/gh259-jog-plan-qa.md`) and maintainer review.**
> Addresses all blocking findings from the review relay, resolving contract promotion, probe quality,
> and the landing confirmation boundary.

1. **Dedicated `jog_queue` relation over roadmap overload (Codex Finding 2):**
   `roadmap_items` enforces a unique constraint on `(repo_id, gh_number)` and owns portfolio display
   sections. Adding a second jog row for an existing issue would violate uniqueness or mutate PDDA
   portfolio position. Phase 1 introduces a dedicated `jog_queue` table in `releases.db` (and SQL dump)
   keyed to `(repo_id, gh_number)` with columns `(id, repo_id, gh_number, position, status, created_at, updated_at, attempt_count, lease_pid, failure_reason)`.
   *(Note: Tier-2 vendored setups with `.xyz/` inherit the `jog_queue` schema migration automatically).*
2. **Short writer transactions, leasing & crash recovery (Codex Finding 3):**
   Jog never holds SQLite writer locks across long-running turn-taker dispatches. State transitions
   (`pending -> running -> completed|parked|failed`) execute inside short, atomic transactions.
   - **Startup reconciliation:** On launch, `jog run` inspects any existing `running` rows. If the
     recorded `lease_pid` is dead, it resets the lease to `pending` (or `parked` if attempt cap exceeded)
     before selecting the next item.
   - **Signal handling:** Traps `SIGINT`/`SIGTERM` to cleanly release held leases and drop driver locks.
   - **Operator controls:** Provides explicit CLI commands to retry failed items (`jog retry <n>`) or
     skip blocked items (`jog skip <n>`).
   - **Audit archival:** `jog clear` archives terminal rows rather than hard-deleting them, preserving
     attempt and failure receipts for subsequent hygiene sweeps.
3. **Outer driver lock composition (Codex Finding 4):**
   The `jog run` supervisor acquires `relay-driver.lock` via `rtl.driver_lock_path()`, exports
   `RELAY_DRIVER_LOCKED=1`, and registers trap cleanup. Subordinate `relay-drive` invocations inherit
   the environment variable and recognize the outer supervisor, proceeding without lock refusal.
4. **Two-stage capture, fire promotion & probe hardening (Codex Findings 5 & 7):**
   - **Capture Stage:** Natural conversational capture (`"jog GH-123"`, `"jog task above"`).
     `"jog task above"` extracts session context, opens the tracking issue via `gh issue create`
     (issue-first SOP), parks a roadmap row immediately (`releases roadmap add`), echoes the resolved
     issue number/title for operator confirmation, and enqueues the `jog_queue` row.
   - **Fire Stage Promotion & Probe Hardening:** `swarm-preflight` requires an active doc in `PROJECT/2-WORKING/` with
     `fix_probes`. However, auto-scaffolded probes from an LLM are an acute failure mode (a trivially passing
     probe like `exit 0` lets preflight go green on garbage). Jog hardens this boundary:
     - **Probe linting:** Static assertion verifying probe commands are non-trivial, syntactically valid,
       and target genuine test/gate surfaces.
     - **Default operator confirmation:** In interactive mode, `jog run` presents the auto-promoted contract
       and drafted probes for operator approval before dispatching preflight.
     - **Unattended guard:** In non-interactive runs, auto-scaffolding is refused unless the capture already
       carried validated probe definitions, parking the item with `unreviewed-probe-contract`. Already promoted
       `2-WORKING` docs with existing verified contracts proceed directly.
   - **Preflight Exit Mapping:**
     - `ready` -> proceed to single-phase drive.
     - `already-landed` (exit 4) -> mark `completed` / auto-drop with recorded receipt.
     - `not-ready` / probe failure -> mark `parked` with diagnostic reason, skip item, and prompt operator.
5. **Landing confirmation boundary & re-anchoring (Codex Findings 6 & 8):**
   - **Default Landing Policy (Pause for Operator Confirmation):** Consistent with repository governance
     and the orchestrator role split (`AGENTS.md` GH-221), `jog run` **defaults to pausing at each landing
     boundary** to prompt the operator for confirmation (outer review of base branch, diff size sanity,
     and gate pass receipts) before merging PRs into `development` and advancing.
   - **`--auto-merge` Opt-In:** An explicit CLI flag for unattended runs where the operator intentionally
     authorizes automatic merging of passing PRs on same-seam tasks before advancing.
   - **Same-Seam Re-anchoring (`merge-before-advance`):** For overlapping/adjacent tasks, task N's PR
     is merged into `development` before task N+1 branches, guaranteeing task N+1 builds directly on
     task N's committed state and eliminating deferred merge conflicts.
   - **Disjoint Tasks:** Independent tasks touching non-overlapping paths branch from current `origin/development`.
   - **Teardown Cleanliness:** Between serial items, the supervisor verifies throwaway worktree cleanup,
     clean working tree status, and gate pass receipts before advancing.
   - **Stacking:** Explicit stacked-branch chaining is deferred as a future opt-in mode.

## Phase 1 Implementation Plan

### 1. State as a Dedicated `jog_queue` Schema in Releases DB
- Add `jog_queue` relation to `releases.db` and dump schema in `utils/py/releases_app.py`:
  - Fields: `id`, `repo_id`, `gh_number`, `position` (integer order), `status` (`pending`, `running`, `completed`, `parked`, `failed`), `created_at`, `updated_at`, `attempt_count`, `lease_pid`, `failure_reason`.
- CLI verbs in `releases_app.py` / `jog` subcommands:
  - `jog add <issue-or-capture>`: inserts item at end of queue (or specified position).
  - `jog list`: renders active queue ordered by position with status, attempts, and lease state.
  - `jog bump <n>`: manual head-of-line position override.
  - `jog drop <n> --reason <r>`: marks item dropped with recorded rationale.
  - `jog retry <n>`: resets parked/failed item back to `pending`.
  - `jog skip <n>`: advances past blocked item to next in queue.
  - `jog clear`: archives completed/parked terminal rows.

### 2. Capture Skill (`skills/jog/`)
- Natural-language / conversational triggers:
  - `"jog GH-123"`: validates the open issue against `gh`, verifies/creates minimal 1-INBOX capture doc if missing,
    parks roadmap row if unparked, and inserts the `jog_queue` row.
  - `"jog task above"`: session-context capture that files the GitHub issue first (issue-first SOP), parks roadmap
    entry, confirms resolved issue identity with operator, and queues it.

### 3. Execution Driver (`jog run`)
- Reconciles any orphan `running` leases on startup.
- Pops head of the queue (`pending` -> `running` lease).
- Acquires outer driver lock and exports `RELAY_DRIVER_LOCKED=1`.
- **Contract Promotion & Probe Linting:** If capture is in `1-INBOX/`, promotes to `2-WORKING/` with scaffolded status table,
  lints probes, and prompts operator for confirmation (or parks if unattended without prior probe definitions).
- Executes `swarm-preflight --gh-issue <n>`:
  - `ready` -> fires single-phase drive (`relay-drive` / turn shim).
  - `already-landed` -> marks `completed` / auto-drops with receipt.
  - `not-ready` / error -> marks `parked` with error reason, reports diagnostic, and prompts operator.
- **Landing & Verification:** Generates PR targeting `development`, verifies gate pass receipts, and **pauses for operator
  confirmation by default** before merging into `development` (or auto-merges if `--auto-merge` is passed) and re-anchoring
  same-seam tasks.
- Verifies clean worktree teardown before selecting the next queue item.
- Loops until queue is empty or a task escalates.

### 4. Marathon Handoff (`jog to-marathon`)
- Exports the active jog queue to `marathon-triage` as a candidate set when the queue expands beyond
  single-day serial execution. Ranking, wave planning, and concurrency zoning are delegated to marathon tools.

### 5. Automated Test Suite
- Registered test suite (`test/jog-queue.sh` or `test/gh259-jog.sh`) covering:
  - Queue CRUD, ordering overrides (`jog bump`), and retry/skip controls.
  - Schema integrity, dump, and rebuild consistency.
  - Startup orphan-lease recovery and signal traps.
  - 1-INBOX fire-time promotion, probe linting, and `already-landed` auto-drop handling.
  - Landing pause behavior (default) vs `--auto-merge` opt-in.
  - Outer driver-lock mutual exclusion against concurrent marathons/relays.
  - Serial execution with seam overlap and re-anchoring.
  - `jog to-marathon` queue export.

## Non-goals (Deliberately Out of Scope for Phase 1)

- Automated scoring / algorithmic ranking (jog ordering is operator-driven by design).
- Concurrency or multi-lane parallelism (owned by marathon).
- The `whatsnext-xyz` catchall router (Phase 2 — will query jog state as an oracle).
- Complex stacked-branch graph management (Phase 1 uses `merge-before-advance` for overlapping seams).
