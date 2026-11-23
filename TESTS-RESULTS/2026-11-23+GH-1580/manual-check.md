# GH-1580 manual check: swarm_preflight misreports (red/green)

No new suite (GH-831). The check replays #1205's defects through the real preflight CLI against throwaway
fixture repos (`controls.sh`; `gh` stubbed, `uv` absent from PATH). Every case states the CORRECT behaviour and
prints MATCH or MISMATCH; the script exits 0 either way, so read the totals.

| Run | Tree | Result | Evidence |
|---|---|---|---|
| RED | origin/development 81eefac61 (pristine export) | MATCH=7 MISMATCH=11 | `outputs/red.txt` |
| GREEN | changed head fc26f01b9 | MATCH=18 MISMATCH=0 | `outputs/green.txt` |
| RED CONTROL (cd rule) | green tree with the cd-context guard and subshell restore removed | MATCH=15 MISMATCH=3 (D2g, D2h, D2i) | `outputs/mutant-unconditional-cd.txt` |
| Adjacent path | all 129 in-repo Preflight Contract docs, base vs changed | exit code and readiness line identical for all 129 | `outputs/corpus-sweep.txt` |
| Existing suites | 17 shell suites + `test_python_layer.py` in a disposable full clone | all rc=0, pytest 21 passed | `outputs/existing-suites.txt` |

What each defect read on the unchanged source (red.txt):
- D1a `grep_present '^ENABLE_X=1$'` on a mid-file line: STALE (exit 4), should be ready. D1b `grep_absent '^alembic check'` with the fix on its own line: ready, should be STALE.
- D2b the #1140 gate (`bash -n … && uv lock --check`, `uv` absent): ready (exit 0), should be NOT-READY (exit 5). D2d/D2e: a missing script in a later command, or after `cd src`: ready.
- D3 an issue with criteria under `## Done when`: `acceptance: unknown [cause: no-issue-section]`, ready, no gap line and no `readiness.acceptance_gaps` key.

Observation recorded against the task framing: the acceptance check was not literally silent on the base (it printed
`unknown [cause: no-issue-section]`), but it flagged nothing to act on and named no heading. The change adds an
explicit `gap` line and `readiness.acceptance_gaps`, advisory only (GH-557 keeps non-manifest lanes ready, exit 0).

Smoke (GH-1088): main path = the controls above through the CLI; adjacent path = the 129-contract sweep (real
contracts, a rerun-shaped comparison with no state written).
