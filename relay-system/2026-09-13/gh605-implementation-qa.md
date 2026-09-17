# RELAY · GH605 implementation QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-13.
-->

NEXT: Producer
STATUS: Approved
ROUND: 7 / 7

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

### Harness boundary — parked before final Producer correction

The next builder dispatch returned exit8: lane RELAY-gh605-implementation-qa is parked at
its default two-attempt cap. No builder process started and no correction was made after
round2 review. Do not confuse this with completion of Reviewer round3; round3 has not run.
Per start-task and AGENTS.md GH45, implementation stops here pending explicit operator
authorization/replan to resume the parked lane. No --force, new lane or self-review bypass.
All seven round2 findings remain accepted but unimplemented. The existing draft push gate
may finish collecting/publishing b9d784e9; that does not approve code or authorize live apply.
Automatic follow-up paused to prevent unattended re-fire. Handing off to the operator.

### Operator-authorized resume

Operator now says: "Did you implement plan yet? If not please start." This follows the explicit
request for authorization to resume the parked lane. Resume the saved seven-item final-round
correction brief above, with one deliberate --force dispatch on the SAME lane. Do not create
a replacement lane or expand the review cap. PR611/development ec0823ab has been merged;
both ledger histories preserved through the canonical resolver, generation635, check clean.
Keep its new validate registration and subscription-support changes intact. Prior full gate
377/377 predates this merge/correction and must be rerun. No live board changes before QA.
Sol High: follow the existing20-minute correction brief, all seven findings, reproduce then
fix/test, append dispositions, NEXT Reviewer/STATUS Open, release codex-author. Parent will
verify in separate full clones and dispatch final Reviewer round3. You are not alone in the
repo; no main edits, Git commands, live writes or full shell suites in the linked worktree.

## Producer — sol-builder delegated by codex-author — Round 3 final correction

Disposition: all four Blockers and three Should findings from Reviewer round 2 are implemented in
the existing lifecycle, planner, writer, restore and roadmap seams. No live board/network/config/
ledger mutation, Git command, full suite or shell suite was run.

- **Implemented — real jog lifecycle ownership.** `_extract_jog` resolves the existing `GH-N`
  receipt target to exactly one queue row inside the write transaction, carries its `repo_id` and
  `jog_global_id`, and refuses same-number ambiguity (`utils/py/releases_app.py:1482-1505`). Full-
  schema fixtures exercise real lease plus failed/parked/completed/dropped/archived status writers,
  matching event/receipt transactions and repository, terminal supersession, metadata-only
  non-reset, and ambiguous rollback (`test/test_gh605_work_state.py:402-459`).
- **Implemented — invalid identity preservation on every issue path.** OPEN-issue planning now
  checks `invalid_ledger` as well as duplicate/missing identity before readiness/progress selection
  (`utils/py/board_sync.py:319-322`). Valid-plus-invalid fixtures preserve the card both with and
  without a linked PR (`test/test_gh605_board_policy.py:193-210`).
- **Implemented — real preview/apply/audit/restore integration.** Full-schema ledger fixtures use
  real `build_policy_preview`, planner, saved preview, apply and conditional restore with the
  existing stateful mock GitHub transport. They cover complete apply, second-operation lost
  response, original unset restoration, residual added card, nonempty durable audits, decision/
  digest/target tampering and source drift with zero mutation calls
  (`test/test_gh605_board_policy.py:605-786`).
- **Implemented — mutation acknowledgement validation.** Add/set/clear validate a nonempty Project
  item ID, and set/clear require it to match the requested item, before an audited success result is
  recorded; malformed/null/wrong IDs become indeterminate without retry
  (`utils/py/board_sync.py:734-782`, `:842-859`; tests `test/test_gh605_board_policy.py:226-249`).
- **Implemented — restore uncertainty on exceptions.** The restore exception branch now includes
  pre-existing unmatched/indeterminate requests when selecting its status
  (`utils/py/board_sync.py:1327-1330`), with a write-mode ordinary-preflight-error fixture at
  `test/test_gh605_board_policy.py:558-588`.
- **Implemented — complete forced rerating replacement.** `_without_rating` validates the stored
  canonical score, removes the full rating and optional override, and cleans the empty wrapper
  before writing the new token (`utils/py/releases_app.py:3315-3328`, `:3681-3686`). The fixture
  proves stored raw text parses back to stored columns with and without replacement overrides
  (`test/test_gh605_work_state.py:323-352`).
- **Implemented — repository-safe repoint.** Number-only repoint fetches at most two rows, refuses
  ambiguity, then mutates the resolved `global_id` only (`utils/py/releases_app.py:3720-3742`), with
  a two-repository no-mutation control at `test/test_gh605_work_state.py:354-365`.

Verification: four defect-restoration controls were witnessed red (mutation acknowledgement,
valid+invalid identity, `GH-N` jog resolution, complete rerating removal). Post-fix direct fixtures
pass **65/65** (22 work-state + 43 board-policy); the four changed Python files parse via `ast`.
Codebase Memory production-path coverage reported no recorded gap but the new test files were
missing from its generation, so implementation claims above use current source and direct fixtures.
FAQ and CHANGELOG describe the final contracts. Remaining work is parent-owned legacy shell/full-
clone gates, independent Reviewer round 3 whole-surface sweep, and later reviewed live Rev.2 apply.
No self-approval.

Handing off to codex-author: run and retain the separate-full-clone verification, then dispatch the
independent Codex Reviewer for Round 3; no live apply before approval.

### Parent verification and final Reviewer round3 handoff

Parent verified22533bb4:65/65Python fixtures pass in separate full clone2. Full normal push
gate and six legacy/focused shell suites are running separately; no result is presumed.
Development PR611/ec0823ab is included. See updated SUMMARY/provenance and producer disposition.
Final code QA is independent from publication: pending gate is not a source defect, but both
must pass before live apply. No live writes occurred. Review-only ALLOW_PATHS empty.

Close the prior coverage gaps FIRST: read utils/py/mock_gh_board.py, RELEASES-DB-FAQS.md,
CHANGELOG.md, the full controlling plan including historical sections, and all of
test/gh549-work-events.sh in bounded chunks without omitted/truncated ranges. Then review the
full changed production/test/validate files, using round2's declared source sweep as prior
context but not as approval. Do not finish early with missing coverage if time remains.
Prior-reviewed files unchanged except22533bb4 and development's single validate registration.
This is final Reviewer round3 of3,20-minute ceiling to finish the requested full-file coverage.

Adjudicate each of the seven round2 findings against real code and fixtures: actual jog
start/terminal ownership and ambiguity rollback; no identity fall-through; real preview->apply
->failure->restore (no planner stub); strict audited mutation acknowledgements; restore
uncertainty on exceptions; canonical rerating round-trip; safe repoint. Cite exact source.
Check surrounding touched code and fresh test assumptions; no new unrelated architecture.
No real network/config/ledger writes, no shell/full suites in this linked worktree. Only
append this relay file, preserving history. Emit honest swept file yes/no and PASS/FAIL Basis.
Approve/tick done only if all blockers addressed and coverage complete; otherwise Escalated
with concrete remaining findings at the cap. Do not self-fix. Parent handles remaining gates
and live application after approval. No fresh review round beyond this cap is authorized.

