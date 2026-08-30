---
gh_issue: 165
source: https://github.com/HiQS-Labs/XYZ-forge/issues/165
title: "GH-165: Post-Merge Wave & Marathon Lifecycle Reconciler (Docs, ROADMAP, DB, Views, and Planning)"
status: Proposed
created: 2026-08-22
updated: 2026-08-22
owner: orchestrator
doc_type: active
effort: 3
complexity: 3
risk: 2
phases: 3
goal: >
  Implement the single canonical post-merge wave and marathon lifecycle reconciler in Python
  (utils/py/wave_reconcile.py) to atomically transition active docs from 2-WORKING to 3-COMPLETED,
  archive ROADMAP.md entries, mirror into releases.db, regenerate views, and compute next-wave
  marathon plans with zero split-brain script sprawl.
---

# GH-165: Post-Merge Wave & Marathon Lifecycle Reconciler (Docs, ROADMAP, DB, Views, and Planning)

## Status

| What was just completed | What's next |
|---|---|
| Multi-model QA review completed: Codex QA relay review (11 findings) and DeepSeek-V3 architectural trace. Draft 3 posted to Issue #165. | Implement `utils/py/wave_reconcile.py`, test suite `test/wave-reconcile.sh`, and static anti-sprawl guard `test/gh165-governance-canonical-paths-guard.sh`. |

## Table of contents
- [Definition of Done](#definition-of-done)
- [Two-Workflow Architectural Map](#two-workflow-architectural-map)
- [Phase 1: Canonical Reconciler Engine Implementation](#phase-1-canonical-reconciler-engine-implementation)
- [Phase 2: Hermetic Test Suite & Rollback Verification](#phase-2-hermetic-test-suite--rollback-verification)
- [Phase 3: Static Anti-Sprawl Regression Guard](#phase-3-static-anti-sprawl-regression-guard)

---

## Definition of Done

1. **Canonical Engine (`utils/py/wave_reconcile.py`):** Direct Python executable (no wrapper `.sh` shim per GH-551) acting as the sole post-merge lifecycle transition bridge.
2. **Merged PR Authority:** Moves active docs to `3-COMPLETED/` and derives badges strictly from merged PR metadata (`number`, `mergedAt`) on `development`. Asserts presence of `## Lessons Learned (For Future Agents)`. Routes unmerged/declined docs to `4-MISC/`.
3. **Hermetic Non-Mutating Dry-Run:** `--dry-run` performs zero network calls, cache writes, DB writes, or generated-file writes, proving byte-identical working tree state upon exit.
4. **Fail-Closed & Atomic Rollback:** Rejects dirty working trees (`git status --porcelain`) and rolls back all modifications via snapshot journal on any failure.
5. **Anti-Sprawl Static Guard:** `test/gh165-governance-canonical-paths-guard.sh` verifies in CI that no script outside `wave_reconcile.py` mutates docs, ROADMAP, or releases.

---

## Two-Workflow Architectural Map

1. **Workflow 1: Unified Mutation & Closeout Pipeline (Write Path):**
   `[PR Merged]` $\to$ `wave_reconcile.py` $\to$ `releases_app.py roadmap sync` $\to$ `marathon-plan.sh` $\to$ `export_timeline.py --preview` & `roadmap-dashboard.sh`.
2. **Workflow 2: Unified Verification & Hygiene Pipeline (Read Path):**
   `pdda.sh run` / `issue-doc-sync` $\to$ `releases_app.py check` $\to$ `standup/triage.py` (strictly read-only).

---

## Phase 1: Canonical Reconciler Engine Implementation
- Build `utils/py/wave_reconcile.py` with CLI flags (`--pr`, `--marathon`, `--manifest`, `--dry-run`, `--offline`, `--skip-pull`, `--gate`).
- Implement porcelain cleanliness preflight, common-dir lock (`.git/wave-reconcile.lock`), doc frontmatter updater, multiline ROADMAP entry block preserver, and subprocess orchestrator.

## Phase 2: Hermetic Test Suite & Rollback Verification
- Build `test/wave-reconcile.sh` with hermetic test cases for dirty-tree rejection, wrong-branch rejection, dry-run immutability, missing lessons rejection, offline mode, and rollback recovery.

## Phase 3: Static Anti-Sprawl Regression Guard
- Build `test/gh165-governance-canonical-paths-guard.sh` asserting read-only purity for validation scripts and authorized write boundaries for `wave_reconcile.py`.
