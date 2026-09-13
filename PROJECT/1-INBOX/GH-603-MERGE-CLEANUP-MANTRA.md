---
gh_issue: 603
source: https://github.com/HiQS-Labs/XYZ-forge/issues/603
title: "feat(skills): add 5-point discipline mantra and overall goal to merge-cleanup and start-task skills"
status: Proposed (1-INBOX — active)
created: 2026-09-13
updated: 2026-09-13
owner: noelsaw1
doc_type: feedback
goal: >
  Add verbatim 5-point discipline mantra recital blocks and Overall Goal anchors at the top of
  skills/merge-cleanup/SKILL.md and skills/start-task/SKILL.md (matching debug-mantra) to enforce
  re-anchoring across multi-turn agent conversations.
roadmap_exempt: true
---

# GH-603 — workflow discipline mantras for merge-cleanup and start-task

Add verbatim 5-point discipline mantra recital blocks and Overall Goal anchors to `skills/merge-cleanup/SKILL.md` and `skills/start-task/SKILL.md` to ensure agents reciting the skill at the start of execution re-anchor context across multi-turn sessions.

## 1. Merge-Cleanup Discipline Mantra
1. **Verify primary landing readiness (Phase 0).** Confirm the primary on-disk checkout is clean, on the integration branch (`development`), and ready to fast-forward before any remote action.
2. **Inventory checkouts & protect active sessions (Phases 1–3).** Scan worktrees and task clones across safe roots; preserve any checkout with active file handles, driver locks, `.tick` claims, or recent edits (10m/60m recency ladder).
3. **Sequence PRs & pre-gate conflicts (Phases 4–5).** Fetch open PRs into a topological DAG to prevent file collisions; pre-simulate landings and resolve disjoint ledger/doc conflicts.
4. **Merge & reconcile governance (Phase 5).** Remote squash-merge in dependency order, fast-forward primary checkout (`git merge --ff-only`), and execute post-merge reconciliation (`wave_reconcile`, `releases_app check`, `pdda.sh`).
5. **Safe teardown & status confirmation (Phase 6).** Deregister worktrees via canonical git protocol, move clean disposable clones to Trash, prune dangling skill symlinks, and confirm all PRs are landed.
**Overall Goal:** All ready-to-merge PRs processed and local disk clones and git worktree folders safely torn down when appropriate.

## 2. Start-Task Discipline Mantra
1. **Resolve intake & isolate in a fresh clone (Steps 1–3).** Verify the canonical remote/issue, provision a fresh full clone with a task branch off `origin/development`, register the PDDA capture doc in `1-INBOX`, and record 4-axis RELEASES task ratings.
2. **Ground in recon & draft a surgical plan (Steps 4–5).** Trace live entry points, state writes, and blast radius before proposing changes; design the leanest DRY plan that extends existing subsystems with falsifiable acceptance checks.
3. **Pre-implementation plan QA (Step 6).** Run a Codex relay review on the plan, adjudicate findings against ground-truth evidence, and iterate until approved before writing production code.
4. **Execute & deterministically verify (Step 7).** Build the reviewed scope, commit structured checkpoints, and execute all required test suites and repo gates in safe isolation.
5. **Final relay QA & open ready PR (Steps 8–9).** Run final Codex relay QA on the completed diff and test evidence; upon approval, push through the pre-push gate, open the PR against `development`, and retain the task clone for merge handoff.
**Overall Goal:** Issue implemented to spec, validated through double-relay QA (plan + final), and submitted as a verified, conflict-free PR ready for merge.
