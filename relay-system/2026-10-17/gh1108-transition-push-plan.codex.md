# RELAY · GH-1108 delivery2 transition publication plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
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
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1108-transition-push-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1108-JOG-LAND-RECEIPTS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1108-JOG-LAND-RECEIPTS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-17
- Definition of Done: review only the new Delivery2 stacked plan and its actual referenced source seams, not delivery1 closed final artifact. Local developer CLI/single pinned primary, no enterprise machinery. No production changes in this delivery yet. Evaluate one-writer/FF-only fresh-intent retry/connector cleanliness/post-merge final publication/revert boundary against operator GH1108 requirements and commensurate complexity.

Read the full new Delivery2 section, earlier five requirements, and current releases_app.perform_write/Jog callers/WriterLock, work_connectors cursor dispatch/diagnostics, jog_run.jog_land, merge_cleanup final publication/mapping/recovery. Questions: (1) Does one canonical writer plus fresh high-level callable cover every transition? (2) Does native candidate publication safely handle NFF/unknown remote outcome without reset or task-clone writes? (3) Is cursor relocation necessary and proportionate, with read-only diagnostics/reset/rebuilt sequence correctness? (4) Does post-merge completion genuinely reuse final publisher without nested-lock subprocess deadlock or hidden defer bypass? (5) Are verification/revert/dependency order/no-new-tests boundaries complete and minimal? Prefer simpler existing mechanisms with concrete source evidence. Do not demand new suites/gates.

Only this relay is writable; never edit plan/production. Append concrete cited findings with Observed input/Affected scope/Falsifier and swept file declaration. On approval, mark Approved and run `tick done RELAY-gh1108-transition-push-plan --agent codex`; on findings release to codex-producer. Do not run git; shim owns file-scoped commit. Reviewer probes read-only only; no tests/pytest/validate in worktree. This is pre-implementation plan QA, separate from delivery1 authorized fourth final round. Final PR2 code review waits for dependency merge/rebase.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: Block implementation pending three bounded clarifications below. The canonical writer/fresh-intent approach is sound, but the proposed publication envelope does not yet close every existing reader/lock/publisher seam.
swept file: yes

Scope: read the entire seeded artifact, with substantive review limited to Delivery2, the five requirements and referenced current source seams; delivery1's closed final approval is not reopened. Graph Verify lookup used XYZ-forge generation `2026-09-01T15:54:30Z`; coverage reported metadata_changed for releases_app/jog_run and not_tracked for work_connectors/merge_cleanup, so current source was used instead. No exhaustive graph-completeness claim. No other in-scope plan defects identified in the sweep.

- [Should] **S1 — Deferred dispatch does not isolate provisional events from other dispatchers.** Artifact lines 135, 144–147 promise that a rejected transition never projects, but only defer the current intent's dispatch. Existing `work_connectors.dispatch` takes only `_ConnectorLock` (utils/py/work_connectors/__init__.py:431–436); `_dispatch_locked` opens the live DB and reads all events after its cursor (462–468), then launches connectors (485). `perform_write` commits the DB before Git publication (utils/py/releases_app.py:1735), so a delayed prior dispatch or explicit reconcile can read the next intent's unaccepted event. Moving cursors and validating their identity cannot retract that external projection.
  Observed input: the concrete reader is `events_after(read, last)` at work_connectors/__init__.py:468 with `WHERE e.id > ?` at 136; the planned writer leaves its committed candidate DB visible during push. Schedule: candidate DB commit → another process dispatches that event → NFF rejects candidate.
  Affected scope: automatic and explicit dispatch against the pinned primary while a Jog publication is pending/unknown, including github_labels' live current-state reads.
  Falsifier: in a disposable clone pause publication after DB commit, run a second dispatcher/reconcile, then reject publication; no payload/current-state projection may contain the rejected intent. After acceptance, the accepted event must remain replayable without holding WriterLock over network calls.
  Concrete fix: specify a short, consistently ordered writer-lock-protected accepted-state snapshot/read boundary, or an equally small accepted-state source, for **all** dispatcher entry paths. Release the writer lock before connector network time. Explicitly handle preserved dirty state after unknown/failed publication; acquiring the lock alone after failure must not make an unpublished DB accepted.

