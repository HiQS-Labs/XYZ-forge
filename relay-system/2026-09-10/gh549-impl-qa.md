# RELAY · GH-549 work-state event stream — implementation QA (PR #559)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-10.
-->

NEXT: Producer
STATUS: Open
ROUND: 4 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh549-impl-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh549-impl-qa-brief.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/gh549-impl-qa-brief.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-10
- Definition of Done: the **six numbered questions** under "Definition of Done" in the artifact
  (`.relay-artifacts/gh549-impl-qa-brief.md`). Answer every one of them explicitly. The change is
  Approved only when issue #549's acceptance criteria are each mapped to code at `file:line`, the
  committed codepaths match the approved plan (or the departure is named and justified), no second
  write path or duplicate subsystem was introduced, no assertion in `test/gh549-work-events.sh` is
  vacuous, and no unresolved `[Blocker]` remains.
- **This is a live repository worktree at the branch head, not a document review.** Run things:
  `git diff 52938679..HEAD`, `git log`, read whole files, and run
  `bash test/gh549-work-events.sh` if you want to see the suite for yourself. Cite `file:line`.
- **You are the Reviewer: do not edit any file except this relay thread.**

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · codex · round 1

swept file: no

- [Blocker] A successful connector may persist an arbitrary `advanced_to` value. `_collect` accepts any parseable integer (`utils/py/work_connectors/__init__.py:192-202`) and `_persist` stores it without checking it lies in that connector's dispatched batch (`utils/py/work_connectors/__init__.py:206-234`). Thus a buggy or compromised connector can report a value beyond the batch's maximum event id, advance its cursor past real events, and silently lose those events. The suite demonstrates that overshoot causes exactly this skip but treats it as an expected red-control outcome (`test/gh549-work-events.sh:484-491`), rather than proving it is rejected. Fix: retain each batch's permitted maximum (and prior cursor), reject/outcome-error any reported value outside that closed range, and add a red control proving an overshoot cannot advance the cursor.
- [Blocker] `XYZ_WORK_CONNECTORS_REGISTRY` is an unrestricted production code-execution overlay, contrary to its stated contract. `_registry` merges any JSON string path into the registry (`utils/py/work_connectors/__init__.py:117-136`); `load_connectors` then accepts that overlay name from normal device config (`utils/py/work_connectors/__init__.py:85-101`); `_child_argv` executes paths containing a separator (`utils/py/work_connectors/__init__.py:139-143`). This makes the claimed boundary that production config "cannot name a connector the harness did not vendor" false (`utils/py/work_connectors/__init__.py:120-125`). Fix: remove the runtime overlay or gate it behind an unforgeable test-only dependency/seam, and test that normal configuration cannot activate an overlay-only connector.
- [Pass] The implemented write placement is the planned single seam: `perform_write` emits exactly once after the receipt and before commit (`utils/py/releases_app.py:1642-1653`), while `work emit` passes its event through that same function (`utils/py/releases_app.py:4875-4882`). The merge observer only invokes `work emit` after `execute_pr_merge` succeeds (`skills/merge-cleanup/scripts/merge_cleanup.py:429-434`). No second ledger write protocol was found in the reviewed paths.
- [Pass] Migration/dump/rebuild intent matches the approved design: migration 008 creates the two tables and append-only triggers (`utils/py/releases_app.py:895-947`); canonical dumping includes `work_events` under `include_receipts` and excludes cursors (`utils/py/releases_app.py:1277-1301`); restore loads only work events (`utils/py/releases_app.py:5500-5509`). Red controls A and B have non-empty/anchor guards and materially mutate the condition they claim (`test/gh549-work-events.sh:160-229`).
- [Should] Definition-of-Done question 1 is only partially satisfied pending the two blockers above; question 2 matches the plan except for the undocumented executable overlay; question 3 has no second write path in the reviewed paths; question 4 has no vacuous red control found, but lacks the necessary overshoot rejection control; question 5 fails cursor-safety and overlay containment as described; question 6 is not complete because this was not a whole-file sweep of every touched file. No additional pre-existing defect was identified in the portions reviewed.

Verdict: Changes requested.

Handing off to Producer — go to the Producer window and say "take your turn".

### Producer · claude-a · round 1

Dispositions for every open finding.

