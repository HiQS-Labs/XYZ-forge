---
title: "GH-922 · Preserve project chats in Codex task-sync"
status: working
created: 2026-10-02
updated: 2026-10-02
owner: codex
goal: Align centralized Codex candidate eligibility with native sweep policy.
gh_issue: 922
branch: fix/gh-922-codex-scope
---

# GH-922 · Codex candidate eligibility

## Status

| What was just completed | What's next |
|---|---|
| Fresh full clone from PR #902; deterministic saved-snapshot reproduction | Independent plan QA, then surgical fix and PR |

## Scope and dependencies

Tracking: https://github.com/HiQS-Labs/XYZ-forge/issues/922. User explicitly authorized a stacked full-clone fix on PR #902. Base SHA: 8c2e6cf3b18b2e3d58ff532f30d538a0dee3eb32. Prerequisites #900 then #902 must land before this PR. No deployment or merge in this task.

## Triangulate / recon

CELL: reversible x crossing -> recon-lite + falsify. Native instructions and read-only planner share eligibility; no stored schema or writer change.
GROUND: task-sync SKILL.md Native sweep steps 1-3 require local Codex, projectId null, chats/pinned membership and recent updatedAt. task_sync.py main -> run_sweep -> CodexAdapter.sweep -> _snapshot; sweep delegates title normalization to core.clean_base/local_stamp and returns proposals only. Native tools exclusively own writes. CodexAdapter.sweep currently lacks the projectId exclusion, allowing project chats when pinned. Options affecting selection: exclusion ID, hours, pin, pin_hours; apply/unpin/group are refused. Other adapters and core remain untouched.
Graph Verify attempted on primary generation 2026-09-30T07:57:23Z: task-sync symbols absent and all three source paths freshness missing. Exact branch source read in full instead; no completeness claim from graph.
FALSIFY: project grouping alone was insufficient to trigger failure: the 06:38 UTC snapshot places the excluded project chat in pinned; the 06:53 snapshot lacks its thread membership and passes with unchanged adapter source. Replaying both with refreshed captured_at gives missing/invalid activity error then success. Pin membership is the decisive differential. Do not weaken activity validation or substitute updatedAt.
Root cause: planner candidate predicate omits projectId restriction; Fix site: CodexAdapter.sweep eligibility predicate; Why not upstream/downstream: producer correctly excludes project chats and activity checker correctly refuses missing eligible activity.
SMALLEST: add projectId is not None to existing skip predicate. Keep manual pins unchanged. No new helper, scheduler, API, store writer, suite or gate.
UNKNOWNS: source snapshots are private and were not imported; public evidence uses synthetic IDs/titles. Real failure represents one incident repeated across five ticks, not growing incident count.

## Rating rationale

2026-10-02: pri/sev/appeal/effort = 80/80/50/95. Recurring work-blocking grooming failure, no observed data loss, local scope and easy recovery. Appeal neutral; effort high cheapness because one predicate. Recent 14-day window has this one observed incident; preceding 14-day rate unknown. No operator override.

## Ordered implementation and acceptance

1. Obtain independent Codex plan approval against source and native policy -> Approved before production edit.
2. Add the project exclusion at the existing predicate -> synthetic pinned project chat without activity is skipped, unpinned project/custom/remote/cloud/non-Codex/heartbeat entries remain untouched.
3. Record manual red/green controls under TESTS-RESULTS/2026-10-02+GH-922/ with provenance -> unmodified base fails mixed-inventory assertion; fixed planner succeeds; removing eligible activity still produces error and CLI exit 3. Check positive title/pin proposals, full description, existing manual pins, actual-old turns, freshness/malformed/empty refusal and idempotence. Do not create new test files or gate machinery.
4. Run independent final Codex QA and existing Small qualifying gate in disposable full clone, check clone identities and PDDA/ledger -> Approved and green evidence at exact code SHA.
5. Push through gate, open dependent PR against development with explicit #900/#902 sequence and verify hosted exact-head checks -> PR ready awaiting prerequisites; retain clone.

## Risk / rollback / non-scope

Easy rollback: revert this task commit. Unknown/missing projectId stays eligible for backward compatibility with native rows; a non-null ID is excluded. No blanket error suppression, no auto-unpin, no custom grouping changes, no app stores, no enabling Agy, no pilot edits. Qualifying suites only once in disposable clone; narrow manual checks during review. Private raw sidebar snapshots never committed.
