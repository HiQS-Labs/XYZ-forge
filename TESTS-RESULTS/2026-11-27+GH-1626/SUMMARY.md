# GH-1626 preparation evidence (2026-11-27)

## Current proof: after review round 1 (`probe-proof-r1/`, GitHub origin)

| State | Evaluated `development` (proof clone) | Jog lint | Preflight `--dry-run` | Probe |
|---|---|---|---|---|
| 1 Unfixed, prepared commit | `db8a09385` | 0 | 0 READY | 1 unfixed |
| 2 Simulated fix + `delivery.md` (proof clone only) | `ed06a9254` | 0 | 4 STALE (landed) | 0 |
| 3 Comment-only edit (proof clone only) | `af570e01b` | 0 | 0 READY | 1 unfixed |

Issue fetched in every state: OPEN, acceptance fidelity `unknown / no-issue-section` (advisory). The probe change matrix is in `review-round1-fixes/` (README + `matrix`/variant outputs). The `delivery.md` `path_absent` probe reads `unfixed` on its own until the receipt exists. Delivery needs both probes landed. A real fix without the receipt is not STALE: the behavioral probe reads landed and the receipt probe unfixed, so the aggregate is AMBIGUOUS (exit 7). See `probe-proof-r2/2b-simulated-fix-no-receipt/`.

## Round 0 history (`probe-proof/`, before review)

Preparation only: this records a probe, not an implementation. Run in a disposable full clone (`~/flywheel-day3-proof`) of the preparation branch. Baseline: `origin/development` at `cf04c03b4`. The seam is byte-identical to `76808a53b`, where the bug was first reproduced.

| State | Commit (proof clone) | Jog lint | Preflight `--dry-run` | Probe |
|---|---|---|---|---|
| 1 Unfixed, prepared commit (local origin) | `07a3d91c0` | 0 | 0 READY | 1 unfixed |
| 2 Simulated fix (`if not dry_run:` before the `:2545` call; proof clone only) | see `probe-proof/2-simulated-fix/state.txt` | 0 | 4 STALE | 0 landed |
| 3 Comment-only edit (proof clone only) | see `probe-proof/3-comment-only-edit/state.txt` | 0 | 0 READY | 1 unfixed |
| 4 Prepared head, GitHub origin (issue fetched) | `42f85a3ec` | 0 | 0 READY | 1 unfixed |

State 4 fetched the live issue: OPEN, acceptance fidelity `unknown / no-issue-section`. That is advisory, since the issue states its fix under "Suggested fix" rather than an Acceptance heading. `ready: true`, gaps lists only that advisory.

Probe (`readiness_probe.py`) behavior: it plants an old, tool-shaped `merge-cleanup-*` folder and three newer ones under a fixture temp root, then calls the real `land_prs([], …)` twice. It exits 0 only when the dry run keeps the folder **and** the executing run removes it. It stubs only the merge policy, the origin URL, the `pgrep` "another run" check and lsof.

Existing suite against the simulated fix: `existing-suites/gh436-merge-cleanup-simulated-fix.txt`.

Files: `probe-proof/<state>/{state.txt,jog-lint-1626.*,preflight-1626.*,probe-1626.*}`, `simulated-fix.patch`, `provenance.jsonl`.
