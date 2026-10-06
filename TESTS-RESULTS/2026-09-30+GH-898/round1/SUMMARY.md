# GH-898 verification summary (2026-09-30)

Commit under test: c56a0ff8 (implementation 4b378d19 + this evidence script). Run in a disposable full clone; identity unchanged before and after.

| Check | Result |
|---|---|
| Manual matrix (absent-source parity vs base c42044d2, pinned-first/dedupe/cap/tie-break, validation, config output, restore-identity recovery, live DB, three fallbacks) | ALL PASS (`matrix-pass.log`) |
| Red control: resolver merge mutated to drop pinned repos on failure | FAILED as required, rc=1, 6 assertions (`redcontrol-mutated.log`); restored, rc=0 |
| Existing suites: gh402 / gh405 / gh549 / test_gh605_board_policy | 34 / 19 / 125 / 52 passed |

Not run here: the full `validate.sh` gate (run once on the final approved commit). The live-DB probe reads the operator's real rebalanceOS DB; its repo list is printed in `matrix-pass.log`.
