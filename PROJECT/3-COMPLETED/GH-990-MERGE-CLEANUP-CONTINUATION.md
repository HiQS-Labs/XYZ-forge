---
gh_issue: 990
source: https://github.com/HiQS-Labs/XYZ-forge/issues/990
title: Merge-cleanup continuation contract
status: Complete
created: 2026-10-07
updated: 2026-10-08
owner: Claude
goal: Stop merge-cleanup agents from handing reversible, already-authorized steps back to the operator
---

# Merge-cleanup continuation contract

## Status

| What was just completed | What's next |
|---|---|
| Contract added to the drive loop; parity guard green (7 passed); shipped with the GH-985 landing | Merge, reconcile, deploy to the local skill collection |

## Observed input

Agents driving `/merge-cleanup` pause on steps the request already authorizes: running `--execute`
after the dry run, `--resume --execute` after exit 3, committing intake docs that block Phase 0,
opening the batch issue, tearing down `SAFE_REMOVE_*` clones. The skill carried one line about
carrying authorization forward but no list of in-scope steps and no closed list of real decisions,
so every pause read as prudent.

## Bet (smallest viable)

Documentation only. Port the `/workhorse` shared continuation and completion contract (GH-983,
GH-985) into the merge-cleanup drive loop as a "Continuation contract" subsection: what the request
authorizes, which reversible steps proceed without asking, the closed list of decisions that do
warrant a stop, evidence before Done, and no widening of authorization. Step 2 of the drive loop
now says to finish independent steps before reporting a blocker.

## Non-goals

No script, flag, hook, or test change. No Stop hook for merge-cleanup; the script's exit codes and
the attempt record already bound the loop. No change to Costly / One-way-door handling.

## Acceptance

- [x] Continuation contract subsection present in `skills/2-daily/merge-cleanup/SKILL.md` — evidence: this PR's diff
- [x] Parity guard unchanged — evidence: `python3 -m pytest -q test/gh534_phase_c_tests.py -k Parity` → 7 passed
- [ ] Landed on development and deployed to `~/git-pulse-sync/Deployed Skills/merge-cleanup`

## Merge evidence

Recorded by reconciliation on landing.

## Lessons Learned (For Future Agents)

A single sentence saying "carry authorization forward" does not stop an agent from asking. It needs
the in-scope steps named and the real decisions enumerated as a closed list; anything not on the
list proceeds.
