# RELAY · Safety docs and worktree full-clone QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-27.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(safety-docs-agy-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **safety-docs-agy-qa.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-08-27

### Artifact — safety-docs-agy-qa.md
````
# Safety documentation QA packet

Review the embedded patch against the repository's existing house style and safety context.

Answer these questions explicitly:

1. Is the compact safety-and-warranty notice accurate, concise, consistent across all three docs, and aligned with the applicable license?
2. Does the AGENTS.md danger block provide useful immediate guidance without contradicting the detailed rails below it?
3. Is WORKTREE-SAFETY.md coherently merged, free of duplicated guidance, correctly scoped to linked worktrees and full clones, and navigable through its TOC?
4. Are any commands, recovery steps, or claims unsafe, technically inaccurate, overly absolute, or likely to cause data loss?
5. Does README.md avoid promises that conflict with the no-warranty/no-data-integrity-guarantee notice?

Return a severity-ranked finding list with exact file/section references. If there are no blocking or material findings, say PASS and list only optional polish separately.

## Patch under review

```diff
diff --git a/AGENTS.md b/AGENTS.md
index 48c66612..2888d199 100644
--- a/AGENTS.md
+++ b/AGENTS.md
@@ -1,6 +1,26 @@
 # AGENTS.md
 
-Read `WORKTREE-SAFETY.md` for important Git Worktree Dangerous actions to avoid.
+## Danger: commands agents must not run
+
+- Never run `git reset --hard`, `git checkout -- <path>`, or a tree-wide `git stash` in a checkout
+  whose state matters; they overwrite tracked work or hide shared worktree-family state.
+- Never run `rm -rf`, `find ... -delete`, or equivalent recursive cleanup through an empty,
+  unresolved, relative, root, home, workspace, or otherwise unproven target path.
+- Never remove or move a linked worktree with `rm -rf` or `mv`, and never hand-delete
+  `.git/worktrees/*`; use `git worktree remove` / `move` / `prune` / `repair`.
+- Never run sandboxed `git switch --track` or `git branch -D` directly; wrap the complete command
+  with `utils/git-sandbox-guard.sh --repo <root> -- <git command>`.
+- Never delete or move a full-clone folder until its working tree, stashes, local refs, and registered
+  worktrees prove that it contains no unique or depended-on state.
+- Never run `validate.sh` or `test/*.sh` from a linked worktree or a full clone whose state matters;
+  run mutation-heavy gates only in a separate disposable full clone.
+
+Read [`WORKTREE-SAFETY.md`](WORKTREE-SAFETY.md) for the rationale, recovery paths, and safe patterns.
+
+> **Safety and warranty:** XYZ Forge is provided **“AS IS,” without warranty**, under the applicable
+> license. Coding models may choose commands through their own runtimes and safety controls, outside
+> the intended harness workflow. XYZ Forge cannot guarantee model behavior or data integrity; maintain
+> tested, independent backups and follow industry-standard backup and recovery practices.
 
 Read `ROUTER.md` first for startup order and canonical files.
 
diff --git a/README.md b/README.md
index 462cb091..8291adf1 100644
--- a/README.md
+++ b/README.md
@@ -1,14 +1,20 @@
 # XYZ — Multi-Agent Coordination Beta
 
 **XYZ lets several AI coding agents — Claude Code, Codex, and agy (Google's Antigravity CLI) — work
-on the same repo at the same time without overwriting each other's work.**
+on the same repo concurrently, with path claims and isolated turns that reduce accidental overwrites.**
+
+> **Safety and warranty:** XYZ Forge is provided **“AS IS,” without warranty**, under the applicable
+> license. Coding-agent automation is inherently risky: models may choose commands through their own
+> runtimes and safety controls, outside the intended harness workflow. XYZ Forge cannot guarantee
+> model behavior or data integrity; maintain tested, independent backups and follow industry-standard
+> backup and recovery practices.
 
 ## What XYZ is
 
 It's built in two layers:
 
-- **`tick`** — the kernel: a tiny local event-log CLI that hands out collision-free, path-scoped
-  work claims, so two agents never edit the same thing at once. No server, no API keys, no remote.
+- **`tick`** — the kernel: a tiny local event-log CLI that hands out path-scoped work claims to
+  serialize overlapping edits. No server, no API keys, no remote.
 - **`relay-automation/`** — the product on top of `tick`: it runs agents in **turns** (one builds,
   another reviews) headlessly, so you can hand a task to Codex or agy and let them iterate toward
   done without babysitting the handoff.
diff --git a/WORKTREE-SAFETY.md b/WORKTREE-SAFETY.md
index f8e58d01..594f00b1 100644
--- a/WORKTREE-SAFETY.md
+++ b/WORKTREE-SAFETY.md
@@ -1,15 +1,59 @@
-# Git Worktree Safety Guide for Agents
+# Git Worktree and Full-Clone Safety Guide for Agents
 
 Author: Noel Saw (@noelsaw1)  
-Licensed under: Apache 2.0  
+License: See [`LICENSE`](LICENSE) and [`LICENSE-COMMERCIAL.md`](LICENSE-COMMERCIAL.md)
 Copyright 2026 Neochrome, Inc.  
 
-> **Purpose:** Prevent destructive footguns when scripting with Git worktrees.  
-> **Scope:** Shell scripts, CI pipelines, and agent workflows that create, manage, or clean up worktrees.
+> **Purpose:** Prevent destructive checkout and repository-state failures in agent-driven Git workflows.
+> **Scope:** Shell scripts, CI pipelines, and agent workflows that create, use, verify, move, or
+> remove linked worktrees and full-clone folders.
+
+> **Safety and warranty:** XYZ Forge is provided **“AS IS,” without warranty**, under the applicable
+> license. Coding models may choose commands through their own runtimes and safety controls, outside
+> the intended harness workflow. These mitigations cannot guarantee model behavior or data integrity;
+> maintain tested, independent backups and follow industry-standard backup and recovery practices.
+
+---
+
+## Table of contents
+
+- [Safety model: linked worktrees and full clones](#safety-model-linked-worktrees-and-full-clones)
+- [1. The `rm -rf` worktree-path trap](#1-the-rm--rf-worktree-path-trap)
+- [2. Scripting `git worktree add` without failure handling](#2-scripting-git-worktree-add-without-failure-handling)
+- [3. Trap cleanup with relative or unvalidated paths](#3-trap-cleanup-with-relative-or-unvalidated-paths)
+- [4. Moving worktree directories outside Git](#4-moving-worktree-directories-outside-git)
+- [5. Assuming a shared branch is free for checkout](#5-assuming-a-shared-branch-is-free-for-checkout)
+- [6. Garbage collection while worktrees are active](#6-garbage-collection-while-worktrees-are-active)
+- [7. Deleting a clone's `.git` or full-clone folder](#7-deleting-a-clones-git-or-full-clone-folder)
+- [8. Using fragile relative paths between checkouts](#8-using-fragile-relative-paths-between-checkouts)
+- [9. What branch deletion actually protects](#9-what-branch-deletion-actually-protects)
+- [10. `git stash` is global within a worktree family](#10-git-stash-is-global-within-a-worktree-family)
+- [11. Selective `.git` corruption and skeleton loss](#11-selective-git-corruption-and-skeleton-loss)
+- [12. Run the full gate only in a disposable full clone](#12-run-the-full-gate-only-in-a-disposable-full-clone)
+- [13. Other worktree and full-clone footguns](#13-other-worktree-and-full-clone-footguns)
+- [Golden rules](#golden-rules)
+- [See also](#see-also)
+
+## Safety model: linked worktrees and full clones
+
+The boundary that matters is the Git directory, not the number of folders on disk. A linked
+worktree gives a branch its own working files but shares repository state with its parent. A full
+clone owns a separate Git directory, but it is safe to destroy only when it contains no unique work
+and no linked worktrees depend on it.
+
+| Checkout type | Git storage | What it isolates | Safe default use |
+|---|---|---|---|
+| Primary checkout of a full clone | `.git/` directory | Independent from other full clones; shared with its own linked worktrees | Valued repository state; do not treat as a test fixture |
+| Linked worktree | `.git` file pointing into the parent clone | Working-tree files only | Editing and committing within a known branch lane |
+| Disposable full clone | Independent `.git/` directory with no unique state or dependent worktrees | Working tree and Git config, refs, objects, hooks, and stashes | Mutation-heavy gates and destructive experiments |
+
+“Disposable” is an operator-owned lifecycle, not a Git property. A normal clone becomes valued as
+soon as it holds an unpushed commit, stash, reflog-only recovery object, local configuration, or a
+linked worktree that another process still uses.
 
 ---
 
-## 1. The "rm -rf worktree path" trap
+## 1. The `rm -rf` worktree-path trap
 
 **Anti-pattern:** Deleting a worktree by just removing its directory.
 
@@ -70,7 +114,7 @@ fi
 
 ---
 
-## 3. Trap cleaning worktrees with `rm -rf` and relative paths
+## 3. Trap cleanup with relative or unvalidated paths
 
 **Anti-pattern:** The sibling of the `mktemp` bug — cleaning worktrees in traps.
 
@@ -108,7 +152,7 @@ trap cleanup EXIT
 
 ---
 
-## 4. Moving/renaming worktree directories outside of git
+## 4. Moving worktree directories outside Git
 
 **Anti-pattern:** Using `mv` to relocate a worktree.
 
@@ -135,7 +179,7 @@ git worktree repair ../feature-branch-renamed
 
 ---
 
-## 5. Assuming `main` (or any shared branch) is free for checkout
+## 5. Assuming a shared branch is free for checkout
 
 **Anti-pattern:** `git worktree add` for a branch that's already checked out elsewhere.
 
@@ -146,6 +190,10 @@ git worktree add ../main-worktree main
 
 **Why it's dangerous:** If any other worktree already has `main` checked out, this fails. This is especially problematic in CI or multi-session environments.
 
+The occupancy rule applies within one worktree family. A separate full clone has independent refs
+and may check out a branch with the same name, but the two branch refs can then diverge; matching
+names do not make them shared state.
+
 **Defensive version:**
 ```bash
 # Use a unique branch name or detached HEAD
@@ -162,7 +210,7 @@ fi
 
 ---
 
-## 6. Garbage collection while worktrees exist
+## 6. Garbage collection while worktrees are active
 
 **Anti-pattern:** Running aggressive GC without considering worktrees.
 
@@ -186,6 +234,9 @@ git gc --aggressive --prune=now
   admin entry can leave git's bookkeeping out of sync with reality until
   pruned
 
+The blast radius stops at the full-clone boundary. Another full clone has its own object database;
+every linked worktree registered to the current clone does not.
+
 **Defensive approach:**
 ```bash
 # Always list worktrees before GC to understand what's shared
@@ -198,29 +249,52 @@ git gc --auto  # conservative, safe
 
 ---
 
-## 7. Deleting the main worktree's `.git` directory
+## 7. Deleting a clone's `.git` or full-clone folder
 
-**Anti-pattern:** Treating the main `.git` directory as just another git database.
+**Anti-pattern:** Treating a clone's `.git` directory—or the folder containing it—as disposable
+before checking what depends on it and what exists only there.
 
 ```bash
-# Thinking you're cleaning up an old clone
+# WRONG — destroys the database behind the current checkout and its linked worktrees
 rm -rf .git
 ```
 
-**Why it's dangerous:** All linked worktrees reference the main repo's object database via their `.git` files. Deleting the main `.git` irrecoverably breaks every linked worktree.
+**Why it's dangerous:** A full clone is independent from *other clones*, not from its own linked
+worktrees. Those worktrees point back to its Git directory. The clone may also hold local-only
+branches, unpushed commits, stashes, reflog recovery objects, hooks, and configuration that a clean
+working tree does not reveal.
 
-**Real-world scenario:** You have 3 worktrees off a main checkout. Someone decides to "clean up" by deleting the main checkout folder. Now all 3 worktrees are orphaned with no object database, and even `git log` fails.
+**Real-world scenario:** You have three linked worktrees registered to one full clone. Someone
+deletes the clone folder because its primary checkout looks idle. The linked folders remain on disk,
+but their object database and refs are gone; even `git log` fails.
+
+**Preflight a full-clone cleanup:**
 
-**Precaution:**
 ```bash
-# Before removing any repo, check if it's the primary for worktrees
-git worktree list
-# If other worktrees reference this one's objects, don't delete .git
+CLONE_INPUT=/absolute/path/to/candidate-clone
+[ -n "$CLONE_INPUT" ] || { echo "refusing: empty clone path" >&2; exit 2; }
+CLONE="$(cd "$CLONE_INPUT" 2>/dev/null && pwd -P)" \
+    || { echo "refusing: clone path does not resolve" >&2; exit 2; }
+[ -d "$CLONE/.git" ] \
+    || { echo "refusing: not a conventional full clone: $CLONE" >&2; exit 2; }
+
+git -C "$CLONE" status --short
+git -C "$CLONE" stash list
+git -C "$CLONE" for-each-ref \
+    --format='%(refname:short) %(upstream:short) %(upstream:track)' refs/heads
+git -C "$CLONE" worktree list --porcelain
 ```
 
+Stop if the output shows unique work or more than the primary checkout. Remove owned linked
+worktrees with `git worktree remove`, then `git worktree prune`; never delete the parent clone out
+from under them. For a standalone clone that is genuinely disposable, prefer a recoverable move to
+trash over immediate recursive deletion. Automation must additionally prove that the resolved path
+is a descendant of its dedicated task-clone root—not `$HOME`, a workspace root, or a path supplied
+only through an unchecked variable.
+
 ---
 
-## 8. Scripts that `cd` into a worktree then use relative paths back
+## 8. Using fragile relative paths between checkouts
 
 **Anti-pattern:**
 ```bash
@@ -229,7 +303,8 @@ cd ../feature-branch
 ../../main-repo/some-script.sh  # fragile relative path
 ```
 
-**Why it's dangerous:** The worktree is a separate directory. Your relative path `../../` assumes a specific directory layout that may not hold (the worktree could be anywhere on disk, not necessarily a sibling).
+**Why it's dangerous:** Worktrees and full clones can live anywhere. A relative path assumes a
+directory layout that may not hold and may resolve to a different clone after one `cd`.
 
 **Defensive approach:**
 ```bash
@@ -245,7 +320,7 @@ reports each worktree's actual path).
 
 ---
 
-## 9. Assuming `git branch -D` on a worktree-occupied branch is dangerous the way you think
+## 9. What branch deletion actually protects
 
 **Corrected claim:** Git actually protects you here — both `git branch -d` *and* `git branch -D`
 (force) refuse to delete a branch that's checked out in **any** worktree, main or linked. This was
@@ -274,7 +349,7 @@ fi
 
 ---
 
-## 10. `git stash` is GLOBAL, not per-worktree — popping in the wrong worktree corrupts the wrong tree
+## 10. `git stash` is global within a worktree family
 
 **Corrected claim:** Stashes are **shared** across all worktrees via the single ref `refs/stash` in
 the main repo's shared ref store — `git-worktree`'s docs list `refs/bisect`, `refs/worktree`, and
@@ -282,6 +357,9 @@ the main repo's shared ref store — `git-worktree`'s docs list `refs/bisect`, `
 was verified empirically: a stash pushed in the main worktree shows up identically in
 `git stash list` run from a linked worktree.
 
+A separate full clone has a separate `refs/stash`. That isolation does not copy stashes between
+clones or make either stash recoverable after its owning clone folder is removed.
+
 ```bash
 # In worktree A
 git stash push -m "WIP: half-done feature"
@@ -303,7 +381,7 @@ popping.
 
 ---
 
-## 11. Selective `.git` corruption & skeleton loss (the GH-177 scenario)
+## 11. Selective `.git` corruption and skeleton loss
 
 **What actually happened here (2026-07-07):** this repo's main `.git` directory lost `HEAD`,
 `objects/`, `refs/`, and `index`, while `hooks/`, `worktrees/`, and `config` survived intact. This
@@ -359,71 +437,74 @@ disposable, which after a partial-corruption incident it specifically is not.
 
 ---
 
-## 12. Never run the full test gate from a linked worktree (the 2026-08-19 incident)
-
-**Anti-pattern:** treating a linked worktree as an isolated place to verify a branch.
+## 12. Run the full gate only in a disposable full clone
 
-```bash
-git worktree add ../repo-feature -b feature origin/development
-cd ../repo-feature
-bash validate.sh          # WRONG — this can corrupt the PARENT clone
-```
+**Rule:** Run `validate.sh` and full `ci-local.sh` only in a separate full clone whose loss will not
+damage active work. A linked worktree exposes its parent clone; a valued full clone exposes itself.
+Neither is the right containment boundary for a fixture-heavy suite.
 
-**Why it's dangerous:** a linked worktree **shares the parent's `.git` common directory** — config,
-refs, and object store alike (§5, §10). A suite that manipulates "the repo" rather than a fixture
-therefore reaches the *real* repository. Observed on 2026-08-19, from one `validate.sh` run in a
-worktree:
-
-- `core.bare` set to **true** on the parent clone, after which `git rev-parse --show-toplevel` fails
-  with `this operation must be run in a work tree` and `git worktree list` reports the main clone as
-  `(bare)`
-- `remote.origin.url` repointed to a fixture's temp bare repo, which was then deleted — leaving
-  `origin` pointing at nothing, and every `gh` command failing with `none of the git remotes
-  configured for this repository point to a known GitHub host`
-- **all** `refs/remotes/origin/*` deleted
-- `development` overwritten with fixture commits (`merge feature`, `feature two`, `fake ra turn`);
-  local `main` overwritten with a fixture commit
-- ~72 fixture files strewn through the worktree (`art.md`, `relay-flip.md`, `GH-42-SAMPLE-THING.md`, …)
-
-No commits were lost — objects survived and the clone was repairable — but recovery required knowing
-exactly what to inspect. This is the failure mode GH-564 describes ("suites that can reach the
-caller's clone through an empty fixture path") arriving in practice.
-
-A second, independent symptom of the same sharing: `test/gh4-ungated-clone-warning.sh` **cannot pass
-from a worktree at all**, because it does `rm .git/hooks/pre-push` and in a worktree `.git` is a
-*file*, not a directory. Same commit, two locations — 6 pass / 0 fail in the main clone, 3 pass /
-3 fail in a worktree. A worktree gate run is not merely risky, it is not measuring what you think.
-
-**Correct approach — run the gate from a normal clone.** A worktree is for editing and committing;
-verification belongs in a full clone:
+**Anti-patterns:**
 
 ```bash
-# In the worktree: make the change, commit it.
-git commit -am "..."
-
-# In the MAIN clone (or a fresh throwaway clone): check out that branch and gate it there.
-cd /path/to/main-clone
-git checkout feature
-bash validate.sh
-```
-
-**Detect it in a script** with the same `--git-common-dir` idiom the driver-lock resolver uses
-(GH-448) — in a main clone the two are equal, in a linked worktree they are not:
+# WRONG: the linked worktree shares the parent clone's .git.
+git worktree add ../repo-feature -b feature origin/development
+(cd ../repo-feature && bash validate.sh)
 
-```bash
-if [ "$(git rev-parse --absolute-git-dir)" != "$(cd "$(git rev-parse --git-common-dir)" && pwd)" ]; then
-    echo "refusing: linked worktree shares the parent clone's .git — run this from a normal clone" >&2
-    exit 2
-fi
+# ALSO WRONG: this is a full clone, but it holds state the operator cares about.
+(cd /path/to/primary-clone && bash validate.sh)
 ```
 
-Tracked as [GH-45](https://github.com/HiQS-Suite/XYZ-forge/issues/45): `validate.sh` should carry
-that guard and fail closed by default, so this class is unreachable regardless of how many
-individual suites have been audited.
+### Why the boundary matters
+
+A linked worktree shares the parent clone's config, refs, objects, hooks, and most reflogs. A suite
+that escapes a fixture therefore writes into the parent repository. A separate full clone stops
+that cross-clone blast radius, but the suite can still corrupt the clone in which it runs; the word
+*disposable* is load-bearing.
+
+On 2026-08-19, a gate run from a linked worktree escaped its fixture and changed the parent clone:
+
+- `core.bare` became `true`
+- `remote.origin.url` pointed at a temporary bare repository that was later deleted
+- every `refs/remotes/origin/*` ref was deleted
+- local `development` and `main` moved to fixture commits
+- fixture files appeared in the working tree
+
+The objects survived, but the run was no longer attributable to the clone that started it. This is
+the GH-564/GH-567 failure class: an empty or invalid fixture path reaches the caller's repository.
+A suite can also behave differently in a linked worktree because `.git` is a file there, not a
+directory. A linked-worktree run is both unsafe and an invalid measurement.
+
+### What XYZ enforces now
+
+- [`validate.sh`](validate.sh) and [`ci-local.sh`](ci-local.sh) refuse linked worktrees with exit 2
+  before the suite starts. They compare the checkout's absolute Git directory with its resolved
+  common directory, checking both the script root and invocation directory where applicable.
+- `XYZ_ALLOW_WORKTREE_GATE=1` is an announced override. It changes the refusal, not the isolation;
+  use it only when the entire parent clone and every linked worktree registered to it are disposable.
+- [`test/gh35-test-tiers.sh`](test/gh35-test-tiers.sh) pins the refusal, override, absolute-path
+  invocation, and normal-full-clone control.
+- The full gate captures clone identity before the suite and asserts it afterward. Drift in
+  `core.bare`, `origin`, local user identity, or `HEAD` fails the run. This detects corruption after
+  it happens; it does not protect a valued clone from the mutation.
+
+### Correct workflow
+
+1. Edit and commit in the assigned worktree or task clone.
+2. Bring that exact commit into a dedicated full clone; do not substitute a similarly named branch.
+3. Confirm the gate clone has a real `.git/` directory, a clean working tree, and no registered
+   linked worktrees beyond its primary checkout.
+4. Run the gate from that clone. -> expect the linked-worktree guard to stay silent and the final
+   clone-identity invariant to pass.
+5. If clone identity changes, discard the gate result and the disposable clone, create a fresh full
+   clone, and rerun at the same concurrency. Repairing the damaged clone does not rehabilitate the
+   prior result.
+
+Tracked as [GH-45](https://github.com/HiQS-Suite/XYZ-forge/issues/45), with the broader fixture
+containment and identity work tracked by GH-564/GH-567.
 
 ---
 
-## 13. Other footguns worth knowing before scripting worktrees
+## 13. Other worktree and full-clone footguns
 
 - **Untracked or modified files block `git worktree remove`.** It refuses if the worktree has any
   uncommitted changes; `--force` is required to proceed — and `--force` silently discards those
@@ -439,65 +520,50 @@ individual suites have been audited.
 - **Prefer `git worktree list --porcelain` over the human-readable format** in any script. The
   plain-text table is not a stable API; porcelain output is machine-parseable and won't false-match
   on branch/path substrings the way a `grep` over the table can.
-
-## 13. Running the test gate from a linked worktree corrupts the PARENT clone
-
-**The trap.** `validate.sh` / `ci-local.sh` run ~190 suites, many driving git fixtures. From a
-linked worktree, a suite that escapes its fixture — or resolves a fixture path to an empty
-string — reaches the **parent clone's shared `.git`** (config, refs, objects), because a
-worktree isolates the working tree ONLY. This is not hypothetical: the observed 2026-08-19 run
-([GH-45](https://github.com/HiQS-Suite/XYZ-forge/issues/45)) set `core.bare=true`, repointed
-`remote.origin.url` at a since-deleted temp bare repo, deleted every `refs/remotes/origin/*`,
-and overwrote `development` and `main` with fixture commits. Same root cause as the
-`mktemp`-under-parallel-load family (GH-177/GH-564).
-
-**The guard (GH-45, built 2026-08-18).** Both gate entry points now REFUSE to run from a linked
-worktree — exit 2 before anything executes, every tier — using the one-comparison detection
-`git rev-parse --absolute-git-dir` ≠ resolved `git rev-parse --git-common-dir`, anchored on both
-the script's own root and the invocation CWD. The refusal message names the observed damage;
-`XYZ_ALLOW_WORKTREE_GATE=1` is the announced override for deliberate disposable runs. Pinned —
-including the control that a normal checkout of the same repo still runs — in
-`test/gh35-test-tiers.sh` §9.
-
-**Rule:** run the gate from a normal clone. A worktree is a fine place to *edit*; it is not a
-place to run a suite whose fixtures assume "the repo" is disposable.
+- **A clean clone can still hold unique state.** `git status --short` does not show unpushed branch
+  tips, stashes, reflog-only objects, hooks, or local configuration. Check them before cleanup (§7).
+- **Do not move a full-clone folder while it owns linked worktrees.** Their administrative files
+  point back to the clone's common directory. If a clone was already moved, use `git worktree
+  repair` with the real checkout paths; do not hand-edit `.git` files.
+- **Same branch name does not mean same branch state across full clones.** Verify the exact commit
+  SHA before grading, publishing, or deleting either clone.
 
 ---
 
-## Golden Rules for Worktree Safety
+## Golden rules
 
 1. **Always use `git worktree remove`/`prune`/`repair`, never manual `rm -rf` or `mv`** on worktree
    directories or `.git/worktrees/<name>` — repair (2.29+) and move (2.17+) are git's own tools for
    exactly these cases
-2. **Validate before destroying** — check that paths are non-empty, real directories, and not repo
-   roots before any destructive operation
+2. **Validate before destroying** — resolve the exact path, prove it is inside the operation's
+   dedicated root, and inventory worktree dependencies plus local-only state before cleanup
 3. **Be path-aware in traps** — canonicalize paths early, validate them, and never `rm -rf` on
    relative paths or unvalidated variables
-4. **The main repo's `.git` is the single source of truth** — protect it like a database, and verify
-   its skeleton (`HEAD`/`objects`/`refs`/`config`) is intact before trusting any command run against
-   it (§11); partial corruption is a real failure mode, not just total deletion
-5. **Worktrees share almost everything — objects, refs, AND stashes/logs.** The only genuinely
+4. **Each full clone's `.git` is the source of truth for its worktree family** — protect it like a
+   database, and verify its skeleton (`HEAD`/`objects`/`refs`/`config`) before trusting commands run
+   against it (§11); partial corruption is a real failure mode, not just total deletion
+5. **Linked worktrees share almost everything — objects, refs, AND stashes/logs.** The only genuinely
    per-worktree ref namespaces are `refs/bisect`, `refs/worktree`, and `refs/rewritten`. Don't assume
    isolation you don't have (§10); Git also actively *protects* shared state you might expect it not
-   to (§9's branch-delete block)
+   to (§9's branch-delete block). Separate full clones do not share that state.
 6. **Prefer git's own recovery tools over hand-surgery on `.git/`** — `init` (safe to re-run),
    `fetch`, `prune`, `repair` — and reach for `read-tree`/`diff`/`status` to inspect before any
    command that can overwrite the working tree (`checkout -f`, `reset --hard`, `clean`)
 7. **Script against `--porcelain` output, never the human-readable table** — `git worktree list`'s
    plain format is not a stable, grep-safe API
-8. **Never run the full test gate from a linked worktree** (§12) — the suite writes to the shared
-   `.git`, so it can set `core.bare`, repoint `origin`, delete remote refs, and overwrite branches in
-   the *parent* clone. Edit and commit in a worktree; verify in a normal clone.
+8. **Run the full test gate only in a separate disposable full clone** (§12) — never in a linked
+   worktree or a primary clone whose state matters. The identity bracket detects damage; it does not
+   make damage acceptable.
 
 ---
 
-## See Also
+## See also
 
+- [Git Clone Documentation](https://git-scm.com/docs/git-clone)
 - [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
 - [git-init](https://git-scm.com/docs/git-init) — confirms re-running `init` on an existing repo is safe/non-clobbering
 - [git-fsck](https://git-scm.com/docs/git-fsck) — integrity check, first step after any suspected `.git` corruption
 - [git-gc](https://git-scm.com/docs/git-gc) — documents the `--prune=now` concurrency risk cited in §6
-- Related: [Temp Directory Safety Guide](./temp-dir-safety.md) — for the `mktemp` failure mode that can cascade into worktree destruction
 
 ---
 
```
````
- Definition of Done: The three-doc patch is concise, internally consistent, technically safe,
  license-aligned, complete for linked worktrees and full clones, free of duplicate guidance, and
  ready to ship with no Blocker or Should findings.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer (agy) — Turn 1
- **swept file: yes**

- `[Pass]` Question 1: The safety-and-warranty notice is accurate, concise, consistent, and correctly limits liability while addressing agent autonomy. (e.g., `README.md` lines 109-113: `> **Safety and warranty:** XYZ Forge is provided **“AS IS,” without warranty**...`).
- `[Pass]` Question 2: The `AGENTS.md` danger block provides immediate, actionable guidance without contradicting the rails below (e.g., lines 76-87: `- Never run \`git reset --hard\`...`).
- `[Pass]` Question 3: `WORKTREE-SAFETY.md` is coherently merged, handles full-clones vs linked-worktrees accurately, and TOC links are well-formed and navigable.
- `[Pass]` Question 4: No unsafe or absolute claims found. Preflight bash checks (e.g., lines 288-298 in `WORKTREE-SAFETY.md`) are technically sound and use proper guards.
- `[Pass]` Question 5: `README.md` correctly avoids guarantees. The wording `reduce accidental overwrites` replaces the absolute promise (line 107).
- `[Nit]` In `WORKTREE-SAFETY.md` Section 12, line 476: `4. Run the gate from that clone. -> expect the linked-worktree guard...` — the `-> expect` syntax is slightly informal. Consider reformatting (e.g., `(expect the ...)`).

Verdict: **Approved**

relay closed (Approved), no further turn needed

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
