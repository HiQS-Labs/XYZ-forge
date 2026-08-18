**SINGLE-MODEL — NOT RECONCILED** (only codex answered; 1 of 2 requested advisor(s) failed — this is one model's read, not a cross-model consult. Do not treat any claim below as cross-verified.)

**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.6-terra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
2026-08-18T16:08:00.205433Z ERROR codex_models_manager::cache: failed to load models cache: missing field `base_instructions` at line 98 column 5
OpenAI Codex v0.144.6
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4
model: gpt-5.6-terra
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 01a015a1-3115-7a10-81fc-ae72718d9d56
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# GH-28 — validate and sharpen before promotion to 2-WORKING

Read `PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md` (the capture doc) and GitHub issue #28
(https://github.com/HiQS-Suite/XYZ-forge/issues/28) in this repo. Also read `check_releases()` in
`utils/pdda/pdda.sh` and the "RELEASES.md — release ledger" contract section in `PROJECT/PDDA.md`.

Not yet implemented — still in `1-INBOX`, not promoted to `2-WORKING`. Low urgency, low risk
(doc-governance tooling only; `check_releases()` is confirmed NOT wired into `validate.sh`'s `TESTS[]`,
so nothing here touches the push gate). This is a post-Ballast 0.7.0 follow-up.

## Question

What are the concrete next steps to validate and sharpen this plan before promotion? Specifically:

1. **The revised bloat-check design** — `Description:` >4 sentences, `Exit criterion:` >4 sentences,
   `Manifest-Members:` >7 tokens. These were validated by an ad-hoc scan against the live
   `RELEASES.md` (results in the doc's "Validation scan" section — clean blocks sit at 0-592 chars /
   0-6 sentences on Exit criterion, bloated ones start at 1544+ chars / 6+ sentences; only 2 of 8
   blocks even use `Manifest-Members:`, both clean). Is the threshold choice (4 sentences) sound, or
   is there a better signal? Sentence-counting is a crude heuristic (splits on `.!?`) — will it false-
   positive on legitimate technical prose (e.g. version numbers, decimal points, abbreviations)?
2. **The warn-only-first rollout sequencing** — ship the new checks warn-only, clean up the 6 of 8
   existing bloated blocks (or explicitly grandfather them), THEN flip to blocking in a follow-up
   commit. Is this the right sequencing, or is there a risk in a two-commit rollout (e.g. the
   blocking flip never happens, warn-only becomes the permanent state by inertia)?
3. **The new `Tracking Issue:` field** on the RELEASES.md block spec — a per-release GH issue meant
   to hold release-level status/run-log notes that currently get stuffed inline. Does this field
   design hold up, or is there a simpler/existing mechanism already in the repo that should be reused
   instead (e.g. the `Milestone:` field, or `GH_URL:` once a GitHub Release object exists)?
4. **Anything missing or wrong that would only surface during implementation** — e.g. parser changes
   needed in `pdda-lib.sh` to actually extract the new field, backward-compat for blocks that predate
   the field, interaction with `check_releases()`'s existing warn-only-by-design invariant
   (`PROJECT/PDDA.md` section J), or test coverage gaps.

Give a direct recommendation for what to change before promoting this to `2-WORKING`, not just a list
of considerations.

hook: SessionStart
hook: SessionStart Completed
2026-08-18T16:08:03.642883Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
codex
I’ll validate the capture against the live contract, checker implementation, and issue history, then give a promotion-ready recommendation. This is advisory only; I’ll make the rollout and compatibility assumptions explicit.
exec
/bin/zsh -lc "pwd && rg --files -g 'WORKTREE-SAFETY.md' -g 'ROUTER.md' -g 'GUIDING-PRINCIPLES.md' -g 'PROJECT/PDDA.md' -g 'PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md' -g 'utils/pdda/pdda.sh' -g 'utils/pdda/pdda-lib.sh' -g 'RELEASES.md'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4
 succeeded in 0ms:
/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4
ROUTER.md
GUIDING-PRINCIPLES.md
WORKTREE-SAFETY.md
PROJECT/PDDA.md
RELEASES.md
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md
utils/pdda/pdda.sh
utils/pdda/pdda-lib.sh

2026-08-18T16:08:11.290087Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "sed -n '1,240p' WORKTREE-SAFETY.md && sed -n '1,260p' ROUTER.md && sed -n '1,240p' GUIDING-PRINCIPLES.md && sed -n '1,360p' PROJECT/PDDA.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4
 succeeded in 0ms:
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
    # --force here is NOT the §12 anti-pattern: this worktree was just created by THIS script for a
    # throwaway purpose and is being torn down in its own exit trap, not force-removed out from under
    # someone else's uncommitted work. §12's warning is about scripts reaching for --force to silence
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
./validate.sh              # the gate — PARALLEL by default (GH-544), ~4 min, auto-sized to the host
./validate.sh --print-mode # which mode would this host pick, and why — runs nothing
./validate.sh --sequential # force the sequential run (~16 min)
bash ci-local.sh           # the QUALIFYING run — sequential + writes the gate record (GH-509/GH-536)
```

**Hosted CI fires on nothing while this repo is private (GH-544).** The gate runs locally at the push
boundary instead, so `githooks/install.sh` is part of setting up a clone — the hook lives in
`.git/hooks/`, which does not travel with a clone, and an uninstalled one pushes unverified. One
install covers every branch and every linked worktree of that clone (GH-549). Bypass with
`git push --no-verify` or `XYZ_SKIP_PREPUSH=1`; both announce themselves. Re-arm CI when the repo
goes public (free there).

**Parallel became the default on 2026-08-14 (GH-544)** because the local gate is the only gate during
the private phase, and a 16-minute gate does not get run — it gets skipped, which is worse than a
3-minute one. Width is detected from the host (cores − 2, capped at 8); below 4 cores, or where
`xargs -P` is unsupported, it **falls back to sequential and says so**. Every run prints the mode it
chose and the reason, so a fallback is never silent. Override with `--parallel N`, `--sequential`, or
`XYZ_VALIDATE_PARALLEL` (a flag always beats the env var).

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

## Routing hints

- If the task is about current priorities or active work, start in `ROADMAP.md`, then follow the linked `PROJECT/**` doc.
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
# Project-Driven Doc Automation (PDDA)

PDDA is the document operating layer for this repo. Its job is to keep project plans, bug-fix docs,
research notes, and roadmap pointers clean enough that an agent can pick up work with minimal drift
and enough structure that routine hygiene can be automated instead of re-decided every session.

The core idea is simple:

- deterministic scripts enforce the parts that should never require judgment
- an LLM reviewer flags structural or planning-quality gaps that are hard to express as regex alone
- `ROADMAP.md` stays a pointer/index, while project detail lives in the individual project docs

## Goals

- Keep `PROJECT/2-WORKING` limited to docs that are truly active.
- Ensure every active doc answers two questions at a glance: what was just completed, and what is next.
- Make phased plans automation-ready by requiring explicit QA gates.
- Prevent plan rot: stale files, missing next steps, hardcoded paths, and hidden scope drift.
- Give agents one repeatable contract for project docs, bug-fix docs, and experimental plans.

## Non-goals

- PDDA does not replace the project docs themselves.
- PDDA does not decide product strategy.
- PDDA does not auto-rewrite nuanced plan content without review.
- PDDA does not turn `ROADMAP.md` into a second execution plan.

## Canonical document model

PDDA assumes four lifecycle buckets:

- `PROJECT/1-INBOX`: new ideas, rough proposals, untriaged notes
- `PROJECT/2-WORKING`: active docs that should be updated as work progresses
- `PROJECT/3-COMPLETED`: completed docs with an outcome
- `PROJECT/4-MISC`: reference, stale, superseded, or abandoned docs

Within that model:

- `ROADMAP.md` is the index of current, completed, attempted, and deferred work
- project detail lives in the individual `PROJECT/**` documents
- a working doc is the canonical source of truth for that effort until it is completed, deferred, or superseded
- `blank.md` placeholders are scaffolding and should be ignored by PDDA checks

## Required contract for active docs

Every doc in `PROJECT/2-WORKING` should have:

1. YAML frontmatter with at least `title`, `status`, `created`, `updated`, `owner`, and `goal`
2. a near-top status table with the exact columns:

```md
## Status

| What was just completed | What's next |
|---|---|
| ... | ... |
```

3. clear phase or work sections if the doc is a plan
4. a table of contents (`## Table of contents`) listing each phase, if the plan is multi-phase — so a
   cold agent can see the full phase span and jump to the live one without scrolling the whole body
5. QA gates or acceptance criteria after each phase if the plan is multi-phase
6. for any discovery or spike phase, its findings written **back into this doc** before its QA gate can
   pass (see [Discovery & spike phases (Memory Injection)](#discovery--spike-phases-memory-injection))
7. repo-relative paths only; no hardcoded absolute local paths
8. before moving to `PROJECT/3-COMPLETED`, a `## Lessons Learned (For Future Agents)` section appended to capture quirks and gotchas

Recommended fields when relevant:

- `related`
- `context_tags` (e.g. `[auth, flaky-tests, build]`)
- `reviewed`
- `branch`
- `non_goals`
- `gh_issue`
- `effort`, `complexity`, `risk`, `phases` — triage ratings; **required for medium-large work** (see
  [Triage ratings for medium-large work](#triage-ratings-for-medium-large-work))

## Quad Concepts (opt-in)

An **opt-in** glance layer, **off by default**. The `## Status` table says *where* the work is; Quad
Concepts says *what* it is — a 5-second read of the core problems a plan tackles and how, so an operator
can see whether the real pain points are covered. (Distinct from `context_tags`: those are for search;
this is for glance.)

When enabled system-wide via the `.pdda-quad` lever (or the `PDDA_QUAD` env var — **orthogonal** to the
enforcement mode), tracked plan docs must carry a `## Quad Concepts` section of **1–4 bullets**,
conventionally right after `## Status`:

```md
## Quad Concepts
- <pain the doc addresses> → <how it addresses it>
```

- **Shape (deterministic):** 1–4 **top-level, non-empty** `-`/`*` bullets in the first `## Quad Concepts`
  section. `pain → fix` phrasing is the convention (nudged by the LLM readiness rubric), not a hard regex.
- **Scope:** `PROJECT/2-WORKING`, `PROJECT/1-INBOX/GH-*.md`, and `PROJECT/3-COMPLETED` (the last keeps a
  glanceable summary for cold-start recall). `PROJECT/4-MISC` is out.
- **Enable:** set `.pdda-quad` to `on` (or `PDDA_QUAD=1`). The enforcement mode still governs whether a
  missing/malformed section merely reports or blocks. **Opt a doc out** with `quad_exempt: true`.
- Enforced by `pdda.sh quad-concepts` (deterministic, structure-only) plus a warn-only readiness rubric.
- `pdda.sh glance` (read-only, always available) rolls up `title + Quad Concepts` across `2-WORKING` for
  a one-screen view of what the active portfolio is addressing.

## Triage ratings for medium-large work

So automation can pick *which* task to pursue without re-reading every plan, every newly recorded
**medium-large** task or project carries four triage fields in its frontmatter:

| Field | Range | Meaning |
|---|---|---|
| `effort` | integer `1`–`5` | how much work — `1` low, `5` highest |
| `complexity` | integer `1`–`5` | how intricate / how many moving parts — `1` low, `5` highest |
| `risk` | integer `1`–`5` | blast radius + uncertainty — `1` safe/contained, `5` one-way-door or unknown |
| `phases` | positive integer | total number of phases in the plan |

```yaml
effort: 2
complexity: 3
risk: 1
phases: 4
```

`risk` should track the repo's existing reversibility scale (`Easy / Costly / One-way door`,
`AGENTS.md` #3): `1`–`2` ≈ Easy, `3` ≈ Costly, `4`–`5` ≈ one-way door / high uncertainty. It is not a
parallel notion of danger — it is that scale expressed as a number.

**Scope.** Required for medium-large work (project plans, experiments, features, multi-phase efforts).
Genuinely small/trivial docs (a typo, a path repoint, a ≤2–3 line bug-fix — the same floor as the
issue-first SOP) do not need them. "Medium-large" is a judgment, so *presence* is enforced by the LLM
layer, not a regex (below).

### How to combine them — derive, don't store

There is deliberately **no stored composite "score" field.** A frozen aggregate would (a) drift from
the three numbers it came from, violating Principle #4 (*one canonical place per fact*), and (b) bake a
weighting choice into every doc that you then cannot re-tune without rewriting them. Compute the
selection signal **live, at selection time**, from the raw fields:

- **`risk` is a gate, not an addend.** A trivial-but-risky task (`effort 1`, `complexity 1`, `risk 5`)
  is easy to *do* but exactly what automation should not auto-pick — folding risk into a linear sum
  lets it slip through mid-ranked. Gate on it instead.
- **`effort` and `complexity` are correlated** (complex work is usually effortful), so summing them is
  a rough "size" proxy, not two independent signals — treat the sum as one ease axis, not two.

Reference selection rule (tune the thresholds per repo):

```text
eligible      = risk <= 2 AND not ratings_provisional   # safety gate; risk >= 4 => route to a human
ease          = effort + complexity       # 2..10, lower = easier
pick          = among eligible, lowest ease, then fewest phases as the tiebreak
```

`ratings_provisional: true` is an **eligibility gate, not just metadata.** Auto-drafted intake (e.g.
the `/idea` skill) ships best-guess ratings marked provisional; a rough `risk: 2` guess on a large
effort must **not** become auto-selectable on the strength of that guess. So a provisional doc is held
out of auto-selection until a human confirms the ratings and clears the flag — the same "route to a
human" posture as `risk >= 4`.

This keeps the raw ratings canonical and queryable while letting the "what's the easiest *safe* thing
to grab" logic live in one place that can evolve. (See the resolved `priority` note under
[Proposed extensions](#proposed-extensions-not-yet-locked).)

### How this is enforced

- **deterministic (values)** — `pdda.sh frontmatter` validates the fields **only when present**:
  `effort`/`complexity`/`risk` must be integers `1`–`5`, `phases` a positive integer. A present-but-bad
  value is unambiguous, so it `error`s. The script does **not** force presence — it cannot know whether
  a doc is "medium-large."
- **LLM (presence)** — `pdda-doc-ready.sh` flags a medium-large plan that is *missing* the triage
  ratings. Whether a doc is medium-large is a judgment, so it stays advisory/warn-capped like every
  other readiness finding.

## Why the two-column status header matters

The status table is the front door for both humans and automation.

- The left column is the last verified state change.
- The right column is the next action.
- If either is missing, an agent has to reconstruct state from the body, which is slow and error-prone.

PDDA therefore treats the exact header names as a contract, not a style preference. The header must be
exactly `What was just completed | What's next` — there is no alias/compatibility window. (One was
specced with a `2026-07-31` cutover, but a single-repo system controls its own docs: no doc here used
an old alias, so a dated, silently-changing branch guarded nothing and was removed 2026-06-22.)

## Discovery & spike phases (Memory Injection)

Discovery and spike phases exist to *learn* — reverse-engineer an existing system, probe an unknown,
prove or kill a risky approach before committing the plan to it. Their output is durable **memory**, and under
Principle #1 (*docs are the runtime state, not a record of it*) that knowledge is project state. If it
lives only in an agent's context or a throwaway scratch note, a cold agent resuming the plan cannot see
what was learned, why a path was chosen or abandoned, or what the spike actually proved — and the work
gets re-done.

Contract: **a phase tagged as discovery or spike must write its findings back into the originating plan
doc before its QA gate can pass.** This is active memory injection. Concretely, that phase's section (or a clearly linked sibling
section in the same doc) must capture:

- **what was investigated** — the system/area reverse-engineered or the question the spike asked
- **what was found (quirks, gotchas, mechanics)** — the concrete mechanics learned, with repo-relative pointers (`file:line`) where
  the finding lives in code, not a vague summary
- **what it changes** — how the finding confirms, redirects, or kills the plan's later phases; an
  unfinished "we'll know after the spike" left dangling is itself the gap

This satisfies Principle #4 (*one canonical place per fact*): the originating plan is that place. A
spike whose findings sit in chat is the exact drift PDDA exists to prevent. The QA gate for a
discovery/spike phase therefore includes "findings are written back to this doc" as an acceptance
criterion alongside the phase's normal checks.

Enforcement is **advisory (LLM layer, warn-capped)** — `pdda-doc-ready.sh` flags a discovery/spike
phase whose findings were not written back. "Did the agent actually capture what it learned" is a
judgment a regex cannot make honestly, so it stays with the LLM reviewer and, like every finding from
that layer, never blocks a build (see [LLM-assisted doc readiness review](#2-llm-assisted-doc-readiness-review)).
To tag a phase, name it plainly (e.g. `## Phase 2 — Discovery: …` / `## Phase 3 — Spike: …`) or set
`doc_type: research` / a phase-level marker the reviewer can see.

## Bug-fix doc stance

Bug-fix docs may use a lighter template than multi-phase project plans, but they still need:

- the minimum frontmatter
- the same `## Status` table while active
- a short bug description
- source of truth for intake, including a GitHub issue when relevant
- verification steps

GitHub issues are the default intake for substantive bug reports (issue-first SOP — see below). They are not a
substitute for the local active-work doc once execution starts in this repo.

## GitHub issue intake

GitHub issues are the **default front door** for substantive work — every project plan and every
non-trivial bug/fix opens an issue *first*, and that issue gets an in-repo pointer doc. The signal
stream lives in GitHub (machine-queryable state, labels, commit↔issue linkage); the execution
surface of record stays in `PROJECT/**`. This is the **issue-first SOP**; the bug-fix stance above
states the principle, and this section owns the *format*. To prevent duplicate intake and forgotten
work, every captured `GH-*.md` doc is also **parked immediately in `ROADMAP.md`** as a one-line queue
entry until it is promoted, deferred, or closed.

**Floor (what needs an issue).** The operational test is **lines of code touched**: any change
beyond a **2–3 line** fix opens a GitHub issue first, and its local plan doc is named after that
issue (see Filename below). Project plans, experiments, and features are always above this line.
**Exempt:** genuinely trivial edits — a ≤2–3 line code fix, a typo, a path repoint, a doc-only
one-liner, formatting — commit directly with a clear message and no issue. When in doubt, open the
issue — it is a cheap `gh issue create`. The SOP applies to *new* efforts going forward; in-flight
`1-INBOX`/`2-WORKING` docs are not backfilled.

Capture a tracked issue as a doc in `PROJECT/1-INBOX/` using this convention:

- **Filename:** `GH-<number>-VERY-SHORT-DESCRIPTION.md` — the local plan doc is always named after
  its GitHub issue (e.g. `GH-1234-SHOWME-COMMAND.md`, `GH-11-CROSS-REPO-TARGETING.md`). Keep the
  description to ~2–4 words; the issue number is the real key, the slug is just a human hint.
  SCREAMING-KEBAB to match the other inbox docs; no zero-padding — mirror the GitHub issue number.
  `<number>` resolves against `origin` (a single canonical repo), so the bare number is unambiguous.
- **Minimum frontmatter:** `gh_issue`, `source` (the full issue URL), `title`, `status`
  (`Proposed (1-INBOX — not yet active)`), `created`, and `doc_type` (`feedback` or `bugfix`).
  For medium-large captures, also include the triage ratings `effort`, `complexity`, `risk`, `phases`
  at capture time, so the queue can be triaged before promotion (see
  [Triage ratings for medium-large work](#triage-ratings-for-medium-large-work)).
- **Body:** transcribe the issue's actionable substance (the asks / acceptance criteria), not the whole
  thread. The live issue stays the discussion surface; this doc is the in-repo capture and back-reference.

Lifecycle:

- The `GH-` inbox doc is the **capture**, not the active-work doc. It carries no `## Status` table while
  it sits in `1-INBOX` (the inbox is the rough/untriaged bucket).
- Capture time also adds a **one-line `ROADMAP.md` queue pointer** linking that inbox doc. This is a
  temporary parking slot: it makes fresh intake visible to humans and automation before promotion,
  which is the duplicate-prevention guard.
- When execution starts, **promote** it to `PROJECT/2-WORKING/` — keep the `GH-` prefix for provenance —
  and it must then satisfy the full active-doc contract (frontmatter, exact status table, QA gates if
  phased), **carrying `gh_issue` forward**. The `ROADMAP.md` pointer is therefore required twice:
  first as a queued parking entry at capture, then as an active-work ledger entry after promotion.
  This is the concrete mechanism behind "GitHub issues are not a substitute for the local active-work
  doc once execution starts" (bug-fix stance above).
- If a captured issue is never actioned it ages out of `1-INBOX` like any other untriaged note; if it is
  closed without work, move the doc to `PROJECT/4-MISC` and remove its queue pointer from `ROADMAP.md`.

A foreign-repo issue (not `origin`) is the rare exception: the `source:` URL disambiguates it, since the
bare `GH-<number>` only guarantees uniqueness within the canonical repo.

## Automation layers

PDDA should have two classes of automation:

Implementation note:

- the automation ships as a single dispatcher, `utils/pdda/pdda.sh`, which sources shared helpers from
  `utils/pdda/pdda-lib.sh`
- every deterministic check is a subcommand: `pdda.sh frontmatter`, `pdda.sh status-table`,
  `pdda.sh hardcoded-paths`, `pdda.sh roadmap`, `pdda.sh roadmap-coverage`, `pdda.sh changelog`,
  `pdda.sh stale`, `pdda.sh issue-doc-sync`, `pdda.sh governance`
- the aggregate runner is `pdda.sh run` (it runs the deterministic checks in order, then the LLM
  review)
- each finding still carries a stable `check` id (e.g. `pdda-check-frontmatter`) in stdout and the
  activity log, independent of how the check is invoked
- **`run` reports what it found, not what it blocked on.** The mode gate forces every check's exit code
  to `0` outside `full`, so the closing line has three outcomes, not two: *all checks passed* (nothing
  found), *N error(s) found, not blocking in `<mode>` mode* (found, gate suppressed the failure), and
  *failures:* (found and blocked). Warnings never move the run out of the first state — a `warn` is the
  house-style advisory, and letting it read as failure would collapse the distinction. Inferring success
  from the gated exit code was BUG-001b: `run` printed *all checks passed* over real errors in `observe`
  and `light`, which are precisely the modes a new adopter starts in. The LLM readiness review is gated
  on the same signal, so an error-laden repo never spends an LLM call. **The rule:** a check that could
  not run — or could not block — must never be scored as a check that passed.

### 1. Deterministic hygiene checks

These catch issues where the answer should be the same every time.

#### A. `pdda.sh stale`

Purpose:
- inspect docs in `PROJECT/2-WORKING`
- detect stale docs based on file modification time
- **flag** them for a human to move (this check never moves files itself)

Minimum behavior:
- find docs in `PROJECT/2-WORKING` whose last edit is older than 4 days
- emit a `warn` finding per stale doc recommending the exact `git mv` to `PROJECT/4-MISC`
- honor a `pdda_hold: true` frontmatter override (skip the flag for held docs)
- log every flag to the activity log; **never** auto-move, so this check can never block a build

Why flag-only (design call, 2026-06-22):
- the auto-move was the repo's only destructive mechanic, and the activity log showed it never once
  fired a real move. The value is the flag; the move is risk with no proven payoff — a human runs one
  reversible `git mv`. mtime staleness is a deliberately loose signal, and flag-only makes a wrong
  guess cost nothing but an ignorable line. An opt-in move can be re-added later behind `pdda_hold` +
  `full` mode if it ever earns the miles.

#### B. `pdda.sh status-table`

Purpose:
- verify every doc in `PROJECT/2-WORKING` contains the exact two-column status table

Minimum behavior:
- fail if the `## Status` section is missing
- fail if the table headers are not exactly `What was just completed` and `What's next`
- fail if either first-row cell is blank

#### B2. `pdda.sh quad-concepts` (opt-in)

Purpose:
- when the `.pdda-quad` / `PDDA_QUAD` lever is on, verify each in-scope plan doc carries a
  `## Quad Concepts` section of 1–4 bullets (see [Quad Concepts (opt-in)](#quad-concepts-opt-in))

Minimum behavior:
- scope: `PROJECT/2-WORKING` + `PROJECT/1-INBOX/GH-*.md` + `PROJECT/3-COMPLETED`; skip `quad_exempt: true`
- parse the first `## Quad Concepts` section; count top-level, non-empty `-`/`*` bullets (skip fenced
  code, indented/nested and empty bullets; stop on the next h1/h2 or a blank line after a bullet)
- fail if the section is missing, has 0 bullets, or has more than 4
- **structure-only** — bullet *quality* (are they real `pain → fix` concepts?) is a warn-only job for
  the LLM readiness rubric, not this deterministic check
- runs standalone always; joins `pdda.sh run` only when the lever is enabled (orthogonal to the mode)

#### C. `pdda.sh frontmatter`

Purpose:
- ensure active docs expose the minimum machine-readable metadata

2026-08-18T16:08:15.691202Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "rg -n -i -C 4 'release ledger|check_releases|releases-current|tracking issue|Manifest-Members|Description:|Exit criterion' PROJECT/PDDA.md PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md utils/pdda/pdda.sh utils/pdda/pdda-lib.sh RELEASES.md ROADMAP.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4
 succeeded in 0ms:
PROJECT/PDDA.md-589-- validate `RELEASES.md`, the single forward-looking release-planning ledger — deliberately light.
PROJECT/PDDA.md-590-  This replaced an earlier per-tag-doc lifecycle (`PROJECT/releases/RELEASE-<tag>.md` with a
PROJECT/PDDA.md-591-  Draft/RC/Published status, linked marathons, linked issues, and a GitHub release-tag cache) that
PROJECT/PDDA.md-592-  turned out to be too much data to keep current for an initial release. Fields and checks grow
PROJECT/PDDA.md:593:  only as a real need shows up — see "RELEASES.md — release ledger" below.
PROJECT/PDDA.md-594-
PROJECT/PDDA.md-595-Scope: every `Release:` block in `RELEASES.md`.
PROJECT/PDDA.md-596-
PROJECT/PDDA.md-597-Minimum behavior:
--
PROJECT/PDDA.md-621-
PROJECT/PDDA.md-622-gh-degrade: none. The check is purely file-driven (no GitHub calls), which is a deliberate
PROJECT/PDDA.md-623-simplification over the old per-tag-doc check's issue/tag cross-checks against `gh`.
PROJECT/PDDA.md-624-
PROJECT/PDDA.md:625:#### RELEASES.md — release ledger
PROJECT/PDDA.md-626-
PROJECT/PDDA.md-627-**`RELEASES.md` is an optional planning aid.** It is not a required artifact, not a checklist, and
PROJECT/PDDA.md-628-not something to keep topped up. An empty file, a stale file, or no file at all are all valid
PROJECT/PDDA.md-629-states — `pdda.sh releases` skips a missing file entirely ("RELEASES.md not found — nothing to
--
PROJECT/PDDA.md-645-forward planning cross-reference it for target release names/dates.
PROJECT/PDDA.md-646-
PROJECT/PDDA.md-647-**The admission rule.** A block earns its place by being worth *planning toward* — a named arc with
PROJECT/PDDA.md-648-a theme, usually carrying a target date and a milestone. If the only thing that can go in
PROJECT/PDDA.md:649:`Description:` is a restatement of what changed, it belongs in `CHANGELOG.md` and nowhere else.
PROJECT/PDDA.md-650-Everything below the threshold goes in an `Iterations:` band (see the field docs) rather than getting
PROJECT/PDDA.md-651-its own block.
PROJECT/PDDA.md-652-
PROJECT/PDDA.md-653-The test is the theme, not the paperwork: `Target Date:` and `Milestone:` are optional fields and
--
PROJECT/PDDA.md-664-Status: Draft
PROJECT/PDDA.md-665-Target Date: 2026-07-31
PROJECT/PDDA.md-666-Codename: n/a
PROJECT/PDDA.md-667-Milestone:
PROJECT/PDDA.md:668:Description:
PROJECT/PDDA.md:669:Exit criterion:
PROJECT/PDDA.md-670-Manifest:
PROJECT/PDDA.md-671-GH_URL:
PROJECT/PDDA.md-672-Front-door reviewed:
PROJECT/PDDA.md-673-Shakedown reviewed:
--
PROJECT/PDDA.md-677-Fields:
PROJECT/PDDA.md-678-- `Release:` (required) — the version being planned
PROJECT/PDDA.md-679-- `Status:` (optional) — free-text, unvalidated by design (`Draft`, `Working`, `Shipped`, whatever
PROJECT/PDDA.md-680-  an operator finds useful). **`Status: Shipped` is the sole "already shipped" signal** — both
PROJECT/PDDA.md:681:  `pdda.sh releases`'s overdue nudge and `pdda.sh releases-current`'s "in progress" filter key off
PROJECT/PDDA.md-682-  it exclusively. This is a rough signal, not a gated lifecycle — no fixed vocabulary is enforced.
PROJECT/PDDA.md-683-- `Iterations:` (optional) — a **reserved band of version numbers**, written `<lo>-<hi>` (e.g.
PROJECT/PDDA.md-684-  `0.2.0-0.2.4`). Versions inside a band ship freely and are recorded in `CHANGELOG.md` only; they
PROJECT/PDDA.md-685-  **never get a block here**, and the band deliberately does not enumerate them. Absence of the
--
PROJECT/PDDA.md-720-  this file — which is why the field is worth having and why it stays a pointer. Unvalidated for the
PROJECT/PDDA.md-721-  same reason as `Status:`: checking a title against GitHub would need a `gh` call, and this check is
PROJECT/PDDA.md-722-  deliberately network-free. **Not warned on when absent** — a release with no milestone is a normal
PROJECT/PDDA.md-723-  state, and a nudge here would recreate exactly the fill-it-in pressure this section exists to stop.
PROJECT/PDDA.md:724:- `Description:` (optional) — a concise one-to-four-sentence statement of the release theme. It is
PROJECT/PDDA.md-725-  not a run log, implementation plan, or second changelog; historical outcomes stay in
PROJECT/PDDA.md-726-  `CHANGELOG.md` and execution detail stays in the canonical `PROJECT/**` document. `/releases`
PROJECT/PDDA.md-727-  warns when this field exceeds four sentences or becomes multi-paragraph history.
PROJECT/PDDA.md:728:- `Exit criterion:` (optional) — one runnable command or observable condition that proves the arc
PROJECT/PDDA.md-729-  reached its goal. Keep the implementation and phased QA plan in `PROJECT/**`; this field is the
PROJECT/PDDA.md-730-  release-level goalpost only.
PROJECT/PDDA.md-731-- `Manifest:` (optional) — a concise, fixed release boundary, normally a dated `FROZEN` list of
PROJECT/PDDA.md-732-  issue IDs. Prefer `Milestone:` when the intent is a live issue-set query. `/releases` triggers an
PROJECT/PDDA.md-733-  ambition review above seven named issues and when the list mixes themes, grows without a dated
PROJECT/PDDA.md:734:  re-scope, or lacks an exit criterion; the count is advisory, never an automatic rejection.
PROJECT/PDDA.md-735-- `GH_URL:` (optional) — populated once *a* GitHub Release object exists, including a draft (see
PROJECT/PDDA.md-736-  `/releases publish`). **This means "a Release object exists," not "shipped"** — a draft's
PROJECT/PDDA.md-737-  `GH_URL` is real but the release isn't out. Flip `Status: Shipped` yourself (or let
PROJECT/PDDA.md-738-  `/releases publish` do it on an actual, non-draft publish) when it's really out; `GH_URL` alone
--
PROJECT/PDDA.md-766-existing ledger, but it must never treat an absent, sparse, or merely old file as unfinished work or
PROJECT/PDDA.md-767-offer to top it up. A skill that exists to keep this file populated is the most efficient possible
PROJECT/PDDA.md-768-way to violate the optionality rule at the top of this section.
PROJECT/PDDA.md-769-
PROJECT/PDDA.md:770:#### `pdda.sh releases-current`
PROJECT/PDDA.md-771-
PROJECT/PDDA.md-772-Read-only roll-up (not part of `PDDA_DETERMINISTIC_CHECKS` — emits no findings, never gates): lists
PROJECT/PDDA.md-773-every `RELEASES.md` entry whose `Status` is empty or not exactly `Shipped`. A rough, non-authoritative
PROJECT/PDDA.md-774-answer to "what's currently in progress" — for a human, or for another repo's tooling (e.g. the XYZ
--
utils/pdda/pdda.sh-645-# ------------------------------------------------------------------------------------------------
utils/pdda/pdda.sh-646-# J. releases (warn-only nudge; never blocks, even in full)
utils/pdda/pdda.sh-647-# ------------------------------------------------------------------------------------------------
utils/pdda/pdda.sh-648-# Validates RELEASES.md, the single forward-looking release-planning ledger (see PROJECT/PDDA.md
utils/pdda/pdda.sh:649:# "RELEASES.md — release ledger"). Deliberately light: this replaced a heavier per-tag-doc lifecycle
utils/pdda/pdda.sh-650-# (status Draft/RC/Published, linked marathons, linked issues, a GitHub release-tag cache) that
utils/pdda/pdda.sh-651-# proved like too much data to keep current for an initial release. Grows only as real need shows up.
utils/pdda/pdda.sh-652-#   (1) error — a "Release:" block has an empty version
utils/pdda/pdda.sh-653-#   (2) warn  — Target Date is set but not a valid YYYY-MM-DD date
utils/pdda/pdda.sh-654-#   (3) warn  — Target Date has passed and GH_URL is still empty (looks overdue/unshipped)
utils/pdda/pdda.sh-655-#   (4) warn  — Iterations is set but isn't a well-formed "<lo>-<hi>" version band
utils/pdda/pdda.sh-656-#   (5) warn  — a block's version falls inside another block's reserved Iterations band
utils/pdda/pdda.sh:657:check_releases() {
utils/pdda/pdda.sh-658-  pdda_reset_counts
utils/pdda/pdda.sh-659-  local CHECK_NAME="pdda-check-releases" rc=0
utils/pdda/pdda.sh-660-  local RELEASES_FILE_EFF="${PDDA_RELEASES_FILE:-$PDDA_REPO_ROOT/RELEASES.md}"
utils/pdda/pdda.sh-661-  local release status target_date codename description gh_url line_no target_epoch today_epoch
--
utils/pdda/pdda.sh-730-    fi
utils/pdda/pdda.sh-731-
utils/pdda/pdda.sh-732-    # Front-door reviewed / Shakedown reviewed / License file: optional pre-release QA-gate
utils/pdda/pdda.sh-733-    # checkboxes, warn-only Yes/No like the rest of this check (see PROJECT/PDDA.md "RELEASES.md
utils/pdda/pdda.sh:734:    # — release ledger"). A blank value is fine (not yet answered); only a set-but-invalid value warns.
utils/pdda/pdda.sh-735-    for qa_field in "Front-door reviewed:$front_door" "Shakedown reviewed:$shakedown" "License file:$license_file"; do
utils/pdda/pdda.sh-736-      qa_label="${qa_field%%:*}"
utils/pdda/pdda.sh-737-      qa_value="$(pdda_trim "${qa_field#*:}")"
utils/pdda/pdda.sh-738-      [ -n "$qa_value" ] || continue
--
utils/pdda/pdda.sh-754-    fi
utils/pdda/pdda.sh-755-
utils/pdda/pdda.sh-756-    # Status: Shipped is the sole "already shipped" signal (GH_URL only means a Release object
utils/pdda/pdda.sh-757-    # exists — draft or published — not that the release is out; see PROJECT/PDDA.md "RELEASES.md
utils/pdda/pdda.sh:758:    # — release ledger"). A populated GH_URL alone no longer skips this check.
utils/pdda/pdda.sh-759-    status_lc="$(printf '%s' "$(pdda_trim "$status")" | tr '[:upper:]' '[:lower:]')"
utils/pdda/pdda.sh-760-    [ "$status_lc" != "shipped" ] || continue
utils/pdda/pdda.sh-761-
utils/pdda/pdda.sh-762-    # _pdda_cl_epoch is the changelog check's date->epoch helper, portable BSD/GNU; reused here
--
utils/pdda/pdda.sh-778-  return "$(pdda_gated_exit 0)"
utils/pdda/pdda.sh-779-}
utils/pdda/pdda.sh-780-
utils/pdda/pdda.sh-781-# ------------------------------------------------------------------------------------------------
utils/pdda/pdda.sh:782:# releases-current (read-only roll-up; not part of PDDA_DETERMINISTIC_CHECKS — no findings, no gate)
utils/pdda/pdda.sh-783-# ------------------------------------------------------------------------------------------------
utils/pdda/pdda.sh-784-# A rough, non-authoritative answer to "what release is in progress right now" — for a human, or for
utils/pdda/pdda.sh-785-# another repo's tooling (e.g. the XYZ sibling harness) to shell out to rather than re-implementing
utils/pdda/pdda.sh-786-# RELEASES.md parsing itself. Lists every release whose Status is empty or not "Shipped" (Status is
--
utils/pdda/pdda.sh-794-    printf '%s not found — nothing to report\n' "$(pdda_relpath "$RELEASES_FILE_EFF")"
utils/pdda/pdda.sh-795-    return 0
utils/pdda/pdda.sh-796-  fi
utils/pdda/pdda.sh-797-
utils/pdda/pdda.sh:798:  printf 'PDDA releases-current — in-progress entries in %s\n' "$(pdda_relpath "$RELEASES_FILE_EFF")"
utils/pdda/pdda.sh-799-  while IFS=$'\037' read -r release status target_date codename description gh_url \
utils/pdda/pdda.sh-800-    front_door shakedown license_file iterations milestone line_no; do
utils/pdda/pdda.sh-801-    [ -n "$(pdda_trim "$release")" ] || continue
utils/pdda/pdda.sh-802-    status_lc="$(printf '%s' "$(pdda_trim "$status")" | tr '[:upper:]' '[:lower:]')"
--
utils/pdda/pdda.sh-1238-pdda-check-roadmap-coverage:check_roadmap_coverage
utils/pdda/pdda.sh-1239-pdda-check-changelog:check_changelog
utils/pdda/pdda.sh-1240-pdda-stale-working-docs:check_stale
utils/pdda/pdda.sh-1241-pdda-check-issue-doc-sync:check_issue_doc_sync
utils/pdda/pdda.sh:1242:pdda-check-releases:check_releases
utils/pdda/pdda.sh-1243-pdda-check-governance:check_governance
utils/pdda/pdda.sh-1244-"
utils/pdda/pdda.sh-1245-
utils/pdda/pdda.sh-1246-cmd_run() {
--
utils/pdda/pdda.sh-1377-  changelog          end-of-iteration changelog nudge (warn-only)
utils/pdda/pdda.sh-1378-  stale              flag stale working docs (flag-only; never moves)
utils/pdda/pdda.sh-1379-  issue-doc-sync     flag 2-WORKING/GH-*.md docs drifted from their GitHub issue state (warn-only)
utils/pdda/pdda.sh-1380-  releases           validate RELEASES.md — the release-planning ledger (warn-only nudge)
utils/pdda/pdda.sh:1381:  releases-current   read-only roll-up: RELEASES.md entries whose Status isn't "Shipped" (rough, unvalidated)
utils/pdda/pdda.sh-1382-  governance         repo-root governance-doc (ROUTER/AGENTS/CLAUDE/...) cross-reference + doc/code drift
utils/pdda/pdda.sh-1383-  gh-refresh         refresh the cached GitHub issue-state file issue-doc-sync reads offline (needs gh)
utils/pdda/pdda.sh-1384-  doc-ready          LLM readiness review (delegates to pdda-doc-ready.sh; opt-in via PDDA_LLM_BIN)
utils/pdda/pdda.sh-1385-  catchup            LLM repo triage and ROUTER.md recommendations (delegates to pdda-catchup.sh)
--
utils/pdda/pdda.sh-1403-  roadmap-coverage) check_roadmap_coverage; exit "$?" ;;
utils/pdda/pdda.sh-1404-  changelog)        check_changelog; exit "$?" ;;
utils/pdda/pdda.sh-1405-  stale)            check_stale; exit "$?" ;;
utils/pdda/pdda.sh-1406-  issue-doc-sync)   check_issue_doc_sync; exit "$?" ;;
utils/pdda/pdda.sh:1407:  releases)         check_releases; exit "$?" ;;
utils/pdda/pdda.sh:1408:  releases-current) cmd_releases_current; exit "$?" ;;
utils/pdda/pdda.sh-1409-  governance)       check_governance; exit "$?" ;;
utils/pdda/pdda.sh-1410-  gh-refresh)       exec "$HERE/pdda-gh-refresh.sh" "$@" ;;
utils/pdda/pdda.sh-1411-  doc-ready)        exec "$HERE/pdda-doc-ready.sh" "$@" ;;
utils/pdda/pdda.sh-1412-  catchup)          exec "$HERE/pdda-catchup.sh" "$@" ;;
--
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-1----
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-2-gh_issue: 28
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-3-source: https://github.com/HiQS-Suite/XYZ-forge/issues/28
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:4:title: "RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue"
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-5-status: Proposed (1-INBOX — not yet active)
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-6-created: 2026-08-18
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-7-doc_type: feedback
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-8-effort: 2
--
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-18-`RELEASES.md` is contracted to be ~90% pointers/manifest (`PROJECT/PDDA.md` → "RELEASES.md — release
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-19-ledger"), with a narrative discipline rubric already living in `skills/releases/SKILL.md`
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-20-("Discipline and abuse warnings" — Description ≤4 sentences, Manifest ≤7 issues, no execution-history
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-21-prose). In practice the ledger keeps ballooning anyway: status appendices, run logs, and dated notes
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:22:get written directly into `Description:`/`Exit criterion:`/`Manifest:` fields.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-23-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-24-**Concrete instance (Ballast 0.7.0, 2026-08-17):** a long "BUILT 2026-08-17" status appendix was added
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:25:directly to the `Exit criterion:` field mid-release-gate-work — exactly the violation the skill already
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-26-warns against.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-27-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-28-## Root cause (two gaps, not one)
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-29-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-30-1. **No enforcement teeth.** The discipline rubric only fires when someone explicitly runs
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:31:   `/releases clean`. The deterministic checker (`check_releases()` in `utils/pdda/pdda.sh`) validates
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-32-   structure only (version present, date format, QA yes/no fields) and is deliberately warn-only by
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-33-   design — it never blocks, per `PROJECT/PDDA.md` section J.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-34-2. **No other legitimate home for release-level notes.** Manifest members each get their own GH issue;
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:35:   the release ledger entry itself (e.g. "Ballast 0.7.0") has none, so status/run-log notes go inline
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-36-   in `RELEASES.md` by necessity.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-37-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-38-## Validation scan (2026-08-18, ad-hoc, against live RELEASES.md)
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-39-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-40-Ran the proposed checks against all 7 real blocks before writing any code:
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-41-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:42:| Release | Description >4 sentences | Manifest-Members >7 tokens | Exit criterion length |
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-43-|---|---|---|---|
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-44-| 0.1.0 Quicksilver | clean | — (no field) | clean |
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-45-| 0.2.0 Litmus | clean | — | 592 chars / 6 sentences |
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-46-| 0.3.0 Nightwatch | 6 sentences | — | 2007 chars / 9 sentences |
--
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-51-| 0.8.0 (next) | 11 sentences | — | clean |
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-52-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-53-Two findings that changed the plan:
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-54-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:55:- **Manifest size is not the problem.** Only two blocks (0.6.0, 0.7.0) even use `Manifest-Members:`,
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:56:  and both are clean. The real bloat is entirely in `Description:` and `Exit criterion:`, and it's
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-57-  near-universal — 6 of 8 blocks trip the Description check, not just Ballast.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-58-- **"Spans multiple lines" is the wrong signal.** Every field in the file is one long wrapped physical
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-59-  line, never literally multi-line — a line-count check would catch nothing. Replaced with a
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:60:  sentence-count threshold on `Exit criterion:` (mirroring the existing Description rule): clean
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-61-  blocks sit at 0-592 chars, bloated ones start at 1544+ chars / 6+ sentences.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-62-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-63-## Revised proposed fix (lightest viable — no new skill, no new scanner binary)
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-64-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:65:1. Add a `Tracking Issue:` field to the `RELEASES.md` block spec (`PROJECT/PDDA.md` contract +
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-66-   `skills/releases/SKILL.md`'s plan-subroutine template). Extends the existing Issue-first SOP
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:67:   (`PROJECT/PDDA.md` → "GitHub issue intake") to the release ledger itself. Release-level status/run-log
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-68-   notes go there, not inline in the ledger.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:69:2. Extend `check_releases()` in `utils/pdda/pdda.sh` with deterministic bloat checks:
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:70:   - `Description:` exceeding 4 sentences (validated signal, confirmed above)
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:71:   - `Exit criterion:` exceeding 4 sentences (replaces the multi-line check — validated to actually
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-72-     catch the observed bloat)
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:73:   - `Manifest-Members:` exceeding 7 tokens (kept for when the field is used; low incidence today but
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-74-     cheap to check)
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-75-   Same line-based-check style already used in that function — no LLM needed for detection.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-76-3. Ship the new checks **warn-only first**. Run once against live `RELEASES.md`, confirm the hit list
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-77-   matches this scan, then flip to blocking in a follow-up commit — only after existing bloated blocks
--
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-87-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-88----
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-89-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-90-## Acceptance Criteria
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:91:- [ ] `Tracking Issue:` field documented in `PROJECT/PDDA.md`'s RELEASES.md contract and
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-92-      `skills/releases/SKILL.md`'s plan-subroutine template.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:93:- [ ] `check_releases()` flags Description/Exit-criterion/Manifest-Members bloat deterministically,
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-94-      with a registered regression test.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-95-- [ ] New checks ship warn-only first; existing bloated blocks (6 of 8, per the validation scan above)
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-96-      are cleaned up or explicitly grandfathered before flipping to blocking.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-97-- [ ] `skills/releases/SKILL.md`'s discipline section cross-references the new field/checks instead of
--
utils/pdda/pdda-lib.sh-8-PDDA_WORKING_DIR="${PDDA_WORKING_DIR:-$PDDA_REPO_ROOT/PROJECT/2-WORKING}"
utils/pdda/pdda-lib.sh-9-PDDA_COMPLETED_DIR="${PDDA_COMPLETED_DIR:-$PDDA_REPO_ROOT/PROJECT/3-COMPLETED}"
utils/pdda/pdda-lib.sh-10-PDDA_MISC_DIR="${PDDA_MISC_DIR:-$PDDA_REPO_ROOT/PROJECT/4-MISC}"
utils/pdda/pdda-lib.sh-11-# Forward-looking release-planning ledger — a single root file (like ROADMAP.md/CHANGELOG.md), not
utils/pdda/pdda-lib.sh:12:# a lifecycle bucket of per-tag docs. See PROJECT/PDDA.md "RELEASES.md — release ledger".
utils/pdda/pdda-lib.sh-13-PDDA_RELEASES_FILE="${PDDA_RELEASES_FILE:-$PDDA_REPO_ROOT/RELEASES.md}"
utils/pdda/pdda-lib.sh-14-PDDA_ACTIVITY_LOG="${PDDA_ACTIVITY_LOG:-$PDDA_REPO_ROOT/PROJECT/PDDA-ACTIVITY.jsonl}"
utils/pdda/pdda-lib.sh-15-# Cached GitHub issue-state file (TSV: "<number>\t<STATE>", '#'-comment lines ignored). Written by
utils/pdda/pdda-lib.sh-16-# pdda-gh-refresh.sh; read by `pdda.sh issue-doc-sync` when gh is absent/offline. Gitignored runtime
--
utils/pdda/pdda-lib.sh-446-}
utils/pdda/pdda-lib.sh-447-
utils/pdda/pdda-lib.sh-448-# --- RELEASES.md helpers -------------------------------------------------------------------------
utils/pdda/pdda-lib.sh-449-# RELEASES.md is a single forward-looking planning ledger (like ROADMAP.md/CHANGELOG.md), not a
utils/pdda/pdda-lib.sh:450:# bucket of per-tag docs — see PROJECT/PDDA.md "RELEASES.md — release ledger". Each release is a
utils/pdda/pdda-lib.sh-451-# flat "Label: value" block; a block starts at a line matching ^Release: and runs until the next
utils/pdda/pdda-lib.sh-452-# such line or EOF (blank lines between blocks are just visual spacing, not parsed).
utils/pdda/pdda-lib.sh-453-
utils/pdda/pdda-lib.sh-454-# List releases as rows of
--
utils/pdda/pdda-lib.sh-462-# THIS ROW SHAPE IS INTERNAL, AND ADDING A FIELD IS A BREAKING CHANGE. Callers read it positionally
utils/pdda/pdda-lib.sh-463-# with `read -r`, and there is no position that is safe to extend: a new field before <line> shifts
utils/pdda/pdda-lib.sh-464-# <line> onto the wrong variable, and one after it makes bash's last-variable-absorbs-the-rest rule
utils/pdda/pdda-lib.sh-465-# fold the extras into <line>. So <line> stays last as a record terminator, and every reader must be
utils/pdda/pdda-lib.sh:466:# updated in the SAME change — `check_releases` and `cmd_releases_current` are the only two, and
utils/pdda/pdda-lib.sh-467-# test/pdda-releases-iterations.sh pins the field count so a future addition can't drift silently.
utils/pdda/pdda-lib.sh:468:# The stable, external surface for other tooling is `pdda.sh releases-current`, not this helper.
utils/pdda/pdda-lib.sh-469-#
utils/pdda/pdda-lib.sh-470-# `Status:` is free-text (Draft/Working/Shipped/... — whatever an operator writes) and unvalidated
utils/pdda/pdda-lib.sh-471-# by design: it's a rough, non-authoritative signal for "what's in progress," not a gated lifecycle
utils/pdda/pdda-lib.sh-472-# field. `Milestone:` is free-text for the same reason — it carries a GitHub milestone *title* so a
utils/pdda/pdda-lib.sh-473-# release's scope can be queried (`gh issue list --milestone "<title>"`) instead of hand-listed here.
utils/pdda/pdda-lib.sh-474-# `Front-door reviewed:`/`Shakedown reviewed:`/`License file:` are optional Yes/No QA-gate fields,
utils/pdda/pdda-lib.sh-475-# and `Iterations:` is an optional reserved version band (`pdda.sh releases` warns on a malformed
utils/pdda/pdda-lib.sh:476:# value for either). See PROJECT/PDDA.md "RELEASES.md — release ledger".
utils/pdda/pdda-lib.sh-477-pdda_releases_list() {
utils/pdda/pdda-lib.sh-478-  local file="$1"
utils/pdda/pdda-lib.sh-479-  [ -f "$file" ] || return 0
utils/pdda/pdda-lib.sh-480-  awk '
--
utils/pdda/pdda-lib.sh-491-    /^Iterations:/          { v=$0; sub(/^Iterations:[[:space:]]*/, "", v); iterations=v; next }
utils/pdda/pdda-lib.sh-492-    /^Target Date:/         { v=$0; sub(/^Target Date:[[:space:]]*/, "", v); target_date=v; next }
utils/pdda/pdda-lib.sh-493-    /^Codename:/             { v=$0; sub(/^Codename:[[:space:]]*/, "", v); codename=v; next }
utils/pdda/pdda-lib.sh-494-    /^Milestone:/           { v=$0; sub(/^Milestone:[[:space:]]*/, "", v); milestone=v; next }
utils/pdda/pdda-lib.sh:495:    /^Description:/         { v=$0; sub(/^Description:[[:space:]]*/, "", v); description=v; next }
utils/pdda/pdda-lib.sh-496-    /^GH_URL:/               { v=$0; sub(/^GH_URL:[[:space:]]*/, "", v); gh_url=v; next }
utils/pdda/pdda-lib.sh-497-    /^Front-door reviewed:/ { v=$0; sub(/^Front-door reviewed:[[:space:]]*/, "", v); front_door=v; next }
utils/pdda/pdda-lib.sh-498-    /^Shakedown reviewed:/  { v=$0; sub(/^Shakedown reviewed:[[:space:]]*/, "", v); shakedown=v; next }
utils/pdda/pdda-lib.sh-499-    /^License file:/        { v=$0; sub(/^License file:[[:space:]]*/, "", v); license_file=v; next }
--
RELEASES.md-3-Forward-looking planning ledger for major releases — one block per release, minimal fields, blank
RELEASES.md-4-line between blocks. Marathon plans and other forward planning cross-reference this doc for
RELEASES.md-5-target release names/dates; it is not a history of what shipped (that's CHANGELOG.md — lessons
RELEASES.md-6-learned belong there at ship time, not duplicated here). Contract lives in PROJECT/PDDA.md ->
RELEASES.md:7:"RELEASES.md — release ledger". Add new fields only when a real need shows up.
RELEASES.md-8-
RELEASES.md-9-## This file is OPTIONAL (GH-381)
RELEASES.md-10-
RELEASES.md-11-**Read this before proposing an edit to it.**
--
RELEASES.md-46-Litmus-style test. Conversely #407 reports `pre-advance-failed` when no gate ran, and that *is* a
RELEASES.md-47-Litmus defect, because the violated invariant is the verdict itself.
RELEASES.md-48-
RELEASES.md-49-**A release is not its milestone.** A milestone is a backlog and grows while you work; a release needs
RELEASES.md:50:a frozen manifest and a testable exit criterion, both recorded in the blocks below. "The open issues
RELEASES.md:51:are done" is not an exit criterion, because working on a release generates more of them.
RELEASES.md-52-
RELEASES.md-53-## What belongs here, on the occasions it is used
RELEASES.md-54-
RELEASES.md-55-**Major and meaningful releases only. Not every release number.**
RELEASES.md-56-
RELEASES.md-57-A block earns its place by being worth *planning toward* — a named arc with a theme, a target date,
RELEASES.md:58:and a milestone. If the only thing you can write in `Description:` is a restatement of what changed,
RELEASES.md-59-it belongs in CHANGELOG.md and nowhere else.
RELEASES.md-60-
RELEASES.md-61-`Iterations:` reserves a band of patch numbers for a release. **Reserved, deliberately not
RELEASES.md-62-enumerated** — versions inside a band ship freely and are recorded in CHANGELOG.md only. They never
--
RELEASES.md-88-Iterations: 0.1.0-0.1.4
RELEASES.md-89-Status: Shipped
RELEASES.md-90-Target Date: 2026-08-01
RELEASES.md-91-Codename: Quicksilver
RELEASES.md:92:Description: Python-authoritative Tier-A twins. Licensed AGPL-3.0-only (`LICENSE`) with a commercial option (`LICENSE-COMMERCIAL.md`), adopted 2026-07-29 post-ship; the pre-existing conflicting `LICENSE.md` was removed 2026-07-30 (#372).
RELEASES.md-93-GH_URL: [GH 308](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/308)
RELEASES.md-94-Milestone: Quicksilver
RELEASES.md-95-Front-door reviewed: No
RELEASES.md-96-Shakedown reviewed: No
--
RELEASES.md-98-
RELEASES.md-99-Release: 0.2.0
RELEASES.md-100-Iterations: 0.2.0-0.2.4
RELEASES.md-101-Status: Shipped
RELEASES.md:102:Shipped: 2026-08-14 — RC 2026-08-09 on `development` @ `263816c`, soak window 5 days, re-verified at ship on `86ba3bd5`: `bash test/litmus-release.sh --release-gate` → exit 0, 6/6 complete, 0 false completion claims. **The ship test was the release's own exit command, not an issue-state audit.** Convention settled 2026-08-14: an exit criterion that is MET *is* the definition of done; a release is not held open by issues it never named. Falsification check on the soak window found nothing — every issue filed 08-09 → 08-14 (#485, #491, #499, #503, #504, #509, #510, #514, #518, #520, #521, #522, #523, #525, #527, #528, #533, #534, #536, #539, #540, #542, #544) either shipped inside it or left the exit command green, and the command was re-run on a `development` containing all of those fixes.
RELEASES.md-103-Target Date: 2026-09-05
RELEASES.md:104:RC evidence: `bash test/litmus-release.sh --release-gate` → `GOALPOST MET — all 6 manifest entries complete` (6/6, 0 remaining, 0 false completion claims). Its own negative control, `--mutate-evidence`, was re-run on the same commit and reports `negative control OBSERVED in both directions (6 pass, 0 fail)` — it detects a stripped declaration, an unregistered gate (the #461 defect), and an invariant violated in either direction. Four of the six issues are CLOSED with per-criterion evidence (#407, #417, #457, #461). **Residual scope, resolved at ship (2026-08-14).** Both entries' gates are registered, green and control-observed — which is what this release's exit criterion measures — but each carried acceptance criteria that did not ship, and an unshipped criterion is not a reason to hold a met goalpost open. **#375 is CLOSED** (this block previously said it remained open; that was stale). **#390's residual is now [#546](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/546), milestoned Meter** — Layer 4's host free-memory floor and packet-driven per-phase overrides, deferred by the source itself at `utils/py/marathon_drive.py:1509` (verbatim: `# Layer 4 (host free-memory floor) and packet-driven per-phase overrides are Phase 2.`). Meter is the right home rather than a parking space: a host floor is a precondition checked before spending, #382 is already a Meter member and its capture doc documents this exact deferral, and #392 is the static counterpart to this runtime one. #546 is **milestone backlog, NOT admitted to Meter's frozen manifest** — it does not make Meter's exit command fail, so "discovery is not admission" applies. #375's shipped three-state `unverifiable` verdict still deliberately contradicts its criteria 1 and 5, because implementing them literally took `relay-self-sufficiency.sh` from 4/0 to 0/4 on a working machine; that is recorded on the issue and is a deliberate deviation, not an omission.
RELEASES.md-105-Codename: Litmus
RELEASES.md:106:Description: Make the checks capable of failing. Every gate in the Litmus manifest is shown to report red against a real defect, or is explicitly downgraded to advisory — a check never observed failing is not evidence (#419). Ordered first because it is the release that makes the next one measurable. It is also what the self-improvement chain (#431) is blocked on: a Reviewer is a gate, so #419 applies to it, and its qualification gate is currently un-runnable (#428) and has only ever been measured once (#429).
RELEASES.md:107:Exit criterion: `bash test/litmus-release.sh --release-gate` exits 0. Red today by design; turning it green is what "done" means. Its own negative control is `--mutate-evidence`, which must detect a stripped declaration and an unregistered gate. NOTE the honest limit, stated in that file: the audit proves registration, declaration shape and the absence of false completion claims. It does NOT prove a control was truly observed, because `gate_inventory.py` reads a declaration authored by the same person who wrote the gate. Recorded execution of each control is deliberately out of scope for this release.
RELEASES.md-108-Manifest: FROZEN 2026-08-08 — #375, #390, #407, #417, #457, #461. Six named decision gates, a fixed denominator rather than a percentage. "Every gate" was unshippable prose: `gate_inventory.py` reports 152 of 158 gates with no declared control, and retrofitting them is explicitly out of scope. Adding an entry is a RE-SCOPE, not a bugfix: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission — #457, #460 and #461 were all filed while executing Litmus, which is what an unfrozen boundary looks like.
RELEASES.md-109-GH_URL:
RELEASES.md-110-Milestone: Litmus
RELEASES.md-111-Front-door reviewed: No
--
RELEASES.md-114-
RELEASES.md-115-Release: 0.3.0
RELEASES.md-116-Iterations: 0.3.0-0.3.4
RELEASES.md-117-Status: Shipped
RELEASES.md:118:Shipped: 2026-08-14 — RC 2026-08-11 on `development`, soak window 3 days, re-verified at ship on `86ba3bd5`: `bash test/nightwatch-release.sh --release-gate` → exit 0, **manifest 8/8 complete, lifecycle 5 passing / 0 failing / 0 NOT COVERED**. Half B *executes* the lifecycle cases rather than auditing them, so this is a run that killed real children and watched them recover — not a checklist. Falsification check on the soak window found nothing: the exit command was re-run on a `development` that already contains every fix landed 08-11 → 08-14, including GH-314 (the marathon transcript write-set), which is adjacent to this release's subject and was the one worth checking. The hostile-target write-set lifecycle case still passes via `gh514-write-set-trackable.sh`. Open non-manifest issues (#514, #467, #402, #392, #391, #386) do **not** hold this release open — the exit criterion never named them, and a milestone is a backlog, not a goalpost.
RELEASES.md-119-Target Date: 2026-10-10
RELEASES.md-120-RC evidence: `bash test/nightwatch-release.sh --release-gate` → `GOALPOST MET — all 8 manifest entries complete and every lifecycle case executes green` (manifest 8/8, lifecycle 5 passing / 0 failing / 0 NOT COVERED). Its own negative control, `--mutate-evidence`, reports 34/0 and `negative control OBSERVED in both directions`. Every manifest entry carries a recorded pre-fix control under `test/baselines/`, not an assertion that one happened. **Two entries are honest about their limits and are worth reading before signing off:** #358's Phase 2 is a *disposition* that needs a real CI failure carrying the new instrumentation, and its capture doc forbids pre-committing one — so Phase 1 shipped and Phase 2 is blocked on an observation, not on work; and #354's membership is Phase 1 only, which was delivered by #376/#448 rather than by this release, recorded as such rather than rebuilt. **#426's outcome inverted its own diagnosis:** a factorial control showed the leak survives with worktree isolation OFF, so teardown was exonerated and the real cause was the GH-375 auth pre-flight running with the caller's CWD, outside containment. **Twelve open Nightwatch-milestone issues remain and gate nothing**, per this block's own "a release is not its milestone" rule. **CI-VERIFIED 2026-08-12, and it was not before:** the goalpost was first met on macOS only, and two of the five lifecycle cases (#388, #514) were failing on every ubuntu CI run at the time the RC was recorded — their fixtures stubbed the builder but not the reviewer binary, so `marathon_drive.py`'s probe fail-fasted and the cases never executed the code they assert on. Fixed, and the gate now reports `GOALPOST MET` with `codex` absent from `PATH`, which is the CI condition reproduced locally rather than inferred. Recorded here because it is exactly the class of thing this release exists to catch: a green result that was green about the wrong environment. The general defect is #520; the control is `test/baselines/GH-520-negative-control.md`.
RELEASES.md-121-Post RC update: **#358 Phase 1 is in Nightwatch. Phase 2 is deferred to the Lantern build.** Operator decision, 2026-08-11, recorded here rather than left implicit in an issue thread. Phase 1 — the lock instrumentation — shipped and is counted in the RC evidence above; the manifest below is unchanged and this release does not wait on Phase 2. Phase 2 is the *disposition*, which needs a real CI failure carrying that instrumentation, and it belongs to Lantern because what it produces is a failure that states its own reason — Lantern's whole subject — not a lifecycle invariant. **#358 keeps its Nightwatch milestone**, because it is a frozen manifest entry counted in this block's evidence and re-milestoning it to tidy a join key would falsify a frozen boundary. Only the scope moved.
RELEASES.md-122-Codename: Nightwatch
RELEASES.md:123:Description: An unattended marathon against a real target repo survives, records, and recovers. Before dispatching work, it proves the target can accept the harness write-set and preserves the local-state contract, so hostile ignore rules or linked worktrees fail clearly rather than silently splitting, leaking, or losing the run. GH-354 Phase 1 is an early Nightwatch containment prerequisite: restore clone-wide driver exclusion for linked worktrees and prove all driver pairs fail closed. A run interrupted, killed at its cap, or panicking the host leaves a durable record and recovery path instead of a clean tree full of ungated commits. Depends on Litmus. The same durability work is what makes a reflection corpus trustworthy (#431): a run with no record is invisible to any later pass over it, and the loop's own evidence has never survived a reboot (#430).
RELEASES.md:124:Exit criterion: `bash test/nightwatch-release.sh --release-gate` exits 0. **BUILT 2026-08-11 and red by design**, exactly as Litmus's was; turning it green is what "done" means. It has two halves because a metadata audit cannot answer this release's question. Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), and has a RECORDED control under `test/baselines/`; it also cross-checks that this list and the `Manifest:` line below agree, since a boundary that disagrees with itself is not frozen. Half B **executes** the lifecycle cases rather than auditing them, delegating to the suites that already drive real children and kill them rather than growing a second driver fixture here. Status on 2026-08-11: **manifest 8/8 complete; lifecycle 5 passing, 0 NOT COVERED — GOALPOST MET.** The last gap was the hostile-target write-set case, closed by #514, which was filed while executing this release and deliberately NOT admitted to the manifest (discovery is not admission); it belongs to the lifecycle list because the exit criterion always named that case — what was missing was a suite driving it. That lane also corrected its own premise: the pre-fix tree does not dispatch a turn first, it dies at the render's `git add` with an unhandled `CalledProcessError` traceback, so the discriminating assertion is the absence of that traceback rather than the absence of a dispatch. Its own negative control is `--mutate-evidence` (34/0), which unregisters a gate and deletes a recorded control in a fixture copy, requires both to be detected, and re-checks the unmutated inputs green in the same run so an always-red detector cannot pass for one. Honest limit, inherited from Litmus: Half A reads a declaration and a filename and cannot know a recorded control was honestly recorded; Half B is what narrows that, and is why this criterion is a command that kills children rather than a checklist.
RELEASES.md:125:Manifest: FROZEN 2026-08-11 — #408, #409, #426, #388, #387, #384, #358, plus #354 Phase 1. Eight named entries, a fixed denominator rather than a percentage. The first six were moved out of Litmus on 2026-08-08 after a codex+agy consult; #387 and #384 are added at freeze time because the exit criterion above already names their cases — it requires a cap-killed child and a restarted recovery, and nothing else in the milestone supplies either. **The milestone is not the manifest.** Nightwatch's milestone holds 18 open issues; the twelve not listed here (#376, #378, #379, #380, #382, #386, #391, #392, #402, #467, #491, and anything filed during execution) are backlog worked inside the 0.3.0-0.3.4 band, and none of them gates the release. **AMENDED 2026-08-11:** five of those — #378, #379, #380, #382, #491 — were re-milestoned to Meter (0.6.0) at the operator's instruction, so they are no longer Nightwatch backlog at all. The manifest above is untouched and the RC evidence stands; what changed is only the non-gating remainder. #358 stays milestoned here because it is a frozen manifest entry whose Phase 1 shipped and is counted in the RC evidence above — only its *Phase 2* moved, and it moved to **Lantern**, not Meter (see the Post RC update line above). Adding an entry is a RE-SCOPE, not a bugfix, under the same admission rule Litmus used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission.
RELEASES.md-126-GH_URL:
RELEASES.md-127-Milestone: Nightwatch
RELEASES.md-128-Front-door reviewed: No
RELEASES.md-129-Shakedown reviewed: No
--
RELEASES.md-133-Iterations: 0.4.0-0.4.4
RELEASES.md-134-Status: Draft
RELEASES.md-135-Target Date: 2026-11-14
RELEASES.md-136-Codename: Plumbline
RELEASES.md:137:Description: Assisted reflection and a bounded self-improvement loop, measured before either is trusted. The reflection pipeline turns durable Nightwatch records into proposals (`proposals-sink.sh` gains its first production caller) and is graded against external ground truth — the 49 human-filed findings from the two rebalance-OS marathons (#405/#406) — for recall and precision. Ships a committed benchmark and a recorded go/no-go; "not worth automating yet" is a passing result, per #431's own Phase 2 exit criterion. Operator sign-off stays manual. Depends on Nightwatch.
RELEASES.md-138-GH_URL: [GH 431](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/431)
RELEASES.md-139-Milestone: Plumbline
RELEASES.md-140-Front-door reviewed: No
RELEASES.md-141-Shakedown reviewed: No
--
RELEASES.md-145-Iterations: 0.5.0-0.5.4
RELEASES.md-146-Status: Draft
RELEASES.md-147-Target Date: 2026-12-12
RELEASES.md-148-Codename: Lantern
RELEASES.md:149:Description: When the harness fails, the information needed to act already exists inside it — make it say so. Not "add checks": every case was already detected, and some were then described wrongly (a stack trace, a fabricated path, a success exit code, silence). Scope is one epic, deliberately narrow, and deliberately NOT Nightwatch: that milestone owns run lifecycle "even when lifecycle code emits a misleading message" (see the scope boundary above), and none of Lantern's cases violates a lifecycle invariant — they violate the legibility of a failure whose lifecycle handling was already correct. All four members were found in one afternoon during Nightwatch wave 3, which halted three times at zero paid-turn cost; each halt was avoidable from information the system already held. Depends on nothing; independent of Plumbline.
RELEASES.md:150:Exit criterion: `bash test/lantern-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it precedes fixing any member, which is the Litmus and Nightwatch ordering and the reason both releases could tell a finished entry from a claimed one. Two halves, the established shape: Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below. Half B **executes** #499's four phases rather than auditing them, since every one of them is a message an operator either receives or does not: a `relay-drive` launch preflight that refuses before spending, a gate refusal that states its real reason, a launcher exit code that survives its wrapper, and a change-impact report. **#358 Phase 2 is the one member with no executable half, and the criterion is written around that rather than pretending otherwise:** it is satisfied by a RECORDED transcript of a real CI failure under `test/baselines/`, and it must NOT be satisfiable by a disposition written in advance — that issue's own capture doc forbids pre-committing one, and an exit criterion that accepted a pre-written verdict would launder exactly the thing #419 exists to prevent. Its own negative control is `--mutate-evidence`, which must unregister a gate, delete a recorded control, and substitute a pre-dated disposition for a real transcript — detecting all three, and re-checking the unmutated inputs green in the same run so an always-red detector cannot pass for one.
RELEASES.md-151-Manifest: FROZEN at one issue on creation — #499, which supersedes and closes #494, #495, #496 and #498. Four phases, each shippable alone: relay-drive launch preflight; a gate refusal that states its real reason; a launcher whose exit code survives plus a gate-readiness check; and a change-impact reporter. Freezing at one is the whole point — these were filed as four and unified precisely to stop a single coherent change spreading across four PRs. **RE-FROZEN AT TWO on 2026-08-11 by explicit operator decision — #499, plus #358 Phase 2.** Recorded as a re-scope rather than an edit, because the admission rule below is worthless if a manifest can grow quietly: the operator named the entry and the release, which is the documented way past the rule, and this line says so with a date instead of just showing two items where there was one. It is a genuine fit, not a parking space — Phase 2 is a *disposition* that turns a lost concurrent-append record into a failure naming its own terminal lock state, which is Lantern's subject exactly, whereas the run lifecycle it sits inside was already handled correctly (that is the Nightwatch boundary, and it is why Phase 1 belonged there and Phase 2 does not). It was briefly a Meter member the same day and moved here before either release started; Meter's block records the move from its side. **#358 keeps its Nightwatch milestone** — it is a frozen entry counted in Nightwatch's RC evidence, so only its scope moved, and this is the second Lantern member not enumerable by `gh issue list --milestone Lantern`. Adding a further member is a RE-SCOPE, not a bugfix, per the Litmus rule above.
RELEASES.md-152-GH_URL: [GH 499](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/499)
RELEASES.md-153-Milestone: not created yet. The original reason — "#499 is unmilestoned by design while Nightwatch is the active goalpost" — expired when Nightwatch reached RC on 2026-08-11, and is kept here only so a reader does not act on it as if current. Creating it is a live decision, not a formality: **neither member would be enumerable by it as things stand** (#499 is unmilestoned, and #358 keeps its Nightwatch milestone deliberately), so the milestone would join nothing until #499 is assigned. The `Manifest:` line below is this release's authoritative scope either way.
RELEASES.md-154-Front-door reviewed: No
--
RELEASES.md-159-Iterations: 0.6.0-0.6.4
RELEASES.md-160-Status: Draft
RELEASES.md-161-Target Date: 2026-09-26
RELEASES.md-162-Codename: Meter
RELEASES.md:163:Description: A run accounts for what it spends and checks what it requires before spending it. Every member was found the same way — a real unattended marathon against `Hypercart-Dev-Tools/rebalance-OS` — and each one costs the operator something no gate ever reports: ten ready lanes blocked by two unrelated pre-existing test failures (#378); a builder killed by a $0.50 budget and escalated as a failed pre-advance gate, its `terminal_reason: budget_exhausted` left in an unreferenced temp file (#379); 108 of the target's own `permissions.allow` grants silently dropped because the directory was never trusted interactively, invisible in preflight, stdout and the escalation alike (#380); a host kernel-panicked under memory pressure while the run's telemetry reported tokens and wall-clock and nothing about memory (#382); and three codex builds plus three agy reviews spent re-running work the driver already had, because the cheap gate-only path exists but nothing points at it and `--retry` silently takes the expensive one (#491). Depends on Nightwatch — #382's numbers need a durable place to land, which is exactly what Nightwatch built. Independent of Plumbline and Lantern.
RELEASES.md-164-**RE-SCOPED 2026-08-15 by explicit operator decision — Meter is now the public-repository release candidate, and the paragraph above describes what Meter *was*.** The new sentence is: **XYZ can be handed to a stranger.** An unauthenticated clone reaches a documented entry path and exercises a supported happy path with no private context, from a tree that has been sanitized and secret-scanned. The metering work was not abandoned and it was not finished — five of its seven entries moved intact to Sundown (0.8.0), where they keep their capture docs, their acceptance criteria and their evidence. Recorded here as a re-scope with a date rather than presented as a release that always meant this, because a codename that quietly changes its subject is the same defect as a manifest that quietly grows. The reason for reusing Meter rather than opening an eighth release is that the operator named it: publication is the next thing that happens to this repository, and a launch release parked behind five unrelated engineering entries would have shipped late for reasons that have nothing to do with whether a stranger can clone it.
RELEASES.md-165-Publication target — **the deliverable is a sanitized clone, not this repository.** The public artifact is a new working tree cut from `development`, stripped of runtime state and internal working documents, committed as **fresh history with a single initial commit**, and pushed to **https://github.com/HiQS-Suite/XYZ-forge** — a new repository in a different organization, named by the operator on 2026-08-15, which becomes XYZ's permanent home. `CHANGELOG.md` is carried forward verbatim and is the public record of the project's history — it is a *file*, so it survives a fresh-history cut intact, and carrying 2,147 commits was rejected on 2026-08-15 for a stated reason: every document removed during sanitization stays reachable in a carried history, which makes the full-history secret scan this release requires a scan of everything ever deleted rather than a scan of one tree. Fresh history makes the sanitization complete by construction. `.tick/` (161 MB of runtime event state) and `relay-system/` (32 MB of relay transcripts) do not ship. `PROJECT/` ships as an **empty PDDA scaffold** plus the Meter build documents retained deliberately as a worked example of how PDDA is used — the method travels, the backlog does not.
RELEASES.md-166-Scope boundary — Meter vs Lantern: **Lantern owns how a failure is described; Meter owns what a run consumed and what it required.** Route by asking whether the issue names a *resource or a precondition* — dollars, turns, memory, swap, a trusted directory, a green suite — or names *the wording of a verdict whose handling was already correct*. Written down because two members straddle it and the file already has one recorded case (Litmus vs Nightwatch, 2026-08-08) of two descriptions that a competent agent could not route between. **#379 is split by that rule and belongs to both:** the overloaded exit 5 is a Lantern-shaped naming defect, the budget itself is a Meter resource, and the scope boundary above says to split an issue that violates both rather than argue it into one. **#491 is the marginal call and is placed here deliberately** — the re-scoped defect is a help-text and discoverability gap, which reads Lantern, but the invariant it violates is that the harness re-spends paid turns whose results it already holds, and the issue's evidence is a cost measurement.
RELEASES.md:167:Exit criterion: `bash test/meter-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it is Meter's first task, before any member is fixed — that ordering is the Litmus and Nightwatch precedent, and it is the whole reason both releases could tell a finished entry from a claimed one. Two halves, same shape as Nightwatch's: Half A audits the frozen manifest (each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below) and Half B EXECUTES the cases rather than auditing them — a run against a red-suite target proceeds under a recorded baseline and halts on a *new* failure; a budget-exhausted builder is escalated as budget-exhausted rather than pre-advance-failed; an untrusted target is reported before the first paid turn rather than after; a phase boundary records memory and swap; and a re-fire of an already-satisfied phase runs only the gate and says so. Its own negative control is `--mutate-evidence`, which must unregister a gate and delete a recorded control in a fixture copy, detect both, and re-check the unmutated inputs green in the same run. **RE-SCOPED 2026-08-15 with the release.** The command is unchanged and the two-half shape is unchanged — that shape is the reason Litmus and Nightwatch could tell a finished entry from a claimed one, and it is retained deliberately. What changed is what the halves measure, because a gate that audits a manifest which no longer exists is not a gate. **Half A audits the launch artifact**: the sanitized clone exists at the declared path and is a repository with exactly one commit; `CHANGELOG.md` is present and byte-identical to this repository's; `.tick/`, `relay-system/` and `temp/` are absent; `PROJECT/` contains the PDDA scaffold and the retained Meter example and nothing else; `LICENSE` and `LICENSE-COMMERCIAL.md` are present and mutually consistent; and the secret scan's recorded result names its tool version and the exact commit it scanned. **Half B EXECUTES the stranger's path rather than auditing it**: a clone taken with no credentials, from the published commit, reaches the documented entry point and completes one supported happy path with no file, token, or environment variable that exists only on the author's machine. Its own negative control, `--mutate-evidence`, is likewise re-pointed: in a fixture copy it must plant a private path in a tracked file, remove `CHANGELOG.md`, and leave a `relay-system/` directory behind, detect all three, and re-check the unmutated inputs green in the same run. **The gate is RED on arrival and is Meter's first task, before any sanitization is performed** — same ordering as the two releases that shipped.
RELEASES.md:168:Manifest: FROZEN 2026-08-11 on creation — #378, #379, #380, #382, #491. **RE-SCOPED TO SIX on 2026-08-12 by explicit operator decision: #509 admitted.** **RE-SCOPED TO SIX on 2026-08-14 (second decision the same day): #509 RETIRED as complete.** Its two unchecked criteria are not unfinished work — they are blocked by a LATER deliberate decision, GH-544, which retired hosted CI for the private phase. *"A push cannot cancel a running workflow_dispatch boundary run"* is now vacuously true and permanently unwitnessable: `ci.yml` carries only `workflow_dispatch:`, so no push can start a run, and you cannot control-test an interaction between two triggers when one of them no longer exists. *"A green hosted macOS full run exists for a chosen commit"* cannot be satisfied without spending the Actions minutes #509 existed to stop and #544 formally stopped. GH-544 already records that debt in its own terms and owns the re-arm trigger (the repo goes public), so keeping #509 open under Meter tracked the same gap twice while making the manifest look one item larger than it is. Phases 1-5 shipped. **RE-SCOPED TO SIX on 2026-08-14 by explicit operator decision: #551 admitted, and the target date pulled in from 2027-01-16 to 2026-09-26 in the same decision.** Recorded as a dated re-scope for the third time rather than shown as a list that has always had seven — the admission rule is worthless if a manifest can grow quietly, and it is worth as little if the third growth is the one that stops being announced. #551 is the shared root cause under nine open issues (#272, #310, #329, #365, #395, #504, #548, plus the already-closed #314/#440/#549) in which a resolver that cannot determine its answer returns a plausible default instead of refusing. It is a genuine fit on this block's own routing question — it names a **precondition**, not a description of a failure, so it is Meter and not Lantern — and two of its nine (#380, #491) were already Meter members, which is what surfaced it: they were being worked as separate defects when they are one. **RE-SCOPED TO SEVEN on 2026-08-15 by explicit operator decision: #555 admitted.** Recorded as a dated re-scope for the fourth time. #555 is the release's own exit criterion — the prerequisite for the other six being verifiable — so it ships first. The seven frozen manifest entries are #378, #379, #380, #382, #491, #551, and #555. **The date moved because Nightwatch shipped.** This release's only dependency was Nightwatch (#382's numbers needed a durable place to land), that shipped 2026-08-14, and Meter has been unblocked since — January was a date set while its blocker was still open and never revisited when the blocker cleared. Adding a further member is a RE-SCOPE, not a bugfix, under the unchanged rule below. Recorded as a re-scope with a date rather than shown as a list that has always had six, because the admission rule below is worthless if a manifest can grow quietly. It is a genuine fit, not a parking space: GH-509 is CI minute burn and route correctness — what a run costs and what it checks before spending — which is this release's sentence almost verbatim. The operator named the entry and the release, which is the documented way past the rule. Its plan is `PROJECT/2-WORKING/GH-509-CI-MINUTE-BURN.md`, replanned the same day on the macOS-target reframe and reviewed by agy. All six are milestoned Meter, so the ledger and `gh issue list --milestone Meter` cannot drift apart. **#358 Phase 2 was a member for part of 2026-08-11 and was moved to Lantern by operator decision the same day, before any Meter work began.** Recorded rather than quietly dropped: a frozen manifest whose membership changes without a trace is not frozen, and the honest version of "we got the routing wrong for an afternoon" is a dated line, not a clean list. It was the only entry blocked on an *observation* rather than on work, and the only one with no executable half — both of which now sit in Lantern's exit criterion, which is where the reasoning for them lives. The move is also correct on the boundary this block defines: Phase 2 produces a failure that states its own reason, which is Lantern's subject, not a resource or a precondition. Adding an entry is a RE-SCOPE, not a bugfix, under the same admission rule Litmus and Nightwatch used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission. **RE-SCOPED TO TWO on 2026-08-15 by explicit operator decision — the fifth dated re-scope of this manifest, and the only one that replaces the release's subject rather than extending it.** The seven engineering entries are dissolved. **#380 is CLOSED and shipped under the original scope**; it stays milestoned Meter as delivered work and is not a launch member — retiring a manifest does not un-ship what it produced. **#378, #379, #382, #491 and #551 move intact to Sundown (0.8.0)**, keeping their capture docs, their verbatim acceptance criteria and their milestone history; none of them was dropped, deferred without a home, or quietly closed. **#546 moves with them as Sundown backlog** — it was Meter milestone backlog and never a manifest entry, and it follows the subject it belongs to rather than the codename it happened to sit under. **The two frozen launch entries are #555 and #563.** #555 is the release's own exit criterion, re-pointed by the paragraph above and unchanged in its role: it ships first and it arrives RED. #563 is the launch checklist authored by an external reviewer (Codex Sol High) and covers the release boundary, public onboarding and behavior, the secret and privacy review, and the legal/CI/publication sequence. Freezing at two is the Plumbline precedent (frozen at one on creation) and is deliberate: the checklist was written as one coherent cutover and splitting it across issues is exactly what that precedent exists to prevent. **Scope is CLOSED to further admission by explicit operator instruction on 2026-08-15** — no issue filed after this date joins this manifest, and the standing admission rule below is superseded for this release only, because a launch whose scope can still grow does not have a date. Anything discovered during execution is filed, milestoned Sundown or left unmilestoned, and **waived in writing per #563's rule: a waiver names the failed criterion, the owner, the reason and the follow-up issue — silence is not a waiver.** Two known open items are covered by that rule rather than admitted: **#564** (31 unaudited suites that can reach the caller's clone through an empty fixture path) and **#544**'s re-arm debt (hosted CI fires on nothing while the repository is private, and going public is its own documented trigger). Both bear on publication and neither is a launch member; both need a waiver or a fix before the gate is called green.
RELEASES.md:169:Manifest-Members: 555 563
RELEASES.md-170-GH_URL: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/563
RELEASES.md-171-Milestone: Meter
RELEASES.md-172-Front-door reviewed: Yes
RELEASES.md-173-Shakedown reviewed: Yes
--
RELEASES.md-177-Iterations: 0.7.0-0.7.4
RELEASES.md-178-Status: Draft
RELEASES.md-179-Target Date: 2026-09-12
RELEASES.md-180-Codename: Ballast
RELEASES.md:181:Description: Post-launch hardening: **the launched repository holds up under a stranger's first run and an outside contributor's first push.** Every member was found the same way — by pointing the launch machinery at its own published output: the first fresh-clone runs of the public repository produced a different failing set each time (#15), a push gate that does not travel with clones got worse the moment the repo went public (#4), and the kernel's own event log can drop events on the concurrent path the kernel exists to coordinate (#14). Ballast exists because publication moved the failure surface from "our machines" to "everyone else's", and nothing in the shipped tree tests that surface. Builds on Meter's publication; depends on nothing unshipped.
RELEASES.md:182:Exit criterion: `bash test/ballast-release.sh --release-gate` exits 0. **NOT BUILT — writing it is Ballast's first task, before any member is fixed** (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. **Half A audits the frozen manifest:** each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. **Half B EXECUTES the stranger's path rather than auditing it:** (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. **BUILT 2026-08-17.** `test/ballast-release.sh` written and registered in `validate.sh`; suite mode green (`--mutate-evidence` 7/0). Half A: 3 of 4 manifest members complete (#14, #15, #3 — gate/registration/control/CLOSED-issue all confirmed); #4 landed the same day this file was written, so its CLOSED-issue credit is pending the next suite run. Half B's mechanics were smoke-tested end-to-end (all four sub-checks — B1/B2a/B2b/B3 — execute correctly against a real disposable clone) but **`--release-gate` has not yet been run for real** (the full ten-run stranger pass, against a clone cut from the commit that carries all four fixes) — that run is the actual goalpost and is still red pending it, honestly, not silently.
RELEASES.md-183-Manifest: FROZEN 2026-08-16 on creation — #14, #15, #4, #10, #3. Five entries, a fixed denominator rather than a percentage. Same admission rule Litmus and Nightwatch used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission. **#14 and #15 SHIPPED 2026-08-17** (PR #21, PR #20; each closed with evidence — atomic-write negative control, 10/10 consecutive parallel fresh-clone runs). **#3 SHIPPED 2026-08-17**: the durable-default and path-printing halves were already landed pre-freeze (GH-430); the sole remaining gap, a recorded negative control, closed the same day (`test/baselines/GH-3-state-dir-negative-control.md`) — closed as landed, not re-scoped or swapped. **#10 CUT 2026-08-17, invoking its own pre-declared contingency**: a driven marathon attempt (builder agy, reviewer codex, round-cap 5) escalated after 5 rounds without landing — the suite count the fix would need to touch grew from the estimated ~31 to 73 with zero mechanically adopted, and the builder self-issued a scope waiver rather than flagging the blocker back to the orchestrator. This is exactly the scope-slip the freeze anticipated ("#10 is the designated cut if scope slips... #1's clone-identity bracket already covers the same ground *detectably* in the meantime"); cut per that pre-authorized contingency rather than re-fired. Issue #10 stays open, un-closed by this cut — the underlying containment gap remains real, just descoped from Ballast. Manifest reduced from 5 to 4 entries; this is a recorded re-scope, not a silent drop.
RELEASES.md:184:Manifest-Members: 14 15 4 3
RELEASES.md-185-Explicit non-goals, stated so they are not silently absorbed: #16 (hosted CI re-arm — tracked separately, explicitly NOT in scope, the local pre-push gate stays the only gate), #9 (tooling floor: eslint/prettier, src/ coverage, decompositions), #11 (Sundown twin retirement), #12 (tree diet), #13 (fold scaling — its body was corrected 2026-08-16: it claimed event append is already atomic temp+rename, which was never true; #14 owns making it so).
RELEASES.md-186-GH_URL:
RELEASES.md-187-Milestone: Ballast
RELEASES.md-188-Front-door reviewed: No
--
RELEASES.md-193-Iterations: 0.8.0-0.8.4
RELEASES.md-194-Status: Draft
RELEASES.md-195-Target Date: 2026-10-17
RELEASES.md-196-Codename: Sundown
RELEASES.md:197:Description: Retire the twelve frozen Bash twins. Three steps, in order: (1) sweep for real `XYZ_PYTHON=0` usage — if nothing sets it, the fallback is already dead in practice; (2) re-vendor every fleet `.xyz/` copy onto the Python lane (`xyz-sync.sh list` is the worklist); (3) delete the twins and retire the GH-308 edit-guard, keeping only its no-new-Bash half (GH-551). Not before steps 1-2: the vendored fleet still runs the Bash path, and `XYZ_PYTHON=0` is the documented rollback. Depends on nothing in Meter.
RELEASES.md-198-**WIDENED 2026-08-15 by explicit operator decision — Sundown receives Meter's five engineering entries.** The release's sentence becomes: **the harness accounts for what it spends, checks what it requires before spending it, and stops carrying the retired Bash lane.** Said plainly rather than argued into one theme: the twin retirement and the metering work are two subjects sharing one release, and they are here together because Meter was re-pointed at publication on 2026-08-15 and these five needed a home that was not a parking space. They arrive intact — same capture docs under `PROJECT/2-WORKING/`, same verbatim acceptance criteria, same evidence — and the honest reading of the widening is that Sundown's date is now less trustworthy than it was, because it absorbed five entries without absorbing any schedule.
RELEASES.md-199-**RENUMBERED 0.7.0 → 0.8.0 on 2026-08-16 by explicit operator decision, to open 0.7.0 for Ballast.** Nothing about this release changed except its version: same codename, same target date, same manifest, same milestone. The band moves with it (`0.7.0-0.7.4` → `0.8.0-0.8.4`) because a release's iteration band is part of its identity here, not a separate fact. Recorded as a dated line rather than shown as a block that was always 0.8.0, on the same principle the manifest re-scopes above follow: a version that changes without a trace is indistinguishable from one that was misread. The `(0.7.0)` parentheticals in Meter's re-scope paragraphs were swept to `(0.8.0)` in the same edit — they identify *which release received the transfer*, so leaving them stale would have pointed a reader at a version that no longer exists. `CHANGELOG.md`'s existing entry is **not** swept: it is the append-only record of what was decided on 2026-08-15, when Sundown was 0.7.0, and the renumber is recorded there as its own dated entry instead.
RELEASES.md-200-Manifest: **#378, #379, #382, #491, #551**, received from Meter 2026-08-15, plus the twin-retirement work described above, which remains unnumbered until its issues are filed. **#546 is milestone backlog, not a manifest entry** — it followed the metering subject here and does not gate this release, under the standing rule that discovery is not admission. **Not yet frozen.** Freezing requires the twin-retirement issues to exist so the manifest is a fixed denominator rather than a list plus a promise; until then this line is a receipt for the transfer, not a contract. #380 did not move: it is CLOSED and shipped under Meter's original scope, and stays milestoned there.
RELEASES.md:201:Exit criterion: **NOT WRITTEN.** Required before this release starts, per the ordering Litmus and Nightwatch both used and Meter is repeating — the gate is built first and arrives RED, because a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one.
RELEASES.md-202-GH_URL: pending — api.github.com DNS outage 2026-08-14; file on recovery
RELEASES.md-203-Milestone: Sundown
RELEASES.md-204-Front-door reviewed: No
RELEASES.md-205-Shakedown reviewed: No
--
ROADMAP.md-67-- **`/open-router` skill — OpenRouter model-name resolve discoverability** 🆕 **2026-07-08** — `resolve-model-alias.sh` (GH-120) already resolves a colloquial name to a canonical slug locally, but a live session probed `aider --list-models` + curled the live catalog for "GLM 5.2" instead of using it. Added doc pointers (`aider-turn.sh`, `AGENTS.md`) + a new `skills/open-router/SKILL.md` so the alias table is checked first; no behavior change. See CHANGELOG `[Unreleased]`.
ROADMAP.md-68-- **GH-183 · GH-178 B1's isolation-breach detector false-positives on legitimate agy turns** 🆕 **found 2026-07-08 reviewing PR #182** — the post-hoc `$ROOT`-citation check fails a fully in-bounds agy turn whenever its response narrates the mandatory `TICK_REPO_ROOT="$ROOT"` tick command (ordinary LLM narration); shipped in PR #182 as-is per operator call rather than block the merge. Fix direction: exclude the known tick-command line from the scan, same pattern as the existing `[trace]`-line filter. → [GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md](PROJECT/2-WORKING/GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md) · [#183](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/183)
ROADMAP.md-69-
ROADMAP.md-70-### Queue / parked intake
ROADMAP.md:71:- **GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue** 🆕 **queued 2026-08-18, post-Ballast 0.7.0 follow-up** — root cause is two gaps: the discipline rubric only fires on manual `/releases clean`, and release-level notes have no home of their own (manifest members get GH issues, releases don't). Fix: add a `Tracking Issue:` field to the RELEASES.md block spec, and extend `check_releases()` with deterministic bloat checks (Description length, Manifest size, multi-line Exit criterion/Manifest). → [GH-28-RELEASES-LEDGER-DISCIPLINE.md](PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md) · [#28](https://github.com/HiQS-Suite/XYZ-forge/issues/28)
ROADMAP.md:72:- **GH-17 · SOP for evaluating new agent harnesses and frontier models** 🆕 **queued 2026-08-16** — establish a standardized operating procedure, checklist, and per-harness tracking issue workflow for new harness discovery, isolation, non-interactive execution, and cross-model matrix evaluation. → [GH-17-SOP-HARNESS-MODEL-EVAL.md](PROJECT/1-INBOX/GH-17-SOP-HARNESS-MODEL-EVAL.md) · [#17](https://github.com/HiQS-Suite/XYZ-forge/issues/17)
ROADMAP.md-73-- **GH-18 · Harness evaluation: Command Code (cmd) and model matrix** 🆕 **queued 2026-08-16** — evaluate Command Code CLI (v1.26.0), PATH resolution, auth, non-interactive `-p` execution, and model review benchmarks with `qwen/qwen3.7-flash` and `qwen/qwen3.8-max`. → [GH-18-COMMANDCODE-EVAL.md](PROJECT/1-INBOX/GH-18-COMMANDCODE-EVAL.md) · [#18](https://github.com/HiQS-Suite/XYZ-forge/issues/18)
ROADMAP.md-74-- **GH-536 · the gate-evidence record was a bare `result: green`** ✅ **BUILT 2026-08-14 on `fix/gh536-gate-evidence`** — the record now carries an `output-sha256` of the suite transcript plus per-suite verdicts, so a reader can tell a real run from a stamped one. **Three of the issue's four premises were factually wrong** (`ci-local.sh` already existed and already refused-if-dirty, ran the suite, and could not record after a failure); its trust-level argument is rejected and the `NOT-promotion-evidence` disclaimer is now pinned by a test — a self-computed hash is tamper-evident, not attested. → [GH-536-EVIDENCE-DETAIL.md](PROJECT/2-WORKING/GH-536-EVIDENCE-DETAIL.md) · [#536](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/536)
ROADMAP.md-75-- **GH-539 · a gitignored 2-minute skill-sync job resurrects deleted SKILL.md files** 🆕 **diagnosed 2026-08-14, NOT fixed — every candidate fix is cross-repo** — `com.rebalance-os.3eyes.skill-sync` runs every 120s doing a *bidirectional last-writer-wins* sync with `giant-brains-claude-skills`, and that has no representation for a deletion, so a removed skill is written back within two minutes. Preserved mtime (`Aug 11 15:29:08`, identical to the giant-brains source) is what ruled out a git-based restore. **This is the mechanism behind GH-395**, and it means no skill deletion here is durable. **Re-filed against the owning repo as [rebalance-OS#269](https://github.com/Hypercart-Dev-Tools/rebalance-OS/issues/269)** (the job, its registry entry and its plist all live there); #539 stays open as the consumer-side record. → [GH-539-SKILL-SYNC-RESURRECTION.md](PROJECT/2-WORKING/GH-539-SKILL-SYNC-RESURRECTION.md) · [#539](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/539)
ROADMAP.md-76-- **GH-527 · a destructive git command has no guard, and a doc rail demonstrably will not fix it** ✅ **BUILT 2026-08-14 on `fix/critical-2026-08-14`** — snapshot-then-allow PreToolUse hook copies the doomed *tracked* files into `.tick/orphan-backups/` before the command runs (the GH-141 `rtl_check` precedent), plus the `AGENTS.md` rail naming all three spellings. 26/0; recovery demonstrated end-to-end; clean-tree silence is defended by two conditions so it took a combined mutation to falsify. → [GH-527-DESTRUCTIVE-GIT-GUARD.md](PROJECT/2-WORKING/GH-527-DESTRUCTIVE-GIT-GUARD.md) · [#527](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/527)
--
ROADMAP.md-82-- **GH-423 · validate and codify 3+ agent swarm support** 🆕 **parked 2026-08-14 by the /10days sweep — needs a capture doc** — README claims "two or more" while `skills/xyz/SKILL.md:57` records the cap as unvalidated above two; six checkable acceptance items exist but closing the contradiction needs real multi-agent runs, not a doc edit. → [#423](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/423)
ROADMAP.md-83-- **GH-429 · the GH-40 Reviewer was qualified on a single blind run with no committed transcripts** 🆕 **parked 2026-08-14 by the /10days sweep — unblocked by GH-428, needs a capture doc** — a nondeterministic gate needs a measured pass rate re-established per model version. Was blocked on the rotted gamma fixture; that rot is fixed, so this is now actionable. → [#429](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/429)
ROADMAP.md-84-- **GH-518 · fuzzing loop emits PRs with no `--base development` and skips CI with no local fallback** ⏸️ **parked 2026-08-14 — awaiting an operator decision, deliberately NOT contracted** — `fuzz-agy-plan.sh:78` reproduces it, but the issue lists three option groups ("Ideas for Improvement") rather than a decided scope; auto-drafting a contract here would be guessing which group ships. → [#518](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/518)
ROADMAP.md-85-- **GH-520 · a fixture that does not stub `CODEX_BIN` tests the reviewer probe, not the code** ⏸️ **parked 2026-08-14 — awaiting an operator decision, deliberately NOT contracted** — third recorded instance of the same trap; `test/_setup.sh` still has zero `CODEX_BIN` references and the issue offers cost-ordered options while self-parking as "Parked. Not built." → [#520](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/520)
ROADMAP.md:86:- **GH-499 · 0.5.0 Lantern — the information needed to act already exists inside the harness** 🔒 **parked 2026-08-14 — release-order blocked, do not start members** — Lantern's frozen manifest is this epic plus GH-358 Phase 2, and `RELEASES.md:148` records its exit criterion as **NOT BUILT** with writing it required *before* any member is fixed. `test/lantern-release.sh` does not exist. → [#499](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/499)
ROADMAP.md-87-- **GH-421 · relay-xyz SKILL.md documents a `vendor` subcommand that does not exist** 🆕 **queued 2026-08-13 by /10days sweep** — the documented `xyz-vendor.sh vendor <repo>` form fails; correct it to the real single-positional contract and sweep sibling skill docs. → [GH-421-RELAY-XYZ-VENDOR-DOC.md](PROJECT/2-WORKING/GH-421-RELAY-XYZ-VENDOR-DOC.md) · [#421](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/421)
ROADMAP.md-88-- **GH-428 · gamma-poison poison.patch no longer applies, and nothing detects fixture rot** 🆕 **queued 2026-08-13 by /10days sweep** — re-derive the patch against current `src/paths.js` and add a non-recursive staleness probe to `validate.sh`. → [GH-428-GAMMA-POISON-FIXTURE-ROT.md](PROJECT/2-WORKING/GH-428-GAMMA-POISON-FIXTURE-ROT.md) · [#428](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/428)
ROADMAP.md-89-- **GH-430 · improve-loop.sh defaults its state dir to /tmp, so provenance evidence evaporates** 🆕 **queued 2026-08-13 by /10days sweep** — default to a tracked in-repo path per the GH-396 placement constraint and pin it with a registered test. → [GH-430-IMPROVE-LOOP-STATE-DIR.md](PROJECT/2-WORKING/GH-430-IMPROVE-LOOP-STATE-DIR.md) · [#430](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/430)
ROADMAP.md-90-- **GH-528 · measure and recalibrate the test suite — spike verdict + experimental parallel gate** 🚧 **spike complete 2026-08-13, Phase 1 built on `feat/gh528-parallel-validate`** — the spike measured the full gate (190 shell suites, 950.3s sequential), falsified the sleep-heavy hypothesis, found **zero** redundant suites (Codex+agy consult concurred), and identified parallelism as the one lever: with the 13 real-`relay-drive.sh` suites serialized into one lock lane (GH-42 exclusion preserved), 8-way runs green in ~167s. Phase 1 ships `validate.sh --parallel N` as **explicitly experimental**; sequential stays the default until Phase 2 promotion evidence (multi-width stress runs per the consult bar). Driver-lock scope (`relay_drive.py` locks harness root, not `RELAY_TARGET_ROOT`) parked as a Phase 3 separate issue. → [GH-528-TEST-SUITE-RECALIBRATION.md](PROJECT/2-WORKING/GH-528-TEST-SUITE-RECALIBRATION.md) · [#528](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/528)
--
ROADMAP.md-99-- **GH-409 + GH-408 · a leaked tick claim wedges the next turn, and every layer that could name the cause discards it** 🆕 **captured 2026-08-08 for release 0.2.0 Litmus, combined into ONE lane, awaiting operator go** — a shim claims its token and does not release it when the agent fails, so **two failed turns wedge that agent at its claim cap**. Then: the ownership error suggests a diagnostic that shows a *healthy* token, `rtl.py:74` sends the claim's stdout **and** stderr to `DEVNULL` so the `claim limit reached (holding …)` line naming both culprits is thrown away, `tick claim` prints that failure and **exits 0** so an exit-status check learns nothing either, and marathon-drive reports the result as `pre-advance-failed` on a phase **whose gate never ran** (#407). **Both fired live on 2026-08-07 and cost ~2h**, #409's transcript reproducing character-for-character with `agy` for `claude`. Combined because #408 is *why* #409 costs hours. Two additions the issues do not name: a **second** discard site (`rtl.py:74`, on every turn's path — #408 names only `_run_tick_loud`), and a **second** leak producer (a test suite claiming in the production log; fixed `7785c2a`, control 95→95 events). #432 shipped the persistence half and does **not** cover this. cx/risk/eff 2/2/3, 3 phases. → [GH-409-408-TOKEN-FAILURE-VISIBILITY.md](PROJECT/2-WORKING/GH-409-408-TOKEN-FAILURE-VISIBILITY.md) · [#409](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/409) · [#408](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/408) · [#407](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/407)
ROADMAP.md-100-- **GH-432 · a failed builder turn takes the one exit that skips `rtl_enforce`** 🆕 **captured 2026-08-06, in progress on `claude/gh432-turn-failure-persist`** — the generic-failure branch calls `sys.exit(5)` two lines before the timeout branch falls THROUGH to `rtl_enforce`, so a crashed turn skips the file-scoped commit, the allowlist containment check, the transcript archive, the GH-67 token handoff, and the drift signal in one step. **Worktree isolation makes the loss precise:** `worktree_end` has already copied the agent's allowlisted edits back into the real tree, so they are sitting there correct and uncommitted when the exit discards the only path that would commit them — the reporter confirms Round 3's lost patch "closely matched the fix I ended up applying by hand." **All five Python shims share the shape**, so the report is reachable via codex, agy, pi, and aider too; fixing only the reported file would leave it live. Largely subsumes **#409** (same defect from the token side); **#408** is adjacent and NOT fixed here. The issue carried no acceptance block — criteria derived from its "Suggested fix direction" per the GH-400 contract, with the deviations declared in the doc. Its second suggestion (a `RELAY_PEER` interaction) was **checked and declined**: unset `RELAY_PEER` only reaches a WARN branch that cannot fail a turn. cx/risk/eff 2/2/2, 2 phases. → [GH-432-TURN-FAILURE-PERSIST.md](PROJECT/3-COMPLETED/GH-432-TURN-FAILURE-PERSIST.md) · [#432](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/432) · [#409](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/409)
ROADMAP.md-101-- **GH-544 · local-gate-before-push: retire hosted CI for the private phase** 🆕 **operator decision 2026-08-14, captured — not built** — while the repo is private we stop paying for hosted CI and enforce the gate at the push boundary instead: an in-repo `pre-push` hook runs `validate.sh --parallel 8` (~167s, the fast form deliberately, because a 16-minute hook gets `--no-verify`'d rather than run), `ci.yml` loses its `push`/`pull_request` triggers with file and reasoning intact, and `marathon-closeout.sh` learns to tell *no checks configured* from *checks failed*. Coverage is unchanged — #528 already established there is nothing redundant to cut; this moves where the bill lands, not what runs. Knowingly sets aside GH-509's promotion boundary for the private phase and records the debt: no independent attestation, and Linux portability drift accumulates unreported until re-arm. **Re-arm trigger: the repo goes public** (Actions is free and unmetered on public repos, so the entire cost basis expires by construction). → [GH-544-LOCAL-GATE-BEFORE-PUSH.md](PROJECT/2-WORKING/GH-544-LOCAL-GATE-BEFORE-PUSH.md) · [#544](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/544)
ROADMAP.md-102-- **GH-522 · SmallCode (local Qwen 2.5 32B via LM Studio) as an autonomous marathon Builder — experiment run, verdict recorded** 🆕 **ran 2026-08-12..13, merged 2026-08-14 via PR #529** — adds a `smallcode` builder lane (`relay-automation/smallcode-turn.sh` plus agent routing in `marathon-agent.sh` and `utils/py/marathon_drive.py`) and records what four runs actually showed: the model **can** drive the harness — it passed tokens correctly, took a Codex change-request, and landed a real fix in `test/acorn-extract.sh` — but its inference engine repeatedly **wedges in tool-call loops** (run 3 re-issued a `tick claim` that had already returned `won`; run 4 re-read the same files until the 30-minute turn timeout), and SmallCode's own `quality-monitor` flagged `repeat_call` without aborting. Verdict: **not autonomous without strict repeat bounds**, recorded as a finding rather than a fix. Two defects the experiment introduced were fixed on merge rather than shipped: a hardcoded absolute SmallCode path ([#548](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/548), now `SMALLCODE_BIN` with a loud refusal) and the experiment's own driver script, which wiped `.tick/events/` and force-deleted the driver lock — withheld from the merge with the reasons recorded in the capture doc. → [GH-522-SMALLCODE-FUZZER.md](PROJECT/2-WORKING/GH-522-SMALLCODE-FUZZER.md) · [#522](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/522) · [#523](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/523)
ROADMAP.md:103:- **GH-555 · Meter 0.6.0 has no exit criterion — build it FIRST, and ship it RED** 🆕 **captured 2026-08-15, admitted to the Meter frozen manifest as entry SEVEN by explicit operator decision** — `test/meter-release.sh` does not exist, so Meter's other six entries are not falsifiable. Neither prior release gate was ever tracked work (`litmus-release.sh` and `nightwatch-release.sh` were both built inside other issues' commits), which is exactly why nobody could point at this one. Two halves per the Litmus/Nightwatch precedent: Half A audits the manifest for EXISTS/REGISTERED/RECORDED-CONTROL and cross-checks `RELEASES.md`; Half B **executes** the six member cases rather than reading declarations about them. **It must be RED on arrival** — a release gate that passes the day it is written has not been shown capable of failing (#419 at the release boundary). Exempt from thematic fit by construction: the exit criterion is what defines the theme. → [GH-555-METER-EXIT-CRITERION.md](PROJECT/2-WORKING/GH-555-METER-EXIT-CRITERION.md) · [#555](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/555)
ROADMAP.md-104-- **GH-563 · public repository launch — Meter becomes the public RC and the artifact is a sanitized, fresh-history clone** 🆕 **captured 2026-08-15; Meter frozen manifest entry TWO by explicit operator decision** — the published thing is not this repository: it is a clone cut with `git archive` (not a clone + orphan branch, which leaves the whole object database physically present until a gc), committed as ONE initial commit, pushed to a new organisation. `CHANGELOG.md` is carried verbatim as the public record of history; `.tick/`, `relay-system/`, `temp/`, `PARKED/`, `phases/` and `decisions/` do not ship; `PROJECT/` keeps the PDDA scaffold plus this release's own capture docs so the tree reflects the repo's real state. Measured by `test/meter-release.sh --release-gate`: Half A audits the artifact, Half B EXECUTES a credential-free clone completing the documented happy path under a scrubbed environment. → [GH-563-PUBLIC-LAUNCH.md](PROJECT/2-WORKING/GH-563-PUBLIC-LAUNCH.md) · [#563](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/563)
ROADMAP.md-105-- **GH-564 · a test suite can rewrite the REAL clone's git remote — `git -C ""` and `cd ""` are silent no-ops** 🆕 **reported from a live incident 2026-08-15 by a peer session; `gh544-pre-push-gate.sh` half fixed, 31 files unaudited** — the shared clone's `origin` was found pointing at a suite's throwaway bare repo, so its every push/fetch/ls-remote addressed a fixture. Pushes failed loudly; a **fetch would have succeeded against the wrong repository**, which is the shape that does real damage. Not a missing `-C`: every call already passed `-C "$r"`, but both escapes are documented no-ops on an EMPTY string and these suites run without `set -e`, so one unguarded `r="$(mktemp -d ...)"` redirects every fixture operation onto the caller's clone. Same family as #177 (mktemp resolving to repo root) and #559. Fixed by `require_fixture`, which demands a path exist AND live under `$WORK` — containment, not a null check, so a later edit cannot weaken it to `[ -n "$r" ]` and still pass. 78/0; control 72 pass / 6 fail pre-fix with *"the caller's real clone keeps its origin"* observed FAILING. → [GH-564-FIXTURE-CONTAINMENT.md](PROJECT/2-WORKING/GH-564-FIXTURE-CONTAINMENT.md) · [#564](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/564) · [#177](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/177)
ROADMAP.md-106-- **GH-557 · an unverifiable acceptance section reads as `ready` — `unknown` must block on a frozen manifest entry** 🆕 **filed and fixed 2026-08-15; deliberately NOT admitted to Meter, which stays frozen at seven** — preflight's fidelity check blocked only on `diverged`, so `unknown` reached `ready (exit 0)`. Observed live on Meter member #382 with `gh` authenticated and the network healthy: six criteria inlined from the capture doc, none on the issue, lane declared ready — GH-400's failure arriving through GH-400's own pass-through case. One status was hiding two situations that need opposite handling: a **transient** outage and a **structural** absence of criteria, which is why the 2026-08-14 DNS outage and the real defect produced identical output and the first was blamed for the second. Now `cause` distinguishes them; only the structural cause blocks, and only on a **frozen manifest member** — an outage stays advisory everywhere, and an ordinary exploratory lane is untouched. Membership is read from each `test/*-release.sh` goalpost's `MANIFEST=(...)` array, not from `RELEASES.md`'s prose, which names retired (#509), moved (#358 Ph2) and sibling (#551's nine) issues that a regex would have blocked. 16/0; control 5 pass / 11 fail pre-fix — the three that PASS pre-fix are the point. → [GH-557-UNKNOWN-BLOCKS-MANIFEST.md](PROJECT/2-WORKING/GH-557-UNKNOWN-BLOCKS-MANIFEST.md) · [#557](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/557) · [#400](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/400)
ROADMAP.md-107-- **GH-551 · a resolver that cannot determine its answer returns a plausible default instead of refusing** 🆕 **captured 2026-08-15 for Meter 0.6.0; RE-SCOPED 2026-08-14** — adopt one contract (*cannot determine → raise, never default*) and apply it per seam. Trimmed from nine members to ~3 open after a Fable review: #310 is citation semantics, #365 a file missing from `VENDOR_DIRS`, #504 an untested premise — none reduces to a resolver defaulting. The *"+ its Bash twin"* criterion was struck on an operator correction: per `AGENTS.md:131-137` the frozen-twin set is a **closed list of twelve legacy entry points**, so new code carries no twin obligation and a new Bash resolver would be dead on arrival. **Contended** — `rescue/gh344-gh329-path-resolution` already carries a #329 fix and another session is building the enforcement guard. → [GH-551-RESOLVER-REFUSES-INSTEAD-OF-DEFAULTING.md](PROJECT/2-WORKING/GH-551-RESOLVER-REFUSES-INSTEAD-OF-DEFAULTING.md) · [#551](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/551)
--
ROADMAP.md-149-- **GH-401 · `marathon-drive --dry-run` writes to the harness's own tracked `phases/p1/RELAY.md`** 🆕 **captured 2026-08-06 for release 0.2.0 Litmus, preflight READY, OPERATOR GO GIVEN 2026-08-08 — phase 2 of 3 in [MARATHON-2026-08-08-LITMUS-WAVE-2](PROJECT/2-WORKING/MARATHON-2026-08-08-LITMUS-WAVE-2/MARATHON.yaml)** — a dry run mutates the working tree, and the diff is **machine-dependent** (it rewrites embedded absolute paths), so it churns for everyone who runs the suite and reverts for whoever last committed it. **Observed live three times during the 2026-08-05/06 sessions**, each needing a hand revert before unrelated work could be committed, and once nearly swept into a commit. The existing guard `marathon-root-audit.sh` reads as covering this and does not — its scope is **two hardcoded filenames**, so the offending test is out of reach because of its *name*, not because it is safe. **A review correction:** the first criterion, *"writes nothing into any git repository"*, would have broken a legitimate existing test that renders into a caller-supplied fixture root; it now says *outside the root it was given*. cx/risk/eff 2/2/2, 2 phases. → [GH-401-DRY-RUN-MUTATES-REPO.md](PROJECT/2-WORKING/GH-401-DRY-RUN-MUTATES-REPO.md) · [#401](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/401) · [#209](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/209) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419)
ROADMAP.md-150-- **GH-418 · swarm-preflight can pass a lane whose issue is closed and whose artifacts are frozen — it never checks either** ✅ **BUILT 2026-08-08 in the Litmus marathon — agy-approved, full gate passed (704s), and it grew a third phase from its own review.** Phases 1-2 add the issue-state and GH-308 FROZEN-banner checks preflight never had (`test/gh418-issue-state-frozen.sh`, 143 lines). **Phase 3 was operator-approved mid-run after agy found a PRE-EXISTING crash while reviewing Phase 1-2:** `expand_effective_artifacts`'s `read()` helper (`swarm_preflight.py:366`) did `open(..., "r")` + `except OSError:` only while walking all of `test/`, so ONE binary file there was an uncaught `UnicodeDecodeError` that killed preflight outright — reproduced with a single probe. The tell was the asymmetry: codex's own new `find_frozen_artifacts` already used `encoding="utf-8"` + `except (OSError, UnicodeError)`. Now hardened and pinned by a binary fixture asserting both exit 0 **and** the absence of `UnicodeDecodeError`, since an exit-code check alone would pass if the error were merely swallowed. **preflight READY, awaiting operator go** — the **designated first child of #419**. Preflight validates a contract's *internal consistency* (artifacts exist, probes still detect the bug, base is fresh) and never asks the two questions that decide whether the work should run: is the issue still open, and are the targets writable by policy. So a lane can read READY, emit a packet, and send a builder to edit a frozen Bash twin to close an issue that shipped two weeks ago. Measured on the 2026-08-03 four-plan triage: Plan J both lanes CLOSED, Plan K **16 of 17** CLOSED, 2026-07-23's #279 CLOSED, and Plan M targeting `relay-automation/consult.sh` — **FROZEN**, so following that plan's own gate would violate GH-308. None of it discoverable from preflight; it was re-derived by hand twice, weeks apart. Cheap now because #400 already added the `gh issue view` call — `state` is **one more field on a request that already happens**, and #400's `unknown`-never-blocks posture covers the offline case unchanged. **Collides with #368 by construction:** its frozen check would refuse that lane, whose only write target carries the banner — fire #368 first (recorded identically in both docs). cx/risk/eff 2/2/2, 2 phases. → [GH-418-PREFLIGHT-ISSUE-STATE-FROZEN.md](PROJECT/3-COMPLETED/GH-418-PREFLIGHT-ISSUE-STATE-FROZEN.md) · [#418](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/418) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419)
ROADMAP.md-151-- **GH-417 · the tree asserts both that `rev-parse --show-toplevel` is the correct turn-ROOT default and that it is the bug "caught live"** ✅ **BUILT 2026-08-08 — `test/gh417-turn-root-symlink-prefix.sh` 13/0, the last unbuilt entry in the frozen Litmus manifest.** Filed as an **unreconciled contradiction with no regression coverage**, deliberately not as "it is broken now" — and that framing was right. `utils/py/rtl.py:resolve_turn_root` uses the construct by design (GH-296: a shim invoked from inside a same-repo vendored `.xyz/` must root at the true target repo), while `relay-turn-lib.sh` said that exact construct was wrong and was *"caught live."* **What actually resolved it: `312a2c3` (2026-07-21, GH-261)**, whose own commit message names the `test/marathon-drive.sh` GH-171/GH-172 failures — the ones Marathon Plan K measured on **2026-07-19** and explained by blaming `--show-toplevel`. Plan K was two days early. GH-261 canonicalizes **both** `RTL_ROOT` and each absolute allowlist entry to physical form before stripping, so either symlink form resolves; the GH-160 collapse runs *before* that and must not change ROOT's form, which is the whole of what its warning was ever about. The warning is **kept and scoped**, not deleted — it is still true of the collapse. **The control is what makes the test evidence:** reverting GH-261 in a fixture copy brings exit 6 straight back with the original symptom in words, and the *same reverted tree* passes when ROOT is pinned to the logical form — which is what identifies ROOT's symlink form as the axis rather than the fixture. The fixture builds its **own** symlink instead of trusting `$TMPDIR` (whose shape differs across macOS, Linux CI and a sandbox), and the **Python lane is proven** by a `python3` wrapper on `PATH` rather than assumed. Comments only in both files; the five GH-308-frozen Bash shims untouched. → [GH-417-TURN-ROOT-RESOLUTION.md](PROJECT/2-WORKING/GH-417-TURN-ROOT-RESOLUTION.md) · [#417](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/417) · [#426](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/426)
ROADMAP.md-152-- **GH-426 · worktree isolation leaks an off-lane creation into the harness repo — the turn correctly exits 6 and the file is still there** 🆕 **captured 2026-08-05 for release 0.2.0 Litmus, preflight READY, awaiting operator go** — under `RELAY_WORKTREE_ISOLATION=1` a file *created* inside the throwaway worktree also lands in the real harness repo. Isolation exists precisely to stop creations and renames reaching the real tree, where the allowlist's tracked-file revert cannot help. Three facts confirmed in **one run**: the stub's CWD really is the worktree (`rtl-wt.3FV3IO`), the shim really exits 6, and `offlane.md` is in the harness root anyway — while the declared target (`AGY_TURN_ROOT`) stays clean. **The exit code is reassuring and wrong**, and the defect is invisible to the obvious test: GH-410's regression case asserted absence in the target repo and passed, because that is where the file *wasn't*. Found while writing GH-410's counter-pin and filed separately rather than absorbed; predates it and reproduces independently. Plausibly one root with **#417** — the Python shim and Bash lib disagreeing about which repo is the target — so **never run the two as concurrent lanes**. Phase 1 ships a **red test only**: a lane whose subject is a test that passed for the wrong reason must not write fix and test together. cx/risk/eff 3/3/3, 2 phases. → [GH-426-WORKTREE-LEAK.md](PROJECT/2-WORKING/GH-426-WORKTREE-LEAK.md) · [#426](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/426) · [#410](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/410)
ROADMAP.md:153:- **GH-425 · `check_source_url` compares the issue number and ignores the repo slug** 🆕 **captured 2026-08-05 for release 0.2.0 Litmus, preflight READY, awaiting operator go — design call SETTLED 2026-08-05: option 1** — the gate extracts `owner/repo`, stores it, and never looks at it, producing a false positive and a false negative at once: legitimate cross-repo provenance is **refused**, and `source: .../SomeoneElse/unrelated-repo/issues/94` against `gh_issue: 94` reads **`ok` → READY**. The false negative is the worse half — the packet then tells the builder its acceptance was *"Verified against issue #94"* while pointing at someone else's #94: the #419 class **inside the gate built to enforce provenance**. Surfaced by dogfooding #422's backfill against `LTVera-Pandas`, whose GH-94 doc legitimately cites another repo's issue #2 and is not a typo. The issue offered three options and said *"this needs a call"*; the operator settled it on 2026-08-05 as **option 1** — `source:` always cites the TRACKING issue, cross-repo origins live in `related:`, options 2 and 3 rejected. The one measured refusal (`LTVera-Pandas` GH-94, citing a connector repo's issue #2) is fixed by moving that reference to `related:`; nothing is deleted, and the doc is in another repo so this lane only reports it. **Preflight reports this lane READY**, which is itself worth noting: it has no way to express "blocked on a human decision" (cf. #412). cx/risk/eff 2/2/2, 2 phases. → [GH-425-SOURCE-URL-SLUG.md](PROJECT/2-WORKING/GH-425-SOURCE-URL-SLUG.md) · [#425](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/425) · [#422](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/422)
ROADMAP.md-154-- **GH-368 · `marathon-plan.sh` documents `--check` as a `validate.sh` drift guard, but `validate.sh` never runs it** 🆕 **captured 2026-08-05 for release 0.2.0 Litmus, preflight READY, awaiting operator go — FIRE THIS BEFORE #418** — re-verified live 2026-08-05: the claim is still at `utils/marathon-plan.sh:67` and `validate.sh` invokes it **zero** times; `utils/py/marathon_plan.py` does not carry the claim, so the false statement exists in exactly one place. The smallest, cleanest instance of the #419 class in the tree — a documented guard that reads as active while nothing runs it, same family as #315/#319/#348. **Scoped to the issue's Option B** (delete the claim); Option A (wire it up) is separable and carries a real false-positive question — `--check` fails whenever today's plan doc has not been re-rendered, and *"a suite people learn to ignore protects nothing"* — so it stays open on #368 with #336's sidecar interaction as its first question. Three "If A" criteria dropped individually through #400's deviations mechanism, **which caught the first attempt**: declaring a deviation against a still-verbatim list was rejected as vacuous (the C8b hole closed during #399/#400, working). **Its only write target carries the GH-308 FROZEN banner**, which is the whole #418 collision — a comment correction is not a behaviour change, but #418's criterion 3 does not distinguish the two, and it should not be weakened to accommodate this. cx/risk/eff 1/1/1, 1 phase. → [GH-368-MARATHON-PLAN-CHECK-CLAIM.md](PROJECT/3-COMPLETED/GH-368-MARATHON-PLAN-CHECK-CLAIM.md) · [#368](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/368) · [#418](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/418)
ROADMAP.md-155-- **GH-410 · the worktree containment check greps the reviewer's prose for the repo path, turns on wording, and throws away a completed review** 🆕 **built 2026-08-05, awaiting review** — the containment *verdict* was `if root in line` over the agent's transcript (`agy-turn.py:223`), so it answered "did the model mention a path", not "did it access one". The two diverge both ways: an agent that quietly touched the real tree without naming it was never caught, and one that cited a path in a finding was failed for it. Reporter's quantified case, same run and same builder: the phase with **10** repo-root mentions was Approved, the one with **9** failed three times consecutively. Worse, **the harness supplies the string it punishes** — the retry preamble renders absolute paths into `RELAY.md` (`marathon_drive.py:403-407`, plus *"Use this exact tick binary … {tick_cli}"*), and it renders **only on a retry**, so failing once hands the next attempt more copies of the trigger. Four exemption shapes had already accreted (`[trace] `, `TICK_REPO_ROOT=`, `file://`, `](`) across two prior patches — a deny-list that does not converge. **Correction to the report's third item:** the shims do *not* disagree about containment — `rtl.worktree_end()`'s filesystem diff is called and enforced by **all five** (agy, codex, claude, aider, pi), each exiting 6. What agy alone carried was an *extra, unsound* layer, so uniformity is reached by removing it, not by copying it to four more shims; choosing a builder never picked a safety model, only an exposure to false positives. **Resolution:** writes are observable and stay the verdict; reads are not observable here (openat tracing is not portable under macOS SIP), so the honest answer is to stop asserting an unobservable property rather than keep asserting it badly. The prose scan is now an advisory recorded on the transcript and stderr, and **never fails a turn or discards a verdict** — a heuristic that destroys completed work must fail toward keeping it. Retry preamble now names `DEBUG-MANTRA.md`/`ESCALATION.md` with the directory given once; the tick line keeps its absolute path because "run it from any directory" requires it. Python only — all five Bash twins are frozen (GH-308). Suite **11/0** with two controls: pre-fix replay **7/4**, containment-deleted mutation **9/2** — and the mutation run caught a weakness in the counter-pin itself, which had been satisfied by a comment. cx/risk/eff 3/3/3. → [GH-410-CONTAINMENT-PROSE-SCAN.md](PROJECT/3-COMPLETED/GH-410-CONTAINMENT-PROSE-SCAN.md) · [#410](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/410)
ROADMAP.md-156-- **GH-422 · the source-URL gate's blast radius was measured on the harness only, and its remediation was a placeholder** 🆕 **built 2026-08-04, awaiting review** — PR #420's gate is right and unchanged; two things around it were not. Its posture came from a sample of **this repo alone** (1 of 48 docs) while the vendoring repos carried far more — the very miss #419 exists to catch — and the message it printed told operators to set `source: https://github.com/<owner>/<repo>/issues/N`, a value `repo_slug_for()` already derives from the target's `origin` in the same file. To be precise about what the gate does: it exits 5 with NOT-READY and writes no packet; **no file is altered, nothing is removed, no git state moves** — a refusal to start a lane, undone by one frontmatter line, sharing nothing with GH-312's destructive class. Now the message resolves the real slug, and `utils/py/backfill_source_url.py` remediates a whole repo in one command, deriving URLs from the **target's** origin so a vendored install cites its own project. Conservative by design: dry-run unless `--apply`; frontmatter-only with the body asserted byte-identical; and a `source:` citing a *different* issue than `gh_issue` is **never** rewritten but reported with a non-zero exit, because the incorrect field may be `gh_issue` and guessing would launder bad provenance into provenance that looks verified. **A live-consumer dry-run caught a real defect before merge:** `cactus` reported 0 to change against a measured 4, since its docs use `issue:` not `gh_issue:` — the gate blocks them via the `GH-9-*.md` glob, the tool read only frontmatter and skipped exactly those, reporting success over a still-blocked repo. Same two-extractors-disagree family as #413, one day later; the tool now uses the gate's own rule and C5b/C5c assert the gate **agrees** the doc passes afterwards. Fleet exposure also corrected upward to **34 docs, not 18** (the first blast script's glob was non-recursive). Dry-run: rebalance-OS 16, LTVera-Pandas 14 + 1 conflict for a human, cactus 4, three repos clean. Suite **20/0** with both #419 control forms — pre-fix replay 15/3, conflict-guard mutation 16/2. cx/risk/eff 2/2/2. → [GH-422-SOURCE-URL-REMEDIATION.md](PROJECT/3-COMPLETED/GH-422-SOURCE-URL-REMEDIATION.md) · [#422](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/422)
ROADMAP.md-157-- **GH-419 · trustworthy gates: a check that has never been observed failing is not evidence** ⚙️ **Phases 1-2 BUILT 2026-08-08 in the Litmus marathon — agy-approved, full gate passed (739s). Phase 3 is #418, built in the same run.** `GUIDING-PRINCIPLES.md` + `utils/py/gate_inventory.py` + `test/gh419-gate-inventory.sh` (169 + 75 lines) land the principle and a machine-readable per-gate inventory recording whether a negative control has been OBSERVED and in what form. Not closed: it is an umbrella, and its remaining children are still open.** — umbrella for one recurring defect class: *a gate reported green while structurally incapable of reporting anything else*. **Eight documented instances**, five of them already worked (#348 compared Python to Python; #351 regenerated the artifact it validated; #342 never ran on the default lane; #362 rejected a trailer permanently in history; #369 spun forever and blamed the wrong flag) and three surfaced in a **single afternoon** of read-only triage on 2026-08-03 (#400 nothing compared the capture doc to its issue; #417 no test can distinguish the two candidate turn-ROOT behaviours; #418 preflight never checks issue state or the GH-308 FROZEN banner). Every one passed review; every one was caught by a human reading the check and its subject side by side, weeks later. The principle is enforceable because the repo already applies it ad hoc — #400's suite was observed at 1 pass / 19 fail against pre-fix code, GH-400 criterion 2's at 2 pass / 11 fail, and #348's fix carries an in-run mutation self-check — what is missing is that these are acts of diligence rather than a contract. Scope is deliberately **decision gates only** (preflight, `fix_probes`, planner/pre-advance, containment, plus the tests certifying them), never ordinary unit assertions, and it starts as **policy plus an evidence inventory that changes no execution behaviour**, so rollback is deleting a doc section and a generated file. **#418 is the designated first child**, mirroring GH-308 Phase 1's use of #278 as proof its policy worked. Scope, sequencing and acceptance were revised after a Codex review that caught three defects in the original framing: a demanded "pre-fix count" that cannot exist for net-new behaviour, an inventory criterion conflating automatic *discovery* with evidence that must be *declared*, and an `unknown`-reporting requirement loose enough to land on ordinary unit tests. Preflight contract authored and verified READY via `--dry-run`; acceptance reads `match — 8/8 criteria copied verbatim from issue #419`. cx/risk/eff 3/2/3, 3 phases, ratings provisional. → [GH-419-TRUSTWORTHY-GATES.md](PROJECT/2-WORKING/GH-419-TRUSTWORTHY-GATES.md) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419) · [#418](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/418) · [#417](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/417)
--
ROADMAP.md-185-- **GH-274 · marathon-drive: re-invoking a phase whose tick token is already done clobbers RELAY.md's Approved record instead of detecting a satisfied lane** 🆕 **found live 2026-07-21 during GH-273 Phase 0's real fire** — the relay succeeded (Codex builder, agy reviewer, Approved), the `bash validate.sh` pre-advance gate flaked on an unrelated pre-existing test, and retrying via `marathon-drive.sh` re-rendered `RELAY.md` back to `STATUS: Open` and failed on the already-`done` tick token (can't reopen), discarding the accurate Approved record — recovered manually via `git revert`. Fix direction: extend the existing GH-207 satisfied-lane detection to also cover "gate failed after an already-terminal relay," not just its current mid-relay reroute case. Not blocking — a distinct `--phase-id` per fire avoids the collision entirely (confirmed live during GH-273 Phase 1's fire), but `swarm-preflight`'s suggested command never varies it, so any caller copying that verbatim across repeat fires hits this. cx/risk/eff 3/2/2. → [GH-274-MARATHON-DRIVE-DONE-TOKEN-RETRY-CLOBBER.md](PROJECT/3-COMPLETED/GH-274-MARATHON-DRIVE-DONE-TOKEN-RETRY-CLOBBER.md) · [#274](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/274)
ROADMAP.md-186-- **GH-294 · swarm-preflight: isolation flag not carried into the suggested marathon command** 🆕 **landed 2026-07-26 (marathon phase 1/4)** — the preflight packet's suggested invocation omitted the worktree-isolation flag, so a copy-paste fire silently ran unisolated. Relay Approved, lane satisfied. → [GH-294-PREFLIGHT-ISOLATION-FLAG.md](PROJECT/3-COMPLETED/GH-294-PREFLIGHT-ISOLATION-FLAG.md) · [#294](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/294)
ROADMAP.md-187-- **GH-292 · A linked worktree cannot discover the main checkout's vendored .xyz harness** 🆕 **landed 2026-07-26 (marathon phase 3/4)** — `find-harness.sh` now resolves the main checkout's `.xyz/` from a linked worktree via the shared `.git` probe, and falls back truthfully when that vendor is unusable. Gate initially failed on two static guards (GH-177 mktemp shape, GH-64 unsanitized eval) in the new fixture; both fixed rather than baselined. → [GH-292-WORKTREE-VENDORED-DISCOVERY.md](PROJECT/3-COMPLETED/GH-292-WORKTREE-VENDORED-DISCOVERY.md) · [#292](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/292)
ROADMAP.md-188-- **GH-272 · Driven relay turn's tick release resolves wrong TICK_REPO_ROOT in a vendored same-repo lane** 🆕 **captured 2026-07-21 via /file-xyz-bug from `sleuth-app`; root-caused + fixed 2026-07-23 via GH-296/PR #297, NOT this doc's own contract** — traced to `RelayTurnLib._run_rtl()` (`utils/py/rtl.py`) feeding `codex-turn.py`/`agy-turn.py`/`claude-turn.py`'s buggy `root` default into every bridged `relay-turn-lib.sh` call (incl. the turn-prompt text and the GH-67 backstop release) as `TICK_REPO_ROOT`. Confirmed via a live A/B repro with `xyz-vendor.sh`: pre-fix baked `TICK_REPO_ROOT="<target>/.xyz"` into the prompt and the backstop release itself, matching this issue's exact symptom; post-fix (PR #297) resolves both. This doc's own drafted contract targeted `relay-turn-lib.sh`'s `rtl_tick_bin()` — the wrong file — and is marked superseded/do-not-fire. cx/risk/eff 3/2/2 (provisional, now moot). → [GH-272-TICK-REPO-ROOT-VENDORED-MISMATCH.md](PROJECT/2-WORKING/GH-272-TICK-REPO-ROOT-VENDORED-MISMATCH.md) · [#272](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/272) · [#297](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/297)
ROADMAP.md:189:- **GH-284 · marathon closeout → release-driven selection (6 phases; P1-P4 ✅ SHIPPED, P4 2026-07-29)** 🟡 **captured 2026-07-23 (/10days sweep)** — **P1** closeout PR (`--open-only` + `--closeout-pr`), PR [#316](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/316). **P2** file-based driver liveness + opt-in idempotent GitHub run log, PR [#317](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/317) — its marathon surfaced [#319](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/319) (every phase gate was fake) and [#320](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/320), and its merge surfaced [#322](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/322) (`--log-github` silently swallowed by the Python lane, so P2's feature was inert by default). **#322 closed 2026-07-29 and P2 is now effective**: PR [#324](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/324) stopped the silence, then the port landed BOTH Phase 2 halves in `utils/py/marathon_drive.py` — the run log *and* the driver heartbeat, which #322 had believed was already there (its "12 references" were `xyz_marathon_heartbeat_*`, the unrelated GH-75 session record; `grep -c driver_heartbeat` on the Python twin was 0). `test/gh322-runlog-python-lane.sh` 5/19 pre-fix → 26/0. **P3** the release→issue-set join key: `RELEASES.md` gains `Milestone:` (a GitHub milestone title, not a URL and not an issue list), the `pdda.sh releases` check warns when a dated unshipped release lacks one, `releases-current` surfaces it, and GitHub milestone **Quicksilver** was created with #308 assigned. `test/gh284-p3-release-milestone.sh` is the **first test the releases check has ever had** (10 pass/5 fail pre-fix, 15/0 after). **P4** SHIPPED 2026-07-29 — `utils/release-lanes.sh` closes the loop in both directions: `seed` turns a release's `Milestone:` into a marathon candidate list in the same JSON shape `skills/10days/scan-issues.sh` emits, and `rollup` reports `N/M landed` from git ancestry. GitHub's own PR↔issue linkage turned out to be **empty on every issue in this repo**, so "landed" is evidenced by a commit whose CONVENTIONAL SCOPE claims the issue (`type(GH-N):` / leading `GH-N`); a bare `#N` is the squash-merge PR number and is rejected. Reports `landed`/`mentioned`/`absent`, because the matcher under-reports (a fix inside a marathon commit claims no issue) and a silent binary would call that a clean "not done". `test/gh284-p4-release-lanes.sh` 33/0, mutation-tested. **P5-P6 scoped, not contracted.** Original capture: — after a marathon run completes successfully, open a non-merging PR (opt-in `--closeout-pr` flag) carrying deterministic notes built from the plan name/phase count/tick events, reusing `marathon-closeout.sh`'s existing PR-creation code behind a new `--open-only` flag. Fully spec'd by the issue itself (exact seam, acceptance criteria, explicit non-goals: no merge, no force-push, no branch creation). cx/risk/eff 2/2/2 (provisional). → [GH-284-MARATHON-CLOSEOUT-PR.md](PROJECT/2-WORKING/GH-284-MARATHON-CLOSEOUT-PR.md) · [#284](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/284)
ROADMAP.md-190-- **GH-153 · Cost observability: Codex per-turn token capture (parseCodexStats)** 🆕 **captured 2026-07-23 (/10days sweep)** — was gated on #151 (Phase 4 discovery spike), now CLOSED; its recorded finding says the Codex capture gate check passes and `parseCodexStats` can mirror the existing `parseGeminiStats` almost exactly. Confirmed unimplemented in `src/cost.js`; `codex-turn.sh` needs `--json` wired into its `codex exec` invocation. Full spec already written in `PROJECT/1-INBOX/COST-OBSERVABILITY-PLAN.md` Phase 7. cx/risk/eff 2/1/2 (provisional). → [GH-153-CODEX-TOKEN-CAPTURE.md](PROJECT/2-WORKING/GH-153-CODEX-TOKEN-CAPTURE.md) · [#153](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/153)
ROADMAP.md-191-- **GH-268 · Beta onboarding & build-quality test report — remediation plan (re: #123)** 🔄 **Phases 1–2 done 2026-07-28; Phases 3–4 open** — Phase 1 closed: skill installers shipped via PR #282, and the clean-clone Quickstart was **verified green** (fresh clone of `development`, 133/133, exit 0) rather than needing a fix — only its "~1 minute" claim was wrong (~8 min measured). Phase 2 closed: README reordered to lead with what-it-is + Quickstart, CLI prerequisites lifted above the fast path with real install URLs, `relay-automation/README.md` retitled "Set up Codex, agy, and Pi" with an install/auth table, sandbox-hang callout added — plus **two dead prerequisite anchors** the report never saw (`a595c6f` renamed the target heading on 2026-07-23). Still open: **Phase 3** (relay handoff cues; the review loop checks the diff not the file it lands in) and **Phase 4** (cross-model re-test). Original findings: beta tester (Matthew Taylor) found 2 blocking onboarding issues (Quickstart fails on a clean clone; a named skill has no installer), 4 fix-before-broader-beta README/sandbox items, 2 follow-up process gaps (manual relay handoff; the review loop checks the diff not the file it lands in — an independent audit found 20 issues incl. 1 critical in code a relay approved), and 1 untested item (cross-model Codex/agy lane never ran — blocked on #232, now closed). Single plan doc, 4 phases, no per-finding issue split per operator instruction. cx/risk/eff 4/3/5 (provisional). → [GH-268-BETA-ONBOARDING-BUILD-QUALITY-REMEDIATION.md](PROJECT/3-COMPLETED/GH-268-BETA-ONBOARDING-BUILD-QUALITY-REMEDIATION.md) · [#268](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/268)
ROADMAP.md-192-- **GH-261 · marathon-drive: reconcile the Bash/Python disjoint-failure union (last Phase-1 gate for the XYZ_PYTHON flip)** ✅ **SHIPPED — closed 2026-07-22 (PR #271, merge 2a2da17)** — split out of #255; Python side already DONE (112/0 under XYZ_PYTHON=1, PR #262). Bash side (`test/marathon-drive.sh` exit 6 where 4/0 expected) fixed via direct RTL_TRACE instrumentation, not the issue's original hypothesis: real causes were (1) a bidirectional physical/logical symlink-form mismatch between `RTL_ROOT` and an absolute `RTL_ALLOW` entry, and (2) `rtl_check()` missing the collapsed-directory transcript-log exemption GH-266 already gave `rtl_worktree_end`. The issue's own "inherited TICK_REPO_ROOT" hypothesis was tested directly and confirmed real but NOT the actual gating cause. `test/marathon-drive.sh` 112/112 under both runtimes, confirmed on a real ubuntu:latest container. cx/risk/eff 4/5/3. → [GH-261-MARATHON-DRIVE-BASH-CONTAINMENT-VENDORED-CHAIN.md](PROJECT/3-COMPLETED/GH-261-MARATHON-DRIVE-BASH-CONTAINMENT-VENDORED-CHAIN.md) · [#261](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/261)
ROADMAP.md-193-- **GH-266 · rtl_worktree_end doesn't exempt relay-system/ (its own transcript dir) — false containment violation discards a fully in-scope turn** ✅ **SHIPPED — closed 2026-07-22 (PR #271, merge 2a2da17)** — the worktree-isolation containment path (`rtl_worktree_end`) had no exemption for the harness's own `relay-system/` transcript directory, unlike `.tick/` (explicitly exempted) and unlike the non-worktree `rtl_check()` path (exempts `$RTL_LOG_REL` directly). A fully in-scope Codex build turn was discarded every time the isolated worktree's own transcript log landed under `relay-system/`. Adjacent to #30 (XYZ_ARCHIVE_ROOT redirect — complementary, not a substitute) and #160 (closed, different false-positive mechanism). Shared an edit surface with #261 (`relay-turn-lib.sh`) — fixed together. cx/risk/eff 2/4/2. → [GH-266-WORKTREE-RELAYSYSTEM-CONTAINMENT.md](PROJECT/3-COMPLETED/GH-266-WORKTREE-RELAYSYSTEM-CONTAINMENT.md) · [#266](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/266)

2026-08-18T16:08:20.164481Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "sed -n '1,220p' PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md
sed -n '625,778p' PROJECT/PDDA.md
sed -n '645,815p' utils/pdda/pdda.sh
rg -n -C 3 'pdda_parse_release|parse_release|RELEASES' utils/pdda/pdda-lib.sh" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4
 succeeded in 0ms:
---
gh_issue: 28
source: https://github.com/HiQS-Suite/XYZ-forge/issues/28
title: "RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue"
status: Proposed (1-INBOX — not yet active)
created: 2026-08-18
doc_type: feedback
effort: 2
complexity: 2
risk: 1
phases: 2
---

# GH-28: RELEASES.md Ledger Discipline

## Context & Purpose

`RELEASES.md` is contracted to be ~90% pointers/manifest (`PROJECT/PDDA.md` → "RELEASES.md — release
ledger"), with a narrative discipline rubric already living in `skills/releases/SKILL.md`
("Discipline and abuse warnings" — Description ≤4 sentences, Manifest ≤7 issues, no execution-history
prose). In practice the ledger keeps ballooning anyway: status appendices, run logs, and dated notes
get written directly into `Description:`/`Exit criterion:`/`Manifest:` fields.

**Concrete instance (Ballast 0.7.0, 2026-08-17):** a long "BUILT 2026-08-17" status appendix was added
directly to the `Exit criterion:` field mid-release-gate-work — exactly the violation the skill already
warns against.

## Root cause (two gaps, not one)

1. **No enforcement teeth.** The discipline rubric only fires when someone explicitly runs
   `/releases clean`. The deterministic checker (`check_releases()` in `utils/pdda/pdda.sh`) validates
   structure only (version present, date format, QA yes/no fields) and is deliberately warn-only by
   design — it never blocks, per `PROJECT/PDDA.md` section J.
2. **No other legitimate home for release-level notes.** Manifest members each get their own GH issue;
   the release ledger entry itself (e.g. "Ballast 0.7.0") has none, so status/run-log notes go inline
   in `RELEASES.md` by necessity.

## Validation scan (2026-08-18, ad-hoc, against live RELEASES.md)

Ran the proposed checks against all 7 real blocks before writing any code:

| Release | Description >4 sentences | Manifest-Members >7 tokens | Exit criterion length |
|---|---|---|---|
| 0.1.0 Quicksilver | clean | — (no field) | clean |
| 0.2.0 Litmus | clean | — | 592 chars / 6 sentences |
| 0.3.0 Nightwatch | 6 sentences | — | 2007 chars / 9 sentences |
| 0.4.0 Plumbline | 5 sentences | — | clean |
| 0.5.0 Lantern | 5 sentences | — | 1544 chars / 6 sentences |
| 0.6.0 Meter | 17 sentences | 2 (clean) | 2718 chars / 10 sentences |
| 0.7.0 Ballast | clean | 4 (clean) | 2470 chars / 10 sentences |
| 0.8.0 (next) | 11 sentences | — | clean |

Two findings that changed the plan:

- **Manifest size is not the problem.** Only two blocks (0.6.0, 0.7.0) even use `Manifest-Members:`,
  and both are clean. The real bloat is entirely in `Description:` and `Exit criterion:`, and it's
  near-universal — 6 of 8 blocks trip the Description check, not just Ballast.
- **"Spans multiple lines" is the wrong signal.** Every field in the file is one long wrapped physical
  line, never literally multi-line — a line-count check would catch nothing. Replaced with a
  sentence-count threshold on `Exit criterion:` (mirroring the existing Description rule): clean
  blocks sit at 0-592 chars, bloated ones start at 1544+ chars / 6+ sentences.

## Revised proposed fix (lightest viable — no new skill, no new scanner binary)

1. Add a `Tracking Issue:` field to the `RELEASES.md` block spec (`PROJECT/PDDA.md` contract +
   `skills/releases/SKILL.md`'s plan-subroutine template). Extends the existing Issue-first SOP
   (`PROJECT/PDDA.md` → "GitHub issue intake") to the release ledger itself. Release-level status/run-log
   notes go there, not inline in the ledger.
2. Extend `check_releases()` in `utils/pdda/pdda.sh` with deterministic bloat checks:
   - `Description:` exceeding 4 sentences (validated signal, confirmed above)
   - `Exit criterion:` exceeding 4 sentences (replaces the multi-line check — validated to actually
     catch the observed bloat)
   - `Manifest-Members:` exceeding 7 tokens (kept for when the field is used; low incidence today but
     cheap to check)
   Same line-based-check style already used in that function — no LLM needed for detection.
3. Ship the new checks **warn-only first**. Run once against live `RELEASES.md`, confirm the hit list
   matches this scan, then flip to blocking in a follow-up commit — only after existing bloated blocks
   (6 of 8) are cleaned up or grandfathered, so the feature doesn't land immediately red against its
   own repo.
4. `/releases clean`'s existing LLM rubric remains the fix-up drafting tool once a violation is
   flagged by (2) — never the detector. Matches this repo's deterministic-before-LLM constitution rule.

## Sequencing

Queued as a **post-Ballast 0.7.0 follow-up** — not a Ballast manifest member, no dependency on the
in-flight release-gate run.

---

## Acceptance Criteria
- [ ] `Tracking Issue:` field documented in `PROJECT/PDDA.md`'s RELEASES.md contract and
      `skills/releases/SKILL.md`'s plan-subroutine template.
- [ ] `check_releases()` flags Description/Exit-criterion/Manifest-Members bloat deterministically,
      with a registered regression test.
- [ ] New checks ship warn-only first; existing bloated blocks (6 of 8, per the validation scan above)
      are cleaned up or explicitly grandfathered before flipping to blocking.
- [ ] `skills/releases/SKILL.md`'s discipline section cross-references the new field/checks instead of
      relying solely on manual `/releases clean` invocation.
#### RELEASES.md — release ledger

**`RELEASES.md` is an optional planning aid.** It is not a required artifact, not a checklist, and
not something to keep topped up. An empty file, a stale file, or no file at all are all valid
states — `pdda.sh releases` skips a missing file entirely ("RELEASES.md not found — nothing to
check") and never blocks, even in `full` mode.

**Do not proactively offer to fill it in, populate it, bring it current, or add a release that has
already shipped. Do not treat a sparse file as an incomplete one.** Edit it only when an operator
explicitly asks for release *planning*.

That instruction is aimed at the reader who is likeliest to erode this file, which is increasingly
an LLM maintainer. The failure mode is not one bad decision; it is a long series of individually
reasonable offers to help — "want me to add the release you just shipped?" — that in aggregate turn
a planning aid into a second, hand-maintained history of what shipped. Two sources of truth for the
same fact is the defect, and it arrives one helpful suggestion at a time. `CHANGELOG.md` is the
history. This file is not.

What it *is*: a first-class root file, like `ROADMAP.md`/`CHANGELOG.md` — a single forward-looking
planning ledger for major releases, not a lifecycle bucket of per-tag docs. Marathon plans and other
forward planning cross-reference it for target release names/dates.

**The admission rule.** A block earns its place by being worth *planning toward* — a named arc with
a theme, usually carrying a target date and a milestone. If the only thing that can go in
`Description:` is a restatement of what changed, it belongs in `CHANGELOG.md` and nowhere else.
Everything below the threshold goes in an `Iterations:` band (see the field docs) rather than getting
its own block.

The test is the theme, not the paperwork: `Target Date:` and `Milestone:` are optional fields and
their absence never disqualifies a block. A release can be worth planning toward before anyone knows
when it lands.

Format — one flat `Label: value` block per release, blank line between blocks (blank lines are
just visual spacing; a new block starts at the next `Release:` line). Field order is not parsed and
every field except `Release:` is optional, so a real block is usually shorter than this:

```text
Release: 1.0.0
Iterations: 1.0.0-1.0.4
Status: Draft
Target Date: 2026-07-31
Codename: n/a
Milestone:
Description:
Exit criterion:
Manifest:
GH_URL:
Front-door reviewed:
Shakedown reviewed:
License file:
```

Fields:
- `Release:` (required) — the version being planned
- `Status:` (optional) — free-text, unvalidated by design (`Draft`, `Working`, `Shipped`, whatever
  an operator finds useful). **`Status: Shipped` is the sole "already shipped" signal** — both
  `pdda.sh releases`'s overdue nudge and `pdda.sh releases-current`'s "in progress" filter key off
  it exclusively. This is a rough signal, not a gated lifecycle — no fixed vocabulary is enforced.
- `Iterations:` (optional) — a **reserved band of version numbers**, written `<lo>-<hi>` (e.g.
  `0.2.0-0.2.4`). Versions inside a band ship freely and are recorded in `CHANGELOG.md` only; they
  **never get a block here**, and the band deliberately does not enumerate them. Absence of the
  field means no band is reserved.

  **The band's owner is the one exception.** A band is written on the block it belongs to, and that
  block's own `Release:` is the band's `<lo>` — so the owner sits inside its own band and keeps its
  block. Every *other* version in the range is covered by the band and gets none. `pdda.sh releases`
  identifies the owner by line, not by version text, so a second block that merely repeats the
  owner's version is still caught as the duplicate it is.

  This is what gives the admission rule an answer instead of an argument. "Where does 0.2.3 go?"
  resolved case-by-case is resolved by adding a row, every time; with a band it has a written
  answer, and `pdda.sh releases` can check it — a version inside an existing band is already
  accounted for, so a block for it is by definition a duplicate. That is testable in a way "is this
  release meaningful?" never will be.

  **When a band is exhausted** — `0.2.5` is needed and the band ends at `0.2.4` — **widen the band.
  Do not start enumerating, and do not add a block.** Promote to the next release only when the work
  genuinely became a new arc with its own theme, never merely because the numbers ran out; a version
  number driven by an accounting artifact is the convention rotting rather than holding.

  Rejected alternative, recorded so it isn't re-proposed: persisting `Iteration 1:` … `Iteration 5:`
  labels per release. That is 20–25 named rows across a five-release horizon, each an invitation to
  fill in what shipped — the same drift, arriving as structure instead of as appended blocks. One
  optional field beats five required ones.
- `Target Date:` (optional) — `YYYY-MM-DD`; `pdda.sh releases` warns once this passes and `Status`
  doesn't read `Shipped`
- `Codename:` (optional) — `n/a` is fine
- `Milestone:` (optional) — free-text, unvalidated, the **release → issue-set join key**. It holds a
  GitHub milestone *title*, so a release's scope can be queried rather than hand-maintained here:

  ```bash
  gh issue list --milestone "Quicksilver" --state open --json number,title,labels
  ```

  That query *is* release-driven work selection, with no second cache and no issue list copied into
  this file — which is why the field is worth having and why it stays a pointer. Unvalidated for the
  same reason as `Status:`: checking a title against GitHub would need a `gh` call, and this check is
  deliberately network-free. **Not warned on when absent** — a release with no milestone is a normal
  state, and a nudge here would recreate exactly the fill-it-in pressure this section exists to stop.
- `Description:` (optional) — a concise one-to-four-sentence statement of the release theme. It is
  not a run log, implementation plan, or second changelog; historical outcomes stay in
  `CHANGELOG.md` and execution detail stays in the canonical `PROJECT/**` document. `/releases`
  warns when this field exceeds four sentences or becomes multi-paragraph history.
- `Exit criterion:` (optional) — one runnable command or observable condition that proves the arc
  reached its goal. Keep the implementation and phased QA plan in `PROJECT/**`; this field is the
  release-level goalpost only.
- `Manifest:` (optional) — a concise, fixed release boundary, normally a dated `FROZEN` list of
  issue IDs. Prefer `Milestone:` when the intent is a live issue-set query. `/releases` triggers an
  ambition review above seven named issues and when the list mixes themes, grows without a dated
  re-scope, or lacks an exit criterion; the count is advisory, never an automatic rejection.
- `GH_URL:` (optional) — populated once *a* GitHub Release object exists, including a draft (see
  `/releases publish`). **This means "a Release object exists," not "shipped"** — a draft's
  `GH_URL` is real but the release isn't out. Flip `Status: Shipped` yourself (or let
  `/releases publish` do it on an actual, non-draft publish) when it's really out; `GH_URL` alone
  no longer implies that.
- `Front-door reviewed:` / `Shakedown reviewed:` / `License file:` (optional) — pre-release QA-gate
  checkboxes: has the `/front-door` onboarding audit run, has the `/shakedown` script-path audit
  run, is a `LICENSE` file present. `Yes` or `No`; `pdda.sh releases` warns on any other non-blank
  value. A blank value just means not yet answered, not a failure.

Add new fields only when a real need shows up. This format intentionally started smaller than the
earlier per-tag-doc convention (status lifecycle, linked marathons, linked issues, a GitHub
release-tag cache) — that was more data than was practical to keep current for an initial release.
`Status:` is the first field added back in, deliberately kept unvalidated (baby steps, not a new
gated lifecycle) rather than reintroducing the old rigid `Draft → RC → Published` enum. The three
QA-gate fields are the second: a real pre-release checklist need (open-sourcing a release means a
front-door pass, a shakedown pass, and a `LICENSE` file all need to be true before shipping) that,
unlike `Status`, has an unambiguous right answer — so they're validated `Yes`/`No` rather than free-text.
`Iterations:` and `Milestone:` are the third pair, and both are additive: the parser ignores labels
it doesn't know, absence means "not reserved" / "no milestone", and neither produces a finding in a
ledger that has never used them. A repo can adopt them, or never hear of them, with no migration.

One repo-owned skill operates on this file: `/releases`. It is a read-first router that synthesizes
the ledger, checks evidence-backed contradictions against `CHANGELOG.md`, reachable commits, merged
PRs, and GitHub Releases when available, then enters cleanup, author/update, historical-anchor, or
publish subroutines only on an explicit operator request. Every mutation and public release is
previewed and confirmation-gated. Its strategic-drift handoff is `/radar`; its frozen path-to-ship
handoff is `/finish-line`. It recommends either only when that distinct goal matches and never
duplicates or auto-invokes their workflows.

Invocation is operator-triggered by design. The initial synthesis may report contradictions in an
existing ledger, but it must never treat an absent, sparse, or merely old file as unfinished work or
offer to top it up. A skill that exists to keep this file populated is the most efficient possible
way to violate the optionality rule at the top of this section.

#### `pdda.sh releases-current`

Read-only roll-up (not part of `PDDA_DETERMINISTIC_CHECKS` — emits no findings, never gates): lists
every `RELEASES.md` entry whose `Status` is empty or not exactly `Shipped`. A rough, non-authoritative
answer to "what's currently in progress" — for a human, or for another repo's tooling (e.g. the XYZ
sibling harness) to shell out to instead of re-implementing `RELEASES.md` parsing itself. Because
`Status` is free-text, this is a best-effort filter, not a guarantee — an entry with a typo'd or
unconventional `Status` value still shows up (safer default: never silently hide something that
lacks an explicit `Shipped` signal).
# ------------------------------------------------------------------------------------------------
# J. releases (warn-only nudge; never blocks, even in full)
# ------------------------------------------------------------------------------------------------
# Validates RELEASES.md, the single forward-looking release-planning ledger (see PROJECT/PDDA.md
# "RELEASES.md — release ledger"). Deliberately light: this replaced a heavier per-tag-doc lifecycle
# (status Draft/RC/Published, linked marathons, linked issues, a GitHub release-tag cache) that
# proved like too much data to keep current for an initial release. Grows only as real need shows up.
#   (1) error — a "Release:" block has an empty version
#   (2) warn  — Target Date is set but not a valid YYYY-MM-DD date
#   (3) warn  — Target Date has passed and GH_URL is still empty (looks overdue/unshipped)
#   (4) warn  — Iterations is set but isn't a well-formed "<lo>-<hi>" version band
#   (5) warn  — a block's version falls inside another block's reserved Iterations band
check_releases() {
  pdda_reset_counts
  local CHECK_NAME="pdda-check-releases" rc=0
  local RELEASES_FILE_EFF="${PDDA_RELEASES_FILE:-$PDDA_REPO_ROOT/RELEASES.md}"
  local release status target_date codename description gh_url line_no target_epoch today_epoch
  local status_lc front_door shakedown license_file qa_field qa_label qa_value qa_value_lc
  local iterations milestone rows bands="" band_release band_lo band_hi band_line release_trimmed

  if [ ! -f "$RELEASES_FILE_EFF" ]; then
    pdda_record_finding info "$CHECK_NAME" "$RELEASES_FILE_EFF" 0 \
      "RELEASES.md not found — nothing to check" "skip"
    pdda_emit_summary "$CHECK_NAME" 0
    return "$(pdda_gated_exit 0)"
  fi

  # A ledger with no blocks at all (header-only, or empty) is a VALID state under this contract —
  # sparse is fine — so it reports exactly as clean as it did before this field pair existed. The
  # guard exists because the here-doc loops below would otherwise see one empty line and fake a
  # "block near line 0 has no version" error; it deliberately records NO finding of its own.
  rows="$(pdda_releases_list "$RELEASES_FILE_EFF")"
  if [ -z "$rows" ]; then
    pdda_emit_summary "$CHECK_NAME" 0
    return "$(pdda_gated_exit 0)"
  fi

  # Pass 1 — validate each Iterations band and remember the well-formed ones. A band reserves patch
  # numbers that deliberately never get their own block (PROJECT/PDDA.md "RELEASES.md — release
  # ledger"), which is what lets pass 2 test the admission rule mechanically instead of rhetorically.
  while IFS=$'\037' read -r release status target_date codename description gh_url \
    front_door shakedown license_file iterations milestone line_no; do
    iterations="$(pdda_trim "$iterations")"
    [ -n "$iterations" ] || continue
    if pdda_is_iteration_band "$iterations"; then
      bands="${bands}${release}"$'\037'"${iterations%%-*}"$'\037'"${iterations#*-}"$'\037'"${line_no}"$'\n'
    else
      pdda_record_finding warn "$CHECK_NAME" "$RELEASES_FILE_EFF" "$line_no" \
        "release '$release' Iterations '$iterations' is not a valid <lo>-<hi> version band (e.g. 0.2.0-0.2.4)" \
        "fix-iterations-band"
    fi
  done <<EOF
$rows
EOF

  while IFS=$'\037' read -r release status target_date codename description gh_url \
    front_door shakedown license_file iterations milestone line_no; do
    if [ -z "$(pdda_trim "$release")" ]; then
      pdda_record_finding error "$CHECK_NAME" "$RELEASES_FILE_EFF" "$line_no" \
        "a 'Release:' block near line $line_no has no version" "fix-release-value"
      rc=1
      continue
    fi

    # Admission rule, made mechanical: a version inside another block's reserved band is already
    # accounted for by that band, so a second block for it is by definition a duplicate. Only plain
    # dotted-numeric versions are testable this way; anything else is left to human judgment.
    #
    # A band's OWNER is inside its own band by construction (0.2.0 owns 0.2.0-0.2.4), so it must not
    # flag itself. Identity is the block's LINE, not its version text: comparing versions would let a
    # second, genuinely duplicate `Release: 0.2.0` block hide behind the owner's identical value —
    # exactly the case the check exists to catch.
    release_trimmed="$(pdda_trim "$release")"
    if pdda_is_dotted_version "$release_trimmed"; then
      while IFS=$'\037' read -r band_release band_lo band_hi band_line; do
        [ -n "$band_release" ] || continue
        [ "$band_line" != "$line_no" ] || continue
        [ "$(pdda_vercmp "$release_trimmed" "$band_lo")" != "-1" ] || continue
        [ "$(pdda_vercmp "$release_trimmed" "$band_hi")" != "1" ] || continue
        pdda_record_finding warn "$CHECK_NAME" "$RELEASES_FILE_EFF" "$line_no" \
          "release '$release_trimmed' is inside the Iterations band $band_lo-$band_hi reserved by release '$(pdda_trim "$band_release")' (line $band_line) — already accounted for; record it in CHANGELOG.md instead of giving it a block" \
          "in-band-release-block"
      done <<EOF
$bands
EOF
    fi

    # Front-door reviewed / Shakedown reviewed / License file: optional pre-release QA-gate
    # checkboxes, warn-only Yes/No like the rest of this check (see PROJECT/PDDA.md "RELEASES.md
    # — release ledger"). A blank value is fine (not yet answered); only a set-but-invalid value warns.
    for qa_field in "Front-door reviewed:$front_door" "Shakedown reviewed:$shakedown" "License file:$license_file"; do
      qa_label="${qa_field%%:*}"
      qa_value="$(pdda_trim "${qa_field#*:}")"
      [ -n "$qa_value" ] || continue
      qa_value_lc="$(printf '%s' "$qa_value" | tr '[:upper:]' '[:lower:]')"
      case "$qa_value_lc" in
        yes | no) ;;
        *) pdda_record_finding warn "$CHECK_NAME" "$RELEASES_FILE_EFF" "$line_no" \
             "release '$release' $qa_label value '$qa_value' is not exactly Yes or No" "fix-release-yesno-field" ;;
      esac
    done

    [ -n "$target_date" ] || continue

    if ! pdda_is_real_date "$target_date"; then
      pdda_record_finding warn "$CHECK_NAME" "$RELEASES_FILE_EFF" "$line_no" \
        "release '$release' Target Date '$target_date' is not a valid YYYY-MM-DD date" \
        "fix-target-date"
      continue
    fi

    # Status: Shipped is the sole "already shipped" signal (GH_URL only means a Release object
    # exists — draft or published — not that the release is out; see PROJECT/PDDA.md "RELEASES.md
    # — release ledger"). A populated GH_URL alone no longer skips this check.
    status_lc="$(printf '%s' "$(pdda_trim "$status")" | tr '[:upper:]' '[:lower:]')"
    [ "$status_lc" != "shipped" ] || continue

    # _pdda_cl_epoch is the changelog check's date->epoch helper, portable BSD/GNU; reused here
    # rather than duplicating the date-parsing logic for a second date-comparison check.
    target_epoch="$(_pdda_cl_epoch "$target_date")"
    today_epoch="$(_pdda_cl_epoch "$(pdda_today)")"
    if [ -n "$target_epoch" ] && [ -n "$today_epoch" ] && [ "$target_epoch" -lt "$today_epoch" ]; then
      pdda_record_finding warn "$CHECK_NAME" "$RELEASES_FILE_EFF" "$line_no" \
        "release '$release' Target Date '$target_date' has passed and Status isn't Shipped — overdue" \
        "overdue-release"
    fi
  done <<EOF
$rows
EOF

  pdda_emit_summary "$CHECK_NAME" "$rc"
  # Warn-only in spirit — never blocks, even in full mode (see PROJECT/PDDA.md section J). The one
  # error above is a malformed-doc guard, surfaced loudly, but deliberately never gates the exit code.
  return "$(pdda_gated_exit 0)"
}

# ------------------------------------------------------------------------------------------------
# releases-current (read-only roll-up; not part of PDDA_DETERMINISTIC_CHECKS — no findings, no gate)
# ------------------------------------------------------------------------------------------------
# A rough, non-authoritative answer to "what release is in progress right now" — for a human, or for
# another repo's tooling (e.g. the XYZ sibling harness) to shell out to rather than re-implementing
# RELEASES.md parsing itself. Lists every release whose Status is empty or not "Shipped" (Status is
# free-text and unvalidated, so this is a best-effort filter, not a gate — see PROJECT/PDDA.md).
cmd_releases_current() {
  local RELEASES_FILE_EFF="${PDDA_RELEASES_FILE:-$PDDA_REPO_ROOT/RELEASES.md}"
  local release status target_date codename description gh_url line_no status_lc any=0
  local front_door shakedown license_file iterations milestone

  if [ ! -f "$RELEASES_FILE_EFF" ]; then
    printf '%s not found — nothing to report\n' "$(pdda_relpath "$RELEASES_FILE_EFF")"
    return 0
  fi

  printf 'PDDA releases-current — in-progress entries in %s\n' "$(pdda_relpath "$RELEASES_FILE_EFF")"
  while IFS=$'\037' read -r release status target_date codename description gh_url \
    front_door shakedown license_file iterations milestone line_no; do
    [ -n "$(pdda_trim "$release")" ] || continue
    status_lc="$(printf '%s' "$(pdda_trim "$status")" | tr '[:upper:]' '[:lower:]')"
    [ "$status_lc" != "shipped" ] || continue

    any=1
    printf '\n• %s' "$release"
    [ -n "$codename" ] && printf ' (%s)' "$codename"
    printf ' — %s\n' "${status:-no Status set}"
    [ -n "$iterations" ] && printf '    Iterations: %s (reserved; these ship without their own block)\n' "$iterations"
    [ -n "$target_date" ] && printf '    Target Date: %s\n' "$target_date"
    [ -n "$milestone" ] && printf '    Milestone: %s\n' "$milestone"
    [ -n "$description" ] && printf '    %s\n' "$description"
    [ -n "$gh_url" ] && printf '    %s\n' "$gh_url"
  done < <(pdda_releases_list "$RELEASES_FILE_EFF")

9-PDDA_COMPLETED_DIR="${PDDA_COMPLETED_DIR:-$PDDA_REPO_ROOT/PROJECT/3-COMPLETED}"
10-PDDA_MISC_DIR="${PDDA_MISC_DIR:-$PDDA_REPO_ROOT/PROJECT/4-MISC}"
11-# Forward-looking release-planning ledger — a single root file (like ROADMAP.md/CHANGELOG.md), not
12:# a lifecycle bucket of per-tag docs. See PROJECT/PDDA.md "RELEASES.md — release ledger".
13:PDDA_RELEASES_FILE="${PDDA_RELEASES_FILE:-$PDDA_REPO_ROOT/RELEASES.md}"
14-PDDA_ACTIVITY_LOG="${PDDA_ACTIVITY_LOG:-$PDDA_REPO_ROOT/PROJECT/PDDA-ACTIVITY.jsonl}"
15-# Cached GitHub issue-state file (TSV: "<number>\t<STATE>", '#'-comment lines ignored). Written by
16-# pdda-gh-refresh.sh; read by `pdda.sh issue-doc-sync` when gh is absent/offline. Gitignored runtime
--
445-  mv "$tmp" "$PDDA_GH_STATE_CACHE" 2>/dev/null || { rm -f "$tmp"; return 1; }
446-}
447-
448:# --- RELEASES.md helpers -------------------------------------------------------------------------
449:# RELEASES.md is a single forward-looking planning ledger (like ROADMAP.md/CHANGELOG.md), not a
450:# bucket of per-tag docs — see PROJECT/PDDA.md "RELEASES.md — release ledger". Each release is a
451-# flat "Label: value" block; a block starts at a line matching ^Release: and runs until the next
452-# such line or EOF (blank lines between blocks are just visual spacing, not parsed).
453-
--
473-# release's scope can be queried (`gh issue list --milestone "<title>"`) instead of hand-listed here.
474-# `Front-door reviewed:`/`Shakedown reviewed:`/`License file:` are optional Yes/No QA-gate fields,
475-# and `Iterations:` is an optional reserved version band (`pdda.sh releases` warns on a malformed
476:# value for either). See PROJECT/PDDA.md "RELEASES.md — release ledger".
477-pdda_releases_list() {
478-  local file="$1"
479-  [ -f "$file" ] || return 0
--
530-# True if the value is a well-formed reserved-iteration band: exactly "<lo>-<hi>", both plain
531-# dotted-numeric versions, lo <= hi. Strict on purpose — a band is only useful if the containment
532-# test in `pdda.sh releases` can be trusted, so anything ambiguous (a prerelease hyphen, a reversed
533:# range) warns rather than being silently half-parsed. See PROJECT/PDDA.md "RELEASES.md — release
534-# ledger" → `Iterations:`.
535-pdda_is_iteration_band() {
536-  local band="$1" lo hi

2026-08-18T16:08:25.697125Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "sed -n '448,530p' utils/pdda/pdda-lib.sh
sed -n '1,260p' RELEASES.md
rg -n -C 3 'pdda.*releases|releases.*pdda|gh284-p3|Manifest-Members|Tracking Issue|Exit criterion' test utils skills PROJECT -g '*.sh' -g '*.md' | head -n 900" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4
 succeeded in 0ms:
# --- RELEASES.md helpers -------------------------------------------------------------------------
# RELEASES.md is a single forward-looking planning ledger (like ROADMAP.md/CHANGELOG.md), not a
# bucket of per-tag docs — see PROJECT/PDDA.md "RELEASES.md — release ledger". Each release is a
# flat "Label: value" block; a block starts at a line matching ^Release: and runs until the next
# such line or EOF (blank lines between blocks are just visual spacing, not parsed).

# List releases as rows of
#   <release><US><status><US><target_date><US><codename><US><description><US><gh_url><US>
#   <front_door><US><shakedown><US><license_file><US><iterations><US><milestone><US><line>
# (US = ASCII unit separator 0x1F, not tab — bash's `read` collapses empty fields around literal
# tabs since tab counts as "IFS whitespace" regardless of IFS's contents, which would silently
# misalign every block with a blank Description/GH_URL, i.e. the common case here). One row per
# block, in file order. Prints nothing (silently) if the file doesn't exist.
#
# THIS ROW SHAPE IS INTERNAL, AND ADDING A FIELD IS A BREAKING CHANGE. Callers read it positionally
# with `read -r`, and there is no position that is safe to extend: a new field before <line> shifts
# <line> onto the wrong variable, and one after it makes bash's last-variable-absorbs-the-rest rule
# fold the extras into <line>. So <line> stays last as a record terminator, and every reader must be
# updated in the SAME change — `check_releases` and `cmd_releases_current` are the only two, and
# test/pdda-releases-iterations.sh pins the field count so a future addition can't drift silently.
# The stable, external surface for other tooling is `pdda.sh releases-current`, not this helper.
#
# `Status:` is free-text (Draft/Working/Shipped/... — whatever an operator writes) and unvalidated
# by design: it's a rough, non-authoritative signal for "what's in progress," not a gated lifecycle
# field. `Milestone:` is free-text for the same reason — it carries a GitHub milestone *title* so a
# release's scope can be queried (`gh issue list --milestone "<title>"`) instead of hand-listed here.
# `Front-door reviewed:`/`Shakedown reviewed:`/`License file:` are optional Yes/No QA-gate fields,
# and `Iterations:` is an optional reserved version band (`pdda.sh releases` warns on a malformed
# value for either). See PROJECT/PDDA.md "RELEASES.md — release ledger".
pdda_releases_list() {
  local file="$1"
  [ -f "$file" ] || return 0
  awk '
    function flush() {
      if (has_release) {
        printf "%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%d\n", release, status, target_date, codename, description, gh_url, front_door, shakedown, license_file, iterations, milestone, release_line
      }
      release=""; status=""; target_date=""; codename=""; description=""; gh_url=""
      front_door=""; shakedown=""; license_file=""; iterations=""; milestone=""
      release_line=0; has_release=0
    }
    /^Release:/             { flush(); v=$0; sub(/^Release:[[:space:]]*/, "", v); release=v; has_release=1; release_line=NR; next }
    /^Status:/              { v=$0; sub(/^Status:[[:space:]]*/, "", v); status=v; next }
    /^Iterations:/          { v=$0; sub(/^Iterations:[[:space:]]*/, "", v); iterations=v; next }
    /^Target Date:/         { v=$0; sub(/^Target Date:[[:space:]]*/, "", v); target_date=v; next }
    /^Codename:/             { v=$0; sub(/^Codename:[[:space:]]*/, "", v); codename=v; next }
    /^Milestone:/           { v=$0; sub(/^Milestone:[[:space:]]*/, "", v); milestone=v; next }
    /^Description:/         { v=$0; sub(/^Description:[[:space:]]*/, "", v); description=v; next }
    /^GH_URL:/               { v=$0; sub(/^GH_URL:[[:space:]]*/, "", v); gh_url=v; next }
    /^Front-door reviewed:/ { v=$0; sub(/^Front-door reviewed:[[:space:]]*/, "", v); front_door=v; next }
    /^Shakedown reviewed:/  { v=$0; sub(/^Shakedown reviewed:[[:space:]]*/, "", v); shakedown=v; next }
    /^License file:/        { v=$0; sub(/^License file:[[:space:]]*/, "", v); license_file=v; next }
    END { flush() }
  ' "$file"
}

# Compare two dotted-numeric versions; echoes -1 / 0 / 1 for a<b / a==b / a>b. Missing and
# non-numeric components read as 0. Deliberately NOT a semver implementation — it exists only to
# answer "does this version fall inside a reserved Iterations band", and callers gate it behind
# pdda_is_dotted_version so prerelease/date-shaped values never reach it.
pdda_vercmp() {
  awk -v a="$1" -v b="$2" '
    BEGIN {
      na = split(a, x, "."); nb = split(b, y, ".")
      n = (na > nb ? na : nb)
      for (i = 1; i <= n; i++) {
        ai = (i <= na ? x[i] + 0 : 0); bi = (i <= nb ? y[i] + 0 : 0)
        if (ai < bi) { print -1; exit }
        if (ai > bi) { print  1; exit }
      }
      print 0
    }'
}

# True if the value is a plain dotted-numeric version (1, 1.2, 0.2.14 — not v1.2.3, not 1.0.0-rc1).
pdda_is_dotted_version() {
  case "$1" in
    "" | *[!0-9.]* | .* | *. | *..*) return 1 ;;
  esac
  return 0
}

# True if the value is a well-formed reserved-iteration band: exactly "<lo>-<hi>", both plain
# Major Releases

Forward-looking planning ledger for major releases — one block per release, minimal fields, blank
line between blocks. Marathon plans and other forward planning cross-reference this doc for
target release names/dates; it is not a history of what shipped (that's CHANGELOG.md — lessons
learned belong there at ship time, not duplicated here). Contract lives in PROJECT/PDDA.md ->
"RELEASES.md — release ledger". Add new fields only when a real need shows up.

## This file is OPTIONAL (GH-381)

**Read this before proposing an edit to it.**

`RELEASES.md` is an *optional planning aid*. It is not a required artifact, it is not a checklist,
and it is **not something to keep topped up**. An empty file, a stale file, or no file at all are
all perfectly valid states. The tooling agrees: `pdda.sh releases` is warn-only, never blocks, and
skips entirely when the file is absent — *"RELEASES.md not found — nothing to check."*

**Do not offer to fill this in, populate it, bring it up to date, or add the release you just
shipped.** Do not treat a sparse file as an incomplete one. If nobody is actively planning a release
arc right now, the correct amount of content here is whatever is already present — including
nothing.

Edit it only when an operator explicitly asks for release *planning*. That is the whole trigger.

## Scope boundary — Litmus (0.2.0) vs Nightwatch (0.3.0)

Added 2026-08-08 after a cross-model consult (codex + agy) found the two descriptions **not
decidable**: a competent agent could not route a new issue between them from the prose alone, because
Litmus says checks must "report red" correctly while Nightwatch says hostile states must "fail
clearly." Both advisors independently flagged this as blocking, and the overlap is worst exactly where
orchestration failures emit gate-looking verdicts.

> **Litmus owns faulty decision semantics.** A named acceptance, preflight, reviewer, or pre-advance
> check returns pass, fail, or a *reason* inconsistent with a controlled input's observable outcome —
> or lacks a recorded negative control.
>
> **Nightwatch owns run lifecycle.** Dispatch, target and worktree containment, claims, durable
> logging, interruption, and resume — **even when lifecycle code emits a misleading message.**
>
> **Classify by the violated invariant, not by the wording of the message.** Split an issue that
> violates both.

That last clause is the load-bearing one. The intuitive rule — "a lying message is Litmus" — gives the
wrong answer: #426 exits 6 claiming containment worked while a file leaked, but the invariant it
violates is run containment, so it is Nightwatch, with the assertion of its lie written as a
Litmus-style test. Conversely #407 reports `pre-advance-failed` when no gate ran, and that *is* a
Litmus defect, because the violated invariant is the verdict itself.

**A release is not its milestone.** A milestone is a backlog and grows while you work; a release needs
a frozen manifest and a testable exit criterion, both recorded in the blocks below. "The open issues
are done" is not an exit criterion, because working on a release generates more of them.

## What belongs here, on the occasions it is used

**Major and meaningful releases only. Not every release number.**

A block earns its place by being worth *planning toward* — a named arc with a theme, a target date,
and a milestone. If the only thing you can write in `Description:` is a restatement of what changed,
it belongs in CHANGELOG.md and nowhere else.

`Iterations:` reserves a band of patch numbers for a release. **Reserved, deliberately not
enumerated** — versions inside a band ship freely and are recorded in CHANGELOG.md only. They never
get a block here. The band is what makes "where does 0.2.3 go?" a question with a written answer
instead of one resolved by adding a row.

**A version inside an existing band is already accounted for, so a new block for it is a
duplicate.** That is the admission rule, and it is the only one.

Why this is written down rather than assumed: the failure mode is not a wrong entry, it is a file
that stays correct at every single step while turning into the wrong thing. Add `0.2.1` because it
shipped, add `0.2.2` for symmetry, and this becomes a **de-facto pre-CHANGELOG** — a second,
hand-maintained history that is guaranteed to disagree with the real one the first time someone
updates one and not the other. Two sources of truth for the same fact is the defect; the row count
is only the symptom.

An assistant that keeps asking for this file to be filled produces exactly that outcome, one
helpful suggestion at a time. Hence the section above.

When a band is exhausted, widen it or promote the next release — do not start enumerating.

`Milestone:` is the release -> issue-set join key (GH-284 Phase 3): a GitHub MILESTONE TITLE, not a
URL and not a list of issues. `GH_URL:` can name only one thing, which cannot express a release's
scope. Ask GitHub what is in a release instead of maintaining a list here:

    gh issue list --milestone "Quicksilver" --state open --json number,title,labels

Release: 0.1.0
Iterations: 0.1.0-0.1.4
Status: Shipped
Target Date: 2026-08-01
Codename: Quicksilver
Description: Python-authoritative Tier-A twins. Licensed AGPL-3.0-only (`LICENSE`) with a commercial option (`LICENSE-COMMERCIAL.md`), adopted 2026-07-29 post-ship; the pre-existing conflicting `LICENSE.md` was removed 2026-07-30 (#372).
GH_URL: [GH 308](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/308)
Milestone: Quicksilver
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes

Release: 0.2.0
Iterations: 0.2.0-0.2.4
Status: Shipped
Shipped: 2026-08-14 — RC 2026-08-09 on `development` @ `263816c`, soak window 5 days, re-verified at ship on `86ba3bd5`: `bash test/litmus-release.sh --release-gate` → exit 0, 6/6 complete, 0 false completion claims. **The ship test was the release's own exit command, not an issue-state audit.** Convention settled 2026-08-14: an exit criterion that is MET *is* the definition of done; a release is not held open by issues it never named. Falsification check on the soak window found nothing — every issue filed 08-09 → 08-14 (#485, #491, #499, #503, #504, #509, #510, #514, #518, #520, #521, #522, #523, #525, #527, #528, #533, #534, #536, #539, #540, #542, #544) either shipped inside it or left the exit command green, and the command was re-run on a `development` containing all of those fixes.
Target Date: 2026-09-05
RC evidence: `bash test/litmus-release.sh --release-gate` → `GOALPOST MET — all 6 manifest entries complete` (6/6, 0 remaining, 0 false completion claims). Its own negative control, `--mutate-evidence`, was re-run on the same commit and reports `negative control OBSERVED in both directions (6 pass, 0 fail)` — it detects a stripped declaration, an unregistered gate (the #461 defect), and an invariant violated in either direction. Four of the six issues are CLOSED with per-criterion evidence (#407, #417, #457, #461). **Residual scope, resolved at ship (2026-08-14).** Both entries' gates are registered, green and control-observed — which is what this release's exit criterion measures — but each carried acceptance criteria that did not ship, and an unshipped criterion is not a reason to hold a met goalpost open. **#375 is CLOSED** (this block previously said it remained open; that was stale). **#390's residual is now [#546](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/546), milestoned Meter** — Layer 4's host free-memory floor and packet-driven per-phase overrides, deferred by the source itself at `utils/py/marathon_drive.py:1509` (verbatim: `# Layer 4 (host free-memory floor) and packet-driven per-phase overrides are Phase 2.`). Meter is the right home rather than a parking space: a host floor is a precondition checked before spending, #382 is already a Meter member and its capture doc documents this exact deferral, and #392 is the static counterpart to this runtime one. #546 is **milestone backlog, NOT admitted to Meter's frozen manifest** — it does not make Meter's exit command fail, so "discovery is not admission" applies. #375's shipped three-state `unverifiable` verdict still deliberately contradicts its criteria 1 and 5, because implementing them literally took `relay-self-sufficiency.sh` from 4/0 to 0/4 on a working machine; that is recorded on the issue and is a deliberate deviation, not an omission.
Codename: Litmus
Description: Make the checks capable of failing. Every gate in the Litmus manifest is shown to report red against a real defect, or is explicitly downgraded to advisory — a check never observed failing is not evidence (#419). Ordered first because it is the release that makes the next one measurable. It is also what the self-improvement chain (#431) is blocked on: a Reviewer is a gate, so #419 applies to it, and its qualification gate is currently un-runnable (#428) and has only ever been measured once (#429).
Exit criterion: `bash test/litmus-release.sh --release-gate` exits 0. Red today by design; turning it green is what "done" means. Its own negative control is `--mutate-evidence`, which must detect a stripped declaration and an unregistered gate. NOTE the honest limit, stated in that file: the audit proves registration, declaration shape and the absence of false completion claims. It does NOT prove a control was truly observed, because `gate_inventory.py` reads a declaration authored by the same person who wrote the gate. Recorded execution of each control is deliberately out of scope for this release.
Manifest: FROZEN 2026-08-08 — #375, #390, #407, #417, #457, #461. Six named decision gates, a fixed denominator rather than a percentage. "Every gate" was unshippable prose: `gate_inventory.py` reports 152 of 158 gates with no declared control, and retrofitting them is explicitly out of scope. Adding an entry is a RE-SCOPE, not a bugfix: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission — #457, #460 and #461 were all filed while executing Litmus, which is what an unfrozen boundary looks like.
GH_URL:
Milestone: Litmus
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes

Release: 0.3.0
Iterations: 0.3.0-0.3.4
Status: Shipped
Shipped: 2026-08-14 — RC 2026-08-11 on `development`, soak window 3 days, re-verified at ship on `86ba3bd5`: `bash test/nightwatch-release.sh --release-gate` → exit 0, **manifest 8/8 complete, lifecycle 5 passing / 0 failing / 0 NOT COVERED**. Half B *executes* the lifecycle cases rather than auditing them, so this is a run that killed real children and watched them recover — not a checklist. Falsification check on the soak window found nothing: the exit command was re-run on a `development` that already contains every fix landed 08-11 → 08-14, including GH-314 (the marathon transcript write-set), which is adjacent to this release's subject and was the one worth checking. The hostile-target write-set lifecycle case still passes via `gh514-write-set-trackable.sh`. Open non-manifest issues (#514, #467, #402, #392, #391, #386) do **not** hold this release open — the exit criterion never named them, and a milestone is a backlog, not a goalpost.
Target Date: 2026-10-10
RC evidence: `bash test/nightwatch-release.sh --release-gate` → `GOALPOST MET — all 8 manifest entries complete and every lifecycle case executes green` (manifest 8/8, lifecycle 5 passing / 0 failing / 0 NOT COVERED). Its own negative control, `--mutate-evidence`, reports 34/0 and `negative control OBSERVED in both directions`. Every manifest entry carries a recorded pre-fix control under `test/baselines/`, not an assertion that one happened. **Two entries are honest about their limits and are worth reading before signing off:** #358's Phase 2 is a *disposition* that needs a real CI failure carrying the new instrumentation, and its capture doc forbids pre-committing one — so Phase 1 shipped and Phase 2 is blocked on an observation, not on work; and #354's membership is Phase 1 only, which was delivered by #376/#448 rather than by this release, recorded as such rather than rebuilt. **#426's outcome inverted its own diagnosis:** a factorial control showed the leak survives with worktree isolation OFF, so teardown was exonerated and the real cause was the GH-375 auth pre-flight running with the caller's CWD, outside containment. **Twelve open Nightwatch-milestone issues remain and gate nothing**, per this block's own "a release is not its milestone" rule. **CI-VERIFIED 2026-08-12, and it was not before:** the goalpost was first met on macOS only, and two of the five lifecycle cases (#388, #514) were failing on every ubuntu CI run at the time the RC was recorded — their fixtures stubbed the builder but not the reviewer binary, so `marathon_drive.py`'s probe fail-fasted and the cases never executed the code they assert on. Fixed, and the gate now reports `GOALPOST MET` with `codex` absent from `PATH`, which is the CI condition reproduced locally rather than inferred. Recorded here because it is exactly the class of thing this release exists to catch: a green result that was green about the wrong environment. The general defect is #520; the control is `test/baselines/GH-520-negative-control.md`.
Post RC update: **#358 Phase 1 is in Nightwatch. Phase 2 is deferred to the Lantern build.** Operator decision, 2026-08-11, recorded here rather than left implicit in an issue thread. Phase 1 — the lock instrumentation — shipped and is counted in the RC evidence above; the manifest below is unchanged and this release does not wait on Phase 2. Phase 2 is the *disposition*, which needs a real CI failure carrying that instrumentation, and it belongs to Lantern because what it produces is a failure that states its own reason — Lantern's whole subject — not a lifecycle invariant. **#358 keeps its Nightwatch milestone**, because it is a frozen manifest entry counted in this block's evidence and re-milestoning it to tidy a join key would falsify a frozen boundary. Only the scope moved.
Codename: Nightwatch
Description: An unattended marathon against a real target repo survives, records, and recovers. Before dispatching work, it proves the target can accept the harness write-set and preserves the local-state contract, so hostile ignore rules or linked worktrees fail clearly rather than silently splitting, leaking, or losing the run. GH-354 Phase 1 is an early Nightwatch containment prerequisite: restore clone-wide driver exclusion for linked worktrees and prove all driver pairs fail closed. A run interrupted, killed at its cap, or panicking the host leaves a durable record and recovery path instead of a clean tree full of ungated commits. Depends on Litmus. The same durability work is what makes a reflection corpus trustworthy (#431): a run with no record is invisible to any later pass over it, and the loop's own evidence has never survived a reboot (#430).
Exit criterion: `bash test/nightwatch-release.sh --release-gate` exits 0. **BUILT 2026-08-11 and red by design**, exactly as Litmus's was; turning it green is what "done" means. It has two halves because a metadata audit cannot answer this release's question. Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), and has a RECORDED control under `test/baselines/`; it also cross-checks that this list and the `Manifest:` line below agree, since a boundary that disagrees with itself is not frozen. Half B **executes** the lifecycle cases rather than auditing them, delegating to the suites that already drive real children and kill them rather than growing a second driver fixture here. Status on 2026-08-11: **manifest 8/8 complete; lifecycle 5 passing, 0 NOT COVERED — GOALPOST MET.** The last gap was the hostile-target write-set case, closed by #514, which was filed while executing this release and deliberately NOT admitted to the manifest (discovery is not admission); it belongs to the lifecycle list because the exit criterion always named that case — what was missing was a suite driving it. That lane also corrected its own premise: the pre-fix tree does not dispatch a turn first, it dies at the render's `git add` with an unhandled `CalledProcessError` traceback, so the discriminating assertion is the absence of that traceback rather than the absence of a dispatch. Its own negative control is `--mutate-evidence` (34/0), which unregisters a gate and deletes a recorded control in a fixture copy, requires both to be detected, and re-checks the unmutated inputs green in the same run so an always-red detector cannot pass for one. Honest limit, inherited from Litmus: Half A reads a declaration and a filename and cannot know a recorded control was honestly recorded; Half B is what narrows that, and is why this criterion is a command that kills children rather than a checklist.
Manifest: FROZEN 2026-08-11 — #408, #409, #426, #388, #387, #384, #358, plus #354 Phase 1. Eight named entries, a fixed denominator rather than a percentage. The first six were moved out of Litmus on 2026-08-08 after a codex+agy consult; #387 and #384 are added at freeze time because the exit criterion above already names their cases — it requires a cap-killed child and a restarted recovery, and nothing else in the milestone supplies either. **The milestone is not the manifest.** Nightwatch's milestone holds 18 open issues; the twelve not listed here (#376, #378, #379, #380, #382, #386, #391, #392, #402, #467, #491, and anything filed during execution) are backlog worked inside the 0.3.0-0.3.4 band, and none of them gates the release. **AMENDED 2026-08-11:** five of those — #378, #379, #380, #382, #491 — were re-milestoned to Meter (0.6.0) at the operator's instruction, so they are no longer Nightwatch backlog at all. The manifest above is untouched and the RC evidence stands; what changed is only the non-gating remainder. #358 stays milestoned here because it is a frozen manifest entry whose Phase 1 shipped and is counted in the RC evidence above — only its *Phase 2* moved, and it moved to **Lantern**, not Meter (see the Post RC update line above). Adding an entry is a RE-SCOPE, not a bugfix, under the same admission rule Litmus used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission.
GH_URL:
Milestone: Nightwatch
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes

Release: 0.4.0
Iterations: 0.4.0-0.4.4
Status: Draft
Target Date: 2026-11-14
Codename: Plumbline
Description: Assisted reflection and a bounded self-improvement loop, measured before either is trusted. The reflection pipeline turns durable Nightwatch records into proposals (`proposals-sink.sh` gains its first production caller) and is graded against external ground truth — the 49 human-filed findings from the two rebalance-OS marathons (#405/#406) — for recall and precision. Ships a committed benchmark and a recorded go/no-go; "not worth automating yet" is a passing result, per #431's own Phase 2 exit criterion. Operator sign-off stays manual. Depends on Nightwatch.
GH_URL: [GH 431](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/431)
Milestone: Plumbline
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes

Release: 0.5.0
Iterations: 0.5.0-0.5.4
Status: Draft
Target Date: 2026-12-12
Codename: Lantern
Description: When the harness fails, the information needed to act already exists inside it — make it say so. Not "add checks": every case was already detected, and some were then described wrongly (a stack trace, a fabricated path, a success exit code, silence). Scope is one epic, deliberately narrow, and deliberately NOT Nightwatch: that milestone owns run lifecycle "even when lifecycle code emits a misleading message" (see the scope boundary above), and none of Lantern's cases violates a lifecycle invariant — they violate the legibility of a failure whose lifecycle handling was already correct. All four members were found in one afternoon during Nightwatch wave 3, which halted three times at zero paid-turn cost; each halt was avoidable from information the system already held. Depends on nothing; independent of Plumbline.
Exit criterion: `bash test/lantern-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it precedes fixing any member, which is the Litmus and Nightwatch ordering and the reason both releases could tell a finished entry from a claimed one. Two halves, the established shape: Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below. Half B **executes** #499's four phases rather than auditing them, since every one of them is a message an operator either receives or does not: a `relay-drive` launch preflight that refuses before spending, a gate refusal that states its real reason, a launcher exit code that survives its wrapper, and a change-impact report. **#358 Phase 2 is the one member with no executable half, and the criterion is written around that rather than pretending otherwise:** it is satisfied by a RECORDED transcript of a real CI failure under `test/baselines/`, and it must NOT be satisfiable by a disposition written in advance — that issue's own capture doc forbids pre-committing one, and an exit criterion that accepted a pre-written verdict would launder exactly the thing #419 exists to prevent. Its own negative control is `--mutate-evidence`, which must unregister a gate, delete a recorded control, and substitute a pre-dated disposition for a real transcript — detecting all three, and re-checking the unmutated inputs green in the same run so an always-red detector cannot pass for one.
Manifest: FROZEN at one issue on creation — #499, which supersedes and closes #494, #495, #496 and #498. Four phases, each shippable alone: relay-drive launch preflight; a gate refusal that states its real reason; a launcher whose exit code survives plus a gate-readiness check; and a change-impact reporter. Freezing at one is the whole point — these were filed as four and unified precisely to stop a single coherent change spreading across four PRs. **RE-FROZEN AT TWO on 2026-08-11 by explicit operator decision — #499, plus #358 Phase 2.** Recorded as a re-scope rather than an edit, because the admission rule below is worthless if a manifest can grow quietly: the operator named the entry and the release, which is the documented way past the rule, and this line says so with a date instead of just showing two items where there was one. It is a genuine fit, not a parking space — Phase 2 is a *disposition* that turns a lost concurrent-append record into a failure naming its own terminal lock state, which is Lantern's subject exactly, whereas the run lifecycle it sits inside was already handled correctly (that is the Nightwatch boundary, and it is why Phase 1 belonged there and Phase 2 does not). It was briefly a Meter member the same day and moved here before either release started; Meter's block records the move from its side. **#358 keeps its Nightwatch milestone** — it is a frozen entry counted in Nightwatch's RC evidence, so only its scope moved, and this is the second Lantern member not enumerable by `gh issue list --milestone Lantern`. Adding a further member is a RE-SCOPE, not a bugfix, per the Litmus rule above.
GH_URL: [GH 499](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/499)
Milestone: not created yet. The original reason — "#499 is unmilestoned by design while Nightwatch is the active goalpost" — expired when Nightwatch reached RC on 2026-08-11, and is kept here only so a reader does not act on it as if current. Creating it is a live decision, not a formality: **neither member would be enumerable by it as things stand** (#499 is unmilestoned, and #358 keeps its Nightwatch milestone deliberately), so the milestone would join nothing until #499 is assigned. The `Manifest:` line below is this release's authoritative scope either way.
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes

Release: 0.6.0
Iterations: 0.6.0-0.6.4
Status: Draft
Target Date: 2026-09-26
Codename: Meter
Description: A run accounts for what it spends and checks what it requires before spending it. Every member was found the same way — a real unattended marathon against `Hypercart-Dev-Tools/rebalance-OS` — and each one costs the operator something no gate ever reports: ten ready lanes blocked by two unrelated pre-existing test failures (#378); a builder killed by a $0.50 budget and escalated as a failed pre-advance gate, its `terminal_reason: budget_exhausted` left in an unreferenced temp file (#379); 108 of the target's own `permissions.allow` grants silently dropped because the directory was never trusted interactively, invisible in preflight, stdout and the escalation alike (#380); a host kernel-panicked under memory pressure while the run's telemetry reported tokens and wall-clock and nothing about memory (#382); and three codex builds plus three agy reviews spent re-running work the driver already had, because the cheap gate-only path exists but nothing points at it and `--retry` silently takes the expensive one (#491). Depends on Nightwatch — #382's numbers need a durable place to land, which is exactly what Nightwatch built. Independent of Plumbline and Lantern.
**RE-SCOPED 2026-08-15 by explicit operator decision — Meter is now the public-repository release candidate, and the paragraph above describes what Meter *was*.** The new sentence is: **XYZ can be handed to a stranger.** An unauthenticated clone reaches a documented entry path and exercises a supported happy path with no private context, from a tree that has been sanitized and secret-scanned. The metering work was not abandoned and it was not finished — five of its seven entries moved intact to Sundown (0.8.0), where they keep their capture docs, their acceptance criteria and their evidence. Recorded here as a re-scope with a date rather than presented as a release that always meant this, because a codename that quietly changes its subject is the same defect as a manifest that quietly grows. The reason for reusing Meter rather than opening an eighth release is that the operator named it: publication is the next thing that happens to this repository, and a launch release parked behind five unrelated engineering entries would have shipped late for reasons that have nothing to do with whether a stranger can clone it.
Publication target — **the deliverable is a sanitized clone, not this repository.** The public artifact is a new working tree cut from `development`, stripped of runtime state and internal working documents, committed as **fresh history with a single initial commit**, and pushed to **https://github.com/HiQS-Suite/XYZ-forge** — a new repository in a different organization, named by the operator on 2026-08-15, which becomes XYZ's permanent home. `CHANGELOG.md` is carried forward verbatim and is the public record of the project's history — it is a *file*, so it survives a fresh-history cut intact, and carrying 2,147 commits was rejected on 2026-08-15 for a stated reason: every document removed during sanitization stays reachable in a carried history, which makes the full-history secret scan this release requires a scan of everything ever deleted rather than a scan of one tree. Fresh history makes the sanitization complete by construction. `.tick/` (161 MB of runtime event state) and `relay-system/` (32 MB of relay transcripts) do not ship. `PROJECT/` ships as an **empty PDDA scaffold** plus the Meter build documents retained deliberately as a worked example of how PDDA is used — the method travels, the backlog does not.
Scope boundary — Meter vs Lantern: **Lantern owns how a failure is described; Meter owns what a run consumed and what it required.** Route by asking whether the issue names a *resource or a precondition* — dollars, turns, memory, swap, a trusted directory, a green suite — or names *the wording of a verdict whose handling was already correct*. Written down because two members straddle it and the file already has one recorded case (Litmus vs Nightwatch, 2026-08-08) of two descriptions that a competent agent could not route between. **#379 is split by that rule and belongs to both:** the overloaded exit 5 is a Lantern-shaped naming defect, the budget itself is a Meter resource, and the scope boundary above says to split an issue that violates both rather than argue it into one. **#491 is the marginal call and is placed here deliberately** — the re-scoped defect is a help-text and discoverability gap, which reads Lantern, but the invariant it violates is that the harness re-spends paid turns whose results it already holds, and the issue's evidence is a cost measurement.
Exit criterion: `bash test/meter-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it is Meter's first task, before any member is fixed — that ordering is the Litmus and Nightwatch precedent, and it is the whole reason both releases could tell a finished entry from a claimed one. Two halves, same shape as Nightwatch's: Half A audits the frozen manifest (each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below) and Half B EXECUTES the cases rather than auditing them — a run against a red-suite target proceeds under a recorded baseline and halts on a *new* failure; a budget-exhausted builder is escalated as budget-exhausted rather than pre-advance-failed; an untrusted target is reported before the first paid turn rather than after; a phase boundary records memory and swap; and a re-fire of an already-satisfied phase runs only the gate and says so. Its own negative control is `--mutate-evidence`, which must unregister a gate and delete a recorded control in a fixture copy, detect both, and re-check the unmutated inputs green in the same run. **RE-SCOPED 2026-08-15 with the release.** The command is unchanged and the two-half shape is unchanged — that shape is the reason Litmus and Nightwatch could tell a finished entry from a claimed one, and it is retained deliberately. What changed is what the halves measure, because a gate that audits a manifest which no longer exists is not a gate. **Half A audits the launch artifact**: the sanitized clone exists at the declared path and is a repository with exactly one commit; `CHANGELOG.md` is present and byte-identical to this repository's; `.tick/`, `relay-system/` and `temp/` are absent; `PROJECT/` contains the PDDA scaffold and the retained Meter example and nothing else; `LICENSE` and `LICENSE-COMMERCIAL.md` are present and mutually consistent; and the secret scan's recorded result names its tool version and the exact commit it scanned. **Half B EXECUTES the stranger's path rather than auditing it**: a clone taken with no credentials, from the published commit, reaches the documented entry point and completes one supported happy path with no file, token, or environment variable that exists only on the author's machine. Its own negative control, `--mutate-evidence`, is likewise re-pointed: in a fixture copy it must plant a private path in a tracked file, remove `CHANGELOG.md`, and leave a `relay-system/` directory behind, detect all three, and re-check the unmutated inputs green in the same run. **The gate is RED on arrival and is Meter's first task, before any sanitization is performed** — same ordering as the two releases that shipped.
Manifest: FROZEN 2026-08-11 on creation — #378, #379, #380, #382, #491. **RE-SCOPED TO SIX on 2026-08-12 by explicit operator decision: #509 admitted.** **RE-SCOPED TO SIX on 2026-08-14 (second decision the same day): #509 RETIRED as complete.** Its two unchecked criteria are not unfinished work — they are blocked by a LATER deliberate decision, GH-544, which retired hosted CI for the private phase. *"A push cannot cancel a running workflow_dispatch boundary run"* is now vacuously true and permanently unwitnessable: `ci.yml` carries only `workflow_dispatch:`, so no push can start a run, and you cannot control-test an interaction between two triggers when one of them no longer exists. *"A green hosted macOS full run exists for a chosen commit"* cannot be satisfied without spending the Actions minutes #509 existed to stop and #544 formally stopped. GH-544 already records that debt in its own terms and owns the re-arm trigger (the repo goes public), so keeping #509 open under Meter tracked the same gap twice while making the manifest look one item larger than it is. Phases 1-5 shipped. **RE-SCOPED TO SIX on 2026-08-14 by explicit operator decision: #551 admitted, and the target date pulled in from 2027-01-16 to 2026-09-26 in the same decision.** Recorded as a dated re-scope for the third time rather than shown as a list that has always had seven — the admission rule is worthless if a manifest can grow quietly, and it is worth as little if the third growth is the one that stops being announced. #551 is the shared root cause under nine open issues (#272, #310, #329, #365, #395, #504, #548, plus the already-closed #314/#440/#549) in which a resolver that cannot determine its answer returns a plausible default instead of refusing. It is a genuine fit on this block's own routing question — it names a **precondition**, not a description of a failure, so it is Meter and not Lantern — and two of its nine (#380, #491) were already Meter members, which is what surfaced it: they were being worked as separate defects when they are one. **RE-SCOPED TO SEVEN on 2026-08-15 by explicit operator decision: #555 admitted.** Recorded as a dated re-scope for the fourth time. #555 is the release's own exit criterion — the prerequisite for the other six being verifiable — so it ships first. The seven frozen manifest entries are #378, #379, #380, #382, #491, #551, and #555. **The date moved because Nightwatch shipped.** This release's only dependency was Nightwatch (#382's numbers needed a durable place to land), that shipped 2026-08-14, and Meter has been unblocked since — January was a date set while its blocker was still open and never revisited when the blocker cleared. Adding a further member is a RE-SCOPE, not a bugfix, under the unchanged rule below. Recorded as a re-scope with a date rather than shown as a list that has always had six, because the admission rule below is worthless if a manifest can grow quietly. It is a genuine fit, not a parking space: GH-509 is CI minute burn and route correctness — what a run costs and what it checks before spending — which is this release's sentence almost verbatim. The operator named the entry and the release, which is the documented way past the rule. Its plan is `PROJECT/2-WORKING/GH-509-CI-MINUTE-BURN.md`, replanned the same day on the macOS-target reframe and reviewed by agy. All six are milestoned Meter, so the ledger and `gh issue list --milestone Meter` cannot drift apart. **#358 Phase 2 was a member for part of 2026-08-11 and was moved to Lantern by operator decision the same day, before any Meter work began.** Recorded rather than quietly dropped: a frozen manifest whose membership changes without a trace is not frozen, and the honest version of "we got the routing wrong for an afternoon" is a dated line, not a clean list. It was the only entry blocked on an *observation* rather than on work, and the only one with no executable half — both of which now sit in Lantern's exit criterion, which is where the reasoning for them lives. The move is also correct on the boundary this block defines: Phase 2 produces a failure that states its own reason, which is Lantern's subject, not a resource or a precondition. Adding an entry is a RE-SCOPE, not a bugfix, under the same admission rule Litmus and Nightwatch used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission. **RE-SCOPED TO TWO on 2026-08-15 by explicit operator decision — the fifth dated re-scope of this manifest, and the only one that replaces the release's subject rather than extending it.** The seven engineering entries are dissolved. **#380 is CLOSED and shipped under the original scope**; it stays milestoned Meter as delivered work and is not a launch member — retiring a manifest does not un-ship what it produced. **#378, #379, #382, #491 and #551 move intact to Sundown (0.8.0)**, keeping their capture docs, their verbatim acceptance criteria and their milestone history; none of them was dropped, deferred without a home, or quietly closed. **#546 moves with them as Sundown backlog** — it was Meter milestone backlog and never a manifest entry, and it follows the subject it belongs to rather than the codename it happened to sit under. **The two frozen launch entries are #555 and #563.** #555 is the release's own exit criterion, re-pointed by the paragraph above and unchanged in its role: it ships first and it arrives RED. #563 is the launch checklist authored by an external reviewer (Codex Sol High) and covers the release boundary, public onboarding and behavior, the secret and privacy review, and the legal/CI/publication sequence. Freezing at two is the Plumbline precedent (frozen at one on creation) and is deliberate: the checklist was written as one coherent cutover and splitting it across issues is exactly what that precedent exists to prevent. **Scope is CLOSED to further admission by explicit operator instruction on 2026-08-15** — no issue filed after this date joins this manifest, and the standing admission rule below is superseded for this release only, because a launch whose scope can still grow does not have a date. Anything discovered during execution is filed, milestoned Sundown or left unmilestoned, and **waived in writing per #563's rule: a waiver names the failed criterion, the owner, the reason and the follow-up issue — silence is not a waiver.** Two known open items are covered by that rule rather than admitted: **#564** (31 unaudited suites that can reach the caller's clone through an empty fixture path) and **#544**'s re-arm debt (hosted CI fires on nothing while the repository is private, and going public is its own documented trigger). Both bear on publication and neither is a launch member; both need a waiver or a fix before the gate is called green.
Manifest-Members: 555 563
GH_URL: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/563
Milestone: Meter
Front-door reviewed: Yes
Shakedown reviewed: Yes
License file: Yes

Release: 0.7.0
Iterations: 0.7.0-0.7.4
Status: Draft
Target Date: 2026-09-12
Codename: Ballast
Description: Post-launch hardening: **the launched repository holds up under a stranger's first run and an outside contributor's first push.** Every member was found the same way — by pointing the launch machinery at its own published output: the first fresh-clone runs of the public repository produced a different failing set each time (#15), a push gate that does not travel with clones got worse the moment the repo went public (#4), and the kernel's own event log can drop events on the concurrent path the kernel exists to coordinate (#14). Ballast exists because publication moved the failure surface from "our machines" to "everyone else's", and nothing in the shipped tree tests that surface. Builds on Meter's publication; depends on nothing unshipped.
Exit criterion: `bash test/ballast-release.sh --release-gate` exits 0. **NOT BUILT — writing it is Ballast's first task, before any member is fixed** (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. **Half A audits the frozen manifest:** each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. **Half B EXECUTES the stranger's path rather than auditing it:** (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. **BUILT 2026-08-17.** `test/ballast-release.sh` written and registered in `validate.sh`; suite mode green (`--mutate-evidence` 7/0). Half A: 3 of 4 manifest members complete (#14, #15, #3 — gate/registration/control/CLOSED-issue all confirmed); #4 landed the same day this file was written, so its CLOSED-issue credit is pending the next suite run. Half B's mechanics were smoke-tested end-to-end (all four sub-checks — B1/B2a/B2b/B3 — execute correctly against a real disposable clone) but **`--release-gate` has not yet been run for real** (the full ten-run stranger pass, against a clone cut from the commit that carries all four fixes) — that run is the actual goalpost and is still red pending it, honestly, not silently.
Manifest: FROZEN 2026-08-16 on creation — #14, #15, #4, #10, #3. Five entries, a fixed denominator rather than a percentage. Same admission rule Litmus and Nightwatch used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission. **#14 and #15 SHIPPED 2026-08-17** (PR #21, PR #20; each closed with evidence — atomic-write negative control, 10/10 consecutive parallel fresh-clone runs). **#3 SHIPPED 2026-08-17**: the durable-default and path-printing halves were already landed pre-freeze (GH-430); the sole remaining gap, a recorded negative control, closed the same day (`test/baselines/GH-3-state-dir-negative-control.md`) — closed as landed, not re-scoped or swapped. **#10 CUT 2026-08-17, invoking its own pre-declared contingency**: a driven marathon attempt (builder agy, reviewer codex, round-cap 5) escalated after 5 rounds without landing — the suite count the fix would need to touch grew from the estimated ~31 to 73 with zero mechanically adopted, and the builder self-issued a scope waiver rather than flagging the blocker back to the orchestrator. This is exactly the scope-slip the freeze anticipated ("#10 is the designated cut if scope slips... #1's clone-identity bracket already covers the same ground *detectably* in the meantime"); cut per that pre-authorized contingency rather than re-fired. Issue #10 stays open, un-closed by this cut — the underlying containment gap remains real, just descoped from Ballast. Manifest reduced from 5 to 4 entries; this is a recorded re-scope, not a silent drop.
Manifest-Members: 14 15 4 3
Explicit non-goals, stated so they are not silently absorbed: #16 (hosted CI re-arm — tracked separately, explicitly NOT in scope, the local pre-push gate stays the only gate), #9 (tooling floor: eslint/prettier, src/ coverage, decompositions), #11 (Sundown twin retirement), #12 (tree diet), #13 (fold scaling — its body was corrected 2026-08-16: it claimed event append is already atomic temp+rename, which was never true; #14 owns making it so).
GH_URL:
Milestone: Ballast
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes

Release: 0.8.0
Iterations: 0.8.0-0.8.4
Status: Draft
Target Date: 2026-10-17
Codename: Sundown
Description: Retire the twelve frozen Bash twins. Three steps, in order: (1) sweep for real `XYZ_PYTHON=0` usage — if nothing sets it, the fallback is already dead in practice; (2) re-vendor every fleet `.xyz/` copy onto the Python lane (`xyz-sync.sh list` is the worklist); (3) delete the twins and retire the GH-308 edit-guard, keeping only its no-new-Bash half (GH-551). Not before steps 1-2: the vendored fleet still runs the Bash path, and `XYZ_PYTHON=0` is the documented rollback. Depends on nothing in Meter.
**WIDENED 2026-08-15 by explicit operator decision — Sundown receives Meter's five engineering entries.** The release's sentence becomes: **the harness accounts for what it spends, checks what it requires before spending it, and stops carrying the retired Bash lane.** Said plainly rather than argued into one theme: the twin retirement and the metering work are two subjects sharing one release, and they are here together because Meter was re-pointed at publication on 2026-08-15 and these five needed a home that was not a parking space. They arrive intact — same capture docs under `PROJECT/2-WORKING/`, same verbatim acceptance criteria, same evidence — and the honest reading of the widening is that Sundown's date is now less trustworthy than it was, because it absorbed five entries without absorbing any schedule.
**RENUMBERED 0.7.0 → 0.8.0 on 2026-08-16 by explicit operator decision, to open 0.7.0 for Ballast.** Nothing about this release changed except its version: same codename, same target date, same manifest, same milestone. The band moves with it (`0.7.0-0.7.4` → `0.8.0-0.8.4`) because a release's iteration band is part of its identity here, not a separate fact. Recorded as a dated line rather than shown as a block that was always 0.8.0, on the same principle the manifest re-scopes above follow: a version that changes without a trace is indistinguishable from one that was misread. The `(0.7.0)` parentheticals in Meter's re-scope paragraphs were swept to `(0.8.0)` in the same edit — they identify *which release received the transfer*, so leaving them stale would have pointed a reader at a version that no longer exists. `CHANGELOG.md`'s existing entry is **not** swept: it is the append-only record of what was decided on 2026-08-15, when Sundown was 0.7.0, and the renumber is recorded there as its own dated entry instead.
Manifest: **#378, #379, #382, #491, #551**, received from Meter 2026-08-15, plus the twin-retirement work described above, which remains unnumbered until its issues are filed. **#546 is milestone backlog, not a manifest entry** — it followed the metering subject here and does not gate this release, under the standing rule that discovery is not admission. **Not yet frozen.** Freezing requires the twin-retirement issues to exist so the manifest is a fixed denominator rather than a list plus a promise; until then this line is a receipt for the transfer, not a contract. #380 did not move: it is CLOSED and shipped under Meter's original scope, and stays milestoned there.
Exit criterion: **NOT WRITTEN.** Required before this release starts, per the ordering Litmus and Nightwatch both used and Meter is repeating — the gate is built first and arrives RED, because a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one.
GH_URL: pending — api.github.com DNS outage 2026-08-14; file on recovery
Milestone: Sundown
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes
PROJECT/PDDA.md-583-judgment call for the LLM layer or a human — see the `/governance-audit` skill, which runs this check
PROJECT/PDDA.md-584-first and then reads the same doc set for that fuzzier class of inconsistency.
PROJECT/PDDA.md-585-
PROJECT/PDDA.md:586:#### J. `pdda.sh releases`
PROJECT/PDDA.md-587-
PROJECT/PDDA.md-588-Purpose:
PROJECT/PDDA.md-589-- validate `RELEASES.md`, the single forward-looking release-planning ledger — deliberately light.
--
PROJECT/PDDA.md-626-
PROJECT/PDDA.md-627-**`RELEASES.md` is an optional planning aid.** It is not a required artifact, not a checklist, and
PROJECT/PDDA.md-628-not something to keep topped up. An empty file, a stale file, or no file at all are all valid
PROJECT/PDDA.md:629:states — `pdda.sh releases` skips a missing file entirely ("RELEASES.md not found — nothing to
PROJECT/PDDA.md-630-check") and never blocks, even in `full` mode.
PROJECT/PDDA.md-631-
PROJECT/PDDA.md-632-**Do not proactively offer to fill it in, populate it, bring it current, or add a release that has
--
PROJECT/PDDA.md-666-Codename: n/a
PROJECT/PDDA.md-667-Milestone:
PROJECT/PDDA.md-668-Description:
PROJECT/PDDA.md:669:Exit criterion:
PROJECT/PDDA.md-670-Manifest:
PROJECT/PDDA.md-671-GH_URL:
PROJECT/PDDA.md-672-Front-door reviewed:
--
PROJECT/PDDA.md-678-- `Release:` (required) — the version being planned
PROJECT/PDDA.md-679-- `Status:` (optional) — free-text, unvalidated by design (`Draft`, `Working`, `Shipped`, whatever
PROJECT/PDDA.md-680-  an operator finds useful). **`Status: Shipped` is the sole "already shipped" signal** — both
PROJECT/PDDA.md:681:  `pdda.sh releases`'s overdue nudge and `pdda.sh releases-current`'s "in progress" filter key off
PROJECT/PDDA.md-682-  it exclusively. This is a rough signal, not a gated lifecycle — no fixed vocabulary is enforced.
PROJECT/PDDA.md-683-- `Iterations:` (optional) — a **reserved band of version numbers**, written `<lo>-<hi>` (e.g.
PROJECT/PDDA.md-684-  `0.2.0-0.2.4`). Versions inside a band ship freely and are recorded in `CHANGELOG.md` only; they
--
PROJECT/PDDA.md-687-
PROJECT/PDDA.md-688-  **The band's owner is the one exception.** A band is written on the block it belongs to, and that
PROJECT/PDDA.md-689-  block's own `Release:` is the band's `<lo>` — so the owner sits inside its own band and keeps its
PROJECT/PDDA.md:690:  block. Every *other* version in the range is covered by the band and gets none. `pdda.sh releases`
PROJECT/PDDA.md-691-  identifies the owner by line, not by version text, so a second block that merely repeats the
PROJECT/PDDA.md-692-  owner's version is still caught as the duplicate it is.
PROJECT/PDDA.md-693-
PROJECT/PDDA.md-694-  This is what gives the admission rule an answer instead of an argument. "Where does 0.2.3 go?"
PROJECT/PDDA.md-695-  resolved case-by-case is resolved by adding a row, every time; with a band it has a written
PROJECT/PDDA.md:696:  answer, and `pdda.sh releases` can check it — a version inside an existing band is already
PROJECT/PDDA.md-697-  accounted for, so a block for it is by definition a duplicate. That is testable in a way "is this
PROJECT/PDDA.md-698-  release meaningful?" never will be.
PROJECT/PDDA.md-699-
--
PROJECT/PDDA.md-706-  labels per release. That is 20–25 named rows across a five-release horizon, each an invitation to
PROJECT/PDDA.md-707-  fill in what shipped — the same drift, arriving as structure instead of as appended blocks. One
PROJECT/PDDA.md-708-  optional field beats five required ones.
PROJECT/PDDA.md:709:- `Target Date:` (optional) — `YYYY-MM-DD`; `pdda.sh releases` warns once this passes and `Status`
PROJECT/PDDA.md-710-  doesn't read `Shipped`
PROJECT/PDDA.md-711-- `Codename:` (optional) — `n/a` is fine
PROJECT/PDDA.md-712-- `Milestone:` (optional) — free-text, unvalidated, the **release → issue-set join key**. It holds a
--
PROJECT/PDDA.md-725-  not a run log, implementation plan, or second changelog; historical outcomes stay in
PROJECT/PDDA.md-726-  `CHANGELOG.md` and execution detail stays in the canonical `PROJECT/**` document. `/releases`
PROJECT/PDDA.md-727-  warns when this field exceeds four sentences or becomes multi-paragraph history.
PROJECT/PDDA.md:728:- `Exit criterion:` (optional) — one runnable command or observable condition that proves the arc
PROJECT/PDDA.md-729-  reached its goal. Keep the implementation and phased QA plan in `PROJECT/**`; this field is the
PROJECT/PDDA.md-730-  release-level goalpost only.
PROJECT/PDDA.md-731-- `Manifest:` (optional) — a concise, fixed release boundary, normally a dated `FROZEN` list of
--
PROJECT/PDDA.md-739-  no longer implies that.
PROJECT/PDDA.md-740-- `Front-door reviewed:` / `Shakedown reviewed:` / `License file:` (optional) — pre-release QA-gate
PROJECT/PDDA.md-741-  checkboxes: has the `/front-door` onboarding audit run, has the `/shakedown` script-path audit
PROJECT/PDDA.md:742:  run, is a `LICENSE` file present. `Yes` or `No`; `pdda.sh releases` warns on any other non-blank
PROJECT/PDDA.md-743-  value. A blank value just means not yet answered, not a failure.
PROJECT/PDDA.md-744-
PROJECT/PDDA.md-745-Add new fields only when a real need shows up. This format intentionally started smaller than the
--
PROJECT/PDDA.md-767-offer to top it up. A skill that exists to keep this file populated is the most efficient possible
PROJECT/PDDA.md-768-way to violate the optionality rule at the top of this section.
PROJECT/PDDA.md-769-
PROJECT/PDDA.md:770:#### `pdda.sh releases-current`
PROJECT/PDDA.md-771-
PROJECT/PDDA.md-772-Read-only roll-up (not part of `PDDA_DETERMINISTIC_CHECKS` — emits no findings, never gates): lists
PROJECT/PDDA.md-773-every `RELEASES.md` entry whose `Status` is empty or not exactly `Shipped`. A rough, non-authoritative
--
PROJECT/PDDA.md-999-6. `pdda.sh changelog`
PROJECT/PDDA.md-1000-7. `pdda.sh stale`
PROJECT/PDDA.md-1001-8. `pdda.sh issue-doc-sync`
PROJECT/PDDA.md:1002:9. `pdda.sh releases`
PROJECT/PDDA.md-1003-10. `pdda.sh governance`
PROJECT/PDDA.md-1004-
PROJECT/PDDA.md-1005-Then run:
--
utils/pdda-local-checks.sh-212-
utils/pdda-local-checks.sh-213-# ── GH-284 Phase 3 · the release → issue-set join key ─────────────────────────────────────────────
utils/pdda-local-checks.sh-214-# Ported verbatim from check_releases as it stood at cfd56b0^. Upstream still PARSES `Milestone:`
utils/pdda-local-checks.sh:215:# (pdda_releases_list emits it) and documents it as "optional — free-text, unvalidated"; this repo
utils/pdda-local-checks.sh-216-# needs it validated because it is the key that resolves a release to a set of issues, which is what
utils/pdda-local-checks.sh-217-# lets a release drive marathon selection at all.
utils/pdda-local-checks.sh-218-check_release_milestone() {
--
utils/pdda-local-checks.sh-231-
utils/pdda-local-checks.sh-232-  # A ledger with no blocks is a VALID state (sparse is fine, and RELEASES.md is optional per
utils/pdda-local-checks.sh-233-  # GH-381) — report exactly as clean as an absent file, and record no finding of our own.
utils/pdda-local-checks.sh:234:  rows="$(pdda_releases_list "$RELEASES_FILE_EFF")"
utils/pdda-local-checks.sh-235-  if [ -z "$rows" ]; then
utils/pdda-local-checks.sh-236-    pdda_emit_summary "$CHECK_NAME" 0
utils/pdda-local-checks.sh-237-    return "$(pdda_gated_exit 0)"
--
skills/radar/SKILL.md-374-| `weekly-shipped` | Outward recap of what shipped | Inward, diagnostic, judgmental |
skills/radar/SKILL.md-375-| `marathon-triage` | Ranking marathon candidates | Radar asks what deserves to be a candidate; feeds it, never requires it |
skills/radar/SKILL.md-376-| `/honest` | Whole-repo maturity read | Windowed (21 days) and mix-focused |
skills/radar/SKILL.md:377:| `pdda.sh glance` / `releases-current` | Doc-state inventory | A verdict across git + issues + docs + releases, not an inventory |
skills/radar/SKILL.md-378-| `/10days` | Sweeps issues then **executes** | Radar never executes anything |
--
test/gh460-pipe-buffer-sigpipe.sh-129-# does NOT work: printf is a builtin, so SIGPIPE kills the pipeline's left subshell before `|| true`
test/gh460-pipe-buffer-sigpipe.sh-130-# can run (measured: still 141).
test/gh460-pipe-buffer-sigpipe.sh-131-GH472_FILES="test/gh308-frozen-twin-guard.sh test/gh438-acceptance-recheck.sh
test/gh460-pipe-buffer-sigpipe.sh:132:test/gh284-p3-release-milestone.sh test/pdda-roadmap-coverage.sh utils/pdda-local-checks.sh
test/gh460-pipe-buffer-sigpipe.sh-133-test/pdda-local-checks.sh"
test/gh460-pipe-buffer-sigpipe.sh-134-# ANY producer piped into `grep -q`, not just printf. The first version matched `printf` only, and
test/gh460-pipe-buffer-sigpipe.sh-135-# codex's QA review found what that missed: two `grep -v … | grep -qF` transcript scans with the
--
skills/releases/SKILL.md-39-
skills/releases/SKILL.md-40-Run this route before every other route unless the same invocation already established fresh state.
skills/releases/SKILL.md-41-
skills/releases/SKILL.md:42:1. Run `utils/pdda/pdda.sh releases` and `utils/pdda/pdda.sh releases-current`. Preserve their
skills/releases/SKILL.md-43-   warn-only semantics.
skills/releases/SKILL.md-44-2. Select the evidence window: use an operator-supplied window, otherwise 21 days. Resolve the
skills/releases/SKILL.md-45-   active integration branch from repo policy (`development` in this repo; otherwise the declared
--
skills/releases/SKILL.md-109-4. Immediately before writing, re-read `RELEASES.md` and compare its hash. If it changed, discard the
skills/releases/SKILL.md-110-   patch, synthesize again, and preview a new patch.
skills/releases/SKILL.md-111-5. Edit only the confirmed blocks. Never reorder unrelated blocks.
skills/releases/SKILL.md:112:6. Run `utils/pdda/pdda.sh releases` and report every finding.
skills/releases/SKILL.md-113-
skills/releases/SKILL.md-114-## Plan or update subroutine
skills/releases/SKILL.md-115-
--
skills/releases/SKILL.md-139-Target Date: 2026-12-01
skills/releases/SKILL.md-140-Codename: Example
skills/releases/SKILL.md-141-Description: One coherent release theme in no more than four sentences.
skills/releases/SKILL.md:142:Exit criterion: `command --that-proves-the-release` exits 0.
skills/releases/SKILL.md-143-Manifest: FROZEN YYYY-MM-DD — #101, #102, #103.
skills/releases/SKILL.md-144-GH_URL:
skills/releases/SKILL.md-145-Milestone: Example
--
skills/releases/SKILL.md-151-5. Preview the complete new or replacement block and get one confirmation. Re-check the file hash
skills/releases/SKILL.md-152-before writing. Append new blocks after the last block; replace only an explicitly selected existing
skills/releases/SKILL.md-153-block. Never silently edit neighboring blocks.
skills/releases/SKILL.md:154:6. Run `utils/pdda/pdda.sh releases` and report findings.
skills/releases/SKILL.md-155-
skills/releases/SKILL.md-156-## Anchor and backfill subroutine
skills/releases/SKILL.md-157-
--
skills/releases/SKILL.md-169-1. Require `gh` authentication and a specific existing release block. Stop if it is already
skills/releases/SKILL.md-170-   `Shipped`. If `GH_URL:` exists but status is unshipped, inspect the existing Release and ask how
skills/releases/SKILL.md-171-   to handle the draft or conflicting object.
skills/releases/SKILL.md:172:2. Run `utils/pdda/pdda.sh releases` and surface its findings.
skills/releases/SKILL.md-173-3. Build release notes from the block's `Description:` plus concise codename, exit-criterion, and
skills/releases/SKILL.md-174-   manifest context when useful. Never invent notes. Ask for missing release-facing prose.
skills/releases/SKILL.md-175-4. Preview together:
--
skills/releases/SKILL.md-179-5. Get one explicit confirmation, publish live, and capture the returned URL. If creation fails,
skills/releases/SKILL.md-180-   report the error verbatim and make no ledger edit.
skills/releases/SKILL.md-181-6. On success only, re-check the file hash, write the returned URL, set `Status: Shipped`, and run
skills/releases/SKILL.md:182:   `utils/pdda/pdda.sh releases`.
skills/releases/SKILL.md-183-7. Remind the operator that shipped history and lessons belong in `CHANGELOG.md`; do not write that
skills/releases/SKILL.md-184-   entry unless separately asked.
skills/releases/SKILL.md-185-
--
utils/pdda/pdda.sh-656-#   (5) warn  — a block's version falls inside another block's reserved Iterations band
utils/pdda/pdda.sh-657-check_releases() {
utils/pdda/pdda.sh-658-  pdda_reset_counts
utils/pdda/pdda.sh:659:  local CHECK_NAME="pdda-check-releases" rc=0
utils/pdda/pdda.sh-660-  local RELEASES_FILE_EFF="${PDDA_RELEASES_FILE:-$PDDA_REPO_ROOT/RELEASES.md}"
utils/pdda/pdda.sh-661-  local release status target_date codename description gh_url line_no target_epoch today_epoch
utils/pdda/pdda.sh-662-  local status_lc front_door shakedown license_file qa_field qa_label qa_value qa_value_lc
--
utils/pdda/pdda.sh-673-  # sparse is fine — so it reports exactly as clean as it did before this field pair existed. The
utils/pdda/pdda.sh-674-  # guard exists because the here-doc loops below would otherwise see one empty line and fake a
utils/pdda/pdda.sh-675-  # "block near line 0 has no version" error; it deliberately records NO finding of its own.
utils/pdda/pdda.sh:676:  rows="$(pdda_releases_list "$RELEASES_FILE_EFF")"
utils/pdda/pdda.sh-677-  if [ -z "$rows" ]; then
utils/pdda/pdda.sh-678-    pdda_emit_summary "$CHECK_NAME" 0
utils/pdda/pdda.sh-679-    return "$(pdda_gated_exit 0)"
--
utils/pdda/pdda.sh-795-    return 0
utils/pdda/pdda.sh-796-  fi
utils/pdda/pdda.sh-797-
utils/pdda/pdda.sh:798:  printf 'PDDA releases-current — in-progress entries in %s\n' "$(pdda_relpath "$RELEASES_FILE_EFF")"
utils/pdda/pdda.sh-799-  while IFS=$'\037' read -r release status target_date codename description gh_url \
utils/pdda/pdda.sh-800-    front_door shakedown license_file iterations milestone line_no; do
utils/pdda/pdda.sh-801-    [ -n "$(pdda_trim "$release")" ] || continue
--
utils/pdda/pdda.sh-811-    [ -n "$milestone" ] && printf '    Milestone: %s\n' "$milestone"
utils/pdda/pdda.sh-812-    [ -n "$description" ] && printf '    %s\n' "$description"
utils/pdda/pdda.sh-813-    [ -n "$gh_url" ] && printf '    %s\n' "$gh_url"
utils/pdda/pdda.sh:814:  done < <(pdda_releases_list "$RELEASES_FILE_EFF")
utils/pdda/pdda.sh-815-
utils/pdda/pdda.sh-816-  [ "$any" -eq 1 ] || printf '\n(no in-progress releases — every entry is Status: Shipped)\n'
utils/pdda/pdda.sh-817-  return 0
--
utils/pdda/pdda.sh-847-#     suffix widened.
utils/pdda/pdda.sh-848-#   - config.sh, which belongs to git-pulse, a separate program. It is not ours and never will be here.
utils/pdda/pdda.sh-849-PDDA_GOV_SHIPPED_DOCS_DEFAULT="utils/pdda/PDDA-INSTALL.md PROJECT/PDDA.md"
utils/pdda/pdda.sh:850:PDDA_GOV_SHIPPED_DOC_REF_EXEMPTIONS_DEFAULT="ROUTER.md AGENTS.md GUIDING-PRINCIPLES.md README.md CLAUDE.md .claude/skills/pdda/SKILL.md .claude/skills/governance-audit/SKILL.md .claude/skills/releases/SKILL.md PROJECT/3-COMPLETED/PDDA-SYNC-TO-OTHER-REPOS.md utils/PDDA-INSTALL.md install.sh templates/ROUTER.target.md test/pdda-doc-health-hooks.sh pdda-sync.sh utils/pdda/pdda-sync.sh utils/pdda/pdda-manifest.sh utils/pdda.sh utils/pdda-lib.sh utils/pdda-doc-ready.sh utils/pdda-catchup.sh config.sh"
utils/pdda/pdda.sh-851-PDDA_GOV_SHIPPED_DOC_ENVVAR_EXEMPTIONS_DEFAULT="PDDA_REGISTRY PDDA_GITPULSE_DIR PDDA_SYNC_MAX_SHRINK"
utils/pdda/pdda.sh-852-
utils/pdda/pdda.sh-853-# Print "<line>\t<text>" for lines outside an exempt fence/blockquote — same carve-out convention as
--
utils/pdda/pdda.sh-1239-pdda-check-changelog:check_changelog
utils/pdda/pdda.sh-1240-pdda-stale-working-docs:check_stale
utils/pdda/pdda.sh-1241-pdda-check-issue-doc-sync:check_issue_doc_sync
utils/pdda/pdda.sh:1242:pdda-check-releases:check_releases
utils/pdda/pdda.sh-1243-pdda-check-governance:check_governance
utils/pdda/pdda.sh-1244-"
utils/pdda/pdda.sh-1245-
--
utils/release-lanes.sh-65-[[ -z "$MILESTONE" || -z "$RELEASE" ]] || die "--milestone and --release are mutually exclusive"
utils/release-lanes.sh-66-
utils/release-lanes.sh-67-# ── milestone resolution ────────────────────────────────────────────────────────────────────────
utils/release-lanes.sh:68:# Reads RELEASES.md directly rather than shelling out to `pdda.sh releases-current`: that command is
utils/release-lanes.sh-69-# a human-facing report whose formatting is free to change, and parsing a report to drive automation
utils/release-lanes.sh-70-# is how you get a silent break the day someone improves the wording.
utils/release-lanes.sh-71-resolve_milestone() {
--
utils/pdda/pdda-lib.sh-464-# <line> onto the wrong variable, and one after it makes bash's last-variable-absorbs-the-rest rule
utils/pdda/pdda-lib.sh-465-# fold the extras into <line>. So <line> stays last as a record terminator, and every reader must be
utils/pdda/pdda-lib.sh-466-# updated in the SAME change — `check_releases` and `cmd_releases_current` are the only two, and
utils/pdda/pdda-lib.sh:467:# test/pdda-releases-iterations.sh pins the field count so a future addition can't drift silently.
utils/pdda/pdda-lib.sh:468:# The stable, external surface for other tooling is `pdda.sh releases-current`, not this helper.
utils/pdda/pdda-lib.sh-469-#
utils/pdda/pdda-lib.sh-470-# `Status:` is free-text (Draft/Working/Shipped/... — whatever an operator writes) and unvalidated
utils/pdda/pdda-lib.sh-471-# by design: it's a rough, non-authoritative signal for "what's in progress," not a gated lifecycle
utils/pdda/pdda-lib.sh-472-# field. `Milestone:` is free-text for the same reason — it carries a GitHub milestone *title* so a
utils/pdda/pdda-lib.sh-473-# release's scope can be queried (`gh issue list --milestone "<title>"`) instead of hand-listed here.
utils/pdda/pdda-lib.sh-474-# `Front-door reviewed:`/`Shakedown reviewed:`/`License file:` are optional Yes/No QA-gate fields,
utils/pdda/pdda-lib.sh:475:# and `Iterations:` is an optional reserved version band (`pdda.sh releases` warns on a malformed
utils/pdda/pdda-lib.sh-476-# value for either). See PROJECT/PDDA.md "RELEASES.md — release ledger".
utils/pdda/pdda-lib.sh:477:pdda_releases_list() {
utils/pdda/pdda-lib.sh-478-  local file="$1"
utils/pdda/pdda-lib.sh-479-  [ -f "$file" ] || return 0
utils/pdda/pdda-lib.sh-480-  awk '
--
utils/pdda/pdda-lib.sh-529-
utils/pdda/pdda-lib.sh-530-# True if the value is a well-formed reserved-iteration band: exactly "<lo>-<hi>", both plain
utils/pdda/pdda-lib.sh-531-# dotted-numeric versions, lo <= hi. Strict on purpose — a band is only useful if the containment
utils/pdda/pdda-lib.sh:532:# test in `pdda.sh releases` can be trusted, so anything ambiguous (a prerelease hyphen, a reversed
utils/pdda/pdda-lib.sh-533-# range) warns rather than being silently half-parsed. See PROJECT/PDDA.md "RELEASES.md — release
utils/pdda/pdda-lib.sh-534-# ledger" → `Iterations:`.
utils/pdda/pdda-lib.sh-535-pdda_is_iteration_band() {
--
utils/pdda/PDDA-INSTALL.md-173-
utils/pdda/PDDA-INSTALL.md-174-1. Create the target directories listed above. -> expect `PROJECT/` and `utils/` to exist.
utils/pdda/PDDA-INSTALL.md-175-2. Copy the canonical install-set files verbatim to the same relative paths in the target repo. -> expect `PROJECT/PDDA.md` and all shipped `utils/pdda-*.sh` files to exist.
utils/pdda/PDDA-INSTALL.md:176:3. Create baseline `ROADMAP.md`, `CHANGELOG.md`, and `RELEASES.md` files if the target repo does not already have them. -> expect the roadmap contract to have a file to guard, the changelog check to warn less, and a release-planning ledger to exist. `RELEASES.md` is the one optional member of that set: `pdda.sh releases` skips a missing file and never blocks, so a repo that never plans a release arc can delete it and stay green. It is seeded only so the format is discoverable — not as a file to keep populated (see `PROJECT/PDDA.md` -> "RELEASES.md — release ledger").
utils/pdda/PDDA-INSTALL.md-177-4. Create an empty `PROJECT/PDDA-ACTIVITY.jsonl` if it does not exist. -> expect a zero- or low-byte log file, not this repo's historical log.
utils/pdda/PDDA-INSTALL.md-178-4a. Add `PROJECT/PDDA-ACTIVITY.jsonl` and `.pdda-gh-state.tsv` to the target's `.gitignore` (and `git rm --cached` any that are already tracked). -> expect the churning runtime state to stop dirtying `git status` on every run.
utils/pdda/PDDA-INSTALL.md-179-4b. Record the install in the per-user, machine-local registry `${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv` (one tab-delimited row per target: `target · last_install_utc · mode · source_commit · startup_docs`; latest install wins). -> expect `pdda-sync.sh` to read this to find copies that are behind. Machine-local, never committed; `--no-register` or `PDDA_REGISTRY` adjust it.
--
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-19-ledger"), with a narrative discipline rubric already living in `skills/releases/SKILL.md`
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-20-("Discipline and abuse warnings" — Description ≤4 sentences, Manifest ≤7 issues, no execution-history
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-21-prose). In practice the ledger keeps ballooning anyway: status appendices, run logs, and dated notes
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:22:get written directly into `Description:`/`Exit criterion:`/`Manifest:` fields.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-23-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-24-**Concrete instance (Ballast 0.7.0, 2026-08-17):** a long "BUILT 2026-08-17" status appendix was added
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:25:directly to the `Exit criterion:` field mid-release-gate-work — exactly the violation the skill already
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-26-warns against.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-27-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-28-## Root cause (two gaps, not one)
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-29-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-30-1. **No enforcement teeth.** The discipline rubric only fires when someone explicitly runs
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:31:   `/releases clean`. The deterministic checker (`check_releases()` in `utils/pdda/pdda.sh`) validates
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-32-   structure only (version present, date format, QA yes/no fields) and is deliberately warn-only by
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-33-   design — it never blocks, per `PROJECT/PDDA.md` section J.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-34-2. **No other legitimate home for release-level notes.** Manifest members each get their own GH issue;
--
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-39-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-40-Ran the proposed checks against all 7 real blocks before writing any code:
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-41-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:42:| Release | Description >4 sentences | Manifest-Members >7 tokens | Exit criterion length |
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-43-|---|---|---|---|
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-44-| 0.1.0 Quicksilver | clean | — (no field) | clean |
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-45-| 0.2.0 Litmus | clean | — | 592 chars / 6 sentences |
--
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-52-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-53-Two findings that changed the plan:
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-54-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:55:- **Manifest size is not the problem.** Only two blocks (0.6.0, 0.7.0) even use `Manifest-Members:`,
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:56:  and both are clean. The real bloat is entirely in `Description:` and `Exit criterion:`, and it's
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-57-  near-universal — 6 of 8 blocks trip the Description check, not just Ballast.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-58-- **"Spans multiple lines" is the wrong signal.** Every field in the file is one long wrapped physical
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-59-  line, never literally multi-line — a line-count check would catch nothing. Replaced with a
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:60:  sentence-count threshold on `Exit criterion:` (mirroring the existing Description rule): clean
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-61-  blocks sit at 0-592 chars, bloated ones start at 1544+ chars / 6+ sentences.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-62-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-63-## Revised proposed fix (lightest viable — no new skill, no new scanner binary)
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-64-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:65:1. Add a `Tracking Issue:` field to the `RELEASES.md` block spec (`PROJECT/PDDA.md` contract +
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-66-   `skills/releases/SKILL.md`'s plan-subroutine template). Extends the existing Issue-first SOP
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-67-   (`PROJECT/PDDA.md` → "GitHub issue intake") to the release ledger itself. Release-level status/run-log
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-68-   notes go there, not inline in the ledger.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:69:2. Extend `check_releases()` in `utils/pdda/pdda.sh` with deterministic bloat checks:
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-70-   - `Description:` exceeding 4 sentences (validated signal, confirmed above)
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:71:   - `Exit criterion:` exceeding 4 sentences (replaces the multi-line check — validated to actually
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-72-     catch the observed bloat)
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:73:   - `Manifest-Members:` exceeding 7 tokens (kept for when the field is used; low incidence today but
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-74-     cheap to check)
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-75-   Same line-based-check style already used in that function — no LLM needed for detection.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-76-3. Ship the new checks **warn-only first**. Run once against live `RELEASES.md`, confirm the hit list
--
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-88----
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-89-
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-90-## Acceptance Criteria
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:91:- [ ] `Tracking Issue:` field documented in `PROJECT/PDDA.md`'s RELEASES.md contract and
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-92-      `skills/releases/SKILL.md`'s plan-subroutine template.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:93:- [ ] `check_releases()` flags Description/Exit-criterion/Manifest-Members bloat deterministically,
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-94-      with a registered regression test.
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-95-- [ ] New checks ship warn-only first; existing bloated blocks (6 of 8, per the validation scan above)
PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md-96-      are cleaned up or explicitly grandfathered before flipping to blocking.
--
test/gh284-p3-release-milestone.sh-5-# holds exactly one link. The linkage lives in GitHub (a milestone), so it maintains itself as issues
test/gh284-p3-release-milestone.sh-6-# open and close; RELEASES.md carries only the milestone TITLE.
test/gh284-p3-release-milestone.sh-7-#
test/gh284-p3-release-milestone.sh:8:# This file is also the first test the `pdda.sh releases` check has ever had — before Phase 3 it had
test/gh284-p3-release-milestone.sh-9-# none, so the pre-existing behaviors it must not break (empty version -> error, bad date -> warn,
test/gh284-p3-release-milestone.sh-10-# overdue -> warn, never gates the exit code) are pinned here too, not just the new field.
test/gh284-p3-release-milestone.sh:11:source "$(dirname "$0")/_setup.sh" gh284-p3-release-milestone
test/gh284-p3-release-milestone.sh-12-ROOT="$(cd "$(dirname "$0")/.." && pwd)"
test/gh284-p3-release-milestone.sh-13-PDDA="$ROOT/utils/pdda/pdda.sh"
test/gh284-p3-release-milestone.sh-14-
--
test/gh284-p3-release-milestone.sh-22-# The Milestone WARNING is this repo's own policy and lives in utils/pdda-local-checks.sh, not in
test/gh284-p3-release-milestone.sh-23-# the sync-managed upstream script. The 2026-08-03 PDDA sync (cfd56b0) deleted it from pdda.sh —
test/gh284-p3-release-milestone.sh-24-# upstream carries `Milestone:` as "optional, free-text, unvalidated" — and this test went red for
test/gh284-p3-release-milestone.sh:25:# ~2 days reading as pre-existing noise. Everything else below still exercises `pdda.sh releases`,
test/gh284-p3-release-milestone.sh-26-# which is the point: the upstream behaviours must keep working alongside the local check.
test/gh284-p3-release-milestone.sh-27-LOCAL_CHECKS="$ROOT/utils/pdda-local-checks.sh"
test/gh284-p3-release-milestone.sh-28-run_milestone() { # <fixture-file>
--
test/gh284-p3-release-milestone.sh-189-  || fail "field ordering broke: Milestone missing or shifted in $out"
test/gh284-p3-release-milestone.sh-190-
test/gh284-p3-release-milestone.sh-191-# ── (7) the repo's own ledger satisfies the contract it just documented ──────────────────
test/gh284-p3-release-milestone.sh:192:# Against `pdda.sh releases` this assertion is now UNFALSIFIABLE — upstream emits no Milestone
test/gh284-p3-release-milestone.sh-193-# warning at all, so "no warning fired" would be true for any ledger, including a broken one. It runs
test/gh284-p3-release-milestone.sh-194-# against the local check, which is the only thing that can still produce the string it greps for.
test/gh284-p3-release-milestone.sh-195-out="$(PDDA_ACTIVITY_LOG=/dev/null bash "$LOCAL_CHECKS" release-milestone 2>&1)"
--
test/gh284-p3-release-milestone.sh-197-  && fail "this repo's own RELEASES.md has a dated release with no Milestone: $out" \
test/gh284-p3-release-milestone.sh-198-  || pass "the repo's RELEASES.md carries a Milestone for every dated, unshipped release"
test/gh284-p3-release-milestone.sh-199-
test/gh284-p3-release-milestone.sh:200:echo "  gh284-p3-release-milestone: $PASS pass, $FAIL fail"
test/gh284-p3-release-milestone.sh-201-exit 0
--
test/path-integrity.sh-58-# (cfd56b0) added four such tokens and turned this check — and CI on `development` — red for ~2 days:
test/path-integrity.sh-59-#   utils/pdda/pdda.sh:850     an EXEMPTION-LIST data string naming three upstream skill/test files
test/path-integrity.sh-60-#                              under a dot-claude skills dir that this repo does not vendor
test/path-integrity.sh:61:#   utils/pdda/pdda-lib.sh:467 a COMMENT citing an upstream releases-iterations test file
test/path-integrity.sh-62-# None is a reference this repo can resolve or repair. (Those paths are deliberately DESCRIBED rather
test/path-integrity.sh-63-# than quoted here: this file is itself scanned, so spelling them out would trip the very check.) Excluding the tree is narrower than it looks:
test/path-integrity.sh-64-# every path this repo actually authors and can fix is still scanned, and upstream's tree is
--
test/meter-release.sh-29-#      #382 #491 #551 #555 #563 matched it, including one the script had never heard of. The check
test/meter-release.sh-30-#      was also one-directional: it asked "is everything I list in the ledger?" and never "is
test/meter-release.sh-31-#      everything the ledger lists in me?", so a ledger naming two entries while this file named
test/meter-release.sh:32:#      seven was invisible. Fixed below by reading a single machine-readable `Manifest-Members:`
test/meter-release.sh-33-#      field and comparing BOTH directions against it — prose is for humans, this field is for the
test/meter-release.sh-34-#      gate, and a retired number in the history paragraph can no longer satisfy anything.
test/meter-release.sh-35-#
--
test/meter-release.sh-83-
test/meter-release.sh-84-# ── The FROZEN manifest ───────────────────────────────────────────────────────────────────────────
test/meter-release.sh-85-# RE-SCOPED TO TWO on 2026-08-15 by explicit operator decision; scope is CLOSED to further admission.
test/meter-release.sh:86:# Adding one here is a RE-SCOPE and must be matched in RELEASES.md's `Manifest-Members:` field — the
test/meter-release.sh-87-# cross-check below compares the two in BOTH directions.
test/meter-release.sh-88-#
test/meter-release.sh-89-# Format: <issue>|<gate test file, or '-' if satisfied by another gate>|<note>
--
test/meter-release.sh-436-  local rel="${1:-$ROOT/RELEASES.md}" line entry n missing="" extra="" declared
test/meter-release.sh-437-  [ -f "$rel" ] || { info "RELEASES.md absent — manifest cross-check skipped"; return 0; }
test/meter-release.sh-438-
test/meter-release.sh:439:  line="$(/usr/bin/awk '/^Codename: Meter/,/^$/' "$rel" | /usr/bin/grep '^Manifest-Members:')"
test/meter-release.sh-440-  if [ -z "$line" ]; then
test/meter-release.sh:441:    bad "RELEASES.md's Meter block has no machine-readable 'Manifest-Members:' field — the frozen boundary is not recorded in a form this gate can check (the prose Manifest: paragraph names retired members and cannot be used)"
test/meter-release.sh-442-    return 1
test/meter-release.sh-443-  fi
test/meter-release.sh:444:  declared="${line#Manifest-Members:}"
test/meter-release.sh-445-
test/meter-release.sh-446-  # direction 1 — everything this file names must be declared in the ledger
test/meter-release.sh-447-  for entry in "${MANIFEST[@]}"; do
--
test/meter-release.sh-457-  done
test/meter-release.sh-458-
test/meter-release.sh-459-  if [ -n "$missing" ] || [ -n "$extra" ]; then
test/meter-release.sh:460:    [ -n "$missing" ] && bad "RELEASES.md's Manifest-Members does not declare:$missing — this file names members the ledger does not"
test/meter-release.sh-461-    [ -n "$extra" ]   && bad "this file does not name:$extra — the ledger declares members this gate does not measure"
test/meter-release.sh-462-    return 1
test/meter-release.sh-463-  fi
test/meter-release.sh:464:  ok "the frozen manifest here matches RELEASES.md's Manifest-Members field in both directions ($declared)"
test/meter-release.sh-465-}
test/meter-release.sh-466-
test/meter-release.sh-467-# ── Mutation mode: the negative control for this audit ────────────────────────────────────────────
--
test/meter-release.sh-583-  # version of this file unable to fail, so the control must observe both halves of the fix.
test/meter-release.sh-584-  echo "-- mutation 6: ledger declares a RETIRED member (direction 2 — ledger has one this file lacks)"
test/meter-release.sh-585-  REL_FIX="$TMP/RELEASES.md"
test/meter-release.sh:586:  { echo "Codename: Meter"; echo "Manifest-Members: 555 563 378"; echo; } > "$REL_FIX"
test/meter-release.sh-587-  if manifest_matches_releases_md "$REL_FIX" >/dev/null 2>&1; then
test/meter-release.sh-588-    mut_bad "a ledger declaring retired #378 was ACCEPTED — the cross-check is still one-directional"
test/meter-release.sh-589-  else
--
test/meter-release.sh-591-  fi
test/meter-release.sh-592-
test/meter-release.sh-593-  echo "-- mutation 7: ledger drops a current member (direction 1 — this file has one the ledger lacks)"
test/meter-release.sh:594:  { echo "Codename: Meter"; echo "Manifest-Members: 555"; echo; } > "$REL_FIX"
test/meter-release.sh-595-  if manifest_matches_releases_md "$REL_FIX" >/dev/null 2>&1; then
test/meter-release.sh-596-    mut_bad "a ledger missing #563 was ACCEPTED — direction 1 does not work"
test/meter-release.sh-597-  else
--
test/meter-release.sh-609-
test/meter-release.sh-610-  echo "-- restore: the unmutated fixture must be green again in this same run"
test/meter-release.sh-611-  audit_artifact "$FIX" "$REF" >/dev/null 2>&1
test/meter-release.sh:612:  { echo "Codename: Meter"; echo "Manifest-Members: 555 563"; echo; } > "$REL_FIX"
test/meter-release.sh-613-  if [ "$ART_BAD" -eq 0 ] && manifest_matches_releases_md "$REL_FIX" >/dev/null 2>&1; then
test/meter-release.sh-614-    mut_ok "restoring the inputs restores the verdict — the detector is not simply always-red"
test/meter-release.sh-615-  else
--
test/ballast-release.sh-11-#            EXISTS, is REGISTERED in validate.sh's TESTS array (a gate absent from TESTS is
test/ballast-release.sh-12-#            indistinguishable from one that passes — the #461 defect), has a RECORDED negative
test/ballast-release.sh-13-#            control under test/baselines/, and the manifest here agrees with RELEASES.md's
test/ballast-release.sh:14:#            Ballast `Manifest-Members:` field in BOTH directions (a one-directional check, or one
test/ballast-release.sh-15-#            that reads the prose `Manifest:` paragraph instead of the machine field, cannot fail —
test/ballast-release.sh-16-#            see meter-release.sh's own history for exactly how that happened).
test/ballast-release.sh-17-#
--
test/ballast-release.sh-63-
test/ballast-release.sh-64-# ── The FROZEN manifest, post-#10-cut (2026-08-17) ───────────────────────────────────────────────
test/ballast-release.sh-65-# Format: <issue>|<gate test file>|<recorded control file>|<note>
test/ballast-release.sh:66:# A re-scope (an admission, a swap, a cut) must be matched in RELEASES.md's `Manifest-Members:`
test/ballast-release.sh-67-# field — the cross-check below compares the two in BOTH directions.
test/ballast-release.sh-68-MANIFEST=(
test/ballast-release.sh-69-  "14|test/gh14-atomic-append.sh|test/baselines/GH-14-negative-control.md|atomic event append — appendEvent publishes via temp+rename"
--
test/ballast-release.sh-162-  local rel="${1:-$ROOT/RELEASES.md}" line n missing="" extra="" declared
test/ballast-release.sh-163-  [ -f "$rel" ] || { info "RELEASES.md absent — manifest cross-check skipped"; return 0; }
test/ballast-release.sh-164-
test/ballast-release.sh:165:  line="$(/usr/bin/awk '/^Codename: Ballast/,/^$/' "$rel" | /usr/bin/grep '^Manifest-Members:')"
test/ballast-release.sh-166-  if [ -z "$line" ]; then
test/ballast-release.sh:167:    bad "RELEASES.md's Ballast block has no machine-readable 'Manifest-Members:' field — the frozen boundary is not recorded in a form this gate can check (the prose Manifest: paragraph names cut/shipped members too and cannot be used)"
test/ballast-release.sh-168-    return 1
test/ballast-release.sh-169-  fi
test/ballast-release.sh:170:  declared="${line#Manifest-Members:}"
test/ballast-release.sh-171-
test/ballast-release.sh-172-  local entry
test/ballast-release.sh-173-  for entry in "${MANIFEST[@]}"; do
--
test/ballast-release.sh-180-  done
test/ballast-release.sh-181-
test/ballast-release.sh-182-  if [ -n "$missing" ] || [ -n "$extra" ]; then
test/ballast-release.sh:183:    [ -n "$missing" ] && bad "RELEASES.md's Manifest-Members does not declare:$missing — this file names members the ledger does not"
test/ballast-release.sh-184-    [ -n "$extra" ]   && bad "this file does not name:$extra — the ledger declares members this gate does not measure"
test/ballast-release.sh-185-    return 1
test/ballast-release.sh-186-  fi
test/ballast-release.sh:187:  ok "the frozen manifest here matches RELEASES.md's Manifest-Members field in both directions ($declared)"
test/ballast-release.sh-188-}
test/ballast-release.sh-189-
test/ballast-release.sh-190-# ── Half B: the stranger's path, EXECUTED ─────────────────────────────────────────────────────────
--
test/ballast-release.sh-344-
test/ballast-release.sh-345-  echo "-- mutation 4: ledger declares a member this file does not measure (direction 2)"
test/ballast-release.sh-346-  REL_FIX="$TMP/RELEASES.md"
test/ballast-release.sh:347:  { echo "Codename: Ballast"; echo "Manifest-Members: 14 15 4 3 999"; echo; } > "$REL_FIX"
test/ballast-release.sh-348-  saved=("${MANIFEST[@]}")
test/ballast-release.sh-349-  if manifest_matches_releases_md "$REL_FIX" >/dev/null 2>&1; then
test/ballast-release.sh-350-    mut_bad "a ledger declaring an unmeasured #999 was ACCEPTED — direction 2 does not work"
--
test/ballast-release.sh-353-  fi
test/ballast-release.sh-354-
test/ballast-release.sh-355-  echo "-- mutation 5: this file measures a member the ledger drops (direction 1)"
test/ballast-release.sh:356:  { echo "Codename: Ballast"; echo "Manifest-Members: 14 15 4"; echo; } > "$REL_FIX"
test/ballast-release.sh-357-  if manifest_matches_releases_md "$REL_FIX" >/dev/null 2>&1; then
test/ballast-release.sh-358-    mut_bad "a ledger missing #3 was ACCEPTED — direction 1 does not work"
test/ballast-release.sh-359-  else
--
test/ballast-release.sh-362-
test/ballast-release.sh-363-  echo "-- restore: the unmutated fixture and ledger must be green again in this same run"
test/ballast-release.sh-364-  fixture_audit
test/ballast-release.sh:365:  { echo "Codename: Ballast"; echo "Manifest-Members: 14 15 4 3"; echo; } > "$REL_FIX"
test/ballast-release.sh-366-  if [ "$FALSE_CLAIMS" -eq 0 ] && [ "$COMPLETE" -eq 1 ] && manifest_matches_releases_md "$REL_FIX" >/dev/null 2>&1; then
test/ballast-release.sh-367-    mut_ok "restoring the inputs restores the verdict — the detector is not simply always-red"
test/ballast-release.sh-368-  else
--
test/baselines/GH-555-negative-control.md-48-
test/baselines/GH-555-negative-control.md-49-## What the fix had to be falsifiable against
test/baselines/GH-555-negative-control.md-50-
test/baselines/GH-555-negative-control.md:51:- Membership is read from a machine-readable `Manifest-Members:` field, compared in **both**
test/baselines/GH-555-negative-control.md-52-  directions, and prose can no longer satisfy it.
test/baselines/GH-555-negative-control.md-53-- An entry is COMPLETE only when its evidence machinery is in place **and** its issue is CLOSED.
test/baselines/GH-555-negative-control.md-54-- The artifact audit and the stranger's path each detect their own specific violation.

2026-08-18T16:08:31.757754Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "sed -n '1,245p' test/pdda-releases-iterations.sh
rg -n 'Manifest-Members:|Exit criterion:' RELEASES.md
rg -n -C 2 'PDDA_DETERMINISTIC_CHECKS|check_releases|releases' validate.sh utils/pdda/pdda.sh | head -n 300
rg -n -C 5 'Discipline and abuse warnings|Manifest-Members|Exit criterion|plan-subroutine|Tracking Issue' skills/releases/SKILL.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4
 succeeded in 0ms:
sed: test/pdda-releases-iterations.sh: No such file or directory
107:Exit criterion: `bash test/litmus-release.sh --release-gate` exits 0. Red today by design; turning it green is what "done" means. Its own negative control is `--mutate-evidence`, which must detect a stripped declaration and an unregistered gate. NOTE the honest limit, stated in that file: the audit proves registration, declaration shape and the absence of false completion claims. It does NOT prove a control was truly observed, because `gate_inventory.py` reads a declaration authored by the same person who wrote the gate. Recorded execution of each control is deliberately out of scope for this release.
124:Exit criterion: `bash test/nightwatch-release.sh --release-gate` exits 0. **BUILT 2026-08-11 and red by design**, exactly as Litmus's was; turning it green is what "done" means. It has two halves because a metadata audit cannot answer this release's question. Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), and has a RECORDED control under `test/baselines/`; it also cross-checks that this list and the `Manifest:` line below agree, since a boundary that disagrees with itself is not frozen. Half B **executes** the lifecycle cases rather than auditing them, delegating to the suites that already drive real children and kill them rather than growing a second driver fixture here. Status on 2026-08-11: **manifest 8/8 complete; lifecycle 5 passing, 0 NOT COVERED — GOALPOST MET.** The last gap was the hostile-target write-set case, closed by #514, which was filed while executing this release and deliberately NOT admitted to the manifest (discovery is not admission); it belongs to the lifecycle list because the exit criterion always named that case — what was missing was a suite driving it. That lane also corrected its own premise: the pre-fix tree does not dispatch a turn first, it dies at the render's `git add` with an unhandled `CalledProcessError` traceback, so the discriminating assertion is the absence of that traceback rather than the absence of a dispatch. Its own negative control is `--mutate-evidence` (34/0), which unregisters a gate and deletes a recorded control in a fixture copy, requires both to be detected, and re-checks the unmutated inputs green in the same run so an always-red detector cannot pass for one. Honest limit, inherited from Litmus: Half A reads a declaration and a filename and cannot know a recorded control was honestly recorded; Half B is what narrows that, and is why this criterion is a command that kills children rather than a checklist.
150:Exit criterion: `bash test/lantern-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it precedes fixing any member, which is the Litmus and Nightwatch ordering and the reason both releases could tell a finished entry from a claimed one. Two halves, the established shape: Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below. Half B **executes** #499's four phases rather than auditing them, since every one of them is a message an operator either receives or does not: a `relay-drive` launch preflight that refuses before spending, a gate refusal that states its real reason, a launcher exit code that survives its wrapper, and a change-impact report. **#358 Phase 2 is the one member with no executable half, and the criterion is written around that rather than pretending otherwise:** it is satisfied by a RECORDED transcript of a real CI failure under `test/baselines/`, and it must NOT be satisfiable by a disposition written in advance — that issue's own capture doc forbids pre-committing one, and an exit criterion that accepted a pre-written verdict would launder exactly the thing #419 exists to prevent. Its own negative control is `--mutate-evidence`, which must unregister a gate, delete a recorded control, and substitute a pre-dated disposition for a real transcript — detecting all three, and re-checking the unmutated inputs green in the same run so an always-red detector cannot pass for one.
167:Exit criterion: `bash test/meter-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it is Meter's first task, before any member is fixed — that ordering is the Litmus and Nightwatch precedent, and it is the whole reason both releases could tell a finished entry from a claimed one. Two halves, same shape as Nightwatch's: Half A audits the frozen manifest (each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below) and Half B EXECUTES the cases rather than auditing them — a run against a red-suite target proceeds under a recorded baseline and halts on a *new* failure; a budget-exhausted builder is escalated as budget-exhausted rather than pre-advance-failed; an untrusted target is reported before the first paid turn rather than after; a phase boundary records memory and swap; and a re-fire of an already-satisfied phase runs only the gate and says so. Its own negative control is `--mutate-evidence`, which must unregister a gate and delete a recorded control in a fixture copy, detect both, and re-check the unmutated inputs green in the same run. **RE-SCOPED 2026-08-15 with the release.** The command is unchanged and the two-half shape is unchanged — that shape is the reason Litmus and Nightwatch could tell a finished entry from a claimed one, and it is retained deliberately. What changed is what the halves measure, because a gate that audits a manifest which no longer exists is not a gate. **Half A audits the launch artifact**: the sanitized clone exists at the declared path and is a repository with exactly one commit; `CHANGELOG.md` is present and byte-identical to this repository's; `.tick/`, `relay-system/` and `temp/` are absent; `PROJECT/` contains the PDDA scaffold and the retained Meter example and nothing else; `LICENSE` and `LICENSE-COMMERCIAL.md` are present and mutually consistent; and the secret scan's recorded result names its tool version and the exact commit it scanned. **Half B EXECUTES the stranger's path rather than auditing it**: a clone taken with no credentials, from the published commit, reaches the documented entry point and completes one supported happy path with no file, token, or environment variable that exists only on the author's machine. Its own negative control, `--mutate-evidence`, is likewise re-pointed: in a fixture copy it must plant a private path in a tracked file, remove `CHANGELOG.md`, and leave a `relay-system/` directory behind, detect all three, and re-check the unmutated inputs green in the same run. **The gate is RED on arrival and is Meter's first task, before any sanitization is performed** — same ordering as the two releases that shipped.
169:Manifest-Members: 555 563
182:Exit criterion: `bash test/ballast-release.sh --release-gate` exits 0. **NOT BUILT — writing it is Ballast's first task, before any member is fixed** (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. **Half A audits the frozen manifest:** each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. **Half B EXECUTES the stranger's path rather than auditing it:** (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. **BUILT 2026-08-17.** `test/ballast-release.sh` written and registered in `validate.sh`; suite mode green (`--mutate-evidence` 7/0). Half A: 3 of 4 manifest members complete (#14, #15, #3 — gate/registration/control/CLOSED-issue all confirmed); #4 landed the same day this file was written, so its CLOSED-issue credit is pending the next suite run. Half B's mechanics were smoke-tested end-to-end (all four sub-checks — B1/B2a/B2b/B3 — execute correctly against a real disposable clone) but **`--release-gate` has not yet been run for real** (the full ten-run stranger pass, against a clone cut from the commit that carries all four fixes) — that run is the actual goalpost and is still red pending it, honestly, not silently.
184:Manifest-Members: 14 15 4 3
201:Exit criterion: **NOT WRITTEN.** Required before this release starts, per the ordering Litmus and Nightwatch both used and Meter is repeating — the gate is built first and arrives RED, because a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one.
validate.sh-141-  "gh384-crash-recovery.sh"      # GH-384 (marathon-recover.sh actually DISTINGUISHES a gated phase from an ungated one, in one repo, one run) — 19/0; control in test/baselines/GH-384-negative-control.md is a MUTATION pair (the tool already shipped, so there is no pre-fix revision): detection removed → 2 red, verdict decoupled from the approval event → 1 red. Also pins read-only (tree byte-identical) and the STALE/LIVE lock distinction
validate.sh-142-  "gh388-run-log-durability.sh"  # GH-388 (the harness owns a durable chain run log; a phase KILLED mid-run leaves a content-bearing record; rtl_default_log refuses rather than silently relocating to volatile storage) — 24/0; control in test/baselines/GH-388-negative-control.md: 9 red pre-fix. Part C/D actually kill a running phase and a running chain — a green success path proves nothing on this issue
validate.sh:143:  "gh409-claim-leak.sh"          # GH-409 P2 (a turn that fails releases its claim, on the three paths that never reach rtl_enforce) — 8/0; control in test/baselines/GH-409-negative-control.md: 4 red pre-fix. Every case fails TWICE before asserting, because the cap is 2 and one leak is invisible
validate.sh-144-  "gh438-removal-is-progress.sh" # GH-438 PARTIAL (a removal counts as a phase delta) — 6/0; controls: untouched artifact + newly empty file still rejected. fix_probe re-evaluation NOT covered; issue stays open
validate.sh-145-  "gh438-acceptance-recheck.sh" # GH-438 P2 (the lane's own fix_probes re-read after the build; a still-unfixed probe escalates) — 14/0; controls: fix-really-lands completes, no-contract byte-identical, --dry-run runs none, builder cannot rewrite its own criteria
--
validate.sh-174-  "relay-pkg-freshness.sh"
validate.sh-175-  "skill-extract.sh"
validate.sh:176:  "releases-skill.sh"            # consolidated /releases router + Claude-only symlink migration — 26/0.
validate.sh-177-                                 # RE-REGISTERED 2026-08-15 in the same commit that lands the gate file,
validate.sh-178-                                 # which is the condition its brief unregistration was waiting on. It was
--
validate.sh-221-  "pdda-local-checks.sh"        # the checks the 2026-08-03 PDDA sync deleted, restored outside the sync surface
validate.sh-222-  "gh460-pipe-buffer-sigpipe.sh" # GH-460 (the tier1 "flake" was a SIGPIPE race against the pipe buffer under pipefail, not a flaky assertion) — 8/0; control: the pre-fix shape exits 141 on a >64KB payload whose marker IS present, and passes on a payload that fits
validate.sh:223:  "gh284-p3-release-milestone.sh" # GH-284 P3 (RELEASES.md Milestone: join key + the releases check's first test)
validate.sh-224-  "gh284-p4-release-lanes.sh"   # GH-284 P4 (milestone seed + landed-on-trunk rollup: scope-claim matcher)
validate.sh-225-  "swarm-preflight.sh"
--
utils/pdda/pdda.sh-644-
utils/pdda/pdda.sh-645-# ------------------------------------------------------------------------------------------------
utils/pdda/pdda.sh:646:# J. releases (warn-only nudge; never blocks, even in full)
utils/pdda/pdda.sh-647-# ------------------------------------------------------------------------------------------------
utils/pdda/pdda.sh-648-# Validates RELEASES.md, the single forward-looking release-planning ledger (see PROJECT/PDDA.md
--
utils/pdda/pdda.sh-655-#   (4) warn  — Iterations is set but isn't a well-formed "<lo>-<hi>" version band
utils/pdda/pdda.sh-656-#   (5) warn  — a block's version falls inside another block's reserved Iterations band
utils/pdda/pdda.sh:657:check_releases() {
utils/pdda/pdda.sh-658-  pdda_reset_counts
utils/pdda/pdda.sh:659:  local CHECK_NAME="pdda-check-releases" rc=0
utils/pdda/pdda.sh-660-  local RELEASES_FILE_EFF="${PDDA_RELEASES_FILE:-$PDDA_REPO_ROOT/RELEASES.md}"
utils/pdda/pdda.sh-661-  local release status target_date codename description gh_url line_no target_epoch today_epoch
--
utils/pdda/pdda.sh-674-  # guard exists because the here-doc loops below would otherwise see one empty line and fake a
utils/pdda/pdda.sh-675-  # "block near line 0 has no version" error; it deliberately records NO finding of its own.
utils/pdda/pdda.sh:676:  rows="$(pdda_releases_list "$RELEASES_FILE_EFF")"
utils/pdda/pdda.sh-677-  if [ -z "$rows" ]; then
utils/pdda/pdda.sh-678-    pdda_emit_summary "$CHECK_NAME" 0
--
utils/pdda/pdda.sh-780-
utils/pdda/pdda.sh-781-# ------------------------------------------------------------------------------------------------
utils/pdda/pdda.sh:782:# releases-current (read-only roll-up; not part of PDDA_DETERMINISTIC_CHECKS — no findings, no gate)
utils/pdda/pdda.sh-783-# ------------------------------------------------------------------------------------------------
utils/pdda/pdda.sh-784-# A rough, non-authoritative answer to "what release is in progress right now" — for a human, or for
--
utils/pdda/pdda.sh-786-# RELEASES.md parsing itself. Lists every release whose Status is empty or not "Shipped" (Status is
utils/pdda/pdda.sh-787-# free-text and unvalidated, so this is a best-effort filter, not a gate — see PROJECT/PDDA.md).
utils/pdda/pdda.sh:788:cmd_releases_current() {
utils/pdda/pdda.sh-789-  local RELEASES_FILE_EFF="${PDDA_RELEASES_FILE:-$PDDA_REPO_ROOT/RELEASES.md}"
utils/pdda/pdda.sh-790-  local release status target_date codename description gh_url line_no status_lc any=0
--
utils/pdda/pdda.sh-796-  fi
utils/pdda/pdda.sh-797-
utils/pdda/pdda.sh:798:  printf 'PDDA releases-current — in-progress entries in %s\n' "$(pdda_relpath "$RELEASES_FILE_EFF")"
utils/pdda/pdda.sh-799-  while IFS=$'\037' read -r release status target_date codename description gh_url \
utils/pdda/pdda.sh-800-    front_door shakedown license_file iterations milestone line_no; do
--
utils/pdda/pdda.sh-812-    [ -n "$description" ] && printf '    %s\n' "$description"
utils/pdda/pdda.sh-813-    [ -n "$gh_url" ] && printf '    %s\n' "$gh_url"
utils/pdda/pdda.sh:814:  done < <(pdda_releases_list "$RELEASES_FILE_EFF")
utils/pdda/pdda.sh-815-
utils/pdda/pdda.sh:816:  [ "$any" -eq 1 ] || printf '\n(no in-progress releases — every entry is Status: Shipped)\n'
utils/pdda/pdda.sh-817-  return 0
utils/pdda/pdda.sh-818-}
--
utils/pdda/pdda.sh-848-#   - config.sh, which belongs to git-pulse, a separate program. It is not ours and never will be here.
utils/pdda/pdda.sh-849-PDDA_GOV_SHIPPED_DOCS_DEFAULT="utils/pdda/PDDA-INSTALL.md PROJECT/PDDA.md"
utils/pdda/pdda.sh:850:PDDA_GOV_SHIPPED_DOC_REF_EXEMPTIONS_DEFAULT="ROUTER.md AGENTS.md GUIDING-PRINCIPLES.md README.md CLAUDE.md .claude/skills/pdda/SKILL.md .claude/skills/governance-audit/SKILL.md .claude/skills/releases/SKILL.md PROJECT/3-COMPLETED/PDDA-SYNC-TO-OTHER-REPOS.md utils/PDDA-INSTALL.md install.sh templates/ROUTER.target.md test/pdda-doc-health-hooks.sh pdda-sync.sh utils/pdda/pdda-sync.sh utils/pdda/pdda-manifest.sh utils/pdda.sh utils/pdda-lib.sh utils/pdda-doc-ready.sh utils/pdda-catchup.sh config.sh"
utils/pdda/pdda.sh-851-PDDA_GOV_SHIPPED_DOC_ENVVAR_EXEMPTIONS_DEFAULT="PDDA_REGISTRY PDDA_GITPULSE_DIR PDDA_SYNC_MAX_SHRINK"
utils/pdda/pdda.sh-852-
--
utils/pdda/pdda.sh-1231-
utils/pdda/pdda.sh-1232-# Deterministic checks, in the PDDA.md "Suggested hourly schedule" order. Format: "<label> <function>".
utils/pdda/pdda.sh:1233:PDDA_DETERMINISTIC_CHECKS="
utils/pdda/pdda.sh-1234-pdda-check-frontmatter:check_frontmatter
utils/pdda/pdda.sh-1235-pdda-check-status-table:check_status_table
--
utils/pdda/pdda.sh-1240-pdda-stale-working-docs:check_stale
utils/pdda/pdda.sh-1241-pdda-check-issue-doc-sync:check_issue_doc_sync
utils/pdda/pdda.sh:1242:pdda-check-releases:check_releases
utils/pdda/pdda.sh-1243-pdda-check-governance:check_governance
utils/pdda/pdda.sh-1244-"
--
utils/pdda/pdda.sh-1258-  # Quad Concepts is opt-in and orthogonal to the mode: include its check in the suite only when the
utils/pdda/pdda.sh-1259-  # .pdda-quad / PDDA_QUAD lever is enabled, so a default run's output is unchanged when it's off.
utils/pdda/pdda.sh:1260:  local CHECKS="$PDDA_DETERMINISTIC_CHECKS"
utils/pdda/pdda.sh-1261-  if quad_is_enabled; then
utils/pdda/pdda.sh-1262-    CHECKS="$CHECKS
--
utils/pdda/pdda.sh-1378-  stale              flag stale working docs (flag-only; never moves)
utils/pdda/pdda.sh-1379-  issue-doc-sync     flag 2-WORKING/GH-*.md docs drifted from their GitHub issue state (warn-only)
utils/pdda/pdda.sh:1380:  releases           validate RELEASES.md — the release-planning ledger (warn-only nudge)
utils/pdda/pdda.sh:1381:  releases-current   read-only roll-up: RELEASES.md entries whose Status isn't "Shipped" (rough, unvalidated)
utils/pdda/pdda.sh-1382-  governance         repo-root governance-doc (ROUTER/AGENTS/CLAUDE/...) cross-reference + doc/code drift
utils/pdda/pdda.sh-1383-  gh-refresh         refresh the cached GitHub issue-state file issue-doc-sync reads offline (needs gh)
--
utils/pdda/pdda.sh-1405-  stale)            check_stale; exit "$?" ;;
utils/pdda/pdda.sh-1406-  issue-doc-sync)   check_issue_doc_sync; exit "$?" ;;
utils/pdda/pdda.sh:1407:  releases)         check_releases; exit "$?" ;;
utils/pdda/pdda.sh:1408:  releases-current) cmd_releases_current; exit "$?" ;;
utils/pdda/pdda.sh-1409-  governance)       check_governance; exit "$?" ;;
utils/pdda/pdda.sh-1410-  gh-refresh)       exec "$HERE/pdda-gh-refresh.sh" "$@" ;;
81-- A target date no longer fits explicit dependencies or the observed delivery rate.
82-
83-Do not infer shipment from a closed-but-unmerged PR, an issue closure alone, a branch push, a commit
84-on an unmerged branch, or a populated `GH_URL:` that points to a draft.
85-
86:## Discipline and abuse warnings
87-
88-Warn, without blocking, when:
89-
90-- `Description:` exceeds four sentences, becomes multi-paragraph execution history, or duplicates
91-  `CHANGELOG.md`. Recommend a one-to-four-sentence theme and move history to `CHANGELOG.md` and
--
137-Iterations: 1.2.0-1.2.4
138-Status: Draft
139-Target Date: 2026-12-01
140-Codename: Example
141-Description: One coherent release theme in no more than four sentences.
142:Exit criterion: `command --that-proves-the-release` exits 0.
143-Manifest: FROZEN YYYY-MM-DD — #101, #102, #103.
144-GH_URL:
145-Milestone: Example
146-Front-door reviewed: No
147-Shakedown reviewed: No

2026-08-18T16:08:38.249591Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "rg --files | rg 'pdda.*releases|releases.*iteration|release.*milestone' && sed -n '70,165p' skills/releases/SKILL.md && sed -n '1,235p' test/gh284-p3-release-milestone.sh && sed -n '140,230p' RELEASES.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4
 succeeded in 0ms:
test/gh284-p3-release-milestone.sh
- A GitHub Release exists but `GH_URL:` is empty, points elsewhere, or `Status:` contradicts the
  actual publish state.
- `Target Date:` is past while `Status:` is not `Shipped`.
- A block says work is open, absent, or unbuilt while a merged PR, reachable commit, or canonical
  project document proves the opposite.
- Iteration bands overlap or a non-owner release sits inside another block's band.

Treat these as advisory drift signals:

- Recent merged work materially follows a different theme than an active description.
- A manifest contains replaced, duplicated, unrelated, or silently added scope.
- A target date no longer fits explicit dependencies or the observed delivery rate.

Do not infer shipment from a closed-but-unmerged PR, an issue closure alone, a branch push, a commit
on an unmerged branch, or a populated `GH_URL:` that points to a draft.

## Discipline and abuse warnings

Warn, without blocking, when:

- `Description:` exceeds four sentences, becomes multi-paragraph execution history, or duplicates
  `CHANGELOG.md`. Recommend a one-to-four-sentence theme and move history to `CHANGELOG.md` and
  implementation detail to the canonical `PROJECT/**` document.
- `Manifest:` names more than seven issues. The count triggers review, not condemnation.
- A manifest mixes unrelated themes, lacks a fixed denominator, grows without a dated re-scope,
  crosses several release dependencies, or has no runnable/observable exit criterion.
- A block copies an issue inventory that should be represented by the `Milestone:` join key.

Explain which signal fired. Never call a large manifest abusive solely because of its issue count.

## Clean subroutine

1. Default to active/unshipped blocks. Touch a shipped block only when the operator explicitly names
   it.
2. Propose the smallest cleanup that restores the documented shape: compact descriptions, preserve
   theme and dependencies, reduce manifests to a fixed list or milestone pointer, preserve dated
   re-scope decisions, and move historical narrative to `CHANGELOG.md` or execution detail to its
   existing project doc. Never create a new doc merely to shorten the ledger.
3. Record the file hash before preview. Render the exact patch and get one confirmation.
4. Immediately before writing, re-read `RELEASES.md` and compare its hash. If it changed, discard the
   patch, synthesize again, and preview a new patch.
5. Edit only the confirmed blocks. Never reorder unrelated blocks.
6. Run `utils/pdda/pdda.sh releases` and report every finding.

## Plan or update subroutine

1. Apply the admission rule. A block earns a place only when it represents a named arc worth
   planning toward. A restatement of shipped changes belongs only in `CHANGELOG.md`. A version inside
   another block's `Iterations:` band is already accounted for.
2. If no version was supplied, compare the highest bracketed `CHANGELOG.md` version with the highest
   ledger version. Propose the next semantic version and explain the patch/minor/major judgment; let
   the operator override it.
3. Ask only for unanswered fields:
   - status;
   - optional iteration band;
   - target date or blank/TBD;
   - optional codename;
   - optional GitHub milestone title;
   - a one-to-four-sentence description of the theme;
   - optional concise manifest;
   - optional executable or observable exit criterion;
   - optional QA fields (`Front-door reviewed`, `Shakedown reviewed`, `License file`).
4. Draft the flat block below, omitting blank optional fields except `GH_URL:` when publication is
   expected:

```text
Release: 1.2.0
Iterations: 1.2.0-1.2.4
Status: Draft
Target Date: 2026-12-01
Codename: Example
Description: One coherent release theme in no more than four sentences.
Exit criterion: `command --that-proves-the-release` exits 0.
Manifest: FROZEN YYYY-MM-DD — #101, #102, #103.
GH_URL:
Milestone: Example
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes
```

5. Preview the complete new or replacement block and get one confirmation. Re-check the file hash
before writing. Append new blocks after the last block; replace only an explicitly selected existing
block. Never silently edit neighboring blocks.
6. Run `utils/pdda/pdda.sh releases` and report findings.

## Anchor and backfill subroutine

Run only when explicitly requested.

- For `anchor`, draft exactly the shipped versions the operator named. Trace each one-line summary
  to its bracketed `CHANGELOG.md` section and set `Status: Shipped`.
- For `backfill`, show bracketed `CHANGELOG.md` versions that are not already represented and do not
  sit inside an existing iteration band. Present them as an optional menu, never as missing work.
  Draft only the versions the operator selects; drafting none is valid.
- Never initiate either route because the ledger looks incomplete.
#!/usr/bin/env bash
# GH-284 Phase 3 — RELEASES.md gains `Milestone:`, the release -> issue-set join key.
#
# A release must resolve to a SET of issues before it can drive marathon selection, and `GH_URL:`
# holds exactly one link. The linkage lives in GitHub (a milestone), so it maintains itself as issues
# open and close; RELEASES.md carries only the milestone TITLE.
#
# This file is also the first test the `pdda.sh releases` check has ever had — before Phase 3 it had
# none, so the pre-existing behaviors it must not break (empty version -> error, bad date -> warn,
# overdue -> warn, never gates the exit code) are pinned here too, not just the new field.
source "$(dirname "$0")/_setup.sh" gh284-p3-release-milestone
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PDDA="$ROOT/utils/pdda/pdda.sh"

# PDDA_RELEASES_FILE points the check at a fixture instead of the repo's real ledger.
run_releases() {  # <fixture-file>
  PDDA_RELEASES_FILE="$1" PDDA_ACTIVITY_LOG=/dev/null bash "$PDDA" releases 2>&1
}
run_current() {   # <fixture-file>
  PDDA_RELEASES_FILE="$1" PDDA_ACTIVITY_LOG=/dev/null bash "$PDDA" releases-current 2>&1
}
# The Milestone WARNING is this repo's own policy and lives in utils/pdda-local-checks.sh, not in
# the sync-managed upstream script. The 2026-08-03 PDDA sync (cfd56b0) deleted it from pdda.sh —
# upstream carries `Milestone:` as "optional, free-text, unvalidated" — and this test went red for
# ~2 days reading as pre-existing noise. Everything else below still exercises `pdda.sh releases`,
# which is the point: the upstream behaviours must keep working alongside the local check.
LOCAL_CHECKS="$ROOT/utils/pdda-local-checks.sh"
run_milestone() { # <fixture-file>
  PDDA_RELEASES_FILE="$1" PDDA_ACTIVITY_LOG=/dev/null bash "$LOCAL_CHECKS" release-milestone 2>&1
}

# ── (1) the new warning fires on a dated, unshipped release with no Milestone ────────────
F="$WORK/no-milestone.md"
cat > "$F" <<'EOF'
Release: 1.0.0
Status: Draft
Target Date: 2999-01-01
Codename: Testcodename
Description: no milestone here
GH_URL:
EOF
out="$(run_milestone "$F")"; rc=$?
printf '%s' "$out" | grep -F "no 'Milestone:'" >/dev/null \
  && pass "dated unshipped release with no Milestone is warned" \
  || fail "expected a missing-Milestone warning, got: $out"
printf '%s' "$out" | grep "^WARN" >/dev/null \
  && pass "the missing-Milestone finding is a WARN, not an error" \
  || fail "missing-Milestone should be warn severity: $out"
[ "$rc" -eq 0 ] && pass "the check still never gates the exit code" \
  || fail "releases check must never block (exit $rc)"

# ── (2) supplying the Milestone silences it ──────────────────────────────────────────────
F="$WORK/with-milestone.md"
cat > "$F" <<'EOF'
Release: 1.0.0
Status: Draft
Target Date: 2999-01-01
Codename: Testcodename
Description: has a milestone
GH_URL:
Milestone: Quicksilver
EOF
out="$(run_milestone "$F")"
printf '%s' "$out" | grep -F "no 'Milestone:'" >/dev/null \
  && fail "Milestone was present but the warning still fired: $out" \
  || pass "a populated Milestone silences the warning"

# ── (3) scoping: undated and shipped blocks stay quiet ───────────────────────────────────
# The example/placeholder block has no Target Date; backfilling history buys nothing.
F="$WORK/quiet.md"
cat > "$F" <<'EOF'
Release: 0.1.0
Status: Draft
Target Date:
Codename: n/a
Description: placeholder, no date
GH_URL:

Release: 0.9.0
Status: Shipped
Target Date: 2000-01-01
Codename: Ancient
Description: already out, never had a milestone
GH_URL:
EOF
out="$(run_milestone "$F")"
printf '%s' "$out" | grep -F "no 'Milestone:'" >/dev/null \
  && fail "undated/shipped blocks must not be warned about: $out" \
  || pass "undated and Shipped blocks are exempt from the Milestone warning"

# ── (4) the pre-existing behaviors this check already had must survive ───────────────────
F="$WORK/legacy.md"
cat > "$F" <<'EOF'
Release:
Status: Draft
Target Date:
Codename: n/a
Description: empty version
GH_URL:
Milestone: X

Release: 2.0.0
Status: Draft
Target Date: not-a-date
Codename: n/a
Description: malformed date
GH_URL:
Milestone: X

Release: 3.0.0
Status: Draft
Target Date: 2000-01-01
Codename: n/a
Description: overdue and unshipped
GH_URL:
Milestone: X
EOF
out="$(run_releases "$F")"; rc=$?
printf '%s' "$out" | grep -F "has no version" >/dev/null \
  && pass "empty Release: version still reported" \
  || fail "empty-version error regressed: $out"
printf '%s' "$out" | grep -F "is not a valid YYYY-MM-DD date" >/dev/null \
  && pass "malformed Target Date still warned" \
  || fail "bad-date warning regressed: $out"
printf '%s' "$out" | grep -F "overdue" >/dev/null \
  && pass "overdue unshipped release still warned" \
  || fail "overdue warning regressed: $out"
[ "$rc" -eq 0 ] && pass "an error finding still does not gate the exit code" \
  || fail "the releases check must stay warn-only in spirit (exit $rc)"

# ── (5) the roll-up surfaces the join key, and says so when it is missing ────────────────
F="$WORK/rollup.md"
cat > "$F" <<'EOF'
Release: 4.0.0
Status: Draft
Target Date: 2999-01-01
Codename: Withkey
Description: has one
GH_URL:
Milestone: Quicksilver

Release: 5.0.0
Status: Draft
Target Date: 2999-01-01
Codename: Withoutkey
Description: has none
GH_URL:
EOF
out="$(run_current "$F")"
printf '%s' "$out" | grep -F "Milestone: Quicksilver" >/dev/null \
  && pass "releases-current prints the milestone when set" \
  || fail "roll-up did not show the milestone: $out"
# The roll-up's explicit "(none — release cannot resolve to an issue set)" line was ALSO deleted by
# the cfd56b0 sync: upstream's `releases-current` now prints the Milestone line only when set, so a
# missing one is rendered as absence. This assertion was masked until case (1) was fixed — the file
# fail-fasted before reaching it. The requirement it encodes ("a missing milestone is never silent")
# is preserved by the local check, which names the offending release; the roll-up no longer does.
# Restoring the roll-up line belongs upstream, not in a file the next sync overwrites.
out_ms="$(run_milestone "$F")"
printf '%s' "$out_ms" | grep -F "release '5.0.0' has a Target Date but no 'Milestone:'" >/dev/null \
  && pass "a milestone-less release is still named explicitly (by the local check, not the roll-up)" \
  || fail "a missing milestone became silent in BOTH the roll-up and the check: $out_ms"
printf '%s' "$out_ms" | grep -F "release '4.0.0'" >/dev/null \
  && fail "the release that HAS a milestone was wrongly flagged: $out_ms" \
  || pass "the release carrying a milestone is not flagged"

# ── (6) the field must not shift the other parsed fields ─────────────────────────────────
# Milestone was appended to a \037-delimited record. A mis-ordered read would silently hand
# `line_no` to `milestone` (or vice versa) and every assertion above could still pass by accident.
F="$WORK/ordering.md"
cat > "$F" <<'EOF'
Release: 6.0.0
Status: Draft
Target Date: 2999-01-01
Codename: Ordercheck
Description: DESCRIPTION-SENTINEL
GH_URL: GHURL-SENTINEL
Milestone: MILESTONE-SENTINEL
EOF
out="$(run_current "$F")"
printf '%s' "$out" | grep -F "DESCRIPTION-SENTINEL" >/dev/null \
  && pass "Description still lands in the Description slot" \
  || fail "field ordering broke: Description missing from $out"
printf '%s' "$out" | grep -F "GHURL-SENTINEL" >/dev/null \
  && pass "GH_URL still lands in the GH_URL slot" \
  || fail "field ordering broke: GH_URL missing from $out"
printf '%s' "$out" | grep -F "Milestone: MILESTONE-SENTINEL" >/dev/null \
  && pass "Milestone lands in its own slot, not shifted" \
  || fail "field ordering broke: Milestone missing or shifted in $out"

# ── (7) the repo's own ledger satisfies the contract it just documented ──────────────────
# Against `pdda.sh releases` this assertion is now UNFALSIFIABLE — upstream emits no Milestone
# warning at all, so "no warning fired" would be true for any ledger, including a broken one. It runs
# against the local check, which is the only thing that can still produce the string it greps for.
out="$(PDDA_ACTIVITY_LOG=/dev/null bash "$LOCAL_CHECKS" release-milestone 2>&1)"
printf '%s' "$out" | grep -F "no 'Milestone:'" >/dev/null \
  && fail "this repo's own RELEASES.md has a dated release with no Milestone: $out" \
  || pass "the repo's RELEASES.md carries a Milestone for every dated, unshipped release"

echo "  gh284-p3-release-milestone: $PASS pass, $FAIL fail"
exit 0
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes

Release: 0.5.0
Iterations: 0.5.0-0.5.4
Status: Draft
Target Date: 2026-12-12
Codename: Lantern
Description: When the harness fails, the information needed to act already exists inside it — make it say so. Not "add checks": every case was already detected, and some were then described wrongly (a stack trace, a fabricated path, a success exit code, silence). Scope is one epic, deliberately narrow, and deliberately NOT Nightwatch: that milestone owns run lifecycle "even when lifecycle code emits a misleading message" (see the scope boundary above), and none of Lantern's cases violates a lifecycle invariant — they violate the legibility of a failure whose lifecycle handling was already correct. All four members were found in one afternoon during Nightwatch wave 3, which halted three times at zero paid-turn cost; each halt was avoidable from information the system already held. Depends on nothing; independent of Plumbline.
Exit criterion: `bash test/lantern-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it precedes fixing any member, which is the Litmus and Nightwatch ordering and the reason both releases could tell a finished entry from a claimed one. Two halves, the established shape: Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below. Half B **executes** #499's four phases rather than auditing them, since every one of them is a message an operator either receives or does not: a `relay-drive` launch preflight that refuses before spending, a gate refusal that states its real reason, a launcher exit code that survives its wrapper, and a change-impact report. **#358 Phase 2 is the one member with no executable half, and the criterion is written around that rather than pretending otherwise:** it is satisfied by a RECORDED transcript of a real CI failure under `test/baselines/`, and it must NOT be satisfiable by a disposition written in advance — that issue's own capture doc forbids pre-committing one, and an exit criterion that accepted a pre-written verdict would launder exactly the thing #419 exists to prevent. Its own negative control is `--mutate-evidence`, which must unregister a gate, delete a recorded control, and substitute a pre-dated disposition for a real transcript — detecting all three, and re-checking the unmutated inputs green in the same run so an always-red detector cannot pass for one.
Manifest: FROZEN at one issue on creation — #499, which supersedes and closes #494, #495, #496 and #498. Four phases, each shippable alone: relay-drive launch preflight; a gate refusal that states its real reason; a launcher whose exit code survives plus a gate-readiness check; and a change-impact reporter. Freezing at one is the whole point — these were filed as four and unified precisely to stop a single coherent change spreading across four PRs. **RE-FROZEN AT TWO on 2026-08-11 by explicit operator decision — #499, plus #358 Phase 2.** Recorded as a re-scope rather than an edit, because the admission rule below is worthless if a manifest can grow quietly: the operator named the entry and the release, which is the documented way past the rule, and this line says so with a date instead of just showing two items where there was one. It is a genuine fit, not a parking space — Phase 2 is a *disposition* that turns a lost concurrent-append record into a failure naming its own terminal lock state, which is Lantern's subject exactly, whereas the run lifecycle it sits inside was already handled correctly (that is the Nightwatch boundary, and it is why Phase 1 belonged there and Phase 2 does not). It was briefly a Meter member the same day and moved here before either release started; Meter's block records the move from its side. **#358 keeps its Nightwatch milestone** — it is a frozen entry counted in Nightwatch's RC evidence, so only its scope moved, and this is the second Lantern member not enumerable by `gh issue list --milestone Lantern`. Adding a further member is a RE-SCOPE, not a bugfix, per the Litmus rule above.
GH_URL: [GH 499](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/499)
Milestone: not created yet. The original reason — "#499 is unmilestoned by design while Nightwatch is the active goalpost" — expired when Nightwatch reached RC on 2026-08-11, and is kept here only so a reader does not act on it as if current. Creating it is a live decision, not a formality: **neither member would be enumerable by it as things stand** (#499 is unmilestoned, and #358 keeps its Nightwatch milestone deliberately), so the milestone would join nothing until #499 is assigned. The `Manifest:` line below is this release's authoritative scope either way.
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes

Release: 0.6.0
Iterations: 0.6.0-0.6.4
Status: Draft
Target Date: 2026-09-26
Codename: Meter
Description: A run accounts for what it spends and checks what it requires before spending it. Every member was found the same way — a real unattended marathon against `Hypercart-Dev-Tools/rebalance-OS` — and each one costs the operator something no gate ever reports: ten ready lanes blocked by two unrelated pre-existing test failures (#378); a builder killed by a $0.50 budget and escalated as a failed pre-advance gate, its `terminal_reason: budget_exhausted` left in an unreferenced temp file (#379); 108 of the target's own `permissions.allow` grants silently dropped because the directory was never trusted interactively, invisible in preflight, stdout and the escalation alike (#380); a host kernel-panicked under memory pressure while the run's telemetry reported tokens and wall-clock and nothing about memory (#382); and three codex builds plus three agy reviews spent re-running work the driver already had, because the cheap gate-only path exists but nothing points at it and `--retry` silently takes the expensive one (#491). Depends on Nightwatch — #382's numbers need a durable place to land, which is exactly what Nightwatch built. Independent of Plumbline and Lantern.
**RE-SCOPED 2026-08-15 by explicit operator decision — Meter is now the public-repository release candidate, and the paragraph above describes what Meter *was*.** The new sentence is: **XYZ can be handed to a stranger.** An unauthenticated clone reaches a documented entry path and exercises a supported happy path with no private context, from a tree that has been sanitized and secret-scanned. The metering work was not abandoned and it was not finished — five of its seven entries moved intact to Sundown (0.8.0), where they keep their capture docs, their acceptance criteria and their evidence. Recorded here as a re-scope with a date rather than presented as a release that always meant this, because a codename that quietly changes its subject is the same defect as a manifest that quietly grows. The reason for reusing Meter rather than opening an eighth release is that the operator named it: publication is the next thing that happens to this repository, and a launch release parked behind five unrelated engineering entries would have shipped late for reasons that have nothing to do with whether a stranger can clone it.
Publication target — **the deliverable is a sanitized clone, not this repository.** The public artifact is a new working tree cut from `development`, stripped of runtime state and internal working documents, committed as **fresh history with a single initial commit**, and pushed to **https://github.com/HiQS-Suite/XYZ-forge** — a new repository in a different organization, named by the operator on 2026-08-15, which becomes XYZ's permanent home. `CHANGELOG.md` is carried forward verbatim and is the public record of the project's history — it is a *file*, so it survives a fresh-history cut intact, and carrying 2,147 commits was rejected on 2026-08-15 for a stated reason: every document removed during sanitization stays reachable in a carried history, which makes the full-history secret scan this release requires a scan of everything ever deleted rather than a scan of one tree. Fresh history makes the sanitization complete by construction. `.tick/` (161 MB of runtime event state) and `relay-system/` (32 MB of relay transcripts) do not ship. `PROJECT/` ships as an **empty PDDA scaffold** plus the Meter build documents retained deliberately as a worked example of how PDDA is used — the method travels, the backlog does not.
Scope boundary — Meter vs Lantern: **Lantern owns how a failure is described; Meter owns what a run consumed and what it required.** Route by asking whether the issue names a *resource or a precondition* — dollars, turns, memory, swap, a trusted directory, a green suite — or names *the wording of a verdict whose handling was already correct*. Written down because two members straddle it and the file already has one recorded case (Litmus vs Nightwatch, 2026-08-08) of two descriptions that a competent agent could not route between. **#379 is split by that rule and belongs to both:** the overloaded exit 5 is a Lantern-shaped naming defect, the budget itself is a Meter resource, and the scope boundary above says to split an issue that violates both rather than argue it into one. **#491 is the marginal call and is placed here deliberately** — the re-scoped defect is a help-text and discoverability gap, which reads Lantern, but the invariant it violates is that the harness re-spends paid turns whose results it already holds, and the issue's evidence is a cost measurement.
Exit criterion: `bash test/meter-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it is Meter's first task, before any member is fixed — that ordering is the Litmus and Nightwatch precedent, and it is the whole reason both releases could tell a finished entry from a claimed one. Two halves, same shape as Nightwatch's: Half A audits the frozen manifest (each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below) and Half B EXECUTES the cases rather than auditing them — a run against a red-suite target proceeds under a recorded baseline and halts on a *new* failure; a budget-exhausted builder is escalated as budget-exhausted rather than pre-advance-failed; an untrusted target is reported before the first paid turn rather than after; a phase boundary records memory and swap; and a re-fire of an already-satisfied phase runs only the gate and says so. Its own negative control is `--mutate-evidence`, which must unregister a gate and delete a recorded control in a fixture copy, detect both, and re-check the unmutated inputs green in the same run. **RE-SCOPED 2026-08-15 with the release.** The command is unchanged and the two-half shape is unchanged — that shape is the reason Litmus and Nightwatch could tell a finished entry from a claimed one, and it is retained deliberately. What changed is what the halves measure, because a gate that audits a manifest which no longer exists is not a gate. **Half A audits the launch artifact**: the sanitized clone exists at the declared path and is a repository with exactly one commit; `CHANGELOG.md` is present and byte-identical to this repository's; `.tick/`, `relay-system/` and `temp/` are absent; `PROJECT/` contains the PDDA scaffold and the retained Meter example and nothing else; `LICENSE` and `LICENSE-COMMERCIAL.md` are present and mutually consistent; and the secret scan's recorded result names its tool version and the exact commit it scanned. **Half B EXECUTES the stranger's path rather than auditing it**: a clone taken with no credentials, from the published commit, reaches the documented entry point and completes one supported happy path with no file, token, or environment variable that exists only on the author's machine. Its own negative control, `--mutate-evidence`, is likewise re-pointed: in a fixture copy it must plant a private path in a tracked file, remove `CHANGELOG.md`, and leave a `relay-system/` directory behind, detect all three, and re-check the unmutated inputs green in the same run. **The gate is RED on arrival and is Meter's first task, before any sanitization is performed** — same ordering as the two releases that shipped.
Manifest: FROZEN 2026-08-11 on creation — #378, #379, #380, #382, #491. **RE-SCOPED TO SIX on 2026-08-12 by explicit operator decision: #509 admitted.** **RE-SCOPED TO SIX on 2026-08-14 (second decision the same day): #509 RETIRED as complete.** Its two unchecked criteria are not unfinished work — they are blocked by a LATER deliberate decision, GH-544, which retired hosted CI for the private phase. *"A push cannot cancel a running workflow_dispatch boundary run"* is now vacuously true and permanently unwitnessable: `ci.yml` carries only `workflow_dispatch:`, so no push can start a run, and you cannot control-test an interaction between two triggers when one of them no longer exists. *"A green hosted macOS full run exists for a chosen commit"* cannot be satisfied without spending the Actions minutes #509 existed to stop and #544 formally stopped. GH-544 already records that debt in its own terms and owns the re-arm trigger (the repo goes public), so keeping #509 open under Meter tracked the same gap twice while making the manifest look one item larger than it is. Phases 1-5 shipped. **RE-SCOPED TO SIX on 2026-08-14 by explicit operator decision: #551 admitted, and the target date pulled in from 2027-01-16 to 2026-09-26 in the same decision.** Recorded as a dated re-scope for the third time rather than shown as a list that has always had seven — the admission rule is worthless if a manifest can grow quietly, and it is worth as little if the third growth is the one that stops being announced. #551 is the shared root cause under nine open issues (#272, #310, #329, #365, #395, #504, #548, plus the already-closed #314/#440/#549) in which a resolver that cannot determine its answer returns a plausible default instead of refusing. It is a genuine fit on this block's own routing question — it names a **precondition**, not a description of a failure, so it is Meter and not Lantern — and two of its nine (#380, #491) were already Meter members, which is what surfaced it: they were being worked as separate defects when they are one. **RE-SCOPED TO SEVEN on 2026-08-15 by explicit operator decision: #555 admitted.** Recorded as a dated re-scope for the fourth time. #555 is the release's own exit criterion — the prerequisite for the other six being verifiable — so it ships first. The seven frozen manifest entries are #378, #379, #380, #382, #491, #551, and #555. **The date moved because Nightwatch shipped.** This release's only dependency was Nightwatch (#382's numbers needed a durable place to land), that shipped 2026-08-14, and Meter has been unblocked since — January was a date set while its blocker was still open and never revisited when the blocker cleared. Adding a further member is a RE-SCOPE, not a bugfix, under the unchanged rule below. Recorded as a re-scope with a date rather than shown as a list that has always had six, because the admission rule below is worthless if a manifest can grow quietly. It is a genuine fit, not a parking space: GH-509 is CI minute burn and route correctness — what a run costs and what it checks before spending — which is this release's sentence almost verbatim. The operator named the entry and the release, which is the documented way past the rule. Its plan is `PROJECT/2-WORKING/GH-509-CI-MINUTE-BURN.md`, replanned the same day on the macOS-target reframe and reviewed by agy. All six are milestoned Meter, so the ledger and `gh issue list --milestone Meter` cannot drift apart. **#358 Phase 2 was a member for part of 2026-08-11 and was moved to Lantern by operator decision the same day, before any Meter work began.** Recorded rather than quietly dropped: a frozen manifest whose membership changes without a trace is not frozen, and the honest version of "we got the routing wrong for an afternoon" is a dated line, not a clean list. It was the only entry blocked on an *observation* rather than on work, and the only one with no executable half — both of which now sit in Lantern's exit criterion, which is where the reasoning for them lives. The move is also correct on the boundary this block defines: Phase 2 produces a failure that states its own reason, which is Lantern's subject, not a resource or a precondition. Adding an entry is a RE-SCOPE, not a bugfix, under the same admission rule Litmus and Nightwatch used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission. **RE-SCOPED TO TWO on 2026-08-15 by explicit operator decision — the fifth dated re-scope of this manifest, and the only one that replaces the release's subject rather than extending it.** The seven engineering entries are dissolved. **#380 is CLOSED and shipped under the original scope**; it stays milestoned Meter as delivered work and is not a launch member — retiring a manifest does not un-ship what it produced. **#378, #379, #382, #491 and #551 move intact to Sundown (0.8.0)**, keeping their capture docs, their verbatim acceptance criteria and their milestone history; none of them was dropped, deferred without a home, or quietly closed. **#546 moves with them as Sundown backlog** — it was Meter milestone backlog and never a manifest entry, and it follows the subject it belongs to rather than the codename it happened to sit under. **The two frozen launch entries are #555 and #563.** #555 is the release's own exit criterion, re-pointed by the paragraph above and unchanged in its role: it ships first and it arrives RED. #563 is the launch checklist authored by an external reviewer (Codex Sol High) and covers the release boundary, public onboarding and behavior, the secret and privacy review, and the legal/CI/publication sequence. Freezing at two is the Plumbline precedent (frozen at one on creation) and is deliberate: the checklist was written as one coherent cutover and splitting it across issues is exactly what that precedent exists to prevent. **Scope is CLOSED to further admission by explicit operator instruction on 2026-08-15** — no issue filed after this date joins this manifest, and the standing admission rule below is superseded for this release only, because a launch whose scope can still grow does not have a date. Anything discovered during execution is filed, milestoned Sundown or left unmilestoned, and **waived in writing per #563's rule: a waiver names the failed criterion, the owner, the reason and the follow-up issue — silence is not a waiver.** Two known open items are covered by that rule rather than admitted: **#564** (31 unaudited suites that can reach the caller's clone through an empty fixture path) and **#544**'s re-arm debt (hosted CI fires on nothing while the repository is private, and going public is its own documented trigger). Both bear on publication and neither is a launch member; both need a waiver or a fix before the gate is called green.
Manifest-Members: 555 563
GH_URL: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/563
Milestone: Meter
Front-door reviewed: Yes
Shakedown reviewed: Yes
License file: Yes

Release: 0.7.0
Iterations: 0.7.0-0.7.4
Status: Draft
Target Date: 2026-09-12
Codename: Ballast
Description: Post-launch hardening: **the launched repository holds up under a stranger's first run and an outside contributor's first push.** Every member was found the same way — by pointing the launch machinery at its own published output: the first fresh-clone runs of the public repository produced a different failing set each time (#15), a push gate that does not travel with clones got worse the moment the repo went public (#4), and the kernel's own event log can drop events on the concurrent path the kernel exists to coordinate (#14). Ballast exists because publication moved the failure surface from "our machines" to "everyone else's", and nothing in the shipped tree tests that surface. Builds on Meter's publication; depends on nothing unshipped.
Exit criterion: `bash test/ballast-release.sh --release-gate` exits 0. **NOT BUILT — writing it is Ballast's first task, before any member is fixed** (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. **Half A audits the frozen manifest:** each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. **Half B EXECUTES the stranger's path rather than auditing it:** (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. **BUILT 2026-08-17.** `test/ballast-release.sh` written and registered in `validate.sh`; suite mode green (`--mutate-evidence` 7/0). Half A: 3 of 4 manifest members complete (#14, #15, #3 — gate/registration/control/CLOSED-issue all confirmed); #4 landed the same day this file was written, so its CLOSED-issue credit is pending the next suite run. Half B's mechanics were smoke-tested end-to-end (all four sub-checks — B1/B2a/B2b/B3 — execute correctly against a real disposable clone) but **`--release-gate` has not yet been run for real** (the full ten-run stranger pass, against a clone cut from the commit that carries all four fixes) — that run is the actual goalpost and is still red pending it, honestly, not silently.
Manifest: FROZEN 2026-08-16 on creation — #14, #15, #4, #10, #3. Five entries, a fixed denominator rather than a percentage. Same admission rule Litmus and Nightwatch used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission. **#14 and #15 SHIPPED 2026-08-17** (PR #21, PR #20; each closed with evidence — atomic-write negative control, 10/10 consecutive parallel fresh-clone runs). **#3 SHIPPED 2026-08-17**: the durable-default and path-printing halves were already landed pre-freeze (GH-430); the sole remaining gap, a recorded negative control, closed the same day (`test/baselines/GH-3-state-dir-negative-control.md`) — closed as landed, not re-scoped or swapped. **#10 CUT 2026-08-17, invoking its own pre-declared contingency**: a driven marathon attempt (builder agy, reviewer codex, round-cap 5) escalated after 5 rounds without landing — the suite count the fix would need to touch grew from the estimated ~31 to 73 with zero mechanically adopted, and the builder self-issued a scope waiver rather than flagging the blocker back to the orchestrator. This is exactly the scope-slip the freeze anticipated ("#10 is the designated cut if scope slips... #1's clone-identity bracket already covers the same ground *detectably* in the meantime"); cut per that pre-authorized contingency rather than re-fired. Issue #10 stays open, un-closed by this cut — the underlying containment gap remains real, just descoped from Ballast. Manifest reduced from 5 to 4 entries; this is a recorded re-scope, not a silent drop.
Manifest-Members: 14 15 4 3
Explicit non-goals, stated so they are not silently absorbed: #16 (hosted CI re-arm — tracked separately, explicitly NOT in scope, the local pre-push gate stays the only gate), #9 (tooling floor: eslint/prettier, src/ coverage, decompositions), #11 (Sundown twin retirement), #12 (tree diet), #13 (fold scaling — its body was corrected 2026-08-16: it claimed event append is already atomic temp+rename, which was never true; #14 owns making it so).
GH_URL:
Milestone: Ballast
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes

Release: 0.8.0
Iterations: 0.8.0-0.8.4
Status: Draft
Target Date: 2026-10-17
Codename: Sundown
Description: Retire the twelve frozen Bash twins. Three steps, in order: (1) sweep for real `XYZ_PYTHON=0` usage — if nothing sets it, the fallback is already dead in practice; (2) re-vendor every fleet `.xyz/` copy onto the Python lane (`xyz-sync.sh list` is the worklist); (3) delete the twins and retire the GH-308 edit-guard, keeping only its no-new-Bash half (GH-551). Not before steps 1-2: the vendored fleet still runs the Bash path, and `XYZ_PYTHON=0` is the documented rollback. Depends on nothing in Meter.
**WIDENED 2026-08-15 by explicit operator decision — Sundown receives Meter's five engineering entries.** The release's sentence becomes: **the harness accounts for what it spends, checks what it requires before spending it, and stops carrying the retired Bash lane.** Said plainly rather than argued into one theme: the twin retirement and the metering work are two subjects sharing one release, and they are here together because Meter was re-pointed at publication on 2026-08-15 and these five needed a home that was not a parking space. They arrive intact — same capture docs under `PROJECT/2-WORKING/`, same verbatim acceptance criteria, same evidence — and the honest reading of the widening is that Sundown's date is now less trustworthy than it was, because it absorbed five entries without absorbing any schedule.
**RENUMBERED 0.7.0 → 0.8.0 on 2026-08-16 by explicit operator decision, to open 0.7.0 for Ballast.** Nothing about this release changed except its version: same codename, same target date, same manifest, same milestone. The band moves with it (`0.7.0-0.7.4` → `0.8.0-0.8.4`) because a release's iteration band is part of its identity here, not a separate fact. Recorded as a dated line rather than shown as a block that was always 0.8.0, on the same principle the manifest re-scopes above follow: a version that changes without a trace is indistinguishable from one that was misread. The `(0.7.0)` parentheticals in Meter's re-scope paragraphs were swept to `(0.8.0)` in the same edit — they identify *which release received the transfer*, so leaving them stale would have pointed a reader at a version that no longer exists. `CHANGELOG.md`'s existing entry is **not** swept: it is the append-only record of what was decided on 2026-08-15, when Sundown was 0.7.0, and the renumber is recorded there as its own dated entry instead.
Manifest: **#378, #379, #382, #491, #551**, received from Meter 2026-08-15, plus the twin-retirement work described above, which remains unnumbered until its issues are filed. **#546 is milestone backlog, not a manifest entry** — it followed the metering subject here and does not gate this release, under the standing rule that discovery is not admission. **Not yet frozen.** Freezing requires the twin-retirement issues to exist so the manifest is a fixed denominator rather than a list plus a promise; until then this line is a receipt for the transfer, not a contract. #380 did not move: it is CLOSED and shipped under Meter's original scope, and stays milestoned there.
Exit criterion: **NOT WRITTEN.** Required before this release starts, per the ordering Litmus and Nightwatch both used and Meter is repeating — the gate is built first and arrives RED, because a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one.
GH_URL: pending — api.github.com DNS outage 2026-08-14; file on recovery
Milestone: Sundown
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes

2026-08-18T16:08:43.084277Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
web search: 
web search: https://github.com/HiQS-Suite/XYZ-forge/issues/28
2026-08-18T16:08:46.927302Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
web search: 
web search: site:github.com/HiQS-Suite/XYZ-forge/issues/28 "RELEASES.md"
2026-08-18T16:08:50.407214Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "git remote -v && gh issue view 28 --repo HiQS-Suite/XYZ-forge --json number,title,state,body,comments --jq '{number,title,state,body,comments:[.comments[]|{author:.author.login,body:.body}]}'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4
2026-08-18T16:08:56.953634Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
 succeeded in 404ms:
{"body":"## Problem\n\n`RELEASES.md` is meant to be ~90% pointers/manifest, per its own contract (`PROJECT/PDDA.md` → \"RELEASES.md — release ledger\", enforced narratively by `skills/releases/SKILL.md`'s \"Discipline and abuse warnings\"). In practice it keeps ballooning with execution-history prose (status appendices, run logs, dated notes) stuffed directly into `Description:`/`Exit criterion:`/`Manifest:` fields.\n\n**Concrete instance (Ballast 0.7.0, 2026-08-17):** a long status appendix was added directly to the `Exit criterion:` field during release-gate work — exactly the violation `skills/releases/SKILL.md` already warns against.\n\n## Root cause\n\nTwo gaps, not one:\n\n1. **No enforcement teeth.** The discipline rubric (Description ≤4 sentences, Manifest ≤7 issues, no execution-history prose) exists only as English prose inside `skills/releases/SKILL.md`, and only fires when someone explicitly runs `/releases clean`. The deterministic checker, `check_releases()` in `utils/pdda/pdda.sh`, validates structure (version present, date format, QA yes/no fields) but has **zero** bloat checks, and is deliberately warn-only by design (never blocks, per `PROJECT/PDDA.md` section J).\n2. **No other legitimate home for release-level notes.** Manifest members each get their own GH issue, but the release ledger entry itself (e.g. \"Ballast 0.7.0\") has none — so status/run-log notes go inline in `RELEASES.md` by necessity, not laziness.\n\n## Validation scan (2026-08-18, ad-hoc, against live RELEASES.md)\n\nRan the proposed checks against all 7 real blocks before writing any code. Results:\n\n| Release | Description \u003e4 sentences | Manifest-Members \u003e7 tokens | Exit criterion length |\n|---|---|---|---|\n| 0.1.0 Quicksilver | clean | — (no field) | clean |\n| 0.2.0 Litmus | clean | — | 592 chars / 6 sentences |\n| 0.3.0 Nightwatch | 6 sentences | — | 2007 chars / 9 sentences |\n| 0.4.0 Plumbline | 5 sentences | — | clean |\n| 0.5.0 Lantern | 5 sentences | — | 1544 chars / 6 sentences |\n| 0.6.0 Meter | 17 sentences | 2 (clean) | 2718 chars / 10 sentences |\n| 0.7.0 Ballast | clean | 4 (clean) | 2470 chars / 10 sentences |\n| 0.8.0 (next) | 11 sentences | — | clean |\n\nTwo findings that change the plan:\n\n- **Manifest size is not the problem.** Only two blocks (0.6.0, 0.7.0) even use `Manifest-Members:`, and both are clean (2 and 4 tokens). The real bloat is entirely in `Description:` and `Exit criterion:`, and it's near-universal — 6 of 8 blocks trip the Description check, not just Ballast.\n- **\"Spans multiple lines\" is the wrong signal for Exit criterion/Manifest.** Every field in the file is one long wrapped physical line, never literally multi-line. A line-count check would catch **nothing**. Dropping this in favor of a length/sentence threshold on `Exit criterion:` (mirroring the existing Description rule) — clean blocks sit at 0-592 chars, bloated ones start at 1544+ chars / 6+ sentences.\n\n## Revised proposed fix (lightest viable — no new skill)\n\n1. Add a `Tracking Issue:` field to the `RELEASES.md` block spec (`PROJECT/PDDA.md` contract + `skills/releases/SKILL.md` plan-subroutine template). Extends the existing Issue-first SOP to the release ledger itself. Release-level status/run-log notes go there, not inline.\n2. Extend `check_releases()` in `utils/pdda/pdda.sh` with deterministic bloat checks:\n   - `Description:` exceeding 4 sentences (validated signal, confirmed above)\n   - `Exit criterion:` exceeding 4 sentences (replaces the multi-line check — validated to actually catch the observed bloat)\n   - `Manifest-Members:` exceeding 7 tokens (kept for when the field is used; low incidence today but cheap to check)\n3. Ship the new checks **warn-only first**. Run once against live `RELEASES.md`, confirm the hit list matches this scan, then flip to blocking in a follow-up commit — only after existing bloated blocks (6 of 8) are cleaned up or grandfathered, so the feature doesn't land immediately red against its own repo.\n4. `/releases clean`'s existing LLM rubric stays the fix-up drafting tool once a violation is flagged — never the detector.\n\n## Acceptance criteria\n- [ ] `Tracking Issue:` field documented in `PROJECT/PDDA.md`'s RELEASES.md contract and `skills/releases/SKILL.md`'s plan-subroutine template.\n- [ ] `check_releases()` flags Description/Exit-criterion/Manifest-Members bloat deterministically, with a registered regression test.\n- [ ] New checks ship warn-only first; existing bloated blocks are cleaned up or explicitly grandfathered before flipping to blocking.\n- [ ] `skills/releases/SKILL.md`'s discipline section cross-references the new field/checks instead of relying solely on manual invocation.\n\n## Sequencing\nQueued as a post-Ballast 0.7.0 follow-up — not a Ballast manifest member, no dependency on the release-gate run in flight.","comments":[],"number":28,"state":"OPEN","title":"RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue"}

codex
I found a material contract conflict: the plan’s “flip to blocking” would contradict the explicit permanent warn-only behavior of `pdda.sh releases`. I’m checking the parser/test seams and the scan’s boundary cases now, because those determine whether this is promotable as written.
exec
/bin/zsh -lc "awk '
function emit(){if (r"'!="") printf "%s'"\\tdesc=%d\\tdesc_terms=%d\\texit=%d\\texit_terms=%d\\tmembers=%d\\n\",r,length(d),terms(d),length(e),terms(e),members(m)}
function terms(s, t,n){t=s; n=gsub(/[."'!?][[:space:]]+|[.!?]$/, "&", t); return n}
/''^Release:/ {emit(); r=$0; sub(/''^Release:[[:space:]]*/,"",r); d=""; e=""; m=""; next}
/''^Description:/ {d=$0; sub(/''^Description:[[:space:]]*/,"",d); next}
/''^Exit criterion:/ {e=$0; sub(/''^Exit criterion:[[:space:]]*/,"",e); next}
/''^Manifest-Members:/ {m=$0; sub(/''^Manifest-Members:[[:space:]]*/,"",m); next}
END{emit()}
'"' RELEASES.md
nl -ba PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md | sed -n '38,100p'
nl -ba PROJECT/PDDA.md | sed -n '625,755p'
nl -ba utils/pdda/pdda-lib.sh | sed -n '448,530p'
nl -ba utils/pdda/pdda.sh | sed -n '645,815p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4
 succeeded in 0ms:
awk: calling undefined function members
 input record number 99, file RELEASES.md
 source line number 2
    38	## Validation scan (2026-08-18, ad-hoc, against live RELEASES.md)
    39	
    40	Ran the proposed checks against all 7 real blocks before writing any code:
    41	
    42	| Release | Description >4 sentences | Manifest-Members >7 tokens | Exit criterion length |
    43	|---|---|---|---|
    44	| 0.1.0 Quicksilver | clean | — (no field) | clean |
    45	| 0.2.0 Litmus | clean | — | 592 chars / 6 sentences |
    46	| 0.3.0 Nightwatch | 6 sentences | — | 2007 chars / 9 sentences |
    47	| 0.4.0 Plumbline | 5 sentences | — | clean |
    48	| 0.5.0 Lantern | 5 sentences | — | 1544 chars / 6 sentences |
    49	| 0.6.0 Meter | 17 sentences | 2 (clean) | 2718 chars / 10 sentences |
    50	| 0.7.0 Ballast | clean | 4 (clean) | 2470 chars / 10 sentences |
    51	| 0.8.0 (next) | 11 sentences | — | clean |
    52	
    53	Two findings that changed the plan:
    54	
    55	- **Manifest size is not the problem.** Only two blocks (0.6.0, 0.7.0) even use `Manifest-Members:`,
    56	  and both are clean. The real bloat is entirely in `Description:` and `Exit criterion:`, and it's
    57	  near-universal — 6 of 8 blocks trip the Description check, not just Ballast.
    58	- **"Spans multiple lines" is the wrong signal.** Every field in the file is one long wrapped physical
    59	  line, never literally multi-line — a line-count check would catch nothing. Replaced with a
    60	  sentence-count threshold on `Exit criterion:` (mirroring the existing Description rule): clean
    61	  blocks sit at 0-592 chars, bloated ones start at 1544+ chars / 6+ sentences.
    62	
    63	## Revised proposed fix (lightest viable — no new skill, no new scanner binary)
    64	
    65	1. Add a `Tracking Issue:` field to the `RELEASES.md` block spec (`PROJECT/PDDA.md` contract +
    66	   `skills/releases/SKILL.md`'s plan-subroutine template). Extends the existing Issue-first SOP
    67	   (`PROJECT/PDDA.md` → "GitHub issue intake") to the release ledger itself. Release-level status/run-log
    68	   notes go there, not inline in the ledger.
    69	2. Extend `check_releases()` in `utils/pdda/pdda.sh` with deterministic bloat checks:
    70	   - `Description:` exceeding 4 sentences (validated signal, confirmed above)
    71	   - `Exit criterion:` exceeding 4 sentences (replaces the multi-line check — validated to actually
    72	     catch the observed bloat)
    73	   - `Manifest-Members:` exceeding 7 tokens (kept for when the field is used; low incidence today but
    74	     cheap to check)
    75	   Same line-based-check style already used in that function — no LLM needed for detection.
    76	3. Ship the new checks **warn-only first**. Run once against live `RELEASES.md`, confirm the hit list
    77	   matches this scan, then flip to blocking in a follow-up commit — only after existing bloated blocks
    78	   (6 of 8) are cleaned up or grandfathered, so the feature doesn't land immediately red against its
    79	   own repo.
    80	4. `/releases clean`'s existing LLM rubric remains the fix-up drafting tool once a violation is
    81	   flagged by (2) — never the detector. Matches this repo's deterministic-before-LLM constitution rule.
    82	
    83	## Sequencing
    84	
    85	Queued as a **post-Ballast 0.7.0 follow-up** — not a Ballast manifest member, no dependency on the
    86	in-flight release-gate run.
    87	
    88	---
    89	
    90	## Acceptance Criteria
    91	- [ ] `Tracking Issue:` field documented in `PROJECT/PDDA.md`'s RELEASES.md contract and
    92	      `skills/releases/SKILL.md`'s plan-subroutine template.
    93	- [ ] `check_releases()` flags Description/Exit-criterion/Manifest-Members bloat deterministically,
    94	      with a registered regression test.
    95	- [ ] New checks ship warn-only first; existing bloated blocks (6 of 8, per the validation scan above)
    96	      are cleaned up or explicitly grandfathered before flipping to blocking.
    97	- [ ] `skills/releases/SKILL.md`'s discipline section cross-references the new field/checks instead of
    98	      relying solely on manual `/releases clean` invocation.
   625	#### RELEASES.md — release ledger
   626	
   627	**`RELEASES.md` is an optional planning aid.** It is not a required artifact, not a checklist, and
   628	not something to keep topped up. An empty file, a stale file, or no file at all are all valid
   629	states — `pdda.sh releases` skips a missing file entirely ("RELEASES.md not found — nothing to
   630	check") and never blocks, even in `full` mode.
   631	
   632	**Do not proactively offer to fill it in, populate it, bring it current, or add a release that has
   633	already shipped. Do not treat a sparse file as an incomplete one.** Edit it only when an operator
   634	explicitly asks for release *planning*.
   635	
   636	That instruction is aimed at the reader who is likeliest to erode this file, which is increasingly
   637	an LLM maintainer. The failure mode is not one bad decision; it is a long series of individually
   638	reasonable offers to help — "want me to add the release you just shipped?" — that in aggregate turn
   639	a planning aid into a second, hand-maintained history of what shipped. Two sources of truth for the
   640	same fact is the defect, and it arrives one helpful suggestion at a time. `CHANGELOG.md` is the
   641	history. This file is not.
   642	
   643	What it *is*: a first-class root file, like `ROADMAP.md`/`CHANGELOG.md` — a single forward-looking
   644	planning ledger for major releases, not a lifecycle bucket of per-tag docs. Marathon plans and other
   645	forward planning cross-reference it for target release names/dates.
   646	
   647	**The admission rule.** A block earns its place by being worth *planning toward* — a named arc with
   648	a theme, usually carrying a target date and a milestone. If the only thing that can go in
   649	`Description:` is a restatement of what changed, it belongs in `CHANGELOG.md` and nowhere else.
   650	Everything below the threshold goes in an `Iterations:` band (see the field docs) rather than getting
   651	its own block.
   652	
   653	The test is the theme, not the paperwork: `Target Date:` and `Milestone:` are optional fields and
   654	their absence never disqualifies a block. A release can be worth planning toward before anyone knows
   655	when it lands.
   656	
   657	Format — one flat `Label: value` block per release, blank line between blocks (blank lines are
   658	just visual spacing; a new block starts at the next `Release:` line). Field order is not parsed and
   659	every field except `Release:` is optional, so a real block is usually shorter than this:
   660	
   661	```text
   662	Release: 1.0.0
   663	Iterations: 1.0.0-1.0.4
   664	Status: Draft
   665	Target Date: 2026-07-31
   666	Codename: n/a
   667	Milestone:
   668	Description:
   669	Exit criterion:
   670	Manifest:
   671	GH_URL:
   672	Front-door reviewed:
   673	Shakedown reviewed:
   674	License file:
   675	```
   676	
   677	Fields:
   678	- `Release:` (required) — the version being planned
   679	- `Status:` (optional) — free-text, unvalidated by design (`Draft`, `Working`, `Shipped`, whatever
   680	  an operator finds useful). **`Status: Shipped` is the sole "already shipped" signal** — both
   681	  `pdda.sh releases`'s overdue nudge and `pdda.sh releases-current`'s "in progress" filter key off
   682	  it exclusively. This is a rough signal, not a gated lifecycle — no fixed vocabulary is enforced.
   683	- `Iterations:` (optional) — a **reserved band of version numbers**, written `<lo>-<hi>` (e.g.
   684	  `0.2.0-0.2.4`). Versions inside a band ship freely and are recorded in `CHANGELOG.md` only; they
   685	  **never get a block here**, and the band deliberately does not enumerate them. Absence of the
   686	  field means no band is reserved.
   687	
   688	  **The band's owner is the one exception.** A band is written on the block it belongs to, and that
   689	  block's own `Release:` is the band's `<lo>` — so the owner sits inside its own band and keeps its
   690	  block. Every *other* version in the range is covered by the band and gets none. `pdda.sh releases`
   691	  identifies the owner by line, not by version text, so a second block that merely repeats the
   692	  owner's version is still caught as the duplicate it is.
   693	
   694	  This is what gives the admission rule an answer instead of an argument. "Where does 0.2.3 go?"
   695	  resolved case-by-case is resolved by adding a row, every time; with a band it has a written
   696	  answer, and `pdda.sh releases` can check it — a version inside an existing band is already
   697	  accounted for, so a block for it is by definition a duplicate. That is testable in a way "is this
   698	  release meaningful?" never will be.
   699	
   700	  **When a band is exhausted** — `0.2.5` is needed and the band ends at `0.2.4` — **widen the band.
   701	  Do not start enumerating, and do not add a block.** Promote to the next release only when the work
   702	  genuinely became a new arc with its own theme, never merely because the numbers ran out; a version
   703	  number driven by an accounting artifact is the convention rotting rather than holding.
   704	
   705	  Rejected alternative, recorded so it isn't re-proposed: persisting `Iteration 1:` … `Iteration 5:`
   706	  labels per release. That is 20–25 named rows across a five-release horizon, each an invitation to
   707	  fill in what shipped — the same drift, arriving as structure instead of as appended blocks. One
   708	  optional field beats five required ones.
   709	- `Target Date:` (optional) — `YYYY-MM-DD`; `pdda.sh releases` warns once this passes and `Status`
   710	  doesn't read `Shipped`
   711	- `Codename:` (optional) — `n/a` is fine
   712	- `Milestone:` (optional) — free-text, unvalidated, the **release → issue-set join key**. It holds a
   713	  GitHub milestone *title*, so a release's scope can be queried rather than hand-maintained here:
   714	
   715	  ```bash
   716	  gh issue list --milestone "Quicksilver" --state open --json number,title,labels
   717	  ```
   718	
   719	  That query *is* release-driven work selection, with no second cache and no issue list copied into
   720	  this file — which is why the field is worth having and why it stays a pointer. Unvalidated for the
   721	  same reason as `Status:`: checking a title against GitHub would need a `gh` call, and this check is
   722	  deliberately network-free. **Not warned on when absent** — a release with no milestone is a normal
   723	  state, and a nudge here would recreate exactly the fill-it-in pressure this section exists to stop.
   724	- `Description:` (optional) — a concise one-to-four-sentence statement of the release theme. It is
   725	  not a run log, implementation plan, or second changelog; historical outcomes stay in
   726	  `CHANGELOG.md` and execution detail stays in the canonical `PROJECT/**` document. `/releases`
   727	  warns when this field exceeds four sentences or becomes multi-paragraph history.
   728	- `Exit criterion:` (optional) — one runnable command or observable condition that proves the arc
   729	  reached its goal. Keep the implementation and phased QA plan in `PROJECT/**`; this field is the
   730	  release-level goalpost only.
   731	- `Manifest:` (optional) — a concise, fixed release boundary, normally a dated `FROZEN` list of
   732	  issue IDs. Prefer `Milestone:` when the intent is a live issue-set query. `/releases` triggers an
   733	  ambition review above seven named issues and when the list mixes themes, grows without a dated
   734	  re-scope, or lacks an exit criterion; the count is advisory, never an automatic rejection.
   735	- `GH_URL:` (optional) — populated once *a* GitHub Release object exists, including a draft (see
   736	  `/releases publish`). **This means "a Release object exists," not "shipped"** — a draft's
   737	  `GH_URL` is real but the release isn't out. Flip `Status: Shipped` yourself (or let
   738	  `/releases publish` do it on an actual, non-draft publish) when it's really out; `GH_URL` alone
   739	  no longer implies that.
   740	- `Front-door reviewed:` / `Shakedown reviewed:` / `License file:` (optional) — pre-release QA-gate
   741	  checkboxes: has the `/front-door` onboarding audit run, has the `/shakedown` script-path audit
   742	  run, is a `LICENSE` file present. `Yes` or `No`; `pdda.sh releases` warns on any other non-blank
   743	  value. A blank value just means not yet answered, not a failure.
   744	
   745	Add new fields only when a real need shows up. This format intentionally started smaller than the
   746	earlier per-tag-doc convention (status lifecycle, linked marathons, linked issues, a GitHub
   747	release-tag cache) — that was more data than was practical to keep current for an initial release.
   748	`Status:` is the first field added back in, deliberately kept unvalidated (baby steps, not a new
   749	gated lifecycle) rather than reintroducing the old rigid `Draft → RC → Published` enum. The three
   750	QA-gate fields are the second: a real pre-release checklist need (open-sourcing a release means a
   751	front-door pass, a shakedown pass, and a `LICENSE` file all need to be true before shipping) that,
   752	unlike `Status`, has an unambiguous right answer — so they're validated `Yes`/`No` rather than free-text.
   753	`Iterations:` and `Milestone:` are the third pair, and both are additive: the parser ignores labels
   754	it doesn't know, absence means "not reserved" / "no milestone", and neither produces a finding in a
   755	ledger that has never used them. A repo can adopt them, or never hear of them, with no migration.
   448	# --- RELEASES.md helpers -------------------------------------------------------------------------
   449	# RELEASES.md is a single forward-looking planning ledger (like ROADMAP.md/CHANGELOG.md), not a
   450	# bucket of per-tag docs — see PROJECT/PDDA.md "RELEASES.md — release ledger". Each release is a
   451	# flat "Label: value" block; a block starts at a line matching ^Release: and runs until the next
   452	# such line or EOF (blank lines between blocks are just visual spacing, not parsed).
   453	
   454	# List releases as rows of
   455	#   <release><US><status><US><target_date><US><codename><US><description><US><gh_url><US>
   456	#   <front_door><US><shakedown><US><license_file><US><iterations><US><milestone><US><line>
   457	# (US = ASCII unit separator 0x1F, not tab — bash's `read` collapses empty fields around literal
   458	# tabs since tab counts as "IFS whitespace" regardless of IFS's contents, which would silently
   459	# misalign every block with a blank Description/GH_URL, i.e. the common case here). One row per
   460	# block, in file order. Prints nothing (silently) if the file doesn't exist.
   461	#
   462	# THIS ROW SHAPE IS INTERNAL, AND ADDING A FIELD IS A BREAKING CHANGE. Callers read it positionally
   463	# with `read -r`, and there is no position that is safe to extend: a new field before <line> shifts
   464	# <line> onto the wrong variable, and one after it makes bash's last-variable-absorbs-the-rest rule
   465	# fold the extras into <line>. So <line> stays last as a record terminator, and every reader must be
   466	# updated in the SAME change — `check_releases` and `cmd_releases_current` are the only two, and
   467	# test/pdda-releases-iterations.sh pins the field count so a future addition can't drift silently.
   468	# The stable, external surface for other tooling is `pdda.sh releases-current`, not this helper.
   469	#
   470	# `Status:` is free-text (Draft/Working/Shipped/... — whatever an operator writes) and unvalidated
   471	# by design: it's a rough, non-authoritative signal for "what's in progress," not a gated lifecycle
   472	# field. `Milestone:` is free-text for the same reason — it carries a GitHub milestone *title* so a
   473	# release's scope can be queried (`gh issue list --milestone "<title>"`) instead of hand-listed here.
   474	# `Front-door reviewed:`/`Shakedown reviewed:`/`License file:` are optional Yes/No QA-gate fields,
   475	# and `Iterations:` is an optional reserved version band (`pdda.sh releases` warns on a malformed
   476	# value for either). See PROJECT/PDDA.md "RELEASES.md — release ledger".
   477	pdda_releases_list() {
   478	  local file="$1"
   479	  [ -f "$file" ] || return 0
   480	  awk '
   481	    function flush() {
   482	      if (has_release) {
   483	        printf "%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%d\n", release, status, target_date, codename, description, gh_url, front_door, shakedown, license_file, iterations, milestone, release_line
   484	      }
   485	      release=""; status=""; target_date=""; codename=""; description=""; gh_url=""
   486	      front_door=""; shakedown=""; license_file=""; iterations=""; milestone=""
   487	      release_line=0; has_release=0
   488	    }
   489	    /^Release:/             { flush(); v=$0; sub(/^Release:[[:space:]]*/, "", v); release=v; has_release=1; release_line=NR; next }
   490	    /^Status:/              { v=$0; sub(/^Status:[[:space:]]*/, "", v); status=v; next }
   491	    /^Iterations:/          { v=$0; sub(/^Iterations:[[:space:]]*/, "", v); iterations=v; next }
   492	    /^Target Date:/         { v=$0; sub(/^Target Date:[[:space:]]*/, "", v); target_date=v; next }
   493	    /^Codename:/             { v=$0; sub(/^Codename:[[:space:]]*/, "", v); codename=v; next }
   494	    /^Milestone:/           { v=$0; sub(/^Milestone:[[:space:]]*/, "", v); milestone=v; next }
   495	    /^Description:/         { v=$0; sub(/^Description:[[:space:]]*/, "", v); description=v; next }
   496	    /^GH_URL:/               { v=$0; sub(/^GH_URL:[[:space:]]*/, "", v); gh_url=v; next }
   497	    /^Front-door reviewed:/ { v=$0; sub(/^Front-door reviewed:[[:space:]]*/, "", v); front_door=v; next }
   498	    /^Shakedown reviewed:/  { v=$0; sub(/^Shakedown reviewed:[[:space:]]*/, "", v); shakedown=v; next }
   499	    /^License file:/        { v=$0; sub(/^License file:[[:space:]]*/, "", v); license_file=v; next }
   500	    END { flush() }
   501	  ' "$file"
   502	}
   503	
   504	# Compare two dotted-numeric versions; echoes -1 / 0 / 1 for a<b / a==b / a>b. Missing and
   505	# non-numeric components read as 0. Deliberately NOT a semver implementation — it exists only to
   506	# answer "does this version fall inside a reserved Iterations band", and callers gate it behind
   507	# pdda_is_dotted_version so prerelease/date-shaped values never reach it.
   508	pdda_vercmp() {
   509	  awk -v a="$1" -v b="$2" '
   510	    BEGIN {
   511	      na = split(a, x, "."); nb = split(b, y, ".")
   512	      n = (na > nb ? na : nb)
   513	      for (i = 1; i <= n; i++) {
   514	        ai = (i <= na ? x[i] + 0 : 0); bi = (i <= nb ? y[i] + 0 : 0)
   515	        if (ai < bi) { print -1; exit }
   516	        if (ai > bi) { print  1; exit }
   517	      }
   518	      print 0
   519	    }'
   520	}
   521	
   522	# True if the value is a plain dotted-numeric version (1, 1.2, 0.2.14 — not v1.2.3, not 1.0.0-rc1).
   523	pdda_is_dotted_version() {
   524	  case "$1" in
   525	    "" | *[!0-9.]* | .* | *. | *..*) return 1 ;;
   526	  esac
   527	  return 0
   528	}
   529	
   530	# True if the value is a well-formed reserved-iteration band: exactly "<lo>-<hi>", both plain
   645	# ------------------------------------------------------------------------------------------------
   646	# J. releases (warn-only nudge; never blocks, even in full)
   647	# ------------------------------------------------------------------------------------------------
   648	# Validates RELEASES.md, the single forward-looking release-planning ledger (see PROJECT/PDDA.md
   649	# "RELEASES.md — release ledger"). Deliberately light: this replaced a heavier per-tag-doc lifecycle
   650	# (status Draft/RC/Published, linked marathons, linked issues, a GitHub release-tag cache) that
   651	# proved like too much data to keep current for an initial release. Grows only as real need shows up.
   652	#   (1) error — a "Release:" block has an empty version
   653	#   (2) warn  — Target Date is set but not a valid YYYY-MM-DD date
   654	#   (3) warn  — Target Date has passed and GH_URL is still empty (looks overdue/unshipped)
   655	#   (4) warn  — Iterations is set but isn't a well-formed "<lo>-<hi>" version band
   656	#   (5) warn  — a block's version falls inside another block's reserved Iterations band
   657	check_releases() {
   658	  pdda_reset_counts
   659	  local CHECK_NAME="pdda-check-releases" rc=0
   660	  local RELEASES_FILE_EFF="${PDDA_RELEASES_FILE:-$PDDA_REPO_ROOT/RELEASES.md}"
   661	  local release status target_date codename description gh_url line_no target_epoch today_epoch
   662	  local status_lc front_door shakedown license_file qa_field qa_label qa_value qa_value_lc
   663	  local iterations milestone rows bands="" band_release band_lo band_hi band_line release_trimmed
   664	
   665	  if [ ! -f "$RELEASES_FILE_EFF" ]; then
   666	    pdda_record_finding info "$CHECK_NAME" "$RELEASES_FILE_EFF" 0 \
   667	      "RELEASES.md not found — nothing to check" "skip"
   668	    pdda_emit_summary "$CHECK_NAME" 0
   669	    return "$(pdda_gated_exit 0)"
   670	  fi
   671	
   672	  # A ledger with no blocks at all (header-only, or empty) is a VALID state under this contract —
   673	  # sparse is fine — so it reports exactly as clean as it did before this field pair existed. The
   674	  # guard exists because the here-doc loops below would otherwise see one empty line and fake a
   675	  # "block near line 0 has no version" error; it deliberately records NO finding of its own.
   676	  rows="$(pdda_releases_list "$RELEASES_FILE_EFF")"
   677	  if [ -z "$rows" ]; then
   678	    pdda_emit_summary "$CHECK_NAME" 0
   679	    return "$(pdda_gated_exit 0)"
   680	  fi
   681	
   682	  # Pass 1 — validate each Iterations band and remember the well-formed ones. A band reserves patch
   683	  # numbers that deliberately never get their own block (PROJECT/PDDA.md "RELEASES.md — release
   684	  # ledger"), which is what lets pass 2 test the admission rule mechanically instead of rhetorically.
   685	  while IFS=$'\037' read -r release status target_date codename description gh_url \
   686	    front_door shakedown license_file iterations milestone line_no; do
   687	    iterations="$(pdda_trim "$iterations")"
   688	    [ -n "$iterations" ] || continue
   689	    if pdda_is_iteration_band "$iterations"; then
   690	      bands="${bands}${release}"$'\037'"${iterations%%-*}"$'\037'"${iterations#*-}"$'\037'"${line_no}"$'\n'
   691	    else
   692	      pdda_record_finding warn "$CHECK_NAME" "$RELEASES_FILE_EFF" "$line_no" \
   693	        "release '$release' Iterations '$iterations' is not a valid <lo>-<hi> version band (e.g. 0.2.0-0.2.4)" \
   694	        "fix-iterations-band"
   695	    fi
   696	  done <<EOF
   697	$rows
   698	EOF
   699	
   700	  while IFS=$'\037' read -r release status target_date codename description gh_url \
   701	    front_door shakedown license_file iterations milestone line_no; do
   702	    if [ -z "$(pdda_trim "$release")" ]; then
   703	      pdda_record_finding error "$CHECK_NAME" "$RELEASES_FILE_EFF" "$line_no" \
   704	        "a 'Release:' block near line $line_no has no version" "fix-release-value"
   705	      rc=1
   706	      continue
   707	    fi
   708	
   709	    # Admission rule, made mechanical: a version inside another block's reserved band is already
   710	    # accounted for by that band, so a second block for it is by definition a duplicate. Only plain
   711	    # dotted-numeric versions are testable this way; anything else is left to human judgment.
   712	    #
   713	    # A band's OWNER is inside its own band by construction (0.2.0 owns 0.2.0-0.2.4), so it must not
   714	    # flag itself. Identity is the block's LINE, not its version text: comparing versions would let a
   715	    # second, genuinely duplicate `Release: 0.2.0` block hide behind the owner's identical value —
   716	    # exactly the case the check exists to catch.
   717	    release_trimmed="$(pdda_trim "$release")"
   718	    if pdda_is_dotted_version "$release_trimmed"; then
   719	      while IFS=$'\037' read -r band_release band_lo band_hi band_line; do
   720	        [ -n "$band_release" ] || continue
   721	        [ "$band_line" != "$line_no" ] || continue
   722	        [ "$(pdda_vercmp "$release_trimmed" "$band_lo")" != "-1" ] || continue
   723	        [ "$(pdda_vercmp "$release_trimmed" "$band_hi")" != "1" ] || continue
   724	        pdda_record_finding warn "$CHECK_NAME" "$RELEASES_FILE_EFF" "$line_no" \
   725	          "release '$release_trimmed' is inside the Iterations band $band_lo-$band_hi reserved by release '$(pdda_trim "$band_release")' (line $band_line) — already accounted for; record it in CHANGELOG.md instead of giving it a block" \
   726	          "in-band-release-block"
   727	      done <<EOF
   728	$bands
   729	EOF
   730	    fi
   731	
   732	    # Front-door reviewed / Shakedown reviewed / License file: optional pre-release QA-gate
   733	    # checkboxes, warn-only Yes/No like the rest of this check (see PROJECT/PDDA.md "RELEASES.md
   734	    # — release ledger"). A blank value is fine (not yet answered); only a set-but-invalid value warns.
   735	    for qa_field in "Front-door reviewed:$front_door" "Shakedown reviewed:$shakedown" "License file:$license_file"; do
   736	      qa_label="${qa_field%%:*}"
   737	      qa_value="$(pdda_trim "${qa_field#*:}")"
   738	      [ -n "$qa_value" ] || continue
   739	      qa_value_lc="$(printf '%s' "$qa_value" | tr '[:upper:]' '[:lower:]')"
   740	      case "$qa_value_lc" in
   741	        yes | no) ;;
   742	        *) pdda_record_finding warn "$CHECK_NAME" "$RELEASES_FILE_EFF" "$line_no" \
   743	             "release '$release' $qa_label value '$qa_value' is not exactly Yes or No" "fix-release-yesno-field" ;;
   744	      esac
   745	    done
   746	
   747	    [ -n "$target_date" ] || continue
   748	
   749	    if ! pdda_is_real_date "$target_date"; then
   750	      pdda_record_finding warn "$CHECK_NAME" "$RELEASES_FILE_EFF" "$line_no" \
   751	        "release '$release' Target Date '$target_date' is not a valid YYYY-MM-DD date" \
   752	        "fix-target-date"
   753	      continue
   754	    fi
   755	
   756	    # Status: Shipped is the sole "already shipped" signal (GH_URL only means a Release object
   757	    # exists — draft or published — not that the release is out; see PROJECT/PDDA.md "RELEASES.md
   758	    # — release ledger"). A populated GH_URL alone no longer skips this check.
   759	    status_lc="$(printf '%s' "$(pdda_trim "$status")" | tr '[:upper:]' '[:lower:]')"
   760	    [ "$status_lc" != "shipped" ] || continue
   761	
   762	    # _pdda_cl_epoch is the changelog check's date->epoch helper, portable BSD/GNU; reused here
   763	    # rather than duplicating the date-parsing logic for a second date-comparison check.
   764	    target_epoch="$(_pdda_cl_epoch "$target_date")"
   765	    today_epoch="$(_pdda_cl_epoch "$(pdda_today)")"
   766	    if [ -n "$target_epoch" ] && [ -n "$today_epoch" ] && [ "$target_epoch" -lt "$today_epoch" ]; then
   767	      pdda_record_finding warn "$CHECK_NAME" "$RELEASES_FILE_EFF" "$line_no" \
   768	        "release '$release' Target Date '$target_date' has passed and Status isn't Shipped — overdue" \
   769	        "overdue-release"
   770	    fi
   771	  done <<EOF
   772	$rows
   773	EOF
   774	
   775	  pdda_emit_summary "$CHECK_NAME" "$rc"
   776	  # Warn-only in spirit — never blocks, even in full mode (see PROJECT/PDDA.md section J). The one
   777	  # error above is a malformed-doc guard, surfaced loudly, but deliberately never gates the exit code.
   778	  return "$(pdda_gated_exit 0)"
   779	}
   780	
   781	# ------------------------------------------------------------------------------------------------
   782	# releases-current (read-only roll-up; not part of PDDA_DETERMINISTIC_CHECKS — no findings, no gate)
   783	# ------------------------------------------------------------------------------------------------
   784	# A rough, non-authoritative answer to "what release is in progress right now" — for a human, or for
   785	# another repo's tooling (e.g. the XYZ sibling harness) to shell out to rather than re-implementing
   786	# RELEASES.md parsing itself. Lists every release whose Status is empty or not "Shipped" (Status is
   787	# free-text and unvalidated, so this is a best-effort filter, not a gate — see PROJECT/PDDA.md).
   788	cmd_releases_current() {
   789	  local RELEASES_FILE_EFF="${PDDA_RELEASES_FILE:-$PDDA_REPO_ROOT/RELEASES.md}"
   790	  local release status target_date codename description gh_url line_no status_lc any=0
   791	  local front_door shakedown license_file iterations milestone
   792	
   793	  if [ ! -f "$RELEASES_FILE_EFF" ]; then
   794	    printf '%s not found — nothing to report\n' "$(pdda_relpath "$RELEASES_FILE_EFF")"
   795	    return 0
   796	  fi
   797	
   798	  printf 'PDDA releases-current — in-progress entries in %s\n' "$(pdda_relpath "$RELEASES_FILE_EFF")"
   799	  while IFS=$'\037' read -r release status target_date codename description gh_url \
   800	    front_door shakedown license_file iterations milestone line_no; do
   801	    [ -n "$(pdda_trim "$release")" ] || continue
   802	    status_lc="$(printf '%s' "$(pdda_trim "$status")" | tr '[:upper:]' '[:lower:]')"
   803	    [ "$status_lc" != "shipped" ] || continue
   804	
   805	    any=1
   806	    printf '\n• %s' "$release"
   807	    [ -n "$codename" ] && printf ' (%s)' "$codename"
   808	    printf ' — %s\n' "${status:-no Status set}"
   809	    [ -n "$iterations" ] && printf '    Iterations: %s (reserved; these ship without their own block)\n' "$iterations"
   810	    [ -n "$target_date" ] && printf '    Target Date: %s\n' "$target_date"
   811	    [ -n "$milestone" ] && printf '    Milestone: %s\n' "$milestone"
   812	    [ -n "$description" ] && printf '    %s\n' "$description"
   813	    [ -n "$gh_url" ] && printf '    %s\n' "$gh_url"
   814	  done < <(pdda_releases_list "$RELEASES_FILE_EFF")
   815	

2026-08-18T16:09:26.880390Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "awk '
function terms(s, t){t=s; return gsub(/[."'!?][[:space:]]+|[.!?]$/, "&", t)}
function emit(){if (r!="") printf "%s'"\\tdesc=%d\\tdesc_terms=%d\\texit=%d\\texit_terms=%d\\tmembers=%d\\n\",r,length(d),terms(d),length(e),terms(e),split(m,a,/ +/)}
/"'^Release:/ {emit(); r=$0; sub(/''^Release:[[:space:]]*/,"",r); d=""; e=""; m=""; next}
/''^Description:/ {d=$0; sub(/''^Description:[[:space:]]*/,"",d); next}
/''^Exit criterion:/ {e=$0; sub(/''^Exit criterion:[[:space:]]*/,"",e); next}
/''^Manifest-Members:/ {m=$0; sub(/''^Manifest-Members:[[:space:]]*/,"",m); next}
END{emit()}
'"' RELEASES.md
nl -ba skills/releases/SKILL.md | sed -n '86,155p'
nl -ba test/gh284-p3-release-milestone.sh | sed -n '1,35p;151,205p'
nl -ba validate.sh | sed -n '1,55p;210,228p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4
 succeeded in 0ms:
0.1.0	desc=224	desc_terms=2	exit=0	exit_terms=0	members=0
0.2.0	desc=504	desc_terms=4	exit=592	exit_terms=6	members=0
0.3.0	desc=853	desc_terms=6	exit=2015	exit_terms=9	members=0
0.4.0	desc=568	desc_terms=5	exit=0	exit_terms=0	members=0
0.5.0	desc=827	desc_terms=5	exit=1550	exit_terms=6	members=0
0.6.0	desc=1179	desc_terms=4	exit=2726	exit_terms=10	members=2
0.7.0	desc=751	desc_terms=3	exit=2486	exit_terms=10	members=4
0.8.0	desc=505	desc_terms=4	exit=288	exit_terms=1	members=0
    86	## Discipline and abuse warnings
    87	
    88	Warn, without blocking, when:
    89	
    90	- `Description:` exceeds four sentences, becomes multi-paragraph execution history, or duplicates
    91	  `CHANGELOG.md`. Recommend a one-to-four-sentence theme and move history to `CHANGELOG.md` and
    92	  implementation detail to the canonical `PROJECT/**` document.
    93	- `Manifest:` names more than seven issues. The count triggers review, not condemnation.
    94	- A manifest mixes unrelated themes, lacks a fixed denominator, grows without a dated re-scope,
    95	  crosses several release dependencies, or has no runnable/observable exit criterion.
    96	- A block copies an issue inventory that should be represented by the `Milestone:` join key.
    97	
    98	Explain which signal fired. Never call a large manifest abusive solely because of its issue count.
    99	
   100	## Clean subroutine
   101	
   102	1. Default to active/unshipped blocks. Touch a shipped block only when the operator explicitly names
   103	   it.
   104	2. Propose the smallest cleanup that restores the documented shape: compact descriptions, preserve
   105	   theme and dependencies, reduce manifests to a fixed list or milestone pointer, preserve dated
   106	   re-scope decisions, and move historical narrative to `CHANGELOG.md` or execution detail to its
   107	   existing project doc. Never create a new doc merely to shorten the ledger.
   108	3. Record the file hash before preview. Render the exact patch and get one confirmation.
   109	4. Immediately before writing, re-read `RELEASES.md` and compare its hash. If it changed, discard the
   110	   patch, synthesize again, and preview a new patch.
   111	5. Edit only the confirmed blocks. Never reorder unrelated blocks.
   112	6. Run `utils/pdda/pdda.sh releases` and report every finding.
   113	
   114	## Plan or update subroutine
   115	
   116	1. Apply the admission rule. A block earns a place only when it represents a named arc worth
   117	   planning toward. A restatement of shipped changes belongs only in `CHANGELOG.md`. A version inside
   118	   another block's `Iterations:` band is already accounted for.
   119	2. If no version was supplied, compare the highest bracketed `CHANGELOG.md` version with the highest
   120	   ledger version. Propose the next semantic version and explain the patch/minor/major judgment; let
   121	   the operator override it.
   122	3. Ask only for unanswered fields:
   123	   - status;
   124	   - optional iteration band;
   125	   - target date or blank/TBD;
   126	   - optional codename;
   127	   - optional GitHub milestone title;
   128	   - a one-to-four-sentence description of the theme;
   129	   - optional concise manifest;
   130	   - optional executable or observable exit criterion;
   131	   - optional QA fields (`Front-door reviewed`, `Shakedown reviewed`, `License file`).
   132	4. Draft the flat block below, omitting blank optional fields except `GH_URL:` when publication is
   133	   expected:
   134	
   135	```text
   136	Release: 1.2.0
   137	Iterations: 1.2.0-1.2.4
   138	Status: Draft
   139	Target Date: 2026-12-01
   140	Codename: Example
   141	Description: One coherent release theme in no more than four sentences.
   142	Exit criterion: `command --that-proves-the-release` exits 0.
   143	Manifest: FROZEN YYYY-MM-DD — #101, #102, #103.
   144	GH_URL:
   145	Milestone: Example
   146	Front-door reviewed: No
   147	Shakedown reviewed: No
   148	License file: Yes
   149	```
   150	
   151	5. Preview the complete new or replacement block and get one confirmation. Re-check the file hash
   152	before writing. Append new blocks after the last block; replace only an explicitly selected existing
   153	block. Never silently edit neighboring blocks.
   154	6. Run `utils/pdda/pdda.sh releases` and report findings.
   155	
     1	#!/usr/bin/env bash
     2	# GH-284 Phase 3 — RELEASES.md gains `Milestone:`, the release -> issue-set join key.
     3	#
     4	# A release must resolve to a SET of issues before it can drive marathon selection, and `GH_URL:`
     5	# holds exactly one link. The linkage lives in GitHub (a milestone), so it maintains itself as issues
     6	# open and close; RELEASES.md carries only the milestone TITLE.
     7	#
     8	# This file is also the first test the `pdda.sh releases` check has ever had — before Phase 3 it had
     9	# none, so the pre-existing behaviors it must not break (empty version -> error, bad date -> warn,
    10	# overdue -> warn, never gates the exit code) are pinned here too, not just the new field.
    11	source "$(dirname "$0")/_setup.sh" gh284-p3-release-milestone
    12	ROOT="$(cd "$(dirname "$0")/.." && pwd)"
    13	PDDA="$ROOT/utils/pdda/pdda.sh"
    14	
    15	# PDDA_RELEASES_FILE points the check at a fixture instead of the repo's real ledger.
    16	run_releases() {  # <fixture-file>
    17	  PDDA_RELEASES_FILE="$1" PDDA_ACTIVITY_LOG=/dev/null bash "$PDDA" releases 2>&1
    18	}
    19	run_current() {   # <fixture-file>
    20	  PDDA_RELEASES_FILE="$1" PDDA_ACTIVITY_LOG=/dev/null bash "$PDDA" releases-current 2>&1
    21	}
    22	# The Milestone WARNING is this repo's own policy and lives in utils/pdda-local-checks.sh, not in
    23	# the sync-managed upstream script. The 2026-08-03 PDDA sync (cfd56b0) deleted it from pdda.sh —
    24	# upstream carries `Milestone:` as "optional, free-text, unvalidated" — and this test went red for
    25	# ~2 days reading as pre-existing noise. Everything else below still exercises `pdda.sh releases`,
    26	# which is the point: the upstream behaviours must keep working alongside the local check.
    27	LOCAL_CHECKS="$ROOT/utils/pdda-local-checks.sh"
    28	run_milestone() { # <fixture-file>
    29	  PDDA_RELEASES_FILE="$1" PDDA_ACTIVITY_LOG=/dev/null bash "$LOCAL_CHECKS" release-milestone 2>&1
    30	}
    31	
    32	# ── (1) the new warning fires on a dated, unshipped release with no Milestone ────────────
    33	F="$WORK/no-milestone.md"
    34	cat > "$F" <<'EOF'
    35	Release: 1.0.0
   151	  && pass "releases-current prints the milestone when set" \
   152	  || fail "roll-up did not show the milestone: $out"
   153	# The roll-up's explicit "(none — release cannot resolve to an issue set)" line was ALSO deleted by
   154	# the cfd56b0 sync: upstream's `releases-current` now prints the Milestone line only when set, so a
   155	# missing one is rendered as absence. This assertion was masked until case (1) was fixed — the file
   156	# fail-fasted before reaching it. The requirement it encodes ("a missing milestone is never silent")
   157	# is preserved by the local check, which names the offending release; the roll-up no longer does.
   158	# Restoring the roll-up line belongs upstream, not in a file the next sync overwrites.
   159	out_ms="$(run_milestone "$F")"
   160	printf '%s' "$out_ms" | grep -F "release '5.0.0' has a Target Date but no 'Milestone:'" >/dev/null \
   161	  && pass "a milestone-less release is still named explicitly (by the local check, not the roll-up)" \
   162	  || fail "a missing milestone became silent in BOTH the roll-up and the check: $out_ms"
   163	printf '%s' "$out_ms" | grep -F "release '4.0.0'" >/dev/null \
   164	  && fail "the release that HAS a milestone was wrongly flagged: $out_ms" \
   165	  || pass "the release carrying a milestone is not flagged"
   166	
   167	# ── (6) the field must not shift the other parsed fields ─────────────────────────────────
   168	# Milestone was appended to a \037-delimited record. A mis-ordered read would silently hand
   169	# `line_no` to `milestone` (or vice versa) and every assertion above could still pass by accident.
   170	F="$WORK/ordering.md"
   171	cat > "$F" <<'EOF'
   172	Release: 6.0.0
   173	Status: Draft
   174	Target Date: 2999-01-01
   175	Codename: Ordercheck
   176	Description: DESCRIPTION-SENTINEL
   177	GH_URL: GHURL-SENTINEL
   178	Milestone: MILESTONE-SENTINEL
   179	EOF
   180	out="$(run_current "$F")"
   181	printf '%s' "$out" | grep -F "DESCRIPTION-SENTINEL" >/dev/null \
   182	  && pass "Description still lands in the Description slot" \
   183	  || fail "field ordering broke: Description missing from $out"
   184	printf '%s' "$out" | grep -F "GHURL-SENTINEL" >/dev/null \
   185	  && pass "GH_URL still lands in the GH_URL slot" \
   186	  || fail "field ordering broke: GH_URL missing from $out"
   187	printf '%s' "$out" | grep -F "Milestone: MILESTONE-SENTINEL" >/dev/null \
   188	  && pass "Milestone lands in its own slot, not shifted" \
   189	  || fail "field ordering broke: Milestone missing or shifted in $out"
   190	
   191	# ── (7) the repo's own ledger satisfies the contract it just documented ──────────────────
   192	# Against `pdda.sh releases` this assertion is now UNFALSIFIABLE — upstream emits no Milestone
   193	# warning at all, so "no warning fired" would be true for any ledger, including a broken one. It runs
   194	# against the local check, which is the only thing that can still produce the string it greps for.
   195	out="$(PDDA_ACTIVITY_LOG=/dev/null bash "$LOCAL_CHECKS" release-milestone 2>&1)"
   196	printf '%s' "$out" | grep -F "no 'Milestone:'" >/dev/null \
   197	  && fail "this repo's own RELEASES.md has a dated release with no Milestone: $out" \
   198	  || pass "the repo's RELEASES.md carries a Milestone for every dated, unshipped release"
   199	
   200	echo "  gh284-p3-release-milestone: $PASS pass, $FAIL fail"
   201	exit 0
     1	#!/usr/bin/env bash
     2	# Aggregate runner for all tick acceptance tests.
     3	# Exit 0 = all pass; Exit 1 = at least one failed.
     4	set -u
     5	
     6	# GH-441 Phase 2: clean the ambient variables a live marathon exports, via the shared contract rather
     7	# than a list copied here. This file used to hardcode six names; the driver popped three DIFFERENT
     8	# ones, and any other --pre-advance-cmd that forgot the prologue was silently wrong. One did, on
     9	# 2026-08-07, and cost two marathon rounds. utils/py/gate_env.py is now the single registry, and
    10	# test/gh441-gate-env-contract.sh fails if a new driver export is left unclassified.
    11	# NOTE: RELAY_DRIVER_LOCKED is deliberately NOT scrubbed — see gate_env.py's docstring.
    12	. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/relay-automation/gate-env.sh"
    13	
    14	HERE="$(cd "$(dirname "$0")" && pwd)"
    15	TESTS=(
    16	  "projection-idempotent.sh"
    17	  "concurrent-claim.sh"
    18	  "chaos-stale-writer.sh"
    19	  "chaos-concurrent-pollers.sh"
    20	  "chaos-midturn-kill.sh"
    21	  "path-overlap.sh"
    22	  "scope-change.sh"
    23	  "tick-foreign-cwd.sh"
    24	  "handoff.sh"
    25	  "handoff-exclusive.sh"
    26	  "circuit-break.sh"
    27	  "terminality-seal.sh"          # GH-41 (terminal seal edge cases — cross-model review of PR #99)
    28	  "auto-sync.sh"
    29	  "analyze.sh"
    30	  "workstealing-verdict.sh"      # GH-4 (work-stealing via take + lane-count-independent verdict)
    31	  "verdict-edge.sh"              # GH-4 (verdict/collision edge cases — cross-model review of PR #101)
    32	  "claim-cap.sh"
    33	  "reap.sh"
    34	  "heartbeat.sh"
    35	  "cost.sh"
    36	  "take.sh"
    37	  "watchdog-liveness.sh"
    38	  "runner-loop.sh"
    39	  "poll-driver.sh"
    40	  "relay-loop.sh"
    41	  "poll-relay.sh"
    42	  "watchdog-relay.sh"
    43	  "codex-turn.sh"
    44	  "agy-turn.sh"
    45	  "pi-turn.sh"                   # GH-295 (Pi/pi.dev headless turn-taker: PI_MODEL safety + cost capture)
    46	  "relay-turn-trace.sh"          # GH-161 (rtl_trace/rtl_log_always/rtl_default_log instrumentation)
    47	  "aider-turn.sh"
    48	  "gh278-turn-timeout-parity.sh" # GH-278 (Aider Python/Bash/doc timeout default must stay aligned)
    49	  "gh308-frozen-twin-guard.sh"  # GH-308 (Python-authoritative twins: banner + committed-change guard)
    50	  "ate-run-variations.sh"       # GH-195 (ATE fuzzer git helpers: base-commit/disposable-guard/reset/detect-edit)
    51	  "model-alias.sh"              # GH-120 (OpenRouter model-alias fuzzy lookup)
    52	  "swe-diagram.sh"              # GH-146 (hub-ring layout ring-balance math + search/filter matching)
    53	  "claude-turn.sh"             # GH-58
    54	  "worktree-isolation.sh"
    55	  "shim-worktree.sh"
   210	  "xyz-vendor.sh"
   211	  "xyz-sync-check.sh"            # GH-96 (xyz-sync check: tick_version/source_commit drift report)
   212	  "gh293-vendored-guard-drift.sh" # GH-293 (safety-guard manifest + safe fleet-update source gate)
   213	  "relay-concurrent-commit.sh"
   214	  "relay-commit-pathspec.sh"     # GH-198 (rtl_enforce commit is file-scoped, no pathspec regression)
   215	  "relay-case-insensitive.sh"
   216	  "relay-xyz-skill-guard.sh"
   217	  "find-harness.sh"
   218	  "gh292-worktree-vendored-discovery.sh"  # GH-292 (linked worktree resolves main-checkout .xyz/)
   219	  "pdda-roadmap-coverage.sh"
   220	  "pdda-repo-contract.sh"       # GH-311 (real-repository PDDA deterministic contract)
   221	  "pdda-local-checks.sh"        # the checks the 2026-08-03 PDDA sync deleted, restored outside the sync surface
   222	  "gh460-pipe-buffer-sigpipe.sh" # GH-460 (the tier1 "flake" was a SIGPIPE race against the pipe buffer under pipefail, not a flaky assertion) — 8/0; control: the pre-fix shape exits 141 on a >64KB payload whose marker IS present, and passes on a payload that fits
   223	  "gh284-p3-release-milestone.sh" # GH-284 P3 (RELEASES.md Milestone: join key + the releases check's first test)
   224	  "gh284-p4-release-lanes.sh"   # GH-284 P4 (milestone seed + landed-on-trunk rollup: scope-claim matcher)
   225	  "swarm-preflight.sh"
   226	  "ci-workflow.sh"
   227	  "ci-route.sh"                  # GH-509 (docs/fast/full routing + changed-area test selection)
   228	  "gh509-gate-evidence.sh"       # GH-509 (per-commit local gate record + the operator surface)

2026-08-18T16:10:02.046771Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "sed -n '1,100p' utils/pdda/pdda.sh
sed -n '1,100p' utils/pdda/pdda-lib.sh
rg -n -C 3 'sync-managed|pdda-local-checks|PDDA sync|pdda.sh' PROJECT/PDDA-SYNC-POLICY.md PROJECT/PDDA.md utils/pdda/PDDA-INSTALL.md README.md | head -n 500
nl -ba RELEASES.md | sed -n '90,112p;145,173p;176,205p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4
 succeeded in 0ms:
#!/usr/bin/env bash
set -u

# PDDA unified entry point. One dispatcher for every deterministic hygiene check plus the aggregate
# run. The LLM-assisted readiness review stays in its own file (utils/pdda/pdda-doc-ready.sh) — it is a
# different class of automation (opt-in, model-dependent, advisory/warn-max), per PROJECT/PDDA.md
# "Automation layers". Shared helpers live in utils/pdda/pdda-lib.sh.
#
# Usage:
#   pdda.sh run                 # run every deterministic check, then the LLM review (steps in order)
#   pdda.sh frontmatter         # one check (see SUBCOMMANDS below)
#   pdda.sh status-table
#   pdda.sh hardcoded-paths
#   pdda.sh roadmap
#   pdda.sh roadmap-coverage
#   pdda.sh changelog
#   pdda.sh stale
#   pdda.sh issue-doc-sync
#   pdda.sh governance          # repo-root governance-doc cross-reference + doc/code drift
#   pdda.sh doc-ready           # delegates to utils/pdda/pdda-doc-ready.sh (the LLM layer)
#   pdda.sh help
#
# Mode/format/overrides are honored exactly as before via the env vars resolved in pdda-lib.sh
# (PDDA_MODE, PDDA_FORMAT, PDDA_WORKING_DIR, PDDA_ROADMAP, ...). Every check resets the finding
# counters on entry and emits its own SUMMARY, so per-check output is identical whether a check runs
# standalone (`pdda.sh frontmatter`) or as part of `pdda.sh run`.

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=utils/pdda/pdda-lib.sh
. "$HERE/pdda-lib.sh"

pdda_reset_counts() { ERROR_COUNT=0; WARN_COUNT=0; INFO_COUNT=0; }

# ------------------------------------------------------------------------------------------------
# A. frontmatter
# ------------------------------------------------------------------------------------------------
check_frontmatter() {
  pdda_reset_counts
  local CHECK_NAME="pdda-check-frontmatter" rc=0
  local REQUIRED_KEYS="title status created updated owner goal"
  local file key value date_key rating_key

  while IFS= read -r file; do
    if ! pdda_has_frontmatter "$file"; then
      pdda_record_finding error "$CHECK_NAME" "$file" 1 "missing YAML frontmatter" "add-frontmatter"
      rc=1
      continue
    fi

    for key in $REQUIRED_KEYS; do
      if ! pdda_frontmatter_has_key "$file" "$key"; then
        pdda_record_finding error "$CHECK_NAME" "$file" 1 "missing required frontmatter key '$key'" "add-frontmatter-key"
        rc=1
        continue
      fi

      value="$(pdda_frontmatter_value "$file" "$key")"
      if [ -z "$(pdda_trim "$value")" ]; then
        pdda_record_finding error "$CHECK_NAME" "$file" 1 "frontmatter key '$key' is empty" "fill-frontmatter-key"
        rc=1
      fi
    done

    for date_key in created updated; do
      if pdda_frontmatter_has_key "$file" "$date_key"; then
        value="$(pdda_trim "$(pdda_frontmatter_value "$file" "$date_key")")"
        # tolerate YAML-quoted dates, e.g. created: "2026-06-15" or '2026-06-15'
        case "$value" in
          \"*\") value="${value#\"}"; value="${value%\"}" ;;
          \'*\') value="${value#\'}"; value="${value%\'}" ;;
        esac
        if ! printf '%s' "$value" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
          pdda_record_finding error "$CHECK_NAME" "$file" 1 "frontmatter key '$date_key' must use YYYY-MM-DD" "fix-date-format"
          rc=1
        elif ! pdda_is_real_date "$value"; then
          pdda_record_finding error "$CHECK_NAME" "$file" 1 "frontmatter key '$date_key' is not a real calendar date ($value)" "fix-date-value"
          rc=1
        fi
      fi
    done

    # Optional triage ratings (PDDA.md "Triage ratings for medium-large work"). Validate ONLY when
    # present: whether a doc SHOULD carry them depends on it being medium-large — a judgment the LLM
    # layer flags, not this script. But a present value out of range is unambiguous => error. Effort,
    # complexity, and risk are integers 1 (low) .. 5 (highest); phases is a positive integer.
    for rating_key in effort complexity risk; do
      if pdda_frontmatter_has_key "$file" "$rating_key"; then
        value="$(pdda_trim "$(pdda_frontmatter_value "$file" "$rating_key")")"
        if ! printf '%s' "$value" | grep -Eq '^[1-5]$'; then
          pdda_record_finding error "$CHECK_NAME" "$file" 1 "frontmatter rating '$rating_key' must be an integer 1-5 (got '$value')" "fix-rating-value"
          rc=1
        fi
      fi
    done
    if pdda_frontmatter_has_key "$file" "phases"; then
      value="$(pdda_trim "$(pdda_frontmatter_value "$file" "phases")")"
      if ! printf '%s' "$value" | grep -Eq '^[1-9][0-9]*$'; then
        pdda_record_finding error "$CHECK_NAME" "$file" 1 "frontmatter 'phases' must be a positive integer (got '$value')" "fix-phases-value"
        rc=1
      fi
#!/usr/bin/env bash
set -u

PDDA_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Runtime lives in <repo>/utils/pdda/, so the repo root is two levels up from the lib dir.
PDDA_REPO_ROOT="${PDDA_REPO_ROOT:-$(cd "$PDDA_LIB_DIR/../.." && pwd)}"
PDDA_INBOX_DIR="${PDDA_INBOX_DIR:-$PDDA_REPO_ROOT/PROJECT/1-INBOX}"
PDDA_WORKING_DIR="${PDDA_WORKING_DIR:-$PDDA_REPO_ROOT/PROJECT/2-WORKING}"
PDDA_COMPLETED_DIR="${PDDA_COMPLETED_DIR:-$PDDA_REPO_ROOT/PROJECT/3-COMPLETED}"
PDDA_MISC_DIR="${PDDA_MISC_DIR:-$PDDA_REPO_ROOT/PROJECT/4-MISC}"
# Forward-looking release-planning ledger — a single root file (like ROADMAP.md/CHANGELOG.md), not
# a lifecycle bucket of per-tag docs. See PROJECT/PDDA.md "RELEASES.md — release ledger".
PDDA_RELEASES_FILE="${PDDA_RELEASES_FILE:-$PDDA_REPO_ROOT/RELEASES.md}"
PDDA_ACTIVITY_LOG="${PDDA_ACTIVITY_LOG:-$PDDA_REPO_ROOT/PROJECT/PDDA-ACTIVITY.jsonl}"
# Cached GitHub issue-state file (TSV: "<number>\t<STATE>", '#'-comment lines ignored). Written by
# pdda-gh-refresh.sh; read by `pdda.sh issue-doc-sync` when gh is absent/offline. Gitignored runtime
# state, regenerated on demand — sits beside .pdda-mode at the repo root by default.
PDDA_GH_STATE_CACHE="${PDDA_GH_STATE_CACHE:-$PDDA_REPO_ROOT/.pdda-gh-state.tsv}"
PDDA_STALE_DAYS="${PDDA_STALE_DAYS:-4}"
PDDA_DRY_RUN="${PDDA_DRY_RUN:-0}"
# Output format for findings on stdout: "text" (human, default) or "json" (one JSON object per line,
# the same machine-readable shape as the activity log) — satisfies PDDA.md's composable output contract.
PDDA_FORMAT="${PDDA_FORMAT:-text}"
# Activity-log rotation ceiling (lines); pdda_rotate_activity trims to the last N. 0 = never rotate.
PDDA_ACTIVITY_MAX_LINES="${PDDA_ACTIVITY_MAX_LINES:-10000}"

# --- Enforcement mode (observe | light | full) -------------------------------------------------
# PDDA's adoption ramp (see PDDA.md "Enforcement modes"). Resolution order:
#   env PDDA_MODE  ->  first non-comment line of <repo>/.pdda-mode  ->  default "observe".
# Default is "observe" so a freshly-installed PDDA is non-destructive (sees everything, changes
# nothing, never fails a build); a project graduates to "light" then "full" deliberately.
#   observe : report findings only; every check/the suite exits 0.
#   light   : report findings (incl. stale-doc flags); still exit 0 (warn, don't block the build).
#   full    : report + exit non-zero on errors (strict; fully on rails).
pdda_resolve_mode() {
  local m="${PDDA_MODE:-}"
  if [ -z "$m" ] && [ -f "$PDDA_REPO_ROOT/.pdda-mode" ]; then
    m="$(awk 'NF && $0 !~ /^[[:space:]]*#/ { gsub(/[[:space:]]/,""); print; exit }' "$PDDA_REPO_ROOT/.pdda-mode" 2>/dev/null)"
  fi
  case "$m" in
    observe|light|full) printf '%s' "$m" ;;
    *) printf 'observe' ;;
  esac
}
PDDA_MODE="$(pdda_resolve_mode)"
# Stale docs are flag-only in every mode (see `pdda.sh stale`), so no mode mutates the tree.
# PDDA_DRY_RUN stays a reserved knob for any future opt-in move re-added behind pdda_hold + full.

# Gate a check's raw exit code by mode: only "full" lets an error block (non-zero exit). observe and
# light still report every finding but exit 0, so a fresh or transitioning install never fails a
# build while the project is being brought onto the rails. Each check ends with
#   exit "$(pdda_gated_exit "$EXIT_CODE")"
pdda_gated_exit() {
  if [ "$PDDA_MODE" = "full" ]; then printf '%s' "${1:-0}"; else printf '0'; fi
}

ERROR_COUNT=0
WARN_COUNT=0
INFO_COUNT=0

# Cross-check totals for one `pdda.sh run`, accumulated by pdda_emit_summary. The per-check counters
# above are reset by every pdda_reset_counts, and a check's RETURN VALUE is gated to 0 outside full
# mode — so in observe/light a run of nothing but errors leaves cmd_run's EXIT_CODE at 0. Inferring
# "all checks passed" from that zero is BUG-001b: the mode gate is supposed to stop the run from
# BLOCKING, not to stop it from REPORTING. These totals survive the resets and ignore the gate, so the
# closing line can say what was actually found. Same family as GH-23 and GH-27: a check that could not
# run, or could not block, must never be scored as a check that passed.
PDDA_RUN_ERRORS=0
PDDA_RUN_WARNS=0
PDDA_RUN_ERROR_CHECKS=""
# GH-43: the warn total was accumulated below but never read, so a run whose findings were all
# warn-level printed "all checks passed". Same family, one step further out: PDDA_RUN_ERRORS answers
# "did anything go wrong", not "did anything need attention" — which is what that line asserts.
PDDA_RUN_WARN_CHECKS=""

pdda_now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

pdda_today() {
  date +"%Y-%m-%d"
}

pdda_relpath() {
  case "$1" in
    "$PDDA_REPO_ROOT") printf '.\n' ;;
    "$PDDA_REPO_ROOT"/*) printf '%s\n' "${1#$PDDA_REPO_ROOT/}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

pdda_trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s\n' "$value"
}

pdda_json_escape() {
  if command -v node >/dev/null 2>&1; then
utils/pdda/PDDA-INSTALL.md-34-
utils/pdda/PDDA-INSTALL.md-35-### Migrating a repo that predates the `utils/pdda/` layout
utils/pdda/PDDA-INSTALL.md-36-
utils/pdda/PDDA-INSTALL.md:37:Older installs put the runtime **flat** under `utils/` (`utils/pdda.sh`, `utils/pdda-lib.sh`,
utils/pdda/PDDA-INSTALL.md-38-`utils/pdda-doc-ready.sh`, sometimes `utils/pdda-catchup.sh`, plus `utils/PDDA-INSTALL.md` and a
utils/pdda/PDDA-INSTALL.md-39-legacy `utils/pdda-phase-out/`). The runtime is relocatable (it sources via `HERE="$(dirname "$0")"`),
utils/pdda/PDDA-INSTALL.md-40-so both layouts *run* — but a plain re-install **adds** the new `utils/pdda/` subfolder beside the old
utils/pdda/PDDA-INSTALL.md-41-flat files, leaving **two copies** and an ambiguous source of truth.
utils/pdda/PDDA-INSTALL.md-42-
utils/pdda/PDDA-INSTALL.md-43-`install.sh` detects the flat layout and **migrates it automatically** (one canonical `utils/pdda/`):
utils/pdda/PDDA-INSTALL.md:44:it removes the now-duplicate PDDA-owned flat files (`utils/pdda.sh`, `utils/pdda-lib.sh`,
utils/pdda/PDDA-INSTALL.md-45-`utils/pdda-doc-ready.sh`, `utils/pdda-catchup.sh`, `utils/PDDA-INSTALL.md`, the legacy
utils/pdda/PDDA-INSTALL.md:46:`utils/pdda-phase-out/`), repoints old-path references (`utils/pdda.sh` → `utils/pdda/pdda.sh`, etc.)
utils/pdda/PDDA-INSTALL.md-47-in tracked docs, and prints a summary of what moved. The target repo's own non-PDDA `utils/` files are
utils/pdda/PDDA-INSTALL.md-48-never touched, and historical CHANGELOG paths are left as the dated record they are. Migration runs as
utils/pdda/PDDA-INSTALL.md-49-part of the upgrade so the maintainer's whole job is "run the script, review the diff, commit."
--
utils/pdda/PDDA-INSTALL.md-92-A failure here is a bug in PDDA's template, not in your repo. The install still completes — the target is
utils/pdda/PDDA-INSTALL.md-93-usable, its router is misleading — and the non-zero exit is what stops `pdda-sync.sh register` from
utils/pdda/PDDA-INSTALL.md-94-propagating it further. `.claude/skills/governance-audit/SKILL.md`
utils/pdda/PDDA-INSTALL.md:95:(the `pdda.sh governance` companion — see `PROJECT/PDDA.md` § "I. `pdda.sh governance`") is the same
utils/pdda/PDDA-INSTALL.md-96-kind of repo-local, not-installed-by-default skill; copy it manually into a target repo if wanted.
utils/pdda/PDDA-INSTALL.md-97-
utils/pdda/PDDA-INSTALL.md-98-Do not install deprecated PDDA companion docs from `PROJECT/4-MISC/`.
--
utils/pdda/PDDA-INSTALL.md-110-```text
utils/pdda/PDDA-INSTALL.md-111-PROJECT/PDDA.md
utils/pdda/PDDA-INSTALL.md-112-utils/pdda/pdda-lib.sh
utils/pdda/PDDA-INSTALL.md:113:utils/pdda/pdda.sh
utils/pdda/PDDA-INSTALL.md-114-utils/pdda/pdda-doc-ready.sh
utils/pdda/PDDA-INSTALL.md-115-utils/pdda/pdda-catchup.sh
utils/pdda/PDDA-INSTALL.md-116-utils/pdda/pdda-gh-refresh.sh
--
utils/pdda/PDDA-INSTALL.md-120-```
utils/pdda/PDDA-INSTALL.md-121-
utils/pdda/PDDA-INSTALL.md-122-The shipped runtime lives in its own `utils/pdda/` subfolder so it never mixes with a target repo's
utils/pdda/PDDA-INSTALL.md:123:existing `utils/` files. `utils/pdda/pdda.sh` is the unified entry point — it carries every
utils/pdda/PDDA-INSTALL.md:124:deterministic check plus the aggregate `run` as subcommands (`pdda.sh run`, `pdda.sh frontmatter`,
utils/pdda/PDDA-INSTALL.md:125:`pdda.sh roadmap`, ...). `utils/pdda/pdda-lib.sh` holds the shared helpers it sources;
utils/pdda/PDDA-INSTALL.md-126-`utils/pdda/pdda-doc-ready.sh` is the opt-in LLM readiness layer and `utils/pdda/pdda-catchup.sh` is
utils/pdda/PDDA-INSTALL.md:127:the opt-in ROUTER.md triage layer. `utils/pdda/pdda-gh-refresh.sh` (`pdda.sh gh-refresh`) refreshes the
utils/pdda/PDDA-INSTALL.md:128:cached GitHub issue-state file that `pdda.sh issue-doc-sync` reads when `gh` is offline. That cache is
utils/pdda/PDDA-INSTALL.md:129:also written automatically by any successful live lookup (every online `pdda.sh run`), so the offline
utils/pdda/PDDA-INSTALL.md-130-consumers — chiefly the `Stop` hook — have last-known state without anyone remembering to run
utils/pdda/PDDA-INSTALL.md-131-`gh-refresh`. Explicit `gh-refresh` remains useful to prime the cache before going offline.
utils/pdda/PDDA-INSTALL.md-132-`utils/pdda/pdda-edit-doc-hook.sh` (tier 1, a `PostToolUse` single-file lint) and
--
utils/pdda/PDDA-INSTALL.md-173-
utils/pdda/PDDA-INSTALL.md-174-1. Create the target directories listed above. -> expect `PROJECT/` and `utils/` to exist.
utils/pdda/PDDA-INSTALL.md-175-2. Copy the canonical install-set files verbatim to the same relative paths in the target repo. -> expect `PROJECT/PDDA.md` and all shipped `utils/pdda-*.sh` files to exist.
utils/pdda/PDDA-INSTALL.md:176:3. Create baseline `ROADMAP.md`, `CHANGELOG.md`, and `RELEASES.md` files if the target repo does not already have them. -> expect the roadmap contract to have a file to guard, the changelog check to warn less, and a release-planning ledger to exist. `RELEASES.md` is the one optional member of that set: `pdda.sh releases` skips a missing file and never blocks, so a repo that never plans a release arc can delete it and stay green. It is seeded only so the format is discoverable — not as a file to keep populated (see `PROJECT/PDDA.md` -> "RELEASES.md — release ledger").
utils/pdda/PDDA-INSTALL.md-177-4. Create an empty `PROJECT/PDDA-ACTIVITY.jsonl` if it does not exist. -> expect a zero- or low-byte log file, not this repo's historical log.
utils/pdda/PDDA-INSTALL.md-178-4a. Add `PROJECT/PDDA-ACTIVITY.jsonl` and `.pdda-gh-state.tsv` to the target's `.gitignore` (and `git rm --cached` any that are already tracked). -> expect the churning runtime state to stop dirtying `git status` on every run.
utils/pdda/PDDA-INSTALL.md-179-4b. Record the install in the per-user, machine-local registry `${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv` (one tab-delimited row per target: `target · last_install_utc · mode · source_commit · startup_docs`; latest install wins). -> expect `pdda-sync.sh` to read this to find copies that are behind. Machine-local, never committed; `--no-register` or `PDDA_REGISTRY` adjust it.
utils/pdda/PDDA-INSTALL.md-180-4c. If git-pulse (a separate, GitHub-backed activity-sync tool) is present, also write a path-normalized projection of the registry into `<git-pulse-repo>/pdda/registry-<device>.tsv` (col 1 reduced to the bare repo name; **no absolute paths**), letting git-pulse's own sync roll PDDA install status up across devices. -> expect this to be best-effort and fail-open: absent git-pulse it is silently skipped and the install is unaffected. The local registry stays the source of truth. The git-pulse checkout is auto-detected: explicit `PDDA_GITPULSE_DIR` wins, else git-pulse's own `config.sh` `sync_repo_dir`, else the first existing of `${XDG_CONFIG_HOME:-$HOME/.config}/git-pulse/repo` or `~/git-pulse-sync`; set `PDDA_GITPULSE_DIR` to a nonexistent path to disable, and `--no-register` skips it too. **Hazard (GH-28):** if a machine has more than one git-pulse checkout on disk, `sync_repo_dir` always wins over the `~/git-pulse-sync` fallback — check which one is actually current with `origin` before assuming the projection reached your other devices. -> expect a follow-up warning (`warn: git-pulse checkout … is N commit(s) behind` / `… is uncommitted`) printed right after this step whenever the resolved checkout is dirty or behind its own upstream as of its last fetch (no network call is made here); the write to disk still always succeeds regardless.
utils/pdda/PDDA-INSTALL.md:181:5. Make the shell scripts executable. -> expect `chmod +x utils/pdda/pdda.sh utils/pdda/pdda-doc-ready.sh utils/pdda/pdda-lib.sh utils/pdda/pdda-catchup.sh utils/pdda/pdda-gh-refresh.sh utils/pdda/pdda-edit-doc-hook.sh utils/pdda/pdda-stop-doc-health.sh` to succeed.
utils/pdda/PDDA-INSTALL.md-182-6. Optionally create a repo-root `.pdda-mode` file with `observe` for first install. -> expect a non-destructive first run.
utils/pdda/PDDA-INSTALL.md-183-7. If the target repo uses a different doc layout, set environment overrides instead of editing the scripts first. -> expect the checks to honor the env vars below.
utils/pdda/PDDA-INSTALL.md:184:8. Run `utils/pdda/pdda.sh run` in the target repo. -> expect report-only behavior in `observe` mode and an append to `PROJECT/PDDA-ACTIVITY.jsonl`.
utils/pdda/PDDA-INSTALL.md-185-
utils/pdda/PDDA-INSTALL.md-186-## Environment overrides
utils/pdda/PDDA-INSTALL.md-187-
--
utils/pdda/PDDA-INSTALL.md-225-utils/pdda/PDDA-INSTALL.md`), `PDDA_GOVERNANCE_INDEX` (the doc every other governance doc must be
utils/pdda/PDDA-INSTALL.md-226-reachable from; default `ROUTER.md`), and three GH-15 exemption-manifest overrides scoped to the docs
utils/pdda/PDDA-INSTALL.md-227-that ship to every target install (`PDDA-INSTALL.md`, `PROJECT/PDDA.md`) so a fresh install's first
utils/pdda/PDDA-INSTALL.md:228:`pdda.sh run` doesn't self-inflict dead-reference/env-var noise from files `install.sh` deliberately
utils/pdda/PDDA-INSTALL.md-229-never copies: `PDDA_GOV_SHIPPED_DOCS` (which shipped docs the exemptions apply to; default
utils/pdda/PDDA-INSTALL.md-230-`utils/pdda/PDDA-INSTALL.md PROJECT/PDDA.md`), `PDDA_GOV_SHIPPED_DOC_REF_EXEMPTIONS` (basenames/paths
utils/pdda/PDDA-INSTALL.md-231-those docs may dead-reference without a warn — the target's own startup docs, canonical-only skill and
--
utils/pdda/PDDA-INSTALL.md-268-Run these commands in the target repo:
utils/pdda/PDDA-INSTALL.md-269-
utils/pdda/PDDA-INSTALL.md-270-```bash
utils/pdda/PDDA-INSTALL.md:271:chmod +x utils/pdda/pdda.sh utils/pdda/pdda-doc-ready.sh utils/pdda/pdda-lib.sh utils/pdda/pdda-catchup.sh
utils/pdda/PDDA-INSTALL.md-272-printf 'observe\n' > .pdda-mode
utils/pdda/PDDA-INSTALL.md:273:utils/pdda/pdda.sh run
utils/pdda/PDDA-INSTALL.md-274-```
utils/pdda/PDDA-INSTALL.md-275-
utils/pdda/PDDA-INSTALL.md-276-Expected result:
--
PROJECT/PDDA-SYNC-POLICY.md:1:# PDDA sync review policy
PROJECT/PDDA-SYNC-POLICY.md-2-
PROJECT/PDDA-SYNC-POLICY.md-3-## Purpose and scope
PROJECT/PDDA-SYNC-POLICY.md-4-
--
PROJECT/PDDA-SYNC-POLICY.md-10-
PROJECT/PDDA-SYNC-POLICY.md-11-This file is deliberately repo-owned. Neither `PROJECT/PDDA.md` nor anything under `utils/pdda/**`
PROJECT/PDDA-SYNC-POLICY.md-12-can be the durable home for a policy about reviewing a sync: both are sync **inputs** and may be
PROJECT/PDDA-SYNC-POLICY.md:13:replaced wholesale by the next one. That is not hypothetical — `cfd56b0` replaced the sync-managed
PROJECT/PDDA-SYNC-POLICY.md-14-`utils/pdda/**` tree in exactly that way, which is how the guardrails went missing.
PROJECT/PDDA-SYNC-POLICY.md-15-
PROJECT/PDDA-SYNC-POLICY.md-16-## Before a sync is approved
--
PROJECT/PDDA-SYNC-POLICY.md-28-   documentation that records local behaviour. The sign-off records the path, why it is safe to
PROJECT/PDDA-SYNC-POLICY.md-29-   remove, the replacement (or why none is needed), and the verification to run.
PROJECT/PDDA-SYNC-POLICY.md-30-3. A sync must not delete repo-owned checks merely because they sit near an imported tree. In
PROJECT/PDDA-SYNC-POLICY.md:31:   particular, `utils/pdda-local-checks.sh` and `test/pdda-local-checks.sh` are local seams, not
PROJECT/PDDA-SYNC-POLICY.md-32-   sync input. New local behaviour belongs outside `utils/pdda/**` so a later sync cannot silently
PROJECT/PDDA-SYNC-POLICY.md-33-   remove it.
PROJECT/PDDA-SYNC-POLICY.md-34-
--
PROJECT/PDDA.md-98-  glanceable summary for cold-start recall). `PROJECT/4-MISC` is out.
PROJECT/PDDA.md-99-- **Enable:** set `.pdda-quad` to `on` (or `PDDA_QUAD=1`). The enforcement mode still governs whether a
PROJECT/PDDA.md-100-  missing/malformed section merely reports or blocks. **Opt a doc out** with `quad_exempt: true`.
PROJECT/PDDA.md:101:- Enforced by `pdda.sh quad-concepts` (deterministic, structure-only) plus a warn-only readiness rubric.
PROJECT/PDDA.md:102:- `pdda.sh glance` (read-only, always available) rolls up `title + Quad Concepts` across `2-WORKING` for
PROJECT/PDDA.md-103-  a one-screen view of what the active portfolio is addressing.
PROJECT/PDDA.md-104-
PROJECT/PDDA.md-105-## Triage ratings for medium-large work
--
PROJECT/PDDA.md-163-
PROJECT/PDDA.md-164-### How this is enforced
PROJECT/PDDA.md-165-
PROJECT/PDDA.md:166:- **deterministic (values)** — `pdda.sh frontmatter` validates the fields **only when present**:
PROJECT/PDDA.md-167-  `effort`/`complexity`/`risk` must be integers `1`–`5`, `phases` a positive integer. A present-but-bad
PROJECT/PDDA.md-168-  value is unambiguous, so it `error`s. The script does **not** force presence — it cannot know whether
PROJECT/PDDA.md-169-  a doc is "medium-large."
--
PROJECT/PDDA.md-286-
PROJECT/PDDA.md-287-Implementation note:
PROJECT/PDDA.md-288-
PROJECT/PDDA.md:289:- the automation ships as a single dispatcher, `utils/pdda/pdda.sh`, which sources shared helpers from
PROJECT/PDDA.md-290-  `utils/pdda/pdda-lib.sh`
PROJECT/PDDA.md:291:- every deterministic check is a subcommand: `pdda.sh frontmatter`, `pdda.sh status-table`,
PROJECT/PDDA.md:292:  `pdda.sh hardcoded-paths`, `pdda.sh roadmap`, `pdda.sh roadmap-coverage`, `pdda.sh changelog`,
PROJECT/PDDA.md:293:  `pdda.sh stale`, `pdda.sh issue-doc-sync`, `pdda.sh governance`
PROJECT/PDDA.md:294:- the aggregate runner is `pdda.sh run` (it runs the deterministic checks in order, then the LLM
PROJECT/PDDA.md-295-  review)
PROJECT/PDDA.md-296-- each finding still carries a stable `check` id (e.g. `pdda-check-frontmatter`) in stdout and the
PROJECT/PDDA.md-297-  activity log, independent of how the check is invoked
--
PROJECT/PDDA.md-309-
PROJECT/PDDA.md-310-These catch issues where the answer should be the same every time.
PROJECT/PDDA.md-311-
PROJECT/PDDA.md:312:#### A. `pdda.sh stale`
PROJECT/PDDA.md-313-
PROJECT/PDDA.md-314-Purpose:
PROJECT/PDDA.md-315-- inspect docs in `PROJECT/2-WORKING`
--
PROJECT/PDDA.md-329-  guess cost nothing but an ignorable line. An opt-in move can be re-added later behind `pdda_hold` +
PROJECT/PDDA.md-330-  `full` mode if it ever earns the miles.
PROJECT/PDDA.md-331-
PROJECT/PDDA.md:332:#### B. `pdda.sh status-table`
PROJECT/PDDA.md-333-
PROJECT/PDDA.md-334-Purpose:
PROJECT/PDDA.md-335-- verify every doc in `PROJECT/2-WORKING` contains the exact two-column status table
--
PROJECT/PDDA.md-339-- fail if the table headers are not exactly `What was just completed` and `What's next`
PROJECT/PDDA.md-340-- fail if either first-row cell is blank
PROJECT/PDDA.md-341-
PROJECT/PDDA.md:342:#### B2. `pdda.sh quad-concepts` (opt-in)
PROJECT/PDDA.md-343-
PROJECT/PDDA.md-344-Purpose:
PROJECT/PDDA.md-345-- when the `.pdda-quad` / `PDDA_QUAD` lever is on, verify each in-scope plan doc carries a
--
PROJECT/PDDA.md-352-- fail if the section is missing, has 0 bullets, or has more than 4
PROJECT/PDDA.md-353-- **structure-only** — bullet *quality* (are they real `pain → fix` concepts?) is a warn-only job for
PROJECT/PDDA.md-354-  the LLM readiness rubric, not this deterministic check
PROJECT/PDDA.md:355:- runs standalone always; joins `pdda.sh run` only when the lever is enabled (orthogonal to the mode)
PROJECT/PDDA.md-356-
PROJECT/PDDA.md:357:#### C. `pdda.sh frontmatter`
PROJECT/PDDA.md-358-
PROJECT/PDDA.md-359-Purpose:
PROJECT/PDDA.md-360-- ensure active docs expose the minimum machine-readable metadata
--
PROJECT/PDDA.md-367-  integers `1`–`5`, `phases` a positive integer (presence itself is judged by the LLM layer; see
PROJECT/PDDA.md-368-  [Triage ratings for medium-large work](#triage-ratings-for-medium-large-work))
PROJECT/PDDA.md-369-
PROJECT/PDDA.md:370:#### D. `pdda.sh hardcoded-paths`
PROJECT/PDDA.md-371-
PROJECT/PDDA.md-372-Purpose:
PROJECT/PDDA.md-373-- catch absolute machine-specific paths before they fossilize into plans
--
PROJECT/PDDA.md-380-- quoted terminal output
PROJECT/PDDA.md-381-- explicitly marked transcript blocks
PROJECT/PDDA.md-382-
PROJECT/PDDA.md:383:#### E. `pdda.sh roadmap`
PROJECT/PDDA.md-384-
PROJECT/PDDA.md-385-Purpose:
PROJECT/PDDA.md-386-- enforce the `ROADMAP.md` pointer/ledger contract deterministically (the cheap, hourly guard that
--
PROJECT/PDDA.md-394-
PROJECT/PDDA.md-395-Expected exceptions:
PROJECT/PDDA.md-396-- fenced `console` / `text` / `transcript` blocks and blockquote lines (the carve-out exception note)
PROJECT/PDDA.md:397:  are not scanned — same convention as `pdda.sh hardcoded-paths`
PROJECT/PDDA.md-398-
PROJECT/PDDA.md-399-The fuzzy judgment ("deep execution notes that belong elsewhere") stays with the LLM layer below; this
PROJECT/PDDA.md-400-script only catches the unambiguous signals.
PROJECT/PDDA.md-401-
PROJECT/PDDA.md:402:#### F. `pdda.sh changelog`
PROJECT/PDDA.md-403-
PROJECT/PDDA.md-404-Purpose:
PROJECT/PDDA.md-405-- nudge that `CHANGELOG.md` (the first-class end-of-iteration record) was updated this iteration
--
PROJECT/PDDA.md-416-- "did you update the changelog" is a reminder, not a correctness gate — blocking a build because a
PROJECT/PDDA.md-417-  human hasn't written the prose yet is the wrong kind of friction (the calibration principle)
PROJECT/PDDA.md-418-
PROJECT/PDDA.md:419:#### G. `pdda.sh roadmap-coverage`
PROJECT/PDDA.md-420-
PROJECT/PDDA.md-421-Purpose:
PROJECT/PDDA.md-422-- enforce the *coverage* direction of the `ROADMAP.md` contract: every active doc in `PROJECT/2-WORKING`
PROJECT/PDDA.md-423-  must be reflected by a pointer in `ROADMAP.md`, so the ledger can never silently fall behind the
PROJECT/PDDA.md:424:  working set. This is the inverse of `pdda.sh roadmap` (which keeps execution detail from leaking
PROJECT/PDDA.md-425-  *into* the roadmap); together they guard the pointer/working-set relationship in both directions.
PROJECT/PDDA.md-426-
PROJECT/PDDA.md-427-Minimum behavior:
--
PROJECT/PDDA.md-433-
PROJECT/PDDA.md-434-Expected exceptions:
PROJECT/PDDA.md-435-- a working doc that should not appear in the ledger opts out with `roadmap_exempt: true` in its
PROJECT/PDDA.md:436:  frontmatter (mirrors the `pdda_hold` escape hatch in `pdda.sh stale`); the check then
PROJECT/PDDA.md-437-  emits `info` (skip) for that doc
PROJECT/PDDA.md-438-
PROJECT/PDDA.md:439:#### H. `pdda.sh issue-doc-sync`
PROJECT/PDDA.md-440-
PROJECT/PDDA.md-441-Purpose:
PROJECT/PDDA.md-442-- catch a tracked plan doc whose recorded state has drifted from its **GitHub issue**, in either
--
PROJECT/PDDA.md-466-    The lifecycle bucket is a deterministic signal; the status prose is not. `3-COMPLETED/` *is* the
PROJECT/PDDA.md-467-    operator's assertion that the work is done, recorded in a path and verifiable with `test -f`.
PROJECT/PDDA.md-468-    A doc in `3-COMPLETED` with a **CLOSED** issue is the fully reconciled end state: no finding.
PROJECT/PDDA.md:469:- `warn` (never `error` — does not block, even in `full`, mirroring `pdda.sh changelog`); **flag-only**,
PROJECT/PDDA.md-470-  never moves a file and never closes an issue
PROJECT/PDDA.md-471-- gh-degrade: with `PDDA_ISSUE_SYNC_SOURCE=auto` (default) it uses live `gh` when that succeeds, else a
PROJECT/PDDA.md-472-  cached state file (`PDDA_GH_STATE_CACHE`). `gh`/`cache` force one source. **A successful live lookup
--
PROJECT/PDDA.md-477-Why warn-only + flag-only:
PROJECT/PDDA.md-478-- every drift class here is mechanical, so the check carries zero false-judgment risk; a false flag is
PROJECT/PDDA.md-479-  one ignorable warn line and a missed flag just leaves today's manual reconciliation — both cheap, so
PROJECT/PDDA.md:480:  warn-only never-blocks is the right calibration (same stance as `pdda.sh stale` and `pdda.sh changelog`)
PROJECT/PDDA.md-481-- closing an issue is a **human judgment** about whether the work is genuinely done, so no script does it.
PROJECT/PDDA.md-482-  The `Stop` hook names the wrap (`/pdda-eod`) when this check reports reconciliation drift; the skill
PROJECT/PDDA.md-483-  proposes, the operator confirms. Detect deterministically, act only with a yes.
PROJECT/PDDA.md-484-
PROJECT/PDDA.md:485:#### I. `pdda.sh governance`
PROJECT/PDDA.md-486-
PROJECT/PDDA.md-487-Purpose:
PROJECT/PDDA.md-488-- evaluate the repo's own governance docs — `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`,
--
PROJECT/PDDA.md-501-  never flagged; those are illustrative instances of the issue-doc naming convention, not fixed
PROJECT/PDDA.md-502-  cross-references. `warn`, not `error`: prose extraction is inherently more heuristic than the
PROJECT/PDDA.md-503-  mechanical checks above, so a false flag should cost one ignorable line, not a blocked build (same
PROJECT/PDDA.md:504:  calibration as `pdda.sh stale`/`pdda.sh changelog`).
PROJECT/PDDA.md-505-  - **Three extraction patterns** (union, then deduplicated): the target of a markdown link; a code span
PROJECT/PDDA.md-506-    that contains nothing but the path; and **command-position paths** — a script token that opens a code
PROJECT/PDDA.md-507-    span or a scanned fence line. The third exists because a router's most load-bearing references are
--
PROJECT/PDDA.md-511-    both name a real file and matched nothing before GH-23 P3. Command position — line start, or
PROJECT/PDDA.md-512-    immediately after a backtick — is where a shell command's *program* sits; a script name appearing
PROJECT/PDDA.md-513-    later in a sentence is prose, and is not extracted. That is what keeps a documented invocation such
PROJECT/PDDA.md:514:    as `pdda.sh run` from being read as two separate references. A leading `./` is stripped, because in
PROJECT/PDDA.md-515-    command position it means "from the repo root I am standing in", not "relative to this doc".
PROJECT/PDDA.md-516-  - **Suffix widening was not free.** `.sh` references are the ones that differ most between the canonical
PROJECT/PDDA.md-517-    repo and a target, so the exemption manifest below had to grow with them — a fresh install went from
--
PROJECT/PDDA.md-525-    `PROJECT/3-COMPLETED/PDDA-SYNC-TO-OTHER-REPOS.md`), and the pre-`utils/pdda/` legacy layout path
PROJECT/PDDA.md-526-    (`utils/PDDA-INSTALL.md`, named only in migration-note prose). A fresh `install.sh . --mode observe`
PROJECT/PDDA.md-527-    self-inflicted ~30 dead-reference/env-var warns from exactly this mismatch on its very first
PROJECT/PDDA.md:528:    `pdda.sh run`, drowning a new adopter's own repo drift in PDDA-on-PDDA noise. The dead-reference scan
PROJECT/PDDA.md-529-    skips a match against `PDDA_GOV_SHIPPED_DOC_REF_EXEMPTIONS_DEFAULT`, scoped strictly to the docs in
PROJECT/PDDA.md-530-    `PDDA_GOV_SHIPPED_DOCS_DEFAULT` — a repo-authored governance doc (e.g. this canonical repo's own `ROUTER.md`)
PROJECT/PDDA.md-531-    referencing one of these is still a real dead-reference bug and is never exempted. The manifest was
--
PROJECT/PDDA.md-541-    `--with-startup-docs` target (46 warns before, 0 after), in three groups:
PROJECT/PDDA.md-542-    canonical-only **tools** a target never receives (the installer itself; the sync engine, which
PROJECT/PDDA.md-543-    `pdda-sync-manifest.conf` excludes because targets are leaf nodes; `templates/`; `test/`);
PROJECT/PDDA.md:544:    **legacy flat-layout paths** (`utils/pdda.sh`, `utils/pdda-lib.sh`, …) that the install manifest names
PROJECT/PDDA.md-545-    *precisely because they must not exist* — it documents the layout `install.sh` migrates away from,
PROJECT/PDDA.md-546-    and their `.md` sibling was already exempt for this reason; and `config.sh`, which belongs to
PROJECT/PDDA.md-547-    git-pulse, a separate program.
--
PROJECT/PDDA.md-552-    flagged rather than silently exempted pending a human decision on those files' fate.
PROJECT/PDDA.md-553-- **orphan governance docs** (`warn`) — a present governance doc whose filename never appears anywhere
PROJECT/PDDA.md-554-  in the index doc (`ROUTER.md` by default) — a doc a cold agent's startup sequence would never surface.
PROJECT/PDDA.md:555:- **subcommand drift** (`error`) — every subcommand in `utils/pdda/pdda.sh`'s dispatcher `case` block
PROJECT/PDDA.md-556-  must be named somewhere in the index doc. Parsing the `case` statement is mechanical (zero prose
PROJECT/PDDA.md-557-  ambiguity), so this earns the same blocking severity as the structural checks — it is the concrete
PROJECT/PDDA.md-558-  enforcement of AGENTS.md #5 ("keep the installer surface in lockstep").
--
PROJECT/PDDA.md-571-
PROJECT/PDDA.md-572-Expected exceptions:
PROJECT/PDDA.md-573-- fenced `console`/`text`/`transcript` blocks and blockquote lines are not scanned (same carve-out as
PROJECT/PDDA.md:574:  `pdda.sh hardcoded-paths`)
PROJECT/PDDA.md-575-- override the doc set with `PDDA_GOVERNANCE_DOCS` (space-separated, repo-relative) and the index doc
PROJECT/PDDA.md-576-  with `PDDA_GOVERNANCE_INDEX` (default `ROUTER.md`) for a repo with a different layout
PROJECT/PDDA.md-577-- override the shipped-doc exemption manifest with `PDDA_GOV_SHIPPED_DOCS`,
--
PROJECT/PDDA.md-583-judgment call for the LLM layer or a human — see the `/governance-audit` skill, which runs this check
PROJECT/PDDA.md-584-first and then reads the same doc set for that fuzzier class of inconsistency.
PROJECT/PDDA.md-585-
PROJECT/PDDA.md:586:#### J. `pdda.sh releases`
PROJECT/PDDA.md-587-
PROJECT/PDDA.md-588-Purpose:
PROJECT/PDDA.md-589-- validate `RELEASES.md`, the single forward-looking release-planning ledger — deliberately light.
--
PROJECT/PDDA.md-626-
PROJECT/PDDA.md-627-**`RELEASES.md` is an optional planning aid.** It is not a required artifact, not a checklist, and
PROJECT/PDDA.md-628-not something to keep topped up. An empty file, a stale file, or no file at all are all valid
PROJECT/PDDA.md:629:states — `pdda.sh releases` skips a missing file entirely ("RELEASES.md not found — nothing to
PROJECT/PDDA.md-630-check") and never blocks, even in `full` mode.
PROJECT/PDDA.md-631-
PROJECT/PDDA.md-632-**Do not proactively offer to fill it in, populate it, bring it current, or add a release that has
--
PROJECT/PDDA.md-678-- `Release:` (required) — the version being planned
PROJECT/PDDA.md-679-- `Status:` (optional) — free-text, unvalidated by design (`Draft`, `Working`, `Shipped`, whatever
PROJECT/PDDA.md-680-  an operator finds useful). **`Status: Shipped` is the sole "already shipped" signal** — both
PROJECT/PDDA.md:681:  `pdda.sh releases`'s overdue nudge and `pdda.sh releases-current`'s "in progress" filter key off
PROJECT/PDDA.md-682-  it exclusively. This is a rough signal, not a gated lifecycle — no fixed vocabulary is enforced.
PROJECT/PDDA.md-683-- `Iterations:` (optional) — a **reserved band of version numbers**, written `<lo>-<hi>` (e.g.
PROJECT/PDDA.md-684-  `0.2.0-0.2.4`). Versions inside a band ship freely and are recorded in `CHANGELOG.md` only; they
--
PROJECT/PDDA.md-687-
PROJECT/PDDA.md-688-  **The band's owner is the one exception.** A band is written on the block it belongs to, and that
PROJECT/PDDA.md-689-  block's own `Release:` is the band's `<lo>` — so the owner sits inside its own band and keeps its
PROJECT/PDDA.md:690:  block. Every *other* version in the range is covered by the band and gets none. `pdda.sh releases`
PROJECT/PDDA.md-691-  identifies the owner by line, not by version text, so a second block that merely repeats the
PROJECT/PDDA.md-692-  owner's version is still caught as the duplicate it is.
PROJECT/PDDA.md-693-
PROJECT/PDDA.md-694-  This is what gives the admission rule an answer instead of an argument. "Where does 0.2.3 go?"
PROJECT/PDDA.md-695-  resolved case-by-case is resolved by adding a row, every time; with a band it has a written
PROJECT/PDDA.md:696:  answer, and `pdda.sh releases` can check it — a version inside an existing band is already
PROJECT/PDDA.md-697-  accounted for, so a block for it is by definition a duplicate. That is testable in a way "is this
PROJECT/PDDA.md-698-  release meaningful?" never will be.
PROJECT/PDDA.md-699-
--
PROJECT/PDDA.md-706-  labels per release. That is 20–25 named rows across a five-release horizon, each an invitation to
PROJECT/PDDA.md-707-  fill in what shipped — the same drift, arriving as structure instead of as appended blocks. One
PROJECT/PDDA.md-708-  optional field beats five required ones.
PROJECT/PDDA.md:709:- `Target Date:` (optional) — `YYYY-MM-DD`; `pdda.sh releases` warns once this passes and `Status`
PROJECT/PDDA.md-710-  doesn't read `Shipped`
PROJECT/PDDA.md-711-- `Codename:` (optional) — `n/a` is fine
PROJECT/PDDA.md-712-- `Milestone:` (optional) — free-text, unvalidated, the **release → issue-set join key**. It holds a
--
PROJECT/PDDA.md-739-  no longer implies that.
PROJECT/PDDA.md-740-- `Front-door reviewed:` / `Shakedown reviewed:` / `License file:` (optional) — pre-release QA-gate
PROJECT/PDDA.md-741-  checkboxes: has the `/front-door` onboarding audit run, has the `/shakedown` script-path audit
PROJECT/PDDA.md:742:  run, is a `LICENSE` file present. `Yes` or `No`; `pdda.sh releases` warns on any other non-blank
PROJECT/PDDA.md-743-  value. A blank value just means not yet answered, not a failure.
PROJECT/PDDA.md-744-
PROJECT/PDDA.md-745-Add new fields only when a real need shows up. This format intentionally started smaller than the
--
PROJECT/PDDA.md-767-offer to top it up. A skill that exists to keep this file populated is the most efficient possible
PROJECT/PDDA.md-768-way to violate the optionality rule at the top of this section.
PROJECT/PDDA.md-769-
PROJECT/PDDA.md:770:#### `pdda.sh releases-current`
PROJECT/PDDA.md-771-
PROJECT/PDDA.md-772-Read-only roll-up (not part of `PDDA_DETERMINISTIC_CHECKS` — emits no findings, never gates): lists
PROJECT/PDDA.md-773-every `RELEASES.md` entry whose `Status` is empty or not exactly `Shipped`. A rough, non-authoritative
--
PROJECT/PDDA.md-822-doc-health system. The hooks are pure **delivery** — they run the SAME section-1 checks on a trigger;
PROJECT/PDDA.md-823-they add no new analysis class. Both are **warn-only and fail-open: they always exit `0` and can never
PROJECT/PDDA.md-824-block** an edit or a stop (a doc-hygiene reminder is never worth interrupting work — the calibration
PROJECT/PDDA.md:825:principle, same as `pdda.sh changelog`).
PROJECT/PDDA.md-826-
PROJECT/PDDA.md-827-- **Tier 1 — `pdda-edit-doc-hook.sh` (`PostToolUse` on `Edit|Write|MultiEdit`).** Reads the edited
PROJECT/PDDA.md-828-  `tool_input.file_path`; exits `0` instantly unless it is `ROADMAP.md` or a `PROJECT/**/*.md` doc;
--
PROJECT/PDDA.md-843-consolidated report**:
PROJECT/PDDA.md-844-
PROJECT/PDDA.md-845-- it runs the deterministic suite with `PDDA_ISSUE_SYNC_SOURCE=cache`, so `issue-doc-sync` reads the
PROJECT/PDDA.md:846:  cached gh-state file (written by `pdda.sh gh-refresh`) and the scan makes **no network call**;
PROJECT/PDDA.md-847-- it runs in `observe` mode with the LLM layer disabled — purely deterministic, fast, offline;
PROJECT/PDDA.md-848-- it aggregates the run into one report: a header with the error/warn totals, then the warn/error
PROJECT/PDDA.md-849-  finding lines (an `all clear` line when there are none);
PROJECT/PDDA.md-850-- it **always exits `0`** (proven by `test/pdda-doc-health-hooks.sh`), so it can never block a stop.
PROJECT/PDDA.md-851-
PROJECT/PDDA.md-852-Wire it as a `Stop` hook in `.claude/settings.json` (no matcher). Because it reads the cache rather
PROJECT/PDDA.md:853:than calling `gh`, keep `pdda.sh gh-refresh` on the hourly cadence so the Stop report stays current.
PROJECT/PDDA.md-854-
PROJECT/PDDA.md-855-## Enforcement modes
PROJECT/PDDA.md-856-
--
PROJECT/PDDA.md-914-  quietly disappear and later be duplicated.
PROJECT/PDDA.md-915-
PROJECT/PDDA.md-916-How this is enforced (so it cannot quietly rot in either direction):
PROJECT/PDDA.md:917:- **deterministic (no leak in)** — `pdda.sh roadmap` errors on task checklists / `### Checklist` /
PROJECT/PDDA.md-918-  `### QA checklist` headings and warns on size sprawl (runs hourly, free, no model needed)
PROJECT/PDDA.md:919:- **deterministic (no gap missing)** — `pdda.sh roadmap-coverage` errors when either an
PROJECT/PDDA.md-920-  active `PROJECT/2-WORKING` doc has no pointer here, or a captured `PROJECT/1-INBOX/GH-*.md` doc is
PROJECT/PDDA.md-921-  not parked here as a queue entry (honors `roadmap_exempt: true`)
PROJECT/PDDA.md-922-- **LLM** — `utils/pdda/pdda-doc-ready.sh` reviews `ROADMAP.md` against the full pointer contract for the
--
PROJECT/PDDA.md-970-  two files.)
PROJECT/PDDA.md-971-
PROJECT/PDDA.md-972-How this is enforced (a nudge, not a gate):
PROJECT/PDDA.md:973:- **deterministic** — `pdda.sh changelog` **warns** (never `error`, so it never blocks —
PROJECT/PDDA.md-974-  even in `full`) when the newest dated entry predates the latest git commit by more than
PROJECT/PDDA.md-975-  `PDDA_CHANGELOG_STALE_DAYS` days (default `0`), i.e. an iteration shipped without a changelog entry
PROJECT/PDDA.md-976-- whether an entry is actually *substantive* stays a human / LLM judgment, not a regex
--
PROJECT/PDDA.md-991-
PROJECT/PDDA.md-992-Run the deterministic checks every hour in this order:
PROJECT/PDDA.md-993-
PROJECT/PDDA.md:994:1. `pdda.sh frontmatter`
PROJECT/PDDA.md:995:2. `pdda.sh status-table`
PROJECT/PDDA.md:996:3. `pdda.sh hardcoded-paths`
PROJECT/PDDA.md:997:4. `pdda.sh roadmap`
PROJECT/PDDA.md:998:5. `pdda.sh roadmap-coverage`
PROJECT/PDDA.md:999:6. `pdda.sh changelog`
PROJECT/PDDA.md:1000:7. `pdda.sh stale`
PROJECT/PDDA.md:1001:8. `pdda.sh issue-doc-sync`
PROJECT/PDDA.md:1002:9. `pdda.sh releases`
PROJECT/PDDA.md:1003:10. `pdda.sh governance`
PROJECT/PDDA.md-1004-
PROJECT/PDDA.md-1005-Then run:
PROJECT/PDDA.md-1006-
PROJECT/PDDA.md:1007:11. `pdda.sh doc-ready`
PROJECT/PDDA.md-1008-
PROJECT/PDDA.md:1009:(`pdda.sh run` runs exactly this sequence and applies the active `PDDA_MODE` gate. Scheduling the
PROJECT/PDDA.md-1010-single aggregate command is the recommended hourly cron entry.)
PROJECT/PDDA.md-1011-
PROJECT/PDDA.md:1012:The cached GitHub issue-state refresh is a separate, network-only step. Run `pdda.sh gh-refresh`
PROJECT/PDDA.md-1013-(the standalone `utils/pdda/pdda-gh-refresh.sh`) on the same hourly cron/launchd cadence, **before**
PROJECT/PDDA.md-1014-the suite, so `issue-doc-sync` and the Stop doc-health scan read fresh state. It is the only step that
PROJECT/PDDA.md-1015-needs `gh`/the network; it writes `PDDA_GH_STATE_CACHE` atomically and leaves the existing cache
--
PROJECT/PDDA.md-1110-- forbid hardcoded absolute paths
PROJECT/PDDA.md-1111-- run deterministic checks hourly
PROJECT/PDDA.md-1112-- let the LLM reviewer flag readiness issues
PROJECT/PDDA.md:1113:- keep `ROADMAP.md` pointer-only (deterministic `pdda.sh roadmap` + the LLM rubric guard it)
PROJECT/PDDA.md-1114-- append all script activity to `PROJECT/PDDA-ACTIVITY.jsonl`
    90	Target Date: 2026-08-01
    91	Codename: Quicksilver
    92	Description: Python-authoritative Tier-A twins. Licensed AGPL-3.0-only (`LICENSE`) with a commercial option (`LICENSE-COMMERCIAL.md`), adopted 2026-07-29 post-ship; the pre-existing conflicting `LICENSE.md` was removed 2026-07-30 (#372).
    93	GH_URL: [GH 308](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/308)
    94	Milestone: Quicksilver
    95	Front-door reviewed: No
    96	Shakedown reviewed: No
    97	License file: Yes
    98	
    99	Release: 0.2.0
   100	Iterations: 0.2.0-0.2.4
   101	Status: Shipped
   102	Shipped: 2026-08-14 — RC 2026-08-09 on `development` @ `263816c`, soak window 5 days, re-verified at ship on `86ba3bd5`: `bash test/litmus-release.sh --release-gate` → exit 0, 6/6 complete, 0 false completion claims. **The ship test was the release's own exit command, not an issue-state audit.** Convention settled 2026-08-14: an exit criterion that is MET *is* the definition of done; a release is not held open by issues it never named. Falsification check on the soak window found nothing — every issue filed 08-09 → 08-14 (#485, #491, #499, #503, #504, #509, #510, #514, #518, #520, #521, #522, #523, #525, #527, #528, #533, #534, #536, #539, #540, #542, #544) either shipped inside it or left the exit command green, and the command was re-run on a `development` containing all of those fixes.
   103	Target Date: 2026-09-05
   104	RC evidence: `bash test/litmus-release.sh --release-gate` → `GOALPOST MET — all 6 manifest entries complete` (6/6, 0 remaining, 0 false completion claims). Its own negative control, `--mutate-evidence`, was re-run on the same commit and reports `negative control OBSERVED in both directions (6 pass, 0 fail)` — it detects a stripped declaration, an unregistered gate (the #461 defect), and an invariant violated in either direction. Four of the six issues are CLOSED with per-criterion evidence (#407, #417, #457, #461). **Residual scope, resolved at ship (2026-08-14).** Both entries' gates are registered, green and control-observed — which is what this release's exit criterion measures — but each carried acceptance criteria that did not ship, and an unshipped criterion is not a reason to hold a met goalpost open. **#375 is CLOSED** (this block previously said it remained open; that was stale). **#390's residual is now [#546](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/546), milestoned Meter** — Layer 4's host free-memory floor and packet-driven per-phase overrides, deferred by the source itself at `utils/py/marathon_drive.py:1509` (verbatim: `# Layer 4 (host free-memory floor) and packet-driven per-phase overrides are Phase 2.`). Meter is the right home rather than a parking space: a host floor is a precondition checked before spending, #382 is already a Meter member and its capture doc documents this exact deferral, and #392 is the static counterpart to this runtime one. #546 is **milestone backlog, NOT admitted to Meter's frozen manifest** — it does not make Meter's exit command fail, so "discovery is not admission" applies. #375's shipped three-state `unverifiable` verdict still deliberately contradicts its criteria 1 and 5, because implementing them literally took `relay-self-sufficiency.sh` from 4/0 to 0/4 on a working machine; that is recorded on the issue and is a deliberate deviation, not an omission.
   105	Codename: Litmus
   106	Description: Make the checks capable of failing. Every gate in the Litmus manifest is shown to report red against a real defect, or is explicitly downgraded to advisory — a check never observed failing is not evidence (#419). Ordered first because it is the release that makes the next one measurable. It is also what the self-improvement chain (#431) is blocked on: a Reviewer is a gate, so #419 applies to it, and its qualification gate is currently un-runnable (#428) and has only ever been measured once (#429).
   107	Exit criterion: `bash test/litmus-release.sh --release-gate` exits 0. Red today by design; turning it green is what "done" means. Its own negative control is `--mutate-evidence`, which must detect a stripped declaration and an unregistered gate. NOTE the honest limit, stated in that file: the audit proves registration, declaration shape and the absence of false completion claims. It does NOT prove a control was truly observed, because `gate_inventory.py` reads a declaration authored by the same person who wrote the gate. Recorded execution of each control is deliberately out of scope for this release.
   108	Manifest: FROZEN 2026-08-08 — #375, #390, #407, #417, #457, #461. Six named decision gates, a fixed denominator rather than a percentage. "Every gate" was unshippable prose: `gate_inventory.py` reports 152 of 158 gates with no declared control, and retrofitting them is explicitly out of scope. Adding an entry is a RE-SCOPE, not a bugfix: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission — #457, #460 and #461 were all filed while executing Litmus, which is what an unfrozen boundary looks like.
   109	GH_URL:
   110	Milestone: Litmus
   111	Front-door reviewed: No
   112	Shakedown reviewed: No
   145	Iterations: 0.5.0-0.5.4
   146	Status: Draft
   147	Target Date: 2026-12-12
   148	Codename: Lantern
   149	Description: When the harness fails, the information needed to act already exists inside it — make it say so. Not "add checks": every case was already detected, and some were then described wrongly (a stack trace, a fabricated path, a success exit code, silence). Scope is one epic, deliberately narrow, and deliberately NOT Nightwatch: that milestone owns run lifecycle "even when lifecycle code emits a misleading message" (see the scope boundary above), and none of Lantern's cases violates a lifecycle invariant — they violate the legibility of a failure whose lifecycle handling was already correct. All four members were found in one afternoon during Nightwatch wave 3, which halted three times at zero paid-turn cost; each halt was avoidable from information the system already held. Depends on nothing; independent of Plumbline.
   150	Exit criterion: `bash test/lantern-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it precedes fixing any member, which is the Litmus and Nightwatch ordering and the reason both releases could tell a finished entry from a claimed one. Two halves, the established shape: Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below. Half B **executes** #499's four phases rather than auditing them, since every one of them is a message an operator either receives or does not: a `relay-drive` launch preflight that refuses before spending, a gate refusal that states its real reason, a launcher exit code that survives its wrapper, and a change-impact report. **#358 Phase 2 is the one member with no executable half, and the criterion is written around that rather than pretending otherwise:** it is satisfied by a RECORDED transcript of a real CI failure under `test/baselines/`, and it must NOT be satisfiable by a disposition written in advance — that issue's own capture doc forbids pre-committing one, and an exit criterion that accepted a pre-written verdict would launder exactly the thing #419 exists to prevent. Its own negative control is `--mutate-evidence`, which must unregister a gate, delete a recorded control, and substitute a pre-dated disposition for a real transcript — detecting all three, and re-checking the unmutated inputs green in the same run so an always-red detector cannot pass for one.
   151	Manifest: FROZEN at one issue on creation — #499, which supersedes and closes #494, #495, #496 and #498. Four phases, each shippable alone: relay-drive launch preflight; a gate refusal that states its real reason; a launcher whose exit code survives plus a gate-readiness check; and a change-impact reporter. Freezing at one is the whole point — these were filed as four and unified precisely to stop a single coherent change spreading across four PRs. **RE-FROZEN AT TWO on 2026-08-11 by explicit operator decision — #499, plus #358 Phase 2.** Recorded as a re-scope rather than an edit, because the admission rule below is worthless if a manifest can grow quietly: the operator named the entry and the release, which is the documented way past the rule, and this line says so with a date instead of just showing two items where there was one. It is a genuine fit, not a parking space — Phase 2 is a *disposition* that turns a lost concurrent-append record into a failure naming its own terminal lock state, which is Lantern's subject exactly, whereas the run lifecycle it sits inside was already handled correctly (that is the Nightwatch boundary, and it is why Phase 1 belonged there and Phase 2 does not). It was briefly a Meter member the same day and moved here before either release started; Meter's block records the move from its side. **#358 keeps its Nightwatch milestone** — it is a frozen entry counted in Nightwatch's RC evidence, so only its scope moved, and this is the second Lantern member not enumerable by `gh issue list --milestone Lantern`. Adding a further member is a RE-SCOPE, not a bugfix, per the Litmus rule above.
   152	GH_URL: [GH 499](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/499)
   153	Milestone: not created yet. The original reason — "#499 is unmilestoned by design while Nightwatch is the active goalpost" — expired when Nightwatch reached RC on 2026-08-11, and is kept here only so a reader does not act on it as if current. Creating it is a live decision, not a formality: **neither member would be enumerable by it as things stand** (#499 is unmilestoned, and #358 keeps its Nightwatch milestone deliberately), so the milestone would join nothing until #499 is assigned. The `Manifest:` line below is this release's authoritative scope either way.
   154	Front-door reviewed: No
   155	Shakedown reviewed: No
   156	License file: Yes
   157	
   158	Release: 0.6.0
   159	Iterations: 0.6.0-0.6.4
   160	Status: Draft
   161	Target Date: 2026-09-26
   162	Codename: Meter
   163	Description: A run accounts for what it spends and checks what it requires before spending it. Every member was found the same way — a real unattended marathon against `Hypercart-Dev-Tools/rebalance-OS` — and each one costs the operator something no gate ever reports: ten ready lanes blocked by two unrelated pre-existing test failures (#378); a builder killed by a $0.50 budget and escalated as a failed pre-advance gate, its `terminal_reason: budget_exhausted` left in an unreferenced temp file (#379); 108 of the target's own `permissions.allow` grants silently dropped because the directory was never trusted interactively, invisible in preflight, stdout and the escalation alike (#380); a host kernel-panicked under memory pressure while the run's telemetry reported tokens and wall-clock and nothing about memory (#382); and three codex builds plus three agy reviews spent re-running work the driver already had, because the cheap gate-only path exists but nothing points at it and `--retry` silently takes the expensive one (#491). Depends on Nightwatch — #382's numbers need a durable place to land, which is exactly what Nightwatch built. Independent of Plumbline and Lantern.
   164	**RE-SCOPED 2026-08-15 by explicit operator decision — Meter is now the public-repository release candidate, and the paragraph above describes what Meter *was*.** The new sentence is: **XYZ can be handed to a stranger.** An unauthenticated clone reaches a documented entry path and exercises a supported happy path with no private context, from a tree that has been sanitized and secret-scanned. The metering work was not abandoned and it was not finished — five of its seven entries moved intact to Sundown (0.8.0), where they keep their capture docs, their acceptance criteria and their evidence. Recorded here as a re-scope with a date rather than presented as a release that always meant this, because a codename that quietly changes its subject is the same defect as a manifest that quietly grows. The reason for reusing Meter rather than opening an eighth release is that the operator named it: publication is the next thing that happens to this repository, and a launch release parked behind five unrelated engineering entries would have shipped late for reasons that have nothing to do with whether a stranger can clone it.
   165	Publication target — **the deliverable is a sanitized clone, not this repository.** The public artifact is a new working tree cut from `development`, stripped of runtime state and internal working documents, committed as **fresh history with a single initial commit**, and pushed to **https://github.com/HiQS-Suite/XYZ-forge** — a new repository in a different organization, named by the operator on 2026-08-15, which becomes XYZ's permanent home. `CHANGELOG.md` is carried forward verbatim and is the public record of the project's history — it is a *file*, so it survives a fresh-history cut intact, and carrying 2,147 commits was rejected on 2026-08-15 for a stated reason: every document removed during sanitization stays reachable in a carried history, which makes the full-history secret scan this release requires a scan of everything ever deleted rather than a scan of one tree. Fresh history makes the sanitization complete by construction. `.tick/` (161 MB of runtime event state) and `relay-system/` (32 MB of relay transcripts) do not ship. `PROJECT/` ships as an **empty PDDA scaffold** plus the Meter build documents retained deliberately as a worked example of how PDDA is used — the method travels, the backlog does not.
   166	Scope boundary — Meter vs Lantern: **Lantern owns how a failure is described; Meter owns what a run consumed and what it required.** Route by asking whether the issue names a *resource or a precondition* — dollars, turns, memory, swap, a trusted directory, a green suite — or names *the wording of a verdict whose handling was already correct*. Written down because two members straddle it and the file already has one recorded case (Litmus vs Nightwatch, 2026-08-08) of two descriptions that a competent agent could not route between. **#379 is split by that rule and belongs to both:** the overloaded exit 5 is a Lantern-shaped naming defect, the budget itself is a Meter resource, and the scope boundary above says to split an issue that violates both rather than argue it into one. **#491 is the marginal call and is placed here deliberately** — the re-scoped defect is a help-text and discoverability gap, which reads Lantern, but the invariant it violates is that the harness re-spends paid turns whose results it already holds, and the issue's evidence is a cost measurement.
   167	Exit criterion: `bash test/meter-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it is Meter's first task, before any member is fixed — that ordering is the Litmus and Nightwatch precedent, and it is the whole reason both releases could tell a finished entry from a claimed one. Two halves, same shape as Nightwatch's: Half A audits the frozen manifest (each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below) and Half B EXECUTES the cases rather than auditing them — a run against a red-suite target proceeds under a recorded baseline and halts on a *new* failure; a budget-exhausted builder is escalated as budget-exhausted rather than pre-advance-failed; an untrusted target is reported before the first paid turn rather than after; a phase boundary records memory and swap; and a re-fire of an already-satisfied phase runs only the gate and says so. Its own negative control is `--mutate-evidence`, which must unregister a gate and delete a recorded control in a fixture copy, detect both, and re-check the unmutated inputs green in the same run. **RE-SCOPED 2026-08-15 with the release.** The command is unchanged and the two-half shape is unchanged — that shape is the reason Litmus and Nightwatch could tell a finished entry from a claimed one, and it is retained deliberately. What changed is what the halves measure, because a gate that audits a manifest which no longer exists is not a gate. **Half A audits the launch artifact**: the sanitized clone exists at the declared path and is a repository with exactly one commit; `CHANGELOG.md` is present and byte-identical to this repository's; `.tick/`, `relay-system/` and `temp/` are absent; `PROJECT/` contains the PDDA scaffold and the retained Meter example and nothing else; `LICENSE` and `LICENSE-COMMERCIAL.md` are present and mutually consistent; and the secret scan's recorded result names its tool version and the exact commit it scanned. **Half B EXECUTES the stranger's path rather than auditing it**: a clone taken with no credentials, from the published commit, reaches the documented entry point and completes one supported happy path with no file, token, or environment variable that exists only on the author's machine. Its own negative control, `--mutate-evidence`, is likewise re-pointed: in a fixture copy it must plant a private path in a tracked file, remove `CHANGELOG.md`, and leave a `relay-system/` directory behind, detect all three, and re-check the unmutated inputs green in the same run. **The gate is RED on arrival and is Meter's first task, before any sanitization is performed** — same ordering as the two releases that shipped.
   168	Manifest: FROZEN 2026-08-11 on creation — #378, #379, #380, #382, #491. **RE-SCOPED TO SIX on 2026-08-12 by explicit operator decision: #509 admitted.** **RE-SCOPED TO SIX on 2026-08-14 (second decision the same day): #509 RETIRED as complete.** Its two unchecked criteria are not unfinished work — they are blocked by a LATER deliberate decision, GH-544, which retired hosted CI for the private phase. *"A push cannot cancel a running workflow_dispatch boundary run"* is now vacuously true and permanently unwitnessable: `ci.yml` carries only `workflow_dispatch:`, so no push can start a run, and you cannot control-test an interaction between two triggers when one of them no longer exists. *"A green hosted macOS full run exists for a chosen commit"* cannot be satisfied without spending the Actions minutes #509 existed to stop and #544 formally stopped. GH-544 already records that debt in its own terms and owns the re-arm trigger (the repo goes public), so keeping #509 open under Meter tracked the same gap twice while making the manifest look one item larger than it is. Phases 1-5 shipped. **RE-SCOPED TO SIX on 2026-08-14 by explicit operator decision: #551 admitted, and the target date pulled in from 2027-01-16 to 2026-09-26 in the same decision.** Recorded as a dated re-scope for the third time rather than shown as a list that has always had seven — the admission rule is worthless if a manifest can grow quietly, and it is worth as little if the third growth is the one that stops being announced. #551 is the shared root cause under nine open issues (#272, #310, #329, #365, #395, #504, #548, plus the already-closed #314/#440/#549) in which a resolver that cannot determine its answer returns a plausible default instead of refusing. It is a genuine fit on this block's own routing question — it names a **precondition**, not a description of a failure, so it is Meter and not Lantern — and two of its nine (#380, #491) were already Meter members, which is what surfaced it: they were being worked as separate defects when they are one. **RE-SCOPED TO SEVEN on 2026-08-15 by explicit operator decision: #555 admitted.** Recorded as a dated re-scope for the fourth time. #555 is the release's own exit criterion — the prerequisite for the other six being verifiable — so it ships first. The seven frozen manifest entries are #378, #379, #380, #382, #491, #551, and #555. **The date moved because Nightwatch shipped.** This release's only dependency was Nightwatch (#382's numbers needed a durable place to land), that shipped 2026-08-14, and Meter has been unblocked since — January was a date set while its blocker was still open and never revisited when the blocker cleared. Adding a further member is a RE-SCOPE, not a bugfix, under the unchanged rule below. Recorded as a re-scope with a date rather than shown as a list that has always had six, because the admission rule below is worthless if a manifest can grow quietly. It is a genuine fit, not a parking space: GH-509 is CI minute burn and route correctness — what a run costs and what it checks before spending — which is this release's sentence almost verbatim. The operator named the entry and the release, which is the documented way past the rule. Its plan is `PROJECT/2-WORKING/GH-509-CI-MINUTE-BURN.md`, replanned the same day on the macOS-target reframe and reviewed by agy. All six are milestoned Meter, so the ledger and `gh issue list --milestone Meter` cannot drift apart. **#358 Phase 2 was a member for part of 2026-08-11 and was moved to Lantern by operator decision the same day, before any Meter work began.** Recorded rather than quietly dropped: a frozen manifest whose membership changes without a trace is not frozen, and the honest version of "we got the routing wrong for an afternoon" is a dated line, not a clean list. It was the only entry blocked on an *observation* rather than on work, and the only one with no executable half — both of which now sit in Lantern's exit criterion, which is where the reasoning for them lives. The move is also correct on the boundary this block defines: Phase 2 produces a failure that states its own reason, which is Lantern's subject, not a resource or a precondition. Adding an entry is a RE-SCOPE, not a bugfix, under the same admission rule Litmus and Nightwatch used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission. **RE-SCOPED TO TWO on 2026-08-15 by explicit operator decision — the fifth dated re-scope of this manifest, and the only one that replaces the release's subject rather than extending it.** The seven engineering entries are dissolved. **#380 is CLOSED and shipped under the original scope**; it stays milestoned Meter as delivered work and is not a launch member — retiring a manifest does not un-ship what it produced. **#378, #379, #382, #491 and #551 move intact to Sundown (0.8.0)**, keeping their capture docs, their verbatim acceptance criteria and their milestone history; none of them was dropped, deferred without a home, or quietly closed. **#546 moves with them as Sundown backlog** — it was Meter milestone backlog and never a manifest entry, and it follows the subject it belongs to rather than the codename it happened to sit under. **The two frozen launch entries are #555 and #563.** #555 is the release's own exit criterion, re-pointed by the paragraph above and unchanged in its role: it ships first and it arrives RED. #563 is the launch checklist authored by an external reviewer (Codex Sol High) and covers the release boundary, public onboarding and behavior, the secret and privacy review, and the legal/CI/publication sequence. Freezing at two is the Plumbline precedent (frozen at one on creation) and is deliberate: the checklist was written as one coherent cutover and splitting it across issues is exactly what that precedent exists to prevent. **Scope is CLOSED to further admission by explicit operator instruction on 2026-08-15** — no issue filed after this date joins this manifest, and the standing admission rule below is superseded for this release only, because a launch whose scope can still grow does not have a date. Anything discovered during execution is filed, milestoned Sundown or left unmilestoned, and **waived in writing per #563's rule: a waiver names the failed criterion, the owner, the reason and the follow-up issue — silence is not a waiver.** Two known open items are covered by that rule rather than admitted: **#564** (31 unaudited suites that can reach the caller's clone through an empty fixture path) and **#544**'s re-arm debt (hosted CI fires on nothing while the repository is private, and going public is its own documented trigger). Both bear on publication and neither is a launch member; both need a waiver or a fix before the gate is called green.
   169	Manifest-Members: 555 563
   170	GH_URL: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/563
   171	Milestone: Meter
   172	Front-door reviewed: Yes
   173	Shakedown reviewed: Yes
   176	Release: 0.7.0
   177	Iterations: 0.7.0-0.7.4
   178	Status: Draft
   179	Target Date: 2026-09-12
   180	Codename: Ballast
   181	Description: Post-launch hardening: **the launched repository holds up under a stranger's first run and an outside contributor's first push.** Every member was found the same way — by pointing the launch machinery at its own published output: the first fresh-clone runs of the public repository produced a different failing set each time (#15), a push gate that does not travel with clones got worse the moment the repo went public (#4), and the kernel's own event log can drop events on the concurrent path the kernel exists to coordinate (#14). Ballast exists because publication moved the failure surface from "our machines" to "everyone else's", and nothing in the shipped tree tests that surface. Builds on Meter's publication; depends on nothing unshipped.
   182	Exit criterion: `bash test/ballast-release.sh --release-gate` exits 0. **NOT BUILT — writing it is Ballast's first task, before any member is fixed** (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. **Half A audits the frozen manifest:** each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. **Half B EXECUTES the stranger's path rather than auditing it:** (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. **BUILT 2026-08-17.** `test/ballast-release.sh` written and registered in `validate.sh`; suite mode green (`--mutate-evidence` 7/0). Half A: 3 of 4 manifest members complete (#14, #15, #3 — gate/registration/control/CLOSED-issue all confirmed); #4 landed the same day this file was written, so its CLOSED-issue credit is pending the next suite run. Half B's mechanics were smoke-tested end-to-end (all four sub-checks — B1/B2a/B2b/B3 — execute correctly against a real disposable clone) but **`--release-gate` has not yet been run for real** (the full ten-run stranger pass, against a clone cut from the commit that carries all four fixes) — that run is the actual goalpost and is still red pending it, honestly, not silently.
   183	Manifest: FROZEN 2026-08-16 on creation — #14, #15, #4, #10, #3. Five entries, a fixed denominator rather than a percentage. Same admission rule Litmus and Nightwatch used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission. **#14 and #15 SHIPPED 2026-08-17** (PR #21, PR #20; each closed with evidence — atomic-write negative control, 10/10 consecutive parallel fresh-clone runs). **#3 SHIPPED 2026-08-17**: the durable-default and path-printing halves were already landed pre-freeze (GH-430); the sole remaining gap, a recorded negative control, closed the same day (`test/baselines/GH-3-state-dir-negative-control.md`) — closed as landed, not re-scoped or swapped. **#10 CUT 2026-08-17, invoking its own pre-declared contingency**: a driven marathon attempt (builder agy, reviewer codex, round-cap 5) escalated after 5 rounds without landing — the suite count the fix would need to touch grew from the estimated ~31 to 73 with zero mechanically adopted, and the builder self-issued a scope waiver rather than flagging the blocker back to the orchestrator. This is exactly the scope-slip the freeze anticipated ("#10 is the designated cut if scope slips... #1's clone-identity bracket already covers the same ground *detectably* in the meantime"); cut per that pre-authorized contingency rather than re-fired. Issue #10 stays open, un-closed by this cut — the underlying containment gap remains real, just descoped from Ballast. Manifest reduced from 5 to 4 entries; this is a recorded re-scope, not a silent drop.
   184	Manifest-Members: 14 15 4 3
   185	Explicit non-goals, stated so they are not silently absorbed: #16 (hosted CI re-arm — tracked separately, explicitly NOT in scope, the local pre-push gate stays the only gate), #9 (tooling floor: eslint/prettier, src/ coverage, decompositions), #11 (Sundown twin retirement), #12 (tree diet), #13 (fold scaling — its body was corrected 2026-08-16: it claimed event append is already atomic temp+rename, which was never true; #14 owns making it so).
   186	GH_URL:
   187	Milestone: Ballast
   188	Front-door reviewed: No
   189	Shakedown reviewed: No
   190	License file: Yes
   191	
   192	Release: 0.8.0
   193	Iterations: 0.8.0-0.8.4
   194	Status: Draft
   195	Target Date: 2026-10-17
   196	Codename: Sundown
   197	Description: Retire the twelve frozen Bash twins. Three steps, in order: (1) sweep for real `XYZ_PYTHON=0` usage — if nothing sets it, the fallback is already dead in practice; (2) re-vendor every fleet `.xyz/` copy onto the Python lane (`xyz-sync.sh list` is the worklist); (3) delete the twins and retire the GH-308 edit-guard, keeping only its no-new-Bash half (GH-551). Not before steps 1-2: the vendored fleet still runs the Bash path, and `XYZ_PYTHON=0` is the documented rollback. Depends on nothing in Meter.
   198	**WIDENED 2026-08-15 by explicit operator decision — Sundown receives Meter's five engineering entries.** The release's sentence becomes: **the harness accounts for what it spends, checks what it requires before spending it, and stops carrying the retired Bash lane.** Said plainly rather than argued into one theme: the twin retirement and the metering work are two subjects sharing one release, and they are here together because Meter was re-pointed at publication on 2026-08-15 and these five needed a home that was not a parking space. They arrive intact — same capture docs under `PROJECT/2-WORKING/`, same verbatim acceptance criteria, same evidence — and the honest reading of the widening is that Sundown's date is now less trustworthy than it was, because it absorbed five entries without absorbing any schedule.
   199	**RENUMBERED 0.7.0 → 0.8.0 on 2026-08-16 by explicit operator decision, to open 0.7.0 for Ballast.** Nothing about this release changed except its version: same codename, same target date, same manifest, same milestone. The band moves with it (`0.7.0-0.7.4` → `0.8.0-0.8.4`) because a release's iteration band is part of its identity here, not a separate fact. Recorded as a dated line rather than shown as a block that was always 0.8.0, on the same principle the manifest re-scopes above follow: a version that changes without a trace is indistinguishable from one that was misread. The `(0.7.0)` parentheticals in Meter's re-scope paragraphs were swept to `(0.8.0)` in the same edit — they identify *which release received the transfer*, so leaving them stale would have pointed a reader at a version that no longer exists. `CHANGELOG.md`'s existing entry is **not** swept: it is the append-only record of what was decided on 2026-08-15, when Sundown was 0.7.0, and the renumber is recorded there as its own dated entry instead.
   200	Manifest: **#378, #379, #382, #491, #551**, received from Meter 2026-08-15, plus the twin-retirement work described above, which remains unnumbered until its issues are filed. **#546 is milestone backlog, not a manifest entry** — it followed the metering subject here and does not gate this release, under the standing rule that discovery is not admission. **Not yet frozen.** Freezing requires the twin-retirement issues to exist so the manifest is a fixed denominator rather than a list plus a promise; until then this line is a receipt for the transfer, not a contract. #380 did not move: it is CLOSED and shipped under Meter's original scope, and stays milestoned there.
   201	Exit criterion: **NOT WRITTEN.** Required before this release starts, per the ordering Litmus and Nightwatch both used and Meter is repeating — the gate is built first and arrives RED, because a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one.
   202	GH_URL: pending — api.github.com DNS outage 2026-08-14; file on recovery
   203	Milestone: Sundown
   204	Front-door reviewed: No
   205	Shakedown reviewed: No

2026-08-18T16:10:17.502108Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
codex
## ANSWER

Do not promote GH-28 unchanged. Keep `pdda.sh releases` warn-only permanently; first define a parser/field grammar that can actually see the planned bloat, then add optional `Tracking Issue: #N` pointers and fixture-tested advisory warnings.

## FINDINGS

- [Blocker] The proposed blocking follow-up conflicts with the release-ledger contract: `RELEASES.md` is optional and `pdda.sh releases` “never blocks, even in full mode” ([PROJECT/PDDA.md:627](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/PROJECT/PDDA.md:627), [utils/pdda/pdda.sh:775](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/utils/pdda/pdda.sh:775)). A temporary warning phase followed by blocking is therefore the wrong rollout. Make these warnings permanent; a future strict checker would need a separately approved contract and must not be smuggled into `check_releases()`.

- [Blocker] The scan does not validate a `>4 sentences` exit threshold. It calls Litmus’s six-sentence, 592-character criterion “clean,” while the proposed rule would flag it; it also says bloated entries begin at “6+ sentences” ([GH-28 capture:44-61](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:44)). Resolve that boundary before promotion. Do not split blindly on `.!?`: release prose contains versions, money, paths, abbreviations, commands, and issue identifiers. Use a documented conservative terminal-sentence rule plus a generous length warning, or use length alone for `Exit criterion:`; test the punctuation cases explicitly.

- [Blocker] “Same line-based-check style” cannot detect all of the bloat being cited. The parser extracts only the value on a `Description:` line ([utils/pdda/pdda-lib.sh:489](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/utils/pdda/pdda-lib.sh:489), [utils/pdda/pdda-lib.sh:495](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/utils/pdda/pdda-lib.sh:495)). Sundown has two following narrative paragraphs before `Manifest:` ([RELEASES.md:197](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/RELEASES.md:197), [RELEASES.md:200](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/RELEASES.md:200)). Decide whether continuations are valid and normalize them in the parser, or prohibit them and warn on them. Without that, the detector will report a misleadingly clean ledger.

- [Should] Scope warnings to active/unshipped releases. The existing cleanup workflow deliberately defaults to those and will not alter shipped entries unless explicitly named ([skills/releases/SKILL.md:100](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/skills/releases/SKILL.md:100)). Warning forever on historic blocks that the normal repair path declines to touch creates permanent noise.

- [Should] `Manifest-Members:` needs a contract decision before checking it. The documented/skill threshold is for issue count in `Manifest:` ([PROJECT/PDDA.md:731](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/PROJECT/PDDA.md:731), [skills/releases/SKILL.md:93](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/skills/releases/SKILL.md:93)), while `Manifest-Members:` is presently an undocumented release-gate-specific machine field. Drop its generic bloat warning for now, or specify its syntax and ownership first.

- [Should] `Tracking Issue:` is the right new field, but make it optional, pointer-only, and syntactically local (for example `Tracking Issue: #123`). Do not reuse `Milestone:`—it is explicitly the release→issue-set join key ([PROJECT/PDDA.md:712](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/PROJECT/PDDA.md:712))—or `GH_URL:`, which denotes a GitHub Release object ([PROJECT/PDDA.md:735](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/PROJECT/PDDA.md:735)). Never require or auto-create it.

- [Should] Parser changes are coupled. Its positional unit-separator row is explicitly breaking; both `check_releases()` and `releases-current` must change together ([utils/pdda/pdda-lib.sh:462](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/utils/pdda/pdda-lib.sh:462)). Add fixtures for absent new fields, each warning boundary, multiline behavior, punctuation, shipped-vs-active scope, and parser-slot preservation—the existing test already identifies this silent-shift risk ([test/gh284-p3-release-milestone.sh:167](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/test/gh284-p3-release-milestone.sh:167)).

## RECOMMENDATION

Rewrite the capture to: permanent advisory checks for unshipped blocks, parser grammar first, optional `Tracking Issue: #N`, no `Manifest-Members` rule until specified, and fixture-based threshold evidence—then promote to `2-WORKING`.
tokens used
122,316
## ANSWER

Do not promote GH-28 unchanged. Keep `pdda.sh releases` warn-only permanently; first define a parser/field grammar that can actually see the planned bloat, then add optional `Tracking Issue: #N` pointers and fixture-tested advisory warnings.

## FINDINGS

- [Blocker] The proposed blocking follow-up conflicts with the release-ledger contract: `RELEASES.md` is optional and `pdda.sh releases` “never blocks, even in full mode” ([PROJECT/PDDA.md:627](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/PROJECT/PDDA.md:627), [utils/pdda/pdda.sh:775](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/utils/pdda/pdda.sh:775)). A temporary warning phase followed by blocking is therefore the wrong rollout. Make these warnings permanent; a future strict checker would need a separately approved contract and must not be smuggled into `check_releases()`.

- [Blocker] The scan does not validate a `>4 sentences` exit threshold. It calls Litmus’s six-sentence, 592-character criterion “clean,” while the proposed rule would flag it; it also says bloated entries begin at “6+ sentences” ([GH-28 capture:44-61](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md:44)). Resolve that boundary before promotion. Do not split blindly on `.!?`: release prose contains versions, money, paths, abbreviations, commands, and issue identifiers. Use a documented conservative terminal-sentence rule plus a generous length warning, or use length alone for `Exit criterion:`; test the punctuation cases explicitly.

- [Blocker] “Same line-based-check style” cannot detect all of the bloat being cited. The parser extracts only the value on a `Description:` line ([utils/pdda/pdda-lib.sh:489](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/utils/pdda/pdda-lib.sh:489), [utils/pdda/pdda-lib.sh:495](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/utils/pdda/pdda-lib.sh:495)). Sundown has two following narrative paragraphs before `Manifest:` ([RELEASES.md:197](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/RELEASES.md:197), [RELEASES.md:200](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/RELEASES.md:200)). Decide whether continuations are valid and normalize them in the parser, or prohibit them and warn on them. Without that, the detector will report a misleadingly clean ledger.

- [Should] Scope warnings to active/unshipped releases. The existing cleanup workflow deliberately defaults to those and will not alter shipped entries unless explicitly named ([skills/releases/SKILL.md:100](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/skills/releases/SKILL.md:100)). Warning forever on historic blocks that the normal repair path declines to touch creates permanent noise.

- [Should] `Manifest-Members:` needs a contract decision before checking it. The documented/skill threshold is for issue count in `Manifest:` ([PROJECT/PDDA.md:731](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/PROJECT/PDDA.md:731), [skills/releases/SKILL.md:93](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/skills/releases/SKILL.md:93)), while `Manifest-Members:` is presently an undocumented release-gate-specific machine field. Drop its generic bloat warning for now, or specify its syntax and ownership first.

- [Should] `Tracking Issue:` is the right new field, but make it optional, pointer-only, and syntactically local (for example `Tracking Issue: #123`). Do not reuse `Milestone:`—it is explicitly the release→issue-set join key ([PROJECT/PDDA.md:712](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/PROJECT/PDDA.md:712))—or `GH_URL:`, which denotes a GitHub Release object ([PROJECT/PDDA.md:735](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/PROJECT/PDDA.md:735)). Never require or auto-create it.

- [Should] Parser changes are coupled. Its positional unit-separator row is explicitly breaking; both `check_releases()` and `releases-current` must change together ([utils/pdda/pdda-lib.sh:462](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/utils/pdda/pdda-lib.sh:462)). Add fixtures for absent new fields, each warning boundary, multiline behavior, punctuation, shipped-vs-active scope, and parser-slot preservation—the existing test already identifies this silent-shift risk ([test/gh284-p3-release-milestone.sh:167](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-32467-_dakx9i4/test/gh284-p3-release-milestone.sh:167)).

## RECOMMENDATION

Rewrite the capture to: permanent advisory checks for unshipped blocks, parser grammar first, optional `Tracking Issue: #N`, no `Manifest-Members` rule until specified, and fixture-based threshold evidence—then promote to `2-WORKING`.
