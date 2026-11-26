---
title: "Correct the 'ungated' claim about the merge-cleanup phase B/C suite in the GH-1606 documents"
status: Active
created: 2026-11-25
updated: 2026-11-25
owner: Noel Saw
gh_issue: 1618
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1618
doc_type: bugfix
reported_from: XYZ-forge
harness_commit: 086b657ea
non_goals:
  - any code, test, suite or gate change (GH-831; `validate.sh`, `ci-local.sh`, `test/*` are untouched)
  - rewriting `TESTS-RESULTS/2026-11-25+GH-1606/provenance.jsonl` (a recorded evidence receipt; row `FINDING-phaseB-pre-existing` stays byte-identical)
  - rewriting the original measurements (red standalone at `b479f74e0`: 39 tests, 14 failures, 1 error; cause: GH-1576 wiring check)
  - re-opening Issue #1615 or touching PR #1614 / #1617 text (they already carry the correction)
  - deleting `gh436`'s now redundant module-level stub (named optional in PR #1617, not wanted here)
related:
  - 1606
  - 1614
  - 1615
  - 1617
  - 831
goal: "The two GH-1606 documents no longer assert that the phase B/C suite is ungated or that no gated suite enters the B1 reserve path; each keeps what was measured, marks only the wrong inference as superseded, and carries one dated 2026-11-25 correction note that points to Issue #1615 / PR #1617 and states only what was verified."
---

# GH-1618: Correct the "ungated" claim in the GH-1606 documents

## Status

| What was just completed | What's next |
|---|---|
| Plan approved by Codex (round 2; round 1 FAIL on one wording finding, applied). Edits made to both GH-1606 documents; AC-1 to AC-4 recorded under `TESTS-RESULTS/2026-11-25+GH-1618/`. | Final Codex QA, qualification gate and push from a disposable clone, ready PR. Merge is the operator's. |



## Observed (measured at base `086b657ea`, not remembered)

| Claim | Command / source | Observed |
|---|---|---|
| The gated entry point collects phases A, B and C | `test/gh436-merge-cleanup.py:1382-1384`: `from gh534_phase_{a,b,c}_tests import *`; `validate.sh:96` registers `gh436-merge-cleanup.sh` | `TESTS-RESULTS/2026-11-25+GH-1615/collect_count.py` (existing receipt) rerun: collects **227 tests = 95 own + 46 (A) + 39 (B) + 47 (C)**; the four pinned phase B tests are collected |
| `gh436` stubs the wiring check for its whole process | `test/gh436-merge-cleanup.py:43`: `merge_cleanup.gate_unwired_reason = lambda clone, install=False: ""` | present; this is why the gate stayed green while standalone runs were red |
| A gated-collected phase B test enters the B1 reserve call | probe `TESTS-RESULTS/2026-11-25+GH-1618/probe_gate_reserve.py`: import `gh436` as the gate does, wrap `attempt_record.reserve` and `merge_cleanup.gate_toolchain_fault_reason` with counters, run `TestPhase5EndToEnd.test_two_prs_second_conflicts_after_first_lands_and_b1_resolves_it` | `Ran 1 test ... OK`; `reserve` called 1x, toolchain probe called 1x (one test, healthy path only) |
| No test names the toolchain-fault helper | `git grep -n gate_toolchain_fault_reason -- test` | no match (a direct-reference search only: a test can reach the helper indirectly through `run_main()`, as the healthy-path probe above does, so this does not establish that no gated test supplies a fault). The fault ordering is demonstrated by the GH-1606 manual driver; gated fault-ordering coverage was not established by these checks |
| The wrong sentences | `git grep -n -i -E "ungated|no gated suite|never saw|referenced by" -- PROJECT/3-COMPLETED/GH-1606-MERGE-CLEANUP-PUSH-ENVFAULT.md TESTS-RESULTS/2026-11-25+GH-1606` | Doc lines 30 (status cell), 47 (table row), 131 and 133 (measured-prerequisite bullets); `SUMMARY.md` line 38; `provenance.jsonl` line 23 (left unchanged); doc lines 180, 214, 240 repeat "red at base" / "withdrawn as a witness" without the word "standalone" |
| Existing correction elsewhere | Issue #1615 (closed) body, PR #1617 body, PR #1614 body, #1606 closeout comment | dated correction already present; the two merged files are the remaining gap |

## Per-issue rating (RELEASES vocabulary, `rated pri/sev/appeal/effort`, 1-100)

