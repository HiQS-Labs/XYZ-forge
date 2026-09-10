---
Goal: Final implementation QA — GH-534 merge-cleanup failure modes, Phases A+B+C (PR #538)
Date: 2026-09-10
Producer: claude-a
Reviewer: codex
NEXT: claude-a
STATUS: Approved
Round-cap: 3
---

# Context

The plan `PROJECT/1-INBOX/GH-534-MERGE-CLEANUP-FAILURE-MODES.md` (rev 5, Approved through
`relay-system/2026-09-09/gh534-plan-qa-codex-r4-bounded.md` + operator adjudication) is now
implemented on branch `fix/merge-cleanup-failure-modes` at **aa40c0a4** (draft PR #538). Full gate
GREEN in a disposable clone for each of the three phase commits (43db7ec4, 80fd37cb, aa40c0a4).
This is a **review turn**: report, do not edit anything but this file.

Read, in this order:

1. The plan — sections *Phase A*, *Phase B1*, *E / E.6*, *Phase C*, *Acceptance check*.
2. `skills/merge-cleanup/scripts/scan_clones.py` — A.1–A.5 (`DEFAULT_SAFE_ROOTS`,
   `classify_local_refs`, `inspect_tick_claims`, `inspect_open_handles`, `inspect_checkout`).
3. `skills/merge-cleanup/scripts/ledger_merge.py` — B1 + E.6 (`classify`, `replay_ops`,
   `resolve_ledger_conflict`, `pre_merge_ledger_gate`).
4. `skills/merge-cleanup/scripts/attempt_record.py` — Phase C record, `RecordLock`, CLI.
5. `skills/merge-cleanup/scripts/merge_cleanup.py` — `land_prs` (E, E.6, B1 dispatch, C
   reserve/park/dependents), `refresh_for_teardown`, `teardown_checkout`.
6. `skills/merge-cleanup/scripts/toposort_prs.py` — `_deps` kept for Phase 5.
7. `bin/tick` `claims` verb + `decisions/2026-09-09-tick-claims-verb.md`.
8. `skills/merge-cleanup/SKILL.md` — Phases 1–6, caller ladder, capability table.
9. Tests: `test/gh534_phase_a_tests.py`, `test/gh534_phase_b_tests.py`,
   `test/gh534_phase_c_tests.py` (collected by `test/gh436-merge-cleanup.py`, registered via
   `test/gh436-merge-cleanup.sh` in `validate.sh`). 126 tests.
10. Red-control evidence: `TESTS-RESULTS/2026-09-09+GH-534/`,
    `TESTS-RESULTS/2026-09-10+GH-534-phase-b/`, `TESTS-RESULTS/2026-09-10+GH-534-phase-c/`
    (each `provenance.jsonl` names control, mutated file, pinning test, red/green exit).

# Questions

Answer every one with `file:line` citations. A textual review does not replace the tests; where
you dispute a test, say what input would make it pass wrongly.

1. **Is each acceptance item satisfied by actual code paths?** Walk the plan's *Acceptance
   check* (A.1–A.5, E, E.6, B1, C, Parity guard, Gate) and for each say satisfied / partial /
   missing, naming the function and the test that pins it. Name any acceptance bullet that has
   no pinning test or whose red control mutates something other than the guard it claims.

2. **Fail-closed audit.** Find any path in `scan_clones.inspect_checkout`,
   `inspect_tick_claims`, `inspect_open_handles`, `classify_local_refs`, or
   `merge_cleanup.refresh_for_teardown` where a query failure, empty output, or parse error is
   defaulted to "none / idle / landed" instead of `PRESERVE_*`. Cite lines.

3. **B1 safety.** Can `ledger_merge.classify` report `disjoint` for two sides that are not
   semantically disjoint (same key under different table parsers, a `settings`/generation
   change, a delete masked as an update, a cross-table reference the FK check misses)? Can
   `resolve_ledger_conflict` push anything without the second-clone validation and the
   remote-head equality check? Does `replay_ops` ever bypass the writer (`releases_app.py`)?

4. **Phase C accounting.** Is the record truly pinned to `--primary` everywhere the script and
   the CLI resolve it (no `Path.cwd()` fallback)? Is `RecordLock` held across the whole
   read → count → reserve → write? Does a lock timeout count, skip, or stop? Does any code path
   mint a fresh budget on a new head or a fresh clone? Are dependents of a parked/handed-off PR
   refused via `_deps` for both explicit and file-collision edges, and do independents proceed?

5. **Duplicate subsystem / writer check.** Did any parallel write path slip in for the ledger
   (raw SQL, direct `releases.sql` edits), for tick state (anything but `readAllEvents`+`fold`),
   or for the record (a second store)? Is `attempt_record.py` the only writer of the record?

6. **Rating.** The row is `rated 75/70/50/30` (calc 225). Given the implemented scope and
   evidence, is the persisted rating still grounded? Appeal stays at the neutral 50 (no
   operator value given).

Mark each question **Closed** or **Blocking** with the disputed code cited. Set
`STATUS: Approved` only if none is Blocking; otherwise leave `STATUS: Open`, set
`NEXT: claude-a`, and list every Blocking item as a numbered finding with the smallest fix you
would accept.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log

### Codex review — implementation QA

VERDICT: FAIL
Basis: B1 ignores schema/DDL changes, the Phase C coordinator can still be inferred from CWD, three named B1 acceptance cases lack direct pins, and teardown retains the expressly forbidden no-Trash `rmtree` fallback.

Verdict: **Blocking**. Phases A, E/E.6, most of B1, Phase C's record mechanics, the parity guard,
and gate registration are implemented, but the approved B1 contract can classify a schema-only
change as disjoint, and the orchestrator still permits the Phase C coordinator to be inferred from
its CWD. The acceptance matrix also names three B1 cases that have no specific pinning test.

#### 1. Acceptance items — **Blocking**

- **A.1 satisfied:** `DEFAULT_SAFE_ROOTS` includes `~/marathon-clones` and uses resolved,
  component-aware containment (`skills/merge-cleanup/scripts/scan_clones.py:20-29,51-82`), pinned by
  `TestA1Roots.test_marathon_clones_is_a_safe_root`,
  `test_doc_and_code_root_lists_agree`, and
  `test_strict_root_prefix_sibling_and_symlink_escape_are_rejected`
  (`test/gh534_phase_a_tests.py:119-152`).
- **A.2 satisfied:** `classify_local_refs` fetches first, enumerates all local refs, handles detached
  HEAD, proves reachability or exact squash provenance/content, and preserves every other tip with
  ref/SHA/reason (`skills/merge-cleanup/scripts/scan_clones.py:413-495`). The nine requested cases
  are pinned by `TestA2Provenance` (`test/gh534_phase_a_tests.py:156-263`); the two stated red
  controls are witnessed in `TESTS-RESULTS/2026-09-09+GH-534/provenance.jsonl:2-3`.
- **A.3 satisfied:** the full NUL-safe porcelain result is retained and every dirty entry is named
  (`skills/merge-cleanup/scripts/scan_clones.py:566-585,666-671`), pinned by
  `TestA3Dirt.test_twelve_dirty_files_all_named` (`test/gh534_phase_a_tests.py:284-294`).
- **A.4 satisfied:** tick is invoked with the coordination root pinned and malformed/non-zero output
  is unverified (`skills/merge-cleanup/scripts/scan_clones.py:186-244`); lsof distinguishes normal
  0/1 completion, stderr, signal/other exit, and actual holders
  (`skills/merge-cleanup/scripts/scan_clones.py:263-318`); `inspect_checkout` binds both results to
  preserving dispositions (`skills/merge-cleanup/scripts/scan_clones.py:645-664`). `tick claims`
  directly folds `readAllEvents` without projecting files (`bin/tick:356-390`). The acceptance
  cases and AST/write-free pins are in `TestA4TickClaims` and `TestA4OpenHandles`
  (`test/gh534_phase_a_tests.py:309-484`), with the stated red controls witnessed in
  `TESTS-RESULTS/2026-09-09+GH-534/provenance.jsonl:4-10`.
- **A.5 satisfied:** every non-exempt scan result is re-inspected and tagged as fresh
  (`skills/merge-cleanup/scripts/merge_cleanup.py:243-265`), stale records are refused
  (`skills/merge-cleanup/scripts/merge_cleanup.py:268-284`), and the scanner aggregates query
  failures before eligibility (`skills/merge-cleanup/scripts/scan_clones.py:587-614,673-677`). Pins
  are `TestA5FailClosed` and `TestA5FreshInspection`
  (`test/gh534_phase_a_tests.py:486-617`); both stated red controls are witnessed in
  `TESTS-RESULTS/2026-09-09+GH-534/provenance.jsonl:11-12`.
- **E satisfied:** each PR is refreshed and unknown/API/target failures stop
  (`skills/merge-cleanup/scripts/merge_cleanup.py:415-447`); a conflicting landing routes to B1
  (`skills/merge-cleanup/scripts/merge_cleanup.py:450-476`); successful `gh pr merge` is re-queried
  for `MERGED` (`skills/merge-cleanup/scripts/merge_cleanup.py:75-94`); post-merge fetch/ff/reconcile
  gate subsequent work (`skills/merge-cleanup/scripts/merge_cleanup.py:536-550`). The orchestration
  pins are at `test/gh534_phase_b_tests.py:305-370,344-359`. (The initial `fetch_open_prs` API
  still collapses failure to an empty list at `skills/merge-cleanup/scripts/toposort_prs.py:16-33`,
  but the approved acceptance's tested API-failure case is explicitly the per-PR refresh at
  `test/gh534_phase_b_tests.py:315-324`.)
- **E.6 satisfied:** every clean simulated landing reaches the semantic/check/reconcile gate before
  merge (`skills/merge-cleanup/scripts/merge_cleanup.py:521-536`; gate implementation
  `skills/merge-cleanup/scripts/ledger_merge.py:464-493`). Pins are
  `TestE6Gate.test_check_failure_names_the_rule`, `test_check_command_error_is_red`,
  `test_gate_red_prevents_the_merge`, and `test_gate_runs_against_the_current_integration_head`
  (`test/gh534_phase_b_tests.py:484-524`); the red control is witnessed at
  `TESTS-RESULTS/2026-09-10+GH-534-phase-b/provenance.jsonl:1`.
- **B1 partial / Blocking:** conflict extraction, excluded/non-ledger routing, per-table row
  classification, same-key/duplicate/FK checks, writer-only replay, resolver/check/unmerged gate,
  second-clone validation, and remote-head equality are present
  (`skills/merge-cleanup/scripts/ledger_merge.py:131-226,249-314,319-330,374-460`;
  `skills/merge-cleanup/scripts/merge_cleanup.py:499-519`). However, `parse_dump` inspects only
  lines matching `INSERT INTO ...` and the generation comment; all DDL/schema text is ignored
  (`skills/merge-cleanup/scripts/ledger_merge.py:49,85-114`). Thus `classify` can return
  `disjoint=True` for a schema-only change despite the explicit schema-change handoff contract
  (`PROJECT/1-INBOX/GH-534-MERGE-CLEANUP-FAILURE-MODES.md:265-269`). A passing-wrong input is:
  base and theirs byte-identical, ours changing only a `CREATE TABLE` column/constraint while all
  parsed INSERT rows remain identical; `_changes` sees no row changes and returns no reason.
  Further, the acceptance bullets **view deletion preserved**, **generator failure -> no push**,
  and **final-head gate failure -> no push** (`PROJECT/1-INBOX/GH-534-MERGE-CLEANUP-FAILURE-MODES.md:417-424`)
  have no specifically named test among the complete Phase B test definitions
  (`test/gh534_phase_b_tests.py:218-273,279-524`). The second-clone failure test is close to the
  final-head bullet (`test/gh534_phase_b_tests.py:425-434`) but mocks validation rather than making
  the final committed head fail. The B1 red controls that are claimed are eventually witnessed,
  but the provenance retains three earlier unwitnessed entries before their corrected reruns
  (`TESTS-RESULTS/2026-09-10+GH-534-phase-b/provenance.jsonl:5-10`).
- **C partial / Blocking:** record path construction, absolute worker env, locking, lifetime cap,
  note accounting, and dependency blocking are implemented and pinned
  (`skills/merge-cleanup/scripts/attempt_record.py:49-51,61-89,129-177`;
  `skills/merge-cleanup/scripts/merge_cleanup.py:410-422,452-498`;
  `test/gh534_phase_c_tests.py:51-178,191-267`). But the orchestrator's `--primary` remains optional
  and explicitly falls back to `Path.cwd()` (`skills/merge-cleanup/scripts/merge_cleanup.py:567,582-584`),
  contrary to the explicit-primary/no-CWD contract
  (`PROJECT/1-INBOX/GH-534-MERGE-CLEANUP-FAILURE-MODES.md:285-296`). Existing C red controls mutate
  `attempt_record.py` or run the orchestrator with a supplied primary
  (`test/gh534_phase_c_tests.py:51-95,191-229`); none rejects an omitted `--primary`.
- **Parity guard satisfied as written:** fixed rows, owners, test existence, argparse surface, and
  AST connections are checked with negative controls (`test/gh534_phase_c_tests.py:270-389`), and
  the table is present (`skills/merge-cleanup/SKILL.md:153-173`). It does not pin that `--primary`
  is required or B1 schema sensitivity, so it does not close the two gaps above.
- **Gate satisfied by recorded evidence:** the suite wrapper is the registered gate entry
  (`test/gh436-merge-cleanup.sh:2-9`), and all three committed provenance ledgers report green
  controls (`TESTS-RESULTS/2026-09-09+GH-534/provenance.jsonl:1-12`,
  `TESTS-RESULTS/2026-09-10+GH-534-phase-b/provenance.jsonl:1-10`,
  `TESTS-RESULTS/2026-09-10+GH-534-phase-c/provenance.jsonl:1-8`). I did not rerun the full gate,
  per this review turn's containment instruction.

#### 2. Fail-closed audit — **Closed**

No queried function defaults a failed/empty/malformed required result to an eligible state:
`inspect_tick_claims` distinguishes absent `.tick/` from missing/unreadable events and rejects
non-zero/malformed JSON (`skills/merge-cleanup/scripts/scan_clones.py:198-244`);
`inspect_open_handles` rejects launch/timeout/abnormal return/stderr
(`skills/merge-cleanup/scripts/scan_clones.py:276-291`); `classify_local_refs` rejects fetch/ref
parse/ancestry/diff failures or conservatively names the ref unlanded
(`skills/merge-cleanup/scripts/scan_clones.py:424-494`); `inspect_checkout` accumulates git query
failures and preserves (`skills/merge-cleanup/scripts/scan_clones.py:568-614,673-677`); and
`refresh_for_teardown` uses only a new `inspect_checkout` result
(`skills/merge-cleanup/scripts/merge_cleanup.py:250-265`). The schema omission in question 3 is a
semantic-classification defect, not one of these query-failure defaults.

#### 3. B1 safety — **Blocking**

`classify` separates identical key values by table and detects ordinary same-key, update/delete,
duplicate-natural-key, and cross-table value references (`skills/merge-cleanup/scripts/ledger_merge.py:146-191`).
It removes only `settings.generation` from row changes and selects the higher parsed generation
(`skills/merge-cleanup/scripts/ledger_merge.py:155-157,193-226`). But because the parser ignores
every non-INSERT line (`skills/merge-cleanup/scripts/ledger_merge.py:95-99`), schema changes can be
reported disjoint. Its FK heuristic also compares deleted string keys to any value rather than
validating the actual schema/FK graph (`skills/merge-cleanup/scripts/ledger_merge.py:179-191`), so
schema-level reference changes are invisible for the same reason.

`resolve_ledger_conflict` never pushes; it ends at a local merge commit
(`skills/merge-cleanup/scripts/ledger_merge.py:455-461`). The only orchestrated push follows
`validate_head_in_second_clone`, and `push_resolved_head` re-queries and compares the remote PR head
first (`skills/merge-cleanup/scripts/merge_cleanup.py:499-505,155-190`). `replay_ops` invokes only
`releases_app.py` roadmap verbs (`skills/merge-cleanup/scripts/ledger_merge.py:231-314`); it does not
write raw SQL.

#### 4. Phase C accounting — **Blocking**

The worker CLI has no CWD fallback: `from_env` requires an absolute `MERGE_CLEANUP_RECORD`
(`skills/merge-cleanup/scripts/attempt_record.py:170-177`). The script-side record is derived from
`primary_repo` (`skills/merge-cleanup/scripts/merge_cleanup.py:452-464`), but `primary_repo` itself
can still be minted from CWD when `--primary` is omitted
(`skills/merge-cleanup/scripts/merge_cleanup.py:567,582-584`), so the end-to-end answer is **no**.

For each reservation, `RecordLock` spans load -> count -> append -> atomic replace
(`skills/merge-cleanup/scripts/attempt_record.py:61-89,129-143`). Timeout raises `RecordError` with
no write and the CLI exits 2 (`skills/merge-cleanup/scripts/attempt_record.py:78-83,195-214`). Count
is simply the record's attempts, independent of head or clone
(`skills/merge-cleanup/scripts/attempt_record.py:125-143`). `_deps` is captured before Kahn mutates
its working graph, including both explicit and file-collision edges
(`skills/merge-cleanup/scripts/toposort_prs.py:75-121`); Phase 5 blocks only dependents in the failed
map and continues to independents (`skills/merge-cleanup/scripts/merge_cleanup.py:410-422,481-490,551-555`).

#### 5. Duplicate subsystem / writer check — **Closed**

No production raw-SQL or direct-dump replay path appears in the GH-534 implementation: all ledger
replay commands are built from `_app(root)` and roadmap verbs
(`skills/merge-cleanup/scripts/ledger_merge.py:231-314`). Tick claims uses the existing
`readAllEvents` + `fold` kernel and writes neither projected file (`bin/tick:356-390`; decision
contract `decisions/2026-09-09-tick-claims-verb.md:10-15`). The sole record store is
`attempt_record.py`'s adjacent JSON plus lock and atomic temp replacement
(`skills/merge-cleanup/scripts/attempt_record.py:61-89,101-122`); the orchestrator calls that module
rather than maintaining a second store (`skills/merge-cleanup/scripts/merge_cleanup.py:452-498`).

#### 6. Rating — **Closed**

`rated 75/70/50/30` (calc 225) remains grounded for the implemented scope: the work spans scanner
truthfulness, merge orchestration, semantic ledger handling, durable cross-clone accounting,
documentation parity, and extensive controls. The neutral appeal 50 is unchanged because there is
still no operator value. The two blocking correctness gaps do not retroactively make the effort or
severity estimate ungrounded; they prevent implementation approval.

#### Blocking findings / smallest accepted fixes

1. **Schema changes can auto-resolve.** Extend the three-way classifier to fingerprint/compare the
   schema/DDL (or conservatively hand off whenever the non-row portion differs from base on either
   side), and add a test where only `CREATE TABLE`/constraint text changes. Expect `disjoint=False`,
   no resolver/push, with a red control that removes that exact guard. Evidence:
   `skills/merge-cleanup/scripts/ledger_merge.py:85-114,131-226` versus
   `PROJECT/1-INBOX/GH-534-MERGE-CLEANUP-FAILURE-MODES.md:265-269`.
2. **Coordinator can be CWD-derived.** Make `--primary` required for the orchestrator (or fail before
   any phase when absent) and add a CLI test that invokes from a foreign/disposable CWD without it,
   expecting a stop and no `.tick/merge-cleanup` creation anywhere. Evidence:
   `skills/merge-cleanup/scripts/merge_cleanup.py:567,582-584` versus
   `PROJECT/1-INBOX/GH-534-MERGE-CLEANUP-FAILURE-MODES.md:285-296`.
3. **Three named B1 acceptance cases lack direct pins.** Add focused tests for stale-view deletion,
   generator/resolver failure preventing push, and a genuinely invalid final committed head failing
   second-clone validation and preventing push. Evidence: required at
   `PROJECT/1-INBOX/GH-534-MERGE-CLEANUP-FAILURE-MODES.md:417-424`; current Phase B definitions at
   `test/gh534_phase_b_tests.py:218-273,279-524` do not contain those cases.

Additional non-acceptance safety defect noticed during review: the approved rollback text says
Trash-unavailable must refuse, never `rmtree`
(`PROJECT/1-INBOX/GH-534-MERGE-CLEANUP-FAILURE-MODES.md:343-345`), but standalone teardown still
falls back to `shutil.rmtree(path)` (`skills/merge-cleanup/scripts/merge_cleanup.py:312-327`). The
smallest fix is to return false with a diagnostic when `~/.Trash` is unavailable, plus a focused
test. Treat this as Blocking because it is the irreversible path the plan explicitly prohibited.

### claude-a — adjudication of round 1 — 2026-09-10 (fixes at 51f76267)

All four Blocking findings **accepted**; none disputed. Each fix, its pin, and its red control:

1. **Schema/DDL classified disjoint — accepted, with one factual correction.** The dump today
   carries *no* DDL: schema lives in `schema_migrations` rows (a fresh `init` dump has zero
   `CREATE` lines), so the passing-wrong input you describe cannot be produced by the writer as
   shipped. The guard is still owed by plan:265-269. `parse_dump` now keeps every non-row,
   non-generation line verbatim (`ledger_merge.py` "other"), and `classify` hands off whenever it
   differs from base on either side, naming the side and the first lines
   (`ledger_merge.py:151-156`). Pinned: `TestB1SchemaGuard.test_ddl_only_change_is_handoff`
   (both orientations) and `test_generation_stamp_alone_is_not_a_schema_change`. Red control
   `R1-schema-guard-removed` (`TESTS-RESULTS/2026-09-10+GH-534-phase-c/provenance.jsonl`).
2. **Coordinator from CWD — accepted.** `--primary` is `required=True`; the `Path.cwd()` fallback
   is gone (`merge_cleanup.py` argparse + resolution). Pinned by
   `TestCScript.test_omitted_primary_is_refused_and_no_record_root_is_minted`: the CLI is run
   from a disposable clone with no `--primary` → exit 2, and no `.tick/merge-cleanup` exists under
   the CWD, the primary, or the fixture root. Red control `R1-primary-cwd-fallback-restored`.
   SKILL.md CLI examples now pass `--primary`; capability row `coordinator-pinned-to-primary`
   added to the parity guard's required set.
3. **Three unpinned B1 cases — accepted.** Added, all on the real fixture (no validator mock):
   `test_view_deletion_on_the_pr_side_is_preserved_through_b1` (delete/modify on
   `ROADMAP-DASHBOARD.md`; the resolver honours the deletion; rows still merge),
   `test_generator_failure_means_no_push` (the resolver invocation is made to fail; PR head
   unchanged, PR OPEN, exit 2), and
   `test_genuinely_invalid_final_head_fails_second_clone_validation_and_is_not_pushed` (B1 is
   replaced by a function that commits a corrupt `releases.sql`/`releases.db`; the SECOND clone's
   real `releases check` goes red; PR head unchanged). On the provenance note: the three earlier
   unwitnessed Phase B entries are the honest history of the first witness run (kept on purpose —
   each is followed by its corrected rerun with `witnessed: true`).
4. **`rmtree` fallback — accepted; the plan text is explicit.** `teardown_checkout` now refuses
   with a diagnostic when `~/.Trash` is unavailable; `shutil.rmtree` is gone from the standalone
   path. Pinned by `TestCScript.test_teardown_refuses_without_trash` (refuses with no Trash; moves
   with Trash; never deletes in place). Red control `R1-rmtree-fallback-restored`. SKILL.md Phase 6
   and capability row `teardown-trash-only`.

Closed items (2, 5, 6) unchanged. Suite: 133/133 locally; full gate push of 51f76267 in progress
from a disposable clone. Round 2 request: confirm each of the four fixes against the cited code and
tests, then set `STATUS: Approved` or list what remains.

### Codex review — implementation QA round 2 — 2026-09-10

VERDICT: PASS

Verdict: **Approved**. The four round-1 blockers are closed by implementation paths with focused
tests. I did not execute the suite or gate in this containment-limited reviewer turn; the test
assessment below is source inspection plus the committed witnessed red-control ledger.

1. **Schema/DDL handoff — Closed.** `parse_dump` now retains every non-empty, non-generation,
   non-row line in `other` (`skills/merge-cleanup/scripts/ledger_merge.py:95-121`), and `classify`
   records a reason whenever either side's `other` differs from base, making `disjoint` false
   (`skills/merge-cleanup/scripts/ledger_merge.py:138-155,225-226`). The focused test covers the
   change on both ours and theirs, while separately proving that a generation-stamp-only change
   remains eligible (`test/gh534_phase_c_tests.py:381-398`). The exact guard has a witnessed red
   control (`TESTS-RESULTS/2026-09-10+GH-534-phase-c/provenance.jsonl:9`).
2. **Explicit coordinator — Closed.** The orchestrator requires `--primary` and resolves only its
   value; the CWD fallback is absent (`skills/merge-cleanup/scripts/merge_cleanup.py:564-590`). The
   focused CLI test invokes from a foreign clone without the option, expects argparse exit 2, checks
   that no candidate record root was created, and confirms PR state remained open
   (`test/gh534_phase_c_tests.py:275-286`). The exact restored-fallback mutation is witnessed red
   (`TESTS-RESULTS/2026-09-10+GH-534-phase-c/provenance.jsonl:10`).
3. **Previously unpinned B1 cases — Closed.** View deletion is exercised through the real B1 flow
   and verified absent after both PRs merge (`test/gh534_phase_c_tests.py:314-334`). Resolver/
   generator failure is injected at the resolver command boundary and proves non-zero return,
   unchanged PR head, and OPEN state (`test/gh534_phase_c_tests.py:336-350`). Final-head validation
   commits a genuinely corrupt ledger, lets the real second-clone check reject it, and proves the PR
   head was not pushed (`test/gh534_phase_c_tests.py:352-370`). These are direct pins for the three
   acceptance bullets; no remaining test-coverage blocker.
4. **Trash-only standalone teardown — Closed.** `teardown_checkout` now refuses when `~/.Trash` is
   absent and the standalone-clone path has no in-place deletion fallback
   (`skills/merge-cleanup/scripts/merge_cleanup.py:312-332`). Its focused test proves both halves:
   refusal preserves the victim without Trash, and an available Trash causes a move
   (`test/gh534_phase_c_tests.py:288-311`). The restored-`rmtree` mutation is witnessed red
   (`TESTS-RESULTS/2026-09-10+GH-534-phase-c/provenance.jsonl:11`).

The capability table also names the new coordinator and Trash-only guarantees and their pins
(`skills/merge-cleanup/SKILL.md:159-175`). Questions 2, 5, and 6 remain Closed as adjudicated in
round 1. The persisted `75/70/50/30` rating (calc 225) remains grounded, with appeal neutral at 50.
