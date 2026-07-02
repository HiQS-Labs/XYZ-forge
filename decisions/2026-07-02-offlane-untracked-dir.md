---
title: Generalize the worktree off-lane allowlist to a git-collapsed untracked-dir ancestor match (GH-59)
date: 2026-07-02
status: Decided
gh_issue: 59
related:
  - relay-automation/relay-turn-lib.sh      # rtl_in_allow + rtl_worktree_end off-lane loop
  - test/worktree-isolation.sh              # regression coverage
  - decisions/2026-06-30-target-root-same-repo-normalization.md  # prior rtl containment normalization
---

# Generalize the worktree off-lane allowlist to a collapsed untracked-dir ancestor match (GH-59)

**Decision:** In the containment kernel (`relay-turn-lib.sh`), when `rtl_worktree_end` scans
`git status --porcelain -z` for off-lane changes, treat a **git-collapsed untracked-directory entry**
(e.g. `.github/`) as **allowed when, and only when, it is an ancestor directory of a concrete
allowlisted file entry** (e.g. `.github/workflows/ci.yml`). This generalizes the special-case that
already exists for `.relay-artifacts/` so it applies to any allowlisted artifact that happens to live
in an otherwise-untracked directory. Strictness is preserved: a collapsed dir that is **not** an
ancestor of any allowlist file entry still trips `RTL_WT_OFFLANE=1` (exit 6).

**The problem it solves (reproduced live ×2):** under worktree isolation, a turn whose allowlisted
artifact lives in a brand-new (otherwise-untracked) directory is wrongly discarded as a containment
violation. `git status --porcelain` collapses an all-untracked directory to a single `<dir>/` entry,
and `rtl_in_allow` matches by **exact string**, so the collapsed `<dir>/` never equals the file-level
allowlist entry `<dir>/<file>` → `RTL_WT_OFFLANE=1` → the whole (correct) turn is reverted. Surfaced
by the Part C live-loop dogfood (2026-06-30, `improve-loop-machinetest/target.txt`) and again building
GH-61 Tier 1 CI (2026-07-02, `.github/workflows/ci.yml` — codex built all 3 allowlisted files
correctly and its gate passed, yet the turn was discarded). Both were worked around by pre-tracking the
directory (an empty stub), which is friction every future greenfield-in-a-new-dir marathon lane hits.

**The risk this accepts (named, not hidden):** `relay-turn-lib.sh` is the shared containment kernel —
the single most safety-critical component in the repo. A change to off-lane detection could, if
over-broad, let a genuinely off-lane creation slip through (a builder writing outside its allowlist,
undetected). The bet is that an **ancestor-of-a-concrete-allowlist-file** match is strictly narrower
than a bare prefix match:

- The match anchor is an existing **file** entry on the allowlist (`RTL_ALLOW`), not a directory. A
  collapsed dir is allowed only because a file the turn was *explicitly permitted to create* lives
  under it. Nothing the turn was not already allowed to write becomes writable.
- It does not widen what gets **copied back**: `rtl_worktree_end`'s copy-back loop still iterates
  `RTL_ALLOW` file entries only, so a stray sibling file created in the same new dir is neither matched
  as allowed NOR copied back — it is contained exactly as before.
- A collapsed dir with **no** allowlisted-file descendant is unchanged: still off-lane, still exit 6.

**Reversibility:** Costly (containment kernel), but the change is a localized, additive refinement to
one matcher with a mirrored precedent (`.relay-artifacts`). Rollback is a one-function revert. Gated
by a regression test that asserts BOTH directions (the greenfield case now passes; a true off-lane
creation still fails).

**Invariants the implementation must hold (the regression test enforces all three):**
1. **Fix:** an allowlisted file in an otherwise-untracked directory commits file-scoped, no exit 6.
2. **Strictness:** a file created outside any allowlisted ancestor still trips exit 6.
3. **No copy-back widening:** a non-allowlisted sibling in the same new dir is not copied back to ROOT.