## Reviewer — codex — Round 3 final

VERDICT: FAIL

Basis: the seven repairs substantially improve the candidate, but lifecycle stop coverage and saved-preview freshness still have source-visible holes. Identity preservation also remains incomplete on the CLOSED issue path. This is the three-round cap: escalation, not authorization for another automated round or live apply. Findings below are static source review, not executed reproductions.

swept file: no

- **[Blocker] Real jog stop commands still bypass lifecycle emission (round 2 finding 1 only partially closed).** `utils/py/releases_app.py:1408` explicitly exempts `jog-drop`, `jog-retry`, `jog-skip`, and orphan reconciliation; actual drop and skip write terminal queue state through those operations (`:4536`, `:4541`, `:4601`). The corrected extractor cannot run for exempt operations. A recent roadmap-origin start followed by jog skip/drop remains eligible: current queue state is checked only for jog-origin starts (`:5287`), so the planner can still select In progress (`utils/py/board_sync.py:328`). Minimal fix: emit owned superseding lifecycle events for the actual status-changing CLI paths through the existing transaction seam; cover roadmap-start followed by actual drop/skip/requeue, plus orphan recovery where it changes lifecycle. The new helper-status fixtures (`test/test_gh605_work_state.py:402`) do not exercise these operation names. The `GH-N` resolution/ownership and ambiguous rollback repair itself is present at `utils/py/releases_app.py:1482` and tests `:445`.
- **[Blocker] Refreshing only `created_at` revives stale policy evidence.** `_preview_age_ok` bounds creation age but merely requires `as_of <= now` (`utils/py/board_sync.py:1126`). Apply rebuilds against that saved, potentially arbitrarily old `as_of` (`:1176`). An otherwise unchanged old preview with refreshed creation time can therefore pass the digest/decision comparison while treating an expired start or completion as recent. `build_policy_preview` itself stamps creation independently of its supplied evidence clock (`:1120`). Minimal fix: bound the evidence clock by the same freshness window, validate its relationship to creation, and add a fixed-clock integration case that refreshes creation on an expired preview and expects zero remote requests. Existing future-date checks do not cover this case.
- **[Blocker] Invalid/duplicate ledger preservation still falls through for CLOSED issues (round 2 finding 2 partially closed).** The CLOSED branch assigns Done/Backlog and continues before the ledger ambiguity guard (`utils/py/board_sync.py:305`, `:319`). Thus a valid-plus-invalid ledger pair, or multiple valid ledger rows, can move an existing CLOSED issue despite the controlling preserve-on-ambiguity contract. Minimal fix: guard known invalid/duplicate ledger identity before terminal selection too, while preserving the explicitly supported absence-of-ledger terminal case. Add recent-completed, old-completed, and NOT_PLANNED fixtures with ambiguous ledger rows. The current regression covers OPEN only (`test/test_gh605_board_policy.py:193`).
- **[Pass] Round 2 findings 3–5 have concrete repairs.** The integration fixture now uses real preview/planner/apply/audit/restore with full-schema evidence (`test/test_gh605_board_policy.py:605`), including durable nonempty audit and partial-failure scenarios. Mutation acknowledgement validation occurs inside the audited request boundary (`utils/py/board_sync.py:734`, `:762`, `:842`), and restore exception status includes existing unmatched requests (`:1327`; regression `test/test_gh605_board_policy.py:558`). These are source-supported dispositions; the reported runtime passes remain attributed to producer/parent.
- **[Pass] Round 2 findings 6–7 have concrete repairs.** Forced rerating removes the complete parsed rating/override span (`utils/py/releases_app.py:3315`, `:3681`) with round-trip fixtures (`test/test_gh605_work_state.py:323`). Repoint refuses multiple number matches and updates the resolved global ID (`utils/py/releases_app.py:3720`, `:3740`; ambiguity fixture `test/test_gh605_work_state.py:354`).
- **[Should] Stateful mock cannot faithfully add a PR card.** Add resolves content IDs only from `issues`, then defaults an unknown ID to issue number zero and omits PR kind (`utils/py/mock_gh_board.py:220`, `:234`). Minimal fix: resolve both issue and PR IDs, preserve kind, and refuse unknown IDs. Extend the real preview/apply/restore fixture with an absent PR card and consume the mock snapshot rather than only its shadow board state; current integration coverage is a meaningful improvement but does not establish this path.
- **[Should] Complete source coverage and retain final candidate evidence before approval.** This turn read the full plan including history, FAQ, mock, board planner/writer, GitHub connector, both Python test files, gh549 shell suite, and most of the full releases module. Remaining unswept material includes portions of the long historical CHANGELOG, validate, legacy wrappers/gh492/gh402, connector package initialization, and an output-truncated CLI-parser span of releases_app. Earlier-round reads are context, not this turn's complete sweep. Graph discovery found only a stale XYZ-forge generation (2026-09-01); requested coverage returned stale/excluded/missing paths, so no graph completeness claim is made. SUMMARY attributes 65/65 to candidate22533bb4, while the read provenance file ends with earlier candidate evidence. Pending parent gates are not a source defect; append the exact final-candidate receipts when available. No tests, Git commands, source edits, or live writes were performed by this reviewer.

Handing off to codex-author — report these remaining findings to the operator and obtain an explicit continuation decision at the exhausted review cap. No further automatic review round or live application is authorized by this verdict.

### Operator-authorized finish: focused remaining corrections

Operator explicitly authorizes: "Yes, finish corrections and verification." Extend this same
relay to5 review rounds (two additional rounds maximum), preserving all history. Resume Sol
High on the four concrete changes below; previous statements stopping at3 are superseded by
this authorization, not silently bypassed. Development remains ec0823ab and branch is clean.

1. Reproduce and fix ACTUAL jog drop/skip/retry/clear/orphan-recovery commands, not only helper
   status. Trace every queue lifecycle writer and use the existing explicit/batched event
   transaction seam where rows are deleted or multiple rows change. Preserve exact row/repo
   identity and atomic rollback. Roadmap-origin start followed by each real stop/requeue must
   become unverified, not In progress. No-op/metadata commands must not manufacture transitions.
2. Bound both preview created_at AND evidence as_of to15minutes, with coherent ordering.
   Add fixed-clock real apply integration: stale as_of + refreshed created_at refuses before
   any remote request; future/inconsistent clocks refuse; fresh preview still applies.
3. Move known invalid/duplicate ledger preservation ahead of CLOSED selection too. Preserve
   absent-ledger terminal support. Cover recent/old COMPLETED and NOT_PLANNED, both duplicate
   valid rows and valid+invalid identity, ensuring no mutation through any fall-through.
4. Correct the existing stateful mock for PR content IDs and kind, refusing unknown content
   instead of issue0. Extend real preview/apply/restore fixtures with absent PR cards and actual
   mock snapshots, not only shadow state. Preserve existing issue mock compatibility.

Ownership: only prior allowlist production/tests/FAQ/CHANGELOG and this relay; no new modules,
schema, dependencies, writers or unrelated cleanup. You are not alone; preserve PR611 and peer
edits. No Git commands, real network/config/board/ledger writes, or shell/full suites in the
linked worktree. Reproduce first with safe temp Python fixtures, then fix and witness red
controls, run all focusedPython tests/AST. Parent owns separate-full-clone shell/gate evidence.
20-minute ceiling. Append exact dispositions/test results, NEXT Reviewer STATUS Open, release
codex-author. Driver owns commit. Final reviewer must close explicitly listed coverage gaps;
do not claim approval yourself. Parent then verifies and applies the board only after approval.

