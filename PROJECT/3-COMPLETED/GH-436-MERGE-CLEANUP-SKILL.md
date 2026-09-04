---
gh_issue: 436
source: https://github.com/HiQS-Labs/XYZ-forge/issues/436
title: "feat(skill): /merge-cleanup — Worktree & clone consolidation, PR sequencing, and safe teardown"
status: Complete
created: 2026-09-04
updated: 2026-09-04
owner: noelsaw1
doc_type: plan
effort: 3
complexity: 3
risk: 2
phases: 4
rating: "pri/sev/appeal/effort 85/70/90/50 · calc 295"
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/436
  - https://github.com/HiQS-Labs/XYZ-forge/issues/433
fix_probes:
  - test -f skills/merge-cleanup/SKILL.md
  - test -f skills/merge-cleanup/scripts/merge_cleanup.py
goal: >
  Implement and ship the /merge-cleanup agent skill in skills/merge-cleanup/ with full 6-phase ladder logic,
  verifying active locks/sessions, checking Git status across all local branches/stashes, resolving and
  topologically ordering open PRs, executing remote squash merges, running post-merge reconciliation
  (wave_reconcile + RELEASES DB + pdda issue-doc-sync), and performing safe teardown in strict compliance with
  WORKTREE-SAFETY.md.
---

# GH-436: /merge-cleanup Skill

## Status

| What was just completed | What's next |
|---|---|
| Issue #436 created and registered. Compliance with `WORKTREE-SAFETY.md` verified across all 6 phases. | Author `skills/merge-cleanup/SKILL.md` and helper scripts (`merge_cleanup.py`, `scan_clones.py`, `toposort_prs.py`). Register in RELEASES DB. Cut fresh full clone, run test suite, QA consult with Qwen 3.8 max, open PR targeting `development`, and tear down clone. |

## Assumptions (the bets, made explicit)

1. **Strict `WORKTREE-SAFETY.md` compliance.** Linked worktrees are NEVER deleted via `rm -rf`; they must be removed via `git worktree remove` and cleaned with `git worktree prune` and `git worktree repair`.
2. **Disposable standalone clone criteria.** A standalone clone (`.git` is a directory) may only be removed if proven to have 0 uncommitted changes, 0 stashes, 0 unpushed commits across all local branch refs vs origin, and 0 registered linked worktrees pointing to it.
3. **No touch on active in-flight work.** The scanner and cleanup tool will actively identify and preserve clones/worktrees with active driver locks (`.git/relay-driver.lock`), active `.tick/` claims, running processes (`lsof`), or explicitly preserved task branches (e.g. PR #427).
4. **Topological PR sequencing.** PRs are merged via GitHub API in topological order based on declared issue dependencies and overlapping touched files.
5. **Post-merge governance reconciliation.** After PRs are merged, `wave_reconcile.py --pr <N>` is executed, RELEASES DB is regenerated and verified, and `pdda.sh issue-doc-sync` ensures zero doc drift.

## Ladder Logic Phases

- **Phase 1: Discover & Inventory:** Scan candidate paths under `SAFE_ROOTS` (`~/Documents/GH Repos`, `~/agent-workspaces`), classify checkouts into Linked Worktrees vs Standalone Clones, reject paths in `NEVER_DELETE`.
- **Phase 2: Active Process & Session Inspection:** Check `.git/relay-driver.lock`, verify PID liveliness, inspect `.tick/` claims, and verify open file handles.
- **Phase 3: Git Safety & Worktree Verification:** Inspect uncommitted files, unpopped stashes, and unpushed commits on all branches. Check worktree parentage.
- **Phase 4: PR Matrix & Topological Sorting:** Analyze open PRs, inspect dependency relationships, and construct safe merge sequence.
- **Phase 5: Execution & Post-Merge Reconciliation:** Interactive dry-run presentation, execute GitHub merges, fast-forward/pull primary `development`, run `wave_reconcile.py`, RELEASES DB sync, and doc sync.
- **Phase 6: Safe Teardown:** Execute `git worktree remove` + `git worktree prune` on linked worktrees; delete verified-safe standalone clones; clean up dangling skill symlinks.

## Verification Ladder

1. Hermetic unit & property tests covering clone classification, safety predicates, and topological sort.
2. CLI dry-run and execution modes verified on fixture repositories.
3. QA consultation via `/relay-xyz` with Qwen 3.8 max.
4. Full validation pass in a clean task clone.

## Lessons Learned (For Future Agents)

1. **Path Safety & Containment:** Component-aware containment (`_within`) that rejects root and exact identity is essential to prevent catastrophic deletes on parent directories.
2. **Worktree Protocol Integrity:** Linked worktrees must always be removed with `git worktree remove` and pruned with `git worktree prune` — never deleted directly with `rm -rf`.
3. **Multi-Ref Inspection:** When validating disposable standalone clones, checking only `HEAD` is insufficient; checking all local branch refs against `origin` and inspecting `git stash list` guarantees zero unpushed work loss.
