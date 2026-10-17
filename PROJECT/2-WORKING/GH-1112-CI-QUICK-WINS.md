---
gh_issue: 1112
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1112
title: "CI quick wins: marathon-root-audit single pass, heavy-suite ordering, gh648 PermissionError guard"
status: Active
created: 2026-10-17
updated: 2026-10-17
owner: claude
goal: "Cut ~2 minutes from the everyday parallel gate and remove one known flake without new suites or routing changes"
doc_type: fix
effort: 2
complexity: 2
risk: 2
phases: 1
fix_probes:
  - "bash -c 'time bash test/marathon-root-audit.sh >/dev/null' 2>&1 | grep real"
  - "grep -n 'PermissionError' test/gh648-l4-285-revalidate.sh"
---

# GH-1112 — CI quick wins (decided on #1118, 2026-10-17)

## Status

| What was just completed | What's next |
|---|---|
| Intake: clone `XYZ-forge-gh1112-ci-quick-wins-2026-10-17`, branch `fix/…`, base `a984865e` (origin/development after PR #1116) | Plan QA (Codex relay), then implement the three items and measure |

## Problem

The everyday 4-wide parallel gate takes ~14.3 min (858 s, PR #1116 telemetry). Three
bounded, zero-routing-change improvements were decided on #1118 after an independent Agy
relay confirmed them:

1. **QW-2 — `test/marathon-root-audit.sh` (111.5 s → ~4.8 s in the #1112 spike).** The audit
   forks a `$(find_invocation_target "$line")` subshell for every non-comment line of every
   `test/*.sh` (~60k lines) plus `$(get_alias_target …)` inside it. The original spike branch was
   never pushed and its clone is gone; the change is rebuilt here from the recorded spec.
2. **Heavy-suite ordering in `validate.sh`.** Under `xargs -P 4`, `gh436-merge-cleanup.sh`
   (621→841 s), `gh280-jog-marathon-adapter.sh` (632→776 s) and `gh589-xyz-mini-sync.sh`
   (720→738 s) are scheduled late and strand one worker for the final ~100 s. Moving them to the
   front of `TESTS` removes up to ~70 s of tail overhang. One list edit; no scheduler change.
3. **`test/gh648-l4-285-revalidate.sh` PermissionError (#1114 attribution, #1111 408/409).**
   `os.killpg(proc.pid, 0)` and the cleanup `os.killpg(proc.pid, SIGKILL)` catch only
   `ProcessLookupError`; when the group has already been reaped and the pgid reused by a process
   the test may not signal, `PermissionError` escapes and the suite fails. Catch
   `(ProcessLookupError, PermissionError)` at both sites with the same disposition.

## Per-issue requirements

| Issue | Requirement | Acceptance (falsifiable) |
|---|---|---|
| #1112 QW-2 | Audit output byte-identical to the current script on the same tree; wall time ≤ 10 s sequential | `diff <(bash old) <(bash new)` empty, both stdout and stderr; `time` recorded before/after in `TESTS-RESULTS/2026-10-17+GH-1112/` |
| #1112 ordering | The three heavy suites appear first in `TESTS`; registry count unchanged; `gh544-parallel-default.sh` and the registry suites stay green | `validate.sh --print-mode` unchanged; one 4-wide parallel run shows the heavy suites start at t≈0 |
| #1114 gh648 | Guard both `killpg` sites; the suite still fails when a process group genuinely remains | existing suite green; the four previously rescued suites (`gh360-scoped-receipt-chain-rebuild.sh`, `gh484-phase-dir-default.sh`, `gh648-l4-285-revalidate.sh`, `jog-queue.sh`) run concurrently in a disposable clone, 0 failures; red control: a deliberate still-alive group still raises `process group remains` |

## Non-goals

QW-1 (`utils/ci-route.sh` router batching) stays parked. No new suites, registry entries, gate
flags or scheduler logic (GH-831). No change to the sequential qualifying form. No #1114
receipt-contract work (separate task).

## Smallest surface

- `test/marathon-root-audit.sh`: `find_invocation_target` and `get_alias_target` return through a
  variable instead of `printf` + `$(…)`; the per-line call site reads that variable. A cheap
  pre-gate skips lines that contain none of the driver tokens before any regex work. Nothing
  else in the audit's rules changes.
- `validate.sh`: move three entries within `TESTS` (comments travel with them).
- `test/gh648-l4-285-revalidate.sh`: two `except` tuples.

## Risks and rollback

Each item is an independent one-file change; revert individually. The audit rewrite's only risk
is a semantic drift, which the byte-identical diff detects. Ordering has no correctness
surface. The gh648 guard could mask a real leak only if `PermissionError` were the signal of
a live group; the existing `deadline` branch still raises `process group remains` for that.

## Ratings (RELEASES, dated 2026-10-17)

- #1112: `rated 70/40/50/85` — pri: decided on #1118 as the targeted CI win; sev: no user
  harm, developer time only; appeal neutral; effort: three small one-file edits.
- #1114 (gh648 item only): `rated 65/55/50/90` — sev: a flake that fails the full gate
  (408/409 observed on #1111); effort: two-line guard.

## Evidence

`TESTS-RESULTS/2026-10-17+GH-1112/` with `provenance.jsonl`: audit before/after timing and
output diff; concurrent rescued-suite run; one 4-wide parallel `validate.sh` run with telemetry.
