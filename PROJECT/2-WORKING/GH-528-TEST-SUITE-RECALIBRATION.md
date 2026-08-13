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
- [x] Discoverable: `ROUTER.md`'s command rail carries both forms, with the sequential run named as the
      only one that qualifies a claim and `--parallel` labelled experimental and cost-motivated.
- [x] A pooled failure is re-run alone before it is believed, and a suite that passes alone is counted
      passed **and** named as a lane-list gap — `test/gh528-parallel-contention-retry.sh` 4/0, with the
      pre-fix mutation red on 3 of 4. Added after the first reuse produced a false red (see below).

## Why this landed now: the Actions bill (measured 2026-08-13)

Pulled from `gh api orgs/Claude-AI-Tools-Ventura-County/settings/billing/usage` (the per-run billable
timing API reports 0min for this org and is unusable). August 2026, **net $9.09 of a $10 budget**:
Ubuntu 2,740 min → $16.44 gross, −$12.00 for the 2,000 included minutes, **$4.44 net**; macOS 3-core
75 min → **$4.65 net, no discount**. July was 1,586 Linux minutes entirely inside quota, $0.

Two facts this issue inherits from that: 75 macOS minutes cost as much as 2,740 Linux minutes (~10×
rate, no included-quota discount on a private repo — each `boundary-macos` dispatch ≈ $1.25–1.50),
and the Linux side is over quota on *volume*, since every push to `development` and every PR into
`development`/`main` starts a run. Feature-branch pushes with no open PR cost $0.

**Update, same day (PR #532):** the macOS half was closed at the source — `boundary-macos` lost its
`workflow_dispatch` trigger and now fires on push-to-`main` only, so hosted macOS spend goes to
roughly zero. That *raises* this issue's relevance rather than lowering it: the pre-merge macOS
witness is now unserved, and the local gate is what replaces it. A substitute that takes 16 minutes
gets skipped; one that takes 3 gets used.

That is the practical case for `--parallel N` beyond operator patience: the local gate is the
substitute for a hosted run, and at 184s instead of 946s it is cheap enough to actually be used that
way. Recorded on #509, which owns the CI-spend problem; this issue owns only the runner.

## The first reuse found a defect the A/B could not (2026-08-13, same day)

Merging `origin/development` into this branch and re-running `--parallel 8` produced **one failure
the sequential gate does not have**: `gh322-unknown-arg-rejection.sh`, reporting
`exit codes diverge — Python 2, Bash 1`.

It was not a flake and not a product bug. `relay-drive.sh` acquires the driver lock at line ~142,
**before `usage()` and before it parses any argument**. That suite never drives anything — it passes
a bogus flag and asserts both twins exit 2 — but under contention the Bash twin exits 1 (lock
refusal) while the Python twin, which parses first, still exits 2. Reproduced deterministically by
holding the lock with a live pid: identical failure, and green the moment the lock is released.

**So the lane rule was wrong, not just the list.** Membership is not "suites that drive" — it is
**suites that invoke a driver at all**. The spike derived the original 13 from observed lock
refusals in the naive parallel run, and a suite whose contention shows up as a *parity assertion*
rather than a *refusal message* was invisible to that method.

Two things changed, because fixing only the list would leave the same trap armed for the next suite:

1. `gh322-unknown-arg-rejection.sh` joins the lane (13 → 14).
2. **Any pooled failure is now re-run alone**, with the lane finished and the lock free, before it is
   believed. Fails alone too → real failure, reported with the serial log. Passes alone → counted
   **passed** (sequential is the source of truth, and returning sequential's answer is the flag's
   entire promise) and **named in a warning** identifying it as a lane-list gap to fix. An incomplete
   list can no longer produce a false red, and can no longer be silent either.

A third defect surfaced while proving this: the lane iterated the literal `DRIVER_LOCK_LANE` string
instead of intersecting it with `TESTS`, so lane suites ran even when `TESTS` did not contain them —
`--parallel` executed suites the sequential path skipped, and the summary printed `passed: 16 / 3`.
Now both lists are derived from `TESTS`.

`test/gh528-parallel-contention-retry.sh` pins all of it (4 assertions, registered in `validate.sh`).
Its control is a mutation: with the re-run block deleted — the state this branch shipped in its first
build — 3 of the 4 assertions fail, and the probe is reported as a failed suite exactly as `gh322`
was. **The honest read of this is that the flag's original A/B was not sufficient evidence**: one
green parallel run on one commit could not distinguish "correct" from "did not happen to collide
this time". That is precisely the gap Phase 2 exists to close, and it argues for that bar, not
against it.

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
