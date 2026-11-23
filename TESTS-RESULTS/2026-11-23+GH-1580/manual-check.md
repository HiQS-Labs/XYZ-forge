# GH-1580 manual check: swarm_preflight misreports (red/green)

No new suite (GH-831). The check replays #1205's defects through the real preflight CLI against throwaway
fixture repos (`controls.sh`; `gh` stubbed, `uv` absent from PATH). Every case states the CORRECT behaviour and
prints MATCH or MISMATCH; the script exits 0 either way, so read the totals.

| Run | Tree | Result | Evidence |
|---|---|---|---|
| RED | origin/development 81eefac61 (pristine export) | MATCH=15 MISMATCH=21 | `outputs/red.txt` |
| RED (final-QA r1 repairs F1-F4) | fc26f01b9, the tree before them | MATCH=22 MISMATCH=14 | `outputs/prerepair-r1.txt` |
| RED (final-QA r2 repairs F5-F7 + audit) | b3b62735b, the tree before them | MATCH=26 MISMATCH=10 | `outputs/prerepair-r2.txt` |
| RED (round-4 F8 repair) | 5f51d28c8, the tree before it | MATCH=33 MISMATCH=3 (D2w, D2x, D2y) | `outputs/prerepair-r3.txt` |
| GREEN | changed head 940d58499 | MATCH=36 MISMATCH=0 | `outputs/green.txt` |
| RED CONTROL (cd rule) | green tree with the cd-context guard and subshell restore removed | MATCH=33 MISMATCH=3 (D2g, D2h, D2i) | `outputs/mutant-unconditional-cd.txt` |
| Adjacent path | all 129 in-repo Preflight Contract docs, base vs changed | 128 identical; GH-269 rc 6 -> 4 (intended, F4) | `outputs/corpus-sweep.txt` |
| Existing suites | 17 shell suites + `test_python_layer.py` in a disposable full clone, identity bracket before/after unchanged | all rc=0, pytest 21 passed | `outputs/existing-suites.txt` |

What each defect read on the unchanged source (red.txt):
- D1a `grep_present '^ENABLE_X=1$'` on a mid-file line: STALE (exit 4), should be ready. D1b `grep_absent '^alembic check'` with the fix on its own line: ready, should be STALE.
- D2b the #1140 gate (`bash -n … && uv lock --check`, `uv` absent): ready (exit 0), should be NOT-READY (exit 5). D2d/D2e: a missing script in a later command, or after `cd src`: ready.
- D2k/D2l/D4a (final QA r1): a `-c` after the script hid a missing script; an attached `>/dev/null` made a real script look missing; a removed unwanted path read `blocked`.
- D2n/D2p/D2r (final QA r2): an assignment-prefixed `cd` left the old directory certain; a heredoc body was run as commands; `bash -s arg` read the argument as a script. Audit cases D2t-D2v: `[[ a && b ]]`, an unquoted glob operand and process substitution are skipped, not asserted missing.
- D2w/D2x/D2y (round 4, F8): `true && if [[ -f a && -f b ]]; then …; fi` was split at the `&&` inside `[[ ]]` and refused with `command '-f' not found`; a missing command inside the same block must still be found.
- D3 an issue with criteria under `## Done when`: `acceptance: unknown [cause: no-issue-section]`, ready, no gap line and no `readiness.acceptance_gaps` key.

Observation recorded against the task framing: the acceptance check was not literally silent on the base (it printed
`unknown [cause: no-issue-section]`), but it flagged nothing to act on and named no heading. The change adds an
explicit `gap` line and `readiness.acceptance_gaps`, advisory only (GH-557 keeps non-manifest lanes ready, exit 0).

Smoke (GH-1088): main path = the controls above through the CLI; adjacent path = the 129-contract sweep (real
contracts, a rerun-shaped comparison with no state written).

Callers verified: preflight exit codes and the readiness line are unchanged for every in-repo contract except the intended GH-269 case;
marathon (`acceptance_probes_unmet`, same `eval_probes`) and jog (`_dry_run_preflight`, exit-code map) are covered by gh438, gh280 and gh291 in
`outputs/existing-suites.txt`; marathon-plan classification by `marathon-plan.sh` (exit-code map); conveyor, flywheel and kickstart invoke
the preflight CLI and read the same verdict/exit codes, with no parsing of the `readiness` key set (read at `skills/*/SKILL.md`).
