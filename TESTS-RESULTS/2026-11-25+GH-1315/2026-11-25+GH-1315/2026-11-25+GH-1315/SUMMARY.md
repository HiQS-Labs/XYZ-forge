# GH-1315 preparation evidence (2026-11-25)

Preparation only: nothing here implements the fix, enqueues work, or adds a readiness label.
`provenance.jsonl` rows carry the time they were recorded (`at`), not the run time; each row names the exact `source_sha` it ran on.

Prepared commit `P` = `ced62b8966e198f74fe01cc1033291e466bfc260` (probes hardened after Codex round 1; the proof below was re-run on `f2115e986`; on `origin/development` `086b657ea37dc2c7d3e1433e29157b451b331f1c`).
All runs used a disposable verify clone whose local `development` was moved to the state under test (Preflight resolves
`target.ref: development` in the target root) with `origin` pointed at GitHub so the issue-state fetch works; python3.12 first on PATH.

| State | Commit | Preflight (`--dry-run`) | Jog promotion lint | Probe verdict |
|---|---|---|---|---|
| Unfixed today | `f2115e986` | exit 0 READY | exit 0 | unfixed |
| Simulated real fix | `ce717e069` | exit 4 STALE | exit 0 | landed |
| Comment-only edit | `9ba644fe2` | exit 0 READY | exit 0 | unfixed |

- `readiness_probe.py`: the retained manual check named by the contract; `expect_nonzero: true`, so only a positive observation of the fixed behavior reads as landed.
- `probe-proof/`: per-state Preflight JSON (individual probe verdicts, evaluated ref SHA), `.rc` exit codes, Jog lint output, and the patches used for the simulated states.
- `existing-suites/`: existing suites run in the disposable clone against the simulated fix (not the full gate).
- Acceptance fidelity is `unknown`/`no-issue-section` (advisory): the issue states criteria under `## Expected`.
- The `skills-army-hq` wrapper prints `SKIPPED: pytest not importable` and exits 0 under python3.12 without pytest (`existing-suites/skills-army-hq-simulated-fix.txt`): a gate run there passes vacuously. The python3.14 run with pytest is the real result (34 passed).
- Ledger read-back for this issue is in `../2026-11-25+GH-977/ledger-readback-977-1315.json`; the row was preserved, not rescored.
