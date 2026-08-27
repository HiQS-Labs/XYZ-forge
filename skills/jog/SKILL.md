---
name: jog
description: Immediate serial task queue execution engine and conversational capture skill. Use when an operator wants to queue, prioritize, inspect, or execute a sequence of tasks one at a time today without marathon wave planning or concurrency overhead. Re-uses the Releases SQLite DB, driver lock, single-phase drive, and swarm-preflight.
---

# /jog — Serial Immediate-Queue Execution Engine

`jog` manages a serial queue of tasks for immediate execution today. It provides conversational task intake and runs tasks one by one with zero concurrency overhead, using `releases.db` (`jog_queue` table), the outer `relay-driver.lock`, single-phase `relay-drive`, and `swarm-preflight`.

## Conversational Triggers

When the operator speaks naturally:
- `"jog GH-123"`:
  1. Validates the issue via `gh issue view 123`.
  2. Ensures a capture doc exists (in `PROJECT/1-INBOX/` or `PROJECT/2-WORKING/`).
  3. Ensures the issue is parked in the roadmap ledger (`releases roadmap add`).
  4. Enqueues the issue into `jog_queue` (`releases jog add GH-123`).
  5. Echoes: `jog: enqueued GH-123 at position N`.

- `"jog task above"`:
  1. Extracts the immediate task/bug discussion from recent context.
  2. Creates the tracking GitHub issue via `gh issue create` (issue-first SOP).
  3. Writes the initial capture doc to `PROJECT/1-INBOX/GH-<num>-<title>.md`.
  4. Parks the issue in the roadmap ledger (`releases roadmap add`).
  5. Enqueues into `jog_queue` (`releases jog add <num>`).
  6. Confirms the newly created issue number and queue position with the operator.

## CLI Commands

All commands run through `python3 utils/py/releases_app.py jog <subcommand>` (or `releases jog <subcommand>` when aliased):

```text
releases jog add <GH-NUM|doc-path> [--pos N] [--dry-run]
    Enqueue a task at the end of the queue (or at a specific position).

releases jog list [--all] [--json]
    Display active queue items (or all historical items with --all).

releases jog bump <GH-NUM>
    Move an active task to position 1 (head of line). Refuses terminal rows.

releases jog drop <GH-NUM> --reason "<text>" [--force]
    Mark a task as dropped with an auditable reason. Refuses already-completed items without --force.

releases jog retry <GH-NUM>
    Reset a failed, parked, or dropped task back to pending.

releases jog skip <GH-NUM> [--reason "<text>"]
    Park the current head task and advance to the next item.

releases jog clear
    Archive completed/dropped/parked terminal items.

releases jog to-marathon
    Export active jog items to marathon format.

releases jog run [--auto-merge] [--builder agy|codex|aider] [--max-tasks N] [--simulate] [--dry-run]
    Execute the serial jog runner loop.
```

## Runner Execution Lifecycle (`jog run`)

1. **Outer Driver Lock & Hermetic Dry-Run:**
   - `--dry-run`: Hermetic simulation with zero locks and zero mutations (leaves queue and DB untouched).
   - Real run: Acquires `relay-driver.lock` via `rtl.driver_lock_path()`, sets `RELAY_DRIVER_LOCKED=1`, and registers a clean exit handler. Concurrently running marathons or relays in the same clone are safely excluded (GH-42 / GH-354).

2. **Receipt-Backed State Transitions:**
   Every runner transition (lease acquisition, status changes, orphan reconciliation) goes strictly through `perform_write` in `releases_app.py`, ensuring full journal, receipt-chain, and dump integrity. `lease_pid` is excluded from the committed `releases.sql` dump to eliminate merge conflicts.

3. **Startup Lease Reconciliation:**
   Inspects `jog_queue` for orphaned `running` rows (dead `lease_pid`). Resets them to `pending` (or `parked` if `attempt_count >= 3`).

4. **Fire-Time Promotion & Probe Linting:**
   If a task's capture doc is in `PROJECT/1-INBOX/`, `jog run` promotes it to `PROJECT/2-WORKING/`, formats the status table, and lints its `fix_probes`:
   - Rejects trivial or dummy probe patterns (e.g. `exit 0`, `true`).
   - Requires referenced probe scripts/globs to resolve to actual files.
   - In interactive mode, prompts operator to approve drafted probes before running preflight.
   - In unattended mode, unreviewed auto-scaffolding without verified probes is parked with `unreviewed-probe-contract` to prevent false-green runs.

5. **Swarm Preflight:**
   Runs `swarm-preflight --gh-issue <n>`:
   - `ready` (exit 0) -> fires single-phase drive.
   - `already-landed` (exit 4) -> marks `completed` with auto-drop receipt.
   - `not-ready` -> marks `parked`, records error, and prompts operator.

6. **Single-Phase Drive Dispatch:**
   Scaffolds `relay-system/<date>/gh<n>-jog-drive.md`, claims and releases the task token via `bin/tick`, and invokes `relay-drive.sh --relay-file <file> --agent-cmd <shim> --relay-task <task>` with nested driver lock protection.

7. **Landing Boundary & `--auto-merge`:**
   - **Default (Interactive):** Pauses at each landing boundary for human confirmation. On confirm: merges PR into `development` and re-anchors the checkout. On decline: marks row `parked` (`awaiting-landing`) so unmerged tasks are never misrepresented as `completed`.
   - **Unattended without `--auto-merge`:** Parks row as `parked` (`awaiting-landing (unattended run without --auto-merge)`) and halts advance.
   - **`--auto-merge`:** Automatically merges passing PRs on same-seam tasks into `development` and re-anchors the checkout before advancing.

8. **Teardown Cleanliness:**
   Verifies clean worktree disposal, clean working tree status, and gate receipts between serial items.
