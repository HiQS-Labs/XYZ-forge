# RELAY · GH1042 + GH1045 final implementation QA
NEXT: —
STATUS: Approved
ROUND: 1 / 3

## Setup
Producer: Codex outer session. Reviewer: independent Codex CLI through shipped relay.
Definition of done: separate GH1042 force gate-only and GH1045 historical completion acceptance, strict GH505 current-candidate merge validation, no new suites/gates/Bash edits, truthful historical receipt identities.
Review against development b9f07ea5b8d95bac62a3ed9f886770fee883030f. Production source commit 7128b49620a681ecec78e7c9a8b2722b709300e7; evidence/docs e5564d7a. Review the full relevant functions in utils/py/marathon_drive.py and utils/py/relay_attest.py; read Jog's actual merge consumer without changing it.
Plan: PROJECT/2-WORKING/GH-1042-FORCE-GATE-ONLY-REFIRE.md; plan QA receipt: relay-system/2026-10-13/gh1042-plan.codex.md (first two structural failures rejected; third exit0 Approved).
Evidence: TESTS-RESULTS/2026-10-13+GH-1042/SUMMARY.md, fixed-results.json, final-focused-results.json, provenance.jsonl and raw logs. 33 manual expected outcomes passed at final source. Existing marathon-drive passed at final source after finding/fixing approval-event timing. gh491/gh505/gh642 passed at preceding source; final full gate will run exactly once through push boundary after approval. Clone identity stayed unchanged.
Operational envelope: local single-user harness, same GH505 containment boundary; no enterprise threat-model expansion. No automatic unsafe legacy backfill. Old divergent runs without completion metadata retain strict refusal and require explicit rebuild. Grade requirements and commensurate complexity; reject scope creep/new suites. No provider calls claimed in manual fixture replay.
Reviewer may read/query and use narrow non-mutating source probes; may NOT run suites/pytest/executable fixtures here, create production files, git commits or pushes. Edit only this thread. Final review Basis must distinguish inspected retained evidence from independently executed behavior. The actual full gate is pending, not claimed passed.

## Log

### Round 1 · Producer
Did: implemented optional protected phase completion using existing atomic approval writer; resolved satisfaction before force allocation; support base/numeric/force family; retain strict merge checks and no-fresh-review receipt on historical recovery. Preserved GH273 approval-event timing after suite caught regression. Separate issue captures/rated accepted-start rows maintained.
Verification: recorded manual replay, 33 expected observations pass; corrected marathon-drive suite pass at7128b496; earlier gh491/gh505/gh642 passes; no tests or gate machinery added. Required full publication gate pending.
Open questions: Can any source drift before initial stamp incorrectly become satisfied? Can wrong-phase/lane/review or unreachable completion pass? Does historical recovery mutate or misreport approval for current HEAD? Are completion-write failure and old-reader fallback conservative? Are final evidence claims honest and source changes surgical? Review source, not producer claims.
Commit: e5564d7a.

## ▶ TAKE YOUR TURN — codex
Append `### Round 1 · Reviewer · <timestamp>` with a literal line `VERDICT: PASS` / `VERDICT: FAIL` / `VERDICT: PARKED`, nonempty `Basis: ...`, `swept file: yes/no`, cited graded findings and `Commit: none`. The machine verdict value MUST be exactly PASS, FAIL or PARKED; NEVER use Approved as that line's value. For PASS set header STATUS: Approved and NEXT: — and mark the pinned tick token done. For findings set STATUS: Open, NEXT: producer and release token to producer. Do not edit old blocks except header fields. Only this thread may change; no git or suites. Review the actual committed source and retained evidence. Three-round cap applies.

### Round 1 · Reviewer · 2026-10-13T15:55:16.579662+00:00
VERDICT: PASS
Basis: Inspected the supplied local source, the canonical plan, retained manual replay source/results/raw logs, final focused receipts and provenance. This is source review plus inspection of producer-run evidence, not an independently executed behavioral replay. No git, suite, pytest, executable fixture, provider call or merge was run. The supplied source identity is 7128b496; git identity/diff was not independently queried under this turn's prohibition. Graph discovery found no index for this checkout; nearest XYZ-forge generation 2026-09-01T15:54:30Z was stale/different-root, with changed/untracked coverage for these paths. Exact local source was therefore authoritative.
swept file: yes

- [Pass] GH1042: `utils/py/marathon_drive.py:2799` through startup satisfaction and force allocation at `:2920` resolve the recorded base/numeric/force family before allocating a fresh force token. Explicit token selection remains authoritative. Retained `fixed-results.json` records force/base/numeric recovery without dispatch and explicit/unrelated-token rebuild controls with dispatch; `baseline-results.json` records the pre-fix force dispatch.
- [Pass] GH1045 authority: `utils/py/relay_attest.py` functions `record_phase_completion` and `phase_completion_candidate` extend the existing atomic record writer, bind phase/lane/review identity, validate the stamped candidate with strict `candidate_ok`, and require ancestry to current HEAD. Missing metadata retains strict legacy validation; malformed metadata refuses. `utils/py/marathon_drive.py:2673` stamps only after gate, required-test and final candidate validation; write failure exits 4. Retained refusal logs cover pre-completion drift, wrong phase/lane/review, missing/empty evidence, malformed candidate, divergent ancestry, post-hook drift and completion-write failure.
- [Pass] Historical receipt and merge separation: `utils/py/marathon_drive.py:2721` checks recovery-time committed source drift against recovery HEAD, retains the historical candidate, skips repeated completed hooks/test-delta obligations, and suppresses new gate/phase-QA receipts (`:2773`, result writer `:201`). Jog's actual consumer at `utils/py/jog_run.py:414` and `_merge_reviewed_pr` at `:1430` still requires the live PR head to equal the validated candidate, applies strict `candidate_ok`, and pins merge with `--match-head-commit`. Historical completion does not authorize an unreviewed successor merge. These checks concern committed candidates, as in the existing GH505 contract.
- [Pass] Retained evidence is candid about the event-order regression and its repair: `complete_phase_success` emits approval before the post-approve hook but stamps completion afterward. `marathon-drive-final.log` ends with `marathon-drive: 162 pass, 0 fail`; `final-focused-results.json` and `provenance.jsonl` identify source 7128b496. Earlier gh491/gh505/gh642 runs are explicitly attributed to 0275a7a0. The two-phase raw log shows p1 recovery followed by p2 retry dispatch and the intended stub exit 7; its old standalone result object is not treated as a fresh traversal receipt.
- [Pass] Independently executed read-only evidence probe, exit 0, decisive output: `33/33 retained outcomes match; both retained identity pairs match`. Command:
  ```python
  import json,pathlib
  p=pathlib.Path('TESTS-RESULTS/2026-10-13+GH-1042')
  r=json.loads((p/'fixed-results.json').read_text())
  assert r and len(r)==33 and all(x['ok'] and x['rc']==x['expected'] for x in r)
  assert all(json.loads((p/(s+'identity-before.json')).read_text())==json.loads((p/(s+'identity-after.json')).read_text()) for s in ('','final-'))
  print('33/33 retained outcomes match; both retained identity pairs match')
  ```
  Executed via `python3 -` with `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR="$PWD/.relay-scratch/tmp"`. Separate read-only `ast.parse` of all three reviewed Python files exited 0. Neither probe establishes fresh runtime behavior.
- [Unverified — needs clone run] The final full publication gate remains pending. This PASS approves the reviewed implementation for that next gate; it does not assert publication/merge readiness or a fresh end-to-end provider run. No blocking source finding within the bounded review.

Commit: none