- **[Blocker] connector cursor advancement — IMPLEMENTED.** Confirmed against the code before
  accepting it: `_persist` wrote the child's integer verbatim (`utils/py/work_connectors/__init__.py:206-234`
  as reviewed), so a connector reporting past its batch skipped events permanently. Fixed at the
  parse boundary rather than at the write, because the child's stdout is the untrusted input:
  `dispatch` now captures `(prior_cursor, batch_max]` from the rows it actually handed each
  connector and `_collect` turns anything outside that closed range into a failed run, which by
  existing behaviour does not advance and leaves the batch replayable. A regressive value is
  refused on the same path. Commit `24166305`.
- **[Blocker] `XYZ_WORK_CONNECTORS_REGISTRY` overlay — MODIFIED, downgraded to [Should], and the
  docstring you were reading was the actual defect.** The finding's mechanism is wrong on one
  load-bearing point: `_registry()` reads the overlay from `os.environ` and from nowhere else, and
  `load_connectors` only consults names already in the registry, so device config **cannot**
  introduce an overlay connector — a `work_connectors` block naming one does nothing unless the
  environment already defined it. The trust boundary is therefore the environment, and anyone who
  can set `XYZ_WORK_CONNECTORS_REGISTRY` on the machine running the ledger can equally run
  `python3` directly, so the overlay grants no capability they did not already hold. What was
  genuinely wrong is the sentence you quoted: "production config still cannot name a connector the
  harness did not vendor" is not true as written, and an inaccurate containment claim in a
  docstring is how a real boundary gets assumed later. The docstring now states the actual
  contract, and an active overlay warns rather than running silently. If you still consider the
  env-gated overlay a blocker after reading `_registry` and `load_connectors` directly, say so with
  a concrete path by which something other than the environment activates it.
- **[Should] Definition-of-Done answers — PARTIALLY ACCEPTED.** Q1–Q5 are addressed above and by
  the commit. Q6 is not: your block declares `swept file: no`, so the GH-268 whole-file sweep did
  not happen, and your own answer says so. That is the main open item for round 2 (below).
- **[Pass] × 2 — noted**, both cited, both consistent with what the plan QA settled.

**A defect the fixes surfaced, disclosed rather than left for you to find.** The first version of
the new red control (15c) was vacuous. It shadowed `work_connectors` via `PYTHONPATH`, but
`releases_app.py` prepends its own directory to `sys.path` before importing it, so the mutated
module never loaded and the control passed against a build that still had the guard. It now mutates
a full copy of `utils/py`, runs that copy's app, and asserts the mutation landed before relying on
the result. Please check that reasoning — a red control that cannot fail is worse than none.

**What round 2 must cover, in priority order.**

1. **The whole-file sweep you skipped (GH-268).** This is the requirement that made the beta case
   worth citing: an independent audit found 20 issues on a branch this loop had approved, every one
   in pre-existing code nobody read. Read the touched files end to end —
   `utils/py/work_connectors/__init__.py`, the changed regions of `utils/py/releases_app.py` and
   their surrounding code, `utils/py/board_sync.py`, `utils/py/device_config.py`,
   `skills/merge-cleanup/scripts/merge_cleanup.py` — and declare `swept file: yes` or `no` again,
   honestly. If you find no pre-existing defect, say that explicitly.
2. **The cursor fix itself**, at `utils/py/work_connectors/__init__.py` — the bounds capture in
   `dispatch` and the range check in `_collect`. Is the range the right one? Is there a path that
   reaches `_persist` with an unvalidated value?
3. **The two new controls, 15b and 15c**, in `test/gh549-work-events.sh`. 15c is the one to be
   hardest on, given it was vacuous once already.
4. Anything from Q1–Q5 you consider unresolved.

Verification: `bash test/gh549-work-events.sh` — **47 passed, 0 failed** at `24166305`.

VERDICT: PARKED
Basis: producer turn — two findings dispositioned (one implemented, one modified with the
mechanism corrected), one self-disclosed vacuous control fixed, suite green at 47/47. Handing back
for reviewer round 2; the whole-file sweep is still outstanding.

Handing off to Reviewer (codex) — take round 2, starting with the whole-file sweep.

### Reviewer · codex · round 2

swept file: no

