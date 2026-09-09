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
- `"Run merge-cleanup on this repo"`: Reviews the primary on-disk checkout first (Phase 0), then audits the other checkouts, reports the sequence, and proceeds within the session's authorized PR and cleanup scope. Discovery does not add unrelated PRs to that scope; an explicit audit/dry-run request remains read-only.
- `"Scan all clones and worktrees"`: Runs Phase 1–3 discovery and outputs the status matrix of all worktrees and clones.
- `"Sequence and merge open PRs"`: Reports Phase 0 for the primary checkout first — a PR sequence is not actionable until the tree it lands in can receive it — then determines topological order of open PRs, detects file collisions, and executes remote squash merges followed by wave reconciliation.
- `"Tear down clean task clones"`: Safely removes verified clean, non-active clones and worktrees.

---

## 7-Phase Ladder Logic

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Phase 0: Primary On-Disk Checkout (Can It Receive The Landing?)         │
├─────────────────────────────────────────────────────────────────────────┤
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

### Phase 0: Primary On-Disk Checkout — always first, never by discovery

**Report the operator's own checkout before anything remote is fetched.** It is the tree every
PR lands in, the tree `git merge --ff-only` runs in, and the tree `wave_reconcile.py`,
`releases_app.py` and `pdda.sh` write to. A run that opens with a PR table has told the operator
about everyone else's work and nothing about their own.

- Inspect the primary **by identity**, not by discovery. It is listed because it is the primary —
  never because a `SAFE_ROOTS` walk reached it or its directory name matched `--prefix`. A primary
  outside those roots, or under a non-matching prefix, used to vanish from the audit entirely
  while Phase 5 went on merging into it.
- Report and gate on four facts: current branch vs the integration branch (`development`),
  working-tree cleanliness, local commits on the integration branch that `origin` does not have,
  and whether HEAD can fast-forward to `origin/<integration>`.
- **Unpushed commits on the integration branch are a blocker, not a note.** A squash-merge landing
  skips them silently, which is how local work is lost.
- Not ready is a **refusal to merge**, reported before the PR matrix, not a warning discovered
  after the merges are already irreversible. `--allow-unready-primary` overrides it deliberately
  and records the blockers.
- Uncommitted intake docs or captures in the primary are their own commit or a park — they do not
  ride along in whatever PR happens to be open.

```bash
python3 skills/merge-cleanup/scripts/merge_cleanup.py --primary . --scan-only   # Phase 0 + audit
```

### Phase 1: Discover & Inventory
- Always includes the primary checkout from Phase 0, then locates further candidate repositories under `SAFE_ROOTS` (`~/Documents/GH Repos`, `~/agent-workspaces`, etc.).
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
- Runs only after Phase 0 has reported. The PR sequence is advice until the primary can receive it.
- Fetches open PRs via GitHub API (`gh pr list`).
- Extracts explicit dependency references (`depends on #N`, `blocked by #N`, `after #N`).
- Analyzes touched file sets to detect unannotated file collisions and orders shared-file PRs chronologically.
- Builds a Directed Acyclic Graph (DAG) and computes topological merge order.

### Phase 5: Safe Execution & Post-Merge Reconciliation
- **Refuses to merge when Phase 0 says the primary is not landing-ready**, unless `--allow-unready-primary` is passed. Merging is remote and effectively irreversible; landing into a tree that cannot fast-forward leaves the repo half-landed with reconciliation unrun.
- Carries existing authorization forward. Ask only for a missing scope decision, ambiguous resolution, or an action requiring additional permission under repo policy, after completing safe preparation; do not ask the operator to reselect already authorized work.
- Treats routine documentation and generated-artifact conflicts as work to resolve: in an isolated full clone, refresh the target branch, preserve both sides' intended changes using the repo's documented resolver/CLI, regenerate derived files, and renumber only unpublished CHANGELOG entries against the latest target. Never blindly take one side of ledger data. Run required checks on the resulting PR head (mutation-heavy suites in a separate disposable full clone), push within authorization, and resume the merge sequence, refreshing before each PR. Escalate a concrete unresolved ambiguity or repeated failed repair, not the initial `CONFLICTING` status; do not retry the same failed repair indefinitely.
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

1. **Zero Data Loss:** Any dirty working tree, unpopped stash, or unpushed commit automatically stops deletion and marks the checkout `PRESERVE_*`. The primary checkout is inspected first and by identity, so it can never be skipped by a scan filter.
2. **No Blind Landing:** PR merges refuse to run while the primary checkout cannot fast-forward the integration branch.
3. **Zero Process Interference:** Clones with active driver locks or running subagents are detected and preserved.
4. **Canonical Worktree Protocol:** Linked worktrees are always cleanly deregistered from git metadata.
5. **Governed Landing:** Every PR merge triggers deterministic wave reconciliation and doc sync.
