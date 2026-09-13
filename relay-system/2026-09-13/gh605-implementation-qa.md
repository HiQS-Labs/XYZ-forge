# RELAY · GH605 implementation QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-13.
-->

NEXT: Producer
STATUS: Open
ROUND: 3 / 3

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
6. **Commit only the relay file** (`relay(gh605-implementation-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-605-WORK-STATE-PROJECTION.md; utils/py/releases_app.py; utils/py/board_sync.py; utils/py/work_connectors/github_board.py; test/test_gh605_work_state.py; test/test_gh605_board_policy.py; test/gh492-roadmap-state-sweep.sh; validate.sh; TESTS-RESULTS/gh605-implementation/
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-09-13
- Definition of Done: controlling expanded plan implemented safely, deterministic checks substantiate claims, all implementation blockers resolved before live apply. This first QA round has known integration failures: do not approve while they remain.

## Specific implementation QA questions

Read the controlling expanded plan and current files in full, not just the latest diff.
First code checkpoint1e918e83; correction7e24f54a; base development561123d0. Read committed
SUMMARY.md/provenance.jsonl. GLM and Qwen findings are embodied in the controlling plan.
The historical narrower Agy/DeepSeek gates are superseded by the controlling final Codex loop.
The operator requires reusable scripts AND later verified live Rev.2 application. No live  [Unverified — no citation]
apply is permitted before code approval; lack of application now is expected, not a blocker
to approving a correct code candidate. Current code/test defects ARE blockers.

1. Do section-first transitions, metadata-only updates, batched sweep events and rollback
   follow the real shared writer contract, including mixed-repo ownership and idempotence?
2. Does read-only work status actually avoid all DB/sidecar/config/cursor writes (including
   WAL-mode-without-existing-sidecars), refuse ambiguous identity, distinguish real jog/start
   provenance from backfill, and invalidate only genuine superseding lifecycle transitions?
3. Does the planner enforce top10, stable ties/override,3day starts,7day terminal state,
   explicit PR links, draft/non-draft precedence, reopen/unknown/duplicate/foreign preservation?
4. Are the REAL GitHub resolver/snapshot/collector queries valid and bounded? Independently
   adjudicate the known owner-resolution and extra-brace findings. Do mocks detect these?
   Proposed minimum fix: repositoryOwner union fragments, correct brace, focused mock tests.
5. Can saved preview tampering/drift/future dates, missing options, same-status replaced item,
   audit failure before/after requests or a lost response cause an unintended/unaudited write?
   Does conditional restore report partial/indeterminate states honestly, preserve newly added
   cards, validate target and exact item identity, and clear originally unset status safely?
6. Are the tests meaningful nonempty integration fixtures? Known full gate fail is registry
   census .sh372 versus listed374. Prefer thin .sh test entry points and restoration of the
   original runner plumbing over broad unrelated census changes. One URI test omitted Git
   metadata. Report missing load-bearing acceptance tests beyond those known failures.
7. Are there unsafe interactions in surrounding touched code, duplicated writers/subsystems,
   misleading docs, or any premature success/ship claims? Rating80/65/50/45 rank240 remains
   saved and appropriate. No migration of primary checkout, scheduler, delete, merge or deploy.

Output one concise graded verdict with file:line evidence, concrete minimal fixes and
explicit swept file declaration. Address every known finding, then additional material ones.
Review-only: edit this relay file only. No code edits, no real network mutations, no config
changes, no full/test/*.sh suites in this linked worktree. Deterministic probes may use
isolated temp fixtures without touching repo state; parent executes full-clone runtime tests.
Finish within15minutes. Set NEXT Producer / STATUS Open and release to codex-author on
changes requested; only genuine complete approval may set Approved. No git commands—the
driver owns the relay-file commit. Three review rounds maximum.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer — codex — Round 1

VERDICT: FAIL
Basis: The five recorded integration blockers remain in the candidate. Source review also finds ownership, lifecycle, planner and shared-writer gaps below. No code approval or live apply authorization follows from this turn.
swept file: no

Coverage: Read the controlling plan, committed SUMMARY/provenance, board_sync, connector and both Python fixture files; inspected the shared transaction/update/sweep/evidence paths and shell sweep fixture. The entire 6,518-line releases_app.py and 1,515-line validate.sh were not swept within this bounded turn; remaining surrounding-code review is required before approval. Graph Verify lookup found no index for this worktree; nearest XYZ-forge generation 2026-09-01T15:54:30Z has changed/missing/untracked coverage for these paths, so findings use current source. No artifacts/source were executed, no tests or Git commands run, and no network mutations made. Historical test outcomes below are attributed to committed evidence, not reruns.

- [Blocker] **Real GraphQL integration remains broken.** `utils/py/board_sync.py:586` queries both `user` and `organization`, while `_gql` rejects any errors at line 517; the recorded live result rejects the nonexistent owner shape (`TESTS-RESULTS/gh605-implementation/SUMMARY.md:14`). The snapshot query ending at `board_sync.py:639` has one excess closing brace. Replace the owner lookup with `repositoryOwner` plus User/Organization fragments and correct the snapshot brace. Add query-shape regressions exercising the actual resolver/snapshot through the transport seam, with nonexistent-owner errors and both valid owner kinds. The current mock at `test/test_gh605_board_policy.py:406` accepts arbitrary query text. Collector pagination is bounded at `board_sync.py:932` and closing-reference overflow refuses at line 992, but these mocks do not establish real query validity; retain fresh read-only API evidence after repair.
- [Blocker] **Read-only diagnostics can create WAL sidecars.** `utils/py/releases_app.py:5110` checks only existing sidecars, then opens SQLite at line 5125. A closed WAL-format DB without sidecars reaches the first query and creates them, as recorded at `SUMMARY.md:20`. Inspect SQLite format before open and refuse WAL/live ambiguity; add schema-7 and schema-8 fixtures initially lacking sidecars and compare presence/bytes of every protected surface. Keep URI quoting. The odd-path fixture at `test/test_gh605_work_state.py:162` lacks its own Git metadata, and `WriterLock` construction at `releases_app.py:5113` can raise SystemExit outside the Exception handler; fix the fixture and make unsupported-root diagnostics return the promised structured unready result rather than bypass JSON output.
- [Blocker] **Informational events invalidate real starts.** `releases_app.py:5184` chooses the newest event by vocabulary before examining provenance. Thus start→backfill becomes unknown; start→legacy metadata-only in_flight has the same defect. Additionally `roadmap rate --force` changes rating fields only (`releases_app.py:3655`) but emits `rated` at line 1441, which `_STOP_EVENTS` treats as a stop at line 5065. Select genuine lifecycle-bearing transitions separately from latest informational visibility; do not interpret a re-rating as return-to-Queue. Add actual start→backfill, start→metadata, start→re-rating, start→Queue and start→jog-stop sequences, including malformed/future evidence controls.
- [Blocker] **Mixed-repository ownership is only repaired for explicit sweep events.** The batch passes `row["repo_id"]` at `releases_app.py:3980`, but ordinary roadmap/jog extractors still end at `_repo_id_for_event` (`releases_app.py:1561`), which selects the first repository at line 1420. Updating repo B's row can therefore create activity for repo A's same-number issue. Also the `--issue-num` update selector at line 3809 is number-only and its mutation at line 3881 can update multiple rows while emitting one event. Carry the source row's repo_id through extraction, and refuse ambiguous selectors or resolve to the selected global_id. Add a two-owner/same-number fixture checking rows, event ownership and evidence consumption; the existing ownership test only seeds events directly (`test/test_gh605_work_state.py:150`).
- [Blocker] **PR precedence bypasses required preservation.** `board_sync.py:255` assigns a linked OPEN issue a target before ledger validation; line 286 then skips that issue. A reopened issue whose ledger remains Completed/Deferred, or whose ledger identity is duplicated, moves to In review/In progress despite the explicit preservation contract. Apply contradictory/ambiguous-ledger guards before assigning linked-issue targets, while retaining independent open-PR card behavior and non-draft precedence. Add reopened+linked-PR and duplicate-ledger+linked-PR fixtures; the current reopen test at `test/test_gh605_board_policy.py:121` has no PR.
- [Blocker] **The shared writer still adds before validating the destination.** `board_sync.py:858` adds the card before `option_id_for` at line 864. Policy apply's outer preflight protects its initial option set, but legacy connector calls and a disappearing option can still leave an unwanted card. Validate the destination before add inside the shared writer, preserve the successful add ID and do not retry an indeterminate request. Add a direct writer missing-option test asserting zero add/set calls; the current test at `test/test_gh605_board_policy.py:302` mocks the writer and only covers outer apply preflight. Also update a supplied `board_add` snapshot after success (`board_sync.py:775`, `:793`) as required by the plan; those paths currently leave it stale.
- [Blocker] **Acceptance evidence is incomplete and the registered gate is red.** `validate.sh:550` registers Python files into the shell census; `SUMMARY.md:7` records 376/377 and correction 40/41. Use thin shell entry points and restore the established runner plumbing (`validate.sh:1205`), then have the parent run focused and full gates in a disposable full clone. Beyond known failures, add an end-to-end nonempty apply→second-operation-failure→restore fixture through the real writer/audit callbacks, and saved-preview target/digest/decision tamper and GH-drift refusals. Existing apply tests substitute `build_policy_preview` (`test/test_gh605_board_policy.py:293`), so they cannot validate the real evidence/planner integration. Record witnessed red controls for section precedence, batch omission, freshness and top-N, not merely green fixtures.
- [Should] **Unknown and unset cards need accurate decisions.** `board_sync.py:340` uses `before is None` to mean absent, so an existing old-terminal/excess card with unset Status is never moved to Backlog. Test membership in `board_by` instead. An OPEN unrated ledger row already in Ready also falls through line 321 without an unresolved report; report preserved unknown Ready cards explicitly so the top-N summary does not hide excess unknowns.
- [Should] **Keep restore uncertainty durable and explicit.** Restore initially marks unmatched request intents indeterminate (`board_sync.py:1228`) but write-mode completion overwrites that with partial at line 1270. Preserve indeterminate status while unresolved requests remain, including matching result entries whose outcome is indeterminate; `_unmatched_intents` only tests presence of a result (`:1089`). Add write-mode restore tests for response loss and before/after audit failures, with residual added-card reporting and concurrent same-status/replaced-ID preservation.
- [Pass] **Useful foundations and honest checkpoint reporting are present.** Section-first classification is explicit at `releases_app.py:1449`; metadata-only update emits `updated` at line 1469; receipt/event insertion and commit share rollback handling at line 1646. The sweep fixture has a nonempty five-row baseline (`test/gh492-roadmap-state-sweep.sh:78`), second-event fault injection at line 121, and a no-op rerun assertion at line 157. Per-request intent precedes invocation (`board_sync.py:722`), apply checks exact item ID (`:1139`), and unset restore calls the clear writer (`:1264`). These are source observations, not a passing candidate verdict. `SUMMARY.md:9` explicitly disclaims final approval/live mutation; no premature ship claim found in that checkpoint. The controlling plan's final 80/65/50/45 rating remains appropriate; lack of live application before code approval is expected.

Handing off to codex-author (Producer): address the blockers and acceptance gaps, retain the existing scope, and return the corrected candidate with committed evidence for round 2. No live apply before approval.

## Producer disposition and delegated Sol High correction — opening Round 2

Author disposition: all seven Blockers and both Should findings are accepted. These repair
the approved contracts in existing seams; no new subsystem, dependency, schema or policy.
The limited sweep is explicitly NOT approval: the next reviewer must finish surrounding-file
coverage before approval. Reviewer exit5 is a successful changes-requested handback, not a stall.

Additional verification of7e24f54a in a second full clone: gh549-work-events.sh and
gh402-board-sync.sh both exit0; the expanded sweep exits0; Python40/41, with the single
Git-less odd-path fixture error already recorded. First-build full validate376/377 persists
red on .sh census, with clone identity unchanged. No live writes or config edits.

### Sol High implementation instructions for this Producer turn

Sol-builder is the author's delegated Producer for edits, per operator's explicit Sol High
implementation preference. Read the round1 findings and controlling plan. You own only the
allowlisted existing code/docs/tests plus two thin test entry points below. You are not alone;
preserve other changes. Do not edit plan/evidence or unrelated governance. Use apply_patch.
No git commands, no network mutations, no device config/ledger edits, no clone creation.
No full gate or mutation-heavy tests in this linked worktree; parent runs those in a full clone.
Syntax checks/pure probes are fine. Finish this bounded correction within30minutes and hand
back honestly, rather than spending the entire time on commentary. Don't run extra QA agents.

Implement every round1 finding and focused tests. In particular:
- Replace simultaneous user/organization resolver query with repositoryOwner and inline
  User/Organization fragments. The parent tested that exact approach live: valid Rev.2 ID
  and all five columns returned. Fix the extra snapshot brace, adapt existing mock transport
  and test actual query shapes/balanced syntax and both owner types plus missing owner errors.
- Before sqlite connect, inspect the DB header and refuse WAL-format (not merely existing
  sidecars). A closed WAL-mode schema7 fixture creates -wal/-shm under mode=ro today. Add
  WAL7/WAL8 no-sidecar fixtures and bytes/presence protection checks. Do not use immutable=1
  as a live-data shortcut. Unsupported root yields structured unready (not stray SystemExit).
  Give the odd-path fixture its own Git metadata so it actually tests URI quoting.
- Separate informational/latest-event from genuine lifecycle. start->backfill, ->old metadata
  in_flight, and ->re-rating must retain a valid start; actual Queue/park/jog-stop supersedes.
  Preserve unknown for genuinely malformed/future start evidence. Keep existing event vocabulary
  compatible; tagging rate as informational is preferable to breaking existing rated consumers.
- Carry the source row's repo_id for ordinary roadmap/jog extraction as well as sweep events.
  Refuse ambiguous --issue-num selectors and mutate the selected global_id, not every same
  number. Use the already existing event repo-id seam, no new writer/CLI subsystem. Test actual
  writes in two-repo/same-number fixtures, not only seeded history.
- Preserve duplicate/contradictory terminal ledger issues even when linked to an open PR;
  independent PR cards still enter review. Fix unset-versus-absent membership and report unknown
  unrated Ready cards. Keep the approved top10/ties/PR/dates behavior.
- Validate column inside the shared writer BEFORE add; update supplied board_add snapshots on
  success. Keep per-request audit IDs, no blind policy retry and legacy caller compatibility.
- Keep restore indeterminate while unmatched OR explicitly indeterminate results remain.
  Add real writer/audit failure+restore integration, digest/decision/target/GH-drift tests,
  zero-write refusal tests and invalid status/response coverage, not mocks replacing the whole
  planner. Do not swallow genuine fsync I/O failures as "unsupported directory fsync".
- Restore validate.sh's original runner plumbing (remove the Python-dispatch helper and changed
  invocations) and register test/gh605-work-state.sh and test/gh605-board-policy.sh. These should
  be tiny shell entry points invoking their existing Python fixture files, with no new framework.
  Existing .sh census then remains correct. No other test registry/pipeline edits.
- Add fixtures so parent can witness red controls for shared section precedence, omitted batch,
  informational/backfill freshness and top-N. Update FAQ/CHANGELOG only for actual behavior.

Allowed production/test paths: utils/py/releases_app.py, utils/py/board_sync.py,
utils/py/work_connectors/github_board.py, utils/py/work_connectors/__init__.py,
utils/py/mock_gh_board.py, test/test_gh605_work_state.py, test/test_gh605_board_policy.py,
test/gh605-work-state.sh, test/gh605-board-policy.sh, test/gh549-work-events.sh,
test/gh492-roadmap-state-sweep.sh, test/gh402-board-sync.sh, validate.sh,
RELEASES-DB-FAQS.md, CHANGELOG.md and this relay file.

Append one concise disposition block for every review finding with real implementation
citations and remaining gaps. Do not self-approve. Leave STATUS Open and NEXT Reviewer;
release runtime token to codex-author so the parent can execute tests and dispatch Codex round2.
The driver owns the file-scoped commit. No live apply before independent approval.

## Producer — sol-builder delegated by codex-author — Round 2

Disposition: all seven Blockers and both Should findings were implemented in the existing
writer/planner seams. No live board/config/network mutation or Git command was performed.

- **Implemented — GraphQL integration.** Project resolution now uses the `repositoryOwner`
  union with User/Organization fragments (`utils/py/board_sync.py:593-610`), and the project
  snapshot query is balanced (`:646-652`). The mock follows the real response shape; focused
  tests exercise both owner kinds, missing owner, and both query balances
  (`test/test_gh605_board_policy.py:283-313`).
- **Implemented — genuinely read-only diagnostics.** SQLite WAL format is rejected from bytes
  before connect and unsupported roots return structured unready output
  (`utils/py/releases_app.py:5102-5110`, `:5142-5175`). Schema7/schema8 closed-WAL fixtures begin
  without sidecars and assert no DB/sidecar mutation; the URI-metacharacter fixture owns `.git`
  metadata (`test/test_gh605_work_state.py:174-229`).
- **Implemented — lifecycle provenance.** Lifecycle selection skips backfill, metadata-only and
  informational rating events while retaining them as `latest_event`; only tagged transitions
  supersede starts (`utils/py/releases_app.py:5086-5099`, `:5224-5230`). Start→backfill,
  start→re-rating, start→metadata and genuine Queue supersession are pinned in
  `test/test_gh605_work_state.py:85-112`.
- **Implemented — mixed-repository ownership.** Roadmap/jog extractors carry their source row's
  `repo_id` through event insertion (`utils/py/releases_app.py:1424-1489`, `:1560-1570`), and
  rate/update refuse ambiguous issue-number selectors then mutate by `global_id`
  (`:3626-3634`, `:3825-3835`). Connector batches join the recorded repo and refuse foreign
  identities rather than guessing `repos[0]` (`utils/py/work_connectors/__init__.py:127-133`,
  `utils/py/work_connectors/github_board.py:82-99`).
- **Implemented — preservation before PR precedence.** A linked PR cannot override duplicate or
  contradictory terminal ledger identity (`utils/py/board_sync.py:261-274`); independent PR
  cards retain In review. Reopened and duplicate-ledger link fixtures cover both input shapes
  (`test/test_gh605_board_policy.py:127-146`).
- **Implemented — shared writer validation and snapshot honesty.** Destination option resolution
  occurs before content lookup/add (`utils/py/board_sync.py:874-884`), supplied snapshots advance
  after successful legacy adds/sets (`:787-812`), and policy mode still refuses blind retries.
  The zero-add missing-column control is `test/test_gh605_board_policy.py:315-325`.
- **Modified/implemented — acceptance plumbing; parent evidence remains.** Thin shell entries
  restore the original all-shell validate runner (`validate.sh:550-551`, `:1228`, `:1301`,
  `:1357`). Focused tests add nonempty WAL, query-shape, top-N, preservation, identity,
  response-loss and zero-write cases. This turn ran only the two direct Python fixtures:
  **52/52 passed**; seven Python files parse via `ast`, and both wrappers plus `validate.sh`
  pass `bash -n`. Per the containment rail, the parent must run legacy shell suites, witnessed
  red controls and full validate in a separate full clone; no such outcome is claimed here.
- **Implemented — unset/unknown decisions.** Existing unset terminal cards are distinct from
  absent cards, and unrated Ready cards are explicitly unresolved and preserved
  (`utils/py/board_sync.py:336-353`; `test/test_gh605_board_policy.py:148-159`).
- **Implemented — durable restore uncertainty.** Explicitly indeterminate results now remain
  unresolved, and write-mode completion cannot overwrite an existing indeterminate state
  (`utils/py/board_sync.py:1100-1114`, `:1286-1291`). Existing clear-status, response-loss,
  residual-add and concurrent-change fixtures remain green.

FAQ and CHANGELOG now describe the implemented WAL, owner-union, repository attribution and
restore contracts. Remaining gaps are verification-only: parent full-clone gates/red controls,
independent Reviewer round 2, and later reviewed live Rev.2 application. No self-approval.

Handing off to codex-author: run the separate-full-clone verification, preserve its receipts,
then dispatch the Codex Reviewer for Round 2; no live apply before independent approval.

### Parent runtime verification — focused follow-up before Reviewer round 2

db17cb49 passes52/52 Python tests. Real policy-preview now succeeds, selects the independently
expected Ready10, and proposes51 changes (49 Done,1 Backlog,1 PR In review). No mutations.
Two regressions prevent requesting approval; this remains the same round2 Producer phase:

1. Linked issues603/593/592/595 all have explicit current OPEN non-draft closing PRs, but no
   ledger rows in development yet. `len(linked_rows) != 1` treats ABSENCE as AMBIGUITY and
   wrongly preserves/omits them. Absence alone must not block GH-authoritative PR links.
   Guard known contradictory terminal rows, duplicate rows/cards and invalid known ledger
   identity; distinguish invalid rows filtered out of ledger_by from genuinely absent rows.
   Add both nondraft/draft no-ledger link tests. Expected current preview55 changes; Ready10
   unchanged. Don't update the live board or run real preview yourself.
2. gh549 legacy test17 now fails three assertions: event2 has unknown repo identity
   'XYZ-forge' while config explicitly names HiQS-Labs/XYZ-forge. The new raw protocol change
   in events_after/apply_event was incidental to the requested DB ownership fix. Restore
   the pre-db17 raw connector payload/caller compatibility (7e24f54a shape), retaining the
   board-scoped policy guard. Keep ALL database event repo_id and selector corrections and
   the explicitly repo-qualified policy writer. Do not add a new raw protocol or guess owners
   from basenames/config. Document that the legacy event connector remains its existing
   single-repo replay path and policy-preview/apply is the complete repo-qualified projection.
   No unrelated connector architecture expansion. The accepted ownership finding concerns
   event insertion and evidence consumption; the policy guard keeps this board off raw replay.
3. The reviewer requested an actual two-owner/same-number WRITE fixture, but current ownership
   fixture still seeds history directly. Add a real CLI/perform_write regression covering
   repo B update, correct event repo_id, no change to repo A, and ambiguous --issue-num refusal
   with both rows intact. Use existing full-schema fixture infrastructure, not a toy schema
   that misses the writer. Tests only, no real ledger edits.
4. Strengthen the malformed/future-start fixture: it currently uses jog_running without a
   matching jog_queue row, so it would stay unknown even if the timestamp check disappeared.
   Use a genuine tagged roadmap transition or a valid matching jog row to isolate time.

Sol High: same ownership/containment as above; this is a focused test-driven follow-up,
15-minute ceiling. Reproduce against named fixtures, make minimal changes, AST/syntax only
or safe direct Python fixtures; parent owns shell/full-clone tests. Do not change earlier
review findings. Append dispositions, leave NEXT Reviewer / STATUS Open, release codex-author.
No git commands or live writes. Driver owns the commit; Reviewer round2 has not yet run.

## Producer — sol-builder delegated by codex-author — Round 2 focused follow-up

Disposition: all four parent follow-up findings are implemented without live board, device,
network, ledger, or Git mutations. No earlier review disposition was changed.

- **Implemented — absent-ledger PR links.** The planner now tracks invalid ledger identities
  separately and permits an explicit OPEN PR link only when the ledger is genuinely absent;
  duplicate board/ledger identities and invalid or terminal ledger rows still preserve the issue
  (`utils/py/board_sync.py:226-274`). Draft and non-draft absent-ledger cases plus the invalid-row
  control are pinned at `test/test_gh605_board_policy.py:109-121,146-158`.
- **Modified — legacy raw connector compatibility restored.** `events_after` again emits the
  established five-field event payload and raw replay uses its configured first repository
  (`utils/py/work_connectors/__init__.py:127-138`,
  `utils/py/work_connectors/github_board.py:84-100`). The policy-managed-board guard remains
  board-scoped. `test/test_gh605_board_policy.py:270-287` exercises the exact payload and target;
  FAQ/CHANGELOG distinguish this single-repo replay path from repo-qualified policy projection.
- **Implemented — real mixed-owner writer fixture.** A full current-schema ledger is initialized,
  seeded with two owners sharing issue 77, then driven through the parsed CLI and `perform_write`.
  The fixture proves only repo B changes and owns the emitted event, then proves ambiguous
  `--issue-num` refuses with both rows and event count intact
  (`test/test_gh605_work_state.py:253-314`).
- **Implemented — non-vacuous time control.** Malformed/future timestamps now use a genuine tagged
  roadmap transition, so timestamp validation is the only reason the start stays unknown
  (`test/test_gh605_work_state.py:129-136`).

Witnessed red before production repair: the absent-ledger cases raised two missing-decision errors
and the legacy connector payload assertion failed; after repair the focused controls pass 5/5.
The complete direct Python fixtures pass **54/54** (37 board-policy, 17 work-state), and all five
changed Python files parse via `ast`. Codebase Memory coverage was stale/missing for GH-605, so all
claims above use current source reads. Remaining gaps are parent-owned shell/full-clone gates, the
independent Reviewer round 2 sweep, and later reviewed live Rev.2 application. No self-approval.

Handing off to codex-author: preserve the parent full-clone evidence and dispatch the Codex Reviewer
for Round 2; no live apply before independent approval.

### Producer handoff — request independent Reviewer round 2

Review b9d784e9 implementation plus current committed evidence. Parent54/54 Python fixtures
pass in a separate full clone. All four plan red controls fail actual named assertions on
this source; after exact restoration54Python and gh492 sweep pass, clone identity clean.
Real read-only policy preview succeeds and independently matches55 changes:49 Done additions,
four explicitly PR-linked issues plus draft607 In review, one old Done item463 to Backlog.
Ready10 unchanged. No live mutations. Normal gated draft push is running in separate clone1;
the legacy shell rerun is running in separate clone2. Parent will retain exact exits before
live apply/readiness; a pending full gate is not a claim of success or a code defect by itself.

Revisit every round1 Blocker/Should and the focused follow-up. Raw connector protocol restoration
is a deliberate scope decision: DB ownership fixes and policy-qualified identities remain;
legacy single-repo replay compatibility is retained, and the target board remains guarded.
Check this disposition for safety, not for a new unrelated raw multi-repo protocol requirement.

IMPORTANT: finish the whole-file sweep omitted in round1. Read all touched production files,
tests/validate and relevant surrounding code in full, using bounded chunks so tool truncation
doesn't silently skip content. Declare swept file honestly. No new code edits or real writes;
only this relay file may change. No shell/full suites in the linked worktree. Use existing
parent evidence and safe isolated direct probes if useful. Cite specific current file:line.
This is Reviewer round2 of maximum3,15-minute ceiling. If approved, use the normal Approved
header/verdict and tick done so driver attestation is generated; if findings, hand back to
codex-author with NEXT Producer / STATUS Open. Do not invent approval for unfinished coverage.

## Reviewer — codex — Round 2

VERDICT: FAIL

Basis: substantial first-round repairs are present, but real jog provenance still fails at its caller/extractor seam, identity preservation has a fall-through, and apply/restore acceptance coverage remains incomplete. These are source-review findings, not newly executed reproductions. No tests, source programs, Git commands, or live mutations were run this turn.

swept file: no

Coverage: read releases_app.py, board_sync.py, both connector production modules, both GH605 Python test files, wrappers, gh492 sweep, and validate.sh throughout, including surrounding pre-existing code. Read the controlling plan and committed evidence. The broader sweep is incomplete: mock_gh_board.py and historical documentation were not fully swept, and a truncated portion of gh549-work-events.sh remains unclosed. Graph tools were unavailable; current source was the fallback. Do not treat this as whole-surface approval.

- **[Blocker] Real jog starts/stops emit no lifecycle event.** `_extract_jog` queries `jog_queue.global_id` using its argument and silently returns on no match (`utils/py/releases_app.py:1482`), but lease/status callers pass `GH-<number>` (`:4633`, `:4661`), not the row's `jog-…` ID. The existing receipt history also shows these GH selectors (`releases.sql:855`). Thus genuine jog starts are absent and a jog stop cannot supersede a preceding roadmap start. Fix the extractor/caller seam using the actual row identity and repository while preserving receipt compatibility deliberately. Add a full-schema fixture calling real lease and status operations, proving start emission, failed/parked supersession, transaction ownership, and metadata non-reset; manually seeded event fixtures do not cover this seam.
- **[Blocker] An invalid ledger row can still fall through to Ready/In progress.** Invalid identities are split from valid rows at `utils/py/board_sync.py:226`; the PR path rejects them at `:269`, but the OPEN-issue path at `:319` checks only board duplicates and valid-row count. With one valid row plus one invalid row for the same qualified issue, the latter path selects the valid row; even a rejected linked-PR decision can fall through here. Apply the invalid-identity preservation guard to every relevant issue-selection path. Add a nonempty valid-plus-invalid identity fixture, both with and without a linked PR, asserting preservation rather than promotion.
- **[Blocker] Requested apply→failure→restore integration tests remain missing.** The apply tests at `test/test_gh605_board_policy.py:364`, `:387`, and `:419` fabricate saved previews and replace `build_policy_preview`; the restore tests beginning `:448` start with fabricated results. They do not establish the real planner/evidence→saved preview→writer→audit→restore chain, or saved decision/digest/target tampering and source drift. Add transport-mocked integration fixtures using real preview construction, a successful apply, second-operation failure, and conditional restore, plus tampering/drift refusals with zero mutation calls. Assert nonempty decisions and audit records. The parent-owned full gate being pending is not itself a defect.
- **[Blocker] Malformed mutation payloads can be recorded as successful writes.** `_remote_request` records success for any non-raising return (`utils/py/board_sync.py:734`); set/clear ignore the returned item entirely (`:822`, `:831`). An empty or null mutation result therefore permits a complete result without evidence of the requested update. Add extracts its ID only *after* recording success (`:758`), so malformed add results leave a conclusive success record followed by an ordinary exception. Validate the mutation payload and expected nonempty/matching item ID inside the audited invocation, before recording success; treat missing/null/wrong IDs as indeterminate without retry. Cover add, set, and clear responses.
- **[Should] Restore can still downgrade existing uncertainty on its exception path.** The normal completion branch retains original unmatched intents (`utils/py/board_sync.py:1300`), but the exception branch (`:1304`) ignores that original `unmatched` collection. An ordinary preflight/restore error can overwrite an already-indeterminate report with partial. Include original unmatched intents in that branch and add a write-mode failure fixture with a pre-existing unresolved request.
- **[Should] Pre-existing rerating corrupts canonical raw text.** `_RATED_TOKEN_RE` matches only `rated` plus one digit (`utils/py/releases_app.py:3220`), yet `roadmap rate` uses it to remove the previous rating (`:3653`). Rerating an 80/... token leaves its tail and old override behind before appending the new token; subsequent parsing can retain an obsolete override or reject duplicate overrides. Remove the complete old rating/override token with the existing canonical parser contract, and assert stored text parses back to the stored rating columns after forced rerating with and without overrides.
- **[Should] Pre-existing repoint still mutates same-number rows across repositories.** `cmd_roadmap_repoint` selects the first row by issue number and updates every matching number (`utils/py/releases_app.py:3675`). It can overwrite another repository's raw text using the first row's text. Refuse ambiguous number selection and update the selected global ID; pin two repositories sharing an issue number with no unintended changes.
- **[Pass] Owner/snapshot and write-preflight repairs are present.** The resolver uses repositoryOwner fragments and the snapshot query has the corrected closure (`utils/py/board_sync.py:593`, `:646`). Destination validation precedes card addition and supplied legacy snapshots are refreshed (`:787`, `:874`). The parent's actual read-only 55-change preview is recorded at `TESTS-RESULTS/gh605-implementation/SUMMARY.md:7`; this is attributed evidence, not a reviewer rerun.
- **[Pass] Other first-round repairs have current source support.** Read-only loading rejects WAL before opening and quotes the URI (`utils/py/releases_app.py:5102`, `:5140`); lifecycle filtering excludes informational backfill/untagged starts (`:5086`). The actual two-owner roadmap writer fixture is at `test/test_gh605_work_state.py:253`. Terminal/duplicate PR guards and absent-ledger PR support are at `utils/py/board_sync.py:269`; unset membership and unknown Ready handling are at `:336`. These do not close the specific fall-through above. Shell wrappers are registered through the normal runner (`validate.sh:550`). The parent records 54/54 and four witnessed-red controls in `TESTS-RESULTS/gh605-implementation/SUMMARY.md:7`, `:17`; no final full-gate success is inferred.
- **[Pass] Legacy connector restoration is an explicit compatible scope choice.** The five-field replay contract and configured first-repository behavior remain (`utils/py/work_connectors/__init__.py:127`, `utils/py/work_connectors/github_board.py:84`), while the policy-board guard remains (`utils/py/work_connectors/github_board.py:125`). No new raw multi-repository protocol is requested. Evidence explicitly retains “No final implementation approval yet” (`TESTS-RESULTS/gh605-implementation/SUMMARY.md:10`); absence of live apply is appropriate.

Handing off to codex-author (Producer): address these findings, retain parent-owned test evidence, and complete the remaining sweep for the final review round. Go to the Producer window and say 'take your turn'. No live apply is approved.

### Producer disposition and Sol High correction brief for final round

Accept all four Blockers and three Shoulds in Reviewer round2. Reproduce with real isolated
fixtures before changing behavior; these are source findings until the new failing controls
witness them. Address the smallest existing seams, no new modules/dependencies/schema/writers.

Ownership: Sol may edit only the prior allowlist of production/tests/FAQ/CHANGELOG plus this
relay. Parent is concurrently running the normal gate in a separate full clone; you are not
alone. Do not revert other changes. No main-tree edits, no Git commands, no shell/full suites
in your linked worktree, no live network/config/ledger/board writes. Safe direct Python temp
fixtures and AST checks only; parent runs full-clone shell/gates. Driver owns commit. Finish
within20minutes; do not self-approve. This is Producer phase for final Reviewer round3.

1. Actual jog caller/extractor seam: preserve existing GH-number receipt selectors deliberately,
   but supply/resolve exact jog row global ID and repo for event insertion. Fail closed on
   ambiguous ownership; no first-row guessing. Real lease/status CLI full-schema fixtures must
   prove start and stop/failed/parked supersession, event repo and receipt transaction, and
   metadata-only non-reset. Inspect all jog statuses to ensure no real stop silently disappears.
2. Apply invalid-identity preservation consistently in issue selection (including valid+invalid
   row, with/without linked PR). No promotion/demotion by falling through a rejected decision.
3. Add genuinely integrated real build_policy_preview -> saved preview -> apply -> audit ->
   conditional restore fixtures. Mock only external GH transport and explicit config/input
   adapters; do NOT stub the planner/build_policy_preview or fabricate the result under test.
   Use nonempty temp ledger/current GH/board. Success and second-operation failure, original
   unset and existing statuses, residual added card, tampered decisions/digest/target, source
   drift refusal with zero writes, and durable audit assertions. Reuse existing mock transport.
4. Validate add/set/clear mutation response shape and expected nonempty/matching item ID within
   the audited invocation before success recording. Missing/null/wrong IDs are indeterminate,
   never conclusive success, no retry. Preserve add IDs only when established; test all verbs.
5. Restore exception branch must preserve original unmatched/indeterminate evidence too.
   Test write mode ordinary error with an existing unresolved request.
6. Fix rerating's complete old rating/override removal at its existing parser boundary. Do not
   globally broaden _RATED_TOKEN_RE if other callers only count start markers. Stored raw text
   must parse back to stored columns after force-rerating with/without old/new overrides.
7. Repoint selects/updates one global ID and refuses ambiguous issue numbers; prove another
   repository's same-number row cannot change. Reuse selector conventions, no new identity API.

All prior54Python and six focused shell suites are green at b9d784e9; preserve this baseline.
Record exact reproduction and post-fix test counts in your appended disposition. Leave NEXT
Reviewer / STATUS Open and release codex-author. Parent gathers runtime evidence before final
review. The final reviewer must also close the specific remaining coverage gaps (mock file,
historical docs and truncated GH549 portion); do not claim they have already been swept.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
