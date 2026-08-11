**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.6-terra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
2026-08-10T18:02:04.258065Z ERROR codex_models_manager::cache: failed to load models cache: missing field `base_instructions` at line 95 column 5
OpenAI Codex v0.144.6
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua
model: gpt-5.6-terra
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019fecd6-bf95-78f3-be48-f7e09b0be010
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
Question: in `test/gh448-driver-lock-resolver.sh` (PR #449, branch `claude/issue-448-fix-76yxba`),
3 of 17 assertions fail on macOS but all 17 pass on Linux CI. I want a second opinion on **whether
the defect is in the test or in the code**, and on the safety implications of each fix.

## The facts, verified directly

`relay-automation/driver-lock-lib.sh::driver_lock_path_for_repo` (and its Python twin
`utils/py/rtl.py::driver_lock_path`) resolve a linked worktree's lock via:

    git -C "$repo" rev-parse --path-format=absolute --git-common-dir

On macOS this returns a **physical** path (`/private/var/folders/...`), because `$TMPDIR` lives under
`/var`, which is a symlink to `/private/var`. On Linux CI there is no such symlink, so the question
never arises.

The test builds its expected value by **string-concatenating `$TMPDIR`**, i.e. the *logical* path
(`/var/folders/...`) — you can see the concatenation is naive because the failure message contains a
doubled slash (`.../T//gh448-driver-lock.XXXX/...`), since `$TMPDIR` already ends in `/`.

Observed failures on macOS:
1. `worktree case resolved wrong: /private/var/... (expected /var/...)`
2. `marathon-ls.sh: expected LIVE, got '<no row>'`
3. `find-harness.sh --check: warning did not name /var/...`

Linux CI on the same commit: **17 pass, 0 fail** (confirmed in the tier1 log).

## What this code is for

The lock path answers "is a marathon driver currently running in this repo". #449's whole premise is
that three read-only consumers had drifted to a 2-branch guess and reported a genuinely LIVE marathon
as IDLE. So a **false 'not running'** is the dangerous direction — it invites a second driver.

Note the driver itself (`utils/py/marathon_drive.py`) now calls the same shared resolver, so driver
and consumers agree byte-for-byte whatever it returns.

## The two candidate fixes

**A. Fix the test.** Normalize both sides to physical paths (e.g. `cd "$dir" && pwd -P`, or compare
`realpath` of both) before asserting. Leaves the resolver returning git's own physical answer.

**B. Fix the resolver.** Make it return a path derived from the caller-supplied `$repo` string
(logical), so the output matches whatever the caller passed in.

## What I actually want from you

1. Which is correct, A or B — and specifically, is there any real scenario where returning the
   PHYSICAL path causes a consumer to miss a held lock (the dangerous direction), given that the
   driver writes it using the same resolver?
2. Is there a third option I am missing (e.g. compare by inode/device, or assert on
   existence-of-lock rather than on path equality) that is more robust than either?
3. Is fixing another PR's test as part of merging it the right call here, or should the macOS
   fragility be filed as a follow-up issue and the PR merged as-is given Linux CI is green?

Be concrete and cite the files. Do not just approve my reasoning — if A is wrong, say so.

hook: SessionStart
hook: SessionStart Completed
codex
I’ll inspect the referenced resolver, its callers, and the test to distinguish a genuine lock-identity flaw from a platform-specific assertion mismatch.
exec
/bin/zsh -lc "pwd && rg --files -g 'WORKTREE-SAFETY.md' -g 'ROUTER.md' -g 'GUIDING-PRINCIPLES.md' -g 'driver-lock-lib.sh' -g 'rtl.py' -g 'gh448-driver-lock-resolver.sh' -g 'marathon_drive.py' -g 'marathon-ls.sh' -g 'find-harness.sh'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua
 succeeded in 0ms:
/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua
WORKTREE-SAFETY.md
test/find-harness.sh
GUIDING-PRINCIPLES.md
test/gh448-driver-lock-resolver.sh
utils/py/rtl.py
utils/py/marathon_drive.py
skills/relay-xyz/find-harness.sh
ROUTER.md
relay-automation/marathon-ls.sh
relay-automation/driver-lock-lib.sh

exec
/bin/zsh -lc "sed -n '1,240p' WORKTREE-SAFETY.md && sed -n '1,260p' ROUTER.md && sed -n '1,220p' GUIDING-PRINCIPLES.md && sed -n '1,260p' relay-automation/driver-lock-lib.sh && sed -n '1,360p' utils/py/rtl.py" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua
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
#!/usr/bin/env bash
# driver-lock-lib.sh — GH-448: the ONE shared resolver for the relay-driver lock path.
#
# Mirrors the DRIVER's own write-side resolution (marathon_drive.py / marathon-drive.sh,
# relay_drive.py / relay-drive.sh) byte-for-byte (utils/py/rtl.py's driver_lock_path is the Python
# twin — the two MUST agree, asserted by test/gh448-driver-lock-resolver.sh). SOURCED by every
# read-only consumer of the lock (marathon-ls.sh, utils/hq/marathon-live.sh,
# skills/relay-xyz/find-harness.sh) — a consumer that constructs this path inline instead of calling
# this function is the bug this file exists to kill (5 of 7 construction sites had drifted to a
# 2-branch guess that misses the linked-worktree case, silently reporting a LIVE marathon as IDLE).
#
#   .git is a directory  -> <repo>/.git/relay-driver.lock              (normal clone)
#   .git is a file       -> <git-common-dir>/relay-driver.lock         (linked worktree)
#   no .git (vendored)   -> <repo>/.relay-driver.lock                  (vendored .xyz/ copy)
#
# API:
#   driver_lock_path_for_repo <repo-root>   — prints the resolved lock path (no trailing newline)
set -u

driver_lock_path_for_repo() {
  local repo="$1"
  if [ -d "$repo/.git" ]; then
    printf '%s/.git/relay-driver.lock' "$repo"
    return 0
  fi
  if [ -f "$repo/.git" ]; then
    local common
    common="$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
    if [ -n "$common" ]; then
      printf '%s/relay-driver.lock' "$common"
      return 0
    fi
  fi
  printf '%s/.relay-driver.lock' "$repo"
}
import os
import shlex
import subprocess
import tempfile
import sys

# GH-375 — agy's auth pre-flight cannot decide on exit status alone. `agy whoami` EXITS 0 while
# failing to run at all when there is no TTY ("CLI error: bubbletea: error opening TTY: ... open
# /dev/tty: device not configured"), and every marathon or driven relay turn is headless, so that is
# the NORMAL path under automation rather than an edge case. Both callers (agy-turn.py, consult.py)
# had the same shape and the same hole, so the verdict lives here once rather than in two copies
# that can drift.
#
# Matched as line PREFIXES, not as a bare "error" substring anywhere in the output. `whoami` prints
# ACCOUNT IDENTITY on success — a substring test would fail any lane whose handle, org, or banner
# happens to contain "error", and a false failure stops the run outright, which is a worse outcome
# than the bug being fixed. The TTY signature is matched separately: it is the exact shape the issue
# reports and it does not necessarily carry an error prefix.
# GH-375 follow-up. AGY_AUTH_TIMEOUT_S defaulted to 5 while `agy whoami` cost 1.3-2.3s idle on the
# reference machine — under 2x headroom, and concurrent load closed it twice. The second time was AFTER
# the timeout branch was taught to reclassify a TTY-diagnosed timeout as unverifiable: the probe was
# killed before it could FLUSH its diagnostic, so the capture was empty, the reclassification had
# nothing to match on, and the lane was blocked anyway. That flush race was predicted by one reviewer
# and dismissed by another (and by me) as bounded; it then fired in the next consult and cost the agy
# seat. Observed, so no longer a judgement call.
#
# 20s is chosen against the measurement, not by feel: ~9x the worst idle probe, which leaves room for
# the load that closed a 2x margin. The cost is bounded and lands only on a genuine interactive-login
# hang, which now takes 20s to reject instead of 5 — a rare path, and rejecting it late is cheaper than
# blocking a working lane. Same reasoning as GH-457's tiers: size a cap against what the thing actually
# costs, not against a number that looks tidy.
AGY_AUTH_TIMEOUT_DEFAULT_S = 20
WORST_OBSERVED_WHOAMI_S = 2.3   # 1.3 / 1.9 / 2.3 measured idle, 2026-08-09

AGY_AUTH_ERROR_PREFIXES = ("cli error:", "error:", "panic:", "fatal:")
AGY_AUTH_TTY_MARKERS = ("could not open tty", "error opening tty")


def agy_auth_output_verdict(out_file):
    """Classify agy's own probe output. Returns (severity, message).

    severity is one of:
      ""              — nothing suspicious; treat the probe as passed.
      "unverifiable"  — the probe COULD NOT RUN, so it established nothing either way. Report it
                        loudly; do NOT fail the lane on it.
      "failed"        — the probe ran and agy reported an error. Fail the lane.

    THE THIRD STATE IS THE WHOLE POINT, and it was learned the expensive way. GH-375's suggested fix
    was to treat the TTY error as a failed probe and stop the turn. That was implemented literally and
    it broke the agy lane outright: test/relay-self-sufficiency.sh went 4/0 to 0/4 with `agy shim
    exited 5`, on a machine where agy was signed in and working.

    The measurement that settles it, taken on this repo:

      * `agy whoami` cannot run headless at all. It exits 0 while printing
        `CLI error: bubbletea: error opening TTY: ... /dev/tty: device not configured`.
      * `agy -p` — the print mode the ACTUAL turn uses — runs headless perfectly well. The live turn
        in relay-self-sufficiency.sh claims its token, writes the relay file and commits.

    So a TTY error from `whoami` says nothing about whether auth works; it says this probe is the
    wrong instrument in this environment. Treating it as failure converts an unmeasurable check into
    a hard block on a lane that demonstrably works — strictly worse than the bug GH-375 reported,
    which merely let a possibly-unauthed lane proceed. One of two working builders, stopped by its
    own guard.

    What GH-375 established stands and is preserved: exit status alone cannot decide this, and the
    captured output must not be deleted. Those were the real defects. The inference "the probe could
    not run, therefore auth is bad" is the part that does not follow.
    """
    try:
        with open(out_file, "r", encoding="utf-8", errors="replace") as f:
            output = f.read()
    except OSError:
        return ("unverifiable", "the probe produced no readable output")
    # EMPTY OUTPUT IS NOT TREATED AS FAILURE, deliberately. "A probe that establishes nothing must
    # not report success" is a tempting rule and it was written here first — then it failed a turn
    # within minutes: test/gh410-containment-advisory.sh's agy stub prints nothing for `whoami`, so
    # the pre-flight rejected it, the turn exited 5 before running, and a containment assertion that
    # had nothing to do with auth went red. That is the false-failure direction this function's whole
    # matching strategy is built to avoid, and it arrived on first contact.
    #
    # The asymmetry is the point: agy exiting 0 with a VISIBLE error is observed and documented
    # (GH-375). Agy exiting 0 SILENTLY on success is not something this repo can rule out, and
    # guessing wrong there breaks every turn in the fleet rather than one. Match the evidence that
    # exists; do not infer failure from the absence of evidence. stderr is folded into this capture,
    # so a real error has somewhere to appear.
    for raw in output.splitlines():
        line = raw.strip()
        low = line.lower()
        # TTY FIRST, and it must stay first: agy's TTY banner is itself prefixed `CLI error:`, so the
        # error-prefix branch below would otherwise claim it and fail a lane that is perfectly fine.
        if any(m in low for m in AGY_AUTH_TTY_MARKERS):
            return ("unverifiable", f"agy could not run headless, so auth was not verified: {line}")
        if any(low.startswith(p) for p in AGY_AUTH_ERROR_PREFIXES):
            return ("failed", f"agy reported an error: {line}")
    return ("", "")


def agy_auth_timeout_verdict(out_file):
    """Classify a probe that TIMED OUT. Returns (severity, message) — never "".

    A separate function from agy_auth_output_verdict on purpose. That one reads an output stream from
    a process that EXITED, where "nothing suspicious" legitimately means pass. A timeout has no exit
    status to interpret, and silence there is not reassurance — so this function never returns the
    pass verdict, and reusing the other one here would have converted a hung probe into a green one.

    GH-375 follow-up. The three-state fix covered `whoami` EXITING with a TTY error. It did not cover
    the probe blowing its timeout, which still went straight to fatal — and that is the branch that
    actually fired: a /consult on 2026-08-09 lost its agy seat to

        consult: agy auth pre-flight timed out after 5s; likely expired auth opening an interactive
                 login. Run `agy login` in a normal terminal, then retry.

    on a machine where, measured in the same minute, `agy whoami` printed the TTY error and `agy -p`
    (what the turn actually uses) answered correctly. A false block, from the guard, on a working lane
    — the same failure direction GH-375's own fix was written to avoid, one branch over.

    The rule: reclassify ONLY on positive evidence of the TTY cause. If the captured output already
    says agy could not open a TTY, the timeout carries no more information about auth than the fast
    failure did — on a platform where `whoami` can never succeed headlessly, a timeout is just a
    slower spelling of the same thing. Anything else — an interactive login prompt, an unfamiliar
    error, or NO output at all — stays fatal, which keeps the branch's original purpose intact for a
    genuine hang on a login prompt.

    Deliberately narrower than "a timeout is unverifiable". That broader rule would also swallow the
    real hang this branch exists to catch, and silence is exactly the shape a login prompt waiting on
    stdin produces.
    """
    try:
        with open(out_file, "r", encoding="utf-8", errors="replace") as f:
            output = f.read()
    except OSError:
        output = ""
    for raw in output.splitlines():
        line = raw.strip()
        if any(m in line.lower() for m in AGY_AUTH_TTY_MARKERS):
            return ("unverifiable",
                    "agy could not open a TTY and then exceeded the probe timeout, so auth was not "
                    f"verified (the timeout is the same TTY failure, slower): {line}")
    return ("failed", "the probe timed out with no TTY diagnostic, which is the shape of a genuine "
                      "hang on an interactive login prompt")


def split_allow_paths(allow_paths):
    paths = []
    for path in (allow_paths or "").split(","):
        path = path.strip()
        if path:
            paths.append(path)
    return paths

def claim_paths_for_turn(root, relay_file, allow_paths):
    # Resolve both through realpath before computing the relative path. `root` and `relay_file` can
    # come from different resolution paths — e.g. root via resolve_turn_root's `git rev-parse
    # --show-toplevel` fallback, which returns the PHYSICAL path, vs. a caller-supplied relay_file
    # still in macOS's unresolved /var-or-/tmp-symlink form — and a symlink-form mismatch here makes
    # relpath climb all the way out to an unrelated "../../.."-prefixed path instead of a clean
    # repo-relative one (the same GH-51 class of bug relay-turn-lib.sh's rtl_init already guards
    # against on the bridged/bash side; this native Python computation had no equivalent). (GH-296)
    paths = [os.path.relpath(os.path.realpath(relay_file), os.path.realpath(root))]
    paths.extend(split_allow_paths(allow_paths))
    return paths

def resolve_tick_repo_root(root):
    return os.environ.get("TICK_REPO_ROOT", root)

def resolve_turn_root(explicit_root, xyz_root):
    # Mirror the Bash shims' ROOT default (codex-turn.sh): an explicit override wins, else the
    # CWD's git toplevel — so a shim invoked from inside a same-repo vendored .xyz/ (relay-xyz's
    # documented `cd $HARNESS`) roots at the TRUE target repo, not xyz_root (the harness's own
    # directory on disk, which can differ from the git toplevel in that layout even though both
    # paths belong to the same git repo) — else xyz_root as a last resort off a git repo. (GH-296)
    #
    # GH-417: --show-toplevel returns the PHYSICAL path, so ROOT can differ in symlink form from a
    # relay-file path the caller built from its own $PWD. That is survivable, not accidental:
    # relay-turn-lib.sh's rtl_init canonicalizes both sides before stripping (GH-261, 312a2c3), and
    # claim_paths_for_turn above does the same natively. Read the "caught live" warning at
    # relay-turn-lib.sh's GH-160 collapse as scoped to that collapse — it is not an argument against
    # this default. Pinned by test/gh417-turn-root-symlink-prefix.sh, whose control shows the exit-6
    # failure returning the moment that canonicalization is removed.
    if explicit_root:
        return explicit_root
    try:
        out = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                              capture_output=True, text=True, check=True)
        top = out.stdout.strip()
        if top:
            return top
    except Exception:
        pass
    return xyz_root

def resolve_tick_bin(tick_repo_root, xyz_root):
    candidates = []
    tick_bin_env = os.environ.get("TICK_BIN")
    if tick_bin_env:
        candidates.append(tick_bin_env)
    candidates.append(os.path.join(tick_repo_root, "bin", "tick"))
    candidates.append(os.path.join(xyz_root, "bin", "tick"))

    for candidate in candidates:
        if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
            return candidate
    return None

def make_tick_env(tick_repo_root):
    env = dict(os.environ)
    env["TICK_REPO_ROOT"] = tick_repo_root
    return env

