# RELAY · GH605 Sol High implementation
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-13.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 2

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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh605-sol-high-implementation): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-605-WORK-STATE-PROJECTION.md — controlling expanded specification
- Reviewer: codex-author   ·   Producer: sol-builder
- Started: 2026-09-13
- Definition of Done: implement ordered steps1–6 and tests/docs from7, then hand back for main-agent execution of tests, independent QA and live apply.

## Producer implementation instructions (override generic review-only scaffold)

You are Sol High, the implementation builder, not the reviewer. The operator explicitly
requested Sol High for implementation. Plan QA was Approved with driver exit0 and attestation
for8cfad6bb; relay-system/2026-09-13/gh605-expanded-plan.md contains findings and dispositions.
Parent merged currentdevelopment561123d0, preserved bothledgerhistories via canonical resolver;
planned production seams did not change in that merge. Do not touch unrelated GH608 harness fix.

You own edits to utils/py/releases_app.py, utils/py/board_sync.py,
utils/py/work_connectors/github_board.py, utils/py/work_connectors/__init__.py if necessary,
test/test_gh605_work_state.py, test/test_gh605_board_policy.py, existing relevant test fixtures,
validate.sh registration, RELEASES-DB-FAQS.md, CHANGELOG.md and this relay thread.
You are not alone in the codebase; preserve all others' changes, no resets/stash/cleanup.
Use apply_patch for edits. Read plan controlling revision carefully, source before editing.
Don't create a second module/writer; reuse named seams. No schema change/newdependency.

Implement both ledger event/diagnostic fixes AND board policy/safe apply/restore, with tests.
Useful concrete details: current savedpolicy uses singular `repo`, not `repos`; accept that
existing field as a validated single-repo alias, plus explicit repos list for portability.
Saved policy has implementation_status pending: explicit policy commands must consume it
without requiring a config edit, and raw replay must refuse when it matches that board.
No personal defaults. Status columnconfig can use explicit defaults names but targetneverdefaults.
No autoscheduler/connectorenable. Currentrepos.slug may be basename XYZ-forge, not owner/name;
identity must be demonstrated by exact roadmap issue_url and matching repo row/root origin,
not assumed by number or arbitrary first connector. Payload source+transition tags distinguish
newstart events from legacymetadata noise. Count latest superseding lifecycle, not any start.

Board remote reads use existing _gql or gh seam, complete bounded pagination. Prefer GraphQL
closingIssuesReferences for explicit PR links and current GH stateReason. Keep public board
snapshot interfaces compatible. Duplicate/opaque/foreign cards preserve, report; no dedupe/delete.
Use existing _ConnectorLock for same-ledger coordination; document cross-device GH compare/read
cannot be atomic CAS. Policy guard prevents raw replay anyway. Keep as_of fixed for preflight
comparison; re-read GH before apply; compare full resulting decisions/changes and source hashes,
not merely trust serialized changes. Audit per individual remote request and stop indeterminate.
Restoration needs target/policy validation and conditional current-status checks too.

