---
gh_issue: 1597
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1597
title: "merge-cleanup on Ubuntu lsof overlay warnings block scratch pruning, Skills Army HQ install, old git/gh"
status: proposed
created: 2026-11-24
owner: unassigned
doc_type: bug
complexity: 2
risk: 2
effort: 3
phases: 1
ratings_provisional: false
rating_pri: 80
rating_sev: 75
rating_appeal: 80
rating_effort: 75
rating_calc: 310
non_goals:
  - no changes to core landing algorithms or PR dependency ordering
  - no new test files under test/ (GH-831 compliance; all test controls located in TESTS-RESULTS/)
  - no Windows locking implementation (POSIX only)
related:
  - "#534"
  - "#1475"
  - "#660"
goal: >
  Resolve Linux/Ubuntu compatibility gaps in merge-cleanup and Skills Army HQ:
  1. Filter unrelated lsof filesystem warnings (such as Docker overlay2 mounts) while failing closed for paths inside or containing the checkout.
  2. Document the supported Linux path for Skills Army HQ (requiring intake.py init before add).
  3. Implement preflight checks and actionable guidance for minimum git (>= 2.38.0) and gh (>= 2.18.0) versions placed before their consumer operations.
updated: 2026-11-24
---

# GH-1597: merge-cleanup on Ubuntu lsof overlay warnings, Skills Army HQ install, old git/gh

## 1. Problem Statement & Ground Truth

Running `merge-cleanup` on Linux hosts (e.g. Ubuntu 22.04 LTS with Docker running) encounters three operational friction points:

1. **Unrelated `lsof` overlay warnings:**
   When Docker runs with `overlay2` storage, `lsof +D <checkout>` encounters `/var/lib/docker/overlay2/.../merged` mount points that cannot be `stat()`-ed from the host mount namespace. `lsof` emits warnings to stderr:
   ```
   lsof: WARNING: can't stat() overlay file system /var/lib/docker/overlay2/.../merged
         Output information may be incomplete.
   ```
   Currently, `scan_clones.py:inspect_open_handles()` treats any stderr line as an enumeration failure (`lsof enumeration incomplete`), marking idle directories as `PRESERVE_UNVERIFIED_SESSION` and preventing pruning of scratch clones in `/tmp`.

2. **Skills Army HQ collection initialization on Linux:**
   Invoking `python3 skills/3-weekly/skills-army-hq/scripts/intake.py add <skill>` on an uninitialized Linux host fails with:
   ```
   skills-army-hq: Collection missing: /home/<user>/git-pulse-sync/Deployed Skills; run intake.py init
   ```
   The documentation in `skills-army-hq/README.md` and `SKILL.md` describes macOS as the alpha platform without explicitly clarifying the Linux workflow, leading users to believe the platform itself is unsupported rather than requiring standard collection initialization (`intake.py init`).