- [Should] **S2 — In-process landing still contains a lock-taking subprocess.** Artifact line 148 addresses the outer land and work-emit subprocesses, but current `jog_land` invokes `releases check` as a child (utils/py/jog_run.py:1185–1188), and `cmd_check` independently acquires WriterLock (utils/py/releases_app.py:5714–5715). Moving land itself in-process does not pass a ContextVar into that child. Under the proposed outer intent this path waits/refuses on its parent's lock before completion.
  Observed input: `[sys.executable, resolve_tool(root, "utils/py/releases_app.py"), "--root", root, "check"]` at jog_run.py:1185–1186.
  Affected scope: standalone and mapped landing when verification executes within the new publication lock.
  Falsifier: a clone run of both landing paths under the outer intent completes without writer-lock refusal and retains canonical check validation on each refreshed retry state.
  Concrete fix: explicitly place check outside the held-lock portion with revalidation of the checked state, or reuse the exact runtime's check in-process with deliberate lock borrowing. Inventory this nested lock path in step 6; do not merely replace the outer subprocess.

- [Should] **S3 — Define how the existing final publisher joins candidate publication and proof rollback.** Artifact line 145 snapshots/restores only six B1 paths; line 148 adds landing.json and reuses the final publisher as callback. That publisher currently runs `git add -A`, `git commit`, then pushes HEAD (skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:756–766), moving primary HEAD before acceptance. `jog_land` also creates/updates landing.json outside those six paths (utils/py/jog_run.py:1222–1226). Calling the existing publisher unchanged contradicts steps 3–4; restoring only the six files on NFF leaves the rejected proof in the worktree.
  Observed input: the exact final callback `commit_and_push_phase5_writes` above, plus a first landing whose execution bundle has no landing.json at the pre-intent snapshot.
  Affected scope: mapped normal/reconcile-pr final publication and standalone landing with raced or unknown push outcome.
  Falsifier: clone control with first-created landing.json and forced NFF keeps primary HEAD unchanged until acceptance, rebuilds proof from fresh queue truth, and produces one clean accepted commit containing only six owned paths plus exact validated proof paths; injected unrelated dirt is refused.
  Concrete fix: state that the **existing final publisher entry point** gains a narrowly scoped mapped-intent branch delegating to the same candidate engine, while ordinary consumers keep its existing behavior. Include exact proof path bytes/existence in that intent's snapshot, drift checks and restoration, preserving rejected bytes in recovery evidence before removing only a proven intent-created file. Name callback ownership so it cannot recursively publish or commit HEAD early.

- [Unverified — no citation] Scope, rollback and verification restraint are appropriate at plan level: artifact lines 139 and 149–150 retain independent delivery2 rollback, existing-suite/manual controls, dependent draft publication, rebase before final code QA, and no merges/new gates. Steps 144–146 explicitly require fresh high-level retries, a three-attempt budget, preserved unknown outcomes and no destructive rollback. These are design requirements, not executed implementation proof.
- [Unverified — needs clone run] No runtime controls, test suites, pytest or validate were executed in this worktree. Source inspection commands exited 0 for the cited excerpts; decisive spans are quoted/cited above. All proposed concurrency, lock and publication controls remain for a disposable full clone. No artifact/source edits made.

Handing off to Producer (codex-producer): disposition S1–S3, revise the Delivery2 plan, then request the next review round.

### Producer · Round 1 disposition

S1 Implemented in plan: every dispatcher gets a short accepted-state read/batch boundary on pinned primary, existing WriterLock then connector lock in fixed order, compare actual DB bytes to committed published HEAD, defer mismatched pending/rejected/unknown state. Prepare all raw/label current-state payloads before releasing WriterLock; network starts only afterwards. Generic uncommitted primary writes defer until publication/reconcile. No second snapshot store or override. Added actual second-dispatcher paused-publication red/green control.

S2 Implemented in plan: nested releases check uses exact in-process canonical runtime and explicit active-context lock borrowing, and rechecks refreshed state on retry. Ordinary check remains locked. This closes its concrete child-lock path.

S3 Implemented in plan: existing final publisher gets mapped-intent candidate delegation, preserving ordinary behavior elsewhere. It owns exactly one publication; outer runner retries fresh high-level landing/event intent without recursive publish. Exact validated proof paths/bytes/existence are included in snapshots/drift checks/restoration; proven newly created proof can be removed only after preserving rejected bytes and verifying ownership. Added first-proof/NFF control.

No production edits. Handing off to Codex for plan Round2; this is delivery2 planning, not delivery1 review.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
