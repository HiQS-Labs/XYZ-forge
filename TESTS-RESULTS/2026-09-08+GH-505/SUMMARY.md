# GH-505 / GH-509 / GH-510 — gate provenance

Branch `fix/gh505-relay-reviewer-integrity`, final revision `8061b254`. Strict `validate.sh` in a disposable
full clone (`~/task-clones/xyzforge-gh505-gate`), identity verified before and after each run.

| run | commit | result | note |
|---|---|---|---|
| history-1 | 2ca56630 | 355/356 | gh280 N1 — fixture gap, fixed |
| history-2 | c2e01270 | 356/356 | round-1 fix commit |
| history-3 | ce420d4a | 355/356 | gh139 pipe-grep guard on the test helper — fixed |
| **final** | 8061b254 | 355/356 | `agent-chorus.sh` fails identically at base `a6441b9b` in this environment (control recorded); GH-528 parallel flakes passed alone |

Also recorded: the 60-case `test/gh505-relay-attest.sh` run with the base-driver red controls, and the
H4 second-bind mutation control. Full final log: `validate.log.gz`.
