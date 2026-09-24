---
gh_issue: 773
source: https://github.com/HiQS-Labs/XYZ-forge/issues/773
title: "marathon_drive: gate memory guard silently disables when ps is denied, logs peak 0MB"
status: Complete
created: 2026-09-23
updated: 2026-09-24
owner: noelsaw1
doc_type: bugfix
complexity: 2
risk: 1
effort: 2
phases: 1
rating: "pri/sev/appeal/effort 55/60/50/80 · calc 245"
non_goals:
  - Publishing RSS peak or measurement quality in the marathon-drive/result@1 receipt (versioned contract change; follow-up issue).
  - A fail-closed mode or env flag (rejected in AgentChorus #507818).
  - Fallback memory probes (getrusage, /proc, ps -p).
  - GH-772 page size, GH-769 refactor, F20 poll cost.
related:
  - PROJECT/1-INBOX/GH-769-MARATHON-DRIVE-AUDIT.md (finding F19)
  - https://github.com/HiQS-Labs/XYZ-forge/issues/773#issuecomment-5806416746 (design decision)
  - test/gh390-gate-guard.sh
goal: >
  When the gate's RSS watchdog cannot read process-group memory, the gate keeps running under its
  wall-clock and CPU caps, logs one explicit warning, and the summary reports the peak as unknown —
  never as 0MB. A test proves both, with a red control.
---

# marathon_drive: gate memory guard silently disables when ps is denied, logs peak 0MB

## Status

| What was just completed | What's next |
|---|---|
| Plan and final QA approved by Codex. Fix and tests implemented; qualifying gate run once; PR opened against `development`. | Merge, then hosted reconcile. |

## Bug

The gate's memory guard in `utils/py/marathon_drive.py` switches itself off without any message when `ps` is not permitted (reproduced in the Claude Code sandbox). The run log then reports a peak of `0MB`, which reads as a real measurement.

## Rating rationale (2026-09-24)

- **sev 60:** the RSS poll is the only macOS memory layer; GH-382 kernel-panicked the host twice when a gate ran away. With `ps` denied that layer is silently off. Wall and CPU caps still bound the run, so the consequence is a weakened guard with false telemetry, not an active crash.
- **pri 55:** severity-led; no deadline from the operator. Agents routinely run marathons from sandboxed sessions, which is the trigger condition.
- **appeal 50:** neutral (no operator preference given).
- **effort 80:** one helper, one loop/log change, one existing test file.
- **Recurrence (14 days to 2026-09-24 vs the prior 14):** one report of this defect (#773 from the #769 audit); same-area telemetry defect #772 filed the same day. Committed evidence logs show unmeasured `peak group RSS 0MB` lines (`evidence/marathons/run-1/04-fullrun.log:987`). Trend: unknown; no prior incidents recorded for this exact failure.

## Why

The gate's RSS poll is the only memory protection on macOS (`utils/py/marathon_drive.py:859-862`, `:2303-2306`). GH-382 kernel-panicked the host twice from a runaway gate. When `ps` cannot run, that protection switches off silently and the run log prints `peak group RSS 0MB`, which reads as a real measurement. Operators and later telemetry cannot tell "used no memory" from "was not watched".

## Recon (base: `origin/development` after PR #776 lands)

- **Entry point:** `run_pre_advance_gate()` inside `main()` → guarded branch → poll loop `utils/py/marathon_drive.py:2352-2372` → summary `log(...)` `:2399-2403`. Unguarded branch (`MARATHON_GATE_GUARD=0`, `:2315`) never samples RSS and is unaffected.
- **Helper:** `_gate_group_rss_mb(pgid)` `:899-916` returns `-1` on `OSError`/`SubprocessError`, otherwise the summed RSS of rows whose pgid matches (0 when none match; `ps` return code ignored).
- **Observed failure shape:** in the Claude Code sandbox `subprocess.run(["ps", ...])` raises `PermissionError` (errno 1) → `-1` → `peak = max(0, -1) = 0`, `-1 >= cap` never true. Confirmed 2026-09-24.
- **Second silent case found in recon:** a gate that exits before the first sample also reports `peak group RSS 0MB` (the loop checks `proc.poll()` before sampling). Seen in committed evidence, e.g. `evidence/marathons/run-1/04-fullrun.log:987` (`gate exit 0 after 1s — peak group RSS 0MB`). Same lie, same fix: no readable sample means unknown.
- **State writes:** log lines only. `_RESULT` gets `gate_result`/`gate_exit`; the `@1` terminal receipt serializes an explicit allowlist (`:237-272`) pinned by `test/gh291-contract-goldens.sh:233-237`. No RSS value reaches the receipt.
- **Consumers of the log format:** only `test/gh390-gate-guard.sh:173` (substring `peak group RSS`). Other matches are historical evidence logs and docs. No parser.
- **Bash twin:** `relay-automation/marathon-drive.sh` has no RSS guard (0 matches); frozen under GH-308. No parity change.
- **Tests:** `test/gh390-gate-guard.sh` owns the guard (driven cases + a direct-import seam for `gate_guard_cpu_attribution`); `test/gh457-gate-tiers.sh` owns tier caps.
- **Design decided in** AgentChorus #507818 (Codex, Antigravity, Claude) and recorded on the issue.

## Plan

Extends the existing guard in place. No new module, no new writer, no schema change.

1. **Helper** `_gate_group_rss_mb(pgid)` → returns `(mb, status)`:
   - `(mb, None)` when at least one row matched the pgid (0 is legitimate);
   - `(None, "ps-failed")` on OSError/SubprocessError, nonzero return code, or blank stdout;
   - `(None, "group-missing")` when rows came back but none matched.
2. **Poll loop:** track `readable_samples`, `unreadable_samples`, `peak_rss_mb`, `warned`.
   - `group-missing` → re-poll the child; if it has exited, take its code and leave the loop (not unreadable). If alive → unreadable.
   - `ps-failed` → unreadable, always.
   - On unreadable: skip only the RSS cap check; wall/CPU checks unchanged. First time only, log
     `gate-guard: WARNING: RSS watchdog unavailable — cannot read process-group memory; continuing without RSS enforcement`.
3. **Summary fragment** (replaces `peak group RSS {peak}MB`):
   - all readable, ≥1 sample: `peak group RSS {N}MB` (unchanged);
   - some unreadable, ≥1 readable: `peak group RSS unknown (observed max {N}MB; {K} unreadable samples)`;
   - none readable, ≥1 unreadable: `peak group RSS unknown (no readable samples; {K} unreadable samples)`;
   - no samples at all (exited before the first poll): `peak group RSS unknown (gate exited before first sample)`.
4. **Tests** in `test/gh390-gate-guard.sh`:
   - direct-import seam (same pattern as the CPU-attribution seam) with `subprocess.run` patched: OSError, exit 1, blank stdout → `ps-failed`; matching rows (incl. <1 MB) → value; non-matching rows → `group-missing`;
   - driven case: a `ps` stub that exits 1 first on the driver's `PATH`, gate `sleep 3`; assert exit 0, warning exactly once, `peak group RSS unknown (no readable samples;`, and no `peak group RSS 0MB`;
   - red control: the same driven case with the real `ps` must print a numeric `peak group RSS [0-9]+MB` and no warning — proves the assertion distinguishes the two.
   - existing cases (honest gate, allocator kill, wall, CPU, red gate, escape hatch) must stay green unchanged.

### Non-goals

- Publishing RSS peak or measurement quality in the result JSON (versioned contract change → follow-up issue).
- Fail-closed mode or an env flag for it (rejected in #507818; would block sandboxed marathons).
- Fallback probes (`getrusage`, `/proc`, `ps -p`).
- GH-772 page size; GH-769 refactor; F20 poll cost.

### Test non-scope

No new test file, no fuzzing, no timing-sensitive exact sample counts (assert `K ≥ 1` by pattern only).

### Risks / rollback

- Risk: an exited-gate race misclassified as unreadable → a spurious warning. Covered by the `group-missing` re-poll and the seam test.
- Risk: the `PATH` stub also shadows `ps` for other driver code. Only `_gate_group_rss_mb` calls `ps` in the driver (verify with grep before the driven case).
- Rollback: revert the single commit; `MARATHON_GATE_GUARD=0` remains the ship-day escape hatch.

### Acceptance check (falsifiable)

`bash test/gh390-gate-guard.sh` passes, including the new seam and driven cases; the driven red control fails if the warning or `unknown` text is printed with a working `ps`. `bash test/gh291-contract-goldens.sh` and `bash test/gh457-gate-tiers.sh` still pass. Full gate once on the final commit.

## Merge evidence

- PR #776 merged 2026-09-24 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
