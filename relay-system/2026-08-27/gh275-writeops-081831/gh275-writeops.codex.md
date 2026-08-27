**SINGLE-MODEL — NOT RECONCILED** (only codex answered; 1 of 2 requested advisor(s) failed — this is one model's read, not a cross-model consult. Do not treat any claim below as cross-verified.)

**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.6-sol
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
2026-08-27T15:18:32.254804Z ERROR codex_models_manager::cache: failed to load models cache: missing field `base_instructions` at line 98 column 5
OpenAI Codex v0.144.6
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-54680-c807n60b
model: gpt-5.6-sol
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 01a043cd-243b-70d2-9ce2-16f22625e28f
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
Review the implementation plan below (GitHub issue #275 in this repo) for medium-level logging of agent disk-write/teardown commands. The full issue body follows after the questions.

Context to verify against actual repo code:
- relay-automation/hooks/gh527-destructive-git-guard.sh (existing PreToolUse guard the plan sits beside)
- utils/py/marathon_drive.py lines ~97-160 (the XYZ_DEBUG_LOG Sentinel JSONL contract the plan reuses)
- relay-automation/xyz-sync.sh line ~359 (the rm -rf teardown site)
- utils/py/relay_drive.py / utils/py/marathon_drive.py worktree remove sites

Questions:
1. Is the 3-checkbox plan sound and genuinely minimal, or is anything over-built / under-built for a "medium level" logging goal?
2. Sharper seam choices: is a separate user-level PreToolUse hook the right seam, or should the existing gh527 guard be extended instead? Trade-offs?
3. What's missing that would bite in practice? (hook JSON parsing pitfalls, ~/.zshenv inheritance assumptions, multi-machine log sync, concurrent append safety, debug.log landing inside repos vs. home dir)
4. Pattern-list gaps in the destructive-command regex family (rm -rf, git worktree remove/prune, git clean, git branch -D, git reset --hard, xyz-sync delete)?
5. Is the skip list right (eslogger/Endpoint Security, codex/agy internal execs, log rotation)?

Be concrete; cite file:line where you disagree. Advisory only — propose, don't edit.

--- ISSUE #275 BODY ---
## Goal

Medium-level durable logging of the **disk-write commands agents execute** — worktree teardowns, clone deletions, `rm -rf`, destructive git — across Claude Code and the harnesses, so "what deleted that?" has an answer with a timestamp. Not full exec auditing; a receipts trail for destructive writes.

## Recon (grounded, each point directly observed 2026-08-27 — not inferred)

**Where agent disk-writes actually originate, and what already sees them:**

| Chokepoint | Coverage today |
|---|---|
| Claude Code Bash tool (the dominant agent surface) | PreToolUse hooks demonstrably intercept every command — `gh177-sandbox-test-guard.sh` and `gh527-destructive-git-guard.sh` fired on this session's own calls. GH-527's guard **already parses the command JSON and regex-matches destructive git patterns** (`reset --hard`, `checkout --`, `stash`, `clean`) — it snapshots, but does not log non-git teardowns. |
| Harness drivers (`relay_drive.py` / `marathon_drive.py`) | `git worktree remove` sites exist; the Sentinel JSONL journal (`XYZ_DEBUG_LOG=1`, `marathon_drive.py:97-160`) defines the exact timestamped record shape and swallow-errors contract, but is opt-in and not armed at teardown sites. |
| `xyz-sync.sh:359` | The one `rm -rf` that deletes vendored installs. Unlogged. |
| codex/agy CLI internals | Shims already bound their writes (containment reverts off-lane edits; `CODEX_LOG`/`AGY_LOG` per-PID). Internal execs invisible — accepted gap. |
| Interactive terminal | `.zsh_history` now timestamped (`EXTENDED_HISTORY`, verified live) — but captures **only human typing**; every agent shell is non-interactive and writes nothing there. This gap is what motivates this issue. |
| macOS system level | True every-exec capture requires Endpoint Security (`eslogger exec`) — heavyweight, noisy, out of scope for "medium". |

## Plan (ponytail pass — extend existing seams, build nothing new)

- [ ] **1. One new PreToolUse hook, user-level (`~/.claude/`): `write-ops-log.sh` (~25 lines).** Reads the same tool-call JSON GH-527's guard already parses; regex-matches the teardown family (`rm -rf`, `git worktree remove|prune`, `git clean`, `git branch -D`, `git reset --hard`, `xyz-sync.sh delete`); appends one Sentinel-shape JSONL line (`timestamp`, cwd, matched pattern, full command) to `~/.claude/write-ops.jsonl`. Never blocks, never fails the call (mirror the XYZ_DEBUG_LOG swallow-errors contract). User-level placement covers **every repo and session on the Mac**, not just XYZ-forge.
- [ ] **2. Harness teardown sites: arm the journal that already exists.** `export XYZ_DEBUG_LOG=1` in `~/.zshenv` (inherits into all non-interactive shells), plus `xyz_debug_log_append(...)` calls at the driver worktree-remove sites and an echo-append at `xyz-sync.sh:359` (~10 lines total). Both machines.
- [ ] **3. One registered test**: hook emits a line for `git worktree remove`, stays silent for `ls`; harness append fires at a fixture teardown.

Skipped, with re-entry triggers: **eslogger/Endpoint Security daemon** (add only when a forensic question the two logs can't answer actually occurs); **codex/agy internal-exec capture** (containment + shim logs bound the blast radius; revisit if an unattributed deletion appears with no hook/journal line); **log rotation** (single JSONL; revisit past ~10MB).

Est: under an hour of work, zero new dependencies, two files touched + one hook file added.

-Reviewed by Fable 5 (ponytail pass; recon grounded in-session)

## Turn-taker coverage clarification (all harness CLIs: aider, DeepSeek, CommandCode, codex, agy)

Layer 2 covers **all turn-takers identically**: worktree creation/teardown, clone hygiene, and `xyz-sync` deletes are performed by the *drivers* (`relay-drive`/`marathon-drive`/jog), never by the CLIs themselves — so the journal lines fire the same whether the turn is aider, DeepSeek (gh148 shim), CommandCode, codex, or agy. The `~/.zshenv` export inherits into every non-interactive shell, so any XYZ-system invocation is armed.

What is NOT logged: commands those CLIs run *internally* during turns. That gap is structurally **bounded rather than watched** — turns execute in isolated worktrees under the `ALLOW_PATHS` containment contract, and off-lane writes are reverted and fail the turn (GH-441 mechanism). The one true residual blind spot: a CLI writing *outside* the repo with an absolute path (e.g. in `$HOME`) — only the Endpoint Security tier sees that, which is exactly the skipped item's re-entry trigger below.

Layer 1 additionally logs the *launch* of every drive from a Claude Code session, giving each harness run a timestamped start record that ties journal lines back to a session.

## Overhead note

Negligible on SSD/NVMe. The hook appends one ~200-byte line only on matched destructive patterns (a handful per day); the journal appends small JSONL lines per harness event, not per I/O operation. The measurable cost is the hook's process spawn per Bash tool call (single-digit ms against commands that run seconds-to-minutes), not disk. No fsync in the append path; best-effort writes that swallow their own errors, per the existing Sentinel contract.

hook: SessionStart
hook: SessionStart Completed
codex
I’m using the consult workflow because this is explicitly a one-shot cross-model review. I’ll inspect the cited implementation seams and return an independent, line-grounded verdict only.
exec
/bin/zsh -lc "sed -n '1,240p' '/Users/noelsaw/Documents/GH Repos/XYZ-forge/skills/consult/SKILL.md' && sed -n '1,220p' WORKTREE-SAFETY.md && sed -n '1,240p' ROUTER.md && sed -n '1,220p' GUIDING-PRINCIPLES.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-54680-c807n60b
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

# ROUTER.md

This file is the first entry point for an AI agent working in this repo: it tells you what to read, what to run, and which files are canonical.

## Role split

- `ROUTER.md` = startup order and canonical entry points
- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof
- `README.md` = human-facing repo/product overview
- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh`)
- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip (GH-169/GH-243) — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file
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
3. Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.)
4. Read the linked `PROJECT/**` document that owns the work you are touching. -> expect the near-top `## Status` table to tell you what was just completed and what is next.
5. If the task touches project docs, read `PROJECT/PDDA.md` and follow the PDDA contract. -> expect `PROJECT/2-WORKING` docs to have frontmatter, the exact status table, and QA gates when phased.
6. Before reporting success on code or runtime work, run `./validate.sh`. -> expect the suite to stay green; do not claim completion if it fails or was skipped.
7. Before reporting success on doc-hygiene or roadmap work, run `utils/pdda/pdda.sh run` (or the relevant `utils/pdda/pdda.sh <check>` subcommand). -> expect deterministic findings first, then any LLM review.

## Canonical rules

- Do not put phase checklists, build steps, or deep execution notes in the roadmap ledger.
- Every active doc in `PROJECT/2-WORKING/` must be reflected by a pointer row in the roadmap ledger (the RELEASES DB) that links it. A working doc that should not appear opts out with `roadmap_exempt: true` in its frontmatter. (`utils/pdda/pdda.sh roadmap-coverage` still checks the legacy `ROADMAP.md` text — repointing it to the DB is tracked in #169's blast-radius list.) Governance lives in `PROJECT/PDDA.md` → "ROADMAP.md contract".
- Promoting a capture from `1-INBOX` to `2-WORKING` is a DB-verb procedure (`roadmap repoint` + `roadmap update`), never a `ROADMAP.md` edit — the exact steps and their two known gate traps (`updated:` frontmatter key, bullet-format `raw_text`) live in `SOP.md` → "Step 1b: Promoting a capture from 1-INBOX to 2-WORKING (releases-mode)".
- Every captured GitHub issue doc in `PROJECT/1-INBOX/GH-*.md` must also be parked as a queue row immediately at intake — `python3 utils/py/releases_app.py roadmap add --issue-num N --issue-url U --title T --created YYYY-MM-DD --doc-path P` (or `hq park`, which routes there automatically in this repo) — then promoted or removed later. Governance lives in `PROJECT/PDDA.md` → "GitHub issue intake" + "ROADMAP.md contract".
- Do not create a second competing plan when a canonical `PROJECT/**` doc already exists.
- Issue-first: any change beyond a **2–3 line** fix opens a GitHub issue first, then a pointer doc **named after the issue** (`GH-<number>-VERY-SHORT-DESC.md`, e.g. `GH-1234-SHOWME-COMMAND.md`), and that capture is **parked in the roadmap ledger immediately** (`releases roadmap add`) before execution begins. The issue is the signal stream; the pointer doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt. Governed by `PROJECT/PDDA.md` → "GitHub issue intake".
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
python3 utils/py/releases_app.py roadmap add ... # GH-238: park one issue as a roadmap row (the intake write path)
                                                #   GH-249: put `rated N/N/N/N [ovr N]` in --raw-text to score it
python3 utils/py/releases_app.py roadmap rate ...# GH-253: score a row that is ALREADY parked (--force to re-score)
python3 utils/py/releases_app.py roadmap list   # read the roadmap rows (--json for machine consumers)
python3 utils/py/releases_app.py roadmap sync   # LEGACY-mode only (mirrors ROADMAP.md); a guarded no-op in this repo
```

**Subsystem 1 — releases** (GH-32, Phase 0 side-by-side): the release ledger. App-managed writes
only; `RELEASES.md` is still the human file during the shadow phase.
**Subsystem 2 — the roadmap ledger** (GH-69 shadow → GH-238/GH-243 canonical): since the
`ROADMAP_SOURCE=releases` flip, `roadmap_items` IS the ledger — write rows with
`releases roadmap add` (or `hq park`), read with `roadmap list` / `ROADMAP-DASHBOARD.md`, and
never edit `ROADMAP.md` (frozen legacy). `roadmap sync` exists for legacy-mode repos only and
no-ops here by design (it would delete `add`-parked rows). Pinned by `test/gh69-roadmap-shadow.sh`
and `test/gh238-hq-releases-mode.sh`.

## Routing hints

- If the task is about current priorities or active work, start in `ROADMAP-DASHBOARD.md` (or `releases roadmap list`), then follow the linked `PROJECT/**` doc.
- If the task changes the roadmap ledger, write through the CLI (`releases roadmap add` for intake; `hq park` routes there automatically) and finish by regenerating `ROADMAP-DASHBOARD.md` (`utils/roadmap-dashboard.sh`) — the push gate refuses a ledger write with a stale dashboard (GH-243).
- If the task touches `releases.db`, `releases.sql`, or a merge conflict on either, start in [RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md); writes go through the CLI, never a hand-edit.
- If the task is about fresh GitHub intake or duplicate-prevention, start in the dashboard's queue section (or `releases roadmap list`), then follow the linked `PROJECT/1-INBOX/GH-*.md` capture doc.
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
- Issue-first SOP: any change beyond a 2–3 line fix (and every project plan) opens a GitHub issue *first*, then gets a pointer doc named after the issue at `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md` — e.g. `GH-1234-SHOWME-COMMAND.md` — and that capture is parked in the roadmap ledger queue immediately via `releases roadmap add` (format + lifecycle owned by `PROJECT/PDDA.md` → "GitHub issue intake"), following the normal `1-INBOX` → `2-WORKING` flow. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt and commit directly.
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
The repository graph lookup is unavailable in this consult sandbox, so I’m falling back to targeted, read-only source inspection. The key bet I’m testing is whether the proposed “one shared journal” actually preserves its existing contract and covers every teardown path without creating a second policy engine.
exec
/bin/zsh -lc "git status --short && nl -ba relay-automation/hooks/gh527-destructive-git-guard.sh | sed -n '1,260p' && nl -ba utils/py/marathon_drive.py | sed -n '75,180p' && nl -ba relay-automation/xyz-sync.sh | sed -n '320,390p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-54680-c807n60b
2026-08-27T15:19:12.890083Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
 succeeded in 4119ms:
2026-08-27 08:19:09.523 xcodebuild[57232:408771431]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-27 08:19:09.944 xcodebuild[57232:408771428] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-e3Ll1Yg3' (errno=Operation not permitted)
2026-08-27 08:19:10.810 xcodebuild[57335:408771741]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-27 08:19:11.102 xcodebuild[57335:408771738] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
?? PROJECT/1-INBOX/GH-254-PREVIEW-DRAFT-SORT.md
?? relay-automation/dummy-agent.sh
?? relay-system/2026-08-26/gh258-259-qa.md
?? relay-system/2026-08-27/gh275-writeops-081831/
?? scratch/
     1	#!/usr/bin/env bash
     2	#
     3	# gh527-destructive-git-guard.sh — PreToolUse guard: before a git command that
     4	# overwrites the working tree from a committed state runs, snapshot the tracked
     5	# files it is about to destroy so a peer's uncommitted work is recoverable.
     6	#
     7	# The incident this closes (GH-527, three times in ONE session on 2026-08-12): a
     8	# git HISTORY command was used to undo a WORKING-TREE experiment.
     9	#   1. `git stash` tree-wide took four other sessions' files, then timed out
    10	#      BEFORE its pop.
    11	#   2. `git checkout -- <path>` restored HEAD rather than the pre-mutation state
    12	#      and ate ~60 lines of the author's own new tests.
    13	#   3. `git reset --hard origin/development` took four sessions' tracked
    14	#      modifications plus .claude/settings.json, which never came back.
    15	#
    16	# Blast radius was REPRODUCED in a fixture rather than inferred: TRACKED
    17	# modifications are destroyed; untracked files survive. That is why this guard
    18	# keys on tracked dirt only — the dangerous case is exactly the one a peer agent
    19	# produces most often (editing a file that already exists), and snapshotting
    20	# untracked files too would be noise that hides the signal.
    21	#
    22	# SHAPE: snapshot-then-allow, NOT refuse-when-dirty. This is the shape the repo
    23	# already chose for this same problem — rtl_check copies an off-allowlist edit
    24	# into .tick/orphan-backups/ before reverting it (GH-141), precisely so a
    25	# wrongly-caught edit stays recoverable. Refusing instead would fire on every
    26	# legitimate solo-session cleanup and train an override reflex, and an override
    27	# that is always used is not a guard.
    28	#
    29	# WHY A HOOK AND NOT A DOC RAIL: GH-527 falsified the doc-rail proposal against
    30	# the session's own ledger — every mechanical guard (frozen-twin, path-integrity,
    31	# the SIGPIPE detector) caught the author; neither written warning did. The rail
    32	# in AGENTS.md is the explanation; this is the fix.
    33	#
    34	# ALWAYS EXITS 0. This guard snapshots, it does not block — the destructive
    35	# command still runs. Set XYZ_NO_GIT_SNAPSHOT=1 to disable.
    36	#
    37	# Known limits, stated rather than implied: command text is matched with regexes
    38	# over shell-separated segments, so execution nested inside $(...) or dispatched
    39	# via xargs is not seen; and a snapshot only covers files, not staged index state.
    40	
    41	[ "${XYZ_NO_GIT_SNAPSHOT:-0}" = "1" ] && exit 0
    42	
    43	payload="$(cat 2>/dev/null || true)"
    44	[ -n "$payload" ] || exit 0
    45	
    46	printf '%s' "$payload" | python3 -c '
    47	import json, os, re, subprocess, sys, time
    48	
    49	try:
    50	    ev = json.load(sys.stdin)
    51	except Exception:
    52	    sys.exit(0)
    53	
    54	if ev.get("tool_name") != "Bash":
    55	    sys.exit(0)
    56	
    57	cmd = (ev.get("tool_input") or {}).get("command") or ""
    58	if not cmd:
    59	    sys.exit(0)
    60	
    61	# The three shapes GH-527 Part A names, plus clean and the modern restore/switch spellings.
    62	#
    63	# MATCH BROADLY ON PURPOSE. An agy review of the first draft found that
    64	# `git checkout <path>` — no `--` — slipped a narrower regex entirely, and that is the
    65	# single most likely spelling an agent reaches for to revert a file. Verified: it misses,
    66	# and it destroys (a peer edit went back to HEAD). `git restore <path>` slipped too and was
    67	# not in the review either; it is the modern spelling of the same operation.
    68	#
    69	# Over-matching is CHEAP here and that is a property of the chosen shape, not an accident:
    70	# this guard snapshots and always allows, so a false positive costs one directory copy of
    71	# already-dirty files and nothing else. A false NEGATIVE costs a peer their uncommitted work.
    72	# The clean-tree early exit below keeps the noise at zero for the common safe case, so the
    73	# broad match never fires on a tidy tree.
    74	SHAPES = [
    75	    ("reset --hard", re.compile(r"\bgit\b.*\breset\b.*--hard\b")),
    76	    ("checkout",     re.compile(r"\bgit\b.*\bcheckout\b")),
    77	    ("restore",      re.compile(r"\bgit\b.*\brestore\b")),
    78	    ("switch",       re.compile(r"\bgit\b.*\bswitch\b.*(-f\b|--force|--discard-changes)")),
    79	    ("stash",        re.compile(r"\bgit\b\s+stash\b(?!\s+(list|show|apply|pop|drop|branch))")),
    80	    ("clean",        re.compile(r"\bgit\b.*\bclean\b.*(-[a-zA-Z]*f|--force)")),
    81	]
    82	
    83	shape = None
    84	for seg in re.split(r"&&|\|\||;|\|", cmd):
    85	    seg = seg.strip()
    86	    if not seg:
    87	        continue
    88	    for name, rx in SHAPES:
    89	        if rx.search(seg):
    90	            shape = name
    91	            break
    92	    if shape:
    93	        break
    94	
    95	if not shape:
    96	    sys.exit(0)
    97	
    98	
    99	def git(args, cwd):
   100	    try:
   101	        p = subprocess.run(["git"] + args, cwd=cwd, capture_output=True,
   102	                           text=True, timeout=15)
   103	        return p.returncode, p.stdout
   104	    except Exception:
   105	        return 1, ""
   106	
   107	
   108	cwd = ev.get("cwd") or os.getcwd()
   109	rc, top = git(["rev-parse", "--show-toplevel"], cwd)
   110	if rc != 0 or not top.strip():
   111	    sys.exit(0)
   112	root = top.strip()
   113	
   114	# WHICH SET IS AT RISK DEPENDS ON THE SHAPE, and getting this wrong makes the guard useless
   115	# for one of them. `reset --hard`, `checkout`, `restore` and `stash` destroy TRACKED
   116	# modifications and leave untracked files alone — reproduced in GH-527s own fixture, which is
   117	# why the default is tracked-only.
   118	#
   119	# `git clean` is the exact inverse: it deletes UNTRACKED files and does not touch tracked
   120	# modifications. The first draft matched `clean` but still snapshotted only tracked files, so
   121	# it announced a snapshot that contained nothing the command was about to delete — worse than
   122	# not matching at all, because the message implied cover that did not exist. Caught by an agy
   123	# review. For `clean` the untracked set IS the at-risk set.
   124	include_untracked = (shape == "clean")
   125	rc, status = git(["status", "--porcelain",
   126	                  "--untracked-files=" + ("normal" if include_untracked else "no")], root)
   127	if rc != 0:
   128	    sys.exit(0)
   129	
   130	paths = []
   131	for line in status.splitlines():
   132	    if len(line) > 3:
   133	        code = line[:2]
   134	        p = line[3:].strip()
   135	        if " -> " in p:
   136	            p = p.split(" -> ", 1)[1]
   137	        # For clean, only the untracked entries are at risk; for everything else, only the
   138	        # tracked ones. Mixing them would snapshot files the command will not touch.
   139	        is_untracked = code == "??"
   140	        if include_untracked != is_untracked:
   141	            continue
   142	        paths.append(p.strip(chr(34)))
   143	
   144	# Clean tree: nothing to lose. The guard MUST stay silent here — a guard that
   145	# fires on the safe case is a blanket, and GH-527 asks for a control proving it
   146	# does not fire on a clean tree for exactly that reason.
   147	if not paths:
   148	    sys.exit(0)
   149	
   150	stamp = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
   151	leaf = "%s-gh527-%d" % (stamp, os.getpid())
   152	
   153	# WHERE the snapshot goes depends on the shape, because for `clean` the obvious location is
   154	# self-defeating. `.tick/orphan-backups/` is the GH-141 precedent and is correct for
   155	# reset/checkout/restore/stash, none of which touch ignored or untracked directories.
   156	#
   157	# `git clean` does. Observed directly while testing recovery rather than assuming it: the guard
   158	# snapshotted the doomed untracked file into `.tick/`, then `git clean -fd` deleted `.tick/` as
   159	# well, and the recovery step found nothing. In this repo `.tick/` is gitignored so a plain
   160	# `-fd` spares it — but `git clean -fdx` removes ignored files too, and a guard that only works
   161	# against some flags of the command it names is not a guard.
   162	#
   163	# So `clean` snapshots OUTSIDE the repo entirely. Less discoverable, which is why the path is
   164	# printed; correct under every flag combination, which matters more.
   165	if include_untracked:
   166	    base = os.environ.get("TMPDIR") or "/tmp"
   167	    dest = os.path.join(base, "gh527-clean-snapshots", leaf)
   168	else:
   169	    dest = os.path.join(root, ".tick", "orphan-backups", leaf)
   170	
   171	saved = 0
   172	failed = []
   173	for rel in paths:
   174	    src = os.path.join(root, rel)
   175	    if not os.path.isfile(src):
   176	        continue
   177	    dst = os.path.join(dest, rel)
   178	    try:
   179	        os.makedirs(os.path.dirname(dst), exist_ok=True)
   180	        fh = open(src, "rb")
   181	        data = fh.read()
   182	        fh.close()
   183	        out = open(dst, "wb")
   184	        out.write(data)
   185	        out.close()
   186	        saved += 1
   187	    except Exception as exc:
   188	        # A swallowed copy failure was the worst defect in the first draft, found by an agy
   189	        # review: a full disk or a permission error left the guard exiting 0 in silence, so
   190	        # the operator got no snapshot AND no warning, while the destructive command ran
   191	        # anyway. A guard that fails quietly is worse than no guard, because the absence of a
   192	        # message is read as "nothing was at risk".
   193	        failed.append((rel, exc.__class__.__name__))
   194	
   195	# An absolute path for the out-of-repo clean snapshot; a repo-relative one otherwise, which is
   196	# what a reader of .tick/orphan-backups/ expects to see.
   197	where = dest if include_untracked else os.path.relpath(dest, root)
   198	kind = "untracked" if include_untracked else "tracked"
   199	
   200	if saved:
   201	    sys.stderr.write(
   202	        "gh527-guard: %s is about to destroy %d %s file(s).\n" % (shape, saved, kind))
   203	    sys.stderr.write("gh527-guard: snapshot saved -> %s\n" % where)
   204	    sys.stderr.write("gh527-guard: recover with: cp -R \"%s\"/. .\n" % where)
   205	    if include_untracked:
   206	        sys.stderr.write(
   207	            "gh527-guard: (kept OUTSIDE the repo — git clean -x would have deleted an "
   208	            "in-repo snapshot)\n")
   209	
   210	if failed:
   211	    # Loud, and it names what is unprotected rather than only that something went wrong.
   212	    sys.stderr.write(
   213	        "gh527-guard: WARNING — %d file(s) could NOT be snapshotted and are UNPROTECTED:\n"
   214	        % len(failed))
   215	    for rel, err in failed[:10]:
   216	        sys.stderr.write("gh527-guard:   %s (%s)\n" % (rel, err))
   217	    sys.stderr.write(
   218	        "gh527-guard: the command was NOT blocked (this guard never blocks) — if you need "
   219	        "those files, copy them by hand before continuing.\n")
   220	
   221	sys.exit(0)
   222	'
   223	exit 0
    75	    release because it exercised the parser from a FILE, which is not how the driver ran it. Running
    76	    in-process kills the whole failure class, and keeping it importable means a test can exercise the
    77	    real function rather than a reimplementation of it.
    78	    """
    79	    try:
    80	        payload = json.loads(payload_text)
    81	    except Exception:
    82	        payload = []
    83	    comments = []
    84	    if isinstance(payload, list):
    85	        for entry in payload:
    86	            if isinstance(entry, list):
    87	                comments.extend(entry)
    88	            elif isinstance(entry, dict):
    89	                comments.append(entry)
    90	    for comment in comments:
    91	        if isinstance(comment, dict) and marker in str(comment.get("body", "")):
    92	            return str(comment.get("id", ""))
    93	    return ""
    94	
    95	# ── Sentinel Tier 1 (GH-281), ported to the lane that runs (GH-342) ──────────────────────────
    96	# marathon-drive.sh carried this capture; Python is the default lane since GH-264, so arming
    97	# XYZ_DEBUG_LOG=1 on a normal run wrote nothing. Contract preserved exactly, including the parts
    98	# that make it safe to leave in a public repo:
    99	#   · opt-in, DEFAULT OFF — an unset/0 XYZ_DEBUG_LOG must not create the file at all
   100	#   · writes ONE local file ($DEBUG_LOG_FILE, default $ROOT/debug.log) — no network, no telemetry
   101	#   · NEVER fails the run: every write is best-effort and swallows its own errors
   102	# Module scope, not nested in main(), so the record shape is directly testable (the GH-322
   103	# runlog_find_comment_id precedent — a helper reachable only through a full driven run is a helper
   104	# whose format contract is asserted by nothing).
   105	_JSON_CTRL_RE = re.compile(r'[\x00-\x1f\x7f]')
   106	
   107	
   108	def _json_esc(value):
   109	    """Bash `_json_esc`: normalize all C0/DEL controls to a space, then escape backslash + quote.
   110	
   111	    Mirrors `printf '%s' "$s" | tr '\\000-\\037\\177' ' '` — a byte-for-byte translation, so a
   112	    multi-byte UTF-8 sequence is untouched (Python operates on code points; `tr` on bytes; the
   113	    ranges here are all < 0x80, where the two agree).
   114	    """
   115	    return _JSON_CTRL_RE.sub(" ", "" if value is None else str(value)) \
   116	        .replace("\\", "\\\\").replace('"', '\\"')
   117	
   118	
   119	def xyz_debug_log_enabled():
   120	    """The single gate. Read at call time, not import time, so a test can arm it per-case."""
   121	    return os.environ.get("XYZ_DEBUG_LOG", "0") == "1"
   122	
   123	
   124	def xyz_debug_log_file(root):
   125	    """`: "${DEBUG_LOG_FILE:=$ROOT/debug.log}"` — an explicitly EMPTY value falls back too."""
   126	    return os.environ.get("DEBUG_LOG_FILE") or os.path.join(root, "debug.log")
   127	
   128	
   129	def _xyz_debug_log_write(root, line):
   130	    """Append one line, swallowing everything. Mirrors `>> "$f" 2>/dev/null || true`."""
   131	    try:
   132	        with open(xyz_debug_log_file(root), "a") as fh:
   133	            fh.write(line)
   134	    except Exception:
   135	        pass
   136	
   137	
   138	def xyz_debug_log_append(root, severity, check, message,
   139	                         file="", action="", probe="",
   140	                         target_root=None, phase_id=None, relay_task=None):
   141	    """Append ONE PDDA-output-contract JSONL finding. No-op unless XYZ_DEBUG_LOG=1.
   142	
   143	    Field order and the empty `line` field are load-bearing: this file is consumed by the Sentinel
   144	    tooling as a fixed record shape, and the Bash lane emits exactly this. Built with a format
   145	    string rather than json.dumps for the same reason — json.dumps would escape correctly but is
   146	    free to differ on separators, and the two lanes must produce identical bytes.
   147	    """
   148	    if not xyz_debug_log_enabled():
   149	        return
   150	    scope = f"target:{target_root}" if target_root else "harness"
   151	    _xyz_debug_log_write(root, (
   152	        '{"timestamp":"%s","severity":"%s","check":"%s","scope":"%s","repo":"%s","phase":"%s"'
   153	        ',"task":"%s","file":"%s","line":"","message":"%s","action":"%s","probe":"%s"}\n'
   154	    ) % (
   155	        _utc_now_z(),
   156	        _json_esc(severity), _json_esc(check), _json_esc(scope),
   157	        _json_esc(target_root or root), _json_esc(phase_id or ""), _json_esc(relay_task or ""),
   158	        _json_esc(file), _json_esc(message), _json_esc(action), _json_esc(probe),
   159	    ))
   160	
   161	
   162	def xyz_debug_log_stale_lock(root):
   163	    """The stale-lock reclaim record.
   164	
   165	    Deliberately NOT routed through xyz_debug_log_append: `marathon-drive.sh:220` inlines a SHORTER
   166	    record here (no phase/task/file/line/probe) because the helper is not defined that early in the
   167	    Bash file, and it leaves `repo` unescaped. Reproduced as-is — the two lanes must agree, and
   168	    "improving" the shape on one lane only is how the drift this issue exists to fix gets recreated.
   169	    The inconsistent shape is worth fixing on BOTH lanes, separately and on purpose.
   170	    """
   171	    if not xyz_debug_log_enabled():
   172	        return
   173	    _xyz_debug_log_write(root, (
   174	        '{"timestamp":"%s","severity":"info","check":"marathon.stale-lock","scope":"harness"'
   175	        ',"repo":"%s","message":"stale driver lock reclaimed","action":"none (auto-healed)"}\n'
   176	    ) % (_utc_now_z(), root))
   177	
   178	
   179	def xyz_harvest_findings(harvest_bin, relay_file, root, target_root, debug_log):
   180	    """Spawn harvest-findings.sh to pull a relay's Side Findings into the debug log.
   320	  branch="$(git -C "$HARNESS_ROOT" branch --show-current 2>/dev/null || true)"
   321	  if [ -z "$branch" ] || ! is_canonical_update_branch "$branch"; then
   322	    die "refusing update: harness source branch '${branch:-detached}' is not canonical (${XYZ_SYNC_CANONICAL_BRANCHES:-main,development}); set XYZ_SYNC_ALLOW_UNSAFE_SOURCE=1 for an intentional override"
   323	  fi
   324	
   325	  dirty="$(git -C "$HARNESS_ROOT" status --porcelain --untracked-files=normal 2>/dev/null || true)"
   326	  if [ -n "$dirty" ]; then
   327	    die "refusing update: harness source is dirty; set XYZ_SYNC_ALLOW_UNSAFE_SOURCE=1 for an intentional override"
   328	  fi
   329	}
   330	
   331	delete_rows() {
   332	  local target confirmed i
   333	  target="${1:-}"
   334	  confirmed="${2:-0}"
   335	
   336	  if [ -z "$target" ]; then
   337	    die "delete requires <dir> or --all"
   338	  fi
   339	
   340	  if [ "$target" = "--all" ]; then
   341	    select_vendored_rows
   342	  else
   343	    select_vendored_rows "$target"
   344	  fi
   345	
   346	  require_selection "${target}" || return 0
   347	
   348	  if [ "$confirmed" -ne 1 ]; then
   349	    for ((i = 0; i < ${#SELECTED_INSTALL_DIRS[@]}; i++)); do
   350	      printf 'WOULD REMOVE %s\n' "${SELECTED_INSTALL_DIRS[$i]}"
   351	      printf 'WOULD PRUNE %s\n' "${SELECTED_INSTALL_DIRS[$i]}"
   352	    done
   353	    return 0
   354	  fi
   355	
   356	  for ((i = 0; i < ${#SELECTED_INSTALL_DIRS[@]}; i++)); do
   357	    safe_registered_xyz_dir "${SELECTED_INSTALL_DIRS[$i]}" || die "refusing to delete non-.xyz path: ${SELECTED_INSTALL_DIRS[$i]}"
   358	    if [ -e "${SELECTED_INSTALL_DIRS[$i]}" ]; then
   359	      rm -rf "${SELECTED_INSTALL_DIRS[$i]}"
   360	      note "removed ${SELECTED_INSTALL_DIRS[$i]}"
   361	    else
   362	      note "delete: missing on disk, pruning row: ${SELECTED_INSTALL_DIRS[$i]}"
   363	    fi
   364	  done
   365	
   366	  prune_registry_rows "${SELECTED_INSTALL_DIRS[@]}"
   367	  note "registry: pruned ${#SELECTED_INSTALL_DIRS[@]} row(s)"
   368	}
   369	
   370	# GH-96: report-only drift check. Compares each selected row's recorded (tick_version,
   371	# source_commit) against the CURRENT values this harness computes the same way register_vendor()
   372	# does. Mismatch on either field is drift; a match is silent/"ok". Never mutates the registry or
   373	# the install, never exits non-zero for drift -- this is a warning, not a gate.
   374	check_rows() {
   375	  local target i j cur_ver cur_commit rec_ver rec_commit drifted missing_guards guard_path guard_pattern
   376	
   377	  target="${1:-}"
   378	
   379	  if [ -z "$target" ]; then
   380	    die "check requires <dir> or --all"
   381	  fi
   382	
   383	  if [ "$target" = "--all" ]; then
   384	    select_vendored_rows
   385	  else
   386	    select_vendored_rows "$target"
   387	  fi
   388	
   389	  require_selection "${target}" || return 0
   390	

exec
/bin/zsh -lc "rg -n --no-heading 'worktree (remove|prune)|rm -rf|xyz_debug_log_append|XYZ_DEBUG_LOG|DEBUG_LOG_FILE' utils/py/relay_drive.py utils/py/marathon_drive.py relay-automation/xyz-sync.sh relay-automation/*.sh test relay-automation/hooks .claude/settings.json 2>/dev/null" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-54680-c807n60b
 succeeded in 0ms:
relay-automation/consult.sh:144:  git -C "$ROOT" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"
relay-automation/consult.sh:145:  git -C "$ROOT" worktree prune >/dev/null 2>&1 || true
relay-automation/claude-turn.sh:219:    [[ -n "$shadow_dir" ]] && rm -rf "$shadow_dir"; exit 5
relay-automation/claude-turn.sh:234:[[ -n "$shadow_dir" ]] && rm -rf "$shadow_dir"
utils/py/marathon_drive.py:97:# XYZ_DEBUG_LOG=1 on a normal run wrote nothing. Contract preserved exactly, including the parts
utils/py/marathon_drive.py:99:#   · opt-in, DEFAULT OFF — an unset/0 XYZ_DEBUG_LOG must not create the file at all
utils/py/marathon_drive.py:100:#   · writes ONE local file ($DEBUG_LOG_FILE, default $ROOT/debug.log) — no network, no telemetry
utils/py/marathon_drive.py:121:    return os.environ.get("XYZ_DEBUG_LOG", "0") == "1"
utils/py/marathon_drive.py:125:    """`: "${DEBUG_LOG_FILE:=$ROOT/debug.log}"` — an explicitly EMPTY value falls back too."""
utils/py/marathon_drive.py:126:    return os.environ.get("DEBUG_LOG_FILE") or os.path.join(root, "debug.log")
utils/py/marathon_drive.py:138:def xyz_debug_log_append(root, severity, check, message,
utils/py/marathon_drive.py:141:    """Append ONE PDDA-output-contract JSONL finding. No-op unless XYZ_DEBUG_LOG=1.
utils/py/marathon_drive.py:165:    Deliberately NOT routed through xyz_debug_log_append: `marathon-drive.sh:220` inlines a SHORTER
utils/py/marathon_drive.py:182:    Gated on XYZ_DEBUG_LOG=1 AND the script being executable, exactly as the two Bash call sites
utils/py/marathon_drive.py:746:            xyz_debug_log_append(
utils/py/marathon_drive.py:1419:            xyz_debug_log_append(
utils/py/marathon_drive.py:1658:        xyz_debug_log_append(
relay-automation/xyz-sync.sh:26:# the harness and swapping it in over `rm -rf`, so anything the target accumulated that is not
relay-automation/xyz-sync.sh:359:      rm -rf "${SELECTED_INSTALL_DIRS[$i]}"
relay-automation/finding-new.sh:17:OUT="${DEBUG_LOG_FILE:-$ROOT/debug.log}"
relay-automation/marathon-drive.sh:173:: "${XYZ_DEBUG_LOG:=0}"
relay-automation/marathon-drive.sh:174:: "${DEBUG_LOG_FILE:=$ROOT/debug.log}"
relay-automation/marathon-drive.sh:220:    if [[ "${XYZ_DEBUG_LOG:-0}" == "1" ]]; then
relay-automation/marathon-drive.sh:222:          "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$ROOT" >> "${DEBUG_LOG_FILE:-$ROOT/debug.log}"; } 2>/dev/null || true
relay-automation/marathon-drive.sh:224:    rm -rf "$_lock"
relay-automation/marathon-drive.sh:241:    rm -rf "$_lock" 2>/dev/null || true
relay-automation/marathon-drive.sh:462:# Sentinel Tier 1 (GH-281): append ONE PDDA-output-contract JSONL finding to $DEBUG_LOG_FILE.
relay-automation/marathon-drive.sh:463:# Opt-in (XYZ_DEBUG_LOG=1), default off. Writes only this one local file — no network, no
relay-automation/marathon-drive.sh:469:xyz_debug_log_append() {  # <severity> <check> <message> [file] [action] [probe]
relay-automation/marathon-drive.sh:470:  [[ "${XYZ_DEBUG_LOG:-0}" == "1" ]] || return 0
relay-automation/marathon-drive.sh:477:    >> "$DEBUG_LOG_FILE" 2>/dev/null || true
relay-automation/marathon-drive.sh:857:  if [[ "${XYZ_DEBUG_LOG:-0}" == "1" && -x "$HERE/harvest-findings.sh" ]]; then
relay-automation/marathon-drive.sh:860:      --out "${DEBUG_LOG_FILE:-$ROOT/debug.log}" >/dev/null 2>&1 || true
relay-automation/marathon-drive.sh:875:  xyz_debug_log_append error "marathon.escalation" "$reason (relay-drive-exit=$rexit)" \
relay-automation/marathon-drive.sh:889:  if [[ "${XYZ_DEBUG_LOG:-0}" == "1" && -x "$HERE/harvest-findings.sh" ]]; then
relay-automation/marathon-drive.sh:892:      --out "${DEBUG_LOG_FILE:-$ROOT/debug.log}" >/dev/null 2>&1 || true
relay-automation/marathon-drive.sh:1140:  xyz_debug_log_append warn "marathon.lane-park" "lane $LANE_STATE_KEY parked at attempt cap" \
relay-automation/relay-drive.sh:174:    rm -rf "$_lock"
relay-automation/relay-drive.sh:189:    rm -rf "$_lock" 2>/dev/null || true
relay-automation/relay-turn-lib.sh:701:  rm -rf "$wt"                         # git worktree add wants a non-existent path
relay-automation/relay-turn-lib.sh:703:    rm -rf "$wt" 2>/dev/null; return 1
relay-automation/relay-turn-lib.sh:723:      rm -rf "$wt/$a"                  # allowlisted path ALREADY deleted in the host tree → mirror the
relay-automation/relay-turn-lib.sh:854:        rm -rf "$_tmp"
relay-automation/relay-turn-lib.sh:859:          rm -rf "$RTL_ROOT/$a"
relay-automation/relay-turn-lib.sh:868:        rm -rf "$RTL_ROOT/$a"            # allowlisted path deleted in the worktree → propagate the deletion
relay-automation/relay-turn-lib.sh:874:  git -C "$RTL_ROOT" worktree remove --force "$wt" >/dev/null 2>&1 || rm -rf "$wt"
relay-automation/relay-turn-lib.sh:875:  git -C "$RTL_ROOT" worktree prune >/dev/null 2>&1 || true
relay-automation/relay-turn-lib.sh:1041:  # in the tree. ${RTL_ROOT:?} because rm -rf on an empty-prefix path would target /. — GH-567.
relay-automation/relay-turn-lib.sh:1043:    rm -rf "${RTL_ROOT:?}/.relay-scratch"
relay-automation/relay-turn-lib.sh:1068:  git -C "$RTL_ROOT" checkout -- "$p" 2>/dev/null || rm -rf "$RTL_ROOT/${p%/}"
relay-automation/relay-turn-lib.sh:1273:  [[ -d "${RTL_ROOT:?}/.relay-scratch" ]] && rm -rf "${RTL_ROOT:?}/.relay-scratch"
relay-automation/xyz-sync.sh:26:# the harness and swapping it in over `rm -rf`, so anything the target accumulated that is not
relay-automation/xyz-sync.sh:359:      rm -rf "${SELECTED_INSTALL_DIRS[$i]}"
relay-automation/xyz-releases-onboard.sh:90:    rm -rf "$STAGE_DIR"
relay-automation/xyz-vendor.sh:85:      rm -rf "$entry" 2>/dev/null || true
relay-automation/xyz-vendor.sh:91:    rm -rf "$STAGE_DIR"
relay-automation/xyz-vendor.sh:151:        rm -rf "$lockdir" 2>/dev/null || true
relay-automation/xyz-vendor.sh:163:    rm -rf "$lockdir" 2>/dev/null || true
relay-automation/xyz-vendor.sh:174:    rm -rf "$lockdir" 2>/dev/null || true
relay-automation/xyz-vendor.sh:349:  rm -rf "$STAGE_DIR"
relay-automation/xyz-vendor.sh:371:      rm -rf "$STAGE_DIR/$_overlay_item"
relay-automation/xyz-vendor.sh:389:  # $HARNESS_ROOT, and none of these paths are in VENDOR_DIRS, so the `rm -rf` below would delete
relay-automation/xyz-vendor.sh:406:    rm -rf "$STAGE_DIR/$_keep"
relay-automation/xyz-vendor.sh:411:  rm -rf "$VENDOR_DIR"
test/gh312-vendor-preserves-state.sh:5:#   rm -rf "$VENDOR_DIR"; mv "$STAGE_DIR" "$VENDOR_DIR"
relay-automation/hooks/gh177-sandbox-test-guard.sh:9:# destructive `rm -rf` EXIT trap wiped the working tree plus parts of `.git`.
relay-automation/hooks/gh177-sandbox-test-guard.sh:11:# "rm -rf"-shaped commands cannot catch it. This guard keys on the TRIGGER
test/relay-turn-handoff.sh:67:  rm -rf "$dir"
test/gh155-phase2-differential-oracle.sh:10:cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/sentinel-tier1.sh:13:trap 'rm -rf "$WORK"' EXIT
test/sentinel-tier1.sh:59:DEBUG_LOG_FILE="$MANUAL_LOG" "$FINDING_NEW" --scope "$ADV_SCOPE" --severity warn "$ADV_MSG" >/dev/null
test/releases-skill.sh:86:trap '[ -n "$TMP" ] && [ -d "$TMP" ] && rm -rf "$TMP"' EXIT
test/relay-file-seeding-visibility.sh:35:[ -n "$wt1" ] && { git -C "$A" worktree remove --force "$wt1" >/dev/null 2>&1 || rm -rf "$wt1"; git -C "$A" worktree prune >/dev/null 2>&1; }
test/relay-file-seeding-visibility.sh:55:[ -n "$wt2" ] && { git -C "$A" worktree remove --force "$wt2" >/dev/null 2>&1 || rm -rf "$wt2"; git -C "$A" worktree prune >/dev/null 2>&1; }
test/jog-queue.sh:46:    "${TMPDIR:-/tmp}"/jog-test.*) [ -d "$WORK" ] && rm -rf "$WORK" ;;
test/jog-queue.sh:177:rm -rf "$R/.git/relay-driver.lock"
test/gh430-state-dir-tracked-default.sh:20:W="${TMPDIR:-/tmp}/gh430-state-dir-test.$$"; rm -rf "$W"; mkdir -p "$W"
test/gh430-state-dir-tracked-default.sh:22:cleanup(){ rm -rf "$W"; for d in "${CREATED_DIRS[@]:-}"; do [ -n "$d" ] && rm -rf "$d"; done; }
test/gh425-source-url-slug.sh:12:trap 'rm -rf "$WORK"' EXIT
test/gh257-roadmap-ledger-fixes.sh:334:rm -rf "$GUARD_ROOT_DIR" 2>/dev/null || true
test/gh257-roadmap-ledger-fixes.sh:351:rm -rf "$GUARD_TMP"/staleness-guard.* 2>/dev/null || true
test/gh257-roadmap-ledger-fixes.sh:388:rm -rf "$GUARD_TMP"/staleness-guard.* "$GUARD_TMP"/staleness-guard.*.aside 2>/dev/null || true
test/gh419-gate-inventory.sh:8:trap 'rm -rf "$FIXTURE"' EXIT
test/improve-loop.sh:10:W="${TMPDIR:-/tmp}/improve-loop-test.$$"; rm -rf "$W"; mkdir -p "$W"
test/improve-loop.sh:11:trap 'rm -rf "$W"' EXIT
test/gh77-standup-triage.sh:41:    "${TMPDIR:-/tmp}"/gh77-standup.*) [ -d "$WORK" ] && rm -rf "$WORK" ;;
test/hq.sh:15:trap 'rm -rf "$TMP"' EXIT
test/security-scan.sh:34:trap 'rm -rf "$WORK"' EXIT
test/security-scan.sh:49:UNSANITIZED="rm -rf /"
test/gh557-unknown-blocks-manifest.sh:43:trap 'rm -rf "$WORK"' EXIT
test/gh35-test-tiers.sh:38:cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/gh35-test-tiers.sh:375:git -C "$R7" worktree remove --force "$WT45" >/dev/null 2>&1
test/gh438-removal-is-progress.sh:66:  rm -rf "$A/phases" "$A/.tick"; tick_a init >/dev/null 2>&1 || true
test/gh438-acceptance-recheck.sh:88:  rm -rf "$A/phases" "$A/.tick"; tick_a init >/dev/null 2>&1 || true
test/gh308-swarm-gate-path.sh:18:trap 'rm -rf "$WORK"' EXIT
test/gh308-frozen-twin-guard.sh:381:cleanup() { rm -rf "$tmp"; }
test/gh308-frozen-twin-guard.sh:415:cleanup_exc() { rm -rf "$exc"; }
test/gh527-destructive-git-guard.sh:73:rm -rf "$R"
test/gh527-destructive-git-guard.sh:124:rm -rf "$CSNAP" "$K"
test/gh527-destructive-git-guard.sh:138:rm -rf "$C"
test/gh232-wave-reconcile-multiphase.sh:16:cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/gh388-run-log-durability.sh:352:rm -rf "$A/relay-system/run-logs"
test/gh4-ungated-clone-warning.sh:22:trap 'rm -rf "$W"' EXIT
test/lane-attempt-cap.sh:10:trap 'rm -rf "$WORK"' EXIT
test/gh142-ate-exit-contract.sh:22:trap '[ -n "$WORK" ] && [ -d "$WORK" ] && rm -rf "$WORK"' EXIT
test/marathon-closeout.sh:17:trap 'rm -rf "$WORK"' EXIT
test/gh91-relay-scratch.sh:27:trap 'rm -rf "$WORK"' EXIT
test/agent-chorus.sh:21:trap 'rm -rf "$WORK"' EXIT
test/agent-chorus.sh:524:RACE_RC="$WORK/race-rcs"; rm -rf "$RACE_RC"; mkdir -p "$RACE_RC"
test/gh544-pre-push-gate.sh:33:cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/gh544-pre-push-gate.sh:351:git -C "$R_P" worktree remove --force "$WORK/wt-probe" >/dev/null 2>&1
test/gh544-pre-push-gate.sh:459:cleanup_victim(){ [ -n "${VICTIM_ROOT:-}" ] && [ -d "$VICTIM_ROOT" ] && rm -rf "$VICTIM_ROOT"; }
test/gh418-issue-state-frozen.sh:17:trap 'rm -rf "$WORK"' EXIT
test/hq-promote.sh:20:# root), so the EXIT trap below then rm -rf'd the entire repository — twice (2026-07-07, 2026-07-17).
test/hq-promote.sh:27:trap 'rm -rf "$TMP"' EXIT
test/gh390-timeout-attribution.sh:16:trap 'rm -rf "$TMP"' EXIT
test/gh528-parallel-contention-retry.sh:97:trap '_rc=$?; rm -f "$VP" "$VP2" "$ROOT/test/$PROBE_NAME" "$ROOT/test/$SWALLOWER_NAME" "$ROOT/test/$VICTIM_NAME"; rm -rf "$WORK"; if [ "${TEST_SOFT_FAIL:-0}" = "1" ] && [ "${FAIL:-0}" -gt 0 ]; then exit 1; fi; exit "$_rc"' EXIT
test/gh528-parallel-contention-retry.sh:187:trap '_rc=$?; rm -f "$VP" "$VP2" "$VP3" "$ROOT/test/$PROBE_NAME" "$ROOT/test/$SWALLOWER_NAME" "$ROOT/test/$VICTIM_NAME" "$ROOT/test/$KILLER_NAME"; rm -rf "$WORK"; if [ "${TEST_SOFT_FAIL:-0}" = "1" ] && [ "${FAIL:-0}" -gt 0 ]; then exit 1; fi; exit "$_rc"' EXIT
test/gh2-orphan-backup-repro.sh:26:    "${TMPDIR:-/tmp}"/gh2-orphan-backup.*) rm -rf "$WORK" ;;
test/ate-run-variations.sh:22:trap 'rm -rf "$WORK"' EXIT
test/gh183-explorer-env-soundness.sh:13:cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/gh342-sentinel-debug-log-python.sh:5:# The gap this pins: XYZ_DEBUG_LOG=1 was honored only by relay-automation/marathon-drive.sh, which
test/gh342-sentinel-debug-log-python.sh:19:#   5  robustness: an unwritable DEBUG_LOG_FILE raises nothing and changes no exit code
test/gh342-sentinel-debug-log-python.sh:30:unset XYZ_DEBUG_LOG
test/gh342-sentinel-debug-log-python.sh:31:unset DEBUG_LOG_FILE
test/gh342-sentinel-debug-log-python.sh:42:py_has 'os.environ.get("XYZ_DEBUG_LOG", "0") == "1"' \
test/gh342-sentinel-debug-log-python.sh:43:  && pass "1a: opt-in gate reads XYZ_DEBUG_LOG (default off)" || fail "1a: XYZ_DEBUG_LOG gate missing"
test/gh342-sentinel-debug-log-python.sh:44:py_has 'def xyz_debug_log_append(' \
test/gh342-sentinel-debug-log-python.sh:45:  && pass "1b: append helper defined" || fail "1b: xyz_debug_log_append missing"
test/gh342-sentinel-debug-log-python.sh:72:assert "xyz_debug_log_append" in esc, f"escalate() does not append a finding: {sorted(esc)}"
test/gh342-sentinel-debug-log-python.sh:77:assert "xyz_debug_log_append" in gate, f"lane_attempt_gate() does not emit lane-park: {sorted(gate)}"
test/gh342-sentinel-debug-log-python.sh:103:    os.environ.pop("XYZ_DEBUG_LOG", None)
test/gh342-sentinel-debug-log-python.sh:105:        os.environ["XYZ_DEBUG_LOG"] = val
test/gh342-sentinel-debug-log-python.sh:106:    md.xyz_debug_log_append(root, "error", "marathon.escalation", "must not be written")
test/gh342-sentinel-debug-log-python.sh:111:        ok(f"2: XYZ_DEBUG_LOG {label} — debug.log not created at all")
test/gh342-sentinel-debug-log-python.sh:113:        bad(f"2: XYZ_DEBUG_LOG {label} wrote {os.path.getsize(log)} bytes to debug.log")
test/gh342-sentinel-debug-log-python.sh:114:os.environ.pop("XYZ_DEBUG_LOG", None)
test/gh342-sentinel-debug-log-python.sh:117:os.environ["XYZ_DEBUG_LOG"] = "1"
test/gh342-sentinel-debug-log-python.sh:119:md.xyz_debug_log_append(
test/gh342-sentinel-debug-log-python.sh:157:md.xyz_debug_log_append(root, "warn", "marathon.lane-park", "m", target_root="/tmp/other")
test/gh342-sentinel-debug-log-python.sh:164:# DEBUG_LOG_FILE override, including the empty-value fallback
test/gh342-sentinel-debug-log-python.sh:168:os.environ["DEBUG_LOG_FILE"] = alt
test/gh342-sentinel-debug-log-python.sh:169:md.xyz_debug_log_append(root, "info", "c", "m")
test/gh342-sentinel-debug-log-python.sh:170:ok("3g: DEBUG_LOG_FILE honored") if os.path.exists(alt) else bad("3g: DEBUG_LOG_FILE ignored")
test/gh342-sentinel-debug-log-python.sh:171:os.environ["DEBUG_LOG_FILE"] = ""
test/gh342-sentinel-debug-log-python.sh:172:md.xyz_debug_log_append(root, "info", "c", "m")
test/gh342-sentinel-debug-log-python.sh:174:    ok("3h: an EMPTY DEBUG_LOG_FILE falls back to $ROOT/debug.log (Bash `:=` semantics)")
test/gh342-sentinel-debug-log-python.sh:176:    bad("3h: empty DEBUG_LOG_FILE did not fall back")
test/gh342-sentinel-debug-log-python.sh:177:os.environ.pop("DEBUG_LOG_FILE", None)
test/gh342-sentinel-debug-log-python.sh:188:    ["sed", "-n", r"/^_json_esc()/,/^}/p; /^xyz_debug_log_append()/,/^}/p", sh_twin],
test/gh342-sentinel-debug-log-python.sh:191:if b"xyz_debug_log_append" not in extract.stdout:
test/gh342-sentinel-debug-log-python.sh:207:        env = dict(os.environ, XYZ_DEBUG_LOG="1", DEBUG_LOG_FILE=sh_log,
test/gh342-sentinel-debug-log-python.sh:211:             f'source "{helpers}"; xyz_debug_log_append "$1" "$2" "$3" "$4" "$5" "$6"',
test/gh342-sentinel-debug-log-python.sh:214:        os.environ["DEBUG_LOG_FILE"] = py_log
test/gh342-sentinel-debug-log-python.sh:215:        md.xyz_debug_log_append(root, sev, chk, msg, file=f_, action=act, probe=prb,
test/gh342-sentinel-debug-log-python.sh:217:        os.environ.pop("DEBUG_LOG_FILE", None)
test/gh342-sentinel-debug-log-python.sh:230:os.environ["DEBUG_LOG_FILE"] = os.path.join(root, "no", "such", "dir", "debug.log")
test/gh342-sentinel-debug-log-python.sh:232:    md.xyz_debug_log_append(root, "error", "c", "m")
test/gh342-sentinel-debug-log-python.sh:234:    ok("5a: an unwritable DEBUG_LOG_FILE raises nothing (best-effort append)")
test/gh342-sentinel-debug-log-python.sh:241:    os.environ["DEBUG_LOG_FILE"] = os.path.join(ro, "debug.log")
test/gh342-sentinel-debug-log-python.sh:243:        md.xyz_debug_log_append(root, "error", "c", "m")
test/gh342-sentinel-debug-log-python.sh:251:os.environ.pop("DEBUG_LOG_FILE", None)
test/gh342-sentinel-debug-log-python.sh:261:os.environ.pop("XYZ_DEBUG_LOG", None)
test/gh342-sentinel-debug-log-python.sh:264:    ok("6a: harvest NOT spawned when XYZ_DEBUG_LOG is unset")
test/gh342-sentinel-debug-log-python.sh:268:os.environ["XYZ_DEBUG_LOG"] = "1"
test/gh342-sentinel-debug-log-python.sh:287:os.environ.pop("XYZ_DEBUG_LOG", None)
test/gh342-sentinel-debug-log-python.sh:320:run_md() {  # run_md <XYZ_DEBUG_LOG value or empty> [XYZ_PYTHON value]
test/gh342-sentinel-debug-log-python.sh:322:  rm -rf "$LOCK"; mkdir -p "$LOCK"; printf '999999\n' >"$LOCK/pid"   # 999999: not a live pid
test/gh342-sentinel-debug-log-python.sh:324:  env ${dbg:+XYZ_DEBUG_LOG="$dbg"} ${pyflag:+XYZ_PYTHON="$pyflag"} \
test/gh342-sentinel-debug-log-python.sh:325:      DEBUG_LOG_FILE="$DBG" MARATHON_ROOT="$A" TICK_BIN="$TICK" \
test/gh342-sentinel-debug-log-python.sh:371:rm -rf "$LOCK"
test/gh181-repro-adapter-fidelity.sh:13:cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/gh384-crash-recovery.sh:195:rm -rf "$lockdir"
test/hq-marathon-live.sh:16:trap 'rm -rf "$WORK"' EXIT
test/gh448-driver-lock-resolver.sh:31:# GH-177: guard BEFORE the re-capture below and BEFORE the rm -rf trap is armed. A failed mktemp
test/gh448-driver-lock-resolver.sh:33:# script's own cwd — the repository root — straight into `rm -rf`. That is the historical repo-wipe
test/gh448-driver-lock-resolver.sh:49:trap 'rm -rf "$WORK"' EXIT
test/gh448-driver-lock-resolver.sh:156:rm -rf "$COMMON_LOCK"
test/hq-park.sh:17:TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
test/gh1-adoption-guard.sh:33:cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/sentinel-network-guard.sh:15:trap 'rm -rf "$WORK"' EXIT
test/swarm-preflight.sh:18:trap 'rm -rf "$WORK"' EXIT
test/gh358-lock-instrumentation.sh:9:trap 'rm -rf "$WORK"' EXIT
test/roadmap-dashboard.sh:41:trap 'rm -rf "$TMP_ROOT"' EXIT
test/_setup.sh:62:trap '_rc=$?; rm -rf "$WORK"; if [ "${TEST_SOFT_FAIL:-0}" = "1" ] && [ "${FAIL:-0}" -gt 0 ]; then exit 1; fi; exit "$_rc"' EXIT
test/_setup.sh:88:rm -rf "$SEED"
test/gh492-idle-kill.sh:24:trap 'rm -rf "$WORK"' EXIT
test/gh103-timeline-exporter.sh:59:cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/gh218-synthetic-nested-driver-lock.sh:61:  rm -rf "$LOCK"
test/hq-locator.sh:20:# root), so the EXIT trap below then rm -rf'd the entire repository — twice (2026-07-07, 2026-07-17).
test/hq-locator.sh:27:trap 'rm -rf "$TMP"' EXIT
test/gh400-source-url.sh:30:trap 'rm -rf "$WORK"' EXIT
test/hq-dispatch.sh:14:TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
test/hq-marathon-scan.sh:15:trap 'rm -rf "$WORK"' EXIT
test/gh491-gate-only-refire.sh:51:reset_state() { rm -rf "$A/phases" "$A/.tick"; tick_a init >/dev/null 2>&1 || true; : > "$RD_CALLS"; }
test/verdict-edge.sh:27:A="$WORK/handoff"; rm -rf "$A"
test/verdict-edge.sh:44:B="$WORK/open"; rm -rf "$B"
test/verdict-edge.sh:58:C="$WORK/scope"; rm -rf "$C"
test/verdict-edge.sh:74:D="$WORK/clamp"; rm -rf "$D"
test/marathon-plan.sh:17:trap 'rm -rf "$WORK"' EXIT
test/gh39-releases-project-sync.sh:19:cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/gh369-find-doc-root-resolution.sh:82:trap 'rm -rf "$TMP"' EXIT
test/gh422-backfill-source-url.sh:32:trap 'rm -rf "$WORK"' EXIT
test/marathon.sh:71:rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
test/marathon.sh:85:rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
test/marathon.sh:105:rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
test/marathon.sh:124:rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
test/marathon.sh:138:rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
test/marathon.sh:146:rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
test/marathon.sh:196:rm -f "$WORK/rd-resume-count"; rm -rf "$A/.tick" "$A/phases" "$A/marathon-system"; rm -f "$A/src/gh205.js"
test/marathon.sh:223:rm -f "$WORK/rd-hang-count"; rm -rf "$A/.tick" "$A/phases" "$A/marathon-system"; rm -f "$A/src/gh205-hang.js"
test/marathon.sh:274:rm -f "$WORK/vendored-drive-ran"; rm -rf "$V/.tick"
test/marathon.sh:297:rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
test/marathon.sh:309:rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
test/marathon.sh:318:rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
test/marathon.sh:329:rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
test/signal-triage.sh:42:trap 'rm -rf "$WORK"' EXIT
test/gh168-wave-reconcile-scope.sh:15:cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/gh467-index-only-lane-blocked.sh:12:trap 'rm -rf "$WORK"' EXIT
test/hq-park-synthesis.sh:15:TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
test/hq-park-synthesis.sh:87:rm -rf "$BETA/PROJECT" "$BETA/.tick"; mkdir -p "$BETA/PROJECT/1-INBOX"
test/hq-park-synthesis.sh:96:rm -rf "$BETA/PROJECT"; mkdir -p "$BETA/PROJECT/1-INBOX"
test/find-harness.sh:63:rm -rf "$FR"
test/find-harness.sh:73:rm -rf "$FV"
test/find-harness.sh:84:rm -rf "$FC"
test/find-harness.sh:96:rm -rf "$FVC"
test/find-harness.sh:105:rm -rf "$FN"
test/find-harness.sh:114:rm -rf "$FS"
test/improve-loop-qa.sh:16:W="${TMPDIR:-/tmp}/il-qa.$$"; rm -rf "$W"; mkdir -p "$W"
test/improve-loop-qa.sh:17:trap 'rm -rf "$W"' EXIT
test/gh50-sandboxed-git-guard.sh:31:  [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"
test/gh155-phase4-self-healer.sh:10:cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/gh32-release-target-advisory.sh:37:    "${TMPDIR:-/tmp}"/gh32-target-adv.*) [ -d "$WORK" ] && rm -rf "$WORK" ;;
test/ballast-release.sh:285:  trap 'rm -rf "$TMP"' EXIT
test/gh155-phase3-repro-builder.sh:10:cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/gh1-fixture-guard.sh:29:cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/driver-lock.sh:31:[ ! -e "$LOCK" ] && pass "lock released on clean exit" || { fail "lock leaked after run"; rm -rf "$LOCK"; }
test/driver-lock.sh:38:rm -rf "$LOCK"
test/gh387-gate-not-first-executor.sh:33:trap 'rm -rf "$WORK"' EXIT
test/gh387-gate-not-first-executor.sh:115:  rm -rf "$A/.tick" "$A/marathon-system" "$A/phases"; rm -f "$A/src/gh387.js"
test/gh387-gate-not-first-executor.sh:174:rm -rf "$A/.tick" "$A/marathon-system" "$A/phases"; rm -f "$A/src/gh387.js"
test/xyz-completion.sh:28:trap 'rm -rf "$WORK"' EXIT
test/gh90-allowlist-directory.sh:30:trap 'rm -rf "$WORK"' EXIT
test/gh385-retry-token-satisfied.sh:67:reset_state() { rm -rf "$A/phases" "$A/.tick"; tick_a init >/dev/null 2>&1 || true; : > "$RD_CALLS"; }
test/gh245-agy-probe-verb-invariant.sh:116:  trap 'rm -rf "$CTL"' EXIT
test/gh292-worktree-vendored-discovery.sh:12:# GH-177: $WORK is `rm -rf`'d by the EXIT trap below, so it must be proven a real,
test/gh292-worktree-vendored-discovery.sh:26:  git -C "$MAIN" worktree remove --force "$LINKED" >/dev/null 2>&1 || true
test/gh292-worktree-vendored-discovery.sh:27:  rm -rf "$WORK"
test/gh255-remedy-ordering.sh:24:trap 'rm -rf "$WORK"' EXIT
test/gh182-healer-facade-safety.sh:10:cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/gh113-headless-scratch.sh:23:trap 'rm -rf "$WORK"' EXIT
test/gh155-phase1-metamorphic-invariants.sh:10:cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/gh69-roadmap-shadow.sh:32:    "${TMPDIR:-/tmp}"/gh69-shadow.*) [ -d "$WORK" ] && rm -rf "$WORK" ;;
test/deep-research.sh:13:trap 'rm -rf "$WORK"' EXIT
test/registry-lock-concurrency.sh:9:# fresh lock stale and rm -rf'd it, defeating mutual exclusion -> a lost row. This test drives many
test/registry-lock-concurrency.sh:56:rm -rf "$TMP"
test/nightwatch-release.sh:212:  trap 'rm -rf "$TMP"' EXIT
test/champion.sh:10:D="${TMPDIR:-/tmp}/champion-test.$$"; rm -rf "$D"
test/champion.sh:11:trap 'rm -rf "$D"' EXIT
test/champion.sh:39:Dm="${TMPDIR:-/tmp}/champion-min.$$"; rm -rf "$Dm"
test/champion.sh:45:rm -rf "$Dm"
test/gh400-acceptance-fidelity.sh:30:trap 'rm -rf "$WORK"' EXIT
test/relay-dep-drift.sh:66:rm -rf "$D"
test/relay-dep-drift.sh:93:rm -rf "$D2"
test/gh417-turn-root-symlink-prefix.sh:54:  rm -rf "$base"; mkdir -p "$base/phys/repo"
test/gh407-gate-ran-attribution.sh:169:rm -rf "$PRE_ROOT/phases"
test/relay-self-sufficiency.sh:66:trap 'rm -rf "$WORK"' EXIT
test/sentinel-driver-hooks.sh:3:#   #1 default-off: the append helper writes nothing when XYZ_DEBUG_LOG is unset or 0.
test/sentinel-driver-hooks.sh:15:trap 'rm -rf "$WORK"' EXIT
test/sentinel-driver-hooks.sh:18:# driver's main body). The functions reference ROOT/TARGET_ROOT/PHASE_ID/RELAY_TASK/DEBUG_LOG_FILE.
test/sentinel-driver-hooks.sh:19:sed -n '/^_json_esc()/,/^}/p; /^xyz_debug_log_append()/,/^}/p' "$DRIVE" > "$WORK/helpers.sh"
test/sentinel-driver-hooks.sh:20:grep -q 'xyz_debug_log_append' "$WORK/helpers.sh" || { echo "FAIL: could not extract helpers" >&2; exit 1; }
test/sentinel-driver-hooks.sh:23:LOG="$WORK/debug.log"; DEBUG_LOG_FILE="$LOG"
test/sentinel-driver-hooks.sh:28:unset XYZ_DEBUG_LOG 2>/dev/null || true
test/sentinel-driver-hooks.sh:29:xyz_debug_log_append error marathon.escalation "should not be written"
test/sentinel-driver-hooks.sh:31:XYZ_DEBUG_LOG=0 xyz_debug_log_append error marathon.escalation "still off"
test/sentinel-driver-hooks.sh:32:[[ ! -e "$LOG" ]] || { echo "FAIL: XYZ_DEBUG_LOG=0 wrote to debug.log" >&2; exit 1; }
test/sentinel-driver-hooks.sh:35:export XYZ_DEBUG_LOG=1
test/sentinel-driver-hooks.sh:36:xyz_debug_log_append error "marathon.escalation" "$(printf 'no-progress\t"x" \\y')" "phases/p1/RELAY.md" "promote"
test/sentinel-driver-hooks.sh:51:  ': "${XYZ_DEBUG_LOG:=0}"'                            # (0) opt-in default
test/sentinel-driver-hooks.sh:52:  'xyz_debug_log_append() {'                           # (1) append helper
test/sentinel-driver-hooks.sh:53:  'xyz_debug_log_append error "marathon.escalation"'   # (2) escalation hook
test/gh304-vendored-relay-path.sh:79:[ -n "$wt" ] && { git -C "$A" worktree remove --force "$wt" >/dev/null 2>&1 || rm -rf "$wt"; git -C "$A" worktree prune >/dev/null 2>&1; }
test/gh399-packet-acceptance-continuation.sh:31:trap 'rm -rf "$WORK"' EXIT
test/gh57-live-merge-resolve.sh:44:    "${TMPDIR:-/tmp}"/gh57-live.*) [ -d "$WORK" ] && rm -rf "$WORK" ;;
test/improve-loop-dogfood.sh:17:W="${TMPDIR:-/tmp}/il-dogfood.$$"; rm -rf "$W"; mkdir -p "$W"
test/improve-loop-dogfood.sh:18:trap 'rm -rf "$W"' EXIT
test/checkjs.sh:26:trap 'rm -rf "$WORK"' EXIT
test/gh233-agent-chorus-concurrency.sh:28:trap 'rm -rf "$WORK"' EXIT
test/gh308-consult-guards.sh:19:trap 'rm -rf "$WORK"' EXIT
test/gh184-no-tracked-scratch.sh:13:cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/hq-rollup.sh:23:trap 'rm -rf "$WORK"' EXIT
test/gh174-harness-registry.sh:10:cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/consult.sh:51:rm -rf "$OUT"
test/consult.sh:68:rm -rf "$OUT"
test/consult.sh:87:rm -rf "$OUT"
test/consult.sh:100:rm -rf "$OUT"
test/consult.sh:114:rm -rf "$OUT"
test/consult.sh:135:rm -rf "$OUT"
test/consult.sh:150:rm -rf "$OUT"
test/consult.sh:169:rm -rf "$OUT"
test/consult.sh:178:rm -rf "$OUT"
test/consult.sh:184:rm -rf "$OUT"
test/consult.sh:200:rm -rf "$OUT"
test/consult.sh:223:rm -rf "$OUT"
test/consult.sh:244:rm -rf "$OUT"
test/consult.sh:262:rm -rf "$OUT"
test/consult.sh:293:rm -rf "$OUT"
test/consult.sh:316:rm -rf "$OUT"
test/consult.sh:334:rm -rf "$OUT"
test/gh343-gate-program-target-root.sh:12:trap 'rm -rf "$WORK"' EXIT
test/mktemp-trap-guard.sh:4:# test/mktemp-trap-guard.sh — GH-177 regression guard: static audit for the pattern that rm -rf'd
test/mktemp-trap-guard.sh:11:# repo root itself. Wiring that into `trap 'rm -rf "$VAR"' EXIT` then deletes the repo on exit.
test/mktemp-trap-guard.sh:13:# there, VAR is simply empty, and `rm -rf ""` is a confirmed-safe no-op (verified empirically — it
test/rtl-orphan-backup.sh:27:trap 'rm -rf "$WORK"' EXIT
test/gh153-releases-sidebar-rollup.sh:31:trap 'rm -rf "$WORK"' EXIT
test/hq-next.sh:13:TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
test/sentinel-overlay.sh:18:trap 'rm -rf "$WORK"' EXIT
test/gh536-evidence-detail.sh:76:rm -rf "$R"
test/gh536-evidence-detail.sh:88:rm -rf "$R2"
test/gh536-evidence-detail.sh:100:rm -rf "$R3"
test/gh536-evidence-detail.sh:109:rm -rf "$LOGS"
test/acorn-extract.sh:15:trap 'rm -rf "$WORK"' EXIT
test/marathon-drive.sh:102:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:111:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:132:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:147:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:164:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:181:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:227:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:241:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:276:  rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:286:  rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:305:  rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:316:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:323:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:335:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:343:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:351:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:385:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:396:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:414:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:427:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:452:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:466:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:515:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:546:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:577:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:593:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:657:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:665:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:694:git -C "$A" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"
test/marathon-drive.sh:695:git -C "$A" worktree prune >/dev/null 2>&1 || true
test/marathon-drive.sh:696:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:706:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:732:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:748:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:762:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:776:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:1015:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:1027:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:1041:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:1063:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:1076:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/marathon-drive.sh:1096:rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
test/runner-loop.sh:141:  rm -rf "$WORK"
test/marathon-monitor.sh:31:rm -rf "$D"
test/marathon-monitor.sh:33:trap 'rm -rf "$D"' EXIT
test/marathon-monitor.sh:110:rm -rf "$REPO_GONE"
test/marathon-monitor.sh:127:rm -rf "$REPO_LEGACY/marathon-system"
test/gh155-phase5-active-explorer.sh:10:cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/gh202-wave-reconcile-issue-state.sh:16:cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/synthetic/gh129-relay-tick-root.sh:27:trap '[ -n "$WORK" ] && [ -d "$WORK" ] && rm -rf "$WORK"' EXIT
test/hq-hardening.sh:17:# root), so the EXIT trap below then rm -rf'd the entire repository — twice (2026-07-07, 2026-07-17).
test/hq-hardening.sh:24:trap 'rm -rf "$TMP"' EXIT
test/debug-mantra.sh:70:rm -rf "$A/phases" "$A/.tick"
test/debug-mantra.sh:101:rm -rf "$A/phases" "$A/.tick"
test/debug-mantra.sh:122:rm -rf "$A/phases" "$A/.tick"
test/debug-mantra.sh:131:rm -rf "$A/phases" "$A/.tick"
test/synthetic/gh94-containment-invariants.sh:10:trap 'rm -rf "$WORK"' EXIT
test/synthetic/gh131-marathon-target-root.sh:26:trap '[ -n "$WORK" ] && [ -d "$WORK" ] && rm -rf "$WORK"' EXIT
test/gh410-containment-advisory.sh:30:trap 'rm -rf "$WORK"' EXIT
test/meter-release.sh:396:  trap 'rm -rf "$work"' RETURN
test/meter-release.sh:481:  trap 'rm -rf "$TMP"' EXIT
test/meter-release.sh:558:  rm -rf "$FIX/relay-system"
test/synthetic/gh101-relay-programmatic-stress.sh:20:trap 'rm -rf "$WORK"' EXIT
test/synthetic/gh101-relay-programmatic-stress.sh:104:rm -rf .relay-scratch
test/test-agy-standalone-repo.sh:4:rm -rf /tmp/wt-test
test/transcript-audit.sh:25:trap 'rm -rf "$FIXTURE_DIR"' EXIT
test/swe-diagram.sh:21:trap 'rm -rf "$WORK"' EXIT
test/gh32-releases-app.sh:45:cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/xyz-harness-hooks.sh:159:reset_a() { rm -rf "$A/.tick" "$A/phases" "$A/relay-system"; git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true; }
test/fixtures/canary-token-reuse/verify-fixture.sh:22:cleanup() { rm -rf "$SCRATCH"; }
test/fixtures/canary-token-reuse/verify-fixture.sh:30:  rm -rf "$run"; mkdir -p "$run/.tick/events"
test/fixtures/canary-token-reuse/verify-fixture.sh:50:rm -rf "$CTLDIR"; mkdir -p "$CTLDIR"
test/gh57-releases-fuzz.sh:42:    "${TMPDIR:-/tmp}"/gh57-fuzz.*) [ -d "$WORK" ] && rm -rf "$WORK" ;;
test/gh376-relay-drive-lock-parity.sh:54:# GH-177: guard BEFORE the physical re-capture and BEFORE the rm -rf trap is armed. A failed mktemp
test/gh376-relay-drive-lock-parity.sh:56:# straight into `rm -rf`. Same shape (and the same `&& exit 1` inside the braces, which the scanner
test/gh376-relay-drive-lock-parity.sh:64:trap 'rm -rf "$WORK"' EXIT
test/gh376-relay-drive-lock-parity.sh:104:  rm -rf "$1"; mkdir -p "$1"
test/gh376-relay-drive-lock-parity.sh:115:trap 'release_lock; rm -rf "$WORK"' EXIT
test/gh376-relay-drive-lock-parity.sh:245:rm -rf "$VEND/.git"
test/synthetic/gh124-closeout-suite.sh:11:trap 'rm -rf "$WORK"' EXIT
test/synthetic/gh124-closeout-suite.sh:89:# Execute sweep -> worktree removed
test/synthetic/gh124-closeout-suite.sh:146:git -C "$LOCAL_MAIN" worktree remove --force "$DETACHED_WT" >/dev/null 2>&1 || rm -rf "$DETACHED_WT"
test/gh180-repro-timeout-crash.sh:12:cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
test/synthetic/gh102-telemetry-schema.sh:17:trap 'rm -rf "$WORK"' EXIT
test/synthetic/gh130-agy-auth-whoami.sh:22:trap '[ -n "$WORK" ] && [ -d "$WORK" ] && rm -rf "$WORK"' EXIT
test/synthetic/gh101-consult-programmatic.sh:21:trap 'rm -rf "$WORK"' EXIT
test/fixtures/canary-reviewer-overstep/verify-fixture.sh:27:cleanup() { rm -rf "$SC"; }
test/fixtures/canary-reviewer-overstep/verify-fixture.sh:36:rm -rf "$SC"
test/gh379-claude-builder-diagnosis.sh:68:rm -rf "$ROOT/phases/p2" "$ROOT/relay-system/logs/2026-08-15/claude-turn-MARATHON-P2-TURN-*.log"
test/fixtures/canary-peer-orphan/verify-fixture.sh:22:cleanup() { rm -rf "$SC"; }
test/fixtures/canary-peer-orphan/verify-fixture.sh:33:rm -rf "$SC"

2026-08-27T15:19:20.794029Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "rg -n --no-heading 'worktree|remove|prune|rmtree|unlink' utils/py/relay_drive.py utils/py/marathon_drive.py | head -n 240 && nl -ba utils/py/relay_drive.py | sed -n '1,220p' && nl -ba utils/py/marathon_drive.py | sed -n '700,780p;1380,1445p;1625,1685p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-54680-c807n60b
 succeeded in 0ms:
utils/py/relay_drive.py:131:    # documented `cd "$HARNESS"`, is `.xyz/`, a subdir of the true repo root the turn-taker's worktree
utils/py/relay_drive.py:132:    # checks out. A CWD-relative string then resolves wrong from the worktree root and the relay fails
utils/py/relay_drive.py:139:    # mismatch discards a BUILD turn's Log after full cost. Under --target-root the turn's worktree is
utils/py/relay_drive.py:202:            try: os.remove(attempts_file)
utils/py/relay_drive.py:258:            eprint("  RELAY_WORKTREE_ISOLATION=1 runs the turn-taker in a worktree at HEAD, but its own")
utils/py/relay_drive.py:259:            eprint("  worktree-seeding step copies this file's current content in regardless — this is")
utils/py/relay_drive.py:265:            eprint("  usual worktree-seeding fallback does NOT cover it — it may be genuinely INVISIBLE to")
utils/py/relay_drive.py:278:            eprint("relay-drive: WARNING — --artifact-file needs worktree isolation to seed the artifact; with RELAY_WORKTREE_ISOLATION=0 the reviewer will not see it.")
utils/py/relay_drive.py:362:    def relay_is_worktree_artifact_path(candidate):
utils/py/relay_drive.py:373:        worktree_root = get_env("RELAY_TARGET_ROOT")
utils/py/relay_drive.py:374:        if not worktree_root:
utils/py/relay_drive.py:376:                worktree_root = subprocess.check_output(
utils/py/relay_drive.py:380:                worktree_root = root_dir
utils/py/relay_drive.py:381:            if not worktree_root:
utils/py/relay_drive.py:382:                worktree_root = root_dir
utils/py/relay_drive.py:384:            worktree_root = os.path.realpath(worktree_root) if os.path.isdir(worktree_root) else worktree_root
utils/py/relay_drive.py:393:                if not relay_is_worktree_artifact_path(candidate):
utils/py/relay_drive.py:398:                    resolved = os.path.join(worktree_root, candidate)
utils/py/relay_drive.py:400:                    die(f"artifact path not found in worktree: {candidate}")
utils/py/relay_drive.py:421:        # lock beside the scripts) with no case for a linked worktree, where .git is a FILE. That
utils/py/relay_drive.py:457:                shutil.rmtree(lock_dir)
utils/py/relay_drive.py:469:        # runs FIRST, then the lock is removed. Skipped entirely when nested (RELAY_DRIVER_LOCKED=1):
utils/py/relay_drive.py:473:            try: shutil.rmtree(lock_dir)
utils/py/relay_drive.py:655:            os.remove(cv_prompt_file)
utils/py/marathon_drive.py:366:    `root` while phase_dir stays inside root's worktree — byte-identical to the pre-#131
utils/py/marathon_drive.py:769:            try: os.remove(attempts_file)
utils/py/marathon_drive.py:837:        # worktree .git is a FILE pointing at the shared gitdir, so resolve the real common dir and put
utils/py/marathon_drive.py:839:        # the worktree. A vendored .xyz/ copy (no .git) falls back to a hidden lock beside the scripts.
utils/py/marathon_drive.py:870:            # the finding survives even if the rmtree/mkdir below fails and the run exits 1.
utils/py/marathon_drive.py:873:                shutil.rmtree(lock_dir)
utils/py/marathon_drive.py:884:            try: shutil.rmtree(lock_dir)
utils/py/marathon_drive.py:1059:                    os.unlink(tmp)
utils/py/marathon_drive.py:1069:            os.remove(driver_heartbeat_path())
utils/py/marathon_drive.py:2003:            try: os.remove(tmp_brief)
utils/py/marathon_drive.py:2649:                os.remove(reason_file)
utils/py/marathon_drive.py:2666:        # GH-256: under --target-root the turn shim must GUARD the repo the worktree is cut FROM.
utils/py/marathon_drive.py:2672:        # worktree was the target, the per-artifact seed check resolved every path against the
utils/py/marathon_drive.py:2673:        # wrong root and found nothing, and the agent got a worktree without its own files.
     1	import argparse
     2	import os
     3	import sys
     4	import subprocess
     5	import time
     6	import re
     7	import shutil
     8	import pathlib
     9	from contextlib import contextmanager
    10	
    11	# GH-376: resolve the driver lock through the ONE shared resolver rather than reimplementing it.
    12	# Imported relative to this file (utils/py/), independent of CWD/PYTHONPATH — some callers load this
    13	# module via importlib.util.spec_from_file_location rather than `python3 <path>`, which does NOT put
    14	# the script's own directory on sys.path. Same pattern, and the same reason, as marathon_drive.py:19.
    15	sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    16	from rtl import driver_lock_path, resolve_turn_root  # noqa: E402
    17	
    18	def eprint(*args, **kwargs):
    19	    print(*args, file=sys.stderr, **kwargs)
    20	
    21	def get_env(key, default=None):
    22	    return os.environ.get(key, default)
    23	
    24	def die(msg):
    25	    eprint(f"relay-drive: {msg}")
    26	    sys.exit(2)
    27	
    28	def main():
    29	    parser = argparse.ArgumentParser(description="relay-drive", add_help=False)
    30	    parser.add_argument("--relay-file", dest="relay_file")
    31	    parser.add_argument("--agent-cmd", dest="agent_cmd")
    32	    parser.add_argument("--relay-task", dest="relay_task", default="RELAY-TURN")
    33	    parser.add_argument("--round-cap", dest="round_cap", type=int, default=6)
    34	    parser.add_argument("--target-root", dest="target_root")
    35	    parser.add_argument("--consult-verify", dest="consult_verify", action="store_true")
    36	    parser.add_argument("--artifact-file", dest="artifact_file")
    37	    parser.add_argument("--review-once", dest="review_once", action="store_true")
    38	    parser.add_argument("--force", dest="force", action="store_true")
    39	    parser.add_argument("--dry-run", dest="dry_run", action="store_true")
    40	    parser.add_argument("--tool-mode", dest="tool_mode", default=get_env("RELAY_TOOL_MODE", "standard"), choices=["standard", "programmatic"])
    41	    parser.add_argument("--help", action="store_true")
    42	    
    43	    args, unknown = parser.parse_known_args()
    44	    if args.help:
    45	        print("Usage: relay-automation/relay-drive.sh --relay-file PATH --agent-cmd CMD [options]")
    46	        sys.exit(0)
    47	
    48	    # GH-322: `unknown` was captured and never read, so ANY unrecognised flag was silently
    49	    # discarded. Because Python is the executing lane (GH-264), that made `--log-github` — the
    50	    # headline feature of GH-284 Phase 2, which exists only in the Bash twin — a no-op: the marathon
    51	    # ran, exited 0, reported success, and never posted a run log. All three Bash twins `die
    52	    # "unknown argument: $1"`; this restores that contract byte-for-byte (same prefix, same exit 2).
    53	    # Checked AFTER --help so `--help` still works alongside a bad flag.
    54	    if unknown:
    55	        die(f"unknown argument: {unknown[0]}")
    56	
    57	    if not args.relay_file:
    58	        die("--relay-file is required")
    59	    if not args.agent_cmd and not args.dry_run:
    60	        die("--agent-cmd is required")
    61	
    62	    if args.tool_mode == "programmatic":
    63	        has_sandbox = bool(shutil.which("sandbox-exec") or shutil.which("bwrap"))
    64	        if not has_sandbox:
    65	            die("Containment failure (fail-closed): OS sandbox backend (sandbox-exec or bwrap) unavailable for --tool-mode programmatic")
    66	        os.environ["XYZ_TOOL_MODE"] = "programmatic"
    67	        os.environ["RELAY_TOOL_MODE"] = "programmatic"
    68	
    69	    if args.review_once:
    70	        args.round_cap = 1
    71	
    72	    here = os.path.dirname(os.path.abspath(__file__))
    73	    # ROOT_DIR is the harness root, not necessarily git root.
    74	    # We are in utils/py, so ROOT_DIR is the parent of utils
    75	    root_dir = os.path.abspath(os.path.join(here, "..", ".."))
    76	
    77	    tick_bin = get_env("TICK_BIN", os.path.join(root_dir, "bin", "tick"))
    78	    consult_sh = get_env("CONSULT_SH", os.path.join(root_dir, "relay-automation", "consult.sh"))
    79	    xyz_append_bin = get_env("XYZ_APPEND_BIN", os.path.join(root_dir, "utils", "telemetry", "append-xyz-completion.sh"))
    80	
    81	    # GH-331 (mirrors relay-drive.sh GH-152): auto-surface the `tick analyze` cost block at end-of-run
    82	    # so a driven run stops needing a manual `tick analyze` pull to see what it cost. This lived only in
    83	    # the Bash twin, so on the default Python lane (GH-264) it never ran — zero end-of-run cost
    84	    # visibility. Only fires once a turn was actually about to be driven (cost_summary_state["started"]
    85	    # — never on --help/usage/lock-contention/lane-parked/--dry-run exits), opts out with
    86	    # RELAY_COST_SUMMARY=0, and is best-effort: a failed/forced `tick analyze` is swallowed so it can
    87	    # NEVER change the driven run's own exit code (wired into the same atexit as the lock cleanup;
    88	    # atexit does not alter the process exit status).
    89	    cost_summary_state = {"started": False}
    90	
    91	    def xyz_relay_cost_summary():
    92	        if not cost_summary_state["started"]:
    93	            return
    94	        if get_env("RELAY_COST_SUMMARY", "1") == "0":
    95	            return
    96	        try:
    97	            report = subprocess.check_output([tick_bin, "analyze", "--format", "human"],
    98	                                             stderr=subprocess.DEVNULL).decode("utf-8")
    99	        except Exception:
   100	            eprint("relay-drive: tick analyze failed — end-of-run cost summary unavailable (RELAY_COST_SUMMARY=0 to silence)")
   101	            return
   102	        # Extract from the '--- cost ---' line to EOF (matches `sed -n '/^--- cost ---$/,$p'`).
   103	        block_lines = []
   104	        capturing = False
   105	        for ln in report.splitlines():
   106	            if ln == "--- cost ---":
   107	                capturing = True
   108	            if capturing:
   109	                block_lines.append(ln)
   110	        if not block_lines:
   111	            return
   112	        eprint("\nrelay-drive: end-of-run cost summary (tick analyze) —\n" + "\n".join(block_lines))
   113	
   114	    if args.target_root:
   115	        try:
   116	            subprocess.run(["git", "-C", args.target_root, "rev-parse", "--show-toplevel"], 
   117	                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
   118	        except subprocess.CalledProcessError:
   119	            die(f"invalid target root (not a git repo): {args.target_root}")
   120	        os.environ["RELAY_TARGET_ROOT"] = args.target_root
   121	
   122	    # Resolve relay file path
   123	    relay_file = args.relay_file
   124	    if not os.path.isfile(relay_file) and args.target_root and not relay_file.startswith("/") and os.path.isfile(os.path.join(args.target_root, relay_file)):
   125	        relay_file = os.path.join(args.target_root, relay_file)
   126	    if not os.path.isfile(relay_file):
   127	        die(f"relay file does not exist: {relay_file}")
   128	
   129	    # GH-304: absolutize relay_file before it is exported to the turn-taker. As passed it is relative to
   130	    # the driver's CWD — which, for a same-repo vendored `.xyz/` install driven per the relay-xyz skill's
   131	    # documented `cd "$HARNESS"`, is `.xyz/`, a subdir of the true repo root the turn-taker's worktree
   132	    # checks out. A CWD-relative string then resolves wrong from the worktree root and the relay fails
   133	    # for Codex. An absolute path resolves identically from any CWD (see the Bash driver for the full
   134	    # rationale). Mirrors the artifact_file absolutization below.
   135	    if not relay_file.startswith("/"):
   136	        relay_file = os.path.abspath(relay_file)
   137	
   138	    # GH-289: a review turn (ALLOW_PATHS="") can only write the relay file; the same isolation-root
   139	    # mismatch discards a BUILD turn's Log after full cost. Under --target-root the turn's worktree is
   140	    # based on the TARGET repo, so if the relay file resolves OUTSIDE that target root the turn
   141	    # physically cannot append its findings (codex rejects the out-of-project write). Refuse fast at
   142	    # startup instead of spending the turn — this guard lived only in the Bash twin, so on the default
   143	    # Python lane the build turn ran and discarded its Log after full cost (see relay-drive.sh:275).
   144	    # Fires for build turns AND --review-once (kind flips the diagnostic), before the lane-attempt gate.
   145	    if args.target_root:
   146	        tr = os.path.realpath(args.target_root) if os.path.isdir(args.target_root) else ""
   147	        rf = os.path.join(os.path.realpath(os.path.dirname(relay_file)), os.path.basename(relay_file))
   148	        if tr and rf != tr and not rf.startswith(tr + os.sep):
   149	            turn_kind = "review" if args.review_once else "build"
   150	            die(f"--target-root {turn_kind} turn cannot report: relay file '{relay_file}' resolves "
   151	                f"outside the target root '{args.target_root}', so a {turn_kind} turn (ALLOW_PATHS=\"\") "
   152	                "has no writable path for its findings and the turn would be discarded after full cost. "
   153	                f"Vendor the harness into the target repo (relay-automation/xyz-vendor.sh '{args.target_root}') "
   154	                "and drop --target-root, or move the relay thread under the target root.")
   155	
   156	    def _lane_key(raw):
   157	        return re.sub(r'[^A-Za-z0-9._-]', '_', raw)
   158	
   159	    def lane_attempt_gate(root, raw, force):
   160	        if get_env("LANE_ATTEMPT_COUNTED"): return 0
   161	        if not raw: return 0
   162	        
   163	        max_attempts = get_env("LANE_MAX_ATTEMPTS", "2")
   164	        try: max_attempts = int(max_attempts)
   165	        except ValueError: max_attempts = 2
   166	
   167	        key = _lane_key(raw)
   168	        attempts_dir = os.path.join(root, ".tick", "attempts")
   169	        os.makedirs(attempts_dir, exist_ok=True)
   170	        attempts_file = os.path.join(attempts_dir, key)
   171	
   172	        count = 0
   173	        if os.path.isfile(attempts_file):
   174	            try:
   175	                with open(attempts_file, "r") as f:
   176	                    count = len(f.readlines())
   177	            except Exception:
   178	                pass
   179	        
   180	        if force:
   181	            eprint(f"lane-attempt-cap: --force override — lane {key} at {count} attempt(s) (cap {max_attempts}), proceeding.")
   182	        elif count >= max_attempts:
   183	            eprint(f"lane-attempt-cap: lane {key} PARKED after {count} attempt(s) (cap {max_attempts}) — no relay token seeded.")
   184	            eprint(f"  Re-anchor to the committed QUEUE lanes (AGENTS.md) or re-fire with --force. Attempts log: {attempts_file}")
   185	            sys.exit(8)
   186	
   187	        # append fire
   188	        ts = "fire"
   189	        try:
   190	            ts = subprocess.check_output(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
   191	        except:
   192	            pass
   193	        with open(attempts_file, "a") as f:
   194	            f.write(f"{ts} fire\n")
   195	        return 0
   196	
   197	    def lane_attempt_reset(root, raw):
   198	        if get_env("LANE_ATTEMPT_COUNTED"): return
   199	        if not raw: return
   200	        attempts_file = os.path.join(root, ".tick", "attempts", _lane_key(raw))
   201	        if os.path.exists(attempts_file):
   202	            try: os.remove(attempts_file)
   203	            except: pass
   204	
   205	    # #129/#136: resolve TICK_REPO_ROOT ONCE, here, silently. The lane-attempt gate just below
   206	    # is the first consumer — with the env unset on a vendored-.xyz drive it used to count
   207	    # attempts in the HARNESS root's .tick while the token lives in the caller repo's log, so
   208	    # LANE_MAX_ATTEMPTS enforcement fragmented across two locations (the #129 family: the two
   209	    # halves of one coordination disagreeing about where state lives). An explicit TICK_REPO_ROOT
   210	    # still wins, unchanged. The NOTE announcing a self-resolution prints later, after the
   211	    # driver lock — gh376's twin-parity pin requires a held lock to stay the first printable
   212	    # line — which is why resolution (side-effect-free, ahead of every consumer) and
   213	    # announcement are split.
   214	    tick_repo_root = get_env("TICK_REPO_ROOT")
   215	    self_resolved = not tick_repo_root
   216	    if self_resolved:
   217	        try:
   218	            tick_repo_root = resolve_turn_root(None, root_dir)
   219	        except RuntimeError:
   220	            tick_repo_root = root_dir
   700	    if os.path.basename(xyz_harness) == ".xyz":
   701	        default_root = os.path.abspath(os.path.join(xyz_harness, ".."))
   702	    else:
   703	        default_root = xyz_harness
   704	    
   705	    root = get_env("MARATHON_ROOT", default_root)
   706	    tick_bin = get_env("TICK_BIN", os.path.join(xyz_harness, "bin", "tick"))
   707	    relay_drive_bin = get_env("MARATHON_RELAY_DRIVE", os.path.join(xyz_harness, "relay-automation", "relay-drive.sh"))
   708	    agent_cmd = get_env("MARATHON_AGENT_CMD", os.path.join(xyz_harness, "relay-automation", "marathon-agent.sh"))
   709	    # GH-342: `$HERE/harvest-findings.sh` in the Bash twin — HERE is relay-automation/, which for the
   710	    # Python lane is a sibling of utils/py's grandparent. Resolved once; both call sites re-check
   711	    # os.access(X_OK) at spawn time, so a harness missing the script simply harvests nothing.
   712	    harvest_findings_bin = os.path.join(xyz_harness, "relay-automation", "harvest-findings.sh")
   713	
   714	    def _lane_key(raw):
   715	        return re.sub(r'[^A-Za-z0-9._-]', '_', raw)
   716	
   717	    def lane_attempt_gate(root_dir, raw, force):
   718	        if get_env("LANE_ATTEMPT_COUNTED"): return 0
   719	        if not raw: return 0
   720	        max_attempts = get_env("LANE_MAX_ATTEMPTS", "2")
   721	        try: max_attempts = int(max_attempts)
   722	        except ValueError: max_attempts = 2
   723	
   724	        key = _lane_key(raw)
   725	        attempts_dir = os.path.join(root_dir, ".tick", "attempts")
   726	        os.makedirs(attempts_dir, exist_ok=True)
   727	        attempts_file = os.path.join(attempts_dir, key)
   728	
   729	        count = 0
   730	        if os.path.isfile(attempts_file):
   731	            try:
   732	                with open(attempts_file, "r") as f:
   733	                    count = len(f.readlines())
   734	            except Exception:
   735	                pass
   736	        
   737	        if force:
   738	            eprint(f"lane-attempt-cap: --force override — lane {key} at {count} attempt(s) (cap {max_attempts}), proceeding.")
   739	        elif count >= max_attempts:
   740	            eprint(f"lane-attempt-cap: lane {key} PARKED after {count} attempt(s) (cap {max_attempts}) — no relay token seeded.")
   741	            eprint(f"  Re-anchor to the committed QUEUE lanes (AGENTS.md) or re-fire with --force. Attempts log: {attempts_file}")
   742	            # Sentinel Tier 1 (GH-281/GH-342). The Bash lane emits this from the CALLER, on rc==8
   743	            # (marathon-drive.sh:1103-1106); this gate exits directly, so it emits here instead —
   744	            # same record, same position relative to the two messages above. `raw`, not `key`: the
   745	            # Bash message carries $LANE_STATE_KEY as given, not the sanitized form.
   746	            xyz_debug_log_append(
   747	                root, "warn", "marathon.lane-park",
   748	                f"lane {raw} parked at attempt cap",
   749	                action="re-anchor to QUEUE lanes or re-fire with --force",
   750	                target_root=args.target_root, phase_id=args.phase_id,
   751	                relay_task=relay_task)
   752	            sys.exit(8)
   753	
   754	        # append fire
   755	        ts = "fire"
   756	        try:
   757	            ts = subprocess.check_output(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
   758	        except:
   759	            pass
   760	        with open(attempts_file, "a") as f:
   761	            f.write(f"{ts} fire\n")
   762	        return 0
   763	
   764	    def lane_attempt_reset(root_dir, raw):
   765	        if get_env("LANE_ATTEMPT_COUNTED"): return
   766	        if not raw: return
   767	        attempts_file = os.path.join(root_dir, ".tick", "attempts", _lane_key(raw))
   768	        if os.path.exists(attempts_file):
   769	            try: os.remove(attempts_file)
   770	            except: pass
   771	
   772	    def debug_mantra_prior_attempts(root_dir, raw):
   773	        # GH-162: READ-ONLY peek at the .tick/attempts/<lane> file GH-45 maintains — how many prior
   774	        # fires on this lane did not reach Approved. Never writes.
   775	        f = os.path.join(root_dir, ".tick", "attempts", _lane_key(raw))
   776	        if os.path.isfile(f):
   777	            try:
   778	                with open(f) as fh:
   779	                    return sum(1 for _ in fh)
   780	            except Exception:
  1380	                    f"the run stopped; this record exists so the phase is not simply absent (GH-388).\n"
  1381	                )
  1382	            log(f"interrupted-phase record written: {dest} (reason: {reason})")
  1383	            # Best-effort archive of the relay state itself, for the same reason escalate() does it.
  1384	            try:
  1385	                save_transcript()
  1386	            except Exception:
  1387	                pass
  1388	        except Exception:
  1389	            pass
  1390	
  1391	    _ON_EXIT.append(_write_interrupted_phase_record)
  1392	    _ON_EXIT.append(_marathon_drive_on_exit)
  1393	
  1394	    # GH-238: a vendored consumer normally has no root-level validate.sh. Do NOT spend a builder and
  1395	    # reviewer turn only to discover the default gate can't start after approval. A deliberately
  1396	    # non-executing probe (gates like `test -f build/output` only become true after the builder runs):
  1397	    # prove the gate is *runnable*, not that it currently passes. Runs before any render/tick/dispatch.
  1398	    _gate_root = args.target_root or root
  1399	    def _preflight_check_issue_closed():
  1400	        mock_state = os.environ.get("MOCK_GH_ISSUE_STATE")
  1401	        if mock_state:
  1402	            state = mock_state.upper()
  1403	        else:
  1404	            issue = lane_issue_number()
  1405	            if not issue:
  1406	                return
  1407	            if not shutil.which("gh"):
  1408	                return
  1409	            url = _cmd_out(["git", "-C", root, "remote", "get-url", "origin"])
  1410	            repo = re.sub(r'\.git$', '', re.sub(r'^https?://[^/]+/', '', re.sub(r'^git@[^:]+:', '', url)))
  1411	            if not re.fullmatch(r'[A-Za-z0-9._-]+/[A-Za-z0-9._-]+', repo):
  1412	                repo = _cmd_out(["gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"], cwd=root)
  1413	            if not repo:
  1414	                return
  1415	            state = _cmd_out(["gh", "issue", "view", issue, "--repo", repo, "--json", "state", "--jq", ".state"])
  1416	        
  1417	        if state and state.upper() == "CLOSED":
  1418	            issue_display = lane_issue_number() or "unknown"
  1419	            xyz_debug_log_append(
  1420	                root, "warn", "marathon.issue-closed",
  1421	                f"lane {lane_state_key} parked — issue {issue_display} is already closed",
  1422	                action="none (lane halted)",
  1423	                target_root=args.target_root, phase_id=args.phase_id,
  1424	                relay_task=relay_task)
  1425	            eprint(f"marathon-drive: lane parked — issue {issue_display} is already closed")
  1426	            sys.exit(4)
  1427	
  1428	    def _pre_advance_not_runnable(reason):
  1429	        die(f"pre-advance gate not runnable: '{pre_advance_cmd}' ({reason}). "
  1430	            f"Pass --pre-advance-cmd '<runnable command>' to override it.")
  1431	    def _preflight_pre_advance_gate():
  1432	        if subprocess.run(["bash", "-n", "-c", pre_advance_cmd],
  1433	                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
  1434	            _pre_advance_not_runnable("shell syntax is invalid")
  1435	        # GH-319: tokenize the way the shell will. A regex `(\S+)` capture cannot see a quoted path
  1436	        # that contains a space — it grabs the leading fragment, which on this machine happened to be
  1437	        # a real 0-byte file, so the "is the gate runnable?" check passed on the WRONG file. shlex
  1438	        # splits `bash '/a b/validate.sh'` into two tokens, so the same check now inspects the file
  1439	        # the shell would actually execute. Fall back to naive split only if the string is unparsable
  1440	        # (unbalanced quotes) — that case is caught by the `bash -n` syntax check just above anyway.
  1441	        try:
  1442	            tokens = shlex.split(pre_advance_cmd)
  1443	        except ValueError:
  1444	            tokens = pre_advance_cmd.split()
  1445	        if tokens and re.fullmatch(r'bash|/\S*/bash', tokens[0]) and len(tokens) > 1:
  1625	
  1626	        esc_file = os.path.join(phase_dir, "ESCALATION.md")
  1627	        with open(esc_file, 'w') as f:
  1628	            f.write(f"""# ESCALATION — Marathon Phase {args.phase_id}
  1629	
  1630	phase: {args.phase_id}
  1631	task: {relay_task}
  1632	relay-drive-exit: {rexit}
  1633	reason: {reason}
  1634	gate: {run_gate_result[0]}
  1635	relay-file: {rel_relay}
  1636	""")
  1637	            if builder_diag:
  1638	                f.write(f"builder-diagnostic: {builder_diag}\n")
  1639	        subprocess.run(["git", "-C", commit_root, "add", "--", esc_file], check=True)
  1640	        # GH-207: an identical escalation record must not HALT on nothing-to-commit.
  1641	        if subprocess.run(["git", "-C", commit_root, "diff", "--cached", "--quiet", "--", esc_file]).returncode != 0:
  1642	            subprocess.run(["git", "-C", commit_root, "commit", "-q", "-m", f"marathon: phase {args.phase_id} escalation ({reason})"], check=True)
  1643	        # Archive the failed phase's relay transcript too — save_transcript otherwise runs only
  1644	        # on success, so an escalated/reverted phase leaves no durable record of its rounds. The
  1645	        # 2026-07-30 rebalance-OS marathon (GH-382's panic run) reverted its p5 phase twice and
  1646	        # the relay state survived nowhere. Non-fatal: losing the archive must not mask the
  1647	        # escalation itself.
  1648	        try:
  1649	            if not save_transcript():
  1650	                log(f"warn: could not archive relay transcript for escalated phase {args.phase_id}")
  1651	        except Exception as exc:  # noqa: BLE001 — archive failure must never mask the escalation
  1652	            log(f"warn: could not archive relay transcript for escalated phase {args.phase_id}: {exc}")
  1653	        subprocess.run([tick_bin, "log", "marathon.phase.escalated", relay_task, "--agent", "marathon"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
  1654	        _phase_memory_sample(f"{args.phase_id}-escalated", root=root, tick_bin=tick_bin, relay_task=relay_task)
  1655	        phase_outcome_recorded[0] = True   # GH-388: a decided outcome with a durable record
  1656	        log(f"escalation written: {esc_file} (reason: {reason})")
  1657	        # marathon-drive.sh:867-868 — last thing escalate() does, carrying the relay-drive exit code.
  1658	        xyz_debug_log_append(
  1659	            root, "error", "marathon.escalation",
  1660	            f"{reason} (relay-drive-exit={rexit})",
  1661	            file=rel_relay, action="promote to PROJECT/1-INBOX capture doc",
  1662	            target_root=args.target_root, phase_id=args.phase_id, relay_task=relay_task)
  1663	
  1664	    def save_transcript():
  1665	        try:
  1666	            # We must use relay-turn-lib.sh to resolve rtl_transcript_root
  1667	            ts_base = subprocess.check_output(f"source \"{os.path.join(xyz_harness, 'relay-automation', 'relay-turn-lib.sh')}\" && rtl_transcript_root \"{root}\"", shell=True, executable="/bin/bash").decode('utf-8').strip()
  1668	        except subprocess.CalledProcessError:
  1669	            return False
  1670	
  1671	        import datetime
  1672	        now = datetime.datetime.now(datetime.timezone.utc)   # #140: utcnow() is deprecated, scheduled for removal
  1673	        date_dir = os.path.join(ts_base, now.strftime("%Y-%m-%d"))
  1674	        os.makedirs(date_dir, exist_ok=True)
  1675	        dest = os.path.join(date_dir, f"marathon-{args.phase_id}-{now.strftime('%H%M%S')}.md")
  1676	        shutil.copy2(relay_file, dest)
  1677	        # Sentinel Tier 1 (GH-281/GH-342): harvest Side Findings from the saved transcript
  1678	        # (marathon-drive.sh:880-885) — after the copy, before the commit, same as Bash.
  1679	        xyz_harvest_findings(harvest_findings_bin, relay_file, root, args.target_root,
  1680	                             xyz_debug_log_file(root))
  1681	        subprocess.run(["git", "-C", root, "add", "--", dest], check=True)
  1682	        # GH-207: an identical transcript (same-second re-render) must not HALT on nothing-to-commit.
  1683	        if subprocess.run(["git", "-C", root, "diff", "--cached", "--quiet", "--", dest]).returncode == 0:
  1684	            log(f"transcript unchanged: {dest}")
  1685	        else:

2026-08-27T15:19:27.595656Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "rg -n --no-heading 'rtl_worktree|relay-turn-lib|WORKTREE_ISOLATION|turn_sh|agent_cmd|subprocess\\.(run|Popen|call)' utils/py/relay_drive.py utils/py/marathon_drive.py | head -n 260 && nl -ba relay-automation/relay-turn-lib.sh | sed -n '665,890p' && nl -ba relay-automation/consult.sh | sed -n '115,155p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-54680-c807n60b
 succeeded in 0ms:
utils/py/relay_drive.py:31:    parser.add_argument("--agent-cmd", dest="agent_cmd")
utils/py/relay_drive.py:59:    if not args.agent_cmd and not args.dry_run:
utils/py/relay_drive.py:116:            subprocess.run(["git", "-C", args.target_root, "rev-parse", "--show-toplevel"], 
utils/py/relay_drive.py:227:    if "RELAY_WORKTREE_ISOLATION" not in os.environ:
utils/py/relay_drive.py:228:        os.environ["RELAY_WORKTREE_ISOLATION"] = "1"
utils/py/relay_drive.py:231:        if get_env("RELAY_WORKTREE_ISOLATION", "1") == "0":
utils/py/relay_drive.py:243:            subprocess.run(["git", "-C", rdir, "cat-file", "-e", f"HEAD:{rel}"], stderr=subprocess.DEVNULL, check=True)
utils/py/relay_drive.py:258:            eprint("  RELAY_WORKTREE_ISOLATION=1 runs the turn-taker in a worktree at HEAD, but its own")
utils/py/relay_drive.py:261:            eprint("  RELAY_WORKTREE_ISOLATION=0 if you want to rule out isolation entirely; neither is required.")
utils/py/relay_drive.py:267:            eprint("  first, or re-run with RELAY_WORKTREE_ISOLATION=0.")
utils/py/relay_drive.py:277:        if get_env("RELAY_WORKTREE_ISOLATION", "1") == "0":
utils/py/relay_drive.py:278:            eprint("relay-drive: WARNING — --artifact-file needs worktree isolation to seed the artifact; with RELAY_WORKTREE_ISOLATION=0 the reviewer will not see it.")
utils/py/relay_drive.py:417:        subprocess.run([xyz_append_bin, "relay", slug, health, title, desc], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
utils/py/relay_drive.py:423:        # via RELAY_WORKTREE_ISOLATION=1. The marathon driver already followed .git to the git COMMON
utils/py/relay_drive.py:577:        if os.access(args.agent_cmd, os.X_OK):
utils/py/relay_drive.py:578:            proc = subprocess.Popen([args.agent_cmd], start_new_session=True)
utils/py/relay_drive.py:580:            proc = subprocess.Popen(args.agent_cmd, shell=True, executable="/bin/bash", start_new_session=True)
utils/py/relay_drive.py:583:                out = subprocess.run(["ps", "-axo", "pgid=,rss="], capture_output=True, text=True, timeout=5).stdout
utils/py/relay_drive.py:601:                subprocess.run([tick_bin, "cost", args.relay_task, "--agent", actor, "--peak-rss-mb", str(peak_turn_rss_mb)], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
utils/py/relay_drive.py:694:                subprocess.run(["git", "-C", cv_relay_repo, "add", relay_file], stderr=subprocess.DEVNULL)
utils/py/relay_drive.py:695:                subprocess.run(["git", "-C", cv_relay_repo, "commit", "-m", f"relay-drive: consult-verify divergence escalation (round {round_idx})"], stderr=subprocess.DEVNULL)
utils/py/marathon_drive.py:191:        subprocess.run(
utils/py/marathon_drive.py:237:    res = subprocess.run(cmd_args, capture_output=True, text=True, env=env, cwd=tr_root if (tr_root and os.path.isdir(tr_root)) else None)
utils/py/marathon_drive.py:276:            res = subprocess.run(["git", "-C", repo_root, "check-ignore", "-v", "--no-index", p],
utils/py/marathon_drive.py:516:        out = subprocess.run(["ps", "-axo", "pgid=,rss="], capture_output=True, text=True,
utils/py/marathon_drive.py:573:            out = subprocess.run(["sysctl", "-n", "vm.swapusage"], capture_output=True, text=True, timeout=5).stdout
utils/py/marathon_drive.py:586:            out = subprocess.run(["vm_stat"], capture_output=True, text=True, timeout=5).stdout
utils/py/marathon_drive.py:623:                subprocess.run([tick_bin, "cost", relay_task, "--agent", "marathon"] + extra, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
utils/py/marathon_drive.py:693:            subprocess.run(["git", "-C", args.target_root, "rev-parse", "--show-toplevel"], 
utils/py/marathon_drive.py:708:    agent_cmd = get_env("MARATHON_AGENT_CMD", os.path.join(xyz_harness, "relay-automation", "marathon-agent.sh"))
utils/py/marathon_drive.py:901:        subprocess.run([xyz_append_bin, harness, sid, health, title, desc], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
utils/py/marathon_drive.py:919:            subprocess.run([xyz_heartbeat_bin, harness, sid], env=env,
utils/py/marathon_drive.py:1007:            res = subprocess.run(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
utils/py/marathon_drive.py:1026:    # (rtl_driver_heartbeat_status, relay-turn-lib.sh) still honors the variable. The one consumer
utils/py/marathon_drive.py:1030:        # RTL_DRIVER_HEARTBEAT_FILE is the same override relay-turn-lib.sh honors, so an observer (or
utils/py/marathon_drive.py:1079:    # it, and the reader that observers actually use lives in relay-automation/relay-turn-lib.sh
utils/py/marathon_drive.py:1143:            subprocess.run(
utils/py/marathon_drive.py:1158:        if not shutil.which("gh") or subprocess.run(
utils/py/marathon_drive.py:1175:            res = subprocess.run(["gh", "api", "--paginate", "--slurp",
utils/py/marathon_drive.py:1195:            subprocess.run(["gh", "issue", "comment", "--repo", repo, issue, "--body", body],
utils/py/marathon_drive.py:1204:        if not shutil.which("gh") or subprocess.run(
utils/py/marathon_drive.py:1250:        if trunk and subprocess.run(["git", "-C", root, "merge-base", "--is-ancestor", "HEAD", trunk],
utils/py/marathon_drive.py:1272:            ok = subprocess.run(["gh", "api", "--method", "PATCH",
utils/py/marathon_drive.py:1278:            ok = subprocess.run(["gh", "api", "--method", "POST",
utils/py/marathon_drive.py:1432:        if subprocess.run(["bash", "-n", "-c", pre_advance_cmd],
utils/py/marathon_drive.py:1602:            ts_base = subprocess.check_output(f"source \"{os.path.join(xyz_harness, 'relay-automation', 'relay-turn-lib.sh')}\" && rtl_transcript_root \"{root}\"", shell=True, executable="/bin/bash").decode('utf-8').strip()
utils/py/marathon_drive.py:1639:        subprocess.run(["git", "-C", commit_root, "add", "--", esc_file], check=True)
utils/py/marathon_drive.py:1641:        if subprocess.run(["git", "-C", commit_root, "diff", "--cached", "--quiet", "--", esc_file]).returncode != 0:
utils/py/marathon_drive.py:1642:            subprocess.run(["git", "-C", commit_root, "commit", "-q", "-m", f"marathon: phase {args.phase_id} escalation ({reason})"], check=True)
utils/py/marathon_drive.py:1653:        subprocess.run([tick_bin, "log", "marathon.phase.escalated", relay_task, "--agent", "marathon"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
utils/py/marathon_drive.py:1666:            # We must use relay-turn-lib.sh to resolve rtl_transcript_root
utils/py/marathon_drive.py:1667:            ts_base = subprocess.check_output(f"source \"{os.path.join(xyz_harness, 'relay-automation', 'relay-turn-lib.sh')}\" && rtl_transcript_root \"{root}\"", shell=True, executable="/bin/bash").decode('utf-8').strip()
utils/py/marathon_drive.py:1681:        subprocess.run(["git", "-C", root, "add", "--", dest], check=True)
utils/py/marathon_drive.py:1683:        if subprocess.run(["git", "-C", root, "diff", "--cached", "--quiet", "--", dest]).returncode == 0:
utils/py/marathon_drive.py:1686:            subprocess.run(["git", "-C", root, "commit", "-q", "-m", f"marathon: phase {args.phase_id} transcript saved ({relay_task})"], check=True)
utils/py/marathon_drive.py:1735:        "RELAY_TARGET_ROOT", "RELAY_TASK", "RELAY_WORKTREE_ISOLATION",
utils/py/marathon_drive.py:1778:            rc = subprocess.run(pre_advance_cmd, shell=True, executable="/bin/bash",
utils/py/marathon_drive.py:1810:        proc = subprocess.Popen(cmd, shell=True, executable="/bin/bash", cwd=cwd, env=env,
utils/py/marathon_drive.py:1879:        return subprocess.run(args.post_approve_cmd, shell=True, executable="/bin/bash", cwd=cwd).returncode
utils/py/marathon_drive.py:1926:            out = subprocess.run(["git", "-C", rroot, "diff", "--name-only", pre_phase_head, "--", git_path],
utils/py/marathon_drive.py:1930:        st = subprocess.run(["git", "-C", rroot, "status", "--porcelain", "--", git_path],
utils/py/marathon_drive.py:1969:            shown = subprocess.run(["git", "-C", root, "show", f"{pre_phase_head}:{brief_rel}"],
utils/py/marathon_drive.py:2043:        res = subprocess.run(cmd, capture_output=True, text=True)
utils/py/marathon_drive.py:2090:        subprocess.run([tick_bin, "log", "marathon.phase.approved", relay_task, "--agent", "marathon"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
utils/py/marathon_drive.py:2102:                    subprocess.run(
utils/py/marathon_drive.py:2402:    # relay-turn-lib.sh) rather than assuming the literal `relay-system/`, because a vendored or
utils/py/marathon_drive.py:2411:                os.path.join(xyz_harness, "relay-automation", "relay-turn-lib.sh"), root),
utils/py/marathon_drive.py:2542:        exists = subprocess.run(["git", "-C", commit_root, "rev-parse", "--verify", "--quiet",
utils/py/marathon_drive.py:2545:        cut = subprocess.run(["git", "-C", commit_root, "checkout", "-q"]
utils/py/marathon_drive.py:2585:    subprocess.run(["git", "-C", commit_root, "add", "--", relay_file], check=True)
utils/py/marathon_drive.py:2588:    if subprocess.run(["git", "-C", commit_root, "diff", "--cached", "--quiet", "--", relay_file]).returncode == 0:
utils/py/marathon_drive.py:2591:        subprocess.run(["git", "-C", commit_root, "commit", "-q", "-m", f"marathon: render phase {args.phase_id} relay ({relay_task})"], check=True)
utils/py/marathon_drive.py:2653:                "--agent-cmd", agent_cmd]
utils/py/marathon_drive.py:2668:        # relay-drive exports RELAY_TARGET_ROOT and relay-turn-lib.sh:251 reads
utils/py/marathon_drive.py:2674:        # relay-turn-lib.sh:283 already stated the gap: "marathon-drive/relay-drive don't export
utils/py/marathon_drive.py:2689:        return subprocess.run(cmd2, env=env2, cwd=root).returncode
utils/py/marathon_drive.py:2730:            subprocess.run([tick_bin, "release", relay_task, "--agent", args.builder, "--to", args.reviewer], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
utils/py/marathon_drive.py:2732:            subprocess.run([tick_bin, "claim", relay_task, "--agent", args.builder, "--paths", claim_paths], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
utils/py/marathon_drive.py:2733:            subprocess.run([tick_bin, "release", relay_task, "--agent", args.builder, "--to", args.reviewer], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
   665	  # never clobbers a ROOT-direct edit with a stale seed (GH-22). git is already required by this lib.
   666	  local p="$1"
   667	  if [[ -f "$p" ]]; then
   668	    git hash-object -- "$p" 2>/dev/null || echo "ERR:$p"
   669	  elif [[ -d "$p" ]]; then
   670	    # Stable per-dir signature: hash each tracked-or-untracked file's content in sorted order.
   671	    ( cd "$p" 2>/dev/null && find . -type f -print0 2>/dev/null | LC_ALL=C sort -z \
   672	        | xargs -0 git hash-object 2>/dev/null ) | git hash-object --stdin 2>/dev/null || echo "ERR:$p"
   673	  else
   674	    echo "ABSENT"
   675	  fi
   676	}
   677	
   678	rtl_worktree_begin() {
   679	  # Create the worktree, seed the CURRENT working-tree allowlist into it (the HEAD checkout may be
   680	  # stale, e.g. an uncommitted relay file), and echo the worktree path. Returns non-zero on failure
   681	  # so the caller can fall back to an in-ROOT run. Sets RTL_WT.
   682	  local wt a wt_root _root_abs _tmp_abs _gcd
   683	  # GH-236: in /tmp-rooted environments $TMPDIR can resolve INSIDE the working root, which drops the
   684	  # throwaway isolation worktree inside the very tree the turn operates on and breaks codex turns —
   685	  # a failure that then surfaces mislabeled as a turn timeout. Default to $TMPDIR so behaviour is
   686	  # unchanged everywhere else; ONLY when $TMPDIR lands inside RTL_ROOT, relocate the worktree root
   687	  # under the repo's own git metadata dir (never part of the working tree, never under $TMPDIR) —
   688	  # git worktree add accepts a checkout there and git status ignores it.
   689	  wt_root="${TMPDIR:-/tmp}"
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
   716	      continue
   717	    fi
   718	    if [[ -e "$RTL_ROOT/$a" ]]; then
   719	      mkdir -p "$wt/$(dirname "$a")"
   720	      cp -R "$RTL_ROOT/$a" "$wt/$a"
   721	      rtl_trace "rtl_worktree_begin: SEED $a"
   722	    else
   723	      rm -rf "$wt/$a"                  # allowlisted path ALREADY deleted in the host tree → mirror the
   724	                                       # deletion, else the HEAD checkout would resurrect it on copy-back
   725	      rtl_trace "rtl_worktree_begin: SEED-DELETE $a (already absent in ROOT)"
   726	    fi                                 # (Codex review r2, 2026-06-20 — symmetric to the in-turn delete)
   727	  done
   728	  # GH-22: snapshot each seeded allowlist path's signature so rtl_worktree_end copies back ONLY paths
   729	  # the turn modified in the worktree — an agent that wrote ROOT directly (real agy resolves the relay
   730	  # file to its absolute ROOT path even with CWD=worktree) must not be overwritten by the stale seed.
   731	  # Persist to a sidecar file (NOT inside the worktree — that would read as an off-lane untracked file)
   732	  # because the caller invokes this via wt="$(rtl_worktree_begin)", a subshell whose globals are lost;
   733	  # rtl_worktree_end re-reads the sidecar by the worktree path it is handed. One line per RTL_ALLOW entry.
   734	  : >"${wt}.seedsig"
   735	  for a in "${RTL_ALLOW[@]}"; do [[ "$a" == /* ]] && continue; _rtl_sig "$wt/$a" >>"${wt}.seedsig"; done
   736	  # GH-31 / #15: seed the read-only artifact under review so an ISOLATED reviewer can READ it (it is
   737	  # neither at HEAD nor on the writable allowlist). Snapshot the .relay-artifacts dir signature to a
   738	  # sidecar so rtl_worktree_end can exempt it from off-lane detection ONLY while unchanged — a reviewer
   739	  # edit changes the signature and trips off-lane (strict read-only). NOT in RTL_ALLOW ⇒ never copied back.
   740	  if [[ -n "${RTL_ARTIFACT:-}" && -f "$RTL_ARTIFACT" ]]; then
   741	    mkdir -p "$wt/.relay-artifacts"
   742	    cp "$RTL_ARTIFACT" "$wt/$RTL_ARTIFACT_REL"
   743	    _rtl_sig "$wt/.relay-artifacts" >"${wt}.artifactsig"
   744	  fi
   745	  # GH-91: the sanctioned scratch dir. The harness REQUIRES the builder to verify its work by
   746	  # running commands that produce output, so it owes the turn a place inside the tree to put
   747	  # that output — the 0.7.2 daybreak re-fire reverted four green probe JSONs as off-lane and
   748	  # failed a complete, passing turn at exit 6. Pre-created (the affordance physically exists),
   749	  # named in rtl_turn_prompt, exempted by rtl_worktree_end/rtl_check, never copied back, and
   750	  # discarded with the worktree.
   751	  mkdir -p "$wt/.relay-scratch"
   752	  RTL_WT="$wt"; RTL_WT_USED=1   # GH-13: mark the turn worktree-isolated so rtl_enforce won't reset a concurrent peer's ROOT commit
   753	  printf '%s\n' "$wt"
   754	}
   755	
   756	rtl_worktree_end() {  # [<wt>] — sets RTL_WT_OFFLANE (0|1); copies allowlist back unless off-lane found
   757	  # Contain + DETECT: if the agent touched anything outside {allowlist, .tick} in the worktree, that's
   758	  # an off-lane attempt — do NOT copy anything back (the turn must fail like an in-ROOT exit-6), set
   759	  # RTL_WT_OFFLANE=1, and destroy the worktree. Otherwise copy ONLY the allowlist back to RTL_ROOT —
   760	  # edits/creates propagate, AND an allowlisted path the turn DELETED in the worktree is removed from
   761	  # RTL_ROOT too (so an isolated Producer that deletes an artifact isn't silently undone — Codex review
   762	  # 2026-06-20) — then destroy the worktree.
   763	  local wt="${1:-${RTL_WT:-}}" a entry xy path
   764	  RTL_WT_OFFLANE=0
   765	  [[ -n "$wt" && -d "$wt" ]] || return 0
   766	  rtl_trace "rtl_worktree_end: WT=$wt"
   767	  # GH-266: the harness's own transcript-log directory, when NOT redirected via XYZ_ARCHIVE_ROOT (the
   768	  # default), lives inside RTL_ROOT itself and is genuinely new/untracked in a fresh isolated worktree
   769	  # — exempt it the same way .tick/ is exempted below, mirroring rtl_check()'s $RTL_LOG_REL exemption
   770	  # (line ~683). When XYZ_ARCHIVE_ROOT IS set, rtl_transcript_root resolves outside RTL_ROOT entirely,
   771	  # so nothing here would ever appear in this worktree's own git status — no exemption needed then.
   772	  local _rtl_log_top=""
   773	  [[ -z "${XYZ_ARCHIVE_ROOT:-}" ]] && _rtl_log_top="$(basename "$(rtl_transcript_root "$RTL_ROOT")")"
   774	  # GH-13/#14: rtl_worktree_begin runs in a `wt="$(...)"` subshell, so the RTL_WT_USED=1 it sets there
   775	  # is LOST before rtl_enforce runs — which left the "a moved ROOT HEAD is a concurrent PEER commit;
   776	  # preserve it, don't reset" branch in rtl_enforce as DEAD CODE for the command-substitution shims
   777	  # (codex/agy). Every moved ROOT HEAD then wrongly hit the in-ROOT reset+exit-6 path, discarding a
   778	  # worktree builder's whole turn (the 2026-06-29 codex marathon, #14). This function runs in the
   779	  # caller's shell and is always reached before rtl_enforce for a worktree turn, so re-assert the flag
   780	  # here to restore the GH-13 protection. (The agent ran CWD=worktree, so its OWN commits can't reach
   781	  # ROOT; a moved ROOT HEAD is genuinely a peer/harness commit. Off-lane worktree content is already
   782	  # contained below before rtl_enforce sees it.)
   783	  RTL_WT_USED=1
   784	  while IFS= read -r -d '' entry; do
   785	    [[ -n "$entry" ]] || continue
   786	    xy="${entry:0:2}"; path="${entry:3}"
   787	    case "$xy" in R*|C*) IFS= read -r -d '' _ || true ;; esac   # rename/copy: consume 2nd NUL field
   788	    case "$path" in .tick/*|.tick) continue ;; esac
   789	    # GH-91: builder scratch / verification output — sanctioned, writable by design, exempt with
   790	    # NO signature check (unlike .relay-artifacts above: scratch is meant to be written), never
   791	    # copied back (the copyback loop iterates RTL_ALLOW only), discarded with the worktree.
   792	    case "$path" in .relay-scratch|.relay-scratch/|.relay-scratch/*) continue ;; esac
   793	    # GH-266: git collapses an all-untracked dir to one line (same reasoning as .relay-artifacts
   794	    # below) — match both the bare transcript-log directory name and any path under it.
   795	    if [[ -n "$_rtl_log_top" ]]; then
   796	      case "$path" in "$_rtl_log_top"|"$_rtl_log_top"/|"$_rtl_log_top"/*) continue ;; esac
   797	    fi
   798	    # GH-31 / #15: the read-only artifact seed. Exempt ONLY while unchanged from the seed; a reviewer
   799	    # edit changes the .relay-artifacts dir signature → strict-fail as off-lane (read-only enforced,
   800	    # not silently discarded). git collapses an all-untracked dir to ".relay-artifacts/", so match both.
   801	    case "$path" in
   802	      .relay-artifacts|.relay-artifacts/|.relay-artifacts/*)
   803	        if [[ -f "${wt}.artifactsig" ]] && [[ "$(_rtl_sig "$wt/.relay-artifacts")" == "$(cat "${wt}.artifactsig")" ]]; then
   804	          continue
   805	        fi
   806	        rtl_trace "rtl_worktree_end: OFFLANE path=$path (artifact modified)"
   807	        RTL_WT_OFFLANE=1; continue ;;
   808	    esac
   809	    rtl_in_allow "$path" && continue
   810	    rtl_is_containment_ignored "$path" && continue   # GH-107: opt-in tool-cache exemption
   811	    # GH-113: same scratch relocation as rtl_check's non-worktree path — a scratch-shaped untracked
   812	    # root file in the throwaway worktree is moved into RTL_ROOT's .tick/scratch for inspection
   813	    # (the worktree itself is destroyed below, which would otherwise destroy the evidence) and the
   814	    # turn is NOT failed on it.
   815	    rtl_scratch_relocate "$path" "$wt" "$RTL_ROOT" && continue
   816	    rtl_offlane_hint "$path"                         # GH-90: name a file-vs-directory lane-spec mistake
   817	    rtl_trace "rtl_worktree_end: OFFLANE path=$path"
   818	    RTL_WT_OFFLANE=1                    # a non-allowlist, non-.tick change → off-lane
   819	  done < <(git -C "$wt" status --porcelain -z 2>/dev/null)
   820	  rtl_trace "rtl_worktree_end: OFFLANE_VERDICT=$RTL_WT_OFFLANE"
   821	  if ((RTL_WT_OFFLANE == 0)); then
   822	    local i=0 seedsig nowsig _ln; local _seeds=()
   823	    # Re-read the seed signatures written by rtl_worktree_begin (one line per RTL_ALLOW entry).
   824	    if [[ -f "${wt}.seedsig" ]]; then
   825	      while IFS= read -r _ln; do _seeds+=("$_ln"); done <"${wt}.seedsig"
   826	    fi
   827	    for a in "${RTL_ALLOW[@]}"; do
   828	      # GH-30 Phase 3: skip the absolute archive relay-file entry — never seeded here (committed to the
   829	      # archive by rtl_enforce). Skipped in lockstep with the begin seedsig loop, so `i` stays aligned.
   830	      [[ "$a" == /* ]] && continue
   831	      # GH-22: copy back ONLY paths the turn changed IN THE WORKTREE. If the worktree path is identical
   832	      # to what was seeded, the turn did not touch it here — leave RTL_ROOT alone so a ROOT-direct edit
   833	      # (agy writing the absolute ROOT path) survives for rtl_enforce to commit, instead of being
   834	      # overwritten by the stale seed. No recorded seed signature → copy as before (safe fallback).
   835	      seedsig="${_seeds[i]-}"; i=$((i+1))
   836	      nowsig="$(_rtl_sig "$wt/$a")"
   837	      if [[ -n "$seedsig" && "$nowsig" == "$seedsig" ]]; then
   838	        rtl_trace "rtl_worktree_end: UNCHANGED $a (left ROOT alone)"
   839	        continue
   840	      fi
   841	      if [[ -e "$wt/$a" ]]; then
   842	        mkdir -p "$RTL_ROOT/$(dirname "$a")"
   843	        # GH-140: copy into a temp path beside the destination, then atomically rename it into place —
   844	        # NOT a direct in-place `cp -R` onto $RTL_ROOT/$a. A plain cp truncates+rewrites an existing
   845	        # destination at the SAME inode; if $a is a script actively being interpreted right now (this
   846	        # very marathon-drive.sh, or its relay-drive.sh subprocess — both are legitimate copyback
   847	        # targets for a Seam #1-style lane), the live reader can observe a half-old/half-new file mid
   848	        # execution. A 2026-07-05 run hit exactly this: the outer process crashed with a garbled parse
   849	        # immediately after copyback, then corrupted further into wiping the working tree. `mv` on the
   850	        # same filesystem is an atomic rename (same pattern as append-xyz-completion.sh's os.replace) —
   851	        # an fd already open on the old $RTL_ROOT/$a keeps reading the old inode until it closes, and it
   852	        # never observes a nonexistent or half-written path in between.
   853	        local _tmp="$RTL_ROOT/$(dirname "$a")/.rtl-copyback.$$.$(basename "$a")"
   854	        rm -rf "$_tmp"
   855	        cp -R "$wt/$a" "$_tmp"
   856	        if [[ -d "$_tmp" && ! -L "$_tmp" ]]; then
   857	          # rename(2) cannot atomically replace a non-empty directory — remove the old one first.
   858	          # No live process reads a directory as an executing script, so this narrow window is safe.
   859	          rm -rf "$RTL_ROOT/$a"
   860	          mv "$_tmp" "$RTL_ROOT/$a"
   861	        else
   862	          # Regular file (or symlink): rename(2) atomically clobbers an existing destination directly —
   863	          # no separate rm, no window where the path is missing.
   864	          mv -f "$_tmp" "$RTL_ROOT/$a"
   865	        fi
   866	        rtl_trace "rtl_worktree_end: COPIED $a"
   867	      elif [[ -e "$RTL_ROOT/$a" ]]; then
   868	        rm -rf "$RTL_ROOT/$a"            # allowlisted path deleted in the worktree → propagate the deletion
   869	        rtl_trace "rtl_worktree_end: DELETED $a (removed from ROOT)"
   870	      fi
   871	    done
   872	  fi
   873	  rm -f "${wt}.seedsig" "${wt}.artifactsig"   # GH-22 + GH-31: clean up the sidecar signature files
   874	  git -C "$RTL_ROOT" worktree remove --force "$wt" >/dev/null 2>&1 || rm -rf "$wt"
   875	  git -C "$RTL_ROOT" worktree prune >/dev/null 2>&1 || true
   876	  if [ -n "${RTL_ROOT:-}" ] && [ -f "$RTL_ROOT/utils/py/workspace_manager.py" ]; then
   877	    python3 "$RTL_ROOT/utils/py/workspace_manager.py" deregister --repo "$RTL_ROOT" --path "$wt" >/dev/null 2>&1 || true
   878	  fi
   879	  RTL_WT=""
   880	}
   881	
   882	rtl_turn_prompt() {  # <agent> <relay_file> <task> <allow_csv> [peer]
   883	  local agent="$1" f="$2" task="$3" csv="$4" peer="${5:-}"
   884	  # Name the peer explicitly when known — a live Gemini turn (2026-06-15) released the token to the
   885	  # literal role "Producer" because "the other agent" was unnamed. RELAY_PEER closes that ambiguity.
   886	  local handoff="release --to the other agent (the role named by NEXT in the file)"
   887	  [[ -n "$peer" ]] && handoff="release --to ${peer}"
   888	  # Emit repo-root-relative EDIT paths (relay file, artifact) so they resolve against the turn's CWD —
   889	  # which under worktree isolation IS the throwaway worktree. An ABSOLUTE edit path would invite the
   890	  # model to write straight into RTL_ROOT, bypassing the worktree (Codex review 2026-06-20). RTL_ROOT
   115	# GH-30 Phase 2: default the run parent to the transcript-root resolver (honors XYZ_ARCHIVE_ROOT).
   116	# An explicit --out (OUT already set) wins and skips the resolver entirely, so an invalid
   117	# XYZ_ARCHIVE_ROOT can never override a caller who named their own --out. Resolver hard-errors loudly.
   118	if [[ -z "$OUT" ]]; then
   119	  _ts_base="$(rtl_transcript_root "$ROOT")" || exit 1
   120	  OUT="$_ts_base/$(date +%F)"
   121	fi
   122	RUN_DIR="$OUT/${LABEL}-$(date +%H%M%S)"
   123	mkdir -p "$RUN_DIR"
   124	
   125	# Advisor preamble: independent, advisory, structured, cite evidence. Each is told a peer answers the
   126	# SAME question separately and a coordinator reconciles — so it gives its OWN read, not a guessed consensus.
   127	PREAMBLE="You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering \
   128	the SAME question separately and a coordinator will reconcile both answers, so give your own honest, \
   129	specific read — do not hedge toward a consensus you cannot see. Read any repo files the question \
   130	references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — \
   131	[Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY \
   132	ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy)."
   133	FULL_PROMPT="$PREAMBLE
   134	
   135	=== CONSULT QUESTION ===
   136	$PROMPT_TEXT"
   137	printf '%s' "$PROMPT_TEXT" > "$RUN_DIR/${LABEL}.PROMPT.txt"
   138	
   139	# --- build the throwaway worktree = operator's CURRENT visible state, isolated --------------------
   140	# tracked WIP (staged+unstaged) WITHOUT touching the real tree; falls back to HEAD when clean.
   141	base="$(git -C "$ROOT" stash create 2>/dev/null || true)"; base="${base:-HEAD}"
   142	WT="${TMPDIR:-/tmp}/consult-wt-$$-${RANDOM}"
   143	cleanup() {
   144	  git -C "$ROOT" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"
   145	  git -C "$ROOT" worktree prune >/dev/null 2>&1 || true
   146	}
   147	trap cleanup EXIT
   148	git -C "$ROOT" worktree add --detach "$WT" "$base" >/dev/null 2>&1 \
   149	  || die "could not create isolation worktree (base $base)"
   150	# overlay untracked-not-ignored files so advisors see brand-new files (e.g. a skill being reviewed).
   151	while IFS= read -r -d '' f; do
   152	  mkdir -p "$WT/$(dirname "$f")"
   153	  cp -p "$ROOT/$f" "$WT/$f" 2>/dev/null || true
   154	done < <(git -C "$ROOT" ls-files --others --exclude-standard -z 2>/dev/null)
   155	

2026-08-27T15:19:35.193338Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "nl -ba .claude/settings.json | sed -n '1,260p' && rg -n --no-heading 'gh527-destructive|PreToolUse|hooks/' .claude relay-automation utils test README.md AGENTS.md | head -n 260 && nl -ba test/gh527-destructive-git-guard.sh | sed -n '1,175p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-54680-c807n60b
 succeeded in 0ms:
     1	{
     2	  "permissions": {
     3	    "allow": [
     4	      "Bash(/usr/bin/git status *)",
     5	      "Bash(/usr/bin/git rev-list *)",
     6	      "Bash(/usr/bin/grep -iE \"closeout|pr-emit|complete\")",
     7	      "Bash(/usr/bin/grep -rln \"XYZ.json\\\\|xyz-completion\" relay-automation/*.sh utils/*.sh)",
     8	      "Bash(/usr/bin/git check-ignore *)",
     9	      "Bash(/usr/bin/grep -m1 \"^status:\" PROJECT/2-WORKING/GH-284-MARATHON-CLOSEOUT-PR.md)",
    10	      "Bash(/usr/bin/grep -nE '^#{1,3} ' RELEASES.md)",
    11	      "Bash(/usr/bin/grep -n \"check_releases\" -A30 utils/pdda/pdda.sh)",
    12	      "Bash(/usr/bin/grep -iE \"REQUIRED|field|Release:|GH_URL|Status|Codename\")",
    13	      "Bash(/usr/bin/grep -n \"RELEASES.md\" -A12 PROJECT/PDDA.md)",
    14	      "Bash(/usr/bin/grep -rl \"^## Anti-goals\\\\|^## Non-goals\" PROJECT --include=\"*.md\")",
    15	      "WebFetch(domain:dev.meta.ai)",
    16	      "WebFetch(domain:api.meta.ai)",
    17	      "Bash(/usr/bin/grep -oE https?://[a-zA-Z0-9._/-]+ __TRACKED_VAR__/muse-launcher.sh)",
    18	      "Bash(rm -f xyz-cockpit-0.1.0.vsix)",
    19	      "Bash(rtk npx *)"
    20	    ]
    21	  },
    22	  "hooks": {
    23	    "PreToolUse": [
    24	      {
    25	        "matcher": "Bash|Skill",
    26	        "hooks": [
    27	          {
    28	            "type": "command",
    29	            "command": "bash relay-automation/hooks/relay-xyz-guard.sh"
    30	          }
    31	        ]
    32	      },
    33	      {
    34	        "matcher": "Bash",
    35	        "hooks": [
    36	          {
    37	            "type": "command",
    38	            "command": "bash relay-automation/hooks/gh177-sandbox-test-guard.sh"
    39	          }
    40	        ]
    41	      },
    42	      {
    43	        "matcher": "Bash",
    44	        "hooks": [
    45	          {
    46	            "type": "command",
    47	            "command": "bash relay-automation/hooks/gh527-destructive-git-guard.sh"
    48	          }
    49	        ]
    50	      }
    51	    ],
    52	    "SessionStart": [
    53	      {
    54	        "hooks": [
    55	          {
    56	            "type": "command",
    57	            "command": "bash relay-automation/hooks/xyz-vendor-reminder.sh"
    58	          }
    59	        ]
    60	      }
    61	    ],
    62	    "UserPromptSubmit": [
    63	      {
    64	        "hooks": [
    65	          {
    66	            "type": "command",
    67	            "command": "bash relay-automation/hooks/skill-nudge.sh"
    68	          }
    69	        ]
    70	      }
    71	    ]
    72	  }
    73	}
README.md:26:bash githooks/install.sh   # contributors: wires the pre-push gate (correctness requirement)
README.md:33:**If you are going to push to this repo, run `bash githooks/install.sh` once per clone. It is a
README.md:35:CI independently checks public-repo changes afterward. The hook lives in `.git/hooks/`, which does
README.md:39:directly any time with `bash githooks/install.sh --check`. (Just evaluating the project and never
README.md:450:- `utils/git-bundle-snapshot.sh` + `relay-automation/hooks/gh177-sandbox-test-guard.sh` — the wipe-prevention layer: rotated `git bundle --all` backups on a daily cron, plus a PreToolUse hook that blocks running the test suite under a *sandboxed* Claude Code Bash call (the ignition for the GH-177 repo wipes). See legacy source issue #233.
AGENTS.md:125:  `githooks/pre-push` so failures are caught before the remote round trip.
AGENTS.md:126:  - Wire a new clone once: `bash githooks/install.sh` (idempotent). It installs a dispatch stub into
AGENTS.md:127:    `.git/hooks/`, which covers **every branch and linked worktree** of that clone, including branches
AGENTS.md:128:    with no `githooks/` directory (GH-549 — the first design wired `core.hooksPath` at the in-tree
AGENTS.md:131:    runs. Check with `bash githooks/install.sh --check`.
AGENTS.md:150:  blast radius is **tracked** modifications; untracked files survive. `relay-automation/hooks/gh527-destructive-git-guard.sh`
AGENTS.md:261:  (enforced by `relay-automation/hooks/gh177-sandbox-test-guard.sh` — re-run it un-sandboxed; do NOT
.claude/settings.json:23:    "PreToolUse": [
.claude/settings.json:29:            "command": "bash relay-automation/hooks/relay-xyz-guard.sh"
.claude/settings.json:38:            "command": "bash relay-automation/hooks/gh177-sandbox-test-guard.sh"
.claude/settings.json:47:            "command": "bash relay-automation/hooks/gh527-destructive-git-guard.sh"
.claude/settings.json:57:            "command": "bash relay-automation/hooks/xyz-vendor-reminder.sh"
.claude/settings.json:67:            "command": "bash relay-automation/hooks/skill-nudge.sh"
utils/ci-route.sh:19:# githooks/pre-push and validate.sh (--tier 2 / --subsystem). Extending it is a deliberate
relay-automation/xyz-vendor.sh:329:#                      the self-improve loop, hooks/, docs, example configs
relay-automation/xyz-vendor.sh:355:    # Trailing '/.' copies the directory *contents* (incl. nested hooks/, fixtures/) into the stage.
test/gh35-test-tiers.sh:180:  cp "$REPO/githooks/install.sh" "$r/githooks/install.sh"
test/gh35-test-tiers.sh:234:# already niced the runner — which githooks/pre-push did, stacking to 20 and turning this pin into
test/gh35-test-tiers.sh:321:   "grep -q -- '--paths-file' '$REPO/githooks/pre-push'"
test/gh35-test-tiers.sh:323:   "grep -q '_tier\" = \"2\"' '$REPO/githooks/pre-push'"
test/gh257-roadmap-ledger-fixes.sh:13:GUARD="$root/githooks/dashboard-staleness-guard.sh"
test/gh527-destructive-git-guard.sh:4:# gh527-destructive-git-guard.sh — GH-527: a git command that overwrites the working tree
test/gh527-destructive-git-guard.sh:21:GUARD="$REPO/relay-automation/hooks/gh527-destructive-git-guard.sh"
test/gh527-destructive-git-guard.sh:26:echo "== test: gh527-destructive-git-guard =="
test/gh527-destructive-git-guard.sh:41:# hook_out <repo> <command> — run the guard with a PreToolUse-shaped payload, capture stderr
test/gh527-destructive-git-guard.sh:144:ok "AGENTS.md rail points at the guard"      "grep -q 'gh527-destructive-git-guard' '$REPO/AGENTS.md'"
test/gh527-destructive-git-guard.sh:146:# --- (8) registered as a PreToolUse Bash hook (acceptance 5) -----------------------------------
test/gh527-destructive-git-guard.sh:148:   "grep -q 'gh527-destructive-git-guard' '$REPO/.claude/settings.json'"
test/gh527-destructive-git-guard.sh:150:echo "  gh527-destructive-git-guard: $pass pass, $fail fail"
test/xyz-vendor.sh:15:HOOK="$ROOT/relay-automation/hooks/xyz-vendor-reminder.sh"
test/sentinel-network-guard.sh:10:GUARD="$HERE/../relay-automation/hooks/sentinel-network-guard.sh"
test/security-scan.sh:2:# test/security-scan.sh — registered test for relay-automation/hooks/security-scan.sh (GH-64)
test/security-scan.sh:14:SCANNER="$HERE/../relay-automation/hooks/security-scan.sh"
test/security-scan.sh:335:# review) added to relay-automation/hooks/security-scan-baseline.txt.
test/gh4-ungated-clone-warning.sh:35:rm -f "$CLONE/.git/hooks/pre-push"
test/gh4-ungated-clone-warning.sh:44:printf '%s' "$OUT_A" | /usr/bin/grep -q "Fix: bash githooks/install.sh" \
test/gh4-ungated-clone-warning.sh:52:( cd "$CLONE" && bash githooks/install.sh >/dev/null 2>&1 )
test/gh544-pre-push-gate.sh:7:#   1. githooks/pre-push  — refuses a push when the gate is red, and announces every bypass
test/gh544-pre-push-gate.sh:21:HOOK="$REPO/githooks/pre-push"
test/gh544-pre-push-gate.sh:22:INSTALL="$REPO/githooks/install.sh"
test/gh544-pre-push-gate.sh:73:  cp "$HOOK" "$r/githooks/pre-push"; chmod +x "$r/githooks/pre-push"
test/gh544-pre-push-gate.sh:100:  ( cd "$r" && printf '%s\n' "$line" | env "$@" bash githooks/pre-push 2>&1 )
test/gh544-pre-push-gate.sh:215:out="$( cd "$R_RED" && printf '%s\n' "$MIXED" | bash githooks/pre-push 2>&1 )"; rc=$?
test/gh544-pre-push-gate.sh:220:cp "$INSTALL" "$R_I/githooks/install.sh"
test/gh544-pre-push-gate.sh:221:out="$( cd "$R_I" && bash githooks/install.sh --check 2>&1 )"; rc=$?
test/gh544-pre-push-gate.sh:225:out="$( cd "$R_I" && bash githooks/install.sh 2>&1 )"; rc=$?
test/gh544-pre-push-gate.sh:230:ok "  and writes the stub into the git hooks dir, not the tree" "[ -x '$R_I/.git/hooks/pre-push' ]"
test/gh544-pre-push-gate.sh:232:   "grep -q 'XYZ-GH549-PREPUSH-STUB' '$R_I/.git/hooks/pre-push'"
test/gh544-pre-push-gate.sh:235:out="$( cd "$R_I" && bash githooks/install.sh --check 2>&1 )"; rc=$?
test/gh544-pre-push-gate.sh:237:out="$( cd "$R_I" && bash githooks/install.sh 2>&1 )"; rc=$?
test/gh544-pre-push-gate.sh:242:out="$( cd "$R_I" && bash githooks/install.sh 2>&1 )"; rc=$?
test/gh544-pre-push-gate.sh:248:# core.hooksPath, so with the legacy value still set it resolves to the in-tree githooks/ and the
test/gh544-pre-push-gate.sh:251:   "grep -q 'run the gate before anything reaches the remote' '$R_I/githooks/pre-push'"
test/gh544-pre-push-gate.sh:256:out="$( cd "$R_I" && bash githooks/install.sh --check 2>&1 )"; rc=$?
test/gh544-pre-push-gate.sh:259:out="$( cd "$R_I" && bash githooks/install.sh 2>&1 )"; rc=$?
test/gh544-pre-push-gate.sh:266:cp "$R_I/.git/hooks/pre-push" "$WORK/our-stub"
test/gh544-pre-push-gate.sh:267:cp "$WORK/foreign-hook" "$R_I/.git/hooks/pre-push"
test/gh544-pre-push-gate.sh:268:out="$( cd "$R_I" && bash githooks/install.sh --uninstall 2>&1 )"; rc=$?
test/gh544-pre-push-gate.sh:269:ok "--uninstall leaves a foreign pre-push hook alone" "[ -f '$R_I/.git/hooks/pre-push' ]"
test/gh544-pre-push-gate.sh:271:out="$( cd "$R_I" && bash githooks/install.sh 2>&1 )"; rc=$?
test/gh544-pre-push-gate.sh:273:cp "$WORK/our-stub" "$R_I/.git/hooks/pre-push"; chmod +x "$R_I/.git/hooks/pre-push"
test/gh544-pre-push-gate.sh:274:out="$( cd "$R_I" && bash githooks/install.sh --uninstall 2>&1 )"; rc=$?
test/gh544-pre-push-gate.sh:275:ok "--uninstall removes OUR stub (exit 0)" "[ $rc -eq 0 ] && [ ! -f '$R_I/.git/hooks/pre-push' ]"
test/gh544-pre-push-gate.sh:277:# --- (5b) THE PIN: a REAL `git push`, from a branch with no githooks/ ------------------------------
test/gh544-pre-push-gate.sh:289:# A branch that predates the hook: githooks/ simply does not exist on it.
test/gh544-pre-push-gate.sh:306:cp "$INSTALL" "$R_P/githooks/install.sh"
test/gh544-pre-push-gate.sh:308:( cd "$R_P" && bash githooks/install.sh >/dev/null 2>&1 )
test/gh544-pre-push-gate.sh:312:ok "REAL push on a branch WITH githooks/ is refused by the red gate" \
test/gh544-pre-push-gate.sh:319:ok "THE PIN: REAL push on a branch with NO githooks/ still runs the gate" \
test/gh544-pre-push-gate.sh:325:# The pre-fix wiring, reproduced exactly: core.hooksPath=githooks on a branch without githooks/.
test/gh243-dashboard-staleness-guard.sh:8:GUARD="$root/githooks/dashboard-staleness-guard.sh"
utils/README.md:139:* [`ci-route.sh`](ci-route.sh): 3-tier test suite routing engine (`docs`, `utility`, `core`) and CPU throttling governor consumed by `validate.sh` and `githooks/pre-push`.
relay-automation/hooks/security-scan-baseline.txt:3:# Hand-reviewed and hand-maintained (relay-automation/hooks/security-scan.sh never writes this
relay-automation/hooks/security-scan-baseline.txt:9:# To review/regenerate candidate rows: bash relay-automation/hooks/security-scan.sh --no-baseline --tsv
relay-automation/hooks/security-scan-baseline.txt:15:relay-automation/hooks/security-scan.sh	eval-unsanitized	#   R1  eval of variable / unsanitized input     eval "$foo" / eval $foo
relay-automation/hooks/security-scan-baseline.txt:16:relay-automation/hooks/security-scan.sh	eval-unsanitized	# Matches: eval "$foo", eval $foo, eval "$(…)", eval $(…)
relay-automation/hooks/security-scan-baseline.txt:17:relay-automation/hooks/security-scan.sh	pipe-remote-shell	#   R2  piped remote execution                   curl/wget ... | sh/bash
relay-automation/hooks/security-scan-baseline.txt:18:relay-automation/hooks/security-scan.sh	credential-literal	password=/secret=/api_key=
relay-automation/hooks/security-scan-baseline.txt:19:relay-automation/hooks/security-scan.sh	credential-literal	api_key=realsecret`,
relay-automation/hooks/security-scan-baseline.txt:20:relay-automation/hooks/security-scan.sh	credential-literal	password="pw secret"
relay-automation/hooks/security-scan-baseline.txt:30:test/gh527-destructive-git-guard.sh	eval-unsanitized	ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
relay-automation/hooks/relay-xyz-guard.sh:3:# relay-xyz-guard.sh — PreToolUse guard that stops a session from driving the relay
relay-automation/hooks/relay-xyz-guard.sh:12:#   "hooks": { "PreToolUse": [ { "matcher": "Bash|Skill",
relay-automation/hooks/relay-xyz-guard.sh:14:#       "command": "bash relay-automation/hooks/relay-xyz-guard.sh" } ] } ] }
relay-automation/hooks/relay-xyz-guard.sh:16:# Contract (reads the PreToolUse JSON event on stdin):
relay-automation/hooks/xyz-vendor-reminder.sh:12:#     "command": "bash relay-automation/hooks/xyz-vendor-reminder.sh" } ] } ] }
relay-automation/hooks/gh177-sandbox-test-guard.sh:3:# gh177-sandbox-test-guard.sh — PreToolUse guard: never EXECUTE this repo's test
relay-automation/hooks/gh177-sandbox-test-guard.sh:15:#   "hooks": { "PreToolUse": [ { "matcher": "Bash",
relay-automation/hooks/gh177-sandbox-test-guard.sh:17:#       "command": "bash relay-automation/hooks/gh177-sandbox-test-guard.sh" } ] } ] }
relay-automation/hooks/gh177-sandbox-test-guard.sh:19:# Contract (reads the PreToolUse JSON event on stdin):
test/ballast-release.sh:242:  rm -f "$clone/.git/hooks/pre-push"
test/ballast-release.sh:251:  (cd "$clone" && bash githooks/install.sh >/dev/null 2>&1)
test/ballast-release.sh:252:  local stub; stub="$(cd "$clone" && git rev-parse --git-common-dir 2>/dev/null)/hooks/pre-push"
relay-automation/hooks/security-scan.sh:11:#   bash relay-automation/hooks/security-scan.sh [--no-baseline] [--baseline FILE] [--tsv] [<path>...]
relay-automation/hooks/security-scan.sh:22:# in the baseline file (default: relay-automation/hooks/security-scan-baseline.txt, next to this
relay-automation/hooks/gh527-destructive-git-guard.sh:3:# gh527-destructive-git-guard.sh — PreToolUse guard: before a git command that
test/xyz-harness-hooks.sh:24:SKILL_NUDGE="$REPO/relay-automation/hooks/skill-nudge.sh"
test/relay-xyz-skill-guard.sh:3:# The PreToolUse guard (relay-automation/hooks/relay-xyz-guard.sh) must block a session from
test/relay-xyz-skill-guard.sh:8:GUARD="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/hooks/relay-xyz-guard.sh"
test/relay-xyz-skill-guard.sh:14:# Emit a PreToolUse event JSON: ev <session> <tool> <field>
relay-automation/marathon-closeout.sh:219:# A closeout with no checks is not unverified: `githooks/pre-push` gated the push that created this
test/baselines/GH-15-parallel-contention-negative-control.md:66:`bash githooks/install.sh`), cloned from the merged `fix/gh-15-parallel-contention-retry` branch:
test/baselines/GH-4-negative-control.md:18:$ bash githooks/install.sh --uninstall
test/baselines/GH-4-negative-control.md:19:githooks: uninstalled — removed .../.git/hooks/pre-push.
test/baselines/GH-4-negative-control.md:24:  .../.git/hooks/pre-push does not exist.
test/baselines/GH-4-negative-control.md:25:  This clone will push WITHOUT running the gate. Fix: bash githooks/install.sh
test/baselines/GH-4-negative-control.md:38:$ bash githooks/install.sh
test/baselines/GH-4-negative-control.md:39:githooks: installed — .../.git/hooks/pre-push
test/baselines/GH-4-negative-control.md:51:The Ballast wave-1 brief scoped lane #4 to `README.md` + `githooks/install.sh` only, explicitly
test/baselines/GH-527-negative-control.md:3:Suite: `test/gh527-destructive-git-guard.sh` (26 pass / 0 fail unmutated)
test/baselines/GH-527-negative-control.md:4:Guard: `relay-automation/hooks/gh527-destructive-git-guard.sh`
test/baselines/GH-527-negative-control.md:16:gh527-destructive-git-guard: 17 pass, 9 fail
test/baselines/GH-527-negative-control.md:38:gh527-destructive-git-guard: 25 pass, 1 fail
test/baselines/GH-527-negative-control.md:53:The suite drives the guard through its PreToolUse payload shape, not through a live Claude Code
test/baselines/GH-544-prepush-negative-control.md:76:`githooks/pre-push`: final `exit 1` → `exit 0`.
test/baselines/GH-544-prepush-negative-control.md:90:`githooks/pre-push`: the `XYZ_SKIP_PREPUSH` message changed to `(silently skipped)`.
test/baselines/GH-544-prepush-negative-control.md:140:   version-controlled; a fresh clone has no gate. `githooks/install.sh --check` exists to make that
test/baselines/GH-544-prepush-negative-control.md:143:## D — GH-549: the pre-fix wiring pushes UNGATED and SILENT from a branch without `githooks/`
test/baselines/GH-544-prepush-negative-control.md:148:`githooks/` directory git resolves no hook file and runs nothing, with no warning.
test/baselines/GH-544-prepush-negative-control.md:166:resolved to the in-tree `githooks/` and the installer targeted the very hook it delegates to. It was
test/baselines/GH-139-pipe-grep-baseline.txt:18:4 test/gh527-destructive-git-guard.sh
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	#
     4	# gh527-destructive-git-guard.sh — GH-527: a git command that overwrites the working tree
     5	# from a committed state must leave the tracked files it destroys recoverable.
     6	#
     7	# The guard is SNAPSHOT-THEN-ALLOW, not refuse-when-dirty, so the assertions below are about
     8	# what it PRESERVES, not what it blocks. Two properties carry the whole issue:
     9	#
    10	#   1. It fires on a dirty tree and the destroyed content is recoverable END-TO-END
    11	#      (GH-527 acceptance 4: "destroy -> recover from the snapshot", demonstrated not asserted).
    12	#   2. It stays SILENT on a clean tree (GH-527 acceptance 3), because a guard that fires on the
    13	#      safe case is a blanket, and a blanket trains the override reflex that makes it useless.
    14	#
    15	# Blast radius is asserted in both directions to match the issue's own reproduced fixture:
    16	# TRACKED modifications are destroyed, untracked files survive. If that ever inverts, the guard
    17	# is snapshotting the wrong set.
    18	
    19	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    20	REPO="$(cd "$HERE/.." && pwd)"
    21	GUARD="$REPO/relay-automation/hooks/gh527-destructive-git-guard.sh"
    22	
    23	pass=0; fail=0
    24	ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
    25	
    26	echo "== test: gh527-destructive-git-guard =="
    27	
    28	mkrepo() {
    29	  _r="$(mktemp -d "${TMPDIR:-/tmp}/gh527.XXXXXX")"
    30	  . "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
    31	  fixture_guard_init "$_r"   # GH-10: pin the sandbox root
    32	  git -C "$_r" init -q
    33	  git -C "$_r" config user.email t@t
    34	  git -C "$_r" config user.name t
    35	  printf 'v1\n' > "$_r/peer.txt"
    36	  git -C "$_r" add peer.txt
    37	  git -C "$_r" commit -qm init
    38	  printf '%s\n' "$_r"
    39	}
    40	
    41	# hook_out <repo> <command> — run the guard with a PreToolUse-shaped payload, capture stderr
    42	hook_out() {
    43	  printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"%s"}}' "$1" "$2" \
    44	    | bash "$GUARD" 2>&1 || true
    45	}
    46	
    47	ok "guard script exists and is executable" "[ -x '$GUARD' ]"
    48	
    49	# --- (1) dirty tree: fires, and the snapshot actually contains the doomed content ------------
    50	R="$(mkrepo)"
    51	printf 'PEER-UNCOMMITTED-WORK\n' > "$R/peer.txt"
    52	printf 'untracked peer work\n'   > "$R/peer-new.txt"
    53	OUT="$(hook_out "$R" "git reset --hard HEAD")"
    54	
    55	ok "dirty tree: guard announces the snapshot" "printf '%s' \"\$OUT\" | grep -q 'snapshot saved'"
    56	ok "dirty tree: message names the command shape" "printf '%s' \"\$OUT\" | grep -q 'reset --hard'"
    57	SNAP="$(ls -d "$R"/.tick/orphan-backups/*/ 2>/dev/null | head -1 || true)"
    58	ok "dirty tree: a snapshot directory was created" "[ -n '$SNAP' ]"
    59	ok "snapshot holds the pre-destruction content" \
    60	   "grep -q 'PEER-UNCOMMITTED-WORK' '$SNAP/peer.txt' 2>/dev/null"
    61	ok "snapshot does NOT include untracked files (they survive the command)" \
    62	   "[ ! -f '$SNAP/peer-new.txt' ]"
    63	
    64	# --- (2) recovery is demonstrated, not asserted (acceptance 4) --------------------------------
    65	git -C "$R" reset --hard HEAD >/dev/null 2>&1
    66	ok "the destructive command really did destroy the tracked edit" \
    67	   "grep -q '^v1$' '$R/peer.txt'"
    68	ok "untracked file survived the command (matches the issue's fixture)" \
    69	   "[ -f '$R/peer-new.txt' ]"
    70	cp -R "$SNAP". "$R"/
    71	ok "RECOVERY: content restored from the snapshot end-to-end" \
    72	   "grep -q 'PEER-UNCOMMITTED-WORK' '$R/peer.txt'"
    73	rm -rf "$R"
    74	
    75	# --- (3) THE CONTROL: clean tree must stay silent (acceptance 3) ------------------------------
    76	# Without this the guard is a blanket. This assertion is the reason the guard checks tracked
    77	# dirt at all rather than simply matching on the command.
    78	C="$(mkrepo)"
    79	OUT="$(hook_out "$C" "git reset --hard HEAD")"
    80	ok "CONTROL: clean tree — guard stays silent" "[ -z \"\$OUT\" ]"
    81	ok "CONTROL: clean tree — no snapshot directory created" \
    82	   "[ -z \"\$(ls -d '$C'/.tick/orphan-backups/*/ 2>/dev/null || true)\" ]"
    83	
    84	# --- (4) every destructive spelling, including the ones an agy review found slipping ----------
    85	# `git checkout <path>` (no `--`) and `git restore <path>` both slipped the first draft's regex.
    86	# They are the most likely spellings an agent reaches for to revert a file, and both were verified
    87	# to destroy a peer edit. Over-matching is cheap here — the guard only ever snapshots — so these
    88	# are matched broadly on purpose.
    89	printf 'dirty\n' > "$C/peer.txt"
    90	# `git clean` is deliberately NOT in this loop: this fixture has only a TRACKED modification, and
    91	# clean does not touch tracked files, so the guard correctly finds nothing to snapshot and stays
    92	# silent. Asserting "snapshot saved" here would demand the wrong behaviour. Section 4b drives clean
    93	# against the set it actually destroys.
    94	for shape in "git reset --hard HEAD" "git checkout -- peer.txt" "git checkout peer.txt" \
    95	             "git restore peer.txt" "git stash"; do
    96	  OUT="$(hook_out "$C" "$shape")"
    97	  ok "fires on: $shape" "printf '%s' \"\$OUT\" | grep -q 'snapshot saved'"
    98	done
    99	
   100	# --- (4b) `git clean` is the INVERSE case, and it needs its own everything --------------------
   101	# clean deletes UNTRACKED files and leaves tracked modifications alone — the exact opposite of the
   102	# other four shapes. The first draft matched clean but still snapshotted only tracked files, so it
   103	# announced cover that did not exist. Worse, the snapshot went into `.tick/`, which `git clean -fdx`
   104	# then deleted along with everything else: the guard destroyed its own evidence. Both found by
   105	# testing recovery rather than asserting it.
   106	K="$(mkrepo)"
   107	printf 'tracked-edit\n' > "$K/peer.txt"          # tracked modification — clean must NOT save this
   108	printf 'UNTRACKED-WORK\n' > "$K/untracked.txt"   # untracked — clean DOES destroy this
   109	OUT="$(hook_out "$K" "git clean -fdx")"
   110	ok "clean: names the untracked set, not the tracked one" \
   111	   "printf '%s' \"\$OUT\" | grep -q 'untracked file'"
   112	CSNAP="$(printf '%s' "$OUT" | sed -n 's/.*snapshot saved -> //p')"
   113	ok "clean: snapshot is OUTSIDE the repo (git clean -x would delete an in-repo one)" \
   114	   "case '$CSNAP' in '$K'*) false ;; /*) true ;; *) false ;; esac"
   115	ok "clean: snapshot holds the untracked file" "[ -f '$CSNAP/untracked.txt' ]"
   116	ok "clean: snapshot does NOT hold the tracked modification (clean would not touch it)" \
   117	   "[ ! -f '$CSNAP/peer.txt' ]"
   118	( cd "$K" && git clean -fdx >/dev/null 2>&1 )
   119	ok "clean really destroyed the untracked file" "[ ! -f '$K/untracked.txt' ]"
   120	ok "clean: the snapshot SURVIVED the command that deleted everything else" "[ -d '$CSNAP' ]"
   121	cp -R "$CSNAP"/. "$K"/ 2>/dev/null || true
   122	ok "clean: RECOVERY restores the untracked file end-to-end" \
   123	   "grep -q 'UNTRACKED-WORK' '$K/untracked.txt' 2>/dev/null"
   124	rm -rf "$CSNAP" "$K"
   125	
   126	# --- (5) read-only git and non-Bash tools must NOT trip it ------------------------------------
   127	for safe in "git status" "git stash list" "git log --oneline" "git diff"; do
   128	  OUT="$(hook_out "$C" "$safe")"
   129	  ok "silent on read-only: $safe" "[ -z \"\$OUT\" ]"
   130	done
   131	OUT="$(printf '{"tool_name":"Edit","cwd":"%s","tool_input":{"command":"git reset --hard"}}' "$C" | bash "$GUARD" 2>&1 || true)"
   132	ok "ignores non-Bash tool calls" "[ -z \"\$OUT\" ]"
   133	
   134	# --- (6) the documented escape hatch works ----------------------------------------------------
   135	OUT="$(printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"git reset --hard HEAD"}}' "$C" \
   136	  | XYZ_NO_GIT_SNAPSHOT=1 bash "$GUARD" 2>&1 || true)"
   137	ok "XYZ_NO_GIT_SNAPSHOT=1 disables the guard" "[ -z \"\$OUT\" ]"
   138	rm -rf "$C"
   139	
   140	# --- (7) the rail exists and names all three shapes (acceptance 1) -----------------------------
   141	ok "AGENTS.md rail names reset --hard"      "grep -q 'reset --hard' '$REPO/AGENTS.md'"
   142	ok "AGENTS.md rail names checkout -- <path>" "grep -q 'checkout --' '$REPO/AGENTS.md'"
   143	ok "AGENTS.md rail names stash"              "grep -qi 'git stash' '$REPO/AGENTS.md'"
   144	ok "AGENTS.md rail points at the guard"      "grep -q 'gh527-destructive-git-guard' '$REPO/AGENTS.md'"
   145	
   146	# --- (8) registered as a PreToolUse Bash hook (acceptance 5) -----------------------------------
   147	ok "hook registered in .claude/settings.json" \
   148	   "grep -q 'gh527-destructive-git-guard' '$REPO/.claude/settings.json'"
   149	
   150	echo "  gh527-destructive-git-guard: $pass pass, $fail fail"
   151	[ "$fail" -eq 0 ]

2026-08-27T15:19:40.726495Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "rg -n --no-heading '("'^|/)debug'"\\.log|debug.log|XYZ_DEBUG_LOG|DEBUG_LOG_FILE' .gitignore **/.gitignore ROUTER.md README.md PROJECT relay-automation utils test 2>/dev/null | head -n 260 && rg -n --no-heading 'git\", \"worktree|git.*worktree.*remove|worktree.*prune|shutil\\.rmtree\\(' utils/py relay-automation | head -n 260 && nl -ba utils/py/relay_drive.py | sed -n '220,290p;410,490p;560,620p' && nl -ba utils/py/marathon_drive.py | sed -n '850,900p;1720,1840p;2635,2700p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-54680-c807n60b
 succeeded in 0ms:
.gitignore:63:debug.log
.gitignore:63:debug.log
test/sentinel-tier1.sh:59:DEBUG_LOG_FILE="$MANUAL_LOG" "$FINDING_NEW" --scope "$ADV_SCOPE" --severity warn "$ADV_MSG" >/dev/null
relay-automation/harvest-findings.sh:3:# debug.log as PDDA-output-contract JSONL findings. Read-only on the relay; append-only on
relay-automation/harvest-findings.sh:4:# debug.log; NO network. Best-effort — a broken harvest must never fail a phase.
relay-automation/harvest-findings.sh:5:# Usage: harvest-findings.sh --relay FILE [--scope S] [--repo R] [--out debug.log]
relay-automation/harvest-findings.sh:20:OUT="${OUT:-debug.log}"
test/gh342-sentinel-debug-log-python.sh:2:# test/gh342-sentinel-debug-log-python.sh — GH-342: the GH-281 Sentinel Tier-1 debug capture must
test/gh342-sentinel-debug-log-python.sh:5:# The gap this pins: XYZ_DEBUG_LOG=1 was honored only by relay-automation/marathon-drive.sh, which
test/gh342-sentinel-debug-log-python.sh:19:#   5  robustness: an unwritable DEBUG_LOG_FILE raises nothing and changes no exit code
test/gh342-sentinel-debug-log-python.sh:23:source "$(dirname "$0")/_setup.sh" gh342-sentinel-debug-log-python
test/gh342-sentinel-debug-log-python.sh:30:unset XYZ_DEBUG_LOG
test/gh342-sentinel-debug-log-python.sh:31:unset DEBUG_LOG_FILE
test/gh342-sentinel-debug-log-python.sh:42:py_has 'os.environ.get("XYZ_DEBUG_LOG", "0") == "1"' \
test/gh342-sentinel-debug-log-python.sh:43:  && pass "1a: opt-in gate reads XYZ_DEBUG_LOG (default off)" || fail "1a: XYZ_DEBUG_LOG gate missing"
test/gh342-sentinel-debug-log-python.sh:44:py_has 'def xyz_debug_log_append(' \
test/gh342-sentinel-debug-log-python.sh:45:  && pass "1b: append helper defined" || fail "1b: xyz_debug_log_append missing"
test/gh342-sentinel-debug-log-python.sh:72:assert "xyz_debug_log_append" in esc, f"escalate() does not append a finding: {sorted(esc)}"
test/gh342-sentinel-debug-log-python.sh:77:assert "xyz_debug_log_append" in gate, f"lane_attempt_gate() does not emit lane-park: {sorted(gate)}"
test/gh342-sentinel-debug-log-python.sh:98:    return d, os.path.join(d, "debug.log")
test/gh342-sentinel-debug-log-python.sh:103:    os.environ.pop("XYZ_DEBUG_LOG", None)
test/gh342-sentinel-debug-log-python.sh:105:        os.environ["XYZ_DEBUG_LOG"] = val
test/gh342-sentinel-debug-log-python.sh:106:    md.xyz_debug_log_append(root, "error", "marathon.escalation", "must not be written")
test/gh342-sentinel-debug-log-python.sh:107:    md.xyz_debug_log_stale_lock(root)
test/gh342-sentinel-debug-log-python.sh:111:        ok(f"2: XYZ_DEBUG_LOG {label} — debug.log not created at all")
test/gh342-sentinel-debug-log-python.sh:113:        bad(f"2: XYZ_DEBUG_LOG {label} wrote {os.path.getsize(log)} bytes to debug.log")
test/gh342-sentinel-debug-log-python.sh:114:os.environ.pop("XYZ_DEBUG_LOG", None)
test/gh342-sentinel-debug-log-python.sh:117:os.environ["XYZ_DEBUG_LOG"] = "1"
test/gh342-sentinel-debug-log-python.sh:119:md.xyz_debug_log_append(
test/gh342-sentinel-debug-log-python.sh:157:md.xyz_debug_log_append(root, "warn", "marathon.lane-park", "m", target_root="/tmp/other")
test/gh342-sentinel-debug-log-python.sh:164:# DEBUG_LOG_FILE override, including the empty-value fallback
test/gh342-sentinel-debug-log-python.sh:168:os.environ["DEBUG_LOG_FILE"] = alt
test/gh342-sentinel-debug-log-python.sh:169:md.xyz_debug_log_append(root, "info", "c", "m")
test/gh342-sentinel-debug-log-python.sh:170:ok("3g: DEBUG_LOG_FILE honored") if os.path.exists(alt) else bad("3g: DEBUG_LOG_FILE ignored")
test/gh342-sentinel-debug-log-python.sh:171:os.environ["DEBUG_LOG_FILE"] = ""
test/gh342-sentinel-debug-log-python.sh:172:md.xyz_debug_log_append(root, "info", "c", "m")
test/gh342-sentinel-debug-log-python.sh:173:if os.path.exists(os.path.join(root, "debug.log")):
test/gh342-sentinel-debug-log-python.sh:174:    ok("3h: an EMPTY DEBUG_LOG_FILE falls back to $ROOT/debug.log (Bash `:=` semantics)")
test/gh342-sentinel-debug-log-python.sh:176:    bad("3h: empty DEBUG_LOG_FILE did not fall back")
test/gh342-sentinel-debug-log-python.sh:177:os.environ.pop("DEBUG_LOG_FILE", None)
test/gh342-sentinel-debug-log-python.sh:188:    ["sed", "-n", r"/^_json_esc()/,/^}/p; /^xyz_debug_log_append()/,/^}/p", sh_twin],
test/gh342-sentinel-debug-log-python.sh:191:if b"xyz_debug_log_append" not in extract.stdout:
test/gh342-sentinel-debug-log-python.sh:207:        env = dict(os.environ, XYZ_DEBUG_LOG="1", DEBUG_LOG_FILE=sh_log,
test/gh342-sentinel-debug-log-python.sh:211:             f'source "{helpers}"; xyz_debug_log_append "$1" "$2" "$3" "$4" "$5" "$6"',
test/gh342-sentinel-debug-log-python.sh:214:        os.environ["DEBUG_LOG_FILE"] = py_log
test/gh342-sentinel-debug-log-python.sh:215:        md.xyz_debug_log_append(root, sev, chk, msg, file=f_, action=act, probe=prb,
test/gh342-sentinel-debug-log-python.sh:217:        os.environ.pop("DEBUG_LOG_FILE", None)
test/gh342-sentinel-debug-log-python.sh:230:os.environ["DEBUG_LOG_FILE"] = os.path.join(root, "no", "such", "dir", "debug.log")
test/gh342-sentinel-debug-log-python.sh:232:    md.xyz_debug_log_append(root, "error", "c", "m")
test/gh342-sentinel-debug-log-python.sh:233:    md.xyz_debug_log_stale_lock(root)
test/gh342-sentinel-debug-log-python.sh:234:    ok("5a: an unwritable DEBUG_LOG_FILE raises nothing (best-effort append)")
test/gh342-sentinel-debug-log-python.sh:241:    os.environ["DEBUG_LOG_FILE"] = os.path.join(ro, "debug.log")
test/gh342-sentinel-debug-log-python.sh:243:        md.xyz_debug_log_append(root, "error", "c", "m")
test/gh342-sentinel-debug-log-python.sh:251:os.environ.pop("DEBUG_LOG_FILE", None)
test/gh342-sentinel-debug-log-python.sh:261:os.environ.pop("XYZ_DEBUG_LOG", None)
test/gh342-sentinel-debug-log-python.sh:262:md.xyz_harvest_findings(harvest, "relay.md", root, None, os.path.join(root, "debug.log"))
test/gh342-sentinel-debug-log-python.sh:264:    ok("6a: harvest NOT spawned when XYZ_DEBUG_LOG is unset")
test/gh342-sentinel-debug-log-python.sh:268:os.environ["XYZ_DEBUG_LOG"] = "1"
test/gh342-sentinel-debug-log-python.sh:269:md.xyz_harvest_findings(harvest, "relay.md", root, "/tmp/tr", os.path.join(root, "debug.log"))
test/gh342-sentinel-debug-log-python.sh:282:    md.xyz_harvest_findings(harvest, "relay.md", root, None, os.path.join(root, "debug.log"))
test/gh342-sentinel-debug-log-python.sh:287:os.environ.pop("XYZ_DEBUG_LOG", None)
test/gh342-sentinel-debug-log-python.sh:318:DBG="$WORK/e2e-debug.log"
test/gh342-sentinel-debug-log-python.sh:320:run_md() {  # run_md <XYZ_DEBUG_LOG value or empty> [XYZ_PYTHON value]
test/gh342-sentinel-debug-log-python.sh:324:  env ${dbg:+XYZ_DEBUG_LOG="$dbg"} ${pyflag:+XYZ_PYTHON="$pyflag"} \
test/gh342-sentinel-debug-log-python.sh:325:      DEBUG_LOG_FILE="$DBG" MARATHON_ROOT="$A" TICK_BIN="$TICK" \
test/gh342-sentinel-debug-log-python.sh:353:  && pass "7b: flag off — no debug.log created by a real default-lane run" \
test/gh342-sentinel-debug-log-python.sh:354:  || fail "7b: flag off but debug.log exists (rc=$rc, exists=$([ -e "$DBG" ] && echo yes || echo no))"
relay-automation/marathon-drive.sh:173:: "${XYZ_DEBUG_LOG:=0}"
relay-automation/marathon-drive.sh:174:: "${DEBUG_LOG_FILE:=$ROOT/debug.log}"
relay-automation/marathon-drive.sh:220:    if [[ "${XYZ_DEBUG_LOG:-0}" == "1" ]]; then
relay-automation/marathon-drive.sh:222:          "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$ROOT" >> "${DEBUG_LOG_FILE:-$ROOT/debug.log}"; } 2>/dev/null || true
relay-automation/marathon-drive.sh:462:# Sentinel Tier 1 (GH-281): append ONE PDDA-output-contract JSONL finding to $DEBUG_LOG_FILE.
relay-automation/marathon-drive.sh:463:# Opt-in (XYZ_DEBUG_LOG=1), default off. Writes only this one local file — no network, no
relay-automation/marathon-drive.sh:469:xyz_debug_log_append() {  # <severity> <check> <message> [file] [action] [probe]
relay-automation/marathon-drive.sh:470:  [[ "${XYZ_DEBUG_LOG:-0}" == "1" ]] || return 0
relay-automation/marathon-drive.sh:477:    >> "$DEBUG_LOG_FILE" 2>/dev/null || true
relay-automation/marathon-drive.sh:857:  if [[ "${XYZ_DEBUG_LOG:-0}" == "1" && -x "$HERE/harvest-findings.sh" ]]; then
relay-automation/marathon-drive.sh:860:      --out "${DEBUG_LOG_FILE:-$ROOT/debug.log}" >/dev/null 2>&1 || true
relay-automation/marathon-drive.sh:875:  xyz_debug_log_append error "marathon.escalation" "$reason (relay-drive-exit=$rexit)" \
relay-automation/marathon-drive.sh:889:  if [[ "${XYZ_DEBUG_LOG:-0}" == "1" && -x "$HERE/harvest-findings.sh" ]]; then
relay-automation/marathon-drive.sh:892:      --out "${DEBUG_LOG_FILE:-$ROOT/debug.log}" >/dev/null 2>&1 || true
relay-automation/marathon-drive.sh:1140:  xyz_debug_log_append warn "marathon.lane-park" "lane $LANE_STATE_KEY parked at attempt cap" \
test/sentinel-driver-hooks.sh:3:#   #1 default-off: the append helper writes nothing when XYZ_DEBUG_LOG is unset or 0.
test/sentinel-driver-hooks.sh:18:# driver's main body). The functions reference ROOT/TARGET_ROOT/PHASE_ID/RELAY_TASK/DEBUG_LOG_FILE.
test/sentinel-driver-hooks.sh:19:sed -n '/^_json_esc()/,/^}/p; /^xyz_debug_log_append()/,/^}/p' "$DRIVE" > "$WORK/helpers.sh"
test/sentinel-driver-hooks.sh:20:grep -q 'xyz_debug_log_append' "$WORK/helpers.sh" || { echo "FAIL: could not extract helpers" >&2; exit 1; }
test/sentinel-driver-hooks.sh:23:LOG="$WORK/debug.log"; DEBUG_LOG_FILE="$LOG"
test/sentinel-driver-hooks.sh:28:unset XYZ_DEBUG_LOG 2>/dev/null || true
test/sentinel-driver-hooks.sh:29:xyz_debug_log_append error marathon.escalation "should not be written"
test/sentinel-driver-hooks.sh:30:[[ ! -e "$LOG" ]] || { echo "FAIL: default-off (unset) wrote to debug.log" >&2; exit 1; }
test/sentinel-driver-hooks.sh:31:XYZ_DEBUG_LOG=0 xyz_debug_log_append error marathon.escalation "still off"
test/sentinel-driver-hooks.sh:32:[[ ! -e "$LOG" ]] || { echo "FAIL: XYZ_DEBUG_LOG=0 wrote to debug.log" >&2; exit 1; }
test/sentinel-driver-hooks.sh:35:export XYZ_DEBUG_LOG=1
test/sentinel-driver-hooks.sh:36:xyz_debug_log_append error "marathon.escalation" "$(printf 'no-progress\t"x" \\y')" "phases/p1/RELAY.md" "promote"
test/sentinel-driver-hooks.sh:51:  ': "${XYZ_DEBUG_LOG:=0}"'                            # (0) opt-in default
test/sentinel-driver-hooks.sh:52:  'xyz_debug_log_append() {'                           # (1) append helper
test/sentinel-driver-hooks.sh:53:  'xyz_debug_log_append error "marathon.escalation"'   # (2) escalation hook
test/gh376-relay-drive-lock-parity.sh:44:# gh342-sentinel-debug-log-python.sh:27. Section F below then re-asserts the inherited=1 behaviour
relay-automation/finding-new.sh:2:# finding-new.sh — manually append one PDDA-output-contract JSONL finding to debug.log. NO network.
relay-automation/finding-new.sh:17:OUT="${DEBUG_LOG_FILE:-$ROOT/debug.log}"
test/sentinel-overlay.sh:39:printf '%s\n' '{"timestamp":"t","severity":"error","check":"marathon.escalation","scope":"harness","repo":"r","message":"boom","action":"triage","probe":"false"}' > "$WORK/debug.log"
test/sentinel-overlay.sh:41:ri(){ PATH="$BIN:$PATH" SENTINEL_DEBUG_LOG="$WORK/debug.log" SENTINEL_INBOX="$WORK/inbox" SENTINEL_WORKING="$WORK/working" "$@"; }
test/sentinel-overlay.sh:46:ri bash "$OV/adversarial-review.sh" --diff-file "$WORK/debug.log" >/dev/null 2>&1 || fail "adversarial errored when inert"
test/sentinel-overlay.sh:54:  SENTINEL_DEBUG_LOG="$WORK/debug.log" SENTINEL_INBOX="$WORK/inbox2" \
test/sentinel-overlay.sh:65:  SENTINEL_DEBUG_LOG="$WORK/debug.log" SENTINEL_INBOX="$WORK/inbox2" \
PROJECT/2-WORKING/GH-251-VALIDATE-PYTEST-SKIP.md:46:- Precedent: `test/gh342-sentinel-debug-log-python.sh:249` — "say so rather than reporting a pass
PROJECT/2-WORKING/GH-249-CANARY-EUID-ROOT-ASSERTIONS.md:55:- Follow the existing in-repo precedent at `test/gh342-sentinel-debug-log-python.sh:249` — a named
PROJECT/2-WORKING/GH-249-CANARY-EUID-ROOT-ASSERTIONS.md:67:- `test/gh50-sandboxed-git-guard.sh` · `test/security-scan.sh` · `test/gh342-sentinel-debug-log-python.sh:249`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md:272:- #342 GH-342 · Sentinel Tier-1 debug capture (XYZ_DEBUG_LOG) never ran on the default lane — `blocked`
utils/py/marathon_drive.py:97:# XYZ_DEBUG_LOG=1 on a normal run wrote nothing. Contract preserved exactly, including the parts
utils/py/marathon_drive.py:99:#   · opt-in, DEFAULT OFF — an unset/0 XYZ_DEBUG_LOG must not create the file at all
utils/py/marathon_drive.py:100:#   · writes ONE local file ($DEBUG_LOG_FILE, default $ROOT/debug.log) — no network, no telemetry
utils/py/marathon_drive.py:119:def xyz_debug_log_enabled():
utils/py/marathon_drive.py:121:    return os.environ.get("XYZ_DEBUG_LOG", "0") == "1"
utils/py/marathon_drive.py:124:def xyz_debug_log_file(root):
utils/py/marathon_drive.py:125:    """`: "${DEBUG_LOG_FILE:=$ROOT/debug.log}"` — an explicitly EMPTY value falls back too."""
utils/py/marathon_drive.py:126:    return os.environ.get("DEBUG_LOG_FILE") or os.path.join(root, "debug.log")
utils/py/marathon_drive.py:129:def _xyz_debug_log_write(root, line):
utils/py/marathon_drive.py:132:        with open(xyz_debug_log_file(root), "a") as fh:
utils/py/marathon_drive.py:138:def xyz_debug_log_append(root, severity, check, message,
utils/py/marathon_drive.py:141:    """Append ONE PDDA-output-contract JSONL finding. No-op unless XYZ_DEBUG_LOG=1.
utils/py/marathon_drive.py:148:    if not xyz_debug_log_enabled():
utils/py/marathon_drive.py:151:    _xyz_debug_log_write(root, (
utils/py/marathon_drive.py:162:def xyz_debug_log_stale_lock(root):
utils/py/marathon_drive.py:165:    Deliberately NOT routed through xyz_debug_log_append: `marathon-drive.sh:220` inlines a SHORTER
utils/py/marathon_drive.py:171:    if not xyz_debug_log_enabled():
utils/py/marathon_drive.py:173:    _xyz_debug_log_write(root, (
utils/py/marathon_drive.py:179:def xyz_harvest_findings(harvest_bin, relay_file, root, target_root, debug_log):
utils/py/marathon_drive.py:180:    """Spawn harvest-findings.sh to pull a relay's Side Findings into the debug log.
utils/py/marathon_drive.py:182:    Gated on XYZ_DEBUG_LOG=1 AND the script being executable, exactly as the two Bash call sites
utils/py/marathon_drive.py:186:    if not xyz_debug_log_enabled():
utils/py/marathon_drive.py:195:             "--out", debug_log],
utils/py/marathon_drive.py:746:            xyz_debug_log_append(
utils/py/marathon_drive.py:871:            xyz_debug_log_stale_lock(root)
utils/py/marathon_drive.py:1419:            xyz_debug_log_append(
utils/py/marathon_drive.py:1599:                             xyz_debug_log_file(root))
utils/py/marathon_drive.py:1658:        xyz_debug_log_append(
utils/py/marathon_drive.py:1680:                             xyz_debug_log_file(root))
utils/py/review_xyz.py:689:                    ["git", "-C", root, "worktree", "remove", "--force", wt_dir],
utils/py/review_xyz.py:695:            shutil.rmtree(wt_dir, ignore_errors=True)
utils/py/self_healer.py:359:            shutil.rmtree(sandbox_root, ignore_errors=True)
utils/py/self_healer.py:472:        shutil.rmtree(tmp_dir, ignore_errors=True)
utils/py/claude-turn.py:195:        shutil.rmtree(shadow_dir, ignore_errors=True)
relay-automation/consult.sh:144:  git -C "$ROOT" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"
relay-automation/consult.sh:145:  git -C "$ROOT" worktree prune >/dev/null 2>&1 || true
relay-automation/relay-turn-lib.sh:874:  git -C "$RTL_ROOT" worktree remove --force "$wt" >/dev/null 2>&1 || rm -rf "$wt"
relay-automation/relay-turn-lib.sh:875:  git -C "$RTL_ROOT" worktree prune >/dev/null 2>&1 || true
utils/py/workspace_manager.py:107:                shutil.rmtree(p, ignore_errors=True)
utils/py/workspace_manager.py:283:            res = subprocess.run(["git", "-C", repo_root, "worktree", "remove", p],
utils/py/swarm_preflight.py:1269:    shutil.rmtree(ref_wt)
utils/py/swarm_preflight.py:1291:    try: subprocess.check_call(["git", "-C", target_root, "worktree", "remove", "--force", ref_wt], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
utils/py/swarm_preflight.py:1292:    except: shutil.rmtree(ref_wt, ignore_errors=True)
utils/py/swarm_preflight.py:1293:    try: subprocess.check_call(["git", "-C", target_root, "worktree", "prune"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
utils/py/relay_drive.py:457:                shutil.rmtree(lock_dir)
utils/py/relay_drive.py:473:            try: shutil.rmtree(lock_dir)
utils/py/repro_builder.py:438:        shutil.rmtree(tmp_dir, ignore_errors=True)
utils/py/agy-turn.py:233:            shutil.rmtree(probe_cwd, ignore_errors=True)
utils/py/consult.py:748:        subprocess.run(["git", "-C", root, "worktree", "remove", "--force", wt], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
utils/py/consult.py:749:        subprocess.run(["git", "-C", root, "worktree", "prune"], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
utils/py/consult.py:751:            shutil.rmtree(wt, ignore_errors=True)
utils/py/marathon_drive.py:873:                shutil.rmtree(lock_dir)
utils/py/marathon_drive.py:884:            try: shutil.rmtree(lock_dir)
utils/py/jog_run.py:88:                shutil.rmtree(self.lock_dir)
utils/py/jog_run.py:107:                    shutil.rmtree(self.lock_dir)
utils/py/active_explorer.py:307:        shutil.rmtree(tmp_dir, ignore_errors=True)
utils/py/marathon_plan.py:173:        shutil.rmtree(tmp_dir, ignore_errors=True)
utils/py/marathon_plan.py:178:        shutil.rmtree(tmp_dir, ignore_errors=True)
utils/py/marathon_plan.py:184:            shutil.rmtree(tmp_dir, ignore_errors=True)
utils/py/marathon_plan.py:189:            shutil.rmtree(tmp_dir, ignore_errors=True)
utils/py/marathon_plan.py:194:            shutil.rmtree(tmp_dir, ignore_errors=True)
utils/py/marathon_plan.py:198:        shutil.rmtree(tmp_dir, ignore_errors=True)
utils/py/marathon_plan.py:207:    shutil.rmtree(tmp_dir, ignore_errors=True)
   220	            tick_repo_root = root_dir
   221	        os.environ["TICK_REPO_ROOT"] = tick_repo_root
   222	
   223	    # check lane attempt
   224	    if not args.dry_run and not args.review_once:
   225	        lane_attempt_gate(tick_repo_root, args.relay_task, args.force)
   226	
   227	    if "RELAY_WORKTREE_ISOLATION" not in os.environ:
   228	        os.environ["RELAY_WORKTREE_ISOLATION"] = "1"
   229	
   230	    def warn_if_relay_file_untracked():
   231	        if get_env("RELAY_WORKTREE_ISOLATION", "1") == "0":
   232	            return
   233	        rdir = os.path.dirname(os.path.abspath(relay_file))
   234	        if not os.path.isdir(rdir):
   235	            return
   236	
   237	        try:
   238	            prefix = subprocess.check_output(["git", "-C", rdir, "rev-parse", "--show-prefix"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
   239	        except Exception:
   240	            return
   241	        rel = prefix + os.path.basename(relay_file)
   242	        try:
   243	            subprocess.run(["git", "-C", rdir, "cat-file", "-e", f"HEAD:{rel}"], stderr=subprocess.DEVNULL, check=True)
   244	            return
   245	        except subprocess.CalledProcessError:
   246	            pass
   247	
   248	        try:
   249	            relay_toplevel = subprocess.check_output(["git", "-C", rdir, "rev-parse", "--show-toplevel"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
   250	            effective_root = get_env("RELAY_TARGET_ROOT", root_dir)
   251	            effective_toplevel = subprocess.check_output(["git", "-C", effective_root, "rev-parse", "--show-toplevel"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
   252	        except Exception:
   253	            relay_toplevel = ""
   254	            effective_toplevel = ""
   255	
   256	        if relay_toplevel and relay_toplevel == effective_toplevel:
   257	            eprint(f"relay-drive: NOTE — relay file is not committed at HEAD: {rel}")
   258	            eprint("  RELAY_WORKTREE_ISOLATION=1 runs the turn-taker in a worktree at HEAD, but its own")
   259	            eprint("  worktree-seeding step copies this file's current content in regardless — this is")
   260	            eprint("  usually fine. Commit it for a clean paper trail, or re-run with")
   261	            eprint("  RELAY_WORKTREE_ISOLATION=0 if you want to rule out isolation entirely; neither is required.")
   262	        else:
   263	            eprint(f"relay-drive: WARNING — relay file is not committed at HEAD: {rel}")
   264	            eprint("  It lives in a DIFFERENT repo than the turn-taker's root (archive-routed?), so the")
   265	            eprint("  usual worktree-seeding fallback does NOT cover it — it may be genuinely INVISIBLE to")
   266	            eprint("  the reviewer (it will find nothing and do no work). Remedy: commit the relay file")
   267	            eprint("  first, or re-run with RELAY_WORKTREE_ISOLATION=0.")
   268	
   269	    warn_if_relay_file_untracked()
   270	
   271	    if args.artifact_file:
   272	        if not os.path.isfile(args.artifact_file):
   273	            die(f"artifact file not found: {args.artifact_file}")
   274	        if not args.artifact_file.startswith("/"):
   275	            args.artifact_file = os.path.abspath(args.artifact_file)
   276	        os.environ["RELAY_ARTIFACT_FILE"] = args.artifact_file
   277	        if get_env("RELAY_WORKTREE_ISOLATION", "1") == "0":
   278	            eprint("relay-drive: WARNING — --artifact-file needs worktree isolation to seed the artifact; with RELAY_WORKTREE_ISOLATION=0 the reviewer will not see it.")
   279	
   280	    def file_status():
   281	        try:
   282	            with open(relay_file, 'r') as f:
   283	                for line in f:
   284	                    if line.startswith("STATUS:"):
   285	                        return line.split(":", 1)[1].strip()
   286	        except: pass
   287	        return ""
   288	
   289	    def next_pointer():
   290	        try:
   410	                    if line.startswith("# "):
   411	                        title = line[2:].strip()
   412	                        break
   413	        except: pass
   414	        if not title: title = slug
   415	        s = file_status()
   416	        desc = f"Relay session ended: STATUS {s or 'unknown'} (health {health})."
   417	        subprocess.run([xyz_append_bin, "relay", slug, health, title, desc], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
   418	
   419	    if get_env("RELAY_DRIVER_LOCKED", "0") != "1":
   420	        # GH-376: this was a 2-branch guess (.git is a dir -> .git/relay-driver.lock, ELSE a hidden
   421	        # lock beside the scripts) with no case for a linked worktree, where .git is a FILE. That
   422	        # topology is not exotic — it is the one swarm-preflight's own recommended invocation creates
   423	        # via RELAY_WORKTREE_ISOLATION=1. The marathon driver already followed .git to the git COMMON
   424	        # dir, so the two drivers resolved DIFFERENT paths from the same tree and each held what it
   425	        # believed was the one mutex, invisible to the other. marathon-drive.sh:195-196 asserts in
   426	        # prose that they mutually exclude; this call is what makes that true.
   427	        #
   428	        # driver_lock_path is #448's shared resolver (Bash twin: relay-automation/driver-lock-lib.sh).
   429	        # Reused, never reimplemented — a fourth inline copy is the bug class, not the fix.
   430	        lock_dir, lock_label = driver_lock_path(root_dir)
   431	
   432	
   433	        try:
   434	            os.mkdir(lock_dir)
   435	        except OSError:
   436	            holder = ""
   437	            pid_file = os.path.join(lock_dir, "pid")
   438	            if os.path.isfile(pid_file):
   439	                try:
   440	                    with open(pid_file, 'r') as f: holder = f.read().strip()
   441	                except: pass
   442	            
   443	            is_running = False
   444	            if holder:
   445	                try:
   446	                    os.kill(int(holder), 0)
   447	                    is_running = True
   448	                except: pass
   449	            
   450	            if is_running:
   451	                eprint(f"relay-drive: another driver is active in this repo (pid {holder}, lock: {lock_label}).")
   452	                eprint("relay-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).")
   453	                sys.exit(1)
   454	            
   455	            eprint(f"relay-drive: reclaiming stale relay-driver.lock (holder pid {holder or 'none'} not running).")
   456	            try:
   457	                shutil.rmtree(lock_dir)
   458	                os.mkdir(lock_dir)
   459	            except:
   460	                eprint("relay-drive: could not acquire relay-driver.lock after reclaiming a stale one.")
   461	                sys.exit(1)
   462	        
   463	        with open(os.path.join(lock_dir, "pid"), 'w') as f:
   464	            f.write(str(os.getpid()) + "\n")
   465	        
   466	        os.environ["RELAY_DRIVER_LOCKED"] = "1"
   467	        # GH-331: the cost summary is wired into the SAME atexit as the lock cleanup (the one place
   468	        # every exit path funnels through), mirroring relay-drive.sh's GH-152 EXIT trap. The summary
   469	        # runs FIRST, then the lock is removed. Skipped entirely when nested (RELAY_DRIVER_LOCKED=1):
   470	        # the outer driver owns this exit hook, exactly as the Bash trap is only armed by the lock owner.
   471	        def _relay_drive_on_exit():
   472	            xyz_relay_cost_summary()
   473	            try: shutil.rmtree(lock_dir)
   474	            except: pass
   475	        import atexit
   476	        atexit.register(_relay_drive_on_exit)
   477	
   478	    # #129/#136: the announcement half of the self-resolution computed above the lane gate.
   479	    # Printed HERE, after the lock, because a held lock must stay the FIRST thing this driver
   480	    # can print, byte-identical to the frozen Bash twin — gh376's twin-parity pin, observed live
   481	    # in the Wave-1 run when the NOTE printed first and parity went red.
   482	    #
   483	    # BASH/PYTHON DIVERGENCE, deliberate and pinned (#138): the frozen twin
   484	    # (relay-automation/relay-drive.sh, GH-308) has none of this — no self-resolution, and its
   485	    # not-found diagnostic still reads "token missing". The twin is not to be taught this fix
   486	    # without a `Frozen-twin-exception:` trailer; recorded here so a `XYZ_PYTHON=0` run is not
   487	    # misread as a regression (the #379/#380 lesson: undocumented divergences generate false
   488	    # bug reports against the dead half).
   489	    if self_resolved:
   490	        eprint(f"relay-drive: NOTE — TICK_REPO_ROOT unset; self-resolved to {tick_repo_root} (#129)")
   560	
   561	        if args.dry_run:
   562	            print(f"relay-drive: WOULD drive turn for agent: {actor} (token {tstatus}, STATUS: {s})")
   563	            sys.exit(0)
   564	
   565	        cost_summary_state["started"] = True   # GH-331: past here a turn is really being driven — arm the summary
   566	        prev = f"{tstatus}:{actor}"
   567	        rfsig = relay_content_sig()   # GH-245: relay-file content signature BEFORE the turn
   568	        nextp = next_pointer()        # GH-245: NEXT: handoff pointer BEFORE the turn
   569	        head_before = get_head_commit()
   570	        resolved_before = count_resolved_items()
   571	        os.environ["RELAY_FILE"] = relay_file
   572	        os.environ["RELAY_TASK"] = args.relay_task
   573	        os.environ["RELAY_AGENT"] = actor
   574	        
   575	        # Execute agent-cmd with RSS measurement (GH-382)
   576	        peak_turn_rss_mb = 0
   577	        if os.access(args.agent_cmd, os.X_OK):
   578	            proc = subprocess.Popen([args.agent_cmd], start_new_session=True)
   579	        else:
   580	            proc = subprocess.Popen(args.agent_cmd, shell=True, executable="/bin/bash", start_new_session=True)
   581	        while proc.poll() is None:
   582	            try:
   583	                out = subprocess.run(["ps", "-axo", "pgid=,rss="], capture_output=True, text=True, timeout=5).stdout
   584	                total_kb = 0
   585	                for line in out.splitlines():
   586	                    parts = line.split()
   587	                    if len(parts) == 2 and int(parts[0]) == proc.pid:
   588	                        total_kb += int(parts[1])
   589	                rss_mb = total_kb // 1024
   590	                if rss_mb > peak_turn_rss_mb:
   591	                    peak_turn_rss_mb = rss_mb
   592	            except Exception:
   593	                pass
   594	            time.sleep(0.1)
   595	
   596	        res_code = proc.returncode
   597	        if peak_turn_rss_mb > 0 and tick_bin:
   598	            try:
   599	                env = os.environ.copy()
   600	                env["TICK_REPO_ROOT"] = tick_repo_root
   601	                subprocess.run([tick_bin, "cost", args.relay_task, "--agent", actor, "--peak-rss-mb", str(peak_turn_rss_mb)], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
   602	            except Exception:
   603	                pass
   604	        if res_code != 0:
   605	            sys.exit(res_code)
   606	            
   607	        round_idx += 1
   608	        
   609	        if args.consult_verify:
   610	            # We skip this port since it relies on bashisms in consult_verify and it's long. Wait, I should port it.
   611	            # I will just write a small stub here or actually port it if it's strictly needed.
   612	            # actually I will port it fully.
   613	            pass
   614	            # consult_verify logic
   615	            taker_verdict = ""
   616	            try:
   617	                # Get the last VERDICT
   618	                with open(relay_file, 'r') as f:
   619	                    content = f.read()
   620	                log_idx = content.find("## Log")
   850	            pid_file = os.path.join(lock_dir, "pid")
   851	            if os.path.isfile(pid_file):
   852	                try:
   853	                    with open(pid_file, 'r') as f: holder = f.read().strip()
   854	                except: pass
   855	            
   856	            is_running = False
   857	            if holder:
   858	                try:
   859	                    os.kill(int(holder), 0)
   860	                    is_running = True
   861	                except: pass
   862	            
   863	            if is_running:
   864	                eprint(f"marathon-drive: another driver is active in this repo (pid {holder}, lock: {lock_label}).")
   865	                eprint("marathon-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).")
   866	                sys.exit(1)
   867	            
   868	            eprint(f"marathon-drive: reclaiming stale relay-driver.lock (holder pid {holder or 'none'} not running).")
   869	            # Sentinel Tier 1 (GH-281/GH-342): record the auto-heal. Emitted BEFORE the reclaim, so
   870	            # the finding survives even if the rmtree/mkdir below fails and the run exits 1.
   871	            xyz_debug_log_stale_lock(root)
   872	            try:
   873	                shutil.rmtree(lock_dir)
   874	                os.mkdir(lock_dir)
   875	            except:
   876	                eprint("marathon-drive: could not acquire relay-driver.lock after reclaiming a stale one.")
   877	                sys.exit(1)
   878	        
   879	        with open(os.path.join(lock_dir, "pid"), 'w') as f:
   880	            f.write(str(os.getpid()) + "\n")
   881	        
   882	        os.environ["RELAY_DRIVER_LOCKED"] = "1"
   883	        def cleanup_lock():
   884	            try: shutil.rmtree(lock_dir)
   885	            except: pass
   886	        import atexit
   887	        atexit.register(cleanup_lock)
   888	
   889	    xyz_append_bin = get_env("XYZ_APPEND_BIN", os.path.join(xyz_harness, "utils", "telemetry", "append-xyz-completion.sh"))
   890	
   891	    def xyz_marathon_emit(health, desc):
   892	        ctx = get_env("XYZ_HARNESS_CONTEXT", "")
   893	        if ctx == "marathon-phase": return
   894	        if not os.access(xyz_append_bin, os.X_OK): return
   895	        
   896	        harness = "swarm" if ctx == "swarm" else "marathon"
   897	        title = os.path.splitext(os.path.basename(args.phase_brief_file))[0]
   898	        if not title: title = args.phase_id
   899	        
   900	        sid = get_env("XYZ_SESSION_ID", args.phase_id)
  1720	    #     here raises ModuleNotFoundError and takes the whole driver down. Measured, not guessed.
  1721	    #
  1722	    # The two copies cannot drift: test/gh441-gate-env-contract.sh asserts this literal is exactly
  1723	    # gate_env.SCRUBBED_NAMES, and fails if either side changes alone.
  1724	    #
  1725	    # RELAY_DRIVER_LOCKED is deliberately ABSENT — scrubbing it globally was landed and reverted on
  1726	    # 2026-08-07 (nested drivers need it SET, lock assertions need it UNSET; no global value is
  1727	    # correct). See gate_env.py's docstring for the measured matrix.
  1728	    GATE_SCRUBBED_ENV = (
  1729	        "AGY_AGENT", "AIDER_AGENT", "ALLOW_PATHS",
  1730	        "CLAUDE_AGENT", "CODEX_AGENT", "MARATHON_ALLOW_PLAN_OUTSIDE_WORKING",
  1731	        "MARATHON_BUILDER",
  1732	        "MARATHON_LANE_NS", "MARATHON_REVIEWER", "RELAY_AGENT",
  1733	        "PI_AGENT", "RELAY_ARTIFACT_FILE", "RELAY_FILE", "RELAY_PEER",
  1734	        "SMALLCODE_AGENT",
  1735	        "RELAY_TARGET_ROOT", "RELAY_TASK", "RELAY_WORKTREE_ISOLATION",
  1736	        "RELAY_TOOL_MODE", "XYZ_TOOL_MODE",
  1737	        "XYZ_HARNESS_CONTEXT", "XYZ_SESSION_ID",
  1738	    )
  1739	
  1740	    def _gate_env():
  1741	        env = os.environ.copy()
  1742	        for var in GATE_SCRUBBED_ENV:
  1743	            env.pop(var, None)
  1744	        return env
  1745	
  1746	    # GH-390 Phase 1 — layered gate guard.
  1747	    #
  1748	    # The gate executes code an LLM wrote seconds earlier, and by the packet's own instruction the
  1749	    # builder must NOT run the gate itself ("it can create files that trip containment and discard
  1750	    # your turn"). The gate is therefore, by construction, the FIRST execution of anything the
  1751	    # builder wrote — yet it ran with no timeout, no resource bounds, and in the marathon's own
  1752	    # process group. Twice on 2026-07-30 (GH-382) a generated test mocked a paging function with a
  1753	    # constant return_value against a `while True:` loop; MagicMock recorded ~1 KB per call until
  1754	    # all 30.75 GB of swap was gone and the host kernel-panicked.
  1755	    #
  1756	    # The framing that matters: the target's suite is the WORKPIECE, not trusted infrastructure.
  1757	    # It must be assumed hostile the way CI assumes a PR is hostile.
  1758	    #
  1759	    # Measured on the crash host (Darwin 24.6, arm64) — not assumed from Linux habit:
  1760	    #   setrlimit(RLIMIT_AS)  / ulimit -v  -> REFUSED, EINVAL, even soft-only
  1761	    #   setrlimit(RLIMIT_DATA)/ ulimit -d  -> REFUSED, same
  1762	    #   setrlimit(RLIMIT_CPU) / ulimit -t  -> works (layer 2 below)
  1763	    #   process-group RSS poll + killpg    -> works (layer 3 below)
  1764	    # On Linux `ulimit -v` alone would have turned both crashes into a MemoryError inside pytest.
  1765	    # On macOS kernel-enforced MEMORY caps do not exist for ordinary processes, so layer 3 is not
  1766	    # a belt-and-braces extra — it is the only thing standing between a runaway test and the host.
  1767	    #
  1768	    # Layer 4 (host free-memory floor) and packet-driven per-phase overrides are Phase 2.
  1769	    def run_pre_advance_gate():
  1770	        cwd = args.target_root if args.target_root else None
  1771	        env = _gate_env()
  1772	
  1773	        # The escape hatch is load-bearing for a same-day ship: a guard that false-positives would
  1774	        # otherwise block every marathon until someone can land a revert. This restores the exact
  1775	        # pre-GH-390 call, including running in the marathon's own process group.
  1776	        if os.environ.get("MARATHON_GATE_GUARD", "1").strip() == "0":
  1777	            log("gate-guard: disabled via MARATHON_GATE_GUARD=0 — running the gate unguarded")
  1778	            rc = subprocess.run(pre_advance_cmd, shell=True, executable="/bin/bash",
  1779	                                cwd=cwd, env=env).returncode
  1780	            baseline_allow = args.pre_advance_baseline or os.environ.get("MARATHON_GATE_BASELINE")
  1781	            if baseline_allow and rc != 0 and rc != GATE_GUARD_KILL_EXIT:
  1782	                try:
  1783	                    base_rc = int(baseline_allow)
  1784	                    if rc == base_rc or (rc > 0 and rc <= base_rc):
  1785	                        log(f"gate-baseline: gate exit {rc} matches recorded baseline allowance ({base_rc}) — allowing advance (GH-378)")
  1786	                        run_gate_result[0] = "green"
  1787	                        return 0
  1788	                except ValueError:
  1789	                    pass
  1790	            run_gate_result[0] = "green" if rc == 0 else "red"
  1791	            return rc
  1792	
  1793	        cfg = _gate_guard_config()
  1794	        cmd = pre_advance_cmd
  1795	        if cfg["cpu_s"] > 0:
  1796	            # Layer 2. Unlike the RSS poll below this cannot be raced, and it still fires if this
  1797	            # driver process itself wedges — the one bound that does not depend on the watchdog.
  1798	            #
  1799	            # The soft cap MUST sit below the hard cap. A bare `ulimit -t N` sets both to N, and
  1800	            # Linux's posix_cpu_timers tests the hard limit FIRST — so at N seconds it delivers
  1801	            # SIGKILL and SIGXCPU is never sent at all, making the signal this layer is built to
  1802	            # recognize unreachable. macOS's BSD path delivers SIGXCPU for the same limits, which
  1803	            # is why this only ever failed on CI. Splitting the two restores the intended signal
  1804	            # and leaves the hard cap as a backstop for a gate that ignores SIGXCPU.
  1805	            cmd = (f"ulimit -H -t {cfg['cpu_s'] + GATE_CPU_HARD_MARGIN_S} 2>/dev/null || true; "
  1806	                   f"ulimit -S -t {cfg['cpu_s']}; {pre_advance_cmd}")
  1807	
  1808	        # start_new_session=True makes the gate a session and process-group leader (pgid == pid),
  1809	        # which is what lets layer 3 measure and kill the whole tree rather than just the shell.
  1810	        proc = subprocess.Popen(cmd, shell=True, executable="/bin/bash", cwd=cwd, env=env,
  1811	                                start_new_session=True)
  1812	        started = time.monotonic()
  1813	        peak_rss_mb = 0
  1814	        rc = None
  1815	        while rc is None:
  1816	            rc = proc.poll()
  1817	            if rc is not None:
  1818	                break
  1819	            elapsed = int(time.monotonic() - started)
  1820	            rss_mb = _gate_group_rss_mb(proc.pid)
  1821	            peak_rss_mb = max(peak_rss_mb, rss_mb)
  1822	            reason = None
  1823	            if cfg["wall_s"] > 0 and elapsed >= cfg["wall_s"]:
  1824	                reason = f"wall clock {elapsed}s >= cap {cfg['wall_s']}s"
  1825	            elif cfg["rss_mb"] > 0 and rss_mb >= cfg["rss_mb"]:
  1826	                reason = f"gate group RSS {rss_mb}MB >= cap {cfg['rss_mb']}MB"
  1827	            if reason:
  1828	                _gate_kill_group(proc, reason)
  1829	                rc = GATE_GUARD_KILL_EXIT
  1830	                break
  1831	            time.sleep(cfg["poll_s"])
  1832	
  1833	        # A layer-2 kill never comes through the poll loop above — the kernel reaps the gate without
  1834	        # consulting us. Left unmapped it would escalate as `pre-advance-failed`, i.e. as the gate
  1835	        # having found a defect in the change, which is the single most misleading thing this guard
  1836	        # could report. Only mapped when we set the cap.
  1837	        #
  1838	        # It arrives in TWO shapes, and which one depends on the bash build, not on us:
  1839	        #   128+SIGXCPU (152) — bash forked the gate, reaped SIGXCPU, and reported it as an exit
  1840	        #                       status. macOS's bash 3.2 does this.
  2635	    _phase_memory_sample(f"{args.phase_id}-start", root=root, tick_bin=tick_bin, relay_task=relay_task)
  2636	    log(f"phase start: running relay-drive --round-cap {args.round_cap}")
  2637	    # Past this point a phase is really being driven — arm the run log and start the driver
  2638	    # heartbeat. Same placement as MARATHON_DRIVE_STARTED=1 + marathon_driver_heartbeat_start in the
  2639	    # Bash twin, so --help / usage / lock contention / a parked lane / --dry-run never post a run log
  2640	    # or leave a liveness record behind.
  2641	    drive_started[0] = True
  2642	    driver_heartbeat_start()
  2643	    refresh_remote_tracking_ref()
  2644	
  2645	    def _run_relay_drive(review_once=False):
  2646	        reason_file = os.path.join(xyz_harness, ".relay-scratch", "escalation-reason")
  2647	        if os.path.isfile(reason_file):
  2648	            try:
  2649	                os.remove(reason_file)
  2650	            except OSError:
  2651	                pass
  2652	        cmd2 = [relay_drive_bin, "--relay-file", relay_file, "--relay-task", relay_task,
  2653	                "--agent-cmd", agent_cmd]
  2654	        if review_once:
  2655	            cmd2.append("--review-once")   # GH-207: one approval pass, no round-cap
  2656	        else:
  2657	            cmd2.extend(["--round-cap", str(args.round_cap)])
  2658	        if args.target_root:
  2659	            cmd2.extend(["--target-root", args.target_root])
  2660	        env2 = os.environ.copy()
  2661	        env2["RELAY_FILE"] = relay_file
  2662	        env2["LANE_ATTEMPT_COUNTED"] = "1"
  2663	        env2["XYZ_HARNESS_CONTEXT"] = "marathon-phase"
  2664	        env2["RELAY_COST_SUMMARY"] = "0"
  2665	        env2["TICK_REPO_ROOT"] = get_env("TICK_REPO_ROOT", root)
  2666	        # GH-256: under --target-root the turn shim must GUARD the repo the worktree is cut FROM.
  2667	        #
  2668	        # relay-drive exports RELAY_TARGET_ROOT and relay-turn-lib.sh:251 reads
  2669	        # RTL_ROOT="${RELAY_TARGET_ROOT:-$1}", so the WORKTREE is correct. But each shim resolves
  2670	        # its own containment root from <AGENT>_TURN_ROOT (utils/py/agy-turn.py:321,
  2671	        # utils/py/codex-turn.py:26), which nothing set — so the shim guarded the harness while the
  2672	        # worktree was the target, the per-artifact seed check resolved every path against the
  2673	        # wrong root and found nothing, and the agent got a worktree without its own files.
  2674	        # relay-turn-lib.sh:283 already stated the gap: "marathon-drive/relay-drive don't export
  2675	        # CODEX_TURN_ROOT/AGY_TURN_ROOT — they never do".
  2676	        #
  2677	        # Measured: four builder turns wrote nothing, appended no builder block, and the phase
  2678	        # escalated cap-stalled after 29 minutes with zero lines of code. No error anywhere.
  2679	        #
  2680	        # Set on env2 (the relay-drive child) rather than os.environ, so the guard root is scoped
  2681	        # to the drive that actually has a foreign target and cannot leak into anything else in
  2682	        # this process. The name set matches route_agent's accepted prefixes above — claude, codex,
  2683	        # agy, aider, pi, smallcode — plus commandcode, whose shim reads the var. Keeping the two
  2684	        # lists together is deliberate: a new builder route added above without a guard root here
  2685	        # silently reintroduces this bug.
  2686	        if args.target_root:
  2687	            for _shim in ("CLAUDE", "CODEX", "AGY", "AIDER", "PI", "SMALLCODE", "COMMANDCODE"):
  2688	                env2[f"{_shim}_TURN_ROOT"] = args.target_root
  2689	        return subprocess.run(cmd2, env=env2, cwd=root).returncode
  2690	
  2691	    # GH-75: write liveness before the drive; clear it on ANY terminal path via atexit (registered only
  2692	    # here, so early exits before a live phase never register a spurious clear).
  2693	    xyz_marathon_heartbeat_write()
  2694	    import atexit as _atexit
  2695	    _atexit.register(xyz_marathon_heartbeat_clear)
  2696	    relay_exit = _run_relay_drive()
  2697	
  2698	    # escalate/save_transcript/run_pre_advance_gate/file_status/terminal_status/token_state/
  2699	    # requires_test_delta/complete_phase_success are defined earlier (ahead of the render) —
  2700	    # see the GH-274 comment there — but still called from below as before.

2026-08-27T15:19:56.528000Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "rg -n --no-heading 'gh527-destructive-git-guard|sentinel-tier1|gh342-sentinel-debug-log-python|REGISTER|test/' validate.sh utils/ci-route.sh | head -n 180 && nl -ba .gitignore | sed -n '55,68p' && nl -ba utils/py/consult.py | sed -n '724,758p' && nl -ba utils/py/review_xyz.py | sed -n '675,702p' && nl -ba utils/py/workspace_manager.py | sed -n '270,292p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-54680-c807n60b
 succeeded in 0ms:
utils/ci-route.sh:12:# paths, any test/* change, and every kernel/containment/gate surface are tier 3.
utils/ci-route.sh:21:# and list its suites in SUBSYSTEM_TESTS_<name>. Every listed suite must exist in test/ AND
utils/ci-route.sh:22:# be registered in validate.sh's TESTS array — test/gh35-test-tiers.sh enforces both, because
utils/ci-route.sh:58:        [[ -f "$ROOT/test/$t" ]] || { echo "ci-route: subsystem $s registers missing test test/$t" >&2; exit 2; }
utils/ci-route.sh:121:# its own repo as the working directory (test/ci-route.sh's rename fixture depends on this —
utils/ci-route.sh:126:  [[ -f "test/$candidate" ]] || return 0
utils/ci-route.sh:135:  [[ -f "test/$candidate" ]] || return 0
utils/ci-route.sh:164:    .github/workflows/*|validate.sh|utils/ci-route.sh|test/ci-route.sh|test/ci-workflow.sh)
utils/ci-route.sh:178:    test/*worktree*|test/*containment*|test/tick-*|test/relay-*|test/agent-chorus.sh|test/marathon*.sh)
utils/ci-route.sh:181:    test/gh308-*|test/mktemp-trap-guard.sh|test/path-integrity.sh)
utils/ci-route.sh:190:    test/*) test_touched=true ;;
utils/ci-route.sh:219:    test/*.sh)
utils/ci-route.sh:221:        add_changed_test "${path#test/}"
validate.sh:10:# test/gh441-gate-env-contract.sh fails if a new driver export is left unclassified.
validate.sh:114:  "gh342-sentinel-debug-log-python.sh" # GH-342/GH-281 (Sentinel Tier-1 XYZ_DEBUG_LOG capture on the default Python lane)
validate.sh:117:  "gh557-unknown-blocks-manifest.sh" # GH-557 (an `unknown` acceptance verdict blocks on a FROZEN MANIFEST member when the cause is structural — the issue states no criteria — and stays advisory everywhere else) — 16/0; control in test/baselines/GH-557-negative-control.md: 5 pass / 11 fail pre-fix, with the pin observed as `expected exit 5, got 0`. The three assertions that PASS pre-fix are the point: a detector that refused every acceptance-less issue would satisfy the pin and break ordinary lanes, and an outage must never block
validate.sh:137:                                 #   test/marathon.sh's GH-205 cases are the non-regression CONTROL,
validate.sh:154:  "gh218-synthetic-nested-driver-lock.sh" # GH-218 (synthetic suites must not contend for the harness clone's driver lock: static sweep rejects RELAY_DRIVER_LOCKED=0 on/above any relay_drive/marathon_drive invocation in test/synthetic; dynamic repro holds the real lock dir+live pid and runs gh101 green — the live marathon pre-advance incident shape) — 2/0; negative control: detector flags the pre-fix gh101 line 101
validate.sh:155:  "gh217-gate-env-plan-outside.sh"    # GH-217 (MARATHON_ALLOW_PLAN_OUTSIDE_WORKING classified SCRUB in the gate_env registry + mirrored in the driver literal; test/marathon.sh unsets it defensively; the issue's literal repro — full marathon suite under the ambient leak — is green, GH-212 refusal specifically not vacuous) — 4/0
validate.sh:173:  "gh408-tick-failure-visibility.sh" # GH-408 + GH-409 P1 (a failed `tick claim` is detectable by exit status AND readable in the output, at both discard sites) — 22/0; control recorded in test/baselines/GH-408-negative-control.md: 12 red pre-fix. Guards the two directions a naive fix breaks: an idempotent re-claim by the holder must stay exit 0, and a successful tick call must stay silent
validate.sh:183:  "gh402-branch-enforcement.sh"   # GH-402 (a marathon refuses to commit to the RECEIVING repo's shared trunk; --allow-trunk-commit and preflight's risk=1 carve-out are the two documented ways past) — 13/0; control in test/baselines/GH-402-negative-control.md: 8 red pre-fix, with the pre-fix run observed COMMITTING to trunk. Fires only when origin/HEAD resolves — a repo with no remote shares nothing and `git reset` undoes it, asserted as an explicit non-block
validate.sh:184:  "gh386-turn-budget-honesty.sh"  # GH-386 (one wall-clock default across all five builders on both lanes; the packet's budget names turn_timeout_s, the field marathon.sh actually reads) — 10/0; control in test/baselines/GH-386-negative-control.md: 9 red pre-fix. Part C EXERCISES the shipped sizing ladder and requires every suggestion to be >= the default — the assertion a partial fix (raise the cap, forget the ladder) fails
validate.sh:185:  "gh514-write-set-trackable.sh"  # GH-514 (the target is proven able to TRACK the run's write-set before dispatch; a hostile ignore rule gets an actionable refusal naming the rule and the remedy, not an unhandled CalledProcessError traceback) — 12/0; control in test/baselines/GH-514-negative-control.md: 6 red pre-fix. Note the corrected framing recorded there: "no dispatch" does NOT discriminate (the render's own git add already dies first) — the traceback assertion does
validate.sh:188:  "gh426-worktree-leak.sh"       # GH-426 (an isolated turn's creation is absent from BOTH the target and the harness) — 7/0; control in test/baselines/GH-426-negative-control.md: 2 red here + 1 red in gh410's C4c. The reported cause (worktree teardown) is FALSIFIED and the suite pins the real one: the agent binary is invoked twice, and the GH-375 auth probe ran with the caller's CWD, outside containment
validate.sh:189:  "gh384-crash-recovery.sh"      # GH-384 (marathon-recover.sh actually DISTINGUISHES a gated phase from an ungated one, in one repo, one run) — 19/0; control in test/baselines/GH-384-negative-control.md is a MUTATION pair (the tool already shipped, so there is no pre-fix revision): detection removed → 2 red, verdict decoupled from the approval event → 1 red. Also pins read-only (tree byte-identical) and the STALE/LIVE lock distinction
validate.sh:190:  "gh388-run-log-durability.sh"  # GH-388 (the harness owns a durable chain run log; a phase KILLED mid-run leaves a content-bearing record; rtl_default_log refuses rather than silently relocating to volatile storage) — 24/0; control in test/baselines/GH-388-negative-control.md: 9 red pre-fix. Part C/D actually kill a running phase and a running chain — a green success path proves nothing on this issue
validate.sh:191:  "gh409-claim-leak.sh"          # GH-409 P2 (a turn that fails releases its claim, on the three paths that never reach rtl_enforce) — 8/0; control in test/baselines/GH-409-negative-control.md: 4 red pre-fix. Every case fails TWICE before asserting, because the cap is 2 and one leak is invisible
validate.sh:215:  "gh314-transcript-writeset.sh"       # GH-314 (the write set is THREE paths: the transcript's git add was outside GH-514's preflight, so an ignored relay-system/ was discovered only after paid turns) — 5/0; control: dropping the transcript path spends 2 builder turns before the same refusal (test/baselines/GH-314-negative-control.md)
validate.sh:216:  "gh520-default-reviewer-stub.sh"     # GH-520 (test/_setup.sh gives every fixture a default CODEX_BIN, so a suite tests its subject rather than the reviewer probe) — 11/0; control: with gh402's own stub removed AND this default removed, gh402 fails with the probe's message verbatim (test/baselines/GH-520-default-stub-control.md)
validate.sh:217:  "gh527-destructive-git-guard.sh"     # GH-527 (a tree-overwriting git command snapshots the tracked files it destroys into .tick/orphan-backups/ first) — 26/0; controls: a no-op guard drops 9 assertions, and a blanket that fires on a CLEAN tree drops exactly the control assertion. Clean-tree silence is defended by TWO conditions, so it takes a combined mutation to falsify — recorded in test/baselines/GH-527-negative-control.md
validate.sh:222:  "marathon-root-audit.sh"       # GH-209 (static audit: every test/marathon*.sh invocation is MARATHON_ROOT-scoped)
validate.sh:232:  "gh139-pipe-grep-guard.sh"     # #139 (static inventory guard: no NEW `| grep -q` pipes in test/ — the GH-460 SIGPIPE shape; baseline of unconverted stragglers beside it)
validate.sh:233:  # #141 Phase 1: every test/synthetic/ suite is owned by THIS registry (single selector).
validate.sh:234:  # Direct entries — the runner invokes bash test/<entry>, wrappers would only add indirection.
validate.sh:245:  "gh141-synthetic-registry.sh"  # #141 Phase 1 (single selector: every test/synthetic suite is registry-reachable AND fuzz-loop's derived selection matches — no suite selectable by one path but not the other; a dropped-in unregistered suite is CAUGHT)
validate.sh:268:                                 # RE-REGISTERED 2026-08-15 in the same commit that lands the gate file,
validate.sh:292:                                 #   revert-and-replay transcript is test/baselines/GH-32-negative-control.md
validate.sh:302:                                 #   test/baselines/GH-52-negative-control.md
validate.sh:427:  "sentinel-tier1.sh"           # GH-281 (Tier-1 JSONL finding capture)
validate.sh:437:  # 0/1, so it plugs straight in. ponytail: the Gamma canary (test/fixtures/gamma-poison/) is
validate.sh:456:# "--target-root moves the build, not the lock", see test/gh331-cost-summary.sh), so those run
validate.sh:513:  introspection --list                             print the registry this gate runs (test/<entry>
validate.sh:522:      # #141 Phase 1: expose the authoritative registry as a manifest. Prints test/<entry> for
validate.sh:524:      for _t in "${TESTS[@]}"; do printf 'test/%s\n' "$_t"; done
validate.sh:767:  # for a gate run — both for test/gh544-parallel-default.sh (which must never execute the real
validate.sh:821:    [ -f "$HERE/test/$t" ] || { echo "validate.sh: tier-2 suite test/$t is missing — a gate that cannot run has not passed." >&2; exit 1; }
validate.sh:886:bash "$HERE/test/lib/clone-identity.sh" capture "$IDENTITY_SNAPSHOT" "$HERE" || {
validate.sh:932:    if $NICE_CMD bash "$VALIDATE_HERE/test/$t" >"$log" 2>&1 </dev/null; then rc=0; else rc=$?; fi
validate.sh:994:    if bash "$HERE/test/$t" > "$log.serial" 2>&1 </dev/null; then
validate.sh:1043:  if $NICE_CMD bash "$HERE/test/$t"; then
validate.sh:1056:  echo "Running python3 -m pytest test/test_python_layer.py"
validate.sh:1058:  if $NICE_CMD python3 -m pytest "$HERE/test/test_python_layer.py"; then
validate.sh:1072:if bash "$HERE/test/lib/clone-identity.sh" assert "$IDENTITY_SNAPSHOT" "$HERE"; then
validate.sh:1086:  if git apply --check "$HERE/test/fixtures/gamma-poison/poison.patch" 2>/dev/null; then
validate.sh:1098:# fixed probes the tier selected. The pytest/identity/gamma conditions here are the same ones
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
   724	                if consult_tick_bin:
   725	                    tick_env = dict(os.environ)
   726	                    tick_env["TICK_REPO_ROOT"] = consult_tick_root
   727	                    try:
   728	                        subprocess.run(
   729	                            [
   730	                                consult_tick_bin,
   731	                                "cost",
   732	                                f"CONSULT-{label}",
   733	                                "--agent",
   734	                                "gemini",
   735	                                "--from-gemini-json",
   736	                                gj,
   737	                                "--tool",
   738	                                "gemini",
   739	                            ],
   740	                            env=tick_env,
   741	                            stderr=subprocess.DEVNULL,
   742	                            stdout=subprocess.DEVNULL,
   743	                        )
   744	                    except Exception:
   745	                        warn("gemini tokens not captured (no parseable stats)")
   746	                
   747	    finally:
   748	        subprocess.run(["git", "-C", root, "worktree", "remove", "--force", wt], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
   749	        subprocess.run(["git", "-C", root, "worktree", "prune"], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
   750	        if os.path.exists(wt):
   751	            shutil.rmtree(wt, ignore_errors=True)
   752	        
   753	    print(f"consult: {answered} answered, {failed} failed -> {run_dir}{summary}")
   754	    if degraded:
   755	        warn(f"SINGLE-MODEL — NOT RECONCILED (stamped into {survivor_out} and {os.path.join(run_dir, 'DEGRADED-SINGLE-MODEL.txt')})")
   756	    if citeless_models:
   757	        warn(f"NO FIRSTHAND VERIFICATION CITED for: {' '.join(citeless_models)} (stamped into transcript(s) + sidecar(s) in {run_dir})")
   758	    for pw_model, pw_count in provenance_warnings:
   675	                with open(args.mock_response, "r", errors="replace") as f:
   676	                    raw_response = f.read()
   677	            else:
   678	                raw_response = args.mock_response
   679	            duration = 0.05
   680	        else:
   681	            raw_response, duration = execute_model_review(
   682	                engine, model_slug, prompt, wt_dir, args.timeout, env
   683	            )
   684	    finally:
   685	        # 6. Teardown Worktree
   686	        if wt_created:
   687	            try:
   688	                subprocess.run(
   689	                    ["git", "-C", root, "worktree", "remove", "--force", wt_dir],
   690	                    capture_output=True,
   691	                )
   692	            except Exception:
   693	                pass
   694	        if os.path.exists(wt_dir):
   695	            shutil.rmtree(wt_dir, ignore_errors=True)
   696	
   697	    if not raw_response or not raw_response.strip():
   698	        die("model execution failed to return a review transcript", code=2)
   699	
   700	    # 7. Parse Findings & Format Report
   701	    review_data = parse_review_output(raw_response, strict_citations=args.strict_citations)
   702	    report_md = format_final_report(
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

2026-08-27T15:21:22.052712Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "rg -n --no-heading 'delete_rows|delete\\)' relay-automation/xyz-sync.sh | tail -n 30 && nl -ba relay-automation/xyz-sync.sh | sed -n '500,570p' && nl -ba relay-automation/harvest-findings.sh | sed -n '1,70p' && nl -ba relay-automation/marathon-drive.sh | sed -n '455,482p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-54680-c807n60b
 succeeded in 0ms:
331:delete_rows() {
465:  delete|--delete)
493:    delete_rows "$DELETE_TARGET" "$DELETE_YES"
   500	    usage >&2
   501	    exit 2
   502	    ;;
   503	esac
     1	#!/usr/bin/env bash
     2	# harvest-findings.sh — extract `### Side Finding` blocks from a relay file and append them to
     3	# debug.log as PDDA-output-contract JSONL findings. Read-only on the relay; append-only on
     4	# debug.log; NO network. Best-effort — a broken harvest must never fail a phase.
     5	# Usage: harvest-findings.sh --relay FILE [--scope S] [--repo R] [--out debug.log]
     6	set -u
     7	RELAY="" SCOPE="harness" REPO="" OUT=""
     8	while [ $# -gt 0 ]; do
     9	  case "$1" in
    10	    --relay) RELAY="${2:-}"; shift 2 ;;
    11	    --scope) SCOPE="${2:-harness}"; shift 2 ;;
    12	    --repo)  REPO="${2:-}"; shift 2 ;;
    13	    --out)   OUT="${2:-}"; shift 2 ;;
    14	    -h|--help) echo "usage: harvest-findings.sh --relay FILE [--scope S] [--repo R] [--out FILE]"; exit 0 ;;
    15	    *) echo "harvest-findings.sh: unexpected arg: $1" >&2; exit 2 ;;
    16	  esac
    17	done
    18	[ -n "$RELAY" ] && [ -f "$RELAY" ] || exit 0
    19	[ -n "$SCOPE" ] || SCOPE="harness"
    20	OUT="${OUT:-debug.log}"
    21	TS="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
    22	
    23	awk -v ts="$TS" -v scope="$SCOPE" -v repo="$REPO" -v relay="$RELAY" '
    24	  function esc(s){ gsub(/\\/,"\\\\",s); gsub(/"/,"\\\"",s); gsub(/[[:cntrl:]]/," ",s); return s }
    25	  function flush(){
    26	    if (!inblk) return
    27	    printf("{\"timestamp\":\"%s\",\"severity\":\"warn\",\"check\":\"marathon.side-finding\",\"scope\":\"%s\",\"repo\":\"%s\",\"file\":\"%s\",\"line\":\"\",\"message\":\"%s%s\",\"action\":\"triage\",\"probe\":\"%s\"}\n",
    28	      ts, esc(scope), esc(repo), esc(p), esc(sy), (sc!=""?"; suspected: " esc(sc):""), esc(pr))
    29	    inblk=0; p=""; sy=""; sc=""; pr=""
    30	  }
    31	  /^###[ \t]+Side Finding/ { flush(); inblk=1; next }
    32	  inblk && (/^#/ || /^---/) { flush() }
    33	  inblk {
    34	    if (match($0,/^-[ \t]*path:[ \t]*/))                 p =substr($0,RLENGTH+1)
    35	    else if (match($0,/^-[ \t]*symptom:[ \t]*/))         sy=substr($0,RLENGTH+1)
    36	    else if (match($0,/^-[ \t]*suspected_cause:[ \t]*/)) sc=substr($0,RLENGTH+1)
    37	    else if (match($0,/^-[ \t]*probe:[ \t]*/))           pr=substr($0,RLENGTH+1)
    38	  }
    39	  END { flush() }
    40	' "$RELAY" >> "$OUT" 2>/dev/null || true
    41	exit 0
   455	  # sessionId: PHASE_ID defaults to "p1", which is a constant across every swarm/bare run — useless for
   456	  # telling one run from another. Let the invoker override it (swarm-preflight bakes the per-run slug
   457	  # into its generated command via XYZ_SESSION_ID); fall back to PHASE_ID otherwise (GH-75 review).
   458	  sid="${XYZ_SESSION_ID:-$PHASE_ID}"
   459	  "$XYZ_APPEND_BIN" "$harness" "$sid" "$health" "$title" "$desc" >/dev/null 2>&1 || true
   460	}
   461	
   462	# Sentinel Tier 1 (GH-281): append ONE PDDA-output-contract JSONL finding to $DEBUG_LOG_FILE.
   463	# Opt-in (XYZ_DEBUG_LOG=1), default off. Writes only this one local file — no network, no
   464	# PDDA-ACTIVITY.jsonl, no telemetry. NEVER fails the run.
   465	_json_esc() {  # normalize all C0/DEL controls (UTF-8 safe), then escape backslash + quote
   466	  local s="$1"; s="$(printf '%s' "$s" | tr '\000-\037\177' ' ')"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
   467	  printf '%s' "$s"
   468	}
   469	xyz_debug_log_append() {  # <severity> <check> <message> [file] [action] [probe]
   470	  [[ "${XYZ_DEBUG_LOG:-0}" == "1" ]] || return 0
   471	  local sev="$1" chk="$2" msg="$3" file="${4:-}" action="${5:-}" probe="${6:-}" ts scope
   472	  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
   473	  scope="${TARGET_ROOT:+target:$TARGET_ROOT}"; scope="${scope:-harness}"
   474	  printf '{"timestamp":"%s","severity":"%s","check":"%s","scope":"%s","repo":"%s","phase":"%s","task":"%s","file":"%s","line":"","message":"%s","action":"%s","probe":"%s"}\n' \
   475	    "$ts" "$sev" "$chk" "$(_json_esc "$scope")" "$(_json_esc "${TARGET_ROOT:-$ROOT}")" "$(_json_esc "${PHASE_ID:-}")" "$(_json_esc "${RELAY_TASK:-}")" \
   476	    "$(_json_esc "$file")" "$(_json_esc "$msg")" "$(_json_esc "$action")" "$(_json_esc "$probe")" \
   477	    >> "$DEBUG_LOG_FILE" 2>/dev/null || true
   478	}
   479	
   480	file_status() { sed -n 's/^STATUS:[[:space:]]*//p' "$RELAY_FILE" | head -1 | sed 's/[[:space:]]*$//'; }
   481	terminal_status() { case "$1" in Approved|Closed) return 0 ;; *) return 1 ;; esac; }
   482	token_state() {

2026-08-27T15:21:28.709351Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "nl -ba relay-automation/xyz-sync.sh | sed -n '440,500p' && nl -ba validate.sh | sed -n '104,122p;208,222p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-54680-c807n60b
 succeeded in 0ms:
   440	        usage >&2
   441	        exit 2
   442	        ;;
   443	      *)
   444	        [ "$#" -eq 1 ] || { usage >&2; exit 2; }
   445	        update_rows "$1"
   446	        ;;
   447	    esac
   448	    ;;
   449	  check|--check)
   450	    case "${1:-}" in
   451	      --all)
   452	        [ "$#" -eq 1 ] || { usage >&2; exit 2; }
   453	        check_rows --all
   454	        ;;
   455	      "")
   456	        usage >&2
   457	        exit 2
   458	        ;;
   459	      *)
   460	        [ "$#" -eq 1 ] || { usage >&2; exit 2; }
   461	        check_rows "$1"
   462	        ;;
   463	    esac
   464	    ;;
   465	  delete|--delete)
   466	    DELETE_TARGET=""
   467	    DELETE_YES=0
   468	    while [ "$#" -gt 0 ]; do
   469	      case "$1" in
   470	        --yes)
   471	          DELETE_YES=1
   472	          ;;
   473	        --all)
   474	          [ -z "$DELETE_TARGET" ] || { usage >&2; exit 2; }
   475	          DELETE_TARGET="--all"
   476	          ;;
   477	        -h|--help)
   478	          usage
   479	          exit 0
   480	          ;;
   481	        -*)
   482	          usage >&2
   483	          exit 2
   484	          ;;
   485	        *)
   486	          [ -z "$DELETE_TARGET" ] || { usage >&2; exit 2; }
   487	          DELETE_TARGET="$1"
   488	          ;;
   489	      esac
   490	      shift
   491	    done
   492	    [ -n "$DELETE_TARGET" ] || { usage >&2; exit 2; }
   493	    delete_rows "$DELETE_TARGET" "$DELETE_YES"
   494	    ;;
   495	  -h|--help)
   496	    usage
   497	    ;;
   498	  *)
   499	    printf 'xyz-sync.sh: unknown subcommand %q\n\n' "$COMMAND" >&2
   500	    usage >&2
   104	  "gh319-gate-path-with-space.sh" # GH-319 (default gate must not word-split a spaced repo path)
   105	  "gh320-twin-timeout-parity.sh" # GH-320 (Python twin turn-timeout defaults must match Bash + docs)
   106	  "gh322-unknown-arg-rejection.sh" # GH-322 (Python lane must reject unknown flags, not discard them)
   107	  "gh322-runlog-python-lane.sh"  # GH-322 (GH-284 P2 heartbeat + run log on the lane that actually runs)
   108	  "gh331-cost-summary.sh"        # GH-331/GH-308 (end-of-run tick-analyze cost summary on the default Python lane)
   109	  "gh308-poll-guards.sh"         # GH-308 (poll.py: --help/--mode/--turn-source/positional guards, GH-92 warning, watchdog default)
   110	  "gh308-swarm-gate-path.sh"     # GH-308 (swarm_preflight.py: uninstalled node/npm/python3 gate program → NOT-READY)
   111	  "gh343-gate-program-target-root.sh" # GH-343 (target-relative direct gate programs resolve from target_root)
   112	  "gh308-consult-guards.sh"      # GH-308 (consult.py: agy isolation-breach detector + codex ATTESTATION header)
   113	  "gh308-turn-shim-parity.sh"    # GH-308 (claude drift brief + turn-shim ROOT resolution + agy TICK_REPO_ROOT propagation)
   114	  "gh342-sentinel-debug-log-python.sh" # GH-342/GH-281 (Sentinel Tier-1 XYZ_DEBUG_LOG capture on the default Python lane)
   115	  "gh369-find-doc-root-resolution.sh"  # GH-369/GH-344 (find-doc.sh resolves PROJECT/** from the SWEPT repo; --root arg-parse guards)
   116	  "gh400-acceptance-fidelity.sh" # GH-400 (a capture doc's acceptance block must be the issue's, or declare each deviation)
   117	  "gh557-unknown-blocks-manifest.sh" # GH-557 (an `unknown` acceptance verdict blocks on a FROZEN MANIFEST member when the cause is structural — the issue states no criteria — and stays advisory everywhere else) — 16/0; control in test/baselines/GH-557-negative-control.md: 5 pass / 11 fail pre-fix, with the pin observed as `expected exit 5, got 0`. The three assertions that PASS pre-fix are the point: a detector that refused every acceptance-less issue would satisfy the pin and break ordinary lanes, and an outage must never block
   118	  "gh400-source-url.sh"          # GH-400 criterion 2 (a capture doc must cite its issue's URL) — 13/0 post-fix, observed 2/11 pre-fix
   119	  "gh419-gate-inventory.sh"      # GH-419 (generated decision-gate inventory; declared negative-control evidence)
   120	  "litmus-release.sh"            # Litmus 0.2.0 frozen-manifest audit. Suite mode fails ONLY on a false completion claim (a CLOSED manifest issue whose gate is missing/unregistered/undeclared); remaining work is INFO. The goalpost itself is `--release-gate` (red until done). Control: `--mutate-evidence` 9/0 — NOT run by this suite; run it by hand when touching audit_entry
   121	  "gh418-issue-state-frozen.sh"  # GH-418 (issue state is advisory; on-disk GH-308 FROZEN banner blocks writes)
   122	  "gh422-backfill-source-url.sh" # GH-422 (self-remediating message + bulk backfill) — 18/0; controls: pre-fix replay 15/3, conflict-guard mutation 16/2
   208	  "gh430-state-dir-tracked-default.sh" # GH-430 (STATE_DIR default is a tracked in-repo path, not ${TMPDIR:-/tmp})
   209	  "gh536-evidence-detail.sh"           # GH-536 (the gate-evidence record carries an output hash + per-suite verdicts, so a reader can tell a real run from a stamped one) — 19/0; pins that the NOT-promotion-evidence disclaimer STAYS: a self-computed hash is tamper-evident, not attested
   210	  "gh544-parallel-default.sh"          # GH-544 (parallel is the default; every decline to it is ANNOUNCED with a reason) — 29/0; uses --print-mode so it cannot recurse into the gate it belongs to, and pins the two invariants nothing else pins: ci-local.sh never inherits the default, and ci.yml's macOS boundary passes --sequential explicitly
   211	  "gh544-pre-push-gate.sh"             # GH-544 (the gate moved to the push boundary; hosted CI fires on nothing) — 78/0; drives githooks/pre-push against a STUB validate.sh so it cannot recurse, and stubs `gh` to pin the one state nothing else can produce: a PR with ZERO configured checks must not read as "checks failed"
   212	  "gh35-test-tiers.sh"                 # GH-35 (tiered test selection + CPU governance) — 56/0; pins the registry contract (every registered suite exists AND is in TESTS), the fail-closed tier boundaries, the balanced cores/2 default + --throttle/--burst/env levers, nice -n 10 on the workers, and the tier-1/tier-2 execution paths against fixture clones whose suites are stubs (real runner, real pool, real summary math)
   213	  "gh1-fixture-guard.sh"               # GH-1 (shared require_fixture resolved-containment + clone-identity invariant gate; covers the GH-567 lexical-check residual)
   214	  "gh1-adoption-guard.sh"             # GH-10 (every fixture-creating suite carries require_fixture adoption — derivation computed from source, exemptions declared in-file; controls prove the guard fires on an unguarded new suite, a stripped adoption, and a removed exemption marker)
   215	  "gh314-transcript-writeset.sh"       # GH-314 (the write set is THREE paths: the transcript's git add was outside GH-514's preflight, so an ignored relay-system/ was discovered only after paid turns) — 5/0; control: dropping the transcript path spends 2 builder turns before the same refusal (test/baselines/GH-314-negative-control.md)
   216	  "gh520-default-reviewer-stub.sh"     # GH-520 (test/_setup.sh gives every fixture a default CODEX_BIN, so a suite tests its subject rather than the reviewer probe) — 11/0; control: with gh402's own stub removed AND this default removed, gh402 fails with the probe's message verbatim (test/baselines/GH-520-default-stub-control.md)
   217	  "gh527-destructive-git-guard.sh"     # GH-527 (a tree-overwriting git command snapshots the tracked files it destroys into .tick/orphan-backups/ first) — 26/0; controls: a no-op guard drops 9 assertions, and a blanket that fires on a CLEAN tree drops exactly the control assertion. Clean-tree silence is defended by TWO conditions, so it takes a combined mutation to falsify — recorded in test/baselines/GH-527-negative-control.md
   218	  "gh50-sandboxed-git-guard.sh"        # GH-50 (config writability is proven before a tracking switch can rewrite the tree; writable-config control proves the wrapper is not a blanket ban)
   219	  "marathon.sh"
   220	  "marathon-closeout.sh"
   221	  "gh484-phase-dir-default.sh"   # GH-484 (phase-output default is marathon-system/; --phases-dir still overrides; the dirty-tree exclusion tracks the CONFIGURED dir) — 10/0; controls: pre-fix red on both defaults and both containment cases, plus a stray-file control proving the clean check actually ran. Forces XYZ_PYTHON=0 so the Bash twin is really exercised
   222	  "marathon-root-audit.sh"       # GH-209 (static audit: every test/marathon*.sh invocation is MARATHON_ROOT-scoped)

2026-08-27T15:21:32.974836Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
codex
ANSWER

The three-layer shape is sensible, but the plan is under-built at the harness seam and overstates its environment coverage. Keep a separate user-level hook, but instrument the actual shared teardown function and write all receipts to a central home-directory log without relying on `~/.zshenv`.

FINDINGS

[Blocker] The plan identifies the wrong worktree teardown sites. Neither Python driver removes turn worktrees directly: `relay_drive.py` launches the agent shim at `utils/py/relay_drive.py:575-580`, while `marathon_drive.py` delegates to relay-drive at `utils/py/marathon_drive.py:2645-2689`. The shared teardown is `rtl_worktree_end()` at `relay-automation/relay-turn-lib.sh:756-762`, with removal/fallback/prune at `:873-875`. Logging only the Python drivers would miss the actual operation and fallback `rm -rf`. If consult/review worktrees are in scope, the authoritative Python paths also remove independently at `utils/py/consult.py:747-751` and `utils/py/review_xyz.py:684-695`.

[Should] A separate user-level hook is the right ownership seam. GH-527 is a recovery guard with repo-specific behavior: it detects Git operations, finds the repository, classifies dirty paths, and may copy files (`relay-automation/hooks/gh527-destructive-git-guard.sh:61-81`, `:108-148`, `:165-186`). A global best-effort receipt logger has different scope, failure semantics, and storage. Extending GH-527 would also remain project-local because it is registered through this repo’s `.claude/settings.json:22-50`. Avoid matcher drift by making the logger’s Git family a tested superset of GH-527’s shapes, rather than coupling the implementations.

[Blocker] `~/.zshenv` does not mean “inherits into every non-interactive shell.” It is read by zsh startup; Bash, Python, GUI-launched processes, launchd jobs, and already-running Claude/Codex processes only inherit the variable if some ancestor already had it. Moreover, the actual teardown is in a Bash library. Use a dedicated logger that defaults to a known home-state path, or set the environment in the harness entry-point configuration itself.

[Should] Exporting only `XYZ_DEBUG_LOG=1` scatters `debug.log` files into repository roots. The existing contract explicitly defaults to `$ROOT/debug.log` (`utils/py/marathon_drive.py:99-101`, `:124-126`). This repo ignores that file at `.gitignore:62-63`, but target repositories need not. It also enables unrelated Sentinel findings, not just write receipts. Prefer a dedicated `XYZ_WRITE_OPS_LOG`, or at minimum also set `DEBUG_LOG_FILE` to a central local path such as `~/.local/state/xyz/write-ops.jsonl`.

[Should] PreToolUse records intent, not success. A matched `xyz-sync.sh delete` may only preview because deletion requires `--yes` (`relay-automation/xyz-sync.sh:465-493`). Direct-site logging belongs immediately before the confirmed `rm -rf` at `:356-360`; records should say `stage:"pre"` or `outcome:"attempted"`. Ideally add a post-call result for operations whose return code is available.

[Should] The hook must parse and emit JSON through a real JSON encoder. Validate that the payload and `tool_input` are dictionaries and `command` is a string; malformed input must be swallowed. Commands can contain quotes, newlines, controls, heredocs, or megabytes of content. Use one `O_APPEND` write, restrictive permissions, and a command-size cap plus hash/truncation marker. Shell interpolation or hand-built JSON will eventually corrupt the JSONL or leak excessively large/sensitive commands.

[Should] The proposed pattern family has material gaps:

- Include the existing destructive Git family: checkout, restore, forced switch, stash, and clean (`gh527-destructive-git-guard.sh:74-81`).
- Match `rm -rf`, `rm -fr`, `rm -r -f`, and `rm --recursive --force`, including absolute `/bin/rm`.
- Match `git branch -D`, `-d`, `-df`, and `--delete --force`.
- Match `git worktree remove` and `prune` with intervening flags and `git -C`.
- Treat `xyz-sync delete` as launch intent only; confirmed execution is best recorded inside `delete_rows`.
- Consider `git stash clear/drop` and `git update-ref -d` if “destructive Git” includes deletion of recovery refs, not only working-tree destruction.

[Nit] Regex over raw shell text will match comments, quoted examples, heredocs, and commands that never execute after a failing `&&`; the existing guard acknowledges equivalent nested-command limitations at `gh527-destructive-git-guard.sh:37-39`. That is acceptable for medium-level best-effort logging if records are explicitly labeled as pre-execution intent.

[Pass] Concurrent local appends are adequate if each record is encoded first and issued as one append write. The existing Python helper already performs one append write and swallows errors (`utils/py/marathon_drive.py:129-135`). Do not place the live file on a network/cloud-synced filesystem and assume the same guarantees.

[Should] Keep logs local per machine, add `host` and preferably session/process identifiers, and document that forensic lookup queries both machines. Automatic sync is unnecessary at this level and creates a security problem because full commands may contain tokens or secrets. Use mode `0600`.

[Pass] Skipping Endpoint Security and codex/agy internal-exec capture is proportionate for “medium level,” provided the absolute-path-outside-containment blind spot remains explicit.

[Should] Deferring rotation is fine only with bounded command records. Without a size cap, one heredoc or generated shell payload can cross 10 MB immediately, so “a handful of ~200-byte lines” is not a reliable assumption.

[Should] One registered test file is enough, but the stated three assertions are not. It should cover malformed/non-dict JSON, escaping/newlines, every pattern family, `xyz-sync` preview versus confirmed deletion, the `git worktree remove` fallback, centralized destination, file permissions, and a small concurrent-append integrity check. Existing registration precedent is `validate.sh:217`.

RECOMMENDATION

Keep the three checkboxes, but replace checkbox 2 with a dedicated central write-ops logger called from `rtl_worktree_end()` and confirmed `xyz-sync` deletion, avoiding global `XYZ_DEBUG_LOG` activation and `~/.zshenv` dependence.
tokens used
112,528
ANSWER

The three-layer shape is sensible, but the plan is under-built at the harness seam and overstates its environment coverage. Keep a separate user-level hook, but instrument the actual shared teardown function and write all receipts to a central home-directory log without relying on `~/.zshenv`.

FINDINGS

[Blocker] The plan identifies the wrong worktree teardown sites. Neither Python driver removes turn worktrees directly: `relay_drive.py` launches the agent shim at `utils/py/relay_drive.py:575-580`, while `marathon_drive.py` delegates to relay-drive at `utils/py/marathon_drive.py:2645-2689`. The shared teardown is `rtl_worktree_end()` at `relay-automation/relay-turn-lib.sh:756-762`, with removal/fallback/prune at `:873-875`. Logging only the Python drivers would miss the actual operation and fallback `rm -rf`. If consult/review worktrees are in scope, the authoritative Python paths also remove independently at `utils/py/consult.py:747-751` and `utils/py/review_xyz.py:684-695`.

[Should] A separate user-level hook is the right ownership seam. GH-527 is a recovery guard with repo-specific behavior: it detects Git operations, finds the repository, classifies dirty paths, and may copy files (`relay-automation/hooks/gh527-destructive-git-guard.sh:61-81`, `:108-148`, `:165-186`). A global best-effort receipt logger has different scope, failure semantics, and storage. Extending GH-527 would also remain project-local because it is registered through this repo’s `.claude/settings.json:22-50`. Avoid matcher drift by making the logger’s Git family a tested superset of GH-527’s shapes, rather than coupling the implementations.

[Blocker] `~/.zshenv` does not mean “inherits into every non-interactive shell.” It is read by zsh startup; Bash, Python, GUI-launched processes, launchd jobs, and already-running Claude/Codex processes only inherit the variable if some ancestor already had it. Moreover, the actual teardown is in a Bash library. Use a dedicated logger that defaults to a known home-state path, or set the environment in the harness entry-point configuration itself.

[Should] Exporting only `XYZ_DEBUG_LOG=1` scatters `debug.log` files into repository roots. The existing contract explicitly defaults to `$ROOT/debug.log` (`utils/py/marathon_drive.py:99-101`, `:124-126`). This repo ignores that file at `.gitignore:62-63`, but target repositories need not. It also enables unrelated Sentinel findings, not just write receipts. Prefer a dedicated `XYZ_WRITE_OPS_LOG`, or at minimum also set `DEBUG_LOG_FILE` to a central local path such as `~/.local/state/xyz/write-ops.jsonl`.

[Should] PreToolUse records intent, not success. A matched `xyz-sync.sh delete` may only preview because deletion requires `--yes` (`relay-automation/xyz-sync.sh:465-493`). Direct-site logging belongs immediately before the confirmed `rm -rf` at `:356-360`; records should say `stage:"pre"` or `outcome:"attempted"`. Ideally add a post-call result for operations whose return code is available.

[Should] The hook must parse and emit JSON through a real JSON encoder. Validate that the payload and `tool_input` are dictionaries and `command` is a string; malformed input must be swallowed. Commands can contain quotes, newlines, controls, heredocs, or megabytes of content. Use one `O_APPEND` write, restrictive permissions, and a command-size cap plus hash/truncation marker. Shell interpolation or hand-built JSON will eventually corrupt the JSONL or leak excessively large/sensitive commands.

[Should] The proposed pattern family has material gaps:

- Include the existing destructive Git family: checkout, restore, forced switch, stash, and clean (`gh527-destructive-git-guard.sh:74-81`).
- Match `rm -rf`, `rm -fr`, `rm -r -f`, and `rm --recursive --force`, including absolute `/bin/rm`.
- Match `git branch -D`, `-d`, `-df`, and `--delete --force`.
- Match `git worktree remove` and `prune` with intervening flags and `git -C`.
- Treat `xyz-sync delete` as launch intent only; confirmed execution is best recorded inside `delete_rows`.
- Consider `git stash clear/drop` and `git update-ref -d` if “destructive Git” includes deletion of recovery refs, not only working-tree destruction.

[Nit] Regex over raw shell text will match comments, quoted examples, heredocs, and commands that never execute after a failing `&&`; the existing guard acknowledges equivalent nested-command limitations at `gh527-destructive-git-guard.sh:37-39`. That is acceptable for medium-level best-effort logging if records are explicitly labeled as pre-execution intent.

[Pass] Concurrent local appends are adequate if each record is encoded first and issued as one append write. The existing Python helper already performs one append write and swallows errors (`utils/py/marathon_drive.py:129-135`). Do not place the live file on a network/cloud-synced filesystem and assume the same guarantees.

[Should] Keep logs local per machine, add `host` and preferably session/process identifiers, and document that forensic lookup queries both machines. Automatic sync is unnecessary at this level and creates a security problem because full commands may contain tokens or secrets. Use mode `0600`.

[Pass] Skipping Endpoint Security and codex/agy internal-exec capture is proportionate for “medium level,” provided the absolute-path-outside-containment blind spot remains explicit.

[Should] Deferring rotation is fine only with bounded command records. Without a size cap, one heredoc or generated shell payload can cross 10 MB immediately, so “a handful of ~200-byte lines” is not a reliable assumption.

[Should] One registered test file is enough, but the stated three assertions are not. It should cover malformed/non-dict JSON, escaping/newlines, every pattern family, `xyz-sync` preview versus confirmed deletion, the `git worktree remove` fallback, centralized destination, file permissions, and a small concurrent-append integrity check. Existing registration precedent is `validate.sh:217`.

RECOMMENDATION

Keep the three checkboxes, but replace checkbox 2 with a dedicated central write-ops logger called from `rtl_worktree_end()` and confirmed `xyz-sync` deletion, avoiding global `XYZ_DEBUG_LOG` activation and `~/.zshenv` dependence.
