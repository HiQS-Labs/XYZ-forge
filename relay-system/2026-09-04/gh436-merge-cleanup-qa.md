---
Goal: QA /merge-cleanup Skill Implementation (GH-436)
Date: 2026-09-04
NEXT: Reviewer
STATUS: Open
---

# Context

Adjudicate the implementation of the `/merge-cleanup` skill against its design and the repository's strict safety standards in `WORKTREE-SAFETY.md`.

Read the following files:
- `PROJECT/2-WORKING/GH-436-MERGE-CLEANUP-SKILL.md`
- `skills/merge-cleanup/SKILL.md`
- `skills/merge-cleanup/scripts/merge_cleanup.py`
- `skills/merge-cleanup/scripts/scan_clones.py`
- `skills/merge-cleanup/scripts/toposort_prs.py`
- `test/gh436-merge-cleanup.py`

# Questions to Adjudicate

1. **WORKTREE-SAFETY.md Compliance:** Does `scan_clones.py` and `merge_cleanup.py` enforce all safety invariants?
   - Is path containment component-aware (`_within` rejects `child == parent`) and does `is_safe_deletable_path` refuse protected roots (`NEVER_DELETE`)?
   - Are linked worktrees (`.git` is a file) strictly removed via `git worktree remove` + `git worktree prune` + `git worktree repair` from the parent clone, with zero `rm -rf` on linked worktrees?
2. **Active Process & Session Protection:** Does the active lock inspection correctly check `.git/relay-driver.lock` (including in linked worktrees), verify PID liveness (`kill -0 <pid>`), and protect active sessions from disruption?
3. **Git Data Loss Prevention:** Are the safety criteria for standalone clones airtight (requiring `git status --porcelain` is clean, `git stash list` is empty, all local branches have zero unpushed commits vs origin, and zero dependent linked worktrees)?
4. **Topological PR Sequencing:** Does `toposort_prs.py` correctly extract explicit dependencies (`depends on #N`, `blocked by #N`, etc.), detect file collision overlap between PRs, and gracefully handle cycles?
5. **Post-Merge Reconciliation:** Does `merge_cleanup.py` properly coordinate post-merge governance updates (`wave_reconcile.py --pr <N>`, `releases_app.py gen/check`, and `pdda.sh issue-doc-sync`)?

Please review and provide concrete citations (`file:line`). If the implementation is sound and meets all safety requirements, change the STATUS to `Approved/Closed`.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (commandcode)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
