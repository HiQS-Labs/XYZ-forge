---
title: Repair unborn fixture and fail closed on unsafe fixture paths
status: Active
created: 2026-09-17
updated: 2026-09-17
gh_issue: 653
source: https://github.com/HiQS-Labs/XYZ-forge/issues/653
doc_type: bugfix
owner: noel
goal: Restore complete GH-642 coverage without permitting fixture failures to write into caller repositories.
effort: 1
complexity: 2
risk: 3
phases: 1
---

# GH-653 — Fixture safety

## Status

| What was just completed | What's next |
|---|---|
| Existing repair located in held GH-661 clone; current development failure observed; both issues registered/rated | Independent plan QA, extract only fixture changes, verify and open separate PR; test combined with #669 without publishing a stack |

## Quad Concepts

- Unborn fixture prevents complete checks → seed only a validated sandbox repository.

## Recon, diagnosis and recent PRs

Base: development 011113f6. validate.sh:505 registers the existing suite. Its
Original-base test/gh642-consumer-fruit.sh:23–27 mkrepo initializes a repository but makes no
commit; :44–46 pushes HEAD then clones/adds a worktree with errors suppressed.
Fresh full-clone reproduction fails after six checks, before real worktree coverage.
Protocol: debug-mantra. Ranked causes: missing commit (source/observed); worktree
feature unsupported (not demonstrated; setup never seeded); full-clone isolation
failure (falsified by controlled unchanged clone identity); vendor behavior failure
(earlier normal-clone assertions pass). Do not imply caller damage on current base.

GH-665: adding a seed alone is unsafe. Failed mkrepo substitution can return empty;
git -C empty targets caller. Existing held GH-661 fixture repair stops construction
failures and reuses test/lib/fixture-guard.sh. That shared guard resolves physical
descendants and refuses empty/traversal/symlink escapes with exit2. _setup.sh pins
the owned root and traps cleanup; do not change either shared file. Source/test
write sites and cleanup boundaries in the complete GH-642 suite were read, including
its RTL temporary worktree, standalone fixture clones and generated stub/output paths.

Recent PR sample: #643 (merged Sep16) introduced this suite; #614 (Sep15) repaired
Claude isolation/routing tests, related class but not this cause; #652 (Sep17)
fixed vendored ledger-conflict tool lookup, separate failure path. Historical #6
(Aug16) introduced the reusable guard, #89 expanded adoption. Existing #669
repairs a different inherited-CWD probe. Bounded Sep03–17 merged-PR sample and older fixture examples:
examples, not exhaustive incident counts; recurrence trend unknown. No other
published PR specifically repairing #653/#665 found. Existing unpublished repair
remains held under #661; extract only this test file, preserving that clone/branch.

## Task map and persisted ratings

| Issue | Requirement | Shared delivery / acceptance | Rating |
|---|---|---|---|
| #653 | Seed validated repository before HEAD use; retain actual worktree coverage | fix/gh653-gh665-fixture-safety; this plan; entire GH-642 suite passes | 90/85/50/90 |
| #665 | Fail closed on malformed/failed fixture setup; caller preserved | same clone/branch/PR; empty/traversal/symlink/mkdir/init faults exit2 with caller HEAD/identity/tree unchanged | 95/95/50/85 |

Ratings: #653 blocks required qualification; #665 has demonstrated potential caller
commit damage in a controlled reproduction. Severity-led urgency, appeal neutral,
local existing repair cheap. Neither canonical nor held-source ledger previously
contained these rows; use existing CLI for intake/rating/promotion, no overrides.
GH-665's issue-named doc links here rather than duplicating the implementation plan.

## Scope and reversibility

Bet: the existing guarded fixture pattern plus one test-local seed restores
coverage without runtime behavior changes. Easy code rollback by reviewed revert;
safety consequences deserve risk3 and independent QA. Shield: owned controlled
callers and separate full validation clones. Tripwire: any changed real clone
HEAD/origin/bare state or caller sentinel invalidates results/stops publication.
One edited test, existing shared guard, no dependencies or new guard abstraction.
No runtime/kernel/Bash-twin changes, worktree removal/policy migration, unrelated
base repairs, merge, deployment, #661 resumption, or stacked-PR publication.

## Phase 1 — Repair and verification

1. Commit plan/intake; independent Codex plan QA cap3 → Approved before code.
2. Extract only GH-642 fixture edits from held source via apply_patch; keep actual
   feature assertions. Require nonempty/owned paths at writes, explicit seed
   identity, checked substitutions, and fail-closed construction → fault tests
   exit2 and preserve controlled caller; full suite reaches true worktree assertions.
3. In disposable full clone, retain original-base red and repaired green. Run
   bounded in-memory controls: disable fixture guard → symlink refusal turns red;
   inject controlled caller commit → caller-preservation check turns red. No tracked
   mutation; all generated fixtures remain inside _setup's owned outer sandbox.
4. Commit code/docs/evidence with source/hash/exit provenance; focused suite and
   static/full local gate in independent disposable clone → green and identity stable.
   Independent final Codex QA cap3 → Approved or explicit blocker, no silent retry.
5. Normal gated push and one PR into development → exact head/base/scope/CI checked,
   issues remain open. In a separate disposable combined-verification clone, merge
   #669 with fixture candidate locally, using existing ledger resolver if needed;
   preserve both ledgers, move resolver backup intact under temp, run full checks.
   Label as combined proposed-change evidence, not qualification of published #669.
   #669 remains draft until prerequisite lands; recheck actual hosted checks without
   claiming a configured/skipped check passed. No merge to development authorized.

### Phase 1 — QA checklist

- [ ] Original unborn fixture red retained and actual linked-worktree coverage green.
- [ ] All five fault refusals and caller checks pass; guard/caller controls witnessed red.
- [ ] Focused/static/full gate green at final source, clone identity stable, provenance committed.
- [ ] Independent plan/final QA Approved; separate PR base/head/scope verified.
- [ ] Combined #669 checks recorded separately; prerequisite and merge hold explicit.

## Lessons Learned (For Future Agents)

An initial commit is a prerequisite of worktree coverage, not a reason to skip it.
Guard path construction before introducing that commit; empty git -C targets caller.
