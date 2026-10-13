# GH-898 verification summary (2026-09-30)

Commit under test: eb314285 (round 2, after final-QA r1 F1). Run in a disposable full clone; identity unchanged before and after. Round-1 evidence at c56a0ff8 is kept under `round1/` (its matrix had 29 PASS; an earlier note saying 31 was a miscount).

| Check | Result |
|---|---|
| Manual matrix (absent-source parity vs base c42044d2, pinned-first/dedupe/cap/tie-break, validation incl. top_n overflow, config output, restore-identity recovery, live DB, three fallbacks) | 31 PASS, ALL PASS (`matrix-pass.log`) |
| Red control for the F1 guard: guard removed | matrix crashed with the reviewer's `OverflowError`, rc=1 (`redcontrol-f1-guard-removed.log`); restored, rc=0 |
| Round-1 red control (merge drops pinned on failure) | failed 6 assertions as required (`round1/redcontrol-mutated.log`) |
| Existing suites: gh402 / gh405 / gh549 / test_gh605_board_policy | 34 / 19 / 125 / 52 passed |

Not run here: the full `validate.sh` gate (run once on the final approved commit). Not shown by the matrix: URI paths with spaces/unicode on a non-default DB path, and a locked-DB execution (static review only).
