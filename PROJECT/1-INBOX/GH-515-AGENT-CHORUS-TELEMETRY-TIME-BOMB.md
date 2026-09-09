---
title: "GH-515: test/agent-chorus.sh's telemetry assertions time-bomb on the default-ON pilot window"
status: Parked
created: 2026-09-08
updated: 2026-09-08
owner: unassigned
goal: make the telemetry block of test/agent-chorus.sh opt in to telemetry explicitly, and assert the pilot-window logic without reading the wall clock
gh_issue: 515
source: https://github.com/HiQS-Labs/XYZ-forge/issues/515
doc_type: defect
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/327
  - https://github.com/HiQS-Labs/XYZ-forge/issues/505
context_tags: [agent-chorus, telemetry, test-hygiene, gate-red, time-dependent-test]
non_goals:
  - Extending or moving TELEMETRY_PILOT_WINDOW (a product decision, not a test fix)
  - Changing the shipped default-OFF behaviour now that the window has closed
  - Any other suite that reads the clock
effort: 2
complexity: 1
risk: 1
---

# GH-515 — eight telemetry assertions that expire with the calendar

## Status

| What was just completed | What's next |
|---|---|
| Fixed on `fix/gh505-relay-reviewer-integrity`: explicit opt-in + a clock-independent window assertion; both red controls observed | Land with the GH-505 PR |

## Observed

`test/agent-chorus.sh` went red at 00:00 UTC on 2026-09-09 with eight telemetry failures, and the
`pre-push` gate then refused every push in the repo. Nothing about telemetry was broken.

`TELEMETRY_PILOT_WINDOW = ("2026-08-24", "2026-09-08")` (`skills/agent-chorus/scripts/agent_chorus.py:202`)
is a closed date range compared against the real UTC clock by `telemetry_enabled()`. The suite's
telemetry block seeded through `ts_cli()` with no `AGENT2AGENT_TELEMETRY` opt-in, so every assertion
in it depended on today's date. The GH-327 block's seed `start` had the same defect, while its own
comment claimed telemetry was "forced ON so this tests the policy, not the pilot window".

Reproduced identically at `a6441b9b` (`origin/development`), so it is pre-existing and not
branch-specific.

## Fix

- `ts_cli()` and the GH-327 seed pass `AGENT2AGENT_TELEMETRY=1`, so they test the telemetry
  machinery rather than the calendar.
- One new assertion covers the window logic itself by substituting the window (open, closed, and
  today-as-edge) instead of reading the date, so the default-ON semantics stay pinned after the
  real window closes.

## Red controls (observed)

| Mutation | Result |
|---|---|
| `telemetry_enabled` → `return True` | `FAIL: pilot window logic wrong: inside=True outside=True edge=True` |
| `emit_telemetry` → no-op | 7 FAILs across the opt-in assertions, so the opt-in did not paper over a real break |

## Rating rationale — 2026-09-08

`rated 85/80/50/95`

- **Severity 80.** Work-blocking: the gate goes red and `pre-push` refuses every push from every
  branch until it is fixed. No data loss and no user-facing defect, which keeps it off the top of
  the band.
- **Priority 85.** Blocking now, repo-wide, and it does not self-heal.
- **Appeal 50.** Neutral; the operator expressed no preference.
- **Effort/cheapness 95.** One test file, 28 lines, one sitting.
- **Recurrence.** Window 2026-08-25 → 2026-09-08 versus the preceding 14 days: no prior report of a
  clock-dependent suite failure in this repo. Unknown whether other suites carry the same pattern;
  only `agent-chorus.sh` was audited.
