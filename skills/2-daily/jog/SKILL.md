---
name: jog
description: Immediate serial task queue execution engine and conversational capture skill. Use when an operator wants to queue, prioritize, inspect, or execute a sequence of tasks one at a time today without marathon wave planning or concurrency overhead. Re-uses the Releases SQLite DB, driver lock, Marathon's reviewed one-phase executor (default since GH-280), and swarm-preflight.
---

# /jog — Serial Immediate-Queue Execution Engine

`jog` manages a serial queue of tasks for immediate execution today. It provides conversational task intake and runs tasks one by one with zero concurrency overhead, using `releases.db` (`jog_queue` table), the outer `relay-driver.lock`, and `swarm-preflight`. Since the GH-280 recalibration, per-task execution defaults to Marathon's reviewed one-phase driver (`--executor marathon`); `--executor relay` keeps the legacy single-phase `relay-drive` path as the documented rollback during a bounded compatibility window.

## Conversational Triggers

When the operator speaks naturally:
- `"jog GH-123"`:
  1. Validates the issue via `gh issue view 123`.
  2. Ensures a capture doc exists (in `PROJECT/1-INBOX/` or `PROJECT/2-WORKING/`).
  3. Ensures the issue has a roadmap ledger row created at pickup with real rating (`releases roadmap pickup --issue-num 123`).
  4. Enqueues the issue into `jog_queue` (`releases jog add GH-123`).
  5. Echoes: `jog: enqueued GH-123 at position N`.

- `"jog task above"`:
  1. Extracts the immediate task/bug discussion from recent context.
  2. Creates the tracking GitHub issue via `gh issue create` (issue-first SOP).
  3. Writes the initial capture doc to `PROJECT/1-INBOX/GH-<num>-<title>.md`.
  4. Creates the roadmap row at pickup (`releases roadmap pickup --issue-num <num>`) with rating from the issue body/doc.
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

releases jog resume <GH-NUM>
    Reconcile durable Marathon state for an item (spends no token).

releases jog retry-gate <GH-NUM>
    Re-run ONLY the gate against the same head SHA (no builder turn).

releases jog retry-build <GH-NUM> --target-root <disposable-full-clone>
    Fresh Marathon attempt on a fresh execution id (history preserved).

releases jog land <GH-NUM> [--pr N]
    Verify committed delivery after hosted or local reconciliation and complete the primary queue row.

releases jog reconcile <GH-NUM>
    Idempotent replay entry for jog land (same verification and steps).

releases jog run --target-root <disposable-full-clone> [--executor relay|marathon] [--reviewer <agent>] [--builder agy|codex|aider] [--auto-merge] [--max-tasks N] [--simulate] [--dry-run]
    Execute the serial jog runner loop. Default executor is marathon (GH-280); --reviewer is
    required (builder and reviewer must differ). --executor relay selects the legacy rollback
    path during its compatibility window.
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
   - With no frontmatter `fix_probes`, accepts the `## Swarm Preflight Contract` JSON `fix_probes` when every entry is well-formed (known `type`; non-empty `path`, grep `pattern`, or a `command` `cmd` that passes the same lint). Promotion evaluates no probe: preflight judges "unfixed" next, in its ref-pinned worktree (GH-1232).
   - In interactive mode, prompts operator to approve drafted probes before running preflight.
   - In unattended mode, unreviewed auto-scaffolding without verified probes is parked with `unreviewed-probe-contract` to prevent false-green runs.

5. **Swarm Preflight:**
   Runs `swarm-preflight --gh-issue <n>`:
   - `ready` (exit 0) -> fires the executor (Marathon one-phase drive by default).
   - `already-landed` (exit 4) -> marks `completed` with auto-drop receipt.
   - `not-ready` -> marks `parked`, records error, and prompts operator.