## Producer — sol-builder delegated by codex-author — Round 4 focused corrections

Disposition: all three Blockers and the mock Should from Reviewer round 3 are implemented in the
existing lifecycle/planner/writer seams. No live board/network/config/ledger mutation, Git command,
shell suite, or full gate was run.

- **Implemented — every real jog stop/requeue path emits owned lifecycle evidence.** Actual add,
  drop, retry, skip and helper status writes resolve one queue identity, refuse same-number
  ambiguity, and emit only when status changes (`utils/py/releases_app.py:1479-1517`,
  `:4362-4429`, `:4526-4643`, `:4719-4751`). Clear and orphan recovery collect per-row events
  inside the transaction and hand the batch to the shared receipt boundary; orphan rows are
  re-resolved under `BEGIN IMMEDIATE` (`:4646-4674`, `:4754-4809`). Direct fixtures exercise
  roadmap-start→drop/retry/skip/re-add, clear, orphan pending/parked, same-state retry omission,
  exact ownership, and second-event rollback (`test/test_gh605_work_state.py:415-506`).
- **Implemented — preview creation and evidence clocks share one freshness boundary.** Apply now
  requires `as_of <= created_at <= now` and both clocks within 15 minutes
  (`utils/py/board_sync.py:1132-1139`). Fixed-clock controls cover stale evidence with refreshed
  creation, future/inconsistent ordering and a fresh apply (`test/test_gh605_board_policy.py:353-366`,
  `:774-785`).
- **Implemented — CLOSED issues preserve known ambiguous identity.** The invalid/duplicate guard
  now precedes OPEN/CLOSED selection while still allowing genuinely absent-ledger terminal issues
  (`utils/py/board_sync.py:300-318`). Recent/old COMPLETED and NOT_PLANNED fixtures cover duplicate
  valid and valid-plus-invalid rows (`test/test_gh605_board_policy.py:209-228`).
- **Implemented — stateful mock PR identity.** Mock add resolves issues and PRs, preserves kind,
  and refuses unknown content without creating issue zero (`utils/py/mock_gh_board.py:215-252`).
  Direct and real preview/apply controls add an absent PR, consume the mock's actual snapshot, and
  confirm In review (`test/test_gh605_board_policy.py:368-386`, `:787-817`).

Verification: pre-fix controls visibly failed for missing clear events, CLOSED ambiguity, stale or
incoherent evidence acceptance, and PR/unknown mock identity. After repair the direct fixtures pass
**74/74** (26 work-state, 48 board-policy), and all five changed Python files parse via `ast`; logs
are retained under `.relay-scratch/`. Codebase Memory generation 2026-09-14T03:39:25Z reports no
recorded gap for production/tests/FAQ, while mock_gh_board.py and CHANGELOG remain intentionally
excluded from the fast index and were verified from current source. FAQ/CHANGELOG record only the  [Unverified — no citation]
implemented behavior. Remaining work is parent-owned separate-full-clone shell/full-gate evidence,
independent Reviewer round 4 whole-surface coverage, and only then any reviewed live Rev.2 apply.
No self-approval.

Handing off to codex-author: retain the parent gate receipts and dispatch the independent Reviewer
for Round 4; no live apply before approval.

### Parent independent verification — Reviewer4 handoff

Parent74/74Python passes on426f5825 in full clone2. Six focused shell suites and full normal
push gate are running in separate full clones; their outcomes are not presumed. Operator
authorizes finishing, same relay4/5. Pending runtime gate does not itself prevent a code verdict;
both approval and green gates are required before live apply. No live writes occurred.

Review the four new repairs and their real callers/tests against the controlling plan. Confirm
actual jog operations and no-op behavior, batch ownership/rollback, stale/incoherent clocks,
both CLOSED and OPEN ambiguity with absence support, and actual mock PR snapshots. Dispose all
prior findings explicitly, cite file:line. Keep scope to this task's code and surrounding files.

Complete the full-file sweep before approval. Close the known omitted spans FIRST: full
utils/py/work_connectors/__init__.py; full validate.sh; all test/gh492-roadmap-state-sweep.sh,
test/gh402-board-sync.sh and GH605 wrappers; entire CLI parser tail of releases_app.py; full
CHANGELOG.md. Then read full current board_sync.py, releases_app.py, mock_gh_board.py,
work_connectors/github_board.py, both GH605Python tests, gh549 suite, FAQ, plan and evidence.
Use bounded output chunks and close every truncation; do not declare missing coverage merely
because an earlier read was truncated. Twenty-minute ceiling, no reason to finish prematurely
with unread material when time remains. Whole-file review remains required, not diff-only.
Review-only: this relay file is the only allowed edit. No Git, shell/full suites, live network,
config or ledger writes. Safe isolated direct probes optional. Emit PASS/FAIL and Basis, honest
swept file yes/no. Approve and tick done only if all blockers are closed and coverage complete;
otherwise hand back concrete minimal findings NEXT Producer/STATUS Open for round5. No code edits.

## Reviewer — codex — Round 4

VERDICT: FAIL
Basis: the latest repairs address their direct cases, but the real loader still loses known
invalid ledger identity before preservation, and real lease acquisition still assumes the
first repository. A pre-existing repeated-terminal queue-position defect also remains in the
touched code. These are source-traced failures, not reviewer-executed reproductions.
swept file: no

- **[Blocker] Invalid ledger identity disappears at the loader/planner boundary.**
  `utils/py/releases_app.py:5328` knows the owning repository, but `:5370` exports only
  `url_repo`. A missing/non-GitHub/malformed URL therefore exports `repo=None` despite an
  unambiguous qualified source slug. Such URLs are expressly accepted by intake (`:3538`,
  `:3546`). `utils/py/board_sync.py:228` drops that row before populating `invalid_ledger`.
  Consequently an existing Ready card for that source issue can move to Done when GitHub
  says recently COMPLETED (`:307`, `:318`), or In review through an OPEN closing PR (`:269`,
  `:277`): both paths mistake known-invalid evidence for genuinely absent evidence. A URL
  naming another owner similarly loses the source identity. Retain an independently trusted
  source identity (qualified owning slug, or origin-proven legacy basename) for invalid-row
  preservation; do not make the URL valid or guess an unknown owner. Add real
  `load_work_evidence` → planner/preview fixtures for missing, malformed and wrong-owner URLs,
  CLOSED and OPEN+PR cases, and valid-plus-invalid evidence. Assert no issue mutation plus an
  unresolved report, retaining genuine-absence positive controls. The current tests inject
  already-qualified invalid rows (`test/test_gh605_board_policy.py:193`, `:209`) and miss this
  boundary. Round 3's CLOSED ordering is repaired; the end-to-end preservation finding remains open.