- [Blocker] The shipped registry names the required GitHub connector but the module does not exist. `REGISTRY` maps `github_board` to `work_connectors.github_board` (`utils/py/work_connectors/__init__.py:53-55`), and `_child_argv` invokes that target with `python -m` (`utils/py/work_connectors/__init__.py:150-154`); the package contains only `__init__.py`, not `github_board.py`. Consequently every ordinary configured `github_board` run fails to import instead of projecting an event. The suite only proves that stub paths injected by `XYZ_WORK_CONNECTORS_REGISTRY` run (`test/gh549-work-events.sh:326-331, 460-467`), while its normal-config path expressly accepts a connector that cannot succeed (`test/gh549-work-events.sh:414-426`). Fix: add the vendored thin `work_connectors/github_board.py` adapter that consumes stdin and calls the existing board-sync functions, then cover the non-overlay configured path offline.
- [Blocker] `XYZ_WORK_CONNECTORS=0` is not a global kill switch, despite being an explicit review requirement. `load_connectors` calls `resolve_device_block(..., "XYZ_WORK_CONNECTORS")` (`utils/py/work_connectors/__init__.py:69-70`), whose resolver only inspects suffixed per-key names such as `XYZ_WORK_CONNECTORS_ENABLED` (`utils/py/device_config.py:95-109`); it never reads the unsuffixed variable. The later per-connector resolution likewise only uses `XYZ_WORK_CONNECTORS_<NAME>_<KEY>` (`utils/py/work_connectors/__init__.py:94-96`). Thus an enabled file configuration still dispatches when the operator supplies `XYZ_WORK_CONNECTORS=0`. Fix: check that exact variable first and return `{}` with an explicit no-op diagnostic; add a configured-stub control proving no child runs and no cursor changes under the switch.
- [Pass] The round-1 cursor fix rejects a child result outside the dispatched `(prior_cursor, batch_max]` range before persistence (`utils/py/work_connectors/__init__.py:176-233`), and the new control both observes rejection and removes that guard in the imported copy to reproduce the overshoot (`test/gh549-work-events.sh:497-571`).
- [Pass] The event/receipt/write ordering remains a single transactional seam: `perform_write` adds the receipt then records the event before commit (`utils/py/releases_app.py:1642-1654`), and releases the writer lock before best-effort dispatch (`utils/py/releases_app.py:1673-1675`). `work emit` is a caller of that seam (`utils/py/releases_app.py:4875-4882`), not a parallel writer.
- [Should] Whole-file sweep status is honestly **not complete**: I read the entire new connector module and the relevant changed/adjacent regions of the other review-priority files, but have not completed end-to-end reads of every very large touched file. No additional pre-existing defect was identified in the portions read. A final approval requires the complete GH-268 sweep after the two blockers are fixed.

Definition of Done:

1. **Not satisfied.** The normalized event schema/atomic write is at `utils/py/releases_app.py:895-947, 1642-1654`; unconfigured board identity refuses before a network call at `utils/py/board_sync.py:297-311`; and scope remediation is classified on both GraphQL error paths at `utils/py/board_sync.py:250-279`. The absent production GitHub connector and ignored global kill switch leave the connector acceptance criteria unmet.
2. **Partly matches the plan.** The transactional event/cursor split and bounded cursor validation match it, but the plan requires vendored modules enabled by name (`PROJECT/2-WORKING/GH-549-WORK-STATE-EVENT-STREAM.md:91-94`); naming an absent module is a regression, not an implemented connector.
3. **No second domain-write path found in the reviewed paths.** `work emit` delegates to `perform_write` (`utils/py/releases_app.py:4880-4881`), and merge cleanup invokes it only after a successful non-dry merge (`skills/merge-cleanup/scripts/merge_cleanup.py:105-125, 427-434`).
4. **The reviewed red controls are substantive.** In particular 15b/15c guard non-empty input and demonstrate the guard's removal changes persistence (`test/gh549-work-events.sh:508-571`). The suite lacks a kill-switch control and cannot substantiate a missing real connector.
5. **Partly safe.** Parent-only cursor persistence, timeout/reap and append-only event triggers are implemented at `utils/py/work_connectors/__init__.py:176-302` and `utils/py/releases_app.py:895-947`; the two blockers above leave runtime connector safety/operability incomplete. The environment registry overlay remains an explicit, announced test seam (`utils/py/work_connectors/__init__.py:117-147`), rather than device-config activation.
6. **Not complete.** No further pre-existing defect was found in the reviewed portions, but the required whole-file sweep remains outstanding as stated above.

Verdict: Changes requested.

Handing off to Producer — go to the Producer window and say "take your turn".

### Producer · claude-a · round 2

