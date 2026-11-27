# GH-792 preparation evidence (2026-11-27)

Preparation only: this records a probe, not an implementation. Run in a disposable full clone (`~/flywheel-day3-proof`) of the preparation branch. Baseline: `origin/development` at `cf04c03b4`. `utils/py/gen4_campaign.py` is identical to `76808a53b`.

| State | Commit (proof clone) | Jog lint | Preflight `--dry-run` | Probe |
|---|---|---|---|---|
| 1 Unfixed, prepared commit (local origin, issue not fetched) | `07a3d91c0` | 0 | 0 READY | 1 unfixed |
| 1b Same commit, GitHub origin (issue fetched) | `07a3d91c0` | — | **5 NOT-READY** (`diverged`) | — |
| 2 Simulated fix (disjoint check before makedirs/rmtree/clone; proof clone only) | see `probe-proof/2-simulated-fix/state.txt` | 0 | 4 STALE | 0 landed |
| 3 Comment-only edit (proof clone only) | see `probe-proof/3-comment-only-edit/state.txt` | 0 | 0 READY | 1 unfixed |
| 4 Prepared head after declaring deviations, GitHub origin | `42f85a3ec` | 0 | 0 READY, fidelity `match` | 1 unfixed |

State 1b was a real preparation defect, found and fixed before review. The issue's `## Acceptance` uses plain `- ` bullets, and Preflight parses only checkbox bullets. So it read the issue's list as empty and the verbatim copy as three undeclared additions. The capture now declares them `[added]` with the wording unchanged. The parser gap is filed as #1646. Files: `probe-proof/1-unfixed-at-prepared-commit/preflight-792.github-origin.*`.

Probe (`readiness_probe.py`) behavior: it builds a real fixture repo at `<base>/clone` and calls `make_sandbox(<base>/clone, <base>)`, recording `os.makedirs` / `shutil.rmtree` / `subprocess.run` calls and passing each one through. It exits 0 only when that call raises `RuntimeError` with zero such calls and an intact source, a disjoint call still clones, and the `:348` descendant shape still refuses. Today the fixture source is deleted, then `git clone` fails with exit 128.

Existing suite against the simulated fix: `existing-suites/gh-gen4-phase5-campaign-simulated-fix.txt`.
