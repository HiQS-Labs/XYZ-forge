---
title: "GH-1470: clean-first conflict-hub forecast"
status: in-progress
created: 2026-11-14
updated: 2026-11-14
owner: Codex
goal: "Identify clean-first landing passes without changing landing authority or gates"
gh_issue: 1470
effort: 2
complexity: 2
risk: 2
---

## Status

| What was just completed | What's next |
|---|---|
| 10 manual scenarios and 227 existing checks pass; PDDA/PRS checks have no errors | Push through final gate, publish ready PR, await merge |

## Scope and recon

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1470.
`ledger_merge.landing_forecast` owns merge-tree simulation and advice; `merge_cleanup` owns
formatting, atomic selection snapshots and comparison. Extend these existing writers only.
The clean set excludes base conflicts, greedy highest-degree hubs (later-sequence tie break),
and transitive hard dependents. A second fold validates the clean set. No landing mutation changes.
`scan_directories` filters discovered clones by `--prefix` before Phase 6; primary inspection is
explicit and always preserved. Dangling symlink pruning remains independent.

Easy to reverse: revert this PR. Blast radius is advisory forecast output and its comparison metadata;
incorrect advice could increase operator repair churn, while explicit landing decisions and gates remain.

## Acceptance and verification

- Two hubs plus clean members: exact two pass lists, hub/clean counts, clean-set fold.
- Greedy hub and hard-dependency closure: retained manual driver scenarios H2/H5.
- Distributed conflicts or failed clean-set fold: group; unknown steps: withheld. H3c also covers
  small queues where fewer than three conflicts previously bypassed these rules.
- Pass-aware comparison and CLI: H7, including whole-queue override, refusal and clean-first execution.
- Existing merge-cleanup suite and parity guard, deterministic PDDA/PRS checks, disposable push gate.
- Retained driver and logs: `TESTS-RESULTS/2026-11-14+GH-1470/`. No new test suite (GH-831).

## Rating rationale (2026-11-14)

Retained rating 60/45/50/65: misleading advice increases repair and gate churn; operator requested completion,
no observed data loss, neutral appeal, bounded extension of existing simulation. Recurrence trend unknown:
one concrete downstream 12-PR incident in #1470; no historical incident count inferred.
No operator override. Intake admission was resumed after implementation already existed; not backdated.

## Review and limitations

Independent review did not run. Operator explicitly requested doing the work without subagents and
publishing with this disclosure. Manual checks and author review do not count as independent QA.
Text simulation does not run B1 or future reconcile commits; even pass 1 can need repair and re-pin.

## Lessons Learned (For Future Agents)

NO_ENTRY: component effects are confounded by a single resumed implementation run.