6. **Marathon Executor Dispatch (default; GH-280):**
   Per-task execution is delegated to Marathon's reviewed one-phase driver: Jog validates the
   preflight packet's `marathon-invocation@1` contract, invokes the drive, and projects the
   validated `marathon-drive/result@1` receipt. Attempts, review, gates, branch/commit, and PR
   identity are Marathon-owned; Jog records a receipt-backed projection, never a guess. Builder
   and reviewer are separated: `--builder` defaults to the cost-blind lanes (`agy`; `codex`/`aider`
   selectable) while `--reviewer <agent>` is required, must differ from the builder, and has no
   silent default. `--executor relay` keeps the legacy single-phase `relay-drive.sh` dispatch as
   the explicit rollback path during a documented compatibility window; it will be removed in its
   own dedicated commit one release cycle after the flip — do not build new usage on it.

7. **Receipt-Backed Landing & `--auto-merge`:**
   A row is never marked `completed` on a self-report. `jog land` verifies GitHub truth first —
   merged state, merge-SHA reachability, PR identity (repo, base, head, head SHA), and qualifying
   gate evidence after hosted or local `wave_reconcile` has recorded reconciliation — then completes
   the primary row and records its landing proof.
   - **Real runs do not merge.** `jog run --auto-merge` is refused before any lease, and a published
     task parks awaiting landing; independent pending work may continue. Land through
     merge-cleanup, whose Jog hook calls `jog land` after reconciliation (see the interim publication
     checkpoint below).
   - **`--simulate` only:** the interactive confirm and `--auto-merge` paths remain for the hermetic
     simulation and never touch a real PR.

8. **Teardown Cleanliness:**
   Verifies clean worktree disposal, clean working tree status, and gate receipts between serial items.
   At campaign end, point the operator at `/merge-cleanup` to retire the task clone (GH-690).

## Primary writer and committed evidence (GH-1108, delivery 1)

Invoke mutating Jog commands in the canonical primary on `development`. Bind that primary
explicitly once for its origin; task clones do not configure themselves as primaries:

```bash
# Run in the checkout the operator selected as the primary.
key="$(PYTHONPATH=utils/py python3 -c 'from harness_paths import primary_config_key; print(primary_config_key("."))')"
git config --global "$key" "$PWD"
```

The origin-specific pin is shared with merge-cleanup's explicit `--primary`: a mismatched
path refuses. Jog also refuses unconfigured writers and non-development primaries before
queue/cache writes. Read-only list/export/dry-run do not need a primary pin.

Pass a separate full clone with the same origin to `jog run --target-root <clone>` or
`jog retry-build --target-root <clone>`. It must have no pre-existing ledger delta. Preflight,
Marathon, Tick and builder/reviewer work run in that clone. The primary retains the queue,
lease and restart cache. Execution must leave the clone's `releases.db`/`releases.sql` unchanged;
contract promotion commits only its doc pair there. The primary roadmap is repointed by
normal reconciliation after that document movement lands.

After approval, Jog commits and pushes exactly one portable evidence bundle on the lane:
`TESTS-RESULTS/<date>+GH-<n>/jog/<execution-id>/`. It contains the original Marathon result,
copied gate receipt, provenance and `receipt.json` with relative pointers and content hashes.
The original result's historical absolute paths are retained as source data; landing reads
the committed bundle pointers instead. Publication failure parks the item; resume can retry
publication without another builder turn. `.tick/jog` remains a local restart cache, never a
landing prerequisite.

**Interim publication checkpoint:** delivery 1 does not automatically push queue transitions.
Before merge-cleanup, inspect the primary's status, index and local supervisor commits. Commit
only owned Jog ledger/view paths explicitly, then normally push development. Confirm a clean,
published, fast-forward-ready primary. Unrelated changes or a rejected hand push stop and
preserve state; do not bypass Phase 0. The automatic direct-push/rebuild
path is a separate PR so it can be reverted independently. `--auto-merge` on native Jog dispatch/retry refuses before leasing during this interim;
it cannot skip the publication checkpoint. Use merge-cleanup for actual landing;
its mapped Jog hook runs after hosted or local reconciliation and before the existing final post-merge
commit/push. A direct `jog land` call likewise needs that final publication checkpoint.