3. **Outdated default tool versions on Ubuntu 22.04:**
   - Default apt `git` on Ubuntu 22.04 is `2.34.1`. The landing forecast uses `git merge-tree --write-tree`, which was introduced in Git `2.38.0`. In Git 2.34.1, it fails with:
     ```
     merge-tree failed: usage: git merge-tree <base-tree> <branch1> <branch2>
     ```
   - Default apt `gh` on Ubuntu 22.04 is `2.4.0`. PR discovery queries `headRefOid`, which was added to GitHub CLI in `v2.18.0` (PR #6399). In gh 2.4.0, it fails with:
     ```
     PR discovery failed: Unknown JSON field: "headRefOid"
     ```
   - No preflight checks or minimum versions were documented in `SKILL.md`.

---

## 2. Technical Architecture & Surgical Design

### Seam 1: `scan_clones.py` lsof Stderr Classification & Deletion Guard Preservation
In `skills/2-daily/merge-cleanup/scripts/scan_clones.py` (`inspect_open_handles`):
- Parse each line of `proc.stderr`.
- Identify filesystem warnings: `lsof: WARNING: can't stat() <fstype> file system <path>` (and secondary disclaimer `Output information may be incomplete.`), as well as path warnings like `can't stat(<path>)` / `can't opendir(<path>)`.
- Test if the warned path is related to `repo_path` or `resolved_repo`:
  - Related if `warn_path == repo_path`, `warn_path == resolved_repo`, `_within(warn_path, repo_path)`, `_within(warn_path, resolved_repo)`, `_within(repo_path, warn_path)`, or `_within(resolved_repo, warn_path)`.
- If a warning refers to an unrelated path (e.g. Docker overlay2 mount outside the checkout), it is safely filtered out.
- If a line is `Output information may be incomplete.` following an unrelated warning, it is tolerated as companion text. A standalone incomplete-output disclaimer without an preceding unrelated warning is treated as an unclassified error and fails closed.
- If any warning path is related to the checkout, OR if there is an unclassified non-warning error line on stderr, fail closed:
  `{"verified": False, "active": False, "details": f"lsof enumeration incomplete: {line}", "holders": []}`.
- Deletion safety invariant: Filtering unrelated stderr does NOT bypass handle parsing. If stdout reports open file handles or an active process whose CWD is the checkout root, `inspect_open_handles` MUST return `{"verified": True, "active": True, ...}`, and pruning (`merge_cleanup.py:_prune_retained_workdirs`) MUST refuse to remove it.

### Seam 2: `merge_cleanup.py` Early Version Preflight Placed Before Consumers
In `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` & `ledger_merge.py`:
- **Placement before consumer operations:**
  - `check_gh_version()`: Run before Phase 4 PR discovery (`fetch_open_prs_with_retry()`). If `gh` is older than `2.18.0`, log clear error and actionable guidance (`gh 2.18+ required for 'headRefOid' field; on Ubuntu/Debian install from https://cli.github.com or release .deb`) before failing discovery.
  - `check_git_version()`: Run before Phase 4 landing forecast (`landing_forecast()`). If `git` is older than `2.38.0`, emit warning naming `git 2.38+ required for 'git merge-tree --write-tree'; on Ubuntu/Debian upgrade via ppa:git-core/ppa`.
  - Also include tool version checks in `preflight_warnings()` for preview/unattended runs.
- In `ledger_merge.py` (`_merge_tree`): When `git merge-tree` exits non-zero with `usage: git merge-tree <base-tree>` or syntax refusal, return:
  `merge-tree failed: git merge-tree --write-tree requires git 2.38+ (installed git is older; upgrade git via ppa:git-core/ppa on Ubuntu/Debian)`

### Seam 3: Skills Army HQ & Merge-Cleanup Documentation
- `skills/3-weekly/skills-army-hq/README.md` & `SKILL.md`: Document Linux POSIX support. Clarify that `intake.py init` must be run first to establish the collection (or adopt an existing Pulse collection) before `add`.
- `skills/2-daily/merge-cleanup/SKILL.md`: Document Prerequisites: Python 3.9+, Git >= 2.38.0, GitHub CLI (`gh`) >= 2.18.0, and explain the lsof unrelated warning tolerance.

---

## 3. Falsifiable Acceptance Criteria & Execution Controls

All verification controls will execute deterministically in `TESTS-RESULTS/2026-11-24+GH-1597/run_controls.py` (zero test sprawl under `test/`, strictly complying with GH-831), with results captured in `SUMMARY.md` and `provenance.jsonl`:

1. **AC-1 (lsof unrelated warning + idle directory):**
   `inspect_open_handles` on an idle directory with simulated `lsof: WARNING: can't stat() overlay file system /var/lib/docker/overlay2/abc/merged\n Output information may be incomplete.` on stderr returns `verified: True, active: False`.
2. **AC-2 (lsof unrelated warning + root-CWD holder process):**
   In a disposable checkout with an active subprocess whose CWD is the checkout root, `inspect_open_handles` in the presence of an unrelated Docker overlay warning returns `verified: True, active: True` naming the holder PID, and scratch pruning refuses removal.
3. **AC-3 (lsof related warning fails closed):**
   `inspect_open_handles` with a warning mentioning a path equal to, inside, or containing the checkout path (including canonical symlink aliases, e.g. `lsof: WARNING: can't opendir(/path/to/repo/sealed)`) returns `verified: False, active: False` with `lsof enumeration incomplete`.
4. **AC-4 (lsof standalone incomplete disclaimer & unclassified errors fail closed):**
   `inspect_open_handles` with a standalone `Output information may be incomplete.` (without prior warning) or an unrecognized stderr line returns `verified: False, active: False`.
5. **AC-5 (gh version check before discovery):**
   CLI execution with a stubbed `gh` reporting version 2.4.0 (below 2.18.0) fails with a clear message naming `gh 2.18+` and the upgrade path before discovery returns. A stub reporting 2.18.0 succeeds without warning.
6. **AC-6 (git version check before forecast):**
   CLI execution with a stubbed `git` reporting version 2.34.1 (or 2.37.9, below 2.38.0) emits the Git 2.38+ recommendation before running `landing_forecast`. A stub reporting 2.38.0 passes without warning.
7. **AC-7 (_merge_tree diagnostic output):**
   `_merge_tree` simulation on git returning legacy usage syntax returns `merge-tree failed: git merge-tree --write-tree requires git 2.38+...`.
8. **AC-8 (Skills Army HQ Linux documentation):**
   Documentation in `skills-army-hq/README.md` and `SKILL.md` explicitly states POSIX/Linux support and specifies running `intake.py init` prior to `add`.
9. **AC-9 (Regression verification):**
   Existing suite `test/gh534_phase_a_tests.py` runs and passes 46/46 tests cleanly.

