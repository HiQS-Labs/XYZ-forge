# GH-487 — bounded gates for new-branch skill/test pushes: evidence summary

Branch `fix/gh487-bounded-gates`, final commit `7011669f` (base `origin/development@eb26fb74`).
All runs executed in a **separate disposable full clone** (`XYZ-forge-gh487-work`); clone identity
(`core.bare`, `origin`, user email, HEAD) verified before and after every gate run per GH-567.
Plan of record: [issue #487 comment #3, Rev. 2](https://github.com/HiQS-Labs/XYZ-forge/issues/487#issuecomment-5575660146).

## Measured timings (same machine, same default parallel width)

| Scenario | Before (incident) | After | Where |
|---|---|---|---|
| First push of a registered skill + its dedicated tests | 698 s full gate (issue body) | **27.4 s** tier-2 gate, 4/4 green | `./validate.sh --paths-file` on the incident path set |
| Receipt-only follow-up push (issue comment 2) | 698 s full gate | **36.3 s** docs gate, no errors | `pdda.sh run` |
| Broad change (kernel/gate/unmapped) | full gate | **641–601 s** full gate, unchanged by design | two full-gate runs below |

## Full-gate runs

| Run | HEAD | Result | Notes |
|---|---|---|---|
| 1 | `f956d91b` (pre-doc-fix) | 351/353, 10:41 | two real failures (`pdda-repo-contract.sh`, `sentinel-overlay.sh`), one root cause: capture doc carried RELEASES-style ratings in PDDA frontmatter (needs 1–5 integers). Fixed in `7011669f`; both suites re-run green alone. Zero contended suites. |
| 2 | `7011669f` (final) | **353/353 GREEN**, 10:01, rc=0 | one pool flake: `registry-lock-concurrency.sh`, passed its serial re-run (GH-528 contended classification). `gh365` and `gh376`: zero flakes in both runs. |

## Contention observations (item 4 of the issue, evidence-first)

- Two fresh-clone full-gate runs on this machine: 1 flaked suite in 2 runs
  (`registry-lock-concurrency.sh`, 1/2) — no shared relay-driver-lock resource involved, despite
  the GH-528 warning text claiming "almost always THIS CLONE's `.git/relay-driver.lock`". That
  text is misleading for every suite observed so far (reviewer's five runs + these two) and is
  recorded as a separate out-of-scope defect.
- No `DRIVER_LOCK_LANE` change is made: no observed flake has a *proven* shared resource.
- `gh57-releases-fuzz.sh` rc=2 masking (review finding): not reproduced in these two runs; the
  GH-528 any-non-zero retry semantics remain an out-of-scope observation.

## Contract-suite evidence (red before green, per the plan's falsifier table)

| Suite | Red witnessed | Green |
|---|---|---|
| `test/ci-route.sh` | `bb94f2bd` run: 5 new cases red | 56 pass / 0 fail @ `415a9505` |
| `test/gh544-pre-push-gate.sh` | `7a09d823` run: 5 reds incl. both new behaviors | 96 pass / 0 fail @ `f956d91b` |
| `test/gh35-test-tiers.sh` (drift guard) | — (guard auto-covers the registry) | 71 / 0 |
| `test/gh365-tier-fail-closed.sh` | — | 5 / 0 |
| `test/gh365-validate-telemetry.sh` | `RT_SHARD=1`: rc=1, 345 bytes, FAIL A2 | `RT_SHARD=1` 16/0 and clean 16/0 |

Detailed per-run records: `provenance.jsonl` beside this file.
