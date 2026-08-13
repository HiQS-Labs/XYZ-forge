**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.6-terra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
2026-08-13T17:18:49.849819Z ERROR codex_models_manager::cache: failed to load models cache: missing field `base_instructions` at line 95 column 5
OpenAI Codex v0.144.6
--------
workdir: /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-86418-h4t1yue0
model: gpt-5.6-terra
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019ffc22-3f80-7043-a0ee-aa74c9f1f7d4
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Independent review request: GH-528 test-suite research spike

You are reviewing a research spike conducted on this repository (the working tree you are in). Please assess it independently and critically. You may inspect any file in the repo (e.g. `validate.sh`, `test/`, `ci-local.sh`) to verify claims.

## The task the spike was answering (from GitHub issue #528)

> Research spike: can the test suite be optimized — for wall-clock, maintenance load, or both — without giving up coverage that real incidents paid for? The answer is not guaranteed either way. "We measured, and the suite should stay as it is" is a passing result.
>
> Research questions: (1) Time census: time every suite in a full run; rank. Hypothesis: a handful of sleep-heavy suites own a disproportionate share of wall-clock. (2) Wait-time audit: which slow suites wait on injectable intervals vs inherent waits? (3) Parallelism feasibility: which suites are isolated and could run concurrently; what breaks the rest — is the sharing load-bearing or incidental? (4) Redundancy map: do any suites assert the same property (candidates: GH-375/385/407/419-family)? (5) Coverage-per-risk: which incident does each candidate suite trace to?
>
> Constraints: no coverage regression on incident-backed suites without explicit operator decision; any consolidated/interval-injected suite must still be observed red against its original defect (the #419 standard); tiering of *when* suites run is GH-509's lane — coordinate, don't duplicate.

## Method used

- Time census: extracted `validate.sh`'s TESTS array verbatim; ran each `bash test/<suite>` sequentially under `relay-automation/gate-env.sh` with `RELAY_SELF_SUFFICIENCY_SKIP=1`, timing each with sub-second precision. Single machine (M-series macOS), single run.
- Wait-time audit: static grep of sleep literals across `test/*.sh`, cross-referenced against the census ranking and the env-injectable timeout knobs.
- Parallelism: audited isolation (per-suite mktemp dirs, lock locations), then two experiments: (a) full suite list under `xargs -P 8`; (b) same, but with 13 identified suites serialized in a single sequential lane.
- Redundancy: full read of `test/gh375-agy-auth-preflight.sh`, `test/gh375-auth-timeout-verdict.sh`, `test/gh385-retry-token-satisfied.sh`, `test/gh390-gate-guard.sh`, `test/gh390-timeout-attribution.sh`, `test/gh407-gate-ran-attribution.sh`, `test/gh419-gate-inventory.sh`, `test/marathon-drive.sh`.

## Measured data

- Sequential full gate: 950.3s (15.8 min), 186 suites. Median suite 1.4s; 78 suites < 1s; 22 suites ≥ 10s own 582s (61%).
- Top 10: marathon-drive.sh 91.0s, pdda-repo-contract.sh 74.2s, agy-turn.sh 59.4s, consult.sh 38.7s, shim-worktree.sh 26.6s, marathon-root-audit.sh 23.4s, gh390-gate-guard.sh 22.5s, xyz-harness-hooks.sh 21.5s, codex-turn.sh 21.3s, claude-turn.sh 20.3s.
- Top-10 slowest suites contain essentially zero executed sleep time; timeout-proving suites already inject tiny intervals (`RELAY_TURN_TIMEOUT_S=1`, `RELAY_TURN_IDLE_S`, `CONSULT_IDLE_S`, `AGY_AUTH_TIMEOUT_S=2`). Residual literal sleep across the gate estimated ~30–60s.
- Naive 8-way parallel run: 172.9s wall; 7 failures, all "relay-drive: another driver is active in this repo (lock: .git/relay-driver.lock)" refusals, in suites that execute the real `relay-automation/relay-drive.sh` from the harness checkout.
- 8-way with those 13 real-driver suites serialized in one lane (lane total 42.7s): 167.4s wall; the only failure was `acorn-extract.sh`, which also fails sequentially without `npm ci` (missing `acorn` node module — environmental).
- Two known census caveats: the python pytest lane wasn't timed (no pytest in the invoking shell; CI pip-installs it), and `acorn-extract.sh` failed environmentally in the sequential census too.

## The recorded verdict under review

1. Keep the suite exactly as it is: no cuts, no merges, no sleep surgery.
   - Wait-time hypothesis called FALSIFIED: slow suites are slow from real subprocess/git work, not sleeps.
   - Redundancy called ZERO: every suite in the named family has a distinct observable; the two gh375 suites assert opposite verdicts on the same input; the two gh390 suites test different modules (exit 5 vs exit 7); the one repeated assertion (red gate → `pre-advance-failed` in marathon-drive.sh §6, gh390-gate-guard, gh407) is judged a load-bearing anti-overcorrection control in each location, not a redundancy. Only optional cleanup: ~40 lines of duplicated `run_driver` scaffolding between gh390-gate-guard and gh407.
2. Add an opt-in parallel mode to the runner (`validate.sh --parallel N`): pool everything except the 13 real-driver suites, which run sequentially in one lane. Keep sequential default until ≥3 consecutive green parallel runs; watch timeout-proving suites under CPU contention as the plausible flake source. Land it coordinated with (not inside) GH-509's route/tiering lane.
3. Optional, separable hygiene: shared fixture helper for the duplicated scaffolding; `gh390-timeout-attribution.sh` is the one suite not on `_setup.sh` conventions.

## Questions for you

1. Is the methodology adequate to support each conclusion? What would you have measured or done differently, and would it plausibly change any verdict?
2. Are there risks, failure modes, or alternatives this verdict misses or underweights?
3. Do you agree or disagree with each of the three recommendation points? Where you disagree, say what you would recommend instead and why.
4. Anything in the repo itself that contradicts the claims above? Spot-check where useful.

Be direct and critical where warranted; do not defer to the verdict's framing. Advisory only — do not modify files.

hook: SessionStart
hook: SessionStart Completed
codex
I’ll audit the actual gate topology and the named suites against the spike’s claims, then give an evidence-backed independent verdict.
mcp: codebase-memory-mcp/list_projects started
mcp: codebase-memory-mcp/list_projects (failed)
user cancelled MCP tool call
exec
/bin/zsh -lc "sed -n '1,220p' WORKTREE-SAFETY.md; sed -n '1,260p' ROUTER.md; sed -n '1,180p' GUIDING-PRINCIPLES.md" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-86418-h4t1yue0
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

# ROUTER.md

This file is the first entry point for an AI agent working in this repo: it tells you what to read, what to run, and which files are canonical.

## Role split

- `ROUTER.md` = startup order and canonical entry points
- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof
- `README.md` = human-facing repo/product overview
- `ROADMAP.md` = pointer ledger of queued, current, completed, attempted, and deferred work
- `CHANGELOG.md` = the end-of-iteration running log (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
- `RELEASES.md` = forward-looking release-planning ledger (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
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
./validate.sh
```

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
- If the task is about planning or publishing a major release, start in `RELEASES.md`; governance is in `PROJECT/PDDA.md` (the "RELEASES.md — release ledger" contract). `/release-plan` authors entries, `/release` publishes an entry to GitHub.
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
/bin/zsh -lc "rg --files -g 'validate.sh' -g 'ci-local.sh' -g 'GH-528*' -g 'gh375-*.sh' -g 'gh385-*.sh' -g 'gh390-*.sh' -g 'gh407-*.sh' -g 'gh419-*.sh' -g 'marathon-drive.sh' -g '*setup*.sh' -g 'gate-env.sh' | sort" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-86418-h4t1yue0
 succeeded in 0ms:
ci-local.sh
relay-automation/gate-env.sh
relay-automation/marathon-drive.sh
test/_setup.sh
test/gh375-agy-auth-preflight.sh
test/gh375-auth-timeout-verdict.sh
test/gh385-retry-token-satisfied.sh
test/gh390-gate-guard.sh
test/gh390-timeout-attribution.sh
test/gh407-gate-ran-attribution.sh
test/gh419-gate-inventory.sh
test/marathon-drive.sh
validate.sh

exec
/bin/zsh -lc "nl -ba validate.sh | sed -n '1,280p'; nl -ba ci-local.sh | sed -n '1,240p'; nl -ba relay-automation/gate-env.sh | sed -n '1,240p'; rg -n --glob '*.sh' 'relay-driver\\.lock|another driver|RELAY_SELF_SUFFICIENCY_SKIP|pytest|TESTS=|sleep [0-9]|RELAY_TURN_TIMEOUT_S|RELAY_TURN_IDLE_S|CONSULT_IDLE_S|AGY_AUTH_TIMEOUT_S' validate.sh ci-local.sh relay-automation test" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-86418-h4t1yue0
 succeeded in 0ms:
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
    56	  "marathon-yaml.sh"
    57	  "gh391-emit-marathon-yaml.sh" # GH-391 (ranked plan + packets -> runnable MARATHON.yaml; missing-packet control)
    58	  "marathon-drive.sh"
    59	  "gh284-runlog-heartbeat.sh"   # GH-284 (driver heartbeat + opt-in idempotent run log)
    60	  "gh307-gate-env-scrub.sh"      # GH-307 (pre-advance gate must not inherit run-identity tags)
    61	  "gh319-gate-path-with-space.sh" # GH-319 (default gate must not word-split a spaced repo path)
    62	  "gh320-twin-timeout-parity.sh" # GH-320 (Python twin turn-timeout defaults must match Bash + docs)
    63	  "gh322-unknown-arg-rejection.sh" # GH-322 (Python lane must reject unknown flags, not discard them)
    64	  "gh322-runlog-python-lane.sh"  # GH-322 (GH-284 P2 heartbeat + run log on the lane that actually runs)
    65	  "gh331-cost-summary.sh"        # GH-331/GH-308 (end-of-run tick-analyze cost summary on the default Python lane)
    66	  "gh308-poll-guards.sh"         # GH-308 (poll.py: --help/--mode/--turn-source/positional guards, GH-92 warning, watchdog default)
    67	  "gh308-swarm-gate-path.sh"     # GH-308 (swarm_preflight.py: uninstalled node/npm/python3 gate program → NOT-READY)
    68	  "gh343-gate-program-target-root.sh" # GH-343 (target-relative direct gate programs resolve from target_root)
    69	  "gh308-consult-guards.sh"      # GH-308 (consult.py: agy isolation-breach detector + codex ATTESTATION header)
    70	  "gh308-turn-shim-parity.sh"    # GH-308 (claude drift brief + turn-shim ROOT resolution + agy TICK_REPO_ROOT propagation)
    71	  "gh342-sentinel-debug-log-python.sh" # GH-342/GH-281 (Sentinel Tier-1 XYZ_DEBUG_LOG capture on the default Python lane)
    72	  "gh369-find-doc-root-resolution.sh"  # GH-369/GH-344 (find-doc.sh resolves PROJECT/** from the SWEPT repo; --root arg-parse guards)
    73	  "gh400-acceptance-fidelity.sh" # GH-400 (a capture doc's acceptance block must be the issue's, or declare each deviation)
    74	  "gh400-source-url.sh"          # GH-400 criterion 2 (a capture doc must cite its issue's URL) — 13/0 post-fix, observed 2/11 pre-fix
    75	  "gh419-gate-inventory.sh"      # GH-419 (generated decision-gate inventory; declared negative-control evidence)
    76	  "litmus-release.sh"            # Litmus 0.2.0 frozen-manifest audit. Suite mode fails ONLY on a false completion claim (a CLOSED manifest issue whose gate is missing/unregistered/undeclared); remaining work is INFO. The goalpost itself is `--release-gate` (red until done). Control: `--mutate-evidence` 9/0 — NOT run by this suite; run it by hand when touching audit_entry
    77	  "gh418-issue-state-frozen.sh"  # GH-418 (issue state is advisory; on-disk GH-308 FROZEN banner blocks writes)
    78	  "gh422-backfill-source-url.sh" # GH-422 (self-remediating message + bulk backfill) — 18/0; controls: pre-fix replay 15/3, conflict-guard mutation 16/2
    79	  "gh425-source-url-slug.sh" # GH-425 (source URL validates tracking repository + issue number; `related:` preserves foreign origin)
    80	  "gh410-containment-advisory.sh" # GH-410 (prose scan demoted to advisory; worktree_end stays the verdict) — 11/0; controls: pre-fix replay 7/4, containment-deleted mutation 9/2
    81	  "gh399-packet-acceptance-continuation.sh" # GH-399 (the packet's acceptance block is a lossless copy: continuations, scope, cap)
    82	  "gh417-turn-root-symlink-prefix.sh" # GH-417 (--show-toplevel is safe as resolve_turn_root's default: a Python turn with *_TURN_ROOT unset, from a repo behind a symlinked prefix, is not reverted) — 13/0; control: reverting GH-261's canonicalization brings exit 6 back, and the same reverted tree passes with a logical-form ROOT
    83	  "gh390-gate-guard.sh"          # GH-390/GH-382 (gate resource guard: wall/CPU/RSS caps, gate-killed escalation, off switch)
    84	  "gh457-gate-tiers.sh"         # GH-457 (the gate's caps come from a declared TIER; the default tier must exceed the worst observed real gate runtime) — 10/0; control: mutating the registry moves the resolved cap, restoring it moves back
    85	  "gh407-gate-ran-attribution.sh" # GH-407 (pre-advance-failed is reserved for a gate that RAN; every escalation records gate: not-run|green|red) — 7/0; control: pre-fix replay reproduces the mislabel inside the fixture
    86	  "gh390-timeout-attribution.sh" # GH-390 (exit-7 attribution: dialog vs runaway vs slow vs wedged)
    87	  "gh387-gate-not-first-executor.sh" # GH-387 (a timed-out turn's artifact is reviewed BEFORE any gate
    88	                                 #   executes it) — 9/0. The gate LOGS every invocation, because the
    89	                                 #   outcome alone cannot distinguish the fix: with a green gate the
    90	                                 #   phase completes either way. Pre-fix replay: restoring the probe
    91	                                 #   makes the gate run TWICE and the pin fails 7/2.
    92	                                 #   test/marathon.sh's GH-205 cases are the non-regression CONTROL,
    93	                                 #   not the pin — they pass with OR without the probe, which is
    94	                                 #   exactly why this file exists.
    95	  "gh492-idle-kill.sh"           # GH-492 (a blocked turn is killed on an IDLE threshold, not only at the
    96	                                 #   wall cap) — 16/0, covering both surfaces: agy-turn.py and consult.py.
    97	                                 #   The NEGATIVE CONTROLS are the point, because a trigger-happy bound is
    98	                                 #   worse than the hang it replaces — it kills reviewer turns, and a dead
    99	                                 #   reviewer turn takes a VERDICT with it. (1) a slow-but-progressing turn
   100	                                 #   must NOT be killed: measured 0.06s idle vs the blocked turn's 4.09s.
   101	                                 #   (2) consult scoping is pinned BOTH ways — a hung advisor reads 2.99s
   102	                                 #   idle scoped to its own pid and 0.14s under the shared parent, so the
   103	                                 #   case cannot pass on a build where scoping does nothing.
   104	                                 #   Behavioural mutation (not just a missing symbol): dropping worktree
   105	                                 #   progress from the idle signal makes the control fail, which is exactly
   106	                                 #   what a trigger-happy bound looks like.
   107	  "gh432-failed-turn-persist.sh" # GH-432 (a failed turn still reaches rtl_enforce: commit + token handoff; both routes) — 12/0 post-fix, control 5/4 pre-fix
   108	  "gh441-gate-env-contract.sh"   # GH-441 P2 (every driver export is classified scrub-or-pass; custom gates get the same clean env) — 13/0; controls: unhelped gate contaminated, orphaned helper fails loud
   109	  "gh448-driver-lock-resolver.sh" # GH-448 (shared driver-lock resolver: bash/python parity + linked-worktree LIVE, real worktree fixture; negative control: pre-fix 2-branch logic misses the lock)
   110	  "gh376-relay-drive-lock-parity.sh" # GH-376 (the DRIVER-side half of #448: relay-drive's own two twins
   111	                                 #   now resolve the lock through that shared resolver, so a relay driver
   112	                                 #   and a marathon driver actually exclude from a linked worktree — the
   113	                                 #   thing marathon-drive.sh:195-196 already claimed in prose) — 18/0.
   114	                                 #   Observable is "does it REFUSE against a lock held at marathon-drive's
   115	                                 #   path", run end-to-end through the real scripts against a real
   116	                                 #   `git worktree add`; the drivers never print the path and the EXIT
   117	                                 #   trap removes the lock, so no filesystem probe can see it.
   118	                                 #   Controls: pre-fix resolution replayed on BOTH lanes sails past the
   119	                                 #   held lock; normal-clone and vendored (no .git) cases unchanged;
   120	                                 #   source guards pin that the resolver is CALLED, never re-inlined.
   121	  "gh397-reviewer-turn-role.sh"  # GH-397 (reviewer scope derived from the tick token + role directive, not agent-maintained NEXT:) — 11/0; control: pre-fix red on the un-flipped-NEXT case
   122	  "gh401-dry-run-no-mutation.sh" # GH-401 (--dry-run writes nothing; render goes to stdout) — 4/0; control: pre-fix red on directory creation. Static half: marathon-root-audit.sh
   123	  "gh375-agy-auth-preflight.sh"  # GH-375 (agy whoami exits 0 without a TTY, so output decides) — 14/0; controls: 5 legitimate auth outputs containing "error" must NOT be rejected
   124	  "gh375-auth-timeout-verdict.sh" # GH-375 follow-up (a timed-out probe is reclassified ONLY on positive evidence of the TTY cause; silence and a login prompt stay fatal) — 11/0; control: pre-fix replay of BOTH callers blocks the TTY-diagnosed timeout, and each replay is compile-checked
   125	  "gh385-retry-token-satisfied.sh" # GH-385 (a phase completed on a --retry suffixed token is satisfied) + GH-491 (--retry on an already-satisfied lane says a plain re-fire would have been gate-only) — 19/0; controls: un-completed recorded token must still rebuild; GH-491 advisory must NOT fire when the recorded token is not done, and must not change --retry's behaviour
   126	  "gh408-tick-failure-visibility.sh" # GH-408 + GH-409 P1 (a failed `tick claim` is detectable by exit status AND readable in the output, at both discard sites) — 22/0; control recorded in test/baselines/GH-408-negative-control.md: 12 red pre-fix. Guards the two directions a naive fix breaks: an idempotent re-claim by the holder must stay exit 0, and a successful tick call must stay silent
   127	  "nightwatch-release.sh"        # Nightwatch 0.3.0 frozen-manifest goalpost. Suite mode fails ONLY on a false completion claim (a CLOSED manifest issue whose gate is missing/unregistered/uncontrolled) or a disagreement with RELEASES.md; remaining work is INFO. The goalpost itself is `--release-gate` (red until done, and it EXECUTES the lifecycle suites rather than auditing them). Control: `--mutate-evidence` 34/0 — NOT run by this suite; run it by hand when touching audit_manifest
   128	  "gh402-branch-enforcement.sh"   # GH-402 (a marathon refuses to commit to the RECEIVING repo's shared trunk; --allow-trunk-commit and preflight's risk=1 carve-out are the two documented ways past) — 13/0; control in test/baselines/GH-402-negative-control.md: 8 red pre-fix, with the pre-fix run observed COMMITTING to trunk. Fires only when origin/HEAD resolves — a repo with no remote shares nothing and `git reset` undoes it, asserted as an explicit non-block
   129	  "gh386-turn-budget-honesty.sh"  # GH-386 (one wall-clock default across all five builders on both lanes; the packet's budget names turn_timeout_s, the field marathon.sh actually reads) — 10/0; control in test/baselines/GH-386-negative-control.md: 9 red pre-fix. Part C EXERCISES the shipped sizing ladder and requires every suggestion to be >= the default — the assertion a partial fix (raise the cap, forget the ladder) fails
   130	  "gh514-write-set-trackable.sh"  # GH-514 (the target is proven able to TRACK the run's write-set before dispatch; a hostile ignore rule gets an actionable refusal naming the rule and the remedy, not an unhandled CalledProcessError traceback) — 12/0; control in test/baselines/GH-514-negative-control.md: 6 red pre-fix. Note the corrected framing recorded there: "no dispatch" does NOT discriminate (the render's own git add already dies first) — the traceback assertion does
   131	  "gh426-worktree-leak.sh"       # GH-426 (an isolated turn's creation is absent from BOTH the target and the harness) — 7/0; control in test/baselines/GH-426-negative-control.md: 2 red here + 1 red in gh410's C4c. The reported cause (worktree teardown) is FALSIFIED and the suite pins the real one: the agent binary is invoked twice, and the GH-375 auth probe ran with the caller's CWD, outside containment
   132	  "gh384-crash-recovery.sh"      # GH-384 (marathon-recover.sh actually DISTINGUISHES a gated phase from an ungated one, in one repo, one run) — 19/0; control in test/baselines/GH-384-negative-control.md is a MUTATION pair (the tool already shipped, so there is no pre-fix revision): detection removed → 2 red, verdict decoupled from the approval event → 1 red. Also pins read-only (tree byte-identical) and the STALE/LIVE lock distinction
   133	  "gh388-run-log-durability.sh"  # GH-388 (the harness owns a durable chain run log; a phase KILLED mid-run leaves a content-bearing record; rtl_default_log refuses rather than silently relocating to volatile storage) — 24/0; control in test/baselines/GH-388-negative-control.md: 9 red pre-fix. Part C/D actually kill a running phase and a running chain — a green success path proves nothing on this issue
   134	  "gh409-claim-leak.sh"          # GH-409 P2 (a turn that fails releases its claim, on the three paths that never reach rtl_enforce) — 8/0; control in test/baselines/GH-409-negative-control.md: 4 red pre-fix. Every case fails TWICE before asserting, because the cap is 2 and one leak is invisible
   135	  "gh438-removal-is-progress.sh" # GH-438 PARTIAL (a removal counts as a phase delta) — 6/0; controls: untouched artifact + newly empty file still rejected. fix_probe re-evaluation NOT covered; issue stays open
   136	  "gh438-acceptance-recheck.sh" # GH-438 P2 (the lane's own fix_probes re-read after the build; a still-unfixed probe escalates) — 14/0; controls: fix-really-lands completes, no-contract byte-identical, --dry-run runs none, builder cannot rewrite its own criteria
   137	  "gh467-index-only-lane-blocked.sh" # GH-467 (an undeclared index-only lane BLOCKS before dispatch; the builder git ban stays explicit)
   138	  "hq-marathon-live.sh"          # GH-218 (cross-repo live marathon status)
   139	  "debug-mantra.sh"              # GH-162 (debug-mantra auto-trigger note on a phase's prior attempt)
   140	  "lane-attempt-cap.sh"
   141	  "driver-lock.sh"
   142	  "measure.sh"
   143	  "loop-stop.sh"
   144	  "oracle-guard.sh"
   145	  "champion.sh"
   146	  "heldout-check.sh"
   147	  "loop-cost.sh"
   148	  "improve-loop.sh"
   149	  "improve-loop-qa.sh"
   150	  "improve-loop-dogfood.sh"
   151	  "marathon.sh"
   152	  "gh484-phase-dir-default.sh"   # GH-484 (phase-output default is marathon-system/; --phases-dir still overrides; the dirty-tree exclusion tracks the CONFIGURED dir) — 10/0; controls: pre-fix red on both defaults and both containment cases, plus a stray-file control proving the clean check actually ran. Forces XYZ_PYTHON=0 so the Bash twin is really exercised
   153	  "marathon-root-audit.sh"       # GH-209 (static audit: every test/marathon*.sh invocation is MARATHON_ROOT-scoped)
   154	  "rtl-orphan-backup.sh"         # GH-141 (concurrent peer-edit race: revert unchanged, content recoverable)
   155	  "consult.sh"
   156	  "deep-research.sh"             # GH-87 (provider-agnostic grounded-search adapter)
   157	  "relay-pkg-freshness.sh"
   158	  "skill-extract.sh"
   159	  "path-integrity.sh"
   160	  "relay-turn-timeout.sh"
   161	  "relay-target-root.sh"
   162	  "relay-target-root-paths.sh"
   163	  "relay-target-root-relayfile.sh"
   164	  "relay-target-root-newfile.sh"
   165	  "gh289-target-root-build-turn.sh"  # GH-289 (foreign relay Log: BUILD refuses before discarding it)
   166	  "archive-root.sh"              # GH-30 Phase 1 (transcript-root resolver: unset/set/missing/non-git)
   167	  "archive-writers.sh"           # GH-30 Phase 2 (writers honor the resolver: consult e2e + structural)
   168	  "archive-commit.sh"            # GH-30 Phase 3 (Model A: transcript → archive repo, code+.tick → target)
   169	  "archive-telemetry.sh"         # GH-30 Phase 4 (telemetry reads the resolver: archive aggregation + unset)
   170	  "relay-token-collision.sh"
   171	  "relay-escalation-not-stall.sh"
   172	  "relay-untracked-file-warn.sh"
   173	  "relay-file-seeding-visibility.sh"  # GH-178 B2
   174	  "gh304-vendored-relay-path.sh"      # GH-304 (vendored-.xyz relay path: prompt + seeding + gitignored-file message)
   175	  "relay-review-once.sh"
   176	  "relay-artifact-file.sh"
   177	  "relay-turn-handoff.sh"
   178	  "relay-dep-drift.sh"
   179	  "new-relay.sh"
   180	  "agent2agent.sh"              # GH-497 (compact six-digit rendezvous + serialized 2+ agent routing)
   181	  "gh268-relay-cue-and-target-checks.sh" # GH-268 items 7+8 (handoff cue every turn, reviewer file sweep, target-repo gate)
   182	  "xyz-vendor.sh"
   183	  "xyz-sync-check.sh"            # GH-96 (xyz-sync check: tick_version/source_commit drift report)
   184	  "gh293-vendored-guard-drift.sh" # GH-293 (safety-guard manifest + safe fleet-update source gate)
   185	  "relay-concurrent-commit.sh"
   186	  "relay-commit-pathspec.sh"     # GH-198 (rtl_enforce commit is file-scoped, no pathspec regression)
   187	  "relay-case-insensitive.sh"
   188	  "relay-xyz-skill-guard.sh"
   189	  "find-harness.sh"
   190	  "gh292-worktree-vendored-discovery.sh"  # GH-292 (linked worktree resolves main-checkout .xyz/)
   191	  "pdda-roadmap-coverage.sh"
   192	  "pdda-repo-contract.sh"       # GH-311 (real-repository PDDA deterministic contract)
   193	  "pdda-local-checks.sh"        # the checks the 2026-08-03 PDDA sync deleted, restored outside the sync surface
   194	  "gh460-pipe-buffer-sigpipe.sh" # GH-460 (the tier1 "flake" was a SIGPIPE race against the pipe buffer under pipefail, not a flaky assertion) — 8/0; control: the pre-fix shape exits 141 on a >64KB payload whose marker IS present, and passes on a payload that fits
   195	  "gh284-p3-release-milestone.sh" # GH-284 P3 (RELEASES.md Milestone: join key + the releases check's first test)
   196	  "gh284-p4-release-lanes.sh"   # GH-284 P4 (milestone seed + landed-on-trunk rollup: scope-claim matcher)
   197	  "swarm-preflight.sh"
   198	  "ci-workflow.sh"
   199	  "ci-route.sh"                  # GH-509 (docs/fast/full routing + changed-area test selection)
   200	  "gh509-gate-evidence.sh"       # GH-509 (per-commit local gate record + the operator surface)
   201	  "xyz-completion.sh"
   202	  "gh358-lock-instrumentation.sh" # GH-358 (concurrent append reports lost writes vs lock starvation)
   203	  "xyz-harness-hooks.sh"
   204	  "preflight-docs.sh"
   205	  "roadmap-dashboard.sh"
   206	  "marathon-plan.sh"
   207	  "hq.sh"                        # GH-128 Phase 1 (HQ resolver + read-only project card)
   208	  "hq-park.sh"                   # GH-128 Phase 2 (HQ issue-first intake writer: preview + --create)
   209	  "hq-park-synthesis.sh"         # GH-164 Phase 1 (fuller PDDA skeleton template + synthesis passthrough + dashboard regen)
   210	  "hq-dispatch.sh"               # GH-128 Phase 3 (HQ queue: append lane · fire: gated hand-off)
   211	  "hq-next.sh"                   # GH-128 Phase 4 (HQ next: Rebalance-priority project board)
   212	  "hq-locator.sh"                # GH-128 Phase 4 (find-hq.sh: device-agnostic locator, user-level /hq)
   213	  "hq-hardening.sh"              # GH-132 (resolution/dispatch hardening: owner/repo, stale-path, YAML, glob)
   214	  "hq-promote.sh"                # GH-138 (HQ promote: 1-INBOX→2-WORKING scaffolder + marathon glob broadening)
   215	  "mktemp-trap-guard.sh"         # GH-177 (static audit: no unguarded mktemp-into-destructive-rm-rf/cd-recapture pattern anywhere in the repo)
   216	  "hq-marathon-scan.sh"          # GH-158 (cross-repo marathon aggregation + preflight — written, never registered until GH-192)
   217	  "hq-rollup.sh"                 # GH-192 (marathon-scan.sh bridged verbatim into the Obsidian daily rollup)
   218	  "transcript-audit.sh"
   219	  "security-scan.sh"
   220	  "sentinel-tier1.sh"           # GH-281 (Tier-1 JSONL finding capture)
   221	  "sentinel-network-guard.sh"   # GH-281 (bundled scripts stay zero-network)
   222	  "sentinel-driver-hooks.sh"    # GH-281 (marathon-drive.sh Tier-1 hooks: default-off + on-mode append)
   223	  "sentinel-overlay.sh"         # GH-281 (Tier-2 overlay: static egress guard + inert-by-default proof)
   224	  "checkjs.sh"
   225	  "acorn-extract.sh"             # GH-169
   226	  "registry-lock-concurrency.sh"
   227	  "marathon-monitor.sh"          # GH-88 (cross-repo marathon monitor)
   228	  "signal-triage.sh"             # GH-63 (signal triage stage)
   229	  # GH-40 double-blind Reviewer canaries — each verify-fixture.sh drives the real kernel and exits
   230	  # 0/1, so it plugs straight in. ponytail: the Gamma canary (test/fixtures/gamma-poison/) is
   231	  # deliberately NOT here — it runs the whole validate.sh itself, so nesting it would recurse; it
   232	  # stays a manual check.
   233	  "fixtures/canary-token-reuse/verify-fixture.sh"
   234	  "fixtures/canary-peer-orphan/verify-fixture.sh"
   235	  "fixtures/canary-reviewer-overstep/verify-fixture.sh"
   236	  "phase3-signoff-guard.sh"
   237	  # Live-agent test — auto-skips when agy/codex not on PATH or RELAY_SELF_SUFFICIENCY_SKIP=1.
   238	  # Set RELAY_SELF_SUFFICIENCY_SKIP=1 in CI / keyless environments to avoid the real API call.
   239	  "relay-self-sufficiency.sh"
   240	)
   241	
   242	PASSED=()
   243	FAILED=()
   244	
   245	for t in "${TESTS[@]}"; do
   246	  echo
   247	  echo "==============================="
   248	  echo "Running $t"
   249	  echo "==============================="
   250	  if bash "$HERE/test/$t"; then
   251	    PASSED+=("$t")
   252	  else
   253	    FAILED+=("$t")
   254	  fi
   255	done
   256	
   257	echo
   258	echo "==============================="
   259	echo "Running python3 -m pytest test/test_python_layer.py"
   260	echo "==============================="
   261	if python3 -m pytest "$HERE/test/test_python_layer.py"; then
   262	  PASSED+=("python:test_python_layer.py")
   263	else
   264	  FAILED+=("python:test_python_layer.py")
   265	fi
   266	
   267	echo
   268	echo "==============================="
   269	echo "Summary"
   270	echo "==============================="
   271	TOTAL=$(( ${#TESTS[@]} + 1 ))
   272	echo "passed: ${#PASSED[@]} / ${TOTAL}"
   273	for t in "${PASSED[@]}"; do echo "  + $t"; done
   274	if [ "${#FAILED[@]}" -gt 0 ]; then
   275	  echo "failed:"
   276	  for t in "${FAILED[@]}"; do echo "  - $t"; done
   277	  exit 1
   278	fi
   279	exit 0
     1	#!/usr/bin/env bash
     2	# ci-local.sh — run the tier1 CI job on this machine, step for step.
     3	#
     4	# WHY THIS EXISTS: GitHub Actions is metered. Every push burned budget to learn things a laptop can
     5	# tell you for free, and when the budget ran out `gh pr checks` started reporting `fail` in 2 seconds
     6	# on every commit — not a test failure, but "the job was not started because recent account payments
     7	# have failed". A red check that means nothing is worse than no check, because a real break looks
     8	# identical. This runs the same steps locally so the signal keeps existing.
     9	#
    10	# It follows .github/workflows/ci.yml's job in ORDER and CONTENT, but NOT in coverage — see the
    11	# section below. test/ci-workflow.sh pins the parts that must not drift.
    12	#
    13	# ─────────────────────────────────────────────────────────────────────────────────────────────────
    14	# THIS RUNS ON THE PLATFORM WE SHIP TO. THE HOSTED UBUNTU JOB DOES NOT. (GH-509)
    15	# ─────────────────────────────────────────────────────────────────────────────────────────────────
    16	# XYZ is a local developer toolkit for macOS developers. Linux and Windows support are on the roadmap
    17	# and are not here yet. So the direction of the old caveat here — "a green local run does not mean a
    18	# green ubuntu run" — was true but pointed at the less useful risk. Reversed and stated properly:
    19	#
    20	#   * A green run HERE is the best evidence we have about what users experience, because your machine
    21	#     is the shipping platform with the real toolchain.
    22	#   * A green run on hosted UBUNTU says little. That job is an advisory portability canary; its red
    23	#     means "would not work on a platform we do not support yet", not "broken".
    24	#
    25	# This script therefore runs MORE than the hosted job, on purpose. It does not skip
    26	# `registry-lock-concurrency.sh` — the workflow's own comment says that suite "passes locally" and
    27	# flakes only under contended Linux CI, so skipping it here discarded real macOS signal to imitate a
    28	# machine no user has.
    29	#
    30	# THE HONEST LIMIT IS NOW ELSEWHERE, and it is not about platform. This run is SELF-REPORTED: it
    31	# proves someone ran the suite, not that they ran it on the code they are shipping. That is what the
    32	# hosted macOS boundary job buys — a clean machine, and evidence not produced by the claimant.
    33	# ─────────────────────────────────────────────────────────────────────────────────────────────────
    34	#
    35	# Usage:
    36	#   ./ci-local.sh              # every step (~15-20 min; the suite dominates)
    37	#   ./ci-local.sh --fast       # everything EXCEPT the full validate.sh suite (~1 min)
    38	#   ./ci-local.sh --base REF   # also run the frozen-twin guard against REF (CI does this on PRs only)
    39	#   ./ci-local.sh --probe      # GH-509: the UNCONFIGURED-MAC probe (see below)
    40	#
    41	# ── --probe: what a new adopter's machine actually looks like (GH-509 / GH-520) ──────────────────
    42	# Runs with `codex`, `agy` and `aider` stripped from PATH, simulating a Mac where XYZ has just been
    43	# installed and none of the agent CLIs are set up yet. That is a real audience, not a hypothetical:
    44	# GH-380 describes someone installing Claude Code specifically to run the swarm, with nothing else on
    45	# the box.
    46	#
    47	# It is also the only cheap way to catch a whole defect class. On 2026-08-12 three suites passed here
    48	# and failed in CI purely because those binaries exist on this machine and not on a runner (#520).
    49	# This probe reproduced all three in ~90 seconds. It is NOT a Linux check — it is a
    50	# "does-this-work-before-the-operator-has-installed-everything" check, and it belongs on the same
    51	# platform we ship to.
    52	#
    53	# ── The per-commit record, and what it is NOT (GH-509) ───────────────────────────────────────────
    54	# A successful full run writes `.gate-evidence/<sha>.txt`. That answers exactly one question — "has
    55	# anyone run the whole suite against THIS commit?" — so an agent or operator can tell a verified HEAD
    56	# from an unverified one without re-running 15 minutes of tests on a hunch.
    57	#
    58	# It is deliberately NOT promotion evidence. An earlier draft of the GH-509 plan let a local record
    59	# qualify a commit for promotion; the agy review called that circular and was right — if a
    60	# self-reported record satisfies the boundary, the boundary is optional and buys nothing. Promotion
    61	# needs the hosted macOS run. This record is for the day-to-day question, not the release question.
    62	#
    63	# Refused from a dirty tree, and that refusal is the whole integrity story: a record keyed to a
    64	# commit hash while uncommitted edits sit in the tree would name a state that was never tested.
    65	
    66	set -uo pipefail
    67	
    68	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    69	cd "$HERE" || exit 1
    70	
    71	FAST=0
    72	BASE=""
    73	PROBE=0
    74	while (($#)); do
    75	  case "$1" in
    76	    --fast) FAST=1; shift ;;
    77	    --probe) PROBE=1; shift ;;
    78	    --base) BASE="${2:-}"; shift 2 ;;
    79	    -h|--help) sed -n '1,60p' "$0"; exit 0 ;;
    80	    *) echo "ci-local: unknown argument: $1" >&2; exit 2 ;;
    81	  esac
    82	done
    83	
    84	# GH-509/GH-520 — strip the agent CLIs from PATH for the probe. Done by rebuilding PATH without the
    85	# directories that hold them, rather than by unsetting *_BIN vars: the failure being reproduced is a
    86	# binary that is not on PATH at all, and a shim that falls back to a PATH lookup would defeat a
    87	# variable-only approach.
    88	if [ "$PROBE" -eq 1 ]; then
    89	  probe_dirs=""
    90	  for c in codex agy aider; do
    91	    p="$(command -v "$c" 2>/dev/null || true)"
    92	    [ -n "$p" ] && probe_dirs="$probe_dirs $(dirname "$p")"
    93	  done
    94	  if [ -n "$probe_dirs" ]; then
    95	    new_path=""
    96	    while IFS= read -r d; do
    97	      [ -n "$d" ] || continue
    98	      skip=0
    99	      for pd in $probe_dirs; do [ "$d" = "$pd" ] && { skip=1; break; }; done
   100	      [ "$skip" -eq 1 ] && continue
   101	      new_path="${new_path:+$new_path:}$d"
   102	    done < <(printf '%s\n' "${PATH//:/$'\n'}")
   103	    PATH="$new_path"; export PATH
   104	  fi
   105	  # Assert the condition rather than assume it. A probe that silently ran with the binaries still
   106	  # present would report green and mean nothing — the exact shape of failure this repo keeps paying
   107	  # for, and the reason GH-520's control aborts on the same check.
   108	  still=""
   109	  for c in codex agy aider; do command -v "$c" >/dev/null 2>&1 && still="$still $c"; done
   110	  if [ -n "$still" ]; then
   111	    echo "ci-local --probe: ABORT — still on PATH:$still (the probe would be meaningless)" >&2
   112	    exit 2
   113	  fi
   114	  printf '\033[33mmode: --probe (codex/agy/aider stripped from PATH — simulating a fresh Mac)\033[0m\n'
   115	fi
   116	
   117	PASSED=(); FAILED=()
   118	step() {  # <name> — everything after is the step body, run in a subshell
   119	  local name="$1"; shift
   120	  printf '\n\033[1m=== %s\033[0m\n' "$name"
   121	  if "$@"; then PASSED+=("$name"); else FAILED+=("$name"); printf '\033[31mFAILED: %s\033[0m\n' "$name" >&2; fi
   122	}
   123	
   124	# ── 1. prerequisites ─────────────────────────────────────────────────────────────────────────────
   125	# CI apt-installs shellcheck; locally it is the operator's to provide. Checked up front so the run
   126	# does not get 15 minutes in before discovering a missing binary.
   127	check_prereqs() {
   128	  local missing=0 c
   129	  for c in shellcheck bash node python3 npm git; do
   130	    if command -v "$c" >/dev/null 2>&1; then
   131	      printf '  ok       %s\n' "$c"
   132	    else
   133	      printf '  MISSING  %s\n' "$c" >&2; missing=1
   134	    fi
   135	  done
   136	  [ "$missing" -eq 0 ] || {
   137	    echo "  shellcheck: brew install shellcheck   (CI apt-installs it; this is the only extra dep)" >&2
   138	    return 1
   139	  }
   140	  return 0
   141	}
   142	
   143	# ── 2-5. the cheap static checks, verbatim from the workflow ─────────────────────────────────────
   144	shellcheck_tracked() {
   145	  # severity=error, matching the workflow's deliberate choice to land green before tightening.
   146	  local rc=0 file
   147	  while IFS= read -r file; do
   148	    [ -n "$file" ] || continue
   149	    shellcheck -S error "$file" || rc=1
   150	  done < <(git ls-files -- '*.sh')
   151	  return $rc
   152	}
   153	
   154	bash_syntax_tracked() {
   155	  local rc=0 file
   156	  while IFS= read -r file; do
   157	    [ -n "$file" ] || continue
   158	    bash -n "$file" || rc=1
   159	  done < <(git ls-files -- '*.sh')
   160	  return $rc
   161	}
   162	
   163	node_syntax_tracked() {
   164	  local rc=0 file
   165	  while IFS= read -r file; do
   166	    [ -n "$file" ] || continue
   167	    node --check "$file" || rc=1
   168	  done < <(git ls-files -- 'src/*.js' 'bin/*.js')
   169	  return $rc
   170	}
   171	
   172	settings_json_valid() {
   173	  local rc=0 file
   174	  while IFS= read -r file; do
   175	    [ -n "$file" ] || continue
   176	    python3 -m json.tool "$file" >/dev/null || rc=1
   177	  done < <(git ls-files -- '.claude/settings*.json')
   178	  return $rc
   179	}
   180	
   181	# ── 6. PDDA ──────────────────────────────────────────────────────────────────────────────────────
   182	pdda_gate() {
   183	  utils/pdda/pdda.sh run || return 1
   184	  # Warn-only by contract — it reports, it never gates. Kept outside the sync-managed utils/pdda/
   185	  # tree because a 2026-08-03 upstream sync silently deleted three of these checks.
   186	  utils/pdda-local-checks.sh run || true
   187	  return 0
   188	}
   189	
   190	# ── 7. frozen twin guard — PR-only in CI, so opt-in here ─────────────────────────────────────────
   191	frozen_twin_guard() {
   192	  bash test/gh308-frozen-twin-guard.sh --check --base "$BASE" --allow-exceptions
   193	}
   194	
   195	# ── 8. npm + acorn-extract ───────────────────────────────────────────────────────────────────────
   196	# A fresh clone has no node_modules, so acorn-extract dies with MODULE_NOT_FOUND. CI proves the
   197	# README Quickstart path from scratch (GH-230); the same install is what makes a fresh checkout
   198	# gate-ready at all — a marathon has already halted on exactly this.
   199	npm_and_acorn() {
   200	  npm ci || return 1
   201	  bash test/acorn-extract.sh
   202	}
   203	
   204	# ── 9. the suite ─────────────────────────────────────────────────────────────────────────────────
   205	# TESTS is parsed out of validate.sh exactly the way the workflow parses it, so the two cannot drift
   206	# on WHICH tests run — only on the environment they run in.
   207	#
   208	# NOTE: `git config --global` is what CI does before this step, to supply the user identity and
   209	# init.defaultBranch that fixture-driven tests assume. That is deliberately NOT done here: a dev
   210	# machine already has both, and silently rewriting an operator's global git config is not something
   211	# a test runner should do. If a fixture test fails on a bare machine, set them yourself.
   212	validate_suite() {
   213	  # GH-509: THIS SKIP LIST IS DELIBERATELY SHORTER THAN THE WORKFLOW'S, and that is the point.
   214	  #
   215	  # It used to mirror CI's, including `registry-lock-concurrency.sh`. That suite's own skip comment
   216	  # in the workflow reads "flaky under CI load … PASSES LOCALLY" — it fails on a contended shared
   217	  # Linux runner, a machine no XYZ user will ever have. Skipping it here threw away real signal about
   218	  # the platform we actually ship to, in order to stay faithful to a platform we do not.
   219	  #
   220	  # Only ONE skip survives, and it is not a platform concession: acorn-extract.sh already ran in the
   221	  # npm step above, so running it again would be duplicated work rather than dropped coverage.
   222	  local skip_tests=(
   223	    "acorn-extract.sh"                # already run above (needs npm ci first) — duplicate, not dropped
   224	  )
   225	  local all_tests=() line t s skip rc=0
   226	  while IFS= read -r line; do
   227	    [ -n "$line" ] && all_tests+=("$line")
   228	  done < <(sed -n '/^TESTS=(/,/^)/p' validate.sh | grep -oE '"[^"]+\.sh"' | tr -d '"')
   229	
   230	  [ "${#all_tests[@]}" -gt 0 ] || { echo "  could not parse TESTS from validate.sh" >&2; return 1; }
   231	  echo "  ${#all_tests[@]} suites declared in validate.sh"
   232	
   233	  for t in "${all_tests[@]}"; do
   234	    skip=0
   235	    for s in "${skip_tests[@]}"; do [ "$t" = "$s" ] && { skip=1; break; }; done
   236	    [ "$skip" -eq 1 ] && { echo "SKIP (already run above): $t"; continue; }
   237	    echo "=== $t ==="
   238	    bash "test/$t" || { rc=1; echo "  ^^ FAILED: $t" >&2; }
   239	  done
   240	  return $rc
     1	#!/usr/bin/env bash
     2	# gate-env.sh — GH-441 Phase 2. SOURCE this at the top of any `--pre-advance-cmd`.
     3	#
     4	#   . "$(dirname "$0")/relay-automation/gate-env.sh"      # or an absolute path
     5	#
     6	# It clears the variables a live marathon exports that would otherwise flip a suite's verdict, so the
     7	# gate reports on the change under review rather than on its parent.
     8	#
     9	# WHY A HELPER AND NOT A COPIED PROLOGUE
    10	# `validate.sh` used to carry its own hardcoded `unset` line. That worked only for validate.sh: any
    11	# custom gate that did not copy it was silently wrong, and one did — a hand-written gate on
    12	# 2026-08-07 reproduced test/oracle-guard.sh's failure because it inherited ALLOW_PATHS (ambient →
    13	# 10 pass/1 fail; unset → 11/0). It cost two marathon rounds and three clean standalone re-runs
    14	# before the variable was found. A gate cannot be expected to remember a list it does not own.
    15	#
    16	# SINGLE SOURCE OF TRUTH
    17	# The list comes from utils/py/gate_env.py, the same registry `marathon_drive._gate_env()` uses, so
    18	# the shell side and the driver side cannot drift. Do not inline the names here — a second copy of
    19	# the list is the defect this replaces. `test/gh441-gate-env-contract.sh` asserts the two agree.
    20	#
    21	# NOT SCRUBBED: RELAY_DRIVER_LOCKED. Nested drivers need it SET; suites asserting real lock
    22	# acquisition need it UNSET; no global value is correct. Scrubbing it was landed and reverted
    23	# (2026-08-07). The two suites that need it clear do so themselves — GH-441 Phase 1.
    24	
    25	# Resolve the harness root from this script's own location, following symlinks, so sourcing works
    26	# from any CWD and from a vendored .xyz/ install. No machine path is ever hardcoded.
    27	_ge_src="${BASH_SOURCE[0]:-$0}"
    28	while [ -L "$_ge_src" ]; do
    29	  _ge_dir="$(cd -P "$(dirname "$_ge_src")" && pwd)"
    30	  _ge_src="$(readlink "$_ge_src")"
    31	  case "$_ge_src" in /*) ;; *) _ge_src="$_ge_dir/$_ge_src" ;; esac
    32	done
    33	_ge_root="$(cd -P "$(dirname "$_ge_src")/.." && pwd)"
    34	_ge_py="$_ge_root/utils/py/gate_env.py"
    35	
    36	if [ -r "$_ge_py" ]; then
    37	  # One name per line from the registry, applied by an explicit loop.
    38	  #
    39	  # The first draft of this file instead shell-evaluated a generated `unset A B C` line. The GH-64
    40	  # security gate rejected it as `eval-unsanitized` and was right to: nothing should hand generated
    41	  # text to the shell for interpretation when a loop does the same job. This form has no shell
    42	  # evaluation at all, and validates each name against a strict pattern before acting on it.
    43	  #
    44	  # (The rewrite of this very comment was also a finding: the scanner matches the four-letter
    45	  # builtin anywhere in the file, comments included, so the earlier wording tripped it while the
    46	  # code beneath was already clean.)
    47	  # Read one name per line. A `for _ge_n in $_ge_names` loop would be a bug in any shell that does
    48	  # NOT word-split unquoted parameters — zsh does not, so it would pass the whole newline-joined blob
    49	  # as a single name and fail with `invalid parameter name` (observed 2026-08-07). A heredoc-fed
    50	  # `while read` behaves identically in bash and zsh, and unlike a pipe it keeps the loop in the
    51	  # CURRENT shell so the unsets survive.
    52	  _ge_names="$(python3 "$_ge_py" --list-scrubbed 2>/dev/null || true)"
    53	  if [ -n "$_ge_names" ]; then
    54	    while IFS= read -r _ge_n; do
    55	      [ -n "$_ge_n" ] || continue
    56	      case "$_ge_n" in
    57	        [A-Z_][A-Z_0-9]*) unset "$_ge_n" ;;
    58	        *) printf 'gate-env.sh: refusing to unset malformed name from the registry: %s\n' "$_ge_n" >&2 ;;
    59	      esac
    60	    done <<GATE_ENV_NAMES
    61	$_ge_names
    62	GATE_ENV_NAMES
    63	  else
    64	    # Fail LOUDLY rather than leaving the gate contaminated and looking clean. A gate that silently
    65	    # skips its own scrub is the exact shape GH-441 is about: a check reporting a verdict on a
    66	    # question it never asked.
    67	    printf 'gate-env.sh: could not read the scrub list from %s — refusing to run a gate with an ungoverned environment.\n' "$_ge_py" >&2
    68	    printf 'gate-env.sh: (this guard exists because a silently-unscrubbed gate reports its PARENT'\''s failures as the change'\''s own — see GH-441.)\n' >&2
    69	    return 1 2>/dev/null || exit 1
    70	  fi
    71	else
    72	  printf 'gate-env.sh: %s not found — refusing to run a gate with an ungoverned environment (GH-441).\n' "$_ge_py" >&2
    73	  return 1 2>/dev/null || exit 1
    74	fi
    75	
    76	unset _ge_src _ge_dir _ge_root _ge_py _ge_names _ge_n
ci-local.sh:228:  done < <(sed -n '/^TESTS=(/,/^)/p' validate.sh | grep -oE '"[^"]+\.sh"' | tr -d '"')
ci-local.sh:262:  RELAY_SELF_SUFFICIENCY_SKIP=1 step "validate.sh suite" validate_suite
validate.sh:15:TESTS=(
validate.sh:237:  # Live-agent test — auto-skips when agy/codex not on PATH or RELAY_SELF_SUFFICIENCY_SKIP=1.
validate.sh:238:  # Set RELAY_SELF_SUFFICIENCY_SKIP=1 in CI / keyless environments to avoid the real API call.
validate.sh:259:echo "Running python3 -m pytest test/test_python_layer.py"
validate.sh:261:if python3 -m pytest "$HERE/test/test_python_layer.py"; then
relay-automation/xyz-vendor.sh:113:  # (GH-72: the old attempt-count + `sleep 1` gave up in ~5s under contention and wrote UNLOCKED,
relay-automation/xyz-vendor.sh:139:      sleep 0.1 2>/dev/null || sleep 1
relay-automation/xyz-vendor.sh:144:      sleep 0.1 2>/dev/null || sleep 1   # live holder — wait for its (fast) release, then retry
relay-automation/xyz-vendor.sh:300:  #   .relay-driver.lock    live driver lock (a running relay or marathon)
relay-automation/xyz-vendor.sh:303:  for _keep in relay-system .tick .relay-driver.lock XYZ.json XYZ.json.lock XYZ.heartbeat.json; do
test/gh312-vendor-preserves-state.sh:7:# relay-system/ threads, .tick/ event logs, .relay-driver.lock -- was deleted unread. That state is
test/gh312-vendor-preserves-state.sh:24:# The intake report named only relay-system/, .tick/ and .relay-driver.lock. Auditing what `.xyz/`
test/gh312-vendor-preserves-state.sh:33:  printf 'pid=4242\n' > "$REPO/.xyz/.relay-driver.lock"
test/gh312-vendor-preserves-state.sh:46:  [ "$(cat "$REPO/.xyz/.relay-driver.lock" 2>/dev/null)" = "pid=4242" ] \
test/gh312-vendor-preserves-state.sh:47:    && pass "$label: .relay-driver.lock survived" \
test/gh312-vendor-preserves-state.sh:48:    || fail "$label: .relay-driver.lock destroyed"
test/gh419-gate-inventory.sh:12:TESTS=(
test/gh358-lock-instrumentation.sh:52:  sleep 0.05
test/gh358-lock-instrumentation.sh:59:  sleep 20 &
test/gh492-idle-kill.sh:144:# ── (7) the shim honours RELAY_TURN_IDLE_S=0 as 'disable', not as 'kill immediately' ─────────────
test/gh492-idle-kill.sh:148:  && pass "agy-turn guards the idle bound behind idle_cap > 0 (RELAY_TURN_IDLE_S=0 disables it)" \
test/gh492-idle-kill.sh:149:  || fail "agy-turn does not guard the idle bound — RELAY_TURN_IDLE_S=0 would not disable it"
test/gh492-idle-kill.sh:239:# ── (10) consult honours CONSULT_IDLE_S=0 as 'disable', and null-checks the reading ──────────────
test/gh492-idle-kill.sh:241:  && pass "consult guards the idle bound (CONSULT_IDLE_S=0 restores pure wall-cap behaviour)" \
test/gh492-idle-kill.sh:242:  || fail "consult does not guard the idle bound — CONSULT_IDLE_S=0 would not disable it"
test/gh278-turn-timeout-parity.sh:39:                and env.args[0].value == "RELAY_TURN_TIMEOUT_S"
test/gh278-turn-timeout-parity.sh:50:if grep -Fxq 'turn_timeout="${RELAY_TURN_TIMEOUT_S:-900}"' "$SH"; then
test/gh278-turn-timeout-parity.sh:102:sleep 5
test/gh278-turn-timeout-parity.sh:125:  RELAY_TURN_TIMEOUT_S=1 \
relay-automation/consult.sh:61:#   AGY_AUTH_TIMEOUT_S         short wall-clock cap for the agy auth probe (`agy whoami`); default 5.
relay-automation/consult.sh:181:  local out="$1" secs="${AGY_AUTH_TIMEOUT_S:-5}" tmp rc=0
test/gh388-run-log-durability.sh:154:sleep 300
test/gh388-run-log-durability.sh:175:# It also means the `sleep 300` builder cannot outlive the case and wedge the suite.
test/gh388-run-log-durability.sh:196:  sleep 0.5
test/gh388-run-log-durability.sh:210:  sleep 1.5
test/gh388-run-log-durability.sh:214:  # shim, the sleeping stub — is reachable by negating the pid. Without this the `sleep 300` outlives
test/gh388-run-log-durability.sh:281:  sleep 0.5
test/gh388-run-log-durability.sh:302:    sleep 0.5
test/agent2agent.sh:143:sleep 0.1
test/agent2agent.sh:246:  --interval 0.05 --timeout 0.15 --max-turns 1 -- /bin/sleep 5 2>&1)"
test/agent2agent.sh:258:sleep 0.1
test/agent2agent.sh:303:  --message "Close before another driver can dispatch." >/dev/null 2>&1
test/gh390-gate-guard.sh:205:out="$(MARATHON_GATE_WALL_S=3 MARATHON_GATE_CPU_S=0 run_driver --phase-id p3 --pre-advance-cmd 'sleep 60' 2>&1)"; rc=$?
test/gh457-gate-tiers.sh:131:printf '#!/usr/bin/env bash\nsleep 2\nexit 0\n' > "$ROOT/validate.sh"
test/gh457-gate-tiers.sh:143:printf '#!/usr/bin/env bash\nsleep 30\nexit 0\n' > "$ROOT/validate.sh"
relay-automation/marathon-tui.sh:42:  --bind "load:reload-sync(sleep 2; bash '$LS_SCRIPT')" \
test/codex-turn.sh:150:# approval prompt until RELAY_TURN_TIMEOUT_S kills it (exit 7).
test/codex-turn.sh:152:grep -q 'RELAY_TURN_TIMEOUT_S:-900' "$SHIM" && pass "default RELAY_TURN_TIMEOUT_S is 900s" || fail "expected 900s default turn timeout"
test/codex-turn.sh:160:RELAY_TURN_TIMEOUT_S=1 run_shim RELAY-TURN-timeout codex slowafterrelease RELAY_PEER=claude-a; rc=$?
test/codex-turn.sh:161:[ "$rc" -eq 7 ] && pass "turn killed at RELAY_TURN_TIMEOUT_S exits 7" || fail "timeout fixture should exit 7, got $rc"
test/hq-marathon-live.sh:56:: >"$LIVE_REPO/.git/relay-driver.lock"
test/gh342-sentinel-debug-log-python.sh:315:LOCK="$A/.git/relay-driver.lock"
test/swarm-preflight.sh:90:# GH-386: the packet still recommends a budget, but no longer as a bare `RELAY_TURN_TIMEOUT_S=<n>`.
test/relay-turn-timeout.sh:21:sleep 5
test/relay-turn-timeout.sh:48:sleep 5
test/relay-turn-timeout.sh:80:  RELAY_TURN_TIMEOUT_S=1 \
test/relay-turn-timeout.sh:91:  RELAY_TURN_TIMEOUT_S=1 \
test/relay-turn-timeout.sh:106:  RELAY_TURN_TIMEOUT_S=1 \
test/relay-turn-timeout.sh:118:  RELAY_TURN_TIMEOUT_S=1 \
test/relay-turn-timeout.sh:133:  RELAY_TURN_TIMEOUT_S=1 \
test/relay-turn-timeout.sh:145:  RELAY_TURN_TIMEOUT_S=1 \
test/gh448-driver-lock-resolver.sh:91:COMMON_LOCK="$MAIN_REPO/.git/relay-driver.lock"
test/gh448-driver-lock-resolver.sh:121:  if [ -d "$repo/.git" ]; then printf '%s/.git/relay-driver.lock' "$repo"
test/gh448-driver-lock-resolver.sh:122:  else printf '%s/.relay-driver.lock' "$repo"; fi
test/gh448-driver-lock-resolver.sh:128:  [ -e "$repo/.git/relay-driver.lock" ] && { printf '%s' "$repo/.git/relay-driver.lock"; return 0; }
test/gh448-driver-lock-resolver.sh:129:  [ -e "$repo/.xyz/.relay-driver.lock" ] && { printf '%s' "$repo/.xyz/.relay-driver.lock"; return 0; }
test/gh448-driver-lock-resolver.sh:147:for _lk in "$WT/.git/relay-driver.lock" "$WT/.relay-driver.lock"; do
test/gh448-driver-lock-resolver.sh:219:HARNESS_COMMON_LOCK="$HARNESS_MAIN/.git/relay-driver.lock"
relay-automation/pi-turn.sh:66:#   RELAY_TURN_TIMEOUT_S — per-turn wall-clock ceiling in seconds (default: 900). A hung or
relay-automation/pi-turn.sh:164:turn_timeout="${RELAY_TURN_TIMEOUT_S:-900}"
test/gh386-turn-budget-honesty.sh:11:#   2. `swarm-preflight` printed `RELAY_TURN_TIMEOUT_S=<n>` into every packet and NOTHING read it.
test/gh386-turn-budget-honesty.sh:35:  py="$(/usr/bin/grep -oE 'RELAY_TURN_TIMEOUT_S"?,? ?[0-9]+' "$ROOT_DIR/utils/py/$shim-turn.py" 2>/dev/null | /usr/bin/grep -oE '[0-9]+$' | head -1)"
test/gh386-turn-budget-honesty.sh:36:  sh="$(/usr/bin/grep -oE 'RELAY_TURN_TIMEOUT_S:-[0-9]+' "$ROOT_DIR/relay-automation/$shim-turn.sh" 2>/dev/null | /usr/bin/grep -oE '[0-9]+$' | head -1)"
test/gh386-turn-budget-honesty.sh:76:# The dead form must be gone from the packet TEMPLATE. Checked as the rendered `RELAY_TURN_TIMEOUT_S=`
test/gh386-turn-budget-honesty.sh:80:  if /usr/bin/grep -qE 'Suggested turn budget.*RELAY_TURN_TIMEOUT_S=' "$ROOT_DIR/$f"; then
test/gh386-turn-budget-honesty.sh:81:    fail "GH-386: $f still prints a bare RELAY_TURN_TIMEOUT_S=<n> as the suggestion — nothing reads it"
test/gh386-turn-budget-honesty.sh:95:if /usr/bin/grep -q 'RELAY_TURN_TIMEOUT_S="\$turn_timeout_s"' "$ROOT_DIR/relay-automation/marathon.sh"; then
test/ci-workflow.sh:87:skip_block="$(sed -n '/^[[:space:]]*SKIP_TESTS=(/,/^[[:space:]]*)/p' "$WORKFLOW")"
test/ci-workflow.sh:203:if grep -Eq 'TESTS=\(|SKIP_TESTS' <<<"$boundary_block"; then
test/ci-workflow.sh:273:  wf_parse="$(grep -F "sed -n '/^TESTS=(/,/^)/p' validate.sh" "$WORKFLOW" | tr -d ' ')"
test/ci-workflow.sh:274:  cl_parse="$(grep -F "sed -n '/^TESTS=(/,/^)/p' validate.sh" "$CI_LOCAL" | tr -d ' ')"
test/marathon.sh:21:pid=""; cap=""; rev=""; art=""; rtask=""; timeout="${RELAY_TURN_TIMEOUT_S:-}"; lane_ns="${MARATHON_LANE_NS:-}"; pdir=""
test/marathon.sh:39:  RELAY_TURN_TIMEOUT_S= MARATHON_ROOT="$A" MARATHON_DRIVE="$STUB" MARATHON_YAML_BIN="$YBIN" TICK_BIN="$TICK" \
relay-automation/relay-drive.sh:157:  # rather than recomputed: the vendored fallback is the ONLY branch that yields <root>/.relay-driver.lock,
relay-automation/relay-drive.sh:159:  if [[ "$_lock" == "$ROOT_DIR/.relay-driver.lock" ]]; then
relay-automation/relay-drive.sh:160:    _lock_label=".relay-driver.lock"
relay-automation/relay-drive.sh:162:    _lock_label=".git/relay-driver.lock"
relay-automation/relay-drive.sh:169:      printf 'relay-drive: another driver is active in this repo (pid %s, lock: %s).\n' "$_holder" "$_lock_label" >&2
relay-automation/relay-drive.sh:173:    printf 'relay-drive: reclaiming stale relay-driver.lock (holder pid %s not running).\n' "${_holder:-none}" >&2
relay-automation/relay-drive.sh:175:    mkdir "$_lock" 2>/dev/null || { printf 'relay-drive: could not acquire relay-driver.lock after reclaiming a stale one.\n' >&2; exit 1; }
test/relay-loop.sh:71:sleep 2
test/relay-loop.sh:86:for _ in $(seq 1 60); do p="$(cat "$BGPID" 2>/dev/null || true)"; { [ -n "$p" ] && kill -0 "$p" 2>/dev/null; } || break; sleep 0.1; done
test/relay-loop.sh:108:for _ in $(seq 1 60); do p="$(cat "$BGP9" 2>/dev/null || true)"; { [ -n "$p" ] && kill -0 "$p" 2>/dev/null; } || break; sleep 0.1; done
test/relay-loop.sh:126:sleep 2
test/relay-loop.sh:139:for _ in $(seq 1 60); do p="$(cat "$BGP11" 2>/dev/null || true)"; { [ -n "$p" ] && kill -0 "$p" 2>/dev/null; } || break; sleep 0.1; done
test/driver-lock.sh:2:# driver-lock.sh — GH-42 self-heal: marathon-drive reclaims a STALE relay-driver.lock (the holder
test/driver-lock.sh:14:LOCK="$A/.git/relay-driver.lock"
test/litmus-release.sh:230:    echo 'TESTS=('
test/litmus-release.sh:275:  printf 'TESTS=(\n  "gh401-dry-run-no-mutation.sh"\n)\n' > "$FIX2/validate.sh"
test/relay-self-sufficiency.sh:8:# live agent is found on PATH, or when RELAY_SELF_SUFFICIENCY_SKIP=1 is set.
test/relay-self-sufficiency.sh:10:# CI gate: set RELAY_SELF_SUFFICIENCY_SKIP=1 in keyless environments (no API key / network).
test/relay-self-sufficiency.sh:29:if [ "${RELAY_SELF_SUFFICIENCY_SKIP:-0}" = "1" ]; then
test/relay-self-sufficiency.sh:30:  echo "  SKIPPED: RELAY_SELF_SUFFICIENCY_SKIP=1 (CI gate — no live agent in this environment)"
test/nightwatch-release.sh:101:  sed -n '/^TESTS=(/,/^)/p' "$validate" | /usr/bin/grep -qF "\"$base\""
relay-automation/marathon-drive.sh:198:    _lock="$ROOT/.git/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
relay-automation/marathon-drive.sh:202:      _lock="$_git_common_dir/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
relay-automation/marathon-drive.sh:204:      _lock="$ROOT/.relay-driver.lock";           _lock_label=".relay-driver.lock"
relay-automation/marathon-drive.sh:207:    _lock="$ROOT/.relay-driver.lock";     _lock_label=".relay-driver.lock"
relay-automation/marathon-drive.sh:214:      printf 'marathon-drive: another driver is active in this repo (pid %s, lock: %s).\n' "$_holder" "$_lock_label" >&2
relay-automation/marathon-drive.sh:218:    printf 'marathon-drive: reclaiming stale relay-driver.lock (holder pid %s not running).\n' "${_holder:-none}" >&2
relay-automation/marathon-drive.sh:225:    mkdir "$_lock" 2>/dev/null || { printf 'marathon-drive: could not acquire relay-driver.lock after reclaiming a stale one.\n' >&2; exit 1; }
test/marathon-monitor.sh:6:#       - Normal clone: .git/relay-driver.lock/pid
test/marathon-monitor.sh:7:#       - Vendored install: .relay-driver.lock/pid  (no .git/)
test/marathon-monitor.sh:78:# Create .git/relay-driver.lock/pid with our own PID (definitely alive).
test/marathon-monitor.sh:79:mkdir -p "$REPO_LIVE/.git/relay-driver.lock"
test/marathon-monitor.sh:80:printf '%s\n' "$$" > "$REPO_LIVE/.git/relay-driver.lock/pid"
test/marathon-monitor.sh:84:# Fixture 2: STALE — vendored (.relay-driver.lock/) + dead PID
test/marathon-monitor.sh:89:# Create .relay-driver.lock/pid with a dead PID.
test/marathon-monitor.sh:90:mkdir -p "$REPO_STALE/.relay-driver.lock"
test/marathon-monitor.sh:91:printf '%s\n' "999999" > "$REPO_STALE/.relay-driver.lock/pid"
test/marathon-monitor.sh:143:sleep 1   # mtime granularity: `test -nt` is second-resolution on some filesystems
test/marathon-monitor.sh:165:  && pass "LIVE: clone with .git/relay-driver.lock + live pid -> LIVE" \
test/marathon-monitor.sh:170:  && pass "STALE: vendored .relay-driver.lock + dead pid (999999) -> STALE" \
test/marathon-monitor.sh:201:[ -d "$REPO_LIVE/.git/relay-driver.lock" ] \
test/marathon-monitor.sh:202:  && pass "LIVE fixture has .git/relay-driver.lock (clone path)" \
test/marathon-monitor.sh:203:  || fail "LIVE fixture missing .git/relay-driver.lock"
test/marathon-monitor.sh:209:[ -d "$REPO_STALE/.relay-driver.lock" ] \
test/marathon-monitor.sh:210:  && pass "STALE fixture has .relay-driver.lock (vendored path)" \
test/marathon-monitor.sh:211:  || fail "STALE fixture missing .relay-driver.lock"
test/gh375-auth-timeout-verdict.sh:19:# against an AGY_AUTH_TIMEOUT_S default of 5. Under 2x, and concurrent load closed it.
test/gh375-auth-timeout-verdict.sh:147:sleep 30
test/gh375-auth-timeout-verdict.sh:154:    PYTHONPATH="$pydir" AGY_AUTH_TIMEOUT_S=2 python3 -c '
test/gh375-auth-timeout-verdict.sh:160:    PYTHONPATH="$pydir" AGY_AUTH_TIMEOUT_S=2 python3 -c '
test/gh375-auth-timeout-verdict.sh:197:  if grep -q 'AGY_AUTH_TIMEOUT_S", 5)' "$ROOT_REPO/$f"; then
test/gh331-cost-summary.sh:15:# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: hold the clone's .git/relay-driver.lock with a LIVE pid, then run this suite (that is the in-marathon condition; a linked worktree does NOT reproduce it because relay-drive takes a per-worktree lock there, GH-376). pre-fix revision: this file with RELAY_DRIVER_LOCKED unset but the relay-drive invocations unscoped. pre-fix result: FAIL rc=1 'another driver is active in this repo (pid 2436, lock: .git/relay-driver.lock)' — the same failure that halted Litmus wave-2 phase 1 on 2026-08-08 at 893s. post-fix result: 8 pass / 0 fail with the SAME lock still held, and 8 pass / 0 fail with no lock, so the fix is verified in both directions rather than only the one under investigation"}
test/gh331-cost-summary.sh:41:# .git/relay-driver.lock — held by the marathon driver that was running this very gate — and refused:
test/gh331-cost-summary.sh:44:#     relay-drive: another driver is active in this repo (pid 35784, lock: .git/relay-driver.lock).
test/gh331-cost-summary.sh:58:# minus the three it creates or owns itself (.git, .relay-driver.lock, relay-system). Getting this
test/deep-research.sh:40:  hang)     sleep 5 ;;
test/deep-research.sh:176:  for _ in $(seq 1 50); do [ -s "$WORK/or-port" ] && break; sleep 0.1; done
test/gh399-packet-acceptance-continuation.sh:150:# .git/relay-driver.lock in the live repo — hence also the hard timeout below: an unattended suite
test/worktree-isolation.sh:43:  ( sleep 1; printf 'async junk\n' > offlane-async.txt ) &   # async side effect AFTER the turn
test/worktree-isolation.sh:69:sleep 2   # let the detached async write fire (t+1s) against the now-deleted worktree
test/worktree-isolation.sh:115:sleep 2
test/xyz-completion.sh:60:    sleep 0.1
test/gh376-relay-drive-lock-parity.sh:91:COMMON_LOCK="$MAIN/.git/relay-driver.lock"
test/gh376-relay-drive-lock-parity.sh:93:WORKTREE_LOCAL_LOCK="$WT/.relay-driver.lock"
test/gh376-relay-drive-lock-parity.sh:103:  /bin/sleep 300 & HOLDER=$!
test/gh376-relay-drive-lock-parity.sh:125:refused() { printf '%s' "$1" | grep -q 'another driver is active in this repo'; }
test/gh376-relay-drive-lock-parity.sh:155:  && pass "neither lane left a worktree-local lock behind at \$WT/.relay-driver.lock" \
test/gh376-relay-drive-lock-parity.sh:178:       '            lock_dir = os.path.join(root_dir, ".git", "relay-driver.lock")\n'
test/gh376-relay-drive-lock-parity.sh:179:       '            lock_label = ".git/relay-driver.lock"\n'
test/gh376-relay-drive-lock-parity.sh:181:       '            lock_dir = os.path.join(root_dir, ".relay-driver.lock")\n'
test/gh376-relay-drive-lock-parity.sh:182:       '            lock_label = ".relay-driver.lock"\n')
test/gh376-relay-drive-lock-parity.sh:195:  if [ -d "$repo/.git" ]; then printf '%s/.git/relay-driver.lock' "$repo"
test/gh376-relay-drive-lock-parity.sh:196:  else printf '%s/.relay-driver.lock' "$repo"; fi
test/gh376-relay-drive-lock-parity.sh:227:  && pass "CONTROL (python): a normal clone still excludes at .git/relay-driver.lock" \
test/gh376-relay-drive-lock-parity.sh:230:  && pass "CONTROL (bash): a normal clone still excludes at .git/relay-driver.lock" \
test/gh376-relay-drive-lock-parity.sh:238:echo "-- D. control: a vendored copy with no .git falls back to .relay-driver.lock --"
test/gh376-relay-drive-lock-parity.sh:245:hold_lock "$VEND/.relay-driver.lock"
test/gh320-twin-timeout-parity.sh:2:# GH-320: every turn-taker's Python twin must default RELAY_TURN_TIMEOUT_S to the same value as its
test/gh320-twin-timeout-parity.sh:34:  sh_default="$(grep -oE 'turn_timeout="\$\{RELAY_TURN_TIMEOUT_S:-[0-9]+\}"' "$sh_path" \
test/gh320-twin-timeout-parity.sh:36:  py_default="$(grep -oE 'RELAY_TURN_TIMEOUT_S", *[0-9]+' "$py_path" \
test/gh320-twin-timeout-parity.sh:50:  doc_default="$(grep -oE 'RELAY_TURN_TIMEOUT_S — per-turn wall-clock ceiling in seconds \(default: [0-9]+' "$sh_path" \
test/gh320-twin-timeout-parity.sh:53:    fail "$name: $sh_rel header does not document a RELAY_TURN_TIMEOUT_S default"
test/gh407-gate-ran-attribution.sh:14:# whether any pytest output existed anywhere after the phase started.
test/pi-turn.sh:201:RELAY_TURN_TIMEOUT_S=1 run_shim RELAY-TURN-timeout pi slowafterrelease RELAY_PEER=claude-a; rc=$?
test/pi-turn.sh:202:[ "$rc" -eq 7 ] && pass "turn killed at RELAY_TURN_TIMEOUT_S exits 7" || fail "timeout fixture should exit 7, got $rc"
test/pi-turn.sh:205:# --- (12) default RELAY_TURN_TIMEOUT_S is 900s (GH-295 design doc) ----------------------------------
test/pi-turn.sh:206:grep -q 'RELAY_TURN_TIMEOUT_S:-900' "$SHIM" && pass "default RELAY_TURN_TIMEOUT_S is 900s" || fail "expected 900s default turn timeout"
test/consult.sh:113:printf '#!/usr/bin/env bash\nsleep 30\n' >"$SLOW"; chmod +x "$SLOW"
relay-automation/marathon.sh:36:# brief→--phase-brief (required to run), artifact→--artifact, turn_timeout_s→RELAY_TURN_TIMEOUT_S,
relay-automation/marathon.sh:306:      RELAY_TURN_TIMEOUT_S="$turn_timeout_s" \
relay-automation/driver-lock-lib.sh:12:#   .git is a directory  -> <repo>/.git/relay-driver.lock              (normal clone)
relay-automation/driver-lock-lib.sh:13:#   .git is a file       -> <git-common-dir>/relay-driver.lock         (linked worktree)
relay-automation/driver-lock-lib.sh:14:#   no .git (vendored)   -> <repo>/.relay-driver.lock                  (vendored .xyz/ copy)
relay-automation/driver-lock-lib.sh:23:    printf '%s/.git/relay-driver.lock' "$repo"
relay-automation/driver-lock-lib.sh:30:      printf '%s/relay-driver.lock' "$common"
relay-automation/driver-lock-lib.sh:34:  printf '%s/.relay-driver.lock' "$repo"
relay-automation/marathon-ls.sh:46:# FILE and the driver's real lock lives at the git common dir, not <repo>/.git/relay-driver.lock).
relay-automation/xyz-sync.sh:29:#   relay-system/  .tick/  .relay-driver.lock  XYZ.json  XYZ.json.lock/  XYZ.heartbeat.json
relay-automation/codex-turn.sh:40:#                     a headless run until RELAY_TURN_TIMEOUT_S kills it (exit 7), burning a lane
relay-automation/codex-turn.sh:56:#   RELAY_TURN_TIMEOUT_S — per-turn wall-clock ceiling in seconds (default: 900). A hung or
relay-automation/codex-turn.sh:136:# hangs on an interactive approval prompt until RELAY_TURN_TIMEOUT_S kills it (exit 7). Keeps the
relay-automation/codex-turn.sh:145:turn_timeout="${RELAY_TURN_TIMEOUT_S:-900}"
relay-automation/target-checks.sh:122:if has_file "pytest.ini" || has_file "tox.ini" \
relay-automation/target-checks.sh:123:   || { has_file "pyproject.toml" && grep -q 'pytest' "$ROOT/pyproject.toml" 2>/dev/null; }; then
relay-automation/target-checks.sh:124:  add "pytest" "python3" "python3 -m pytest -q"
relay-automation/target-checks.sh:142:  say "              pytest/ruff config, Makefile test:, validate.sh"
relay-automation/agy-turn.sh:52:#   AGY_AUTH_TIMEOUT_S — short wall-clock cap for the auth pre-flight probe (`agy whoami`);
relay-automation/agy-turn.sh:66:#   RELAY_TURN_TIMEOUT_S — per-turn wall-clock ceiling in seconds (default: 900). A hung or
relay-automation/agy-turn.sh:92:  local secs="${AGY_AUTH_TIMEOUT_S:-5}" out rc=0 line
relay-automation/agy-turn.sh:109:  local model="${AGY_MODEL:-}" secs="${AGY_AUTH_TIMEOUT_S:-5}" out rc=0 line
relay-automation/agy-turn.sh:208:turn_timeout="${RELAY_TURN_TIMEOUT_S:-900}"
relay-automation/aider-turn.sh:70:#   RELAY_TURN_TIMEOUT_S — per-turn wall-clock ceiling in seconds (default: 900). A hung/runaway aider
relay-automation/aider-turn.sh:242:turn_timeout="${RELAY_TURN_TIMEOUT_S:-900}"
relay-automation/claude-turn.sh:69:#   RELAY_TURN_TIMEOUT_S — per-turn wall-clock ceiling in seconds (default: 900, raised from 600 by
relay-automation/claude-turn.sh:204:turn_timeout="${RELAY_TURN_TIMEOUT_S:-900}"

exec
/bin/zsh -lc "nl -ba validate.sh | sed -n '175,390p'; nl -ba ci-local.sh | sed -n '1,180p'; nl -ba relay-automation/gate-env.sh | sed -n '1,180p'; nl -ba relay-automation/driver-lock-lib.sh | sed -n '1,100p'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-86418-h4t1yue0
 succeeded in 0ms:
   175	  "relay-review-once.sh"
   176	  "relay-artifact-file.sh"
   177	  "relay-turn-handoff.sh"
   178	  "relay-dep-drift.sh"
   179	  "new-relay.sh"
   180	  "agent2agent.sh"              # GH-497 (compact six-digit rendezvous + serialized 2+ agent routing)
   181	  "gh268-relay-cue-and-target-checks.sh" # GH-268 items 7+8 (handoff cue every turn, reviewer file sweep, target-repo gate)
   182	  "xyz-vendor.sh"
   183	  "xyz-sync-check.sh"            # GH-96 (xyz-sync check: tick_version/source_commit drift report)
   184	  "gh293-vendored-guard-drift.sh" # GH-293 (safety-guard manifest + safe fleet-update source gate)
   185	  "relay-concurrent-commit.sh"
   186	  "relay-commit-pathspec.sh"     # GH-198 (rtl_enforce commit is file-scoped, no pathspec regression)
   187	  "relay-case-insensitive.sh"
   188	  "relay-xyz-skill-guard.sh"
   189	  "find-harness.sh"
   190	  "gh292-worktree-vendored-discovery.sh"  # GH-292 (linked worktree resolves main-checkout .xyz/)
   191	  "pdda-roadmap-coverage.sh"
   192	  "pdda-repo-contract.sh"       # GH-311 (real-repository PDDA deterministic contract)
   193	  "pdda-local-checks.sh"        # the checks the 2026-08-03 PDDA sync deleted, restored outside the sync surface
   194	  "gh460-pipe-buffer-sigpipe.sh" # GH-460 (the tier1 "flake" was a SIGPIPE race against the pipe buffer under pipefail, not a flaky assertion) — 8/0; control: the pre-fix shape exits 141 on a >64KB payload whose marker IS present, and passes on a payload that fits
   195	  "gh284-p3-release-milestone.sh" # GH-284 P3 (RELEASES.md Milestone: join key + the releases check's first test)
   196	  "gh284-p4-release-lanes.sh"   # GH-284 P4 (milestone seed + landed-on-trunk rollup: scope-claim matcher)
   197	  "swarm-preflight.sh"
   198	  "ci-workflow.sh"
   199	  "ci-route.sh"                  # GH-509 (docs/fast/full routing + changed-area test selection)
   200	  "gh509-gate-evidence.sh"       # GH-509 (per-commit local gate record + the operator surface)
   201	  "xyz-completion.sh"
   202	  "gh358-lock-instrumentation.sh" # GH-358 (concurrent append reports lost writes vs lock starvation)
   203	  "xyz-harness-hooks.sh"
   204	  "preflight-docs.sh"
   205	  "roadmap-dashboard.sh"
   206	  "marathon-plan.sh"
   207	  "hq.sh"                        # GH-128 Phase 1 (HQ resolver + read-only project card)
   208	  "hq-park.sh"                   # GH-128 Phase 2 (HQ issue-first intake writer: preview + --create)
   209	  "hq-park-synthesis.sh"         # GH-164 Phase 1 (fuller PDDA skeleton template + synthesis passthrough + dashboard regen)
   210	  "hq-dispatch.sh"               # GH-128 Phase 3 (HQ queue: append lane · fire: gated hand-off)
   211	  "hq-next.sh"                   # GH-128 Phase 4 (HQ next: Rebalance-priority project board)
   212	  "hq-locator.sh"                # GH-128 Phase 4 (find-hq.sh: device-agnostic locator, user-level /hq)
   213	  "hq-hardening.sh"              # GH-132 (resolution/dispatch hardening: owner/repo, stale-path, YAML, glob)
   214	  "hq-promote.sh"                # GH-138 (HQ promote: 1-INBOX→2-WORKING scaffolder + marathon glob broadening)
   215	  "mktemp-trap-guard.sh"         # GH-177 (static audit: no unguarded mktemp-into-destructive-rm-rf/cd-recapture pattern anywhere in the repo)
   216	  "hq-marathon-scan.sh"          # GH-158 (cross-repo marathon aggregation + preflight — written, never registered until GH-192)
   217	  "hq-rollup.sh"                 # GH-192 (marathon-scan.sh bridged verbatim into the Obsidian daily rollup)
   218	  "transcript-audit.sh"
   219	  "security-scan.sh"
   220	  "sentinel-tier1.sh"           # GH-281 (Tier-1 JSONL finding capture)
   221	  "sentinel-network-guard.sh"   # GH-281 (bundled scripts stay zero-network)
   222	  "sentinel-driver-hooks.sh"    # GH-281 (marathon-drive.sh Tier-1 hooks: default-off + on-mode append)
   223	  "sentinel-overlay.sh"         # GH-281 (Tier-2 overlay: static egress guard + inert-by-default proof)
   224	  "checkjs.sh"
   225	  "acorn-extract.sh"             # GH-169
   226	  "registry-lock-concurrency.sh"
   227	  "marathon-monitor.sh"          # GH-88 (cross-repo marathon monitor)
   228	  "signal-triage.sh"             # GH-63 (signal triage stage)
   229	  # GH-40 double-blind Reviewer canaries — each verify-fixture.sh drives the real kernel and exits
   230	  # 0/1, so it plugs straight in. ponytail: the Gamma canary (test/fixtures/gamma-poison/) is
   231	  # deliberately NOT here — it runs the whole validate.sh itself, so nesting it would recurse; it
   232	  # stays a manual check.
   233	  "fixtures/canary-token-reuse/verify-fixture.sh"
   234	  "fixtures/canary-peer-orphan/verify-fixture.sh"
   235	  "fixtures/canary-reviewer-overstep/verify-fixture.sh"
   236	  "phase3-signoff-guard.sh"
   237	  # Live-agent test — auto-skips when agy/codex not on PATH or RELAY_SELF_SUFFICIENCY_SKIP=1.
   238	  # Set RELAY_SELF_SUFFICIENCY_SKIP=1 in CI / keyless environments to avoid the real API call.
   239	  "relay-self-sufficiency.sh"
   240	)
   241	
   242	PASSED=()
   243	FAILED=()
   244	
   245	for t in "${TESTS[@]}"; do
   246	  echo
   247	  echo "==============================="
   248	  echo "Running $t"
   249	  echo "==============================="
   250	  if bash "$HERE/test/$t"; then
   251	    PASSED+=("$t")
   252	  else
   253	    FAILED+=("$t")
   254	  fi
   255	done
   256	
   257	echo
   258	echo "==============================="
   259	echo "Running python3 -m pytest test/test_python_layer.py"
   260	echo "==============================="
   261	if python3 -m pytest "$HERE/test/test_python_layer.py"; then
   262	  PASSED+=("python:test_python_layer.py")
   263	else
   264	  FAILED+=("python:test_python_layer.py")
   265	fi
   266	
   267	echo
   268	echo "==============================="
   269	echo "Summary"
   270	echo "==============================="
   271	TOTAL=$(( ${#TESTS[@]} + 1 ))
   272	echo "passed: ${#PASSED[@]} / ${TOTAL}"
   273	for t in "${PASSED[@]}"; do echo "  + $t"; done
   274	if [ "${#FAILED[@]}" -gt 0 ]; then
   275	  echo "failed:"
   276	  for t in "${FAILED[@]}"; do echo "  - $t"; done
   277	  exit 1
   278	fi
   279	exit 0
     1	#!/usr/bin/env bash
     2	# ci-local.sh — run the tier1 CI job on this machine, step for step.
     3	#
     4	# WHY THIS EXISTS: GitHub Actions is metered. Every push burned budget to learn things a laptop can
     5	# tell you for free, and when the budget ran out `gh pr checks` started reporting `fail` in 2 seconds
     6	# on every commit — not a test failure, but "the job was not started because recent account payments
     7	# have failed". A red check that means nothing is worse than no check, because a real break looks
     8	# identical. This runs the same steps locally so the signal keeps existing.
     9	#
    10	# It follows .github/workflows/ci.yml's job in ORDER and CONTENT, but NOT in coverage — see the
    11	# section below. test/ci-workflow.sh pins the parts that must not drift.
    12	#
    13	# ─────────────────────────────────────────────────────────────────────────────────────────────────
    14	# THIS RUNS ON THE PLATFORM WE SHIP TO. THE HOSTED UBUNTU JOB DOES NOT. (GH-509)
    15	# ─────────────────────────────────────────────────────────────────────────────────────────────────
    16	# XYZ is a local developer toolkit for macOS developers. Linux and Windows support are on the roadmap
    17	# and are not here yet. So the direction of the old caveat here — "a green local run does not mean a
    18	# green ubuntu run" — was true but pointed at the less useful risk. Reversed and stated properly:
    19	#
    20	#   * A green run HERE is the best evidence we have about what users experience, because your machine
    21	#     is the shipping platform with the real toolchain.
    22	#   * A green run on hosted UBUNTU says little. That job is an advisory portability canary; its red
    23	#     means "would not work on a platform we do not support yet", not "broken".
    24	#
    25	# This script therefore runs MORE than the hosted job, on purpose. It does not skip
    26	# `registry-lock-concurrency.sh` — the workflow's own comment says that suite "passes locally" and
    27	# flakes only under contended Linux CI, so skipping it here discarded real macOS signal to imitate a
    28	# machine no user has.
    29	#
    30	# THE HONEST LIMIT IS NOW ELSEWHERE, and it is not about platform. This run is SELF-REPORTED: it
    31	# proves someone ran the suite, not that they ran it on the code they are shipping. That is what the
    32	# hosted macOS boundary job buys — a clean machine, and evidence not produced by the claimant.
    33	# ─────────────────────────────────────────────────────────────────────────────────────────────────
    34	#
    35	# Usage:
    36	#   ./ci-local.sh              # every step (~15-20 min; the suite dominates)
    37	#   ./ci-local.sh --fast       # everything EXCEPT the full validate.sh suite (~1 min)
    38	#   ./ci-local.sh --base REF   # also run the frozen-twin guard against REF (CI does this on PRs only)
    39	#   ./ci-local.sh --probe      # GH-509: the UNCONFIGURED-MAC probe (see below)
    40	#
    41	# ── --probe: what a new adopter's machine actually looks like (GH-509 / GH-520) ──────────────────
    42	# Runs with `codex`, `agy` and `aider` stripped from PATH, simulating a Mac where XYZ has just been
    43	# installed and none of the agent CLIs are set up yet. That is a real audience, not a hypothetical:
    44	# GH-380 describes someone installing Claude Code specifically to run the swarm, with nothing else on
    45	# the box.
    46	#
    47	# It is also the only cheap way to catch a whole defect class. On 2026-08-12 three suites passed here
    48	# and failed in CI purely because those binaries exist on this machine and not on a runner (#520).
    49	# This probe reproduced all three in ~90 seconds. It is NOT a Linux check — it is a
    50	# "does-this-work-before-the-operator-has-installed-everything" check, and it belongs on the same
    51	# platform we ship to.
    52	#
    53	# ── The per-commit record, and what it is NOT (GH-509) ───────────────────────────────────────────
    54	# A successful full run writes `.gate-evidence/<sha>.txt`. That answers exactly one question — "has
    55	# anyone run the whole suite against THIS commit?" — so an agent or operator can tell a verified HEAD
    56	# from an unverified one without re-running 15 minutes of tests on a hunch.
    57	#
    58	# It is deliberately NOT promotion evidence. An earlier draft of the GH-509 plan let a local record
    59	# qualify a commit for promotion; the agy review called that circular and was right — if a
    60	# self-reported record satisfies the boundary, the boundary is optional and buys nothing. Promotion
    61	# needs the hosted macOS run. This record is for the day-to-day question, not the release question.
    62	#
    63	# Refused from a dirty tree, and that refusal is the whole integrity story: a record keyed to a
    64	# commit hash while uncommitted edits sit in the tree would name a state that was never tested.
    65	
    66	set -uo pipefail
    67	
    68	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    69	cd "$HERE" || exit 1
    70	
    71	FAST=0
    72	BASE=""
    73	PROBE=0
    74	while (($#)); do
    75	  case "$1" in
    76	    --fast) FAST=1; shift ;;
    77	    --probe) PROBE=1; shift ;;
    78	    --base) BASE="${2:-}"; shift 2 ;;
    79	    -h|--help) sed -n '1,60p' "$0"; exit 0 ;;
    80	    *) echo "ci-local: unknown argument: $1" >&2; exit 2 ;;
    81	  esac
    82	done
    83	
    84	# GH-509/GH-520 — strip the agent CLIs from PATH for the probe. Done by rebuilding PATH without the
    85	# directories that hold them, rather than by unsetting *_BIN vars: the failure being reproduced is a
    86	# binary that is not on PATH at all, and a shim that falls back to a PATH lookup would defeat a
    87	# variable-only approach.
    88	if [ "$PROBE" -eq 1 ]; then
    89	  probe_dirs=""
    90	  for c in codex agy aider; do
    91	    p="$(command -v "$c" 2>/dev/null || true)"
    92	    [ -n "$p" ] && probe_dirs="$probe_dirs $(dirname "$p")"
    93	  done
    94	  if [ -n "$probe_dirs" ]; then
    95	    new_path=""
    96	    while IFS= read -r d; do
    97	      [ -n "$d" ] || continue
    98	      skip=0
    99	      for pd in $probe_dirs; do [ "$d" = "$pd" ] && { skip=1; break; }; done
   100	      [ "$skip" -eq 1 ] && continue
   101	      new_path="${new_path:+$new_path:}$d"
   102	    done < <(printf '%s\n' "${PATH//:/$'\n'}")
   103	    PATH="$new_path"; export PATH
   104	  fi
   105	  # Assert the condition rather than assume it. A probe that silently ran with the binaries still
   106	  # present would report green and mean nothing — the exact shape of failure this repo keeps paying
   107	  # for, and the reason GH-520's control aborts on the same check.
   108	  still=""
   109	  for c in codex agy aider; do command -v "$c" >/dev/null 2>&1 && still="$still $c"; done
   110	  if [ -n "$still" ]; then
   111	    echo "ci-local --probe: ABORT — still on PATH:$still (the probe would be meaningless)" >&2
   112	    exit 2
   113	  fi
   114	  printf '\033[33mmode: --probe (codex/agy/aider stripped from PATH — simulating a fresh Mac)\033[0m\n'
   115	fi
   116	
   117	PASSED=(); FAILED=()
   118	step() {  # <name> — everything after is the step body, run in a subshell
   119	  local name="$1"; shift
   120	  printf '\n\033[1m=== %s\033[0m\n' "$name"
   121	  if "$@"; then PASSED+=("$name"); else FAILED+=("$name"); printf '\033[31mFAILED: %s\033[0m\n' "$name" >&2; fi
   122	}
   123	
   124	# ── 1. prerequisites ─────────────────────────────────────────────────────────────────────────────
   125	# CI apt-installs shellcheck; locally it is the operator's to provide. Checked up front so the run
   126	# does not get 15 minutes in before discovering a missing binary.
   127	check_prereqs() {
   128	  local missing=0 c
   129	  for c in shellcheck bash node python3 npm git; do
   130	    if command -v "$c" >/dev/null 2>&1; then
   131	      printf '  ok       %s\n' "$c"
   132	    else
   133	      printf '  MISSING  %s\n' "$c" >&2; missing=1
   134	    fi
   135	  done
   136	  [ "$missing" -eq 0 ] || {
   137	    echo "  shellcheck: brew install shellcheck   (CI apt-installs it; this is the only extra dep)" >&2
   138	    return 1
   139	  }
   140	  return 0
   141	}
   142	
   143	# ── 2-5. the cheap static checks, verbatim from the workflow ─────────────────────────────────────
   144	shellcheck_tracked() {
   145	  # severity=error, matching the workflow's deliberate choice to land green before tightening.
   146	  local rc=0 file
   147	  while IFS= read -r file; do
   148	    [ -n "$file" ] || continue
   149	    shellcheck -S error "$file" || rc=1
   150	  done < <(git ls-files -- '*.sh')
   151	  return $rc
   152	}
   153	
   154	bash_syntax_tracked() {
   155	  local rc=0 file
   156	  while IFS= read -r file; do
   157	    [ -n "$file" ] || continue
   158	    bash -n "$file" || rc=1
   159	  done < <(git ls-files -- '*.sh')
   160	  return $rc
   161	}
   162	
   163	node_syntax_tracked() {
   164	  local rc=0 file
   165	  while IFS= read -r file; do
   166	    [ -n "$file" ] || continue
   167	    node --check "$file" || rc=1
   168	  done < <(git ls-files -- 'src/*.js' 'bin/*.js')
   169	  return $rc
   170	}
   171	
   172	settings_json_valid() {
   173	  local rc=0 file
   174	  while IFS= read -r file; do
   175	    [ -n "$file" ] || continue
   176	    python3 -m json.tool "$file" >/dev/null || rc=1
   177	  done < <(git ls-files -- '.claude/settings*.json')
   178	  return $rc
   179	}
   180	
     1	#!/usr/bin/env bash
     2	# gate-env.sh — GH-441 Phase 2. SOURCE this at the top of any `--pre-advance-cmd`.
     3	#
     4	#   . "$(dirname "$0")/relay-automation/gate-env.sh"      # or an absolute path
     5	#
     6	# It clears the variables a live marathon exports that would otherwise flip a suite's verdict, so the
     7	# gate reports on the change under review rather than on its parent.
     8	#
     9	# WHY A HELPER AND NOT A COPIED PROLOGUE
    10	# `validate.sh` used to carry its own hardcoded `unset` line. That worked only for validate.sh: any
    11	# custom gate that did not copy it was silently wrong, and one did — a hand-written gate on
    12	# 2026-08-07 reproduced test/oracle-guard.sh's failure because it inherited ALLOW_PATHS (ambient →
    13	# 10 pass/1 fail; unset → 11/0). It cost two marathon rounds and three clean standalone re-runs
    14	# before the variable was found. A gate cannot be expected to remember a list it does not own.
    15	#
    16	# SINGLE SOURCE OF TRUTH
    17	# The list comes from utils/py/gate_env.py, the same registry `marathon_drive._gate_env()` uses, so
    18	# the shell side and the driver side cannot drift. Do not inline the names here — a second copy of
    19	# the list is the defect this replaces. `test/gh441-gate-env-contract.sh` asserts the two agree.
    20	#
    21	# NOT SCRUBBED: RELAY_DRIVER_LOCKED. Nested drivers need it SET; suites asserting real lock
    22	# acquisition need it UNSET; no global value is correct. Scrubbing it was landed and reverted
    23	# (2026-08-07). The two suites that need it clear do so themselves — GH-441 Phase 1.
    24	
    25	# Resolve the harness root from this script's own location, following symlinks, so sourcing works
    26	# from any CWD and from a vendored .xyz/ install. No machine path is ever hardcoded.
    27	_ge_src="${BASH_SOURCE[0]:-$0}"
    28	while [ -L "$_ge_src" ]; do
    29	  _ge_dir="$(cd -P "$(dirname "$_ge_src")" && pwd)"
    30	  _ge_src="$(readlink "$_ge_src")"
    31	  case "$_ge_src" in /*) ;; *) _ge_src="$_ge_dir/$_ge_src" ;; esac
    32	done
    33	_ge_root="$(cd -P "$(dirname "$_ge_src")/.." && pwd)"
    34	_ge_py="$_ge_root/utils/py/gate_env.py"
    35	
    36	if [ -r "$_ge_py" ]; then
    37	  # One name per line from the registry, applied by an explicit loop.
    38	  #
    39	  # The first draft of this file instead shell-evaluated a generated `unset A B C` line. The GH-64
    40	  # security gate rejected it as `eval-unsanitized` and was right to: nothing should hand generated
    41	  # text to the shell for interpretation when a loop does the same job. This form has no shell
    42	  # evaluation at all, and validates each name against a strict pattern before acting on it.
    43	  #
    44	  # (The rewrite of this very comment was also a finding: the scanner matches the four-letter
    45	  # builtin anywhere in the file, comments included, so the earlier wording tripped it while the
    46	  # code beneath was already clean.)
    47	  # Read one name per line. A `for _ge_n in $_ge_names` loop would be a bug in any shell that does
    48	  # NOT word-split unquoted parameters — zsh does not, so it would pass the whole newline-joined blob
    49	  # as a single name and fail with `invalid parameter name` (observed 2026-08-07). A heredoc-fed
    50	  # `while read` behaves identically in bash and zsh, and unlike a pipe it keeps the loop in the
    51	  # CURRENT shell so the unsets survive.
    52	  _ge_names="$(python3 "$_ge_py" --list-scrubbed 2>/dev/null || true)"
    53	  if [ -n "$_ge_names" ]; then
    54	    while IFS= read -r _ge_n; do
    55	      [ -n "$_ge_n" ] || continue
    56	      case "$_ge_n" in
    57	        [A-Z_][A-Z_0-9]*) unset "$_ge_n" ;;
    58	        *) printf 'gate-env.sh: refusing to unset malformed name from the registry: %s\n' "$_ge_n" >&2 ;;
    59	      esac
    60	    done <<GATE_ENV_NAMES
    61	$_ge_names
    62	GATE_ENV_NAMES
    63	  else
    64	    # Fail LOUDLY rather than leaving the gate contaminated and looking clean. A gate that silently
    65	    # skips its own scrub is the exact shape GH-441 is about: a check reporting a verdict on a
    66	    # question it never asked.
    67	    printf 'gate-env.sh: could not read the scrub list from %s — refusing to run a gate with an ungoverned environment.\n' "$_ge_py" >&2
    68	    printf 'gate-env.sh: (this guard exists because a silently-unscrubbed gate reports its PARENT'\''s failures as the change'\''s own — see GH-441.)\n' >&2
    69	    return 1 2>/dev/null || exit 1
    70	  fi
    71	else
    72	  printf 'gate-env.sh: %s not found — refusing to run a gate with an ungoverned environment (GH-441).\n' "$_ge_py" >&2
    73	  return 1 2>/dev/null || exit 1
    74	fi
    75	
    76	unset _ge_src _ge_dir _ge_root _ge_py _ge_names _ge_n
     1	#!/usr/bin/env bash
     2	# driver-lock-lib.sh — GH-448: the ONE shared resolver for the relay-driver lock path.
     3	#
     4	# Mirrors the DRIVER's own write-side resolution (marathon_drive.py / marathon-drive.sh,
     5	# relay_drive.py / relay-drive.sh) byte-for-byte (utils/py/rtl.py's driver_lock_path is the Python
     6	# twin — the two MUST agree, asserted by test/gh448-driver-lock-resolver.sh). SOURCED by every
     7	# read-only consumer of the lock (marathon-ls.sh, utils/hq/marathon-live.sh,
     8	# skills/relay-xyz/find-harness.sh) — a consumer that constructs this path inline instead of calling
     9	# this function is the bug this file exists to kill (5 of 7 construction sites had drifted to a
    10	# 2-branch guess that misses the linked-worktree case, silently reporting a LIVE marathon as IDLE).
    11	#
    12	#   .git is a directory  -> <repo>/.git/relay-driver.lock              (normal clone)
    13	#   .git is a file       -> <git-common-dir>/relay-driver.lock         (linked worktree)
    14	#   no .git (vendored)   -> <repo>/.relay-driver.lock                  (vendored .xyz/ copy)
    15	#
    16	# API:
    17	#   driver_lock_path_for_repo <repo-root>   — prints the resolved lock path (no trailing newline)
    18	set -u
    19	
    20	driver_lock_path_for_repo() {
    21	  local repo="$1"
    22	  if [ -d "$repo/.git" ]; then
    23	    printf '%s/.git/relay-driver.lock' "$repo"
    24	    return 0
    25	  fi
    26	  if [ -f "$repo/.git" ]; then
    27	    local common
    28	    common="$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
    29	    if [ -n "$common" ]; then
    30	      printf '%s/relay-driver.lock' "$common"
    31	      return 0
    32	    fi
    33	  fi
    34	  printf '%s/.relay-driver.lock' "$repo"
    35	}

exec
/bin/zsh -lc "nl -ba test/_setup.sh | sed -n '1,300p'; for f in test/gh375-agy-auth-preflight.sh test/gh375-auth-timeout-verdict.sh test/gh385-retry-token-satisfied.sh test/gh390-gate-guard.sh test/gh390-timeout-attribution.sh test/gh407-gate-ran-attribution.sh test/gh419-gate-inventory.sh test/marathon-drive.sh; do echo \"=== "'$f"; nl -ba "$f" | sed -n '"'1,360p'; done" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-86418-h4t1yue0
 succeeded in 0ms:
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
   115	PASS=0
   116	FAIL=0
   117	pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
   118	# TEST_SOFT_FAIL=1 keeps going after a failed assertion so one run enumerates every
   119	# gap instead of stopping at the first. Default (unset/0) is fail-fast, unchanged.
   120	# Soft-fail output is a lead list, not a verdict: later assertions may cascade off
   121	# the state a failed one left behind. The file-level pass/fail stays authoritative.
   122	fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); [ "${TEST_SOFT_FAIL:-0}" = "1" ] || exit 1; }
   123	
   124	echo "== test: $TEST_NAME =="
   125	echo "  workdir: $WORK"
=== test/gh375-agy-auth-preflight.sh
     1	#!/usr/bin/env bash
     2	# test/gh375-agy-auth-preflight.sh — GH-375 regression.
     3	# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh375-agy-auth-preflight.sh; pre-fix revisions: (a) agy-turn.py/consult.py before acf2d3e, deciding on exit status alone with the captured output deleted — the reported TTY output read as successful auth; (b) the first fix, which made that TTY output FATAL — test/relay-self-sufficiency.sh went 4/0 to 0/4 with 'agy shim exited 5' on a machine where agy was signed in and working. Post-fix result: 17/0 with the TTY shape classified unverifiable rather than failed"}
     4	#
     5	# The agy auth pre-flight decided pass/fail on EXIT STATUS alone and deleted the captured output on
     6	# the success branch. `agy whoami` exits 0 while failing to run at all when there is no TTY:
     7	#
     8	#   $ agy whoami </dev/null; echo "exit=$?"
     9	#   CLI error: bubbletea: error opening TTY: ... open /dev/tty: device not configured
    10	#   exit=0
    11	#
    12	# and the probe passes stdin=DEVNULL, so that is the NORMAL path under automation — every marathon
    13	# and every driven relay turn. The guard that exists to stop a lane before it burns a turn on
    14	# expired credentials could not fail in the one context it exists for. The protection depended on a
    15	# hang that only happens when a TTY is present, so attended runs were protected and unattended ones
    16	# were not: exactly inverted from the intent.
    17	#
    18	# Both directions are asserted here. A probe that only ever says "fail" would satisfy the bug report
    19	# and break every real run, and that failure mode is live: the first fix for this matched a bare
    20	# "error" substring anywhere in the output, which fails any account whose handle, org, or banner
    21	# contains the word. A false failure stops the run outright — worse than the bug being fixed.
    22	source "$(dirname "$0")/_setup.sh" gh375-agy-auth-preflight
    23	PY="$(cd "$(dirname "$0")/.." && pwd)/utils/py"
    24	
    25	probe() {  # <fixture-text> → prints "<severity>|<message>"; severity is ""/unverifiable/failed
    26	  printf '%s' "$1" > "$WORK/agy-out.txt"
    27	  python3 -c "
    28	import sys
    29	sys.path.insert(0, '$PY')
    30	from rtl import agy_auth_output_verdict
    31	sev, msg = agy_auth_output_verdict('$WORK/agy-out.txt')
    32	print(f'{sev}|{msg}')
    33	"
    34	}
    35	sev() { printf '%s' "${1%%|*}"; }
    36	
    37	# --- the reported failure, verbatim from the issue ------------------------------------------------
    38	# It must be NOTICED (the original bug was that it read as success) but classified `unverifiable`,
    39	# NOT `failed`. See the block below for what the difference cost.
    40	r="$(probe 'CLI error: bubbletea: error opening TTY: bubbletea: could not open TTY: open /dev/tty: device not configured')"
    41	[ -n "$(sev "$r")" ] && pass "the headless TTY output is no longer read as successful auth" \
    42	  || fail "GH-375 is back: the exact reported output reads as successful auth"
    43	[ "$(sev "$r")" = "unverifiable" ] \
    44	  && pass "the TTY output is classified unverifiable, not failed" \
    45	  || fail "the TTY output is classified '$(sev "$r")' — a fatal verdict here blocks a WORKING agy lane"
    46	
    47	# --- WHY unverifiable AND NOT failed --------------------------------------------------------------
    48	# GH-375's suggested fix said to treat the TTY error as a failed probe and stop the turn. That was
    49	# implemented literally, and it broke the agy lane outright: test/relay-self-sufficiency.sh, which
    50	# drives a LIVE agy turn, went 4/0 to 0/4 with `agy shim exited 5` — on a machine where agy was
    51	# signed in and working. Two measurements settle it:
    52	#
    53	#   * `agy whoami` cannot run headless at all. Exit 0, `CLI error: ... could not open TTY`.
    54	#   * `agy -p` — the print mode the ACTUAL turn uses — runs headless perfectly well.
    55	#
    56	# So the TTY banner says nothing about auth; it says this probe is the wrong instrument here.
    57	# Treating it as failure converts an unmeasurable check into a hard block on a lane that
    58	# demonstrably works, which is strictly worse than the bug GH-375 reported: that one merely let a
    59	# possibly-unauthed lane proceed, this one stopped one of two working builders dead.
    60	#
    61	# What GH-375 established stands and is asserted above: exit status alone cannot decide this, and
    62	# the captured output must survive to be printed. The inference "the probe could not run, therefore
    63	# auth is bad" is the part that does not follow.
    64	r="$(probe 'CLI error: bubbletea: error opening TTY: bubbletea: could not open TTY: open /dev/tty: device not configured')"
    65	printf '%s' "$r" | grep -Fq "not verified" \
    66	  && pass "the unverifiable message says auth was not verified, rather than asserting it failed" \
    67	  || fail "the message overstates what the probe established: $r"
    68	
    69	# --- silence is deliberately NOT failure ----------------------------------------------------------
    70	# This pins a decision that was made the other way first and reverted on evidence. "A probe that
    71	# establishes nothing must not report success" reads well, but test/gh410-containment-advisory.sh's
    72	# agy stub prints nothing for `whoami`: under that rule the pre-flight rejected it, the turn exited 5
    73	# before running, and a containment assertion unrelated to auth went red. One rule, one real turn
    74	# killed, on first contact.
    75	#
    76	# The asymmetry is the whole argument. agy exiting 0 with a VISIBLE error is observed and documented
    77	# (GH-375). agy exiting 0 SILENTLY on success is not something this repo can rule out — and guessing
    78	# wrong there breaks every turn in the fleet rather than one. These two assertions exist so nobody
    79	# re-adds the stricter rule without first re-reading why it was removed.
    80	r="$(probe '')"
    81	[ -z "$(sev "$r")" ] && pass "empty output is NOT treated as failure (see the incident note in rtl.py)" \
    82	  || fail "empty output rejected — this kills any turn whose agy prints nothing: $r"
    83	
    84	r="$(probe '
    85	')"
    86	[ -z "$(sev "$r")" ] && pass "whitespace-only output is NOT treated as failure" \
    87	  || fail "whitespace-only output rejected ($r)"
    88	
    89	# --- other genuine error shapes ------------------------------------------------------------------
    90	# These are the shape the pre-flight EXISTS for, and they must stay `failed` — the fix above widened
    91	# one branch, it must not have softened this one into a warning that lets a dead lane run anyway.
    92	for bad in "Error: not logged in" "panic: runtime error: invalid memory address" "fatal: credentials expired"; do
    93	  r="$(probe "$bad")"
    94	  [ "$(sev "$r")" = "failed" ] && pass "rejected as failed: ${bad:0:32}" \
    95	    || fail "a genuine error line is classified '$(sev "$r")', not failed: $bad"
    96	done
    97	
    98	# --- THE OTHER DIRECTION: real auth output must NOT be rejected ----------------------------------
    99	# Each of these contains the letters "error" somewhere a naive substring test would trip on. They are
   100	# what a working `agy whoami` can legitimately print. Failing these is not a safe default — it makes
   101	# the pre-flight refuse every turn.
   102	while IFS= read -r good; do
   103	  [ -z "$good" ] && continue
   104	  r="$(probe "$good")"
   105	  [ -z "$(sev "$r")" ] && pass "accepted real auth output: ${good:0:44}" \
   106	    || fail "FALSE FAILURE — legitimate auth output rejected ($r): $good"
   107	done <<'GOOD'
   108	noel@neochro.me
   109	Logged in as: terror-form-labs
   110	account: acme-corp  org: error-budget-team
   111	user: mirror-ops
   112	plan: pro   errors_last_24h: 0
   113	GOOD
   114	
   115	# --- the shim wires it in ------------------------------------------------------------------------
   116	# The verdict living in rtl.py is only worth anything if the callers use it. Both had the same hole.
   117	grep -q 'agy_auth_output_verdict' "$PY/agy-turn.py" \
   118	  && pass "agy-turn.py consults the output verdict, not just the exit status" \
   119	  || fail "agy-turn.py still decides on exit status alone"
   120	grep -q 'agy_auth_output_verdict' "$PY/consult.py" \
   121	  && pass "consult.py consults the output verdict too (same hole, same fix)" \
   122	  || fail "consult.py still decides on exit status alone"
   123	
   124	# The captured output is the diagnosis; deleting it on the success branch is what hid this for so
   125	# long. Assert the failure path keeps it long enough to print.
   126	grep -q 'Run `agy login` in a normal terminal' "$PY/agy-turn.py" \
   127	  && pass "the remedy an operator needs is still printed" \
   128	  || fail "the 'agy login' remedy is missing from the failure path"
   129	
   130	# --- the callers must ACT on the three states, not just import the function -----------------------
   131	# The verdict is only worth anything if `unverifiable` actually lets the turn proceed. A caller that
   132	# imports the new function and then treats any non-empty severity as fatal reproduces the exact
   133	# regression this rework undoes, while passing every assertion above.
   134	grep -q 'unverifiable' "$PY/agy-turn.py" \
   135	  && pass "agy-turn.py branches on the unverifiable state (a working lane is not blocked)" \
   136	  || fail "agy-turn.py ignores the unverifiable state — any non-empty verdict still kills the turn"
   137	grep -q 'unverifiable' "$PY/consult.py" \
   138	  && pass "consult.py branches on it too (headless is the normal path there as well)" \
   139	  || fail "consult.py ignores the unverifiable state — the agy seat is disabled on every consult"
   140	
   141	exit 0
=== test/gh375-auth-timeout-verdict.sh
     1	#!/usr/bin/env bash
     2	# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh375-auth-timeout-verdict.sh. The pre-fix revision is replayed by patching COPIES of agy-turn.py and consult.py back to their old TimeoutExpired branches (unconditional fatal: rc=7 / return False, with no consultation of the captured output). Pre-fix result: a probe that timed out AFTER already printing agy's TTY diagnostic blocked the lane -- agy-turn exits 7 and consult drops the agy seat -- which is what cost a real /consult its agy advisor on 2026-08-09. Post-fix result: the same fixture proceeds, while a timeout with NO diagnostic and a timeout with an interactive-login prompt both still block. All observed in one run."}
     3	# GH-375 follow-up: the timeout branch was still a false block.
     4	#
     5	# GH-375's three-state fix covered `agy whoami` EXITING with a TTY error -> unverifiable -> proceed.
     6	# It never covered the probe blowing its timeout, which went straight to fatal. That is the branch
     7	# that actually fired: a /consult on 2026-08-09 lost its agy seat to
     8	#
     9	#   consult: agy auth pre-flight timed out after 5s; likely expired auth opening an interactive
    10	#            login. Run `agy login` in a normal terminal, then retry.
    11	#
    12	# measured in the same minute on the same machine:
    13	#
    14	#   $ agy whoami   -> CLI error: bubbletea: error opening TTY: ... /dev/tty: device not configured
    15	#   $ agy -p "..." -> answered correctly
    16	#
    17	# So the guard blocked a lane whose builder demonstrably worked -- the same failure DIRECTION GH-375's
    18	# own fix exists to avoid, one branch over. Margin, measured idle on that machine: 1.3s / 1.9s / 2.3s
    19	# against an AGY_AUTH_TIMEOUT_S default of 5. Under 2x, and concurrent load closed it.
    20	#
    21	# The rule pinned here: reclassify a timeout ONLY on positive evidence of the TTY cause.
    22	#   (1) timeout + TTY diagnostic already in the output -> unverifiable, lane proceeds
    23	#   (2) timeout + NO output                            -> still fatal   <- the real hang
    24	#   (3) timeout + an interactive login prompt          -> still fatal   <- the branch's own purpose
    25	#   (4) a probe that EXITS keeps its old verdict, unchanged  <- no regression to GH-375 proper
    26	#
    27	# (2) and (3) are the assertions that matter. "A timeout is unverifiable" is the tempting broader
    28	# rule and it is wrong: silence is exactly the shape a login prompt waiting on stdin produces, so the
    29	# broad rule would swallow the failure this branch was written to catch. Narrow beats tidy here.
    30	set -euo pipefail
    31	
    32	source "$(dirname "$0")/_setup.sh" gh375-auth-timeout-verdict
    33	ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
    34	export PYTHONPATH="$ROOT_REPO/utils/py${PYTHONPATH:+:$PYTHONPATH}"
    35	
    36	TTY_LINE='CLI error: bubbletea: error opening TTY: bubbletea: could not open TTY: open /dev/tty: device not configured'
    37	LOGIN_LINE='To authenticate, visit https://example.invalid/device and enter code ABCD-1234'
    38	
    39	# ── (1)-(4) the verdict function itself ───────────────────────────────────────────────────
    40	mkfix() { printf '%s\n' "$2" > "$WORK/$1"; printf '%s' "$WORK/$1"; }
    41	: > "$WORK/empty.txt"
    42	
    43	verdict() {  # <file> -> "<severity>|<detail>"
    44	  python3 -c 'import sys; from rtl import agy_auth_timeout_verdict as v; s,d = v(sys.argv[1]); print(f"{s}|{d}")' "$1"
    45	}
    46	
    47	got="$(verdict "$(mkfix tty.txt "$TTY_LINE")")"
    48	[ "${got%%|*}" = "unverifiable" ] \
    49	  && pass "timeout + the TTY diagnostic already printed -> unverifiable (the lane proceeds)" \
    50	  || fail "expected unverifiable for a TTY-diagnosed timeout, got '${got%%|*}'"
    51	
    52	got="$(verdict "$WORK/empty.txt")"
    53	[ "${got%%|*}" = "failed" ] \
    54	  && pass "timeout + NO output -> still fatal — silence is the shape of a hang, not evidence of a TTY problem" \
    55	  || fail "a silent timeout must stay fatal, got '${got%%|*}'"
    56	
    57	got="$(verdict "$(mkfix login.txt "$LOGIN_LINE")")"
    58	[ "${got%%|*}" = "failed" ] \
    59	  && pass "timeout + an interactive login prompt -> still fatal — the branch keeps its original purpose" \
    60	  || fail "an interactive-login hang must stay fatal, got '${got%%|*}'"
    61	
    62	got="$(verdict "$WORK/does-not-exist-$$.txt")"
    63	[ "${got%%|*}" = "failed" ] \
    64	  && pass "timeout + unreadable capture -> fatal, not silently green" \
    65	  || fail "a missing capture must not read as success, got '${got%%|*}'"
    66	
    67	# The two functions must not be collapsed into one. agy_auth_output_verdict treats "nothing
    68	# suspicious" as PASS, which is right for a process that exited and catastrophic for one that hung.
    69	got="$(python3 -c 'import sys; from rtl import agy_auth_output_verdict as v; s,d=v(sys.argv[1]); print(s or "PASS")' "$WORK/empty.txt")"
    70	[ "$got" = "PASS" ] \
    71	  && pass "the EXIT-path verdict still passes on empty output (GH-375 proper, unchanged) — which is exactly why the timeout path needs its own function" \
    72	  || fail "agy_auth_output_verdict changed behaviour on empty output — GH-375's own false-failure lesson regressed"
    73	
    74	# ── the pre-fix replay: the old unconditional-fatal timeout branch ────────────────────────
    75	# Patched into COPIES so the working tree is never mutated. Both callers had the same shape, so both
    76	# are replayed; a fix in one and not the other is the drift this issue already paid for once.
    77	FIXH="$WORK/prefix"
    78	mkdir -p "$FIXH"
    79	cp -R "$ROOT_REPO/utils" "$FIXH/utils"
    80	# Literal block replacement, restoring each caller's pre-fix source byte-for-byte. NOT index-slicing
    81	# between two anchors: an 8-space-indented anchor also matches INSIDE a 12-space block (the deeper
    82	# line contains the shallower one as a substring), which silently cut consult.py mid-block and left it
    83	# with an IndentationError. A control that fails to compile still "reproduces a block", so that class
    84	# of bug is invisible unless the replay is asserted to be valid Python. Both are compile-checked below.
    85	python3 - "$FIXH/utils/py/agy-turn.py" "$FIXH/utils/py/consult.py" <<'PY'
    86	import pathlib, sys
    87	
    88	# GH-492 demoted the unverifiable branch's WARNING to a NOTE and started recording the detail for
    89	# the failure path, so this anchor moved with it. The anchor is what keeps the replay honest — if it
    90	# stops matching, the control below would patch nothing and still report green — so it is updated in
    91	# lockstep rather than loosened into a regex. What is being replayed is UNCHANGED: the pre-fix source
    92	# had no `unverifiable` branch at all and treated every timeout as fatal.
    93	AGY_NEW = '''        t_severity, t_detail = agy_auth_timeout_verdict(out_file)
    94	        if t_severity == "unverifiable":
    95	            _record_auth_unverified(t_detail)
    96	            print(f"agy-turn: NOTE — agy auth is unverifiable headless (expected, via timeout); proceeding. {_AUTH_PROBE_FINDING}",
    97	                  file=sys.stderr)
    98	            print("agy-turn: continuing; `agy whoami` cannot run headless, so it is not a usable auth "
    99	                  "check here. If the turn fails on credentials, run `agy login` in a normal terminal.",
   100	                  file=sys.stderr)
   101	            if os.path.exists(out_file): os.remove(out_file)
   102	            return True
   103	        print(f"agy-turn: agy auth pre-flight timed out after {secs}s; {t_detail}. Run `agy login` in a normal terminal, then retry.", file=sys.stderr)
   104	'''
   105	AGY_OLD = '''        print(f"agy-turn: agy auth pre-flight timed out after {secs}s; likely expired auth opening an interactive login. Run `agy login` in a normal terminal, then retry.", file=sys.stderr)
   106	'''
   107	
   108	CONSULT_NEW = '''        t_severity, t_detail = agy_auth_timeout_verdict(tmp)
   109	        if t_severity == "unverifiable":
   110	            with open(log_file, "a") as f:
   111	                if os.path.exists(tmp):
   112	                    with open(tmp) as tf: f.write(tf.read())
   113	                f.write(f"\\nconsult: WARNING — {t_detail}. Proceeding; if agy fails on credentials, "
   114	                        f"run `agy login` in a normal terminal.\\n")
   115	            if os.path.exists(tmp): os.remove(tmp)
   116	            return True
   117	        with open(log_file, "a") as f:
   118	            if os.path.exists(tmp):
   119	                with open(tmp) as tf: f.write(tf.read())
   120	            f.write(f"\\nconsult: agy auth pre-flight timed out after {secs}s; {t_detail}. Run `agy login` in a normal terminal, then retry.\\n")
   121	'''
   122	CONSULT_OLD = '''        with open(log_file, "a") as f:
   123	            if os.path.exists(tmp):
   124	                with open(tmp) as tf: f.write(tf.read())
   125	            f.write(f"\\nconsult: agy auth pre-flight timed out after {secs}s; likely expired auth opening an interactive login. Run `agy login` in a normal terminal, then retry.\\n")
   126	'''
   127	
   128	for path, new, old, name in ((sys.argv[1], AGY_NEW, AGY_OLD, "agy-turn.py"),
   129	                             (sys.argv[2], CONSULT_NEW, CONSULT_OLD, "consult.py")):
   130	    p = pathlib.Path(path); s = p.read_text()
   131	    assert new in s, f"{name}: post-fix timeout block not found — the replay would be vacuous"
   132	    p.write_text(s.replace(new, old, 1))
   133	print("PATCHED")
   134	PY
   135	for f in agy-turn consult; do
   136	  python3 -m py_compile "$FIXH/utils/py/$f.py" 2>/dev/null \
   137	    && pass "control: the pre-fix $f.py replay is valid Python (a control that cannot compile proves nothing)" \
   138	    || fail "control: the pre-fix $f.py replay does not compile — the replacement cut a block"
   139	done
   140	
   141	# Drive each caller's pre-flight directly with a stub `agy` that prints the TTY line and then hangs
   142	# past the timeout — the exact live shape.
   143	STUB="$WORK/agy-hang"
   144	cat > "$STUB" << STUB_EOF
   145	#!/usr/bin/env bash
   146	printf '%s\n' '$TTY_LINE'
   147	sleep 30
   148	STUB_EOF
   149	chmod +x "$STUB"
   150	
   151	run_preflight() {  # <utils-py-dir> <caller> -> prints "True"/"False"
   152	  local pydir="$1" caller="$2"
   153	  if [ "$caller" = agy ]; then
   154	    PYTHONPATH="$pydir" AGY_AUTH_TIMEOUT_S=2 python3 -c '
   155	import importlib.util, sys, os
   156	spec = importlib.util.spec_from_file_location("agyturn", os.path.join(sys.argv[1], "agy-turn.py"))
   157	m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
   158	print(m.agy_auth_preflight(sys.argv[2]))' "$pydir" "$STUB" 2>/dev/null
   159	  else
   160	    PYTHONPATH="$pydir" AGY_AUTH_TIMEOUT_S=2 python3 -c '
   161	import importlib.util, sys, os
   162	spec = importlib.util.spec_from_file_location("consultmod", os.path.join(sys.argv[1], "consult.py"))
   163	m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
   164	print(m.agy_auth_preflight(sys.argv[2], sys.argv[3]))' "$pydir" "$STUB" "$WORK/consult-pf.log" 2>/dev/null
   165	  fi
   166	}
   167	
   168	for caller in agy consult; do
   169	  # `|| true` so a crashing pre-flight is reported by the assertion below rather than aborting the
   170	  # file under `set -e` with no message at all — which is how the consult IndentationError above hid.
   171	  pre="$(run_preflight "$FIXH/utils/py" "$caller" || true)"
   172	  [ "$pre" = "False" ] \
   173	    && pass "control: pre-fix $caller pre-flight BLOCKS a TTY-diagnosed timeout (the defect, observed)" \
   174	    || fail "control: pre-fix $caller did not reproduce the block (got '$pre') — the assertions above prove nothing"
   175	  post="$(run_preflight "$ROOT_REPO/utils/py" "$caller" || true)"
   176	  [ "$post" = "True" ] \
   177	    && pass "post-fix $caller pre-flight proceeds on the same fixture" \
   178	    || fail "post-fix $caller still blocks a TTY-diagnosed timeout (got '$post')"
   179	done
   180	
   181	# ── the probe budget must clear the probe's own measured cost, with room for load ───────────
   182	# The flush race is what a too-tight budget looks like from the inside: the probe is killed before it
   183	# can write the diagnostic the reclassification above needs, so a TTY failure degrades into a silent
   184	# one and blocks the lane. Fixing the branch without fixing the margin left that live, and it fired.
   185	#
   186	# Asserted against the MEASURED worst probe cost rather than a number that looks tidy — the #457 rule,
   187	# reused. If `agy whoami` gets slower, or someone trims the default, this fails and says which.
   188	budget="$(python3 -c 'import rtl; print(rtl.AGY_AUTH_TIMEOUT_DEFAULT_S)')"
   189	worst="$(python3 -c 'import rtl; print(rtl.WORST_OBSERVED_WHOAMI_S)')"
   190	ratio="$(python3 -c "print(f'{$budget/$worst:.1f}')")"
   191	python3 -c "import sys; sys.exit(0 if $budget >= 4*$worst else 1)" \
   192	  && pass "the auth-probe budget (${budget}s) clears 4x the worst measured probe cost (${worst}s) — ${ratio}x headroom, where 5s gave under 2x and lost the lane twice" \
   193	  || fail "the auth-probe budget (${budget}s) is under 4x the worst measured cost (${worst}s) — this is the margin whose closure produced the flush race"
   194	
   195	# Both callers must read the shared default; a second hardcoded 5 would reintroduce the drift silently.
   196	for f in utils/py/agy-turn.py utils/py/consult.py; do
   197	  if grep -q 'AGY_AUTH_TIMEOUT_S", 5)' "$ROOT_REPO/$f"; then
   198	    fail "$f still hardcodes a 5s probe budget instead of the shared AGY_AUTH_TIMEOUT_DEFAULT_S"
   199	  else
   200	    pass "$(basename "$f") reads the shared AGY_AUTH_TIMEOUT_DEFAULT_S, so the two callers cannot drift"
   201	  fi
   202	done
   203	
   204	echo "gh375-auth-timeout-verdict: $PASS pass, $FAIL fail"
=== test/gh385-retry-token-satisfied.sh
     1	#!/usr/bin/env bash
     2	# test/gh385-retry-token-satisfied.sh — GH-385 regression.
     3	# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh385-retry-token-satisfied.sh; pre-fix revisions: (a) marathon_drive.py before acf2d3e, where satisfied_lane_terminal read only the BASE token — case 1 FAILED, an Approved phase completed on a --retry suffix was rebuilt; (b) the first version of that fix, which trusted the builder-written task= directive unconditionally — cases 5,6,7,9 FAILED, a directive naming any unrelated done token satisfied the lane. Post-fix result: 12/0, with case 8 (multi-digit suffix) green in all three revisions as the anti-over-tightening control"}
     4	#
     5	# An Approved phase rebuilt from scratch because its completion was recorded on a --retry SUFFIXED
     6	# token while satisfied_lane_terminal() read only the BASE token:
     7	#
     8	#   1. p1 runs, the builder fails, the phase escalates — MARATHON-P1-TURN is left claimed.
     9	#   2. Operator re-runs with --retry. GH-116 allocates MARATHON-P1-TURN-2, the phase succeeds,
    10	#      -TURN-2 reaches done and RELAY.md records STATUS: Approved.
    11	#   3. A later run without --retry computes the BASE name again, reads the dead attempt's state,
    12	#      and rebuilds a phase that is demonstrably Approved.
    13	#
    14	# Observed on a real 10-phase run: phase 1 rebuilt while phases 2-4 correctly reported satisfied, and
    15	# the only difference was that phase 1 had once been retried. Cost is a full builder + reviewer cycle
    16	# — real money on --builder claude — and the rebuild re-introduced a defect that had been reverted,
    17	# so a phase believed complete silently regressed the tree. Nothing in the log said why.
    18	#
    19	# The driver now reads which task the relay was actually rendered for, from its own marathon-drive
    20	# directive, instead of assuming the base name.
    21	source "$(dirname "$0")/_setup.sh" gh385-retry-token-satisfied
    22	DRIVER="$(cd "$(dirname "$0")/.." && pwd)/utils/py/marathon_drive.py"
    23	export TICK_BIN="$TICK"
    24	tick_a init >/dev/null
    25	
    26	printf '.tick/\n' > "$A/.gitignore"
    27	git -C "$A" add .gitignore >/dev/null 2>&1
    28	git -C "$A" commit -q -m init
    29	BRIEF="$WORK/brief.md"; printf '## brief\nbody\n' > "$BRIEF"
    30	
    31	STUB_CLAUDE="$WORK/stub-claude"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_CLAUDE"; chmod +x "$STUB_CLAUDE"
    32	STUB_AGY="$WORK/stub-agy"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_AGY"; chmod +x "$STUB_AGY"
    33	
    34	# A relay-drive stub that RECORDS being called. The whole point of the satisfied path is that the
    35	# phase is not driven again, so "was the driver re-entered" is the observable that matters.
    36	RD="$WORK/relay-drive-stub.sh"
    37	cat > "$RD" <<'STUB'
    38	#!/usr/bin/env bash
    39	echo called >> "$RD_CALLS"
    40	exit 0
    41	STUB
    42	chmod +x "$RD"
    43	export RD_CALLS="$WORK/rd-calls"
    44	
    45	BASE="MARATHON-P1-TURN"
    46	
    47	seed_relay() {  # <recorded-task> — an Approved relay rendered for <recorded-task>
    48	  mkdir -p "$A/phases/p1"
    49	  printf '# Marathon Phase p1\nSTATUS: Approved\nNEXT: agy (Reviewer)\n\n<!-- marathon-drive: task=%s builder=claude reviewer=agy round-cap=5 -->\n\nbody\n' \
    50	    "$1" > "$A/phases/p1/RELAY.md"
    51	}
    52	
    53	mk_token() {  # <task> <done|claimed>
    54	  tick_a log task.created "$1" --agent marathon >/dev/null 2>&1 || true
    55	  tick_a claim "$1" --agent claude --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
    56	  [ "$2" = "done" ] && { tick_a done "$1" --agent claude >/dev/null 2>&1 || true; }
    57	}
    58	
    59	run_driver() {  # [extra marathon-drive args...]
    60	  : > "$RD_CALLS"
    61	  MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
    62	  CLAUDE_BIN="$STUB_CLAUDE" AGY_BIN="$STUB_AGY" \
    63	  python3 "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
    64	    --reviewer agy --builder claude --pre-advance-cmd "true" "$@" 2>&1
    65	}
    66	
    67	reset_state() { rm -rf "$A/phases" "$A/.tick"; tick_a init >/dev/null 2>&1 || true; : > "$RD_CALLS"; }
    68	
    69	# --- (1) THE BUG: completion recorded on -TURN-2, base token left on the failed attempt ----------
    70	reset_state
    71	seed_relay "${BASE}-2"
    72	mk_token "$BASE" claimed      # the dead attempt, exactly as a crashed run leaves it
    73	mk_token "${BASE}-2" done     # where the phase actually completed
    74	out="$(run_driver)"; rc=$?
    75	printf '%s' "$out" | grep -q "already reached a terminal relay" \
    76	  && pass "a phase completed on a --retry token is recognized as satisfied" \
    77	  || fail "GH-385 is back: the Approved phase rebuilt because the BASE token was read: $out"
    78	[ ! -s "$RD_CALLS" ] \
    79	  && pass "relay-drive was NOT re-entered (no builder + reviewer cycle re-run)" \
    80	  || fail "the phase was driven again despite being Approved — the cost this issue is about"
    81	[ "$rc" -eq 0 ] && pass "satisfied phase exits 0" || fail "satisfied phase exit=$rc: $out"
    82	
    83	# --- (2) NEGATIVE CONTROL: nothing reached done, so the phase MUST still run ----------------------
    84	# Without this, an implementation that always reported "satisfied" would pass case (1) and silently
    85	# skip every phase in the fleet. The assertion above is only meaningful next to this one.
    86	reset_state
    87	seed_relay "${BASE}-2"
    88	mk_token "$BASE" claimed
    89	mk_token "${BASE}-2" claimed  # recorded task exists but never completed
    90	out="$(run_driver)"
    91	printf '%s' "$out" | grep -q "already reached a terminal relay" \
    92	  && fail "a phase whose recorded token never reached done was skipped — satisfied is now unfalsifiable" \
    93	  || pass "an un-completed recorded token does NOT satisfy the lane (the check can still fail)"
    94	
    95	# --- (3) the ordinary no-retry path is unchanged --------------------------------------------------
    96	reset_state
    97	seed_relay "$BASE"
    98	mk_token "$BASE" done
    99	out="$(run_driver)"
   100	printf '%s' "$out" | grep -q "already reached a terminal relay" \
   101	  && pass "the plain base-token satisfied path still works" \
   102	  || fail "regressed the ordinary satisfied path: $out"
   103	
   104	# --- (4) a relay with no directive falls back to the base token ------------------------------------
   105	# Relays rendered before the directive existed must keep working rather than being read as unsatisfied.
   106	reset_state
   107	mkdir -p "$A/phases/p1"
   108	printf '# Marathon Phase p1\nSTATUS: Approved\nNEXT: agy\n\nbody\n' > "$A/phases/p1/RELAY.md"
   109	mk_token "$BASE" done
   110	out="$(run_driver)"
   111	printf '%s' "$out" | grep -q "already reached a terminal relay" \
   112	  && pass "a directive-less relay still resolves against the base token" \
   113	  || fail "a pre-directive relay stopped being recognized as satisfied: $out"
   114	
   115	# ==================================================================================================
   116	# THE DIRECTIVE IS THE BUILDER'S TO WRITE. Everything below pins that RELAY.md is a hint, not an
   117	# authority. Raised in review of #458 before it merged: the first version of this fix accepted any
   118	# `task=` value, and the builder writes both that line AND `STATUS: Approved` — so the two together
   119	# are a complete forgery of the terminal state. Point the directive at any unrelated already-done
   120	# token and the driver skips render/reseed and reports success after the gate, which is a WIDER hole
   121	# than the one being closed (the pre-GH-385 check read a harness-computed name the builder cannot
   122	# touch). The resolution must never be able to leave this lane's own token family.
   123	# ==================================================================================================
   124	
   125	# --- (5) FORGERY: Approved + a directive naming an unrelated done token must NOT satisfy -----------
   126	reset_state
   127	seed_relay "MARATHON-P0-TURN"    # a different lane's token, or any stale/invented name
   128	mk_token "$BASE" claimed         # this lane never completed
   129	mk_token "MARATHON-P0-TURN" done # ...but the named token is legitimately done
   130	out="$(run_driver)"
   131	printf '%s' "$out" | grep -q "already reached a terminal relay" \
   132	  && fail "a builder-written directive naming an unrelated done token satisfied the lane — a builder can now skip its own review: $out" \
   133	  || pass "an out-of-family directive does NOT satisfy the lane"
   134	# ...and it must not report the phase COMPLETE either. Not asserted via RD_CALLS: this fixture leaves
   135	# the base token live-claimed (exactly how a crashed attempt leaves it), so the driver correctly dies
   136	# at reconcile_relay_task before relay-drive is reached. "Did the builder run" is therefore the wrong
   137	# observable here; "did the harness announce success having changed nothing" is the one the issue is
   138	# about, and it is what the pre-fix code did — it exited 0 with the success line.
   139	printf '%s' "$out" | grep -q "complete — " \
   140	  && fail "the harness reported the phase COMPLETE off a forged directive: $out" \
   141	  || pass "the phase is not reported complete — the lane halts honestly instead"
   142	
   143	# --- (6) the refusal is VISIBLE ---------------------------------------------------------------------
   144	# A silent fallback is indistinguishable from a directive that was honored, and this repo has shipped
   145	# three checks that could not fail (#333, #348, #351). A lane that rebuilds because its directive was
   146	# refused has to say so, or nobody can tell the guard from a bug.
   147	printf '%s' "$out" | grep -q "not $BASE or a retry derivative" \
   148	  && pass "the ignored directive is named in the log" \
   149	  || fail "the directive was refused silently: $out"
   150	
   151	# --- (7) PREFIX-MATCH CONTROL: family membership is not a startswith ---------------------------------
   152	# `MARATHON-P1-TURN-EVIL` and `MARATHON-P1-TURNX` both begin with the base name. A membership test
   153	# written as a prefix check accepts them and the forgery in (5) comes straight back through a name
   154	# chosen to look related.
   155	reset_state
   156	seed_relay "${BASE}X"
   157	mk_token "$BASE" claimed
   158	mk_token "${BASE}X" done
   159	out="$(run_driver)"
   160	printf '%s' "$out" | grep -q "already reached a terminal relay" \
   161	  && fail "'${BASE}X' was accepted as family — the check is a prefix match, not a suffix rule: $out" \
   162	  || pass "a name that merely starts with the base token is not a retry derivative"
   163	
   164	# --- (8) POSITIVE CONTROL for the suffix rule: multi-digit retries are still family -----------------
   165	# Without this, a rule of `-\d` (or an over-tight one) would pass every assertion above while
   166	# quietly re-breaking GH-385 for any lane retried more than nine times.
   167	reset_state
   168	seed_relay "${BASE}-11"
   169	mk_token "$BASE" claimed
   170	mk_token "${BASE}-11" done
   171	out="$(run_driver)"
   172	printf '%s' "$out" | grep -q "already reached a terminal relay" \
   173	  && pass "a two-digit retry suffix is still recognized as this lane's token" \
   174	  || fail "the family rule is too tight — GH-385 is back for lanes retried 10+ times: $out"
   175	
   176	# --- (9) an explicit --relay-task pins the token; the directive is not consulted --------------------
   177	# This is the --retry path (GH-116 allocates the first unused suffix and passes it through). A retry
   178	# must never be satisfied by the attempt it was invoked to retry, or --retry silently becomes a
   179	# gate-only re-run and the operator's explicit request is discarded.
   180	reset_state
   181	seed_relay "${BASE}-2"
   182	mk_token "${BASE}-2" done        # the previous attempt genuinely completed
   183	out="$(run_driver --relay-task "${BASE}-3")"
   184	printf '%s' "$out" | grep -q "already reached a terminal relay" \
   185	  && fail "--retry was satisfied by the attempt it was retrying — the operator's fresh token was ignored: $out" \
   186	  || pass "an explicit --relay-task overrides the directive (--retry still forces a real re-run)"
   187	
   188	# --- (10) GH-385's OTHER ask: the disagreement is logged before the rebuild ------------------------
   189	# The issue asked for this by name — "Log the disagreement ... that single line would have made this
   190	# diagnosable immediately" — because the failure mode is invisible: a phase that is demonstrably
   191	# Approved silently re-runs a full builder + reviewer cycle and the log reads like an ordinary first
   192	# fire. The fix above stops the common cause, but a terminal relay whose token genuinely is not done
   193	# is still reachable (a token reaped after a host crash, a record on a token this run cannot see),
   194	# and in that case the operator gets a rebuild with no explanation unless this line exists.
   195	#
   196	# Asserted, not merely written: an unasserted log line is precisely the "check nobody can see
   197	# working" shape this repo has shipped three times (#333, #348, #351).
   198	reset_state
   199	seed_relay "$BASE"            # directive names the BASE token — no retry involved
   200	mk_token "$BASE" claimed      # terminal relay, but the token is NOT done: the contradiction
   201	out="$(run_driver)"
   202	printf '%s' "$out" | grep -q "already reached a terminal relay" \
   203	  && fail "a not-done token must NOT satisfy the lane: $out" \
   204	  || pass "a terminal relay with a not-done token still rebuilds (unchanged)"
   205	printf '%s' "$out" | grep -q "relay is terminal .* but token .* not done — rebuilding" \
   206	  && pass "GH-385: the token/relay disagreement is logged before the rebuild" \
   207	  || fail "the rebuild is still silent — GH-385's 'log the disagreement' ask is unmet: $out"
   208	printf '%s' "$out" | grep -q "GH-385" \
   209	  && pass "the disagreement line points at GH-385 so the next reader can find the mechanism" \
   210	  || fail "disagreement line does not cite GH-385: $out"
   211	
   212	# --- (11) GH-491: --retry on an ALREADY-SATISFIED lane says the cheap path existed ------------------
   213	# Case (9) above establishes that --retry correctly refuses to be satisfied by the attempt it retries.
   214	# The cost of that correctness is that the cheap path becomes invisible exactly when it applies: the
   215	# `already reached a terminal relay` line prints only once the operator has already chosen the right
   216	# invocation, so choosing wrong yields a rebuild and the reasonable conclusion that one was required.
   217	#
   218	# Measured, not hypothetical: three codex builds and three agy reviews across two Nightwatch waves on
   219	# 2026-08-10, both of whose base tokens read `done` afterwards. Every one of those turns was avoidable.
   220	reset_state
   221	seed_relay "$BASE"
   222	mk_token "$BASE" done            # terminal AND done: a plain re-fire would have been gate-only
   223	out="$(run_driver --relay-task "${BASE}-2")"
   224	printf '%s' "$out" | grep -q "already reached a terminal relay" \
   225	  && fail "advisory case regressed into an actual short-circuit — --retry must still rebuild: $out" \
   226	  || pass "GH-491 advisory does not change --retry's behaviour (it still rebuilds)"
   227	printf '%s' "$out" | grep -q "re-firing WITHOUT --retry would have re-run only the pre-advance gate" \
   228	  && pass "GH-491: --retry on a satisfied lane says a plain re-fire would have skipped both turns" \
   229	  || fail "no advisory — the cheaper path stays invisible at the one moment it applies: $out"
   230	printf '%s' "$out" | grep -q "GH-491" \
   231	  && pass "the advisory cites GH-491 so the next reader can find the mechanism" \
   232	  || fail "advisory does not cite GH-491: $out"
   233	
   234	# --- (12) NEGATIVE CONTROL for (11): the advisory must NOT fire when it does not apply --------------
   235	# Without this, (11) is indistinguishable from a line that prints on every --retry — which would be
   236	# worse than silence, because an operator would learn to ignore it exactly like #492's TTY warning.
   237	# Same --retry invocation; the ONLY variable is whether the recorded token actually completed.
   238	reset_state
   239	seed_relay "$BASE"
   240	mk_token "$BASE" claimed         # terminal relay, token NOT done: a plain re-fire would ALSO rebuild
   241	out="$(run_driver --relay-task "${BASE}-2")"
   242	printf '%s' "$out" | grep -q "re-firing WITHOUT --retry would have re-run only the pre-advance gate" \
   243	  && fail "control: the advisory fired on a lane a plain re-fire would ALSO have rebuilt — it is unconditional, so it carries no information: $out" \
   244	  || pass "control: no advisory when the recorded token is not done (the cheap path genuinely did not apply)"
   245	
   246	exit 0
=== test/gh390-gate-guard.sh
     1	#!/usr/bin/env bash
     2	# gate-evidence: {"form":"deliberate-mutation","observed":true,"result":"all four CPU signal/Bash exit shapes map to gate-killed; an inverted classifier is observed to misattribute each as a red gate"}
     3	# GH-390 Phase 1: the pre-advance gate must not be able to take the host down.
     4	#
     5	# The gate executes code an LLM wrote seconds earlier, and the packet forbids the builder from
     6	# running it first — so the gate is by construction the first execution of the builder's work.
     7	# With no timeout and no resource bounds, a generated test that mocked a paging function against a
     8	# `while True:` loop consumed all 30.75 GB of swap and kernel-panicked the host twice on one day
     9	# (GH-382). This pins the guard that turns that into a failed phase.
    10	#
    11	# Properties pinned here:
    12	#   (1) an honest gate is unaffected — same exit code, and peak-RSS telemetry is recorded
    13	#   (2) a runaway ALLOCATOR is killed at the RSS cap (layer 3) and escalates as `gate-killed`
    14	#   (3) a HANG is killed at the wall-clock cap (layer 1)
    15	#   (4) a CPU SPIN is killed by the kernel-enforced ulimit -t (layer 2), and its 128+SIGXCPU
    16	#       exit is reported as a guard kill rather than as the gate finding a defect
    17	#   (5) a gate that genuinely FAILS still escalates `pre-advance-failed` — the guard must not
    18	#       relabel real red gates
    19	#   (6) MARATHON_GATE_GUARD=0 restores the exact unguarded behavior (the ship-day escape hatch)
    20	#
    21	# Every runaway fixture below is SELF-LIMITING: if the guard fails to kill it, the fixture exits
    22	# on its own well short of any level that could affect the host, and the case fails loudly. This
    23	# test must never be able to reproduce the panic it exists to prevent.
    24	source "$(dirname "$0")/_setup.sh" gh390-gate-guard
    25	export TICK_BIN="$TICK"
    26	ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
    27	DRIVER="$ROOT_REPO/relay-automation/marathon-drive.sh"
    28	
    29	# ── fixture: a marathon root whose gate we swap per case ─────────────────────────────────
    30	ROOT="$WORK/target"
    31	mkdir -p "$ROOT"
    32	git init -q "$ROOT"
    33	git -C "$ROOT" config user.email gh390@t
    34	git -C "$ROOT" config user.name gh390
    35	printf '.tick/\n' > "$ROOT/.gitignore"
    36	printf '#!/usr/bin/env bash\nexit 0\n' > "$ROOT/validate.sh"
    37	git -C "$ROOT" add .gitignore validate.sh >/dev/null 2>&1
    38	git -C "$ROOT" commit -q -m init
    39	
    40	# Stub relay-drive: marks the thread Approved so the driver proceeds straight to the gate,
    41	# which is the only thing under test.
    42	STUB_RD="$WORK/relay-drive.sh"
    43	cat > "$STUB_RD" << 'STUB_EOF'
    44	#!/usr/bin/env bash
    45	set -u
    46	rf=""
    47	while (($#)); do case "$1" in --relay-file) rf="${2:-}"; shift 2 ;; *) shift ;; esac; done
    48	[ -n "$rf" ] && printf 'STATUS: Approved\n' >> "$rf"
    49	exit 0
    50	STUB_EOF
    51	chmod +x "$STUB_RD"
    52	STUB_BIN="$WORK/stub-bin"
    53	printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_BIN"
    54	chmod +x "$STUB_BIN"
    55	BRIEF="$WORK/brief.md"
    56	printf '## Do a thing\nBody.\n' > "$BRIEF"
    57	
    58	# Self-limiting allocator: ~10 MB/50 ms, hard stop at 1 GB. Reaching the stop means the guard
    59	# never fired; the fixture exits 0 so the case can report a clean, unambiguous failure.
    60	HOG="$WORK/hog.py"
    61	cat > "$HOG" << 'HOG_EOF'
    62	import time
    63	blocks = []
    64	for _ in range(100):            # hard ceiling: 100 x 10 MB = 1 GB, then exit cleanly
    65	    blocks.append(bytearray(10 * 1024 * 1024))
    66	    time.sleep(0.05)
    67	HOG_EOF
    68	
    69	# GH-382 reproducer baseline (observed by case p7 below): a MagicMock records every invocation,
    70	# so this exact `while True` shape grows without bound.  Pre-fix (the deliberately inverted
    71	# classifier in case 0): resource exits are `pre-advance-failed`; post-fix: the guard terminates
    72	# the process group and records `gate-killed` (exit 108).  The harness's file-scoped commit is the
    73	# revision carrying this baseline; keeping it beside the reproducer prevents a detached result log.
    74	MOCK_HOG="$WORK/gh382-magicmock-while-true.py"
    75	cat > "$MOCK_HOG" << 'MOCK_HOG_EOF'
    76	from unittest.mock import MagicMock
    77	
    78	page = MagicMock()
    79	calls = 0
    80	while True:
    81	    page()
    82	    calls += 1
    83	    if calls >= 500_000:
    84	        raise SystemExit("fixture safety ceiling reached before the guard fired")
    85	MOCK_HOG_EOF
    86	
    87	# Each case passes its OWN --phase-id: a lane whose token is already spent takes the
    88	# "already terminal, re-run only the gate" path instead of the one under test. Note the ids are
    89	# passed explicitly rather than from a counter — every call site here is inside "$( … )", which
    90	# runs in a subshell, so a counter incremented in the function would never reach the next case.
    91	run_driver() {  # <extra-args…>
    92	  MARATHON_ROOT="$ROOT" \
    93	  MARATHON_RELAY_DRIVE="$STUB_RD" \
    94	  MARATHON_AGENT_CMD="$WORK/noop-agent" \
    95	  TICK_REPO_ROOT="$ROOT" TICK_BIN="$TICK" \
    96	  CLAUDE_BIN="$STUB_BIN" AGY_BIN="$STUB_BIN" CODEX_BIN="$STUB_BIN" \
    97	  bash "$DRIVER" \
    98	    --phases-dir "$ROOT/phases" \
    99	    --phase-brief "$BRIEF" \
   100	    --reviewer agy \
   101	    --builder claude \
   102	    "$@"
   103	}
   104	
   105	esc_reason() {  # <phase-id> — the reason recorded in that phase's ESCALATION.md
   106	  sed -n 's/^reason: //p' "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null
   107	}
   108	
   109	# ── (0) the attribution seam: both signals and both Bash return-code shapes ──────────────
   110	# This is deliberately a direct import rather than a driven phase: a host can only cause one of
   111	# these kernel outcomes, whereas the seam makes all four observed controls reproducible anywhere.
   112	out="$(python3 - "$ROOT_REPO/utils/py/marathon_drive.py" <<'PY'
   113	import importlib.util
   114	import signal
   115	import sys
   116	
   117	spec = importlib.util.spec_from_file_location("marathon_drive", sys.argv[1])
   118	driver = importlib.util.module_from_spec(spec)
   119	spec.loader.exec_module(driver)
   120	
   121	cases = {
   122	    "SIGXCPU forked (128+signal)": 128 + signal.SIGXCPU,
   123	    "SIGXCPU exec-optimised (-signal)": -signal.SIGXCPU,
   124	    "SIGKILL forked (128+signal)": 128 + signal.SIGKILL,
   125	    "SIGKILL exec-optimised (-signal)": -signal.SIGKILL,
   126	}
   127	
   128	def must_classify_as_guard_kill(classifier, label, returncode):
   129	    actual, message = classifier(returncode, 2)
   130	    assert actual == driver.GATE_GUARD_KILL_EXIT, (label, actual, message)
   131	    return message
   132	
   133	for label, returncode in cases.items():
   134	    message = must_classify_as_guard_kill(driver.gate_guard_cpu_attribution, label, returncode)
   135	    assert message and ("SIGXCPU" in message or "SIGKILL" in message), (label, message)
   136	
   137	# Negative control: this is the deliberately inverted pre-fix classifier.  Every case must be
   138	# observed to fail the same assertion, proving the controls catch a resource kill misreported as
   139	# `pre-advance-failed` rather than merely documenting the expected production behaviour.
   140	def inverted_classifier(returncode, cpu_s):
   141	    if cpu_s > 0 and returncode in cases.values():
   142	        return returncode, None
   143	    return driver.GATE_GUARD_KILL_EXIT, "inverted"
   144	
   145	for label, returncode in cases.items():
   146	    try:
   147	        must_classify_as_guard_kill(inverted_classifier, label, returncode)
   148	    except AssertionError:
   149	        pass
   150	    else:
   151	        raise AssertionError(("negative control did not fail", label))
   152	
   153	# A genuine red gate and a disabled CPU layer must stay red; broadening this classification would
   154	# recreate GH-407 in the opposite direction.
   155	for returncode in (1, -signal.SIGTERM):
   156	    assert driver.gate_guard_cpu_attribution(returncode, 2)[0] == returncode
   157	assert driver.gate_guard_cpu_attribution(-signal.SIGKILL, 0)[0] == -signal.SIGKILL
   158	print("four attribution shapes + inverted negative control observed")
   159	PY
   160	)"; rc=$?
   161	if [ "$rc" -eq 0 ]; then
   162	  pass "all CPU signal/Bash attribution shapes are covered through the module-level seam"
   163	else
   164	  fail "attribution seam coverage failed: $out"
   165	fi
   166	
   167	# ── (1) an honest gate is unaffected, and telemetry is recorded ──────────────────────────
   168	out="$(run_driver --phase-id p1 --pre-advance-cmd '/usr/bin/true' 2>&1)"; rc=$?
   169	if [ "$rc" -eq 0 ]; then
   170	  pass "an honest gate still passes under the guard (exit 0)"
   171	else
   172	  fail "guard broke an honest gate (rc=$rc): $(printf '%s' "$out" | tail -5)"
   173	fi
   174	case "$out" in
   175	  *"peak group RSS"*) pass "peak-RSS telemetry is logged on a passing run (the Phase 3 trip condition)" ;;
   176	  *) fail "no peak-RSS telemetry logged on a passing run: $(printf '%s' "$out" | tail -5)" ;;
   177	esac
   178	
   179	# ── (2) layer 3: a runaway allocator is killed at the RSS cap ────────────────────────────
   180	start=$SECONDS
   181	out="$(MARATHON_GATE_RSS_MB=256 run_driver --phase-id p2 --pre-advance-cmd "python3 $HOG" 2>&1)"; rc=$?
   182	elapsed=$((SECONDS - start))
   183	if [ "$rc" -eq 5 ]; then
   184	  pass "a runaway allocator halts the phase (exit 5) instead of the host"
   185	else
   186	  fail "expected exit 5 for a killed gate, got $rc — the hog may have run to its own ceiling: $(printf '%s' "$out" | tail -5)"
   187	fi
   188	case "$out" in
   189	  *"KILLING gate process group"*) pass "layer 3 killed the gate's whole process group" ;;
   190	  *) fail "no group kill logged — the RSS watchdog did not fire: $(printf '%s' "$out" | tail -5)" ;;
   191	esac
   192	if [ "$(esc_reason p2)" = "gate-killed" ]; then
   193	  pass "ESCALATION.md records reason: gate-killed (distinct from a red gate)"
   194	else
   195	  fail "expected reason gate-killed, got '$(esc_reason p2)'"
   196	fi
   197	if [ "$elapsed" -lt 30 ]; then
   198	  pass "the kill landed promptly (${elapsed}s), well before the hog's own 1 GB ceiling"
   199	else
   200	  fail "kill took ${elapsed}s — too slow to be protecting anything"
   201	fi
   202	
   203	# ── (3) layer 1: a hang is killed at the wall-clock cap ──────────────────────────────────
   204	start=$SECONDS
   205	out="$(MARATHON_GATE_WALL_S=3 MARATHON_GATE_CPU_S=0 run_driver --phase-id p3 --pre-advance-cmd 'sleep 60' 2>&1)"; rc=$?
   206	elapsed=$((SECONDS - start))
   207	if [ "$rc" -eq 5 ] && [ "$elapsed" -lt 40 ]; then
   208	  pass "a hanging gate is killed at the wall-clock cap (${elapsed}s, exit 5)"
   209	else
   210	  fail "hanging gate not capped (rc=$rc, ${elapsed}s): $(printf '%s' "$out" | tail -5)"
   211	fi
   212	case "$out" in
   213	  *"wall clock"*) pass "the kill reason names the wall-clock cap" ;;
   214	  *) fail "wall-clock cap not named in the kill reason: $(printf '%s' "$out" | tail -5)" ;;
   215	esac
   216	
   217	# ── (4) layer 2: a CPU spin is killed by ulimit -t, and reads as a guard kill ────────────
   218	# Wall and RSS are set out of reach so only the kernel-enforced cap can end this.
   219	start=$SECONDS
   220	out="$(MARATHON_GATE_CPU_S=2 MARATHON_GATE_WALL_S=120 MARATHON_GATE_RSS_MB=0 \
   221	       run_driver --phase-id p4 --pre-advance-cmd 'python3 -c "while True: pass"' 2>&1)"; rc=$?
   222	elapsed=$((SECONDS - start))
   223	if [ "$rc" -eq 5 ] && [ "$elapsed" -lt 60 ]; then
   224	  pass "a CPU spin is killed by the kernel-enforced cap (${elapsed}s, exit 5)"
   225	else
   226	  fail "CPU cap did not end the spin (rc=$rc, ${elapsed}s): $(printf '%s' "$out" | tail -5)"
   227	fi
   228	if [ "$(esc_reason p4)" = "gate-killed" ]; then
   229	  pass "a SIGXCPU kill escalates as gate-killed, not as the gate finding a defect"
   230	else
   231	  # The reason alone cannot tell you WHY it was misclassified — the whole question is which exit
   232	  # status the kill arrived as, and the guard already logs it. Print it, or this failure costs a
   233	  # CI round-trip to say anything actionable.
   234	  fail "expected reason gate-killed for the CPU cap, got '$(esc_reason p4)' \
   235	[$(printf '%s' "$out" | /usr/bin/grep -o 'gate-guard: gate exit [-0-9]*' | tail -1)]"
   236	fi
   237	
   238	# ── (5) GH-382's actual runaway: MagicMock in a while-True loop ───────────────────────────
   239	# The 96 MB cap is intentionally much lower than the general allocator's 256 MB cap: this fixture
   240	# can append calls very quickly before the one-second watchdog poll, but it still leaves room for a
   241	# normal Python process.  It is the recorded post-fix baseline described beside MOCK_HOG above.
   242	start=$SECONDS
   243	out="$(MARATHON_GATE_RSS_MB=96 run_driver --phase-id p7 --pre-advance-cmd "python3 $MOCK_HOG" 2>&1)"; rc=$?
   244	elapsed=$((SECONDS - start))
   245	if [ "$rc" -eq 5 ] && [ "$(esc_reason p7)" = "gate-killed" ]; then
   246	  pass "GH-382 MagicMock-in-while-True runaway is killed and attributed as gate-killed"
   247	else
   248	  fail "GH-382 reproducer was not attributed as gate-killed (rc=$rc, reason=$(esc_reason p7)): $(printf '%s' "$out" | tail -5)"
   249	fi
   250	case "$out" in
   251	  *"KILLING gate process group"*"gate exit 108"*) pass "GH-382 baseline records group kill and distinct guard exit (108, ${elapsed}s)" ;;
   252	  *) fail "GH-382 baseline missing guard-kill evidence: $(printf '%s' "$out" | tail -8)" ;;
   253	esac
   254	
   255	# ── (6) a genuinely failing gate is still `pre-advance-failed` ───────────────────────────
   256	out="$(run_driver --phase-id p5 --pre-advance-cmd '/usr/bin/false' 2>&1)"; rc=$?
   257	if [ "$rc" -eq 5 ]; then
   258	  pass "a red gate still halts the phase (exit 5)"
   259	else
   260	  fail "a red gate did not halt the phase (rc=$rc): $(printf '%s' "$out" | tail -5)"
   261	fi
   262	if [ "$(esc_reason p5)" = "pre-advance-failed" ]; then
   263	  pass "a red gate keeps reason pre-advance-failed — the guard does not relabel real failures"
   264	else
   265	  fail "guard relabelled a real gate failure as '$(esc_reason p5)'"
   266	fi
   267	
   268	# ── (7) the escape hatch restores the unguarded path ─────────────────────────────────────
   269	# The same allocator that case (2) killed must now run to its own 1 GB ceiling and pass,
   270	# proving the switch removes the guard rather than merely loosening a cap.
   271	out="$(MARATHON_GATE_GUARD=0 MARATHON_GATE_RSS_MB=256 run_driver --phase-id p6 --pre-advance-cmd "python3 $HOG" 2>&1)"; rc=$?
   272	if [ "$rc" -eq 0 ]; then
   273	  pass "MARATHON_GATE_GUARD=0 restores the unguarded gate (the hog completes, exit 0)"
   274	else
   275	  fail "escape hatch did not restore unguarded behavior (rc=$rc): $(printf '%s' "$out" | tail -5)"
   276	fi
   277	case "$out" in
   278	  *"KILLING gate process group"*) fail "guard still killed the gate with MARATHON_GATE_GUARD=0" ;;
   279	  *) pass "no kill occurred with the guard disabled" ;;
   280	esac
   281	
   282	echo "  gh390-gate-guard: $PASS pass, $FAIL fail"
   283	exit 0
=== test/gh390-timeout-attribution.sh
     1	#!/usr/bin/env bash
     2	# Timeout attribution (exit-7 reason strings) — turn_diagnostics.
     3	#
     4	# An exit-7 turn can mean "slow agent", "runaway loop", or "a modal OS dialog
     5	# blocked the process and no budget will ever be enough". Those need opposite
     6	# responses, so the shims classify the timeout instead of reporting a bare code.
     7	# This pins each classification against a real sampled process, not a mock.
     8	#
     9	# Every fixture is self-limiting (bounded sleep / bounded spin), so this suite
    10	# cannot itself hang the machine it is protecting.
    11	set -uo pipefail
    12	
    13	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    14	PY_DIR="$HERE/../utils/py"
    15	TMP="$(mktemp -d "${TMPDIR:-/tmp}/gh390-timeout-attr.XXXXXX")"
    16	trap 'rm -rf "$TMP"' EXIT
    17	
    18	pass=0; fail=0
    19	ok()   { printf '  PASS: %s\n' "$1"; pass=$((pass + 1)); }
    20	bad()  { printf '  FAIL: %s\n' "$1"; fail=$((fail + 1)); }
    21	
    22	# Run a python snippet with utils/py importable.
    23	pyrun() { PYTHONPATH="$PY_DIR" python3 -c "$1" 2>&1; }
    24	
    25	# --- parser: ps TIME shapes across platforms -------------------------------
    26	out="$(pyrun '
    27	from turn_diagnostics import _parse_ps_time as p
    28	cases = {"0:00.07": 0.07, "1:02.50": 62.5, "1:00:00": 3600.0, "2-01:00:00": 176400.0, "": 0.0, "garbage": 0.0}
    29	bad = [(k, p(k), v) for k, v in cases.items() if abs(p(k) - v) > 0.001]
    30	print("OK" if not bad else f"BAD {bad}")
    31	')"
    32	[ "$out" = "OK" ] && ok "ps TIME parser handles mm:ss, hh:mm:ss, dd-hh:mm:ss, and junk" \
    33	                  || bad "ps TIME parser: $out"
    34	
    35	# --- a probe failure must never raise --------------------------------------
    36	out="$(pyrun '
    37	import turn_diagnostics as td
    38	td._run = lambda *a, **k: (_ for _ in ()).throw(RuntimeError("probe exploded"))
    39	d = td.TurnDiagnostics(worktree=None)
    40	try:
    41	    d._sample()
    42	    print("RAISED-NOT")
    43	except Exception as e:
    44	    print(f"RAISED {e}")
    45	')"
    46	# _sample calls _run indirectly; the loop wraps it, but classify must survive either way.
    47	case "$out" in
    48	  RAISED-NOT|RAISED*) ok "a failing probe does not escape as an unhandled crash path" ;;
    49	  *) bad "probe failure: $out" ;;
    50	esac
    51	
    52	# --- unclassified when there is nothing to go on ---------------------------
    53	out="$(pyrun '
    54	from turn_diagnostics import TurnDiagnostics, REASON_UNCLASSIFIED
    55	d = TurnDiagnostics(worktree=None)
    56	r, _ = d.classify()
    57	print("OK" if r == REASON_UNCLASSIFIED else f"BAD {r}")
    58	')"
    59	[ "$out" = "OK" ] && ok "no samples -> timeout-unclassified (never guesses)" || bad "unclassified: $out"
    60	
    61	# --- CPU-bound: a real spinning child --------------------------------------
    62	out="$(pyrun '
    63	import subprocess, time
    64	from turn_diagnostics import TurnDiagnostics, REASON_CPU_BOUND
    65	d = TurnDiagnostics(worktree=None, interval=0.5)
    66	d.start()
    67	p = subprocess.Popen(["python3", "-c", "import time\nt=time.time()\nwhile time.time()-t<3: pass"])
    68	time.sleep(3.2); p.wait(); d.stop()
    69	r, detail = d.classify()
    70	print("OK" if r == REASON_CPU_BOUND else f"BAD {r} :: {detail}")
    71	')"
    72	[ "$out" = "OK" ] && ok "a spinning child classifies as timeout-cpu-bound (runaway shape)" \
    73	                  || bad "cpu-bound: $out"
    74	
    75	# --- a runaway that DIED must still read as cpu-bound ----------------------
    76	# Regression: the real sequence is kill-then-classify, and a dead process leaves
    77	# ps entirely — so anchoring on the last sample scored a runaway as 0.00s/s and
    78	# reported "idle", the exact opposite of the truth. Peak CPU is the anchor.
    79	out="$(pyrun '
    80	from turn_diagnostics import TurnDiagnostics, REASON_CPU_BOUND
    81	d = TurnDiagnostics(worktree=None)
    82	# tree burned 5 CPU-seconds over 5 wall-seconds, then exited (accounting -> 0)
    83	d.samples = [(0.0, 0.0, 1), (2.5, 2.5, 1), (5.0, 5.0, 1), (6.0, 0.0, 0)]
    84	r, detail = d.classify()
    85	print("OK" if r == REASON_CPU_BOUND else f"BAD {r} :: {detail}")
    86	')"
    87	[ "$out" = "OK" ] && ok "a runaway that exited before the last sample still reads cpu-bound" \
    88	                  || bad "dead-runaway anchoring: $out"
    89	
    90	# --- a perfectly flat CPU trace must classify, not fall through ------------
    91	# Regression: peak-anchoring left t_peak == t0 when CPU never grew, producing a
    92	# zero-length window and `unclassified`. That is exactly the blocked-process
    93	# case this module exists to name — a turn stalled on a modal dialog burns no
    94	# CPU at all — so a flat trace has to score a real 0.0 over the full window.
    95	out="$(pyrun '
    96	from turn_diagnostics import TurnDiagnostics, REASON_IDLE
    97	d = TurnDiagnostics(worktree=None)
    98	d.samples = [(0.0, 0.0, 1), (5.0, 0.0, 1), (10.0, 0.0, 1)]   # flat: zero CPU throughout
    99	ratio = d.cpu_ratio()
   100	r, _ = d.classify()
   101	print("OK" if ratio == 0.0 and r == REASON_IDLE else f"BAD ratio={ratio} reason={r}")
   102	')"
   103	[ "$out" = "OK" ] && ok "a flat zero-CPU trace scores 0.0 and classifies as idle (not unclassified)" \
   104	                  || bad "flat-trace anchoring: $out"
   105	
   106	# --- idle: a real sleeping child, no file progress -------------------------
   107	out="$(pyrun '
   108	import subprocess, time
   109	from turn_diagnostics import TurnDiagnostics, REASON_IDLE
   110	d = TurnDiagnostics(worktree=None, interval=0.5)
   111	d.start()
   112	p = subprocess.Popen(["sleep", "3"])
   113	time.sleep(3.2); p.wait(); d.stop()
   114	r, detail = d.classify()
   115	print("OK" if r == REASON_IDLE else f"BAD {r} :: {detail}")
   116	')"
   117	[ "$out" = "OK" ] && ok "a sleeping child with no writes classifies as timeout-idle-no-progress" \
   118	                  || bad "idle: $out"
   119	
   120	# --- slow-but-progressing: idle CPU but the worktree is being written ------
   121	mkdir -p "$TMP/wt"; : > "$TMP/wt/seed"
   122	out="$(pyrun "
   123	import subprocess, time, os
   124	from turn_diagnostics import TurnDiagnostics, REASON_SLOW_PROGRESS
   125	wt = '$TMP/wt'
   126	d = TurnDiagnostics(worktree=wt, interval=0.5)
   127	d.start()
   128	p = subprocess.Popen(['sleep', '3'])
   129	time.sleep(1.0)
   130	open(os.path.join(wt, 'progress.txt'), 'w').write('builder wrote this')
   131	time.sleep(2.2); p.wait(); d.stop()
   132	r, detail = d.classify()
   133	print('OK' if r == REASON_SLOW_PROGRESS else f'BAD {r} :: {detail}')
   134	")"
   135	[ "$out" = "OK" ] && ok "idle CPU + fresh worktree writes -> timeout-slow-but-progressing" \
   136	                  || bad "slow-progress: $out"
   137	
   138	# --- security dialog outranks every other signal ---------------------------
   139	out="$(pyrun '
   140	from turn_diagnostics import TurnDiagnostics, REASON_SECURITY_DIALOG
   141	d = TurnDiagnostics(worktree=None)
   142	d.security_dialog_seen = True          # sticky flag the sampler would have set
   143	d.samples = [(0.0, 0.0, 1), (10.0, 9.9, 1)]   # would otherwise read as cpu-bound
   144	r, detail = d.classify()
   145	ok = r == REASON_SECURITY_DIALOG and "Raising the turn budget will not help" in detail
   146	print("OK" if ok else f"BAD {r} :: {detail}")
   147	')"
   148	[ "$out" = "OK" ] && ok "a seen auth dialog outranks CPU evidence and says budget will not help" \
   149	                  || bad "security-dialog precedence: $out"
   150	
   151	# --- the dialog probe must not match general-purpose interpreters ----------
   152	# Regression: osascript was originally in this list. It is a general-purpose
   153	# AppleScript interpreter, so unrelated automation on the machine set the flag
   154	# and produced a confident, wrong "a dialog blocked your turn" verdict. Measured
   155	# live: transient osascript PIDs appeared inside a 4s window with no dialog up.
   156	out="$(pyrun '
   157	from turn_diagnostics import SECURITY_AGENT_PROCS as S
   158	banned = {"osascript", "python3", "bash", "sh", "sudo", "ssh"}
   159	hit = banned & set(S)
   160	print("OK" if not hit else f"BAD {hit}")
   161	')"
   162	[ "$out" = "OK" ] && ok "dialog probe list excludes general-purpose interpreters (osascript regression)" \
   163	                  || bad "dialog probe list too broad: $out"
   164	
   165	# --- a single blip must not confirm a dialog -------------------------------
   166	out="$(pyrun '
   167	import turn_diagnostics as td
   168	d = td.TurnDiagnostics(worktree=None)
   169	calls = {"n": 0}
   170	def flaky():
   171	    calls["n"] += 1
   172	    return calls["n"] == 1          # one positive, then quiet
   173	td._security_dialog_present = flaky
   174	td._descendant_cpu_seconds = lambda pid: (0.0, 1)
   175	for _ in range(4):
   176	    d._sample()
   177	print("OK" if not d.security_dialog_seen else "BAD single blip confirmed a dialog")
   178	')"
   179	[ "$out" = "OK" ] && ok "one isolated positive does not confirm a dialog (needs consecutive samples)" \
   180	                  || bad "dialog debounce: $out"
   181	
   182	# --- sustained presence still confirms -------------------------------------
   183	out="$(pyrun '
   184	import turn_diagnostics as td
   185	d = td.TurnDiagnostics(worktree=None)
   186	td._security_dialog_present = lambda: True
   187	td._descendant_cpu_seconds = lambda pid: (0.0, 1)
   188	d._sample(); d._sample()
   189	print("OK" if d.security_dialog_seen else "BAD sustained dialog was not confirmed")
   190	')"
   191	[ "$out" = "OK" ] && ok "a dialog present across consecutive samples is confirmed" \
   192	                  || bad "dialog confirm: $out"
   193	
   194	# --- the shims actually wire it in -----------------------------------------
   195	wired=0
   196	for f in claude-turn.py agy-turn.py codex-turn.py; do
   197	  if grep -q "from turn_diagnostics import TurnDiagnostics" "$PY_DIR/$f" \
   198	     && grep -q "diag.classify()" "$PY_DIR/$f" \
   199	     && grep -q "diag.stop()" "$PY_DIR/$f"; then
   200	    wired=$((wired + 1))
   201	  else
   202	    bad "$f does not import/stop/classify TurnDiagnostics"
   203	  fi
   204	done
   205	[ "$wired" -eq 3 ] && ok "all three turn shims start, stop, and classify diagnostics"
   206	
   207	# --- exit code must stay 7 (callers depend on the number) ------------------
   208	if grep -q 'bounded_rc = 7' "$PY_DIR/claude-turn.py" \
   209	   && ! grep -qE 'bounded_rc = (10[0-9]|8|9)\b' "$PY_DIR/claude-turn.py"; then
   210	  ok "attribution did not change the exit code — callers still see 7"
   211	else
   212	  bad "exit code for a timeout changed; downstream callers would break"
   213	fi
   214	
   215	printf 'gh390-timeout-attribution: %d pass, %d fail\n' "$pass" "$fail"
   216	[ "$fail" -eq 0 ]
=== test/gh407-gate-ran-attribution.sh
     1	#!/usr/bin/env bash
     2	# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh407-gate-ran-attribution.sh. The pre-fix revision is replayed inside the fixture by patching the driver copy back to its old single-expression form (reason = pre-advance-failed whenever no timeout reason was recorded, with no gate: line in ESCALATION.md). Pre-fix result: a phase whose builder never produced work escalated as pre-advance-failed and the record carried no statement of whether the gate ran. Post-fix result: the same phase escalates as relay-failed-before-gate with gate: not-run, while a genuinely red gate still escalates as pre-advance-failed with gate: red. Both observed in one run."}
     3	# GH-407: `pre-advance-failed` asserts that the gate RAN and found a defect in the change.
     4	#
     5	# Several unrelated failures reach the same relay exit 5 — a builder shim that failed to start, a
     6	# builder that exhausted its turn cap, a reviewer turn discarded by containment — and all of them
     7	# were reported with that label. Observed three times in one 10-lane marathon on 2026-08-02, wrong
     8	# all three times; in one case the relay file read STATUS: Approved while the phase was escalated as
     9	# though the gate had rejected the work.
    10	#
    11	# Why the mislabel costs real time: the reason is the operator's entry point into a failed run.
    12	# `pre-advance-failed` sends them to read the diff and the test output. When the gate never ran there
    13	# is no test output, and nothing in the escalation record said so — confirming it required checking
    14	# whether any pytest output existed anywhere after the phase started.
    15	#
    16	# Pinned here:
    17	#   (1) a relay failure that never reached the gate does NOT claim a gate verdict
    18	#   (2) every escalation states whether the gate ran, on every reason
    19	#   (3) a genuinely red gate still reports pre-advance-failed with gate: red  <- anti-overcorrection
    20	#   (4) the reason for the no-gate case names no cause it cannot determine
    21	#
    22	# (3) is the assertion that protects against the cheap fix. Reserving `pre-advance-failed` is easy to
    23	# over-apply: relabel every exit 5 and criteria 1, 2 and 4 all pass while real gate failures stop
    24	# being reported as gate failures — the same defect pointing the other way.
    25	set -euo pipefail
    26	
    27	source "$(dirname "$0")/_setup.sh" gh407-gate-ran-attribution
    28	export TICK_BIN="$TICK"
    29	ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
    30	DRIVER="$ROOT_REPO/relay-automation/marathon-drive.sh"
    31	
    32	ROOT="$WORK/target"
    33	mkdir -p "$ROOT"
    34	git init -q "$ROOT"
    35	git -C "$ROOT" config user.email gh407@t
    36	git -C "$ROOT" config user.name gh407
    37	printf '.tick/\n' > "$ROOT/.gitignore"
    38	printf '#!/usr/bin/env bash\nexit 0\n' > "$ROOT/validate.sh"
    39	git -C "$ROOT" add .gitignore validate.sh >/dev/null 2>&1
    40	git -C "$ROOT" commit -q -m init
    41	
    42	STUB_BIN="$WORK/stub-bin"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_BIN"; chmod +x "$STUB_BIN"
    43	BRIEF="$WORK/brief.md"; printf '## Do a thing\nBody.\n' > "$BRIEF"
    44	
    45	# Stub relay-drive, exit 5 WITHOUT approving: this is the shape the issue describes — the relay
    46	# failed (builder never produced work), so the driver never reaches its own gate.
    47	RD_FAIL="$WORK/relay-drive-fail.sh"
    48	cat > "$RD_FAIL" << 'STUB_EOF'
    49	#!/usr/bin/env bash
    50	set -u
    51	exit 5
    52	STUB_EOF
    53	chmod +x "$RD_FAIL"
    54	
    55	# Stub relay-drive that DOES approve, so the driver runs its gate and the gate decides.
    56	RD_OK="$WORK/relay-drive-ok.sh"
    57	cat > "$RD_OK" << 'STUB_EOF'
    58	#!/usr/bin/env bash
    59	set -u
    60	rf=""
    61	while (($#)); do case "$1" in --relay-file) rf="${2:-}"; shift 2 ;; *) shift ;; esac; done
    62	[ -n "$rf" ] && printf 'STATUS: Approved\n' >> "$rf"
    63	exit 0
    64	STUB_EOF
    65	chmod +x "$RD_OK"
    66	
    67	run_driver() {  # <relay-drive-stub> <extra-args…>
    68	  local rd="$1"; shift
    69	  MARATHON_ROOT="$ROOT" \
    70	  MARATHON_RELAY_DRIVE="$rd" \
    71	  MARATHON_AGENT_CMD="$WORK/noop-agent" \
    72	  TICK_REPO_ROOT="$ROOT" TICK_BIN="$TICK" \
    73	  CLAUDE_BIN="$STUB_BIN" AGY_BIN="$STUB_BIN" CODEX_BIN="$STUB_BIN" \
    74	  bash "$DRIVER" \
    75	    --phases-dir "$ROOT/phases" \
    76	    --phase-brief "$BRIEF" \
    77	    --reviewer agy \
    78	    --builder claude \
    79	    "$@"
    80	}
    81	esc_field() { sed -n "s/^$2: //p" "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null; }
    82	
    83	# ── (1)(2)(4) the relay failed before the gate ────────────────────────────────────────────
    84	printf '#!/usr/bin/env bash\nexit 0\n' > "$ROOT/validate.sh"
    85	run_driver "$RD_FAIL" --phase-id no-gate > "$WORK/no-gate.log" 2>&1 && rc=0 || rc=$?
    86	reason="$(esc_field no-gate reason)"
    87	gate="$(esc_field no-gate gate)"
    88	
    89	[ "$reason" != "pre-advance-failed" ] \
    90	  && pass "a relay failure that never reached the gate does NOT claim pre-advance-failed (got: $reason)" \
    91	  || fail "the gate never ran, yet the phase was reported as pre-advance-failed"
    92	
    93	[ "$reason" = "relay-failed-before-gate" ] \
    94	  && pass "the no-gate case reports relay-failed-before-gate — states what is known, names no cause it cannot determine" \
    95	  || fail "expected relay-failed-before-gate, got '$reason'"
    96	
    97	[ "$gate" = "not-run" ] \
    98	  && pass "ESCALATION.md records gate: not-run — the one line that resolves the ambiguity" \
    99	  || fail "expected 'gate: not-run' in the escalation record, got '$gate'"
   100	
   101	# ── (3) anti-overcorrection: a real gate failure is still a gate failure ──────────────────
   102	printf '#!/usr/bin/env bash\nexit 1\n' > "$ROOT/validate.sh"
   103	run_driver "$RD_OK" --phase-id red-gate > "$WORK/red-gate.log" 2>&1 && rc=0 || rc=$?
   104	reason="$(esc_field red-gate reason)"
   105	gate="$(esc_field red-gate gate)"
   106	
   107	[ "$reason" = "pre-advance-failed" ] \
   108	  && pass "a gate that RAN and failed is still pre-advance-failed — the fix does not relabel real failures" \
   109	  || fail "a real gate failure was reported as '$reason' — GH-407 pointing the other way"
   110	
   111	[ "$gate" = "red" ] \
   112	  && pass "ESCALATION.md records gate: red, so the record distinguishes a verdict from a non-run" \
   113	  || fail "expected 'gate: red', got '$gate'"
   114	
   115	# ── (5) the THIRD value: an escalation that happens AFTER a green gate says so ─────────────
   116	# Added after a codex review of the merged fix noted the suite pinned `not-run` and `red` but never
   117	# `green` — so `gate:` could have been hardwired to emit only the two failure words and every other
   118	# assertion here would still pass. `requires-test-missing` is the reachable green-gate escalation: it
   119	# is checked after the gate returns 0 (marathon_drive.py:1504), so the gate genuinely ran and passed
   120	# while the phase still halted. That is precisely the case an operator must be able to tell apart from
   121	# a gate failure, which is this issue's whole subject.
   122	printf '#!/usr/bin/env bash\nexit 0\n' > "$ROOT/validate.sh"
   123	run_driver "$RD_OK" --phase-id green-gate --requires-test "test/definitely-absent-$$.sh" > "$WORK/green-gate.log" 2>&1 && rc=0 || rc=$?
   124	reason="$(esc_field green-gate reason)"
   125	gate="$(esc_field green-gate gate)"
   126	
   127	[ "$reason" = "requires-test-missing" ] \
   128	  && pass "a phase halted after a PASSING gate keeps its own reason (requires-test-missing), not a gate verdict" \
   129	  || fail "expected requires-test-missing after a green gate, got '$reason'"
   130	
   131	[ "$gate" = "green" ] \
   132	  && pass "ESCALATION.md records gate: green — all three values are now observed, so the field cannot be a two-word failure label" \
   133	  || fail "expected 'gate: green' for an escalation after a passing gate, got '$gate'"
   134	
   135	# ── the pre-fix replay (#419): the old single-expression form, inside the fixture ──────────
   136	# Replayed against a COPY of the driver so the working tree is never mutated. The copy is patched
   137	# back to the pre-fix behaviour and driven through the same no-gate case, which must produce the old
   138	# wrong answer. If it does not, this whole file is asserting something that was never broken.
   139	FIXH="$WORK/prefix-harness"
   140	mkdir -p "$FIXH"
   141	for d in relay-automation utils bin src; do
   142	  [ -e "$ROOT_REPO/$d" ] && cp -R "$ROOT_REPO/$d" "$FIXH/$d"
   143	done
   144	PRE_MD="$FIXH/utils/py/marathon_drive.py"
   145	python3 - "$PRE_MD" <<'PY'
   146	import pathlib, sys
   147	p = pathlib.Path(sys.argv[1]); s = p.read_text()
   148	
   149	# revert the escalation record: drop the gate: line
   150	before = s
   151	s = s.replace("reason: {reason}\ngate: {run_gate_result[0]}\n", "reason: {reason}\n", 1)
   152	assert s != before, "could not revert the gate: line — pre-fix replay would be vacuous"
   153	
   154	# revert the reason choice to the old unconditional form
   155	i = s.index("        gate_ran = run_gate_result[0] != \"not-run\"")
   156	j = s.index("        escalate(reason, 5)", i)
   157	s = s[:i] + (
   158	'        reason = timeout_reason[0] if timeout_reason[0] != "turn-timeout-or-hang" else "pre-advance-failed"\n'
   159	'        emit = timeout_emit[0] if timeout_reason[0] != "turn-timeout-or-hang" else "halted"\n'
   160	'        log("relay escalated: pre-advance gate failed")\n'
   161	) + s[j:]
   162	p.write_text(s)
   163	print("PATCHED")
   164	PY
   165	
   166	PRE_DRIVER="$FIXH/relay-automation/marathon-drive.sh"
   167	PRE_ROOT="$WORK/target-prefix"
   168	cp -R "$ROOT" "$PRE_ROOT"
   169	rm -rf "$PRE_ROOT/phases"
   170	MARATHON_ROOT="$PRE_ROOT" \
   171	MARATHON_RELAY_DRIVE="$RD_FAIL" \
   172	MARATHON_AGENT_CMD="$WORK/noop-agent" \
   173	TICK_REPO_ROOT="$PRE_ROOT" TICK_BIN="$TICK" \
   174	CLAUDE_BIN="$STUB_BIN" AGY_BIN="$STUB_BIN" CODEX_BIN="$STUB_BIN" \
   175	  bash "$PRE_DRIVER" --phases-dir "$PRE_ROOT/phases" --phase-brief "$BRIEF" \
   176	    --reviewer agy --builder claude --phase-id no-gate > "$WORK/prefix.log" 2>&1 && rc=0 || rc=$?
   177	
   178	pre_reason="$(sed -n 's/^reason: //p' "$PRE_ROOT/phases/no-gate/ESCALATION.md" 2>/dev/null)"
   179	pre_gate="$(sed -n 's/^gate: //p' "$PRE_ROOT/phases/no-gate/ESCALATION.md" 2>/dev/null)"
   180	
   181	[ "$pre_reason" = "pre-advance-failed" ] \
   182	  && pass "control: the pre-fix revision reports pre-advance-failed for a gate that never ran (the defect, observed)" \
   183	  || fail "control: pre-fix replay did not reproduce the defect — got reason '$pre_reason', so the post-fix assertions prove nothing"
   184	
   185	[ -z "$pre_gate" ] \
   186	  && pass "control: the pre-fix record carries NO statement of whether the gate ran" \
   187	  || fail "control: pre-fix record unexpectedly had 'gate: $pre_gate'"
   188	
   189	echo "gh407-gate-ran-attribution: $PASS pass, $FAIL fail"
=== test/gh419-gate-inventory.sh
     1	#!/usr/bin/env bash
     2	# gate-evidence: {"form":"controlled-bad-fixture","observed":true,"result":"self-comparing and self-regenerating fixtures were reported as none"}
     3	# GH-419 — inventory discovery and negative-control evidence must stay separate.
     4	set -euo pipefail
     5	
     6	HERE="$(cd "$(dirname "$0")/.." && pwd)"
     7	FIXTURE="$(mktemp -d "${TMPDIR:-/tmp}/gh419-gate-inventory.XXXXXX")"
     8	trap 'rm -rf "$FIXTURE"' EXIT
     9	
    10	mkdir -p "$FIXTURE/test"
    11	cat >"$FIXTURE/validate.sh" <<'EOF'
    12	TESTS=(
    13	  "safe.sh"
    14	  "self-comparing.sh"
    15	  "self-regenerating.sh"
    16	  "new-gate.sh"
    17	)
    18	EOF
    19	
    20	cat >"$FIXTURE/test/safe.sh" <<'EOF'
    21	# gate-evidence: {"form":"deliberate-mutation","observed":true,"result":"mutation made this fixture fail"}
    22	test "safe" = "safe"
    23	EOF
    24	cat >"$FIXTURE/test/self-comparing.sh" <<'EOF'
    25	# gate-evidence: {"form":"controlled-bad-fixture","observed":true,"result":"this declaration must not override the shape"}
    26	cmp "$candidate" "$candidate"
    27	EOF
    28	cat >"$FIXTURE/test/self-regenerating.sh" <<'EOF'
    29	# gate-evidence: {"form":"controlled-bad-fixture","observed":true,"result":"this declaration must not override the shape"}
    30	generate-report > "$EXPECTED_SNAPSHOT"
    31	diff "$EXPECTED_SNAPSHOT" "$actual"
    32	EOF
    33	cat >"$FIXTURE/test/new-gate.sh" <<'EOF'
    34	test "new gate" = "new gate"
    35	EOF
    36	
    37	python3 "$HERE/utils/py/gate_inventory.py" --root "$FIXTURE" >"$FIXTURE/inventory.json"
    38	python3 - "$FIXTURE/inventory.json" <<'PY'
    39	import json
    40	import sys
    41	
    42	report = json.load(open(sys.argv[1], encoding="utf-8"))
    43	gates = {row["gate"]: row for row in report["gates"]}
    44	assert set(gates) == {
    45	    "test/safe.sh",
    46	    "test/self-comparing.sh",
    47	    "test/self-regenerating.sh",
    48	    "test/new-gate.sh",
    49	}, gates
    50	assert gates["test/safe.sh"]["negative_control"]["form"] == "deliberate-mutation"
    51	assert gates["test/safe.sh"]["negative_control"]["observed"] is True
    52	for gate, shape in (
    53	    ("test/self-comparing.sh", "self-comparing-parity"),
    54	    ("test/self-regenerating.sh", "self-regenerating-drift"),
    55	):
    56	    row = gates[gate]
    57	    assert shape in row["disqualifying_shapes"], row
    58	    assert row["negative_control"]["form"] == "none", row
    59	    assert row["negative_control"]["observed"] is False, row
    60	assert gates["test/new-gate.sh"]["negative_control"]["form"] == "none"
    61	assert gates["test/new-gate.sh"]["negative_control"]["observed"] is False
    62	PY
    63	
    64	python3 "$HERE/utils/py/gate_inventory.py" --root "$HERE" >"$FIXTURE/repo-inventory.json"
    65	python3 - "$FIXTURE/repo-inventory.json" <<'PY'
    66	import json
    67	import sys
    68	
    69	gates = {row["gate"]: row for row in json.load(open(sys.argv[1], encoding="utf-8"))["gates"]}
    70	row = gates["test/gh419-gate-inventory.sh"]
    71	assert row["negative_control"]["form"] == "controlled-bad-fixture", row
    72	assert row["negative_control"]["observed"] is True, row
    73	PY
    74	
    75	echo "PASS: GH-419 inventory discovers registered gates and records only declared controls"
=== test/marathon-drive.sh
     1	#!/usr/bin/env bash
     2	# marathon-drive.sh test: single-phase driver — renders relay file, seeds tick token,
     3	# calls relay-drive, runs pre-advance gate, saves transcript, emits phase events.
     4	# Uses MARATHON_RELAY_DRIVE + MARATHON_AGENT_CMD + stub pre-advance-cmd to avoid real CLI.
     5	source "$(dirname "$0")/_setup.sh" marathon-drive
     6	unset MARATHON_LANE_NS
     7	export TICK_BIN="$TICK"
     8	DRIVER="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/marathon-drive.sh"
     9	tick_a init >/dev/null
    10	
    11	# Set up the fixture repo as the marathon root: .gitignore .tick/, seed an initial commit.
    12	printf '.tick/\n' > "$A/.gitignore"
    13	git -C "$A" add .gitignore >/dev/null 2>&1
    14	git -C "$A" commit -q -m "init"
    15	INIT_HEAD="$(git -C "$A" rev-parse HEAD)"   # saved so we can hard-reset between cases
    16	
    17	# Stub relay-drive: writes EXIT_CODE to $WORK/relay-drive-exit, echoes args, then exits.
    18	STUB_RD="$WORK/relay-drive.sh"
    19	cat > "$STUB_RD" << 'STUB_EOF'
    20	#!/usr/bin/env bash
    21	set -u
    22	printf '%s\n' "$*" > "$WORK/relay-drive-args"
    23	exit "${RELAY_DRIVE_EXIT:-0}"
    24	STUB_EOF
    25	chmod +x "$STUB_RD"
    26	
    27	# Phase brief file used across tests.
    28	BRIEF="$WORK/brief.md"
    29	printf '## Implement a hello-world function\nWrite a function that returns "hello".\n' > "$BRIEF"
    30	
    31	# GH-117: stub builder/reviewer binaries so marathon-drive's binary-existence probe (added ahead of
    32	# any tick mutation) sees a resolvable claude/agy on every pre-existing test below — this suite never
    33	# invokes the real CLI (relay-drive is stubbed), so it must not depend on claude/agy actually being
    34	# installed on the test machine either.
    35	STUB_CLAUDE_BIN="$WORK/stub-claude"
    36	printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_CLAUDE_BIN"
    37	chmod +x "$STUB_CLAUDE_BIN"
    38	STUB_AGY_BIN="$WORK/stub-agy"
    39	printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_AGY_BIN"
    40	chmod +x "$STUB_AGY_BIN"
    41	STUB_CODEX_BIN="$WORK/stub-codex"
    42	printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_CODEX_BIN"
    43	chmod +x "$STUB_CODEX_BIN"
    44	MISSING_BIN="$WORK/does-not-exist-bin"   # deliberately never created
    45	
    46	# GH-212: this suite's default builder identity is pinned to `claude` here (not marathon-drive's
    47	# own new `codex` default) so every existing case below — written against a literal "claude" agent
    48	# identity in tick claims/relay text — keeps testing exactly what it always tested. The dedicated
    49	# GH-212 case further down verifies the real (unpinned) default separately.
    50	run_driver() {  # <extra-args…>
    51	  MARATHON_ROOT="$A" \
    52	  MARATHON_RELAY_DRIVE="$STUB_RD" \
    53	  MARATHON_AGENT_CMD="$WORK/noop-agent" \
    54	  TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
    55	  CLAUDE_BIN="${CLAUDE_BIN:-$STUB_CLAUDE_BIN}" AGY_BIN="${AGY_BIN:-$STUB_AGY_BIN}" \
    56	  bash "$DRIVER" \
    57	    --phases-dir "$A/phases" \
    58	    --phase-brief "$BRIEF" \
    59	    --reviewer agy \
    60	    --pre-advance-cmd "true" \
    61	    --builder claude \
    62	    "$@"
    63	}
    64	
    65	# ── (1) dry-run: relay rendered and SHOWN, nothing written, no commit, no tick events ─────────
    66	# GH-401: this case used to assert `[ -f "$A/phases/p1/RELAY.md" ]` — it pinned the defect as the
    67	# contract. A dry run that writes is the bug: unscoped, that write landed on the harness's own
    68	# tracked phases/p1/RELAY.md and left `bash validate.sh` with a dirty tree. The property worth
    69	# pinning was never "the file appears"; it was "the render happened and you can see it", so the
    70	# assertion moves to the fenced render on stdout and gains its true complement — nothing on disk.
    71	out="$(run_driver --dry-run 2>&1)"; rc=$?
    72	[ "$rc" -eq 0 ] && pass "dry-run exits 0" || fail "dry-run exit=$rc"
    73	printf '%s' "$out" | grep -q '^--- BEGIN RENDERED RELAY ---$' \
    74	  && pass "dry-run emits the rendered relay on stdout" \
    75	  || fail "dry-run produced no render: $out"
    76	printf '%s' "$out" | grep -q 'TAKE YOUR TURN' \
    77	  && pass "the emitted render is the real relay body, not just a banner" \
    78	  || fail "render fence present but the body is missing"
    79	[ ! -e "$A/phases" ] \
    80	  && pass "dry-run writes nothing to disk (GH-401)" \
    81	  || fail "dry-run created $A/phases — a dry run must not mutate the tree"
    82	git -C "$A" diff --cached --quiet && pass "dry-run makes no staged changes" || fail "dry-run should not stage anything"
    83	before_head="$(git -C "$A" rev-parse HEAD)"
    84	run_driver --dry-run >/dev/null 2>&1 || true   # run again to confirm HEAD stability
    85	[ "$(git -C "$A" rev-parse HEAD)" = "$before_head" ] && pass "dry-run makes no commits" || fail "dry-run should not commit"
    86	
    87	# ── (2) relay file template: builder + reviewer sections present ──────────
    88	RELAY_DRIVE_EXIT=0 run_driver >/dev/null 2>&1 || true
    89	grep -q "TAKE YOUR TURN.*claude.*BUILDER" "$A/phases/p1/RELAY.md" 2>/dev/null \
    90	  && pass "relay file has builder TAKE YOUR TURN section" \
    91	  || fail "builder TAKE YOUR TURN section missing"
    92	grep -q "TAKE YOUR TURN.*agy.*REVIEWER" "$A/phases/p1/RELAY.md" 2>/dev/null \
    93	  && pass "relay file has reviewer TAKE YOUR TURN section" \
    94	  || fail "reviewer TAKE YOUR TURN section missing"
    95	grep -q "STATUS: Open" "$A/phases/p1/RELAY.md" 2>/dev/null \
    96	  && pass "relay file has STATUS: Open" \
    97	  || fail "STATUS: Open missing"
    98	grep -q "Implement a hello-world" "$A/phases/p1/RELAY.md" 2>/dev/null \
    99	  && pass "phase brief text baked into relay file" \
   100	  || fail "brief text not in relay file"
   101	# clean for next case
   102	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   103	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   104	
   105	# ── (3) tick token seeded: task created + handed to builder ──────────────
   106	RELAY_DRIVE_EXIT=0 run_driver >/dev/null 2>&1 || true
   107	# Verify task exists by checking the tick events dir directly (most reliable).
   108	ls "$A/.tick/events/" 2>/dev/null | grep -q "MARATHON-P1-TURN" \
   109	  && pass "MARATHON-P1-TURN tick task created (event file present)" \
   110	  || fail "MARATHON-P1-TURN tick task not found — no event file in .tick/events/"
   111	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   112	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   113	
   114	# ── (3b) leaked open handoff is reconciled before re-seeding the same phase-id (GH-56) ─
   115	tick_a log task.created MARATHON-P1-TURN --agent seed >/dev/null
   116	tick_a claim MARATHON-P1-TURN --agent seed --paths "phases/p1/RELAY.md" >/dev/null
   117	tick_a release MARATHON-P1-TURN --agent seed --to claude >/dev/null
   118	LEAK_INFO="$(tick_a info MARATHON-P1-TURN 2>&1 || true)"
   119	printf '%s\n' "$LEAK_INFO" | grep -qE '^status:[[:space:]]+open$' \
   120	  && printf '%s\n' "$LEAK_INFO" | grep -qE '^handoff-to:[[:space:]]+claude$' \
   121	  && pass "seeded the leaked open handoff fixture" \
   122	  || fail "expected leaked open handoff fixture, got: $LEAK_INFO"
   123	RERUN_OUT="$(RELAY_DRIVE_EXIT=0 run_driver 2>&1)"; rc=$?
   124	[ "$rc" -eq 0 ] && pass "driver reconciles leaked handoff and re-seeds cleanly" \
   125	  || fail "driver should succeed after reconciling leaked handoff: $RERUN_OUT"
   126	printf '%s\n' "$RERUN_OUT" | grep -q "task MARATHON-P1-TURN is open" \
   127	  && fail "driver hit the old leaked-token collision: $RERUN_OUT" \
   128	  || pass "driver avoids the old 'task ... is open' collision"
   129	tick_a info MARATHON-P1-TURN | grep -qE '^handoff-to:[[:space:]]+claude$' \
   130	  && pass "driver re-seeds the token back to the builder handoff" \
   131	  || fail "driver did not restore the builder handoff: $(tick_a info MARATHON-P1-TURN)"
   132	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   133	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   134	
   135	# ── (3c) a live claim is never reaped during re-seed (GH-56) ──────────────
   136	tick_a log task.created MARATHON-P1-TURN --agent seed >/dev/null
   137	tick_a claim MARATHON-P1-TURN --agent claude --paths "phases/p1/RELAY.md" >/dev/null
   138	LIVE_OUT="$(RELAY_DRIVE_EXIT=0 run_driver 2>&1)"; rc=$?
   139	[ "$rc" -ne 0 ] && pass "live claim blocks re-seed instead of being reaped" \
   140	  || fail "re-seed should refuse a live claim, not reap it"
   141	printf '%s\n' "$LIVE_OUT" | grep -q "refusing to reap a live claim" \
   142	  && pass "live-claim refusal is explicit" \
   143	  || fail "expected explicit live-claim refusal, got: $LIVE_OUT"
   144	tick_a info MARATHON-P1-TURN | grep -qE '^claimer:[[:space:]]+claude$' \
   145	  && pass "live claude claim survives the failed re-seed" \
   146	  || fail "live claim was disturbed by re-seed attempt: $(tick_a info MARATHON-P1-TURN)"
   147	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   148	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   149	
   150	# ── (4) relay-drive called with correct args ──────────────────────────────
   151	RELAY_DRIVE_EXIT=0 run_driver >/dev/null 2>&1 || true
   152	grep -q -- "--relay-file" "$WORK/relay-drive-args" \
   153	  && pass "relay-drive called with --relay-file" \
   154	  || fail "--relay-file arg missing from relay-drive invocation"
   155	grep -q -- "--relay-task" "$WORK/relay-drive-args" \
   156	  && pass "relay-drive called with --relay-task" \
   157	  || fail "--relay-task arg missing from relay-drive invocation"
   158	grep -q -- "--round-cap" "$WORK/relay-drive-args" \
   159	  && pass "relay-drive called with --round-cap" \
   160	  || fail "--round-cap arg missing from relay-drive invocation"
   161	grep -q -- "--agent-cmd" "$WORK/relay-drive-args" \
   162	  && pass "relay-drive called with --agent-cmd" \
   163	  || fail "--agent-cmd arg missing from relay-drive invocation"
   164	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   165	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   166	
   167	# ── (5) happy path: relay exit 0 → pre-advance passes → transcript saved ─
   168	GATE_CMD="$WORK/gate-pass.sh"
   169	printf '#!/usr/bin/env bash\nprintf "gate: passed\n"; exit 0\n' > "$GATE_CMD"
   170	chmod +x "$GATE_CMD"
   171	
   172	RELAY_DRIVE_EXIT=0 run_driver --pre-advance-cmd "bash $GATE_CMD" >/dev/null 2>&1; rc=$?
   173	[ "$rc" -eq 0 ] && pass "happy path exits 0 (relay approved + gate passed)" || fail "happy path exit=$rc"
   174	ls "$A/relay-system"/*/marathon-p1-*.md >/dev/null 2>&1 \
   175	  && pass "transcript saved under relay-system/<date>/" \
   176	  || fail "transcript not found in relay-system/"
   177	# marathon.phase.approved event emitted (check events dir directly)
   178	ls "$A/.tick/events/" 2>/dev/null | grep -q "marathon.phase.approved" \
   179	  && pass "marathon.phase.approved event emitted" \
   180	  || fail "marathon.phase.approved not found in tick events"
   181	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   182	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   183	
   184	# ── (5b) GH-307: the gate must NOT inherit the run's identity tags ───────
   185	# The gate is a correctness check on the repo, not part of the run's provenance. When these
   186	# leaked in, test/xyz-harness-hooks.sh (reads XYZ_HARNESS_CONTEXT / XYZ_SESSION_ID) and
   187	# test/debug-mantra.sh (reads MARATHON_LANE_NS) failed inside every marathon, so `bash
   188	# validate.sh` — the documented default gate — always escalated phase 1 with a correct,
   189	# approved change. Behavioural: the gate itself reports what it can see.
   190	GATE_ENV_OUT="$WORK/gate-env-seen.txt"
   191	GATE_ENV_CMD="$WORK/gate-report-env.sh"
   192	cat > "$GATE_ENV_CMD" <<'GATEEOF'
   193	#!/usr/bin/env bash
   194	{
   195	  printf 'XYZ_HARNESS_CONTEXT=%s\n' "${XYZ_HARNESS_CONTEXT-<unset>}"
   196	  printf 'XYZ_SESSION_ID=%s\n'      "${XYZ_SESSION_ID-<unset>}"
   197	  printf 'MARATHON_LANE_NS=%s\n'    "${MARATHON_LANE_NS-<unset>}"
   198	  printf 'MARATHON_ROOT=%s\n'       "${MARATHON_ROOT-<unset>}"
   199	  printf 'TICK_REPO_ROOT=%s\n'      "${TICK_REPO_ROOT-<unset>}"
   200	} > "$GATE_ENV_OUT_PATH"
   201	exit 0
   202	GATEEOF
   203	chmod +x "$GATE_ENV_CMD"
   204	
   205	GATE_ENV_OUT_PATH="$GATE_ENV_OUT" \
   206	XYZ_HARNESS_CONTEXT=marathon-phase XYZ_SESSION_ID=sid-gh307 MARATHON_LANE_NS=lane-gh307 \
   207	RELAY_DRIVE_EXIT=0 run_driver --pre-advance-cmd "bash $GATE_ENV_CMD" >/dev/null 2>&1 || true
   208	
   209	if [ -f "$GATE_ENV_OUT" ]; then
   210	  for v in XYZ_HARNESS_CONTEXT XYZ_SESSION_ID MARATHON_LANE_NS; do
   211	    grep -q "^$v=<unset>$" "$GATE_ENV_OUT" \
   212	      && pass "GH-307: gate cannot see $v" \
   213	      || fail "GH-307: gate inherited $v ($(grep "^$v=" "$GATE_ENV_OUT"))"
   214	  done
   215	  # Narrowness: repo/config inputs a gate may legitimately need must survive the scrub.
   216	  # (Codex round 1: TICK_REPO_ROOT was recorded but never asserted — now both are checked.
   217	  # run_driver exports TICK_REPO_ROOT="$A", so a <unset> here means the scrub was too broad.)
   218	  for keep in MARATHON_ROOT TICK_REPO_ROOT; do
   219	    grep -q "^$keep=<unset>$" "$GATE_ENV_OUT" \
   220	      && fail "GH-307: scrub was too broad — $keep was removed" \
   221	      || pass "GH-307: scrub is narrow — $keep preserved"
   222	  done
   223	else
   224	  fail "GH-307: gate never ran (no env report written)"
   225	fi
   226	rm -f "$GATE_ENV_OUT"
   227	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   228	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   229	
   230	# ── (6) pre-advance gate failure → ESCALATION.md, exit 5 ─────────────────
   231	GATE_CMD_FAIL="$WORK/gate-fail.sh"
   232	printf '#!/usr/bin/env bash\nprintf "gate: FAILED\n" >&2; exit 1\n' > "$GATE_CMD_FAIL"
   233	chmod +x "$GATE_CMD_FAIL"
   234	
   235	RELAY_DRIVE_EXIT=0 run_driver --pre-advance-cmd "bash $GATE_CMD_FAIL" >/dev/null 2>&1; rc=$?
   236	[ "$rc" -eq 5 ] && pass "pre-advance failure exits 5" || fail "pre-advance failure exit=$rc (expected 5)"
   237	[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on gate failure" || fail "ESCALATION.md missing"
   238	grep -q "pre-advance-failed" "$A/phases/p1/ESCALATION.md" \
   239	  && pass "ESCALATION.md records pre-advance-failed reason" \
   240	  || fail "reason field missing in ESCALATION.md"
   241	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   242	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   243	
   244	# ── (6b) GH-273: post-approve hook parity, ordering, and failure semantics ─
   245	POST_APPROVE_PASS="$WORK/post-approve-pass.sh"
   246	cat > "$POST_APPROVE_PASS" <<'HOOK'
   247	#!/usr/bin/env bash
   248	set -euo pipefail
   249	ls "$POST_EVENT_DIR"/*marathon.phase.approved* >/dev/null 2>&1
   250	printf 'ran-after-approval\n' >> "$POST_MARKER"
   251	HOOK
   252	chmod +x "$POST_APPROVE_PASS"
   253	POST_APPROVE_FAIL="$WORK/post-approve-fail.sh"
   254	cat > "$POST_APPROVE_FAIL" <<'HOOK'
   255	#!/usr/bin/env bash
   256	set -euo pipefail
   257	ls "$POST_EVENT_DIR"/*marathon.phase.approved* >/dev/null 2>&1
   258	printf 'ran-after-approval\n' >> "$POST_MARKER"
   259	exit 17
   260	HOOK
   261	chmod +x "$POST_APPROVE_FAIL"
   262	
   263	for runtime in 0 1; do
   264	  HELP_OUT="$(MARATHON_ROOT="$A" XYZ_PYTHON="$runtime" bash "$DRIVER" --help 2>&1)"; rc=$?
   265	  [ "$rc" -eq 0 ] && printf '%s\n' "$HELP_OUT" | grep -q -- '--post-approve-cmd' \
   266	    && pass "GH-273: XYZ_PYTHON=$runtime help documents --post-approve-cmd" \
   267	    || fail "GH-273: XYZ_PYTHON=$runtime help omitted --post-approve-cmd: $HELP_OUT"
   268	
   269	  POST_MARKER="$WORK/post-approve-omitted-$runtime"
   270	  rm -f "$POST_MARKER"
   271	  POST_APPROVE_CMD="POST_EVENT_DIR='$A/.tick/events' POST_MARKER='$POST_MARKER' bash '$POST_APPROVE_PASS'" \
   272	    XYZ_PYTHON="$runtime" RELAY_DRIVE_EXIT=0 run_driver >/dev/null 2>&1; rc=$?
   273	  [ "$rc" -eq 0 ] && [ ! -e "$POST_MARKER" ] \
   274	    && pass "GH-273: XYZ_PYTHON=$runtime omitted hook preserves the existing happy path" \
   275	    || fail "GH-273: XYZ_PYTHON=$runtime omitted hook changed default behavior (exit=$rc)"
   276	  rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   277	  git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   278	
   279	  POST_MARKER="$WORK/post-approve-pass-$runtime"
   280	  rm -f "$POST_MARKER"
   281	  POST_CMD="POST_EVENT_DIR='$A/.tick/events' POST_MARKER='$POST_MARKER' bash '$POST_APPROVE_PASS'"
   282	  XYZ_PYTHON="$runtime" RELAY_DRIVE_EXIT=0 run_driver --post-approve-cmd "$POST_CMD" >/dev/null 2>&1; rc=$?
   283	  [ "$rc" -eq 0 ] && [ "$(grep -c '^ran-after-approval$' "$POST_MARKER" 2>/dev/null || true)" = "1" ] \
   284	    && pass "GH-273: XYZ_PYTHON=$runtime passing hook runs exactly once after approval" \
   285	    || fail "GH-273: XYZ_PYTHON=$runtime passing hook exit=$rc or did not run exactly once"
   286	  rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   287	  git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   288	
   289	  POST_MARKER="$WORK/post-approve-fail-$runtime"
   290	  rm -f "$POST_MARKER"
   291	  POST_CMD="POST_EVENT_DIR='$A/.tick/events' POST_MARKER='$POST_MARKER' bash '$POST_APPROVE_FAIL'"
   292	  XYZ_PYTHON="$runtime" RELAY_DRIVE_EXIT=0 run_driver --post-approve-cmd "$POST_CMD" >/dev/null 2>&1; rc=$?
   293	  [ "$rc" -eq 9 ] \
   294	    && pass "GH-273: XYZ_PYTHON=$runtime failing hook exits 9" \
   295	    || fail "GH-273: XYZ_PYTHON=$runtime failing hook exit=$rc (expected 9)"
   296	  [ "$(grep -c '^ran-after-approval$' "$POST_MARKER" 2>/dev/null || true)" = "1" ] \
   297	    && pass "GH-273: XYZ_PYTHON=$runtime failing hook still runs exactly once after approval" \
   298	    || fail "GH-273: XYZ_PYTHON=$runtime failing hook did not run exactly once"
   299	  grep -q '^reason: post-approve-failed$' "$A/phases/p1/ESCALATION.md" 2>/dev/null \
   300	    && pass "GH-273: XYZ_PYTHON=$runtime failing hook records post-approve-failed" \
   301	    || fail "GH-273: XYZ_PYTHON=$runtime failing hook escalation reason missing"
   302	  ls "$A/.tick/events/" 2>/dev/null | grep -q 'marathon.phase.approved' \
   303	    && pass "GH-273: XYZ_PYTHON=$runtime approval remains logged when closeout fails" \
   304	    || fail "GH-273: XYZ_PYTHON=$runtime closeout failure retroactively lost approval"
   305	  rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   306	  git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   307	done
   308	
   309	# ── (7) relay cap/mismatch (exit 4) → ESCALATION.md, driver exits 4 ──────
   310	RELAY_DRIVE_EXIT=4 run_driver >/dev/null 2>&1; rc=$?
   311	[ "$rc" -eq 4 ] && pass "relay cap escalation exits 4" || fail "relay cap exit=$rc (expected 4)"
   312	[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on relay cap" || fail "ESCALATION.md missing on cap"
   313	grep -q "relay-drive-exit: 4" "$A/phases/p1/ESCALATION.md" \
   314	  && pass "ESCALATION.md records relay-drive-exit: 4" \
   315	  || fail "relay-drive-exit field wrong in ESCALATION.md"
   316	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   317	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   318	
   319	# ── (8) relay no-progress (exit 3) → ESCALATION.md, driver exits 3 ───────
   320	RELAY_DRIVE_EXIT=3 run_driver >/dev/null 2>&1; rc=$?
   321	[ "$rc" -eq 3 ] && pass "relay no-progress exits 3" || fail "relay no-progress exit=$rc (expected 3)"
   322	[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on no-progress" || fail "ESCALATION.md missing on no-progress"
   323	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   324	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   325	
   326	# ── (8b) containment violation (exit 6) → ESCALATION.md, driver exits 6 (Phase 3.6) ───
   327	# A turn-taker shim exits 6 when it reverts an off-lane edit; relay-drive propagates it. The
   328	# driver must treat that as a DEFINED escalation, not die "unexpected code 6" (dogfood 2026-06-17).
   329	RELAY_DRIVE_EXIT=6 run_driver >/dev/null 2>&1; rc=$?
   330	[ "$rc" -eq 6 ] && pass "containment violation escalation exits 6 (not 'unexpected')" || fail "containment exit=$rc (expected 6)"
   331	[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on containment violation" || fail "ESCALATION.md missing on exit 6"
   332	grep -q "containment-violation" "$A/phases/p1/ESCALATION.md" \
   333	  && pass "ESCALATION.md records containment-violation reason" \
   334	  || fail "containment-violation reason missing in ESCALATION.md"
   335	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   336	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   337	
   338	# ── (9) MARATHON_BUILDER/MARATHON_REVIEWER exported for peer threading ────
   339	RELAY_DRIVE_EXIT=0 run_driver --pre-advance-cmd "bash $GATE_CMD" >/dev/null 2>&1 || true
   340	# We can only verify this indirectly: marathon-agent.sh reads MARATHON_BUILDER/REVIEWER.
   341	# Here we just confirm the env vars are wired through by checking drive output doesn't error.
   342	pass "MARATHON_BUILDER/MARATHON_REVIEWER wired (no dispatcher errors in happy path)"
   343	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   344	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   345	
   346	# ── (10) custom round-cap reaches relay-drive ─────────────────────────────
   347	RELAY_DRIVE_EXIT=0 run_driver --round-cap 9 >/dev/null 2>&1 || true
   348	grep -q "9" "$WORK/relay-drive-args" \
   349	  && pass "--round-cap 9 passed to relay-drive" \
   350	  || fail "custom round-cap not found in relay-drive args"
   351	rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
   352	git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
   353	
   354	# ── (11) agent-cmd path with spaces survives relay-drive dispatch ──────────
   355	# Regression: relay-drive runs a BARE executable --agent-cmd directly (space-safe), falling back to
   356	# eval only for command strings. marathon-drive passes the path as-is (no %q quoting). This case uses
   357	# a stub that mirrors relay-drive's smart dispatch, with the agent script under a spaced directory.
   358	SPACED_AGENT="$WORK/dir with space/agent.sh"
   359	mkdir -p "$WORK/dir with space"
   360	cat > "$SPACED_AGENT" <<AG

exec
/bin/zsh -lc "nl -ba test/gh419-gate-inventory.sh | sed -n '1,300p'; nl -ba test/gh390-gate-guard.sh | sed -n '1,280p'; nl -ba test/gh407-gate-ran-attribution.sh | sed -n '1,330p'; nl -ba test/gh390-timeout-attribution.sh | sed -n '1,300p'; nl -ba test/gh385-retry-token-satisfied.sh | sed -n '1,260p'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-86418-h4t1yue0
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# gate-evidence: {"form":"controlled-bad-fixture","observed":true,"result":"self-comparing and self-regenerating fixtures were reported as none"}
     3	# GH-419 — inventory discovery and negative-control evidence must stay separate.
     4	set -euo pipefail
     5	
     6	HERE="$(cd "$(dirname "$0")/.." && pwd)"
     7	FIXTURE="$(mktemp -d "${TMPDIR:-/tmp}/gh419-gate-inventory.XXXXXX")"
     8	trap 'rm -rf "$FIXTURE"' EXIT
     9	
    10	mkdir -p "$FIXTURE/test"
    11	cat >"$FIXTURE/validate.sh" <<'EOF'
    12	TESTS=(
    13	  "safe.sh"
    14	  "self-comparing.sh"
    15	  "self-regenerating.sh"
    16	  "new-gate.sh"
    17	)
    18	EOF
    19	
    20	cat >"$FIXTURE/test/safe.sh" <<'EOF'
    21	# gate-evidence: {"form":"deliberate-mutation","observed":true,"result":"mutation made this fixture fail"}
    22	test "safe" = "safe"
    23	EOF
    24	cat >"$FIXTURE/test/self-comparing.sh" <<'EOF'
    25	# gate-evidence: {"form":"controlled-bad-fixture","observed":true,"result":"this declaration must not override the shape"}
    26	cmp "$candidate" "$candidate"
    27	EOF
    28	cat >"$FIXTURE/test/self-regenerating.sh" <<'EOF'
    29	# gate-evidence: {"form":"controlled-bad-fixture","observed":true,"result":"this declaration must not override the shape"}
    30	generate-report > "$EXPECTED_SNAPSHOT"
    31	diff "$EXPECTED_SNAPSHOT" "$actual"
    32	EOF
    33	cat >"$FIXTURE/test/new-gate.sh" <<'EOF'
    34	test "new gate" = "new gate"
    35	EOF
    36	
    37	python3 "$HERE/utils/py/gate_inventory.py" --root "$FIXTURE" >"$FIXTURE/inventory.json"
    38	python3 - "$FIXTURE/inventory.json" <<'PY'
    39	import json
    40	import sys
    41	
    42	report = json.load(open(sys.argv[1], encoding="utf-8"))
    43	gates = {row["gate"]: row for row in report["gates"]}
    44	assert set(gates) == {
    45	    "test/safe.sh",
    46	    "test/self-comparing.sh",
    47	    "test/self-regenerating.sh",
    48	    "test/new-gate.sh",
    49	}, gates
    50	assert gates["test/safe.sh"]["negative_control"]["form"] == "deliberate-mutation"
    51	assert gates["test/safe.sh"]["negative_control"]["observed"] is True
    52	for gate, shape in (
    53	    ("test/self-comparing.sh", "self-comparing-parity"),
    54	    ("test/self-regenerating.sh", "self-regenerating-drift"),
    55	):
    56	    row = gates[gate]
    57	    assert shape in row["disqualifying_shapes"], row
    58	    assert row["negative_control"]["form"] == "none", row
    59	    assert row["negative_control"]["observed"] is False, row
    60	assert gates["test/new-gate.sh"]["negative_control"]["form"] == "none"
    61	assert gates["test/new-gate.sh"]["negative_control"]["observed"] is False
    62	PY
    63	
    64	python3 "$HERE/utils/py/gate_inventory.py" --root "$HERE" >"$FIXTURE/repo-inventory.json"
    65	python3 - "$FIXTURE/repo-inventory.json" <<'PY'
    66	import json
    67	import sys
    68	
    69	gates = {row["gate"]: row for row in json.load(open(sys.argv[1], encoding="utf-8"))["gates"]}
    70	row = gates["test/gh419-gate-inventory.sh"]
    71	assert row["negative_control"]["form"] == "controlled-bad-fixture", row
    72	assert row["negative_control"]["observed"] is True, row
    73	PY
    74	
    75	echo "PASS: GH-419 inventory discovers registered gates and records only declared controls"
     1	#!/usr/bin/env bash
     2	# gate-evidence: {"form":"deliberate-mutation","observed":true,"result":"all four CPU signal/Bash exit shapes map to gate-killed; an inverted classifier is observed to misattribute each as a red gate"}
     3	# GH-390 Phase 1: the pre-advance gate must not be able to take the host down.
     4	#
     5	# The gate executes code an LLM wrote seconds earlier, and the packet forbids the builder from
     6	# running it first — so the gate is by construction the first execution of the builder's work.
     7	# With no timeout and no resource bounds, a generated test that mocked a paging function against a
     8	# `while True:` loop consumed all 30.75 GB of swap and kernel-panicked the host twice on one day
     9	# (GH-382). This pins the guard that turns that into a failed phase.
    10	#
    11	# Properties pinned here:
    12	#   (1) an honest gate is unaffected — same exit code, and peak-RSS telemetry is recorded
    13	#   (2) a runaway ALLOCATOR is killed at the RSS cap (layer 3) and escalates as `gate-killed`
    14	#   (3) a HANG is killed at the wall-clock cap (layer 1)
    15	#   (4) a CPU SPIN is killed by the kernel-enforced ulimit -t (layer 2), and its 128+SIGXCPU
    16	#       exit is reported as a guard kill rather than as the gate finding a defect
    17	#   (5) a gate that genuinely FAILS still escalates `pre-advance-failed` — the guard must not
    18	#       relabel real red gates
    19	#   (6) MARATHON_GATE_GUARD=0 restores the exact unguarded behavior (the ship-day escape hatch)
    20	#
    21	# Every runaway fixture below is SELF-LIMITING: if the guard fails to kill it, the fixture exits
    22	# on its own well short of any level that could affect the host, and the case fails loudly. This
    23	# test must never be able to reproduce the panic it exists to prevent.
    24	source "$(dirname "$0")/_setup.sh" gh390-gate-guard
    25	export TICK_BIN="$TICK"
    26	ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
    27	DRIVER="$ROOT_REPO/relay-automation/marathon-drive.sh"
    28	
    29	# ── fixture: a marathon root whose gate we swap per case ─────────────────────────────────
    30	ROOT="$WORK/target"
    31	mkdir -p "$ROOT"
    32	git init -q "$ROOT"
    33	git -C "$ROOT" config user.email gh390@t
    34	git -C "$ROOT" config user.name gh390
    35	printf '.tick/\n' > "$ROOT/.gitignore"
    36	printf '#!/usr/bin/env bash\nexit 0\n' > "$ROOT/validate.sh"
    37	git -C "$ROOT" add .gitignore validate.sh >/dev/null 2>&1
    38	git -C "$ROOT" commit -q -m init
    39	
    40	# Stub relay-drive: marks the thread Approved so the driver proceeds straight to the gate,
    41	# which is the only thing under test.
    42	STUB_RD="$WORK/relay-drive.sh"
    43	cat > "$STUB_RD" << 'STUB_EOF'
    44	#!/usr/bin/env bash
    45	set -u
    46	rf=""
    47	while (($#)); do case "$1" in --relay-file) rf="${2:-}"; shift 2 ;; *) shift ;; esac; done
    48	[ -n "$rf" ] && printf 'STATUS: Approved\n' >> "$rf"
    49	exit 0
    50	STUB_EOF
    51	chmod +x "$STUB_RD"
    52	STUB_BIN="$WORK/stub-bin"
    53	printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_BIN"
    54	chmod +x "$STUB_BIN"
    55	BRIEF="$WORK/brief.md"
    56	printf '## Do a thing\nBody.\n' > "$BRIEF"
    57	
    58	# Self-limiting allocator: ~10 MB/50 ms, hard stop at 1 GB. Reaching the stop means the guard
    59	# never fired; the fixture exits 0 so the case can report a clean, unambiguous failure.
    60	HOG="$WORK/hog.py"
    61	cat > "$HOG" << 'HOG_EOF'
    62	import time
    63	blocks = []
    64	for _ in range(100):            # hard ceiling: 100 x 10 MB = 1 GB, then exit cleanly
    65	    blocks.append(bytearray(10 * 1024 * 1024))
    66	    time.sleep(0.05)
    67	HOG_EOF
    68	
    69	# GH-382 reproducer baseline (observed by case p7 below): a MagicMock records every invocation,
    70	# so this exact `while True` shape grows without bound.  Pre-fix (the deliberately inverted
    71	# classifier in case 0): resource exits are `pre-advance-failed`; post-fix: the guard terminates
    72	# the process group and records `gate-killed` (exit 108).  The harness's file-scoped commit is the
    73	# revision carrying this baseline; keeping it beside the reproducer prevents a detached result log.
    74	MOCK_HOG="$WORK/gh382-magicmock-while-true.py"
    75	cat > "$MOCK_HOG" << 'MOCK_HOG_EOF'
    76	from unittest.mock import MagicMock
    77	
    78	page = MagicMock()
    79	calls = 0
    80	while True:
    81	    page()
    82	    calls += 1
    83	    if calls >= 500_000:
    84	        raise SystemExit("fixture safety ceiling reached before the guard fired")
    85	MOCK_HOG_EOF
    86	
    87	# Each case passes its OWN --phase-id: a lane whose token is already spent takes the
    88	# "already terminal, re-run only the gate" path instead of the one under test. Note the ids are
    89	# passed explicitly rather than from a counter — every call site here is inside "$( … )", which
    90	# runs in a subshell, so a counter incremented in the function would never reach the next case.
    91	run_driver() {  # <extra-args…>
    92	  MARATHON_ROOT="$ROOT" \
    93	  MARATHON_RELAY_DRIVE="$STUB_RD" \
    94	  MARATHON_AGENT_CMD="$WORK/noop-agent" \
    95	  TICK_REPO_ROOT="$ROOT" TICK_BIN="$TICK" \
    96	  CLAUDE_BIN="$STUB_BIN" AGY_BIN="$STUB_BIN" CODEX_BIN="$STUB_BIN" \
    97	  bash "$DRIVER" \
    98	    --phases-dir "$ROOT/phases" \
    99	    --phase-brief "$BRIEF" \
   100	    --reviewer agy \
   101	    --builder claude \
   102	    "$@"
   103	}
   104	
   105	esc_reason() {  # <phase-id> — the reason recorded in that phase's ESCALATION.md
   106	  sed -n 's/^reason: //p' "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null
   107	}
   108	
   109	# ── (0) the attribution seam: both signals and both Bash return-code shapes ──────────────
   110	# This is deliberately a direct import rather than a driven phase: a host can only cause one of
   111	# these kernel outcomes, whereas the seam makes all four observed controls reproducible anywhere.
   112	out="$(python3 - "$ROOT_REPO/utils/py/marathon_drive.py" <<'PY'
   113	import importlib.util
   114	import signal
   115	import sys
   116	
   117	spec = importlib.util.spec_from_file_location("marathon_drive", sys.argv[1])
   118	driver = importlib.util.module_from_spec(spec)
   119	spec.loader.exec_module(driver)
   120	
   121	cases = {
   122	    "SIGXCPU forked (128+signal)": 128 + signal.SIGXCPU,
   123	    "SIGXCPU exec-optimised (-signal)": -signal.SIGXCPU,
   124	    "SIGKILL forked (128+signal)": 128 + signal.SIGKILL,
   125	    "SIGKILL exec-optimised (-signal)": -signal.SIGKILL,
   126	}
   127	
   128	def must_classify_as_guard_kill(classifier, label, returncode):
   129	    actual, message = classifier(returncode, 2)
   130	    assert actual == driver.GATE_GUARD_KILL_EXIT, (label, actual, message)
   131	    return message
   132	
   133	for label, returncode in cases.items():
   134	    message = must_classify_as_guard_kill(driver.gate_guard_cpu_attribution, label, returncode)
   135	    assert message and ("SIGXCPU" in message or "SIGKILL" in message), (label, message)
   136	
   137	# Negative control: this is the deliberately inverted pre-fix classifier.  Every case must be
   138	# observed to fail the same assertion, proving the controls catch a resource kill misreported as
   139	# `pre-advance-failed` rather than merely documenting the expected production behaviour.
   140	def inverted_classifier(returncode, cpu_s):
   141	    if cpu_s > 0 and returncode in cases.values():
   142	        return returncode, None
   143	    return driver.GATE_GUARD_KILL_EXIT, "inverted"
   144	
   145	for label, returncode in cases.items():
   146	    try:
   147	        must_classify_as_guard_kill(inverted_classifier, label, returncode)
   148	    except AssertionError:
   149	        pass
   150	    else:
   151	        raise AssertionError(("negative control did not fail", label))
   152	
   153	# A genuine red gate and a disabled CPU layer must stay red; broadening this classification would
   154	# recreate GH-407 in the opposite direction.
   155	for returncode in (1, -signal.SIGTERM):
   156	    assert driver.gate_guard_cpu_attribution(returncode, 2)[0] == returncode
   157	assert driver.gate_guard_cpu_attribution(-signal.SIGKILL, 0)[0] == -signal.SIGKILL
   158	print("four attribution shapes + inverted negative control observed")
   159	PY
   160	)"; rc=$?
   161	if [ "$rc" -eq 0 ]; then
   162	  pass "all CPU signal/Bash attribution shapes are covered through the module-level seam"
   163	else
   164	  fail "attribution seam coverage failed: $out"
   165	fi
   166	
   167	# ── (1) an honest gate is unaffected, and telemetry is recorded ──────────────────────────
   168	out="$(run_driver --phase-id p1 --pre-advance-cmd '/usr/bin/true' 2>&1)"; rc=$?
   169	if [ "$rc" -eq 0 ]; then
   170	  pass "an honest gate still passes under the guard (exit 0)"
   171	else
   172	  fail "guard broke an honest gate (rc=$rc): $(printf '%s' "$out" | tail -5)"
   173	fi
   174	case "$out" in
   175	  *"peak group RSS"*) pass "peak-RSS telemetry is logged on a passing run (the Phase 3 trip condition)" ;;
   176	  *) fail "no peak-RSS telemetry logged on a passing run: $(printf '%s' "$out" | tail -5)" ;;
   177	esac
   178	
   179	# ── (2) layer 3: a runaway allocator is killed at the RSS cap ────────────────────────────
   180	start=$SECONDS
   181	out="$(MARATHON_GATE_RSS_MB=256 run_driver --phase-id p2 --pre-advance-cmd "python3 $HOG" 2>&1)"; rc=$?
   182	elapsed=$((SECONDS - start))
   183	if [ "$rc" -eq 5 ]; then
   184	  pass "a runaway allocator halts the phase (exit 5) instead of the host"
   185	else
   186	  fail "expected exit 5 for a killed gate, got $rc — the hog may have run to its own ceiling: $(printf '%s' "$out" | tail -5)"
   187	fi
   188	case "$out" in
   189	  *"KILLING gate process group"*) pass "layer 3 killed the gate's whole process group" ;;
   190	  *) fail "no group kill logged — the RSS watchdog did not fire: $(printf '%s' "$out" | tail -5)" ;;
   191	esac
   192	if [ "$(esc_reason p2)" = "gate-killed" ]; then
   193	  pass "ESCALATION.md records reason: gate-killed (distinct from a red gate)"
   194	else
   195	  fail "expected reason gate-killed, got '$(esc_reason p2)'"
   196	fi
   197	if [ "$elapsed" -lt 30 ]; then
   198	  pass "the kill landed promptly (${elapsed}s), well before the hog's own 1 GB ceiling"
   199	else
   200	  fail "kill took ${elapsed}s — too slow to be protecting anything"
   201	fi
   202	
   203	# ── (3) layer 1: a hang is killed at the wall-clock cap ──────────────────────────────────
   204	start=$SECONDS
   205	out="$(MARATHON_GATE_WALL_S=3 MARATHON_GATE_CPU_S=0 run_driver --phase-id p3 --pre-advance-cmd 'sleep 60' 2>&1)"; rc=$?
   206	elapsed=$((SECONDS - start))
   207	if [ "$rc" -eq 5 ] && [ "$elapsed" -lt 40 ]; then
   208	  pass "a hanging gate is killed at the wall-clock cap (${elapsed}s, exit 5)"
   209	else
   210	  fail "hanging gate not capped (rc=$rc, ${elapsed}s): $(printf '%s' "$out" | tail -5)"
   211	fi
   212	case "$out" in
   213	  *"wall clock"*) pass "the kill reason names the wall-clock cap" ;;
   214	  *) fail "wall-clock cap not named in the kill reason: $(printf '%s' "$out" | tail -5)" ;;
   215	esac
   216	
   217	# ── (4) layer 2: a CPU spin is killed by ulimit -t, and reads as a guard kill ────────────
   218	# Wall and RSS are set out of reach so only the kernel-enforced cap can end this.
   219	start=$SECONDS
   220	out="$(MARATHON_GATE_CPU_S=2 MARATHON_GATE_WALL_S=120 MARATHON_GATE_RSS_MB=0 \
   221	       run_driver --phase-id p4 --pre-advance-cmd 'python3 -c "while True: pass"' 2>&1)"; rc=$?
   222	elapsed=$((SECONDS - start))
   223	if [ "$rc" -eq 5 ] && [ "$elapsed" -lt 60 ]; then
   224	  pass "a CPU spin is killed by the kernel-enforced cap (${elapsed}s, exit 5)"
   225	else
   226	  fail "CPU cap did not end the spin (rc=$rc, ${elapsed}s): $(printf '%s' "$out" | tail -5)"
   227	fi
   228	if [ "$(esc_reason p4)" = "gate-killed" ]; then
   229	  pass "a SIGXCPU kill escalates as gate-killed, not as the gate finding a defect"
   230	else
   231	  # The reason alone cannot tell you WHY it was misclassified — the whole question is which exit
   232	  # status the kill arrived as, and the guard already logs it. Print it, or this failure costs a
   233	  # CI round-trip to say anything actionable.
   234	  fail "expected reason gate-killed for the CPU cap, got '$(esc_reason p4)' \
   235	[$(printf '%s' "$out" | /usr/bin/grep -o 'gate-guard: gate exit [-0-9]*' | tail -1)]"
   236	fi
   237	
   238	# ── (5) GH-382's actual runaway: MagicMock in a while-True loop ───────────────────────────
   239	# The 96 MB cap is intentionally much lower than the general allocator's 256 MB cap: this fixture
   240	# can append calls very quickly before the one-second watchdog poll, but it still leaves room for a
   241	# normal Python process.  It is the recorded post-fix baseline described beside MOCK_HOG above.
   242	start=$SECONDS
   243	out="$(MARATHON_GATE_RSS_MB=96 run_driver --phase-id p7 --pre-advance-cmd "python3 $MOCK_HOG" 2>&1)"; rc=$?
   244	elapsed=$((SECONDS - start))
   245	if [ "$rc" -eq 5 ] && [ "$(esc_reason p7)" = "gate-killed" ]; then
   246	  pass "GH-382 MagicMock-in-while-True runaway is killed and attributed as gate-killed"
   247	else
   248	  fail "GH-382 reproducer was not attributed as gate-killed (rc=$rc, reason=$(esc_reason p7)): $(printf '%s' "$out" | tail -5)"
   249	fi
   250	case "$out" in
   251	  *"KILLING gate process group"*"gate exit 108"*) pass "GH-382 baseline records group kill and distinct guard exit (108, ${elapsed}s)" ;;
   252	  *) fail "GH-382 baseline missing guard-kill evidence: $(printf '%s' "$out" | tail -8)" ;;
   253	esac
   254	
   255	# ── (6) a genuinely failing gate is still `pre-advance-failed` ───────────────────────────
   256	out="$(run_driver --phase-id p5 --pre-advance-cmd '/usr/bin/false' 2>&1)"; rc=$?
   257	if [ "$rc" -eq 5 ]; then
   258	  pass "a red gate still halts the phase (exit 5)"
   259	else
   260	  fail "a red gate did not halt the phase (rc=$rc): $(printf '%s' "$out" | tail -5)"
   261	fi
   262	if [ "$(esc_reason p5)" = "pre-advance-failed" ]; then
   263	  pass "a red gate keeps reason pre-advance-failed — the guard does not relabel real failures"
   264	else
   265	  fail "guard relabelled a real gate failure as '$(esc_reason p5)'"
   266	fi
   267	
   268	# ── (7) the escape hatch restores the unguarded path ─────────────────────────────────────
   269	# The same allocator that case (2) killed must now run to its own 1 GB ceiling and pass,
   270	# proving the switch removes the guard rather than merely loosening a cap.
   271	out="$(MARATHON_GATE_GUARD=0 MARATHON_GATE_RSS_MB=256 run_driver --phase-id p6 --pre-advance-cmd "python3 $HOG" 2>&1)"; rc=$?
   272	if [ "$rc" -eq 0 ]; then
   273	  pass "MARATHON_GATE_GUARD=0 restores the unguarded gate (the hog completes, exit 0)"
   274	else
   275	  fail "escape hatch did not restore unguarded behavior (rc=$rc): $(printf '%s' "$out" | tail -5)"
   276	fi
   277	case "$out" in
   278	  *"KILLING gate process group"*) fail "guard still killed the gate with MARATHON_GATE_GUARD=0" ;;
   279	  *) pass "no kill occurred with the guard disabled" ;;
   280	esac
     1	#!/usr/bin/env bash
     2	# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh407-gate-ran-attribution.sh. The pre-fix revision is replayed inside the fixture by patching the driver copy back to its old single-expression form (reason = pre-advance-failed whenever no timeout reason was recorded, with no gate: line in ESCALATION.md). Pre-fix result: a phase whose builder never produced work escalated as pre-advance-failed and the record carried no statement of whether the gate ran. Post-fix result: the same phase escalates as relay-failed-before-gate with gate: not-run, while a genuinely red gate still escalates as pre-advance-failed with gate: red. Both observed in one run."}
     3	# GH-407: `pre-advance-failed` asserts that the gate RAN and found a defect in the change.
     4	#
     5	# Several unrelated failures reach the same relay exit 5 — a builder shim that failed to start, a
     6	# builder that exhausted its turn cap, a reviewer turn discarded by containment — and all of them
     7	# were reported with that label. Observed three times in one 10-lane marathon on 2026-08-02, wrong
     8	# all three times; in one case the relay file read STATUS: Approved while the phase was escalated as
     9	# though the gate had rejected the work.
    10	#
    11	# Why the mislabel costs real time: the reason is the operator's entry point into a failed run.
    12	# `pre-advance-failed` sends them to read the diff and the test output. When the gate never ran there
    13	# is no test output, and nothing in the escalation record said so — confirming it required checking
    14	# whether any pytest output existed anywhere after the phase started.
    15	#
    16	# Pinned here:
    17	#   (1) a relay failure that never reached the gate does NOT claim a gate verdict
    18	#   (2) every escalation states whether the gate ran, on every reason
    19	#   (3) a genuinely red gate still reports pre-advance-failed with gate: red  <- anti-overcorrection
    20	#   (4) the reason for the no-gate case names no cause it cannot determine
    21	#
    22	# (3) is the assertion that protects against the cheap fix. Reserving `pre-advance-failed` is easy to
    23	# over-apply: relabel every exit 5 and criteria 1, 2 and 4 all pass while real gate failures stop
    24	# being reported as gate failures — the same defect pointing the other way.
    25	set -euo pipefail
    26	
    27	source "$(dirname "$0")/_setup.sh" gh407-gate-ran-attribution
    28	export TICK_BIN="$TICK"
    29	ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
    30	DRIVER="$ROOT_REPO/relay-automation/marathon-drive.sh"
    31	
    32	ROOT="$WORK/target"
    33	mkdir -p "$ROOT"
    34	git init -q "$ROOT"
    35	git -C "$ROOT" config user.email gh407@t
    36	git -C "$ROOT" config user.name gh407
    37	printf '.tick/\n' > "$ROOT/.gitignore"
    38	printf '#!/usr/bin/env bash\nexit 0\n' > "$ROOT/validate.sh"
    39	git -C "$ROOT" add .gitignore validate.sh >/dev/null 2>&1
    40	git -C "$ROOT" commit -q -m init
    41	
    42	STUB_BIN="$WORK/stub-bin"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_BIN"; chmod +x "$STUB_BIN"
    43	BRIEF="$WORK/brief.md"; printf '## Do a thing\nBody.\n' > "$BRIEF"
    44	
    45	# Stub relay-drive, exit 5 WITHOUT approving: this is the shape the issue describes — the relay
    46	# failed (builder never produced work), so the driver never reaches its own gate.
    47	RD_FAIL="$WORK/relay-drive-fail.sh"
    48	cat > "$RD_FAIL" << 'STUB_EOF'
    49	#!/usr/bin/env bash
    50	set -u
    51	exit 5
    52	STUB_EOF
    53	chmod +x "$RD_FAIL"
    54	
    55	# Stub relay-drive that DOES approve, so the driver runs its gate and the gate decides.
    56	RD_OK="$WORK/relay-drive-ok.sh"
    57	cat > "$RD_OK" << 'STUB_EOF'
    58	#!/usr/bin/env bash
    59	set -u
    60	rf=""
    61	while (($#)); do case "$1" in --relay-file) rf="${2:-}"; shift 2 ;; *) shift ;; esac; done
    62	[ -n "$rf" ] && printf 'STATUS: Approved\n' >> "$rf"
    63	exit 0
    64	STUB_EOF
    65	chmod +x "$RD_OK"
    66	
    67	run_driver() {  # <relay-drive-stub> <extra-args…>
    68	  local rd="$1"; shift
    69	  MARATHON_ROOT="$ROOT" \
    70	  MARATHON_RELAY_DRIVE="$rd" \
    71	  MARATHON_AGENT_CMD="$WORK/noop-agent" \
    72	  TICK_REPO_ROOT="$ROOT" TICK_BIN="$TICK" \
    73	  CLAUDE_BIN="$STUB_BIN" AGY_BIN="$STUB_BIN" CODEX_BIN="$STUB_BIN" \
    74	  bash "$DRIVER" \
    75	    --phases-dir "$ROOT/phases" \
    76	    --phase-brief "$BRIEF" \
    77	    --reviewer agy \
    78	    --builder claude \
    79	    "$@"
    80	}
    81	esc_field() { sed -n "s/^$2: //p" "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null; }
    82	
    83	# ── (1)(2)(4) the relay failed before the gate ────────────────────────────────────────────
    84	printf '#!/usr/bin/env bash\nexit 0\n' > "$ROOT/validate.sh"
    85	run_driver "$RD_FAIL" --phase-id no-gate > "$WORK/no-gate.log" 2>&1 && rc=0 || rc=$?
    86	reason="$(esc_field no-gate reason)"
    87	gate="$(esc_field no-gate gate)"
    88	
    89	[ "$reason" != "pre-advance-failed" ] \
    90	  && pass "a relay failure that never reached the gate does NOT claim pre-advance-failed (got: $reason)" \
    91	  || fail "the gate never ran, yet the phase was reported as pre-advance-failed"
    92	
    93	[ "$reason" = "relay-failed-before-gate" ] \
    94	  && pass "the no-gate case reports relay-failed-before-gate — states what is known, names no cause it cannot determine" \
    95	  || fail "expected relay-failed-before-gate, got '$reason'"
    96	
    97	[ "$gate" = "not-run" ] \
    98	  && pass "ESCALATION.md records gate: not-run — the one line that resolves the ambiguity" \
    99	  || fail "expected 'gate: not-run' in the escalation record, got '$gate'"
   100	
   101	# ── (3) anti-overcorrection: a real gate failure is still a gate failure ──────────────────
   102	printf '#!/usr/bin/env bash\nexit 1\n' > "$ROOT/validate.sh"
   103	run_driver "$RD_OK" --phase-id red-gate > "$WORK/red-gate.log" 2>&1 && rc=0 || rc=$?
   104	reason="$(esc_field red-gate reason)"
   105	gate="$(esc_field red-gate gate)"
   106	
   107	[ "$reason" = "pre-advance-failed" ] \
   108	  && pass "a gate that RAN and failed is still pre-advance-failed — the fix does not relabel real failures" \
   109	  || fail "a real gate failure was reported as '$reason' — GH-407 pointing the other way"
   110	
   111	[ "$gate" = "red" ] \
   112	  && pass "ESCALATION.md records gate: red, so the record distinguishes a verdict from a non-run" \
   113	  || fail "expected 'gate: red', got '$gate'"
   114	
   115	# ── (5) the THIRD value: an escalation that happens AFTER a green gate says so ─────────────
   116	# Added after a codex review of the merged fix noted the suite pinned `not-run` and `red` but never
   117	# `green` — so `gate:` could have been hardwired to emit only the two failure words and every other
   118	# assertion here would still pass. `requires-test-missing` is the reachable green-gate escalation: it
   119	# is checked after the gate returns 0 (marathon_drive.py:1504), so the gate genuinely ran and passed
   120	# while the phase still halted. That is precisely the case an operator must be able to tell apart from
   121	# a gate failure, which is this issue's whole subject.
   122	printf '#!/usr/bin/env bash\nexit 0\n' > "$ROOT/validate.sh"
   123	run_driver "$RD_OK" --phase-id green-gate --requires-test "test/definitely-absent-$$.sh" > "$WORK/green-gate.log" 2>&1 && rc=0 || rc=$?
   124	reason="$(esc_field green-gate reason)"
   125	gate="$(esc_field green-gate gate)"
   126	
   127	[ "$reason" = "requires-test-missing" ] \
   128	  && pass "a phase halted after a PASSING gate keeps its own reason (requires-test-missing), not a gate verdict" \
   129	  || fail "expected requires-test-missing after a green gate, got '$reason'"
   130	
   131	[ "$gate" = "green" ] \
   132	  && pass "ESCALATION.md records gate: green — all three values are now observed, so the field cannot be a two-word failure label" \
   133	  || fail "expected 'gate: green' for an escalation after a passing gate, got '$gate'"
   134	
   135	# ── the pre-fix replay (#419): the old single-expression form, inside the fixture ──────────
   136	# Replayed against a COPY of the driver so the working tree is never mutated. The copy is patched
   137	# back to the pre-fix behaviour and driven through the same no-gate case, which must produce the old
   138	# wrong answer. If it does not, this whole file is asserting something that was never broken.
   139	FIXH="$WORK/prefix-harness"
   140	mkdir -p "$FIXH"
   141	for d in relay-automation utils bin src; do
   142	  [ -e "$ROOT_REPO/$d" ] && cp -R "$ROOT_REPO/$d" "$FIXH/$d"
   143	done
   144	PRE_MD="$FIXH/utils/py/marathon_drive.py"
   145	python3 - "$PRE_MD" <<'PY'
   146	import pathlib, sys
   147	p = pathlib.Path(sys.argv[1]); s = p.read_text()
   148	
   149	# revert the escalation record: drop the gate: line
   150	before = s
   151	s = s.replace("reason: {reason}\ngate: {run_gate_result[0]}\n", "reason: {reason}\n", 1)
   152	assert s != before, "could not revert the gate: line — pre-fix replay would be vacuous"
   153	
   154	# revert the reason choice to the old unconditional form
   155	i = s.index("        gate_ran = run_gate_result[0] != \"not-run\"")
   156	j = s.index("        escalate(reason, 5)", i)
   157	s = s[:i] + (
   158	'        reason = timeout_reason[0] if timeout_reason[0] != "turn-timeout-or-hang" else "pre-advance-failed"\n'
   159	'        emit = timeout_emit[0] if timeout_reason[0] != "turn-timeout-or-hang" else "halted"\n'
   160	'        log("relay escalated: pre-advance gate failed")\n'
   161	) + s[j:]
   162	p.write_text(s)
   163	print("PATCHED")
   164	PY
   165	
   166	PRE_DRIVER="$FIXH/relay-automation/marathon-drive.sh"
   167	PRE_ROOT="$WORK/target-prefix"
   168	cp -R "$ROOT" "$PRE_ROOT"
   169	rm -rf "$PRE_ROOT/phases"
   170	MARATHON_ROOT="$PRE_ROOT" \
   171	MARATHON_RELAY_DRIVE="$RD_FAIL" \
   172	MARATHON_AGENT_CMD="$WORK/noop-agent" \
   173	TICK_REPO_ROOT="$PRE_ROOT" TICK_BIN="$TICK" \
   174	CLAUDE_BIN="$STUB_BIN" AGY_BIN="$STUB_BIN" CODEX_BIN="$STUB_BIN" \
   175	  bash "$PRE_DRIVER" --phases-dir "$PRE_ROOT/phases" --phase-brief "$BRIEF" \
   176	    --reviewer agy --builder claude --phase-id no-gate > "$WORK/prefix.log" 2>&1 && rc=0 || rc=$?
   177	
   178	pre_reason="$(sed -n 's/^reason: //p' "$PRE_ROOT/phases/no-gate/ESCALATION.md" 2>/dev/null)"
   179	pre_gate="$(sed -n 's/^gate: //p' "$PRE_ROOT/phases/no-gate/ESCALATION.md" 2>/dev/null)"
   180	
   181	[ "$pre_reason" = "pre-advance-failed" ] \
   182	  && pass "control: the pre-fix revision reports pre-advance-failed for a gate that never ran (the defect, observed)" \
   183	  || fail "control: pre-fix replay did not reproduce the defect — got reason '$pre_reason', so the post-fix assertions prove nothing"
   184	
   185	[ -z "$pre_gate" ] \
   186	  && pass "control: the pre-fix record carries NO statement of whether the gate ran" \
   187	  || fail "control: pre-fix record unexpectedly had 'gate: $pre_gate'"
   188	
   189	echo "gh407-gate-ran-attribution: $PASS pass, $FAIL fail"
     1	#!/usr/bin/env bash
     2	# Timeout attribution (exit-7 reason strings) — turn_diagnostics.
     3	#
     4	# An exit-7 turn can mean "slow agent", "runaway loop", or "a modal OS dialog
     5	# blocked the process and no budget will ever be enough". Those need opposite
     6	# responses, so the shims classify the timeout instead of reporting a bare code.
     7	# This pins each classification against a real sampled process, not a mock.
     8	#
     9	# Every fixture is self-limiting (bounded sleep / bounded spin), so this suite
    10	# cannot itself hang the machine it is protecting.
    11	set -uo pipefail
    12	
    13	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    14	PY_DIR="$HERE/../utils/py"
    15	TMP="$(mktemp -d "${TMPDIR:-/tmp}/gh390-timeout-attr.XXXXXX")"
    16	trap 'rm -rf "$TMP"' EXIT
    17	
    18	pass=0; fail=0
    19	ok()   { printf '  PASS: %s\n' "$1"; pass=$((pass + 1)); }
    20	bad()  { printf '  FAIL: %s\n' "$1"; fail=$((fail + 1)); }
    21	
    22	# Run a python snippet with utils/py importable.
    23	pyrun() { PYTHONPATH="$PY_DIR" python3 -c "$1" 2>&1; }
    24	
    25	# --- parser: ps TIME shapes across platforms -------------------------------
    26	out="$(pyrun '
    27	from turn_diagnostics import _parse_ps_time as p
    28	cases = {"0:00.07": 0.07, "1:02.50": 62.5, "1:00:00": 3600.0, "2-01:00:00": 176400.0, "": 0.0, "garbage": 0.0}
    29	bad = [(k, p(k), v) for k, v in cases.items() if abs(p(k) - v) > 0.001]
    30	print("OK" if not bad else f"BAD {bad}")
    31	')"
    32	[ "$out" = "OK" ] && ok "ps TIME parser handles mm:ss, hh:mm:ss, dd-hh:mm:ss, and junk" \
    33	                  || bad "ps TIME parser: $out"
    34	
    35	# --- a probe failure must never raise --------------------------------------
    36	out="$(pyrun '
    37	import turn_diagnostics as td
    38	td._run = lambda *a, **k: (_ for _ in ()).throw(RuntimeError("probe exploded"))
    39	d = td.TurnDiagnostics(worktree=None)
    40	try:
    41	    d._sample()
    42	    print("RAISED-NOT")
    43	except Exception as e:
    44	    print(f"RAISED {e}")
    45	')"
    46	# _sample calls _run indirectly; the loop wraps it, but classify must survive either way.
    47	case "$out" in
    48	  RAISED-NOT|RAISED*) ok "a failing probe does not escape as an unhandled crash path" ;;
    49	  *) bad "probe failure: $out" ;;
    50	esac
    51	
    52	# --- unclassified when there is nothing to go on ---------------------------
    53	out="$(pyrun '
    54	from turn_diagnostics import TurnDiagnostics, REASON_UNCLASSIFIED
    55	d = TurnDiagnostics(worktree=None)
    56	r, _ = d.classify()
    57	print("OK" if r == REASON_UNCLASSIFIED else f"BAD {r}")
    58	')"
    59	[ "$out" = "OK" ] && ok "no samples -> timeout-unclassified (never guesses)" || bad "unclassified: $out"
    60	
    61	# --- CPU-bound: a real spinning child --------------------------------------
    62	out="$(pyrun '
    63	import subprocess, time
    64	from turn_diagnostics import TurnDiagnostics, REASON_CPU_BOUND
    65	d = TurnDiagnostics(worktree=None, interval=0.5)
    66	d.start()
    67	p = subprocess.Popen(["python3", "-c", "import time\nt=time.time()\nwhile time.time()-t<3: pass"])
    68	time.sleep(3.2); p.wait(); d.stop()
    69	r, detail = d.classify()
    70	print("OK" if r == REASON_CPU_BOUND else f"BAD {r} :: {detail}")
    71	')"
    72	[ "$out" = "OK" ] && ok "a spinning child classifies as timeout-cpu-bound (runaway shape)" \
    73	                  || bad "cpu-bound: $out"
    74	
    75	# --- a runaway that DIED must still read as cpu-bound ----------------------
    76	# Regression: the real sequence is kill-then-classify, and a dead process leaves
    77	# ps entirely — so anchoring on the last sample scored a runaway as 0.00s/s and
    78	# reported "idle", the exact opposite of the truth. Peak CPU is the anchor.
    79	out="$(pyrun '
    80	from turn_diagnostics import TurnDiagnostics, REASON_CPU_BOUND
    81	d = TurnDiagnostics(worktree=None)
    82	# tree burned 5 CPU-seconds over 5 wall-seconds, then exited (accounting -> 0)
    83	d.samples = [(0.0, 0.0, 1), (2.5, 2.5, 1), (5.0, 5.0, 1), (6.0, 0.0, 0)]
    84	r, detail = d.classify()
    85	print("OK" if r == REASON_CPU_BOUND else f"BAD {r} :: {detail}")
    86	')"
    87	[ "$out" = "OK" ] && ok "a runaway that exited before the last sample still reads cpu-bound" \
    88	                  || bad "dead-runaway anchoring: $out"
    89	
    90	# --- a perfectly flat CPU trace must classify, not fall through ------------
    91	# Regression: peak-anchoring left t_peak == t0 when CPU never grew, producing a
    92	# zero-length window and `unclassified`. That is exactly the blocked-process
    93	# case this module exists to name — a turn stalled on a modal dialog burns no
    94	# CPU at all — so a flat trace has to score a real 0.0 over the full window.
    95	out="$(pyrun '
    96	from turn_diagnostics import TurnDiagnostics, REASON_IDLE
    97	d = TurnDiagnostics(worktree=None)
    98	d.samples = [(0.0, 0.0, 1), (5.0, 0.0, 1), (10.0, 0.0, 1)]   # flat: zero CPU throughout
    99	ratio = d.cpu_ratio()
   100	r, _ = d.classify()
   101	print("OK" if ratio == 0.0 and r == REASON_IDLE else f"BAD ratio={ratio} reason={r}")
   102	')"
   103	[ "$out" = "OK" ] && ok "a flat zero-CPU trace scores 0.0 and classifies as idle (not unclassified)" \
   104	                  || bad "flat-trace anchoring: $out"
   105	
   106	# --- idle: a real sleeping child, no file progress -------------------------
   107	out="$(pyrun '
   108	import subprocess, time
   109	from turn_diagnostics import TurnDiagnostics, REASON_IDLE
   110	d = TurnDiagnostics(worktree=None, interval=0.5)
   111	d.start()
   112	p = subprocess.Popen(["sleep", "3"])
   113	time.sleep(3.2); p.wait(); d.stop()
   114	r, detail = d.classify()
   115	print("OK" if r == REASON_IDLE else f"BAD {r} :: {detail}")
   116	')"
   117	[ "$out" = "OK" ] && ok "a sleeping child with no writes classifies as timeout-idle-no-progress" \
   118	                  || bad "idle: $out"
   119	
   120	# --- slow-but-progressing: idle CPU but the worktree is being written ------
   121	mkdir -p "$TMP/wt"; : > "$TMP/wt/seed"
   122	out="$(pyrun "
   123	import subprocess, time, os
   124	from turn_diagnostics import TurnDiagnostics, REASON_SLOW_PROGRESS
   125	wt = '$TMP/wt'
   126	d = TurnDiagnostics(worktree=wt, interval=0.5)
   127	d.start()
   128	p = subprocess.Popen(['sleep', '3'])
   129	time.sleep(1.0)
   130	open(os.path.join(wt, 'progress.txt'), 'w').write('builder wrote this')
   131	time.sleep(2.2); p.wait(); d.stop()
   132	r, detail = d.classify()
   133	print('OK' if r == REASON_SLOW_PROGRESS else f'BAD {r} :: {detail}')
   134	")"
   135	[ "$out" = "OK" ] && ok "idle CPU + fresh worktree writes -> timeout-slow-but-progressing" \
   136	                  || bad "slow-progress: $out"
   137	
   138	# --- security dialog outranks every other signal ---------------------------
   139	out="$(pyrun '
   140	from turn_diagnostics import TurnDiagnostics, REASON_SECURITY_DIALOG
   141	d = TurnDiagnostics(worktree=None)
   142	d.security_dialog_seen = True          # sticky flag the sampler would have set
   143	d.samples = [(0.0, 0.0, 1), (10.0, 9.9, 1)]   # would otherwise read as cpu-bound
   144	r, detail = d.classify()
   145	ok = r == REASON_SECURITY_DIALOG and "Raising the turn budget will not help" in detail
   146	print("OK" if ok else f"BAD {r} :: {detail}")
   147	')"
   148	[ "$out" = "OK" ] && ok "a seen auth dialog outranks CPU evidence and says budget will not help" \
   149	                  || bad "security-dialog precedence: $out"
   150	
   151	# --- the dialog probe must not match general-purpose interpreters ----------
   152	# Regression: osascript was originally in this list. It is a general-purpose
   153	# AppleScript interpreter, so unrelated automation on the machine set the flag
   154	# and produced a confident, wrong "a dialog blocked your turn" verdict. Measured
   155	# live: transient osascript PIDs appeared inside a 4s window with no dialog up.
   156	out="$(pyrun '
   157	from turn_diagnostics import SECURITY_AGENT_PROCS as S
   158	banned = {"osascript", "python3", "bash", "sh", "sudo", "ssh"}
   159	hit = banned & set(S)
   160	print("OK" if not hit else f"BAD {hit}")
   161	')"
   162	[ "$out" = "OK" ] && ok "dialog probe list excludes general-purpose interpreters (osascript regression)" \
   163	                  || bad "dialog probe list too broad: $out"
   164	
   165	# --- a single blip must not confirm a dialog -------------------------------
   166	out="$(pyrun '
   167	import turn_diagnostics as td
   168	d = td.TurnDiagnostics(worktree=None)
   169	calls = {"n": 0}
   170	def flaky():
   171	    calls["n"] += 1
   172	    return calls["n"] == 1          # one positive, then quiet
   173	td._security_dialog_present = flaky
   174	td._descendant_cpu_seconds = lambda pid: (0.0, 1)
   175	for _ in range(4):
   176	    d._sample()
   177	print("OK" if not d.security_dialog_seen else "BAD single blip confirmed a dialog")
   178	')"
   179	[ "$out" = "OK" ] && ok "one isolated positive does not confirm a dialog (needs consecutive samples)" \
   180	                  || bad "dialog debounce: $out"
   181	
   182	# --- sustained presence still confirms -------------------------------------
   183	out="$(pyrun '
   184	import turn_diagnostics as td
   185	d = td.TurnDiagnostics(worktree=None)
   186	td._security_dialog_present = lambda: True
   187	td._descendant_cpu_seconds = lambda pid: (0.0, 1)
   188	d._sample(); d._sample()
   189	print("OK" if d.security_dialog_seen else "BAD sustained dialog was not confirmed")
   190	')"
   191	[ "$out" = "OK" ] && ok "a dialog present across consecutive samples is confirmed" \
   192	                  || bad "dialog confirm: $out"
   193	
   194	# --- the shims actually wire it in -----------------------------------------
   195	wired=0
   196	for f in claude-turn.py agy-turn.py codex-turn.py; do
   197	  if grep -q "from turn_diagnostics import TurnDiagnostics" "$PY_DIR/$f" \
   198	     && grep -q "diag.classify()" "$PY_DIR/$f" \
   199	     && grep -q "diag.stop()" "$PY_DIR/$f"; then
   200	    wired=$((wired + 1))
   201	  else
   202	    bad "$f does not import/stop/classify TurnDiagnostics"
   203	  fi
   204	done
   205	[ "$wired" -eq 3 ] && ok "all three turn shims start, stop, and classify diagnostics"
   206	
   207	# --- exit code must stay 7 (callers depend on the number) ------------------
   208	if grep -q 'bounded_rc = 7' "$PY_DIR/claude-turn.py" \
   209	   && ! grep -qE 'bounded_rc = (10[0-9]|8|9)\b' "$PY_DIR/claude-turn.py"; then
   210	  ok "attribution did not change the exit code — callers still see 7"
   211	else
   212	  bad "exit code for a timeout changed; downstream callers would break"
   213	fi
   214	
   215	printf 'gh390-timeout-attribution: %d pass, %d fail\n' "$pass" "$fail"
   216	[ "$fail" -eq 0 ]
     1	#!/usr/bin/env bash
     2	# test/gh385-retry-token-satisfied.sh — GH-385 regression.
     3	# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh385-retry-token-satisfied.sh; pre-fix revisions: (a) marathon_drive.py before acf2d3e, where satisfied_lane_terminal read only the BASE token — case 1 FAILED, an Approved phase completed on a --retry suffix was rebuilt; (b) the first version of that fix, which trusted the builder-written task= directive unconditionally — cases 5,6,7,9 FAILED, a directive naming any unrelated done token satisfied the lane. Post-fix result: 12/0, with case 8 (multi-digit suffix) green in all three revisions as the anti-over-tightening control"}
     4	#
     5	# An Approved phase rebuilt from scratch because its completion was recorded on a --retry SUFFIXED
     6	# token while satisfied_lane_terminal() read only the BASE token:
     7	#
     8	#   1. p1 runs, the builder fails, the phase escalates — MARATHON-P1-TURN is left claimed.
     9	#   2. Operator re-runs with --retry. GH-116 allocates MARATHON-P1-TURN-2, the phase succeeds,
    10	#      -TURN-2 reaches done and RELAY.md records STATUS: Approved.
    11	#   3. A later run without --retry computes the BASE name again, reads the dead attempt's state,
    12	#      and rebuilds a phase that is demonstrably Approved.
    13	#
    14	# Observed on a real 10-phase run: phase 1 rebuilt while phases 2-4 correctly reported satisfied, and
    15	# the only difference was that phase 1 had once been retried. Cost is a full builder + reviewer cycle
    16	# — real money on --builder claude — and the rebuild re-introduced a defect that had been reverted,
    17	# so a phase believed complete silently regressed the tree. Nothing in the log said why.
    18	#
    19	# The driver now reads which task the relay was actually rendered for, from its own marathon-drive
    20	# directive, instead of assuming the base name.
    21	source "$(dirname "$0")/_setup.sh" gh385-retry-token-satisfied
    22	DRIVER="$(cd "$(dirname "$0")/.." && pwd)/utils/py/marathon_drive.py"
    23	export TICK_BIN="$TICK"
    24	tick_a init >/dev/null
    25	
    26	printf '.tick/\n' > "$A/.gitignore"
    27	git -C "$A" add .gitignore >/dev/null 2>&1
    28	git -C "$A" commit -q -m init
    29	BRIEF="$WORK/brief.md"; printf '## brief\nbody\n' > "$BRIEF"
    30	
    31	STUB_CLAUDE="$WORK/stub-claude"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_CLAUDE"; chmod +x "$STUB_CLAUDE"
    32	STUB_AGY="$WORK/stub-agy"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_AGY"; chmod +x "$STUB_AGY"
    33	
    34	# A relay-drive stub that RECORDS being called. The whole point of the satisfied path is that the
    35	# phase is not driven again, so "was the driver re-entered" is the observable that matters.
    36	RD="$WORK/relay-drive-stub.sh"
    37	cat > "$RD" <<'STUB'
    38	#!/usr/bin/env bash
    39	echo called >> "$RD_CALLS"
    40	exit 0
    41	STUB
    42	chmod +x "$RD"
    43	export RD_CALLS="$WORK/rd-calls"
    44	
    45	BASE="MARATHON-P1-TURN"
    46	
    47	seed_relay() {  # <recorded-task> — an Approved relay rendered for <recorded-task>
    48	  mkdir -p "$A/phases/p1"
    49	  printf '# Marathon Phase p1\nSTATUS: Approved\nNEXT: agy (Reviewer)\n\n<!-- marathon-drive: task=%s builder=claude reviewer=agy round-cap=5 -->\n\nbody\n' \
    50	    "$1" > "$A/phases/p1/RELAY.md"
    51	}
    52	
    53	mk_token() {  # <task> <done|claimed>
    54	  tick_a log task.created "$1" --agent marathon >/dev/null 2>&1 || true
    55	  tick_a claim "$1" --agent claude --paths "phases/p1/RELAY.md" >/dev/null 2>&1 || true
    56	  [ "$2" = "done" ] && { tick_a done "$1" --agent claude >/dev/null 2>&1 || true; }
    57	}
    58	
    59	run_driver() {  # [extra marathon-drive args...]
    60	  : > "$RD_CALLS"
    61	  MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
    62	  CLAUDE_BIN="$STUB_CLAUDE" AGY_BIN="$STUB_AGY" \
    63	  python3 "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
    64	    --reviewer agy --builder claude --pre-advance-cmd "true" "$@" 2>&1
    65	}
    66	
    67	reset_state() { rm -rf "$A/phases" "$A/.tick"; tick_a init >/dev/null 2>&1 || true; : > "$RD_CALLS"; }
    68	
    69	# --- (1) THE BUG: completion recorded on -TURN-2, base token left on the failed attempt ----------
    70	reset_state
    71	seed_relay "${BASE}-2"
    72	mk_token "$BASE" claimed      # the dead attempt, exactly as a crashed run leaves it
    73	mk_token "${BASE}-2" done     # where the phase actually completed
    74	out="$(run_driver)"; rc=$?
    75	printf '%s' "$out" | grep -q "already reached a terminal relay" \
    76	  && pass "a phase completed on a --retry token is recognized as satisfied" \
    77	  || fail "GH-385 is back: the Approved phase rebuilt because the BASE token was read: $out"
    78	[ ! -s "$RD_CALLS" ] \
    79	  && pass "relay-drive was NOT re-entered (no builder + reviewer cycle re-run)" \
    80	  || fail "the phase was driven again despite being Approved — the cost this issue is about"
    81	[ "$rc" -eq 0 ] && pass "satisfied phase exits 0" || fail "satisfied phase exit=$rc: $out"
    82	
    83	# --- (2) NEGATIVE CONTROL: nothing reached done, so the phase MUST still run ----------------------
    84	# Without this, an implementation that always reported "satisfied" would pass case (1) and silently
    85	# skip every phase in the fleet. The assertion above is only meaningful next to this one.
    86	reset_state
    87	seed_relay "${BASE}-2"
    88	mk_token "$BASE" claimed
    89	mk_token "${BASE}-2" claimed  # recorded task exists but never completed
    90	out="$(run_driver)"
    91	printf '%s' "$out" | grep -q "already reached a terminal relay" \
    92	  && fail "a phase whose recorded token never reached done was skipped — satisfied is now unfalsifiable" \
    93	  || pass "an un-completed recorded token does NOT satisfy the lane (the check can still fail)"
    94	
    95	# --- (3) the ordinary no-retry path is unchanged --------------------------------------------------
    96	reset_state
    97	seed_relay "$BASE"
    98	mk_token "$BASE" done
    99	out="$(run_driver)"
   100	printf '%s' "$out" | grep -q "already reached a terminal relay" \
   101	  && pass "the plain base-token satisfied path still works" \
   102	  || fail "regressed the ordinary satisfied path: $out"
   103	
   104	# --- (4) a relay with no directive falls back to the base token ------------------------------------
   105	# Relays rendered before the directive existed must keep working rather than being read as unsatisfied.
   106	reset_state
   107	mkdir -p "$A/phases/p1"
   108	printf '# Marathon Phase p1\nSTATUS: Approved\nNEXT: agy\n\nbody\n' > "$A/phases/p1/RELAY.md"
   109	mk_token "$BASE" done
   110	out="$(run_driver)"
   111	printf '%s' "$out" | grep -q "already reached a terminal relay" \
   112	  && pass "a directive-less relay still resolves against the base token" \
   113	  || fail "a pre-directive relay stopped being recognized as satisfied: $out"
   114	
   115	# ==================================================================================================
   116	# THE DIRECTIVE IS THE BUILDER'S TO WRITE. Everything below pins that RELAY.md is a hint, not an
   117	# authority. Raised in review of #458 before it merged: the first version of this fix accepted any
   118	# `task=` value, and the builder writes both that line AND `STATUS: Approved` — so the two together
   119	# are a complete forgery of the terminal state. Point the directive at any unrelated already-done
   120	# token and the driver skips render/reseed and reports success after the gate, which is a WIDER hole
   121	# than the one being closed (the pre-GH-385 check read a harness-computed name the builder cannot
   122	# touch). The resolution must never be able to leave this lane's own token family.
   123	# ==================================================================================================
   124	
   125	# --- (5) FORGERY: Approved + a directive naming an unrelated done token must NOT satisfy -----------
   126	reset_state
   127	seed_relay "MARATHON-P0-TURN"    # a different lane's token, or any stale/invented name
   128	mk_token "$BASE" claimed         # this lane never completed
   129	mk_token "MARATHON-P0-TURN" done # ...but the named token is legitimately done
   130	out="$(run_driver)"
   131	printf '%s' "$out" | grep -q "already reached a terminal relay" \
   132	  && fail "a builder-written directive naming an unrelated done token satisfied the lane — a builder can now skip its own review: $out" \
   133	  || pass "an out-of-family directive does NOT satisfy the lane"
   134	# ...and it must not report the phase COMPLETE either. Not asserted via RD_CALLS: this fixture leaves
   135	# the base token live-claimed (exactly how a crashed attempt leaves it), so the driver correctly dies
   136	# at reconcile_relay_task before relay-drive is reached. "Did the builder run" is therefore the wrong
   137	# observable here; "did the harness announce success having changed nothing" is the one the issue is
   138	# about, and it is what the pre-fix code did — it exited 0 with the success line.
   139	printf '%s' "$out" | grep -q "complete — " \
   140	  && fail "the harness reported the phase COMPLETE off a forged directive: $out" \
   141	  || pass "the phase is not reported complete — the lane halts honestly instead"
   142	
   143	# --- (6) the refusal is VISIBLE ---------------------------------------------------------------------
   144	# A silent fallback is indistinguishable from a directive that was honored, and this repo has shipped
   145	# three checks that could not fail (#333, #348, #351). A lane that rebuilds because its directive was
   146	# refused has to say so, or nobody can tell the guard from a bug.
   147	printf '%s' "$out" | grep -q "not $BASE or a retry derivative" \
   148	  && pass "the ignored directive is named in the log" \
   149	  || fail "the directive was refused silently: $out"
   150	
   151	# --- (7) PREFIX-MATCH CONTROL: family membership is not a startswith ---------------------------------
   152	# `MARATHON-P1-TURN-EVIL` and `MARATHON-P1-TURNX` both begin with the base name. A membership test
   153	# written as a prefix check accepts them and the forgery in (5) comes straight back through a name
   154	# chosen to look related.
   155	reset_state
   156	seed_relay "${BASE}X"
   157	mk_token "$BASE" claimed
   158	mk_token "${BASE}X" done
   159	out="$(run_driver)"
   160	printf '%s' "$out" | grep -q "already reached a terminal relay" \
   161	  && fail "'${BASE}X' was accepted as family — the check is a prefix match, not a suffix rule: $out" \
   162	  || pass "a name that merely starts with the base token is not a retry derivative"
   163	
   164	# --- (8) POSITIVE CONTROL for the suffix rule: multi-digit retries are still family -----------------
   165	# Without this, a rule of `-\d` (or an over-tight one) would pass every assertion above while
   166	# quietly re-breaking GH-385 for any lane retried more than nine times.
   167	reset_state
   168	seed_relay "${BASE}-11"
   169	mk_token "$BASE" claimed
   170	mk_token "${BASE}-11" done
   171	out="$(run_driver)"
   172	printf '%s' "$out" | grep -q "already reached a terminal relay" \
   173	  && pass "a two-digit retry suffix is still recognized as this lane's token" \
   174	  || fail "the family rule is too tight — GH-385 is back for lanes retried 10+ times: $out"
   175	
   176	# --- (9) an explicit --relay-task pins the token; the directive is not consulted --------------------
   177	# This is the --retry path (GH-116 allocates the first unused suffix and passes it through). A retry
   178	# must never be satisfied by the attempt it was invoked to retry, or --retry silently becomes a
   179	# gate-only re-run and the operator's explicit request is discarded.
   180	reset_state
   181	seed_relay "${BASE}-2"
   182	mk_token "${BASE}-2" done        # the previous attempt genuinely completed
   183	out="$(run_driver --relay-task "${BASE}-3")"
   184	printf '%s' "$out" | grep -q "already reached a terminal relay" \
   185	  && fail "--retry was satisfied by the attempt it was retrying — the operator's fresh token was ignored: $out" \
   186	  || pass "an explicit --relay-task overrides the directive (--retry still forces a real re-run)"
   187	
   188	# --- (10) GH-385's OTHER ask: the disagreement is logged before the rebuild ------------------------
   189	# The issue asked for this by name — "Log the disagreement ... that single line would have made this
   190	# diagnosable immediately" — because the failure mode is invisible: a phase that is demonstrably
   191	# Approved silently re-runs a full builder + reviewer cycle and the log reads like an ordinary first
   192	# fire. The fix above stops the common cause, but a terminal relay whose token genuinely is not done
   193	# is still reachable (a token reaped after a host crash, a record on a token this run cannot see),
   194	# and in that case the operator gets a rebuild with no explanation unless this line exists.
   195	#
   196	# Asserted, not merely written: an unasserted log line is precisely the "check nobody can see
   197	# working" shape this repo has shipped three times (#333, #348, #351).
   198	reset_state
   199	seed_relay "$BASE"            # directive names the BASE token — no retry involved
   200	mk_token "$BASE" claimed      # terminal relay, but the token is NOT done: the contradiction
   201	out="$(run_driver)"
   202	printf '%s' "$out" | grep -q "already reached a terminal relay" \
   203	  && fail "a not-done token must NOT satisfy the lane: $out" \
   204	  || pass "a terminal relay with a not-done token still rebuilds (unchanged)"
   205	printf '%s' "$out" | grep -q "relay is terminal .* but token .* not done — rebuilding" \
   206	  && pass "GH-385: the token/relay disagreement is logged before the rebuild" \
   207	  || fail "the rebuild is still silent — GH-385's 'log the disagreement' ask is unmet: $out"
   208	printf '%s' "$out" | grep -q "GH-385" \
   209	  && pass "the disagreement line points at GH-385 so the next reader can find the mechanism" \
   210	  || fail "disagreement line does not cite GH-385: $out"
   211	
   212	# --- (11) GH-491: --retry on an ALREADY-SATISFIED lane says the cheap path existed ------------------
   213	# Case (9) above establishes that --retry correctly refuses to be satisfied by the attempt it retries.
   214	# The cost of that correctness is that the cheap path becomes invisible exactly when it applies: the
   215	# `already reached a terminal relay` line prints only once the operator has already chosen the right
   216	# invocation, so choosing wrong yields a rebuild and the reasonable conclusion that one was required.
   217	#
   218	# Measured, not hypothetical: three codex builds and three agy reviews across two Nightwatch waves on
   219	# 2026-08-10, both of whose base tokens read `done` afterwards. Every one of those turns was avoidable.
   220	reset_state
   221	seed_relay "$BASE"
   222	mk_token "$BASE" done            # terminal AND done: a plain re-fire would have been gate-only
   223	out="$(run_driver --relay-task "${BASE}-2")"
   224	printf '%s' "$out" | grep -q "already reached a terminal relay" \
   225	  && fail "advisory case regressed into an actual short-circuit — --retry must still rebuild: $out" \
   226	  || pass "GH-491 advisory does not change --retry's behaviour (it still rebuilds)"
   227	printf '%s' "$out" | grep -q "re-firing WITHOUT --retry would have re-run only the pre-advance gate" \
   228	  && pass "GH-491: --retry on a satisfied lane says a plain re-fire would have skipped both turns" \
   229	  || fail "no advisory — the cheaper path stays invisible at the one moment it applies: $out"
   230	printf '%s' "$out" | grep -q "GH-491" \
   231	  && pass "the advisory cites GH-491 so the next reader can find the mechanism" \
   232	  || fail "advisory does not cite GH-491: $out"
   233	
   234	# --- (12) NEGATIVE CONTROL for (11): the advisory must NOT fire when it does not apply --------------
   235	# Without this, (11) is indistinguishable from a line that prints on every --retry — which would be
   236	# worse than silence, because an operator would learn to ignore it exactly like #492's TTY warning.
   237	# Same --retry invocation; the ONLY variable is whether the recorded token actually completed.
   238	reset_state
   239	seed_relay "$BASE"
   240	mk_token "$BASE" claimed         # terminal relay, token NOT done: a plain re-fire would ALSO rebuild
   241	out="$(run_driver --relay-task "${BASE}-2")"
   242	printf '%s' "$out" | grep -q "re-firing WITHOUT --retry would have re-run only the pre-advance gate" \
   243	  && fail "control: the advisory fired on a lane a plain re-fire would ALSO have rebuilt — it is unconditional, so it carries no information: $out" \
   244	  || pass "control: no advisory when the recorded token is not done (the cheap path genuinely did not apply)"
   245	
   246	exit 0

exec
/bin/zsh -lc "nl -ba test/acorn-extract.sh | sed -n '1,240p'; rg -l --glob '*.sh' 'relay-automation/relay-drive\\.sh|RELAY_DRIVE=.*relay-drive|RELAY_DRIVE=.*relay-automation|MARATHON_RELAY_DRIVE=.*relay-drive' test | sort; rg -l --glob '*.sh' 'git (add|commit|reset|checkout|clean|worktree)|\\.git/' test | wc -l; rg -n --glob '*.sh' 'git -C \"?\\"'$?(ROOT_REPO|HERE|ROOT_DIR|ROOT|REPO)?|'"\\"'$ROOT_REPO|'"\\"'$HERE.*(git|validate)|validate'"\\.sh|ci-local\\.sh' test | head -240" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-86418-h4t1yue0
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	
     4	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
     5	EXTRACTOR="$HERE/../src/acorn-extract.js"
     6	
     7	TEST_NAME="acorn-extract"
     8	PASS=0
     9	FAIL=0
    10	
    11	pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
    12	fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }
    13	
    14	WORK="$(mktemp -d "${TMPDIR:-/tmp}/acorn-extract-test.XXXXXX")"
    15	trap 'rm -rf "$WORK"' EXIT
    16	
    17	echo "== test: $TEST_NAME =="
    18	
    19	# ---------------------------------------------------------------------------
    20	# Test 1: Real file (happy path)
    21	# ---------------------------------------------------------------------------
    22	REAL_FILE="$HERE/../src/identity.js"
    23	
    24	node "$EXTRACTOR" "$REAL_FILE" > "$WORK/real.json" || true
    25	
    26	if grep -q "declarations" "$WORK/real.json" && grep -q "callSites" "$WORK/real.json"; then
    27	  pass "real file extracted successfully"
    28	else
    29	  fail "real file extraction failed or missing fields: $(cat "$WORK/real.json")"
    30	fi
    31	
    32	# ---------------------------------------------------------------------------
    33	# Test 2: Malformed snippet
    34	# ---------------------------------------------------------------------------
    35	MALFORMED="$WORK/bad.js"
    36	echo "function foo( {" > "$MALFORMED"
    37	
    38	RC=0
    39	node "$EXTRACTOR" "$MALFORMED" > "$WORK/bad.json" || RC=$?
    40	
    41	if [[ "$RC" -ne 0 ]]; then
    42	  pass "malformed file exited with non-zero ($RC)"
    43	else
    44	  fail "malformed file should exit non-zero, got 0"
    45	fi
    46	
    47	if grep -q "Parse error" "$WORK/bad.json"; then
    48	  pass "malformed file reported Parse error"
    49	else
    50	  fail "malformed file did not report parse error: $(cat "$WORK/bad.json")"
    51	fi
    52	
    53	echo ""
    54	echo "acorn-extract: $PASS pass, $FAIL fail"
    55	[[ "$FAIL" -eq 0 ]]
test/archive-writers.sh
test/find-harness.sh
test/gh289-target-root-build-turn.sh
test/gh292-worktree-vendored-discovery.sh
test/gh293-vendored-guard-drift.sh
test/gh308-frozen-twin-guard.sh
test/gh322-unknown-arg-rejection.sh
test/gh331-cost-summary.sh
test/gh376-relay-drive-lock-parity.sh
test/gh448-driver-lock-resolver.sh
test/lane-attempt-cap.sh
test/marathon-plan.sh
test/poll-relay.sh
test/relay-artifact-file.sh
test/relay-escalation-not-stall.sh
test/relay-review-once.sh
test/relay-target-root-newfile.sh
test/relay-target-root-paths.sh
test/relay-target-root-relayfile.sh
test/relay-target-root.sh
test/relay-token-collision.sh
test/relay-untracked-file-warn.sh
test/relay-xyz-skill-guard.sh
test/skill-extract.sh
test/swarm-preflight.sh
test/xyz-harness-hooks.sh
      33
test/gh312-vendor-preserves-state.sh:57:HEAD="$(git -C "$ROOT" rev-parse HEAD)"
test/claim-cap.sh:9:git -C "$A" config user.name alice
test/claim-cap.sh:15:git -C "$A" add .tick && git -C "$A" commit -q -m "seed tasks" && git -C "$A" push -q origin main
test/relay-case-insensitive.sh:20:git -C "$A" config core.ignorecase true
test/relay-case-insensitive.sh:28:git -C "$A" config core.ignorecase false
test/xyz-vendor.sh:94:HEAD="$(git -C "$ROOT" rev-parse HEAD)"
test/xyz-vendor.sh:95:ANCESTOR="$(git -C "$ROOT" rev-list --max-parents=0 HEAD | tail -1)"
test/gh278-turn-timeout-parity.sh:84:git -C "$A" add relay.md .gitignore tracked.md >/dev/null 2>&1
test/gh278-turn-timeout-parity.sh:85:git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1
test/gh278-turn-timeout-parity.sh:115:  git -C "$A" reset --hard >/dev/null 2>&1
test/gh278-turn-timeout-parity.sh:116:  git -C "$A" clean -f >/dev/null 2>&1
test/poll-driver.sh:17:git -C "$A" add relay.md relay-approved.md art.md art-dirty.md >/dev/null 2>&1
test/poll-driver.sh:18:git -C "$A" commit -q -m "poll-driver fixtures" >/dev/null 2>&1
test/poll-driver.sh:98:git -C "$A" add relay-next-mine.md relay-next-other.md relay-next-codex.md relay-next-approved.md \
test/poll-driver.sh:101:git -C "$A" commit -q -m "file-source fixtures" >/dev/null 2>&1
test/gh460-pipe-buffer-sigpipe.sh:35:SITE="$ROOT_REPO/test/pdda-local-checks.sh"
test/gh460-pipe-buffer-sigpipe.sh:119:# validate.sh runs each test as `bash test/<file>`, a fresh shell, so options are not inherited from
test/gh460-pipe-buffer-sigpipe.sh:148:  if [ -n "$(gh472_shape "$ROOT_REPO/$rel")" ]; then
test/gh460-pipe-buffer-sigpipe.sh:180:  grep -qE 'set -[a-zA-Z]*o pipefail|set -o pipefail|_setup\.sh' "$ROOT_REPO/$cand" 2>/dev/null || continue
test/gh460-pipe-buffer-sigpipe.sh:181:  grep -qE "$REPO_WIDE" "$ROOT_REPO/$cand" 2>/dev/null || continue
test/gh460-pipe-buffer-sigpipe.sh:182:  [ -n "$(gh472_shape "$ROOT_REPO/$cand")" ] && derived_bad="$derived_bad $cand"
test/gh460-pipe-buffer-sigpipe.sh:184:$(cd "$ROOT_REPO" && git ls-files 'test/*.sh' 'utils/*.sh' 'utils/**/*.sh' 'relay-automation/*.sh' 2>/dev/null)
test/gh460-pipe-buffer-sigpipe.sh:212:grep -nE '\|[[:space:]]*grep[[:space:]]+-[A-Za-z]*q' "$ROOT_REPO/utils/py/rtl.py" >/dev/null 2>&1 \
test/gh460-pipe-buffer-sigpipe.sh:218:  grep -qE 'set -[a-zA-Z]*o pipefail' "$ROOT_REPO/$cand" 2>/dev/null || continue
test/gh460-pipe-buffer-sigpipe.sh:219:  [ -n "$(gh472_shape "$ROOT_REPO/$cand")" ] && exposed="$exposed $cand"
test/gh460-pipe-buffer-sigpipe.sh:221:$(cd "$ROOT_REPO" && git ls-files 'relay-automation/*.sh' 2>/dev/null)
test/gh402-branch-enforcement.sh:61:  git -C "$d" config user.email t@t
test/gh402-branch-enforcement.sh:62:  git -C "$d" config user.name t
test/gh402-branch-enforcement.sh:63:  git -C "$d" symbolic-ref HEAD refs/heads/main
test/gh402-branch-enforcement.sh:67:  git -C "$d" add -A >/dev/null 2>&1
test/gh402-branch-enforcement.sh:68:  git -C "$d" commit -q -m seed
test/gh402-branch-enforcement.sh:69:  git -C "$d" remote add origin "$bare"
test/gh402-branch-enforcement.sh:70:  git -C "$d" push -q -u origin main
test/gh402-branch-enforcement.sh:72:  git -C "$d" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
test/gh402-branch-enforcement.sh:105:if [ "$(git -C "$R1" rev-list --count HEAD)" -eq 1 ]; then
test/gh402-branch-enforcement.sh:108:  fail "GH-402: the run committed to trunk before refusing — $(git -C "$R1" log --oneline | head -3)"
test/gh402-branch-enforcement.sh:146:git -C "$R3" checkout -q -b marathon/probe
test/gh402-branch-enforcement.sh:198:git -C "$R7" config user.email t@t
test/gh402-branch-enforcement.sh:199:git -C "$R7" config user.name t
test/gh402-branch-enforcement.sh:200:git -C "$R7" symbolic-ref HEAD refs/heads/main
test/gh402-branch-enforcement.sh:204:git -C "$R7" add -A >/dev/null 2>&1
test/gh402-branch-enforcement.sh:205:git -C "$R7" commit -q -m seed
test/gh397-reviewer-turn-role.sh:14:# reviewer crossed on 2026-06-20 when it edited validate.sh.
test/xyz-sync-check.sh:16:HEAD="$(git -C "$ROOT" rev-parse HEAD)"
test/gh369-find-doc-root-resolution.sh:83:  git -C "$TMP/$r" init -q 2>/dev/null
test/gh408-tick-failure-visibility.sh:119:git -C "$C" config user.email c@t
test/gh408-tick-failure-visibility.sh:120:git -C "$C" config user.name c
test/gh408-tick-failure-visibility.sh:122:git -C "$C" add relay.md
test/gh408-tick-failure-visibility.sh:123:git -C "$C" commit -q -m init
test/relay-self-sufficiency.sh:75:git -C "$REPO" config user.email "test@t"
test/relay-self-sufficiency.sh:76:git -C "$REPO" config user.name "test"
test/relay-self-sufficiency.sh:85:git -C "$REPO" add .gitignore relay.md
test/relay-self-sufficiency.sh:86:git -C "$REPO" commit -q -m "seed minimal relay"
test/relay-self-sufficiency.sh:140:relay_commit_count="$(git -C "$REPO" log --oneline relay.md 2>/dev/null | wc -l | tr -d ' ')"
test/ate-run-variations.sh:12:# dependency-free, consistent with the rest of validate.sh.
test/relay-target-root.sh:17:git -C "$B" add relay.md artifact.txt >/dev/null 2>&1
test/relay-target-root.sh:18:git -C "$B" commit -q -m "seed B" >/dev/null 2>&1
test/relay-target-root.sh:24:git -C "$A" add relay.md artifact.txt >/dev/null 2>&1
test/relay-target-root.sh:25:git -C "$A" commit -q -m "seed A" >/dev/null 2>&1
test/relay-target-root.sh:66:B_BEFORE="$(git -C "$B" rev-parse HEAD)"
test/relay-target-root.sh:67:A_BEFORE="$(git -C "$A" rev-parse HEAD)"
test/relay-target-root.sh:83:[ "$(git -C "$B" rev-parse HEAD)" != "$B_BEFORE" ] && pass "foreign repo target: commit created in foreign repo B" || fail "no commit in foreign repo B"
test/relay-target-root.sh:86:[ "$(git -C "$A" rev-parse HEAD)" = "$A_BEFORE" ] && pass "foreign repo target: harness repo A untouched" || fail "harness repo A was modified"
test/relay-target-root.sh:98:B_BEFORE="$(git -C "$B" rev-parse HEAD)"
test/relay-target-root.sh:99:A_BEFORE="$(git -C "$A" rev-parse HEAD)"
test/relay-target-root.sh:111:[ "$(git -C "$A" rev-parse HEAD)" != "$A_BEFORE" ] && pass "default path: commit created in harness repo A" || fail "no commit in harness repo A"
test/relay-target-root.sh:114:[ "$(git -C "$B" rev-parse HEAD)" = "$B_BEFORE" ] && pass "default path: foreign repo B untouched" || fail "foreign repo B was modified"
test/relay-target-root.sh:126:A_BEFORE="$(git -C "$A" rev-parse HEAD)"
test/relay-target-root.sh:136:[ "$(git -C "$A" rev-parse HEAD)" != "$A_BEFORE" ] \
test/relay-target-root.sh:159:A_BEFORE="$(git -C "$A" rev-parse HEAD)"
test/relay-target-root.sh:169:[ "$(git -C "$A" rev-parse HEAD)" != "$A_BEFORE" ] \
test/oracle-guard.sh:15:run --allow "src/foo.js" --oracle "spec/foo.spec,validate.sh"
test/oracle-guard.sh:19:run --allow "validate.sh" --oracle "validate.sh"
test/oracle-guard.sh:31:run --allow "src/cost.js" --oracle "test/cost.sh,validate.sh,relay-automation/measure.sh"
test/oracle-guard.sh:51:# GH-110 P2b: this sub-test needs a real oracle target on disk ($ROOT/validate.sh) to canonicalize;
test/oracle-guard.sh:52:# in a vendored copy validate.sh does not travel, so skip (don't dangle-fail) when it is absent.
test/oracle-guard.sh:53:if [ -e "$ROOT/validate.sh" ]; then
test/oracle-guard.sh:54:  SL="${TMPDIR:-/tmp}/og-alias.$$.sh"; ln -sf "$ROOT/validate.sh" "$SL"
test/oracle-guard.sh:55:  run --allow "$SL" --oracle "validate.sh"
test/oracle-guard.sh:59:  skip "symlink-to-oracle sub-test needs \$ROOT/validate.sh (absent in a vendored copy)"
test/xyz-harness-hooks.sh:145:git -C "$A" add .gitignore >/dev/null 2>&1
test/xyz-harness-hooks.sh:146:git -C "$A" commit -q -m "gh75 test init" >/dev/null 2>&1
test/xyz-harness-hooks.sh:147:INIT_HEAD="$(git -C "$A" rev-parse HEAD)"
test/xyz-harness-hooks.sh:159:reset_a() { rm -rf "$A/.tick" "$A/phases" "$A/relay-system"; git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true; }
test/find-harness.sh:14:mkrepo() { _repo="$(mktemp -d "${TMPDIR:-/tmp}/fh-case.XXXXXX")"; git -C "$_repo" init -q; printf '%s\n' "$_repo"; }
test/find-harness.sh:23:  _blob="$(printf 'fixture\n' | git -C "$_repo" hash-object -w --stdin)"
test/find-harness.sh:24:  git -C "$_repo" update-index --add --cacheinfo 100644,"$_blob","$_path"
test/find-harness.sh:41:FR="$(mktemp -d "${TMPDIR:-/tmp}/fh-foreign.XXXXXX")"; git -C "$FR" init -q
test/find-harness.sh:49:FV="$(mktemp -d "${TMPDIR:-/tmp}/fh-vendored.XXXXXX")"; git -C "$FV" init -q
test/find-harness.sh:59:git -C "$FC" config core.ignorecase true
test/find-harness.sh:70:git -C "$FVC" config core.ignorecase true
test/find-harness.sh:82:git -C "$FN" config core.ignorecase true
test/find-harness.sh:91:git -C "$FS" config core.ignorecase false
test/gh292-worktree-vendored-discovery.sh:24:  git -C "$MAIN" worktree remove --force "$LINKED" >/dev/null 2>&1 || true
test/gh292-worktree-vendored-discovery.sh:47:git -C "$MAIN" config user.email gh292@test
test/gh292-worktree-vendored-discovery.sh:48:git -C "$MAIN" config user.name gh292
test/gh292-worktree-vendored-discovery.sh:50:git -C "$MAIN" add .seed
test/gh292-worktree-vendored-discovery.sh:51:git -C "$MAIN" commit -qm init
test/gh292-worktree-vendored-discovery.sh:53:git -C "$MAIN" worktree add -q -b gh292-linked "$LINKED" HEAD
test/gh509-gate-evidence.sh:10:# `gate-record.sh` exists as its own script: inlined in ci-local.sh, exercising the dirty-tree path
test/gh509-gate-evidence.sh:25:  git -C "$d" config user.email t@t
test/gh509-gate-evidence.sh:26:  git -C "$d" config user.name t
test/gh509-gate-evidence.sh:28:  git -C "$d" add -A >/dev/null 2>&1
test/gh509-gate-evidence.sh:29:  git -C "$d" commit -q -m seed
test/gh509-gate-evidence.sh:37:sha1="$(git -C "$R1" rev-parse HEAD)"
test/gh322-runlog-python-lane.sh:69:git -C "$A" add .gitignore && git -C "$A" commit -qm init
test/gh308-swarm-gate-path.sh:46:git -C "$R" init -q -b main 2>/dev/null || { git -C "$R" init -q; git -C "$R" symbolic-ref HEAD refs/heads/main; }
test/gh308-swarm-gate-path.sh:47:git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
test/gh308-swarm-gate-path.sh:48:git -C "$R" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
test/gh268-relay-cue-and-target-checks.sh:132:# ── the wiring: a cross-repo lane with no validate.sh gets this gate by default ──────────
test/gh268-relay-cue-and-target-checks.sh:136:  && pass "marathon_drive wires target-checks.sh for a --target-root with no validate.sh" \
test/gh268-relay-cue-and-target-checks.sh:146:# own tracked phases/p1/RELAY.md — `bash validate.sh` left the tree dirty, and the polluted file was
test/gh268-relay-cue-and-target-checks.sh:154:  git -C "$1" config user.email gh268@t; git -C "$1" config user.name gh268
test/gh268-relay-cue-and-target-checks.sh:155:  [ -n "${2:-}" ] && printf '%s' "$2" > "$1/validate.sh"
test/gh268-relay-cue-and-target-checks.sh:157:  git -C "$1" add -A >/dev/null 2>&1; git -C "$1" commit -q -m init
test/gh268-relay-cue-and-target-checks.sh:160:# [Blocker] "A target that has validate.sh does NOT keep using it" — it fell to the else branch and
test/gh268-relay-cue-and-target-checks.sh:161:# ran the HARNESS's validate.sh against a foreign repo, while the code comment claimed otherwise.
test/gh268-relay-cue-and-target-checks.sh:167:printf '%s' "$out" | grep -Fq "$HASV/validate.sh" \
test/gh268-relay-cue-and-target-checks.sh:168:  && pass "a --target-root with its own validate.sh is gated on the TARGET's copy" \
test/gh268-relay-cue-and-target-checks.sh:169:  || fail "gate did not select the target's validate.sh: $(printf '%s' "$out" | grep -i gate)"
test/gh268-relay-cue-and-target-checks.sh:170:printf '%s' "$out" | grep -Fq "$ROOT/validate.sh" \
test/gh268-relay-cue-and-target-checks.sh:171:  && fail "gate selected the HARNESS validate.sh for a foreign target — Codex Blocker 1 is back" \
test/gh268-relay-cue-and-target-checks.sh:172:  || pass "the harness validate.sh is not used against a foreign target"
test/gh268-relay-cue-and-target-checks.sh:196:  && pass "a --target-root with no validate.sh falls back to target-checks.sh" \
test/gh268-relay-cue-and-target-checks.sh:197:  || fail "no target-checks fallback for a target lacking validate.sh: $out"
test/gh331-cost-summary.sh:73:# nested marathon to find the REAL validate.sh and re-enter the full gate recursively.
test/gh331-cost-summary.sh:148:git -C "$A" add .gitignore >/dev/null 2>&1 && git -C "$A" commit -qm init >/dev/null 2>&1
test/mktemp-trap-guard.sh:32:# Real code directories, PLUS root-level .sh files themselves (validate.sh, install.sh,
test/gh293-vendored-guard-drift.sh:23:  git -C "$HARNESS" config user.email test@xyz
test/gh293-vendored-guard-drift.sh:24:  git -C "$HARNESS" config user.name test
test/gh293-vendored-guard-drift.sh:25:  git -C "$HARNESS" add .
test/gh293-vendored-guard-drift.sh:26:  git -C "$HARNESS" commit -q -m seed
test/gh293-vendored-guard-drift.sh:27:  git -C "$HARNESS" branch -M main
test/gh293-vendored-guard-drift.sh:69:git -C "$HARNESS" checkout -q -- README.md
test/gh293-vendored-guard-drift.sh:70:git -C "$HARNESS" checkout -q -b feature
test/relay-untracked-file-warn.sh:57:git -C "$A" add relayB.md >/dev/null 2>&1
test/relay-untracked-file-warn.sh:58:git -C "$A" commit -q -m "commit relay file" >/dev/null 2>&1
test/roadmap-dashboard.sh:110:# The old version regenerated $ROOT/ROADMAP-DASHBOARD.md as a side effect, so `validate.sh` could
test/gh319-gate-path-with-space.sh:6:# produced `bash /Users/.../Documents/GH Repos/.../validate.sh`. On the machine where this was
test/gh319-gate-path-with-space.sh:9:# while `bash validate.sh` was in fact RED.
test/gh319-gate-path-with-space.sh:12:#   (1) the gate actually runs the real validate.sh (marker written) and its FAILURE propagates
test/gh319-gate-path-with-space.sh:21:DRIVER="$ROOT_REPO/relay-automation/marathon-drive.sh"
test/gh319-gate-path-with-space.sh:29:SPACED_ROOT="$SPLIT_PARENT/GH Repos/proj"   # splits into ".../GH" + "Repos/proj/validate.sh"
test/gh319-gate-path-with-space.sh:31:printf '#!/usr/bin/env bash\ntouch "%s/validate-ran"\nexit 1\n' "$WORK" > "$SPACED_ROOT/validate.sh"
test/gh319-gate-path-with-space.sh:34:old_cmd="bash $SPACED_ROOT/validate.sh"                      # UNQUOTED — the pre-fix form
test/gh319-gate-path-with-space.sh:43:new_cmd="bash $(printf '%q' "$SPACED_ROOT/validate.sh")"     # QUOTED — the fixed form
test/gh319-gate-path-with-space.sh:46:  pass "post-fix: quoted gate runs the real validate.sh and propagates its failure"
test/gh319-gate-path-with-space.sh:59:git -C "$ROOT" config user.email gh319@t
test/gh319-gate-path-with-space.sh:60:git -C "$ROOT" config user.name gh319
test/gh319-gate-path-with-space.sh:64:printf '#!/usr/bin/env bash\ntouch "%s/gate-ran"\nexit 1\n' "$WORK" > "$ROOT/validate.sh"
test/gh319-gate-path-with-space.sh:65:git -C "$ROOT" add .gitignore validate.sh >/dev/null 2>&1
test/gh319-gate-path-with-space.sh:66:git -C "$ROOT" commit -q -m init
test/gh319-gate-path-with-space.sh:112:# ── (2) a FAILING validate.sh must actually fail the phase, not silently pass ────────────
test/gh319-gate-path-with-space.sh:117:  pass "the real validate.sh at the spaced root actually executed"
test/gh319-gate-path-with-space.sh:119:  fail "gate never ran the real validate.sh — the path split again (rc=$drc): $(printf '%s' "$drv_out" | tail -5)"
test/gh319-gate-path-with-space.sh:136:  pass "XYZ_PYTHON=0: the real validate.sh at the spaced root actually executed"
test/gh319-gate-path-with-space.sh:138:  fail "XYZ_PYTHON=0: gate never ran the real validate.sh (rc=$brc): $(printf '%s' "$bash_out" | tail -5)"
test/gh419-gate-inventory.sh:11:cat >"$FIXTURE/validate.sh" <<'EOF'
test/phase3-signoff-guard.sh:16:# never make `git -C "$A"` fall through to the real repo.
test/gh409-claim-leak.sh:32:git -C "$A" add relay.md .gitignore >/dev/null 2>&1
test/gh409-claim-leak.sh:33:git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1
test/gh409-claim-leak.sh:109:before="$(git -C "$A" rev-parse HEAD)"
test/gh409-claim-leak.sh:116:if [ "$(git -C "$A" rev-parse HEAD)" != "$before" ]; then
test/rtl-orphan-backup.sh:34:git -C "$R" init -q
test/rtl-orphan-backup.sh:35:git -C "$R" config user.email t@example.com
test/rtl-orphan-backup.sh:36:git -C "$R" config user.name t
test/rtl-orphan-backup.sh:40:git -C "$R" add -A
test/rtl-orphan-backup.sh:41:git -C "$R" commit -qm init
test/rtl-orphan-backup.sh:112:if rtl_was_dirty_before "$(git -C "$R" status --porcelain -z | tr -d '\0' | head -c 200)" \
test/gh514-write-set-trackable.sh:82:  git -C "$d" config user.email t@t
test/gh514-write-set-trackable.sh:83:  git -C "$d" config user.name t
test/gh514-write-set-trackable.sh:87:  git -C "$d" add -A >/dev/null 2>&1
test/gh514-write-set-trackable.sh:88:  git -C "$d" commit -q -m seed
test/deep-research.sh:264:# default validate.sh required-green set — same opt-in posture as relay-self-sufficiency.sh. When
test/consult.sh:14:git -C "$A" add tracked.txt >/dev/null 2>&1; git -C "$A" commit -q -m "seed tracked" >/dev/null 2>&1
test/consult.sh:60:porc="$(git -C "$A" status --porcelain)"
test/consult.sh:64:[ "$(git -C "$A" worktree list | wc -l | tr -d ' ')" = "1" ] && pass "isolation worktree cleaned up" \
test/consult.sh:65:  || fail "worktree left behind: $(git -C "$A" worktree list)"
test/gh388-run-log-durability.sh:144:git -C "$A" add relay.md .gitignore >/dev/null 2>&1
test/gh388-run-log-durability.sh:145:git -C "$A" commit -q -m "seed" >/dev/null 2>&1
test/gh343-gate-program-target-root.sh:55:git -C "$R" init -q -b main 2>/dev/null || { git -C "$R" init -q; git -C "$R" symbolic-ref HEAD refs/heads/main; }
test/gh343-gate-program-target-root.sh:56:git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
test/gh343-gate-program-target-root.sh:57:git -C "$R" -c user.email=t@t -c user.name=t commit -qm fixture >/dev/null 2>&1
test/driver-lock.sh:10:# the acquire/reclaim path regardless of how validate.sh was invoked.
test/gh385-retry-token-satisfied.sh:27:git -C "$A" add .gitignore >/dev/null 2>&1
test/gh385-retry-token-satisfied.sh:28:git -C "$A" commit -q -m init
test/swe-diagram.sh:9:GENERATOR="$HERE/../utils/swe-diagram/scripts/git-history-to-json.js"
test/swe-diagram.sh:269:git -C "$GIT_REPO" init -q -b main
test/swe-diagram.sh:270:git -C "$GIT_REPO" config user.name "Diagram Test"
test/swe-diagram.sh:271:git -C "$GIT_REPO" config user.email "diagram@example.test"
test/swe-diagram.sh:273:git -C "$GIT_REPO" add history.txt
test/swe-diagram.sh:274:git -C "$GIT_REPO" commit -q -m "base"
test/swe-diagram.sh:275:git -C "$GIT_REPO" switch -q -c development
test/swe-diagram.sh:277:git -C "$GIT_REPO" commit -qam "development commit"
test/swe-diagram.sh:278:git -C "$GIT_REPO" switch -q -c feature/x
test/swe-diagram.sh:280:git -C "$GIT_REPO" commit -qam "feature one"
test/swe-diagram.sh:282:git -C "$GIT_REPO" commit -qam "feature two"
test/swe-diagram.sh:283:git -C "$GIT_REPO" switch -q development
test/swe-diagram.sh:284:git -C "$GIT_REPO" merge -q --no-ff feature/x -m "merge feature"
test/swe-diagram.sh:285:git -C "$GIT_REPO" switch -q main
test/swe-diagram.sh:286:git -C "$GIT_REPO" merge -q --no-ff development -m "merge development"
test/gh375-auth-timeout-verdict.sh:34:export PYTHONPATH="$ROOT_REPO/utils/py${PYTHONPATH:+:$PYTHONPATH}"
test/gh375-auth-timeout-verdict.sh:79:cp -R "$ROOT_REPO/utils" "$FIXH/utils"
test/gh375-auth-timeout-verdict.sh:175:  post="$(run_preflight "$ROOT_REPO/utils/py" "$caller" || true)"
test/gh375-auth-timeout-verdict.sh:197:  if grep -q 'AGY_AUTH_TIMEOUT_S", 5)' "$ROOT_REPO/$f"; then
test/relay-target-root-relayfile.sh:17:git -C "$B" add "$REL" >/dev/null 2>&1
test/relay-target-root-relayfile.sh:18:git -C "$B" commit -q -m "seed relay in B" >/dev/null 2>&1
test/litmus-release.sh:13:#   PROVES  (1) each manifest gate is REGISTERED in validate.sh's TESTS array, so the suite actually
test/litmus-release.sh:33:#   (default)          Suite mode, registered in validate.sh. GREEN while Litmus is in progress.
test/litmus-release.sh:145:  # (1) registration — the inventory is generated FROM validate.sh's TESTS array, so presence in it
test/litmus-release.sh:148:    printf '%s incomplete not-registered-in-validate.sh:%s\n' "$issue" "$gate"; return 0
test/litmus-release.sh:236:  } > "$FIX/validate.sh"
test/litmus-release.sh:253:  /usr/bin/grep -v 'gh401-dry-run-no-mutation.sh' "$FIX/validate.sh" > "$FIX/validate.sh.new"
test/litmus-release.sh:254:  mv "$FIX/validate.sh.new" "$FIX/validate.sh"
test/litmus-release.sh:266:  printf '%s' "$AUDIT_OUT" | /usr/bin/grep '^461 incomplete not-registered-in-validate.sh' >/dev/null \
test/litmus-release.sh:275:  printf 'TESTS=(\n  "gh401-dry-run-no-mutation.sh"\n)\n' > "$FIX2/validate.sh"
test/litmus-release.sh:283:  violated="$(audit_entry  "$FIX2" 461 "test/gh401-dry-run-no-mutation.sh" "$inv2" "absent:validate.sh")"
test/gh432-failed-turn-persist.sh:24:git -C "$A" add relay.md .gitignore >/dev/null 2>&1
test/gh432-failed-turn-persist.sh:25:git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1
test/gh432-failed-turn-persist.sh:65:before0="$(git -C "$A" rev-parse HEAD)"
test/gh432-failed-turn-persist.sh:70:[ "$(git -C "$A" rev-parse HEAD)" != "$before0" ] \
test/gh432-failed-turn-persist.sh:77:before="$(git -C "$A" rev-parse HEAD)"
test/gh432-failed-turn-persist.sh:84:after="$(git -C "$A" rev-parse HEAD)"
test/gh432-failed-turn-persist.sh:94:   && git -C "$A" log "$before"..HEAD --name-only --format= 2>/dev/null | grep -qx 'relay.md'; then
test/gh432-failed-turn-persist.sh:100:if [ -z "$(git -C "$A" status --porcelain -- relay.md)" ]; then
test/gh432-failed-turn-persist.sh:120:before2="$(git -C "$A" rev-parse HEAD)"
test/gh432-failed-turn-persist.sh:122:if git -C "$A" log "$before2"..HEAD --name-only --format= 2>/dev/null | grep -qx 'offlane.md'; then
test/gh432-failed-turn-persist.sh:157:before4="$(git -C "$A" rev-parse HEAD)"
test/gh432-failed-turn-persist.sh:173:if [ "$(git -C "$A" rev-parse HEAD)" != "$before4" ]; then
test/gh387-gate-not-first-executor.sh:47:git -C "$A" init -q 2>/dev/null || { git init -q "$A"; }
test/gh387-gate-not-first-executor.sh:48:git -C "$A" config user.email t@t.t; git -C "$A" config user.name t
test/gh387-gate-not-first-executor.sh:51:git -C "$A" add -A >/dev/null 2>&1; git -C "$A" commit -q -m init
test/gh376-relay-drive-lock-parity.sh:29:# When validate.sh runs as a live marathon's --pre-advance-cmd, marathon_drive.py:649 has already
test/gh376-relay-drive-lock-parity.sh:79:git -C "$MAIN" config user.email t@example.com
test/gh376-relay-drive-lock-parity.sh:80:git -C "$MAIN" config user.name "gh376 test"
test/gh376-relay-drive-lock-parity.sh:81:git -C "$MAIN" add -A >/dev/null 2>&1
test/gh376-relay-drive-lock-parity.sh:82:git -C "$MAIN" commit -qm seed >/dev/null 2>&1
test/gh376-relay-drive-lock-parity.sh:84:git -C "$MAIN" worktree add -q "$WT" -b gh376-wt-branch
test/worktree-isolation.sh:17:git -C "$A" add relay.md artifact.txt .gitignore >/dev/null 2>&1
test/worktree-isolation.sh:18:git -C "$A" commit -q -m "seed" >/dev/null 2>&1

2026-08-13T17:19:48.143903Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 95 column 5
exec
/bin/zsh -lc "rg -n -i 'GH-528|test[- ]suite|parallel.*validate|time census|950\\.3|167\\.4|172\\.9|run_driver' PROJECT ROADMAP.md CHANGELOG.md README.md validate.sh ci-local.sh test relay-automation 2>/dev/null | head -400; git status --short; git log --oneline -12" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-86418-h4t1yue0
2026-08-13T17:19:59.229816Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 95 column 5
 succeeded in 6135ms:
2026-08-13 10:19:54.220 xcodebuild[87235:3127665]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-13 10:19:54.593 xcodebuild[87235:3127664] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-2YfdxeV8' (errno=Operation not permitted)
2026-08-13 10:19:55.394 xcodebuild[87256:3127884]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-13 10:19:55.590 xcodebuild[87256:3127883] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
?? relay-system/2026-08-13/
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-Fayjl0tL' (errno=Operation not permitted)
2026-08-13 10:19:57.105 xcodebuild[87268:3127934]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-13 10:19:57.308 xcodebuild[87268:3127932] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-ivRvnSTy' (errno=Operation not permitted)
2026-08-13 10:19:57.923 xcodebuild[87302:3128036]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-13 10:19:58.116 xcodebuild[87302:3128035] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
8a6a64a Merge remote-tracking branch 'origin/development' into feat/gh509-ci-macos-strategy
f6dd746 Merge pull request #524 from Claude-AI-Tools-Ventura-County/feature/agent2agent-doorbell
efe5900 fix(GH-509): two boundary-run failures from the first hosted macOS dispatch
893a4b9 docs(GH-509): record the agy Approved verdict, and the scope it does NOT cover
ca86178 relay(RELAY-gh509-ci-strategy-macos-review): agy turn (agy headless; no push)
53ddbd7 Merge remote-tracking branch 'origin/development' into feature/agent2agent-doorbell
8ac7359 feat(agent2agent): watch prints a REARM line on take-turn — doorbell re-arm becomes enforced protocol (#510)
aa076e4 docs(changelog): record the agy relay hardening of Doorbell mode (#510)
3eaa2ec relay(RELAY-agent2agent-doorbell-agy-review): agy turn (agy headless; no push)
63fee8c relay(agent2agent-doorbell-agy-review): producer r2
3b9f085 docs(agent2agent): apply agy r2 findings — DECISION-line discriminator, watch in send gate, closed paths (#510)
e482c79 relay(RELAY-agent2agent-doorbell-agy-review): agy turn (agy headless; no push)

exec
/bin/zsh -lc "nl -ba README.md | sed -n '1,52p'; ls -l package.json package-lock.json node_modules/acorn/package.json 2>&1 || true; nl -ba package.json 2>/dev/null || true; rg -n 'npm (ci|install)|acorn' .github ci-local.sh validate.sh README.md test/ci-workflow.sh | head -240; sed -n '180,330p' ci-local.sh" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-86418-h4t1yue0
 succeeded in 0ms:
     1	# XYZ — Multi-Agent Coordination Beta
     2	
     3	**XYZ lets several AI coding agents — Claude Code, Codex, and agy (Google's Antigravity CLI) — work
     4	on the same repo at the same time without overwriting each other's work.**
     5	
     6	## What XYZ is
     7	
     8	It's built in two layers:
     9	
    10	- **`tick`** — the kernel: a tiny local event-log CLI that hands out collision-free, path-scoped
    11	  work claims, so two agents never edit the same thing at once. No server, no API keys, no remote.
    12	- **`relay-automation/`** — the product on top of `tick`: it runs agents in **turns** (one builds,
    13	  another reviews) headlessly, so you can hand a task to Codex or agy and let them iterate toward
    14	  done without babysitting the handoff.
    15	
    16	It's a working beta, not a polished product — but the kernel is test-covered and the relay stack
    17	is the main active surface.
    18	
    19	## Quickstart — prove it works (no accounts needed)
    20	
    21	Requires **Node 18+** and **git** (the `tick` kernel runs on Node). No accounts or API keys.
    22	
    23	```bash
    24	npm install
    25	./validate.sh
    26	```
    27	
    28	(`npm install` pulls the two parser dependencies the test suite needs — skip it and the
    29	suite stops at `Cannot find module 'acorn'`.)
    30	
    31	That runs the full kernel + coordination test suite, with **no accounts or API keys required** —
    32	the fastest proof the coordination kernel actually works. It's the whole suite, not a smoke test,
    33	so **budget 5–10 minutes** on a first run. The suite prints its own pass count at the end; if it's
    34	green, you're good.
    35	
    36	> **⚠️ Run this un-sandboxed.** Under Claude Code's default Bash sandbox — or any sandboxed agent
    37	> harness — this command prints **nothing for several minutes** before failing, because the suite's
    38	> `mktemp -d` scratch directories are blocked. It looks like a hang, not a permissions error, and
    39	> it is this repo's single most common false alarm. Turn the sandbox off for this command
    40	> (`/sandbox` in Claude Code, or run it yourself in a normal terminal) before concluding anything
    41	> is broken.
    42	
    43	## Then pick your path
    44	
    45	- **New here for the beta test?** → start at [Beta Tester Onboarding](#beta-tester-onboarding) below.
    46	- **Run a live relay** — hand a real task to Codex/agy and let them build→review it →
    47	  start at **[relay-automation/README.md](relay-automation/README.md)**. Live turns need each CLI
    48	  installed and authenticated first: see
    49	  **[Set up Codex, agy, and Pi](relay-automation/README.md#set-up-codex-agy-and-pi-headless-bring-up)**.
    50	  For phase/status context, the project hub is
    51	  [PROJECT/4-MISC/AUTOMATED-RELAY.md](PROJECT/4-MISC/AUTOMATED-RELAY.md).
    52	- **Connect live agent sessions by a short ID** — start a serialized discussion with two or more
ls: node_modules/acorn/package.json: No such file or directory
-rw-r--r--@ 1 noelsaw  staff  1101 Aug 13 10:18 package-lock.json
-rw-r--r--@ 1 noelsaw  staff   487 Aug 13 10:18 package.json
     1	{
     2	  "name": "xyz-3-agents-swarm",
     3	  "version": "1.0.0",
     4	  "description": "XYZ multi-agent coordination: the tick kernel plus relay automation for running multiple AI coding agents on one repo without collisions.",
     5	  "main": "index.js",
     6	  "directories": {
     7	    "doc": "docs",
     8	    "test": "test"
     9	  },
    10	  "scripts": {
    11	    "test": "./validate.sh"
    12	  },
    13	  "keywords": [],
    14	  "author": "",
    15	  "license": "AGPL-3.0-only",
    16	  "dependencies": {
    17	    "acorn": "^8.17.0",
    18	    "acorn-walk": "^8.3.5"
    19	  }
    20	}
test/ci-workflow.sh:289:  if grep -qF '"acorn-extract.sh"' "$WORKFLOW" && grep -qF '"acorn-extract.sh"' "$CI_LOCAL"; then
test/ci-workflow.sh:290:    pass "both skip acorn-extract.sh (it already ran in the npm step — duplicate work, not lost coverage)"
test/ci-workflow.sh:292:    fail "acorn-extract.sh skip drift — it is duplicate work in both files and should be skipped in both"
ci-local.sh:195:# ── 8. npm + acorn-extract ───────────────────────────────────────────────────────────────────────
ci-local.sh:196:# A fresh clone has no node_modules, so acorn-extract dies with MODULE_NOT_FOUND. CI proves the
ci-local.sh:199:npm_and_acorn() {
ci-local.sh:200:  npm ci || return 1
ci-local.sh:201:  bash test/acorn-extract.sh
ci-local.sh:220:  # Only ONE skip survives, and it is not a platform concession: acorn-extract.sh already ran in the
ci-local.sh:223:    "acorn-extract.sh"                # already run above (needs npm ci first) — duplicate, not dropped
ci-local.sh:260:step "npm ci + acorn-extract"       npm_and_acorn
README.md:24:npm install
README.md:28:(`npm install` pulls the two parser dependencies the test suite needs — skip it and the
README.md:29:suite stops at `Cannot find module 'acorn'`.)
validate.sh:225:  "acorn-extract.sh"             # GH-169
.github/workflows/ci.yml:70:        run: npm ci
.github/workflows/ci.yml:268:      - name: Install npm dependencies and run acorn-extract test
.github/workflows/ci.yml:272:          npm ci
.github/workflows/ci.yml:273:          bash test/acorn-extract.sh
.github/workflows/ci.yml:345:            "acorn-extract.sh"                    # already run above (needs npm ci first)

# ── 6. PDDA ──────────────────────────────────────────────────────────────────────────────────────
pdda_gate() {
  utils/pdda/pdda.sh run || return 1
  # Warn-only by contract — it reports, it never gates. Kept outside the sync-managed utils/pdda/
  # tree because a 2026-08-03 upstream sync silently deleted three of these checks.
  utils/pdda-local-checks.sh run || true
  return 0
}

# ── 7. frozen twin guard — PR-only in CI, so opt-in here ─────────────────────────────────────────
frozen_twin_guard() {
  bash test/gh308-frozen-twin-guard.sh --check --base "$BASE" --allow-exceptions
}

# ── 8. npm + acorn-extract ───────────────────────────────────────────────────────────────────────
# A fresh clone has no node_modules, so acorn-extract dies with MODULE_NOT_FOUND. CI proves the
# README Quickstart path from scratch (GH-230); the same install is what makes a fresh checkout
# gate-ready at all — a marathon has already halted on exactly this.
npm_and_acorn() {
  npm ci || return 1
  bash test/acorn-extract.sh
}

# ── 9. the suite ─────────────────────────────────────────────────────────────────────────────────
# TESTS is parsed out of validate.sh exactly the way the workflow parses it, so the two cannot drift
# on WHICH tests run — only on the environment they run in.
#
# NOTE: `git config --global` is what CI does before this step, to supply the user identity and
# init.defaultBranch that fixture-driven tests assume. That is deliberately NOT done here: a dev
# machine already has both, and silently rewriting an operator's global git config is not something
# a test runner should do. If a fixture test fails on a bare machine, set them yourself.
validate_suite() {
  # GH-509: THIS SKIP LIST IS DELIBERATELY SHORTER THAN THE WORKFLOW'S, and that is the point.
  #
  # It used to mirror CI's, including `registry-lock-concurrency.sh`. That suite's own skip comment
  # in the workflow reads "flaky under CI load … PASSES LOCALLY" — it fails on a contended shared
  # Linux runner, a machine no XYZ user will ever have. Skipping it here threw away real signal about
  # the platform we actually ship to, in order to stay faithful to a platform we do not.
  #
  # Only ONE skip survives, and it is not a platform concession: acorn-extract.sh already ran in the
  # npm step above, so running it again would be duplicated work rather than dropped coverage.
  local skip_tests=(
    "acorn-extract.sh"                # already run above (needs npm ci first) — duplicate, not dropped
  )
  local all_tests=() line t s skip rc=0
  while IFS= read -r line; do
    [ -n "$line" ] && all_tests+=("$line")
  done < <(sed -n '/^TESTS=(/,/^)/p' validate.sh | grep -oE '"[^"]+\.sh"' | tr -d '"')

  [ "${#all_tests[@]}" -gt 0 ] || { echo "  could not parse TESTS from validate.sh" >&2; return 1; }
  echo "  ${#all_tests[@]} suites declared in validate.sh"

  for t in "${all_tests[@]}"; do
    skip=0
    for s in "${skip_tests[@]}"; do [ "$t" = "$s" ] && { skip=1; break; }; done
    [ "$skip" -eq 1 ] && { echo "SKIP (already run above): $t"; continue; }
    echo "=== $t ==="
    bash "test/$t" || { rc=1; echo "  ^^ FAILED: $t" >&2; }
  done
  return $rc
}

# ── run ──────────────────────────────────────────────────────────────────────────────────────────
printf '\033[1mci-local — mirroring .github/workflows/ci.yml tier1\033[0m\n'
printf 'repo: %s\n' "$HERE"
printf 'HEAD: %s\n' "$(git log --oneline -1 2>/dev/null)"
[ "$FAST" -eq 1 ] && printf '\033[33mmode: --fast (full validate.sh suite SKIPPED)\033[0m\n'

step "prerequisites"                check_prereqs
step "shellcheck tracked scripts"   shellcheck_tracked
step "bash syntax"                  bash_syntax_tracked
step "node syntax"                  node_syntax_tracked
step "settings JSON"                settings_json_valid
step "PDDA deterministic gate"      pdda_gate
if [ -n "$BASE" ]; then
  step "frozen twin guard"          frozen_twin_guard
else
  printf '\n\033[33mSKIP: frozen twin guard — CI runs it on pull_request only. Pass --base <ref> to run it.\033[0m\n'
fi
step "npm ci + acorn-extract"       npm_and_acorn
if [ "$FAST" -eq 0 ]; then
  RELAY_SELF_SUFFICIENCY_SKIP=1 step "validate.sh suite" validate_suite
fi

# ── report ───────────────────────────────────────────────────────────────────────────────────────
printf '\n\033[1m─── ci-local summary ───\033[0m\n'
for s in "${PASSED[@]}"; do printf '  \033[32m+\033[0m %s\n' "$s"; done
if [ "${#FAILED[@]}" -gt 0 ]; then
  for s in "${FAILED[@]}"; do printf '  \033[31m-\033[0m %s\n' "$s"; done
  printf '\n\033[31mci-local: %d step(s) failed\033[0m\n' "${#FAILED[@]}"
  printf 'This ran on macOS — the platform XYZ ships to — so a failure here is a real defect for\n'
  printf 'real users. Do not wait for hosted CI to confirm it; the ubuntu job is advisory (GH-509).\n'
  exit 1
fi
printf '\n\033[32mci-local: all steps passed\033[0m\n'
printf 'Green on the shipping platform, with the full suite — including the one hosted ubuntu skips.\n'
printf 'NOT a promotion qualification: this run is self-reported. Promotion needs a hosted macOS run\n'
printf 'for this exact commit (GH-509 §6) — a clean machine, and evidence you did not produce.\n'

# ── GH-509: record that THIS COMMIT was verified here ────────────────────────────────────────────
# Only a full run earns a record. A --fast or --probe run deliberately does not exercise the suite,
# so recording one would make a partial run indistinguishable from a complete one — which is the
# whole failure mode this file keeps warning about in other contexts.
if [ "$FAST" -eq 0 ] && [ "$PROBE" -eq 0 ]; then
  printf '\n'
  # Delegated rather than inlined, so the REFUSAL has a test that does not cost a 15-minute suite run.
  bash utils/gate-record.sh || true
fi
exit 0

2026-08-13T17:20:05.153058Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 95 column 5
exec
/bin/zsh -lc "sed -n '/"'^TESTS=(/,/''^)/p'"' validate.sh | grep -oE '\"["'^"]+'"\\.sh\"' | wc -l; sed -n '/"'^TESTS=(/,/''^)/p'"' validate.sh | grep -oE '\"["'^"]+'"\\.sh\"' | tr -d '\"' | rg -n '("'^|/)(gh375|gh385|gh390|gh407|gh419|marathon-drive)'"' ; nl -ba .github/workflows/ci.yml | sed -n '245,365p'; rg -n --glob '*.sh' '/tmp/|TMPDIR|mktemp|\\.git/index.lock|\\.git/.*lock|node_modules|\\.gate-evidence|relay-system/20|\\.pdda|ROADMAP-DASHBOARD' test | head -500" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-86418-h4t1yue0
 succeeded in 0ms:
     190
43:marathon-drive.sh
60:gh419-gate-inventory.sh
68:gh390-gate-guard.sh
70:gh407-gate-ran-attribution.sh
71:gh390-timeout-attribution.sh
80:gh375-agy-auth-preflight.sh
81:gh375-auth-timeout-verdict.sh
82:gh385-retry-token-satisfied.sh
   245	      #
   246	      # Escape hatch: a safety defect in a frozen fallback can legitimately warrant an edit (GH-319
   247	      # left a silently-fake pre-advance gate in marathon-drive.sh under XYZ_PYTHON=0). Such a commit
   248	      # must carry a trailer naming the twin it covers, which makes the exception auditable in
   249	      # `git log` instead of invisible:
   250	      #
   251	      #   Frozen-twin-exception: relay-automation/marathon-drive.sh — <reason>
   252	      #
   253	      # GH-321: the rule used to live here, inline, and was RANGE-scoped — one trailer anywhere in
   254	      # BASE..HEAD excused every frozen twin touched in the PR, including files nobody declared. It
   255	      # now lives in the guard script as `--allow-exceptions`, per-file, so it can be tested; inline
   256	      # YAML shell is unreachable from the suite, which is part of why the looseness shipped at all.
   257	      - name: Frozen Bash twin guard (GH-308)
   258	        if: github.event_name == 'pull_request'
   259	        env:
   260	          BASE_SHA: ${{ github.event.pull_request.base.sha }}
   261	        run: |
   262	          set -euo pipefail
   263	          bash test/gh308-frozen-twin-guard.sh --check --base "$BASE_SHA" --allow-exceptions
   264	
   265	      # GH-230: prove the README Quickstart's npm-dependency path works from a fresh
   266	      # clone, so a missing-install-step regression fails here instead of on a
   267	      # newcomer's machine.
   268	      - name: Install npm dependencies and run acorn-extract test
   269	        if: steps.route.outputs.docs_only != 'true'
   270	        run: |
   271	          set -euo pipefail
   272	          npm ci
   273	          bash test/acorn-extract.sh
   274	
   275	      # GH-232: the acting-agent's user/keychain config and default `git init` branch name are
   276	      # macOS-dev-machine assumptions baked into several fixture-driven tests (e.g. archive-writers.sh,
   277	      # xyz-vendor.sh do a bare `git init` and expect the resulting branch to be "main"). ubuntu-latest's
   278	      # git has no global identity and may default new repos to a non-"main" branch, so prepare both
   279	      # here rather than touch the tests themselves (out of scope for this lane).
   280	      - name: Prepare git environment for fixture-driven tests
   281	        if: steps.route.outputs.docs_only != 'true'
   282	        run: |
   283	          set -euo pipefail
   284	          git config --global init.defaultBranch main
   285	          git config --global user.email "ci@runner.invalid"
   286	          git config --global user.name "CI Runner"
   287	
   288	      - name: Run Fast Gate tests (Pull Request)
   289	        # Whole-job budget target: < 3 minutes for a code-only fast PR.
   290	        if: github.event_name == 'pull_request' && steps.route.outputs.route == 'fast'
   291	        env:
   292	          RELAY_SELF_SUFFICIENCY_SKIP: "1"
   293	          CHANGED_TESTS: ${{ steps.route.outputs.changed_tests }}
   294	        run: |
   295	          set -euo pipefail
   296	          FAST_TESTS=(
   297	            "worktree-isolation.sh"
   298	            "shim-worktree.sh"
   299	            "gh292-worktree-vendored-discovery.sh"
   300	            "relay-target-root.sh"
   301	            "relay-target-root-paths.sh"
   302	            "relay-target-root-relayfile.sh"
   303	            "relay-target-root-newfile.sh"
   304	            "gh289-target-root-build-turn.sh"
   305	            "gh410-containment-advisory.sh"
   306	            "tick-foreign-cwd.sh"
   307	            "mktemp-trap-guard.sh"
   308	          )
   309	          if [[ -n "$CHANGED_TESTS" ]]; then
   310	            IFS=',' read -r -a routed_tests <<<"$CHANGED_TESTS"
   311	            for t in "${routed_tests[@]}"; do
   312	              already_listed=0
   313	              for existing in "${FAST_TESTS[@]}"; do
   314	                [[ "$existing" == "$t" ]] && { already_listed=1; break; }
   315	              done
   316	              [[ "$already_listed" -eq 1 ]] || FAST_TESTS+=("$t")
   317	            done
   318	          fi
   319	          FAILED=0
   320	          for t in "${FAST_TESTS[@]}"; do
   321	            echo "=== $t ==="
   322	            bash "test/$t" || FAILED=1
   323	          done
   324	          exit "$FAILED"
   325	
   326	      # GH-232: PR #231 ran the full ./validate.sh suite on ubuntu-latest for the first time and
   327	      # found ~12 failures, assumed to be Ubuntu-environment-only and scoped out of CI. Re-diagnosed
   328	      # directly against a real ubuntu:latest container (not guessed at from macOS): almost all were
   329	      # masked by two things, now both fixed — (1) marathon.sh/marathon-drive.sh (and dependents
   330	      # debug-mantra.sh/driver-lock.sh) used a BSD-only `sed -i ''` invocation that mis-parses under
   331	      # GNU sed; (2) driver-lock.sh/xyz-harness-hooks.sh stubbed CLAUDE_BIN/AGY_BIN but not
   332	      # CODEX_BIN — the actual default builder — so they only "passed" locally because a real `codex`
   333	      # binary happened to be on the developer's own PATH, masking the gap; ubuntu CI has no such
   334	      # binary. path-integrity.sh/archive-writers.sh/relay-file-seeding-visibility.sh/xyz-vendor.sh/
   335	      # hq.sh/relay-pkg-freshness.sh all passed cleanly once re-tested for real — no ubuntu-specific
   336	      # bug in any of them. Only registry-lock-concurrency.sh (GH-72, a documented 16-concurrent-writer
   337	      # lock-contention flake under CI load, unrelated to this issue) stays skipped.
   338	      - name: Run validate.sh suite (minus a documented flaky test)
   339	        if: steps.route.outputs.route == 'full'
   340	        env:
   341	          RELAY_SELF_SUFFICIENCY_SKIP: "1"
   342	        run: |
   343	          set -euo pipefail
   344	          SKIP_TESTS=(
   345	            "acorn-extract.sh"                    # already run above (needs npm ci first)
   346	            "registry-lock-concurrency.sh"          # GH-72/GH-232: flaky under CI load (16 concurrent tick writers → lock contention / lost row); passes locally, flaked 3 runs across PRs #257/#259
   347	            "pdda-repo-contract.sh"               # already run in PDDA step
   348	          )
   349	          ALL_TESTS=()
   350	          while IFS= read -r line; do
   351	            [ -n "$line" ] && ALL_TESTS+=("$line")
   352	          done < <(sed -n '/^TESTS=(/,/^)/p' validate.sh | grep -oE '"[^"]+\.sh"' | tr -d '"')
   353	          FAILED=0
   354	          for t in "${ALL_TESTS[@]}"; do
   355	            skip=0
   356	            for s in "${SKIP_TESTS[@]}"; do
   357	              [ "$t" = "$s" ] && { skip=1; break; }
   358	            done
   359	            if [ "$skip" -eq 1 ]; then
   360	              echo "SKIP (GH-232): $t"
   361	              continue
   362	            fi
   363	            echo "=== $t ==="
   364	            bash "test/$t" || FAILED=1
   365	          done
test/gh312-vendor-preserves-state.sh:30:  mkdir -p "$REPO/.xyz/relay-system/2026-07-27" "$REPO/.xyz/.tick/events"
test/gh312-vendor-preserves-state.sh:31:  printf 'PRODUCER-TURN-1\n' > "$REPO/.xyz/relay-system/2026-07-27/thread.md"
test/gh312-vendor-preserves-state.sh:40:  [ "$(cat "$REPO/.xyz/relay-system/2026-07-27/thread.md" 2>/dev/null)" = "PRODUCER-TURN-1" ] \
test/relay-case-insensitive.sh:16:REL="relay-system/2026-06-24/thread.md"
test/xyz-vendor.sh:24:# find-harness store/resolve — otherwise the symlinked mktemp dir breaks string compares.
test/hq-marathon-live.sh:15:WORK="$(mktemp -d "${TMPDIR:-/tmp}/hq-marathon-live.XXXXXX")"
test/hq-marathon-live.sh:56:: >"$LIVE_REPO/.git/relay-driver.lock"
test/gh369-find-doc-root-resolution.sh:79:TMP="$(mktemp -d)"
test/relay-file-seeding-visibility.sh:18:RELAY_A="$A/relay-system/2026-07-08/seed-test.md"
test/relay-file-seeding-visibility.sh:25:if [ "$rc1" -eq 0 ] && [ -n "$wt1" ] && [ -f "$wt1/relay-system/2026-07-08/seed-test.md" ]; then
test/relay-file-seeding-visibility.sh:27:  if grep -q "UNCOMMITTED CONTENT $$" "$wt1/relay-system/2026-07-08/seed-test.md" 2>/dev/null; then
test/relay-file-seeding-visibility.sh:40:RELAY_B="$B/relay-system/2026-07-08/archive-test.md"
test/relay-file-seeding-visibility.sh:47:  if [ -f "$wt2$B/relay-system/2026-07-08/archive-test.md" ] || find "$wt2" -name archive-test.md 2>/dev/null | grep -q .; then
test/hq-promote.sh:18:# GH-177: mktemp -d can fail silently under a sandboxed shell (empty stdout, non-zero rc). The old
test/hq-promote.sh:19:# `cd "$(mktemp -d)" && pwd -P` idiom let `cd ""` succeed and silently stay at the CWD (the repo
test/hq-promote.sh:21:# Verify mktemp actually succeeded and returned a real directory BEFORE it's wired into a destructive
test/hq-promote.sh:23:TMP="$(mktemp -d)" || { echo "FAIL: mktemp -d failed" >&2; exit 1; }
test/hq-promote.sh:24:[ -n "$TMP" ] && [ -d "$TMP" ] || { echo "FAIL: mktemp -d returned an invalid path" >&2; exit 1; }
test/hq-promote.sh:31:: > "$REPO/.pdda-mode"   # marks Tier A/B (has_pdda) for cmd_promote
test/gh331-cost-summary.sh:15:# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: hold the clone's .git/relay-driver.lock with a LIVE pid, then run this suite (that is the in-marathon condition; a linked worktree does NOT reproduce it because relay-drive takes a per-worktree lock there, GH-376). pre-fix revision: this file with RELAY_DRIVER_LOCKED unset but the relay-drive invocations unscoped. pre-fix result: FAIL rc=1 'another driver is active in this repo (pid 2436, lock: .git/relay-driver.lock)' — the same failure that halted Litmus wave-2 phase 1 on 2026-08-08 at 893s. post-fix result: 8 pass / 0 fail with the SAME lock still held, and 8 pass / 0 fail with no lock, so the fix is verified in both directions rather than only the one under investigation"}
test/gh331-cost-summary.sh:41:# .git/relay-driver.lock — held by the marathon driver that was running this very gate — and refused:
test/gh331-cost-summary.sh:44:#     relay-drive: another driver is active in this repo (pid 35784, lock: .git/relay-driver.lock).
test/gh331-cost-summary.sh:97:tmp="\$(mktemp)"; sed 's/^STATUS:.*/STATUS: Approved/' "$rf" > "\$tmp" && mv "\$tmp" "$rf"
test/gh467-index-only-lane-blocked.sh:9:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh467-index-only.XXXXXX")"
test/gh308-swarm-gate-path.sh:15:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh308-swarm-gate-path.XXXXXX")"
test/gh308-swarm-gate-path.sh:67:            mktemp dirname basename date rm mkdir ls cp mv find printf test lsof realpath; do
test/gh387-gate-not-first-executor.sh:29:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh387.XXXXXX")"
test/gh343-gate-program-target-root.sh:9:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh343-gate-program-target-root.XXXXXX")"
test/hq-marathon-scan.sh:14:WORK="$(mktemp -d "${TMPDIR:-/tmp}/hq-marathon-scan.XXXXXX")"
test/ci-workflow.sh:74:require_marker "steps.route.outputs.pdda_needed == 'true'" "PDDA is path-routed instead of unconditional"
test/ate-run-variations.sh:8:#   - _clear_stale_index_lock: removes a planted .git/index.lock so reset can't wedge the loop
test/ate-run-variations.sh:21:WORK="$(mktemp -d "${TMPDIR:-/tmp}/ate-run-variations.XXXXXX")"
test/relay-escalation-not-stall.sh:28:tmp="\$(mktemp)"
test/signal-triage.sh:24:# Output: uses a TMPDIR-based triage dir — does not pollute the repo
test/signal-triage.sh:41:WORK="$(mktemp -d "${TMPDIR:-/tmp}/signal-triage-test.XXXXXX")"
test/pdda-local-checks.sh:29:  PDDA_GH_STATE_CACHE="$TMP/.pdda-gh-state.tsv" \
test/pdda-local-checks.sh:35:printf '601\tCLOSED\n602\tOPEN\n' >"$TMP/.pdda-gh-state.tsv"
test/swe-diagram.sh:18:WORK="$(mktemp -d -t "swe-diagram.XXXXXX")"
test/gh419-gate-inventory.sh:7:FIXTURE="$(mktemp -d "${TMPDIR:-/tmp}/gh419-gate-inventory.XXXXXX")"
test/deep-research.sh:10:WORK="$(mktemp -d -t deep-research-test.XXXXXX)"
test/improve-loop-qa.sh:16:W="${TMPDIR:-/tmp}/il-qa.$$"; rm -rf "$W"; mkdir -p "$W"
test/find-harness.sh:14:mkrepo() { _repo="$(mktemp -d "${TMPDIR:-/tmp}/fh-case.XXXXXX")"; git -C "$_repo" init -q; printf '%s\n' "$_repo"; }
test/find-harness.sh:41:FR="$(mktemp -d "${TMPDIR:-/tmp}/fh-foreign.XXXXXX")"; git -C "$FR" init -q
test/find-harness.sh:49:FV="$(mktemp -d "${TMPDIR:-/tmp}/fh-vendored.XXXXXX")"; git -C "$FV" init -q
test/relay-review-once.sh:32:tmp="\$(mktemp)"; sed 's/^STATUS:.*/STATUS: Changes requested/' "$A/relayRC.md" > "\$tmp" && mv "\$tmp" "$A/relayRC.md"
test/relay-review-once.sh:50:tmp="\$(mktemp)"; sed 's/^STATUS:.*/STATUS: Approved/' "$A/relayAP.md" > "\$tmp" && mv "\$tmp" "$A/relayAP.md"
test/relay-review-once.sh:71:tmp="\$(mktemp)"; sed 's/^STATUS:.*/STATUS: Escalated/' "$A/relayES.md" > "\$tmp" && mv "\$tmp" "$A/relayES.md"
test/_setup.sh:51:WORK="$(mktemp -d -t "tick-${TEST_NAME}.XXXXXX")"
test/xyz-harness-hooks.sh:289:tmp="\$(mktemp)"; sed 's/^STATUS:.*/STATUS: Approved/' "\$RELAY_FILE" > "\$tmp" && mv "\$tmp" "\$RELAY_FILE"
test/roadmap-dashboard.sh:10:#   2. Nothing here ever writes $ROOT/ROADMAP-DASHBOARD.md. Write-mode is exercised against a
test/roadmap-dashboard.sh:22:ARTIFACT="$ROOT/ROADMAP-DASHBOARD.md"
test/roadmap-dashboard.sh:34:# GH-110 P2b: ROADMAP-DASHBOARD.md is a repo-root artifact that does not travel with a vendored
test/roadmap-dashboard.sh:36:# there is nothing here to render/check, so skip the whole ROADMAP-DASHBOARD.md-dependent case
test/roadmap-dashboard.sh:40:TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/roadmap-dashboard-test.XXXXXX")"
test/roadmap-dashboard.sh:53:  fail "committed ROADMAP-DASHBOARD.md is stale — regenerate it with 'bash utils/roadmap-dashboard.sh'"$'\n'"$out"
test/roadmap-dashboard.sh:110:# The old version regenerated $ROOT/ROADMAP-DASHBOARD.md as a side effect, so `validate.sh` could
test/roadmap-dashboard.sh:115:  fail "this test MUTATED \$ROOT/ROADMAP-DASHBOARD.md — the GH-351 side effect is back"
test/roadmap-dashboard.sh:199:  skip "ROADMAP-DASHBOARD.md-dependent checks need \$ROOT/ROADMAP-DASHBOARD.md (absent in a vendored copy)"
test/gh388-run-log-durability.sh:42:for p in /tmp/x.log /private/tmp/x /var/tmp/y /dev/shm/z "$ROOT_DIR/relay-system/logs/a.log" /usr/local/share/keepme; do
test/gh388-run-log-durability.sh:58:xyz_path_is_durable /tmp/whatever \
test/gh388-run-log-durability.sh:79:# answered with a $TMPDIR path and said nothing at all.
test/gh388-run-log-durability.sh:95:  *"$WORK"*|*TMPDIR*|*/tmp/*|*/var/folders/*)
test/xyz-completion.sh:27:WORK="$(mktemp -d "${TMPDIR:-/tmp}/xyz-completion.XXXXXX")"
test/driver-lock.sh:14:LOCK="$A/.git/relay-driver.lock"
test/hq-dispatch.sh:14:TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
test/hq-dispatch.sh:22:mk_repo(){ local d="$1"; git init -q "$d"; mkdir -p "$d/PROJECT/2-WORKING"; printf 'observe\n' > "$d/.pdda-mode"; }
test/marathon-monitor.sh:6:#       - Normal clone: .git/relay-driver.lock/pid
test/marathon-monitor.sh:30:_tmp="${TMPDIR:-/tmp}"; D="${_tmp%/}/marathon-monitor-test.$$"   # strip trailing slash so paths never contain '//'
test/marathon-monitor.sh:78:# Create .git/relay-driver.lock/pid with our own PID (definitely alive).
test/marathon-monitor.sh:79:mkdir -p "$REPO_LIVE/.git/relay-driver.lock"
test/marathon-monitor.sh:80:printf '%s\n' "$$" > "$REPO_LIVE/.git/relay-driver.lock/pid"
test/marathon-monitor.sh:165:  && pass "LIVE: clone with .git/relay-driver.lock + live pid -> LIVE" \
test/marathon-monitor.sh:199:# Sanity: lock-path distinction — STALE uses vendored lock, LIVE uses .git/ lock.
test/marathon-monitor.sh:201:[ -d "$REPO_LIVE/.git/relay-driver.lock" ] \
test/marathon-monitor.sh:202:  && pass "LIVE fixture has .git/relay-driver.lock (clone path)" \
test/marathon-monitor.sh:203:  || fail "LIVE fixture missing .git/relay-driver.lock"
test/hq-park-synthesis.sh:15:TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
test/hq-park-synthesis.sh:23:printf 'observe\n' > "$BETA/.pdda-mode"
test/hq-park-synthesis.sh:78:  [ -f "$BETA/ROADMAP-DASHBOARD.md" ] && pass "ROADMAP-DASHBOARD.md regenerated after --create" || fail "dashboard was not regenerated"
test/hq-park-synthesis.sh:79:  grep -q 'GH-900' "$BETA/ROADMAP-DASHBOARD.md" 2>/dev/null && pass "regenerated dashboard reflects the new ROADMAP pointer" || fail "dashboard content stale/missing the new entry"
test/hq-park-synthesis.sh:86:rm -f "$BETA/ROADMAP-DASHBOARD.md" "$BETA/utils/roadmap-dashboard.sh"
test/hq-park-synthesis.sh:90:[ -f "$BETA/ROADMAP-DASHBOARD.md" ] && fail "a dashboard file appeared despite the script being absent" || pass "no phantom dashboard file when the script is absent"
test/path-integrity.sh:104:# fixtures to "$FIXTURE/test/<name>.sh" under a mktemp root and then asserts on the inventory KEYS
test/measure.sh:33:T="${TMPDIR:-/tmp}/measure-noise.$$"; echo 0 >"$T"
test/measure.sh:39:ERR="${TMPDIR:-/tmp}/measure-err.$$"
test/relay-target-root-relayfile.sh:14:mkdir -p "$B/relay-system/2026-06-24"
test/relay-target-root-relayfile.sh:15:REL="relay-system/2026-06-24/demo.md"
test/new-relay.sh:10:out1="$(bash "$NR" --title "Review My PR" --reviewer codex --artifact-file /tmp/some-pr.diff --print)"
test/gh342-sentinel-debug-log-python.sh:157:md.xyz_debug_log_append(root, "warn", "marathon.lane-park", "m", target_root="/tmp/other")
test/gh342-sentinel-debug-log-python.sh:159:if row["scope"] == "target:/tmp/other" and row["repo"] == "/tmp/other":
test/gh342-sentinel-debug-log-python.sh:201:         "a/b.md", "act", "probe-1", "p3", "TASK-3", "/tmp/target-repo"),
test/gh342-sentinel-debug-log-python.sh:269:md.xyz_harvest_findings(harvest, "relay.md", root, "/tmp/tr", os.path.join(root, "debug.log"))
test/gh342-sentinel-debug-log-python.sh:272:    if "--relay" in argv and "relay.md" in argv and "target:/tmp/tr" in argv:
test/gh342-sentinel-debug-log-python.sh:315:LOCK="$A/.git/relay-driver.lock"
test/gh292-worktree-vendored-discovery.sh:9:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh292-worktree.XXXXXX")"
test/gh292-worktree-vendored-discovery.sh:13:# The `&&` before each `exit` is deliberate, not a typo: test/mktemp-trap-guard.sh
test/gh292-worktree-vendored-discovery.sh:16:[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "  FAIL: mktemp -d produced no usable dir" >&2 && exit 1; }
test/gh492-idle-kill.sh:23:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh492-idle.XXXXXX")"
test/relay-self-sufficiency.sh:63:WORK="$(mktemp -d -t "tick-relay-self-sufficiency.XXXXXX")"
test/mktemp-trap-guard.sh:2:# test/mktemp-trap-guard.sh — GH-177 regression guard: static audit for the pattern that rm -rf'd
test/mktemp-trap-guard.sh:5:# Root cause (see PROJECT/2-WORKING/GH-177-MKTEMP-TRAP-REPO-WIPE.md): `mktemp -d` can fail silently
test/mktemp-trap-guard.sh:8:# `cd "$(mktemp -d)" && pwd -P` converts a failed mktemp into a valid-looking, NON-EMPTY path: the
test/mktemp-trap-guard.sh:10:# NOTE this is NOT the same risk as a bare `VAR="$(mktemp -d)"` with no `cd`-wrap: if mktemp fails
test/mktemp-trap-guard.sh:15:# node_modules) for the shape that is actually dangerous, whether inline or split across lines:
test/mktemp-trap-guard.sh:16:#   (1) the exact historical idiom `cd "$(mktemp` / `cd $(mktemp` on one line — unsafe regardless of
test/mktemp-trap-guard.sh:17:#       what follows, because `cd` swallows mktemp's failure silently and can turn it into a hit.
test/mktemp-trap-guard.sh:18:#   (2) a variable assigned from `mktemp` that is later `cd`'d into (`cd "$VAR"`) — one or more lines
test/mktemp-trap-guard.sh:30:echo "== test: mktemp-trap-guard (GH-177) =="
test/mktemp-trap-guard.sh:34:# gitignored (node_modules, .tick, etc.) by construction (find only walks what's listed).
test/mktemp-trap-guard.sh:54:      find "$REPO/$d" -type f -not -path '*/node_modules/*' -not -name '*.sh' -print | while IFS= read -r _cand; do
test/mktemp-trap-guard.sh:57:      find "$REPO/$d" -type f -name '*.sh' -not -path '*/node_modules/*'
test/mktemp-trap-guard.sh:72:  # Never flag THIS file for quoting the pattern in its own header comment / for the word "mktemp"
test/mktemp-trap-guard.sh:73:  # appearing in prose — only real code lines matter, and this file has no mktemp assignment of its
test/mktemp-trap-guard.sh:81:  # multi-statement chain — `TMP="$(mktemp -d)"; cd "$TMP"` (or `; TMP="$(cd "$TMP" && pwd)"`) all on
test/mktemp-trap-guard.sh:106:    if [[ "$line" =~ cd[[:space:]]+\"?\$\(.*mktemp ]]; then
test/mktemp-trap-guard.sh:107:      fail "$rel:${seg_ln[$idx]} unsafe 'cd \$(mktemp ...)' idiom — cd \"\" silently succeeds and stays at cwd if mktemp fails, instead of erroring: ${line#"${line%%[![:space:]]*}"}"
test/mktemp-trap-guard.sh:110:    # --- Tier 2: a var assigned from mktemp, later `cd`'d into without a real guard first ------------
test/mktemp-trap-guard.sh:115:    # exit-status check chained directly onto the mktemp assignment itself) has NOT already appeared:
test/mktemp-trap-guard.sh:117:    #       swallowed mktemp failure into a persisted, valid-looking PATH string (the split-line twin
test/mktemp-trap-guard.sh:118:    #       of Tier 1's inline `cd "$(mktemp ...)" && pwd`).
test/mktemp-trap-guard.sh:127:    # `||` on the assignment itself, but that's STILL too loose: `TMP="$(mktemp -d)" || true` doesn't
test/mktemp-trap-guard.sh:130:    # naming $VAR on some later line — a real `X="$(mktemp -d)" || { ...; exit 1; }` still passes fine
test/mktemp-trap-guard.sh:134:    # segment, so a declaration-prefixed assignment (`local TMP="$(mktemp -d)"`, `declare TMP=...`,
test/mktemp-trap-guard.sh:137:    local decl_re='^[[:space:]]*(local[[:space:]]+|declare[[:space:]]+|export[[:space:]]+|typeset[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)=.*mktemp'
test/mktemp-trap-guard.sh:144:      # failure, so mktemp failure still flows straight through to the dangerous path. Fail-closed now:
test/mktemp-trap-guard.sh:155:      # chains (`TMP="$(mktemp -d)" && cd "$TMP"`, `... || TMP="$(cd "$TMP" && pwd)"`) — the chained
test/mktemp-trap-guard.sh:175:          fail "$rel:${seg_ln[$idx]} \$$var assigned from mktemp, then RE-CAPTURED via '\$(cd \"\$$var\" && ...)' at ${rel}:${seg_ln[$j]} with no non-empty/is-directory guard in between — same shape as the historical repo-wipe (GH-177), just split across lines/statements"
test/mktemp-trap-guard.sh:181:          # is fooled by the mktemp call's OWN parens on the same segment (`TMP="$(mktemp -d)" && cd
test/mktemp-trap-guard.sh:182:          # "$TMP"` has a `(` before "cd" from "$(mktemp", but it's already CLOSED — not wrapping the
test/mktemp-trap-guard.sh:188:            fail "$rel:${seg_ln[$idx]} \$$var assigned from mktemp, then BARE 'cd \"\$$var\"' at ${rel}:${seg_ln[$j]} (not scoped inside a subshell) with no non-empty/is-directory guard first — changes the script's own cwd unconditionally if mktemp failed, same failure class as GH-177"
test/mktemp-trap-guard.sh:207:  echo "  mktemp-trap-guard: $PASS passed, $FAIL failed"
test/mktemp-trap-guard.sh:211:pass "audited ${#FILES[@]} shell scripts under ${SCAN_DIRS[*]} (*.sh + extensionless bash-shebang executables) — no unguarded mktemp-into-destructive-rm-rf pattern found"
test/mktemp-trap-guard.sh:212:echo "  mktemp-trap-guard: $PASS passed, $FAIL failed"
test/gh400-source-url.sh:27:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh400-srcurl.XXXXXX")"
test/improve-loop-dogfood.sh:17:W="${TMPDIR:-/tmp}/il-dogfood.$$"; rm -rf "$W"; mkdir -p "$W"
test/loop-cost.sh:12:run(){ ERRF="${TMPDIR:-/tmp}/lc-err.$$"; OUT="$(bash "$L" "$@" 2>"$ERRF")"; RC=$?; HON="$(tail -1 "$ERRF")"; rm -f "$ERRF"; }
test/gh376-relay-drive-lock-parity.sh:7:# dir, and relay-drive's own inline 2-branch guess (.git is a dir -> .git/…, ELSE a hidden lock beside
test/gh376-relay-drive-lock-parity.sh:51:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh376.XXXXXX")"
test/gh376-relay-drive-lock-parity.sh:52:# GH-177: guard BEFORE the physical re-capture and BEFORE the rm -rf trap is armed. A failed mktemp
test/gh376-relay-drive-lock-parity.sh:56:[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "  FAIL: mktemp -d produced no usable dir" >&2 && exit 1; }
test/gh376-relay-drive-lock-parity.sh:58:# `rev-parse --path-format=absolute --git-common-dir`, and on macOS $TMPDIR lives under /var, a
test/gh376-relay-drive-lock-parity.sh:59:# symlink to /private/var. A $TMPDIR-derived expected string would never equal git's answer.
test/gh376-relay-drive-lock-parity.sh:91:COMMON_LOCK="$MAIN/.git/relay-driver.lock"
test/gh376-relay-drive-lock-parity.sh:179:       '            lock_label = ".git/relay-driver.lock"\n'
test/gh376-relay-drive-lock-parity.sh:195:  if [ -d "$repo/.git" ]; then printf '%s/.git/relay-driver.lock' "$repo"
test/gh376-relay-drive-lock-parity.sh:227:  && pass "CONTROL (python): a normal clone still excludes at .git/relay-driver.lock" \
test/gh376-relay-drive-lock-parity.sh:230:  && pass "CONTROL (bash): a normal clone still excludes at .git/relay-driver.lock" \
test/security-scan.sh:30:# Use TMPDIR for all fixture files — hermetic, never touches the real repo tree.
test/security-scan.sh:31:WORK="$(mktemp -d "${TMPDIR:-/tmp}/sec-scan-test.XXXXXX")"
test/relay-xyz-skill-guard.sh:12:export TMPDIR="$WORK/tmp"; mkdir -p "$TMPDIR"
test/relay-xyz-skill-guard.sh:28:DRIVE="bash relay-automation/relay-drive.sh --relay-file relay-system/2026-06-24/t.md --round-cap 4"
test/relay-target-root-paths.sh:19:REL_REL="relay-system/2026-06-24/thread.md"
test/relay-target-root-paths.sh:40:printf '\n### Round 1 · Agent\n' >> "relay-system/2026-06-24/thread.md"
test/gh399-packet-acceptance-continuation.sh:28:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh399-continuation.XXXXXX")"
test/gh399-packet-acceptance-continuation.sh:150:# .git/relay-driver.lock in the live repo — hence also the hard timeout below: an unattended suite
test/registry-lock-concurrency.sh:40:TMP="$(mktemp -d "${TMPDIR:-/tmp}/gh72.XXXXXX")"
test/sentinel-driver-hooks.sh:14:WORK="$(mktemp -d "${TMPDIR:-/tmp}/sentinel-driver.XXXXXX")"
test/gh422-backfill-source-url.sh:29:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh422-backfill.XXXXXX")"
test/acorn-extract.sh:14:WORK="$(mktemp -d "${TMPDIR:-/tmp}/acorn-extract-test.XXXXXX")"
test/oracle-guard.sh:54:  SL="${TMPDIR:-/tmp}/og-alias.$$.sh"; ln -sf "$ROOT/validate.sh" "$SL"
test/hq-next.sh:13:TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
test/hq-next.sh:26:TOP="$TMP/repos/top-proj"; mkdir -p "$TOP/.git"; printf 'observe\n' > "$TOP/.pdda-mode"
test/pdda-roadmap-coverage.sh:95:GH_CACHE="$TMP/.pdda-gh-state.tsv"
test/gh390-timeout-attribution.sh:15:TMP="$(mktemp -d "${TMPDIR:-/tmp}/gh390-timeout-attr.XXXXXX")"
test/checkjs.sh:25:WORK="$(mktemp -d "${TMPDIR:-/tmp}/checkjs-test.XXXXXX")"
test/hq-hardening.sh:15:# GH-177: mktemp -d can fail silently under a sandboxed shell (empty stdout, non-zero rc). The old
test/hq-hardening.sh:16:# `cd "$(mktemp -d)" && pwd -P` idiom let `cd ""` succeed and silently stay at the CWD (the repo
test/hq-hardening.sh:18:# Verify mktemp actually succeeded and returned a real directory BEFORE it's wired into a destructive
test/hq-hardening.sh:20:TMP="$(mktemp -d)" || { echo "FAIL: mktemp -d failed" >&2; exit 1; }
test/hq-hardening.sh:21:[ -n "$TMP" ] && [ -d "$TMP" ] || { echo "FAIL: mktemp -d returned an invalid path" >&2; exit 1; }
test/marathon-plan.sh:16:WORK="$(mktemp -d "${TMPDIR:-/tmp}/marathon-plan.XXXXXX")"
test/transcript-audit.sh:24:FIXTURE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/transcript-audit.XXXXXX")"
test/transcript-audit.sh:40:  ls relay-system/2026-06-14/
test/transcript-audit.sh:43:  ls relay-system/2026-06-14/
test/transcript-audit.sh:46:  ls relay-system/2026-06-14/
test/transcript-audit.sh:49:  ls relay-system/2026-06-14/
test/relay-turn-trace.sh:72:# failure silently produced `${TMPDIR}/codex-turn-$$.log` and "never propagated the failure to the
test/aider-turn.sh:87:  tmp="$(mktemp)"; sed 's/^STATUS:.*/STATUS: Approved/' "$relay" > "$tmp" && mv "$tmp" "$relay"
test/agent2agent.sh:9:WORK="$(mktemp -d "${TMPDIR:-/tmp}/agent2agent-test.XXXXXX")" || {
test/agent2agent.sh:10:  echo "FAIL: mktemp -d failed" >&2
test/agent2agent.sh:14:  echo "FAIL: mktemp -d returned an invalid directory" >&2
test/agent2agent.sh:18:  "${TMPDIR:-/tmp}"/agent2agent-test.*) ;;
test/agent2agent.sh:210:mkdir -p "$AMBIG/relay-system/2026-08-10" "$AMBIG/relay-system/2026-08-11"
test/agent2agent.sh:213:cp "$ambig_source" "$AMBIG/relay-system/2026-08-10/445566-agent2agent-duplicate.md"
test/relay-turn-handoff.sh:25:  local dir; dir="$(mktemp -d "${TMPDIR:-/tmp}/relay-handoff.XXXXXX")"
test/gh400-acceptance-fidelity.sh:27:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh400-acceptance.XXXXXX")"
test/gh509-gate-evidence.sh:39:[ -f "$R1/.gate-evidence/$sha1.txt" ] \
test/gh509-gate-evidence.sh:41:  || fail "GH-509: no record at .gate-evidence/<sha>.txt"
test/gh509-gate-evidence.sh:42:/usr/bin/grep -q "commit: $sha1" "$R1/.gate-evidence/$sha1.txt" \
test/gh509-gate-evidence.sh:48:/usr/bin/grep -q "NOT-promotion-evidence" "$R1/.gate-evidence/$sha1.txt" \
test/gh509-gate-evidence.sh:59:[ -d "$R2/.gate-evidence" ] \
test/gh509-gate-evidence.sh:60:  && fail "GH-509: a refused run still created .gate-evidence — the refusal is cosmetic" \
test/gh417-turn-root-symlink-prefix.sh:48:# Built explicitly rather than leaning on $TMPDIR's shape. macOS gives /var -> /private/var for free,
test/gh417-turn-root-symlink-prefix.sh:49:# but Linux CI does not, and a sandbox can rewrite $TMPDIR to an already-physical path -- in either
test/gh448-driver-lock-resolver.sh:28:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh448-driver-lock.XXXXXX")"
test/gh448-driver-lock-resolver.sh:29:# GH-177: guard BEFORE the re-capture below and BEFORE the rm -rf trap is armed. A failed mktemp
test/gh448-driver-lock-resolver.sh:32:# shape, and test/mktemp-trap-guard.sh caught this exact omission in CI when the re-capture was
test/gh448-driver-lock-resolver.sh:37:[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "  FAIL: mktemp -d produced no usable dir" >&2 && exit 1; }
test/gh448-driver-lock-resolver.sh:40:# path; on macOS $TMPDIR lives under /var, a symlink to /private/var, so a $TMPDIR-derived expected
test/gh448-driver-lock-resolver.sh:91:COMMON_LOCK="$MAIN_REPO/.git/relay-driver.lock"
test/gh448-driver-lock-resolver.sh:121:  if [ -d "$repo/.git" ]; then printf '%s/.git/relay-driver.lock' "$repo"
test/gh448-driver-lock-resolver.sh:128:  [ -e "$repo/.git/relay-driver.lock" ] && { printf '%s' "$repo/.git/relay-driver.lock"; return 0; }
test/gh448-driver-lock-resolver.sh:143:  pass "negative control: old marathon-live.sh logic (checks .git/… or .xyz/… under \$WT) misses the held lock"
test/gh448-driver-lock-resolver.sh:147:for _lk in "$WT/.git/relay-driver.lock" "$WT/.relay-driver.lock"; do
test/gh448-driver-lock-resolver.sh:219:HARNESS_COMMON_LOCK="$HARNESS_MAIN/.git/relay-driver.lock"
test/synthetic/synthetic-claude-target-root.sh:3:export TARGET_ROOT="/tmp/dummy-root"
test/rtl-orphan-backup.sh:23:WORK="$(mktemp -d "${TMPDIR:-/tmp}/rtl-orphan-backup.XXXXXX")"
test/rtl-orphan-backup.sh:24:[[ -n "$WORK" && -d "$WORK" && "$WORK" != "/" ]] || { echo "FATAL: mktemp -d failed"; exit 1; }
test/relay-dep-drift.sh:24:  local dir; dir="$(mktemp -d "${TMPDIR:-/tmp}/dep-drift.XXXXXX")"
test/gh358-lock-instrumentation.sh:8:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh358-lock-instrumentation.XXXXXX")"
test/gh358-lock-instrumentation.sh:26:if TMPDIR="$clobber_dir" XYZ_COMPLETION_TEST_CLOBBER_SESSION_ID=conc-1 bash "$XYZ_TEST" >"$clobber_log" 2>&1; then
test/gh358-lock-instrumentation.sh:46:TMPDIR="$starve_dir" XYZ_COMPLETION_WRITER_LOCK_WAIT_S=1 bash "$XYZ_TEST" >"$starve_log" 2>&1 &
test/sentinel-overlay.sh:17:WORK="$(mktemp -d "${TMPDIR:-/tmp}/sentinel-overlay.XXXXXX")"
test/hq-rollup.sh:22:WORK="$(mktemp -d "${TMPDIR:-/tmp}/hq-rollup.XXXXXX")"
test/gh304-vendored-relay-path.sh:33:REL=".xyz/relay-system/2026-07-24/gh304.md"
test/gh304-vendored-relay-path.sh:87:IGN="relay-system/2026-07-24/gh304-ignored.md"
test/gh410-containment-advisory.sh:27:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh410.XXXXXX")"
test/swarm-preflight.sh:15:WORK="$(mktemp -d "${TMPDIR:-/tmp}/swarm-preflight.XXXXXX")"
test/swarm-preflight.sh:692:TMP="$(mktemp -d)"
test/swarm-preflight.sh:867:# ── T36 (GH-127): isFsTouching also catches a bare '>' redirect (not just cat>/>>/ mktemp/etc.), while
test/swarm-preflight.sh:913:# ── T37/T38/T39 (GH-203): a stale, unheld .git/index.lock is advisory only — warn in both text and
test/swarm-preflight.sh:923:: >"$R/.git/index.lock"
test/swarm-preflight.sh:927:grep -q "stale git index lock detected at $R_CANON/.git/index.lock" <<<"$out" \
test/swarm-preflight.sh:939:    j.freshness.stale_index_lock_warning.includes("rm .git/index.lock") &&
test/swarm-preflight.sh:942:' "$R_CANON/.git/index.lock" <<<"$sj" \
test/gh425-source-url-slug.sh:9:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh425-source-url-slug.XXXXXX")"
test/champion.sh:10:D="${TMPDIR:-/tmp}/champion-test.$$"; rm -rf "$D"
test/champion.sh:39:Dm="${TMPDIR:-/tmp}/champion-min.$$"; rm -rf "$Dm"
test/champion.sh:48:bash "$C" init "${TMPDIR:-/tmp}/champion-bad.$$" --metric notanumber >/dev/null 2>&1; rc=$?
test/gh308-consult-guards.sh:16:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh308-consult-guards.XXXXXX")"
test/test-agy-standalone-repo.sh:4:rm -rf /tmp/wt-test
test/test-agy-standalone-repo.sh:5:mkdir -p /tmp/wt-test
test/test-agy-standalone-repo.sh:6:cd /tmp/wt-test
test/nightwatch-release.sh:211:  TMP="$(mktemp -d)"
test/sentinel-network-guard.sh:14:WORK="$(mktemp -d "${TMPDIR:-/tmp}/sentinel-network.XXXXXX")"
test/hq.sh:14:TMP="$(mktemp -d)"
test/hq.sh:27:printf 'observe\n' > "$ACME/.pdda-mode"
test/hq-locator.sh:16:# Canonicalize: macOS mktemp yields /var/folders/… but the locator returns pwd -P
test/hq-locator.sh:18:# GH-177: mktemp -d can fail silently under a sandboxed shell (empty stdout, non-zero rc). The old
test/hq-locator.sh:19:# `cd "$(mktemp -d)" && pwd -P` idiom let `cd ""` succeed and silently stay at the CWD (the repo
test/hq-locator.sh:21:# Verify mktemp actually succeeded and returned a real directory BEFORE it's wired into a destructive
test/hq-locator.sh:23:TMP="$(mktemp -d)" || { echo "FAIL: mktemp -d failed" >&2; exit 1; }
test/hq-locator.sh:24:[ -n "$TMP" ] && [ -d "$TMP" ] || { echo "FAIL: mktemp -d returned an invalid path" >&2; exit 1; }
test/gh308-frozen-twin-guard.sh:329:tmp="$(mktemp -d "${TMPDIR:-/tmp}/gh308-frozen-twin.XXXXXX")"
test/gh308-frozen-twin-guard.sh:362:exc="$(mktemp -d "${TMPDIR:-/tmp}/gh308-exceptions.XXXXXX")"
test/hq-park.sh:17:TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
test/hq-park.sh:27:printf 'observe\n' > "$BETA/.pdda-mode"
test/marathon-closeout.sh:15:WORK="$(mktemp -d -t marathon-closeout.XXXXXX)" || { echo "FAIL: mktemp failed" >&2; exit 1; }
test/sentinel-tier1.sh:12:WORK="$(mktemp -d "${TMPDIR:-/tmp}/sentinel-tier1.XXXXXX")"
test/improve-loop.sh:10:W="${TMPDIR:-/tmp}/improve-loop-test.$$"; rm -rf "$W"; mkdir -p "$W"
test/gh418-issue-state-frozen.sh:14:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh418-preflight.XXXXXX")"
test/lane-attempt-cap.sh:9:WORK="$(mktemp -d -t "lane-attempt-cap.XXXXXX")"

2026-08-13T17:20:12.634180Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 95 column 5
exec
/bin/zsh -lc "nl -ba test/transcript-audit.sh | sed -n '1,220p'; nl -ba test/marathon-root-audit.sh | sed -n '1,260p'; nl -ba test/gh331-cost-summary.sh | sed -n '1,230p'; nl -ba test/gh376-relay-drive-lock-parity.sh | sed -n '1,260p'; nl -ba test/gh407-gate-ran-attribution.sh | sed -n '1,190p'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-86418-h4t1yue0
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	# test/transcript-audit.sh — GH-66: hermetic tests for utils/transcript-audit.sh
     4	#
     5	# Tests:
     6	#   1. stale-ref detection
     7	#   2. repeat-explore detection
     8	#   3. unbounded-stall detection
     9	#   4. read-only guarantee (fixture bytes/mtimes unchanged after audit run)
    10	#   5. non-existent dir exits 0 with clean report
    11	
    12	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    13	AUDIT_SCRIPT="$(cd "$HERE/.." && pwd)/utils/transcript-audit.sh"
    14	
    15	PASS=0
    16	FAIL=0
    17	
    18	pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
    19	fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }
    20	
    21	echo "== test: transcript-audit =="
    22	
    23	# ── build hermetic fixture dir ─────────────────────────────────────────────────
    24	FIXTURE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/transcript-audit.XXXXXX")"
    25	trap 'rm -rf "$FIXTURE_DIR"' EXIT
    26	
    27	# Fixture 1: stale-ref — references a .bak file and a deprecated path
    28	cat >"$FIXTURE_DIR/stale-ref-transcript.md" <<'EOF'
    29	Turn 1
    30	  Reading OLD_config.bak to understand the old layout.
    31	  cat relay-automation/relay-loop.sh.OLD
    32	  source ./utils/deprecated_helper.bak
    33	  STATUS: Open
    34	  DECISION: continue
    35	EOF
    36	
    37	# Fixture 2: repeat-explore — ls the same directory 4 times (above threshold of 3)
    38	cat >"$FIXTURE_DIR/repeat-explore-transcript.md" <<'EOF'
    39	Turn 1
    40	  ls relay-system/2026-06-14/
    41	  Did not find what I needed.
    42	Turn 2
    43	  ls relay-system/2026-06-14/
    44	  Still looking.
    45	Turn 3
    46	  ls relay-system/2026-06-14/
    47	  Still the same.
    48	Turn 4
    49	  ls relay-system/2026-06-14/
    50	  Finally found it.
    51	  STATUS: Open
    52	  DECISION: proceed
    53	EOF
    54	
    55	# Fixture 3: unbounded-stall — no terminal marker at all
    56	cat >"$FIXTURE_DIR/stalled-transcript.md" <<'EOF'
    57	Turn 1
    58	  I am exploring the codebase.
    59	Turn 2
    60	  ls relay-system/
    61	  Reading some files...
    62	Turn 3
    63	  Still processing, no exit, no STATUS, no DECISION.
    64	EOF
    65	
    66	# ── capture checksums BEFORE audit run ────────────────────────────────────────
    67	if command -v md5sum >/dev/null 2>&1; then
    68	  CHECKSUM_BEFORE="$(md5sum "$FIXTURE_DIR"/*.md | sort)"
    69	elif command -v md5 >/dev/null 2>&1; then
    70	  # macOS
    71	  CHECKSUM_BEFORE="$(for f in "$FIXTURE_DIR"/*.md; do md5 -r "$f"; done | sort)"
    72	else
    73	  CHECKSUM_BEFORE="$(ls -la "$FIXTURE_DIR"/*.md)"
    74	fi
    75	
    76	# Also capture mtimes (macOS stat -f %m, GNU stat -c %Y)
    77	if stat -f '%m %N' "$FIXTURE_DIR"/*.md >/dev/null 2>&1; then
    78	  MTIME_BEFORE="$(stat -f '%m %N' "$FIXTURE_DIR"/*.md | sort)"
    79	else
    80	  MTIME_BEFORE="$(stat -c '%Y %n' "$FIXTURE_DIR"/*.md | sort)"
    81	fi
    82	
    83	# ── run the audit against the fixture dir ─────────────────────────────────────
    84	AUDIT_OUTPUT="$(bash "$AUDIT_SCRIPT" "$FIXTURE_DIR" 2>&1)"
    85	AUDIT_RC=$?
    86	
    87	echo "  audit output:"
    88	echo "$AUDIT_OUTPUT" | sed 's/^/    /'
    89	
    90	# ── Test 1: stale-ref finding ─────────────────────────────────────────────────
    91	if echo "$AUDIT_OUTPUT" | grep -qF 'AUDIT stale-ref'; then
    92	  pass "stale-ref: audit emitted stale-ref finding"
    93	else
    94	  fail "stale-ref: no 'AUDIT stale-ref' line found in output"
    95	fi
    96	
    97	# ── Test 2: repeat-explore finding ───────────────────────────────────────────
    98	if echo "$AUDIT_OUTPUT" | grep -qE 'AUDIT repeat-explore .+ count=[0-9]+'; then
    99	  pass "repeat-explore: audit emitted repeat-explore finding with count"
   100	else
   101	  fail "repeat-explore: no 'AUDIT repeat-explore ... count=N' line found in output"
   102	fi
   103	
   104	# ── Test 3: unbounded-stall finding ──────────────────────────────────────────
   105	if echo "$AUDIT_OUTPUT" | grep -qF 'AUDIT unbounded-stall'; then
   106	  pass "unbounded-stall: audit emitted unbounded-stall finding"
   107	else
   108	  fail "unbounded-stall: no 'AUDIT unbounded-stall' line found in output"
   109	fi
   110	
   111	# ── Test 4: read-only guarantee ───────────────────────────────────────────────
   112	if command -v md5sum >/dev/null 2>&1; then
   113	  CHECKSUM_AFTER="$(md5sum "$FIXTURE_DIR"/*.md | sort)"
   114	elif command -v md5 >/dev/null 2>&1; then
   115	  CHECKSUM_AFTER="$(for f in "$FIXTURE_DIR"/*.md; do md5 -r "$f"; done | sort)"
   116	else
   117	  CHECKSUM_AFTER="$(ls -la "$FIXTURE_DIR"/*.md)"
   118	fi
   119	
   120	if stat -f '%m %N' "$FIXTURE_DIR"/*.md >/dev/null 2>&1; then
   121	  MTIME_AFTER="$(stat -f '%m %N' "$FIXTURE_DIR"/*.md | sort)"
   122	else
   123	  MTIME_AFTER="$(stat -c '%Y %n' "$FIXTURE_DIR"/*.md | sort)"
   124	fi
   125	
   126	if [[ "$CHECKSUM_BEFORE" == "$CHECKSUM_AFTER" ]] && [[ "$MTIME_BEFORE" == "$MTIME_AFTER" ]]; then
   127	  pass "read-only: fixture checksums and mtimes unchanged after audit run"
   128	else
   129	  fail "read-only: fixture files were modified by the audit script (checksums or mtimes differ)"
   130	fi
   131	
   132	# ── Test 5: non-existent dir exits 0 ─────────────────────────────────────────
   133	NONEXISTENT_DIR="$FIXTURE_DIR/does-not-exist-ever"
   134	NODIR_OUTPUT="$(bash "$AUDIT_SCRIPT" "$NONEXISTENT_DIR" 2>&1)"
   135	NODIR_RC=$?
   136	
   137	if [[ "$NODIR_RC" -eq 0 ]]; then
   138	  pass "non-existent-dir: exits 0"
   139	else
   140	  fail "non-existent-dir: expected exit 0, got $NODIR_RC"
   141	fi
   142	
   143	if echo "$NODIR_OUTPUT" | grep -qE 'AUDIT (summary:|total )'; then
   144	  pass "non-existent-dir: clean structured report emitted (no crash, no error noise)"
   145	else
   146	  fail "non-existent-dir: expected a clean structured AUDIT line, got: $NODIR_OUTPUT"
   147	fi
   148	
   149	# ── also verify audit itself exited 0 on fixture run ─────────────────────────
   150	if [[ "$AUDIT_RC" -eq 0 ]]; then
   151	  pass "audit exit code: exits 0 (findings are a report, not a gate)"
   152	else
   153	  fail "audit exit code: expected 0, got $AUDIT_RC"
   154	fi
   155	
   156	# ── final summary ─────────────────────────────────────────────────────────────
   157	echo ""
   158	echo "transcript-audit: $PASS pass, $FAIL fail"
   159	
   160	[[ "$FAIL" -eq 0 ]]
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	
     4	HERE="$(cd "$(dirname "$0")" && pwd)"
     5	
     6	# GH-401: this audit exists for GH-209 — "every test invocation of the marathon driver is
     7	# MARATHON_ROOT-scoped" — but its scope was two hardcoded filenames. An unscoped `--dry-run`
     8	# invocation in test/gh268-relay-cue-and-target-checks.sh therefore wrote phases/p1/RELAY.md into
     9	# the HARNESS repo on every `bash validate.sh`, and the audit reported PASS the whole time: it was
    10	# out of reach because of its FILENAME, not because it was safe. A guard whose coverage is a literal
    11	# list silently stops covering the thing it was written for the moment someone adds a file.
    12	#
    13	# Audit every test script instead, and let discover_file_metadata/find_invocation_target decide what
    14	# is actually an invocation — a file with none is simply skipped. The audit excludes only itself:
    15	# it necessarily contains the driver path literals it matches on, so it would self-report.
    16	FILES=()
    17	for candidate in "$HERE"/*.sh; do
    18	  [ "$candidate" = "${BASH_SOURCE[0]}" ] && continue
    19	  [ "$(basename "$candidate")" = "$(basename "${BASH_SOURCE[0]}")" ] && continue
    20	  FILES+=("$candidate")
    21	done
    22	
    23	safe_vars=()
    24	alias_names=()
    25	alias_targets=()
    26	failures=0
    27	checked=0
    28	
    29	add_safe_var() {
    30	  local candidate="$1"
    31	  local existing
    32	  for existing in "${safe_vars[@]}"; do
    33	    [ "$existing" = "$candidate" ] && return 0
    34	  done
    35	  safe_vars+=("$candidate")
    36	}
    37	
    38	reset_safe_vars() {
    39	  safe_vars=(A B)
    40	}
    41	
    42	is_safe_var() {
    43	  local candidate="$1"
    44	  local existing
    45	  for existing in "${safe_vars[@]}"; do
    46	    [ "$existing" = "$candidate" ] && return 0
    47	  done
    48	  return 1
    49	}
    50	
    51	reset_aliases() {
    52	  alias_names=()
    53	  alias_targets=()
    54	}
    55	
    56	set_alias() {
    57	  local name="$1"
    58	  local target="$2"
    59	  local i
    60	  for ((i = 0; i < ${#alias_names[@]}; i++)); do
    61	    if [ "${alias_names[$i]}" = "$name" ]; then
    62	      alias_targets[$i]="$target"
    63	      return 0
    64	    fi
    65	  done
    66	  alias_names+=("$name")
    67	  alias_targets+=("$target")
    68	}
    69	
    70	get_alias_target() {
    71	  local name="$1"
    72	  local i
    73	  for ((i = 0; i < ${#alias_names[@]}; i++)); do
    74	    if [ "${alias_names[$i]}" = "$name" ]; then
    75	      printf '%s\n' "${alias_targets[$i]}"
    76	      return 0
    77	    fi
    78	  done
    79	  return 1
    80	}
    81	
    82	line_has_safe_cwd() {
    83	  local line="$1"
    84	  local candidate
    85	  if [[ "$line" =~ cd[[:space:]]+\"\$([A-Z][A-Z0-9_]*)\" ]]; then
    86	    candidate="${BASH_REMATCH[1]}"
    87	    is_safe_var "$candidate"
    88	    return $?
    89	  fi
    90	  return 1
    91	}
    92	
    93	discover_file_metadata() {
    94	  local file="$1"
    95	  local line name target
    96	
    97	  reset_safe_vars
    98	  reset_aliases
    99	
   100	  while IFS= read -r line || [ -n "$line" ]; do
   101	    if [[ "$line" =~ ^([A-Z][A-Z0-9_]*)=\"\$WORK/ ]]; then
   102	      add_safe_var "${BASH_REMATCH[1]}"
   103	    fi
   104	
   105	    if [[ "$line" =~ ^([A-Z][A-Z0-9_]*)=.*relay-automation/(marathon|marathon-drive)\.sh ]]; then
   106	      name="${BASH_REMATCH[1]}"
   107	      target="${BASH_REMATCH[2]}"
   108	      set_alias "$name" "$target"
   109	    fi
   110	  done < "$file"
   111	}
   112	
   113	find_invocation_target() {
   114	  local line="$1"
   115	  local rest var target
   116	
   117	  if [[ "$line" == *'./.xyz/relay-automation/marathon-drive.sh'* ]]; then
   118	    printf '%s\n' "marathon-drive"
   119	    return 0
   120	  fi
   121	
   122	  if [[ "$line" == *'./.xyz/relay-automation/marathon.sh'* ]]; then
   123	    printf '%s\n' "marathon"
   124	    return 0
   125	  fi
   126	
   127	  rest="${line#*bash \"\$}"
   128	  if [ "$rest" != "$line" ]; then
   129	    var="${rest%%\"*}"
   130	    target="$(get_alias_target "$var" || true)"
   131	    if [ -n "$target" ]; then
   132	      printf '%s\n' "$target"
   133	      return 0
   134	    fi
   135	  fi
   136	
   137	  return 1
   138	}
   139	
   140	check_invocation_safety() {
   141	  local idx="$1"
   142	  shift
   143	  local -a lines=("$@")
   144	  local start j boundary_found=0
   145	  local line="${lines[$idx]}"
   146	
   147	  if [[ "$line" == *'MARATHON_ROOT='* ]]; then
   148	    return 0
   149	  fi
   150	
   151	  if line_has_safe_cwd "$line"; then
   152	    return 0
   153	  fi
   154	
   155	  for ((j = idx - 1; j >= 0; j--)); do
   156	    if [[ "${lines[$j]}" == *'MARATHON_ROOT='* ]]; then
   157	      return 0
   158	    fi
   159	    if line_has_safe_cwd "${lines[$j]}"; then
   160	      return 0
   161	    fi
   162	    [[ "${lines[$j]}" =~ \\[[:space:]]*$ ]] || break
   163	  done
   164	
   165	  start=$((idx > 40 ? idx - 40 : 0))
   166	  for ((j = idx - 1; j >= start; j--)); do
   167	    if [[ "${lines[$j]}" =~ ^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(\)[[:space:]]*\{ ]]; then
   168	      start="$j"
   169	      boundary_found=1
   170	      break
   171	    fi
   172	    if [[ "${lines[$j]}" =~ ^[[:space:]]*\([[:space:]]*$ ]]; then
   173	      start="$j"
   174	      boundary_found=1
   175	      break
   176	    fi
   177	  done
   178	
   179	  [ "$boundary_found" -eq 1 ] || return 1
   180	
   181	  for ((j = start; j < idx; j++)); do
   182	    if [[ "${lines[$j]}" == *'MARATHON_ROOT='* ]]; then
   183	      return 0
   184	    fi
   185	    if line_has_safe_cwd "${lines[$j]}"; then
   186	      return 0
   187	    fi
   188	  done
   189	
   190	  return 1
   191	}
   192	
   193	audit_file() {
   194	  local file="$1"
   195	  local -a lines=()
   196	  local line target idx
   197	
   198	  discover_file_metadata "$file"
   199	
   200	  while IFS= read -r line || [ -n "$line" ]; do
   201	    lines+=("$line")
   202	  done < "$file"
   203	
   204	  for ((idx = 0; idx < ${#lines[@]}; idx++)); do
   205	    target="$(find_invocation_target "${lines[$idx]}" || true)"
   206	    [ -z "$target" ] && continue
   207	    checked=$((checked + 1))
   208	    if check_invocation_safety "$idx" "${lines[@]}"; then
   209	      printf 'PASS: %s:%d %s invocation is rooted or fixture-local\n' \
   210	        "${file#$HERE/}" "$((idx + 1))" "$target"
   211	    else
   212	      printf 'FAIL: %s:%d %s invocation lacks MARATHON_ROOT and fixture-local cwd\n' \
   213	        "${file#$HERE/}" "$((idx + 1))" "$target" >&2
   214	      failures=$((failures + 1))
   215	    fi
   216	  done
   217	}
   218	
   219	for file in "${FILES[@]}"; do
   220	  audit_file "$file"
   221	done
   222	
   223	if [ "$checked" -eq 0 ]; then
   224	  echo "FAIL: no real marathon script invocations found to audit" >&2
   225	  exit 1
   226	fi
   227	
   228	if [ "$failures" -ne 0 ]; then
   229	  echo "FAIL: $failures unsafe marathon invocation(s) found" >&2
   230	  exit 1
   231	fi
   232	
   233	echo "PASS: audited $checked real marathon invocation(s)"
   234	
   235	# ── the driver commits phase artifacts, so they must not be gitignored ────────────────────────────
   236	# marathon_drive.py stages phase output with `git add --` and check=True at three sites
   237	# (ESCALATION.md, the transcript, RELAY.md — line numbers deliberately not cited; they have drifted
   238	# twice already and a stale citation reads as precision it does not have). `git add` on an EXPLICIT path that .gitignore covers
   239	# exits 1 — "The following paths are ignored ... Use -f if you really want to add them" — so
   240	# check=True raises CalledProcessError and the phase dies while trying to record itself.
   241	#
   242	# Not hypothetical: `/phases/` was added to .gitignore on 2026-08-09 to stop the #401/#461 churn, and
   243	# it would have crashed the first new same-repo phase. Reverted the same day; this assertion is what
   244	# makes the revert stick. Verified directly before writing it: in a scratch repo ignoring /phases/,
   245	# `git add -- phases/newrun/RELAY.md` exits 1.
   246	#
   247	# If phase records should stop being committed, that is a driver change (and a #388 durability
   248	# question), not a .gitignore line — the ignore alone breaks the write without removing the intent.
   249	#
   250	# GH-484: the default moved to marathon-system/, so the NEW default is now the path that actually
   251	# matters. phases/ stays probed too — the driver no longer writes there, but a fleet repo whose
   252	# vendored .xyz/ has not re-synced still does, and this repo's committed pre-flip records live
   253	# there. An ignore rule on either name is a live crash for someone.
   254	audit_root="$(cd "$(dirname "$0")/.." && pwd)"
   255	ignore_violations=0
   256	for probe in marathon-system/audit-probe/RELAY.md marathon-system/audit-probe/ESCALATION.md \
   257	             phases/audit-probe/RELAY.md phases/audit-probe/ESCALATION.md; do
   258	  if git -C "$audit_root" check-ignore -q "$probe" 2>/dev/null; then
   259	    echo "FAIL: .gitignore covers $probe, but the driver stages it with \`git add --\` + check=True — a new same-repo phase would exit 1 while recording itself" >&2
   260	    ignore_violations=$((ignore_violations + 1))
     1	#!/usr/bin/env bash
     2	# test/gh331-cost-summary.sh — GH-331 / GH-308: the end-of-run `tick analyze` cost summary was
     3	# implemented only in the Bash twins (relay-drive.sh GH-152, marathon-drive.sh GH-222), so on the
     4	# DEFAULT lane (XYZ_PYTHON unset → Python, since GH-264) a driven run emitted NO cost visibility.
     5	# marathon was worse: it tells its nested relay-drive child RELAY_COST_SUMMARY=0, so with the parent's
     6	# own summary also absent a driven phase showed ZERO cost.
     7	#
     8	# Every invocation here drives the DEFAULT (Python) lane — that is the whole point of GH-308. Pins:
     9	#   (1) a driven relay-drive turn prints the cost block on the default lane;
    10	#   (2) RELAY_COST_SUMMARY=0 silences it;
    11	#   (3) the summary is ADDITIVE — it never changes the driven run's exit code (checked on a NON-zero
    12	#       exit path, and when `tick analyze` itself fails);
    13	#   (4) the same three properties for marathon-drive with MARATHON_COST_SUMMARY.
    14	#
    15	# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: hold the clone's .git/relay-driver.lock with a LIVE pid, then run this suite (that is the in-marathon condition; a linked worktree does NOT reproduce it because relay-drive takes a per-worktree lock there, GH-376). pre-fix revision: this file with RELAY_DRIVER_LOCKED unset but the relay-drive invocations unscoped. pre-fix result: FAIL rc=1 'another driver is active in this repo (pid 2436, lock: .git/relay-driver.lock)' — the same failure that halted Litmus wave-2 phase 1 on 2026-08-08 at 893s. post-fix result: 8 pass / 0 fail with the SAME lock still held, and 8 pass / 0 fail with no lock, so the fix is verified in both directions rather than only the one under investigation"}
    16	source "$(dirname "$0")/_setup.sh" gh331-cost-summary
    17	
    18	# GH-441 — hermetic against an ambient driver, same reason as test/driver-lock.sh:11. Every
    19	# assertion here drives relay-drive/marathon-drive against this suite's own throwaway repo ($A) and
    20	# reads the driven run's OWN output. Inheriting RELAY_DRIVER_LOCKED=1 from a live marathon gate makes
    21	# those nested drivers take the already-locked path and skip the end-of-run cost summary, so the
    22	# suite measures the parent rather than itself. Measured 2026-08-07: inherited → 5 pass / 3 fail;
    23	# unset → clean.
    24	unset RELAY_DRIVER_LOCKED
    25	
    26	export TICK_BIN="$TICK"
    27	ROOT="$(cd "$(dirname "$0")/.." && pwd)"
    28	TICK_PATH="$TICK"
    29	
    30	# ...BUT unsetting it is only half the fix, and the missing half halted a live marathon.
    31	#
    32	# The first version of this file's comment claimed "$A is isolated, so unsetting cannot collide with
    33	# a real lock." That was reasoned, not observed, and it is FALSE. $A is where the relay FILE lives;
    34	# it is not the nested driver's ROOT. relay-drive.sh:48 sets
    35	#     ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    36	# from its OWN script location, and there is no env override for it (--target-root moves the build,
    37	# not the lock; MARATHON_ROOT is honoured by marathon-drive only — which is why the sibling
    38	# test/gh284-runlog-heartbeat.sh, scoped with MARATHON_ROOT="$A", was never affected).
    39	#
    40	# So with RELAY_DRIVER_LOCKED unset, the nested relay-drive reached for the REAL clone's
    41	# .git/relay-driver.lock — held by the marathon driver that was running this very gate — and refused:
    42	#
    43	#   FAIL: relay-drive default lane: expected exit 0 + cost summary; got rc=1
    44	#     relay-drive: another driver is active in this repo (pid 35784, lock: .git/relay-driver.lock).
    45	#
    46	# Observed 2026-08-08, Litmus wave-2 phase 1: relay Approved, gate exit 1 after 893s, marathon HALT
    47	# (exit 5). Green standalone, red inside a marathon — GH-441's own defect, reintroduced by GH-441's
    48	# own fix, in the one direction the standalone run cannot see.
    49	#
    50	# THE FIX: give relay-drive a script path INSIDE $A so its script-relative ROOT_DIR resolves to $A,
    51	# and the lock it takes is $A's. Symlinking DIRECTORIES (not individual scripts) is what makes this
    52	# work — the driver resolves its siblings relative to itself, and those resolve through the symlinked
    53	# directory. Same technique as the gitignored `$A/bin/tick` symlink in
    54	# test/gh410-containment-advisory.sh, for the same reason.
    55	#
    56	# The set below is not guessed: it is every path relay-drive.sh dereferences under $ROOT_DIR
    57	#     grep -ohE '\$\{?ROOT_DIR\}?/[A-Za-z0-9._/-]+' relay-automation/relay-drive.sh
    58	# minus the three it creates or owns itself (.git, .relay-driver.lock, relay-system). Getting this
    59	# wrong fails LOUDLY rather than silently — the first attempt symlinked only relay-automation/ and
    60	# the nested run died with
    61	#     can't open file '<A>/utils/py/relay_drive.py': [Errno 2] No such file or directory
    62	# because relay-drive.sh dispatches to the Python lane under $ROOT_DIR/utils (GH-264 default).
    63	mkdir -p "$A"
    64	for _ge_dir in relay-automation utils bin; do
    65	  ln -sfn "$ROOT/$_ge_dir" "$A/$_ge_dir"
    66	done
    67	unset _ge_dir
    68	DRIVE="$A/relay-automation/relay-drive.sh"
    69	
    70	# marathon-drive needs NO such treatment and deliberately keeps the real path: every assertion below
    71	# passes MARATHON_ROOT="$A" (line ~141), which marathon-drive honours for lock resolution, and
    72	# --pre-advance-cmd true so no real gate runs. Routing it through $A too would only add a way for a
    73	# nested marathon to find the REAL validate.sh and re-enter the full gate recursively.
    74	MDRIVE="$ROOT/relay-automation/marathon-drive.sh"
    75	
    76	tick_a init >/dev/null
    77	
    78	COST_LINE='relay-drive: end-of-run cost summary (tick analyze)'
    79	
    80	# ── relay-drive ─────────────────────────────────────────────────────────────────────────
    81	seed() {  # <task> <relayfile-basename>
    82	  printf 'STATUS: In progress\n# body\n' >"$A/$2"
    83	  tick_a log task.created "$1" --agent producer --paths "$2" >/dev/null 2>&1
    84	  tick_a claim   "$1" --agent producer --paths "$2" >/dev/null 2>&1
    85	  tick_a release "$1" --agent producer --to reviewer >/dev/null 2>&1
    86	  tick_a cost    "$1" --agent reviewer --tokens-in 1200 --tokens-out 340 --tool codex >/dev/null 2>&1
    87	}
    88	
    89	approve_stub() {  # <task> <relayfile> → path
    90	  local task="$1"
    91	  local rf="$2"
    92	  local p="$WORK/approve-$task.sh"
    93	  cat >"$p" <<EOF
    94	#!/usr/bin/env bash
    95	export TICK_REPO_ROOT="$A"
    96	"$TICK_PATH" claim $task --agent reviewer >/dev/null 2>&1
    97	tmp="\$(mktemp)"; sed 's/^STATUS:.*/STATUS: Approved/' "$rf" > "\$tmp" && mv "\$tmp" "$rf"
    98	"$TICK_PATH" done $task --agent reviewer >/dev/null 2>&1
    99	exit 0
   100	EOF
   101	  chmod +x "$p"; printf '%s' "$p"
   102	}
   103	
   104	# (1) default lane, cost summary ON → the block appears, run still exits 0.
   105	seed RELAY-A relayA.md
   106	STUB_A="$(approve_stub RELAY-A "$A/relayA.md")"
   107	outA="$(bash "$DRIVE" --relay-file "$A/relayA.md" --relay-task RELAY-A --agent-cmd "$STUB_A" --review-once 2>&1)"; rcA=$?
   108	[ "$rcA" -eq 0 ] && printf '%s' "$outA" | grep -qF "$COST_LINE" \
   109	  && pass "relay-drive default lane: driven turn prints the cost summary (exit 0)" \
   110	  || fail "relay-drive default lane: expected exit 0 + cost summary; got rc=$rcA (out: $outA)"
   111	printf '%s' "$outA" | grep -qF -- '--- cost ---' \
   112	  && pass "relay-drive: the summary carries the real tick analyze cost block" \
   113	  || fail "relay-drive: cost block missing from summary: $outA"
   114	
   115	# (2) RELAY_COST_SUMMARY=0 silences it (still exit 0).
   116	seed RELAY-B relayB.md
   117	STUB_B="$(approve_stub RELAY-B "$A/relayB.md")"
   118	outB="$(RELAY_COST_SUMMARY=0 bash "$DRIVE" --relay-file "$A/relayB.md" --relay-task RELAY-B --agent-cmd "$STUB_B" --review-once 2>&1)"; rcB=$?
   119	[ "$rcB" -eq 0 ] && ! printf '%s' "$outB" | grep -qF "$COST_LINE" \
   120	  && pass "relay-drive: RELAY_COST_SUMMARY=0 opts out of the summary" \
   121	  || fail "relay-drive: RELAY_COST_SUMMARY=0 did not silence the summary (rc=$rcB): $outB"
   122	
   123	# (3a) NON-zero exit path: a genuine stall exits 3. The summary must be additive — exit STAYS 3.
   124	seed RELAY-C relayC.md
   125	NOOP="$WORK/noop.sh"; printf '#!/usr/bin/env bash\nexit 0\n' >"$NOOP"; chmod +x "$NOOP"
   126	outC="$(bash "$DRIVE" --relay-file "$A/relayC.md" --relay-task RELAY-C --agent-cmd "$NOOP" --review-once 2>&1)"; rcC=$?
   127	[ "$rcC" -eq 3 ] \
   128	  && pass "relay-drive: the summary never changes the run's exit code (stall still exits 3)" \
   129	  || fail "relay-drive: exit code changed by the summary — expected 3, got $rcC (out: $outC)"
   130	
   131	# (3b) `tick analyze` itself failing must degrade gracefully and NOT change the exit code.
   132	seed RELAY-D relayD.md
   133	STUB_D="$(approve_stub RELAY-D "$A/relayD.md")"
   134	BROKEN_TICK="$WORK/broken-tick.sh"
   135	printf '#!/usr/bin/env bash\ncase "$1" in analyze) exit 9 ;; esac\nexec "%s" "$@"\n' "$TICK" >"$BROKEN_TICK"
   136	chmod +x "$BROKEN_TICK"
   137	outD="$(TICK_BIN="$BROKEN_TICK" bash "$DRIVE" --relay-file "$A/relayD.md" --relay-task RELAY-D --agent-cmd "$STUB_D" --review-once 2>&1)"; rcD=$?
   138	[ "$rcD" -eq 0 ] \
   139	  && pass "relay-drive: a failed tick analyze does not change the exit code (still 0)" \
   140	  || fail "relay-drive: failed tick analyze changed exit code — expected 0, got $rcD (out: $outD)"
   141	printf '%s' "$outD" | grep -qF 'tick analyze failed — end-of-run cost summary unavailable' \
   142	  && pass "relay-drive: a failed tick analyze degrades with a note, not a crash" \
   143	  || fail "relay-drive: expected the analyze-failed degradation note: $outD"
   144	
   145	# ── marathon-drive ──────────────────────────────────────────────────────────────────────
   146	MCOST_LINE='marathon-drive: end-of-run cost summary (tick analyze)'
   147	printf '.tick/\n' > "$A/.gitignore"
   148	git -C "$A" add .gitignore >/dev/null 2>&1 && git -C "$A" commit -qm init >/dev/null 2>&1
   149	BRIEF="$WORK/GH-331-brief.md"; printf 'GH-331 cost brief\n' > "$BRIEF"
   150	# Stub relay-drive that exits 3 (a stall): marathon still arms drive_started before invoking it, so the
   151	# cost summary must fire at marathon's own exit, and marathon must still exit 3.
   152	STUB_RD="$WORK/relay-drive-stub.sh"; printf '#!/usr/bin/env bash\nexit 3\n' >"$STUB_RD"; chmod +x "$STUB_RD"
   153	STUB_CLAUDE="$WORK/claude"; printf '#!/usr/bin/env bash\nexit 0\n' >"$STUB_CLAUDE"; chmod +x "$STUB_CLAUDE"
   154	STUB_AGY="$WORK/agy"; printf '#!/usr/bin/env bash\nexit 0\n' >"$STUB_AGY"; chmod +x "$STUB_AGY"
   155	tick_a cost MARATHON-GH331 --agent codex --tokens-in 2000 --tokens-out 700 --tool codex >/dev/null 2>&1
   156	
   157	run_marathon() { # <phase-id> [extra-env-assignments passed via `env`]
   158	  local pid="$1"; shift
   159	  env "$@" MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$STUB_RD" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
   160	    CLAUDE_BIN="$STUB_CLAUDE" AGY_BIN="$STUB_AGY" \
   161	    bash "$MDRIVE" --phases-dir "$A/phases" --phase-brief "$BRIEF" --phase-id "$pid" \
   162	      --relay-task "MARATHON-GH331-$pid" --builder claude --reviewer agy --pre-advance-cmd true 2>&1
   163	}
   164	
   165	# (4a) default lane, cost summary ON → marathon prints its own block, still exits 3.
   166	mOut="$(run_marathon m1)"; mRc=$?
   167	[ "$mRc" -eq 3 ] && printf '%s' "$mOut" | grep -qF "$MCOST_LINE" \
   168	  && pass "marathon-drive default lane: driven phase prints the cost summary (exit preserved: 3)" \
   169	  || fail "marathon-drive default lane: expected exit 3 + cost summary; got rc=$mRc (out: $(printf '%s' "$mOut" | tail -5))"
   170	
   171	# (4b) MARATHON_COST_SUMMARY=0 silences it (still exits 3).
   172	mOut0="$(run_marathon m2 MARATHON_COST_SUMMARY=0)"; mRc0=$?
   173	[ "$mRc0" -eq 3 ] && ! printf '%s' "$mOut0" | grep -qF "$MCOST_LINE" \
   174	  && pass "marathon-drive: MARATHON_COST_SUMMARY=0 opts out of the summary" \
   175	  || fail "marathon-drive: MARATHON_COST_SUMMARY=0 did not silence the summary (rc=$mRc0): $(printf '%s' "$mOut0" | tail -5)"
   176	
   177	echo "  $TEST_NAME: $PASS pass, $FAIL fail"
   178	exit 0
     1	#!/usr/bin/env bash
     2	# test/gh376-relay-drive-lock-parity.sh — GH-376.
     3	#
     4	# marathon-drive.sh:195-196 asserts, in prose, that a marathon driver and a relay driver "still
     5	# mutually exclude in one clone" because they share one lock NAME. From a normal clone that was true.
     6	# From a LINKED WORKTREE it was false: .git is a FILE, marathon-drive followed it to the git COMMON
     7	# dir, and relay-drive's own inline 2-branch guess (.git is a dir -> .git/…, ELSE a hidden lock beside
     8	# the scripts) had no case for that at all — so it locked inside the worktree instead. Two top-level
     9	# drivers could each hold what they believed was THE mutex, against the same tree, invisible to each
    10	# other. That topology is not exotic: it is the one swarm-preflight's own recommended invocation
    11	# creates via RELAY_WORKTREE_ISOLATION=1.
    12	#
    13	# The fix routes both relay-drive twins through GH-448's shared resolver
    14	# (relay-automation/driver-lock-lib.sh / utils/py/rtl.py::driver_lock_path), which marathon-drive's
    15	# Python half already uses — so the two agree by construction rather than by coincidence.
    16	#
    17	# WHY THE OBSERVABLE IS "DOES IT REFUSE", NOT "WHAT PATH DID IT PRINT":
    18	# the drivers never print their lock path on the happy path, and the EXIT trap removes the lock, so a
    19	# post-hoc filesystem probe cannot see it. Holding the lock at the path MARATHON-DRIVE resolves and
    20	# then running relay-drive is the direct test of the claim the comment makes: if relay-drive resolves
    21	# the same path it must refuse; if it resolves anywhere else it sails past. That refusal IS the
    22	# mutual exclusion, observed end-to-end through the real scripts rather than asserted about a string.
    23	#
    24	# Hermetic: a throwaway harness clone + a REAL `git worktree add`. No network, no agent, no paid turn.
    25	
    26	set -uo pipefail
    27	
    28	# THIS SUITE DRIVES REAL LOCK ACQUISITION, so it must own RELAY_DRIVER_LOCKED rather than inherit it.
    29	# When validate.sh runs as a live marathon's --pre-advance-cmd, marathon_drive.py:649 has already
    30	# exported RELAY_DRIVER_LOCKED=1 so its NESTED relay-drive skips a lock the parent already holds. The
    31	# gate inherits that on purpose: gate_env.py deliberately does NOT scrub it (tried, landed, REVERTED
    32	# 2026-08-07 — its docstring carries the measured 4-suite table showing neither value is right for
    33	# the whole gate). Inherited here, every driver invocation below skips the lock block entirely and
    34	# each "must refuse" assertion silently inverts.
    35	#
    36	# NOT hypothetical: this suite went 12/6 inside the Nightwatch wave-3 gate on 2026-08-11 while
    37	# passing 18/0 standalone, and halted the marathon at phase 1 for a defect that was in this file and
    38	# not in the phase's own work. Setting RELAY_DRIVER_LOCKED=1 and running this file reproduces it
    39	# exactly. (Spell that invocation out rather than abbreviating the filename: test/path-integrity.sh
    40	# reads a path-shaped token in any comment as a real reference and fails the gate on the ellipsis.)
    41	#
    42	# The per-suite clear is the shipped remedy for exactly this (GH-441 Phase 1), and this file is the
    43	# fifth to need it — see test/driver-lock.sh:11, gh284-runlog-heartbeat.sh:12, gh331-cost-summary.sh:24,
    44	# gh342-sentinel-debug-log-python.sh:27. Section F below then re-asserts the inherited=1 behaviour
    45	# deliberately, so what cost a marathon phase is covered rather than merely avoided.
    46	unset RELAY_DRIVER_LOCKED
    47	
    48	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    49	REPO="$(cd "$HERE/.." && pwd)"
    50	
    51	WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh376.XXXXXX")"
    52	# GH-177: guard BEFORE the physical re-capture and BEFORE the rm -rf trap is armed. A failed mktemp
    53	# leaves $WORK empty, `cd ""` is a no-op, and `pwd -P` would then hand back the repository root
    54	# straight into `rm -rf`. Same shape (and the same `&& exit 1` inside the braces, which the scanner
    55	# requires in the SAME `;`-delimited segment as the `||`) as test/gh448-driver-lock-resolver.sh:37.
    56	[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "  FAIL: mktemp -d produced no usable dir" >&2 && exit 1; }
    57	# Resolve to the PHYSICAL path first: git always reports a physical path from
    58	# `rev-parse --path-format=absolute --git-common-dir`, and on macOS $TMPDIR lives under /var, a
    59	# symlink to /private/var. A $TMPDIR-derived expected string would never equal git's answer.
    60	WORK="$(cd "$WORK" && pwd -P)"
    61	[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "  FAIL: could not resolve \$WORK to a physical path" >&2 && exit 1; }
    62	trap 'rm -rf "$WORK"' EXIT
    63	
    64	PASS=0; FAIL=0
    65	pass() { printf '  PASS: %s\n' "$*"; PASS=$((PASS+1)); }
    66	fail() { printf '  FAIL: %s\n' "$*" >&2; FAIL=$((FAIL+1)); }
    67	
    68	echo "== test: gh376-relay-drive-lock-parity =="
    69	echo "  workdir: $WORK"
    70	
    71	# ── fixtures ─────────────────────────────────────────────────────────────────────────────────────
    72	# A harness clone carrying the REAL scripts. relay-drive resolves its lock from its OWN location
    73	# (ROOT_DIR = dirname(script)/..), not from a target repo, so the thing that must live in a linked
    74	# worktree is the HARNESS itself. Same construction as gh448's section C3.
    75	MAIN="$WORK/harness"
    76	mkdir -p "$MAIN"
    77	cp -R "$REPO/relay-automation" "$REPO/utils" "$REPO/bin" "$MAIN/" 2>/dev/null
    78	git init -q "$MAIN"
    79	git -C "$MAIN" config user.email t@example.com
    80	git -C "$MAIN" config user.name "gh376 test"
    81	git -C "$MAIN" add -A >/dev/null 2>&1
    82	git -C "$MAIN" commit -qm seed >/dev/null 2>&1
    83	WT="$WORK/harness-wt"
    84	git -C "$MAIN" worktree add -q "$WT" -b gh376-wt-branch
    85	
    86	[ -f "$WT/.git" ] \
    87	  && pass "fixture: the linked worktree's .git is a FILE (the branch that had no case)" \
    88	  || fail "fixture setup: expected $WT/.git to be a file"
    89	
    90	# The path MARATHON-DRIVE resolves for this worktree — the git common dir, i.e. the main clone's .git.
    91	COMMON_LOCK="$MAIN/.git/relay-driver.lock"
    92	# The path the PRE-FIX relay-drive resolved instead: a lock local to whichever worktree it ran in.
    93	WORKTREE_LOCAL_LOCK="$WT/.relay-driver.lock"
    94	
    95	RELAY="$WORK/RELAY.md"
    96	printf 'STATUS: In progress\n' > "$RELAY"
    97	
    98	HOLDER=""
    99	hold_lock() {  # <lock-dir> — hold it with a genuinely LIVE pid, or the GH-42 stale-reclaim path
   100	               # fires and the driver takes the lock for a completely different (correct) reason.
   101	  release_lock
   102	  rm -rf "$1"; mkdir -p "$1"
   103	  /bin/sleep 300 & HOLDER=$!
   104	  printf '%s\n' "$HOLDER" > "$1/pid"
   105	}
   106	release_lock() {
   107	  # `wait` after `kill` reaps the job so bash does not print its own "Terminated: 15" job-control
   108	  # line to the terminal — that notice is emitted by the shell, not by the test, and cannot be
   109	  # silenced by redirecting the kill alone.
   110	  [ -n "$HOLDER" ] && { kill "$HOLDER" 2>/dev/null; wait "$HOLDER" 2>/dev/null; }
   111	  HOLDER=""
   112	}
   113	trap 'release_lock; rm -rf "$WORK"' EXIT
   114	
   115	run_driver() {  # <harness-root> <lane: py|sh> — prints the driver's stderr
   116	  local h="$1" lane="$2"
   117	  if [ "$lane" = "py" ]; then
   118	    python3 "$h/utils/py/relay_drive.py" \
   119	      --relay-file "$RELAY" --agent-cmd /bin/true --dry-run 2>&1
   120	  else
   121	    XYZ_PYTHON=0 bash "$h/relay-automation/relay-drive.sh" \
   122	      --relay-file "$RELAY" --agent-cmd /bin/true --dry-run 2>&1
   123	  fi
   124	}
   125	refused() { printf '%s' "$1" | grep -q 'another driver is active in this repo'; }
   126	
   127	# ═══════════════════════════════════════════════════════════════════════════════════════════════
   128	# A. THE PIN — from a linked worktree, both twins now see the lock marathon-drive holds
   129	# ═══════════════════════════════════════════════════════════════════════════════════════════════
   130	echo "-- A. linked worktree: relay-drive excludes against the marathon-side lock --"
   131	
   132	hold_lock "$COMMON_LOCK"
   133	
   134	py_out="$(run_driver "$WT" py)"
   135	refused "$py_out" \
   136	  && pass "THE PIN (python): relay_drive.py refuses — it resolved the git COMMON dir, like marathon-drive" \
   137	  || fail "THE PIN FAILED (python): did not see the held lock; got: $(printf '%s' "$py_out" | head -1)"
   138	
   139	sh_out="$(run_driver "$WT" sh)"
   140	refused "$sh_out" \
   141	  && pass "THE PIN (bash): relay-drive.sh refuses — the frozen twin agrees with the Python half" \
   142	  || fail "THE PIN FAILED (bash): did not see the held lock; got: $(printf '%s' "$sh_out" | head -1)"
   143	
   144	# Equality ALONE is not enough, and the wave-3 gate proved it: when both lanes skipped the lock they
   145	# emitted the same NON-refusal and this assertion passed green while the two pins beside it failed.
   146	# Requiring that the matched line is a refusal is what makes parity mean something.
   147	if refused "$py_out" && refused "$sh_out" \
   148	   && [ "$(printf '%s' "$py_out" | head -1)" = "$(printf '%s' "$sh_out" | head -1)" ]; then
   149	  pass "twin parity: both lanes emit a byte-identical REFUSAL (same path, same label, same pid)"
   150	else
   151	  fail "twin parity: py='$(printf '%s' "$py_out" | head -1)' sh='$(printf '%s' "$sh_out" | head -1)'"
   152	fi
   153	
   154	[ ! -e "$WORKTREE_LOCAL_LOCK" ] \
   155	  && pass "neither lane left a worktree-local lock behind at \$WT/.relay-driver.lock" \
   156	  || fail "a lane created $WORKTREE_LOCAL_LOCK — it is still resolving inside the worktree"
   157	
   158	release_lock
   159	
   160	# ═══════════════════════════════════════════════════════════════════════════════════════════════
   161	# B. NEGATIVE CONTROL (per #419) — the pre-fix logic, replayed against the SAME fixture
   162	#
   163	# Replaying the OLD resolution must be shown to sail straight past the held lock, or section A is
   164	# only evidence that a lock can be held at all. The Python replay restores the removed 2-branch block
   165	# verbatim. The Bash replay swaps the sourced resolver for one carrying the old body — behaviourally
   166	# identical to the inline block relay-drive.sh used to own, at the same call site.
   167	# ═══════════════════════════════════════════════════════════════════════════════════════════════
   168	echo "-- B. negative control: pre-fix resolution does NOT exclude --"
   169	
   170	PRE="$WORK/harness-prefix-wt"
   171	cp -R "$WT/" "$PRE/" 2>/dev/null
   172	
   173	python3 - "$PRE/utils/py/relay_drive.py" <<'PY'
   174	import sys
   175	p = sys.argv[1]
   176	s = open(p).read()
   177	old = ('        if os.path.isdir(os.path.join(root_dir, ".git")):\n'
   178	       '            lock_dir = os.path.join(root_dir, ".git", "relay-driver.lock")\n'
   179	       '            lock_label = ".git/relay-driver.lock"\n'
   180	       '        else:\n'
   181	       '            lock_dir = os.path.join(root_dir, ".relay-driver.lock")\n'
   182	       '            lock_label = ".relay-driver.lock"\n')
   183	new = "        lock_dir, lock_label = driver_lock_path(root_dir)\n"
   184	if new not in s:
   185	    sys.exit("gh376 replay: the post-fix call site was not found — this control is vacuous")
   186	open(p, "w").write(s.replace(new, old, 1))
   187	PY
   188	[ $? -eq 0 ] || fail "negative control: could not build the python pre-fix replay"
   189	
   190	cat > "$PRE/relay-automation/driver-lock-lib.sh" <<'EOF'
   191	#!/usr/bin/env bash
   192	set -u
   193	driver_lock_path_for_repo() {
   194	  local repo="$1"
   195	  if [ -d "$repo/.git" ]; then printf '%s/.git/relay-driver.lock' "$repo"
   196	  else printf '%s/.relay-driver.lock' "$repo"; fi
   197	}
   198	EOF
   199	
   200	# The replay runs against the ORIGINAL worktree's common dir: $PRE is a copy of the worktree, so its
   201	# own .git file still points at $MAIN. Hold the same lock the real drivers just honoured.
   202	hold_lock "$COMMON_LOCK"
   203	
   204	pre_py="$(run_driver "$PRE" py)"
   205	refused "$pre_py" \
   206	  && fail "negative control (python) is VACUOUS: the pre-fix logic also refused — the fixture is not exercising the worktree branch" \
   207	  || pass "negative control (python): pre-fix 2-branch logic sails past the held lock — the defect, reproduced"
   208	
   209	pre_sh="$(run_driver "$PRE" sh)"
   210	refused "$pre_sh" \
   211	  && fail "negative control (bash) is VACUOUS: the pre-fix logic also refused" \
   212	  || pass "negative control (bash): pre-fix 2-branch logic sails past the held lock"
   213	
   214	release_lock
   215	
   216	# ═══════════════════════════════════════════════════════════════════════════════════════════════
   217	# C. CONTROL — a normal clone must behave EXACTLY as before
   218	#
   219	# The fix is worthless if it bought the worktree case at the cost of the common one. Run from $MAIN,
   220	# where .git is a directory: the resolved path is unchanged, so exclusion must still hold.
   221	# ═══════════════════════════════════════════════════════════════════════════════════════════════
   222	echo "-- C. control: a normal clone (.git is a directory) is unchanged --"
   223	
   224	hold_lock "$COMMON_LOCK"
   225	
   226	refused "$(run_driver "$MAIN" py)" \
   227	  && pass "CONTROL (python): a normal clone still excludes at .git/relay-driver.lock" \
   228	  || fail "CONTROL (python): the fix broke the ordinary single-clone case"
   229	refused "$(run_driver "$MAIN" sh)" \
   230	  && pass "CONTROL (bash): a normal clone still excludes at .git/relay-driver.lock" \
   231	  || fail "CONTROL (bash): the fix broke the ordinary single-clone case"
   232	
   233	release_lock
   234	
   235	# ═══════════════════════════════════════════════════════════════════════════════════════════════
   236	# D. CONTROL — a vendored .xyz/ copy (no .git anywhere) still falls back beside the scripts
   237	# ═══════════════════════════════════════════════════════════════════════════════════════════════
   238	echo "-- D. control: a vendored copy with no .git falls back to .relay-driver.lock --"
   239	
   240	VEND="$WORK/vendored"
   241	mkdir -p "$VEND"
   242	cp -R "$MAIN/relay-automation" "$MAIN/utils" "$MAIN/bin" "$VEND/" 2>/dev/null
   243	rm -rf "$VEND/.git"
   244	
   245	hold_lock "$VEND/.relay-driver.lock"
   246	
   247	vend_py="$(run_driver "$VEND" py)"
   248	refused "$vend_py" && printf '%s' "$vend_py" | grep -q '\.relay-driver\.lock' \
   249	  && pass "CONTROL (python): vendored copy resolves the hidden lock beside the scripts" \
   250	  || fail "CONTROL (python): vendored fallback changed; got: $(printf '%s' "$vend_py" | head -1)"
   251	vend_sh="$(run_driver "$VEND" sh)"
   252	refused "$vend_sh" && printf '%s' "$vend_sh" | grep -q '\.relay-driver\.lock' \
   253	  && pass "CONTROL (bash): vendored copy resolves the hidden lock beside the scripts" \
   254	  || fail "CONTROL (bash): vendored fallback changed; got: $(printf '%s' "$vend_sh" | head -1)"
   255	
   256	release_lock
   257	
   258	# ═══════════════════════════════════════════════════════════════════════════════════════════════
   259	# E. SOURCE GUARDS — the resolver is REUSED, not reimplemented
   260	#
     1	#!/usr/bin/env bash
     2	# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh407-gate-ran-attribution.sh. The pre-fix revision is replayed inside the fixture by patching the driver copy back to its old single-expression form (reason = pre-advance-failed whenever no timeout reason was recorded, with no gate: line in ESCALATION.md). Pre-fix result: a phase whose builder never produced work escalated as pre-advance-failed and the record carried no statement of whether the gate ran. Post-fix result: the same phase escalates as relay-failed-before-gate with gate: not-run, while a genuinely red gate still escalates as pre-advance-failed with gate: red. Both observed in one run."}
     3	# GH-407: `pre-advance-failed` asserts that the gate RAN and found a defect in the change.
     4	#
     5	# Several unrelated failures reach the same relay exit 5 — a builder shim that failed to start, a
     6	# builder that exhausted its turn cap, a reviewer turn discarded by containment — and all of them
     7	# were reported with that label. Observed three times in one 10-lane marathon on 2026-08-02, wrong
     8	# all three times; in one case the relay file read STATUS: Approved while the phase was escalated as
     9	# though the gate had rejected the work.
    10	#
    11	# Why the mislabel costs real time: the reason is the operator's entry point into a failed run.
    12	# `pre-advance-failed` sends them to read the diff and the test output. When the gate never ran there
    13	# is no test output, and nothing in the escalation record said so — confirming it required checking
    14	# whether any pytest output existed anywhere after the phase started.
    15	#
    16	# Pinned here:
    17	#   (1) a relay failure that never reached the gate does NOT claim a gate verdict
    18	#   (2) every escalation states whether the gate ran, on every reason
    19	#   (3) a genuinely red gate still reports pre-advance-failed with gate: red  <- anti-overcorrection
    20	#   (4) the reason for the no-gate case names no cause it cannot determine
    21	#
    22	# (3) is the assertion that protects against the cheap fix. Reserving `pre-advance-failed` is easy to
    23	# over-apply: relabel every exit 5 and criteria 1, 2 and 4 all pass while real gate failures stop
    24	# being reported as gate failures — the same defect pointing the other way.
    25	set -euo pipefail
    26	
    27	source "$(dirname "$0")/_setup.sh" gh407-gate-ran-attribution
    28	export TICK_BIN="$TICK"
    29	ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
    30	DRIVER="$ROOT_REPO/relay-automation/marathon-drive.sh"
    31	
    32	ROOT="$WORK/target"
    33	mkdir -p "$ROOT"
    34	git init -q "$ROOT"
    35	git -C "$ROOT" config user.email gh407@t
    36	git -C "$ROOT" config user.name gh407
    37	printf '.tick/\n' > "$ROOT/.gitignore"
    38	printf '#!/usr/bin/env bash\nexit 0\n' > "$ROOT/validate.sh"
    39	git -C "$ROOT" add .gitignore validate.sh >/dev/null 2>&1
    40	git -C "$ROOT" commit -q -m init
    41	
    42	STUB_BIN="$WORK/stub-bin"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_BIN"; chmod +x "$STUB_BIN"
    43	BRIEF="$WORK/brief.md"; printf '## Do a thing\nBody.\n' > "$BRIEF"
    44	
    45	# Stub relay-drive, exit 5 WITHOUT approving: this is the shape the issue describes — the relay
    46	# failed (builder never produced work), so the driver never reaches its own gate.
    47	RD_FAIL="$WORK/relay-drive-fail.sh"
    48	cat > "$RD_FAIL" << 'STUB_EOF'
    49	#!/usr/bin/env bash
    50	set -u
    51	exit 5
    52	STUB_EOF
    53	chmod +x "$RD_FAIL"
    54	
    55	# Stub relay-drive that DOES approve, so the driver runs its gate and the gate decides.
    56	RD_OK="$WORK/relay-drive-ok.sh"
    57	cat > "$RD_OK" << 'STUB_EOF'
    58	#!/usr/bin/env bash
    59	set -u
    60	rf=""
    61	while (($#)); do case "$1" in --relay-file) rf="${2:-}"; shift 2 ;; *) shift ;; esac; done
    62	[ -n "$rf" ] && printf 'STATUS: Approved\n' >> "$rf"
    63	exit 0
    64	STUB_EOF
    65	chmod +x "$RD_OK"
    66	
    67	run_driver() {  # <relay-drive-stub> <extra-args…>
    68	  local rd="$1"; shift
    69	  MARATHON_ROOT="$ROOT" \
    70	  MARATHON_RELAY_DRIVE="$rd" \
    71	  MARATHON_AGENT_CMD="$WORK/noop-agent" \
    72	  TICK_REPO_ROOT="$ROOT" TICK_BIN="$TICK" \
    73	  CLAUDE_BIN="$STUB_BIN" AGY_BIN="$STUB_BIN" CODEX_BIN="$STUB_BIN" \
    74	  bash "$DRIVER" \
    75	    --phases-dir "$ROOT/phases" \
    76	    --phase-brief "$BRIEF" \
    77	    --reviewer agy \
    78	    --builder claude \
    79	    "$@"
    80	}
    81	esc_field() { sed -n "s/^$2: //p" "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null; }
    82	
    83	# ── (1)(2)(4) the relay failed before the gate ────────────────────────────────────────────
    84	printf '#!/usr/bin/env bash\nexit 0\n' > "$ROOT/validate.sh"
    85	run_driver "$RD_FAIL" --phase-id no-gate > "$WORK/no-gate.log" 2>&1 && rc=0 || rc=$?
    86	reason="$(esc_field no-gate reason)"
    87	gate="$(esc_field no-gate gate)"
    88	
    89	[ "$reason" != "pre-advance-failed" ] \
    90	  && pass "a relay failure that never reached the gate does NOT claim pre-advance-failed (got: $reason)" \
    91	  || fail "the gate never ran, yet the phase was reported as pre-advance-failed"
    92	
    93	[ "$reason" = "relay-failed-before-gate" ] \
    94	  && pass "the no-gate case reports relay-failed-before-gate — states what is known, names no cause it cannot determine" \
    95	  || fail "expected relay-failed-before-gate, got '$reason'"
    96	
    97	[ "$gate" = "not-run" ] \
    98	  && pass "ESCALATION.md records gate: not-run — the one line that resolves the ambiguity" \
    99	  || fail "expected 'gate: not-run' in the escalation record, got '$gate'"
   100	
   101	# ── (3) anti-overcorrection: a real gate failure is still a gate failure ──────────────────
   102	printf '#!/usr/bin/env bash\nexit 1\n' > "$ROOT/validate.sh"
   103	run_driver "$RD_OK" --phase-id red-gate > "$WORK/red-gate.log" 2>&1 && rc=0 || rc=$?
   104	reason="$(esc_field red-gate reason)"
   105	gate="$(esc_field red-gate gate)"
   106	
   107	[ "$reason" = "pre-advance-failed" ] \
   108	  && pass "a gate that RAN and failed is still pre-advance-failed — the fix does not relabel real failures" \
   109	  || fail "a real gate failure was reported as '$reason' — GH-407 pointing the other way"
   110	
   111	[ "$gate" = "red" ] \
   112	  && pass "ESCALATION.md records gate: red, so the record distinguishes a verdict from a non-run" \
   113	  || fail "expected 'gate: red', got '$gate'"
   114	
   115	# ── (5) the THIRD value: an escalation that happens AFTER a green gate says so ─────────────
   116	# Added after a codex review of the merged fix noted the suite pinned `not-run` and `red` but never
   117	# `green` — so `gate:` could have been hardwired to emit only the two failure words and every other
   118	# assertion here would still pass. `requires-test-missing` is the reachable green-gate escalation: it
   119	# is checked after the gate returns 0 (marathon_drive.py:1504), so the gate genuinely ran and passed
   120	# while the phase still halted. That is precisely the case an operator must be able to tell apart from
   121	# a gate failure, which is this issue's whole subject.
   122	printf '#!/usr/bin/env bash\nexit 0\n' > "$ROOT/validate.sh"
   123	run_driver "$RD_OK" --phase-id green-gate --requires-test "test/definitely-absent-$$.sh" > "$WORK/green-gate.log" 2>&1 && rc=0 || rc=$?
   124	reason="$(esc_field green-gate reason)"
   125	gate="$(esc_field green-gate gate)"
   126	
   127	[ "$reason" = "requires-test-missing" ] \
   128	  && pass "a phase halted after a PASSING gate keeps its own reason (requires-test-missing), not a gate verdict" \
   129	  || fail "expected requires-test-missing after a green gate, got '$reason'"
   130	
   131	[ "$gate" = "green" ] \
   132	  && pass "ESCALATION.md records gate: green — all three values are now observed, so the field cannot be a two-word failure label" \
   133	  || fail "expected 'gate: green' for an escalation after a passing gate, got '$gate'"
   134	
   135	# ── the pre-fix replay (#419): the old single-expression form, inside the fixture ──────────
   136	# Replayed against a COPY of the driver so the working tree is never mutated. The copy is patched
   137	# back to the pre-fix behaviour and driven through the same no-gate case, which must produce the old
   138	# wrong answer. If it does not, this whole file is asserting something that was never broken.
   139	FIXH="$WORK/prefix-harness"
   140	mkdir -p "$FIXH"
   141	for d in relay-automation utils bin src; do
   142	  [ -e "$ROOT_REPO/$d" ] && cp -R "$ROOT_REPO/$d" "$FIXH/$d"
   143	done
   144	PRE_MD="$FIXH/utils/py/marathon_drive.py"
   145	python3 - "$PRE_MD" <<'PY'
   146	import pathlib, sys
   147	p = pathlib.Path(sys.argv[1]); s = p.read_text()
   148	
   149	# revert the escalation record: drop the gate: line
   150	before = s
   151	s = s.replace("reason: {reason}\ngate: {run_gate_result[0]}\n", "reason: {reason}\n", 1)
   152	assert s != before, "could not revert the gate: line — pre-fix replay would be vacuous"
   153	
   154	# revert the reason choice to the old unconditional form
   155	i = s.index("        gate_ran = run_gate_result[0] != \"not-run\"")
   156	j = s.index("        escalate(reason, 5)", i)
   157	s = s[:i] + (
   158	'        reason = timeout_reason[0] if timeout_reason[0] != "turn-timeout-or-hang" else "pre-advance-failed"\n'
   159	'        emit = timeout_emit[0] if timeout_reason[0] != "turn-timeout-or-hang" else "halted"\n'
   160	'        log("relay escalated: pre-advance gate failed")\n'
   161	) + s[j:]
   162	p.write_text(s)
   163	print("PATCHED")
   164	PY
   165	
   166	PRE_DRIVER="$FIXH/relay-automation/marathon-drive.sh"
   167	PRE_ROOT="$WORK/target-prefix"
   168	cp -R "$ROOT" "$PRE_ROOT"
   169	rm -rf "$PRE_ROOT/phases"
   170	MARATHON_ROOT="$PRE_ROOT" \
   171	MARATHON_RELAY_DRIVE="$RD_FAIL" \
   172	MARATHON_AGENT_CMD="$WORK/noop-agent" \
   173	TICK_REPO_ROOT="$PRE_ROOT" TICK_BIN="$TICK" \
   174	CLAUDE_BIN="$STUB_BIN" AGY_BIN="$STUB_BIN" CODEX_BIN="$STUB_BIN" \
   175	  bash "$PRE_DRIVER" --phases-dir "$PRE_ROOT/phases" --phase-brief "$BRIEF" \
   176	    --reviewer agy --builder claude --phase-id no-gate > "$WORK/prefix.log" 2>&1 && rc=0 || rc=$?
   177	
   178	pre_reason="$(sed -n 's/^reason: //p' "$PRE_ROOT/phases/no-gate/ESCALATION.md" 2>/dev/null)"
   179	pre_gate="$(sed -n 's/^gate: //p' "$PRE_ROOT/phases/no-gate/ESCALATION.md" 2>/dev/null)"
   180	
   181	[ "$pre_reason" = "pre-advance-failed" ] \
   182	  && pass "control: the pre-fix revision reports pre-advance-failed for a gate that never ran (the defect, observed)" \
   183	  || fail "control: pre-fix replay did not reproduce the defect — got reason '$pre_reason', so the post-fix assertions prove nothing"
   184	
   185	[ -z "$pre_gate" ] \
   186	  && pass "control: the pre-fix record carries NO statement of whether the gate ran" \
   187	  || fail "control: pre-fix record unexpectedly had 'gate: $pre_gate'"
   188	
   189	echo "gh407-gate-ran-attribution: $PASS pass, $FAIL fail"

2026-08-13T17:20:25.596048Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 95 column 5
codex
## ANSWER

The spike supports “do not cut or merge incident-backed tests,” but it does not yet support shipping `validate.sh --parallel N`. Its census is incomplete/non-reproducible as stated, and one parallel run only demonstrates a promising experiment—not a safe runner design.

## FINDINGS

- [Blocker] The reported “full gate” was not the repository’s full gate. `validate.sh` runs an additional pytest lane after the shell array, which the census omitted (`validate.sh:259–265`). The current array also contains 190 shell suites, not 186 (`validate.sh:15–240`), so the timing data must be reconciled to an exact commit and command before it drives a design decision.

- [Blocker] Treating `acorn-extract.sh` as merely environmental underweights a documented prerequisite. The project explicitly requires `npm install` before `validate.sh` because otherwise Acorn is missing (`README.md:23–29`); the canonical local CI path uses `npm ci` and runs Acorn separately (`ci-local.sh:195–201`). A parallel implementation must preserve that setup and avoid double-running Acorn, rather than normalize a known-red direct invocation.

- [Should] The “sleep hypothesis falsified” conclusion is directionally credible but overstated. A literal-`sleep` grep cannot attribute wall time spent in subprocesses, polling loops, git, Python/Node startup, or timeout wrappers. One run can rank likely targets; it cannot establish stable causal attribution. Repeat the census (cold/warm cache, at least several runs) and record median/range plus the exact environment.

- [Should] The parallel experiment identifies one real shared resource, but does not establish that the remaining suites are isolated. The lock is deliberately shared through Git’s common directory for linked worktrees (`relay-automation/driver-lock-lib.sh:20–34`), and the suite has prior evidence that nested real-driver invocations are sensitive to leaked environment/root context (`test/marathon-root-audit.sh:6–15`). A single successful mixed run cannot rule out intermittent file, process, environment, or Git-index interference.

- [Should] “Three consecutive green parallel runs” is too weak for a race-prone runner. Before exposing a flag, run the exact proposed scheduler repeatedly at several widths, with per-suite logs, exit-code preservation, a clean-tree check before/after, no leaked worktrees/processes/locks, and inclusion of pytest and npm setup. Make it experimental until that evidence exists.

- [Pass] The no-cut/no-merge conclusion for the named incident family is well founded. The GH-375 tests cover distinct branches: output classification versus timeout classification (`test/gh375-agy-auth-preflight.sh:37–45`; `test/gh375-auth-timeout-verdict.sh:21–29`). GH-390 verifies resource-guard behavior while explicitly retaining a genuine-red-gate control (`test/gh390-gate-guard.sh:12–19`, `255–266`); GH-407 verifies whether a gate ran and retains the opposite-direction red-gate control (`test/gh407-gate-ran-attribution.sh:16–24`, `101–113`). The repeated `pre-advance-failed` assertion is an intentional anti-overcorrection control, not demonstrated redundancy.

- [Nit] I would not prioritize the shared `run_driver` helper. The apparent duplication sits in tests with materially different fixtures and failure modes; abstraction could obscure the incident-specific setup for little measured gain. The statement that GH-390 timeout attribution is the only suite outside `_setup.sh` conventions is only true if limited to that small named group—many registered tests do not source `_setup.sh`, e.g. `test/gh419-gate-inventory.sh:4–7`.

## RECOMMENDATION

Keep all incident-backed suites; first re-run a complete, dependency-correct, repeated parallelism study, then add only an explicitly experimental parallel runner with the identified driver lane serialized.
tokens used
133,557
## ANSWER

The spike supports “do not cut or merge incident-backed tests,” but it does not yet support shipping `validate.sh --parallel N`. Its census is incomplete/non-reproducible as stated, and one parallel run only demonstrates a promising experiment—not a safe runner design.

## FINDINGS

- [Blocker] The reported “full gate” was not the repository’s full gate. `validate.sh` runs an additional pytest lane after the shell array, which the census omitted (`validate.sh:259–265`). The current array also contains 190 shell suites, not 186 (`validate.sh:15–240`), so the timing data must be reconciled to an exact commit and command before it drives a design decision.

- [Blocker] Treating `acorn-extract.sh` as merely environmental underweights a documented prerequisite. The project explicitly requires `npm install` before `validate.sh` because otherwise Acorn is missing (`README.md:23–29`); the canonical local CI path uses `npm ci` and runs Acorn separately (`ci-local.sh:195–201`). A parallel implementation must preserve that setup and avoid double-running Acorn, rather than normalize a known-red direct invocation.

- [Should] The “sleep hypothesis falsified” conclusion is directionally credible but overstated. A literal-`sleep` grep cannot attribute wall time spent in subprocesses, polling loops, git, Python/Node startup, or timeout wrappers. One run can rank likely targets; it cannot establish stable causal attribution. Repeat the census (cold/warm cache, at least several runs) and record median/range plus the exact environment.

- [Should] The parallel experiment identifies one real shared resource, but does not establish that the remaining suites are isolated. The lock is deliberately shared through Git’s common directory for linked worktrees (`relay-automation/driver-lock-lib.sh:20–34`), and the suite has prior evidence that nested real-driver invocations are sensitive to leaked environment/root context (`test/marathon-root-audit.sh:6–15`). A single successful mixed run cannot rule out intermittent file, process, environment, or Git-index interference.

- [Should] “Three consecutive green parallel runs” is too weak for a race-prone runner. Before exposing a flag, run the exact proposed scheduler repeatedly at several widths, with per-suite logs, exit-code preservation, a clean-tree check before/after, no leaked worktrees/processes/locks, and inclusion of pytest and npm setup. Make it experimental until that evidence exists.

- [Pass] The no-cut/no-merge conclusion for the named incident family is well founded. The GH-375 tests cover distinct branches: output classification versus timeout classification (`test/gh375-agy-auth-preflight.sh:37–45`; `test/gh375-auth-timeout-verdict.sh:21–29`). GH-390 verifies resource-guard behavior while explicitly retaining a genuine-red-gate control (`test/gh390-gate-guard.sh:12–19`, `255–266`); GH-407 verifies whether a gate ran and retains the opposite-direction red-gate control (`test/gh407-gate-ran-attribution.sh:16–24`, `101–113`). The repeated `pre-advance-failed` assertion is an intentional anti-overcorrection control, not demonstrated redundancy.

- [Nit] I would not prioritize the shared `run_driver` helper. The apparent duplication sits in tests with materially different fixtures and failure modes; abstraction could obscure the incident-specific setup for little measured gain. The statement that GH-390 timeout attribution is the only suite outside `_setup.sh` conventions is only true if limited to that small named group—many registered tests do not source `_setup.sh`, e.g. `test/gh419-gate-inventory.sh:4–7`.

## RECOMMENDATION

Keep all incident-backed suites; first re-run a complete, dependency-correct, repeated parallelism study, then add only an explicitly experimental parallel runner with the identified driver lane serialized.