- **[Blocker] Lease acquisition still selects the first repository.**
  `utils/py/releases_app.py:4702` chooses `repos ORDER BY id LIMIT 1`, then `:4705` looks up
  the queue row only there. With repo A first and one uniquely numbered pending item in repo B,
  `jog_acquire_lease` refuses `jog-not-found`; it never reaches the repaired owned extractor.
  This is reachable from the real supervisor, which selects pending rows across repositories
  (`utils/py/jog_run.py:1669`) and calls this helper (`:1687`). Resolve the unique actual queue
  row inside the write transaction, using the same ambiguity refusal as the repaired stop
  writers, and preserve the GH-N receipt contract. Add a two-repository success fixture where
  only the second repository owns the requested number; assert its row starts and its event
  carries the same receipt transaction and correct repo/global ID. Keep the ambiguous-number
  rollback control. The current successful lease fixture initializes only one repository
  (`test/test_gh605_work_state.py:367`, `:498`); `:539` covers ambiguity but not this success
  case. This is the remaining real-start ownership gap, not a request to widen raw connector replay.
- **[Should] Repeated terminal jog commands corrupt active queue positions.** Drop and skip
  decrement later active positions unconditionally (`utils/py/releases_app.py:4555`, `:4634`);
  helper status writes do likewise whenever the destination is terminal (`:4741`). Event
  suppression on same-state writes does not suppress this mutation. For active positions
  1/2/3, dropping item 1 leaves the others at 1/2; dropping it again decrements the last to 1,
  producing duplicate positions. Terminal-to-terminal helper transitions have the same problem.
  Compact positions only when the prior row actually leaves pending/running. Extend the
  existing real-command fixtures with three items and repeated drop/skip/helper-terminal
  calls, asserting stable distinct positions and no duplicate same-state lifecycle events.
  The present no-op coverage checks event names with one queue item
  (`test/test_gh605_work_state.py:415`), so it cannot detect this pre-existing surrounding defect.
- **[Pass] Round 3's actual stop/batch emission, clock and mock repairs have source support.**
  Actual drop/retry/skip/add now supply owned transitions; clear and orphan recovery batch
  through the receipt boundary (`utils/py/releases_app.py:4426`, `:4560`, `:4600`, `:4639`,
  `:4670`, `:4806`; rollback fixture `test/test_gh605_work_state.py:462`). Both clocks are
  coherently ordered and bounded (`utils/py/board_sync.py:1132`; integration control
  `test/test_gh605_board_policy.py:774`). The mock resolves PR versus issue content and refuses
  unknown IDs (`utils/py/mock_gh_board.py:215`), with an actual PR snapshot integration at
  `test/test_gh605_board_policy.py:787`. These close those specific cases, subject to the
  remaining identity and queue findings above; runtime results remain parent/producer-attributed.
- **[Pass] Earlier repaired findings remain supported.** Real preview/apply/failure/restore
  integration is present (`test/test_gh605_board_policy.py:605`); mutation IDs are validated
  within the audited boundary and restore retains prior uncertainty on error
  (`utils/py/board_sync.py:750`, `:769`, `:1336`). Complete rating-token replacement and
  uniquely scoped repoint remain (`utils/py/releases_app.py:3315`, `:3681`, `:3720`, `:3740`).
  Owner fragments, bounded snapshots, destination-before-add, WAL-before-open, informational
  lifecycle filtering, unset/unknown card reporting, and normal shell registrations retain
  their repairs (`utils/py/board_sync.py:610`, `:650`, `:900`, `:327`;
  `utils/py/releases_app.py:5193`, `:5210`; `validate.sh:550`). The legacy five-field configured
  single-repository connector scope remains deliberate (`utils/py/work_connectors/github_board.py:84`).
- **[Should] Coverage/evidence disposition: approval remains outstanding.** This turn closed
  the prior connector package, validate runner, GH492/GH402/wrapper and releases CLI-tail
  reading gaps and read the current production modules, both GH605 Python fixtures, full
  GH549 suite, FAQ, controlling plan and evidence records. The long historical CHANGELOG
  remains incompletely swept, including truncated historical spans and material after line
  800; no whole-surface approval is claimed. Graph tools were unavailable in this runtime;
  source reads supplied evidence, with no graph completeness claim. The latest SUMMARY
  attributes 74/74 to 426f5825 and explicitly leaves shell/full gates pending
  (`TESTS-RESULTS/gh605-implementation/SUMMARY.md:3`). Retain final-candidate receipts when
  those parent runs finish; their pending status is not an additional code defect. No tests,
  Git commands, source changes, or live board/config/ledger writes were performed by this reviewer.

Handing off to codex-author (Producer) for Round 5 corrections — go to the Producer window
and say "take your turn". No live apply before complete approval and qualifying gates.

### Parent continuation for Producer round 5

The operator authorized finishing corrections and verification. Resolve Round 4's two
blockers and queue-position finding surgically, with direct regression controls and
dispositions. Preserve independently trusted source identity without treating invalid URLs
as valid. Resolve lease ownership inside the transaction. Compact positions only on exit
from active states. No new subsystem or schema. Parent full gate on426f5825 failed:
gh57-releases-fuzz.sh returned4 both parallel and serial (38 passed,4 failed); this remains
unresolved, not a passing gate. Parent will investigate it in the separate full clone while
you correct the three source findings. Do not run shell/full suites in this worktree.
Run isolated Python fixtures, update FAQ/CHANGELOG if necessary, then hand back to Reviewer
with ROUND5/5. Do not self-approve or push. Sol High owns implementation edits; parent owns
verification receipts and final Astra review. Do not edit unrelated changes from PR611.

## Producer — codex-author — Round 5 final corrections

Disposition: both Round 4 Blockers and the queue-position Should are implemented in the existing
loader/planner and jog transaction seams. No live board/network/config/ledger mutation, Git command,
shell suite, or full gate was run.

- **Implemented — invalid URL evidence retains independently trusted source identity.**
  `load_work_evidence` now projects a qualified owning `repos.slug`, or an origin-proven legacy
  basename, independently from URL validity while leaving `identity_valid=False`; it never adopts a
  foreign URL as identity (`utils/py/releases_app.py:5335-5352`, `:5386-5389`). Real
  loader→preview fixtures cover missing, malformed and wrong-owner URLs across CLOSED and OPEN+PR
  paths, a valid-plus-invalid evidence pair, and the genuinely absent-ledger positive control
  (`test/test_gh605_board_policy.py:787-867`).
- **Implemented — lease ownership resolves the unique queue row across repositories.** Lease
  acquisition selects up to two matching queue rows inside `perform_write`, refuses ambiguity, and
  updates the sole row without a first-repository guess while preserving the `GH-N` receipt target
  (`utils/py/releases_app.py:4698-4720`). The second-repository fixture proves row state, PID,
  receipt/event transaction equality, repository ownership and jog global ID; the existing ambiguous
  rollback control remains (`test/test_gh605_work_state.py:534-559`, `:626-642`).
- **Implemented — terminal compaction is conditional on an active-state exit.** Drop, skip and the
  shared status writer decrement later active positions only when the prior row was `pending` or
  `running` (`utils/py/releases_app.py:4552-4559`, `:4631-4639`, `:4743-4753`). A three-item fixture
  repeats drop, skip and helper-terminal commands, then checks stable distinct active positions and
  exactly one same-state lifecycle event (`test/test_gh605_work_state.py:561-613`).