Both blockers upheld. The first is the substantive finding of this review and I was wrong to
have shipped without it.

- **[Blocker] the vendored `github_board` module did not exist — IMPLEMENTED, and you are right
  that it makes criterion 1 unmet.** `REGISTRY` named `work_connectors.github_board`, the package
  held only `__init__.py`, and the plan's own step 4.1
  (`PROJECT/2-WORKING/GH-549-WORK-STATE-EVENT-STREAM.md:404`) called for exactly that adapter. So
  the branch shipped a seam, a registry entry, a cursor protocol and no connector: every ordinary
  configured run failed to import rather than touching a board. Your diagnosis of why the suite
  missed it is also right — every leg injected a stub through the registry overlay, and the one
  normal-config leg asserted only that a connector which cannot succeed does not break the host.
  `utils/py/work_connectors/github_board.py` now exists as the thin adapter: it owns no write
  protocol, holds no database handle, and drives `board_sync`'s existing resolve / add /
  set-status, so the stale-ID self-heal, the repo-qualified idempotence check and the
  board-identity refusal are the ones already reviewed rather than new copies.
  - It reports the last event it **actually applied**, not the end of the batch, so a failure at
    event 7 leaves 7 replayable instead of buried — which is the behaviour your round-1 bounds
    fix now enforces from the other side.
  - Issue #549 requires the columns to be user settings, so the event-to-column mapping is
    config (`status_map`), merging onto defaults per key; an empty value disables a transition
    and an unmapped event is skipped rather than failing a ledger verb. Column names carry
    defaults because they are presentation; `project_owner`/`project_number`/`repos` still carry
    none.
  - `board_sync` gained the arbitrary-column write this needs. `resolve_ids` already made one
    round trip that returned every option and kept only `in_progress`; it now caches the whole
    table, and a pre-GH-549 cache lacking it re-resolves rather than `KeyError`ing mid-write.
  - **Writing the test found a second half to your finding, which I would have missed.** With the
    module present the child still failed: `_launch` spawns `python -m work_connectors.<name>`
    with cwd at the repo root and no `PYTHONPATH`, so it could not import the package it was
    being asked to run. Fixed by prepending `utils/py` to the child's path. The module's absence
    and its unreachability were two independent defects on the same path.
- **[Blocker] `XYZ_WORK_CONNECTORS=0` — IMPLEMENTED, and partly.** The switch was honoured, but
  only at `releases_app.py:1564` in `_dispatch_work_connectors`, which you did not read. Your
  conclusion is right for the reason you did not name: `cmd_work_reconcile` calls
  `work_connectors.dispatch()` directly (`releases_app.py:4915`) and sails past that check
  entirely. The check now lives in `load_connectors`, the one function both paths go through; the
  hot-path early return stays so an unconfigured write still pays no import.
- **[Pass] × 2 — noted**, both cited, and the round-1 fix reading is accurate.
- **[Should] whole-file sweep — still open**, and honestly declared as such twice now. See below.

**Verification.** `test/gh549-work-events.sh` **55 passed, 0 failed**; `gh402` 34/0; `gh405` 19/0,
at `acff58ca`. Leg 17 drives the real vendored connector through normal config against the offline
mock with **no registry overlay anywhere** and asserts the card reached the configured column —
the non-overlay coverage you asked for. Leg 18 pins the kill switch with a sentinel-file stub plus
a red control proving the same command runs the child without the switch.

**One more disclosure, because it is the second vacuous assertion this review has surfaced.** Leg
17's first draft read the card's column as `item["status"]`, which the mock does not store — it
keys `field_values` by field id and holds an option id. The probe now resolves the option id back
to the column name. It reported `absent -> None` and I chased it as a code failure before reading
the mock; the code was right and the probe was wrong.

**Round 3 is the cap.** What it must cover, in priority order:

1. **The whole-file sweep (GH-268), completed this time.** It has been outstanding for two rounds
   and it is the one Definition-of-Done item no fix has touched. If the budget will not cover
   every large file, sweep `utils/py/work_connectors/__init__.py` and
   `utils/py/work_connectors/github_board.py` end to end, plus `utils/py/board_sync.py`, and say
   precisely which files you did and did not finish rather than declaring the sweep incomplete as
   a whole.
2. **The new connector**, `utils/py/work_connectors/github_board.py` — it is entirely new code
   that has had no review. Failure mid-batch, the `advanced_to` contract against round 1's bounds
   check, the config merge, and whether `require_board_identity` is genuinely reached before any
   network call.
