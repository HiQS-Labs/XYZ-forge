---
gh_issue: 528
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/528
title: "GH-528 — measure and recalibrate the test suite: spike verdict + experimental parallel gate"
status: "Spike complete 2026-08-13 (verdict + cross-model consult recorded on the issue). Phase 1 (experimental --parallel N in validate.sh, 13-suite driver-lock lane serialized) built on feat/gh528-parallel-validate. Promotion to default is gated on Phase 2 stress evidence, deliberately NOT this branch."
created: 2026-08-13
updated: 2026-08-13
owner: noel
doc_type: project
complexity: 2
risk: 2
effort: 2
phases: 3
related:
  - "#509 — tiering of WHEN suites run (docs/fast/full routes, ci-local.sh). This issue is about the suites and the runner itself; coordinate, don't duplicate."
  - "#419 — the observed-red standard every consolidation or interval change must meet. The spike proposed no such change, so no suite needs new evidence."
  - "#42 — the ROOT-HEAD hazard the driver lock exists for; the reason the 13 real-driver suites serialize instead of the lock moving."
  - "#331 — prior live-marathon halt from the same lock-at-harness-root behavior ('--target-root moves the build, not the lock'); the documented per-test remedies."
non_goals:
  - "Cutting or merging any suite. The spike's redundancy map found zero redundant suites; the thrice-repeated red-gate assertion is a load-bearing anti-overcorrection control in each location."
  - "Sleep/interval surgery. Hypothesis falsified: top wall-clock owners contain essentially no sleeps; timeout proofs already inject 1–5s intervals."
  - "Making --parallel the default. That needs Phase 2 promotion evidence (multi-width stress runs), not one green run."
  - "Relocating the driver lock to RELAY_TARGET_ROOT. Real mechanism (relay_drive.py:67,403), but it is a safety behavior with incident history (#331/#376/#448); needs its own issue with #419-standard evidence."
goal: >
  The full local gate is ~16 minutes, sequential. The GH-528 spike measured it (190 shell suites +
  the pytest lane), falsified the sleep hypothesis, found zero redundancy, and proved ~95% of
  wall-clock parallelizes cleanly once the 13 suites that execute the real relay-drive.sh are
  serialized into one lane (they contend on the harness clone's .git/relay-driver.lock, by design).
  Deliver that as an opt-in, explicitly experimental `validate.sh --parallel N` so an operator can
  self-verify in ~3 minutes instead of ~16, without weakening what the sequential default proves.
---

# GH-528 · test-suite recalibration: spike verdict + experimental parallel gate

## Status

| What was just completed | What's next |
|---|---|
| Spike verdict + Codex/agy consult addendum recorded on #528 (2026-08-13). Phase 1 built: `validate.sh --parallel N` pools 177 suites and serializes the 13 real-driver suites in one lock lane; sequential default untouched. A/B on one commit: sequential 946.0s vs `--parallel 8` 184.3s (5.1×), byte-identical pass/fail sets, no lock or worktree leaked; all five Phase 1 QA gates observed (details on the issue). | Phase 2 (separate effort): promotion evidence — repeated multi-width runs, leak/clean-tree checks, pytest+npm steps included — before `--parallel` can be default. Phase 3 (separate issue to file): evaluate driver-lock scope (`relay_drive.py` locking harness root vs effective root). |

## Table of contents

- Phase 1 — experimental `--parallel N` (this branch)
- Phase 2 — promotion evidence (not this branch)
- Phase 3 — driver-lock scope follow-up (separate issue)

## Spike results (measured 2026-08-13, M-series macOS, single run)

- Sequential shell-lane total **950.3s (15.8 min)**, 190 suites. Median 1.4s; 78 suites <1s; the 22 suites ≥10s own 582s (61%). Top: marathon-drive.sh 91.0s, pdda-repo-contract.sh 74.2s, agy-turn.sh 59.4s, consult.sh 38.7s.
- Wait-time hypothesis **falsified**: top-10 owners have ~zero executed sleep; residual literal sleep ~30–60s gate-wide; load-bearing timeout proofs already env-injected (`RELAY_TURN_TIMEOUT_S=1`, `RELAY_TURN_IDLE_S`, `CONSULT_IDLE_S`, `AGY_AUTH_TIMEOUT_S=2`).
- Naive 8-way parallel: 172.9s, 7 failures — all GH-42 driver-lock refusals from suites executing the real `relay-drive.sh` against the harness clone. With those 13 serialized in one 42.7s lane: **167.4s, green** (sole failure `acorn-extract.sh`, which requires the documented `npm install` prerequisite and fails sequentially too without it).
- Redundancy map (full read of the GH-375/385/390/407/419 family + marathon-drive.sh): **zero redundant suites**. Both consult advisors independently confirmed.
- Consult corrections folded in: suite count is 190 (not 186); the pytest lane must be timed before "full gate" claims; the npm/acorn prerequisite is part of the gate, not noise.

## Phase 1 — experimental `--parallel N` (this branch)

`validate.sh --parallel N` runs the same TESTS array with N-way concurrency: the 13 lock-lane suites
(sequentially, one lane, preserving GH-42 exclusion) plus a pool of everything else; the pytest lane
runs after, unchanged. Per-suite output goes to a per-run log dir so failures stay attributable;
exit-code semantics identical to sequential (0 all pass, 1 any fail; failed suites listed). No
argument → sequential path byte-for-byte unchanged.

QA gates (all observed 2026-08-13 on the A/B commit)
- [x] Sequential `./validate.sh` (no args) path unchanged — 946.0s, same pass/fail set as before the patch (its two fails: a genuinely stale ROADMAP-DASHBOARD.md, regenerated after the run and its suite re-run 9/0; the pytest lane missing pytest in the invoking shell — environmental, pre-existing).
- [x] `./validate.sh --parallel 8` on the same commit — 184.3s, pass/fail set byte-identical to sequential.
- [x] The 13 lock-lane suites ran in one sequential background lane; zero driver-lock refusals (vs 7 in the spike's naive 8-way run); no lock or worktree leaked.
- [x] A failing suite fails the parallel run with the suite named + its log tail printed, exit 1 — demonstrated organically by the stale-dashboard failure.
- [x] `--parallel` with missing/zero/non-numeric/extra args and unknown flags all refuse with usage, exit 2 (five cases observed).

## Phase 2 — promotion evidence (deliberately not this branch)

Per the consult bar: repeated runs at several widths (incl. ~N=50 for timing-sensitive suites under
CPU load), cold/warm cache census repeats with median/range, clean-tree check before/after, no leaked
worktrees/processes/locks, pytest + npm setup included. Only after that may `--parallel` become the
default or enter ci-local.sh's full route (coordinate with #509).

## Phase 3 — driver-lock scope (separate issue to file)

`utils/py/relay_drive.py:67,403` locks the harness root regardless of `RELAY_TARGET_ROOT`
("--target-root moves the build, not the lock" — test/gh331-cost-summary.sh). agy's consult position:
fix resolution to the effective root and the lane dissolves. Adjudicated: real mechanism, but it is a
safety behavior with incident history (#331/#376/#448) — needs its own issue and #419-standard
observed-red evidence, not a drive-by here.
