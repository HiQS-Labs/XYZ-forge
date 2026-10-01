# GH-898 verification summary (2026-09-30)

Commit under test: d3e1b631 (round 3 evidence; implementation unchanged since eb314285). Run in a disposable full clone; identity unchanged before and after. Earlier rounds are kept under `round1/` (c56a0ff8; its matrix had 29 PASS — an earlier note saying 31 was a miscount) and `round2/` (eb314285).

| Check | Result |
|---|---|
| Manual matrix: absent-source parity vs base c42044d2, pinned-first/dedupe/cap/tie-break, validation incl. top_n overflow, config output, three fallbacks, live DB | 34 PASS in total (`matrix-pass.log`) |
| Restore: dictionary equality (saved vs recovered vs drifted vs other-board) | PASS — dictionary comparison only |
| Restore: EXECUTION of the real `restore_policy_result` (preview mode, board read stubbed, no board writes): drifted membership refused before readback; documented recovery reaches readback and proposes `restore_to=Ready`; different board number refused before readback | 3 PASS |
| Red control for those three: restore identity guard disabled | refusal checks FAILED, rc=1 (`redcontrol-restore-guard-disabled.log`); restored, rc=0 |
| Earlier red controls: merge drops pinned on failure (round 1, 6 failures); top_n bound removed (round 2, `OverflowError`) | witnessed red then green; logs in `round1/`, `round2/` |
| Existing suites: gh402 / gh405 / gh549 / test_gh605_board_policy | 34 / 19 / 125 / 52 passed |

Not run here: the full `validate.sh` gate (run once on the final approved commit); a live `policy-preview` (the live section resolves the repo list only); URI paths with spaces/unicode and a locked-DB execution (static review only).

## Marker round (2026-10-01, commit ea460d22)
The first full pre-push gate (at 84d6f0a2) was RED and the push was refused: `gh777-inventory-ratchet` (caused by this change: SQLite connect count 32 -> 33) plus 12 harness-discovery suites that inherit the session's `XYZ_HARNESS` and fail identically on base 57bd97af (all 12 pass with it unset). The operator approved annotating the one connect line with the ratchet's own `SQLITE-GATEWAY-OK:` marker. Evidence under `marker/`: matrix 34 PASS, ratchet suite PASS (`clean (matches baseline, 0 new scripts/connects)`), gh402/405/549/605 34/19/125/52. The full gate is re-run once on the final commit with `XYZ_HARNESS` unset.
