**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.6-sol
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
2026-08-24T04:45:22.831448Z ERROR codex_models_manager::cache: failed to load models cache: missing field `base_instructions` at line 98 column 5
OpenAI Codex v0.144.6
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-17781-brvet5yb
model: gpt-5.6-sol
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 01a03216-6340-7ea0-aea5-0da2609146b2
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
Question: where should the marathon-cleanup SOP store "clone-teardown salvage" data, and why?

Context (XYZ-forge repo):
- Disposable marathon clones of this repo accumulate unique UNCOMMITTED per-clone state before deletion: GH-174 turn-telemetry (`harnesses.db` + `harnesses.sql` diffs), regenerated `HARNESS-MODELS-REGISTRY.generated.md` / `docs/blog-frontier-benchmarks.md`, and `.relay-scratch/` probe JSON.
- This data must survive clone deletion until an operator merges it into the canonical `harnesses.db` in the primary clone, then it is disposable.
- Today it was salvaged ad hoc to `~/marathon-clones/gh174-telemetry-salvage-2026-08-23/<clone-name>/` (outside any repo).

Candidate locations:
1. Outside the repo beside the clones (`~/marathon-clones/<salvage-dir>/`) — safe from all repo tooling, but undiscoverable; no session auto-loads it, easy to forget.
2. Inside the primary repo under `relay-system/` (committed thread storage) or a new top-level `marathon-system/` folder — discoverable and versionable, but: (a) GH-141 hazard — untracked/hand-added files in a clone while a driven turn is in flight can be swept into `.tick/orphan-backups/` or reverted; (b) dirties a working tree that may have pending PR decisions; (c) binary `harnesses.db` blobs in git history if committed.
3. `.tick/orphan-backups/` — existing backup convention, but gitignored, per-clone, and deleted with the clone: unsuitable for teardown salvage by construction (confirm or refute).
4. Anything better you can argue for (e.g. XDG data dir like `~/.local/share/xyz/salvage/`, or a gitignored-but-in-repo dir with a README pointer, or "don't salvage — merge before delete as an SOP gate").

What "good" looks like: one recommended location + rationale, an explicit statement on whether "merge-before-delete" should replace salvage entirely, and how discoverability is guaranteed (what pointer, where). Judge the GH-141 sweep hazard seriously: the repo's turn shims revert non-allowlisted new files in the real tree during driven turns.

hook: SessionStart
hook: SessionStart Completed
codex
I’m treating this as a read-only architecture/SOP judgment. I’ll use the consult guidance only to frame the independent advisory response, then inspect the repo’s canonical routing and the actual teardown/sweep behavior; the key bet is whether salvage is durable operational state rather than project source.
exec
/bin/zsh -lc "cat '/Users/noelsaw/Documents/GH Repos/XYZ-forge/skills/consult/SKILL.md' && cat WORKTREE-SAFETY.md && cat ROUTER.md && cat GUIDING-PRINCIPLES.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-17781-brvet5yb
 succeeded in 0ms:
---
name: consult
description: One-shot cross-model CONSULT — fan the same question out to Codex and agy in parallel (repo-isolated, advisory), then reconcile their answers into one. Use when the user wants a "second opinion", to "ask Codex and agy", a "panel" or "cross-model" check, or an independent gut-check on a decision/design/doc before committing — and does NOT need an iterative build/review loop. NOT a relay: a relay is an iterative 1:1 Producer↔Reviewer loop that converges an artifact; a consult is a parallel 1-shot 1:N second opinion, reconciled once. Depends on the codex + agy CLIs and the relay-automation shims; runs in any repo that ships them at the repo root OR in a vendored `.xyz/` install (the skill resolves either).
---

# Consult

**One question → N independent models in parallel → one reconciled answer.**

A consult asks Codex and agy the *same* question at the same time, isolated from your real tree, and then a
coordinator (Claude) reconciles their answers — surfacing where they **agree**, where they
**disagree**, and giving a single reconciled **call**. It is the fast "ask the other brains before I
commit" move: no copy-paste, no window-shuttling, one step.

## Consult vs. relay — pick the right tool

| | **consult** (this skill) | **relay** |
|---|---|---|
| shape | parallel fan-out, 1 question → N models | iterative loop, 2 agents |
| rounds | exactly **one** | many, until `Approved` |
| writes | **none** — advisory only | Producer edits the artifact |
| output | reconciled answer + divergences | a converged artifact |
| use for | a decision, a design gut-check, "is this doc sound?" | building/fixing an artifact under review |

If after a consult you decide the work needs iteration, *start a relay* — the consult is the cheap
first look, the relay is the build loop.

## When to use

- "Get a second opinion." "Ask Codex and agy." "What do the other models think?"
- "Panel review" / "cross-model check" / "sanity-check this before I commit."
- An independent gut-check on a plan, design, schema, or doc — where you want *divergent* reads, not
  a single model's confident answer.

Do **not** use it to build or fix an artifact iteratively — that's `relay`.

## How it works

`relay-automation/consult.sh` (path is relative to **this repo's root**, not your cwd) fans the question
out to both advisors **in parallel** and writes each transcript to a per-run dir
`relay-system/<today>/<label>-<HHMMSS>/`. The synthesis is **yours** — the script only gathers the raw
opinions.

**Locating the script — resolve it cwd-independently; never assume your cwd is the repo root.** A bare
`consult.sh` or `relay-automation/consult.sh` only resolves when you happen to be sitting at the root,
so invoke it through its repo-root anchor instead. Two homes are supported so consult works both in
the `xyz-3-agents-swarm` checkout **and** in any repo that has a vendored `.xyz/` install: the
top-level `relay-automation/` if present, otherwise the vendored `.xyz/relay-automation/`.

```
ROOT="$(git rev-parse --show-toplevel)"
SCRIPT="$ROOT/relay-automation/consult.sh"
[ -f "$SCRIPT" ] || SCRIPT="$ROOT/.xyz/relay-automation/consult.sh"
# CONSULT_ROOT MUST be the repo root: consult.sh otherwise infers its root as the script's parent-of-
# parent, which for the vendored copy is `.xyz/` (wrong). Setting it pins the consult to the real repo
# and its `relay-system/` output. Harmless (a no-op) for the top-level copy.
CONSULT_ROOT="$ROOT" "$SCRIPT" --prompt "…" --label …
```

`git rev-parse --show-toplevel` works from any subdirectory of the repo. If you are not inside a repo
that has consult (no top-level `relay-automation/` and no `.xyz/`), either `cd` into the
`xyz-3-agents-swarm` worktree, or vendor a `.xyz/` into the target repo first
(`relay-automation/xyz-vendor.sh <repo>`). (Do **not** go hunting the disk for `consult.sh`; the
anchor above always finds it.)

**Provable no-mutation boundary (not best-effort).** Advisors run with their working directory set to a
**throwaway git worktree** checked out from your *current* state — tracked WIP (via `git stash create`)
plus untracked-non-ignored files copied in — so they see your working state (minus `.gitignore`d
files), including a brand-new file under
review. Anything an advisor writes lands in that disposable worktree and is destroyed with it; your
real working tree is **never** the advisors' surface, so there is nothing to revert and ambient WIP
cannot be clobbered. (Codex additionally runs `-s read-only`.) This replaced an earlier best-effort
post-hoc revert that the skill's own first dogfood flagged as unsafe.

```
consult.sh --prompt-file Q.md            # question is the file's contents (may reference repo paths)
consult.sh --prompt "Is X sound?"        # inline question
  [--models codex,agy]                   # which advisors (default both)
  [--out DIR]                            # parent dir (default relay-system/<today>/)
  [--label SLUG]                         # run-subdir + transcript stem (default "consult")
```

Each run gets its own `<label>-<HHMMSS>/` subdir, so two consults the same day never overwrite each
other. Behavior is covered by `test/consult.sh` in `validate.sh` (WIP preservation, no advisor leak,
graceful degrade, non-git refusal).

Exit `0` = at least one advisor answered; `5` = all failed; `3` = not a git repo (isolation needs
one); `2` = usage. Per-model failures are reported, not fatal — if Codex's backend is down, Gemini's
answer still comes back (**graceful degrade**, and the degrade is stated, never silent).

## Steps (the coordinator's job)

1. **Frame one sharp question.** Put it in a prompt file when it references repo paths (the advisors
   read the files themselves). Be explicit about what "good" looks like, just like a relay's
   Definition of Done.
2. **Fan out:** run the script through its repo-root anchor (see "Locating the script" above — prefer
   `$ROOT/relay-automation/consult.sh`, fall back to `$ROOT/.xyz/relay-automation/consult.sh`, and
   always pass `CONSULT_ROOT="$ROOT"`) with the prompt + a `--label`. Both models run at once. Don't
   invoke a bare `consult.sh`; it only resolves at the repo root.
3. **Read both transcripts** in `relay-system/<today>/<label>-<HHMMSS>/<label>.codex.md` and `…agy.*`.
4. **Reconcile — this is the load-bearing step.** Produce a synthesis with four parts, in this order:
   - **TLDR** (new — one to two sentences, before anything else): the reconciled call and how confident
     it is, so the operator can stop reading right there if that's all they need. e.g. *"Both models
     agree the migration is safe — go ahead. Codex flagged one edge case worth a follow-up (see below)."*
   - **Disagree** (it's the whole point of asking two models): every point the two differ on, with your
     adjudication and *why*. Never in the TLDR — the TLDR previews the call, it doesn't bury the split.
   - **Agree:** what both independently converged on (higher confidence because it's cross-model).
   - **Sorted categories** (new — closes the synthesis, replaces a bare prose recommendation): bucket
     every point either advisor raised — agreements and adjudicated disagreements alike — into exactly
     one:
     - **Blocking** — a real risk either advisor surfaced; must address before proceeding.
     - **Worth doing, optional** — a real improvement; the operator's call.
     - **Skip / out of scope** — noted and dismissed, named so it doesn't resurface.
     Drop empty buckets. For a short, clean consult (both advisors agree, one or two minor notes),
     skip the buckets and give the recommendation as plain prose instead — don't force structure on a
     synthesis with nothing to sort.
5. **Hand the synthesis back** to the operator. If it reveals the work needs iteration, offer to
   start a `relay`.

## The one rule that makes a consult worth running

**Surface disagreement; never average it away.** The entire value of asking two models is the *delta*
between them — the place one caught what the other missed. A synthesis that smooths two answers into
one confident paragraph throws that away and is worse than asking one model, because it launders two
guesses into false consensus. Lead with the disagreements, adjudicate them explicitly, and if you
can't adjudicate one, say so and flag it for the human. (Same failure mode as a review that only
hunts overclaims and misses silent drops: the easy direction satisfices.)

## Honest caveats

- **Two models, not ground truth.** Cross-model agreement raises confidence; it does not prove
  correctness — both can share a blind spot or a wrong prior. Treat a unanimous answer as *strong
  signal*, not proof, especially when correctness rides on runtime behavior neither model ran.
- **Repo-isolated, not process-sandboxed.** Advisors run in a throwaway worktree and cannot reach
  your real tree, so a consult never changes your code even if an advisor ignores the "advisory only"
  instruction. Be precise about the boundary: this protects your *repository*, not the *host process*.
  Codex additionally runs `-s read-only`; agy runs with `--dangerously-skip-permissions` and is
  repo-isolated but not a sandboxed process (it can still reach the network / the host outside the
  worktree). For a hard process boundary, run consult inside your own sandbox. If a fix is needed,
  *you* (or a relay) apply it — the independent check stays independent.
- **The worktree shows tracked + untracked state, not ignored files.** `.gitignore`d local context is
  excluded from what advisors see; reference it inline in the question if it matters.
- **Cost capture is not available for agy.** agy has no JSON/token output, so an agy lane is cost-blind
  (a floor). Codex token parsing is also still deferred. Neither lane captures `tick cost` events in a consult.
- **Needs the shims present, but is not tied to one repo.** Unlike `relay` (model-agnostic, file-only),
  consult hard-depends on the `codex` + `agy` CLIs being installed and authed and on the
  `relay-automation` shims. Those shims can live at the repo root **or** in a vendored `.xyz/` install,
  so any repo carrying a `.xyz/` (see `relay-automation/xyz-vendor.sh`) can run consult standalone.

## Gotcha: run consult OUTSIDE Claude Code's Bash sandbox

If you launch `consult.sh` from a Claude Code session, **disable the Bash sandbox for that call**
(`dangerouslyDisableSandbox: true`). **Both advisors fail under the sandbox:**
- **Codex** — the sandbox blocks the macOS keychain (`no native root CA certificates found` / `No keychain is available`) and does not allowlist `chatgpt.com`.
- **agy** — the sandbox blocks agy's backend network; `agy -p` exits 0 with **empty output** (the shim treats this as a hard failure, exit 5).

The symptom is a two-sided `0 answered, 2 failed` degrade. Disabling the sandbox here is safe:
consult's isolation comes from its **throwaway worktree** (and Codex's own `-s read-only`), not from
the Bash sandbox, so nothing is weakened.

## What success looks like

The operator asks one question and gets back a single, honest, reconciled answer that **shows its
seams** — what the two models agreed on, where they split, and which way the coordinator called it and
why — in one step, with both raw transcripts on disk for audit.
# Git Worktree Safety Guide for Agents

Author: Noel Saw (@noelsaw1)  
Licensed under: Apache 2.0  
Copyright 2026 Neochrome, Inc.  

> **Purpose:** Prevent destructive footguns when scripting with Git worktrees.  
> **Scope:** Shell scripts, CI pipelines, and agent workflows that create, manage, or clean up worktrees.

---

## 1. The "rm -rf worktree path" trap

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

## 3. Trap cleaning worktrees with `rm -rf` and relative paths

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

## 4. Moving/renaming worktree directories outside of git

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

## 5. Assuming `main` (or any shared branch) is free for checkout

**Anti-pattern:** `git worktree add` for a branch that's already checked out elsewhere.

```bash
# Script adds a worktree for "main" to run tests
git worktree add ../main-worktree main
```

**Why it's dangerous:** If any other worktree already has `main` checked out, this fails. This is especially problematic in CI or multi-session environments.

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

## 6. Garbage collection while worktrees exist

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

**Defensive approach:**
```bash
# Always list worktrees before GC to understand what's shared
git worktree list

# Avoid --prune=now while any worktree might be mid-write (build, commit, checkout)
# Or avoid --prune=now entirely
git gc --auto  # conservative, safe
```

---

## 7. Deleting the main worktree's `.git` directory

**Anti-pattern:** Treating the main `.git` directory as just another git database.

```bash
# Thinking you're cleaning up an old clone
rm -rf .git
```

**Why it's dangerous:** All linked worktrees reference the main repo's object database via their `.git` files. Deleting the main `.git` irrecoverably breaks every linked worktree.

**Real-world scenario:** You have 3 worktrees off a main checkout. Someone decides to "clean up" by deleting the main checkout folder. Now all 3 worktrees are orphaned with no object database, and even `git log` fails.

**Precaution:**
```bash
# Before removing any repo, check if it's the primary for worktrees
git worktree list
# If other worktrees reference this one's objects, don't delete .git
```

---

## 8. Scripts that `cd` into a worktree then use relative paths back

**Anti-pattern:**
```bash
cd ../feature-branch
# ... do stuff ...
../../main-repo/some-script.sh  # fragile relative path
```

**Why it's dangerous:** The worktree is a separate directory. Your relative path `../../` assumes a specific directory layout that may not hold (the worktree could be anywhere on disk, not necessarily a sibling).

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

## 9. Assuming `git branch -D` on a worktree-occupied branch is dangerous the way you think

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

## 10. `git stash` is GLOBAL, not per-worktree — popping in the wrong worktree corrupts the wrong tree

**Corrected claim:** Stashes are **shared** across all worktrees via the single ref `refs/stash` in
the main repo's shared ref store — `git-worktree`'s docs list `refs/bisect`, `refs/worktree`, and
`refs/rewritten` as the only per-worktree ref namespaces, and `refs/stash` is not among them. This
was verified empirically: a stash pushed in the main worktree shows up identically in
`git stash list` run from a linked worktree.

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

## 11. Selective `.git` corruption & skeleton loss (the GH-177 scenario)

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

## 12. Never run the full test gate from a linked worktree (the 2026-08-19 incident)

**Anti-pattern:** treating a linked worktree as an isolated place to verify a branch.

```bash
git worktree add ../repo-feature -b feature origin/development
cd ../repo-feature
bash validate.sh          # WRONG — this can corrupt the PARENT clone
```

**Why it's dangerous:** a linked worktree **shares the parent's `.git` common directory** — config,
refs, and object store alike (§5, §10). A suite that manipulates "the repo" rather than a fixture
therefore reaches the *real* repository. Observed on 2026-08-19, from one `validate.sh` run in a
worktree:

- `core.bare` set to **true** on the parent clone, after which `git rev-parse --show-toplevel` fails
  with `this operation must be run in a work tree` and `git worktree list` reports the main clone as
  `(bare)`
- `remote.origin.url` repointed to a fixture's temp bare repo, which was then deleted — leaving
  `origin` pointing at nothing, and every `gh` command failing with `none of the git remotes
  configured for this repository point to a known GitHub host`
- **all** `refs/remotes/origin/*` deleted
- `development` overwritten with fixture commits (`merge feature`, `feature two`, `fake ra turn`);
  local `main` overwritten with a fixture commit
- ~72 fixture files strewn through the worktree (`art.md`, `relay-flip.md`, `GH-42-SAMPLE-THING.md`, …)

No commits were lost — objects survived and the clone was repairable — but recovery required knowing
exactly what to inspect. This is the failure mode GH-564 describes ("suites that can reach the
caller's clone through an empty fixture path") arriving in practice.

A second, independent symptom of the same sharing: `test/gh4-ungated-clone-warning.sh` **cannot pass
from a worktree at all**, because it does `rm .git/hooks/pre-push` and in a worktree `.git` is a
*file*, not a directory. Same commit, two locations — 6 pass / 0 fail in the main clone, 3 pass /
3 fail in a worktree. A worktree gate run is not merely risky, it is not measuring what you think.

**Correct approach — run the gate from a normal clone.** A worktree is for editing and committing;
verification belongs in a full clone:

```bash
# In the worktree: make the change, commit it.
git commit -am "..."

# In the MAIN clone (or a fresh throwaway clone): check out that branch and gate it there.
cd /path/to/main-clone
git checkout feature
bash validate.sh
```

**Detect it in a script** with the same `--git-common-dir` idiom the driver-lock resolver uses
(GH-448) — in a main clone the two are equal, in a linked worktree they are not:

```bash
if [ "$(git rev-parse --absolute-git-dir)" != "$(cd "$(git rev-parse --git-common-dir)" && pwd)" ]; then
    echo "refusing: linked worktree shares the parent clone's .git — run this from a normal clone" >&2
    exit 2
fi
```

Tracked as [GH-45](https://github.com/HiQS-Suite/XYZ-forge/issues/45): `validate.sh` should carry
that guard and fail closed by default, so this class is unreachable regardless of how many
individual suites have been audited.

---

## 13. Other footguns worth knowing before scripting worktrees

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

## 13. Running the test gate from a linked worktree corrupts the PARENT clone

**The trap.** `validate.sh` / `ci-local.sh` run ~190 suites, many driving git fixtures. From a
linked worktree, a suite that escapes its fixture — or resolves a fixture path to an empty
string — reaches the **parent clone's shared `.git`** (config, refs, objects), because a
worktree isolates the working tree ONLY. This is not hypothetical: the observed 2026-08-19 run
([GH-45](https://github.com/HiQS-Suite/XYZ-forge/issues/45)) set `core.bare=true`, repointed
`remote.origin.url` at a since-deleted temp bare repo, deleted every `refs/remotes/origin/*`,
and overwrote `development` and `main` with fixture commits. Same root cause as the
`mktemp`-under-parallel-load family (GH-177/GH-564).

**The guard (GH-45, built 2026-08-18).** Both gate entry points now REFUSE to run from a linked
worktree — exit 2 before anything executes, every tier — using the one-comparison detection
`git rev-parse --absolute-git-dir` ≠ resolved `git rev-parse --git-common-dir`, anchored on both
the script's own root and the invocation CWD. The refusal message names the observed damage;
`XYZ_ALLOW_WORKTREE_GATE=1` is the announced override for deliberate disposable runs. Pinned —
including the control that a normal checkout of the same repo still runs — in
`test/gh35-test-tiers.sh` §9.

**Rule:** run the gate from a normal clone. A worktree is a fine place to *edit*; it is not a
place to run a suite whose fixtures assume "the repo" is disposable.

---

## Golden Rules for Worktree Safety

1. **Always use `git worktree remove`/`prune`/`repair`, never manual `rm -rf` or `mv`** on worktree
   directories or `.git/worktrees/<name>` — repair (2.29+) and move (2.17+) are git's own tools for
   exactly these cases
2. **Validate before destroying** — check that paths are non-empty, real directories, and not repo
   roots before any destructive operation
3. **Be path-aware in traps** — canonicalize paths early, validate them, and never `rm -rf` on
   relative paths or unvalidated variables
4. **The main repo's `.git` is the single source of truth** — protect it like a database, and verify
   its skeleton (`HEAD`/`objects`/`refs`/`config`) is intact before trusting any command run against
   it (§11); partial corruption is a real failure mode, not just total deletion
5. **Worktrees share almost everything — objects, refs, AND stashes/logs.** The only genuinely
   per-worktree ref namespaces are `refs/bisect`, `refs/worktree`, and `refs/rewritten`. Don't assume
   isolation you don't have (§10); Git also actively *protects* shared state you might expect it not
   to (§9's branch-delete block)
6. **Prefer git's own recovery tools over hand-surgery on `.git/`** — `init` (safe to re-run),
   `fetch`, `prune`, `repair` — and reach for `read-tree`/`diff`/`status` to inspect before any
   command that can overwrite the working tree (`checkout -f`, `reset --hard`, `clean`)
7. **Script against `--porcelain` output, never the human-readable table** — `git worktree list`'s
   plain format is not a stable, grep-safe API
8. **Never run the full test gate from a linked worktree** (§12) — the suite writes to the shared
   `.git`, so it can set `core.bare`, repoint `origin`, delete remote refs, and overwrite branches in
   the *parent* clone. Edit and commit in a worktree; verify in a normal clone.

---

## See Also

- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [git-init](https://git-scm.com/docs/git-init) — confirms re-running `init` on an existing repo is safe/non-clobbering
- [git-fsck](https://git-scm.com/docs/git-fsck) — integrity check, first step after any suspected `.git` corruption
- [git-gc](https://git-scm.com/docs/git-gc) — documents the `--prune=now` concurrency risk cited in §6
- Related: [Temp Directory Safety Guide](./temp-dir-safety.md) — for the `mktemp` failure mode that can cascade into worktree destruction

---

Licensed under: Apache 2.0   
Copyright 2026 Neochrome, Inc.  
# ROUTER.md

This file is the first entry point for an AI agent working in this repo: it tells you what to read, what to run, and which files are canonical.

## Role split

- `ROUTER.md` = startup order and canonical entry points
- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof
- `README.md` = human-facing repo/product overview
- `ROADMAP.md` = pointer ledger of queued, current, completed, attempted, and deferred work
- `CHANGELOG.md` = the end-of-iteration running log (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
- `RELEASES.md` = forward-looking release-planning ledger (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
- `HARNESS-MODELS-REGISTRY.md` = evaluated agent harnesses, supported model grades (A/B/C), and CLI flags
- `PROJECT/**` docs = canonical execution detail for a specific effort
- `PROJECT/PDDA.md` = document contract and automation rules (incl. the CHANGELOG contract)
- `PROJECT/CONSTITUTION.md` = the policy of record: PDDA's lane and its non-negotiables (deterministic-before-LLM, verified-success-only, reversibility, local-first)
- `PROJECT/DO-NOT-BUILD.md` = the anti-scope list — product directions PDDA must not become (companion to `CONSTITUTION.md`)

## Startup sequence

1. Read `ROUTER.md` to understand the repo's operating order and canonical files. -> expect one clear next file, not a repo-wide scavenger hunt.
2. Read `AGENTS.md` before making recommendations or edits. -> expect explicit assumptions, a reversibility read on consequential changes, and verified claims only.
3. Read `ROADMAP.md` to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; `ROADMAP.md` is a pointer ledger, not a plan body.
4. Read the linked `PROJECT/**` document that owns the work you are touching. -> expect the near-top `## Status` table to tell you what was just completed and what is next.
5. If the task touches project docs, read `PROJECT/PDDA.md` and follow the PDDA contract. -> expect `PROJECT/2-WORKING` docs to have frontmatter, the exact status table, and QA gates when phased.
6. Before reporting success on code or runtime work, run `./validate.sh`. -> expect the suite to stay green; do not claim completion if it fails or was skipped.
7. Before reporting success on doc-hygiene or roadmap work, run `utils/pdda/pdda.sh run` (or the relevant `utils/pdda/pdda.sh <check>` subcommand). -> expect deterministic findings first, then any LLM review.

## Canonical rules

- Do not put phase checklists, build steps, or deep execution notes in `ROADMAP.md`.
- Every active doc in `PROJECT/2-WORKING/` must be reflected by a pointer in `ROADMAP.md` — a one-line ledger entry that links it. A working doc that should not appear opts out with `roadmap_exempt: true` in its frontmatter. Enforced by `utils/pdda/pdda.sh roadmap-coverage`; governance lives in `PROJECT/PDDA.md` → "ROADMAP.md contract".
- Every captured GitHub issue doc in `PROJECT/1-INBOX/GH-*.md` must also be parked in `ROADMAP.md` as a one-line queue entry immediately at intake, then promoted or removed later. Enforced by `utils/pdda/pdda.sh roadmap-coverage`; governance lives in `PROJECT/PDDA.md` → "GitHub issue intake" + "ROADMAP.md contract".
- Do not create a second competing plan when a canonical `PROJECT/**` doc already exists.
- Issue-first: any change beyond a **2–3 line** fix opens a GitHub issue first, then a pointer doc **named after the issue** (`GH-<number>-VERY-SHORT-DESC.md`, e.g. `GH-1234-SHOWME-COMMAND.md`), and that capture is **parked in `ROADMAP.md` immediately** before execution begins. The issue is the signal stream; the pointer doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt. Governed by `PROJECT/PDDA.md` → "GitHub issue intake".
- Runtime triage labels: since the `XYZ_PYTHON` flip the harness is dual-runtime, so any harness-bug issue gets a `runtime:` label — `runtime:python` (default path), `runtime:bash` (`XYZ_PYTHON=0` opt-out), or `runtime:parity` (the twins diverge). `/file-xyz-bug` harvests and applies it; for in-repo intake (`/triage`, hand-filed `gh issue create`) apply it by hand. Omit rather than guess — a wrong runtime tag misroutes triage.
- Do not override deterministic PDDA findings with prose.
- Do not report a win you did not verify with the relevant script or test.
- Update `CHANGELOG.md` at the end of each iteration; its governance lives in `PROJECT/PDDA.md` — do not re-specify CHANGELOG rules in `AGENTS.md` or elsewhere.

## Command rails

For repo correctness:

```bash
bash githooks/install.sh        # ONCE PER CLONE — wires the pre-push gate (GH-544)
bash githooks/install.sh --check # is this clone gated? exit 1 if not
./validate.sh              # the gate — PARALLEL by default (GH-544), auto-sized to the host (GH-35)
./validate.sh --print-mode # which mode would this host pick, and why — runs nothing
./validate.sh --sequential # force the sequential run (~16 min)
./validate.sh --tier 2 --subsystem hq   # GH-35: one subsystem's focused suites (pre-push speed, NOT evidence)
./validate.sh --auto       # GH-35: classify the git diff, run the minimal safe tier (fails closed to 3)
./validate.sh --throttle   # GH-35: 2 workers under nice — quiet-machine mode (--burst restores full width)
bash ci-local.sh           # the QUALIFYING run — sequential + writes the gate record (GH-509/GH-536)
```

**Both gate entry points refuse to run from a linked git worktree (GH-45)** — a worktree shares
the parent clone's `.git`, and an observed suite escape corrupted the parent (core.bare, origin,
remote refs, development). Run the gate from a normal clone; `XYZ_ALLOW_WORKTREE_GATE=1` is the
announced override for disposable runs.

**Hosted CI fires on nothing while this repo is private (GH-544).** The gate runs locally at the push
boundary instead, so `githooks/install.sh` is part of setting up a clone — the hook lives in
`.git/hooks/`, which does not travel with a clone, and an uninstalled one pushes unverified. One
install covers every branch and every linked worktree of that clone (GH-549). Bypass with
`git push --no-verify` or `XYZ_SKIP_PREPUSH=1`; both announce themselves. Re-arm CI when the repo
goes public (free there).

**Parallel became the default on 2026-08-14 (GH-544)** because the local gate is the only gate during
the private phase, and a 16-minute gate does not get run — it gets skipped, which is worse than a
3-minute one. **GH-35 (2026-08-18) rebalanced the width to `cores/2` (floor 2, cap 4) and put every
worker under `nice -n 10`** — the original `cores − 2` (up to 8) saturated developer machines badly
enough to wedge the editor; `--burst` buys the old full-core width back for unattended runs, and
`--throttle`/`--quiet-cpu` pins 2 workers. Ambient levers: `XYZ_VALIDATE_THROTTLE=1`,
`XYZ_VALIDATE_MAX_JOBS=N`, `XYZ_VALIDATE_PARALLEL` (flags > MAX_JOBS > THROTTLE > PARALLEL > host
detection; malformed values exit 2 naming the variable). Below 4 cores, or where `xargs -P` is
unsupported, the run **falls back to sequential and says so** — every run prints the mode it chose
and the reason, so a fallback is never silent.

**GH-35 also added TIERED SELECTION on top, as a separate axis from width.** `utils/ci-route.sh`
owns one fail-closed subsystem registry (hq, releases, telemetry, ate, swe-diagram, pdda,
agent-chorus); a push the classifier rates `tier=2` runs only those focused suites at the boundary,
`--tier 1` runs the docs gate, and everything else — unknown paths, test edits, kernel surfaces —
runs the full suite. `--auto` classifies a local diff the same way. Tiers 1 and 2 are pre-push
speed and are labelled NOT promotion evidence; only `ci-local.sh`'s sequential full run qualifies
(GH-509).

**What still qualifies a claim is unchanged.** `./validate.sh` in either mode is a self-check;
`ci-local.sh` is the run that writes the evidence record, it does **not** call `validate.sh`, and it
stays sequential. The macOS promotion boundary in `ci.yml` pins `--sequential` explicitly for the same
reason. GH-528 Phase 2 (multi-width stress evidence) is still **owed** — the flip was an operator
decision taken with that evidence outstanding, mitigated by the announced fallback rather than
discharged. See `PROJECT/2-WORKING/GH-528-TEST-SUITE-RECALIBRATION.md`, #509 and #544.

For document hygiene:

```bash
utils/pdda/pdda.sh run
```

For targeted PDDA debugging (subcommands of the single dispatcher):

```bash
utils/pdda/pdda.sh frontmatter
utils/pdda/pdda.sh status-table
utils/pdda/pdda.sh hardcoded-paths
utils/pdda/pdda.sh roadmap
utils/pdda/pdda.sh roadmap-coverage
utils/pdda/pdda.sh changelog
utils/pdda/pdda.sh stale
utils/pdda/pdda.sh issue-doc-sync   # warn-only: flags 2-WORKING/GH-*.md docs drifted from their GitHub issue state
utils/pdda/pdda.sh releases         # validate RELEASES.md, the OPTIONAL release-planning ledger (warn-only; skips a missing file)
utils/pdda/pdda.sh releases-current # read-only roll-up: RELEASES.md entries whose Status isn't "Shipped"
utils/pdda/pdda.sh quad-concepts    # opt-in: requires a "## Quad Concepts" section of 1-4 bullets (lever: .pdda-quad / PDDA_QUAD)
utils/pdda/pdda.sh glance           # read-only roll-up: title + Quad Concepts for each PROJECT/2-WORKING doc
utils/pdda/pdda.sh gh-refresh       # refresh the cached GitHub issue-state file issue-doc-sync reads offline (needs gh)
utils/pdda/pdda.sh catchup          # LLM repo triage + ROUTER.md recommendations (delegates to pdda-catchup.sh)
utils/pdda/pdda.sh doc-ready        # LLM readiness review — set PDDA_LLM_BIN (codex/claude/agy) for recommendations, else it self-skips
```

## The RELEASES DB — two subsystems, one ledger (GH-32 / GH-69)

`releases.db` + `releases.sql` hold TWO mirrored subsystems, both operated through ONE CLI,
`utils/py/releases_app.py` (alias: the `/releases` skill). Read
[RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md) before merging either file — the SQLite binary is
derived; the SQL dump is what git actually merges, and a conflicted merge has a one-command
resolver (`utils/releases-merge-resolve.sh`).

```bash
python3 utils/py/releases_app.py check          # trio consistency, receipt chain, crash recovery
python3 utils/py/releases_app.py next           # the next unshipped release, by target date
python3 utils/py/releases_app.py add|ship ...   # RELEASE writes — never hand-edit releases.sql
python3 utils/py/releases_app.py roadmap sync   # GH-69: mirror ROADMAP.md's ledger into roadmap_items
python3 utils/py/releases_app.py roadmap list   # read the shadow rows
```

**Subsystem 1 — releases** (GH-32, Phase 0 side-by-side): the release ledger. App-managed writes
only; `RELEASES.md` is still the human file during the shadow phase.
**Subsystem 2 — the ROADMAP shadow** (GH-69, same pattern): `ROADMAP.md` stays the ONLY thing
anyone edits; `roadmap sync` mirrors its ledger into the DB, losslessly, one-way. After editing
`ROADMAP.md`'s ledger, run the sync — a no-change sync is a free no-op. Pinned by
`test/gh69-roadmap-shadow.sh`.

## Routing hints

- If the task is about current priorities or active work, start in `ROADMAP.md`, then follow the linked `PROJECT/**` doc.
- If the task edits `ROADMAP.md`'s ledger, finish with `python3 utils/py/releases_app.py roadmap sync` (GH-69 shadow — see the RELEASES DB section above).
- If the task touches `releases.db`, `releases.sql`, or a merge conflict on either, start in [RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md); writes go through the CLI, never a hand-edit.
- If the task is about fresh GitHub intake or duplicate-prevention, start in `ROADMAP.md`'s queue, then follow the linked `PROJECT/1-INBOX/GH-*.md` capture doc.
- If the task is about document quality, active-doc lifecycle, roadmap sprawl, or automation policy, start in `PROJECT/PDDA.md`.
- If the task is about the CHANGELOG, provenance, or end-of-iteration logging, the governance is in `PROJECT/PDDA.md` (the "CHANGELOG.md — end-of-iteration record" contract).
- If the task is about release planning, ledger health, cleanup, authoring, or publishing, invoke `/releases`. It reads and synthesizes `RELEASES.md` first, then routes explicit requests into confirmation-gated cleanup, planning, or publication; governance is in `PROJECT/PDDA.md` (the "RELEASES.md — release ledger" contract). It conditionally points strategic drift to `/radar` and a frozen path-to-ship to `/finish-line` without duplicating either workflow.
- If the task is about the `tick` runtime, event projection, or multi-agent coordination kernel, start in `README.md`, then `bin/`, `src/`, `test/`, and the active project doc.
- If the task is about the **Aider ↔ OpenRouter** turn-taker lane (`relay-automation/aider-turn.sh` — an OpenAI-standard build lane discrete from Codex; `AIDER_MODEL`/`OPENROUTER_API_KEY`, `--builder aider`), start in `PROJECT/3-COMPLETED/GH-77-AIDER-OPENROUTER-LANE.md`. The shim owns the tick token ops (Aider can't run shell mid-turn), asserts token ownership before launching Aider, and runs Aider `--no-auto-commits` (the harness commits).
- If the task is about running, driving, or reviewing via the relay (`relay-automation/` — `relay-drive.sh`, `poll.sh`, the turn shims, `marathon*.sh`), **invoke the `relay-xyz` skill first — do not improvise the handoff or hand-roll a harness from `ls relay-automation/`.** The skill owns the locator, sandbox rules, exit codes, and the safety boundary; a `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) blocks driving a harness driver before the skill is loaded. For the two live-Claude-windows, same-machine duel recipe (Reporter↔Maintainer with a human go-gate), the copy-paste form is [relay-automation/DUELING-CLAUDES.md](relay-automation/DUELING-CLAUDES.md).
- If the task is about the ATE (Automated Testing Environment) skill — unattended Aider variation-test fuzzing driven by a local Gemma worker under `utils/ate/` — start in `utils/ate/SKILL.md`. Currently hardcoded to Aider despite the generic name/description; generalizing it to other harnesses is tracked, not urgent, in `PROJECT/1-INBOX/GH-191-ATE-GENERALIZE-HARNESS.md`.
- If the task is about relay session telemetry, the `focus5float` health feed, or extraction scripts under `utils/telemetry/`, start in `PROJECT/1-INBOX/GH-24-RELAY-TELEMETRY-EXTRACTOR.md`.
- If the task is about live per-session completion telemetry — the `XYZ.json` log every relay/marathon/swarm session appends to at the harness repo root (schema: `harness`/`sessionId`/`health`/`title`/`description`/`updatedAt`), the shared writer `utils/telemetry/append-xyz-completion.sh`, or the shared health mapping `utils/telemetry/health-lib.sh` — start in `PROJECT/1-INBOX/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md`. `XYZ.json` is local + gitignored (machine-specific).
- If the task is about cross-repo HQ tooling (`utils/hq/` — `hq.sh` single-repo actions, `rollup.sh` the Obsidian daily ROADMAP rollup, `marathon-scan.sh` the cross-repo marathon-preflight aggregator, `hq-lib.sh` the shared repo registry), start in `PROJECT/3-COMPLETED/GH-27-ROADMAP-DASHBOARD.md` and `PROJECT/3-COMPLETED/GH-158-HQ-MARATHON-SCAN.md`. The two rollups are deliberately separate today (`rollup.sh` → Obsidian, generic; `marathon-scan.sh` → hub repo, preflight-aware) and are not yet bridged — tracked in `PROJECT/1-INBOX/GH-192-HQ-MARATHON-OBSIDIAN-ROLLUP.md`.
- If the task is about a proposed roadmap-steward agent, start here, then read `PROJECT/PDDA.md` and its `Proposed roadmap steward extension` section.
- If the task is about finding or picking a skill for a job, see `ARCHITECTURE.md` → "Skills Index" for a one-line inventory of every skill in `skills/`.
- Issue-first SOP: any change beyond a 2–3 line fix (and every project plan) opens a GitHub issue *first*, then gets a pointer doc named after the issue at `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md` — e.g. `GH-1234-SHOWME-COMMAND.md` — and that capture is parked in the `ROADMAP.md` queue immediately (format + lifecycle owned by `PROJECT/PDDA.md` → "GitHub issue intake"), following the normal `1-INBOX` → `2-WORKING` flow. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt and commit directly.
# Guiding Principles

North star for **xyz-3-agents-swarm**, the multi-agent coordination harness behind the `tick` event-log kernel and `relay-automation/` relay stack. When a choice is unclear, the option that keeps agents synchronized, contained, and verifiable — without leaking or destroying work — wins. AGENTS.md is the behavioral playbook; ROUTER.md is the entry-point map; this is the *why*.

## Purpose

`tick` coordinates Claude Code, Codex, and agy (Antigravity CLI) on the same branch without collision: a shared local event log under `.tick/events/`, claims serialized by `O_EXCL` locks, and a `Marathon` harness that chains multi-phase build→review cycles from a `MARATHON.yaml`. The relay layer (`relay-automation/`) drives headless turns, isolates agent writes to worktrees, and enforces an allowlist so no headless agent destroys work it didn't intend to touch. The goal: a multi-agent swarm safe enough to run against a real external codebase and correct enough that its output is worth shipping.

## The quality bar

Every agent turn is a signal. A turn is high-quality only when it is all four:

- **Attested** — carries its receipts: source, evidence, confidence. Never a bare verdict. A relay review names which claim is wrong and why; a build turn names the seam it touched.
- **Relevant** — ranked, not dumped. Volume is not value. One real bug beats five nits and a phantom.
- **Fresh** — current, not stale. A turn that reads a stale `STATE.md` or misses an epoch fence is wrong by construction.
- **Structured** — one shape, clean for the operator to read and for downstream agents to feed on.

Fail a pillar, and the turn, feature, or relay review isn't done.

## How it's built

1. **Coordination is local-transport only.** `.tick/events/` is the shared bus; claims resolve from there, not from a remote. No per-event push/fetch; no remote dependency at runtime. A coordination primitive that reaches out is a coordination primitive that can fail or leak.

2. **One canonical event log; every surface is a projection.** `tick` accretes events; `STATE.md` is the current projection. Reads go through the projection; writes go through a `claim/take/scope/done` verb. Nothing canonical lives in two places where it can drift. An agent that hard-codes state outside `.tick/` is creating drift.

3. **Containment is non-negotiable.** A headless turn must not: self-commit mid-turn, orphan a peer's concurrent commit, or write outside its allowlist. The allowlist, worktree isolation, and commit-bypass guard exist because a driven agent will do all three if unconstrained — not hypothetically, but as documented live incidents (GH-13, GH-14, GH-17). New relay paths must clear the containment bar before they ship.

4. **Skill-first; never improvise the harness.** The `relay-xyz` skill owns the locator, sandbox rules, exit codes, and the safety boundary. A session that improvises those from `ls relay-automation/` silently skips the skill's safety layer. The `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) enforces this by blocking driver calls before the skill loads. Add capabilities to the skill; do not work around it.

5. **Adversarially proven before commercially viable.** The harness exists to run against real codebases. Features in the adversarial-hardening track (epoch fencing, chaos suite, cross-repo E2E) must be verified to survive deliberate abuse — stale writers, zombie claims, macOS case-sensitivity, concurrent peer commits — not just the happy path. A feature that clears the happy path and skips chaos is half-done.

6. **Build durable, not band-aid.** Durable means it removes the root cause and the next planned change builds on it — not a patch torn out when the obvious next feature lands. A band-aid is wasted work unless a demo strictly needs one, and a demo band-aid is tagged for removal so it isn't silently inherited.

7. **Least code that clears the bar.** Node standard library only — no deps, no lockfile; the repo ships no root manifest. Prefer reusing or extending what exists; the smallest change that stays correct, contained, and durable wins. Net-new code is a cost to justify. Deleting code counts as progress.

8. **Honest; the operator decides.** Surface what failed and why — never mask a stall as success or an escalation as a stall. A headless turn self-repairs within a bounded exit-code menu (`exit 3` stall, `exit 4` escalated-by-design, `exit 6` containment revert), then stops; it never loops forever or silently swallows an error. Destructive actions require explicit authorization.

9. **Docs are resumable runtime state (PDDA).** Agent work is stoppable, resumable, and handed off from `PROJECT/**` alone — ROUTER points, project docs hold detail, CHANGELOG logs dated outcomes. ROADMAP.md is a pointer/ledger only; execution detail lives in the linked `PROJECT/**` doc. If reality and the docs disagree, the docs are the bug.

10. **Done means verified.** "Done" is `validate.sh` green, the relevant PDDA checks passing, and any relay review returning `Approved` — not work that looks finished. An unverified success claim is itself a low-quality signal.

11. **Issue-first; every non-trivial change has a signal stream.** Any change beyond a 2–3 line fix opens a GitHub issue first, then gets a `GH-<number>` in-repo pointer doc, then lands. The issue is the machine-queryable signal stream; the `PROJECT/**` doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt.

12. **Independent Verification (Separated Grading)** — The agent that produces a turn must not be the sole grader of its own quality. Verification must be performed by an independent deterministic check or a separate reviewing agent before the lock releases. Applies to: the relay's structural block validator (`bin/validate-relay-block` — Phase 1 of GH-21), consult-verify diversity (Phase 3), and any other post-generation quality gate.

13. **A green gate without a witnessed red control is not evidence.** Every new or materially changed decision gate ships a recorded demonstration that it fails for the right reason: a pre-fix replay, deliberate mutation, or controlled bad fixture. Do not mistake a check that validates the artifact it just generated (#351) or a parity check that compares a lane to itself (#348) for evidence; both shapes are structurally unable to falsify their claim.

## Applying this

Adding a feature or weighing a tradeoff, ask: *does this keep agents coordinated without collision, contained within their scope, and verifiable to an outside observer? And is "done" provable by running `validate.sh`?* If any answer is no, reconsider.

---

## Conventions

### Strict-mode policy (bash `set -e`)

Strict mode is **per-subsystem, not repo-wide** (GH-110 P3b). The split is deliberate:

- **`relay-automation/` drivers and turn shims run `set -euo pipefail`.** They orchestrate risky,
  multi-step, containment-sensitive turns where a silently-ignored failure can commit off-lane or
  orphan a peer. Abort-on-error (`-e`) is the correct default there.
- **`utils/` analysis tools (`pdda/*`, `marathon-plan.sh`, `swarm-preflight.sh`) run `set -uo pipefail`
  or `set -u`, deliberately *without* `-e`.** These are long single-pass scripts whose normal control
  flow includes many expected-nonzero probes (`git rev-parse`, `gh` lookups, `grep` misses). Under
  `-e` a benign "no match" would abort the whole run, so they set `-u` (catch unset vars) + explicit
  per-call error handling instead. This is an exemption, not an oversight.

Every currently `-e`-exempt script carries a one-line `# strict-mode: -e exempt — …` header next to
its `set -` line so the exemption is self-documenting. New scripts default to `set -euo pipefail`
unless they fit the analysis-tool profile above, in which case they add the exemption header.

### Tool install paths — never inside another app's folder (GH-347)

**This harness's tool binaries never live inside another application's private directory.** Not the
worker CLIs (`codex`, `agy`, `pi`, `aider`), not `tick`, not anything the harness shells out to.

The failure mode is specific and quiet: a foreign app owns its own directory, so its next update or
reinstall deletes our dependency with it — on that app's schedule, with no signal we control. Worse, the
readiness check cannot tell the two apart. `find-harness.sh --check` tests only whether a worker is *on
PATH*, so "the neighbouring app just wiped our tool" and "never installed" produce the byte-identical
line. That is the same disease as GH-315/GH-319: a broken observation layer where failure is invisible
and every available signal agrees.

**The `npm install -g` trap — this is how GH-347 actually happened.** npm derives its global prefix from
whichever `npm` is on PATH, so a bare `npm install -g <pkg>` inherits a foreign app's runtime silently
and exits 0. On the machine that filed GH-347, another agent app had symlinked its bundled Node onto PATH
(`~/.local/bin/npm -> ~/.hermes/node/bin/npm`) with no `~/.npmrc` involved at all, so `pi` installed into
that app's folder and — because only `node`/`npm` were symlinked out, not `pi` — was invisible to every
shell while being perfectly functional. **Run `npm config get prefix` before any global install and
confirm it is a path this repo's tooling owns.** Never assume.

The positive pattern is already on disk in the two lanes that have never had this problem: a tool's own
app directory with a symlink onto PATH (`~/.local/bin/codex -> ~/.codex/packages/…/bin/codex`), or a real
binary in a shared user-local `bin`. Either is fine. Someone else's runtime is not.

**Scope note:** where a *working* binary lives stays the operator's call. This is a convention and a
warning, deliberately **not** a gate — a false positive that blocks a relay is worse than the papercut it
prevents.

### Marathon builder default & plan location (GH-212)

Two vendored-harness defaults, made explicit so an agent given only the vendored bundle picks the
right behavior without pattern-matching a downstream repo's prior drift:

- **Builder default is `codex`, not a billed CLI.** `marathon.sh`/`marathon-drive.sh` (and the
  `XYZ_PYTHON=1` port) default `--builder` to `codex` — build turns bill via the Codex/ChatGPT
  subscription, not the Anthropic API (agy is the other cost-blind option). `--builder claude`
  spawns a headless Claude Code CLI subprocess instead: a separate, per-call API-billed turn-taker.
  Use it only as an explicit, cost-acknowledged choice — never assume it's free because an
  interactive session is already running. `swarm-preflight.sh`'s suggested invocation and
  `marathon.sh`'s own default now agree; don't let them drift apart again.
- **A marathon's plan lives under `PROJECT/2-WORKING/`.** The `MARATHON.yaml` + its phase briefs
  belong under `PROJECT/2-WORKING/<capture-doc>/` — never a standalone top-level folder (e.g.
  `marathon-plans/<slug>/`). `marathon.sh --plan` enforces this: it refuses (exit 2) a plan that
  resolves outside `PROJECT/2-WORKING/`, exempting only paths under the harness's own home
  (`MARATHON_HOME` — shipped reference examples like `MARATHON.example.yaml`) or an explicit
  `MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1` override for a genuinely non-default location.

---

## Appendix: AI Doc Review Heuristics

When reviewing any repo doc (roadmap entries, plans, architecture notes, audits, task writeups), apply these. Priority: containment > coordination correctness > signal quality > implementation speed and operator friction.

**Heuristics**

1. **Containment preserved?** Any headless path that could self-commit, touch off-allowlist files, or orphan a peer commit without an explicit containment argument → reject or escalate.
2. **Skill-first respected?** Any plan that bypasses `relay-xyz` or improvises the harness from scratch without the skill layer → reject. Add to the skill instead.
3. **Coordination through the event log?** Reads/writes to shared state route through `tick` verbs; hard-coded state outside `.tick/` needs explicit justification.
4. **Done verifiable?** Names runnable gates (`validate.sh`, specific tests, `utils/pdda/pdda.sh run`). None = low-quality signal.
5. **Drift reduced, not created?** No duplicated docs, no execution detail in ROADMAP.md, no reinventing a path the event-log contract already documents.
6. **Next action singular?** One explicit next step, not buried in prose; status cells non-empty.
7. **Operator control explicit?** No silent retry, no auto-repair outside the bounded exit-code menu, no masked failure; destructive ops surface before executing.
8. **Four pillars pass?** Each turn/output is Attested, Relevant, Fresh, Structured. Fail one → not done.

**Tie-breakers**

- **Containment vs speed:** choose containment; flag friction as a design question, not a shortcut.
- **New relay path vs reuse:** extend the existing skill and harness over forking a parallel path; if the harness can't accommodate it, surface the gap.
- **Ambitious vs resumable:** a shorter plan an agent can resume cold beats a comprehensive one that buries state in prose.

**Reject or escalate when**

- A headless path has no allowlist, no worktree isolation, and no commit-bypass guard — and the doc doesn't justify why.
- "Done" has no runnable verification step.
- Adding a new relay lane requires editing the event-log kernel or the `tick` verb schema without a decision record under `decisions/`.
- Hardcoded absolute paths, silent destructive operations, or opaque epoch-fence assumptions.
- ROADMAP.md would need execution detail to make the plan legible.

mcp: codebase-memory-mcp/list_projects started
mcp: codebase-memory-mcp/list_projects (failed)
user cancelled MCP tool call
codex
The graph index is unavailable in this throwaway consult, so I’m falling back to literal/document searches as the repo permits. The consult skill confirms this lane is advisory-only and that ignored local state is intentionally excluded from disposable review worktrees—directly relevant to why an in-repo ignored salvage directory would remain poorly visible.
exec
/bin/zsh -lc "rg -n --hidden -S \"GH-141|orphan-backups|marathon-cleanup|teardown|salvage|harnesses\\.db|HARNESS-MODELS-REGISTRY.generated|blog-frontier-benchmarks|relay-scratch|clone.*delete|delete.*clone\" --glob '"'!harnesses.sql'"' --glob '"'!releases.sql'"' ." in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-17781-brvet5yb
 succeeded in 0ms:
./.gitattributes:37:harnesses.db          -diff linguist-generated=true
./ARCHITECTURE.md:44:| [marathon-cleanup](skills/marathon-cleanup/SKILL.md) | Audit and archive completed PDDA marathon plans/bundles. |
./ROADMAP.md:140:- **GH-113 · headless agy builder writes root scratch files, tripping containment (exit 6)** 🚧 **queued 2026-08-22 for THE MARATHON (release 0.7.3 "Bulkhead", #179)** — give headless builder turns a sanctioned scratch lane (.relay-scratch/<turn>/) so debugging temp files relocate instead of failing the turn; tracked-file violations still exit 6. rated 85/60/85/60. → [GH-113-HEADLESS-SCRATCH-CONTAINMENT.md](PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md) · [#113](https://github.com/HiQS-Suite/XYZ-forge/issues/113)
./ROADMAP.md:143:- **GH-2 · test-suite run relocated an untracked file into .tick/orphan-backups/** 🚧 **queued 2026-08-22 for THE MARATHON (release 0.7.3 "Bulkhead", #179)** — reproduce under parallel load, then guard every mv/rm/find-delete on a derived path with resolved containment. rated 80/55/85/55. → [GH-2-ORPHAN-BACKUP-RELOCATION.md](PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md) · [#2](https://github.com/HiQS-Suite/XYZ-forge/issues/2)
./ROADMAP.md:147:- **GH-141 · make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison** 🚧 **active 2026-08-22 on branch `gh141-fuzz-ate-utility`** — one selector owns the synthetic suites (validate.sh `--list` consumed by fuzz-loop, all 14 synthetic suites registered, divergence regression), telemetry de-aliased (nested `classification.status` removed; severity/likely_cause become derived signal from documented exit classes and output classes, consumers updated in-phase), the ATE chain fails loudly (#142's exit-code contract: 0 filed · 3 no-records · 1 gh-failed, propagated through run_variations) with a hermetic stub-`gh` chain regression, and ATE decoupled from Aider (neutral default labels, `expects_edits` grid key fixing #146's 17 false-HIGH no_edit verdicts, turn-shim grid declared, SKILL.md generalized). Phase 3 (generative boundary fuzzing) deliberately NOT scheduled — #143's counted comparison picks the target first, per the issue's own recommendation. rated 80/65/85/55. → [GH-141-FUZZ-ATE-UTILITY.md](PROJECT/2-WORKING/GH-141-FUZZ-ATE-UTILITY.md) · [#141](https://github.com/HiQS-Suite/XYZ-forge/issues/141) · [#142](https://github.com/HiQS-Suite/XYZ-forge/issues/142) · [#146](https://github.com/HiQS-Suite/XYZ-forge/issues/146)
./ROADMAP.md:150:- **GH-174 · Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator** ✅ **SHIPPED 2026-08-23 (PR #174; issue closed)** — migrate static HARNESS-MODELS-REGISTRY.md into active SQLite ledger (harnesses.db) with DRY per-device configs, reasoning level tracking, deterministic post-turn AI grading hooks, and automated blog generation. rated 85/75/95/45. → [GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md](PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md) · [#174](https://github.com/HiQS-Suite/XYZ-forge/issues/174)
./ROADMAP.md:154:- **GH-181 · repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2)** ✅ **SHIPPED 2026-08-23 (PR #185; Bulkhead wave — Gen 3.5 soak cohort)** — telemetry schema 1.1 (`argv` list + realized `env` + failure signature, emitter side) and signature-matching ingest; the real GH-141 record becomes the permanent end-to-end regression fixture (#174's finding-travels-untouched criterion). rated 90/75/90/60. → [GH-181-REPRO-ADAPTER-FIDELITY.md](PROJECT/3-COMPLETED/GH-181-REPRO-ADAPTER-FIDELITY.md) · [#181](https://github.com/HiQS-Labs/XYZ-forge/issues/181)
./ROADMAP.md:156:- **GH-184 · committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation** ✅ **SHIPPED 2026-08-23 (PR #185; Bulkhead wave — Gen 3.5 soak cohort)** — remove the PR #160 artifact and add a derived no-tracked-scratch guard, so the lane's by-design discard can never dirty a clone (success-shaped-exit mutation found in soak §3.5). rated 60/40/80/90. → [GH-184-TRACKED-SCRATCH-ARTIFACT.md](PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md) · [#184](https://github.com/HiQS-Labs/XYZ-forge/issues/184)
./ROADMAP.md:165:- **GH-91 · a build turn has nowhere to write verification output — containment kills a complete, green turn** ✅ **CLOSED 2026-08-22 (issue closed; ledger reconciled)** — issue option 1: `.relay-scratch/` as an intrinsic write category — pre-created by `rtl_worktree_begin`, exempted in `rtl_worktree_end` (no signature check; never copied back), exempted-and-discarded in `rtl_check` (non-worktree path), and NAMED in `rtl_turn_prompt` at the point of use. New suite `test/gh91-relay-scratch.sh` 15/0 with controls (stray still exit-6, lookalike prefix not exempt, off-lane copies nothing back); containment-pinning neighbors green. Surfaced by the daybreak wave-1 re-fire after #90. rated 60/65/55/75. → [GH-91-RELAY-SCRATCH-DIR.md](PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md) · [#91](https://github.com/HiQS-Suite/XYZ-forge/issues/91)
./ROADMAP.md:176:- **GH-101 · Feasibility Study: Promoting Programmatic Script Runner (`script_runner.py`) into Core Relay & Consult Runtimes** ✅ **SHIPPED 2026-08-20 (issue closed)** — evaluated and promoted programmatic tool mode across `consult.py` and `relay_drive.py` behind `--tool-mode programmatic` (default off); completed 3-test qualification ladder (Test 1 architectural review & fail-closed threat scoping; Test 2 consult dogfooding with throwaway worktree isolation, pre-created `.relay-scratch/`, and 1,935-trial paired density benchmark in `TESTS-RESULTS/2026-08-20+GH-101/`; Test 3 relay-drive PGID process cleanup stress and fail-closed sandbox checks in `test/synthetic/gh101-relay-programmatic-stress.sh`); promoted to Production-Ready (A-Grade) in `HARNESS-MODELS-REGISTRY.md`. → [GH-101-FEASIBILITY-STUDY-SCRIPT-RUNNER.md](PROJECT/3-COMPLETED/GH-101-FEASIBILITY-STUDY-SCRIPT-RUNNER.md) · [#101](https://github.com/HiQS-Suite/XYZ-forge/issues/101)
./ROADMAP.md:182:- **GH-45 · validate.sh must refuse to run from a linked worktree — an observed run corrupted the parent clone** ✅ **SHIPPED 2026-08-18 (PR #55, built on `development` in clone `XYZ-forge-gh35`; issue closed 2026-08-19)** — `validate.sh` AND `ci-local.sh` now refuse (exit 2, before anything runs, every tier) when invoked from a linked git worktree, using the issue's verified `--absolute-git-dir` vs `--git-common-dir` comparison anchored on both HERE and the CWD. The refusal names the observed 2026-08-19 damage (core.bare=true, origin repointed, remote refs deleted, development overwritten with fixture commits); `XYZ_ALLOW_WORKTREE_GATE=1` overrides and announces itself. Pinned in `test/gh35-test-tiers.sh` §9 incl. the required control (normal checkout of the same repo still runs, silently). → [GH-45-WORKTREE-GATE-REFUSAL.md](PROJECT/3-COMPLETED/GH-45-WORKTREE-GATE-REFUSAL.md) · [#45](https://github.com/HiQS-Suite/XYZ-forge/issues/45) · [#564](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/564)
./LEADERBOARD.md:21:| 9 | **285** | [GH-141](https://github.com/HiQS-Suite/XYZ-forge/issues/141) — make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison | Bulkhead | ad-hoc detour | 80 | 65 | 85 | 55 | 285 | — |
./LEADERBOARD.md:29:| 17 | **275** | [GH-2](https://github.com/HiQS-Suite/XYZ-forge/issues/2) — test-suite run relocated an untracked file into .tick/orphan-backups/ | Bulkhead | in progress | 80 | 55 | 85 | 55 | 275 | — |
./LEADERBOARD.md:31:| 19 | **270** | GH-184 — committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation | Bulkhead | queue | 60 | 40 | 80 | 90 | 270 | — |
./AGENTS.md:138:  snapshots the doomed tracked files into `.tick/orphan-backups/` before the command runs, so
./AGENTS.md:157:  worktree teardown; it accumulates silently across sessions until nobody can say which agent or
./audit/repro.sh:204:# teardown is the EXIT trap; this only reports what it will do
./PROJECT/3-COMPLETED/GH-181-REPRO-ADAPTER-FIDELITY.md:28:Release 0.7.3 "Bulkhead" manifest member. Gen 3.5 soak (#177 §3.2, probe B2): a real GH-141
./PROJECT/3-COMPLETED/GH-181-REPRO-ADAPTER-FIDELITY.md:37:`TESTS-RESULTS/2026-08-22+GH-141/error_log.jsonl` (record 1). The builder manufactured a
./PROJECT/3-COMPLETED/GH-181-REPRO-ADAPTER-FIDELITY.md:46:3. `test/gh181-repro-adapter-fidelity.sh`: the GH-141 record (committed fixture) builds a
./PROJECT/3-COMPLETED/GH-181-REPRO-ADAPTER-FIDELITY.md:52:The GH-141 record builds a reproducer that reproduces the actual agy `--help` exit-2 failure
./PROJECT/3-COMPLETED/GH-181-REPRO-ADAPTER-FIDELITY.md:65:  "remediation":   { "source": "self#plan", "criteria": "the committed GH-141 record builds a reproducer that reproduces the exit-2 failure; signature matching rejects wrong-cause rc coincidence" },
./PROJECT/3-COMPLETED/GH-181-REPRO-ADAPTER-FIDELITY.md:76:rejects wrong-cause rc coincidence and an end-to-end test against a real committed GH-141
./PROJECT/3-COMPLETED/GH-111-DIALED-IN.md:492:and applied.** The verification round FAILED — the lane produced no findings and its salvage appended
./PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md:25:  Migrate static HARNESS-MODELS-REGISTRY.md into an active SQLite ledger (harnesses.db)
./PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md:36:| Phase 1-5 implemented: `harnesses.db` schema, CLI `harness_app.py`, 3-tier config `device_config.py`, telemetry `harness_turn_logger.py`, AI grading hooks, blog generator, and 6/6 test assertions passing in `test/gh174-harness-registry.sh`. | Full validation gate run and pull request merge. |
./PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md:50:3. **Dual Storage & Reversibility:** SQLite `harnesses.db` paired with human-readable, lossless `harnesses.sql` dump and generated `HARNESS-MODELS-REGISTRY.generated.md`.
./PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md:151:- **Phase 1 (Core Schema & CLI Engine):** Implement `utils/py/harness_app.py`, `harnesses.db`, `harnesses.sql`, and `harness check` integrity tests.
./PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md:15:  .relay-scratch/ — exempted like the other intrinsic write categories, pre-created by
./PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md:30:| **BUILT 2026-08-20 (linked worktree `XYZ-forge-gh91`, branch `fix/gh91-relay-scratch`)** — issue option 1 implemented across all four surfaces: `rtl_worktree_begin` pre-creates `.relay-scratch/` in the isolated worktree (the affordance physically exists, not prose); `rtl_worktree_end` exempts it intrinsically (no signature check — it is *meant* to be written, unlike the read-only `.relay-artifacts/` seed) and never copies it back; `rtl_check` on the non-worktree path exempts AND discards it (`rm -rf` — it lives in ROOT there and must neither linger nor ride into a commit); `rtl_turn_prompt` names it at the point of use with its disposition. `.gitignore` carries `.relay-scratch/` as defense in depth (the exemption is intrinsic in code and does not depend on it, per the `.tick` lesson). New suite `test/gh91-relay-scratch.sh` **15/0** with controls: stray writes still violate, lookalike prefix `.relay-scratch2` is NOT exempt, off-lane worktree turns still copy nothing back. Containment-pinning neighbors re-run green (worktree-isolation 33/0, shim-worktree 32/0, relay-artifact-file 13/0, rtl-orphan-backup 8/0, gh410 11/0, path-overlap, relay-xyz-skill-guard, untracked-file-warn, seeding-visibility, relay-target-root). | Full gate from a NORMAL clone (GH-45 refuses it from this worktree — by design), then PR into `development`. Watch the next daybreak re-fire: the builder should now put probe output in `.relay-scratch/` because the prompt says so at the point of use. If a lane still writes scratch elsewhere, that is a prompt-weighting question for GH-77's briefs, not a missing facility. |
./PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md:45:`.relay-scratch/`, treated as an intrinsic write category:
./PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md:49:| `rtl_worktree_begin` | `mkdir -p "$wt/.relay-scratch"` — the affordance physically exists before the turn starts |
./PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md:51:| `rtl_check` (non-worktree) | exempt AND discard: `rm -rf "${RTL_ROOT:?}/.relay-scratch"` — the transcript-log drop is the precedent; `${RTL_ROOT:?}` guards the empty-prefix `rm -rf` (GH-567) |
./PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md:53:| `.gitignore` | ~~`.relay-scratch/`~~ — **REVERTED in review**: the entry hid the dir from porcelain, so `rtl_enforce`'s per-path `rtl_check` discard never fired and scratch lingered in ROOT forever (the reviewer reproduced it end-to-end). The real guarantee is the unconditional sweep in `rtl_enforce`, independent of git visibility |
./PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md:59:| `test/gh91-relay-scratch.sh` (new, registered in TESTS same commit) | **22/0** — lib-function level, no builder binary: scratch not a violation + discarded + lane edit untouched (both the file and collapsed-dir status forms); CONTROLS: stray write still exit-6s and is reverted, `.relay-scratch2` lookalike not exempt, worktree stray still off-lane with copyback withheld; begin pre-creates the dir; end exempts without copying back; prompt names the room and its disposition. **PR #93 review round:** prompt template renders EXACTLY once (printf arg/conversion cardinality — bash recycles the format and a 14th arg without a 14th `%s` doubled the whole template garbled; the old substring greps passed through that, so the pins are cardinality + position now), and an INTEGRATION case through `rtl_enforce` with `.relay-scratch/` gitignored: turn passes (exit 0), ignored scratch still discarded, lane edit committed file-scoped |
./PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md:82:  prefixes (`.relay-scratch2`) still fail — otherwise the fix would just relocate the hole.
./docs/ROADMAP-UPSTREAM-ARCHIVE.md:34:- **GH-527 · a destructive git command has no guard, and a doc rail demonstrably will not fix it** ✅ **BUILT 2026-08-14 on `fix/critical-2026-08-14`** — snapshot-then-allow PreToolUse hook copies the doomed *tracked* files into `.tick/orphan-backups/` before the command runs (the GH-141 `rtl_check` precedent), plus the `AGENTS.md` rail naming all three spellings. 26/0; recovery demonstrated end-to-end; clean-tree silence is defended by two conditions so it took a combined mutation to falsify. → [GH-527-DESTRUCTIVE-GIT-GUARD.md](PROJECT/2-WORKING/GH-527-DESTRUCTIVE-GIT-GUARD.md) · [#527](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/527)
./docs/ROADMAP-UPSTREAM-ARCHIVE.md:242:- **GH-251 · OpenRouter/aider reviewer seam doesn't persist its review (builder-only in practice)** ✅ **SHIPPED — closed 2026-07-21** (commit `cf7a123`, merged PR #256; NOTE: live-OpenRouter-model verification remains an outstanding operator step, not claimed done) — found during a live multi-turn `/relay-xyz` GLM 5.2 QA of the 2026-07-19 marathon: aider produces a correct review in-transcript but its relay-file append is lost through repomap-wandering + worktree containment, so `--review-once` correctly scores it a stall (a live confirmation of GH-245, not a classifier bug). Fix: a review-mode / transcript-salvage for `aider-turn.sh`, or document builder-only and route reviews to codex/agy. cx/risk/eff 2/2/2. → [GH-251-OPENROUTER-AIDER-REVIEWER-SEAM.md](PROJECT/3-COMPLETED/GH-251-OPENROUTER-AIDER-REVIEWER-SEAM.md) · [#251](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/251)
./docs/ROADMAP-UPSTREAM-ARCHIVE.md:362:- **GH-141 · Containment: rtl_enforce's pre-turn dirty snapshot can't see a concurrent peer session's edit that lands mid-turn, reverting it as off-lane** 🆕 **captured 2026-07-05** — `rtl_before()` snapshots `git status --porcelain` once at turn start so `rtl_enforce` can exempt pre-existing ambient WIP; it can't see an independent session's edit landing *during* a turn's execution window, so `rtl_check()` reverts it directly in `$RTL_ROOT` as if the agent made an off-lane edit itself. Live incident: a review-only agy turn reverted a concurrent Claude Code session's in-progress edit to `PROJECT/1-INBOX/PEER-RESEARCH.md`; recovered by hand (content still visible in scrollback), not recoverable in general. Real but narrow — needs a driven turn AND a second live session hand-editing the same clone simultaneously; same family as the already-guarded concurrent-commits race, but for uncommitted edits. Found reviewing **#140**. **Investigated 2026-07-17 by `/10days` — no fix shipped, deliberately.** No code-only signal can distinguish a peer session's concurrent edit from the agent's own off-lane self-escape (both produce identical porcelain diffs), and `rtl_enforce`'s revert is the documented backstop for a real, already-exploited self-escape vector (GH-22) — a naive fix would silently disable that protection. Two non-detection follow-ups recorded for an operator decision: a recoverable backup-before-revert, and documenting the don't-hand-edit-a-live-clone constraint. Still open, still not marathon-ready. cx/risk/eff 2/2/2 (provisional). → [GH-141-CONCURRENT-PEER-EDIT-RACE.md](PROJECT/2-WORKING/GH-141-CONCURRENT-PEER-EDIT-RACE.md) · [#141](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/141)
./docs/ROADMAP-UPSTREAM-ARCHIVE.md:457:- **GH-240 · PDDA-compatible marathon triage and cleanup skills** ✅ **SHIPPED 2026-07-18** — `marathon-triage` is now repo-owned and remains read-only/plan-only; new `marathon-cleanup` reconciles canonical docs, terminal frontmatter/status, GitHub issue and PR state, reachable commits, verification, and CHANGELOG evidence before proposing any move. It distinguishes a completed marathon slice from a fully completed issue, requires every lane to verify before archiving the parent, and defaults to confirmation-gated mutation. Both Claude entries symlink to this clone through idempotent installers. Skill validators, ShellCheck, file-scoped PDDA checks, and `./validate.sh` 115/115 passed. cx/risk/eff 2/2/2. → [GH-240-MARATHON-SKILLS.md](PROJECT/3-COMPLETED/GH-240-MARATHON-SKILLS.md) · [#240](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/240)
./test/gh527-destructive-git-guard.sh:57:SNAP="$(ls -d "$R"/.tick/orphan-backups/*/ 2>/dev/null | head -1 || true)"
./test/gh527-destructive-git-guard.sh:82:   "[ -z \"\$(ls -d '$C'/.tick/orphan-backups/*/ 2>/dev/null || true)\" ]"
./PROJECT/3-COMPLETED/GH-101-FEASIBILITY-STUDY-SCRIPT-RUNNER.md:32:- [x] Integration touchpoints named (`utils/py/consult.py`, `.relay-scratch/`, `relay-turn-lib`/`relay-drive`).
./PROJECT/3-COMPLETED/GH-101-FEASIBILITY-STUDY-SCRIPT-RUNNER.md:39:- [x] Fail-closed containment: `consult.py` enforces throwaway worktree isolation, pre-creates `.relay-scratch/`, and refuses to run if sandbox engines are absent when programmatic mode is requested.
./skills/relay-xyz/SKILL.md:485:**Never hand-edit a clone while a driven turn is in flight there (GH-141).** `rtl_before()` snapshots
./skills/relay-xyz/SKILL.md:492:content is copied to `.tick/orphan-backups/<utc>-<pid>/<path>` first, so a wrongly-caught edit is
./TESTS-RESULTS/2026-08-23+GH-174/gh174-validate-baseline.log:150:[parallel] gh91-relay-scratch.sh rc=0
./TESTS-RESULTS/2026-08-23+GH-174/gh174-validate-baseline.log:469:  + gh91-relay-scratch.sh
./TESTS-RESULTS/2026-08-23+GH-174/README.md:12:  real-turn log, sample GH-141 record)
./PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:39:2. **Soft-Quarantine with Automated Reaper:** Untracked/ignored contents (`.relay-scratch/`) and swept full clones are moved into `.xyz/trash/<timestamp>-<name>/`. Each sweep run automatically reaps trash directories older than 72h (`find .xyz/trash/ -mtime +3 -delete`); immediate hard purge is available via `--purge-trash`.
./PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:114:     - Archives untracked/ignored files (`.relay-scratch/`) to `.xyz/trash/$(date +%Y%m%d-%H%M%S)-$(basename "$p")/`.
./PROJECT/3-COMPLETED/GH-45-WORKTREE-GATE-REFUSAL.md:28:| **BUILT 2026-08-18 (clone `XYZ-forge-gh35`, `development`)**: `validate.sh` and `ci-local.sh` refuse to run from a linked git worktree — exit 2, before anything executes, in every tier. Detection is the issue's verified one-liner (`--absolute-git-dir` vs a resolved `--git-common-dir`, the GH-448 resolver's idiom), anchored on BOTH `HERE` and the invocation CWD so an absolute-path invocation from outside the worktree cannot slip past. The message names the observed 2026-08-19 damage (core.bare=true, origin repointed at a deleted temp path, every `refs/remotes/origin/*` deleted, `development` overwritten with fixture commits); `XYZ_ALLOW_WORKTREE_GATE=1` overrides and announces itself. Pinned in `test/gh35-test-tiers.sh` §9 (suite now 67/0), including the issue's required control: the normal checkout of the SAME fixture repo still runs, silently. | GH-564 owns the per-suite fixture-escape audit — this guard is deliberately outer and stays valuable after every suite is fixed (it fails closed for suites nobody has audited yet). The incident's doc record lives on the `docs/worktree-gate-safety` lane (separate branch). Revisit whether `githooks/pre-push`'s fallback (which execs validate.sh) needs its own wording once a real worktree push is observed. |
./validate.sh:183:  "gh426-worktree-leak.sh"       # GH-426 (an isolated turn's creation is absent from BOTH the target and the harness) — 7/0; control in test/baselines/GH-426-negative-control.md: 2 red here + 1 red in gh410's C4c. The reported cause (worktree teardown) is FALSIFIED and the suite pins the real one: the agent binary is invoked twice, and the GH-375 auth probe ran with the caller's CWD, outside containment
./validate.sh:212:  "gh527-destructive-git-guard.sh"     # GH-527 (a tree-overwriting git command snapshots the tracked files it destroys into .tick/orphan-backups/ first) — 26/0; controls: a no-op guard drops 9 assertions, and a blanket that fires on a CLEAN tree drops exactly the control assertion. Clean-tree silence is defended by TWO conditions, so it takes a combined mutation to falsify — recorded in test/baselines/GH-527-negative-control.md
./validate.sh:217:  "rtl-orphan-backup.sh"         # GH-141 (concurrent peer-edit race: revert unchanged, content recoverable)
./validate.sh:218:  "gh91-relay-scratch.sh"          # GH-91 (sanctioned .relay-scratch/ for builder verification output: exempted in rtl_check + rtl_worktree_end, pre-created by begin, named in the turn prompt; never copied back, discarded under ROOT; controls pin that stray writes and lookalike prefixes still go off-lane) — 15/0, driven at the lib-function level, no builder binary needed
./validate.sh:249:  "gh184-no-tracked-scratch.sh"         # #184 (derived guard: nothing under the disposable .relay-scratch/ lane is ever tracked)
./test/gh91-relay-scratch.sh:2:# test/gh91-relay-scratch.sh — GH-91: a sanctioned scratch dir for builder verification output.
./test/gh91-relay-scratch.sh:12:# The fix (issue option 1): `.relay-scratch/` — exempted in rtl_check and rtl_worktree_end
./test/gh91-relay-scratch.sh:23:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh91-relay-scratch.XXXXXX")"
./test/gh91-relay-scratch.sh:55:mkdir -p "$R/.relay-scratch"
./test/gh91-relay-scratch.sh:56:printf '{"lens":2}\n' >"$R/.relay-scratch/out2.json"      # the probe output that killed the real turn
./test/gh91-relay-scratch.sh:57:printf '{"lens":3}\n' >"$R/.relay-scratch/out3.json"
./test/gh91-relay-scratch.sh:59:rtl_check ".relay-scratch/out2.json"
./test/gh91-relay-scratch.sh:62:[ ! -d "$R/.relay-scratch" ] && pass "rtl_check: the scratch dir is DISCARDED from ROOT (not committed, not lingering)" \
./test/gh91-relay-scratch.sh:67:# The collapsed-dir form (git shows ".relay-scratch/" when the dir is wholly untracked) — same branch.
./test/gh91-relay-scratch.sh:68:mkdir -p "$R/.relay-scratch"; printf 'x\n' >"$R/.relay-scratch/probe.json"
./test/gh91-relay-scratch.sh:70:rtl_check ".relay-scratch/"
./test/gh91-relay-scratch.sh:71:[ "$RTL_VIOLATION" -eq 0 ] && [ ! -d "$R/.relay-scratch" ] \
./test/gh91-relay-scratch.sh:72:  && pass "rtl_check: the collapsed '.relay-scratch/' status form is exempted and discarded too" \
./test/gh91-relay-scratch.sh:79:[ "$RTL_VIOLATION" -eq 1 ] && pass "CONTROL: a stray file OUTSIDE .relay-scratch still violates (exit-6 path intact)" \
./test/gh91-relay-scratch.sh:84:mkdir -p "$R/.relay-scratch2"; printf 'x\n' >"$R/.relay-scratch2/out.json"
./test/gh91-relay-scratch.sh:86:rtl_check ".relay-scratch2/out.json"
./test/gh91-relay-scratch.sh:87:[ "$RTL_VIOLATION" -eq 1 ] && pass "CONTROL: '.relay-scratch2' (lookalike prefix) is NOT exempt" \
./test/gh91-relay-scratch.sh:88:  || fail "CONTROL: lookalike prefix .relay-scratch2 slipped the exemption"
./test/gh91-relay-scratch.sh:94:[ -d "$wt/.relay-scratch" ] && pass "rtl_worktree_begin: the scratch dir EXISTS in the worktree (affordance, not prose)" \
./test/gh91-relay-scratch.sh:98:printf '{"lens":2}\n' >"$wt/.relay-scratch/out2.json"
./test/gh91-relay-scratch.sh:100:[ "$RTL_WT_OFFLANE" -eq 0 ] && pass "rtl_worktree_end: probe output in .relay-scratch is NOT off-lane" \
./test/gh91-relay-scratch.sh:104:[ ! -e "$R/.relay-scratch" ] && pass "rtl_worktree_end: scratch is NEVER copied back to ROOT" \
./test/gh91-relay-scratch.sh:120:grep -q '.relay-scratch' <<<"$(printf '%s' "$out")" \
./test/gh91-relay-scratch.sh:133:[ "$(printf '%s' "$out" | grep -c '.relay-scratch')" -eq 1 ] \
./test/gh91-relay-scratch.sh:135:  || fail "rtl_turn_prompt: scratch note appears $(printf '%s' "$out" | grep -c '.relay-scratch') times"
./test/gh91-relay-scratch.sh:141:# The reviewer's exact reproduction: a repo whose .gitignore hides .relay-scratch/ never shows
./test/gh91-relay-scratch.sh:151:printf '.relay-scratch/\n' >"$E/.gitignore"
./test/gh91-relay-scratch.sh:158:mkdir -p "$E/.relay-scratch"; printf 'probe\n' >"$E/.relay-scratch/out.json"
./test/gh91-relay-scratch.sh:159:[ -z "$(git -C "$E" status --porcelain -- .relay-scratch)" ] \
./test/gh91-relay-scratch.sh:165:[ ! -d "$E/.relay-scratch" ] && pass "rtl_enforce: ignored scratch is STILL discarded (unconditional sweep)" \
./test/gh91-relay-scratch.sh:173:echo "  gh91-relay-scratch: $PASS pass, $FAIL fail"
./PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:2:title: "GH-184: committed scratch artifact .relay-scratch/probe_telemetry.json makes every real turn a tracked-file mutation"
./PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:7:goal: nothing under the sanctioned-disposable .relay-scratch/ lane is ever tracked, so its by-design discard can never dirty a clone
./PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:29:committed `.relay-scratch/probe_telemetry.json`. A shim driven through its real-turn path
./PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:31:`.relay-scratch/` deletes the tracked file — a success-shaped exit plus a tracked-file mutation,
./PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:38:.relay-scratch/probe_telemetry.json` after one real-turn run).
./PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:42:1. `git rm .relay-scratch/probe_telemetry.json` — it is regenerable probe output; the lane is
./PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:45:   .relay-scratch/` every run (empty required; mirrors gh1-adoption-guard's derived-from-source
./PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:52:`git ls-files .relay-scratch/` returns nothing; gh184 guard green and registered; soak §3.5
./PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:62:  "artifacts":     [ ".relay-scratch/probe_telemetry.json", "test/gh184-no-tracked-scratch.sh", "validate.sh" ],
./PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:64:  "remediation":   { "source": "self#plan", "criteria": "no .relay-scratch/ content tracked; derived guard green; real-turn repro leaves git status clean" },
./PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:65:  "lanes":         { "agy_safe": [ "test/gh184-no-tracked-scratch.sh" ], "orchestrator_only": [ ".relay-scratch/", "validate.sh" ] }
./PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:71:One tracked scratch file (`.relay-scratch/probe_telemetry.json`) made every real agent turn a
./PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:74:nothing under `.relay-scratch/` is ever tracked — the guard matters more than the removal, because
./PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md:32:in the tree root; `rtl_check()` reverted them into `.tick/orphan-backups/` and failed the turn
./PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md:44:   provision a per-turn scratch dir (`.relay-scratch/<turn>/`,
./PROJECT/2-WORKING/GH-141-FUZZ-ATE-UTILITY.md:26:# GH-141: make the fuzzing and ATE subsystems actually useful
./test/gh184-no-tracked-scratch.sh:2:# GH-184: nothing under the sanctioned-disposable .relay-scratch/ lane is ever tracked, so its
./test/gh184-no-tracked-scratch.sh:4:# come from `git ls-files .relay-scratch/` every run — no hand-maintained exception list.
./test/gh184-no-tracked-scratch.sh:5:# Pre-fix state: PR #160 had committed .relay-scratch/probe_telemetry.json (see
./test/gh184-no-tracked-scratch.sh:25:# 1. The real repo must track nothing under .relay-scratch/
./test/gh184-no-tracked-scratch.sh:26:TRACKED="$(git -C "$ROOT" ls-files .relay-scratch/)"
./test/gh184-no-tracked-scratch.sh:28:  pass "repo tracks nothing under .relay-scratch/"
./test/gh184-no-tracked-scratch.sh:36:mkdir -p "$FIX/.relay-scratch"
./test/gh184-no-tracked-scratch.sh:41:printf '{}' > "$FIX/.relay-scratch/probe.json"
./test/gh184-no-tracked-scratch.sh:42:git -C "$FIX" add .relay-scratch/probe.json
./test/gh184-no-tracked-scratch.sh:44:BAD="$(git -C "$FIX" ls-files .relay-scratch/)"
./marathon-system/p1-gh115/RELAY.md:60:- **`utils/py/relay_drive.py`**: Added logic to write `### Extension · System` to the relay file so that it's reliably captured in the durable archive by `save_transcript()`. Also added a structured reason channel by writing to `.relay-scratch/escalation-reason` before any exit 4.
./marathon-system/p1-gh115/RELAY.md:61:- **`utils/py/marathon_drive.py`**: Modified the `relay_exit == 4` block to read `.relay-scratch/escalation-reason` to distinctively log and pass the specific reason down instead of mapping everything blindly to `cap-or-close-mismatch`. Changed the `argparse` default for `--round-cap` to `None` to fix the CLI precedence overwrite defect.
./marathon-system/p1-gh115/RELAY.md:81:- **`utils/py/relay_drive.py`**: Added an `exit_escalate(reason)` helper to ensure all `sys.exit(4)` paths publish a distinct reason to `.relay-scratch/escalation-reason` before exiting. Updated existing escalation exits to use this helper.
./marathon-system/p1-gh115/RELAY.md:82:- **`utils/py/marathon_drive.py`**: Changed the `relay_exit == 4` block to read `.relay-scratch/escalation-reason` under `xyz_harness` rather than `root`, ensuring paths match in a vendored layout. Added clearing of any stale `escalation-reason` file before launching `relay_drive`.
./marathon-system/p1-gh115/RELAY.md:94:2. The producer and consumer now resolve `.relay-scratch/escalation-reason` from their source-derived harness root (`root_dir` / `xyz_harness`), which is the same `.xyz` directory in the supported vendored layout. `marathon_drive.py` clears the channel before every relay launch, preventing a prior run's reason from being reused.
./ARCHITECTURE/git-history-diagram.html:1230:      "label": "fix(aider-turn): review mode + transcript salvage so review turns land, not stall (GH-251)",
./ARCHITECTURE/git-history-diagram.html:1237:      "description": "fix(aider-turn): review mode + transcript salvage so review turns land, not stall (GH-251)\ncf7a123ae0bcfc29f525d2af167521765e136b95\nNoel Saw \u00b7 2026-07-19T21:14:23-07:00"
./PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md:2:title: "GH-2: test-suite run relocated an untracked file into .tick/orphan-backups/"
./PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md:19:# GH-2 — untracked file relocated into .tick/orphan-backups/
./PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md:34:`.tick/orphan-backups/`. Observed once, not yet reproduced. Same family as #1's sandbox
./test/gh388-run-log-durability.sh:196:# backgrounded it normally and the test itself exited 143: the driver's teardown signals its process
./evidence/00-environment.md:281:cd0f5bd Merge pull request #93 from HiQS-Suite/fix/gh91-relay-scratch
./test/gh410-containment-advisory.sh:174:  # The cause was not worktree teardown, which was the standing hypothesis. The agent binary is
./PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md:225:- #141 GH-141 · Containment: rtl_enforce's pre-turn dirty snapshot can't see a concurrent peer session's edit that lands mid-turn, reverting it as off-lane — `blocked`
./test/gh181-repro-adapter-fidelity.sh:3:# the real GH-141 record is the TOKENIZATION fixture (its underlying defect was fixed by GH-156 —
./test/gh181-repro-adapter-fidelity.sh:45:# The real GH-141 failure record, verbatim shape (joined command string; the absolute path
./test/gh181-repro-adapter-fidelity.sh:53:# 1. TOKENIZATION: the GH-141 record's spaced path survives parsing as ONE argv token,
./test/gh181-repro-adapter-fidelity.sh:67:  pass "GH-141 spaced-path record tokenizes to repo-relative argv without splitting"
./PROJECT/2-WORKING/MARATHON-PLAN-2026-08-23.md:52:| [#184] GH-184 · committed scratch artifact .relay-scratch/probe_telemetry.json makes every real turn a tracked-file mutation | 1 | 1 | 1 | kernel | — | 7 | 2 |
./PROJECT/2-WORKING/MARATHON-PLAN-2026-08-23.md:104:- #2 GH-2 · test-suite run relocated an untracked file into .tick/orphan-backups/ — `not-ready`
./PROJECT/2-WORKING/MARATHON-PLAN-2026-08-23.md:107:- #141 GH-141 · make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison — `needs-contract`
./test/baselines/GH-181-negative-control.md:3:Soak evidence: #177 §3.2 (probe B2). A real GH-141 failure record — `command`
./test/baselines/GH-181-negative-control.md:14:2026-08-23 amendment: the GH-141 record's underlying defect is historical
./evidence/10-validate-sequential-clean.log:834:  PASS: GH-251: transcript review salvaged into the relay file (attributed)
./evidence/10-validate-sequential-clean.log:835:  PASS: GH-251: salvaged block carries the graded verdict
./evidence/10-validate-sequential-clean.log:836:  PASS: GH-251: salvaged review committed (turn lands, not a stall)
./evidence/10-validate-sequential-clean.log:838:  PASS: GH-251: non-review turn not salvaged (no false rescue)
./evidence/10-validate-sequential-clean.log:3471:test-turn: pre-revert copy of PROJECT/peer.md saved under /tmp/rtl-orphan-backup.MLGfRY/repo/.tick/orphan-backups/20260820T145041Z-10872
./evidence/10-validate-sequential-clean.log:3473:test-turn: pre-revert copy of PROJECT/peer-new.md saved under /tmp/rtl-orphan-backup.MLGfRY/repo/.tick/orphan-backups/20260820T145041Z-10872
./evidence/10-validate-sequential-clean.log:3486:Running gh91-relay-scratch.sh
./evidence/10-validate-sequential-clean.log:3491:  PASS: rtl_check: the collapsed '.relay-scratch/' status form is exempted and discarded too
./evidence/10-validate-sequential-clean.log:3493:test-turn: pre-revert copy of stray.txt saved under /tmp/gh91-relay-scratch.FjgW4z/repo/.tick/orphan-backups/20260820T145041Z-10920
./evidence/10-validate-sequential-clean.log:3494:  PASS: CONTROL: a stray file OUTSIDE .relay-scratch still violates (exit-6 path intact)
./evidence/10-validate-sequential-clean.log:3496:test-turn: OFF-ALLOWLIST change: .relay-scratch2/out.json — reverting
./evidence/10-validate-sequential-clean.log:3497:test-turn: pre-revert copy of .relay-scratch2/out.json saved under /tmp/gh91-relay-scratch.FjgW4z/repo/.tick/orphan-backups/20260820T145041Z-10920
./evidence/10-validate-sequential-clean.log:3498:  PASS: CONTROL: '.relay-scratch2' (lookalike prefix) is NOT exempt
./evidence/10-validate-sequential-clean.log:3500:  PASS: rtl_worktree_end: probe output in .relay-scratch is NOT off-lane
./evidence/10-validate-sequential-clean.log:3518:  gh91-relay-scratch: 22 pass, 0 fail
./evidence/10-validate-sequential-clean.log:6468:  + gh91-relay-scratch.sh
./test/baselines/GH-184-negative-control.md:4:`.relay-scratch/probe_telemetry.json`. A shim driven through its real-turn path
./test/baselines/GH-184-negative-control.md:7:`.relay-scratch/` deleted the tracked file:
./test/baselines/GH-184-negative-control.md:10:    -> exit 0; git status: ' D .relay-scratch/probe_telemetry.json'
./test/baselines/GH-184-negative-control.md:13:(`git ls-files .relay-scratch/` must be empty, negative control on a fixture
./ARCHITECTURE/git-history-diagram.json:231:      "label": "fix(aider-turn): review mode + transcript salvage so review turns land, not stall (GH-251)",
./ARCHITECTURE/git-history-diagram.json:238:      "description": "fix(aider-turn): review mode + transcript salvage so review turns land, not stall (GH-251)\ncf7a123ae0bcfc29f525d2af167521765e136b95\nNoel Saw · 2026-07-19T21:14:23-07:00"
./test/aider-turn.sh:67:# relay file is never edited. reviewphantom carries a Verdict anchor (must be salvaged); reviewnoop is
./test/aider-turn.sh:68:# non-review chatter with no anchor and no edit (must NOT be salvaged).
./test/aider-turn.sh:374:# lands it in the relay file -> the shim salvages the review from the transcript and appends it
./test/aider-turn.sh:377:git -C "$A" add relay.md >/dev/null 2>&1; git -C "$A" commit -q -m "reseed relay for GH-251 salvage" >/dev/null 2>&1
./test/aider-turn.sh:381:[ "$rc" -eq 0 ] && pass "GH-251: review-only phantom-review turn exits 0" || fail "GH-251 salvage turn rc=$rc"
./test/aider-turn.sh:382:grep -q "salvaged from" "$A/relay.md" && pass "GH-251: transcript review salvaged into the relay file (attributed)" || fail "GH-251: review not salvaged into relay.md"
./test/aider-turn.sh:383:grep -q "Verdict: Changes requested" "$A/relay.md" && pass "GH-251: salvaged block carries the graded verdict" || fail "GH-251: verdict text not salvaged"
./test/aider-turn.sh:384:[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "GH-251: salvaged review committed (turn lands, not a stall)" || fail "GH-251: salvage produced no commit"
./test/aider-turn.sh:388:# and no relay edit must NOT be salvaged — a non-review turn is still a genuine stall (composes with the
./test/aider-turn.sh:395:grep -q "salvaged from" "$A/relay.md" && fail "GH-251: a non-review turn must NOT be salvaged (no Verdict anchor)" || pass "GH-251: non-review turn not salvaged (no false rescue)"
./README.md:433:- `skills/marathon-triage/`, `skills/marathon-cleanup/`, `skills/10days/` — the marathon operator
./README.md:436:  evidence after a run ([`marathon-cleanup`](skills/marathon-cleanup/SKILL.md)); and — the one deliberate,
./utils/ate/scripts/compile_issue.py:55:        # alias of the top-level field (the third alias GH-141's review counted), and stripping
./test/gh426-worktree-leak.sh:4:# The issue's headline reading is that worktree teardown leaks the creation into the harness repo.
./test/gh426-worktree-leak.sh:18:# on every invocation; real `agy whoami` does not, which is why this looked like a teardown defect.
./relay-system/2026-08-18/merge-order-230056/merge-order.codex.md:1142:   140	  "gh426-worktree-leak.sh"       # GH-426 (an isolated turn's creation is absent from BOTH the target and the harness) — 7/0; control in test/baselines/GH-426-negative-control.md: 2 red here + 1 red in gh410's C4c. The reported cause (worktree teardown) is FALSIFIED and the suite pins the real one: the agent binary is invoked twice, and the GH-375 auth probe ran with the caller's CWD, outside containment
./relay-system/2026-08-18/merge-order-230056/merge-order.codex.md:1169:   167	  "gh527-destructive-git-guard.sh"     # GH-527 (a tree-overwriting git command snapshots the tracked files it destroys into .tick/orphan-backups/ first) — 26/0; controls: a no-op guard drops 9 assertions, and a blanket that fires on a CLEAN tree drops exactly the control assertion. Clean-tree silence is defended by TWO conditions, so it takes a combined mutation to falsify — recorded in test/baselines/GH-527-negative-control.md
./relay-system/2026-08-18/merge-order-230056/merge-order.codex.md:1173:   171	  "rtl-orphan-backup.sh"         # GH-141 (concurrent peer-edit race: revert unchanged, content recoverable)
./LEADERBOARD.html:375:<script id="ledger-data" type="application/json">{"meta": {"title": "Planning ledgers", "subtitle": "XYZ-forge · releases.db · read-only", "generatedAtDisplay": "2026-08-24 03:30:06Z", "sourceLabel": "releases.db · schema v5", "repoUrl": "https://github.com/HiQS-Suite/XYZ-forge"}, "sync": null, "telemetry": {"dbGeneration": 114, "receipts": 128, "lastSyncDisplay": "2026-08-24T03:30", "lastSyncAgoDisplay": "in 1 day", "releasesOpen": 6, "releasesTotal": 12, "releasesOverdue": 0}, "ratedTasks": [{"id": "GH-67", "title": "Commandcode builder default widened to `--yolo` — closer evaluation → possible build", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 88, "sev": 80, "appeal": 45, "effort": 70, "calc": 283, "effectiveScore": 340}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/67"}, "override": {"value": 340, "hot": true}}, {"id": "GH-181", "title": "repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 90, "sev": 75, "appeal": 90, "effort": 60, "calc": 315, "effectiveScore": 315}, "links": null}, {"id": "GH-174", "title": "Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 85, "sev": 75, "appeal": 95, "effort": 45, "calc": 300, "effectiveScore": 300}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/174"}}, {"id": "GH-155", "title": "3rd Gen ATE & Fuzzing", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 70, "appeal": 90, "effort": 50, "calc": 295, "effectiveScore": 295}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/155"}}, {"id": "GH-165", "title": "Post-Merge Wave & Marathon Lifecycle Reconciler (Docs, ROADMAP, DB, Views, and Planning)", "release": null, "lane": "Completed", "metrics": {"pri": 90, "sev": 80, "appeal": 90, "effort": 35, "calc": 295, "effectiveScore": 295}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/165"}}, {"id": "GH-113", "title": "headless agy builder writes root scratch files, tripping containment (exit 6)", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 85, "sev": 60, "appeal": 85, "effort": 60, "calc": 290, "effectiveScore": 290}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/113"}}, {"id": "GH-148", "title": "DeepSeek Harness (dsh) integration & deepseek-turn shim for OpenRouter DeepSeek V4 Pro", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 75, "appeal": 90, "effort": 40, "calc": 290, "effectiveScore": 290}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/148"}}, {"id": "GH-168", "title": "wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 70, "calc": 290, "effectiveScore": 290}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/168"}}, {"id": "GH-141", "title": "make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison", "release": "Bulkhead", "lane": "ad-hoc detour", "metrics": {"pri": 80, "sev": 65, "appeal": 85, "effort": 55, "calc": 285, "effectiveScore": 285}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/141"}}, {"id": "GH-114", "title": "headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7)", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 80, "sev": 60, "appeal": 80, "effort": 60, "calc": 280, "effectiveScore": 280}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/114"}}, {"id": "GH-115", "title": "marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 75, "sev": 50, "appeal": 85, "effort": 70, "calc": 280, "effectiveScore": 280}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/115"}}, {"id": "GH-180", "title": "repro_builder crashes on timeout telemetry records (exit_code: null → TypeError)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 70, "sev": 45, "appeal": 85, "effort": 80, "calc": 280, "effectiveScore": 280}, "links": null}, {"id": "GH-77", "title": "`/standup` — session-scoped triage: what did I leave open, what is rotting, is the plan still right?", "release": null, "lane": "Completed", "metrics": {"pri": 95, "sev": 70, "appeal": 85, "effort": 30, "calc": 280, "effectiveScore": 280}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/77"}}, {"id": "GH-124", "title": "eliminate end-of-day closeout friction — automated phase QA receipts, auto-PR creation, and clone lifecycle hygiene", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 60, "appeal": 90, "effort": 40, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/124"}}, {"id": "GH-132", "title": "feat(skills): formal /review-xyz code review skill & multi-model harness", "release": null, "lane": "Completed", "metrics": {"pri": 80, "sev": 70, "appeal": 85, "effort": 40, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/132"}}, {"id": "GH-170", "title": "Agent2Agent: close transcript glitches and harden publishing", "release": null, "lane": "Completed", "metrics": {"pri": 75, "sev": 60, "appeal": 85, "effort": 55, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/170"}}, {"id": "GH-2", "title": "test-suite run relocated an untracked file into .tick/orphan-backups/", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 55, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/2"}}, {"id": "GH-8", "title": "kernel boundary hardening — CLI numeric validation, task/agent format contract", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 65, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/8"}}, {"id": "GH-184", "title": "committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 60, "sev": 40, "appeal": 80, "effort": 90, "calc": 270, "effectiveScore": 270}, "links": null}, {"id": "GH-75", "title": "single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 90, "sev": 40, "appeal": 85, "effort": 55, "calc": 270, "effectiveScore": 270}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/75"}}, {"id": "GH-111", "title": "retire manifest FREEZE; tasks and marathons are DIALED IN to exactly one release, as a database state", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 75, "appeal": 70, "effort": 35, "calc": 265, "effectiveScore": 265}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/111"}}, {"id": "GH-182", "title": "self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 55, "calc": 265, "effectiveScore": 265}, "links": null}, {"id": "GH-50", "title": "sandboxed git --track / branch -D half-applies and loses uncommitted work", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 65, "sev": 35, "appeal": 85, "effort": 80, "calc": 265, "effectiveScore": 265}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/50"}}, {"id": "GH-183", "title": "active_explorer env-family fuzzing unsound (base_env={} hardcoded, one always-deferring vector, ambient-env leakage)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 65, "sev": 50, "appeal": 75, "effort": 70, "calc": 260, "effectiveScore": 260}, "links": null}, {"id": "GH-10", "title": "prevent-half of containment: require_fixture adoption across the fixture-creating suites + adoption guard + ci-local identity bracket", "release": null, "lane": "Completed", "metrics": {"pri": 55, "sev": 70, "appeal": 50, "effort": 80, "calc": 255, "effectiveScore": 255}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/10"}}, {"id": "GH-144", "title": "Agent2Agent 3+ participant onboarding + read-only status quick wins", "release": null, "lane": "Completed", "metrics": {"pri": 55, "sev": 30, "appeal": 80, "effort": 90, "calc": 255, "effectiveScore": 255}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/144"}}, {"id": "GH-91", "title": "a build turn has nowhere to write verification output — containment kills a complete, green turn", "release": null, "lane": "Completed", "metrics": {"pri": 60, "sev": 65, "appeal": 55, "effort": 75, "calc": 255, "effectiveScore": 255}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/91"}}, {"id": "GH-153", "title": "RELEASES dashboard sidebar + full-cycle rollup (technical spike)", "release": null, "lane": "Completed", "metrics": {"pri": 70, "sev": 55, "appeal": 80, "effort": 45, "calc": 250, "effectiveScore": 250}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/153"}}, {"id": "GH-197", "title": "two-tier xyz-vendor.sh: Tier 1 core-harness default, Tier 2 opt-in RELEASES overlay + onboarding SOP (GH-105 follow-up)", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 80, "sev": 55, "appeal": 65, "effort": 50, "calc": 250, "effectiveScore": 250}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/197"}}, {"id": "GH-108", "title": "pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override)", "release": "Daybreak", "lane": "cut", "metrics": {"pri": 80, "sev": 50, "appeal": 75, "effort": 40, "calc": 245, "effectiveScore": 245}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/108"}}, {"id": "GH-105", "title": "vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on)", "release": "Cargo", "lane": "queue", "metrics": {"pri": 75, "sev": 50, "appeal": 60, "effort": 45, "calc": 230, "effectiveScore": 230}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/105"}}, {"id": "GH-32", "title": "RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 70, "sev": 50, "appeal": 65, "effort": 35, "calc": 220, "effectiveScore": 220}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/32"}}, {"id": "GH-5", "title": "kernel robustness: node:test unit runner", "release": "Bulkhead", "lane": "ad-hoc detour", "metrics": {"pri": 45, "sev": 40, "appeal": 45, "effort": 80, "calc": 210, "effectiveScore": 210}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/5"}}, {"id": "GH-35", "title": "3-tier test suite selection (docs / utility subsystems / core) + CPU governance", "release": null, "lane": "Completed", "metrics": {"pri": 55, "sev": 45, "appeal": 50, "effort": 45, "calc": 195, "effectiveScore": 195}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/35"}}, {"id": "GH-61", "title": "RELEASES ledger durability hardening (GH-57 follow-up)", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 45, "sev": 55, "appeal": 40, "effort": 50, "calc": 190, "effectiveScore": 190}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/62"}}, {"id": "GH-17", "title": "SOP for evaluating new agent harnesses and frontier models", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 45, "sev": 30, "appeal": 50, "effort": 60, "calc": 185, "effectiveScore": 185}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/17"}}, {"id": "GH-42", "title": "relay automation: supported Commandcode turn-taker", "release": null, "lane": "Completed", "metrics": {"pri": 50, "sev": 35, "appeal": 55, "effort": 45, "calc": 185, "effectiveScore": 185}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/42"}}, {"id": "GH-195", "title": "marathon-root-audit's blind spot: a direct `python3 marathon_drive.py` call", "release": null, "lane": "Completed", "metrics": {"pri": 60, "sev": 40, "appeal": 50, "effort": 20, "calc": 170, "effectiveScore": 170}, "links": null}, {"id": "GH-28", "title": "RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 40, "sev": 35, "appeal": 40, "effort": 55, "calc": 170, "effectiveScore": 170}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/28"}}, {"id": "GH-18", "title": "Harness evaluation: Command Code (cmd) and model matrix", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 35, "sev": 25, "appeal": 45, "effort": 55, "calc": 160, "effectiveScore": 160}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/18"}}], "justFinished": {"issue": "v0.7.2", "title": "Daybreak shipped", "closedDateDisplay": "2026-08-23", "closedAgoDisplay": "today", "issueUrl": "https://github.com/HiQS-Suite/XYZ-forge/issues/77"}, "whatsNext": {"issue": "v0.7.3", "title": "Bulkhead", "note": "target 2026-09-05 · in 13 days", "issueUrl": "https://github.com/HiQS-Suite/XYZ-forge/issues/179"}, "releases": [{"id": "c-0-1-0", "slug": "quicksilver", "name": "Quicksilver", "version": "0.1.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-01", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Quicksilver", "blurb": "Python-authoritative Tier-A twins.", "exit": "Python-authoritative Tier-A twins. Licensed AGPL-3.0-only (`LICENSE`) with a commercial option (`LICENSE-COMMERCIAL.md`), adopted 2026-07-29 post-ship; the pre-existing conflicting `LICENSE.md` was removed 2026-07-30 (#372).", "detours": [], "roadmap": []}, {"id": "c-0-2-0", "slug": "litmus", "name": "Litmus", "version": "0.2.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-14", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Litmus", "blurb": "Make the checks capable of failing.", "exit": "Exit: `bash test/litmus-release.sh --release-gate` exits 0. Red today by design; turning it green is what \"done\" means. Its own negative control is `--mutate-evidence`, which must detect a stripped declaration and an unregistered gate. NOTE the honest limit, stated in that file: the audit proves registration, declaration shape and the absence of false completion claims. It does NOT prove a control was truly observed, because `gate_inventory.py` reads a declaration authored by the same person who wrote the gate. Recorded execution of each control is deliberately out of scope for this release.", "detours": [], "roadmap": []}, {"id": "c-0-3-0", "slug": "nightwatch", "name": "Nightwatch", "version": "0.3.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-14", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Nightwatch", "blurb": "An unattended marathon against a real target repo survives, records, and recovers.", "exit": "Exit: `bash test/nightwatch-release.sh --release-gate` exits 0. BUILT 2026-08-11 and red by design, exactly as Litmus's was; turning it green is what \"done\" means. It has two halves because a metadata audit cannot answer this release's question. Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), and has a RECORDED control under `test/baselines/`; it also cross-checks that this list and the `Manifest:` line below agree, since a boundary that disagrees with itself is not frozen. Half B executes the lifecycle cases rather than auditing them, delegating to the suites that already drive real children and kill them rather than growing a second driver fixture here. Status on 2026-08-11: manifest 8/8 complete; lifecycle 5 passing, 0 NOT COVERED — GOALPOST MET. The last gap was the hostile-target write-set case, closed by #514, which was filed while executing this release and deliberately NOT admitted to the manifest (discovery is not admission); it belongs to the lifecycle list because the exit criterion always named that case — what was missing was a suite driving it. That lane also corrected its own premise: the pre-fix tree does not dispatch a turn first, it dies at the render's `git add` with an unhandled `CalledProcessError` traceback, so the discriminating assertion is the absence of that traceback rather than the absence of a dispatch. Its own negative control is `--mutate-evidence` (34/0), which unregisters a gate and deletes a recorded control in a fixture copy, requires both to be detected, and re-checks the unmutated inputs green in the same run so an always-red detector cannot pass for one. Honest limit, inherited from Litmus: Half A reads a declaration and a filename and cannot know a recorded control was honestly recorded; Half B is what narrows that, and is why this criterion is a command that kills children rather than a checklist.", "detours": [], "roadmap": []}, {"id": "c-0-7-0", "slug": "ballast", "name": "Ballast", "version": "0.7.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-18", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Ballast", "blurb": "Post-launch hardening: the launched repository holds up under a stranger's first run and an outside contributor's first push.", "exit": "Exit: `bash test/ballast-release.sh --release-gate` exits 0. NOT BUILT — writing it is Ballast's first task, before any member is fixed (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. Half A audits the frozen manifest: each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. Half B EXECUTES the stranger's path rather than auditing it: (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. SHIPPED 2026-08-18. `XYZ_BALLAST_STRANGER_RUNS=10 test/ballast-release.sh --release-gate` executed for real against a fresh disposable clone (`~/xyz-disposable/xyz-stranger-clone`): exit 0. Half A: 4 of 4 manifest members complete (#14, #15, #4, #3 — gate/registration/control/CLOSED-issue all confirmed). Half B: 4 of 4 passing (B1: 10/10 consecutive parallel runs with zero failures; B2a: ungated clone warning in-band; B2b: forced-red push refusal; B3: atomic-append cross-process stress case clean) — GOALPOST MET.", "detours": [], "roadmap": []}, {"id": "c-0-7-1", "slug": "bulwark", "name": "Bulwark", "version": "0.7.1", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-19", "extra": null, "itemsTotal": 3, "itemsOpen": 3, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Bulwark", "blurb": "Patch release on Ballast: the RELEASES ledger survives a git merge.", "exit": "Exit: test/gh32-releases-artifacts.sh, test/gh53-releases-merge-resolve.sh, test/gh54-merged-dump-refusals.sh and releases_app.py check all exit 0, AND this release's own merge into development resolves releases.sql without a hand-edit.", "detours": [], "roadmap": [{"id": "GH-52", "title": "issue GH-52", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/52"}}, {"id": "GH-53", "title": "issue GH-53", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/53"}}, {"id": "GH-54", "title": "issue GH-54", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/54"}}]}, {"id": "c-0-7-2", "slug": "daybreak", "name": "Daybreak", "version": "0.7.2", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-23", "extra": null, "itemsTotal": 9, "itemsOpen": 0, "baseline": {"count": 9, "at": "2026-08-21T04:21:29Z", "source": "backfilled", "growth": 0}, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Daybreak", "blurb": "The /standup skill completes: collect.sh implements the eight bounded lens reads that feed triage.py, and the skill runs end-to-end.", "exit": "Exit: collect.sh --fixture emits all eight lenses; triage.py consumes each without a D5; test/gh77-standup-triage.sh green with per-lens assertions AND a per-lens degradation assertion; the skill runs end-to-end on this repo and its output fits the 15-line cap; validate.sh full gate green.", "detours": [], "roadmap": [{"type": "marathon", "id": "GH-77", "url": "https://github.com/HiQS-Suite/XYZ-forge/issues/77", "title": "Daybreak marathon", "meta": "planned", "state": "run", "cards": [{"id": "GH-79", "title": "issue GH-79", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/79"}}, {"id": "GH-80", "title": "issue GH-80", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/80"}}, {"id": "GH-81", "title": "issue GH-81", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/81"}}, {"id": "GH-82", "title": "issue GH-82", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/82"}}, {"id": "GH-83", "title": "issue GH-83", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/83"}}, {"id": "GH-84", "title": "issue GH-84", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/84"}}, {"id": "GH-85", "title": "issue GH-85", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/85"}}, {"id": "GH-86", "title": "issue GH-86", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/86"}}, {"id": "GH-87", "title": "issue GH-87", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/87"}}]}, {"id": "GH-108", "title": "pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override)", "marker": "paused", "section": "deferred", "sectionLabel": "cut", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/108", "doc": "PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md"}, "metrics": {"pri": 80, "sev": 50, "appeal": 75, "effort": 40, "calc": 245, "effectiveScore": 245}}]}, {"id": "c-0-7-3", "slug": "bulkhead", "name": "Bulkhead", "version": "0.7.3", "status": "active", "flags": {"now": true}, "badge": {"type": "active", "label": "active"}, "dateLabel": "target", "date": "2026-09-05", "extra": "in 13 days", "itemsTotal": 13, "itemsOpen": 13, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Bulkhead", "blurb": "An unattended marathon survives its own harness.", "exit": "Exit: Each member suite (gh8, gh2, gh50, gh113, gh114, gh115, gh168) green and registered in validate.sh; full local gate green; manifest 7/7 shipped or explicitly cut.", "detours": [{"id": "GH-141", "title": "make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison", "marker": "wip", "section": "adhoc", "sectionLabel": "ad-hoc detour", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/141"}, "metrics": {"pri": 80, "sev": 65, "appeal": 85, "effort": 55, "calc": 285, "effectiveScore": 285}}, {"id": "GH-5", "title": "kernel robustness: node:test unit runner", "marker": "wip", "section": "adhoc", "sectionLabel": "ad-hoc detour", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/5"}, "metrics": {"pri": 45, "sev": 40, "appeal": 45, "effort": 80, "calc": 210, "effectiveScore": 210}}], "roadmap": [{"id": "GH-113", "title": "headless agy builder writes root scratch files, tripping containment (exit 6)", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/113", "doc": "PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md"}, "metrics": {"pri": 85, "sev": 60, "appeal": 85, "effort": 60, "calc": 290, "effectiveScore": 290}}, {"id": "GH-114", "title": "headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7)", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/114", "doc": "PROJECT/2-WORKING/GH-114-HEADLESS-TTY-IDLE-HANG.md"}, "metrics": {"pri": 80, "sev": 60, "appeal": 80, "effort": 60, "calc": 280, "effectiveScore": 280}}, {"id": "GH-115", "title": "marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/115", "doc": "PROJECT/3-COMPLETED/GH-115-ROUND-CAP-ESCALATION.md"}, "metrics": {"pri": 75, "sev": 50, "appeal": 85, "effort": 70, "calc": 280, "effectiveScore": 280}}, {"id": "GH-168", "title": "wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/168", "doc": "PROJECT/2-WORKING/GH-168-WAVE-RECONCILE-SCOPE.md"}, "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 70, "calc": 290, "effectiveScore": 290}}, {"id": "GH-8", "title": "kernel boundary hardening — CLI numeric validation, task/agent format contract", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/8", "doc": "PROJECT/3-COMPLETED/GH-8-KERNEL-BOUNDARY-HARDENING.md"}, "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 65, "calc": 275, "effectiveScore": 275}}, {"id": "GH-2", "title": "test-suite run relocated an untracked file into .tick/orphan-backups/", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/2", "doc": "PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md"}, "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 55, "calc": 275, "effectiveScore": 275}}, {"id": "GH-50", "title": "sandboxed git --track / branch -D half-applies and loses uncommitted work", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/50", "doc": "PROJECT/2-WORKING/GH-50-SANDBOXED-GIT-HALF-APPLY.md"}, "metrics": {"pri": 65, "sev": 35, "appeal": 85, "effort": 80, "calc": 265, "effectiveScore": 265}}, {"id": "GH-180", "title": "repro_builder crashes on timeout telemetry records (exit_code: null → TypeError)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/180", "doc": "PROJECT/3-COMPLETED/GH-180-REPRO-TIMEOUT-CRASH.md"}, "metrics": {"pri": 70, "sev": 45, "appeal": 85, "effort": 80, "calc": 280, "effectiveScore": 280}}, {"id": "GH-181", "title": "repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/181", "doc": "PROJECT/3-COMPLETED/GH-181-REPRO-ADAPTER-FIDELITY.md"}, "metrics": {"pri": 90, "sev": 75, "appeal": 90, "effort": 60, "calc": 315, "effectiveScore": 315}}, {"id": "GH-182", "title": "self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/182", "doc": "PROJECT/2-WORKING/GH-182-HEALER-FACADE-SAFETY.md"}, "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 55, "calc": 265, "effectiveScore": 265}}, {"id": "GH-183", "title": "active_explorer env-family fuzzing unsound (base_env={} hardcoded, one always-deferring vector, ambient-env leakage)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/183", "doc": "PROJECT/3-COMPLETED/GH-183-EXPLORER-ENV-SOUNDNESS.md"}, "metrics": {"pri": 65, "sev": 50, "appeal": 75, "effort": 70, "calc": 260, "effectiveScore": 260}}, {"id": "GH-184", "title": "committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/184", "doc": "PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md"}, "metrics": {"pri": 60, "sev": 40, "appeal": 80, "effort": 90, "calc": 270, "effectiveScore": 270}}, {"id": "GH-174", "title": "Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/174", "doc": "PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md"}, "metrics": {"pri": 85, "sev": 75, "appeal": 95, "effort": 45, "calc": 300, "effectiveScore": 300}}]}, {"id": "c-0-9-0", "slug": "cargo", "name": "Cargo", "version": "0.9.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-09-19", "extra": "in 27 days", "itemsTotal": 2, "itemsOpen": 2, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Cargo", "blurb": "The harness travels with its ledger: the RELEASES DB system (releases_app.py CLI + merge resolver + FAQs) and the GH-103 HTML timeline generator (utils/timeline/) ship inside every vendored .xyz/ payload as an optional, never-wired-by-default add-on — a 'when you're ready' module a target repo enables by running releases init itself, matching RELEASES.md's own OPTIONAL philosophy (GH-381).", "exit": "Exit: A repo vendored with xyz-vendor.sh can, with zero extra downloads, run releases init/add and export_timeline.py --preview from .xyz/ against its own root, and xyz-sync.sh update preserves the target's ledger state (GH-312 preserve list). Nothing runs until the user invokes it.", "detours": [], "roadmap": [{"id": "GH-105", "title": "vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on)", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/105", "doc": "PROJECT/1-INBOX/GH-105-VENDOR-RELEASES-ADDON.md"}, "metrics": {"pri": 75, "sev": 50, "appeal": 60, "effort": 45, "calc": 230, "effectiveScore": 230}}, {"id": "GH-107", "title": "issue GH-107", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/107"}}]}, {"id": "c-0-6-0", "slug": "meter", "name": "Meter", "version": "0.6.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-09-26", "extra": "in 34 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Meter", "blurb": "XYZ can be handed to a stranger: an unauthenticated clone reaches a documented entry path and exercises a supported happy path with no private context, from a sanitized, secret-scanned tree.", "exit": "Exit: bash test/meter-release.sh --release-gate exits 0. NOT BUILT — written first, before any sanitization (the Litmus/Nightwatch ordering). Half A AUDITS the launch artifact: single-commit sanitized clone at the declared path; CHANGELOG.md byte-identical; .tick/, relay-system/, temp/ absent; PROJECT/ = PDDA scaffold + retained Meter example only; both LICENSE files present and consistent; secret-scan result names tool version and exact commit. Half B EXECUTES the stranger's path: a credential-less clone of the published commit completes one supported happy path with nothing author-machine-local. Negative control --mutate-evidence: plant a private path, remove CHANGELOG.md, leave a relay-system/ behind — detect all three, re-check unmutated inputs green in the same run. RED on arrival.", "detours": [], "roadmap": []}, {"id": "c-0-8-0", "slug": "sundown", "name": "Sundown", "version": "0.8.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-10-17", "extra": "in 55 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Sundown", "blurb": "Retire the twelve frozen Bash twins.", "exit": "Exit: NOT WRITTEN. Required before this release starts, per the ordering Litmus and Nightwatch both used and Meter is repeating — the gate is built first and arrives RED, because a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one.", "detours": [], "roadmap": []}, {"id": "c-0-4-0", "slug": "plumbline", "name": "Plumbline", "version": "0.4.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-11-14", "extra": "in 83 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Plumbline", "blurb": "Assisted reflection and a bounded self-improvement loop, measured before either is trusted.", "exit": "Assisted reflection and a bounded self-improvement loop, measured before either is trusted. The reflection pipeline turns durable Nightwatch records into proposals (`proposals-sink.sh` gains its first production caller) and is graded against external ground truth — the 49 human-f…", "detours": [], "roadmap": []}, {"id": "c-0-5-0", "slug": "lantern", "name": "Lantern", "version": "0.5.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-12-12", "extra": "in 111 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "milestones", "blurb": "When the harness fails, the information needed to act already exists inside it — make it say so.", "exit": "Exit: `bash test/lantern-release.sh --release-gate` exits 0. NOT BUILT. Writing it precedes fixing any member, which is the Litmus and Nightwatch ordering and the reason both releases could tell a finished entry from a claimed one. Two halves, the established shape: Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below. Half B executes #499's four phases rather than auditing them, since every one of them is a message an operator either receives or does not: a `relay-drive` launch preflight that refuses before spending, a gate refusal that states its real reason, a launcher exit code that survives its wrapper, and a change-impact report. #358 Phase 2 is the one member with no executable half, and the criterion is written around that rather than pretending otherwise: it is satisfied by a RECORDED transcript of a real CI failure under `test/baselines/`, and it must NOT be satisfiable by a disposition written in advance — that issue's own capture doc forbids pre-committing one, and an exit criterion that accepted a pre-written verdict would launder exactly the thing #419 exists to prevent. Its own negative control is `--mutate-evidence`, which must unregister a gate, delete a recorded control, and substitute a pre-dated disposition for a real transcript — detecting all three, and re-checking the unmutated inputs green in the same run so an always-red detector cannot pass for one.", "detours": [], "roadmap": []}], "projects": [{"slug": "XYZ-forge", "active": true}], "cycle": {"repo": "XYZ-forge", "generatedAt": "2026-08-24T03:30:06Z", "db": {"generation": 114, "receipts": 128, "lastOp": "2026-08-24T03:30:06Z", "schemaVersion": 5}, "releases": {"total": 12, "open": 6, "overdue": 0, "byStatus": {"active": 1, "draft": 5, "shipped": 6}, "openList": [{"version": "0.7.3", "codename": "Bulkhead", "status": "active", "target": "2026-09-05", "daysToTarget": 13}, {"version": "0.9.0", "codename": "Cargo", "status": "draft", "target": "2026-09-19", "daysToTarget": 27}, {"version": "0.6.0", "codename": "Meter", "status": "draft", "target": "2026-09-26", "daysToTarget": 34}, {"version": "0.8.0", "codename": "Sundown", "status": "draft", "target": "2026-10-17", "daysToTarget": 55}, {"version": "0.4.0", "codename": "Plumbline", "status": "draft", "target": "2026-11-14", "daysToTarget": 83}], "recentShipped": [{"version": "0.7.2", "shipped": "2026-08-23"}, {"version": "0.7.1", "shipped": "2026-08-19"}, {"version": "0.7.0", "shipped": "2026-08-18"}]}, "roadmap": {"total": 56, "unmarked": 9, "wip": 9, "queued": 0, "done": 38, "paused": 0}, "marathons": {"total": 1, "byStatus": {"planned": 1}, "runningRefs": ["GH-77"]}, "items": {"open": 0, "dialedIn": 18, "shipped": 9, "cut": 1}, "recentEvents": [{"at": "2026-08-23T04:30:03Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-87"}, {"at": "2026-08-23T04:30:02Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-85"}, {"at": "2026-08-23T04:30:02Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-86"}, {"at": "2026-08-23T04:30:01Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-82"}, {"at": "2026-08-23T04:30:01Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-83"}]}, "view": "leaderboard"}</script>
./skills/agent-chorus/SKILL.md:344:- **A conditional teardown instruction is permission to check its condition, not to assume it —
./skills/agent-chorus/SKILL.md:365:  pushed, and executed the teardown. It was not pushed: the peer had a local-only commit, which the
./skills/agent-chorus/SKILL.md:366:  teardown lost. The failure was not merely "an agent skipped verifying the one fact the instruction
./utils/fuzzing/fuzz-loop.sh:132:  # `status` key is gone entirely: it was a pure alias of top-level status (GH-141's review
./test/xyz-harness-hooks.sh:66:assert_nudge "nudge: commit/push + close issues" "Commit and push, then close the resolved issues" loose-ends marathon-cleanup
./test/xyz-harness-hooks.sh:67:assert_nudge "nudge: commit/push + archive/PDDA" "Commit and push; move docs to 3-COMPLETED and run a PDDA sweep" loose-ends marathon-cleanup
./relay-system/2026-08-18/gh28-releases-discipline-090759/gh28-releases-discipline.codex.md:1314:RELEASES.md-120-RC evidence: `bash test/nightwatch-release.sh --release-gate` → `GOALPOST MET — all 8 manifest entries complete and every lifecycle case executes green` (manifest 8/8, lifecycle 5 passing / 0 failing / 0 NOT COVERED). Its own negative control, `--mutate-evidence`, reports 34/0 and `negative control OBSERVED in both directions`. Every manifest entry carries a recorded pre-fix control under `test/baselines/`, not an assertion that one happened. **Two entries are honest about their limits and are worth reading before signing off:** #358's Phase 2 is a *disposition* that needs a real CI failure carrying the new instrumentation, and its capture doc forbids pre-committing one — so Phase 1 shipped and Phase 2 is blocked on an observation, not on work; and #354's membership is Phase 1 only, which was delivered by #376/#448 rather than by this release, recorded as such rather than rebuilt. **#426's outcome inverted its own diagnosis:** a factorial control showed the leak survives with worktree isolation OFF, so teardown was exonerated and the real cause was the GH-375 auth pre-flight running with the caller's CWD, outside containment. **Twelve open Nightwatch-milestone issues remain and gate nothing**, per this block's own "a release is not its milestone" rule. **CI-VERIFIED 2026-08-12, and it was not before:** the goalpost was first met on macOS only, and two of the five lifecycle cases (#388, #514) were failing on every ubuntu CI run at the time the RC was recorded — their fixtures stubbed the builder but not the reviewer binary, so `marathon_drive.py`'s probe fail-fasted and the cases never executed the code they assert on. Fixed, and the gate now reports `GOALPOST MET` with `codex` absent from `PATH`, which is the CI condition reproduced locally rather than inferred. Recorded here because it is exactly the class of thing this release exists to catch: a green result that was green about the wrong environment. The general defect is #520; the control is `test/baselines/GH-520-negative-control.md`.
./relay-system/2026-08-18/gh28-releases-discipline-090759/gh28-releases-discipline.codex.md:1352:RELEASES.md-165-Publication target — **the deliverable is a sanitized clone, not this repository.** The public artifact is a new working tree cut from `development`, stripped of runtime state and internal working documents, committed as **fresh history with a single initial commit**, and pushed to **https://github.com/HiQS-Suite/XYZ-forge** — a new repository in a different organization, named by the operator on 2026-08-15, which becomes XYZ's permanent home. `CHANGELOG.md` is carried forward verbatim and is the public record of the project's history — it is a *file*, so it survives a fresh-history cut intact, and carrying 2,147 commits was rejected on 2026-08-15 for a stated reason: every document removed during sanitization stays reachable in a carried history, which makes the full-history secret scan this release requires a scan of everything ever deleted rather than a scan of one tree. Fresh history makes the sanitization complete by construction. `.tick/` (161 MB of runtime event state) and `relay-system/` (32 MB of relay transcripts) do not ship. `PROJECT/` ships as an **empty PDDA scaffold** plus the Meter build documents retained deliberately as a worked example of how PDDA is used — the method travels, the backlog does not.
./relay-system/2026-08-18/gh28-releases-discipline-090759/gh28-releases-discipline.codex.md:1354:RELEASES.md:167:Exit criterion: `bash test/meter-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it is Meter's first task, before any member is fixed — that ordering is the Litmus and Nightwatch precedent, and it is the whole reason both releases could tell a finished entry from a claimed one. Two halves, same shape as Nightwatch's: Half A audits the frozen manifest (each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below) and Half B EXECUTES the cases rather than auditing them — a run against a red-suite target proceeds under a recorded baseline and halts on a *new* failure; a budget-exhausted builder is escalated as budget-exhausted rather than pre-advance-failed; an untrusted target is reported before the first paid turn rather than after; a phase boundary records memory and swap; and a re-fire of an already-satisfied phase runs only the gate and says so. Its own negative control is `--mutate-evidence`, which must unregister a gate and delete a recorded control in a fixture copy, detect both, and re-check the unmutated inputs green in the same run. **RE-SCOPED 2026-08-15 with the release.** The command is unchanged and the two-half shape is unchanged — that shape is the reason Litmus and Nightwatch could tell a finished entry from a claimed one, and it is retained deliberately. What changed is what the halves measure, because a gate that audits a manifest which no longer exists is not a gate. **Half A audits the launch artifact**: the sanitized clone exists at the declared path and is a repository with exactly one commit; `CHANGELOG.md` is present and byte-identical to this repository's; `.tick/`, `relay-system/` and `temp/` are absent; `PROJECT/` contains the PDDA scaffold and the retained Meter example and nothing else; `LICENSE` and `LICENSE-COMMERCIAL.md` are present and mutually consistent; and the secret scan's recorded result names its tool version and the exact commit it scanned. **Half B EXECUTES the stranger's path rather than auditing it**: a clone taken with no credentials, from the published commit, reaches the documented entry point and completes one supported happy path with no file, token, or environment variable that exists only on the author's machine. Its own negative control, `--mutate-evidence`, is likewise re-pointed: in a fixture copy it must plant a private path in a tracked file, remove `CHANGELOG.md`, and leave a `relay-system/` directory behind, detect all three, and re-check the unmutated inputs green in the same run. **The gate is RED on arrival and is Meter's first task, before any sanitization is performed** — same ordering as the two releases that shipped.
./relay-system/2026-08-18/gh28-releases-discipline-090759/gh28-releases-discipline.codex.md:1367:RELEASES.md:182:Exit criterion: `bash test/ballast-release.sh --release-gate` exits 0. **NOT BUILT — writing it is Ballast's first task, before any member is fixed** (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. **Half A audits the frozen manifest:** each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. **Half B EXECUTES the stranger's path rather than auditing it:** (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. **BUILT 2026-08-17.** `test/ballast-release.sh` written and registered in `validate.sh`; suite mode green (`--mutate-evidence` 7/0). Half A: 3 of 4 manifest members complete (#14, #15, #3 — gate/registration/control/CLOSED-issue all confirmed); #4 landed the same day this file was written, so its CLOSED-issue credit is pending the next suite run. Half B's mechanics were smoke-tested end-to-end (all four sub-checks — B1/B2a/B2b/B3 — execute correctly against a real disposable clone) but **`--release-gate` has not yet been run for real** (the full ten-run stranger pass, against a clone cut from the commit that carries all four fixes) — that run is the actual goalpost and is still red pending it, honestly, not silently.
./relay-system/2026-08-18/gh28-releases-discipline-090759/gh28-releases-discipline.codex.md:1398:ROADMAP.md-76-- **GH-527 · a destructive git command has no guard, and a doc rail demonstrably will not fix it** ✅ **BUILT 2026-08-14 on `fix/critical-2026-08-14`** — snapshot-then-allow PreToolUse hook copies the doomed *tracked* files into `.tick/orphan-backups/` before the command runs (the GH-141 `rtl_check` precedent), plus the `AGENTS.md` rail naming all three spellings. 26/0; recovery demonstrated end-to-end; clean-tree silence is defended by two conditions so it took a combined mutation to falsify. → [GH-527-DESTRUCTIVE-GIT-GUARD.md](PROJECT/2-WORKING/GH-527-DESTRUCTIVE-GIT-GUARD.md) · [#527](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/527)
./relay-system/2026-08-18/gh28-releases-discipline-090759/gh28-releases-discipline.codex.md:2113:RC evidence: `bash test/nightwatch-release.sh --release-gate` → `GOALPOST MET — all 8 manifest entries complete and every lifecycle case executes green` (manifest 8/8, lifecycle 5 passing / 0 failing / 0 NOT COVERED). Its own negative control, `--mutate-evidence`, reports 34/0 and `negative control OBSERVED in both directions`. Every manifest entry carries a recorded pre-fix control under `test/baselines/`, not an assertion that one happened. **Two entries are honest about their limits and are worth reading before signing off:** #358's Phase 2 is a *disposition* that needs a real CI failure carrying the new instrumentation, and its capture doc forbids pre-committing one — so Phase 1 shipped and Phase 2 is blocked on an observation, not on work; and #354's membership is Phase 1 only, which was delivered by #376/#448 rather than by this release, recorded as such rather than rebuilt. **#426's outcome inverted its own diagnosis:** a factorial control showed the leak survives with worktree isolation OFF, so teardown was exonerated and the real cause was the GH-375 auth pre-flight running with the caller's CWD, outside containment. **Twelve open Nightwatch-milestone issues remain and gate nothing**, per this block's own "a release is not its milestone" rule. **CI-VERIFIED 2026-08-12, and it was not before:** the goalpost was first met on macOS only, and two of the five lifecycle cases (#388, #514) were failing on every ubuntu CI run at the time the RC was recorded — their fixtures stubbed the builder but not the reviewer binary, so `marathon_drive.py`'s probe fail-fasted and the cases never executed the code they assert on. Fixed, and the gate now reports `GOALPOST MET` with `codex` absent from `PATH`, which is the CI condition reproduced locally rather than inferred. Recorded here because it is exactly the class of thing this release exists to catch: a green result that was green about the wrong environment. The general defect is #520; the control is `test/baselines/GH-520-negative-control.md`.
./relay-system/2026-08-18/gh28-releases-discipline-090759/gh28-releases-discipline.codex.md:2158:Publication target — **the deliverable is a sanitized clone, not this repository.** The public artifact is a new working tree cut from `development`, stripped of runtime state and internal working documents, committed as **fresh history with a single initial commit**, and pushed to **https://github.com/HiQS-Suite/XYZ-forge** — a new repository in a different organization, named by the operator on 2026-08-15, which becomes XYZ's permanent home. `CHANGELOG.md` is carried forward verbatim and is the public record of the project's history — it is a *file*, so it survives a fresh-history cut intact, and carrying 2,147 commits was rejected on 2026-08-15 for a stated reason: every document removed during sanitization stays reachable in a carried history, which makes the full-history secret scan this release requires a scan of everything ever deleted rather than a scan of one tree. Fresh history makes the sanitization complete by construction. `.tick/` (161 MB of runtime event state) and `relay-system/` (32 MB of relay transcripts) do not ship. `PROJECT/` ships as an **empty PDDA scaffold** plus the Meter build documents retained deliberately as a worked example of how PDDA is used — the method travels, the backlog does not.
./relay-system/2026-08-18/gh28-releases-discipline-090759/gh28-releases-discipline.codex.md:2160:Exit criterion: `bash test/meter-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it is Meter's first task, before any member is fixed — that ordering is the Litmus and Nightwatch precedent, and it is the whole reason both releases could tell a finished entry from a claimed one. Two halves, same shape as Nightwatch's: Half A audits the frozen manifest (each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below) and Half B EXECUTES the cases rather than auditing them — a run against a red-suite target proceeds under a recorded baseline and halts on a *new* failure; a budget-exhausted builder is escalated as budget-exhausted rather than pre-advance-failed; an untrusted target is reported before the first paid turn rather than after; a phase boundary records memory and swap; and a re-fire of an already-satisfied phase runs only the gate and says so. Its own negative control is `--mutate-evidence`, which must unregister a gate and delete a recorded control in a fixture copy, detect both, and re-check the unmutated inputs green in the same run. **RE-SCOPED 2026-08-15 with the release.** The command is unchanged and the two-half shape is unchanged — that shape is the reason Litmus and Nightwatch could tell a finished entry from a claimed one, and it is retained deliberately. What changed is what the halves measure, because a gate that audits a manifest which no longer exists is not a gate. **Half A audits the launch artifact**: the sanitized clone exists at the declared path and is a repository with exactly one commit; `CHANGELOG.md` is present and byte-identical to this repository's; `.tick/`, `relay-system/` and `temp/` are absent; `PROJECT/` contains the PDDA scaffold and the retained Meter example and nothing else; `LICENSE` and `LICENSE-COMMERCIAL.md` are present and mutually consistent; and the secret scan's recorded result names its tool version and the exact commit it scanned. **Half B EXECUTES the stranger's path rather than auditing it**: a clone taken with no credentials, from the published commit, reaches the documented entry point and completes one supported happy path with no file, token, or environment variable that exists only on the author's machine. Its own negative control, `--mutate-evidence`, is likewise re-pointed: in a fixture copy it must plant a private path in a tracked file, remove `CHANGELOG.md`, and leave a `relay-system/` directory behind, detect all three, and re-check the unmutated inputs green in the same run. **The gate is RED on arrival and is Meter's first task, before any sanitization is performed** — same ordering as the two releases that shipped.
./relay-system/2026-08-18/gh28-releases-discipline-090759/gh28-releases-discipline.codex.md:2175:Exit criterion: `bash test/ballast-release.sh --release-gate` exits 0. **NOT BUILT — writing it is Ballast's first task, before any member is fixed** (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. **Half A audits the frozen manifest:** each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. **Half B EXECUTES the stranger's path rather than auditing it:** (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. **BUILT 2026-08-17.** `test/ballast-release.sh` written and registered in `validate.sh`; suite mode green (`--mutate-evidence` 7/0). Half A: 3 of 4 manifest members complete (#14, #15, #3 — gate/registration/control/CLOSED-issue all confirmed); #4 landed the same day this file was written, so its CLOSED-issue credit is pending the next suite run. Half B's mechanics were smoke-tested end-to-end (all four sub-checks — B1/B2a/B2b/B3 — execute correctly against a real disposable clone) but **`--release-gate` has not yet been run for real** (the full ten-run stranger pass, against a clone cut from the commit that carries all four fixes) — that run is the actual goalpost and is still red pending it, honestly, not silently.
./relay-system/2026-08-18/gh28-releases-discipline-090759/gh28-releases-discipline.codex.md:2705:167:Exit criterion: `bash test/meter-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it is Meter's first task, before any member is fixed — that ordering is the Litmus and Nightwatch precedent, and it is the whole reason both releases could tell a finished entry from a claimed one. Two halves, same shape as Nightwatch's: Half A audits the frozen manifest (each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below) and Half B EXECUTES the cases rather than auditing them — a run against a red-suite target proceeds under a recorded baseline and halts on a *new* failure; a budget-exhausted builder is escalated as budget-exhausted rather than pre-advance-failed; an untrusted target is reported before the first paid turn rather than after; a phase boundary records memory and swap; and a re-fire of an already-satisfied phase runs only the gate and says so. Its own negative control is `--mutate-evidence`, which must unregister a gate and delete a recorded control in a fixture copy, detect both, and re-check the unmutated inputs green in the same run. **RE-SCOPED 2026-08-15 with the release.** The command is unchanged and the two-half shape is unchanged — that shape is the reason Litmus and Nightwatch could tell a finished entry from a claimed one, and it is retained deliberately. What changed is what the halves measure, because a gate that audits a manifest which no longer exists is not a gate. **Half A audits the launch artifact**: the sanitized clone exists at the declared path and is a repository with exactly one commit; `CHANGELOG.md` is present and byte-identical to this repository's; `.tick/`, `relay-system/` and `temp/` are absent; `PROJECT/` contains the PDDA scaffold and the retained Meter example and nothing else; `LICENSE` and `LICENSE-COMMERCIAL.md` are present and mutually consistent; and the secret scan's recorded result names its tool version and the exact commit it scanned. **Half B EXECUTES the stranger's path rather than auditing it**: a clone taken with no credentials, from the published commit, reaches the documented entry point and completes one supported happy path with no file, token, or environment variable that exists only on the author's machine. Its own negative control, `--mutate-evidence`, is likewise re-pointed: in a fixture copy it must plant a private path in a tracked file, remove `CHANGELOG.md`, and leave a `relay-system/` directory behind, detect all three, and re-check the unmutated inputs green in the same run. **The gate is RED on arrival and is Meter's first task, before any sanitization is performed** — same ordering as the two releases that shipped.
./relay-system/2026-08-18/gh28-releases-discipline-090759/gh28-releases-discipline.codex.md:2707:182:Exit criterion: `bash test/ballast-release.sh --release-gate` exits 0. **NOT BUILT — writing it is Ballast's first task, before any member is fixed** (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. **Half A audits the frozen manifest:** each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. **Half B EXECUTES the stranger's path rather than auditing it:** (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. **BUILT 2026-08-17.** `test/ballast-release.sh` written and registered in `validate.sh`; suite mode green (`--mutate-evidence` 7/0). Half A: 3 of 4 manifest members complete (#14, #15, #3 — gate/registration/control/CLOSED-issue all confirmed); #4 landed the same day this file was written, so its CLOSED-issue credit is pending the next suite run. Half B's mechanics were smoke-tested end-to-end (all four sub-checks — B1/B2a/B2b/B3 — execute correctly against a real disposable clone) but **`--release-gate` has not yet been run for real** (the full ten-run stranger pass, against a clone cut from the commit that carries all four fixes) — that run is the actual goalpost and is still red pending it, honestly, not silently.
./relay-system/2026-08-18/gh28-releases-discipline-090759/gh28-releases-discipline.codex.md:3162:Publication target — **the deliverable is a sanitized clone, not this repository.** The public artifact is a new working tree cut from `development`, stripped of runtime state and internal working documents, committed as **fresh history with a single initial commit**, and pushed to **https://github.com/HiQS-Suite/XYZ-forge** — a new repository in a different organization, named by the operator on 2026-08-15, which becomes XYZ's permanent home. `CHANGELOG.md` is carried forward verbatim and is the public record of the project's history — it is a *file*, so it survives a fresh-history cut intact, and carrying 2,147 commits was rejected on 2026-08-15 for a stated reason: every document removed during sanitization stays reachable in a carried history, which makes the full-history secret scan this release requires a scan of everything ever deleted rather than a scan of one tree. Fresh history makes the sanitization complete by construction. `.tick/` (161 MB of runtime event state) and `relay-system/` (32 MB of relay transcripts) do not ship. `PROJECT/` ships as an **empty PDDA scaffold** plus the Meter build documents retained deliberately as a worked example of how PDDA is used — the method travels, the backlog does not.
./relay-system/2026-08-18/gh28-releases-discipline-090759/gh28-releases-discipline.codex.md:3164:Exit criterion: `bash test/meter-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it is Meter's first task, before any member is fixed — that ordering is the Litmus and Nightwatch precedent, and it is the whole reason both releases could tell a finished entry from a claimed one. Two halves, same shape as Nightwatch's: Half A audits the frozen manifest (each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below) and Half B EXECUTES the cases rather than auditing them — a run against a red-suite target proceeds under a recorded baseline and halts on a *new* failure; a budget-exhausted builder is escalated as budget-exhausted rather than pre-advance-failed; an untrusted target is reported before the first paid turn rather than after; a phase boundary records memory and swap; and a re-fire of an already-satisfied phase runs only the gate and says so. Its own negative control is `--mutate-evidence`, which must unregister a gate and delete a recorded control in a fixture copy, detect both, and re-check the unmutated inputs green in the same run. **RE-SCOPED 2026-08-15 with the release.** The command is unchanged and the two-half shape is unchanged — that shape is the reason Litmus and Nightwatch could tell a finished entry from a claimed one, and it is retained deliberately. What changed is what the halves measure, because a gate that audits a manifest which no longer exists is not a gate. **Half A audits the launch artifact**: the sanitized clone exists at the declared path and is a repository with exactly one commit; `CHANGELOG.md` is present and byte-identical to this repository's; `.tick/`, `relay-system/` and `temp/` are absent; `PROJECT/` contains the PDDA scaffold and the retained Meter example and nothing else; `LICENSE` and `LICENSE-COMMERCIAL.md` are present and mutually consistent; and the secret scan's recorded result names its tool version and the exact commit it scanned. **Half B EXECUTES the stranger's path rather than auditing it**: a clone taken with no credentials, from the published commit, reaches the documented entry point and completes one supported happy path with no file, token, or environment variable that exists only on the author's machine. Its own negative control, `--mutate-evidence`, is likewise re-pointed: in a fixture copy it must plant a private path in a tracked file, remove `CHANGELOG.md`, and leave a `relay-system/` directory behind, detect all three, and re-check the unmutated inputs green in the same run. **The gate is RED on arrival and is Meter's first task, before any sanitization is performed** — same ordering as the two releases that shipped.
./relay-system/2026-08-18/gh28-releases-discipline-090759/gh28-releases-discipline.codex.md:3179:Exit criterion: `bash test/ballast-release.sh --release-gate` exits 0. **NOT BUILT — writing it is Ballast's first task, before any member is fixed** (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. **Half A audits the frozen manifest:** each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. **Half B EXECUTES the stranger's path rather than auditing it:** (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. **BUILT 2026-08-17.** `test/ballast-release.sh` written and registered in `validate.sh`; suite mode green (`--mutate-evidence` 7/0). Half A: 3 of 4 manifest members complete (#14, #15, #3 — gate/registration/control/CLOSED-issue all confirmed); #4 landed the same day this file was written, so its CLOSED-issue credit is pending the next suite run. Half B's mechanics were smoke-tested end-to-end (all four sub-checks — B1/B2a/B2b/B3 — execute correctly against a real disposable clone) but **`--release-gate` has not yet been run for real** (the full ten-run stranger pass, against a clone cut from the commit that carries all four fixes) — that run is the actual goalpost and is still red pending it, honestly, not silently.
./relay-system/2026-08-18/gh28-releases-discipline-090759/gh28-releases-discipline.codex.md:4611:   165	Publication target — **the deliverable is a sanitized clone, not this repository.** The public artifact is a new working tree cut from `development`, stripped of runtime state and internal working documents, committed as **fresh history with a single initial commit**, and pushed to **https://github.com/HiQS-Suite/XYZ-forge** — a new repository in a different organization, named by the operator on 2026-08-15, which becomes XYZ's permanent home. `CHANGELOG.md` is carried forward verbatim and is the public record of the project's history — it is a *file*, so it survives a fresh-history cut intact, and carrying 2,147 commits was rejected on 2026-08-15 for a stated reason: every document removed during sanitization stays reachable in a carried history, which makes the full-history secret scan this release requires a scan of everything ever deleted rather than a scan of one tree. Fresh history makes the sanitization complete by construction. `.tick/` (161 MB of runtime event state) and `relay-system/` (32 MB of relay transcripts) do not ship. `PROJECT/` ships as an **empty PDDA scaffold** plus the Meter build documents retained deliberately as a worked example of how PDDA is used — the method travels, the backlog does not.
./relay-system/2026-08-18/gh28-releases-discipline-090759/gh28-releases-discipline.codex.md:4613:   167	Exit criterion: `bash test/meter-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it is Meter's first task, before any member is fixed — that ordering is the Litmus and Nightwatch precedent, and it is the whole reason both releases could tell a finished entry from a claimed one. Two halves, same shape as Nightwatch's: Half A audits the frozen manifest (each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below) and Half B EXECUTES the cases rather than auditing them — a run against a red-suite target proceeds under a recorded baseline and halts on a *new* failure; a budget-exhausted builder is escalated as budget-exhausted rather than pre-advance-failed; an untrusted target is reported before the first paid turn rather than after; a phase boundary records memory and swap; and a re-fire of an already-satisfied phase runs only the gate and says so. Its own negative control is `--mutate-evidence`, which must unregister a gate and delete a recorded control in a fixture copy, detect both, and re-check the unmutated inputs green in the same run. **RE-SCOPED 2026-08-15 with the release.** The command is unchanged and the two-half shape is unchanged — that shape is the reason Litmus and Nightwatch could tell a finished entry from a claimed one, and it is retained deliberately. What changed is what the halves measure, because a gate that audits a manifest which no longer exists is not a gate. **Half A audits the launch artifact**: the sanitized clone exists at the declared path and is a repository with exactly one commit; `CHANGELOG.md` is present and byte-identical to this repository's; `.tick/`, `relay-system/` and `temp/` are absent; `PROJECT/` contains the PDDA scaffold and the retained Meter example and nothing else; `LICENSE` and `LICENSE-COMMERCIAL.md` are present and mutually consistent; and the secret scan's recorded result names its tool version and the exact commit it scanned. **Half B EXECUTES the stranger's path rather than auditing it**: a clone taken with no credentials, from the published commit, reaches the documented entry point and completes one supported happy path with no file, token, or environment variable that exists only on the author's machine. Its own negative control, `--mutate-evidence`, is likewise re-pointed: in a fixture copy it must plant a private path in a tracked file, remove `CHANGELOG.md`, and leave a `relay-system/` directory behind, detect all three, and re-check the unmutated inputs green in the same run. **The gate is RED on arrival and is Meter's first task, before any sanitization is performed** — same ordering as the two releases that shipped.
./relay-system/2026-08-18/gh28-releases-discipline-090759/gh28-releases-discipline.codex.md:4626:   182	Exit criterion: `bash test/ballast-release.sh --release-gate` exits 0. **NOT BUILT — writing it is Ballast's first task, before any member is fixed** (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. **Half A audits the frozen manifest:** each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. **Half B EXECUTES the stranger's path rather than auditing it:** (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. **BUILT 2026-08-17.** `test/ballast-release.sh` written and registered in `validate.sh`; suite mode green (`--mutate-evidence` 7/0). Half A: 3 of 4 manifest members complete (#14, #15, #3 — gate/registration/control/CLOSED-issue all confirmed); #4 landed the same day this file was written, so its CLOSED-issue credit is pending the next suite run. Half B's mechanics were smoke-tested end-to-end (all four sub-checks — B1/B2a/B2b/B3 — execute correctly against a real disposable clone) but **`--release-gate` has not yet been run for real** (the full ten-run stranger pass, against a clone cut from the commit that carries all four fixes) — that run is the actual goalpost and is still red pending it, honestly, not silently.
./utils/py/harness_app.py:25:    return os.path.join(root, "harnesses.db")
./utils/py/harness_app.py:35:    return os.path.join(root, "HARNESS-MODELS-REGISTRY.generated.md")
./utils/py/harness_app.py:202:    """Render canonical HARNESS-MODELS-REGISTRY.generated.md view from database."""
./utils/py/harness_app.py:216:        "<!-- Auto-generated from harnesses.db by utils/py/harness_app.py — DO NOT HAND-EDIT -->",
./utils/py/harness_app.py:292:    subparsers.add_parser("init", help="Initialize and seed harnesses.db")
./utils/py/harness_app.py:298:    subparsers.add_parser("gen", help="Generate HARNESS-MODELS-REGISTRY.generated.md")
./utils/py/workspace_manager.py:12:3. Soft-quarantine of ignored scratch and deleted clones into .xyz/trash/<timestamp>-<name>/ with a 72h reaper.
./utils/py/workspace_manager.py:274:        scratch_dir = os.path.join(p, ".relay-scratch")
./utils/py/workspace_manager.py:278:                shutil.copytree(scratch_dir, os.path.join(dest_trash, ".relay-scratch"), dirs_exist_ok=True)
./relay-system/2026-08-20/gh111-gh108-qa.md:126:### Review salvaged from openrouter/qwen/qwen3.8-max transcript (aider-turn.sh · GH-251)
./relay-system/2026-08-20/gh111-gh108-qa.md:1407:did not land the review itself — `aider-turn.sh`'s GH-251 salvage recovered it from the transcript,
./relay-system/2026-08-20/gh94-pr100-feasibility-review.md:28:2. **Feasibility Review for GH-101:** Evaluate the feasibility and architectural risks of promoting `script_runner.py` into core runtimes (`consult.py`, `.relay-scratch/` probes, and `relay-turn-lib`). Grade findings into `[Blocker]`, `[Should]`, `[Nit]`, or `[Pass]`.
./relay-system/2026-08-20/gh94-pr100-feasibility-review.md:45:- **[Blocker] Containment is implemented as an unused helper, not an execution boundary.** `run_script_safely()` resolves `work_dir` and launches arbitrary `python -c`, `bash -c`, or `--file` content, but never calls `validate_path_containment()` (nor accepts a designated `$WORK` root). It therefore permits `--workdir` outside a scratch root, an absolute `--file` outside it, and direct code such as `open('../x', 'w')` or `.git/config` mutation. `start_new_session=True` confines signals only; it cannot confine filesystem access. This contradicts the stated use-boundary containment invariant and is an absolute no-go for `consult.py`, relay turns, or `.relay-scratch/` diagnostics. Fix the security model first: validate every runner-owned input/output path against an explicit, pre-created scratch root, and execute arbitrary model code only in a separate disposable full clone/sandbox with a capability-limited interface. Path validation alone cannot mediate arbitrary in-script file or subprocess access.
./utils/py/relay_drive.py:513:        reason_file = os.path.join(root_dir, ".relay-scratch", "escalation-reason")
./test/gh115-round-cap.sh:134:mkdir -p "$ROOT/.relay-scratch"
./test/gh115-round-cap.sh:135:echo "stale-reason" > "$ROOT/.relay-scratch/escalation-reason"
./skills/marathon-cleanup/SKILL.md:2:name: marathon-cleanup
./utils/py/marathon_drive.py:2224:                    if not in_phases and not p.startswith(".tick/") and not p.startswith(".xyz/") and not p.startswith(".relay-scratch/"):
./utils/py/marathon_drive.py:2611:        reason_file = os.path.join(xyz_harness, ".relay-scratch", "escalation-reason")
./utils/py/marathon_drive.py:2779:        reason_file = os.path.join(xyz_harness, ".relay-scratch", "escalation-reason")
./relay-system/2026-08-20/gh111-dialed-in-qa.md:149:**The aider/qwen verification turn FAILED to produce a review** (relay-drive exit 5). The model never emitted a findings block; it entered a meta-loop reasoning about the response format itself — whether to update the `NEXT:` line, and how to nest triple-backtick fences when echoing a file that contains them. `aider-turn.sh`'s GH-251 salvage then did its documented job and appended the turn transcript verbatim, which preserved ~1,200 lines of chain-of-thought as relay content. That salvage block is removed here; this note replaces it so the failure stays on the record rather than being silently deleted.
./skills/marathon-cleanup/agents/openai.yaml:4:  default_prompt: "Use $marathon-cleanup to audit active marathon files and archive only fully verified completed work."
./test/gh174-harness-registry.sh:126:BLOG_FILE="$ROOT/docs/blog-frontier-benchmarks.md"
./skills/marathon-cleanup/install.sh:13:SKILL_NAME="marathon-cleanup"
./relay-system/2026-08-20/709506-agent2agent-gh-102-telemetry-architecture-gh-101-test-2-consult-dogf.md:52:**1. `consult.py --tool-mode programmatic` integration.** Copy the boundary `consult.sh` already proved rather than inventing one: each advisor runs in a throwaway git worktree cut from current state, and anything written there dies with it. Wire `script_runner.py` as the execution backend *inside* that worktree, and make it **fail-closed the same way GH-94 did** (fc9b0b3): if worktree creation or the seatbelt profile fails, refuse to start — never fall back to executing against the live tree. Three specifics: (a) keep the flag default-off and purely additive — the advisory contract (final text is the deliverable) is unchanged; programmatic mode only changes how the advisor gathers evidence; (b) give probe output a sanctioned home per the GH-91 `.relay-scratch/` precedent instead of a new ad-hoc category — a probe that has nowhere to write its evidence fails a green turn, which is the exact defect GH-91 retired; (c) telemetry: don't silently widen schema 1.0 — add `tool_mode` behind a versioned minor bump so `checkin.py` can still parse mixed logs, and keep `tokens_source` triage untouched.
./relay-system/2026-08-20/709506-agent2agent-gh-102-telemetry-architecture-gh-101-test-2-consult-dogf.md:56:**3. Containment edge cases before dogfooding.** Four that have actually bitten this repo: (a) **empty containment root** — GH-564's class: a cleanup or write guard that resolves an empty fixture path reaches the caller's clone; assert the scratch root is non-empty, absolute, and inside the expected parent before any destructive op (the ffbce23 containment-root check is the template); (b) **EXIT-trap destruction on unverified paths** — the GH-177 repo-wipe: a sandbox-broken `mktemp` fed an `rm -rf` trap; verify before you destroy, and note the Bash-sandbox interplay generally (agy under sandbox exits 0 with *empty output* — treat empty output as hard failure, never as a quiet pass); (c) **mid-flight hand edits** — GH-141: never share a scratch checkout between a live session and a driven probe; per-run worktrees only; (d) single-turn probes should run with **no push, no keychain, declared egress** — same posture as the relay shims (commit-bypass guard + no-push), so a runaway probe's blast radius is one disposable directory.
./relay-system/2026-08-20/709506-agent2agent-gh-102-telemetry-architecture-gh-101-test-2-consult-dogf.md:71:   - Probe artifacts will write to the sanctioned `.relay-scratch/` directory per GH-91, with zero push and zero keychain access.
./relay-system/2026-08-20/gh102-commandcode-glm52-review.md:70:- **Verification artifacts:** `.relay-scratch/gh102-synthetic-run.log` (synthetic test PASS), `.relay-scratch/gh102-checkin-compare.log` (reproduced SUMMARY.md).
./relay-system/2026-08-20/gh102-commandcode-glm52-review.md:107:- **Verification artifacts:** `.relay-scratch/gh102-r2-synthetic.log` (synthetic PASS), `.relay-scratch/gh102-r2-checkin-compare.log` (reproduced SUMMARY.md), `.relay-scratch/gh102-r2-missing-log.log` (exit 2 confirmed), `.relay-scratch/gh102-r2-injection.log` (`bob's-test.sh` apostrophe probe — 1 clean record, no injection).
./utils/py/aider-turn.py:162:    # review in the transcript but landed NO relay-file append can be detected and salvaged after.
./utils/py/aider-turn.py:212:        # The GH-251 salvage block between the two is unaffected: it needs a NON-empty transcript,
./utils/py/aider-turn.py:216:    # GH-251 transcript-salvage backstop. On a REVIEW-ONLY turn (ALLOW_PATHS empty), if the relay file
./utils/py/aider-turn.py:231:                rf.write(f"\n\n---\n\n### Review salvaged from {aider_model} transcript (aider-turn.sh · GH-251)\n\n")
./utils/py/aider-turn.py:237:            print("aider-turn: review turn landed no relay-file delta but the transcript carried a graded review — salvaged it into the relay file (attributed; GH-251)", file=sys.stderr)
./relay-system/2026-08-21/gh141-fuzz-ate-qa.md:1:# RELAY · GH-141 fuzzing + ATE overhaul — plan QA & brainstorm
./relay-system/2026-08-21/gh141-fuzz-ate-qa.md:345:the ownership from the fuzz-loop/ATE disposition being decided here. Carrying it inside GH-141 would
./relay-system/2026-08-21/gh141-fuzz-ate-qa.md:348:What stays in GH-141: the open recommendation that **the incidence comparison between input-boundary
./relay-system/2026-08-21/gh141-fuzz-ate-qa.md:785:  GH-141; promote the tick/relay model only through its own scoped issue. Cost remains 2–3 days.
./relay-system/2026-08-21/gh141-fuzz-ate-qa.md:857:  make GH-141 unclosable on its own terms. The second is stronger — those are four different axes, and
./relay-system/2026-08-21/gh141-fuzz-ate-qa.md:859:  "Split out" section; what stays in GH-141 is the **recommendation that the incidence comparison
./relay-system/2026-08-21/gh141-fuzz-ate-qa.md:962:  work to a linked issue keeps the useful incidence comparison without making GH-141 own a second
./relay-system/2026-08-21/gh141-fuzz-ate-qa.md:1001:leaving `issue_body.md` behind with no signal to any caller). GH-141 carries a comment linking it as a
./relay-system/2026-08-21/gh141-fuzz-ate-qa.md:1122:separately with a hermetic repro and linked from GH-141 as a Phase 4 prerequisite. Worth stating
./relay-system/2026-08-21/658731-agent2agent-gh-124-closeout-plan-adjudicate-four-safety-contract-ref.md:49:  - Swept full clones are moved into `.xyz/trash/<timestamp>-<basename>/` rather than deleted immediately.
./relay-system/2026-08-21/658731-agent2agent-gh-124-closeout-plan-adjudicate-four-safety-contract-ref.md:122:  3. **Ignored-Content Snapshotting:** Before invoking `git worktree remove`, archive all untracked/ignored contents (`.relay-scratch/`, debug artifacts) into `.xyz/trash/<timestamp>-<name>/` so ignored work is never destroyed.
./test/synthetic/gh101-relay-programmatic-stress.sh:63:# Write probe output into .relay-scratch
./test/synthetic/gh101-relay-programmatic-stress.sh:64:mkdir -p .relay-scratch
./test/synthetic/gh101-relay-programmatic-stress.sh:65:echo "{\"probe\": \"pass\", \"tool_mode\": \"programmatic\"}" > .relay-scratch/probe_telemetry.json
./test/synthetic/gh101-relay-programmatic-stress.sh:83:Basis: Programmatic probe verified in .relay-scratch
./test/synthetic/gh101-relay-programmatic-stress.sh:115:if [ -d "$REPO/.relay-scratch" ] || [ -f "$REPO/probe_telemetry.json" ]; then
./relay-system/2026-08-21/gh-124-127-merge-sequence-review.md:129:- [Should] Retain the exact-SHA local-gate receipt before deleting the disposable clone, and explicitly verify it was written. `ci-local.sh` intentionally tolerates `gate-record.sh` failure (`|| true`), and its `.gate-evidence/` record is ignored; deleting the clone otherwise deletes the stated qualification evidence. Citation: `ci-local.sh:361`; `utils/gate-record.sh:59-60,104`; `.gitignore:70`.
./relay-system/2026-08-21/gh-124-127-merge-sequence-review.md:143:- [Blocker: DoD placeholder] **Implemented.** DoD adopted: both merges land on the recorded `development` base; #128 re-verified (head SHA, mergeability, guard) after #127; `bash ci-local.sh` exits 0 on the exact merged SHA in a disposable clone; `python3 utils/py/releases_app.py check` green; gate receipt copied out before the clone is deleted.
./utils/py/consult.py:456:            "programmatically via script_runner.py with output directed to .relay-scratch/ inside the isolation worktree."
./utils/py/consult.py:497:            os.makedirs(os.path.join(wt, ".relay-scratch"), exist_ok=True)
./utils/py/consult.py:504:            base_env["RELAY_SCRATCH_DIR"] = os.path.join(wt, ".relay-scratch")
./test/synthetic/gh102-telemetry-schema.sh:5:#     third alias GH-141's review counted)
./test/synthetic/gh101-consult-programmatic.sh:75:# Assert that parent repo has no leaked .relay-scratch or probe files
./test/synthetic/gh101-consult-programmatic.sh:76:if [ -d "$REPO/.relay-scratch" ] || [ -f "$REPO/probe_output.txt" ]; then
./relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.agy.md:19:Standard-merge #127 and #128 (noting GH-123 drift), pull `development` into a fresh disposable clone, run `bash ci-local.sh` there to qualify the final SHA, and delete the clone and local branches.
./utils/py/harness_turn_logger.py:18:    """Context manager for transparently logging turn execution into harnesses.db."""
./utils/py/harness_turn_logger.py:104:        """Record post-turn AI / reviewer evaluation into harnesses.db."""
./relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.codex.md:1095:  "gh426-worktree-leak.sh"       # GH-426 (an isolated turn's creation is absent from BOTH the target and the harness) — 7/0; control in test/baselines/GH-426-negative-control.md: 2 red here + 1 red in gh410's C4c. The reported cause (worktree teardown) is FALSIFIED and the suite pins the real one: the agent binary is invoked twice, and the GH-375 auth probe ran with the caller's CWD, outside containment
./relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.codex.md:1124:  "gh527-destructive-git-guard.sh"     # GH-527 (a tree-overwriting git command snapshots the tracked files it destroys into .tick/orphan-backups/ first) — 26/0; controls: a no-op guard drops 9 assertions, and a blanket that fires on a CLEAN tree drops exactly the control assertion. Clean-tree silence is defended by TWO conditions, so it takes a combined mutation to falsify — recorded in test/baselines/GH-527-negative-control.md
./relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.codex.md:1129:  "rtl-orphan-backup.sh"         # GH-141 (concurrent peer-edit race: revert unchanged, content recoverable)
./relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.codex.md:1130:  "gh91-relay-scratch.sh"          # GH-91 (sanctioned .relay-scratch/ for builder verification output: exempted in rtl_check + rtl_worktree_end, pre-created by begin, named in the turn prompt; never copied back, discarded under ROOT; controls pin that stray writes and lookalike prefixes still go off-lane) — 15/0, driven at the lib-function level, no builder binary needed
./relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.codex.md:3451:1c1effa2 fix(marathon-drive): exempt harness-owned .xyz/ and .relay-scratch/ from require-clean dirty check
./relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.codex.md:3485:1c1effa2 fix(marathon-drive): exempt harness-owned .xyz/ and .relay-scratch/ from require-clean dirty check
./relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.codex.md:3567:CHANGELOG.md-382-- **The `releases-skill` gate is unregistered until its file lands — `development`'s suite was red in every clone but one.** The registration reached `development` while the gate file it names did not, so `validate.sh` exited 127 for everyone whose working tree did not happen to hold the author's uncommitted copy — and green for the one session that could not see the breakage. That is #461's defect in mirror image: there, a gate that exists but is unregistered is invisible; here, a registration with no gate is a permanent red that says nothing about the code, and since GH-544 put the suite on the push boundary it was refusing every push from every session. **The test is not at fault and was not deleted** — it passes **26/0** in the tree where its inputs exist. It needs the whole consolidation (the plural skill directory, removal of the legacy singular one, and the router / PDDA-contract routing updates), which is in flight and uncommitted elsewhere; landing that change re-enables the line in the same commit. Deliberately not completed here: pulling ~7 files of another session's uncommitted work across — including its own CHANGELOG prose — to satisfy a one-line registration would be a much larger intervention than the breakage warrants. Suite goes from 3 failures to 1. **RESOLVED the same day** — the consolidation landed and the line was re-registered in the commit that brought the gate file with it, which is exactly the condition recorded here. Kept rather than deleted because a ~2h window in which the shared branch refused every session's push is a real event, and the rule it produced is worth stating once: **register a gate and its file together, or neither.** → [#461](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/461)
./relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.codex.md:3578:CHANGELOG.md-418-- **A tree-overwriting git command now leaves what it destroys recoverable (GH-527).** Three times in one session an agent used a git *history* command to undo a *working-tree* experiment: a tree-wide `git stash` that took four other sessions' files and timed out before its `pop`; a `git checkout -- <path>` that restored HEAD rather than the pre-edit state and ate ~60 lines of new tests; a `git reset --hard origin/development` that took four sessions' tracked modifications plus `.claude/settings.json`, which never came back. **The shape is snapshot-then-allow, not refuse-when-dirty** — `relay-automation/hooks/gh527-destructive-git-guard.sh` copies the doomed **tracked** files into `.tick/orphan-backups/` and always exits 0. That is the shape this repo already chose for the same problem (`rtl_check` does exactly this before reverting an off-allowlist edit, GH-141); refusing instead would fire on every legitimate solo cleanup and train an override reflex, and it could not satisfy the issue's own acceptance criterion requiring *demonstrated* recovery. Tracked-only is not an oversight: the issue **reproduced** the blast radius in a fixture — tracked modifications die, untracked files survive — so snapshotting untracked files would be noise hiding the signal. **The `AGENTS.md` rail is the explanation, not the fix:** the issue falsified a doc-rail-only proposal against the session's own ledger — every mechanical guard (frozen-twin, `path-integrity.sh`, the GH-472 SIGPIPE detector) caught the author; neither written warning did. 26/0, registered, recovery demonstrated end-to-end. **Control worth reading:** clean-tree silence is defended by *two* independent conditions, so two separate single-line mutations both stayed green and it took a combined mutation to produce exactly one red — recorded in `test/baselines/GH-527-negative-control.md` rather than presented as a clean first try. → [GH-527-DESTRUCTIVE-GIT-GUARD.md](PROJECT/2-WORKING/GH-527-DESTRUCTIVE-GIT-GUARD.md) · [#527](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/527)
./relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.codex.md:3613:CHANGELOG.md-677-- **GH-273: Phase 2 SHIPPED — `.claude/loose-ends-sequence.md` gives this repo a real custom end sequence.** Fired via `swarm-preflight → marathon-drive` with `--phase-id gh273-phase2`. Contract was grounded in a direct read of `~/.claude/skills/loose-ends/SKILL.md` rather than inferred: the manifest mechanism already existed (project-local `.claude/loose-ends-sequence.md` takes precedence over the global one, `### *` heading, `- cmd` bullets, paths resolved relative to the manifest's own directory) — Phase 2 only needed to author the file. Codex got the path-resolution subtlety right unprompted: bullets are `../utils/pdda/pdda.sh run` and `../utils/roadmap-dashboard.sh`, correctly relative to `.claude/` (the manifest's directory), not repo root. The third bullet is a reminder that `PROJECT/2-WORKING` docs move to `3-COMPLETED` only once `marathon-cleanup` classifies them `VERIFIED-COMPLETE`, never on a bare status-word edit. Same flaky-gate pattern as Phases 0-1 (`test/xyz-harness-hooks.sh`'s pre-existing "relay green count" assertion — 3 for 3 now, unrelated to any of the three builds); confirmed clean each time, closed out manually. → [#273](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/273) · [GH-273-MARATHON-CLOSEOUT-AUTOMATION.md](PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md)
./relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.codex.md:3616:CHANGELOG.md-680-- **GH-273: Phase 0 SHIPPED — the `UserPromptSubmit` skill-nudge hook is live.** Fired via `swarm-preflight → marathon-drive` (Codex builder, agy reviewer, Approved after 2 turns): `relay-automation/hooks/skill-nudge.sh` (89 lines, follows the `xyz-vendor-reminder.sh` fail-open/opt-out-env/exit-0-always contract) matches only the marathon-lifecycle keyword table from the plan doc — "add ... to marathon"/"fire the marathon"/"preflight sweep/all"/"dry-run each plan" → nudges `marathon-triage`; "commit and push" + ("close issues"/"move to 3-completed"/"PDDA sweep") in the same prompt → nudges `loose-ends` + `marathon-cleanup`. Unrelated prompts stay silent. Wired into this repo's `.claude/settings.json` alongside the existing `PreToolUse`/`SessionStart` hooks. 14 new cases in `test/xyz-harness-hooks.sh`, all passing. **Process note, worth recording:** the `bash validate.sh` pre-advance gate initially reported FAILED, but the actual red was a pre-existing flaky assertion in the same test file ("relay green count", last touched by the unrelated GH-232 fix) — none of the 14 new nudge assertions failed. Confirmed flaky, not regressive: the test file alone re-ran 61/61 clean, and a full `validate.sh` re-run immediately after was exit 0 with nothing failing. Re-invoking `marathon-drive` to retry the gate then hit a real harness limitation — the `MARATHON-P1-TURN` tick token was already `status: done` from the successful first run, so it couldn't be reopened; the retry re-rendered `phases/p1/RELAY.md` back to a fresh `STATUS: Open` template and failed immediately after (exit 1), discarding the accurate Approved record. Recovered by `git revert`ing that render commit (restoring the true Approved state) and closing the phase out manually rather than re-driving a third time — the code was already correct and committed; only the harness's own bookkeeping needed the fix. Full detail: `phases/p1/ESCALATION.md` § Resolution. → [#273](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/273) · [GH-273-MARATHON-CLOSEOUT-AUTOMATION.md](PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md)
./relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.codex.md:3617:CHANGELOG.md-681-- **GH-273: Phase 0 added — a `UserPromptSubmit` skill-nudge hook, folded into the plan doc so the design is documented and searchable before it's built.** Operator raised: could a hook remind them that skills like `marathon-triage`/`loose-ends`/`marathon-cleanup` already exist, so they stop hand-typing the ceremony those skills already automate? Confirmed the mechanism is already live in this repo's own `.claude/settings.json` (2 `PreToolUse` guards + a `SessionStart` reminder, `relay-automation/hooks/xyz-vendor-reminder.sh`) and picked `UserPromptSubmit` over another `SessionStart` entry — a per-prompt nudge matches the *specific* thing being typed, where a once-per-session reminder goes stale after the first screen. New Phase 0 in `GH-273-MARATHON-CLOSEOUT-AUTOMATION.md`: `relay-automation/hooks/skill-nudge.sh`, following the `xyz-vendor-reminder.sh` fail-open/opt-out-env/exit-0-always contract, matched against a narrow marathon-lifecycle keyword table (documented in the doc, not just the script) so it stays silent on unrelated prompts. Preflight contract redrafted to target Phase 0 (was Phase 1); frontmatter `phases: 4→5`, `effort: 4→5`. → [#273](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/273) · [GH-273-MARATHON-CLOSEOUT-AUTOMATION.md](PROJECT/1-INBOX/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md)
./relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.codex.md:3618:CHANGELOG.md:682:- **GH-273: marathon pre-flight/post-flight ceremony automation — planned, not yet built.** A Fable 5 web app's analysis of ~583 logged Claude Code prompts (`PROJECT/1-INBOX/LESS-TYPING.md`, source: `0. Claude Prompts.md`) found two heavily repeated manual sequences: pre-marathon (capture → add to plan → preflight sweep → cleanup → dry-run → fire, ~25 occurrences) and post-marathon (commit/push → PR → merge → pull/switch → close issues → move docs → PDDA sweep → Slack, ~45 combined). Verified against the raw corpus (78 commit+push mentions, 12+ "add to marathon" phrasings, 8 "move to 3-COMPLETED", 6 "close issue", 5 "PDDA sweep" across 583 entries) — the repetition is real. **Cross-checked against existing tooling before accepting the recommendation as-is:** the pre-marathon half largely overlaps `skills/marathon-triage/SKILL.md` (which already reconciles/ranks/preflights, and deliberately refuses to fire), so `/pre-marathon` will wrap it rather than reimplement it; the post-marathon half is a genuine gap — `marathon-cleanup` is archive-only and `loose-ends` is generic, neither does the PR→merge→close-issues chain. 4-phase plan drafted: `/pre-marathon` + `/post-marathon` slash commands → per-repo `loose-ends-sequence.md` manifest → `marathon-closeout.sh` extraction → symmetric `--post-approve-cmd` harness flag (mirrors `marathon_drive.py`'s existing `--pre-advance-cmd`). Filed, captured, ledgered, and folded into today's marathon queue (Wave 1, `MARATHON-PLAN-2026-07-22.md`) — no phase fired yet. → [#273](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/273) · [GH-273-MARATHON-CLOSEOUT-AUTOMATION.md](PROJECT/1-INBOX/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md)
./relay-system/2026-08-21/gh124-merge-seq-173029/gh124-merge-seq.codex.md:3820:1c1effa2 fix(marathon-drive): exempt harness-owned .xyz/ and .relay-scratch/ from require-clean dirty check
./RELEASES-PREVIEW.html:375:<script id="ledger-data" type="application/json">{"meta": {"title": "Planning ledgers", "subtitle": "XYZ-forge · releases.db · read-only", "generatedAtDisplay": "2026-08-24 03:30:06Z", "sourceLabel": "releases.db · schema v5", "repoUrl": "https://github.com/HiQS-Suite/XYZ-forge"}, "sync": null, "telemetry": {"dbGeneration": 114, "receipts": 128, "lastSyncDisplay": "2026-08-24T03:30", "lastSyncAgoDisplay": "in 1 day", "releasesOpen": 6, "releasesTotal": 12, "releasesOverdue": 0}, "ratedTasks": [{"id": "GH-67", "title": "Commandcode builder default widened to `--yolo` — closer evaluation → possible build", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 88, "sev": 80, "appeal": 45, "effort": 70, "calc": 283, "effectiveScore": 340}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/67"}, "override": {"value": 340, "hot": true}}, {"id": "GH-181", "title": "repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 90, "sev": 75, "appeal": 90, "effort": 60, "calc": 315, "effectiveScore": 315}, "links": null}, {"id": "GH-174", "title": "Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 85, "sev": 75, "appeal": 95, "effort": 45, "calc": 300, "effectiveScore": 300}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/174"}}, {"id": "GH-155", "title": "3rd Gen ATE & Fuzzing", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 70, "appeal": 90, "effort": 50, "calc": 295, "effectiveScore": 295}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/155"}}, {"id": "GH-165", "title": "Post-Merge Wave & Marathon Lifecycle Reconciler (Docs, ROADMAP, DB, Views, and Planning)", "release": null, "lane": "Completed", "metrics": {"pri": 90, "sev": 80, "appeal": 90, "effort": 35, "calc": 295, "effectiveScore": 295}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/165"}}, {"id": "GH-113", "title": "headless agy builder writes root scratch files, tripping containment (exit 6)", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 85, "sev": 60, "appeal": 85, "effort": 60, "calc": 290, "effectiveScore": 290}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/113"}}, {"id": "GH-148", "title": "DeepSeek Harness (dsh) integration & deepseek-turn shim for OpenRouter DeepSeek V4 Pro", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 75, "appeal": 90, "effort": 40, "calc": 290, "effectiveScore": 290}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/148"}}, {"id": "GH-168", "title": "wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 70, "calc": 290, "effectiveScore": 290}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/168"}}, {"id": "GH-141", "title": "make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison", "release": "Bulkhead", "lane": "ad-hoc detour", "metrics": {"pri": 80, "sev": 65, "appeal": 85, "effort": 55, "calc": 285, "effectiveScore": 285}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/141"}}, {"id": "GH-114", "title": "headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7)", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 80, "sev": 60, "appeal": 80, "effort": 60, "calc": 280, "effectiveScore": 280}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/114"}}, {"id": "GH-115", "title": "marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 75, "sev": 50, "appeal": 85, "effort": 70, "calc": 280, "effectiveScore": 280}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/115"}}, {"id": "GH-180", "title": "repro_builder crashes on timeout telemetry records (exit_code: null → TypeError)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 70, "sev": 45, "appeal": 85, "effort": 80, "calc": 280, "effectiveScore": 280}, "links": null}, {"id": "GH-77", "title": "`/standup` — session-scoped triage: what did I leave open, what is rotting, is the plan still right?", "release": null, "lane": "Completed", "metrics": {"pri": 95, "sev": 70, "appeal": 85, "effort": 30, "calc": 280, "effectiveScore": 280}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/77"}}, {"id": "GH-124", "title": "eliminate end-of-day closeout friction — automated phase QA receipts, auto-PR creation, and clone lifecycle hygiene", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 60, "appeal": 90, "effort": 40, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/124"}}, {"id": "GH-132", "title": "feat(skills): formal /review-xyz code review skill & multi-model harness", "release": null, "lane": "Completed", "metrics": {"pri": 80, "sev": 70, "appeal": 85, "effort": 40, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/132"}}, {"id": "GH-170", "title": "Agent2Agent: close transcript glitches and harden publishing", "release": null, "lane": "Completed", "metrics": {"pri": 75, "sev": 60, "appeal": 85, "effort": 55, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/170"}}, {"id": "GH-2", "title": "test-suite run relocated an untracked file into .tick/orphan-backups/", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 55, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/2"}}, {"id": "GH-8", "title": "kernel boundary hardening — CLI numeric validation, task/agent format contract", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 65, "calc": 275, "effectiveScore": 275}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/8"}}, {"id": "GH-184", "title": "committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 60, "sev": 40, "appeal": 80, "effort": 90, "calc": 270, "effectiveScore": 270}, "links": null}, {"id": "GH-75", "title": "single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 90, "sev": 40, "appeal": 85, "effort": 55, "calc": 270, "effectiveScore": 270}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/75"}}, {"id": "GH-111", "title": "retire manifest FREEZE; tasks and marathons are DIALED IN to exactly one release, as a database state", "release": null, "lane": "Completed", "metrics": {"pri": 85, "sev": 75, "appeal": 70, "effort": 35, "calc": 265, "effectiveScore": 265}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/111"}}, {"id": "GH-182", "title": "self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 55, "calc": 265, "effectiveScore": 265}, "links": null}, {"id": "GH-50", "title": "sandboxed git --track / branch -D half-applies and loses uncommitted work", "release": "Bulkhead", "lane": "in progress", "metrics": {"pri": 65, "sev": 35, "appeal": 85, "effort": 80, "calc": 265, "effectiveScore": 265}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/50"}}, {"id": "GH-183", "title": "active_explorer env-family fuzzing unsound (base_env={} hardcoded, one always-deferring vector, ambient-env leakage)", "release": "Bulkhead", "lane": "queue", "metrics": {"pri": 65, "sev": 50, "appeal": 75, "effort": 70, "calc": 260, "effectiveScore": 260}, "links": null}, {"id": "GH-10", "title": "prevent-half of containment: require_fixture adoption across the fixture-creating suites + adoption guard + ci-local identity bracket", "release": null, "lane": "Completed", "metrics": {"pri": 55, "sev": 70, "appeal": 50, "effort": 80, "calc": 255, "effectiveScore": 255}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/10"}}, {"id": "GH-144", "title": "Agent2Agent 3+ participant onboarding + read-only status quick wins", "release": null, "lane": "Completed", "metrics": {"pri": 55, "sev": 30, "appeal": 80, "effort": 90, "calc": 255, "effectiveScore": 255}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/144"}}, {"id": "GH-91", "title": "a build turn has nowhere to write verification output — containment kills a complete, green turn", "release": null, "lane": "Completed", "metrics": {"pri": 60, "sev": 65, "appeal": 55, "effort": 75, "calc": 255, "effectiveScore": 255}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/91"}}, {"id": "GH-153", "title": "RELEASES dashboard sidebar + full-cycle rollup (technical spike)", "release": null, "lane": "Completed", "metrics": {"pri": 70, "sev": 55, "appeal": 80, "effort": 45, "calc": 250, "effectiveScore": 250}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/153"}}, {"id": "GH-197", "title": "two-tier xyz-vendor.sh: Tier 1 core-harness default, Tier 2 opt-in RELEASES overlay + onboarding SOP (GH-105 follow-up)", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 80, "sev": 55, "appeal": 65, "effort": 50, "calc": 250, "effectiveScore": 250}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/197"}}, {"id": "GH-108", "title": "pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override)", "release": "Daybreak", "lane": "cut", "metrics": {"pri": 80, "sev": 50, "appeal": 75, "effort": 40, "calc": 245, "effectiveScore": 245}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/108"}}, {"id": "GH-105", "title": "vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on)", "release": "Cargo", "lane": "queue", "metrics": {"pri": 75, "sev": 50, "appeal": 60, "effort": 45, "calc": 230, "effectiveScore": 230}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/105"}}, {"id": "GH-32", "title": "RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 70, "sev": 50, "appeal": 65, "effort": 35, "calc": 220, "effectiveScore": 220}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/32"}}, {"id": "GH-5", "title": "kernel robustness: node:test unit runner", "release": "Bulkhead", "lane": "ad-hoc detour", "metrics": {"pri": 45, "sev": 40, "appeal": 45, "effort": 80, "calc": 210, "effectiveScore": 210}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/5"}}, {"id": "GH-35", "title": "3-tier test suite selection (docs / utility subsystems / core) + CPU governance", "release": null, "lane": "Completed", "metrics": {"pri": 55, "sev": 45, "appeal": 50, "effort": 45, "calc": 195, "effectiveScore": 195}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/35"}}, {"id": "GH-61", "title": "RELEASES ledger durability hardening (GH-57 follow-up)", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 45, "sev": 55, "appeal": 40, "effort": 50, "calc": 190, "effectiveScore": 190}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/62"}}, {"id": "GH-17", "title": "SOP for evaluating new agent harnesses and frontier models", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 45, "sev": 30, "appeal": 50, "effort": 60, "calc": 185, "effectiveScore": 185}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/17"}}, {"id": "GH-42", "title": "relay automation: supported Commandcode turn-taker", "release": null, "lane": "Completed", "metrics": {"pri": 50, "sev": 35, "appeal": 55, "effort": 45, "calc": 185, "effectiveScore": 185}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/42"}}, {"id": "GH-195", "title": "marathon-root-audit's blind spot: a direct `python3 marathon_drive.py` call", "release": null, "lane": "Completed", "metrics": {"pri": 60, "sev": 40, "appeal": 50, "effort": 20, "calc": 170, "effectiveScore": 170}, "links": null}, {"id": "GH-28", "title": "RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 40, "sev": 35, "appeal": 40, "effort": 55, "calc": 170, "effectiveScore": 170}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/28"}}, {"id": "GH-18", "title": "Harness evaluation: Command Code (cmd) and model matrix", "release": null, "lane": "Queue / parked intake", "metrics": {"pri": 35, "sev": 25, "appeal": 45, "effort": 55, "calc": 160, "effectiveScore": 160}, "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/18"}}], "justFinished": {"issue": "v0.7.2", "title": "Daybreak shipped", "closedDateDisplay": "2026-08-23", "closedAgoDisplay": "today", "issueUrl": "https://github.com/HiQS-Suite/XYZ-forge/issues/77"}, "whatsNext": {"issue": "v0.7.3", "title": "Bulkhead", "note": "target 2026-09-05 · in 13 days", "issueUrl": "https://github.com/HiQS-Suite/XYZ-forge/issues/179"}, "releases": [{"id": "c-0-1-0", "slug": "quicksilver", "name": "Quicksilver", "version": "0.1.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-01", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Quicksilver", "blurb": "Python-authoritative Tier-A twins.", "exit": "Python-authoritative Tier-A twins. Licensed AGPL-3.0-only (`LICENSE`) with a commercial option (`LICENSE-COMMERCIAL.md`), adopted 2026-07-29 post-ship; the pre-existing conflicting `LICENSE.md` was removed 2026-07-30 (#372).", "detours": [], "roadmap": []}, {"id": "c-0-2-0", "slug": "litmus", "name": "Litmus", "version": "0.2.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-14", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Litmus", "blurb": "Make the checks capable of failing.", "exit": "Exit: `bash test/litmus-release.sh --release-gate` exits 0. Red today by design; turning it green is what \"done\" means. Its own negative control is `--mutate-evidence`, which must detect a stripped declaration and an unregistered gate. NOTE the honest limit, stated in that file: the audit proves registration, declaration shape and the absence of false completion claims. It does NOT prove a control was truly observed, because `gate_inventory.py` reads a declaration authored by the same person who wrote the gate. Recorded execution of each control is deliberately out of scope for this release.", "detours": [], "roadmap": []}, {"id": "c-0-3-0", "slug": "nightwatch", "name": "Nightwatch", "version": "0.3.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-14", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Nightwatch", "blurb": "An unattended marathon against a real target repo survives, records, and recovers.", "exit": "Exit: `bash test/nightwatch-release.sh --release-gate` exits 0. BUILT 2026-08-11 and red by design, exactly as Litmus's was; turning it green is what \"done\" means. It has two halves because a metadata audit cannot answer this release's question. Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), and has a RECORDED control under `test/baselines/`; it also cross-checks that this list and the `Manifest:` line below agree, since a boundary that disagrees with itself is not frozen. Half B executes the lifecycle cases rather than auditing them, delegating to the suites that already drive real children and kill them rather than growing a second driver fixture here. Status on 2026-08-11: manifest 8/8 complete; lifecycle 5 passing, 0 NOT COVERED — GOALPOST MET. The last gap was the hostile-target write-set case, closed by #514, which was filed while executing this release and deliberately NOT admitted to the manifest (discovery is not admission); it belongs to the lifecycle list because the exit criterion always named that case — what was missing was a suite driving it. That lane also corrected its own premise: the pre-fix tree does not dispatch a turn first, it dies at the render's `git add` with an unhandled `CalledProcessError` traceback, so the discriminating assertion is the absence of that traceback rather than the absence of a dispatch. Its own negative control is `--mutate-evidence` (34/0), which unregisters a gate and deletes a recorded control in a fixture copy, requires both to be detected, and re-checks the unmutated inputs green in the same run so an always-red detector cannot pass for one. Honest limit, inherited from Litmus: Half A reads a declaration and a filename and cannot know a recorded control was honestly recorded; Half B is what narrows that, and is why this criterion is a command that kills children rather than a checklist.", "detours": [], "roadmap": []}, {"id": "c-0-7-0", "slug": "ballast", "name": "Ballast", "version": "0.7.0", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-18", "extra": null, "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Ballast", "blurb": "Post-launch hardening: the launched repository holds up under a stranger's first run and an outside contributor's first push.", "exit": "Exit: `bash test/ballast-release.sh --release-gate` exits 0. NOT BUILT — writing it is Ballast's first task, before any member is fixed (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. Half A audits the frozen manifest: each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. Half B EXECUTES the stranger's path rather than auditing it: (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. SHIPPED 2026-08-18. `XYZ_BALLAST_STRANGER_RUNS=10 test/ballast-release.sh --release-gate` executed for real against a fresh disposable clone (`~/xyz-disposable/xyz-stranger-clone`): exit 0. Half A: 4 of 4 manifest members complete (#14, #15, #4, #3 — gate/registration/control/CLOSED-issue all confirmed). Half B: 4 of 4 passing (B1: 10/10 consecutive parallel runs with zero failures; B2a: ungated clone warning in-band; B2b: forced-red push refusal; B3: atomic-append cross-process stress case clean) — GOALPOST MET.", "detours": [], "roadmap": []}, {"id": "c-0-7-1", "slug": "bulwark", "name": "Bulwark", "version": "0.7.1", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-19", "extra": null, "itemsTotal": 3, "itemsOpen": 3, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Bulwark", "blurb": "Patch release on Ballast: the RELEASES ledger survives a git merge.", "exit": "Exit: test/gh32-releases-artifacts.sh, test/gh53-releases-merge-resolve.sh, test/gh54-merged-dump-refusals.sh and releases_app.py check all exit 0, AND this release's own merge into development resolves releases.sql without a hand-edit.", "detours": [], "roadmap": [{"id": "GH-52", "title": "issue GH-52", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/52"}}, {"id": "GH-53", "title": "issue GH-53", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/53"}}, {"id": "GH-54", "title": "issue GH-54", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/54"}}]}, {"id": "c-0-7-2", "slug": "daybreak", "name": "Daybreak", "version": "0.7.2", "status": "shipped", "flags": {}, "badge": {"type": "shipped", "label": "shipped"}, "dateLabel": "shipped", "date": "2026-08-23", "extra": null, "itemsTotal": 9, "itemsOpen": 0, "baseline": {"count": 9, "at": "2026-08-21T04:21:29Z", "source": "backfilled", "growth": 0}, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Daybreak", "blurb": "The /standup skill completes: collect.sh implements the eight bounded lens reads that feed triage.py, and the skill runs end-to-end.", "exit": "Exit: collect.sh --fixture emits all eight lenses; triage.py consumes each without a D5; test/gh77-standup-triage.sh green with per-lens assertions AND a per-lens degradation assertion; the skill runs end-to-end on this repo and its output fits the 15-line cap; validate.sh full gate green.", "detours": [], "roadmap": [{"type": "marathon", "id": "GH-77", "url": "https://github.com/HiQS-Suite/XYZ-forge/issues/77", "title": "Daybreak marathon", "meta": "planned", "state": "run", "cards": [{"id": "GH-79", "title": "issue GH-79", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/79"}}, {"id": "GH-80", "title": "issue GH-80", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/80"}}, {"id": "GH-81", "title": "issue GH-81", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/81"}}, {"id": "GH-82", "title": "issue GH-82", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/82"}}, {"id": "GH-83", "title": "issue GH-83", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/83"}}, {"id": "GH-84", "title": "issue GH-84", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/84"}}, {"id": "GH-85", "title": "issue GH-85", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/85"}}, {"id": "GH-86", "title": "issue GH-86", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/86"}}, {"id": "GH-87", "title": "issue GH-87", "marker": "done", "section": "done", "sectionLabel": "completed", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/87"}}]}, {"id": "GH-108", "title": "pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override)", "marker": "paused", "section": "deferred", "sectionLabel": "cut", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/108", "doc": "PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md"}, "metrics": {"pri": 80, "sev": 50, "appeal": 75, "effort": 40, "calc": 245, "effectiveScore": 245}}]}, {"id": "c-0-7-3", "slug": "bulkhead", "name": "Bulkhead", "version": "0.7.3", "status": "active", "flags": {"now": true}, "badge": {"type": "active", "label": "active"}, "dateLabel": "target", "date": "2026-09-05", "extra": "in 13 days", "itemsTotal": 13, "itemsOpen": 13, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Bulkhead", "blurb": "An unattended marathon survives its own harness.", "exit": "Exit: Each member suite (gh8, gh2, gh50, gh113, gh114, gh115, gh168) green and registered in validate.sh; full local gate green; manifest 7/7 shipped or explicitly cut.", "detours": [{"id": "GH-141", "title": "make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison", "marker": "wip", "section": "adhoc", "sectionLabel": "ad-hoc detour", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/141"}, "metrics": {"pri": 80, "sev": 65, "appeal": 85, "effort": 55, "calc": 285, "effectiveScore": 285}}, {"id": "GH-5", "title": "kernel robustness: node:test unit runner", "marker": "wip", "section": "adhoc", "sectionLabel": "ad-hoc detour", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/5"}, "metrics": {"pri": 45, "sev": 40, "appeal": 45, "effort": 80, "calc": 210, "effectiveScore": 210}}], "roadmap": [{"id": "GH-113", "title": "headless agy builder writes root scratch files, tripping containment (exit 6)", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/113", "doc": "PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md"}, "metrics": {"pri": 85, "sev": 60, "appeal": 85, "effort": 60, "calc": 290, "effectiveScore": 290}}, {"id": "GH-114", "title": "headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7)", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/114", "doc": "PROJECT/2-WORKING/GH-114-HEADLESS-TTY-IDLE-HANG.md"}, "metrics": {"pri": 80, "sev": 60, "appeal": 80, "effort": 60, "calc": 280, "effectiveScore": 280}}, {"id": "GH-115", "title": "marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/115", "doc": "PROJECT/3-COMPLETED/GH-115-ROUND-CAP-ESCALATION.md"}, "metrics": {"pri": 75, "sev": 50, "appeal": 85, "effort": 70, "calc": 280, "effectiveScore": 280}}, {"id": "GH-168", "title": "wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/168", "doc": "PROJECT/2-WORKING/GH-168-WAVE-RECONCILE-SCOPE.md"}, "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 70, "calc": 290, "effectiveScore": 290}}, {"id": "GH-8", "title": "kernel boundary hardening — CLI numeric validation, task/agent format contract", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/8", "doc": "PROJECT/3-COMPLETED/GH-8-KERNEL-BOUNDARY-HARDENING.md"}, "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 65, "calc": 275, "effectiveScore": 275}}, {"id": "GH-2", "title": "test-suite run relocated an untracked file into .tick/orphan-backups/", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/2", "doc": "PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md"}, "metrics": {"pri": 80, "sev": 55, "appeal": 85, "effort": 55, "calc": 275, "effectiveScore": 275}}, {"id": "GH-50", "title": "sandboxed git --track / branch -D half-applies and loses uncommitted work", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/50", "doc": "PROJECT/2-WORKING/GH-50-SANDBOXED-GIT-HALF-APPLY.md"}, "metrics": {"pri": 65, "sev": 35, "appeal": 85, "effort": 80, "calc": 265, "effectiveScore": 265}}, {"id": "GH-180", "title": "repro_builder crashes on timeout telemetry records (exit_code: null → TypeError)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/180", "doc": "PROJECT/3-COMPLETED/GH-180-REPRO-TIMEOUT-CRASH.md"}, "metrics": {"pri": 70, "sev": 45, "appeal": 85, "effort": 80, "calc": 280, "effectiveScore": 280}}, {"id": "GH-181", "title": "repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/181", "doc": "PROJECT/3-COMPLETED/GH-181-REPRO-ADAPTER-FIDELITY.md"}, "metrics": {"pri": 90, "sev": 75, "appeal": 90, "effort": 60, "calc": 315, "effectiveScore": 315}}, {"id": "GH-182", "title": "self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design", "marker": "wip", "section": "wip", "sectionLabel": "in progress", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/182", "doc": "PROJECT/2-WORKING/GH-182-HEALER-FACADE-SAFETY.md"}, "metrics": {"pri": 75, "sev": 55, "appeal": 80, "effort": 55, "calc": 265, "effectiveScore": 265}}, {"id": "GH-183", "title": "active_explorer env-family fuzzing unsound (base_env={} hardcoded, one always-deferring vector, ambient-env leakage)", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/183", "doc": "PROJECT/3-COMPLETED/GH-183-EXPLORER-ENV-SOUNDNESS.md"}, "metrics": {"pri": 65, "sev": 50, "appeal": 75, "effort": 70, "calc": 260, "effectiveScore": 260}}, {"id": "GH-184", "title": "committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Labs/XYZ-forge/issues/184", "doc": "PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md"}, "metrics": {"pri": 60, "sev": 40, "appeal": 80, "effort": 90, "calc": 270, "effectiveScore": 270}}, {"id": "GH-174", "title": "Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator", "marker": "done", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/174", "doc": "PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md"}, "metrics": {"pri": 85, "sev": 75, "appeal": 95, "effort": 45, "calc": 300, "effectiveScore": 300}}]}, {"id": "c-0-9-0", "slug": "cargo", "name": "Cargo", "version": "0.9.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-09-19", "extra": "in 27 days", "itemsTotal": 2, "itemsOpen": 2, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Cargo", "blurb": "The harness travels with its ledger: the RELEASES DB system (releases_app.py CLI + merge resolver + FAQs) and the GH-103 HTML timeline generator (utils/timeline/) ship inside every vendored .xyz/ payload as an optional, never-wired-by-default add-on — a 'when you're ready' module a target repo enables by running releases init itself, matching RELEASES.md's own OPTIONAL philosophy (GH-381).", "exit": "Exit: A repo vendored with xyz-vendor.sh can, with zero extra downloads, run releases init/add and export_timeline.py --preview from .xyz/ against its own root, and xyz-sync.sh update preserves the target's ledger state (GH-312 preserve list). Nothing runs until the user invokes it.", "detours": [], "roadmap": [{"id": "GH-105", "title": "vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on)", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/105", "doc": "PROJECT/1-INBOX/GH-105-VENDOR-RELEASES-ADDON.md"}, "metrics": {"pri": 75, "sev": 50, "appeal": 60, "effort": 45, "calc": 230, "effectiveScore": 230}}, {"id": "GH-107", "title": "issue GH-107", "marker": "queued", "section": "queue", "sectionLabel": "queue", "links": {"issue": "https://github.com/HiQS-Suite/XYZ-forge/issues/107"}}]}, {"id": "c-0-6-0", "slug": "meter", "name": "Meter", "version": "0.6.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-09-26", "extra": "in 34 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Meter", "blurb": "XYZ can be handed to a stranger: an unauthenticated clone reaches a documented entry path and exercises a supported happy path with no private context, from a sanitized, secret-scanned tree.", "exit": "Exit: bash test/meter-release.sh --release-gate exits 0. NOT BUILT — written first, before any sanitization (the Litmus/Nightwatch ordering). Half A AUDITS the launch artifact: single-commit sanitized clone at the declared path; CHANGELOG.md byte-identical; .tick/, relay-system/, temp/ absent; PROJECT/ = PDDA scaffold + retained Meter example only; both LICENSE files present and consistent; secret-scan result names tool version and exact commit. Half B EXECUTES the stranger's path: a credential-less clone of the published commit completes one supported happy path with nothing author-machine-local. Negative control --mutate-evidence: plant a private path, remove CHANGELOG.md, leave a relay-system/ behind — detect all three, re-check unmutated inputs green in the same run. RED on arrival.", "detours": [], "roadmap": []}, {"id": "c-0-8-0", "slug": "sundown", "name": "Sundown", "version": "0.8.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-10-17", "extra": "in 55 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Sundown", "blurb": "Retire the twelve frozen Bash twins.", "exit": "Exit: NOT WRITTEN. Required before this release starts, per the ordering Litmus and Nightwatch both used and Meter is repeating — the gate is built first and arrives RED, because a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one.", "detours": [], "roadmap": []}, {"id": "c-0-4-0", "slug": "plumbline", "name": "Plumbline", "version": "0.4.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-11-14", "extra": "in 83 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "Plumbline", "blurb": "Assisted reflection and a bounded self-improvement loop, measured before either is trusted.", "exit": "Assisted reflection and a bounded self-improvement loop, measured before either is trusted. The reflection pipeline turns durable Nightwatch records into proposals (`proposals-sink.sh` gains its first production caller) and is graded against external ground truth — the 49 human-f…", "detours": [], "roadmap": []}, {"id": "c-0-5-0", "slug": "lantern", "name": "Lantern", "version": "0.5.0", "status": "draft", "flags": {}, "badge": {"type": "draft", "label": "draft"}, "dateLabel": "target", "date": "2026-12-12", "extra": "in 111 days", "itemsTotal": 0, "itemsOpen": 0, "baseline": null, "milestoneUrl": "https://github.com/HiQS-Suite/XYZ-forge/milestones", "milestoneRef": "milestones", "blurb": "When the harness fails, the information needed to act already exists inside it — make it say so.", "exit": "Exit: `bash test/lantern-release.sh --release-gate` exits 0. NOT BUILT. Writing it precedes fixing any member, which is the Litmus and Nightwatch ordering and the reason both releases could tell a finished entry from a claimed one. Two halves, the established shape: Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below. Half B executes #499's four phases rather than auditing them, since every one of them is a message an operator either receives or does not: a `relay-drive` launch preflight that refuses before spending, a gate refusal that states its real reason, a launcher exit code that survives its wrapper, and a change-impact report. #358 Phase 2 is the one member with no executable half, and the criterion is written around that rather than pretending otherwise: it is satisfied by a RECORDED transcript of a real CI failure under `test/baselines/`, and it must NOT be satisfiable by a disposition written in advance — that issue's own capture doc forbids pre-committing one, and an exit criterion that accepted a pre-written verdict would launder exactly the thing #419 exists to prevent. Its own negative control is `--mutate-evidence`, which must unregister a gate, delete a recorded control, and substitute a pre-dated disposition for a real transcript — detecting all three, and re-checking the unmutated inputs green in the same run so an always-red detector cannot pass for one.", "detours": [], "roadmap": []}], "projects": [{"slug": "XYZ-forge", "active": true}], "cycle": {"repo": "XYZ-forge", "generatedAt": "2026-08-24T03:30:06Z", "db": {"generation": 114, "receipts": 128, "lastOp": "2026-08-24T03:30:06Z", "schemaVersion": 5}, "releases": {"total": 12, "open": 6, "overdue": 0, "byStatus": {"active": 1, "draft": 5, "shipped": 6}, "openList": [{"version": "0.7.3", "codename": "Bulkhead", "status": "active", "target": "2026-09-05", "daysToTarget": 13}, {"version": "0.9.0", "codename": "Cargo", "status": "draft", "target": "2026-09-19", "daysToTarget": 27}, {"version": "0.6.0", "codename": "Meter", "status": "draft", "target": "2026-09-26", "daysToTarget": 34}, {"version": "0.8.0", "codename": "Sundown", "status": "draft", "target": "2026-10-17", "daysToTarget": 55}, {"version": "0.4.0", "codename": "Plumbline", "status": "draft", "target": "2026-11-14", "daysToTarget": 83}], "recentShipped": [{"version": "0.7.2", "shipped": "2026-08-23"}, {"version": "0.7.1", "shipped": "2026-08-19"}, {"version": "0.7.0", "shipped": "2026-08-18"}]}, "roadmap": {"total": 56, "unmarked": 9, "wip": 9, "queued": 0, "done": 38, "paused": 0}, "marathons": {"total": 1, "byStatus": {"planned": 1}, "runningRefs": ["GH-77"]}, "items": {"open": 0, "dialedIn": 18, "shipped": 9, "cut": 1}, "recentEvents": [{"at": "2026-08-23T04:30:03Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-87"}, {"at": "2026-08-23T04:30:02Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-85"}, {"at": "2026-08-23T04:30:02Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-86"}, {"at": "2026-08-23T04:30:01Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-82"}, {"at": "2026-08-23T04:30:01Z", "from": "dialed_in", "to": "shipped", "reason": "merged to development via daybreak wave 2-4 marathon; test/gh77-standup-triage.sh exit 0 (150 pass) on d8e8c5b0; wave-4 relay Approved (marathon-system/daybreak-wave-4-2026-08-20/RELAY.md)", "item": "GH-83"}]}}</script>
./test/rtl-orphan-backup.sh:2:# test/rtl-orphan-backup.sh — GH-141: concurrent peer-edit race, recoverability mitigation.
./test/rtl-orphan-backup.sh:11:# GH-22 self-escape backstop. The ratified mitigation (GH-141 recommended next step 1) is
./relay-system/2026-08-21/gh124-closeout-implementation-qa.md:48:### Review salvaged from openrouter/stealth/ox-alpha transcript (aider-turn.sh · GH-251)
./relay-system/2026-08-21/gh124-closeout-implementation-qa.md:696:  61 test/gh91-relay-scratch.sh — relay scratch.                                
./relay-system/2026-08-21/gh124-closeout-implementation-qa.md:1252: • test/gh91-relay-scratch.sh — pins .relay-scratch behavior in                 
./relay-system/2026-08-21/gh124-closeout-implementation-qa.md:1253:   relay-turn-lib.sh. The Phase 2 sweep quarantines .relay-scratch — if we touch
./relay-system/2026-08-21/gh124-closeout-implementation-qa.md:1301:    • test/gh426-worktree-leak.sh + test/gh91-relay-scratch.sh +                
./relay-system/2026-08-21/gh124-closeout-implementation-qa.md:1352:   test/gh426-worktree-leak.sh, test/gh91-relay-scratch.sh,                     
./relay-system/2026-08-21/gh124-closeout-implementation-qa.md:1388:test/gh91-relay-scratch.sh
./CHANGELOG.md:66:- **#141 Phase 3 (generative boundary fuzzing) is deliberately not scheduled** — per the issue's own recommendation, #143's counted incidence comparison (coordination-kernel vs input-boundary defects) picks the higher-value target first. Recorded in `PROJECT/2-WORKING/GH-141-FUZZ-ATE-UTILITY.md` with the other plan assumptions (RELEASES.md untouched per its optional-ledger contract; the Aider presets are NOT archived because the #146 soak is evidence of active use — the decoupling shipped instead).
./CHANGELOG.md:152:  Added fail-closed OS sandboxing verification (`sandbox-exec`/`bwrap`), pre-created `.relay-scratch/` isolation,
./CHANGELOG.md:196:  assertions, throwaway worktree isolation, and sanitized `.relay-scratch/` output paths; added synthetic test
./CHANGELOG.md:230:- **GH-91: `.relay-scratch/` — a sanctioned home for builder verification output.** A build
./CHANGELOG.md:236:  writes and lookalike prefixes still fail the turn (pinned by `test/gh91-relay-scratch.sh`
./CHANGELOG.md:432:- **Meter (0.6.0) is re-scoped from metering to the public-repository release candidate, by explicit operator decision.** The release's sentence becomes *XYZ can be handed to a stranger*: an unauthenticated clone reaches a documented entry path and exercises a supported happy path with no private context. **The published artifact is not this repository** — it is a sanitized clone cut from `development`, committed as **fresh history with a single initial commit**, and pushed to a new repository in a different organization that becomes XYZ's permanent home. Fresh history was chosen over carrying the current 2,147 commits for a stated reason, not for tidiness: in a carried history every document removed during sanitization stays reachable, so the full-history secret scan the launch requires becomes a scan of everything ever deleted rather than a scan of one tree. `CHANGELOG.md` is carried forward verbatim and is the public record of the project's history — it is a *file*, so keeping the project's story and keeping its commit history turned out to be separate decisions, and only the first was ever the goal. `.tick/` (161 MB of runtime event state) and `relay-system/` (32 MB of transcripts) do not ship; `PROJECT/` ships as an empty PDDA scaffold plus the Meter build documents retained deliberately as a worked example of how PDDA is used. **The manifest is RE-SCOPED TO TWO (#555, #563)** — the fifth dated re-scope of that manifest and the only one that replaces the release's subject rather than extending it. The seven engineering entries are dissolved without being dropped: **#378, #379, #382, #491 and #551 move intact to Sundown (0.7.0)** with their capture docs and verbatim acceptance criteria, #546 follows as Sundown backlog, and #380 is CLOSED and stays milestoned Meter as work already shipped under the original scope. **Scope is CLOSED to further admission** — no issue filed after 2026-08-15 joins this manifest; discoveries are filed, milestoned Sundown, and waived in writing under #563's rule that *a waiver names the failed criterion, the owner, the reason and the follow-up issue — silence is not a waiver*. Two known open items are covered by that rule rather than admitted, and both bear on publication: **#564** (31 unaudited suites reachable through an empty fixture path — the shakedown and the exit criterion both run the suite) and **#544**'s re-arm debt (hosted CI fires on nothing while the repo is private; going public is its own trigger). The exit criterion `bash test/meter-release.sh --release-gate` keeps its command and its two-half shape — that shape is why Litmus and Nightwatch could tell a finished entry from a claimed one — but is re-pointed: Half A audits the launch artifact, Half B executes the stranger's path, and it is **RED on arrival**, built before any sanitization is performed. **Sundown is WIDENED to receive the transfer**, and the honest reading is recorded there: it absorbed five entries without absorbing any schedule, so its date is now less trustworthy than it was. Also corrected: the Meter milestone's due date was 2027-01-15 on GitHub against 2026-09-26 in the ledger, a drift left over from when the date was pulled in; the Sundown milestone did not exist and was created. Launch checklist authored by an external reviewer (Codex Sol High) and now carrying the operator's goals. → [#563](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/563) · [#555](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/555) · [#544](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/544)
./CHANGELOG.md:436:- **GH-567: two rules from the GH-564 post-mortem — validate sandbox paths at the USE boundary, and never attribute a run from a clone whose identity drifted.** Folded into the existing GH-564 rail rather than added as new ones, because the incident's *environmental* lesson was already landed by #566 and a rule nobody reads is worse than no rule. Both were sharpened by a cross-model consult (Codex `gpt-5.6-terra` + agy, transcripts in `relay-system/2026-08-15/gh564-rules-143706/`), which independently returned the **same two Blockers** against the drafts: validation must bind to the **call site**, not the point of derivation — a variable safe at line 10 can be empty at line 50, and a derivation-site check never covers a path passed in from elsewhere — and the draft under-named the lethal cases, since `rm -rf "$VAR/"` → `/` and `find "$VAR" -delete` → `.` are worse than the `git -C ""` that actually fired. **The advisors split on the second rule and the disagreement is recorded rather than averaged:** agy said cut it outright ("AGENTS.md is governance, not a troubleshooting wiki"), Codex said keep it but make it falsifiable. Codex's form landed, scoped to *drift detected* — `core.bare`, `origin`, local user identity, `HEAD` against pre-run values — precisely so it cannot become "suspect the harness first," which is a thought-terminating excuse for ignoring real regressions and was agy's actual objection. **One residual defect found while grounding the rule, and it is in the merged fix:** `require_fixture`'s containment is `case "$p" in "$WORK"/*)`, a *lexical* prefix test that blocks the observed empty-path case but still accepts `$WORK/../../<real repo>` — verified directly, and flagged before that helper is copied into the other 31 unaudited suites. The RCA also records the expensive contributing cause honestly: the corruption was misdiagnosed for ~40 minutes because a single green control run was treated as proof that the change under test was guilty, when it was one sample from a nondeterministic process. → [#567](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/567) · [#564](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/564)
./CHANGELOG.md:458:- **The `releases-skill` gate is unregistered until its file lands — `development`'s suite was red in every clone but one.** The registration reached `development` while the gate file it names did not, so `validate.sh` exited 127 for everyone whose working tree did not happen to hold the author's uncommitted copy — and green for the one session that could not see the breakage. That is #461's defect in mirror image: there, a gate that exists but is unregistered is invisible; here, a registration with no gate is a permanent red that says nothing about the code, and since GH-544 put the suite on the push boundary it was refusing every push from every session. **The test is not at fault and was not deleted** — it passes **26/0** in the tree where its inputs exist. It needs the whole consolidation (the plural skill directory, removal of the legacy singular one, and the router / PDDA-contract routing updates), which is in flight and uncommitted elsewhere; landing that change re-enables the line in the same commit. Deliberately not completed here: pulling ~7 files of another session's uncommitted work across — including its own CHANGELOG prose — to satisfy a one-line registration would be a much larger intervention than the breakage warrants. Suite goes from 3 failures to 1. **RESOLVED the same day** — the consolidation landed and the line was re-registered in the commit that brought the gate file with it, which is exactly the condition recorded here. Kept rather than deleted because a ~2h window in which the shared branch refused every session's push is a real event, and the rule it produced is worth stating once: **register a gate and its file together, or neither.** → [#461](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/461)
./CHANGELOG.md:494:- **A tree-overwriting git command now leaves what it destroys recoverable (GH-527).** Three times in one session an agent used a git *history* command to undo a *working-tree* experiment: a tree-wide `git stash` that took four other sessions' files and timed out before its `pop`; a `git checkout -- <path>` that restored HEAD rather than the pre-edit state and ate ~60 lines of new tests; a `git reset --hard origin/development` that took four sessions' tracked modifications plus `.claude/settings.json`, which never came back. **The shape is snapshot-then-allow, not refuse-when-dirty** — `relay-automation/hooks/gh527-destructive-git-guard.sh` copies the doomed **tracked** files into `.tick/orphan-backups/` and always exits 0. That is the shape this repo already chose for the same problem (`rtl_check` does exactly this before reverting an off-allowlist edit, GH-141); refusing instead would fire on every legitimate solo cleanup and train an override reflex, and it could not satisfy the issue's own acceptance criterion requiring *demonstrated* recovery. Tracked-only is not an oversight: the issue **reproduced** the blast radius in a fixture — tracked modifications die, untracked files survive — so snapshotting untracked files would be noise hiding the signal. **The `AGENTS.md` rail is the explanation, not the fix:** the issue falsified a doc-rail-only proposal against the session's own ledger — every mechanical guard (frozen-twin, `path-integrity.sh`, the GH-472 SIGPIPE detector) caught the author; neither written warning did. 26/0, registered, recovery demonstrated end-to-end. **Control worth reading:** clean-tree silence is defended by *two* independent conditions, so two separate single-line mutations both stayed green and it took a combined mutation to produce exactly one red — recorded in `test/baselines/GH-527-negative-control.md` rather than presented as a clean first try. → [GH-527-DESTRUCTIVE-GIT-GUARD.md](PROJECT/2-WORKING/GH-527-DESTRUCTIVE-GIT-GUARD.md) · [#527](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/527)
./CHANGELOG.md:551:- **The "worktree isolation leaks an off-lane creation into the harness repo" defect is real, reproduces exactly as filed — and is not a worktree defect at all.** #426 named worktree teardown as the place to look, and explicitly warned against treating that as the answer: *"a builder that treats this as the answer will produce a fix shaped like the guess rather than like the defect."* A factorial control settled it in three runs — same fixture, one variable at a time: stub writes + isolation **ON** → leak; stub writes **nothing** + isolation ON → no leak; stub writes + isolation **OFF** → **leak**. The third case is fatal to the stated theory: the leak survives with isolation disabled, so teardown cannot be the mechanism. Logging every invocation of the agent binary showed the real one — there are **two per turn**, `agy whoami` (the GH-375 auth pre-flight) and then the turn itself, and **the pre-flight ran with the caller's CWD**, i.e. the harness clone, which is the one execution of the agent binary that happens entirely outside the turn's containment. The reproducing stub — like `test/gh410-containment-advisory.sh`'s — writes on *every* invocation, so the pre-flight invocation is what reached the harness root. The turn's own copy was always discarded, `worktree_end` always fired, and the worktree's `git-common-dir` always resolved to `AGY_TURN_ROOT`: **criterion 3 was already true and needed proof, not a change.** The fix is still worth making, for a different reason than the one filed — real `agy whoami` does not write to its CWD, but *"the binary we shell out to happens not to write"* is a claim about someone else's program rather than a property this harness enforces, and it is exactly the assumption that made a test stub indistinguishable from a containment failure. `agy_auth_preflight` now runs in a throwaway directory and **reports** anything the probe leaves there instead of discarding it silently. **`test/gh410-containment-advisory.sh`'s cleanup block is deleted, and its absence is the proof**: it used to `rm -f "$ROOT/offlane.md"` and print a NOTE, so a returning leak now makes that suite litter a live repo again rather than quietly tidying up after itself. `test/gh426-worktree-leak.sh` 7/0 — absence asserted in **both** repos in separate assertions (checking only the declared target is the miss this criterion exists for), exit 6 asserted **first** so a fix cannot buy containment by weakening the verdict, and criterion 3 read from the turn invocation's own `git-common-dir` *while the worktree still exists* (an earlier draft asserted it after teardown and reported "could not resolve", which is not a verdict). Controls: **2 red** here and **1 red** in gh410's new C4c against the pre-fix `agy-turn.py` (`test/baselines/GH-426-negative-control.md`). → [#426](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/426) · [#410](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/410) · [#375](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/375)
./CHANGELOG.md:590:- **The Litmus wave-1 doc sweep dropped from three docs to two, and the ROADMAP's GH-417 entry turned out to be describing someone else's work.** `GH-343` and `GH-418` moved to `3-COMPLETED` (both issues CLOSED). **`GH-425` was pulled back out**: it shipped, closed on per-criterion verification, and was reopened the same day when salvage triage from the abandoned `agy/gh375-385-438-wip` worktree (#458) found a **second call site the fix never reached** — `marathon_drive.py`'s `--log-github` handler resolves `repo` and `issue` independently and compares no slug at all. Sweeping it would have been a false completion claim. Separately, the ROADMAP entry for **GH-417 carried GH-425's text verbatim** — it read `✅ BUILT` and then described `check_source_url` acting on the repo slug, claiming one lane was finished while describing another; it now describes #417's own resolution.
./CHANGELOG.md:653:- **GH-399/GH-400: an agy QA relay found two real gate bypasses, and both were reproduced before being fixed.** Reviewed via `relay-xyz` with a review-only allowlist; 2 Blockers, 2 Shoulds, 1 Nit, all accepted. **(1)** An issue whose `## Acceptance` section *exists but lists nothing* returned `[]`, and the caller collapsed `[]` with `None` → `unknown` → **no block**, so a capture doc could invent arbitrary criteria under its own heading. `extract_acceptance_criteria`'s own docstring said the two cases must stay distinct *because collapsing them would let a doc dodge the gate*; the caller collapsed them anyway — the defect was in the gap between the documented intent and its one consumer. **(2)** Extraction stopped at the first **unindented** line, so an explanatory paragraph between criteria truncated the list — worse than reported, because `collect_inline_checklist` kept scanning: the two extractors **disagreed about the same document**, and the packet would inline three criteria while the fidelity check compared two. **(3)** `## Acceptance:` and `## Acceptance Criteria (draft)` read as "no section" → another silent `unknown` bypass; relaxed **more narrowly than proposed**, since dropping the `$` anchor outright would also match a prose heading like *"## Acceptance is not required here"* (pinned by a negative case). **(4)** The review correctly identified three cases that pass against the pre-fix code — they were exactly the 1 and the 2 that passed in the pre-fix runs. **Kept and labelled rather than deleted:** they are the cry-wolf controls, and a gate that flags faithful copies is precisely the failure that gets a gate switched off; each now names its falsifiable sibling. **(5)** An arrow inside a criterion broke `[changed]` parsing — **fixed differently than proposed**, because `rsplit` is also wrong: with three arrows neither the first nor the last is the separator, so the parser now offers every split as a candidate and reconciliation picks the one matching the actual diff. Suites 21 → **26/0** and **14/0**. **The review turn itself exited 6:** agy wrote `scratch-reviewer.md` off-allowlist and `rtl_check` reverted it — GH-22's backstop working — with the content recovered from `.tick/orphan-backups/`; another instance of the known agy-oversteps-allowlist pattern, on a turn whose `ALLOW_PATHS` was deliberately empty. → [thread](relay-system/2026-08-03/gh399-400-acceptance-qa.md)
./CHANGELOG.md:753:- **GH-273: Phase 2 SHIPPED — `.claude/loose-ends-sequence.md` gives this repo a real custom end sequence.** Fired via `swarm-preflight → marathon-drive` with `--phase-id gh273-phase2`. Contract was grounded in a direct read of `~/.claude/skills/loose-ends/SKILL.md` rather than inferred: the manifest mechanism already existed (project-local `.claude/loose-ends-sequence.md` takes precedence over the global one, `### *` heading, `- cmd` bullets, paths resolved relative to the manifest's own directory) — Phase 2 only needed to author the file. Codex got the path-resolution subtlety right unprompted: bullets are `../utils/pdda/pdda.sh run` and `../utils/roadmap-dashboard.sh`, correctly relative to `.claude/` (the manifest's directory), not repo root. The third bullet is a reminder that `PROJECT/2-WORKING` docs move to `3-COMPLETED` only once `marathon-cleanup` classifies them `VERIFIED-COMPLETE`, never on a bare status-word edit. Same flaky-gate pattern as Phases 0-1 (`test/xyz-harness-hooks.sh`'s pre-existing "relay green count" assertion — 3 for 3 now, unrelated to any of the three builds); confirmed clean each time, closed out manually. → [#273](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/273) · [GH-273-MARATHON-CLOSEOUT-AUTOMATION.md](PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md)
./CHANGELOG.md:756:- **GH-273: Phase 0 SHIPPED — the `UserPromptSubmit` skill-nudge hook is live.** Fired via `swarm-preflight → marathon-drive` (Codex builder, agy reviewer, Approved after 2 turns): `relay-automation/hooks/skill-nudge.sh` (89 lines, follows the `xyz-vendor-reminder.sh` fail-open/opt-out-env/exit-0-always contract) matches only the marathon-lifecycle keyword table from the plan doc — "add ... to marathon"/"fire the marathon"/"preflight sweep/all"/"dry-run each plan" → nudges `marathon-triage`; "commit and push" + ("close issues"/"move to 3-completed"/"PDDA sweep") in the same prompt → nudges `loose-ends` + `marathon-cleanup`. Unrelated prompts stay silent. Wired into this repo's `.claude/settings.json` alongside the existing `PreToolUse`/`SessionStart` hooks. 14 new cases in `test/xyz-harness-hooks.sh`, all passing. **Process note, worth recording:** the `bash validate.sh` pre-advance gate initially reported FAILED, but the actual red was a pre-existing flaky assertion in the same test file ("relay green count", last touched by the unrelated GH-232 fix) — none of the 14 new nudge assertions failed. Confirmed flaky, not regressive: the test file alone re-ran 61/61 clean, and a full `validate.sh` re-run immediately after was exit 0 with nothing failing. Re-invoking `marathon-drive` to retry the gate then hit a real harness limitation — the `MARATHON-P1-TURN` tick token was already `status: done` from the successful first run, so it couldn't be reopened; the retry re-rendered `phases/p1/RELAY.md` back to a fresh `STATUS: Open` template and failed immediately after (exit 1), discarding the accurate Approved record. Recovered by `git revert`ing that render commit (restoring the true Approved state) and closing the phase out manually rather than re-driving a third time — the code was already correct and committed; only the harness's own bookkeeping needed the fix. Full detail: `phases/p1/ESCALATION.md` § Resolution. → [#273](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/273) · [GH-273-MARATHON-CLOSEOUT-AUTOMATION.md](PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md)
./CHANGELOG.md:757:- **GH-273: Phase 0 added — a `UserPromptSubmit` skill-nudge hook, folded into the plan doc so the design is documented and searchable before it's built.** Operator raised: could a hook remind them that skills like `marathon-triage`/`loose-ends`/`marathon-cleanup` already exist, so they stop hand-typing the ceremony those skills already automate? Confirmed the mechanism is already live in this repo's own `.claude/settings.json` (2 `PreToolUse` guards + a `SessionStart` reminder, `relay-automation/hooks/xyz-vendor-reminder.sh`) and picked `UserPromptSubmit` over another `SessionStart` entry — a per-prompt nudge matches the *specific* thing being typed, where a once-per-session reminder goes stale after the first screen. New Phase 0 in `GH-273-MARATHON-CLOSEOUT-AUTOMATION.md`: `relay-automation/hooks/skill-nudge.sh`, following the `xyz-vendor-reminder.sh` fail-open/opt-out-env/exit-0-always contract, matched against a narrow marathon-lifecycle keyword table (documented in the doc, not just the script) so it stays silent on unrelated prompts. Preflight contract redrafted to target Phase 0 (was Phase 1); frontmatter `phases: 4→5`, `effort: 4→5`. → [#273](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/273) · [GH-273-MARATHON-CLOSEOUT-AUTOMATION.md](PROJECT/1-INBOX/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md)
./CHANGELOG.md:758:- **GH-273: marathon pre-flight/post-flight ceremony automation — planned, not yet built.** A Fable 5 web app's analysis of ~583 logged Claude Code prompts (`PROJECT/1-INBOX/LESS-TYPING.md`, source: `0. Claude Prompts.md`) found two heavily repeated manual sequences: pre-marathon (capture → add to plan → preflight sweep → cleanup → dry-run → fire, ~25 occurrences) and post-marathon (commit/push → PR → merge → pull/switch → close issues → move docs → PDDA sweep → Slack, ~45 combined). Verified against the raw corpus (78 commit+push mentions, 12+ "add to marathon" phrasings, 8 "move to 3-COMPLETED", 6 "close issue", 5 "PDDA sweep" across 583 entries) — the repetition is real. **Cross-checked against existing tooling before accepting the recommendation as-is:** the pre-marathon half largely overlaps `skills/marathon-triage/SKILL.md` (which already reconciles/ranks/preflights, and deliberately refuses to fire), so `/pre-marathon` will wrap it rather than reimplement it; the post-marathon half is a genuine gap — `marathon-cleanup` is archive-only and `loose-ends` is generic, neither does the PR→merge→close-issues chain. 4-phase plan drafted: `/pre-marathon` + `/post-marathon` slash commands → per-repo `loose-ends-sequence.md` manifest → `marathon-closeout.sh` extraction → symmetric `--post-approve-cmd` harness flag (mirrors `marathon_drive.py`'s existing `--pre-advance-cmd`). Filed, captured, ledgered, and folded into today's marathon queue (Wave 1, `MARATHON-PLAN-2026-07-22.md`) — no phase fired yet. → [#273](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/273) · [GH-273-MARATHON-CLOSEOUT-AUTOMATION.md](PROJECT/1-INBOX/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md)
./CHANGELOG.md:763:- **GH-255: Phase 1 of the Python cutover CLEARED — `XYZ_PYTHON=1 validate.sh` is 117/117 with ZERO Python-attributable failures, closing the cutover gate; the one remaining red (`marathon-drive.sh`) is a pre-existing BASH-only bug, split to #261.** The #255 ledger's 10 Python-only-failing files are closed and verified two-mode on branch `gh255-phase2-toggle-harden`. **`utils/py/marathon_drive.py`** ported to full parity (test/marathon-drive.sh 89/23 → **112/0** under Python): GH-207 lane namespacing + byte-identical re-render skip (git `diff --cached --quiet`, no more "nothing to commit" halt) + satisfied-lane recovery (`--review-once` reroute + `lane_already_satisfied`), GH-238 gate-runnable preflight (exit 2 before spending a turn, ordered *after* the binary probes so a missing builder still fails first), `--require-clean` linked-worktree lock relocated to the git-common-dir, GH-162 debug-mantra note, GH-205 timeout recovery — which also greened the two files that only fail *through* it (`marathon.sh` 33/0, `debug-mantra.sh` 14/0). **Four independent twins ported in PARALLEL via a subagent workflow**, each independently re-verified green in both modes: `swarm_preflight.py` (88/8→96/0: GH-203 stale `.git/index.lock`, contract-heading detection, artifacts-subset validation, effective-artifacts/`fs_touching_tests`), `consult.py` (55/7→62/0: the whole GH-235 A4 prompt-trace provenance surface — `.PROMPT.txt` snapshot, ECHOED-vs-FIRSTHAND classifier, `.PROVENANCE.txt` sidecar), `marathon_plan.py` (55/5→60/0: GH-150 docOf lane-pointer + GH-86 review-lanes overlay, as twin-side shims because the drifted `_marathon_plan_node.js` engine was out of the port's scope — flagged for a cleaner direct sync), `aider-turn.py` (57/4→61/0: GH-168/186 `--add-gitignore-files` capability probe + GH-251 transcript-salvage backstop). **`relay_drive.py`** (GH-198 Setup-artifact preflight exit-2 + GH-245 `--review-once` evidence-of-work oracle). **`codex-turn.py` + `rtl.py`** (GH-161 persistent turn transcript — new `rtl_default_log`, `RTL_LOG` exported before the first rtl call, and append-not-truncate so `rtl_init`'s trace survives). A caught-in-flight regression — the GH-238 preflight's `bash -n` syntax check tripped `test_python_layer.py`'s "no subprocess before the builder-binary check" contract — was fixed by ordering the preflight after `_probe_agent_bin`. **Same-commit two-mode sweep: Python 117/117 (Python-attributable set = ∅, the cutover criterion), Bash 116/117.** The lone Bash red, `marathon-drive.sh` GH-171/172 (vendored `.xyz/` + worktree + macOS `$TMPDIR` containment exit-6), is a multi-factor bug in the permanent-Bash containment core (`relay-turn-lib.sh` `/var`-vs-`/private/var` symlink-form strip + inherited `TICK_REPO_ROOT`) that pre-dates this work and does NOT fail under Python (the Python driver resolves paths consistently and sidesteps it); a partial symlink fix was **reverted** to keep the safety core clean, with the full diagnosis on #261 for a reviewed fix. → [#255](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/255) · [#261](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/261)
./CHANGELOG.md:768:- **GH-255: `UPGRADE.md` hardened by a SECOND independent `/relay-xyz` review — Codex, 5 rounds to Approved, 9 real blockers + 6 shoulds fixed that the agy pass missed.** Ran Codex as a different-model reviewer over the already-agy-Approved doc; it found substantially more, all verified against the repo before fixing. **Blockers:** the `python3 --version` "gate" didn't enforce the >=3.8 floor (3.7 passed) → executable predicate; `git fetch origin <branch>` could leave `origin/<branch>` stale → bare `git fetch origin`; the locator was referenced by a non-existent root path → concrete `skills/relay-xyz/find-harness.sh` (+ `.xyz/` variant); **Codex caught a bug in one of my own fixes** — a `python3 -c … || { echo; }` guard whose `||` swallowed the failure and continued → rewrote §2 as a real accumulator `preconditions.sh` that fails closed (behaviorally proven); per-copy permanent rollback that `git -C <root> revert`ed the *shared* live root → isolated `git worktree add <flip-sha>^` re-vendor; the §2(c) parity gate pointed at GH-255 instead of being runnable → embedded a `comm -13` Python-attributable-failure computation; the gate could **false-pass** if `validate.sh` aborted before its summary (empty set looks clean) → footer-completion guard; the Phase-2 shim guard checked python3 *presence* but not the *>=3.8 version* → version-enforcing guard; and the Type-B (vendored leaf) path was internally non-executable (told to skip only Phases 1 & 3 while Phases 2 & 4 are also root-only) → leaf now runs **none** of Phases 1–4, receive-and-verify only. **The deepest correction:** the interpreter matrix claimed the 10 non-marathon-plan twins were "python3 only" — but `bin/tick` is a Node program (`bin/tick:1`) that **both** the Bash drivers (`relay-drive.sh:42`) and the Python twins shell to, so Node was always a whole-harness baseline and the "flip 10 without Node" escape hatch was incoherent; removed it. **Shoulds** covered the honest external-tool deps (`date`/`sed`/`bash`/`consult.sh`), the `xyz-sync check` semantics (metadata-only drift, so don't hand-edit `.xyz/` because the next `update` overwrites it — not because `check` catches it), and propagating the Node/marathon-plan/Type-B corrections consistently across §0/§9/§10. Final Codex verdict: 4× `[Pass]`, 0 open. **Process note:** the closing turn hit driver exit 6 (GH-141) because I hand-edited the tree mid-review; the containment guard reverted it and the orphan-backup mechanism preserved the content — re-applied in the close commit. Thread: `relay-system/2026-07-20/upgrade-doc-review-codex.md`. → [#255](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/255)
./CHANGELOG.md:782:- **Marathon Plan L fired end-to-end on branch `marathon/plan-l-followup-2026-07-19` — 3 lanes (GH-251, GH-241, GH-218), all preflight exit 0, single wave, gate green relative to baseline.** The post-marathon follow-up queue ([MARATHON-PLAN-2026-07-19-L](PROJECT/2-WORKING/MARATHON-PLAN-2026-07-19-L-POST-MARATHON-FOLLOWUP.md)) was carried from a fresh `swarm-preflight --gh-issue` (3× exit 0), through a disjoint-write-set overlap check (`relay-automation/aider-turn.sh` ‖ `bin/marathon-yaml`+test ‖ `utils/hq/*`+tests — no intersection, so one wave), to execution and gating. Run **serial Opus-direct** rather than worktree-isolated subagents: only 3 small lanes, and the Agent worktree-isolation branches from `main` not the marathon branch (GH-225), so a serial pass on the branch avoids the cherry-pick reconciliation for no concurrency benefit. **GH-241** — `bin/marathon-yaml` now rejects the `depends_on` YAML flow-sequence form (`[p1]`) with a shape-specific "flow sequence" error instead of the bewildering `unknown phase '[p1]'` lookup at `bin/marathon-yaml:102-105`; this is the code fix (3) the 2026-07-19 docs-only pass deliberately deferred, plus a `test/marathon-yaml.sh` regression case (list form → shape error; scalar still parses). **GH-251** — the OpenRouter/aider reviewer seam gets two complementary fixes inside `relay-automation/aider-turn.sh`: an explicit **review mode** posture on review-only turns (append a graded review to the relay file — the only writable target), and a **transcript-salvage backstop** that, when a review turn lands no relay-file delta but the transcript carries a `Verdict:` anchor, appends the transcript (attributed) so the completed review lands instead of being discarded as a stall — composes with the GH-245 `--review-once` classifier (an empty/non-review turn leaves no anchor → not salvaged → still a genuine stall); two regression cases added. **GH-218** — new read-only `utils/hq/marathon-live.sh` reports cross-repo LIVE marathon status by composing existing local primitives (repo registry, each repo's own `tick project` STATE.md `## Claimed` section, driver-lock + `marathon/*`-worktree liveness cross-check) with no new per-repo MCP server; `utils/hq/rollup.sh` embeds it as a `## Live Marathons (cross-repo, right now)` section via a shared `demote_embed` helper. Tests: `test/hq-marathon-live.sh` (live/claimed-not-driving/idle fixture matrix, read-only asserted) registered in `validate.sh`; `test/hq-rollup.sh` extended with the embedded live section + a live-status-failure banner case. Each lane stayed within its contract's `artifacts` allowlist (plus the one-line `validate.sh` test registration for GH-218). **Gate:** `bash validate.sh` — the 5 reds (`marathon-drive.sh`, `relay-pkg-freshness.sh`, `acorn-extract.sh`, `relay-self-sufficiency.sh`, `python:test_python_layer.py`) were confirmed pre-existing/environmental by re-running each on `development` (identical failures); all 4 new/touched test files pass. Auto-drafted GH-241/GH-251 contracts were verified against the real code during the run. **Merged to `development` via PR #256.** → [#241](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/241) · [#251](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/251) · [#218](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/218)
./CHANGELOG.md:787:- **2026-07-19 · Post-marathon: merged the `/10days` marathon to `development` (PR #252) + PDDA/marathon-file cleanup.** Merged PR #252 (13 lanes, both gates green) into `development`. Marathon-file hygiene per `skills/marathon-cleanup`: retired the fired `MARATHON-PLAN-2026-07-19` and the superseded `-2026-07-17` generated snapshot from `2-WORKING` → `3-COMPLETED` with terminal status; corrected stale `Active (2-WORKING)` status words on `MARATHON-PLAN-2026-07-03-A/-B` (both already complete; B's final parked lane #94 since closed). Filed **GH-251** (OpenRouter/aider reviewer seam doesn't persist its review) with a `1-INBOX` intake doc + ROADMAP pointer. `utils/pdda/pdda.sh run` is error-free; remaining warns are **deliberately-retained residuals** — the bundled-slice `roadmap-issue-state` entries GH-224 already classified (shipped slice, parent issue tracks more), and the age-flagged-but-actively-referenced frontier docs GH-173/GH-178/ADVERSARIAL-HARDENING (ROADMAP still names them the active/parked frontier — not archived). The 13 marathon lane docs stay in `2-WORKING` with issues open: the marathon reached `development`, not `main`, and GH-232 is explicitly verified only on the next `development → main` PR, so closing them now would be premature.
./CHANGELOG.md:793:- **README repo map refreshed to match what's actually on disk since 2026-07-17.** The `## Repo map` was stale after the marathon-tooling and wipe-prevention work landed — it still enumerated only the pre-07-17 skills/utils. Added the three marathon operator skills (`skills/marathon-triage/`, `skills/marathon-cleanup/`, `skills/10days/`, linked to [GH-240](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/240)), the cross-repo bug front-door (`skills/file-xyz-bug/`), and three previously-unlisted utils/hooks: `utils/marathon-plan.sh` (the ROADMAP-ranking marathon planner that writes `MARATHON-PLAN-<date>.md`), `utils/swe-diagram/` (Git-history/architecture diagram generator, [GH-201](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/201)), and the GH-233 wipe-prevention layer (`utils/git-bundle-snapshot.sh` + `relay-automation/hooks/gh177-sandbox-test-guard.sh`, [GH-233](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/233)). Doc-only; grounded against the working tree (`ls skills/ utils/`) and the capture docs, not memory.
./CHANGELOG.md:834:- **PDDA sweep + consolidation of `PROJECT/2-WORKING`'s marathon files.** Audited all 6 hand-authored Marathon Plan docs + 4 execution-artifact folders sitting in `2-WORKING`, verifying each against real git/GitHub history rather than trusting its own stale status line. 4 plan docs (Plan E, Plan F, the LM Studio plan, Plan G) and 3 execution folders (`GH172-ROOT-AUDIT`, `GH213-209-203`, `GH208-154-149-198`) were fully shipped — retired to `PROJECT/3-COMPLETED/`, each with a corrected, terminal-worded status line (several had gone stale: Plan E's frontmatter still said `#186` was unmerged 8 days after it landed; the LM Studio plan's Lane 2 had shipped via `/10days` without the doc ever being told). Consolidated down to the 2 remaining live marathon files: `MARATHON-PLAN-2026-07-17-H-LIVE-MARATHON-STATUS.md` (GH-218, not yet fired) and the auto-generated `MARATHON-PLAN-2026-07-17.md` (regenerated by `marathon-plan.sh --deep`, already supersedes every other doc's remaining open items). Along the way, found and fixed a live instance of the exact bug GH-189 (filed earlier this session) describes: `GH-208`/`GH-154`/`GH-149`/`GH-198` were fully fixed-and-merged but their capture docs were never moved out of `2-WORKING`, and all 4 GitHub issues were still OPEN — closed all 4 issues with evidence comments and moved their docs to `3-COMPLETED`. Also caught and fixed a duplicate ROADMAP.md ledger entry for GH-189 (one from its original 2026-07-08 capture, one from today's promotion) by merging them into one accurate entry. `GH-221`'s doc (this session's earlier builder/orchestrator fix) had the same stranding — moved it too. `pdda.sh run`: `issue-doc-sync` clean; remaining frontmatter/status-table failures are pre-existing and unrelated (GH-141/151/152/155).
./CHANGELOG.md:837:- **[GH-221](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/221) — explicit builder/orchestrator role split, closing a real doc gap causing session drift.** Some Claude Code sessions had started trying to use the Claude CLI as a marathon/relay builder. The code-level default was already correct (GH-212: `--builder` defaults to `codex`), but the only existing doc caveat was cost-framed ("don't assume it's free"), never role-framed — nothing stated that Claude Code is the orchestrator/reviewer, Agy/Codex CLI are the builders, and Claude CLI is an explicit user opt-in only. Worse, the vendored `skills/relay-xyz/SKILL.md` — the doc a vendored `.xyz/` install's own sessions actually read — had zero mention of a role split at all. Fixed both: added the explicit role statement to `AGENTS.md`'s "Repo-specific rails" and to `skills/relay-xyz/SKILL.md` (this file IS in `xyz-vendor.sh`'s `VENDOR_DIRS`, so it reaches every vendored `.xyz/` install on its next re-vendor — existing already-vendored copies need a manual re-vendor to pick it up immediately). Docs-only, no script behavior changed. `pdda.sh run` clean (pre-existing unrelated failures on GH-141/151/152/155 left untouched, out of scope).
./CHANGELOG.md:840:- **New `/10days` skill, dogfooded live on its first run — 11-14-day issue sweep, 5 of 6 candidates shipped.** Built `skills/10days/` (SKILL.md + `scan-issues.sh`/`find-doc.sh` deterministic helpers) to automate: scan a GH issue age window → verify each is still valid/reproducible/not-already-fixed via subagent fan-out → build + preflight a marathon → cut a branch and execute, unattended. Statically reviewed via `/consult --models agy` before running (caught and fixed: unsafe hand-rolled JSON in `find-doc.sh`, a `swarm-preflight.sh` multi-`--gh-issue` bundling misunderstanding, missing concurrent-marathon/behind-origin checks, no worktree isolation for parallel lanes). First live run (11-14 day window, chosen to not overlap the concurrent `#208/#154/#149/#198` sweep) scanned 16 issues, excluded 7 with commit/PR evidence (already-landed: #109, #111, #144, #96; gated-on-another-issue: #153; stale/paused: #97, #156, #157) and 2 more (#149, #154) for being actively claimed by that concurrent marathon — a collision the skill's own logic didn't catch on its own; caught by cross-referencing the other marathon's branch name live. Surfaced a real design gap along the way: `marathon-plan.sh` ranks the *entire* ROADMAP ledger, not just a sweep's own candidates, so its generated waves silently included the 2 already-claimed issues — fixed `SKILL.md` to require filtering to the sweep's own candidate set before firing anything. 6 issues survived triage; **5 shipped**: [#110](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/110) P2b (`test/roadmap-dashboard.sh` skip-guard + new top-level `run-tests.sh` entry point, `49c7b8d`), [#147](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/147) P2 (LM Studio lane threaded through the production Aider relay turn shim, byte-identical default OpenRouter path, 55/55 tests, `160c0fe`), [#151](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/151) P4 (cost-observability coverage-truth spike: Codex usage surface feasible, agy confirmed structurally cost-blind, Gemini relay-lane recommended for retirement, `7c77e4f`), [#152](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/152) P6 (`relay-drive.sh` now auto-surfaces the `tick analyze` cost block at end-of-run behind an env toggle, wired through the existing `EXIT` trap without touching the real exit code, `89d823a`), [#155](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/155) (3 new agy hardening regression cases — S2/S5/S8 — 54/54 own tests, `5f37954`). **[#141](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/141) deliberately shipped no fix** — investigated and correctly declined: no code-only signal can distinguish a peer session's concurrent edit from the agent's own off-lane self-escape (both produce identical porcelain diffs), and `rtl_enforce`'s revert is the documented backstop for a real, already-exploited self-escape vector (GH-22) — "fixing" this without an attribution signal would silently disable that protection. Recorded two non-detection follow-ups (recoverable backup-before-revert; document the don't-hand-edit-a-live-clone constraint) for an operator decision instead. Consolidated Wave 1 gate surfaced two real (non-flaky) cross-lane issues only visible once all 5 lanes merged together: a new unbaselined `credential-literal` finding from `#147`'s test fixture (`test/aider-turn.sh:322`, a dummy key — baselined, same class as the existing `test/deep-research.sh` entry) and a stale `relay-pkg.tar.gz` (two lanes each regenerated it for their own change via `make-pkg.sh`, but neither reflected the other's — refreshed once against the fully-merged tree). `worktree-isolation.sh` and `acorn-extract.sh` also failed in the gate; independently verified both fail identically against the pre-merge base commit in a scratch worktree (pre-existing GH-208 flaky race; missing `acorn` npm module) before ruling them out as unrelated. Live incident along the way: worktree directories (including the sweep's own and multiple lane worktrees) were deleted out from under running agents mid-`validate.sh` by an external, unrelated process — no committed work was lost (all recoverable from the branch), but it forced a switch to faster, targeted per-lane gates instead of the full suite to reduce the exposure window.
./CHANGELOG.md:870:- **GH-240: repo-owned `/marathon-triage` plus a new PDDA-compatible `/marathon-cleanup` skill.** Migrated the machine-only triage instructions into `skills/marathon-triage/`, tightened them to remain read-only and honor deterministic preflight/PDDA findings, and added reproducible Claude symlink installation. The cleanup skill audits active marathon plans and bundles lane-by-lane across canonical task docs, terminal frontmatter/status, GitHub issues and PRs, target-branch commit reachability, verification evidence, and CHANGELOG provenance. It distinguishes a completed bounded marathon slice from a completed whole issue, moves task docs only for whole-effort completion, and moves a parent marathon only after every lane is verified; all mutations remain report-first and confirmation-gated. Both skills pass the official validator, both installers pass `bash -n` and ShellCheck plus live idempotency checks, file-scoped PDDA checks are clean, and `./validate.sh` passes 115/115. The original machine-only triage directory remains recoverable as `~/.claude/skills/.marathon-triage.pre-repo-20260718`.
./CHANGELOG.md:977:Triaged `PROJECT/1-INBOX` lowest-GH-number-first to build a collision-safe marathon queue, and codified the recurring workflow as a machine-wide Claude skill (`~/.claude/skills/marathon-triage`). Reconciled every `GH-*` capture doc against live issue state: **16 stale docs** for already-CLOSED issues (GH-22/45/56/58/59/64/66/68/69/70/71/75/78/83/84/85) archived to `3-COMPLETED`. **Closed [#61](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/61)** — `swarm-preflight` returns STALE (Tier-1 CI already live on PR #145); doc archived. Promoted the four preflight-ready open issues to `2-WORKING` with `GH-<n>-*.md` names so `swarm-preflight --gh-issue` resolves them: **GH-133** (relay-dep-drift flake → `test/relay-dep-drift.sh`), **GH-142** (agy reliability → `test/agy-turn.sh`+`swarm-preflight.sh`+`_setup.sh`), **GH-143** (front-door → `skills/relay-xyz/SKILL.md`), **GH-144** (PDDA synthesis → `PROJECT/CONSTITUTION.md`+`DO-NOT-BUILD.md`); all four verdict `ready (0)`, disjoint write-sets → one 4-wide parallel wave. Authored preflight contracts for **GH-138** (now preflights STALE — `test/hq-promote.sh` already exists, candidate to close like #61) and **GH-141** (orchestrator-only lane on `relay-turn-lib.sh`; fix direction unratified, honestly flagged). Broadened **GH-94**'s contract write-set (`skills/xyz/SKILL.md` is the real bug site; added `install.sh`+`package.json` for the npx path). Kicked off Wave 1 Lane A (GH-133) via `marathon-drive` in an isolated worktree.
./CHANGELOG.md:989:### Loose-ends sweep: GH-140/GH-141 paper trail backfilled
./CHANGELOG.md:990:A `/relay-xyz` review of the GH-96/GH-140 work above actually completed successfully (Approved, 5/5 `[Pass]`) but surfaced a second containment hazard along the way: **[#141](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/141)** — `rtl_enforce`'s pre-turn dirty-snapshot protection (`rtl_before`/`rtl_was_dirty_before`) only exempts WIP that existed *before* a turn starts; it can't see a second, independent session's edit landing *during* the turn's execution window, so `rtl_check()` reverts it directly in `$RTL_ROOT` as if it were an off-lane agent edit. Live-hit: a review-only agy turn reverted a concurrent Claude Code session's in-progress edit to `PROJECT/1-INBOX/PEER-RESEARCH.md`; recovered by hand (the content was still visible in recent scrollback), not recoverable in general. Filed, not fixed — genuinely a multi-session concurrency question, not a quick patch; captured as [GH-141-CONCURRENT-PEER-EDIT-RACE.md](PROJECT/1-INBOX/GH-141-CONCURRENT-PEER-EDIT-RACE.md) with three candidate fix directions, none chosen. A subsequent `/loose-ends` sweep also found GH-140 itself had no dedicated capture doc (only inline ROADMAP/CHANGELOG prose) despite being a real kernel fix — backfilled as [GH-140-CONTAINMENT-ATOMIC-COPYBACK.md](PROJECT/3-COMPLETED/GH-140-CONTAINMENT-ATOMIC-COPYBACK.md), and posted the missing "Seam #1 shipped" comment on issue #96 (Seam #2 got one; Seam #1 hadn't).
./CHANGELOG.md:1489:- **Phase 6 — tests + the self-hosting dogfood (COMPLETE).** `test/xyz-vendor.sh` (**28 assertions**: vendor completeness, idempotency, `--no-register`, locator default-path-intact + `.xyz/` preference + `XYZ_HARNESS` precedence, staleness current-silent/behind-banner/stdout-pure, `xyz-sync` list/update/delete, reminder hook) wired into `validate.sh` → **70/70**. **Level-2 dogfood (self-hosting proof):** vendored `.xyz/` into a scratch foreign repo and drove a real `relay-xyz` **agy** review turn using *only* the vendored `.xyz/relay-automation/*` + `.xyz/bin/tick` (no live clone referenced, `--target-root` into the foreign repo) — agy caught both planted issues (`rm -rf /`, hardcoded key) as `[Blocker]`s and committed its turn file-scoped in the foreign repo. **The harness self-hosts from its snapshot.**
./CHANGELOG.md:1638:Closes agy's GH-38/GH-39 "ready packet that fails mid-air" gaps (validation slice), via the GH-39 marathon then salvaged inline.
./CHANGELOG.md:1751:- **Reversibility:** Easy — the teardown change is additive and falls back to the prior copy-all behavior when no seed signature is recorded.
./CHANGELOG.md:1902:Finished Ask 1's load-bearing half by closing out agy's salvaged test. `--target-root` now actually routes a relay turn to a foreign repo: `relay-turn-lib.sh` resolves `RTL_ROOT` from `RELAY_TARGET_ROOT` (exported by `relay-drive.sh`'s flag) at the one anchor that drives the worktree base, allowlist copyback, file-scoped commit, and enforce — so the artifact worktree/commit lands in the target repo while coordination (`.tick`) stays in the harness clone. **Default (no flag) is byte-for-byte unchanged** (`${RELAY_TARGET_ROOT:-$1}`). Also fixed Codex's empty-string `[Nit]` (`--target-root ""` now dies instead of falling back to CWD via `git -C ""`).
./CHANGELOG.md:1903:- **Test closed out:** `test/relay-target-root.sh` (agy's salvage, finished) proves the foreign-repo turn commits in the target + leaves the harness untouched, and the default path commits in the harness — **7/7**, wired into `validate.sh` → **36/36**.
./CHANGELOG.md:1971:- **Audit deliverable:** `PROJECT/2-WORKING/RELAY-XYZ-DISCOVERY-SHAKEDOWN.md` (PDDA-compliant; shakedown report format) + a one-line ROADMAP ledger entry. Flagged-but-not-touched (needs sign-off): repair the two dangling `consult`/`wpcc` symlinks. (A flagged `GH Repos` vs `GitHub-Repos` "clone split" was later retracted — `GitHub-Repos` was a symlink alias to `GH Repos`, not a second clone; the alias has since been deleted and the 20 skill symlinks repointed to `GH Repos`.)
./CHANGELOG.md:1997:The airtight async/side-effect containment that existed only in `claude-turn.sh` (a throwaway `git worktree` of `ROOT@HEAD`; only the allowlist copies back; off-lane → exit 6) is now opt-in for the cross-model turn-takers too: `RELAY_WORKTREE_ISOLATION=1` runs `agy`/`codex` with `CWD` = the worktree, so a background or absolute-of-CWD write can't reach the real repo. Default OFF → byte-for-byte the prior in-ROOT behaviour. The wiring is a byte-identical mirror of `claude-turn.sh` (begin → `cwd_wrap` → teardown → off-lane exit 6). New `test/shim-worktree.sh` proves both shims contain an off-lane write and copy back a good turn (18/0, OFF baseline included); suite 35/35. Complements Safeguard #1: a reviewer overstep is now contained two ways (allowlist scope + worktree).
./ROADMAP-DASHBOARD.md:32:| GH-2 · test-suite run relocated an untracked file into .tick/orphan-backups/ | — | [GH-2-ORPHAN-BACKUP-RELOCATION.md](PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md) · [#2](https://github.com/HiQS-Suite/XYZ-forge/issues/2) |
./ROADMAP-DASHBOARD.md:35:| GH-141 · make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison | — | [GH-141-FUZZ-ATE-UTILITY.md](PROJECT/2-WORKING/GH-141-FUZZ-ATE-UTILITY.md) · [#141](https://github.com/HiQS-Suite/XYZ-forge/issues/141) · [#142](https://github.com/HiQS-Suite/XYZ-forge/issues/142) · [#146](https://github.com/HiQS-Suite/XYZ-forge/issues/146) |
./ROADMAP-DASHBOARD.md:50:| GH-184 · committed scratch artifact .relay-scratch/probe_telemetry.json makes every real turn a tracked-file mutation | ✅ | [GH-184-TRACKED-SCRATCH-ARTIFACT.md](PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md) · [#184](https://github.com/HiQS-Labs/XYZ-forge/issues/184) |
./relay-automation/codex-turn.sh:187:# Worktree teardown FIRST (regardless of rc). Copies the allowlist back to ROOT unless an off-lane
./relay-system/2026-08-21/2026-08-22-pr149-agent2agent-session-transcript.md:53:The first three discussion turns are recorded. One useful fact emerged: the cited green run was on pre-amend commit `956ba9ad`; the PR head differs only by deletion of a stray `.relay-scratch/probe_telemetry.json`, but the repo policy still requires proof against the exact final SHA. Focused tests are green, and the doc gate is currently running while GLM answers the evidence challenge.
./relay-system/2026-08-21/2026-08-22-pr149-agent2agent-session-transcript.md:77:The shell safety guard rejected permanent deletion, so the clone is still intact. I’m switching to a recoverable teardown by moving that exact folder to macOS Trash, then verifying the original path is gone.
./relay-system/2026-08-21/2026-08-22-pr149-agent2agent-session-transcript.md:99:Understood. I’ll always request explicit human approval before moving anything to Trash, even when teardown was previously requested. Sorry—I should have paused first.
./relay-system/2026-08-21/2026-08-22-pr149-agent2agent-session-transcript.md:128:I do not accept the full-gate claim yet. You cite commit `956ba9ad`, but the checked-out PR head and `origin/gh141-fuzz-ate-utility` are `feca8732`; `git log origin/development..HEAD` contains only that commit. The committed plan at `PROJECT/2-WORKING/GH-141-FUZZ-ATE-UTILITY.md:32` says “Full gate green” is still next, and its verification ladder at :152-155 requires `gh141-ate-chain-hermetic.sh` even though no such file exists (the status table says gh142 replaced it). No committed `provenance.jsonl` or other final-SHA receipt is present in this diff.
./relay-automation/relay-turn-lib.sh:751:  mkdir -p "$wt/.relay-scratch"
./relay-automation/relay-turn-lib.sh:792:    case "$path" in .relay-scratch|.relay-scratch/|.relay-scratch/*) continue ;; esac
./relay-automation/relay-turn-lib.sh:933:  local scratch_note=" Verification output (probe results, generated JSON, logs) goes under .relay-scratch/ — pre-created for you, exempt from containment, never copied back; scratch files anywhere else in the tree are reverted and FAIL your turn."
./relay-automation/relay-turn-lib.sh:936:    prog_note=" Programmatic tool mode is enabled: diagnostic Python scripts may be executed via script_runner.py with output directed to .relay-scratch/."
./relay-automation/relay-turn-lib.sh:966:# GH-141 — recoverability-only mitigation for the concurrent peer-edit race.
./relay-automation/relay-turn-lib.sh:975:# first, turning "not recoverable in general" (GH-141's live 2026-07-05 incident, and a second
./relay-automation/relay-turn-lib.sh:982:  : "${RTL_ORPHAN_BACKUP:="$RTL_ROOT/.tick/orphan-backups/$(date -u +%Y%m%dT%H%M%SZ)-$$"}"
./relay-automation/relay-turn-lib.sh:1000:  case "$p" in .relay-scratch|.relay-scratch/|.relay-scratch/*)
./relay-automation/relay-turn-lib.sh:1001:    rm -rf "${RTL_ROOT:?}/.relay-scratch"
./relay-automation/relay-turn-lib.sh:1021:  rtl_orphan_backup "$p"   # GH-141: recoverable copy BEFORE the destructive revert below
./relay-automation/relay-turn-lib.sh:1227:  [[ -d "${RTL_ROOT:?}/.relay-scratch" ]] && rm -rf "${RTL_ROOT:?}/.relay-scratch"
./relay-automation/agy-turn.sh:239:# Worktree teardown FIRST (regardless of rc — a killed/crashed agy may have left work or off-lane edits
./relay-automation/claude-turn.sh:236:# Worktree teardown FIRST (regardless of rc — a killed/crashed builder may have left work or off-lane
./.claude/loose-ends-sequence.md:4:- echo "Reminder: move PROJECT/2-WORKING docs to PROJECT/3-COMPLETED only after marathon-cleanup classifies them VERIFIED-COMPLETE; never archive from a bare status-word change."
./relay-automation/aider-turn.sh:154:# must spend the turn appending a graded review THERE. If it still doesn't, the transcript-salvage
./relay-automation/aider-turn.sh:263:# the review salvaged from the transcript after the run. Captured at ROOT so it reflects the copy-back
./relay-automation/aider-turn.sh:290:# Worktree teardown FIRST (regardless of rc): copies the allowlist back to ROOT unless an off-lane
./relay-automation/aider-turn.sh:311:# GH-251 transcript-salvage backstop. On a REVIEW-ONLY turn (ALLOW_PATHS empty), if the relay file is
./relay-automation/aider-turn.sh:315:# being discarded as a stall. Runs BEFORE rtl_enforce so the salvaged append is the file-scoped commit.
./relay-automation/aider-turn.sh:319:# leaves no `Verdict:` anchor here, so it is NOT salvaged, the relay file stays unchanged, and the drive
./relay-automation/aider-turn.sh:325:      printf '\n\n---\n\n### Review salvaged from %s transcript (aider-turn.sh · GH-251)\n\n' "$AIDER_MODEL"
./relay-automation/aider-turn.sh:332:    printf 'aider-turn: review turn landed no relay-file delta but the transcript carried a graded review — salvaged it into the relay file (attributed; GH-251)\n' >&2
./HARNESS-MODELS-REGISTRY.generated.md:3:<!-- Auto-generated from harnesses.db by utils/py/harness_app.py — DO NOT HAND-EDIT -->
./relay-automation/pi-turn.sh:190:# Worktree teardown FIRST (regardless of rc). Copies the allowlist back to ROOT unless an off-lane
./relay-system/2026-08-21/gh124-closeout-auto-pr-review.md:52:### Review salvaged from openrouter/stealth/ox-alpha transcript (aider-turn.sh · GH-251)
./relay-system/2026-08-21/gh124-closeout-auto-pr-review.md:198:    • Audit logging under .relay-scratch or dedicated log.                      
./relay-system/2026-08-21/gh124-closeout-auto-pr-review.md:267:      against a denylist: .relay-scratch, relay files, telemetry);              
./relay-system/2026-08-21/gh124-closeout-auto-pr-review.md:643: (denylist: `.relay-scratch/`, relay files, telemetry dirs);                    
./relay-system/2026-08-21/gh124-closeout-auto-pr-review.md:1415:  6 test/gh91-relay-scratch.sh — if QW3 sweep interacts with .relay-scratch/,   
./relay-system/2026-08-21/gh124-closeout-auto-pr-review.md:1486: 3 test/gh91-relay-scratch.sh — pins .relay-scratch/ contract which QW3's       
./relay-system/2026-08-21/gh124-closeout-auto-pr-review.md:1549: • test/gh91-relay-scratch.sh — pins the .relay-scratch/ contract (pre-created, 
./relay-system/2026-08-21/gh124-closeout-auto-pr-review.md:1599:test/gh91-relay-scratch.sh
./relay-system/2026-08-19/gh77-standup-lenses-qa.md:127:- **Write every scratch and probe file under `.relay-scratch/`.** It is exempted from containment for
./relay-automation/hooks/skill-nudge.sh:11:#       -> loose-ends + marathon-cleanup
./relay-automation/hooks/skill-nudge.sh:72:        skills.extend(("loose-ends", "marathon-cleanup"))
./relay-automation/hooks/gh527-destructive-git-guard.sh:24:# into .tick/orphan-backups/ before reverting it (GH-141), precisely so a
./relay-automation/hooks/gh527-destructive-git-guard.sh:154:# self-defeating. `.tick/orphan-backups/` is the GH-141 precedent and is correct for
./relay-automation/hooks/gh527-destructive-git-guard.sh:169:    dest = os.path.join(root, ".tick", "orphan-backups", leaf)
./relay-automation/hooks/gh527-destructive-git-guard.sh:196:# what a reader of .tick/orphan-backups/ expects to see.
./relay-system/2026-08-17/consult-130916/consult.codex.md:1067:- **GH-527 · a destructive git command has no guard, and a doc rail demonstrably will not fix it** ✅ **BUILT 2026-08-14 on `fix/critical-2026-08-14`** — snapshot-then-allow PreToolUse hook copies the doomed *tracked* files into `.tick/orphan-backups/` before the command runs (the GH-141 `rtl_check` precedent), plus the `AGENTS.md` rail naming all three spellings. 26/0; recovery demonstrated end-to-end; clean-tree silence is defended by two conditions so it took a combined mutation to falsify. → [GH-527-DESTRUCTIVE-GIT-GUARD.md](PROJECT/2-WORKING/GH-527-DESTRUCTIVE-GIT-GUARD.md) · [#527](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/527)
./relay-system/2026-08-17/consult-130916/consult.codex.md:1187:- **GH-251 · OpenRouter/aider reviewer seam doesn't persist its review (builder-only in practice)** ✅ **SHIPPED — closed 2026-07-21** (commit `cf7a123`, merged PR #256; NOTE: live-OpenRouter-model verification remains an outstanding operator step, not claimed done) — found during a live multi-turn `/relay-xyz` GLM 5.2 QA of the 2026-07-19 marathon: aider produces a correct review in-transcript but its relay-file append is lost through repomap-wandering + worktree containment, so `--review-once` correctly scores it a stall (a live confirmation of GH-245, not a classifier bug). Fix: a review-mode / transcript-salvage for `aider-turn.sh`, or document builder-only and route reviews to codex/agy. cx/risk/eff 2/2/2. → [GH-251-OPENROUTER-AIDER-REVIEWER-SEAM.md](PROJECT/3-COMPLETED/GH-251-OPENROUTER-AIDER-REVIEWER-SEAM.md) · [#251](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/251)
./relay-system/2026-08-17/consult-130916/consult.codex.md:3976:  "gh426-worktree-leak.sh"       # GH-426 (an isolated turn's creation is absent from BOTH the target and the harness) — 7/0; control in test/baselines/GH-426-negative-control.md: 2 red here + 1 red in gh410's C4c. The reported cause (worktree teardown) is FALSIFIED and the suite pins the real one: the agent binary is invoked twice, and the GH-375 auth probe ran with the caller's CWD, outside containment
./relay-system/2026-08-17/consult-130916/consult.codex.md:4003:  "gh527-destructive-git-guard.sh"     # GH-527 (a tree-overwriting git command snapshots the tracked files it destroys into .tick/orphan-backups/ first) — 26/0; controls: a no-op guard drops 9 assertions, and a blanket that fires on a CLEAN tree drops exactly the control assertion. Clean-tree silence is defended by TWO conditions, so it takes a combined mutation to falsify — recorded in test/baselines/GH-527-negative-control.md
./relay-system/2026-08-17/consult-130916/consult.codex.md:4007:  "rtl-orphan-backup.sh"         # GH-141 (concurrent peer-edit race: revert unchanged, content recoverable)
./relay-system/2026-08-17/consult-122553/consult.codex.md:2997:README.md-423-- `skills/marathon-triage/`, `skills/marathon-cleanup/`, `skills/10days/` — the marathon operator
./relay-system/2026-08-17/consult-122553/consult.codex.md:3000:README.md-426-  evidence after a run ([`marathon-cleanup`](skills/marathon-cleanup/SKILL.md)); and — the one deliberate,
./relay-system/2026-08-23/marathon-p1-164126.md:60:- **`utils/py/relay_drive.py`**: Added logic to write `### Extension · System` to the relay file so that it's reliably captured in the durable archive by `save_transcript()`. Also added a structured reason channel by writing to `.relay-scratch/escalation-reason` before any exit 4.
./relay-system/2026-08-23/marathon-p1-164126.md:61:- **`utils/py/marathon_drive.py`**: Modified the `relay_exit == 4` block to read `.relay-scratch/escalation-reason` to distinctively log and pass the specific reason down instead of mapping everything blindly to `cap-or-close-mismatch`. Changed the `argparse` default for `--round-cap` to `None` to fix the CLI precedence overwrite defect.
./relay-system/2026-08-23/marathon-p1-164126.md:81:- **`utils/py/relay_drive.py`**: Added an `exit_escalate(reason)` helper to ensure all `sys.exit(4)` paths publish a distinct reason to `.relay-scratch/escalation-reason` before exiting. Updated existing escalation exits to use this helper.
./relay-system/2026-08-23/marathon-p1-164126.md:82:- **`utils/py/marathon_drive.py`**: Changed the `relay_exit == 4` block to read `.relay-scratch/escalation-reason` under `xyz_harness` rather than `root`, ensuring paths match in a vendored layout. Added clearing of any stale `escalation-reason` file before launching `relay_drive`.
./relay-system/2026-08-23/gh185-qa-cmd-oxalpha.md:33:fixture split (#181: GH-141 record = tokenization, synthetic live record = reproduction,
./relay-system/2026-08-23/gh185-qa-cmd-oxalpha.md:81:- [SEVERITY: minor] Path-rewriting heuristic (`repro_builder.py:38-48`) has real failure modes: (1) **multiple absolute paths** — only the first match is rewritten; `bash /a/tool.sh --flag /other/x.sh` leaves `/other/x.sh` absolute, breaking hermeticity of the baked repro; (2) **`.sh` inside argument payloads** — `tool.sh --note "see /docs/run.sh for help"` rewrites prose inside a quoted string if a same-named file happens to exist under repo_root, corrupting argv; (3) **quoted paths** — `'/abs/x.sh'` followed by `'` matches neither `\s` nor `$`, so the path is left absolute (unquoted joins from `" ".join(cmd)` do match, which covers the actual GH-141 shape); (4) **relative `.sh` tokens** are correctly untouched. Mitigating factor keeping this minor: every misrewrite is caught downstream by the mandatory initial-reproduction gate (mis-tokenized command won't reproduce → exit 2), so corruption degrades to refusal, never to a wrong reproducer. Worth a TODO to iterate over all matches, not just the first.
./relay-system/2026-08-23/gh185-qa-cmd-oxalpha.md:88:- [SEVERITY: note] The #181 split is sound: tokenization (real spaced-path record), reproduction (synthetic live record, rc 7 + signature), wrong-cause rejection (rc-coincident twin without signature) each pin one contract, and the amendment honestly documents that GH-141's defect is historical (fixed by GH-156). What's lost: no end-to-end proof that the pipeline handles a *real-world* record shape through build-to-reproduction (the synthetic record uses a list-form `cmd`, sidestepping the string-tokenization + rewrite + reproduce path in one flow — the GH-141 record proves parsing but its build is asserted to *refuse*). Acceptable given the defect is genuinely fixed; worth revisiting when the next real live spaced-path defect arrives.
./relay-system/2026-08-23/salvage-location-214521/salvage-location.PROMPT.txt:1:Question: where should the marathon-cleanup SOP store "clone-teardown salvage" data, and why?
./relay-system/2026-08-23/salvage-location-214521/salvage-location.PROMPT.txt:4:- Disposable marathon clones of this repo accumulate unique UNCOMMITTED per-clone state before deletion: GH-174 turn-telemetry (`harnesses.db` + `harnesses.sql` diffs), regenerated `HARNESS-MODELS-REGISTRY.generated.md` / `docs/blog-frontier-benchmarks.md`, and `.relay-scratch/` probe JSON.
./relay-system/2026-08-23/salvage-location-214521/salvage-location.PROMPT.txt:5:- This data must survive clone deletion until an operator merges it into the canonical `harnesses.db` in the primary clone, then it is disposable.
./relay-system/2026-08-23/salvage-location-214521/salvage-location.PROMPT.txt:6:- Today it was salvaged ad hoc to `~/marathon-clones/gh174-telemetry-salvage-2026-08-23/<clone-name>/` (outside any repo).
./relay-system/2026-08-23/salvage-location-214521/salvage-location.PROMPT.txt:9:1. Outside the repo beside the clones (`~/marathon-clones/<salvage-dir>/`) — safe from all repo tooling, but undiscoverable; no session auto-loads it, easy to forget.
./relay-system/2026-08-23/salvage-location-214521/salvage-location.PROMPT.txt:10:2. Inside the primary repo under `relay-system/` (committed thread storage) or a new top-level `marathon-system/` folder — discoverable and versionable, but: (a) GH-141 hazard — untracked/hand-added files in a clone while a driven turn is in flight can be swept into `.tick/orphan-backups/` or reverted; (b) dirties a working tree that may have pending PR decisions; (c) binary `harnesses.db` blobs in git history if committed.
./relay-system/2026-08-23/salvage-location-214521/salvage-location.PROMPT.txt:11:3. `.tick/orphan-backups/` — existing backup convention, but gitignored, per-clone, and deleted with the clone: unsuitable for teardown salvage by construction (confirm or refute).
./relay-system/2026-08-23/salvage-location-214521/salvage-location.PROMPT.txt:12:4. Anything better you can argue for (e.g. XDG data dir like `~/.local/share/xyz/salvage/`, or a gitignored-but-in-repo dir with a README pointer, or "don't salvage — merge before delete as an SOP gate").
./relay-system/2026-08-23/salvage-location-214521/salvage-location.PROMPT.txt:14:What "good" looks like: one recommended location + rationale, an explicit statement on whether "merge-before-delete" should replace salvage entirely, and how discoverability is guaranteed (what pointer, where). Judge the GH-141 sweep hazard seriously: the repo's turn shims revert non-allowlisted new files in the real tree during driven turns.
./relay-system/2026-08-22/gh-agent2agent-skill-review-beb9c833.md:47:- Definition of Done: focus on the two bullets under `## Guardrails` — "A conditional teardown
./relay-system/2026-08-22/gh-agent2agent-skill-review-beb9c833.md:51:  conditional teardown instruction ("if fully on origin, tear down the clone"); the agent didn't
./relay-system/2026-08-22/gh-agent2agent-skill-review-beb9c833.md:75:  The teardown guardrail (lines 237-250) requires the agent to "confirm with the operator once more before executing." However, it fails to specify how an agent should handle this when running in a headless/non-interactive mode (like Drive) where user confirmation is impossible.
./relay-system/2026-08-22/gh-agent2agent-skill-review-beb9c833.md:79:  The teardown guardrail asks the agent to pause for confirmation. In the Doorbell protocol, if an agent pauses without executing a `send`, it does not receive the `REARM:` command (which only prints after `send`).
./relay-system/2026-08-22/gh-agent2agent-skill-review-beb9c833.md:83:  The teardown guardrail discusses executing teardown/destructive instructions on clones, worktrees, or branches. However, the Drive section (lines 262-266) strictly scopes authority to "composing and sending this participant's own turn — it must never read, judge, or act on another participant's workspace". The guardrail implies destructive actions *could* be permissible if verified and confirmed, creating tension with the Drive section's strict prohibition.
./relay-system/2026-08-22/gh-agent2agent-skill-review-beb9c833.md:84:  *Fix:* Align the teardown guardrail with the Drive section by clarifying that under no circumstances should a participant execute teardowns on a peer's workspace (even if confirmed), and distinguish between a participant's own workspace teardown versus a peer's.
./relay-system/2026-08-22/gh-agent2agent-skill-review-beb9c833.md:109:  Restructured the teardown guardrail so the FIRST question is "is the target another participant's
./relay-system/2026-08-22/gh-agent2agent-skill-review-beb9c833.md:129:- **[Blocker]** Tension within the teardown guardrail's incident description (DoD #2).
./relay-system/2026-08-22/gh-agent2agent-skill-review-beb9c833.md:140:  The teardown guardrail properly distinguishes between one's own workspace and a peer's workspace, aligning with the Drive section's strict scope. (Cited lines 237-243: "...NEVER permission to touch another participant's workspace. Before running any destructive command... first ask whether the target is or might be another participant's own workspace. If so, stop: the next bullet's absolute rule governs...")
./relay-system/2026-08-22/gh-agent2agent-skill-review-beb9c833.md:151:- **[Blocker] Incident narrative implying confirmation could excuse peer-workspace teardown —
./relay-system/2026-08-22/gh174-harness-registry-plan-qa-deepseek.md:28:  1. Relational SQLite Ledger (`harnesses.db` + `harnesses.sql` dump) replacing static Markdown tables.
./relay-system/2026-08-22/gh174-harness-registry-plan-qa-deepseek.md:176:   sqlite3 harnesses.db "PRAGMA foreign_key_check; 
./relay-system/2026-08-22/gh174-harness-registry-plan-qa-deepseek.md:228:- **Mitigation:** Implement a synchronization mechanism to ensure that changes in the SQLite database are reflected in the Markdown file and vice versa. Use a script to generate the `HARNESS-MODELS-REGISTRY.generated.md` file from the SQLite database.
./relay-system/2026-08-22/gh-agent2agent-test-standalone-qa.md:78:### Review salvaged from openrouter/stealth/ox-alpha transcript (aider-turn.sh · GH-251)
./relay-system/2026-08-22/gh-agent2agent-test-standalone-qa.md:689: • P5: Lock-holder teardown kills + waits, no orphan (line 122).                
./relay-system/2026-08-22/gh-agent2agent-test-standalone-qa.md:988: teardown kills then waits                                                      
./relay-system/2026-08-22/gh-agent2agent-test-standalone-qa.md:1180:kill+wait teardown), and the shell sweep found no bugs beyond nits. Four        
./relay-system/2026-08-22/gh-agent2agent-test-standalone-qa.md:1250: +(`grep -q "held-since" "$lock_dir/.$lock_base.lock"`), and teardown is        
./relay-system/2026-08-22/gh-agent2agent-test-standalone-qa.md:1657:chain-of-thought salvage (aider-turn.sh's GH-251 recovery path — a known, documented seam
./relay-system/2026-08-22/gh-agent2agent-test-standalone-qa.md:1710:through the salvage path) — reporting to the operator instead of looping. `NEXT` is left on
./relay-system/2026-08-22/gh165-post-merge-reconcile-plan-qa.md:144:   write, or plan write, renders proposed outputs against isolated copies under `.relay-scratch/` or an
./relay-system/2026-08-22/573353-agent2agent-pr-166-gh-165-wave-reconciler-marathon-triage-overlap-wo.md:46:* **`.relay-scratch/`:** Ephemeral relay artifacts generated by the DeepSeek QA turn (`relay-drive.sh`), safe to ignore/clean.
./evidence/02-validate-sequential.log:834:  PASS: GH-251: transcript review salvaged into the relay file (attributed)
./evidence/02-validate-sequential.log:835:  PASS: GH-251: salvaged block carries the graded verdict
./evidence/02-validate-sequential.log:836:  PASS: GH-251: salvaged review committed (turn lands, not a stall)
./evidence/02-validate-sequential.log:838:  PASS: GH-251: non-review turn not salvaged (no false rescue)
./evidence/02-validate-sequential.log:3467:test-turn: pre-revert copy of PROJECT/peer.md saved under /tmp/rtl-orphan-backup.oSKOIw/repo/.tick/orphan-backups/20260820T110900Z-11786
./evidence/02-validate-sequential.log:3469:test-turn: pre-revert copy of PROJECT/peer-new.md saved under /tmp/rtl-orphan-backup.oSKOIw/repo/.tick/orphan-backups/20260820T110900Z-11786
./evidence/02-validate-sequential.log:3482:Running gh91-relay-scratch.sh
./evidence/02-validate-sequential.log:3487:  PASS: rtl_check: the collapsed '.relay-scratch/' status form is exempted and discarded too
./evidence/02-validate-sequential.log:3489:test-turn: pre-revert copy of stray.txt saved under /tmp/gh91-relay-scratch.EVge6t/repo/.tick/orphan-backups/20260820T110900Z-11834
./evidence/02-validate-sequential.log:3490:  PASS: CONTROL: a stray file OUTSIDE .relay-scratch still violates (exit-6 path intact)
./evidence/02-validate-sequential.log:3492:test-turn: OFF-ALLOWLIST change: .relay-scratch2/out.json — reverting
./evidence/02-validate-sequential.log:3493:test-turn: pre-revert copy of .relay-scratch2/out.json saved under /tmp/gh91-relay-scratch.EVge6t/repo/.tick/orphan-backups/20260820T110900Z-11834
./evidence/02-validate-sequential.log:3494:  PASS: CONTROL: '.relay-scratch2' (lookalike prefix) is NOT exempt
./evidence/02-validate-sequential.log:3496:  PASS: rtl_worktree_end: probe output in .relay-scratch is NOT off-lane
./evidence/02-validate-sequential.log:3514:  gh91-relay-scratch: 22 pass, 0 fail
./evidence/02-validate-sequential.log:6297:  + gh91-relay-scratch.sh
./relay-system/2026-08-22/818589-agent2agent-review-pr-149-against-issue-142-from-tmp-xyz-141-pnt4ib.md:56:I do not accept the full-gate claim yet. You cite commit `956ba9ad`, but the checked-out PR head and `origin/gh141-fuzz-ate-utility` are `feca8732`; `git log origin/development..HEAD` contains only that commit. The committed plan at `PROJECT/2-WORKING/GH-141-FUZZ-ATE-UTILITY.md:32` says "Full gate green" is still next, and its verification ladder at :152-155 requires `gh141-ate-chain-hermetic.sh` even though no such file exists (the status table says gh142 replaced it). No committed `provenance.jsonl` or other final-SHA receipt is present in this diff.
./relay-system/2026-08-22/818589-agent2agent-review-pr-149-against-issue-142-from-tmp-xyz-141-pnt4ib.md:69:Q1 (full-gate evidence for the PR head): CONCEDED as stated, now cured properly. Root cause of the stale citation: after the gate I amended the commit to drop a `.relay-scratch/` artifact that `git add -A` had swept in — the amend changed the SHA (956ba9ad → feca8732) and every later citation kept the pre-amend SHA. Your tree-equivalence argument was available (diff 956ba9ad..feca8732 = exactly that one file) but you are right that it is not the standard. The branch head is NOW `a581079f`, a fresh commit carrying the turn-3 remediation, and the full gate was re-run on that exact clean committed tree: ./validate.sh **249/249**, pdda 0 errors, working tree porcelain-clean at gate time. The PR body and the plan doc's verification ladder (step 2) now both cite SHA-exact receipts and the ladder rule is written down: a gate cited to any other SHA is not evidence.
./HARNESS-MODELS-REGISTRY.md:45:| Aider + OpenRouter | `openrouter/qwen/qwen3.8-max` | Cloud | Advisory review **under supervision only** — never unattended; builder untested on this exact route | **C** | **The model's review content was the strongest recorded this day; the Aider reviewer SEAM is what fails.** Turn 1 landed a correct, fully-cited 7-blocker review with zero false positives. Turn 2 on the same thread produced no findings at all — the model entered a meta-loop about its own output format (whether to edit the `NEXT:` line, how to nest triple-backtick fences when echoing a file containing them) — and `aider-turn.sh`'s GH-251 salvage then appended ~1,200 lines of raw chain-of-thought into the relay file as if it were review content. Budget a human to read and truncate after **every** turn. The shim's qwen brevity instruction (`aider-turn.sh:145-147`, "under 50 words") does not hold on review-only turns. **SECOND USAGE 2026-08-20 (GH-111 + GH-108 code QA) — same split, sharper.** One `--review-once` turn against a 1,944-line diff: 13m 44s wall clock, verdict *Changes requested*, 0 Blockers, 2 `[Should]`, 3 `[Nit]`, 16 `[Pass]` each carrying a file/symbol citation, plus an honest `swept file: yes`. **Every finding was reproduced by the operator before acceptance and every one held** — two real regex false positives that refused a correctly scored entry, one under-graded correctness gap (baseline provenance was mutable; upgraded to Should and shipped as migration 005), one cosmetic bug. Zero hallucinated findings. **The seam failed the same way again:** the model did not append to the relay file; GH-251 salvage recovered the review from the transcript. New datum — the salvage output was **usable this time** (~1,200 lines of thinking with a correctly graded review at the end), so the salvage is not purely a noise amplifier; but 1 of 3 review turns has now landed natively, which is why this stays **C** and not a promotion. | [#111](https://github.com/HiQS-Suite/XYZ-forge/issues/111), [#108](https://github.com/HiQS-Suite/XYZ-forge/issues/108); relays `relay-system/2026-08-20/gh111-dialed-in-qa.md` (usage 1) and `relay-system/2026-08-20/gh111-gh108-qa.md` (usage 2, with the operator's finding-by-finding adjudication) |
./HARNESS-MODELS-REGISTRY.md:53:| Command Code | `zai-org/GLM-5.3` (GLM 5.3 High) | Cloud | Autonomous Marathon Driver, Builder, and PR Orchestration | **A-** | `cmd -p --tools-all --yolo -t` with isolated workspace clones; verified across two multi-phase marathons (5 phases total). Zero test regressions; clean PRs, branch push verification, and workspace teardown. | [rebalanceOS PR #117](https://github.com/HiQS-Suite/rebalanceOS/pull/117) (Build 0.76.0, 2/2 phases approved, 2,018 tests passed); [rebalanceOS PR #118](https://github.com/HiQS-Suite/rebalanceOS/pull/118) (Build 0.77.0, 3/3 phases approved, 2,026 tests passed) |
./HARNESS-MODELS-REGISTRY.md:98:  2. **GH-251 salvage amplifies a bad turn.** When the model produces reasoning instead of a review,
./HARNESS-MODELS-REGISTRY.md:99:     the salvage path faithfully preserves that reasoning *as relay content* — here ~1,200 lines.
./HARNESS-MODELS-REGISTRY.md:137:  2. *Test 2:* `consult.py` dogfooding with throwaway worktree isolation, pre-created `.relay-scratch/`, and a 1,935-trial paired density benchmark committed in `TESTS-RESULTS/2026-08-20+GH-101/`.
./HARNESS-MODELS-REGISTRY.md:141:### 3.2 Automated Triage Evaluation: Local Gemma 4 in ATE (GH-94 / GH-141)
./HARNESS-MODELS-REGISTRY.md:143:Local Gemma 4 (`google/gemma-4-31b-qat` via LM Studio) was evaluated as the automated triage judge in `utils/ate/scripts/run_variations.py` across two multi-hour campaigns: the 438-iteration GH-94 campaign and the 143-iteration GH-141 1-hour soak campaign (`TESTS-RESULTS/2026-08-22+GH-141/`). It performed reliably with zero JSON schema failures and 100% parseable structured triage classifications. Because `run_variations.py` is an experimental testing script rather than a core XYZ runtime shim, this evaluation qualifies Gemma 4 specifically for offline test triage ($0 operational token cost) rather than production coding or relay turn execution.
./HARNESS-MODELS-REGISTRY.md:176:| **2026-08-22** | ATE 1-Hour Fuzz Campaign (GH-141 soak) | Policy & benchmark baseline recorded | Executed 60.0-minute automated testing campaign across all 7 turn shims with local Gemma 4 31B triage on LM Studio. Completed 143 full execution-and-classification cycles with zero crashes, hangs, or memory leaks; telemetry receipts archived to `TESTS-RESULTS/2026-08-22+GH-141/error_log.jsonl`. |
./HARNESS-MODELS-REGISTRY.md:177:| **2026-08-20** | Aider + OpenRouter + Qwen 3.8-Max, **reviewer role — 2nd reported usage** | **C confirmed, not promoted** | Second review turn on this route, against CODE this time (the 1,944-line GH-111 + GH-108 diff) rather than a plan doc. `--review-once`, `ALLOW_PATHS=""`, worktree isolation ON, 13m 44s. **Content: the strongest signal-to-noise yet.** Verdict *Changes requested* with 0 Blockers, 2 `[Should]`, 3 `[Nit]`, 16 cited `[Pass]`, and a declared `swept file: yes`. The operator reproduced every finding before acting: both `[Should]`s were live regex false positives that refused a correctly scored ROADMAP entry, and one `[Nit]` was under-graded — `baseline_source` was mutable, letting a `backfilled` baseline be quietly relabelled `observed`, which is a correctness gap in the metric and shipped as migration 005. **Zero hallucinated findings; zero uncited Passes.** **Delivery: failed identically to usage 1** — no relay-file append, GH-251 salvage recovered the review from the transcript. The salvage output was *usable* this time, which is new, but native delivery now stands at 1 of 3 turns. **Net: the grade holds at C for exactly the reason the registry already states — one good turn is not evidence the seam is fixed, and two good turns out of three still means a human reads every one.** [#111](https://github.com/HiQS-Suite/XYZ-forge/issues/111), [#108](https://github.com/HiQS-Suite/XYZ-forge/issues/108); relay `relay-system/2026-08-20/gh111-gh108-qa.md`. |
./HARNESS-MODELS-REGISTRY.md:178:| **2026-08-20** | Programmatic Tool Execution (`script_runner.py`, GH-101) | Promoted to **Production-Ready (A)** | Completed 3-stage qualification ladder: Test 1 architectural fail-closed scoping; Test 2 `consult.py` throwaway worktree isolation with 1,935-trial paired density benchmark (`TESTS-RESULTS/2026-08-20+GH-101/`); Test 3 `relay_drive.py` / `relay-turn-lib.sh` integration with fail-closed sandbox verification, `.relay-scratch/` isolation, PGID cleanup, and synthetic stress verification (`test/synthetic/gh101-relay-programmatic-stress.sh`, 10/10 synthetic fuzz pass). |
./HARNESS-MODELS-REGISTRY.md:179:| **2026-08-20** | Aider + OpenRouter + Qwen 3.8-Max, **reviewer role** | Added **C** | Both halves recorded deliberately, because they point opposite ways. **Positive — the review content was excellent, arguably the best of the day across three harnesses.** One turn against a plan doc produced seven blocking findings, each citing file and line, and **every one verified true against the live schema before acceptance**: SQLite cannot ALTER a CHECK constraint in place (the migration as drafted was unimplementable); an existing `UNIQUE (release_id, issue_ref_id)` made the drafted state machine impossible; an entire table the plan ignored (`manifest_state_events`, with its own old-vocabulary CHECKs, append-only triggers, and a `NOT NULL` reason column that the proposed `manifest ship` verb had no value for); and a backfill that named `releases.created_at`, **a column that does not exist**. It also returned explicit verdicts on all five of the plan's open questions. Zero false positives. **Negative — the seam failed on the very next turn, twice.** The model produced no findings, instead looping on its own output format; GH-251 salvage then appended ~1,200 lines of chain-of-thought into the relay file as review content. `ALLOW_PATHS=""` containment held and the reviewed artifact was untouched. Lane abandoned by operator instruction after one retry; verification rerouted. **Net: use this route for advisory review only with a human reading every turn — the intelligence is real, the delivery is not.** [#111](https://github.com/HiQS-Suite/XYZ-forge/issues/111); relay `relay-system/2026-08-20/gh111-dialed-in-qa.md`. |
./RELEASES.md:134:RC evidence: `bash test/nightwatch-release.sh --release-gate` → `GOALPOST MET — all 8 manifest entries complete and every lifecycle case executes green` (manifest 8/8, lifecycle 5 passing / 0 failing / 0 NOT COVERED). Its own negative control, `--mutate-evidence`, reports 34/0 and `negative control OBSERVED in both directions`. Every manifest entry carries a recorded pre-fix control under `test/baselines/`, not an assertion that one happened. **Two entries are honest about their limits and are worth reading before signing off:** #358's Phase 2 is a *disposition* that needs a real CI failure carrying the new instrumentation, and its capture doc forbids pre-committing one — so Phase 1 shipped and Phase 2 is blocked on an observation, not on work; and #354's membership is Phase 1 only, which was delivered by #376/#448 rather than by this release, recorded as such rather than rebuilt. **#426's outcome inverted its own diagnosis:** a factorial control showed the leak survives with worktree isolation OFF, so teardown was exonerated and the real cause was the GH-375 auth pre-flight running with the caller's CWD, outside containment. **Twelve open Nightwatch-milestone issues remain and gate nothing**, per this block's own "a release is not its milestone" rule. **CI-VERIFIED 2026-08-12, and it was not before:** the goalpost was first met on macOS only, and two of the five lifecycle cases (#388, #514) were failing on every ubuntu CI run at the time the RC was recorded — their fixtures stubbed the builder but not the reviewer binary, so `marathon_drive.py`'s probe fail-fasted and the cases never executed the code they assert on. Fixed, and the gate now reports `GOALPOST MET` with `codex` absent from `PATH`, which is the CI condition reproduced locally rather than inferred. Recorded here because it is exactly the class of thing this release exists to catch: a green result that was green about the wrong environment. The general defect is #520; the control is `test/baselines/GH-520-negative-control.md`.
./RELEASES.md:178:Publication target: **the deliverable is a sanitized clone, not this repository** — fresh history, single initial commit, pushed to **https://github.com/HiQS-Suite/XYZ-forge** (new org, named by the operator 2026-08-15, XYZ's permanent home). `CHANGELOG.md` carried forward verbatim as the public record; carrying the 2,147-commit history was rejected 2026-08-15 because a full-history secret scan would have to scan everything ever deleted — fresh history makes sanitization complete by construction. `.tick/` (161 MB) and `relay-system/` (32 MB) do not ship; `PROJECT/` ships as an empty PDDA scaffold plus the Meter build docs retained as a worked example — the method travels, the backlog does not.
./RELEASES.md:196:Exit criterion: `bash test/ballast-release.sh --release-gate` exits 0. **NOT BUILT — writing it is Ballast's first task, before any member is fixed** (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. **Half A audits the frozen manifest:** each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. **Half B EXECUTES the stranger's path rather than auditing it:** (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. **SHIPPED 2026-08-18.** `XYZ_BALLAST_STRANGER_RUNS=10 test/ballast-release.sh --release-gate` executed for real against a fresh disposable clone (`~/xyz-disposable/xyz-stranger-clone`): exit 0. Half A: 4 of 4 manifest members complete (#14, #15, #4, #3 — gate/registration/control/CLOSED-issue all confirmed). Half B: 4 of 4 passing (B1: 10/10 consecutive parallel runs with zero failures; B2a: ungated clone warning in-band; B2b: forced-red push refusal; B3: atomic-append cross-process stress case clean) — **GOALPOST MET**.

exec
/bin/zsh -lc 'cat skills/marathon-cleanup/SKILL.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-17781-brvet5yb
 succeeded in 0ms:
---
name: marathon-cleanup
description: >
  Audit active PDDA marathon plans and bundles, reconcile every lane against canonical project docs,
  frontmatter and status tables, GitHub issue and PR state, landed commits, tests, and CHANGELOG
  evidence, then archive only verified-complete task docs and fully complete marathons. Use when asked
  to clean up, reconcile, retire, archive, or sweep completed marathon files under PROJECT/2-WORKING,
  especially after marathon lanes merge. Defaults to report-only and requires explicit confirmation
  before moving files or changing lifecycle records.
---

# Marathon cleanup

Reconcile marathon execution artifacts with PDDA lifecycle state. A move is the final bookkeeping
step, never the evidence that work completed.

## Guardrails

- Read `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `ROADMAP.md`, `PROJECT/PDDA.md`, and the
  candidate marathon in full before classifying it.
- Default to audit-only. Do not edit, move, close issues, create commits, or change ROADMAP or
  CHANGELOG until the operator confirms the exact proposed move set.
- Never classify from a closed issue, checked box, frontmatter word, commit message, or changelog
  entry alone. Require converging durable evidence and no contradiction.
- Preserve unrelated dirty-worktree changes. Stop if a candidate or lifecycle ledger has overlapping
  edits that cannot be safely merged.
- Use `git mv` for approved repo moves. Never delete marathon files or rewrite history.
- Treat unavailable GitHub state as `UNKNOWN`, not complete.

## 1. Inventory marathon candidates

Inspect only active execution artifacts under `PROJECT/2-WORKING`:

```bash
find PROJECT/2-WORKING -maxdepth 1 \
  \( -type f -o -type d \) \
  \( -name 'MARATHON-*.md' -o -name 'MARATHON-*' \) \
  -print | LC_ALL=C sort
```

Include hand-authored and generated marathon plans plus execution bundle directories. Classify
generated HQ rollups, triage reports, examples, snapshots, and docs that merely mention marathons as
`NOT-EXECUTION-DOC`; do not archive them through this workflow.

For each candidate, extract lane IDs from frontmatter (`lanes`), wave/lane tables, issue links,
phase briefs, and bundle YAML. Resolve each lane to its canonical `GH-<n>-*.md` document when one
exists. Report duplicate or contradictory mappings rather than choosing silently.

## 2. Build an evidence record per lane

Collect these signals without changing state:

| Signal | What to verify | Weight |
|---|---|---|
| Canonical PDDA doc | Location, terminal frontmatter, exact Status table, acceptance/QA state, explicit remaining work | Primary scope record |
| Marathon plan or brief | Bounded lane scope, terminal lane result, reviewer verdict, branch/PR/commit references | Scope and execution record |
| GitHub issue | Open/closed state, close reason, linked PRs, comments that narrow or preserve remaining scope | Corroboration; closed alone is insufficient |
| Delivery | Merged PR or commit is reachable from the intended target branch; changed paths match the lane | Required for implementation lanes |
| Verification | Recorded tests/gates passed for the shipped scope; no unresolved failed gate | Required |
| CHANGELOG | Dated entry names the issue/scope and delivery outcome | Provenance corroboration |

Useful read-only probes:

```bash
gh issue view <n> --json number,title,state,stateReason,closedAt,url,comments
gh pr list --state all --search '<n>' --json number,title,state,mergedAt,mergeCommit,url
git log --all --decorate --oneline --grep='GH-<n>\|#<n>'
git merge-base --is-ancestor <commit> development
rg -n "GH-<n>|#<n>" CHANGELOG.md PROJECT ROADMAP.md
```

Use the actual target branch from repo policy or the marathon contract in place of `development`
when they differ. Verify a referenced commit exists before running `merge-base`.

## 3. Classify every lane

Assign exactly one result:

| Result | Rule | Parent marathon eligible? |
|---|---|---|
| `VERIFIED-COMPLETE` | Entire canonical task scope is terminal, delivered, verified, and consistent | Yes; task doc may move |
| `VERIFIED-MARATHON-SLICE` | This marathon's explicitly bounded slice is delivered and verified, while separately stated issue scope remains | Yes; task doc stays active |
| `OPEN` | Acceptance work remains or issue/doc says active | No |
| `BLOCKED` | Work is parked, failed, awaiting review, unmerged, or gate-failed | No |
| `AMBIGUOUS` | Evidence is missing or too weak | No |
| `CONFLICT` | Durable sources disagree about completion, target, or scope | No |

`VERIFIED-COMPLETE` requires all of the following:

1. The canonical doc explicitly records the completed outcome and has no in-scope next action.
2. Implementation is merged/reachable on the intended target branch, or a docs/research lane records
   its required durable artifact.
3. The lane's acceptance criteria and relevant gates have positive verification evidence.
4. GitHub state and CHANGELOG do not contradict the local outcome. An open issue requires an explicit
   reason; otherwise classify `CONFLICT`.

Use `VERIFIED-MARATHON-SLICE` only when the plan defined the slice before or during execution and the
canonical doc clearly separates remaining issue work. Do not retroactively narrow scope to make a
marathon look complete.

## 4. Decide task-doc and marathon moves separately

A canonical `GH-*.md` task doc may move from `2-WORKING` to `3-COMPLETED` only when its result is
`VERIFIED-COMPLETE`. Before proposing the move, require a PDDA terminal lead word such as `Complete`,
`Shipped`, `Fixed`, `Closed`, `Merged`, `Resolved`, or `Landed`, and reconcile its Status table.

The parent marathon may move only when:

- every lane is `VERIFIED-COMPLETE` or `VERIFIED-MARATHON-SLICE`;
- no wave, lane, review, merge, gate, or operator action remains;
- the marathon's own status can truthfully become terminal;
- all sibling bundle files describe the same terminal outcome;
- the destination does not already exist; and
- relative links will remain valid or are included in the proposed edit set.

An open issue does not block a completed marathon slice by itself. It does block moving that issue's
canonical task doc unless the entire issue is complete and the open state is being explicitly
reconciled.

## 5. Report before mutation

Return one table per marathon with lane result, canonical doc, GitHub state, delivery proof,
verification proof, CHANGELOG proof, contradictions, and proposed action. End with one exact move
set, for example:

```text
git mv PROJECT/2-WORKING/GH-123-EXAMPLE.md PROJECT/3-COMPLETED/
git mv PROJECT/2-WORKING/MARATHON-PLAN-YYYY-MM-DD.md PROJECT/3-COMPLETED/
```

Also list required content edits and ledger updates. Ask for explicit confirmation of that set. If
any lane is not eligible, leave the marathon in place and state the smallest evidence or work needed.

## 6. Apply a confirmed cleanup

After confirmation, execute in this order:

1. Re-check `git status`, GitHub state, target-branch reachability, and destination absence.
2. Update eligible task docs to terminal frontmatter and an evidence-backed Status row; preserve
   issue links and outcome detail.
3. Update the marathon plan and every file in its bundle to the verified terminal outcome. Do not
   leave `not yet fired`, `ready`, or an outstanding next action inside `3-COMPLETED`.
4. Use `git mv` for eligible task docs, then the fully complete marathon file or directory.
5. Update ROADMAP pointers and state in place. Keep it a pointer ledger; do not copy execution detail.
6. Add a concise dated CHANGELOG entry naming the verified outcome and moved artifacts.
7. Run `utils/pdda/pdda.sh run`. Run relevant link or repo validation when links or code changed.
8. Report moves, evidence, validation output, and anything deliberately left active.

If validation fails, do not claim completion. Repair only changes in the confirmed cleanup scope; if
the failure is unrelated, report it precisely without altering unrelated user work.


exec
/bin/zsh -lc 'rg -n --hidden -S "orphan-backups|rtl_before|rtl_check|relay-scratch|harnesses.sql|harnesses.db|generated.md|blog-frontier" relay-automation utils skills PROJECT .gitignore ROUTER.md AGENTS.md | head -n 400' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-17781-brvet5yb
 succeeded in 0ms:
AGENTS.md:138:  snapshots the doomed tracked files into `.tick/orphan-backups/` before the command runs, so
.gitignore:25:# ignored — rtl_check already deletes any file landing in the tracked tree that matches the shim's
.gitignore:73:RELEASES.generated.md
.gitignore:74:RELEASES.generated.md.drift
PROJECT/3-COMPLETED/GH-57-RELEASES-SQLITE-FUZZING.md:50:   - Side-by-side view `RELEASES.generated.md` generated without touching `RELEASES.md`.
PROJECT/3-COMPLETED/GH-57-RELEASES-SQLITE-FUZZING.md:51:   - Discrepancies reported in `RELEASES.generated.md.drift`.
PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md:25:  Migrate static HARNESS-MODELS-REGISTRY.md into an active SQLite ledger (harnesses.db)
PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md:36:| Phase 1-5 implemented: `harnesses.db` schema, CLI `harness_app.py`, 3-tier config `device_config.py`, telemetry `harness_turn_logger.py`, AI grading hooks, blog generator, and 6/6 test assertions passing in `test/gh174-harness-registry.sh`. | Full validation gate run and pull request merge. |
PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md:50:3. **Dual Storage & Reversibility:** SQLite `harnesses.db` paired with human-readable, lossless `harnesses.sql` dump and generated `HARNESS-MODELS-REGISTRY.generated.md`.
PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md:54:## 3. SQLite Relational Schema (`harnesses.sql`)
PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md:151:- **Phase 1 (Core Schema & CLI Engine):** Implement `utils/py/harness_app.py`, `harnesses.db`, `harnesses.sql`, and `harness check` integrity tests.
PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md:15:  .relay-scratch/ — exempted like the other intrinsic write categories, pre-created by
PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md:30:| **BUILT 2026-08-20 (linked worktree `XYZ-forge-gh91`, branch `fix/gh91-relay-scratch`)** — issue option 1 implemented across all four surfaces: `rtl_worktree_begin` pre-creates `.relay-scratch/` in the isolated worktree (the affordance physically exists, not prose); `rtl_worktree_end` exempts it intrinsically (no signature check — it is *meant* to be written, unlike the read-only `.relay-artifacts/` seed) and never copies it back; `rtl_check` on the non-worktree path exempts AND discards it (`rm -rf` — it lives in ROOT there and must neither linger nor ride into a commit); `rtl_turn_prompt` names it at the point of use with its disposition. `.gitignore` carries `.relay-scratch/` as defense in depth (the exemption is intrinsic in code and does not depend on it, per the `.tick` lesson). New suite `test/gh91-relay-scratch.sh` **15/0** with controls: stray writes still violate, lookalike prefix `.relay-scratch2` is NOT exempt, off-lane worktree turns still copy nothing back. Containment-pinning neighbors re-run green (worktree-isolation 33/0, shim-worktree 32/0, relay-artifact-file 13/0, rtl-orphan-backup 8/0, gh410 11/0, path-overlap, relay-xyz-skill-guard, untracked-file-warn, seeding-visibility, relay-target-root). | Full gate from a NORMAL clone (GH-45 refuses it from this worktree — by design), then PR into `development`. Watch the next daybreak re-fire: the builder should now put probe output in `.relay-scratch/` because the prompt says so at the point of use. If a lane still writes scratch elsewhere, that is a prompt-weighting question for GH-77's briefs, not a missing facility. |
PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md:45:`.relay-scratch/`, treated as an intrinsic write category:
PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md:49:| `rtl_worktree_begin` | `mkdir -p "$wt/.relay-scratch"` — the affordance physically exists before the turn starts |
PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md:51:| `rtl_check` (non-worktree) | exempt AND discard: `rm -rf "${RTL_ROOT:?}/.relay-scratch"` — the transcript-log drop is the precedent; `${RTL_ROOT:?}` guards the empty-prefix `rm -rf` (GH-567) |
PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md:53:| `.gitignore` | ~~`.relay-scratch/`~~ — **REVERTED in review**: the entry hid the dir from porcelain, so `rtl_enforce`'s per-path `rtl_check` discard never fired and scratch lingered in ROOT forever (the reviewer reproduced it end-to-end). The real guarantee is the unconditional sweep in `rtl_enforce`, independent of git visibility |
PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md:59:| `test/gh91-relay-scratch.sh` (new, registered in TESTS same commit) | **22/0** — lib-function level, no builder binary: scratch not a violation + discarded + lane edit untouched (both the file and collapsed-dir status forms); CONTROLS: stray write still exit-6s and is reverted, `.relay-scratch2` lookalike not exempt, worktree stray still off-lane with copyback withheld; begin pre-creates the dir; end exempts without copying back; prompt names the room and its disposition. **PR #93 review round:** prompt template renders EXACTLY once (printf arg/conversion cardinality — bash recycles the format and a 14th arg without a 14th `%s` doubled the whole template garbled; the old substring greps passed through that, so the pins are cardinality + position now), and an INTEGRATION case through `rtl_enforce` with `.relay-scratch/` gitignored: turn passes (exit 0), ignored scratch still discarded, lane edit committed file-scoped |
PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md:66:- **Why exempt-and-discard in `rtl_check` but leave-in inside worktrees**: under isolation the
PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md:82:  prefixes (`.relay-scratch2`) still fail — otherwise the fix would just relocate the hole.
PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:2:title: "GH-184: committed scratch artifact .relay-scratch/probe_telemetry.json makes every real turn a tracked-file mutation"
PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:7:goal: nothing under the sanctioned-disposable .relay-scratch/ lane is ever tracked, so its by-design discard can never dirty a clone
PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:29:committed `.relay-scratch/probe_telemetry.json`. A shim driven through its real-turn path
PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:31:`.relay-scratch/` deletes the tracked file — a success-shaped exit plus a tracked-file mutation,
PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:38:.relay-scratch/probe_telemetry.json` after one real-turn run).
PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:42:1. `git rm .relay-scratch/probe_telemetry.json` — it is regenerable probe output; the lane is
PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:45:   .relay-scratch/` every run (empty required; mirrors gh1-adoption-guard's derived-from-source
PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:52:`git ls-files .relay-scratch/` returns nothing; gh184 guard green and registered; soak §3.5
PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:62:  "artifacts":     [ ".relay-scratch/probe_telemetry.json", "test/gh184-no-tracked-scratch.sh", "validate.sh" ],
PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:64:  "remediation":   { "source": "self#plan", "criteria": "no .relay-scratch/ content tracked; derived guard green; real-turn repro leaves git status clean" },
PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:65:  "lanes":         { "agy_safe": [ "test/gh184-no-tracked-scratch.sh" ], "orchestrator_only": [ ".relay-scratch/", "validate.sh" ] }
PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:71:One tracked scratch file (`.relay-scratch/probe_telemetry.json`) made every real agent turn a
PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md:74:nothing under `.relay-scratch/` is ever tracked — the guard matters more than the removal, because
skills/relay-xyz/SKILL.md:485:**Never hand-edit a clone while a driven turn is in flight there (GH-141).** `rtl_before()` snapshots
skills/relay-xyz/SKILL.md:488:self-escape** — so `rtl_check()` reverts it in the real tree. This is not a bug that can be fixed by
skills/relay-xyz/SKILL.md:492:content is copied to `.tick/orphan-backups/<utc>-<pid>/<path>` first, so a wrongly-caught edit is
PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:332:releases gen [--side-by-side]          # Phase 0: writes RELEASES.generated.md + drift report only
PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:406:   generator runs **side-by-side only** (`RELEASES.generated.md` + drift report; the real file
PROJECT/3-COMPLETED/GH-101-FEASIBILITY-STUDY-SCRIPT-RUNNER.md:32:- [x] Integration touchpoints named (`utils/py/consult.py`, `.relay-scratch/`, `relay-turn-lib`/`relay-drive`).
PROJECT/3-COMPLETED/GH-101-FEASIBILITY-STUDY-SCRIPT-RUNNER.md:39:- [x] Fail-closed containment: `consult.py` enforces throwaway worktree isolation, pre-creates `.relay-scratch/`, and refuses to run if sandbox engines are absent when programmatic mode is requested.
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:39:2. **Soft-Quarantine with Automated Reaper:** Untracked/ignored contents (`.relay-scratch/`) and swept full clones are moved into `.xyz/trash/<timestamp>-<name>/`. Each sweep run automatically reaps trash directories older than 72h (`find .xyz/trash/ -mtime +3 -delete`); immediate hard purge is available via `--purge-trash`.
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:40:3. **Strictly Read-Only In-Turn Hooks + Designated Inter-Phase Fetch:** Turn shims (`rtl_before()`) never call `git fetch`. The outer driver (`marathon_drive.py` / `relay_drive.py`) owns the single serialized `git fetch --no-tags --quiet origin development` at **startup** and **inter-phase boundaries**, ensuring local tracking refs stay fresh without mid-turn lock contention.
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:52:    P0[Phase 0: Local Gate Receipt Contract<br/>ci-local.sh & validate.sh write .xyz/receipts/SHA.json] --> P1[Phase 1: Early Rebase Drift Alert<br/>Driver fetch at phase boundary + rtl_before read-only check]
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:85:- **In-Turn Check (`rtl_before` in `relay-turn-lib.sh`):** Strictly read-only, non-network comparison:
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:114:     - Archives untracked/ignored files (`.relay-scratch/`) to `.xyz/trash/$(date +%Y%m%d-%H%M%S)-$(basename "$p")/`.
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-23.md:52:| [#184] GH-184 · committed scratch artifact .relay-scratch/probe_telemetry.json makes every real turn a tracked-file mutation | 1 | 1 | 1 | kernel | — | 7 | 2 |
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-23.md:104:- #2 GH-2 · test-suite run relocated an untracked file into .tick/orphan-backups/ — `not-ready`
PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md:2:title: "GH-2: test-suite run relocated an untracked file into .tick/orphan-backups/"
PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md:19:# GH-2 — untracked file relocated into .tick/orphan-backups/
PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md:34:`.tick/orphan-backups/`. Observed once, not yet reproduced. Same family as #1's sandbox
PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md:32:in the tree root; `rtl_check()` reverted them into `.tick/orphan-backups/` and failed the turn
PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md:44:   provision a per-turn scratch dir (`.relay-scratch/<turn>/`,
PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md:48:3. Soft-landing in `rtl_check()`: a root-level scratch-shaped file (matching a small extension
relay-automation/pi-turn.sh:169:rtl_before
relay-automation/claude-turn.sh:201:rtl_before
relay-automation/agy-turn.sh:215:rtl_before
relay-automation/README.md:47:should source `relay-turn-lib.sh` for the containment contract (`rtl_init`/`rtl_before`/
relay-automation/marathon-drive.sh:1078:# ── Step 2: commit the relay file (rtl_before needs a clean HEAD) ───────────
relay-automation/aider-turn.sh:267:rtl_before
relay-automation/relay-turn-lib.sh:28:#   rtl_before                                         — snapshot HEAD before the agent runs
relay-automation/relay-turn-lib.sh:185:# stay gitignored (see .gitignore's "relay-system/logs/" entry) — rtl_check already removes any file
relay-automation/relay-turn-lib.sh:749:  # named in rtl_turn_prompt, exempted by rtl_worktree_end/rtl_check, never copied back, and
relay-automation/relay-turn-lib.sh:751:  mkdir -p "$wt/.relay-scratch"
relay-automation/relay-turn-lib.sh:769:  # — exempt it the same way .tick/ is exempted below, mirroring rtl_check()'s $RTL_LOG_REL exemption
relay-automation/relay-turn-lib.sh:792:    case "$path" in .relay-scratch|.relay-scratch/|.relay-scratch/*) continue ;; esac
relay-automation/relay-turn-lib.sh:933:  local scratch_note=" Verification output (probe results, generated JSON, logs) goes under .relay-scratch/ — pre-created for you, exempt from containment, never copied back; scratch files anywhere else in the tree are reverted and FAIL your turn."
relay-automation/relay-turn-lib.sh:936:    prog_note=" Programmatic tool mode is enabled: diagnostic Python scripts may be executed via script_runner.py with output directed to .relay-scratch/."
relay-automation/relay-turn-lib.sh:942:rtl_before() {
relay-automation/relay-turn-lib.sh:943:  RTL_BEFORE_HEAD="$(git -C "$RTL_ROOT" rev-parse HEAD 2>/dev/null || echo none)"
relay-automation/relay-turn-lib.sh:946:  RTL_BEFORE=()
relay-automation/relay-turn-lib.sh:948:  while IFS= read -r -d '' fld; do RTL_BEFORE+=("$fld"); done \
relay-automation/relay-turn-lib.sh:962:  for b in ${RTL_BEFORE[@]+"${RTL_BEFORE[@]}"}; do [[ "$b" == "$e" ]] && return 0; done
relay-automation/relay-turn-lib.sh:968:# rtl_check CANNOT distinguish "a peer session's concurrent mid-turn edit" from "the agent's own
relay-automation/relay-turn-lib.sh:969:# off-lane self-escape": both produce byte-identical porcelain diffs, and rtl_before's snapshot is
relay-automation/relay-turn-lib.sh:977:# rtl_enforce already uses for the moved-HEAD case. Backups land under .tick/, which rtl_check
relay-automation/relay-turn-lib.sh:982:  : "${RTL_ORPHAN_BACKUP:="$RTL_ROOT/.tick/orphan-backups/$(date -u +%Y%m%dT%H%M%SZ)-$$"}"
relay-automation/relay-turn-lib.sh:987:  rtl_log_always "rtl_check: orphan-backup path=$p dest=$RTL_ORPHAN_BACKUP"
relay-automation/relay-turn-lib.sh:990:rtl_check() {  # <path> — reads RTL_ROOT/RTL_LOG_REL/RTL_TOOL, sets RTL_VIOLATION
relay-automation/relay-turn-lib.sh:1000:  case "$p" in .relay-scratch|.relay-scratch/|.relay-scratch/*)
relay-automation/relay-turn-lib.sh:1001:    rm -rf "${RTL_ROOT:?}/.relay-scratch"
relay-automation/relay-turn-lib.sh:1015:    rtl_trace "rtl_check: ALLOW path=$p"
relay-automation/relay-turn-lib.sh:1019:  rtl_log_always "rtl_check: OFF-ALLOWLIST path=$p tool=$RTL_TOOL — reverting"
relay-automation/relay-turn-lib.sh:1027:# are shared by both call sites below — rtl_check_uncited_findings's per-line downgrade, and
relay-automation/relay-turn-lib.sh:1059:rtl_check_uncited_findings() {  # <relay_file_path> — rewrites the file in place
relay-automation/relay-turn-lib.sh:1171:  if [[ "$(git -C "$RTL_ROOT" rev-parse HEAD 2>/dev/null || echo none)" != "$RTL_BEFORE_HEAD" ]]; then
relay-automation/relay-turn-lib.sh:1189:      git -C "$RTL_ROOT" reset --hard "$RTL_BEFORE_HEAD" >/dev/null 2>&1 || true
relay-automation/relay-turn-lib.sh:1190:      printf '%s-turn: %s committed during its turn (forbidden) — reset to %s (prior HEAD saved to refs/relay-orphan/), failing\n' "$RTL_TOOL" "$agent" "${RTL_BEFORE_HEAD:0:8}" >&2
relay-automation/relay-turn-lib.sh:1191:      rtl_log_always "rtl_enforce: HEAD_MOVED branch=in-root-reset agent=$agent reset_to=${RTL_BEFORE_HEAD:0:8}"
relay-automation/relay-turn-lib.sh:1216:        rtl_check "$path"; rtl_check "$src"
relay-automation/relay-turn-lib.sh:1220:        rtl_check "$path"
relay-automation/relay-turn-lib.sh:1225:  # it — porcelain omits ignored paths, so the per-path rtl_check discard above never fires and
relay-automation/relay-turn-lib.sh:1227:  [[ -d "${RTL_ROOT:?}/.relay-scratch" ]] && rm -rf "${RTL_ROOT:?}/.relay-scratch"
relay-automation/relay-turn-lib.sh:1234:    rtl_check_uncited_findings "$RELAY_FILE"
relay-automation/relay-turn-lib.sh:1372:  if [[ -n "$task" && -x "$_tickbin" && -n "${RTL_BEFORE_HEAD:-}" ]]; then
relay-automation/relay-turn-lib.sh:1375:    if [[ "$_newhead" != none && "$_newhead" != "$RTL_BEFORE_HEAD" ]]; then
relay-automation/relay-turn-lib.sh:1378:        _psha="$(git -C "$RTL_ROOT" rev-parse "$RTL_BEFORE_HEAD:$_surf" 2>/dev/null || true)"
relay-automation/relay-turn-lib.sh:1381:        _dl="$(git -C "$RTL_ROOT" diff --numstat "$RTL_BEFORE_HEAD" "$_newhead" -- "$_surf" 2>/dev/null \
relay-automation/relay-turn-lib.sh:1393:  # earlier in-loop cleanup (rtl_check drops the shim's own transcript log when it happens to land
relay-automation/relay-turn-lib.sh:1399:  # ignored paths, so it only flags the genuine stray case rtl_check already handles mid-loop (an
relay-automation/codex-turn.sh:144:rtl_before
relay-automation/hooks/gh527-destructive-git-guard.sh:23:# already chose for this same problem — rtl_check copies an off-allowlist edit
relay-automation/hooks/gh527-destructive-git-guard.sh:24:# into .tick/orphan-backups/ before reverting it (GH-141), precisely so a
relay-automation/hooks/gh527-destructive-git-guard.sh:154:# self-defeating. `.tick/orphan-backups/` is the GH-141 precedent and is correct for
relay-automation/hooks/gh527-destructive-git-guard.sh:169:    dest = os.path.join(root, ".tick", "orphan-backups", leaf)
relay-automation/hooks/gh527-destructive-git-guard.sh:196:# what a reader of .tick/orphan-backups/ expects to see.
relay-automation/smallcode-turn.sh:52:rtl_before
utils/py/harness_app.py:25:    return os.path.join(root, "harnesses.db")
utils/py/harness_app.py:30:    return os.path.join(root, "harnesses.sql")
utils/py/harness_app.py:33:def get_generated_md_path(repo_root: Optional[str] = None) -> str:
utils/py/harness_app.py:35:    return os.path.join(root, "HARNESS-MODELS-REGISTRY.generated.md")
utils/py/harness_app.py:202:    """Render canonical HARNESS-MODELS-REGISTRY.generated.md view from database."""
utils/py/harness_app.py:216:        "<!-- Auto-generated from harnesses.db by utils/py/harness_app.py — DO NOT HAND-EDIT -->",
utils/py/harness_app.py:265:    gen_md = get_generated_md_path(root)
utils/py/harness_app.py:292:    subparsers.add_parser("init", help="Initialize and seed harnesses.db")
utils/py/harness_app.py:295:    subparsers.add_parser("dump", help="Dump database to harnesses.sql")
utils/py/harness_app.py:298:    subparsers.add_parser("gen", help="Generate HARNESS-MODELS-REGISTRY.generated.md")
utils/py/harness_app.py:342:    md_p = get_generated_md_path(root)
utils/py/workspace_manager.py:274:        scratch_dir = os.path.join(p, ".relay-scratch")
utils/py/workspace_manager.py:278:                shutil.copytree(scratch_dir, os.path.join(dest_trash, ".relay-scratch"), dirs_exist_ok=True)
utils/py/rtl.py:666:        res = self._run_rtl("rtl_before", capture=False)
utils/py/relay_drive.py:513:        reason_file = os.path.join(root_dir, ".relay-scratch", "escalation-reason")
utils/py/marathon_drive.py:2224:                    if not in_phases and not p.startswith(".tick/") and not p.startswith(".xyz/") and not p.startswith(".relay-scratch/"):
utils/py/marathon_drive.py:2611:        reason_file = os.path.join(xyz_harness, ".relay-scratch", "escalation-reason")
utils/py/marathon_drive.py:2779:        reason_file = os.path.join(xyz_harness, ".relay-scratch", "escalation-reason")
utils/py/agy-turn.py:75:    # never seen by `rtl_check` (which inspects RTL_ROOT, a different repo), and is never reverted.
utils/py/harness_turn_logger.py:18:    """Context manager for transparently logging turn execution into harnesses.db."""
utils/py/harness_turn_logger.py:104:        """Record post-turn AI / reviewer evaluation into harnesses.db."""
utils/py/consult.py:456:            "programmatically via script_runner.py with output directed to .relay-scratch/ inside the isolation worktree."
utils/py/consult.py:497:            os.makedirs(os.path.join(wt, ".relay-scratch"), exist_ok=True)
utils/py/consult.py:504:            base_env["RELAY_SCRATCH_DIR"] = os.path.join(wt, ".relay-scratch")
utils/py/releases_app.py:16:writes RELEASES.generated.md plus a drift report. If a code path here can reach RELEASES.md for
utils/py/releases_app.py:30:  RELEASES.generated.md          side-by-side generated view (Phase 0; gen only)
utils/py/releases_app.py:31:  RELEASES.generated.md.drift    drift report: generated view vs the real RELEASES.md (gen only)
utils/py/releases_app.py:86:GEN_NAME = "RELEASES.generated.md"
utils/py/releases_app.py:87:DRIFT_NAME = "RELEASES.generated.md.drift"

exec
/bin/zsh -lc "nl -ba .gitignore | sed -n '1,95p'; nl -ba skills/relay-xyz/SKILL.md | sed -n '475,502p'; nl -ba relay-automation/relay-turn-lib.sh | sed -n '942,1025p'; nl -ba relay-automation/relay-turn-lib.sh | sed -n '1210,1232p'; nl -ba utils/py/workspace_manager.py | sed -n '220,315p'; nl -ba PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md | sed -n '1,140p'; nl -ba PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md | sed -n '42,58p'; nl -ba utils/py/harness_app.py | sed -n '1,45p'; nl -ba utils/py/harness_app.py | sed -n '250,355p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-17781-brvet5yb
 succeeded in 0ms:
     1	.tick/
     2	node_modules/
     3	.vscode/
     4	# GH-480: tools/vscode-cockpit ships its own F5 debug launch config as part of the extension.
     5	!tools/vscode-cockpit/.vscode/
     6	!tools/vscode-cockpit/.vscode/*.json
     7	.claude/settings.local.json
     8	.claude/scheduled_tasks.lock
     9	.DS_Store
    10	**/.DS_Store
    11	PROJECT/PDDA-ACTIVITY.jsonl
    12	relay-system/2026-06-21/shakedown-lib.sh
    13	/temp/
    14	.pdda-gh-state.tsv
    15	# GH-75 / GH-96: XYZ.json is the local newest-first completion log; XYZ.heartbeat.json is the mutable
    16	# in-flight companion marker. Both are machine-specific and kept out of git to avoid churn.
    17	XYZ.json
    18	XYZ.json.lock/
    19	XYZ.heartbeat.json
    20	# GH-78: hourly doc-preflight telemetry — per-machine, per-run edit/warn logs; gitignored to avoid churn.
    21	utils/telemetry/preflight-log/
    22	# swarm-preflight packet output — ephemeral per-run artifact (sleuth-app already gitignores this).
    23	relay-system/preflight/
    24	# GH-161: persistent CODEX_LOG/AGY_LOG default (rtl_default_log in relay-turn-lib.sh). MUST stay
    25	# ignored — rtl_check already deletes any file landing in the tracked tree that matches the shim's
    26	# own transcript path, so an un-ignored log here would be wiped at the end of every single turn.
    27	relay-system/logs/
    28	# Hourly HQ marathon scan (utils/hq/hourly-global-scan.sh) — a live, machine-local rolling snapshot
    29	# overwritten every run; committing it each hour would be pure churn with no historical value.
    30	PROJECT/2-WORKING/GLOBAL-HQ-MARATHON.md
    31	# Aider aux files: a MANUAL (non-shim) aider run drops .aider.chat.history.md / .aider.input.history /
    32	# .aider.llm.history into the tree. The aider-turn.sh shim already redirects these via AIDER_AUX_DIR;
    33	# this guards ad-hoc runs so they can't re-leak as untracked noise.
    34	.aider*
    35	# GH-112 Python layer: bytecode caches from pytest / XYZ_PYTHON=1 runs.
    36	__pycache__/
    37	*.pyc
    38	# codebase-memory MCP index — a per-device local tool cache (like .tick/); never committed.
    39	.codebase-memory/
    40	
    41	# Aider Studio (auto-added)
    42	REPO_MAP.md
    43	
    44	# ask-self RAG — kept PER-USER / PER-DEVICE, not committed to the shared repo.
    45	# The whole integration layer is local: teammates opt in by installing ask-self
    46	# themselves (see ask-self's ASK_SELF_INTEGRATION.md) rather than inheriting it here.
    47	/ask_self/
    48	/scripts/ask-self-ingest.sh
    49	/scripts/ask-self-query.sh
    50	/.claude/commands/reingest.md
    51	/.claude/commands/ask_self.md
    52	# Local working index lives under temp/rag/ (already ignored via /temp/); these lines
    53	# also catch the per-DB sidecars anywhere they land.
    54	temp/rag/
    55	temp/ask-self-rag.env
    56	*__embed_cache.sqlite
    57	*__events.jsonl
    58	# ask-self generated architecture doc (falls back to ASK_SELF.md; our ARCHITECTURE.md is hand-owned).
    59	ASK_SELF.md
    60	ARCHITECTURE-BAK.md
    61	
    62	# Sentinel Tier 1 debug capture — local only, never committed.
    63	debug.log
    64	/BTW
    65	
    66	# Vendored per-repo harness copy (xyz-vendor.sh) — machine-local, never committed.
    67	.xyz/
    68	
    69	# GH-509: per-commit local gate evidence — machine-local, self-reported, never committed.
    70	.gate-evidence/
    71	
    72	# GH-32 Phase 0: side-by-side generator output is regenerable proof, never committed
    73	RELEASES.generated.md
    74	RELEASES.generated.md.drift
    75	# `check --rebuild` displaces the old DB to this path, and utils/releases-merge-resolve.sh tells the
    76	# operator it is "untracked and safe to delete". It was not actually ignored, so a `git add -A`
    77	# during a merge resolution would have committed a ~200KB stale binary copy of the ledger — the one
    78	# artifact guaranteed to disagree with the dump (GH-57 probe, 2026-08-19).
    79	releases.db.bak
    80	
    81	# GH-38: agent2agent lock files are flock mutexes, deliberately never unlinked (unlinking is what
    82	# reintroduced the steal race). They are per-machine runtime state, never discussion content.
    83	relay-system/**/.*.lock
    84	# Doorbell liveness markers — per-agent, mtime-only, regenerated by every watch.
    85	relay-system/**/*.watch.agent*
    86	
    87	# Audit probe output when --out is pointed at the worktree (default is a scratch dir).
    88	audit/out/
   475	  (`nudge-cross-model` = turn belongs to an agent not in `--claude-agents`; relay it as a manual nudge).
   476	
   477	## Safety boundary (what the shim guarantees)
   478	
   479	The shim is the containment contract, so an unattended turn can't run away: **path-allowlist**
   480	(anything off `RELAY_FILE` + `ALLOW_PATHS` is reverted, exit 6), **commit-bypass guard** (if the CLI
   481	commits mid-turn, the shim resets and re-commits file-scoped), and **no push** (turns commit locally
   482	only — `git push` yourself when ready). `.tick/` is gitignored and per-device, so this is single-clone
   483	coordination, not cross-machine.
   484	
   485	**Never hand-edit a clone while a driven turn is in flight there (GH-141).** `rtl_before()` snapshots
   486	the dirty set once, at turn start. A second session's edit landing *during* the turn window produces a
   487	porcelain entry with no match in that snapshot — **byte-identical to the agent's own off-lane
   488	self-escape** — so `rtl_check()` reverts it in the real tree. This is not a bug that can be fixed by
   489	detection: preserving newly-dirty non-allowlisted paths would disable the documented GH-22
   490	self-escape backstop. Observed live twice (2026-07-05, 2026-07-18); the second incident silently
   491	deleted an untracked doc and reverted a tracked one mid-session. Since 2026-07-18 the pre-revert
   492	content is copied to `.tick/orphan-backups/<utc>-<pid>/<path>` first, so a wrongly-caught edit is
   493	**recoverable** — but the revert still happens. Wait for the turn, or work in a separate worktree.
   494	
   495	**Worktree isolation is ON by default for driven runs.** `relay-drive.sh` exports
   496	`RELAY_WORKTREE_ISOLATION=1`, so each turn-taker runs in a throwaway `git worktree` of `ROOT@HEAD` —
   497	an off-task model's stray *creations/renames* (not just tracked edits) can't reach the real tree,
   498	closing the gap where the allowlist only reverted named tracked files. Opt out per run with
   499	`RELAY_WORKTREE_ISOLATION=0`; direct/attended shim use keeps the leaf default OFF. Also: `--agent-cmd`
   500	runs a bare executable path directly, so an **absolute path with spaces** (a clone under
   501	`…/GH Repos/…`) is safe — no quoting needed.
   502	
   942	rtl_before() {
   943	  RTL_BEFORE_HEAD="$(git -C "$RTL_ROOT" rev-parse HEAD 2>/dev/null || echo none)"
   944	  # Snapshot the PRE-turn dirty set (raw -z porcelain fields) so enforcement touches only the
   945	  # agent's OWN changes — never pre-existing ambient WIP in the host repo (field report MBP16 [1]).
   946	  RTL_BEFORE=()
   947	  local fld
   948	  while IFS= read -r -d '' fld; do RTL_BEFORE+=("$fld"); done \
   949	    < <(git -C "$RTL_ROOT" status --porcelain -z 2>/dev/null)
   950	
   951	  # GH-124 QW4: Early Rebase Drift Alert (Option A: zero-lock local tracking ref inspection)
   952	  local drift_count
   953	  drift_count="$(git -C "${RTL_ROOT:-.}" rev-list --count HEAD..refs/remotes/origin/development 2>/dev/null || echo 0)"
   954	  if [ "${drift_count:-0}" -ge 3 ]; then
   955	    printf '%s-turn: ⚠️  NOTICE: tracking ref origin/development is %d commits ahead. Consider rebasing between phases.\n' \
   956	      "${RTL_TOOL:-relay}" "$drift_count" >&2
   957	  fi
   958	}
   959	
   960	rtl_was_dirty_before() {  # <porcelain-entry> — true if this exact status+path was dirty pre-turn
   961	  local e="$1" b
   962	  for b in ${RTL_BEFORE[@]+"${RTL_BEFORE[@]}"}; do [[ "$b" == "$e" ]] && return 0; done
   963	  return 1
   964	}
   965	
   966	# GH-141 — recoverability-only mitigation for the concurrent peer-edit race.
   967	#
   968	# rtl_check CANNOT distinguish "a peer session's concurrent mid-turn edit" from "the agent's own
   969	# off-lane self-escape": both produce byte-identical porcelain diffs, and rtl_before's snapshot is
   970	# taken once at turn start, so anything that turns dirty DURING the turn window looks identical.
   971	# Any fix of the shape "don't revert a newly-dirty non-allowlisted path" would silently disable
   972	# rtl_enforce's documented backstop against the already-observed GH-22 self-escape vector.
   973	#
   974	# So the revert DECISION IS DELIBERATELY UNCHANGED. This only copies the pre-revert content aside
   975	# first, turning "not recoverable in general" (GH-141's live 2026-07-05 incident, and a second
   976	# occurrence on 2026-07-18) into a recoverable one. Mirrors the refs/relay-orphan/<sha> pattern
   977	# rtl_enforce already uses for the moved-HEAD case. Backups land under .tick/, which rtl_check
   978	# exempts intrinsically, so a backup can never itself be flagged as off-lane.
   979	rtl_orphan_backup() {  # <path> — copy pre-revert content aside; must never block the revert
   980	  local p="$1" dest
   981	  [[ -n "$p" && -e "$RTL_ROOT/$p" ]] || return 0
   982	  : "${RTL_ORPHAN_BACKUP:="$RTL_ROOT/.tick/orphan-backups/$(date -u +%Y%m%dT%H%M%SZ)-$$"}"
   983	  dest="$RTL_ORPHAN_BACKUP/$p"
   984	  mkdir -p "$(dirname "$dest")" 2>/dev/null || return 0
   985	  cp -R "$RTL_ROOT/$p" "$dest" 2>/dev/null || return 0
   986	  printf '%s-turn: pre-revert copy of %s saved under %s\n' "$RTL_TOOL" "$p" "$RTL_ORPHAN_BACKUP" >&2
   987	  rtl_log_always "rtl_check: orphan-backup path=$p dest=$RTL_ORPHAN_BACKUP"
   988	}
   989	
   990	rtl_check() {  # <path> — reads RTL_ROOT/RTL_LOG_REL/RTL_TOOL, sets RTL_VIOLATION
   991	  local p="$1"
   992	  [[ -n "$p" ]] || return 0
   993	  # tick's own state dir is coordination state the turn legitimately writes — exempt it intrinsically,
   994	  # independent of whether the HOST repo gitignores .tick (field report MBP16 [2]).
   995	  case "$p" in .tick/*|.tick) return 0 ;; esac
   996	  # GH-91: same sanction on the non-worktree path, but here the dir lives in RTL_ROOT itself —
   997	  # exempt AND discard (the transcript-log drop below is the precedent, not the .tick leave-in):
   998	  # scratch is consumed by the turn that wrote it and must neither ride into a commit nor linger
   999	  # in the tree. ${RTL_ROOT:?} because rm -rf on an empty-prefix path would target /. — GH-567.
  1000	  case "$p" in .relay-scratch|.relay-scratch/|.relay-scratch/*)
  1001	    rm -rf "${RTL_ROOT:?}/.relay-scratch"
  1002	    return 0
  1003	  ;; esac
  1004	  # the shim's own transcript log, if it lands in the tree, is not an agent edit — drop it, don't flag
  1005	  if [[ -n "$RTL_LOG_REL" && "$p" == "$RTL_LOG_REL" ]]; then rm -f "$RTL_ROOT/$p"; return 0; fi
  1006	  # GH-261: the exact-match exemption above only fires for the ONE transcript file itself; when the
  1007	  # harness's own transcript-log directory is entirely new/untracked, git collapses it to one line
  1008	  # (e.g. "relay-system/"), which never equals $RTL_LOG_REL's deeper file path. Mirrors
  1009	  # rtl_worktree_end's GH-266 fix, applied here to the non-worktree containment path too.
  1010	  if [[ -z "${XYZ_ARCHIVE_ROOT:-}" ]]; then
  1011	    local _rtl_log_top; _rtl_log_top="$(basename "$(rtl_transcript_root "$RTL_ROOT")")"
  1012	    case "$p" in "$_rtl_log_top"|"$_rtl_log_top"/|"$_rtl_log_top"/*) return 0 ;; esac
  1013	  fi
  1014	  if rtl_in_allow "$p"; then
  1015	    rtl_trace "rtl_check: ALLOW path=$p"
  1016	    return 0
  1017	  fi
  1018	  printf '%s-turn: OFF-ALLOWLIST change: %s — reverting\n' "$RTL_TOOL" "$p" >&2
  1019	  rtl_log_always "rtl_check: OFF-ALLOWLIST path=$p tool=$RTL_TOOL — reverting"
  1020	  rtl_offlane_hint "$p"    # GH-90: name a file-vs-directory lane-spec mistake before the revert
  1021	  rtl_orphan_backup "$p"   # GH-141: recoverable copy BEFORE the destructive revert below
  1022	  git -C "$RTL_ROOT" checkout -- "$p" 2>/dev/null || rm -rf "$RTL_ROOT/${p%/}"
  1023	  RTL_VIOLATION=1
  1024	}
  1025	
  1210	      R*|C*)
  1211	        IFS= read -r -d '' src || true
  1212	        # A rename counts as pre-existing only if BOTH dest and src were dirty before — else enforce
  1213	        # both paths. Prevents a staged rename whose dest matches an ambient rename's dest from hiding
  1214	        # a clean file's move/deletion via the src field (Gemini review 2026-06-15, rename-hijack).
  1215	        if rtl_was_dirty_before "$entry" && rtl_was_dirty_before "$src"; then continue; fi
  1216	        rtl_check "$path"; rtl_check "$src"
  1217	        ;;
  1218	      *)
  1219	        rtl_was_dirty_before "$entry" && continue
  1220	        rtl_check "$path"
  1221	        ;;
  1222	    esac
  1223	  done < <(git -C "$RTL_ROOT" status --porcelain -z)
  1224	  # GH-91 (PR #93 review): scratch must not survive the turn EVEN WHEN the host repo gitignores
  1225	  # it — porcelain omits ignored paths, so the per-path rtl_check discard above never fires and
  1226	  # the dir lingered in ROOT forever. Sweep unconditionally, independent of git visibility.
  1227	  [[ -d "${RTL_ROOT:?}/.relay-scratch" ]] && rm -rf "${RTL_ROOT:?}/.relay-scratch"
  1228	  rtl_trace "rtl_enforce: RTL_VIOLATION=$RTL_VIOLATION"
  1229	  ((RTL_VIOLATION == 0)) || { printf '%s-turn: off-lane edits reverted; failing the turn\n' "$RTL_TOOL" >&2; rtl_log_always "rtl_enforce: VIOLATION off-lane edits reverted; failing the turn"; exit 6; }
  1230	  # GH-173 B3: downgrade any uncited [Pass]/verified Reviewer finding BEFORE staging, so the fix lands
  1231	  # in the SAME commit as the turn instead of needing a second one. Reviewer-only (Producer findings
  1232	  # aren't graded by this template); RTL_WAS_REVIEWER_TURN was captured in rtl_init, before NEXT flipped.
   220	    # Discover candidate paths from manifest + git worktree list
   221	    candidates = {}
   222	    for entry in load_manifest(repo_root):
   223	        p = entry.get("path")
   224	        if p and os.path.exists(p):
   225	            candidates[os.path.abspath(p)] = entry.get("type", "unknown")
   226	
   227	    # Also discover linked worktrees via git worktree list
   228	    wt_out = subprocess.run(["git", "-C", repo_root, "worktree", "list", "--porcelain"],
   229	                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
   230	    if wt_out.returncode == 0:
   231	        for line in wt_out.stdout.splitlines():
   232	            if line.startswith("worktree "):
   233	                wt_path = line[len("worktree "):].strip()
   234	                abs_wt = os.path.abspath(wt_path)
   235	                if abs_wt not in candidates:
   236	                    candidates[abs_wt] = "worktree"
   237	
   238	    if not candidates:
   239	        print("workspace-sweep: no candidate ephemeral workspaces found.")
   240	        return
   241	
   242	    print(f"workspace-sweep: auditing {len(candidates)} candidate workspace(s)...")
   243	    print("-" * 80)
   244	    print(f"{'TYPE':<10} {'STATUS':<25} {'PATH'}")
   245	    print("-" * 80)
   246	
   247	    to_remove = []
   248	    for p, _ in candidates.items():
   249	        is_safe, ws_type, branch, reason = evaluate_workspace_safety(repo_root, p)
   250	        status_str = "ELIGIBLE" if is_safe else f"REFUSED ({reason})"
   251	        print(f"{ws_type:<10} {status_str:<25} {p}")
   252	        if is_safe:
   253	            to_remove.append((p, ws_type, branch))
   254	
   255	    print("-" * 80)
   256	    if not to_remove:
   257	        print("workspace-sweep: 0 workspaces eligible for sweep.")
   258	        return
   259	
   260	    if not execute:
   261	        print(f"workspace-sweep: DRY-RUN — {len(to_remove)} workspace(s) eligible. Pass --execute to remove.")
   262	        return
   263	
   264	    # Execute removal
   265	    trash_dir = get_trash_dir(repo_root)
   266	    os.makedirs(trash_dir, exist_ok=True)
   267	    timestamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
   268	
   269	    for p, ws_type, _ in to_remove:
   270	        # Soft-quarantine untracked / scratch files
   271	        base_name = os.path.basename(os.path.normpath(p))
   272	        dest_trash = os.path.join(trash_dir, f"{timestamp}-{base_name}")
   273	        
   274	        scratch_dir = os.path.join(p, ".relay-scratch")
   275	        if os.path.exists(scratch_dir):
   276	            try:
   277	                os.makedirs(dest_trash, exist_ok=True)
   278	                shutil.copytree(scratch_dir, os.path.join(dest_trash, ".relay-scratch"), dirs_exist_ok=True)
   279	            except Exception:
   280	                pass
   281	
   282	        if ws_type == "worktree":
   283	            res = subprocess.run(["git", "-C", repo_root, "worktree", "remove", p],
   284	                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
   285	            if res.returncode == 0:
   286	                print(f"workspace-sweep: removed linked worktree {p}")
   287	                deregister_workspace(repo_root, p)
   288	            else:
   289	                print(f"workspace-sweep: failed to remove worktree {p}: {res.stderr.strip()}", file=sys.stderr)
   290	        else:
   291	            # Full clone: move entire directory into trash
   292	            try:
   293	                shutil.move(p, dest_trash)
   294	                print(f"workspace-sweep: moved clone to quarantine {dest_trash}")
   295	                deregister_workspace(repo_root, p)
   296	            except Exception as e:
   297	                print(f"workspace-sweep: failed to quarantine clone {p}: {e}", file=sys.stderr)
   298	
   299	
   300	def main():
   301	    parser = argparse.ArgumentParser(description="Manage and sweep ephemeral workspaces.")
   302	    subparsers = parser.add_subparsers(dest="action", required=True)
   303	
   304	    reg_p = subparsers.add_parser("register")
   305	    reg_p.add_argument("--repo", default=".")
   306	    reg_p.add_argument("--path", required=True)
   307	    reg_p.add_argument("--type", choices=["worktree", "clone"], required=True)
   308	    reg_p.add_argument("--branch")
   309	    reg_p.add_argument("--pid", type=int)
   310	
   311	    dereg_p = subparsers.add_parser("deregister")
   312	    dereg_p.add_argument("--repo", default=".")
   313	    dereg_p.add_argument("--path", required=True)
   314	
   315	    sweep_p = subparsers.add_parser("sweep")
     1	---
     2	gh_issue: 124
     3	source: https://github.com/HiQS-Suite/XYZ-forge/issues/124
     4	title: "feat(harness): eliminate end-of-day closeout friction — automated phase QA receipts, auto-PR creation, and clone lifecycle hygiene"
     5	status: Active (2-WORKING as of 2026-08-21)
     6	created: 2026-08-21
     7	updated: 2026-08-21
     8	owner: noelsaw1
     9	doc_type: plan
    10	rating: "pri/sev/appeal/effort 85/60/90/40 · calc 275"
    11	goal: >
    12	  Eliminate 50+ minutes of daily end-of-day closeout friction across marathon and ad-hoc sessions:
    13	  add machine-checkable local gate receipts, driver-refreshed early drift alerts, safe manifest-bounded
    14	  workspace garbage collection with soft quarantine, hardened one-shot PR creation, and post-gate
    15	  in-flight QA attestation comments.
    16	---
    17	
    18	# GH-124: End-of-Day Closeout Automation & Lifecycle Hygiene (Plan)
    19	
    20	## Status
    21	
    22	| What was just completed | What's next |
    23	|---|---|
    24	| **Plan Finalized (2026-08-21):** Adjudicated across Ox-Alpha review, Agent2Agent #658731 consensus, and Fable 5 hardening. | Implement Phase 0 (Gate Receipt Contract) & Phase 1 (Drift Alert). |
    25	
    26	---
    27	
    28	## Canonical Implementation Specification (Finalized & Hardened Plan)
    29	
    30	This document establishes the **authoritative, production-grade implementation specification and safety contracts** for eliminating end-of-day closeout friction, incorporating all feedback from the `openrouter/stealth/ox-alpha` relay review, Agent2Agent session [#658731](https://github.com/HiQS-Suite/XYZ-forge/issues/124#issuecomment-5373503236), and Fable 5's architectural verification.
    31	
    32	---
    33	
    34	### Core Operating Principles & Invariants
    35	
    36	1. **Guilty-Until-Proven-Pushed (Zero Data Loss across all refs):**
    37	   - **Worktrees:** Must verify `git merge-base --is-ancestor HEAD origin/<branch>`.
    38	   - **Full Clones:** Must verify that **every** local branch in the clone is pushed (`git for-each-ref refs/heads/` ancestor check) AND `git stash list` is empty.
    39	2. **Soft-Quarantine with Automated Reaper:** Untracked/ignored contents (`.relay-scratch/`) and swept full clones are moved into `.xyz/trash/<timestamp>-<name>/`. Each sweep run automatically reaps trash directories older than 72h (`find .xyz/trash/ -mtime +3 -delete`); immediate hard purge is available via `--purge-trash`.
    40	3. **Strictly Read-Only In-Turn Hooks + Designated Inter-Phase Fetch:** Turn shims (`rtl_before()`) never call `git fetch`. The outer driver (`marathon_drive.py` / `relay_drive.py`) owns the single serialized `git fetch --no-tags --quiet origin development` at **startup** and **inter-phase boundaries**, ensuring local tracking refs stay fresh without mid-turn lock contention.
    41	4. **On-Disk Local Gate Receipt Contract:** `ci-local.sh` and `validate.sh` write a machine-checkable receipt artifact to `.xyz/receipts/<SHA>.json` upon green exit. Auto-PR consumes this deterministic local file before opening PRs.
    42	5. **Registered Workspace Lifecycle:** `rtl_worktree_begin` and clone creation tools write entries into `.xyz/workspaces.json`. Sweep bounds itself to this manifest and safely cross-checks `git worktree list --porcelain`.
    43	6. **Single Source of Truth (No Duplicate Twins):** Reject creating `utils/py/closeout.py`; harden the existing `relay-automation/marathon-closeout.sh` path directly.
    44	7. **Preserve Shared Tooling Schemas:** Issue titles are immutable across the automation lifecycle (no title mutations). QA attestation is emitted via post-gate structured issue comments with machine-checkable test receipts.
    45	
    46	---
    47	
    48	### Phased Implementation Roadmap
    49	
    50	```mermaid
    51	graph TD
    52	    P0[Phase 0: Local Gate Receipt Contract<br/>ci-local.sh & validate.sh write .xyz/receipts/SHA.json] --> P1[Phase 1: Early Rebase Drift Alert<br/>Driver fetch at phase boundary + rtl_before read-only check]
    53	    P0 --> P3[Phase 3: Harden marathon-closeout.sh<br/>Purge git add -A + consume local receipt + lock --base]
    54	    P2[Phase 2: Workspace Sweep & Lifecycle Manifest<br/>rtl_worktree_begin registration + all-branch ancestor check + .xyz/trash/ reaper]
    55	    P0 --> P4[Phase 4: Driver-Owned QA Receipts<br/>Post-gate issue comments from local receipt]
    56	```
    57	
    58	---
    59	
    60	### Phase 0: Local Gate Receipt Contract (Prerequisite for PR & QA)
    61	- **Location:** `ci-local.sh` and `validate.sh`
    62	- **Specification:** When a test suite passes (exit 0), write an on-disk JSON receipt:
    63	  - **Path:** `.xyz/receipts/<HEAD_SHA>.json`
    64	  - **Schema:**
    65	    ```json
    66	    {
    67	      "sha": "<HEAD_COMMIT_SHA>",
    68	      "gate": "ci-local.sh",
    69	      "mode": "sequential",
    70	      "exit_code": 0,
    71	      "passed": 230,
    72	      "total": 230,
    73	      "timestamp": "2026-08-21T18:00:00Z"
    74	    }
    75	    ```
    76	- **Durability:** Committed into evidence or preserved under `.xyz/` so downstream consumers (`marathon-closeout.sh`, issue commenter) read an authoritative local proof of qualification.
    77	
    78	---
    79	
    80	### Phase 1: Early Rebase Drift Alert (`QW4` — Driver-Refreshed Local Cache)
    81	- **Designated Fetch Point:** The outer driver (`marathon_drive.py` / `relay_drive.py`) runs a single serialized background fetch at startup and **between phase handoffs**:
    82	  ```bash
    83	  GIT_OPTIONAL_LOCKS=0 timeout 5s git fetch --no-tags --quiet origin development 2>/dev/null || true
    84	  ```
    85	- **In-Turn Check (`rtl_before` in `relay-turn-lib.sh`):** Strictly read-only, non-network comparison:
    86	  ```bash
    87	  local drift_count
    88	  drift_count="$(git rev-list --count HEAD..refs/remotes/origin/development 2>/dev/null || echo 0)"
    89	  if [ "$drift_count" -ge 3 ]; then
    90	    echo "⚠️  NOTICE: tracking ref origin/development is $drift_count commits ahead. Consider rebasing between phases."
    91	  fi
    92	  ```
    93	
    94	---
    95	
    96	### Phase 2: Ephemeral Workspace Garbage Collector & Lifecycle Manifest (`QW3`)
    97	- **Registration Point:**
    98	  - `rtl_worktree_begin()` (in `relay-turn-lib.sh`) and clone creation helpers append newly created workspaces to `.xyz/workspaces.json` (`{path, type, branch, created_at, pid}`).
    99	- **Location:** `utils/harness/workspace-sweep.sh` (and `xyz workspace sweep`)
   100	- **Safety Predicate Chain:**
   101	  1. **Candidate Resolution:** Evaluates entries in `.xyz/workspaces.json` and registered `git worktree list --porcelain`.
   102	  2. **Canonical Path Refusals:** Hard refusal if target resolves to primary repo root, active CWD, a symlink, or an unmanaged parent directory.
   103	  3. **Porcelain Cleanliness:** `[ -z "$(git -C "$p" status --porcelain)" ]` (zero uncommitted tracked changes).
   104	  4. **Multi-Branch & Stash Verification (Full Clones):**
   105	     ```bash
   106	     # Check ALL local branches are pushed to remote
   107	     for ref in $(git -C "$p" for-each-ref --format='%(refname:short)' refs/heads/); do
   108	       git -C "$p" merge-base --is-ancestor "$ref" "origin/$ref" || die "Unpushed branch $ref in clone $p"
   109	     done
   110	     # Check no stashes exist
   111	     [ -z "$(git -C "$p" stash list)" ] || die "Unsaved git stash in clone $p"
   112	     ```
   113	  5. **Ignored-Content Quarantine & Deletion:**
   114	     - Archives untracked/ignored files (`.relay-scratch/`) to `.xyz/trash/$(date +%Y%m%d-%H%M%S)-$(basename "$p")/`.
   115	     - **Linked Worktree:** Runs `git worktree remove "$p"` from primary repo context.
   116	     - **Full Clone:** Moves directory into `.xyz/trash/`.
   117	  6. **Automated Trash Reaper:** Automatically purges `.xyz/trash/` entries older than 72 hours on every sweep run; explicit purge via `--purge-trash`.
   118	
   119	---
   120	
   121	### Phase 3: One-Shot PR Scaffold (`QW2` — Hardened Existing Path)
   122	- **Location:** `relay-automation/marathon-closeout.sh` (invoked via `marathon_drive.py --open-only --no-commit`)
   123	- **Reject Duplicate Twin:** No `utils/py/closeout.py`.
   124	- **Hardening Enhancements:**
   125	  1. **Purge `git add -A`:** Remove indiscriminate `git add -A` sweep in `marathon-closeout.sh` that sweeps unintended untracked files.
   126	  2. **Hard-Lock Base:** Strictly enforce `--base development` by default with validation against `main`.
   127	  3. **Deterministic Local Receipt Check:** Asserts that `.xyz/receipts/<HEAD_SHA>.json` exists, is valid JSON, and has `exit_code: 0` before executing `gh pr create`.
   128	  4. **Interface:** Defaults to `--dry-run`; `--execute` runs `git push origin "$branch"` and `gh pr create`.
   129	
   130	---
   131	
   132	### Phase 4: Continuous In-Flight QA Attestation (`QW1` — Driver-Owned, Post-Gate)
   133	- **Location:** `utils/py/marathon_drive.py` (and `utils/py/relay_drive.py`)
   134	- **Timing:** Emitted **post-gate** after the pre-advance gate succeeds and `.xyz/receipts/<SHA>.json` is written.
   135	- **Behavior:** Reads the local receipt and emits a structured comment to the tracked issue:
   136	  ```markdown
   137	  ### Phase QA Attestation: Phase <id> Approved ✅
   138	  <!-- xyz-qa-receipt: issue=<n> phase=<id> sha=<sha> -->
   139	  - **Reviewer:** <Model ID> (<Harness>)
   140	  - **Evidence Receipt:** `gate: ci-local.sh @ <SHA> -> PASS (230/230 in <dur>s)`
    42	2. **Missing Local Telemetry:** Turns across diverse harnesses (`dsh`, `commandcode`, `codex`, `agy`, `claude`, `aider`, `pi`) do not capture local device hardware specs, reasoning levels, or exact token costs in queryable format.
    43	3. **No Automated AI Grading Loop:** Post-turn evaluations rely on ad-hoc human notes rather than a deterministic grading hook scoring runs against objective invariants (gate pass, diff cleanliness, native delivery).
    44	4. **Untapped Empirical Publishing:** The repository generates unique real-world benchmarks on 1M context reasoning models, but lacks an automated pipeline to synthesize experience blog posts and comparative articles.
    45	
    46	## 2. Core Architectural Invariants
    47	
    48	1. **DRY Per-Device Configuration:** Reuses the existing `~/.xyz/` config hierarchy (`~/.xyz/device_config.json` falling back to environment variables `XYZ_HARNESS`, `XYZ_MODEL`, `XYZ_REASONING_EFFORT`).
    49	2. **Reasoning Level & Model Variant Tracking:** Captures explicit reasoning levels (`low`, `medium`, `high`, `max`, `xhigh`) and thinking token budgets per invocation.
    50	3. **Dual Storage & Reversibility:** SQLite `harnesses.db` paired with human-readable, lossless `harnesses.sql` dump and generated `HARNESS-MODELS-REGISTRY.generated.md`.
    51	4. **Deterministic Post-Turn Grading Hook:** Automated callback prompting the AI orchestrator or reviewer to assign grades (`A`, `B`, `C`, `N/A`) with structured qualitative descriptions (1–3 paragraphs).
    52	5. **Blog & Case Study Synthesis:** Subcommand `harness blog gen` querying evaluation history to produce publishable Markdown articles.
    53	
    54	## 3. SQLite Relational Schema (`harnesses.sql`)
    55	
    56	```sql
    57	-- Devices & Local Configurations
    58	CREATE TABLE IF NOT EXISTS devices (
     1	#!/usr/bin/env python3
     2	"""harness_app.py (GH-174) — Transactional Harness & Models SQLite Registry CLI.
     3	
     4	Canonical SQLite ledger for agent harnesses, model routes, per-device configurations,
     5	reasoning effort levels, deterministic post-turn AI evaluations, and grounded blog story synthesis.
     6	"""
     7	
     8	import argparse
     9	import datetime
    10	import json
    11	import os
    12	import sqlite3
    13	import sys
    14	from pathlib import Path
    15	from typing import Any, Dict, List, Optional, Tuple
    16	
    17	
    18	def get_repo_root() -> str:
    19	    """Resolve repository root."""
    20	    return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    21	
    22	
    23	def get_db_path(repo_root: Optional[str] = None) -> str:
    24	    root = repo_root or get_repo_root()
    25	    return os.path.join(root, "harnesses.db")
    26	
    27	
    28	def get_sql_path(repo_root: Optional[str] = None) -> str:
    29	    root = repo_root or get_repo_root()
    30	    return os.path.join(root, "harnesses.sql")
    31	
    32	
    33	def get_generated_md_path(repo_root: Optional[str] = None) -> str:
    34	    root = repo_root or get_repo_root()
    35	    return os.path.join(root, "HARNESS-MODELS-REGISTRY.generated.md")
    36	
    37	
    38	def init_db(db_path: str) -> sqlite3.Connection:
    39	    """Initialize SQLite database with full schema, indexes, and PRAGMAs."""
    40	    os.makedirs(os.path.dirname(os.path.abspath(db_path)), exist_ok=True)
    41	    conn = sqlite3.connect(db_path)
    42	    conn.row_factory = sqlite3.Row
    43	    conn.execute("PRAGMA foreign_keys = ON;")
    44	    conn.execute("PRAGMA journal_mode = WAL;")
    45	
   250	                lines.append(f"**Reasoning Effort:** `{ev['reasoning_effort']}`")
   251	            lines.append("")
   252	            lines.append(ev['work_description_narrative'])
   253	            lines.append("")
   254	
   255	    content = "\n".join(lines) + "\n"
   256	    with open(md_path, "w", encoding="utf-8") as f:
   257	        f.write(content)
   258	
   259	
   260	def check_integrity(repo_root: Optional[str] = None) -> int:
   261	    """Validate database foreign keys, schema consistency, and generated views."""
   262	    root = repo_root or get_repo_root()
   263	    db_p = get_db_path(root)
   264	    sql_p = get_sql_path(root)
   265	    gen_md = get_generated_md_path(root)
   266	
   267	    if not os.path.exists(db_p):
   268	        print(f"harness check: FAIL — database missing at {db_p}", file=sys.stderr)
   269	        return 1
   270	
   271	    conn = init_db(db_p)
   272	    fk_errors = conn.execute("PRAGMA foreign_key_check;").fetchall()
   273	    if fk_errors:
   274	        print(f"harness check: FAIL — foreign key integrity errors: {fk_errors}", file=sys.stderr)
   275	        return 1
   276	
   277	    integ = conn.execute("PRAGMA integrity_check;").fetchall()
   278	    if not integ or integ[0][0] != "ok":
   279	        print(f"harness check: FAIL — SQLite integrity check failed: {integ}", file=sys.stderr)
   280	        return 1
   281	
   282	    print("OK: SQLite database integrity verified (foreign_keys=ON, integrity_check=ok)")
   283	    print("harness check: clean (0 failures, 0 warnings)")
   284	    return 0
   285	
   286	
   287	def main() -> int:
   288	    parser = argparse.ArgumentParser(description="harness_app.py — Harness & Models SQLite Registry CLI")
   289	    subparsers = parser.add_subparsers(dest="subcommand", required=True)
   290	
   291	    # Subcommand: init
   292	    subparsers.add_parser("init", help="Initialize and seed harnesses.db")
   293	
   294	    # Subcommand: dump
   295	    subparsers.add_parser("dump", help="Dump database to harnesses.sql")
   296	
   297	    # Subcommand: gen
   298	    subparsers.add_parser("gen", help="Generate HARNESS-MODELS-REGISTRY.generated.md")
   299	
   300	    # Subcommand: check
   301	    subparsers.add_parser("check", help="Run integrity and schema validation checks")
   302	
   303	    # Subcommand: log
   304	    log_parser = subparsers.add_parser("log", help="Log a harness execution invocation")
   305	    log_parser.add_argument("--device-id", required=True)
   306	    log_parser.add_argument("--harness-id", required=True)
   307	    log_parser.add_argument("--model-id", required=True)
   308	    log_parser.add_argument("--gateway", default="openrouter")
   309	    log_parser.add_argument("--reasoning-effort", choices=["none", "low", "medium", "high", "max", "xhigh"])
   310	    log_parser.add_argument("--shim", required=True)
   311	    log_parser.add_argument("--flags", default="[]")
   312	    log_parser.add_argument("--task-scope", required=True)
   313	    log_parser.add_argument("--seconds", type=float, default=0.0)
   314	    log_parser.add_argument("--exit-code", type=int, default=0)
   315	    log_parser.add_argument("--tokens", type=int, default=0)
   316	    log_parser.add_argument("--cost", type=float, default=0.0)
   317	    log_parser.add_argument("--diff-stat", default="")
   318	
   319	    # Subcommand: eval
   320	    eval_parser = subparsers.add_parser("eval", help="Record a post-turn AI evaluation")
   321	    eval_parser.add_argument("--invocation-id", required=True)
   322	    eval_parser.add_argument("--evaluated-by", required=True)
   323	    eval_parser.add_argument("--role", required=True)
   324	    eval_parser.add_argument("--grade", choices=["A", "A-", "B+", "B", "B-", "C", "N/A"], required=True)
   325	    eval_parser.add_argument("--gate-passed", type=int, choices=[0, 1], required=True)
   326	    eval_parser.add_argument("--cleanliness", type=int, default=5)
   327	    eval_parser.add_argument("--seam-score", type=int, default=5)
   328	    eval_parser.add_argument("--narrative", required=True)
   329	    eval_parser.add_argument("--failure-tag", default="none")
   330	
   331	    # Subcommand: blog
   332	    blog_parser = subparsers.add_parser("blog", help="Blog story generator subcommands")
   333	    blog_sub = blog_parser.add_subparsers(dest="blog_command", required=True)
   334	    gen_blog = blog_sub.add_parser("gen", help="Generate a publishable case study story")
   335	    gen_blog.add_argument("--theme", required=True)
   336	    gen_blog.add_argument("--slug", required=True)
   337	
   338	    args = parser.parse_args()
   339	    root = get_repo_root()
   340	    db_p = get_db_path(root)
   341	    sql_p = get_sql_path(root)
   342	    md_p = get_generated_md_path(root)
   343	
   344	    if args.subcommand == "init":
   345	        conn = init_db(db_p)
   346	        seed_canonical_registry(conn)
   347	        dump_sql(conn, sql_p)
   348	        generate_markdown(conn, md_p)
   349	        print(f"Initialized {db_p} -> dumped {sql_p} -> rendered {md_p}")
   350	        return 0
   351	
   352	    if args.subcommand == "dump":
   353	        conn = init_db(db_p)
   354	        dump_sql(conn, sql_p)
   355	        print(f"Dumped database to {sql_p}")

exec
/bin/zsh -lc 'rg -n --hidden -S "~/.xyz|XYZ_HOME|XDG_DATA_HOME|Application Support|workspace-sweep|workspaces.json|get_trash_dir|purge-trash" utils relay-automation skills README.md ROUTER.md PROJECT | head -n 300' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-17781-brvet5yb
 succeeded in 0ms:
PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md:48:1. **DRY Per-Device Configuration:** Reuses the existing `~/.xyz/` config hierarchy (`~/.xyz/device_config.json` falling back to environment variables `XYZ_HARNESS`, `XYZ_MODEL`, `XYZ_REASONING_EFFORT`).
PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md:160:2. **3-Tier Config Resolution Avoids Repetition:** Resolving per-device settings through local JSON (`~/.xyz/device_config.json`) with environment variable overrides (`XYZ_*`) and sensible global defaults keeps turn shims clean, portable, and completely DRY.
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:39:2. **Soft-Quarantine with Automated Reaper:** Untracked/ignored contents (`.relay-scratch/`) and swept full clones are moved into `.xyz/trash/<timestamp>-<name>/`. Each sweep run automatically reaps trash directories older than 72h (`find .xyz/trash/ -mtime +3 -delete`); immediate hard purge is available via `--purge-trash`.
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:42:5. **Registered Workspace Lifecycle:** `rtl_worktree_begin` and clone creation tools write entries into `.xyz/workspaces.json`. Sweep bounds itself to this manifest and safely cross-checks `git worktree list --porcelain`.
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:98:  - `rtl_worktree_begin()` (in `relay-turn-lib.sh`) and clone creation helpers append newly created workspaces to `.xyz/workspaces.json` (`{path, type, branch, created_at, pid}`).
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:99:- **Location:** `utils/harness/workspace-sweep.sh` (and `xyz workspace sweep`)
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:101:  1. **Candidate Resolution:** Evaluates entries in `.xyz/workspaces.json` and registered `git worktree list --porcelain`.
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:117:  6. **Automated Trash Reaper:** Automatically purges `.xyz/trash/` entries older than 72 hours on every sweep run; explicit purge via `--purge-trash`.
relay-automation/relay-turn-lib.sh:705:  # GH-124 QW3: Register created worktree in .xyz/workspaces.json manifest
utils/py/workspace_manager.py:10:1. Manifest registration (.xyz/workspaces.json).
utils/py/workspace_manager.py:28:    return os.path.join(repo_root, ".xyz", "workspaces.json")
utils/py/workspace_manager.py:31:def get_trash_dir(repo_root):
utils/py/workspace_manager.py:80:    trash_dir = get_trash_dir(repo_root)
utils/py/workspace_manager.py:218:            print(f"workspace-sweep: reaped {reaped} expired trash entries")
utils/py/workspace_manager.py:239:        print("workspace-sweep: no candidate ephemeral workspaces found.")
utils/py/workspace_manager.py:242:    print(f"workspace-sweep: auditing {len(candidates)} candidate workspace(s)...")
utils/py/workspace_manager.py:257:        print("workspace-sweep: 0 workspaces eligible for sweep.")
utils/py/workspace_manager.py:261:        print(f"workspace-sweep: DRY-RUN — {len(to_remove)} workspace(s) eligible. Pass --execute to remove.")
utils/py/workspace_manager.py:265:    trash_dir = get_trash_dir(repo_root)
utils/py/workspace_manager.py:286:                print(f"workspace-sweep: removed linked worktree {p}")
utils/py/workspace_manager.py:289:                print(f"workspace-sweep: failed to remove worktree {p}: {res.stderr.strip()}", file=sys.stderr)
utils/py/workspace_manager.py:294:                print(f"workspace-sweep: moved clone to quarantine {dest_trash}")
utils/py/workspace_manager.py:297:                print(f"workspace-sweep: failed to quarantine clone {p}: {e}", file=sys.stderr)
utils/py/workspace_manager.py:318:    sweep_p.add_argument("--purge-trash", action="store_true", help="Immediately empty .xyz/trash/")
utils/py/device_config.py:5:1. Local per-device file: ~/.xyz/device_config.json
utils/py/device_config.py:28:    return os.path.expanduser("~/.xyz/device_config.json")
utils/py/device_config.py:32:    """Read ~/.xyz/device_config.json if present; return empty dict if missing."""

2026-08-24T04:46:20.580894Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "nl -ba utils/py/workspace_manager.py | sed -n '1,95p'; nl -ba utils/py/workspace_manager.py | sed -n '115,220p'; nl -ba relay-automation/relay-turn-lib.sh | sed -n '690,715p'; nl -ba skills/marathon-cleanup/SKILL.md | sed -n '1,45p'; nl -ba skills/marathon-cleanup/SKILL.md | sed -n '105,165p'; nl -ba AGENTS.md | sed -n '148,166p'; nl -ba ROUTER.md | sed -n '1,45p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-17781-brvet5yb
 succeeded in 0ms:
     1	#!/usr/bin/env python3
     2	"""workspace_manager.py — Ephemeral workspace registration, audit, and safe garbage collection (GH-124).
     3	
     4	WHY THIS FILE EXISTS
     5	--------------------
     6	Marathons and ad-hoc lanes spawn linked git worktrees and temporary full clones.
     7	At closeout, cleaning them up manually is high friction and risky.
     8	
     9	This tool enforces:
    10	1. Manifest registration (.xyz/workspaces.json).
    11	2. Fail-closed safety checks before removal (clean status, all-branch push ancestor verification, stash check).
    12	3. Soft-quarantine of ignored scratch and deleted clones into .xyz/trash/<timestamp>-<name>/ with a 72h reaper.
    13	4. Linked worktree removal executed from the primary repo context.
    14	"""
    15	
    16	import argparse
    17	import datetime
    18	import json
    19	import os
    20	import re
    21	import shutil
    22	import subprocess
    23	import sys
    24	import time
    25	
    26	
    27	def get_manifest_path(repo_root):
    28	    return os.path.join(repo_root, ".xyz", "workspaces.json")
    29	
    30	
    31	def get_trash_dir(repo_root):
    32	    return os.path.join(repo_root, ".xyz", "trash")
    33	
    34	
    35	def load_manifest(repo_root):
    36	    m_path = get_manifest_path(repo_root)
    37	    if not os.path.exists(m_path):
    38	        return []
    39	    try:
    40	        with open(m_path, "r", encoding="utf-8") as f:
    41	            return json.load(f)
    42	    except Exception:
    43	        return []
    44	
    45	
    46	def save_manifest(repo_root, entries):
    47	    m_path = get_manifest_path(repo_root)
    48	    os.makedirs(os.path.dirname(m_path), exist_ok=True)
    49	    tmp = f"{m_path}.tmp.{os.getpid()}"
    50	    with open(tmp, "w", encoding="utf-8") as f:
    51	        json.dump(entries, f, indent=2)
    52	        f.write("\n")
    53	    os.replace(tmp, m_path)
    54	
    55	
    56	def register_workspace(repo_root, path, ws_type, branch=None, pid=None):
    57	    abs_path = os.path.abspath(path)
    58	    entries = load_manifest(repo_root)
    59	    # Deduplicate existing entry for the same path
    60	    entries = [e for e in entries if os.path.abspath(e.get("path", "")) != abs_path]
    61	    entries.append({
    62	        "path": abs_path,
    63	        "type": ws_type,
    64	        "branch": branch,
    65	        "pid": pid or os.getpid(),
    66	        "created_at": datetime.datetime.now(datetime.timezone.utc).isoformat()
    67	    })
    68	    save_manifest(repo_root, entries)
    69	
    70	
    71	def deregister_workspace(repo_root, path):
    72	    abs_path = os.path.abspath(path)
    73	    entries = load_manifest(repo_root)
    74	    filtered = [e for e in entries if os.path.abspath(e.get("path", "")) != abs_path]
    75	    save_manifest(repo_root, filtered)
    76	
    77	
    78	def reap_trash(repo_root, max_age_hours=72, force_all=False):
    79	    """Purge trash directories older than max_age_hours or all if force_all is True."""
    80	    trash_dir = get_trash_dir(repo_root)
    81	    if not os.path.exists(trash_dir):
    82	        return 0
    83	    now = time.time()
    84	    reaped = 0
    85	    for name in os.listdir(trash_dir):
    86	        p = os.path.join(trash_dir, name)
    87	        if not os.path.isdir(p):
    88	            continue
    89	        try:
    90	            age_hours = None
    91	            if len(name) >= 16 and name[8] == "T" and name[15] == "Z":
    92	                try:
    93	                    dt = datetime.datetime.strptime(name[:16], "%Y%m%dT%H%M%SZ").replace(tzinfo=datetime.timezone.utc)
    94	                    age_hours = (datetime.datetime.now(datetime.timezone.utc) - dt).total_seconds() / 3600.0
    95	                except Exception:
   115	    """Evaluate whether a workspace is safe to tear down.
   116	    
   117	    Returns: (is_safe, ws_type, branch, reason)
   118	    """
   119	    canon_repo = os.path.realpath(repo_root)
   120	    target_abs = os.path.abspath(target_path)
   121	    if not os.path.exists(target_abs):
   122	        return False, "unknown", None, "path does not exist"
   123	
   124	    canon_target = os.path.realpath(target_abs)
   125	
   126	    # Invariant 1: Never delete primary repo root
   127	    if canon_target == canon_repo:
   128	        return False, "primary", None, "refusing to sweep primary repository root"
   129	
   130	    # Invariant 2: Never delete current working directory
   131	    canon_cwd = os.path.realpath(os.getcwd())
   132	    if canon_target == canon_cwd or canon_cwd.startswith(canon_target + os.sep):
   133	        return False, "active_cwd", None, "refusing to sweep current working directory"
   134	
   135	    # Invariant 3: Refuse symlinks
   136	    if os.path.islink(target_abs):
   137	        return False, "symlink", None, "refusing to sweep symlink"
   138	
   139	    # Invariant 4: Must be a git repository or linked worktree
   140	    dot_git = os.path.join(target_abs, ".git")
   141	    if not os.path.exists(dot_git):
   142	        return False, "unknown", None, "target does not have a .git file or directory"
   143	
   144	    is_worktree = os.path.isfile(dot_git)
   145	    ws_type = "worktree" if is_worktree else "clone"
   146	
   147	    # Invariant 5: Stash check (Full Clones)
   148	    if not is_worktree:
   149	        stash = subprocess.run(["git", "-C", target_abs, "stash", "list"],
   150	                               stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
   151	        if stash.stdout.strip():
   152	            return False, ws_type, None, "clone contains unsaved/unmerged git stashes"
   153	
   154	    # Invariant 6: Porcelain cleanliness (zero uncommitted changes)
   155	    st = subprocess.run(["git", "-C", target_abs, "status", "--porcelain"],
   156	                        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
   157	    if st.returncode != 0:
   158	        return False, ws_type, None, f"git status failed: {st.stderr.strip()}"
   159	    if st.stdout.strip():
   160	        return False, ws_type, None, "uncommitted changes in working tree"
   161	
   162	    # Invariant 7: Branch & Push Verification
   163	    if is_worktree:
   164	        br_res = subprocess.run(["git", "-C", target_abs, "rev-parse", "--abbrev-ref", "HEAD"],
   165	                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
   166	        branch = br_res.stdout.strip() if br_res.returncode == 0 else ""
   167	        if not branch or branch == "HEAD":
   168	            # Detached HEAD in worktree: check if HEAD is an ancestor of ANY remote tracking branch
   169	            head_sha_res = subprocess.run(["git", "-C", target_abs, "rev-parse", "HEAD"],
   170	                                          stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
   171	            head_sha = head_sha_res.stdout.strip() if head_sha_res.returncode == 0 else ""
   172	            if not head_sha:
   173	                return False, ws_type, "detached", "could not determine HEAD commit"
   174	            
   175	            # Query all remote tracking refs
   176	            rem_refs_res = subprocess.run(["git", "-C", target_abs, "for-each-ref", "--format=%(refname:short)", "refs/remotes/"],
   177	                                          stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
   178	            rem_refs = [r.strip() for r in rem_refs_res.stdout.splitlines() if r.strip()]
   179	            is_pushed = False
   180	            for rref in rem_refs:
   181	                anc = subprocess.run(["git", "-C", target_abs, "merge-base", "--is-ancestor", head_sha, rref],
   182	                                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
   183	                if anc.returncode == 0:
   184	                    is_pushed = True
   185	                    break
   186	            if not is_pushed:
   187	                return False, ws_type, f"detached:{head_sha[:8]}", f"detached HEAD ({head_sha[:8]}) has unpushed commits"
   188	            return True, ws_type, f"detached:{head_sha[:8]}", "clean & pushed"
   189	        else:
   190	            # Check if HEAD is pushed to origin/<branch>
   191	            anc = subprocess.run(["git", "-C", target_abs, "merge-base", "--is-ancestor", "HEAD", f"origin/{branch}"],
   192	                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
   193	            if anc.returncode != 0:
   194	                return False, ws_type, branch, f"HEAD on branch '{branch}' has unpushed commits"
   195	            return True, ws_type, branch, "clean & pushed"
   196	
   197	    else:
   198	        # Full Clone: Check all local branches
   199	        refs = subprocess.run(["git", "-C", target_abs, "for-each-ref", "--format=%(refname:short)", "refs/heads/"],
   200	                              stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
   201	        branches = refs.stdout.splitlines() if refs.returncode == 0 else []
   202	        for br in branches:
   203	            br = br.strip()
   204	            if not br:
   205	                continue
   206	            anc = subprocess.run(["git", "-C", target_abs, "merge-base", "--is-ancestor", br, f"origin/{br}"],
   207	                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
   208	            if anc.returncode != 0:
   209	                return False, ws_type, br, f"local branch '{br}' is not pushed to origin/{br}"
   210	        return True, ws_type, ", ".join(branches), "clean, all branches pushed, zero stashes"
   211	
   212	
   213	def sweep_workspaces(repo_root, execute=False, purge_trash=False):
   214	    """Audit and sweep eligible ephemeral workspaces."""
   215	    if execute or purge_trash:
   216	        reaped = reap_trash(repo_root, force_all=purge_trash)
   217	        if reaped > 0:
   218	            print(f"workspace-sweep: reaped {reaped} expired trash entries")
   219	
   220	    # Discover candidate paths from manifest + git worktree list
   690	  _root_abs="$(cd "$RTL_ROOT" 2>/dev/null && pwd -P)"
   691	  _tmp_abs="$(cd "$wt_root" 2>/dev/null && pwd -P)"
   692	  if [[ -n "$_root_abs" && -n "$_tmp_abs" && ( "$_tmp_abs" == "$_root_abs" || "$_tmp_abs" == "$_root_abs"/* ) ]]; then
   693	    _gcd="$(git -C "$RTL_ROOT" rev-parse --git-common-dir 2>/dev/null)"
   694	    [[ -n "$_gcd" && "$_gcd" != /* ]] && _gcd="$RTL_ROOT/$_gcd"
   695	    if [[ -n "$_gcd" ]] && mkdir -p "$_gcd/rtl-worktrees" 2>/dev/null; then
   696	      wt_root="$_gcd/rtl-worktrees"
   697	      rtl_trace "rtl_worktree_begin: RELOCATED worktree root off \$TMPDIR (inside RTL_ROOT) -> $wt_root (GH-236)"
   698	    fi
   699	  fi
   700	  wt="$(mktemp -d "${wt_root}/rtl-wt.XXXXXX")" || return 1
   701	  rm -rf "$wt"                         # git worktree add wants a non-existent path
   702	  if ! git -C "$RTL_ROOT" worktree add --detach "$wt" HEAD >/dev/null 2>&1; then
   703	    rm -rf "$wt" 2>/dev/null; return 1
   704	  fi
   705	  # GH-124 QW3: Register created worktree in .xyz/workspaces.json manifest
   706	  if [ -n "${RTL_ROOT:-}" ] && [ -f "$RTL_ROOT/utils/py/workspace_manager.py" ]; then
   707	    python3 "$RTL_ROOT/utils/py/workspace_manager.py" register --repo "$RTL_ROOT" --path "$wt" --type worktree >/dev/null 2>&1 || true
   708	  fi
   709	  rtl_trace "rtl_worktree_begin: WT=$wt"
   710	  for a in "${RTL_ALLOW[@]}"; do       # seed current content (overwrite HEAD versions)
   711	    # GH-30 Phase 3: an ABSOLUTE allowlist entry is the archive relay file — it lives in a DIFFERENT
   712	    # repo, not this RTL_ROOT worktree. Skip it: the agent edits it at its real location and rtl_enforce
   713	    # commits it to the archive. (Keeps seedsig index aligned with the copyback loop, which skips it too.)
   714	    if [[ "$a" == /* ]]; then
   715	      rtl_trace "rtl_worktree_begin: SKIP (archive-absolute) $a"
     1	---
     2	name: marathon-cleanup
     3	description: >
     4	  Audit active PDDA marathon plans and bundles, reconcile every lane against canonical project docs,
     5	  frontmatter and status tables, GitHub issue and PR state, landed commits, tests, and CHANGELOG
     6	  evidence, then archive only verified-complete task docs and fully complete marathons. Use when asked
     7	  to clean up, reconcile, retire, archive, or sweep completed marathon files under PROJECT/2-WORKING,
     8	  especially after marathon lanes merge. Defaults to report-only and requires explicit confirmation
     9	  before moving files or changing lifecycle records.
    10	---
    11	
    12	# Marathon cleanup
    13	
    14	Reconcile marathon execution artifacts with PDDA lifecycle state. A move is the final bookkeeping
    15	step, never the evidence that work completed.
    16	
    17	## Guardrails
    18	
    19	- Read `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `ROADMAP.md`, `PROJECT/PDDA.md`, and the
    20	  candidate marathon in full before classifying it.
    21	- Default to audit-only. Do not edit, move, close issues, create commits, or change ROADMAP or
    22	  CHANGELOG until the operator confirms the exact proposed move set.
    23	- Never classify from a closed issue, checked box, frontmatter word, commit message, or changelog
    24	  entry alone. Require converging durable evidence and no contradiction.
    25	- Preserve unrelated dirty-worktree changes. Stop if a candidate or lifecycle ledger has overlapping
    26	  edits that cannot be safely merged.
    27	- Use `git mv` for approved repo moves. Never delete marathon files or rewrite history.
    28	- Treat unavailable GitHub state as `UNKNOWN`, not complete.
    29	
    30	## 1. Inventory marathon candidates
    31	
    32	Inspect only active execution artifacts under `PROJECT/2-WORKING`:
    33	
    34	```bash
    35	find PROJECT/2-WORKING -maxdepth 1 \
    36	  \( -type f -o -type d \) \
    37	  \( -name 'MARATHON-*.md' -o -name 'MARATHON-*' \) \
    38	  -print | LC_ALL=C sort
    39	```
    40	
    41	Include hand-authored and generated marathon plans plus execution bundle directories. Classify
    42	generated HQ rollups, triage reports, examples, snapshots, and docs that merely mention marathons as
    43	`NOT-EXECUTION-DOC`; do not archive them through this workflow.
    44	
    45	For each candidate, extract lane IDs from frontmatter (`lanes`), wave/lane tables, issue links,
   105	`Shipped`, `Fixed`, `Closed`, `Merged`, `Resolved`, or `Landed`, and reconcile its Status table.
   106	
   107	The parent marathon may move only when:
   108	
   109	- every lane is `VERIFIED-COMPLETE` or `VERIFIED-MARATHON-SLICE`;
   110	- no wave, lane, review, merge, gate, or operator action remains;
   111	- the marathon's own status can truthfully become terminal;
   112	- all sibling bundle files describe the same terminal outcome;
   113	- the destination does not already exist; and
   114	- relative links will remain valid or are included in the proposed edit set.
   115	
   116	An open issue does not block a completed marathon slice by itself. It does block moving that issue's
   117	canonical task doc unless the entire issue is complete and the open state is being explicitly
   118	reconciled.
   119	
   120	## 5. Report before mutation
   121	
   122	Return one table per marathon with lane result, canonical doc, GitHub state, delivery proof,
   123	verification proof, CHANGELOG proof, contradictions, and proposed action. End with one exact move
   124	set, for example:
   125	
   126	```text
   127	git mv PROJECT/2-WORKING/GH-123-EXAMPLE.md PROJECT/3-COMPLETED/
   128	git mv PROJECT/2-WORKING/MARATHON-PLAN-YYYY-MM-DD.md PROJECT/3-COMPLETED/
   129	```
   130	
   131	Also list required content edits and ledger updates. Ask for explicit confirmation of that set. If
   132	any lane is not eligible, leave the marathon in place and state the smallest evidence or work needed.
   133	
   134	## 6. Apply a confirmed cleanup
   135	
   136	After confirmation, execute in this order:
   137	
   138	1. Re-check `git status`, GitHub state, target-branch reachability, and destination absence.
   139	2. Update eligible task docs to terminal frontmatter and an evidence-backed Status row; preserve
   140	   issue links and outcome detail.
   141	3. Update the marathon plan and every file in its bundle to the verified terminal outcome. Do not
   142	   leave `not yet fired`, `ready`, or an outstanding next action inside `3-COMPLETED`.
   143	4. Use `git mv` for eligible task docs, then the fully complete marathon file or directory.
   144	5. Update ROADMAP pointers and state in place. Keep it a pointer ledger; do not copy execution detail.
   145	6. Add a concise dated CHANGELOG entry naming the verified outcome and moved artifacts.
   146	7. Run `utils/pdda/pdda.sh run`. Run relevant link or repo validation when links or code changed.
   147	8. Report moves, evidence, validation output, and anything deliberately left active.
   148	
   149	If validation fails, do not claim completion. Repair only changes in the confirmed cleanup scope; if
   150	the failure is unrelated, report it precisely without altering unrelated user work.
   151	
   148	- `validate.sh` is the code/runtime gate. `utils/pdda/pdda.sh run` and its targeted
   149	  `utils/pdda/pdda.sh <check>` subcommands are the doc-hygiene gates.
   150	- **Scratch and temporary files go in `temp/`, never the repo root.** `/temp/` is already gitignored
   151	  (`.gitignore:13`). Probes, reproduction scripts, one-off analysis, captured command output,
   152	  half-written notes — anything you would not put in a commit — belongs there or outside the repo
   153	  entirely. **Do not create `scratch-*.md`, `notes-*.md`, `*.tmp` or similar at the repo root.**
   154	
   155	  This is a housekeeping rule with a real failure mode behind it, which is why it is a rail and not a
   156	  preference. Root-level scratch is *untracked*, so it survives branch switches, rebases and
   157	  worktree teardown; it accumulates silently across sessions until nobody can say which agent or
   158	  which lane produced it, or whether it is safe to delete. It also puts unreviewed prose one
   159	  `git add -A` away from a commit — and `marathon-closeout.sh` has already swept 20 unrelated files
   160	  into a lane's PR once (2026-08-10), which is exactly this hazard firing.
   161	
   162	  A file that turns out to be worth keeping gets *promoted* deliberately — into `PROJECT/1-INBOX/`
   163	  as a capture doc, into `test/baselines/` as recorded evidence, or into the CHANGELOG — rather than
   164	  being left at the root in the hope that someone later works out what it was.
   165	- **Frozen Bash twins (GH-308).** Python in `utils/py/` is authoritative for the eleven Tier-A
   166	  entry points (`agy-turn`, `aider-turn`, `claude-turn`, `codex-turn`, `pi-turn`, `poll`,
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

2026-08-24T04:46:35.028793Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc 'rg -n -S "blog-frontier-benchmarks|HARNESS-MODELS-REGISTRY.generated|def generate_blog|blog gen|dump_sql" utils/py/harness_app.py test/gh174-harness-registry.sh PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-17781-brvet5yb
 succeeded in 0ms:
PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md:36:| Phase 1-5 implemented: `harnesses.db` schema, CLI `harness_app.py`, 3-tier config `device_config.py`, telemetry `harness_turn_logger.py`, AI grading hooks, blog generator, and 6/6 test assertions passing in `test/gh174-harness-registry.sh`. | Full validation gate run and pull request merge. |
PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md:50:3. **Dual Storage & Reversibility:** SQLite `harnesses.db` paired with human-readable, lossless `harnesses.sql` dump and generated `HARNESS-MODELS-REGISTRY.generated.md`.
PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md:52:5. **Blog & Case Study Synthesis:** Subcommand `harness blog gen` querying evaluation history to produce publishable Markdown articles.
PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md:154:- **Phase 4 (Blog & Experience Story Synthesizer):** `harness blog gen` generating publishable markdown case studies.
utils/py/harness_app.py:35:    return os.path.join(root, "HARNESS-MODELS-REGISTRY.generated.md")
utils/py/harness_app.py:194:def dump_sql(conn: sqlite3.Connection, sql_path: str):
utils/py/harness_app.py:202:    """Render canonical HARNESS-MODELS-REGISTRY.generated.md view from database."""
utils/py/harness_app.py:298:    subparsers.add_parser("gen", help="Generate HARNESS-MODELS-REGISTRY.generated.md")
utils/py/harness_app.py:347:        dump_sql(conn, sql_p)
utils/py/harness_app.py:354:        dump_sql(conn, sql_p)
utils/py/harness_app.py:392:        dump_sql(conn, sql_p)
utils/py/harness_app.py:411:        dump_sql(conn, sql_p)
utils/py/harness_app.py:432:            f"**Generated by:** `utils/py/harness_app.py blog gen` | **Published:** {datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%d')}",
utils/py/harness_app.py:464:        dump_sql(conn, sql_p)
test/gh174-harness-registry.sh:125:out="$(python3 "$HARNESS_APP" blog gen --theme "Frontier AI Benchmarks in XYZ" --slug "frontier-benchmarks" 2>&1)" || rc=$?
test/gh174-harness-registry.sh:126:BLOG_FILE="$ROOT/docs/blog-frontier-benchmarks.md"
test/gh174-harness-registry.sh:128:  pass "harness_app.py blog gen synthesizes publishable Markdown case study"
test/gh174-harness-registry.sh:130:  fail "harness_app.py blog gen failed (rc=$rc, out=$out)"

2026-08-24T04:47:08.171536Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "nl -ba utils/py/harness_app.py | sed -n '185,225p'; nl -ba utils/py/harness_app.py | sed -n '370,470p'; nl -ba test/gh174-harness-registry.sh | sed -n '100,135p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-17781-brvet5yb
 succeeded in 0ms:
   185	            ('google/gemma-4-31b-qat', 'Google', 'Gemma 4 31B QAT', 'lmstudio', 32768, 0.0, 0.0, 0.0, '["none"]'),
   186	        ]
   187	        for m in models_data:
   188	            conn.execute("""
   189	            INSERT OR REPLACE INTO models (model_id, lab, canonical_name, gateway, context_window, prompt_price_per_m, completion_price_per_m, cache_read_price_per_m, supported_reasoning_levels)
   190	            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
   191	            """, m)
   192	
   193	
   194	def dump_sql(conn: sqlite3.Connection, sql_path: str):
   195	    """Losslessly dump database schema and contents into SQL text file."""
   196	    with open(sql_path, "w", encoding="utf-8") as f:
   197	        for line in conn.iterdump():
   198	            f.write(f"{line}\n")
   199	
   200	
   201	def generate_markdown(conn: sqlite3.Connection, md_path: str):
   202	    """Render canonical HARNESS-MODELS-REGISTRY.generated.md view from database."""
   203	    harnesses = conn.execute("SELECT * FROM harnesses ORDER BY harness_id;").fetchall()
   204	    models = conn.execute("SELECT * FROM models ORDER BY lab, canonical_name;").fetchall()
   205	    evals = conn.execute("""
   206	        SELECT e.grade, e.evaluated_by, e.evaluation_role, e.work_description_narrative,
   207	               i.harness_id, i.model_id, i.reasoning_effort, i.created_at
   208	        FROM evaluations e
   209	        JOIN invocation_logs i ON e.invocation_id = i.invocation_id
   210	        ORDER BY e.created_at DESC;
   211	    """).fetchall()
   212	
   213	    lines = [
   214	        "# Harness & Models Registry (Generated View)",
   215	        "",
   216	        "<!-- Auto-generated from harnesses.db by utils/py/harness_app.py — DO NOT HAND-EDIT -->",
   217	        "",
   218	        "## 1. Operating Harnesses & Policy Lanes",
   219	        "",
   220	        "| Harness | Execution Engine | Policy Role | Operating Constraint |",
   221	        "|---|---|---|---|",
   222	    ]
   223	    for h in harnesses:
   224	        lines.append(f"| **{h['name']}** (`{h['harness_id']}`) | `{h['execution_engine']}` | {h['standing_policy_role'] or '—'} | {h['operating_constraint'] or '—'} |")
   225	
   370	        with conn:
   371	            conn.execute("""
   372	            INSERT OR IGNORE INTO devices (device_id, user_name, os_version, cpu_cores, ram_gb)
   373	            VALUES (?, ?, ?, ?, ?);
   374	            """, (args.device_id, os.environ.get("USER", "default_user"), sys.platform, os.cpu_count() or 4, 16))
   375	
   376	            conn.execute("""
   377	            INSERT OR IGNORE INTO models (model_id, lab, canonical_name, gateway, context_window, prompt_price_per_m, completion_price_per_m, cache_read_price_per_m, supported_reasoning_levels)
   378	            VALUES (?, 'Auto', ?, ?, 1000000, 0.0, 0.0, 0.0, '["none"]');
   379	            """, (args.model_id, args.model_id, args.gateway))
   380	
   381	            conn.execute("""
   382	            INSERT INTO invocation_logs (
   383	                invocation_id, device_id, harness_id, model_id, gateway, reasoning_effort,
   384	                entry_point_shim, cli_flags, task_scope, wall_clock_seconds, exit_code,
   385	                total_tokens, estimated_cost_usd, repo_diff_stat
   386	            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
   387	            """, (
   388	                inv_id, args.device_id, args.harness_id, args.model_id, args.gateway,
   389	                args.reasoning_effort, args.shim, args.flags, args.task_scope,
   390	                args.seconds, args.exit_code, args.tokens, args.cost, args.diff_stat
   391	            ))
   392	        dump_sql(conn, sql_p)
   393	        print(inv_id)
   394	        return 0
   395	
   396	    if args.subcommand == "eval":
   397	        conn = init_db(db_p)
   398	        eval_id = f"eval-{datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d%H%M%S')}-{os.urandom(4).hex()}"
   399	        with conn:
   400	            conn.execute("""
   401	            INSERT INTO evaluations (
   402	                evaluation_id, invocation_id, evaluated_by, evaluation_role, grade,
   403	                qualifying_gate_passed, diff_cleanliness_score, seam_reliability_score,
   404	                work_description_narrative, failure_mode_tag
   405	            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
   406	            """, (
   407	                eval_id, args.invocation_id, args.evaluated_by, args.role, args.grade,
   408	                args.gate_passed, args.cleanliness, args.seam_score, args.narrative,
   409	                args.failure_tag
   410	            ))
   411	        dump_sql(conn, sql_p)
   412	        generate_markdown(conn, md_p)
   413	        print(eval_id)
   414	        return 0
   415	
   416	    if args.subcommand == "blog" and args.blog_command == "gen":
   417	        conn = init_db(db_p)
   418	        evals = conn.execute("""
   419	            SELECT e.grade, e.evaluated_by, e.work_description_narrative, e.qualifying_gate_passed,
   420	                   i.harness_id, i.model_id, i.reasoning_effort, i.wall_clock_seconds, i.estimated_cost_usd,
   421	                   i.task_scope, i.repo_diff_stat
   422	            FROM evaluations e
   423	            JOIN invocation_logs i ON e.invocation_id = i.invocation_id
   424	            ORDER BY e.created_at DESC;
   425	        """).fetchall()
   426	
   427	        story_id = f"story-{datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d%H%M%S')}"
   428	        title = args.theme
   429	        body = [
   430	            f"# {title}",
   431	            "",
   432	            f"**Generated by:** `utils/py/harness_app.py blog gen` | **Published:** {datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%d')}",
   433	            "",
   434	            "## Executive Summary & Empirical Takeaways",
   435	            "",
   436	            f"This benchmark analysis synthesizes empirical results across {len(evals)} verified agent evaluations under load in `XYZ-forge`.",
   437	            "",
   438	            "## Evaluated Performance Matrix",
   439	            "",
   440	            "| Task Scope | Harness & Model | Reasoning Level | Duration | Gate Passed | Grade |",
   441	            "|---|---|:---:|:---:|:---:|:---:|",
   442	        ]
   443	        for ev in evals:
   444	            gate_badge = "✅ PASS" if ev['qualifying_gate_passed'] else "❌ FAIL"
   445	            body.append(f"| {ev['task_scope']} | `{ev['harness_id']}` + `{ev['model_id']}` | `{ev['reasoning_effort'] or 'standard'}` | {ev['wall_clock_seconds']:.1f}s | {gate_badge} | **{ev['grade']}** |")
   446	
   447	        body.extend([
   448	            "",
   449	            "## In-Depth Architectural Narratives & Field Notes",
   450	            "",
   451	        ])
   452	        for ev in evals:
   453	            body.append(f"### Case Study: `{ev['model_id']}` on `{ev['task_scope']}`")
   454	            body.append(ev['work_description_narrative'])
   455	            body.append("")
   456	
   457	        story_md = "\n".join(body) + "\n"
   458	        with conn:
   459	            conn.execute("""
   460	            INSERT OR REPLACE INTO blog_stories (story_id, title, slug, theme, source_evaluations, markdown_content, published_at)
   461	            VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP);
   462	            """, (story_id, title, args.slug, args.theme, json.dumps([]), story_md))
   463	
   464	        dump_sql(conn, sql_p)
   465	        out_path = os.path.join(root, "docs", f"blog-{args.slug}.md")
   466	        os.makedirs(os.path.dirname(out_path), exist_ok=True)
   467	        with open(out_path, "w", encoding="utf-8") as f:
   468	            f.write(story_md)
   469	        print(f"Generated blog story {story_id} -> {out_path}")
   470	        return 0
   100	assert logger.invocation_id is not None
   101	
   102	eval_id = logger.record_evaluation(
   103	    evaluated_by="stealth/ox-alpha",
   104	    role="Systems Reviewer",
   105	    grade="A-",
   106	    gate_passed=True,
   107	    narrative="Qwen 3.8-Max executed thorough systems refactoring with extra high reasoning effort.",
   108	    cleanliness=5,
   109	    seam_score=5,
   110	)
   111	assert eval_id is not None
   112	print("LOGGER_EVAL_OK")
   113	PYEOF
   114	
   115	rc=0
   116	out="$(python3 "$TEST_LOGGER" 2>&1)" || rc=$?
   117	if [ "$rc" -eq 0 ] && grep -q "LOGGER_EVAL_OK" <<<"$out"; then
   118	  pass "HarnessTurnLogger logs telemetry and records evaluation successfully"
   119	else
   120	  fail "HarnessTurnLogger failed (rc=$rc, out=$out)"
   121	fi
   122	
   123	# 5. Blog generation synthesis
   124	rc=0
   125	out="$(python3 "$HARNESS_APP" blog gen --theme "Frontier AI Benchmarks in XYZ" --slug "frontier-benchmarks" 2>&1)" || rc=$?
   126	BLOG_FILE="$ROOT/docs/blog-frontier-benchmarks.md"
   127	if [ "$rc" -eq 0 ] && [ -f "$BLOG_FILE" ] && grep -q "Frontier AI Benchmarks in XYZ" "$BLOG_FILE"; then
   128	  pass "harness_app.py blog gen synthesizes publishable Markdown case study"
   129	else
   130	  fail "harness_app.py blog gen failed (rc=$rc, out=$out)"
   131	fi
   132	
   133	# 6. Negative control: Invalid grade rejected by SQLite CHECK constraint
   134	TEST_NEG="$WORK/test_neg.py"
   135	cat > "$TEST_NEG" <<PYEOF

2026-08-24T04:47:12.631671Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc 'git ls-files harnesses.db harnesses.sql HARNESS-MODELS-REGISTRY.generated.md docs/blog-frontier-benchmarks.md .relay-scratch; git status --short -- harnesses.db harnesses.sql HARNESS-MODELS-REGISTRY.generated.md docs/blog-frontier-benchmarks.md .relay-scratch; git check-ignore -v .tick/orphan-backups/example .xyz/trash/example .relay-scratch/example 2>/dev/null || true' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-17781-brvet5yb
2026-08-24T04:47:27.302560Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
 succeeded in 8096ms:
2026-08-23 21:47:20.041 xcodebuild[25659:269870199]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-23 21:47:20.439 xcodebuild[25659:269870198] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-WoEAiI80' (errno=Operation not permitted)
2026-08-23 21:47:21.147 xcodebuild[25791:269870538]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-23 21:47:21.335 xcodebuild[25791:269870536] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
HARNESS-MODELS-REGISTRY.generated.md
docs/blog-frontier-benchmarks.md
harnesses.db
harnesses.sql
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-qTb0Kv7V' (errno=Operation not permitted)
2026-08-23 21:47:22.643 xcodebuild[25835:269870640]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-23 21:47:22.849 xcodebuild[25835:269870639] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-gLjh7WKb' (errno=Operation not permitted)
2026-08-23 21:47:23.482 xcodebuild[25940:269870906]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-23 21:47:23.678 xcodebuild[25940:269870905] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
?? .relay-scratch/
.gitignore:1:.tick/	.tick/orphan-backups/example
.gitignore:67:.xyz/	.xyz/trash/example

codex
## ANSWER

Store teardown salvage in a host-owned, repo-independent inbox:

`~/.xyz/salvage/<repo-id>/<marathon-id>/<clone-name>/`

Each clone directory should contain the raw files plus `manifest.json` recording source path, HEAD, timestamp, file hashes, SQLite integrity result, and `pending|imported` status. This uses the repo’s established per-device `~/.xyz/` hierarchy (`PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md:46-50`) while keeping transient snapshots outside every Git working tree.

“Merge before delete” should be the preferred path, but not replace salvage. Teardown should permit deletion only when either:

1. The telemetry has been merged, canonical outputs regenerated, and integrity checked; or
2. An atomic, hash-verified salvage snapshot is registered as pending.

Salvage remains the failure/deferred-import buffer.

## FINDINGS

- [Blocker] `.tick/orphan-backups/` is unsuitable by construction. It lives beneath the clone root, is gitignored (`.gitignore:1`), and exists specifically as a best-effort pre-revert copy (`relay-automation/relay-turn-lib.sh:966-987`). Clone deletion deletes it too.

- [Blocker] Do not use `relay-system/`, a new top-level directory, or any other primary-repo path. A driven turn snapshots dirtiness only once and reverts newly dirty off-allowlist paths (`skills/relay-xyz/SKILL.md:485-493`; `relay-automation/relay-turn-lib.sh:1018-1023`). Repo-local scratch also risks accidental `git add -A`; that exact failure has already swept unrelated files into a PR (`AGENTS.md:150-160`).

- [Should] Do not rely on the existing repo-local `.xyz/trash/`. It is explicitly reaped after 72 hours (`utils/py/workspace_manager.py:78-95`), while pending telemetry needs retention until confirmed import. The current sweep also refuses clones with uncommitted changes (`utils/py/workspace_manager.py:154-160`), so salvage/import must be a prerequisite to eligibility.

- [Should] Preserve all stated files in the snapshot, but treat `harnesses.db` plus its lossless SQL dump as the import sources. The registry defines the DB, SQL dump, and generated Markdown as one reversible set (`PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md:46-52`); the implementation losslessly dumps SQL and derives Markdown from the DB (`utils/py/harness_app.py:194-216`). Never commit separate per-clone DB blobs.

- [Should] Guarantee discoverability mechanically, not merely with a README. Add the canonical pointer and teardown gate to `skills/marathon-cleanup/SKILL.md`, plus a routing hint in `ROUTER.md`. Maintain `~/.xyz/salvage/index.json`; cleanup/sweep must list pending entries and refuse source deletion unless import or verified salvage is recorded. The cleanup skill currently ends after PDDA archival and validation, with no clone-state check (`skills/marathon-cleanup/SKILL.md:134-150`).

- [Pass] The current ad-hoc external location chose the correct containment boundary. Its defect is lifecycle indexing, not being outside the repository.

## RECOMMENDATION

Standardize on `~/.xyz/salvage/`, make merge-first the happy path and verified salvage the mandatory fallback, and enforce discoverability through the marathon-cleanup skill plus a fail-closed pending-salvage index.
tokens used
102,063
## ANSWER

Store teardown salvage in a host-owned, repo-independent inbox:

`~/.xyz/salvage/<repo-id>/<marathon-id>/<clone-name>/`

Each clone directory should contain the raw files plus `manifest.json` recording source path, HEAD, timestamp, file hashes, SQLite integrity result, and `pending|imported` status. This uses the repo’s established per-device `~/.xyz/` hierarchy (`PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md:46-50`) while keeping transient snapshots outside every Git working tree.

“Merge before delete” should be the preferred path, but not replace salvage. Teardown should permit deletion only when either:

1. The telemetry has been merged, canonical outputs regenerated, and integrity checked; or
2. An atomic, hash-verified salvage snapshot is registered as pending.

Salvage remains the failure/deferred-import buffer.

## FINDINGS

- [Blocker] `.tick/orphan-backups/` is unsuitable by construction. It lives beneath the clone root, is gitignored (`.gitignore:1`), and exists specifically as a best-effort pre-revert copy (`relay-automation/relay-turn-lib.sh:966-987`). Clone deletion deletes it too.

- [Blocker] Do not use `relay-system/`, a new top-level directory, or any other primary-repo path. A driven turn snapshots dirtiness only once and reverts newly dirty off-allowlist paths (`skills/relay-xyz/SKILL.md:485-493`; `relay-automation/relay-turn-lib.sh:1018-1023`). Repo-local scratch also risks accidental `git add -A`; that exact failure has already swept unrelated files into a PR (`AGENTS.md:150-160`).

- [Should] Do not rely on the existing repo-local `.xyz/trash/`. It is explicitly reaped after 72 hours (`utils/py/workspace_manager.py:78-95`), while pending telemetry needs retention until confirmed import. The current sweep also refuses clones with uncommitted changes (`utils/py/workspace_manager.py:154-160`), so salvage/import must be a prerequisite to eligibility.

- [Should] Preserve all stated files in the snapshot, but treat `harnesses.db` plus its lossless SQL dump as the import sources. The registry defines the DB, SQL dump, and generated Markdown as one reversible set (`PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md:46-52`); the implementation losslessly dumps SQL and derives Markdown from the DB (`utils/py/harness_app.py:194-216`). Never commit separate per-clone DB blobs.

- [Should] Guarantee discoverability mechanically, not merely with a README. Add the canonical pointer and teardown gate to `skills/marathon-cleanup/SKILL.md`, plus a routing hint in `ROUTER.md`. Maintain `~/.xyz/salvage/index.json`; cleanup/sweep must list pending entries and refuse source deletion unless import or verified salvage is recorded. The cleanup skill currently ends after PDDA archival and validation, with no clone-state check (`skills/marathon-cleanup/SKILL.md:134-150`).

- [Pass] The current ad-hoc external location chose the correct containment boundary. Its defect is lifecycle indexing, not being outside the repository.

## RECOMMENDATION

Standardize on `~/.xyz/salvage/`, make merge-first the happy path and verified salvage the mandatory fallback, and enforce discoverability through the marathon-cleanup skill plus a fail-closed pending-salvage index.
