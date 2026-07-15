**SINGLE-MODEL — NOT RECONCILED** (only codex answered; 1 of 2 requested advisor(s) failed — this is one model's read, not a cross-model consult. Do not treat any claim below as cross-verified.)

**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.4
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
OpenAI Codex v0.140.0
--------
workdir: /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241
model: gpt-5.4
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019f4cfd-ad1a-7c21-aa9f-f38b338358c7
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
## Review request: PR #196 — "GH-192: bridge marathon-scan.sh's preflight readiness into the Obsidian daily rollup"

Branch `gh-192-hq-marathon-obsidian-rollup-2026-07-09` into `main`. You are sitting in a worktree
checked out from this branch's tip, so `utils/hq/rollup.sh`, `test/hq-rollup.sh`, `validate.sh`, and
`utils/hq/marathon-scan.sh`/`utils/hq/hq-lib.sh` (unchanged, for context) are all present on disk —
read them directly rather than relying only on the diff below.

### What changed (summary)

`utils/hq/rollup.sh` previously only scraped `ROADMAP.md` "queue/parked" sections across known repos
and synthesized them into an Obsidian note (`$HQ_OBSIDIAN_VAULT/HQ-Daily-Rollup.md`) via a single
`agy -p ... > "$OUT_FILE"` call — if the scrape found nothing, the script printed a message and
exited without writing the file at all.

This PR makes `rollup.sh` also shell out to `utils/hq/marathon-scan.sh` (an existing, separately
tested cross-repo marathon-preflight aggregator) and append its aggregate report **verbatim** —
deliberately NOT passed through `agy` — as a new `## Marathon Readiness (cross-repo preflight)`
section underneath the agy-synthesized ROADMAP section, in the same output file. The embedded
report's own leading YAML frontmatter is stripped, and every heading in the embedded report is
demoted by 2 levels (`#` → `###`, `##` → `####`, skipping fenced code blocks) so it nests properly
under the outer `## Marathon Readiness` heading instead of sitting at a sibling level.

One deliberate behavior change: `rollup.sh` now ALWAYS writes `OUT_FILE`, even when the ROADMAP
scrape finds nothing (a placeholder string is used for that section instead), so the marathon
section still reaches Obsidian on a quiet day.

A new `AGY_BIN="${AGY_BIN:-agy}"` env var was added as a test seam (mirrors
`relay-automation/consult.sh`'s own `CODEX_BIN`/`GEMINI_BIN`/`AIDER_BIN` convention), and the
`command -v agy` hard-requirement check now checks `command -v "$AGY_BIN"` instead.

Failure handling for the new marathon-scan call: `marathon_rc=0; marathon_log="$(bash "$HERE/marathon-scan.sh" --out "$MARATHON_TMP" 2>&1)" || marathon_rc=$?` —
if `marathon-scan.sh` exits non-zero, the marathon section becomes a visible
`_marathon scan failed (exit N): <log>_` string instead of silently disappearing.

New test: `test/hq-rollup.sh` (14 assertions) — stubs `agy` via `AGY_BIN`, but runs the REAL
`marathon-scan.sh` against fixture repos/registries (same fixture pattern as the pre-existing
`test/hq-marathon-scan.sh`), covering: (1) populated ROADMAP + a marathon lane, (2) empty ROADMAP +
a marathon lane (asserts the file is still written and `agy` is NOT invoked in this case).

Also: `test/hq-marathon-scan.sh` (GH-158, pre-existing, unrelated to this PR's code) had apparently
shipped without ever being added to `validate.sh`'s `TESTS` array — this PR registers it alongside
the new `hq-rollup.sh` test.

Separately, this PR's author checked whether `utils/hq/hq-lib.sh`'s `hq_repo_resolve()` had a
pre-existing "same path counted twice → false ambiguity" bug that an earlier related doc (GH-158)
flagged as a known gap — and found it was already fixed by a prior PR (GH-159, `hq_xyz_lookup()`
already dedupes registry rows by resolved `coord` path). No code change was made for that; it's
included here only as context for why the diff doesn't touch `hq-lib.sh`.

### What I want from you

Read the actual current file contents (not just my summary) of `utils/hq/rollup.sh`,
`test/hq-rollup.sh`, and `validate.sh`'s new registrations, plus `utils/hq/marathon-scan.sh` and
`utils/hq/hq-lib.sh` for context on what rollup.sh is calling into. Then answer:

1. **Correctness**: Any bug in the new bash — quoting, the `set -euo pipefail` interaction with the
   `marathon_log="$(...)" || marathon_rc=$?` failure-capture pattern, the awk heading-demotion regex,
   edge cases in the frontmatter-stripping awk, or anything that could silently corrupt the merged
   note or crash the script in a real (non-test) environment?
2. **Test coverage**: Does `test/hq-rollup.sh` actually prove what it claims, or are there gaps —
   e.g. does it adequately test the `marathon-scan.sh` failure/non-zero-exit path, or only the happy
   path?
3. **Design**: Is verbatim-appending (not LLM-synthesizing) the marathon section the right call, or
   is there a real problem with that approach you'd flag?
4. **Merge readiness**: Would you merge this PR as-is? If not, what's the one thing you'd block on?

Do not just validate my summary — read the code yourself and form an independent view. If you
disagree with any design choice above, say so explicitly rather than hedging.
hook: SessionStart
hook: SessionStart Completed
codex
I’m reviewing the actual bash and test files on this branch, starting with the repo’s required guidance docs and the rollup/marathon scripts so I can judge the failure paths from the code rather than the summary.
codex
I have the graph tools now. Next I’m checking whether this worktree is already indexed; if not I’ll index it before reading the relevant symbols and then inspect the shell tests and validation registration directly.
mcp: codebase-memory-mcp/list_projects started
mcp: codebase-memory-mcp/list_projects (failed)
user cancelled MCP tool call
exec
/bin/zsh -lc "pwd && printf '\\n---\\n' && sed -n '1,220p' WORKTREE-SAFETY.md && printf '\\n---\\n' && sed -n '1,240p' ROUTER.md && printf '\\n---\\n' && sed -n '1,220p' GUIDING-PRINCIPLES.md" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241
 succeeded in 0ms:
/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241

---
# Git Worktree Safety Guide for Agents

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


---
# ROUTER.md

This file is the first entry point for an AI agent working in this repo: it tells you what to read, what to run, and which files are canonical.

## Role split

- `ROUTER.md` = startup order and canonical entry points
- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof
- `README.md` = human-facing repo/product overview
- `ROADMAP.md` = pointer ledger of queued, current, completed, attempted, and deferred work
- `CHANGELOG.md` = the end-of-iteration running log (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
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
utils/pdda/pdda.sh doc-ready        # LLM readiness review — set PDDA_LLM_BIN (codex/claude/agy) for recommendations, else it self-skips
```

## Routing hints

- If the task is about current priorities or active work, start in `ROADMAP.md`, then follow the linked `PROJECT/**` doc.
- If the task is about fresh GitHub intake or duplicate-prevention, start in `ROADMAP.md`'s queue, then follow the linked `PROJECT/1-INBOX/GH-*.md` capture doc.
- If the task is about document quality, active-doc lifecycle, roadmap sprawl, or automation policy, start in `PROJECT/PDDA.md`.
- If the task is about the CHANGELOG, provenance, or end-of-iteration logging, the governance is in `PROJECT/PDDA.md` (the "CHANGELOG.md — end-of-iteration record" contract).
- If the task is about the `tick` runtime, event projection, or multi-agent coordination kernel, start in `README.md`, then `bin/`, `src/`, `test/`, and the active project doc.
- If the task is about the **Aider ↔ OpenRouter** turn-taker lane (`relay-automation/aider-turn.sh` — an OpenAI-standard build lane discrete from Codex; `AIDER_MODEL`/`OPENROUTER_API_KEY`, `--builder aider`), start in `PROJECT/3-COMPLETED/GH-77-AIDER-OPENROUTER-LANE.md`. The shim owns the tick token ops (Aider can't run shell mid-turn), asserts token ownership before launching Aider, and runs Aider `--no-auto-commits` (the harness commits).
- If the task is about running, driving, or reviewing via the relay (`relay-automation/` — `relay-drive.sh`, `poll.sh`, the turn shims, `marathon*.sh`), **invoke the `relay-xyz` skill first — do not improvise the handoff or hand-roll a harness from `ls relay-automation/`.** The skill owns the locator, sandbox rules, exit codes, and the safety boundary; a `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) blocks driving a harness driver before the skill is loaded. For the two live-Claude-windows, same-machine duel recipe (Reporter↔Maintainer with a human go-gate), the copy-paste form is [relay-automation/DUELING-CLAUDES.md](relay-automation/DUELING-CLAUDES.md).
- If the task is about the ATE (Automated Testing Environment) skill — unattended Aider variation-test fuzzing driven by a local Gemma worker under `utils/ate/` — start in `utils/ate/SKILL.md`. Currently hardcoded to Aider despite the generic name/description; generalizing it to other harnesses is tracked, not urgent, in `PROJECT/1-INBOX/GH-191-ATE-GENERALIZE-HARNESS.md`.
- If the task is about relay session telemetry, the `focus5float` health feed, or extraction scripts under `utils/telemetry/`, start in `PROJECT/1-INBOX/GH-24-RELAY-TELEMETRY-EXTRACTOR.md`.
- If the task is about live per-session completion telemetry — the `XYZ.json` log every relay/marathon/swarm session appends to at the harness repo root (schema: `harness`/`sessionId`/`health`/`title`/`description`/`updatedAt`), the shared writer `utils/telemetry/append-xyz-completion.sh`, or the shared health mapping `utils/telemetry/health-lib.sh` — start in `PROJECT/1-INBOX/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md`. `XYZ.json` is local + gitignored (machine-specific).
- If the task is about cross-repo HQ tooling (`utils/hq/` — `hq.sh` single-repo actions, `rollup.sh` the Obsidian daily ROADMAP rollup, `marathon-scan.sh` the cross-repo marathon-preflight aggregator, `hq-lib.sh` the shared repo registry), start in `PROJECT/3-COMPLETED/GH-27-ROADMAP-DASHBOARD.md` and `PROJECT/3-COMPLETED/GH-158-HQ-MARATHON-SCAN.md`. The two rollups are deliberately separate today (`rollup.sh` → Obsidian, generic; `marathon-scan.sh` → hub repo, preflight-aware) and are not yet bridged — tracked in `PROJECT/1-INBOX/GH-192-HQ-MARATHON-OBSIDIAN-ROLLUP.md`.
- If the task is about a proposed roadmap-steward agent, start here, then read `PROJECT/PDDA.md` and its `Proposed roadmap steward extension` section.
- Issue-first SOP: any change beyond a 2–3 line fix (and every project plan) opens a GitHub issue *first*, then gets a pointer doc named after the issue at `PROJECT/1-INBOX/GH-<number>-VERY-SHORT-DESC.md` — e.g. `GH-1234-SHOWME-COMMAND.md` — and that capture is parked in the `ROADMAP.md` queue immediately (format + lifecycle owned by `PROJECT/PDDA.md` → "GitHub issue intake"), following the normal `1-INBOX` → `2-WORKING` flow. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt and commit directly.

---
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
The graph MCP is behaving oddly on project discovery, so I’m falling back to a direct index attempt on this worktree and then I’ll use it for symbol-level reads if it succeeds; otherwise I’ll read the shell files directly and note the tool failure.
mcp: codebase-memory-mcp/index_repository started
mcp: codebase-memory-mcp/index_repository (failed)
user cancelled MCP tool call
exec
/bin/zsh -lc 'nl -ba test/hq-rollup.sh' in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241
exec
/bin/zsh -lc 'nl -ba utils/hq/rollup.sh' in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# utils/hq/rollup.sh — Roll up cross-repo ROADMAP activity + marathon preflight readiness
     3	# (GH-158's marathon-scan.sh) into one daily Obsidian summary (GH-192).
     4	
     5	set -euo pipefail
     6	
     7	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
     8	# shellcheck source=utils/hq/hq-lib.sh
     9	. "$HERE/hq-lib.sh"
    10	
    11	AGY_BIN="${AGY_BIN:-agy}"   # test seam — same convention as relay-automation/consult.sh
    12	
    13	command -v node >/dev/null 2>&1 || { echo "hq rollup: node is required" >&2; exit 2; }
    14	command -v "$AGY_BIN" >/dev/null 2>&1 || { echo "hq rollup: agy (Antigravity CLI) is required" >&2; exit 2; }
    15	
    16	mkdir -p "$HQ_OBSIDIAN_VAULT"
    17	OUT_FILE="$HQ_OBSIDIAN_VAULT/HQ-Daily-Rollup.md"
    18	RAW_FILE="${TMPDIR:-/tmp}/hq-raw-rollup.txt"
    19	> "$RAW_FILE"
    20	
    21	echo "HQ Rollup: scanning repos for ROADMAP activity..."
    22	
    23	# hq_known_repos outputs one per line
    24	while IFS= read -r repo; do
    25	  [ -z "$repo" ] && continue
    26	  
    27	  fields="$(hq_repo_resolve "$repo")"
    28	  path="$(printf '%s\n' "$fields" | sed -n 's/^REPO_PATH=//p' | head -1)"
    29	  
    30	  if [ -n "$path" ] && [ -f "$path/ROADMAP.md" ]; then
    31	    echo "  scanning $repo ($path)..."
    32	    
    33	    node - "$path/ROADMAP.md" "$repo" >> "$RAW_FILE" <<'NODE'
    34	const fs = require("fs");
    35	const sourcePath = process.argv[2];
    36	const repoName = process.argv[3];
    37	const raw = fs.readFileSync(sourcePath, "utf8");
    38	const lines = raw.split(/\r?\n/);
    39	
    40	const sections = new Map();
    41	let currentSection = null;
    42	
    43	for (let i = 0; i < lines.length; i++) {
    44	  const line = lines[i];
    45	
    46	  const sectionMatch = line.match(/^###\s+(.+?)\s*$/);
    47	  if (sectionMatch) {
    48	    const heading = sectionMatch[1].trim().toLowerCase();
    49	    if (heading.includes("queue") || heading.includes("parked") || heading.includes("in progress") || heading.includes("next-up")) {
    50	      currentSection = sectionMatch[1].trim();
    51	      if (!sections.has(currentSection)) sections.set(currentSection, []);
    52	    } else {
    53	      currentSection = null;
    54	    }
    55	    continue;
    56	  }
    57	
    58	  if (!currentSection) continue;
    59	  
    60	  // Bullets usually start with `- **` or `<number>. **`
    61	  if (!/^(-\s+|\d+\.\s+)\*\*/.test(line)) continue;
    62	
    63	  const block = [line];
    64	  while (i + 1 < lines.length) {
    65	    const next = lines[i + 1];
    66	    if (/^###\s+/.test(next) || /^##\s+/.test(next) || /^(-\s+|\d+\.\s+)\*\*/.test(next)) break;
    67	    block.push(next);
    68	    i += 1;
    69	  }
    70	  sections.get(currentSection).push(block.join(" ").replace(/\s+/g, " "));
    71	}
    72	
    73	let hasData = false;
    74	let out = `\n=== REPO: ${repoName} ===\n`;
    75	for (const [heading, items] of sections.entries()) {
    76	  if (items && items.length > 0) {
    77	    hasData = true;
    78	    out += `\nSection: ${heading}\n`;
    79	    items.forEach(item => out += `${item}\n`);
    80	  }
    81	}
    82	
    83	if (hasData) {
    84	  process.stdout.write(out);
    85	}
    86	NODE
    87	
    88	  fi
    89	done < <(hq_known_repos)
    90	
    91	if [ -s "$RAW_FILE" ]; then
    92	  echo "HQ Rollup: Synthesizing with agy..."
    93	
    94	  PROMPT="Synthesize the following cross-repo parked and marathon items into a clean daily summary for an Obsidian dashboard.
    95	Format it beautifully using GitHub flavored markdown.
    96	Group the information into logical sections such as 'Active / Next Up' and 'Parked / Queued'.
    97	Mention which repo each item belongs to.
    98	Do not hallucinate any information.
    99	Keep it concise but detailed enough so I remember context without context switching.
   100	
   101	RAW DATA:
   102	$(cat "$RAW_FILE")
   103	"
   104	
   105	  roadmap_section="$("$AGY_BIN" -p "$PROMPT" --dangerously-skip-permissions < /dev/null)"
   106	else
   107	  echo "HQ Rollup: No parked or active items found in any ROADMAP.md."
   108	  roadmap_section="_No parked or active items found in any ROADMAP.md._"
   109	fi
   110	
   111	# GH-192: fold in GH-158's cross-repo marathon-preflight aggregator. Appended verbatim, never
   112	# passed through agy — the ready/blocked/stale/ambiguous verdicts are the one deterministic,
   113	# structured signal in this pipeline, and an LLM synthesis pass risks paraphrasing one wrong.
   114	echo "HQ Rollup: running marathon-scan.sh for preflight readiness..."
   115	MARATHON_TMP="$(mktemp "${TMPDIR:-/tmp}/hq-rollup-marathon.XXXXXX")"
   116	marathon_rc=0
   117	marathon_log="$(bash "$HERE/marathon-scan.sh" --out "$MARATHON_TMP" 2>&1)" || marathon_rc=$?
   118	
   119	if [ "$marathon_rc" -eq 0 ] && [ -s "$MARATHON_TMP" ]; then
   120	  # Strip the report's own leading YAML frontmatter (redundant once embedded under a heading here),
   121	  # and demote every heading by 2 levels (# -> ###, ## -> ####) so the report's own H1 title nests
   122	  # properly under this section's H2 instead of sitting at the same level as its own subheadings.
   123	  marathon_section="$(awk '
   124	    NR==1 && $0=="---" { infm=1; next }
   125	    infm && $0=="---" { infm=0; next }
   126	    infm { next }
   127	    /^```/ { infence = !infence; print; next }
   128	    !infence && match($0, /^#+ /) { print "##" $0; next }
   129	    { print }
   130	  ' "$MARATHON_TMP")"
   131	else
   132	  marathon_section="_marathon scan failed (exit ${marathon_rc}): ${marathon_log}_"
   133	fi
   134	rm -f "$MARATHON_TMP"
   135	
   136	{
   137	  printf '%s\n' "$roadmap_section"
   138	  printf '\n---\n\n## Marathon Readiness (cross-repo preflight)\n\n'
   139	  printf '%s\n' "$marathon_section"
   140	} > "$OUT_FILE"
   141	
   142	echo "HQ Rollup: ✓ wrote $OUT_FILE"

 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# GH-192: hermetic regression lock for utils/hq/rollup.sh's marathon-readiness bridge.
     3	#
     4	# Stubs agy (AGY_BIN) so no real network/CLI call happens, and reuses marathon-scan.sh's own
     5	# fixture pattern (a fixture repo + stub swarm-preflight.sh) so the marathon section is a REAL
     6	# classification, not a stub — proving the bridge actually invokes marathon-scan.sh and embeds its
     7	# verbatim output. Two cases: (1) ROADMAP has queued items -> agy-synthesized section + marathon
     8	# section both present; (2) ROADMAP has none -> file still written (the one deliberate behavior
     9	# change from before GH-192), placeholder + marathon section both present, agy never invoked.
    10	
    11	set -uo pipefail
    12	# strict-mode: -e exempt — assertion-style test with expected-nonzero probes handled explicitly.
    13	
    14	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    15	ROOT="$(cd "$HERE/.." && pwd)"
    16	ROLLUP="$ROOT/utils/hq/rollup.sh"
    17	
    18	WORK="$(mktemp -d "${TMPDIR:-/tmp}/hq-rollup.XXXXXX")"
    19	trap 'rm -rf "$WORK"' EXIT
    20	
    21	PASS=0
    22	FAIL=0
    23	pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
    24	fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
    25	
    26	echo "== test: hq-rollup =="
    27	echo "  workdir: $WORK"
    28	
    29	REPO="$WORK/repos/repo-a"
    30	mkdir -p "$REPO/.git" "$REPO/PROJECT/2-WORKING" "$REPO/utils"
    31	
    32	cat >"$REPO/utils/swarm-preflight.sh" <<'EOF'
    33	#!/usr/bin/env bash
    34	set -uo pipefail
    35	ISSUE=""
    36	while (($# > 0)); do
    37	  case "$1" in
    38	    --gh-issue) ISSUE="${2:-}"; shift 2 ;;
    39	    --target-root|--project-doc|--format|--dry-run) shift ;;
    40	    *) shift ;;
    41	  esac
    42	done
    43	if [[ "$ISSUE" == "101" ]]; then
    44	  echo '{"readiness":{"ready":true}}'; exit 0
    45	fi
    46	echo '{"readiness":{"ready":false}}'; exit 6
    47	EOF
    48	chmod +x "$REPO/utils/swarm-preflight.sh"
    49	
    50	cat >"$REPO/PROJECT/2-WORKING/MARATHON-PLAN-2026-07-09.md" <<'EOF'
    51	---
    52	title: repo-a-marathon
    53	status: Active
    54	---
    55	
    56	# repo-a-marathon
    57	
    58	## Recommended waves
    59	
    60	**Wave 1:** #101
    61	EOF
    62	
    63	AGY_STUB="$WORK/agy-stub"
    64	AGY_MARKER_FILE="$WORK/agy-invoked"
    65	cat >"$AGY_STUB" <<EOF
    66	#!/usr/bin/env bash
    67	touch "$AGY_MARKER_FILE"
    68	echo "AGY-STUB-SYNTHESIS-MARKER"
    69	EOF
    70	chmod +x "$AGY_STUB"
    71	
    72	PDDA_DIR="$WORK/pdda"
    73	mkdir -p "$PDDA_DIR"
    74	XYZ_REG="$WORK/xyz.tsv"
    75	cat >"$XYZ_REG" <<EOF
    76	$REPO/.xyz	2026-07-09T00:00:00Z	0.2.0	a1	$REPO
    77	EOF
    78	
    79	VAULT="$WORK/vault"
    80	OUT="$VAULT/HQ-Daily-Rollup.md"
    81	
    82	run_rollup() {
    83	  HQ_OBSIDIAN_VAULT="$VAULT" \
    84	  HQ_XYZ_REGISTRY="$XYZ_REG" \
    85	  HQ_PDDA_REGISTRY_DIR="$PDDA_DIR" \
    86	  HQ_SEARCH_ROOTS="$WORK/repos" \
    87	  HQ_MARATHON_SCAN_TODAY="2026-07-09" \
    88	  HQ_MARATHON_SCAN_NOW="2026-07-09T12:00:00Z" \
    89	  AGY_BIN="$AGY_STUB" \
    90	  bash "$ROLLUP"
    91	}
    92	
    93	echo "-- Case A: populated ROADMAP.md --"
    94	cat >"$REPO/ROADMAP.md" <<'EOF'
    95	# Roadmap
    96	## Ledger
    97	### Queue / parked intake
    98	- **Test item** some description
    99	EOF
   100	
   101	run_rollup >"$WORK/case-a.log" 2>&1
   102	rc=$?
   103	[[ $rc -eq 0 ]] && pass "case A: rollup exits 0" || fail "case A: rollup rc=$rc ($(cat "$WORK/case-a.log"))"
   104	[[ -f "$OUT" ]] && pass "case A: report written" || fail "case A: report missing"
   105	[[ -f "$AGY_MARKER_FILE" ]] && pass "case A: agy stub was invoked" || fail "case A: agy stub never ran"
   106	
   107	grep -q "AGY-STUB-SYNTHESIS-MARKER" "$OUT" \
   108	  && pass "case A: agy-synthesized ROADMAP section present" || fail "case A: agy section missing"
   109	grep -q "^## Marathon Readiness (cross-repo preflight)$" "$OUT" \
   110	  && pass "case A: marathon section heading present" || fail "case A: marathon section heading missing"
   111	grep -q "^### HQ MARATHON" "$OUT" \
   112	  && pass "case A: embedded report's H1 demoted to H3 (nests under the H2 section)" \
   113	  || fail "case A: embedded report's heading not demoted: $(grep '^#* HQ MARATHON' "$OUT")"
   114	grep -q "^# HQ MARATHON" "$OUT" \
   115	  && fail "case A: embedded report's H1 leaked through undemoted" \
   116	  || pass "case A: no bare H1 from the embedded report"
   117	grep -q '| #101 | .*| ✅ ready (exit 0) |' "$OUT" \
   118	  && pass "case A: real marathon-scan classification embedded verbatim" \
   119	  || fail "case A: marathon-scan classification missing/wrong: $(grep '#101' "$OUT")"
   120	grep -q "^generated_by:" "$OUT" \
   121	  && fail "case A: marathon-scan's own frontmatter leaked into the rollup" \
   122	  || pass "case A: marathon-scan's frontmatter stripped"
   123	
   124	echo "-- Case B: empty ROADMAP.md, agy must NOT be invoked --"
   125	rm -f "$AGY_MARKER_FILE" "$OUT"
   126	cat >"$REPO/ROADMAP.md" <<'EOF'
   127	# Roadmap
   128	## Ledger
   129	### Completed
   130	- Nothing relevant to the queue/parked scrape here.
   131	EOF
   132	
   133	run_rollup >"$WORK/case-b.log" 2>&1
   134	rc=$?
   135	[[ $rc -eq 0 ]] && pass "case B: rollup exits 0" || fail "case B: rollup rc=$rc ($(cat "$WORK/case-b.log"))"
   136	[[ -f "$OUT" ]] && pass "case B: report STILL written despite empty ROADMAP scrape" || fail "case B: report missing"
   137	[[ -f "$AGY_MARKER_FILE" ]] && fail "case B: agy stub ran even though ROADMAP scrape was empty" \
   138	  || pass "case B: agy stub correctly skipped"
   139	grep -q "_No parked or active items found in any ROADMAP.md._" "$OUT" \
   140	  && pass "case B: placeholder ROADMAP text present" || fail "case B: placeholder missing"
   141	grep -q '| #101 | .*| ✅ ready (exit 0) |' "$OUT" \
   142	  && pass "case B: marathon section still present on a quiet ROADMAP day" \
   143	  || fail "case B: marathon section missing"
   144	
   145	echo "== hq-rollup: $PASS passed, $FAIL failed =="
   146	[ "$FAIL" -eq 0 ]

exec
/bin/zsh -lc "rg -n \"hq-rollup|hq-marathon-scan\" validate.sh && printf '\\n---\\n' && nl -ba validate.sh | sed -n '1,220p'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241
 succeeded in 0ms:
107:  "hq-marathon-scan.sh"          # GH-158 (cross-repo marathon aggregation + preflight — written, never registered until GH-192)
108:  "hq-rollup.sh"                 # GH-192 (marathon-scan.sh bridged verbatim into the Obsidian daily rollup)

---
     1	#!/usr/bin/env bash
     2	# Aggregate runner for all tick acceptance tests.
     3	# Exit 0 = all pass; Exit 1 = at least one failed.
     4	set -u
     5	
     6	# Clean ambient variables that might interfere with tests inside the harness.
     7	unset ALLOW_PATHS RELAY_FILE RELAY_TASK RELAY_AGENT RELAY_PEER RELAY_WORKTREE_ISOLATION
     8	
     9	HERE="$(cd "$(dirname "$0")" && pwd)"
    10	TESTS=(
    11	  "projection-idempotent.sh"
    12	  "concurrent-claim.sh"
    13	  "chaos-stale-writer.sh"
    14	  "chaos-concurrent-pollers.sh"
    15	  "chaos-midturn-kill.sh"
    16	  "path-overlap.sh"
    17	  "scope-change.sh"
    18	  "tick-foreign-cwd.sh"
    19	  "handoff.sh"
    20	  "handoff-exclusive.sh"
    21	  "circuit-break.sh"
    22	  "terminality-seal.sh"          # GH-41 (terminal seal edge cases — cross-model review of PR #99)
    23	  "auto-sync.sh"
    24	  "analyze.sh"
    25	  "workstealing-verdict.sh"      # GH-4 (work-stealing via take + lane-count-independent verdict)
    26	  "verdict-edge.sh"              # GH-4 (verdict/collision edge cases — cross-model review of PR #101)
    27	  "claim-cap.sh"
    28	  "reap.sh"
    29	  "heartbeat.sh"
    30	  "cost.sh"
    31	  "take.sh"
    32	  "watchdog-liveness.sh"
    33	  "runner-loop.sh"
    34	  "poll-driver.sh"
    35	  "relay-loop.sh"
    36	  "poll-relay.sh"
    37	  "watchdog-relay.sh"
    38	  "codex-turn.sh"
    39	  "agy-turn.sh"
    40	  "relay-turn-trace.sh"          # GH-161 (rtl_trace/rtl_log_always/rtl_default_log instrumentation)
    41	  "aider-turn.sh"
    42	  "model-alias.sh"              # GH-120 (OpenRouter model-alias fuzzy lookup)
    43	  "swe-diagram.sh"              # GH-146 (hub-ring layout ring-balance math + search/filter matching)
    44	  "claude-turn.sh"             # GH-58
    45	  "worktree-isolation.sh"
    46	  "shim-worktree.sh"
    47	  "marathon-yaml.sh"
    48	  "marathon-drive.sh"
    49	  "debug-mantra.sh"              # GH-162 (debug-mantra auto-trigger note on a phase's prior attempt)
    50	  "lane-attempt-cap.sh"
    51	  "driver-lock.sh"
    52	  "measure.sh"
    53	  "loop-stop.sh"
    54	  "oracle-guard.sh"
    55	  "champion.sh"
    56	  "heldout-check.sh"
    57	  "loop-cost.sh"
    58	  "improve-loop.sh"
    59	  "improve-loop-qa.sh"
    60	  "improve-loop-dogfood.sh"
    61	  "marathon.sh"
    62	  "consult.sh"
    63	  "deep-research.sh"             # GH-87 (provider-agnostic grounded-search adapter)
    64	  "relay-pkg-freshness.sh"
    65	  "skill-extract.sh"
    66	  "path-integrity.sh"
    67	  "relay-turn-timeout.sh"
    68	  "relay-target-root.sh"
    69	  "relay-target-root-paths.sh"
    70	  "relay-target-root-relayfile.sh"
    71	  "relay-target-root-newfile.sh"
    72	  "archive-root.sh"              # GH-30 Phase 1 (transcript-root resolver: unset/set/missing/non-git)
    73	  "archive-writers.sh"           # GH-30 Phase 2 (writers honor the resolver: consult e2e + structural)
    74	  "archive-commit.sh"            # GH-30 Phase 3 (Model A: transcript → archive repo, code+.tick → target)
    75	  "archive-telemetry.sh"         # GH-30 Phase 4 (telemetry reads the resolver: archive aggregation + unset)
    76	  "relay-token-collision.sh"
    77	  "relay-escalation-not-stall.sh"
    78	  "relay-untracked-file-warn.sh"
    79	  "relay-file-seeding-visibility.sh"  # GH-178 B2
    80	  "relay-review-once.sh"
    81	  "relay-artifact-file.sh"
    82	  "relay-turn-handoff.sh"
    83	  "relay-dep-drift.sh"
    84	  "new-relay.sh"
    85	  "xyz-vendor.sh"
    86	  "xyz-sync-check.sh"            # GH-96 (xyz-sync check: tick_version/source_commit drift report)
    87	  "relay-concurrent-commit.sh"
    88	  "relay-case-insensitive.sh"
    89	  "relay-xyz-skill-guard.sh"
    90	  "find-harness.sh"
    91	  "pdda-roadmap-coverage.sh"
    92	  "swarm-preflight.sh"
    93	  "ci-workflow.sh"
    94	  "xyz-completion.sh"
    95	  "xyz-harness-hooks.sh"
    96	  "preflight-docs.sh"
    97	  "roadmap-dashboard.sh"
    98	  "marathon-plan.sh"
    99	  "hq.sh"                        # GH-128 Phase 1 (HQ resolver + read-only project card)
   100	  "hq-park.sh"                   # GH-128 Phase 2 (HQ issue-first intake writer: preview + --create)
   101	  "hq-park-synthesis.sh"         # GH-164 Phase 1 (fuller PDDA skeleton template + synthesis passthrough + dashboard regen)
   102	  "hq-dispatch.sh"               # GH-128 Phase 3 (HQ queue: append lane · fire: gated hand-off)
   103	  "hq-next.sh"                   # GH-128 Phase 4 (HQ next: Rebalance-priority project board)
   104	  "hq-locator.sh"                # GH-128 Phase 4 (find-hq.sh: device-agnostic locator, user-level /hq)
   105	  "hq-hardening.sh"              # GH-132 (resolution/dispatch hardening: owner/repo, stale-path, YAML, glob)
   106	  "hq-promote.sh"                # GH-138 (HQ promote: 1-INBOX→2-WORKING scaffolder + marathon glob broadening)
   107	  "hq-marathon-scan.sh"          # GH-158 (cross-repo marathon aggregation + preflight — written, never registered until GH-192)
   108	  "hq-rollup.sh"                 # GH-192 (marathon-scan.sh bridged verbatim into the Obsidian daily rollup)
   109	  "transcript-audit.sh"
   110	  "security-scan.sh"
   111	  "checkjs.sh"
   112	  "acorn-extract.sh"             # GH-169
   113	  "registry-lock-concurrency.sh"
   114	  "marathon-monitor.sh"          # GH-88 (cross-repo marathon monitor)
   115	  "signal-triage.sh"             # GH-63 (signal triage stage)
   116	  # GH-40 double-blind Reviewer canaries — each verify-fixture.sh drives the real kernel and exits
   117	  # 0/1, so it plugs straight in. ponytail: the Gamma canary (test/fixtures/gamma-poison/) is
   118	  # deliberately NOT here — it runs the whole validate.sh itself, so nesting it would recurse; it
   119	  # stays a manual check.
   120	  "fixtures/canary-token-reuse/verify-fixture.sh"
   121	  "fixtures/canary-peer-orphan/verify-fixture.sh"
   122	  "fixtures/canary-reviewer-overstep/verify-fixture.sh"
   123	  "phase3-signoff-guard.sh"
   124	  # Live-agent test — auto-skips when agy/codex not on PATH or RELAY_SELF_SUFFICIENCY_SKIP=1.
   125	  # Set RELAY_SELF_SUFFICIENCY_SKIP=1 in CI / keyless environments to avoid the real API call.
   126	  "relay-self-sufficiency.sh"
   127	)
   128	
   129	PASSED=()
   130	FAILED=()
   131	
   132	for t in "${TESTS[@]}"; do
   133	  echo
   134	  echo "==============================="
   135	  echo "Running $t"
   136	  echo "==============================="
   137	  if bash "$HERE/test/$t"; then
   138	    PASSED+=("$t")
   139	  else
   140	    FAILED+=("$t")
   141	  fi
   142	done
   143	
   144	echo
   145	echo "==============================="
   146	echo "Running python3 -m pytest test/test_python_layer.py"
   147	echo "==============================="
   148	if python3 -m pytest "$HERE/test/test_python_layer.py"; then
   149	  PASSED+=("python:test_python_layer.py")
   150	else
   151	  FAILED+=("python:test_python_layer.py")
   152	fi
   153	
   154	echo
   155	echo "==============================="
   156	echo "Summary"
   157	echo "==============================="
   158	TOTAL=$(( ${#TESTS[@]} + 1 ))
   159	echo "passed: ${#PASSED[@]} / ${TOTAL}"
   160	for t in "${PASSED[@]}"; do echo "  + $t"; done
   161	if [ "${#FAILED[@]}" -gt 0 ]; then
   162	  echo "failed:"
   163	  for t in "${FAILED[@]}"; do echo "  - $t"; done
   164	  exit 1
   165	fi
   166	exit 0

exec
/bin/zsh -lc "nl -ba utils/hq/marathon-scan.sh | sed -n '1,320p'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# utils/hq/marathon-scan.sh — read-only cross-repo marathon aggregation + preflight (GH-158).
     3	#
     4	# Enumerates PDDA-known repos via hq-lib.sh, finds marathon docs under PROJECT/2-WORKING/, parses
     5	# each doc's frontmatter status + active wave lanes, and runs EACH TARGET REPO'S OWN
     6	# utils/swarm-preflight.sh in --dry-run mode per active lane. Output is one aggregated
     7	# HQ-MARATHON-<date>.md written in the hub repo (or a caller-specified path). Target repos are
     8	# never written; the only write is the aggregate doc itself.
     9	#
    10	# Usage:
    11	#   utils/hq/marathon-scan.sh
    12	#   utils/hq/marathon-scan.sh --out PROJECT/2-WORKING/HQ-MARATHON-2026-07-06.md
    13	#
    14	# Test seams:
    15	#   HQ_MARATHON_SCAN_TODAY   pin the report date (YYYY-MM-DD)
    16	#   HQ_MARATHON_SCAN_NOW     pin the generated-at timestamp
    17	
    18	set -uo pipefail
    19	# strict-mode: -e exempt — analysis tool with expected-nonzero probes (repo resolution/preflight); errors handled explicitly. See GUIDING-PRINCIPLES.md#strict-mode-policy.
    20	
    21	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    22	ROOT="$(cd "$HERE/../.." && pwd)"
    23	# shellcheck source=utils/hq/hq-lib.sh
    24	. "$HERE/hq-lib.sh"
    25	
    26	TODAY="${HQ_MARATHON_SCAN_TODAY:-"$(date -u +%Y-%m-%d)"}"
    27	NOW="${HQ_MARATHON_SCAN_NOW:-"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}"
    28	OUT=""
    29	
    30	usage() {
    31	  cat <<'EOF'
    32	Usage: utils/hq/marathon-scan.sh [--out FILE]
    33	
    34	Enumerate PDDA-known repos, scan their PROJECT/2-WORKING/*marathon*.md docs, preflight every
    35	active-wave lane with that repo's own utils/swarm-preflight.sh --dry-run, and write one aggregate
    36	HQ-MARATHON-<date>.md report in the hub repo.
    37	EOF
    38	}
    39	
    40	while (($# > 0)); do
    41	  case "$1" in
    42	    --out) OUT="${2:-}"; shift 2 ;;
    43	    --help|-h) usage; exit 0 ;;
    44	    *) usage >&2; echo "hq marathon-scan: unknown argument: $1" >&2; exit 2 ;;
    45	  esac
    46	done
    47	
    48	command -v node >/dev/null 2>&1 || { echo "hq marathon-scan: node is required" >&2; exit 2; }
    49	
    50	OUT="${OUT:-$ROOT/PROJECT/2-WORKING/HQ-MARATHON-$TODAY.md}"
    51	[[ "$OUT" = /* ]] || OUT="$ROOT/$OUT"
    52	mkdir -p "$(dirname "$OUT")"
    53	
    54	TMP="$(mktemp -d "${TMPDIR:-/tmp}/hq-marathon-scan.XXXXXX")"
    55	trap 'rm -rf "$TMP"' EXIT
    56	
    57	HELPER="$TMP/helper.mjs"
    58	cat >"$HELPER" <<'NODE'
    59	import fs from "node:fs";
    60	import path from "node:path";
    61	
    62	const cmd = process.argv[2];
    63	const arg1 = process.argv[3];
    64	const arg2 = process.argv[4];
    65	
    66	const norm = (s) => String(s || "").toLowerCase().replace(/[^a-z0-9]+/g, "");
    67	const stripMd = (v) => String(v || "")
    68	  .replace(/`([^`]+)`/g, "$1")
    69	  .replace(/\*\*([^*]+)\*\*/g, "$1")
    70	  .replace(/\*([^*]+)\*/g, "$1")
    71	  .replace(/\[([^\]]+)\]\(([^)]+)\)/g, "$1")
    72	  .trim();
    73	
    74	function readFileSafe(p) {
    75	  try { return fs.readFileSync(p, "utf8"); }
    76	  catch { return null; }
    77	}
    78	
    79	function frontmatter(raw) {
    80	  const lines = raw.replace(/^\ufeff/, "").split(/\r?\n/);
    81	  let i = 0;
    82	  while (i < lines.length && lines[i].trim() === "") i += 1;
    83	  if (!/^---\s*$/.test(lines[i] || "")) return {};
    84	  const fm = {};
    85	  for (i += 1; i < lines.length; i += 1) {
    86	    if (/^---\s*$/.test(lines[i])) break;
    87	    const m = lines[i].match(/^([A-Za-z0-9_]+):\s*(.*)$/);
    88	    if (m) fm[m[1]] = m[2].trim();
    89	  }
    90	  return fm;
    91	}
    92	
    93	function markdownTitle(raw) {
    94	  const m = raw.match(/^#\s+(.+)$/m);
    95	  return m ? stripMd(m[1]) : "";
    96	}
    97	
    98	function parseLedger(raw) {
    99	  const lines = raw.split(/\r?\n/);
   100	  const items = [];
   101	  let inLedger = false;
   102	  let section = null;
   103	  for (let i = 0; i < lines.length; i += 1) {
   104	    const line = lines[i];
   105	    if (!inLedger) {
   106	      if (/^##\s+Ledger\s*$/.test(line.trim())) inLedger = true;
   107	      continue;
   108	    }
   109	    if (/^##\s+/.test(line) && !/^##\s+Ledger\s*$/.test(line.trim())) break;
   110	    const sm = line.match(/^###\s+(.+?)\s*$/);
   111	    if (sm) { section = sm[1].trim(); continue; }
   112	    if (!section || !/^- \*\*/.test(line)) continue;
   113	    const block = [line];
   114	    while (i + 1 < lines.length) {
   115	      const next = lines[i + 1];
   116	      if (/^###\s+/.test(next) || /^##\s+/.test(next) || /^- \*\*/.test(next)) break;
   117	      block.push(next);
   118	      i += 1;
   119	    }
   120	    const text = block.map((l) => l.trim()).join(" ").replace(/\s+/g, " ").trim();
   121	    const links = [];
   122	    let lm;
   123	    const re = /\[([^\]]+)\]\(([^)]+)\)/g;
   124	    while ((lm = re.exec(text)) !== null) links.push({ label: lm[1], target: lm[2] });
   125	    items.push({
   126	      section,
   127	      title: stripMd((text.match(/^- \*\*(.+?)\*\*/) || [null, text.replace(/^- /, "")])[1]),
   128	      raw: text,
   129	      links,
   130	    });
   131	  }
   132	  return items;
   133	}
   134	
   135	function ghIssueOf(item) {
   136	  const t = item.title.match(/\bGH-(\d+)\b/);
   137	  if (t) return Number(t[1]);
   138	  for (const link of item.links) {
   139	    const m = String(link.target).match(/issues\/(\d+)/);
   140	    if (m) return Number(m[1]);
   141	  }
   142	  return null;
   143	}
   144	
   145	function docOf(item, gh = null) {
   146	  const mds = item.links
   147	    .map((l) => l.target)
   148	    .filter((t) => /\.md($|#)/.test(t) && /PROJECT\//.test(t) && !/relay-system\//.test(t));
   149	  if (mds.length === 0) return null;
   150	  const issue = gh ?? ghIssueOf(item);
   151	  const ownDoc = issue == null ? null : new RegExp(`(^|/)GH-${issue}-[^/]+\\.md($|#)`, "i");
   152	  const pick =
   153	    mds.find((t) => ownDoc && /2-WORKING\//.test(t) && ownDoc.test(t)) ||
   154	    mds.find((t) => ownDoc && ownDoc.test(t)) ||
   155	    mds.find((t) => /2-WORKING\//.test(t)) ||
   156	    mds[0];
   157	  return pick.replace(/#.*$/, "");
   158	}
   159	
   160	function parseMarathon(docPath) {
   161	  const raw = readFileSafe(docPath);
   162	  if (raw == null) throw new Error(`cannot read ${docPath}`);
   163	  const fm = frontmatter(raw);
   164	  const lines = raw.split(/\r?\n/);
   165	  const waves = [];
   166	  for (const line of lines) {
   167	    const m = line.match(/^\*\*Wave [^*]*:\*\*\s*(.+?)\s*$/);
   168	    if (!m) continue;
   169	    const tokens = m[1]
   170	      .split("‖")
   171	      .map((part) => stripMd(part).replace(/^[*-]\s*/, "").trim())
   172	      .filter((part) => part && part !== "(none)");
   173	    if (tokens.length) waves.push(tokens);
   174	  }
   175	  process.stdout.write(JSON.stringify({
   176	    path: docPath,
   177	    title: String(fm.title || markdownTitle(raw) || path.basename(docPath)),
   178	    status: String(fm.status || ""),
   179	    waves,
   180	  }));
   181	}
   182	
   183	function resolveLane(repoRoot, token) {
   184	  const trimmed = String(token || "").trim();
   185	  const hashIssue = trimmed.match(/^#(\d+)$/);
   186	  if (hashIssue) {
   187	    process.stdout.write(JSON.stringify({ kind: "gh-issue", issue: Number(hashIssue[1]), display: `#${hashIssue[1]}` }));
   188	    return;
   189	  }
   190	  const ghIssue = trimmed.match(/^GH-(\d+)$/i);
   191	  if (ghIssue) {
   192	    process.stdout.write(JSON.stringify({ kind: "gh-issue", issue: Number(ghIssue[1]), display: `#${ghIssue[1]}` }));
   193	    return;
   194	  }
   195	
   196	  const tokenNorm = norm(trimmed);
   197	  const projectRoot = path.join(repoRoot, "PROJECT");
   198	  const docs = [];
   199	  (function walk(dir) {
   200	    let ents = [];
   201	    try { ents = fs.readdirSync(dir, { withFileTypes: true }); }
   202	    catch { return; }
   203	    for (const ent of ents) {
   204	      const abs = path.join(dir, ent.name);
   205	      if (ent.isDirectory()) walk(abs);
   206	      else if (ent.isFile() && ent.name.endsWith(".md")) docs.push(abs);
   207	    }
   208	  })(projectRoot);
   209	
   210	  const relDocs = docs.map((abs) => {
   211	    const raw = readFileSafe(abs) || "";
   212	    const rel = path.relative(repoRoot, abs).replace(/\\/g, "/");
   213	    const base = path.basename(abs, ".md");
   214	    return {
   215	      abs,
   216	      rel,
   217	      baseNorm: norm(base),
   218	      titleNorm: norm(String(frontmatter(raw).title || markdownTitle(raw) || base)),
   219	      inWorking: /\/2-WORKING\//.test(`/${rel}`),
   220	    };
   221	  });
   222	
   223	  const candidates = [];
   224	  const addCandidate = (rel, score, source) => {
   225	    const meta = relDocs.find((d) => d.rel === rel);
   226	    candidates.push({
   227	      rel,
   228	      exists: !!meta,
   229	      inWorking: meta ? meta.inWorking : /\/2-WORKING\//.test(`/${rel}`),
   230	      score,
   231	      source,
   232	    });
   233	  };
   234	
   235	  const roadmap = readFileSafe(path.join(repoRoot, "ROADMAP.md"));
   236	  if (roadmap != null) {
   237	    for (const item of parseLedger(roadmap)) {
   238	      const titleNorm = norm(item.title);
   239	      if (!titleNorm) continue;
   240	      const matches =
   241	        titleNorm === tokenNorm ||
   242	        titleNorm.includes(tokenNorm) ||
   243	        tokenNorm.includes(titleNorm) ||
   244	        norm(item.raw).includes(tokenNorm);
   245	      if (!matches) continue;
   246	      const rel = docOf(item);
   247	      if (rel) addCandidate(rel, titleNorm === tokenNorm ? 0 : 1, "roadmap");
   248	    }
   249	  }
   250	
   251	  for (const meta of relDocs) {
   252	    if (meta.baseNorm === tokenNorm) addCandidate(meta.rel, 0, "basename");
   253	    else if (meta.titleNorm === tokenNorm) addCandidate(meta.rel, 1, "title");
   254	    else if (meta.baseNorm.includes(tokenNorm) || tokenNorm.includes(meta.baseNorm)) addCandidate(meta.rel, 2, "basename-fuzzy");
   255	    else if (meta.titleNorm.includes(tokenNorm) || tokenNorm.includes(meta.titleNorm)) addCandidate(meta.rel, 3, "title-fuzzy");
   256	  }
   257	
   258	  if (candidates.length === 0) {
   259	    process.stdout.write(JSON.stringify({ kind: "unresolved", token: trimmed }));
   260	    return;
   261	  }
   262	
   263	  const dedup = new Map();
   264	  for (const cand of candidates) {
   265	    const key = cand.rel;
   266	    const prev = dedup.get(key);
   267	    if (!prev || cand.score < prev.score || (cand.score === prev.score && cand.exists && !prev.exists)) {
   268	      dedup.set(key, cand);
   269	    }
   270	  }
   271	
   272	  const ordered = [...dedup.values()].sort((a, b) =>
   273	    (a.exists ? 0 : 1) - (b.exists ? 0 : 1) ||
   274	    a.score - b.score ||
   275	    (a.inWorking ? 0 : 1) - (b.inWorking ? 0 : 1) ||
   276	    a.rel.localeCompare(b.rel)
   277	  );
   278	  const best = ordered[0];
   279	  const tied = ordered.filter((c) =>
   280	    (c.exists ? 0 : 1) === (best.exists ? 0 : 1) &&
   281	    c.score === best.score &&
   282	    (c.inWorking ? 0 : 1) === (best.inWorking ? 0 : 1)
   283	  );
   284	  if (tied.length > 1) {
   285	    process.stdout.write(JSON.stringify({
   286	      kind: "ambiguous",
   287	      token: trimmed,
   288	      candidates: tied.map((c) => c.rel),
   289	    }));
   290	    return;
   291	  }
   292	
   293	  process.stdout.write(JSON.stringify({
   294	    kind: "project-doc",
   295	    project_doc: best.rel,
   296	    display: best.rel,
   297	  }));
   298	}
   299	
   300	if (cmd === "parse-marathon") parseMarathon(arg1);
   301	else if (cmd === "resolve-lane") resolveLane(arg1, arg2);
   302	else throw new Error(`unknown helper command: ${cmd}`);
   303	NODE
   304	
   305	STATUS_TSV="$TMP/status.tsv"
   306	LANE_TSV="$TMP/lanes.tsv"
   307	: >"$STATUS_TSV"
   308	: >"$LANE_TSV"
   309	
   310	tsv_escape() {
   311	  printf '%s' "$1" | tr '\t\r\n' '   '
   312	}
   313	
   314	parse_marathon_doc() {
   315	  node "$HELPER" parse-marathon "$1"
   316	}
   317	
   318	resolve_lane() {
   319	  node "$HELPER" resolve-lane "$1" "$2"
   320	}

exec
/bin/zsh -lc "nl -ba utils/hq/hq-lib.sh | sed -n '1,360p'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# HQ resolver library (GH-128, Phase 0/1). READ-ONLY. Sourced by utils/hq/hq.sh and test/hq.sh.
     3	#
     4	# Resolution ladder (name -> repo -> path -> governance), each rung degrading gracefully to empty
     5	# when its source is missing/offline, so a partial registry set never hard-fails:
     6	#   1. Rebalance project_registry (rebalance.db) -> semantic project NAME -> repo list + priority
     7	#   2. XYZ install registry (registry.tsv)       -> repo -> ABSOLUTE PATH + runnable/drift stamps
     8	#   3. Git Pulse PDDA registry (registry-*.tsv)  -> repo -> PDDA mode + startup_docs (NO path)
     9	#   4. Filesystem `find` fallback                -> repo -> path when no registry knows it
    10	#
    11	# Output contract: functions emit `KEY=value` lines (never uses the reserved name PATH — see
    12	# REPO_PATH). Callers grep the keys; nothing is meant to be `eval`ed.
    13	#
    14	# Env seams (override for tests / non-default installs):
    15	#   HQ_PDDA_REGISTRY_DIR  default $HOME/git-pulse-sync/pdda        (globs registry-*.tsv)
    16	#   HQ_XYZ_REGISTRY       default ${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv
    17	#   HQ_REBALANCE_DB       default $HOME/Documents/rebalance-OS/rebalance.db
    18	#   HQ_SEARCH_ROOTS       default "$HOME/Documents/GH Repos:$HOME/Documents:$HOME" (colon-separated)
    19	#   HQ_OBSIDIAN_VAULT     default "$HOME/Documents/Noel Saw/Dashboards" (for rollup synthesis)
    20	
    21	: "${HQ_PDDA_REGISTRY_DIR:=$HOME/git-pulse-sync/pdda}"
    22	: "${HQ_XYZ_REGISTRY:=${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv}"
    23	: "${HQ_REBALANCE_DB:=$HOME/Documents/rebalance-OS/rebalance.db}"
    24	: "${HQ_SEARCH_ROOTS:=$HOME/Documents/GH Repos:$HOME/Documents:$HOME}"
    25	: "${HQ_OBSIDIAN_VAULT:=$HOME/Documents/Noel Saw/Dashboards}"
    26	
    27	hq_lc(){ printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
    28	hq_bare(){ printf '%s' "${1##*/}"; }                       # strip any owner/ prefix
    29	hq_sanitize(){ printf '%s' "$1" | tr -cd '[:alnum:]/_.- '; } # defang before SQL interpolation
    30	# hq_yaml_dq <string> -> escape for a YAML double-quoted scalar (backslash + double-quote). Without
    31	# this, a title containing " (or \) produces invalid frontmatter — GH-132.
    32	hq_yaml_dq(){ printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
    33	
    34	# hq_rebalance_lookup <query> -> REBAL_NAME / REBAL_TIER / REBAL_VALUE / REBAL_STATUS / REBAL_REPOS
    35	# Matches the human project NAME (owner/repo) exactly, or on its repo-part, case-insensitively.
    36	hq_rebalance_lookup(){
    37	  [ -f "$HQ_REBALANCE_DB" ] || return 0
    38	  command -v sqlite3 >/dev/null 2>&1 || return 0
    39	  local q qbare
    40	  q="$(hq_lc "$(hq_sanitize "$1")")"
    41	  qbare="$(hq_lc "$(hq_sanitize "$(hq_bare "$1")")")"
    42	  local row
    43	  row="$(sqlite3 -separator '|' "$HQ_REBALANCE_DB" \
    44	    "SELECT name, priority_tier, value_level, status, repos_json FROM project_registry
    45	       WHERE lower(name)='$q' OR lower(name)='$qbare' OR lower(name) LIKE '%/'||'$qbare'
    46	       LIMIT 1;" 2>/dev/null)" || return 0
    47	  [ -n "$row" ] || return 0
    48	  local name tier value status repos_json repos
    49	  IFS='|' read -r name tier value status repos_json <<<"$row"
    50	  repos="$(printf '%s' "$repos_json" | grep -oE '"[^"]+"' | tr -d '"' | sed 's#.*/##' | paste -sd, -)"
    51	  printf 'REBAL_NAME=%s\n'   "$name"
    52	  printf 'REBAL_TIER=%s\n'   "$tier"
    53	  printf 'REBAL_VALUE=%s\n'  "$value"
    54	  printf 'REBAL_STATUS=%s\n' "$status"
    55	  printf 'REBAL_REPOS=%s\n'  "$repos"
    56	}
    57	
    58	# hq_xyz_lookup <repo> [<slug_hint>] -> XYZ_PATH / XYZ_INSTALL / XYZ_TICK / XYZ_COMMIT for the LIVE
    59	# install whose coord basename matches <repo>. GH-132 hardening:
    60	#   * Blocker 2 — a registry row whose coord no longer exists on disk is NOT a usable install; skip it
    61	#     (so a stale row can't arm Tier A / `fire` at a dead path).
    62	#   * Blocker 1 — on a basename COLLISION among live installs, disambiguate by full `owner/repo` slug
    63	#     (authoritative: each candidate's git origin remote) when <slug_hint> carries an owner. If it still
    64	#     can't uniquely resolve, emit `XYZ_AMBIGUOUS=<paths>` and return 2 rather than guessing a path.
    65	hq_xyz_lookup(){
    66	  [ -f "$HQ_XYZ_REGISTRY" ] || return 0
    67	  local repo slug install _f tick commit coord
    68	  repo="$(hq_lc "$(hq_bare "$1")")"
    69	  slug="$(hq_lc "${2:-}")"
    70	  local matches=() seen_coords=()
    71	  while IFS=$'\t' read -r install _f tick commit coord; do
    72	    case "$install" in ''|'#'*) continue;; esac
    73	    [ -n "$coord" ] || continue
    74	    [ -d "$coord" ] || continue                          # stale row -> not a usable install (Blocker 2)
    75	    [ "$(hq_lc "$(hq_bare "$coord")")" = "$repo" ] || continue
    76	    
    77	    local i seen=-1
    78	    for i in "${!seen_coords[@]}"; do
    79	      if [ "${seen_coords[$i]}" = "$coord" ]; then
    80	        seen=$i
    81	        break
    82	      fi
    83	    done
    84	    if [ "$seen" -ge 0 ]; then
    85	      # If we see a duplicate coord but the new install is the vendored .xyz, prefer it
    86	      case "$install" in */.xyz) matches[$seen]="$install"$'\t'"$coord"$'\t'"$tick"$'\t'"$commit";; esac
    87	      continue
    88	    fi
    89	    seen_coords+=("$coord")
    90	
    91	    matches+=("$install"$'\t'"$coord"$'\t'"$tick"$'\t'"$commit")
    92	  done < "$HQ_XYZ_REGISTRY"
    93	
    94	  local n="${#matches[@]}"
    95	  [ "$n" -gt 0 ] || return 0
    96	
    97	  local chosen=""
    98	  if [ "$n" = 1 ]; then
    99	    chosen="${matches[0]}"
   100	  else
   101	    # Same-repo collapse (GH-132 follow-on): multiple registry rows can point at ONE repo — e.g. a
   102	    # repo carrying both a legacy `xyz-tick` install and the current vendored `.xyz`. They share the
   103	    # same coord (repo path), so there is no real path to guess between; collapse to it, preferring
   104	    # the vendored `.xyz` install's drift stamps. Only a collision across DIFFERENT repos is a true
   105	    # ambiguity that still needs the owner-slug tiebreak below.
   106	    local m mc first_coord="" all_same=1 dotxyz=""
   107	    for m in "${matches[@]}"; do
   108	      mc="$(printf '%s' "$m" | cut -f2)"
   109	      [ -n "$first_coord" ] || first_coord="$mc"
   110	      [ "$mc" = "$first_coord" ] || all_same=0
   111	      case "$(printf '%s' "$m" | cut -f1)" in */.xyz) dotxyz="$m";; esac
   112	    done
   113	    if [ "$all_same" = 1 ]; then
   114	      chosen="${dotxyz:-${matches[0]}}"
   115	    elif [ -n "$slug" ] && printf '%s' "$slug" | grep -q '/'; then
   116	      # basename collision across different repos + an owner-carrying hint: keep only candidates
   117	      # whose real git slug matches
   118	      local mslug hits=()
   119	      for m in "${matches[@]}"; do
   120	        mslug="$(hq_lc "$(hq_target_slug "$(printf '%s' "$m" | cut -f2)")")"
   121	        [ -n "$mslug" ] && [ "$mslug" = "$slug" ] && hits+=("$m")
   122	      done
   123	      [ "${#hits[@]}" = 1 ] && chosen="${hits[0]}"
   124	    fi
   125	  fi
   126	
   127	  if [ -n "$chosen" ]; then
   128	    printf 'XYZ_PATH=%s\n'    "$(printf '%s' "$chosen" | cut -f2)"
   129	    printf 'XYZ_INSTALL=%s\n' "$(printf '%s' "$chosen" | cut -f1)"
   130	    printf 'XYZ_TICK=%s\n'    "$(printf '%s' "$chosen" | cut -f3)"
   131	    printf 'XYZ_COMMIT=%s\n'  "$(printf '%s' "$chosen" | cut -f4)"
   132	    return 0
   133	  fi
   134	
   135	  # collision we won't resolve -> refuse to guess (Blocker 1)
   136	  local paths=() m sIFS
   137	  for m in "${matches[@]}"; do paths+=("$(printf '%s' "$m" | cut -f2)"); done
   138	  sIFS="$IFS"; IFS=,; printf 'XYZ_AMBIGUOUS=%s\n' "${paths[*]}"; IFS="$sIFS"
   139	  return 2
   140	}
   141	
   142	# hq_pdda_lookup <repo> -> PDDA_MODE / PDDA_STARTUP / PDDA_DEVICE  (scans every device registry)
   143	hq_pdda_lookup(){
   144	  [ -d "$HQ_PDDA_REGISTRY_DIR" ] || return 0
   145	  local repo; repo="$(hq_lc "$(hq_bare "$1")")"
   146	  local f rrepo mode startup
   147	  for f in "$HQ_PDDA_REGISTRY_DIR"/registry-*.tsv; do
   148	    [ -f "$f" ] || continue
   149	    while IFS=$'\t' read -r rrepo _ mode _ startup; do
   150	      case "$rrepo" in ''|'#'*) continue;; esac
   151	      if [ "$(hq_lc "$rrepo")" = "$repo" ]; then
   152	        printf 'PDDA_MODE=%s\n'    "$mode"
   153	        printf 'PDDA_STARTUP=%s\n' "$startup"
   154	        printf 'PDDA_DEVICE=%s\n'  "$(basename "$f" | sed 's/^registry-//; s/\.tsv$//')"
   155	        return 0
   156	      fi
   157	    done < "$f"
   158	  done
   159	}
   160	
   161	# hq_fs_find <repo> -> first git working tree named <repo> under the search roots (depth-capped)
   162	hq_fs_find(){
   163	  local repo; repo="$(hq_bare "$1")"
   164	  # GH-132: a glob-metachar token would be a `find -name` PATTERN, not a literal name — e.g. `resolve
   165	  # '*'` would match the first repo under the roots. A real repo name has no glob chars, so refuse to
   166	  # fall through to a filesystem match on one (return empty -> UNRESOLVED, not a wrong guess).
   167	  case "$repo" in *[\*\?\[]*) return 0;; esac
   168	  local saved="$IFS" root hit
   169	  IFS=':'
   170	  for root in $HQ_SEARCH_ROOTS; do
   171	    IFS="$saved"
   172	    [ -d "$root" ] || continue
   173	    hit="$(find "$root" -maxdepth 3 -type d -name "$repo" -exec test -d '{}/.git' \; -print 2>/dev/null | head -1)"
   174	    [ -n "$hit" ] && { printf '%s\n' "$hit"; return 0; }
   175	  done
   176	  IFS="$saved"
   177	  return 0
   178	}
   179	
   180	# ---- Fuzzy resolution (Phase 1.x) --------------------------------------------------------------
   181	# Loose names ("rebalanceOS", "rebalance os", "REBALANCE-OS") should resolve to the canonical repo,
   182	# but a genuinely ambiguous name must return candidates rather than guess.
   183	
   184	hq_norm(){ printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]'; }  # lower + alnum-only
   185	hq_contains(){ case "$1" in *"$2"*) return 0;; *) return 1;; esac; }
   186	
   187	# hq_known_repos -> every distinct repo name any registry knows (one per line). Filesystem is NOT
   188	# enumerated here (too broad); the exact path-resolve already covers on-disk repos.
   189	hq_known_repos(){
   190	  {
   191	    if [ -f "$HQ_REBALANCE_DB" ] && command -v sqlite3 >/dev/null 2>&1; then
   192	      sqlite3 "$HQ_REBALANCE_DB" 'SELECT name FROM project_registry;' 2>/dev/null | sed 's#.*/##'
   193	    fi
   194	    if [ -f "$HQ_XYZ_REGISTRY" ]; then
   195	      local install coord
   196	      while IFS=$'\t' read -r install _ _ _ coord; do
   197	        case "$install" in ''|'#'*) continue;; esac
   198	        [ -n "$coord" ] && basename "$coord"
   199	      done < "$HQ_XYZ_REGISTRY"
   200	    fi
   201	    if [ -d "$HQ_PDDA_REGISTRY_DIR" ]; then
   202	      local f rrepo
   203	      for f in "$HQ_PDDA_REGISTRY_DIR"/registry-*.tsv; do
   204	        [ -f "$f" ] || continue
   205	        while IFS=$'\t' read -r rrepo _; do
   206	          case "$rrepo" in ''|'#'*) continue;; esac
   207	          printf '%s\n' "$rrepo"
   208	        done < "$f"
   209	      done
   210	    fi
   211	  } | awk 'NF' | sort -u
   212	}
   213	
   214	# hq_candidates <query> -> matching repo names. Normalized-EQUAL matches win outright; only if there
   215	# are none does it fall back to substring matches (either direction). Deduped, one per line.
   216	hq_candidates(){
   217	  local q; q="$(hq_norm "$1")"
   218	  [ -n "$q" ] || return 0
   219	  local name n equal=() sub=()
   220	  while IFS= read -r name; do
   221	    n="$(hq_norm "$name")"
   222	    if [ "$n" = "$q" ]; then equal+=("$name")
   223	    elif hq_contains "$n" "$q" || hq_contains "$q" "$n"; then sub+=("$name")
   224	    fi
   225	  done < <(hq_known_repos)
   226	  if   [ "${#equal[@]}" -gt 0 ]; then printf '%s\n' "${equal[@]}" | sort -u
   227	  elif [ "${#sub[@]}"   -gt 0 ]; then printf '%s\n' "${sub[@]}"   | sort -u
   228	  fi
   229	}
   230	
   231	# hq_repo_resolve <repo> [<slug_hint>] -> XYZ_*/PDDA_* + REPO_PATH= + REPO_PATH_SOURCE=
   232	# (xyz-registry|filesystem|ambiguous|''). <slug_hint> (an owner/repo) is only used to break an XYZ
   233	# basename collision (GH-132). On an unresolved collision it emits XYZ_AMBIGUOUS + empty REPO_PATH.
   234	hq_repo_resolve(){
   235	  local repo="$1" slug="${2:-}" xyz xrc amb path src="" pdda xyz_path
   236	  xyz="$(hq_xyz_lookup "$repo" "$slug")"; xrc=$?
   237	  if [ "$xrc" = 2 ]; then
   238	    amb="$(printf '%s\n' "$xyz" | sed -n 's/^XYZ_AMBIGUOUS=//p')"
   239	    printf 'XYZ_AMBIGUOUS=%s\n' "$amb"
   240	    printf 'REPO_PATH=\n'
   241	    printf 'REPO_PATH_SOURCE=ambiguous\n'
   242	    return 0
   243	  fi
   244	  xyz_path="$(printf '%s\n' "$xyz" | sed -n 's/^XYZ_PATH=//p')"   # already existence-filtered
   245	  if [ -n "$xyz_path" ]; then src="xyz-registry"; path="$xyz_path"
   246	  else path="$(hq_fs_find "$repo")"; [ -n "$path" ] && src="filesystem"; fi
   247	  pdda="$(hq_pdda_lookup "$repo")"
   248	  [ -n "$xyz" ]  && printf '%s\n' "$xyz"
   249	  [ -n "$pdda" ] && printf '%s\n' "$pdda"
   250	  printf 'REPO_PATH=%s\n' "$path"
   251	  printf 'REPO_PATH_SOURCE=%s\n' "$src"
   252	}
   253	
   254	# hq_resolve <query> -> QUERY / REPO / RESOLVED_VIA / REPO_PATH / REPO_PATH_SOURCE + REBAL_/XYZ_/PDDA_.
   255	# Exit 0 if a REPO_PATH was resolved (exact or fuzzy), 2 if the name is ambiguous (CANDIDATES listed),
   256	# 1 if unresolved.
   257	hq_resolve(){
   258	  local query="$1" rebal repo fields path via="exact" slug_hint amb
   259	  rebal="$(hq_rebalance_lookup "$query")"
   260	  repo="$(printf '%s\n' "$rebal" | sed -n 's/^REBAL_REPOS=//p' | cut -d, -f1)"
   261	  [ -n "$repo" ] || repo="$(hq_bare "$query")"
   262	  # GH-132: slug hint for an XYZ basename collision — prefer an owner-carrying query, else the
   263	  # Rebalance project NAME (owner/repo). Bare names give no owner, so a collision stays ambiguous.
   264	  case "$query" in */*) slug_hint="$query";; *) slug_hint="";; esac
   265	  [ -n "$slug_hint" ] || slug_hint="$(printf '%s\n' "$rebal" | sed -n 's/^REBAL_NAME=//p')"
   266	  fields="$(hq_repo_resolve "$repo" "$slug_hint")"
   267	  amb="$(printf '%s\n' "$fields" | sed -n 's/^XYZ_AMBIGUOUS=//p')"
   268	  if [ -n "$amb" ]; then
   269	    printf 'QUERY=%s\nREPO=%s\nRESOLVED_VIA=ambiguous\nCANDIDATES=%s\nREPO_PATH=\nREPO_PATH_SOURCE=ambiguous\n' \
   270	      "$query" "$repo" "$amb"
   271	    return 2
   272	  fi
   273	  path="$(printf '%s\n' "$fields" | sed -n 's/^REPO_PATH=//p' | head -1)"
   274	
   275	  if [ -z "$path" ]; then
   276	    local cands count
   277	    cands="$(hq_candidates "$query")"
   278	    count="$(printf '%s' "$cands" | grep -c .)"
   279	    if [ "$count" = 1 ]; then
   280	      repo="$cands"; via="fuzzy"
   281	      rebal="$(hq_rebalance_lookup "$repo")"
   282	      fields="$(hq_repo_resolve "$repo" "$(printf '%s\n' "$rebal" | sed -n 's/^REBAL_NAME=//p')")"
   283	      amb="$(printf '%s\n' "$fields" | sed -n 's/^XYZ_AMBIGUOUS=//p')"
   284	      if [ -n "$amb" ]; then
   285	        printf 'QUERY=%s\nREPO=%s\nRESOLVED_VIA=ambiguous\nCANDIDATES=%s\nREPO_PATH=\nREPO_PATH_SOURCE=ambiguous\n' \
   286	          "$query" "$repo" "$amb"
   287	        return 2
   288	      fi
   289	      path="$(printf '%s\n' "$fields" | sed -n 's/^REPO_PATH=//p' | head -1)"
   290	    elif [ "$count" -gt 1 ]; then
   291	      printf 'QUERY=%s\nREPO=\nRESOLVED_VIA=ambiguous\nCANDIDATES=%s\nREPO_PATH=\nREPO_PATH_SOURCE=ambiguous\n' \
   292	        "$query" "$(printf '%s' "$cands" | paste -sd, -)"
   293	      return 2
   294	    fi
   295	  fi
   296	
   297	  printf 'QUERY=%s\nREPO=%s\nRESOLVED_VIA=%s\n' "$query" "$repo" "$via"
   298	  [ -n "$rebal" ] && printf '%s\n' "$rebal"
   299	  if [ -n "$path" ]; then
   300	    printf '%s\n' "$fields"
   301	    return 0
   302	  fi
   303	  printf '%s\n' "$fields" | sed 's/^REPO_PATH_SOURCE=$/REPO_PATH_SOURCE=unresolved/'
   304	  return 1
   305	}
   306	
   307	# hq_inspect_repo <path> -> repo-local governance facts (authoritative over the registries)
   308	hq_inspect_repo(){
   309	  local p="$1"
   310	  [ -d "$p" ] || return 0
   311	  [ -f "$p/.pdda-mode" ]        && printf 'LOCAL_PDDA_MODE=%s\n' "$(head -1 "$p/.pdda-mode" | tr -d '[:space:]')"
   312	  [ -f "$p/ROUTER.md" ]         && printf 'LOCAL_ROUTER=yes\n'
   313	  [ -f "$p/AGENTS.md" ]         && printf 'LOCAL_AGENTS=yes\n'
   314	  [ -f "$p/ROADMAP.md" ]        && printf 'LOCAL_ROADMAP=yes\n'
   315	  [ -f "$p/utils/pdda/pdda.sh" ] && printf 'LOCAL_PDDA_SH=yes\n'
   316	  if [ -d "$p/PROJECT/2-WORKING" ]; then
   317	    local n mp
   318	    n="$(find "$p/PROJECT/2-WORKING" -maxdepth 1 -name '*.md' ! -name 'blank.md' 2>/dev/null | wc -l | tr -d ' ')"
   319	    printf 'LOCAL_ACTIVE_DOCS=%s\n' "$n"
   320	    # Broadened from 'MARATHON-PLAN-*.md' to 'MARATHON-*.md' (GH-138): a target repo may name its
   321	    # plan MARATHON-<date>.md (e.g. rebalance-OS) rather than this repo's MARATHON-PLAN-<date>.md.
   322	    mp="$(find "$p/PROJECT/2-WORKING" -maxdepth 1 -name 'MARATHON-*.md' 2>/dev/null | sort | tail -1)"
   323	    [ -n "$mp" ] && printf 'LOCAL_MARATHON=%s\n' "$(basename "$mp")"
   324	  fi
   325	}
   326	
   327	# hq_tier <has_pdda 0|1> <has_xyz 0|1> -> A (PDDA+XYZ) / B (PDDA only) / C (bare)
   328	hq_tier(){
   329	  if [ "$1" = 1 ] && [ "$2" = 1 ]; then echo A
   330	  elif [ "$1" = 1 ]; then echo B
   331	  else echo C; fi
   332	}
   333	
   334	# ---- Phase 2 (intake writer) helpers ------------------------------------------------------------
   335	
   336	# hq_slug <request text> -> SCREAMING-KEBAB of up to 4 meaningful words (stopwords dropped).
   337	# Falls back to REQUEST when nothing survives. Used for the GH-<n>-<SLUG>.md capture filename.
   338	hq_slug(){
   339	  local s
   340	  s="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '\n' \
   341	        | grep -vxE '(the|a|an|to|for|of|and|do|this|that|please|add|make|it)' \
   342	        | head -4 | tr '[:lower:]' '[:upper:]' | paste -sd- -)"
   343	  [ -n "$s" ] && printf '%s' "$s" || printf 'REQUEST'
   344	}
   345	
   346	# hq_issue_title <project> <request> -> a concise (<=72 char) issue title.
   347	hq_issue_title(){
   348	  local t="$2"
   349	  [ "${#t}" -le 72 ] || t="${t:0:69}..."
   350	  printf '%s' "$t"
   351	}
   352	
   353	# hq_render_capture <issue_num> <source_url> <title> <created> <doc_type> <project> <repo> <request>
   354	#                    [<complexity>] [<risk>] [<effort>] [<phases>]
   355	#                    [<why>] [<key_concepts_pipe>] [<non_goals_pipe>] [<related_pipe>]
   356	# Emits a PDDA-compliant 1-INBOX capture doc: the full skeleton shape (frontmatter ratings/non_goals/
   357	# related/goal + Key Concepts/Idea/Why/Phase-0-checklist/QA-checklist body) that GH-161-164's real
   358	# docs use — not the older thin Request/Notes template. GH-164 Phase 1, item 1.
   359	#
   360	# The 8 trailing params are OPTIONAL and default to a generic TODO-stub value when omitted, so a bare

codex
I’ve got the implementation. Next I’m checking the existing marathon report shape and the PR diff itself so I can see whether the heading/frontmatter rewrite matches the real output and whether the new test misses any important failure mode.
exec
/bin/zsh -lc "nl -ba test/hq-marathon-scan.sh | sed -n '1,260p'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# GH-158: hermetic regression lock for utils/hq/marathon-scan.sh.
     3	#
     4	# Builds fixture registries + fixture repos, stubs each target repo's own swarm-preflight.sh, and
     5	# asserts the scanner classifies all five lane verdicts plus Held-not-counted without writing inside
     6	# any target repo.
     7	
     8	set -uo pipefail
     9	
    10	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    11	ROOT="$(cd "$HERE/.." && pwd)"
    12	SCAN="$ROOT/utils/hq/marathon-scan.sh"
    13	
    14	WORK="$(mktemp -d "${TMPDIR:-/tmp}/hq-marathon-scan.XXXXXX")"
    15	trap 'rm -rf "$WORK"' EXIT
    16	
    17	PASS=0
    18	FAIL=0
    19	pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
    20	fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
    21	
    22	echo "== test: hq-marathon-scan =="
    23	echo "  workdir: $WORK"
    24	
    25	make_repo() {
    26	  local name="$1"
    27	  local repo="$WORK/repos/$name"
    28	  mkdir -p "$repo/.git" "$repo/PROJECT/2-WORKING" "$repo/PROJECT/1-INBOX" "$repo/PROJECT/3-COMPLETED" "$repo/utils"
    29	  cat >"$repo/utils/swarm-preflight.sh" <<'EOF'
    30	#!/usr/bin/env bash
    31	set -uo pipefail
    32	MODE="" ISSUE="" DOC=""
    33	while (($# > 0)); do
    34	  case "$1" in
    35	    --gh-issue) ISSUE="${2:-}"; shift 2 ;;
    36	    --project-doc) DOC="${2:-}"; shift 2 ;;
    37	    --target-root|--format|--dry-run) shift ;;
    38	    *) shift ;;
    39	  esac
    40	done
    41	if [[ -n "$ISSUE" ]]; then
    42	  case "$ISSUE" in
    43	    101) echo '{"readiness":{"ready":true}}'; exit 0 ;;
    44	    201) echo '{"readiness":{"ready":false}}'; exit 6 ;;
    45	    301) echo '{"readiness":{"ready":false}}'; exit 6 ;;
    46	    501) echo '{"readiness":{"ready":false}}'; exit 7 ;;
    47	  esac
    48	fi
    49	case "$DOC" in
    50	  PROJECT/3-COMPLETED/RELAY-TO-ISSUE-SKILL.md) echo '{"readiness":{"ready":false}}'; exit 4 ;;
    51	  *) echo '{"readiness":{"ready":false}}'; exit 6 ;;
    52	esac
    53	EOF
    54	  chmod +x "$repo/utils/swarm-preflight.sh"
    55	  cat >"$repo/ROADMAP.md" <<'EOF'
    56	# Roadmap
    57	## Ledger
    58	### In progress
    59	- **relay-to-issue-skill** 🟡 — stale pointer → [d](PROJECT/2-WORKING/RELAY-TO-ISSUE-SKILL.md)
    60	EOF
    61	  printf '%s' "$repo"
    62	}
    63	
    64	mk_doc() {
    65	  local path="$1" title="$2" status="$3"
    66	  cat >"$path" <<EOF
    67	---
    68	title: $title
    69	status: $status
    70	---
    71	
    72	# $title
    73	
    74	## Swarm Preflight Contract
    75	\`\`\`json
    76	{"target":{"repo":".","ref":"main"},"gate":"true","fix_probes":[{"type":"path_absent","path":"missing.txt"}],"artifacts":["src/a.js"]}
    77	\`\`\`
    78	EOF
    79	}
    80	
    81	mk_marathon() {
    82	  local path="$1" title="$2" status="$3" lanes="$4"
    83	  cat >"$path" <<EOF
    84	---
    85	title: $title
    86	status: $status
    87	---
    88	
    89	# $title
    90	
    91	## Recommended waves
    92	
    93	**Wave 1:** $lanes
    94	EOF
    95	}
    96	
    97	READY_REPO="$(make_repo ready-repo)"
    98	PROMOTE_REPO="$(make_repo promote-repo)"
    99	BLOCKED_REPO="$(make_repo blocked-repo)"
   100	STALE_REPO="$(make_repo stale-repo)"
   101	AMBIG_REPO="$(make_repo ambiguous-repo)"
   102	HELD_REPO="$(make_repo held-repo)"
   103	
   104	mk_doc "$READY_REPO/PROJECT/2-WORKING/GH-101-READY.md" GH-101-ready "Active"
   105	mk_doc "$PROMOTE_REPO/PROJECT/1-INBOX/GH-201-PROMOTE.md" GH-201-promote "Open"
   106	mk_doc "$BLOCKED_REPO/PROJECT/2-WORKING/GH-301-BLOCKED.md" GH-301-blocked "Active"
   107	mk_doc "$AMBIG_REPO/PROJECT/2-WORKING/GH-501-AMBIG.md" GH-501-ambig "Active"
   108	mk_doc "$STALE_REPO/PROJECT/3-COMPLETED/RELAY-TO-ISSUE-SKILL.md" relay-to-issue-skill "Shipped"
   109	
   110	mk_marathon "$READY_REPO/PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md" ready-marathon "Active" "#101"
   111	mk_marathon "$PROMOTE_REPO/PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md" promote-marathon "Active" "#201"
   112	mk_marathon "$BLOCKED_REPO/PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md" blocked-marathon "Active" "#301"
   113	mk_marathon "$STALE_REPO/PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md" stale-marathon "Active" "relay-to-issue-skill"
   114	mk_marathon "$AMBIG_REPO/PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md" ambiguous-marathon "Active" "#501"
   115	mk_marathon "$HELD_REPO/PROJECT/2-WORKING/MARATHON-2026-07-06-B.md" held-marathon "Held (operator go)" "#601"
   116	
   117	PDDA_DIR="$WORK/pdda"
   118	mkdir -p "$PDDA_DIR"
   119	cat >"$PDDA_DIR/registry-test.tsv" <<EOF
   120	ready-repo	2026-07-06T00:00:00Z	observe	abc	yes
   121	promote-repo	2026-07-06T00:00:00Z	observe	abc	yes
   122	blocked-repo	2026-07-06T00:00:00Z	observe	abc	yes
   123	stale-repo	2026-07-06T00:00:00Z	observe	abc	yes
   124	ambiguous-repo	2026-07-06T00:00:00Z	observe	abc	yes
   125	held-repo	2026-07-06T00:00:00Z	observe	abc	yes
   126	EOF
   127	
   128	XYZ_REG="$WORK/xyz.tsv"
   129	cat >"$XYZ_REG" <<EOF
   130	$READY_REPO/.xyz	2026-07-06T00:00:00Z	0.2.0	a1	$READY_REPO
   131	$PROMOTE_REPO/.xyz	2026-07-06T00:00:00Z	0.2.0	a1	$PROMOTE_REPO
   132	$BLOCKED_REPO/.xyz	2026-07-06T00:00:00Z	0.2.0	a1	$BLOCKED_REPO
   133	$STALE_REPO/.xyz	2026-07-06T00:00:00Z	0.2.0	a1	$STALE_REPO
   134	$AMBIG_REPO/.xyz	2026-07-06T00:00:00Z	0.2.0	a1	$AMBIG_REPO
   135	$HELD_REPO/.xyz	2026-07-06T00:00:00Z	0.2.0	a1	$HELD_REPO
   136	EOF
   137	
   138	OUT="$WORK/HQ-MARATHON-2026-07-06.md"
   139	HQ_PDDA_REGISTRY_DIR="$PDDA_DIR" \
   140	HQ_XYZ_REGISTRY="$XYZ_REG" \
   141	HQ_SEARCH_ROOTS="$WORK/repos" \
   142	HQ_MARATHON_SCAN_TODAY="2026-07-06" \
   143	HQ_MARATHON_SCAN_NOW="2026-07-06T12:00:00Z" \
   144	bash "$SCAN" --out "$OUT" >/dev/null 2>&1
   145	rc=$?
   146	[[ $rc -eq 0 ]] && pass "scan exits 0" || fail "scan rc=$rc"
   147	[[ -f "$OUT" ]] && pass "report written" || fail "report missing"
   148	
   149	grep -q '| ready-repo | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md` | Active | ✅ active |' "$OUT" \
   150	  && pass "ready repo surfaced in source table" || fail "ready repo missing from source table"
   151	grep -q '| #101 | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md` | `gh-issue #101` | ✅ ready (exit 0) |' "$OUT" \
   152	  && pass "ready lane classified" || fail "ready lane not classified"
   153	grep -q '| #201 | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md` | `gh-issue #201` | ⚠️ blocked-not-promoted (exit 6) |' "$OUT" \
   154	  && pass "blocked-not-promoted lane classified" || fail "blocked-not-promoted missing"
   155	grep -q '| #301 | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md` | `gh-issue #301` | ⛔ blocked-other (exit 6) |' "$OUT" \
   156	  && pass "blocked-other lane classified" || fail "blocked-other missing"
   157	grep -q '| relay-to-issue-skill | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md` | `PROJECT/3-COMPLETED/RELAY-TO-ISSUE-SKILL.md` | ⚠️ stale-already-landed (exit 4) |' "$OUT" \
   158	  && pass "named ghost lane resolves to completed doc and classifies stale" || fail "stale ghost lane missing"
   159	grep -q '| #501 | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md` | `gh-issue #501` | ❓ ambiguous (exit 7) |' "$OUT" \
   160	  && pass "ambiguous lane classified" || fail "ambiguous missing"
   161	grep -q '| held-repo | `PROJECT/2-WORKING/MARATHON-2026-07-06-B.md` | Held (operator go) | 🟡 held, not counted |' "$OUT" \
   162	  && pass "held marathon surfaced but marked not counted" || fail "held marathon missing"
   163	
   164	grep -q -- '- Ready: 1' "$OUT" \
   165	  && grep -q -- '- Blocked-not-promoted: 1' "$OUT" \
   166	  && grep -q -- '- Blocked-other: 1' "$OUT" \
   167	  && grep -q -- '- Stale-already-landed: 1' "$OUT" \
   168	  && grep -q -- '- Ambiguous: 1' "$OUT" \
   169	  && grep -q -- '- Held marathons surfaced, not counted: 1' "$OUT" \
   170	  && pass "net counts match fixture matrix" \
   171	  || fail "net counts wrong: $(grep -E '^- (Ready|Blocked|Stale|Ambiguous|Held)' "$OUT")"
   172	
   173	if find "$WORK/repos" -path '*/PROJECT/2-WORKING/HQ-MARATHON-*' -o -path '*/packet/*' | grep -q .; then
   174	  fail "scanner wrote inside a target repo"
   175	else
   176	  pass "scanner stayed read-only over target repos"
   177	fi
   178	
   179	echo "== hq-marathon-scan: $PASS passed, $FAIL failed =="
   180	[ "$FAIL" -eq 0 ]

exec
/bin/zsh -lc 'rg -n "generated_by:|''^# HQ MARATHON|''^## Repo summary|''^### " -n utils/hq/marathon-scan.sh test/hq-marathon-scan.sh PROJECT/3-COMPLETED/GH-158-HQ-MARATHON-SCAN.md PROJECT/1-INBOX/GH-192-HQ-MARATHON-OBSIDIAN-ROLLUP.md' in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241
 exited 2 in 0ms:
rg: PROJECT/1-INBOX/GH-192-HQ-MARATHON-OBSIDIAN-ROLLUP.md: No such file or directory (os error 2)
test/hq-marathon-scan.sh:58:### In progress
utils/hq/marathon-scan.sh:458:generated_by: utils/hq/marathon-scan.sh
utils/hq/marathon-scan.sh:461:# HQ MARATHON — $TODAY

exec
/bin/zsh -lc "git diff --stat main...HEAD && printf '\\n---\\n' && git diff --unified=80 main...HEAD -- utils/hq/rollup.sh test/hq-rollup.sh validate.sh" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241
exec
/bin/zsh -lc "nl -ba utils/hq/marathon-scan.sh | sed -n '320,560p'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241
 succeeded in 0ms:
   320	}
   321	
   322	classify_blocked() {
   323	  local repo="$1" kind="$2" issue="$3" project_doc="$4"
   324	  if [[ "$kind" == "gh-issue" && "$issue" =~ ^[0-9]+$ ]]; then
   325	    local inbox working
   326	    inbox="$(find "$repo/PROJECT/1-INBOX" -maxdepth 1 -type f -name "GH-$issue-*.md" 2>/dev/null | head -1 || true)"
   327	    working="$(find "$repo/PROJECT/2-WORKING" -maxdepth 1 -type f -name "GH-$issue-*.md" 2>/dev/null | head -1 || true)"
   328	    [[ -n "$inbox" && -z "$working" ]] && { printf 'blocked-not-promoted'; return; }
   329	  fi
   330	  if [[ "$kind" == "project-doc" && "$project_doc" == PROJECT/1-INBOX/* ]]; then
   331	    printf 'blocked-not-promoted'
   332	    return
   333	  fi
   334	  printf 'blocked-other'
   335	}
   336	
   337	fireable_ready=0
   338	blocked_not_promoted=0
   339	blocked_other=0
   340	stale_already_landed=0
   341	ambiguous_count=0
   342	held_docs=0
   343	active_lanes=0
   344	
   345	while IFS= read -r repo; do
   346	  [[ -n "$repo" ]] || continue
   347	  fields="$(hq_repo_resolve "$repo")"
   348	  repo_path="$(printf '%s\n' "$fields" | sed -n 's/^REPO_PATH=//p' | head -1)"
   349	  [[ -n "$repo_path" && -d "$repo_path/PROJECT/2-WORKING" ]] || continue
   350	
   351	  while IFS= read -r doc; do
   352	    [[ -n "$doc" ]] || continue
   353	    meta="$(parse_marathon_doc "$doc")" || continue
   354	    doc_rel="${doc#$repo_path/}"
   355	    title="$(printf '%s' "$meta" | node -e 'const o=JSON.parse(require("fs").readFileSync(0,"utf8"));process.stdout.write(o.title||"")')"
   356	    status="$(printf '%s' "$meta" | node -e 'const o=JSON.parse(require("fs").readFileSync(0,"utf8"));process.stdout.write(o.status||"")')"
   357	    waves_flat="$(printf '%s' "$meta" | node -e 'const o=JSON.parse(require("fs").readFileSync(0,"utf8"));for (const wave of (o.waves||[])) { for (const lane of wave) console.log(lane); }')"
   358	    status_kind="other"
   359	    case "$(printf '%s' "$status" | tr '[:upper:]' '[:lower:]')" in
   360	      active*) status_kind="active" ;;
   361	      held*) status_kind="held" ;;
   362	      completed*|shipped*) status_kind="closed" ;;
   363	    esac
   364	    in_scope="closed"
   365	    [[ "$status_kind" == "active" ]] && in_scope="active"
   366	    [[ "$status_kind" == "held" ]] && { in_scope="held"; held_docs=$((held_docs + 1)); }
   367	    printf '%s\t%s\t%s\t%s\t%s\n' \
   368	      "$(tsv_escape "$repo")" \
   369	      "$(tsv_escape "$doc_rel")" \
   370	      "$(tsv_escape "$title")" \
   371	      "$(tsv_escape "$status")" \
   372	      "$in_scope" >>"$STATUS_TSV"
   373	
   374	    [[ "$status_kind" == "active" ]] || continue
   375	    while IFS= read -r lane; do
   376	      [[ -n "$lane" ]] || continue
   377	      active_lanes=$((active_lanes + 1))
   378	      resolution="$(resolve_lane "$repo_path" "$lane")"
   379	      kind="$(printf '%s' "$resolution" | node -e 'const o=JSON.parse(require("fs").readFileSync(0,"utf8"));process.stdout.write(o.kind||"")')"
   380	      issue="$(printf '%s' "$resolution" | node -e 'const o=JSON.parse(require("fs").readFileSync(0,"utf8"));process.stdout.write(o.issue==null?"":String(o.issue))')"
   381	      project_doc="$(printf '%s' "$resolution" | node -e 'const o=JSON.parse(require("fs").readFileSync(0,"utf8"));process.stdout.write(o.project_doc||"")')"
   382	      resolution_display="$kind"
   383	      preflight_exit=""
   384	      classification=""
   385	      if [[ "$kind" == "gh-issue" ]]; then
   386	        resolution_display="gh-issue #$issue"
   387	      elif [[ "$kind" == "project-doc" ]]; then
   388	        resolution_display="$project_doc"
   389	      elif [[ "$kind" == "ambiguous" ]]; then
   390	        resolution_display="$(printf '%s' "$resolution" | node -e 'const o=JSON.parse(require("fs").readFileSync(0,"utf8"));process.stdout.write((o.candidates||[]).join(", "))')"
   391	      fi
   392	
   393	      if [[ "$kind" == "ambiguous" || "$kind" == "unresolved" ]]; then
   394	        classification="ambiguous"
   395	        preflight_exit="7"
   396	        ambiguous_count=$((ambiguous_count + 1))
   397	      elif [[ ! -x "$repo_path/utils/swarm-preflight.sh" && ! -f "$repo_path/utils/swarm-preflight.sh" ]]; then
   398	        classification="blocked-other"
   399	        preflight_exit="6"
   400	        blocked_other=$((blocked_other + 1))
   401	      else
   402	        cmd=(bash "$repo_path/utils/swarm-preflight.sh" --target-root "$repo_path" --dry-run --format json)
   403	        if [[ "$kind" == "gh-issue" ]]; then
   404	          cmd+=(--gh-issue "$issue")
   405	        else
   406	          cmd+=(--project-doc "$project_doc")
   407	        fi
   408	        if "${cmd[@]}" >/dev/null 2>"$TMP/preflight.err"; then
   409	          preflight_exit="0"
   410	        else
   411	          preflight_exit="$?"
   412	        fi
   413	        case "$preflight_exit" in
   414	          0) classification="ready"; fireable_ready=$((fireable_ready + 1)) ;;
   415	          4) classification="stale-already-landed"; stale_already_landed=$((stale_already_landed + 1)) ;;
   416	          7) classification="ambiguous"; ambiguous_count=$((ambiguous_count + 1)) ;;
   417	          *)
   418	            classification="$(classify_blocked "$repo_path" "$kind" "$issue" "$project_doc")"
   419	            if [[ "$classification" == "blocked-not-promoted" ]]; then
   420	              blocked_not_promoted=$((blocked_not_promoted + 1))
   421	            else
   422	              blocked_other=$((blocked_other + 1))
   423	            fi
   424	            ;;
   425	        esac
   426	      fi
   427	      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
   428	        "$(tsv_escape "$repo")" \
   429	        "$(tsv_escape "$doc_rel")" \
   430	        "$(tsv_escape "$lane")" \
   431	        "$(tsv_escape "$resolution_display")" \
   432	        "$preflight_exit" \
   433	        "$classification" \
   434	        "$kind" >>"$LANE_TSV"
   435	    done <<<"$waves_flat"
   436	  done < <(find "$repo_path/PROJECT/2-WORKING" -maxdepth 1 -type f \( -iname '*marathon*.md' \) ! -name 'GH-*' ! -name 'HQ-MARATHON-*' | sort)
   437	done < <(hq_known_repos)
   438	
   439	repos_total="$(cut -f1 "$STATUS_TSV" 2>/dev/null | sort -u | sed '/^$/d' | wc -l | tr -d ' ')"
   440	docs_total="$(wc -l <"$STATUS_TSV" | tr -d ' ')"
   441	
   442	{
   443	  cat <<EOF
   444	---
   445	title: HQ MARATHON — $TODAY (cross-repo rollup, orchestrated from xyz-3-agents-swarm)
   446	status: Active
   447	created: $TODAY
   448	updated: $TODAY
   449	owner: noel@neochro.me
   450	scope: >
   451	  Repos with marathon docs under PROJECT/2-WORKING/, enumerated from the HQ PDDA registry and
   452	  resolved via hq-lib.sh. Active docs are preflighted lane-by-lane with each repo's own
   453	  utils/swarm-preflight.sh --dry-run; Held docs are surfaced but never counted as fireable.
   454	goal: >
   455	  Give the operator one at-a-glance cross-repo rollup of every marathon doc's status and
   456	  preflight verdict on this device, regenerated fresh each run rather than hand-maintained.
   457	roadmap_exempt: true
   458	generated_by: utils/hq/marathon-scan.sh
   459	---
   460	
   461	# HQ MARATHON — $TODAY
   462	
   463	## Source registry
   464	
   465	\`hq_known_repos\` + \`hq_repo_resolve\` from \`utils/hq/hq-lib.sh\`.
   466	
   467	| Repo | Marathon file | Status | In scope? |
   468	|---|---|---|---|
   469	EOF
   470	
   471	  while IFS=$'\t' read -r repo doc_rel title status in_scope; do
   472	    scope_label="❌ closed"
   473	    [[ "$in_scope" == "active" ]] && scope_label="✅ active"
   474	    [[ "$in_scope" == "held" ]] && scope_label="🟡 held, not counted"
   475	    printf '| %s | `%s` | %s | %s |\n' "$repo" "$doc_rel" "$status" "$scope_label"
   476	  done <"$STATUS_TSV"
   477	
   478	  current_repo=""
   479	  while IFS=$'\t' read -r repo doc_rel lane resolution_display preflight_exit classification kind; do
   480	    if [[ "$repo" != "$current_repo" ]]; then
   481	      [[ -n "$current_repo" ]] && printf '\n'
   482	      printf '## %s\n\n' "$repo"
   483	      printf '| Lane | Source marathon | Resolution | Verdict |\n'
   484	      printf '|---|---|---|---|\n'
   485	      current_repo="$repo"
   486	    fi
   487	    verdict="$classification"
   488	    case "$classification" in
   489	      ready) verdict="✅ ready (exit 0)" ;;
   490	      blocked-not-promoted) verdict="⚠️ blocked-not-promoted (exit $preflight_exit)" ;;
   491	      blocked-other) verdict="⛔ blocked-other (exit $preflight_exit)" ;;
   492	      stale-already-landed) verdict="⚠️ stale-already-landed (exit 4)" ;;
   493	      ambiguous) verdict="❓ ambiguous (exit $preflight_exit)" ;;
   494	    esac
   495	    printf '| %s | `%s` | `%s` | %s |\n' "$lane" "$doc_rel" "$resolution_display" "$verdict"
   496	  done <"$LANE_TSV"
   497	
   498	  cat <<EOF
   499	
   500	## Status
   501	
   502	| What was just completed | What's next |
   503	|---|---|
   504	| Scanned $repos_total repo(s), found $docs_total marathon doc(s), preflighted $active_lanes active lane(s): $fireable_ready ready, $blocked_not_promoted blocked-not-promoted, $blocked_other blocked-other, $stale_already_landed stale-already-landed, $ambiguous_count ambiguous; $held_docs held marathon(s) surfaced but not counted. | Re-run \`utils/hq/marathon-scan.sh\` to refresh; fire any ready lane via that repo's own \`swarm-preflight.sh\` → \`marathon-drive.sh\`. |
   505	
   506	## Net result
   507	
   508	- Repos scanned: $repos_total
   509	- Marathon docs found: $docs_total
   510	- Active lanes scanned: $active_lanes
   511	- Ready: $fireable_ready
   512	- Blocked-not-promoted: $blocked_not_promoted
   513	- Blocked-other: $blocked_other
   514	- Stale-already-landed: $stale_already_landed
   515	- Ambiguous: $ambiguous_count
   516	- Held marathons surfaced, not counted: $held_docs
   517	
   518	## Notes
   519	
   520	- The scanner is read-only over target repos. It writes only this aggregate doc.
   521	- Each active lane is preflighted with that repo's own \`utils/swarm-preflight.sh --dry-run\`.
   522	- Held marathons are surfaced for operator awareness but excluded from the fireable count by design.
   523	EOF
   524	} >"$OUT"
   525	
   526	printf 'hq marathon-scan: wrote %s\n' "$OUT"

 succeeded in 6562ms:
2026-07-10 10:06:08.665 xcodebuild[8693:56601567]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-07-10 10:06:09.086 xcodebuild[8693:56601548] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-afr5yOrc' (errno=Operation not permitted)
2026-07-10 10:06:09.951 xcodebuild[8704:56601627]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-07-10 10:06:10.156 xcodebuild[8704:56601626] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
 CHANGELOG.md                                       |   1 +
 .../1-INBOX/GH-192-HQ-MARATHON-OBSIDIAN-ROLLUP.md  |  71 --------
 .../GH-192-HQ-MARATHON-OBSIDIAN-ROLLUP.md          | 200 +++++++++++++++++++++
 ROADMAP-DASHBOARD.md                               |   6 +-
 ROADMAP.md                                         |   2 +-
 test/hq-rollup.sh                                  | 146 +++++++++++++++
 utils/hq/rollup.sh                                 |  56 ++++--
 validate.sh                                        |   2 +
 8 files changed, 399 insertions(+), 85 deletions(-)

---
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-CIobqWnH' (errno=Operation not permitted)
2026-07-10 10:06:11.623 xcodebuild[8708:56601673]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-07-10 10:06:11.846 xcodebuild[8708:56601671] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-bHoBrXz3' (errno=Operation not permitted)
2026-07-10 10:06:12.526 xcodebuild[8713:56601705]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-07-10 10:06:12.726 xcodebuild[8713:56601700] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
diff --git a/test/hq-rollup.sh b/test/hq-rollup.sh
new file mode 100755
index 0000000..d69e179
--- /dev/null
+++ b/test/hq-rollup.sh
@@ -0,0 +1,146 @@
+#!/usr/bin/env bash
+# GH-192: hermetic regression lock for utils/hq/rollup.sh's marathon-readiness bridge.
+#
+# Stubs agy (AGY_BIN) so no real network/CLI call happens, and reuses marathon-scan.sh's own
+# fixture pattern (a fixture repo + stub swarm-preflight.sh) so the marathon section is a REAL
+# classification, not a stub — proving the bridge actually invokes marathon-scan.sh and embeds its
+# verbatim output. Two cases: (1) ROADMAP has queued items -> agy-synthesized section + marathon
+# section both present; (2) ROADMAP has none -> file still written (the one deliberate behavior
+# change from before GH-192), placeholder + marathon section both present, agy never invoked.
+
+set -uo pipefail
+# strict-mode: -e exempt — assertion-style test with expected-nonzero probes handled explicitly.
+
+HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
+ROOT="$(cd "$HERE/.." && pwd)"
+ROLLUP="$ROOT/utils/hq/rollup.sh"
+
+WORK="$(mktemp -d "${TMPDIR:-/tmp}/hq-rollup.XXXXXX")"
+trap 'rm -rf "$WORK"' EXIT
+
+PASS=0
+FAIL=0
+pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
+fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
+
+echo "== test: hq-rollup =="
+echo "  workdir: $WORK"
+
+REPO="$WORK/repos/repo-a"
+mkdir -p "$REPO/.git" "$REPO/PROJECT/2-WORKING" "$REPO/utils"
+
+cat >"$REPO/utils/swarm-preflight.sh" <<'EOF'
+#!/usr/bin/env bash
+set -uo pipefail
+ISSUE=""
+while (($# > 0)); do
+  case "$1" in
+    --gh-issue) ISSUE="${2:-}"; shift 2 ;;
+    --target-root|--project-doc|--format|--dry-run) shift ;;
+    *) shift ;;
+  esac
+done
+if [[ "$ISSUE" == "101" ]]; then
+  echo '{"readiness":{"ready":true}}'; exit 0
+fi
+echo '{"readiness":{"ready":false}}'; exit 6
+EOF
+chmod +x "$REPO/utils/swarm-preflight.sh"
+
+cat >"$REPO/PROJECT/2-WORKING/MARATHON-PLAN-2026-07-09.md" <<'EOF'
+---
+title: repo-a-marathon
+status: Active
+---
+
+# repo-a-marathon
+
+## Recommended waves
+
+**Wave 1:** #101
+EOF
+
+AGY_STUB="$WORK/agy-stub"
+AGY_MARKER_FILE="$WORK/agy-invoked"
+cat >"$AGY_STUB" <<EOF
+#!/usr/bin/env bash
+touch "$AGY_MARKER_FILE"
+echo "AGY-STUB-SYNTHESIS-MARKER"
+EOF
+chmod +x "$AGY_STUB"
+
+PDDA_DIR="$WORK/pdda"
+mkdir -p "$PDDA_DIR"
+XYZ_REG="$WORK/xyz.tsv"
+cat >"$XYZ_REG" <<EOF
+$REPO/.xyz	2026-07-09T00:00:00Z	0.2.0	a1	$REPO
+EOF
+
+VAULT="$WORK/vault"
+OUT="$VAULT/HQ-Daily-Rollup.md"
+
+run_rollup() {
+  HQ_OBSIDIAN_VAULT="$VAULT" \
+  HQ_XYZ_REGISTRY="$XYZ_REG" \
+  HQ_PDDA_REGISTRY_DIR="$PDDA_DIR" \
+  HQ_SEARCH_ROOTS="$WORK/repos" \
+  HQ_MARATHON_SCAN_TODAY="2026-07-09" \
+  HQ_MARATHON_SCAN_NOW="2026-07-09T12:00:00Z" \
+  AGY_BIN="$AGY_STUB" \
+  bash "$ROLLUP"
+}
+
+echo "-- Case A: populated ROADMAP.md --"
+cat >"$REPO/ROADMAP.md" <<'EOF'
+# Roadmap
+## Ledger
+### Queue / parked intake
+- **Test item** some description
+EOF
+
+run_rollup >"$WORK/case-a.log" 2>&1
+rc=$?
+[[ $rc -eq 0 ]] && pass "case A: rollup exits 0" || fail "case A: rollup rc=$rc ($(cat "$WORK/case-a.log"))"
+[[ -f "$OUT" ]] && pass "case A: report written" || fail "case A: report missing"
+[[ -f "$AGY_MARKER_FILE" ]] && pass "case A: agy stub was invoked" || fail "case A: agy stub never ran"
+
+grep -q "AGY-STUB-SYNTHESIS-MARKER" "$OUT" \
+  && pass "case A: agy-synthesized ROADMAP section present" || fail "case A: agy section missing"
+grep -q "^## Marathon Readiness (cross-repo preflight)$" "$OUT" \
+  && pass "case A: marathon section heading present" || fail "case A: marathon section heading missing"
+grep -q "^### HQ MARATHON" "$OUT" \
+  && pass "case A: embedded report's H1 demoted to H3 (nests under the H2 section)" \
+  || fail "case A: embedded report's heading not demoted: $(grep '^#* HQ MARATHON' "$OUT")"
+grep -q "^# HQ MARATHON" "$OUT" \
+  && fail "case A: embedded report's H1 leaked through undemoted" \
+  || pass "case A: no bare H1 from the embedded report"
+grep -q '| #101 | .*| ✅ ready (exit 0) |' "$OUT" \
+  && pass "case A: real marathon-scan classification embedded verbatim" \
+  || fail "case A: marathon-scan classification missing/wrong: $(grep '#101' "$OUT")"
+grep -q "^generated_by:" "$OUT" \
+  && fail "case A: marathon-scan's own frontmatter leaked into the rollup" \
+  || pass "case A: marathon-scan's frontmatter stripped"
+
+echo "-- Case B: empty ROADMAP.md, agy must NOT be invoked --"
+rm -f "$AGY_MARKER_FILE" "$OUT"
+cat >"$REPO/ROADMAP.md" <<'EOF'
+# Roadmap
+## Ledger
+### Completed
+- Nothing relevant to the queue/parked scrape here.
+EOF
+
+run_rollup >"$WORK/case-b.log" 2>&1
+rc=$?
+[[ $rc -eq 0 ]] && pass "case B: rollup exits 0" || fail "case B: rollup rc=$rc ($(cat "$WORK/case-b.log"))"
+[[ -f "$OUT" ]] && pass "case B: report STILL written despite empty ROADMAP scrape" || fail "case B: report missing"
+[[ -f "$AGY_MARKER_FILE" ]] && fail "case B: agy stub ran even though ROADMAP scrape was empty" \
+  || pass "case B: agy stub correctly skipped"
+grep -q "_No parked or active items found in any ROADMAP.md._" "$OUT" \
+  && pass "case B: placeholder ROADMAP text present" || fail "case B: placeholder missing"
+grep -q '| #101 | .*| ✅ ready (exit 0) |' "$OUT" \
+  && pass "case B: marathon section still present on a quiet ROADMAP day" \
+  || fail "case B: marathon section missing"
+
+echo "== hq-rollup: $PASS passed, $FAIL failed =="
+[ "$FAIL" -eq 0 ]
diff --git a/utils/hq/rollup.sh b/utils/hq/rollup.sh
index 8bb0407..22968d3 100755
--- a/utils/hq/rollup.sh
+++ b/utils/hq/rollup.sh
@@ -1,108 +1,142 @@
 #!/usr/bin/env bash
-# utils/hq/rollup.sh — Roll up cross-repo ROADMAP activity into a daily Obsidian summary.
+# utils/hq/rollup.sh — Roll up cross-repo ROADMAP activity + marathon preflight readiness
+# (GH-158's marathon-scan.sh) into one daily Obsidian summary (GH-192).
 
 set -euo pipefail
 
 HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
 # shellcheck source=utils/hq/hq-lib.sh
 . "$HERE/hq-lib.sh"
 
+AGY_BIN="${AGY_BIN:-agy}"   # test seam — same convention as relay-automation/consult.sh
+
 command -v node >/dev/null 2>&1 || { echo "hq rollup: node is required" >&2; exit 2; }
-command -v agy >/dev/null 2>&1 || { echo "hq rollup: agy (Antigravity CLI) is required" >&2; exit 2; }
+command -v "$AGY_BIN" >/dev/null 2>&1 || { echo "hq rollup: agy (Antigravity CLI) is required" >&2; exit 2; }
 
 mkdir -p "$HQ_OBSIDIAN_VAULT"
 OUT_FILE="$HQ_OBSIDIAN_VAULT/HQ-Daily-Rollup.md"
 RAW_FILE="${TMPDIR:-/tmp}/hq-raw-rollup.txt"
 > "$RAW_FILE"
 
 echo "HQ Rollup: scanning repos for ROADMAP activity..."
 
 # hq_known_repos outputs one per line
 while IFS= read -r repo; do
   [ -z "$repo" ] && continue
   
   fields="$(hq_repo_resolve "$repo")"
   path="$(printf '%s\n' "$fields" | sed -n 's/^REPO_PATH=//p' | head -1)"
   
   if [ -n "$path" ] && [ -f "$path/ROADMAP.md" ]; then
     echo "  scanning $repo ($path)..."
     
     node - "$path/ROADMAP.md" "$repo" >> "$RAW_FILE" <<'NODE'
 const fs = require("fs");
 const sourcePath = process.argv[2];
 const repoName = process.argv[3];
 const raw = fs.readFileSync(sourcePath, "utf8");
 const lines = raw.split(/\r?\n/);
 
 const sections = new Map();
 let currentSection = null;
 
 for (let i = 0; i < lines.length; i++) {
   const line = lines[i];
 
   const sectionMatch = line.match(/^###\s+(.+?)\s*$/);
   if (sectionMatch) {
     const heading = sectionMatch[1].trim().toLowerCase();
     if (heading.includes("queue") || heading.includes("parked") || heading.includes("in progress") || heading.includes("next-up")) {
       currentSection = sectionMatch[1].trim();
       if (!sections.has(currentSection)) sections.set(currentSection, []);
     } else {
       currentSection = null;
     }
     continue;
   }
 
   if (!currentSection) continue;
   
   // Bullets usually start with `- **` or `<number>. **`
   if (!/^(-\s+|\d+\.\s+)\*\*/.test(line)) continue;
 
   const block = [line];
   while (i + 1 < lines.length) {
     const next = lines[i + 1];
     if (/^###\s+/.test(next) || /^##\s+/.test(next) || /^(-\s+|\d+\.\s+)\*\*/.test(next)) break;
     block.push(next);
     i += 1;
   }
   sections.get(currentSection).push(block.join(" ").replace(/\s+/g, " "));
 }
 
 let hasData = false;
 let out = `\n=== REPO: ${repoName} ===\n`;
 for (const [heading, items] of sections.entries()) {
   if (items && items.length > 0) {
     hasData = true;
     out += `\nSection: ${heading}\n`;
     items.forEach(item => out += `${item}\n`);
   }
 }
 
 if (hasData) {
   process.stdout.write(out);
 }
 NODE
 
   fi
 done < <(hq_known_repos)
 
-if [ ! -s "$RAW_FILE" ]; then
-  echo "HQ Rollup: No parked or active items found in any ROADMAP.md."
-  exit 0
-fi
+if [ -s "$RAW_FILE" ]; then
+  echo "HQ Rollup: Synthesizing with agy..."
 
-echo "HQ Rollup: Synthesizing with agy into $OUT_FILE..."
-
-PROMPT="Synthesize the following cross-repo parked and marathon items into a clean daily summary for an Obsidian dashboard.
-Format it beautifully using GitHub flavored markdown. 
+  PROMPT="Synthesize the following cross-repo parked and marathon items into a clean daily summary for an Obsidian dashboard.
+Format it beautifully using GitHub flavored markdown.
 Group the information into logical sections such as 'Active / Next Up' and 'Parked / Queued'.
 Mention which repo each item belongs to.
 Do not hallucinate any information.
 Keep it concise but detailed enough so I remember context without context switching.
 
 RAW DATA:
 $(cat "$RAW_FILE")
 "
 
-agy -p "$PROMPT" --dangerously-skip-permissions < /dev/null > "$OUT_FILE"
+  roadmap_section="$("$AGY_BIN" -p "$PROMPT" --dangerously-skip-permissions < /dev/null)"
+else
+  echo "HQ Rollup: No parked or active items found in any ROADMAP.md."
+  roadmap_section="_No parked or active items found in any ROADMAP.md._"
+fi
+
+# GH-192: fold in GH-158's cross-repo marathon-preflight aggregator. Appended verbatim, never
+# passed through agy — the ready/blocked/stale/ambiguous verdicts are the one deterministic,
+# structured signal in this pipeline, and an LLM synthesis pass risks paraphrasing one wrong.
+echo "HQ Rollup: running marathon-scan.sh for preflight readiness..."
+MARATHON_TMP="$(mktemp "${TMPDIR:-/tmp}/hq-rollup-marathon.XXXXXX")"
+marathon_rc=0
+marathon_log="$(bash "$HERE/marathon-scan.sh" --out "$MARATHON_TMP" 2>&1)" || marathon_rc=$?
+
+if [ "$marathon_rc" -eq 0 ] && [ -s "$MARATHON_TMP" ]; then
+  # Strip the report's own leading YAML frontmatter (redundant once embedded under a heading here),
+  # and demote every heading by 2 levels (# -> ###, ## -> ####) so the report's own H1 title nests
+  # properly under this section's H2 instead of sitting at the same level as its own subheadings.
+  marathon_section="$(awk '
+    NR==1 && $0=="---" { infm=1; next }
+    infm && $0=="---" { infm=0; next }
+    infm { next }
+    /^```/ { infence = !infence; print; next }
+    !infence && match($0, /^#+ /) { print "##" $0; next }
+    { print }
+  ' "$MARATHON_TMP")"
+else
+  marathon_section="_marathon scan failed (exit ${marathon_rc}): ${marathon_log}_"
+fi
+rm -f "$MARATHON_TMP"
+
+{
+  printf '%s\n' "$roadmap_section"
+  printf '\n---\n\n## Marathon Readiness (cross-repo preflight)\n\n'
+  printf '%s\n' "$marathon_section"
+} > "$OUT_FILE"
 
 echo "HQ Rollup: ✓ wrote $OUT_FILE"
diff --git a/validate.sh b/validate.sh
index 33e90e9..ef067d0 100755
--- a/validate.sh
+++ b/validate.sh
@@ -27,138 +27,140 @@ TESTS=(
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
   "relay-turn-trace.sh"          # GH-161 (rtl_trace/rtl_log_always/rtl_default_log instrumentation)
   "aider-turn.sh"
   "model-alias.sh"              # GH-120 (OpenRouter model-alias fuzzy lookup)
   "swe-diagram.sh"              # GH-146 (hub-ring layout ring-balance math + search/filter matching)
   "claude-turn.sh"             # GH-58
   "worktree-isolation.sh"
   "shim-worktree.sh"
   "marathon-yaml.sh"
   "marathon-drive.sh"
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
   "marathon.sh"
   "consult.sh"
   "deep-research.sh"             # GH-87 (provider-agnostic grounded-search adapter)
   "relay-pkg-freshness.sh"
   "skill-extract.sh"
   "path-integrity.sh"
   "relay-turn-timeout.sh"
   "relay-target-root.sh"
   "relay-target-root-paths.sh"
   "relay-target-root-relayfile.sh"
   "relay-target-root-newfile.sh"
   "archive-root.sh"              # GH-30 Phase 1 (transcript-root resolver: unset/set/missing/non-git)
   "archive-writers.sh"           # GH-30 Phase 2 (writers honor the resolver: consult e2e + structural)
   "archive-commit.sh"            # GH-30 Phase 3 (Model A: transcript → archive repo, code+.tick → target)
   "archive-telemetry.sh"         # GH-30 Phase 4 (telemetry reads the resolver: archive aggregation + unset)
   "relay-token-collision.sh"
   "relay-escalation-not-stall.sh"
   "relay-untracked-file-warn.sh"
   "relay-file-seeding-visibility.sh"  # GH-178 B2
   "relay-review-once.sh"
   "relay-artifact-file.sh"
   "relay-turn-handoff.sh"
   "relay-dep-drift.sh"
   "new-relay.sh"
   "xyz-vendor.sh"
   "xyz-sync-check.sh"            # GH-96 (xyz-sync check: tick_version/source_commit drift report)
   "relay-concurrent-commit.sh"
   "relay-case-insensitive.sh"
   "relay-xyz-skill-guard.sh"
   "find-harness.sh"
   "pdda-roadmap-coverage.sh"
   "swarm-preflight.sh"
   "ci-workflow.sh"
   "xyz-completion.sh"
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
+  "hq-marathon-scan.sh"          # GH-158 (cross-repo marathon aggregation + preflight — written, never registered until GH-192)
+  "hq-rollup.sh"                 # GH-192 (marathon-scan.sh bridged verbatim into the Obsidian daily rollup)
   "transcript-audit.sh"
   "security-scan.sh"
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
   "fixtures/canary-peer-orphan/verify-fixture.sh"
   "fixtures/canary-reviewer-overstep/verify-fixture.sh"
   "phase3-signoff-guard.sh"
   # Live-agent test — auto-skips when agy/codex not on PATH or RELAY_SELF_SUFFICIENCY_SKIP=1.
   # Set RELAY_SELF_SUFFICIENCY_SKIP=1 in CI / keyless environments to avoid the real API call.
   "relay-self-sufficiency.sh"
 )
 
 PASSED=()
 FAILED=()
 
 for t in "${TESTS[@]}"; do
   echo
   echo "==============================="
   echo "Running $t"
   echo "==============================="
   if bash "$HERE/test/$t"; then
     PASSED+=("$t")
   else
     FAILED+=("$t")
   fi
 done
 
 echo
 echo "==============================="
 echo "Running python3 -m pytest test/test_python_layer.py"
 echo "==============================="
 if python3 -m pytest "$HERE/test/test_python_layer.py"; then
   PASSED+=("python:test_python_layer.py")
 else
   FAILED+=("python:test_python_layer.py")
 fi
 
 echo
 echo "==============================="
 echo "Summary"
 echo "==============================="
 TOTAL=$(( ${#TESTS[@]} + 1 ))
 echo "passed: ${#PASSED[@]} / ${TOTAL}"
 for t in "${PASSED[@]}"; do echo "  + $t"; done
 if [ "${#FAILED[@]}" -gt 0 ]; then
   echo "failed:"
   for t in "${FAILED[@]}"; do echo "  - $t"; done
   exit 1
 fi
 exit 0

exec
/bin/zsh -lc 'bash test/hq-marathon-scan.sh' in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241
 exited 1 in 133ms:
grep: /HQ-MARATHON-2026-07-06.md: No such file or directory
  FAIL: blocked-other missing
grep: /HQ-MARATHON-2026-07-06.md: No such file or directory
  FAIL: stale ghost lane missing
grep: /HQ-MARATHON-2026-07-06.md: No such file or directory
  FAIL: ambiguous missing
grep: /HQ-MARATHON-2026-07-06.md: No such file or directory
  FAIL: held marathon missing
grep: /HQ-MARATHON-2026-07-06.md: No such file or directory
grep: /HQ-MARATHON-2026-07-06.md: No such file or directory
  FAIL: net counts wrong: 
find: /repos: No such file or directory
  PASS: scanner stayed read-only over target repos
== hq-marathon-scan: 2 passed, 9 failed ==

codex
**Answer**

I would not merge this PR as-is. The new merge logic is mostly sound: the `set -euo pipefail` + `marathon_rc` capture works, and the frontmatter/heading rewrite matches the actual `marathon-scan.sh` output shape. The blocker is that `rollup.sh` still hard-fails on missing `agy` before it knows whether any ROADMAP synthesis is needed, so the new “always write the file so marathon readiness still reaches Obsidian on a quiet day” behavior is not actually true in that environment ([utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:14), [utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:91)).

I couldn’t run the shell tests here because this sandbox blocks `mktemp`/temp writes, so the test comments below are from direct source review rather than execution.

**Findings**

- [Blocker] `agy` is required unconditionally at startup, but only used when the ROADMAP scrape is non-empty. That means a quiet-day run with valid marathon output still exits at startup if `agy` is absent, which undermines the PR’s explicit behavior change ([utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:13), [utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:14), [utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:107)).

- [Should] `test/hq-rollup.sh` does not cover the new non-zero `marathon-scan.sh` path at all. The implementation has an explicit visible-failure branch, but the test only exercises successful marathon scans in the “ROADMAP populated” and “ROADMAP empty” cases ([utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:117), [utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:132), [test/hq-rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/test/hq-rollup.sh:93), [test/hq-rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/test/hq-rollup.sh:124)).

- [Should] The heading/frontmatter rewrite is only partially regression-locked. The test proves H1 demotion and frontmatter removal against today’s `marathon-scan.sh` output, but it does not prove the “skip fenced code blocks” behavior or demotion of deeper headings; that matters because the awk is generic while the current producer doesn’t emit fenced headings to stress it ([utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:123), [utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:128), [test/hq-rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/test/hq-rollup.sh:109)).

- [Pass] The `marathon_log="$(...)" || marathon_rc=$?` pattern is correct under `set -euo pipefail`; because it is in an OR-list, a non-zero `marathon-scan.sh` exit is captured instead of killing `rollup.sh` outright ([utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:5), [utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:116)).

- [Pass] The frontmatter stripping and heading demotion match the actual report producer. `marathon-scan.sh` writes YAML frontmatter first and an H1 title after it, so the current awk transforms exactly the format it is consuming ([utils/hq/marathon-scan.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/marathon-scan.sh:443), [utils/hq/marathon-scan.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/marathon-scan.sh:461), [utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:120)).

- [Pass] Verbatim appending is the right design. The marathon section is already deterministic, structured status data with explicit verdict tables and counts; running that through `agy` would create real risk of paraphrasing or collapsing the signal ([utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:111), [utils/hq/marathon-scan.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/marathon-scan.sh:467), [utils/hq/marathon-scan.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/marathon-scan.sh:506)).

- [Pass] Registering both HQ tests in `validate.sh` is correct and overdue ([validate.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/validate.sh:107), [validate.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/validate.sh:108)).

**Recommendation**

Block on making the `agy` dependency lazy; after that, I’d merge and separately add one focused test for the `marathon-scan.sh` non-zero/failure-message path.
tokens used
97,345
**Answer**

I would not merge this PR as-is. The new merge logic is mostly sound: the `set -euo pipefail` + `marathon_rc` capture works, and the frontmatter/heading rewrite matches the actual `marathon-scan.sh` output shape. The blocker is that `rollup.sh` still hard-fails on missing `agy` before it knows whether any ROADMAP synthesis is needed, so the new “always write the file so marathon readiness still reaches Obsidian on a quiet day” behavior is not actually true in that environment ([utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:14), [utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:91)).

I couldn’t run the shell tests here because this sandbox blocks `mktemp`/temp writes, so the test comments below are from direct source review rather than execution.

**Findings**

- [Blocker] `agy` is required unconditionally at startup, but only used when the ROADMAP scrape is non-empty. That means a quiet-day run with valid marathon output still exits at startup if `agy` is absent, which undermines the PR’s explicit behavior change ([utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:13), [utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:14), [utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:107)).

- [Should] `test/hq-rollup.sh` does not cover the new non-zero `marathon-scan.sh` path at all. The implementation has an explicit visible-failure branch, but the test only exercises successful marathon scans in the “ROADMAP populated” and “ROADMAP empty” cases ([utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:117), [utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:132), [test/hq-rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/test/hq-rollup.sh:93), [test/hq-rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/test/hq-rollup.sh:124)).

- [Should] The heading/frontmatter rewrite is only partially regression-locked. The test proves H1 demotion and frontmatter removal against today’s `marathon-scan.sh` output, but it does not prove the “skip fenced code blocks” behavior or demotion of deeper headings; that matters because the awk is generic while the current producer doesn’t emit fenced headings to stress it ([utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:123), [utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:128), [test/hq-rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/test/hq-rollup.sh:109)).

- [Pass] The `marathon_log="$(...)" || marathon_rc=$?` pattern is correct under `set -euo pipefail`; because it is in an OR-list, a non-zero `marathon-scan.sh` exit is captured instead of killing `rollup.sh` outright ([utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:5), [utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:116)).

- [Pass] The frontmatter stripping and heading demotion match the actual report producer. `marathon-scan.sh` writes YAML frontmatter first and an H1 title after it, so the current awk transforms exactly the format it is consuming ([utils/hq/marathon-scan.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/marathon-scan.sh:443), [utils/hq/marathon-scan.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/marathon-scan.sh:461), [utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:120)).

- [Pass] Verbatim appending is the right design. The marathon section is already deterministic, structured status data with explicit verdict tables and counts; running that through `agy` would create real risk of paraphrasing or collapsing the signal ([utils/hq/rollup.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/rollup.sh:111), [utils/hq/marathon-scan.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/marathon-scan.sh:467), [utils/hq/marathon-scan.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/utils/hq/marathon-scan.sh:506)).

- [Pass] Registering both HQ tests in `validate.sh` is correct and overdue ([validate.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/validate.sh:107), [validate.sh](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-8135-21241/validate.sh:108)).

**Recommendation**

Block on making the `agy` dependency lazy; after that, I’d merge and separately add one focused test for the `marathon-scan.sh` non-zero/failure-message path.