### Checkpoint publication (`--checkpoint-root`): remote contact and legal stops (GH-1453)

A `jog run --checkpoint-root <publication-clone> --max-tasks N` wake works from the primary's
**local state**. It does not fetch at start and does not need the primary to equal
`origin/development`. It contacts `origin/development` only during publication, after the last task.
(Per-task preflight in the execution clone still fetches, so each task's PR starts from current
`development`; that is separate from the checkpoint.)

**"Competing writer", defined once.** A competing writer is anything else that changes *this
wake's own queue rows* while the wake runs, from this clone or from another clone or machine. Jog
handles each case itself:

- A second `jog run` in the same primary clone is refused by the supervisor lock.
- A change pushed from elsewhere to the `status`, `attempt_count` or `failure_reason` of a row this
  wake wrote is the overlap stop at publication. A change to only that row's queue position is not
  a stop; the published order is the remote's.
- A queue write made in this primary by another process during the wake counts as part of the wake
  when publication has to replay it (that is, when `development` moved). A lease or a status write
  (for example from `jog resume`) is replayed with the rest; any other queue verb (`add`, `drop`,
  `skip`, `bump`, `clear`, `retry`) or an orphan-lease reconcile is a stop.

A session that pushes any other ledger change to `development` (a reconcile, intake, a rating,
another coordinator's rows) is not a competing writer. Run directives, runbooks and issue checklists
**cite this section** for Jog's stop conditions; they do not restate or paraphrase them.

**A moved `development` is reconciled automatically.** At publication Jog merges the remote into
the primary, takes the remote ledger, replays this wake's own queue writes through the canonical
writers, runs `utils/releases-merge-resolve.sh` and publishes the merge. It prints
`jog: reconciled wake checkpoint onto moved development <sha>` and then
`jog: published primary checkpoint <sha>`. That is a normal successful run.

**These are the only checkpoint stops.** For checkpoint publication, a stop exists only when Jog
itself prints `jog: checkpoint held: <message>` and exits 2. The list below is closed: each entry is
the fixed start of a message, and Jog appends the details (the rows, the paths, the failing command).
Nobody adds to it. A conflict that an agent or a runbook predicts, with no command having failed, is
not a stop: continue.

This list covers checkpoint publication only. It does not override anything else Jog reports: a
failed task or gate, a refusal that is not a checkpoint stop (the primary pin, the execution clone,
the supervisor lock), or an unexpected error or traceback. Those are real outcomes; report them
verbatim. An error you do not recognise is an error to report, never permission to continue.

At start (nothing has run yet):

- `checkpoint root must be a separate full clone with the same origin`
- `checkpoint refuses unrelated changes` (a dirty path outside the ledger files and adopted HTML views)
- `checkpoint refuses pre-existing ledger changes without an active journal`
- `checkpoint requires a local origin/development ref`
- `checkpoint refuses unpublished local commits`

At publication:

- `development changed the same Jog queue row(s) as this wake` (a real overlap; the rows are named)
- `development moved and conflicts outside the ledger` (the primary's own files conflict with the remote)
- `checkpoint cannot replay this wake onto a moved development` (the wake includes an orphan-lease
  reconcile or an operator queue verb, which are not replayed against another ledger)
- `checkpoint replay did not reproduce the wake's queue state`
- `canonical writer refused the replay of`
- `development kept moving through` (three reconcile attempts in one run)
- `development moved and this checkpoint journal predates automatic reconcile`
- `checkpoint refuses a merge in progress that this wake did not start` (finish or abort your own
  merge in the primary first; Jog restores only a merge that matches the target it recorded and
  whose `HEAD` is still its checkpoint, so a hand-made merge of that same commit from that same
  `HEAD` would be treated as Jog's)
- `unmerged or unstaged changes remain after the ledger merge resolver`
- `checkpoint reconcile could not merge development`
- `ledger merge resolver refused`
- `checkpoint ledger command failed` (`releases check` or `check --rebuild`; the message quotes it)
- `checkpoint primary HEAD changed outside this wake`
- `checkpoint has new changes after its recorded commit`
- `checkpoint publication clone is dirty; preserve it before retry`
- `checkpoint publication clone must be on development`
- `publication clone contains commits beyond this checkpoint`

Any other message after `jog: checkpoint held:` is a command or system call that failed and is
quoted as it failed: usually `git <command> failed: <git's own error>` (this includes the publication
clone's push gate), otherwise a file or database error raised during the reconcile.

**At a stop:** state is preserved. A stop while the merge is open restores the primary to its
checkpoint commit; a stop after a reconcile merge keeps that merge. If a run died while its own
merge was open, the rerun restores it first. Fix the named cause if there is one, then **rerun the
same command**. What the rerun does depends on whether an unpublished checkpoint is retained, not
on which message was printed: if one is (the wake had already committed its checkpoint), the rerun
retries publication first and dispatches no task; if none is, the rerun is an ordinary start and may
dispatch tasks. Never force-push, never `git reset` the primary, and never hand-edit `releases.db` or
`releases.sql`.

Landing requires merged GitHub truth, a validated green gate on the original approved SHA,
clean `releases check`, hosted or local reconciliation evidence, and merge reachability from
freshly fetched `origin/<integration>` and primary HEAD. A moved head must match this PR's
fetched head; queue completion does not require exact approval ancestry or a permitted-file
tail. It records delivery, not approval or test coverage of later edits. `landing.json` records
`completion_policy: merged-pr`, the original approved/tested SHA, reported review head/candidate
(null when absent), landed PR head, merge SHA and reconciliation evidence. Publication and
retry-gate admission retain their existing checks. Replay uses canonical queue truth and emits
no duplicate completion transition.

## Recovery Verbs

After an interrupted or failed item, pick the verb that matches what actually needs redoing:

- `jog resume <GH-NUM>` — the crash/restart remedy: reconciles the durable Marathon state and
  re-projects a valid terminal receipt without spending a token (parks instead of silently
  re-firing when state is missing or contradictory).
- `jog retry-gate <GH-NUM>` — the "approved relay, red gate" remedy: re-runs ONLY the gate against
  the same head SHA with no builder turn, for failures fixed outside the build (e.g. operator
  intake-hygiene fixes).
- `jog retry-build <GH-NUM>` — the real rebuild: a fresh Marathon attempt on a fresh execution id
  when the build itself must be redone; all prior Tick history and execution records are preserved.

### Crash leftovers

Keep the verb order above: run `resume` first (spends no token), then `retry-gate` (approved build, failed gate), then `retry-build` (real rebuild). When a crashed run parks on cold-start (`cold-start-paused` / no valid result receipt), the crashed target clone may still hold four leftovers. For each, separate **"no process owns it"** from **"no unique work remains"**, and preserve on any uncertainty:

1. **Isolation worktree (`rtl-wt.*`):** inspect `git worktree list` and confirm no live process holds the path (`lsof`). A worktree with no live owner can still hold unpublished edits, so check `git -C <wt> status` to confirm no unique work remains before removing it (`git worktree remove`).
2. **Claimed tick token (`MARATHON-…-TURN`):** `tick info <token>` names an agent, not a pid. Establish the owning execution from the driver lock and the Jog row's `lease_pid` (`kill -0`). The token only clears once that execution is confirmed dead.
3. **Clone driver lock (`.git/relay-driver.lock`):** confirm the pid in it is not alive (`kill -0`). Once no process owns it, the driver reclaims a stale lock itself on the next run.
4. **Unpushed local marathon branch (`marathon/gh-…`):** this is evidence to **preserve**, never proof that removal is safe.

Before anything is cleared, rely on `/merge-cleanup`'s existing checks — dirty files, unpublished refs, dependent worktrees, and live handles — rather than repeating them by hand.

**Fresh-clone rule for `retry-build`:** after a cold-start park, `jog retry-build --target-root <clone>` targets a **fresh disposable full clone**, never the crashed one. The crashed clone is retired through `/merge-cleanup`, which preserves an unpushed branch until the operator says it is disposable.
