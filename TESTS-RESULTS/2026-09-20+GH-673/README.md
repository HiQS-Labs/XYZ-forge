# GH-673 — Flight Deck established-work reader: 2026-09-20 rebase evidence

Branch `fix/gh673-reader-completion` rebased from `ba1f58e8` onto origin/development `41be79e2`
(every content path patch-identical to the pre-rebase tip `09ec4faa`; the GH-673 ledger row replayed
through `releases_app`, never text-merged). Head at evidence time: `9123b89b`.

| Check | Where | Result |
|---|---|---|
| `pytest test/flightdeck` | task clone | 39/39 |
| work-status selector checks | task clone | pass |
| real-Chrome checks (Node 26) | task clone | pass |
| manual harness fixture check | task clone | pass |
| gh53-releases-merge-resolve | task clone | 17/17 |
| **full `validate.sh`** | disposable clone `/tmp/xyz-gh673-probe` | **407/409**; the two reds (`gh268`, `gh649`) are red on unmodified `development` in the same environment (`dev-control-*.log`) |
| final QA | agy relay, `relay-system/2026-09-17/gh673-replacement-focused.md` | PASS / Approved (Codex over quota) |

`provenance.jsonl` carries one row per check with log sha256; `validate-identity.txt` records the
disposable clone's HEAD and porcelain state before and after the gate (unchanged).
The 2026-09-17 evidence (`TESTS-RESULTS/2026-09-17+GH-673/`) is the pre-rebase record and is retained.