Runtime testing will be run by parent in a SEPARATE FULL CLONE. Do NOT run validate.sh or
test/*.sh, or mutation-heavy Python suites from this linked worktree. You may syntax-check
without bytecode writes (ast.parse) and inspect fixtures. Write robust nonempty isolated Python
unittest fixtures with no real network/device config. Register via validate.sh's existing pattern.
Do not call gh mutations, change localdeviceconfig, writeledgerdata, create clones, or deploy.
Do not gitadd/commit/push; driver owns file-scoped commit, notwithstanding generic scaffold.

On completion append concise producedfiles/remaininglimits/testing-not-run block, set NEXT
Reviewer, STATUS Open (never Approved), release runtime task to codex-author. Parent will run
tests and final QA. Prioritize full coherent implementation over commentary; cap your turn20min.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Author checkpoint — first implementation, correction pass

First build saved as 1e918e8344c2b22a0e83454b7e21629033905735. Driver exit7 at
1200 seconds, classified slow-but-progressing, allowed files committed and token released.
This is an incomplete build, NOT QA approval. Separate full validation clone ran the new
Python discovery suite: 18 tests passed. Existing event/sweep/board suites are running there.
No live board/config writes. The parent does not count the timed-out turn as a reviewer round.

Sol High: finish this implementation in one focused correction turn (30-minute ceiling),
then STOP and hand back; don't spend the ceiling repeatedly polishing commentary.
Same ownership and containment rules above. Do not run mutation-heavy suites in the worktree.
Add deterministic fixtures and syntax-check; parent runs tests in the full clone. No git commits.

Confirmed planner probes against saved 1e918e83 (fixed time 2026-09-13T12:00Z):
- Invalid identity is now correctly preserved (your late fix worked).
- CLOSED COMPLETED issue with closed_at='garbage' and existing Done incorrectly moves Backlog.
- OPEN non-draft PR followed by a recent draft PR, both closing issue1, incorrectly assigns
  issue1 In progress. Review must outrank progress independent of input order.
- GH CLOSED COMPLETED issue with valid recent closed_at and no ledger row is omitted. GH
  terminal truth does not need a rating/ledger row; ledger requirements apply to Ready/starts.

Fix these and complete the traced acceptance gaps below, using the controlling plan rather
than creating new policy. Reproduce each relevant failure in focused fixtures before fixing.

1. Planner: validate non-future parseable terminal dates before any terminal demotion, and
   known PR state before classifying old/closed. Unknown PR state/date stays unresolved.
   Keep duplicate/foreign identity guards, but recent GH completion is authoritative even
   without a ledger row. Non-draft closing PR always wins over draft in both input orders.
2. Evidence loader: SELECT/use each roadmap row's actual repo_id, not a different repo row
   inferred solely from its URL. Cross-owner same-basename and mismatched row ownership must
   never lend events or Ready identity. Encode SQLite file URI safely for spaces/#/? paths.
   Reject backfill starts for every start event, and test jog running/leased provenance with
   the actual current jog state. Do not arbitrarily require running for a legitimate lease.
   Report ambiguous multiple jog rows conservatively; don't pick unspecified SQL order.
3. Apply preflight: hold existing connector lock across fresh preflight through all writes;
   release even if initial audit creation fails. Resolve fresh board IDs/options (not cached
   IDs), compare item_id as well as status immediately before mutation, and reject future
   preview timestamps. Preserve automatic connector disabled. Respect read-only preview
   (explicit artifact only; no state cache/config mutations). Verify complete bounded board
   pagination including malformed/missing cursors and preserve/report opaque cards.
4. Audit/recovery: per-request intent/result writes must be durable (fsync then atomic
   replace, directory durability where supported); do not overwrite an existing result audit
   during a retry. Preserve successful add ID even if status fails. A persisted unmatched
   intent is indeterminate. Recovery must report such operations and residual added cards,
   not return an empty success because only phase=change records were selected. Require
   readback for indeterminate requests; no blind retry. Keep LEGACY set_issue_status stale-ID
   retry working when no policy/audit is requested (_remote_request currently wraps all
   exceptions in IndeterminateMutation, disabling that legacy retry).
5. Restore: validate every operation identity against policy allowlist, require current
   item_id AND status at the final check, prevalidate destination options, and use the same
   audited request seam for set/clear with durable per-request restore evidence. Keep default
   remote read-only; explicit write only. Report skipped/partial/indeterminate nonzero, retain
   added cards by default, never delete. A partial add+failed status must be visible in report.
6. Tests must cover the controlling plan's load-bearing cases, not only helper calls: two
   completed + one deferred sweep share one txn/receipt; inject failure at second event and
   prove rows/events/receipt/generation/dump/journal all rollback, no duplicate on rerun;
   status schema7/8 bytes and all sidecars/config unchanged; start->park, start->stop,
   backfill/malformed/future exclusions; top10 with ties/override/unrated/foreign/reopened;
   saved preview drift/tampering/future age/missing option makes zero mutation; concurrent
   replacement with same status refused; add-success/status-failure and before/after audit
   failures preserve evidence; restore unset status actually clears and concurrent changes
   survive. Mock network and device config. Ensure validation registration handles Python
   in both lanes without changing legacy suite semantics or exported nice defaults.
7. Sanitized source observations are context only; validate expected source/kind/reference,
   show their freshness/coverage, never derive mutations solely from intent. Docs must match
   actual locking/restore behavior. No unrelated refactors or new dependency/module/schema.

Disposition every numbered item briefly in your final appended block, note anything still
unfinished honestly, leave STATUS Open and NEXT Reviewer, release to codex-author, finish.
The parent will run tests and independent final Codex QA after this build. No self-approval.

### Producer r2 — correction build complete

- 1 **Implemented:** terminal issue/PR timestamps must parse and be non-future before demotion;
  recent GH COMPLETED issues no longer require a ledger row; non-draft closing PR review wins over
  draft progress in both input orders; unknown PR state/date is preserved.
- 2 **Implemented:** evidence reads each roadmap row's actual `repo_id`, accepts a basename only
  when origin proves the owner/name, URI-quotes DB paths, rejects tagged backfill for every start
  kind, accepts consistent running/leased jog state, and reports duplicate jog rows. Sweep batch
  events now retain per-row repo identity; the fixture is two completed + one deferred with the
  second insert forced red and full transaction rollback assertions.
- 3 **Implemented:** apply holds the existing connector lock across fresh preflight and writes,
  resolves uncached board IDs/options, refuses future previews/existing result artifacts, compares
  item ID plus status immediately before each mutation, and releases the lock on preflight/audit
  creation failure. Preview remains remotely read-only and cache-free.
- 4 **Implemented:** JSON audits fsync file contents before atomic replace and fsync the directory
  where supported; request IDs expose unmatched intents; policy mode stops indeterminate without
  legacy retry; successful add IDs are persisted before status; partial adds remain recoverable.
- 5 **Implemented:** restore validates policy/identity allowlists, reports unmatched intents and
  residual added cards, pre-resolves destinations, rechecks item ID plus status, audits set/clear
  requests durably, requires `--out` for writes, returns partial/indeterminate nonzero, and never
  deletes cards.
- 6 **Implemented/expanded:** fixtures now cover terminal authority/date guards, PR precedence in
  both orders, repo ownership, odd DB paths, backfill/jog provenance, missing options, same-status
  item replacement, audit failures, add-success/status-failure, partial recovery, unset-status
  clear, opaque pagination and concurrent restore preservation. Existing batch/event tests remain.
- 7 **Modified:** FAQ and CHANGELOG now match locking, cross-device compare/read limits, durable
  restore evidence and partial recovery; focused Python tests were already registered in
  `validate.sh`. Produced: `utils/py/releases_app.py`, `utils/py/board_sync.py`,
  `utils/py/work_connectors/github_board.py`, `test/test_gh605_work_state.py`,
  `test/test_gh605_board_policy.py`, `test/gh492-roadmap-state-sweep.sh`,
  `RELEASES-DB-FAQS.md`, `CHANGELOG.md`, and this relay file.
- Verification deliberately limited here: AST parse **OK (6 files)** and Bash syntax **OK (3
  existing suites)**, logs under `.relay-scratch/`. Runtime tests, legacy suites, full gate,
  independent QA and live Rev. 2 preview/apply/readback remain for the parent in a separate full
  clone; no live board/config/ledger mutation and no Git command was run.

Handing off to Reviewer — go to the codex-author window and say “take your turn”.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
