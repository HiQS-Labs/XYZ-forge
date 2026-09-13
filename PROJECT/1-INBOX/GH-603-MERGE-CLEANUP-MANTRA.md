---
gh_issue: 603
source: https://github.com/HiQS-Labs/XYZ-forge/issues/603
title: "feat(merge-cleanup): add 5-point discipline mantra block to merge-cleanup skill"
status: Proposed (1-INBOX — active)
created: 2026-09-13
updated: 2026-09-13
owner: noelsaw1
doc_type: feedback
goal: >
  Add a verbatim 5-point discipline mantra recital block at the top of
  skills/merge-cleanup/SKILL.md (matching debug-mantra) to enforce re-anchoring across
  multi-turn agent conversations.
roadmap_exempt: true
---

# GH-603 — merge-cleanup discipline mantra

Add a verbatim 5-point discipline mantra block to `skills/merge-cleanup/SKILL.md` to ensure agents reciting the skill at the start of execution re-anchor context across multi-turn sessions.

## 5-Point Mantra Structure

1. **Verify primary landing readiness (Phase 0).** Confirm the primary on-disk checkout is clean, on the integration branch (`development`), and ready to fast-forward before any remote action.
2. **Inventory checkouts & protect active sessions (Phases 1–3).** Scan worktrees and task clones across safe roots; preserve any checkout with active file handles, driver locks, `.tick` claims, or recent edits (10m/60m recency ladder).
3. **Sequence PRs & pre-gate conflicts (Phases 4–5).** Fetch open PRs into a topological DAG to prevent file collisions; pre-simulate landings and resolve disjoint ledger/doc conflicts.
4. **Merge & reconcile governance (Phase 5).** Remote squash-merge in dependency order, fast-forward primary checkout (`git merge --ff-only`), and execute post-merge reconciliation (`wave_reconcile`, `releases_app check`, `pdda.sh`).
5. **Safe teardown & status confirmation (Phase 6).** Deregister worktrees via canonical git protocol, move clean disposable clones to Trash, prune dangling skill symlinks, and confirm all PRs are landed.
