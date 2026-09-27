---
gh_issue: 800
source: https://github.com/HiQS-Labs/XYZ-forge/issues/800
title: "Benchmark full local CI suite across three Apple devices"
status: In progress
created: 2026-09-24
updated: 2026-09-25
owner: unassigned
effort: 3
complexity: 2
risk: 1
phases: 3
doc_type: feedback
goal: Measure and compare matched-commit full-suite gate time on three Apple devices with retained, public-safe evidence.
---

# GH-800 — Cross-device full-suite benchmark

## Status

| What was just completed | What's next |
|---|---|
| M4 Pro: three trials at proposed repin `0ae3452a` — 912 s and 910 s green, 964 s refused (intermittent `gh496-telemetry-isolation` SQLite lock race). The M6 trial (1,083 s, 416/420 at `a08f30e9`) is not matched to them. | Run the M6 and M1 Max at `0ae3452a`, then compare medians. |

## Table of contents

- [Phase 1 — M6 baseline](#phase-1--m6-baseline)
- [Phase 2 — Matched device trials](#phase-2--matched-device-trials)
- [Phase 3 — Comparison](#phase-3--comparison)

## Scope

Run `./validate.sh` in a disposable full clone at one pinned `development` commit on the Mac mini M6, MacBook Pro 14-inch M4 Pro, and Mac Studio M1 Max. Record selected width, full-suite verdict, wall time, retries, and per-suite timings. Compare medians and ranges after at least three uncontended trials per device when practical. Keep machine identifiers and operator paths out of public artifacts.

## Relationship

Issue #732 owns gate timing presentation and optimization. This issue measures devices; it does not alter gate behavior.

## Plan

1. Pin the same commit and verify dependencies on each device; expect identical SHA and import success.
2. In a separate full clone per device, record identity before/after and run the default full `./validate.sh` without concurrent gates; expect a complete verdict and unchanged identity.
3. Retain per-run timings, public-safe metadata, sanitized log excerpts and `provenance.jsonl`; expect nonempty evidence and no device identifiers or local paths.
4. Repeat to at least three uncontended trials per device when practical, compare medians and ranges, and mark mismatched or failed runs separately.

## Risk and rollback

Easy: measurement only; no runtime behavior changes. Stop an invalid run and keep its failed receipt. Correct erroneous public claims with an issue update and evidence follow-up.

## Phase 1 — M6 baseline

Recorded one complete M6 run and its selected width, toolchain and refused verdict. The earlier setup attempt is excluded from timing comparison but retained as an incomplete attempt. See `TESTS-RESULTS/2026-09-25+GH-800/` for public-safe provenance and per-suite timings. Four failures survived isolated retries; the campaign does not classify them as device-specific.

**QA:** Nonempty full-suite verdict, elapsed time, matching SHA and unchanged clone identity; public-safe provenance.

## Phase 2 — Matched device trials

Run the M4 Pro and M1 Max on the same SHA and command; repeat uncontended trials to reach at least three per device when practical.

M4 Pro recorded three uncontended trials at `0ae3452a` (proposed repin after #801 and #794 fixed the four M6 failures): 912 s and 910 s green, and 964 s refused on an intermittent `gh496-telemetry-isolation.sh` SQLite `database is locked` race (reproduced 1/30 standalone). See `TESTS-RESULTS/2026-09-25+GH-800/SUMMARY.md`. The M6 and M1 Max still need trials at the same SHA.

**QA:** Every trial has a complete verdict and environment record; mismatched SHAs are excluded from matched comparison.

## Phase 3 — Comparison

Compute medians and ranges from completed matched trials, separate refused runs and retry cost, and link any newly discovered optimization to a separate issue.

**QA:** Recomputable timings and no public machine identifiers or absolute home paths.
