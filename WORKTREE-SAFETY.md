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
- [14. Recovering a checkout that is already gone](#14-recovering-a-checkout-that-is-already-gone)
- [15. Audit trails that make the next incident solvable](#15-audit-trails-that-make-the-next-incident-solvable)
- [16. Containment: limiting blast radius outside Git](#16-containment-limiting-blast-radius-outside-git)
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

### What the clone boundary does not cover

A disposable clone contains everything the suite does *to a repository*. It does not contain what the
suite does to the machine, and the identity invariant above only watches Git state.

Observed 2026-08-30: running the full gate from a throwaway clone repointed six real symlinks under
`~/.gemini/**/skills/` at that clone, because a skill-install suite installs from whatever checkout it
is running in. The gate passed and reported nothing unusual — correctly, since no Git state drifted.
Step 5 below then says to discard the clone, which is exactly what turns those symlinks into dangling
links pointing at a deleted temporary directory. The damage lands outside Git, outside the clone, and
after a green run.

This is §16's point applied to the gate itself: a suite that writes to `$HOME` is not contained by
choosing where its `.git` lives. Two practical consequences:

- Before deleting a gate clone, check whether the run installed anything pointing back at it:
  `find ~ -maxdepth 6 -type l -lname '*<clone-path-fragment>*' 2>/dev/null`.
- Prefer running such suites in the checkout that will still exist afterwards, or give the gate clone a
  scratch `HOME` so home-directory writes land somewhere disposable too.

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

## 14. Recovering a checkout that is already gone

Sections 1–13 prevent damage. This section assumes prevention failed: a linked worktree or a full-clone
folder is missing, and the first job is to recover the bytes and establish a timeline. Work in this
order — the cheapest, least destructive sources first.

**Do not re-run the agent, re-clone into the same path, or `git init` the parent directory yet.** Each
of those writes to the volume and can overwrite the free blocks a recovery would have used.

### 14.1 Local APFS snapshots and Time Machine

macOS can keep automatic local APFS snapshots even with no backup disk attached, which makes this the
highest-yield first check. It is not guaranteed: `tmutil localsnapshot` only covers APFS volumes
included in a configured Time Machine backup, so a machine that has never been configured may have
none. Check first, and never treat a snapshot as a precondition that must exist.

```bash
# What point-in-time views exist on the boot volume?
tmutil listlocalsnapshots /

# Mount one read-only and copy files out. NOTE: the tool is mount_apfs -s,
# not "mount_apfs_snapshot" — the latter does not exist.
mkdir -p /tmp/snap
sudo mount_apfs -s com.apple.TimeMachine.2026-08-27-073000 / /tmp/snap
ls "/tmp/snap/Users/$USER/Documents/GH Repos/"

# When finished
sudo umount /tmp/snap
```

Copy out of the snapshot; never work inside it. If an external Time Machine disk is attached, browse it
in Finder instead — same data, friendlier interface.

### 14.2 Trash, then any sync provider

`rm -rf` does not use the Trash, but a Finder-driven or script-driven move might have. Check `~/.Trash`
before assuming permanent loss. If the path lived under Dropbox, iCloud Drive, Google Drive, or a NAS
sync root, check that provider's web UI — most keep deleted-file and version history well past the
local deletion.

### 14.3 Git can rebuild more than you think

A destroyed *working tree* need not mean destroyed *history* — but only if the objects survive
somewhere, and each source has a real limit. A **remote** carries only what was pushed and is still
reachable there. A **linked worktree is not an independent object store**: it helps only if the parent
clone's common Git directory survived, which is exactly what §7 warns you can destroy. A **sibling full
clone** is independent, and is the strongest of the three. Before treating a loss as total:

```bash
# Does the remote still carry the work?
git ls-remote origin 'refs/heads/*'

# Does a sibling full clone or the parent of a linked worktree still hold the objects?
git --git-dir=/path/to/other/clone/.git log --oneline --all | head

# Unreferenced commits in a surviving clone — the reflog MAY outlive branch deletion.
# Retention is finite (gc.reflogExpire, default 90d; 30d unreachable) and `git gc`
# can prune it, so run this early rather than after more repo activity.
git --git-dir=/path/to/other/clone/.git reflog --date=iso | head -50
git --git-dir=/path/to/other/clone/.git fsck --lost-found
```

This is the payoff for §7 and §12: if the destroyed folder was a *disposable* full clone, recovery is a
fresh `git clone` and nothing was lost. The recovery cost of an incident is set by the discipline applied
before it.

### 14.4 This harness's two non-Git stores

Before concluding anything is unrecoverable, check the two places this harness keeps data that `git`
will never show you.

**`.tick/orphan-backups/` — the relay's pre-revert copies.** A driven turn reverts any edit outside its
allowlist, and since 2026-07-18 it copies the file's prior content out first rather than discarding it
(`relay-automation/relay-turn-lib.sh`). If a hand-edit was made in a clone while a turn was in flight
there, this is where it went:

```bash
ls -lt .tick/orphan-backups/ | head          # newest incident first
find .tick/orphan-backups -name '*<filename>*'
```

**Vendored `.xyz/` has no Git recovery at all.** It is gitignored (`.gitignore`), so nothing inside it
has a reflog, a stash, or an `fsck --lost-found` behind it — a destroyed relay thread or `.tick/` log
under `.xyz/` is simply gone. `xyz-sync.sh update` preserves a known list of runtime paths across the
rebuild, and anything not on that list is deleted unread. Snapshots (§14.1) are the only recovery path
for this directory, which is why §15.4's pre-run snapshot matters more here than anywhere else.

### 14.5 Correlate with shell history

```bash
grep -n -E 'rm -rf|git clean|git worktree remove|reset --hard|rsync.*--delete' ~/.zsh_history
```

Without `EXTENDED_HISTORY` (§15.1) these lines carry no timestamps, so you get sequence but not time.
Enable it now so the *next* incident has both.

### 14.6 Unified logging

macOS retains system log data for a limited window, so capture this early:

```bash
# Everything a given process did in the last few hours
log show --last 3h --predicate 'process == "node"' --info --style compact

# Narrow to a path fragment that appears in error messages
log show --last 3h --style compact | grep -i 'GH Repos'
```

Unified logging will not hand you "this command deleted this folder." It gives process names, restart and
crash events, and paths quoted in errors — enough to bound the window and identify the actor.

---

## 15. Audit trails that make the next incident solvable

§14 is only as good as the evidence that exists before the incident. All three of these are cheap and
worth enabling once.

### 15.1 Timestamped shell history

```zsh
# ~/.zshrc
setopt EXTENDED_HISTORY        # record start time and duration per command
setopt INC_APPEND_HISTORY      # write as commands run, not only at shell exit
setopt HIST_IGNORE_DUPS
```

`INC_APPEND_HISTORY` matters as much as the timestamps: without it, a shell killed mid-incident —
which is exactly what happens when an agent run goes wrong — never flushes its history to disk.

### 15.2 An agent action log

Have the harness, not the model, record every destructive intent before it executes. Log the resolved
absolute path, the operation, and the justification:

```python
import datetime, json, os, pathlib

LOG = pathlib.Path(os.environ.get("AGENT_ACTION_LOG", "~/agent-logs/actions.jsonl")).expanduser()

def log_action(action: str, **details):
    LOG.parent.mkdir(parents=True, exist_ok=True)
    entry = {"ts": datetime.datetime.now(datetime.timezone.utc).isoformat(),
             "action": action, **details}
    with LOG.open("a") as f:                     # append-only, one JSON object per line
        f.write(json.dumps(entry) + "\n")
        f.flush()
        os.fsync(f.fileno())                     # survive a hard kill
```

The `fsync` is the point. A buffered log loses precisely the last few entries — the ones describing the
operation that killed the process.

### 15.3 Filesystem-level events with `eslogger`

`eslogger` ships with macOS 13+ and reports Endpoint Security events directly. It requires root and Full
Disk Access for the invoking terminal, and it is verbose — treat it as a diagnostic you switch on while
hunting a specific problem, not a permanent daemon:

```bash
# Deletion-and-move audit. Subscribe ONLY to what the selector actually handles.
sudo eslogger unlink rename 2>/dev/null \
  | jq -c --arg re 'GH Repos|agent-workspaces' '
      [ .event.unlink.target.path,
        .event.rename.source.path,
        .event.rename.destination.new_path,
        .event.rename.destination.existing_file.path ]
      | map(select(. != null))
      | select(any(.[]; test($re)))' \
  >> ~/agent-logs/file-events.jsonl
```

Three things this deliberately gets right, because the obvious version gets them wrong:

- **Do not subscribe to an event you do not extract.** Adding `create` to the command line while the
  selector has no `.event.create` arm produces a log that looks complete and silently drops every
  creation. Either handle it or leave it unsubscribed.
- **A rename has two ends.** Filtering only on `.source.path` misses a move *into* a watched root.
  `rename` reports its destination as either `new_path` or an `existing_file` being clobbered,
  so check both.
- **This JSON is not a stable API.** Apple documents the Endpoint Security event schema as subject to
  change, so treat the field paths above as verified-at-time-of-writing and confirm against
  `eslogger --list-events` and a sample event on your OS version before relying on them.

This tells you the exact time, full path, and responsible process for every delete — the one source that
attributes a deletion to a process rather than inferring it. It cannot tell you which prompt caused it;
that is what §15.2 is for.

### 15.4 Snapshot before a destructive run

```bash
tmutil localsnapshot && echo "snapshot taken: $(date -u +%FT%TZ)"
```

Cheap (copy-on-write, seconds) and the single highest-value pre-flight for any mass refactor, migration,
or cleanup. Wire it into the harness ahead of destructive lanes rather than remembering it by hand.

Two limits to encode rather than assume. Snapshots are pruned automatically under disk pressure, so
they are a short-horizon undo buffer, never a backup. And the command fails on a machine with no
suitable Time Machine configuration — a harness preflight should **report** that it could not snapshot
and carry on, not treat snapshot support as universally available:

```bash
if tmutil localsnapshot 2>/dev/null | grep -q 'Created local snapshot'; then
  echo "pre-run snapshot: ok"
else
  echo "pre-run snapshot: UNAVAILABLE — proceeding without an undo buffer" >&2
fi
```

---

## 16. Containment: limiting blast radius outside Git

Git-level care (§1–§13) does not help when a command never reaches Git. These limits are what keep a
mistaken path from reaching valued data at all.

### 16.1 Give agents a dedicated root

**Anti-pattern:** letting an agent run with its working directory anywhere under `$HOME`, so a
mis-resolved relative path lands on `~/Documents` or `~/Desktop`.

Keep agent-writable work under one root, and require an explicit override to leave it:

```python
from pathlib import Path

SAFE_ROOTS = [Path.home() / "agent-workspaces", Path.home() / "Documents" / "GH Repos"]
NEVER_DELETE = {Path.home(), Path.home() / "Documents", Path.home() / "Desktop", Path("/")}

def _within(child: Path, parent: Path) -> bool:
    """True only if child is STRICTLY inside parent. Python 3.8-compatible:
    Path.is_relative_to() was added in 3.9, and it also returns True for
    child == parent, which would authorize deleting the safe root itself."""
    if child == parent:
        return False
    try:
        child.relative_to(parent)
        return True
    except ValueError:
        return False

def assert_deletable(path: Path):
    p = path.resolve()                                   # resolve symlinks BEFORE comparing
    if p in {r.resolve() for r in NEVER_DELETE}:         # resolve BOTH sides, or the test misses
        raise RuntimeError(f"refusing to delete a protected root: {p}")
    if not any(_within(p, root.resolve()) for root in SAFE_ROOTS):
        raise RuntimeError(f"refusing to delete outside safe roots: {p}")
    log_action("file_delete", path=str(p))
```

Four things here are load-bearing, and three of them are defects this example had in an earlier draft:

- **Resolve before comparing.** Without it a path inside the safe root can still point outside it via a
  symlink — the same class of defect as §3's unvalidated trap paths.
- **Resolve both sides.** Comparing a resolved `p` against unresolved `NEVER_DELETE` members silently
  misses when `~` or any parent is itself a symlink.
- **Component-aware containment, not string prefixes.** `str.startswith` accepts
  `/Users/me/Documents-backup` as being inside `/Users/me/Documents`.
- **Reject `child == parent`.** `Path.is_relative_to` returns `True` for a path against itself, so the
  obvious one-liner authorizes `rm -rf ~/Documents/GH Repos` — deleting *every* repo — as "inside a safe
  root." `_within` rejects it explicitly. It also keeps the check working on Python 3.8, this repo's
  declared floor (`README.md:198`); `is_relative_to` needs 3.9+.

`resolve()` is non-strict by default, so it still returns a usable path when the leaf does not exist.

**What this check does not do — know the boundary before you rely on it.** `assert_deletable` validates
a path at one instant; the caller deletes at a later one. Anything able to change what a path points at
in between — retargeting a symlink inside a safe root, swapping a parent directory — redirects the
delete to somewhere the check already approved. That is a genuine time-of-check-to-time-of-use gap, and
it is not closable at this layer.

It is also outside what this guard is for. The threat model here is **a mistaken path, not a hostile
one**: an agent resolving `../..` one level too far, or interpolating an empty variable. Against that,
a one-instant check is sufficient and worth having. Against a local attacker deliberately racing your
process, it is not — and no amount of pre-validation makes it so. If that is your threat model, the
answer is §16.4's isolation or an `openat`-style handle-based delete, not a better string check.

### 16.2 Make critical directories refuse writes

```bash
chflags uchg ~/ImportantData          # set the immutable flag
chflags nouchg ~/ImportantData        # release it deliberately, for a known operation
```

`rm -rf` fails against `uchg` even as your own user, which turns a silent catastrophe into an error
message. It is not a security boundary — anyone able to run `chflags` can undo it — but it is an
effective guard against an unthinking command.

### 16.3 Wrap destructive commands, and prefer dry-run first

Put a wrapper earlier on `PATH` than the real binary so an unqualified `rm -rf` cannot run unattended:

```bash
#!/bin/zsh
# ~/bin/safe-rm — refuses ANY recursive delete without an explicit acknowledgement
set -euo pipefail

ack=0 recursive=0 end_of_opts=0
for arg in "$@"; do
  [[ "$arg" == "--i-mean-it" ]] && { ack=1; continue; }
  (( end_of_opts )) && continue
  [[ "$arg" == "--" ]] && { end_of_opts=1; continue; }
  case "$arg" in
    --recursive) recursive=1 ;;               # GNU spelling; macOS /bin/rm rejects it, but flag it anyway
    --*) ;;                                   # any other long option: not recursive
    -*[rR]*) recursive=1 ;;                   # -r, -R, -rf, -fr, -Rv, and every other cluster
  esac
done

if (( recursive && ! ack )); then
  print -u2 "safe-rm: recursive delete requires --i-mean-it"
  print -u2 "  command: rm $*"
  exit 1
fi
exec /bin/rm "${@:#--i-mean-it}"     # zsh: drop the sentinel, then exec the real rm
```

The gate is on **`-r`/`-R` alone**, not on the combination of `-r` and `-f`. An earlier draft matched
only single words containing both letters, which let `safe-rm -r target`, `safe-rm -R target`, and
`safe-rm -r -f target` (two separate words) through ungated — the wrapper advertised a guarantee it did
not provide, which is worse than no wrapper. `-r` without `-f` still destroys a directory tree, so it
needs the same acknowledgement. Options are scanned only up to `--`, so a file literally named `-rf`
after the separator does not trip the gate — correct, since `rm -- -rf` deletes one file, not a tree.

One known wart, in the safe direction: a file literally named `--i-mean-it` is stripped along with the
sentinel, so it survives instead of being deleted. That is a false negative, not a gate bypass, and it
is the right way round for a safety wrapper to fail.

Pair it with a two-phase habit for any bulk operation: run with `--dry-run`, read the plan it prints,
then re-run for real. An agent that cannot articulate what it is about to delete should not delete it.

### 16.4 Isolate the environment when the stakes justify it

- **Containers** — mount only the specific project directory into the container; everything else is
  simply absent from the filesystem the agent can see. Lowest overhead of the three.
- **Virtual machines** — a full VM with a snapshot taken before each session, reverted afterwards.
  Heaviest, and the only option that also contains a compromised toolchain.
- **A separate macOS user account** — run agents as a distinct user whose home directory holds only
  agent workspaces. POSIX permissions then do the enforcing, with no wrapper to bypass.

For this harness specifically, §12's disposable full clone is already the containment boundary for
mutation-heavy gates. These options extend the same principle to everything the agent does outside Git.

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
9. **Assume prevention will eventually fail, and pay the small costs that make recovery possible** —
   timestamped shell history, an `fsync`ed action log, and a `tmutil localsnapshot` before destructive
   runs (§15). After a loss, capture snapshots and logs *before* re-running anything (§14).
10. **Constrain the agent's writable world outside Git, not just inside it** — a resolved-path safe-root
    check, `chflags uchg` on data that should not move, and containment for mutation-heavy work (§16).
    Resolve symlinks before any path comparison; `startswith` on a path string is not containment.

---

## See also

- [Git Clone Documentation](https://git-scm.com/docs/git-clone)
- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [git-init](https://git-scm.com/docs/git-init) — confirms re-running `init` on an existing repo is safe/non-clobbering
- [git-fsck](https://git-scm.com/docs/git-fsck) — integrity check, first step after any suspected `.git` corruption
- [git-gc](https://git-scm.com/docs/git-gc) — documents the `--prune=now` concurrency risk cited in §6
- [git-reflog](https://git-scm.com/docs/git-reflog) — the recovery path in §14.3 for commits no branch points at
- [tmutil(8)](https://keith.github.io/xcode-man-pages/tmutil.8.html) — `listlocalsnapshots` and `localsnapshot`, §14.1 and §15.4
- [mount_apfs(8)](https://keith.github.io/xcode-man-pages/mount_apfs.8.html) — `-s` mounts a named snapshot read-only (§14.1)
- [chflags(1)](https://keith.github.io/xcode-man-pages/chflags.1.html) — the `uchg` immutable flag used in §16.2
- [Apple: Endpoint Security](https://developer.apple.com/documentation/endpointsecurity) — the framework behind `eslogger` (§15.3)

---

License: See [`LICENSE`](LICENSE) and [`LICENSE-COMMERCIAL.md`](LICENSE-COMMERCIAL.md)  
Copyright 2026 Neochrome, Inc.  
