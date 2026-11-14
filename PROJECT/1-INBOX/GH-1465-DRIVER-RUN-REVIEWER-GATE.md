---
title: relay-drive runs the configured reviewer gate itself; finding-continuity rule in the reviewer protocol
status: Proposed (1-INBOX — not yet active)
created: 2026-11-14
owner: Noel Saw
gh_issue: 1465
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1465
doc_type: bugfix
complexity: 2
risk: 2
effort: 1
phases: 1
ratings_provisional: true
reported_from: LTVera-Pandas
non_goals:
  - new config file, env framework, clone manager or scheduler
  - rerunning browser cases or anything outside the configured gate command
related:
  - BinoidCBD/LTVera-Pandas#981
  - "#1428"
goal: >
  With a reviewer gate command configured, an Approved is attested only after relay-drive itself ran
  that command to exit 0; the reviewer protocol states that an earlier finding stays open until new
  evidence closes it.
---

# GH-1465 — relay-drive runs the configured reviewer gate itself; finding-continuity rule

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Symptom
In a host relay run (BinoidCBD/LTVera-Pandas#981) AI reviews turned a FAIL with open findings into a
PASS with no new evidence, and approved without running anything, relying on the builder's receipts.

## Operator rulings (pipeline owner, 2026-11-14)
- Keep "A `[Blocker]` must cite an observed failure" and add next to it, verbatim: "A finding from an
  earlier round stays open, and the verdict stays failing, until new evidence closes it."
- The driver runs the configured gate command itself and records the exit code, instead of trusting
  the reviewer's own `gate run: yes` line.

## Write-set
- `relay-automation/new-relay.sh` (canonical rule text) and its mirrors: `utils/py/marathon_drive.py`
  step 4c, `skills/1-hourly/relay/SKILL.md`, `skills/1-hourly/relay-xyz/SKILL.md`.
- `utils/py/proc_group.py` (`group_rss_mb`, optional `max_rss_mb` on `run_bounded`,
  `GATE_RSS_MB_DEFAULT = 8192`, `RSS_KILL_RC = 108`), shared with `utils/py/marathon_drive.py`
  (`_gate_group_rss_mb` delegates to `group_rss_mb`).
- `utils/py/relay_drive.py` `judge_terminal`: when `MARATHON_REVIEWER_GATE_CMD` is set, run it through
  `gate_env.gate_env()` and `proc_group.run_bounded(..., max_rss_mb=...)` (honoring
  `MARATHON_GATE_RSS_MB` and `MARATHON_GATE_GUARD=0`) in the target checkout; refuse on non-zero
  (`unverified-approval` after a builder-declared unverified block, else `gate-failed`).
  `utils/py/relay_attest.py` binds `driver-gate:` into the trailer.

## Verification
Manual red control and existing focused suites: `TESTS-RESULTS/2026-11-14+GH-1465/`. No new suite (GH-831).

## Limits
- Applies only when a gate command is configured; an unarmed relay is unchanged.
- In a marathon the focused gate now runs up to three times (reviewer, driver, pre-advance gate).
- The 900-second timeout path (exit 124) was not exercised; the driver-run gate uses wall-clock
  and group-RSS caps (no `ulimit -t` CPU cap, which stays on `run_pre_advance_gate`).
