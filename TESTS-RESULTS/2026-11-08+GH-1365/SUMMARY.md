# GH-1365 verification

- Existing Jog adapter: 227 passed, 0 failed; separate full verification clone retained its HEAD and local Git configuration throughout. Existing Codex turn suite: 43 passed, 0 failed with unchanged identity.
- Manual command: `python3 TESTS-RESULTS/2026-11-08+GH-1365/manual-replay.py SOURCE_CLONE NEW_DISPOSABLE_WORK_DIRECTORY`. Requires Python dependencies requests/PyYAML, Git and the source commit. The script clones its source, uses a local bare mirror for fetch, and captures every GitHub operation locally. No production function is replaced and no live issue is closed/commented.
- Main path uses actual PR #1361 head and its committed #1287 receipt. Baseline cff1d0a16 refuses the nonledger tail; candidate succeeds and records the original review head, review candidate, tested head, PR head and merge separately. Adjacent repeat preserves bytes and counts. Five invalid-input cases refuse without ledger changes. A self-consistent *fixture* receipt on an unrelated commit also completes a parked queue; it is not evidence of an actual review of that constructed commit.
- `manual-results.json` contains the nine outcomes and final historical landing record. `provenance.jsonl` names source revisions and the runner hash. GitHub snapshots are recorded inputs, not a claim that live issue state is unchanged.
- Full classified gate remains pending until final QA; focused checks are not a full-gate claim. No live queue was modified. Plan QA approved in round 2 after adding the missed Jog instruction consumer.

## Component observations

| Component | Verdict | Evidence |
|---|---|---|
| Queue policy | helped | Historical failure/success control and idempotent replay |
| Version attribution | helped | Distinct recorded historical review/gate/landing SHAs |
| Guidance | no observed effect | Text inspected; no future-run burden reduction measured |

Lessons register: NO_ENTRY; this bounded replay does not establish a general improvement in factory performance.
