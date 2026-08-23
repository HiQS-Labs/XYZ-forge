---
title: "GH-195: test/gh115-round-cap.sh committed a live transcript onto the real clone during every validate.sh run"
status: Completed
created: 2026-08-23
updated: 2026-08-23
owner: orchestrator (Claude Code)
goal: document the incident, root cause, and fix so a future agent recognizes the failure shape immediately instead of re-diagnosing it
gh_issue: 195
source: https://github.com/HiQS-Labs/XYZ-forge/issues/195
doc_type: bugfix
effort: 1
complexity: 2
risk: 1
related:
  - "#115 — the marathon lane whose own new test caused this"
  - "GH-401 — the identical failure shape (unscoped marathon-drive invocation), described inline in test/marathon-root-audit.sh; this incident is that guard's blind spot reopened via a different invocation shape"
  - "GH-567/GH-1 — clone-identity-invariant, the gate that caught this"
---

# GH-195 — marathon-root-audit's blind spot: a direct `python3 marathon_drive.py` call

Captured and promoted directly to Completed (issue-first SOP, filed after the fix already landed).

## Status

| What was just completed | What's next |
|---|---|
| Root-caused via direct instrumentation, fixed in PR #194 (commit b1f5805), full gate verified 259/259 twice with `clone-identity-invariant` stable | Nothing further — closed. Flagged as a precedent for anyone hardening `marathon-root-audit.sh`'s invocation-shape coverage. |

## Incident

While driving the Bulkhead marathon (release 0.7.3, #179), GH-115's own new integration test
(`test/gh115-round-cap.sh` Test 5) set `MARATHON_ROOT=$ROOT` (the real repo) instead of `$A` (its
own tick fixture) when invoking `marathon_drive.py --phase-id p1 --relay-task TASK6 --force`. Every
`bash validate.sh` run therefore committed a live `marathon: phase p1 transcript saved (TASK6)`
record onto whichever real clone was running the gate — reproduced identically across 4 separate
clones, including a brand-new sterile one that had never run marathon-drive before. Always mid-gate,
always moving HEAD, always failing `clone-identity-invariant` (GH-1/GH-567) — the exact gate that
exists to catch a clone whose identity changed under a run.

## Why it evaded detection

`marathon-root-audit.sh` — the suite whose entire purpose is catching an unscoped marathon-drive
invocation, written as GH-401's own fix — only recognizes `bash <driver>.sh` invocations via regex
(`find_invocation_target()` matches `bash "$VAR"` or the literal `.xyz/relay-automation/*.sh`
strings). It never matches a direct `python3 <path>/marathon_drive.py` call, which is exactly how
this test invoked it. Same defect class as GH-401 — a guard's coverage defined by an invocation
*pattern* rather than by what the operation actually does — reopened via a shape the original fix
never anticipated.

## Diagnostic path (what worked, what didn't)

~2.5 hours were spent on inference-based hypotheses first, in order:
1. A leftover background process from an earlier marathon-drive run, still retrying — ruled out via
   `ps -ef` and `lsof +D` on the clone directories, twice, ~10 minutes apart.
2. A second concurrent marathon session (GLM or Agy) hitting the same generic phase-id — ruled out
   via an agent2agent cross-check with both live sessions; neither had ever touched the affected
   clones or used the observed task label.
3. A scheduled job — ruled out via `launchctl list` / `crontab -l` (found one unrelated, already-
   broken agent pointed at a different repo).

All three were plausible given the evidence at the time, and all three were wrong. What actually
resolved it: ground-truth inspection of `.tick/attempts/p1` in the affected clone — a per-clone,
append-only fire ledger — showed fire timestamps correlating to the exact second of each
`validate.sh` invocation, proving the writer was validate.sh itself, not an external process. A
single `traceback.print_stack()` dropped at the actual `git commit` call site in
`marathon_drive.py:save_transcript()`, run once, then confirmed it: the captured `argv`/`root` named
`test/gh115-round-cap.sh` and its exact flags.

**Lesson:** when a repeatable artifact exists (a commit, a ledger file), inspect it directly before
building a process-hunting hypothesis chain. The `.tick/attempts/` ledger was available from the
first occurrence and would have shortened the diagnosis by roughly 2 hours.

## Fix

Two parts, not one. The first attempt (`MARATHON_ROOT="$A"` alone) broke the test — the original
author had pointed `MARATHON_ROOT` at the real repo specifically so the invocation's *default*
`--pre-advance-cmd` (`<root>/validate.sh`) would resolve to something that exists; the fixture has
no `validate.sh` of its own. Fixed by scoping `MARATHON_ROOT` to the fixture **and** passing an
explicit `--pre-advance-cmd true`, matching the pattern already used by every other properly-scoped
invocation in this codebase (e.g. the GH-331 cost-summary suite).

Landed in [PR #194](https://github.com/HiQS-Labs/XYZ-forge/pull/194), commit `b1f5805`. Verified:
`test/gh115-round-cap.sh` green standalone with the fire correctly landing in the tmp fixture; full
`validate.sh` 259/259 on two consecutive runs with `clone-identity-invariant` stable.

## Follow-up (not actioned here, flagged for whoever picks it up)

`marathon-root-audit.sh`'s `find_invocation_target()` should also recognize a direct
`python3 .../marathon_drive.py` / `python3 .../relay_drive.py` invocation, not only the `.sh`
wrapper shape — otherwise this exact blind spot reopens the next time a test calls the Python
module directly instead of through its Bash twin.
