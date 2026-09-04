---
Goal: QA /merge-cleanup Skill Implementation (GH-436)
Date: 2026-09-04
NEXT: done
STATUS: Approved/Closed
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

---

## Reviewer Adjudication & Findings (Qwen 3.8 Max QA Review)

**Verdict:** **Approved / Closed** (All 5 questions verified with concrete file citations).

### 1. WORKTREE-SAFETY.md Compliance: PASS
- **Component-aware containment:** `_within()` in [`scan_clones.py:37-45`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh436/skills/merge-cleanup/scripts/scan_clones.py#L37-L45) strictly rejects `child == parent` and validates relative component containment. `is_safe_deletable_path` ([`scan_clones.py:48-68`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh436/skills/merge-cleanup/scripts/scan_clones.py#L48-L68)) resolves symlinks on both target and boundary sets and refuses `NEVER_DELETE` (`$HOME`, `~/Documents`, `~/Desktop`, `/`).
- **Canonical Worktree Protocol:** Linked worktrees are identified via `.git.is_file()` ([`scan_clones.py:195-202`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh436/skills/merge-cleanup/scripts/scan_clones.py#L195-L202)) and removed strictly via `git -C <parent> worktree remove <path>` followed by `git worktree prune` and `git worktree repair` in [`merge_cleanup.py:120-139`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh436/skills/merge-cleanup/scripts/merge_cleanup.py#L120-L139). Zero `rm -rf` on linked worktrees.

### 2. Active Process & Session Protection: PASS
- Driver lock detection in [`scan_clones.py:92-134`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh436/skills/merge-cleanup/scripts/scan_clones.py#L92-L134) checks both local and parent common-dir `.git/relay-driver.lock` (resolving `--git-common-dir` in linked worktrees), parses PID, and verifies liveness via `os.kill(pid, 0)` ([`scan_clones.py:81-89`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh436/skills/merge-cleanup/scripts/scan_clones.py#L81-L89)).
- Active `.tick/STATE.md` claims and lockfiles are checked in [`scan_clones.py:136-159`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh436/skills/merge-cleanup/scripts/scan_clones.py#L136-L159), marking checkouts `ACTIVE_TICK_CLAIM` to prevent disruption.
- User exclusion patterns (e.g. `--exclude gh427`) and wiki repos (`.wiki`) are preserved ([`scan_clones.py:270-288`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh436/skills/merge-cleanup/scripts/scan_clones.py#L270-L288)).

### 3. Git Data Loss Prevention: PASS
- Standalone clones are validated across 4 distinct invariants:
  - Working tree cleanliness: `git status --porcelain` must have 0 entries ([`scan_clones.py:220-229`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh436/skills/merge-cleanup/scripts/scan_clones.py#L220-L229)).
  - Stashes: `git stash list` must be empty ([`scan_clones.py:231-236`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh436/skills/merge-cleanup/scripts/scan_clones.py#L231-L236)).
  - Unpushed refs: `git for-each-ref` checks tracking status across all branches and validates local-only branches against remote history ([`scan_clones.py:238-255`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh436/skills/merge-cleanup/scripts/scan_clones.py#L238-L255)).
  - Worktree parentage: Standalone clones with active linked worktrees are preserved ([`scan_clones.py:257-266, 317-321`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh436/skills/merge-cleanup/scripts/scan_clones.py#L257-L266)).

### 4. Topological PR Sequencing: PASS
- Dependency regexes in [`toposort_prs.py:35-53`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh436/skills/merge-cleanup/scripts/toposort_prs.py#L35-L53) parse explicit dependency phrases.
- Unannotated file collision detection in [`toposort_prs.py:88-115`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh436/skills/merge-cleanup/scripts/toposort_prs.py#L88-L115) orders shared-file PRs chronologically.
- Kahn's topological sort with sorted cycle handling in [`toposort_prs.py:117-150`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh436/skills/merge-cleanup/scripts/toposort_prs.py#L117-L150) delivers deterministic, collision-free merge sequences.

### 5. Post-Merge Reconciliation: PASS
- `merge_cleanup.py` executes `gh pr merge --squash --delete-branch` ([`merge_cleanup.py:48-63`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh436/skills/merge-cleanup/scripts/merge_cleanup.py#L48-L63)), pulls `development` ([`merge_cleanup.py:261-264`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh436/skills/merge-cleanup/scripts/merge_cleanup.py#L261-L264)), and runs `wave_reconcile.py --pr <N>`, `releases_app.py gen/check`, and `pdda.sh issue-doc-sync` ([`merge_cleanup.py:65-102`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh436/skills/merge-cleanup/scripts/merge_cleanup.py#L65-L102)).
- Dangling skill symlinks under `~/.claude/skills` and `~/.gemini/**/skills` are cleanly pruned ([`merge_cleanup.py:164-186`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh436/skills/merge-cleanup/scripts/merge_cleanup.py#L164-L186)).

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ COMPLETE (reviewer)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