`15/10/40/90` (2026-11-25). Severity: documentation only; a reader of the merged GH-1606 files could wrongly conclude merge-cleanup phase B/C has no gate coverage and re-file or wire it (this already produced one wrong issue, #1615). No behaviour affected. Priority low: nothing blocked. Appeal 40 is the operator's supplied value, preserved. Effort is cheapness: two files, text only, 90. Recurrence: one incident (the #1615 premise); trend unknown.

## Plan (smallest honest correction)

Extend the two existing documents in place; no new subsystem, no writer other than the files themselves.

1. `PROJECT/3-COMPLETED/GH-1606-MERGE-CLEANUP-PUSH-ENVFAULT.md` (front matter and status table shape unchanged; the doc stays in `3-COMPLETED`):
   - Add one `## Correction (2026-11-25)` section directly after the Status table, containing the dated note (text below).
   - Status cell (line 30): replace "The ungated phase B breakage is tracked in Issue #1615." with a pointer to #1615 / #1617 and the correction section.
   - AC-table row (line 47): strike the whole original row (claim, evidence cell and result cell, including "no suite drives B1 reservation or a toolchain fault") with `~~...~~`, mark it `Superseded 2026-11-25`, and put the verified statement beside it; keep the cited stub/mock facts (they are true of gh436's own tests).
   - "Measured prerequisite" bullets (lines 128-136): keep the 39/14/1 measurement and its cause, add the word "standalone", strike "not referenced by ... so the gate never saw it" and "so no gated suite enters the B1 reserve path" (original text kept, struck), add a one-line "see Correction".
   - Lines 180, 214, 240: insert "standalone" / a bracketed "[correction 2026-11-25: see Correction]" only; no other change.
2. `TESTS-RESULTS/2026-11-25+GH-1606/SUMMARY.md`: line 38 keeps "red at the clean base (39 tests, 14 failures, 1 error)" but replaces "and ungated" with "when run standalone", and the new note adds the cause (the GH-1576 wiring check), which that file did not name before; add a short dated correction note that also says the `provenance.jsonl` row `FINDING-phaseB-pre-existing` carries the word "ungated" in its title and that wording is superseded by this note (the row is unchanged).
3. Evidence for this change: `TESTS-RESULTS/2026-11-25+GH-1618/` (`SUMMARY.md`, `provenance.jsonl`, the probe script). A manual check, not a suite (GH-831).

### Correction note text (doc section; the SUMMARY note is the same facts, shorter)

> **Correction (2026-11-25; Issue #1615, PR #1617, Issue #1618).** What was measured below stands: run standalone at base `b479f74e0`, `python3 test/gh534_phase_b_tests.py` gave 39 tests, 14 failures, 1 error, cause the GH-1576 wiring check (the fixture seed has no `githooks/`). The inference drawn from it was wrong. It came from searching `validate.sh`, `ci-local.sh` and `test/*.sh` for the file name and missing that `test/gh436-merge-cleanup.py` imports phases A, B and C with `from gh534_phase_{a,b,c}_tests import *` (lines 1382-1384 at `086b657ea`) and that `validate.sh:96` registers `gh436-merge-cleanup.sh`. The gate therefore runs the phase B and C tests (the gated entry point collects 227 tests including 39 of phase B); it stayed green because `gh436` stubs the wiring check for its whole process (`:43`). Only standalone runs were red; PR #1617 (merged as `f8bd9860d`) repaired them. Consequently "no gated suite enters the B1 reserve path" is superseded: a phase B end-to-end test collected through `gh436` was run once with call counters and reached `attempt_record.reserve` (1 call) on the healthy path. A search of `test/` found no direct reference to the toolchain-fault helper; the fault ordering this issue added is demonstrated by this issue's manual driver, and gated fault-ordering coverage was not established by these checks. The reserve probe ran at `086b657ea` on that one test only; the gate at the GH-1606 base was not re-run, and nothing else here was re-measured. The original sentences are kept, struck through.

## Alternatives considered

| # | Alternative | Verdict |
|---|---|---|
| 1 | **Dated correction note + strike the wrong inference in place (chosen)** | Keeps the record, fixes the trap for the next reader, text only |
| 2 | Rewrite the sentences silently | Rejected: rewrites history |
| 3 | Leave as is (PR #1614/#1617 already carry the correction) | Rejected by the operator: the merged files are what a future reader opens; #1615 was filed from exactly this text |
| 4 | Edit `provenance.jsonl` too | Rejected: recorded evidence receipt; superseded by a note in `SUMMARY.md` instead |

## Rollback / containment

Documentation only; revert the one PR. No ledger row other than this issue's pickup row changes.

## Acceptance (no new tests: AGENTS.md *No new tests*, GH-831)

| ID | Check | An unfixed candidate fails because | Expected |
|---|---|---|---|
| AC-1 | `git grep -n -i -E "ungated|no gated suite|never saw|referenced by" -- <the two files>` | the wrong sentences are still unqualified | every remaining hit is inside a struck-through original, a correction note, or the untouched `provenance.jsonl` row |
| AC-2 | `git diff origin/development --stat` and `git diff -- TESTS-RESULTS/2026-11-25+GH-1606/provenance.jsonl` | an edit leaked into code, tests, gates or the receipt | only the two target files, this plan, the `TESTS-RESULTS/2026-11-25+GH-1618/` evidence, ledger pickup files and relay threads; `provenance.jsonl` diff empty |
| AC-3 | measured facts survive: grep for `39 tests`, `14 failures` in both files (present before the edit, so they must remain) and for `GH-1576` in both files (present in the doc before; added by the SUMMARY note, which did not name it) | the measurement was deleted instead of qualified | all three strings present in each file after the edit |
| AC-4 | `utils/pdda/pdda.sh run` (docs route) | front matter or status table broken, hardcoded path added | zero errors; `pdda.sh hardcoded-paths` clean for the touched files |
| AC-5 | the correction's factual claims re-run from the evidence directory | a claim in the note that was not verified | probe and collection output match the note; claims the probe did not cover are worded as not covered |

Red control for AC-1: the same grep at `origin/development` (before edits) returns the unqualified hits listed above, so the check does detect the defect.

## Lessons learned

NO_ENTRY (one incident, one correction; a merge is not evidence).