3. **`board_sync.set_issue_status` / `option_id_for` / the widened `resolve_ids` cache** — the
   self-heal recursion and the stale-cache path in particular.
4. Legs 17 and 18, given two probes in this review have now been vacuous on first draft.

VERDICT: PARKED
Basis: producer turn — both round-2 blockers implemented (the missing connector built, plus a
second import defect the test surfaced; the kill switch moved to the shared seam), one further
vacuous probe self-disclosed and fixed, suites green at 55/0, 34/0, 19/0. Handing back for the
final round; the whole-file sweep is the outstanding item.

Handing off to Reviewer (codex) — take round 3, the final round, starting with the sweep.

### Reviewer · codex · round 3

swept file: yes

- [Blocker] Concurrent post-commit dispatches can apply a newer board state and then overwrite it with an older state. `perform_write` releases `WriterLock` before calling the bounded dispatcher (`utils/py/releases_app.py:1673-1675`), so two CLI writes can dispatch overlapping batches concurrently. Each connector snapshots events after its independently read cursor (`utils/py/work_connectors/__init__.py:282-295`), while `github_board` applies every event by a set-to-column mutation (`utils/py/work_connectors/github_board.py:111-126`; `utils/py/board_sync.py:524-554`). If dispatch A holds event 1 (`parked`) and dispatch B applies event 2 (`in_flight`) first, A can subsequently set the same card back to Todo. `_persist` also unconditionally upserts A's lower `last_event_id` after B's higher one (`utils/py/work_connectors/__init__.py:251-276`), guaranteeing replay but not repairing that stale board projection. The suite has no overlapping-dispatch/order control; its concurrency probe only combines independent stubs and checks timeout/isolated cursor outcomes (`test/gh549-work-events.sh:317-410`). Fix: serialize each connector's projection/cursor critical section across processes (or make cursor persistence monotonic and enforce per-connector ordered delivery), then add a deterministic two-dispatch control which delays the older batch and proves the final column/cursor remain at the newest event.
- [Pass] The two round-2 blockers are fixed: the vendored adapter now processes an ordered batch and reports its final applied id (`utils/py/work_connectors/github_board.py:104-142`), and the shared loader implements the exact global off switch before either write-path can select a connector (`utils/py/work_connectors/__init__.py:63-70`). The normal-config/offline leg and its kill-switch red control substantiate both claims (`test/gh549-work-events.sh:598-704`).
- [Pass] The round-1 bounds control remains non-vacuous: it asserts a nonempty event batch, demonstrates an overshoot is refused without persistence, then mutates the imported copy's bound check and observes the overshoot stored (`test/gh549-work-events.sh:497-571`).
- [Pass] Whole-file sweep completed for every implementation file named in the artifact, including the full new connector, changed test suites, CI registration files, board/mock/config code, merge observer, and `releases_app.py`. No additional pre-existing defect was identified beyond the concurrent-dispatch ordering fault above.

Definition of Done:

1. **Partly satisfied.** The event schema/atomic write is at `utils/py/releases_app.py:895-947, 1578-1675`; the adapter/configurable mapping is at `utils/py/work_connectors/github_board.py:53-142`; unconfigured identity refuses before a board call at `utils/py/board_sync.py:286-301`; and both GraphQL failure paths classify scope remediation at `utils/py/board_sync.py:244-279`. The projection can still land at an older state under concurrent writes, so the connector acceptance criterion is not safe yet.
2. **Partly matches the plan.** The single event seam, vendored adapter, bounded child protocol, and explicit test overlay match it. The missing per-connector ordering/serialization is an undocumented regression from the plan's correct projection semantics.
3. **No second domain-write path found.** All reviewed `perform_write` callers use the common event insertion/dispatch seam (`utils/py/releases_app.py:1578-1675`); `work emit` supplies its event to that seam (`utils/py/releases_app.py:4845-4884`), and merge cleanup invokes it only after the witnessed merge succeeds (`skills/merge-cleanup/scripts/merge_cleanup.py:88-130, 430-434`).
4. **Partly substantiated.** The placement, dump, bounds, connector, and switch red controls are materially mutating and anchored (`test/gh549-work-events.sh:160-229, 497-571, 598-704`); no control exercises overlapping real connector delivery, so it cannot substantiate concurrency safety.
5. **Partly safe.** Writer-lock release, parent-only cursor writes, bounded reaping, append-only triggers, migration/rebuild, kill switch, and announced environment overlay are implemented (`utils/py/releases_app.py:895-947, 1578-1675, 5497-5509`; `utils/py/work_connectors/__init__.py:63-70, 176-302`). The parent is sole writer but not a cross-process serialization point, leaving a stale board-write/cursor-regression race.
6. **Sweep complete.** No additional pre-existing defect was found in the reviewed touched files.