def claim_task_or_exit(root, xyz_root, relay_file, allow_paths, task, agent, tool_name):
    tick_repo_root = resolve_tick_repo_root(root)
    tick_bin = resolve_tick_bin(tick_repo_root, xyz_root)
    if not tick_bin:
        return tick_repo_root, None

    tick_env = make_tick_env(tick_repo_root)
    claim_paths = ",".join(claim_paths_for_turn(root, relay_file, allow_paths))
    subprocess.run(
        [tick_bin, "claim", task, "--agent", agent, "--paths", claim_paths],
        env=tick_env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    info_res = subprocess.run([tick_bin, "info", task], env=tick_env, capture_output=True, text=True)
    claimer = "none"
    for line in info_res.stdout.splitlines():
        if line.startswith("claimer:"):
            claimer = line.split(":", 1)[1].strip()
            break

    if claimer != agent:
        print(
            f"{tool_name}: could not establish token ownership of {task} (claimer={claimer}, expected {agent}) — refusing to run so the turn cannot commit with the token open under the old owner; inspect `tick info {task}`",
            file=sys.stderr,
        )
        sys.exit(5)

    subprocess.run(
        [tick_bin, "ping", task, "--agent", agent],
        env=tick_env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return tick_repo_root, tick_bin

# ASCII-only slug alphabet — mirrors the Bash `tr -c 'A-Za-z0-9._-' '_'` sanitizer exactly. Python's
# str.isalnum() would also pass Unicode letters/digits (e.g. `é`), diverging from the Bash contract.
_SLUG_SAFE = frozenset("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-")

def _ascii_slug(s):
    return "".join(c if c in _SLUG_SAFE else "_" for c in s)

def _rtl_repo_slug(target_root):
    # Mirror Bash rtl_repo_slug: origin remote basename, else target dir basename, sanitized to a SAFE
    # single path segment ([A-Za-z0-9._-]; never empty, never "."/"..", never leading "-").
    url = ""
    try:
        url = subprocess.check_output(["git", "-C", target_root, "remote", "get-url", "origin"],
                                      stderr=subprocess.DEVNULL).decode("utf-8").strip()
    except Exception:
        url = ""
    while url.endswith("/"):
        url = url[:-1]
    if url.endswith(".git"):
        url = url[:-4]
    while url.endswith("/"):
        url = url[:-1]
    slug = ""
    if url:
        slug = url.rsplit("/", 1)[-1].rsplit(":", 1)[-1]   # strip path AND scp-style host: prefix
    if not slug:
        slug = os.path.basename(target_root) or ""
    slug = _ascii_slug(slug or "repo")
    while slug.startswith("-"):
        slug = slug[1:]
    if slug in ("", ".", ".."):
        slug = "repo"
    return slug

def _rtl_transcript_root(target_root, quiet=False):
    # Mirror Bash rtl_transcript_root: <root>/relay-system on the common path; when XYZ_ARCHIVE_ROOT is
    # set, validate it (ABSOLUTE, exists, is a git repo — Model A) and namespace as
    # <archive>/relay-system/<repo-slug>. Returns None on an invalid archive so the caller (rtl_default_log)
    # falls back to $TMPDIR, exactly as the Bash `... || fallback` does. quiet=True mirrors Bash callers
    # that redirect the resolver's stderr (rtl_default_log) — direct callers keep the diagnostics.
    def _warn(msg):
        if not quiet:
            print(msg, file=sys.stderr)
    target_root = (target_root or "").rstrip("/")
    ar = os.environ.get("XYZ_ARCHIVE_ROOT", "")
    if not ar:
        return f"{target_root}/relay-system"
    if not os.path.isabs(ar):
        _warn(f"rtl_transcript_root: XYZ_ARCHIVE_ROOT must be an ABSOLUTE path, got: {ar}")
        return None
    if not os.path.isdir(ar):
        _warn(f"rtl_transcript_root: XYZ_ARCHIVE_ROOT does not exist (or is not a directory): {ar}")
        return None
    if subprocess.run(["git", "-C", ar, "rev-parse", "--git-dir"],
                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
        _warn(f"rtl_transcript_root: XYZ_ARCHIVE_ROOT is not a git repo (Model A requires a committed archive): {ar}")
        return None
    return f"{ar}/relay-system/{_rtl_repo_slug(target_root)}"

def rtl_default_log(root, tool, task):
    # GH-161: persistent turn-transcript path under <transcript-root>/logs/<date>/, falling back to
    # $TMPDIR when the transcript root can't be resolved/created. Mirrors Bash rtl_default_log.
    fallback = os.path.join(tempfile.gettempdir(), f"{tool}-{os.getpid()}.log")
    base = _rtl_transcript_root(root, quiet=True)   # Bash redirects the resolver's stderr here
    if not base:
        return fallback
    tslug = _ascii_slug(task or "")
    try:
        day = subprocess.check_output(["date", "+%Y-%m-%d"], stderr=subprocess.DEVNULL).decode("utf-8").strip()
    except Exception:
        day = "unknown-date"
    path = os.path.join(base, "logs", day, f"{tool}-{tslug}-{os.getpid()}.log")
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        return path
    except Exception:
        return fallback

class RelayTurnLib:
    def __init__(self, root, xyz_root, relay_file, allow_paths):
        self.root = root
        self.xyz_root = xyz_root
        self.relay_file = relay_file
        self.allow_paths = allow_paths
        fd, self.state_file = tempfile.mkstemp()
        os.close(fd)
        
    def __del__(self):
        # Guard against a partially-initialized instance (mkstemp raised before
        # state_file was bound) — __del__ can still fire and must not AttributeError.
        if not hasattr(self, "state_file"):
            return
        try:
            os.remove(self.state_file)
        except OSError:
            pass

    def _run_rtl(self, cmd_str, capture=True):
        # Build the bridge script; every interpolated path is shell-quoted and
        # TICK_REPO_ROOT is passed via the child env (not embedded in the source)
        # so a path/value with quotes or `$()` can't inject shell syntax.
        lib = shlex.quote(os.path.join(self.xyz_root, "relay-automation", "relay-turn-lib.sh"))
        state = shlex.quote(self.state_file)
        state_tmp = shlex.quote(self.state_file + ".tmp")
        script = f"""
source {lib} >/dev/null 2>&1
if [ -s {state} ]; then
  source {state}
else
  rtl_init {shlex.quote(self.root)} {shlex.quote(self.relay_file)} {shlex.quote(self.allow_paths)} >/dev/null 2>&1
fi

{cmd_str}

exec
/bin/zsh -lc "rg -n -C 12 'driver_lock_path|driver_lock_path_for_repo|relay-driver\\.lock' utils/py/rtl.py utils/py/marathon_drive.py relay-automation/marathon-ls.sh skills/relay-xyz/find-harness.sh test/find-harness.sh test/gh448-driver-lock-resolver.sh utils/hq/marathon-live.sh relay-automation/driver-lock-lib.sh && nl -ba test/gh448-driver-lock-resolver.sh && nl -ba relay-automation/driver-lock-lib.sh && nl -ba relay-automation/marathon-ls.sh && nl -ba skills/relay-xyz/find-harness.sh" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua
 succeeded in 0ms:
skills/relay-xyz/find-harness.sh-247-        if [ -n "$MAIN_CHECKOUT_VENDORED" ]; then
skills/relay-xyz/find-harness.sh-248-          echo "  !   concurrency: vendored .xyz found in the main checkout at $MAIN_CHECKOUT_VENDORED, but it is not"
skills/relay-xyz/find-harness.sh-249-          echo "      a usable harness here; relays fall back to the CENTRALIZED harness and"
skills/relay-xyz/find-harness.sh-250-        else
skills/relay-xyz/find-harness.sh-251-          echo "  !   concurrency: no local .xyz/ in this repo — relays here use the CENTRALIZED harness and"
skills/relay-xyz/find-harness.sh-252-        fi
skills/relay-xyz/find-harness.sh-253-        echo "      share ONE global driver lock (can't run concurrently with another repo's relay). For"
skills/relay-xyz/find-harness.sh-254-        echo "      per-repo isolation / concurrent relays, vendor this repo:"
skills/relay-xyz/find-harness.sh-255-        echo "        relay-automation/xyz-vendor.sh vendor $_caller"
skills/relay-xyz/find-harness.sh-256-        # GH-448: resolve via the shared resolver, not a 2-candidate guess — when $HARNESS itself is a
skills/relay-xyz/find-harness.sh-257-        # linked worktree (.git is a FILE), the driver's real lock lives at the git common dir, which
skills/relay-xyz/find-harness.sh-258-        # neither hardcoded candidate above matched, so this warning silently never fired.
skills/relay-xyz/find-harness.sh:259:        _lk="$(driver_lock_path_for_repo "$HARNESS")"
skills/relay-xyz/find-harness.sh-260-        [ -d "$_lk" ] && echo "  !   a driver lock is currently HELD ($_lk) — a relay started here will BLOCK until it frees"
skills/relay-xyz/find-harness.sh-261-      fi
skills/relay-xyz/find-harness.sh-262-    fi
skills/relay-xyz/find-harness.sh-263-    _collision="$(_find_case_collision_pair "${_caller:-}" || true)"
skills/relay-xyz/find-harness.sh-264-    if [ -n "$_collision" ]; then
skills/relay-xyz/find-harness.sh-265-      _path_a="${_collision%%$'\t'*}"
skills/relay-xyz/find-harness.sh-266-      _path_b="${_collision#*$'\t'}"
skills/relay-xyz/find-harness.sh-267-      echo "  !   case-collision: tracked paths '$_path_a' and '$_path_b' differ only by case in this repo"
skills/relay-xyz/find-harness.sh-268-      echo "      and only one casing can exist as a real directory tree on this filesystem. A headless"
skills/relay-xyz/find-harness.sh-269-      echo "      relay turn can misread git status here and revert a legitimate edit (exit 6). Remedy:"
skills/relay-xyz/find-harness.sh-270-      echo "      git mv one variant to match the other's casing, commit, then re-run --check."
skills/relay-xyz/find-harness.sh-271-    fi
--
relay-automation/driver-lock-lib.sh-1-#!/usr/bin/env bash
relay-automation/driver-lock-lib.sh-2-# driver-lock-lib.sh — GH-448: the ONE shared resolver for the relay-driver lock path.
relay-automation/driver-lock-lib.sh-3-#
relay-automation/driver-lock-lib.sh-4-# Mirrors the DRIVER's own write-side resolution (marathon_drive.py / marathon-drive.sh,
relay-automation/driver-lock-lib.sh:5:# relay_drive.py / relay-drive.sh) byte-for-byte (utils/py/rtl.py's driver_lock_path is the Python
relay-automation/driver-lock-lib.sh-6-# twin — the two MUST agree, asserted by test/gh448-driver-lock-resolver.sh). SOURCED by every
relay-automation/driver-lock-lib.sh-7-# read-only consumer of the lock (marathon-ls.sh, utils/hq/marathon-live.sh,
relay-automation/driver-lock-lib.sh-8-# skills/relay-xyz/find-harness.sh) — a consumer that constructs this path inline instead of calling
relay-automation/driver-lock-lib.sh-9-# this function is the bug this file exists to kill (5 of 7 construction sites had drifted to a
relay-automation/driver-lock-lib.sh-10-# 2-branch guess that misses the linked-worktree case, silently reporting a LIVE marathon as IDLE).
relay-automation/driver-lock-lib.sh-11-#
relay-automation/driver-lock-lib.sh:12:#   .git is a directory  -> <repo>/.git/relay-driver.lock              (normal clone)
relay-automation/driver-lock-lib.sh:13:#   .git is a file       -> <git-common-dir>/relay-driver.lock         (linked worktree)
relay-automation/driver-lock-lib.sh:14:#   no .git (vendored)   -> <repo>/.relay-driver.lock                  (vendored .xyz/ copy)
relay-automation/driver-lock-lib.sh-15-#
relay-automation/driver-lock-lib.sh-16-# API:
relay-automation/driver-lock-lib.sh:17:#   driver_lock_path_for_repo <repo-root>   — prints the resolved lock path (no trailing newline)
relay-automation/driver-lock-lib.sh-18-set -u
relay-automation/driver-lock-lib.sh-19-
relay-automation/driver-lock-lib.sh:20:driver_lock_path_for_repo() {
relay-automation/driver-lock-lib.sh-21-  local repo="$1"
relay-automation/driver-lock-lib.sh-22-  if [ -d "$repo/.git" ]; then
relay-automation/driver-lock-lib.sh:23:    printf '%s/.git/relay-driver.lock' "$repo"
relay-automation/driver-lock-lib.sh-24-    return 0
relay-automation/driver-lock-lib.sh-25-  fi
relay-automation/driver-lock-lib.sh-26-  if [ -f "$repo/.git" ]; then
relay-automation/driver-lock-lib.sh-27-    local common
relay-automation/driver-lock-lib.sh-28-    common="$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
relay-automation/driver-lock-lib.sh-29-    if [ -n "$common" ]; then
relay-automation/driver-lock-lib.sh:30:      printf '%s/relay-driver.lock' "$common"
relay-automation/driver-lock-lib.sh-31-      return 0
relay-automation/driver-lock-lib.sh-32-    fi
relay-automation/driver-lock-lib.sh-33-  fi
relay-automation/driver-lock-lib.sh:34:  printf '%s/.relay-driver.lock' "$repo"
relay-automation/driver-lock-lib.sh-35-}
--
test/gh448-driver-lock-resolver.sh-1-#!/usr/bin/env bash
test/gh448-driver-lock-resolver.sh-2-# test/gh448-driver-lock-resolver.sh — GH-448: the shared driver-lock resolver.
test/gh448-driver-lock-resolver.sh-3-#
test/gh448-driver-lock-resolver.sh-4-# marathon-drive writes its lock to the git COMMON dir when .git is a FILE (a linked worktree). Every
test/gh448-driver-lock-resolver.sh-5-# read-only consumer used to guess the path with its OWN 2-branch inline logic (dir vs "everything
test/gh448-driver-lock-resolver.sh-6-# else"), which is wrong for the worktree case — so a LIVE marathon reported as IDLE. This test:
test/gh448-driver-lock-resolver.sh-7-#
test/gh448-driver-lock-resolver.sh-8-#   A. Parity — the Bash resolver (relay-automation/driver-lock-lib.sh) and the Python resolver
test/gh448-driver-lock-resolver.sh:9:#      (utils/py/rtl.py's driver_lock_path) agree byte-for-byte on all three branches: .git dir,
test/gh448-driver-lock-resolver.sh-10-#      .git file (real linked worktree), and no .git (vendored).
test/gh448-driver-lock-resolver.sh-11-#   B. Negative control (per #419) — the OLD 2-branch logic each consumer carried pre-fix, replayed
test/gh448-driver-lock-resolver.sh-12-#      verbatim against the SAME linked-worktree fixture, observably misses the lock the driver holds.
test/gh448-driver-lock-resolver.sh-13-#   C. End-to-end, real linked worktree — marathon-ls.sh, utils/hq/marathon-live.sh, and
test/gh448-driver-lock-resolver.sh-14-#      skills/relay-xyz/find-harness.sh --check, run for real against a `git worktree add` fixture
test/gh448-driver-lock-resolver.sh-15-#      with the lock held at the driver's real (common-dir) path, all observe it correctly.
test/gh448-driver-lock-resolver.sh-16-set -uo pipefail
test/gh448-driver-lock-resolver.sh-17-
test/gh448-driver-lock-resolver.sh-18-HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
test/gh448-driver-lock-resolver.sh-19-ROOT="$(cd "$HERE/.." && pwd)"
test/gh448-driver-lock-resolver.sh-20-LIB="$ROOT/relay-automation/driver-lock-lib.sh"
test/gh448-driver-lock-resolver.sh-21-LS="$ROOT/relay-automation/marathon-ls.sh"
--
test/gh448-driver-lock-resolver.sh-30-
test/gh448-driver-lock-resolver.sh-31-PASS=0; FAIL=0
test/gh448-driver-lock-resolver.sh-32-pass() { printf '  PASS: %s\n' "$*"; PASS=$((PASS+1)); }
test/gh448-driver-lock-resolver.sh-33-fail() { printf '  FAIL: %s\n' "$*" >&2; FAIL=$((FAIL+1)); }
test/gh448-driver-lock-resolver.sh-34-
test/gh448-driver-lock-resolver.sh-35-echo "== test: gh448-driver-lock-resolver =="
test/gh448-driver-lock-resolver.sh-36-echo "  workdir: $WORK"
test/gh448-driver-lock-resolver.sh-37-
test/gh448-driver-lock-resolver.sh-38-py_resolve() {  # <repo> -> prints the python resolver's lock path
test/gh448-driver-lock-resolver.sh-39-  python3 -c '
test/gh448-driver-lock-resolver.sh-40-import sys
test/gh448-driver-lock-resolver.sh-41-sys.path.insert(0, sys.argv[2])
test/gh448-driver-lock-resolver.sh:42:from rtl import driver_lock_path
test/gh448-driver-lock-resolver.sh:43:print(driver_lock_path(sys.argv[1])[0], end="")
test/gh448-driver-lock-resolver.sh-44-' "$1" "$ROOT/utils/py"
test/gh448-driver-lock-resolver.sh-45-}
test/gh448-driver-lock-resolver.sh-46-
test/gh448-driver-lock-resolver.sh-47-# ---------------------------------------------------------------------------
test/gh448-driver-lock-resolver.sh-48-# Fixtures
test/gh448-driver-lock-resolver.sh-49-# ---------------------------------------------------------------------------
test/gh448-driver-lock-resolver.sh-50-
test/gh448-driver-lock-resolver.sh-51-# (1) Normal clone: .git is a directory.
test/gh448-driver-lock-resolver.sh-52-DIR_REPO="$WORK/dir-repo"
test/gh448-driver-lock-resolver.sh-53-mkdir -p "$DIR_REPO/.git"
test/gh448-driver-lock-resolver.sh-54-
test/gh448-driver-lock-resolver.sh-55-# (2) Vendored: no .git at all.
--
test/gh448-driver-lock-resolver.sh-61-mkdir -p "$MAIN_REPO"
test/gh448-driver-lock-resolver.sh-62-git init -q "$MAIN_REPO"
test/gh448-driver-lock-resolver.sh-63-git -C "$MAIN_REPO" config user.email t@example.com
test/gh448-driver-lock-resolver.sh-64-git -C "$MAIN_REPO" config user.name "gh448 test"
test/gh448-driver-lock-resolver.sh-65-printf 'seed\n' >"$MAIN_REPO/seed.txt"
test/gh448-driver-lock-resolver.sh-66-git -C "$MAIN_REPO" add seed.txt
test/gh448-driver-lock-resolver.sh-67-git -C "$MAIN_REPO" commit -qm seed
test/gh448-driver-lock-resolver.sh-68-WT="$WORK/wt"
test/gh448-driver-lock-resolver.sh-69-git -C "$MAIN_REPO" worktree add -q "$WT" -b gh448-wt-branch
test/gh448-driver-lock-resolver.sh-70-[ -f "$WT/.git" ] && pass "fixture: linked worktree's .git is a FILE (not a dir)" \
test/gh448-driver-lock-resolver.sh-71-  || fail "fixture setup: expected $WT/.git to be a file"
test/gh448-driver-lock-resolver.sh-72-
test/gh448-driver-lock-resolver.sh:73:COMMON_LOCK="$MAIN_REPO/.git/relay-driver.lock"
test/gh448-driver-lock-resolver.sh-74-
test/gh448-driver-lock-resolver.sh-75-# ===========================================================================
test/gh448-driver-lock-resolver.sh-76-# A. Parity — Bash resolver vs Python resolver, all three branches
test/gh448-driver-lock-resolver.sh-77-# ===========================================================================
test/gh448-driver-lock-resolver.sh-78-echo "-- A. resolver parity (bash vs python) --"
test/gh448-driver-lock-resolver.sh-79-
test/gh448-driver-lock-resolver.sh-80-for case_name_repo in "dir:$DIR_REPO" "absent:$ABSENT_REPO" "worktree:$WT"; do
test/gh448-driver-lock-resolver.sh-81-  name="${case_name_repo%%:*}"; repo="${case_name_repo#*:}"
test/gh448-driver-lock-resolver.sh:82:  bash_out="$(driver_lock_path_for_repo "$repo")"
test/gh448-driver-lock-resolver.sh-83-  py_out="$(py_resolve "$repo")"
test/gh448-driver-lock-resolver.sh-84-  [ "$bash_out" = "$py_out" ] \
test/gh448-driver-lock-resolver.sh-85-    && pass "parity ($name): bash and python agree ($bash_out)" \
test/gh448-driver-lock-resolver.sh-86-    || fail "parity ($name): bash='$bash_out' python='$py_out'"
test/gh448-driver-lock-resolver.sh-87-done
test/gh448-driver-lock-resolver.sh-88-
test/gh448-driver-lock-resolver.sh:89:[ "$(driver_lock_path_for_repo "$WT")" = "$COMMON_LOCK" ] \
test/gh448-driver-lock-resolver.sh-90-  && pass "worktree case resolves to the git COMMON dir, not <worktree>/.git/…" \
test/gh448-driver-lock-resolver.sh:91:  || fail "worktree case resolved wrong: $(driver_lock_path_for_repo "$WT") (expected $COMMON_LOCK)"
test/gh448-driver-lock-resolver.sh-92-
test/gh448-driver-lock-resolver.sh-93-# ===========================================================================
test/gh448-driver-lock-resolver.sh-94-# B. Negative control — the OLD 2-branch logic each site carried, replayed
test/gh448-driver-lock-resolver.sh-95-#    verbatim against the SAME worktree fixture. Per #419: observed, not
test/gh448-driver-lock-resolver.sh-96-#    asserted-in-prose. All three must MISS the lock the driver holds.
test/gh448-driver-lock-resolver.sh-97-# ===========================================================================
test/gh448-driver-lock-resolver.sh-98-echo "-- B. negative control: pre-fix 2-branch logic misses the worktree lock --"
test/gh448-driver-lock-resolver.sh-99-
test/gh448-driver-lock-resolver.sh-100-# marathon-ls.sh's original lock_path_for_repo (pre-GH-448):
test/gh448-driver-lock-resolver.sh-101-old_marathon_ls_lock() {
test/gh448-driver-lock-resolver.sh-102-  local repo="$1"
test/gh448-driver-lock-resolver.sh:103:  if [ -d "$repo/.git" ]; then printf '%s/.git/relay-driver.lock' "$repo"
test/gh448-driver-lock-resolver.sh:104:  else printf '%s/.relay-driver.lock' "$repo"; fi
test/gh448-driver-lock-resolver.sh-105-}
test/gh448-driver-lock-resolver.sh-106-
test/gh448-driver-lock-resolver.sh:107:# utils/hq/marathon-live.sh's original driver_lock_path (pre-GH-448):
test/gh448-driver-lock-resolver.sh-108-old_marathon_live_lock() {
test/gh448-driver-lock-resolver.sh-109-  local repo="$1"
test/gh448-driver-lock-resolver.sh:110:  [ -e "$repo/.git/relay-driver.lock" ] && { printf '%s' "$repo/.git/relay-driver.lock"; return 0; }
test/gh448-driver-lock-resolver.sh:111:  [ -e "$repo/.xyz/.relay-driver.lock" ] && { printf '%s' "$repo/.xyz/.relay-driver.lock"; return 0; }
test/gh448-driver-lock-resolver.sh-112-  return 1
test/gh448-driver-lock-resolver.sh-113-}
test/gh448-driver-lock-resolver.sh-114-
test/gh448-driver-lock-resolver.sh-115-mkdir -p "$COMMON_LOCK"; printf '%s\n' "$$" >"$COMMON_LOCK/pid"
test/gh448-driver-lock-resolver.sh-116-
test/gh448-driver-lock-resolver.sh-117-old_ls_path="$(old_marathon_ls_lock "$WT")"
test/gh448-driver-lock-resolver.sh-118-[ "$old_ls_path" != "$COMMON_LOCK" ] && [ ! -e "$old_ls_path" ] \
test/gh448-driver-lock-resolver.sh-119-  && pass "negative control: old marathon-ls.sh logic guesses '$old_ls_path' — misses the held lock" \
test/gh448-driver-lock-resolver.sh-120-  || fail "negative control: old marathon-ls.sh logic unexpectedly found the lock"
test/gh448-driver-lock-resolver.sh-121-
test/gh448-driver-lock-resolver.sh-122-if old_live_path="$(old_marathon_live_lock "$WT")"; then
test/gh448-driver-lock-resolver.sh-123-  fail "negative control: old marathon-live.sh logic unexpectedly found the lock ($old_live_path)"
test/gh448-driver-lock-resolver.sh-124-else
test/gh448-driver-lock-resolver.sh-125-  pass "negative control: old marathon-live.sh logic (checks .git/… or .xyz/… under \$WT) misses the held lock"
test/gh448-driver-lock-resolver.sh-126-fi
test/gh448-driver-lock-resolver.sh-127-
test/gh448-driver-lock-resolver.sh-128-old_fh_found=0
test/gh448-driver-lock-resolver.sh:129:for _lk in "$WT/.git/relay-driver.lock" "$WT/.relay-driver.lock"; do
test/gh448-driver-lock-resolver.sh-130-  [ -d "$_lk" ] && old_fh_found=1
test/gh448-driver-lock-resolver.sh-131-done
test/gh448-driver-lock-resolver.sh-132-[ "$old_fh_found" -eq 0 ] \
test/gh448-driver-lock-resolver.sh-133-  && pass "negative control: old find-harness.sh 2-candidate loop misses the held lock" \
test/gh448-driver-lock-resolver.sh-134-  || fail "negative control: old find-harness.sh 2-candidate loop unexpectedly found the lock"
test/gh448-driver-lock-resolver.sh-135-
test/gh448-driver-lock-resolver.sh-136-rm -rf "$COMMON_LOCK"
test/gh448-driver-lock-resolver.sh-137-
test/gh448-driver-lock-resolver.sh-138-# ===========================================================================
test/gh448-driver-lock-resolver.sh-139-# C. End-to-end, real linked worktree — the ACTUAL (fixed) scripts
test/gh448-driver-lock-resolver.sh-140-# ===========================================================================
test/gh448-driver-lock-resolver.sh-141-echo "-- C. end-to-end: fixed scripts observe LIVE from a linked worktree --"
--
test/gh448-driver-lock-resolver.sh-189-printf '#!/usr/bin/env bash\n:\n' >"$HARNESS_MAIN/relay-automation/relay-drive.sh"
test/gh448-driver-lock-resolver.sh-190-chmod +x "$HARNESS_MAIN/relay-automation/relay-drive.sh"
test/gh448-driver-lock-resolver.sh-191-cp "$LIB" "$HARNESS_MAIN/relay-automation/driver-lock-lib.sh"
test/gh448-driver-lock-resolver.sh-192-cp "$FH" "$HARNESS_MAIN/skills/relay-xyz/find-harness.sh"
test/gh448-driver-lock-resolver.sh-193-git init -q "$HARNESS_MAIN"
test/gh448-driver-lock-resolver.sh-194-git -C "$HARNESS_MAIN" config user.email t@example.com
test/gh448-driver-lock-resolver.sh-195-git -C "$HARNESS_MAIN" config user.name "gh448 test"
test/gh448-driver-lock-resolver.sh-196-git -C "$HARNESS_MAIN" add -A
test/gh448-driver-lock-resolver.sh-197-git -C "$HARNESS_MAIN" commit -qm seed
test/gh448-driver-lock-resolver.sh-198-HARNESS_WT="$WORK/harness-wt"
test/gh448-driver-lock-resolver.sh-199-git -C "$HARNESS_MAIN" worktree add -q "$HARNESS_WT" -b gh448-harness-wt-branch
test/gh448-driver-lock-resolver.sh-200-
test/gh448-driver-lock-resolver.sh:201:HARNESS_COMMON_LOCK="$HARNESS_MAIN/.git/relay-driver.lock"
test/gh448-driver-lock-resolver.sh-202-mkdir -p "$HARNESS_COMMON_LOCK"; printf '%s\n' "$$" >"$HARNESS_COMMON_LOCK/pid"
test/gh448-driver-lock-resolver.sh-203-
test/gh448-driver-lock-resolver.sh-204-FOREIGN="$WORK/foreign"
test/gh448-driver-lock-resolver.sh-205-mkdir -p "$FOREIGN"
test/gh448-driver-lock-resolver.sh-206-git init -q "$FOREIGN"
test/gh448-driver-lock-resolver.sh-207-
test/gh448-driver-lock-resolver.sh-208-fh_out="$(cd "$FOREIGN" && bash "$HARNESS_WT/skills/relay-xyz/find-harness.sh" --check 2>&1)"
test/gh448-driver-lock-resolver.sh-209-printf '%s' "$fh_out" | grep -q 'a driver lock is currently HELD' \
test/gh448-driver-lock-resolver.sh-210-  && pass "find-harness.sh --check: linked-worktree harness + held common-dir lock -> warns" \
test/gh448-driver-lock-resolver.sh-211-  || fail "find-harness.sh --check: expected a held-lock warning, got: $fh_out"
test/gh448-driver-lock-resolver.sh-212-printf '%s' "$fh_out" | grep -qF "$HARNESS_COMMON_LOCK" \
test/gh448-driver-lock-resolver.sh-213-  && pass "find-harness.sh --check: warning names the REAL (common-dir) lock path" \
--
utils/hq/marathon-live.sh-86-
utils/hq/marathon-live.sh-87-# Derive a human "marathon/lane" label from a claimed task id (e.g. MARATHON-GH208-FOO-TURN -> GH208-FOO).
utils/hq/marathon-live.sh-88-lane_of() {
utils/hq/marathon-live.sh-89-  local task="$1"
utils/hq/marathon-live.sh-90-  task="${task#MARATHON-}"; task="${task#RELAY-}"
utils/hq/marathon-live.sh-91-  task="${task%-TURN}"
utils/hq/marathon-live.sh-92-  printf '%s' "$task"
utils/hq/marathon-live.sh-93-}
utils/hq/marathon-live.sh-94-
utils/hq/marathon-live.sh-95-# Is the driver lock present for this repo? Prints the lock path or nothing. GH-448: resolved via the
utils/hq/marathon-live.sh-96-# shared resolver (relay-automation/driver-lock-lib.sh) — the SAME path the driver itself writes,
utils/hq/marathon-live.sh-97-# including the linked-worktree case (.git is a FILE -> the git common dir, not <repo>/.git/…) and the
utils/hq/marathon-live.sh:98:# vendored case (no .git -> <repo>/.relay-driver.lock, NOT <repo>/.xyz/.relay-driver.lock — the driver
utils/hq/marathon-live.sh-99-# never writes inside .xyz/, so the old .xyz/-scoped check here could never have matched a real lock).
utils/hq/marathon-live.sh:100:driver_lock_path() {
utils/hq/marathon-live.sh-101-  local repo_path="$1" lock
utils/hq/marathon-live.sh:102:  lock="$(driver_lock_path_for_repo "$repo_path")"
utils/hq/marathon-live.sh-103-  [[ -e "$lock" ]] && { printf '%s' "$lock"; return 0; }
utils/hq/marathon-live.sh-104-  return 1
utils/hq/marathon-live.sh-105-}
utils/hq/marathon-live.sh-106-
utils/hq/marathon-live.sh-107-# Newest marathon/*-branch worktree commit epoch within the repo, or empty. Best-effort — a fixture
utils/hq/marathon-live.sh-108-# .git that is not a real repo simply yields nothing (guarded), never an error.
utils/hq/marathon-live.sh-109-newest_marathon_worktree_epoch() {
utils/hq/marathon-live.sh-110-  local repo_path="$1" wt="" br="" best="" ct
utils/hq/marathon-live.sh-111-  while IFS= read -r line; do
utils/hq/marathon-live.sh-112-    case "$line" in
utils/hq/marathon-live.sh-113-      worktree\ *) wt="${line#worktree }" ;;
utils/hq/marathon-live.sh-114-      branch\ *)
--
utils/hq/marathon-live.sh-135-  repo_path="$(printf '%s\n' "$fields" | sed -n 's/^REPO_PATH=//p' | head -1)"
utils/hq/marathon-live.sh-136-  [[ -n "$repo_path" && -d "$repo_path" ]] || continue
utils/hq/marathon-live.sh-137-  repos_scanned=$((repos_scanned + 1))
utils/hq/marathon-live.sh-138-
utils/hq/marathon-live.sh-139-  # Regenerate this repo's STATE.md from its own event log (writes only .tick/, coordination state —
utils/hq/marathon-live.sh-140-  # never touched code). Best-effort: a repo with no tick binary / no events is simply reported idle.
utils/hq/marathon-live.sh-141-  tick_bin="$(resolve_tick "$repo_path" || true)"
utils/hq/marathon-live.sh-142-  if [[ -n "$tick_bin" ]]; then
utils/hq/marathon-live.sh-143-    ( cd "$repo_path" && TICK_REPO_ROOT="$repo_path" "$tick_bin" project ) >/dev/null 2>&1 || true
utils/hq/marathon-live.sh-144-  fi
utils/hq/marathon-live.sh-145-
utils/hq/marathon-live.sh-146-  # Liveness signals for the whole repo (shared by each claimed task in it).
utils/hq/marathon-live.sh:147:  lock_path="$(driver_lock_path "$repo_path" || true)"
utils/hq/marathon-live.sh-148-  wt_epoch="$(newest_marathon_worktree_epoch "$repo_path")"
utils/hq/marathon-live.sh-149-  recent_wt=0
utils/hq/marathon-live.sh-150-  if [[ -n "$wt_epoch" ]] && (( NOW_EPOCH - wt_epoch <= window_secs )); then recent_wt=1; fi
utils/hq/marathon-live.sh-151-  is_driving=0
utils/hq/marathon-live.sh-152-  [[ -n "$lock_path" || "$recent_wt" == 1 ]] && is_driving=1
utils/hq/marathon-live.sh-153-
utils/hq/marathon-live.sh-154-  # Last-activity display: newest marathon worktree commit, else the driver-lock mtime, else em dash.
utils/hq/marathon-live.sh-155-  last_activity="—"
utils/hq/marathon-live.sh-156-  if [[ -n "$wt_epoch" ]]; then
utils/hq/marathon-live.sh-157-    last_activity="$(date -u -r "$wt_epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$wt_epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || printf 'epoch:%s' "$wt_epoch")"
utils/hq/marathon-live.sh-158-  elif [[ -n "$lock_path" ]]; then
utils/hq/marathon-live.sh-159-    lk_epoch="$(stat -f %m "$lock_path" 2>/dev/null || stat -c %Y "$lock_path" 2>/dev/null || true)"
--
utils/py/rtl.py-465-                if line.startswith("[trace] "):
utils/py/rtl.py-466-                    continue
utils/py/rtl.py-467-                if "TICK_REPO_ROOT=" in line or "file://" in line or "](" in line:
utils/py/rtl.py-468-                    continue
utils/py/rtl.py-469-                if root in line:
utils/py/rtl.py-470-                    count += 1
utils/py/rtl.py-471-                    if first is None:
utils/py/rtl.py-472-                        first = line.strip()
utils/py/rtl.py-473-    except OSError:
utils/py/rtl.py-474-        return 0, None
utils/py/rtl.py-475-    return count, first
utils/py/rtl.py-476-
utils/py/rtl.py:477:def driver_lock_path(root):
utils/py/rtl.py-478-    # GH-448: the ONE shared resolver for the relay-driver lock path, matching the DRIVER's own
utils/py/rtl.py-479-    # write-side resolution (marathon_drive.py / marathon-drive.sh, relay_drive.py / relay-drive.sh) —
utils/py/rtl.py-480-    # every read-only consumer (marathon-ls.sh, marathon-live.sh, find-harness.sh) must resolve the
utils/py/rtl.py-481-    # SAME path or it probes a location the driver never writes and reports a live run as idle.
utils/py/rtl.py:482:    #   .git is a directory  -> <root>/.git/relay-driver.lock                (normal clone)
utils/py/rtl.py:483:    #   .git is a file       -> <git-common-dir>/relay-driver.lock           (linked worktree)
utils/py/rtl.py:484:    #   no .git (vendored)   -> <root>/.relay-driver.lock                    (vendored .xyz/ copy)
utils/py/rtl.py-485-    # Returns (lock_path, lock_label) — lock_label is always the SHORT display form used in messages.
utils/py/rtl.py-486-    git_path = os.path.join(root, ".git")
utils/py/rtl.py-487-    if os.path.isdir(git_path):
utils/py/rtl.py:488:        return os.path.join(root, ".git", "relay-driver.lock"), ".git/relay-driver.lock"
utils/py/rtl.py-489-    if os.path.isfile(git_path):
utils/py/rtl.py-490-        common = ""
utils/py/rtl.py-491-        try:
utils/py/rtl.py-492-            common = subprocess.check_output(
utils/py/rtl.py-493-                ["git", "-C", root, "rev-parse", "--path-format=absolute", "--git-common-dir"],
utils/py/rtl.py-494-                stderr=subprocess.DEVNULL).decode("utf-8").strip()
utils/py/rtl.py-495-        except Exception:
utils/py/rtl.py-496-            common = ""
utils/py/rtl.py-497-        if common:
utils/py/rtl.py:498:            return os.path.join(common, "relay-driver.lock"), ".git/relay-driver.lock"
utils/py/rtl.py:499:    return os.path.join(root, ".relay-driver.lock"), ".relay-driver.lock"
--
relay-automation/marathon-ls.sh-34-
relay-automation/marathon-ls.sh-35-# shellcheck source=relay-automation/driver-lock-lib.sh
relay-automation/marathon-ls.sh-36-. "$SELF_DIR/driver-lock-lib.sh"
relay-automation/marathon-ls.sh-37-
relay-automation/marathon-ls.sh-38-# ---------------------------------------------------------------------------
relay-automation/marathon-ls.sh-39-# helpers
relay-automation/marathon-ls.sh-40-# ---------------------------------------------------------------------------
relay-automation/marathon-ls.sh-41-
relay-automation/marathon-ls.sh-42-trim_cr() { printf '%s' "${1%$'\r'}"; }
relay-automation/marathon-ls.sh-43-
relay-automation/marathon-ls.sh-44-# Resolve the relay-driver lock path for a given repo root — delegates to the shared resolver
relay-automation/marathon-ls.sh-45-# (GH-448: this used to guess 2 branches inline and missed the linked-worktree case, where .git is a
relay-automation/marathon-ls.sh:46:# FILE and the driver's real lock lives at the git common dir, not <repo>/.git/relay-driver.lock).
relay-automation/marathon-ls.sh-47-lock_path_for_repo() {
relay-automation/marathon-ls.sh:48:  driver_lock_path_for_repo "$1"
relay-automation/marathon-ls.sh-49-}
relay-automation/marathon-ls.sh-50-
relay-automation/marathon-ls.sh-51-# Find the newest *marathon*.jsonl file under <repo>/.tick/events/.
relay-automation/marathon-ls.sh-52-newest_marathon_jsonl() {
relay-automation/marathon-ls.sh-53-  local repo="$1"
relay-automation/marathon-ls.sh-54-  local events_dir="$repo/.tick/events"
relay-automation/marathon-ls.sh-55-  [ -d "$events_dir" ] || return 0
relay-automation/marathon-ls.sh-56-  # Use ls -t (newest first) rather than `find -newer` for bash 3.2 compat.
relay-automation/marathon-ls.sh-57-  # Glob for files matching *marathon*.jsonl; pick the first (newest by mtime).
relay-automation/marathon-ls.sh-58-  local f
relay-automation/marathon-ls.sh-59-  # shellcheck disable=SC2012
relay-automation/marathon-ls.sh-60-  f="$(ls -t "$events_dir"/*marathon*.jsonl 2>/dev/null | head -1 || true)"
--
utils/py/marathon_drive.py-8-import shlex
utils/py/marathon_drive.py-9-import shutil
utils/py/marathon_drive.py-10-import json
utils/py/marathon_drive.py-11-import tempfile
utils/py/marathon_drive.py-12-import threading
utils/py/marathon_drive.py-13-import datetime as _dt
utils/py/marathon_drive.py-14-
utils/py/marathon_drive.py-15-# Import rtl relative to this file (utils/py/), independent of CWD/PYTHONPATH — needed because some
utils/py/marathon_drive.py-16-# callers load this module via importlib.util.spec_from_file_location rather than `python3 <path>`,
utils/py/marathon_drive.py-17-# which does NOT put the script's own directory on sys.path (GH-448 regression, test/gh322-runlog-
utils/py/marathon_drive.py-18-# python-lane.sh caught it). Same pattern as marathon_plan.py's `_marathon_plan` import.
utils/py/marathon_drive.py-19-sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
utils/py/marathon_drive.py:20:from rtl import driver_lock_path  # noqa: E402
utils/py/marathon_drive.py-21-
utils/py/marathon_drive.py-22-# GH-284 Phase 2 / GH-322: hooks run on EVERY terminal path with the driver's real exit code — the
utils/py/marathon_drive.py-23-# Python equivalent of marathon-drive.sh's `trap _marathon_drive_on_exit EXIT`. Same contract as
utils/py/marathon_drive.py-24-# that trap: the code is captured FIRST and re-exited explicitly, so nothing a hook does can
utils/py/marathon_drive.py-25-# overwrite the driven run's real status.
utils/py/marathon_drive.py-26-_ON_EXIT = []
utils/py/marathon_drive.py-27-
utils/py/marathon_drive.py-28-
utils/py/marathon_drive.py-29-# GH-333: the run log used to carry a `driver still running` line that could only ever say
utils/py/marathon_drive.py-30-# "running". Dropping it left `driver exit: `3`` as the sole disposition signal — a bare number the
utils/py/marathon_drive.py-31-# reader has to look up. Naming it is the half of that field which was actually worth keeping.
utils/py/marathon_drive.py-32-#
--
utils/py/marathon_drive.py-597-        if reason:
utils/py/marathon_drive.py-598-            out += (f"Last recorded reason (`{os.path.join(phase_rel, 'ESCALATION.md')}`): `{reason}`. "
utils/py/marathon_drive.py-599-                    "Read it before re-guessing.\n")
utils/py/marathon_drive.py-600-        return out
utils/py/marathon_drive.py-601-
utils/py/marathon_drive.py-602-    if get_env("RELAY_DRIVER_LOCKED", "0") != "1":
utils/py/marathon_drive.py-603-        # GH-49b/GH-207: the lock lives in .git/ (never committed) for a normal clone. In a linked
utils/py/marathon_drive.py-604-        # worktree .git is a FILE pointing at the shared gitdir, so resolve the real common dir and put
utils/py/marathon_drive.py-605-        # the lock there — otherwise --require-clean sees the driver's own lock as untracked dirt inside
utils/py/marathon_drive.py-606-        # the worktree. A vendored .xyz/ copy (no .git) falls back to a hidden lock beside the scripts.
utils/py/marathon_drive.py-607-        # GH-448: this resolution is the canonical write-side one — every read-only consumer (marathon-
utils/py/marathon_drive.py-608-        # ls.sh, marathon-live.sh, find-harness.sh) must agree with it, so it lives in rtl.py's shared
utils/py/marathon_drive.py:609:        # driver_lock_path (with a byte-for-byte Bash twin in relay-automation/driver-lock-lib.sh)
utils/py/marathon_drive.py-610-        # rather than being reimplemented here.
utils/py/marathon_drive.py:611:        lock_dir, lock_label = driver_lock_path(root)
utils/py/marathon_drive.py-612-
utils/py/marathon_drive.py-613-        try:
utils/py/marathon_drive.py-614-            os.mkdir(lock_dir)
utils/py/marathon_drive.py-615-        except OSError:
utils/py/marathon_drive.py-616-            holder = ""
utils/py/marathon_drive.py-617-            pid_file = os.path.join(lock_dir, "pid")
utils/py/marathon_drive.py-618-            if os.path.isfile(pid_file):
utils/py/marathon_drive.py-619-                try:
utils/py/marathon_drive.py-620-                    with open(pid_file, 'r') as f: holder = f.read().strip()
utils/py/marathon_drive.py-621-                except: pass
utils/py/marathon_drive.py-622-            
utils/py/marathon_drive.py-623-            is_running = False
utils/py/marathon_drive.py-624-            if holder:
utils/py/marathon_drive.py-625-                try:
utils/py/marathon_drive.py-626-                    os.kill(int(holder), 0)
utils/py/marathon_drive.py-627-                    is_running = True
utils/py/marathon_drive.py-628-                except: pass
utils/py/marathon_drive.py-629-            
utils/py/marathon_drive.py-630-            if is_running:
utils/py/marathon_drive.py-631-                eprint(f"marathon-drive: another driver is active in this repo (pid {holder}, lock: {lock_label}).")
utils/py/marathon_drive.py-632-                eprint("marathon-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).")
utils/py/marathon_drive.py-633-                sys.exit(1)
utils/py/marathon_drive.py-634-            
utils/py/marathon_drive.py:635:            eprint(f"marathon-drive: reclaiming stale relay-driver.lock (holder pid {holder or 'none'} not running).")
utils/py/marathon_drive.py-636-            # Sentinel Tier 1 (GH-281/GH-342): record the auto-heal. Emitted BEFORE the reclaim, so
utils/py/marathon_drive.py-637-            # the finding survives even if the rmtree/mkdir below fails and the run exits 1.
utils/py/marathon_drive.py-638-            xyz_debug_log_stale_lock(root)
utils/py/marathon_drive.py-639-            try:
utils/py/marathon_drive.py-640-                shutil.rmtree(lock_dir)
utils/py/marathon_drive.py-641-                os.mkdir(lock_dir)
utils/py/marathon_drive.py-642-            except:
utils/py/marathon_drive.py:643:                eprint("marathon-drive: could not acquire relay-driver.lock after reclaiming a stale one.")
utils/py/marathon_drive.py-644-                sys.exit(1)
utils/py/marathon_drive.py-645-        
utils/py/marathon_drive.py-646-        with open(os.path.join(lock_dir, "pid"), 'w') as f:
utils/py/marathon_drive.py-647-            f.write(str(os.getpid()) + "\n")
utils/py/marathon_drive.py-648-        
utils/py/marathon_drive.py-649-        os.environ["RELAY_DRIVER_LOCKED"] = "1"
utils/py/marathon_drive.py-650-        def cleanup_lock():
utils/py/marathon_drive.py-651-            try: shutil.rmtree(lock_dir)
utils/py/marathon_drive.py-652-            except: pass
utils/py/marathon_drive.py-653-        import atexit
utils/py/marathon_drive.py-654-        atexit.register(cleanup_lock)
utils/py/marathon_drive.py-655-
     1	#!/usr/bin/env bash
     2	# test/gh448-driver-lock-resolver.sh — GH-448: the shared driver-lock resolver.
     3	#
     4	# marathon-drive writes its lock to the git COMMON dir when .git is a FILE (a linked worktree). Every
     5	# read-only consumer used to guess the path with its OWN 2-branch inline logic (dir vs "everything
     6	# else"), which is wrong for the worktree case — so a LIVE marathon reported as IDLE. This test:
     7	#
     8	#   A. Parity — the Bash resolver (relay-automation/driver-lock-lib.sh) and the Python resolver
     9	#      (utils/py/rtl.py's driver_lock_path) agree byte-for-byte on all three branches: .git dir,
    10	#      .git file (real linked worktree), and no .git (vendored).
    11	#   B. Negative control (per #419) — the OLD 2-branch logic each consumer carried pre-fix, replayed
    12	#      verbatim against the SAME linked-worktree fixture, observably misses the lock the driver holds.
    13	#   C. End-to-end, real linked worktree — marathon-ls.sh, utils/hq/marathon-live.sh, and
    14	#      skills/relay-xyz/find-harness.sh --check, run for real against a `git worktree add` fixture
    15	#      with the lock held at the driver's real (common-dir) path, all observe it correctly.
    16	set -uo pipefail
    17	
    18	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    19	ROOT="$(cd "$HERE/.." && pwd)"
    20	LIB="$ROOT/relay-automation/driver-lock-lib.sh"
    21	LS="$ROOT/relay-automation/marathon-ls.sh"
    22	LIVE="$ROOT/utils/hq/marathon-live.sh"
    23	FH="$ROOT/skills/relay-xyz/find-harness.sh"
    24	
    25	# shellcheck source=relay-automation/driver-lock-lib.sh
    26	. "$LIB"
    27	
    28	WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh448-driver-lock.XXXXXX")"
    29	trap 'rm -rf "$WORK"' EXIT
    30	
    31	PASS=0; FAIL=0
    32	pass() { printf '  PASS: %s\n' "$*"; PASS=$((PASS+1)); }
    33	fail() { printf '  FAIL: %s\n' "$*" >&2; FAIL=$((FAIL+1)); }
    34	
    35	echo "== test: gh448-driver-lock-resolver =="
    36	echo "  workdir: $WORK"
    37	
    38	py_resolve() {  # <repo> -> prints the python resolver's lock path
    39	  python3 -c '
    40	import sys
    41	sys.path.insert(0, sys.argv[2])
    42	from rtl import driver_lock_path
    43	print(driver_lock_path(sys.argv[1])[0], end="")
    44	' "$1" "$ROOT/utils/py"
    45	}
    46	
    47	# ---------------------------------------------------------------------------
    48	# Fixtures
    49	# ---------------------------------------------------------------------------
    50	
    51	# (1) Normal clone: .git is a directory.
    52	DIR_REPO="$WORK/dir-repo"
    53	mkdir -p "$DIR_REPO/.git"
    54	
    55	# (2) Vendored: no .git at all.
    56	ABSENT_REPO="$WORK/absent-repo"
    57	mkdir -p "$ABSENT_REPO"
    58	
    59	# (3) Real linked worktree: .git is a FILE pointing at the shared gitdir.
    60	MAIN_REPO="$WORK/main-repo"
    61	mkdir -p "$MAIN_REPO"
    62	git init -q "$MAIN_REPO"
    63	git -C "$MAIN_REPO" config user.email t@example.com
    64	git -C "$MAIN_REPO" config user.name "gh448 test"
    65	printf 'seed\n' >"$MAIN_REPO/seed.txt"
    66	git -C "$MAIN_REPO" add seed.txt
    67	git -C "$MAIN_REPO" commit -qm seed
    68	WT="$WORK/wt"
    69	git -C "$MAIN_REPO" worktree add -q "$WT" -b gh448-wt-branch
    70	[ -f "$WT/.git" ] && pass "fixture: linked worktree's .git is a FILE (not a dir)" \
    71	  || fail "fixture setup: expected $WT/.git to be a file"
    72	
    73	COMMON_LOCK="$MAIN_REPO/.git/relay-driver.lock"
    74	
    75	# ===========================================================================
    76	# A. Parity — Bash resolver vs Python resolver, all three branches
    77	# ===========================================================================
    78	echo "-- A. resolver parity (bash vs python) --"
    79	
    80	for case_name_repo in "dir:$DIR_REPO" "absent:$ABSENT_REPO" "worktree:$WT"; do
    81	  name="${case_name_repo%%:*}"; repo="${case_name_repo#*:}"
    82	  bash_out="$(driver_lock_path_for_repo "$repo")"
    83	  py_out="$(py_resolve "$repo")"
    84	  [ "$bash_out" = "$py_out" ] \
    85	    && pass "parity ($name): bash and python agree ($bash_out)" \
    86	    || fail "parity ($name): bash='$bash_out' python='$py_out'"
    87	done
    88	
    89	[ "$(driver_lock_path_for_repo "$WT")" = "$COMMON_LOCK" ] \
    90	  && pass "worktree case resolves to the git COMMON dir, not <worktree>/.git/…" \
    91	  || fail "worktree case resolved wrong: $(driver_lock_path_for_repo "$WT") (expected $COMMON_LOCK)"
    92	
    93	# ===========================================================================
    94	# B. Negative control — the OLD 2-branch logic each site carried, replayed
    95	#    verbatim against the SAME worktree fixture. Per #419: observed, not
    96	#    asserted-in-prose. All three must MISS the lock the driver holds.
    97	# ===========================================================================
    98	echo "-- B. negative control: pre-fix 2-branch logic misses the worktree lock --"
    99	
   100	# marathon-ls.sh's original lock_path_for_repo (pre-GH-448):
   101	old_marathon_ls_lock() {
   102	  local repo="$1"
   103	  if [ -d "$repo/.git" ]; then printf '%s/.git/relay-driver.lock' "$repo"
   104	  else printf '%s/.relay-driver.lock' "$repo"; fi
   105	}
   106	
   107	# utils/hq/marathon-live.sh's original driver_lock_path (pre-GH-448):
   108	old_marathon_live_lock() {
   109	  local repo="$1"
   110	  [ -e "$repo/.git/relay-driver.lock" ] && { printf '%s' "$repo/.git/relay-driver.lock"; return 0; }
   111	  [ -e "$repo/.xyz/.relay-driver.lock" ] && { printf '%s' "$repo/.xyz/.relay-driver.lock"; return 0; }
   112	  return 1
   113	}
   114	
   115	mkdir -p "$COMMON_LOCK"; printf '%s\n' "$$" >"$COMMON_LOCK/pid"
   116	
   117	old_ls_path="$(old_marathon_ls_lock "$WT")"
   118	[ "$old_ls_path" != "$COMMON_LOCK" ] && [ ! -e "$old_ls_path" ] \
   119	  && pass "negative control: old marathon-ls.sh logic guesses '$old_ls_path' — misses the held lock" \
   120	  || fail "negative control: old marathon-ls.sh logic unexpectedly found the lock"
   121	
   122	if old_live_path="$(old_marathon_live_lock "$WT")"; then
   123	  fail "negative control: old marathon-live.sh logic unexpectedly found the lock ($old_live_path)"
   124	else
   125	  pass "negative control: old marathon-live.sh logic (checks .git/… or .xyz/… under \$WT) misses the held lock"
   126	fi
   127	
   128	old_fh_found=0
   129	for _lk in "$WT/.git/relay-driver.lock" "$WT/.relay-driver.lock"; do
   130	  [ -d "$_lk" ] && old_fh_found=1
   131	done
   132	[ "$old_fh_found" -eq 0 ] \
   133	  && pass "negative control: old find-harness.sh 2-candidate loop misses the held lock" \
   134	  || fail "negative control: old find-harness.sh 2-candidate loop unexpectedly found the lock"
   135	
   136	rm -rf "$COMMON_LOCK"
   137	
   138	# ===========================================================================
   139	# C. End-to-end, real linked worktree — the ACTUAL (fixed) scripts
   140	# ===========================================================================
   141	echo "-- C. end-to-end: fixed scripts observe LIVE from a linked worktree --"
   142	
   143	mkdir -p "$COMMON_LOCK"; printf '%s\n' "$$" >"$COMMON_LOCK/pid"
   144	
   145	# C1. marathon-ls.sh — registry row pointing at the worktree.
   146	REGISTRY="$WORK/registry.tsv"
   147	printf 'install_dir\tlast_install_utc\ttick_version\tsource_commit\tcoordinated_repo\n' >"$REGISTRY"
   148	printf '%s\t2026-08-08\tv1\tabc\t%s\n' "$WT/.xyz" "$WT" >>"$REGISTRY"
   149	
   150	ls_out="$(XYZ_REGISTRY="$REGISTRY" bash "$LS" 2>/dev/null || true)"
   151	ls_state="$(printf '%s' "$ls_out" | awk -F'\t' -v r="$WT" '$1 == r { print $2 }')"
   152	[ "$ls_state" = "LIVE" ] \
   153	  && pass "marathon-ls.sh: linked worktree with held common-dir lock -> LIVE" \
   154	  || fail "marathon-ls.sh: expected LIVE, got '${ls_state:-<no row>}'"
   155	
   156	# C2. utils/hq/marathon-live.sh — claimed task + the same held lock.
   157	mkdir -p "$WT/.tick" "$WT/bin"
   158	cat >"$WT/bin/tick" <<'EOF'
   159	#!/usr/bin/env bash
   160	exit 0
   161	EOF
   162	chmod +x "$WT/bin/tick"
   163	{
   164	  printf '# Coordination State\n\n## Open\n_(none)_\n\n## Claimed\n'
   165	  printf -- '- MARATHON-GH448-DRIVER-LOCK-TURN by agy\n'
   166	  printf '\n## Done\n_(none)_\n'
   167	} >"$WT/.tick/STATE.md"
   168	
   169	XYZ_REG2="$WORK/xyz.tsv"
   170	printf '%s\t2026-08-08T00:00:00Z\tv1\tabc\t%s\n' "$WT/.xyz" "$WT" >"$XYZ_REG2"
   171	
   172	LIVE_OUT="$WORK/HQ-MARATHON-LIVE-gh448.md"
   173	HQ_PDDA_REGISTRY_DIR="$WORK/empty-pdda" \
   174	HQ_REBALANCE_DB="$WORK/nonexistent.db" \
   175	HQ_XYZ_REGISTRY="$XYZ_REG2" \
   176	HQ_SEARCH_ROOTS="$WORK" \
   177	HQ_MARATHON_LIVE_TODAY="2026-08-08" \
   178	HQ_MARATHON_LIVE_NOW="2026-08-08T12:00:00Z" \
   179	HQ_MARATHON_LIVE_NOW_EPOCH="1000000000" \
   180	bash "$LIVE" --out "$LIVE_OUT" >/dev/null 2>&1
   181	grep -q '🟢 live' "$LIVE_OUT" 2>/dev/null \
   182	  && pass "marathon-live.sh: claimed task + linked-worktree common-dir lock -> 🟢 live" \
   183	  || fail "marathon-live.sh: expected a 🟢 live row: $(grep -E '^\| ' "$LIVE_OUT" 2>/dev/null || echo '(no report)')"
   184	
   185	# C3. find-harness.sh --check — a "harness" fixture whose skill script + lib live in a linked
   186	# worktree, invoked from a separate FOREIGN caller repo so the concurrency-warning gate fires.
   187	HARNESS_MAIN="$WORK/harness-main"
   188	mkdir -p "$HARNESS_MAIN/relay-automation" "$HARNESS_MAIN/skills/relay-xyz"
   189	printf '#!/usr/bin/env bash\n:\n' >"$HARNESS_MAIN/relay-automation/relay-drive.sh"
   190	chmod +x "$HARNESS_MAIN/relay-automation/relay-drive.sh"
   191	cp "$LIB" "$HARNESS_MAIN/relay-automation/driver-lock-lib.sh"
   192	cp "$FH" "$HARNESS_MAIN/skills/relay-xyz/find-harness.sh"
   193	git init -q "$HARNESS_MAIN"
   194	git -C "$HARNESS_MAIN" config user.email t@example.com
   195	git -C "$HARNESS_MAIN" config user.name "gh448 test"
   196	git -C "$HARNESS_MAIN" add -A
   197	git -C "$HARNESS_MAIN" commit -qm seed
   198	HARNESS_WT="$WORK/harness-wt"
   199	git -C "$HARNESS_MAIN" worktree add -q "$HARNESS_WT" -b gh448-harness-wt-branch
   200	
   201	HARNESS_COMMON_LOCK="$HARNESS_MAIN/.git/relay-driver.lock"
   202	mkdir -p "$HARNESS_COMMON_LOCK"; printf '%s\n' "$$" >"$HARNESS_COMMON_LOCK/pid"
   203	
   204	FOREIGN="$WORK/foreign"
   205	mkdir -p "$FOREIGN"
   206	git init -q "$FOREIGN"
   207	
   208	fh_out="$(cd "$FOREIGN" && bash "$HARNESS_WT/skills/relay-xyz/find-harness.sh" --check 2>&1)"
   209	printf '%s' "$fh_out" | grep -q 'a driver lock is currently HELD' \
   210	  && pass "find-harness.sh --check: linked-worktree harness + held common-dir lock -> warns" \
   211	  || fail "find-harness.sh --check: expected a held-lock warning, got: $fh_out"
   212	printf '%s' "$fh_out" | grep -qF "$HARNESS_COMMON_LOCK" \
   213	  && pass "find-harness.sh --check: warning names the REAL (common-dir) lock path" \
   214	  || fail "find-harness.sh --check: warning did not name $HARNESS_COMMON_LOCK: $fh_out"
   215	
   216	# ---------------------------------------------------------------------------
   217	echo "-- syntax check --"
   218	for s in "$LIB" "$LS" "$LIVE" "$FH" "$HERE/gh448-driver-lock-resolver.sh"; do
   219	  bash -n "$s" 2>/dev/null && pass "syntax OK: $(basename "$s")" || fail "syntax error in: $s"
   220	done
   221	
   222	printf '\ngh448-driver-lock-resolver: %d pass, %d fail\n' "$PASS" "$FAIL"
   223	[ "$FAIL" -eq 0 ]
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
     1	#!/usr/bin/env bash
     2	# marathon-ls.sh — cross-repo marathon monitor engine (read-only).
     3	#
     4	# Enumerates every repo known to the xyz registry (hub + col-5 coordinated_repo),
     5	# resolves its relay-driver lock path, derives LIVE/STALE/IDLE/GONE state, finds
     6	# the newest *marathon*.jsonl tick event, and prints one TSV row per repo.
     7	#
     8	# Output columns (tab-separated, header row first):
     9	#   REPO  STATE  PHASE  LAST-TICK  PID  RELAY-FILE
    10	#
    11	# STATE derivation:
    12	#   LIVE  — lock dir present + pid file alive (kill -0 succeeds)
    13	#   STALE — lock dir present + pid dead or missing
    14	#   IDLE  — no lock + newest marathon tick event is phase.approved or marathon.complete
    15	#   GONE  — repo path does not exist on disk
    16	#
    17	# Registry: $XYZ_REGISTRY (default: ${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv)
    18	# Registry format: install_dir<TAB>last_install_utc<TAB>tick_version<TAB>source_commit<TAB>coordinated_repo
    19	#
    20	# This script writes NO state to any monitored repo.
    21	set -euo pipefail
    22	
    23	XYZ_REGISTRY="${XYZ_REGISTRY:-${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv}"
    24	
    25	# Resolve this script's real directory (bash 3.2 / macOS safe — no readlink -f).
    26	_src="${BASH_SOURCE[0]}"
    27	while [ -h "$_src" ]; do
    28	  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
    29	  _src="$(readlink "$_src")"
    30	  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
    31	done
    32	SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
    33	HUB_REPO="$(cd "$SELF_DIR/.." && pwd)"
    34	
    35	# shellcheck source=relay-automation/driver-lock-lib.sh
    36	. "$SELF_DIR/driver-lock-lib.sh"
    37	
    38	# ---------------------------------------------------------------------------
    39	# helpers
    40	# ---------------------------------------------------------------------------
    41	
    42	trim_cr() { printf '%s' "${1%$'\r'}"; }
    43	
    44	# Resolve the relay-driver lock path for a given repo root — delegates to the shared resolver
    45	# (GH-448: this used to guess 2 branches inline and missed the linked-worktree case, where .git is a
    46	# FILE and the driver's real lock lives at the git common dir, not <repo>/.git/relay-driver.lock).
    47	lock_path_for_repo() {
    48	  driver_lock_path_for_repo "$1"
    49	}
    50	
    51	# Find the newest *marathon*.jsonl file under <repo>/.tick/events/.
    52	newest_marathon_jsonl() {
    53	  local repo="$1"
    54	  local events_dir="$repo/.tick/events"
    55	  [ -d "$events_dir" ] || return 0
    56	  # Use ls -t (newest first) rather than `find -newer` for bash 3.2 compat.
    57	  # Glob for files matching *marathon*.jsonl; pick the first (newest by mtime).
    58	  local f
    59	  # shellcheck disable=SC2012
    60	  f="$(ls -t "$events_dir"/*marathon*.jsonl 2>/dev/null | head -1 || true)"
    61	  printf '%s' "$f"
    62	}
    63	
    64	# Extract the last event line from a jsonl file and return phase type + timestamp.
    65	# Outputs: TYPE<TAB>TIMESTAMP  (or empty strings when not parseable).
    66	last_event_fields() {
    67	  local jsonl="$1"
    68	  [ -f "$jsonl" ] || { printf '\t'; return 0; }
    69	  local last_line type ts
    70	  last_line="$(tail -1 "$jsonl" 2>/dev/null || true)"
    71	  [ -n "$last_line" ] || { printf '\t'; return 0; }
    72	  # Parse with sed: no jq dependency requirement.
    73	  type="$(printf '%s' "$last_line" | sed 's/.*"type"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' 2>/dev/null || true)"
    74	  ts="$(printf '%s' "$last_line" | sed 's/.*"ts"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' 2>/dev/null || true)"
    75	  # If sed didn't actually find a match it returns the whole string unchanged; detect that.
    76	  [ "$type" = "$last_line" ] && type=""
    77	  [ "$ts" = "$last_line" ] && ts=""
    78	  printf '%s\t%s' "${type:-}" "${ts:-}"
    79	}
    80	
    81	# Determine the STATE for a repo given its lock dir path.
    82	# Sets globals: _STATE _PID
    83	resolve_state() {
    84	  local lock="$1"
    85	  _STATE="IDLE"
    86	  _PID="-"
    87	
    88	  if [ -d "$lock" ]; then
    89	    local pid_file="$lock/pid"
    90	    local pid=""
    91	    [ -f "$pid_file" ] && pid="$(cat "$pid_file" 2>/dev/null || true)"
    92	    pid="$(trim_cr "${pid:-}")"
    93	    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    94	      _STATE="LIVE"
    95	      _PID="$pid"
    96	    else
    97	      _STATE="STALE"
    98	      _PID="${pid:--}"
    99	    fi
   100	    return 0
   101	  fi
   102	
   103	  # No lock — state is IDLE (no lock present).
   104	  _STATE="IDLE"
   105	  _PID="-"
   106	}
   107	
   108	# Find the newest <phase-dir>/*/RELAY.md path for a repo (used in RELAY-FILE column).
   109	#
   110	# GH-484: reads BOTH the current default (marathon-system/) and the historical one (phases/), and
   111	# picks whichever holds the newer file — not a straight swap. Two populations need to stay visible
   112	# at once: this repo's ~72 committed pre-flip runs (deliberately not migrated), and fleet repos
   113	# whose vendored .xyz/ has not re-synced yet and so is still writing to phases/. Checking only the
   114	# new name would make the monitor silently report nothing for either.
   115	newest_relay_file() {
   116	  local repo="$1" d f newest=""
   117	  for d in "$repo/marathon-system" "$repo/phases"; do
   118	    [ -d "$d" ] || continue
   119	    # shellcheck disable=SC2012
   120	    f="$(ls -t "$d"/*/RELAY.md 2>/dev/null | head -1 || true)"
   121	    [ -n "$f" ] || continue
   122	    if [ -z "$newest" ] || [ "$f" -nt "$newest" ]; then newest="$f"; fi
   123	  done
   124	  printf '%s' "${newest:--}"
   125	}
   126	
   127	# ---------------------------------------------------------------------------
   128	# print one row per repo
   129	# ---------------------------------------------------------------------------
   130	
   131	print_row() {
   132	  local repo="$1"
   133	  local repo_abs
   134	
   135	  # Canonicalize path (no readlink -f on macOS bash 3.2).
   136	  if [ -d "$repo" ]; then
   137	    repo_abs="$(cd "$repo" && pwd)"
   138	  else
   139	    repo_abs="$repo"
   140	  fi
   141	
   142	  # GONE: repo does not exist on disk.
   143	  if [ ! -d "$repo_abs" ]; then
   144	    printf '%s\tGONE\t-\t-\t-\t-\n' "$repo_abs"
   145	    return 0
   146	  fi
   147	
   148	  local lock
   149	  lock="$(lock_path_for_repo "$repo_abs")"
   150	
   151	  resolve_state "$lock"
   152	  local state="$_STATE" pid="$_PID"
   153	
   154	  local marathon_jsonl phase ts relay_file
   155	  marathon_jsonl="$(newest_marathon_jsonl "$repo_abs")"
   156	  if [ -n "$marathon_jsonl" ]; then
   157	    local fields
   158	    fields="$(last_event_fields "$marathon_jsonl")"
   159	    phase="$(printf '%s' "$fields" | cut -f1)"
   160	    ts="$(printf '%s' "$fields" | cut -f2)"
   161	  else
   162	    phase="-"
   163	    ts="-"
   164	  fi
   165	  [ -n "$phase" ] || phase="-"
   166	  [ -n "$ts" ]    || ts="-"
   167	
   168	  relay_file="$(newest_relay_file "$repo_abs")"
   169	
   170	  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
   171	    "$repo_abs" "$state" "$phase" "$ts" "$pid" "$relay_file"
   172	}
   173	
   174	# ---------------------------------------------------------------------------
   175	# collect repos: hub + registry col-5
   176	# ---------------------------------------------------------------------------
   177	
   178	printf 'REPO\tSTATE\tPHASE\tLAST-TICK\tPID\tRELAY-FILE\n'
   179	
   180	# Hub repo always first.
   181	print_row "$HUB_REPO"
   182	
   183	# Registry — col 5 (coordinated_repo), skip header + comment lines.
   184	if [ -f "$XYZ_REGISTRY" ]; then
   185	  while IFS=$'\t' read -r install_dir _last_utc _tick_ver _source_commit coordinated_repo _extra; do
   186	    install_dir="$(trim_cr "${install_dir:-}")"
   187	    coordinated_repo="$(trim_cr "${coordinated_repo:-}")"
   188	    [ -n "$install_dir" ] || continue
   189	    case "$install_dir" in \#*) continue ;; esac
   190	    [ "$install_dir" = "install_dir" ] && continue   # skip the TSV header row
   191	    [ -n "$coordinated_repo" ] || continue
   192	    # Skip duplicates (if coordinated_repo == hub repo).
   193	    local_abs=""
   194	    if [ -d "$coordinated_repo" ]; then
   195	      local_abs="$(cd "$coordinated_repo" && pwd)"
   196	    fi
   197	    [ "$local_abs" = "$HUB_REPO" ] && continue
   198	    print_row "$coordinated_repo"
   199	  done < "$XYZ_REGISTRY"
   200	fi
     1	#!/usr/bin/env bash
     2	#
     3	# find-harness.sh — device-agnostic locator for the xyz-3-agents-swarm relay harness.
     4	#
     5	# Prints the absolute path to the repo root that ships relay-automation/ (the relay
     6	# harness: relay-drive.sh, the turn shims, poll.sh, bin/tick). It resolves WITHOUT any
     7	# hardcoded machine path, so /relay-xyz works from any working directory — including a
     8	# clone of a *different* repo — because this script ships INSIDE the harness repo
     9	# (skills/relay-xyz/find-harness.sh) and resolves relative to its own real location,
    10	# following symlinks (the skill is usually symlinked into ~/.claude/skills/relay-xyz).
    11	#
    12	# Usage:
    13	#   find-harness.sh            # print the harness root, or error to stderr (exit 1)
    14	#   find-harness.sh --root     # same as default
    15	#   find-harness.sh --env      # print shell `export …` lines, safe to eval
    16	#   find-harness.sh --check    # human-readable readiness checklist
    17	#
    18	# Resolution order (first hit wins):
    19	#   1. $XYZ_HARNESS / $XYZ_REPO_ROOT          — explicit override
    20	#   2. <caller-root>/.xyz                     — vendored local copy in the repo you're standing in
    21	#   3. <main-checkout>/.xyz                   — vendored copy visible from a linked worktree
    22	#   4. the current git repo root              — you're already standing in a harness clone
    23	#   5. this script's own real location        — …/<repo>/skills/relay-xyz → <repo>
    24	#
    25	# bash 3.2-safe (macOS default): no `readlink -f`, no associative arrays.
    26	set -u
    27	
    28	_has_harness() { [ -n "${1:-}" ] && [ -x "$1/relay-automation/relay-drive.sh" ]; }
    29	_has_vendored_harness() { _has_harness "${1:-}" && [ -f "$1/bin/tick" ]; }
    30	_canon_dir() { [ -n "${1:-}" ] && (cd "$1" >/dev/null 2>&1 && pwd); }
    31	_short_sha() { printf '%.12s' "${1:-unknown}"; }
    32	_read_source_commit() {
    33	  [ -f "${1:-}/VERSION" ] || return 1
    34	  while IFS='=' read -r _k _v; do
    35	    [ "$_k" = "source_commit" ] || continue
    36	    [ -n "$_v" ] || return 1
    37	    printf '%s\n' "$_v"
    38	    return 0
    39	  done < "${1}/VERSION"
    40	  return 1
    41	}
    42	_find_case_collision_pair() {
    43	  [ -n "${1:-}" ] || return 0
    44	  [ "$(git -C "$1" config --get core.ignorecase 2>/dev/null || true)" = "true" ] || return 0
    45	  git -C "$1" ls-files 2>/dev/null | awk '
    46	    {
    47	      count = split($0, parts, "/")
    48	      exact = ""
    49	      lower = ""
    50	      for (i = 1; i <= count; i++) {
    51	        exact = exact (i > 1 ? "/" : "") parts[i]
    52	        lower = lower (i > 1 ? "/" : "") tolower(parts[i])
    53	        if ((lower in seen_exact) && seen_exact[lower] != exact) {
    54	          print seen_path[lower] "\t" $0
    55	          exit 0
    56	        }
    57	        if (!(lower in seen_exact)) {
    58	          seen_exact[lower] = exact
    59	          seen_path[lower] = $0
    60	        }
    61	      }
    62	    }
    63	  '
    64	}
    65	
    66	# --- resolve this script's real directory (symlink-safe) ---
    67	_src="${BASH_SOURCE[0]}"
    68	while [ -h "$_src" ]; do
    69	  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
    70	  _src="$(readlink "$_src")"
    71	  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
    72	done
    73	SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
    74	
    75	# shellcheck source=relay-automation/driver-lock-lib.sh
    76	. "$SELF_DIR/../../relay-automation/driver-lock-lib.sh"
    77	
    78	HARNESS=""
    79	VENDORED=0
    80	CALLER_ROOT=""
    81	VENDORED_COMMIT=""
    82	LIVE_HARNESS=""
    83	LIVE_HARNESS_HEAD=""
    84	VENDORED_STATUS=""
    85	MAIN_CHECKOUT_VENDORED=""
    86	# 1. explicit override
    87	for _o in "${XYZ_HARNESS:-}" "${XYZ_REPO_ROOT:-}"; do
    88	  if _has_harness "$_o"; then HARNESS="$(cd "$_o" && pwd)"; break; fi
    89	done
    90	# 2. vendored .xyz/ copy in the repo/PWD I'm standing in
    91	if [ -z "$HARNESS" ]; then
    92	  _g="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    93	  CALLER_ROOT="$_g"
    94	  [ -n "$CALLER_ROOT" ] || CALLER_ROOT="${PWD:-$(pwd)}"
    95	  _vendored="$CALLER_ROOT/.xyz"
    96	  if _has_vendored_harness "$_vendored"; then
    97	    HARNESS="$(cd "$_vendored" && pwd)"
    98	    VENDORED=1
    99	  fi
   100	fi
   101	# 3. vendored .xyz/ copy in the main checkout, when the caller is a linked
   102	# worktree. Gitignored vendor files exist only in that main checkout.
   103	if [ -z "$HARNESS" ] && [ -n "$_g" ] && [ "$(git rev-parse --is-bare-repository 2>/dev/null || true)" != "true" ]; then
   104	  _common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
   105	  if [ -n "$_common_dir" ] && [ -d "$_common_dir" ]; then
   106	    _main_root="$(dirname "$_common_dir")"
   107	    _main_vendored="$_main_root/.xyz"
   108	    if [ -d "$_main_vendored" ]; then
   109	      MAIN_CHECKOUT_VENDORED="$(_canon_dir "$_main_vendored" || true)"
   110	      if _has_vendored_harness "$MAIN_CHECKOUT_VENDORED"; then
   111	        HARNESS="$MAIN_CHECKOUT_VENDORED"
   112	        VENDORED=1
   113	      fi
   114	    fi
   115	  fi
   116	fi
   117	# 4. current git repo (preserves "operate on the clone I'm standing in")
   118	if [ -z "$HARNESS" ]; then
   119	  if _has_harness "$_g"; then HARNESS="$_g"; fi
   120	fi
   121	# 5. relative to this script (…/<repo>/skills/relay-xyz → <repo>) — fixes the
   122	#    cross-repo case: the skill is global but the harness ships beside it.
   123	if [ -z "$HARNESS" ]; then
   124	  _cand="$(cd "$SELF_DIR/../.." >/dev/null 2>&1 && pwd || true)"
   125	  if _has_harness "$_cand"; then HARNESS="$_cand"; fi
   126	fi
   127	
   128	if [ -z "$HARNESS" ]; then
   129	  echo "find-harness: relay-automation/ harness not found." >&2
   130	  echo "  Set XYZ_HARNESS=/path/to/your/xyz-3-agents-swarm clone and retry." >&2
   131	  exit 1
   132	fi
   133	
   134	# TICK_REPO_ROOT is the repo root that bin/tick and tick-consuming shims expect.
   135	# When a vendored .xyz/ copy is in play, $HARNESS is $CALLER_ROOT/.xyz — one
   136	# directory too deep — so use the already-resolved caller root instead.
   137	TICK_REPO_ROOT="$HARNESS"
   138	[ "$VENDORED" = 1 ] && TICK_REPO_ROOT="$CALLER_ROOT"
   139	
   140	# Vendored copies are opt-in fallbacks: warn on reachable drift, never block.
   141	if [ "$VENDORED" = 1 ]; then
   142	  for _o in "${XYZ_HARNESS:-}" "${XYZ_REPO_ROOT:-}"; do
   143	    if _has_harness "$_o"; then
   144	      _live="$(_canon_dir "$_o" || true)"
   145	      if [ -n "$_live" ] && [ "$_live" != "$HARNESS" ]; then
   146	        LIVE_HARNESS="$_live"
   147	        break
   148	      fi
   149	    fi
   150	  done
   151	  if [ -z "$LIVE_HARNESS" ]; then
   152	    _cand="$(_canon_dir "$SELF_DIR/../.." || true)"
   153	    if _has_harness "$_cand" && [ "$_cand" != "$HARNESS" ]; then
   154	      LIVE_HARNESS="$_cand"
   155	    fi
   156	  fi
   157	
   158	  if [ -n "$LIVE_HARNESS" ]; then
   159	    VENDORED_COMMIT="$(_read_source_commit "$HARNESS" || true)"
   160	    LIVE_HARNESS_HEAD="$(git -C "$LIVE_HARNESS" rev-parse HEAD 2>/dev/null || true)"
   161	    if [ -n "$VENDORED_COMMIT" ] && [ -n "$LIVE_HARNESS_HEAD" ]; then
   162	      if [ "$VENDORED_COMMIT" = "$LIVE_HARNESS_HEAD" ]; then
   163	        VENDORED_STATUS="current"
   164	      elif git -C "$LIVE_HARNESS" merge-base --is-ancestor "$VENDORED_COMMIT" HEAD >/dev/null 2>&1; then
   165	        VENDORED_STATUS="behind"
   166	        {
   167	          echo "find-harness: WARNING — vendored .xyz harness is behind the live harness."
   168	          echo "  vendored: $(_short_sha "$VENDORED_COMMIT")"
   169	          echo "  live:     $(_short_sha "$LIVE_HARNESS_HEAD")"
   170	          echo "  remedy:   xyz-sync --update $CALLER_ROOT"
   171	        } >&2
   172	      else
   173	        VENDORED_STATUS="different"
   174	      fi
   175	    else
   176	      VENDORED_STATUS="different"
   177	    fi
   178	
   179	    if [ "$VENDORED_STATUS" = "different" ]; then
   180	      echo "find-harness: vendored copy differs from or can't be compared to the live harness." >&2
   181	    fi
   182	  else
   183	    VENDORED_STATUS="standalone"
   184	  fi
   185	fi
   186	
   187	# --- capability probes (read-only; safe under any sandbox) ---
   188	TICK="$HARNESS/bin/tick"; [ -x "$TICK" ] || TICK=""
   189	_bin() { command -v "${1:-}" 2>/dev/null || true; }
   190	CODEX_PATH="$(_bin "${CODEX_BIN:-codex}")"
   191	AGY_PATH="$(_bin "${AGY_BIN:-agy}")"
   192	# Antigravity installs agy at ~/.local/bin/agy on macOS by default (not on system PATH).
   193	# Fall back to that well-known location when neither AGY_BIN nor PATH resolves it.
   194	if [ -z "$AGY_PATH" ] && [ -z "${AGY_BIN:-}" ] && [ -x "$HOME/.local/bin/agy" ]; then
   195	  AGY_PATH="$HOME/.local/bin/agy"
   196	fi
   197	_flag() { [ -n "${1:-}" ] && echo 1 || echo 0; }
   198	
   199	case "${1:-}" in
   200	  ""|--root)
   201	    printf '%s\n' "$HARNESS"
   202	    ;;
   203	  --env)
   204	    printf 'export HARNESS=%q\n'         "$HARNESS"
   205	    printf 'export TICK_REPO_ROOT=%q\n'  "$TICK_REPO_ROOT"
   206	    [ -n "$TICK" ]       && printf 'export TICK=%q\n'       "$TICK"
   207	    [ -n "$CODEX_PATH" ] && printf 'export CODEX_BIN=%q\n'  "$CODEX_PATH"
   208	    [ -n "$AGY_PATH" ]   && printf 'export AGY_BIN=%q\n'    "$AGY_PATH"
   209	    printf 'export RELAY_HAS_TICK=%s\n'  "$(_flag "$TICK")"
   210	    printf 'export RELAY_HAS_CODEX=%s\n' "$(_flag "$CODEX_PATH")"
   211	    printf 'export RELAY_HAS_AGY=%s\n'   "$(_flag "$AGY_PATH")"
   212	    ;;
   213	  --check)
   214	    mark() { if [ -n "${1:-}" ]; then echo "  ok  $2  ($1)"; else echo "  --  $2  (not found)"; fi; }
   215	    _caller="$(git rev-parse --show-toplevel 2>/dev/null || true)"
   216	    echo "relay harness readiness:"
   217	    echo "  ok  harness  ($HARNESS)"
   218	    if [ "$VENDORED" = 1 ]; then
   219	      echo "  ok  vendored resolution  ($HARNESS)"
   220	      case "$VENDORED_STATUS" in
   221	        current)
   222	          echo "  ok  vendored copy is current with the live harness ($(_short_sha "$VENDORED_COMMIT") = $(_short_sha "$LIVE_HARNESS_HEAD"))"
   223	          ;;
   224	        behind)
   225	          echo "  !   vendored copy is behind the live harness ($(_short_sha "$VENDORED_COMMIT") < $(_short_sha "$LIVE_HARNESS_HEAD")); run: xyz-sync --update $CALLER_ROOT"
   226	          ;;
   227	        different)
   228	          echo "  !   vendored copy differs from or can't be compared to the live harness"
   229	          ;;
   230	        standalone)
   231	          echo "  ok  no reachable live harness to compare; using vendored copy"
   232	          ;;
   233	      esac
   234	    fi
   235	    mark "$TICK"       "tick CLI"
   236	    mark "$CODEX_PATH" "codex CLI (Path A worker)"
   237	    mark "$AGY_PATH"   "agy CLI   (Path A worker)"
   238	    if [ -z "$CODEX_PATH" ] && [ -z "$AGY_PATH" ]; then
   239	      echo "  !   no cross-model headless worker on PATH — only Path B (all-Claude poll) is available"
   240	    fi
   241	    # GH-70: concurrency-readiness. When a FOREIGN repo (not the harness clone) has no local .xyz/, it
   242	    # resolves to the CENTRALIZED harness, whose single global driver lock serializes ALL relays run
   243	    # through it — so it cannot run a relay concurrently with another repo pointed at the same harness.
   244	    # Advise vendoring for per-repo lock isolation. Fail-open: this only prints; --check still exits 0.
   245	    if [ "$VENDORED" = 0 ]; then
   246	      if [ -n "$_caller" ] && [ "$(_canon_dir "$_caller")" != "$HARNESS" ]; then
   247	        if [ -n "$MAIN_CHECKOUT_VENDORED" ]; then
   248	          echo "  !   concurrency: vendored .xyz found in the main checkout at $MAIN_CHECKOUT_VENDORED, but it is not"
   249	          echo "      a usable harness here; relays fall back to the CENTRALIZED harness and"
   250	        else
   251	          echo "  !   concurrency: no local .xyz/ in this repo — relays here use the CENTRALIZED harness and"
   252	        fi
   253	        echo "      share ONE global driver lock (can't run concurrently with another repo's relay). For"
   254	        echo "      per-repo isolation / concurrent relays, vendor this repo:"
   255	        echo "        relay-automation/xyz-vendor.sh vendor $_caller"
   256	        # GH-448: resolve via the shared resolver, not a 2-candidate guess — when $HARNESS itself is a
   257	        # linked worktree (.git is a FILE), the driver's real lock lives at the git common dir, which
   258	        # neither hardcoded candidate above matched, so this warning silently never fired.
   259	        _lk="$(driver_lock_path_for_repo "$HARNESS")"
   260	        [ -d "$_lk" ] && echo "  !   a driver lock is currently HELD ($_lk) — a relay started here will BLOCK until it frees"
   261	      fi
   262	    fi
   263	    _collision="$(_find_case_collision_pair "${_caller:-}" || true)"
   264	    if [ -n "$_collision" ]; then
   265	      _path_a="${_collision%%$'\t'*}"
   266	      _path_b="${_collision#*$'\t'}"
   267	      echo "  !   case-collision: tracked paths '$_path_a' and '$_path_b' differ only by case in this repo"
   268	      echo "      and only one casing can exist as a real directory tree on this filesystem. A headless"
   269	      echo "      relay turn can misread git status here and revert a legitimate edit (exit 6). Remedy:"
   270	      echo "      git mv one variant to match the other's casing, commit, then re-run --check."
   271	    fi
   272	    true   # --check is advisory: always exit 0 (fail-open), never block a relay on a warning
   273	    ;;
   274	  *)
   275	    echo "usage: find-harness.sh [--root|--env|--check]" >&2
   276	    exit 2
   277	    ;;
   278	esac

exec
/bin/zsh -lc "rg -n -C 10 '"'^def driver_lock_path|driver_lock_path'"\\(' utils/py/rtl.py utils/py/marathon_drive.py utils/py/relay_drive.py relay-automation/marathon-drive.sh relay-automation/relay-drive.sh && nl -ba test/gh448-driver-lock-resolver.sh | sed -n '1,260p' && nl -ba relay-automation/marathon-ls.sh | sed -n '1,230p' && nl -ba utils/hq/marathon-live.sh | sed -n '1,145p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua
 succeeded in 0ms:
utils/py/marathon_drive.py-601-
utils/py/marathon_drive.py-602-    if get_env("RELAY_DRIVER_LOCKED", "0") != "1":
utils/py/marathon_drive.py-603-        # GH-49b/GH-207: the lock lives in .git/ (never committed) for a normal clone. In a linked
utils/py/marathon_drive.py-604-        # worktree .git is a FILE pointing at the shared gitdir, so resolve the real common dir and put
utils/py/marathon_drive.py-605-        # the lock there — otherwise --require-clean sees the driver's own lock as untracked dirt inside
utils/py/marathon_drive.py-606-        # the worktree. A vendored .xyz/ copy (no .git) falls back to a hidden lock beside the scripts.
utils/py/marathon_drive.py-607-        # GH-448: this resolution is the canonical write-side one — every read-only consumer (marathon-
utils/py/marathon_drive.py-608-        # ls.sh, marathon-live.sh, find-harness.sh) must agree with it, so it lives in rtl.py's shared
utils/py/marathon_drive.py-609-        # driver_lock_path (with a byte-for-byte Bash twin in relay-automation/driver-lock-lib.sh)
utils/py/marathon_drive.py-610-        # rather than being reimplemented here.
utils/py/marathon_drive.py:611:        lock_dir, lock_label = driver_lock_path(root)
utils/py/marathon_drive.py-612-
utils/py/marathon_drive.py-613-        try:
utils/py/marathon_drive.py-614-            os.mkdir(lock_dir)
utils/py/marathon_drive.py-615-        except OSError:
utils/py/marathon_drive.py-616-            holder = ""
utils/py/marathon_drive.py-617-            pid_file = os.path.join(lock_dir, "pid")
utils/py/marathon_drive.py-618-            if os.path.isfile(pid_file):
utils/py/marathon_drive.py-619-                try:
utils/py/marathon_drive.py-620-                    with open(pid_file, 'r') as f: holder = f.read().strip()
utils/py/marathon_drive.py-621-                except: pass
--
utils/py/rtl.py-467-                if "TICK_REPO_ROOT=" in line or "file://" in line or "](" in line:
utils/py/rtl.py-468-                    continue
utils/py/rtl.py-469-                if root in line:
utils/py/rtl.py-470-                    count += 1
utils/py/rtl.py-471-                    if first is None:
utils/py/rtl.py-472-                        first = line.strip()
utils/py/rtl.py-473-    except OSError:
utils/py/rtl.py-474-        return 0, None
utils/py/rtl.py-475-    return count, first
utils/py/rtl.py-476-
utils/py/rtl.py:477:def driver_lock_path(root):
utils/py/rtl.py-478-    # GH-448: the ONE shared resolver for the relay-driver lock path, matching the DRIVER's own
utils/py/rtl.py-479-    # write-side resolution (marathon_drive.py / marathon-drive.sh, relay_drive.py / relay-drive.sh) —
utils/py/rtl.py-480-    # every read-only consumer (marathon-ls.sh, marathon-live.sh, find-harness.sh) must resolve the
utils/py/rtl.py-481-    # SAME path or it probes a location the driver never writes and reports a live run as idle.
utils/py/rtl.py-482-    #   .git is a directory  -> <root>/.git/relay-driver.lock                (normal clone)
utils/py/rtl.py-483-    #   .git is a file       -> <git-common-dir>/relay-driver.lock           (linked worktree)
utils/py/rtl.py-484-    #   no .git (vendored)   -> <root>/.relay-driver.lock                    (vendored .xyz/ copy)
utils/py/rtl.py-485-    # Returns (lock_path, lock_label) — lock_label is always the SHORT display form used in messages.
utils/py/rtl.py-486-    git_path = os.path.join(root, ".git")
utils/py/rtl.py-487-    if os.path.isdir(git_path):
     1	#!/usr/bin/env bash
     2	# test/gh448-driver-lock-resolver.sh — GH-448: the shared driver-lock resolver.
     3	#
     4	# marathon-drive writes its lock to the git COMMON dir when .git is a FILE (a linked worktree). Every
     5	# read-only consumer used to guess the path with its OWN 2-branch inline logic (dir vs "everything
     6	# else"), which is wrong for the worktree case — so a LIVE marathon reported as IDLE. This test:
     7	#
     8	#   A. Parity — the Bash resolver (relay-automation/driver-lock-lib.sh) and the Python resolver
     9	#      (utils/py/rtl.py's driver_lock_path) agree byte-for-byte on all three branches: .git dir,
    10	#      .git file (real linked worktree), and no .git (vendored).
    11	#   B. Negative control (per #419) — the OLD 2-branch logic each consumer carried pre-fix, replayed
    12	#      verbatim against the SAME linked-worktree fixture, observably misses the lock the driver holds.
    13	#   C. End-to-end, real linked worktree — marathon-ls.sh, utils/hq/marathon-live.sh, and
    14	#      skills/relay-xyz/find-harness.sh --check, run for real against a `git worktree add` fixture
    15	#      with the lock held at the driver's real (common-dir) path, all observe it correctly.
    16	set -uo pipefail
    17	
    18	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    19	ROOT="$(cd "$HERE/.." && pwd)"
    20	LIB="$ROOT/relay-automation/driver-lock-lib.sh"
    21	LS="$ROOT/relay-automation/marathon-ls.sh"
    22	LIVE="$ROOT/utils/hq/marathon-live.sh"
    23	FH="$ROOT/skills/relay-xyz/find-harness.sh"
    24	
    25	# shellcheck source=relay-automation/driver-lock-lib.sh
    26	. "$LIB"
    27	
    28	WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh448-driver-lock.XXXXXX")"
    29	trap 'rm -rf "$WORK"' EXIT
    30	
    31	PASS=0; FAIL=0
    32	pass() { printf '  PASS: %s\n' "$*"; PASS=$((PASS+1)); }
    33	fail() { printf '  FAIL: %s\n' "$*" >&2; FAIL=$((FAIL+1)); }
    34	
    35	echo "== test: gh448-driver-lock-resolver =="
    36	echo "  workdir: $WORK"
    37	
    38	py_resolve() {  # <repo> -> prints the python resolver's lock path
    39	  python3 -c '
    40	import sys
    41	sys.path.insert(0, sys.argv[2])
    42	from rtl import driver_lock_path
    43	print(driver_lock_path(sys.argv[1])[0], end="")
    44	' "$1" "$ROOT/utils/py"
    45	}
    46	
    47	# ---------------------------------------------------------------------------
    48	# Fixtures
    49	# ---------------------------------------------------------------------------
    50	
    51	# (1) Normal clone: .git is a directory.
    52	DIR_REPO="$WORK/dir-repo"
    53	mkdir -p "$DIR_REPO/.git"
    54	
    55	# (2) Vendored: no .git at all.
    56	ABSENT_REPO="$WORK/absent-repo"
    57	mkdir -p "$ABSENT_REPO"
    58	
    59	# (3) Real linked worktree: .git is a FILE pointing at the shared gitdir.
    60	MAIN_REPO="$WORK/main-repo"
    61	mkdir -p "$MAIN_REPO"
    62	git init -q "$MAIN_REPO"
    63	git -C "$MAIN_REPO" config user.email t@example.com
    64	git -C "$MAIN_REPO" config user.name "gh448 test"
    65	printf 'seed\n' >"$MAIN_REPO/seed.txt"
    66	git -C "$MAIN_REPO" add seed.txt
    67	git -C "$MAIN_REPO" commit -qm seed
    68	WT="$WORK/wt"
    69	git -C "$MAIN_REPO" worktree add -q "$WT" -b gh448-wt-branch
    70	[ -f "$WT/.git" ] && pass "fixture: linked worktree's .git is a FILE (not a dir)" \
    71	  || fail "fixture setup: expected $WT/.git to be a file"
    72	
    73	COMMON_LOCK="$MAIN_REPO/.git/relay-driver.lock"
    74	
    75	# ===========================================================================
    76	# A. Parity — Bash resolver vs Python resolver, all three branches
    77	# ===========================================================================
    78	echo "-- A. resolver parity (bash vs python) --"
    79	
    80	for case_name_repo in "dir:$DIR_REPO" "absent:$ABSENT_REPO" "worktree:$WT"; do
    81	  name="${case_name_repo%%:*}"; repo="${case_name_repo#*:}"
    82	  bash_out="$(driver_lock_path_for_repo "$repo")"
    83	  py_out="$(py_resolve "$repo")"
    84	  [ "$bash_out" = "$py_out" ] \
    85	    && pass "parity ($name): bash and python agree ($bash_out)" \
    86	    || fail "parity ($name): bash='$bash_out' python='$py_out'"
    87	done
    88	
    89	[ "$(driver_lock_path_for_repo "$WT")" = "$COMMON_LOCK" ] \
    90	  && pass "worktree case resolves to the git COMMON dir, not <worktree>/.git/…" \
    91	  || fail "worktree case resolved wrong: $(driver_lock_path_for_repo "$WT") (expected $COMMON_LOCK)"
    92	
    93	# ===========================================================================
    94	# B. Negative control — the OLD 2-branch logic each site carried, replayed
    95	#    verbatim against the SAME worktree fixture. Per #419: observed, not
    96	#    asserted-in-prose. All three must MISS the lock the driver holds.
    97	# ===========================================================================
    98	echo "-- B. negative control: pre-fix 2-branch logic misses the worktree lock --"
    99	
   100	# marathon-ls.sh's original lock_path_for_repo (pre-GH-448):
   101	old_marathon_ls_lock() {
   102	  local repo="$1"
   103	  if [ -d "$repo/.git" ]; then printf '%s/.git/relay-driver.lock' "$repo"
   104	  else printf '%s/.relay-driver.lock' "$repo"; fi
   105	}
   106	
   107	# utils/hq/marathon-live.sh's original driver_lock_path (pre-GH-448):
   108	old_marathon_live_lock() {
   109	  local repo="$1"
   110	  [ -e "$repo/.git/relay-driver.lock" ] && { printf '%s' "$repo/.git/relay-driver.lock"; return 0; }
   111	  [ -e "$repo/.xyz/.relay-driver.lock" ] && { printf '%s' "$repo/.xyz/.relay-driver.lock"; return 0; }
   112	  return 1
   113	}
   114	
   115	mkdir -p "$COMMON_LOCK"; printf '%s\n' "$$" >"$COMMON_LOCK/pid"
   116	
   117	old_ls_path="$(old_marathon_ls_lock "$WT")"
   118	[ "$old_ls_path" != "$COMMON_LOCK" ] && [ ! -e "$old_ls_path" ] \
   119	  && pass "negative control: old marathon-ls.sh logic guesses '$old_ls_path' — misses the held lock" \
   120	  || fail "negative control: old marathon-ls.sh logic unexpectedly found the lock"
   121	
   122	if old_live_path="$(old_marathon_live_lock "$WT")"; then
   123	  fail "negative control: old marathon-live.sh logic unexpectedly found the lock ($old_live_path)"
   124	else
   125	  pass "negative control: old marathon-live.sh logic (checks .git/… or .xyz/… under \$WT) misses the held lock"
   126	fi
   127	
   128	old_fh_found=0
   129	for _lk in "$WT/.git/relay-driver.lock" "$WT/.relay-driver.lock"; do
   130	  [ -d "$_lk" ] && old_fh_found=1
   131	done
   132	[ "$old_fh_found" -eq 0 ] \
   133	  && pass "negative control: old find-harness.sh 2-candidate loop misses the held lock" \
   134	  || fail "negative control: old find-harness.sh 2-candidate loop unexpectedly found the lock"
   135	
   136	rm -rf "$COMMON_LOCK"
   137	
   138	# ===========================================================================
   139	# C. End-to-end, real linked worktree — the ACTUAL (fixed) scripts
   140	# ===========================================================================
   141	echo "-- C. end-to-end: fixed scripts observe LIVE from a linked worktree --"
   142	
   143	mkdir -p "$COMMON_LOCK"; printf '%s\n' "$$" >"$COMMON_LOCK/pid"
   144	
   145	# C1. marathon-ls.sh — registry row pointing at the worktree.
   146	REGISTRY="$WORK/registry.tsv"
   147	printf 'install_dir\tlast_install_utc\ttick_version\tsource_commit\tcoordinated_repo\n' >"$REGISTRY"
   148	printf '%s\t2026-08-08\tv1\tabc\t%s\n' "$WT/.xyz" "$WT" >>"$REGISTRY"
   149	
   150	ls_out="$(XYZ_REGISTRY="$REGISTRY" bash "$LS" 2>/dev/null || true)"
   151	ls_state="$(printf '%s' "$ls_out" | awk -F'\t' -v r="$WT" '$1 == r { print $2 }')"
   152	[ "$ls_state" = "LIVE" ] \
   153	  && pass "marathon-ls.sh: linked worktree with held common-dir lock -> LIVE" \
   154	  || fail "marathon-ls.sh: expected LIVE, got '${ls_state:-<no row>}'"
   155	
   156	# C2. utils/hq/marathon-live.sh — claimed task + the same held lock.
   157	mkdir -p "$WT/.tick" "$WT/bin"
   158	cat >"$WT/bin/tick" <<'EOF'
   159	#!/usr/bin/env bash
   160	exit 0
   161	EOF
   162	chmod +x "$WT/bin/tick"
   163	{
   164	  printf '# Coordination State\n\n## Open\n_(none)_\n\n## Claimed\n'
   165	  printf -- '- MARATHON-GH448-DRIVER-LOCK-TURN by agy\n'
   166	  printf '\n## Done\n_(none)_\n'
   167	} >"$WT/.tick/STATE.md"
   168	
   169	XYZ_REG2="$WORK/xyz.tsv"
   170	printf '%s\t2026-08-08T00:00:00Z\tv1\tabc\t%s\n' "$WT/.xyz" "$WT" >"$XYZ_REG2"
   171	
   172	LIVE_OUT="$WORK/HQ-MARATHON-LIVE-gh448.md"
   173	HQ_PDDA_REGISTRY_DIR="$WORK/empty-pdda" \
   174	HQ_REBALANCE_DB="$WORK/nonexistent.db" \
   175	HQ_XYZ_REGISTRY="$XYZ_REG2" \
   176	HQ_SEARCH_ROOTS="$WORK" \
   177	HQ_MARATHON_LIVE_TODAY="2026-08-08" \
   178	HQ_MARATHON_LIVE_NOW="2026-08-08T12:00:00Z" \
   179	HQ_MARATHON_LIVE_NOW_EPOCH="1000000000" \
   180	bash "$LIVE" --out "$LIVE_OUT" >/dev/null 2>&1
   181	grep -q '🟢 live' "$LIVE_OUT" 2>/dev/null \
   182	  && pass "marathon-live.sh: claimed task + linked-worktree common-dir lock -> 🟢 live" \
   183	  || fail "marathon-live.sh: expected a 🟢 live row: $(grep -E '^\| ' "$LIVE_OUT" 2>/dev/null || echo '(no report)')"
   184	
   185	# C3. find-harness.sh --check — a "harness" fixture whose skill script + lib live in a linked
   186	# worktree, invoked from a separate FOREIGN caller repo so the concurrency-warning gate fires.
   187	HARNESS_MAIN="$WORK/harness-main"
   188	mkdir -p "$HARNESS_MAIN/relay-automation" "$HARNESS_MAIN/skills/relay-xyz"
   189	printf '#!/usr/bin/env bash\n:\n' >"$HARNESS_MAIN/relay-automation/relay-drive.sh"
   190	chmod +x "$HARNESS_MAIN/relay-automation/relay-drive.sh"
   191	cp "$LIB" "$HARNESS_MAIN/relay-automation/driver-lock-lib.sh"
   192	cp "$FH" "$HARNESS_MAIN/skills/relay-xyz/find-harness.sh"
   193	git init -q "$HARNESS_MAIN"
   194	git -C "$HARNESS_MAIN" config user.email t@example.com
   195	git -C "$HARNESS_MAIN" config user.name "gh448 test"
   196	git -C "$HARNESS_MAIN" add -A
   197	git -C "$HARNESS_MAIN" commit -qm seed
   198	HARNESS_WT="$WORK/harness-wt"
   199	git -C "$HARNESS_MAIN" worktree add -q "$HARNESS_WT" -b gh448-harness-wt-branch
   200	
   201	HARNESS_COMMON_LOCK="$HARNESS_MAIN/.git/relay-driver.lock"
   202	mkdir -p "$HARNESS_COMMON_LOCK"; printf '%s\n' "$$" >"$HARNESS_COMMON_LOCK/pid"
   203	
   204	FOREIGN="$WORK/foreign"
   205	mkdir -p "$FOREIGN"
   206	git init -q "$FOREIGN"
   207	
   208	fh_out="$(cd "$FOREIGN" && bash "$HARNESS_WT/skills/relay-xyz/find-harness.sh" --check 2>&1)"
   209	printf '%s' "$fh_out" | grep -q 'a driver lock is currently HELD' \
   210	  && pass "find-harness.sh --check: linked-worktree harness + held common-dir lock -> warns" \
   211	  || fail "find-harness.sh --check: expected a held-lock warning, got: $fh_out"
   212	printf '%s' "$fh_out" | grep -qF "$HARNESS_COMMON_LOCK" \
   213	  && pass "find-harness.sh --check: warning names the REAL (common-dir) lock path" \
   214	  || fail "find-harness.sh --check: warning did not name $HARNESS_COMMON_LOCK: $fh_out"
   215	
   216	# ---------------------------------------------------------------------------
   217	echo "-- syntax check --"
   218	for s in "$LIB" "$LS" "$LIVE" "$FH" "$HERE/gh448-driver-lock-resolver.sh"; do
   219	  bash -n "$s" 2>/dev/null && pass "syntax OK: $(basename "$s")" || fail "syntax error in: $s"
   220	done
   221	
   222	printf '\ngh448-driver-lock-resolver: %d pass, %d fail\n' "$PASS" "$FAIL"
   223	[ "$FAIL" -eq 0 ]
     1	#!/usr/bin/env bash
     2	# marathon-ls.sh — cross-repo marathon monitor engine (read-only).
     3	#
     4	# Enumerates every repo known to the xyz registry (hub + col-5 coordinated_repo),
     5	# resolves its relay-driver lock path, derives LIVE/STALE/IDLE/GONE state, finds
     6	# the newest *marathon*.jsonl tick event, and prints one TSV row per repo.
     7	#
     8	# Output columns (tab-separated, header row first):
     9	#   REPO  STATE  PHASE  LAST-TICK  PID  RELAY-FILE
    10	#
    11	# STATE derivation:
    12	#   LIVE  — lock dir present + pid file alive (kill -0 succeeds)
    13	#   STALE — lock dir present + pid dead or missing
    14	#   IDLE  — no lock + newest marathon tick event is phase.approved or marathon.complete
    15	#   GONE  — repo path does not exist on disk
    16	#
    17	# Registry: $XYZ_REGISTRY (default: ${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv)
    18	# Registry format: install_dir<TAB>last_install_utc<TAB>tick_version<TAB>source_commit<TAB>coordinated_repo
    19	#
    20	# This script writes NO state to any monitored repo.
    21	set -euo pipefail
    22	
    23	XYZ_REGISTRY="${XYZ_REGISTRY:-${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv}"
    24	
    25	# Resolve this script's real directory (bash 3.2 / macOS safe — no readlink -f).
    26	_src="${BASH_SOURCE[0]}"
    27	while [ -h "$_src" ]; do
    28	  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
    29	  _src="$(readlink "$_src")"
    30	  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
    31	done
    32	SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
    33	HUB_REPO="$(cd "$SELF_DIR/.." && pwd)"
    34	
    35	# shellcheck source=relay-automation/driver-lock-lib.sh
    36	. "$SELF_DIR/driver-lock-lib.sh"
    37	
    38	# ---------------------------------------------------------------------------
    39	# helpers
    40	# ---------------------------------------------------------------------------
    41	
    42	trim_cr() { printf '%s' "${1%$'\r'}"; }
    43	
    44	# Resolve the relay-driver lock path for a given repo root — delegates to the shared resolver
    45	# (GH-448: this used to guess 2 branches inline and missed the linked-worktree case, where .git is a
    46	# FILE and the driver's real lock lives at the git common dir, not <repo>/.git/relay-driver.lock).
    47	lock_path_for_repo() {
    48	  driver_lock_path_for_repo "$1"
    49	}
    50	
    51	# Find the newest *marathon*.jsonl file under <repo>/.tick/events/.
    52	newest_marathon_jsonl() {
    53	  local repo="$1"
    54	  local events_dir="$repo/.tick/events"
    55	  [ -d "$events_dir" ] || return 0
    56	  # Use ls -t (newest first) rather than `find -newer` for bash 3.2 compat.
    57	  # Glob for files matching *marathon*.jsonl; pick the first (newest by mtime).
    58	  local f
    59	  # shellcheck disable=SC2012
    60	  f="$(ls -t "$events_dir"/*marathon*.jsonl 2>/dev/null | head -1 || true)"
    61	  printf '%s' "$f"
    62	}
    63	
    64	# Extract the last event line from a jsonl file and return phase type + timestamp.
    65	# Outputs: TYPE<TAB>TIMESTAMP  (or empty strings when not parseable).
    66	last_event_fields() {
    67	  local jsonl="$1"
    68	  [ -f "$jsonl" ] || { printf '\t'; return 0; }
    69	  local last_line type ts
    70	  last_line="$(tail -1 "$jsonl" 2>/dev/null || true)"
    71	  [ -n "$last_line" ] || { printf '\t'; return 0; }
    72	  # Parse with sed: no jq dependency requirement.
    73	  type="$(printf '%s' "$last_line" | sed 's/.*"type"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' 2>/dev/null || true)"
    74	  ts="$(printf '%s' "$last_line" | sed 's/.*"ts"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' 2>/dev/null || true)"
    75	  # If sed didn't actually find a match it returns the whole string unchanged; detect that.
    76	  [ "$type" = "$last_line" ] && type=""
    77	  [ "$ts" = "$last_line" ] && ts=""
    78	  printf '%s\t%s' "${type:-}" "${ts:-}"
    79	}
    80	
    81	# Determine the STATE for a repo given its lock dir path.
    82	# Sets globals: _STATE _PID
    83	resolve_state() {
    84	  local lock="$1"
    85	  _STATE="IDLE"
    86	  _PID="-"
    87	
    88	  if [ -d "$lock" ]; then
    89	    local pid_file="$lock/pid"
    90	    local pid=""
    91	    [ -f "$pid_file" ] && pid="$(cat "$pid_file" 2>/dev/null || true)"
    92	    pid="$(trim_cr "${pid:-}")"
    93	    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    94	      _STATE="LIVE"
    95	      _PID="$pid"
    96	    else
    97	      _STATE="STALE"
    98	      _PID="${pid:--}"
    99	    fi
   100	    return 0
   101	  fi
   102	
   103	  # No lock — state is IDLE (no lock present).
   104	  _STATE="IDLE"
   105	  _PID="-"
   106	}
   107	
   108	# Find the newest <phase-dir>/*/RELAY.md path for a repo (used in RELAY-FILE column).
   109	#
   110	# GH-484: reads BOTH the current default (marathon-system/) and the historical one (phases/), and
   111	# picks whichever holds the newer file — not a straight swap. Two populations need to stay visible
   112	# at once: this repo's ~72 committed pre-flip runs (deliberately not migrated), and fleet repos
   113	# whose vendored .xyz/ has not re-synced yet and so is still writing to phases/. Checking only the
   114	# new name would make the monitor silently report nothing for either.
   115	newest_relay_file() {
   116	  local repo="$1" d f newest=""
   117	  for d in "$repo/marathon-system" "$repo/phases"; do
   118	    [ -d "$d" ] || continue
   119	    # shellcheck disable=SC2012
   120	    f="$(ls -t "$d"/*/RELAY.md 2>/dev/null | head -1 || true)"
   121	    [ -n "$f" ] || continue
   122	    if [ -z "$newest" ] || [ "$f" -nt "$newest" ]; then newest="$f"; fi
   123	  done
   124	  printf '%s' "${newest:--}"
   125	}
   126	
   127	# ---------------------------------------------------------------------------
   128	# print one row per repo
   129	# ---------------------------------------------------------------------------
   130	
   131	print_row() {
   132	  local repo="$1"
   133	  local repo_abs
   134	
   135	  # Canonicalize path (no readlink -f on macOS bash 3.2).
   136	  if [ -d "$repo" ]; then
   137	    repo_abs="$(cd "$repo" && pwd)"
   138	  else
   139	    repo_abs="$repo"
   140	  fi
   141	
   142	  # GONE: repo does not exist on disk.
   143	  if [ ! -d "$repo_abs" ]; then
   144	    printf '%s\tGONE\t-\t-\t-\t-\n' "$repo_abs"
   145	    return 0
   146	  fi
   147	
   148	  local lock
   149	  lock="$(lock_path_for_repo "$repo_abs")"
   150	
   151	  resolve_state "$lock"
   152	  local state="$_STATE" pid="$_PID"
   153	
   154	  local marathon_jsonl phase ts relay_file
   155	  marathon_jsonl="$(newest_marathon_jsonl "$repo_abs")"
   156	  if [ -n "$marathon_jsonl" ]; then
   157	    local fields
   158	    fields="$(last_event_fields "$marathon_jsonl")"
   159	    phase="$(printf '%s' "$fields" | cut -f1)"
   160	    ts="$(printf '%s' "$fields" | cut -f2)"
   161	  else
   162	    phase="-"
   163	    ts="-"
   164	  fi
   165	  [ -n "$phase" ] || phase="-"
   166	  [ -n "$ts" ]    || ts="-"
   167	
   168	  relay_file="$(newest_relay_file "$repo_abs")"
   169	
   170	  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
   171	    "$repo_abs" "$state" "$phase" "$ts" "$pid" "$relay_file"
   172	}
   173	
   174	# ---------------------------------------------------------------------------
   175	# collect repos: hub + registry col-5
   176	# ---------------------------------------------------------------------------
   177	
   178	printf 'REPO\tSTATE\tPHASE\tLAST-TICK\tPID\tRELAY-FILE\n'
   179	
   180	# Hub repo always first.
   181	print_row "$HUB_REPO"
   182	
   183	# Registry — col 5 (coordinated_repo), skip header + comment lines.
   184	if [ -f "$XYZ_REGISTRY" ]; then
   185	  while IFS=$'\t' read -r install_dir _last_utc _tick_ver _source_commit coordinated_repo _extra; do
   186	    install_dir="$(trim_cr "${install_dir:-}")"
   187	    coordinated_repo="$(trim_cr "${coordinated_repo:-}")"
   188	    [ -n "$install_dir" ] || continue
   189	    case "$install_dir" in \#*) continue ;; esac
   190	    [ "$install_dir" = "install_dir" ] && continue   # skip the TSV header row
   191	    [ -n "$coordinated_repo" ] || continue
   192	    # Skip duplicates (if coordinated_repo == hub repo).
   193	    local_abs=""
   194	    if [ -d "$coordinated_repo" ]; then
   195	      local_abs="$(cd "$coordinated_repo" && pwd)"
   196	    fi
   197	    [ "$local_abs" = "$HUB_REPO" ] && continue
   198	    print_row "$coordinated_repo"
   199	  done < "$XYZ_REGISTRY"
   200	fi
     1	#!/usr/bin/env bash
     2	# utils/hq/marathon-live.sh — read-only cross-repo LIVE marathon status (GH-218).
     3	#
     4	# Answers "what marathons are running right now?" across every XYZ-vendored repo on this machine, by
     5	# COMPOSING existing local primitives — it stands up no new per-repo infrastructure (no MCP server):
     6	#   - repo discovery : hq_known_repos + hq_repo_resolve (utils/hq/hq-lib.sh), the SAME enumeration
     7	#                      marathon-scan.sh already uses. No new discovery code.
     8	#   - live claim     : each repo's OWN `tick project` regenerates its `.tick/STATE.md` from its event
     9	#                      log; the `## Claimed` section names the task id + claimant currently holding work
    10	#                      (the live signal the doc-status scanner marathon-scan.sh cannot see).
    11	#   - is-it-really-driving : cross-checked against the driver lock file (resolved by the SAME shared
    12	#                      resolver the driver itself writes through — relay-automation/driver-lock-lib.sh,
    13	#                      GH-448 — so a linked worktree's lock in the git common dir is found, not missed)
    14	#                      and any `marathon/*`-branch worktree with a commit inside the activity window —
    15	#                      a claim without either is "claimed, not driving".
    16	#
    17	# Emits one compact Markdown table: repo | marathon/lane | task | claimant | live | last activity.
    18	# Read-only over every target repo (the only write is the aggregate report itself), matching
    19	# marathon-scan.sh's safety posture. Phase 2 (rollup.sh) embeds this report verbatim.
    20	#
    21	# Usage:
    22	#   utils/hq/marathon-live.sh
    23	#   utils/hq/marathon-live.sh --out PROJECT/2-WORKING/HQ-MARATHON-LIVE-2026-07-19.md --window 30
    24	#
    25	# Test seams (mirror marathon-scan.sh):
    26	#   HQ_MARATHON_LIVE_TODAY   pin the report date (YYYY-MM-DD)
    27	#   HQ_MARATHON_LIVE_NOW     pin the generated-at timestamp
    28	#   HQ_MARATHON_LIVE_NOW_EPOCH  pin "now" (unix seconds) for the worktree activity-window math
    29	#   HQ_MARATHON_LIVE_WINDOW_MIN default activity window in minutes (default 30; --window overrides)
    30	
    31	set -uo pipefail
    32	# strict-mode: -e exempt — analysis tool with expected-nonzero probes (repo resolution, tick, git in a
    33	# non-repo fixture); every such failure is handled explicitly. See GUIDING-PRINCIPLES.md#strict-mode-policy.
    34	
    35	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    36	ROOT="$(cd "$HERE/../.." && pwd)"
    37	# shellcheck source=utils/hq/hq-lib.sh
    38	. "$HERE/hq-lib.sh"
    39	# shellcheck source=relay-automation/driver-lock-lib.sh
    40	. "$ROOT/relay-automation/driver-lock-lib.sh"
    41	
    42	TODAY="${HQ_MARATHON_LIVE_TODAY:-"$(date -u +%Y-%m-%d)"}"
    43	NOW="${HQ_MARATHON_LIVE_NOW:-"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}"
    44	NOW_EPOCH="${HQ_MARATHON_LIVE_NOW_EPOCH:-"$(date +%s)"}"
    45	WINDOW_MIN="${HQ_MARATHON_LIVE_WINDOW_MIN:-30}"
    46	OUT=""
    47	
    48	usage() {
    49	  cat <<'EOF'
    50	Usage: utils/hq/marathon-live.sh [--out FILE] [--window MINUTES]
    51	
    52	Enumerate XYZ-vendored repos, regenerate each repo's own tick STATE.md, and report every LIVE
    53	marathon claim (repo, marathon/lane, task, claimant, live-or-stalled, last activity) as one aggregate
    54	Markdown table written in the hub repo. Read-only over every target repo.
    55	EOF
    56	}
    57	
    58	while (($# > 0)); do
    59	  case "$1" in
    60	    --out) OUT="${2:-}"; shift 2 ;;
    61	    --window) WINDOW_MIN="${2:-}"; shift 2 ;;
    62	    --help|-h) usage; exit 0 ;;
    63	    *) usage >&2; echo "hq marathon-live: unknown argument: $1" >&2; exit 2 ;;
    64	  esac
    65	done
    66	
    67	case "$WINDOW_MIN" in ''|*[!0-9]*) echo "hq marathon-live: --window must be a whole number of minutes" >&2; exit 2 ;; esac
    68	
    69	OUT="${OUT:-$ROOT/PROJECT/2-WORKING/HQ-MARATHON-LIVE-$TODAY.md}"
    70	[[ "$OUT" = /* ]] || OUT="$ROOT/$OUT"
    71	mkdir -p "$(dirname "$OUT")"
    72	
    73	ROWS="$(mktemp "${TMPDIR:-/tmp}/hq-marathon-live-rows.XXXXXX")"
    74	trap 'rm -f "$ROWS"' EXIT
    75	
    76	# tsv_escape/pipe-escape a cell for a Markdown table (| would break the column).
    77	md_cell() { printf '%s' "$1" | sed 's/|/\\|/g'; }
    78	
    79	# Resolve a repo's own tick binary (native, then vendored) — same precedence find-harness.sh uses.
    80	resolve_tick() {
    81	  local repo_path="$1"
    82	  if [[ -x "$repo_path/bin/tick" ]]; then printf '%s' "$repo_path/bin/tick"; return 0; fi
    83	  if [[ -x "$repo_path/.xyz/bin/tick" ]]; then printf '%s' "$repo_path/.xyz/bin/tick"; return 0; fi
    84	  return 1
    85	}
    86	
    87	# Derive a human "marathon/lane" label from a claimed task id (e.g. MARATHON-GH208-FOO-TURN -> GH208-FOO).
    88	lane_of() {
    89	  local task="$1"
    90	  task="${task#MARATHON-}"; task="${task#RELAY-}"
    91	  task="${task%-TURN}"
    92	  printf '%s' "$task"
    93	}
    94	
    95	# Is the driver lock present for this repo? Prints the lock path or nothing. GH-448: resolved via the
    96	# shared resolver (relay-automation/driver-lock-lib.sh) — the SAME path the driver itself writes,
    97	# including the linked-worktree case (.git is a FILE -> the git common dir, not <repo>/.git/…) and the
    98	# vendored case (no .git -> <repo>/.relay-driver.lock, NOT <repo>/.xyz/.relay-driver.lock — the driver
    99	# never writes inside .xyz/, so the old .xyz/-scoped check here could never have matched a real lock).
   100	driver_lock_path() {
   101	  local repo_path="$1" lock
   102	  lock="$(driver_lock_path_for_repo "$repo_path")"
   103	  [[ -e "$lock" ]] && { printf '%s' "$lock"; return 0; }
   104	  return 1
   105	}
   106	
   107	# Newest marathon/*-branch worktree commit epoch within the repo, or empty. Best-effort — a fixture
   108	# .git that is not a real repo simply yields nothing (guarded), never an error.
   109	newest_marathon_worktree_epoch() {
   110	  local repo_path="$1" wt="" br="" best="" ct
   111	  while IFS= read -r line; do
   112	    case "$line" in
   113	      worktree\ *) wt="${line#worktree }" ;;
   114	      branch\ *)
   115	        br="${line#branch }"
   116	        if [[ "$br" == refs/heads/marathon/* && -n "$wt" ]]; then
   117	          ct="$(git -C "$wt" log -1 --format=%ct 2>/dev/null || true)"
   118	          if [[ -n "$ct" && ( -z "$best" || "$ct" -gt "$best" ) ]]; then best="$ct"; fi
   119	        fi
   120	        ;;
   121	    esac
   122	  done < <(git -C "$repo_path" worktree list --porcelain 2>/dev/null || true)
   123	  printf '%s' "$best"
   124	}
   125	
   126	window_secs=$(( WINDOW_MIN * 60 ))
   127	repos_scanned=0
   128	live_count=0
   129	stalled_count=0
   130	idle_count=0
   131	
   132	while IFS= read -r repo; do
   133	  [[ -n "$repo" ]] || continue
   134	  fields="$(hq_repo_resolve "$repo")"
   135	  repo_path="$(printf '%s\n' "$fields" | sed -n 's/^REPO_PATH=//p' | head -1)"
   136	  [[ -n "$repo_path" && -d "$repo_path" ]] || continue
   137	  repos_scanned=$((repos_scanned + 1))
   138	
   139	  # Regenerate this repo's STATE.md from its own event log (writes only .tick/, coordination state —
   140	  # never touched code). Best-effort: a repo with no tick binary / no events is simply reported idle.
   141	  tick_bin="$(resolve_tick "$repo_path" || true)"
   142	  if [[ -n "$tick_bin" ]]; then
   143	    ( cd "$repo_path" && TICK_REPO_ROOT="$repo_path" "$tick_bin" project ) >/dev/null 2>&1 || true
   144	  fi
   145	

exec
/bin/zsh -lc "nl -ba utils/py/rtl.py | sed -n '477,525p' && nl -ba utils/py/marathon_drive.py | sed -n '590,660p' && rg -n -C 4 'gh448-driver-lock|driver-lock-resolver|COMMON_LOCK' test PROJECT ROADMAP.md CHANGELOG.md .github 2>/dev/null" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua
 succeeded in 0ms:
   477	def driver_lock_path(root):
   478	    # GH-448: the ONE shared resolver for the relay-driver lock path, matching the DRIVER's own
   479	    # write-side resolution (marathon_drive.py / marathon-drive.sh, relay_drive.py / relay-drive.sh) —
   480	    # every read-only consumer (marathon-ls.sh, marathon-live.sh, find-harness.sh) must resolve the
   481	    # SAME path or it probes a location the driver never writes and reports a live run as idle.
   482	    #   .git is a directory  -> <root>/.git/relay-driver.lock                (normal clone)
   483	    #   .git is a file       -> <git-common-dir>/relay-driver.lock           (linked worktree)
   484	    #   no .git (vendored)   -> <root>/.relay-driver.lock                    (vendored .xyz/ copy)
   485	    # Returns (lock_path, lock_label) — lock_label is always the SHORT display form used in messages.
   486	    git_path = os.path.join(root, ".git")
   487	    if os.path.isdir(git_path):
   488	        return os.path.join(root, ".git", "relay-driver.lock"), ".git/relay-driver.lock"
   489	    if os.path.isfile(git_path):
   490	        common = ""
   491	        try:
   492	            common = subprocess.check_output(
   493	                ["git", "-C", root, "rev-parse", "--path-format=absolute", "--git-common-dir"],
   494	                stderr=subprocess.DEVNULL).decode("utf-8").strip()
   495	        except Exception:
   496	            common = ""
   497	        if common:
   498	            return os.path.join(common, "relay-driver.lock"), ".git/relay-driver.lock"
   499	    return os.path.join(root, ".relay-driver.lock"), ".relay-driver.lock"
   590	        harness_root = os.path.dirname(os.path.dirname(mantra_file))
   591	        mantra_rel = _rel(mantra_file, harness_root)          # relay-automation/DEBUG-MANTRA.md
   592	        phase_rel = _rel(phase_dir_, root)
   593	        out = (f"\n## Debug mantra (auto-triggered — {prior} prior attempt(s) on this phase did not reach Approved)\n\n"
   594	               f"Before trying again, read `{mantra_rel}` (relative to the harness root) and follow its "
   595	               f"four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this "
   596	               f"round as a breadcrumb for the next one.\n")
   597	        if reason:
   598	            out += (f"Last recorded reason (`{os.path.join(phase_rel, 'ESCALATION.md')}`): `{reason}`. "
   599	                    "Read it before re-guessing.\n")
   600	        return out
   601	
   602	    if get_env("RELAY_DRIVER_LOCKED", "0") != "1":
   603	        # GH-49b/GH-207: the lock lives in .git/ (never committed) for a normal clone. In a linked
   604	        # worktree .git is a FILE pointing at the shared gitdir, so resolve the real common dir and put
   605	        # the lock there — otherwise --require-clean sees the driver's own lock as untracked dirt inside
   606	        # the worktree. A vendored .xyz/ copy (no .git) falls back to a hidden lock beside the scripts.
   607	        # GH-448: this resolution is the canonical write-side one — every read-only consumer (marathon-
   608	        # ls.sh, marathon-live.sh, find-harness.sh) must agree with it, so it lives in rtl.py's shared
   609	        # driver_lock_path (with a byte-for-byte Bash twin in relay-automation/driver-lock-lib.sh)
   610	        # rather than being reimplemented here.
   611	        lock_dir, lock_label = driver_lock_path(root)
   612	
   613	        try:
   614	            os.mkdir(lock_dir)
   615	        except OSError:
   616	            holder = ""
   617	            pid_file = os.path.join(lock_dir, "pid")
   618	            if os.path.isfile(pid_file):
   619	                try:
   620	                    with open(pid_file, 'r') as f: holder = f.read().strip()
   621	                except: pass
   622	            
   623	            is_running = False
   624	            if holder:
   625	                try:
   626	                    os.kill(int(holder), 0)
   627	                    is_running = True
   628	                except: pass
   629	            
   630	            if is_running:
   631	                eprint(f"marathon-drive: another driver is active in this repo (pid {holder}, lock: {lock_label}).")
   632	                eprint("marathon-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).")
   633	                sys.exit(1)
   634	            
   635	            eprint(f"marathon-drive: reclaiming stale relay-driver.lock (holder pid {holder or 'none'} not running).")
   636	            # Sentinel Tier 1 (GH-281/GH-342): record the auto-heal. Emitted BEFORE the reclaim, so
   637	            # the finding survives even if the rmtree/mkdir below fails and the run exits 1.
   638	            xyz_debug_log_stale_lock(root)
   639	            try:
   640	                shutil.rmtree(lock_dir)
   641	                os.mkdir(lock_dir)
   642	            except:
   643	                eprint("marathon-drive: could not acquire relay-driver.lock after reclaiming a stale one.")
   644	                sys.exit(1)
   645	        
   646	        with open(os.path.join(lock_dir, "pid"), 'w') as f:
   647	            f.write(str(os.getpid()) + "\n")
   648	        
   649	        os.environ["RELAY_DRIVER_LOCKED"] = "1"
   650	        def cleanup_lock():
   651	            try: shutil.rmtree(lock_dir)
   652	            except: pass
   653	        import atexit
   654	        atexit.register(cleanup_lock)
   655	
   656	    xyz_append_bin = get_env("XYZ_APPEND_BIN", os.path.join(xyz_harness, "utils", "telemetry", "append-xyz-completion.sh"))
   657	
   658	    def xyz_marathon_emit(health, desc):
   659	        ctx = get_env("XYZ_HARNESS_CONTEXT", "")
   660	        if ctx == "marathon-phase": return
ROADMAP.md-260-- **Part B — Adversarial hardening** ⚠️ — Phase 1 (epoch fencing) shipped; Phase 2 chaos-suite *detection* partials landed; Phases 2–4 are the active "adversarially proven → commercially viable" frontier. Immediate next-up: promote exactly one proof-sized Phase-2 slice into a contract-backed lane (important because Part B only keeps momentum if it advances in small, verifiable proofs instead of reopening the whole frontier at once). → [ADVERSARIAL-HARDENING.md](PROJECT/2-WORKING/ADVERSARIAL-HARDENING.md)
ROADMAP.md-261-- **Tooling · relay-to-issue skill** ✅ **SHIPPED + VERIFIED END-TO-END 2026-07-05; closed** — a post-relay skill that distills a closed `/relay` thread into ONE checklist-style GitHub issue, filed in the repo the relay was *about* (cross-repo aware; dedup-stamped; auto-posts via `gh`). `skills/relay-to-issue/` (SKILL + `relay-to-issue.sh` + `install.sh`); the full `resolve → file → provenance-stamp → dedup` loop proven live against a real closed relay — a live `gh issue create` posted #139, and a re-run correctly reported `ALREADY_FILED` (dedup holds). Nothing outstanding. **Correction (2026-07-07):** this line was stale (still marked 🟡, pointing at a `2-WORKING` path that no longer exists) — the doc had already moved to `3-COMPLETED`, and the generated [MARATHON-PLAN-2026-07-07.md](PROJECT/4-MISC/MARATHON-PLAN-2026-07-07.md) was surfacing this as a live Wave 1 item off that drift. Re-run `utils/marathon-plan.sh` to clear the ghost lane once this line is corrected. → [RELAY-TO-ISSUE-SKILL.md](PROJECT/3-COMPLETED/RELAY-TO-ISSUE-SKILL.md)
ROADMAP.md-262-
ROADMAP.md-263-### Completed
ROADMAP.md:264:- **GH-448 · driver-lock consumers guess the path with 2 branches while the drivers use 3, so a linked worktree's LIVE marathon reads as IDLE** ✅ **SHIPPED 2026-08-10 (PR #449)** — `marathon-drive` (frozen `.sh` + authoritative `utils/py/marathon_drive.py`) correctly resolves its lock 3 ways (`.git` dir / `.git` file → git common dir / absent → vendored); `marathon-ls.sh`, `utils/hq/marathon-live.sh`, and `find-harness.sh --check` had each drifted to a 2-branch guess that misses the linked-worktree case, so a genuinely-live driver reads as `IDLE`/"claimed, not driving"/silent. New shared resolver (`utils/py/rtl.py::driver_lock_path` + `relay-automation/driver-lock-lib.sh`, parity-tested) used by all three; `marathon_drive.py` refactored onto it too (no behavior change, `driver-lock.sh` still 4/4). `test/gh448-driver-lock-resolver.sh` (17/17): bash/python parity, a negative control replaying the pre-fix logic against a REAL `git worktree add` fixture (observed missing the lock), and an end-to-end pass of the fixed scripts against that same fixture (observed LIVE/🟢 live/warning). Sibling **#376** (driver-side `relay-drive.sh`/`relay_drive.py` half of the same defect) is explicitly out of scope here. cx/risk/eff 3/2/3, 1 phase. → [GH-448-DRIVER-LOCK-RESOLVER.md](PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md) · [#448](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/448) · [#376](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/376) · [#354](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/354)
ROADMAP.md-265-- **GH-484 · redefine the canonical marathon-phase directory default from phases/ to marathon-system/** ✅ **SHIPPED 2026-08-09 (branch `feat/gh484-marathon-system-default`)** — the phase-output default now matches `relay-system/`'s naming; `--phases-dir`/`PHASES_DIR` override it exactly as before and the ~72 committed historical `phases/<run-id>/` records are deliberately not migrated. **Three independent defaults had to move, not one** — a pre-implementation consult (codex; agy timed out twice, single-model and stated as such) caught that `marathon.sh` computes its own at `:167` and forwards the flag on every phase, so a driver-only flip would have left the multi-phase orchestrator untouched while still satisfying the original acceptance criteria. Carried a **latent bug that predates the rename**: the dirty-tree pre-flight excluded a hardcoded `"phases/"` instead of the configured directory, so any `--phases-dir` user already had their own phase output called stray, and a vendored `<repo>/.xyz/phases/` was never matched at all. **The most instructive defect was in the fix itself** — `git rev-parse --show-toplevel` always reports the physical path, so a repo behind a symlinked ancestor (macOS `/var`, `/tmp`) silently emptied the computed prefix and disabled the exclusion, exactly the failure the fix existed to remove; both twins had it, and the new test caught it. That test's own first two drafts were vacuous and passed against pre-fix code (the driver dies on the gate probe before the clean check; porcelain collapses untracked dirs to `?? state/`) — now controlled and replay-verified red pre-fix. Monitors get dual-path lookup, not a swap, so pre-flip runs and not-yet-re-synced fleet repos stay visible. Phase 0's grep classification missed two live sites that only running the suite found, recorded in the doc rather than folded in quietly. GH-308 exception process followed for the one frozen twin. cx/risk/eff 3/2/3, 3 phases. → [GH-484-MARATHON-SYSTEM-DEFAULT.md](PROJECT/3-COMPLETED/GH-484-MARATHON-SYSTEM-DEFAULT.md) · [#484](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/484)
ROADMAP.md-266-- **GH-307 · Marathon pre-advance gate inherits the run's identity tags, so `bash validate.sh` can never pass inside a marathon** ✅ **SHIPPED 2026-07-27 (PR #309)** — `marathon.sh` drives each phase with `XYZ_HARNESS_CONTEXT` / `MARATHON_LANE_NS` set (and packet-generated invocations add `XYZ_SESSION_ID`); the gate ran as a plain subprocess and inherited all three, breaking `test/xyz-harness-hooks.sh` and `test/debug-mantra.sh` — so the *documented default gate* halted every packet-driven run at phase 1. Scrubbed in both twins (`utils/py/marathon_drive.py` is the one that runs by default), narrowly: `MARATHON_ROOT` / `TICK_BIN` / `TICK_REPO_ROOT` are preserved. Guarded by `test/gh307-gate-env-scrub.sh` (structural parity) and a behavioural case in `test/marathon-drive.sh` §5b. Proven live — the gate passed in marathon phase 2 of the same run that previously halted. No capture doc: found and fixed in-flight while driving the marathon. · [#307](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/307)
ROADMAP.md-267-- **GH-278 · aider-turn per-turn timeout drifts across twins and docs (py 300s / sh 600s / docs 900s)** ✅ **SHIPPED 2026-07-27 (PR #309, marathon phase 4/4)** — 900s asserted across both twins and the relay-xyz skill by a static parity guard, plus a behavioural guard that a timeout-killed turn (exit 7) leaves no 0-byte stubs (untracked removed, tracked restored from HEAD). The phase escalated once on a containment violation traced to the fixture, not the product: the shims' `--help` probe is deliberately not cwd-wrapped, and the stub CLI wrote unconditionally, so fixtures leaked into the caller's cwd. Fixed; phase deliberately not re-driven (a re-fire would regenerate the leaky fixture). → [GH-278-AIDER-TURN-TIMEOUT-DRIFT.md](PROJECT/3-COMPLETED/GH-278-AIDER-TURN-TIMEOUT-DRIFT.md) · [#278](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/278)
ROADMAP.md-268-- **GH-300 · swe-diagram: search input touches/overflows the font-picker when typing — two distinct bugs, same symptom family** ✅ **SHIPPED 2026-07-23** — **(1)** `type="search"` never reset `-webkit-appearance`, letting WebKit's native cancel-button decoration override the input's explicit 180px width; fixed, but not independently re-verified in Safari (no Safari automation in this environment). **(2)** found on operator re-report: `positionPicker()` only ran on load/font-change/resize, never on the search box's own `input` event, so the custom clear button appearing (growing the right-anchored `.swe-search` box leftward) left the picker stranded — a window resize incidentally fixed it by recomputing from the now-current width, which is exactly the behavior reported. Fixed by dispatching a `swe-search-resize` event from `renderer.js`'s search handlers; **verified quantitatively** (headless-Chrome bounding-rect measurement: gap went from a healthy 8px to a -22px overlap after typing, now stays a constant 8px with no resize needed) — this fix is plain DOM logic, not WebKit-specific, so the Chrome verification is directly conclusive. `test/swe-diagram.sh` 42/42 throughout. → [GH-300-SWE-DIAGRAM-SEARCH-INPUT-OVERFLOW.md](PROJECT/3-COMPLETED/GH-300-SWE-DIAGRAM-SEARCH-INPUT-OVERFLOW.md) · [#300](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/300)
--
test/gh448-driver-lock-resolver.sh-1-#!/usr/bin/env bash
test/gh448-driver-lock-resolver.sh:2:# test/gh448-driver-lock-resolver.sh — GH-448: the shared driver-lock resolver.
test/gh448-driver-lock-resolver.sh-3-#
test/gh448-driver-lock-resolver.sh-4-# marathon-drive writes its lock to the git COMMON dir when .git is a FILE (a linked worktree). Every
test/gh448-driver-lock-resolver.sh-5-# read-only consumer used to guess the path with its OWN 2-branch inline logic (dir vs "everything
test/gh448-driver-lock-resolver.sh-6-# else"), which is wrong for the worktree case — so a LIVE marathon reported as IDLE. This test:
--
test/gh448-driver-lock-resolver.sh-24-
test/gh448-driver-lock-resolver.sh-25-# shellcheck source=relay-automation/driver-lock-lib.sh
test/gh448-driver-lock-resolver.sh-26-. "$LIB"
test/gh448-driver-lock-resolver.sh-27-
test/gh448-driver-lock-resolver.sh:28:WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh448-driver-lock.XXXXXX")"
test/gh448-driver-lock-resolver.sh-29-trap 'rm -rf "$WORK"' EXIT
test/gh448-driver-lock-resolver.sh-30-
test/gh448-driver-lock-resolver.sh-31-PASS=0; FAIL=0
test/gh448-driver-lock-resolver.sh-32-pass() { printf '  PASS: %s\n' "$*"; PASS=$((PASS+1)); }
test/gh448-driver-lock-resolver.sh-33-fail() { printf '  FAIL: %s\n' "$*" >&2; FAIL=$((FAIL+1)); }
test/gh448-driver-lock-resolver.sh-34-
test/gh448-driver-lock-resolver.sh:35:echo "== test: gh448-driver-lock-resolver =="
test/gh448-driver-lock-resolver.sh-36-echo "  workdir: $WORK"
test/gh448-driver-lock-resolver.sh-37-
test/gh448-driver-lock-resolver.sh-38-py_resolve() {  # <repo> -> prints the python resolver's lock path
test/gh448-driver-lock-resolver.sh-39-  python3 -c '
--
test/gh448-driver-lock-resolver.sh-69-git -C "$MAIN_REPO" worktree add -q "$WT" -b gh448-wt-branch
test/gh448-driver-lock-resolver.sh-70-[ -f "$WT/.git" ] && pass "fixture: linked worktree's .git is a FILE (not a dir)" \
test/gh448-driver-lock-resolver.sh-71-  || fail "fixture setup: expected $WT/.git to be a file"
test/gh448-driver-lock-resolver.sh-72-
test/gh448-driver-lock-resolver.sh:73:COMMON_LOCK="$MAIN_REPO/.git/relay-driver.lock"
test/gh448-driver-lock-resolver.sh-74-
test/gh448-driver-lock-resolver.sh-75-# ===========================================================================
test/gh448-driver-lock-resolver.sh-76-# A. Parity — Bash resolver vs Python resolver, all three branches
test/gh448-driver-lock-resolver.sh-77-# ===========================================================================
--
test/gh448-driver-lock-resolver.sh-85-    && pass "parity ($name): bash and python agree ($bash_out)" \
test/gh448-driver-lock-resolver.sh-86-    || fail "parity ($name): bash='$bash_out' python='$py_out'"
test/gh448-driver-lock-resolver.sh-87-done
test/gh448-driver-lock-resolver.sh-88-
test/gh448-driver-lock-resolver.sh:89:[ "$(driver_lock_path_for_repo "$WT")" = "$COMMON_LOCK" ] \
test/gh448-driver-lock-resolver.sh-90-  && pass "worktree case resolves to the git COMMON dir, not <worktree>/.git/…" \
test/gh448-driver-lock-resolver.sh:91:  || fail "worktree case resolved wrong: $(driver_lock_path_for_repo "$WT") (expected $COMMON_LOCK)"
test/gh448-driver-lock-resolver.sh-92-
test/gh448-driver-lock-resolver.sh-93-# ===========================================================================
test/gh448-driver-lock-resolver.sh-94-# B. Negative control — the OLD 2-branch logic each site carried, replayed
test/gh448-driver-lock-resolver.sh-95-#    verbatim against the SAME worktree fixture. Per #419: observed, not
--
test/gh448-driver-lock-resolver.sh-111-  [ -e "$repo/.xyz/.relay-driver.lock" ] && { printf '%s' "$repo/.xyz/.relay-driver.lock"; return 0; }
test/gh448-driver-lock-resolver.sh-112-  return 1
test/gh448-driver-lock-resolver.sh-113-}
test/gh448-driver-lock-resolver.sh-114-
test/gh448-driver-lock-resolver.sh:115:mkdir -p "$COMMON_LOCK"; printf '%s\n' "$$" >"$COMMON_LOCK/pid"
test/gh448-driver-lock-resolver.sh-116-
test/gh448-driver-lock-resolver.sh-117-old_ls_path="$(old_marathon_ls_lock "$WT")"
test/gh448-driver-lock-resolver.sh:118:[ "$old_ls_path" != "$COMMON_LOCK" ] && [ ! -e "$old_ls_path" ] \
test/gh448-driver-lock-resolver.sh-119-  && pass "negative control: old marathon-ls.sh logic guesses '$old_ls_path' — misses the held lock" \
test/gh448-driver-lock-resolver.sh-120-  || fail "negative control: old marathon-ls.sh logic unexpectedly found the lock"
test/gh448-driver-lock-resolver.sh-121-
test/gh448-driver-lock-resolver.sh-122-if old_live_path="$(old_marathon_live_lock "$WT")"; then
--
test/gh448-driver-lock-resolver.sh-132-[ "$old_fh_found" -eq 0 ] \
test/gh448-driver-lock-resolver.sh-133-  && pass "negative control: old find-harness.sh 2-candidate loop misses the held lock" \
test/gh448-driver-lock-resolver.sh-134-  || fail "negative control: old find-harness.sh 2-candidate loop unexpectedly found the lock"
test/gh448-driver-lock-resolver.sh-135-
test/gh448-driver-lock-resolver.sh:136:rm -rf "$COMMON_LOCK"
test/gh448-driver-lock-resolver.sh-137-
test/gh448-driver-lock-resolver.sh-138-# ===========================================================================
test/gh448-driver-lock-resolver.sh-139-# C. End-to-end, real linked worktree — the ACTUAL (fixed) scripts
test/gh448-driver-lock-resolver.sh-140-# ===========================================================================
test/gh448-driver-lock-resolver.sh-141-echo "-- C. end-to-end: fixed scripts observe LIVE from a linked worktree --"
test/gh448-driver-lock-resolver.sh-142-
test/gh448-driver-lock-resolver.sh:143:mkdir -p "$COMMON_LOCK"; printf '%s\n' "$$" >"$COMMON_LOCK/pid"
test/gh448-driver-lock-resolver.sh-144-
test/gh448-driver-lock-resolver.sh-145-# C1. marathon-ls.sh — registry row pointing at the worktree.
test/gh448-driver-lock-resolver.sh-146-REGISTRY="$WORK/registry.tsv"
test/gh448-driver-lock-resolver.sh-147-printf 'install_dir\tlast_install_utc\ttick_version\tsource_commit\tcoordinated_repo\n' >"$REGISTRY"
--
test/gh448-driver-lock-resolver.sh-197-git -C "$HARNESS_MAIN" commit -qm seed
test/gh448-driver-lock-resolver.sh-198-HARNESS_WT="$WORK/harness-wt"
test/gh448-driver-lock-resolver.sh-199-git -C "$HARNESS_MAIN" worktree add -q "$HARNESS_WT" -b gh448-harness-wt-branch
test/gh448-driver-lock-resolver.sh-200-
test/gh448-driver-lock-resolver.sh:201:HARNESS_COMMON_LOCK="$HARNESS_MAIN/.git/relay-driver.lock"
test/gh448-driver-lock-resolver.sh:202:mkdir -p "$HARNESS_COMMON_LOCK"; printf '%s\n' "$$" >"$HARNESS_COMMON_LOCK/pid"
test/gh448-driver-lock-resolver.sh-203-
test/gh448-driver-lock-resolver.sh-204-FOREIGN="$WORK/foreign"
test/gh448-driver-lock-resolver.sh-205-mkdir -p "$FOREIGN"
test/gh448-driver-lock-resolver.sh-206-git init -q "$FOREIGN"
--
test/gh448-driver-lock-resolver.sh-208-fh_out="$(cd "$FOREIGN" && bash "$HARNESS_WT/skills/relay-xyz/find-harness.sh" --check 2>&1)"
test/gh448-driver-lock-resolver.sh-209-printf '%s' "$fh_out" | grep -q 'a driver lock is currently HELD' \
test/gh448-driver-lock-resolver.sh-210-  && pass "find-harness.sh --check: linked-worktree harness + held common-dir lock -> warns" \
test/gh448-driver-lock-resolver.sh-211-  || fail "find-harness.sh --check: expected a held-lock warning, got: $fh_out"
test/gh448-driver-lock-resolver.sh:212:printf '%s' "$fh_out" | grep -qF "$HARNESS_COMMON_LOCK" \
test/gh448-driver-lock-resolver.sh-213-  && pass "find-harness.sh --check: warning names the REAL (common-dir) lock path" \
test/gh448-driver-lock-resolver.sh:214:  || fail "find-harness.sh --check: warning did not name $HARNESS_COMMON_LOCK: $fh_out"
test/gh448-driver-lock-resolver.sh-215-
test/gh448-driver-lock-resolver.sh-216-# ---------------------------------------------------------------------------
test/gh448-driver-lock-resolver.sh-217-echo "-- syntax check --"
test/gh448-driver-lock-resolver.sh:218:for s in "$LIB" "$LS" "$LIVE" "$FH" "$HERE/gh448-driver-lock-resolver.sh"; do
test/gh448-driver-lock-resolver.sh-219-  bash -n "$s" 2>/dev/null && pass "syntax OK: $(basename "$s")" || fail "syntax error in: $s"
test/gh448-driver-lock-resolver.sh-220-done
test/gh448-driver-lock-resolver.sh-221-
test/gh448-driver-lock-resolver.sh:222:printf '\ngh448-driver-lock-resolver: %d pass, %d fail\n' "$PASS" "$FAIL"
test/gh448-driver-lock-resolver.sh-223-[ "$FAIL" -eq 0 ]
--
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-26-  - relay-automation/driver-lock-lib.sh
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-27-  - relay-automation/marathon-ls.sh
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-28-  - utils/hq/marathon-live.sh
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-29-  - skills/relay-xyz/find-harness.sh
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md:30:  - test/gh448-driver-lock-resolver.sh
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-31-  - PROJECT/1-INBOX/GH-354-CONCURRENT-SWARMS.md
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-32-goal: >
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-33-  One shared driver-lock-path resolver (a Bash lib + a Python function, agreeing byte-for-byte),
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-34-  used by every read-only consumer of the lock, so a linked worktree's held lock is observed as
--
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-55-## Status
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-56-
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-57-| What was just completed | What's next |
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-58-|---|---|
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md:59:| Implemented + tested in one pass 2026-08-08: shared resolver (`utils/py/rtl.py::driver_lock_path` + new `relay-automation/driver-lock-lib.sh`, byte-for-byte parity asserted by test); `marathon_drive.py` refactored to call it (no behavior change, confirmed by `test/driver-lock.sh` still 4/4); the three broken consumers (`marathon-ls.sh`, `utils/hq/marathon-live.sh`, `find-harness.sh`) now call the shared resolver instead of guessing inline. New `test/gh448-driver-lock-resolver.sh` (17/17): bash/python parity across all 3 branches, a negative control replaying the OLD 2-branch logic against a REAL `git worktree add` fixture (observed missing the lock), and an end-to-end run of the three real, fixed scripts against that same fixture (observed LIVE / 🟢 live / held-lock warning). Existing regression suites (`marathon-monitor.sh`, `hq-marathon-live.sh`, `find-harness.sh`, `driver-lock.sh`) still green. | Open the PR into `development`. Sibling **#376** (driver-side `relay-drive.sh`/`relay_drive.py` 2-branch fix) is out of this doc's scope and stays a separate follow-up. |
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-60-
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-61-## Acceptance (transcribed from #448)
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-62-
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-63-- [x] A single shared resolver produces the driver-lock path; the in-scope consumers (marathon-ls.sh,
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-64-      marathon-live.sh, find-harness.sh) call it instead of constructing the path inline.
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-65-      `marathon-drive.sh` (frozen) is unchanged since it was already correct; `relay-drive.sh`/
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-66-      `relay_drive.py` are explicitly #376's scope, not re-litigated here.
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-67-- [x] The shell and Python resolvers agree on all inputs asserted by a test (`.git` dir, `.git` file
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md:68:      via a REAL `git worktree add`, absent/vendored) — `test/gh448-driver-lock-resolver.sh` section A.
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-69-- [x] From a **linked worktree** with a driver holding the lock: `marathon-ls` reports `LIVE`,
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-70-      `marathon-live` reports 🟢 live, and `find-harness.sh --check` prints its held-lock warning
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-71-      naming the real (common-dir) path — all three **observed** against real fixed scripts + a real
PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md-72-      `git worktree add`, not inferred — section C.

exec
/bin/zsh -lc "rg -n -C 8 'git-common-dir|relay-driver\\.lock|RELAY_DRIVER_LOCKED' relay-automation/marathon-drive.sh relay-automation/relay-drive.sh utils/py/relay_drive.py && nl -ba PROJECT/2-WORKING/GH-448-DRIVER-LOCK-RESOLVER.md | sed -n '55,75p' && git status --short" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua
 succeeded in 3219ms:
2026-08-10 11:03:15.134 xcodebuild[46384:501607]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-10 11:03:15.516 xcodebuild[46384:501605] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-4v5HXtTP' (errno=Operation not permitted)
2026-08-10 11:03:16.210 xcodebuild[46443:501947]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-10 11:03:16.426 xcodebuild[46443:501945] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
?? relay-system/2026-08-10/

exec
/bin/zsh -lc "printf 'pwd=%s\\n' \""'$PWD"; printf '"'.git='; test -f .git && sed -n '1p' .git || printf 'not-file\\n'; printf 'common-default='; git rev-parse --git-common-dir 2>/dev/null || true; printf 'common-absolute='; git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true; printf 'top='; git rev-parse --show-toplevel 2>/dev/null || true; printf 'physical-pwd='; pwd -P" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua
2026-08-10T18:03:35.639998Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 95 column 5
 succeeded in 6736ms:
/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/.git
common-absolute=/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/.git
top=/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua
physical-pwd=/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua

codex
ANSWER: **A is correct.** The resolver is behaving correctly; the macOS failures are path-string assertions using `/var/...` against Git’s canonical `/private/var/...` result. With driver and consumers using the same resolver in one filesystem namespace, a physical path cannot miss the held lock—both names address the same directory.

FINDINGS:

- [Blocker] Do not implement B. A linked worktree’s common Git directory is authoritative only through Git; it is not safely derivable from the caller’s repository string. It may live outside the worktree hierarchy (including separate-git-dir layouts). A root-string reconstruction risks returning a path the driver does not lock—the exact false-IDLE direction this PR fixes. The resolver deliberately asks Git for it in both implementations: [driver-lock-lib.sh:26](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/relay-automation/driver-lock-lib.sh:26), [rtl.py:489](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/utils/py/rtl.py:489).

- [Pass] The write side uses that same Python resolver before `mkdir`, so its lock directory and every fixed reader’s probe agree: [marathon_drive.py:607](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/utils/py/marathon_drive.py:607), [marathon_drive.py:611](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/utils/py/marathon_drive.py:611). `marathon-ls` checks the resolved path with `-d`, not by string comparison: [marathon-ls.sh:47](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/relay-automation/marathon-ls.sh:47), [marathon-ls.sh:88](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/relay-automation/marathon-ls.sh:88). `/var` versus `/private/var` therefore cannot make it report IDLE.

- [Should] Fix all three brittle test expectations in this PR. `COMMON_LOCK` is naïvely built from `$MAIN_REPO` at [gh448-driver-lock-resolver.sh:73](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/test/gh448-driver-lock-resolver.sh:73), then compared literally at [89](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/test/gh448-driver-lock-resolver.sh:89) and [212](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/test/gh448-driver-lock-resolver.sh:212). Derive the expected common directory with the same Git query, then append `relay-driver.lock`. For the `marathon-ls` row lookup, compare against `WT_PHYSICAL="$(cd "$WT" && pwd -P)"`, since the script canonicalizes its emitted repo path before printing it at [marathon-ls.sh:135](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/relay-automation/marathon-ls.sh:135).

- [Should] The best third option is not inode comparison. Keep two assertions: (1) resolver output equals Git’s `--path-format=absolute --git-common-dir` plus the lock filename; (2) create the lock at that resolved path and verify each consumer observes it. This preserves the semantic contract and the end-to-end safety property. Device/inode comparison only hides differing spellings; “exists” alone could let a resolver point to the wrong location.

- [Pass] The existing end-to-end structure is the right kind of regression coverage: it creates a real linked worktree, holds the common-dir lock, and runs all three real consumers ([gh448-driver-lock-resolver.sh:139](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/test/gh448-driver-lock-resolver.sh:139)). Only its expected-path spelling is wrong.

RECOMMENDATION: Make the small, **Easy-to-revert** test-only canonicalization fix in PR #449 before merging; do not defer a known macOS red test or alter the shared lock resolver.
tokens used
73,736
ANSWER: **A is correct.** The resolver is behaving correctly; the macOS failures are path-string assertions using `/var/...` against Git’s canonical `/private/var/...` result. With driver and consumers using the same resolver in one filesystem namespace, a physical path cannot miss the held lock—both names address the same directory.

FINDINGS:

- [Blocker] Do not implement B. A linked worktree’s common Git directory is authoritative only through Git; it is not safely derivable from the caller’s repository string. It may live outside the worktree hierarchy (including separate-git-dir layouts). A root-string reconstruction risks returning a path the driver does not lock—the exact false-IDLE direction this PR fixes. The resolver deliberately asks Git for it in both implementations: [driver-lock-lib.sh:26](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/relay-automation/driver-lock-lib.sh:26), [rtl.py:489](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/utils/py/rtl.py:489).

- [Pass] The write side uses that same Python resolver before `mkdir`, so its lock directory and every fixed reader’s probe agree: [marathon_drive.py:607](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/utils/py/marathon_drive.py:607), [marathon_drive.py:611](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/utils/py/marathon_drive.py:611). `marathon-ls` checks the resolved path with `-d`, not by string comparison: [marathon-ls.sh:47](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/relay-automation/marathon-ls.sh:47), [marathon-ls.sh:88](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/relay-automation/marathon-ls.sh:88). `/var` versus `/private/var` therefore cannot make it report IDLE.

- [Should] Fix all three brittle test expectations in this PR. `COMMON_LOCK` is naïvely built from `$MAIN_REPO` at [gh448-driver-lock-resolver.sh:73](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/test/gh448-driver-lock-resolver.sh:73), then compared literally at [89](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/test/gh448-driver-lock-resolver.sh:89) and [212](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/test/gh448-driver-lock-resolver.sh:212). Derive the expected common directory with the same Git query, then append `relay-driver.lock`. For the `marathon-ls` row lookup, compare against `WT_PHYSICAL="$(cd "$WT" && pwd -P)"`, since the script canonicalizes its emitted repo path before printing it at [marathon-ls.sh:135](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/relay-automation/marathon-ls.sh:135).

- [Should] The best third option is not inode comparison. Keep two assertions: (1) resolver output equals Git’s `--path-format=absolute --git-common-dir` plus the lock filename; (2) create the lock at that resolved path and verify each consumer observes it. This preserves the semantic contract and the end-to-end safety property. Device/inode comparison only hides differing spellings; “exists” alone could let a resolver point to the wrong location.

- [Pass] The existing end-to-end structure is the right kind of regression coverage: it creates a real linked worktree, holds the common-dir lock, and runs all three real consumers ([gh448-driver-lock-resolver.sh:139](/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-43636-9406orua/test/gh448-driver-lock-resolver.sh:139)). Only its expected-path spelling is wrong.

RECOMMENDATION: Make the small, **Easy-to-revert** test-only canonicalization fix in PR #449 before merging; do not defer a known macOS red test or alter the shared lock resolver.
