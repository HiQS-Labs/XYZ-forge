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
2. **Overlap check as an advisory sort hint, not a safety gate:** Write-set collision analysis
   exists solely to protect parallel lanes from stomping each other. In a serial queue, task N+1
   executes against the committed state left by task N, so multiple tasks touching the same seam
   are safe by construction. Overlap serves only as:
   - A **sort hint**: grouping adjacent tasks touching the same seam to minimize context reload.
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

> **Revised after Codex QA (`relay-system/2026-08-26/gh259-jog-plan-qa.md`).** The original proposal
> specified embedding jog state as an ad-hoc marker in `roadmap_items`. Codex QA identified the
> table's unique identity constraint `(repo_id, gh_number)` and section-position semantics, leading to
> the dedicated `jog_queue` schema design below.

1. **Dedicated `jog_queue` relation over roadmap overload:**
   `roadmap_items` enforces a unique constraint on `(repo_id, gh_number)` and owns portfolio display
   sections. Adding a second jog row for an existing issue would violate uniqueness or mutate PDDA
   portfolio position. Phase 1 introduces a dedicated `jog_queue` table in `releases.db` (and SQL dump)
   keyed to `(repo_id, gh_number)` with columns `(id, repo_id, gh_number, position, status, created_at, updated_at, attempt_count, lease_pid, failure_reason)`.
2. **Short writer transactions & lease state:**
   Jog never holds SQLite writer locks across long-running turn-taker dispatches. State transitions
   (`pending -> running -> completed|parked|failed`) execute inside short, atomic transactions with
   crash-recovery journaling.
3. **Outer driver lock composition:**
   The `jog run` supervisor acquires `relay-driver.lock` via `rtl.driver_lock_path()`, exports
   `RELAY_DRIVER_LOCKED=1`, and registers trap cleanup. Subordinate `relay-drive` invocations inherit
   the environment variable and proceed without lock contention.
4. **Preflight exit mapping & two-stage capture:**
   - At enqueue time: cheap issue existence and deduplication checks.
   - At fire time: `swarm-preflight` executes against the candidate. Ready tasks fire; `already-landed`
     tasks auto-drop with recorded receipt; `not-ready` tasks are parked/skipped with operator notification.
5. **Serial landing boundary:**
   Each task creates its task branch and opens a PR targeting `development`. Before advancing to the
   next task, the supervisor verifies worktree teardown cleanliness and branch sanity.

## Phase 1 Implementation Plan

### 1. State as a Dedicated `jog_queue` Schema in Releases DB
- Add `jog_queue` relation to `releases.db` and dump schema in `utils/py/releases_app.py`:
  - Fields: `id`, `repo_id`, `gh_number`, `position` (integer order), `status` (`pending`, `running`, `completed`, `parked`, `failed`), `created_at`, `updated_at`, `attempt_count`, `lease_pid`, `failure_reason`.
- CLI verbs in `releases_app.py` / `jog` subcommands:
  - `jog add <issue-or-capture>`: inserts item at end of queue (or specified position).
  - `jog list`: renders active queue ordered by position with status and attempts.
  - `jog bump <n>`: manual head-of-line position override.
  - `jog drop <n> --reason <r>`: removes or marks item dropped with recorded rationale.
  - `jog clear`: flushes completed/parked items.

### 2. Capture Skill (`skills/jog/`)
- Natural-language / conversational triggers:
  - `"jog GH-123"`: validates the open issue against `gh`, verifies/creates a minimal 1-INBOX capture doc if missing,
    and inserts the `jog_queue` row.
  - `"jog task above"`: session-context capture that files the GitHub issue first (issue-first SOP)
    and then queues it.
- Cheap deduplication at capture; full preflight contracts remain deferred to fire time.

### 3. Execution Driver (`jog run`)
- Pops head of the queue (`pending` -> `running` lease).
- Acquires outer driver lock and exports `RELAY_DRIVER_LOCKED=1`.
- Executes `swarm-preflight --gh-issue <n>`:
  - `ready` -> fires single-phase drive (`relay-drive` / turn shim).
  - `already-landed` -> marks `completed` / auto-drops with receipt.
  - `not-ready` / error -> marks `parked` with error reason, reports diagnostic, and prompts operator.
- Verifies clean worktree teardown before selecting the next queue item.
- Loops until queue is empty or a task escalates.

### 4. Marathon Handoff (`jog to-marathon`)
- Exports the active jog queue to `marathon-triage` as a candidate set when the queue expands beyond
  single-day serial execution. Ranking, wave planning, and concurrency zoning are delegated to marathon tools.

### 5. Automated Test Suite
- Registered test suite (`test/jog-queue.sh` or `test/gh259-jog.sh`) covering:
  - Queue CRUD and manual position overrides (`jog bump`, `jog drop`).
  - Schema integrity, dump, and rebuild consistency.
  - `already-landed` auto-drop handling.
  - Outer driver-lock mutual exclusion against concurrent marathons/relays.
  - Serial execution with seam overlap (verifying safety and adjacency hints).
  - `jog to-marathon` queue export.

## Non-goals (Deliberately Out of Scope for Phase 1)

- Automated scoring / algorithmic ranking (jog ordering is operator-driven by design).
- Concurrency or multi-lane parallelism (owned by marathon).
- The `whatsnext-xyz` catchall router (Phase 2 — will query jog state as an oracle).
