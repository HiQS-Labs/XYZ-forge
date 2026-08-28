# Git Worktree and Full-Clone Safety Guide for Agents

Author: Noel Saw (@noelsaw1)  
License: See [`LICENSE`](LICENSE) and [`LICENSE-COMMERCIAL.md`](LICENSE-COMMERCIAL.md)
Copyright 2026 Neochrome, Inc.  

> **Purpose:** Prevent destructive checkout and repository-state failures in agent-driven Git workflows.
> **Scope:** Shell scripts, CI pipelines, and agent workflows that create, use, verify, move, or
> remove linked worktrees and full-clone folders.

> **Safety and warranty:** XYZ Forge is provided **“AS IS,” without warranty**, under the applicable
> license. Coding models may choose commands through their own runtimes and safety controls, outside
> the intended harness workflow. These mitigations cannot guarantee model behavior or data integrity;
> maintain tested, independent backups and follow industry-standard backup and recovery practices.

---

## Table of contents

- [Safety model: linked worktrees and full clones](#safety-model-linked-worktrees-and-full-clones)
- [1. The `rm -rf` worktree-path trap](#1-the-rm--rf-worktree-path-trap)
- [2. Scripting `git worktree add` without failure handling](#2-scripting-git-worktree-add-without-failure-handling)
- [3. Trap cleanup with relative or unvalidated paths](#3-trap-cleanup-with-relative-or-unvalidated-paths)
- [4. Moving worktree directories outside Git](#4-moving-worktree-directories-outside-git)
- [5. Assuming a shared branch is free for checkout](#5-assuming-a-shared-branch-is-free-for-checkout)
- [6. Garbage collection while worktrees are active](#6-garbage-collection-while-worktrees-are-active)
- [7. Deleting a clone's `.git` or full-clone folder](#7-deleting-a-clones-git-or-full-clone-folder)
- [8. Using fragile relative paths between checkouts](#8-using-fragile-relative-paths-between-checkouts)
- [9. What branch deletion actually protects](#9-what-branch-deletion-actually-protects)
- [10. `git stash` is global within a worktree family](#10-git-stash-is-global-within-a-worktree-family)
- [11. Selective `.git` corruption and skeleton loss](#11-selective-git-corruption-and-skeleton-loss)
- [12. Run the full gate only in a disposable full clone](#12-run-the-full-gate-only-in-a-disposable-full-clone)
- [13. Other worktree and full-clone footguns](#13-other-worktree-and-full-clone-footguns)
- [Golden rules](#golden-rules)
- [See also](#see-also)

## Safety model: linked worktrees and full clones

The boundary that matters is the Git directory, not the number of folders on disk. A linked
worktree gives a branch its own working files but shares repository state with its parent. A full
clone owns a separate Git directory, but it is safe to destroy only when it contains no unique work
and no linked worktrees depend on it.

| Checkout type | Git storage | What it isolates | Safe default use |
|---|---|---|---|
| Primary checkout of a full clone | `.git/` directory | Independent from other full clones; shared with its own linked worktrees | Valued repository state; do not treat as a test fixture |
| Linked worktree | `.git` file pointing into the parent clone | Working-tree files only | Editing and committing within a known branch lane |
| Disposable full clone | Independent `.git/` directory with no unique state or dependent worktrees | Working tree and Git config, refs, objects, hooks, and stashes | Mutation-heavy gates and destructive experiments |

“Disposable” is an operator-owned lifecycle, not a Git property. A normal clone becomes valued as
soon as it holds an unpushed commit, stash, reflog-only recovery object, local configuration, or a
linked worktree that another process still uses.

---

## 1. The `rm -rf` worktree-path trap

**Anti-pattern:** Deleting a worktree by just removing its directory.

```bash
# WRONG — leaves stale metadata in .git/worktrees/
rm -rf ../feature-branch

# Also WRONG — git still thinks the worktree exists
git worktree remove ../feature-branch  # fails: "not a working tree"
```

**Why it's dangerous:** Git maintains metadata in `.git/worktrees/<name>/` and in a `.git` file inside the worktree. If you `rm -rf` the directory, you get:
- Orphaned metadata polluting your repo
- The branch may still be checked out according to git, blocking operations
- `.git/worktrees/<name>/index` can grow large and never gets cleaned

**Correct approach:**
```bash
# Always use git worktree remove
git worktree remove ../feature-branch

# If the directory is already gone, let git reconcile its own metadata —
# don't hand-delete .git/worktrees/<name> yourself:
git worktree prune

# If the worktree still exists but was moved/relinked and git can't find it,
# `repair` (Git 2.29+) is the documented fix, not manual surgery on .git/worktrees/:
git worktree repair ../feature-branch
```
Manual `rm -rf .git/worktrees/<name>` is a last resort for a clearly corrupt admin
stub that `prune`/`repair` won't touch — not the normal cleanup path.

---

## 2. Scripting `git worktree add` without failure handling

**Anti-pattern:** Assuming `git worktree add` succeeds.

```bash
git worktree add ../hotfix hotfix-branch
cd ../hotfix || exit 1
# ... do work ...
```

**Why it's dangerous:**
- Branch might already be checked out in another worktree (git refuses with "already checked out")
- Path might already exist
- Disk might be full
- Detached HEAD might not be what you expected

**Defensive version:**
```bash
if ! git worktree add ../hotfix hotfix-branch 2>/dev/null; then
    echo "Worktree creation failed — branch may already be checked out or path exists" >&2
    exit 1
fi
```

---

## 3. Trap cleanup with relative or unvalidated paths

**Anti-pattern:** The sibling of the `mktemp` bug — cleaning worktrees in traps.

```bash
WORKTREE="../feature-$(date +%s)"
git worktree add "$WORKTREE" feature-branch
trap 'rm -rf "$WORKTREE"' EXIT
```

**Why it's dangerous:**
- If `git worktree add` fails and `WORKTREE` is empty/malformed, a quoted `rm -rf "$WORKTREE"` errors on an empty string (`rm: missing operand`) rather than silently targeting cwd — but an *unquoted* `rm -rf $WORKTREE` word-splits an empty value to zero arguments, which for GNU `rm` is also a no-op/error, NOT an implicit `.`. The real risk isn't a specific "resolves to cwd" mechanism at all: it's that an unvalidated variable in a destructive trap can hold anything (a partial path, a stray `*`, a value from a prior failed `cd`) by the time `EXIT` fires, and nothing between assignment and the trap firing re-checks it
- If the script `cd`s into the worktree, the relative path `../` now points somewhere else
- `rm -rf` leaves stale metadata in `.git/worktrees/`

**Defensive version:**
```bash
# NOTE: unlike mktemp, git worktree add does NOT expand "XXXX" into a random
# suffix — that string would be used verbatim as the path. Build the unique
# path yourself before calling git, and don't rely on parsing git's output
# (--quiet suppresses exactly the text a naive script would try to awk out of it).
WORKTREE="$(pwd)/../feature-$$-$(date +%s)"
git worktree add "$WORKTREE" feature-branch || { echo "Worktree creation failed" >&2; exit 1; }
WORKTREE="$(cd "$WORKTREE" && pwd -P)"  # canonicalize AFTER validation

cleanup() {
    # --force here is NOT the §13 anti-pattern: this worktree was just created by THIS script for a
    # throwaway purpose and is being torn down in its own exit trap, not force-removed out from under
    # someone else's uncommitted work. §13's warning is about scripts reaching for --force to silence
    # an error on a worktree they don't own/didn't create.
    git worktree remove --force "$WORKTREE" 2>/dev/null || true
    git worktree prune 2>/dev/null || true
}
trap cleanup EXIT
```

---

## 4. Moving worktree directories outside Git

**Anti-pattern:** Using `mv` to relocate a worktree.

```bash
mv ../feature-branch ../feature-branch-old
```

**Why it's dangerous:** The `.git` file inside the worktree contains an absolute or relative path back to the main repo. Moving it breaks that link. Git now can't find the worktree, and `git worktree remove` fails.

**Correct approach:**
```bash
# git worktree move shipped in Git 2.17.0 — use it instead of mv
git worktree move ../feature-branch ../feature-branch-renamed

# Pre-2.17: remove and re-add
git worktree remove ../feature-branch
git worktree add ../feature-branch-renamed feature-branch

# If a worktree (or the main worktree) was ALREADY moved outside git's
# knowledge — e.g. via `mv`, a backup restore, or a renamed parent dir — the
# documented fix is `repair` (Git 2.29+), not manual .git-file surgery:
git worktree repair ../feature-branch-renamed
```

---

## 5. Assuming a shared branch is free for checkout

**Anti-pattern:** `git worktree add` for a branch that's already checked out elsewhere.

```bash
# Script adds a worktree for "main" to run tests
git worktree add ../main-worktree main
```

**Why it's dangerous:** If any other worktree already has `main` checked out, this fails. This is especially problematic in CI or multi-session environments.

The occupancy rule applies within one worktree family. A separate full clone has independent refs
and may check out a branch with the same name, but the two branch refs can then diverge; matching
names do not make them shared state.

**Defensive version:**
```bash
# Use a unique branch name or detached HEAD
git worktree add --detach ../test-run-$$ main

# Or check first — parse --porcelain, not human-readable output. The plain
# `git worktree list` format is not a stable API and grep can false-match on
# pathnames that happen to contain "[main]"-like substrings.
if git worktree list --porcelain | grep -qx 'branch refs/heads/main'; then
    echo "main is already checked out in another worktree" >&2
    exit 1
fi
```

---

## 6. Garbage collection while worktrees are active

**Anti-pattern:** Running aggressive GC without considering worktrees.

```bash
git gc --aggressive --prune=now
```

**Why it's dangerous:**
- Worktrees share the same object database, and (with the exception of
  `refs/bisect`, `refs/worktree`, and `refs/rewritten`) the same refs — modern
  Git *is* worktree-aware and does scan all registered worktrees' refs/logs
  before pruning, so "gc can't see another worktree's refs" is not the
  mechanism
- The real documented risk is **concurrency**: `--prune=now` disables the
  normal grace-period safety margin, so if another process (a build in a
  linked worktree, a concurrent commit) creates an object that isn't
  referenced by a ref yet, `--prune=now` can delete it out from under that
  process — a race, not a worktree-visibility gap
- A secondary, worktree-specific risk: if a worktree directory was manually
  `rm -rf`'d without `git worktree prune`, its stale `.git/worktrees/<name>/`
  admin entry can leave git's bookkeeping out of sync with reality until
  pruned

The blast radius stops at the full-clone boundary. Another full clone has its own object database;
every linked worktree registered to the current clone does not.

**Defensive approach:**
```bash
# Always list worktrees before GC to understand what's shared
git worktree list

# Avoid --prune=now while any worktree might be mid-write (build, commit, checkout)
# Or avoid --prune=now entirely
git gc --auto  # conservative, safe
```

---

## 7. Deleting a clone's `.git` or full-clone folder

**Anti-pattern:** Treating a clone's `.git` directory—or the folder containing it—as disposable
before checking what depends on it and what exists only there.

```bash
# WRONG — destroys the database behind the current checkout and its linked worktrees
rm -rf .git
```

**Why it's dangerous:** A full clone is independent from *other clones*, not from its own linked
worktrees. Those worktrees point back to its Git directory. The clone may also hold local-only
branches, unpushed commits, stashes, reflog recovery objects, hooks, and configuration that a clean
working tree does not reveal.

**Real-world scenario:** You have three linked worktrees registered to one full clone. Someone
deletes the clone folder because its primary checkout looks idle. The linked folders remain on disk,
but their object database and refs are gone; even `git log` fails.

**Preflight a full-clone cleanup:**

```bash
CLONE_INPUT=/absolute/path/to/candidate-clone
[ -n "$CLONE_INPUT" ] || { echo "refusing: empty clone path" >&2; exit 2; }
CLONE="$(cd "$CLONE_INPUT" 2>/dev/null && pwd -P)" \
    || { echo "refusing: clone path does not resolve" >&2; exit 2; }
[ -d "$CLONE/.git" ] \
    || { echo "refusing: not a conventional full clone: $CLONE" >&2; exit 2; }

git -C "$CLONE" status --short
git -C "$CLONE" stash list
git -C "$CLONE" for-each-ref \
    --format='%(refname:short) %(upstream:short) %(upstream:track)' refs/heads
git -C "$CLONE" worktree list --porcelain
```

Stop if the output shows unique work or more than the primary checkout. Remove owned linked
worktrees with `git worktree remove`, then `git worktree prune`; never delete the parent clone out
from under them. For a standalone clone that is genuinely disposable, prefer a recoverable move to
trash over immediate recursive deletion. Automation must additionally prove that the resolved path
is a descendant of its dedicated task-clone root—not `$HOME`, a workspace root, or a path supplied
only through an unchecked variable.

---

## 8. Using fragile relative paths between checkouts

**Anti-pattern:**
```bash
cd ../feature-branch
# ... do stuff ...
../../main-repo/some-script.sh  # fragile relative path
```

**Why it's dangerous:** Worktrees and full clones can live anywhere. A relative path assumes a
directory layout that may not hold and may resolve to a different clone after one `cd`.

**Defensive approach:**
```bash
MAIN_REPO="$(git rev-parse --git-common-dir)"  # finds the shared .git
MAIN_ROOT="$(cd "$MAIN_REPO/.." && pwd)"        # parent of shared .git
```
Caveat: `"$MAIN_REPO/.."` assumes the standard "`.git` directory sits directly
under the repo root" layout. It breaks for repos using `--separate-git-dir`
or a bare common dir, where `.git` isn't a sibling of the working files. For
those layouts, don't derive the root by walking up from `--git-common-dir` —
resolve it explicitly (e.g. from `git worktree list --porcelain`, which
reports each worktree's actual path).

---

## 9. What branch deletion actually protects

**Corrected claim:** Git actually protects you here — both `git branch -d` *and* `git branch -D`
(force) refuse to delete a branch that's checked out in **any** worktree, main or linked. This was
verified empirically (Git 2.50.1): `git branch -D feature-branch` fails with
`error: cannot delete branch 'feature-branch' used by worktree at 'PATH'` (exit 1). There is no
"force-delete succeeds and leaves that worktree in detached HEAD" failure mode — that was this
doc's own error, not a real Git footgun.

```bash
git branch -d feature-branch  # fails if checked out elsewhere
git branch -D feature-branch  # ALSO fails — Git blocks this even with -D
```

**What's still worth guarding against:** the actual footgun is scripts that treat this failure as
fatal-and-unexpected instead of handling it, or that work around it by first force-removing the
occupying worktree (`git worktree remove --force`) to clear the way — which *does* discard that
worktree's uncommitted work. If a script needs to delete a branch, check occupancy first and fail
loud rather than reaching for `--force` on the worktree to unblock the branch deletion:

```bash
if git worktree list --porcelain | grep -qx "branch refs/heads/feature-branch"; then
    echo "Branch is checked out in a worktree — aborting deletion (do not --force the worktree to work around this)" >&2
    exit 1
fi
```

---

## 10. `git stash` is global within a worktree family

**Corrected claim:** Stashes are **shared** across all worktrees via the single ref `refs/stash` in
the main repo's shared ref store — `git-worktree`'s docs list `refs/bisect`, `refs/worktree`, and
`refs/rewritten` as the only per-worktree ref namespaces, and `refs/stash` is not among them. This
was verified empirically: a stash pushed in the main worktree shows up identically in
`git stash list` run from a linked worktree.

A separate full clone has a separate `refs/stash`. That isolation does not copy stashes between
clones or make either stash recoverable after its owning clone folder is removed.

```bash
# In worktree A
git stash push -m "WIP: half-done feature"

# In worktree B
git stash list  # shows the SAME stash — it is not worktree-local
git stash pop   # applies worktree A's stash onto worktree B's files — likely the WRONG tree
```

**Why it's actually dangerous:** because the stash is shared, popping it in the wrong worktree
applies changes meant for one branch/tree onto a different one — conflicts, or silent application
to unrelated files, and the stash is now consumed so worktree A can't get it back without digging
through the reflog (`git fsck --unreachable`, `git stash list` right after `pop` won't show it).

**Correct mental model:** Stashes are a single shared stack across the whole repo, indexed the same
way from every worktree. Use unmistakable `-m` messages, and run `git stash list` in the worktree
you're about to pop into (not the one you pushed from) to confirm which entry is `stash@{0}` before
popping.

---

## 11. Selective `.git` corruption and skeleton loss

**What actually happened here (2026-07-07):** this repo's main `.git` directory lost `HEAD`,
`objects/`, `refs/`, and `index`, while `hooks/`, `worktrees/`, and `config` survived intact. This
is **not** the "someone ran `rm -rf .git`" scenario in §7 above — that deletes everything uniformly.
This was a *partial* loss (consistent with a selective backup/restore gap), and none of the 10
anti-patterns above describe it or would have helped diagnose it.

**Detection — verify before trusting a repo:**
```bash
# A healthy repo has ALL of these. Any missing = don't trust git commands here yet.
for f in HEAD objects refs config; do
    [ -e ".git/$f" ] || echo "MISSING: .git/$f"
done
git fsck --no-progress 2>&1 | head -5   # first real integrity check once the above pass
```
Also check `.git/worktrees/*/gitdir` stubs for staleness — a stub with no valid path behind it (or
just a bare `commondir` file and nothing else) is metadata cruft from the same class of incident,
not a real linked worktree; `git worktree prune` clears it once the main repo is healthy again.

**Recovery — in order, verifying before each destructive-looking step:**
```bash
# 1. git init is DOCUMENTED SAFE to re-run on an existing repo: it only fills in
#    missing standard files (HEAD, objects/, refs/, description, info/exclude,
#    sample hooks) and does NOT overwrite an existing config, hooks, or any
#    working-tree file.
git init

# 2. Repopulate history from the remote — additive only, does not touch the
#    working tree or local branch refs.
git fetch origin

# 3. Before pointing any local ref at origin, or touching the working tree,
#    build an index from the candidate branch WITHOUT checkout (read-tree does
#    not write to the working tree) and diff it against what's on disk:
git read-tree origin/main
git status   # compare — do NOT `checkout -f` / `reset --hard` / `clean` yet

# 4. Only once you've confirmed the working tree matches (or you've decided
#    what to do about genuine local divergence), point the branch ref at the
#    remote — this only writes a ref, still doesn't touch the working tree:
git update-ref refs/heads/main origin/main

# 5. Restore any tracked files that are genuinely missing/corrupted on disk
#    (confirmed absent or differing from origin, not local WIP) from the
#    remote's tree — scoped to just those paths, not a blanket checkout:
git checkout origin/main -- path/to/missing-file
```
The critical discipline: steps 1–3 are provably non-destructive to the working tree (`init` fills
gaps only, `fetch` writes only to `.git/objects` and remote-tracking refs, `read-tree` populates the
index without touching files). Do not reach for `checkout -f`, `reset --hard`, or `clean` until
you've diffed and know exactly what you'd be overwriting — those commands assume the working tree is
disposable, which after a partial-corruption incident it specifically is not.

---

## 12. Run the full gate only in a disposable full clone

**Rule:** Run `validate.sh` and full `ci-local.sh` only in a separate full clone whose loss will not
damage active work. A linked worktree exposes its parent clone; a valued full clone exposes itself.
Neither is the right containment boundary for a fixture-heavy suite.

**Anti-patterns:**

```bash
# WRONG: the linked worktree shares the parent clone's .git.
git worktree add ../repo-feature -b feature origin/development
(cd ../repo-feature && bash validate.sh)

# ALSO WRONG: this is a full clone, but it holds state the operator cares about.
(cd /path/to/primary-clone && bash validate.sh)
```

### Why the boundary matters

A linked worktree shares the parent clone's config, refs, objects, hooks, and most reflogs. A suite
that escapes a fixture therefore writes into the parent repository. A separate full clone stops
that cross-clone blast radius, but the suite can still corrupt the clone in which it runs; the word
*disposable* is load-bearing.

On 2026-08-19, a gate run from a linked worktree escaped its fixture and changed the parent clone:

- `core.bare` became `true`
- `remote.origin.url` pointed at a temporary bare repository that was later deleted
- every `refs/remotes/origin/*` ref was deleted
- local `development` and `main` moved to fixture commits
- fixture files appeared in the working tree

The objects survived, but the run was no longer attributable to the clone that started it. This is
the GH-564/GH-567 failure class: an empty or invalid fixture path reaches the caller's repository.
A suite can also behave differently in a linked worktree because `.git` is a file there, not a
directory. A linked-worktree run is both unsafe and an invalid measurement.

### What XYZ enforces now

- [`validate.sh`](validate.sh) and [`ci-local.sh`](ci-local.sh) refuse linked worktrees with exit 2
  before the suite starts. They compare the checkout's absolute Git directory with its resolved
  common directory, checking both the script root and invocation directory where applicable.
- `XYZ_ALLOW_WORKTREE_GATE=1` is an announced override. It changes the refusal, not the isolation;
  use it only when the entire parent clone and every linked worktree registered to it are disposable.
- [`test/gh35-test-tiers.sh`](test/gh35-test-tiers.sh) pins the refusal, override, absolute-path
  invocation, and normal-full-clone control.
- The full gate captures clone identity before the suite and asserts it afterward. Drift in
  `core.bare`, `origin`, local user identity, or `HEAD` fails the run. This detects corruption after
  it happens; it does not protect a valued clone from the mutation.

### Correct workflow

1. Edit and commit in the assigned worktree or task clone.
2. Bring that exact commit into a dedicated full clone; do not substitute a similarly named branch.
3. Confirm the gate clone has a real `.git/` directory, a clean working tree, and no registered
   linked worktrees beyond its primary checkout.
4. Run the gate from that clone. -> expect the linked-worktree guard to stay silent and the final
   clone-identity invariant to pass.
5. If clone identity changes, discard the gate result and the disposable clone, create a fresh full
   clone, and rerun at the same concurrency. Repairing the damaged clone does not rehabilitate the
   prior result.

Tracked as [GH-45](https://github.com/HiQS-Suite/XYZ-forge/issues/45), with the broader fixture
containment and identity work tracked by GH-564/GH-567.

---

## 13. Other worktree and full-clone footguns

- **Untracked or modified files block `git worktree remove`.** It refuses if the worktree has any
  uncommitted changes; `--force` is required to proceed — and `--force` silently discards those
  changes. Never default a script to `--force` as a way to "fix" a remove that failed.
- **`git worktree move` does not support worktrees containing submodules** — the relative links
  back to `.git/modules/` break. Don't script a blind `move` without checking `.gitmodules` first.
- **`--force` on `add` / `move` / `remove` overrides the exact safeguards this guide teaches** (branch
  occupancy, dirty-worktree protection, path collisions). Treat any script that reaches for `-f`/`--force`
  to silence a worktree error as a signal to stop and understand *why* git refused, not a shortcut.
- **Lock worktrees on removable/unstable storage.** `git worktree lock <path>` prevents `git worktree
  prune` (including the prune that `git gc` can trigger) from reaping a worktree's metadata just
  because its directory is temporarily unreachable (unmounted drive, network share).
- **Prefer `git worktree list --porcelain` over the human-readable format** in any script. The
  plain-text table is not a stable API; porcelain output is machine-parseable and won't false-match
  on branch/path substrings the way a `grep` over the table can.
- **A clean clone can still hold unique state.** `git status --short` does not show unpushed branch
  tips, stashes, reflog-only objects, hooks, or local configuration. Check them before cleanup (§7).
- **Do not move a full-clone folder while it owns linked worktrees.** Their administrative files
  point back to the clone's common directory. If a clone was already moved, use `git worktree
  repair` with the real checkout paths; do not hand-edit `.git` files.
- **Same branch name does not mean same branch state across full clones.** Verify the exact commit
  SHA before grading, publishing, or deleting either clone.

---

## Golden rules

1. **Always use `git worktree remove`/`prune`/`repair`, never manual `rm -rf` or `mv`** on worktree
   directories or `.git/worktrees/<name>` — repair (2.29+) and move (2.17+) are git's own tools for
   exactly these cases
2. **Validate before destroying** — resolve the exact path, prove it is inside the operation's
   dedicated root, and inventory worktree dependencies plus local-only state before cleanup
3. **Be path-aware in traps** — canonicalize paths early, validate them, and never `rm -rf` on
   relative paths or unvalidated variables
4. **Each full clone's `.git` is the source of truth for its worktree family** — protect it like a
   database, and verify its skeleton (`HEAD`/`objects`/`refs`/`config`) before trusting commands run
   against it (§11); partial corruption is a real failure mode, not just total deletion
5. **Linked worktrees share almost everything — objects, refs, AND stashes/logs.** The only genuinely
   per-worktree ref namespaces are `refs/bisect`, `refs/worktree`, and `refs/rewritten`. Don't assume
   isolation you don't have (§10); Git also actively *protects* shared state you might expect it not
   to (§9's branch-delete block). Separate full clones do not share that state.
6. **Prefer git's own recovery tools over hand-surgery on `.git/`** — `init` (safe to re-run),
   `fetch`, `prune`, `repair` — and reach for `read-tree`/`diff`/`status` to inspect before any
   command that can overwrite the working tree (`checkout -f`, `reset --hard`, `clean`)
7. **Script against `--porcelain` output, never the human-readable table** — `git worktree list`'s
   plain format is not a stable, grep-safe API
8. **Run the full test gate only in a separate disposable full clone** (§12) — never in a linked
   worktree or a primary clone whose state matters. The identity bracket detects damage; it does not
   make damage acceptable.

---

## See also

- [Git Clone Documentation](https://git-scm.com/docs/git-clone)
- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [git-init](https://git-scm.com/docs/git-init) — confirms re-running `init` on an existing repo is safe/non-clobbering
- [git-fsck](https://git-scm.com/docs/git-fsck) — integrity check, first step after any suspected `.git` corruption
- [git-gc](https://git-scm.com/docs/git-gc) — documents the `--prune=now` concurrency risk cited in §6

---

Licensed under: Apache 2.0   
Copyright 2026 Neochrome, Inc.  
