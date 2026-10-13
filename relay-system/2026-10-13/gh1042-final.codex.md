# RELAY · GH1042 + GH1045 final implementation QA
NEXT: codex (Reviewer)
STATUS: Open
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
