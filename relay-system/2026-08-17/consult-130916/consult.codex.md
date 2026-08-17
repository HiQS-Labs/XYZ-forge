**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.6-terra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
2026-08-17T20:09:17.202123Z ERROR codex_models_manager::cache: failed to load models cache: missing field `base_instructions` at line 96 column 5
OpenAI Codex v0.144.6
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb
model: gpt-5.6-terra
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 01a01157-bbe8-7ea1-95a8-e6ac2a2407e9
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
Please review the implementation of GH-23 (kernel path-overlap enforcement) on this branch:
1. src/claim.js: checks setsOverlap(paths, otherClaimedPaths) under withClaimLock; returns won: false, overlap: true, and unavailable reason unless --force is passed.
2. src/scope.js: wraps scope in withClaimLock; checks setsOverlap(paths, otherClaimedPaths) and throws an error unless --force is passed.
3. bin/tick: wires --force flag on claim and scope, formats failure message, and exits 1.
4. test/gh23-path-overlap-enforcement.sh: 8 regression assertions.

Critique correctness, edge cases (e.g. idempotent re-claim by same owner, epoch fencing, concurrency under claim lock), and test completeness. Output your findings and recommendation.
hook: SessionStart
hook: SessionStart Completed
codex
I’ll inspect the routed project guidance and the GH‑23 implementation/tests, then give a read-only, line-cited review.
exec
/bin/zsh -lc "pwd && rg --files -g 'WORKTREE-SAFETY.md' -g 'ROUTER.md' -g 'GUIDING-PRINCIPLES.md' -g 'src/claim.js' -g 'src/scope.js' -g 'bin/tick' -g 'test/gh23-path-overlap-enforcement.sh' -g 'package.json' | sort" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb
 succeeded in 0ms:
/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb
GUIDING-PRINCIPLES.md
ROUTER.md
WORKTREE-SAFETY.md
bin/tick
package.json
sandbox-app/package.json
src/claim.js
src/scope.js
test/gh23-path-overlap-enforcement.sh
tools/vscode-cockpit/package.json

mcp: codebase-memory-mcp/index_status started
mcp: codebase-memory-mcp/index_status (failed)
user cancelled MCP tool call
exec
/bin/zsh -lc "sed -n '1,240p' WORKTREE-SAFETY.md; sed -n '1,260p' ROUTER.md; sed -n '1,220p' GUIDING-PRINCIPLES.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb
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

mcp: codebase-memory-mcp/index_repository started
mcp: codebase-memory-mcp/index_repository (failed)
user cancelled MCP tool call
exec
/bin/zsh -lc "wc -l WORKTREE-SAFETY.md ROUTER.md GUIDING-PRINCIPLES.md README.md ROADMAP.md; rg --files PROJECT | rg 'GH-23|23-.*(CLAIM|PATH|OVERLAP)|PATH.*OVERLAP' || true; sed -n '241,520p' WORKTREE-SAFETY.md; sed -n '261,520p' ROUTER.md; sed -n '221,440p' GUIDING-PRINCIPLES.md; sed -n '1,240p' README.md; sed -n '1,240p' ROADMAP.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb
 succeeded in 0ms:
     416 WORKTREE-SAFETY.md
     116 ROUTER.md
     149 GUIDING-PRINCIPLES.md
     535 README.md
     366 ROADMAP.md
    1582 total
PROJECT/2-WORKING/GH-23-KERNEL-OVERLAP-ENFORCEMENT.md
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

## 12. Other footguns worth knowing before scripting worktrees

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
# XYZ — Multi-Agent Coordination Beta

**XYZ lets several AI coding agents — Claude Code, Codex, and agy (Google's Antigravity CLI) — work
on the same repo at the same time without overwriting each other's work.**

## What XYZ is

It's built in two layers:

- **`tick`** — the kernel: a tiny local event-log CLI that hands out collision-free, path-scoped
  work claims, so two agents never edit the same thing at once. No server, no API keys, no remote.
- **`relay-automation/`** — the product on top of `tick`: it runs agents in **turns** (one builds,
  another reviews) headlessly, so you can hand a task to Codex or agy and let them iterate toward
  done without babysitting the handoff.

It's a working beta, not a polished product — but the kernel is test-covered and the relay stack
is the main active surface.

## Quickstart — prove it works (no accounts needed)

Requires **Node 18+** and **git** (the `tick` kernel runs on Node). No accounts or API keys.

```bash
npm install
bash githooks/install.sh   # contributors: wires the pre-push gate (correctness requirement)
./validate.sh
```

(`npm install` pulls the two parser dependencies the test suite needs — skip it and the
suite stops at `Cannot find module 'acorn'`.)

**If you are going to push to this repo, run `bash githooks/install.sh` once per clone. It is a
correctness requirement, not optional setup.** The local gate catches failures before a push; hosted
CI independently checks public-repo changes afterward. The hook lives in `.git/hooks/`, which does
not travel with a clone, so skipping this step removes the early boundary even though hosted CI may
still run later. One run covers every branch and linked worktree of that clone (GH-549).
`./validate.sh` itself warns, in-band, if this clone is ungated — check
directly any time with `bash githooks/install.sh --check`. (Just evaluating the project and never
pushing? The warning is informational only — `validate.sh` still runs and exits exactly as it
would gated.)

That runs the full kernel + coordination test suite, with **no accounts or API keys required** —
the fastest proof the coordination kernel actually works. It's the whole suite, not a smoke test,
so **budget 5–10 minutes** on a first run. The suite prints its own pass count at the end; if it's
green, you're good.

> **⚠️ Run this un-sandboxed.** Under Claude Code's default Bash sandbox — or any sandboxed agent
> harness — this command prints **nothing for several minutes** before failing, because the suite's
> `mktemp -d` scratch directories are blocked. It looks like a hang, not a permissions error, and
> it is this repo's single most common false alarm. Turn the sandbox off for this command
> (`/sandbox` in Claude Code, or run it yourself in a normal terminal) before concluding anything
> is broken.

## Then pick your path

- **New here for the beta test?** → start at [Beta Tester Onboarding](#beta-tester-onboarding) below.
- **Run a live relay** — hand a real task to Codex/agy and let them build→review it →
  start at **[relay-automation/README.md](relay-automation/README.md)**. Live turns need each CLI
  installed and authenticated first: see
  **[Set up Codex, agy, and Pi](relay-automation/README.md#set-up-codex-agy-and-pi-headless-bring-up)**.
  For phase/status context, the project hub is
  [PROJECT/4-MISC/AUTOMATED-RELAY.md](PROJECT/4-MISC/AUTOMATED-RELAY.md).
- **Connect live agent sessions by a short ID** — start a serialized discussion with two or more
  Claude, Codex, or other skill-aware sessions → see [Agent2Agent](#agent2agent--live-sessions-by-compact-id).
- **Here for the kernel** — how the `tick` coordination primitive works →
  read [What `tick` is](#what-tick-is), then the source in [bin/tick](bin/tick), [src/](src), [test/](test).
- **Install `tick` into another repo** → see [Install into another repo](#install-into-another-repo).

> **Editing this repo as an agent?** Read [ROUTER.md](ROUTER.md) for the startup order and canonical
> entry points. It's the map for *working on* the repo, not for *using* it — a human landing here
> should start with the Quickstart above.

---

> **⏳ Beta-testing period:** the onboarding guide below runs for the duration of the beta. Once the
> beta wraps, this section moves out and the README continues straight from
> [What XYZ is](#what-xyz-is) above. Historical design discussion: legacy source issue #123.

## Beta Tester Onboarding

**TL;DR:** You can get immediate value from **Relay** and **Consult** with just this XYZ repo — no
PDDA required. PDDA installation is only needed if you want the full eventual automation path
(**Swarm** and especially **Marathon**). Start with the fast path, graduate to PDDA later if you
like what you see.

Background links (not required for this test):

- GiantBrains Claude Skills — https://github.com/Claude-AI-Tools-Ventura-County/giant-brains-claude-skills
- PDDA (the doc-governance half of the system) — https://github.com/Hypercart-Dev-Tools/pdda

### The four modes of operation

XYZ has four modes. They stack — each one builds on the trust you develop with the previous:

1. **Consult** — a one-shot, parallel second opinion. The same question fans out to Codex and agy
   at the same time, each answers independently in an isolated copy of the repo, and the answers
   are reconciled into one. Nothing is modified; it's purely advisory. Lowest risk, fastest payoff.
2. **Relay** — an iterative, turn-based loop between two agents on one shared file: a **Producer**
   builds an artifact, a **Reviewer** critiques and proposes fixes, and they hand off back and
   forth until the artifact converges. This replaces you copy-pasting output between two agent
   windows. Changes are confined to the relay thread file and the artifact under review.
3. **Swarm** — two or more agents working **concurrently** on the same repo, each claiming a
   non-overlapping, path-scoped lane (via the `tick` kernel) so they never collide. Good for
   parallel builds or parallel codebase recon. This is where PDDA's doc structure starts to matter,
   because lanes are carved from well-defined task docs.
4. **Marathon** — the full automation payoff: a queue of pre-flighted tasks (built up during the
   day) fired as one long autonomous run, typically end-of-day or overnight. Marathon **requires**
   PDDA, because the preflight scripts rely on PDDA's opinionated docs/roadmap structure to verify
   every queued task is well-specified before anything runs unattended.

How they fit together: **Consult** answers "what do the other models think?", **Relay** answers
"build this and have it reviewed until it's right", **Swarm** answers "do several independent
things at once", and **Marathon** answers "do all of today's queued work while I sleep." Consult
and Relay need only this XYZ repo. Swarm and Marathon are where PDDA earns its setup cost.

### Agent2Agent — live sessions by compact ID

**Agent2Agent is the general-discussion face of Relay:** it drops Producer/Reviewer vocabulary,
allows a declared roster of two or more live sessions, and keeps exactly one active writer through
the relay file's existing `NEXT:` field. It is local and serialized, not a chat server: every
participant must be able to see the same XYZ clone, and parallel writes/broadcasts are deliberately
out of scope.

Install the repo-backed skill for both Claude Code and Codex (idempotent):

```bash
bash skills/agent2agent/install.sh
```

Then ask the first session to start a discussion, for example: *"Start XYZ agent2agent with four
agents to discuss: subject line here."* It seeds turn 1 as `agent1`, creates a collision-checked
six-digit ID under `relay-system/<date>/`, and prints a copy/paste invitation:

```text
Join XYZ agent2agent #123456 as agent number two to discuss: "subject line here"
```

Paste that one line into the target session. The same skill validates the ID and subject, reads the
durable discussion, and responds only if that participant owns `NEXT:`. Each successful turn prints
the next compact invitation, which can route to `agent1`, `agent3`, `agent4`, or any other member of
the original roster. Two operating levels are available: read-only `watch` polls every 150 seconds
by default, while `drive` is an explicit, bounded opt-in that invokes an approved turn command only
when that participant owns `NEXT:`. See [the agent2agent skill](skills/agent2agent/SKILL.md) for the
deterministic `start`/`join`/`watch`/`drive`/`send`/`close` contract.

### Before you start — safety and reversibility

Everything below is designed to be reversible, but please help it along:

- **Create a fresh branch (or git worktree) in *both* repos you touch** — one in your clone of
  XYZ, and one in each target project where you'll run relays or install PDDA. E.g.
  `git checkout -b xyz-beta-test`. If anything goes sideways, recovery is just
  `git checkout main` and deleting the branch. If you use `git worktree` directly, read
  [WORKTREE-SAFETY.md](WORKTREE-SAFETY.md) first — a couple of its operations (force-removing a
  worktree directory, moving/relinking one) leave stale git metadata if done by hand instead of
  through `git worktree remove`/`repair`.
- **What each step actually touches** (so you know how to undo it):
  - *Skill install* — symlinks skill folders into the selected agent's user-level skill directory
    (`~/.claude/skills/` and, where supported, `~/.codex/skills/`). A `git pull` in your XYZ clone
    updates the installed skill through that symlink. Undo: delete the symlink. Your project repos
    are untouched.
  - *Relay runs* — write a dated thread file under `relay-system/<date>/` plus the artifact being
    reviewed, on your branch. Undo: discard the branch.
  - *Consult runs* — advisory only; agents work in isolated copies. Nothing to undo. **Known
    limitation:** the `agy` CLI has been observed grounding its answers against the real repo
    instead of confining itself to its isolated copy, undermining the "isolated" guarantee for that
    one advisor specifically. A detect-and-fail check now catches this case and hard-fails the turn
    rather than silently returning a contaminated answer, though it isn't a complete fix yet — see
    legacy source issues #178 and #183.
  - *PDDA install* — adds scripts and an opinionated `PROJECT/` docs structure to the target repo.
    Undo: it's all ordinary tracked files on your branch, so discarding the branch fully reverts it.
- Clone this XYZ repo locally. Clone PDDA **only** if you're going for the full automation path.

### Prerequisites — install and authenticate these before the fast path

The fast path below shells out to the Codex and agy CLIs. **Install and sign in to both before you
start** — a relay or consult fails mid-run, not at startup, if either isn't logged in.

| Prerequisite | Install | Notes |
|---|---|---|
| **Codex CLI** (OpenAI) | <https://openai.com/index/introducing-the-codex-app/> | Authenticate with your ChatGPT account. |
| **agy CLI** (Google Antigravity — the **CLI**, not just the desktop app) | <https://antigravity.google/product/antigravity-cli> | Authenticate through the Antigravity desktop app. You can hand this URL to Claude Code and ask it to install for you. |
| **Node 18+ and git** | your usual package manager | Needed by the `tick` kernel and the Quickstart above. |
| **Python 3.8+** | usually already present | See the runtime note below. |

#### Hardware sizing for Marathon

**Recommended minimum: 16 GB RAM for the serial `marathon.sh --plan` route.** That minimum covers
one builder and its gate running serially, with normal host reserve; it does **not** support the
`/10days` per-lane parallel dispatch. The two routes are intentionally different: the serial command
works one lane at a time, while `/10days` may start one agent for each lane in a wave.

“Supported” below means a recommended planning envelope that leaves host reserve and is not expected
to swap because of XYZ itself. It is not a guarantee that a target repository's test suite will
finish: that suite's memory use is unbounded and must be supplied by the operator when sizing a wave.

| Host RAM | Supported execution path | Planning guidance |
|---|---|---|
| 16 GB | Serial `marathon.sh --plan` only | Do not use `/10days` per-lane parallel dispatch. |
| 24 GB | Serial route; small `/10days` parallel wave after manual budgeting | Reserve memory for macOS and the target suite before choosing the lane count. |
| 32 GB | Serial route; `/10days` per-lane parallel dispatch after manual budgeting | A practical baseline for a normal parallel wave, subject to the target suite's memory cost. |
| 64 GB | Serial route; wider `/10days` per-lane parallel dispatch after manual budgeting | More headroom for lanes and repository tests; it is still not an automatic wave-width limit. |

For a serial marathon, XYZ measured about **2.2 GB steady**. For `/10days`, budget
**1.5–2 GB per concurrent lane**, then add the target repository's own test suite memory (an
unbounded, operator-supplied term) and the host reserve. In other words, choose a width that fits:
`available RAM − host reserve − target-suite memory`, divided by 1.5–2 GB per lane. Do not infer a
safe width from the table alone for a repository whose tests are memory-heavy.

Measurement provenance: on a **32 GB M1 Max**, 138 samples taken at **10-second intervals** while a
builder, an agy reviewer, and three pytest gates were active measured a serial marathon at **2.19 GB
average steady-state**, with a **2.26 GB peak**. Re-measure when the agent mix, gate command, or host
meaningfully changes.

`kernel ≤ 1 per wave` is a **coordination/zone cap, not a memory cap**. It is configured through
`maxPerWave` in `utils/marathon-plan-zones.default.json` and applies independently of write-set
collisions: it constrains which lanes may share a wave, never how much RAM they consume.

XYZ does have per-gate resource containment: the GH-390 gate guard enforces **wall-clock, CPU and
RSS** caps and kills an over-budget gate. It does **not** currently inspect host RAM, clamp a wave
width, or refuse a wave that is too large for the machine. Host-aware wave sizing remains the
operator's responsibility.

The caps come from a **tier**, so there is one place to look rather than a rule per gate:

| Tier | Wall | CPU | Use |
|---|---|---|---|
| `full` (default) | 1800s | 1200s | a whole-suite gate; sized ~1.9× the worst observed run |
| `fast` | 300s | 240s | a targeted gate, where minutes already means runaway |

RSS is not tiered: it defaults to 8192 MB. A gate the guard kills exits **108**, and the phase
escalates as `gate-killed` — deliberately distinct from `pre-advance-failed`, so a gate that ran out
of time is never triaged as a gate that found a defect.

| Variable | Effect |
|---|---|
| `MARATHON_GATE_TIER` | pick `full` or `fast` |
| `MARATHON_GATE_WALL_S` | override the tier's wall cap |
| `MARATHON_GATE_CPU_S` | override the tier's CPU cap |
| `MARATHON_GATE_RSS_MB` | override the RSS cap (default 8192) |
---
title: Combined Roadmap — Cost-Observed Marathon Loops + Adversarial Hardening
status: Active
created: 2026-06-16
updated: 2026-07-08
branch: main
supersedes: PROJECT/2-WORKING/ROADMAP-COMBINED.md (promoted to canonical 2026-06-17); folds in the former standalone ROADMAP.md (adversarial-hardening track, now Part B)
synthesizes:
  - PROJECT/1-INBOX/LOOPS.md
  - PROJECT/4-MISC/COST-OBSERVABILITY-PLAN.md
  - PROJECT/1-INBOX/MARATHON.md
goal: >
  Canonical pointer/ledger index for the repo's work — queued intake, projects in progress,
  completed, attempted, and deferred — linking to the canonical PROJECT/** docs that own the
  execution detail. This is an index, not a plan body.
---

<!-- PDDA ROADMAP CONTRACT — this file is a POINTER/LEDGER, not a plan body.
     Allowed: queued intake / projects in progress / completed / attempted / deferred + links to PROJECT/** docs.
     NOT allowed: phase checklists, build steps, deep execution notes — put those in the project doc.
     Carve-out: a SHORT exception note is OK only when omitting it would hide an operationally critical fact.
     Coverage rule: every PROJECT/2-WORKING doc must be reflected here by a pointer (or opt out with roadmap_exempt: true).
     Enforced by `utils/pdda/pdda.sh roadmap` + `utils/pdda/pdda.sh roadmap-coverage` (deterministic) + `utils/pdda/pdda.sh doc-ready` ROADMAP rubric (LLM). -->

# Combined Roadmap: Cost-Observed Marathon Loops + Adversarial Hardening

> **Pointer/ledger only — not a plan body.** Execution detail (phase checklists, build steps, QA
> gates, deep notes) lives in the linked `PROJECT/**` docs; keep it there. See the contract banner above.

Three tracks, sequenced independently:

- **Part A — Marathon:** cost observability (done) → headless multi-phase chaining (done) → real-monolith dogfood (active)
- **Part B — Adversarial Hardening:** epoch fencing (done) → chaos suite → cross-repo E2E → reference deploy
- **Part C — Autonomous Self-Improvement:** the gated LOOPS.md endgame

## Status

| What was just completed | What's next |
|---|---|
| **2026-07-04 marathon Wave 2+3, reviewed and merged (PR #125, `d9db49d`):** **GH-55** auto-includes covering tests/helpers in preflight allowlists, **GH-54** forbids in-turn execution of fs-touching tests, and **GH-48** generalized `marathon-plan`'s zone model with a real rebalance-OS live check (#54/#55 closed; #48 stays open pending an operator closure call). Targeted gates are green (`test/swarm-preflight.sh` 75/75, `test/marathon-plan.sh` 57/57); the full `validate.sh` rerun isn't blocked by this wave's files — non-green runs traced to pre-existing `oracle-guard.sh`/`improve-loop-qa.sh` flakiness, not `relay-self-sufficiency.sh`. Independent review before merge filed two non-blocking follow-ups: **GH-126**, **GH-127**. Also closed 2026-07-04: **#113**/**#114** (already fixed in code, left open past landing) and **GH-112** retitled to reflect its spike-to-full-rewrite scope creep (PR #121, now targeting a new `development` branch, not `main`). With Plan B and the blend plan both fully shipped, authored **[Marathon Plan C](PROJECT/3-COMPLETED/MARATHON-PLAN-2026-07-04-C-RELIABILITY.md)** — the dogfood-reliability cluster (#106, #107, #108+#126+#127 bundled, #116 Bug B, #117, #124) — then **fired and shipped it the same day**: Wave 1's 5 parallel lanes (`742c230`, `691848c`, `53c8dce`, `b4e73df`, `6daaff5`) plus the **#107 kernel track** Opus-serial (`524d345`, 31/31, + [decisions record](decisions/2026-07-04-containment-ignore-toolcache.md)), integration commit `d5a1681`, full `validate.sh` exit 0. All 7 commits are ancestors of `main`; all 6 capture docs + the plan are in `3-COMPLETED`. *(The post-merge sweep moved the docs but left this cell and the per-item entries advertising Plan C as unfired — corrected 2026-07-08.)* | **Still open:** **GH-61 Tier 2** (needs operator `macos-latest`/`ubuntu-latest` runner decision). **Operator-driven:** rebalance-OS cross-repo harness dogfood beyond the queue-planner proof; **GH-48** closure call. **Part B:** G2 dup-token determinism (next adversarial-hardening slice). **Queue / parked:** GH-30 Phases 2–5 (writer wiring + risk-4 containment), #94 re-verify-vs-`5972ef4` installer repro. |

### Immediate next-up (ordered)

1. ✅ **Done — GH-51 [1-kernel] fixed (2026-06-30).** `rtl_init` now collapses a same-repo `--target-root` to the caller's root (no-op), so `--target-root .` no longer reverts the relay file off-lane. Decision record + regression test; `validate.sh` 69/69. The remaining GH-51 items ([2]/[3]/[5]) are minor. → [#51](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/51)
2. **Re-open the rebalance-OS cross-repo harness dogfood — now UNBLOCKED** (GH-51 [1-kernel] landed). Converts the #14 fix into a real external-repo proof: drive a scoped rebalance-OS lane via `swarm-preflight --target-root <clone> → marathon-drive`. The highest-value momentum test now that `--target-root` is containment-correct.
3. **[GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md](PROJECT/3-COMPLETED/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md) built 2026-07-04; live rebalance validation corrected one assumption.** The foreign helper lane now classifies correctly as `signed-helper`, but the real 3-lane rebalance queue still stays one wave because only one lane touches that capped zone. Useful proof for the planner; not itself the full cross-repo harness dogfood.
4. **Part B Phase-2 remainder: G2 dup-token determinism** (`test/chaos-dup-token.sh`) — the next adversarial-hardening slice now that **R2 (#52) + G4 are done**. Kernel epoch-fence territory → Opus + `decisions/` record.
5. ✅ **Done — Part C real-agent run PROVEN (2026-06-30, operator GO).** `improve-loop` drove a live `marathon-drive` (**codex builder + agy reviewer**) as `--build-cmd`: baseline 4 → live build → `KEEP` oracle held → champion ACCEPTed (metric 3) → halted on the iteration cap, with provenance. Every safety invariant fired against a real build. The run surfaced two harness defects (neither a loop bug): **#58** (`--builder claude` not on PATH headless — use codex/agy) and **#59** (allowlisted artifact in an untracked dir → spurious off-lane exit 6). → [#50](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/50)

> **Active scheduling overlay:** re-run `utils/marathon-plan.sh` to regenerate after today's ledger update. Last generated: [MARATHON-PLAN-2026-07-02.md](PROJECT/3-COMPLETED/MARATHON-PLAN-2026-07-02.md) (2026-07-02 — stale; the 2026-07-03 wave shipped ~10 items that were in the held list). Derived from this ledger; the ledger stays source of truth.

## Model assignment (heuristic)

Mechanical / pattern-following work → **Sonnet High**; trust-critical kernel-correctness reasoning
(epoch-fencing kernel, dup-token determinism) → **Opus**. Full build-track table:
[MARATHON-HARNESS.md → Model assignment](PROJECT/3-COMPLETED/MARATHON-HARNESS.md#model-assignment-build-track-guidance).

> **Operational note (carve-out — operationally critical):** Gemini CLI retired 2026-06-19; **agy**
> (Antigravity CLI) is the permanent cross-model lane. **Run agy turns sandbox-OFF** (it exits 0 with
> empty output when its backend is blocked) and an agy lane is **cost-blind** (no token output).
> Detail: [MARATHON-HARNESS.md → Operational note](PROJECT/3-COMPLETED/MARATHON-HARNESS.md#operational-note--cross-model-lane).

## Ledger

### Ad-hoc detours
- **GH-23 · Kernel invariant: enforce path-overlap rejection on direct tick claim and tick scope** 🆕 **2026-08-17, active on `fix/gh-23-kernel-overlap-enforcement`** — enforce collision-free path claims at the kernel boundary by rejecting direct `tick claim` and `tick scope` when requested paths overlap active claims held by other agents; wire `--force` bypass; add regression test coverage. → [GH-23-KERNEL-OVERLAP-ENFORCEMENT.md](PROJECT/2-WORKING/GH-23-KERNEL-OVERLAP-ENFORCEMENT.md) · [#23](https://github.com/HiQS-Suite/XYZ-forge/issues/23)
- **GH-173 B3 + GH-178 A1/A4 — three bounded patches, one PR** 🆕 **2026-07-08, [PR #184](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/184)** — **B3**: found the actual uncited-"[Pass]" source is `new-relay.sh`'s scaffolded Reviewer template (not `consult.sh`'s PREAMBLE or `relay-turn-lib.sh`'s generic role_note); added a citation requirement there + a mechanical `rtl_check_uncited_findings()` downgrade in `relay-turn-lib.sh`. **A1**: `consult.sh`'s advisor `case` dispatch is now a data table (`ADV_NAMES`/`ADV_RUNFNS`); "add vendor N+1" recipe in `relay-automation/README.md`. **A4** (deliberately scoped down, not the full firsthand-vs-asserted taxonomy): reused A2's stdout+transcript+sidecar mechanism to stamp `NO FIRSTHAND VERIFICATION CITED` on any advisor answer with zero citations anywhere. All three carry regression tests; targeted suites green. See CHANGELOG `[Unreleased]` and both PDDA docs' Validation tables. → [GH-173-JEDI-WRIGHT-FEEDBACK.md](PROJECT/2-WORKING/GH-173-JEDI-WRIGHT-FEEDBACK.md) · [GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md](PROJECT/2-WORKING/GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md) · [#173](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/173) · [#178](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/178)
- **`/open-router` skill — OpenRouter model-name resolve discoverability** 🆕 **2026-07-08** — `resolve-model-alias.sh` (GH-120) already resolves a colloquial name to a canonical slug locally, but a live session probed `aider --list-models` + curled the live catalog for "GLM 5.2" instead of using it. Added doc pointers (`aider-turn.sh`, `AGENTS.md`) + a new `skills/open-router/SKILL.md` so the alias table is checked first; no behavior change. See CHANGELOG `[Unreleased]`.
- **GH-183 · GH-178 B1's isolation-breach detector false-positives on legitimate agy turns** 🆕 **found 2026-07-08 reviewing PR #182** — the post-hoc `$ROOT`-citation check fails a fully in-bounds agy turn whenever its response narrates the mandatory `TICK_REPO_ROOT="$ROOT"` tick command (ordinary LLM narration); shipped in PR #182 as-is per operator call rather than block the merge. Fix direction: exclude the known tick-command line from the scan, same pattern as the existing `[trace]`-line filter. → [GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md](PROJECT/2-WORKING/GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md) · [#183](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/183)

### Queue / parked intake
- **GH-17 · SOP for evaluating new agent harnesses and frontier models** 🆕 **queued 2026-08-16** — establish a standardized operating procedure, checklist, and per-harness tracking issue workflow for new harness discovery, isolation, non-interactive execution, and cross-model matrix evaluation. → [GH-17-SOP-HARNESS-MODEL-EVAL.md](PROJECT/1-INBOX/GH-17-SOP-HARNESS-MODEL-EVAL.md) · [#17](https://github.com/HiQS-Suite/XYZ-forge/issues/17)
- **GH-18 · Harness evaluation: Command Code (cmd) and model matrix** 🆕 **queued 2026-08-16** — evaluate Command Code CLI (v1.26.0), PATH resolution, auth, non-interactive `-p` execution, and model review benchmarks with `qwen/qwen3.7-flash` and `qwen/qwen3.8-max`. → [GH-18-COMMANDCODE-EVAL.md](PROJECT/1-INBOX/GH-18-COMMANDCODE-EVAL.md) · [#18](https://github.com/HiQS-Suite/XYZ-forge/issues/18)
- **GH-536 · the gate-evidence record was a bare `result: green`** ✅ **BUILT 2026-08-14 on `fix/gh536-gate-evidence`** — the record now carries an `output-sha256` of the suite transcript plus per-suite verdicts, so a reader can tell a real run from a stamped one. **Three of the issue's four premises were factually wrong** (`ci-local.sh` already existed and already refused-if-dirty, ran the suite, and could not record after a failure); its trust-level argument is rejected and the `NOT-promotion-evidence` disclaimer is now pinned by a test — a self-computed hash is tamper-evident, not attested. → [GH-536-EVIDENCE-DETAIL.md](PROJECT/2-WORKING/GH-536-EVIDENCE-DETAIL.md) · [#536](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/536)
- **GH-539 · a gitignored 2-minute skill-sync job resurrects deleted SKILL.md files** 🆕 **diagnosed 2026-08-14, NOT fixed — every candidate fix is cross-repo** — `com.rebalance-os.3eyes.skill-sync` runs every 120s doing a *bidirectional last-writer-wins* sync with `giant-brains-claude-skills`, and that has no representation for a deletion, so a removed skill is written back within two minutes. Preserved mtime (`Aug 11 15:29:08`, identical to the giant-brains source) is what ruled out a git-based restore. **This is the mechanism behind GH-395**, and it means no skill deletion here is durable. **Re-filed against the owning repo as [rebalance-OS#269](https://github.com/Hypercart-Dev-Tools/rebalance-OS/issues/269)** (the job, its registry entry and its plist all live there); #539 stays open as the consumer-side record. → [GH-539-SKILL-SYNC-RESURRECTION.md](PROJECT/2-WORKING/GH-539-SKILL-SYNC-RESURRECTION.md) · [#539](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/539)
- **GH-527 · a destructive git command has no guard, and a doc rail demonstrably will not fix it** ✅ **BUILT 2026-08-14 on `fix/critical-2026-08-14`** — snapshot-then-allow PreToolUse hook copies the doomed *tracked* files into `.tick/orphan-backups/` before the command runs (the GH-141 `rtl_check` precedent), plus the `AGENTS.md` rail naming all three spellings. 26/0; recovery demonstrated end-to-end; clean-tree silence is defended by two conditions so it took a combined mutation to falsify. → [GH-527-DESTRUCTIVE-GIT-GUARD.md](PROJECT/2-WORKING/GH-527-DESTRUCTIVE-GIT-GUARD.md) · [#527](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/527)
- **GH-520 · a fixture that does not stub `CODEX_BIN` tests the reviewer probe, not the code** ✅ **BUILT 2026-08-14** — default `CODEX_BIN` stub declared once in `test/_setup.sh`, the file every fixture already sources, in the same idiom as the GH-402 trunk-guard line. Third recorded instance of the trap; a `ci.yml` comment did not prevent the previous two. Control reproduces the CI failure character-for-character. → [GH-520-DEFAULT-REVIEWER-STUB.md](PROJECT/2-WORKING/GH-520-DEFAULT-REVIEWER-STUB.md) · [#520](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/520)
- **GH-314 · the marathon write set is THREE paths, and the transcript was outside the preflight** ✅ **BUILT 2026-08-14** — GH-514's `preflight_write_set_trackable` cites #314 but checked only `RELAY.md` and `ESCALATION.md`; `save_transcript()`'s `git add` was unguarded, and it is the latest of the three, so both turns were already spent. Control: dropping the path costs **2 paid builder turns** before the same refusal. The `xyz-vendor.sh` half is deliberately not built. → [GH-314-TRANSCRIPT-WRITESET.md](PROJECT/2-WORKING/GH-314-TRANSCRIPT-WRITESET.md) · [#314](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/314)
- **GH-395 · an unreviewed CI push left a duplicate skill dir and a hardcoded tick path** 🚧 **half shipped 2026-08-14 on `quickwins/parked-2026-08-14`** — `skills/ponytail-refined/` (byte-identical to `skills/ponytail/`, nothing live referencing it) is deleted; the hardcoded absolute tick path in the generated-`RELAY.md` template is NOT fixed, and the branch-protection + access-audit half is operator-only, not a lane. → [GH-395-UNREVIEWED-CI-PUSH-CLEANUP.md](PROJECT/2-WORKING/GH-395-UNREVIEWED-CI-PUSH-CLEANUP.md) · [#395](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/395)
- **GH-527 · a destructive git command has no guard, and a doc rail demonstrably will not fix it** 🆕 **parked 2026-08-14 by the /10days sweep — needs a capture doc before it can be preflighted** — three destructive incidents in one session; the issue carries a reproduced fixture and a falsification table showing prose rails failed where mechanical guards caught every incident. Wants a PreToolUse guard beside the existing `relay-automation/hooks/`. → [#527](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/527)
- **GH-398 · ~35 KB of auto-loaded instruction reaches every turn, recorded nowhere** 🆕 **parked 2026-08-14 by the /10days sweep — needs a capture doc** — a turn's prompt has 7 layers and XYZ authors 4; the named cheap fix is a turn-start probe that records the loaded layers into the run log and warns when the target's `permissions.allow` contradicts the turn prompt. Its analysis half is [#404](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/404). → [#398](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/398)
- **GH-423 · validate and codify 3+ agent swarm support** 🆕 **parked 2026-08-14 by the /10days sweep — needs a capture doc** — README claims "two or more" while `skills/xyz/SKILL.md:57` records the cap as unvalidated above two; six checkable acceptance items exist but closing the contradiction needs real multi-agent runs, not a doc edit. → [#423](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/423)
- **GH-429 · the GH-40 Reviewer was qualified on a single blind run with no committed transcripts** 🆕 **parked 2026-08-14 by the /10days sweep — unblocked by GH-428, needs a capture doc** — a nondeterministic gate needs a measured pass rate re-established per model version. Was blocked on the rotted gamma fixture; that rot is fixed, so this is now actionable. → [#429](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/429)
- **GH-518 · fuzzing loop emits PRs with no `--base development` and skips CI with no local fallback** ⏸️ **parked 2026-08-14 — awaiting an operator decision, deliberately NOT contracted** — `fuzz-agy-plan.sh:78` reproduces it, but the issue lists three option groups ("Ideas for Improvement") rather than a decided scope; auto-drafting a contract here would be guessing which group ships. → [#518](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/518)
- **GH-520 · a fixture that does not stub `CODEX_BIN` tests the reviewer probe, not the code** ⏸️ **parked 2026-08-14 — awaiting an operator decision, deliberately NOT contracted** — third recorded instance of the same trap; `test/_setup.sh` still has zero `CODEX_BIN` references and the issue offers cost-ordered options while self-parking as "Parked. Not built." → [#520](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/520)
- **GH-499 · 0.5.0 Lantern — the information needed to act already exists inside the harness** 🔒 **parked 2026-08-14 — release-order blocked, do not start members** — Lantern's frozen manifest is this epic plus GH-358 Phase 2, and `RELEASES.md:148` records its exit criterion as **NOT BUILT** with writing it required *before* any member is fixed. `test/lantern-release.sh` does not exist. → [#499](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/499)
- **GH-421 · relay-xyz SKILL.md documents a `vendor` subcommand that does not exist** 🆕 **queued 2026-08-13 by /10days sweep** — the documented `xyz-vendor.sh vendor <repo>` form fails; correct it to the real single-positional contract and sweep sibling skill docs. → [GH-421-RELAY-XYZ-VENDOR-DOC.md](PROJECT/2-WORKING/GH-421-RELAY-XYZ-VENDOR-DOC.md) · [#421](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/421)
- **GH-428 · gamma-poison poison.patch no longer applies, and nothing detects fixture rot** 🆕 **queued 2026-08-13 by /10days sweep** — re-derive the patch against current `src/paths.js` and add a non-recursive staleness probe to `validate.sh`. → [GH-428-GAMMA-POISON-FIXTURE-ROT.md](PROJECT/2-WORKING/GH-428-GAMMA-POISON-FIXTURE-ROT.md) · [#428](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/428)
- **GH-430 · improve-loop.sh defaults its state dir to /tmp, so provenance evidence evaporates** 🆕 **queued 2026-08-13 by /10days sweep** — default to a tracked in-repo path per the GH-396 placement constraint and pin it with a registered test. → [GH-430-IMPROVE-LOOP-STATE-DIR.md](PROJECT/2-WORKING/GH-430-IMPROVE-LOOP-STATE-DIR.md) · [#430](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/430)
- **GH-528 · measure and recalibrate the test suite — spike verdict + experimental parallel gate** 🚧 **spike complete 2026-08-13, Phase 1 built on `feat/gh528-parallel-validate`** — the spike measured the full gate (190 shell suites, 950.3s sequential), falsified the sleep-heavy hypothesis, found **zero** redundant suites (Codex+agy consult concurred), and identified parallelism as the one lever: with the 13 real-`relay-drive.sh` suites serialized into one lock lane (GH-42 exclusion preserved), 8-way runs green in ~167s. Phase 1 ships `validate.sh --parallel N` as **explicitly experimental**; sequential stays the default until Phase 2 promotion evidence (multi-width stress runs per the consult bar). Driver-lock scope (`relay_drive.py` locks harness root, not `RELAY_TARGET_ROOT`) parked as a Phase 3 separate issue. → [GH-528-TEST-SUITE-RECALIBRATION.md](PROJECT/2-WORKING/GH-528-TEST-SUITE-RECALIBRATION.md) · [#528](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/528)
- **GH-510 · Agent2Agent watch/drive operating levels** 🚧 **active 2026-08-11 on `feature/agent2agent`** — add byte-preserving 150-second polling and an explicitly authorized, bounded turn-command driver without weakening `send`/`close` ownership enforcement. → [GH-510-AGENT2AGENT-WATCH-DRIVE.md](PROJECT/2-WORKING/GH-510-AGENT2AGENT-WATCH-DRIVE.md) · [#510](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/510)
- **GH-509 · tier CI to stop per-push Actions minute burn** 🚧 **active 2026-08-11 on PR #511** — route PDDA to documentation/full boundaries, keep a sub-three-minute code-only fast gate, and require the complete suite before merge for Tick, relay-containment, frozen-twin, worktree-safety, and CI changes. → [GH-509-CI-MINUTE-BURN.md](PROJECT/3-COMPLETED/GH-509-CI-MINUTE-BURN.md) · [#509](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/509) **CLOSED 2026-08-14 — complete, and RETIRED from the Meter manifest.** The two unchecked criteria are blocked by GH-544 (hosted CI retired for the private phase), not by unfinished work: with `ci.yml` reduced to `workflow_dispatch:` only, push-cannot-cancel is vacuously true and permanently unwitnessable, and the hosted macOS witness cannot be obtained without spending the minutes this issue existed to stop. The residual is owned by GH-544's re-arm trigger.
- **GH-497 · agent2agent compact multi-session rendezvous** ✅ **shipped 2026-08-11 in PR #500** — compact six-digit discussion IDs, stable `agent1`/`agent2`/`agentN` identities, seeded turn 1, and serialized file routing for 2+ live sessions. → [GH-497-AGENT2AGENT.md](PROJECT/2-WORKING/GH-497-AGENT2AGENT.md) · [#497](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/497)
- **GH-480 · XYZ Cockpit — read-only VS Code view for Marathons, Releases, Worktrees** 🆕 **captured 2026-08-09, alpha scaffold built on `feat/gh480-vscode-cockpit-ext` (PR #481, draft)** — standalone extension (Traycer's own Activity Bar view is a closed single webview with no extension point, checked directly), one webview with three collapsible card sections and copy-to-clipboard. Read-only: nothing is executed. Still needs a live F5 visual check before the PR leaves draft. → [GH-480-VSCODE-COCKPIT-EXT.md](PROJECT/1-INBOX/GH-480-VSCODE-COCKPIT-EXT.md) · [#480](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/480)
- **GH-451 · Marathon: support Pi builders on the Python-default path** 🆕 **captured 2026-08-08** — route Pi through the existing dispatcher and preflight `PI_BIN` before any relay/tick mutation; no provider policy or fallback-twin change. → [GH-451-PI-MARATHON-ROUTING.md](PROJECT/1-INBOX/GH-451-PI-MARATHON-ROUTING.md) · [#451](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/451)
- **GH-453 · Design an issue-derived fuzzing evidence pipeline** 🆕 **second-pass design 2026-08-08** — qualify closed issue/fix pairs from a rolling 30-day corpus with a blinded pre-fix/post-fix oracle; run generated artifacts only in credential-free throwaway clones, measure reproduction precision and novel defect-class yield, then require human promotion. → [GH-453-ISSUE-DERIVED-FUZZING.md](PROJECT/2-WORKING/GH-453-ISSUE-DERIVED-FUZZING.md) · [#453](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/453)
- **GH-441 · the pre-advance gate inherits the marathon state it is supposed to judge** ✅ **Phases 1 AND 2 SHIPPED 2026-08-08 — acceptance 1-5 met** — `validate.sh` is marathon-drive's default `--pre-advance-cmd`, so it ran as a child of a live driver and inherited variables that silently flipped suite verdicts (`gh284` 20/0→15/5, `gh331` 8/0→5/3, `oracle-guard` on ambient `ALLOW_PATHS`). Every affected suite passed standalone every time, which is why it halted the Litmus marathon twice and was misdiagnosed as flakiness both times. **Phase 1** (`3ea23fd`) fixed it per-suite — two suites clear the flag for themselves, the idiom `test/driver-lock.sh:11` already used — after a *global* scrub was landed and **reverted** (measured on a clean tree, the one state where the flag is never set). **Phase 2** (`c9a17d7`) made the boundary governed: `utils/py/gate_env.py` classifies all 19 driver exports scrub-or-pass **with a reason**, `relay-automation/gate-env.sh` gives custom gates the same clean environment without copying a prologue, and the contract test fails loudly on an unclassified export (**observed**). `RELAY_DRIVER_LOCKED` stays PASS by measurement, pinned so the revert cannot recur. **The full gate caught three defects in Phase 2 itself** — a driver-killing `import`, an `eval` the security gate rejected, and a duplicate list — all recorded in the doc. cx/risk/eff 2/2/2, 2 phases. → [GH-441-GATE-ENV-CONTRACT.md](PROJECT/2-WORKING/GH-441-GATE-ENV-CONTRACT.md) · [#441](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/441) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419) · [#407](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/407)
- **GH-390 remainder · the gate guard's other kill branch has never been observed firing** 🆕 **captured 2026-08-08 for release 0.2.0 Litmus, OPERATOR GO GIVEN — phase 3 of 3 in [MARATHON-2026-08-08-LITMUS-WAVE-2](PROJECT/2-WORKING/MARATHON-2026-08-08-LITMUS-WAVE-2/MARATHON.yaml)** — the guard itself SHIPPED in PR #393 and is exercised on every gate run (5x observed, 704-806s, exit 0). What did not ship is coverage of its *attribution*: macOS delivers `SIGXCPU` on the soft `RLIMIT_CPU` while Linux checks the **hard** limit first and delivers `SIGKILL`, so a test can only ever observe its own kernel's branch and one half is unreachable on any single machine. **Not hypothetical — that branch already cost a day:** PR #393 failed Linux-only, a first fix mapping another SIGXCPU shape failed identically because `ulimit -t N` sets soft AND hard together, and what produced the answer was a diagnostic commit printing `gate exit -9` — observing the branch, not reasoning about it. Two structural blockers: the runnability pre-check rejects a literal `exec`, and the guard helpers are nested inside `main()` so there is no unit hook. This is #419 applied to the guard, and #407 is the wrong verdict it protects. cx/risk/eff 3/2/3, 2 phases. → [GH-390-GATE-GUARD-COVERAGE.md](PROJECT/2-WORKING/GH-390-GATE-GUARD-COVERAGE.md) · [#390](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/390) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419)
- **GH-409 + GH-408 · a leaked tick claim wedges the next turn, and every layer that could name the cause discards it** 🆕 **captured 2026-08-08 for release 0.2.0 Litmus, combined into ONE lane, awaiting operator go** — a shim claims its token and does not release it when the agent fails, so **two failed turns wedge that agent at its claim cap**. Then: the ownership error suggests a diagnostic that shows a *healthy* token, `rtl.py:74` sends the claim's stdout **and** stderr to `DEVNULL` so the `claim limit reached (holding …)` line naming both culprits is thrown away, `tick claim` prints that failure and **exits 0** so an exit-status check learns nothing either, and marathon-drive reports the result as `pre-advance-failed` on a phase **whose gate never ran** (#407). **Both fired live on 2026-08-07 and cost ~2h**, #409's transcript reproducing character-for-character with `agy` for `claude`. Combined because #408 is *why* #409 costs hours. Two additions the issues do not name: a **second** discard site (`rtl.py:74`, on every turn's path — #408 names only `_run_tick_loud`), and a **second** leak producer (a test suite claiming in the production log; fixed `7785c2a`, control 95→95 events). #432 shipped the persistence half and does **not** cover this. cx/risk/eff 2/2/3, 3 phases. → [GH-409-408-TOKEN-FAILURE-VISIBILITY.md](PROJECT/2-WORKING/GH-409-408-TOKEN-FAILURE-VISIBILITY.md) · [#409](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/409) · [#408](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/408) · [#407](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/407)
- **GH-432 · a failed builder turn takes the one exit that skips `rtl_enforce`** 🆕 **captured 2026-08-06, in progress on `claude/gh432-turn-failure-persist`** — the generic-failure branch calls `sys.exit(5)` two lines before the timeout branch falls THROUGH to `rtl_enforce`, so a crashed turn skips the file-scoped commit, the allowlist containment check, the transcript archive, the GH-67 token handoff, and the drift signal in one step. **Worktree isolation makes the loss precise:** `worktree_end` has already copied the agent's allowlisted edits back into the real tree, so they are sitting there correct and uncommitted when the exit discards the only path that would commit them — the reporter confirms Round 3's lost patch "closely matched the fix I ended up applying by hand." **All five Python shims share the shape**, so the report is reachable via codex, agy, pi, and aider too; fixing only the reported file would leave it live. Largely subsumes **#409** (same defect from the token side); **#408** is adjacent and NOT fixed here. The issue carried no acceptance block — criteria derived from its "Suggested fix direction" per the GH-400 contract, with the deviations declared in the doc. Its second suggestion (a `RELAY_PEER` interaction) was **checked and declined**: unset `RELAY_PEER` only reaches a WARN branch that cannot fail a turn. cx/risk/eff 2/2/2, 2 phases. → [GH-432-TURN-FAILURE-PERSIST.md](PROJECT/3-COMPLETED/GH-432-TURN-FAILURE-PERSIST.md) · [#432](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/432) · [#409](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/409)
- **GH-544 · local-gate-before-push: retire hosted CI for the private phase** 🆕 **operator decision 2026-08-14, captured — not built** — while the repo is private we stop paying for hosted CI and enforce the gate at the push boundary instead: an in-repo `pre-push` hook runs `validate.sh --parallel 8` (~167s, the fast form deliberately, because a 16-minute hook gets `--no-verify`'d rather than run), `ci.yml` loses its `push`/`pull_request` triggers with file and reasoning intact, and `marathon-closeout.sh` learns to tell *no checks configured* from *checks failed*. Coverage is unchanged — #528 already established there is nothing redundant to cut; this moves where the bill lands, not what runs. Knowingly sets aside GH-509's promotion boundary for the private phase and records the debt: no independent attestation, and Linux portability drift accumulates unreported until re-arm. **Re-arm trigger: the repo goes public** (Actions is free and unmetered on public repos, so the entire cost basis expires by construction). → [GH-544-LOCAL-GATE-BEFORE-PUSH.md](PROJECT/2-WORKING/GH-544-LOCAL-GATE-BEFORE-PUSH.md) · [#544](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/544)
- **GH-522 · SmallCode (local Qwen 2.5 32B via LM Studio) as an autonomous marathon Builder — experiment run, verdict recorded** 🆕 **ran 2026-08-12..13, merged 2026-08-14 via PR #529** — adds a `smallcode` builder lane (`relay-automation/smallcode-turn.sh` plus agent routing in `marathon-agent.sh` and `utils/py/marathon_drive.py`) and records what four runs actually showed: the model **can** drive the harness — it passed tokens correctly, took a Codex change-request, and landed a real fix in `test/acorn-extract.sh` — but its inference engine repeatedly **wedges in tool-call loops** (run 3 re-issued a `tick claim` that had already returned `won`; run 4 re-read the same files until the 30-minute turn timeout), and SmallCode's own `quality-monitor` flagged `repeat_call` without aborting. Verdict: **not autonomous without strict repeat bounds**, recorded as a finding rather than a fix. Two defects the experiment introduced were fixed on merge rather than shipped: a hardcoded absolute SmallCode path ([#548](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/548), now `SMALLCODE_BIN` with a loud refusal) and the experiment's own driver script, which wiped `.tick/events/` and force-deleted the driver lock — withheld from the merge with the reasons recorded in the capture doc. → [GH-522-SMALLCODE-FUZZER.md](PROJECT/2-WORKING/GH-522-SMALLCODE-FUZZER.md) · [#522](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/522) · [#523](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/523)
- **GH-555 · Meter 0.6.0 has no exit criterion — build it FIRST, and ship it RED** 🆕 **captured 2026-08-15, admitted to the Meter frozen manifest as entry SEVEN by explicit operator decision** — `test/meter-release.sh` does not exist, so Meter's other six entries are not falsifiable. Neither prior release gate was ever tracked work (`litmus-release.sh` and `nightwatch-release.sh` were both built inside other issues' commits), which is exactly why nobody could point at this one. Two halves per the Litmus/Nightwatch precedent: Half A audits the manifest for EXISTS/REGISTERED/RECORDED-CONTROL and cross-checks `RELEASES.md`; Half B **executes** the six member cases rather than reading declarations about them. **It must be RED on arrival** — a release gate that passes the day it is written has not been shown capable of failing (#419 at the release boundary). Exempt from thematic fit by construction: the exit criterion is what defines the theme. → [GH-555-METER-EXIT-CRITERION.md](PROJECT/2-WORKING/GH-555-METER-EXIT-CRITERION.md) · [#555](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/555)
- **GH-563 · public repository launch — Meter becomes the public RC and the artifact is a sanitized, fresh-history clone** 🆕 **captured 2026-08-15; Meter frozen manifest entry TWO by explicit operator decision** — the published thing is not this repository: it is a clone cut with `git archive` (not a clone + orphan branch, which leaves the whole object database physically present until a gc), committed as ONE initial commit, pushed to a new organisation. `CHANGELOG.md` is carried verbatim as the public record of history; `.tick/`, `relay-system/`, `temp/`, `PARKED/`, `phases/` and `decisions/` do not ship; `PROJECT/` keeps the PDDA scaffold plus this release's own capture docs so the tree reflects the repo's real state. Measured by `test/meter-release.sh --release-gate`: Half A audits the artifact, Half B EXECUTES a credential-free clone completing the documented happy path under a scrubbed environment. → [GH-563-PUBLIC-LAUNCH.md](PROJECT/2-WORKING/GH-563-PUBLIC-LAUNCH.md) · [#563](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/563)
- **GH-564 · a test suite can rewrite the REAL clone's git remote — `git -C ""` and `cd ""` are silent no-ops** 🆕 **reported from a live incident 2026-08-15 by a peer session; `gh544-pre-push-gate.sh` half fixed, 31 files unaudited** — the shared clone's `origin` was found pointing at a suite's throwaway bare repo, so its every push/fetch/ls-remote addressed a fixture. Pushes failed loudly; a **fetch would have succeeded against the wrong repository**, which is the shape that does real damage. Not a missing `-C`: every call already passed `-C "$r"`, but both escapes are documented no-ops on an EMPTY string and these suites run without `set -e`, so one unguarded `r="$(mktemp -d ...)"` redirects every fixture operation onto the caller's clone. Same family as #177 (mktemp resolving to repo root) and #559. Fixed by `require_fixture`, which demands a path exist AND live under `$WORK` — containment, not a null check, so a later edit cannot weaken it to `[ -n "$r" ]` and still pass. 78/0; control 72 pass / 6 fail pre-fix with *"the caller's real clone keeps its origin"* observed FAILING. → [GH-564-FIXTURE-CONTAINMENT.md](PROJECT/2-WORKING/GH-564-FIXTURE-CONTAINMENT.md) · [#564](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/564) · [#177](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/177)
- **GH-557 · an unverifiable acceptance section reads as `ready` — `unknown` must block on a frozen manifest entry** 🆕 **filed and fixed 2026-08-15; deliberately NOT admitted to Meter, which stays frozen at seven** — preflight's fidelity check blocked only on `diverged`, so `unknown` reached `ready (exit 0)`. Observed live on Meter member #382 with `gh` authenticated and the network healthy: six criteria inlined from the capture doc, none on the issue, lane declared ready — GH-400's failure arriving through GH-400's own pass-through case. One status was hiding two situations that need opposite handling: a **transient** outage and a **structural** absence of criteria, which is why the 2026-08-14 DNS outage and the real defect produced identical output and the first was blamed for the second. Now `cause` distinguishes them; only the structural cause blocks, and only on a **frozen manifest member** — an outage stays advisory everywhere, and an ordinary exploratory lane is untouched. Membership is read from each `test/*-release.sh` goalpost's `MANIFEST=(...)` array, not from `RELEASES.md`'s prose, which names retired (#509), moved (#358 Ph2) and sibling (#551's nine) issues that a regex would have blocked. 16/0; control 5 pass / 11 fail pre-fix — the three that PASS pre-fix are the point. → [GH-557-UNKNOWN-BLOCKS-MANIFEST.md](PROJECT/2-WORKING/GH-557-UNKNOWN-BLOCKS-MANIFEST.md) · [#557](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/557) · [#400](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/400)
- **GH-551 · a resolver that cannot determine its answer returns a plausible default instead of refusing** 🆕 **captured 2026-08-15 for Meter 0.6.0; RE-SCOPED 2026-08-14** — adopt one contract (*cannot determine → raise, never default*) and apply it per seam. Trimmed from nine members to ~3 open after a Fable review: #310 is citation semantics, #365 a file missing from `VENDOR_DIRS`, #504 an untested premise — none reduces to a resolver defaulting. The *"+ its Bash twin"* criterion was struck on an operator correction: per `AGENTS.md:131-137` the frozen-twin set is a **closed list of twelve legacy entry points**, so new code carries no twin obligation and a new Bash resolver would be dead on arrival. **Contended** — `rescue/gh344-gh329-path-resolution` already carries a #329 fix and another session is building the enforcement guard. → [GH-551-RESOLVER-REFUSES-INSTEAD-OF-DEFAULTING.md](PROJECT/2-WORKING/GH-551-RESOLVER-REFUSES-INSTEAD-OF-DEFAULTING.md) · [#551](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/551)
- **GH-491 · the gate-only re-fire path exists but is undiscoverable, and `--retry` silently rebuilds** 🆕 **captured 2026-08-15 for Meter 0.6.0** — three codex builds plus three agy reviews spent re-running work the driver already had, because the cheap path exists, nothing points at it, and `--retry` takes the expensive one without saying so. Meter's sentence almost verbatim: a run that re-spends on work it already has did not account for what it spends. → [GH-491-GATE-ONLY-REFIRE-DISCOVERABILITY.md](PROJECT/2-WORKING/GH-491-GATE-ONLY-REFIRE-DISCOVERABILITY.md) · [#491](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/491)
- **GH-549 · the pre-push gate is silently skipped on any branch without `githooks/`** 🆕 **captured + BUILT 2026-08-14, ships inside PR #545** — `core.hooksPath` is repo-scoped, not branch-scoped, so on a checkout with no `githooks/` directory git resolves no hook and **runs nothing, with no warning**. Observed live, not predicted: pushing `chore/ship-litmus-nightwatch` produced no gate output at all. The trap is structural — **the hook is the thing that does not run**, so nothing inside it can detect its own absence. Fix moves the entrypoint out of the working tree: `install.sh` writes a dispatch stub into the clone's `.git/hooks/` (branch-independent, and shared by every linked worktree) which execs the in-tree hook, falls back to `validate.sh` announced on older branches, and **refuses** when neither exists. Cross-model consult (codex + agy) converged on this and both rejected a check in `validate.sh`/`ci-local.sh` — a detector inside the failing component. Their split on stub location was settled by measurement, not argument. Pinned by a **real `git push`** harness against a local bare remote (every prior case invoked the hook directly, which is exactly what this defect was invisible to), plus the negative control that reproduces the pre-fix wiring sailing through ungated. → [GH-549-PREPUSH-BRANCH-INDEPENDENT.md](PROJECT/2-WORKING/GH-549-PREPUSH-BRANCH-INDEPENDENT.md) · [#549](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/549) · [#544](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/544)
- **GH-314 · a pre-existing `phases/`/`relay-system/` ignore rule HALTs a marathon, and `--dry-run` cannot see it** 🆕 **capture written 2026-08-07 (issue open since 2026-07-28)** — `marathon_drive.py` unconditionally `git add`s three files into the target; any ignored one raises `CalledProcessError` and halts the chain. Filed from `LTVera-Pandas` 2026-07-28 with no doc and no ROADMAP entry, so it never became work — then cost a second operator an afternoon in `aegis-sleuth-slack-bot` on 2026-08-07. That run added three things to the issue: a **third** call site, `phases/<lane>/ESCALATION.md` (`marathon_drive.py:956`), which fires *inside* `escalate()` so the crash destroys the record of why the phase halted; serial discovery costing ~1.5h per landmine (un-ignore `RELAY.md` → burn a full phase → crash on `ESCALATION.md`, with the `relay-system/` transcript still queued); and confirmation that **`--target-root` is not an escape hatch** — GH-245/GH-289 correctly reject it for BUILD turns, so a repo that deliberately does not track harness output has *no supported configuration*. On a public target the only workaround publishes builder/reviewer transcripts the repo had explicitly decided to withhold. Operator preference: fail fast in preflight naming all three paths, wired into `--dry-run` too (cf. [#117](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/117)) — explicitly **not** `git add -f`, which would publish silently. Likely the same seam as [#440](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/440) (same `ensure_gitignore`, opposite direction) — worth doing together. Reported via /file-xyz-bug from `aegis-sleuth-slack-bot`. Issue [#314](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/314). -> [PROJECT/1-INBOX/GH-314-VENDOR-GITIGNORE-HALT.md](PROJECT/1-INBOX/GH-314-VENDOR-GITIGNORE-HALT.md)
- **GH-440 · `xyz-vendor.sh` gitignores `.xyz/` but not `/.tick/`, so tick runtime state lands untracked in the consuming repo** 🆕 **captured 2026-08-07** — `ensure_gitignore()` (`relay-automation/xyz-vendor.sh:211-218`) appends only `.xyz/`, so the first driven relay drops `<repo>/.tick/` at the repo root as `?? .tick/`, committable by an unrelated `git add -A`. Deterministic, every time. `.tick/` is explicitly per-device state (`skills/relay-xyz/SKILL.md`), so nothing in it is meaningful when shared. Prior art checked: [#18](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/18) named the same symptom for the `--target-root` cross-repo case and closed **doc-only**, leaving the vendor-time gap in code; [#314](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/314) is open against the *same* function in the opposite direction (never un-ignoring `phases/`/`relay-system/`) and is likely the same seam — worth doing together rather than as a second append path. Low severity, hygiene class, but a public-repo footgun. Filed via /file-xyz-bug from `giant-brains-claude-skills`. Issue [#440](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/440). -> [PROJECT/1-INBOX/GH-440-VENDOR-TICK-GITIGNORE.md](PROJECT/1-INBOX/GH-440-VENDOR-TICK-GITIGNORE.md)
- **GH-439 · GH-11's foreign-repo split has no guard for a linked worktree of the SAME repo** 🆕 **captured 2026-08-07** — with a vendored `.xyz/`, `ROOT` is the host repo, so `--target-root <linked worktree>` silently commits the relay thread to the main checkout's branch while the build lands on the worktree's. Working-as-designed per [#11](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/11); the ask is a warning naming both branches. `marathon.sh` is unaffected. Filed via /file-xyz-bug from `LTVera-Pandas`. Issue [#439](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/439). -> [PROJECT/1-INBOX/GH-439-SAME-REPO-WORKTREE-SPLIT.md](PROJECT/1-INBOX/GH-439-SAME-REPO-WORKTREE-SPLIT.md)
- **GH-435 · XYZ's coordination model is a sequential chain, not a DAG** 🆕 **captured 2026-08-06** — a question about whether XYZ does "graph engineering" turned up a documentation gap, not a defect. The multi-phase model is coherent and its limits look deliberate, but nothing a reader meets says so: `README.md`'s Glossary describes Marathon as chaining phases "in `depends_on` order" and stops, so anyone carrying standard agent-graph vocabulary infers a DAG, parallel stages, and dependency-derived scheduling — none of which exist. Verified against `development`@`80cab6b`: `depends_on` is **scalar-only**, so a join is inexpressible (`MARATHON.example.yaml:42-46`; a list form parses as the literal string and aborts); phases run **strictly one at a time** and a disjoint write-set buys no parallelism (`MARATHON.example.yaml:7-11`, `marathon.sh:168` — one serial `while read` loop); `depends_on` **validates** authored order rather than deriving it, inverting the graph model; failure **halts** with no conditional edge (`marathon.sh:214-226`, nine exit codes → nine halt reasons); and **`Wave` appears in no executor** — only the renderers (`utils/marathon-plan.sh`, `utils/py/_marathon_plan.py`) and reporting (`utils/hq/marathon-scan.sh`). What *does* match is the micro level: nodes with LLM bodies, a genuine LLM-selected edge (`relay_drive.py:278`, reviewer `STATUS:` → terminal or another round), gates that must be able to start before turn 1, and an inspectable state machine. Graph-shaped inside a phase, deliberately not between them — `swarm-preflight.sh:28-29` / GUIDING-PRINCIPLES §8 hand scheduling to the operator. Names the shared root of three open issues: **#354** (parallel stages; its own Phase 0 found the lock excludes marathon↔marathon but silently not marathon↔relay or relay↔relay), **#359** (wave grouping asserted in prose, unverifiable — sharper once the waves never execute), **#391** (the chain is hand-transcribed, so the graph is authored twice and only one copy runs), plus **#396**'s conflict-as-signal restated: disagreement escalates on a *count* rather than routing on substance. Ships the README FAQ; changes nothing in the model; makes "should XYZ execute a DAG?" an explicit decision downstream of #354's Phase 4 gate. cx/risk/eff 2/1/1 (provisional). → [GH-435-COORDINATION-MODEL.md](PROJECT/1-INBOX/GH-435-COORDINATION-MODEL.md) · [#435](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/435)
- **GH-396 · Accuracy Ledger — design constraints to settle before build** 🆕 **captured 2026-08-01** — four constraints recorded before the Ledger exists, from a contributor thread on the Mythos cryptanalysis results whose framing (a model "routing around its constraints") did not survive reading the published run — Claude edited a harness it already had write access to, which is strategy adaptation in-lane, not evasion. What is real: **(1) placement** — the Ledger lives outside every agent-writable path (#50's pillar 2 one level up), and since `rtl_enforce` deliberately skips gitignored files (`relay-turn-lib.sh:1011-1015`), a Ledger under `.tick/` would get *zero* containment — decide tracked-path-vs-close-the-gap up front; **(2) observed vs. declared writes** — `oracle-guard.sh` asserts `ALLOW_PATHS ∩ ORACLE_PATHS = ∅` from CSV lists and never observes what was written, the same declared-trust-vs-actual-execution class as #390, and **PR #393 does not close it** (resource caps only), though `rtl_enforce()` and `requires_test_delta()` are existing reuse candidates; **(3) external ground truth** — our only oracle is the pre-advance gate plus an opt-in `requires_test` that asserts a path merely *changed*, over a gate defaulting to the target's own `validate.sh` (GH-238), i.e. the workpiece — so the Ledger cannot be more trustworthy than its oracle and #390 is necessary but not sufficient; **(4) an untested premise** — per-advisor calibration assumes uncorrelated advisors, but `consult.sh:287` is `(codex agy gemini aider)` where `gemini` is a legacy alias for `AGY_BIN` (a default panel may be one binary twice), `claude` is a builder not an advisor, and `aider` is an OpenRouter harness — cheap divergence replay proposed, but **not** against `.tick/`, whose schema carries no verdict/status/finding field (`src/events.js:12-30`), so it runs on `relay-system/**` transcripts or waits on new emission. Also names one thing buildable now with no Ledger: relay disagreement escalates on a **count** (`relay_drive.py:439,620` → `cap-or-close-mismatch`) rather than on the substance of the dispute. Nothing implemented; the Ledger, reflection pipeline, and semantic-oracle wiring stay future-tense per the #40 post-close review. cx/risk/eff 3/2/3 (provisional). → [GH-396-ACCURACY-LEDGER.md](PROJECT/1-INBOX/GH-396-ACCURACY-LEDGER.md) · [#396](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/396)
- **GH-343 · a target-relative gate program is checked against cwd/PATH instead of `target_root`, so a ready contract reports NOT-READY** ✅ **BUILT 2026-08-08 in the Litmus marathon — agy-approved, full gate passed (715s). Took THREE builds, and the first two failures were the PLAN's fault.** Acceptance criterion 3 ("a gate script **or** program that … is not executable sets NOT-READY, rather than passing readiness and failing at execution time") had a FALSE premise for the interpreter branch: `bash foo.sh` runs a mode-644 file fine. Two independent codex builds implemented it literally and both regressed `test/swarm-preflight.sh` **98/0 → 91/7** (T15/T33/T36). `chmod +x`-ing the fixtures would have shipped a NEW false NOT-READY for `gate: "bash validate.sh"` in any repo whose `validate.sh` is 644 — the lane shipping the bug it exists to fix. Criterion 3 was narrowed on the issue (operator-approved) to **directly-executed** programs only; the third build then produced the correct split — `isfile` alone on the interpreter branch, `isfile` + `X_OK` on the separator-containing program branch — first try. Same builder, same lane; only the criterion changed. **preflight READY, awaiting operator go** — the `bash`/`sh` branch joins the gate script onto `target_root`; the program branch calls `shutil.which()`, which for a separator-containing string tests it against the **process's** cwd. So the identical contract is `ready (exit 0)` from the target repo and `NOT-READY (exit 5)` from the harness clone, with the message blaming PATH. **A false NOT-READY silently drops an issue from a sweep** — `/10days` Step 6 treats any non-zero exit as a reason to drop, and exit 5 is indistinguishable from a real verdict. **Not a GH-308 regression:** the old exemption list never covered a target-relative interpreter, so it failed identically before. Criteria were **authored onto the issue** (it had none) and then **revised after a codex+agy review that found the original satisfiable by making the CORRECT branch wrong** — *"the two branches agree"* is met by resolving both against cwd. cx/risk/eff 2/1/2, 2 phases. → [GH-343-GATE-PROGRAM-TARGET-ROOT.md](PROJECT/3-COMPLETED/GH-343-GATE-PROGRAM-TARGET-ROOT.md) · [#343](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/343) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419)
- **GH-378 · a marathon can only run against a repo whose suite is already green** 🆕 **captured 2026-08-10 for release 0.3.0 Nightwatch, RE-SCOPED 2026-08-11 to release 0.6.0 Meter, doc drafted, NOT yet preflightable — its central design question is open** — `marathon.sh` takes ONE `--pre-advance-cmd` for a whole run, so the global gate is the full suite, and a marathon exists to work on repos whose suites are not green. Measured on rebalance-OS: all 9 lanes' own scoped gates pass, the full suite is red 5/1587, and the failures are unrelated to any lane. It bit this repo twice on 2026-08-10 — both Nightwatch waves halted an already-**Approved** phase on a red that had nothing to do with the lane. **The blocker is sharper than "parsing arbitrary gate output is hard":** `run_pre_advance_gate()` calls `subprocess.Popen(...)` with **no `stdout=`/`stderr=`** (`utils/py/marathon_drive.py:1352-1353`), so the driver retains **only an exit code** — there is no output for any baseline-allowance scheme to parse, and every option is gated behind a capture change first. The doc deliberately does **not** pick a design; it enumerates them and records the choice as the operator's. **Can never be a marathon lane** — it edits the live driver that would be gating its own change. cx/risk/eff TBD. → [GH-378-GATE-REQUIRES-GREEN-SUITE.md](PROJECT/2-WORKING/GH-378-GATE-REQUIRES-GREEN-SUITE.md) · [#378](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/378)

- **GH-414 · `--builder pi` is rejected by the marathon router while the shim sits on disk, working** ✅ **BUILT 2026-08-10 — criteria 4 and 5 shipped as a direct PR; criteria 1-3 were ALREADY SHIPPED before the lane opened** — the builder half landed via **GH-451 / PR #452** (`66d2945f`, 2026-08-09), an issue unrelated in framing, so #414's own evidence table is half-stale: `route_agent` accepts `pi*` and `marathon-agent.sh:65-68` dispatches it. What remains is criteria 4 and 5 — no regression case names Pi in `test/marathon-drive.sh` (0 references), and neither driver documents the now-real Bash/Python divergence. **The gap the issue does not close:** every criterion is about `--builder pi`, but Pi as a **REVIEWER** is blocked independently at `bin/marathon-yaml:95` and `utils/py/marathon_drive.py:1111` — and the reviewer is what we actually need a fallback for, since agy failed twice on 2026-08-10. A latent contradiction found alongside: `:1111` permits `gemini`, but `route_agent` runs first at `:1109` and rejects it, making that branch **unreachable**. **Built:** `test/marathon-drive.sh` case (20) pins Pi routing on the default Python path AND asserts the frozen Bash twin still rejects it — 148 pass / 0 fail, up from 144. Falsifiability proven by mutation: deleting the `pi` branch from `route_agent` makes (20a) fail with exit 2. The divergence note lives in `marathon_drive.py`'s `route_agent`, NOT in the frozen Bash half, which was deliberately left untouched (twin guard 32/0). **Still open and NOT part of #414:** Pi as a REVIEWER is still rejected at `bin/marathon-yaml:95`, so there is still no fallback for a dead agy reviewer. cx/risk/eff 1/1/1. → [GH-414-PI-BUILDER-ROUTER.md](PROJECT/2-WORKING/GH-414-PI-BUILDER-ROUTER.md) · [#414](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/414) · [#451](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/451) · [#492](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/492)

- **GH-392 · the harness publishes no hardware requirement, so a 16 GB host gets no signal before a 7-lane wave** 🆕 **captured 2026-08-10 for release 0.3.0 Nightwatch wave 2, preflight READY** — README's Prerequisites section is four rows (Codex CLI, agy CLI, Node 18+/git, Python 3.8+) and states **no RAM figure at all**, verified against the tree. That matters because the cost is not uniform: a serial `marathon.sh --plan` run holds **~2.2 GB steady** (2.26 GB peak, 138 samples) while a `/10days` 7-lane wave wants **7-14 GB**, uncapped. Scoped to the issue's **part (a), documentation only** — its own text calls the two parts "deliberately separable". **Two criteria were defective in the first draft and an adversarial codex+agy consult caught both:** "Path A"/"Path B" were used as if defined when they are the issue's private vocabulary appearing nowhere in README, and a criterion would have licensed the **false** statement that no memory protection exists — the GH-390 gate guard demonstrably kills an over-budget gate on an RSS cap, observed live. The true distinction is that per-gate containment exists and **host-aware wave sizing** does not. cx/risk/eff 1/1/2, 1 phase. → [GH-392-HARDWARE-SIZING-GUIDANCE.md](PROJECT/2-WORKING/GH-392-HARDWARE-SIZING-GUIDANCE.md) · [#392](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/392) · [#390](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/390) · [#382](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/382)

- **GH-391 · nothing generates `MARATHON.yaml`, so every multi-phase run starts with an undocumented hand-authoring step** 🆕 **captured 2026-08-10 for release 0.3.0 Nightwatch wave 2, preflight READY** — grepping the tree for `MARATHON.yaml` returns **only readers**: the single-lane path is scripted end to end, the multi-phase path begins with hand-authoring that appears in no skill, no generated document and no packet. The author of Nightwatch wave 1 hand-wrote two of them on 2026-08-10, which is the issue reproducing inside the release that contains it. **The consult rewrote this lane, and all three findings were verified before acting:** a criterion asserted `bin/marathon-yaml` requires `brief`/`artifact` when it throws only on missing `id`/`reviewer` (`:91-94`) — so the validator alone accepts a YAML that cannot run, and `marathon.sh --dry-run` is now a second oracle; a criterion claimed emitting `depends_on` everywhere would "remove all parallelism" when **phases are strictly serial** and there is none to remove (the real harm is a fabricated dependency being indistinguishable from a real one); and the original **"edit the Python planner, leave the frozen twin alone" scope was impossible** — `test/marathon-plan.sh` Scenario T enforces cross-lane byte parity, so a Python-only edit goes red inside the lane's own gate. Now a **new standalone emitter** touching no planner file. cx/risk/eff 3/2/3, 1 phase. → [GH-391-EMIT-MARATHON-YAML.md](PROJECT/2-WORKING/GH-391-EMIT-MARATHON-YAML.md) · [#391](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/391) · [#340](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/340) · [#362](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/362)

- **GH-383 · the "pre-advance gate has no timeout" claim is STALE — the guard already bounds it** ✅ **RESOLVED 2026-08-10 — code was already shipped by GH-390/GH-457; the documentation remainder shipped the same day. Ready to close.** — GH-390 landed the wall-clock/CPU/RSS gate guard the issue asks for: `GATE_TIERS` (`utils/py/marathon_drive.py:303-308`, full = 1800s wall / 1200s CPU, fast = 300/240), enforced in the poll loop at `:1365-1372`, killing the process group and returning a dedicated `GATE_GUARD_KILL_EXIT = 108` (`:273`). The issue's own suggested fix #1 — "report a timeout distinctly from a failure" — is the `gate-killed` branch at `:1562-1568`, already there. **Why it was missed is the transferable lesson:** the issue's reproduction is `grep -rn 'GATE_TIMEOUT|gate_timeout'`, which genuinely returns nothing — the feature shipped under `MARATHON_GATE_WALL_S`/`_CPU_S`/`_TIER`, so a **grep-shaped repro proved the wrong proposition**, the same class as an assertion that cannot tell the bug from the fix. All verified against the tree, not inferred. Residual is a **documentation gap only**: `README.md:174-176` documents the RSS cap and never mentions the wall/CPU caps or that `MARATHON_GATE_GUARD=0` removes all timeout protection. Issue carries no acceptance criteria; criteria authored in a separate labelled section. **Shipped:** `README.md` previously named only the RSS cap — it now states wall/CPU/RSS, publishes the `fast`/`full` tier table (300/240 and 1800/1200), documents all five `MARATHON_GATE_*` variables, names exit `108` and the `gate-killed` vs `pre-advance-failed` split, and warns that `MARATHON_GATE_GUARD=0` removes ALL protection and reintroduces exactly this issue. cx/risk/eff 1/1/1. → [GH-383-GATE-TIMEOUT-ALREADY-SHIPPED.md](PROJECT/2-WORKING/GH-383-GATE-TIMEOUT-ALREADY-SHIPPED.md) · [#383](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/383) · [#390](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/390) · [#457](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/457)

- **GH-387 · a builder turn killed at its wall-clock cap is committed and gated as if it completed** ✅ **BUILT 2026-08-11 as a direct PR — and the feared regression turned out not to exist** — a killed turn falls through to `rtl_enforce`, which commits (`relay-automation/relay-turn-lib.sh:1144`) and hands off the token, so `run_pre_advance_gate()` becomes **the first thing that ever executes work no human or reviewer inspected**. The tension that makes this hard, and that the issue never names: **committing a failed turn is GH-432's deliberate, already-shipped fix** — its title is literally "a failed builder turn skips `rtl_enforce` entirely, so its work is never committed and its token is never handed off", filed for a real outage of orphaned tokens and lost work. So "don't commit a killed turn" is not a fix, it is a revert. A second reason the naive fix falls short: `path_has_nonempty_phase_delta` (`utils/py/marathon_drive.py:1439`) accepts a newly-created **untracked** file as evidence of work, and the issue's own crash scenario is exactly that shape — suppressing the commit leaves the artifact behind anyway. The issue's severity is also dated: GH-390's guard shipped ~16h AFTER it was filed, so the described host takedown would very likely be killed today; the **structural** defect is untouched by that. **The fix is one deletion, and the reason it is safe is the finding:** the gate probe DECIDED NOTHING. Reading `recover_timeout_exit()` end to end, every branch is resolved by `artifacts_exist()`, `file_status()` and `token_state()` — the tick token records the builder's handoff directly, so the gate was only ever a proxy for a question the token already answers. Removing it preserves all five outcomes and every GH-205 recovery path. An earlier draft of this entry claimed GH-205 and GH-387 could not both hold; that was wrong and is corrected. What is actually given up is the `timeout-gate-failed` early exit — one wasted reviewer turn on work that was going to fail anyway, a fail-fast optimisation rather than a guarantee. **Verified:** all six GH-205 assertions pass unchanged (`test/marathon.sh` 33/0), GH-432 untouched, `test/gh387-gate-not-first-executor.sh` 9/0 with a gate that LOGS every invocation (the outcome alone cannot distinguish the fix — with a green gate the phase completes either way), and a pre-fix replay restoring the probe fails the pin 7/2. The frozen Bash twin still carries the old probe at `marathon-drive.sh:1208` — documented as a deliberate divergence, not taught the fix, since that needs a `Frozen-twin-exception:` trailer. **Still open, sequenced second:** the untracked-partial leak. cx/risk/eff 4/5/4. → [GH-387-KILLED-TURN-GATED-AS-COMPLETE.md](PROJECT/2-WORKING/GH-387-KILLED-TURN-GATED-AS-COMPLETE.md) · [#387](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/387) · [#432](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/432) · [#390](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/390)

- **GH-402 · a marathon commits to whatever branch the target has checked out, and the `marathon/<slug>` branch is advisory text nothing enforces** 🆕 **captured 2026-08-10 for release 0.3.0 Nightwatch — the issue names one of two failure directions, and the MISSING one reproduced LIVE during this doc's own drafting** — direction A (the issue's): nothing in the ready/verdict computation references branch or dirty state, and `--require-clean` is opt-in (`utils/py/marathon_drive.py:1735`). Direction B (unnamed): a run **leaves** the shared clone parked on a non-trunk branch, so a later unrelated commit silently lands there — `skills/10days/SKILL.md:381-382` cuts `marathon/10days-<today>` and never restores, and `CHANGELOG.md:239` already admits the clone "can be left … parked on a `marathon/*` branch". **On 2026-08-10, while this very doc was being written, a concurrent process moved the shared root from `development` (`d121cac`) to `feature/agent-devtools-fuzzing` (`68ade4d`) mid-session with no signal; the next commit would have landed all 11 Nightwatch capture docs on the fuzzing branch, silently, with every gate green.** Batch 2 was landed from an isolated worktree pinned to `development` instead — a workaround, not a fix. **The issue's proposed fix makes direction B more likely**, since its remediation is to hand-cut a `marathon/*` branch. Root cause is design, not oversight: `PROJECT/3-COMPLETED/GH-69-MARATHON-BRANCH-PROMPT.md:40-41` shows this was built as a human-in-the-loop prompt, an assumption that breaks unattended. Nine of the issue's file:line citations have drifted. Phase 1 touches the running driver — **direct PR only.** cx/risk/eff 3/4/3. → [GH-402-MARATHON-BRANCH-ENFORCEMENT.md](PROJECT/2-WORKING/GH-402-MARATHON-BRANCH-ENFORCEMENT.md) · [#402](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/402) · [#69](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/69)

- **GH-492 · agy hangs headless with no CPU and no progress, and its only pre-flight warning fires on every turn** ✅ **BUILT 2026-08-10/11 — both surfaces done. Captured for release 0.3.0 Nightwatch — operationally urgent: agy is the reviewer half of the cross-model QA pipeline and it failed TWICE on 2026-08-10** — the 900s bound is **wall-clock only** (`utils/py/agy-turn.py:246` `subprocess.run(..., timeout=…)`); `TurnDiagnostics.classify()` runs post-hoc at `:301`, after `TimeoutExpired` already fired at `:247`, so nothing detects a process burning wall clock at zero CPU. The TTY warning is unconditional in headless mode (`utils/py/rtl.py:39-96` returns `"unverifiable"`, and headless always has `stdin=DEVNULL` at `agy-turn.py:22`), so the one available signal cannot distinguish a hang from three healthy runs. **The scope gap neither the issue nor the title names:** `utils/py/consult.py` — where the SECOND failure actually happened — has **zero** `TurnDiagnostics` (`agy-turn.py` has 2 references, `consult.py` has 0) and its own older 300s `CONSULT_TIMEOUT` (`:374`); implementing only in `agy-turn.py` leaves that surface exactly as blind. `consult.py` also lacks the empty-output guard `agy-turn.py:307-313` has — a distinct, unreported silent-success gap. Restored 2026-08-10 by an interactive `agy login`, itself the evidence: the failure was an expired auth session headless mode could not report as such. **This host has no GNU `timeout`/`gtimeout`**, so any fix assuming `timeout(1)` will not run here. **Built:** `TurnDiagnostics.idle_seconds()` measures forward from the last CPU growth or file write; `agy-turn.py` now bounds the turn by BOTH an idle threshold (`RELAY_TURN_IDLE_S`, default 300s, `0` disables) and the wall cap, killing the whole process group. The blocking `subprocess.run(timeout=)` became an explicit poll loop, because a blocking call cannot consult the sampler measuring it. `test/gh492-idle-kill.sh` 9/0 — and the **negative control is the point**: a slow-but-progressing turn measured 0.06s idle against the blocked turn's 4.09s. Proven falsifiable behaviourally, not just by a missing symbol: dropping worktree progress from the idle signal makes the control fail 2/9, which is exactly what a trigger-happy bound looks like. Criterion 3 was met WITHOUT touching the kernel — the every-turn `WARNING` is demoted to a one-line `NOTE` and re-raised in full only on the failure path, where an unverifiable auth probe is a live hypothesis rather than noise. Criterion 4 is satisfied by RECORDING the finding: no reliable headless agy probe exists and none is shipped, per GH-375's measured cost. **consult.py now covered too** — the surface where the SECOND 2026-08-10 failure actually happened. It needed a distinction a turn shim never does: a consult launches every advisor as a SIBLING under one parent inside ONE shared worktree, so measuring the parent sums all advisors and a fast codex answer masks a hung agy. `TurnDiagnostics` gained an explicit `root_pid` and now accepts a FILE as the progress signal, so each advisor is scoped to its own subtree and its own transcript. The test pins the masking BOTH ways — correctly scoped sees 2.99s idle, shared-parent scope sees 0.14s — so it cannot pass on a build where scoping does nothing. `CONSULT_IDLE_S` default 90s, `0` disables. Live consult re-run after the change: 1 answered, 0 failed, no false kill. 16/0. cx/risk/eff 4/4/4. → [GH-492-AGY-IDLE-HANG-DETECTION.md](PROJECT/2-WORKING/GH-492-AGY-IDLE-HANG-DETECTION.md) · [#492](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/492) · [#390](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/390) · [#414](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/414)

- **GH-376 · relay-drive and marathon-drive take different locks from a linked worktree, so their mutual exclusion does not exist** ✅ **SHIPPED 2026-08-11 (direct PR) — the fix was "adopt the resolver that already shipped", not "write one"** — both twins now call GH-448's shared resolver; `test/gh376-relay-drive-lock-parity.sh` 18/0 against a real `git worktree add`, with the pre-fix resolution replayed on BOTH lanes and observed sailing past a held lock, plus normal-clone and vendored controls and source guards pinning that the resolver is called rather than re-inlined. **Confirmed live, not only in fixture:** a marathon in a sibling clone (pid 39588) held the lock in this repo's common `.git/`, and post-fix `poll-relay` + `relay-escalation-not-stall` correctly refuse from a linked worktree (both 12/0 and 5/0 in a standalone clone) — the exact collision the issue describes, occurring by accident during its own fix. Consequence now documented: the suite can no longer run from a linked worktree while a driver holds the main clone's lock, which pre-fix it could *because* the worktree got its own private lock. Original capture below. — GH-448 (PR #449) shipped a proven 3-branch resolver, `driver_lock_path` (`utils/py/rtl.py:477`), plus a Bash twin; `utils/py/marathon_drive.py` imports and uses it (`:20`, `:611`) and **`utils/py/relay_drive.py` does not** — it still hand-rolls a 2-branch version at `:385-391` keyed on `os.path.isdir(root/.git)`, which is **false in a linked worktree** (there `.git` is a file), so the two drivers resolve different paths and neither excludes the other. GH-448's own doc explicitly scoped this out as "sibling issue #376". Also found: `rtl.py`'s docstring claims to match relay_drive's resolution too — currently false, a second stale comment in the same area. Traced why it only bites standalone: `marathon_drive.py:649` sets `RELAY_DRIVER_LOCKED=1` before invoking relay-drive, making it skip its own buggy acquisition — so the real collision is two independently-launched top-level drivers, not marathon's internal chaining. `relay-drive` is the per-turn subprocess the driver re-execs every turn, so the write-set is self-modifying in substance — **direct PR only.** Frozen-twin pair #8; Bash edits need a `Frozen-twin-exception:` trailer. cx/risk/eff 2/3/2. → [GH-376-RELAY-DRIVE-LOCK-PATH-DIVERGENCE.md](PROJECT/2-WORKING/GH-376-RELAY-DRIVE-LOCK-PATH-DIVERGENCE.md) · [#376](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/376) · [#448](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/448)

- **GH-386 · `claude-turn` caps at 600s while every other builder defaults to 900s, and the computed `RELAY_TURN_TIMEOUT_S` is never wired through** 🆕 **captured 2026-08-10 for release 0.3.0 Nightwatch — both halves still reproduce, but the issue mis-states the second one in a way that would have sent the fix into an unfireable file** — (a) confirmed: `utils/py/claude-turn.py:97` defaults **600**, while `agy-turn.py:205`, `codex-turn.py:73` and `pi-turn.py:105` all default **900**; no rationale comment at either claude twin. (b) the issue says "marathon.sh does not read the packet's suggestion" — **false as stated**: `relay-automation/marathon.sh:236-238` DOES export `RELAY_TURN_TIMEOUT_S` when a phase sets `turn_timeout_s:`, and `bin/marathon-yaml` carries the field end to end (both wave-2 phases set `900`). The real gap is only the last hop: **nothing auto-populates that field from swarm-preflight's computed number** (`utils/py/swarm_preflight.py:1535` prints it to `packet.md` and stops), so a plan author hand-transcribes it. That correction matters operationally — taken at face value the fix lands in `marathon.sh`/`marathon_drive.py` and is **unfireable by the self-modification rule**; steered into `marathon-plan` instead, it stays a legal marathon lane. A 2026-07-31 issue comment establishes the 600 value's lineage via GH-320 — deliberate per-file, just undocumented cross-shim. Line citations drifted up to 652 lines. No acceptance criteria on the issue; authored separately. cx/risk/eff 2/2/2. → [GH-386-CLAUDE-TURN-TIMEOUT-ASYMMETRY.md](PROJECT/2-WORKING/GH-386-CLAUDE-TURN-TIMEOUT-ASYMMETRY.md) · [#386](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/386) · [#387](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/387) · [#320](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/320)

- **GH-379 · a budget-exhausted claude builder is escalated as `pre-advance-failed` and its own error text is discarded** 🆕 **captured 2026-08-10 for release 0.3.0 Nightwatch, RE-SCOPED 2026-08-11 to release 0.6.0 Meter — the headline already shipped in GH-407; only a propagation step remains** — the title-level complaint no longer reproduces: `utils/py/marathon_drive.py:2058` now escalates `relay-failed-before-gate` when the gate never ran, distinct from `pre-advance-failed` when it ran and failed, and `test/gh407-gate-ran-attribution.sh` pins it with a **pre-fix replay** inside the fixture. The "error text is discarded" half is stale for the path that actually runs: `utils/py/claude-turn.py:72` persists via `rtl_default_log()` (commit `7812710`, 2026-07-31 — one day AFTER this issue was filed, in direct response to the same panic run). The quoted `$TMPDIR/claude-turn-<pid>.json` is real only on the **frozen Bash twin** (`relay-automation/claude-turn.sh:159`). What genuinely remains: nothing copies `subtype`/`terminal_reason` forward into `ESCALATION.md`. Deliberately **not merged** with #408/#409 — #408 is *active suppression* (`stderr=DEVNULL`), this is a *missing propagation* of data already persisted; cousins pointing at the same absent reason-channel, not one bug. Bonus defect found: `claude-turn.sh:46` documents defaults of `20` turns / `2.00` budget while `:175-176` sets `12` / `0.50` — its own header contradicts its own code, twice. Driver touch — **direct PR or supervised relay, not an automated lane.** cx/risk/eff 2/2/2. → [GH-379-CLAUDE-BUILDER-DIAGNOSIS-SURFACING.md](PROJECT/2-WORKING/GH-379-CLAUDE-BUILDER-DIAGNOSIS-SURFACING.md) · [#379](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/379) · [#407](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/407) · [#408](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/408)

- **GH-380 · a claude builder silently ignores the target repo's permissions unless the directory was pre-trusted** 🆕 **captured 2026-08-10 for release 0.3.0 Nightwatch, RE-SCOPED 2026-08-11 to release 0.6.0 Meter — the issue describes the DEAD half of a frozen twin pair** — its evidence table says the warning lands in `$TMPDIR/claude-turn-<pid>.json` and is "never copied into the phase directory". True of `relay-automation/claude-turn.sh:159`, the **frozen Bash** shim; **false of the path that actually runs** — `utils/py/claude-turn.py:72` → `rtl_default_log()` (`utils/py/rtl.py:307-324`) already writes to a persistent in-repo `relay-system/logs/<date>/…` path as of `7812710`, confirmed an ancestor of HEAD. So the issue's suggested fix #4 ("preserve the turn log") is **already shipped** and is scoped out. The core defect stands untouched: nothing surfaces the trust *warning line itself* anywhere operator-visible, so a builder degrades to default permissions silently. Verified orthogonal to the separate "claude not headless" gap — `marathon_drive.py:238-260`'s binary probe (GH-117) fail-fasts before any tick mutation but is PATH-only, never trust-aware. Write-set is the Python half only — **no `Frozen-twin-exception:` trailer needed, and this one CAN run as a marathon lane.** Issue has no acceptance criteria; five authored separately. cx/risk/eff 2/2/2. → [GH-380-CLAUDE-BUILDER-TRUST-SILENT-DEGRADE.md](PROJECT/2-WORKING/GH-380-CLAUDE-BUILDER-TRUST-SILENT-DEGRADE.md) · [#380](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/380)

- **GH-382 · a marathon reports tokens and wall-clock but no memory — an unattended run ended in a kernel panic with no signal in the telemetry** 🆕 **captured 2026-08-10 for release 0.3.0 Nightwatch, RE-SCOPED 2026-08-11 to release 0.6.0 Meter — the issue is accurate; a SIBLING DOC is what's wrong** — `src/analyze.js:550-566` / `computeCost()` at `:363-385` carry zero references to memory, rss, swap, compressor or `vm_stat`, exactly as claimed. But `PROJECT/2-WORKING/GH-390-GATE-GUARD-COVERAGE.md:99` asserts a host-pressure floor "shipped in PR #393", and it did not — contradicted by `utils/py/marathon_drive.py:1320` ("Layer 4 (host free-memory floor) … are Phase 2") and by the shipping commit's own title (`94cafc9`, "Phase 1 — layers 1-3"). Flagged so nobody builds on the sibling doc's claim. A trap a plausible-but-wrong fix would walk into: the gate ALREADY computes a peak-RSS number and then discards it, log-only (`marathon_drive.py:1397-1403`). Pairs with GH-392, which publishes the **static** sizing guidance measured from this very crash; #382 is the **runtime** counterpart and neither substitutes for the other. Write-set almost certainly includes the running driver plus `relay_drive.py` — **direct PR only.** cx/risk/eff 3/3/3. → [GH-382-MARATHON-MEMORY-TELEMETRY.md](PROJECT/2-WORKING/GH-382-MARATHON-MEMORY-TELEMETRY.md) · [#382](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/382) · [#392](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/392) · [#390](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/390)

- **GH-384 · no recovery path after an interrupted marathon — a crash leaves a clean tree containing ungated commits, and nothing reports it** 🆕 **captured 2026-08-10 for release 0.3.0 Nightwatch — scoped deliberately so it CAN be a marathon lane** — the mechanism the issue asserts but never explains: the turn's commit lands at `relay-turn-lib.sh:1144`, `run_pre_advance_gate()` runs later at `marathon_drive.py:1557`, and `phase.approved` is logged only after the gate passes at `:1580` — so an interruption in that window is structurally an ungated commit. Two issue claims corrected: the `phases/<plan>--p*/` residue row is stale (**GH-484 flipped the default phase-output dir to `marathon-system/`** the same day — `marathon_drive.py:697-700`, `marathon.sh:174-178`; the old path survives only as a fallback in the two monitors), and "no tooling reports phase state" is an overstatement — `marathon-ls.sh` and `marathon-detail.sh` already report driver-lock LIVE/STALE/IDLE and `STATUS:`/`NEXT:`. The genuinely missing thing is narrower and worth stating exactly: **no tool cross-references "phase Open + a commit exists + no `phase.approved` ever landed".** The issue's own suggestion 1 (`marathon --status/--recover`) would edit the running driver and be unfireable, so acceptance is scoped to a **new standalone script** instead — which keeps it a legal lane. Depends on #388 for a durable record to recover FROM. No acceptance criteria on the issue; authored separately. cx/risk/eff 3/2/3. → [GH-384-MARATHON-CRASH-RECOVERY.md](PROJECT/2-WORKING/GH-384-MARATHON-CRASH-RECOVERY.md) · [#384](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/384) · [#388](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/388) · [#387](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/387)

- **GH-467 · a builder is told "Do NOT run git", so a lane whose deliverable is an index change cannot perform its own work** 🆕 **captured 2026-08-10 for release 0.3.0 Nightwatch — the ban is PROTECTIVE, so the fix is not "remove it"** — the packet text is verbatim at `relay-automation/marathon-drive.sh:1017,1023` and `utils/py/marathon_drive.py:1757,1772`, and the rationale is real and documented (`relay-turn-lib.sh:1026-1053`, `PROJECT/3-COMPLETED/RELAY-CONTAINMENT-HARDENING.md:31`): the harness performs the commit itself, and a builder committing mid-turn has previously reset HEAD and orphaned a peer agent's commit. The issue deliberately declines to choose among three shapes ("Not choosing here"), so criteria were authored for **option 3 only** (declare the intent, let preflight refuse) — chosen because options 1 and 2 touch the driver and the kernel respectively and could never be marathon lanes, while option 3's write-set is `utils/py/swarm_preflight.py` alone and **can** be. Key fact the issue omits: `lanes.orchestrator_only` already exists (`swarm_preflight.py:199-234`) but is **advisory-only — nothing outside that file reads it**, so "preflight refuses to dispatch" is new behaviour, not existing. Also: no test asserts the ban string's presence, so a fix should add a regression guard against silently weakening it. The #466 workaround is confirmed in `git log` (`81b3127` untracked `phases/p1/RELAY.md` by hand). cx/risk/eff 3/3/3. → [GH-467-INDEX-ONLY-LANE-GIT-BAN.md](PROJECT/2-WORKING/GH-467-INDEX-ONLY-LANE-GIT-BAN.md) · [#467](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/467) · [#466](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/466)

- **GH-358 · the 16-way concurrent-append lock assertion flakes on the shared CI runner** 🆕 **captured 2026-08-06 for release 0.2.0 Litmus, preflight READY, awaiting operator go** — a flaky **lock** test is the one kind that cannot be waved off: *"flaky"* and *"the lock genuinely loses a write under contention"* produce an identical symptom, so neither verdict is currently evidence. The review added two findings verified against the tree: **every appender's exit status is discarded** (`wait "$p" 2>/dev/null || true`, in two places), so a crashed appender is indistinguishable from a lost record; and **two different lock bounds are in play** — the test's own wait and the writer's `XYZ_LOCK_WAIT_S` default — so a report naming "the timeout" is not actionable. Instrument first, decide after; **`M` stays 16 and the distinctness check stays**, both of which only make the symptom disappear. cx/risk/eff 2/2/2, 2 phases. → [GH-358-LOCK-FLAKE-INSTRUMENTATION.md](PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md) · [#358](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/358) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419)
- **GH-375 · the agy auth pre-flight passes on exit status alone, so it cannot fail in the headless context it exists for** 🆕 **captured 2026-08-06 for release 0.2.0 Litmus, preflight READY, awaiting operator go** — the sharpest instance of the #419 class in the tree. `check=True` raises only on non-zero; `agy whoami` **exits 0 while printing a TTY error**; stdin is `DEVNULL` so the error path is the *normal* path under automation; and the captured output — the only place the failure is visible — is **deleted on the success branch**. The timeout safety net names the right failure mode but depends on a hang that only happens when a TTY exists, so **attended runs are protected and unattended runs are not** — inverted from the intent. Preflight's `agy=present` is a PATH check; both signals read green with no credentials. Criteria revised after codex found *"a positive assertion on an expected identity field"* specified neither the field nor a valid response. `agy_safe` is deliberately empty. cx/risk/eff 2/1/2, 2 phases. → [GH-375-AGY-AUTH-PROBE.md](PROJECT/2-WORKING/GH-375-AGY-AUTH-PROBE.md) · [#375](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/375) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419)
- **GH-388 · `marathon.sh` persists no run log, and per-phase transcripts are written only on completion** 🆕 **captured 2026-08-06 for release 0.2.0 Litmus, preflight READY, awaiting operator go** — **the failure mode guarantees the absence of the record**: phases 1–4 completed and each has a transcript; phase 5 killed the host and has none, because the transcript is written at phase end. The chain narrative lived only on the terminal, redirected to a path the platform clears at boot, and the panic reboot destroyed it. A related live path: `rtl_default_log` falls back to volatile storage **with the diagnostic suppressed**. **Two review corrections, both mine:** a criterion rested on the false premise that the PDDA lint classifies runtime log destinations (it scans *documentation*), and *"writes a partial transcript"* was satisfiable by an empty pre-created file; agy separately found *"no longer silent"* satisfiable by a print statement while still writing to storage a reboot erases. cx/risk/eff 2/2/3, 2 phases. → [GH-388-MARATHON-RUN-LOG-DURABILITY.md](PROJECT/2-WORKING/GH-388-MARATHON-RUN-LOG-DURABILITY.md) · [#388](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/388) · [#382](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/382) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419)
- **GH-401 · `marathon-drive --dry-run` writes to the harness's own tracked `phases/p1/RELAY.md`** 🆕 **captured 2026-08-06 for release 0.2.0 Litmus, preflight READY, OPERATOR GO GIVEN 2026-08-08 — phase 2 of 3 in [MARATHON-2026-08-08-LITMUS-WAVE-2](PROJECT/2-WORKING/MARATHON-2026-08-08-LITMUS-WAVE-2/MARATHON.yaml)** — a dry run mutates the working tree, and the diff is **machine-dependent** (it rewrites embedded absolute paths), so it churns for everyone who runs the suite and reverts for whoever last committed it. **Observed live three times during the 2026-08-05/06 sessions**, each needing a hand revert before unrelated work could be committed, and once nearly swept into a commit. The existing guard `marathon-root-audit.sh` reads as covering this and does not — its scope is **two hardcoded filenames**, so the offending test is out of reach because of its *name*, not because it is safe. **A review correction:** the first criterion, *"writes nothing into any git repository"*, would have broken a legitimate existing test that renders into a caller-supplied fixture root; it now says *outside the root it was given*. cx/risk/eff 2/2/2, 2 phases. → [GH-401-DRY-RUN-MUTATES-REPO.md](PROJECT/2-WORKING/GH-401-DRY-RUN-MUTATES-REPO.md) · [#401](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/401) · [#209](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/209) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419)
- **GH-418 · swarm-preflight can pass a lane whose issue is closed and whose artifacts are frozen — it never checks either** ✅ **BUILT 2026-08-08 in the Litmus marathon — agy-approved, full gate passed (704s), and it grew a third phase from its own review.** Phases 1-2 add the issue-state and GH-308 FROZEN-banner checks preflight never had (`test/gh418-issue-state-frozen.sh`, 143 lines). **Phase 3 was operator-approved mid-run after agy found a PRE-EXISTING crash while reviewing Phase 1-2:** `expand_effective_artifacts`'s `read()` helper (`swarm_preflight.py:366`) did `open(..., "r")` + `except OSError:` only while walking all of `test/`, so ONE binary file there was an uncaught `UnicodeDecodeError` that killed preflight outright — reproduced with a single probe. The tell was the asymmetry: codex's own new `find_frozen_artifacts` already used `encoding="utf-8"` + `except (OSError, UnicodeError)`. Now hardened and pinned by a binary fixture asserting both exit 0 **and** the absence of `UnicodeDecodeError`, since an exit-code check alone would pass if the error were merely swallowed. **preflight READY, awaiting operator go** — the **designated first child of #419**. Preflight validates a contract's *internal consistency* (artifacts exist, probes still detect the bug, base is fresh) and never asks the two questions that decide whether the work should run: is the issue still open, and are the targets writable by policy. So a lane can read READY, emit a packet, and send a builder to edit a frozen Bash twin to close an issue that shipped two weeks ago. Measured on the 2026-08-03 four-plan triage: Plan J both lanes CLOSED, Plan K **16 of 17** CLOSED, 2026-07-23's #279 CLOSED, and Plan M targeting `relay-automation/consult.sh` — **FROZEN**, so following that plan's own gate would violate GH-308. None of it discoverable from preflight; it was re-derived by hand twice, weeks apart. Cheap now because #400 already added the `gh issue view` call — `state` is **one more field on a request that already happens**, and #400's `unknown`-never-blocks posture covers the offline case unchanged. **Collides with #368 by construction:** its frozen check would refuse that lane, whose only write target carries the banner — fire #368 first (recorded identically in both docs). cx/risk/eff 2/2/2, 2 phases. → [GH-418-PREFLIGHT-ISSUE-STATE-FROZEN.md](PROJECT/3-COMPLETED/GH-418-PREFLIGHT-ISSUE-STATE-FROZEN.md) · [#418](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/418) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419)
- **GH-417 · the tree asserts both that `rev-parse --show-toplevel` is the correct turn-ROOT default and that it is the bug "caught live"** ✅ **BUILT 2026-08-08 — `test/gh417-turn-root-symlink-prefix.sh` 13/0, the last unbuilt entry in the frozen Litmus manifest.** Filed as an **unreconciled contradiction with no regression coverage**, deliberately not as "it is broken now" — and that framing was right. `utils/py/rtl.py:resolve_turn_root` uses the construct by design (GH-296: a shim invoked from inside a same-repo vendored `.xyz/` must root at the true target repo), while `relay-turn-lib.sh` said that exact construct was wrong and was *"caught live."* **What actually resolved it: `312a2c3` (2026-07-21, GH-261)**, whose own commit message names the `test/marathon-drive.sh` GH-171/GH-172 failures — the ones Marathon Plan K measured on **2026-07-19** and explained by blaming `--show-toplevel`. Plan K was two days early. GH-261 canonicalizes **both** `RTL_ROOT` and each absolute allowlist entry to physical form before stripping, so either symlink form resolves; the GH-160 collapse runs *before* that and must not change ROOT's form, which is the whole of what its warning was ever about. The warning is **kept and scoped**, not deleted — it is still true of the collapse. **The control is what makes the test evidence:** reverting GH-261 in a fixture copy brings exit 6 straight back with the original symptom in words, and the *same reverted tree* passes when ROOT is pinned to the logical form — which is what identifies ROOT's symlink form as the axis rather than the fixture. The fixture builds its **own** symlink instead of trusting `$TMPDIR` (whose shape differs across macOS, Linux CI and a sandbox), and the **Python lane is proven** by a `python3` wrapper on `PATH` rather than assumed. Comments only in both files; the five GH-308-frozen Bash shims untouched. → [GH-417-TURN-ROOT-RESOLUTION.md](PROJECT/2-WORKING/GH-417-TURN-ROOT-RESOLUTION.md) · [#417](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/417) · [#426](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/426)
- **GH-426 · worktree isolation leaks an off-lane creation into the harness repo — the turn correctly exits 6 and the file is still there** 🆕 **captured 2026-08-05 for release 0.2.0 Litmus, preflight READY, awaiting operator go** — under `RELAY_WORKTREE_ISOLATION=1` a file *created* inside the throwaway worktree also lands in the real harness repo. Isolation exists precisely to stop creations and renames reaching the real tree, where the allowlist's tracked-file revert cannot help. Three facts confirmed in **one run**: the stub's CWD really is the worktree (`rtl-wt.3FV3IO`), the shim really exits 6, and `offlane.md` is in the harness root anyway — while the declared target (`AGY_TURN_ROOT`) stays clean. **The exit code is reassuring and wrong**, and the defect is invisible to the obvious test: GH-410's regression case asserted absence in the target repo and passed, because that is where the file *wasn't*. Found while writing GH-410's counter-pin and filed separately rather than absorbed; predates it and reproduces independently. Plausibly one root with **#417** — the Python shim and Bash lib disagreeing about which repo is the target — so **never run the two as concurrent lanes**. Phase 1 ships a **red test only**: a lane whose subject is a test that passed for the wrong reason must not write fix and test together. cx/risk/eff 3/3/3, 2 phases. → [GH-426-WORKTREE-LEAK.md](PROJECT/2-WORKING/GH-426-WORKTREE-LEAK.md) · [#426](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/426) · [#410](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/410)
- **GH-425 · `check_source_url` compares the issue number and ignores the repo slug** 🆕 **captured 2026-08-05 for release 0.2.0 Litmus, preflight READY, awaiting operator go — design call SETTLED 2026-08-05: option 1** — the gate extracts `owner/repo`, stores it, and never looks at it, producing a false positive and a false negative at once: legitimate cross-repo provenance is **refused**, and `source: .../SomeoneElse/unrelated-repo/issues/94` against `gh_issue: 94` reads **`ok` → READY**. The false negative is the worse half — the packet then tells the builder its acceptance was *"Verified against issue #94"* while pointing at someone else's #94: the #419 class **inside the gate built to enforce provenance**. Surfaced by dogfooding #422's backfill against `LTVera-Pandas`, whose GH-94 doc legitimately cites another repo's issue #2 and is not a typo. The issue offered three options and said *"this needs a call"*; the operator settled it on 2026-08-05 as **option 1** — `source:` always cites the TRACKING issue, cross-repo origins live in `related:`, options 2 and 3 rejected. The one measured refusal (`LTVera-Pandas` GH-94, citing a connector repo's issue #2) is fixed by moving that reference to `related:`; nothing is deleted, and the doc is in another repo so this lane only reports it. **Preflight reports this lane READY**, which is itself worth noting: it has no way to express "blocked on a human decision" (cf. #412). cx/risk/eff 2/2/2, 2 phases. → [GH-425-SOURCE-URL-SLUG.md](PROJECT/2-WORKING/GH-425-SOURCE-URL-SLUG.md) · [#425](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/425) · [#422](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/422)
- **GH-368 · `marathon-plan.sh` documents `--check` as a `validate.sh` drift guard, but `validate.sh` never runs it** 🆕 **captured 2026-08-05 for release 0.2.0 Litmus, preflight READY, awaiting operator go — FIRE THIS BEFORE #418** — re-verified live 2026-08-05: the claim is still at `utils/marathon-plan.sh:67` and `validate.sh` invokes it **zero** times; `utils/py/marathon_plan.py` does not carry the claim, so the false statement exists in exactly one place. The smallest, cleanest instance of the #419 class in the tree — a documented guard that reads as active while nothing runs it, same family as #315/#319/#348. **Scoped to the issue's Option B** (delete the claim); Option A (wire it up) is separable and carries a real false-positive question — `--check` fails whenever today's plan doc has not been re-rendered, and *"a suite people learn to ignore protects nothing"* — so it stays open on #368 with #336's sidecar interaction as its first question. Three "If A" criteria dropped individually through #400's deviations mechanism, **which caught the first attempt**: declaring a deviation against a still-verbatim list was rejected as vacuous (the C8b hole closed during #399/#400, working). **Its only write target carries the GH-308 FROZEN banner**, which is the whole #418 collision — a comment correction is not a behaviour change, but #418's criterion 3 does not distinguish the two, and it should not be weakened to accommodate this. cx/risk/eff 1/1/1, 1 phase. → [GH-368-MARATHON-PLAN-CHECK-CLAIM.md](PROJECT/3-COMPLETED/GH-368-MARATHON-PLAN-CHECK-CLAIM.md) · [#368](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/368) · [#418](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/418)
- **GH-410 · the worktree containment check greps the reviewer's prose for the repo path, turns on wording, and throws away a completed review** 🆕 **built 2026-08-05, awaiting review** — the containment *verdict* was `if root in line` over the agent's transcript (`agy-turn.py:223`), so it answered "did the model mention a path", not "did it access one". The two diverge both ways: an agent that quietly touched the real tree without naming it was never caught, and one that cited a path in a finding was failed for it. Reporter's quantified case, same run and same builder: the phase with **10** repo-root mentions was Approved, the one with **9** failed three times consecutively. Worse, **the harness supplies the string it punishes** — the retry preamble renders absolute paths into `RELAY.md` (`marathon_drive.py:403-407`, plus *"Use this exact tick binary … {tick_cli}"*), and it renders **only on a retry**, so failing once hands the next attempt more copies of the trigger. Four exemption shapes had already accreted (`[trace] `, `TICK_REPO_ROOT=`, `file://`, `](`) across two prior patches — a deny-list that does not converge. **Correction to the report's third item:** the shims do *not* disagree about containment — `rtl.worktree_end()`'s filesystem diff is called and enforced by **all five** (agy, codex, claude, aider, pi), each exiting 6. What agy alone carried was an *extra, unsound* layer, so uniformity is reached by removing it, not by copying it to four more shims; choosing a builder never picked a safety model, only an exposure to false positives. **Resolution:** writes are observable and stay the verdict; reads are not observable here (openat tracing is not portable under macOS SIP), so the honest answer is to stop asserting an unobservable property rather than keep asserting it badly. The prose scan is now an advisory recorded on the transcript and stderr, and **never fails a turn or discards a verdict** — a heuristic that destroys completed work must fail toward keeping it. Retry preamble now names `DEBUG-MANTRA.md`/`ESCALATION.md` with the directory given once; the tick line keeps its absolute path because "run it from any directory" requires it. Python only — all five Bash twins are frozen (GH-308). Suite **11/0** with two controls: pre-fix replay **7/4**, containment-deleted mutation **9/2** — and the mutation run caught a weakness in the counter-pin itself, which had been satisfied by a comment. cx/risk/eff 3/3/3. → [GH-410-CONTAINMENT-PROSE-SCAN.md](PROJECT/3-COMPLETED/GH-410-CONTAINMENT-PROSE-SCAN.md) · [#410](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/410)
- **GH-422 · the source-URL gate's blast radius was measured on the harness only, and its remediation was a placeholder** 🆕 **built 2026-08-04, awaiting review** — PR #420's gate is right and unchanged; two things around it were not. Its posture came from a sample of **this repo alone** (1 of 48 docs) while the vendoring repos carried far more — the very miss #419 exists to catch — and the message it printed told operators to set `source: https://github.com/<owner>/<repo>/issues/N`, a value `repo_slug_for()` already derives from the target's `origin` in the same file. To be precise about what the gate does: it exits 5 with NOT-READY and writes no packet; **no file is altered, nothing is removed, no git state moves** — a refusal to start a lane, undone by one frontmatter line, sharing nothing with GH-312's destructive class. Now the message resolves the real slug, and `utils/py/backfill_source_url.py` remediates a whole repo in one command, deriving URLs from the **target's** origin so a vendored install cites its own project. Conservative by design: dry-run unless `--apply`; frontmatter-only with the body asserted byte-identical; and a `source:` citing a *different* issue than `gh_issue` is **never** rewritten but reported with a non-zero exit, because the incorrect field may be `gh_issue` and guessing would launder bad provenance into provenance that looks verified. **A live-consumer dry-run caught a real defect before merge:** `cactus` reported 0 to change against a measured 4, since its docs use `issue:` not `gh_issue:` — the gate blocks them via the `GH-9-*.md` glob, the tool read only frontmatter and skipped exactly those, reporting success over a still-blocked repo. Same two-extractors-disagree family as #413, one day later; the tool now uses the gate's own rule and C5b/C5c assert the gate **agrees** the doc passes afterwards. Fleet exposure also corrected upward to **34 docs, not 18** (the first blast script's glob was non-recursive). Dry-run: rebalance-OS 16, LTVera-Pandas 14 + 1 conflict for a human, cactus 4, three repos clean. Suite **20/0** with both #419 control forms — pre-fix replay 15/3, conflict-guard mutation 16/2. cx/risk/eff 2/2/2. → [GH-422-SOURCE-URL-REMEDIATION.md](PROJECT/3-COMPLETED/GH-422-SOURCE-URL-REMEDIATION.md) · [#422](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/422)
- **GH-419 · trustworthy gates: a check that has never been observed failing is not evidence** ⚙️ **Phases 1-2 BUILT 2026-08-08 in the Litmus marathon — agy-approved, full gate passed (739s). Phase 3 is #418, built in the same run.** `GUIDING-PRINCIPLES.md` + `utils/py/gate_inventory.py` + `test/gh419-gate-inventory.sh` (169 + 75 lines) land the principle and a machine-readable per-gate inventory recording whether a negative control has been OBSERVED and in what form. Not closed: it is an umbrella, and its remaining children are still open.** — umbrella for one recurring defect class: *a gate reported green while structurally incapable of reporting anything else*. **Eight documented instances**, five of them already worked (#348 compared Python to Python; #351 regenerated the artifact it validated; #342 never ran on the default lane; #362 rejected a trailer permanently in history; #369 spun forever and blamed the wrong flag) and three surfaced in a **single afternoon** of read-only triage on 2026-08-03 (#400 nothing compared the capture doc to its issue; #417 no test can distinguish the two candidate turn-ROOT behaviours; #418 preflight never checks issue state or the GH-308 FROZEN banner). Every one passed review; every one was caught by a human reading the check and its subject side by side, weeks later. The principle is enforceable because the repo already applies it ad hoc — #400's suite was observed at 1 pass / 19 fail against pre-fix code, GH-400 criterion 2's at 2 pass / 11 fail, and #348's fix carries an in-run mutation self-check — what is missing is that these are acts of diligence rather than a contract. Scope is deliberately **decision gates only** (preflight, `fix_probes`, planner/pre-advance, containment, plus the tests certifying them), never ordinary unit assertions, and it starts as **policy plus an evidence inventory that changes no execution behaviour**, so rollback is deleting a doc section and a generated file. **#418 is the designated first child**, mirroring GH-308 Phase 1's use of #278 as proof its policy worked. Scope, sequencing and acceptance were revised after a Codex review that caught three defects in the original framing: a demanded "pre-fix count" that cannot exist for net-new behaviour, an inventory criterion conflating automatic *discovery* with evidence that must be *declared*, and an `unknown`-reporting requirement loose enough to land on ordinary unit tests. Preflight contract authored and verified READY via `--dry-run`; acceptance reads `match — 8/8 criteria copied verbatim from issue #419`. cx/risk/eff 3/2/3, 3 phases, ratings provisional. → [GH-419-TRUSTWORTHY-GATES.md](PROJECT/2-WORKING/GH-419-TRUSTWORTHY-GATES.md) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419) · [#418](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/418) · [#417](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/417)
- **GH-416 · a dependency sync silently deleted three working guardrails, and CI stayed red on `development` for two days because the failures read as noise** <!-- reads "working" where the issue title says otherwise: roadmap-issue-state keys on that done-word anywhere in the line, so echoing the title verbatim would read as a completion marker and contradict the 🟡 below (this comment avoids the word for the same reason) --> 🟡 **code fixed + merged 2026-08-03 (PR #413, `d06139c`); `validate.sh` 0 failures, `tier1` green — issue stays OPEN deliberately**, its last acceptance criterion (a stated policy for reviewing the next PDDA sync diff for deleted local behaviour) is not written yet — `cfd56b0` replaced the sync-managed `utils/pdda/**` tree wholesale, closed two failures and left three, which everyone (me included, in PR #413's body) carried as "pre-existing". Diffing across the commit found **three deleted checks** — GH-189's 3-COMPLETED stale-status scan (`non-terminal` 4 → 0), GH-189's entire **`roadmap-issue-state` subcommand** (5 → 0, so its test hit `unknown command`), and GH-284 Phase 3's missing-`Milestone:` warning — plus a deleted roll-up line and four introduced broken path refs. **Two were invisible behind the other two** because the test files fail-fast: the #315/#319/#351 broken-observation family again. Root cause is structural — local checks lived in a wholesale-replaced tree and `pdda.sh` has no extension seam — so they moved **out** to repo-owned `utils/pdda-local-checks.sh`, guarded falsifiably (trip-fixture *and* must-not-trip fixture per check, plus an upstream drift detector), and wired into both `validate.sh` and CI. One upstream change (INFO → WARN on unevaluable state) was **kept, not reverted** — its reasoning is better than what it replaced. cx/risk/eff 3/2/3. **Captured 2026-08-05 as a lane of release 0.2.0 Litmus, preflight READY, OPERATOR GO GIVEN 2026-08-08 — phase 1 of 3 in [MARATHON-2026-08-08-LITMUS-WAVE-2](PROJECT/2-WORKING/MARATHON-2026-08-08-LITMUS-WAVE-2/MARATHON.yaml), scoped to ONE criterion.** Re-verified against `development` @ `2c95a56`: criteria 1–4 already shipped in PR #413 (`utils/pdda-local-checks.sh` and `test/pdda-local-checks.sh` both exist and are wired into `validate.sh` *and* `ci.yml`). Only criterion 5 is outstanding — **a stated review policy for the next PDDA sync**, which exists nowhere; `PDDA sync` appears only as narrative in `CHANGELOG.md`/`ROADMAP.md`. Recorded explicitly because a doc restating all five would send a builder to rebuild four things that already exist, and **preflight would not catch it** — it has no issue-state or done-ness check (that is #418, a sibling lane in this release). Placement is load-bearing: `PROJECT/PDDA.md` is **sync-managed** (`utils/pdda/PDDA-SOURCE.md:12`), so a policy about surviving syncs cannot live there without restaging the incident — it goes in repo-owned `PROJECT/PDDA-SYNC-POLICY.md` with `AGENTS.md` pointing at it. cx/risk/eff 1/1/2, 1 phase. → [GH-416-PDDA-SYNC-DELETED-GUARDRAILS.md](PROJECT/2-WORKING/GH-416-PDDA-SYNC-DELETED-GUARDRAILS.md) · [#416](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/416)
- **GH-399 · the packet's acceptance block kept only each criterion's first line, so every hard-wrapped requirement reached the builder as a half-sentence** ✅ **SHIPPED 2026-08-03 (PR #413, `d06139c`); closed** — companion to #400 and the second cut in the same chain: #400 is the capture doc drifting from the issue, this is the packet drifting from the capture doc. Preflight matched only lines *beginning* a `- [ ]` bullet, and capture docs hard-wrap at ~80 columns, so continuations were discarded silently under a heading claiming the criteria were *"inlined from the capture doc"* — **10 of 10 lanes** in one marathon, 1–4 lines each. GH-201's *"raises a clear error instead / of silently resolving to the canonical DB"* lost the clause naming the defect; what survived reads as an order to **preserve** the fallback the issue exists to remove. **Correction to the report:** it cites `utils/swarm-preflight.sh:882`, which GH-308 **froze** — the executing defect was the same regex in the Python twin. Fixed with indent-gated continuation folding (reusing #400's extractor), extraction bounded to `## Acceptance` **where one exists**, an announced 25-item cap, and a lossless-copy check that re-parses the *rendered* block and sets NOT-READY rather than warning. `test/gh399-packet-acceptance-continuation.sh` **14/0**, pinning the full capture doc → packet → **relay file** chain byte-for-byte; observed **2 pass / 12 fail** pre-fix. **One criterion deliberately narrowed and declared** via #400's new deviations mechanism: bounding extraction *unconditionally* to `## Acceptance` would have emptied the acceptance block of **32 of this repo's 33 active capture docs**, which keep their checkboxes under `## Phase N` — deleting every lane's definition of done to close a leak the issue itself files as *"not yet observed."* Writing the test also cost one orphaned driver holding `.git/relay-driver.lock` in the live repo (missing `MARATHON_ROOT`), so the chain test now runs under a hard 60s timeout. cx/risk/eff 2/2/2. → [GH-399-PACKET-ACCEPTANCE-CONTINUATION.md](PROJECT/3-COMPLETED/GH-399-PACKET-ACCEPTANCE-CONTINUATION.md) · [#399](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/399)
- **GH-400 · `/10days` capture docs restate a GitHub issue's acceptance criteria instead of copying them — a measured case inverted one, and the marathon delivered the inversion** ✅ **SHIPPED 2026-08-03 (PR #413, `d06139c`); closed — re-verified before registering** — Step 4 has a model summarise an issue into `PROJECT/2-WORKING/`, and everything downstream (preflight → packet → relay file → builder → reviewer) reads the **summary**, never the issue; nothing compares the two. Independently re-derived from both source repos rather than taken on the report's word: `rebalance-OS` #202 requires the malformed row be *"never silently dropped"*, the capture doc requires asserting *"the actual current behavior (drop the row…)"*, and the delivered test (`3673257f`, reproduced identically by a second run at `7525d047`) adds a function named **`malformed_source_row_is_dropped`** — every quoted string matches byte-for-byte, and the delivered artifact is worse than reported. Two criteria were dropped outright, including the one written specifically to prevent what shipped. **No downstream role can catch it**: builder and reviewer both read the packet, so no undamaged copy of the requirement exists anywhere in the pipeline — every gate was green and the phase closed. Not a source-material problem: 9 of 9 sampled issues carry an explicit `## Acceptance` block; the degradation is introduced in translation. **Two corrections to the report:** its suggested fix leans on *"preflight already fetches the issue"* — **it does not**, neither twin invokes `gh` at all, so the gate must introduce the first body-fetch into that path and carry its own offline contract; and companion **#399** cites `utils/swarm-preflight.sh:882`, which GH-308 **froze** — the line that actually runs is `utils/py/swarm_preflight.py:844`. Fix is a copy-not-restate skill contract, an explicit deviations section, and a preflight check that hard-fails on unexplained divergence while reporting `unknown` (never blocking) when the issue is simply unreachable. cx/risk/eff 3/3/3. → [GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md](PROJECT/3-COMPLETED/GH-400-CAPTURE-DOC-ACCEPTANCE-FIDELITY.md) · [#400](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/400) · [#399](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/399) — **criterion 2 closed 2026-08-04**: it had shipped as prose only (`SKILL.md` told the model to set `source:`; no gate read the field), so `source: issue#400` or no `source:` at all passed everything — this issue's own defect inside its own fix. `check_source_url()` now hard-fails NOT-READY on a doc that does not cite its issue's URL; blast radius measured at 1 of 48 before choosing the posture, and that one doc fixed in the same commit. `test/gh400-source-url.sh` **13/0**, observed **2/11** pre-fix. All four criteria met.
- **GH-381 · `/Releases` rolling release-train planner** 🆕 **captured 2026-07-30** — proposal for a preview-first planning skill that lays out 4–5 upcoming releases, each with four or five explicit iteration slots, and hands one bounded milestone-derived iteration to `/10days` without duplicating the `RELEASES.md` ledger or GitHub issue membership. → [GH-381-RELEASES-ROLLING-TRAIN.md](PROJECT/1-INBOX/GH-381-RELEASES-ROLLING-TRAIN.md) · [#381](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/381)
- **GH-351 · the registered dashboard gate graded its own answer key** ✅ **done (2026-07-30)** — `test/roadmap-dashboard.sh` rendered the dashboard **into the repo** and then `--check`ed the copy it had just written, so its drift assertion could never fail; its own pass string read *"--check passes on the committed artifact"*, which was false by the time it ran. **The renderer was never the defect** — standalone `utils/roadmap-dashboard.sh --check` returned `rc=1` on all three of the day's stale dashboards, so the correct signal existed the whole time and the test overwrote its input before asking. A second, quieter fault: the test **wrote into `$ROOT`**, so `validate.sh` silently un-staled the dashboard mid-run — a suite repairing the evidence it was meant to judge, and leaving the tree dirty. Three stale dashboards reached `development` on 2026-07-30 alone from three different authors (GH-342, #356, #350); it fires on essentially every ROADMAP-touching PR. Fixed by two rules: `--check` runs **first** against the **committed** artifact, and nothing writes `$ROOT` (write-mode goes through `ROADMAP_DASHBOARD_OUTPUT`, which the renderer already supported — no renderer change). **4 → 9 cases**, including a mutation proof (case 4 plants a canary and requires `--check` to reject it, since cases 1 and 3 are unfalsifiable alone) and a no-side-effect assertion. **Verified against the real commit, not a synthetic fixture:** replaying `719867f`, the old test scores **4 pass / 0 fail** on a genuinely stale dashboard while the new one scores **6 pass / 3 fail**. Two findings only visible by running it — the old test left `ROADMAP-DASHBOARD.md` modified afterwards, and **case 9 (section counts) was already correct and still reported green**, because the regeneration ran first: the bug did not add a bad assertion, it *disabled a good one*. Sixth instance of *an assertion that compares a thing to a freshly-derived copy of itself* after #348/#342/#362(B)/#369. cx/risk/eff 2/2/2. → [GH-351-DASHBOARD-TEST-GRADES-ITS-OWN-ANSWER-KEY.md](PROJECT/3-COMPLETED/GH-351-DASHBOARD-TEST-GRADES-ITS-OWN-ANSWER-KEY.md) · [#351](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/351)
- **GH-369 · `/10days`' capture-doc lookup hung forever on a valueless `--root`, in a skill built to run unattended** ✅ **done (2026-07-30)** — found reviewing PR #364 before merge; that PR's own GH-344 fix is correct and shipped, these are defects in the argument parser it introduced. `shift 2` with one argument left shifts nothing and returns non-zero, and `find-doc.sh` is deliberately `-e`-exempt, so `$#` never decreased, `$1` stayed `--root`, and the loop re-entered forever — confirmed at **rc=142/SIGALRM** under an `alarm(5)` wrapper. The severity is not the malformed call but the *shape*: `/10days` runs unattended, so this stalls a sweep with no error, no output and no timeout — the absent-signal class of #315/#319/#351, not a wrong answer. Second defect: a bad `$TENDAYS_ROOT` reported `--root not a directory:`, naming a flag never passed and printing an empty path; the resolver now records which of its four sources supplied the value. (My first fix repeated the same class — printing `$ROOT`, already emptied by the failed substitution — kept as `$ROOT_RAW`.) **The durable half is coverage**: the file had *no* test and was absent from `validate.sh`'s `TESTS=()`, which is why both defects and GH-344's resolution order shipped unguarded. New `test/gh369-find-doc-root-resolution.sh` **14/0**, hang-capable cases under a hard `alarm` cap so a regression fails the gate instead of hanging it. Observed failing against **both** prior revisions: **12/2** vs pre-fix (exactly cases 1–2), **4/10** vs pre-#364 (case 6: *"answered GH-163 from the HARNESS tree"*). **Case 6 was wrong first** — it probed an issue absent from both trees, so bug and fix both returned `null` and it passed against the code it existed to catch; a fifth member of the *assertion that cannot distinguish the bug from the fix* family after #348/#342/#351/#362(B). cx/risk/eff 2/2/1. → [GH-369-FIND-DOC-ARG-PARSE-AND-ROOT-RESOLUTION.md](PROJECT/3-COMPLETED/GH-369-FIND-DOC-ARG-PARSE-AND-ROOT-RESOLUTION.md) · [#369](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/369)
- **GH-354 · concurrent swarms: the driver lock blocks 1 of 3 pairs, and the monitors can't see the one it does** 🟡 **active — Phase 0 discovery complete 2026-07-30; Phase 1 (relay-drive worktree lock) next** — review of [#354](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/354)'s own analysis, which reasoned about `relay-drive.sh`/`relay-turn-lib.sh` from `marathon-drive.sh`'s comments because it lacked the files. Reading them overturns the conclusion's basis: `relay-drive` never received GH-49b's linked-worktree lock branch on **either** runtime (`relay-drive.sh:147-152`, `utils/py/relay_drive.py:386-391`), so it takes a per-worktree lock while `marathon-drive` takes a shared one — marathon↔marathon excludes, marathon↔relay and relay↔relay silently do **not**, the second being two drivers on one working tree with no guard at all. Also overturned: `.tick/` task ids, lane attempt counters and `tick analyze` cost do **not** commingle across linked worktrees (`TICK_REPO_ROOT` defaults to each shim's own `ROOT`), deleting 3 of #354's 5 collision claims and the `.tick`-namespacing work it proposed. #354's one-line observability footnote is escalated to a phase: the false-IDLE is in **three** monitors (`marathon-ls.sh:44-50`, `utils/hq/marathon-live.sh:94-95`, `utils/hq/hourly-global-scan.sh:28`), so the operator's every window onto the lock state is blind in exactly the shape under discussion. Separate full clones remains the right operator answer — for a different reason than #354 gave. Plan does **not** enable parallelism: Phases 1–3 make the exclusion contract true, provable and observable; Phase 4 is a GO/NO-GO gate whose first criterion is that nobody has ever written down the GH-42 `ROOT@HEAD` mechanism. cx/risk/eff 4/3/3. → [GH-354-CONCURRENT-SWARMS.md](PROJECT/2-WORKING/GH-354-CONCURRENT-SWARMS.md) · [#354](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/354)
- **GH-347 · pi CLI installed inside another app's folder, invisible to PATH** 🆕 (2026-07-29) — found driving the GH-336 round-4 review: `find-harness.sh --check` reported `pi` absent while it was installed and working inside `~/.hermes/node`, a separate agent app's bundled Node runtime. Cause is ambient, not a typo — that app symlinked its `npm` onto PATH, so `npm config get prefix` returns its folder and a bare `npm install -g` lands our tools there silently, exit 0, with no `~/.npmrc` involved. Risk is silent loss on a foreign app's update schedule, and `--check` cannot distinguish "wiped" from "never installed" — same observation-layer disease as #315/#319. Phases 1 and 2 are **done** (2026-07-30): `pi` reinstalled via Homebrew's npm into `~/.local` (launcher now `~/.local/bin/pi`, same shape as `codex`/`agy`), removed from `~/.hermes` (132 packages), Hermes's own symlinks untouched, `test/pi-turn.sh` 39/0; and the `GUIDING-PRINCIPLES.md` convention landed. **Correction:** `find-harness.sh` never probed for `pi` at all (it exports only tick/codex/agy), so a missing `pi` gives *no* signal rather than a negative one — Phase 3 now carries adding that probe, and is no longer optional. → [GH-347-TOOL-INSTALL-PATHS.md](PROJECT/1-INBOX/GH-347-TOOL-INSTALL-PATHS.md) · [#347](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/347)
- **GH-336 · planning context: phase metadata signals before deterministic marathon contracts** 🆕 — proposed three-phase, advisory-first planning context linking release alignment, delivery arc, and churn signals; ships Python-only, default-off, writing a sidecar so the plan doc is byte-identical in every mode. Release alignment delegates to `utils/release-lanes.sh seed|rollup` (#330) rather than re-deriving scope. Relay-reviewed across 4 rounds / 3 models (codex, agy, pi+qwen) → Approved at r3, re-opened at r4 which overturned two criteria. **Re-tested 2026-07-30 (GH-370):** all four rounds cited `_marathon_plan_node.js`, which #340 deleted — 7 of 8 findings hold, and the 5 stale/false claims are corrected. → [GH-336-PLANNING-CONTEXT.md](PROJECT/1-INBOX/GH-336-PLANNING-CONTEXT.md) · [#336](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/336) · [#370](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/370)
- **GH-320 · the executing Python lane caps turns at a third of the documented budget** 🆕 (2026-07-28) - found when it killed the agy review turn for PR #318: `agy -p exceeded 300s wall-clock cap`, on a shim whose header and code both say **900**. XYZ has been Python-default since GH-264, so `agy-turn.sh` `exec`s `utils/py/agy-turn.py` — which defaulted to **300**. Same split in `codex-turn` (900↔300) and `claude-turn` (600↔300); `aider-turn`/`pi-turn` were consistent. The failure surfaces as `exit 7` *(turn timeout / hang)*, which reads as a hung model rather than a misconfigured ceiling — and the natural response, retrying, burns another turn at the same wrong cap. **GH-308's freeze does not cover this**: freezing the twins stops them drifting *forward* and says nothing about values that had already diverged. Fixed by aligning the three Python defaults, plus `test/gh320-twin-timeout-parity.sh`, which reads the default from **both** files rather than hardcoding an expectation (a third copy would be a third thing to drift) and separately asserts each Bash header's documented `(default: N)` matches its own code. Open follow-on for GH-308 Phase 2: nothing establishes the turn timeout was the only constant that diverged. Issue [#320](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/320). -> [PROJECT/3-COMPLETED/GH-320-TWIN-TURN-TIMEOUT-DRIFT.md](PROJECT/3-COMPLETED/GH-320-TWIN-TURN-TIMEOUT-DRIFT.md)
- **GH-319 · the marathon pre-advance gate word-splits a spaced repo path and passes on the wrong file** 🆕 (2026-07-28) - found while verifying the 2026-07-27 marathon by direct inspection instead of trusting its exit code. `utils/py/marathon_drive.py` interpolated the default gate **unquoted** into a `shell=True` command, so at `.../GH Repos/xyz-3-agents-swarm` the shell ran `bash $HOME/Documents/GH` — an unrelated **0-byte file** — exiting 0 in 0.0s with no output. All four phases logged `STATUS: Approved, gate passed` while `bash validate.sh` was in fact RED. Timing was the tell: 6.6s/7.5s from `agy-done` to `phase.approved` against a **483s** real suite. GH-238's gate-runnable preflight did not catch it — its `(\S+)` regex captured the same wrong fragment and `isfile()` on the decoy returned True, so **the guard and the gate agreed on the wrong file**. Third instance of one failure class after [#315](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/315) and the sandboxed-liveness gap: a broken observation layer where failure is invisible. Fixed with `shlex.quote` + `shlex.split`; `test/gh319-gate-path-with-space.sh` plants the same 0-byte decoy at the split point and was observed **failing pre-fix** (driver printed "gate passed", exit 0, while the fixture gate exited 1) and passes 6/0 post-fix. `relay-automation/marathon-drive.sh:493` has the identical defect and is **deliberately left unpatched** — GH-308 froze it in the same PR — so `XYZ_PYTHON=0` at a spaced path retains a fake gate until Phase 2 retires the twin. Issue [#319](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/319). -> [PROJECT/3-COMPLETED/GH-319-MARATHON-GATE-PATH-WORD-SPLIT.md](PROJECT/3-COMPLETED/GH-319-MARATHON-GATE-PATH-WORD-SPLIT.md)
- **MARATHON-2026-07-27 · gate + fleet integrity (GH-311 → GH-289 → GH-293 → GH-308)** ✅ FIRED 2026-07-28 (2026-07-27) - marathon file built by the `/10days` sweep under an operator narrowing (top-3 critical bugs + the single highest-unlock feature). All 4 lanes preflight **exit 0 / READY**. Fully sequential by design: `validate.sh` is in all four write-sets (each lane registers a new test) and `relay-drive.sh` is in both GH-289 and GH-308 — a Step 6.5 overlap diff, not a planner guess. **Fired 2026-07-28: all 4 phases approved in 2 turns each (gh293 took 4), exit 0, PR [#318](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/318).** Every lane produced a real, contract-matching deliverable — but **each phase's "gate passed" was false** (see GH-319); the suite was genuinely RED on stale `relay-pkg.tar.gz` throughout. -> [PROJECT/3-COMPLETED/MARATHON-2026-07-27-GATE-AND-FLEET-INTEGRITY/MARATHON.yaml](PROJECT/3-COMPLETED/MARATHON-2026-07-27-GATE-AND-FLEET-INTEGRITY/MARATHON.yaml)
- **GH-311 · `validate.sh` can be green while CI tier1 is red** 🆕 (2026-07-27) - the local suite registers only `pdda-roadmap-coverage.sh`, which runs the PDDA checker against *synthetic fixtures*; it never runs `pdda.sh run` against the repo's real `PROJECT/`+`ROADMAP.md` the way tier1 does. PR #309 was locally green with 7 real doc-contract errors. Because `validate.sh` is the default marathon `--pre-advance-cmd`, a lane can advance on a false-positive gate. Scheduled FIRST in the 2026-07-27 marathon so every later lane is gated by a gate that means something. Issue [#311](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/311). -> [PROJECT/3-COMPLETED/GH-311-VALIDATE-MISSES-REPO-PDDA-CONTRACT.md](PROJECT/3-COMPLETED/GH-311-VALIDATE-MISSES-REPO-PDDA-CONTRACT.md)
- **GH-289 · `--target-root` BUILD turns silently lose the relay Log** 🆕 (2026-07-27) - GH-245's fast-refusal is gated on `((REVIEW_ONCE))`, re-verified still present at `relay-automation/relay-drive.sh:273`, so a build turn completes at full cost and discards its Log. Surfaces as `no-progress` — reads as a model failure, is a harness one; Codex takes the blame, agy bypasses the guard. `--artifact-file` can't substitute (read-only seed). Leaves **no working configuration** for "harness in repo A, code in repo B, Codex as builder." Issue [#289](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/289). -> [PROJECT/3-COMPLETED/GH-289-TARGET-ROOT-BUILD-TURN-LOG-LOSS.md](PROJECT/3-COMPLETED/GH-289-TARGET-ROOT-BUILD-TURN-LOG-LOSS.md)
- **GH-293 · vendored `.xyz` copies silently miss safety guards** 🆕 (2026-07-27) - `xyz-sync check` can only report an opaque commit-hash delta, so an operator can't tell "cosmetic drift" from "missing a safety guard" (GH-245 shipped without moving `tick_version`, so the version contract can't express it); and `cmd_update` has no dirty/non-canonical-source guard, so `update --all` from a dirty far-ahead branch would push unmerged code fleet-wide in one command. Touches the same `xyz-vendor.sh` swap path as the GH-312 preserve-list fix — must not regress it. Issue [#293](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/293). -> [PROJECT/3-COMPLETED/GH-293-VENDORED-GUARD-DRIFT.md](PROJECT/3-COMPLETED/GH-293-VENDORED-GUARD-DRIFT.md)
- **GH-312 · `xyz-sync update` destroys the target's live `relay-system/` and `.tick/` state** 🆕 (2026-07-27) - `update` re-vendors the whole `.xyz/` tree via an unconditional `rm -rf "$VENDOR_DIR"` (`xyz-vendor.sh:281-282`) whose staged replacement is mirrored purely from `$HARNESS_ROOT` — so everything the *target* accumulated at runtime is deleted unread. Exits 0, prints success, no warning, no backup, no `--dry-run`, no preserve list anywhere in `xyz-vendor.sh` or `xyz-sync.sh`. **Deterministic — every time.** Three things make it worse than it reads: the destroyed paths are exactly what vendoring is *sold on* (`relay-xyz/SKILL.md`: a vendored install gives you your "own `.xyz/.relay-driver.lock`, `.tick/`, and worktrees"); `ensure_gitignore` makes `.xyz/` gitignored by construction, so nothing was ever hashed into a git object and there is no reflog/stash/`fsck` recovery; and a *closed* relay was the lucky case — the same command mid-review destroys an active thread and a claimed `tick` token, and the peer agent's turn simply vanishes. Docs actively mislead: `xyz-sync.sh`'s header frames updates as "pinned + manual, by design", i.e. deliberate, never destructive. **Real incident:** silently destroyed a completed 2-round Codex relay thread (both reviews, dispositions, closing block) + the full `.tick/` event log; survived only because the Codex CLI transcripts live in `$TMPDIR`, outside the harness. `xyz-sync list` showed **6 repos** vendored at the same stale commit — `update --all` would take them all out in one command. Requested fix: preserve `relay-system/`, `.tick/`, `.relay-driver.lock` into the stage before the swap (chosen over warn-or-refuse, both of which still depend on someone reading output at the right moment). Phase 0 carries the sharper open question — whether runtime state belongs under a disposable, gitignored `.xyz/` at all. Bug filed via /file-xyz-bug from `rebalance-OS` at harness `dff45d5`. **✅ SHIPPED 2026-07-27 (`4ec5928`)** — `materialize_vendor()` now carries target-owned state across the stage-then-swap. **The requested preserve list was incomplete:** auditing what `.xyz/` actually accumulates added the GH-75 telemetry trio (`XYZ.json`, `XYZ.json.lock/`, `XYZ.heartbeat.json`), which had identical exposure — not in `VENDOR_DIRS`, so never recreated by the stage — making the shipped list **six** paths, not three. Regression test `test/gh312-vendor-preserves-state.sh` was written first and observed **failing pre-fix (6 failures)**, passes 14/14 post-fix, and also pins that VERSION still restamps to live HEAD so a fix that "preserved" state by skipping the update cannot pass. Phase 0's open question about `xyz-vendor.sh vendor` over an existing `.xyz/` is **answered: same destructive path**, now covered. Reviewed by agy via a driven relay (Approved, 4 `[Pass]`, no defects raised — a clean but shallow signal). `validate.sh` green. **Still open, deliberately out of scope:** whether runtime state should live outside `.xyz/` entirely — needs its own issue. Issue [#312](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/312). -> [PROJECT/3-COMPLETED/GH-312-XYZ-SYNC-DESTROYS-STATE.md](PROJECT/3-COMPLETED/GH-312-XYZ-SYNC-DESTROYS-STATE.md)
- **GH-308 — Stop maintaining the Bash twins** ✅ **PHASE 1 SHIPPED 2026-07-29 — released as Quicksilver 0.1.0; issue closed.** Insurance tag `bash-final-2026-07-28` cut at `06100cc` (the one checklist item never done, found by verifying rather than trusting); freeze guard demonstrated blocking a staged twin edit (exit 1); 20 single-lane Python-only fixes shipped as the proof (#322, #331, #289, 16 in #338, #342 — the last known item in the class). Phases 2-3 were never contracted and stay unscheduled: they need a new issue, not this one reopened. Original capture follows — (2026-07-26, promoted to 2-WORKING 2026-07-27 — **Phase 1 ONLY** contracted, freeze-not-delete; Phases 2-3 stay unscheduled) - project: make Python the single authoritative lane for the 11 entry points with a real Python twin (`agy`/`aider`/`claude`/`codex`/`pi-turn`, `poll`, `relay-loop`, `relay-drive`, `consult`, `marathon-drive`, `swarm-preflight`); **freeze, do not delete** — banner + commit guard, a frozen `bash-final-2026-07-26` tag as the escape hatch, then collapse the ~72-invocation dual-lane test matrix. Motivated by a recurring correctness bug class, not just cost: Python is the default runtime since GH-264, so Bash-only fixes silently do not run (#296, #215, #223, #174, #148; **#278** — aider-turn timeout drift py 300s / sh 600s / docs 900s). `marathon-plan` **carved out** — its "port" delegates to a vendored node engine with documented gaps, so Bash stays authoritative there; `relay-turn-lib.sh` untouched (the Python lane shells into it at runtime). Deletion is opportunistic and unscheduled; a mixed Bash + Python tree is the accepted end state. Captured via /idea. Issue [#308](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/308). -> [PROJECT/3-COMPLETED/GH-308-BASH-TWIN-RETIREMENT.md](PROJECT/3-COMPLETED/GH-308-BASH-TWIN-RETIREMENT.md) · behavior-audit follow-on (sweep all 11 pairs for Bash-only behavior dead on the default Python lane; ports #331 cost summary + #289 build-turn guard + 14 more) -> [PROJECT/3-COMPLETED/GH-308-BASH-TWIN-BEHAVIOR-AUDIT.md](PROJECT/3-COMPLETED/GH-308-BASH-TWIN-BEHAVIOR-AUDIT.md)
- **GH-304 · Vendored `.xyz` relay lane is broken for Codex but works for agy** (2026-07-26) - second, independent reproduction of #304, captured via /file-xyz-bug from `rebalance-OS` at harness `e8cd951` (**newer than the original report's `efdb394c54ed` — not fixed at HEAD**). New finding beyond the existing diagnosis: the failure is **worker-dependent**. In one session, on the same vendored `.xyz/`, an agy review completed two full rounds and landed content while Codex failed 3× across both isolation modes — so the lane reports green to anyone who smoke-tests it with agy, which likely explains how a 100%-reproducible break in one of the two documented builders went unnoticed. Also refines the isolation-ON mechanism (Codex *can* read the pinned checkout; the **write** is rejected as "outside of the project" — seeding for read alone won't fix it) and corroborates the secondary false-negative `no tracked changes` message in a second repo with a gitignored `relay-system/`. Workaround confirmed: scaffold + drive from the live harness clone with `--embed`, at the cost of the per-repo driver lock vendoring exists to provide. Issue [#304](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/304). -> [PROJECT/1-INBOX/GH-304-VENDORED-XYZ-CODEX-RELAY.md](PROJECT/1-INBOX/GH-304-VENDORED-XYZ-CODEX-RELAY.md)
- **GH-305 — 4-agent swarm validation test** (2026-07-24) - spike: one instrumented 4-agent concurrent-swarm run on a large repo (`LTVera-Pandas`/`sleuth-app`) with a codebase-memory dependency-aware lane preflight, added observability (overlap-rejection counts, per-lane wall-clock, JSON run summary, graph-cut-vs-path-cut control arm), and a fault-injection phase (manual reap, no watchdog today). Captured via /idea. Issue [#305](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/305). -> [PROJECT/1-INBOX/GH-305-4AGENT-SWARM-TEST.md](PROJECT/1-INBOX/GH-305-4AGENT-SWARM-TEST.md)
- **GH-296 · relay-drive.sh EPERM on tick lock in a same-repo vendored .xyz reviewing an artifact outside .xyz/** 🆕 **captured 2026-07-23 via /file-xyz-bug from `pdda`; root-caused + fixed same day on branch `gh-296-relay-drive-tick-eperm`** — **not a fresh instance of #263's bug: a regression via incomplete port.** #263's fix genuinely landed in the Bash `codex-turn.sh` (commit `8c361a0`), but this repo later flipped its default turn-shim runtime to Python (GH-264, `af7bb4d`) — *after* #263 shipped — and `utils/py/codex-turn.py` (the file that actually executes by default now) never received the #263/GH-36 fix at all, and separately mis-resolved its own `root` (defaulted to the harness's own directory instead of falling back to the CWD's git toplevel like Bash does). Fixed: `resolve_turn_root()` helper in `rtl.py` + `codex-turn.py`'s `--add-dir` built off `tick_repo_root`. **Follow-up folded in (same session, not a separate issue):** `agy-turn.py`/`claude-turn.py` shared the identical `root` defect (their own pre-launch `tick claim --paths` computation escaped the repo root with `../..`), plus a second, independent GH-51-class symlink physical/logical-path bug found while testing the fix (`git rev-parse --show-toplevel`'s physical-path form vs. a caller's unresolved macOS `/var`→`/private/var` path) — both fixed in `rtl.claim_paths_for_turn`. 5 new/extended regression cases across `test/{codex,agy,claude}-turn.sh`, each verified to fail pre-fix / pass post-fix via `git stash`. `relay-pkg.tar.gz` rebuilt (drifted from the `test/*.sh` edits). Also related to open #272 (same TICK_REPO_ROOT-in-vendored-lane root-cause family; this session's `root`-default fix may also resolve it — unverified, flagged for a human to confirm separately). Workaround while unfixed: `consult.sh` with `CONSULT_ROOT`. → [GH-296-RELAY-DRIVE-TICK-EPERM.md](PROJECT/1-INBOX/GH-296-RELAY-DRIVE-TICK-EPERM.md) · [#296](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/296)
- **GH-281 · Sentinel / Debug Flywheel — opt-in debug capture (public) + private triage overlay** 🆕 **captured + triaged + Codex-relay adjudicated 2026-07-22** — turns the harness's runtime failure/lesson signal into a capture→triage→plan→execute→PR→review pipeline, split into a public opt-in `XYZ_DEBUG_LOG` capture-only tier (one gitignored `debug.log`, zero network) and a private, unbundled Gemma triage overlay. Verdict: accept direction, gate execution. A `/relay-xyz` Codex review (Changes requested, 2 Blockers + 3 Shoulds, all accepted) corrected two holes: the Tier-2 issue→PR loop is operator experimentation *outside this repo's delivery scope* (reopening needs DO-NOT-BUILD's canonical amendment path, not a capture note), and the human gate is hardened (no auto-clear of `ratings_provisional`; explicit per-run attestation; canonical PDDA selection gates only on `risk`). Tier-1 Stage-0 is the *proposed* first slice, ready only after its own confirmed ratings + a green §1.7 run. Umbrella — do not fire as one lane. cx/risk/eff 4/4/4 (provisional, route-to-human). → [GH-281-SENTINEL-DEBUG-FLYWHEEL.md](PROJECT/1-INBOX/GH-281-SENTINEL-DEBUG-FLYWHEEL.md) · [#281](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/281)
  - **↳ Tier-1 Stage-0 carve (2-WORKING, swarm-preflight `ready` 2026-07-22)** — the headlessly-buildable slice: 3 standalone zero-network scripts (`harvest-findings.sh`, `finding-new.sh`, `hooks/sentinel-network-guard.sh`) + 2 covering suites + the `debug.log` gitignore line + `validate.sh` test-registration. Driver Stage-0 hooks (`marathon-drive.sh`) and integration acceptance are **orchestrator-only** (self-edit hazard), not in the builder lane. cx/risk/eff 2/2/2. **SHIPPED** — built (Codex+Agy marathon), a 3-round Codex relay closed 2 blockers, merged #285; §1.3 driver hooks applied + integration-tested + Agy-QA-approved. → [GH-281-SENTINEL-TIER1-STAGE0.md](PROJECT/3-COMPLETED/GH-281-SENTINEL-TIER1-STAGE0.md)
  - **↳ Tier-2 overlay (2-WORKING, built + Agy-QA-approved 2026-07-22)** — the full triage overlay (reader → Gemma classify → draft PDDA doc → file issue → nightly batch → PR-emit → adversarial red-team → morning report) shipped as **transparent in-repo reference code**, with every call-home path (ollama/`gh`/`git push`/marathon-fire) gated behind a gitignored `runtime.env`. **Inert by default** — proven by `test/sentinel-overlay.sh` (zero network/LLM/GitHub with no config). Operator opts in locally to activate. cx/risk/eff 4/4/3 (provisional). → [GH-281-SENTINEL-TIER2-OVERLAY.md](PROJECT/3-COMPLETED/GH-281-SENTINEL-TIER2-OVERLAY.md)
- **GH-280 · Investigate Aider+Qwen3.8-Max reliability vs Aider+Claude-Sonnet-5 control ($5 OpenRouter budget)** 🔬 **Phase 1+2 run 2026-07-23 — 80 trials, root cause narrowed, not fully isolated.** Corrected baseline: 6/7 (~86%) real historical failure rate. 62/62 clean across edit-format, file-count, prompt-complexity, repo-scale, and an OpenRouter `qwen3.7-max`-vs-`sonnet-5` control (10/10 pass each, $0.40 of $5 spent) — rules out Qwen-inherent-unreliability and Aider-edit-format-mismatch alone. Only real `git worktree add --detach` reproduced it: 15/18 pass (16.7% fail, matching production's empty-file signature) — points at Aider's own behavior under detached-HEAD worktree mechanics, not Qwen, not this repo's harness (`relay-turn-lib.sh` copyback logic read in full, confirmed sound). **Update 2026-07-23 (second session):** with real GH-161 log persistence finally in place, a real Qwen-builder exercise caught and read an actual failure transcript — the "no tracked changes" symptom is Aider's `whole` edit format silently discarding a genuinely correct edit because Qwen emits unified-diff hunks instead; forcing `AIDER_FLAGS=--edit-format diff` took a real production task from 0/3 real edits to a 90%-complete, substantively correct implementation in round 1. Root cause resolved: **H2 (edit-format mismatch) was real all along** — earlier synthetic tests were too small/simple to trigger it. cx/risk/eff 3/2/3. → [GH-280-AIDER-QWEN-VS-SONNET-INVESTIGATION.md](PROJECT/1-INBOX/GH-280-AIDER-QWEN-VS-SONNET-INVESTIGATION.md) · [#280](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/280)
- **GH-279 · aider-qwen marathon trial — consolidated run issues** **captured 2026-07-22; SHIPPED 2026-07-24** — re-grounded all 6 original items against the live repo before firing: items 1/2 resolved via #280, item 3 tracked separately as #278, items 5 and 6b confirmed not applicable. Fired via `swarm-preflight → marathon-drive` (Codex builder, agy reviewer): fixed **(4)** zero-byte/unchanged artifacts passing as "appeared" in `marathon-drive.sh`/`marathon_drive.py` (reused the existing `requires_test_delta()` non-empty+git-delta pattern) and **(6a)** the aider-turn API key leaking into `ps` argv on the `AIDER_OPENAI_API_BASE` seam (moved to `OPENAI_API_KEY` env). First turn's off-allowlist edits (a stray `CHANGELOG.md` entry, an unrelated concurrently-open scratch file) were correctly reverted by containment; closed out manually rather than risk a third automated invocation colliding with the operator's own concurrent edits — 63/63 + 137/137 targeted tests, full `validate.sh` green (only pre-existing environmental reds). Agy's own review didn't run (auth expired); reviewed by the orchestrating session instead, disclosed in the doc/CHANGELOG rather than treated as equivalent. This closes out the GH-279/GH-280 marathon. → [GH-279-AIDER-QWEN-MARATHON-TRIAL-FINDINGS.md](PROJECT/3-COMPLETED/GH-279-AIDER-QWEN-MARATHON-TRIAL-FINDINGS.md) · [#279](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/279)
- **GH-276 · Weekly risk-control reconciliation — keeping GH-275 on the ball** 🆕 **captured 2026-07-22** — recurring, comment-based evidence review that reconciles the live `development` branch, GitHub state, PDDA docs, containment/parity incidents, vendor drift, and recovery controls without becoming a second plan or auto-firing work. → [GH-276-WEEKLY-RISK-RECONCILIATION.md](PROJECT/1-INBOX/GH-276-WEEKLY-RISK-RECONCILIATION.md) · [#276](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/276)
- **GH-275 · Long-Term Risk Remediation — balanced, evidence-led safety program** 🆕 **captured and reconciled 2026-07-22** — umbrella residual-risk register, rewritten as a six-phase actionable checklist after a timed rescan of `development`; reuses existing issues, treats shipped work as controls, caps committed work at three proof-sized lanes, and delegates weekly drift checks to GH-276. → [GH-275-LONG-TERM-RISK.md](PROJECT/1-INBOX/GH-275-LONG-TERM-RISK.md) · [#275](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/275)
- **GH-274 · marathon-drive: re-invoking a phase whose tick token is already done clobbers RELAY.md's Approved record instead of detecting a satisfied lane** 🆕 **found live 2026-07-21 during GH-273 Phase 0's real fire** — the relay succeeded (Codex builder, agy reviewer, Approved), the `bash validate.sh` pre-advance gate flaked on an unrelated pre-existing test, and retrying via `marathon-drive.sh` re-rendered `RELAY.md` back to `STATUS: Open` and failed on the already-`done` tick token (can't reopen), discarding the accurate Approved record — recovered manually via `git revert`. Fix direction: extend the existing GH-207 satisfied-lane detection to also cover "gate failed after an already-terminal relay," not just its current mid-relay reroute case. Not blocking — a distinct `--phase-id` per fire avoids the collision entirely (confirmed live during GH-273 Phase 1's fire), but `swarm-preflight`'s suggested command never varies it, so any caller copying that verbatim across repeat fires hits this. cx/risk/eff 3/2/2. → [GH-274-MARATHON-DRIVE-DONE-TOKEN-RETRY-CLOBBER.md](PROJECT/3-COMPLETED/GH-274-MARATHON-DRIVE-DONE-TOKEN-RETRY-CLOBBER.md) · [#274](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/274)
- **GH-294 · swarm-preflight: isolation flag not carried into the suggested marathon command** 🆕 **landed 2026-07-26 (marathon phase 1/4)** — the preflight packet's suggested invocation omitted the worktree-isolation flag, so a copy-paste fire silently ran unisolated. Relay Approved, lane satisfied. → [GH-294-PREFLIGHT-ISOLATION-FLAG.md](PROJECT/3-COMPLETED/GH-294-PREFLIGHT-ISOLATION-FLAG.md) · [#294](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/294)
- **GH-292 · A linked worktree cannot discover the main checkout's vendored .xyz harness** 🆕 **landed 2026-07-26 (marathon phase 3/4)** — `find-harness.sh` now resolves the main checkout's `.xyz/` from a linked worktree via the shared `.git` probe, and falls back truthfully when that vendor is unusable. Gate initially failed on two static guards (GH-177 mktemp shape, GH-64 unsanitized eval) in the new fixture; both fixed rather than baselined. → [GH-292-WORKTREE-VENDORED-DISCOVERY.md](PROJECT/3-COMPLETED/GH-292-WORKTREE-VENDORED-DISCOVERY.md) · [#292](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/292)
- **GH-272 · Driven relay turn's tick release resolves wrong TICK_REPO_ROOT in a vendored same-repo lane** 🆕 **captured 2026-07-21 via /file-xyz-bug from `sleuth-app`; root-caused + fixed 2026-07-23 via GH-296/PR #297, NOT this doc's own contract** — traced to `RelayTurnLib._run_rtl()` (`utils/py/rtl.py`) feeding `codex-turn.py`/`agy-turn.py`/`claude-turn.py`'s buggy `root` default into every bridged `relay-turn-lib.sh` call (incl. the turn-prompt text and the GH-67 backstop release) as `TICK_REPO_ROOT`. Confirmed via a live A/B repro with `xyz-vendor.sh`: pre-fix baked `TICK_REPO_ROOT="<target>/.xyz"` into the prompt and the backstop release itself, matching this issue's exact symptom; post-fix (PR #297) resolves both. This doc's own drafted contract targeted `relay-turn-lib.sh`'s `rtl_tick_bin()` — the wrong file — and is marked superseded/do-not-fire. cx/risk/eff 3/2/2 (provisional, now moot). → [GH-272-TICK-REPO-ROOT-VENDORED-MISMATCH.md](PROJECT/2-WORKING/GH-272-TICK-REPO-ROOT-VENDORED-MISMATCH.md) · [#272](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/272) · [#297](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/297)
- **GH-284 · marathon closeout → release-driven selection (6 phases; P1-P4 ✅ SHIPPED, P4 2026-07-29)** 🟡 **captured 2026-07-23 (/10days sweep)** — **P1** closeout PR (`--open-only` + `--closeout-pr`), PR [#316](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/316). **P2** file-based driver liveness + opt-in idempotent GitHub run log, PR [#317](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/317) — its marathon surfaced [#319](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/319) (every phase gate was fake) and [#320](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/320), and its merge surfaced [#322](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/322) (`--log-github` silently swallowed by the Python lane, so P2's feature was inert by default). **#322 closed 2026-07-29 and P2 is now effective**: PR [#324](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/324) stopped the silence, then the port landed BOTH Phase 2 halves in `utils/py/marathon_drive.py` — the run log *and* the driver heartbeat, which #322 had believed was already there (its "12 references" were `xyz_marathon_heartbeat_*`, the unrelated GH-75 session record; `grep -c driver_heartbeat` on the Python twin was 0). `test/gh322-runlog-python-lane.sh` 5/19 pre-fix → 26/0. **P3** the release→issue-set join key: `RELEASES.md` gains `Milestone:` (a GitHub milestone title, not a URL and not an issue list), the `pdda.sh releases` check warns when a dated unshipped release lacks one, `releases-current` surfaces it, and GitHub milestone **Quicksilver** was created with #308 assigned. `test/gh284-p3-release-milestone.sh` is the **first test the releases check has ever had** (10 pass/5 fail pre-fix, 15/0 after). **P4** SHIPPED 2026-07-29 — `utils/release-lanes.sh` closes the loop in both directions: `seed` turns a release's `Milestone:` into a marathon candidate list in the same JSON shape `skills/10days/scan-issues.sh` emits, and `rollup` reports `N/M landed` from git ancestry. GitHub's own PR↔issue linkage turned out to be **empty on every issue in this repo**, so "landed" is evidenced by a commit whose CONVENTIONAL SCOPE claims the issue (`type(GH-N):` / leading `GH-N`); a bare `#N` is the squash-merge PR number and is rejected. Reports `landed`/`mentioned`/`absent`, because the matcher under-reports (a fix inside a marathon commit claims no issue) and a silent binary would call that a clean "not done". `test/gh284-p4-release-lanes.sh` 33/0, mutation-tested. **P5-P6 scoped, not contracted.** Original capture: — after a marathon run completes successfully, open a non-merging PR (opt-in `--closeout-pr` flag) carrying deterministic notes built from the plan name/phase count/tick events, reusing `marathon-closeout.sh`'s existing PR-creation code behind a new `--open-only` flag. Fully spec'd by the issue itself (exact seam, acceptance criteria, explicit non-goals: no merge, no force-push, no branch creation). cx/risk/eff 2/2/2 (provisional). → [GH-284-MARATHON-CLOSEOUT-PR.md](PROJECT/2-WORKING/GH-284-MARATHON-CLOSEOUT-PR.md) · [#284](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/284)
- **GH-153 · Cost observability: Codex per-turn token capture (parseCodexStats)** 🆕 **captured 2026-07-23 (/10days sweep)** — was gated on #151 (Phase 4 discovery spike), now CLOSED; its recorded finding says the Codex capture gate check passes and `parseCodexStats` can mirror the existing `parseGeminiStats` almost exactly. Confirmed unimplemented in `src/cost.js`; `codex-turn.sh` needs `--json` wired into its `codex exec` invocation. Full spec already written in `PROJECT/1-INBOX/COST-OBSERVABILITY-PLAN.md` Phase 7. cx/risk/eff 2/1/2 (provisional). → [GH-153-CODEX-TOKEN-CAPTURE.md](PROJECT/2-WORKING/GH-153-CODEX-TOKEN-CAPTURE.md) · [#153](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/153)
- **GH-268 · Beta onboarding & build-quality test report — remediation plan (re: #123)** 🔄 **Phases 1–2 done 2026-07-28; Phases 3–4 open** — Phase 1 closed: skill installers shipped via PR #282, and the clean-clone Quickstart was **verified green** (fresh clone of `development`, 133/133, exit 0) rather than needing a fix — only its "~1 minute" claim was wrong (~8 min measured). Phase 2 closed: README reordered to lead with what-it-is + Quickstart, CLI prerequisites lifted above the fast path with real install URLs, `relay-automation/README.md` retitled "Set up Codex, agy, and Pi" with an install/auth table, sandbox-hang callout added — plus **two dead prerequisite anchors** the report never saw (`a595c6f` renamed the target heading on 2026-07-23). Still open: **Phase 3** (relay handoff cues; the review loop checks the diff not the file it lands in) and **Phase 4** (cross-model re-test). Original findings: beta tester (Matthew Taylor) found 2 blocking onboarding issues (Quickstart fails on a clean clone; a named skill has no installer), 4 fix-before-broader-beta README/sandbox items, 2 follow-up process gaps (manual relay handoff; the review loop checks the diff not the file it lands in — an independent audit found 20 issues incl. 1 critical in code a relay approved), and 1 untested item (cross-model Codex/agy lane never ran — blocked on #232, now closed). Single plan doc, 4 phases, no per-finding issue split per operator instruction. cx/risk/eff 4/3/5 (provisional). → [GH-268-BETA-ONBOARDING-BUILD-QUALITY-REMEDIATION.md](PROJECT/3-COMPLETED/GH-268-BETA-ONBOARDING-BUILD-QUALITY-REMEDIATION.md) · [#268](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/268)
- **GH-261 · marathon-drive: reconcile the Bash/Python disjoint-failure union (last Phase-1 gate for the XYZ_PYTHON flip)** ✅ **SHIPPED — closed 2026-07-22 (PR #271, merge 2a2da17)** — split out of #255; Python side already DONE (112/0 under XYZ_PYTHON=1, PR #262). Bash side (`test/marathon-drive.sh` exit 6 where 4/0 expected) fixed via direct RTL_TRACE instrumentation, not the issue's original hypothesis: real causes were (1) a bidirectional physical/logical symlink-form mismatch between `RTL_ROOT` and an absolute `RTL_ALLOW` entry, and (2) `rtl_check()` missing the collapsed-directory transcript-log exemption GH-266 already gave `rtl_worktree_end`. The issue's own "inherited TICK_REPO_ROOT" hypothesis was tested directly and confirmed real but NOT the actual gating cause. `test/marathon-drive.sh` 112/112 under both runtimes, confirmed on a real ubuntu:latest container. cx/risk/eff 4/5/3. → [GH-261-MARATHON-DRIVE-BASH-CONTAINMENT-VENDORED-CHAIN.md](PROJECT/3-COMPLETED/GH-261-MARATHON-DRIVE-BASH-CONTAINMENT-VENDORED-CHAIN.md) · [#261](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/261)
- **GH-266 · rtl_worktree_end doesn't exempt relay-system/ (its own transcript dir) — false containment violation discards a fully in-scope turn** ✅ **SHIPPED — closed 2026-07-22 (PR #271, merge 2a2da17)** — the worktree-isolation containment path (`rtl_worktree_end`) had no exemption for the harness's own `relay-system/` transcript directory, unlike `.tick/` (explicitly exempted) and unlike the non-worktree `rtl_check()` path (exempts `$RTL_LOG_REL` directly). A fully in-scope Codex build turn was discarded every time the isolated worktree's own transcript log landed under `relay-system/`. Adjacent to #30 (XYZ_ARCHIVE_ROOT redirect — complementary, not a substitute) and #160 (closed, different false-positive mechanism). Shared an edit surface with #261 (`relay-turn-lib.sh`) — fixed together. cx/risk/eff 2/4/2. → [GH-266-WORKTREE-RELAYSYSTEM-CONTAINMENT.md](PROJECT/3-COMPLETED/GH-266-WORKTREE-RELAYSYSTEM-CONTAINMENT.md) · [#266](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/266)
- **GH-263 · codex-turn.sh isolation=0 path can't reach the parent-root .tick lock in vendored installs** ✅ **SHIPPED — closed 2026-07-22 (PR #271, merge 2a2da17)** — the GH-36 `--add-dir "$TICK_REPO_ROOT/.tick"` fix was only in the `RELAY_WORKTREE_ISOLATION=1` branch of `codex-turn.sh`; the `isolation=0` opt-out assumed Codex CWD == ROOT, but a vendored run driven from `cd $HARNESS` (= `.xyz`) sandboxed Codex to `.xyz` → `EPERM` on the token claim before the turn started. Follow-up to #36; adjacent to [[GH-234]]. cx/risk/eff 2/3/2. → [GH-263-CODEX-ISOLATION0-TICK-EPERM.md](PROJECT/3-COMPLETED/GH-263-CODEX-ISOLATION0-TICK-EPERM.md) · [#263](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/263)
- **GH-258 · vendor-stack skill — one-step XYZ harness + PDDA governance install into a target repo** ✅ **SHIPPED — closed 2026-07-21** (commit `cb01fae`, merged PR #259) — new `skills/vendor-stack/` orchestrates the two independent installers: vendors XYZ into `<target>/.xyz/` (`xyz-vendor.sh`), then optionally installs PDDA (pdda `install.sh`, observe mode) via a device-agnostic `find-pdda.sh` resolver. Prompt + resolver live at the skill layer, not baked into `xyz-vendor.sh` (which ships in every vendored `.xyz/` and must stay non-interactive). Each tool keeps its own upgrade registry. Files on disk + smoke-tested; symlink `install.sh` not yet run. cx/risk/eff 2/1/2. → [GH-258-VENDOR-STACK-SKILL.md](PROJECT/3-COMPLETED/GH-258-VENDOR-STACK-SKILL.md) · [#258](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/258)
- **GH-251 · OpenRouter/aider reviewer seam doesn't persist its review (builder-only in practice)** ✅ **SHIPPED — closed 2026-07-21** (commit `cf7a123`, merged PR #256; NOTE: live-OpenRouter-model verification remains an outstanding operator step, not claimed done) — found during a live multi-turn `/relay-xyz` GLM 5.2 QA of the 2026-07-19 marathon: aider produces a correct review in-transcript but its relay-file append is lost through repomap-wandering + worktree containment, so `--review-once` correctly scores it a stall (a live confirmation of GH-245, not a classifier bug). Fix: a review-mode / transcript-salvage for `aider-turn.sh`, or document builder-only and route reviews to codex/agy. cx/risk/eff 2/2/2. → [GH-251-OPENROUTER-AIDER-REVIEWER-SEAM.md](PROJECT/3-COMPLETED/GH-251-OPENROUTER-AIDER-REVIEWER-SEAM.md) · [#251](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/251)
- **GH-199 · swe-diagram: add a font picker to the generated diagram HTML (default + Indie Flower)** ✅ **SHIPPED — closed 2026-07-21** (commit `1e08154`) — no font picker exists in the generated diagram HTML today (0 matches for `Indie Flower` in `utils/swe-diagram/assets/template.html`); an orphaned branch `origin/gh-199-swe-diagram-font-picker` (`322ecbe`, agy-reviewed) already implements it but was never merged — operator may prefer merging that over a rebuild. cx/risk/eff 1/1/2. → [GH-199-SWE-DIAGRAM-FONT-PICKER.md](PROJECT/3-COMPLETED/GH-199-SWE-DIAGRAM-FONT-PICKER.md) · [#199](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/199)
- **GH-232 · validate.sh: ~12 tests fail on ubuntu-latest CI runner (environment incompatibilities, first exposed by GH-230's CI step)** ✅ **SHIPPED — closed 2026-07-22 (PR #271, merge 2a2da17)** — re-diagnosed against a real ubuntu:latest container across 4 rounds: portable `sed -i` (3b59d75), `hq_sanitize`'s GNU `tr` range-ambiguity corruption (899302a), missing `CODEX_BIN`/`--builder` pins + shallow-clone `fetch-depth` (0abb6aa), macOS AppleDouble tar junk in `make-pkg.sh` (70640ca). Confirmed green on real CI (run 29865944751, `tier1` SUCCESS). cx/risk/eff 3/2/3. → [GH-232-VALIDATE-UBUNTU-CI-FAILURES.md](PROJECT/3-COMPLETED/GH-232-VALIDATE-UBUNTU-CI-FAILURES.md) · [#232](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/232)
- **GH-234 · find-harness.sh --env exports TICK_REPO_ROOT one directory too deep (found during GH-177 wipe investigation, never filed)** ✅ **SHIPPED — closed 2026-07-21** (commit `125f184`, merged PR #252) — `find-harness.sh:178` exports `TICK_REPO_ROOT` as the vendored `.xyz` harness path instead of the actual repo root that `bin/tick` and tick-consuming shims expect (confirmed present today). cx/risk/eff 2/2/2. → [GH-234-FIND-HARNESS-TICK-ROOT-TOO-DEEP.md](PROJECT/3-COMPLETED/GH-234-FIND-HARNESS-TICK-ROOT-TOO-DEEP.md) · [#234](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/234)
- **GH-236 · Worktree isolation under $TMPDIR breaks codex turns in /tmp-rooted environments (and escalates as a false timeout)** ✅ **SHIPPED — closed 2026-07-21** (commit `36d9e62`, merged PR #252) — `relay-turn-lib.sh`'s isolation worktree is created under `${TMPDIR:-/tmp}/rtl-wt.XXXXXX`, which breaks codex turns in /tmp-rooted environments and surfaces as a false timeout instead of the real cause. cx/risk/eff 2/3/2. → [GH-236-WORKTREE-TMPDIR-CODEX-BREAK.md](PROJECT/3-COMPLETED/GH-236-WORKTREE-TMPDIR-CODEX-BREAK.md) · [#236](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/236)
- **GH-242 · agy S10: off-prompt-nonempty repro — deferred from #155, needs a controlled trigger** ✅ **SHIPPED — closed 2026-07-21** (commit `9c052f4`) — agy's off-prompt-nonempty (S10) condition, split out of #155, has no controlled repro and no regression coverage in `test/agy-turn.sh`; spike/discovery item, may come back marathon-unready from preflight. cx/risk/eff 2/3/3. → [GH-242-AGY-S10-OFFPROMPT-REPRO.md](PROJECT/3-COMPLETED/GH-242-AGY-S10-OFFPROMPT-REPRO.md) · [#242](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/242)
- **GH-247 · marathon-triage: bare utils/ paths break in vendored .xyz/ installs** ✅ **SHIPPED — closed 2026-07-21** (commit `95c3e12`, merged PR #252) — `skills/marathon-triage/SKILL.md` hardcodes bare `utils/swarm-preflight.sh`/`utils/marathon-plan.sh` paths that don't resolve in a vendored `.xyz/` install; fix resolves `utils/` relative to the harness root. Shares an edit surface with #250 — serialize, do not run concurrently. cx/risk/eff 1/1/1. → [GH-247-MARATHON-TRIAGE-VENDORED-PATHS.md](PROJECT/3-COMPLETED/GH-247-MARATHON-TRIAGE-VENDORED-PATHS.md) · [#247](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/247)
- **GH-249 · Marathon gate enforces 'existing tests pass', not new-test presence — brief acceptance criteria are advisory prose** ✅ **SHIPPED — closed 2026-07-21** (commit `c1b3b6d`; Python port commit `4418122`) — `relay-automation/marathon-drive.sh`'s pre-advance gate only checks existing tests pass, never that a lane added a test for its fix; add an optional `requires_test` contract field + test-delta check. cx/risk/eff 3/3/3. → [GH-249-MARATHON-GATE-NEW-TEST-PRESENCE.md](PROJECT/3-COMPLETED/GH-249-MARATHON-GATE-NEW-TEST-PRESENCE.md) · [#249](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/249)
- **GH-250 · marathon-triage: emit a default recommendation per item, not symmetric options** ✅ **SHIPPED — closed 2026-07-21** (commit `9bf1b56`) — `skills/marathon-triage/SKILL.md`'s report step lists symmetric options with no default call; add a `RECOMMEND:`/`BECAUSE:`/`UNLESS:` framing per item. Shares an edit surface with #247 — serialize, do not run concurrently. cx/risk/eff 1/1/2. → [GH-250-MARATHON-TRIAGE-DEFAULT-RECOMMENDATION.md](PROJECT/3-COMPLETED/GH-250-MARATHON-TRIAGE-DEFAULT-RECOMMENDATION.md) · [#250](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/250)
- **GH-245 · `--target-root` review turn cannot report, and `relay-drive` misclassifies the outcome both ways** ✅ **SHIPPED — closed 2026-07-21** (commit `3783665`, merged PR #246) — a cross-repo review turn is structurally unable to produce a review: `--target-root` bases the worktree on the *target* repo while `--relay-file` resolves against the *harness* repo, so with the documented review-turn setting `ALLOW_PATHS=""` the only writable path isn't in the worktree. Codex finished the review (~88k tokens), hit `patch rejected: writing outside of the project`, released the token cleanly and lost everything but a one-sentence transcript summary — on the path SKILL.md presents as the normal case. The amplifier is defect 2: `--review-once` classifies on **token state alone**, so within one hour it scored an empty turn as a successful review (exit 5; `## Log` empty, `NEXT:` unflipped, shim had already printed "no tracked changes") and a complete 6-finding review as a `genuine stall` (exit 3; file written, `NEXT:` flipped, token merely left claimed). Both times the distinguishing evidence was present and unused. Same family as [#236](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/236). Not blocking — workaround is `xyz-vendor.sh <target-repo>` then drop `--target-root`. **Promoted to `2-WORKING` 2026-07-19 via /10days sweep with an auto-drafted contract.** cx/risk/eff 2/4/2. → [GH-245-TARGET-ROOT-REVIEW-UNWRITABLE.md](PROJECT/3-COMPLETED/GH-245-TARGET-ROOT-REVIEW-UNWRITABLE.md) · [#245](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/245)
- **GH-241 · `MARATHON.example.yaml` understates sequencing and `depends_on`'s scalar-only shape** ✅ **SHIPPED — closed 2026-07-21** (commits `353d4c0`/`500dd87`, merged PR #256) — the only worked example a plan author has leaves two things unstated that together produce a plan which parses cleanly, reads correctly, and aborts on first run. (1) Nothing in the example says phases run **one at a time** and halt on first failure — and since every phase in it except `p1` carries a `depends_on`, the natural inference is that phases *without* one run concurrently. A real 4-phase plan shipped with a header claiming "3 lanes, then 1" on the back of a sound disjoint-write-set analysis; the write-set work was load-bearing, the concurrency conclusion was fiction. (2) `depends_on: [phase-id]` parses as the **literal string** and fails at `bin/marathon-yaml:102` as an unknown-phase lookup, pointing the author at their phase ids rather than the field's shape. Both caught by `--dry-run` at zero cost, which is also the fix's fourth option: recommend it in the example header. cx/risk/eff 1/2/1. → [GH-241-MARATHON-EXAMPLE-SEQUENCING.md](PROJECT/3-COMPLETED/GH-241-MARATHON-EXAMPLE-SEQUENCING.md) · [#241](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/241)
- **GH-238 · marathon-drive: pre-advance gate defaults to `bash validate.sh` — halts AFTER approval in any consuming repo without it** ✅ **SHIPPED — closed 2026-07-21** (commit `d999c36`, merged PR #243; Python port commit `b180ace`) — external field report from a vendored `.xyz/` consumer (`Hypercart-Dev-Tools/rebalance-OS`), all claims verified against source: `marathon-drive.sh:376` defaults the gate to `bash $ROOT/validate.sh` and never existence-checks it, and `:751` runs it only *after* `relay approved` — so a consumer without `validate.sh` pays a full builder turn **plus** a full reviewer turn before exit 5. Wider than filed: the gate is also probed on the exit-7 timeout (`:662`) and exit-3 stall (`:779`) recovery paths, so those degrade too. `MARATHON.example.yaml` never mentions the gate at all. Fix: fail fast at plan load (resolve + probe before turn 1) and document the default in the example; explicitly **not** silently skipping the gate, and **not** a mode-dependent default. Distinct from #170/#232 (those are `validate.sh`'s own tests failing here). cx/risk/eff 2/2/2. → [GH-238-MARATHON-PREADVANCE-GATE-DEFAULT.md](PROJECT/3-COMPLETED/GH-238-MARATHON-PREADVANCE-GATE-DEFAULT.md) · [#238](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/238)
- **GH-239 · swarm-preflight: no contract example ships — consumers hit exit 3 with nothing to copy, so the gate gets bypassed** ✅ **SHIPPED — closed 2026-07-21** (merged PR #243) — same reporter, same day, same root cause (defaults/onboarding assume the consumer looks like this repo). The contract schema lives **only** in `utils/swarm-preflight.sh:24-36`'s header comment; `MARATHON.example.yaml` is the sole shipped worked example and has no contract equivalent. Worse than filed: a dozen-plus real filled-in contracts exist in `PROJECT/**/GH-*.md`, but `PROJECT/**` isn't part of a vendored `.xyz/` install — every working example is structurally invisible to the audience that needs one. Consequence is behavioural, not cosmetic: consumers skip `swarm-preflight.sh` and hand-author `MARATHON.yaml` because *that* format has an on-ramp, so the freshness/fix-required/collision gates get routinely bypassed. Fix: ship `relay-automation/CONTRACT.example.md` (per-field annotated, `fix_probes` polarity called out explicitly — inverting it yields a STALE exit-4 *false completion* signal) + print the minimal skeleton on exit 3. Deferring `--emit-contract-skeleton`. cx/risk/eff 1/1/2. → [GH-239-PREFLIGHT-CONTRACT-EXAMPLE.md](PROJECT/3-COMPLETED/GH-239-PREFLIGHT-CONTRACT-EXAMPLE.md) · [#239](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/239)
- **PDDA sweep 2026-07-18 · 4 shipped docs swept to `3-COMPLETED`, 6 stale marathon status words corrected** 🆕 **2026-07-18, branch `docsweep/2026-07-18`** — GH-151/152/155/230 were sitting in `2-WORKING` with terminal status in their own frontmatter and `CLOSED/COMPLETED` issues; moved to `3-COMPLETED`. Six marathon plans filed under `3-COMPLETED`/`4-MISC` still read `status: Active (2-WORKING)` (`07-01/02/03/05/06`, `4-MISC/07-07`); corrected. Both classes are instances of the #224 drift backlog, found by a manual marathon-file audit rather than by the #189 checks. Caveat carried forward: GH-155's own doc says sub-item **S10 stays open** despite the issue being closed. → [GH-224-PDDA-DRIFT-BACKLOG-RECONCILE.md](PROJECT/3-COMPLETED/GH-224-PDDA-DRIFT-BACKLOG-RECONCILE.md) · [#224](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/224)
- **GH-235 · Consult A4 provenance v0: prompt-trace classifier for cited claims (FIRSTHAND vs ECHOED)** ✅ **SHIPPED — closed 2026-07-21** (Bash commits `1e87a1f`/`e1a7b61`; Python port commit `19830e4`) — closes the shipped A4 slice's blind spot (a prompt-echoed citation looks identical to a firsthand one). A parallel Codex+agy consult (`relay-system/2026-07-17/a4-scope-181325/`) converged independently on **v0** (2-category: FIRSTHAND vs ECHOED on already-cited claims) over the 4-category taxonomy, both citing Principle 7 + the reuse tie-breaker. v0: persist `PROMPT_TEXT`, sibling predicate to `rtl_has_uncited_claim()`, per-advisor `PROVENANCE.txt` sidecar, existing `NO FIRSTHAND` stamp unchanged. Defers INFERENCE/UNSUPPORTED split + reconciliation backstop. Coordinates with #226. cx/risk/eff 2/2/2. → [GH-235-CONSULT-A4-PROVENANCE-V0.md](PROJECT/3-COMPLETED/GH-235-CONSULT-A4-PROVENANCE-V0.md) · [#235](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/235)
- **GH-230 · Front-door onboarding drift: undocumented npm install + package.json drift** ✅ **SHIPPED 2026-07-17; closed** — read-only `/front-door` audit found a genuinely fresh clone following README's own Quickstart verbatim hits `Cannot find module 'acorn'` (real `package.json` deps, gitignored `node_modules/`, no doc mentions `npm install`, and CI's `tier1` job never runs `./validate.sh` so the gap is invisible to CI). Also cleaned up: `package.json`'s stale `"name": "lane-169"`, garbled beta-banner `"description"`, and a deliberately-failing `npm test` stub. No leaked secrets found. cx/risk/eff 1/1/2. → [GH-230-FRONT-DOOR-ONBOARDING-DRIFT.md](PROJECT/3-COMPLETED/GH-230-FRONT-DOOR-ONBOARDING-DRIFT.md) · [#230](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/230)
- **GH-177 · mktemp-into-destructive-EXIT-trap recurrence — `test/hq-hardening.sh` (+2 siblings) rm -rf'd the entire repo a 2nd time** ✅ **SHIPPED 2026-07-17** (`e7fd117`) — closed 2026-07-08 without the code fix ever landing; the unguarded `TMP="$(cd "$(mktemp -d)" && pwd -P)"; trap 'rm -rf "$TMP"' EXIT` idiom was still live in `test/hq-hardening.sh`/`hq-promote.sh`/`hq-locator.sh` and fired again when `validate.sh` ran under a sandboxed shell (`mktemp -d` fails silently, `cd ""` succeeds and stays at cwd = repo root, the EXIT trap deletes it). Recovered clean via `git init` + `fetch` + `read-tree`/`checkout-index` from `origin/development` (no upstream loss) + a Time Machine assist for the working tree. Fixed all 3 files with the guard the original issue already specified, plus a new static-audit regression test (`test/mktemp-trap-guard.sh`) wired into `validate.sh`, verified (via disposable scratch files) to fail on the historical pattern and pass clean (191 files, 0 findings) post-fix. cx/risk/eff 1/3/1. → [GH-177-MKTEMP-TRAP-REPO-WIPE.md](PROJECT/3-COMPLETED/GH-177-MKTEMP-TRAP-REPO-WIPE.md) · [#177](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/177)
- **GH-226 · Full provenance follow-up should coordinate with the already-reworked consult/relay summary surface** ✅ **SHIPPED (coordination/decision scope only) — closed 2026-07-21** (merged PR #257; the two-lane implementation itself is a SEPARATE, still-held effort — see PROJECT/2-WORKING/MARATHON-PLAN-2026-07-20-M-GH226-PROVENANCE-IMPL.md, Plan M) — Jedi Wright flagged a real coordination gap in Slack: GH-211 already changed the operator-facing TLDR/category layer, GH-178 intentionally shipped only a narrow provenance slice, and a future "full provenance" pass will likely rework the same human-facing surface twice unless the two are designed together. Ask: inventory the operator-facing summary surfaces GH-211 touched and the provenance surfaces GH-178 touched, then decide whether the next pass stays one coordinated issue or splits by repo/surface. cx/risk/eff 2/2/2. → [GH-226-PROVENANCE-SUMMARY-SURFACE-COORDINATION.md](PROJECT/3-COMPLETED/GH-226-PROVENANCE-SUMMARY-SURFACE-COORDINATION.md) · [#226](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/226)
- **GH-225 · 10days/marathon guardrail: `isolation:"worktree"` lanes can branch from a stale historical commit, not the marathon branch** ✅ **SHIPPED — closed 2026-07-21** (commit `cf608da`, merged PR #227) — found live during the GH-174/215/222/189 marathon fire the same day: all 4 parallel lanes' isolation worktrees branched from stale historical commits (e.g. `788a5c6`, `e8acdc5`), not the marathon branch named as `target.ref`; caught only by manually checking `git log` before merging, and recovered via cherry-pick instead of a full merge (which would have silently reintroduced superseded history). Fix: doc-only guardrail in `skills/10days/SKILL.md` Step 7 — verify each lane's worktree base against the marathon branch start commit before merging, cherry-pick instead of merge when it fails. cx/risk/eff 1/2/1. → [GH-225-ISOLATION-WORKTREE-STALE-BASE-GUARDRAIL.md](PROJECT/3-COMPLETED/GH-225-ISOLATION-WORKTREE-STALE-BASE-GUARDRAIL.md) · [#225](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/225)
- **GH-224 · PDDA drift backlog: 45 stale 3-COMPLETED status words + 15 ROADMAP/issue-state mismatches** ✅ **SHIPPED — closed 2026-07-21** (commit `19468be`) — GH-189's two new checks (`pdda-check-roadmap-issue-state`, 3-COMPLETED scan) surfaced real, reproducible drift when run against this repo's own docs/ROADMAP on the then-unmerged `marathon/gh174-215-222-189-2026-07-17`: 15 ROADMAP ledger entries reading ✅/SHIPPED against a still-OPEN issue (or vice versa) and 45 `3-COMPLETED` docs with non-terminal frontmatter status. Doc-only reconciliation, no safe bulk regex — per-item eyeball against real `gh issue view` state. cx/risk/eff 2/1/3. → [GH-224-PDDA-DRIFT-BACKLOG-RECONCILE.md](PROJECT/3-COMPLETED/GH-224-PDDA-DRIFT-BACKLOG-RECONCILE.md) · [#224](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/224)
- **GH-223 · utils/py/consult.py missing GH-178 A4 citation-stamp parity** ✅ **SHIPPED — closed 2026-07-21** (commit `54972e9`, merged PR #228) — unmasked while fixing GH-215 (consult.py SINGLE-MODEL stamping): `XYZ_PYTHON=1 bash test/consult.sh` gets past test 3 now but fails at test 12 — `consult.py` never got `relay-automation/consult.sh:310-336`'s "NO FIRSTHAND VERIFICATION CITED" stamping. Direct port, no design work; existing test 12 already exercises it. cx/risk/eff 2/1/2. → [GH-223-CONSULT-PY-CITATION-STAMP-PARITY.md](PROJECT/3-COMPLETED/GH-223-CONSULT-PY-CITATION-STAMP-PARITY.md) · [#223](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/223)
- **GH-222 · Marathon end-of-session hygiene: no cost summary in `marathon-drive.sh`, no worktree cleanup in `/10days`** ✅ **SHIPPED 2026-07-17 via a marathon lane (worktree-isolated Sonnet subagent)** — added `xyz_marathon_cost_summary()` to `marathon-drive.sh`, mirroring `relay-drive.sh`'s GH-152 pattern verbatim, EXIT-trap wired; `skills/10days/SKILL.md` Step 7 now removes each lane's worktree after merge, Step 8 reports cleanup failures. `bash validate.sh` 113/114 (only pre-existing `acorn-extract.sh`). cx/risk/eff 2/1/2. → [GH-222-MARATHON-SESSION-HYGIENE.md](PROJECT/3-COMPLETED/GH-222-MARATHON-SESSION-HYGIENE.md) · [#222](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/222)
- **GH-189 · PDDA: sweeping a doc to 3-COMPLETED silences the only issue-state check watching it** ✅ **SHIPPED 2026-07-17 via a marathon lane (worktree-isolated Sonnet subagent)** — added `check_roadmap_issue_state()` (ROADMAP entry vs. issue state, both directions) + extended `check_issue_doc_sync()` to also scan `3-COMPLETED` via a new `pdda_list_completed_docs()` helper, both warn-only/offline-degrading. 7 new `test/pdda-roadmap-coverage.sh` assertions (10/10 pass). Run against this repo's own real docs: genuinely found 48 stale `3-COMPLETED` status words and 15 real ROADMAP/issue-state mismatches — not false positives (spot-checked #211: ledger says SHIPPED, issue still OPEN). `bash validate.sh` 113/114 (only pre-existing environmental reds). cx/risk/eff 2/2/2. → [GH-189-PDDA-COMPLETED-STATE-BLINDSPOT.md](PROJECT/3-COMPLETED/GH-189-PDDA-COMPLETED-STATE-BLINDSPOT.md) · [#189](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/189)
- **GH-198 Bug 1 · `rtl_enforce`'s file-scoped commit had no pathspec (pre-existing staged content could ride into a relay commit)** ✅ **built 2026-07-16** — `relay-turn-lib.sh`'s commit step staged each allowlisted path independently but committed with no pathspec, so pre-existing staged content silently rode along (reproduced live 2026-07-10/11). Fixed by scoping the commit to the allowlist, cross-checked against what's actually staged (a naive scope reintroduced the GH-29 batched-pathspec-abort bug, caught by `test/relay-target-root-newfile.sh` regressing during the fix). Kernel path (`relay-turn-lib.sh`) — implemented directly, not via the marathon below. New `test/relay-commit-pathspec.sh` (9/9). GH-198 Bug 2 (uncommitted-artifact review UX gap) remains open. → [#198](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/198)
- **GH-213/209/203 · 3-lane marathon, all Approved** ✅ **built 2026-07-16, `validate.sh` green (only pre-existing #208 red)** — all three non-kernel bugs from the last-7-days issue sweep. **GH-213**: `find-harness.sh --check` gains a case-collision detector (`test/find-harness.sh` 20/20). **GH-209**: scope narrowed from the issue's full architectural ask (risks breaking GH-206's zero-config goal) to a static audit (`test/marathon-root-audit.sh` 13/13, new) — the builder turn found and fixed the actual leak: `MARATHON_LANE_NS` bleeding from a live `marathon-drive.sh` process into a nested `test/marathon.sh` run, which had caused a gate false-negative earlier in this same marathon. **GH-203**: scope narrowed to a non-destructive `swarm-preflight.sh` stale-`.git/index.lock` warning (`test/swarm-preflight.sh` 94/94, +7). One more recovery: agy's gh209 review tripped the known, already-tracked GH-183 isolation-breach false positive; content independently re-verified and committed by hand. → [GH-213-CASE-COLLISION-LANDMINE.md](PROJECT/3-COMPLETED/GH-213-CASE-COLLISION-LANDMINE.md) · [GH-209-MARATHON-ROOT-LEAK-AUDIT.md](PROJECT/3-COMPLETED/GH-209-MARATHON-ROOT-LEAK-AUDIT.md) · [GH-203-STALE-INDEX-LOCK-PREFLIGHT.md](PROJECT/3-COMPLETED/GH-203-STALE-INDEX-LOCK-PREFLIGHT.md) · [#213](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/213) · [#209](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/209) · [#203](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/203)
- **GH-212 · Make marathon builder-default (no billed CLI) and plan-location (PROJECT/2-WORKING) explicit, enforced defaults** ✅ **built 2026-07-15, `validate.sh` green (only pre-existing #208 red) — PR pending** — `marathon.sh`/`marathon-drive.sh` hardcode `BUILDER="claude"` (a billed headless CLI subprocess), disagreeing with `swarm-preflight.sh`'s own suggested `--builder codex`; separately, `marathon-plans` appears 0 times in any vendored doc so agents pattern-match a downstream repo's stray top-level plan folder instead of `PROJECT/2-WORKING/`. Operator chose the simple default-swap (`BUILDER` → `codex`, `--builder claude` becomes a documented billed opt-in) over a new `--builder self` control-flow mode. Ask: default swap in both scripts + the `XYZ_PYTHON=1` port, a `marathon.sh --plan` guard that refuses a plan outside `PROJECT/2-WORKING/` (exempt: harness-owned examples, or `MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1`), both conventions documented in `GUIDING-PRINCIPLES.md`. cx/risk/eff 3/2/4. → [GH-212-MARATHON-BUILDER-PLAN-DEFAULTS.md](PROJECT/3-COMPLETED/GH-212-MARATHON-BUILDER-PLAN-DEFAULTS.md) · [#212](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/212)
- **GH-211 · Consult and Relay — compact TLDR + sorted-category output** ✅ **built 2026-07-15** — `relay`'s and `consult`'s chat-facing reports (not the relay log file or consult transcripts) now open with a 1–2 sentence TLDR and, for non-trivial findings, close with a sorted category list: relay reuses its own `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]` grades (new "Reporting to the human" section, `giant-brains-claude-skills` `eb9271b`, committed not pushed — operator's call, that repo is shared across every project symlinking it), consult adds a Blocking/Worth-doing-optional/Skip triage under its existing disagree-first synthesis (`skills/consult/SKILL.md`, this repo). Verdict semantics, disagree-first ordering, and the log/transcript file formats are unchanged — this only reshapes the chat reply. cx/risk/eff 1/1/2. → [GH-211-CONSULT-RELAY-TLDR-SUMMARIES.md](PROJECT/1-INBOX/GH-211-CONSULT-RELAY-TLDR-SUMMARIES.md) · [#211](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/211)
- **GH-207 · Marathon retry/resume brittle against pre-existing lane state (cross-marathon lane-id collision + no-progress HALT on a done lane)** ✅ **built 2026-07-15 on `marathon/gh-205-turn-timeout-false-halt-2026-07-15` (agy Approved, gate 162 green) — PR pending** — `.tick/attempts/<lane>` + `phases/<id>/RELAY.md` are keyed by bare plan-local ids in a shared per-repo namespace, so a new marathon's `p1` inherits a 9-day-old stale attempt and PARKs at the cap before its builder runs; a lane whose artifact is already built + gate-green escalates `no-progress` (exit 3) with no way to advance the `depends_on` chain; plus spurious 0-line `dependency.drift` on harness-owned files. Ask: namespace lane state by marathon name, idempotent re-render commit, an already-satisfied lane path (green gate + reviewer approval → advance). cx/risk/eff 4/3/4. → [GH-207-MARATHON-RETRY-RESUME-BRITTLE.md](PROJECT/3-COMPLETED/GH-207-MARATHON-RETRY-RESUME-BRITTLE.md) · [#207](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/207)
- **GH-206 · Marathon: vendored .xyz/ conflates harness-home with repo-root — won't run without MARATHON_ROOT + bin overrides** ✅ **built 2026-07-15 on `marathon/gh-205-turn-timeout-false-halt-2026-07-15` (agy Approved, gate green) — PR pending; follow-up #209 open** — `marathon.sh:37-40` derives one `ROOT` used as both harness home (`bin/tick`, `bin/marathon-yaml`) and repo root (briefs, `TICK_REPO_ROOT`); in a vendored `.xyz/` those differ and no single value works — a plain invocation needs a 4-variable override set (reproduced in sleuth-app 2026-07-15). Ask: split into `MARATHON_HOME` (script-relative) + `MARATHON_ROOT` (`git rev-parse --show-toplevel`), each overridable, mirroring consult's `CONSULT_ROOT`. cx/risk/eff 3/3/3. → [GH-206-VENDORED-MARATHON-ROOT-SPLIT.md](PROJECT/3-COMPLETED/GH-206-VENDORED-MARATHON-ROOT-SPLIT.md) · [#206](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/206)
- **GH-205 · Marathon: 300s per-turn cap (RELAY_TURN_TIMEOUT_S) too short for real code+test builds → false HALT** ✅ **built 2026-07-15 on `marathon/gh-205-turn-timeout-false-halt-2026-07-15` (agy Approved, gate 144/144) — PR pending; the lane live-reproduced its own bug mid-run** — a builder turn that already wrote + committed its artifact with a green gate still gets killed at `codex-turn.sh:131`'s 300s default (exit 7) and HALTs the whole chain, shipping the artifact unreviewed (observed live, sleuth-app GH-367 marathon 2026-07-15). Ask: raise the default (600–900s), add per-lane `turn_timeout_s:` to MARATHON.yaml, treat exit-7-with-artifact-present+gate-green as complete-pending-review, document the env var (currently only a shim comment). cx/risk/eff 3/3/3. → [GH-205-TURN-TIMEOUT-FALSE-HALT.md](PROJECT/3-COMPLETED/GH-205-TURN-TIMEOUT-FALSE-HALT.md) · [#205](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/205)
- **GH-197 · Spike: two-axis (disclosure/steering) diagnostic tag pass on AGENTS.md** ✅ **Phase 0 complete 2026-07-10, Codex-reviewed and Approved after 3 rounds — verdict: predicted disclosure-heavy skew does not hold for AGENTS.md's 8 principles** — tagged all 8 current AGENTS.md Operating Principles (disclosure/steering/both); split is steering-heavy or balanced (6 steering-leaning vs. 4 disclosure-leaning), not disclosure-heavy as `AGENT-MD-PYDANTIC.md`'s Phase 0 predicted. Codex review ([relay](PROJECT/1-INBOX/GH-197-AGENTS-MD-TWO-AXIS-SPIKE.md), 3 rounds) caught and fixed two overreaches in the original write-up: the first draft claimed a strict file-level split (`ROUTER.md` = pure disclosure, `AGENTS.md` = pure steering), but `ROUTER.md` also carries steering-shaped verify gates and `AGENTS.md` opens with disclosure-shaped routing pointers — narrowed to "ROUTER leans disclosure, AGENTS leans steering," and "no further work needed"/repo-wide-sufficiency claims were retracted as unproven by a two-file read. One candidate missing-steering-rule flagged (a standing "stop and ask when ambiguous" rule lives only in system-level instructions, not in either repo-owned file) but not actioned. cx/risk/eff 1/1/1. → [GH-197-AGENTS-MD-TWO-AXIS-SPIKE.md](PROJECT/1-INBOX/GH-197-AGENTS-MD-TWO-AXIS-SPIKE.md) · [#197](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/197)
- **GH-191 · ATE: generalize harness runner beyond Aider (pluggable command/flags/classifier)** 🆕 **captured 2026-07-09, rated — not urgent, deferred backlog** — `utils/ate/`'s variation-test runner is described generically but hardcoded to Aider: `run_aider()`'s binary name and flags (`--edit-format`/`--map-tokens`/`--no-auto-commits`/etc.) are literal, `build_variations()`'s grid schema is Aider-specific (`edit_formats`/`map_tokens`/`auto_commits`), `CLASSIFY_PROMPT` names the Aider/OpenRouter/GLM-5.2 pipeline directly, and `install.sh` hard-requires the `aider` CLI on `PATH`. Ask: replace with a `variations.yaml`-declared command template (safe argv substitution, not a shell string), arbitrary grid keys, a parameterized classifier prompt, and a conditional install check — Aider stays the default/reference config, no regression. **Promoted to `2-WORKING` 2026-07-19 via /10days sweep with an auto-drafted contract.** cx/risk/eff 3/2/3. → [GH-191-ATE-GENERALIZE-HARNESS.md](PROJECT/2-WORKING/GH-191-ATE-GENERALIZE-HARNESS.md) · [#191](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/191)
- **GH-173 · Jedi Wright beta feedback: agy worktree grounding + reconciliation-layer hardening** **captured 2026-07-07, Phase 2 dogfood-mining pass 2026-07-07 night** — fast-path (Consult+Relay) beta trip report triaged into 4 verified bugs + 4 architecture gaps + 2 doc notes, all clustered on the epistemic/reconciliation layer. Phase 1 (#175) firing now via an Antigravity agent in an isolated worktree. Tonight's task: mined today's own Codex+agy consult + aider/GLM-5.2 relay transcripts (fresh field evidence, same category as Jedi's report) back into the Validation table — found **B2**'s exact warning-emission site + a live false-positive (`relay-drive.sh:226-240` vs. `relay-turn-lib.sh`'s seeding step), a live unstamped **A2** degrade (codex timeout, no mechanical marker), a live hedged-but-wrong advisor claim for **A4**, a **B1** non-repro (agy fine today — suggests intermittency), and **B3** partial counter-evidence (both advisors cited unprompted today). Likely splits into per-cluster `GH-*` issues on promotion; ratings provisional. cx/risk/eff 4/3/4. → [GH-173-JEDI-WRIGHT-FEEDBACK.md](PROJECT/2-WORKING/GH-173-JEDI-WRIGHT-FEEDBACK.md) · [#173](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/173)
- **GH-175 · #173 feedback Phase-1 low-fruit slice: bring-up + README supply-chain docs + Codex preflight attestation** ✅ **SHIPPED 2026-07-08 (PR #179, `39729a0`); closed 2026-07-08** — the contained, no-reporter-dependency slice of #173: **B4** headless bring-up doc notes (macOS Documents prompt, `agy -p` vs TTY), **D2** README supply-chain notes (symlinked skills, agy self-update), **A3** parse Codex's exec preamble (model/provider/sandbox) into the consult panel record — confirmed live in `README.md` + `relay-automation/consult.sh`. Additive/doc-only; disjoint write-set from #159/#168/#169. Parent [#173](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/173); design-heavy items stay parked there. cx/risk/eff 2/1/2. → [GH-173-JEDI-WRIGHT-FEEDBACK.md](PROJECT/2-WORKING/GH-173-JEDI-WRIGHT-FEEDBACK.md) · [Plan E](PROJECT/3-COMPLETED/MARATHON-PLAN-2026-07-07-E-BUILD.md) · [#175](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/175)
- **GH-178 · #173 feedback split: epistemic/reconciliation-layer hardening (agy grounding, stale warning, advisor pluggability, degraded-panel stamp, verdict provenance)** — updated 2026-07-08 — all 5 items now have a shipped fix: **B1** agy worktree grounding (isolation-breach transcript scan, PR #181; caveat #183), **B2** stale HEAD-visibility warning (PR #181), **A1** advisor pluggability (data-table dispatch, this pass), **A2** degraded-panel stamp (PR #181), **A4** verdict provenance (this pass — deliberately a scoped "no citation anywhere" slice, NOT the full firsthand-vs-asserted taxonomy, which stays future-scoped). Parent [#173](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/173). See the ad-hoc detour entry above for today's B3/A1/A4 PR. cx/risk/eff 4/3/5. → [GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md](PROJECT/2-WORKING/GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md) · [#178](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/178)
- **GH-172 · vendored harness root-semantics audit before Python-default cutover** ✅ **SHIPPED — 4-phase marathon merged 2026-07-17 ([PR #214](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/214), codex builder, agy reviewer, `validate.sh` green except pre-existing #208); #172 closed** — comprehensive Bash/Python audit of harness-install root vs coordination root vs target/work root in vendored `.xyz` runs. Found and fixed real gaps in `relay-automation/consult.sh` and `utils/py/consult.py` (stale tick-binary fallback) and `utils/py/relay_drive.py` (uncommitted-relay-file warning parity); every other scoped entry point verified clean. Cutover recommendation: safe to cut a stable Bash branch now; **not yet safe** to switch `main` to Python-default — `utils/py/consult.py` still lacks the Bash degraded-panel `SINGLE-MODEL — NOT RECONCILED` stamping, keeping `XYZ_PYTHON=1 bash test/consult.sh` red — filed as [#215](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/215), see its own entry below. cx/risk/eff 4/4/4. → [GH-172-VENDORED-ROOT-AUDIT.md](PROJECT/3-COMPLETED/GH-172-VENDORED-ROOT-AUDIT.md) · [GH-172-BASH-AUDIT-FINDINGS.md](PROJECT/3-COMPLETED/GH-172-BASH-AUDIT-FINDINGS.md) · [GH-172-PYTHON-AUDIT-FINDINGS.md](PROJECT/3-COMPLETED/GH-172-PYTHON-AUDIT-FINDINGS.md) · [GH-172-CUTOVER-RECOMMENDATION.md](PROJECT/3-COMPLETED/GH-172-CUTOVER-RECOMMENDATION.md) · [#172](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/172)
- **Marathon Plan F · validate.sh's pre-existing failing tests + parity gaps (GH-170, GH-174, GH-215, GH-208, GH-154)** 🟢 **updated 2026-07-17 — Lanes 12-13 SHIPPED (see their own entries below); Lanes 1-9 (#170) STALE; Lanes 10-11 still queued, not yet fired** — originally 9 lanes from `validate.sh` triage (`analyze.sh`, `cost.sh`, `watchdog-relay.sh`, `deep-research.sh`, `relay-token-collision.sh`, `new-relay.sh`, `find-harness.sh`, `transcript-audit.sh`, `marathon-plan.sh`) plus Lane 10 (#174). While building Swarm Preflight Contracts for this plan 2026-07-17: **all 9 Lane 1-9 tests now pass** (`swarm-preflight.sh --gh-issue 170` → STALE/exit 4; independently re-verified, incl. 5x repeats for the two flaky lanes; full `validate.sh` confirms only pre-existing `#208` red at that time) — root cause of the flip unconfirmed, #170 commented recommending closure, not closed unilaterally. **Lane 10** re-scoped to test-only: its code fix landed as a side effect of GH-172 Phase 0 (commit `7e9e683`), only the dedicated `XYZ_PYTHON=1` regression test remains. **Lane 11** (#215): GH-172's cutover-recommendation follow-up (`utils/py/consult.py` degraded-panel parity). **Lanes 12-13 added 2026-07-17** during a recent-issues (last 10 days) sweep: Lane 12 (#208) is the exact `worktree-isolation.sh` flaky race this doc's own Status table names as the last red gate; Lane 13 (#154) is another Bash/Python-port parity gap (marathon-plan.sh's GH-48 zone model missing from the JS port). Contracts added to all source docs, `swarm-preflight.sh --dry-run` confirmed ready (exit 0) for #174, #215, #208, #154; a combined 4-phase marathon (Lanes 10/11 excluded from this fire, Lanes 12-13 + Plan G's 2 lanes included) fired 2026-07-17. → [MARATHON-PLAN-2026-07-07-F-VALIDATE-FIXES.md](PROJECT/3-COMPLETED/MARATHON-PLAN-2026-07-07-F-VALIDATE-FIXES.md)
- **GH-174 · agy-turn.py never got GH-171's claim-before-launch guard (XYZ_PYTHON=1 agy turns still exposed)** ✅ **SHIPPED 2026-07-17 via a marathon lane (worktree-isolated Sonnet subagent)** — the source fix had already landed via GH-172 Phase 0; added the missing regression test, case `(18a)` in `test/marathon-drive.sh`, proving the agy-leg claim event lands under `XYZ_PYTHON=1`. `bash test/marathon-drive.sh` 106/106, zero regressions. cx/risk/eff 1/1/1. → [GH-174-AGY-PY-CLAIM-GUARD.md](PROJECT/3-COMPLETED/GH-174-AGY-PY-CLAIM-GUARD.md) · [#174](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/174)
- **GH-215 · utils/py/consult.py missing Bash degraded-panel SINGLE-MODEL stamping** ✅ **SHIPPED 2026-07-17 via a marathon lane (worktree-isolated Sonnet subagent)** — ported the `SINGLE-MODEL — NOT RECONCILED` stamping from `consult.sh` into `consult.py` verbatim, 2 new `test/consult.sh` cases, gate `bash test/consult.sh` 50/50 green. **Found in the process:** `XYZ_PYTHON=1 bash test/consult.sh` is still red for an unrelated, pre-existing reason this bug was masking (GH-178 A4's citation stamping was never ported to Python either) — tracked as [#223](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/223), not fixed here. cx/risk/eff 2/1/2. → [GH-215-CONSULT-PY-DEGRADED-PANEL-PARITY.md](PROJECT/3-COMPLETED/GH-215-CONSULT-PY-DEGRADED-PANEL-PARITY.md) · [#215](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/215)
- **GH-208 · worktree-isolation.sh: flaky moved-ROOT-HEAD preserve-case race (GH-13/#14 guard)** ✅ **SHIPPED 2026-07-17 via the GH208-154-149-198 marathon (codex builder, agy reviewer, Approved)** — 9 local runs of `test/worktree-isolation.sh` at HEAD had produced 8 failures (case 6, `rc=6`); root cause turned out NOT to be a `relay-turn-lib.sh` race (that logic was correct) but a **test-fixture timing bug**: case (5)'s deliberate async write hadn't landed before case (6)'s cleanup ran. Fixed with a 2s wait in the fixture, no source-code change. Verified 8/8 clean repeated runs. Full `validate.sh`: 113/114 (only the separately-fixed `relay-pkg-freshness.sh` staleness). cx/risk/eff 2/2/2. → [GH-208-WORKTREE-ISOLATION-RACE.md](PROJECT/3-COMPLETED/GH-208-WORKTREE-ISOLATION-RACE.md) · [#208](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/208)
- **GH-154 · port-drift: marathon-plan shell heredoc vs. Python-layer port diverged (missing GH-48 zone model)** ✅ **SHIPPED 2026-07-17 via the GH208-154-149-198 marathon (Approved)** — ported `compileZoneConfig`/`QP_ZONES_CONFIG`/`QUEUE_PLAN_ZONES_FILE` into `utils/py/_marathon_plan_node.js`; also wired `utils/marathon-plan.sh`'s `XYZ_PYTHON=1` dispatcher to translate `--zones-config` into `QUEUE_PLAN_ZONES_FILE` so the flag survives the shell→Python→Node handoff. 2 new parity assertions in `test/marathon-plan.sh` (explicit-zones dry-run + rendered doc, shell vs. `XYZ_PYTHON=1`). Full `bash test/marathon-plan.sh`: 60/60 (up from 58). GH-110 P3a is now unblocked. cx/risk/eff 2/2/3. → [GH-154-MARATHON-PLAN-PORT-PARITY.md](PROJECT/3-COMPLETED/GH-154-MARATHON-PLAN-PORT-PARITY.md) · [#154](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/154)
- **Marathon Plan G · marathon/relay driver hardening (GH-149, GH-198)** ✅ **both lanes SHIPPED 2026-07-17 (codex builder, agy reviewer, both Approved)** — two small, independent driver-script bugs, neither fitting Plan F's theme: Lane 1 (#149) fixed, Lane 2 (#198 Bug 2) fixed — see their own entries below. → [MARATHON-PLAN-2026-07-17-G-DRIVER-HARDENING.md](PROJECT/3-COMPLETED/MARATHON-PLAN-2026-07-17-G-DRIVER-HARDENING.md)
- **GH-149 · marathon-drive --require-clean self-trips on its own .relay-driver.lock inside a linked worktree** ✅ **SHIPPED 2026-07-17 via the GH208-154-149-198 marathon (Approved)** — `marathon-drive.sh` now resolves the driver lock via `git rev-parse --git-common-dir "$ROOT"` when `$ROOT/.git` is a file (linked worktree), landing it in the real `.git/` dir outside the worktree's own `git status --porcelain` view (falls back to the original hidden-lock behavior for a vendored `.xyz/` copy). New regression case in `test/marathon-drive.sh`. Full `bash test/marathon-drive.sh`: 105/105. cx/risk/eff 2/2/2. → [GH-149-REQUIRE-CLEAN-SELFTRIP.md](PROJECT/3-COMPLETED/GH-149-REQUIRE-CLEAN-SELFTRIP.md) · [#149](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/149)
- **GH-198 · relay-drive.sh headless turn: file-scoped commit ignores pathspec + uncommitted-artifact review fails opaquely** ✅ **Bug 2 SHIPPED 2026-07-17 via the GH208-154-149-198 marathon (Approved); Bug 1 already fixed separately (commit `bee1abf`)** — `relay-drive.sh` gained `preflight_setup_artifact_paths()`, called before each turn dispatch: scans the relay file's `Setup` section, fails fast with `artifact path not found in worktree: <path>` if a referenced artifact is missing, instead of failing opaquely mid-turn. 2 new cases in `test/relay-artifact-file.sh`. Full suite: 13/13 (up from 11). cx/risk/eff 1/1/2. → [GH-198-RELAY-DRIVE-ARTIFACT-PREFLIGHT.md](PROJECT/3-COMPLETED/GH-198-RELAY-DRIVE-ARTIFACT-PREFLIGHT.md) · [#198](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/198)
- **Marathon Plan H · cross-repo live marathon status query (GH-218)** 🆕 **captured 2026-07-17 via `/idea`, promoted to 2-WORKING, 2-phase marathon built** — lets the operator/Claude ask "what marathons are running right now" across every XYZ-vendored repo, returning repo + marathon/lane + in-flight task + claimant. Composes entirely existing primitives (`hq_known_repos`/registry.tsv for repo discovery, `tick project`'s own derived `STATE.md` for live claim state, `rollup.sh`'s existing embed mechanism for Obsidian) — explicitly rejects a per-repo MCP server as unjustified overkill (everything needed is a local file/process read on this machine). Phase 1: new `utils/hq/marathon-live.sh`. Phase 2: small `rollup.sh` hook to embed its report. cx/risk/eff 3/1/2. → [MARATHON-PLAN-2026-07-17-H-LIVE-MARATHON-STATUS.md](PROJECT/2-WORKING/MARATHON-PLAN-2026-07-17-H-LIVE-MARATHON-STATUS.md)

exec
/bin/zsh -lc "wc -l PROJECT/2-WORKING/GH-23-KERNEL-OVERLAP-ENFORCEMENT.md src/claim.js src/scope.js bin/tick test/gh23-path-overlap-enforcement.sh src/*.js; sed -n '1,280p' PROJECT/2-WORKING/GH-23-KERNEL-OVERLAP-ENFORCEMENT.md; nl -ba src/claim.js; nl -ba src/scope.js; nl -ba bin/tick; nl -ba test/gh23-path-overlap-enforcement.sh; rg -n --glob '*.js' --glob '*.sh' 'setsOverlap|withClaimLock|otherClaimedPaths|claim\\(|scope\\(|unavailable|claimedPaths|epoch' src bin test | head -500; git status --short; git log --oneline -10" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb
2026-08-17T20:09:55.162283Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 96 column 5
 succeeded in 5832ms:
2026-08-17 13:09:50.152 xcodebuild[9836:258832516]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-17 13:09:50.570 xcodebuild[9836:258832515] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-AxIJthVB' (errno=Operation not permitted)
2026-08-17 13:09:51.317 xcodebuild[9980:258832868]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-17 13:09:51.504 xcodebuild[9980:258832867] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
?? PROJECT/2-WORKING/GH-23-KERNEL-OVERLAP-ENFORCEMENT.md
?? relay-system/2026-08-17/consult-130916/
?? test/gh23-path-overlap-enforcement.sh
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-OzCxMS96' (errno=Operation not permitted)
2026-08-17 13:09:53.086 xcodebuild[10136:258833130]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-17 13:09:53.289 xcodebuild[10136:258833129] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-yZotQTZf' (errno=Operation not permitted)
2026-08-17 13:09:53.866 xcodebuild[10184:258833333]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-17 13:09:54.081 xcodebuild[10184:258833332] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
1c0d6c8 WIP on fix/gh-23-kernel-overlap-enforcement: 2914411 docs(readme): establish canonical Glossary and clarify sequential vs concurrent execution model
a13bb2e index on fix/gh-23-kernel-overlap-enforcement: 2914411 docs(readme): establish canonical Glossary and clarify sequential vs concurrent execution model
2914411 docs(readme): establish canonical Glossary and clarify sequential vs concurrent execution model
de092cb chore(GH-563): witness restored push gate
7a8ece6 docs(GH-563): record front-door and shakedown reviews
00b2816 docs(GH-563): align push-gate guidance with hosted CI
d09bdb6 fix(GH-563): execute public front-door and shakedown gates
e80e1fc Ballast 0.7.0: land #4 and #3, cut #10, write the release's exit criterion
3afc0df GH-15: finalize ten-run stranger verification (10/10 clean) + re-derive Ballast wave 1
6ddb12e Ballast: post-merge reconciliation for #14 and #15 (PR #21, PR #20)

codex
The branch keeps the overlap decision inside the existing claim lock, which is the right atomicity boundary. I’m now checking the CLI contract and projection/epoch interactions for loopholes the regression script may miss.
exec
/bin/zsh -lc "nl -ba bin/tick | sed -n '80,255p'; nl -ba bin/tick | sed -n '255,470p'; nl -ba test/gh23-path-overlap-enforcement.sh; nl -ba src/paths.js; nl -ba src/lock.js; nl -ba src/project.js | sed -n '1,305p'; nl -ba src/events.js | sed -n '1,230p'; nl -ba src/take.js; nl -ba src/next.js; nl -ba test/concurrent-claim.sh; nl -ba test/ownership.sh | sed -n '1,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb
 succeeded in 0ms:
    80	}
    81	
    82	function usage() {
    83	  process.stderr.write(`tick — coordination layer CLI
    84	
    85	Usage:
    86	  tick init
    87	  tick log <type> <task> [--agent <id>] [--note "..."] [--paths a,b] [--priority N] [--epoch N]
    88	  tick project
    89	  tick fences                                      (read-only: fenced-event audit log)
    90	  tick claim <task> --agent <id> --paths <globs> [--force]
    91	  tick take --agent <id>                           (atomic next+claim)
    92	  tick next --agent <id>                           (read-only, no STATE.md write)
    93	  tick scope <task> --agent <id> --paths <globs> [--force]
    94	  tick release <task> --agent <id> [--to <agent>] [--relay-file <path>]
    95	  tick break <task> --agent <id> --reason "..."
    96	  tick done <task> --agent <id> [--note "..."] [--relay-file <path>]
    97	  tick drift <surface> --agent <id> [--task <id>] [--prior-sha <sha>] [--current-sha <sha>] [--diff-lines <n>] [--turn <id>]
    98	  tick ping <task> --agent <id> [--note "..."]      (liveness heartbeat)
    99	  tick reap <agent> [--by <id>] [--task <task>]
   100	  tick info <task>
   101	  tick cost <task> --agent <id> --human-minutes <n>          (log operator attention)
   102	  tick cost <task> --agent <id> --tokens-in <n> --tokens-out <n> [--tokens-total <n>] [--tool <name>]
   103	  tick cost <task> --agent <id> --from-gemini-json <file> [--tool gemini]   (parse gemini -o json)
   104	  tick analyze [--format human|md|json] [--write <file>]
   105	
   106	Event types: ${Array.from(EVENT_TYPES).join(', ')}
   107	
   108	Exit codes:
   109	  1 — claim not acquired (GH-408): lost to another owner, task already terminal, path overlap,
   110	      or at the per-agent claim cap. A claim you already hold is a WIN and still exits 0.
   111	  2 — usage error (missing/unknown flags) — deliberately distinct from a lost claim
   112	  6 — containment violation (off-allowlist edit in relay-turn-lib.sh)
   113	  8 — relay block structural validation failed (bin/validate-relay-block returned non-zero)
   114	`);
   115	}
   116	
   117	function main(argv) {
   118	  const verb = argv[0];
   119	  const rest = argv.slice(1);
   120	  const { positional, flags } = parseArgs(rest);
   121	  const { root, source } = repoRoot();
   122	  assertResolvedRoot(verb, root, source);
   123	
   124	  switch (verb) {
   125	    case 'init': {
   126	      ensureEventsDir(root);
   127	      process.stdout.write(`initialized .tick/events at ${root}\n`);
   128	      return 0;
   129	    }
   130	
   131	    case 'log': {
   132	      const [type, task] = positional;
   133	      if (!type || !task) { usage(); return 2; }
   134	      const { path: p } = appendEvent(root, {
   135	        type,
   136	        task,
   137	        agent: flags.agent || process.env.TICK_AGENT || 'unknown',
   138	        note: typeof flags.note === 'string' ? flags.note : undefined,
   139	        paths: flags.paths ? parsePathsFlag(flags.paths) : undefined,
   140	        to_agent: typeof flags.to === 'string' ? flags.to : undefined,
   141	        reason: typeof flags.reason === 'string' ? flags.reason : undefined,
   142	        priority: flags.priority !== undefined ? Number(flags.priority) : undefined,
   143	        epoch: flags.epoch !== undefined ? Number(flags.epoch) : undefined,
   144	      });
   145	      process.stdout.write(`${path.relative(root, p)}\n`);
   146	      return 0;
   147	    }
   148	
   149	    case 'project': {
   150	      const { stateFile, rejections } = project(root);
   151	      process.stdout.write(`${path.relative(root, stateFile)}\n`);
   152	      if (rejections.length) {
   153	        process.stderr.write(`fenced ${rejections.length} stale/non-owner event(s) — see .tick/rejected.jsonl\n`);
   154	      }
   155	      return 0;
   156	    }
   157	
   158	    case 'fences': {
   159	      // Read-only: re-project and print the fenced-event audit log (one JSON
   160	      // object per line). Shows the epoch fence firing (R1) for operators/SIEM.
   161	      const { rejections } = project(root);
   162	      for (const r of rejections) process.stdout.write(`${JSON.stringify(r)}\n`);
   163	      return 0;
   164	    }
   165	
   166	    case 'claim': {
   167	      const [task] = positional;
   168	      if (!task || !flags.agent || !flags.paths) { usage(); return 2; }
   169	      const result = claim(root, {
   170	        task,
   171	        agent: flags.agent,
   172	        paths: parsePathsFlag(flags.paths),
   173	        force: Boolean(flags.force),
   174	      });
   175	      // GH-408: every `lost:` branch below exits 1, not 0. It used to print the reason and exit 0,
   176	      // which made the failure undetectable by exit status — so a caller doing the correct thing
   177	      // (`if ! tick claim ...; then`) learned nothing, and the only remaining signal was stdout,
   178	      // which every caller in this repo was sending to DEVNULL. Both belts were cut at once, and on
   179	      // 2026-08-07 that cost ~2h: an agent at its claim cap produced a turn failure whose message
   180	      // pointed at a perfectly healthy token. A won claim (including the idempotent re-claim by the
   181	      // holder, which `claim()` reports as won) still exits 0; usage errors still exit 2.
   182	      if (result.limitReached) {
   183	        process.stdout.write(`lost: claim limit reached (holding ${result.holding.join(', ')}) — finish or release first\n`);
   184	        return 1;
   185	      }
   186	      if (result.won) {
   187	        process.stdout.write(`won: ${task} claimed by ${flags.agent}\n`);
   188	        return 0;
   189	      }
   190	      if (result.overlap) {
   191	        process.stdout.write(`lost: ${task} is ${result.unavailable} — use --force to override\n`);
   192	        return 1;
   193	      }
   194	      if (result.unavailable) {
   195	        process.stdout.write(`lost: ${task} is ${result.unavailable} — not claimable\n`);
   196	        // A tick task id is single-shot: once terminal it can't be reclaimed. A relay that reuses a
   197	        // spent turn-token id (e.g. the literal RELAY-TURN from a prior relay) lands here and the seed
   198	        // silently breaks. Point at the fix (GH-18 #1): a fresh per-relay id.
   199	        process.stdout.write(`  → '${task}' is spent; use a fresh per-relay id (e.g. --relay-task RELAY-<your-slug>)\n`);
   200	        return 1;
   201	      }
   202	      process.stdout.write(`lost: ${task} already claimed by ${result.winner || 'unknown'}\n`);
   203	      return 1;
   204	    }
   205	
   206	    case 'take': {
   207	      if (!flags.agent) { usage(); return 2; }
   208	      const tr = take(root, { agent: flags.agent });
   209	      if (tr.limitReached) {
   210	        process.stdout.write(`(claim limit reached — holding ${tr.holding.join(', ')} — finish or release a task first)\n`);
   211	        return 0;
   212	      }
   213	      if (!tr.won) { process.stdout.write('(no available task)\n'); return 0; }
   214	      const handoffMark = tr.handoff ? ' [handoff]' : '';
   215	      process.stdout.write(`won: ${tr.task} (priority: ${tr.priority})${handoffMark}\n`);
   216	      return 0;
   217	    }
   218	
   219	    case 'next': {
   220	      if (!flags.agent) { usage(); return 2; }
   221	      const t = next(root, { agent: flags.agent });
   222	      if (t && t.limitReached) {
   223	        process.stdout.write(`(claim limit reached — holding ${t.holding.join(', ')} — finish or release a task first)\n`);
   224	        return 0;
   225	      }
   226	      if (!t) { process.stdout.write('(no available task)\n'); return 0; }
   227	      const handoff = t.handoff_to === flags.agent ? ' [handoff]' : '';
   228	      process.stdout.write(`${t.id} (priority: ${t.priority})${handoff}\n`);
   229	      return 0;
   230	    }
   231	
   232	    case 'scope': {
   233	      const [task] = positional;
   234	      if (!task || !flags.agent || !flags.paths) { usage(); return 2; }
   235	      try {
   236	        scope(root, { task, agent: flags.agent, paths: parsePathsFlag(flags.paths), force: Boolean(flags.force) });
   237	        process.stdout.write(`scoped: ${task}\n`);
   238	        return 0;
   239	      } catch (err) {
   240	        process.stderr.write(`tick scope: ${err.message}\n`);
   241	        return 1;
   242	      }
   243	    }
   244	
   245	    case 'release': {
   246	      const [task] = positional;
   247	      if (!task || !flags.agent) { usage(); return 2; }
   248	      if (flags['relay-file']) {
   249	        const validateScript = path.resolve(__dirname, 'validate-relay-block');
   250	        try {
   251	          execFileSync(validateScript, [flags['relay-file']], { stdio: 'inherit' });
   252	        } catch (err) {
   253	          process.stderr.write(`tick: validation failed for ${flags['relay-file']}\n`);
   254	          return 8;
   255	        }
   255	        }
   256	      }
   257	      release(root, { task, agent: flags.agent, to_agent: typeof flags.to === 'string' ? flags.to : undefined });
   258	      process.stdout.write(`released: ${task}\n`);
   259	      return 0;
   260	    }
   261	
   262	    case 'break': {
   263	      const [task] = positional;
   264	      if (!task || !flags.agent) { usage(); return 2; }
   265	      circuitBreak(root, { task, agent: flags.agent, reason: typeof flags.reason === 'string' ? flags.reason : '' });
   266	      process.stdout.write(`broken: ${task}\n`);
   267	      return 0;
   268	    }
   269	
   270	    case 'done': {
   271	      const [task] = positional;
   272	      if (!task || !flags.agent) { usage(); return 2; }
   273	      if (flags['relay-file']) {
   274	        const validateScript = path.resolve(__dirname, 'validate-relay-block');
   275	        try {
   276	          execFileSync(validateScript, [flags['relay-file']], { stdio: 'inherit' });
   277	        } catch (err) {
   278	          process.stderr.write(`tick: validation failed for ${flags['relay-file']}\n`);
   279	          return 8;
   280	        }
   281	      }
   282	      done(root, { task, agent: flags.agent, note: typeof flags.note === 'string' ? flags.note : undefined });
   283	      process.stdout.write(`done: ${task}\n`);
   284	      return 0;
   285	    }
   286	
   287	    case 'drift': {
   288	      // GH-68 warn-only cross-agent dependency-drift signal. Emits a dependency.drift event when a
   289	      // landed relay turn changed a shared surface, so the next agent's shim can inject a heads-up.
   290	      // Purely informational — best-effort like `cost`/`log`, deliberately NOT in MUTATING_GUARD_VERBS
   291	      // so it can never hard-fail a turn (the warn-only invariant, decisions/2026-07-01-cross-agent-dep-conflict.md).
   292	      const [surface] = positional;
   293	      if (!surface) { usage(); return 2; }
   294	      const { path: p } = appendEvent(root, {
   295	        type: 'dependency.drift',
   296	        task: typeof flags.task === 'string' ? flags.task : 'post-commit',
   297	        agent: flags.agent || process.env.TICK_AGENT || 'unknown',
   298	        surface,
   299	        prior_sha: typeof flags['prior-sha'] === 'string' ? flags['prior-sha'] : undefined,
   300	        current_sha: typeof flags['current-sha'] === 'string' ? flags['current-sha'] : undefined,
   301	        diff_lines: flags['diff-lines'] !== undefined ? Number(flags['diff-lines']) : undefined,
   302	        turn: typeof flags.turn === 'string' ? flags.turn : undefined,
   303	      });
   304	      process.stdout.write(`${path.relative(root, p)}\n`);
   305	      return 0;
   306	    }
   307	
   308	    case 'ping': {
   309	      const [task] = positional;
   310	      if (!task || !flags.agent) { usage(); return 2; }
   311	      heartbeat(root, { task, agent: flags.agent, note: typeof flags.note === 'string' ? flags.note : undefined });
   312	      process.stdout.write(`heartbeat: ${task} by ${flags.agent}\n`);
   313	      return 0;
   314	    }
   315	
   316	    case 'reap': {
   317	      const [agent] = positional;
   318	      if (!agent) { usage(); return 2; }
   319	      const by = typeof flags.by === 'string' ? flags.by : (gitUserName(root) || 'coordinator');
   320	      const result = reap(root, {
   321	        agent,
   322	        by,
   323	        task: typeof flags.task === 'string' ? flags.task : undefined,
   324	      });
   325	      if (!result.reaped.length) {
   326	        process.stdout.write(`(no active claims held by ${agent})\n`);
   327	      } else {
   328	        process.stdout.write(`reaped ${result.reaped.length} claim(s) from ${agent}: ${result.reaped.join(', ')}\n`);
   329	      }
   330	      return 0;
   331	    }
   332	
   333	    case 'info': {
   334	      const [task] = positional;
   335	      if (!task) { usage(); return 2; }
   336	      const { tasks: infoTasks } = project(root);
   337	      const t = infoTasks.get(task);
   338	      if (!t) { process.stdout.write(`(task ${task} not found)\n`); return 1; }
   339	      const lines = [
   340	        `id:       ${t.id}`,
   341	        `status:   ${t.status}`,
   342	        `priority: ${t.priority}`,
   343	      ];
   344	      const paths = t.status === 'claimed' ? t.claim.paths : t.paths;
   345	      lines.push(`paths:    ${paths.join(', ') || '(none)'}`);
   346	      if (t.status === 'claimed') lines.push(`claimer:  ${t.claim.agent}`);
   347	      if (t.status === 'circuit_broken') lines.push(`broken-by: ${t.break.agent} — ${t.break.reason}`);
   348	      if (t.handoff_to) lines.push(`handoff-to: ${t.handoff_to}`);
   349	      process.stdout.write(lines.join('\n') + '\n');
   350	      return 0;
   351	    }
   352	
   353	    case 'cost': {
   354	      const [task] = positional;
   355	      if (!task || !flags.agent) { usage(); return 2; }
   356	      const num = v => (v === undefined || v === true ? undefined : Number(v));
   357	
   358	      // (a) human attention — self-reported operator minutes.
   359	      if (flags['human-minutes'] !== undefined) {
   360	        const mins = num(flags['human-minutes']);
   361	        if (!Number.isFinite(mins)) { process.stderr.write('tick cost: --human-minutes must be a number\n'); return 2; }
   362	        appendEvent(root, { type: 'cost.human', task, agent: flags.agent, human_minutes: mins });
   363	        process.stdout.write(`cost.human: ${task} +${mins} min by ${flags.agent}\n`);
   364	        return 0;
   365	      }
   366	
   367	      // (b) memory telemetry — compressor, swap free, and agent peak RSS (GH-382).
   368	      if (flags['compressor-mb'] !== undefined || flags['swap-free-mb'] !== undefined || flags['peak-rss-mb'] !== undefined) {
   369	        const cMb = flags['compressor-mb'] !== undefined ? num(flags['compressor-mb']) : undefined;
   370	        const sMb = flags['swap-free-mb'] !== undefined ? num(flags['swap-free-mb']) : undefined;
   371	        const rMb = flags['peak-rss-mb'] !== undefined ? num(flags['peak-rss-mb']) : undefined;
   372	        appendEvent(root, {
   373	          type: 'cost.memory', task, agent: flags.agent,
   374	          compressor_mb: cMb,
   375	          swap_free_mb: sMb,
   376	          peak_rss_mb: rMb,
   377	        });
   378	        process.stdout.write(`cost.memory: ${task} compressor=${cMb !== undefined ? cMb : 'n/a'} swap_free=${sMb !== undefined ? sMb : 'n/a'} peak_rss=${rMb !== undefined ? rMb : 'n/a'} by ${flags.agent}\n`);
   379	        return 0;
   380	      }
   381	
   382	      // (c) tokens from a gemini -o json transcript — parse verbatim (Q1: CLI report is source of truth).
   383	      let tokensIn, tokensOut, tokensTotal;
   384	      if (typeof flags['from-gemini-json'] === 'string') {
   385	        const jf = path.resolve(root, flags['from-gemini-json']);
   386	        if (!fs.existsSync(jf)) { process.stderr.write(`tick cost: no such file: ${flags['from-gemini-json']}\n`); return 2; }
   387	        const stats = parseGeminiStats(fs.readFileSync(jf, 'utf8'));
   388	        if (!stats) { process.stderr.write(`tick cost: no parseable token stats in ${flags['from-gemini-json']} — not captured\n`); return 1; }
   389	        ({ tokens_in: tokensIn, tokens_out: tokensOut, tokens_total: tokensTotal } = stats);
   390	      } else {
   391	        tokensIn = num(flags['tokens-in']);
   392	        tokensOut = num(flags['tokens-out']);
   393	        tokensTotal = num(flags['tokens-total']);
   394	      }
   395	      if (!Number.isFinite(tokensIn) || !Number.isFinite(tokensOut)) {
   396	        process.stderr.write('tick cost: need --tokens-in and --tokens-out (or --from-gemini-json, or --human-minutes, or --compressor-mb/--swap-free-mb/--peak-rss-mb)\n');
   397	        return 2;
   398	      }
   399	      if (!Number.isFinite(tokensTotal)) tokensTotal = tokensIn + tokensOut;
   400	      appendEvent(root, {
   401	        type: 'cost.tokens', task, agent: flags.agent,
   402	        tokens_in: tokensIn, tokens_out: tokensOut, tokens_total: tokensTotal,
   403	        tool: typeof flags.tool === 'string' ? flags.tool : undefined,
   404	      });
   405	      process.stdout.write(`cost.tokens: ${task} in=${tokensIn} out=${tokensOut} total=${tokensTotal} by ${flags.agent}\n`);
   406	      return 0;
   407	    }
   408	
   409	    case 'analyze': {
   410	      const format = (typeof flags.format === 'string' && flags.format) || 'human';
   411	      const report = analyze(root);
   412	      let body;
   413	      if (format === 'json') body = JSON.stringify(report, null, 2);
   414	      else if (format === 'md') body = renderMd(report);
   415	      else body = renderHuman(report);
   416	
   417	      if (typeof flags.write === 'string') {
   418	        // Append (or replace existing auto-analyzed section in) the target file.
   419	        const target = path.resolve(root, flags.write);
   420	        const md = format === 'md' ? body : renderMd(report);
   421	        let existing = '';
   422	        if (fs.existsSync(target)) existing = fs.readFileSync(target, 'utf8');
   423	        const marker = '## Auto-analyzed (tick analyze)';
   424	        const idx = existing.indexOf(marker);
   425	        let next;
   426	        if (idx >= 0) {
   427	          // Replace from marker to end of file, since auto-analyzed sits at the bottom.
   428	          next = existing.slice(0, idx).replace(/\s+$/, '') + '\n\n' + md;
   429	        } else {
   430	          next = (existing.replace(/\s+$/, '') + '\n\n' + md).replace(/^\n+/, '');
   431	        }
   432	        fs.writeFileSync(target, next.endsWith('\n') ? next : next + '\n');
   433	        process.stdout.write(`wrote analysis to ${path.relative(root, target)}\n`);
   434	      } else {
   435	        process.stdout.write(body + '\n');
   436	      }
   437	      return 0;
   438	    }
   439	
   440	    case '-h':
   441	    case '--help':
   442	    case 'help':
   443	    case undefined:
   444	      usage();
   445	      return 0;
   446	
   447	    default:
   448	      process.stderr.write(`unknown verb: ${verb}\n`);
   449	      usage();
   450	      return 2;
   451	  }
   452	}
   453	
   454	try {
   455	  process.exit(main(process.argv.slice(2)) || 0);
   456	} catch (err) {
   457	  process.stderr.write(`tick: error: ${err.message}\n`);
   458	  process.exit(1);
   459	}
     1	#!/usr/bin/env bash
     2	# GH-23: Enforce path-overlap rejection on direct tick claim and tick scope.
     3	source "$(dirname "$0")/_setup.sh" gh23-path-overlap-enforcement
     4	
     5	tick_a init >/dev/null
     6	
     7	# 1. Setup tasks
     8	TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-101 --agent dispatcher --paths "src/auth/**" >/dev/null
     9	TICK_TS=2026-05-04T10:00:01.000Z tick_a log task.created TASK-102 --agent dispatcher --paths "src/auth/login.js" >/dev/null
    10	TICK_TS=2026-05-04T10:00:02.000Z tick_a log task.created TASK-103 --agent dispatcher --paths "src/billing/**" >/dev/null
    11	
    12	# Alice claims TASK-101 with src/auth/**
    13	tick_a claim TASK-101 --agent alice --paths "src/auth/**" >/dev/null
    14	if [ $? -eq 0 ]; then
    15	  pass "alice successfully claimed TASK-101"
    16	else
    17	  fail "alice failed to claim TASK-101"
    18	fi
    19	
    20	# 2. Bob attempts direct claim on TASK-102 (src/auth/login.js) -> MUST FAIL due to overlap with Alice
    21	BOB_OUT=$(tick_b claim TASK-102 --agent bob --paths "src/auth/login.js" 2>&1)
    22	BOB_STATUS=$?
    23	if [ $BOB_STATUS -ne 0 ] && echo "$BOB_OUT" | grep -q "paths overlap active claim"; then
    24	  pass "direct claim on overlapping task TASK-102 rejected (exit $BOB_STATUS): $BOB_OUT"
    25	else
    26	  fail "direct claim on overlapping task was not rejected! status=$BOB_STATUS out=$BOB_OUT"
    27	fi
    28	
    29	# 3. Bob uses --force -> MUST SUCCEED
    30	BOB_FORCE_OUT=$(tick_b claim TASK-102 --agent bob --paths "src/auth/login.js" --force 2>&1)
    31	BOB_FORCE_STATUS=$?
    32	if [ $BOB_FORCE_STATUS -eq 0 ] && echo "$BOB_FORCE_OUT" | grep -q "won: TASK-102 claimed by bob"; then
    33	  pass "direct claim with --force succeeded: $BOB_FORCE_OUT"
    34	else
    35	  fail "direct claim with --force failed! status=$BOB_FORCE_STATUS out=$BOB_FORCE_OUT"
    36	fi
    37	
    38	# Bob releases TASK-102
    39	tick_b release TASK-102 --agent bob >/dev/null
    40	
    41	# 4. Bob claims TASK-103 (src/billing/**) -> non-overlapping, MUST SUCCEED
    42	tick_b claim TASK-103 --agent bob --paths "src/billing/**" >/dev/null
    43	if [ $? -eq 0 ]; then
    44	  pass "bob claimed non-overlapping TASK-103"
    45	else
    46	  fail "bob failed to claim TASK-103"
    47	fi
    48	
    49	# 5. Bob attempts tick scope on TASK-103 to include "src/auth/oauth.js" -> MUST FAIL due to overlap with Alice
    50	SCOPE_OUT=$(tick_b scope TASK-103 --agent bob --paths "src/billing/**,src/auth/oauth.js" 2>&1)
    51	SCOPE_STATUS=$?
    52	if [ $SCOPE_STATUS -ne 0 ] && echo "$SCOPE_OUT" | grep -q "paths overlap active claim"; then
    53	  pass "scope expansion into overlapping paths rejected (exit $SCOPE_STATUS): $SCOPE_OUT"
    54	else
    55	  fail "scope expansion into overlapping paths was not rejected! status=$SCOPE_STATUS out=$SCOPE_OUT"
    56	fi
    57	
    58	# 6. Bob uses tick scope --force -> MUST SUCCEED
    59	SCOPE_FORCE_OUT=$(tick_b scope TASK-103 --agent bob --paths "src/billing/**,src/auth/oauth.js" --force 2>&1)
    60	SCOPE_FORCE_STATUS=$?
    61	if [ $SCOPE_FORCE_STATUS -eq 0 ] && echo "$SCOPE_FORCE_OUT" | grep -q "scoped: TASK-103"; then
    62	  pass "scope expansion with --force succeeded: $SCOPE_FORCE_OUT"
    63	else
    64	  fail "scope expansion with --force failed! status=$SCOPE_FORCE_STATUS out=$SCOPE_FORCE_OUT"
    65	fi
    66	
    67	# 7. Alice completes TASK-101
    68	tick_a done TASK-101 --agent alice --note "auth done" >/dev/null
    69	
    70	# 8. Dispatcher creates TASK-104 with src/auth/**. Charlie claims it without --force -> MUST SUCCEED now that Alice finished
    71	TICK_TS=2026-05-04T10:00:10.000Z tick_a log task.created TASK-104 --agent dispatcher --paths "src/auth/register.js" >/dev/null
    72	# Bob still holds src/auth/oauth.js from forced scope above, but src/admin/** is free
    73	TICK_TS=2026-05-04T10:00:11.000Z tick_a log task.created TASK-105 --agent dispatcher --paths "src/admin/**" >/dev/null
    74	CHARLIE_OUT=$(tick_b claim TASK-105 --agent charlie --paths "src/admin/**" 2>&1)
    75	if [ $? -eq 0 ]; then
    76	  pass "charlie claimed non-overlapping TASK-105"
    77	else
    78	  fail "charlie failed to claim TASK-105: $CHARLIE_OUT"
    79	fi
    80	
    81	# 9. Idempotent re-claim: Charlie re-claims own held task -> MUST SUCCEED (won)
    82	CHARLIE_RECLAIM=$(tick_b claim TASK-105 --agent charlie --paths "src/admin/**" 2>&1)
    83	if [ $? -eq 0 ] && echo "$CHARLIE_RECLAIM" | grep -q "won: TASK-105 claimed by charlie"; then
    84	  pass "idempotent re-claim by current holder succeeded without self-overlap rejection"
    85	else
    86	  fail "idempotent re-claim failed! out=$CHARLIE_RECLAIM"
    87	fi
    88	
    89	echo "  $TEST_NAME: $PASS pass, $FAIL fail"
    90	[ "$FAIL" -eq 0 ] || exit 1
    91	exit 0
     1	'use strict';
     2	
     3	// Conservative path-overlap detection for the spike.
     4	// Two glob patterns "overlap" if there exists at least one path matching both.
     5	// We don't fully decide intersection of arbitrary globs; we use a sound but
     6	// conservative test: convert each pattern to a literal prefix (text up to the
     7	// first wildcard char), then declare overlap iff one prefix is a prefix of the
     8	// other. This may report overlap when there isn't one (false positive = safer)
     9	// but never misses a real overlap.
    10	
    11	/**
    12	 * The literal (non-wildcard) prefix of a glob pattern — the text before the
    13	 * first `*`, `?`, `[`, or `{`.
    14	 * @param {string} glob
    15	 * @returns {string}
    16	 */
    17	function literalPrefix(glob) {
    18	  const m = glob.match(/^([^*?[{]*)/);
    19	  return m ? m[1] : '';
    20	}
    21	
    22	/**
    23	 * Conservative overlap test between two glob patterns: true if either
    24	 * pattern's literal prefix is a prefix of the other's. Sound but not exact —
    25	 * may false-positive (safer for claim exclusivity), never false-negatives a
    26	 * real overlap.
    27	 * @param {string} a
    28	 * @param {string} b
    29	 * @returns {boolean}
    30	 */
    31	function patternsOverlap(a, b) {
    32	  const pa = literalPrefix(a);
    33	  const pb = literalPrefix(b);
    34	  return pa.startsWith(pb) || pb.startsWith(pa);
    35	}
    36	
    37	/**
    38	 * True if any pattern in `setA` overlaps (per {@link patternsOverlap}) any
    39	 * pattern in `setB`.
    40	 * @param {string[]} setA
    41	 * @param {string[]} setB
    42	 * @returns {boolean}
    43	 */
    44	function setsOverlap(setA, setB) {
    45	  if (!setA || !setB || !setA.length || !setB.length) return false;
    46	  for (const a of setA) {
    47	    for (const b of setB) {
    48	      if (patternsOverlap(a, b)) return true;
    49	    }
    50	  }
    51	  return false;
    52	}
    53	
    54	// Glob-to-regex for matching a literal file path against a glob pattern.
    55	// Handles **, *, ?. No brace/char-class support — keep it small for the spike.
    56	/**
    57	 * Compiles a glob pattern (`**`, `*`, `?`) into an anchored RegExp for
    58	 * matching a literal file path. No brace/char-class support.
    59	 * @param {string} glob
    60	 * @returns {RegExp}
    61	 */
    62	function globToRegex(glob) {
    63	  let re = '';
    64	  for (let i = 0; i < glob.length; i++) {
    65	    const ch = glob[i];
    66	    if (ch === '*') {
    67	      if (glob[i + 1] === '*') {
    68	        re += '.*';
    69	        i++;
    70	        // consume optional trailing slash so foo/** matches foo (no trailing /)
    71	        if (glob[i + 1] === '/') i++;
    72	      } else {
    73	        re += '[^/]*';
    74	      }
    75	    } else if (ch === '?') {
    76	      re += '[^/]';
    77	    } else if ('.+^$()[]{}|\\'.includes(ch)) {
    78	      re += '\\' + ch;
    79	    } else {
    80	      re += ch;
    81	    }
    82	  }
    83	  return new RegExp('^' + re + '$');
    84	}
    85	
    86	/**
    87	 * True if `file` matches any pattern in `globs` (via {@link globToRegex}).
    88	 * @param {string} file - literal file path
    89	 * @param {string[]} globs
    90	 * @returns {boolean}
    91	 */
    92	function matchesAny(file, globs) {
    93	  if (!globs || !globs.length) return false;
    94	  return globs.some(g => globToRegex(g).test(file));
    95	}
    96	
    97	module.exports = { patternsOverlap, setsOverlap, literalPrefix, globToRegex, matchesAny };
     1	'use strict';
     2	
     3	const fs = require('fs');
     4	const path = require('path');
     5	
     6	// Claim-cycle atomicity (Run 2, P2).
     7	//
     8	// `tick claim` does project(read) -> cap-check -> appendEvent(write). That is a
     9	// TOCTOU window: two concurrent `tick claim` processes for the SAME agent could
    10	// both pass the cap check before either writes, busting the cap.
    11	//
    12	// Fix: a per-clone O_EXCL lock serialises one agent's own claim calls. The
    13	// lock lives under .tick/locks/ (never committed; directory is in .gitignore)
    14	// instead of .git/ so sandbox environments that restrict .git/ writes don't
    15	// block normal tick operation.
    16	//
    17	// Known limitation: a hard process kill mid-claim leaves a stale lock. Recovery
    18	// is `rm <repo>/.tick/locks/claim.lock`. Stale-detection is Phase 2.
    19	
    20	/**
    21	 * Path to the per-clone claim lock file, creating its parent directory if needed.
    22	 * @param {string} repoRoot - absolute path to the repo root
    23	 * @returns {string} absolute path to `<repoRoot>/.tick/locks/claim.lock`
    24	 */
    25	function lockPath(repoRoot) {
    26	  const locksDir = path.join(repoRoot, '.tick', 'locks');
    27	  fs.mkdirSync(locksDir, { recursive: true });
    28	  return path.join(locksDir, 'claim.lock');
    29	}
    30	
    31	/**
    32	 * Runs `fn` while holding the per-clone claim lock. `fs.openSync(.., 'wx')` is an
    33	 * atomic create-or-fail (O_EXCL): if the lock already exists it throws EEXIST.
    34	 * The lock is always released (closed + unlinked) before returning, including on throw.
    35	 * @param {string} repoRoot - absolute path to the repo root
    36	 * @param {function(): *} fn - callback to run while the lock is held
    37	 * @returns {*} whatever `fn` returns
    38	 * @throws {Error} if the lock is already held by another process
    39	 */
    40	function withClaimLock(repoRoot, fn) {
    41	  const lp = lockPath(repoRoot);
    42	  let fd;
    43	  try {
    44	    fd = fs.openSync(lp, 'wx');
    45	  } catch (err) {
    46	    if (err.code === 'EEXIST') {
    47	      throw new Error(
    48	        'another tick claim is in progress for this clone (lock held) — retry shortly, ' +
    49	        `or remove ${path.relative(repoRoot, lp)} if a prior claim was killed`
    50	      );
    51	    }
    52	    throw err;
    53	  }
    54	  try {
    55	    fs.writeSync(fd, String(process.pid));
    56	    return fn();
    57	  } finally {
    58	    fs.closeSync(fd);
    59	    try { fs.unlinkSync(lp); } catch { /* best-effort */ }
    60	  }
    61	}
    62	
    63	module.exports = { withClaimLock, lockPath };
     1	'use strict';
     2	
     3	const fs = require('fs');
     4	const path = require('path');
     5	const { readAllEvents } = require('./events');
     6	
     7	// Build deterministic state from all events.
     8	//
     9	// Ownership is fenced by a monotonic per-task EPOCH (R1, Part B Phase 1). Each
    10	// task.claimed carries an `epoch`; a takeover (reap → reclaim) raises it. The
    11	// current owner is the live claim with the HIGHEST epoch (ties: earliest ts,
    12	// then lexicographically smallest agent id — the legacy tie-breaker, reached
    13	// only when every epoch is equal, e.g. pre-0.2.0 logs that are all epoch 0).
    14	//
    15	// A mutating event (done / circuit_break / scope_changed / released) is honoured
    16	// ONLY when it is emitted by the current owner at an epoch >= the owner's. A
    17	// lower-epoch or non-owner mutation is REJECTED — recorded in the rejection log,
    18	// never applied. This is the kernel fence that stops a revived zombie writer
    19	// from advancing or corrupting a task it no longer owns: convention-free,
    20	// replay-deterministic (the verdict is a pure function of the event set, so it
    21	// is identical on every projection regardless of arrival order).
    22	
    23	function epochOf(ev) {
    24	  return Number.isFinite(ev.epoch) ? ev.epoch : 0;
    25	}
    26	
    27	function makeRejection(ev, winner, reason) {
    28	  return {
    29	    ts: ev.ts,
    30	    task: ev.task,
    31	    type: ev.type,
    32	    fenced_agent: ev.agent,
    33	    fenced_epoch: epochOf(ev),
    34	    owner_agent: winner ? winner.agent : null,
    35	    owner_epoch: winner ? epochOf(winner) : null,
    36	    reason,
    37	    file: ev._file || null,
    38	  };
    39	}
    40	
    41	/**
    42	 * Projects the ordered event log into current task state, applying the epoch
    43	 * fence (see file header) to reject stale/non-owner mutations. Pure function
    44	 * of the event set — replay-deterministic regardless of arrival order.
    45	 * @param {Object[]} events - as returned by {@link module:events.readAllEvents}, chronological order
    46	 * @returns {{tasks: Map<string, Object>, rejections: Object[]}} the projected
    47	 *   task map (keyed by task id) and the deterministic, ts-sorted list of fenced
    48	 *   (rejected) mutation events
    49	 */
    50	function foldWithMeta(events) {
    51	  // Bucket events per task in chronological order (events are pre-sorted by
    52	  // filename, which encodes ISO ts).
    53	  const byTask = new Map();
    54	  for (const ev of events) {
    55	    // dependency.drift (GH-68) is a purely informational cross-agent signal: it claims no task and is
    56	    // not a coordination event, so it must never seed or mutate a projected task — its synthetic task
    57	    // id (e.g. 'post-commit') would otherwise surface as a phantom `open` task in `tick project`/`next`.
    58	    // It is consumed directly from .tick/events/ by the shims' drift-brief reader, never via the fold.
    59	    // See decisions/2026-07-01-cross-agent-dep-conflict.md.
    60	    if (ev.type === 'dependency.drift') continue;
    61	    if (!byTask.has(ev.task)) byTask.set(ev.task, []);
    62	    byTask.get(ev.task).push(ev);
    63	  }
    64	
    65	  const tasks = new Map();
    66	  const rejections = [];
    67	
    68	  for (const [taskId, evs] of byTask) {
    69	    const t = {
    70	      id: taskId,
    71	      priority: 0,
    72	      paths: [],
    73	      status: 'open',
    74	      claim: null,
    75	      break: null,
    76	      handoff_to: null,
    77	    };
    78	
    79	    // Determine the live-claim winner: among claims whose agent has not
    80	    // subsequently released (ts >= the claim's), the highest epoch wins.
    81	    const claims = evs.filter(e => e.type === 'task.claimed');
    82	    const releases = evs.filter(e => e.type === 'task.released');
    83	    // A release retires a claim only if it is from the same agent, at or after
    84	    // the claim, AND at an epoch >= the claim's. The epoch guard is load-bearing:
    85	    // without it a revived writer's replayed lower-epoch release would retire the
    86	    // current (higher-epoch) claim it shares an id with — the same-id keystone.
    87	    const liveClaims = claims.filter(c =>
    88	      !releases.some(r => r.agent === c.agent && r.ts >= c.ts && epochOf(r) >= epochOf(c))
    89	    );
    90	    liveClaims.sort((a, b) => {
    91	      const ea = epochOf(a), eb = epochOf(b);
    92	      if (ea !== eb) return eb - ea; // highest epoch is the current owner
    93	      if (a.ts !== b.ts) return a.ts < b.ts ? -1 : 1;
    94	      return a.agent < b.agent ? -1 : a.agent > b.agent ? 1 : 0;
    95	    });
    96	    const winner = liveClaims[0] || null;
    97	    const ownerEpoch = winner ? epochOf(winner) : 0;
    98	    const maxClaimEpoch = claims.reduce((m, c) => Math.max(m, epochOf(c)), 0);
    99	    // A handoff (release --to) is honoured only from the latest epoch — the
   100	    // current owner, or (once released) the most recent epoch-holder. This stops
   101	    // a displaced writer from redirecting the reservation to an accomplice.
   102	    const handoffThreshold = winner ? ownerEpoch : maxClaimEpoch;
   103	
   104	    // Why the `ev.ts > winner.ts` guard on logging: an event that predates the
   105	    // current owner's claim is legitimate prior-epoch history (the reap/handoff
   106	    // release that retired the old claim, the old owner's scope) and is silently
   107	    // superseded — not a fence-firing. Only a mutation that lands AFTER ownership
   108	    // moved on is a genuine stale-writer attempt worth recording.
   109	    const isStaleWrite = (ev) => winner && ev.ts > winner.ts &&
   110	      (ev.agent !== winner.agent || epochOf(ev) < ownerEpoch);
   111	    // Most-specific reason: a different agent is a non-owner; a same-id writer
   112	    // below the owner's epoch is the keystone stale-epoch case.
   113	    const staleReason = (ev) =>
   114	      ev.agent !== winner.agent ? 'non-owner-agent' : 'stale-epoch';
   115	
   116	    // GH-41 (terminality-seal): the owner AS OF a given ts — the highest-epoch claim
   117	    // ACTIVE at that ts (placed at ts' <= ts and not retired by a same-agent release
   118	    // at ts'' <= ts, epoch >= the claim's), optionally capped at `maxEpoch`. It must
   119	    // be computed from the claim set at that instant, NOT the globally-filtered
   120	    // `liveClaims`: a claim that a *later* release retires is absent from liveClaims,
   121	    // so authorizing a terminal against liveClaims would let a release that lands
   122	    // AFTER the terminal retroactively de-authorize it (a done->open corruption).
   123	    // The `maxEpoch` cap (used with the terminal's own epoch) closes the boundary
   124	    // where a same-ts higher-epoch reclaim would otherwise masquerade as the owner.
   125	    const ownerAt = (ts, maxEpoch) => {
   126	      let best = null;
   127	      for (const c of claims) {
   128	        if (c.ts > ts) continue;
   129	        if (maxEpoch !== undefined && epochOf(c) > maxEpoch) continue;
   130	        if (releases.some(r => r.agent === c.agent && r.ts >= c.ts && r.ts <= ts && epochOf(r) >= epochOf(c))) continue;
   131	        if (best === null) { best = c; continue; }
   132	        const ec = epochOf(c), eb = epochOf(best);
   133	        if (ec !== eb) { if (ec > eb) best = c; continue; }
   134	        if (c.ts !== best.ts) { if (c.ts < best.ts) best = c; continue; }
   135	        if (c.agent < best.agent) best = c;
   136	      }
   137	      return best;
   138	    };
   139	
   140	    // Terminal (done/break) — FENCED. Only the owner AT THE TERMINAL'S ts, at an epoch
   141	    // >= that owner's, may terminate the task. The FIRST authorized terminal seals the
   142	    // token: any later terminal is post-terminal and skipped (the seal below rejects
   143	    // the post-terminal claim that begot it). Judging by owner-at-terminal-time (capped
   144	    // at the terminal's epoch) keeps the legitimate terminal authorized even when a
   145	    // higher-epoch reclaim lands later; the seal then rejects that reclaim.
   146	    let terminal = null;
   147	    for (const ev of evs) {
   148	      if (ev.type !== 'task.done' && ev.type !== 'task.circuit_break') continue;
   149	      if (terminal) continue; // already sealed by the first authorized terminal
   150	      const ownerAtTs = ownerAt(ev.ts, epochOf(ev));
   151	      const authorized = ownerAtTs && ev.agent === ownerAtTs.agent && epochOf(ev) >= epochOf(ownerAtTs);
   152	      if (authorized) { terminal = ev; continue; }
   153	      if (!winner) { rejections.push(makeRejection(ev, null, 'no-live-owner')); continue; }
   154	      if (isStaleWrite(ev)) rejections.push(makeRejection(ev, winner, staleReason(ev)));
   155	    }
   156	
   157	    // GH-41 (terminality-seal): once an authorized terminal exists the token is SEALED.
   158	    // Every later mutation on it — a `task.claimed` (reclaim), `task.released`, or
   159	    // `task.scope_changed` — is a reuse of a completed token, rejected with the new
   160	    // distinct lifecycle reason `claim-after-terminal` (NOT folded into stale-epoch/
   161	    // non-owner-agent, which are ownership/epoch failures) and never applied: `terminal`
   162	    // still wins the status below, and the walk-pass below skips these events so they
   163	    // can neither set handoff_to/scope nor double-log. "Later" = strictly after the
   164	    // terminal's ts, OR at the exact terminal ts but at an epoch above the terminal
   165	    // owner's (a same-ts higher-epoch reclaim — never the owner's own claim), which
   166	    // closes the ts==terminal.ts boundary. Rework of a completed unit must mint a fresh
   167	    // task id. Reorder-safe: a pure function of `terminal` + the event set.
   168	    const sealOwner = terminal ? ownerAt(terminal.ts, epochOf(terminal)) : null;
   169	    const sealOwnerEpoch = sealOwner ? epochOf(sealOwner) : 0;
   170	    const isPostTerminal = (ev) => !!terminal &&
   171	      (ev.ts > terminal.ts || (ev.ts === terminal.ts && epochOf(ev) > sealOwnerEpoch));
   172	    if (terminal) {
   173	      for (const ev of evs) {
   174	        if (ev.type !== 'task.claimed' && ev.type !== 'task.released' && ev.type !== 'task.scope_changed') continue;
   175	        if (isPostTerminal(ev)) rejections.push(makeRejection(ev, sealOwner, 'claim-after-terminal'));
   176	      }
   177	    }
   178	
   179	    // Walk events to set priority, paths, handoff_to, and (if winner exists)
   180	    // apply scope_changed updates from the current owner at the current epoch.
   181	    for (const ev of evs) {
   182	      switch (ev.type) {
   183	        case 'task.created':
   184	          if (ev.priority !== undefined) t.priority = ev.priority;
   185	          if (ev.paths) t.paths = ev.paths;
   186	          break;
   187	        case 'task.released':
   188	          if (isPostTerminal(ev)) break; // GH-41: sealed post-terminal mutation — rejected by the seal loop
   189	          // Releases are agent-scoped (a displaced owner's release only retires
   190	          // its own already-dead claim), so a stale release is inert against the
   191	          // current claim — but its handoff is fenced (threshold) and a genuine
   192	          // post-takeover replay is recorded for the audit log.
   193	          if (ev.to_agent && epochOf(ev) >= handoffThreshold) t.handoff_to = ev.to_agent;
   194	          if (isStaleWrite(ev)) rejections.push(makeRejection(ev, winner, 'stale-epoch-inert'));
   195	          break;
   196	        case 'task.scope_changed':
   197	          if (!ev.paths) break;
   198	          if (isPostTerminal(ev)) break; // GH-41: sealed post-terminal mutation — rejected by the seal loop
   199	          if (winner && ev.agent === winner.agent && epochOf(ev) >= ownerEpoch && ev.ts >= winner.ts) {
   200	            // Latest in-epoch scope_changed wins (replacement semantics).
   201	            t._scopedPaths = ev.paths;
   202	          } else if (isStaleWrite(ev)) {
   203	            rejections.push(makeRejection(ev, winner, staleReason(ev)));
   204	          }
   205	          break;
   206	      }
   207	    }
   208	
   209	    if (terminal) {
   210	      if (terminal.type === 'task.done') {
   211	        t.status = 'done';
   212	      } else {
   213	        t.status = 'circuit_broken';
   214	        t.break = { agent: terminal.agent, reason: terminal.reason || '' };
   215	      }
   216	    } else if (winner) {
   217	      t.status = 'claimed';
   218	      t.claim = {
   219	        agent: winner.agent,
   220	        paths: t._scopedPaths || winner.paths || [],
   221	        ts: winner.ts,
   222	        epoch: ownerEpoch,
   223	      };
   224	      // Once claimed, clear handoff_to (handoff was satisfied by the new claim).
   225	      // But if the latest event is a release-with-handoff after this claim,
   226	      // keep it. Walk events: take the last release.to_agent that occurred
   227	      // AFTER the winning claim.
   228	      let lateHandoff = null;
   229	      for (const ev of evs) {
   230	        // Only the current owner at the current epoch may re-hand-off a claimed
   231	        // task; a stale/foreign late release cannot redirect the reservation.
   232	        if (ev.type === 'task.released' && ev.to_agent && ev.ts > winner.ts
   233	            && ev.agent === winner.agent && epochOf(ev) >= ownerEpoch) {
   234	          lateHandoff = ev.to_agent;
   235	        }
   236	      }
   237	      t.handoff_to = lateHandoff; // null if no late handoff
   238	    }
   239	
   240	    delete t._scopedPaths;
   241	    tasks.set(taskId, t);
   242	  }
   243	
   244	  // Stable, arrival-order-independent ordering for the audit log.
   245	  rejections.sort((a, b) => {
   246	    if (a.ts !== b.ts) return a.ts < b.ts ? -1 : 1;
   247	    if (a.task !== b.task) return a.task < b.task ? -1 : 1;
   248	    if (a.type !== b.type) return a.type < b.type ? -1 : 1;
   249	    return a.fenced_agent < b.fenced_agent ? -1 : a.fenced_agent > b.fenced_agent ? 1 : 0;
   250	  });
   251	
   252	  return { tasks, rejections };
   253	}
   254	
   255	/**
   256	 * Back-compat thin wrapper over {@link foldWithMeta} that returns just the task map.
   257	 * @param {Object[]} events - as returned by {@link module:events.readAllEvents}
   258	 * @returns {Map<string, Object>} the projected task map, keyed by task id
   259	 */
   260	function fold(events) {
   261	  return foldWithMeta(events).tasks;
   262	}
   263	
   264	/**
   265	 * Next monotonic epoch for a fresh claim on `taskId`: one above the highest
   266	 * epoch any prior claim on that task has carried (so a reclaim after release/
   267	 * reap always strictly exceeds the displaced owner's). First claim ⇒ 1.
   268	 * @param {Object[]} events - as returned by {@link module:events.readAllEvents}
   269	 * @param {string} taskId
   270	 * @returns {number}
   271	 */
   272	function nextEpoch(events, taskId) {
   273	  let max = 0;
   274	  for (const ev of events) {
   275	    if (ev.type === 'task.claimed' && ev.task === taskId) {
   276	      const e = epochOf(ev);
   277	      if (e > max) max = e;
   278	    }
   279	  }
   280	  return max + 1;
   281	}
   282	
   283	/**
   284	 * Renders the projected task map as the human-readable `STATE.md` body.
   285	 * @param {Map<string, Object>} tasks - as returned by {@link fold}
   286	 * @returns {string} markdown, grouped into Open / Claimed / Done / Circuit-Broken
   287	 */
   288	function renderState(tasks) {
   289	  const lines = [];
   290	  lines.push('<!-- AUTO-GENERATED by `tick project` from .tick/events/. Do not edit by hand. -->');
   291	  lines.push('');
   292	  lines.push('# Coordination State');
   293	  lines.push('');
   294	
   295	  const all = Array.from(tasks.values()).sort((a, b) => a.id.localeCompare(b.id));
   296	  const open = all.filter(t => t.status === 'open');
   297	  const claimed = all.filter(t => t.status === 'claimed');
   298	  const done = all.filter(t => t.status === 'done');
   299	  const broken = all.filter(t => t.status === 'circuit_broken');
   300	
   301	  lines.push('## Open');
   302	  if (!open.length) lines.push('_(none)_');
   303	  for (const t of open) {
   304	    const handoff = t.handoff_to ? ` [handoff_to: ${t.handoff_to}]` : '';
   305	    const paths = t.paths.length ? ` paths: ${JSON.stringify(t.paths)}` : '';
     1	'use strict';
     2	
     3	const fs = require('fs');
     4	const path = require('path');
     5	
     6	// 0.2.0 — adds the optional `epoch` field to claim/mutation events (Part B
     7	// Phase 1, R1 epoch fencing). Events without `epoch` are read as epoch 0, so
     8	// pre-0.2.0 logs project identically. See decisions/2026-06-18-epoch-fencing.md.
     9	const SCHEMA_VERSION = '0.2.0';
    10	
    11	const EVENT_TYPES = new Set([
    12	  'task.created',
    13	  'task.claimed',
    14	  'task.released',
    15	  'task.scope_changed',
    16	  'task.commented',
    17	  'task.heartbeat',
    18	  'task.done',
    19	  'task.circuit_break',
    20	  // Cost signals (Phase 1, COST-OBSERVABILITY-PLAN). Deterministic, additive, ignored by the
    21	  // coordination metrics — they describe what a turn COST, not how it coordinated.
    22	  'cost.tokens',
    23	  'cost.human',
    24	  'cost.memory',
    25	  // Marathon phase-chain signals (Phase 3, marathon-drive.sh). Emitted at phase boundaries by
    26	  // marathon-drive, not by individual turn-takers. Not coordination signals — ignored by tick analyze.
    27	  'marathon.phase.start',
    28	  'marathon.phase.approved',
    29	  'marathon.phase.escalated',
    30	  'marathon.phase.revision',
    31	  'marathon.complete',
    32	  // Cross-agent dependency-drift signal (GH-68, warn-only Phase 1). Emitted by relay-turn-lib.sh
    33	  // post-commit when a landed turn changes a shared surface, so the NEXT agent's shim can inject a
    34	  // heads-up. Purely informational: carries no epoch, claims no task, is NOT a state-transition —
    35	  // the projection kernel ignores it exactly like cost.*/marathon.* signals.
    36	  // See decisions/2026-07-01-cross-agent-dep-conflict.md.
    37	  'dependency.drift',
    38	]);
    39	
    40	const CRITICAL_EVENTS = new Set([
    41	  'task.claimed',
    42	  'task.scope_changed',
    43	  'task.released',
    44	  'task.circuit_break',
    45	  'task.done',
    46	]);
    47	
    48	/**
    49	 * Path to the shared local event-log directory for a repo clone.
    50	 * @param {string} repoRoot - absolute path to the repo root
    51	 * @returns {string} absolute path to `<repoRoot>/.tick/events`
    52	 */
    53	function eventsDir(repoRoot) {
    54	  return path.join(repoRoot, '.tick', 'events');
    55	}
    56	
    57	/**
    58	 * Creates the events directory (and any missing parents) if it doesn't exist yet.
    59	 * @param {string} repoRoot - absolute path to the repo root
    60	 * @returns {void}
    61	 */
    62	function ensureEventsDir(repoRoot) {
    63	  fs.mkdirSync(eventsDir(repoRoot), { recursive: true });
    64	}
    65	
    66	/**
    67	 * Current timestamp in ISO-8601, overridable via `TICK_TS` for deterministic tests.
    68	 * @returns {string} ISO-8601 timestamp
    69	 */
    70	function isoNow() {
    71	  if (process.env.TICK_TS) return process.env.TICK_TS;
    72	  return new Date().toISOString();
    73	}
    74	
    75	function tsForFilename(iso) {
    76	  return iso.replace(/:/g, '-');
    77	}
    78	
    79	function safeSegment(s) {
    80	  return String(s).replace(/[^A-Za-z0-9._-]/g, '_');
    81	}
    82	
    83	/**
    84	 * Appends one event to the log as a new `.jsonl` file (one event per file — the
    85	 * projection's unit of atomicity). Fields present in the event depend on `type`;
    86	 * unset optional fields are omitted from the written JSON, not written as null,
    87	 * so unrelated event types stay byte-identical across schema additions.
    88	 *
    89	 * Publication is atomic (GH-14): the document is written to a `.tmp` name that
    90	 * {@link readAllEvents}' `.jsonl` filter never matches, then `rename(2)`d onto
    91	 * the final path, so concurrent readers either do not see the event yet or see
    92	 * the complete document — never a partial/empty file.
    93	 * @param {string} repoRoot - absolute path to the repo root
    94	 * @param {Object} fields
    95	 * @param {string} fields.type - one of {@link EVENT_TYPES}
    96	 * @param {string} fields.task - task id
    97	 * @param {string} fields.agent - acting agent id
    98	 * @param {string} [fields.note]
    99	 * @param {string[]} [fields.paths] - glob patterns the event declares/claims
   100	 * @param {string} [fields.to_agent] - handoff target (task.released)
   101	 * @param {string} [fields.reason] - circuit-break reason
   102	 * @param {number} [fields.priority]
   103	 * @param {number} [fields.epoch] - monotonic per-task ownership fence (R1)
   104	 * @param {number} [fields.tokens_in]
   105	 * @param {number} [fields.tokens_out]
   106	 * @param {number} [fields.tokens_total]
   107	 * @param {number} [fields.human_minutes]
   108	 * @param {string} [fields.tool]
   109	 * @param {string} [fields.surface] - dependency.drift: the shared surface that changed
   110	 * @param {string} [fields.prior_sha]
   111	 * @param {string} [fields.current_sha]
   112	 * @param {number} [fields.diff_lines]
   113	 * @param {string} [fields.turn]
   114	 * @returns {{path: string, event: Object}} the written file path and the event object
   115	 * @throws {Error} if `type` is unrecognized, or `task`/`agent` is missing
   116	 */
   117	function appendEvent(repoRoot, {
   118	  type, task, agent, note, paths, to_agent, reason, priority, epoch,
   119	  tokens_in, tokens_out, tokens_total, human_minutes, tool,
   120	  compressor_mb, swap_free_mb, peak_rss_mb,
   121	  surface, prior_sha, current_sha, diff_lines, turn,
   122	}) {
   123	  if (!EVENT_TYPES.has(type)) {
   124	    throw new Error(`unknown event type: ${type}`);
   125	  }
   126	  if (!task) throw new Error('task is required');
   127	  if (!agent) throw new Error('agent is required');
   128	
   129	  ensureEventsDir(repoRoot);
   130	
   131	  const ts = isoNow();
   132	  const action = type.replace(/^(task|cost)\./, '');
   133	  const fname = `${tsForFilename(ts)}-${safeSegment(agent)}-${safeSegment(action)}-${safeSegment(task)}.jsonl`;
   134	  const fpath = path.join(eventsDir(repoRoot), fname);
   135	
   136	  const event = {
   137	    schema_version: SCHEMA_VERSION,
   138	    ts,
   139	    type,
   140	    task,
   141	    agent,
   142	  };
   143	  if (paths) event.paths = paths;
   144	  if (note !== undefined) event.note = note;
   145	  if (to_agent) event.to_agent = to_agent;
   146	  if (reason !== undefined) event.reason = reason;
   147	  if (priority !== undefined) event.priority = priority;
   148	  // Epoch fencing token (R1). Stamped on task.claimed (the owner's epoch) and on
   149	  // the owner's mutations; absent ⇒ epoch 0, so legacy events stay byte-stable.
   150	  if (epoch !== undefined) event.epoch = epoch;
   151	  // Cost fields — only stamped when present, so non-cost events stay byte-identical to before.
   152	  if (tokens_in !== undefined) event.tokens_in = tokens_in;
   153	  if (tokens_out !== undefined) event.tokens_out = tokens_out;
   154	  if (tokens_total !== undefined) event.tokens_total = tokens_total;
   155	  if (human_minutes !== undefined) event.human_minutes = human_minutes;
   156	  if (tool !== undefined) event.tool = tool;
   157	  if (compressor_mb !== undefined) event.compressor_mb = compressor_mb;
   158	  if (swap_free_mb !== undefined) event.swap_free_mb = swap_free_mb;
   159	  if (peak_rss_mb !== undefined) event.peak_rss_mb = peak_rss_mb;
   160	  // Dependency-drift fields (GH-68) — only stamped for dependency.drift events, so every other
   161	  // event type stays byte-identical to before.
   162	  if (surface !== undefined) event.surface = surface;
   163	  if (prior_sha !== undefined) event.prior_sha = prior_sha;
   164	  if (current_sha !== undefined) event.current_sha = current_sha;
   165	  if (diff_lines !== undefined) event.diff_lines = diff_lines;
   166	  if (turn !== undefined) event.turn = turn;
   167	
   168	  // Atomic publish (GH-14): write to a name readAllEvents' `.jsonl` filter never
   169	  // matches, then rename(2) into place — rename is atomic within a filesystem, so
   170	  // a concurrent reader observes either no file or the complete document, never a
   171	  // torn one. A crash between the two calls leaves at most an invisible `.tmp`.
   172	  const tmp = fpath + '.tmp';
   173	  fs.writeFileSync(tmp, JSON.stringify(event) + '\n');
   174	  fs.renameSync(tmp, fpath);
   175	  return { path: fpath, event };
   176	}
   177	
   178	/**
   179	 * Reads every event in the log, sorted by filename (which encodes ISO timestamp),
   180	 * so callers see events in chronological arrival order.
   181	 * @param {string} repoRoot - absolute path to the repo root
   182	 * @returns {Object[]} parsed event objects, each carrying a `_file` provenance field
   183	 */
   184	function readAllEvents(repoRoot) {
   185	  const dir = eventsDir(repoRoot);
   186	  if (!fs.existsSync(dir)) return [];
   187	  const files = fs.readdirSync(dir).filter(f => f.endsWith('.jsonl')).sort();
   188	  return files.map(f => {
   189	    const raw = fs.readFileSync(path.join(dir, f), 'utf8').trim();
   190	    const ev = JSON.parse(raw);
   191	    ev._file = f;
   192	    return ev;
   193	  });
   194	}
   195	
   196	module.exports = {
   197	  SCHEMA_VERSION,
   198	  EVENT_TYPES,
   199	  CRITICAL_EVENTS,
   200	  appendEvent,
   201	  readAllEvents,
   202	  eventsDir,
   203	  ensureEventsDir,
   204	  isoNow,
   205	};
     1	'use strict';
     2	
     3	const { appendEvent, readAllEvents } = require('./events');
     4	const { project, fold, nextEpoch, activeClaimsForAgent, MAX_ACTIVE_CLAIMS_PER_AGENT } = require('./project');
     5	const { setsOverlap } = require('./paths');
     6	const { withClaimLock } = require('./lock');
     7	
     8	// Atomic next+claim under one lock. Eliminates the TOCTOU gap between
     9	// `tick next` and `tick claim` where another agent can snatch the task
    10	// between the two calls.
    11	//
    12	// Uses the task's own declared paths as the claim paths (the agent can call
    13	// `tick scope` afterward if they need to narrow or expand).
    14	/**
    15	 * Atomically picks the next available task for `agent` and claims it.
    16	 * @param {string} repoRoot - absolute path to the repo root
    17	 * @param {Object} opts
    18	 * @param {string} opts.agent - the claiming agent
    19	 * @returns {{won: true, task: string, priority: number, handoff: boolean}
    20	 *         | {won: false, noTask: true}
    21	 *         | {limitReached: true, holding: string[]}}
    22	 */
    23	function take(repoRoot, { agent }) {
    24	  return withClaimLock(repoRoot, () => {
    25	    const events = readAllEvents(repoRoot);
    26	    const tasks = fold(events);
    27	
    28	    const held = activeClaimsForAgent(tasks, agent);
    29	    if (held.length >= MAX_ACTIVE_CLAIMS_PER_AGENT) {
    30	      return { limitReached: true, holding: held };
    31	    }
    32	
    33	    // Exclude paths held by ANY active claim — other agents (lane separation)
    34	    // *and* this agent's own (anti-gaming: stops one agent reserving two
    35	    // overlapping tasks in the same half and working them serially, which
    36	    // would inflate the concurrent-claim metric without real parallel work).
    37	    const claimedPaths = [];
    38	    for (const t of tasks.values()) {
    39	      if (t.status === 'claimed') {
    40	        for (const p of t.claim.paths) claimedPaths.push(p);
    41	      }
    42	    }
    43	
    44	    const candidates = [];
    45	    for (const t of tasks.values()) {
    46	      if (t.status !== 'open') continue;
    47	      if (setsOverlap(t.paths, claimedPaths)) continue;
    48	      if (t.handoff_to && t.handoff_to !== agent) continue;
    49	      candidates.push(t);
    50	    }
    51	
    52	    const handoffs = candidates.filter(t => t.handoff_to === agent);
    53	    let chosen;
    54	    if (handoffs.length) {
    55	      handoffs.sort((a, b) => b.priority - a.priority || a.id.localeCompare(b.id));
    56	      chosen = handoffs[0];
    57	    } else {
    58	      candidates.sort((a, b) => b.priority - a.priority || a.id.localeCompare(b.id));
    59	      chosen = candidates[0] || null;
    60	    }
    61	
    62	    if (!chosen) return { won: false, noTask: true };
    63	
    64	    appendEvent(repoRoot, { type: 'task.claimed', task: chosen.id, agent, paths: chosen.paths, epoch: nextEpoch(events, chosen.id) });
    65	    project(repoRoot);
    66	    return { won: true, task: chosen.id, priority: chosen.priority, handoff: chosen.handoff_to === agent };
    67	  });
    68	}
    69	
    70	module.exports = { take };
     1	'use strict';
     2	
     3	const { fold, activeClaimsForAgent, MAX_ACTIVE_CLAIMS_PER_AGENT } = require('./project');
     4	const { readAllEvents } = require('./events');
     5	const { setsOverlap } = require('./paths');
     6	
     7	// Run 2: no git transport — reads the shared local .tick/events/ directly.
     8	// Read-only: folds events in memory without writing STATE.md.
     9	/**
    10	 * Looks up (without claiming) the next available task for `agent`:
    11	 * 0. If the agent is already at the claim cap, returns `{ limitReached }` —
    12	 *    don't route new work until a slot is freed.
    13	 * 1. A targeted handoff to this agent wins immediately.
    14	 * 2. Otherwise, the highest-priority open task whose paths don't overlap any
    15	 *    currently-claimed paths held by *other* agents.
    16	 * @param {string} repoRoot - absolute path to the repo root
    17	 * @param {Object} opts
    18	 * @param {string} opts.agent
    19	 * @returns {Object|null} the chosen task, `{limitReached: true, holding: string[]}`, or `null` if none available
    20	 */
    21	function next(repoRoot, { agent }) {
    22	  const tasks = fold(readAllEvents(repoRoot));
    23	
    24	  // Per-agent claim cap: an agent at the cap is not routed new work.
    25	  const held = activeClaimsForAgent(tasks, agent);
    26	  if (held.length >= MAX_ACTIVE_CLAIMS_PER_AGENT) {
    27	    return { limitReached: true, holding: held };
    28	  }
    29	
    30	  const claimedByOthers = [];
    31	  for (const t of tasks.values()) {
    32	    if (t.status === 'claimed' && t.claim.agent !== agent) {
    33	      for (const p of t.claim.paths) claimedByOthers.push(p);
    34	    }
    35	  }
    36	
    37	  const candidates = [];
    38	  for (const t of tasks.values()) {
    39	    if (t.status !== 'open') continue;
    40	    if (setsOverlap(t.paths, claimedByOthers)) continue;
    41	    candidates.push(t);
    42	  }
    43	
    44	  // Prioritize targeted handoffs to this agent.
    45	  const handoffs = candidates.filter(t => t.handoff_to === agent);
    46	  if (handoffs.length) {
    47	    handoffs.sort((a, b) => b.priority - a.priority || a.id.localeCompare(b.id));
    48	    return handoffs[0];
    49	  }
    50	
    51	  candidates.sort((a, b) => b.priority - a.priority || a.id.localeCompare(b.id));
    52	  return candidates[0] || null;
    53	}
    54	
    55	module.exports = { next };
     1	#!/usr/bin/env bash
     2	# AC #1: two agents race to claim the same task. The O_EXCL lock serialises
     3	# them — first writer wins, second gets "lost". No timestamp tie-breaker
     4	# exists in local transport; the lock is the sole arbiter.
     5	source "$(dirname "$0")/_setup.sh" concurrent-claim
     6	
     7	tick_a init >/dev/null
     8	TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-007 --agent dispatcher --priority 10 --paths "src/auth/**" >/dev/null
     9	
    10	# Alice claims first.
    11	tick_a claim TASK-007 --agent alice --paths "src/auth/**" >"$WORK/a.out"
    12	if grep -q "^won:" "$WORK/a.out"; then
    13	  pass "alice won the claim"
    14	else
    15	  fail "expected alice to win; got: $(cat "$WORK/a.out")"
    16	fi
    17	
    18	# Bob tries to claim the same task — must lose.
    19	tick_b claim TASK-007 --agent bob --paths "src/auth/**" >"$WORK/b.out"
    20	if grep -q "^lost:" "$WORK/b.out"; then
    21	  pass "bob lost the claim (task already held by alice)"
    22	else
    23	  fail "expected bob to lose; got: $(cat "$WORK/b.out")"
    24	fi
    25	
    26	# STATE.md must show exactly alice as claimer.
    27	tick_a project >/dev/null
    28	if grep -E "^- TASK-007 by alice" "$A/.tick/STATE.md" >/dev/null; then
    29	  pass "STATE.md shows TASK-007 claimed by alice"
    30	else
    31	  cat "$A/.tick/STATE.md"; fail "STATE.md does not show alice as winner"
    32	fi
    33	
    34	# Idempotent re-claim by alice returns won.
    35	tick_a claim TASK-007 --agent alice --paths "src/auth/**" >"$WORK/a2.out"
    36	if grep -q "^won:" "$WORK/a2.out"; then
    37	  pass "alice's idempotent re-claim returns won"
    38	else
    39	  fail "idempotent re-claim failed: $(cat "$WORK/a2.out")"
    40	fi
    41	
    42	# Terminal task can't be claimed.
    43	tick_a done TASK-007 --agent alice >/dev/null
    44	tick_a claim TASK-007 --agent bob --paths "src/auth/**" >"$WORK/done.out"
    45	if grep -q "^lost:.*done" "$WORK/done.out"; then
    46	  pass "done task returns lost with unavailable=done"
    47	else
    48	  fail "done task claim unexpected: $(cat "$WORK/done.out")"
    49	fi
    50	
    51	echo "  $TEST_NAME: $PASS pass, $FAIL fail"
    52	exit 0
nl: test/ownership.sh: No such file or directory

2026-08-17T20:10:01.635168Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 96 column 5
exec
/bin/zsh -lc "nl -ba test/gh23-path-overlap-enforcement.sh; nl -ba src/paths.js; nl -ba src/lock.js; nl -ba src/project.js | sed -n '1,264p'; rg -n \"function parseArgs|function parsePathsFlag|flags\\.force|--force\" bin/tick test src; rg -n \"tick .*claim|tick .*scope|scope .*paths|claim .*paths\" test --glob '*.sh' | head -300; rg -n \"gh23-path-overlap|concurrent-claim|chaos-stale-writer\" validate.sh ci-local.sh package.json .github/workflows/ci.yml" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# GH-23: Enforce path-overlap rejection on direct tick claim and tick scope.
     3	source "$(dirname "$0")/_setup.sh" gh23-path-overlap-enforcement
     4	
     5	tick_a init >/dev/null
     6	
     7	# 1. Setup tasks
     8	TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-101 --agent dispatcher --paths "src/auth/**" >/dev/null
     9	TICK_TS=2026-05-04T10:00:01.000Z tick_a log task.created TASK-102 --agent dispatcher --paths "src/auth/login.js" >/dev/null
    10	TICK_TS=2026-05-04T10:00:02.000Z tick_a log task.created TASK-103 --agent dispatcher --paths "src/billing/**" >/dev/null
    11	
    12	# Alice claims TASK-101 with src/auth/**
    13	tick_a claim TASK-101 --agent alice --paths "src/auth/**" >/dev/null
    14	if [ $? -eq 0 ]; then
    15	  pass "alice successfully claimed TASK-101"
    16	else
    17	  fail "alice failed to claim TASK-101"
    18	fi
    19	
    20	# 2. Bob attempts direct claim on TASK-102 (src/auth/login.js) -> MUST FAIL due to overlap with Alice
    21	BOB_OUT=$(tick_b claim TASK-102 --agent bob --paths "src/auth/login.js" 2>&1)
    22	BOB_STATUS=$?
    23	if [ $BOB_STATUS -ne 0 ] && echo "$BOB_OUT" | grep -q "paths overlap active claim"; then
    24	  pass "direct claim on overlapping task TASK-102 rejected (exit $BOB_STATUS): $BOB_OUT"
    25	else
    26	  fail "direct claim on overlapping task was not rejected! status=$BOB_STATUS out=$BOB_OUT"
    27	fi
    28	
    29	# 3. Bob uses --force -> MUST SUCCEED
    30	BOB_FORCE_OUT=$(tick_b claim TASK-102 --agent bob --paths "src/auth/login.js" --force 2>&1)
    31	BOB_FORCE_STATUS=$?
    32	if [ $BOB_FORCE_STATUS -eq 0 ] && echo "$BOB_FORCE_OUT" | grep -q "won: TASK-102 claimed by bob"; then
    33	  pass "direct claim with --force succeeded: $BOB_FORCE_OUT"
    34	else
    35	  fail "direct claim with --force failed! status=$BOB_FORCE_STATUS out=$BOB_FORCE_OUT"
    36	fi
    37	
    38	# Bob releases TASK-102
    39	tick_b release TASK-102 --agent bob >/dev/null
    40	
    41	# 4. Bob claims TASK-103 (src/billing/**) -> non-overlapping, MUST SUCCEED
    42	tick_b claim TASK-103 --agent bob --paths "src/billing/**" >/dev/null
    43	if [ $? -eq 0 ]; then
    44	  pass "bob claimed non-overlapping TASK-103"
    45	else
    46	  fail "bob failed to claim TASK-103"
    47	fi
    48	
    49	# 5. Bob attempts tick scope on TASK-103 to include "src/auth/oauth.js" -> MUST FAIL due to overlap with Alice
    50	SCOPE_OUT=$(tick_b scope TASK-103 --agent bob --paths "src/billing/**,src/auth/oauth.js" 2>&1)
    51	SCOPE_STATUS=$?
    52	if [ $SCOPE_STATUS -ne 0 ] && echo "$SCOPE_OUT" | grep -q "paths overlap active claim"; then
    53	  pass "scope expansion into overlapping paths rejected (exit $SCOPE_STATUS): $SCOPE_OUT"
    54	else
    55	  fail "scope expansion into overlapping paths was not rejected! status=$SCOPE_STATUS out=$SCOPE_OUT"
    56	fi
    57	
    58	# 6. Bob uses tick scope --force -> MUST SUCCEED
    59	SCOPE_FORCE_OUT=$(tick_b scope TASK-103 --agent bob --paths "src/billing/**,src/auth/oauth.js" --force 2>&1)
    60	SCOPE_FORCE_STATUS=$?
    61	if [ $SCOPE_FORCE_STATUS -eq 0 ] && echo "$SCOPE_FORCE_OUT" | grep -q "scoped: TASK-103"; then
    62	  pass "scope expansion with --force succeeded: $SCOPE_FORCE_OUT"
    63	else
    64	  fail "scope expansion with --force failed! status=$SCOPE_FORCE_STATUS out=$SCOPE_FORCE_OUT"
    65	fi
    66	
    67	# 7. Alice completes TASK-101
    68	tick_a done TASK-101 --agent alice --note "auth done" >/dev/null
    69	
    70	# 8. Dispatcher creates TASK-104 with src/auth/**. Charlie claims it without --force -> MUST SUCCEED now that Alice finished
    71	TICK_TS=2026-05-04T10:00:10.000Z tick_a log task.created TASK-104 --agent dispatcher --paths "src/auth/register.js" >/dev/null
    72	# Bob still holds src/auth/oauth.js from forced scope above, but src/admin/** is free
    73	TICK_TS=2026-05-04T10:00:11.000Z tick_a log task.created TASK-105 --agent dispatcher --paths "src/admin/**" >/dev/null
    74	CHARLIE_OUT=$(tick_b claim TASK-105 --agent charlie --paths "src/admin/**" 2>&1)
    75	if [ $? -eq 0 ]; then
    76	  pass "charlie claimed non-overlapping TASK-105"
    77	else
    78	  fail "charlie failed to claim TASK-105: $CHARLIE_OUT"
    79	fi
    80	
    81	# 9. Idempotent re-claim: Charlie re-claims own held task -> MUST SUCCEED (won)
    82	CHARLIE_RECLAIM=$(tick_b claim TASK-105 --agent charlie --paths "src/admin/**" 2>&1)
    83	if [ $? -eq 0 ] && echo "$CHARLIE_RECLAIM" | grep -q "won: TASK-105 claimed by charlie"; then
    84	  pass "idempotent re-claim by current holder succeeded without self-overlap rejection"
    85	else
    86	  fail "idempotent re-claim failed! out=$CHARLIE_RECLAIM"
    87	fi
    88	
    89	echo "  $TEST_NAME: $PASS pass, $FAIL fail"
    90	[ "$FAIL" -eq 0 ] || exit 1
    91	exit 0
     1	'use strict';
     2	
     3	// Conservative path-overlap detection for the spike.
     4	// Two glob patterns "overlap" if there exists at least one path matching both.
     5	// We don't fully decide intersection of arbitrary globs; we use a sound but
     6	// conservative test: convert each pattern to a literal prefix (text up to the
     7	// first wildcard char), then declare overlap iff one prefix is a prefix of the
     8	// other. This may report overlap when there isn't one (false positive = safer)
     9	// but never misses a real overlap.
    10	
    11	/**
    12	 * The literal (non-wildcard) prefix of a glob pattern — the text before the
    13	 * first `*`, `?`, `[`, or `{`.
    14	 * @param {string} glob
    15	 * @returns {string}
    16	 */
    17	function literalPrefix(glob) {
    18	  const m = glob.match(/^([^*?[{]*)/);
    19	  return m ? m[1] : '';
    20	}
    21	
    22	/**
    23	 * Conservative overlap test between two glob patterns: true if either
    24	 * pattern's literal prefix is a prefix of the other's. Sound but not exact —
    25	 * may false-positive (safer for claim exclusivity), never false-negatives a
    26	 * real overlap.
    27	 * @param {string} a
    28	 * @param {string} b
    29	 * @returns {boolean}
    30	 */
    31	function patternsOverlap(a, b) {
    32	  const pa = literalPrefix(a);
    33	  const pb = literalPrefix(b);
    34	  return pa.startsWith(pb) || pb.startsWith(pa);
    35	}
    36	
    37	/**
    38	 * True if any pattern in `setA` overlaps (per {@link patternsOverlap}) any
    39	 * pattern in `setB`.
    40	 * @param {string[]} setA
    41	 * @param {string[]} setB
    42	 * @returns {boolean}
    43	 */
    44	function setsOverlap(setA, setB) {
    45	  if (!setA || !setB || !setA.length || !setB.length) return false;
    46	  for (const a of setA) {
    47	    for (const b of setB) {
    48	      if (patternsOverlap(a, b)) return true;
    49	    }
    50	  }
    51	  return false;
    52	}
    53	
    54	// Glob-to-regex for matching a literal file path against a glob pattern.
    55	// Handles **, *, ?. No brace/char-class support — keep it small for the spike.
    56	/**
    57	 * Compiles a glob pattern (`**`, `*`, `?`) into an anchored RegExp for
    58	 * matching a literal file path. No brace/char-class support.
    59	 * @param {string} glob
    60	 * @returns {RegExp}
    61	 */
    62	function globToRegex(glob) {
    63	  let re = '';
    64	  for (let i = 0; i < glob.length; i++) {
    65	    const ch = glob[i];
    66	    if (ch === '*') {
    67	      if (glob[i + 1] === '*') {
    68	        re += '.*';
    69	        i++;
    70	        // consume optional trailing slash so foo/** matches foo (no trailing /)
    71	        if (glob[i + 1] === '/') i++;
    72	      } else {
    73	        re += '[^/]*';
    74	      }
    75	    } else if (ch === '?') {
    76	      re += '[^/]';
    77	    } else if ('.+^$()[]{}|\\'.includes(ch)) {
    78	      re += '\\' + ch;
    79	    } else {
    80	      re += ch;
    81	    }
    82	  }
    83	  return new RegExp('^' + re + '$');
    84	}
    85	
    86	/**
    87	 * True if `file` matches any pattern in `globs` (via {@link globToRegex}).
    88	 * @param {string} file - literal file path
    89	 * @param {string[]} globs
    90	 * @returns {boolean}
    91	 */
    92	function matchesAny(file, globs) {
    93	  if (!globs || !globs.length) return false;
    94	  return globs.some(g => globToRegex(g).test(file));
    95	}
    96	
    97	module.exports = { patternsOverlap, setsOverlap, literalPrefix, globToRegex, matchesAny };
     1	'use strict';
     2	
     3	const fs = require('fs');
     4	const path = require('path');
     5	
     6	// Claim-cycle atomicity (Run 2, P2).
     7	//
     8	// `tick claim` does project(read) -> cap-check -> appendEvent(write). That is a
     9	// TOCTOU window: two concurrent `tick claim` processes for the SAME agent could
    10	// both pass the cap check before either writes, busting the cap.
    11	//
    12	// Fix: a per-clone O_EXCL lock serialises one agent's own claim calls. The
    13	// lock lives under .tick/locks/ (never committed; directory is in .gitignore)
    14	// instead of .git/ so sandbox environments that restrict .git/ writes don't
    15	// block normal tick operation.
    16	//
    17	// Known limitation: a hard process kill mid-claim leaves a stale lock. Recovery
    18	// is `rm <repo>/.tick/locks/claim.lock`. Stale-detection is Phase 2.
    19	
    20	/**
    21	 * Path to the per-clone claim lock file, creating its parent directory if needed.
    22	 * @param {string} repoRoot - absolute path to the repo root
    23	 * @returns {string} absolute path to `<repoRoot>/.tick/locks/claim.lock`
    24	 */
    25	function lockPath(repoRoot) {
    26	  const locksDir = path.join(repoRoot, '.tick', 'locks');
    27	  fs.mkdirSync(locksDir, { recursive: true });
    28	  return path.join(locksDir, 'claim.lock');
    29	}
    30	
    31	/**
    32	 * Runs `fn` while holding the per-clone claim lock. `fs.openSync(.., 'wx')` is an
    33	 * atomic create-or-fail (O_EXCL): if the lock already exists it throws EEXIST.
    34	 * The lock is always released (closed + unlinked) before returning, including on throw.
    35	 * @param {string} repoRoot - absolute path to the repo root
    36	 * @param {function(): *} fn - callback to run while the lock is held
    37	 * @returns {*} whatever `fn` returns
    38	 * @throws {Error} if the lock is already held by another process
    39	 */
    40	function withClaimLock(repoRoot, fn) {
    41	  const lp = lockPath(repoRoot);
    42	  let fd;
    43	  try {
    44	    fd = fs.openSync(lp, 'wx');
    45	  } catch (err) {
    46	    if (err.code === 'EEXIST') {
    47	      throw new Error(
    48	        'another tick claim is in progress for this clone (lock held) — retry shortly, ' +
    49	        `or remove ${path.relative(repoRoot, lp)} if a prior claim was killed`
    50	      );
    51	    }
    52	    throw err;
    53	  }
    54	  try {
    55	    fs.writeSync(fd, String(process.pid));
    56	    return fn();
    57	  } finally {
    58	    fs.closeSync(fd);
    59	    try { fs.unlinkSync(lp); } catch { /* best-effort */ }
    60	  }
    61	}
    62	
    63	module.exports = { withClaimLock, lockPath };
     1	'use strict';
     2	
     3	const fs = require('fs');
     4	const path = require('path');
     5	const { readAllEvents } = require('./events');
     6	
     7	// Build deterministic state from all events.
     8	//
     9	// Ownership is fenced by a monotonic per-task EPOCH (R1, Part B Phase 1). Each
    10	// task.claimed carries an `epoch`; a takeover (reap → reclaim) raises it. The
    11	// current owner is the live claim with the HIGHEST epoch (ties: earliest ts,
    12	// then lexicographically smallest agent id — the legacy tie-breaker, reached
    13	// only when every epoch is equal, e.g. pre-0.2.0 logs that are all epoch 0).
    14	//
    15	// A mutating event (done / circuit_break / scope_changed / released) is honoured
    16	// ONLY when it is emitted by the current owner at an epoch >= the owner's. A
    17	// lower-epoch or non-owner mutation is REJECTED — recorded in the rejection log,
    18	// never applied. This is the kernel fence that stops a revived zombie writer
    19	// from advancing or corrupting a task it no longer owns: convention-free,
    20	// replay-deterministic (the verdict is a pure function of the event set, so it
    21	// is identical on every projection regardless of arrival order).
    22	
    23	function epochOf(ev) {
    24	  return Number.isFinite(ev.epoch) ? ev.epoch : 0;
    25	}
    26	
    27	function makeRejection(ev, winner, reason) {
    28	  return {
    29	    ts: ev.ts,
    30	    task: ev.task,
    31	    type: ev.type,
    32	    fenced_agent: ev.agent,
    33	    fenced_epoch: epochOf(ev),
    34	    owner_agent: winner ? winner.agent : null,
    35	    owner_epoch: winner ? epochOf(winner) : null,
    36	    reason,
    37	    file: ev._file || null,
    38	  };
    39	}
    40	
    41	/**
    42	 * Projects the ordered event log into current task state, applying the epoch
    43	 * fence (see file header) to reject stale/non-owner mutations. Pure function
    44	 * of the event set — replay-deterministic regardless of arrival order.
    45	 * @param {Object[]} events - as returned by {@link module:events.readAllEvents}, chronological order
    46	 * @returns {{tasks: Map<string, Object>, rejections: Object[]}} the projected
    47	 *   task map (keyed by task id) and the deterministic, ts-sorted list of fenced
    48	 *   (rejected) mutation events
    49	 */
    50	function foldWithMeta(events) {
    51	  // Bucket events per task in chronological order (events are pre-sorted by
    52	  // filename, which encodes ISO ts).
    53	  const byTask = new Map();
    54	  for (const ev of events) {
    55	    // dependency.drift (GH-68) is a purely informational cross-agent signal: it claims no task and is
    56	    // not a coordination event, so it must never seed or mutate a projected task — its synthetic task
    57	    // id (e.g. 'post-commit') would otherwise surface as a phantom `open` task in `tick project`/`next`.
    58	    // It is consumed directly from .tick/events/ by the shims' drift-brief reader, never via the fold.
    59	    // See decisions/2026-07-01-cross-agent-dep-conflict.md.
    60	    if (ev.type === 'dependency.drift') continue;
    61	    if (!byTask.has(ev.task)) byTask.set(ev.task, []);
    62	    byTask.get(ev.task).push(ev);
    63	  }
    64	
    65	  const tasks = new Map();
    66	  const rejections = [];
    67	
    68	  for (const [taskId, evs] of byTask) {
    69	    const t = {
    70	      id: taskId,
    71	      priority: 0,
    72	      paths: [],
    73	      status: 'open',
    74	      claim: null,
    75	      break: null,
    76	      handoff_to: null,
    77	    };
    78	
    79	    // Determine the live-claim winner: among claims whose agent has not
    80	    // subsequently released (ts >= the claim's), the highest epoch wins.
    81	    const claims = evs.filter(e => e.type === 'task.claimed');
    82	    const releases = evs.filter(e => e.type === 'task.released');
    83	    // A release retires a claim only if it is from the same agent, at or after
    84	    // the claim, AND at an epoch >= the claim's. The epoch guard is load-bearing:
    85	    // without it a revived writer's replayed lower-epoch release would retire the
    86	    // current (higher-epoch) claim it shares an id with — the same-id keystone.
    87	    const liveClaims = claims.filter(c =>
    88	      !releases.some(r => r.agent === c.agent && r.ts >= c.ts && epochOf(r) >= epochOf(c))
    89	    );
    90	    liveClaims.sort((a, b) => {
    91	      const ea = epochOf(a), eb = epochOf(b);
    92	      if (ea !== eb) return eb - ea; // highest epoch is the current owner
    93	      if (a.ts !== b.ts) return a.ts < b.ts ? -1 : 1;
    94	      return a.agent < b.agent ? -1 : a.agent > b.agent ? 1 : 0;
    95	    });
    96	    const winner = liveClaims[0] || null;
    97	    const ownerEpoch = winner ? epochOf(winner) : 0;
    98	    const maxClaimEpoch = claims.reduce((m, c) => Math.max(m, epochOf(c)), 0);
    99	    // A handoff (release --to) is honoured only from the latest epoch — the
   100	    // current owner, or (once released) the most recent epoch-holder. This stops
   101	    // a displaced writer from redirecting the reservation to an accomplice.
   102	    const handoffThreshold = winner ? ownerEpoch : maxClaimEpoch;
   103	
   104	    // Why the `ev.ts > winner.ts` guard on logging: an event that predates the
   105	    // current owner's claim is legitimate prior-epoch history (the reap/handoff
   106	    // release that retired the old claim, the old owner's scope) and is silently
   107	    // superseded — not a fence-firing. Only a mutation that lands AFTER ownership
   108	    // moved on is a genuine stale-writer attempt worth recording.
   109	    const isStaleWrite = (ev) => winner && ev.ts > winner.ts &&
   110	      (ev.agent !== winner.agent || epochOf(ev) < ownerEpoch);
   111	    // Most-specific reason: a different agent is a non-owner; a same-id writer
   112	    // below the owner's epoch is the keystone stale-epoch case.
   113	    const staleReason = (ev) =>
   114	      ev.agent !== winner.agent ? 'non-owner-agent' : 'stale-epoch';
   115	
   116	    // GH-41 (terminality-seal): the owner AS OF a given ts — the highest-epoch claim
   117	    // ACTIVE at that ts (placed at ts' <= ts and not retired by a same-agent release
   118	    // at ts'' <= ts, epoch >= the claim's), optionally capped at `maxEpoch`. It must
   119	    // be computed from the claim set at that instant, NOT the globally-filtered
   120	    // `liveClaims`: a claim that a *later* release retires is absent from liveClaims,
   121	    // so authorizing a terminal against liveClaims would let a release that lands
   122	    // AFTER the terminal retroactively de-authorize it (a done->open corruption).
   123	    // The `maxEpoch` cap (used with the terminal's own epoch) closes the boundary
   124	    // where a same-ts higher-epoch reclaim would otherwise masquerade as the owner.
   125	    const ownerAt = (ts, maxEpoch) => {
   126	      let best = null;
   127	      for (const c of claims) {
   128	        if (c.ts > ts) continue;
   129	        if (maxEpoch !== undefined && epochOf(c) > maxEpoch) continue;
   130	        if (releases.some(r => r.agent === c.agent && r.ts >= c.ts && r.ts <= ts && epochOf(r) >= epochOf(c))) continue;
   131	        if (best === null) { best = c; continue; }
   132	        const ec = epochOf(c), eb = epochOf(best);
   133	        if (ec !== eb) { if (ec > eb) best = c; continue; }
   134	        if (c.ts !== best.ts) { if (c.ts < best.ts) best = c; continue; }
   135	        if (c.agent < best.agent) best = c;
   136	      }
   137	      return best;
   138	    };
   139	
   140	    // Terminal (done/break) — FENCED. Only the owner AT THE TERMINAL'S ts, at an epoch
   141	    // >= that owner's, may terminate the task. The FIRST authorized terminal seals the
   142	    // token: any later terminal is post-terminal and skipped (the seal below rejects
   143	    // the post-terminal claim that begot it). Judging by owner-at-terminal-time (capped
   144	    // at the terminal's epoch) keeps the legitimate terminal authorized even when a
   145	    // higher-epoch reclaim lands later; the seal then rejects that reclaim.
   146	    let terminal = null;
   147	    for (const ev of evs) {
   148	      if (ev.type !== 'task.done' && ev.type !== 'task.circuit_break') continue;
   149	      if (terminal) continue; // already sealed by the first authorized terminal
   150	      const ownerAtTs = ownerAt(ev.ts, epochOf(ev));
   151	      const authorized = ownerAtTs && ev.agent === ownerAtTs.agent && epochOf(ev) >= epochOf(ownerAtTs);
   152	      if (authorized) { terminal = ev; continue; }
   153	      if (!winner) { rejections.push(makeRejection(ev, null, 'no-live-owner')); continue; }
   154	      if (isStaleWrite(ev)) rejections.push(makeRejection(ev, winner, staleReason(ev)));
   155	    }
   156	
   157	    // GH-41 (terminality-seal): once an authorized terminal exists the token is SEALED.
   158	    // Every later mutation on it — a `task.claimed` (reclaim), `task.released`, or
   159	    // `task.scope_changed` — is a reuse of a completed token, rejected with the new
   160	    // distinct lifecycle reason `claim-after-terminal` (NOT folded into stale-epoch/
   161	    // non-owner-agent, which are ownership/epoch failures) and never applied: `terminal`
   162	    // still wins the status below, and the walk-pass below skips these events so they
   163	    // can neither set handoff_to/scope nor double-log. "Later" = strictly after the
   164	    // terminal's ts, OR at the exact terminal ts but at an epoch above the terminal
   165	    // owner's (a same-ts higher-epoch reclaim — never the owner's own claim), which
   166	    // closes the ts==terminal.ts boundary. Rework of a completed unit must mint a fresh
   167	    // task id. Reorder-safe: a pure function of `terminal` + the event set.
   168	    const sealOwner = terminal ? ownerAt(terminal.ts, epochOf(terminal)) : null;
   169	    const sealOwnerEpoch = sealOwner ? epochOf(sealOwner) : 0;
   170	    const isPostTerminal = (ev) => !!terminal &&
   171	      (ev.ts > terminal.ts || (ev.ts === terminal.ts && epochOf(ev) > sealOwnerEpoch));
   172	    if (terminal) {
   173	      for (const ev of evs) {
   174	        if (ev.type !== 'task.claimed' && ev.type !== 'task.released' && ev.type !== 'task.scope_changed') continue;
   175	        if (isPostTerminal(ev)) rejections.push(makeRejection(ev, sealOwner, 'claim-after-terminal'));
   176	      }
   177	    }
   178	
   179	    // Walk events to set priority, paths, handoff_to, and (if winner exists)
   180	    // apply scope_changed updates from the current owner at the current epoch.
   181	    for (const ev of evs) {
   182	      switch (ev.type) {
   183	        case 'task.created':
   184	          if (ev.priority !== undefined) t.priority = ev.priority;
   185	          if (ev.paths) t.paths = ev.paths;
   186	          break;
   187	        case 'task.released':
   188	          if (isPostTerminal(ev)) break; // GH-41: sealed post-terminal mutation — rejected by the seal loop
   189	          // Releases are agent-scoped (a displaced owner's release only retires
   190	          // its own already-dead claim), so a stale release is inert against the
   191	          // current claim — but its handoff is fenced (threshold) and a genuine
   192	          // post-takeover replay is recorded for the audit log.
   193	          if (ev.to_agent && epochOf(ev) >= handoffThreshold) t.handoff_to = ev.to_agent;
   194	          if (isStaleWrite(ev)) rejections.push(makeRejection(ev, winner, 'stale-epoch-inert'));
   195	          break;
   196	        case 'task.scope_changed':
   197	          if (!ev.paths) break;
   198	          if (isPostTerminal(ev)) break; // GH-41: sealed post-terminal mutation — rejected by the seal loop
   199	          if (winner && ev.agent === winner.agent && epochOf(ev) >= ownerEpoch && ev.ts >= winner.ts) {
   200	            // Latest in-epoch scope_changed wins (replacement semantics).
   201	            t._scopedPaths = ev.paths;
   202	          } else if (isStaleWrite(ev)) {
   203	            rejections.push(makeRejection(ev, winner, staleReason(ev)));
   204	          }
   205	          break;
   206	      }
   207	    }
   208	
   209	    if (terminal) {
   210	      if (terminal.type === 'task.done') {
   211	        t.status = 'done';
   212	      } else {
   213	        t.status = 'circuit_broken';
   214	        t.break = { agent: terminal.agent, reason: terminal.reason || '' };
   215	      }
   216	    } else if (winner) {
   217	      t.status = 'claimed';
   218	      t.claim = {
   219	        agent: winner.agent,
   220	        paths: t._scopedPaths || winner.paths || [],
   221	        ts: winner.ts,
   222	        epoch: ownerEpoch,
   223	      };
   224	      // Once claimed, clear handoff_to (handoff was satisfied by the new claim).
   225	      // But if the latest event is a release-with-handoff after this claim,
   226	      // keep it. Walk events: take the last release.to_agent that occurred
   227	      // AFTER the winning claim.
   228	      let lateHandoff = null;
   229	      for (const ev of evs) {
   230	        // Only the current owner at the current epoch may re-hand-off a claimed
   231	        // task; a stale/foreign late release cannot redirect the reservation.
   232	        if (ev.type === 'task.released' && ev.to_agent && ev.ts > winner.ts
   233	            && ev.agent === winner.agent && epochOf(ev) >= ownerEpoch) {
   234	          lateHandoff = ev.to_agent;
   235	        }
   236	      }
   237	      t.handoff_to = lateHandoff; // null if no late handoff
   238	    }
   239	
   240	    delete t._scopedPaths;
   241	    tasks.set(taskId, t);
   242	  }
   243	
   244	  // Stable, arrival-order-independent ordering for the audit log.
   245	  rejections.sort((a, b) => {
   246	    if (a.ts !== b.ts) return a.ts < b.ts ? -1 : 1;
   247	    if (a.task !== b.task) return a.task < b.task ? -1 : 1;
   248	    if (a.type !== b.type) return a.type < b.type ? -1 : 1;
   249	    return a.fenced_agent < b.fenced_agent ? -1 : a.fenced_agent > b.fenced_agent ? 1 : 0;
   250	  });
   251	
   252	  return { tasks, rejections };
   253	}
   254	
   255	/**
   256	 * Back-compat thin wrapper over {@link foldWithMeta} that returns just the task map.
   257	 * @param {Object[]} events - as returned by {@link module:events.readAllEvents}
   258	 * @returns {Map<string, Object>} the projected task map, keyed by task id
   259	 */
   260	function fold(events) {
   261	  return foldWithMeta(events).tasks;
   262	}
   263	
   264	/**
bin/tick:56:function parseArgs(argv) {
bin/tick:77:function parsePathsFlag(v) {
bin/tick:90:  tick claim <task> --agent <id> --paths <globs> [--force]
bin/tick:93:  tick scope <task> --agent <id> --paths <globs> [--force]
bin/tick:173:        force: Boolean(flags.force),
bin/tick:191:        process.stdout.write(`lost: ${task} is ${result.unavailable} — use --force to override\n`);
bin/tick:236:        scope(root, { task, agent: flags.agent, paths: parsePathsFlag(flags.paths), force: Boolean(flags.force) });
src/claim.js:63:    // unless --force is explicitly provided.
src/scope.js:67:        throw new Error(`scope rejected: paths overlap active claim (${conflicts.join(', ')}) held by ${Array.from(conflictAgents).join(', ')} (use --force to override)`);
test/gh23-path-overlap-enforcement.sh:29:# 3. Bob uses --force -> MUST SUCCEED
test/gh23-path-overlap-enforcement.sh:30:BOB_FORCE_OUT=$(tick_b claim TASK-102 --agent bob --paths "src/auth/login.js" --force 2>&1)
test/gh23-path-overlap-enforcement.sh:33:  pass "direct claim with --force succeeded: $BOB_FORCE_OUT"
test/gh23-path-overlap-enforcement.sh:35:  fail "direct claim with --force failed! status=$BOB_FORCE_STATUS out=$BOB_FORCE_OUT"
test/gh23-path-overlap-enforcement.sh:58:# 6. Bob uses tick scope --force -> MUST SUCCEED
test/gh23-path-overlap-enforcement.sh:59:SCOPE_FORCE_OUT=$(tick_b scope TASK-103 --agent bob --paths "src/billing/**,src/auth/oauth.js" --force 2>&1)
test/gh23-path-overlap-enforcement.sh:62:  pass "scope expansion with --force succeeded: $SCOPE_FORCE_OUT"
test/gh23-path-overlap-enforcement.sh:64:  fail "scope expansion with --force failed! status=$SCOPE_FORCE_STATUS out=$SCOPE_FORCE_OUT"
test/gh23-path-overlap-enforcement.sh:70:# 8. Dispatcher creates TASK-104 with src/auth/**. Charlie claims it without --force -> MUST SUCCEED now that Alice finished
test/gh342-sentinel-debug-log-python.sh:199:         "", "re-anchor to QUEUE lanes or re-fire with --force", "", "p2", "TASK-2", ""),
test/gh544-pre-push-gate.sh:301:git -C "$R_P" worktree remove --force "$WORK/wt-probe" >/dev/null 2>&1
test/lane-attempt-cap.sh:4:# once it hits LANE_MAX_ATTEMPTS; --force overrides; a nested (LANE_ATTEMPT_COUNTED) call is a no-op;
test/lane-attempt-cap.sh:46:# reset-on-success is wired at each driver's Approved terminal + marathon forwards --force
test/lane-attempt-cap.sh:49:grep -q 'drive_args+=( --force )' "$ROOT/relay-automation/marathon.sh" && pass "marathon.sh forwards --force to each phase" || fail "marathon.sh --force forwarding missing"
test/lane-attempt-cap.sh:65:# --force bypasses the cap and logs the override, and DOES count
test/lane-attempt-cap.sh:67:[ "$rf" = 0 ] && pass "--force proceeds past the cap (exit 0)" || fail "--force blocked (rf=$rf)"
test/lane-attempt-cap.sh:68:printf '%s' "$out" | grep -q 'force override' && pass "--force logs the override" || fail "no override log: $out"
test/lane-attempt-cap.sh:70:  && pass "--force fire is recorded (now 3 attempts)" || fail "--force fire not recorded"
test/relay-file-seeding-visibility.sh:35:[ -n "$wt1" ] && { git -C "$A" worktree remove --force "$wt1" >/dev/null 2>&1 || rm -rf "$wt1"; git -C "$A" worktree prune >/dev/null 2>&1; }
test/relay-file-seeding-visibility.sh:55:[ -n "$wt2" ] && { git -C "$A" worktree remove --force "$wt2" >/dev/null 2>&1 || rm -rf "$wt2"; git -C "$A" worktree prune >/dev/null 2>&1; }
test/gh402-branch-enforcement.sh:162:  bash "$DRIVE" --phase-id lane1 --reviewer codex --builder claude --force \
test/gh402-branch-enforcement.sh:212:# --force must NOT be a way past this. Retrying a flaky lane cannot silently grant permission to
test/gh402-branch-enforcement.sh:216:rc6="$(run_drive "$R6" "$WORK/force.out" --force)"
test/gh402-branch-enforcement.sh:217:# Post-GH-561 this reads as "--force does not grant permission to COMMIT ON trunk" rather than "does
test/gh402-branch-enforcement.sh:223:  pass "--force does NOT grant permission to commit on trunk (it bounds attempts, not branches)"
test/gh402-branch-enforcement.sh:225:  fail "GH-402: --force let a lane retry land on trunk — on '$(git -C "$R6" branch --show-current)', main has $(git -C "$R6" rev-list --count main) commit(s)"
test/gh385-retry-token-satisfied.sh:55:  tick_a claim "$1" --agent claude --paths "phases/p1/RELAY.md" --force >/dev/null 2>&1 || true
test/marathon-drive.sh:694:git -C "$A" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"
test/gh322-runlog-python-lane.sh:248:GH_ON_PATH="$GH_STUB_DIR:" run_driver gh-log --log-github --force >/dev/null 2>&1
test/gh292-worktree-vendored-discovery.sh:24:  git -C "$MAIN" worktree remove --force "$LINKED" >/dev/null 2>&1 || true
test/gh304-vendored-relay-path.sh:79:[ -n "$wt" ] && { git -C "$A" worktree remove --force "$wt" >/dev/null 2>&1 || rm -rf "$wt"; git -C "$A" worktree prune >/dev/null 2>&1; }
test/baselines/GH-402-negative-control.md:64:  FAIL: GH-402: --force bypassed the branch guard — a lane retry now grants permission to land on trunk
test/baselines/GH-402-negative-control.md:91:  PASS: --force does NOT bypass the branch guard (it bounds attempts, not branches)
test/baselines/GH-527-negative-control.md:71:One correction to the review: it also claimed `git clean --force` was missed. It was not — the
test/baselines/GH-527-negative-control.md:72:`-[a-zA-Z]*f` pattern matches the `-f` substring inside `--force`. Verified before changing anything.
test/claim-cap.sh:5:# slot, the 3rd claim succeeds. Tasks have non-overlapping paths so the cap —
test/claim-cap.sh:18:TICK_TS=2026-05-04T10:00:01.000Z tick_a claim TASK-1 --agent alice --paths "src/one/**" >"$WORK/c1.out"
test/claim-cap.sh:19:TICK_TS=2026-05-04T10:00:02.000Z tick_a claim TASK-2 --agent alice --paths "src/two/**" >"$WORK/c2.out"
test/claim-cap.sh:30:TICK_TS=2026-05-04T10:00:03.000Z tick_a claim TASK-3 --agent alice --paths "src/three/**" >"$WORK/c3.out"
test/claim-cap.sh:48:  pass "tick next reports the claim limit"
test/claim-cap.sh:57:TICK_TS=2026-05-04T10:00:05.000Z tick_a claim TASK-3 --agent alice --paths "src/three/**" >"$WORK/c3b.out"
test/gh23-path-overlap-enforcement.sh:2:# GH-23: Enforce path-overlap rejection on direct tick claim and tick scope.
test/gh23-path-overlap-enforcement.sh:13:tick_a claim TASK-101 --agent alice --paths "src/auth/**" >/dev/null
test/gh23-path-overlap-enforcement.sh:21:BOB_OUT=$(tick_b claim TASK-102 --agent bob --paths "src/auth/login.js" 2>&1)
test/gh23-path-overlap-enforcement.sh:30:BOB_FORCE_OUT=$(tick_b claim TASK-102 --agent bob --paths "src/auth/login.js" --force 2>&1)
test/gh23-path-overlap-enforcement.sh:42:tick_b claim TASK-103 --agent bob --paths "src/billing/**" >/dev/null
test/gh23-path-overlap-enforcement.sh:49:# 5. Bob attempts tick scope on TASK-103 to include "src/auth/oauth.js" -> MUST FAIL due to overlap with Alice
test/gh23-path-overlap-enforcement.sh:50:SCOPE_OUT=$(tick_b scope TASK-103 --agent bob --paths "src/billing/**,src/auth/oauth.js" 2>&1)
test/gh23-path-overlap-enforcement.sh:53:  pass "scope expansion into overlapping paths rejected (exit $SCOPE_STATUS): $SCOPE_OUT"
test/gh23-path-overlap-enforcement.sh:55:  fail "scope expansion into overlapping paths was not rejected! status=$SCOPE_STATUS out=$SCOPE_OUT"
test/gh23-path-overlap-enforcement.sh:58:# 6. Bob uses tick scope --force -> MUST SUCCEED
test/gh23-path-overlap-enforcement.sh:59:SCOPE_FORCE_OUT=$(tick_b scope TASK-103 --agent bob --paths "src/billing/**,src/auth/oauth.js" --force 2>&1)
test/gh23-path-overlap-enforcement.sh:74:CHARLIE_OUT=$(tick_b claim TASK-105 --agent charlie --paths "src/admin/**" 2>&1)
test/gh23-path-overlap-enforcement.sh:82:CHARLIE_RECLAIM=$(tick_b claim TASK-105 --agent charlie --paths "src/admin/**" 2>&1)
test/gh278-turn-timeout-parity.sh:119:  tick_a claim "RELAY-$name" --agent claude-a --paths "untracked.md,tracked.md" >/dev/null
test/poll-driver.sh:26:handoff_to(){ tick_a log task.created "$1" --agent dispatcher >/dev/null; tick_a claim "$1" --agent "seed-$1" --paths "z/$1/**" >/dev/null; tick_a release "$1" --agent "seed-$1" --to "$2" >/dev/null; }
test/poll-driver.sh:28:claim_by(){ tick_a log task.created "$1" --agent dispatcher >/dev/null; tick_a claim "$1" --agent "$2" --paths "z/$1/**" >/dev/null; }
test/relay-target-root-relayfile.sh:23:tick_a claim   RELAY-TURN --agent claude-a --paths "$REL" >/dev/null 2>&1
test/concurrent-claim.sh:11:tick_a claim TASK-007 --agent alice --paths "src/auth/**" >"$WORK/a.out"
test/concurrent-claim.sh:19:tick_b claim TASK-007 --agent bob --paths "src/auth/**" >"$WORK/b.out"
test/concurrent-claim.sh:35:tick_a claim TASK-007 --agent alice --paths "src/auth/**" >"$WORK/a2.out"
test/concurrent-claim.sh:44:tick_a claim TASK-007 --agent bob --paths "src/auth/**" >"$WORK/done.out"
test/marathon.sh:176:  TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent codex --paths "$pdir_rel/**,src/gh205.js" >/dev/null 2>&1 || true
test/marathon.sh:184:TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent agy --paths "$pdir_rel/**" >/dev/null 2>&1 || true
test/chaos-stale-writer.sh:25:TICK_TS=2026-05-04T10:00:01.000Z tick_a claim TASK-1 --agent alice --paths "src/one/**" >/dev/null
test/chaos-stale-writer.sh:34:TICK_TS=2026-05-04T10:00:06.000Z tick_a claim TASK-1 --agent alice --paths "src/one/**" >"$WORK/re.out"
test/chaos-stale-writer.sh:119:TICK_TS=2026-05-04T11:00:01.000Z tick_a claim TASK-2 --agent carol --paths "src/two/**" >/dev/null
test/chaos-stale-writer.sh:121:TICK_TS=2026-05-04T11:00:06.000Z tick_a claim TASK-2 --agent dave --paths "src/two/**" >/dev/null
test/reap.sh:2:# Run 2 P5: `tick reap <agent>` releases every active claim held by a
test/reap.sh:15:TICK_TS=2026-05-04T10:00:01.000Z tick_a claim TASK-1 --agent alice --paths "src/one/**" >/dev/null
test/reap.sh:16:TICK_TS=2026-05-04T10:00:02.000Z tick_a claim TASK-2 --agent alice --paths "src/two/**" >/dev/null
test/reap.sh:43:TICK_TS=2026-05-04T10:00:10.000Z tick_b claim TASK-1 --agent bob --paths "src/one/**" >"$WORK/bob.out"
test/gh432-failed-turn-persist.sh:49:seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to claude-builder >/dev/null; }
test/gh432-failed-turn-persist.sh:60:# deliberately so: pre-fix, a crashed turn LEAKS its tick claim, and a leaked claim starves the
test/gh432-failed-turn-persist.sh:155:tick_a claim RELAY-GH432-empty --agent claude-a --paths "z/**" >/dev/null
test/relay-target-root.sh:37:# Perform tick claims
test/relay-target-root.sh:38:"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "artifact.txt" >/dev/null 2>&1
test/relay-target-root.sh:56:  tick_a claim "$1" --agent dispatcher --paths "artifact.txt" >/dev/null 2>&1
test/codex-turn.sh:32:  "$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
test/codex-turn.sh:58:seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to codex >/dev/null; }
test/codex-turn.sh:96:tick_a claim RELAY-TURN-noown --agent boss --paths "z/**" >/dev/null
test/codex-turn.sh:169:# its workspace-write sandbox) -> tick claim EPERM -> deadlock. The fix passes --add-dir <root>/.tick.
test/heartbeat.sh:3:# and `tick analyze` flags a claim window with no heartbeat for longer than the
test/heartbeat.sh:13:TICK_TS=2026-05-04T10:00:01.000Z tick_a claim TASK-1 --agent alice --paths "src/http/**" >/dev/null
test/heartbeat.sh:14:TICK_TS=2026-05-04T10:00:02.000Z tick_a claim TASK-2 --agent alice --paths "src/store/**" >/dev/null
test/heartbeat.sh:59:TICK_TS=2026-05-04T10:30:00.000Z tick_a claim TASK-3 --agent alice --paths "src/x/**" >/dev/null
test/heartbeat.sh:72:TICK_TS=2026-05-04T11:00:00.000Z tick_a claim TASK-4 --agent alice --paths "src/z/**" >/dev/null
test/gh438-removal-is-progress.sh:58:TICK_REPO_ROOT="$A" "$TICK" claim "\$task" --agent agy --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
test/chaos-midturn-kill.sh:12:#   4. `tick analyze --format json` flags the claim as a `parked_suspects` entry.
test/chaos-midturn-kill.sh:148:# (TICK_REPO_ROOT=$A is exported by _setup.sh), so `tick reap` here releases a real claim.
test/chaos-midturn-kill.sh:188:if TICK_TS=2026-05-04T10:32:00.000Z tick_b claim TASK-KILL --agent bob --paths "src/feature/**" >/dev/null 2>&1; then
test/path-overlap.sh:11:TICK_TS=2026-05-04T10:00:05.000Z tick_a claim TASK-007 --agent alice --paths "src/auth/**" >/dev/null
test/cost.sh:81:p2 log task.created REG-1 --agent dispatcher >/dev/null; p2 claim REG-1 --agent alpha --paths "x/**" >/dev/null; p2 done REG-1 --agent alpha >/dev/null
test/cost.sh:82:p2 log task.created REG-2 --agent dispatcher >/dev/null; p2 claim REG-2 --agent beta  --paths "y/**" >/dev/null; p2 done REG-2 --agent beta  >/dev/null
test/gh491-gate-only-refire.sh:39:  tick_a claim "$1" --agent claude --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
test/analyze.sh:14:TICK_TS=2026-05-04T10:01:00.000Z tick_a claim TASK-001 --agent alice --paths "src/auth/**"    >/dev/null
test/analyze.sh:15:TICK_TS=2026-05-04T10:05:00.000Z tick_b claim TASK-002 --agent bob   --paths "src/billing/**" >/dev/null
test/analyze.sh:20:TICK_TS=2026-05-04T10:40:00.000Z tick_a claim TASK-003 --agent alice --paths "src/poison/**" >/dev/null
test/analyze.sh:101:TICK_TS=2026-07-01T10:00:00.000Z tick_in "$GH93" claim TASK-100 --agent alice --paths "src/wide-a/**" >/dev/null
test/analyze.sh:102:TICK_TS=2026-07-01T10:00:05.000Z tick_in "$GH93" claim TASK-101 --agent bob   --paths "src/wide-b/**" >/dev/null
test/poll-relay.sh:3:# The fake turn-taker does REAL tick ops (claim/ping/release/done). The happy path
test/poll-relay.sh:25:"$TICK" claim "$t" --agent "$me" --paths "z/$t/**" >/dev/null 2>&1   # idempotent if already held
test/poll-relay.sh:51:  tick_a claim "$1" --agent dispatcher --paths "z/$1/**" >/dev/null
test/gh331-cost-summary.sh:84:  tick_a claim   "$1" --agent producer --paths "$2" >/dev/null 2>&1
test/relay-untracked-file-warn.sh:23:  tick_a claim   "$1" --agent claude-a --paths "$2" >/dev/null 2>&1
test/scope-change.sh:2:# AC #3: alice claims with src/auth/** then `tick scope` to add src/middleware/**.
test/scope-change.sh:10:TICK_TS=2026-05-04T10:00:05.000Z tick_a claim TASK-007 --agent alice --paths "src/auth/**" >/dev/null
test/scope-change.sh:20:TICK_TS=2026-05-04T10:00:10.000Z tick_a scope TASK-007 --agent alice --paths "src/auth/**,src/middleware/**" >/dev/null
test/gh385-retry-token-satisfied.sh:55:  tick_a claim "$1" --agent claude --paths "phases/p1/RELAY.md" --force >/dev/null 2>&1 || true
test/xyz-harness-hooks.sh:88:tick_a claim RELAY-G --agent a1 --paths rg.md >/dev/null 2>&1
test/xyz-harness-hooks.sh:112:tick_a claim RELAY-O --agent a1 --paths ro.md >/dev/null 2>&1
test/xyz-harness-hooks.sh:136:tick_a claim RELAY-R --agent a1 --paths rr.md >/dev/null 2>&1
test/xyz-harness-hooks.sh:278:  tick_a claim   "$1" --agent builder --paths "$2" >/dev/null 2>&1
test/xyz-harness-hooks.sh:328:tick_a claim RELAY-NP --agent builder --paths rn.md >/dev/null 2>&1
test/relay-turn-timeout.sh:31:"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
test/relay-turn-timeout.sh:59:"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
test/relay-turn-timeout.sh:68:seed_token() { tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to "$2" >/dev/null; }
test/aider-turn.sh:102:seed_token(){ tick_a log task.created "$1" --agent boss >/dev/null; tick_a claim "$1" --agent boss --paths "z/**" >/dev/null; tick_a release "$1" --agent boss --to aider >/dev/null; }
test/aider-turn.sh:143:tick_a claim RELAY-TURN-noown --agent boss --paths "z/**" >/dev/null
test/aider-turn.sh:167:# A failed (exit 6) turn intentionally leaves the token claimed; tick caps concurrent claims per agent,
test/relay-artifact-file.sh:28:"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "relay.md" >/dev/null 2>&1
test/relay-artifact-file.sh:45:  tick_a claim "$task" --agent claude --paths "$paths" >/dev/null 2>&1
test/shim-worktree.sh:33:"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "artifact.txt" >/dev/null 2>&1
test/shim-worktree.sh:47:  tick_a claim   "$1" --agent claude-a --paths "artifact.txt" >/dev/null 2>&1
test/relay-turn-handoff.sh:5:# tick turn-token after its file-scoped commit, so a headless worker that forgets to release/done
test/relay-turn-handoff.sh:41:  "$T" claim RELAY-T --agent agent-a --paths "$relay" >/dev/null
test/gh417-turn-root-symlink-prefix.sh:77:"$TICK_BIN" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
test/gh417-turn-root-symlink-prefix.sh:104:  TICK_REPO_ROOT="$repo" "$tick" claim GH417 --agent claude-a --paths "z/**" >/dev/null
test/gh410-containment-advisory.sh:41:  printf 'I ran: TICK_REPO_ROOT="%s" tick claim T\n' "$R"
test/gh410-containment-advisory.sh:90:# shim resolved tick against the AMBIENT repo and claimed `T-cite`/`T-offlane` as `agy` in the real
test/gh410-containment-advisory.sh:110:  TICK_REPO_ROOT="$A" "$TICK" claim   "T-$_t" --agent claude-a --paths "relay.md" >/dev/null 2>&1
test/relay-dep-drift.sh:70:"$T2" claim RELAY-T --agent agent-a --paths "src/project.js,relay-system/x/thread.md" >/dev/null
test/claude-turn.sh:30:"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
test/claude-turn.sh:55:seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to claude-builder >/dev/null; }
test/claude-turn.sh:228:tick_a claim RELAY-TURN-vendored --agent dispatcher --paths "relay-vendored.md" >/dev/null
test/claude-turn.sh:247:tick_a claim RELAY-TURN-py-unowned --agent intruder --paths "relay-py.md" >/dev/null
test/claude-turn.sh:260:# claim --paths` call (claim_paths_for_turn, native Python — NOT bridged through relay-turn-lib.sh's
test/claude-turn.sh:274:# The shim's own PRE-LAUNCH claim (claim_paths_for_turn's real computed value) is the EARLIEST
test/claude-turn.sh:281:  *..*) fail "GH-296: claude-turn.py's claim --paths escaped root (got: $claimed_paths) — root did not resolve to the CWD's git toplevel" ;;
test/claude-turn.sh:283:  *) pass "GH-296: claude-turn.py's claim --paths stayed repo-relative, no root-escaping '..' (got: $claimed_paths)" ;;
test/take.sh:2:# Run 3: `tick take --agent <id>` is the atomic next+claim verb that replaced the
test/take.sh:3:# `tick next` + `tick claim` two-step (closing the TOCTOU race). This test covers
test/circuit-break.sh:17:TICK_TS=2026-05-04T10:00:04.000Z tick_a claim TASK-007 --agent alice --paths "src/auth/**" >/dev/null
test/relay-target-root-paths.sh:37:"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "src/sub dir/artifact.txt" >/dev/null 2>&1
test/relay-target-root-paths.sh:49:  tick_a claim "$1" --agent dispatcher --paths "src/sub dir/artifact.txt" >/dev/null 2>&1
test/agy-turn.sh:44:# perform NO tool calls at all (no tick claim/ping, no relay edit, no release) before exiting 0.
test/agy-turn.sh:52:[ "${STUB_MODE:-good}" = ticknarration ] && printf 'I ran: TICK_REPO_ROOT="%s" tick claim %s --agent %s --paths "z/**"\n' "$A" "$RELAY_TASK" "$RELAY_AGENT"
test/agy-turn.sh:55:"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
test/agy-turn.sh:92:seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to agy >/dev/null; }
test/agy-turn.sh:274:tick_a claim RELAY-TURN-py-unowned --agent intruder --paths "z/**" >/dev/null
test/agy-turn.sh:285:# --- (13) GH-296 follow-up: with AGY_TURN_ROOT unset, agy-turn.py's own pre-launch `tick claim
test/agy-turn.sh:301:# The shim's own PRE-LAUNCH claim (claim_paths_for_turn's real computed value) is the EARLIEST
test/agy-turn.sh:304:# than `tick info`'s current/post-release state. Excludes seed_token's own claude-a claim event
test/agy-turn.sh:309:  *..*) fail "GH-296: agy-turn.py's claim --paths escaped root (got: $claimed_paths) — root did not resolve to the CWD's git toplevel" ;;
test/agy-turn.sh:310:  *) pass "GH-296: agy-turn.py's claim --paths stayed repo-relative, no root-escaping '..' (got: $claimed_paths)" ;;
test/agy-turn.sh:390:# ZERO real turn work (no tick claim/ping by the stub, no relay edit, no release). The real shim's only
test/archive-commit.sh:51:"\$TICK" claim "\$RELAY_TASK" --agent "\$RELAY_AGENT" --paths "artifact.txt" >/dev/null 2>&1
test/archive-commit.sh:61:seed_token(){ local task="$1"; tick_a log task.created "$task" --agent claude --paths "artifact.txt" >/dev/null; tick_a claim "$task" --agent claude --paths "artifact.txt" >/dev/null 2>&1; tick_a release "$task" --agent claude --to claude >/dev/null 2>&1; }
test/archive-commit.sh:95:"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "artifact.txt" >/dev/null 2>&1
test/watchdog-relay.sh:3:# is now a tick task, a claim with no heartbeat past the threshold is a parked
test/watchdog-relay.sh:12:TICK_TS=2026-05-04T10:00:01.000Z tick_a claim RELAY-TURN --agent ra --paths "z/**" >/dev/null
test/watchdog-relay.sh:15:TICK_TS=2026-05-04T10:58:30.000Z tick_a claim RELAY-TURN-2 --agent rb --paths "y/**" >/dev/null
test/relay-token-collision.sh:4:#   1. `tick claim` on a terminal token → "use a fresh per-relay id" hint.
test/relay-token-collision.sh:16:tick_a claim   RELAY-TURN --agent claude-a --paths foo.txt >/dev/null 2>&1
test/relay-token-collision.sh:18:tick_a claim   RELAY-TURN --agent codex --paths foo.txt    >/dev/null 2>&1
test/relay-token-collision.sh:21:# --- Surface 1: tick claim on the spent id ---
test/relay-token-collision.sh:22:out="$(tick_a claim RELAY-TURN --agent claude-a --paths foo.txt 2>&1)"
test/relay-token-collision.sh:37:tick_a claim   RELAY-custom --agent claude-a --paths foo.txt >/dev/null 2>&1
test/relay-token-collision.sh:39:tick_a claim   RELAY-custom --agent codex --paths foo.txt    >/dev/null 2>&1
test/relay-turn-trace.sh:117:"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
test/relay-turn-trace.sh:125:seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to codex >/dev/null; }
test/tick-foreign-cwd.sh:12:tick_a claim TASK-1 --agent claude-a --paths "src/**" >/dev/null
test/tick-foreign-cwd.sh:33:out="$( cd "$FOREIGN" && env -u TICK_REPO_ROOT "$TICK" claim TASK-2 --agent claude-a --paths "x/**" 2>&1 )"; rc=$?
test/tick-foreign-cwd.sh:49:out="$( cd "$A" && env -u TICK_REPO_ROOT "$TICK" claim TASK-3 --agent claude-a --paths "y/**" 2>&1 )"; rc=$?
test/relay-self-sufficiency.sh:101:TICK_REPO_ROOT="$REPO" "$TICK" claim "$TASK" --agent claude-a --paths relay.md >/dev/null
test/worktree-isolation.sh:28:"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "$ALLOW_PATHS" >/dev/null 2>&1
test/worktree-isolation.sh:55:seed_token(){ local task="$1" allow_paths="${2:-artifact.txt}"; tick_a log task.created "$task" --agent claude --paths "$allow_paths" >/dev/null; tick_a claim "$task" --agent claude --paths "$allow_paths" >/dev/null 2>&1; tick_a release "$task" --agent claude --to claude >/dev/null 2>&1; }
test/worktree-isolation.sh:127:"\$TICK" claim "\$RELAY_TASK" --agent "\$RELAY_AGENT" --paths "artifact.txt" >/dev/null 2>&1
test/handoff.sh:18:TICK_TS=2026-05-04T10:00:05.000Z tick_a claim TASK-007 --agent alice --paths "src/auth/**" >/dev/null
test/nightwatch-release.sh:72:  "408|test/gh408-tick-failure-visibility.sh|a lost tick claim is detectable by exit status and readable in the output"
test/nightwatch-release.sh:73:  "409|test/gh409-claim-leak.sh|a turn that fails releases its claim on the paths that never reach rtl_enforce"
test/gh409-claim-leak.sh:2:# GH-409 — a turn that fails must not keep its tick claim.
test/gh409-claim-leak.sh:53:  tick_a claim "$1" --agent seedster --paths "z/**" >/dev/null
test/relay-target-root-newfile.sh:31:"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "existing.txt,newfile.txt" >/dev/null 2>&1
test/relay-target-root-newfile.sh:44:  tick_a claim "$1" --agent dispatcher --paths "existing.txt,newfile.txt" >/dev/null 2>&1
test/gh408-tick-failure-visibility.sh:2:# GH-408 (+ GH-409 Phase 1) — a failed `tick claim` must be BOTH detectable and readable.
test/gh408-tick-failure-visibility.sh:4:# The 2026-08-07 incident this encodes: an agent sat at its claim cap, `tick claim` printed
test/gh408-tick-failure-visibility.sh:11:#   (1) EXIT STATUS   — `tick claim` fails non-zero when it does not acquire the claim, so a
test/gh408-tick-failure-visibility.sh:34:# Belt 1 — `tick claim` exit status
test/gh408-tick-failure-visibility.sh:36:echo "-- belt 1: tick claim exit status"
test/gh408-tick-failure-visibility.sh:42:out="$(tick_a claim T-one --agent agy --paths 'a.txt' 2>&1)"; rc=$?
test/gh408-tick-failure-visibility.sh:52:out="$(tick_a claim T-one --agent agy --paths 'a.txt' 2>&1)"; rc=$?
test/gh408-tick-failure-visibility.sh:59:out="$(tick_a claim T-two --agent agy --paths 'b.txt' 2>&1)"; rc=$?
test/gh408-tick-failure-visibility.sh:64:out="$(tick_a claim T-three --agent agy --paths 'c.txt' 2>&1)"; rc=$?
test/gh408-tick-failure-visibility.sh:80:out="$(tick_a claim T-one --agent codex --paths 'a.txt' 2>&1)"; rc=$?
test/gh408-tick-failure-visibility.sh:88:tick_a done T-one --agent agy >/dev/null 2>&1 || tick_a claim T-one --agent agy --paths 'a.txt' >/dev/null 2>&1
test/gh408-tick-failure-visibility.sh:90:out="$(tick_a claim T-one --agent codex --paths 'a.txt' 2>&1)"; rc=$?
test/gh408-tick-failure-visibility.sh:128:tick_in "$C" claim H-one --agent agy --paths 'x' >/dev/null 2>&1
test/gh408-tick-failure-visibility.sh:129:tick_in "$C" claim H-two --agent agy --paths 'y' >/dev/null 2>&1
test/gh408-tick-failure-visibility.sh:195:tick_in "$C" claim OWNED --agent codex --paths 'z' >/dev/null 2>&1
test/gh438-acceptance-recheck.sh:79:TICK_REPO_ROOT="$A" "$TICK" claim "\$task" --agent agy --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
test/relay-review-once.sh:20:  tick_a claim   "$1" --agent producer --paths "$2" >/dev/null 2>&1
test/pi-turn.sh:37:  "$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
test/pi-turn.sh:62:seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to pi >/dev/null; }
test/pi-turn.sh:106:tick_a claim RELAY-TURN-noown --agent boss --paths "z/**" >/dev/null
test/runner-loop.sh:51:TICK_TS=2026-05-04T10:00:01.000Z tick_a claim TASK-PASS --agent alice --paths "README.md" >/dev/null
test/runner-loop.sh:90:TICK_TS=2026-05-04T10:01:01.000Z tick_a claim TASK-RETRY --agent codex --paths "README.md" >/dev/null
test/runner-loop.sh:115:TICK_TS=2026-05-04T10:02:01.000Z tick_a claim TASK-CAP --agent codex --paths "README.md" >/dev/null
test/runner-loop.sh:149:TICK_TS=2026-05-04T10:03:01.000Z tick_a claim TASK-REGRESSION --agent alice --paths "README.md" >/dev/null
test/gh308-turn-shim-parity.sh:33:"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
test/gh308-turn-shim-parity.sh:40:seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to claude-builder >/dev/null; }
test/gh382-marathon-memory-telemetry.sh:32:    "$TICK_BIN" claim "$task" --agent codex --paths "$rf" >/dev/null 2>&1 || true
test/gh382-marathon-memory-telemetry.sh:36:    "$TICK_BIN" claim "$task" --agent agy --paths "$rf" >/dev/null 2>&1 || true
test/gh382-marathon-memory-telemetry.sh:141:TICK_REPO_ROOT="$EMPTY_WORK" "$TICK" claim T1 --agent codex --paths foo >/dev/null
test/gh387-gate-not-first-executor.sh:98:  TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent codex --paths "marathon-system/**,src/gh387.js" >/dev/null 2>&1 || true
test/gh387-gate-not-first-executor.sh:104:TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent agy --paths "marathon-system/**" >/dev/null 2>&1 || true
test/marathon-drive.sh:48:# identity in tick claims/relay text — keeps testing exactly what it always tested. The dedicated
test/marathon-drive.sh:116:tick_a claim MARATHON-P1-TURN --agent seed --paths "phases/p1/RELAY.md" >/dev/null
test/marathon-drive.sh:137:tick_a claim MARATHON-P1-TURN --agent claude --paths "phases/p1/RELAY.md" >/dev/null
test/marathon-drive.sh:390:# (a) the artifact path is baked into the relay and the tick claim --paths includes it
test/marathon-drive.sh:395:  && pass "tick claim --paths includes relay + artifact" || fail "claim --paths should declare the artifact"
test/marathon-drive.sh:493:TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent agy --paths "phases/satisfied-plan--p1/RELAY.md" >/dev/null 2>&1 || true
test/marathon-drive.sh:613:TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent claude --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
test/marathon-drive.sh:615:TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent agy --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
test/marathon-drive.sh:810:# creating .xyz/.tick and claiming there while relay-drive watches the consumer repo's real .tick.
test/marathon-drive.sh:857:  || fail "GH-171: consumer repo .tick missing codex claim event"
test/marathon-drive.sh:861:  || fail "GH-171: consumer repo .tick missing reviewer claim event"
test/marathon-drive.sh:890:  || fail "GH-172: consumer repo .tick missing codex claim event in XYZ_PYTHON=1 mode"
test/marathon-drive.sh:894:  || fail "GH-172: consumer repo .tick missing reviewer claim event in XYZ_PYTHON=1 mode"
test/marathon-drive.sh:906:# consumer repo's .tick — mirroring the GH-171 Bash-mode reviewer-claim assertion.
test/marathon-drive.sh:910:  || fail "GH-174: consumer repo .tick missing agy claim event under XYZ_PYTHON=1 (claim-before-launch guard regression)"
test/auto-sync.sh:13:# ("another tick claim in progress"), not a "lost:" on stdout.
test/auto-sync.sh:14:tick_a claim TASK-L1 --agent alice --paths "src/lock/**" >"$WORK/a.out" 2>&1 &
test/auto-sync.sh:15:tick_b claim TASK-L1 --agent bob   --paths "src/lock/**" >"$WORK/b.out" 2>&1 &
test/auto-sync.sh:24:is_loser()  { echo "$1" | grep -qE "^lost:|another tick claim is in progress"; }
test/chaos-concurrent-pollers.sh:23:  tick_a claim "$TASK" --agent poller-a --paths "src/chaos/**" >"$OUT_A" 2>&1 &
test/chaos-concurrent-pollers.sh:24:  tick_a claim "$TASK" --agent poller-b --paths "src/chaos/**" >"$OUT_B" 2>&1 &
test/handoff-exclusive.sh:9:TICK_TS=2026-05-04T10:00:01.000Z tick_a claim TASK-007 --agent alice --paths "src/auth/**" >/dev/null
test/handoff-exclusive.sh:14:CLAIM_OUT=$(TICK_TS=2026-05-04T10:00:03.000Z tick_b claim TASK-007 --agent charlie --paths "src/auth/**" 2>&1)
test/handoff-exclusive.sh:45:CLAIM_BOB=$(TICK_TS=2026-05-04T10:00:05.000Z tick_b claim TASK-007 --agent bob --paths "src/auth/**" 2>&1)
test/handoff-exclusive.sh:55:TICK_TS=2026-05-04T10:00:07.000Z tick_a claim TASK-008 --agent alice --paths "src/api/**" >/dev/null
test/relay-escalation-not-stall.sh:18:tick_a claim   RELAY-A --agent claude-a --paths relayA.md >/dev/null 2>&1
test/relay-escalation-not-stall.sh:47:tick_a claim   RELAY-B --agent claude-a --paths relayB.md >/dev/null 2>&1
test/relay-escalation-not-stall.sh:59:tick_a claim   RELAY-C --agent claude-a --paths relayC.md >/dev/null 2>&1
test/watchdog-liveness.sh:4:# analysis fixture with no real tick claim, so it asserts the reap PATH is invoked + the no-op
validate.sh:17:  "concurrent-claim.sh"
validate.sh:18:  "chaos-stale-writer.sh"
validate.sh:233:  "gh23-path-overlap-enforcement.sh" # GH-23 (enforce path overlap rejection on direct tick claim and tick scope under withClaimLock; --force bypass)

2026-08-17T20:10:07.530574Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 96 column 5
exec
/bin/zsh -lc "git diff -- src/claim.js src/scope.js bin/tick; git diff --cached -- src/claim.js src/scope.js bin/tick; git show HEAD:src/claim.js | nl -ba | sed -n '1,130p'; git show HEAD:src/scope.js | nl -ba | sed -n '1,105p'; git show HEAD:bin/tick | nl -ba | sed -n '80,245p'; nl -ba test/path-overlap.sh; nl -ba test/scope-change.sh; sed -n '1,265p' validate.sh" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb
 succeeded in 12235ms:
2026-08-17 13:10:26.444 xcodebuild[12965:258839865]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-17 13:10:26.742 xcodebuild[12965:258839864] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-zuZf45X2' (errno=Operation not permitted)
2026-08-17 13:10:27.387 xcodebuild[13089:258840117]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-17 13:10:27.585 xcodebuild[13089:258840112] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-cXgxHXXm' (errno=Operation not permitted)
2026-08-17 13:10:28.897 xcodebuild[13408:258841140]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-17 13:10:29.095 xcodebuild[13408:258841094] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-ZyqJZiW7' (errno=Operation not permitted)
2026-08-17 13:10:29.696 xcodebuild[13514:258841636]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-17 13:10:29.908 xcodebuild[13514:258841632] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-4oAC2IyC' (errno=Operation not permitted)
2026-08-17 13:10:31.273 xcodebuild[14177:258842983]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-17 13:10:31.485 xcodebuild[14177:258842954] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-OxBnGa6U' (errno=Operation not permitted)
2026-08-17 13:10:32.083 xcodebuild[14214:258843239]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-17 13:10:32.293 xcodebuild[14214:258843238] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
     1	'use strict';
     2	
     3	const { appendEvent, readAllEvents } = require('./events');
     4	const { project, fold, nextEpoch, activeClaimsForAgent, MAX_ACTIVE_CLAIMS_PER_AGENT } = require('./project');
     5	const { setsOverlap } = require('./paths');
     6	const { withClaimLock } = require('./lock');
     7	
     8	// Local-transport claim (Run 2: git transport removed).
     9	//
    10	// `.tick/events/` is a shared local directory; the per-clone lock serialises
    11	// claim calls. Together that makes `tick claim` a real mutex: read current
    12	// state, decide, append — atomically. No git, no deterministic tie-breaker,
    13	// no auto-release. Those existed only to reconcile the old distributed
    14	// fetch/rebase/push transport's races, which no longer exist.
    15	/**
    16	 * Attempts to claim `task` for `agent`, declaring the path globs it intends to
    17	 * touch. Serialized per-clone via {@link withClaimLock} so two concurrent
    18	 * claims can't both pass the cap check before either writes.
    19	 * @param {string} repoRoot - absolute path to the repo root
    20	 * @param {Object} opts
    21	 * @param {string} opts.task - task id
    22	 * @param {string} opts.agent - claiming agent id
    23	 * @param {string[]} opts.paths - glob patterns the agent intends to touch (required, non-empty)
    24	 * @param {boolean} [opts.force=false] - override path-overlap rejection
    25	 * @returns {{won: boolean, task: string, winner?: string, unavailable?: string, limitReached?: boolean, holding?: string[], overlap?: boolean, conflicts?: string[], conflictAgents?: string[]}}
    26	 * @throws {Error} if `paths` is missing or empty
    27	 */
    28	function claim(repoRoot, { task, agent, paths, force = false }) {
    29	  if (!paths || !paths.length) {
    30	    throw new Error('claim requires --paths (declare every glob you intend to touch)');
    31	  }
    32	
    33	  return withClaimLock(repoRoot, () => {
    34	    const events = readAllEvents(repoRoot);
    35	    const tasks = fold(events);
    36	    const t = tasks.get(task);
    37	
    38	    // Already terminal — not claimable.
    39	    if (t && (t.status === 'done' || t.status === 'circuit_broken')) {
    40	      return { won: false, task, winner: null, unavailable: t.status };
    41	    }
    42	
    43	    // Already claimed.
    44	    if (t && t.status === 'claimed') {
    45	      if (t.claim.agent === agent) {
    46	        return { won: true, task }; // idempotent — you already hold it
    47	      }
    48	      return { won: false, task, winner: t.claim.agent };
    49	    }
    50	
    51	    // Reserved for someone else.
    52	    if (t && t.handoff_to && t.handoff_to !== agent) {
    53	      return { won: false, task, unavailable: 'reserved for another agent' };
    54	    }
    55	
    56	    // Per-agent claim cap.
    57	    const held = activeClaimsForAgent(tasks, agent);
    58	    if (held.length >= MAX_ACTIVE_CLAIMS_PER_AGENT) {
    59	      return { won: false, limitReached: true, holding: held, task };
    60	    }
    61	
    62	    // Path overlap enforcement: reject if requested paths overlap any active claim on other tasks
    63	    // unless --force is explicitly provided.
    64	    if (!force) {
    65	      const conflicts = [];
    66	      const conflictAgents = new Set();
    67	      for (const other of tasks.values()) {
    68	        if (other.id !== task && other.status === 'claimed' && other.claim && other.claim.paths) {
    69	          if (setsOverlap(paths, other.claim.paths)) {
    70	            conflicts.push(other.id);
    71	            conflictAgents.add(other.claim.agent);
    72	          }
    73	        }
    74	      }
    75	      if (conflicts.length > 0) {
    76	        return {
    77	          won: false,
    78	          task,
    79	          overlap: true,
    80	          conflicts,
    81	          conflictAgents: Array.from(conflictAgents),
    82	          unavailable: `paths overlap active claim (${conflicts.join(', ')}) held by ${Array.from(conflictAgents).join(', ')}`
    83	        };
    84	      }
    85	    }
    86	
    87	    // Monotonic epoch: strictly above any prior claim on this task, so a
    88	    // reclaim after reap fences the displaced owner's stale writes.
    89	    appendEvent(repoRoot, { type: 'task.claimed', task, agent, paths, epoch: nextEpoch(events, task), force: force ? true : undefined });
    90	    project(repoRoot);
    91	    return { won: true, task };
    92	  });
    93	}
    94	
    95	module.exports = { claim };
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-JrDTHWPM' (errno=Operation not permitted)
2026-08-17 13:10:33.777 xcodebuild[14367:258843860]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-17 13:10:34.010 xcodebuild[14367:258843838] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-rtRjwnPT' (errno=Operation not permitted)
2026-08-17 13:10:34.603 xcodebuild[14423:258844180]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-17 13:10:34.800 xcodebuild[14423:258844153] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
     1	'use strict';
     2	
     3	const { appendEvent, readAllEvents } = require('./events');
     4	const { project, fold } = require('./project');
     5	const { setsOverlap } = require('./paths');
     6	const { withClaimLock } = require('./lock');
     7	
     8	// Run 2: git transport removed. Every verb is now a pure local event append
     9	// to the shared .tick/events/ dir, followed by a re-projection of STATE.md.
    10	
    11	function emitEvent(repoRoot, type, payload) {
    12	  appendEvent(repoRoot, { type, ...payload });
    13	  project(repoRoot);
    14	}
    15	
    16	// Ownership guard for mutating verbs. Throws if:
    17	//   - task doesn't exist
    18	//   - task is not currently claimed
    19	//   - the claimer doesn't match `agent`
    20	// Only `reap` bypasses this (it explicitly operates on other agents' claims).
    21	// Returns the claimed task `t` so callers can stamp the owner's epoch onto the
    22	// mutation they emit (the fence in fold rejects any mutation whose epoch is
    23	// below the current owner's).
    24	function assertOwnership(repoRoot, task, agent) {
    25	  const tasks = fold(readAllEvents(repoRoot));
    26	  const t = tasks.get(task);
    27	  if (!t) throw new Error(`task ${task} not found`);
    28	  if (t.status === 'open') throw new Error(`task ${task} is open (never claimed) — nothing to break; use a fresh --relay-task id`);
    29	  if (t.status !== 'claimed') throw new Error(`task ${task} is ${t.status} — only the claiming agent can mutate it`);
    30	  if (t.claim.agent !== agent) throw new Error(`task ${task} is claimed by ${t.claim.agent}, not ${agent}`);
    31	  return t;
    32	}
    33	
    34	/**
    35	 * Replaces the claimed task's declared paths (replacement, not merge).
    36	 * Serialized under {@link withClaimLock} so scope expansions cannot overlap
    37	 * another agent's active claim.
    38	 * @param {string} repoRoot - absolute path to the repo root
    39	 * @param {Object} opts
    40	 * @param {string} opts.task - task id (must be claimed by `agent`)
    41	 * @param {string} opts.agent - the claiming agent
    42	 * @param {string[]} opts.paths - new glob patterns (required, non-empty)
    43	 * @param {boolean} [opts.force=false] - override path-overlap rejection
    44	 * @returns {{ok: true}}
    45	 * @throws {Error} if `paths` is missing/empty, {@link assertOwnership} fails, or paths overlap an active claim
    46	 */
    47	function scope(repoRoot, { task, agent, paths, force = false }) {
    48	  if (!paths || !paths.length) throw new Error('scope requires --paths');
    49	
    50	  return withClaimLock(repoRoot, () => {
    51	    const t = assertOwnership(repoRoot, task, agent);
    52	
    53	    if (!force) {
    54	      const events = readAllEvents(repoRoot);
    55	      const tasks = fold(events);
    56	      const conflicts = [];
    57	      const conflictAgents = new Set();
    58	      for (const other of tasks.values()) {
    59	        if (other.id !== task && other.status === 'claimed' && other.claim && other.claim.paths) {
    60	          if (setsOverlap(paths, other.claim.paths)) {
    61	            conflicts.push(other.id);
    62	            conflictAgents.add(other.claim.agent);
    63	          }
    64	        }
    65	      }
    66	      if (conflicts.length > 0) {
    67	        throw new Error(`scope rejected: paths overlap active claim (${conflicts.join(', ')}) held by ${Array.from(conflictAgents).join(', ')} (use --force to override)`);
    68	      }
    69	    }
    70	
    71	    emitEvent(repoRoot, 'task.scope_changed', { task, agent, paths, epoch: t.claim.epoch, force: force ? true : undefined });
    72	    return { ok: true };
    73	  });
    74	}
    75	
    76	/**
    77	 * Releases the claiming agent's hold on `task`, optionally handing it off to
    78	 * another agent (`to_agent`).
    79	 * @param {string} repoRoot - absolute path to the repo root
    80	 * @param {Object} opts
    81	 * @param {string} opts.task - task id (must be claimed by `agent`)
    82	 * @param {string} opts.agent - the claiming agent
    83	 * @param {string} [opts.to_agent] - agent to reserve the task for on release
    84	 * @returns {{ok: true}}
    85	 * @throws {Error} if {@link assertOwnership} fails
    86	 */
    87	function release(repoRoot, { task, agent, to_agent }) {
    88	  const t = assertOwnership(repoRoot, task, agent);
    89	  emitEvent(repoRoot, 'task.released', { task, agent, to_agent, epoch: t.claim.epoch });
    90	  return { ok: true };
    91	}
    92	
    93	/**
    94	 * Terminates `task` as circuit-broken (failed) — a terminal state, same as `done`.
    95	 * @param {string} repoRoot - absolute path to the repo root
    96	 * @param {Object} opts
    97	 * @param {string} opts.task - task id (must be claimed by `agent`)
    98	 * @param {string} opts.agent - the claiming agent
    99	 * @param {string} [opts.reason] - why the task broke
   100	 * @returns {{ok: true}}
   101	 * @throws {Error} if {@link assertOwnership} fails
   102	 */
   103	function circuitBreak(repoRoot, { task, agent, reason }) {
   104	  const t = assertOwnership(repoRoot, task, agent);
   105	  emitEvent(repoRoot, 'task.circuit_break', { task, agent, reason: reason || '', epoch: t.claim.epoch });
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-qTduI5zm' (errno=Operation not permitted)
2026-08-17 13:10:36.195 xcodebuild[14601:258844827]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-17 13:10:36.402 xcodebuild[14601:258844826] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-UeFhWwyl' (errno=Operation not permitted)
2026-08-17 13:10:37.001 xcodebuild[14742:258845273]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-17 13:10:37.214 xcodebuild[14742:258845272] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
    80	}
    81	
    82	function usage() {
    83	  process.stderr.write(`tick — coordination layer CLI
    84	
    85	Usage:
    86	  tick init
    87	  tick log <type> <task> [--agent <id>] [--note "..."] [--paths a,b] [--priority N] [--epoch N]
    88	  tick project
    89	  tick fences                                      (read-only: fenced-event audit log)
    90	  tick claim <task> --agent <id> --paths <globs> [--force]
    91	  tick take --agent <id>                           (atomic next+claim)
    92	  tick next --agent <id>                           (read-only, no STATE.md write)
    93	  tick scope <task> --agent <id> --paths <globs> [--force]
    94	  tick release <task> --agent <id> [--to <agent>] [--relay-file <path>]
    95	  tick break <task> --agent <id> --reason "..."
    96	  tick done <task> --agent <id> [--note "..."] [--relay-file <path>]
    97	  tick drift <surface> --agent <id> [--task <id>] [--prior-sha <sha>] [--current-sha <sha>] [--diff-lines <n>] [--turn <id>]
    98	  tick ping <task> --agent <id> [--note "..."]      (liveness heartbeat)
    99	  tick reap <agent> [--by <id>] [--task <task>]
   100	  tick info <task>
   101	  tick cost <task> --agent <id> --human-minutes <n>          (log operator attention)
   102	  tick cost <task> --agent <id> --tokens-in <n> --tokens-out <n> [--tokens-total <n>] [--tool <name>]
   103	  tick cost <task> --agent <id> --from-gemini-json <file> [--tool gemini]   (parse gemini -o json)
   104	  tick analyze [--format human|md|json] [--write <file>]
   105	
   106	Event types: ${Array.from(EVENT_TYPES).join(', ')}
   107	
   108	Exit codes:
   109	  1 — claim not acquired (GH-408): lost to another owner, task already terminal, path overlap,
   110	      or at the per-agent claim cap. A claim you already hold is a WIN and still exits 0.
   111	  2 — usage error (missing/unknown flags) — deliberately distinct from a lost claim
   112	  6 — containment violation (off-allowlist edit in relay-turn-lib.sh)
   113	  8 — relay block structural validation failed (bin/validate-relay-block returned non-zero)
   114	`);
   115	}
   116	
   117	function main(argv) {
   118	  const verb = argv[0];
   119	  const rest = argv.slice(1);
   120	  const { positional, flags } = parseArgs(rest);
   121	  const { root, source } = repoRoot();
   122	  assertResolvedRoot(verb, root, source);
   123	
   124	  switch (verb) {
   125	    case 'init': {
   126	      ensureEventsDir(root);
   127	      process.stdout.write(`initialized .tick/events at ${root}\n`);
   128	      return 0;
   129	    }
   130	
   131	    case 'log': {
   132	      const [type, task] = positional;
   133	      if (!type || !task) { usage(); return 2; }
   134	      const { path: p } = appendEvent(root, {
   135	        type,
   136	        task,
   137	        agent: flags.agent || process.env.TICK_AGENT || 'unknown',
   138	        note: typeof flags.note === 'string' ? flags.note : undefined,
   139	        paths: flags.paths ? parsePathsFlag(flags.paths) : undefined,
   140	        to_agent: typeof flags.to === 'string' ? flags.to : undefined,
   141	        reason: typeof flags.reason === 'string' ? flags.reason : undefined,
   142	        priority: flags.priority !== undefined ? Number(flags.priority) : undefined,
   143	        epoch: flags.epoch !== undefined ? Number(flags.epoch) : undefined,
   144	      });
   145	      process.stdout.write(`${path.relative(root, p)}\n`);
   146	      return 0;
   147	    }
   148	
   149	    case 'project': {
   150	      const { stateFile, rejections } = project(root);
   151	      process.stdout.write(`${path.relative(root, stateFile)}\n`);
   152	      if (rejections.length) {
   153	        process.stderr.write(`fenced ${rejections.length} stale/non-owner event(s) — see .tick/rejected.jsonl\n`);
   154	      }
   155	      return 0;
   156	    }
   157	
   158	    case 'fences': {
   159	      // Read-only: re-project and print the fenced-event audit log (one JSON
   160	      // object per line). Shows the epoch fence firing (R1) for operators/SIEM.
   161	      const { rejections } = project(root);
   162	      for (const r of rejections) process.stdout.write(`${JSON.stringify(r)}\n`);
   163	      return 0;
   164	    }
   165	
   166	    case 'claim': {
   167	      const [task] = positional;
   168	      if (!task || !flags.agent || !flags.paths) { usage(); return 2; }
   169	      const result = claim(root, {
   170	        task,
   171	        agent: flags.agent,
   172	        paths: parsePathsFlag(flags.paths),
   173	        force: Boolean(flags.force),
   174	      });
   175	      // GH-408: every `lost:` branch below exits 1, not 0. It used to print the reason and exit 0,
   176	      // which made the failure undetectable by exit status — so a caller doing the correct thing
   177	      // (`if ! tick claim ...; then`) learned nothing, and the only remaining signal was stdout,
   178	      // which every caller in this repo was sending to DEVNULL. Both belts were cut at once, and on
   179	      // 2026-08-07 that cost ~2h: an agent at its claim cap produced a turn failure whose message
   180	      // pointed at a perfectly healthy token. A won claim (including the idempotent re-claim by the
   181	      // holder, which `claim()` reports as won) still exits 0; usage errors still exit 2.
   182	      if (result.limitReached) {
   183	        process.stdout.write(`lost: claim limit reached (holding ${result.holding.join(', ')}) — finish or release first\n`);
   184	        return 1;
   185	      }
   186	      if (result.won) {
   187	        process.stdout.write(`won: ${task} claimed by ${flags.agent}\n`);
   188	        return 0;
   189	      }
   190	      if (result.overlap) {
   191	        process.stdout.write(`lost: ${task} is ${result.unavailable} — use --force to override\n`);
   192	        return 1;
   193	      }
   194	      if (result.unavailable) {
   195	        process.stdout.write(`lost: ${task} is ${result.unavailable} — not claimable\n`);
   196	        // A tick task id is single-shot: once terminal it can't be reclaimed. A relay that reuses a
   197	        // spent turn-token id (e.g. the literal RELAY-TURN from a prior relay) lands here and the seed
   198	        // silently breaks. Point at the fix (GH-18 #1): a fresh per-relay id.
   199	        process.stdout.write(`  → '${task}' is spent; use a fresh per-relay id (e.g. --relay-task RELAY-<your-slug>)\n`);
   200	        return 1;
   201	      }
   202	      process.stdout.write(`lost: ${task} already claimed by ${result.winner || 'unknown'}\n`);
   203	      return 1;
   204	    }
   205	
   206	    case 'take': {
   207	      if (!flags.agent) { usage(); return 2; }
   208	      const tr = take(root, { agent: flags.agent });
   209	      if (tr.limitReached) {
   210	        process.stdout.write(`(claim limit reached — holding ${tr.holding.join(', ')} — finish or release a task first)\n`);
   211	        return 0;
   212	      }
   213	      if (!tr.won) { process.stdout.write('(no available task)\n'); return 0; }
   214	      const handoffMark = tr.handoff ? ' [handoff]' : '';
   215	      process.stdout.write(`won: ${tr.task} (priority: ${tr.priority})${handoffMark}\n`);
   216	      return 0;
   217	    }
   218	
   219	    case 'next': {
   220	      if (!flags.agent) { usage(); return 2; }
   221	      const t = next(root, { agent: flags.agent });
   222	      if (t && t.limitReached) {
   223	        process.stdout.write(`(claim limit reached — holding ${t.holding.join(', ')} — finish or release a task first)\n`);
   224	        return 0;
   225	      }
   226	      if (!t) { process.stdout.write('(no available task)\n'); return 0; }
   227	      const handoff = t.handoff_to === flags.agent ? ' [handoff]' : '';
   228	      process.stdout.write(`${t.id} (priority: ${t.priority})${handoff}\n`);
   229	      return 0;
   230	    }
   231	
   232	    case 'scope': {
   233	      const [task] = positional;
   234	      if (!task || !flags.agent || !flags.paths) { usage(); return 2; }
   235	      try {
   236	        scope(root, { task, agent: flags.agent, paths: parsePathsFlag(flags.paths), force: Boolean(flags.force) });
   237	        process.stdout.write(`scoped: ${task}\n`);
   238	        return 0;
   239	      } catch (err) {
   240	        process.stderr.write(`tick scope: ${err.message}\n`);
   241	        return 1;
   242	      }
   243	    }
   244	
   245	    case 'release': {
     1	#!/usr/bin/env bash
     2	# AC #2: agent-A claims TASK-007 with paths src/auth/**.
     3	# TASK-008 (higher priority) also touches src/auth/**.
     4	# agent-B's `tick next` must NOT return TASK-008; should return next compatible.
     5	source "$(dirname "$0")/_setup.sh" path-overlap
     6	
     7	tick_a init >/dev/null
     8	TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-007 --agent dispatcher --priority 5  --paths "src/auth/**" >/dev/null
     9	TICK_TS=2026-05-04T10:00:01.000Z tick_a log task.created TASK-008 --agent dispatcher --priority 99 --paths "src/auth/login.js" >/dev/null
    10	TICK_TS=2026-05-04T10:00:02.000Z tick_a log task.created TASK-009 --agent dispatcher --priority 1  --paths "src/billing/**" >/dev/null
    11	TICK_TS=2026-05-04T10:00:05.000Z tick_a claim TASK-007 --agent alice --paths "src/auth/**" >/dev/null
    12	
    13	# tick_b shares TICK_REPO_ROOT with tick_a — no git pull needed.
    14	NEXT_FOR_B=$(tick_b next --agent bob)
    15	echo "  bob's next: $NEXT_FOR_B"
    16	
    17	if echo "$NEXT_FOR_B" | grep -q "TASK-008"; then
    18	  fail "bob got TASK-008 even though it overlaps src/auth/** claimed by alice"
    19	fi
    20	if echo "$NEXT_FOR_B" | grep -q "TASK-009"; then
    21	  pass "bob routed to TASK-009 (non-overlapping) instead of higher-priority TASK-008"
    22	else
    23	  fail "bob should have received TASK-009 but got: $NEXT_FOR_B"
    24	fi
    25	
    26	echo "  $TEST_NAME: $PASS pass, $FAIL fail"
    27	exit 0
     1	#!/usr/bin/env bash
     2	# AC #3: alice claims with src/auth/** then `tick scope` to add src/middleware/**.
     3	# bob's `tick next` immediately stops returning tasks touching src/middleware/**.
     4	source "$(dirname "$0")/_setup.sh" scope-change
     5	
     6	tick_a init >/dev/null
     7	TICK_TS=2026-05-04T10:00:00.000Z tick_a log task.created TASK-007 --agent dispatcher --priority 5  --paths "src/auth/**" >/dev/null
     8	TICK_TS=2026-05-04T10:00:01.000Z tick_a log task.created TASK-010 --agent dispatcher --priority 50 --paths "src/middleware/**" >/dev/null
     9	TICK_TS=2026-05-04T10:00:02.000Z tick_a log task.created TASK-011 --agent dispatcher --priority 1  --paths "src/billing/**" >/dev/null
    10	TICK_TS=2026-05-04T10:00:05.000Z tick_a claim TASK-007 --agent alice --paths "src/auth/**" >/dev/null
    11	
    12	# tick_b shares TICK_REPO_ROOT with tick_a — no git pull needed.
    13	NEXT1=$(tick_b next --agent bob)
    14	echo "  before scope expansion, bob's next: $NEXT1"
    15	if ! echo "$NEXT1" | grep -q "TASK-010"; then
    16	  fail "bob should have seen TASK-010 (highest priority, no overlap yet)"
    17	fi
    18	
    19	# Alice expands scope to include middleware.
    20	TICK_TS=2026-05-04T10:00:10.000Z tick_a scope TASK-007 --agent alice --paths "src/auth/**,src/middleware/**" >/dev/null
    21	
    22	NEXT2=$(tick_b next --agent bob)
    23	echo "  after scope expansion, bob's next: $NEXT2"
    24	if echo "$NEXT2" | grep -q "TASK-010"; then
    25	  fail "bob still got TASK-010 after alice expanded scope to src/middleware/**"
    26	fi
    27	if echo "$NEXT2" | grep -q "TASK-011"; then
    28	  pass "bob now routed to TASK-011 after alice's scope expansion"
    29	else
    30	  fail "expected TASK-011, got: $NEXT2"
    31	fi
    32	
    33	echo "  $TEST_NAME: $PASS pass, $FAIL fail"
    34	exit 0
#!/usr/bin/env bash
# Aggregate runner for all tick acceptance tests.
# Exit 0 = all pass; Exit 1 = at least one failed.
set -u

# GH-441 Phase 2: clean the ambient variables a live marathon exports, via the shared contract rather
# than a list copied here. This file used to hardcode six names; the driver popped three DIFFERENT
# ones, and any other --pre-advance-cmd that forgot the prologue was silently wrong. One did, on
# 2026-08-07, and cost two marathon rounds. utils/py/gate_env.py is now the single registry, and
# test/gh441-gate-env-contract.sh fails if a new driver export is left unclassified.
# NOTE: RELAY_DRIVER_LOCKED is deliberately NOT scrubbed — see gate_env.py's docstring.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/relay-automation/gate-env.sh"

HERE="$(cd "$(dirname "$0")" && pwd)"
TESTS=(
  "projection-idempotent.sh"
  "concurrent-claim.sh"
  "chaos-stale-writer.sh"
  "chaos-concurrent-pollers.sh"
  "chaos-midturn-kill.sh"
  "path-overlap.sh"
  "scope-change.sh"
  "tick-foreign-cwd.sh"
  "handoff.sh"
  "handoff-exclusive.sh"
  "circuit-break.sh"
  "terminality-seal.sh"          # GH-41 (terminal seal edge cases — cross-model review of PR #99)
  "auto-sync.sh"
  "analyze.sh"
  "workstealing-verdict.sh"      # GH-4 (work-stealing via take + lane-count-independent verdict)
  "verdict-edge.sh"              # GH-4 (verdict/collision edge cases — cross-model review of PR #101)
  "claim-cap.sh"
  "reap.sh"
  "heartbeat.sh"
  "cost.sh"
  "take.sh"
  "watchdog-liveness.sh"
  "runner-loop.sh"
  "poll-driver.sh"
  "relay-loop.sh"
  "poll-relay.sh"
  "watchdog-relay.sh"
  "codex-turn.sh"
  "agy-turn.sh"
  "pi-turn.sh"                   # GH-295 (Pi/pi.dev headless turn-taker: PI_MODEL safety + cost capture)
  "relay-turn-trace.sh"          # GH-161 (rtl_trace/rtl_log_always/rtl_default_log instrumentation)
  "aider-turn.sh"
  "gh278-turn-timeout-parity.sh" # GH-278 (Aider Python/Bash/doc timeout default must stay aligned)
  "gh308-frozen-twin-guard.sh"  # GH-308 (Python-authoritative twins: banner + committed-change guard)
  "ate-run-variations.sh"       # GH-195 (ATE fuzzer git helpers: base-commit/disposable-guard/reset/detect-edit)
  "model-alias.sh"              # GH-120 (OpenRouter model-alias fuzzy lookup)
  "swe-diagram.sh"              # GH-146 (hub-ring layout ring-balance math + search/filter matching)
  "claude-turn.sh"             # GH-58
  "worktree-isolation.sh"
  "shim-worktree.sh"
  "marathon-yaml.sh"
  "gh391-emit-marathon-yaml.sh" # GH-391 (ranked plan + packets -> runnable MARATHON.yaml; missing-packet control)
  "marathon-drive.sh"
  "gh284-runlog-heartbeat.sh"   # GH-284 (driver heartbeat + opt-in idempotent run log)
  "gh307-gate-env-scrub.sh"      # GH-307 (pre-advance gate must not inherit run-identity tags)
  "gh319-gate-path-with-space.sh" # GH-319 (default gate must not word-split a spaced repo path)
  "gh320-twin-timeout-parity.sh" # GH-320 (Python twin turn-timeout defaults must match Bash + docs)
  "gh322-unknown-arg-rejection.sh" # GH-322 (Python lane must reject unknown flags, not discard them)
  "gh322-runlog-python-lane.sh"  # GH-322 (GH-284 P2 heartbeat + run log on the lane that actually runs)
  "gh331-cost-summary.sh"        # GH-331/GH-308 (end-of-run tick-analyze cost summary on the default Python lane)
  "gh308-poll-guards.sh"         # GH-308 (poll.py: --help/--mode/--turn-source/positional guards, GH-92 warning, watchdog default)
  "gh308-swarm-gate-path.sh"     # GH-308 (swarm_preflight.py: uninstalled node/npm/python3 gate program → NOT-READY)
  "gh343-gate-program-target-root.sh" # GH-343 (target-relative direct gate programs resolve from target_root)
  "gh308-consult-guards.sh"      # GH-308 (consult.py: agy isolation-breach detector + codex ATTESTATION header)
  "gh308-turn-shim-parity.sh"    # GH-308 (claude drift brief + turn-shim ROOT resolution + agy TICK_REPO_ROOT propagation)
  "gh342-sentinel-debug-log-python.sh" # GH-342/GH-281 (Sentinel Tier-1 XYZ_DEBUG_LOG capture on the default Python lane)
  "gh369-find-doc-root-resolution.sh"  # GH-369/GH-344 (find-doc.sh resolves PROJECT/** from the SWEPT repo; --root arg-parse guards)
  "gh400-acceptance-fidelity.sh" # GH-400 (a capture doc's acceptance block must be the issue's, or declare each deviation)
  "gh557-unknown-blocks-manifest.sh" # GH-557 (an `unknown` acceptance verdict blocks on a FROZEN MANIFEST member when the cause is structural — the issue states no criteria — and stays advisory everywhere else) — 16/0; control in test/baselines/GH-557-negative-control.md: 5 pass / 11 fail pre-fix, with the pin observed as `expected exit 5, got 0`. The three assertions that PASS pre-fix are the point: a detector that refused every acceptance-less issue would satisfy the pin and break ordinary lanes, and an outage must never block
  "gh400-source-url.sh"          # GH-400 criterion 2 (a capture doc must cite its issue's URL) — 13/0 post-fix, observed 2/11 pre-fix
  "gh419-gate-inventory.sh"      # GH-419 (generated decision-gate inventory; declared negative-control evidence)
  "litmus-release.sh"            # Litmus 0.2.0 frozen-manifest audit. Suite mode fails ONLY on a false completion claim (a CLOSED manifest issue whose gate is missing/unregistered/undeclared); remaining work is INFO. The goalpost itself is `--release-gate` (red until done). Control: `--mutate-evidence` 9/0 — NOT run by this suite; run it by hand when touching audit_entry
  "gh418-issue-state-frozen.sh"  # GH-418 (issue state is advisory; on-disk GH-308 FROZEN banner blocks writes)
  "gh422-backfill-source-url.sh" # GH-422 (self-remediating message + bulk backfill) — 18/0; controls: pre-fix replay 15/3, conflict-guard mutation 16/2
  "gh425-source-url-slug.sh" # GH-425 (source URL validates tracking repository + issue number; `related:` preserves foreign origin)
  "gh410-containment-advisory.sh" # GH-410 (prose scan demoted to advisory; worktree_end stays the verdict) — 11/0; controls: pre-fix replay 7/4, containment-deleted mutation 9/2
  "gh399-packet-acceptance-continuation.sh" # GH-399 (the packet's acceptance block is a lossless copy: continuations, scope, cap)
  "gh417-turn-root-symlink-prefix.sh" # GH-417 (--show-toplevel is safe as resolve_turn_root's default: a Python turn with *_TURN_ROOT unset, from a repo behind a symlinked prefix, is not reverted) — 13/0; control: reverting GH-261's canonicalization brings exit 6 back, and the same reverted tree passes with a logical-form ROOT
  "gh390-gate-guard.sh"          # GH-390/GH-382 (gate resource guard: wall/CPU/RSS caps, gate-killed escalation, off switch)
  "gh457-gate-tiers.sh"         # GH-457 (the gate's caps come from a declared TIER; the default tier must exceed the worst observed real gate runtime) — 10/0; control: mutating the registry moves the resolved cap, restoring it moves back
  "gh407-gate-ran-attribution.sh" # GH-407 (pre-advance-failed is reserved for a gate that RAN; every escalation records gate: not-run|green|red) — 7/0; control: pre-fix replay reproduces the mislabel inside the fixture
  "gh390-timeout-attribution.sh" # GH-390 (exit-7 attribution: dialog vs runaway vs slow vs wedged)
  "gh387-gate-not-first-executor.sh" # GH-387 (a timed-out turn's artifact is reviewed BEFORE any gate
                                 #   executes it) — 9/0. The gate LOGS every invocation, because the
                                 #   outcome alone cannot distinguish the fix: with a green gate the
                                 #   phase completes either way. Pre-fix replay: restoring the probe
                                 #   makes the gate run TWICE and the pin fails 7/2.
                                 #   test/marathon.sh's GH-205 cases are the non-regression CONTROL,
                                 #   not the pin — they pass with OR without the probe, which is
                                 #   exactly why this file exists.
  "gh492-idle-kill.sh"           # GH-492 (a blocked turn is killed on an IDLE threshold, not only at the
                                 #   wall cap) — 16/0, covering both surfaces: agy-turn.py and consult.py.
                                 #   The NEGATIVE CONTROLS are the point, because a trigger-happy bound is
                                 #   worse than the hang it replaces — it kills reviewer turns, and a dead
                                 #   reviewer turn takes a VERDICT with it. (1) a slow-but-progressing turn
                                 #   must NOT be killed: measured 0.06s idle vs the blocked turn's 4.09s.
                                 #   (2) consult scoping is pinned BOTH ways — a hung advisor reads 2.99s
                                 #   idle scoped to its own pid and 0.14s under the shared parent, so the
                                 #   case cannot pass on a build where scoping does nothing.
                                 #   Behavioural mutation (not just a missing symbol): dropping worktree
                                 #   progress from the idle signal makes the control fail, which is exactly
                                 #   what a trigger-happy bound looks like.
  "gh432-failed-turn-persist.sh" # GH-432 (a failed turn still reaches rtl_enforce: commit + token handoff; both routes) — 12/0 post-fix, control 5/4 pre-fix
  "gh441-gate-env-contract.sh"   # GH-441 P2 (every driver export is classified scrub-or-pass; custom gates get the same clean env) — 13/0; controls: unhelped gate contaminated, orphaned helper fails loud
  "gh448-driver-lock-resolver.sh" # GH-448 (shared driver-lock resolver: bash/python parity + linked-worktree LIVE, real worktree fixture; negative control: pre-fix 2-branch logic misses the lock)
  "gh376-relay-drive-lock-parity.sh" # GH-376 (the DRIVER-side half of #448: relay-drive's own two twins
                                 #   now resolve the lock through that shared resolver, so a relay driver
                                 #   and a marathon driver actually exclude from a linked worktree — the
                                 #   thing marathon-drive.sh:195-196 already claimed in prose) — 18/0.
                                 #   Observable is "does it REFUSE against a lock held at marathon-drive's
                                 #   path", run end-to-end through the real scripts against a real
                                 #   `git worktree add`; the drivers never print the path and the EXIT
                                 #   trap removes the lock, so no filesystem probe can see it.
                                 #   Controls: pre-fix resolution replayed on BOTH lanes sails past the
                                 #   held lock; normal-clone and vendored (no .git) cases unchanged;
                                 #   source guards pin that the resolver is CALLED, never re-inlined.
  "gh397-reviewer-turn-role.sh"  # GH-397 (reviewer scope derived from the tick token + role directive, not agent-maintained NEXT:) — 11/0; control: pre-fix red on the un-flipped-NEXT case
  "gh401-dry-run-no-mutation.sh" # GH-401 (--dry-run writes nothing; render goes to stdout) — 4/0; control: pre-fix red on directory creation. Static half: marathon-root-audit.sh
  "gh375-agy-auth-preflight.sh"  # GH-375 (agy whoami exits 0 without a TTY, so output decides) — 14/0; controls: 5 legitimate auth outputs containing "error" must NOT be rejected
  "gh375-auth-timeout-verdict.sh" # GH-375 follow-up (a timed-out probe is reclassified ONLY on positive evidence of the TTY cause; silence and a login prompt stay fatal) — 11/0; control: pre-fix replay of BOTH callers blocks the TTY-diagnosed timeout, and each replay is compile-checked
  "gh385-retry-token-satisfied.sh" # GH-385 (a phase completed on a --retry suffixed token is satisfied) + GH-491 (--retry on an already-satisfied lane says a plain re-fire would have been gate-only) — 19/0; controls: un-completed recorded token must still rebuild; GH-491 advisory must NOT fire when the recorded token is not done, and must not change --retry's behaviour
  "gh408-tick-failure-visibility.sh" # GH-408 + GH-409 P1 (a failed `tick claim` is detectable by exit status AND readable in the output, at both discard sites) — 22/0; control recorded in test/baselines/GH-408-negative-control.md: 12 red pre-fix. Guards the two directions a naive fix breaks: an idempotent re-claim by the holder must stay exit 0, and a successful tick call must stay silent
  "nightwatch-release.sh"        # Nightwatch 0.3.0 frozen-manifest goalpost. Suite mode fails ONLY on a false completion claim (a CLOSED manifest issue whose gate is missing/unregistered/uncontrolled) or a disagreement with RELEASES.md; remaining work is INFO. The goalpost itself is `--release-gate` (red until done, and it EXECUTES the lifecycle suites rather than auditing them). Control: `--mutate-evidence` 34/0 — NOT run by this suite; run it by hand when touching audit_manifest
  "gh378-gate-requires-green-suite.sh" # GH-378 (pre-advance gate baseline allowance for non-green suites)
  "gh379-claude-builder-diagnosis.sh" # GH-379 (Claude builder failure diagnostics surface in ESCALATION.md)
  "gh380-claude-trust.sh"        # GH-380 (Claude builder warns when target workspace lacks Claude Code trust)
  "gh382-marathon-memory-telemetry.sh" # GH-382 (marathon memory telemetry sampled at phase boundaries and end-of-run)
  "gh491-gate-only-refire.sh"    # GH-491 (gate-only re-fire discoverability under --retry)
  "gh551-resolver-refuses.sh"    # GH-551 (resolver refusal contract: raises instead of defaulting)
  "meter-release.sh"             # Meter 0.6.0 PUBLIC-LAUNCH goalpost (RE-POINTED 2026-08-15; the metering manifest moved to Sundown). Suite mode fails ONLY on a false completion claim (a CLOSED manifest issue whose gate is missing/unregistered/uncontrolled) or a ledger disagreement; remaining work is INFO. The goalpost itself is `--release-gate` (red until the sanitized artifact exists AND a credential-free clone completes the documented happy path; the artifact is named by XYZ_LAUNCH_ARTIFACT). Membership is read from RELEASES.md's machine-readable `Manifest-Members:` field and compared in BOTH directions — the prose `Manifest:` paragraph names RETIRED members and must never be parsed, which is the defect that made the pre-2026-08-15 version report a false GOALPOST MET. Control: `--mutate-evidence` — NOT run by this suite; run it by hand when touching audit_artifact or the cross-check
  "ballast-release.sh"           # Ballast 0.7.0 POST-LAUNCH-HARDENING goalpost — the launched repo holds up under a stranger's first run and an outside contributor's first push. Suite mode fails ONLY on a false completion claim or a ledger disagreement; remaining work is INFO. The goalpost itself is `--release-gate` (red until every manifest member — #14 #15 #4 #3, post-#10-cut — is complete AND the stranger's path is executed fresh in a clone named by XYZ_BALLAST_STRANGER_CLONE: ten consecutive parallel runs, an ungated clone's in-band warning, a forced-red push refused, and #14's cross-process stress case). Control: `--mutate-evidence` 7/0 — NOT run by this suite; run it by hand when touching audit_manifest or the cross-check
  "gh402-branch-enforcement.sh"   # GH-402 (a marathon refuses to commit to the RECEIVING repo's shared trunk; --allow-trunk-commit and preflight's risk=1 carve-out are the two documented ways past) — 13/0; control in test/baselines/GH-402-negative-control.md: 8 red pre-fix, with the pre-fix run observed COMMITTING to trunk. Fires only when origin/HEAD resolves — a repo with no remote shares nothing and `git reset` undoes it, asserted as an explicit non-block
  "gh386-turn-budget-honesty.sh"  # GH-386 (one wall-clock default across all five builders on both lanes; the packet's budget names turn_timeout_s, the field marathon.sh actually reads) — 10/0; control in test/baselines/GH-386-negative-control.md: 9 red pre-fix. Part C EXERCISES the shipped sizing ladder and requires every suggestion to be >= the default — the assertion a partial fix (raise the cap, forget the ladder) fails
  "gh514-write-set-trackable.sh"  # GH-514 (the target is proven able to TRACK the run's write-set before dispatch; a hostile ignore rule gets an actionable refusal naming the rule and the remedy, not an unhandled CalledProcessError traceback) — 12/0; control in test/baselines/GH-514-negative-control.md: 6 red pre-fix. Note the corrected framing recorded there: "no dispatch" does NOT discriminate (the render's own git add already dies first) — the traceback assertion does
  "gh426-worktree-leak.sh"       # GH-426 (an isolated turn's creation is absent from BOTH the target and the harness) — 7/0; control in test/baselines/GH-426-negative-control.md: 2 red here + 1 red in gh410's C4c. The reported cause (worktree teardown) is FALSIFIED and the suite pins the real one: the agent binary is invoked twice, and the GH-375 auth probe ran with the caller's CWD, outside containment
  "gh384-crash-recovery.sh"      # GH-384 (marathon-recover.sh actually DISTINGUISHES a gated phase from an ungated one, in one repo, one run) — 19/0; control in test/baselines/GH-384-negative-control.md is a MUTATION pair (the tool already shipped, so there is no pre-fix revision): detection removed → 2 red, verdict decoupled from the approval event → 1 red. Also pins read-only (tree byte-identical) and the STALE/LIVE lock distinction
  "gh388-run-log-durability.sh"  # GH-388 (the harness owns a durable chain run log; a phase KILLED mid-run leaves a content-bearing record; rtl_default_log refuses rather than silently relocating to volatile storage) — 24/0; control in test/baselines/GH-388-negative-control.md: 9 red pre-fix. Part C/D actually kill a running phase and a running chain — a green success path proves nothing on this issue
  "gh409-claim-leak.sh"          # GH-409 P2 (a turn that fails releases its claim, on the three paths that never reach rtl_enforce) — 8/0; control in test/baselines/GH-409-negative-control.md: 4 red pre-fix. Every case fails TWICE before asserting, because the cap is 2 and one leak is invisible
  "gh438-removal-is-progress.sh" # GH-438 PARTIAL (a removal counts as a phase delta) — 6/0; controls: untouched artifact + newly empty file still rejected. fix_probe re-evaluation NOT covered; issue stays open
  "gh438-acceptance-recheck.sh" # GH-438 P2 (the lane's own fix_probes re-read after the build; a still-unfixed probe escalates) — 14/0; controls: fix-really-lands completes, no-contract byte-identical, --dry-run runs none, builder cannot rewrite its own criteria
  "gh467-index-only-lane-blocked.sh" # GH-467 (an undeclared index-only lane BLOCKS before dispatch; the builder git ban stays explicit)
  "hq-marathon-live.sh"          # GH-218 (cross-repo live marathon status)
  "debug-mantra.sh"              # GH-162 (debug-mantra auto-trigger note on a phase's prior attempt)
  "lane-attempt-cap.sh"
  "driver-lock.sh"
  "measure.sh"
  "loop-stop.sh"
  "oracle-guard.sh"
  "champion.sh"
  "heldout-check.sh"
  "loop-cost.sh"
  "improve-loop.sh"
  "improve-loop-qa.sh"
  "improve-loop-dogfood.sh"
  "gh430-state-dir-tracked-default.sh" # GH-430 (STATE_DIR default is a tracked in-repo path, not ${TMPDIR:-/tmp})
  "gh536-evidence-detail.sh"           # GH-536 (the gate-evidence record carries an output hash + per-suite verdicts, so a reader can tell a real run from a stamped one) — 19/0; pins that the NOT-promotion-evidence disclaimer STAYS: a self-computed hash is tamper-evident, not attested
  "gh544-parallel-default.sh"          # GH-544 (parallel is the default; every decline to it is ANNOUNCED with a reason) — 29/0; uses --print-mode so it cannot recurse into the gate it belongs to, and pins the two invariants nothing else pins: ci-local.sh never inherits the default, and ci.yml's macOS boundary passes --sequential explicitly
  "gh544-pre-push-gate.sh"             # GH-544 (the gate moved to the push boundary; hosted CI fires on nothing) — 78/0; drives githooks/pre-push against a STUB validate.sh so it cannot recurse, and stubs `gh` to pin the one state nothing else can produce: a PR with ZERO configured checks must not read as "checks failed"
  "gh1-fixture-guard.sh"               # GH-1 (shared require_fixture resolved-containment + clone-identity invariant gate; covers the GH-567 lexical-check residual)
  "gh314-transcript-writeset.sh"       # GH-314 (the write set is THREE paths: the transcript's git add was outside GH-514's preflight, so an ignored relay-system/ was discovered only after paid turns) — 5/0; control: dropping the transcript path spends 2 builder turns before the same refusal (test/baselines/GH-314-negative-control.md)
  "gh520-default-reviewer-stub.sh"     # GH-520 (test/_setup.sh gives every fixture a default CODEX_BIN, so a suite tests its subject rather than the reviewer probe) — 11/0; control: with gh402's own stub removed AND this default removed, gh402 fails with the probe's message verbatim (test/baselines/GH-520-default-stub-control.md)
  "gh527-destructive-git-guard.sh"     # GH-527 (a tree-overwriting git command snapshots the tracked files it destroys into .tick/orphan-backups/ first) — 26/0; controls: a no-op guard drops 9 assertions, and a blanket that fires on a CLEAN tree drops exactly the control assertion. Clean-tree silence is defended by TWO conditions, so it takes a combined mutation to falsify — recorded in test/baselines/GH-527-negative-control.md
  "marathon.sh"
  "gh484-phase-dir-default.sh"   # GH-484 (phase-output default is marathon-system/; --phases-dir still overrides; the dirty-tree exclusion tracks the CONFIGURED dir) — 10/0; controls: pre-fix red on both defaults and both containment cases, plus a stray-file control proving the clean check actually ran. Forces XYZ_PYTHON=0 so the Bash twin is really exercised
  "marathon-root-audit.sh"       # GH-209 (static audit: every test/marathon*.sh invocation is MARATHON_ROOT-scoped)
  "rtl-orphan-backup.sh"         # GH-141 (concurrent peer-edit race: revert unchanged, content recoverable)
  "consult.sh"
  "deep-research.sh"             # GH-87 (provider-agnostic grounded-search adapter)
  "relay-pkg-freshness.sh"
  "skill-extract.sh"
  "releases-skill.sh"            # consolidated /releases router + Claude-only symlink migration — 26/0.
                                 # RE-REGISTERED 2026-08-15 in the same commit that lands the gate file,
                                 # which is the condition its brief unregistration was waiting on. It was
                                 # disabled for ~2h because the registration reached `development` while
                                 # the file did not, so every clone that did not happen to hold the
                                 # author's uncommitted copy failed the suite with rc=127 — red for
                                 # everyone except the one session that could not see it, and, since
                                 # GH-544 put the suite on the push boundary, refusing every push.
                                 # #461 in mirror image: a gate that exists but is unregistered is
                                 # invisible; a registration with no gate is a permanent red that says
                                 # nothing about the code. Register the two together or neither.
  "path-integrity.sh"
  "relay-turn-timeout.sh"
  "relay-target-root.sh"
  "relay-target-root-paths.sh"
  "relay-target-root-relayfile.sh"
  "relay-target-root-newfile.sh"
  "gh289-target-root-build-turn.sh"  # GH-289 (foreign relay Log: BUILD refuses before discarding it)
  "archive-root.sh"              # GH-30 Phase 1 (transcript-root resolver: unset/set/missing/non-git)
  "archive-writers.sh"           # GH-30 Phase 2 (writers honor the resolver: consult e2e + structural)
  "archive-commit.sh"            # GH-30 Phase 3 (Model A: transcript → archive repo, code+.tick → target)
  "archive-telemetry.sh"         # GH-30 Phase 4 (telemetry reads the resolver: archive aggregation + unset)
  "relay-token-collision.sh"
  "relay-escalation-not-stall.sh"
  "relay-untracked-file-warn.sh"
  "relay-file-seeding-visibility.sh"  # GH-178 B2
  "gh304-vendored-relay-path.sh"      # GH-304 (vendored-.xyz relay path: prompt + seeding + gitignored-file message)
  "relay-review-once.sh"
  "relay-artifact-file.sh"
  "relay-turn-handoff.sh"
  "relay-dep-drift.sh"
  "new-relay.sh"
  "agent2agent.sh"              # GH-497 (compact six-digit rendezvous + serialized 2+ agent routing)
  "gh268-relay-cue-and-target-checks.sh" # GH-268 items 7+8 (handoff cue every turn, reviewer file sweep, target-repo gate)
  "xyz-vendor.sh"
  "xyz-sync-check.sh"            # GH-96 (xyz-sync check: tick_version/source_commit drift report)
  "gh293-vendored-guard-drift.sh" # GH-293 (safety-guard manifest + safe fleet-update source gate)
  "relay-concurrent-commit.sh"
  "relay-commit-pathspec.sh"     # GH-198 (rtl_enforce commit is file-scoped, no pathspec regression)
  "relay-case-insensitive.sh"
  "relay-xyz-skill-guard.sh"
  "find-harness.sh"
  "gh292-worktree-vendored-discovery.sh"  # GH-292 (linked worktree resolves main-checkout .xyz/)
  "pdda-roadmap-coverage.sh"
  "pdda-repo-contract.sh"       # GH-311 (real-repository PDDA deterministic contract)
  "pdda-local-checks.sh"        # the checks the 2026-08-03 PDDA sync deleted, restored outside the sync surface
  "gh460-pipe-buffer-sigpipe.sh" # GH-460 (the tier1 "flake" was a SIGPIPE race against the pipe buffer under pipefail, not a flaky assertion) — 8/0; control: the pre-fix shape exits 141 on a >64KB payload whose marker IS present, and passes on a payload that fits
  "gh284-p3-release-milestone.sh" # GH-284 P3 (RELEASES.md Milestone: join key + the releases check's first test)
  "gh284-p4-release-lanes.sh"   # GH-284 P4 (milestone seed + landed-on-trunk rollup: scope-claim matcher)
  "swarm-preflight.sh"
  "ci-workflow.sh"
  "ci-route.sh"                  # GH-509 (docs/fast/full routing + changed-area test selection)
  "gh509-gate-evidence.sh"       # GH-509 (per-commit local gate record + the operator surface)
  "gh528-parallel-contention-retry.sh" # GH-528 (--parallel re-runs a pooled failure alone before believing it, and names the contended suite; the driver-lock lane list cannot be validated by reading it)
  "xyz-completion.sh"
  "gh358-lock-instrumentation.sh" # GH-358 (concurrent append reports lost writes vs lock starvation)
  "gh14-atomic-append.sh"        # GH-14 (appendEvent publishes via a .tmp name + atomic rename; concurrent readers never see a torn .jsonl)
  "gh23-path-overlap-enforcement.sh" # GH-23 (enforce path overlap rejection on direct tick claim and tick scope under withClaimLock; --force bypass)
  "gh4-ungated-clone-warning.sh" # GH-4 (validate.sh warns non-fatally when the push gate is not installed; silent when gated)
  "xyz-harness-hooks.sh"
  "preflight-docs.sh"
  "roadmap-dashboard.sh"
  "marathon-plan.sh"
  "hq.sh"                        # GH-128 Phase 1 (HQ resolver + read-only project card)
  "hq-park.sh"                   # GH-128 Phase 2 (HQ issue-first intake writer: preview + --create)
  "hq-park-synthesis.sh"         # GH-164 Phase 1 (fuller PDDA skeleton template + synthesis passthrough + dashboard regen)
  "hq-dispatch.sh"               # GH-128 Phase 3 (HQ queue: append lane · fire: gated hand-off)
  "hq-next.sh"                   # GH-128 Phase 4 (HQ next: Rebalance-priority project board)
  "hq-locator.sh"                # GH-128 Phase 4 (find-hq.sh: device-agnostic locator, user-level /hq)
  "hq-hardening.sh"              # GH-132 (resolution/dispatch hardening: owner/repo, stale-path, YAML, glob)
  "hq-promote.sh"                # GH-138 (HQ promote: 1-INBOX→2-WORKING scaffolder + marathon glob broadening)
  "mktemp-trap-guard.sh"         # GH-177 (static audit: no unguarded mktemp-into-destructive-rm-rf/cd-recapture pattern anywhere in the repo)
  "hq-marathon-scan.sh"          # GH-158 (cross-repo marathon aggregation + preflight — written, never registered until GH-192)
  "hq-rollup.sh"                 # GH-192 (marathon-scan.sh bridged verbatim into the Obsidian daily rollup)
  "transcript-audit.sh"
  "security-scan.sh"
  "sentinel-tier1.sh"           # GH-281 (Tier-1 JSONL finding capture)
  "sentinel-network-guard.sh"   # GH-281 (bundled scripts stay zero-network)
  "sentinel-driver-hooks.sh"    # GH-281 (marathon-drive.sh Tier-1 hooks: default-off + on-mode append)
  "sentinel-overlay.sh"         # GH-281 (Tier-2 overlay: static egress guard + inert-by-default proof)
  "checkjs.sh"
  "acorn-extract.sh"             # GH-169
  "registry-lock-concurrency.sh"
  "marathon-monitor.sh"          # GH-88 (cross-repo marathon monitor)
  "signal-triage.sh"             # GH-63 (signal triage stage)
  # GH-40 double-blind Reviewer canaries — each verify-fixture.sh drives the real kernel and exits
  # 0/1, so it plugs straight in. ponytail: the Gamma canary (test/fixtures/gamma-poison/) is
  # deliberately NOT here — it runs the whole validate.sh itself, so nesting it would recurse; it
  # stays a manual check.
  "fixtures/canary-token-reuse/verify-fixture.sh"

exec
/bin/zsh -lc "nl -ba bin/tick | sed -n '45,82p'; nl -ba src/project.js | sed -n '170,252p'; node --check src/claim.js && node --check src/scope.js && node --check bin/tick && bash -n test/gh23-path-overlap-enforcement.sh; printf 'syntax checks: PASS\\n'; nl -ba validate.sh | sed -n '1,35p;220,240p'; nl -ba test/_setup.sh | sed -n '1,180p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb
 succeeded in 0ms:
    45	  process.stderr.write(`tick: resolved repo root ${root} via ${how} (set TICK_REPO_ROOT to pin it)\n`);
    46	  if (!fs.existsSync(path.join(root, '.tick', 'events'))) {
    47	    throw new Error(
    48	      `no .tick/events at ${root} (resolved via ${how}). Refusing to create a coordination ` +
    49	      `log here — this is almost always a wrong-directory mistake that would silently no-op ` +
    50	      `against the real clone. If this IS the harness repo, run \`tick init\` first; otherwise ` +
    51	      `set TICK_REPO_ROOT to the harness clone.`
    52	    );
    53	  }
    54	}
    55	
    56	function parseArgs(argv) {
    57	  const positional = [];
    58	  const flags = {};
    59	  for (let i = 0; i < argv.length; i++) {
    60	    const a = argv[i];
    61	    if (a.startsWith('--')) {
    62	      const key = a.slice(2);
    63	      const next = argv[i + 1];
    64	      if (next === undefined || next.startsWith('--')) {
    65	        flags[key] = true;
    66	      } else {
    67	        flags[key] = next;
    68	        i++;
    69	      }
    70	    } else {
    71	      positional.push(a);
    72	    }
    73	  }
    74	  return { positional, flags };
    75	}
    76	
    77	function parsePathsFlag(v) {
    78	  if (!v || v === true) return [];
    79	  return String(v).split(',').map(s => s.trim()).filter(Boolean);
    80	}
    81	
    82	function usage() {
   170	    const isPostTerminal = (ev) => !!terminal &&
   171	      (ev.ts > terminal.ts || (ev.ts === terminal.ts && epochOf(ev) > sealOwnerEpoch));
   172	    if (terminal) {
   173	      for (const ev of evs) {
   174	        if (ev.type !== 'task.claimed' && ev.type !== 'task.released' && ev.type !== 'task.scope_changed') continue;
   175	        if (isPostTerminal(ev)) rejections.push(makeRejection(ev, sealOwner, 'claim-after-terminal'));
   176	      }
   177	    }
   178	
   179	    // Walk events to set priority, paths, handoff_to, and (if winner exists)
   180	    // apply scope_changed updates from the current owner at the current epoch.
   181	    for (const ev of evs) {
   182	      switch (ev.type) {
   183	        case 'task.created':
   184	          if (ev.priority !== undefined) t.priority = ev.priority;
   185	          if (ev.paths) t.paths = ev.paths;
   186	          break;
   187	        case 'task.released':
   188	          if (isPostTerminal(ev)) break; // GH-41: sealed post-terminal mutation — rejected by the seal loop
   189	          // Releases are agent-scoped (a displaced owner's release only retires
   190	          // its own already-dead claim), so a stale release is inert against the
   191	          // current claim — but its handoff is fenced (threshold) and a genuine
   192	          // post-takeover replay is recorded for the audit log.
   193	          if (ev.to_agent && epochOf(ev) >= handoffThreshold) t.handoff_to = ev.to_agent;
   194	          if (isStaleWrite(ev)) rejections.push(makeRejection(ev, winner, 'stale-epoch-inert'));
   195	          break;
   196	        case 'task.scope_changed':
   197	          if (!ev.paths) break;
   198	          if (isPostTerminal(ev)) break; // GH-41: sealed post-terminal mutation — rejected by the seal loop
   199	          if (winner && ev.agent === winner.agent && epochOf(ev) >= ownerEpoch && ev.ts >= winner.ts) {
   200	            // Latest in-epoch scope_changed wins (replacement semantics).
   201	            t._scopedPaths = ev.paths;
   202	          } else if (isStaleWrite(ev)) {
   203	            rejections.push(makeRejection(ev, winner, staleReason(ev)));
   204	          }
   205	          break;
   206	      }
   207	    }
   208	
   209	    if (terminal) {
   210	      if (terminal.type === 'task.done') {
   211	        t.status = 'done';
   212	      } else {
   213	        t.status = 'circuit_broken';
   214	        t.break = { agent: terminal.agent, reason: terminal.reason || '' };
   215	      }
   216	    } else if (winner) {
   217	      t.status = 'claimed';
   218	      t.claim = {
   219	        agent: winner.agent,
   220	        paths: t._scopedPaths || winner.paths || [],
   221	        ts: winner.ts,
   222	        epoch: ownerEpoch,
   223	      };
   224	      // Once claimed, clear handoff_to (handoff was satisfied by the new claim).
   225	      // But if the latest event is a release-with-handoff after this claim,
   226	      // keep it. Walk events: take the last release.to_agent that occurred
   227	      // AFTER the winning claim.
   228	      let lateHandoff = null;
   229	      for (const ev of evs) {
   230	        // Only the current owner at the current epoch may re-hand-off a claimed
   231	        // task; a stale/foreign late release cannot redirect the reservation.
   232	        if (ev.type === 'task.released' && ev.to_agent && ev.ts > winner.ts
   233	            && ev.agent === winner.agent && epochOf(ev) >= ownerEpoch) {
   234	          lateHandoff = ev.to_agent;
   235	        }
   236	      }
   237	      t.handoff_to = lateHandoff; // null if no late handoff
   238	    }
   239	
   240	    delete t._scopedPaths;
   241	    tasks.set(taskId, t);
   242	  }
   243	
   244	  // Stable, arrival-order-independent ordering for the audit log.
   245	  rejections.sort((a, b) => {
   246	    if (a.ts !== b.ts) return a.ts < b.ts ? -1 : 1;
   247	    if (a.task !== b.task) return a.task < b.task ? -1 : 1;
   248	    if (a.type !== b.type) return a.type < b.type ? -1 : 1;
   249	    return a.fenced_agent < b.fenced_agent ? -1 : a.fenced_agent > b.fenced_agent ? 1 : 0;
   250	  });
   251	
   252	  return { tasks, rejections };
syntax checks: PASS
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
   220	  "pdda-repo-contract.sh"       # GH-311 (real-repository PDDA deterministic contract)
   221	  "pdda-local-checks.sh"        # the checks the 2026-08-03 PDDA sync deleted, restored outside the sync surface
   222	  "gh460-pipe-buffer-sigpipe.sh" # GH-460 (the tier1 "flake" was a SIGPIPE race against the pipe buffer under pipefail, not a flaky assertion) — 8/0; control: the pre-fix shape exits 141 on a >64KB payload whose marker IS present, and passes on a payload that fits
   223	  "gh284-p3-release-milestone.sh" # GH-284 P3 (RELEASES.md Milestone: join key + the releases check's first test)
   224	  "gh284-p4-release-lanes.sh"   # GH-284 P4 (milestone seed + landed-on-trunk rollup: scope-claim matcher)
   225	  "swarm-preflight.sh"
   226	  "ci-workflow.sh"
   227	  "ci-route.sh"                  # GH-509 (docs/fast/full routing + changed-area test selection)
   228	  "gh509-gate-evidence.sh"       # GH-509 (per-commit local gate record + the operator surface)
   229	  "gh528-parallel-contention-retry.sh" # GH-528 (--parallel re-runs a pooled failure alone before believing it, and names the contended suite; the driver-lock lane list cannot be validated by reading it)
   230	  "xyz-completion.sh"
   231	  "gh358-lock-instrumentation.sh" # GH-358 (concurrent append reports lost writes vs lock starvation)
   232	  "gh14-atomic-append.sh"        # GH-14 (appendEvent publishes via a .tmp name + atomic rename; concurrent readers never see a torn .jsonl)
   233	  "gh23-path-overlap-enforcement.sh" # GH-23 (enforce path overlap rejection on direct tick claim and tick scope under withClaimLock; --force bypass)
   234	  "gh4-ungated-clone-warning.sh" # GH-4 (validate.sh warns non-fatally when the push gate is not installed; silent when gated)
   235	  "xyz-harness-hooks.sh"
   236	  "preflight-docs.sh"
   237	  "roadmap-dashboard.sh"
   238	  "marathon-plan.sh"
   239	  "hq.sh"                        # GH-128 Phase 1 (HQ resolver + read-only project card)
   240	  "hq-park.sh"                   # GH-128 Phase 2 (HQ issue-first intake writer: preview + --create)
     1	#!/usr/bin/env bash
     2	# Shared setup for tick test scripts. Source this from each test.
     3	#
     4	# Run 2: local transport — both agents share TICK_REPO_ROOT=$A. tick_b is an
     5	# alias for tick_a; git push/pull between clones is not needed for event
     6	# visibility. $B and $REMOTE are retained for tests that still use git
     7	# operations (e.g. git config user.name), but coordination state lives in $A.
     8	#
     9	# Provides:
    10	#   $TICK     — path to bin/tick
    11	#   $WORK     — temp working dir for this test
    12	#   $REMOTE   — bare remote repo path
    13	#   $A        — shared TICK_REPO_ROOT (both tick_a and tick_b read/write here)
    14	#   $B        — second git clone (kept for git ops; NOT used as TICK_REPO_ROOT)
    15	#   tick_a    — run tick with TICK_REPO_ROOT=$A
    16	#   tick_b    — run tick with TICK_REPO_ROOT=$A (same as tick_a)
    17	#   tick_in   — run tick in arbitrary root: tick_in <dir> <args...>
    18	#   pass / fail — assertion helpers; tests exit 1 on first fail
    19	#
    20	# Usage: source _setup.sh <test-name>
    21	
    22	set -u
    23	set -o pipefail
    24	
    25	# Clean up ambient environment variables that can leak and break tests.
    26	# Each test case sets the relay/aider env it actually needs, so inherited runner
    27	# state should never decide whether the shim behaves like a builder or reviewer.
    28	for _var in \
    29	  RELAY_WORKTREE_ISOLATION \
    30	  ALLOW_PATHS \
    31	  RELAY_ARTIFACT_FILE \
    32	  RELAY_FILE \
    33	  RELAY_TASK \
    34	  RELAY_AGENT \
    35	  AIDER_AGENT \
    36	  AIDER_FLAGS \
    37	  AIDER_MODEL \
    38	  RELAY_PEER \
    39	  RTL_ARTIFACT \
    40	  RTL_LOG \
    41	  RTL_TRACE
    42	do
    43	  unset "$_var"
    44	done
    45	
    46	TEST_NAME="${1:-unnamed}"
    47	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    48	TICK="$(cd "$HERE/.." && pwd)/bin/tick"
    49	export TICK
    50	
    51	WORK="$(mktemp -d -t "tick-${TEST_NAME}.XXXXXX")"
    52	export WORK
    53	# Most tests end with a bare `exit 0`, which is correct under fail-fast (a failed
    54	# assertion exits 1 before reaching it). Under TEST_SOFT_FAIL=1 that would report
    55	# a failing file as green, so the trap re-asserts a non-zero code when any
    56	# assertion failed. With TEST_SOFT_FAIL unset this preserves the code verbatim.
    57	trap '_rc=$?; rm -rf "$WORK"; if [ "${TEST_SOFT_FAIL:-0}" = "1" ] && [ "${FAIL:-0}" -gt 0 ]; then exit 1; fi; exit "$_rc"' EXIT
    58	
    59	REMOTE="$WORK/remote.git"
    60	A="$WORK/agent-a"
    61	B="$WORK/agent-b"
    62	export REMOTE A B
    63	
    64	git init -q --bare "$REMOTE"
    65	
    66	# Seed remote with an empty initial commit so clones have something to track.
    67	SEED="$WORK/.seed"
    68	git init -q "$SEED"
    69	git -C "$SEED" config user.email seed@t
    70	git -C "$SEED" config user.name seed
    71	git -C "$SEED" commit -q --allow-empty -m "init"
    72	git -C "$SEED" branch -M main
    73	git -C "$SEED" remote add origin "$REMOTE"
    74	git -C "$SEED" push -q -u origin main
    75	rm -rf "$SEED"
    76	
    77	git clone -q "$REMOTE" "$A"
    78	git clone -q "$REMOTE" "$B"
    79	for d in "$A" "$B"; do
    80	  git -C "$d" config user.email "${d##*/}@t"
    81	  git -C "$d" config user.name "${d##*/}"
    82	done
    83	
    84	tick_in() {
    85	  local dir="$1"; shift
    86	  TICK_REPO_ROOT="$dir" "$TICK" "$@"
    87	}
    88	
    89	tick_a() { tick_in "$A" "$@"; }
    90	tick_b() { tick_in "$A" "$@"; }  # local transport: shares TICK_REPO_ROOT with tick_a
    91	
    92	# Bind TICK_REPO_ROOT to the shared coordination root by default, so a test that
    93	# calls `$TICK ...` directly (instead of the tick_a/tick_b wrappers) still
    94	# targets $A rather than hitting an unbound var under `set -u`. The wrappers
    95	# override it per-call via tick_in; this is just the sane default for new tests.
    96	# (Run-4 feedback: TICK_REPO_ROOT was unbound when scaffolding handoff-exclusive.sh.)
    97	export TICK_REPO_ROOT="$A"
    98	
    99	# GH-402: fixtures may drive a marathon on their own `main`, and that is not the defect the branch
   100	# guard exists to catch.
   101	#
   102	# Every fixture here is a CLONE OF A BARE REPO this file creates, so it has a real `origin/HEAD` and
   103	# sits on `main` — indistinguishable, to the driver, from an operator about to land a marathon on a
   104	# shared trunk. Eight suites went red on the guard's first full run, and `test/marathon-drive.sh`
   105	# alone has ~98 driver invocations: threading `--allow-trunk-commit` through every call site would be
   106	# a permanent tax on every future marathon fixture, and the churn would be far more likely to
   107	# introduce a mistake than the guard is to catch one here.
   108	#
   109	# Declared ONCE, in the one file every fixture already sources, and declared as what it is: a test
   110	# harness saying branch protection is not the thing under test. The guard itself is still exercised —
   111	# `test/gh402-branch-enforcement.sh` unsets this for the cases that must refuse, so the protection
   112	# has a suite that proves it fires rather than a suite that silently never reaches it.
   113	export MARATHON_ALLOW_TRUNK_COMMIT=1
   114	
   115	# GH-520: give every fixture a default REVIEWER binary, for the same reason and in the same place
   116	# as the line above.
   117	#
   118	# `marathon_drive.py` probes the reviewer binary before the guards, the preflight and the dispatch
   119	# (`_probe_agent_bin`), and `--reviewer codex` is the default in essentially every marathon fixture.
   120	# Stubbing the *builder* is the obvious half — it is the thing the test drives — so the reviewer
   121	# stays invisible until a machine without `codex` runs the suite. A fixture that misses it never
   122	# reaches the code it was written to test, and its assertions read the probe's message instead.
   123	#
   124	# That is not hypothetical and it is not a flake: it has now happened three times. GH-232 recorded
   125	# it in a `ci.yml` comment (`driver-lock.sh`/`xyz-harness-hooks.sh` stubbed CLAUDE_BIN/AGY_BIN but
   126	# not CODEX_BIN), and on 2026-08-11/12 three more suites — gh402, gh514, gh388 — shipped green
   127	# locally and were red on every ubuntu run for a whole session. The comment did not prevent the
   128	# recurrence, which is the actual finding: this needs a default, not another warning.
   129	#
   130	# Worse than a flake, because a fail-fast can satisfy an ABSENCE assertion for the wrong reason:
   131	# `gh514` asserts on the absence of a Python traceback, which a run that dies at the probe also
   132	# produces. Those three happened to fail closed; nothing in the design guarantees the next one will.
   133	#
   134	# Declared ONCE, here, as what it is: the harness saying the reviewer binary is not the thing under
   135	# test. The probe is still exercised — `test/marathon-drive.sh` sets an explicitly MISSING binary
   136	# for the cases that must refuse, so it has a suite proving it fires rather than one that silently
   137	# never reaches it. A fixture that needs its own reviewer behaviour still overrides CODEX_BIN
   138	# inline, exactly as the shim suites already do.
   139	_CODEX_STUB="$WORK/_default-codex-stub"
   140	cat > "$_CODEX_STUB" <<'CODEX_STUB_EOF'
   141	#!/usr/bin/env bash
   142	# GH-520 default reviewer stub: present on PATH-probe, does nothing, succeeds.
   143	exit 0
   144	CODEX_STUB_EOF
   145	chmod +x "$_CODEX_STUB"
   146	export CODEX_BIN="${CODEX_BIN:-$_CODEX_STUB}"
   147	
   148	PASS=0
   149	FAIL=0
   150	pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
   151	# TEST_SOFT_FAIL=1 keeps going after a failed assertion so one run enumerates every
   152	# gap instead of stopping at the first. Default (unset/0) is fail-fast, unchanged.
   153	# Soft-fail output is a lead list, not a verdict: later assertions may cascade off
   154	# the state a failed one left behind. The file-level pass/fail stays authoritative.
   155	fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); [ "${TEST_SOFT_FAIL:-0}" = "1" ] || exit 1; }
   156	
   157	echo "== test: $TEST_NAME =="
   158	echo "  workdir: $WORK"

2026-08-17T20:11:03.588953Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 96 column 5
codex
ANSWER: Not ready to call this a kernel invariant. The direct `claim`/`scope` paths are correctly serialized and preserve epoch fencing, but `tick log` still bypasses overlap enforcement for critical events.

FINDINGS

- [Blocker] `tick log task.claimed` and `tick log task.scope_changed` can create/expand overlapping claims without `withClaimLock`, ownership validation, or `--force`. The generic log verb directly appends any event type, and projection accepts those events. [bin/tick:131](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/bin/tick:131) [src/events.js:117](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/src/events.js:117) [src/project.js:196](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/src/project.js:196)

- [Should] The regression does not prove rejected operations are non-mutating. Each rejection is immediately followed by a forced success, so an erroneous write on the rejected call would remain invisible. Assert `tick info`/event count and retained paths before the forced operation. [test/gh23-path-overlap-enforcement.sh:20](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/test/gh23-path-overlap-enforcement.sh:20) [test/gh23-path-overlap-enforcement.sh:49](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/test/gh23-path-overlap-enforcement.sh:49)

- [Should] “Release unblocking” is not tested: TASK-104 is created but never claimed; the actual claim is unrelated TASK-105 under `src/admin/**`. Add a re-claim of the previously conflicting auth path after release/done. [test/gh23-path-overlap-enforcement.sh:67](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/test/gh23-path-overlap-enforcement.sh:67)

- [Should] Add a concurrent, distinct-task overlap race. The implementation’s read/check/append is correctly inside the lock for both verbs, but the test is wholly sequential and does not demonstrate that only one overlap claimant can commit. [src/claim.js:33](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/src/claim.js:33) [src/scope.js:50](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/src/scope.js:50)

- [Should] `--force` is accepted but its provenance is silently discarded: callers pass `force` to `appendEvent`, whose parameter schema never reads or writes it. Emergency overrides should be auditable in the event log. [src/claim.js:89](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/src/claim.js:89) [src/events.js:117](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/src/events.js:117)

- [Pass] For the intended public verbs, same-owner re-claim is idempotent before overlap checking, and scope uses the current claim epoch; the new checks therefore do not weaken epoch fencing. [src/claim.js:43](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/src/claim.js:43) [src/scope.js:71](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/src/scope.js:71)

RECOMMENDATION: Block the “kernel invariant” claim until critical `tick log` events are routed through the guarded verbs (or explicitly privileged), then add non-mutation, real-unblocking, and concurrent-overlap regressions.
tokens used
99,614
ANSWER: Not ready to call this a kernel invariant. The direct `claim`/`scope` paths are correctly serialized and preserve epoch fencing, but `tick log` still bypasses overlap enforcement for critical events.

FINDINGS

- [Blocker] `tick log task.claimed` and `tick log task.scope_changed` can create/expand overlapping claims without `withClaimLock`, ownership validation, or `--force`. The generic log verb directly appends any event type, and projection accepts those events. [bin/tick:131](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/bin/tick:131) [src/events.js:117](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/src/events.js:117) [src/project.js:196](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/src/project.js:196)

- [Should] The regression does not prove rejected operations are non-mutating. Each rejection is immediately followed by a forced success, so an erroneous write on the rejected call would remain invisible. Assert `tick info`/event count and retained paths before the forced operation. [test/gh23-path-overlap-enforcement.sh:20](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/test/gh23-path-overlap-enforcement.sh:20) [test/gh23-path-overlap-enforcement.sh:49](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/test/gh23-path-overlap-enforcement.sh:49)

- [Should] “Release unblocking” is not tested: TASK-104 is created but never claimed; the actual claim is unrelated TASK-105 under `src/admin/**`. Add a re-claim of the previously conflicting auth path after release/done. [test/gh23-path-overlap-enforcement.sh:67](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/test/gh23-path-overlap-enforcement.sh:67)

- [Should] Add a concurrent, distinct-task overlap race. The implementation’s read/check/append is correctly inside the lock for both verbs, but the test is wholly sequential and does not demonstrate that only one overlap claimant can commit. [src/claim.js:33](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/src/claim.js:33) [src/scope.js:50](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/src/scope.js:50)

- [Should] `--force` is accepted but its provenance is silently discarded: callers pass `force` to `appendEvent`, whose parameter schema never reads or writes it. Emergency overrides should be auditable in the event log. [src/claim.js:89](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/src/claim.js:89) [src/events.js:117](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/src/events.js:117)

- [Pass] For the intended public verbs, same-owner re-claim is idempotent before overlap checking, and scope uses the current claim epoch; the new checks therefore do not weaken epoch fencing. [src/claim.js:43](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/src/claim.js:43) [src/scope.js:71](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-4568-4n555rbb/src/scope.js:71)

RECOMMENDATION: Block the “kernel invariant” claim until critical `tick log` events are routed through the guarded verbs (or explicitly privileged), then add non-mutation, real-unblocking, and concurrent-overlap regressions.
