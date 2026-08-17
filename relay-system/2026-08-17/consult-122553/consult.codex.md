**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.6-terra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
2026-08-17T19:25:54.564179Z ERROR codex_models_manager::cache: failed to load models cache: missing field `base_instructions` at line 96 column 5
OpenAI Codex v0.144.6
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr
model: gpt-5.6-terra
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 01a01130-054f-7f11-8a02-c0aec57b91db
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
Review lines 360-420 of README.md in this repo. Critique the clarity, accuracy, and sharpness of the new 'Glossary & Execution Model' table and the 'Do phases run in parallel?' Q&A section. Identify any ambiguities, missing terms, or opportunities to sharpen the distinction between intra-plan sequential phases, marathon lanes, waves, and worktree/clone swarms.
hook: SessionStart
hook: SessionStart Completed
codex
I’ll inspect the referenced README section alongside the repo’s routing and execution-model guidance, then give a focused, citation-backed editorial review.
exec
/bin/zsh -lc "pwd && rg -n -C 2 'Glossary|Do phases run in parallel|marathon lanes|worktree|clone swarms' README.md ROUTER.md GUIDING-PRINCIPLES.md WORKTREE-SAFETY.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr
 succeeded in 0ms:
/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr
ROUTER.md-55-boundary instead, so `githooks/install.sh` is part of setting up a clone — the hook lives in
ROUTER.md-56-`.git/hooks/`, which does not travel with a clone, and an uninstalled one pushes unverified. One
ROUTER.md:57:install covers every branch and every linked worktree of that clone (GH-549). Bypass with
ROUTER.md-58-`git push --no-verify` or `XYZ_SKIP_PREPUSH=1`; both announce themselves. Re-arm CI when the repo
ROUTER.md-59-goes public (free there).
--
README.md-34-(GH-544), so the local gate at the push boundary is the *only* gate — and the hook lives in
README.md-35-`.git/hooks/`, which does not travel with a clone. A clone that skipped this step pushes
README.md:36:unverified and nothing downstream will notice. One run covers every branch and linked worktree of
README.md-37-that clone (GH-549). `./validate.sh` itself warns, in-band, if this clone is ungated — check
README.md-38-directly any time with `bash githooks/install.sh --check`. (Just evaluating the project and never
--
README.md-148-Everything below is designed to be reversible, but please help it along:
README.md-149-
README.md:150:- **Create a fresh branch (or git worktree) in *both* repos you touch** — one in your clone of
README.md-151-  XYZ, and one in each target project where you'll run relays or install PDDA. E.g.
README.md-152-  `git checkout -b xyz-beta-test`. If anything goes sideways, recovery is just
README.md:153:  `git checkout main` and deleting the branch. If you use `git worktree` directly, read
README.md-154-  [WORKTREE-SAFETY.md](WORKTREE-SAFETY.md) first — a couple of its operations (force-removing a
README.md:155:  worktree directory, moving/relinking one) leave stale git metadata if done by hand instead of
README.md:156:  through `git worktree remove`/`repair`.
README.md-157-- **What each step actually touches** (so you know how to undo it):
README.md-158-  - *Skill install* — symlinks skill folders into the selected agent's user-level skill directory
--
README.md-323----
README.md-324-
README.md:325:## Glossary — the four terms you'll hit first
README.md-326-
README.md-327-(For how the operating modes — Consult, Relay, Swarm, Marathon — relate to each other, see
--
README.md-344-
README.md-345-Partly, and the parts it leaves out are deliberate. If you arrive with the standard agent-graph
README.md:346:vocabulary (a DAG of nodes and edges, parallel stages, routing decisions), the Glossary entry above
README.md-347-will read as more than it says. The precise answer:
README.md-348-
--
README.md-369-and never its executor.
README.md-370-
README.md:371:Parallelism does exist, but as **swarms**: separate agents in separate worktrees or clones on
README.md-372-disjoint write-sets, coordinated by `tick` locks. That is arranged by the operator, not scheduled
README.md-373-from a dependency graph.
README.md-374-
README.md:375:### Do phases run in parallel? What does `depends_on` actually do?
README.md-376-
README.md-377-**Inside a single marathon plan: No.** Phases run **strictly one at a time**, in the order they appear in the plan.
--
README.md-387-
README.md-388-**Where parallelism DOES exist is at the Swarm / Lane level.** Independent tasks and issues (Lanes)
README.md:389:can be dispatched concurrently across **separate standalone clones or isolated worktrees** on disjoint write-sets.
README.md-390-For instance, the `/10days` skill fans out parallel subagents to *triage and inspect* issues simultaneously,
README.md-391-while the execution of any given marathon runner stays strictly sequential across its internal phases to prevent
--
README.md-395-zero cost, which is the cheapest way to catch both a mis-shaped field and a wrong mental model.
README.md-396-
README.md:397:## Glossary & Execution Model
README.md-398-
README.md-399-To avoid ambiguity across planning, kernel locks, and multi-agent workflows, terminology in this repository adheres to the following definitions:
--
README.md-408-| **Wave** | Planner | A batch of independent lanes identified by disjoint write-sets (via `marathon-plan.sh`) that can be safely scheduled together. | Batch scheduling |
README.md-409-| **Marathon** | Automation | A multi-phase runner (`marathon-drive.sh`) that executes an ordered sequence of phases, gates, and git commits on a branch. | Serial orchestrator |
README.md:410:| **Swarm** | Architecture | Multiple independent agents running concurrently across **separate clones or worktrees**, coordinated by `tick` locks. | **Parallel / Distributed** |
README.md-411-| **`depends_on`** | Config | An authoring validation assertion in a marathon plan verifying prerequisite phase completion before starting the next. | Assertion gate (not parallel DAG) |
README.md-412-| **`tick` Kernel** | Kernel | The local, serverless event-log engine managing collision-free task claims and path-scoped locks under `.tick/events/`. | ACID / Event-sourced |
--
GUIDING-PRINCIPLES.md-5-## Purpose
GUIDING-PRINCIPLES.md-6-
GUIDING-PRINCIPLES.md:7:`tick` coordinates Claude Code, Codex, and agy (Antigravity CLI) on the same branch without collision: a shared local event log under `.tick/events/`, claims serialized by `O_EXCL` locks, and a `Marathon` harness that chains multi-phase build→review cycles from a `MARATHON.yaml`. The relay layer (`relay-automation/`) drives headless turns, isolates agent writes to worktrees, and enforces an allowlist so no headless agent destroys work it didn't intend to touch. The goal: a multi-agent swarm safe enough to run against a real external codebase and correct enough that its output is worth shipping.
GUIDING-PRINCIPLES.md-8-
GUIDING-PRINCIPLES.md-9-## The quality bar
--
GUIDING-PRINCIPLES.md-24-2. **One canonical event log; every surface is a projection.** `tick` accretes events; `STATE.md` is the current projection. Reads go through the projection; writes go through a `claim/take/scope/done` verb. Nothing canonical lives in two places where it can drift. An agent that hard-codes state outside `.tick/` is creating drift.
GUIDING-PRINCIPLES.md-25-
GUIDING-PRINCIPLES.md:26:3. **Containment is non-negotiable.** A headless turn must not: self-commit mid-turn, orphan a peer's concurrent commit, or write outside its allowlist. The allowlist, worktree isolation, and commit-bypass guard exist because a driven agent will do all three if unconstrained — not hypothetically, but as documented live incidents (GH-13, GH-14, GH-17). New relay paths must clear the containment bar before they ship.
GUIDING-PRINCIPLES.md-27-
GUIDING-PRINCIPLES.md-28-4. **Skill-first; never improvise the harness.** The `relay-xyz` skill owns the locator, sandbox rules, exit codes, and the safety boundary. A session that improvises those from `ls relay-automation/` silently skips the skill's safety layer. The `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) enforces this by blocking driver calls before the skill loads. Add capabilities to the skill; do not work around it.
--
GUIDING-PRINCIPLES.md-143-**Reject or escalate when**
GUIDING-PRINCIPLES.md-144-
GUIDING-PRINCIPLES.md:145:- A headless path has no allowlist, no worktree isolation, and no commit-bypass guard — and the doc doesn't justify why.
GUIDING-PRINCIPLES.md-146-- "Done" has no runnable verification step.
GUIDING-PRINCIPLES.md-147-- Adding a new relay lane requires editing the event-log kernel or the `tick` verb schema without a decision record under `decisions/`.
--
WORKTREE-SAFETY.md-5-Copyright 2026 Neochrome, Inc.  
WORKTREE-SAFETY.md-6-
WORKTREE-SAFETY.md:7:> **Purpose:** Prevent destructive footguns when scripting with Git worktrees.  
WORKTREE-SAFETY.md:8:> **Scope:** Shell scripts, CI pipelines, and agent workflows that create, manage, or clean up worktrees.
WORKTREE-SAFETY.md-9-
WORKTREE-SAFETY.md-10----
WORKTREE-SAFETY.md-11-
WORKTREE-SAFETY.md:12:## 1. The "rm -rf worktree path" trap
WORKTREE-SAFETY.md-13-
WORKTREE-SAFETY.md:14:**Anti-pattern:** Deleting a worktree by just removing its directory.
WORKTREE-SAFETY.md-15-
WORKTREE-SAFETY.md-16-```bash
WORKTREE-SAFETY.md:17:# WRONG — leaves stale metadata in .git/worktrees/
WORKTREE-SAFETY.md-18-rm -rf ../feature-branch
WORKTREE-SAFETY.md-19-
WORKTREE-SAFETY.md:20:# Also WRONG — git still thinks the worktree exists
WORKTREE-SAFETY.md:21:git worktree remove ../feature-branch  # fails: "not a working tree"
WORKTREE-SAFETY.md-22-```
WORKTREE-SAFETY.md-23-
WORKTREE-SAFETY.md:24:**Why it's dangerous:** Git maintains metadata in `.git/worktrees/<name>/` and in a `.git` file inside the worktree. If you `rm -rf` the directory, you get:
WORKTREE-SAFETY.md-25-- Orphaned metadata polluting your repo
WORKTREE-SAFETY.md-26-- The branch may still be checked out according to git, blocking operations
WORKTREE-SAFETY.md:27:- `.git/worktrees/<name>/index` can grow large and never gets cleaned
WORKTREE-SAFETY.md-28-
WORKTREE-SAFETY.md-29-**Correct approach:**
WORKTREE-SAFETY.md-30-```bash
WORKTREE-SAFETY.md:31:# Always use git worktree remove
WORKTREE-SAFETY.md:32:git worktree remove ../feature-branch
WORKTREE-SAFETY.md-33-
WORKTREE-SAFETY.md-34-# If the directory is already gone, let git reconcile its own metadata —
WORKTREE-SAFETY.md:35:# don't hand-delete .git/worktrees/<name> yourself:
WORKTREE-SAFETY.md:36:git worktree prune
WORKTREE-SAFETY.md-37-
WORKTREE-SAFETY.md:38:# If the worktree still exists but was moved/relinked and git can't find it,
WORKTREE-SAFETY.md:39:# `repair` (Git 2.29+) is the documented fix, not manual surgery on .git/worktrees/:
WORKTREE-SAFETY.md:40:git worktree repair ../feature-branch
WORKTREE-SAFETY.md-41-```
WORKTREE-SAFETY.md:42:Manual `rm -rf .git/worktrees/<name>` is a last resort for a clearly corrupt admin
WORKTREE-SAFETY.md-43-stub that `prune`/`repair` won't touch — not the normal cleanup path.
WORKTREE-SAFETY.md-44-
WORKTREE-SAFETY.md-45----
WORKTREE-SAFETY.md-46-
WORKTREE-SAFETY.md:47:## 2. Scripting `git worktree add` without failure handling
WORKTREE-SAFETY.md-48-
WORKTREE-SAFETY.md:49:**Anti-pattern:** Assuming `git worktree add` succeeds.
WORKTREE-SAFETY.md-50-
WORKTREE-SAFETY.md-51-```bash
WORKTREE-SAFETY.md:52:git worktree add ../hotfix hotfix-branch
WORKTREE-SAFETY.md-53-cd ../hotfix || exit 1
WORKTREE-SAFETY.md-54-# ... do work ...
--
WORKTREE-SAFETY.md-56-
WORKTREE-SAFETY.md-57-**Why it's dangerous:**
WORKTREE-SAFETY.md:58:- Branch might already be checked out in another worktree (git refuses with "already checked out")
WORKTREE-SAFETY.md-59-- Path might already exist
WORKTREE-SAFETY.md-60-- Disk might be full
--
WORKTREE-SAFETY.md-63-**Defensive version:**
WORKTREE-SAFETY.md-64-```bash
WORKTREE-SAFETY.md:65:if ! git worktree add ../hotfix hotfix-branch 2>/dev/null; then
WORKTREE-SAFETY.md-66-    echo "Worktree creation failed — branch may already be checked out or path exists" >&2
WORKTREE-SAFETY.md-67-    exit 1
--
WORKTREE-SAFETY.md-71----
WORKTREE-SAFETY.md-72-
WORKTREE-SAFETY.md:73:## 3. Trap cleaning worktrees with `rm -rf` and relative paths
WORKTREE-SAFETY.md-74-
WORKTREE-SAFETY.md:75:**Anti-pattern:** The sibling of the `mktemp` bug — cleaning worktrees in traps.
WORKTREE-SAFETY.md-76-
WORKTREE-SAFETY.md-77-```bash
WORKTREE-SAFETY.md-78-WORKTREE="../feature-$(date +%s)"
WORKTREE-SAFETY.md:79:git worktree add "$WORKTREE" feature-branch
WORKTREE-SAFETY.md-80-trap 'rm -rf "$WORKTREE"' EXIT
WORKTREE-SAFETY.md-81-```
WORKTREE-SAFETY.md-82-
WORKTREE-SAFETY.md-83-**Why it's dangerous:**
WORKTREE-SAFETY.md:84:- If `git worktree add` fails and `WORKTREE` is empty/malformed, a quoted `rm -rf "$WORKTREE"` errors on an empty string (`rm: missing operand`) rather than silently targeting cwd — but an *unquoted* `rm -rf $WORKTREE` word-splits an empty value to zero arguments, which for GNU `rm` is also a no-op/error, NOT an implicit `.`. The real risk isn't a specific "resolves to cwd" mechanism at all: it's that an unvalidated variable in a destructive trap can hold anything (a partial path, a stray `*`, a value from a prior failed `cd`) by the time `EXIT` fires, and nothing between assignment and the trap firing re-checks it
WORKTREE-SAFETY.md:85:- If the script `cd`s into the worktree, the relative path `../` now points somewhere else
WORKTREE-SAFETY.md:86:- `rm -rf` leaves stale metadata in `.git/worktrees/`
WORKTREE-SAFETY.md-87-
WORKTREE-SAFETY.md-88-**Defensive version:**
WORKTREE-SAFETY.md-89-```bash
WORKTREE-SAFETY.md:90:# NOTE: unlike mktemp, git worktree add does NOT expand "XXXX" into a random
WORKTREE-SAFETY.md-91-# suffix — that string would be used verbatim as the path. Build the unique
WORKTREE-SAFETY.md-92-# path yourself before calling git, and don't rely on parsing git's output
WORKTREE-SAFETY.md-93-# (--quiet suppresses exactly the text a naive script would try to awk out of it).
WORKTREE-SAFETY.md-94-WORKTREE="$(pwd)/../feature-$$-$(date +%s)"
WORKTREE-SAFETY.md:95:git worktree add "$WORKTREE" feature-branch || { echo "Worktree creation failed" >&2; exit 1; }
WORKTREE-SAFETY.md-96-WORKTREE="$(cd "$WORKTREE" && pwd -P)"  # canonicalize AFTER validation
WORKTREE-SAFETY.md-97-
WORKTREE-SAFETY.md-98-cleanup() {
WORKTREE-SAFETY.md:99:    # --force here is NOT the §12 anti-pattern: this worktree was just created by THIS script for a
WORKTREE-SAFETY.md-100-    # throwaway purpose and is being torn down in its own exit trap, not force-removed out from under
WORKTREE-SAFETY.md-101-    # someone else's uncommitted work. §12's warning is about scripts reaching for --force to silence
WORKTREE-SAFETY.md:102:    # an error on a worktree they don't own/didn't create.
WORKTREE-SAFETY.md:103:    git worktree remove --force "$WORKTREE" 2>/dev/null || true
WORKTREE-SAFETY.md:104:    git worktree prune 2>/dev/null || true
WORKTREE-SAFETY.md-105-}
WORKTREE-SAFETY.md-106-trap cleanup EXIT
--
WORKTREE-SAFETY.md-109----
WORKTREE-SAFETY.md-110-
WORKTREE-SAFETY.md:111:## 4. Moving/renaming worktree directories outside of git
WORKTREE-SAFETY.md-112-
WORKTREE-SAFETY.md:113:**Anti-pattern:** Using `mv` to relocate a worktree.
WORKTREE-SAFETY.md-114-
WORKTREE-SAFETY.md-115-```bash
--
WORKTREE-SAFETY.md-117-```
WORKTREE-SAFETY.md-118-
WORKTREE-SAFETY.md:119:**Why it's dangerous:** The `.git` file inside the worktree contains an absolute or relative path back to the main repo. Moving it breaks that link. Git now can't find the worktree, and `git worktree remove` fails.
WORKTREE-SAFETY.md-120-
WORKTREE-SAFETY.md-121-**Correct approach:**
WORKTREE-SAFETY.md-122-```bash
WORKTREE-SAFETY.md:123:# git worktree move shipped in Git 2.17.0 — use it instead of mv
WORKTREE-SAFETY.md:124:git worktree move ../feature-branch ../feature-branch-renamed
WORKTREE-SAFETY.md-125-
WORKTREE-SAFETY.md-126-# Pre-2.17: remove and re-add
WORKTREE-SAFETY.md:127:git worktree remove ../feature-branch
WORKTREE-SAFETY.md:128:git worktree add ../feature-branch-renamed feature-branch
WORKTREE-SAFETY.md-129-
WORKTREE-SAFETY.md:130:# If a worktree (or the main worktree) was ALREADY moved outside git's
WORKTREE-SAFETY.md-131-# knowledge — e.g. via `mv`, a backup restore, or a renamed parent dir — the
WORKTREE-SAFETY.md-132-# documented fix is `repair` (Git 2.29+), not manual .git-file surgery:
WORKTREE-SAFETY.md:133:git worktree repair ../feature-branch-renamed
WORKTREE-SAFETY.md-134-```
WORKTREE-SAFETY.md-135-
--
WORKTREE-SAFETY.md-138-## 5. Assuming `main` (or any shared branch) is free for checkout
WORKTREE-SAFETY.md-139-
WORKTREE-SAFETY.md:140:**Anti-pattern:** `git worktree add` for a branch that's already checked out elsewhere.
WORKTREE-SAFETY.md-141-
WORKTREE-SAFETY.md-142-```bash
WORKTREE-SAFETY.md:143:# Script adds a worktree for "main" to run tests
WORKTREE-SAFETY.md:144:git worktree add ../main-worktree main
WORKTREE-SAFETY.md-145-```
WORKTREE-SAFETY.md-146-
WORKTREE-SAFETY.md:147:**Why it's dangerous:** If any other worktree already has `main` checked out, this fails. This is especially problematic in CI or multi-session environments.
WORKTREE-SAFETY.md-148-
WORKTREE-SAFETY.md-149-**Defensive version:**
WORKTREE-SAFETY.md-150-```bash
WORKTREE-SAFETY.md-151-# Use a unique branch name or detached HEAD
WORKTREE-SAFETY.md:152:git worktree add --detach ../test-run-$$ main
WORKTREE-SAFETY.md-153-
WORKTREE-SAFETY.md-154-# Or check first — parse --porcelain, not human-readable output. The plain
WORKTREE-SAFETY.md:155:# `git worktree list` format is not a stable API and grep can false-match on
WORKTREE-SAFETY.md-156-# pathnames that happen to contain "[main]"-like substrings.
WORKTREE-SAFETY.md:157:if git worktree list --porcelain | grep -qx 'branch refs/heads/main'; then
WORKTREE-SAFETY.md:158:    echo "main is already checked out in another worktree" >&2
WORKTREE-SAFETY.md-159-    exit 1
WORKTREE-SAFETY.md-160-fi
--
WORKTREE-SAFETY.md-163----
WORKTREE-SAFETY.md-164-
WORKTREE-SAFETY.md:165:## 6. Garbage collection while worktrees exist
WORKTREE-SAFETY.md-166-
WORKTREE-SAFETY.md:167:**Anti-pattern:** Running aggressive GC without considering worktrees.
WORKTREE-SAFETY.md-168-
WORKTREE-SAFETY.md-169-```bash
--
WORKTREE-SAFETY.md-173-**Why it's dangerous:**
WORKTREE-SAFETY.md-174-- Worktrees share the same object database, and (with the exception of
WORKTREE-SAFETY.md:175:  `refs/bisect`, `refs/worktree`, and `refs/rewritten`) the same refs — modern
WORKTREE-SAFETY.md:176:  Git *is* worktree-aware and does scan all registered worktrees' refs/logs
WORKTREE-SAFETY.md:177:  before pruning, so "gc can't see another worktree's refs" is not the
WORKTREE-SAFETY.md-178-  mechanism
WORKTREE-SAFETY.md-179-- The real documented risk is **concurrency**: `--prune=now` disables the
WORKTREE-SAFETY.md-180-  normal grace-period safety margin, so if another process (a build in a
WORKTREE-SAFETY.md:181:  linked worktree, a concurrent commit) creates an object that isn't
WORKTREE-SAFETY.md-182-  referenced by a ref yet, `--prune=now` can delete it out from under that
WORKTREE-SAFETY.md:183:  process — a race, not a worktree-visibility gap
WORKTREE-SAFETY.md:184:- A secondary, worktree-specific risk: if a worktree directory was manually
WORKTREE-SAFETY.md:185:  `rm -rf`'d without `git worktree prune`, its stale `.git/worktrees/<name>/`
WORKTREE-SAFETY.md-186-  admin entry can leave git's bookkeeping out of sync with reality until
WORKTREE-SAFETY.md-187-  pruned
--
WORKTREE-SAFETY.md-189-**Defensive approach:**
WORKTREE-SAFETY.md-190-```bash
WORKTREE-SAFETY.md:191:# Always list worktrees before GC to understand what's shared
WORKTREE-SAFETY.md:192:git worktree list
WORKTREE-SAFETY.md-193-
WORKTREE-SAFETY.md:194:# Avoid --prune=now while any worktree might be mid-write (build, commit, checkout)
WORKTREE-SAFETY.md-195-# Or avoid --prune=now entirely
WORKTREE-SAFETY.md-196-git gc --auto  # conservative, safe
--
WORKTREE-SAFETY.md-199----
WORKTREE-SAFETY.md-200-
WORKTREE-SAFETY.md:201:## 7. Deleting the main worktree's `.git` directory
WORKTREE-SAFETY.md-202-
WORKTREE-SAFETY.md-203-**Anti-pattern:** Treating the main `.git` directory as just another git database.
--
WORKTREE-SAFETY.md-208-```
WORKTREE-SAFETY.md-209-
WORKTREE-SAFETY.md:210:**Why it's dangerous:** All linked worktrees reference the main repo's object database via their `.git` files. Deleting the main `.git` irrecoverably breaks every linked worktree.
WORKTREE-SAFETY.md-211-
WORKTREE-SAFETY.md:212:**Real-world scenario:** You have 3 worktrees off a main checkout. Someone decides to "clean up" by deleting the main checkout folder. Now all 3 worktrees are orphaned with no object database, and even `git log` fails.
WORKTREE-SAFETY.md-213-
WORKTREE-SAFETY.md-214-**Precaution:**
WORKTREE-SAFETY.md-215-```bash
WORKTREE-SAFETY.md:216:# Before removing any repo, check if it's the primary for worktrees
WORKTREE-SAFETY.md:217:git worktree list
WORKTREE-SAFETY.md:218:# If other worktrees reference this one's objects, don't delete .git
WORKTREE-SAFETY.md-219-```
WORKTREE-SAFETY.md-220-
WORKTREE-SAFETY.md-221----
WORKTREE-SAFETY.md-222-
WORKTREE-SAFETY.md:223:## 8. Scripts that `cd` into a worktree then use relative paths back
WORKTREE-SAFETY.md-224-
WORKTREE-SAFETY.md-225-**Anti-pattern:**
--
WORKTREE-SAFETY.md-230-```
WORKTREE-SAFETY.md-231-
WORKTREE-SAFETY.md:232:**Why it's dangerous:** The worktree is a separate directory. Your relative path `../../` assumes a specific directory layout that may not hold (the worktree could be anywhere on disk, not necessarily a sibling).
WORKTREE-SAFETY.md-233-
WORKTREE-SAFETY.md-234-**Defensive approach:**
--
WORKTREE-SAFETY.md-241-or a bare common dir, where `.git` isn't a sibling of the working files. For
WORKTREE-SAFETY.md-242-those layouts, don't derive the root by walking up from `--git-common-dir` —
WORKTREE-SAFETY.md:243:resolve it explicitly (e.g. from `git worktree list --porcelain`, which
WORKTREE-SAFETY.md:244:reports each worktree's actual path).
WORKTREE-SAFETY.md-245-
WORKTREE-SAFETY.md-246----
WORKTREE-SAFETY.md-247-
WORKTREE-SAFETY.md:248:## 9. Assuming `git branch -D` on a worktree-occupied branch is dangerous the way you think
WORKTREE-SAFETY.md-249-
WORKTREE-SAFETY.md-250-**Corrected claim:** Git actually protects you here — both `git branch -d` *and* `git branch -D`
WORKTREE-SAFETY.md:251:(force) refuse to delete a branch that's checked out in **any** worktree, main or linked. This was
WORKTREE-SAFETY.md-252-verified empirically (Git 2.50.1): `git branch -D feature-branch` fails with
WORKTREE-SAFETY.md:253:`error: cannot delete branch 'feature-branch' used by worktree at 'PATH'` (exit 1). There is no
WORKTREE-SAFETY.md:254:"force-delete succeeds and leaves that worktree in detached HEAD" failure mode — that was this
WORKTREE-SAFETY.md-255-doc's own error, not a real Git footgun.
WORKTREE-SAFETY.md-256-
--
WORKTREE-SAFETY.md-262-**What's still worth guarding against:** the actual footgun is scripts that treat this failure as
WORKTREE-SAFETY.md-263-fatal-and-unexpected instead of handling it, or that work around it by first force-removing the
WORKTREE-SAFETY.md:264:occupying worktree (`git worktree remove --force`) to clear the way — which *does* discard that
WORKTREE-SAFETY.md:265:worktree's uncommitted work. If a script needs to delete a branch, check occupancy first and fail
WORKTREE-SAFETY.md:266:loud rather than reaching for `--force` on the worktree to unblock the branch deletion:
WORKTREE-SAFETY.md-267-
WORKTREE-SAFETY.md-268-```bash
WORKTREE-SAFETY.md:269:if git worktree list --porcelain | grep -qx "branch refs/heads/feature-branch"; then
WORKTREE-SAFETY.md:270:    echo "Branch is checked out in a worktree — aborting deletion (do not --force the worktree to work around this)" >&2
WORKTREE-SAFETY.md-271-    exit 1
WORKTREE-SAFETY.md-272-fi
--
WORKTREE-SAFETY.md-275----
WORKTREE-SAFETY.md-276-
WORKTREE-SAFETY.md:277:## 10. `git stash` is GLOBAL, not per-worktree — popping in the wrong worktree corrupts the wrong tree
WORKTREE-SAFETY.md-278-
WORKTREE-SAFETY.md:279:**Corrected claim:** Stashes are **shared** across all worktrees via the single ref `refs/stash` in
WORKTREE-SAFETY.md:280:the main repo's shared ref store — `git-worktree`'s docs list `refs/bisect`, `refs/worktree`, and
WORKTREE-SAFETY.md:281:`refs/rewritten` as the only per-worktree ref namespaces, and `refs/stash` is not among them. This
WORKTREE-SAFETY.md:282:was verified empirically: a stash pushed in the main worktree shows up identically in
WORKTREE-SAFETY.md:283:`git stash list` run from a linked worktree.
WORKTREE-SAFETY.md-284-
WORKTREE-SAFETY.md-285-```bash
WORKTREE-SAFETY.md:286:# In worktree A
WORKTREE-SAFETY.md-287-git stash push -m "WIP: half-done feature"
WORKTREE-SAFETY.md-288-
WORKTREE-SAFETY.md:289:# In worktree B
WORKTREE-SAFETY.md:290:git stash list  # shows the SAME stash — it is not worktree-local
WORKTREE-SAFETY.md:291:git stash pop   # applies worktree A's stash onto worktree B's files — likely the WRONG tree
WORKTREE-SAFETY.md-292-```
WORKTREE-SAFETY.md-293-
WORKTREE-SAFETY.md:294:**Why it's actually dangerous:** because the stash is shared, popping it in the wrong worktree
WORKTREE-SAFETY.md-295-applies changes meant for one branch/tree onto a different one — conflicts, or silent application
WORKTREE-SAFETY.md:296:to unrelated files, and the stash is now consumed so worktree A can't get it back without digging
WORKTREE-SAFETY.md-297-through the reflog (`git fsck --unreachable`, `git stash list` right after `pop` won't show it).
WORKTREE-SAFETY.md-298-
WORKTREE-SAFETY.md-299-**Correct mental model:** Stashes are a single shared stack across the whole repo, indexed the same
WORKTREE-SAFETY.md:300:way from every worktree. Use unmistakable `-m` messages, and run `git stash list` in the worktree
WORKTREE-SAFETY.md-301-you're about to pop into (not the one you pushed from) to confirm which entry is `stash@{0}` before
WORKTREE-SAFETY.md-302-popping.
--
WORKTREE-SAFETY.md-307-
WORKTREE-SAFETY.md-308-**What actually happened here (2026-07-07):** this repo's main `.git` directory lost `HEAD`,
WORKTREE-SAFETY.md:309:`objects/`, `refs/`, and `index`, while `hooks/`, `worktrees/`, and `config` survived intact. This
WORKTREE-SAFETY.md-310-is **not** the "someone ran `rm -rf .git`" scenario in §7 above — that deletes everything uniformly.
WORKTREE-SAFETY.md-311-This was a *partial* loss (consistent with a selective backup/restore gap), and none of the 10
--
WORKTREE-SAFETY.md-320-git fsck --no-progress 2>&1 | head -5   # first real integrity check once the above pass
WORKTREE-SAFETY.md-321-```
WORKTREE-SAFETY.md:322:Also check `.git/worktrees/*/gitdir` stubs for staleness — a stub with no valid path behind it (or
WORKTREE-SAFETY.md-323-just a bare `commondir` file and nothing else) is metadata cruft from the same class of incident,
WORKTREE-SAFETY.md:324:not a real linked worktree; `git worktree prune` clears it once the main repo is healthy again.
WORKTREE-SAFETY.md-325-
WORKTREE-SAFETY.md-326-**Recovery — in order, verifying before each destructive-looking step:**
--
WORKTREE-SAFETY.md-360----
WORKTREE-SAFETY.md-361-
WORKTREE-SAFETY.md:362:## 12. Other footguns worth knowing before scripting worktrees
WORKTREE-SAFETY.md-363-
WORKTREE-SAFETY.md:364:- **Untracked or modified files block `git worktree remove`.** It refuses if the worktree has any
WORKTREE-SAFETY.md-365-  uncommitted changes; `--force` is required to proceed — and `--force` silently discards those
WORKTREE-SAFETY.md-366-  changes. Never default a script to `--force` as a way to "fix" a remove that failed.
WORKTREE-SAFETY.md:367:- **`git worktree move` does not support worktrees containing submodules** — the relative links
WORKTREE-SAFETY.md-368-  back to `.git/modules/` break. Don't script a blind `move` without checking `.gitmodules` first.
WORKTREE-SAFETY.md-369-- **`--force` on `add` / `move` / `remove` overrides the exact safeguards this guide teaches** (branch
WORKTREE-SAFETY.md:370:  occupancy, dirty-worktree protection, path collisions). Treat any script that reaches for `-f`/`--force`
WORKTREE-SAFETY.md:371:  to silence a worktree error as a signal to stop and understand *why* git refused, not a shortcut.
WORKTREE-SAFETY.md:372:- **Lock worktrees on removable/unstable storage.** `git worktree lock <path>` prevents `git worktree
WORKTREE-SAFETY.md:373:  prune` (including the prune that `git gc` can trigger) from reaping a worktree's metadata just
WORKTREE-SAFETY.md-374-  because its directory is temporarily unreachable (unmounted drive, network share).
WORKTREE-SAFETY.md:375:- **Prefer `git worktree list --porcelain` over the human-readable format** in any script. The
WORKTREE-SAFETY.md-376-  plain-text table is not a stable API; porcelain output is machine-parseable and won't false-match
WORKTREE-SAFETY.md-377-  on branch/path substrings the way a `grep` over the table can.
--
WORKTREE-SAFETY.md-381-## Golden Rules for Worktree Safety
WORKTREE-SAFETY.md-382-
WORKTREE-SAFETY.md:383:1. **Always use `git worktree remove`/`prune`/`repair`, never manual `rm -rf` or `mv`** on worktree
WORKTREE-SAFETY.md:384:   directories or `.git/worktrees/<name>` — repair (2.29+) and move (2.17+) are git's own tools for
WORKTREE-SAFETY.md-385-   exactly these cases
WORKTREE-SAFETY.md-386-2. **Validate before destroying** — check that paths are non-empty, real directories, and not repo
--
WORKTREE-SAFETY.md-392-   it (§11); partial corruption is a real failure mode, not just total deletion
WORKTREE-SAFETY.md-393-5. **Worktrees share almost everything — objects, refs, AND stashes/logs.** The only genuinely
WORKTREE-SAFETY.md:394:   per-worktree ref namespaces are `refs/bisect`, `refs/worktree`, and `refs/rewritten`. Don't assume
WORKTREE-SAFETY.md-395-   isolation you don't have (§10); Git also actively *protects* shared state you might expect it not
WORKTREE-SAFETY.md-396-   to (§9's branch-delete block)
--
WORKTREE-SAFETY.md-398-   `fetch`, `prune`, `repair` — and reach for `read-tree`/`diff`/`status` to inspect before any
WORKTREE-SAFETY.md-399-   command that can overwrite the working tree (`checkout -f`, `reset --hard`, `clean`)
WORKTREE-SAFETY.md:400:7. **Script against `--porcelain` output, never the human-readable table** — `git worktree list`'s
WORKTREE-SAFETY.md-401-   plain format is not a stable, grep-safe API
WORKTREE-SAFETY.md-402-
--
WORKTREE-SAFETY.md-405-## See Also
WORKTREE-SAFETY.md-406-
WORKTREE-SAFETY.md:407:- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
WORKTREE-SAFETY.md-408-- [git-init](https://git-scm.com/docs/git-init) — confirms re-running `init` on an existing repo is safe/non-clobbering
WORKTREE-SAFETY.md-409-- [git-fsck](https://git-scm.com/docs/git-fsck) — integrity check, first step after any suspected `.git` corruption
WORKTREE-SAFETY.md-410-- [git-gc](https://git-scm.com/docs/git-gc) — documents the `--prune=now` concurrency risk cited in §6
WORKTREE-SAFETY.md:411:- Related: [Temp Directory Safety Guide](./temp-dir-safety.md) — for the `mktemp` failure mode that can cascade into worktree destruction
WORKTREE-SAFETY.md-412-
WORKTREE-SAFETY.md-413----

2026-08-17T19:26:02.876457Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 96 column 5
2026-08-17T19:26:06.146737Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 96 column 5
mcp: codebase-memory-mcp/index_status started
mcp: codebase-memory-mcp/index_status (failed)
user cancelled MCP tool call
exec
/bin/zsh -lc "nl -ba README.md | sed -n '325,420p'
nl -ba ROUTER.md | sed -n '1,120p'
nl -ba GUIDING-PRINCIPLES.md | sed -n '1,55p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr
 succeeded in 0ms:
   325	## Glossary — the four terms you'll hit first
   326	
   327	(For how the operating modes — Consult, Relay, Swarm, Marathon — relate to each other, see
   328	[The four modes of operation](#the-four-modes-of-operation) in the beta section above.)
   329	
   330	- **`tick`** — the coordination kernel: a shared local event log (`.tick/events/`) that agents
   331	  claim work through, serialized by an `O_EXCL` lock.
   332	- **relay** — a turn-based loop where one agent builds and another reviews, handing off through
   333	  files instead of a human copy-pasting between windows.
   334	- **Marathon** (`relay-automation/marathon.sh`) — chains several relay build→review phases from a
   335	  `MARATHON.yaml`, in `depends_on` order. The multi-agent coordinator built on the relay loop.
   336	  Headless builders default to subscription-billed `codex`/`agy`; `--builder claude` is available as
   337	  an explicit per-call API opt-in (`CLAUDE_MAX_BUDGET` defaults to $0.50 and `CLAUDE_MAX_TURNS` to 12).
   338	- **agy** — the Antigravity CLI (Google), one of the agents XYZ coordinates alongside Claude Code
   339	  and Codex.
   340	
   341	## FAQ
   342	
   343	### Is XYZ a "graph" — does it do graph engineering?
   344	
   345	Partly, and the parts it leaves out are deliberate. If you arrive with the standard agent-graph
   346	vocabulary (a DAG of nodes and edges, parallel stages, routing decisions), the Glossary entry above
   347	will read as more than it says. The precise answer:
   348	
   349	**What matches.** Phases are real nodes — each gets `marathon-system/<id>/RELAY.md`, a tick token, a
   350	reviewer, a brief, and an artifact allowlist, with an LLM turn as the body. Inside a phase there is
   351	a genuine LLM-selected edge: the reviewer writes `STATUS:`, and `utils/py/relay_drive.py` treats
   352	`Approved`/`Closed` as terminal and anything else as another round, bounded by a round cap. Every phase boundary runs a verification gate, which must be able to *start* before turn 1 — a missing
   353	gate fails fast rather than being skipped. Target repositories with known pre-existing test failures
   354	can specify `--pre-advance-baseline <rc>` (or `MARATHON_GATE_BASELINE=<rc>`) to permit existing failure exit codes
   355	while halting if regressions worsen the code. And the whole run is an inspectable state machine
   356	(`.tick/events/`, `RELAY.md`, `ESCALATION.md` with typed reason codes) rather than a model's
   357	self-report.
   358	
   359	**What doesn't.** There is no DAG. `depends_on` is scalar-only — one dependency per phase — so a
   360	join is inexpressible: "p4 after p2 *and* p3" cannot be written. There is no parallel execution;
   361	`relay-automation/MARATHON.example.yaml` states that phases run strictly one at a time and that a
   362	disjoint write-set does not buy you parallelism. `depends_on` **validates** the order you authored
   363	rather than **deriving** one, which inverts the usual graph model. And a failure halts the chain —
   364	there is no conditional edge to a remediation node.
   365	
   366	So: a sequential chain of agent-driven build→review loops, with hard gates at every boundary. The
   367	scheduling a graph engine exists to automate is handed to the operator on purpose — see
   368	`GUIDING-PRINCIPLES.md` §8, and `utils/swarm-preflight.sh`, which is the *producer* of a run packet
   369	and never its executor.
   370	
   371	Parallelism does exist, but as **swarms**: separate agents in separate worktrees or clones on
   372	disjoint write-sets, coordinated by `tick` locks. That is arranged by the operator, not scheduled
   373	from a dependency graph.
   374	
   375	### Do phases run in parallel? What does `depends_on` actually do?
   376	
   377	**Inside a single marathon plan: No.** Phases run **strictly one at a time**, in the order they appear in the plan.
   378	A phase *without* `depends_on` is not "unordered" or "parallel-safe" — it simply runs when its turn
   379	comes. `depends_on` constrains and validates that order; it does not create a concurrent execution graph.
   380	
   381	It also takes exactly one phase id, unquoted (`depends_on: p3`). The list form `depends_on: [p3]`
   382	parses as the literal string and aborts the plan with an unknown-phase error that points at your
   383	phase ids rather than at the field's shape. Chain them (`p3 → p4 → p5`) to express a longer order.
   384	
   385	Analysing your phases for a disjoint write-set is still worth doing — it is how you learn which
   386	phases genuinely need `depends_on` — but it will not make them concurrent within the same working tree.
   387	
   388	**Where parallelism DOES exist is at the Swarm / Lane level.** Independent tasks and issues (Lanes)
   389	can be dispatched concurrently across **separate standalone clones or isolated worktrees** on disjoint write-sets.
   390	For instance, the `/10days` skill fans out parallel subagents to *triage and inspect* issues simultaneously,
   391	while the execution of any given marathon runner stays strictly sequential across its internal phases to prevent
   392	workspace clobbering and driver-lock contention.
   393	
   394	Always `--dry-run` a new plan first. It parses every field and prints the real execution order at
   395	zero cost, which is the cheapest way to catch both a mis-shaped field and a wrong mental model.
   396	
   397	## Glossary & Execution Model
   398	
   399	To avoid ambiguity across planning, kernel locks, and multi-agent workflows, terminology in this repository adheres to the following definitions:
   400	
   401	| Term | Scope | Definition | Execution & Concurrency Model |
   402	|:---|:---:|:---|:---:|
   403	| **Turn** | Agent | A single headless invocation of an AI builder (e.g. Codex, Qwen) or reviewer (Claude). | Atomic execution step |
   404	| **Relay** | Product | An automated, iterative handoff loop between builder and reviewer until a verified pass or halt condition. | Sequential loop |
   405	| **Phase (Plan)** | Marathon | A single discrete step/milestone within a `MARATHON.yaml` plan (e.g. `p1`, `p2`). | **Strictly Sequential** (1-at-a-time per runner) |
   406	| **Phase (Doc)** | PDDA | A numbered stage of implementation defined in a `PROJECT/2-WORKING/` design specification (Phase 0, Phase 1). | Documentation / roadmap staging |
   407	| **Lane** | Workflow | An autonomous execution pipeline dedicated to solving a single GitHub issue or task. | Single track |
   408	| **Wave** | Planner | A batch of independent lanes identified by disjoint write-sets (via `marathon-plan.sh`) that can be safely scheduled together. | Batch scheduling |
   409	| **Marathon** | Automation | A multi-phase runner (`marathon-drive.sh`) that executes an ordered sequence of phases, gates, and git commits on a branch. | Serial orchestrator |
   410	| **Swarm** | Architecture | Multiple independent agents running concurrently across **separate clones or worktrees**, coordinated by `tick` locks. | **Parallel / Distributed** |
   411	| **`depends_on`** | Config | An authoring validation assertion in a marathon plan verifying prerequisite phase completion before starting the next. | Assertion gate (not parallel DAG) |
   412	| **`tick` Kernel** | Kernel | The local, serverless event-log engine managing collision-free task claims and path-scoped locks under `.tick/events/`. | ACID / Event-sourced |
   413	
   414	## Repo map
   415	
   416	- `relay-automation/` — scripts and operator docs for poll-driven relays, watchdogs, headless turn-takers, and consult.
   417	- `skills/` — packaged skill surfaces, including `agent2agent`, `relay-xyz`, `relay-automation`, `xyz`, consult helpers, and
   418	  [`ponytail`](skills/ponytail/SKILL.md) (the `/ponytail` lens definition cited throughout
   419	  `PROJECT/` docs and PDDA's `/idea` Phase 0 — see [GH-180](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/180)).
   420	  Claude Code only scans `~/.claude/skills/`, so a fresh clone won't see these until you symlink them in —
     1	# ROUTER.md
     2	
     3	This file is the first entry point for an AI agent working in this repo: it tells you what to read, what to run, and which files are canonical.
     4	
     5	## Role split
     6	
     7	- `ROUTER.md` = startup order and canonical entry points
     8	- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof
     9	- `README.md` = human-facing repo/product overview
    10	- `ROADMAP.md` = pointer ledger of queued, current, completed, attempted, and deferred work
    11	- `CHANGELOG.md` = the end-of-iteration running log (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
    12	- `RELEASES.md` = forward-looking release-planning ledger (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
    13	- `HARNESS-MODELS-REGISTRY.md` = evaluated agent harnesses, supported model grades (A/B/C), and CLI flags
    14	- `PROJECT/**` docs = canonical execution detail for a specific effort
    15	- `PROJECT/PDDA.md` = document contract and automation rules (incl. the CHANGELOG contract)
    16	- `PROJECT/CONSTITUTION.md` = the policy of record: PDDA's lane and its non-negotiables (deterministic-before-LLM, verified-success-only, reversibility, local-first)
    17	- `PROJECT/DO-NOT-BUILD.md` = the anti-scope list — product directions PDDA must not become (companion to `CONSTITUTION.md`)
    18	
    19	## Startup sequence
    20	
    21	1. Read `ROUTER.md` to understand the repo's operating order and canonical files. -> expect one clear next file, not a repo-wide scavenger hunt.
    22	2. Read `AGENTS.md` before making recommendations or edits. -> expect explicit assumptions, a reversibility read on consequential changes, and verified claims only.
    23	3. Read `ROADMAP.md` to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; `ROADMAP.md` is a pointer ledger, not a plan body.
    24	4. Read the linked `PROJECT/**` document that owns the work you are touching. -> expect the near-top `## Status` table to tell you what was just completed and what is next.
    25	5. If the task touches project docs, read `PROJECT/PDDA.md` and follow the PDDA contract. -> expect `PROJECT/2-WORKING` docs to have frontmatter, the exact status table, and QA gates when phased.
    26	6. Before reporting success on code or runtime work, run `./validate.sh`. -> expect the suite to stay green; do not claim completion if it fails or was skipped.
    27	7. Before reporting success on doc-hygiene or roadmap work, run `utils/pdda/pdda.sh run` (or the relevant `utils/pdda/pdda.sh <check>` subcommand). -> expect deterministic findings first, then any LLM review.
    28	
    29	## Canonical rules
    30	
    31	- Do not put phase checklists, build steps, or deep execution notes in `ROADMAP.md`.
    32	- Every active doc in `PROJECT/2-WORKING/` must be reflected by a pointer in `ROADMAP.md` — a one-line ledger entry that links it. A working doc that should not appear opts out with `roadmap_exempt: true` in its frontmatter. Enforced by `utils/pdda/pdda.sh roadmap-coverage`; governance lives in `PROJECT/PDDA.md` → "ROADMAP.md contract".
    33	- Every captured GitHub issue doc in `PROJECT/1-INBOX/GH-*.md` must also be parked in `ROADMAP.md` as a one-line queue entry immediately at intake, then promoted or removed later. Enforced by `utils/pdda/pdda.sh roadmap-coverage`; governance lives in `PROJECT/PDDA.md` → "GitHub issue intake" + "ROADMAP.md contract".
    34	- Do not create a second competing plan when a canonical `PROJECT/**` doc already exists.
    35	- Issue-first: any change beyond a **2–3 line** fix opens a GitHub issue first, then a pointer doc **named after the issue** (`GH-<number>-VERY-SHORT-DESC.md`, e.g. `GH-1234-SHOWME-COMMAND.md`), and that capture is **parked in `ROADMAP.md` immediately** before execution begins. The issue is the signal stream; the pointer doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt. Governed by `PROJECT/PDDA.md` → "GitHub issue intake".
    36	- Runtime triage labels: since the `XYZ_PYTHON` flip the harness is dual-runtime, so any harness-bug issue gets a `runtime:` label — `runtime:python` (default path), `runtime:bash` (`XYZ_PYTHON=0` opt-out), or `runtime:parity` (the twins diverge). `/file-xyz-bug` harvests and applies it; for in-repo intake (`/triage`, hand-filed `gh issue create`) apply it by hand. Omit rather than guess — a wrong runtime tag misroutes triage.
    37	- Do not override deterministic PDDA findings with prose.
    38	- Do not report a win you did not verify with the relevant script or test.
    39	- Update `CHANGELOG.md` at the end of each iteration; its governance lives in `PROJECT/PDDA.md` — do not re-specify CHANGELOG rules in `AGENTS.md` or elsewhere.
    40	
    41	## Command rails
    42	
    43	For repo correctness:
    44	
    45	```bash
    46	bash githooks/install.sh        # ONCE PER CLONE — wires the pre-push gate (GH-544)
    47	bash githooks/install.sh --check # is this clone gated? exit 1 if not
    48	./validate.sh              # the gate — PARALLEL by default (GH-544), ~4 min, auto-sized to the host
    49	./validate.sh --print-mode # which mode would this host pick, and why — runs nothing
    50	./validate.sh --sequential # force the sequential run (~16 min)
    51	bash ci-local.sh           # the QUALIFYING run — sequential + writes the gate record (GH-509/GH-536)
    52	```
    53	
    54	**Hosted CI fires on nothing while this repo is private (GH-544).** The gate runs locally at the push
    55	boundary instead, so `githooks/install.sh` is part of setting up a clone — the hook lives in
    56	`.git/hooks/`, which does not travel with a clone, and an uninstalled one pushes unverified. One
    57	install covers every branch and every linked worktree of that clone (GH-549). Bypass with
    58	`git push --no-verify` or `XYZ_SKIP_PREPUSH=1`; both announce themselves. Re-arm CI when the repo
    59	goes public (free there).
    60	
    61	**Parallel became the default on 2026-08-14 (GH-544)** because the local gate is the only gate during
    62	the private phase, and a 16-minute gate does not get run — it gets skipped, which is worse than a
    63	3-minute one. Width is detected from the host (cores − 2, capped at 8); below 4 cores, or where
    64	`xargs -P` is unsupported, it **falls back to sequential and says so**. Every run prints the mode it
    65	chose and the reason, so a fallback is never silent. Override with `--parallel N`, `--sequential`, or
    66	`XYZ_VALIDATE_PARALLEL` (a flag always beats the env var).
    67	
    68	**What still qualifies a claim is unchanged.** `./validate.sh` in either mode is a self-check;
    69	`ci-local.sh` is the run that writes the evidence record, it does **not** call `validate.sh`, and it
    70	stays sequential. The macOS promotion boundary in `ci.yml` pins `--sequential` explicitly for the same
    71	reason. GH-528 Phase 2 (multi-width stress evidence) is still **owed** — the flip was an operator
    72	decision taken with that evidence outstanding, mitigated by the announced fallback rather than
    73	discharged. See `PROJECT/2-WORKING/GH-528-TEST-SUITE-RECALIBRATION.md`, #509 and #544.
    74	
    75	For document hygiene:
    76	
    77	```bash
    78	utils/pdda/pdda.sh run
    79	```
    80	
    81	For targeted PDDA debugging (subcommands of the single dispatcher):
    82	
    83	```bash
    84	utils/pdda/pdda.sh frontmatter
    85	utils/pdda/pdda.sh status-table
    86	utils/pdda/pdda.sh hardcoded-paths
    87	utils/pdda/pdda.sh roadmap
    88	utils/pdda/pdda.sh roadmap-coverage
    89	utils/pdda/pdda.sh changelog
    90	utils/pdda/pdda.sh stale
    91	utils/pdda/pdda.sh issue-doc-sync   # warn-only: flags 2-WORKING/GH-*.md docs drifted from their GitHub issue state
    92	utils/pdda/pdda.sh releases         # validate RELEASES.md, the OPTIONAL release-planning ledger (warn-only; skips a missing file)
    93	utils/pdda/pdda.sh releases-current # read-only roll-up: RELEASES.md entries whose Status isn't "Shipped"
    94	utils/pdda/pdda.sh quad-concepts    # opt-in: requires a "## Quad Concepts" section of 1-4 bullets (lever: .pdda-quad / PDDA_QUAD)
    95	utils/pdda/pdda.sh glance           # read-only roll-up: title + Quad Concepts for each PROJECT/2-WORKING doc
    96	utils/pdda/pdda.sh gh-refresh       # refresh the cached GitHub issue-state file issue-doc-sync reads offline (needs gh)
    97	utils/pdda/pdda.sh catchup          # LLM repo triage + ROUTER.md recommendations (delegates to pdda-catchup.sh)
    98	utils/pdda/pdda.sh doc-ready        # LLM readiness review — set PDDA_LLM_BIN (codex/claude/agy) for recommendations, else it self-skips
    99	```
   100	
   101	## Routing hints
   102	
   103	- If the task is about current priorities or active work, start in `ROADMAP.md`, then follow the linked `PROJECT/**` doc.
   104	- If the task is about fresh GitHub intake or duplicate-prevention, start in `ROADMAP.md`'s queue, then follow the linked `PROJECT/1-INBOX/GH-*.md` capture doc.
   105	- If the task is about document quality, active-doc lifecycle, roadmap sprawl, or automation policy, start in `PROJECT/PDDA.md`.
   106	- If the task is about the CHANGELOG, provenance, or end-of-iteration logging, the governance is in `PROJECT/PDDA.md` (the "CHANGELOG.md — end-of-iteration record" contract).
   107	- If the task is about release planning, ledger health, cleanup, authoring, or publishing, invoke `/releases`. It reads and synthesizes `RELEASES.md` first, then routes explicit requests into confirmation-gated cleanup, planning, or publication; governance is in `PROJECT/PDDA.md` (the "RELEASES.md — release ledger" contract). It conditionally points strategic drift to `/radar` and a frozen path-to-ship to `/finish-line` without duplicating either workflow.
   108	- If the task is about the `tick` runtime, event projection, or multi-agent coordination kernel, start in `README.md`, then `bin/`, `src/`, `test/`, and the active project doc.
   109	- If the task is about the **Aider ↔ OpenRouter** turn-taker lane (`relay-automation/aider-turn.sh` — an OpenAI-standard build lane discrete from Codex; `AIDER_MODEL`/`OPENROUTER_API_KEY`, `--builder aider`), start in `PROJECT/3-COMPLETED/GH-77-AIDER-OPENROUTER-LANE.md`. The shim owns the tick token ops (Aider can't run shell mid-turn), asserts token ownership before launching Aider, and runs Aider `--no-auto-commits` (the harness commits).
   110	- If the task is about running, driving, or reviewing via the relay (`relay-automation/` — `relay-drive.sh`, `poll.sh`, the turn shims, `marathon*.sh`), **invoke the `relay-xyz` skill first — do not improvise the handoff or hand-roll a harness from `ls relay-automation/`.** The skill owns the locator, sandbox rules, exit codes, and the safety boundary; a `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) blocks driving a harness driver before the skill is loaded. For the two live-Claude-windows, same-machine duel recipe (Reporter↔Maintainer with a human go-gate), the copy-paste form is [relay-automation/DUELING-CLAUDES.md](relay-automation/DUELING-CLAUDES.md).
   111	- If the task is about the ATE (Automated Testing Environment) skill — unattended Aider variation-test fuzzing driven by a local Gemma worker under `utils/ate/` — start in `utils/ate/SKILL.md`. Currently hardcoded to Aider despite the generic name/description; generalizing it to other harnesses is tracked, not urgent, in `PROJECT/1-INBOX/GH-191-ATE-GENERALIZE-HARNESS.md`.
   112	- If the task is about relay session telemetry, the `focus5float` health feed, or extraction scripts under `utils/telemetry/`, start in `PROJECT/1-INBOX/GH-24-RELAY-TELEMETRY-EXTRACTOR.md`.
   113	- If the task is about live per-session completion telemetry — the `XYZ.json` log every relay/marathon/swarm session appends to at the harness repo root (schema: `harness`/`sessionId`/`health`/`title`/`description`/`updatedAt`), the shared writer `utils/telemetry/append-xyz-completion.sh`, or the shared health mapping `utils/telemetry/health-lib.sh` — start in `PROJECT/1-INBOX/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md`. `XYZ.json` is local + gitignored (machine-specific).
   114	- If the task is about cross-repo HQ tooling (`utils/hq/` — `hq.sh` single-repo actions, `rollup.sh` the Obsidian daily ROADMAP rollup, `marathon-scan.sh` the cross-repo marathon-preflight aggregator, `hq-lib.sh` the shared repo registry), start in `PROJECT/3-COMPLETED/GH-27-ROADMAP-DASHBOARD.md` and `PROJECT/3-COMPLETED/GH-158-HQ-MARATHON-SCAN.md`. The two rollups are deliberately separate today (`rollup.sh` → Obsidian, generic; `marathon-scan.sh` → hub repo, preflight-aware) and are not yet bridged — tracked in `PROJECT/1-INBOX/GH-192-HQ-MARATHON-OBSIDIAN-ROLLUP.md`.
   115	- If the task is about a proposed roadmap-steward agent, start here, then read `PROJECT/PDDA.md` and its `Proposed roadmap steward extension` section.
   116	- Issue-first SOP: any change beyond a 2–3 line fix (and every project plan) opens a GitHub issue *first*, then gets a pointer doc named after the issue at `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md` — e.g. `GH-1234-SHOWME-COMMAND.md` — and that capture is parked in the `ROADMAP.md` queue immediately (format + lifecycle owned by `PROJECT/PDDA.md` → "GitHub issue intake"), following the normal `1-INBOX` → `2-WORKING` flow. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt and commit directly.
     1	# Guiding Principles
     2	
     3	North star for **xyz-3-agents-swarm**, the multi-agent coordination harness behind the `tick` event-log kernel and `relay-automation/` relay stack. When a choice is unclear, the option that keeps agents synchronized, contained, and verifiable — without leaking or destroying work — wins. AGENTS.md is the behavioral playbook; ROUTER.md is the entry-point map; this is the *why*.
     4	
     5	## Purpose
     6	
     7	`tick` coordinates Claude Code, Codex, and agy (Antigravity CLI) on the same branch without collision: a shared local event log under `.tick/events/`, claims serialized by `O_EXCL` locks, and a `Marathon` harness that chains multi-phase build→review cycles from a `MARATHON.yaml`. The relay layer (`relay-automation/`) drives headless turns, isolates agent writes to worktrees, and enforces an allowlist so no headless agent destroys work it didn't intend to touch. The goal: a multi-agent swarm safe enough to run against a real external codebase and correct enough that its output is worth shipping.
     8	
     9	## The quality bar
    10	
    11	Every agent turn is a signal. A turn is high-quality only when it is all four:
    12	
    13	- **Attested** — carries its receipts: source, evidence, confidence. Never a bare verdict. A relay review names which claim is wrong and why; a build turn names the seam it touched.
    14	- **Relevant** — ranked, not dumped. Volume is not value. One real bug beats five nits and a phantom.
    15	- **Fresh** — current, not stale. A turn that reads a stale `STATE.md` or misses an epoch fence is wrong by construction.
    16	- **Structured** — one shape, clean for the operator to read and for downstream agents to feed on.
    17	
    18	Fail a pillar, and the turn, feature, or relay review isn't done.
    19	
    20	## How it's built
    21	
    22	1. **Coordination is local-transport only.** `.tick/events/` is the shared bus; claims resolve from there, not from a remote. No per-event push/fetch; no remote dependency at runtime. A coordination primitive that reaches out is a coordination primitive that can fail or leak.
    23	
    24	2. **One canonical event log; every surface is a projection.** `tick` accretes events; `STATE.md` is the current projection. Reads go through the projection; writes go through a `claim/take/scope/done` verb. Nothing canonical lives in two places where it can drift. An agent that hard-codes state outside `.tick/` is creating drift.
    25	
    26	3. **Containment is non-negotiable.** A headless turn must not: self-commit mid-turn, orphan a peer's concurrent commit, or write outside its allowlist. The allowlist, worktree isolation, and commit-bypass guard exist because a driven agent will do all three if unconstrained — not hypothetically, but as documented live incidents (GH-13, GH-14, GH-17). New relay paths must clear the containment bar before they ship.
    27	
    28	4. **Skill-first; never improvise the harness.** The `relay-xyz` skill owns the locator, sandbox rules, exit codes, and the safety boundary. A session that improvises those from `ls relay-automation/` silently skips the skill's safety layer. The `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) enforces this by blocking driver calls before the skill loads. Add capabilities to the skill; do not work around it.
    29	
    30	5. **Adversarially proven before commercially viable.** The harness exists to run against real codebases. Features in the adversarial-hardening track (epoch fencing, chaos suite, cross-repo E2E) must be verified to survive deliberate abuse — stale writers, zombie claims, macOS case-sensitivity, concurrent peer commits — not just the happy path. A feature that clears the happy path and skips chaos is half-done.
    31	
    32	6. **Build durable, not band-aid.** Durable means it removes the root cause and the next planned change builds on it — not a patch torn out when the obvious next feature lands. A band-aid is wasted work unless a demo strictly needs one, and a demo band-aid is tagged for removal so it isn't silently inherited.
    33	
    34	7. **Least code that clears the bar.** Node standard library only — no deps, no lockfile; the repo ships no root manifest. Prefer reusing or extending what exists; the smallest change that stays correct, contained, and durable wins. Net-new code is a cost to justify. Deleting code counts as progress.
    35	
    36	8. **Honest; the operator decides.** Surface what failed and why — never mask a stall as success or an escalation as a stall. A headless turn self-repairs within a bounded exit-code menu (`exit 3` stall, `exit 4` escalated-by-design, `exit 6` containment revert), then stops; it never loops forever or silently swallows an error. Destructive actions require explicit authorization.
    37	
    38	9. **Docs are resumable runtime state (PDDA).** Agent work is stoppable, resumable, and handed off from `PROJECT/**` alone — ROUTER points, project docs hold detail, CHANGELOG logs dated outcomes. ROADMAP.md is a pointer/ledger only; execution detail lives in the linked `PROJECT/**` doc. If reality and the docs disagree, the docs are the bug.
    39	
    40	10. **Done means verified.** "Done" is `validate.sh` green, the relevant PDDA checks passing, and any relay review returning `Approved` — not work that looks finished. An unverified success claim is itself a low-quality signal.
    41	
    42	11. **Issue-first; every non-trivial change has a signal stream.** Any change beyond a 2–3 line fix opens a GitHub issue first, then gets a `GH-<number>` in-repo pointer doc, then lands. The issue is the machine-queryable signal stream; the `PROJECT/**` doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt.
    43	
    44	12. **Independent Verification (Separated Grading)** — The agent that produces a turn must not be the sole grader of its own quality. Verification must be performed by an independent deterministic check or a separate reviewing agent before the lock releases. Applies to: the relay's structural block validator (`bin/validate-relay-block` — Phase 1 of GH-21), consult-verify diversity (Phase 3), and any other post-generation quality gate.
    45	
    46	13. **A green gate without a witnessed red control is not evidence.** Every new or materially changed decision gate ships a recorded demonstration that it fails for the right reason: a pre-fix replay, deliberate mutation, or controlled bad fixture. Do not mistake a check that validates the artifact it just generated (#351) or a parity check that compares a lane to itself (#348) for evidence; both shapes are structurally unable to falsify their claim.
    47	
    48	## Applying this
    49	
    50	Adding a feature or weighing a tradeoff, ask: *does this keep agents coordinated without collision, contained within their scope, and verifiable to an outside observer? And is "done" provable by running `validate.sh`?* If any answer is no, reconsider.
    51	
    52	---
    53	
    54	## Conventions
    55	

2026-08-17T19:26:10.738168Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 96 column 5
mcp: codebase-memory-mcp/index_repository started
mcp: codebase-memory-mcp/index_repository (failed)
user cancelled MCP tool call
2026-08-17T19:26:16.356196Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 96 column 5
exec
/bin/zsh -lc "rg -n -C 2 --glob '"'!README.md'"' --glob '"'!PROJECT/**'"' 'depends_on|strictly one at a time|disjoint write-sets|Wave|wave|standalone clones|separate.*clone|marathon-plan|swarm' relay-automation utils test skills | head -600" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr
 succeeded in 0ms:
skills/file-xyz-bug/SKILL.md-1----
skills/file-xyz-bug/SKILL.md-2-name: file-xyz-bug
skills/file-xyz-bug/SKILL.md:3:description: File a bug against the xyz-3-agents-swarm harness from ANY repo or session — lands a PDDA-compliant capture in that repo's PROJECT/1-INBOX/ (GH-<n>-*.md), files the tracking GitHub issue, and parks a one-line ROADMAP pointer, without touching the repo you are standing in. Use when the xyz harness misbehaves while you are working somewhere else — a relay/marathon driver fails, `tick` misbehaves, a turn shim exits wrong, a vendored `.xyz/` drifts, an xyz skill (relay-xyz, consult, hq, xyz) breaks — and you want it recorded where it will actually be triaged instead of lost in the current session. Trigger on /file-xyz-bug, "file an xyz bug", "report this to the swarm repo", "log this harness bug upstream", "send this bug to xyz". NOT for bugs in the repo you are currently working on (use that repo's own intake, e.g. /idea or /triage).
skills/file-xyz-bug/SKILL.md-4----
skills/file-xyz-bug/SKILL.md-5-
--
skills/file-xyz-bug/SKILL.md-7-
skills/file-xyz-bug/SKILL.md-8-You hit a harness bug **while working somewhere else**. This skill records it in the repo that
skills/file-xyz-bug/SKILL.md:9:owns the harness — `xyz-3-agents-swarm` — as a proper PDDA intake capture, then gets out of the
skills/file-xyz-bug/SKILL.md-10-way so you can go back to what you were doing.
skills/file-xyz-bug/SKILL.md-11-
--
skills/file-xyz-bug/SKILL.md-34-     [ -n "$L" ] && [ -x "$L" ] && break
skills/file-xyz-bug/SKILL.md-35-   done
skills/file-xyz-bug/SKILL.md:36:   [ -x "$L" ] || { echo "file-xyz-bug: locator not found — set XYZ_REPO to your xyz-3-agents-swarm clone"; exit 1; }
skills/file-xyz-bug/SKILL.md-37-
skills/file-xyz-bug/SKILL.md-38-   eval "$("$L" --env)" || exit 1   # XYZ_REPO, XYZ_INBOX, XYZ_BRANCH, XYZ_DIRTY, XYZ_SLUG,
--
relay-automation/xyz-vendor.sh-317-# got it). Copying whole dirs makes the vendored .xyz a COMPLETE, drift-free XYZ install — every
relay-automation/xyz-vendor.sh-318-# relay / marathon / consult / aider / self-improve feature runs standalone, per repo, with no
relay-automation/xyz-vendor.sh:319:# dependency on the central xyz-3-agents-swarm checkout.
relay-automation/xyz-vendor.sh-320-#   relay-automation/  all turn shims (codex/agy/aider/gemini/claude), consult, marathon runtime,
relay-automation/xyz-vendor.sh-321-#                      the self-improve loop, hooks/, docs, example configs
--
utils/marathon-plan-zones.default.json-9-      ],
utils/marathon-plan-zones.default.json-10-      "inferKeywordRegex": "relay-turn-lib|containment kernel|bin/tick|relay-drive|commit semantics|epoch fenc",
utils/marathon-plan-zones.default.json:11:      "maxPerWave": 1,
utils/marathon-plan-zones.default.json-12-      "penalty": 2,
utils/marathon-plan-zones.default.json-13-      "escalateOrchestratorOnly": true
--
skills/file-xyz-bug/install.sh-61-  else
skills/file-xyz-bug/install.sh-62-    echo "file-xyz-bug: WARNING — find-xyz.sh could not resolve the intake repo." >&2
skills/file-xyz-bug/install.sh:63:    echo "  Set XYZ_REPO=/path/to/your/xyz-3-agents-swarm clone." >&2
skills/file-xyz-bug/install.sh-64-  fi
skills/file-xyz-bug/install.sh-65-else
--
relay-automation/DUELING-CLAUDES.md-15-  smallest change, then **stops before commit/push for your "go"** — the one human gate.
relay-automation/DUELING-CLAUDES.md-16-
relay-automation/DUELING-CLAUDES.md:17:All commits land in **this** repo (`xyz-3-agents-swarm`), so no `--target-root` is needed.
relay-automation/DUELING-CLAUDES.md-18-
relay-automation/DUELING-CLAUDES.md-19-## How it works (why it's zero-code)
--
relay-automation/DUELING-CLAUDES.md-32-
relay-automation/DUELING-CLAUDES.md-33-```bash
relay-automation/DUELING-CLAUDES.md:34:bash "~/Documents/GH Repos/xyz-3-agents-swarm/skills/relay-xyz/install.sh"
relay-automation/DUELING-CLAUDES.md-35-```
relay-automation/DUELING-CLAUDES.md-36-
--
relay-automation/DUELING-CLAUDES.md-44-
relay-automation/DUELING-CLAUDES.md-45-```bash
relay-automation/DUELING-CLAUDES.md:46:cd "~/Documents/GH Repos/xyz-3-agents-swarm"
relay-automation/DUELING-CLAUDES.md-47-TOKEN="DUELING-$(date +%m%d-%H%M)"
relay-automation/DUELING-CLAUDES.md-48-DEADLINE=$(date -v+45M +%s)   # compute ONCE here — NEVER inside the /loop string ($(date) there re-evaluates every tick and never expires)
--
relay-automation/DUELING-CLAUDES.md-67-
relay-automation/DUELING-CLAUDES.md-68-```
relay-automation/DUELING-CLAUDES.md:69:/loop 60s run env TICK_REPO_ROOT="~/Documents/GH Repos/xyz-3-agents-swarm" "~/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/poll.sh" --mode relay --agent claude-a --claude-agents "claude-a,claude-b" --relay-task $TOKEN --relay-file "~/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-22/dueling-claudes.md" --artifact "~/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-22/dueling-claudes.md" --deadline <DEADLINE-literal-from-step-0> --dry-run ; if it printed "DECISION: run-runner", take your claude-a turn on that relay file per its embedded instructions (file/refine the bug report, citing the other repo's files by ABSOLUTE path), append your block, set NEXT: claude-b, then hand off the lock with the repo-root env + ABSOLUTE bin/tick (a bare `tick` from your foreign CWD silently no-ops — this is the #1 deadlock cause): TICK_REPO_ROOT="~/Documents/GH Repos/xyz-3-agents-swarm" "~/Documents/GH Repos/xyz-3-agents-swarm/bin/tick" release $TOKEN --agent claude-a --to claude-b ; then commit the relay file (git -C the xyz repo; don't push — claude-b pushes). On "DECISION: stop", CronList + CronDelete this loop. Else do nothing.
relay-automation/DUELING-CLAUDES.md-70-```
relay-automation/DUELING-CLAUDES.md-71-
--
relay-automation/DUELING-CLAUDES.md-74-
relay-automation/DUELING-CLAUDES.md-75-```
relay-automation/DUELING-CLAUDES.md:76:/loop 60s run "~/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/poll.sh" --mode relay --agent claude-b --claude-agents "claude-a,claude-b" --relay-task $TOKEN --relay-file "~/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-22/dueling-claudes.md" --artifact "~/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-22/dueling-claudes.md" --deadline <DEADLINE-literal-from-step-0> --dry-run ; if it printed "DECISION: run-runner", take your claude-b turn: verify the reported bug, fix it in this repo with the smallest change, append your turn block to the relay file, set NEXT: claude-a, then SHOW ME THE DIFF AND STOP — do NOT commit, push, or release the token until I say "go". After "go": commit, push, then `tick release $TOKEN --agent claude-b --to claude-a` (bare `tick` is fine here — window B's CWD is the xyz repo). On "DECISION: stop", CronList + CronDelete this loop. Else do nothing.
relay-automation/DUELING-CLAUDES.md-77-```
relay-automation/DUELING-CLAUDES.md-78-
--
relay-automation/DUELING-CLAUDES.md-112-
relay-automation/DUELING-CLAUDES.md-113-```bash
relay-automation/DUELING-CLAUDES.md:114:cd "~/Documents/GH Repos/xyz-3-agents-swarm"
relay-automation/DUELING-CLAUDES.md-115-TOKEN="DUELING-CODEX-0623"                 # fresh name per run; a done token can't reopen
relay-automation/DUELING-CLAUDES.md-116-DEADLINE=$(date -v+60M +%s)                # e.g. 1782251974 — paste this literal into BOTH loops
--
relay-automation/DUELING-CLAUDES.md-127-
relay-automation/DUELING-CLAUDES.md-128-```
relay-automation/DUELING-CLAUDES.md:129:/loop 60s run env TICK_REPO_ROOT="~/Documents/GH Repos/xyz-3-agents-swarm" "~/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/poll.sh" --mode relay --agent claude-a --claude-agents "claude-a,claude-b" --relay-task DUELING-CODEX-0623 --relay-file "~/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-23/codex-relay-review.md" --artifact "~/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-23/codex-relay-review.md" --deadline 1782251974 --dry-run ; if it printed "DECISION: run-runner", take your claude-a (Reporter) turn on that relay file per its embedded TAKE YOUR TURN block — do a CODE/PROTOCOL REVIEW of "~/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/codex-turn.sh" and "~/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh" (you are on a FOREIGN repo — read by ABSOLUTE path, cite findings by ABSOLUTE path:line, grade each [Blocker]/[Should]/[Nit]/[Pass] with a concrete proposed fix, set a Verdict), append your block to the relay file by absolute path, set NEXT: claude-b, then hand off the lock with the repo-root env + ABSOLUTE bin/tick: TICK_REPO_ROOT="~/Documents/GH Repos/xyz-3-agents-swarm" "~/Documents/GH Repos/xyz-3-agents-swarm/bin/tick" release DUELING-CODEX-0623 --agent claude-a --to claude-b ; then stage+commit the relay file in the xyz repo (git -C "~/Documents/GH Repos/xyz-3-agents-swarm" add/commit — a bare git from your CWD hits the wrong repo; do NOT push, claude-b pushes after the operator go). On "DECISION: stop", CronList + CronDelete this loop, then stop. Else do nothing.
relay-automation/DUELING-CLAUDES.md-130-```
relay-automation/DUELING-CLAUDES.md-131-
--
relay-automation/DUELING-CLAUDES.md-134-
relay-automation/DUELING-CLAUDES.md-135-```
relay-automation/DUELING-CLAUDES.md:136:/loop 60s run "~/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/poll.sh" --mode relay --agent claude-b --claude-agents "claude-a,claude-b" --relay-task DUELING-CODEX-0623 --relay-file "~/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-23/codex-relay-review.md" --artifact "~/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-23/codex-relay-review.md" --deadline 1782251974 --dry-run ; if it printed "DECISION: run-runner", take your claude-b (Maintainer) turn: verify each Reporter finding against the REAL code in relay-automation/codex-turn.sh + relay-turn-lib.sh, fix the [Blocker]/[Should] ones with the smallest change, log a disposition for every finding, append your turn block with a one-line Verification, set NEXT: claude-a — then SHOW ME THE DIFF AND STOP. Do NOT commit, push, or release the token until I say "go". After "go": git commit, git push origin main, then release: TICK_REPO_ROOT="~/Documents/GH Repos/xyz-3-agents-swarm" "~/Documents/GH Repos/xyz-3-agents-swarm/bin/tick" release DUELING-CODEX-0623 --agent claude-b --to claude-a. On "DECISION: stop", CronList + CronDelete this loop, then stop. Else do nothing.
relay-automation/DUELING-CLAUDES.md-137-```
relay-automation/DUELING-CLAUDES.md-138-
--
relay-automation/DUELING-CLAUDES.md-151-  xyz repo from its own foreign CWD, that bypass — not the path — is what keeps prompting you.
relay-automation/DUELING-CLAUDES.md-152-- **Add the poll command to `permissions.allow`** (the prefix rule) so the sandboxed command itself
relay-automation/DUELING-CLAUDES.md:153:  is pre-approved, e.g. an entry matching `Bash(~/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/poll.sh:*)`.
relay-automation/DUELING-CLAUDES.md-154-
relay-automation/DUELING-CLAUDES.md-155-Between the two, the per-minute poll stops prompting entirely. (The infrequent turn actions —
--
skills/file-xyz-bug/find-xyz.sh-1-#!/usr/bin/env bash
skills/file-xyz-bug/find-xyz.sh-2-#
skills/file-xyz-bug/find-xyz.sh:3:# find-xyz.sh — device-agnostic locator for the xyz-3-agents-swarm INTAKE repo.
skills/file-xyz-bug/find-xyz.sh-4-#
skills/file-xyz-bug/find-xyz.sh-5-# Prints the absolute path to the clone that owns PROJECT/1-INBOX/ — the repo a bug
--
skills/file-xyz-bug/find-xyz.sh-75-
skills/file-xyz-bug/find-xyz.sh-76-if [ -z "$XYZ" ]; then
skills/file-xyz-bug/find-xyz.sh:77:  echo "find-xyz: could not locate an xyz-3-agents-swarm clone with PROJECT/1-INBOX/." >&2
skills/file-xyz-bug/find-xyz.sh:78:  echo "  Set XYZ_REPO=/path/to/your/xyz-3-agents-swarm clone and retry." >&2
skills/file-xyz-bug/find-xyz.sh-79-  exit 1
skills/file-xyz-bug/find-xyz.sh-80-fi
--
relay-automation/MARATHON.example.yaml-1-# MARATHON.example.yaml — a multi-phase plan for marathon.sh (Phase 4 / M5).
relay-automation/MARATHON.example.yaml-2-# Run it with:  relay-automation/marathon.sh --plan relay-automation/MARATHON.example.yaml
relay-automation/MARATHON.example.yaml:3:# Each phase runs through marathon-drive.sh in depends_on order; the chain HALTS on the first
relay-automation/MARATHON.example.yaml-4-# phase that fails its review/gate (that phase's ESCALATION.md is left behind), and emits a
relay-automation/MARATHON.example.yaml-5-# marathon.complete event only when every phase is approved.
relay-automation/MARATHON.example.yaml-6-#
relay-automation/MARATHON.example.yaml-7-# SEQUENCING (GH-241): phases run STRICTLY ONE AT A TIME — there is no concurrent execution, and
relay-automation/MARATHON.example.yaml:8:# `depends_on` does not create the ordering, it only constrains it. A phase WITHOUT `depends_on`
relay-automation/MARATHON.example.yaml-9-# is not "unordered" or "parallel-safe"; it simply runs in plan order whenever its turn comes.
relay-automation/MARATHON.example.yaml-10-# Analysing your phases for a disjoint write-set is still worthwhile (it is how you know which
relay-automation/MARATHON.example.yaml:11:# phases genuinely need `depends_on`), but a disjoint write-set does NOT buy you parallelism here.
relay-automation/MARATHON.example.yaml-12-#
relay-automation/MARATHON.example.yaml-13-# ALWAYS `--dry-run` a new plan before firing it. It parses the plan, validates every field, and
--
relay-automation/MARATHON.example.yaml-25-# Plan location (GH-212): once this is a REAL plan for a tracked issue (not this shipped example),
relay-automation/MARATHON.example.yaml-26-# the MARATHON.yaml + its phase briefs belong under PROJECT/2-WORKING/<capture-doc>/ in the target
relay-automation/MARATHON.example.yaml:27:# repo — never a standalone top-level folder like marathon-plans/<slug>/. `marathon.sh --plan`
relay-automation/MARATHON.example.yaml-28-# refuses a plan outside PROJECT/2-WORKING/ unless MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 is set.
relay-automation/MARATHON.example.yaml-29-# (This example is exempt: it lives under the harness's own relay-automation/ home, not a target repo.)
--
relay-automation/MARATHON.example.yaml-46-#   turn_timeout_s     per-turn wall-clock cap exported as RELAY_TURN_TIMEOUT_S            (optional)
relay-automation/MARATHON.example.yaml-47-#   max_review_rounds  round-cap = 2*N+1 (default 2 → cap 5)                              (optional)
relay-automation/MARATHON.example.yaml:48:#   depends_on         run this phase only after the named phase is approved              (optional,
relay-automation/MARATHON.example.yaml:49:#                      SCALAR ONLY — one phase id, unquoted: `depends_on: p3`. NOT a list:
relay-automation/MARATHON.example.yaml:50:#                      `depends_on: [p3]` parses as the literal string "[p3]" and aborts the
relay-automation/MARATHON.example.yaml:51:#                      plan with "depends_on unknown phase '[p3]'". A phase can have at most
relay-automation/MARATHON.example.yaml-52-#                      one dependency; chain them (p3 → p4 → p5) to express a longer order.)
relay-automation/MARATHON.example.yaml-53-#   name               human label for logs                                              (optional)
--
relay-automation/MARATHON.example.yaml-69-    artifact: src/lease.js
relay-automation/MARATHON.example.yaml-70-    turn_timeout_s: 1200
relay-automation/MARATHON.example.yaml:71:    depends_on: p1
relay-automation/MARATHON.example.yaml-72-    max_review_rounds: 3
--
test/xyz-vendor.sh-46-  && pass "utils/ vendored ($utils_van *.sh)" \
test/xyz-vendor.sh-47-  || fail "utils/ vendor incomplete: vendored $utils_van vs harness $utils_repo"
test/xyz-vendor.sh:48:[ -f "$REPO/.xyz/utils/swarm-preflight.sh" ] && bash -n "$REPO/.xyz/utils/swarm-preflight.sh" 2>/dev/null \
test/xyz-vendor.sh:49:  && pass "vendored swarm-preflight.sh parses" || fail "vendored swarm-preflight.sh missing or parse-fail"
test/xyz-vendor.sh:50:[ -f "$REPO/.xyz/utils/marathon-plan.sh" ] && bash -n "$REPO/.xyz/utils/marathon-plan.sh" 2>/dev/null \
test/xyz-vendor.sh:51:  && pass "vendored marathon-plan.sh parses" || fail "vendored marathon-plan.sh missing or parse-fail"
test/xyz-vendor.sh-52-[ -x "$REPO/.xyz/bin/tick" ] && pass "bin/tick vendored + executable" || fail "bin/tick missing or not executable"
test/xyz-vendor.sh-53-[ -x "$REPO/.xyz/bin/validate-relay-block" ] && pass "bin/validate-relay-block vendored + executable" || fail "bin/validate-relay-block missing or not executable"
--
skills/relay-xyz/find-harness.sh-1-#!/usr/bin/env bash
skills/relay-xyz/find-harness.sh-2-#
skills/relay-xyz/find-harness.sh:3:# find-harness.sh — device-agnostic locator for the xyz-3-agents-swarm relay harness.
skills/relay-xyz/find-harness.sh-4-#
skills/relay-xyz/find-harness.sh-5-# Prints the absolute path to the repo root that ships relay-automation/ (the relay
--
skills/relay-xyz/find-harness.sh-128-if [ -z "$HARNESS" ]; then
skills/relay-xyz/find-harness.sh-129-  echo "find-harness: relay-automation/ harness not found." >&2
skills/relay-xyz/find-harness.sh:130:  echo "  Set XYZ_HARNESS=/path/to/your/xyz-3-agents-swarm clone and retry." >&2
skills/relay-xyz/find-harness.sh-131-  exit 1
skills/relay-xyz/find-harness.sh-132-fi
--
skills/ponytail/SKILL.md-106-Operational and recovery controls live here too. If a service genuinely needs
skills/ponytail/SKILL.md-107-a restart path, reboot command, backup, restore, or rollback lever, Ponytail
skills/ponytail/SKILL.md:108:optimizes how that control is implemented and exposed; it does not wave the
skills/ponytail/SKILL.md-109-control away as non-essential unless the requirement itself is clearly
skills/ponytail/SKILL.md-110-speculative.
--
relay-automation/codex-turn.sh-65-
relay-automation/codex-turn.sh-66-# Default ROOT to the CWD's git toplevel (the repo the operator is actually driving) so a
relay-automation/codex-turn.sh:67:# NON-VENDORED run — this shim invoked from outside the target repo, e.g. straight from the swarm
relay-automation/codex-turn.sh-68-# checkout — roots worktree isolation + artifact copyback at the TARGET, not this shim's own repo
relay-automation/codex-turn.sh-69-# ($HERE/..). Explicit CODEX_TURN_ROOT still wins (fixtures); fall back to $HERE/.. off a git repo.
--
skills/consult/SKILL.md-45-`consult.sh` or `relay-automation/consult.sh` only resolves when you happen to be sitting at the root,
skills/consult/SKILL.md-46-so invoke it through its repo-root anchor instead. Two homes are supported so consult works both in
skills/consult/SKILL.md:47:the `xyz-3-agents-swarm` checkout **and** in any repo that has a vendored `.xyz/` install: the
skills/consult/SKILL.md-48-top-level `relay-automation/` if present, otherwise the vendored `.xyz/relay-automation/`.
skills/consult/SKILL.md-49-
--
skills/consult/SKILL.md-60-`git rev-parse --show-toplevel` works from any subdirectory of the repo. If you are not inside a repo
skills/consult/SKILL.md-61-that has consult (no top-level `relay-automation/` and no `.xyz/`), either `cd` into the
skills/consult/SKILL.md:62:`xyz-3-agents-swarm` worktree, or vendor a `.xyz/` into the target repo first
skills/consult/SKILL.md-63-(`relay-automation/xyz-vendor.sh <repo>`). (Do **not** go hunting the disk for `consult.sh`; the
skills/consult/SKILL.md-64-anchor above always finds it.)
--
skills/10days/SKILL.md-6-  verify each one is still valid, reproducible, and not already fixed (fan out
skills/10days/SKILL.md-7-  subagents to check issue state, comments, and git/commit history for completion
skills/10days/SKILL.md:8:  evidence), build a marathon plan from the survivors, run swarm-preflight on it, then
skills/10days/SKILL.md-9-  cut a branch and execute the marathon end-to-end with no pause. This skill is a
skills/10days/SKILL.md-10-  deliberate, operator-authorized exception to this repo's default "ask before cutting
--
skills/10days/SKILL.md-14-  they are still valid, reproducible, not completed already... add each one to a
skills/10days/SKILL.md-15-  marathon file, run preflight, cut a new branch and execute on the marathon."
skills/10days/SKILL.md:16:  Requires swarm-preflight.sh + marathon-plan.sh resolved from the harness root (bare repo
skills/10days/SKILL.md-17-  root or a vendored `.xyz/` install — see Procedure Step 0), plus the swept repo's
skills/10days/SKILL.md-18-  PROJECT/** + ROADMAP.md + gh (authenticated) + jq.
--
skills/10days/SKILL.md-34-transcript: `relay-system/2026-07-16/10days-review-222405/10days-review.agy.md`). That
skills/10days/SKILL.md-35-review found five real problems, all fixed below before this skill was ever run live:
skills/10days/SKILL.md:36:unsafe hand-rolled JSON in `find-doc.sh`, a `swarm-preflight.sh` multi-`--gh-issue`
skills/10days/SKILL.md-37-bundling behavior the original Step 6 got wrong, no check for a concurrently-running
skills/10days/SKILL.md:38:marathon before cutting a branch, no check for a behind-origin `main` (swarm-preflight
skills/10days/SKILL.md-39-itself only warns on this, never blocks), and no containment story for the parallel
skills/10days/SKILL.md-40-lane dispatch in Step 7. See each fix inline below.
--
skills/10days/SKILL.md-72-- **Auto-drafted preflight contracts are a best-effort guess, not a verified fact —
skills/10days/SKILL.md-73-  and the fix for a wrong guess has to land before firing, not in the after-the-fact
skills/10days/SKILL.md:74:  report.** A wrong `artifacts` list makes `marathon-plan.sh`'s wave/collision map
skills/10days/SKILL.md-75-  untrustworthy: two lanes it thinks are disjoint could actually touch the same file
skills/10days/SKILL.md-76-  and race. Step 6.5 adds a cheap deterministic overlap check specifically to catch
skills/10days/SKILL.md:77:  this before any wave runs concurrently, in addition to the Step 8 report flag.
skills/10days/SKILL.md-78-
skills/10days/SKILL.md-79-## Preconditions — install once
--
skills/10days/SKILL.md-91-### 0. Resolve the harness root, and confirm which repo is being swept
skills/10days/SKILL.md-92-
skills/10days/SKILL.md:93:`swarm-preflight.sh` and `marathon-plan.sh` may live at the repo root or, in a vendored install,
skills/10days/SKILL.md-94-under `.xyz/`. Resolve once, using the same precedence as other self-locating skills in this repo
skills/10days/SKILL.md-95-(env override → vendored `.xyz/` → current repo root):
--
skills/10days/SKILL.md-98-HARNESS="${XYZ_HARNESS:-${XYZ_REPO_ROOT:-}}"
skills/10days/SKILL.md-99-[ -n "$HARNESS" ] || HARNESS="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
skills/10days/SKILL.md:100:[ -x "$HARNESS/.xyz/utils/swarm-preflight.sh" ] && HARNESS="$HARNESS/.xyz"
skills/10days/SKILL.md-101-```
skills/10days/SKILL.md-102-
--
skills/10days/SKILL.md-155-- `bucket: "2-WORKING"` with `has_contract: true` → a real preflight verdict already
skills/10days/SKILL.md-156-  exists or can be re-run cheaply; still route it through Step 3 (docs go stale —
skills/10days/SKILL.md:157:  see the swarm-preflight fix-probe gotcha below), but it needs no new contract.
skills/10days/SKILL.md-158-- `bucket: null` or `has_contract: false` → no shortcut; needs the full Step 3 check and,
skills/10days/SKILL.md-159-  if it survives, a contract authored in Step 4.
skills/10days/SKILL.md-160-
skills/10days/SKILL.md:161:**Gotcha to carry into Step 3:** `swarm-preflight.sh` fix-probes detect the *bug*, not
skills/10days/SKILL.md-162-the *fix* (`grep_present` = bug still there, `grep_absent` = fix landed). Read a stale
skills/10days/SKILL.md-163-doc's own probe definitions before trusting its verdict — don't assume "has a contract"
--
skills/10days/SKILL.md-194-> already-fixed: since the default flipped, a plain repro runs the Python twin, so a Bash-path bug
skills/10days/SKILL.md-195-> won't surface and would be falsely `EXCLUDE`d as "already done." `runtime:python`/`runtime:parity`
skills/10days/SKILL.md:196:> reproduce under the default path. These labels exist only in `xyz-3-agents-swarm`, so this is a
skills/10days/SKILL.md-197-> silent no-op for any other repo the sweep runs against.
skills/10days/SKILL.md-198-
--
skills/10days/SKILL.md-208-> `malformed_source_row_is_dropped`, and every gate reported success. Summarise the *background*
skills/10days/SKILL.md-209-> as much as you like. **Reproduce the `## Acceptance` block byte-for-byte** (re-wrapping to ~80
skills/10days/SKILL.md:210:> columns is fine — nothing else is). `swarm-preflight` now re-fetches the issue and refuses to
skills/10days/SKILL.md-211-> emit a packet on unexplained divergence, so a restatement here does not merely risk a wrong
skills/10days/SKILL.md-212-> build, it hard-fails the lane at Step 6.
--
skills/10days/SKILL.md-255-  For a `runtime:bash`-labeled issue, set the gate to `"XYZ_PYTHON=0 bash validate.sh"` so the
skills/10days/SKILL.md-256-  lane verifies against the Bash path the bug actually lives on, not the Python default (again, a
skills/10days/SKILL.md:257:  no-op outside `xyz-3-agents-swarm`, where the label is absent).
skills/10days/SKILL.md-258-
skills/10days/SKILL.md-259-  Mark it explicitly in the doc body: *"Contract auto-drafted by /10days from the issue
--
skills/10days/SKILL.md-286-
skills/10days/SKILL.md-287-- Append one queued-intake pointer line for `GH-<N>` under ROADMAP.md's ledger (pointer
skills/10days/SKILL.md:288:  only — no execution detail) so `$HARNESS/utils/marathon-plan.sh` picks it up in Step 5.
skills/10days/SKILL.md-289-
skills/10days/SKILL.md-290-### 5. Build the marathon file
skills/10days/SKILL.md-291-
skills/10days/SKILL.md-292-```bash
skills/10days/SKILL.md:293:"$HARNESS/utils/marathon-plan.sh" --deep
skills/10days/SKILL.md-294-```
skills/10days/SKILL.md-295-
skills/10days/SKILL.md:296:`--deep` delegates to `$HARNESS/utils/swarm-preflight.sh --dry-run` per ready item for an
skills/10days/SKILL.md-297-authoritative freshness verdict while ranking (slower, needs network — that's fine,
skills/10days/SKILL.md-298-`gh`/network access is already required by this point). Writes
--
skills/10days/SKILL.md-301-out of the fire list in Step 6, with the reason already stated by the planner.
skills/10days/SKILL.md-302-
skills/10days/SKILL.md:303:**`marathon-plan.sh` ranks the ENTIRE ROADMAP ledger, not just this sweep's issues —
skills/10days/SKILL.md:304:filter its waves down to this run's candidate set before treating anything as
skills/10days/SKILL.md:305:fireable.** The generated waves will very likely include other ready ROADMAP items this
skills/10days/SKILL.md-306-sweep never touched (a prior operator triage, a different marathon's queued work, an
skills/10days/SKILL.md-307-old item that just became unblocked). Confirmed live on the first real run of this
skills/10days/SKILL.md:308:skill: the generated plan's Wave 1 included issues already claimed by a separate,
skills/10days/SKILL.md:309:concurrently-running marathon. Before Step 6: intersect the plan's wave assignments
skills/10days/SKILL.md-310-with this run's own INCLUDE list from Step 3, drop everything else from consideration
skills/10days/SKILL.md:311:(their wave slot, zone, and score are irrelevant to this run), and keep each surviving
skills/10days/SKILL.md:312:issue's *relative* wave ordering the planner assigned (it already serialized same-zone
skills/10days/SKILL.md:313:kernel items across separate waves correctly) — just don't fire the issues that aren't
skills/10days/SKILL.md-314-yours.
skills/10days/SKILL.md-315-
--
skills/10days/SKILL.md-318-```bash
skills/10days/SKILL.md-319-for N in <surviving issue numbers>; do
skills/10days/SKILL.md:320:  "$HARNESS/utils/swarm-preflight.sh" --gh-issue "$N"
skills/10days/SKILL.md-321-done
skills/10days/SKILL.md-322-```
--
skills/10days/SKILL.md-344-the packet says which of the two it was.
skills/10days/SKILL.md-345-
skills/10days/SKILL.md:346:### 6.5. Cross-issue artifact-overlap check — before any wave runs concurrently
skills/10days/SKILL.md-347-
skills/10days/SKILL.md:348:`marathon-plan.sh` already groups exit-0 issues into waves by disjoint `artifacts`
skills/10days/SKILL.md-349-sets. That grouping is only as trustworthy as the contracts feeding it, and Step 4 can
skills/10days/SKILL.md:350:include auto-drafted ones. Before accepting a wave's concurrency as safe:
skills/10days/SKILL.md-351-
skills/10days/SKILL.md:352:- Diff every pair of lanes slotted into the same wave: do their `artifacts` lists
skills/10days/SKILL.md-353-  literally intersect (a bug in the planner or the contract) or does either lane's
skills/10days/SKILL.md-354-  underlying issue body/title mention a file path that appears in the other lane's
skills/10days/SKILL.md-355-  `artifacts`? Either signal is enough.
skills/10days/SKILL.md:356:- Any lane pair with a hit — **serialize them**: move one to the next wave regardless
skills/10days/SKILL.md-357-  of what the planner computed. This costs wall-clock time, not correctness; the
skills/10days/SKILL.md:358:  planner's wave grouping is an optimization, not a safety guarantee, once an
skills/10days/SKILL.md-359-  auto-drafted contract is in the mix.
skills/10days/SKILL.md:360:- Log every serialization decision so Step 8 can report it — a silently-reordered wave
skills/10days/SKILL.md-361-  is still a surprise the operator should see.
skills/10days/SKILL.md-362-
--
skills/10days/SKILL.md-370-ls .tick/locks/ 2>/dev/null                               # must be empty — a claim means something is live
skills/10days/SKILL.md-371-find PROJECT/2-WORKING -maxdepth 1 -iname 'MARATHON-*' -newer .git/HEAD 2>/dev/null   # unexpected fresh marathon dir → stop, don't assume it's yours
skills/10days/SKILL.md:372:git fetch origin main --quiet && git rev-list --count HEAD..origin/main   # must be 0 — swarm-preflight only WARNS on behind, never blocks; this skill has to check itself
skills/10days/SKILL.md-373-```
skills/10days/SKILL.md-374-
--
skills/10days/SKILL.md-384-   parallel Sonnet subagents for independent lanes — **not** headless
skills/10days/SKILL.md-385-   `marathon-drive.sh` (it can't run a `claude` builder headlessly, and the `codex`
skills/10days/SKILL.md:386:   builder is known to self-commit mid-turn). Walk the MARATHON-PLAN doc's waves in
skills/10days/SKILL.md-387-   order, respecting any Step 6.5 serialization:
skills/10days/SKILL.md:388:   - Within a wave, dispatch one Agent tool call **per lane, each with
skills/10days/SKILL.md-389-     `isolation: "worktree"`** — this is the containment substitute for
skills/10days/SKILL.md-390-     `marathon-drive.sh`'s worktree isolation, so concurrent lanes cannot write over
skills/10days/SKILL.md:391:     each other on a shared tree. Respect the wave's zone caps (kernel ≤ 1 per wave).
skills/10days/SKILL.md-392-   - Each lane agent writes only inside its contract's `artifacts` allowlist.
skills/10days/SKILL.md:393:   - After all of a wave's lane agents return, before merging any lane's worktree
skills/10days/SKILL.md-394-     commit(s), verify that lane's worktree base against the marathon branch's start
skills/10days/SKILL.md-395-     commit: `git merge-base --is-ancestor <marathon-branch-start-sha> <lane-worktree-HEAD>`.
--
skills/10days/SKILL.md-405-   - Once a lane's commit(s) are merged, remove its worktree: `git worktree remove
skills/10days/SKILL.md-406-     <path>` (fall back to `git worktree remove --force <path>` if it still reports
skills/10days/SKILL.md:407:     uncommitted/stray state). Do this for every lane in the wave, right alongside the
skills/10days/SKILL.md-408-     gate check below — left as-is, a run with several parallel lanes accumulates
skills/10days/SKILL.md-409-     orphaned worktree directories under the repo's git metadata across sessions. A
skills/10days/SKILL.md-410-     removal failure does not stop the run: record the lane, path, and error for the
skills/10days/SKILL.md-411-     Step 8 report and continue.
skills/10days/SKILL.md:412:   - After a wave's merges land, run its gate (the contract's `gate`, default
skills/10days/SKILL.md:413:     `bash validate.sh`) **before starting the next wave.** A red gate stops the run —
skills/10days/SKILL.md:414:     do not advance to the next wave, do not force-merge, report it in Step 8 and leave
skills/10days/SKILL.md-415-     the branch as-is for the operator to inspect.
skills/10days/SKILL.md:416:3. Commit per lane/wave with a message referencing the GH issue number(s) it closes.
skills/10days/SKILL.md-417-
skills/10days/SKILL.md-418-### 8. Report
--
skills/10days/SKILL.md-426-- Every **auto-drafted contract**, named individually, flagged for operator review.
skills/10days/SKILL.md-427-- Every **Step 6.5 serialization** — which lane pairs were pulled out of a concurrent
skills/10days/SKILL.md:428:  wave and why, so a wave that ran slower than expected isn't a mystery.
skills/10days/SKILL.md:429:- Every gate result per wave (green/red) and, if red, exactly where the run stopped.
skills/10days/SKILL.md-430-- Every **worktree-cleanup failure** — lane, worktree path, and the `git worktree
skills/10days/SKILL.md-431-  remove` error — if any lane's worktree failed to remove after its merge. Never
--
skills/radar/SKILL.md-93-starting prior, not a ranking. Run every signal, report each one's **yield** (how many clusters it
skills/radar/SKILL.md-94-produced), and rank targets by the evidence that actually materialized. Validated across two repos
skills/radar/SKILL.md:95:whose sharpest signals were exact inverses: in `xyz-3-agents-swarm` signal 1 was decisive and
skills/radar/SKILL.md-96-signal 2 flat; in `giant-brains-claude-skills` signal 1 yielded nothing and signal 2 carried the run.
skills/radar/SKILL.md-97-
--
skills/relay-xyz/SKILL.md-8-  end-to-end", "drive a relay to completion headless", "run the relay harness",
skills/relay-xyz/SKILL.md-9-  or set up the all-Claude hands-free poll loop — and the working tree is a
skills/relay-xyz/SKILL.md:10:  clone of the xyz-3-agents-swarm repo (it ships relay-automation/). /relay
skills/relay-xyz/SKILL.md-11-  scaffolds the thread and owns the turn protocol; relay-xyz is the repo-specific
skills/relay-xyz/SKILL.md-12-  layer that runs the real scripts. NOT for scaffolding a thread from scratch
--
skills/relay-xyz/SKILL.md-89-  [ -n "$L" ] && [ -x "$L" ] && break
skills/relay-xyz/SKILL.md-90-done
skills/relay-xyz/SKILL.md:91:[ -x "$L" ] || { echo "relay-xyz: locator not found — set XYZ_HARNESS to your xyz-3-agents-swarm clone"; exit 1; }
skills/relay-xyz/SKILL.md-92-
skills/relay-xyz/SKILL.md-93-eval "$("$L" --env)"   # exports HARNESS, TICK, TICK_REPO_ROOT, RELAY_HAS_{TICK,CODEX,AGY}
--
skills/relay-xyz/SKILL.md-144-(*"pre-fix 2-branch logic sails past the held lock"*) is what pins that it can't return.
skills/relay-xyz/SKILL.md-145-
skills/relay-xyz/SKILL.md:146:**To actually run two swarms concurrently, use separate full clones** — not linked worktrees, which
skills/relay-xyz/SKILL.md-147-share the lock by the table above, and not a shared harness, which serializes. Per-run hygiene that
skills/relay-xyz/SKILL.md-148-keeps the event stream readable even across clones: distinct `--phase-id` / `--relay-task`, plus
--
skills/relay-xyz/SKILL.md-323-
skills/relay-xyz/SKILL.md-324-- **Drive a full relay/build that lands in a DIFFERENT repo (`--target-root`):** the *normal* case —
skills/relay-xyz/SKILL.md:325:  the harness lives in `xyz-3-agents-swarm`, the code you want built or reviewed-and-committed lives in
skills/relay-xyz/SKILL.md-326-  your own repo. Pass `--target-root <repo>` to `relay-drive.sh` (or `marathon-drive.sh`): the relay
skills/relay-xyz/SKILL.md-327-  thread + `tick` token stay in the harness clone, while the worktree base, `ALLOW_PATHS` resolution,
--
skills/relay-xyz/SKILL.md-329-  (Preconditions) solves discovery of *the harness*; `--target-root` is the inverse — pointing the
skills/relay-xyz/SKILL.md-330-  harness **at** your repo. **A same-repo lane must OMIT `--target-root`** — passing it for the harness's
skills/relay-xyz/SKILL.md:331:  own repo trips a relay-file off-lane false-positive (exit 6; see [#51](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/51)).
skills/relay-xyz/SKILL.md-332-
skills/relay-xyz/SKILL.md-333-- **One-shot cross-repo review without a relay loop (`CONSULT_ROOT`):** to apply a lens to a file in a
--
utils/telemetry/append-xyz-completion.sh-15-#
utils/telemetry/append-xyz-completion.sh-16-# Usage: append-xyz-completion.sh <harness> <sessionId> <health> <title> <description>
utils/telemetry/append-xyz-completion.sh:17:#   harness      relay | marathon | swarm
utils/telemetry/append-xyz-completion.sh-18-#   sessionId    relay thread slug, or marathon plan/run id
utils/telemetry/append-xyz-completion.sh-19-#   health       green | orange | red
--
utils/telemetry/append-xyz-completion.sh-33-harness="$1"; session_id="$2"; health="$3"; title="$4"; description="$5"
utils/telemetry/append-xyz-completion.sh-34-
utils/telemetry/append-xyz-completion.sh:35:case "$harness" in relay|marathon|swarm) ;; *) die "harness must be relay|marathon|swarm, got: $harness" ;; esac
utils/telemetry/append-xyz-completion.sh-36-case "$health"  in green|orange|red)     ;; *) die "health must be green|orange|red, got: $health" ;; esac
utils/telemetry/append-xyz-completion.sh-37-
--
skills/relay-xyz/install.sh-49-  else
skills/relay-xyz/install.sh-50-    echo "relay-xyz: WARNING — find-harness.sh could not resolve the harness root." >&2
skills/relay-xyz/install.sh:51:    echo "  Set XYZ_HARNESS=/path/to/your/xyz-3-agents-swarm clone." >&2
skills/relay-xyz/install.sh-52-  fi
skills/relay-xyz/install.sh-53-fi
--
skills/marathon-triage/SKILL.md-4-  Triage PDDA intake and active work into a ranked, preflight-checked, collision-safe marathon
skills/marathon-triage/SKILL.md-5-  candidate list. Reconcile GH capture docs with live issue state, identify missing or stale
skills/marathon-triage/SKILL.md:6:  preflight contracts, run dry-run readiness checks, and group disjoint write-sets into safe waves.
skills/marathon-triage/SKILL.md:7:  Use when asked to triage the inbox, build or refresh a marathon queue, choose work to swarm next,
skills/marathon-triage/SKILL.md-8-  identify concurrent issues, or plan a marathon without executing it. Requires this repo's
skills/marathon-triage/SKILL.md:9:  PROJECT lifecycle, ROADMAP ledger, and swarm-preflight.sh / marathon-plan.sh resolved from the
skills/marathon-triage/SKILL.md-10-  harness root (bare repo root or a vendored `.xyz/` install — see Workflow Step 0).
skills/marathon-triage/SKILL.md-11----
--
skills/marathon-triage/SKILL.md-30-### 0. Resolve the harness root
skills/marathon-triage/SKILL.md-31-
skills/marathon-triage/SKILL.md:32:`swarm-preflight.sh` and `marathon-plan.sh` may live at the repo root or, in a vendored install,
skills/marathon-triage/SKILL.md-33-under `.xyz/`. Resolve once, using the same precedence as other self-locating skills in this repo
skills/marathon-triage/SKILL.md-34-(env override → vendored `.xyz/` → current repo root):
--
skills/marathon-triage/SKILL.md-37-HARNESS="${XYZ_HARNESS:-${XYZ_REPO_ROOT:-}}"
skills/marathon-triage/SKILL.md-38-[ -n "$HARNESS" ] || HARNESS="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
skills/marathon-triage/SKILL.md:39:[ -x "$HARNESS/.xyz/utils/swarm-preflight.sh" ] && HARNESS="$HARNESS/.xyz"
skills/marathon-triage/SKILL.md-40-```
skills/marathon-triage/SKILL.md-41-
skills/marathon-triage/SKILL.md:42:Reference every script below as `$HARNESS/utils/swarm-preflight.sh` and
skills/marathon-triage/SKILL.md:43:`$HARNESS/utils/marathon-plan.sh` — not bare `utils/...` paths, which resolve to nothing (or to an
skills/marathon-triage/SKILL.md-44-unrelated `utils/` directory) in a vendored `.xyz/` install.
skills/marathon-triage/SKILL.md-45-
--
skills/marathon-triage/SKILL.md-76-
skills/marathon-triage/SKILL.md-77-A contract exists only when valid JSON appears under a heading matching `Preflight Contract` and
skills/marathon-triage/SKILL.md:78:satisfies `$HARNESS/utils/swarm-preflight.sh`'s current schema (Step 0). Run the script rather than
skills/marathon-triage/SKILL.md-79-hand-validating it.
skills/marathon-triage/SKILL.md-80-
--
skills/marathon-triage/SKILL.md-84-
skills/marathon-triage/SKILL.md-85-```bash
skills/marathon-triage/SKILL.md:86:$HARNESS/utils/swarm-preflight.sh --project-doc PROJECT/1-INBOX/GH-<n>-<slug>.md --dry-run
skills/marathon-triage/SKILL.md:87:$HARNESS/utils/swarm-preflight.sh --gh-issue <n> --dry-run
skills/marathon-triage/SKILL.md-88-```
skills/marathon-triage/SKILL.md-89-
--
skills/marathon-triage/SKILL.md-94-missing, over-broad, or unrelated write-sets; a ready exit does not make a dishonest write-set safe.
skills/marathon-triage/SKILL.md-95-
skills/marathon-triage/SKILL.md:96:### 4. Rank and form waves
skills/marathon-triage/SKILL.md-97-
skills/marathon-triage/SKILL.md:98:Prefer an existing, current `MARATHON-PLAN-*.md` generated by `$HARNESS/utils/marathon-plan.sh`
skills/marathon-triage/SKILL.md-99-(Step 0). Running the planner writes a file, so request confirmation before generating or
skills/marathon-triage/SKILL.md-100-refreshing one.
--
skills/marathon-triage/SKILL.md-105-Place lanes together only when their declared and audited write-sets are disjoint and all zone caps
skills/marathon-triage/SKILL.md-106-hold. Shared ledgers such as `ROADMAP.md` and `CHANGELOG.md` collide. Kernel paths obey the repo's
skills/marathon-triage/SKILL.md:107:one-kernel-lane-per-wave cap.
skills/marathon-triage/SKILL.md-108-
skills/marathon-triage/SKILL.md-109-### 5. Report
--
skills/marathon-triage/SKILL.md-113-1. Classification table with issue, doc, live state, contract state, and reason.
skills/marathon-triage/SKILL.md-114-2. Ranked candidates with ratings and exact preflight verdict.
skills/marathon-triage/SKILL.md:115:3. Collision map and recommended waves.
skills/marathon-triage/SKILL.md-116-4. Decisions needed — one **default recommendation per item**, not a flat symmetric list of
skills/marathon-triage/SKILL.md-117-   options the operator has to weigh unaided. For each item that needs a call, emit:
--
relay-automation/relay-turn-lib.sh-102-
relay-automation/relay-turn-lib.sh-103-# GH-30 Phase 1 — single transcript-root resolver (the ONLY place the relay-system base is decided).
relay-automation/relay-turn-lib.sh:104:# Every transcript writer (consult.sh, marathon-drive.sh, relay-drive.sh, swarm-preflight.sh,
relay-automation/relay-turn-lib.sh-105-# extract-relay-telemetry.sh) is meant to call this instead of hardcoding "$ROOT/relay-system"
relay-automation/relay-turn-lib.sh-106-# (writer wiring lands in Phase 2). It emits the relay-system BASE dir; callers append their own
--
relay-automation/relay-turn-lib.sh-300-  # (GH-296) and is safe doing so: GH-261 (312a2c3) canonicalizes BOTH RTL_ROOT and each absolute
relay-automation/relay-turn-lib.sh-301-  # allowlist entry to physical form before stripping, so by then either form resolves. The two
relay-automation/relay-turn-lib.sh:302:  # statements read as a contradiction for three weeks and cost Marathon Plan K's Wave 1 a wrong
relay-automation/relay-turn-lib.sh-303-  # root-cause; 312a2c3's own message names the test/marathon-drive.sh GH-171/GH-172 failures Plan K
relay-automation/relay-turn-lib.sh-304-  # measured two days earlier and could not explain. test/gh417-turn-root-symlink-prefix.sh pins all
--
skills/xyz/SKILL.md-9-  agents recon/profile the codebase concurrently", or "coordinate Codex +
skills/xyz/SKILL.md-10-  Gemini on the same repo". NOT for work that touches shared files, needs
skills/xyz/SKILL.md:11:  constant cross-agent handoff, or runs across separate clones / async sessions.
skills/xyz/SKILL.md-12----
skills/xyz/SKILL.md-13-
--
skills/xyz/SKILL.md-2195-  claim → **fail/retry the run, never silently treat it as a pass.**
skills/xyz/SKILL.md-2196-- **`take` atomicity is shared-lock/shared-tree specific** — do not generalize to
skills/xyz/SKILL.md:2197:  separate clones or non-shared transports.
skills/xyz/SKILL.md-2198-
skills/xyz/SKILL.md-2199-## 9. Limits (carried from Runs 1–3)
--
relay-automation/agy-turn.sh-83-
relay-automation/agy-turn.sh-84-# Default ROOT to the CWD's git toplevel (the repo the operator is actually driving) so a
relay-automation/agy-turn.sh:85:# NON-VENDORED run — this shim invoked from outside the target repo, e.g. straight from the swarm
relay-automation/agy-turn.sh-86-# checkout — roots worktree isolation + artifact copyback at the TARGET, not this shim's own repo
relay-automation/agy-turn.sh-87-# ($HERE/..). Explicit AGY_TURN_ROOT still wins (fixtures); fall back to $HERE/.. off a git repo.
--
test/gh460-pipe-buffer-sigpipe.sh-178-# a multiline pipeline or the shape inside a string literal. The named list above is the gate; this is
test/gh460-pipe-buffer-sigpipe.sh-179-# the early-warning.
test/gh460-pipe-buffer-sigpipe.sh:180:REPO_WIDE='pdda\.sh|pdda-local-checks|gate_inventory|swarm_preflight|git grep|git ls-files'
test/gh460-pipe-buffer-sigpipe.sh-181-derived_bad=""
test/gh460-pipe-buffer-sigpipe.sh-182-while IFS= read -r cand; do
--
utils/telemetry/preflight-docs.sh-34-#     <key>ProgramArguments</key><array>
utils/telemetry/preflight-docs.sh-35-#       <string>/bin/bash</string>
utils/telemetry/preflight-docs.sh:36:#       <string>/ABSOLUTE/PATH/TO/xyz-3-agents-swarm/utils/telemetry/preflight-docs.sh</string>
utils/telemetry/preflight-docs.sh-37-#     </array>
utils/telemetry/preflight-docs.sh-38-#     <key>EnvironmentVariables</key><dict><key>PDDA_LLM_BIN</key><string>claude</string></dict>
--
test/gh438-removal-is-progress.sh-85-# --- (2) NEGATIVE CONTROL: touching nothing is still not progress ---------------------------------
test/gh438-removal-is-progress.sh-86-# Without this, "always return True" passes case (1) and every stalled lane in the fleet would be
test/gh438-removal-is-progress.sh:87:# waved through as satisfied — a strictly worse bug than the one being fixed.
test/gh438-removal-is-progress.sh-88-mk_stub 'true'
test/gh438-removal-is-progress.sh-89-out="$(run_driver src/kept.js)"; rc=$?
--
skills/vendor-stack/SKILL.md-2-name: vendor-stack
skills/vendor-stack/SKILL.md-3-description: >-
skills/vendor-stack/SKILL.md:4:  Install the full swarm stack into a target repo: vendor the XYZ harness
skills/vendor-stack/SKILL.md-5-  (relay/marathon/consult/self-improve + `tick`) into `<target>/.xyz/`, then
skills/vendor-stack/SKILL.md-6-  optionally install the PDDA doc-governance runtime (`PROJECT/PDDA.md` +
--
skills/vendor-stack/SKILL.md-9-  `pdda-sync push` can carry updates forward. Trigger on "/vendor-stack",
skills/vendor-stack/SKILL.md-10-  "vendor XYZ (and PDDA) into <repo>", "install the stack / harness + governance
skills/vendor-stack/SKILL.md:11:  into <repo>", "set up XYZ and PDDA in this repo", "onboard <repo> to the swarm
skills/vendor-stack/SKILL.md-12-  stack". For XYZ only, `relay-automation/xyz-vendor.sh <repo>` is enough — reach
skills/vendor-stack/SKILL.md-13-  for this skill when you want the harness AND governance, or want to be asked.
--
skills/vendor-stack/SKILL.md-41-## Preconditions
skills/vendor-stack/SKILL.md-42-
skills/vendor-stack/SKILL.md:43:- You are standing in (or can point at) an **xyz-3-agents-swarm** clone — this
skills/vendor-stack/SKILL.md-44-  skill ships inside it at `skills/vendor-stack/`, so it resolves the harness
skills/vendor-stack/SKILL.md-45-  root from its own location. `bin/tick` and `src/` must be present.
--
relay-automation/claude-turn.sh-81-
relay-automation/claude-turn.sh-82-# Default ROOT to the CWD's git toplevel (the repo the operator is actually driving) so a
relay-automation/claude-turn.sh:83:# NON-VENDORED run — this shim invoked from outside the target repo, e.g. straight from the swarm
relay-automation/claude-turn.sh-84-# checkout — roots worktree isolation + artifact copyback at the TARGET, not this shim's own repo
relay-automation/claude-turn.sh-85-# ($HERE/..). Explicit CLAUDE_TURN_ROOT still wins (fixtures); fall back to $HERE/.. off a git repo.
--
test/path-integrity.sh-78-# Intentional FIXTURE LITERALS — path-like tokens that are test DATA (a file a test creates in a
test/path-integrity.sh-79-# throwaway temp repo at runtime), NOT references to a real file in this tree. Check B must skip them,
test/path-integrity.sh:80:# otherwise it false-positives on a case-sensitive filesystem: e.g. test/swarm-preflight.sh T22a asserts
test/path-integrity.sh-81-# case-INSENSITIVE shim classification using `relay-automation/Codex-turn.sh` (a deliberate case-variant
test/path-integrity.sh-82-# of the real lowercase codex-turn.sh). That literal resolves on case-insensitive macOS but not on
--
test/path-integrity.sh-85-# exist in this tree — the real shim is lowercase — so this can never mask a real path break). See #80.
test/path-integrity.sh-86-# Space-delimited; a token matches only when flanked by spaces (exact-token match, no substring slip).
test/path-integrity.sh:87:# GH-85: test/marathon-plan.sh creates `$J/test/gh-951-genuine-test.sh` in a throwaway temp repo to
test/path-integrity.sh-88-# simulate the "tests-reference-slug" partial signal — a fixture literal, not a real reference.
test/path-integrity.sh-89-# GH-63: test/signal-triage.sh passes `test/foo.sh` / `test/some-test.sh` as synthetic `--test` inputs
test/path-integrity.sh-90-# to exercise the classifier (they name no real file) — same class, skip them.
test/path-integrity.sh:91:# GH-108/GH-126/GH-127: test/swarm-preflight.sh's T35/T36 fixtures create test/bare-redirect.sh,
test/path-integrity.sh-92-# test/no-touch.sh, and test/comment-only.sh in a throwaway temp repo to exercise the genuine-ref
test/path-integrity.sh-93-# and bare-`>` fs-touching detectors — fixture literals, not references to files in this tree.
--
utils/telemetry/write-xyz-heartbeat.sh-25-harness="$1"; session_id="$2"
utils/telemetry/write-xyz-heartbeat.sh-26-
utils/telemetry/write-xyz-heartbeat.sh:27:case "$harness" in relay|marathon|swarm) ;; *) die "harness must be relay|marathon|swarm, got: $harness" ;; esac
utils/telemetry/write-xyz-heartbeat.sh-28-[[ -n "$session_id" ]] || die "sessionId cannot be empty"
utils/telemetry/write-xyz-heartbeat.sh-29-
--
test/gh425-source-url-slug.sh-6-HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
test/gh425-source-url-slug.sh-7-ROOT="$(cd "$HERE/.." && pwd)"
test/gh425-source-url-slug.sh:8:PY="$ROOT/utils/py/swarm_preflight.py"
test/gh425-source-url-slug.sh-9-WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh425-source-url-slug.XXXXXX")"
test/gh425-source-url-slug.sh-10-trap 'rm -rf "$WORK"' EXIT
--
test/gh425-source-url-slug.sh-76-# Negative control: remove only the new slug branch in a disposable copy.  It must reproduce the
test/gh425-source-url-slug.sh-77-# pre-GH-425 false green; a control that stays red cannot demonstrate this check's discrimination.
test/gh425-source-url-slug.sh:78:PREFIX="$WORK/swarm_preflight.pre-gh425.py"
test/gh425-source-url-slug.sh-79-cp "$PY" "$PREFIX"
test/gh425-source-url-slug.sh-80-python3 - "$PREFIX" <<'PYEOF'
--
relay-automation/aider-turn.sh-92-
relay-automation/aider-turn.sh-93-# Default ROOT to the CWD's git toplevel (the repo the operator is actually driving) so a
relay-automation/aider-turn.sh:94:# NON-VENDORED run — this shim invoked from outside the target repo, e.g. straight from the swarm
relay-automation/aider-turn.sh-95-# checkout — roots worktree isolation + artifact copyback at the TARGET, not this shim's own repo
relay-automation/aider-turn.sh-96-# ($HERE/..). Explicit AIDER_TURN_ROOT still wins (fixtures); fall back to $HERE/.. off a git repo.
--
test/hq-marathon-scan.sh-2-# GH-158: hermetic regression lock for utils/hq/marathon-scan.sh.
test/hq-marathon-scan.sh-3-#
test/hq-marathon-scan.sh:4:# Builds fixture registries + fixture repos, stubs each target repo's own swarm-preflight.sh, and
test/hq-marathon-scan.sh-5-# asserts the scanner classifies all five lane verdicts plus Held-not-counted without writing inside
test/hq-marathon-scan.sh-6-# any target repo.
--
test/hq-marathon-scan.sh-27-  local repo="$WORK/repos/$name"
test/hq-marathon-scan.sh-28-  mkdir -p "$repo/.git" "$repo/PROJECT/2-WORKING" "$repo/PROJECT/1-INBOX" "$repo/PROJECT/3-COMPLETED" "$repo/utils"
test/hq-marathon-scan.sh:29:  cat >"$repo/utils/swarm-preflight.sh" <<'EOF'
test/hq-marathon-scan.sh-30-#!/usr/bin/env bash
test/hq-marathon-scan.sh-31-set -uo pipefail
--
test/hq-marathon-scan.sh-52-esac
test/hq-marathon-scan.sh-53-EOF
test/hq-marathon-scan.sh:54:  chmod +x "$repo/utils/swarm-preflight.sh"
test/hq-marathon-scan.sh-55-  cat >"$repo/ROADMAP.md" <<'EOF'
test/hq-marathon-scan.sh-56-# Roadmap
--
test/hq-marathon-scan.sh-89-# $title
test/hq-marathon-scan.sh-90-
test/hq-marathon-scan.sh:91:## Recommended waves
test/hq-marathon-scan.sh-92-
test/hq-marathon-scan.sh:93:**Wave 1:** $lanes
test/hq-marathon-scan.sh-94-EOF
test/hq-marathon-scan.sh-95-}
--
utils/git-bundle-snapshot.sh-3-# git-bundle-snapshot.sh — write a rotated full-repo git bundle snapshot, so a
utils/git-bundle-snapshot.sh-4-# repo-wipe recovery (GH-177 happened twice) is one command instead of an evening:

2026-08-17T19:26:21.515767Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 96 column 5
exec
/bin/zsh -lc "nl -ba skills/relay-xyz/SKILL.md | sed -n '110,165p'
nl -ba skills/marathon-triage/SKILL.md | sed -n '90,110p'
nl -ba utils/marathon-plan.sh | sed -n '1,120p'
nl -ba utils/py/marathon_plan.py | sed -n '1,180p' 2>/dev/null
nl -ba relay-automation/MARATHON.example.yaml | sed -n '1,55p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr
 succeeded in 0ms:
   110	**every repo pointed at the same harness clone shares that one lock**, so their automated relays
   111	*serialize*: a second one blocks (`exit 1`) until the first frees.
   112	
   113	### The driver-lock exclusion matrix (GH-354 Phase 3 — canonical)
   114	
   115	> This table is the **one canonical statement** of what the driver lock guarantees (PDDA Principle #4).
   116	> Anything else that describes the lock — driver headers, monitor docs — links here rather than
   117	> restating it. A second copy is how the wrong sentence in `marathon-drive.sh:194-196` survived.
   118	
   119	Both drivers resolve the lock through **one shared resolver** (GH-448) — `utils/py/rtl.py::driver_lock_path`
   120	and its Bash twin `relay-automation/driver-lock-lib.sh::driver_lock_path_for_repo` — which yields three
   121	shapes:
   122	
   123	| Repo shape | Lock path | Display label |
   124	|---|---|---|
   125	| normal clone (`.git` is a directory) | `<root>/.git/relay-driver.lock` | `.git/relay-driver.lock` |
   126	| **linked worktree** (`.git` is a file) | `<git-common-dir>/relay-driver.lock` — i.e. **the parent clone's** | `.git/relay-driver.lock` |
   127	| vendored `.xyz/` (no `.git`) | `<root>/.relay-driver.lock` | `.relay-driver.lock` |
   128	
   129	The middle row is the load-bearing one: **a linked worktree does not get its own lane.** It resolves
   130	to the same lock as the clone it was cut from — pinned by `test/gh448-driver-lock-resolver.sh`
   131	(*"worktree case resolves to the git COMMON dir, not `<worktree>/.git/…`"*, plus a bash/python
   132	*"parity"* assertion per shape). So all three driver pairs mutually exclude *per clone*:
   133	
   134	| Pair | Excludes? | Pinned by |
   135	|---|---|---|
   136	| marathon ↔ marathon | **yes** | `test/driver-lock.sh` — *"live lock (alive holder) → driver refuses (exit 1)"*, *"live lock left intact (not stolen)"* |
   137	| marathon ↔ relay | **yes** | `test/gh376-relay-drive-lock-parity.sh` — *"THE PIN (bash): relay-drive.sh refuses — the frozen twin agrees with the Python half"* |
   138	| relay ↔ relay | **yes** | `test/gh376-relay-drive-lock-parity.sh` — *"neither lane left a worktree-local lock behind at `$WT/.relay-driver.lock`"*, *"twin parity: both lanes emit a byte-identical REFUSAL"* |
   139	
   140	**This became true only in GH-376.** Before it, `relay-drive` used a two-branch guess with no case for
   141	a linked worktree, so it took a *per-worktree* `.relay-driver.lock` while `marathon-drive` took the
   142	shared one — the bottom two rows did **not** exclude, and #354's original premise that the lock was
   143	"the hard blocker (by design)" was false for them. The negative control
   144	(*"pre-fix 2-branch logic sails past the held lock"*) is what pins that it can't return.
   145	
   146	**To actually run two swarms concurrently, use separate full clones** — not linked worktrees, which
   147	share the lock by the table above, and not a shared harness, which serializes. Per-run hygiene that
   148	keeps the event stream readable even across clones: distinct `--phase-id` / `--relay-task`, plus
   149	`MARATHON_LANE_NS` for the lane namespace and an explicit `XYZ_SESSION_ID` (its fallback to `PHASE_ID`
   150	cannot tell one run from another).
   151	
   152	To run relays in **different repos at the same time on one machine**, give each repo its **own harness**
   153	so each gets its own lock, `.tick/`, and worktrees:
   154	
   155	| Install path | Ships | Relay capability | Lock |
   156	|---|---|---|---|
   157	| `install.sh` (tick-only) | `bin/tick` + `src/*.js` | ❌ falls back to the centralized harness | shared (serializes) |
   158	| **`xyz-vendor.sh <target-repo> [--no-register]`** | full harness (`relay-automation/` + tick + src) into a gitignored `.xyz/` | ✅ per-repo | **own** `.xyz/.relay-driver.lock` |
   159	
   160	Updating a vendored copy (`xyz-sync.sh update`, or re-running `xyz-vendor.sh` over an existing
   161	`.xyz/`) replaces the harness **code** and preserves the per-repo state above — `relay-system/`,
   162	`.tick/`, `.relay-driver.lock`, and the `XYZ.json*` telemetry ride across the rebuild (GH-312). This
   163	matters because `.xyz/` is gitignored: state lost there is unrecoverable, with no reflog or stash
   164	behind it. A new runtime artifact under `.xyz/` must be added to the preserve list in
   165	`xyz-vendor.sh`'s `materialize_vendor()`, or the next update will delete it.
    90	Record the exact exit and verdict: ready `0`, usage `2`, invalid contract `3`, already landed `4`,
    91	not ready `5`, blocked target `6`, or ambiguous `7`.
    92	
    93	Audit `artifacts`, `artifacts_new`, and `lanes` against the issue's actual scope. Flag placeholder,
    94	missing, over-broad, or unrelated write-sets; a ready exit does not make a dishonest write-set safe.
    95	
    96	### 4. Rank and form waves
    97	
    98	Prefer an existing, current `MARATHON-PLAN-*.md` generated by `$HARNESS/utils/marathon-plan.sh`
    99	(Step 0). Running the planner writes a file, so request confirmation before generating or
   100	refreshing one.
   101	
   102	Apply the PDDA selection rule: gate on `risk <= 2`, then rank by lowest `effort + complexity`, then
   103	fewest `phases`. Do not store a new composite score.
   104	
   105	Place lanes together only when their declared and audited write-sets are disjoint and all zone caps
   106	hold. Shared ledgers such as `ROADMAP.md` and `CHANGELOG.md` collide. Kernel paths obey the repo's
   107	one-kernel-lane-per-wave cap.
   108	
   109	### 5. Report
   110	
     1	#!/usr/bin/env bash
     2	# FROZEN (GH-308): Python is authoritative — do not make behavior changes here.
     3	# Historical Bash fallback only; update utils/py/marathon_plan.py instead. See issue #308.
     4	# (The native engine behind that entry point is utils/py/_marathon_plan.py.)
     5	#
     6	# Frozen later than the other 11 — the exception was retired by GH-362.
     7	#
     8	# This file was GH-308's ONE documented exception: its Bash body stayed authoritative and
     9	# dual-maintained because the Python "port" shelled out to a copied, drifted node engine. GH-340
    10	# removed that reason — the copy is deleted, utils/py/_marathon_plan.py is a native stdlib engine,
    11	# and the Python lane needs no Node. `test/marathon-plan.sh` Scenario T still compares the two lanes
    12	# byte-for-byte (GH-348), so accidental drift is caught; the FIRST deliberate Python-only change to
    13	# the planner will fail it, and that failure is the signal to retire the assertion on purpose rather
    14	# than to quietly widen it.
    15	
    16	# GH-112 opt-in Python mode: XYZ_PYTHON=1 reroutes this entry point to the Python port in
    17	# utils/py/ (same CLI contract + exit codes). Default (unset/0) runs the canonical Bash
    18	# implementation below — Bash stays the supported default until the port is promoted.
    19	if [[ "${XYZ_PYTHON-1}" == "1" ]]; then
    20	  # UPGRADE.md §4 Phase-2 hardening (GH-255): (2a) `-` not `:-` so an explicit empty XYZ_PYTHON reads
    21	  # as not-1 → Bash (load-bearing once the default flips to 1); (2b) require python3 >=3.8 and fall
    22	  # back to Bash if missing/too-old. This site KEEPS its GH-154 --zones-config translation inside the
    23	  # guarded branch — do NOT collapse it to the generic shim (that would drop the zones-config block).
    24	  if command -v python3 >/dev/null 2>&1 \
    25	     && python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null; then
    26	    _xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    27	    export XYZ_ROOT="$_xyz_root"
    28	    export PYTHONPATH="$_xyz_root/utils/py${PYTHONPATH:+:$PYTHONPATH}"
    29	    _py_args=()
    30	    while (($# > 0)); do
    31	      case "$1" in
    32	        --zones-config)
    33	          [[ $# -ge 2 ]] || { printf 'marathon-plan: missing argument for --zones-config\n' >&2; exit 2; }
    34	          export QUEUE_PLAN_ZONES_FILE="$2"
    35	          shift 2
    36	          ;;
    37	        *)
    38	          _py_args+=("$1")
    39	          shift
    40	          ;;
    41	      esac
    42	    done
    43	    exec python3 "$_xyz_root/utils/py/marathon_plan.py" "${_py_args[@]}"
    44	  else
    45	    echo "xyz: XYZ_PYTHON=1 but python3 missing or < 3.8 — falling back to Bash" >&2
    46	  fi
    47	fi
    48	
    49	# utils/marathon-plan.sh — deterministic "pre-pre-flight" queue planner.
    50	#
    51	# Reads the canonical ROADMAP.md ledger (a queue of work: GitHub issues + PROJECT/**.md docs),
    52	# validates each item is still real (not already fixed / silently half-done), factors in the PDDA
    53	# complexity/risk/effort ratings, and emits TWO artifacts:
    54	#
    55	#   1. a VALIDATION / DRIFT REPORT on stdout — deterministic signals, each a FLAG for a human,
    56	#      never an auto-fix (already-closed / already-landed / undocumented-partial / drift / unrated);
    57	#   2. a SEQUENCED marathon-plan doc  PROJECT/2-WORKING/MARATHON-PLAN-YYYY-MM-DD.md — ratings-ranked, collision-lane
    58	#      aware, reproducing the shape of the hand-authored QUEUE-2026-06-27.md.
    59	#
    60	# It is the stage BEFORE utils/swarm-preflight.sh (which is per-item readiness). Overlap is intended:
    61	# this planner REUSES swarm-preflight's contract shape + probe semantics, and can DELEGATE to it
    62	# per-item with --deep. The planner is a PRODUCER of a plan; it never executes a marathon
    63	# (GUIDING-PRINCIPLES.md §8 — the operator decides).
    64	#
    65	# Determinism: the score for every item is printed alongside its inputs so any ordering is
    66	# reproducible by hand. Same ledger + same ratings + same NOW/TODAY ⇒ byte-identical output
    67	# (which is what makes the manual --check drift comparison below meaningful).
    68	#
    69	# Usage:
    70	#   utils/marathon-plan.sh                         # report on stdout + write today's marathon-plan doc
    71	#   utils/marathon-plan.sh --dry-run               # report only; write nothing
    72	#   utils/marathon-plan.sh --check                 # exit non-zero if today's marathon-plan doc is out of sync
    73	#   utils/marathon-plan.sh --policy derisk-first   # high-risk work sorts earlier (default: quick-wins)
    74	#   utils/marathon-plan.sh --deep                  # also delegate to swarm-preflight --dry-run per item
    75	#   utils/marathon-plan.sh --format json           # findings as JSON lines (pdda finding shape)
    76	#   utils/marathon-plan.sh --zones-config FILE     # explicit zone-rules override
    77	#
    78	# Exit: 0 clean · 2 usage · 3 ROADMAP missing/unparseable ·
    79	#       4 emitted, drift present (already-landed/closed — reconcile the ledger) ·
    80	#       5 emitted, items held out of sequencing (unrated / note-only / not-ready) ·
    81	#       6 gh required but unavailable (--require-gh only).
    82	#
    83	# Test seam (all optional; unset in production):
    84	#   QUEUE_PLAN_ROOT / QUEUE_PLAN_ROADMAP / QUEUE_PLAN_QUEUE_DIR / QUEUE_PLAN_NOW / QUEUE_PLAN_TODAY
    85	#   QUEUE_PLAN_GH_STATE_FILE   JSON map {"24":"CLOSED",...} used instead of calling `gh` (hermetic)
    86	#   QUEUE_PLAN_BRANCHES_FILE   newline list of branch names used instead of calling `git branch`
    87	#   QUEUE_PLAN_GH              force gh mode: off|stub (off ⇒ gh-unverified; stub needs *_STATE_FILE)
    88	#   QUEUE_PLAN_ZONES_FILE      planner zone-rules override (2nd-precedence tier; see --zones-config)
    89	
    90	set -uo pipefail
    91	# strict-mode: -e exempt — analysis tool with expected-nonzero probes (git/gh/grep); errors handled explicitly. See GUIDING-PRINCIPLES.md#strict-mode-policy.
    92	
    93	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    94	# Vendored install: HERE is <target>/.xyz/utils → parent is .xyz → target root is grandparent.
    95	_here_parent="$(cd "$HERE/.." && pwd)"
    96	if [ "$(basename "$_here_parent")" = ".xyz" ]; then
    97	  ROOT="${QUEUE_PLAN_ROOT:-"$(cd "$_here_parent/.." && pwd)"}"
    98	  _SP_CMD=".xyz/utils/swarm-preflight.sh"
    99	  _MD_CMD=".xyz/relay-automation/marathon-drive.sh"
   100	  _MP_CMD=".xyz/utils/marathon-plan.sh"
   101	else
   102	  ROOT="${QUEUE_PLAN_ROOT:-"$_here_parent"}"
   103	  _SP_CMD="utils/swarm-preflight.sh"
   104	  _MD_CMD="relay-automation/marathon-drive.sh"
   105	  _MP_CMD="utils/marathon-plan.sh"
   106	fi
   107	ROADMAP="${QUEUE_PLAN_ROADMAP:-"$ROOT/ROADMAP.md"}"
   108	QUEUE_DIR="${QUEUE_PLAN_QUEUE_DIR:-"$ROOT/PROJECT/2-WORKING"}"
   109	NOW="${QUEUE_PLAN_NOW:-"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}"
   110	TODAY="${QUEUE_PLAN_TODAY:-"$(date -u +%Y-%m-%d)"}"
   111	
   112	die()  { printf 'marathon-plan: %s\n' "$*" >&2; exit 2; }
   113	emit() { printf '%s\n' "$*" >&2; }
   114	
   115	usage() {
   116	  cat <<'EOF'
   117	Usage: utils/marathon-plan.sh [--dry-run | --check] [--policy quick-wins|derisk-first]
   118	                           [--deep] [--require-gh] [--format text|json]
   119	                           [--zones-config <file>]
   120	
     1	#!/usr/bin/env python3
     2	"""marathon-plan (Python path) — native planner CLI wrapper.
     3	
     4	GH-340: this used to shell out to the copied `utils/py/_marathon_plan_node.js` and hard-require
     5	`node`. It now drives the native Python engine in `utils/py/_marathon_plan.py` directly, so a
     6	production Python marathon-plan run needs neither Node nor that JS file. The former `docOf` and
     7	PR-review-overlay parity shims are folded into the native engine (no ROADMAP input mutation, no
     8	post-render patching).
     9	
    10	`utils/marathon-plan.sh` (Bash) remains the authoritative, dual-maintained twin per GH-308; this
    11	change does not alter the `XYZ_PYTHON=0` fallback.
    12	
    13	CLI contract (unchanged): [--dry-run | --check] [--policy quick-wins|derisk-first] [--deep]
    14	[--require-gh] [--format text|json]. `--zones-config` is translated to QUEUE_PLAN_ZONES_FILE by
    15	the Bash entry point before this script runs.
    16	"""
    17	import os
    18	import sys
    19	import subprocess
    20	import tempfile
    21	import shutil
    22	import datetime
    23	
    24	# Import the native engine relative to this file (utils/py/), independent of CWD/PYTHONPATH.
    25	sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    26	import _marathon_plan as engine  # noqa: E402
    27	
    28	
    29	def die(msg):
    30	    sys.stderr.write(f"marathon-plan: {msg}\n")
    31	    sys.exit(2)
    32	
    33	
    34	def emit(msg):
    35	    sys.stderr.write(f"{msg}\n")
    36	
    37	
    38	def print_usage():
    39	    """Print the usage block to stdout and nothing else.
    40	
    41	    GH-349: this used to be inseparable from an unconditional `sys.exit(0)`, which made the `die()`
    42	    after the unknown-argument branch **unreachable** — so `marathon-plan.sh --bogus` exited 0 on the
    43	    default lane while the Bash twin exited 2. Splitting print from exit is the whole fix: Bash's
    44	    `usage()` (`utils/marathon-plan.sh:102`) also only prints, and its callers own the exit code.
    45	    """
    46	    print("""Usage: utils/py/marathon_plan.py [--dry-run | --check] [--policy quick-wins|derisk-first]
    47	                           [--deep] [--require-gh] [--format text|json]
    48	
    49	  (default)        Print the validation report and write PROJECT/2-WORKING/MARATHON-PLAN-<today>.md.
    50	  --dry-run        Print the report; write no marathon-plan doc.
    51	  --check          Re-render and compare against today's marathon-plan doc; non-zero on drift. Writes nothing.
    52	  --policy P       quick-wins (default; momentum, low-cost first) | derisk-first (high-risk first).
    53	  --deep           Additionally delegate to utils/swarm-preflight.sh --dry-run per ready item
    54	                   (authoritative ref-based freshness/probe verdict; slower, needs network).
    55	  --require-gh     Treat an unavailable/offline `gh` as a hard error (exit 6) instead of degrading.
    56	  --format F       text (default) | json (findings as one JSON object per line).
    57	
    58	Exit: 0 clean · 2 usage · 3 ROADMAP unparseable · 4 drift present · 5 items held · 6 gh required-but-absent.""")
    59	
    60	
    61	def main():
    62	    policy = "quick-wins"
    63	    out_format = "text"
    64	    run_mode = "write"
    65	    deep = False
    66	    require_gh = False
    67	
    68	    args = sys.argv[1:]
    69	    i = 0
    70	    while i < len(args):
    71	        arg = args[i]
    72	        if arg == "--dry-run":
    73	            run_mode = "dry-run"
    74	            i += 1
    75	        elif arg == "--check":
    76	            run_mode = "check"
    77	            i += 1
    78	        elif arg == "--policy":
    79	            if i + 1 < len(args):
    80	                policy = args[i + 1]
    81	                i += 2
    82	            else:
    83	                die("missing argument for --policy")
    84	        elif arg == "--deep":
    85	            deep = True
    86	            i += 1
    87	        elif arg == "--require-gh":
    88	            require_gh = True
    89	            i += 1
    90	        elif arg == "--format":
    91	            if i + 1 < len(args):
    92	                out_format = args[i + 1]
    93	                i += 2
    94	            else:
    95	                die("missing argument for --format")
    96	        elif arg in ("--help", "-h"):
    97	            print_usage()
    98	            sys.exit(0)
    99	        else:
   100	            # Mirrors `utils/marathon-plan.sh:139` exactly — `*) usage; die "unknown argument: $1"`:
   101	            # usage to stdout, the error to stderr, exit 2. An unknown flag on the default lane must
   102	            # never be reportable as success (GH-349).
   103	            print_usage()
   104	            die(f"unknown argument: {arg}")
   105	
   106	    if policy not in ("quick-wins", "derisk-first"):
   107	        die("--policy must be 'quick-wins' or 'derisk-first'")
   108	    if out_format not in ("text", "json"):
   109	        die("--format must be 'text' or 'json'")
   110	
   111	    here = os.path.dirname(os.path.abspath(__file__))
   112	    here_parent = os.path.dirname(here)
   113	    is_vendored = os.path.basename(os.path.dirname(here_parent)) == ".xyz"
   114	
   115	    if is_vendored:
   116	        root = os.environ.get("QUEUE_PLAN_ROOT", os.path.dirname(os.path.dirname(here_parent)))
   117	        sp_cmd = ".xyz/utils/swarm-preflight.sh"
   118	        md_cmd = ".xyz/relay-automation/marathon-drive.sh"
   119	        mp_cmd = ".xyz/utils/marathon-plan.sh"
   120	    else:
   121	        root = os.environ.get("QUEUE_PLAN_ROOT", os.path.dirname(here_parent))
   122	        sp_cmd = "utils/swarm-preflight.sh"
   123	        md_cmd = "relay-automation/marathon-drive.sh"
   124	        mp_cmd = "utils/marathon-plan.sh"
   125	
   126	    roadmap = os.environ.get("QUEUE_PLAN_ROADMAP", os.path.join(root, "ROADMAP.md"))
   127	    queue_dir = os.environ.get("QUEUE_PLAN_QUEUE_DIR", os.path.join(root, "PROJECT", "2-WORKING"))
   128	
   129	    now = os.environ.get("QUEUE_PLAN_NOW", datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))
   130	    today = os.environ.get("QUEUE_PLAN_TODAY", datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d"))
   131	
   132	    if not os.path.isfile(roadmap):
   133	        emit(f"ROADMAP not found: {roadmap}")
   134	        sys.exit(3)
   135	
   136	    tmp_dir = tempfile.mkdtemp(prefix="marathon-plan.")
   137	    render_out = os.path.join(tmp_dir, f"MARATHON-PLAN-{today}.md")
   138	    queue_doc = os.path.join(queue_dir, f"MARATHON-PLAN-{today}.md")
   139	
   140	    swarm_preflight = os.path.join(here_parent, "swarm-preflight.sh")
   141	    if not (deep and os.path.isfile(swarm_preflight) and os.access(swarm_preflight, os.X_OK)):
   142	        swarm_preflight = ""
   143	
   144	    # UTILS_DIR is the dir holding marathon-plan-zones.default.json — utils/ (parent of utils/py).
   145	    cfg = {
   146	        "root": root,
   147	        "roadmap": roadmap,
   148	        "queue_dir": queue_dir,
   149	        "today": today,
   150	        "now": now,
   151	        "policy": policy,
   152	        "format": out_format,
   153	        "deep": deep,
   154	        "require_gh": require_gh,
   155	        "swarm_preflight": swarm_preflight,
   156	        "sp_cmd": sp_cmd,
   157	        "md_cmd": md_cmd,
   158	        "mp_cmd": mp_cmd,
   159	        "utils_dir": here_parent,
   160	        "zones_config": os.environ.get("QUEUE_PLAN_ZONES_CONFIG", ""),
   161	        "gh_state_file": os.environ.get("QUEUE_PLAN_GH_STATE_FILE", ""),
   162	        "branches_file": os.environ.get("QUEUE_PLAN_BRANCHES_FILE", ""),
   163	        "branch_env": os.environ.get("QUEUE_PLAN_BRANCH", ""),
   164	        "gh_force": os.environ.get("QUEUE_PLAN_GH", ""),
   165	        "base_files_file": os.environ.get("QUEUE_PLAN_BASE_FILES_FILE", ""),
   166	        "zones_file_env": os.environ.get("QUEUE_PLAN_ZONES_FILE", ""),
   167	    }
   168	
   169	    try:
   170	        rc = engine.run(cfg, render_out)
   171	    except engine.ZoneConfigError as e:
   172	        sys.stderr.write(f"marathon-plan: {e}\n")
   173	        shutil.rmtree(tmp_dir, ignore_errors=True)
   174	        sys.exit(3)
   175	    except engine.EngineExit as e:
   176	        if e.message:
   177	            sys.stderr.write(f"{e.message}\n")
   178	        shutil.rmtree(tmp_dir, ignore_errors=True)
   179	        sys.exit(e.code)
   180	
     1	# MARATHON.example.yaml — a multi-phase plan for marathon.sh (Phase 4 / M5).
     2	# Run it with:  relay-automation/marathon.sh --plan relay-automation/MARATHON.example.yaml
     3	# Each phase runs through marathon-drive.sh in depends_on order; the chain HALTS on the first
     4	# phase that fails its review/gate (that phase's ESCALATION.md is left behind), and emits a
     5	# marathon.complete event only when every phase is approved.
     6	#
     7	# SEQUENCING (GH-241): phases run STRICTLY ONE AT A TIME — there is no concurrent execution, and
     8	# `depends_on` does not create the ordering, it only constrains it. A phase WITHOUT `depends_on`
     9	# is not "unordered" or "parallel-safe"; it simply runs in plan order whenever its turn comes.
    10	# Analysing your phases for a disjoint write-set is still worthwhile (it is how you know which
    11	# phases genuinely need `depends_on`), but a disjoint write-set does NOT buy you parallelism here.
    12	#
    13	# ALWAYS `--dry-run` a new plan before firing it. It parses the plan, validates every field, and
    14	# prints the real execution order ("N phase(s) would run in order") at zero cost — which is the
    15	# cheapest way to catch both a mis-shaped field and a wrong mental model of the ordering.
    16	#
    17	# Builder default (GH-212): marathon.sh/marathon-drive.sh default `--builder` to `codex` — build
    18	# turns bill via the Codex/ChatGPT subscription, not the Anthropic API (agy is the other cost-blind
    19	# option). `--builder claude` is available but spawns a headless Claude Code CLI subprocess — a
    20	# SEPARATE, PER-CALL API-BILLED turn-taker — as an explicit, cost-acknowledged opt-in only.
    21	# (GH-379: Claude builder runs with CLAUDE_MAX_BUDGET defaulting to $0.50 and CLAUDE_MAX_TURNS defaulting
    22	# to 12. Note that a prompt cache-creation floor cost is paid per turn; increase CLAUDE_MAX_BUDGET in env
    23	# if a phase requires extra headroom.)
    24	#
    25	# Plan location (GH-212): once this is a REAL plan for a tracked issue (not this shipped example),
    26	# the MARATHON.yaml + its phase briefs belong under PROJECT/2-WORKING/<capture-doc>/ in the target
    27	# repo — never a standalone top-level folder like marathon-plans/<slug>/. `marathon.sh --plan`
    28	# refuses a plan outside PROJECT/2-WORKING/ unless MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 is set.
    29	# (This example is exempt: it lives under the harness's own relay-automation/ home, not a target repo.)
    30	#
    31	# Pre-advance gate (GH-238): each phase defaults to `bash <repo-root>/validate.sh` before it is
    32	# marked approved. marathon-drive checks that command can start before turn 1. A consuming repo
    33	# without a root-level validate.sh must supply its own gate when launching, for example:
    34	#   relay-automation/marathon.sh --plan PROJECT/2-WORKING/<capture>/MARATHON.yaml \
    35	#     --pre-advance-cmd "npm test"
    36	# The override must remain a real safety gate; a missing default fails fast rather than being skipped.
    37	# (GH-378: to run against a target with pre-existing suite failures, pass `--pre-advance-baseline <rc>`
    38	# or export MARATHON_GATE_BASELINE=<rc>. This permits exit codes <= baseline, but does not distinguish
    39	# individual test identities — a new regression raising the exit code halts the run.)
    40	#
    41	# Per-phase fields:
    42	#   id                 phase id → marathon-system/<id>/RELAY.md + tick token MARATHON-<ID>-TURN   (required)
    43	#   reviewer           codex* or agy* — the model that reviews this phase                 (required)
    44	#   brief              path (repo-relative) to the phase's task markdown                  (required)
    45	#   artifact           comma-separated repo-relative file(s) the builder may create/edit  (optional)
    46	#   turn_timeout_s     per-turn wall-clock cap exported as RELAY_TURN_TIMEOUT_S            (optional)
    47	#   max_review_rounds  round-cap = 2*N+1 (default 2 → cap 5)                              (optional)
    48	#   depends_on         run this phase only after the named phase is approved              (optional,
    49	#                      SCALAR ONLY — one phase id, unquoted: `depends_on: p3`. NOT a list:
    50	#                      `depends_on: [p3]` parses as the literal string "[p3]" and aborts the
    51	#                      plan with "depends_on unknown phase '[p3]'". A phase can have at most
    52	#                      one dependency; chain them (p3 → p4 → p5) to express a longer order.)
    53	#   name               human label for logs                                              (optional)
    54	
    55	name: example-refactor

2026-08-17T19:26:28.650767Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 96 column 5
exec
/bin/zsh -lc "rg -n -C 2 'MARATHON_LANE_NS|separate full clones|linked worktree|driver.lock|phase.*order|depends_on|lane' relay-automation/marathon.sh relay-automation/marathon-drive.sh utils/py/marathon.py utils/py/marathon_drive.py utils/py/rtl.py utils/py/_marathon_plan.py | head -700" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr
 succeeded in 0ms:
rg: utils/py/marathon.py: No such file or directory (os error 2)
utils/py/rtl.py-14-#
utils/py/rtl.py-15-# Matched as line PREFIXES, not as a bare "error" substring anywhere in the output. `whoami` prints
utils/py/rtl.py:16:# ACCOUNT IDENTITY on success — a substring test would fail any lane whose handle, org, or banner
utils/py/rtl.py-17-# happens to contain "error", and a false failure stops the run outright, which is a worse outcome
utils/py/rtl.py-18-# than the bug being fixed. The TTY signature is matched separately: it is the exact shape the issue
--
utils/py/rtl.py-22-# the timeout branch was taught to reclassify a TTY-diagnosed timeout as unverifiable: the probe was
utils/py/rtl.py-23-# killed before it could FLUSH its diagnostic, so the capture was empty, the reclassification had
utils/py/rtl.py:24:# nothing to match on, and the lane was blocked anyway. That flush race was predicted by one reviewer
utils/py/rtl.py-25-# and dismissed by another (and by me) as bounded; it then fired in the next consult and cost the agy
utils/py/rtl.py-26-# seat. Observed, so no longer a judgement call.
--
utils/py/rtl.py-29-# the load that closed a 2x margin. The cost is bounded and lands only on a genuine interactive-login
utils/py/rtl.py-30-# hang, which now takes 20s to reject instead of 5 — a rare path, and rejecting it late is cheaper than
utils/py/rtl.py:31:# blocking a working lane. Same reasoning as GH-457's tiers: size a cap against what the thing actually
utils/py/rtl.py-32-# costs, not against a number that looks tidy.
utils/py/rtl.py-33-AGY_AUTH_TIMEOUT_DEFAULT_S = 20
--
utils/py/rtl.py-44-      ""              — nothing suspicious; treat the probe as passed.
utils/py/rtl.py-45-      "unverifiable"  — the probe COULD NOT RUN, so it established nothing either way. Report it
utils/py/rtl.py:46:                        loudly; do NOT fail the lane on it.
utils/py/rtl.py:47:      "failed"        — the probe ran and agy reported an error. Fail the lane.
utils/py/rtl.py-48-
utils/py/rtl.py-49-    THE THIRD STATE IS THE WHOLE POINT, and it was learned the expensive way. GH-375's suggested fix
utils/py/rtl.py-50-    was to treat the TTY error as a failed probe and stop the turn. That was implemented literally and
utils/py/rtl.py:51:    it broke the agy lane outright: test/relay-self-sufficiency.sh went 4/0 to 0/4 with `agy shim
utils/py/rtl.py-52-    exited 5`, on a machine where agy was signed in and working.
utils/py/rtl.py-53-
--
utils/py/rtl.py-61-    So a TTY error from `whoami` says nothing about whether auth works; it says this probe is the
utils/py/rtl.py-62-    wrong instrument in this environment. Treating it as failure converts an unmeasurable check into
utils/py/rtl.py:63:    a hard block on a lane that demonstrably works — strictly worse than the bug GH-375 reported,
utils/py/rtl.py:64:    which merely let a possibly-unauthed lane proceed. One of two working builders, stopped by its
utils/py/rtl.py-65-    own guard.
utils/py/rtl.py-66-
--
utils/py/rtl.py-90-        low = line.lower()
utils/py/rtl.py-91-        # TTY FIRST, and it must stay first: agy's TTY banner is itself prefixed `CLI error:`, so the
utils/py/rtl.py:92:        # error-prefix branch below would otherwise claim it and fail a lane that is perfectly fine.
utils/py/rtl.py-93-        if any(m in low for m in AGY_AUTH_TTY_MARKERS):
utils/py/rtl.py-94-            return ("unverifiable", f"agy could not run headless, so auth was not verified: {line}")
--
utils/py/rtl.py-114-
utils/py/rtl.py-115-    on a machine where, measured in the same minute, `agy whoami` printed the TTY error and `agy -p`
utils/py/rtl.py:116:    (what the turn actually uses) answered correctly. A false block, from the guard, on a working lane
utils/py/rtl.py-117-    — the same failure direction GH-375's own fix was written to avoid, one branch over.
utils/py/rtl.py-118-
--
utils/py/rtl.py-233-    # of every single turn in the fleet, which made it the most expensive instance of the defect — far
utils/py/rtl.py-234-    # more so than the `_run_tick_loud` site the issue actually names. tick prints the answer here
utils/py/rtl.py:235:    # ("lost: claim limit reached (holding T-cite, T-offlane)") and it was thrown away, so the failure
utils/py/rtl.py-236-    # below could only ever describe the SYMPTOM (nobody owns the token) and never the CAUSE.
utils/py/rtl.py-237-    #
--
utils/py/rtl.py-407-    """The ONE registry of storage this harness will not trust with evidence (GH-388).
utils/py/rtl.py-408-
utils/py/rtl.py:409:    Deliberately a file both lanes read at runtime, not a constant duplicated per language — see the
utils/py/rtl.py-410-    conf's own header. `relay-automation/durable-log-lib.sh` is the Bash reader of this same file.
utils/py/rtl.py-411-    """
--
utils/py/rtl.py-669-    return count, first
utils/py/rtl.py-670-
utils/py/rtl.py:671:def driver_lock_path(root):
utils/py/rtl.py:672:    # GH-448: the ONE shared resolver for the relay-driver lock path, matching the DRIVER's own
utils/py/rtl.py-673-    # write-side resolution (marathon_drive.py / marathon-drive.sh, relay_drive.py / relay-drive.sh) —
utils/py/rtl.py-674-    # every read-only consumer (marathon-ls.sh, marathon-live.sh, find-harness.sh) must resolve the
utils/py/rtl.py-675-    # SAME path or it probes a location the driver never writes and reports a live run as idle.
utils/py/rtl.py:676:    #   .git is a directory  -> <root>/.git/relay-driver.lock                (normal clone)
utils/py/rtl.py:677:    #   .git is a file       -> <git-common-dir>/relay-driver.lock           (linked worktree)
utils/py/rtl.py:678:    #   no .git (vendored)   -> <root>/.relay-driver.lock                    (vendored .xyz/ copy)
utils/py/rtl.py-679-    # Returns (lock_path, lock_label) — lock_label is always the SHORT display form used in messages.
utils/py/rtl.py-680-    git_path = os.path.join(root, ".git")
utils/py/rtl.py-681-    if os.path.isdir(git_path):
utils/py/rtl.py:682:        return os.path.join(root, ".git", "relay-driver.lock"), ".git/relay-driver.lock"
utils/py/rtl.py-683-    if os.path.isfile(git_path):
utils/py/rtl.py-684-        common = ""
--
utils/py/rtl.py-690-            common = ""
utils/py/rtl.py-691-        if common:
utils/py/rtl.py:692:            return os.path.join(common, "relay-driver.lock"), ".git/relay-driver.lock"
utils/py/rtl.py:693:    return os.path.join(root, ".relay-driver.lock"), ".relay-driver.lock"
--
utils/py/_marathon_plan.py-9-The two temporary Python parity shims that used to wrap the copied Node engine are folded
utils/py/_marathon_plan.py-10-in here natively: ``doc_of()`` implements the correct own-``GH-<n>``-doc precedence (was the
utils/py/_marathon_plan.py:11:``_normalize_roadmap`` input-mutation shim ``S``), and the "Review lanes" overlay is rendered
utils/py/_marathon_plan.py:12:in place from ``parse_lanes_table()`` (was the ``_inject_review_lanes`` post-render shim ``N``).
utils/py/_marathon_plan.py-13-
utils/py/_marathon_plan.py-14-Output is intentionally identical to the Bash engine on fixed fixtures. It is invoked by
--
utils/py/_marathon_plan.py-533-        return out
utils/py/_marathon_plan.py-534-
utils/py/_marathon_plan.py:535:    def _parse_lanes_table(self, raw):
utils/py/_marathon_plan.py-536-        lines = re.split(r"\r?\n", raw)
utils/py/_marathon_plan.py-537-        h = -1
--
utils/py/_marathon_plan.py-565-            return -1
utils/py/_marathon_plan.py-566-
utils/py/_marathon_plan.py:567:        lane_idx, pr_idx, rev_idx = col("Lane"), col("PR"), col("Reviewer")
utils/py/_marathon_plan.py-568-        rows = []
utils/py/_marathon_plan.py-569-        while i < len(lines) and re.match(r"^\s*\|", lines[i]):
--
utils/py/_marathon_plan.py-573-                return cs[idx] if 0 <= idx < len(cs) else ""
utils/py/_marathon_plan.py-574-            rows.append({
utils/py/_marathon_plan.py:575:                "lane": at(cells, lane_idx) if lane_idx >= 0 else (cells[0] if cells else ""),
utils/py/_marathon_plan.py-576-                "pr": at(cells, pr_idx) if pr_idx >= 0 else "",
utils/py/_marathon_plan.py-577-                "reviewer": at(cells, rev_idx) if rev_idx >= 0 else "",
--
utils/py/_marathon_plan.py-637-        if contract and isinstance(contract.get("artifacts"), list):
utils/py/_marathon_plan.py-638-            arts = contract["artifacts"]
utils/py/_marathon_plan.py:639:            orch_only = (contract.get("lanes") or {}).get("orchestrator_only") or []
utils/py/_marathon_plan.py-640-            for zone in self.ZONES["zones"]:
utils/py/_marathon_plan.py-641-                if not zone["escalateOrchestratorOnly"]:
--
utils/py/_marathon_plan.py-821-                        self._flag("warn", "already-landed", r,
utils/py/_marathon_plan.py-822-                                   "all fix_probes report 'landed' — the fix is already present",
utils/py/_marathon_plan.py:823:                                   "verify-and-close, not a build lane")
utils/py/_marathon_plan.py-824-
utils/py/_marathon_plan.py-825-            if r["state"] is None:
--
utils/py/_marathon_plan.py-905-                    self._flag("warn", "already-landed", r,
utils/py/_marathon_plan.py-906-                               "swarm-preflight --dry-run → stale (exit 4)",
utils/py/_marathon_plan.py:907:                               "verify-and-close, not a build lane")
utils/py/_marathon_plan.py-908-                elif code == 5:
utils/py/_marathon_plan.py-909-                    r["state"] = "not-ready"
--
utils/py/_marathon_plan.py-968-        def active_cmp(a, b):
utils/py/_marathon_plan.py-969-            # JS: `if (a.score !== b.score) return a.score - b.score;` — null coerces to 0 in the
utils/py/_marathon_plan.py:970:            # subtraction, so a ready-but-unrated lane (score None) sorts as 0. Mirror that exactly.
utils/py/_marathon_plan.py-971-            sa, sb = a["score"], b["score"]
utils/py/_marathon_plan.py-972-            if sa != sb:
--
utils/py/_marathon_plan.py-1049-                    if spine:
utils/py/_marathon_plan.py-1050-                        contract_seams.append({"wave": a["wave"], "a": a, "b": b, "spine": spine})
utils/py/_marathon_plan.py:1051:                        self._flag("warn", "coupled-lanes", a,
utils/py/_marathon_plan.py:1052:                                   "same-wave lane shares the `%s/` spine with %s — write-disjoint but likely a shared contract seam"
utils/py/_marathon_plan.py-1053-                                   % (spine, ("#" + str(b["gh"])) if b["gh"] else b["slug"]),
utils/py/_marathon_plan.py:1054:                                   "pin a CONTRACT.md for the %s/ interface and point both lane prompts at it before launching" % spine)
utils/py/_marathon_plan.py-1055-
utils/py/_marathon_plan.py-1056-        # ── exit code ───────────────────────────────────────────────────────────
--
utils/py/_marathon_plan.py-1132-        out.append("  ledger items : %d  (queue %d · in-progress %d)"
utils/py/_marathon_plan.py-1133-                   % (len(deduped), counts["queue"], counts["inprog"]))
utils/py/_marathon_plan.py:1134:        out.append("  active lanes : %d across %d wave(s)   held: %d%s"
utils/py/_marathon_plan.py-1135-                   % (len(active), len(waves), len(held),
utils/py/_marathon_plan.py-1136-                      ("   gh-unverified: %d" % self.gh_unverified) if self.gh_unverified else ""))
--
utils/py/_marathon_plan.py-1185-        o.append("  A sequenced concurrency plan derived from ROADMAP.md: ranks surviving work by PDDA")
utils/py/_marathon_plan.py-1186-        o.append("  complexity/risk/effort, validates each item is still real, and batches collision-safe")
utils/py/_marathon_plan.py:1187:        o.append("  lanes into waves. Generated — edit the ledger, not this file.")
utils/py/_marathon_plan.py-1188-        o.append("---")
utils/py/_marathon_plan.py-1189-        o.append("")
--
utils/py/_marathon_plan.py-1202-        o.append("|---|---|")
utils/py/_marathon_plan.py-1203-        first_wave = " ‖ ".join(("#" + str(r["gh"])) if r["gh"] else r["slug"] for r in waves[0]) if waves else "(none)"
utils/py/_marathon_plan.py:1204:        o.append("| Generated by `utils/marathon-plan.sh` on %s from the live ROADMAP ledger (%d items; %d active across %d wave(s); %d held). Drift present: %s. | **Wave 1:** %s. Fire each lane via `swarm-preflight → marathon-drive`, scoped by `ALLOW_PATHS`. Re-run this script when the ledger changes. |"
utils/py/_marathon_plan.py-1205-                 % (self.TODAY, len(deduped), len(active), len(waves), len(held),
utils/py/_marathon_plan.py-1206-                    "yes — see Held/Flagged" if has_drift else "no", first_wave))
--
utils/py/_marathon_plan.py-1208-        o.append("## The one safety rule")
utils/py/_marathon_plan.py-1209-        o.append("")
utils/py/_marathon_plan.py:1210:        o.append("Two lanes are safe to run concurrently **iff their write-sets are disjoint** and their zone")
utils/py/_marathon_plan.py-1211-        o.append("caps are respected. Current caps: %s." % cap_summary)
utils/py/_marathon_plan.py-1212-        o.append("")
--
utils/py/_marathon_plan.py-1217-        for zone in zone_rows:
utils/py/_marathon_plan.py-1218-            items = [("#" + str(r["gh"])) if r["gh"] else r["slug"] for r in active if r["zone"] == zone["name"]]
utils/py/_marathon_plan.py:1219:            safe = "✅ one lane per file"
utils/py/_marathon_plan.py-1220-            if isinstance(zone["maxPerWave"], int):
utils/py/_marathon_plan.py-1221-                safe = "❌ serialize — one at a time" if zone["maxPerWave"] == 1 else "❌ cap %d per wave" % zone["maxPerWave"]
utils/py/_marathon_plan.py-1222-            elif zone["conservativeWhenInferred"]:
utils/py/_marathon_plan.py:1223:                safe = "✅ one lane per file (serialize when inferred)"
utils/py/_marathon_plan.py-1224-            o.append("| %s | %s | %s |" % (zone["name"], safe, ", ".join(items) if items else "—"))
utils/py/_marathon_plan.py-1225-        o.append("")
--
utils/py/_marathon_plan.py-1246-        o.append("")
utils/py/_marathon_plan.py-1247-        if not waves:
utils/py/_marathon_plan.py:1248:            o.append("_No active lanes — every item is held or flagged (see below)._")
utils/py/_marathon_plan.py-1249-        for i, w in enumerate(waves):
utils/py/_marathon_plan.py:1250:            lanes = " ‖ ".join(("#" + str(r["gh"])) if r["gh"] else r["slug"] for r in w)
utils/py/_marathon_plan.py:1251:            o.append("**Wave %d:** %s" % (i + 1, lanes if lanes else "(empty)"))
utils/py/_marathon_plan.py-1252-            o.append("")
utils/py/_marathon_plan.py-1253-            for r in w:
--
utils/py/_marathon_plan.py-1259-        o.append("")
utils/py/_marathon_plan.py-1260-        if not contract_seams:
utils/py/_marathon_plan.py:1261:            o.append("_None — no two same-wave lanes share a directory spine (deeper than a top-level dir)._")
utils/py/_marathon_plan.py-1262-            o.append("")
utils/py/_marathon_plan.py-1263-        else:
utils/py/_marathon_plan.py:1264:            o.append("These same-wave lanes are **write-disjoint but share a directory spine**, so they likely share")
utils/py/_marathon_plan.py-1265-            o.append("an interface (a not-yet-built module/schema). xyz is not for tightly-coupled work: pin a short")
utils/py/_marathon_plan.py:1266:            o.append("`CONTRACT.md` for the seam and point **each** lane's prompt at it (code TO the contract, not to")
utils/py/_marathon_plan.py:1267:            o.append("the other lane's source), or the split can stall when the consumer waits on the producer's handoff.")
utils/py/_marathon_plan.py-1268-            o.append("")
utils/py/_marathon_plan.py-1269-            for s in contract_seams:
--
utils/py/_marathon_plan.py-1275-        o.append("")
utils/py/_marathon_plan.py-1276-        buckets = [
utils/py/_marathon_plan.py:1277:            ("✅ Likely done — verify-and-close, not a build lane", ["already-landed", "already-closed"]),
utils/py/_marathon_plan.py-1278-            ("\U0001F527 Reconcile — undocumented partial completion", ["partial"]),
utils/py/_marathon_plan.py-1279-            ("⏸️ Gated on operator GO", ["gated"]),
--
utils/py/_marathon_plan.py-1295-            o.append("")
utils/py/_marathon_plan.py-1296-
utils/py/_marathon_plan.py:1297:        # GH-86: native "Review lanes" overlay (folds the former _inject_review_lanes shim).
utils/py/_marathon_plan.py-1298-        review_rel = "PR-REVIEW-QUEUE-%s.md" % self.TODAY
utils/py/_marathon_plan.py-1299-        review_raw = self._read_file_safe(os.path.join(self.QUEUE_DIR, review_rel))
utils/py/_marathon_plan.py-1300-        if review_raw is not None:
utils/py/_marathon_plan.py:1301:            review_lanes = self._parse_lanes_table(review_raw)
utils/py/_marathon_plan.py:1302:            o.append("## Review lanes (manual overlay — run via relay-xyz)")
utils/py/_marathon_plan.py-1303-            o.append("")
utils/py/_marathon_plan.py-1304-            o.append("A separate manual overlay — [%s](%s) — is not derived from" % (review_rel, review_rel))
utils/py/_marathon_plan.py:1305:            o.append("ROADMAP.md and does not appear in the waves above (a review lane evaluates an existing PR")
utils/py/_marathon_plan.py-1306-            o.append("diff; it doesn't remediate a ledger item). Fire each via `relay-xyz`, per the overlay doc.")
utils/py/_marathon_plan.py-1307-            o.append("")
utils/py/_marathon_plan.py:1308:            if review_lanes:
utils/py/_marathon_plan.py-1309-                o.append("| Lane | PR | Reviewer |")
utils/py/_marathon_plan.py-1310-                o.append("|---|---|---|")
utils/py/_marathon_plan.py:1311:                for l in review_lanes:
utils/py/_marathon_plan.py:1312:                    o.append("| %s | %s | %s |" % (_cell(l["lane"]), _cell(l["pr"]), _cell(l["reviewer"])))
utils/py/_marathon_plan.py-1313-            else:
utils/py/_marathon_plan.py-1314-                o.append("_%s exists but its `## Lanes` table could not be parsed._" % review_rel)
utils/py/_marathon_plan.py-1315-            o.append("")
utils/py/_marathon_plan.py-1316-
utils/py/_marathon_plan.py:1317:        o.append("## How to fire a lane")
utils/py/_marathon_plan.py-1318-        o.append("")
utils/py/_marathon_plan.py:1319:        o.append("Per lane, the existing pipeline applies — no new control plane:")
utils/py/_marathon_plan.py-1320-        o.append("")
utils/py/_marathon_plan.py-1321-        o.append("```")
utils/py/_marathon_plan.py-1322-        o.append("%s --project-doc <PROJECT/**/doc.md>   # or --gh-issue N" % self.SP_CMD)
utils/py/_marathon_plan.py:1323:        o.append("   → ready packet (candidate/freshness/fix-still-required + lane assignment)")
utils/py/_marathon_plan.py-1324-        o.append("%s ...   # build→gate→review, contained" % self.MD_CMD)
utils/py/_marathon_plan.py-1325-        o.append("```")
utils/py/_marathon_plan.py-1326-        o.append("")
utils/py/_marathon_plan.py:1327:        o.append("- **Lane scoping:** give each lane an `ALLOW_PATHS` matching only its zone above.")
utils/py/_marathon_plan.py:1328:        o.append("- If the lane's allowlist includes filesystem-touching `test/*.sh`, treat those tests as read-only specs in-turn; the outer harness gate verifies them after the turn, outside the isolated worktree.")
utils/py/_marathon_plan.py-1329-        o.append("")
utils/py/_marathon_plan.py-1330-        o.append("---")
--
relay-automation/marathon.sh-2-set -euo pipefail
relay-automation/marathon.sh-3-#
relay-automation/marathon.sh:4:# marathon.sh — Phase 4 (M5): multi-phase orchestrator. Reads MARATHON.yaml, resolves depends_on
relay-automation/marathon.sh-5-# order, and runs each phase through marathon-drive.sh (the unmodified single-phase loop). Advances
relay-automation/marathon.sh-6-# on phase approval; HALTS on the first phase failure (relay no-progress / cap / gate / containment),
--
relay-automation/marathon.sh-102-  --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh, per phase).
relay-automation/marathon.sh-103-  --dry-run               Render each phase's relay file and print the tick seed; exit without running.
relay-automation/marathon.sh:104:  --force                 GH-45: bypass the per-lane attempt cap for this run.
relay-automation/marathon.sh-105-  --retry PHASE-ID        GH-116: retry one phase with a fresh relay-task suffix. This REBUILDS the
relay-automation/marathon.sh-106-                          phase — a full builder + reviewer cycle — because a retry must never be
--
relay-automation/marathon.sh-108-                          GH-491: if the phase's relay is already terminal (STATUS: Approved) and its
relay-automation/marathon.sh-109-                          token is done, and only the GATE went red, do NOT use this. Re-fire the plan
relay-automation/marathon.sh:110:                          plainly instead: the driver detects the satisfied lane and re-runs only the
relay-automation/marathon.sh-111-                          pre-advance gate, dispatching no turns. Use --retry when the ARTIFACT is what
relay-automation/marathon.sh-112-                          needs to change.
--
relay-automation/marathon.sh-126-    --pre-advance-cmd) PRE_ADVANCE_CMD="${2:-}"; shift 2 ;;
relay-automation/marathon.sh-127-    --dry-run)         DRY_RUN=1; shift ;;
relay-automation/marathon.sh:128:    --force)           FORCE=1; shift ;;   # GH-45: forward to each phase so a parked lane can be re-fired
relay-automation/marathon.sh-129-    --retry)           RETRY_PHASE="${2:-}"; shift 2 ;;   # GH-116: retry one phase with a fresh relay-task suffix
relay-automation/marathon.sh-130-    --closeout-pr)     CLOSEOUT_PR=1; shift ;;
--
relay-automation/marathon.sh-251-PLAN_NAME="$(sed -n 's/^name:[[:space:]]*//p' "$PLAN" | head -n1 | sed 's/[[:space:]]*$//')"
relay-automation/marathon.sh-252-phase_count="$(printf '%s\n' "$PLAN_TSV" | grep -c .)"
relay-automation/marathon.sh:253:log "plan: $PLAN — $phase_count phase(s) in execution order"
relay-automation/marathon.sh-254-
relay-automation/marathon.sh-255-idx=0
relay-automation/marathon.sh-256-# Read TSV with a NON-whitespace field separator (US / \037): `IFS=$'\t' read` coalesces consecutive
relay-automation/marathon.sh-257-# tabs (tab is whitespace-class), which would collapse empty columns and shift every field. Translate
relay-automation/marathon.sh:258:# tabs → \037 so empty fields (no rounds / no depends_on / no artifact / no turn_timeout_s) are
relay-automation/marathon.sh-259-# preserved positionally.
relay-automation/marathon.sh:260:while IFS=$'\037' read -r id reviewer rounds depends_on brief artifact turn_timeout_s name; do
relay-automation/marathon.sh-261-  [[ -n "$id" ]] || continue
relay-automation/marathon.sh-262-  idx=$((idx + 1))
relay-automation/marathon.sh-263-  rounds="${rounds:-2}"
relay-automation/marathon.sh-264-  cap=$((2 * rounds + 1))
relay-automation/marathon.sh:265:  lane_ns=""
relay-automation/marathon.sh:266:  [[ -n "$PLAN_NAME" ]] && lane_ns="${PLAN_NAME}--${id}"
relay-automation/marathon.sh-267-  [[ -n "$brief" ]] || die "phase $id: no 'brief:' in the plan — a phase needs a task to run"
relay-automation/marathon.sh-268-  # Briefs live beside the plan, so they resolve against the repo the plan came from. On a
--
relay-automation/marathon.sh-281-  [[ -n "$TARGET_ROOT" ]] && drive_args+=( --target-root "$TARGET_ROOT" )
relay-automation/marathon.sh-282-  [[ -n "$PRE_ADVANCE_CMD" ]] && drive_args+=( --pre-advance-cmd "$PRE_ADVANCE_CMD" )
relay-automation/marathon.sh:283:  ((FORCE)) && drive_args+=( --force )   # GH-45: bypass the per-lane attempt cap for this run
relay-automation/marathon.sh-284-  # GH-116: only the phase named by --retry gets a task-name override — every other phase still lets
relay-automation/marathon.sh-285-  # marathon-drive.sh derive its default MARATHON-<ID>-TURN name, unaffected.
--
relay-automation/marathon.sh-303-  # one per phase.
relay-automation/marathon.sh-304-  if [[ -n "$turn_timeout_s" ]]; then
relay-automation/marathon.sh:305:    MARATHON_ROOT="$ROOT" MARATHON_LANE_NS="$lane_ns" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
relay-automation/marathon.sh-306-      RELAY_TURN_TIMEOUT_S="$turn_timeout_s" \
relay-automation/marathon.sh-307-      bash "$DRIVE_BIN" "${drive_args[@]}" || phase_exit=$?
relay-automation/marathon.sh-308-  else
relay-automation/marathon.sh:309:    MARATHON_ROOT="$ROOT" MARATHON_LANE_NS="$lane_ns" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
relay-automation/marathon.sh-310-      bash "$DRIVE_BIN" "${drive_args[@]}" || phase_exit=$?
relay-automation/marathon.sh-311-  fi
--
relay-automation/marathon.sh-326-
relay-automation/marathon.sh-327-if ((DRY_RUN)); then
relay-automation/marathon.sh:328:  log "dry-run complete: $phase_count phase(s) would run in order"
relay-automation/marathon.sh-329-  exit 0
relay-automation/marathon.sh-330-fi
--
relay-automation/marathon-drive.sh-49-#                                fails (exit 5) even if --pre-advance-cmd passed. Omit for phases with
relay-automation/marathon-drive.sh-50-#                                no test surface (docs-only, config-only) — default behavior unchanged.
relay-automation/marathon-drive.sh:51:#     [--log-github]             GH-284 opt-in run log: update the lane's existing GitHub issue with
relay-automation/marathon-drive.sh-52-#                                one marker comment. Default OFF; missing/unauthenticated gh is ignored.
relay-automation/marathon-drive.sh-53-#     [--dry-run]                render relay file and print tick seed cmd, then exit
--
relay-automation/marathon-drive.sh-62-#        5 pre-advance gate failed (also covers a failed --requires-test check — see ESCALATION.md
relay-automation/marathon-drive.sh-63-#        reason: pre-advance-failed vs. requires-test-missing) ·
relay-automation/marathon-drive.sh:64:#        6 containment violation (turn-taker reverted an off-lane edit) ·
relay-automation/marathon-drive.sh:65:#        7 turn timeout / hang · 8 lane parked (GH-45 attempt cap — no token seeded; re-fire with
relay-automation/marathon-drive.sh-66-#        --force) · 9 post-approve command failed (phase remains approved) · 2 usage.
relay-automation/marathon-drive.sh-67-
--
relay-automation/marathon-drive.sh-83-AGENT_CMD="${MARATHON_AGENT_CMD:-"$HERE/marathon-agent.sh"}"
relay-automation/marathon-drive.sh-84-
relay-automation/marathon-drive.sh:85:# GH-45 — QUEUE commitment contract: per-lane attempt cap (anti-rabbit-hole / WIP discipline).
relay-automation/marathon-drive.sh:86:# lane_attempt_gate appends one line per fire to .tick/attempts/<lane> and REFUSES to start a lane at
relay-automation/marathon-drive.sh-87-# >= LANE_MAX_ATTEMPTS (default 2, env-overridable) with exit 8 + a park message, seeding NO relay
relay-automation/marathon-drive.sh:88:# token. --force bypasses for one fire and logs it. lane_attempt_reset clears the counter when a lane
relay-automation/marathon-drive.sh-89-# COMPLETES successfully (Approved), so the cap counts CONSECUTIVE failures and can never permanently
relay-automation/marathon-drive.sh:90:# wedge a lane (reviewer feedback: without a reset a default-keyed lane parks forever). A nested call
relay-automation/marathon-drive.sh:91:# (marathon-drive → relay-drive) is guarded by LANE_ATTEMPT_COUNTED so the same lane is counted (and
relay-automation/marathon-drive.sh-92-# reset) exactly once. Byte-consistent mirror in relay-drive.sh; relay-turn-lib.sh/bin/tick untouched.
relay-automation/marathon-drive.sh:93:_lane_key() { printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'; }
relay-automation/marathon-drive.sh:94:lane_attempt_gate() {
relay-automation/marathon-drive.sh-95-  local root="$1" raw="$2" force="${3:-0}"
relay-automation/marathon-drive.sh-96-  [ -n "${LANE_ATTEMPT_COUNTED:-}" ] && return 0
relay-automation/marathon-drive.sh-97-  [ -n "$raw" ] || return 0
relay-automation/marathon-drive.sh-98-  local max="${LANE_MAX_ATTEMPTS:-2}"; case "$max" in ''|*[!0-9]*) max=2 ;; esac
relay-automation/marathon-drive.sh:99:  local key dir file count; key=$(_lane_key "$raw"); dir="$root/.tick/attempts"; file="$dir/$key"
relay-automation/marathon-drive.sh-100-  mkdir -p "$dir" 2>/dev/null || true
relay-automation/marathon-drive.sh-101-  count=0; [ -f "$file" ] && count=$(wc -l < "$file" 2>/dev/null | tr -d ' '); [ -n "$count" ] || count=0
relay-automation/marathon-drive.sh-102-  if [ "$force" = "1" ]; then
relay-automation/marathon-drive.sh:103:    printf 'lane-attempt-cap: --force override — lane %s at %s attempt(s) (cap %s), proceeding.\n' "$key" "$count" "$max" >&2
relay-automation/marathon-drive.sh-104-  elif [ "$count" -ge "$max" ]; then
relay-automation/marathon-drive.sh:105:    printf 'lane-attempt-cap: lane %s PARKED after %s attempt(s) (cap %s) — no relay token seeded.\n' "$key" "$count" "$max" >&2
relay-automation/marathon-drive.sh:106:    printf '  Re-anchor to the committed QUEUE lanes (AGENTS.md) or re-fire with --force. Attempts log: %s\n' "$file" >&2
relay-automation/marathon-drive.sh-107-    return 8
relay-automation/marathon-drive.sh-108-  fi
--
relay-automation/marathon-drive.sh-110-  return 0
relay-automation/marathon-drive.sh-111-}
relay-automation/marathon-drive.sh:112:lane_attempt_reset() {  # clear a lane's counter after it completes successfully (Approved)
relay-automation/marathon-drive.sh-113-  local root="$1" raw="$2"
relay-automation/marathon-drive.sh-114-  [ -n "${LANE_ATTEMPT_COUNTED:-}" ] && return 0
relay-automation/marathon-drive.sh-115-  [ -n "$raw" ] || return 0
relay-automation/marathon-drive.sh:116:  rm -f "$root/.tick/attempts/$(_lane_key "$raw")" 2>/dev/null || true
relay-automation/marathon-drive.sh-117-}
relay-automation/marathon-drive.sh-118-
relay-automation/marathon-drive.sh-119-# GH-162 — debug-mantra auto-trigger. NOT part of the GH-45 byte-identical mirror block above
relay-automation/marathon-drive.sh:120:# (test/lane-attempt-cap.sh diffs _lane_key..lane_attempt_reset between the two drivers verbatim) —
relay-automation/marathon-drive.sh-121-# kept below it deliberately so that contract stays untouched.
relay-automation/marathon-drive.sh-122-#
relay-automation/marathon-drive.sh:123:# debug_mantra_prior_attempts is a READ-ONLY peek at the SAME .tick/attempts/<lane> file GH-45 already
relay-automation/marathon-drive.sh:124:# maintains (via _lane_key, defined above) — it never writes. lane_attempt_gate is still the only
relay-automation/marathon-drive.sh-125-# writer/park authority; this only answers "did the last attempt at this phase fail to reach Approved"
relay-automation/marathon-drive.sh-126-# so the render step below (Step 1) can decide whether to inject the debug-mantra note, which must
relay-automation/marathon-drive.sh:127:# happen BEFORE lane_attempt_gate's own call (Step 3) appends this fire's own line.
relay-automation/marathon-drive.sh:128:debug_mantra_prior_attempts() {  # <root> <lane-key-raw>
relay-automation/marathon-drive.sh-129-  local root="$1" raw="$2" key file count
relay-automation/marathon-drive.sh:130:  key=$(_lane_key "$raw"); file="$root/.tick/attempts/$key"
relay-automation/marathon-drive.sh-131-  count=0; [ -f "$file" ] && count=$(wc -l < "$file" 2>/dev/null | tr -d ' '); [ -n "$count" ] || count=0
relay-automation/marathon-drive.sh-132-  printf '%s' "$count"
--
relay-automation/marathon-drive.sh-165-# running-total view, not stale/duplicate data. Opt out entirely with MARATHON_COST_SUMMARY=0.
relay-automation/marathon-drive.sh-166-# Default-on and strictly additive: only fires once MARATHON_DRIVE_STARTED is set (i.e. this phase
relay-automation/marathon-drive.sh:167:# got past --help/usage/lock-contention/lane-parked/--dry-run and is really being driven), and a
relay-automation/marathon-drive.sh-168-# failed/forced `tick analyze` is swallowed best-effort — it can never change the driven run's own
relay-automation/marathon-drive.sh-169-# exit code (wired via the EXIT trap below, same one the lock cleanup uses).
--
relay-automation/marathon-drive.sh-189-if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then
relay-automation/marathon-drive.sh-190-  # GH-49b: the lock lives in .git/ (never committed) for a normal clone; a vendored .xyz/ copy has no
relay-automation/marathon-drive.sh:191:  # .git/. In a linked worktree, .git is a file pointing at the shared gitdir, so resolve the real
relay-automation/marathon-drive.sh-192-  # common dir and place the lock there; otherwise --require-clean sees the driver's own bookkeeping as
relay-automation/marathon-drive.sh-193-  # untracked dirt inside the worktree. A vendored .xyz/ copy still falls back to a hidden lock beside
--
relay-automation/marathon-drive.sh-196-  # one clone.
relay-automation/marathon-drive.sh-197-  if [[ -d "$ROOT/.git" ]]; then
relay-automation/marathon-drive.sh:198:    _lock="$ROOT/.git/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
relay-automation/marathon-drive.sh-199-  elif [[ -f "$ROOT/.git" ]]; then
relay-automation/marathon-drive.sh-200-    _git_common_dir="$(git -C "$ROOT" rev-parse --git-common-dir 2>/dev/null || true)"
relay-automation/marathon-drive.sh-201-    if [[ -n "$_git_common_dir" ]]; then
relay-automation/marathon-drive.sh:202:      _lock="$_git_common_dir/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
relay-automation/marathon-drive.sh-203-    else
relay-automation/marathon-drive.sh:204:      _lock="$ROOT/.relay-driver.lock";           _lock_label=".relay-driver.lock"
relay-automation/marathon-drive.sh-205-    fi
relay-automation/marathon-drive.sh-206-  else
relay-automation/marathon-drive.sh:207:    _lock="$ROOT/.relay-driver.lock";     _lock_label=".relay-driver.lock"
relay-automation/marathon-drive.sh-208-  fi
relay-automation/marathon-drive.sh-209-  if ! mkdir "$_lock" 2>/dev/null; then
--
relay-automation/marathon-drive.sh-216-      exit 1
relay-automation/marathon-drive.sh-217-    fi
relay-automation/marathon-drive.sh:218:    printf 'marathon-drive: reclaiming stale relay-driver.lock (holder pid %s not running).\n' "${_holder:-none}" >&2
relay-automation/marathon-drive.sh-219-    # Sentinel Tier 1 (GH-281): the append helper isn't defined this early — inline a gated write.
relay-automation/marathon-drive.sh-220-    if [[ "${XYZ_DEBUG_LOG:-0}" == "1" ]]; then
relay-automation/marathon-drive.sh:221:      { printf '{"timestamp":"%s","severity":"info","check":"marathon.stale-lock","scope":"harness","repo":"%s","message":"stale driver lock reclaimed","action":"none (auto-healed)"}\n' \
relay-automation/marathon-drive.sh-222-          "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$ROOT" >> "${DEBUG_LOG_FILE:-$ROOT/debug.log}"; } 2>/dev/null || true
relay-automation/marathon-drive.sh-223-    fi
relay-automation/marathon-drive.sh-224-    rm -rf "$_lock"
relay-automation/marathon-drive.sh:225:    mkdir "$_lock" 2>/dev/null || { printf 'marathon-drive: could not acquire relay-driver.lock after reclaiming a stale one.\n' >&2; exit 1; }
relay-automation/marathon-drive.sh-226-    # ponytail: tiny TOCTOU window (two drivers could both reclaim a stale lock); acceptable for a
relay-automation/marathon-drive.sh-227-    # single-operator clone — add an atomic PID-CAS only if true multi-operator concurrency appears.
--
relay-automation/marathon-drive.sh-301-}
relay-automation/marathon-drive.sh-302-
relay-automation/marathon-drive.sh:303:# GH-284 run log. This is deliberately restricted to comments on an already-existing lane issue:
relay-automation/marathon-drive.sh-304-# no `gh issue create`, no close/reopen command, and no mutation at all unless --log-github was set.
relay-automation/marathon-drive.sh-305-# Every failing gh probe is swallowed so external reporting can never alter the marathon result.
relay-automation/marathon-drive.sh:306:marathon_lane_issue_number() {
relay-automation/marathon-drive.sh-307-  local candidate
relay-automation/marathon-drive.sh-308-  for candidate in "$LANE_STATE_KEY" "$RELAY_TASK" "$(basename "$PHASE_BRIEF_FILE")"; do
--
relay-automation/marathon-drive.sh-333-    return 0
relay-automation/marathon-drive.sh-334-  fi
relay-automation/marathon-drive.sh:335:  issue="$(marathon_lane_issue_number || true)"
relay-automation/marathon-drive.sh-336-  if [[ -z "$issue" ]]; then
relay-automation/marathon-drive.sh:337:    log "--log-github requested, but no GH issue number is derivable for lane $LANE_STATE_KEY — local telemetry only"
relay-automation/marathon-drive.sh-338-    return 0
relay-automation/marathon-drive.sh-339-  fi
relay-automation/marathon-drive.sh-340-  # GH-284 P2 (codex QA Blocker 1): every gh call MUST be scoped to $ROOT's repository. A bare
relay-automation/marathon-drive.sh-341-  # `gh repo view` / `gh pr view` resolves whatever repo the ambient CWD happens to be in, so a
relay-automation/marathon-drive.sh:342:  # --target-root run, or any invocation from a foreign directory, could post this lane's run log
relay-automation/marathon-drive.sh-343-  # into the WRONG repository's issue #N. Derive the slug from $ROOT's own remote (no gh call, no
relay-automation/marathon-drive.sh-344-  # CWD dependency); fall back to a gh lookup explicitly executed inside $ROOT, never the ambient CWD.
--
relay-automation/marathon-drive.sh-501-# re-rendering + re-seeding here would only clobber the accurate terminal RELAY.md before
relay-automation/marathon-drive.sh-502-# failing anyway. Checked before Step 1's render (below); extends GH-207's already-satisfied
relay-automation/marathon-drive.sh:503:# detection (recover_already_satisfied_lane, triggered mid-relay on a no-progress reroute)
relay-automation/marathon-drive.sh-504-# to this separate post-terminal-gate-retry trigger.
relay-automation/marathon-drive.sh:505:satisfied_lane_terminal() {
relay-automation/marathon-drive.sh-506-  local s tstatus actor
relay-automation/marathon-drive.sh-507-  [[ -f "$RELAY_FILE" ]] || return 1
--
relay-automation/marathon-drive.sh-522-    # via this subshell and break tests that legitimately assert on them
relay-automation/marathon-drive.sh-523-    # (test/xyz-harness-hooks.sh reads XYZ_HARNESS_CONTEXT / XYZ_SESSION_ID; test/debug-mantra.sh
relay-automation/marathon-drive.sh:524:    # reads MARATHON_LANE_NS), which made `bash validate.sh` — the DOCUMENTED DEFAULT GATE —
relay-automation/marathon-drive.sh-525-    # impossible to pass inside a marathon. Keep this list identical to GATE_SCRUBBED_ENV in
relay-automation/marathon-drive.sh-526-    # utils/py/marathon_drive.py; the Python twin is what runs by default (XYZ_PYTHON-1).
relay-automation/marathon-drive.sh-527-    # Deliberately narrow: run-identity tags only, never repo/config inputs like MARATHON_ROOT,
relay-automation/marathon-drive.sh-528-    # TICK_BIN or TICK_REPO_ROOT, which a gate may legitimately need.
relay-automation/marathon-drive.sh:529:    unset XYZ_HARNESS_CONTEXT XYZ_SESSION_ID MARATHON_LANE_NS
relay-automation/marathon-drive.sh-530-    eval "$PRE_ADVANCE_CMD"
relay-automation/marathon-drive.sh-531-  ) || rc=$?
--
relay-automation/marathon-drive.sh-614-                          even when --pre-advance-cmd passed. Omit for phases with no test surface
relay-automation/marathon-drive.sh-615-                          (e.g. docs-only) — default gate behavior is unchanged without this flag.
relay-automation/marathon-drive.sh:616:  --force                 GH-45: bypass the per-lane attempt cap for this fire (re-fire a parked lane).
relay-automation/marathon-drive.sh:617:  --log-github            GH-284 opt-in run log (default OFF). Updates the lane's EXISTING GitHub
relay-automation/marathon-drive.sh-618-                          issue in place via a marker comment — never creates an issue, never closes
relay-automation/marathon-drive.sh-619-                          one. Records landed-on-trunk, driver liveness, branch, PR link (or an
--
relay-automation/marathon-drive.sh-637-REQUIRE_CLEAN=0      # --require-clean: hard-stop if the workspace has pre-existing changes
relay-automation/marathon-drive.sh-638-REQUIRES_TEST=""     # --requires-test PATH: GH-249 requires_test contract field (opt-in; empty = off)
relay-automation/marathon-drive.sh:639:FORCE=0              # --force: bypass the GH-45 per-lane attempt cap for this one fire
relay-automation/marathon-drive.sh-640-LOG_GITHUB=0         # GH-284: external run-log comment; opt-in only
relay-automation/marathon-drive.sh-641-RUN_GATE_RESULT="not-run"
--
relay-automation/marathon-drive.sh-750-# dispatches a builder or reviewer turn, so there is no wasted-turn cost to protect against and
relay-automation/marathon-drive.sh-751-# halting would be pure downside. It also breaks fixtures that drive unrelated paths in repos with
relay-automation/marathon-drive.sh:752:# no gate script (test/driver-lock.sh regressed exactly this way when the check halted every run).
relay-automation/marathon-drive.sh-753-# Still surface the problem, so --dry-run stays a useful plan sanity-check: the subshell contains
relay-automation/marathon-drive.sh-754-# pre_advance_not_runnable's die(), turning the halt into a warning on this path only.
--
relay-automation/marathon-drive.sh-762-# Default the tick token name off the phase id (p1 → MARATHON-P1-TURN), keeping the Phase-3 default.
relay-automation/marathon-drive.sh-763-RELAY_TASK="${RELAY_TASK:-"MARATHON-$(printf '%s' "$PHASE_ID" | tr '[:lower:]' '[:upper:]')-TURN"}"
relay-automation/marathon-drive.sh:764:LANE_STATE_KEY="${MARATHON_LANE_NS:-$PHASE_ID}"
relay-automation/marathon-drive.sh-765-
relay-automation/marathon-drive.sh-766-# GH-249: snapshot HEAD (in the repo the artifact actually lands in — TARGET_ROOT when set, else ROOT)
--
relay-automation/marathon-drive.sh-787-route_agent "$BUILDER"
relay-automation/marathon-drive.sh-788-route_agent "$REVIEWER"
relay-automation/marathon-drive.sh:789:# Reviewer must be a QA-capable model lane (codex/gemini/agy), never the Claude builder lane.
relay-automation/marathon-drive.sh-790-case "$REVIEWER" in codex*|gemini*|agy*) ;; *) die "reviewer '$REVIEWER' must start with codex/gemini/agy" ;; esac
relay-automation/marathon-drive.sh-791-
--
relay-automation/marathon-drive.sh-838-REL_RELAY="${RELAY_FILE#"$ROOT"/}"   # repo-root-relative path the agent edits / declares in claim --paths
relay-automation/marathon-drive.sh-839-
relay-automation/marathon-drive.sh:840:# Bound early (moved ahead of Step 3's own copy below) so the GH-274 satisfied-lane check
relay-automation/marathon-drive.sh-841-# just below — and the escalate/complete_phase_success defs it may call — read/write tick
relay-automation/marathon-drive.sh-842-# state against the right repo even when a caller invoked us without pre-exporting it.
--
relay-automation/marathon-drive.sh-844-
relay-automation/marathon-drive.sh-845-# escalate/save_transcript/complete_phase_success are defined here (ahead of Step 1) instead
relay-automation/marathon-drive.sh:846:# of beside their Step 6 call sites so the GH-274 satisfied-lane short-circuit below — which
relay-automation/marathon-drive.sh-847-# must run BEFORE Step 1's render — can call complete_phase_success directly rather than
relay-automation/marathon-drive.sh-848-# duplicating its gate/requires-test/telemetry logic.
--
relay-automation/marathon-drive.sh-915-  fi
relay-automation/marathon-drive.sh-916-  if [[ "$success_mode" == "already-satisfied" ]]; then
relay-automation/marathon-drive.sh:917:    success_text="phase ${PHASE_ID} complete — lane_already_satisfied, reviewer approved, gate passed"
relay-automation/marathon-drive.sh-918-  else
relay-automation/marathon-drive.sh-919-    success_text="phase ${PHASE_ID} complete — STATUS: Approved, gate passed"
relay-automation/marathon-drive.sh-920-  fi
relay-automation/marathon-drive.sh-921-  "$TICK_BIN" log marathon.phase.approved "$RELAY_TASK" --agent marathon > /dev/null || true
relay-automation/marathon-drive.sh:922:  lane_attempt_reset "${TICK_REPO_ROOT:-$ROOT}" "$LANE_STATE_KEY"
relay-automation/marathon-drive.sh-923-  save_transcript
relay-automation/marathon-drive.sh-924-  xyz_marathon_heartbeat_clear
--
relay-automation/marathon-drive.sh-937-}
relay-automation/marathon-drive.sh-938-
relay-automation/marathon-drive.sh:939:# ── Step 0.4 (GH-274): satisfied-lane short-circuit ────────────────────────
relay-automation/marathon-drive.sh-940-# A phase whose relay is already terminal AND whose tick token is already done needs no
relay-automation/marathon-drive.sh-941-# render/reseed/relay-drive at all — only the pre-advance gate (and requires-test, if set)
--
relay-automation/marathon-drive.sh-943-# point is to render + show the tick seed for inspection, and there is nothing to commit or
relay-automation/marathon-drive.sh-944-# seed on this path anyway.
relay-automation/marathon-drive.sh:945:if ((! DRY_RUN)) && satisfied_lane_terminal; then
relay-automation/marathon-drive.sh-946-  log "phase ${PHASE_ID} already reached a terminal relay (STATUS: $(file_status), token done) — skipping render/reseed, re-running only the pre-advance gate"
relay-automation/marathon-drive.sh-947-  MARATHON_DRIVE_STARTED=1
--
relay-automation/marathon-drive.sh-949-fi
relay-automation/marathon-drive.sh-950-
relay-automation/marathon-drive.sh:951:# GH-162: peek at prior attempts BEFORE rendering (read-only; lane_attempt_gate in Step 3 still owns
relay-automation/marathon-drive.sh-952-# the append/park write) so a re-fired phase's relay file can carry the debug-mantra note. Empty
relay-automation/marathon-drive.sh-953-# DEBUG_MANTRA_TEXT on a first fire (prior=0) — the render below is then byte-identical to before.
--
relay-automation/marathon-drive.sh-1055-   - suspected_cause: <one line>
relay-automation/marathon-drive.sh-1056-   - probe: <a single command that currently DEMONSTRATES the bug (exits nonzero or greps the bad evidence — it must detect the BUG, not the fix)>
relay-automation/marathon-drive.sh:1057:   Off-lane edits are reverted by the harness; a Side Finding block is the only channel that survives.
relay-automation/marathon-drive.sh-1058-
relay-automation/marathon-drive.sh-1059----
--
relay-automation/marathon-drive.sh-1089-
relay-automation/marathon-drive.sh-1090-export TICK_REPO_ROOT="$ROOT"
relay-automation/marathon-drive.sh:1091:# The outer marathon-drive invocation owns the lane attempt count. A leaked caller env var would skip
relay-automation/marathon-drive.sh-1092-# counting entirely, so clear it here before the outer gate; the nested relay-drive below still gets
relay-automation/marathon-drive.sh-1093-# an explicit one-shot LANE_ATTEMPT_COUNTED=1 in its child env to avoid double-counting.
--
relay-automation/marathon-drive.sh-1127-}
relay-automation/marathon-drive.sh-1128-
relay-automation/marathon-drive.sh:1129:# GH-45: per-lane attempt cap — refuse to start this phase once it has hit LANE_MAX_ATTEMPTS
relay-automation/marathon-drive.sh:1130:# (keyed on the marathon-scoped lane-state key when present, else bare PHASE_ID), seeding no token;
relay-automation/marathon-drive.sh-1131-# --force overrides. Counted here, so the nested relay-drive below (LANE_ATTEMPT_COUNTED=1) does not
relay-automation/marathon-drive.sh:1132:# double-count this same lane.
relay-automation/marathon-drive.sh:1133:_lag_rc=0; lane_attempt_gate "${TICK_REPO_ROOT:-$ROOT}" "$LANE_STATE_KEY" "$FORCE" || _lag_rc=$?
relay-automation/marathon-drive.sh-1134-if [[ "$_lag_rc" -eq 8 ]]; then
relay-automation/marathon-drive.sh:1135:  xyz_debug_log_append warn "marathon.lane-park" "lane $LANE_STATE_KEY parked at attempt cap" \
relay-automation/marathon-drive.sh:1136:    "" "re-anchor to QUEUE lanes or re-fire with --force"
relay-automation/marathon-drive.sh-1137-fi
relay-automation/marathon-drive.sh-1138-[[ "$_lag_rc" -eq 0 ]] || exit "$_lag_rc"
--
relay-automation/marathon-drive.sh-1257-# see the GH-274 comment there — but still called from this case statement as before.
relay-automation/marathon-drive.sh-1258-
relay-automation/marathon-drive.sh:1259:recover_already_satisfied_lane() {
relay-automation/marathon-drive.sh-1260-  local gate_exit=0 review_exit=0 s tstatus actor
relay-automation/marathon-drive.sh-1261-  [[ -n "$ARTIFACT_PATHS" ]] || return 3
--
relay-automation/marathon-drive.sh-1294-    0) return 0 ;;
relay-automation/marathon-drive.sh-1295-    5)
relay-automation/marathon-drive.sh:1296:      log "already-satisfied probe: reviewer declined approval — lane remains unsatisfied"
relay-automation/marathon-drive.sh-1297-      return 3
relay-automation/marathon-drive.sh-1298-      ;;
--
relay-automation/marathon-drive.sh-1306-    ;;
relay-automation/marathon-drive.sh-1307-  3)
relay-automation/marathon-drive.sh:1308:    if recover_already_satisfied_lane; then
relay-automation/marathon-drive.sh-1309-      complete_phase_success already-satisfied
relay-automation/marathon-drive.sh-1310-    fi
--
relay-automation/marathon-drive.sh-1331-    ;;
relay-automation/marathon-drive.sh-1332-  6)
relay-automation/marathon-drive.sh:1333:    # A turn-taker shim hit an off-lane edit, reverted it, and failed the turn (exit 6) — the
relay-automation/marathon-drive.sh-1334-    # containment boundary fired. This is a DEFINED escalation, not an "unexpected" crash: the
relay-automation/marathon-drive.sh-1335-    # builder strayed but the safety core held. Record it like any other escalation. (Dogfood
relay-automation/marathon-drive.sh:1336:    # 2026-06-17: an autonomous builder edited an off-lane file; rtl_enforce caught + reverted it.)
relay-automation/marathon-drive.sh:1337:    log "relay escalated: containment violation — a turn-taker reverted an off-lane edit (exit 6)"
relay-automation/marathon-drive.sh:1338:    escalate "containment-violation (off-lane edit reverted by a turn-taker)" 6
relay-automation/marathon-drive.sh-1339-    xyz_marathon_heartbeat_clear
relay-automation/marathon-drive.sh:1340:    xyz_marathon_emit red "halted at phase ${PHASE_ID} — containment violation (off-lane edit reverted)"
relay-automation/marathon-drive.sh-1341-    exit 6
relay-automation/marathon-drive.sh-1342-    ;;
--
utils/py/marathon_drive.py-16-# callers load this module via importlib.util.spec_from_file_location rather than `python3 <path>`,
utils/py/marathon_drive.py-17-# which does NOT put the script's own directory on sys.path (GH-448 regression, test/gh322-runlog-
utils/py/marathon_drive.py:18:# python-lane.sh caught it). Same pattern as marathon_plan.py's `_marathon_plan` import.
utils/py/marathon_drive.py-19-sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
utils/py/marathon_drive.py:20:from rtl import driver_lock_path  # noqa: E402
utils/py/marathon_drive.py-21-
utils/py/marathon_drive.py-22-# GH-284 Phase 2 / GH-322: hooks run on EVERY terminal path with the driver's real exit code — the
--
utils/py/marathon_drive.py-32-#
utils/py/marathon_drive.py-33-# Codes 1, 2 and 8 are mapped defensively but cannot appear in a posted run log: lock contention,
utils/py/marathon_drive.py:34:# `die()` and the lane-attempt cap all exit BEFORE the run log arms (drive_started).
utils/py/marathon_drive.py-35-_EXIT_MEANINGS = {
utils/py/marathon_drive.py-36-    0: "approved, gate passed",
utils/py/marathon_drive.py:37:    1: "driver lock contention",
utils/py/marathon_drive.py-38-    2: "usage or configuration error",
utils/py/marathon_drive.py-39-    3: "no-progress escalation",
utils/py/marathon_drive.py-40-    4: "round-cap or close-mismatch escalation",
utils/py/marathon_drive.py-41-    5: "pre-advance gate failed",
utils/py/marathon_drive.py:42:    6: "containment violation — off-lane edit reverted",
utils/py/marathon_drive.py-43-    7: "turn timeout / hang",
utils/py/marathon_drive.py:44:    8: "lane parked at the attempt cap",
utils/py/marathon_drive.py-45-    9: "post-approve command failed, approval preserved",
utils/py/marathon_drive.py-46-    127: "relay-drive could not execute — check MARATHON_RELAY_DRIVE",
--
utils/py/marathon_drive.py-93-    return ""
utils/py/marathon_drive.py-94-
utils/py/marathon_drive.py:95:# ── Sentinel Tier 1 (GH-281), ported to the lane that runs (GH-342) ──────────────────────────
utils/py/marathon_drive.py:96:# marathon-drive.sh carried this capture; Python is the default lane since GH-264, so arming
utils/py/marathon_drive.py-97-# XYZ_DEBUG_LOG=1 on a normal run wrote nothing. Contract preserved exactly, including the parts
utils/py/marathon_drive.py-98-# that make it safe to leave in a public repo:
--
utils/py/marathon_drive.py-142-
utils/py/marathon_drive.py-143-    Field order and the empty `line` field are load-bearing: this file is consumed by the Sentinel
utils/py/marathon_drive.py:144:    tooling as a fixed record shape, and the Bash lane emits exactly this. Built with a format
utils/py/marathon_drive.py-145-    string rather than json.dumps for the same reason — json.dumps would escape correctly but is
utils/py/marathon_drive.py:146:    free to differ on separators, and the two lanes must produce identical bytes.
utils/py/marathon_drive.py-147-    """
utils/py/marathon_drive.py-148-    if not xyz_debug_log_enabled():
--
utils/py/marathon_drive.py-165-    Deliberately NOT routed through xyz_debug_log_append: `marathon-drive.sh:220` inlines a SHORTER
utils/py/marathon_drive.py-166-    record here (no phase/task/file/line/probe) because the helper is not defined that early in the
utils/py/marathon_drive.py:167:    Bash file, and it leaves `repo` unescaped. Reproduced as-is — the two lanes must agree, and
utils/py/marathon_drive.py:168:    "improving" the shape on one lane only is how the drift this issue exists to fix gets recreated.
utils/py/marathon_drive.py:169:    The inconsistent shape is worth fixing on BOTH lanes, separately and on purpose.
utils/py/marathon_drive.py-170-    """
utils/py/marathon_drive.py-171-    if not xyz_debug_log_enabled():
--
utils/py/marathon_drive.py-173-    _xyz_debug_log_write(root, (
utils/py/marathon_drive.py-174-        '{"timestamp":"%s","severity":"info","check":"marathon.stale-lock","scope":"harness"'
utils/py/marathon_drive.py:175:        ',"repo":"%s","message":"stale driver lock reclaimed","action":"none (auto-healed)"}\n'
utils/py/marathon_drive.py-176-    ) % (_utc_now_z(), root))
utils/py/marathon_drive.py-177-
--
utils/py/marathon_drive.py-331-
utils/py/marathon_drive.py-332-def _probe_agent_bin(agent_id, role_label):
utils/py/marathon_drive.py:333:    # GH-117: fail before any tick mutation or clean-workspace scan if the lane's
utils/py/marathon_drive.py-334-    # builder/reviewer binary would be undispatchable.
utils/py/marathon_drive.py-335-    if agent_id.startswith("claude"):
--
utils/py/marathon_drive.py-368-#
utils/py/marathon_drive.py-369-# Raising the single default to 1800 was the other option and was rejected: it buys headroom and
utils/py/marathon_drive.py:370:# changes nothing structural, so the next lane that adds a suite spends it and this recurs.
utils/py/marathon_drive.py-371-#
utils/py/marathon_drive.py-372-# Tiers restore the cap's meaning. `fast` is sized so that an overrun is unambiguously a runaway
--
utils/py/marathon_drive.py-556-    parser.add_argument("--requires-test", dest="requires_test")  # GH-249: nominated test must change
utils/py/marathon_drive.py-557-    parser.add_argument("--force", dest="force", action="store_true")
utils/py/marathon_drive.py:558:    # GH-402: deliberately NOT folded into --force. --force bypasses the per-lane attempt cap, which
utils/py/marathon_drive.py-559-    # is a "you have tried this too often" bound; this is a "you are about to commit to trunk" bound.
utils/py/marathon_drive.py:560:    # One flag for both would mean an operator retrying a flaky lane silently acquires permission to
utils/py/marathon_drive.py-561-    # land on main, which is the kind of coupling that is obvious only after it happens.
utils/py/marathon_drive.py-562-    parser.add_argument("--allow-trunk-commit", dest="allow_trunk_commit", action="store_true",
--
utils/py/marathon_drive.py-572-        print("  --post-approve-cmd CMD  Optional command after phase.approved + green telemetry (default: unset).")
utils/py/marathon_drive.py-573-        print("                           Failure preserves approval, writes reason post-approve-failed, and exits 9.")
utils/py/marathon_drive.py:574:        print("  --log-github            GH-284 opt-in run log (default OFF). Updates the lane's EXISTING GitHub")
utils/py/marathon_drive.py-575-        print("                          issue in place via a marker comment — never creates an issue, never closes")
utils/py/marathon_drive.py-576-        print("                          one. A missing/unauthenticated gh degrades to local telemetry only.")
--
utils/py/marathon_drive.py-578-
utils/py/marathon_drive.py-579-    # GH-322: `unknown` was captured and never read, so ANY unrecognised flag was silently
utils/py/marathon_drive.py:580:    # discarded. Because Python is the executing lane (GH-264), that made `--log-github` — the
utils/py/marathon_drive.py-581-    # headline feature of GH-284 Phase 2, which existed only in the Bash twin — a no-op: the marathon
utils/py/marathon_drive.py-582-    # ran, exited 0, reported success, and never posted a run log. All three Bash twins `die
utils/py/marathon_drive.py-583-    # "unknown argument: $1"`; this restores that contract byte-for-byte (same prefix, same exit 2).
utils/py/marathon_drive.py-584-    # Checked AFTER --help so `--help` still works alongside a bad flag.
utils/py/marathon_drive.py:585:    # (--log-github is now a real flag on this lane too — see marathon_run_github_log below. The
utils/py/marathon_drive.py-586-    # temporary "re-run with XYZ_PYTHON=0" message this branch used to carry is gone with the port.)
utils/py/marathon_drive.py-587-    if unknown:
--
utils/py/marathon_drive.py-620-    agent_cmd = get_env("MARATHON_AGENT_CMD", os.path.join(xyz_harness, "relay-automation", "marathon-agent.sh"))
utils/py/marathon_drive.py-621-    # GH-342: `$HERE/harvest-findings.sh` in the Bash twin — HERE is relay-automation/, which for the
utils/py/marathon_drive.py:622:    # Python lane is a sibling of utils/py's grandparent. Resolved once; both call sites re-check
utils/py/marathon_drive.py-623-    # os.access(X_OK) at spawn time, so a harness missing the script simply harvests nothing.
utils/py/marathon_drive.py-624-    harvest_findings_bin = os.path.join(xyz_harness, "relay-automation", "harvest-findings.sh")
utils/py/marathon_drive.py-625-
utils/py/marathon_drive.py:626:    def _lane_key(raw):
utils/py/marathon_drive.py-627-        return re.sub(r'[^A-Za-z0-9._-]', '_', raw)
utils/py/marathon_drive.py-628-
utils/py/marathon_drive.py:629:    def lane_attempt_gate(root_dir, raw, force):
utils/py/marathon_drive.py-630-        if get_env("LANE_ATTEMPT_COUNTED"): return 0
utils/py/marathon_drive.py-631-        if not raw: return 0
--
utils/py/marathon_drive.py-634-        except ValueError: max_attempts = 2
utils/py/marathon_drive.py-635-
utils/py/marathon_drive.py:636:        key = _lane_key(raw)
utils/py/marathon_drive.py-637-        attempts_dir = os.path.join(root_dir, ".tick", "attempts")
utils/py/marathon_drive.py-638-        os.makedirs(attempts_dir, exist_ok=True)
--
utils/py/marathon_drive.py-648-        
utils/py/marathon_drive.py-649-        if force:
utils/py/marathon_drive.py:650:            eprint(f"lane-attempt-cap: --force override — lane {key} at {count} attempt(s) (cap {max_attempts}), proceeding.")
utils/py/marathon_drive.py-651-        elif count >= max_attempts:
utils/py/marathon_drive.py:652:            eprint(f"lane-attempt-cap: lane {key} PARKED after {count} attempt(s) (cap {max_attempts}) — no relay token seeded.")
utils/py/marathon_drive.py:653:            eprint(f"  Re-anchor to the committed QUEUE lanes (AGENTS.md) or re-fire with --force. Attempts log: {attempts_file}")
utils/py/marathon_drive.py:654:            # Sentinel Tier 1 (GH-281/GH-342). The Bash lane emits this from the CALLER, on rc==8
utils/py/marathon_drive.py-655-            # (marathon-drive.sh:1103-1106); this gate exits directly, so it emits here instead —
utils/py/marathon_drive.py-656-            # same record, same position relative to the two messages above. `raw`, not `key`: the
utils/py/marathon_drive.py-657-            # Bash message carries $LANE_STATE_KEY as given, not the sanitized form.
utils/py/marathon_drive.py-658-            xyz_debug_log_append(
utils/py/marathon_drive.py:659:                root, "warn", "marathon.lane-park",
utils/py/marathon_drive.py:660:                f"lane {raw} parked at attempt cap",
utils/py/marathon_drive.py:661:                action="re-anchor to QUEUE lanes or re-fire with --force",
utils/py/marathon_drive.py-662-                target_root=args.target_root, phase_id=args.phase_id,

2026-08-17T19:26:34.958695Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 96 column 5
exec
/bin/zsh -lc "rg -n -C 2 '\\bACID\\b|event.sourced|event log|path.scoped|path-scoped|lock(s)?' README.md GUIDING-PRINCIPLES.md bin src utils relay-automation | head -400
rg -n -C 2 'worktree|clone|lane|wave|MARATHON_LANE_NS' README.md skills/relay-xyz/SKILL.md utils/py/_marathon_plan.py utils/marathon-plan.sh | head -450" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr
 succeeded in 0ms:
GUIDING-PRINCIPLES.md-5-## Purpose
GUIDING-PRINCIPLES.md-6-
GUIDING-PRINCIPLES.md:7:`tick` coordinates Claude Code, Codex, and agy (Antigravity CLI) on the same branch without collision: a shared local event log under `.tick/events/`, claims serialized by `O_EXCL` locks, and a `Marathon` harness that chains multi-phase build→review cycles from a `MARATHON.yaml`. The relay layer (`relay-automation/`) drives headless turns, isolates agent writes to worktrees, and enforces an allowlist so no headless agent destroys work it didn't intend to touch. The goal: a multi-agent swarm safe enough to run against a real external codebase and correct enough that its output is worth shipping.
GUIDING-PRINCIPLES.md-8-
GUIDING-PRINCIPLES.md-9-## The quality bar
--
GUIDING-PRINCIPLES.md-22-1. **Coordination is local-transport only.** `.tick/events/` is the shared bus; claims resolve from there, not from a remote. No per-event push/fetch; no remote dependency at runtime. A coordination primitive that reaches out is a coordination primitive that can fail or leak.
GUIDING-PRINCIPLES.md-23-
GUIDING-PRINCIPLES.md:24:2. **One canonical event log; every surface is a projection.** `tick` accretes events; `STATE.md` is the current projection. Reads go through the projection; writes go through a `claim/take/scope/done` verb. Nothing canonical lives in two places where it can drift. An agent that hard-codes state outside `.tick/` is creating drift.
GUIDING-PRINCIPLES.md-25-
GUIDING-PRINCIPLES.md-26-3. **Containment is non-negotiable.** A headless turn must not: self-commit mid-turn, orphan a peer's concurrent commit, or write outside its allowlist. The allowlist, worktree isolation, and commit-bypass guard exist because a driven agent will do all three if unconstrained — not hypothetically, but as documented live incidents (GH-13, GH-14, GH-17). New relay paths must clear the containment bar before they ship.
GUIDING-PRINCIPLES.md-27-
GUIDING-PRINCIPLES.md:28:4. **Skill-first; never improvise the harness.** The `relay-xyz` skill owns the locator, sandbox rules, exit codes, and the safety boundary. A session that improvises those from `ls relay-automation/` silently skips the skill's safety layer. The `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) enforces this by blocking driver calls before the skill loads. Add capabilities to the skill; do not work around it.
GUIDING-PRINCIPLES.md-29-
GUIDING-PRINCIPLES.md-30-5. **Adversarially proven before commercially viable.** The harness exists to run against real codebases. Features in the adversarial-hardening track (epoch fencing, chaos suite, cross-repo E2E) must be verified to survive deliberate abuse — stale writers, zombie claims, macOS case-sensitivity, concurrent peer commits — not just the happy path. A feature that clears the happy path and skips chaos is half-done.
--
GUIDING-PRINCIPLES.md-32-6. **Build durable, not band-aid.** Durable means it removes the root cause and the next planned change builds on it — not a patch torn out when the obvious next feature lands. A band-aid is wasted work unless a demo strictly needs one, and a demo band-aid is tagged for removal so it isn't silently inherited.
GUIDING-PRINCIPLES.md-33-
GUIDING-PRINCIPLES.md:34:7. **Least code that clears the bar.** Node standard library only — no deps, no lockfile; the repo ships no root manifest. Prefer reusing or extending what exists; the smallest change that stays correct, contained, and durable wins. Net-new code is a cost to justify. Deleting code counts as progress.
GUIDING-PRINCIPLES.md-35-
GUIDING-PRINCIPLES.md-36-8. **Honest; the operator decides.** Surface what failed and why — never mask a stall as success or an escalation as a stall. A headless turn self-repairs within a bounded exit-code menu (`exit 3` stall, `exit 4` escalated-by-design, `exit 6` containment revert), then stops; it never loops forever or silently swallows an error. Destructive actions require explicit authorization.
--
GUIDING-PRINCIPLES.md-42-11. **Issue-first; every non-trivial change has a signal stream.** Any change beyond a 2–3 line fix opens a GitHub issue first, then gets a `GH-<number>` in-repo pointer doc, then lands. The issue is the machine-queryable signal stream; the `PROJECT/**` doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt.
GUIDING-PRINCIPLES.md-43-
GUIDING-PRINCIPLES.md:44:12. **Independent Verification (Separated Grading)** — The agent that produces a turn must not be the sole grader of its own quality. Verification must be performed by an independent deterministic check or a separate reviewing agent before the lock releases. Applies to: the relay's structural block validator (`bin/validate-relay-block` — Phase 1 of GH-21), consult-verify diversity (Phase 3), and any other post-generation quality gate.
GUIDING-PRINCIPLES.md-45-
GUIDING-PRINCIPLES.md-46-13. **A green gate without a witnessed red control is not evidence.** Every new or materially changed decision gate ships a recorded demonstration that it fails for the right reason: a pre-fix replay, deliberate mutation, or controlled bad fixture. Do not mistake a check that validates the artifact it just generated (#351) or a parity check that compares a lane to itself (#348) for evidence; both shapes are structurally unable to falsify their claim.
--
GUIDING-PRINCIPLES.md-96-
GUIDING-PRINCIPLES.md-97-**Scope note:** where a *working* binary lives stays the operator's call. This is a convention and a
GUIDING-PRINCIPLES.md:98:warning, deliberately **not** a gate — a false positive that blocks a relay is worse than the papercut it
GUIDING-PRINCIPLES.md-99-prevents.
GUIDING-PRINCIPLES.md-100-
--
GUIDING-PRINCIPLES.md-128-1. **Containment preserved?** Any headless path that could self-commit, touch off-allowlist files, or orphan a peer commit without an explicit containment argument → reject or escalate.
GUIDING-PRINCIPLES.md-129-2. **Skill-first respected?** Any plan that bypasses `relay-xyz` or improvises the harness from scratch without the skill layer → reject. Add to the skill instead.
GUIDING-PRINCIPLES.md:130:3. **Coordination through the event log?** Reads/writes to shared state route through `tick` verbs; hard-coded state outside `.tick/` needs explicit justification.
GUIDING-PRINCIPLES.md-131-4. **Done verifiable?** Names runnable gates (`validate.sh`, specific tests, `utils/pdda/pdda.sh run`). None = low-quality signal.
GUIDING-PRINCIPLES.md-132-5. **Drift reduced, not created?** No duplicated docs, no execution detail in ROADMAP.md, no reinventing a path the event-log contract already documents.
--
README.md-8-It's built in two layers:
README.md-9-
README.md:10:- **`tick`** — the kernel: a tiny local event-log CLI that hands out collision-free, path-scoped
README.md-11-  work claims, so two agents never edit the same thing at once. No server, no API keys, no remote.
README.md-12-- **`relay-automation/`** — the product on top of `tick`: it runs agents in **turns** (one builds,
--
README.md-47-> **⚠️ Run this un-sandboxed.** Under Claude Code's default Bash sandbox — or any sandboxed agent
README.md-48-> harness — this command prints **nothing for several minutes** before failing, because the suite's
README.md:49:> `mktemp -d` scratch directories are blocked. It looks like a hang, not a permissions error, and
README.md-50-> it is this repo's single most common false alarm. Turn the sandbox off for this command
README.md-51-> (`/sandbox` in Claude Code, or run it yourself in a normal terminal) before concluding anything
--
README.md-101-   windows. Changes are confined to the relay thread file and the artifact under review.
README.md-102-3. **Swarm** — two or more agents working **concurrently** on the same repo, each claiming a
README.md:103:   non-overlapping, path-scoped lane (via the `tick` kernel) so they never collide. Good for
README.md-104-   parallel builds or parallel codebase recon. This is where PDDA's doc structure starts to matter,
README.md-105-   because lanes are carved from well-defined task docs.
--
README.md-218-collisions: it constrains which lanes may share a wave, never how much RAM they consume.
README.md-219-
README.md:220:XYZ does have per-gate resource containment: the GH-390 gate guard enforces **wall-clock, CPU and
README.md-221-RSS** caps and kills an over-budget gate. It does **not** currently inspect host RAM, clamp a wave
README.md-222-width, or refuse a wave that is too large for the machine. Host-aware wave sizing remains the
--
README.md-264-- **Agent users: run un-sandboxed.** If you're driving this from Claude Code (or another sandboxed
README.md-265-  agent harness), relay and consult runs need real keychain access and outbound network egress to
README.md:266:  reach Codex/agy — a sandboxed shell will fail with "Operation not permitted" or a blocked-host
README.md-267-  error that looks like a bug but is really the sandbox. Disable the sandbox for these commands
README.md-268-  before concluding something is broken.
--
README.md-306-
README.md-307-It reads every `marathon-system/*/RELAY.md` (and the legacy `phases/` location), the local tick
README.md:308:event log, and commits reachable from the target's current branch tip. A reported **UNGATED COMMIT**
README.md-309-means a phase remains open or escalated, has no `marathon.phase.approved` event, and already has a
README.md-310-landed commit: treat it as unverified. Re-run that phase's gate or revert the commit before trusting
README.md:311:it. The report also shows the driver-lock state. A stale lock self-heals on the next marathon run;
README.md:312:a lock reported LIVE only means its PID still answers the liveness probe, so check a seemingly-dead
README.md-313-holder rather than assuming it is stale.
README.md-314-
--
README.md-328-[The four modes of operation](#the-four-modes-of-operation) in the beta section above.)
README.md-329-
README.md:330:- **`tick`** — the coordination kernel: a shared local event log (`.tick/events/`) that agents
README.md:331:  claim work through, serialized by an `O_EXCL` lock.
README.md-332-- **relay** — a turn-based loop where one agent builds and another reviews, handing off through
README.md-333-  files instead of a human copy-pasting between windows.
--
README.md-370-
README.md-371-Parallelism does exist, but as **swarms**: separate agents in separate worktrees or clones on
README.md:372:disjoint write-sets, coordinated by `tick` locks. That is arranged by the operator, not scheduled
README.md-373-from a dependency graph.
README.md-374-
--
README.md-390-For instance, the `/10days` skill fans out parallel subagents to *triage and inspect* issues simultaneously,
README.md-391-while the execution of any given marathon runner stays strictly sequential across its internal phases to prevent
README.md:392:workspace clobbering and driver-lock contention.
README.md-393-
README.md-394-Always `--dry-run` a new plan first. It parses every field and prints the real execution order at
--
README.md-397-## Glossary & Execution Model
README.md-398-
README.md:399:To avoid ambiguity across planning, kernel locks, and multi-agent workflows, terminology in this repository adheres to the following definitions:
README.md-400-
README.md-401-| Term | Scope | Definition | Execution & Concurrency Model |
--
README.md-408-| **Wave** | Planner | A batch of independent lanes identified by disjoint write-sets (via `marathon-plan.sh`) that can be safely scheduled together. | Batch scheduling |
README.md-409-| **Marathon** | Automation | A multi-phase runner (`marathon-drive.sh`) that executes an ordered sequence of phases, gates, and git commits on a branch. | Serial orchestrator |
README.md:410:| **Swarm** | Architecture | Multiple independent agents running concurrently across **separate clones or worktrees**, coordinated by `tick` locks. | **Parallel / Distributed** |
README.md-411-| **`depends_on`** | Config | An authoring validation assertion in a marathon plan verifying prerequisite phase completion before starting the next. | Assertion gate (not parallel DAG) |
README.md:412:| **`tick` Kernel** | Kernel | The local, serverless event-log engine managing collision-free task claims and path-scoped locks under `.tick/events/`. | ACID / Event-sourced |
README.md-413-
README.md-414-## Repo map
--
README.md-437-- `utils/marathon-plan.sh` — the marathon planner/ranker: scores the whole ROADMAP ledger into waves of disjoint, collision-safe write-sets, and with `--deep` delegates to `swarm-preflight.sh --dry-run` per item for an authoritative freshness verdict. Writes `PROJECT/2-WORKING/MARATHON-PLAN-<date>.md` — the "marathon file" the operator skills act on.
README.md-438-- `utils/swe-diagram/` — dependency-free architecture/Git-history diagram generator; `layout: "git-lanes"` renders stacked branch lanes with commits left-to-right, driven by a local ref-reading generator that emits an auditable JSON spec plus self-contained HTML. See [GH-201](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/201).
README.md:439:- `utils/git-bundle-snapshot.sh` + `relay-automation/hooks/gh177-sandbox-test-guard.sh` — the wipe-prevention layer: rotated `git bundle --all` backups on a daily cron, plus a PreToolUse hook that blocks running the test suite under a *sandboxed* Claude Code Bash call (the ignition for the GH-177 repo wipes). See [GH-233](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/233).
README.md-440-- `install.sh` — materializes the `tick` runtime (`bin/tick` + `src/*.js`) into an external repo and records the install in a per-user, machine-local registry (`~/.config/xyz/registry.tsv`). See "Install into another repo" below.
README.md-441-- `utils/hq/` — **HQ**, the multi-repo command center (`hq.sh` + `hq-lib.sh`); driven by the user-level `/hq` skill in `skills/hq/`. See [HQ — multi-repo command center](#hq--multi-repo-command-center) below.
--
README.md-443-## What `tick` is
README.md-444-
README.md:445:`tick` coordinates agents through a shared local event log under `.tick/events/`.
README.md:446:Claims are serialized by an `O_EXCL` lock, and projection folds events into
README.md-447-`.tick/STATE.md`. Coordination is local-transport only: no per-event push/fetch,
README.md-448-no remote dependency, one shared `.tick/` directory per active run.
--
src/take.js-4-const { project, fold, nextEpoch, activeClaimsForAgent, MAX_ACTIVE_CLAIMS_PER_AGENT } = require('./project');
src/take.js-5-const { setsOverlap } = require('./paths');
src/take.js:6:const { withClaimLock } = require('./lock');
src/take.js-7-
src/take.js:8:// Atomic next+claim under one lock. Eliminates the TOCTOU gap between
src/take.js-9-// `tick next` and `tick claim` where another agent can snatch the task
src/take.js-10-// between the two calls.
--
utils/signal-triage.sh-27-# Severity derived from category: bug->high, drift->medium, enhancement->low, noise->drop
utils/signal-triage.sh-28-# No confidence field (deterministic classifier, trivially 1.0 per GP #7).
utils/signal-triage.sh:29:# Never writes a .tick/ record (.tick/ is the coordination event log; triage notes are not events).
utils/signal-triage.sh-30-#
utils/signal-triage.sh-31-# Usage:
--
relay-automation/CONSUMING.md-20-## 2. Run sandbox-OFF — including the PONG preflight
relay-automation/CONSUMING.md-21-
relay-automation/CONSUMING.md:22:`agy` (and `codex`) fail **silently empty under a sandbox** (blocked backend → exit 0, no output).
relay-automation/CONSUMING.md-23-The shim catches that as a hard failure (exit 5), but the preflight check fails the same way, so run
relay-automation/CONSUMING.md-24-it sandbox-OFF too:
--
bin/tick-25-}
bin/tick-26-
bin/tick:27:// Coordination-mutation verbs that operate on a task's lock in .tick/events.
bin/tick-28-// A bare call from a foreign CWD (no TICK_REPO_ROOT) resolves the wrong root via
bin/tick-29-// `git rev-parse` and would silently land in — or auto-create — the wrong repo's
--
bin/tick-111-  2 — usage error (missing/unknown flags) — deliberately distinct from a lost claim
bin/tick-112-  6 — containment violation (off-allowlist edit in relay-turn-lib.sh)
bin/tick:113:  8 — relay block structural validation failed (bin/validate-relay-block returned non-zero)
bin/tick-114-`);
bin/tick-115-}
--
bin/tick-237-      if (!task || !flags.agent) { usage(); return 2; }
bin/tick-238-      if (flags['relay-file']) {
bin/tick:239:        const validateScript = path.resolve(__dirname, 'validate-relay-block');
bin/tick-240-        try {
bin/tick-241-          execFileSync(validateScript, [flags['relay-file']], { stdio: 'inherit' });
--
bin/tick-262-      if (!task || !flags.agent) { usage(); return 2; }
bin/tick-263-      if (flags['relay-file']) {
bin/tick:264:        const validateScript = path.resolve(__dirname, 'validate-relay-block');
bin/tick-265-        try {
bin/tick-266-          execFileSync(validateScript, [flags['relay-file']], { stdio: 'inherit' });
--
relay-automation/deep-research.mjs-24-// Env:
relay-automation/deep-research.mjs-25-//   AGY_BIN                          agy binary (default: agy; tests inject a stub)
relay-automation/deep-research.mjs:26://   DEEP_RESEARCH_TIMEOUT_MS         wall-clock cap in ms (default: 120000 / 120s). Override upward
relay-automation/deep-research.mjs-27-//                                    (e.g. 180000) for a thorough, multi-claim --search-context-size
relay-automation/deep-research.mjs-28-//                                    high query that needs more headroom than the default — see the
--
relay-automation/deep-research.mjs-150-  try {
relay-automation/deep-research.mjs-151-    // spawn, NOT execFile: execFile silently IGNORES the `stdio` option, so agy's stdin was left an
relay-automation/deep-research.mjs:152:    // OPEN pipe that never EOF'd — real `agy -p` then blocks reading stdin until --print-timeout and
relay-automation/deep-research.mjs-153-    // the whole call hangs (measured 2026-07-04: execFile 75s→timeout/0-bytes vs spawn 10s→ok). The
relay-automation/deep-research.mjs-154-    // stub tests never caught it because the stub does not read stdin. spawn honors stdio:['ignore',…]
relay-automation/deep-research.mjs-155-    // so stdin is /dev/null (immediate EOF) and the run is non-interactive.
relay-automation/deep-research.mjs-156-    // --dangerously-skip-permissions: a non-interactive grounded search MUST auto-approve agy's
relay-automation/deep-research.mjs:157:    // web-search/grounding tool, or print mode blocks on a permission prompt that never comes. Safe
relay-automation/deep-research.mjs-158-    // here: the run is confined to the throwaway tmpdir below and the system prompt forbids file/shell
relay-automation/deep-research.mjs:159:    // tools. --print-timeout mirrors our own wall-clock cap as agy's internal ceiling.
relay-automation/deep-research.mjs-160-    const stdout = await new Promise((resolve, reject) => {
relay-automation/deep-research.mjs-161-      const child = spawn(
--
relay-automation/deep-research.mjs-218-  if (args.maxTokens !== null) body.max_tokens = args.maxTokens;
relay-automation/deep-research.mjs-219-
relay-automation/deep-research.mjs:220:  // AbortController mirrors runAgy's wall-clock cap; an abort surfaces as err.name === 'AbortError'
relay-automation/deep-research.mjs-221-  // → classified 'timeout'. A refused/unreachable gateway surfaces as fetch's TypeError → backend_error.
relay-automation/deep-research.mjs-222-  const controller = new AbortController();
--
relay-automation/xyz-vendor.sh-64-  while IFS= read -r entry; do
relay-automation/xyz-vendor.sh-65-    [ -n "$entry" ] || continue
relay-automation/xyz-vendor.sh:66:    # GH-72: only delete a lock we still own (pid names us, or is gone) — never a peer's lock we may
relay-automation/xyz-vendor.sh-67-    # have lost to a reclaim.
relay-automation/xyz-vendor.sh-68-    owner="$(cat "$entry/pid" 2>/dev/null || true)"
--
relay-automation/xyz-vendor.sh-79-trap cleanup EXIT INT TERM HUP
relay-automation/xyz-vendor.sh-80-
relay-automation/xyz-vendor.sh:81:remember_lock() {
relay-automation/xyz-vendor.sh-82-  HELD_LOCKS="${HELD_LOCKS}${HELD_LOCKS:+
relay-automation/xyz-vendor.sh-83-}$1"
relay-automation/xyz-vendor.sh-84-}
relay-automation/xyz-vendor.sh-85-
relay-automation/xyz-vendor.sh:86:forget_lock() {
relay-automation/xyz-vendor.sh-87-  local needle="$1" kept="" entry
relay-automation/xyz-vendor.sh-88-  while IFS= read -r entry; do
--
relay-automation/xyz-vendor.sh-97-}
relay-automation/xyz-vendor.sh-98-
relay-automation/xyz-vendor.sh:99:advisory_lock_path() {
relay-automation/xyz-vendor.sh-100-  local target="$1" dir stem
relay-automation/xyz-vendor.sh-101-  dir="$(dirname "$target")"
--
relay-automation/xyz-vendor.sh-104-    *.*) stem="${stem%.*}" ;;
relay-automation/xyz-vendor.sh-105-  esac
relay-automation/xyz-vendor.sh:106:  printf '%s/%s.lock' "$dir" "$stem"
relay-automation/xyz-vendor.sh-107-}
relay-automation/xyz-vendor.sh-108-
relay-automation/xyz-vendor.sh:109:acquire_advisory_lock() {
relay-automation/xyz-vendor.sh:110:  local target="$1" label="$2" lockdir holder deadline empty_streak
relay-automation/xyz-vendor.sh:111:  lockdir="$(advisory_lock_path "$target")"
relay-automation/xyz-vendor.sh-112-  # Fail-open only after a real WALL-CLOCK wait on a stuck holder — never after a few lost fast races
relay-automation/xyz-vendor.sh-113-  # (GH-72: the old attempt-count + `sleep 1` gave up in ~5s under contention and wrote UNLOCKED,
--
relay-automation/xyz-vendor.sh-116-  empty_streak=0
relay-automation/xyz-vendor.sh-117-  while :; do
relay-automation/xyz-vendor.sh:118:    if mkdir "$lockdir" 2>/dev/null; then
relay-automation/xyz-vendor.sh:119:      printf '%s\n' "$$" > "$lockdir/pid" 2>/dev/null || true
relay-automation/xyz-vendor.sh:120:      remember_lock "$lockdir"
relay-automation/xyz-vendor.sh:121:      ADVISORY_LOCK_DIR="$lockdir"
relay-automation/xyz-vendor.sh-122-      return 0
relay-automation/xyz-vendor.sh-123-    fi
relay-automation/xyz-vendor.sh-124-    if [ "$(date +%s)" -ge "$deadline" ]; then
relay-automation/xyz-vendor.sh:125:      note "$label: lock $lockdir held too long; proceeding without lock"
relay-automation/xyz-vendor.sh-126-      ADVISORY_LOCK_DIR=""
relay-automation/xyz-vendor.sh-127-      return 1
relay-automation/xyz-vendor.sh-128-    fi
relay-automation/xyz-vendor.sh:129:    holder="$(cat "$lockdir/pid" 2>/dev/null || true)"
relay-automation/xyz-vendor.sh-130-    if [ -z "$holder" ]; then
relay-automation/xyz-vendor.sh-131-      # GH-72: empty pid = winner mkdir'd but hasn't written its pid yet (sub-ms) — NOT stale; wait.
--
relay-automation/xyz-vendor.sh-133-      empty_streak=$((empty_streak + 1))
relay-automation/xyz-vendor.sh-134-      if [ "$empty_streak" -ge 20 ]; then
relay-automation/xyz-vendor.sh:135:        note "$label: reclaiming orphaned lock ($lockdir, no pid)"
relay-automation/xyz-vendor.sh:136:        rm -rf "$lockdir" 2>/dev/null || true
relay-automation/xyz-vendor.sh-137-        empty_streak=0
relay-automation/xyz-vendor.sh-138-      fi
--
relay-automation/xyz-vendor.sh-145-      continue
relay-automation/xyz-vendor.sh-146-    fi
relay-automation/xyz-vendor.sh:147:    note "$label: reclaiming stale lock ($lockdir, dead pid $holder)"
relay-automation/xyz-vendor.sh:148:    rm -rf "$lockdir" 2>/dev/null || true
relay-automation/xyz-vendor.sh-149-  done
relay-automation/xyz-vendor.sh-150-}
relay-automation/xyz-vendor.sh-151-
relay-automation/xyz-vendor.sh:152:release_advisory_lock() {
relay-automation/xyz-vendor.sh:153:  local lockdir="${1:-}" owner
relay-automation/xyz-vendor.sh:154:  [ -n "$lockdir" ] || return 0
relay-automation/xyz-vendor.sh:155:  # GH-72: only delete the lock if WE still own it (pid names us, or is gone) — never a peer's lock
relay-automation/xyz-vendor.sh-156-  # that a reclaim may have handed off.
relay-automation/xyz-vendor.sh:157:  owner="$(cat "$lockdir/pid" 2>/dev/null || true)"
relay-automation/xyz-vendor.sh-158-  if [ -z "$owner" ] || [ "$owner" = "$$" ]; then
relay-automation/xyz-vendor.sh:159:    rm -rf "$lockdir" 2>/dev/null || true
relay-automation/xyz-vendor.sh-160-  fi
relay-automation/xyz-vendor.sh:161:  forget_lock "$lockdir"
relay-automation/xyz-vendor.sh-162-}
relay-automation/xyz-vendor.sh-163-
relay-automation/xyz-vendor.sh:164:run_with_advisory_lock() {
relay-automation/xyz-vendor.sh-165-  local target="$1" label="$2"
relay-automation/xyz-vendor.sh-166-  shift 2
relay-automation/xyz-vendor.sh:167:  if ! acquire_advisory_lock "$target" "$label"; then
relay-automation/xyz-vendor.sh:168:    # GH-72: lock unavailable within the deadline (only under a genuinely stuck holder or pathological
relay-automation/xyz-vendor.sh-169-    # load). This is a best-effort registry/projection side-effect, so SKIP the update rather than
relay-automation/xyz-vendor.sh-170-    # perform an UNLOCKED read-modify-write that could drop a peer's row. The vendor still succeeds.
relay-automation/xyz-vendor.sh:171:    note "$label: update skipped — lock unavailable"
relay-automation/xyz-vendor.sh-172-    return 0
relay-automation/xyz-vendor.sh-173-  fi
relay-automation/xyz-vendor.sh:174:  local lockdir="$ADVISORY_LOCK_DIR" rc
relay-automation/xyz-vendor.sh-175-  "$@"
relay-automation/xyz-vendor.sh-176-  rc=$?
relay-automation/xyz-vendor.sh:177:  release_advisory_lock "$lockdir"
relay-automation/xyz-vendor.sh-178-  return "$rc"
relay-automation/xyz-vendor.sh-179-}
--
relay-automation/xyz-vendor.sh-188-  local reg="$1" target="$2" row="$3" tmp
relay-automation/xyz-vendor.sh-189-  tmp="$reg.tmp.$$"
relay-automation/xyz-vendor.sh:190:  # GH-72: build the WHOLE file under the lock — header (when $reg is new) + existing rows minus this
relay-automation/xyz-vendor.sh-191-  # target + our row — then atomic mv. Bootstrapping the header here (instead of an UNLOCKED `> "$reg"`
relay-automation/xyz-vendor.sh-192-  # in the caller) closes the first-writer truncation race: two "file missing" writers could otherwise
--
relay-automation/xyz-vendor.sh-246-  # directory-only pattern (`/phases/`) matches ONLY when the queried path also ends in `/` — on a
relay-automation/xyz-vendor.sh-247-  # repo where the directory does not exist yet, git cannot infer it is a directory, so
relay-automation/xyz-vendor.sh:248:  # `check-ignore -- phases` returns "not ignored" against a rule that will absolutely block the
relay-automation/xyz-vendor.sh-249-  # harness the moment it creates that directory. Caught by this suite's own `/phases/` case after
relay-automation/xyz-vendor.sh-250-  # the bare-form-only version passed the first two. A check whose query shape does not cover the
relay-automation/xyz-vendor.sh-251-  # rule shapes that exist reports clean for the ones it never asked about.
relay-automation/xyz-vendor.sh:252:  local _blocked="" _hit
relay-automation/xyz-vendor.sh-253-  if git -C "$TARGET_REPO" rev-parse --git-dir >/dev/null 2>&1; then
relay-automation/xyz-vendor.sh-254-    for _p in phases phases/ relay-system relay-system/; do
relay-automation/xyz-vendor.sh-255-      if _hit="$(git -C "$TARGET_REPO" check-ignore -v -- "$_p" 2>/dev/null)"; then
relay-automation/xyz-vendor.sh:256:        case "$_blocked" in
relay-automation/xyz-vendor.sh-257-          *"$_hit"$'\n'*) ;;                       # same rule already reported via the other form
relay-automation/xyz-vendor.sh:258:          *) _blocked="${_blocked}${_hit}"$'\n' ;;
relay-automation/xyz-vendor.sh-259-        esac
relay-automation/xyz-vendor.sh-260-      fi
--
relay-automation/xyz-vendor.sh-262-  fi
relay-automation/xyz-vendor.sh-263-
relay-automation/xyz-vendor.sh:264:  if [ -n "$_blocked" ]; then
relay-automation/xyz-vendor.sh-265-  {
relay-automation/xyz-vendor.sh-266-    printf 'xyz-vendor.sh: this repo IGNORES paths the harness must be able to commit.\n\n'
--
relay-automation/xyz-vendor.sh-270-    printf '  destroys the record of why it stopped.\n\n'
relay-automation/xyz-vendor.sh-271-    printf '  The rules in the way (file:line:pattern <TAB> path):\n'
relay-automation/xyz-vendor.sh:272:    printf '%s' "$_blocked" | sed 's/^/    /'
relay-automation/xyz-vendor.sh-273-    printf '\n  REFUSING to vendor rather than editing your .gitignore for you. Un-ignoring these\n'
relay-automation/xyz-vendor.sh-274-    printf '  would publish builder and reviewer transcripts this repo evidently chose to withhold,\n'
--
relay-automation/xyz-vendor.sh-304-  src_commit="$(git -C "$HARNESS_ROOT" rev-parse HEAD 2>/dev/null || printf 'unknown')"
relay-automation/xyz-vendor.sh-305-
relay-automation/xyz-vendor.sh:306:  # GH-72: header bootstrap now happens INSIDE the locked write_registry_row (no unlocked `> "$reg"`).
relay-automation/xyz-vendor.sh-307-  # Schema stays aligned with install.sh; vendored copies are identified by install_dir=.xyz and
relay-automation/xyz-vendor.sh-308-  # coordinated_repo=<target repo>.
relay-automation/xyz-vendor.sh-309-  row="$(printf '%s\t%s\t%s\t%s\t%s' "$VENDOR_DIR" "$ts" "$ver" "$src_commit" "$TARGET_REPO")"
relay-automation/xyz-vendor.sh:310:  run_with_advisory_lock "$reg" "registry" write_registry_row "$reg" "$VENDOR_DIR" "$row"
relay-automation/xyz-vendor.sh-311-  return 0
relay-automation/xyz-vendor.sh-312-}
--
relay-automation/xyz-vendor.sh-320-#   relay-automation/  all turn shims (codex/agy/aider/gemini/claude), consult, marathon runtime,
relay-automation/xyz-vendor.sh-321-#                      the self-improve loop, hooks/, docs, example configs
relay-automation/xyz-vendor.sh:322:#   bin/               tick, validate-relay-block, marathon-yaml
relay-automation/xyz-vendor.sh-323-#   src/               the tick/marathon JS core
relay-automation/xyz-vendor.sh-324-#   test/              the shim + feature tests, so a vendored repo can self-verify
--
relay-automation/xyz-vendor.sh-357-  # GH-312: carry TARGET-owned runtime state across the swap. $STAGE_DIR is mirrored purely from
relay-automation/xyz-vendor.sh-358-  # $HARNESS_ROOT, and none of these paths are in VENDOR_DIRS, so the `rm -rf` below would delete
relay-automation/xyz-vendor.sh:359:  # whatever the target accumulated -- relay threads, tick event logs, GH-75 telemetry -- unread.
relay-automation/xyz-vendor.sh-360-  # `.xyz/` is gitignored (ensure_gitignore), so nothing under it was ever hashed into a git object:
relay-automation/xyz-vendor.sh-361-  # there is no reflog, stash, or `git fsck --lost-found` recovery. A destroyed relay thread is gone.
--
relay-automation/xyz-vendor.sh-367-  # The list is state that BELONGS TO THE TARGET, not harness code:
relay-automation/xyz-vendor.sh-368-  #   relay-system/         relay threads (what vendoring is sold on -- per-repo isolation)
relay-automation/xyz-vendor.sh:369:  #   .tick/                tick event logs / claim state
relay-automation/xyz-vendor.sh:370:  #   .relay-driver.lock    live driver lock (a running relay or marathon)
relay-automation/xyz-vendor.sh:371:  #   XYZ.json{,.lock/}     GH-75 completion telemetry + its mkdir advisory lock
relay-automation/xyz-vendor.sh-372-  #   XYZ.heartbeat.json    liveness stamp
relay-automation/xyz-vendor.sh:373:  for _keep in relay-system .tick .relay-driver.lock XYZ.json XYZ.json.lock XYZ.heartbeat.json; do
relay-automation/xyz-vendor.sh-374-    [ -e "$VENDOR_DIR/$_keep" ] || continue
relay-automation/xyz-vendor.sh-375-    rm -rf "$STAGE_DIR/$_keep"
--
src/lock.js-10-// both pass the cap check before either writes, busting the cap.
src/lock.js-11-//
src/lock.js:12:// Fix: a per-clone O_EXCL lock serialises one agent's own claim calls. The
src/lock.js:13:// lock lives under .tick/locks/ (never committed; directory is in .gitignore)
src/lock.js-14-// instead of .git/ so sandbox environments that restrict .git/ writes don't
src/lock.js:15:// block normal tick operation.
src/lock.js-16-//
src/lock.js:17:// Known limitation: a hard process kill mid-claim leaves a stale lock. Recovery
src/lock.js:18:// is `rm <repo>/.tick/locks/claim.lock`. Stale-detection is Phase 2.
src/lock.js-19-
src/lock.js-20-/**
src/lock.js:21: * Path to the per-clone claim lock file, creating its parent directory if needed.
src/lock.js-22- * @param {string} repoRoot - absolute path to the repo root
src/lock.js:23: * @returns {string} absolute path to `<repoRoot>/.tick/locks/claim.lock`
src/lock.js-24- */
src/lock.js:25:function lockPath(repoRoot) {
src/lock.js:26:  const locksDir = path.join(repoRoot, '.tick', 'locks');
src/lock.js:27:  fs.mkdirSync(locksDir, { recursive: true });
src/lock.js:28:  return path.join(locksDir, 'claim.lock');
src/lock.js-29-}
src/lock.js-30-
src/lock.js-31-/**
src/lock.js:32: * Runs `fn` while holding the per-clone claim lock. `fs.openSync(.., 'wx')` is an
src/lock.js:33: * atomic create-or-fail (O_EXCL): if the lock already exists it throws EEXIST.
src/lock.js:34: * The lock is always released (closed + unlinked) before returning, including on throw.
src/lock.js-35- * @param {string} repoRoot - absolute path to the repo root
src/lock.js:36: * @param {function(): *} fn - callback to run while the lock is held
src/lock.js-37- * @returns {*} whatever `fn` returns
src/lock.js:38: * @throws {Error} if the lock is already held by another process
src/lock.js-39- */
src/lock.js-40-function withClaimLock(repoRoot, fn) {
src/lock.js:41:  const lp = lockPath(repoRoot);
src/lock.js-42-  let fd;
src/lock.js-43-  try {
--
src/lock.js-46-    if (err.code === 'EEXIST') {
src/lock.js-47-      throw new Error(
src/lock.js:48:        'another tick claim is in progress for this clone (lock held) — retry shortly, ' +
src/lock.js-49-        `or remove ${path.relative(repoRoot, lp)} if a prior claim was killed`
src/lock.js-50-      );
--
src/lock.js-61-}
src/lock.js-62-
src/lock.js:63:module.exports = { withClaimLock, lockPath };
--
README.md-30-suite stops at `Cannot find module 'acorn'`.)
README.md-31-
README.md:32:**If you are going to push to this repo, run `bash githooks/install.sh` once per clone. It is a
README.md-33-correctness requirement, not optional setup.** Hosted CI is off while this repo is private
README.md-34-(GH-544), so the local gate at the push boundary is the *only* gate — and the hook lives in
README.md:35:`.git/hooks/`, which does not travel with a clone. A clone that skipped this step pushes
README.md:36:unverified and nothing downstream will notice. One run covers every branch and linked worktree of
README.md:37:that clone (GH-549). `./validate.sh` itself warns, in-band, if this clone is ungated — check
README.md-38-directly any time with `bash githooks/install.sh --check`. (Just evaluating the project and never
README.md-39-pushing? The warning is informational only — `validate.sh` still runs and exits exactly as it
--
README.md-101-   windows. Changes are confined to the relay thread file and the artifact under review.
README.md-102-3. **Swarm** — two or more agents working **concurrently** on the same repo, each claiming a
README.md:103:   non-overlapping, path-scoped lane (via the `tick` kernel) so they never collide. Good for
README.md-104-   parallel builds or parallel codebase recon. This is where PDDA's doc structure starts to matter,
README.md:105:   because lanes are carved from well-defined task docs.
README.md-106-4. **Marathon** — the full automation payoff: a queue of pre-flighted tasks (built up during the
README.md-107-   day) fired as one long autonomous run, typically end-of-day or overnight. Marathon **requires**
--
README.md-119-allows a declared roster of two or more live sessions, and keeps exactly one active writer through
README.md-120-the relay file's existing `NEXT:` field. It is local and serialized, not a chat server: every
README.md:121:participant must be able to see the same XYZ clone, and parallel writes/broadcasts are deliberately
README.md-122-out of scope.
README.md-123-
--
README.md-148-Everything below is designed to be reversible, but please help it along:
README.md-149-
README.md:150:- **Create a fresh branch (or git worktree) in *both* repos you touch** — one in your clone of
README.md-151-  XYZ, and one in each target project where you'll run relays or install PDDA. E.g.
README.md-152-  `git checkout -b xyz-beta-test`. If anything goes sideways, recovery is just
README.md:153:  `git checkout main` and deleting the branch. If you use `git worktree` directly, read
README.md-154-  [WORKTREE-SAFETY.md](WORKTREE-SAFETY.md) first — a couple of its operations (force-removing a
README.md:155:  worktree directory, moving/relinking one) leave stale git metadata if done by hand instead of
README.md:156:  through `git worktree remove`/`repair`.
README.md-157-- **What each step actually touches** (so you know how to undo it):
README.md-158-  - *Skill install* — symlinks skill folders into the selected agent's user-level skill directory
README.md:159:    (`~/.claude/skills/` and, where supported, `~/.codex/skills/`). A `git pull` in your XYZ clone
README.md-160-    updates the installed skill through that symlink. Undo: delete the symlink. Your project repos
README.md-161-    are untouched.
--
README.md-189-**Recommended minimum: 16 GB RAM for the serial `marathon.sh --plan` route.** That minimum covers
README.md-190-one builder and its gate running serially, with normal host reserve; it does **not** support the
README.md:191:`/10days` per-lane parallel dispatch. The two routes are intentionally different: the serial command
README.md:192:works one lane at a time, while `/10days` may start one agent for each lane in a wave.
README.md-193-
README.md-194-“Supported” below means a recommended planning envelope that leaves host reserve and is not expected
README.md-195-to swap because of XYZ itself. It is not a guarantee that a target repository's test suite will
README.md:196:finish: that suite's memory use is unbounded and must be supplied by the operator when sizing a wave.
README.md-197-
README.md-198-| Host RAM | Supported execution path | Planning guidance |
README.md-199-|---|---|---|
README.md:200:| 16 GB | Serial `marathon.sh --plan` only | Do not use `/10days` per-lane parallel dispatch. |
README.md:201:| 24 GB | Serial route; small `/10days` parallel wave after manual budgeting | Reserve memory for macOS and the target suite before choosing the lane count. |
README.md:202:| 32 GB | Serial route; `/10days` per-lane parallel dispatch after manual budgeting | A practical baseline for a normal parallel wave, subject to the target suite's memory cost. |
README.md:203:| 64 GB | Serial route; wider `/10days` per-lane parallel dispatch after manual budgeting | More headroom for lanes and repository tests; it is still not an automatic wave-width limit. |
README.md-204-
README.md-205-For a serial marathon, XYZ measured about **2.2 GB steady**. For `/10days`, budget
README.md:206:**1.5–2 GB per concurrent lane**, then add the target repository's own test suite memory (an
README.md-207-unbounded, operator-supplied term) and the host reserve. In other words, choose a width that fits:
README.md:208:`available RAM − host reserve − target-suite memory`, divided by 1.5–2 GB per lane. Do not infer a
README.md-209-safe width from the table alone for a repository whose tests are memory-heavy.
README.md-210-
--
README.md-214-meaningfully changes.
README.md-215-
README.md:216:`kernel ≤ 1 per wave` is a **coordination/zone cap, not a memory cap**. It is configured through
README.md-217-`maxPerWave` in `utils/marathon-plan-zones.default.json` and applies independently of write-set
README.md:218:collisions: it constrains which lanes may share a wave, never how much RAM they consume.
README.md-219-
README.md-220-XYZ does have per-gate resource containment: the GH-390 gate guard enforces **wall-clock, CPU and
README.md:221:RSS** caps and kills an over-budget gate. It does **not** currently inspect host RAM, clamp a wave
README.md:222:width, or refuse a wave that is too large for the machine. Host-aware wave sizing remains the
README.md-223-operator's responsibility.
README.md-224-
--
README.md-270-### Fast path: immediate value, no PDDA
README.md-271-
README.md:272:1. Create a working branch in your XYZ clone.
README.md-273-2. In the XYZ repo, ask Claude Code to: *"install the /relay-xyz, /consult, and /agent2agent skills for me
README.md-274-   system-wide."*
--
README.md-369-and never its executor.
README.md-370-
README.md:371:Parallelism does exist, but as **swarms**: separate agents in separate worktrees or clones on
README.md-372-disjoint write-sets, coordinated by `tick` locks. That is arranged by the operator, not scheduled
README.md-373-from a dependency graph.
--
README.md-387-
README.md-388-**Where parallelism DOES exist is at the Swarm / Lane level.** Independent tasks and issues (Lanes)
README.md:389:can be dispatched concurrently across **separate standalone clones or isolated worktrees** on disjoint write-sets.
README.md-390-For instance, the `/10days` skill fans out parallel subagents to *triage and inspect* issues simultaneously,
README.md-391-while the execution of any given marathon runner stays strictly sequential across its internal phases to prevent
--
README.md-406-| **Phase (Doc)** | PDDA | A numbered stage of implementation defined in a `PROJECT/2-WORKING/` design specification (Phase 0, Phase 1). | Documentation / roadmap staging |
README.md-407-| **Lane** | Workflow | An autonomous execution pipeline dedicated to solving a single GitHub issue or task. | Single track |
README.md:408:| **Wave** | Planner | A batch of independent lanes identified by disjoint write-sets (via `marathon-plan.sh`) that can be safely scheduled together. | Batch scheduling |
README.md-409-| **Marathon** | Automation | A multi-phase runner (`marathon-drive.sh`) that executes an ordered sequence of phases, gates, and git commits on a branch. | Serial orchestrator |
README.md:410:| **Swarm** | Architecture | Multiple independent agents running concurrently across **separate clones or worktrees**, coordinated by `tick` locks. | **Parallel / Distributed** |
README.md-411-| **`depends_on`** | Config | An authoring validation assertion in a marathon plan verifying prerequisite phase completion before starting the next. | Assertion gate (not parallel DAG) |
README.md-412-| **`tick` Kernel** | Kernel | The local, serverless event-log engine managing collision-free task claims and path-scoped locks under `.tick/events/`. | ACID / Event-sourced |
--
README.md-418-  [`ponytail`](skills/ponytail/SKILL.md) (the `/ponytail` lens definition cited throughout
README.md-419-  `PROJECT/` docs and PDDA's `/idea` Phase 0 — see [GH-180](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/180)).
README.md:420:  Claude Code only scans `~/.claude/skills/`, so a fresh clone won't see these until you symlink them in —
README.md:421:  run `bash skills/relay-xyz/install.sh` once per clone/machine to make the `/relay-xyz` skill discoverable
README.md:422:  (see [skills/relay-xyz/SKILL.md](skills/relay-xyz/SKILL.md#first-time-setup-on-a-new-clone-or-machine-make-the-skill-discoverable)).
README.md-423-- `skills/marathon-triage/`, `skills/marathon-cleanup/`, `skills/10days/` — the marathon operator
README.md-424-  skills: triage PDDA intake + active work into a ranked, preflight-checked, collision-safe queue
README.md:425:  ([`marathon-triage`](skills/marathon-triage/SKILL.md)); archive only lanes with verified completion
README.md-426-  evidence after a run ([`marathon-cleanup`](skills/marathon-cleanup/SKILL.md)); and — the one deliberate,
README.md-427-  operator-authorized auto-fire exception to the "ask before firing" rule — sweep recent GitHub issues into
--
README.md-434-- `PROJECT/2-WORKING/` — active project docs and working plans.
README.md-435-- `bin/tick`, `src/`, `test/` — the `tick` coordination kernel and its test suite.
README.md:436:- `utils/swarm-preflight.sh` — marathon intake planner: turns a project doc or a GH-issue bundle into a marathon-ready run packet (freshness + fix-still-required checks, readiness gate, Codex/agy lane plan). Run `utils/swarm-preflight.sh --help`; see [GH-25-SWARM-PREFLIGHT-PLANNER.md](PROJECT/3-COMPLETED/GH-25-SWARM-PREFLIGHT-PLANNER.md).
README.md:437:- `utils/marathon-plan.sh` — the marathon planner/ranker: scores the whole ROADMAP ledger into waves of disjoint, collision-safe write-sets, and with `--deep` delegates to `swarm-preflight.sh --dry-run` per item for an authoritative freshness verdict. Writes `PROJECT/2-WORKING/MARATHON-PLAN-<date>.md` — the "marathon file" the operator skills act on.
README.md:438:- `utils/swe-diagram/` — dependency-free architecture/Git-history diagram generator; `layout: "git-lanes"` renders stacked branch lanes with commits left-to-right, driven by a local ref-reading generator that emits an auditable JSON spec plus self-contained HTML. See [GH-201](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/201).
README.md-439-- `utils/git-bundle-snapshot.sh` + `relay-automation/hooks/gh177-sandbox-test-guard.sh` — the wipe-prevention layer: rotated `git bundle --all` backups on a daily cron, plus a PreToolUse hook that blocks running the test suite under a *sandboxed* Claude Code Bash call (the ignition for the GH-177 repo wipes). See [GH-233](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/233).
README.md-440-- `install.sh` — materializes the `tick` runtime (`bin/tick` + `src/*.js`) into an external repo and records the install in a per-user, machine-local registry (`~/.config/xyz/registry.tsv`). See "Install into another repo" below.
--
README.md-487-### Install once, then it works from any repo
README.md-488-
README.md:489:Claude Code only scans `~/.claude/skills/`, so symlink the skill in once per clone (idempotent):
README.md-490-
README.md-491-```bash
README.md:492:bash skills/hq/install.sh      # symlinks this clone's skills/hq into ~/.claude/skills/
README.md-493-bash skills/hq/find-hq.sh --check   # one-glance readiness: hq root, sqlite3, rebalance registry
README.md-494-```
README.md-495-
README.md:496:After that, `/hq …` works from a session opened in **any** repo. Standing in this harness clone you
README.md-497-can also call `bash utils/hq/hq.sh …` directly (the forms below use that short form).
README.md-498-
--
README.md-507-| `hq.sh park [--create] [--title T] <project> <req…>` | **Issue-first intake** in the target repo: GH issue → `PROJECT/1-INBOX/` capture → ROADMAP parking. Previews unless `--create`. |
README.md-508-| `hq.sh promote [--create] --gh-issue N <project>` | **PDDA `1-INBOX → 2-WORKING`** (GH-138): `git mv GH-N-*.md` + scaffold the moved doc so it satisfies the enforced 2-WORKING contract (leaves ratings/QA gates as operator TODOs). Previews unless `--create`. |
README.md:509:| `hq.sh queue [--create] [--gh-issue N] <project> <req…>` | Append an **HQ-queued lane** to the target's newest `MARATHON-*.md` plan (non-destructive). Previews unless `--create`. |
README.md-510-| `hq.sh fire --gh-issue N [--risk 1-5] <project>` | **Gated prepare-and-hand-off** — resolves, gates (Tier A, `risk < 3`), and emits the `swarm-preflight` command for the operator to run. Never drives the harness (GUIDING-PRINCIPLES §8). |
README.md-511-
README.md-512-The intake-to-dispatch pipeline is **`park → promote → queue → fire`** — capture on the rails, promote
README.md:513:into active work, queue a marathon lane, then hand off. Each step previews first.
README.md-514-
README.md-515-### How a name becomes a repo (resolution ladder)
--
utils/py/_marathon_plan.py-9-The two temporary Python parity shims that used to wrap the copied Node engine are folded
utils/py/_marathon_plan.py-10-in here natively: ``doc_of()`` implements the correct own-``GH-<n>``-doc precedence (was the
utils/py/_marathon_plan.py:11:``_normalize_roadmap`` input-mutation shim ``S``), and the "Review lanes" overlay is rendered
utils/py/_marathon_plan.py:12:in place from ``parse_lanes_table()`` (was the ``_inject_review_lanes`` post-render shim ``N``).
utils/py/_marathon_plan.py-13-
utils/py/_marathon_plan.py-14-Output is intentionally identical to the Bash engine on fixed fixtures. It is invoked by
--
utils/py/_marathon_plan.py-533-        return out
utils/py/_marathon_plan.py-534-
utils/py/_marathon_plan.py:535:    def _parse_lanes_table(self, raw):
utils/py/_marathon_plan.py-536-        lines = re.split(r"\r?\n", raw)
utils/py/_marathon_plan.py-537-        h = -1
--
utils/py/_marathon_plan.py-565-            return -1
utils/py/_marathon_plan.py-566-
utils/py/_marathon_plan.py:567:        lane_idx, pr_idx, rev_idx = col("Lane"), col("PR"), col("Reviewer")
utils/py/_marathon_plan.py-568-        rows = []
utils/py/_marathon_plan.py-569-        while i < len(lines) and re.match(r"^\s*\|", lines[i]):
--
utils/py/_marathon_plan.py-573-                return cs[idx] if 0 <= idx < len(cs) else ""
utils/py/_marathon_plan.py-574-            rows.append({
utils/py/_marathon_plan.py:575:                "lane": at(cells, lane_idx) if lane_idx >= 0 else (cells[0] if cells else ""),
utils/py/_marathon_plan.py-576-                "pr": at(cells, pr_idx) if pr_idx >= 0 else "",
utils/py/_marathon_plan.py-577-                "reviewer": at(cells, rev_idx) if rev_idx >= 0 else "",
--
utils/py/_marathon_plan.py-637-        if contract and isinstance(contract.get("artifacts"), list):
utils/py/_marathon_plan.py-638-            arts = contract["artifacts"]
utils/py/_marathon_plan.py:639:            orch_only = (contract.get("lanes") or {}).get("orchestrator_only") or []
utils/py/_marathon_plan.py-640-            for zone in self.ZONES["zones"]:
utils/py/_marathon_plan.py-641-                if not zone["escalateOrchestratorOnly"]:
--
utils/py/_marathon_plan.py-739-    # ── main compute ────────────────────────────────────────────────────────────
utils/py/_marathon_plan.py-740-    def run(self, render_out):
utils/py/_marathon_plan.py:741:        """Parse → resolve → score → wave-pack → render. Prints the report to stdout,
utils/py/_marathon_plan.py-742-        writes the rendered doc to ``render_out``, returns the exit code."""
utils/py/_marathon_plan.py-743-        raw = self._read_file_safe(self.ROADMAP)
--
utils/py/_marathon_plan.py-772-                "suggestedBranch": suggested_branch,
utils/py/_marathon_plan.py-773-                "flags": [], "signals": [], "state": None, "score": None,
utils/py/_marathon_plan.py:774:                "wave": None, "ghState": None,
utils/py/_marathon_plan.py-775-            })
utils/py/_marathon_plan.py-776-
--
utils/py/_marathon_plan.py-821-                        self._flag("warn", "already-landed", r,
utils/py/_marathon_plan.py-822-                                   "all fix_probes report 'landed' — the fix is already present",
utils/py/_marathon_plan.py:823:                                   "verify-and-close, not a build lane")
utils/py/_marathon_plan.py-824-
utils/py/_marathon_plan.py-825-            if r["state"] is None:
--
utils/py/_marathon_plan.py-905-                    self._flag("warn", "already-landed", r,
utils/py/_marathon_plan.py-906-                               "swarm-preflight --dry-run → stale (exit 4)",
utils/py/_marathon_plan.py:907:                               "verify-and-close, not a build lane")
utils/py/_marathon_plan.py-908-                elif code == 5:
utils/py/_marathon_plan.py-909-                    r["state"] = "not-ready"
--
utils/py/_marathon_plan.py-942-                    dep_changed = True
utils/py/_marathon_plan.py-943-                    self._flag("info", "blocked-dep", r,
utils/py/_marathon_plan.py:944:                               "depends on a held/unbuildable item (%s) — excluded from active waves until the dependency is sequenceable"
utils/py/_marathon_plan.py-945-                               % ", ".join("#" + str(d) for d in blocked_by),
utils/py/_marathon_plan.py-946-                               "rate/unblock the dependency first")
--
utils/py/_marathon_plan.py-965-            r["score"] = score_of(r)
utils/py/_marathon_plan.py-966-
utils/py/_marathon_plan.py:967:        # ── wave packing ────────────────────────────────────────────────────────
utils/py/_marathon_plan.py-968-        def active_cmp(a, b):
utils/py/_marathon_plan.py-969-            # JS: `if (a.score !== b.score) return a.score - b.score;` — null coerces to 0 in the
utils/py/_marathon_plan.py:970:            # subtraction, so a ready-but-unrated lane (score None) sorts as 0. Mirror that exactly.
utils/py/_marathon_plan.py-971-            sa, sb = a["score"], b["score"]
utils/py/_marathon_plan.py-972-            if sa != sb:
--
utils/py/_marathon_plan.py-992-                        key=functools.cmp_to_key(active_cmp))
utils/py/_marathon_plan.py-993-
utils/py/_marathon_plan.py:994:        waves = []
utils/py/_marathon_plan.py-995-        placed_issue = {}
utils/py/_marathon_plan.py-996-        pending = active[:]
--
utils/py/_marathon_plan.py-998-        while pending and guard < 100:
utils/py/_marathon_plan.py-999-            guard += 1
utils/py/_marathon_plan.py:1000:            wave = []
utils/py/_marathon_plan.py:1001:            wave_writeset = set()
utils/py/_marathon_plan.py:1002:            wave_zone_counts = {}
utils/py/_marathon_plan.py-1003-            deferred = []
utils/py/_marathon_plan.py-1004-            for r in pending:
--
utils/py/_marathon_plan.py-1011-                        dep_unmet = True
utils/py/_marathon_plan.py-1012-                        break
utils/py/_marathon_plan.py:1013:                collides = any(p in wave_writeset for p in r["writeset"])
utils/py/_marathon_plan.py-1014-                cap = r["zoneRule"]["maxPerWave"] if (r["zoneRule"] and isinstance(r["zoneRule"]["maxPerWave"], int)) else None
utils/py/_marathon_plan.py:1015:                zone_cap_clash = cap is not None and wave_zone_counts.get(r["zone"], 0) >= cap
utils/py/_marathon_plan.py-1016-                inferred_zone_clash = bool(r["zoneRule"] and r["zoneRule"]["conservativeWhenInferred"]
utils/py/_marathon_plan.py:1017:                                           and r["zoneInferred"] and any(w["zone"] == r["zone"] for w in wave))
utils/py/_marathon_plan.py-1018-                if dep_unmet or collides or zone_cap_clash or inferred_zone_clash:
utils/py/_marathon_plan.py-1019-                    deferred.append(r)
utils/py/_marathon_plan.py-1020-                    continue
utils/py/_marathon_plan.py:1021:                wave.append(r)
utils/py/_marathon_plan.py-1022-                for p in r["writeset"]:
utils/py/_marathon_plan.py:1023:                    wave_writeset.add(p)
utils/py/_marathon_plan.py:1024:                wave_zone_counts[r["zone"]] = wave_zone_counts.get(r["zone"], 0) + 1
utils/py/_marathon_plan.py:1025:            if len(wave) == 0:
utils/py/_marathon_plan.py:1026:                waves.append(deferred)
utils/py/_marathon_plan.py-1027-                for r in deferred:
utils/py/_marathon_plan.py-1028-                    if r["gh"] is not None:
utils/py/_marathon_plan.py:1029:                        placed_issue[r["gh"]] = len(waves) - 1
utils/py/_marathon_plan.py-1030-                break
utils/py/_marathon_plan.py:1031:            waves.append(wave)
utils/py/_marathon_plan.py:1032:            for r in wave:
utils/py/_marathon_plan.py-1033-                if r["gh"] is not None:
utils/py/_marathon_plan.py:1034:                    placed_issue[r["gh"]] = len(waves) - 1
utils/py/_marathon_plan.py-1035-            pending = deferred
utils/py/_marathon_plan.py:1036:        for i, w in enumerate(waves):
utils/py/_marathon_plan.py-1037-            for r in w:
utils/py/_marathon_plan.py:1038:                r["wave"] = i + 1
utils/py/_marathon_plan.py-1039-
utils/py/_marathon_plan.py-1040-        # GH-5 contract seams
utils/py/_marathon_plan.py-1041-        contract_seams = []
utils/py/_marathon_plan.py:1042:        for w in waves:
utils/py/_marathon_plan.py-1043-            for i in range(len(w)):
utils/py/_marathon_plan.py-1044-                for j in range(i + 1, len(w)):
--
utils/py/_marathon_plan.py-1048-                    spine = self._shared_spine(a["writeset"], b["writeset"])
utils/py/_marathon_plan.py-1049-                    if spine:
utils/py/_marathon_plan.py:1050:                        contract_seams.append({"wave": a["wave"], "a": a, "b": b, "spine": spine})
utils/py/_marathon_plan.py:1051:                        self._flag("warn", "coupled-lanes", a,
utils/py/_marathon_plan.py:1052:                                   "same-wave lane shares the `%s/` spine with %s — write-disjoint but likely a shared contract seam"
utils/py/_marathon_plan.py-1053-                                   % (spine, ("#" + str(b["gh"])) if b["gh"] else b["slug"]),
utils/py/_marathon_plan.py:1054:                                   "pin a CONTRACT.md for the %s/ interface and point both lane prompts at it before launching" % spine)
utils/py/_marathon_plan.py-1055-
utils/py/_marathon_plan.py-1056-        # ── exit code ───────────────────────────────────────────────────────────
--
utils/py/_marathon_plan.py-1075-            W["eff"], W["cx"], risk_w, "(−)" if risk_sign < 0 else "", W["dep"], W["zone"])
utils/py/_marathon_plan.py-1076-
utils/py/_marathon_plan.py:1077:        report = self._render_report(deduped, active, waves, held, has_drift,
utils/py/_marathon_plan.py-1078-                                     exit_code, counts, weight_str)
utils/py/_marathon_plan.py-1079-        # Print report to stdout exactly as the Bash engine did (no trailing extra newline).
utils/py/_marathon_plan.py-1080-        sys.stdout.write(report)
utils/py/_marathon_plan.py-1081-
utils/py/_marathon_plan.py:1082:        rendered = self._render_queue_doc(deduped, active, waves, held, has_drift,
utils/py/_marathon_plan.py-1083-                                          contract_seams, weight_str)
utils/py/_marathon_plan.py-1084-        with open(render_out, "w", encoding="utf-8") as f:
--
utils/py/_marathon_plan.py-1110-
utils/py/_marathon_plan.py-1111-    # ── report rendering ────────────────────────────────────────────────────────
utils/py/_marathon_plan.py:1112:    def _render_report(self, deduped, active, waves, held, has_drift, exit_code, counts, weight_str):
utils/py/_marathon_plan.py-1113-        if self.FORMAT == "json":
utils/py/_marathon_plan.py-1114-            lines = []
--
utils/py/_marathon_plan.py-1120-            summary = {"timestamp": self.NOW, "severity": "warn" if exit_code else "info",
utils/py/_marathon_plan.py-1121-                       "check": "marathon-plan/summary", "file": "",
utils/py/_marathon_plan.py:1122:                       "message": "items=%d active=%d waves=%d drift=%s held=%d gh=%s"
utils/py/_marathon_plan.py:1123:                       % (len(deduped), len(active), len(waves),
utils/py/_marathon_plan.py-1124-                          "true" if has_drift else "false", len(held), self.GH_MODE),
utils/py/_marathon_plan.py-1125-                       "action": "summary"}
--
utils/py/_marathon_plan.py-1132-        out.append("  ledger items : %d  (queue %d · in-progress %d)"
utils/py/_marathon_plan.py-1133-                   % (len(deduped), counts["queue"], counts["inprog"]))
utils/py/_marathon_plan.py:1134:        out.append("  active lanes : %d across %d wave(s)   held: %d%s"
utils/py/_marathon_plan.py:1135:                   % (len(active), len(waves), len(held),
utils/py/_marathon_plan.py-1136-                      ("   gh-unverified: %d" % self.gh_unverified) if self.gh_unverified else ""))
utils/py/_marathon_plan.py-1137-        if self.GH_MODE == "off":
--
utils/py/_marathon_plan.py-1160-            out.append("        → %s" % f["action"])
utils/py/_marathon_plan.py-1161-        out.append("")
utils/py/_marathon_plan.py:1162:        out.append("SUMMARY [marathon-plan] items=%d active=%d waves=%d drift=%s held=%d (exit %d)"
utils/py/_marathon_plan.py:1163:                   % (len(deduped), len(active), len(waves),
utils/py/_marathon_plan.py-1164-                      "true" if has_drift else "false", len(held), exit_code))
utils/py/_marathon_plan.py-1165-        return "\n".join(out) + "\n"
utils/py/_marathon_plan.py-1166-
utils/py/_marathon_plan.py-1167-    # ── marathon-plan doc rendering ─────────────────────────────────────────────
utils/py/_marathon_plan.py:1168:    def _render_queue_doc(self, deduped, active, waves, held, has_drift, contract_seams, weight_str):
utils/py/_marathon_plan.py-1169-        zone_rows = list(self.ZONES["zones"]) + [self.ZONES["defaultZone"]]
utils/py/_marathon_plan.py-1170-        capped = [z for z in zone_rows if isinstance(z["maxPerWave"], int)]
utils/py/_marathon_plan.py:1171:        cap_summary = ", ".join("%s≤%d/wave" % (z["name"], z["maxPerWave"]) for z in capped) if capped else "none"
utils/py/_marathon_plan.py-1172-        o = []
utils/py/_marathon_plan.py-1173-        o.append("---")
--
utils/py/_marathon_plan.py-1185-        o.append("  A sequenced concurrency plan derived from ROADMAP.md: ranks surviving work by PDDA")
utils/py/_marathon_plan.py-1186-        o.append("  complexity/risk/effort, validates each item is still real, and batches collision-safe")
utils/py/_marathon_plan.py:1187:        o.append("  lanes into waves. Generated — edit the ledger, not this file.")
utils/py/_marathon_plan.py-1188-        o.append("---")
utils/py/_marathon_plan.py-1189-        o.append("")
--
utils/py/_marathon_plan.py-1201-        o.append("| What was just completed | What's next |")
utils/py/_marathon_plan.py-1202-        o.append("|---|---|")
utils/py/_marathon_plan.py:1203:        first_wave = " ‖ ".join(("#" + str(r["gh"])) if r["gh"] else r["slug"] for r in waves[0]) if waves else "(none)"
utils/py/_marathon_plan.py:1204:        o.append("| Generated by `utils/marathon-plan.sh` on %s from the live ROADMAP ledger (%d items; %d active across %d wave(s); %d held). Drift present: %s. | **Wave 1:** %s. Fire each lane via `swarm-preflight → marathon-drive`, scoped by `ALLOW_PATHS`. Re-run this script when the ledger changes. |"
utils/py/_marathon_plan.py:1205:                 % (self.TODAY, len(deduped), len(active), len(waves), len(held),
utils/py/_marathon_plan.py:1206:                    "yes — see Held/Flagged" if has_drift else "no", first_wave))
utils/py/_marathon_plan.py-1207-        o.append("")
utils/py/_marathon_plan.py-1208-        o.append("## The one safety rule")
utils/py/_marathon_plan.py-1209-        o.append("")
utils/py/_marathon_plan.py:1210:        o.append("Two lanes are safe to run concurrently **iff their write-sets are disjoint** and their zone")
utils/py/_marathon_plan.py-1211-        o.append("caps are respected. Current caps: %s." % cap_summary)
utils/py/_marathon_plan.py-1212-        o.append("")
--
utils/py/_marathon_plan.py-1217-        for zone in zone_rows:
utils/py/_marathon_plan.py-1218-            items = [("#" + str(r["gh"])) if r["gh"] else r["slug"] for r in active if r["zone"] == zone["name"]]
utils/py/_marathon_plan.py:1219:            safe = "✅ one lane per file"
utils/py/_marathon_plan.py-1220-            if isinstance(zone["maxPerWave"], int):
utils/py/_marathon_plan.py:1221:                safe = "❌ serialize — one at a time" if zone["maxPerWave"] == 1 else "❌ cap %d per wave" % zone["maxPerWave"]
utils/py/_marathon_plan.py-1222-            elif zone["conservativeWhenInferred"]:
utils/py/_marathon_plan.py:1223:                safe = "✅ one lane per file (serialize when inferred)"
utils/py/_marathon_plan.py-1224-            o.append("| %s | %s | %s |" % (zone["name"], safe, ", ".join(items) if items else "—"))
utils/py/_marathon_plan.py-1225-        o.append("")
--
utils/py/_marathon_plan.py-1228-        o.append("Every input is shown so the ordering is verifiable by hand (lower score = earlier).")
utils/py/_marathon_plan.py-1229-        o.append("")
utils/py/_marathon_plan.py:1230:        o.append("| Item | cx | risk | eff | zone | deps | score | wave |")
utils/py/_marathon_plan.py-1231-        o.append("|---|---|---|---|---|---|---|---|")
utils/py/_marathon_plan.py-1232-        for r in active:
--
utils/py/_marathon_plan.py-1237-                        _rating_num(r["ratings"]["risk"]), _rating_num(r["ratings"]["effort"]),
utils/py/_marathon_plan.py-1238-                        r["zone"], "*" if r["zoneInferred"] else "", deps_cell,
utils/py/_marathon_plan.py:1239:                        _cell(r["score"]), _cell(r["wave"])))
utils/py/_marathon_plan.py-1240-        if not active:
utils/py/_marathon_plan.py-1241-            o.append("| (no active, ready, rated items) | — | — | — | — | — | — | — |")
--
utils/py/_marathon_plan.py-1243-        o.append("`*` = zone inferred from keywords (no preflight contract write-set to prove it).")
utils/py/_marathon_plan.py-1244-        o.append("")
utils/py/_marathon_plan.py:1245:        o.append("## Recommended waves")
utils/py/_marathon_plan.py-1246-        o.append("")
utils/py/_marathon_plan.py:1247:        if not waves:
utils/py/_marathon_plan.py:1248:            o.append("_No active lanes — every item is held or flagged (see below)._")
utils/py/_marathon_plan.py:1249:        for i, w in enumerate(waves):
utils/py/_marathon_plan.py:1250:            lanes = " ‖ ".join(("#" + str(r["gh"])) if r["gh"] else r["slug"] for r in w)
utils/py/_marathon_plan.py:1251:            o.append("**Wave %d:** %s" % (i + 1, lanes if lanes else "(empty)"))
utils/py/_marathon_plan.py-1252-            o.append("")
utils/py/_marathon_plan.py-1253-            for r in w:
--
utils/py/_marathon_plan.py-1259-        o.append("")
utils/py/_marathon_plan.py-1260-        if not contract_seams:
utils/py/_marathon_plan.py:1261:            o.append("_None — no two same-wave lanes share a directory spine (deeper than a top-level dir)._")
utils/py/_marathon_plan.py-1262-            o.append("")
utils/py/_marathon_plan.py-1263-        else:
utils/py/_marathon_plan.py:1264:            o.append("These same-wave lanes are **write-disjoint but share a directory spine**, so they likely share")
utils/py/_marathon_plan.py-1265-            o.append("an interface (a not-yet-built module/schema). xyz is not for tightly-coupled work: pin a short")
utils/py/_marathon_plan.py:1266:            o.append("`CONTRACT.md` for the seam and point **each** lane's prompt at it (code TO the contract, not to")
utils/py/_marathon_plan.py:1267:            o.append("the other lane's source), or the split can stall when the consumer waits on the producer's handoff.")
utils/py/_marathon_plan.py-1268-            o.append("")
utils/py/_marathon_plan.py-1269-            for s in contract_seams:
utils/py/_marathon_plan.py-1270-                an = ("#" + str(s["a"]["gh"])) if s["a"]["gh"] else s["a"]["slug"]
utils/py/_marathon_plan.py-1271-                bn = ("#" + str(s["b"]["gh"])) if s["b"]["gh"] else s["b"]["slug"]
utils/py/_marathon_plan.py:1272:                o.append("- **Wave %d:** %s ‖ %s share `%s/` → pin a contract for that seam." % (s["wave"], an, bn, s["spine"]))
utils/py/_marathon_plan.py-1273-            o.append("")
utils/py/_marathon_plan.py:1274:        o.append("## Held / flagged — excluded from active waves")
utils/py/_marathon_plan.py-1275-        o.append("")
utils/py/_marathon_plan.py-1276-        buckets = [
utils/py/_marathon_plan.py:1277:            ("✅ Likely done — verify-and-close, not a build lane", ["already-landed", "already-closed"]),
utils/py/_marathon_plan.py-1278-            ("\U0001F527 Reconcile — undocumented partial completion", ["partial"]),
utils/py/_marathon_plan.py-1279-            ("⏸️ Gated on operator GO", ["gated"]),
--
utils/py/_marathon_plan.py-1295-            o.append("")
utils/py/_marathon_plan.py-1296-
utils/py/_marathon_plan.py:1297:        # GH-86: native "Review lanes" overlay (folds the former _inject_review_lanes shim).
utils/py/_marathon_plan.py-1298-        review_rel = "PR-REVIEW-QUEUE-%s.md" % self.TODAY
utils/py/_marathon_plan.py-1299-        review_raw = self._read_file_safe(os.path.join(self.QUEUE_DIR, review_rel))
utils/py/_marathon_plan.py-1300-        if review_raw is not None:
utils/py/_marathon_plan.py:1301:            review_lanes = self._parse_lanes_table(review_raw)
utils/py/_marathon_plan.py:1302:            o.append("## Review lanes (manual overlay — run via relay-xyz)")
utils/py/_marathon_plan.py-1303-            o.append("")
utils/py/_marathon_plan.py-1304-            o.append("A separate manual overlay — [%s](%s) — is not derived from" % (review_rel, review_rel))
utils/py/_marathon_plan.py:1305:            o.append("ROADMAP.md and does not appear in the waves above (a review lane evaluates an existing PR")
utils/py/_marathon_plan.py-1306-            o.append("diff; it doesn't remediate a ledger item). Fire each via `relay-xyz`, per the overlay doc.")
utils/py/_marathon_plan.py-1307-            o.append("")
utils/py/_marathon_plan.py:1308:            if review_lanes:
utils/py/_marathon_plan.py-1309-                o.append("| Lane | PR | Reviewer |")
utils/py/_marathon_plan.py-1310-                o.append("|---|---|---|")
utils/py/_marathon_plan.py:1311:                for l in review_lanes:
utils/py/_marathon_plan.py:1312:                    o.append("| %s | %s | %s |" % (_cell(l["lane"]), _cell(l["pr"]), _cell(l["reviewer"])))
utils/py/_marathon_plan.py-1313-            else:
utils/py/_marathon_plan.py-1314-                o.append("_%s exists but its `## Lanes` table could not be parsed._" % review_rel)
utils/py/_marathon_plan.py-1315-            o.append("")
utils/py/_marathon_plan.py-1316-
utils/py/_marathon_plan.py:1317:        o.append("## How to fire a lane")
utils/py/_marathon_plan.py-1318-        o.append("")
utils/py/_marathon_plan.py:1319:        o.append("Per lane, the existing pipeline applies — no new control plane:")
utils/py/_marathon_plan.py-1320-        o.append("")
utils/py/_marathon_plan.py-1321-        o.append("```")
utils/py/_marathon_plan.py-1322-        o.append("%s --project-doc <PROJECT/**/doc.md>   # or --gh-issue N" % self.SP_CMD)
utils/py/_marathon_plan.py:1323:        o.append("   → ready packet (candidate/freshness/fix-still-required + lane assignment)")
utils/py/_marathon_plan.py-1324-        o.append("%s ...   # build→gate→review, contained" % self.MD_CMD)
utils/py/_marathon_plan.py-1325-        o.append("```")
utils/py/_marathon_plan.py-1326-        o.append("")
utils/py/_marathon_plan.py:1327:        o.append("- **Lane scoping:** give each lane an `ALLOW_PATHS` matching only its zone above.")
utils/py/_marathon_plan.py:1328:        o.append("- If the lane's allowlist includes filesystem-touching `test/*.sh`, treat those tests as read-only specs in-turn; the outer harness gate verifies them after the turn, outside the isolated worktree.")
utils/py/_marathon_plan.py-1329-        o.append("")
utils/py/_marathon_plan.py-1330-        o.append("---")
--
skills/relay-xyz/SKILL.md-8-  end-to-end", "drive a relay to completion headless", "run the relay harness",
skills/relay-xyz/SKILL.md-9-  or set up the all-Claude hands-free poll loop — and the working tree is a
skills/relay-xyz/SKILL.md:10:  clone of the xyz-3-agents-swarm repo (it ships relay-automation/). /relay
skills/relay-xyz/SKILL.md-11-  scaffolds the thread and owns the turn protocol; relay-xyz is the repo-specific
skills/relay-xyz/SKILL.md-12-  layer that runs the real scripts. NOT for scaffolding a thread from scratch
--
skills/relay-xyz/SKILL.md-45-  vendored `.xyz/`).
skills/relay-xyz/SKILL.md-46-- You have a relay thread (or are about to scaffold one with `/relay`) **and** the working tree is a
skills/relay-xyz/SKILL.md:47:  clone of this repo.
skills/relay-xyz/SKILL.md-48-
skills/relay-xyz/SKILL.md-49-**Not** for: scaffolding a brand-new thread from scratch (that's `/relay`), repos that don't ship
--
skills/relay-xyz/SKILL.md-51-manual mode).
skills/relay-xyz/SKILL.md-52-
skills/relay-xyz/SKILL.md:53:## First-time setup on a new clone or machine (make the skill discoverable)
skills/relay-xyz/SKILL.md-54-
skills/relay-xyz/SKILL.md-55-This repo keeps its skills in top-level `skills/`, which Claude Code does **not** scan. A session
skills/relay-xyz/SKILL.md:56:finds `relay-xyz` only if it's symlinked into `~/.claude/skills/`. A fresh clone or second machine has
skills/relay-xyz/SKILL.md-57-no such symlink, so the skill is invisible in **every** session there — the "other VS Code sessions
skills/relay-xyz/SKILL.md:58:can't find the relay-xyz files" failure. Fix it **once per clone** (idempotent, self-locating, no

2026-08-17T19:26:45.928663Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 96 column 5
exec
/bin/zsh -lc "nl -ba relay-automation/marathon.sh | sed -n '1,50p'
nl -ba relay-automation/marathon-drive.sh | sed -n '1,32p'
nl -ba utils/py/_marathon_plan.py | sed -n '1180,1215p'
nl -ba README.md | sed -n '95,110p;430,450p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	#
     4	# marathon.sh — Phase 4 (M5): multi-phase orchestrator. Reads MARATHON.yaml, resolves depends_on
     5	# order, and runs each phase through marathon-drive.sh (the unmodified single-phase loop). Advances
     6	# on phase approval; HALTS on the first phase failure (relay no-progress / cap / gate / containment),
     7	# leaving that phase's ESCALATION.md (written by marathon-drive) and NOT starting later phases.
     8	# Emits marathon.complete only when every phase is approved.
     9	#
    10	# Per-phase round cap = 2 * max_review_rounds + 1 (turns ≠ rounds; the off-by-one kills phases early).
    11	# Cross-phase context injection (M6) and MARATHON-STATE.md projection (M7) are deliberately deferred —
    12	# the boundary events already land in .tick/events/ (phase.start/approved/escalated, marathon.complete).
    13	#
    14	# Usage:
    15	#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder codex] [--phases-dir DIR]
    16	#                                [--pre-advance-cmd CMD] [--dry-run] [--retry PHASE-ID]
    17	#
    18	# GH-212: default builder is `codex` — no per-call API charge (bills via the Codex/ChatGPT
    19	# subscription; agy is the other cost-blind option). `--builder claude` spawns a headless Claude
    20	# Code CLI subprocess instead: a SEPARATE, PER-CALL API-BILLED turn-taker, distinct from an
    21	# interactive session. Use it only as an explicit, cost-acknowledged choice.
    22	#
    23	# GH-212: a plan's `--plan` YAML (+ its phase briefs) must resolve under PROJECT/2-WORKING/ in the
    24	# target repo — not a standalone top-level folder (e.g. marathon-plans/<slug>/) an agent might
    25	# pattern-match from a prior repo. Exempt: paths under this harness's own home (MARATHON_HOME —
    26	# covers shipped examples like MARATHON.example.yaml). Override: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
    27	#
    28	# GH-116: --retry <phase-id> recovers a phase whose relay task was left open/never-claimed
    29	# (permanently spent, per this repo's claim-then-abandon constraint) WITHOUT manually renaming the
    30	# phase id in MARATHON.yaml. It overrides just that one phase's --relay-task with the first unused
    31	# MARATHON-<ID>-TURN-<N> suffix (N starts at 2, checked via `tick info`) — every other phase derives
    32	# its task name exactly as before. marathon-drive.sh already supports --relay-task natively; this is
    33	# purely a marathon.sh-side task-name override, no change to marathon-drive.sh itself.
    34	#
    35	# The MARATHON.yaml phase fields drive each marathon-drive call: id→--phase-id, reviewer→--reviewer,
    36	# brief→--phase-brief (required to run), artifact→--artifact, turn_timeout_s→RELAY_TURN_TIMEOUT_S,
    37	# max_review_rounds→--round-cap.
    38	#
    39	# Environment overrides (for tests):
    40	#   MARATHON_HOME       — harness home (default: parent of this script's dir)
    41	#   MARATHON_ROOT       — target repo root (default: `git -C "$PWD" rev-parse --show-toplevel`,
    42	#                         falling back to MARATHON_HOME outside a git repo)
    43	#   MARATHON_DRIVE      — marathon-drive.sh path (default: <harness-home>/relay-automation/marathon-drive.sh)
    44	#   MARATHON_YAML_BIN   — bin/marathon-yaml path (default: <harness-home>/bin/marathon-yaml)
    45	#   TICK_BIN            — tick binary (default: <harness-home>/bin/tick)
    46	#   MARATHON_CLOSEOUT_BIN — marathon-closeout.sh path (default: <harness-home>/relay-automation/marathon-closeout.sh)
    47	#   MARATHON_ALLOW_PLAN_OUTSIDE_WORKING — 1 permits a --plan outside PROJECT/2-WORKING/ (GH-212)
    48	# Real runs also inherit the turn-taker env (CLAUDE_BIN, *_TURN_ROOT, …), passed straight through.
    49	#
    50	# Exit: 0 all phases approved · N the failing phase's marathon-drive exit code · 2 usage/parse error.
     1	#!/usr/bin/env bash
     2	# FROZEN (GH-308): Python is authoritative — do not make behavior changes here.
     3	# Historical Bash fallback only; update utils/py/marathon_drive.py instead. See issue #308.
     4	set -euo pipefail
     5	
     6	# GH-112 opt-in Python mode: XYZ_PYTHON=1 reroutes this entry point to the Python port in
     7	# utils/py/ (same CLI contract + exit codes). Default (unset/0) runs the canonical Bash
     8	# implementation below — Bash stays the supported default until the port is promoted.
     9	if [[ "${XYZ_PYTHON-1}" == "1" ]]; then
    10	  # UPGRADE.md §4 Phase-2 hardening (GH-255): (2a) `-` not `:-` so an explicit empty XYZ_PYTHON reads
    11	  # as not-1 → Bash (load-bearing once the default flips to 1); (2b) require python3 >=3.8 and fall
    12	  # back to Bash with a warning if it's missing/too-old, so a bad interpreter degrades, not bricks.
    13	  if command -v python3 >/dev/null 2>&1 \
    14	     && python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null; then
    15	    _xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    16	    export XYZ_ROOT="$_xyz_root"
    17	    export PYTHONPATH="$_xyz_root/utils/py${PYTHONPATH:+:$PYTHONPATH}"
    18	    exec python3 "$_xyz_root/utils/py/marathon_drive.py" "$@"
    19	  else
    20	    echo "xyz: XYZ_PYTHON=1 but python3 missing or < 3.8 — falling back to Bash" >&2
    21	  fi
    22	fi
    23	#
    24	# marathon-drive.sh — Phase 3: single-phase headless relay loop.
    25	#
    26	# Renders marathon-system/p1/RELAY.md from the phase brief, seeds the tick token (handoff → builder),
    27	# calls relay-drive.sh unmodified, runs the pre-advance gate, emits phase events, and saves
    28	# the transcript. Does NOT reimplement any loop logic — relay-drive.sh IS the loop.
    29	#
    30	# Usage:
    31	#   relay-automation/marathon-drive.sh \
    32	#     --phase-brief <FILE>       phase brief (markdown; baked into the relay template)
  1180	        o.append("doc_type: project")
  1181	        o.append("source: ../../ROADMAP.md (open ledger entries)")
  1182	        o.append("generated_by: %s" % self.MP_CMD)
  1183	        o.append("roadmap_exempt: true")
  1184	        o.append("goal: >")
  1185	        o.append("  A sequenced concurrency plan derived from ROADMAP.md: ranks surviving work by PDDA")
  1186	        o.append("  complexity/risk/effort, validates each item is still real, and batches collision-safe")
  1187	        o.append("  lanes into waves. Generated — edit the ledger, not this file.")
  1188	        o.append("---")
  1189	        o.append("")
  1190	        o.append("<!-- GENERATED by utils/marathon-plan.sh from ROADMAP.md — re-run to refresh; edit the ledger, not this file. -->")
  1191	        o.append("")
  1192	        o.append("# Marathon Plan %s — pre-pre-flight sequenced queue" % self.TODAY)
  1193	        o.append("")
  1194	        o.append("> Derived from [ROADMAP.md](../../ROADMAP.md) · policy `%s` · weights {%s} · gh=%s."
  1195	                 % (self.POLICY, weight_str, self.GH_MODE))
  1196	        o.append("> The roadmap says **what/why**; this says **what is still real and in what order**. Execution")
  1197	        o.append("> detail still lives in each `PROJECT/**` doc — this is a scheduling overlay.")
  1198	        o.append("")
  1199	        o.append("## Status")
  1200	        o.append("")
  1201	        o.append("| What was just completed | What's next |")
  1202	        o.append("|---|---|")
  1203	        first_wave = " ‖ ".join(("#" + str(r["gh"])) if r["gh"] else r["slug"] for r in waves[0]) if waves else "(none)"
  1204	        o.append("| Generated by `utils/marathon-plan.sh` on %s from the live ROADMAP ledger (%d items; %d active across %d wave(s); %d held). Drift present: %s. | **Wave 1:** %s. Fire each lane via `swarm-preflight → marathon-drive`, scoped by `ALLOW_PATHS`. Re-run this script when the ledger changes. |"
  1205	                 % (self.TODAY, len(deduped), len(active), len(waves), len(held),
  1206	                    "yes — see Held/Flagged" if has_drift else "no", first_wave))
  1207	        o.append("")
  1208	        o.append("## The one safety rule")
  1209	        o.append("")
  1210	        o.append("Two lanes are safe to run concurrently **iff their write-sets are disjoint** and their zone")
  1211	        o.append("caps are respected. Current caps: %s." % cap_summary)
  1212	        o.append("")
  1213	        o.append("## Collision map")
  1214	        o.append("")
  1215	        o.append("| Zone | Parallel-safe? | Active items here |")
    95	1. **Consult** — a one-shot, parallel second opinion. The same question fans out to Codex and agy
    96	   at the same time, each answers independently in an isolated copy of the repo, and the answers
    97	   are reconciled into one. Nothing is modified; it's purely advisory. Lowest risk, fastest payoff.
    98	2. **Relay** — an iterative, turn-based loop between two agents on one shared file: a **Producer**
    99	   builds an artifact, a **Reviewer** critiques and proposes fixes, and they hand off back and
   100	   forth until the artifact converges. This replaces you copy-pasting output between two agent
   101	   windows. Changes are confined to the relay thread file and the artifact under review.
   102	3. **Swarm** — two or more agents working **concurrently** on the same repo, each claiming a
   103	   non-overlapping, path-scoped lane (via the `tick` kernel) so they never collide. Good for
   104	   parallel builds or parallel codebase recon. This is where PDDA's doc structure starts to matter,
   105	   because lanes are carved from well-defined task docs.
   106	4. **Marathon** — the full automation payoff: a queue of pre-flighted tasks (built up during the
   107	   day) fired as one long autonomous run, typically end-of-day or overnight. Marathon **requires**
   108	   PDDA, because the preflight scripts rely on PDDA's opinionated docs/roadmap structure to verify
   109	   every queued task is well-specified before anything runs unattended.
   110	
   430	  (GH issue + capture doc + ROADMAP park), without touching the repo you're standing in.
   431	- `skills/agent2agent/` — compact six-digit rendezvous for serialized discussions among two or more
   432	  live sessions; reuses dated relay files and supports Claude Code plus Codex skill installation.
   433	- `relay-system/` — relay transcripts, reviews, and dogfood runs.
   434	- `PROJECT/2-WORKING/` — active project docs and working plans.
   435	- `bin/tick`, `src/`, `test/` — the `tick` coordination kernel and its test suite.
   436	- `utils/swarm-preflight.sh` — marathon intake planner: turns a project doc or a GH-issue bundle into a marathon-ready run packet (freshness + fix-still-required checks, readiness gate, Codex/agy lane plan). Run `utils/swarm-preflight.sh --help`; see [GH-25-SWARM-PREFLIGHT-PLANNER.md](PROJECT/3-COMPLETED/GH-25-SWARM-PREFLIGHT-PLANNER.md).
   437	- `utils/marathon-plan.sh` — the marathon planner/ranker: scores the whole ROADMAP ledger into waves of disjoint, collision-safe write-sets, and with `--deep` delegates to `swarm-preflight.sh --dry-run` per item for an authoritative freshness verdict. Writes `PROJECT/2-WORKING/MARATHON-PLAN-<date>.md` — the "marathon file" the operator skills act on.
   438	- `utils/swe-diagram/` — dependency-free architecture/Git-history diagram generator; `layout: "git-lanes"` renders stacked branch lanes with commits left-to-right, driven by a local ref-reading generator that emits an auditable JSON spec plus self-contained HTML. See [GH-201](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/201).
   439	- `utils/git-bundle-snapshot.sh` + `relay-automation/hooks/gh177-sandbox-test-guard.sh` — the wipe-prevention layer: rotated `git bundle --all` backups on a daily cron, plus a PreToolUse hook that blocks running the test suite under a *sandboxed* Claude Code Bash call (the ignition for the GH-177 repo wipes). See [GH-233](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/233).
   440	- `install.sh` — materializes the `tick` runtime (`bin/tick` + `src/*.js`) into an external repo and records the install in a per-user, machine-local registry (`~/.config/xyz/registry.tsv`). See "Install into another repo" below.
   441	- `utils/hq/` — **HQ**, the multi-repo command center (`hq.sh` + `hq-lib.sh`); driven by the user-level `/hq` skill in `skills/hq/`. See [HQ — multi-repo command center](#hq--multi-repo-command-center) below.
   442	
   443	## What `tick` is
   444	
   445	`tick` coordinates agents through a shared local event log under `.tick/events/`.
   446	Claims are serialized by an `O_EXCL` lock, and projection folds events into
   447	`.tick/STATE.md`. Coordination is local-transport only: no per-event push/fetch,
   448	no remote dependency, one shared `.tick/` directory per active run.
   449	
   450	If you are here for the kernel rather than the relay layer, the implementation

2026-08-17T19:26:58.207529Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 96 column 5
exec
/bin/zsh -lc "nl -ba skills/xyz/SKILL.md | sed -n '2178,2205p'
nl -ba README.md | sed -n '360,414p'
nl -ba utils/py/_marathon_plan.py | sed -n '990,1040p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr
 succeeded in 0ms:
  2178	   (seeding→latest) window — recompute over **first `task.claimed` → last
  2179	   `task.done`**. (Read `.tick/events/*.jsonl`; or call `computeParallelism`
  2180	   with those two timestamps.) **Pass = ≥50%**, AND each agent ≥2 done.
  2181	3. **Serial double-claim check:** no agent held two overlapping-path claims at
  2182	   once (`take` prevents it; verify the log anyway).
  2183	4. **Cross-check:** confirm by `git diff` / passing tests that overlapping claim
  2184	   windows = overlapping REAL edits. The metric is necessary, not sufficient.
  2185	5. Record results + an honest **graduate / iterate / abandon** call.
  2186	
  2187	## 8. Success metric & honest caveats
  2188	
  2189	- **Pass:** work-bounded concurrent-claim ≥50%, both agents ≥2 done, zero parked
  2190	  suspects, zero serial double-claims, cross-check confirms real overlap.
  2191	- **50% is a stress bar, not a proof bar** — clearing it shows the protocol *can*
  2192	  sustain parallelism in this setup, not that it's production-ready.
  2193	- **Parked-claim is an OPERATIONAL CONTRACT, not inference.** It relies on agents
  2194	  calling `tick ping`. A missing heartbeat is indistinguishable from a parked
  2195	  claim → **fail/retry the run, never silently treat it as a pass.**
  2196	- **`take` atomicity is shared-lock/shared-tree specific** — do not generalize to
  2197	  separate clones or non-shared transports.
  2198	
  2199	## 9. Limits (carried from Runs 1–3)
  2200	
  2201	- Sustained parallelism needs **balanced lanes** (Run 3 missed 50%→hit 40% purely
  2202	  from imbalance: the fast agent idled once its lane drained; there is no
  2203	  work-stealing across lanes).
  2204	- Coarse, path-scoped lanes only — per-file drift within a lane is not detected.
  2205	- ≤2 agents validated; same-session, shared tree only.
   360	join is inexpressible: "p4 after p2 *and* p3" cannot be written. There is no parallel execution;
   361	`relay-automation/MARATHON.example.yaml` states that phases run strictly one at a time and that a
   362	disjoint write-set does not buy you parallelism. `depends_on` **validates** the order you authored
   363	rather than **deriving** one, which inverts the usual graph model. And a failure halts the chain —
   364	there is no conditional edge to a remediation node.
   365	
   366	So: a sequential chain of agent-driven build→review loops, with hard gates at every boundary. The
   367	scheduling a graph engine exists to automate is handed to the operator on purpose — see
   368	`GUIDING-PRINCIPLES.md` §8, and `utils/swarm-preflight.sh`, which is the *producer* of a run packet
   369	and never its executor.
   370	
   371	Parallelism does exist, but as **swarms**: separate agents in separate worktrees or clones on
   372	disjoint write-sets, coordinated by `tick` locks. That is arranged by the operator, not scheduled
   373	from a dependency graph.
   374	
   375	### Do phases run in parallel? What does `depends_on` actually do?
   376	
   377	**Inside a single marathon plan: No.** Phases run **strictly one at a time**, in the order they appear in the plan.
   378	A phase *without* `depends_on` is not "unordered" or "parallel-safe" — it simply runs when its turn
   379	comes. `depends_on` constrains and validates that order; it does not create a concurrent execution graph.
   380	
   381	It also takes exactly one phase id, unquoted (`depends_on: p3`). The list form `depends_on: [p3]`
   382	parses as the literal string and aborts the plan with an unknown-phase error that points at your
   383	phase ids rather than at the field's shape. Chain them (`p3 → p4 → p5`) to express a longer order.
   384	
   385	Analysing your phases for a disjoint write-set is still worth doing — it is how you learn which
   386	phases genuinely need `depends_on` — but it will not make them concurrent within the same working tree.
   387	
   388	**Where parallelism DOES exist is at the Swarm / Lane level.** Independent tasks and issues (Lanes)
   389	can be dispatched concurrently across **separate standalone clones or isolated worktrees** on disjoint write-sets.
   390	For instance, the `/10days` skill fans out parallel subagents to *triage and inspect* issues simultaneously,
   391	while the execution of any given marathon runner stays strictly sequential across its internal phases to prevent
   392	workspace clobbering and driver-lock contention.
   393	
   394	Always `--dry-run` a new plan first. It parses every field and prints the real execution order at
   395	zero cost, which is the cheapest way to catch both a mis-shaped field and a wrong mental model.
   396	
   397	## Glossary & Execution Model
   398	
   399	To avoid ambiguity across planning, kernel locks, and multi-agent workflows, terminology in this repository adheres to the following definitions:
   400	
   401	| Term | Scope | Definition | Execution & Concurrency Model |
   402	|:---|:---:|:---|:---:|
   403	| **Turn** | Agent | A single headless invocation of an AI builder (e.g. Codex, Qwen) or reviewer (Claude). | Atomic execution step |
   404	| **Relay** | Product | An automated, iterative handoff loop between builder and reviewer until a verified pass or halt condition. | Sequential loop |
   405	| **Phase (Plan)** | Marathon | A single discrete step/milestone within a `MARATHON.yaml` plan (e.g. `p1`, `p2`). | **Strictly Sequential** (1-at-a-time per runner) |
   406	| **Phase (Doc)** | PDDA | A numbered stage of implementation defined in a `PROJECT/2-WORKING/` design specification (Phase 0, Phase 1). | Documentation / roadmap staging |
   407	| **Lane** | Workflow | An autonomous execution pipeline dedicated to solving a single GitHub issue or task. | Single track |
   408	| **Wave** | Planner | A batch of independent lanes identified by disjoint write-sets (via `marathon-plan.sh`) that can be safely scheduled together. | Batch scheduling |
   409	| **Marathon** | Automation | A multi-phase runner (`marathon-drive.sh`) that executes an ordered sequence of phases, gates, and git commits on a branch. | Serial orchestrator |
   410	| **Swarm** | Architecture | Multiple independent agents running concurrently across **separate clones or worktrees**, coordinated by `tick` locks. | **Parallel / Distributed** |
   411	| **`depends_on`** | Config | An authoring validation assertion in a marathon plan verifying prerequisite phase completion before starting the next. | Assertion gate (not parallel DAG) |
   412	| **`tick` Kernel** | Kernel | The local, serverless event-log engine managing collision-free task claims and path-scoped locks under `.tick/events/`. | ACID / Event-sourced |
   413	
   414	## Repo map
   990	
   991	        active = sorted([r for r in deduped if r["state"] == "ready"],
   992	                        key=functools.cmp_to_key(active_cmp))
   993	
   994	        waves = []
   995	        placed_issue = {}
   996	        pending = active[:]
   997	        guard = 0
   998	        while pending and guard < 100:
   999	            guard += 1
  1000	            wave = []
  1001	            wave_writeset = set()
  1002	            wave_zone_counts = {}
  1003	            deferred = []
  1004	            for r in pending:
  1005	                dep_unmet = False
  1006	                for d in r["deps"]:
  1007	                    dep = self._find_by_gh(deduped, d)
  1008	                    if not dep or dep["state"] in DEP_RESOLVED:
  1009	                        continue
  1010	                    if d not in placed_issue:
  1011	                        dep_unmet = True
  1012	                        break
  1013	                collides = any(p in wave_writeset for p in r["writeset"])
  1014	                cap = r["zoneRule"]["maxPerWave"] if (r["zoneRule"] and isinstance(r["zoneRule"]["maxPerWave"], int)) else None
  1015	                zone_cap_clash = cap is not None and wave_zone_counts.get(r["zone"], 0) >= cap
  1016	                inferred_zone_clash = bool(r["zoneRule"] and r["zoneRule"]["conservativeWhenInferred"]
  1017	                                           and r["zoneInferred"] and any(w["zone"] == r["zone"] for w in wave))
  1018	                if dep_unmet or collides or zone_cap_clash or inferred_zone_clash:
  1019	                    deferred.append(r)
  1020	                    continue
  1021	                wave.append(r)
  1022	                for p in r["writeset"]:
  1023	                    wave_writeset.add(p)
  1024	                wave_zone_counts[r["zone"]] = wave_zone_counts.get(r["zone"], 0) + 1
  1025	            if len(wave) == 0:
  1026	                waves.append(deferred)
  1027	                for r in deferred:
  1028	                    if r["gh"] is not None:
  1029	                        placed_issue[r["gh"]] = len(waves) - 1
  1030	                break
  1031	            waves.append(wave)
  1032	            for r in wave:
  1033	                if r["gh"] is not None:
  1034	                    placed_issue[r["gh"]] = len(waves) - 1
  1035	            pending = deferred
  1036	        for i, w in enumerate(waves):
  1037	            for r in w:
  1038	                r["wave"] = i + 1
  1039	
  1040	        # GH-5 contract seams

2026-08-17T19:27:15.526724Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 96 column 5
codex
## ANSWER

The sequential-phase explanation is strong, but the new table materially blurs execution isolation: linked worktrees are not independent concurrent marathon/relay lanes, and full clones do not share `tick`’s atomic coordination.

## FINDINGS

- [Blocker] The Q&A and Swarm row say concurrent lanes can use “separate … isolated worktrees” and are coordinated by `tick` locks ([README.md:388](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/README.md:388), [README.md:410](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/README.md:410)). For driven relays/marathons, linked worktrees share the parent clone’s driver lock and therefore serialize; two concurrent swarms require separate full clones ([skills/relay-xyz/SKILL.md:125](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/skills/relay-xyz/SKILL.md:125), [skills/relay-xyz/SKILL.md:146](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/skills/relay-xyz/SKILL.md:146)). Conversely, full clones have separate event logs, so `tick` atomicity must not be claimed across them ([skills/xyz/SKILL.md:2196](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/skills/xyz/SKILL.md:2196)). Explicitly distinguish manual shared-tree worktree swarms from concurrent automated runners in full clones.

- [Should] The Marathon row names the wrong executable: `marathon.sh` is the multi-phase orchestrator; `marathon-drive.sh` is the single-phase relay loop ([README.md:409](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/README.md:409), [relay-automation/marathon.sh:4](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/relay-automation/marathon.sh:4), [relay-automation/marathon-drive.sh:24](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/relay-automation/marathon-drive.sh:24)).

- [Should] “Plan” is overloaded precisely where the reader needs the distinction. Define both: a `MARATHON.yaml` execution plan contains serial phases; generated `MARATHON-PLAN-*.md` is a non-executing scheduling overlay that batches lanes into waves ([utils/marathon-plan.sh:57](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/utils/marathon-plan.sh:57), [utils/marathon-plan.sh:60](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/utils/marathon-plan.sh:60)). Add the hierarchy: `wave → lane → optional marathon execution plan → serial phase → relay → turn`.

- [Should] A Wave is not merely lanes with disjoint write-sets. The planner also separates unmet dependencies and enforces zone caps ([utils/py/_marathon_plan.py:1005](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/utils/py/_marathon_plan.py:1005)). Say it is a planner recommendation the operator fires, not a scheduler that executes automatically.

- [Nit] Replace “Atomic execution step” for Turn and “ACID” for `tick` ([README.md:403](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/README.md:403), [README.md:412](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/README.md:412)). They imply guarantees not defined here. “One bounded agent invocation” and “local append-only event log with lock-serialized claims” are sharper.

- [Pass] The Q&A correctly and unusually clearly states that phases are declaration-order serial, `depends_on` is scalar-only, and disjoint phase write-sets do not create intra-plan parallelism ([README.md:377](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/README.md:377)).

## RECOMMENDATION

Rewrite the table around the explicit hierarchy above, with separate rows for YAML execution plans, generated wave plans, linked worktrees, and full clones.
tokens used
96,255
## ANSWER

The sequential-phase explanation is strong, but the new table materially blurs execution isolation: linked worktrees are not independent concurrent marathon/relay lanes, and full clones do not share `tick`’s atomic coordination.

## FINDINGS

- [Blocker] The Q&A and Swarm row say concurrent lanes can use “separate … isolated worktrees” and are coordinated by `tick` locks ([README.md:388](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/README.md:388), [README.md:410](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/README.md:410)). For driven relays/marathons, linked worktrees share the parent clone’s driver lock and therefore serialize; two concurrent swarms require separate full clones ([skills/relay-xyz/SKILL.md:125](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/skills/relay-xyz/SKILL.md:125), [skills/relay-xyz/SKILL.md:146](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/skills/relay-xyz/SKILL.md:146)). Conversely, full clones have separate event logs, so `tick` atomicity must not be claimed across them ([skills/xyz/SKILL.md:2196](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/skills/xyz/SKILL.md:2196)). Explicitly distinguish manual shared-tree worktree swarms from concurrent automated runners in full clones.

- [Should] The Marathon row names the wrong executable: `marathon.sh` is the multi-phase orchestrator; `marathon-drive.sh` is the single-phase relay loop ([README.md:409](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/README.md:409), [relay-automation/marathon.sh:4](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/relay-automation/marathon.sh:4), [relay-automation/marathon-drive.sh:24](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/relay-automation/marathon-drive.sh:24)).

- [Should] “Plan” is overloaded precisely where the reader needs the distinction. Define both: a `MARATHON.yaml` execution plan contains serial phases; generated `MARATHON-PLAN-*.md` is a non-executing scheduling overlay that batches lanes into waves ([utils/marathon-plan.sh:57](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/utils/marathon-plan.sh:57), [utils/marathon-plan.sh:60](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/utils/marathon-plan.sh:60)). Add the hierarchy: `wave → lane → optional marathon execution plan → serial phase → relay → turn`.

- [Should] A Wave is not merely lanes with disjoint write-sets. The planner also separates unmet dependencies and enforces zone caps ([utils/py/_marathon_plan.py:1005](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/utils/py/_marathon_plan.py:1005)). Say it is a planner recommendation the operator fires, not a scheduler that executes automatically.

- [Nit] Replace “Atomic execution step” for Turn and “ACID” for `tick` ([README.md:403](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/README.md:403), [README.md:412](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/README.md:412)). They imply guarantees not defined here. “One bounded agent invocation” and “local append-only event log with lock-serialized claims” are sharper.

- [Pass] The Q&A correctly and unusually clearly states that phases are declaration-order serial, `depends_on` is scalar-only, and disjoint phase write-sets do not create intra-plan parallelism ([README.md:377](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-34223-cp1uuvbr/README.md:377)).

## RECOMMENDATION

Rewrite the table around the explicit hierarchy above, with separate rows for YAML execution plans, generated wave plans, linked worktrees, and full clones.
