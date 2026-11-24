# GH-1580 manual check: swarm_preflight misreports (red/green)

Current scope: see **Retained scope after final QA** below. The first-command gate
check stays in place. Earlier plain-gate runs record the withdrawn change.

No new suite (GH-831). The check replays #1205's defects through the real preflight CLI against throwaway
fixture repos (`controls.sh`; `gh` stubbed, `uv` absent from PATH). Every case states the CORRECT behaviour and
prints MATCH or MISMATCH; the script exits 0 either way, so read the totals.

| Run | Tree | Result | Evidence |
|---|---|---|---|
| RED | origin/development 2ac998d13 (the merge-base, unchanged preflight) | MATCH=5 MISMATCH=31 | `outputs/red.txt` |
| GREEN | changed head 7cc4efb16 | MATCH=36 MISMATCH=0 | `outputs/green.txt` |
| RED CONTROL (plain-gate guard) | green tree with every gate treated as plain | MATCH=17 MISMATCH=19 (the non-plain READY + gap controls fail) | `outputs/mutant-all-plain.txt` |
| Regression guard | base gate block vs new gate block over 33 distinct gate strings (26 plain) | 0 READY -> NOT-READY flips | `outputs/gate-regression-guard.txt` |
| Adjacent path | all 129 in-repo Preflight Contract docs, base vs changed | 128 identical; GH-269 rc 6 -> 4 (the `path_present` effect) | `outputs/corpus-sweep.txt` |
| Existing suites | 17 shell suites + `test_python_layer.py` in a disposable full clone; identity bracket before/after unchanged; no suite edited | all rc=0, pytest 21 passed | `outputs/existing-suites.txt` |

What each defect read on the unchanged source (red.txt):
- D1a `grep_present '^ENABLE_X=1$'` on a mid-file line: STALE (exit 4), should be ready. D1b `grep_absent '^alembic check'` with the fix on its own line: ready, should be STALE.
- D2b the #1140 gate (`bash -n … && uv lock --check`, `uv` absent): ready (exit 0), should be NOT-READY (exit 5). D2d and D2k: a missing script in a later command of a plain gate: ready.
- D3 an issue with criteria under `## Done when`: `acceptance: unknown [cause: no-issue-section]`, ready, no gap line and no `readiness.gaps` key.
- D4a `path_present` on an already-removed path read `blocked`; it is `landed` now.

Gate rule (operator decision 2026-11-24 on #1580): a plain `&&` list has every command checked (D2a, D2b, D2d,
D2k, D2s refuse the genuinely missing one; D2z accepts a fully resolvable one with no gap line). Every other
gate keeps the base first-command check and carries an advisory gap line (D2c-D2aa): all the false-refusal inputs
from final-QA findings F1-F9 are READY, and the gap line is asserted so the check can fail. D2e, D2m, D2o, D2q
and D2x record the accepted trade-off: a missing command inside a non-plain gate is a gap, not a refusal.

The acceptance check was not literally silent on the base (it printed `unknown [cause: no-issue-section]`) but it
flagged nothing and named no heading; it now emits an explicit gap, advisory only (GH-557 keeps non-manifest
lanes ready, exit 0).

Smoke (GH-1088): main path = the controls above through the CLI; adjacent path = the 129-contract sweep (real
contracts, a rerun-shaped comparison with no state written).

Callers verified: preflight exit codes and the readiness line are unchanged for every in-repo contract except
GH-269; marathon (`acceptance_probes_unmet`, same `eval_probes`) and jog (`_dry_run_preflight`, exit-code map) are
covered by gh438, gh280 and gh291 in `outputs/existing-suites.txt`; marathon-plan classification reads the same
exit codes; conveyor, flywheel and kickstart invoke the preflight CLI and read the same verdict and exit codes,
with no parsing of the `readiness` key set.

## Allow-list repair evidence

- Previous candidate `fd5c43fb1` rejects the three new controls for `+x`, bundled
  `-eO` and `shopt`. The complete clone replay is 39 matches and three mismatches
  in `outputs/allowlist-red-full.txt`.
- The repaired source `54ab9275c`, also at tested merge head `ba7cf57cb`, passes
  all 42 controls in `outputs/allowlist-green.txt`. The simple `-nx` script still
  passes and an absent script or external program still blocks.
- Four existing focused suites pass 154 checks in aggregate. The disposable clone's
  HEAD, bare flag, remotes, local email and clean status matched before and after.
  The saved output redacts the local path only. See `outputs/allowlist-focused-suites.txt`.
- Earlier tables above describe the preceding implementation at the named SHAs.

## Retained scope after final QA

The allow-list final review reproduced a false refusal for a later `NAME+=value`
assignment. The gate extension was removed under the operator's fallback.
The gate results above are historical. The delivery candidate retains line anchors,
the removed-path fix, and explicit advisory acceptance gaps.

- At development `895cec0f2`, the retained-scope CLI controls record 6 matches and
  8 mismatches. At `c6b4959ab`, they record 14 matches and zero mismatches.
- The first-command evaluator matches development byte for byte. The CLI keeps its
  existing first-command and later-command outcomes, including the input that
  failed the withdrawn change's final review.
- The prior gate corpus transcript's line endings have been normalized to remove
  trailing whitespace. This preserves the observed verdicts and has an updated hash.

### Dangling-link review finding

The probe runs against a snapshot of the target ref. The control commits a dangling
symlink to the fixture ref so it exercises a directory entry present in that snapshot.
The previously approved head reports STALE and the repaired source reports READY.
The replay passes 15/15 controls with the repair, including the existing absent
and present path cases. See `outputs/dangling-ref-red.txt` and
`outputs/dangling-ref-green.txt`.
