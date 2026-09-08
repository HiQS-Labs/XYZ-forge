# GH-487 — bounded gates for new-branch skill/test pushes: evidence summary

Branch `fix/gh487-bounded-gates`; **code-final commit `5ca805fe`** (base `origin/development@eb26fb74`);
commits after it are receipt/docs-only and are enumerated at the bottom. All gate runs executed in a
**separate disposable full clone** (`XYZ-forge-gh487-work`); clone identity (`core.bare`, `origin`,
user email, HEAD) verified before and after every gate run per GH-567. Plan of record:
[issue #487 comment #3, Rev. 3](https://github.com/HiQS-Labs/XYZ-forge/issues/487#issuecomment-5575660146).

## Review rounds and dispositions

| Round | Reviewer | Verdict | Dispositions |
|---|---|---|---|
| Plan | Claude Opus (issue comment 4) | Approve with item 4 re-aimed | All four points applied; Rev. 2 of the plan. |
| Implementation (final QA, relay) | Codex, round 3 | **Changes requested** — 1 narrow hole | Accepted: the ls-remote probe's exit status was discarded, so a nonzero probe with partial output could pass freshness; exit status is now authoritative (nonzero → full gate with named reason). Red control (PATH-stubbed git: partial ref then exit 1) witnessed red, then 100/0 green. |
| Implementation (final QA, relay) | Codex, round 1 | **Changes requested** — 2 blocking | (1) stale-base safety after a backward integration-branch rewrite: **accepted** — freshness now verified against the live remote (`git ls-remote` equality between tracking ref and advertised tip), ambiguous `merge-base --all` fails closed, three red controls added and witnessed; (2) receipt attested an earlier SHA than the reviewed head: **accepted** — every run is now labeled with its exact SHA and the attestation chain to the pushed head is explicit below. |

## Measured timings (same machine, same default parallel width)

| Scenario | Before (incident) | After | Where |
|---|---|---|---|
| First push of a registered skill + its dedicated tests | 698 s full gate (issue body) | **27.4 s** tier-2 gate, 4/4 green (measured at `7011669f`; classifier/hook code identical through `5ca805fe` — later commits are docs/receipt-only) | `./validate.sh --paths-file` on the incident path set |
| Receipt-only follow-up push (issue comment 2) | 698 s full gate | **36.3 s** docs gate, no errors (same SHA caveat) | `pdda.sh run` |
| Broad change (kernel/gate/unmapped) | full gate | **601–641 s** full gate, unchanged by design | three full-gate runs below |

## Full-gate runs

| Run | HEAD | Result | Notes |
|---|---|---|---|
| 1 | `f956d91b` (pre-doc-fix) | 351/353, 10:41 | two real failures (`pdda-repo-contract.sh`, `sentinel-overlay.sh`), one root cause: capture doc carried RELEASES-style ratings in PDDA frontmatter (needs 1–5 integers). Fixed in `7011669f`; both suites re-run green alone. Zero contended suites. |
| 2 | `7011669f` | **353/353 GREEN**, 10:01, rc=0 | one pool flake: `registry-lock-concurrency.sh`, passed serial re-run (GH-528 contended classification; unrelated to the relay driver lock despite the run's warning text). `gh365`/`gh376`: zero flakes. |
| 3 | `5ca805fe` (code-final, incl. review-round-1 freshness fix) | **353/353 GREEN**, 10:02, rc=0 | zero contended suites. **This is the attestation for the reviewed code.** |
| boundary | pushed head (see PR #488 description) | pre-push full gate, recorded per push | the hook re-runs the full suite at the push boundary; the result at the pushed head is quoted in the PR description and the issue thread. |

## Contention observations (item 4 of the issue, evidence-first)

- Three fresh-clone full-gate runs on this machine: 1 flaked suite in 3 runs
  (`registry-lock-concurrency.sh`, run 2) — no shared relay-driver-lock resource involved, despite
  the GH-528 warning text claiming "almost always THIS CLONE's `.git/relay-driver.lock`". That
  text is misleading for every suite observed so far (reviewer's five runs + these three) and is
  recorded as a separate out-of-scope defect.
- No `DRIVER_LOCK_LANE` change is made: no observed flake has a *proven* shared resource.
- `gh57-releases-fuzz.sh` rc=2 masking (review finding): not reproduced in these runs; the
  GH-528 any-non-zero retry semantics remain an out-of-scope observation.

## Contract-suite evidence (red before green, per the plan's falsifier table)

| Suite | Red witnessed | Green |
|---|---|---|
| `test/ci-route.sh` | `bb94f2bd` run: 5 new cases red | 56 pass / 0 fail @ `415a9505` |
| `test/gh544-pre-push-gate.sh` (round 0) | `7a09d823` run: 5 reds incl. both new behaviors | 96 pass / 0 fail @ `f956d91b` |
| `test/gh544-pre-push-gate.sh` (round 1: backward rewrite, stale-behind, ambiguous base) | fixtures `5ca805fe` + hook `6beeeb43`: 3 reds | 99 pass / 0 fail @ `5ca805fe` |
| `test/gh35-test-tiers.sh` (drift guard) | — (guard auto-covers the registry) | 71 / 0 |
| `test/gh365-tier-fail-closed.sh` | — | 5 / 0 |
| `test/gh365-validate-telemetry.sh` | `RT_SHARD=1`: rc=1, 345 bytes, FAIL A2 | `RT_SHARD=1` 16/0 and clean 16/0 |

## Commit chain after the code-final gate (all docs/receipt-only)

`7011669f` capture-doc rating fix → `b101519b` draft-bypass docs + CHANGELOG → `24f724bb` first
receipt → round-1 test/fix commits `6beeeb43`, `0776b01c`, `5ca805fe` (code) → receipt/docs commits
up to the pushed head (each visible in the branch history; the boundary gate runs on the pushed head).

Detailed per-run records: `provenance.jsonl` beside this file.