Verification: the new pre-fix controls witnessed the intended failures (first-repository lease
`jog-not-found`, repeated terminal compaction producing duplicate position 1, and invalid URL
evidence falling through to Done). After repair the focused direct fixtures pass **78/78** (28
work-state + 50 board-policy), and all three changed Python files parse via `ast`; logs are retained
under `.relay-scratch/`. Codebase Memory's nearest GH-605 generation points at a retired worktree and
reports these paths stale/missing, so implementation claims use current source and direct fixtures.
FAQ/CHANGELOG now describe the trusted-identity, cross-repository lease and conditional compaction
contracts. Parent's `gh57-releases-fuzz.sh` failure remains unresolved and no full-gate success is
claimed; parent owns separate-full-clone investigation and final-candidate receipts. No self-approval
or live apply.

Handing off to codex (Reviewer) for Round 5 — go to the Reviewer window and say "take your turn".
Review the three corrections, close the remaining full-file sweep, and approve only if the source and
qualifying parent gates support it; no live Rev.2 apply before independent approval.

### Parent final-candidate fixture repair before Reviewer5

05eaee6a has78/78 builder-attributed Python passes. Before final Reviewer5, fix the
reproduced gate fixture failure in test/gh57-releases-fuzz.sh (no production change).
Parent instrumented Scenario1: naive union merges two generation2 settings rows differing
only in updated_at seconds. Loader correctly refuses dump-duplicate-setting, causing4
failures. Forced one-second branch gap reproduces exit4; existing resolved_union_dump
instead yields42/42. The delay was diagnostic only and restored, not the proposed fix.
Reuse existing resolved_union_dump for Scenario1. Make its differing timestamp input
deterministic without sleeps, retain a concrete duplicate-setting refusal red control,
and preserve Scenario3's real refusal checks. Read entire shell fixture first. No weakened
loader, skipped test, arbitrary retry, new helper subsystem, or gate bypass.
Only this shell fixture plus CHANGELOG and relay may change. Do NOT run shell suites in
the linked worktree; parent will run the final fixture and whole gate in full clones.
Keep ROUND5/5: this completes its candidate, not a new review cycle. Handoff to Reviewer
after source checks; do not self-approve. Main source repairs must remain unchanged.

## Producer — codex-author — Round 5 gate-fixture correction

Disposition: the parent-reproduced GH-57 Scenario 1 fixture failure is corrected without changing
the loader, resolver, registry, production implementation, or Scenario 3 refusal semantics. No Git
command, shell suite, full gate, live write, network mutation, or device configuration change ran.

- **Implemented — Scenario 1 uses the existing canonical settings union.** The divergent-branch
  rebuild now calls `resolved_union_dump` with side B as the explicit header/settings winner
  (`test/gh57-releases-fuzz.sh:146`), preventing two generation-2 settings rows that differ only by
  timestamp from reaching the loader.
- **Implemented — branch timing is deterministic without sleeps.** Side A and side B writes use
  distinct fixed `RELEASES_APP_NOW` values (`test/gh57-releases-fuzz.sh:118-127`); the production
  clock seam explicitly honors that environment value (`utils/py/releases_app.py:175-181`).
- **Retained — duplicate-input refusals remain load-bearing.** Scenario 3 still builds an unresolved
  duplicate-settings dump and requires `rule=dump-duplicate-setting`, then independently requires
  the duplicate-GID refusal (`test/gh57-releases-fuzz.sh:173-188`). No assertion was removed or
  weakened. `CHANGELOG.md:7` records the deterministic qualification-fixture correction.

Verification: `bash -n test/gh57-releases-fuzz.sh` passes, and focused source checks confirm the
canonical Scenario 1 call, both fixed clocks, and both Scenario 3 refusal paths. Per the containment
instruction, the fixture itself was not executed in this linked worktree; the parent still owns its
disposable-full-clone rerun and the complete gate, so the prior 38-pass/4-fail result is not claimed
green here. No self-approval or live Rev.2 apply.

Handing off to codex (Reviewer) for Round 5 — go to the Reviewer window and say "take your turn".
Approve only after reviewing this correction and the parent supplies qualifying runtime evidence.

### Parent final Reviewer5 dispatch

Independent parent78/78Python passed on05eaee6a production code (28state+50policy).
Latest candidateae7006c8 additionally fixes only the deterministic GH57 fixture. Fresh
normal gated push is running in separate full clone1. Code approval and runtime gate
are separate requirements: code verdict may approve with a clearly pending parent gate;
no live apply until both pass. Do not treat pending parent gate as a source defect.

Close whole-file coverage deliberately: read CHANGELOG.md ALL2527lines FIRST in bounded
chunks (max100lines for long historical entries, ample output tokens), then full gh57
fixture. Do not re-audit historical GH claims externally; this is a source sweep for
material defects and contradictory current documentation. Then current releases_app,
board_sync, mock, connector package/github, both Python tests, gh492/402/549 and wrappers,
validate,FAQ,controlling plan,evidence. All prior reviews remain evidence; resolve each
open finding and inspect new changes plus surrounding full files. Do not manufacture
approval if coverage is incomplete. No shell/full suites, Git, code edits, live writes.
Only relay edits permitted. Twenty-minute ceiling. Explicit PASS/FAIL and swept file yes/no,
file:line support. If all source findings close, approve/tick done. If a genuine blocker
remains, report minimal exact evidence and markEscalated at5/5. No extra review loop.

## Reviewer — codex — Round 5

VERDICT: FAIL
Basis: the three Round 4 repairs and deterministic GH-57 correction have source support. A separate pre-existing mock identity defect remains, and this turn did not complete the mandated whole-file sweep. This is not a claim that the pending parent gate failed, nor a new production blocker inferred from missing coverage.
swept file: no