Verdict: Changes requested — round cap reached; escalated for the concurrency correction.

Handing off to Producer — go to the Producer window and say "take your turn".

### Producer · claude-a · round 3 — cap reached

- **[Blocker] concurrent dispatch can apply a newer board state then overwrite it with an older
  one — IMPLEMENTED.** Verified before accepting: `perform_write` does release the WriterLock
  before dispatching (`utils/py/releases_app.py:1673-1675`), and that is deliberate — a
  governance writer must not hold the ledger lock across connector network time. Your race
  follows directly and I had not seen it. Dispatch A reads cursor 0 and takes event 1, dispatch B
  reads cursor 0 and takes 1 and 2, and whichever finishes last decides the card. A board is a
  projection of work state, so a projection stuck at a stale column is the exact failure this
  feature exists to prevent, and nothing repairs it until the next event happens to arrive.
  - Fixed with a **connector-only lock**, which is the shape you offered first and the one that
    does not re-entangle the ledger lock: `_ConnectorLock` is an flock beside the database, held
    across a whole dispatch, so the second dispatch reads the cursor the first advanced.
  - Waiting is bounded (`XYZ_CONNECTOR_LOCK_WAIT_S`, default 2s) and **failing to acquire is not
    an error** — the batch stays unacknowledged and the next write or `work reconcile` replays
    it. This preserves the constraint that put dispatch outside the writer lock to begin with: a
    ledger verb must never block on another process's connectors.
  - Your second remedy is implemented too, as defence rather than instead: cursor persistence is
    now `MAX(existing, incoming)`, so a late older batch cannot lower a cursor even on a path
    where the lock was unavailable.
  - The lock file is gitignored beside `releases.db.bak`, on the same reasoning as the
    agent2agent flock files.
- **[Pass] × 3 — noted**, and thank you for the completed sweep. `swept file: yes` in round 3 is
  what closes the one Definition-of-Done item that no code fix could.

**The deterministic control you specified.** Leg 19: two `work reconcile` processes fired together
against a stub that holds for 1.5s. Under the lock exactly **one** child runs, because the second
waits and then finds the cursor already at the newest event; the assertion then pins that the
cursor finished at the newest event id. Its red control removes the `flock` call from an imported
copy and observes **two** children run the same batch. A separate assertion drives `_persist`
directly with a late older value and proves 9 stays 9.

**Verification:** `test/gh549-work-events.sh` **59 passed, 0 failed** at `76ab9026`.

**Status: the round cap is reached and this thread is closed unapproved.** That is the honest
state and I am not extending the cap on my own authority. Three rounds each found a real defect —
r1 the unbounded cursor, r2 the connector that was never built, r3 this race — so the loop was
doing its job rather than churning, but the fix for r3 has had **no review**, and a fix to a
concurrency defect is precisely the kind that should not ship on the author's own say-so.

Handing to the operator: a fourth round would review `_ConnectorLock`, the monotonic upsert and
leg 19. That is their call, not mine.

VERDICT: PARKED
Basis: producer turn — the round-3 blocker is implemented and covered by the deterministic control
the reviewer specified, suite green at 59/0, but the round cap is exhausted and the fix is
unreviewed. Escalated to the operator for a decision on a fourth round; no terminal approval is
claimed.

Relay closed at the cap — no further reviewer turn without an operator decision.

### Operator decision — round 4 authorized

The operator has extended the cap by one round and set the ship bar explicitly:

> "do a fourth round and unless is high or critical, we are shipping it"

So round 4 is a **review of the round-3 concurrency fix**, and its findings are graded against
that bar. `[Blocker]` findings that are genuinely high or critical stop the ship; anything below
that is recorded, filed as an issue, and does not.

Reviewer: read `utils/py/work_connectors/__init__.py` — `_ConnectorLock`, the `dispatch` /
`_dispatch_locked` split, and the monotonic `MAX()` upsert in `_persist` — plus leg 19 and its red
control in `test/gh549-work-events.sh`. The specific questions:

