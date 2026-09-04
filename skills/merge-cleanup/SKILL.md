---
name: merge-cleanup
description: Consolidate multiple Git worktrees and clones of a repository into a single clean checkout, safely merge associated PRs in topological dependency order, reconcile post-merge governance state (PDDA and RELEASES DB), and safely remove leftover worktrees/clones without data loss or interrupting active sessions. Strictly complies with WORKTREE-SAFETY.md.
---

# /merge-cleanup — Worktree Consolidation, PR Sequencing, and Safe Teardown

`merge-cleanup` consolidates multiple active Git worktrees and clones of a repository into a single clean primary checkout, determines optimal topological PR merge sequences, executes GitHub PR merges, triggers post-merge PDDA & RELEASES DB reconciliations, and safely tears down disposable worktrees/clones without data loss or active process disruption.

Strictly adheres to [`WORKTREE-SAFETY.md`](../../WORKTREE-SAFETY.md) and [`AGENTS.md`](../../AGENTS.md).

---

## Conversational Triggers

When the operator speaks naturally:
- `"Run merge-cleanup on this repo"`: Audits checkouts, lists open PRs in dependency order, previews the cleanup plan in dry-run mode, and asks for confirmation.
- `"Scan all clones and worktrees"`: Runs Phase 1–3 discovery and outputs the status matrix of all worktrees and clones.
- `"Sequence and merge open PRs"`: Determines topological order of open PRs, detects file collisions, and executes remote squash merges followed by wave reconciliation.
- `"Tear down clean task clones"`: Safely removes verified clean, non-active clones and worktrees.

---

## 6-Phase Ladder Logic

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Phase 1: Discover & Inventory (Identify Checkouts & Roots)              │
├─────────────────────────────────────────────────────────────────────────┤
│ Phase 2: Active Process & Session Inspection (Zero Disruption)          │
├─────────────────────────────────────────────────────────────────────────┤
│ Phase 3: Git Safety & Worktree Verification (Data Loss Prevention)      │
├─────────────────────────────────────────────────────────────────────────┤
│ Phase 4: PR Matrix & Topological Sorting (Dependency-Ordered Landing)   │
├─────────────────────────────────────────────────────────────────────────┤
│ Phase 5: Safe Execution & Post-Merge Reconciliation (Governed Landing)  │
├─────────────────────────────────────────────────────────────────────────┤
│ Phase 6: Safe Teardown (Worktree & Clone Pruning via Git Protocol)      │
└─────────────────────────────────────────────────────────────────────────┘
```

### Phase 1: Discover & Inventory
- Locates candidate repositories under `SAFE_ROOTS` (`~/Documents/GH Repos`, `~/agent-workspaces`, etc.).
- Evaluates component-aware containment (`_within(child, parent)`) and refuses `NEVER_DELETE` protected roots (`$HOME`, `~/Documents`, `~/Desktop`, `/`).
- Distinguishes **Linked Worktrees** (`.git` is a file with pointer `gitdir: ...`) from **Standalone Clones** (`.git` is a directory).
- Uses `git worktree list --porcelain` to determine parent-child relationships.

### Phase 2: Active Process & Session Inspection
- Checks driver locks: `.git/relay-driver.lock` (or vendored `.relay-driver.lock`) and validates holder PID liveness via `kill -0 <pid>`.
- Checks `.tick/` active claims and coordination events.
- Checks running process file handles via `lsof`.
- Honors explicit user exclusion patterns (e.g. `--exclude gh427`).

### Phase 3: Git Safety & Worktree Verification
- **Dirty status:** Asserts `git status --porcelain` is empty (0 modified or untracked files).
- **Stashes:** Asserts `git stash list` is empty (0 unpopped stashes).
- **Unpushed refs:** Asserts all local branches are pushed to `origin` (`git for-each-ref` has 0 `[ahead N]` and 0 local-only branches).
- **Worktree dependencies:** Verifies no other linked worktrees point to a clone before marking it disposable.

### Phase 4: PR Matrix & Topological Sorting
- Fetches open PRs via GitHub API (`gh pr list`).
- Extracts explicit dependency references (`depends on #N`, `blocked by #N`, `after #N`).
- Analyzes touched file sets to detect unannotated file collisions and orders shared-file PRs chronologically.
- Builds a Directed Acyclic Graph (DAG) and computes topological merge order.

### Phase 5: Safe Execution & Post-Merge Reconciliation
- Presents execution plan for confirmation.
- Executes remote merges in topological sequence (`gh pr merge <PR_NUM> --squash --delete-branch`).
- Fast-forwards primary repository `development` branch (`git merge --ff-only origin/development`).
- Executes post-merge reconciliation:
  - `python3 utils/py/wave_reconcile.py --pr <PR_NUM>`
  - `python3 utils/py/releases_app.py gen && python3 utils/py/releases_app.py check`
  - `bash utils/pdda/pdda.sh issue-doc-sync`

### Phase 6: Safe Teardown
- **Linked Worktrees:** Always removed via `git worktree remove <path>` from parent clone, followed by `git worktree prune` and `git worktree repair`. **Zero `rm -rf` on linked worktrees!**
- **Standalone Clones:** Only deleted if verified 100% clean across Phase 2 & 3. Moved to Trash (`~/.Trash`) when available.
- **Symlink Cleanup:** Prunes dangling skill symlinks in `~/.claude/skills/` and `~/.gemini/**/skills/`.

---

## CLI Usage

Run scripts directly from the skill directory or via python:

```bash
# 1. Full Dry-Run Inspection (Default)
python3 skills/merge-cleanup/scripts/merge_cleanup.py --prefix XYZ-forge

# 2. Audit Only (Scan Clones and Worktrees)
python3 skills/merge-cleanup/scripts/scan_clones.py --prefix XYZ-forge

# 3. PR Topological Sequencing
python3 skills/merge-cleanup/scripts/toposort_prs.py

# 4. Execute Full Sequence (Merges, Reconciliation, and Teardown)
python3 skills/merge-cleanup/scripts/merge_cleanup.py --prefix XYZ-forge --execute

# 5. Teardown Only (Clean Clones/Worktrees without merging PRs)
python3 skills/merge-cleanup/scripts/merge_cleanup.py --prefix XYZ-forge --teardown-only --execute

# 6. Exclude Active In-Flight Work (e.g. PR 427)
python3 skills/merge-cleanup/scripts/merge_cleanup.py --prefix XYZ-forge --exclude 427 --execute
```

---

## Safety Guarantees

1. **Zero Data Loss:** Any dirty working tree, unpopped stash, or unpushed commit automatically stops deletion and marks the checkout `PRESERVE_*`.
2. **Zero Process Interference:** Clones with active driver locks or running subagents are detected and preserved.
3. **Canonical Worktree Protocol:** Linked worktrees are always cleanly deregistered from git metadata.
4. **Governed Landing:** Every PR merge triggers deterministic wave reconciliation and doc sync.