- **[Pass] Round 4 invalid-source-identity blocker closed in the reviewed seam.** The loader now retains the independently owning qualified slug, or origin-proven basename, while leaving invalid URL evidence invalid (`utils/py/releases_app.py:5335`). The planner guards that identity before both CLOSED and OPEN selection (`utils/py/board_sync.py:307`) and before linked-PR assignment (`:269`). Real loader/preview fixtures cover missing, malformed and wrong-owner URLs, both CLOSED and OPEN+PR, genuine absence, and valid-plus-invalid rows (`test/test_gh605_board_policy.py:787`, `:829`).
- **[Pass] Round 4 lease-ownership blocker closed.** Acquisition resolves up to two queue matches inside the mutation callback, refuses ambiguity and updates only the sole row (`utils/py/releases_app.py:4704`). The extractor preserves the GH-N receipt selector while obtaining the actual repository/global ID (`:1486`). The second-repository fixture checks state, PID and receipt/event ownership; the ambiguity control remains (`test/test_gh605_work_state.py:534`, `:626`).
- **[Pass] Round 4 repeated-terminal compaction finding closed for its named paths.** Drop, skip and helper-terminal writes now compact only on departure from pending/running and suppress same-state lifecycle events (`utils/py/releases_app.py:4555`, `:4635`, `:4747`). The multi-item fixture checks repeated commands and terminal-to-terminal writes against surviving positions and event counts (`test/test_gh605_work_state.py:561`).
- **[Pass] GH-57 fixture correction is narrow and retains refusal controls.** The full fixture was read: divergent writes use distinct fixed clocks (`test/gh57-releases-fuzz.sh:118`, `:127`), Scenario 1 uses the existing settings-winning union (`:146`), and Scenario 3 retains duplicate-settings and duplicate-GID refusals (`:173`, `:188`). No runtime rerun is claimed by this reviewer.
- **[Should] The mock's real `--seed` path allocates duplicate item IDs.** `get_default_state` initializes `next_item_id` to 1; `--seed` installs `PVTI_mock_item_0001` without advancing that counter (`utils/py/mock_gh_board.py:344`). The next add allocates that same ID (`:239`), and status/clear mutate the first matching item (`:288`, `:299`). Thus seed -> add issue 124 -> set returned ID can change issue 123 while leaving 124 unset. This is source-traced, not an executed reproduction. Minimal fix: advance the seed counter to 2 and add a seed -> add -> set fixture that reads the actual snapshot, requires distinct IDs and proves only the added card changes. The current policy fixture explicitly supplies `next_item_id: 2`, bypassing this CLI defect (`test/test_gh605_board_policy.py:724`). It does not invalidate that fixture's existing results.
- **[Pass] Earlier repair dispositions remain supported by the reviewed paths and prior review evidence.** Actual stop/batch writers use owned explicit events (`utils/py/releases_app.py:4561`, `:4672`, `:4813`); both preview clocks are bounded and coherently ordered (`utils/py/board_sync.py:1132`); audited response validation precedes success (`:750`, `:771`); restore retains original uncertainty on exceptions (`:1336`). Real preview/apply/failure/restore and actual PR snapshot fixtures remain (`test/test_gh605_board_policy.py:868`, `:901`). PR-kind/unknown-content repair itself is present (`utils/py/mock_gh_board.py:221`). Earlier rerating/repoint, WAL, metadata filtering, query-shape, unknown-card and shell-registration dispositions are retained as prior reviewer evidence, not represented as a fresh complete sweep. The five-field raw connector contract and board-policy refusal remain deliberate (`utils/py/work_connectors/__init__.py:127`; `utils/py/work_connectors/github_board.py:125`).
- **[Should] Coverage and runtime evidence remain explicit acceptance limits.** This turn read board_sync, mock and both connector modules, the full GH-57 fixture, current lifecycle/evidence seams and their new regressions, and relay history. It did not finish the 6,689-line releases module, both full Python suites, validate/legacy shell suites, full FAQ/plan, or all 2,527 CHANGELOG lines. Historical CHANGELOG reads still contain unclosed truncations and unread material after line 850; no exhaustive absence-of-defects claim is made. Graph tools were unavailable. Parent 78/78 and the pending final-candidate gate are attributed to the dispatch note; committed SUMMARY still names the older checkpoint (`TESTS-RESULTS/gh605-implementation/SUMMARY.md:3`). Pending results are not source defects. No tests, source programs, Git commands or live board/config/ledger writes were run; only this relay file was edited, apart from the explicitly requested Tick token operations.

Handing off to codex-author for operator disposition at the exhausted 5/5 cap. No additional automatic review cycle or live apply is authorized by this verdict. Preserve the source-supported closures above, resolve or explicitly disposition the mock finding, and complete the outstanding review coverage and final-candidate receipts before approval.

### Operator-authorized final continuation

User: "Yes finish the lane to finish those last two items". Same lane extended to6.
Development7d26411a skill-discipline hotfixes integrated; preserve them. This is a local
single-operator CLI and mock, not enterprise multi-tenant infrastructure. One-line seed
counter correction and one regression in existing board-policy tests are sufficient.
No new module, test framework, fuzzing system, abstraction or unrelated scope.

Sol High Producer: fix real mock --seed counter to2 after creating item1. Add actual
seed -> add124 -> setDone -> snapshot regression asserting distinct IDs, original123
still In progress and added124 Done. Use existing APIs/test helpers. Parent already
reproduced old code changing123 while124 unset. Run focused Python only (no shell/full
suites in worktree), record pre-fix failure and post-fix pass. Touch only mock and existing
board-policy test; no CHANGELOG ceremony for this trivial local correction. Handoff6/6
to independent Reviewer; parent will complete coverage dispatch then run exactly one
full gate after approval. No self-approval, push, board/config writes or ledger edits.

## Producer — codex-author — Round 6 final mock correction

Disposition: the remaining mock identity finding is implemented with the requested one-line
counter correction and one regression. No Git command, shell/full suite, live board/config/ledger
write, network mutation, or CHANGELOG edit was performed.

- **Implemented — `--seed` reserves the seeded item ID.** After installing
  `PVTI_mock_item_0001`, the real seed path now advances `next_item_id` to 2
  (`utils/py/mock_gh_board.py:344-357`). The next add therefore allocates a distinct item rather
  than aliasing the seeded card.
- **Implemented — actual seed/add/set/snapshot regression.** The focused test invokes the real
  `--seed` CLI path, adds issue 124, sets the returned item to Done, consumes the mock snapshot,
  and proves distinct IDs while issue 123 remains In progress and issue 124 is Done
  (`test/test_gh605_board_policy.py:388-412`).

Verification: the new control was witnessed red before the production fix with both issues
receiving `PVTI_mock_item_0001`. After the fix, the individual regression passes **1/1** and the
complete focused board-policy fixture passes **51/51**; logs are retained under
`.relay-scratch/gh605-r6-seed-prefix.log`, `.relay-scratch/gh605-r6-seed-postfix.log`, and
`.relay-scratch/gh605-r6-board-policy-postfix.log`. Codebase Memory's nearest GH-605 project points
to a retired worktree; `mock_gh_board.py` is excluded and the current test/relay paths are missing,
so claims use direct current-source inspection plus the focused fixtures. No self-approval or live
Rev.2 apply is claimed.

Handing off to codex (Reviewer) for Round 6 — go to the Reviewer window and say "take your turn".
Complete the outstanding whole-file coverage and approve only if the source and parent-owned
qualifying gate support it; no live apply before independent approval.

### Parent final coverage-completion packet (Round6)

Independent parent79/79Python passed on830455e8 in separate full clone2. The new seed
regression passed. Historical ae7006c8 full gate378/378 is not current approval; per the
updated start-task discipline the ONE final full gate runs AFTER this source approval.
Pending full gate is not a code defect. Operational envelope: local single-user scripts,
existing configured board, explicit operator apply. No speculative enterprise machinery.

The remaining acceptance item is COMPLETE source coverage, not another sampling pass.
Do not stop after identifying truncation: read the omitted span immediately. Do not emit
an incomplete verdict while time remains. You have30minutes; use it to finish reading.
Keep a private checklist of contiguous read ranges and close each file to EOF. Read source
in chunks of at most150lines with max_output_tokens12000; historical CHANGELOG chunks at
most40lines (long paragraphs). If a tool reports truncation, split that exact chunk again.
Do NOT combine huge files in one output, and do NOT repeatedly dump the entire relay.

Read to EOF in this order: CHANGELOG.md(2529lines), releases_app.py(6689), both GH605
Python tests(646 and1002), validate.sh(1507), gh549-work-events.sh(1426), gh492(160),
gh402(270), gh57(255), both4-lineGH605wrappers, RELEASES-DB-FAQS.md(88), canonical605
plan(446), SUMMARY/provenance. Then full current board_sync(1491), mock(430), connector
package(447) and github connector(186). Paths are under utils/py or test as in Setup.
Linecounts are starting aids; actual EOF controls. Imported FAQ link is reference only;
do not invent a second whole-repository audit. Historical CHANGELOG claims need no live
external revalidation. Grade concrete defects against stated requirements, not new scope.

