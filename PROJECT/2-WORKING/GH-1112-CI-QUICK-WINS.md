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
  - "bash -c 's=$(date +%s); bash test/marathon-root-audit.sh >/dev/null 2>&1; rc=$?; e=$(( $(date +%s) - s )); [ $rc -eq 0 ] && [ $e -le 10 ]'"
  - "grep -c 'except (ProcessLookupError, PermissionError)' test/gh648-l4-285-revalidate.sh | grep -qx 2"
---

# GH-1112 — CI quick wins (decided on #1118, 2026-10-17)

## Status

| What was just completed | What's next |
|---|---|
| Plan QA Approved (round 3); three edits implemented and committed; audit 78.9 s → 8.8 s with identical stdout/stderr/rc; gh273 20/20; --list multiset identical, heavy suites first | Verify clone: gh648 suite + no-op/EPERM/ESRCH controls, four rescued suites concurrently, one 4-wide parallel validate.sh run; final Codex QA; PR |

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
3. **`test/gh648-l4-285-revalidate.sh` PermissionError (authorized by #1118 "pre-measurement
   hygiene"; observed as #1111's 408/409; associated with #1114 only as the parallel-contention
   track, not its original subject).** `os.killpg(proc.pid, 0)` (L148) and the cleanup
   `os.killpg(proc.pid, SIGKILL)` (L159) catch only `ProcessLookupError`. `PermissionError`
   (EPERM) from `killpg` means a process group with that id exists but this uid may not signal
   it. Every descendant this fixture launches shares the test's uid, so a group it cannot signal
   is not the fixture's group; the most likely cause is pgid reuse after reaping, which is a
   hypothesis, not something the observation proves. **Policy:** at the observation site EPERM is
   recorded as `group_absent: "eperm-unsignalable"` and treated as absent (the fixture's own group
   is gone or never existed as such); at the cleanup site EPERM is ignored like
   `ProcessLookupError` so a cleanup error cannot mask the verdict. The `deadline` branch is
   reached only when `killpg(pid, 0)` keeps returning normally (a signalable, still-present
   group); it does not run for EPERM, which the policy above accepts immediately.

## Per-issue requirements

| Issue | Requirement | Acceptance (falsifiable) |
|---|---|---|
| #1112 QW-2 | Audit stdout, stderr and exit status identical to the current script on the same tree, with non-empty stdout; wall time ≤ 10 s sequential (rc must be 0 for the timing to count) | Green parity: old/new run separately with stdout, stderr and rc captured to files; `cmp` both streams, rc equal, stdout non-empty. Red parity: in a disposable clone, temporarily append 41 comment lines (to clear the audit's 40-line lookback, L330-336) followed by an unscoped `python3 utils/py/marathon_drive.py --dry-run` line to an existing `test/gh*.sh`, run old and new: both rc=1, matching non-empty `FAIL:` stderr naming exactly that planted path:line; revert. Existing covering suite `test/gh273-marathon-root-audit-python-shape.sh` (alias/flag/version/unscoped cases) must keep every verdict. All recorded under `TESTS-RESULTS/2026-10-17+GH-1112/` |
| #1112 ordering | The three heavy suites appear first in `TESTS`; suite set and count unchanged; same sequential runner (sequential and `--list` order change accordingly, Tier-2 order comes from `T2_TESTS` and is untouched); `gh544-parallel-default.sh` stays green | `validate.sh --print-mode` unchanged; `--list` exact multiset-equal before/after (a dropped or duplicated entry fails); one 4-wide parallel run's telemetry shows the three suites dispatched in the first wave; red control: the old order fails the same first-wave check on PR #1116's retained telemetry |
| #1114 gh648 (partial hygiene item per #1118; #1114 stays open) | Guard both `killpg` sites under the documented EPERM policy; the suite still fails when a signalable group remains | existing suite green; the four previously rescued suites (`gh360-scoped-receipt-chain-rebuild.sh`, `gh484-phase-dir-default.sh`, `gh648-l4-285-revalidate.sh`, `jog-queue.sh`) run concurrently in a disposable clone, 0 failures; red control that reaches the group oracle: in a disposable copy, replace only the observation `os.killpg(proc.pid, 0)` with a no-op (`pass`) so the probe keeps "succeeding" — the suite must fail specifically with `process group remains` (the existing L171-178 mutant stops at `cap containment` and does not reach this oracle); manual controls: injected `ProcessLookupError` keeps `group_absent: True`; injected `PermissionError` records `eperm-unsignalable` at observation and leaves the verdict unchanged at cleanup |

## Non-goals

QW-1 (`utils/ci-route.sh` router batching) stays parked. No new suites, registry entries, gate
flags or scheduler logic (GH-831). No change to the sequential qualifying form. No #1114
receipt-contract work (separate task).

## Smallest surface

- `test/marathon-root-audit.sh`: `find_invocation_target` and `get_alias_target` return through a
  variable instead of `printf` + `$(…)`; the per-line call site reads that variable. A cheap
  Three substring pre-gates, each provably unable to exclude a line or file the regexes could
  match; the regexes still decide: (a) invocation detection examines a line only if it contains
  `marathon` or `relay` (every direct branch: vendored literals, marathon_drive.py,
  marathon-drive.sh, marathon.sh, relay_drive.py, relay-drive.sh, relay-automation/…), or `$`
  together with `python` or `sh` (every alias branch: alias variable plus bash/zsh/sh/dash or
  python); (b) `discover_file_metadata` examines a line only if it starts with an uppercase
  identifier followed by `=` (all three registrations anchor on `^VAR=`); (c) a file is audited
  only if `grep -q -E 'marathon|relay'` finds either substring anywhere (a direct invocation line
  contains one; an alias invocation needs an alias registered from a line containing one), 139 of
  414 files today. Measured here: 78.9 s → 13.5 s with (a) alone, 8.8 s with all three.
- `validate.sh`: move three entries within `TESTS` (comments travel with them).
- `test/gh648-l4-285-revalidate.sh`: two `except` tuples.

## Risks and rollback

Each item is an independent one-file change; revert individually. The audit rewrite's only risk
is a semantic drift, which the byte-identical diff detects. Ordering has no correctness
surface. The gh648 guard accepts EPERM as "not the fixture's group" by the same-uid argument; a
group that remains signalable still fails at the `deadline` with `process group remains`, and
the no-op-observation red control above proves that branch is still reachable after the edit.

## Ratings (RELEASES, dated 2026-10-17)

- #1112: `rated 70/40/50/85` — pri: decided on #1118 as the targeted CI win; sev: no user
  harm, developer time only; appeal neutral; effort: three small one-file edits.
- #1114 (gh648 item only; cross-track association, authorized by #1118): `rated 65/55/50/90` —
  sev: a flake that fails the full gate (408/409 observed on #1111); effort: two `except`
  tuples plus one recorded field. #1114's own subject (bookkeeping re-trigger) is untouched here.

## Evidence

`TESTS-RESULTS/2026-10-17+GH-1112/` with `provenance.jsonl`: audit before/after timing and
output diff; concurrent rescued-suite run; one 4-wide parallel `validate.sh` run with telemetry.
