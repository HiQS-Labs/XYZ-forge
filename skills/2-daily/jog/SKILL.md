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

## Preparation handoff (GH-1439)

“Prepare N bugs for Jog”, “preflight this queue”, or “make this ready for another
operator/device” uses the following existing workflow before enqueue/dispatch.
Preparation alone does not fire builders. An explicit execution request continues
through these steps into the existing runner without asking again for routine setup.
For multi-lane marathon planning, use start-marathon instead; do not create a second
queue or invent a JSON import format.

1. **Reuse real work and authority.** Reconcile selected issues against current source,
   open PRs, retained candidates and historical queue/native attempts. Name the ordered
   IDs, exact acceptance and write sets; retain existing ratings/counters. Use the
   existing capture/RELEASES writers and independent plan review where required.
   Reuse already-valid preparation rather than repeating inventory or rebuilding a candidate.
2. **Resolve the actual machine and engine.** Record canonical origin, integration ref,
   harness source revision, skill deployment receipt and vendored runtime revision.
   Skills Army HQ owns instruction installation; supported xyz-vendor owns `.xyz`.
   Updating one does not update the other. Verify the harness interpreter and product
   test interpreter separately; a binary named `python3` is not a version/dependency proof.
   Preserve dirty/divergent clones; use the existing full-clone/primary-pin path, not
   destructive cleanup or a hardcoded “main folder” assumption.
3. **Map gates to environments.** Read the target's existing CI/dependency recipes.
   Associate each declared gate with its actual interpreter, dependency set, local service
   prerequisites and working directory. Do not combine incompatible app/service pins.
   Where separate environments are needed, use existing gate commands with explicit
   verified interpreter paths/configuration; do not add a wrapper runner. Prove required
   configuration is nonempty and missing configuration refuses. Keep secrets out of receipts.
   Run relevant baseline checks in disposable full clones; classify existing failures
   separately from the intended bug control. No product/service deployment is implied.
4. **Verify roles and capacity once, near dispatch.** Resolve explicit supported builder
   and independent reviewer identities, exact model/effort/auth route and effective limits.
   Same-provider roles must remain distinct. Reuse the installed route/auth validation
   and one small bounded real request through the selected review route; version/help or
   dry-run is not capacity proof. A successful request is availability now, not reserved
   credits for the whole run. Record UNKNOWN when unavailable; stop on credit/auth failure,
   with no silent model/account fallback. Do not probe once per queued task unless new
   evidence invalidates the result. Honor Claude-builder's existing explicit-user-choice rule.
5. **Publish and align, then exercise the real boundary.** For preparation-only work,
   record unpublished integration as pending instead of claiming dispatch readiness.
   Once landing/publication is authorized, use the normal path and reconcile. Choose one
   exclusive clean published development coordinator plus separate full execution and
   checkpoint-publication clones. Fetch and normally fast-forward; prove target ledger
   has no delta against its fresh integration tracking ref. Use supported queue admission
   or resume/retry, preserving history. Run actual target-aware `jog run --dry-run` with
   explicit roles/max-tasks and inspect every selected result, not an empty-queue exit0.
   Inspect generated packet roots, nonempty/lossless criteria, artifacts, effective caps
   and promotion-probe lint as well as Swarm readiness. Command probes must use supported
   committed paths; a packet that parses is not proof promotion accepts its command.
6. **Hand off one bounded invocation and observe.** Record the actual command with
   target/checkpoint roots, selected order, UTC deadline/closeout reserve, remaining
   attempt budgets and owner. Individual turn/gate timeouts are not an overall deadline;
   the supervising session must enforce the authorized wall window. Do not start work
   whose allowed duration cannot fit. Preserve existing PR outer inspection, landing
   authority and recovery verbs. Measure useful reviewed deliveries, engine-owned
   advancement, interventions, elapsed time, observed API/CLI usage and repeated gates.
   Unknown HTTP/token counts stay unknown. No automatic-success claim for manual dispatch.

Keep one compact record in the existing umbrella issue and committed evidence/provenance;
this is an instruction contract, **not a new runtime receipt schema or state machine**:

| Evidence | Required record / honest limit |
|---|---|
| Selection | Ordered IDs, current base, retained candidates/attempts and declared acceptance |
| Contract-ready | Actual per-item packet + promotion-lint results, nonempty criteria/artifacts |
| Environment-verified | Per-gate interpreter/dependencies/services; actual role/model/auth/capacity observation |
| Integration-aligned | Coordinator/execution/publication roots and SHAs, fresh tracking refs, clean/ledger checks |
| Dispatch-ready | Prior evidence still applies, exact bounded invocation and active owner; otherwise name pending facts |
| Result | Deliveries, advancement, interventions, time/calls/gate repeats; unknowns and preserved failures |

Use these as evidence descriptions, never parallel queue statuses. Reuse valid observations
and rerun only what changed. A prepared contract may be complete while dispatch is blocked
by unpublished intake or another machine's unverified environment. After a metadata-only
tail, record tested versus delivered SHAs and check the relevant unchanged boundaries rather
than reflexively rerunning broad qualification. Do not label the whole run “ready” solely
because preflight/dry-run returned zero. LTVera-Pandas#1014/#1015 is the worked example:
its aligned five-item dry-run passed, but Jose's capacity and useful deliveries remained unproven.

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
   - **Default (Interactive):** Pauses at each landing boundary for human confirmation. On confirm: merges PR into `development` and re-anchors the checkout. On decline: marks row `parked` (`awaiting-landing`) so unmerged tasks are never misrepresented as `completed`.
   - **Unattended without `--auto-merge`:** Parks row as `parked` (`awaiting-landing (unattended run without --auto-merge)`) and halts advance.
   - **`--auto-merge` (verified, GH-300):** Verifies GitHub truth against the receipt BEFORE merging — the PR must still be OPEN on the receipt's base/head/head SHA in this repo with the gate green on that head — and refuses (parking the row) instead of merging blind; on pass, merges into `development` and re-anchors the checkout before advancing.

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
published, fast-forward-ready primary. Unrelated changes, divergence or rejected push stop and
preserve state for reconciliation; do not bypass Phase 0. The automatic direct-push/rebuild
path is a separate PR so it can be reverted independently. `--auto-merge` on native Jog dispatch/retry refuses before leasing during this interim;
it cannot skip the publication checkpoint. Use merge-cleanup for actual landing;
its mapped Jog hook runs after hosted or local reconciliation and before the existing final post-merge
commit/push. A direct `jog land` call likewise needs that final publication checkpoint.

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