At completion output a compact per-file coverage table, exactseed-finding disposition,
PASS/FAIL, Basis, swept file yes/no, and file:line citations. All prior source findings
were closed in Round5; do not reopen without contradictory current evidence. If clean,
setApproved and tickdone. No source edits, Git commands, shell/full suites, board/config
writes. Only relay may be edited. No self-fixing or speculative new testing requirements.

## Reviewer — codex — Round 6 final source approval

VERDICT: PASS
Basis: Complete current-file review closes the outstanding coverage requirement and the remaining mock seed defect. No additional material pre-existing or introduced defect was found in these files against the controlling local, single-user, explicitly applied policy contract. This is source approval; the parent-owned final full gate and subsequent live application remain separate steps, as specified in the final coverage packet.
swept file: yes

Coverage below is direct current-source reading, contiguous through actual EOF (17,729 lines across the 19 artifacts). Truncated reads were split and their omitted spans reread; no truncated span is counted as covered. The relay history was also read in full.

| File | Read coverage |
| --- | --- |
| `CHANGELOG.md` | 1–2529, EOF |
| `utils/py/releases_app.py` | 1–6689, EOF |
| `utils/py/board_sync.py` | 1–1491, EOF |
| `utils/py/mock_gh_board.py` | 1–430, EOF |
| `utils/py/work_connectors/__init__.py` | 1–447, EOF |
| `utils/py/work_connectors/github_board.py` | 1–186, EOF |
| `test/test_gh605_work_state.py` | 1–646, EOF |
| `test/test_gh605_board_policy.py` | 1–1002, EOF |
| `validate.sh` | 1–1507, EOF |
| `test/gh549-work-events.sh` | 1–1426, EOF |
| `test/gh492-roadmap-state-sweep.sh` | 1–160, EOF |
| `test/gh402-board-sync.sh` | 1–270, EOF |
| `test/gh57-releases-fuzz.sh` | 1–255, EOF |
| `test/gh605-work-state.sh` | 1–4, EOF |
| `test/gh605-board-policy.sh` | 1–4, EOF |
| `RELEASES-DB-FAQS.md` | 1–88, EOF |
| `PROJECT/2-WORKING/GH-605-WORK-STATE-PROJECTION.md` | 1–446, EOF |
| `TESTS-RESULTS/gh605-implementation/SUMMARY.md` | 1–121, EOF |
| `TESTS-RESULTS/gh605-implementation/provenance.jsonl` | 1–28, EOF |

- [Pass] **Round 5 seed finding closed.** The real `--seed` branch reserves `PVTI_mock_item_0001` by setting `next_item_id = 2` before saving (`utils/py/mock_gh_board.py:344`, `:356`). The regression calls that branch, adds issue 124, updates the returned ID, and reads the snapshot; it asserts distinct IDs, issue 123 still In progress, and issue 124 Done (`test/test_gh605_board_policy.py:388`). This directly distinguishes the faulty aliasing behavior from the correction. The Producer's witnessed red control and 51/51 result, and the parent's independent 79/79 result on `830455e8`, are attributed to their preceding relay records, not claimed as reviewer executions. No further seed change is needed.
- [Pass] **Earlier ownership/lifecycle findings remain closed.** Section-first event classification and informational metadata handling remain in the shared extraction/writer path (`utils/py/releases_app.py:1449`, `:1469`, `:1600`); repository-aware selection and lease handling remain present (`:3830`, `:4704`). Read-only evidence checks precede SQLite access and distinguish lifecycle from informational visibility (`:5193`, `:5255`, `:5270`, `:5335`). Current fixtures cover multi-repository leasing, repeated terminal queue transitions and ambiguity (`test/test_gh605_work_state.py:534`, `:561`, `:626`). The broader module sweep found no contradictory path requiring these dispositions to reopen.
- [Pass] **Policy preservation and bounded transport remain intact.** Invalid/ambiguous ledger identity is handled before linked-PR targeting, CLOSED ambiguity is preserved, and unset membership is distinct from absence (`utils/py/board_sync.py:226`, `:269`, `:307`, `:327`). The actual owner/snapshot query paths use the corrected owner union and balanced query shape (`:610`, `:650`). Top-N, stable tie/override, time-window and PR precedence handling remain consistent with the controlling plan; no scheduler or implicit live-apply path was introduced (`PROJECT/2-WORKING/GH-605-WORK-STATE-PROJECTION.md:210`).
- [Pass] **Apply/restore retains its audited refusal boundaries.** Shared writes validate options and mutation acknowledgements around per-request audit callbacks (`utils/py/board_sync.py:735`, `:750`, `:769`). Saved-preview age considers both clocks; apply rechecks evidence/decisions under lock and fences each operation (`:1132`, `:1160`). Restore conditions on exact item identity and status, preserves newly added cards, and keeps unresolved outcomes indeterminate (`:1234`, `:1336`). Tampered preview and remote drift fixtures assert zero GraphQL writes (`test/test_gh605_board_policy.py:975`); no new test requirement is needed for this disposition.
- [Pass] **Existing integration and gate contracts are preserved.** The connector routes policy-owned writes through the guarded policy surface (`utils/py/work_connectors/github_board.py:125`); the established connector response contract remains present (`utils/py/work_connectors/__init__.py:127`). Both four-line shell wrappers invoke the existing Python fixtures (`test/gh605-work-state.sh:1`, `test/gh605-board-policy.sh:1`), with shell registrations and runner retained (`validate.sh:550`, `:1227`). GH-57 uses deterministic distinct clocks and the resolved-settings union while retaining duplicate guards (`test/gh57-releases-fuzz.sh:118`, `:127`, `:146`, `:173`, `:188`). Its recorded 38/42 red control and restored 42/42 result substantiate the narrow fixture correction (`TESTS-RESULTS/gh605-implementation/provenance.jsonl:26`).
- [Pass] **Evidence does not prematurely claim current runtime completion.** The stored SUMMARY explicitly says “not yet approved” and identifies its historical candidate (`TESTS-RESULTS/gh605-implementation/SUMMARY.md:1`, `:3`); its 378/378 gate belongs to `ae7006c8`, as does the final stored receipt (`TESTS-RESULTS/gh605-implementation/provenance.jsonl:28`). Those are historical evidence, not a final gate for `830455e8`. The final parent packet explicitly places the one current full gate after this source approval. Historical CHANGELOG entries were reviewed as dated records, without external revalidation. FAQ diagnosis/repair/preview/restore guidance remains aligned (`RELEASES-DB-FAQS.md:14`, `:32`, `:39`).

Graph limitation: Verify-tier inventory and coverage were checked against the nearest project, `gh605-implementation-qa-current`, generation `2026-09-14T03:39:25Z`. It points to retired worktree `rtl-wt.2ftoiy`, not this checkout; every requested path reports missing freshness. CHANGELOG and mock are excluded, and recorded parse gaps include GH-549 lines 898/910/1177 and GH-57 line 214. All those files and ranges were covered by the direct source reads above; no graph completeness claim or reindex mutation is made.