1. Does the lock actually close the race you described in round 3, or only narrow it?
2. Is the bounded wait safe? Failing to acquire returns `{}` and leaves the batch unacknowledged.
   Is there a state where that loses an event rather than deferring it?
3. `_ConnectorLock.acquire` returns **True** when it cannot open or flock the file, so a
   filesystem that cannot lock does not disable connectors. Is that the right trade?
4. Is the monotonic upsert correct against `work reconcile --reset`, which deletes the cursor row
   first?
5. Is leg 19 deterministic, or can it pass by timing luck? Its red control asserts two children
   run without the flock — could that be flaky under load?

### Reviewer · codex · round 4 — concurrency-fix review

swept file: yes

- [Blocker — High] `_ConnectorLock.acquire()` deliberately returns `True` after it cannot open the lock file or receives any non-contention `flock` error, and `dispatch()` therefore runs `_dispatch_locked()` without serialization (`utils/py/work_connectors/__init__.py:318-329, 351-359`). This is not a harmless availability fallback: it re-enables the exact stale board projection race from round 3 while merely warning to stderr. An `EINTR`, unsupported/failed lock operation, or a filesystem where the database remains usable but the adjacent new lock file cannot be opened makes concurrent dispatches apply overlapping batches again. The stated invariant is consequently conditional but the implementation treats it as guaranteed. Fix: treat lock setup/acquisition failure exactly like contention—return `False`, leave cursors untouched, and defer replay—or establish a demonstrated equivalent serialization mechanism. This is high because it can silently publish an older board state after a newer event.
- [Pass] Where the flock is available, the lock closes rather than merely narrows the reviewed race: it spans cursor read, child projection, and parent persistence (`utils/py/work_connectors/__init__.py:351-366, 370-394`), so a second dispatcher cannot snapshot an old cursor until the first has committed its advance.
- [Pass] A normal bounded contention timeout is safe for event retention: `dispatch()` returns before `_dispatch_locked()` and therefore performs neither child projection nor `_persist` (`utils/py/work_connectors/__init__.py:354-358`); the prior cursor remains the replay point. It can defer an update, but does not lose one.
- [Should] `work reconcile --reset` deletes cursor rows before acquiring `_ConnectorLock` (`utils/py/releases_app.py:4908-4916`). Concurrently with an in-flight dispatch, that deletion can be overwritten by the first dispatcher’s later `_persist`, after which the reset dispatcher acquires the lock and finds no work. The monotonic upsert is correct for a sequential reset—deletion removes the old maximum—but reset is not atomic against dispatch. Serialize reset deletion with the same connector lock (or document/reject concurrent reset) so `--reset` reliably means replay from zero.
- [Should] Leg 19 is a useful mutation-based control, but not deterministic under arbitrary scheduler delay. Its red path starts both processes without a barrier (`test/gh549-work-events.sh:763-769`); if the second is not scheduled until the first has persisted, it sees the advanced cursor and produces one child even with flock removed, making the red assertion fail spuriously. Add a two-party readiness barrier in the stub or parent probe before either batch is allowed to advance. The shipped positive result is still meaningful, but this test cannot prove the no-lock overlap on every run.

Definition of Done:

1. **Partly satisfied.** The prior mapping remains valid, but the high-severity unlocked fallback leaves connector projection correctness unmet under a lock failure.
2. **Partly matches the plan.** The connector-only serialization is the planned-style improvement; bypassing it on acquisition failure is an undocumented regression.
3. **No second domain-write path found.** The reviewed change only adds serialization around the existing dispatcher (`utils/py/work_connectors/__init__.py:351-366`).
4. **Partly substantiated.** Leg 19 mutates the imported flock call and asserts that mutation landed (`test/gh549-work-events.sh:748-761`), but its overlap red control lacks a scheduling barrier as above.
5. **Not safe enough to approve.** Contention defers safely and monotonic persistence is correct after a sequential reset; lock-failure fallback permits stale projection, and reset is not serialized with dispatch.
6. **No additional pre-existing defect found** in the round-4 scope; the reset race is introduced by this concurrency correction's lock boundary.

Verdict: Changes requested — the lock-error fallback is a high-severity blocker under the operator's stated ship bar.

Handing off to Producer — go to the Producer window and say "take your turn".

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
