---
title: GH-1111 CI audit process-overhead experiment
status: in-progress
created: 2026-10-16
updated: 2026-10-16
owner: Codex
goal: Measure low-risk process-overhead reductions without reducing the test set
---

# GH-1111 — CI audit overhead spike

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1111
Author: Codex / GPT-6 family / exact model and effort unavailable.

## Status

| What was just completed | What's next |
|---|---|
| Fresh remote full clone, clean development base 2454a781, source trace and bounded scope | Freeze baseline, implement builtin parsing and per-run registry reuse, measure A/B/B/A |

## Recon Map

Graph project XYZ-forge, generation 2026-09-01T15:54:30Z is stale. Coverage for audit/router/setup is unavailable/changed; source read in full replaces graph assumptions.

`validate.sh` registers `gh365-tier-fail-closed.sh`; its T1 enumerates every tracked path and invokes the real `utils/ci-route.sh push` once per path. `classify()` parses three fields through nine external text commands. T2 calls `registered_anywhere()` per family-named suite; each call reruns the same registry listing. The registry is static during a single suite invocation; no step changes router/registry files. T3 repeats classification and registry checks for deliberate planted controls. `test/_setup.sh` provides fixture containment and fail-fast assertions.

Changes stay in one existing test file. No classifier, wrapper, workflow, suite membership, external dependency, telemetry schema or production behavior changes. A failed registry listing must still fail the audit. Bash 3.2 compatibility is required. The parallel runner/qualification policy remains untouched. The maintained task clone is never a test CWD.

## Bet and risks

Easy rollback: drop the candidate test-only commit. The bet is that fork overhead is material. Risks are parsing a wrong key/value or inadvertently ignoring failed registry extraction; validate exact field equality against real outputs and witness both planted controls and deliberately broken inputs. A/B sample size is intentionally small; host-local timing is not a hosted guarantee.

PRS proposal: priority 65 / severity 30 / appeal 50 neutral / cheapness 85. User explicitly requests quick wins; urgency reflects cumulative hour-long feedback cost, not a correctness incident. Recurrence: #835 and #1110 independently identify expensive suites; no claim of increasing incident frequency.

## Ordered experiment

1. Register/rate intake; freeze a baseline commit with the final tracked-file inventory. -> expect base/candidate path sets identical.
2. Implement only fork-free key parsing, cached subsystem-list read, and basename expansion where already reading a path basename. -> expect same per-path inputs and assertion labels. This is a local, obvious suite optimization; preimplementation relay is skipped as a simple change. Final independent Agy QA is required by the request.
3. In separate disposable full clones, run base/candidate/candidate/base without overlapping benchmarks; capture monotonic elapsed time, exact stdout, return code, Git HEAD/config/status before and after, host/platform/shell and environment overrides. -> expect each green and identical assertion output/path counts.
4. Differential-check parser outputs for actual classifier values and failed extraction; execute existing controls and deliberately corrupt the router/registry in disposable clones. Restore only saved file bytes. -> expect a real red verdict, not an empty green result.
5. Run existing affected routing suites and one final full classified gate in disposable isolation. -> retain failures/retries and identity drift honestly. Full-suite timing is a single candidate observation, not an A/B speedup estimate.
6. Commit structured results/provenance and report to GH-1111, then drive relay-xyz with Agy on the diff, methodology, evidence and exact report. -> retain verdict/dispositions; no merge or production rollout.

## Acceptance

No lost path checks, assertions, registry members, tests or negative controls; identical A/B verdicts and output; witnessed red controls; focused and final gate results reported without hiding retries. Publish measured savings and limitations even if the candidate has no useful speedup. No new suites, registry entries, gates, frameworks or scheduled jobs.

## Unknowns

Measured size of the speedup; host variability; whole-gate regressions; hosted applicability. The experiment measures the first two locally, checks the third once, and leaves hosted applicability explicitly unproven.