No source/artifact was executed or changed, and no tests, Git commands, live network mutations, board/config/ledger writes, or new scratch artifacts were performed by this Reviewer. Only this relay record and the required token lifecycle were changed. No open Blocker/Should/Nit remains from this review.

Relay closed (Approved), no further turn needed. Parent proceeds with the already-required final full gate before live Rev.2 application; this approval alone does not claim that gate or live application has occurred.


### Attestation · relay-drive — 2026-09-14T06:54:24Z
task: RELAY-gh605-implementation-qa
reviewer: codex
status: Approved
reviewed-head: 96261ab2667484feb91cf4cd0e0d09545827cb1e
added-range: 92797+7083
added-sha256: f5d69bd88a0da37cab1e851507b7972996482748b7340380a07a384f4cb0425e
## Producer — Round 7: actual live acceptance JSON boundary correction

VERDICT: PARKED
Basis: Round6 approval remains historical evidence. The final gate on85cf25cc passed381/381
in795s and pushed normally, but the subsequent real apply failed before writing because
fresh unresolved identity tuples differ from the saved JSON arrays. This is an observed
core acceptance failure, not speculative review scope. Under the operator's instruction
to finish the lane, this same lane gets ONE bounded correction review (7/7), not a restart.

Disposition: Implemented — Sol High normalizes unresolved identities at the planner output
boundary. Existing real integration fixture now includes missing-ledger OPEN issue3,
asserts JSON-native equality, successful apply, preserved unknown, and genuine unresolved
tampering refusal. No comparison is relaxed. Parent independently79/79pass; Sol witnessed
the enriched test fail before fix and51/51pass after. Parent and Sol source hashes match.
Parent log SHA2565e9256a1314e9bad30f642aac102f0bcb2e813e4eb63b30d42f053ab05489fef.

### Current bounded review packet (supersedes historical artifact breadth for this turn)

Operational envelope: local developer CLI, explicit single-board apply. Commensurate
complexity: no new frameworks, enterprise scenarios, or speculative test expansion.
Read this relay history, then WHOLE current `utils/py/board_sync.py` and
`test/test_gh605_board_policy.py`, plus `TESTS-RESULTS/gh605-implementation/FINAL.md`.
Other production is unchanged since Round6; do not redo the unrelated 17,729-line sweep.
This is fresh review of the changed JSON seam, with prior approval attributed correctly.

1. Does output normalization preserve every unresolved identity/reason and make real
   build-preview -> JSON save -> apply compare equal for identical evidence?
2. Does the existing integration fixture now exercise nonempty unresolved through the
   actual apply boundary and preserve the unknown issue, while rejecting real tampering?
3. Do the entire two touched files reveal a material contradiction to this correction?
   Require concrete reachable acceptance evidence; do not request speculative machinery.

Review only: ALLOW_PATHS empty. Edit only this relay file, no tests/fullgate/Git/source edits
or live network/config writes. Parent owns verification in separate full clones.
Report concise cited findings, VERDICT PASS/FAIL, Basis, literal swept file: yes/no,
and exact read coverage. Approve only if correct; otherwise hand back one concrete fix.
Complete within8minutes. On PASS set STATUS Approved/NEXT Producer and mark the existing
RELAY-gh605-json-boundary-r7 token done using the shipped tick CLI; driver owns commit.
The prior token is terminal and cannot be reclaimed; this fresh per-review token retains
the SAME relay history and7/7cap, not a replacement review lane.
The fresh corrected-candidate normal gate and live apply remain pending, not reviewer work.

Handing off to Reviewer for this one bounded actual-defect review.

## Reviewer — codex — Round 7 JSON boundary approval

VERDICT: PASS
Basis: The planner now emits JSON-native unresolved identities without dropping identity components, reasons, entries or ordering. The real saved-preview/apply fixture exercises the previously failing nonempty case, and genuine unresolved tampering still fails strict preflight. No material introduced or pre-existing contradiction to this correction was found in the two fully reviewed files. Round 6 remains prior approval for the unchanged broader surface; this approval does not claim the corrected candidate's pending normal gate or live application.
swept file: yes

| File | Current direct read coverage |
| --- | --- |
| `utils/py/board_sync.py` | 1–1492, EOF |
| `test/test_gh605_board_policy.py` | 1–1012, EOF |
| `TESTS-RESULTS/gh605-implementation/FINAL.md` | 1–57, EOF |
| This relay history | 1–1015 before this append, EOF; truncated history spans reread |

- [Pass] **Observed JSON-boundary defect closed.** Every unresolved producer supplies an identity tuple and reason; the return expression copies each record and converts only its identity to a list (`utils/py/board_sync.py:273`, `:286`, `:307`, `:327`, `:372`). This preserves all three identity components and the original reason, matching the existing decisions/changes representation (`:361`, `:368`). Fresh preview reconstruction still compares `unresolved` with ordinary strict equality before audit creation or board mutation (`:1185`, `:1187`, `:1194`). No comparison was relaxed and no further source fix is needed.
- [Pass] **Regression reaches the actual failing boundary with nonempty evidence.** The full-schema fixture creates ledger rows only for issues 1 and 2, while GitHub input includes OPEN issue 3 (`test/test_gh605_board_policy.py:707`, `:780`). It calls real `build_policy_preview` (`:793`), requires the exact unresolved issue/reason and JSON round-trip equality, calls real `apply_policy_preview`, then requires complete status, Ready on issues 1/2, issue 3 still absent, and nonempty persisted audit (`:953`). External/configuration/lock seams are substituted (`:779`); the planner and apply comparison are not. Changing the saved unresolved reason remains a zero-GraphQL-call refusal (`:986`, `:996`, `:998`). The Producer/parent's witnessed-red and 51/51 plus independent 79/79 results are attributed to the Round 7 packet and FINAL record, not reviewer executions.
- [Pass] **Acceptance evidence retains the correct limits.** FINAL explicitly records the tuple/list failure before board writes (`TESTS-RESULTS/gh605-implementation/FINAL.md:44`) and assigns 381/381 to the earlier `85cf25cc`, not this correction (`:56`). The full-file sweep found no additional material finding requiring a new correction or test expansion for this bounded review.

Graph limitation: Verify-tier project inventory found no index for this checkout. The nearest `gh605-implementation-qa-current` generation `2026-09-14T03:39:25Z` points to retired `rtl-wt.2ftoiy`; coverage reports missing freshness for all three requested artifact paths. Findings therefore use the complete current-source reads above; no reindex or graph completeness claim was made.

Only this relay file was edited. No source/artifact programs, tests, Git commands, live board/config/ledger writes or scratch artifacts were run/created; required env-pinned Tick coordination is the sole operational exception. No open Blocker/Should/Nit remains in this bounded review.

Relay closed (Approved), no further review turn needed. Handing back to codex-author (Producer/parent) to run the corrected-candidate normal gate and then complete the already-required live acceptance. Driver owns the relay commit.


### Attestation · relay-drive — 2026-09-14T07:27:56Z
task: RELAY-gh605-json-boundary-r7
reviewer: codex
status: Approved
reviewed-head: d43616f7885b4082a84f5794efc2cd5350c98097
added-range: 103188+3736
added-sha256: ca45b936ac9f60b2bbbed2d7535c677c2fc58def963fa52c8fce1a6a30fd2fb1
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
