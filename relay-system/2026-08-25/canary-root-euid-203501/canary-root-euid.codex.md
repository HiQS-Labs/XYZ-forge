**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.6-terra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
2026-08-26T03:35:02.469658Z ERROR codex_models_manager::cache: failed to load models cache: missing field `base_instructions` at line 98 column 5
OpenAI Codex v0.144.6
--------
workdir: /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z
model: gpt-5.6-terra
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 01a03c22-b671-75b0-9e6b-52a12c375c95
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Question

In this repo, the CI job **"portability canary (ubuntu — advisory, never breakage)"** in
`.github/workflows/ci.yml` has been RED for a while — on `development` itself, not just on PRs.
It is marked advisory, so the overall run still reports success. That means the canary now signals
nothing: a real Linux portability regression would be invisible in the noise.

Two suites account for the failures, and BOTH fail for the same environmental reason — **GitHub's
ubuntu runner executes the job as root (EUID=0)**, so `chmod`-based negative assertions do not hold
(root writes a 0444 file and reads a 0000 file anyway):

1. `test/gh50-sandboxed-git-guard.sh` — **3 pass, 8 fail**. It makes a git config read-only and
   asserts the guard refuses (exit 2), that the refusal is named, that the working tree and config
   bytes are unchanged, that HEAD stays on main, and that no branch was created. Under root the
   write succeeds, so the guard never refuses and every downstream assertion collapses.
2. `test/security-scan.sh` — **33 pass, 2 fail**. Both failures are the "unreadable file" case:
   it chmods a file to 0000 and expects exactly one `[scan-error]` finding. Root reads it fine, so
   zero scan-error lines are emitted.

(There are also a few unrelated scattered FAILs in that job — `agy` not on PATH for marathon-drive,
a worktree-isolation case that does not reproduce, and a concurrent-lock race. Treat those as
out of scope background, but say so if you think they change the answer.)

## The decision

Which of these is the better engineering call for THIS repo, and why?

**Option A — fix at the root:** make the guards genuinely fail-closed under EUID=0, so the
production behavior the tests assert is actually true for a root user, and the tests then pass
honestly on both macOS and Linux.

**Option B — skip when EUID=0:** detect root and skip those specific assertions (or whole suites)
with an explicit, named SKIP, so the canary goes green and regains signal, while documenting that
the root case is untested.

## What a good answer looks like

- A clear pick (A, B, or a specific hybrid), with the reasoning that actually decides it.
- Consider: is the root case a REAL production scenario for this harness (does anyone run these
  guards as root — containers, CI, Docker), or is it purely a test-environment artifact? That
  distinction should drive the answer. Please check how the guards are actually invoked in the repo
  before assuming.
- The cost/benefit of each: what does Option A actually require in code, and what does Option B
  cost in lost coverage?
- The risk of the status quo (a permanently-red advisory job) versus either fix.
- Whether "advisory, never breakage" is even the right posture for this job, or whether a
  green-and-required canary would serve better.
- Anything either option would break or mislead about.

Please read the actual files (`test/gh50-sandboxed-git-guard.sh`, `test/security-scan.sh`,
`.github/workflows/ci.yml`, and whatever guard implementation they exercise) before answering.
This is ADVISORY ONLY — do not modify anything.

hook: SessionStart
hook: SessionStart Completed
codex
I’m inspecting the CI workflow, both suites, and the guard implementation to distinguish an environment-only test artifact from a real root-runtime contract.
exec
/bin/zsh -lc "pwd && sed -n '1,240p' WORKTREE-SAFETY.md && sed -n '1,260p' ROUTER.md && sed -n '1,220p' GUIDING-PRINCIPLES.md && sed -n '1,240p' /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge/skills/consult/SKILL.md" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z
 succeeded in 0ms:
/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z
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

mcp: codebase-memory-mcp/list_projects started
mcp: codebase-memory-mcp/list_projects (failed)
user cancelled MCP tool call
2026-08-26T03:35:15.724285Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
mcp: codebase-memory-mcp/index_repository started
mcp: codebase-memory-mcp/index_repository (failed)
user cancelled MCP tool call
2026-08-26T03:35:19.159327Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "rg -n -i -C 3 'sandboxed-git-guard|security-scan|portability canary|ubuntu|scan-error|EUID|chmod|read-only|unreadable' .github/workflows/ci.yml test/gh50-sandboxed-git-guard.sh test/security-scan.sh utils relay-automation githooks 2>/dev/null" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z
 succeeded in 0ms:
test/gh50-sandboxed-git-guard.sh-1-#!/usr/bin/env bash
test/gh50-sandboxed-git-guard.sh-2-set -uo pipefail
test/gh50-sandboxed-git-guard.sh-3-
test/gh50-sandboxed-git-guard.sh:4:# gh50-sandboxed-git-guard.sh — GH-50: a guarded tracking switch must refuse
test/gh50-sandboxed-git-guard.sh:5:# before it can rewrite the index or working tree when .git/config is read-only.
test/gh50-sandboxed-git-guard.sh-6-
test/gh50-sandboxed-git-guard.sh-7-HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
test/gh50-sandboxed-git-guard.sh-8-ROOT="$(cd "$HERE/.." && pwd)"
--
test/gh50-sandboxed-git-guard.sh-22-  fi
test/gh50-sandboxed-git-guard.sh-23-}
test/gh50-sandboxed-git-guard.sh-24-
test/gh50-sandboxed-git-guard.sh:25:echo "== test: gh50-sandboxed-git-guard =="
test/gh50-sandboxed-git-guard.sh-26-
test/gh50-sandboxed-git-guard.sh-27-WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh50-sandbox-guard.XXXXXX")"
test/gh50-sandboxed-git-guard.sh-28-. "$HERE/lib/fixture-guard.sh"
--
test/gh50-sandboxed-git-guard.sh-52-require_fixture_file "$CONFIG" "GH-50 config"
test/gh50-sandboxed-git-guard.sh-53-cp "$R/payload.txt" "$WORK/payload.before"
test/gh50-sandboxed-git-guard.sh-54-cp "$CONFIG" "$WORK/config.before"
test/gh50-sandboxed-git-guard.sh:55:chmod a-w "$CONFIG"
test/gh50-sandboxed-git-guard.sh-56-
test/gh50-sandboxed-git-guard.sh-57-OUT="$WORK/refusal.out"
test/gh50-sandboxed-git-guard.sh-58-"$GUARD" --repo "$R" --operation "git switch --track" -- \
test/gh50-sandboxed-git-guard.sh-59-  git -C "$R" switch --track -c tracked topic >"$OUT" 2>&1
test/gh50-sandboxed-git-guard.sh-60-rc=$?
test/gh50-sandboxed-git-guard.sh-61-
test/gh50-sandboxed-git-guard.sh:62:ok "guard refuses the read-only config with exit 2" test "$rc" -eq 2
test/gh50-sandboxed-git-guard.sh-63-ok "refusal is named and says the operation was not attempted" \
test/gh50-sandboxed-git-guard.sh-64-  grep -q "git-sandbox-guard: REFUSING.*not attempted (GH-50)" "$OUT"
test/gh50-sandboxed-git-guard.sh-65-ok "refusal names the config write problem" grep -q "config.*not writable" "$OUT"
--
test/gh50-sandboxed-git-guard.sh-77-
test/gh50-sandboxed-git-guard.sh-78-# Control: once config writes are possible, the wrapper must run the exact command rather
test/gh50-sandboxed-git-guard.sh-79-# than acting as a blanket branch-operation ban.
test/gh50-sandboxed-git-guard.sh:80:chmod u+w "$CONFIG"
test/gh50-sandboxed-git-guard.sh-81-"$GUARD" --repo "$R" --operation "git switch --track" -- \
test/gh50-sandboxed-git-guard.sh-82-  git -C "$R" switch --track -c tracked topic >"$WORK/control.out" 2>&1
test/gh50-sandboxed-git-guard.sh-83-control_rc=$?
--
test/gh50-sandboxed-git-guard.sh-86-ok "writable-config control switches to the new branch" \
test/gh50-sandboxed-git-guard.sh-87-  test "$(git -C "$R" symbolic-ref --short HEAD)" = tracked
test/gh50-sandboxed-git-guard.sh-88-
test/gh50-sandboxed-git-guard.sh:89:echo "  gh50-sandboxed-git-guard: $pass pass, $fail fail"
test/gh50-sandboxed-git-guard.sh-90-[ "$fail" -eq 0 ]
--
test/security-scan.sh-1-#!/usr/bin/env bash
test/security-scan.sh:2:# test/security-scan.sh — registered test for relay-automation/hooks/security-scan.sh (GH-64)
test/security-scan.sh-3-#
test/security-scan.sh-4-# Verifies:
test/security-scan.sh-5-#   (a) A known-BAD fixture triggers a non-zero exit AND emits findings to stderr.
--
test/security-scan.sh-11-set -euo pipefail
test/security-scan.sh-12-
test/security-scan.sh-13-HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
test/security-scan.sh:14:SCANNER="$HERE/../relay-automation/hooks/security-scan.sh"
test/security-scan.sh-15-
test/security-scan.sh-16-[ -f "$SCANNER" ] || { echo "  FAIL: scanner not found: $SCANNER" >&2; exit 1; }
test/security-scan.sh-17-[ -x "$SCANNER" ] || { echo "  FAIL: scanner not executable: $SCANNER" >&2; exit 1; }
--
test/security-scan.sh-20-# Test harness — mirrors _setup.sh style but self-contained (no tick infra).
test/security-scan.sh-21-# ---------------------------------------------------------------------------
test/security-scan.sh-22-
test/security-scan.sh:23:TEST_NAME="security-scan"
test/security-scan.sh-24-PASS=0
test/security-scan.sh-25-FAIL=0
test/security-scan.sh-26-
--
test/security-scan.sh-43-BAD_FIXTURE="$WORK/bad-fixture.sh"
test/security-scan.sh-44-cat > "$BAD_FIXTURE" <<'BADEOF'
test/security-scan.sh-45-#!/usr/bin/env bash
test/security-scan.sh:46:# This is a fixture for security-scan tests — NOT a real script.
test/security-scan.sh-47-
test/security-scan.sh-48-# R1: eval of unsanitized variable
test/security-scan.sh-49-UNSANITIZED="rm -rf /"
--
test/security-scan.sh-75-CLEAN_FIXTURE="$WORK/clean-fixture.sh"
test/security-scan.sh-76-cat > "$CLEAN_FIXTURE" <<'CLEANEOF'
test/security-scan.sh-77-#!/usr/bin/env bash
test/security-scan.sh:78:# This is a clean fixture for security-scan tests.
test/security-scan.sh-79-set -euo pipefail
test/security-scan.sh-80-
test/security-scan.sh-81-greet() {
--
test/security-scan.sh-225-  'api_key=hunter2supersecretvalue'
test/security-scan.sh-226-
test/security-scan.sh-227-# ---------------------------------------------------------------------------
test/security-scan.sh:228:# Regression (agy relay QA, 2026-07-01, [Should] + a self-caught fix-of-the-fix): an unreadable file
test/security-scan.sh-229-# (grep exit 2+, not the "no match" exit 1) must fail loud, not silently read as clean — AND the
test/security-scan.sh-230-# error report must not abort the rest of the scan under `set -e` (the first version of this fix
test/security-scan.sh-231-# propagated the error's nonzero return through _check() to scan_file() to main()'s file loop,
test/security-scan.sh:232:# silently ending the ENTIRE scan after the first unreadable file — worse than the bug it fixed).
test/security-scan.sh-233-# ---------------------------------------------------------------------------
test/security-scan.sh-234-
test/security-scan.sh:235:UNREADABLE_DIR="$WORK/unreadable-fixture"
test/security-scan.sh:236:mkdir -p "$UNREADABLE_DIR"
test/security-scan.sh:237:UNREADABLE_FILE="$UNREADABLE_DIR/locked.sh"
test/security-scan.sh:238:printf '#!/usr/bin/env bash\neval "$X"\n' > "$UNREADABLE_FILE"
test/security-scan.sh:239:OTHER_FILE="$UNREADABLE_DIR/z-also-bad.sh"
test/security-scan.sh-240-printf '#!/usr/bin/env bash\neval "$ALSO_BAD"\n' > "$OTHER_FILE"
test/security-scan.sh:241:chmod 000 "$UNREADABLE_FILE"
test/security-scan.sh-242-
test/security-scan.sh-243-RC=0
test/security-scan.sh:244:STDOUT_UNREAD="$WORK/stdout-unreadable.txt"
test/security-scan.sh:245:STDERR_UNREAD="$WORK/stderr-unreadable.txt"
test/security-scan.sh:246:bash "$SCANNER" --no-baseline "$UNREADABLE_DIR" >"$STDOUT_UNREAD" 2>"$STDERR_UNREAD" || RC=$?
test/security-scan.sh:247:chmod 644 "$UNREADABLE_FILE"
test/security-scan.sh-248-
test/security-scan.sh:249:[[ "$RC" -ne 0 ]] && pass "unreadable file: scanner fails loud (exit $RC), not silently clean" \
test/security-scan.sh:250:  || fail "unreadable file: scanner should fail, got exit 0"
test/security-scan.sh:251:grep -q "scan-error" "$STDERR_UNREAD" 2>/dev/null \
test/security-scan.sh:252:  && pass "unreadable file: flagged with [scan-error], not silently skipped" \
test/security-scan.sh:253:  || fail "unreadable file: no [scan-error] finding: $(cat "$STDERR_UNREAD")"
test/security-scan.sh:254:[[ "$(grep -c "scan-error" "$STDERR_UNREAD" 2>/dev/null)" -eq 1 ]] \
test/security-scan.sh:255:  && pass "unreadable file: scan-error reported once per file, not once per rule" \
test/security-scan.sh:256:  || fail "unreadable file: expected 1 scan-error line, got $(grep -c "scan-error" "$STDERR_UNREAD" 2>/dev/null)"
test/security-scan.sh-257-grep -qF "ALSO_BAD" "$STDERR_UNREAD" 2>/dev/null \
test/security-scan.sh:258:  && pass "unreadable file: scan CONTINUES to the next file (not silently aborted mid-scan)" \
test/security-scan.sh:259:  || fail "unreadable file: scan stopped before reaching the next file — set -e propagation bug"
test/security-scan.sh-260-
test/security-scan.sh-261-# ---------------------------------------------------------------------------
test/security-scan.sh-262-# Regression (agy relay QA round 2, 2026-07-01, [Should]): the per-occurrence R7 rewrite's unquoted
--
test/security-scan.sh-332-# GH-64 active gate: the REAL repo, scanned with the checked-in baseline, must be clean. This is
test/security-scan.sh-333-# what turns the scanner from an advisory tool into a genuine blocking gate in validate.sh — any
test/security-scan.sh-334-# newly introduced eval/secret/curl-pipe pattern fails validate.sh until it's fixed or (after human
test/security-scan.sh:335:# review) added to relay-automation/hooks/security-scan-baseline.txt.
test/security-scan.sh-336-# ---------------------------------------------------------------------------
test/security-scan.sh-337-
test/security-scan.sh-338-RC=0
--
test/security-scan.sh-345-# ---------------------------------------------------------------------------
test/security-scan.sh-346-
test/security-scan.sh-347-echo ""
test/security-scan.sh:348:echo "security-scan: $PASS pass, $FAIL fail"
test/security-scan.sh-349-[[ "$FAIL" -eq 0 ]]
--
.github/workflows/ci.yml-44-#        gh workflow run ci.yml --ref <branch>
.github/workflows/ci.yml-45-#        gh run watch <run-id>
.github/workflows/ci.yml-46-#
.github/workflows/ci.yml:47:# 2. AN ADVISORY JOB THAT DIES EARLY STILL REPORTS THE RUN GREEN. The ubuntu canary below is
.github/workflows/ci.yml-48-#    advisory by design ("never breakage") and ends in a verdict step that always passes. That
.github/workflows/ci.yml-49-#    means a FAILING canary is invisible at the run level. It happened: from the 2026-08-17 re-arm
.github/workflows/ci.yml-50-#    until 2026-08-21, `utils/fuzzing/fuzz-loop.sh` had no shebang, shellcheck raised SC2148 at
--
.github/workflows/ci.yml-76-# GH-544 deliberately removed `push:` and `pull_request:` while the source repository was private.
.github/workflows/ci.yml-77-# That bridge had one explicit end condition: the repository becomes public. HiQS-Suite/XYZ-forge
.github/workflows/ci.yml-78-# is public, so automatic triggers are restored here. The local pre-push gate remains useful as the
.github/workflows/ci.yml:79:# earliest signal; hosted CI restores independent attestation and the Linux portability canary.
.github/workflows/ci.yml-80-#
.github/workflows/ci.yml-81-# WHY: measured in #509/#528 — Aug 1-14 cost $21.99 gross / $10.00 billed, exhausting the 2,000
.github/workflows/ci.yml-82-# included minutes on Aug 11 and hitting the $10 spending limit on Aug 14, which blocked Actions
--
.github/workflows/ci.yml-84-#
.github/workflows/ci.yml-85-# THE BRIDGE HAS ENDED. The re-arm keeps the constraints the private-phase analysis established:
.github/workflows/ci.yml-86-#   1. `push:` and `pull_request:` cover main and development. The macOS job itself remains guarded
.github/workflows/ci.yml:87:#      to a push on main; pull requests receive only the Ubuntu portability canary.
.github/workflows/ci.yml-88-#   2. Expect a BATCH of accumulated Linux portability drift on the first green-field run. The local
.github/workflows/ci.yml:89:#      gate is macOS, so the platform we ship to stayed covered — the ubuntu canary did not, and drift
.github/workflows/ci.yml-90-#      has been accumulating unreported since this date. That backlog is the known, accepted cost of
.github/workflows/ci.yml-91-#      this decision, not a surprise.
.github/workflows/ci.yml-92-#   3. The GH-509 macOS boundary is again the promotion witness for an exact main commit.
--
.github/workflows/ci.yml-121-  # WHY `workflow_dispatch` WAS REMOVED (2026-08-13, measured — this was the original design and it
.github/workflows/ci.yml-122-  # did not survive contact with the invoice). The theory was that a dispatch costs "well under a
.github/workflows/ci.yml-123-  # dollar a handful of times a month". The org's actual August usage says otherwise: macOS 3-core
.github/workflows/ci.yml:124:  # 75 minutes = **$4.65 net**, against Ubuntu's 2,740 minutes = $4.44 net. Seventy-five macOS minutes
.github/workflows/ci.yml-125-  # cost more than 2,740 Linux minutes, because macOS bills ~10x AND draws no included-minute discount
.github/workflows/ci.yml-126-  # on a private repo. Three dispatches on one branch in one day consumed roughly half a $10 monthly
.github/workflows/ci.yml-127-  # budget. The gating was correct; what was missing was any brake on how often the deliberate trigger
--
.github/workflows/ci.yml-201-            note="This commit is promotion-qualified (GH-509 §6). Cite this SHA, not this run."
.github/workflows/ci.yml-202-          else
.github/workflows/ci.yml-203-            line="MACOS-BOUNDARY: red ${GITHUB_SHA}"
.github/workflows/ci.yml:204:            note="NOT promotable. Unlike the ubuntu canary, this ran on the platform we ship to — a failure here is a real defect for real users."
.github/workflows/ci.yml-205-          fi
.github/workflows/ci.yml-206-          echo "$line"
.github/workflows/ci.yml-207-          echo "$note"
.github/workflows/ci.yml-208-          { echo "### $line"; echo; echo "$note"; } >> "$GITHUB_STEP_SUMMARY"
.github/workflows/ci.yml-209-
.github/workflows/ci.yml:210:  # GH-509 Phase 2 — this job is a PORTABILITY CANARY, not a gate.
.github/workflows/ci.yml-211-  #
.github/workflows/ci.yml-212-  # XYZ ships to macOS developers. Linux and Windows are on the roadmap and are not here yet, so a
.github/workflows/ci.yml:213:  # failure on ubuntu is portability DRIFT, not breakage: it says "this would not work on the platform
.github/workflows/ci.yml-214-  # we do not support yet." Every one of the three CI failures on 2026-08-12 was of exactly that shape
.github/workflows/ci.yml-215-  # (agent CLIs absent from the runner), and treating them as breakage is what produced five hours of
.github/workflows/ci.yml-216-  # unread red across eight commits — which is worse than no signal at all, because it trains everyone
--
.github/workflows/ci.yml-230-  # elsewhere: the canary's status is a line in the promotion output, consulted at the moment a human
.github/workflows/ci.yml-231-  # is already deciding something. If two consecutive promotions ship with drift named and unresolved,
.github/workflows/ci.yml-232-  # this job has proven it is not being actioned and should be deleted rather than kept as decoration.
.github/workflows/ci.yml:233:  canary-ubuntu:
.github/workflows/ci.yml:234:    name: portability canary (ubuntu — advisory, never breakage)
.github/workflows/ci.yml:235:    runs-on: starsling-ubuntu-24.04-8
.github/workflows/ci.yml-236-    continue-on-error: true
.github/workflows/ci.yml-237-    steps:
.github/workflows/ci.yml-238-      - name: Check out repo
--
.github/workflows/ci.yml-382-
.github/workflows/ci.yml-383-      # GH-232: the acting-agent's user/keychain config and default `git init` branch name are
.github/workflows/ci.yml-384-      # macOS-dev-machine assumptions baked into several fixture-driven tests (e.g. archive-writers.sh,
.github/workflows/ci.yml:385:      # xyz-vendor.sh do a bare `git init` and expect the resulting branch to be "main"). ubuntu-latest's
.github/workflows/ci.yml-386-      # git has no global identity and may default new repos to a non-"main" branch, so prepare both
.github/workflows/ci.yml-387-      # here rather than touch the tests themselves (out of scope for this lane).
.github/workflows/ci.yml-388-      - name: Prepare git environment for fixture-driven tests
--
.github/workflows/ci.yml-431-          done
.github/workflows/ci.yml-432-          exit "$FAILED"
.github/workflows/ci.yml-433-
.github/workflows/ci.yml:434:      # GH-232: PR #231 ran the full ./validate.sh suite on ubuntu-latest for the first time and
.github/workflows/ci.yml:435:      # found ~12 failures, assumed to be Ubuntu-environment-only and scoped out of CI. Re-diagnosed
.github/workflows/ci.yml:436:      # directly against a real ubuntu:latest container (not guessed at from macOS): almost all were
.github/workflows/ci.yml-437-      # masked by two things, now both fixed — (1) marathon.sh/marathon-drive.sh (and dependents
.github/workflows/ci.yml-438-      # debug-mantra.sh/driver-lock.sh) used a BSD-only `sed -i ''` invocation that mis-parses under
.github/workflows/ci.yml-439-      # GNU sed; (2) driver-lock.sh/xyz-harness-hooks.sh stubbed CLAUDE_BIN/AGY_BIN but not
.github/workflows/ci.yml-440-      # CODEX_BIN — the actual default builder — so they only "passed" locally because a real `codex`
.github/workflows/ci.yml:441:      # binary happened to be on the developer's own PATH, masking the gap; ubuntu CI has no such
.github/workflows/ci.yml-442-      # binary. path-integrity.sh/archive-writers.sh/relay-file-seeding-visibility.sh/xyz-vendor.sh/
.github/workflows/ci.yml:443:      # hq.sh/relay-pkg-freshness.sh all passed cleanly once re-tested for real — no ubuntu-specific
.github/workflows/ci.yml-444-      # bug in any of them. Only registry-lock-concurrency.sh (GH-72, a documented 16-concurrent-writer
.github/workflows/ci.yml-445-      # lock-contention flake under CI load, unrelated to this issue) stays skipped.
.github/workflows/ci.yml-446-      - name: Run validate.sh suite (minus a documented flaky test)
--
.github/workflows/ci.yml-481-      #
.github/workflows/ci.yml-482-      # The line is deliberately greppable and deliberately does NOT say "failed" or "error": on this
.github/workflows/ci.yml-483-      # platform those words are wrong. This job reports on an operating system we do not ship to yet.
.github/workflows/ci.yml:484:      - name: Portability canary verdict
.github/workflows/ci.yml-485-        if: always()
.github/workflows/ci.yml-486-        run: |
.github/workflows/ci.yml-487-          set -euo pipefail
--
githooks/pre-push-2-# pre-push — run the gate before anything reaches the remote. (GH-544)
githooks/pre-push-3-#
githooks/pre-push-4-# WHY THIS EXISTS: the push boundary gives the author the earliest complete local signal. Hosted CI
githooks/pre-push:5:# is re-armed now that XYZ-forge is public (#16), but it is downstream and the Ubuntu PR lane is
githooks/pre-push-6-# advisory; local commits remain free and ungated on purpose, while a push is checked before it
githooks/pre-push-7-# leaves the machine.
githooks/pre-push-8-#
--
githooks/pre-push-202-  The failing checks are named in the output above.
githooks/pre-push-203-
githooks/pre-push-204-  Hosted CI may run after the push, but this local boundary is the earliest full signal and the
githooks/pre-push:205:  Ubuntu pull-request lane is advisory. Do not use downstream CI as a reason to ignore this red.
githooks/pre-push-206-
githooks/pre-push-207-  To push anyway (and you may have a good reason — a WIP branch, a known-red baseline):
githooks/pre-push-208-    git push --no-verify
--
githooks/install.sh-105-esac
githooks/install.sh-106-
githooks/install.sh-107-[ -f "$REPO/$REL/pre-push" ] || { echo "githooks/install.sh: $REL/pre-push not found" >&2; exit 3; }
githooks/install.sh:108:chmod +x "$REPO/$REL/pre-push" 2>/dev/null || true
githooks/install.sh-109-
githooks/install.sh-110-# `core.hooksPath` must be UNSET for the stub to be reached — it overrides the default hooks
githooks/install.sh-111-# directory entirely. Clear our own legacy value; refuse to touch anyone else's.
--
githooks/install.sh-196-exit 1
githooks/install.sh-197-STUB_EOF
githooks/install.sh-198-
githooks/install.sh:199:chmod +x "$STUB" || { echo "githooks/install.sh: cannot make $STUB executable" >&2; exit 3; }
githooks/install.sh-200-
githooks/install.sh-201-echo "githooks: installed — $STUB"
githooks/install.sh-202-echo "  It runs the gate before any push, on EVERY branch in this clone (and its worktrees),"
--
utils/signal-triage.sh-13-# ├─────────┼──────────┼──────────────────────────────────────────────────────────────────────────┤
utils/signal-triage.sh-14-# │ rule-2  │ bug      │ deterministic failure of existing behaviour: validate.sh test FAIL,      │
utils/signal-triage.sh-15-# │         │          │ canary/fixture rejection, relay containment revert (exit 6), or           │
utils/signal-triage.sh:16:# │         │          │ security-scan failure (source: "security-scan" recorded — NOT a separate  │
utils/signal-triage.sh-17-# │         │          │ bucket per GP #7)                                                         │
utils/signal-triage.sh-18-# ├─────────┼──────────┼──────────────────────────────────────────────────────────────────────────┤
utils/signal-triage.sh-19-# │ rule-3  │ drift    │ reality diverges from declared state without a hard failure: watchdog    │
--
utils/signal-triage.sh-34-# Required flags:
utils/signal-triage.sh-35-#   --source <src>    Signal source. One of:
utils/signal-triage.sh-36-#                       validate-fail       validate.sh test FAIL
utils/signal-triage.sh:37:#                       security-scan       security scan finding
utils/signal-triage.sh-38-#                       relay-exit6         relay containment revert (exit 6)
utils/signal-triage.sh-39-#                       canary-reject       canary/fixture rejection
utils/signal-triage.sh-40-#                       watchdog-parked     watchdog parked_suspects[] record
--
utils/signal-triage.sh-149-  if [[ -n "$DETAIL" ]]; then EVIDENCE="${EVIDENCE} | ${DETAIL}"; fi
utils/signal-triage.sh-150-  DEDUPE_FIELD=""
utils/signal-triage.sh-151-
utils/signal-triage.sh:152:elif [[ "$SIGNAL_SOURCE" == "security-scan" ]]; then
utils/signal-triage.sh-153-  # Security findings fold into bug (NOT a separate bucket — GP #7)
utils/signal-triage.sh-154-  CATEGORY="bug"
utils/signal-triage.sh-155-  SEVERITY="high"
utils/signal-triage.sh:156:  EVIDENCE="rule-2-bug / security-scan"
utils/signal-triage.sh-157-  if [[ -n "$DETAIL" ]]; then EVIDENCE="${EVIDENCE}: ${DETAIL}"; fi
utils/signal-triage.sh-158-  DEDUPE_FIELD=""
utils/signal-triage.sh-159-
--
utils/signal-triage.sh-203-
utils/signal-triage.sh-204-else
utils/signal-triage.sh-205-  echo "$SCRIPT_NAME: unknown --source value: '$SIGNAL_SOURCE'" >&2
utils/signal-triage.sh:206:  echo "$SCRIPT_NAME: valid sources: validate-fail, security-scan, relay-exit6, canary-reject, watchdog-parked, pdda-sync, dependency-drift, manual, informational" >&2
utils/signal-triage.sh-207-  exit 2
utils/signal-triage.sh-208-fi
utils/signal-triage.sh-209-
--
relay-automation/harvest-findings.sh-1-#!/usr/bin/env bash
relay-automation/harvest-findings.sh-2-# harvest-findings.sh — extract `### Side Finding` blocks from a relay file and append them to
relay-automation/harvest-findings.sh:3:# debug.log as PDDA-output-contract JSONL findings. Read-only on the relay; append-only on
relay-automation/harvest-findings.sh-4-# debug.log; NO network. Best-effort — a broken harvest must never fail a phase.
relay-automation/harvest-findings.sh-5-# Usage: harvest-findings.sh --relay FILE [--scope S] [--repo R] [--out debug.log]
relay-automation/harvest-findings.sh-6-set -u
--
relay-automation/claude-turn.sh-63-#
relay-automation/claude-turn.sh-64-# Tool allowlist split:
relay-automation/claude-turn.sh-65-#   builder (this shim)                   → "Bash,Read,Edit,Write"  (needs to mutate the artifact)
relay-automation/claude-turn.sh:66:#   reviewers (codex-turn, gemini-turn)   → "Bash,Read"              (read-only; no write surface)
relay-automation/claude-turn.sh-67-# rtl_enforce is the real guard either way; the allowlist is a second, tighter layer.
relay-automation/claude-turn.sh-68-#
relay-automation/claude-turn.sh-69-#   RELAY_TURN_TIMEOUT_S — per-turn wall-clock ceiling in seconds (default: 900, raised from 600 by
--
relay-automation/claude-turn.sh-194-      printf 'printf "blocked: %%s is off-limits to a headless builder turn (CLAUDE_BLOCK_CMDS)\\n" %q >&2\n' "$c"
relay-automation/claude-turn.sh-195-      printf 'exit 127\n'
relay-automation/claude-turn.sh-196-    } > "$shadow_dir/$c"
relay-automation/claude-turn.sh:197:    chmod +x "$shadow_dir/$c"
relay-automation/claude-turn.sh-198-  done
relay-automation/claude-turn.sh-199-fi
relay-automation/claude-turn.sh-200-
--
relay-automation/DUELING-CLAUDES.md-143-(`dangerouslyDisableSandbox`) is a SEPARATE per-command approval that **no `permissions.allow`
relay-automation/DUELING-CLAUDES.md-144-entry can suppress** — so a loop that bypasses the sandbox prompts on every single tick, forever.
relay-automation/DUELING-CLAUDES.md-145-
relay-automation/DUELING-CLAUDES.md:146:`poll.sh --dry-run` is **read-only** (a `git -C <root> status` + a `tick` read) and runs fine INSIDE
relay-automation/DUELING-CLAUDES.md-147-the sandbox — confirmed in live runs. So:
relay-automation/DUELING-CLAUDES.md-148-
relay-automation/DUELING-CLAUDES.md-149-- **Run the poll sandboxed** — do NOT pass a sandbox bypass on the poll command. The **target
--
relay-automation/marathon-ls.sh-1-#!/usr/bin/env bash
relay-automation/marathon-ls.sh:2:# marathon-ls.sh — cross-repo marathon monitor engine (read-only).
relay-automation/marathon-ls.sh-3-#
relay-automation/marathon-ls.sh-4-# Enumerates every repo known to the xyz registry (hub + col-5 coordinated_repo),
relay-automation/marathon-ls.sh-5-# resolves its relay-driver lock path, derives LIVE/STALE/IDLE/GONE state, finds
--
relay-automation/README.md-29-| `pi-turn.sh` | **GH-295** headless turn-taker for **Pi** (`pi.dev`, package `@earendil-works/pi-coding-agent`; `pi --provider … --model … --mode json -p`); thin dispatch wrapper over `relay-turn-lib.sh`. Same posture as agy (no built-in sandbox — containment is worktree isolation + `rtl_enforce`), but genuinely better on cost visibility: `--mode json`'s JSONL stream carries real per-call `usage`/`cost` fields, so this is the first non-Claude lane with actual `tick cost --tool pi` capture. `PI_MODEL` has **no default** by design (GH-280/aider#5486 class of bug); the operator must set it explicitly. |
relay-automation/README.md-30-| `aider-turn.sh` | Headless turn-taker for **Aider ↔ OpenRouter** (`aider --model openrouter/… --message`) — an OpenAI-standard lane discrete from Codex. Same `relay-turn-lib.sh` containment; because Aider is a file-editor (no mid-turn shell), the SHIM performs the tick token ops itself and runs Aider with `--no-auto-commits` (the harness owns the commit). Set `OPENROUTER_API_KEY` + `AIDER_MODEL` (e.g. `openrouter/anthropic/claude-3.5-sonnet`, `openrouter/openai/gpt-4o`, `openrouter/deepseek/deepseek-chat`). Works in **both** a marathon `--builder aider` lane AND a plain `/relay` — it routes through the shared `marathon-agent.sh` dispatcher (`relay-drive.sh`'s `--agent-cmd`), so a driven relay with `RELAY_AGENT=aider` fires it just like Codex/agy. |
relay-automation/README.md-31-| `deep-research.mjs` | **Provider-agnostic grounded web search** (GH-87/GH-129): one normalized `{answer, citations, query, provider, model, raw}` contract over two backends — **Agy Gemini Search** (default; `agy` CLI in a throwaway tmpdir, side-effect free) and **Perplexity Sonar via OpenRouter** (`--provider openrouter`; same `OPENROUTER_API_KEY` gateway convention as the Aider lane, model `perplexity/sonar` overridable via `DEEP_RESEARCH_OPENROUTER_MODEL`, `--search-context-size` → Perplexity's native `web_search_options.search_context_size`). Fail-closed typed errors (`binary_missing`/`missing_api_key`/`timeout`/`backend_error`/`empty_output`) — never a silent cross-provider fallback. Run sandbox-OFF; prefer `--search-context-size medium` with focused single-intent queries (`high` risks runaway grounding near the 120s `DEEP_RESEARCH_TIMEOUT_MS` cap — see #124). Wall-clock cap is `DEEP_RESEARCH_TIMEOUT_MS`, default `120000` (120s); override upward (e.g. `DEEP_RESEARCH_TIMEOUT_MS=180000`) when a thorough `high`-context, multi-claim query genuinely needs more headroom — the default itself is unchanged. |
relay-automation/README.md:32:| `consult.sh` | Parallel read-only consult: asks the same question to **Codex, agy, and (opt-in) Aider↔OpenRouter** (`--models codex,agy,aider`), captures each transcript, and leaves synthesis to the caller. Advisory-only; also the engine behind `relay-drive.sh --consult-verify`. |
relay-automation/README.md-33-| `xyz-vendor.sh` / `xyz-sync.sh` | Vendoring pair for `.xyz/` copies materialized into another repo. `xyz-vendor.sh <target-repo>` mirrors this harness into `<target-repo>/.xyz/` and stamps a row in the local `registry.tsv` (`install_dir`, `last_install_utc`, `tick_version`, `source_commit`, `coordinated_repo`) at that moment. `xyz-sync.sh list \| update \| delete \| check` manages those registered rows: `list` shows them, `update <dir>\|--all` re-vendors, `delete <dir>\|--all [--yes]` removes a copy and prunes its row. **`check <dir>\|--all`** (GH-96) is report-only drift detection: it recomputes the CURRENT `tick_version`/`source_commit` this harness ships and compares against each row's recorded pair — a mismatch in **either** field counts as drift. Exact match on both → a silent `ok` line; drift → a warning naming the drifted field(s) and both recorded/current values. Never a hard error, never an auto-pull — updates land only via an explicit `update`/`xyz-vendor.sh` re-run (pinned + manual by design). This is the harness-side "is this install stale?" signal a downstream consumer (e.g. rebalance-OS) can poll instead of guessing. |
relay-automation/README.md-34-
relay-automation/README.md-35-## Adding a new consult advisor (GH-178 A1)
--
relay-automation/target-checks.sh-92-  # `-r` and `set -o pipefail` are both from the agy cross-vendor relay (GH-268 item 9):
relay-automation/target-checks.sh-93-  #   * without -r, GNU xargs runs the command ONCE on empty input, so `php -l` with no arguments
relay-automation/target-checks.sh-94-  #     reads stdin and HANGS — permanently blocking the lane. BSD/macOS xargs does not do this,
relay-automation/target-checks.sh:95:  #     which is why it never showed up locally; CI is ubuntu. -r is accepted (no-op) on macOS.
relay-automation/target-checks.sh-96-  #   * `bash -c` does not inherit this script's pipefail, so a `find` that fails (permission
relay-automation/target-checks.sh-97-  #     denied on a subtree) would be masked by a passing xargs and the gate would report green.
relay-automation/target-checks.sh-98-  add "php-lint" "php" \
--
relay-automation/codex-turn.sh-131-
relay-automation/codex-turn.sh-132-# Run the Codex turn headless (token ops + edit the relay file; NO git), then enforce the boundary.
relay-automation/codex-turn.sh-133-# CODEX_FLAGS gives the turn enough autonomy to actually write on a fresh device (default sandbox is
relay-automation/codex-turn.sh:134:# read-only); operator-overridable for tighter/looser policies.
relay-automation/codex-turn.sh-135-# GH-106: default adds `-c approval_policy=never` to the sandbox flag so a headless run no longer
relay-automation/codex-turn.sh-136-# hangs on an interactive approval prompt until RELAY_TURN_TIMEOUT_S kills it (exit 7). Keeps the
relay-automation/codex-turn.sh-137-# workspace-write sandbox restriction (still can't touch outside the workspace) — fully overridable.
--
utils/timeline/README.md-1-# utils/timeline — RELEASES ledger → timeline viewer (GH-103 spike)
utils/timeline/README.md-2-
utils/timeline/README.md:3:Read-only projection of `releases.db` onto the timeline-ui rail (release nodes on a
utils/timeline/README.md-4-horizontal trunk, manifest cards in lanes). See
utils/timeline/README.md-5-`PROJECT/1-INBOX/GH-103-TIMELINE-LEDGER-SPIKE.md`; overlaps queued #75
utils/timeline/README.md-6-(`releases dashboard` verb).
--
utils/timeline/README.md-19-- `--preview [PATH]` — the on-demand snapshot: current DB state baked into one
utils/timeline/README.md-20-  self-contained `RELEASES-PREVIEW.html` (default: repo root). Generated artifact —
utils/timeline/README.md-21-  regenerate rather than edit.
utils/timeline/README.md:22:- `--serve PORT` — live mode: `/data.json` re-queries the DB (read-only) on every
utils/timeline/README.md-23-  request; no stale file in the path. The browser cannot read SQLite directly; this
utils/timeline/README.md-24-  is the one-source equivalent.
utils/timeline/README.md-25-- Full export writes `temp/timeline/`: `data.json` (the viewer's data contract),
--
utils/timeline/README.md-39-
utils/timeline/README.md-40-## Guarantees & limits
utils/timeline/README.md-41-
utils/timeline/README.md:42:- Opens the DB with SQLite's read-only URI (`mode=ro`): no writer lock, no generation
utils/timeline/README.md-43-  bump, no receipt — safe to run mid-merge.
utils/timeline/README.md-44-- Cards lead with the release's own sentence (first sentence of
utils/timeline/README.md-45-  `releases.description`); the exit criterion renders below as the machine contract.
--
relay-automation/aider-turn.sh-175-# block becomes writable, regardless of role — a reviewer that spots a referenced file in the diff can
relay-automation/aider-turn.sh-176-# emit an edit for it, and the harness's all-or-nothing containment then discards the WHOLE turn
relay-automation/aider-turn.sh-177-# (including the correctly-scoped relay-file edit) when that off-lane write is caught. --read is
relay-automation/aider-turn.sh:178:# structurally read-only in Aider even under --yes-always, so this gives full context with no writable
relay-automation/aider-turn.sh-179-# surface — the build/fix path (ALLOW_PATHS set) is completely untouched.
relay-automation/aider-turn.sh-180-read_args=()
relay-automation/aider-turn.sh-181-if [[ -z "${ALLOW_PATHS:-}" && -n "${RTL_ARTIFACT:-}" && -f "$RTL_ARTIFACT" ]]; then
--
relay-automation/marathon-detail.sh-1-#!/usr/bin/env bash
relay-automation/marathon-detail.sh:2:# marathon-detail.sh <repo> — preview for ONE repo path (read-only).
relay-automation/marathon-detail.sh-3-#
relay-automation/marathon-detail.sh-4-# Prints:
relay-automation/marathon-detail.sh-5-#   - STATUS: / NEXT: lines from the newest marathon-system/*/RELAY.md (falling back to phases/) (if any)
--
relay-automation/marathon-closeout.sh-8-#   4  PR checks are not green or GitHub reports the PR is not mergeable
relay-automation/marathon-closeout.sh-9-#
relay-automation/marathon-closeout.sh-10-# Dry-run deliberately requires --head so it can render the complete command
relay-automation/marathon-closeout.sh:11:# sequence without invoking git or gh, including read-only discovery commands.
relay-automation/marathon-closeout.sh-12-set -euo pipefail
relay-automation/marathon-closeout.sh-13-
relay-automation/marathon-closeout.sh-14-SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
--
relay-automation/relay-drive.sh-207-  --consult-verify    After each turn, invoke consult.sh to independently challenge the
relay-automation/relay-drive.sh-208-                      turn-taker's VERDICT. Fires 1-2 real API calls per turn (codex +
relay-automation/relay-drive.sh-209-                      gemini). Do NOT use in CI or budget-sensitive runs.
relay-automation/relay-drive.sh:210:  --artifact-file P   Seed an external read-only artifact (a cross-repo PR/diff or any file) into the
relay-automation/relay-drive.sh-211-                      isolated worktree at .relay-artifacts/<basename> so the reviewer can READ it
relay-automation/relay-drive.sh-212-                      without it being committed into the target repo. Requires worktree isolation
relay-automation/relay-drive.sh-213-                      (the default). The reviewer may not edit it (an edit fails the turn). Implements #15.
--
relay-automation/relay-drive.sh-397-  done < <(relay_setup_section_lines)
relay-automation/relay-drive.sh-398-}
relay-automation/relay-drive.sh-399-
relay-automation/relay-drive.sh:400:# GH-31 / #15: a read-only artifact under review. Absolutize it (the shim runs with a different CWD)
relay-automation/relay-drive.sh-401-# and export it so relay-turn-lib seeds it into the isolated worktree. It only works under isolation —
relay-automation/relay-drive.sh-402-# warn loudly if isolation is off, so the reviewer isn't left silently unable to see it.
relay-automation/relay-drive.sh-403-if [[ -n "$ARTIFACT_FILE" ]]; then
--
relay-automation/hooks/security-scan-baseline.txt:1:# security-scan-baseline.txt — GH-64 pre-approved findings
relay-automation/hooks/security-scan-baseline.txt-2-#
relay-automation/hooks/security-scan-baseline.txt:3:# Hand-reviewed and hand-maintained (relay-automation/hooks/security-scan.sh never writes this
relay-automation/hooks/security-scan-baseline.txt-4-# file). Format: <file>	<rule>	<exact matched line text> — one entry per line, tab-separated.
relay-automation/hooks/security-scan-baseline.txt-5-# A finding here is still PRINTED (labeled "baselined"), just doesn't fail the scan — nothing is
relay-automation/hooks/security-scan-baseline.txt-6-# hidden, per GUIDING-PRINCIPLES.md #8. Matching is by exact line TEXT, not line number: a
relay-automation/hooks/security-scan-baseline.txt-7-# reformatted flagged line drops out of the baseline and must be re-reviewed (deliberate).
relay-automation/hooks/security-scan-baseline.txt-8-#
relay-automation/hooks/security-scan-baseline.txt:9:# To review/regenerate candidate rows: bash relay-automation/hooks/security-scan.sh --no-baseline --tsv
relay-automation/hooks/security-scan-baseline.txt-10-# Every row below was reviewed 2026-07-01 (GH-64): each is a doc/prose comment matching a pattern
relay-automation/hooks/security-scan-baseline.txt-11-# in TEXT (not an actual secret/credential), a reviewed operator-configured dispatcher eval
relay-automation/hooks/security-scan-baseline.txt-12-# (poll.sh/relay-drive.sh/marathon-drive.sh/improve-loop.sh — trusted config, not attacker input),
relay-automation/hooks/security-scan-baseline.txt:13:# or the security-scan test suite's own intentional fixtures. No real secret leak in any row.
relay-automation/hooks/security-scan-baseline.txt-14-#
relay-automation/hooks/security-scan-baseline.txt:15:relay-automation/hooks/security-scan.sh	eval-unsanitized	#   R1  eval of variable / unsanitized input     eval "$foo" / eval $foo
relay-automation/hooks/security-scan-baseline.txt:16:relay-automation/hooks/security-scan.sh	eval-unsanitized	# Matches: eval "$foo", eval $foo, eval "$(…)", eval $(…)
relay-automation/hooks/security-scan-baseline.txt:17:relay-automation/hooks/security-scan.sh	pipe-remote-shell	#   R2  piped remote execution                   curl/wget ... | sh/bash
relay-automation/hooks/security-scan-baseline.txt:18:relay-automation/hooks/security-scan.sh	credential-literal	password=/secret=/api_key=
relay-automation/hooks/security-scan-baseline.txt:19:relay-automation/hooks/security-scan.sh	credential-literal	api_key=realsecret`,
relay-automation/hooks/security-scan-baseline.txt:20:relay-automation/hooks/security-scan.sh	credential-literal	password="pw secret"
relay-automation/hooks/security-scan-baseline.txt-21-relay-automation/improve-loop.sh	eval-unsanitized	if ! eval "$ORACLE_CMD" >/dev/null 2>&1; then echo "improve-loop: baseline FAILS the oracle — refusing to optimize a broken artifact" >&2; exit 3; fi
relay-automation/hooks/security-scan-baseline.txt-22-relay-automation/improve-loop.sh	eval-unsanitized	  eval "$BUILD_CMD" >/dev/null 2>&1 || true
relay-automation/hooks/security-scan-baseline.txt-23-relay-automation/improve-loop.sh	eval-unsanitized	  op=1; eval "$ORACLE_CMD" >/dev/null 2>&1 || op=0
--
relay-automation/hooks/security-scan-baseline.txt-39-test/relay-dep-drift.sh	eval-unsanitized	ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
relay-automation/hooks/security-scan-baseline.txt-40-test/relay-turn-handoff.sh	eval-unsanitized	ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
relay-automation/hooks/security-scan-baseline.txt-41-test/relay-xyz-skill-guard.sh	eval-unsanitized	run "sess-loc" Bash 'eval "$(bash skills/relay-xyz/find-harness.sh --env)"'
relay-automation/hooks/security-scan-baseline.txt:42:test/security-scan.sh	eval-unsanitized	eval "$UNSANITIZED"
relay-automation/hooks/security-scan-baseline.txt:43:test/security-scan.sh	eval-unsanitized	check_pattern "eval-var"         'eval "$MYVAR"'
relay-automation/hooks/security-scan-baseline.txt:44:test/security-scan.sh	eval-unsanitized	check_pattern "eval-dollar"      'eval $MYVAR'
relay-automation/hooks/security-scan-baseline.txt:45:test/security-scan.sh	pipe-remote-shell	curl https://example.com/install.sh | bash
relay-automation/hooks/security-scan-baseline.txt:46:test/security-scan.sh	pipe-remote-shell	check_pattern "pipe-curl-sh"     'curl https://example.com/x.sh | sh'
relay-automation/hooks/security-scan-baseline.txt:47:test/security-scan.sh	pipe-remote-shell	check_pattern "pipe-wget-bash"   'wget -qO- http://x.io/go.sh | bash'
relay-automation/hooks/security-scan-baseline.txt:48:test/security-scan.sh	aws-access-key	AWS_KEY="AKIAIOSFODNN7EXAMPLE"
relay-automation/hooks/security-scan-baseline.txt:49:test/security-scan.sh	aws-access-key	check_pattern "aws-key"          'export KEY=AKIAIOSFODNN7EXAMPLE'
relay-automation/hooks/security-scan-baseline.txt:50:test/security-scan.sh	pem-private-key	echo "-----BEGIN RSA PRIVATE KEY-----"
relay-automation/hooks/security-scan-baseline.txt:51:test/security-scan.sh	pem-private-key	check_pattern "pem-rsa"          '-----BEGIN RSA PRIVATE KEY-----'
relay-automation/hooks/security-scan-baseline.txt:52:test/security-scan.sh	pem-private-key	check_pattern "pem-openssh"      '-----BEGIN OPENSSH PRIVATE KEY-----'
relay-automation/hooks/security-scan-baseline.txt:53:test/security-scan.sh	github-pat	GH_TOKEN="ghp_aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890"
relay-automation/hooks/security-scan-baseline.txt:54:test/security-scan.sh	github-pat	check_pattern "github-pat"       'TOKEN=ghp_aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890'
relay-automation/hooks/security-scan-baseline.txt:55:test/security-scan.sh	slack-token	SLACK_BOT="xoxb-secrettoken"
relay-automation/hooks/security-scan-baseline.txt:56:test/security-scan.sh	slack-token	check_pattern "slack-bot"        'SLACK=xoxb-abc123'
relay-automation/hooks/security-scan-baseline.txt:57:test/security-scan.sh	credential-literal	password="hunter2secret"
relay-automation/hooks/security-scan-baseline.txt:58:test/security-scan.sh	credential-literal	password="mysecretpass"'
relay-automation/hooks/security-scan-baseline.txt:59:test/security-scan.sh	credential-literal	api_key=supersecretvalue'
relay-automation/hooks/security-scan-baseline.txt-60-test/xyz-vendor.sh	eval-unsanitized	( unset HARNESS; eval "$(cat "$WORK/plain.env")"; [ "$HARNESS" = "$ROOT" ] ) \
relay-automation/hooks/security-scan-baseline.txt-61-
relay-automation/hooks/security-scan-baseline.txt:62:# --- added 2026-07-01: GH-64's own baseline-mechanism test fixtures (test/security-scan.sh) ---
relay-automation/hooks/security-scan-baseline.txt:63:test/security-scan.sh	credential-literal	api_key=hunter2supersecretvalue'
relay-automation/hooks/security-scan-baseline.txt:64:test/security-scan.sh	credential-literal	api_key=hunter2supersecretvalue
relay-automation/hooks/security-scan-baseline.txt:65:test/security-scan.sh	credential-literal	password="pw secret"
relay-automation/hooks/security-scan-baseline.txt:66:test/security-scan.sh	eval-unsanitized	printf '#!/usr/bin/env bash\neval "$X"\n' > "$UNREADABLE_FILE"
relay-automation/hooks/security-scan-baseline.txt:67:test/security-scan.sh	eval-unsanitized	printf '#!/usr/bin/env bash\neval "$ALSO_BAD"\n' > "$OTHER_FILE"
relay-automation/hooks/security-scan-baseline.txt:68:test/security-scan.sh	eval-unsanitized	eval "$KNOWN_GOOD"
relay-automation/hooks/security-scan-baseline.txt:69:test/security-scan.sh	eval-unsanitized	eval "$BRAND_NEW_ONE"
relay-automation/hooks/security-scan-baseline.txt:70:test/security-scan.sh	eval-unsanitized	printf '# comment line, ignored\n\nmixed.sh\teval-unsanitized\teval "$KNOWN_GOOD"\n' > "$BASE_FILE"
relay-automation/hooks/security-scan-baseline.txt:71:test/security-scan.sh	eval-unsanitized	printf '# comment\nmixed.sh\teval-unsanitized\teval "$KNOWN_GOOD"\nmixed.sh\teval-unsanitized\teval "$BRAND_NEW_ONE"\n' > "$BASE_FILE"
relay-automation/hooks/security-scan-baseline.txt:72:test/security-scan.sh	eval-unsanitized	TSV_EXPECT="$(printf 'mixed.sh\teval-unsanitized\teval "$KNOWN_GOOD"')"
relay-automation/hooks/security-scan-baseline.txt-73-test/deep-research.sh	credential-literal	API_KEY="test-key"
relay-automation/hooks/security-scan-baseline.txt-74-test/aider-turn.sh	credential-literal	API_KEY="sk-local-test"
relay-automation/hooks/security-scan-baseline.txt-75-test/hq-locator.sh	eval-unsanitized	( eval "$EVOUT"; [ "$HQ_SH" = "$HARN/utils/hq/hq.sh" ] && [ "$HQ_ROOT" = "$HARN" ] ) \
--
relay-automation/new-relay.sh-7-# Setup that names the artifact under review, ground rules, and an empty Log with the next-turn marker.
relay-automation/new-relay.sh-8-#
relay-automation/new-relay.sh-9-# Two artifact modes:
relay-automation/new-relay.sh:10:#   (default, reference) — the Setup points at .relay-artifacts/<basename>, the read-only path that
relay-automation/new-relay.sh-11-#       `relay-drive.sh --artifact-file <source>` seeds into the isolated worktree (GH-31 Phase 2 / #15).
relay-automation/new-relay.sh-12-#   --embed              — inline the artifact's bytes in a FENCE-SAFE code block (GH-31 Phase 3): the
relay-automation/new-relay.sh-13-#       fence is chosen LONGER than the longest backtick run inside the file, so an artifact that itself
--
relay-automation/new-relay.sh-119-EOF
relay-automation/new-relay.sh-120-  elif [[ -n "$ARTIFACT" ]]; then
relay-automation/new-relay.sh-121-    cat <<EOF
relay-automation/new-relay.sh:122:- Artifact under review: **.relay-artifacts/$art_base** — the read-only path that
relay-automation/new-relay.sh-123-  \`relay-drive.sh --artifact-file $ARTIFACT\` seeds into the isolated worktree (read it there; do NOT edit it).
relay-automation/new-relay.sh-124-- Reviewer: $REVIEWER   ·   Producer: $PRODUCER
relay-automation/new-relay.sh-125-- Started: $TODAY
--
relay-automation/hooks/relay-xyz-guard.sh-94-  *find-harness.sh*) : > "$MARKER" 2>/dev/null || true; exit 0 ;;
relay-automation/hooks/relay-xyz-guard.sh-95-esac
relay-automation/hooks/relay-xyz-guard.sh-96-
relay-automation/hooks/relay-xyz-guard.sh:97:# Inspection (read-only) of a harness file is not "driving" — never block it.
relay-automation/hooks/relay-xyz-guard.sh-98-first="${FIELD%% *}"
relay-automation/hooks/relay-xyz-guard.sh-99-case "$first" in
relay-automation/hooks/relay-xyz-guard.sh:100:  cat|head|tail|less|more|wc|grep|rg|ls|bat|file|stat|chmod|git|find|awk|sed) exit 0 ;;
relay-automation/hooks/relay-xyz-guard.sh-101-esac
relay-automation/hooks/relay-xyz-guard.sh-102-case "$FIELD" in *"bash -n "*) exit 0 ;; esac
relay-automation/hooks/relay-xyz-guard.sh-103-
--
relay-automation/driver-lock-lib.sh-4-# Mirrors the DRIVER's own write-side resolution (marathon_drive.py / marathon-drive.sh,
relay-automation/driver-lock-lib.sh-5-# relay_drive.py / relay-drive.sh) byte-for-byte (utils/py/rtl.py's driver_lock_path is the Python
relay-automation/driver-lock-lib.sh-6-# twin — the two MUST agree, asserted by test/gh448-driver-lock-resolver.sh). SOURCED by every
relay-automation/driver-lock-lib.sh:7:# read-only consumer of the lock (marathon-ls.sh, utils/hq/marathon-live.sh,
relay-automation/driver-lock-lib.sh-8-# skills/relay-xyz/find-harness.sh) — a consumer that constructs this path inline instead of calling
relay-automation/driver-lock-lib.sh-9-# this function is the bug this file exists to kill (5 of 7 construction sites had drifted to a
relay-automation/driver-lock-lib.sh-10-# 2-branch guess that misses the linked-worktree case, silently reporting a LIVE marathon as IDLE).
--
relay-automation/hooks/security-scan.sh-1-#!/usr/bin/env bash
relay-automation/hooks/security-scan.sh-2-#
relay-automation/hooks/security-scan.sh:3:# security-scan.sh — static security scanner for shell scripts (GH-64)
relay-automation/hooks/security-scan.sh-4-#
relay-automation/hooks/security-scan.sh-5-# Implements fail-loud detection per GUIDING-PRINCIPLES.md #8 (no masked failure):
relay-automation/hooks/security-scan.sh-6-# every finding is printed to stderr as SECURITY: <file>:<line> <reason>, and the
--
relay-automation/hooks/security-scan.sh-8-# silently suppresses.  No network access required.
relay-automation/hooks/security-scan.sh-9-#
relay-automation/hooks/security-scan.sh-10-# Usage:
relay-automation/hooks/security-scan.sh:11:#   bash relay-automation/hooks/security-scan.sh [--no-baseline] [--baseline FILE] [--tsv] [<path>...]
relay-automation/hooks/security-scan.sh-12-#
relay-automation/hooks/security-scan.sh-13-# --tsv prints each finding as `<file>\t<rule>\t<line text>` on stdout instead of the human-readable
relay-automation/hooks/security-scan.sh-14-# "SECURITY: ..." line — paste a row straight into the baseline file's tab-separated columns after
--
relay-automation/hooks/security-scan.sh-19-#
relay-automation/hooks/security-scan.sh-20-# Baseline (GH-64): a known-legitimate finding (a reviewed dispatcher `eval`, a test fixture, a doc
relay-automation/hooks/security-scan.sh-21-# comment matching a pattern in prose) is pre-approved by an exact `<file>\t<rule>\t<line text>` entry
relay-automation/hooks/security-scan.sh:22:# in the baseline file (default: relay-automation/hooks/security-scan-baseline.txt, next to this
relay-automation/hooks/security-scan.sh-23-# script). A baselined finding is STILL PRINTED (labeled "SECURITY (baselined)") — nothing is hidden,
relay-automation/hooks/security-scan.sh-24-# per GUIDING-PRINCIPLES.md #8 (no masked failure) — it just doesn't count toward the exit code, so the
relay-automation/hooks/security-scan.sh-25-# scan can be a real BLOCKING gate without hand-suppressing every existing legitimate pattern. Matching
--
relay-automation/hooks/security-scan.sh-61-)
relay-automation/hooks/security-scan.sh-62-
relay-automation/hooks/security-scan.sh-63-USE_BASELINE=1
relay-automation/hooks/security-scan.sh:64:BASELINE_FILE="$HOOKS_DIR_CONST/security-scan-baseline.txt"
relay-automation/hooks/security-scan.sh-65-TSV_OUT=0
relay-automation/hooks/security-scan.sh-66-
relay-automation/hooks/security-scan.sh-67-# ---------------------------------------------------------------------------
--
relay-automation/hooks/security-scan.sh-137-  # Baseline entries store the file path relative to the repo root (portable across clones/CI),
relay-automation/hooks/security-scan.sh-138-  # matching how they were authored — resolve once per file.
relay-automation/hooks/security-scan.sh-139-  local f_rel="${f#"$REPO_ROOT_CONST"/}"
relay-automation/hooks/security-scan.sh:140:  # Every rule re-greps the same file, so an unreadable/errored file would otherwise report the
relay-automation/hooks/security-scan.sh:141:  # identical scan-error once per rule (7x). One report per file is enough to fail loud without the
relay-automation/hooks/security-scan.sh-142-  # noise; reset per scan_file() call.
relay-automation/hooks/security-scan.sh-143-  local _scan_error_reported=0
relay-automation/hooks/security-scan.sh-144-
--
relay-automation/hooks/security-scan.sh-168-  # _grep_or_fail_loud <grep-args...> — runs grep, leaving stdout in $_GREP_OUT (bash-3.2-safe: no
relay-automation/hooks/security-scan.sh-169-  # `local -n` nameref, which stock macOS bash doesn't support — see relay-turn-lib.sh). grep exit 1
relay-automation/hooks/security-scan.sh-170-  # (no match — the overwhelmingly common case) is silently treated as "no hits", but any OTHER
relay-automation/hooks/security-scan.sh:171:  # nonzero exit (2+: bad pattern, unreadable file, etc.) is a real scan error and must NOT read as
relay-automation/hooks/security-scan.sh-172-  # "file is clean" — that would be exactly the masked failure GUIDING-PRINCIPLES.md #8 forbids.
relay-automation/hooks/security-scan.sh:173:  # Reports a `[scan-error]` finding (counts toward FINDINGS, fails the scan) instead. Returns 1 if
relay-automation/hooks/security-scan.sh-174-  # the caller should stop processing this pattern (real error), 0 otherwise (matches or none).
relay-automation/hooks/security-scan.sh-175-  local _GREP_OUT=""
relay-automation/hooks/security-scan.sh-176-  _grep_or_fail_loud() {
--
relay-automation/hooks/security-scan.sh-179-    if [[ "$rc" -gt 1 ]]; then
relay-automation/hooks/security-scan.sh-180-      if [[ "$_scan_error_reported" -eq 0 ]]; then
relay-automation/hooks/security-scan.sh-181-        _scan_error_reported=1
relay-automation/hooks/security-scan.sh:182:        _report "scan-error" "-" "grep exited $rc scanning $f — treating as a finding, not silently clean"
relay-automation/hooks/security-scan.sh-183-      fi
relay-automation/hooks/security-scan.sh-184-      return 1
relay-automation/hooks/security-scan.sh-185-    fi
--
relay-automation/relay-turn-lib.sh-326-  [[ "$RTL_IGNORECASE" == "true" ]] || RTL_IGNORECASE=false
relay-automation/relay-turn-lib.sh-327-  RTL_WT_USED=0          # set to 1 by rtl_worktree_begin; read by rtl_enforce's commit-bypass guard (GH-13)
relay-automation/relay-turn-lib.sh-328-  RTL_ALLOW=("$f")
relay-automation/relay-turn-lib.sh:329:  # REVIEWER-turn scoping: a reviewer is near read-only — it only APPENDS findings to the relay file
relay-automation/relay-turn-lib.sh-330-  # and must never edit the artifact under review. When NEXT names the Reviewer, drop the caller's
relay-automation/relay-turn-lib.sh-331-  # extra allowlist (relay file ONLY) so any artifact edit a headless reviewer makes is reverted by
relay-automation/relay-turn-lib.sh-332-  # rtl_enforce. This is the boundary an over-eager agy reviewer crossed on 2026-06-20 (it edited
--
relay-automation/relay-turn-lib.sh-414-      RTL_RELAY_ARCHIVE_REL="${_fabs#"$_frepo"/}"
relay-automation/relay-turn-lib.sh-415-    fi
relay-automation/relay-turn-lib.sh-416-  fi
relay-automation/relay-turn-lib.sh:417:  # GH-31 / #15: optional READ-ONLY artifact under review (a cross-repo or uncommitted PR/diff).
relay-automation/relay-turn-lib.sh-418-  # RELAY_ARTIFACT_FILE is an ABSOLUTE path to the source (relay-drive absolutizes it). It is seeded
relay-automation/relay-turn-lib.sh:419:  # read-only into the worktree by rtl_worktree_begin at .relay-artifacts/<basename> — NOT added to
relay-automation/relay-turn-lib.sh-420-  # RTL_ALLOW, so it is never copied back to RTL_ROOT (no leak). The reviewer may READ it; an edit
relay-automation/relay-turn-lib.sh:421:  # changes its signature and fails the turn (strict read-only). Empty/unset → no artifact (default).
relay-automation/relay-turn-lib.sh-422-  RTL_ARTIFACT="${RELAY_ARTIFACT_FILE:-}"
relay-automation/relay-turn-lib.sh-423-  RTL_ARTIFACT_REL=""
relay-automation/relay-turn-lib.sh-424-  # NB: a trailing `[[ -n .. ]] && assign` would make rtl_init RETURN the test's status (1 when no
--
relay-automation/relay-turn-lib.sh-656-#     allowlisted paths UNDER RTL_ROOT (below). An artifact in ANOTHER repo, or a brand-new uncommitted
relay-automation/relay-turn-lib.sh-657-#     one, is neither at HEAD nor on the writable allowlist, so it would be invisible to an isolated turn.
relay-automation/relay-turn-lib.sh-658-#     FIX (GH-31 / closes #15): set RELAY_ARTIFACT_FILE (relay-drive `--artifact-file`) to seed it as a
relay-automation/relay-turn-lib.sh:659:#     READ-ONLY artifact at .relay-artifacts/<basename> — the read-only seed set distinct from the writable
relay-automation/relay-turn-lib.sh-660-#     allowlist. The reviewer may READ it; an edit changes its signature and fails the turn (strict-fail);
relay-automation/relay-turn-lib.sh-661-#     it is never copied back to RTL_ROOT (no leak). See rtl_init (RTL_ARTIFACT) + the seed/exempt logic
relay-automation/relay-turn-lib.sh-662-#     in rtl_worktree_begin/end. (Embedding inline still works for callers who prefer it.)
--
relay-automation/relay-turn-lib.sh-733-  # rtl_worktree_end re-reads the sidecar by the worktree path it is handed. One line per RTL_ALLOW entry.
relay-automation/relay-turn-lib.sh-734-  : >"${wt}.seedsig"
relay-automation/relay-turn-lib.sh-735-  for a in "${RTL_ALLOW[@]}"; do [[ "$a" == /* ]] && continue; _rtl_sig "$wt/$a" >>"${wt}.seedsig"; done
relay-automation/relay-turn-lib.sh:736:  # GH-31 / #15: seed the read-only artifact under review so an ISOLATED reviewer can READ it (it is
relay-automation/relay-turn-lib.sh-737-  # neither at HEAD nor on the writable allowlist). Snapshot the .relay-artifacts dir signature to a
relay-automation/relay-turn-lib.sh-738-  # sidecar so rtl_worktree_end can exempt it from off-lane detection ONLY while unchanged — a reviewer
relay-automation/relay-turn-lib.sh:739:  # edit changes the signature and trips off-lane (strict read-only). NOT in RTL_ALLOW ⇒ never copied back.
relay-automation/relay-turn-lib.sh-740-  if [[ -n "${RTL_ARTIFACT:-}" && -f "$RTL_ARTIFACT" ]]; then
relay-automation/relay-turn-lib.sh-741-    mkdir -p "$wt/.relay-artifacts"
relay-automation/relay-turn-lib.sh-742-    cp "$RTL_ARTIFACT" "$wt/$RTL_ARTIFACT_REL"
--
relay-automation/relay-turn-lib.sh-795-    if [[ -n "$_rtl_log_top" ]]; then
relay-automation/relay-turn-lib.sh-796-      case "$path" in "$_rtl_log_top"|"$_rtl_log_top"/|"$_rtl_log_top"/*) continue ;; esac
relay-automation/relay-turn-lib.sh-797-    fi
relay-automation/relay-turn-lib.sh:798:    # GH-31 / #15: the read-only artifact seed. Exempt ONLY while unchanged from the seed; a reviewer
relay-automation/relay-turn-lib.sh:799:    # edit changes the .relay-artifacts dir signature → strict-fail as off-lane (read-only enforced,
relay-automation/relay-turn-lib.sh-800-    # not silently discarded). git collapses an all-untracked dir to ".relay-artifacts/", so match both.
relay-automation/relay-turn-lib.sh-801-    case "$path" in
relay-automation/relay-turn-lib.sh-802-      .relay-artifacts|.relay-artifacts/|.relay-artifacts/*)
--
relay-automation/relay-turn-lib.sh-929-    csv_rel=""
relay-automation/relay-turn-lib.sh-930-    role_note=' You are the REVIEWER this turn: do NOT edit, create, or run any artifact or source file — ONLY append your graded findings to the relay file. Any other edit will be reverted and fail the turn.'
relay-automation/relay-turn-lib.sh-931-  fi
relay-automation/relay-turn-lib.sh:932:  # GH-31 / #15: point the reviewer at the seeded read-only artifact (worktree-relative; it is NOT a
relay-automation/relay-turn-lib.sh-933-  # writable edit target — an edit fails the turn).
relay-automation/relay-turn-lib.sh-934-  local art_note=""
relay-automation/relay-turn-lib.sh-935-  [[ -n "${RTL_ARTIFACT_REL:-}" ]] && art_note=" The artifact under review is at ${RTL_ARTIFACT_REL} — READ it for your review, but do NOT edit it (any edit fails your turn)."
--
relay-automation/relay-turn-lib.sh-1071-
relay-automation/relay-turn-lib.sh-1072-# GH-173 B3 / GH-178 A4 follow-up (code review on PR #184): the claim-trigger and citation regexes
relay-automation/relay-turn-lib.sh-1073-# are shared by both call sites below — rtl_check_uncited_findings's per-line downgrade, and
relay-automation/relay-turn-lib.sh:1074:# rtl_has_uncited_claim's read-only predicate (used by consult.sh's A4 stamp) — so the two stay in
relay-automation/relay-turn-lib.sh-1075-# lockstep on one definition of "claim"/"citation" instead of drifting apart.
relay-automation/relay-turn-lib.sh-1076-#   RTL_CLAIM_WORD_RE — free-form phrasing a model might use INSTEAD of the [Pass] tag to assert
relay-automation/relay-turn-lib.sh-1077-#                        correctness. Widened 2026-07-08 from a 3-word list ([Pass]/verified/
--
relay-automation/relay-turn-lib.sh-1129-  ' "$f" > "$tmp" && mv "$tmp" "$f"
relay-automation/relay-turn-lib.sh-1130-}
relay-automation/relay-turn-lib.sh-1131-
relay-automation/relay-turn-lib.sh:1132:# GH-178 A4 follow-up (code review on PR #184): read-only predicate reused by consult.sh's advisor
relay-automation/relay-turn-lib.sh-1133-# citeless-stamp so B3 and A4 share one definition of "claim"/"citation" rather than two independent
relay-automation/relay-turn-lib.sh-1134-# implementations drifting apart. Flags <file> as having an uncited claim if EITHER (a) the file has
relay-automation/relay-turn-lib.sh-1135-# ZERO citations anywhere (the original A4 spec — "carries zero explicit citations anywhere"), OR
--
relay-automation/relay-turn-lib.sh-1138-# original consult.sh check only asked "is there a citation ANYWHERE in the whole transcript" — one
relay-automation/relay-turn-lib.sh-1139-# incidental citation early in a long answer let several later uncited [Pass]/verified claims slip
relay-automation/relay-turn-lib.sh-1140-# through unflagged. Mirrors grep -q's convention: exit 0 (true) = flag it, exit 1 = adequately cited.
relay-automation/relay-turn-lib.sh:1141:# Missing/unreadable file fails safe (flagged), matching the old grep-based check's behavior on a
relay-automation/relay-turn-lib.sh-1142-# missing $out.
relay-automation/relay-turn-lib.sh-1143-rtl_has_uncited_claim() {  # <file>
relay-automation/relay-turn-lib.sh-1144-  local f="$1" win="${RTL_CITATION_WINDOW:-3}"
--
utils/transcript-audit.sh-4-#
utils/transcript-audit.sh-5-# Four pillars: Attested | Relevant | Fresh | Structured
utils/transcript-audit.sh-6-#
utils/transcript-audit.sh:7:# READ-ONLY: this script never writes to, moves, or deletes any transcript.
utils/transcript-audit.sh-8-#
utils/transcript-audit.sh-9-# Usage:
utils/transcript-audit.sh-10-#   utils/transcript-audit.sh [<transcript-dir>]
--
utils/transcript-audit.sh-69-#   (a) path with OLD/deprecated/.bak/.backup in the name (pattern-based)
utils/transcript-audit.sh-70-#   (b) repo-relative path appearing after read/cat/source that no longer exists
utils/transcript-audit.sh-71-#
utils/transcript-audit.sh:72:# READ-ONLY: we only grep transcripts; we never write to them.
utils/transcript-audit.sh-73-
utils/transcript-audit.sh-74-while IFS= read -r tf; do
utils/transcript-audit.sh-75-  [ -f "$tf" ] || continue
--
relay-automation/consult.sh-32-# (tracked WIP via `git stash create` + untracked-not-ignored files copied in). Any file an advisor
relay-automation/consult.sh-33-# writes lands in that disposable worktree and is destroyed with it — the operator's real working tree
relay-automation/consult.sh-34-# is NEVER the advisors' surface, so there is nothing to revert and ambient WIP can't be clobbered.
relay-automation/consult.sh:35:# (Codex stays `-s read-only` on top of that; agy's writes, if any, are contained by the worktree.)
relay-automation/consult.sh-36-#
relay-automation/consult.sh-37-# Usage:
relay-automation/consult.sh-38-#   consult.sh --prompt-file Q.md  [--out DIR] [--models codex,agy] [--label SLUG]
--
relay-automation/consult.sh-57-#   AIDER_OPENAI_API_BASE      OpenAI-compatible base URL (e.g. http://127.0.0.1:1234/v1 for LM Studio).
relay-automation/consult.sh-58-#   AIDER_OPENAI_API_KEY       client key for that base URL (default: dummy — local servers ignore it).
relay-automation/consult.sh-59-#   GEMINI_BIN                 legacy alias for AGY_BIN when `--models ...gemini` is used explicitly
relay-automation/consult.sh:60:#   CODEX_FLAGS                codex sandbox flags (default: -s read-only)
relay-automation/consult.sh-61-#   AGY_AUTH_TIMEOUT_S         short wall-clock cap for the agy auth probe (`agy whoami`); default 5.
relay-automation/consult.sh-62-#                              On failure/time-out consult skips the agy lane fast with an `agy login`
relay-automation/consult.sh-63-#                              remedy instead of waiting for the main CONSULT_TIMEOUT watchdog.
--
relay-automation/consult.sh-68-#                              CONSULT_ROOT via TICK_REPO_ROOT, else harness-local bin/tick)
relay-automation/consult.sh-69-#
relay-automation/consult.sh-70-# Boundary note: advisors run in a throwaway git worktree, so they cannot touch the operator's REPO.
relay-automation/consult.sh:71:# That is repo-isolation, NOT an OS sandbox — only Codex additionally gets `-s read-only`; a model
relay-automation/consult.sh-72-# could still read elsewhere on disk or reach the network. The skill docs say "repo-isolated", not
relay-automation/consult.sh:73:# "read-only", on purpose.
relay-automation/consult.sh-74-#
relay-automation/consult.sh-75-# Exit: 0 = at least one advisor answered · 5 = ALL advisors failed · 2 = usage · 3 = not a git repo.
relay-automation/consult.sh-76-
--
relay-automation/consult.sh-193-}
relay-automation/consult.sh-194-
relay-automation/consult.sh-195-run_codex() {
relay-automation/consult.sh:196:  local out="$1"; read -ra _f <<<"${CODEX_FLAGS:--s read-only}"
relay-automation/consult.sh-197-  # Billing guard: strip OPENAI_API_KEY so a consult ALWAYS bills the ChatGPT-subscription login,
relay-automation/consult.sh-198-  # never per-token API credits (CODEX_ALLOW_API_KEY=1 to opt back in). See codex-turn.sh.
relay-automation/consult.sh-199-  local cenv=(env); [[ "${CODEX_ALLOW_API_KEY:-0}" == "1" ]] || cenv+=(-u OPENAI_API_KEY)
--
relay-automation/marathon-drive.sh-120-# (test/lane-attempt-cap.sh diffs _lane_key..lane_attempt_reset between the two drivers verbatim) —
relay-automation/marathon-drive.sh-121-# kept below it deliberately so that contract stays untouched.
relay-automation/marathon-drive.sh-122-#
relay-automation/marathon-drive.sh:123:# debug_mantra_prior_attempts is a READ-ONLY peek at the SAME .tick/attempts/<lane> file GH-45 already
relay-automation/marathon-drive.sh-124-# maintains (via _lane_key, defined above) — it never writes. lane_attempt_gate is still the only
relay-automation/marathon-drive.sh-125-# writer/park authority; this only answers "did the last attempt at this phase fail to reach Approved"
relay-automation/marathon-drive.sh-126-# so the render step below (Step 1) can decide whether to inject the debug-mantra note, which must
--
relay-automation/marathon-drive.sh-948-  complete_phase_success already-satisfied
relay-automation/marathon-drive.sh-949-fi
relay-automation/marathon-drive.sh-950-
relay-automation/marathon-drive.sh:951:# GH-162: peek at prior attempts BEFORE rendering (read-only; lane_attempt_gate in Step 3 still owns
relay-automation/marathon-drive.sh-952-# the append/park write) so a re-fired phase's relay file can carry the debug-mantra note. Empty
relay-automation/marathon-drive.sh-953-# DEBUG_MANTRA_TEXT on a first fire (prior=0) — the render below is then byte-identical to before.
relay-automation/marathon-drive.sh-954-DEBUG_MANTRA_PRIOR="$(debug_mantra_prior_attempts "${TICK_REPO_ROOT:-$ROOT}" "$LANE_STATE_KEY")"
--
utils/marathon-plan.sh-502-// (PROJECT/2-WORKING/PR-REVIEW-QUEUE-<date>.md) — a different shape from the ROADMAP ledger: each row
utils/marathon-plan.sh-503-// reviews an existing PR diff rather than remediating a ledger item, so it doesn't fit parseBullet's
utils/marathon-plan.sh-504-// `- **title**` bullet shape. Generalized instead by column NAME (Lane/PR/Reviewer), so header-cell
utils/marathon-plan.sh:505:// wording (e.g. "Artifact (read-only)") doesn't need to match exactly. Degrades to [] on any
utils/marathon-plan.sh-506-// malformed shape — never throws (same "flag, don't die" contract as the rest of this planner).
utils/marathon-plan.sh-507-function parseLanesTable(raw) {
utils/marathon-plan.sh-508-  const lines = raw.split(/\r?\n/);
--
utils/marathon-plan.sh-1137-  o.push("```");
utils/marathon-plan.sh-1138-  o.push("");
utils/marathon-plan.sh-1139-  o.push("- **Lane scoping:** give each lane an `ALLOW_PATHS` matching only its zone above.");
utils/marathon-plan.sh:1140:  o.push("- If the lane's allowlist includes filesystem-touching `test/*.sh`, treat those tests as read-only specs in-turn; the outer harness gate verifies them after the turn, outside the isolated worktree.");
utils/marathon-plan.sh-1141-  o.push("");
utils/marathon-plan.sh-1142-  o.push("---");
utils/marathon-plan.sh-1143-  o.push("");
--
utils/timeline/export_timeline.py-1-#!/usr/bin/env python3
utils/timeline/export_timeline.py-2-"""GH-103 spike: project the RELEASES SQLite ledger onto the timeline-ui viewer.
utils/timeline/export_timeline.py-3-
utils/timeline/export_timeline.py:4:Read-only exporter: queries releases.db (releases, manifest_items, issue_refs,
utils/timeline/export_timeline.py-5-marathons, roadmap_items, settings, op_receipts) and emits
utils/timeline/export_timeline.py-6-
utils/timeline/export_timeline.py-7-  <out>/data.json     — the viewer's data contract (RELEASES.html fetches this when served)
--
utils/timeline/export_timeline.py-12-self-contained RELEASES-PREVIEW.html (default: repo root), and --serve PORT
utils/timeline/export_timeline.py-13-answers /data.json live from the DB on every request.
utils/timeline/export_timeline.py-14-
utils/timeline/export_timeline.py:15:Never writes to the database (opens it with SQLite's read-only URI mode).
utils/timeline/export_timeline.py-16-
utils/timeline/export_timeline.py-17-Usage:
utils/timeline/export_timeline.py-18-  python3 utils/timeline/export_timeline.py [--db releases.db] [--out temp/timeline]
--
utils/timeline/export_timeline.py-364-
utils/timeline/export_timeline.py-365-
utils/timeline/export_timeline.py-366-def parse_releases_md(path):
utils/timeline/export_timeline.py:367:    """RELEASES.md 'Release:' blocks -> {version: {status, codename}}. None if unreadable."""
utils/timeline/export_timeline.py-368-    if not path.is_file():
utils/timeline/export_timeline.py-369-        return None
utils/timeline/export_timeline.py-370-    blocks, cur = {}, None
--
utils/timeline/export_timeline.py-513-    return {
utils/timeline/export_timeline.py-514-        "meta": {
utils/timeline/export_timeline.py-515-            "title": "Planning ledgers",
utils/timeline/export_timeline.py:516:            "subtitle": f"{settings.get('repo_slug', 'repo')} · releases.db · read-only",
utils/timeline/export_timeline.py-517-            "generatedAtDisplay": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%SZ"),
utils/timeline/export_timeline.py-518-            "sourceLabel": f"releases.db · schema v{schema_v}",
utils/timeline/export_timeline.py-519-            "repoUrl": repo_url,  # GH-153: sidebar repo links (None -> links stay unwired)
--
utils/timeline/export_timeline.py-643-    if args.preview:
utils/timeline/export_timeline.py-644-        args.preview.write_text(bake_static(args.template.read_text(), payload))
utils/timeline/export_timeline.py-645-        print(f"wrote {args.preview} ({payload['telemetry']['releasesTotal']} releases, "
utils/timeline/export_timeline.py:646:              f"self-contained, read-only snapshot of {args.db})")
utils/timeline/export_timeline.py-647-        return
utils/timeline/export_timeline.py-648-
utils/timeline/export_timeline.py-649-    args.out.mkdir(parents=True, exist_ok=True)
--
utils/timeline/export_timeline.py-654-    print(
utils/timeline/export_timeline.py-655-        f"wrote {args.out}/data.json + index.html "
utils/timeline/export_timeline.py-656-        f"({payload['telemetry']['releasesTotal']} releases, "
utils/timeline/export_timeline.py:657:        f"{sum(r['itemsTotal'] for r in payload['releases'])} manifest cards, read-only)"
utils/timeline/export_timeline.py-658-    )
utils/timeline/export_timeline.py-659-
utils/timeline/export_timeline.py-660-
--
utils/ci-route.sh-235-  esac
utils/ci-route.sh-236-done
utils/ci-route.sh-237-
utils/ci-route.sh:238:# An empty or unreadable PR diff is not proof that the change is documentation-only.
utils/ci-route.sh-239-if [[ "$path_count" -eq 0 ]]; then
utils/ci-route.sh-240-  docs_only=false
utils/ci-route.sh-241-  pdda_needed=true
--
utils/gate-status.sh-61-
utils/gate-status.sh-62-if [ "$NO_NET" -eq 1 ] || ! command -v gh >/dev/null 2>&1; then
utils/gate-status.sh-63-  printf 'hosted macOS boundary: UNKNOWN (no network check requested, or gh unavailable)\n'
utils/gate-status.sh:64:  printf 'portability canary (ubuntu): UNKNOWN\n'
utils/gate-status.sh-65-  printf '\nstatus: unknown — cannot tell promotable from not without querying the hosted runs.\n'
utils/gate-status.sh-66-  exit 0
utils/gate-status.sh-67-fi
--
utils/gate-status.sh-71-# produced by the person making the claim.
utils/gate-status.sh-72-# THE FILTER MUST MIRROR THE JOB'S OWN `if:`, and getting this wrong is not a small bug — the first
utils/gate-status.sh-73-# draft matched any successful `push` or `workflow_dispatch` run and duly reported a push to
utils/gate-status.sh:74:# `development` as boundary evidence. That run executed the UBUNTU CANARY and never touched macOS, so
utils/gate-status.sh-75-# the tool would have presented a Linux green as a promotion qualification: exactly the false-evidence
utils/gate-status.sh-76-# class this whole issue exists to remove, produced by the tool built to prevent it.
utils/gate-status.sh-77-#
utils/gate-status.sh-78-# `boundary-macos` runs when: push to main. That is the whole list — `workflow_dispatch` was removed
utils/gate-status.sh-79-# on 2026-08-13 after 75 macOS minutes cost $4.65 against a $10 monthly budget (see the job's own
utils/gate-status.sh-80-# comment in ci.yml). A dispatch run therefore no longer contains a macOS job at all, and accepting
utils/gate-status.sh:81:# one here would report an ubuntu-only run as boundary evidence — the exact false green this filter
utils/gate-status.sh-82-# was written to stop, arriving from the other direction. This condition is COUPLED to the workflow's
utils/gate-status.sh-83-# `if:` and test/gh509-gate-evidence.sh asserts they agree.
utils/gate-status.sh-84-boundary="$(gh run list --workflow=ci.yml --json headSha,conclusion,createdAt,event,headBranch \
--
utils/gate-status.sh-112-  fi
utils/gate-status.sh-113-fi
utils/gate-status.sh-114-
utils/gate-status.sh:115:# ── portability canary ───────────────────────────────────────────────────────────────────────────
utils/gate-status.sh-116-# The mechanism that makes an advisory job READ rather than merely non-blocking. agy's review of the
utils/gate-status.sh-117-# GH-509 plan was right that "advisory" supplies nobody a reason to look; attaching it to the moment
utils/gate-status.sh-118-# someone is already deciding is the only reliable fix.
utils/gate-status.sh-119-canary="$(gh run list --workflow=ci.yml --branch "$branch" --limit 1 \
utils/gate-status.sh-120-  --json conclusion,headSha -q '.[0] | "\(.conclusion)\t\(.headSha)"' 2>/dev/null || true)"
utils/gate-status.sh-121-if [ -z "$canary" ] || [ "${canary%%$'\t'*}" = "null" ]; then
utils/gate-status.sh:122:  printf 'portability canary (ubuntu): no run found for %s\n' "$branch"
utils/gate-status.sh-123-else
utils/gate-status.sh-124-  c_concl="${canary%%$'\t'*}"
utils/gate-status.sh-125-  if [ "$c_concl" = "success" ]; then
utils/gate-status.sh:126:    printf 'portability canary (ubuntu): green\n'
utils/gate-status.sh-127-  else
utils/gate-status.sh:128:    printf 'portability canary (ubuntu): DRIFT (%s) — not breakage; resolve before Linux support ships\n' "$c_concl"
utils/gate-status.sh-129-  fi
utils/gate-status.sh-130-fi
utils/gate-status.sh-131-
--
utils/hq/marathon-live.sh-1-#!/usr/bin/env bash
utils/hq/marathon-live.sh:2:# utils/hq/marathon-live.sh — read-only cross-repo LIVE marathon status (GH-218).
utils/hq/marathon-live.sh-3-#
utils/hq/marathon-live.sh-4-# Answers "what marathons are running right now?" across every XYZ-vendored repo on this machine, by
utils/hq/marathon-live.sh-5-# COMPOSING existing local primitives — it stands up no new per-repo infrastructure (no MCP server):
--
utils/hq/marathon-live.sh-15-#                      a claim without either is "claimed, not driving".
utils/hq/marathon-live.sh-16-#
utils/hq/marathon-live.sh-17-# Emits one compact Markdown table: repo | marathon/lane | task | claimant | live | last activity.
utils/hq/marathon-live.sh:18:# Read-only over every target repo (the only write is the aggregate report itself), matching
utils/hq/marathon-live.sh-19-# marathon-scan.sh's safety posture. Phase 2 (rollup.sh) embeds this report verbatim.
utils/hq/marathon-live.sh-20-#
utils/hq/marathon-live.sh-21-# Usage:
--
utils/hq/marathon-live.sh-51-
utils/hq/marathon-live.sh-52-Enumerate XYZ-vendored repos, regenerate each repo's own tick STATE.md, and report every LIVE
utils/hq/marathon-live.sh-53-marathon claim (repo, marathon/lane, task, claimant, live-or-stalled, last activity) as one aggregate
utils/hq/marathon-live.sh:54:Markdown table written in the hub repo. Read-only over every target repo.
utils/hq/marathon-live.sh-55-EOF
utils/hq/marathon-live.sh-56-}
utils/hq/marathon-live.sh-57-
--
utils/hq/marathon-live.sh-208-
utils/hq/marathon-live.sh-209-# HQ Marathon — Live cross-repo status ($NOW)
utils/hq/marathon-live.sh-210-
utils/hq/marathon-live.sh:211:Read-only snapshot of every XYZ-vendored repo's live \`tick\` claim, cross-checked against its driver
utils/hq/marathon-live.sh-212-lock and \`marathon/*\` worktree activity (window: ${WINDOW_MIN}m). "🟢 live" = a claim WITH a held
utils/hq/marathon-live.sh-213-driver lock or a recently-active marathon worktree; "🟡 claimed, not driving" = a claim with neither
utils/hq/marathon-live.sh-214-(likely stalled); "⚪ idle" = nothing claimed.
--
utils/hq/marathon-scan.sh-1-#!/usr/bin/env bash
utils/hq/marathon-scan.sh:2:# utils/hq/marathon-scan.sh — read-only cross-repo marathon aggregation + preflight (GH-158).
utils/hq/marathon-scan.sh-3-#
utils/hq/marathon-scan.sh-4-# Enumerates PDDA-known repos via hq-lib.sh, finds marathon docs under PROJECT/2-WORKING/, parses
utils/hq/marathon-scan.sh-5-# each doc's frontmatter status + active wave lanes, and runs EACH TARGET REPO'S OWN
--
utils/hq/marathon-scan.sh-517-
utils/hq/marathon-scan.sh-518-## Notes
utils/hq/marathon-scan.sh-519-
utils/hq/marathon-scan.sh:520:- The scanner is read-only over target repos. It writes only this aggregate doc.
utils/hq/marathon-scan.sh-521-- Each active lane is preflighted with that repo's own \`utils/swarm-preflight.sh --dry-run\`.
utils/hq/marathon-scan.sh-522-- Held marathons are surfaced for operator awareness but excluded from the fireable count by design.
utils/hq/marathon-scan.sh-523-EOF
--
utils/py/gate_env.py-75-    ),
utils/py/gate_env.py-76-    "RELAY_ARTIFACT_FILE": (
utils/py/gate_env.py-77-        SCRUB,
utils/py/gate_env.py:78:        "Seeds a read-only artifact into the worktree. A suite exercising --artifact-file would find "
utils/py/gate_env.py-79-        "the parent's already present. Same family as RELAY_FILE; classified rather than left "
utils/py/gate_env.py-80-        "ungoverned, which is the point of this registry.",
utils/py/gate_env.py-81-    ),
--
utils/ate/SKILL.md-119-
utils/ate/SKILL.md-120-- **Classifier oracle decoupling (`expects_edits`)** — the stock Aider grid expects the tree to
utils/ate/SKILL.md-121-  change, so exit-0-with-no-edit classifies `fail/no_edit`. A grid that only probes (usage
utils/ate/SKILL.md:122:  surfaces, read-only diagnostics) declares `expects_edits: false`, and exit-0-no-edit is a
utils/ate/SKILL.md-123-  PASS. The #146 Gemma soak recorded 17 false HIGH `no_edit` verdicts before this key existed —
utils/ate/SKILL.md-124-  do not run a non-edit grid without it.
utils/ate/SKILL.md-125-- **Rollup labels are neutral by default** — `bug`, nothing else. The Aider preset opts back in
--
utils/hq/hourly-global-scan.sh-1-#!/usr/bin/env bash
utils/hq/hourly-global-scan.sh-2-# utils/hq/hourly-global-scan.sh — scheduled wrapper for utils/hq/marathon-scan.sh (GH-158's follow-on).
utils/hq/hourly-global-scan.sh-3-#
utils/hq/hourly-global-scan.sh:4:# Runs the read-only cross-repo marathon scan and writes ONE fixed-name report — always overwritten
utils/hq/hourly-global-scan.sh-5-# in place, never date-stamped, so there is exactly one copy at any time (unlike
utils/hq/hourly-global-scan.sh-6-# utils/hq/marathon-scan.sh's own default HQ-MARATHON-<date>.md naming, which this wrapper always
utils/hq/hourly-global-scan.sh-7-# overrides via --out). Defaults to an in-repo path (portable, no machine-specific hardcoding — see
--
utils/py/backfill_source_url.py-148-            with open(path, "r", encoding="utf-8") as f:
utils/py/backfill_source_url.py-149-                text = f.read()
utils/py/backfill_source_url.py-150-        except OSError as e:
utils/py/backfill_source_url.py:151:            print(f"  UNREADABLE {path}: {e}", file=sys.stderr)
utils/py/backfill_source_url.py-152-            continue
utils/py/backfill_source_url.py-153-        action, detail, new_text = classify(text, slug, path)
utils/py/backfill_source_url.py-154-        counts[action] += 1
--
utils/py/review_xyz.py-372-        ]
utils/py/review_xyz.py-373-    elif engine == "codex":
utils/py/review_xyz.py-374-        codex_bin = env.get("CODEX_BIN", "codex")
utils/py/review_xyz.py:375:        cflags = env.get("CODEX_FLAGS", "-s read-only").split()
utils/py/review_xyz.py-376-        full_cmd = [codex_bin, "exec"] + cflags + [prompt]
utils/py/review_xyz.py-377-    elif engine == "agy":
utils/py/review_xyz.py-378-        agy_bin = env.get("AGY_BIN", "agy")
--
utils/hq/rollup.sh-199-
utils/hq/rollup.sh-200-# GH-153: the full RELEASES-cycle rollup. The marathon sections above cover RUNS; this covers
utils/hq/rollup.sh-201-# the ledger they serve — releases by status, roadmap movement, marathon states and manifest
utils/hq/rollup.sh:202:# outcomes, read-only from each repo's releases.db via the shared releases_cycle module (also
utils/hq/rollup.sh-203-# the dashboard sidebar's data source, so the two surfaces cannot disagree). Same
utils/hq/rollup.sh-204-# verbatim-embed rule as the marathon sections: the numbers are deterministic, so no synthesis
utils/hq/rollup.sh-205-# pass ever touches them. Per-repo failures degrade to a visible line, never a dropped repo.
--
utils/pdda/pdda.sh-189-    # Bullet count of the first "## Quad Concepts" section via the shared parser (pdda_quad_section:
utils/pdda/pdda.sh-190-    # line 1 is the count, -1 if absent). See pdda-lib.sh for the boundary/fence/CRLF rules.
utils/pdda/pdda.sh-191-    n="$(pdda_quad_section "$file" | sed -n '1p')"
utils/pdda/pdda.sh:192:    # guard against an empty capture (unreadable file) so the numeric comparisons never see an empty operand.
utils/pdda/pdda.sh-193-    case "$n" in ''|*[!0-9-]*) n="-1" ;; esac
utils/pdda/pdda.sh-194-
utils/pdda/pdda.sh-195-    if [ "$n" = "-1" ]; then
--
utils/pdda/pdda.sh-794-}
utils/pdda/pdda.sh-795-
utils/pdda/pdda.sh-796-# ------------------------------------------------------------------------------------------------
utils/pdda/pdda.sh:797:# releases-current (read-only roll-up; not part of PDDA_DETERMINISTIC_CHECKS — no findings, no gate)
utils/pdda/pdda.sh-798-# ------------------------------------------------------------------------------------------------
utils/pdda/pdda.sh-799-# A rough, non-authoritative answer to "what release is in progress right now" — for a human, or for
utils/pdda/pdda.sh-800-# another repo's tooling (e.g. the XYZ sibling harness) to shell out to rather than re-implementing
--
utils/pdda/pdda.sh-1340-}
utils/pdda/pdda.sh-1341-
utils/pdda/pdda.sh-1342-# ------------------------------------------------------------------------------------------------
utils/pdda/pdda.sh:1343:# glance — a read-only portfolio roll-up: title + Quad Concepts for each active plan doc, so the whole
utils/pdda/pdda.sh-1344-# 2-WORKING surface's pain coverage is visible on one screen. Not gated by the lever (a manual read).
utils/pdda/pdda.sh-1345-# ------------------------------------------------------------------------------------------------
utils/pdda/pdda.sh-1346-cmd_glance() {
--
utils/pdda/pdda.sh-1385-  frontmatter        active-doc frontmatter contract
utils/pdda/pdda.sh-1386-  status-table       exact two-column "## Status" table
utils/pdda/pdda.sh-1387-  quad-concepts      opt-in: a "## Quad Concepts" section of 1-4 bullets (lever: .pdda-quad / PDDA_QUAD)
utils/pdda/pdda.sh:1388:  glance             read-only roll-up: title + Quad Concepts for each PROJECT/2-WORKING doc
utils/pdda/pdda.sh-1389-  hardcoded-paths    no machine-specific absolute paths in working docs
utils/pdda/pdda.sh-1390-  roadmap            no execution detail leaks INTO ROADMAP.md
utils/pdda/pdda.sh-1391-  roadmap-coverage   nothing active goes MISSING from ROADMAP.md
--
utils/pdda/pdda.sh-1393-  stale              flag stale working docs (flag-only; never moves)
utils/pdda/pdda.sh-1394-  issue-doc-sync     flag 2-WORKING/GH-*.md docs drifted from their GitHub issue state (warn-only)
utils/pdda/pdda.sh-1395-  releases           validate RELEASES.md — the release-planning ledger (warn-only nudge)
utils/pdda/pdda.sh:1396:  releases-current   read-only roll-up: RELEASES.md entries whose Status isn't "Shipped" (rough, unvalidated)
utils/pdda/pdda.sh-1397-  governance         repo-root governance-doc (ROUTER/AGENTS/CLAUDE/...) cross-reference + doc/code drift
utils/pdda/pdda.sh-1398-  gh-refresh         refresh the cached GitHub issue-state file issue-doc-sync reads offline (needs gh)
utils/pdda/pdda.sh-1399-  doc-ready          LLM readiness review (delegates to pdda-doc-ready.sh; opt-in via PDDA_LLM_BIN)
--
utils/py/self_healer.py-285-"""
utils/py/self_healer.py-286-        with open(target_script, "w") as f:
utils/py/self_healer.py-287-            f.write(buggy_code)
utils/py/self_healer.py:288:        os.chmod(target_script, 0o755)
utils/py/self_healer.py-289-
utils/py/self_healer.py-290-        # Create a repro.sh test script
utils/py/self_healer.py-291-        repro_script = os.path.join(tmp_dir, "repro.sh")
--
utils/py/self_healer.py-300-fi
utils/py/self_healer.py-301-exit 1
utils/py/self_healer.py-302-""")
utils/py/self_healer.py:303:        os.chmod(repro_script, 0o755)
utils/py/self_healer.py-304-
utils/py/self_healer.py-305-        # 1. Realpath containment check
utils/py/self_healer.py-306-        c1 = check_realpath_containment(target_script, tmp_dir)
--
utils/hq/hq-lib.sh-1-#!/usr/bin/env bash
utils/hq/hq-lib.sh:2:# HQ resolver library (GH-128, Phase 0/1). READ-ONLY. Sourced by utils/hq/hq.sh and test/hq.sh.
utils/hq/hq-lib.sh-3-#
utils/hq/hq-lib.sh-4-# Resolution ladder (name -> repo -> path -> governance), each rung degrading gracefully to empty
utils/hq/hq-lib.sh-5-# when its source is missing/offline, so a partial registry set never hard-fails:
--
utils/hq/hq-lib.sh-28-hq_bare(){ printf '%s' "${1##*/}"; }                       # strip any owner/ prefix
utils/hq/hq-lib.sh-29-# GH-232: '.- ' (dot-dash-space) at the end reads to GNU tr as a RANGE from '.' to ' ' (a "reverse
utils/hq/hq-lib.sh-30-# collating sequence" warning) which corrupts the whole SET, silently sanitizing every query down to
utils/hq/hq-lib.sh:31:# an empty string on ubuntu-latest CI (works fine on macOS's BSD tr, which doesn't make that mistake).
utils/hq/hq-lib.sh-32-# Moving '-' to immediately follow the POSIX class is unambiguous on both.
utils/hq/hq-lib.sh-33-hq_sanitize(){ printf '%s' "$1" | tr -cd '[:alnum:]-/_. '; } # defang before SQL interpolation
utils/hq/hq-lib.sh-34-# hq_yaml_dq <string> -> escape for a YAML double-quoted scalar (backslash + double-quote). Without
--
utils/hq/hq-lib.sh-607-
utils/hq/hq-lib.sh-608-# hq_projects_by_priority [limit] -> `tier|value|status|name` rows from Rebalance project_registry,
utils/hq/hq-lib.sh-609-# ranked by priority_tier ASC (1 = highest .. 5 = lowest, per rebalance next_actions.py), then name.
utils/hq/hq-lib.sh:610:# Read-only; degrades to empty when the DB / sqlite3 is unavailable.
utils/hq/hq-lib.sh-611-hq_projects_by_priority(){
utils/hq/hq-lib.sh-612-  local limit="${1:-8}"
utils/hq/hq-lib.sh-613-  case "$limit" in ''|*[!0-9]*) limit=8;; esac
--
utils/py/rtl.py-739-def driver_lock_path(root):
utils/py/rtl.py-740-    # GH-448: the ONE shared resolver for the relay-driver lock path, matching the DRIVER's own
utils/py/rtl.py-741-    # write-side resolution (marathon_drive.py / marathon-drive.sh, relay_drive.py / relay-drive.sh) —
utils/py/rtl.py:742:    # every read-only consumer (marathon-ls.sh, marathon-live.sh, find-harness.sh) must resolve the
utils/py/rtl.py-743-    # SAME path or it probes a location the driver never writes and reports a live run as idle.
utils/py/rtl.py-744-    #   .git is a directory  -> <root>/.git/relay-driver.lock                (normal clone)
utils/py/rtl.py-745-    #   .git is a file       -> <git-common-dir>/relay-driver.lock           (linked worktree)
--
utils/hq/hq.sh-1-#!/usr/bin/env bash
utils/hq/hq.sh:2:# HQ — multi-repo command-center (GH-128). Phase 0/1: READ-ONLY resolver + project card.
utils/hq/hq.sh-3-#
utils/hq/hq.sh-4-# The front door for "For project X, do Y": this layer resolves the project name to a real repo on
utils/hq/hq.sh-5-# this device and reports its governance state. Writing intake (issue -> 1-INBOX capture -> ROADMAP
--
utils/hq/hq.sh-25-
utils/hq/hq.sh-26-usage(){
utils/hq/hq.sh-27-  cat >&2 <<'EOF'
utils/hq/hq.sh:28:HQ — multi-repo command-center (read-only prototype, GH-128)
utils/hq/hq.sh-29-
utils/hq/hq.sh-30-usage:
utils/hq/hq.sh-31-  hq.sh resolve <project|repo>            machine-readable KEY=value resolution
--
utils/hq/hq.sh-506-}
utils/hq/hq.sh-507-
utils/hq/hq.sh-508-# cmd_next [limit] — Phase 4: a Rebalance-priority-ranked board of projects with their HQ capability
utils/hq/hq.sh:509:# tier, so "what should I pick up next across my repos?" has one read-only answer. Rebalance stays
utils/hq/hq.sh:510:# read-only (mirrors the #96 seam discipline).
utils/hq/hq.sh-511-cmd_next(){
utils/hq/hq.sh-512-  local limit="${1:-8}" rows
utils/hq/hq.sh-513-  rows="$(hq_projects_by_priority "$limit")"
--
utils/hq/hq.sh-541-$rows
utils/hq/hq.sh-542-EOF
utils/hq/hq.sh-543-  echo
utils/hq/hq.sh:544:  echo "  Priority from Rebalance project_registry (read-only). 'cap' = HQ capability tier."
utils/hq/hq.sh-545-  echo "  Run 'hq status <project>' for the full card, or 'hq park <project> \"<request>\"' to file work."
utils/hq/hq.sh-546-}
utils/hq/hq.sh-547-
--
utils/py/repro_builder.py-343-echo "mock: success"
utils/py/repro_builder.py-344-exit 0
utils/py/repro_builder.py-345-""")
utils/py/repro_builder.py:346:        os.chmod(fixture_script, 0o755)
utils/py/repro_builder.py-347-
utils/py/repro_builder.py-348-        # 1. Telemetry parsing test (preserving explicit 0 exit codes)
utils/py/repro_builder.py-349-        sample_telemetry = {
--
utils/py/repro_builder.py-418-        repro_path = os.path.join(tmp_dir, "repro.sh")
utils/py/repro_builder.py-419-        with open(repro_path, "w") as f:
utils/py/repro_builder.py-420-            f.write(repro_code)
utils/py/repro_builder.py:421:        os.chmod(repro_path, 0o755)
utils/py/repro_builder.py-422-
utils/py/repro_builder.py-423-        res = subprocess.run(["bash", repro_path], cwd=tmp_dir, capture_output=True, text=True)
utils/py/repro_builder.py-424-        t5 = res.returncode == 0 and "PASS: Failure reproduced successfully" in res.stdout
--
utils/py/repro_builder.py-514-        if args.output:
utils/py/repro_builder.py-515-            with open(args.output, "w") as f:
utils/py/repro_builder.py-516-                f.write(repro_script)
utils/py/repro_builder.py:517:            os.chmod(args.output, 0o755)
utils/py/repro_builder.py-518-            print(f"Wrote hermetic reproducer to {args.output}")
utils/py/repro_builder.py-519-        else:
utils/py/repro_builder.py-520-            print(repro_script)
--
utils/py/claude-turn.py-110-                stub_f.write("#!/usr/bin/env bash\n")
utils/py/claude-turn.py-111-                stub_f.write(f'printf "blocked: %s is off-limits to a headless builder turn (CLAUDE_BLOCK_CMDS)\\n" {shlex.quote(c)} >&2\n')
utils/py/claude-turn.py-112-                stub_f.write("exit 127\n")
utils/py/claude-turn.py:113:            os.chmod(stub_path, 0o755)
utils/py/claude-turn.py-114-
utils/py/claude-turn.py-115-    rtl.before()
utils/py/claude-turn.py-116-    
--
utils/py/claude-turn.py-157-            bounded_rc = 5
utils/py/claude-turn.py-158-
utils/py/claude-turn.py-159-    # GH-380: trust is a per-directory Claude Code setting. This is deliberately warn-only:
utils/py/claude-turn.py:160:    # no config is modified and an untrusted (or unreadable) workspace still runs.
utils/py/claude-turn.py-161-    # Claude evaluates the directory it is launched in; under worktree isolation that is `wt`,
utils/py/claude-turn.py-162-    # rather than the original target root.
utils/py/claude-turn.py-163-    if bounded_rc == 0:
--
utils/py/metamorphic_oracle.py-2-"""Metamorphic Invariant Assertions & Sandbox Hardening Oracle (GH-155 Phase 1).
utils/py/metamorphic_oracle.py-3-
utils/py/metamorphic_oracle.py-4-Provides deterministic, zero-LLM-overhead metamorphic property testing:
utils/py/metamorphic_oracle.py:5:1. Zero-Mutation Invariant: Read-only/diagnostic commands must leave repo state 100% byte-identical.
utils/py/metamorphic_oracle.py-6-2. Idempotence Invariant: Deterministic operations must produce stable hashes across serial & parallel runs.
utils/py/metamorphic_oracle.py-7-3. Use-Boundary Realpath Containment: Resolves canonical paths to outlaw traversal and symlink escapes (GH-567).
utils/py/metamorphic_oracle.py-8-"""
--
utils/py/marathon_drive.py-738-            except: pass
utils/py/marathon_drive.py-739-
utils/py/marathon_drive.py-740-    def debug_mantra_prior_attempts(root_dir, raw):
utils/py/marathon_drive.py:741:        # GH-162: READ-ONLY peek at the .tick/attempts/<lane> file GH-45 maintains — how many prior
utils/py/marathon_drive.py-742-        # fires on this lane did not reach Approved. Never writes.
utils/py/marathon_drive.py-743-        f = os.path.join(root_dir, ".tick", "attempts", _lane_key(raw))
utils/py/marathon_drive.py-744-        if os.path.isfile(f):
--
utils/py/marathon_drive.py-805-        # worktree .git is a FILE pointing at the shared gitdir, so resolve the real common dir and put
utils/py/marathon_drive.py-806-        # the lock there — otherwise --require-clean sees the driver's own lock as untracked dirt inside
utils/py/marathon_drive.py-807-        # the worktree. A vendored .xyz/ copy (no .git) falls back to a hidden lock beside the scripts.
utils/py/marathon_drive.py:808:        # GH-448: this resolution is the canonical write-side one — every read-only consumer (marathon-
utils/py/marathon_drive.py-809-        # ls.sh, marathon-live.sh, find-harness.sh) must agree with it, so it lives in rtl.py's shared
utils/py/marathon_drive.py-810-        # driver_lock_path (with a byte-for-byte Bash twin in relay-automation/driver-lock-lib.sh)
utils/py/marathon_drive.py-811-        # rather than being reimplemented here.
--
utils/py/marathon_drive.py-1327-                        if ln.lstrip().startswith("### Round"):
utils/py/marathon_drive.py-1328-                            round_count += 1
utils/py/marathon_drive.py-1329-            except OSError:
utils/py/marathon_drive.py:1330:                status_line = "relay file unreadable at interruption"
utils/py/marathon_drive.py-1331-
utils/py/marathon_drive.py-1332-            reason = _exit_meaning(code) if code else "interrupted"
utils/py/marathon_drive.py-1333-            dest = os.path.join(phase_dir, "PHASE-INTERRUPTED.md")
--
utils/ate/install.sh-14-  rm -rf "${DEST_DIR}"
utils/ate/install.sh-15-  cp -R "${SRC_DIR}" "${DEST_DIR}"
utils/ate/install.sh-16-fi
utils/ate/install.sh:17:chmod +x "${DEST_DIR}"/scripts/*.py
utils/ate/install.sh-18-
utils/ate/install.sh-19-echo
utils/ate/install.sh-20-echo "Checking dependencies..."
--
utils/py/_marathon_plan.py-1325-        o.append("```")
utils/py/_marathon_plan.py-1326-        o.append("")
utils/py/_marathon_plan.py-1327-        o.append("- **Lane scoping:** give each lane an `ALLOW_PATHS` matching only its zone above.")
utils/py/_marathon_plan.py:1328:        o.append("- If the lane's allowlist includes filesystem-touching `test/*.sh`, treat those tests as read-only specs in-turn; the outer harness gate verifies them after the turn, outside the isolated worktree.")
utils/py/_marathon_plan.py-1329-        o.append("")
utils/py/_marathon_plan.py-1330-        o.append("---")
utils/py/_marathon_plan.py-1331-        o.append("")
--
utils/pdda/PDDA-INSTALL.md-8-## Fastest path: `install.sh`
utils/pdda/PDDA-INSTALL.md-9-
utils/pdda/PDDA-INSTALL.md-10-For a normal install, the repo-root `install.sh` automates this entire manifest — copy the runtime,
utils/pdda/PDDA-INSTALL.md:11:create the lifecycle tree, synthesize the blank seed files, `chmod`, and run a verification pass:
utils/pdda/PDDA-INSTALL.md-12-
utils/pdda/PDDA-INSTALL.md-13-```bash
utils/pdda/PDDA-INSTALL.md-14-./install.sh /path/to/target-repo          # observe mode, idempotent
--
utils/pdda/PDDA-INSTALL.md-178-4a. Add `PROJECT/PDDA-ACTIVITY.jsonl` and `.pdda-gh-state.tsv` to the target's `.gitignore` (and `git rm --cached` any that are already tracked). -> expect the churning runtime state to stop dirtying `git status` on every run.
utils/pdda/PDDA-INSTALL.md-179-4b. Record the install in the per-user, machine-local registry `${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv` (one tab-delimited row per target: `target · last_install_utc · mode · source_commit · startup_docs`; latest install wins). -> expect `pdda-sync.sh` to read this to find copies that are behind. Machine-local, never committed; `--no-register` or `PDDA_REGISTRY` adjust it.
utils/pdda/PDDA-INSTALL.md-180-4c. If git-pulse (a separate, GitHub-backed activity-sync tool) is present, also write a path-normalized projection of the registry into `<git-pulse-repo>/pdda/registry-<device>.tsv` (col 1 reduced to the bare repo name; **no absolute paths**), letting git-pulse's own sync roll PDDA install status up across devices. -> expect this to be best-effort and fail-open: absent git-pulse it is silently skipped and the install is unaffected. The local registry stays the source of truth. The git-pulse checkout is auto-detected: explicit `PDDA_GITPULSE_DIR` wins, else git-pulse's own `config.sh` `sync_repo_dir`, else the first existing of `${XDG_CONFIG_HOME:-$HOME/.config}/git-pulse/repo` or `~/git-pulse-sync`; set `PDDA_GITPULSE_DIR` to a nonexistent path to disable, and `--no-register` skips it too. **Hazard (GH-28):** if a machine has more than one git-pulse checkout on disk, `sync_repo_dir` always wins over the `~/git-pulse-sync` fallback — check which one is actually current with `origin` before assuming the projection reached your other devices. -> expect a follow-up warning (`warn: git-pulse checkout … is N commit(s) behind` / `… is uncommitted`) printed right after this step whenever the resolved checkout is dirty or behind its own upstream as of its last fetch (no network call is made here); the write to disk still always succeeds regardless.
utils/pdda/PDDA-INSTALL.md:181:5. Make the shell scripts executable. -> expect `chmod +x utils/pdda/pdda.sh utils/pdda/pdda-doc-ready.sh utils/pdda/pdda-lib.sh utils/pdda/pdda-catchup.sh utils/pdda/pdda-gh-refresh.sh utils/pdda/pdda-edit-doc-hook.sh utils/pdda/pdda-stop-doc-health.sh` to succeed.
utils/pdda/PDDA-INSTALL.md-182-6. Optionally create a repo-root `.pdda-mode` file with `observe` for first install. -> expect a non-destructive first run.
utils/pdda/PDDA-INSTALL.md-183-7. If the target repo uses a different doc layout, set environment overrides instead of editing the scripts first. -> expect the checks to honor the env vars below.
utils/pdda/PDDA-INSTALL.md-184-8. Run `utils/pdda/pdda.sh run` in the target repo. -> expect report-only behavior in `observe` mode and an append to `PROJECT/PDDA-ACTIVITY.jsonl`.
--
utils/pdda/PDDA-INSTALL.md-268-Run these commands in the target repo:
utils/pdda/PDDA-INSTALL.md-269-
utils/pdda/PDDA-INSTALL.md-270-```bash
utils/pdda/PDDA-INSTALL.md:271:chmod +x utils/pdda/pdda.sh utils/pdda/pdda-doc-ready.sh utils/pdda/pdda-lib.sh utils/pdda/pdda-catchup.sh
utils/pdda/PDDA-INSTALL.md-272-printf 'observe\n' > .pdda-mode
utils/pdda/PDDA-INSTALL.md-273-utils/pdda/pdda.sh run
utils/pdda/PDDA-INSTALL.md-274-```
--
utils/pdda/PDDA-INSTALL.md-307-utils/pdda/pdda-sync.sh push --force-resync   # overwrite DIVERGED targets (each backed up first)
utils/pdda/PDDA-INSTALL.md-308-
utils/pdda/PDDA-INSTALL.md-309-utils/pdda/pdda-sync.sh list                  # registered targets + mode/source-commit/sync state
utils/pdda/PDDA-INSTALL.md:310:utils/pdda/pdda-sync.sh status [/path/to/repo]# read-only: current/behind/diverged/missing/to-delete
utils/pdda/PDDA-INSTALL.md-311-utils/pdda/pdda-sync.sh remove /path/to/repo  # de-register, keep the target's files
utils/pdda/PDDA-INSTALL.md-312-utils/pdda/pdda-sync.sh prune                 # drop registry entries whose dir is gone
utils/pdda/PDDA-INSTALL.md-313-
--
utils/roadmap-dashboard.sh-1-#!/usr/bin/env bash
utils/roadmap-dashboard.sh:2:# utils/roadmap-dashboard.sh — render a read-only dashboard from ROADMAP.md (GH-27).
utils/roadmap-dashboard.sh-3-
utils/roadmap-dashboard.sh-4-set -euo pipefail
utils/roadmap-dashboard.sh-5-
--
utils/roadmap-dashboard.sh-197-output.push("");
utils/roadmap-dashboard.sh-198-output.push("# ROADMAP Dashboard");
utils/roadmap-dashboard.sh-199-output.push("");
utils/roadmap-dashboard.sh:200:output.push("Read-only derived view of the root [ROADMAP.md](ROADMAP.md) ledger.");
utils/roadmap-dashboard.sh-201-output.push("");
utils/roadmap-dashboard.sh-202-
utils/roadmap-dashboard.sh-203-for (const heading of ledgerSections) {
--
utils/py/releases_cycle.py-1-#!/usr/bin/env python3
utils/py/releases_cycle.py-2-"""GH-153: the RELEASES-cycle rollup — the full-ledger companion to the marathon rollup.
utils/py/releases_cycle.py-3-
utils/py/releases_cycle.py:4:One read-only pass over releases.db that answers "where does the whole cycle stand":
utils/py/releases_cycle.py-5-releases by status (with open targets and overdue counts), roadmap-shadow movement,
utils/py/releases_cycle.py-6-marathon states, manifest outcomes (dialed-in / shipped / cut) and the latest
utils/py/releases_cycle.py-7-append-only manifest state events. Two consumers share this module so the numbers can
--
utils/py/releases_cycle.py-12-  * utils/timeline/export_timeline.py — ships the summary inside the dashboard payload
utils/py/releases_cycle.py-13-    (the sidebar's "releases cycle" panel)
utils/py/releases_cycle.py-14-
utils/py/releases_cycle.py:15:Never writes to the database (read-only URI mode), so it is safe to run mid-merge.
utils/py/releases_cycle.py-16-
utils/py/releases_cycle.py-17-Usage:
utils/py/releases_cycle.py-18-  releases_cycle.py [--db releases.db] [--repo-label LABEL] [--json] [--events N]
utils/py/releases_cycle.py-19-
utils/py/releases_cycle.py:20:Exit codes: 0 ok · 2 DB missing/unreadable/not-a-ledger (callers degrade per repo).
utils/py/releases_cycle.py-21-"""
utils/py/releases_cycle.py-22-
utils/py/releases_cycle.py-23-import argparse
--
utils/py/consult.py-59-    if it carries zero citations anywhere, OR at least one claim-bearing line has no citation within
utils/py/consult.py-60-    `window` lines of itself (including its own line) — even though the file cites something
utils/py/consult.py-61-    elsewhere. Does NOT verify a citation is accurate, only that one was attempted nearby. Missing or
utils/py/consult.py:62:    unreadable file fails safe (flagged), matching the Bash version.
utils/py/consult.py-63-    """
utils/py/consult.py-64-    if window is None:
utils/py/consult.py-65-        window = _citation_window()
--
utils/py/consult.py-94-    ALREADY-CITED claim line in <transcript_path>, decide whether the nearby citation string was
utils/py/consult.py-95-    discovered firsthand in the transcript or merely echoed from the operator prompt text persisted
utils/py/consult.py-96-    in <prompt_path>. Yields ("ECHOED", token) or ("FIRSTHAND", token) per claim, matching the awk
utils/py/consult.py:97:    line-order. Missing/unreadable inputs yield nothing (mirrors the Bash early return). Known v0
utils/py/consult.py-98-    limitation (shared with Bash): exact/whitespace-normalized substring matching only — no fuzzy
utils/py/consult.py-99-    reformat matching."""
utils/py/consult.py-100-    if window is None:
--
utils/py/consult.py-514-        for m in models:
utils/py/consult.py-515-            if m == "codex":
utils/py/consult.py-516-                f_out = os.path.join(run_dir, f"{label}.codex.md")
utils/py/consult.py:517:                cflags = os.environ.get("CODEX_FLAGS", "-s read-only").split()
utils/py/consult.py-518-                cenv = dict(base_env)
utils/py/consult.py-519-                if os.environ.get("CODEX_ALLOW_API_KEY", "0") != "1":
utils/py/consult.py-520-                    cenv.pop("OPENAI_API_KEY", None)
--
utils/py/swarm_preflight.py-857-      no-issue-section— structural. The issue itself states no criteria, so the doc's list came from
utils/py/swarm_preflight.py-858-                        somewhere else and no retry will ever verify it. Blocks on a manifest member.
utils/py/swarm_preflight.py-859-      no-gh-issue     — the doc names no issue to compare against.
utils/py/swarm_preflight.py:860:      doc-unreadable  — the capture doc could not be read.
utils/py/swarm_preflight.py-861-      None            — `cause` is unset for `match`/`diverged`; it qualifies `unknown` only.
utils/py/swarm_preflight.py-862-    """
utils/py/swarm_preflight.py-863-    res = {"status": "unknown", "cause": None, "detail": "", "issue": issue_number,
--
utils/py/swarm_preflight.py-870-        with open(doc_path, 'r', encoding='utf-8') as f:
utils/py/swarm_preflight.py-871-            doc_text = f.read()
utils/py/swarm_preflight.py-872-    except Exception:
utils/py/swarm_preflight.py:873:        res["cause"] = "doc-unreadable"
utils/py/swarm_preflight.py:874:        res["detail"] = f"capture doc unreadable: {doc_path}"
utils/py/swarm_preflight.py-875-        return res
utils/py/swarm_preflight.py-876-
utils/py/swarm_preflight.py-877-    body = (issue_details or fetch_issue_details(issue_number, cwd)).get("body")
--
utils/py/active_explorer.py-256-print("target_cli: ok")
utils/py/active_explorer.py-257-sys.exit(0)
utils/py/active_explorer.py-258-""")
utils/py/active_explorer.py:259:        os.chmod(target_script, 0o755)
utils/py/active_explorer.py-260-
utils/py/active_explorer.py-261-        # 1. Family 1: Argv Grammar Mutations
utils/py/active_explorer.py-262-        argv_muts = generate_argv_mutations(["python3", target_script], max_variants=35)
--
utils/py/releases_app.py-85-DB_BAK_NAME = "releases.db.bak"
utils/py/releases_app.py-86-GEN_NAME = "RELEASES.generated.md"
utils/py/releases_app.py-87-DRIFT_NAME = "RELEASES.generated.md.drift"
utils/py/releases_app.py:88:LEDGER_NAME = "RELEASES.md"          # READ-ONLY for this tool, forever in Phase 0
utils/py/releases_app.py-89-LOCK_NAME = "releases-app.lock"
utils/py/releases_app.py-90-AUDIT_NAME = "releases-app-lock-audit.log"
utils/py/releases_app.py-91-JOURNAL_NAME = "releases-app-journal.json"
--
utils/py/releases_app.py-230-
utils/py/releases_app.py-231-
utils/py/releases_app.py-232-def _project_body(release):
utils/py/releases_app.py:233:    """Render the draft-card body; all GitHub state remains a read-only DB projection."""
utils/py/releases_app.py-234-    tracking = release["tracking_url"] or release["tracking_temp"] or "—"
utils/py/releases_app.py-235-    return """## Release
utils/py/releases_app.py-236-
--
utils/py/releases_app.py-249-
utils/py/releases_app.py-250----
utils/py/releases_app.py-251-
utils/py/releases_app.py:252:> Read-only projection from `releases.db`. Edit the release through the Releases CLI; GitHub Project edits do not synchronize back.
utils/py/releases_app.py-253-""" % (release["global_id"], release["milestone"] or "—", tracking,
utils/py/releases_app.py-254-       release["gh_release_url"] or "—", release["description"],
utils/py/releases_app.py-255-       release["exit_criterion"] or "Not recorded")
--
utils/py/releases_app.py-1557-    paths = artifact_paths(root)
utils/py/releases_app.py-1558-    lines = ["releases-app drift report (GH-32 Phase 0, side-by-side)",
utils/py/releases_app.py-1559-             "generated: %s" % now_iso(),
utils/py/releases_app.py:1560:             "real ledger: %s (READ-ONLY — never written by this tool)" % paths["ledger"],
utils/py/releases_app.py-1561-             ""]
utils/py/releases_app.py-1562-    if not os.path.exists(paths["ledger"]):
utils/py/releases_app.py-1563-        lines.append("no real RELEASES.md present — nothing to drift against")

2026-08-26T03:35:25.264577Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "rg -l 'git-sandbox-guard: REFUSING|config.*writable|operation.*not attempted' . --glob '"'!temp/**'"' --glob '"'!relay-system/**'"' && nl -ba .github/workflows/ci.yml | sed -n '210,505p' && nl -ba test/gh50-sandboxed-git-guard.sh && nl -ba test/security-scan.sh | sed -n '220,355p'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z
 succeeded in 0ms:
./CHANGELOG.md
./validate.sh
./ROADMAP.md
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md
./releases.sql
./utils/git-sandbox-guard.sh
./test/gh50-sandboxed-git-guard.sh
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md
./PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/brief-gh50-sandboxed-git-guard.md
./PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/MARATHON.yaml
   210	  # GH-509 Phase 2 — this job is a PORTABILITY CANARY, not a gate.
   211	  #
   212	  # XYZ ships to macOS developers. Linux and Windows are on the roadmap and are not here yet, so a
   213	  # failure on ubuntu is portability DRIFT, not breakage: it says "this would not work on the platform
   214	  # we do not support yet." Every one of the three CI failures on 2026-08-12 was of exactly that shape
   215	  # (agent CLIs absent from the runner), and treating them as breakage is what produced five hours of
   216	  # unread red across eight commits — which is worse than no signal at all, because it trains everyone
   217	  # to ignore the one channel that might have said something real.
   218	  #
   219	  # `continue-on-error: true` at JOB level lets the workflow run pass while this job's own conclusion
   220	  # still records `failure`, so drift stays queryable through the jobs API without marking the commit
   221	  # broken.
   222	  #
   223	  # HONEST LIMIT, stated because this file is exactly the kind of place GH-419 gets violated: the
   224	  # workflow-contract test can assert this key is PRESENT. It cannot assert GitHub's runtime semantics.
   225	  # The acceptance criterion in PROJECT/2-WORKING/GH-509-CI-MINUTE-BURN.md is therefore a witnessed
   226	  # hosted run, not a green grep.
   227	  #
   228	  # Advisory does NOT mean ignorable, and making it non-blocking supplies no reason for anyone to read
   229	  # it — that critique came from the agy review and it is correct. The mechanism that makes it read is
   230	  # elsewhere: the canary's status is a line in the promotion output, consulted at the moment a human
   231	  # is already deciding something. If two consecutive promotions ship with drift named and unresolved,
   232	  # this job has proven it is not being actioned and should be deleted rather than kept as decoration.
   233	  canary-ubuntu:
   234	    name: portability canary (ubuntu — advisory, never breakage)
   235	    runs-on: starsling-ubuntu-24.04-8
   236	    continue-on-error: true
   237	    steps:
   238	      - name: Check out repo
   239	        uses: actions/checkout@v4
   240	        with:
   241	          # GH-232: several tests (e.g. xyz-vendor.sh's staleness check) use `git rev-list
   242	          # --max-parents=0 HEAD` to synthesize an "older" ancestor commit for a fixture. The
   243	          # default shallow clone (depth 1) makes the boundary commit look parentless, so it
   244	          # resolves to the SAME commit as HEAD — silently defeating the fixture, not a real bug.
   245	          fetch-depth: 0
   246	
   247	      - name: Classify CI route
   248	        id: route
   249	        env:
   250	          EVENT_NAME: ${{ github.event_name }}
   251	          BASE_SHA: ${{ github.event.pull_request.base.sha }}
   252	          BEFORE_SHA: ${{ github.event.before }}
   253	        run: |
   254	          set -euo pipefail
   255	
   256	          # GH-509 Phase 3 — pushes classify from their pushed range, like PRs classify from a diff.
   257	          base=""
   258	          case "$EVENT_NAME" in
   259	            pull_request) base="$BASE_SHA" ;;
   260	            push)         base="$BEFORE_SHA" ;;
   261	          esac
   262	
   263	          # FAIL CLOSED, three ways, all reachable in practice:
   264	          #   * a NEW branch's first push sets `before` to all-zeros — there is no range;
   265	          #   * a FORCE-PUSH leaves a `before` that is no longer reachable in this clone;
   266	          #   * an event with no range concept at all (workflow_dispatch handles itself downstream).
   267	          # Any of these emits an empty path list, and ci-route.sh's zero-path branch routes to full.
   268	          # Reusing that already-tested path beats inventing a second fail-closed rule that would
   269	          # need its own proof.
   270	          usable=1
   271	          if [ -z "$base" ] || [ -z "${base//0/}" ]; then
   272	            usable=0
   273	          elif ! git cat-file -e "${base}^{commit}" 2>/dev/null; then
   274	            usable=0
   275	          fi
   276	
   277	          if [ "$usable" -eq 1 ]; then
   278	            # `--no-renames` is load-bearing, not tidiness. With rename detection ON (git's default)
   279	            # `--name-only` prints ONLY the destination path for a rename, so a renamed regression
   280	            # test looks like an ordinary changed file that still exists — and ci-route.sh's
   281	            # fail-closed branch for a vanished test is never reached. That branch's own comment
   282	            # says "deleted/renamed"; without this flag it only ever saw deletions.
   283	            git diff --no-renames --name-only "$base" HEAD \
   284	              | utils/ci-route.sh "$EVENT_NAME" | tee -a "$GITHUB_OUTPUT"
   285	          else
   286	            echo "ci-route: no usable range for $EVENT_NAME (base='${base:-<empty>}') — failing closed to full" >&2
   287	            : | utils/ci-route.sh "$EVENT_NAME" | tee -a "$GITHUB_OUTPUT"
   288	          fi
   289	
   290	      - name: Install shellcheck
   291	        if: steps.route.outputs.docs_only != 'true'
   292	        run: |
   293	          set -euo pipefail
   294	          if command -v shellcheck >/dev/null 2>&1; then
   295	            shellcheck --version
   296	          else
   297	            sudo apt-get update
   298	            sudo apt-get install -y shellcheck
   299	          fi
   300	
   301	      - name: Shellcheck tracked shell scripts
   302	        if: steps.route.outputs.docs_only != 'true'
   303	        run: |
   304	          set -euo pipefail
   305	          # Start at severity=error so Tier 1 lands green; tighten later once the backlog is burned down.
   306	          git ls-files -- '*.sh' | while IFS= read -r file; do
   307	            [ -n "$file" ] || continue
   308	            shellcheck -S error "$file"
   309	          done
   310	
   311	      - name: Bash syntax check tracked shell scripts
   312	        if: steps.route.outputs.docs_only != 'true'
   313	        run: |
   314	          set -euo pipefail
   315	          git ls-files -- '*.sh' | while IFS= read -r file; do
   316	            [ -n "$file" ] || continue
   317	            bash -n "$file"
   318	          done
   319	
   320	      - name: Node syntax check tracked JavaScript
   321	        if: steps.route.outputs.docs_only != 'true'
   322	        run: |
   323	          set -euo pipefail
   324	          git ls-files -- 'src/*.js' 'bin/*.js' | while IFS= read -r file; do
   325	            [ -n "$file" ] || continue
   326	            node --check "$file"
   327	          done
   328	
   329	      - name: Validate .claude/settings JSON
   330	        if: steps.route.outputs.docs_only != 'true'
   331	        run: |
   332	          set -euo pipefail
   333	          git ls-files -- '.claude/settings*.json' | while IFS= read -r file; do
   334	            [ -n "$file" ] || continue
   335	            python3 -m json.tool "$file" >/dev/null
   336	          done
   337	
   338	      - name: Run PDDA deterministic gate
   339	        # PDDA owns documentation state. Run it when that state changes and at every full boundary,
   340	        # but keep its ~2.5-minute scan out of code-only fast PRs.
   341	        if: steps.route.outputs.pdda_needed == 'true'
   342	        run: |
   343	          set -euo pipefail
   344	          utils/pdda/pdda.sh run
   345	          # Checks this repo owns, kept OUTSIDE the sync-managed utils/pdda/ tree because the
   346	          # 2026-08-03 sync (cfd56b0) deleted three of them from upstream's script without a word.
   347	          # Warn-only by contract — it reports, it never gates.
   348	          utils/pdda-local-checks.sh run
   349	
   350	      # GH-308 froze the eleven Tier-A Bash twins and AGENTS.md told readers "CI supplies
   351	      # GH308_FROZEN_TWIN_BASE to reject a committed twin edit". Nothing did — the agy review of
   352	      # PR #318 caught the claim as false ([Blocker]). This is that wiring.
   353	      #
   354	      # Escape hatch: a safety defect in a frozen fallback can legitimately warrant an edit (GH-319
   355	      # left a silently-fake pre-advance gate in marathon-drive.sh under XYZ_PYTHON=0). Such a commit
   356	      # must carry a trailer naming the twin it covers, which makes the exception auditable in
   357	      # `git log` instead of invisible:
   358	      #
   359	      #   Frozen-twin-exception: relay-automation/marathon-drive.sh — <reason>
   360	      #
   361	      # GH-321: the rule used to live here, inline, and was RANGE-scoped — one trailer anywhere in
   362	      # BASE..HEAD excused every frozen twin touched in the PR, including files nobody declared. It
   363	      # now lives in the guard script as `--allow-exceptions`, per-file, so it can be tested; inline
   364	      # YAML shell is unreachable from the suite, which is part of why the looseness shipped at all.
   365	      - name: Frozen Bash twin guard (GH-308)
   366	        if: github.event_name == 'pull_request'
   367	        env:
   368	          BASE_SHA: ${{ github.event.pull_request.base.sha }}
   369	        run: |
   370	          set -euo pipefail
   371	          bash test/gh308-frozen-twin-guard.sh --check --base "$BASE_SHA" --allow-exceptions
   372	
   373	      # GH-230: prove the README Quickstart's npm-dependency path works from a fresh
   374	      # clone, so a missing-install-step regression fails here instead of on a
   375	      # newcomer's machine.
   376	      - name: Install npm dependencies and run acorn-extract test
   377	        if: steps.route.outputs.docs_only != 'true'
   378	        run: |
   379	          set -euo pipefail
   380	          npm ci
   381	          bash test/acorn-extract.sh
   382	
   383	      # GH-232: the acting-agent's user/keychain config and default `git init` branch name are
   384	      # macOS-dev-machine assumptions baked into several fixture-driven tests (e.g. archive-writers.sh,
   385	      # xyz-vendor.sh do a bare `git init` and expect the resulting branch to be "main"). ubuntu-latest's
   386	      # git has no global identity and may default new repos to a non-"main" branch, so prepare both
   387	      # here rather than touch the tests themselves (out of scope for this lane).
   388	      - name: Prepare git environment for fixture-driven tests
   389	        if: steps.route.outputs.docs_only != 'true'
   390	        run: |
   391	          set -euo pipefail
   392	          git config --global init.defaultBranch main
   393	          git config --global user.email "ci@runner.invalid"
   394	          git config --global user.name "CI Runner"
   395	
   396	      - name: Run Fast Gate tests (Pull Request)
   397	        # Whole-job budget target: < 3 minutes for a code-only fast PR.
   398	        if: github.event_name == 'pull_request' && steps.route.outputs.route == 'fast'
   399	        env:
   400	          RELAY_SELF_SUFFICIENCY_SKIP: "1"
   401	          CHANGED_TESTS: ${{ steps.route.outputs.changed_tests }}
   402	        run: |
   403	          set -euo pipefail
   404	          FAST_TESTS=(
   405	            "worktree-isolation.sh"
   406	            "shim-worktree.sh"
   407	            "gh292-worktree-vendored-discovery.sh"
   408	            "relay-target-root.sh"
   409	            "relay-target-root-paths.sh"
   410	            "relay-target-root-relayfile.sh"
   411	            "relay-target-root-newfile.sh"
   412	            "gh289-target-root-build-turn.sh"
   413	            "gh410-containment-advisory.sh"
   414	            "tick-foreign-cwd.sh"
   415	            "mktemp-trap-guard.sh"
   416	          )
   417	          if [[ -n "$CHANGED_TESTS" ]]; then
   418	            IFS=',' read -r -a routed_tests <<<"$CHANGED_TESTS"
   419	            for t in "${routed_tests[@]}"; do
   420	              already_listed=0
   421	              for existing in "${FAST_TESTS[@]}"; do
   422	                [[ "$existing" == "$t" ]] && { already_listed=1; break; }
   423	              done
   424	              [[ "$already_listed" -eq 1 ]] || FAST_TESTS+=("$t")
   425	            done
   426	          fi
   427	          FAILED=0
   428	          for t in "${FAST_TESTS[@]}"; do
   429	            echo "=== $t ==="
   430	            bash "test/$t" || FAILED=1
   431	          done
   432	          exit "$FAILED"
   433	
   434	      # GH-232: PR #231 ran the full ./validate.sh suite on ubuntu-latest for the first time and
   435	      # found ~12 failures, assumed to be Ubuntu-environment-only and scoped out of CI. Re-diagnosed
   436	      # directly against a real ubuntu:latest container (not guessed at from macOS): almost all were
   437	      # masked by two things, now both fixed — (1) marathon.sh/marathon-drive.sh (and dependents
   438	      # debug-mantra.sh/driver-lock.sh) used a BSD-only `sed -i ''` invocation that mis-parses under
   439	      # GNU sed; (2) driver-lock.sh/xyz-harness-hooks.sh stubbed CLAUDE_BIN/AGY_BIN but not
   440	      # CODEX_BIN — the actual default builder — so they only "passed" locally because a real `codex`
   441	      # binary happened to be on the developer's own PATH, masking the gap; ubuntu CI has no such
   442	      # binary. path-integrity.sh/archive-writers.sh/relay-file-seeding-visibility.sh/xyz-vendor.sh/
   443	      # hq.sh/relay-pkg-freshness.sh all passed cleanly once re-tested for real — no ubuntu-specific
   444	      # bug in any of them. Only registry-lock-concurrency.sh (GH-72, a documented 16-concurrent-writer
   445	      # lock-contention flake under CI load, unrelated to this issue) stays skipped.
   446	      - name: Run validate.sh suite (minus a documented flaky test)
   447	        if: steps.route.outputs.route == 'full'
   448	        env:
   449	          RELAY_SELF_SUFFICIENCY_SKIP: "1"
   450	        run: |
   451	          set -euo pipefail
   452	          SKIP_TESTS=(
   453	            "acorn-extract.sh"                    # already run above (needs npm ci first)
   454	            "registry-lock-concurrency.sh"          # GH-72/GH-232: flaky under CI load (16 concurrent tick writers → lock contention / lost row); passes locally, flaked 3 runs across PRs #257/#259
   455	            "pdda-repo-contract.sh"               # already run in PDDA step
   456	          )
   457	          ALL_TESTS=()
   458	          while IFS= read -r line; do
   459	            [ -n "$line" ] && ALL_TESTS+=("$line")
   460	          done < <(sed -n '/^TESTS=(/,/^)/p' validate.sh | grep -oE '"[^"]+\.sh"' | tr -d '"')
   461	          FAILED=0
   462	          for t in "${ALL_TESTS[@]}"; do
   463	            skip=0
   464	            for s in "${SKIP_TESTS[@]}"; do
   465	              [ "$t" = "$s" ] && { skip=1; break; }
   466	            done
   467	            if [ "$skip" -eq 1 ]; then
   468	              echo "SKIP (GH-232): $t"
   469	              continue
   470	            fi
   471	            echo "=== $t ==="
   472	            bash "test/$t" || FAILED=1
   473	          done
   474	          exit "$FAILED"
   475	
   476	      # GH-509 Phase 2 — the canary's verdict, written where a human and a script can both find it.
   477	      #
   478	      # `if: always()` because the whole point is to report when an EARLIER step failed; without it
   479	      # this step is skipped in exactly the case it exists for. `job.status` is the aggregate of the
   480	      # steps above, so this reads the outcome rather than re-deriving it.
   481	      #
   482	      # The line is deliberately greppable and deliberately does NOT say "failed" or "error": on this
   483	      # platform those words are wrong. This job reports on an operating system we do not ship to yet.
   484	      - name: Portability canary verdict
   485	        if: always()
   486	        run: |
   487	          set -euo pipefail
   488	          if [ "${{ job.status }}" = "success" ]; then
   489	            verdict="PORTABILITY-CANARY: green"
   490	            detail="No Linux portability drift detected. This says nothing about macOS, which is what we ship."
   491	          else
   492	            verdict="PORTABILITY-CANARY: drift"
   493	            detail="Linux portability drift on ${GITHUB_SHA}. This is NOT breakage: XYZ ships to macOS and Linux support is not here yet. Do not treat this commit as broken. Carry the drift into the promotion output and resolve it before Linux support ships."
   494	          fi
   495	          echo "$verdict"
   496	          echo "$detail"
   497	          { echo "### $verdict"; echo; echo "$detail"; } >> "$GITHUB_STEP_SUMMARY"
     1	#!/usr/bin/env bash
     2	set -uo pipefail
     3	
     4	# gh50-sandboxed-git-guard.sh — GH-50: a guarded tracking switch must refuse
     5	# before it can rewrite the index or working tree when .git/config is read-only.
     6	
     7	HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
     8	ROOT="$(cd "$HERE/.." && pwd)"
     9	GUARD="$ROOT/utils/git-sandbox-guard.sh"
    10	
    11	pass=0
    12	fail=0
    13	ok() {
    14	  label="$1"
    15	  shift
    16	  if "$@"; then
    17	    echo "  PASS: $label"
    18	    pass=$((pass + 1))
    19	  else
    20	    echo "  FAIL: $label" >&2
    21	    fail=$((fail + 1))
    22	  fi
    23	}
    24	
    25	echo "== test: gh50-sandboxed-git-guard =="
    26	
    27	WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh50-sandbox-guard.XXXXXX")"
    28	. "$HERE/lib/fixture-guard.sh"
    29	fixture_guard_init "$WORK"
    30	cleanup() {
    31	  [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"
    32	}
    33	trap cleanup EXIT
    34	
    35	R="$WORK/repo"
    36	mkdir -p "$R"
    37	require_fixture "$R" "GH-50 repository"
    38	
    39	git -C "$R" init -q
    40	git -C "$R" config user.email test@example.invalid
    41	git -C "$R" config user.name "GH-50 test"
    42	printf 'main\n' > "$R/payload.txt"
    43	git -C "$R" add payload.txt
    44	git -C "$R" commit -qm main
    45	git -C "$R" branch -M main
    46	git -C "$R" switch -qc topic
    47	printf 'topic\n' > "$R/payload.txt"
    48	git -C "$R" commit -qam topic
    49	git -C "$R" switch -q main
    50	
    51	CONFIG="$R/.git/config"
    52	require_fixture_file "$CONFIG" "GH-50 config"
    53	cp "$R/payload.txt" "$WORK/payload.before"
    54	cp "$CONFIG" "$WORK/config.before"
    55	chmod a-w "$CONFIG"
    56	
    57	OUT="$WORK/refusal.out"
    58	"$GUARD" --repo "$R" --operation "git switch --track" -- \
    59	  git -C "$R" switch --track -c tracked topic >"$OUT" 2>&1
    60	rc=$?
    61	
    62	ok "guard refuses the read-only config with exit 2" test "$rc" -eq 2
    63	ok "refusal is named and says the operation was not attempted" \
    64	  grep -q "git-sandbox-guard: REFUSING.*not attempted (GH-50)" "$OUT"
    65	ok "refusal names the config write problem" grep -q "config.*not writable" "$OUT"
    66	ok "working-tree payload is byte-identical after refusal" cmp -s "$WORK/payload.before" "$R/payload.txt"
    67	ok "HEAD remains on main after refusal" test "$(git -C "$R" symbolic-ref --short HEAD)" = main
    68	if git -C "$R" show-ref --verify --quiet refs/heads/tracked; then
    69	  echo "  FAIL: refused command created the tracked branch" >&2
    70	  fail=$((fail + 1))
    71	else
    72	  echo "  PASS: refused command did not create the tracked branch"
    73	  pass=$((pass + 1))
    74	fi
    75	ok "config bytes are unchanged after refusal" cmp -s "$WORK/config.before" "$CONFIG"
    76	ok "config-lock probe leaves no lock behind" test ! -e "$CONFIG.lock"
    77	
    78	# Control: once config writes are possible, the wrapper must run the exact command rather
    79	# than acting as a blanket branch-operation ban.
    80	chmod u+w "$CONFIG"
    81	"$GUARD" --repo "$R" --operation "git switch --track" -- \
    82	  git -C "$R" switch --track -c tracked topic >"$WORK/control.out" 2>&1
    83	control_rc=$?
    84	ok "writable-config control executes the guarded command" test "$control_rc" -eq 0
    85	ok "writable-config control reaches the topic content" grep -q '^topic$' "$R/payload.txt"
    86	ok "writable-config control switches to the new branch" \
    87	  test "$(git -C "$R" symbolic-ref --short HEAD)" = tracked
    88	
    89	echo "  gh50-sandboxed-git-guard: $pass pass, $fail fail"
    90	[ "$fail" -eq 0 ]
   220	check_secret_survives_adjacent_ref "same-line-two-assigns" \
   221	  'password=$REF; api_key=hunter2supersecretvalue' \
   222	  'api_key=hunter2supersecretvalue'
   223	check_secret_survives_adjacent_ref "trailing-comment" \
   224	  'api_key=hunter2supersecretvalue  # password=$VAR' \
   225	  'api_key=hunter2supersecretvalue'
   226	
   227	# ---------------------------------------------------------------------------
   228	# Regression (agy relay QA, 2026-07-01, [Should] + a self-caught fix-of-the-fix): an unreadable file
   229	# (grep exit 2+, not the "no match" exit 1) must fail loud, not silently read as clean — AND the
   230	# error report must not abort the rest of the scan under `set -e` (the first version of this fix
   231	# propagated the error's nonzero return through _check() to scan_file() to main()'s file loop,
   232	# silently ending the ENTIRE scan after the first unreadable file — worse than the bug it fixed).
   233	# ---------------------------------------------------------------------------
   234	
   235	UNREADABLE_DIR="$WORK/unreadable-fixture"
   236	mkdir -p "$UNREADABLE_DIR"
   237	UNREADABLE_FILE="$UNREADABLE_DIR/locked.sh"
   238	printf '#!/usr/bin/env bash\neval "$X"\n' > "$UNREADABLE_FILE"
   239	OTHER_FILE="$UNREADABLE_DIR/z-also-bad.sh"
   240	printf '#!/usr/bin/env bash\neval "$ALSO_BAD"\n' > "$OTHER_FILE"
   241	chmod 000 "$UNREADABLE_FILE"
   242	
   243	RC=0
   244	STDOUT_UNREAD="$WORK/stdout-unreadable.txt"
   245	STDERR_UNREAD="$WORK/stderr-unreadable.txt"
   246	bash "$SCANNER" --no-baseline "$UNREADABLE_DIR" >"$STDOUT_UNREAD" 2>"$STDERR_UNREAD" || RC=$?
   247	chmod 644 "$UNREADABLE_FILE"
   248	
   249	[[ "$RC" -ne 0 ]] && pass "unreadable file: scanner fails loud (exit $RC), not silently clean" \
   250	  || fail "unreadable file: scanner should fail, got exit 0"
   251	grep -q "scan-error" "$STDERR_UNREAD" 2>/dev/null \
   252	  && pass "unreadable file: flagged with [scan-error], not silently skipped" \
   253	  || fail "unreadable file: no [scan-error] finding: $(cat "$STDERR_UNREAD")"
   254	[[ "$(grep -c "scan-error" "$STDERR_UNREAD" 2>/dev/null)" -eq 1 ]] \
   255	  && pass "unreadable file: scan-error reported once per file, not once per rule" \
   256	  || fail "unreadable file: expected 1 scan-error line, got $(grep -c "scan-error" "$STDERR_UNREAD" 2>/dev/null)"
   257	grep -qF "ALSO_BAD" "$STDERR_UNREAD" 2>/dev/null \
   258	  && pass "unreadable file: scan CONTINUES to the next file (not silently aborted mid-scan)" \
   259	  || fail "unreadable file: scan stopped before reaching the next file — set -e propagation bug"
   260	
   261	# ---------------------------------------------------------------------------
   262	# Regression (agy relay QA round 2, 2026-07-01, [Should]): the per-occurrence R7 rewrite's unquoted
   263	# value token stops at the first space, so a QUOTED value containing an internal space matched
   264	# nothing at all — completely missed, not just truncated.
   265	# ---------------------------------------------------------------------------
   266	check_quoted_value_with_spaces() {
   267	  local tmpf="$WORK/quoted-space.sh"
   268	  printf 'password="pw secret"\n' > "$tmpf"
   269	  local rc=0 stderr_out
   270	  stderr_out="$(bash "$SCANNER" --no-baseline "$tmpf" 2>&1 >/dev/null)" || rc=$?
   271	  if grep -qF 'password="pw secret"' <<<"$([[ "$rc" -ne 0 ]] && echo "$stderr_out")"; then
   272	    pass "quoted value with internal space is caught (previously matched nothing)"
   273	  else
   274	    fail "quoted value with internal space NOT caught (rc=$rc): $stderr_out"
   275	  fi
   276	}
   277	check_quoted_value_with_spaces
   278	
   279	# ---------------------------------------------------------------------------
   280	# Baseline (GH-64) — a pre-approved finding is still printed but doesn't fail the scan;
   281	# --no-baseline bypasses it; a NON-baselined finding in the same file still fails.
   282	# ---------------------------------------------------------------------------
   283	
   284	BASE_DIR="$WORK/baseline-fixture"
   285	mkdir -p "$BASE_DIR"
   286	BASE_FIXTURE="$BASE_DIR/mixed.sh"
   287	cat > "$BASE_FIXTURE" <<'MIXEDEOF'
   288	#!/usr/bin/env bash
   289	eval "$KNOWN_GOOD"
   290	eval "$BRAND_NEW_ONE"
   291	MIXEDEOF
   292	BASE_FILE="$WORK/baseline.txt"
   293	printf '# comment line, ignored\n\nmixed.sh\teval-unsanitized\teval "$KNOWN_GOOD"\n' > "$BASE_FILE"
   294	
   295	RC=0
   296	STDERR_BASE="$WORK/stderr-baseline.txt"
   297	( cd "$BASE_DIR" && bash "$SCANNER" --baseline "$BASE_FILE" "mixed.sh" ) >/dev/null 2>"$STDERR_BASE" || RC=$?
   298	[[ "$RC" -ne 0 ]] && pass "baseline: still exits non-zero when a non-baselined finding remains" \
   299	  || fail "baseline: should still fail on the non-baselined line, got exit 0"
   300	grep -q "SECURITY (baselined):.*KNOWN_GOOD" "$STDERR_BASE" 2>/dev/null \
   301	  && pass "baseline: baselined finding is still PRINTED (not hidden)" \
   302	  || fail "baseline: baselined finding missing from output — GUIDING-PRINCIPLES #8 violation risk"
   303	grep -qE '^SECURITY: .*BRAND_NEW_ONE' "$STDERR_BASE" 2>/dev/null \
   304	  && pass "baseline: non-baselined finding still reported as a plain SECURITY line" \
   305	  || fail "baseline: non-baselined finding not reported: $(cat "$STDERR_BASE")"
   306	
   307	# Baseline every line in the fixture → clean, exit 0.
   308	printf '# comment\nmixed.sh\teval-unsanitized\teval "$KNOWN_GOOD"\nmixed.sh\teval-unsanitized\teval "$BRAND_NEW_ONE"\n' > "$BASE_FILE"
   309	RC=0
   310	( cd "$BASE_DIR" && bash "$SCANNER" --baseline "$BASE_FILE" "mixed.sh" ) >/dev/null 2>/dev/null || RC=$?
   311	[[ "$RC" -eq 0 ]] && pass "baseline: fully-baselined fixture exits 0" || fail "baseline: expected exit 0, got $RC"
   312	
   313	# --no-baseline bypasses the baseline file entirely, even when it would fully cover the fixture.
   314	RC=0
   315	STDERR_NOBASE="$WORK/stderr-nobaseline.txt"
   316	( cd "$BASE_DIR" && bash "$SCANNER" --no-baseline --baseline "$BASE_FILE" "mixed.sh" ) >/dev/null 2>"$STDERR_NOBASE" || RC=$?
   317	[[ "$RC" -ne 0 ]] && pass "baseline: --no-baseline ignores the baseline file (raw scan fails)" \
   318	  || fail "baseline: --no-baseline should still fail raw, got exit 0"
   319	! grep -q "baselined" "$STDERR_NOBASE" 2>/dev/null \
   320	  && pass "baseline: --no-baseline output has no 'baselined' labels" \
   321	  || fail "baseline: --no-baseline leaked a baselined label"
   322	
   323	# --tsv emits `file\trule\ttext` — the format the baseline file itself uses, so a reviewer can
   324	# paste a row straight in.
   325	TSV_OUT="$(cd "$BASE_DIR" && bash "$SCANNER" --no-baseline --tsv "mixed.sh" 2>/dev/null || true)"
   326	TSV_EXPECT="$(printf 'mixed.sh\teval-unsanitized\teval "$KNOWN_GOOD"')"
   327	grep -qF "$TSV_EXPECT" <<<"$(printf '%s\n' "$TSV_OUT")" \
   328	  && pass "baseline: --tsv emits tab-separated file/rule/text" \
   329	  || fail "baseline: --tsv output malformed: $TSV_OUT"
   330	
   331	# ---------------------------------------------------------------------------
   332	# GH-64 active gate: the REAL repo, scanned with the checked-in baseline, must be clean. This is
   333	# what turns the scanner from an advisory tool into a genuine blocking gate in validate.sh — any
   334	# newly introduced eval/secret/curl-pipe pattern fails validate.sh until it's fixed or (after human
   335	# review) added to relay-automation/hooks/security-scan-baseline.txt.
   336	# ---------------------------------------------------------------------------
   337	
   338	RC=0
   339	REAL_OUT="$(bash "$SCANNER" 2>&1)" || RC=$?
   340	[[ "$RC" -eq 0 ]] && pass "GH-64 active gate: the real repo tree is clean against the checked-in baseline" \
   341	  || fail "GH-64 active gate: real repo has NON-baselined findings — fix them or review+add to the baseline: $REAL_OUT"
   342	
   343	# ---------------------------------------------------------------------------
   344	# Summary
   345	# ---------------------------------------------------------------------------
   346	
   347	echo ""
   348	echo "security-scan: $PASS pass, $FAIL fail"
   349	[[ "$FAIL" -eq 0 ]]

2026-08-26T03:35:32.091991Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "nl -ba utils/git-sandbox-guard.sh && nl -ba relay-automation/hooks/security-scan.sh | sed -n '1,360p' && rg -n -C 2 'git-sandbox-guard\\.sh|sandbox-guard|security-scan\\.sh|security-scan' --glob '"'!temp/**'"' --glob '"'!relay-system/**'"' --glob '"'!test/gh50-sandboxed-git-guard.sh'"' --glob '"'!test/security-scan.sh'"' ." in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	set -euo pipefail
     3	
     4	# git-sandbox-guard.sh — GH-50: prove the repository config can be written before a
     5	# branch-changing command gets a chance to rewrite the index or working tree.
     6	
     7	usage() {
     8	  cat >&2 <<'USAGE'
     9	Usage: utils/git-sandbox-guard.sh [--repo <path>] [--operation <label>] [--] [command ...]
    10	
    11	Preflight only when no command is supplied. When a command is supplied, run it only
    12	after the repository's config and config-lock path both pass a real write probe.
    13	USAGE
    14	}
    15	
    16	refuse() {
    17	  echo "git-sandbox-guard: REFUSING — $*" >&2
    18	  exit 2
    19	}
    20	
    21	repo="."
    22	operation="git branch mutation"
    23	while [ "$#" -gt 0 ]; do
    24	  case "$1" in
    25	    --repo)
    26	      [ "$#" -ge 2 ] || { usage; exit 2; }
    27	      repo="$2"
    28	      shift 2
    29	      ;;
    30	    --operation)
    31	      [ "$#" -ge 2 ] || { usage; exit 2; }
    32	      operation="$2"
    33	      shift 2
    34	      ;;
    35	    --)
    36	      shift
    37	      break
    38	      ;;
    39	    -h|--help)
    40	      usage
    41	      exit 0
    42	      ;;
    43	    *)
    44	      usage
    45	      exit 2
    46	      ;;
    47	  esac
    48	done
    49	
    50	[ -n "$repo" ] || refuse "repository path is empty; '$operation' was not attempted (GH-50)"
    51	[ -d "$repo" ] || refuse "repository '$repo' is not a directory; '$operation' was not attempted (GH-50)"
    52	
    53	common_dir="$(git -C "$repo" rev-parse --git-common-dir 2>/dev/null)" ||
    54	  refuse "cannot resolve the git common directory for '$repo'; '$operation' was not attempted (GH-50)"
    55	case "$common_dir" in
    56	  /*) common_abs="$common_dir" ;;
    57	  *)
    58	    common_abs="$(cd "$repo" && cd "$common_dir" 2>/dev/null && pwd -P)" ||
    59	      refuse "cannot resolve git common directory '$common_dir'; '$operation' was not attempted (GH-50)"
    60	    ;;
    61	esac
    62	
    63	config="$common_abs/config"
    64	[ -f "$config" ] || refuse "git config '$config' is missing; '$operation' was not attempted (GH-50)"
    65	
    66	# Opening the real file for a zero-byte append tests the exact sandbox permission without
    67	# changing its bytes. Git's config writer also creates config.lock and renames it over config,
    68	# so probe that path too. Noclobber makes a concurrent legitimate lock a loud refusal.
    69	if ! { : >> "$config"; } 2>/dev/null; then
    70	  refuse "git config '$config' is not writable; '$operation' was not attempted (GH-50)"
    71	fi
    72	
    73	config_lock="$config.lock"
    74	if ! ( set -C; : > "$config_lock" ) 2>/dev/null; then
    75	  refuse "git config lock '$config_lock' cannot be created; '$operation' was not attempted (GH-50)"
    76	fi
    77	if ! rm -f -- "$config_lock"; then
    78	  refuse "git config lock probe '$config_lock' cannot be removed; '$operation' was not attempted (GH-50)"
    79	fi
    80	
    81	[ "$#" -gt 0 ] || exit 0
    82	"$@"
     1	#!/usr/bin/env bash
     2	#
     3	# security-scan.sh — static security scanner for shell scripts (GH-64)
     4	#
     5	# Implements fail-loud detection per GUIDING-PRINCIPLES.md #8 (no masked failure):
     6	# every finding is printed to stderr as SECURITY: <file>:<line> <reason>, and the
     7	# script exits NON-ZERO if any finding is emitted.  It never auto-fixes, never
     8	# silently suppresses.  No network access required.
     9	#
    10	# Usage:
    11	#   bash relay-automation/hooks/security-scan.sh [--no-baseline] [--baseline FILE] [--tsv] [<path>...]
    12	#
    13	# --tsv prints each finding as `<file>\t<rule>\t<line text>` on stdout instead of the human-readable
    14	# "SECURITY: ..." line — paste a row straight into the baseline file's tab-separated columns after
    15	# confirming by hand it's a false positive / an accepted pattern (never generated automatically).
    16	#
    17	# With no path arguments, scans the paths listed in DEFAULT_SCAN_PATHS below.
    18	# Each path argument may be a file or a directory (scanned recursively for *.sh files).
    19	#
    20	# Baseline (GH-64): a known-legitimate finding (a reviewed dispatcher `eval`, a test fixture, a doc
    21	# comment matching a pattern in prose) is pre-approved by an exact `<file>\t<rule>\t<line text>` entry
    22	# in the baseline file (default: relay-automation/hooks/security-scan-baseline.txt, next to this
    23	# script). A baselined finding is STILL PRINTED (labeled "SECURITY (baselined)") — nothing is hidden,
    24	# per GUIDING-PRINCIPLES.md #8 (no masked failure) — it just doesn't count toward the exit code, so the
    25	# scan can be a real BLOCKING gate without hand-suppressing every existing legitimate pattern. Matching
    26	# is by exact line TEXT, not line number, so it survives the file growing/shrinking elsewhere but a
    27	# reformatted flagged line drops out of the baseline and must be re-reviewed (deliberate: no silent
    28	# staleness). The baseline is hand-maintained, never auto-written — that keeps "add to baseline" a
    29	# conscious, reviewed act, same spirit as "never auto-fixes" below. Use --no-baseline for a raw scan
    30	# (e.g. auditing what's currently baselined, or a from-scratch review).
    31	#
    32	# Exit codes:
    33	#   0  — clean: no findings, or every finding is baselined
    34	#   1  — one or more NON-baselined security findings detected
    35	#
    36	# Detection rules (grep-nE based):
    37	#   R1  eval of variable / unsanitized input     eval "$foo" / eval $foo
    38	#   R2  piped remote execution                   curl/wget ... | sh/bash
    39	#   R3  AWS access key                           AKIA[0-9A-Z]{16}
    40	#   R4  PEM private key header                   -----BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY-----
    41	#   R5  GitHub personal access token             ghp_[A-Za-z0-9]{36}
    42	#   R6  Slack token                              xox[baprs]-
    43	#   R7  Literal credential assignment            password=/secret=/api_key= with a value
    44	#
    45	set -euo pipefail
    46	
    47	# ---------------------------------------------------------------------------
    48	# Constants
    49	# ---------------------------------------------------------------------------
    50	
    51	readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
    52	readonly HOOKS_DIR_CONST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    53	readonly REPO_ROOT_CONST="$(cd "$HOOKS_DIR_CONST/../.." && pwd)"
    54	
    55	# Default targets when called with no arguments (relative to repo root).
    56	# Callers that supply explicit paths override this entirely.
    57	DEFAULT_SCAN_PATHS=(
    58	  relay-automation
    59	  bin
    60	  test
    61	)
    62	
    63	USE_BASELINE=1
    64	BASELINE_FILE="$HOOKS_DIR_CONST/security-scan-baseline.txt"
    65	TSV_OUT=0
    66	
    67	# ---------------------------------------------------------------------------
    68	# Pattern definitions  (POSIX ERE, passed to grep -nE)
    69	# ---------------------------------------------------------------------------
    70	
    71	# R1: eval applied to a variable or subshell (not a quoted string literal)
    72	# Matches: eval "$foo", eval $foo, eval "$(…)", eval $(…)
    73	# Does NOT match: eval "literal string" (false-positive rate too high for review scripts)
    74	PATTERN_EVAL='eval[[:space:]]+(\$[^"'"'"' ]|\$\{|\$\(|"[[:space:]]*\$)'
    75	
    76	# R2: curl or wget piped to a shell interpreter
    77	PATTERN_PIPE_SHELL='(curl|wget)[^|]*\|[[:space:]]*(ba)?sh'
    78	
    79	# R3: AWS access key ID
    80	PATTERN_AWS_KEY='AKIA[0-9A-Z]{16}'
    81	
    82	# R4: PEM private key block start
    83	# Note: pattern starts with '-', so must be passed via -e flag to grep (not as positional arg)
    84	PATTERN_PEM_KEY='-----BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY-----'
    85	
    86	# R5: GitHub personal access token (classic format, 40 chars total = ghp_ + 36 alphanum)
    87	# Use + quantifier: BSD grep on macOS has known issues with exact {n} counts in some versions
    88	PATTERN_GH_PAT='ghp_[A-Za-z0-9]{36,}'
    89	
    90	# R6: Slack token prefixes
    91	PATTERN_SLACK='xox[baprs]-[A-Za-z0-9]'
    92	
    93	# R7: Generic credential assignment with a literal value (not a variable reference).
    94	# PATTERN_CRED_ASSIGN's value is bounded to ONE occurrence (not `.{4,}`, which used to run to
    95	# end-of-line) so `grep -noE` yields ONE match PER key=value, even when several sit on the same
    96	# line. The value is either a quoted string (3+ inner chars, spaces allowed — `password="pw
    97	# secret"`) or an unquoted whitespace/semicolon-free token (4+ chars). PATTERN_CRED_EXCLUDE is then
    98	# tested against each individual matched SNIPPET (not the whole line) in _check_credential() below —
    99	# exclude when the value immediately after = starts with $, (, or { (a variable/subshell reference),
   100	# optionally behind a quote. Matching+excluding per-occurrence (not per-line) closes a real bypass: a
   101	# line combining a legitimate reference with a hardcoded secret (`password=$REF; api_key=realsecret`,
   102	# or a trailing `# password=$VAR` comment on the same line as a real secret) used to have the WHOLE
   103	# line dropped by the old line-level exclude filter, hiding the real secret (agy relay QA,
   104	# 2026-07-01, [Blocker]). The quoted-value alternative closes a follow-on gap from the first fix: a
   105	# quoted value containing spaces (`password="pw secret"`) previously matched nothing at all, since
   106	# the unquoted-token alternative alone stops at the first space (agy relay QA r2, [Should]).
   107	PATTERN_CRED_ASSIGN='(password|secret|api_key|API_KEY|SECRET|PASSWORD)[[:space:]]*=[[:space:]]*("[^"]{3,}"|'"'"'[^'"'"']{3,}'"'"'|[^[:space:];]{4,})'
   108	PATTERN_CRED_EXCLUDE='(password|secret|api_key|API_KEY|SECRET|PASSWORD)[[:space:]]*=[[:space:]]*"?[$({]'
   109	
   110	# ---------------------------------------------------------------------------
   111	# Helpers
   112	# ---------------------------------------------------------------------------
   113	
   114	FINDINGS=0
   115	BASELINED=0
   116	
   117	# baseline_hit <file> <rule> <line-text> — true (exit 0) iff this exact triple is pre-approved.
   118	# Reads $BASELINE_FILE fresh each call (small file, called rarely enough that caching isn't worth
   119	# the complexity). Format: <file>\t<rule>\t<line text>; '#'-prefixed and blank lines are comments.
   120	baseline_hit() {
   121	  local file="$1" rule="$2" text="$3"
   122	  [[ "$USE_BASELINE" -eq 1 && -f "$BASELINE_FILE" ]] || return 1
   123	  local bfile brule btext
   124	  while IFS=$'\t' read -r bfile brule btext; do
   125	    [[ -z "$bfile" || "$bfile" == \#* ]] && continue
   126	    if [[ "$bfile" == "$file" && "$brule" == "$rule" && "$btext" == "$text" ]]; then
   127	      return 0
   128	    fi
   129	  done < "$BASELINE_FILE"
   130	  return 1
   131	}
   132	
   133	# scan_file <path>
   134	# Runs each pattern against the file and prints findings to stderr.
   135	scan_file() {
   136	  local f="$1"
   137	  # Baseline entries store the file path relative to the repo root (portable across clones/CI),
   138	  # matching how they were authored — resolve once per file.
   139	  local f_rel="${f#"$REPO_ROOT_CONST"/}"
   140	  # Every rule re-greps the same file, so an unreadable/errored file would otherwise report the
   141	  # identical scan-error once per rule (7x). One report per file is enough to fail loud without the
   142	  # noise; reset per scan_file() call.
   143	  local _scan_error_reported=0
   144	
   145	  # _report <label> <lineno> <text> — shared by _check() and _check_credential(): baseline lookup,
   146	  # TSV/human output, and the FINDINGS/BASELINED tally.
   147	  _report() {
   148	    local label="$1" lineno="$2" text="$3"
   149	    local baselined=0
   150	    baseline_hit "$f_rel" "$label" "$text" && baselined=1
   151	    if [[ "$TSV_OUT" -eq 1 ]]; then
   152	      # Machine-parseable form for authoring/reviewing baseline entries: paste a line straight
   153	      # into $BASELINE_FILE (already tab-separated in the right column order) after confirming
   154	      # by hand it's a false positive / accepted pattern, never automatically.
   155	      printf '%s\t%s\t%s\n' "$f_rel" "$label" "$text"
   156	    elif [[ "$baselined" -eq 1 ]]; then
   157	      echo "SECURITY (baselined): $f:$lineno:$text  [$label]" >&2
   158	    else
   159	      echo "SECURITY: $f:$lineno:$text  [$label]" >&2
   160	    fi
   161	    if [[ "$baselined" -eq 1 ]]; then
   162	      BASELINED=$((BASELINED + 1))
   163	    else
   164	      FINDINGS=$((FINDINGS + 1))
   165	    fi
   166	  }
   167	
   168	  # _grep_or_fail_loud <grep-args...> — runs grep, leaving stdout in $_GREP_OUT (bash-3.2-safe: no
   169	  # `local -n` nameref, which stock macOS bash doesn't support — see relay-turn-lib.sh). grep exit 1
   170	  # (no match — the overwhelmingly common case) is silently treated as "no hits", but any OTHER
   171	  # nonzero exit (2+: bad pattern, unreadable file, etc.) is a real scan error and must NOT read as
   172	  # "file is clean" — that would be exactly the masked failure GUIDING-PRINCIPLES.md #8 forbids.
   173	  # Reports a `[scan-error]` finding (counts toward FINDINGS, fails the scan) instead. Returns 1 if
   174	  # the caller should stop processing this pattern (real error), 0 otherwise (matches or none).
   175	  local _GREP_OUT=""
   176	  _grep_or_fail_loud() {
   177	    local rc=0
   178	    _GREP_OUT="$(/usr/bin/grep "$@" 2>/dev/null)" || rc=$?
   179	    if [[ "$rc" -gt 1 ]]; then
   180	      if [[ "$_scan_error_reported" -eq 0 ]]; then
   181	        _scan_error_reported=1
   182	        _report "scan-error" "-" "grep exited $rc scanning $f — treating as a finding, not silently clean"
   183	      fi
   184	      return 1
   185	    fi
   186	    return 0
   187	  }
   188	
   189	  # _check <label> <pattern> — greps for pattern, one finding per matching LINE (whole-line text).
   190	  # Use -e <pattern> so patterns that start with '-' (e.g. PEM key headers) are not misinterpreted
   191	  # as grep flags.
   192	  _check() {
   193	    local label="$1" pattern="$2"
   194	    local hits
   195	    _grep_or_fail_loud -nE -e "$pattern" "$f" || return 0
   196	    hits="$_GREP_OUT"
   197	    [[ -z "$hits" ]] && return
   198	    while IFS= read -r line; do
   199	      _report "$label" "${line%%:*}" "${line#*:}"
   200	    done <<< "$hits"
   201	  }
   202	
   203	  # _check_credential <label> <pattern> <exclude> — R7 only. Unlike _check(), matches and excludes
   204	  # PER OCCURRENCE (via `grep -noE`, one row per key=value token) instead of per whole line, so a
   205	  # line combining a real secret with an excluded variable reference (`password=$REF;
   206	  # api_key=realsecret`, or a trailing `# password=$VAR` comment next to a real assignment) can't
   207	  # hide the real one behind the excluded one — the old whole-line exclude dropped the entire line
   208	  # when ANY part of it matched the exclude pattern (agy relay QA, 2026-07-01, [Blocker]).
   209	  _check_credential() {
   210	    local label="$1" pattern="$2" exclude="$3"
   211	    local hits
   212	    _grep_or_fail_loud -noE -e "$pattern" "$f" || return 0
   213	    hits="$_GREP_OUT"
   214	    [[ -z "$hits" ]] && return
   215	    while IFS= read -r hit; do
   216	      local lineno="${hit%%:*}" snippet="${hit#*:}"
   217	      /usr/bin/grep -qE -e "$exclude" <<< "$snippet" 2>/dev/null && continue
   218	      _report "$label" "$lineno" "$snippet"
   219	    done <<< "$hits"
   220	  }
   221	
   222	  _check "eval-unsanitized"   "$PATTERN_EVAL"
   223	  _check "pipe-remote-shell"  "$PATTERN_PIPE_SHELL"
   224	  _check "aws-access-key"     "$PATTERN_AWS_KEY"
   225	  _check "pem-private-key"    "$PATTERN_PEM_KEY"
   226	  _check "github-pat"         "$PATTERN_GH_PAT"
   227	  _check "slack-token"        "$PATTERN_SLACK"
   228	  _check_credential "credential-literal" "$PATTERN_CRED_ASSIGN" "$PATTERN_CRED_EXCLUDE"
   229	}
   230	
   231	# collect_files <path>...
   232	# Prints the list of .sh files to scan to stdout.
   233	collect_files() {
   234	  for p in "$@"; do
   235	    if [[ -f "$p" ]]; then
   236	      echo "$p"
   237	    elif [[ -d "$p" ]]; then
   238	      find "$p" -type f -name '*.sh' | sort
   239	    else
   240	      echo "$SCRIPT_NAME: warning: path not found: $p" >&2
   241	    fi
   242	  done
   243	}
   244	
   245	# ---------------------------------------------------------------------------
   246	# Main
   247	# ---------------------------------------------------------------------------
   248	
   249	main() {
   250	  local REPO_ROOT="$REPO_ROOT_CONST"
   251	
   252	  # ── flag parsing (baseline options only; everything else is a scan path) ──
   253	  local -a path_args=()
   254	  while [[ $# -gt 0 ]]; do
   255	    case "$1" in
   256	      --no-baseline) USE_BASELINE=0; shift ;;
   257	      --baseline)    BASELINE_FILE="${2:?--baseline requires a FILE argument}"; shift 2 ;;
   258	      --tsv)         TSV_OUT=1; shift ;;
   259	      *)             path_args+=("$1"); shift ;;
   260	    esac
   261	  done
   262	
   263	  # Resolve scan targets.
   264	  local -a targets
   265	  if [[ "${#path_args[@]}" -gt 0 ]]; then
   266	    targets=("${path_args[@]}")
   267	  else
   268	    # Make default paths absolute relative to repo root.
   269	    targets=()
   270	    for p in "${DEFAULT_SCAN_PATHS[@]}"; do
   271	      targets+=("$REPO_ROOT/$p")
   272	    done
   273	  fi
   274	
   275	  # Collect files to scan and process them directly (bash 3.2 compatible — no mapfile).
   276	  local scanned=0
   277	  while IFS= read -r f; do
   278	    [[ -z "$f" ]] && continue
   279	    scan_file "$f"
   280	    scanned=$((scanned + 1))
   281	  done < <(collect_files "${targets[@]}")
   282	
   283	  if [[ "$scanned" -eq 0 ]]; then
   284	    echo "$SCRIPT_NAME: no .sh files found in specified paths" >&2
   285	    exit 0
   286	  fi
   287	
   288	  local baseline_note=""
   289	  [[ "$BASELINED" -gt 0 ]] && baseline_note=" ($BASELINED baselined, see $BASELINE_FILE)"
   290	
   291	  if [[ "$FINDINGS" -gt 0 ]]; then
   292	    echo "$SCRIPT_NAME: $FINDINGS finding(s) in $scanned file(s) — SCAN FAILED$baseline_note" >&2
   293	    exit 1
   294	  else
   295	    echo "$SCRIPT_NAME: clean — $scanned file(s) scanned, 0 non-baselined findings$baseline_note"
   296	    exit 0
   297	  fi
   298	}
   299	
   300	main "$@"
./AGENTS.md-154-  the index and working tree, then deny the `.git/config` lock and leave HEAD on the old branch.
./AGENTS.md-155-  Before a harness runs a tracking switch or destructive branch mutation such as `git branch -D`,
./AGENTS.md:156:  wrap the complete command with `utils/git-sandbox-guard.sh --repo <root> -- <git command>` so it
./AGENTS.md-157-  refuses before mutation when the config cannot be written. Never truncate git stderr for branch
./AGENTS.md-158-  operations: the decisive `could not lock config file` line can otherwise disappear behind an
--
./PARKED/2026-08-19-session-close.md-29-|---|---|---|
./PARKED/2026-08-19-session-close.md-30-| [#59](https://github.com/HiQS-Suite/XYZ-forge/issues/59) | P2 | Re-arm hosted CI: repo is public, Actions enabled, triggers in ci.yml — yet pushes produce zero runs. Find the cause, then narrow triggers to push/merge on `development`+`main`, then wire the required status check behind `main`'s branch protection (protection is already live, PR-required). |
./PARKED/2026-08-19-session-close.md:31:| [#58](https://github.com/HiQS-Suite/XYZ-forge/issues/58) | P2/P3 | GH-35 Phase 3 follow-ups: tier-2 skips the hygiene suites (security-scan, mktemp-trap-guard, path-integrity, checkjs) — P2; `--tier 3 --subsystem X` silently runs tier 2 — P3; pre-push mktemp-failure path contradicts its comment (`_rc` unbound) — P3. Recommended: ride with Phase 3's registry widening, not before. |
./PARKED/2026-08-19-session-close.md-32-| [#56](https://github.com/HiQS-Suite/XYZ-forge/issues/56) | P3 | Split the 2,214-line `skills/xyz/SKILL.md` into SKILL.md + MANUAL.md. Re-derive from today's file; do NOT resurrect PR #19's `tree-hygiene-guard.sh` (GH-484 trap). |
./PARKED/2026-08-19-session-close.md-33-| [#68](https://github.com/HiQS-Suite/XYZ-forge/issues/68) | P3 | `HARNESS-MODELS-REGISTRY.md` row from PR #60 is off-schema (date in the Harness column). Fold into the next touch of that file. |
--
./test/aider-turn.sh-25-# spacefile=off-lane path with a space; empty=exit 0 with NO output + NO edit (blocked-backend phantom).
./test/aider-turn.sh-26-# A throwaway non-secret value for the OPENROUTER_API_KEY pre-flight (assigned via a var, not a literal,
./test/aider-turn.sh:27:# so the security-scan credential-literal rule's variable-value exclusion applies).
./test/aider-turn.sh-28-FAKE_ORKEY="not-a-real-key"
./test/aider-turn.sh-29-
--
./TESTS-RESULTS/2026-08-23+GH-174/gh174-validate-baseline.log-258-[parallel] fixtures/canary-peer-orphan/verify-fixture.sh rc=0
./TESTS-RESULTS/2026-08-23+GH-174/gh174-validate-baseline.log-259-[parallel] phase3-signoff-guard.sh rc=0
./TESTS-RESULTS/2026-08-23+GH-174/gh174-validate-baseline.log:260:[parallel] security-scan.sh rc=0
./TESTS-RESULTS/2026-08-23+GH-174/gh174-validate-baseline.log-261-[parallel] pdda-repo-contract.sh rc=0
./TESTS-RESULTS/2026-08-23+GH-174/gh174-validate-baseline.log-262-[parallel] relay-self-sufficiency.sh rc=0
--
./TESTS-RESULTS/2026-08-23+GH-174/gh174-validate-baseline.log-577-  + fixtures/canary-peer-orphan/verify-fixture.sh
./TESTS-RESULTS/2026-08-23+GH-174/gh174-validate-baseline.log-578-  + phase3-signoff-guard.sh
./TESTS-RESULTS/2026-08-23+GH-174/gh174-validate-baseline.log:579:  + security-scan.sh
./TESTS-RESULTS/2026-08-23+GH-174/gh174-validate-baseline.log-580-  + pdda-repo-contract.sh
./TESTS-RESULTS/2026-08-23+GH-174/gh174-validate-baseline.log-581-  + relay-self-sufficiency.sh
--
./test/gh77-standup-triage.sh-24-pass_() { echo "  PASS: $1"; pass=$((pass+1)); }
./test/gh77-standup-triage.sh-25-fail_() { echo "  FAIL: $1" >&2; fail=$((fail+1)); }
./test/gh77-standup-triage.sh:26:# Deliberately no dynamic evaluation: the helper other suites share needs a security-scan baseline
./test/gh77-standup-triage.sh-27-# entry per suite, and nothing below needs that indirection.
./test/gh77-standup-triage.sh-28-is()   { if [ "$2" = "$3" ]; then pass_ "$1"; else fail_ "$1 (got '$2', want '$3')"; fi; }
--
./validate.sh-415-                                 #   embed itself lives in hq-rollup.sh cases A/F/G)
./validate.sh-416-  "transcript-audit.sh"
./validate.sh:417:  "security-scan.sh"
./validate.sh-418-  "sentinel-tier1.sh"           # GH-281 (Tier-1 JSONL finding capture)
./validate.sh-419-  "sentinel-network-guard.sh"   # GH-281 (bundled scripts stay zero-network)
--
./evidence/09-security-scan.log-1-=== XYZ-FORGE BRINGUP RUN ===
./evidence/09-security-scan.log:2:cmd      : bash /tmp/security-scan.sh
./evidence/09-security-scan.log-3-cwd      : /home/arnoldadero/XYZ-forge
./evidence/09-security-scan.log-4-start    : 2026-08-20T17:25:03+03:00
--
./evidence/09-security-scan.log-71- M evidence/marathons/run-2/04-wallclock.txt
./evidence/09-security-scan.log-72-?? evidence/08-spend-report.log
./evidence/09-security-scan.log:73:?? evidence/09-security-scan.log
./evidence/09-security-scan.log-74-?? evidence/FINDINGS.md
./evidence/09-security-scan.log-75-?? evidence/_env/archive-run.sh
--
./evidence/09-security-scan.log-94-    evidence/07-drift-probe.log
./evidence/09-security-scan.log-95-    evidence/03-pdda-install.log
./evidence/09-security-scan.log:96:    evidence/09-security-scan.log
./evidence/09-security-scan.log-97-    evidence/02-validate-sequential.log
./evidence/09-security-scan.log-98-    evidence/04-codex-install.log
--
./test/signal-triage.sh-6-#   (b) Rule 1 (noise) fires on informational-only source
./test/signal-triage.sh-7-#   (c) Rule 2 (bug) fires on validate-fail, with test name in evidence
./test/signal-triage.sh:8:#   (d) Rule 2 (bug) fires on security-scan (security folds into bug, not a separate bucket)
./test/signal-triage.sh-9-#   (e) Rule 2 (bug) fires on relay-exit6
./test/signal-triage.sh-10-#   (f) Rule 2 (bug) fires on canary-reject
--
./test/signal-triage.sh-106-fi
./test/signal-triage.sh-107-
./test/signal-triage.sh:108:# (d) Rule 2: bug on security-scan (folds into bug, NOT a separate bucket)
./test/signal-triage.sh-109-run_triage "sec-scan-001" "bug" "rule-2-bug" \
./test/signal-triage.sh:110:  --source "security-scan" --detail "CVE-2026-9999"
./test/signal-triage.sh-111-
./test/signal-triage.sh-112-json_d="$(bash "$TRIAGE" --id "sec-scan-002" --output-dir "$TRIAGE_DIR" \
./test/signal-triage.sh:113:  --source "security-scan" 2>/dev/null)"
./test/signal-triage.sh:114:if echo "$json_d" | grep -q "\"source\": \"security-scan\""; then
./test/signal-triage.sh:115:  pass "security-scan: source field preserved as security-scan (stays queryable per GP #7)"
./test/signal-triage.sh-116-else
./test/signal-triage.sh:117:  fail "security-scan: source field should be security-scan; got: $json_d"
./test/signal-triage.sh-118-fi
./test/signal-triage.sh-119-
--
./test/gh32-release-target-advisory.sh-23-fail_() { echo "  FAIL: $1" >&2; fail=$((fail+1)); }
./test/gh32-release-target-advisory.sh-24-# Deliberately no dynamic evaluation here: the ok() helper other suites share needs a
./test/gh32-release-target-advisory.sh:25:# security-scan baseline entry per suite, and nothing below needs that indirection.
./test/gh32-release-target-advisory.sh-26-yes_() { if [ "$2" = "0" ]; then pass_ "$1"; else fail_ "$1"; fi; }
./test/gh32-release-target-advisory.sh-27-has()  { printf '%s' "$1" | grep -Fq -- "$2"; }
--
./relay-automation/hooks/security-scan-baseline.txt:1:# security-scan-baseline.txt — GH-64 pre-approved findings
./relay-automation/hooks/security-scan-baseline.txt-2-#
./relay-automation/hooks/security-scan-baseline.txt:3:# Hand-reviewed and hand-maintained (relay-automation/hooks/security-scan.sh never writes this
./relay-automation/hooks/security-scan-baseline.txt-4-# file). Format: <file>	<rule>	<exact matched line text> — one entry per line, tab-separated.
./relay-automation/hooks/security-scan-baseline.txt-5-# A finding here is still PRINTED (labeled "baselined"), just doesn't fail the scan — nothing is
--
./relay-automation/hooks/security-scan-baseline.txt-7-# reformatted flagged line drops out of the baseline and must be re-reviewed (deliberate).
./relay-automation/hooks/security-scan-baseline.txt-8-#
./relay-automation/hooks/security-scan-baseline.txt:9:# To review/regenerate candidate rows: bash relay-automation/hooks/security-scan.sh --no-baseline --tsv
./relay-automation/hooks/security-scan-baseline.txt-10-# Every row below was reviewed 2026-07-01 (GH-64): each is a doc/prose comment matching a pattern
./relay-automation/hooks/security-scan-baseline.txt-11-# in TEXT (not an actual secret/credential), a reviewed operator-configured dispatcher eval
./relay-automation/hooks/security-scan-baseline.txt-12-# (poll.sh/relay-drive.sh/marathon-drive.sh/improve-loop.sh — trusted config, not attacker input),
./relay-automation/hooks/security-scan-baseline.txt:13:# or the security-scan test suite's own intentional fixtures. No real secret leak in any row.
./relay-automation/hooks/security-scan-baseline.txt-14-#
./relay-automation/hooks/security-scan-baseline.txt:15:relay-automation/hooks/security-scan.sh	eval-unsanitized	#   R1  eval of variable / unsanitized input     eval "$foo" / eval $foo
./relay-automation/hooks/security-scan-baseline.txt:16:relay-automation/hooks/security-scan.sh	eval-unsanitized	# Matches: eval "$foo", eval $foo, eval "$(…)", eval $(…)
./relay-automation/hooks/security-scan-baseline.txt:17:relay-automation/hooks/security-scan.sh	pipe-remote-shell	#   R2  piped remote execution                   curl/wget ... | sh/bash
./relay-automation/hooks/security-scan-baseline.txt:18:relay-automation/hooks/security-scan.sh	credential-literal	password=/secret=/api_key=
./relay-automation/hooks/security-scan-baseline.txt:19:relay-automation/hooks/security-scan.sh	credential-literal	api_key=realsecret`,
./relay-automation/hooks/security-scan-baseline.txt:20:relay-automation/hooks/security-scan.sh	credential-literal	password="pw secret"
./relay-automation/hooks/security-scan-baseline.txt-21-relay-automation/improve-loop.sh	eval-unsanitized	if ! eval "$ORACLE_CMD" >/dev/null 2>&1; then echo "improve-loop: baseline FAILS the oracle — refusing to optimize a broken artifact" >&2; exit 3; fi
./relay-automation/hooks/security-scan-baseline.txt-22-relay-automation/improve-loop.sh	eval-unsanitized	  eval "$BUILD_CMD" >/dev/null 2>&1 || true
--
./relay-automation/hooks/security-scan-baseline.txt-40-test/relay-turn-handoff.sh	eval-unsanitized	ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
./relay-automation/hooks/security-scan-baseline.txt-41-test/relay-xyz-skill-guard.sh	eval-unsanitized	run "sess-loc" Bash 'eval "$(bash skills/relay-xyz/find-harness.sh --env)"'
./relay-automation/hooks/security-scan-baseline.txt:42:test/security-scan.sh	eval-unsanitized	eval "$UNSANITIZED"
./relay-automation/hooks/security-scan-baseline.txt:43:test/security-scan.sh	eval-unsanitized	check_pattern "eval-var"         'eval "$MYVAR"'
./relay-automation/hooks/security-scan-baseline.txt:44:test/security-scan.sh	eval-unsanitized	check_pattern "eval-dollar"      'eval $MYVAR'
./relay-automation/hooks/security-scan-baseline.txt:45:test/security-scan.sh	pipe-remote-shell	curl https://example.com/install.sh | bash
./relay-automation/hooks/security-scan-baseline.txt:46:test/security-scan.sh	pipe-remote-shell	check_pattern "pipe-curl-sh"     'curl https://example.com/x.sh | sh'
./relay-automation/hooks/security-scan-baseline.txt:47:test/security-scan.sh	pipe-remote-shell	check_pattern "pipe-wget-bash"   'wget -qO- http://x.io/go.sh | bash'
./relay-automation/hooks/security-scan-baseline.txt:48:test/security-scan.sh	aws-access-key	AWS_KEY="AKIAIOSFODNN7EXAMPLE"
./relay-automation/hooks/security-scan-baseline.txt:49:test/security-scan.sh	aws-access-key	check_pattern "aws-key"          'export KEY=AKIAIOSFODNN7EXAMPLE'
./relay-automation/hooks/security-scan-baseline.txt:50:test/security-scan.sh	pem-private-key	echo "-----BEGIN RSA PRIVATE KEY-----"
./relay-automation/hooks/security-scan-baseline.txt:51:test/security-scan.sh	pem-private-key	check_pattern "pem-rsa"          '-----BEGIN RSA PRIVATE KEY-----'
./relay-automation/hooks/security-scan-baseline.txt:52:test/security-scan.sh	pem-private-key	check_pattern "pem-openssh"      '-----BEGIN OPENSSH PRIVATE KEY-----'
./relay-automation/hooks/security-scan-baseline.txt:53:test/security-scan.sh	github-pat	GH_TOKEN="ghp_aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890"
./relay-automation/hooks/security-scan-baseline.txt:54:test/security-scan.sh	github-pat	check_pattern "github-pat"       'TOKEN=ghp_aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890'
./relay-automation/hooks/security-scan-baseline.txt:55:test/security-scan.sh	slack-token	SLACK_BOT="xoxb-secrettoken"
./relay-automation/hooks/security-scan-baseline.txt:56:test/security-scan.sh	slack-token	check_pattern "slack-bot"        'SLACK=xoxb-abc123'
./relay-automation/hooks/security-scan-baseline.txt:57:test/security-scan.sh	credential-literal	password="hunter2secret"
./relay-automation/hooks/security-scan-baseline.txt:58:test/security-scan.sh	credential-literal	password="mysecretpass"'
./relay-automation/hooks/security-scan-baseline.txt:59:test/security-scan.sh	credential-literal	api_key=supersecretvalue'
./relay-automation/hooks/security-scan-baseline.txt-60-test/xyz-vendor.sh	eval-unsanitized	( unset HARNESS; eval "$(cat "$WORK/plain.env")"; [ "$HARNESS" = "$ROOT" ] ) \
./relay-automation/hooks/security-scan-baseline.txt-61-
./relay-automation/hooks/security-scan-baseline.txt:62:# --- added 2026-07-01: GH-64's own baseline-mechanism test fixtures (test/security-scan.sh) ---
./relay-automation/hooks/security-scan-baseline.txt:63:test/security-scan.sh	credential-literal	api_key=hunter2supersecretvalue'
./relay-automation/hooks/security-scan-baseline.txt:64:test/security-scan.sh	credential-literal	api_key=hunter2supersecretvalue
./relay-automation/hooks/security-scan-baseline.txt:65:test/security-scan.sh	credential-literal	password="pw secret"
./relay-automation/hooks/security-scan-baseline.txt:66:test/security-scan.sh	eval-unsanitized	printf '#!/usr/bin/env bash\neval "$X"\n' > "$UNREADABLE_FILE"
./relay-automation/hooks/security-scan-baseline.txt:67:test/security-scan.sh	eval-unsanitized	printf '#!/usr/bin/env bash\neval "$ALSO_BAD"\n' > "$OTHER_FILE"
./relay-automation/hooks/security-scan-baseline.txt:68:test/security-scan.sh	eval-unsanitized	eval "$KNOWN_GOOD"
./relay-automation/hooks/security-scan-baseline.txt:69:test/security-scan.sh	eval-unsanitized	eval "$BRAND_NEW_ONE"
./relay-automation/hooks/security-scan-baseline.txt:70:test/security-scan.sh	eval-unsanitized	printf '# comment line, ignored\n\nmixed.sh\teval-unsanitized\teval "$KNOWN_GOOD"\n' > "$BASE_FILE"
./relay-automation/hooks/security-scan-baseline.txt:71:test/security-scan.sh	eval-unsanitized	printf '# comment\nmixed.sh\teval-unsanitized\teval "$KNOWN_GOOD"\nmixed.sh\teval-unsanitized\teval "$BRAND_NEW_ONE"\n' > "$BASE_FILE"
./relay-automation/hooks/security-scan-baseline.txt:72:test/security-scan.sh	eval-unsanitized	TSV_EXPECT="$(printf 'mixed.sh\teval-unsanitized\teval "$KNOWN_GOOD"')"
./relay-automation/hooks/security-scan-baseline.txt-73-test/deep-research.sh	credential-literal	API_KEY="test-key"
./relay-automation/hooks/security-scan-baseline.txt-74-test/aider-turn.sh	credential-literal	API_KEY="sk-local-test"
--
./relay-automation/hooks/security-scan.sh-1-#!/usr/bin/env bash
./relay-automation/hooks/security-scan.sh-2-#
./relay-automation/hooks/security-scan.sh:3:# security-scan.sh — static security scanner for shell scripts (GH-64)
./relay-automation/hooks/security-scan.sh-4-#
./relay-automation/hooks/security-scan.sh-5-# Implements fail-loud detection per GUIDING-PRINCIPLES.md #8 (no masked failure):
--
./relay-automation/hooks/security-scan.sh-9-#
./relay-automation/hooks/security-scan.sh-10-# Usage:
./relay-automation/hooks/security-scan.sh:11:#   bash relay-automation/hooks/security-scan.sh [--no-baseline] [--baseline FILE] [--tsv] [<path>...]
./relay-automation/hooks/security-scan.sh-12-#
./relay-automation/hooks/security-scan.sh-13-# --tsv prints each finding as `<file>\t<rule>\t<line text>` on stdout instead of the human-readable
--
./relay-automation/hooks/security-scan.sh-20-# Baseline (GH-64): a known-legitimate finding (a reviewed dispatcher `eval`, a test fixture, a doc
./relay-automation/hooks/security-scan.sh-21-# comment matching a pattern in prose) is pre-approved by an exact `<file>\t<rule>\t<line text>` entry
./relay-automation/hooks/security-scan.sh:22:# in the baseline file (default: relay-automation/hooks/security-scan-baseline.txt, next to this
./relay-automation/hooks/security-scan.sh-23-# script). A baselined finding is STILL PRINTED (labeled "SECURITY (baselined)") — nothing is hidden,
./relay-automation/hooks/security-scan.sh-24-# per GUIDING-PRINCIPLES.md #8 (no masked failure) — it just doesn't count toward the exit code, so the
--
./relay-automation/hooks/security-scan.sh-62-
./relay-automation/hooks/security-scan.sh-63-USE_BASELINE=1
./relay-automation/hooks/security-scan.sh:64:BASELINE_FILE="$HOOKS_DIR_CONST/security-scan-baseline.txt"
./relay-automation/hooks/security-scan.sh-65-TSV_OUT=0
./relay-automation/hooks/security-scan.sh-66-
--
./evidence/10-validate-sequential-clean.log-6051-
./evidence/10-validate-sequential-clean.log-6052-===============================
./evidence/10-validate-sequential-clean.log:6053:Running security-scan.sh
./evidence/10-validate-sequential-clean.log-6054-===============================
./evidence/10-validate-sequential-clean.log:6055:== test: security-scan ==
./evidence/10-validate-sequential-clean.log-6056-  workdir: /tmp/sec-scan-test.AGLTr0
./evidence/10-validate-sequential-clean.log-6057-  PASS: bad fixture: scanner exits non-zero (1)
--
./evidence/10-validate-sequential-clean.log-6091-  PASS: GH-64 active gate: the real repo tree is clean against the checked-in baseline
./evidence/10-validate-sequential-clean.log-6092-
./evidence/10-validate-sequential-clean.log:6093:security-scan: 35 pass, 0 fail
./evidence/10-validate-sequential-clean.log-6094-
./evidence/10-validate-sequential-clean.log-6095-===============================
--
./evidence/10-validate-sequential-clean.log-6197-  PASS: sec-scan-001: category=bug
./evidence/10-validate-sequential-clean.log-6198-  PASS: sec-scan-001: evidence starts with rule-2-bug
./evidence/10-validate-sequential-clean.log:6199:  PASS: security-scan: source field preserved as security-scan (stays queryable per GP #7)
./evidence/10-validate-sequential-clean.log-6200-  PASS: relay-exit6-001: category=bug
./evidence/10-validate-sequential-clean.log-6201-  PASS: relay-exit6-001: evidence starts with rule-2-bug
--
./evidence/10-validate-sequential-clean.log-6542-  + hq-rollup.sh
./evidence/10-validate-sequential-clean.log-6543-  + transcript-audit.sh
./evidence/10-validate-sequential-clean.log:6544:  + security-scan.sh
./evidence/10-validate-sequential-clean.log-6545-  + sentinel-tier1.sh
./evidence/10-validate-sequential-clean.log-6546-  + sentinel-network-guard.sh
--
./test/sentinel-network-guard.sh-3-#   (a) WIRING: the guard, run with no args over its REAL default set (the bundled capture scripts),
./test/sentinel-network-guard.sh-4-#       exits 0 — so a future network primitive added to a real capture script fails the suite.
./test/sentinel-network-guard.sh:5:#   (b) Per-primitive bad fixtures: every promised primitive trips the guard (security-scan.sh style).
./test/sentinel-network-guard.sh-6-#   (c) Directory traversal: a bad bundle trips; a clean bundle passes with no stderr.
./test/sentinel-network-guard.sh-7-set -euo pipefail
--
./evidence/02-validate-sequential.log-5861-
./evidence/02-validate-sequential.log-5862-===============================
./evidence/02-validate-sequential.log:5863:Running security-scan.sh
./evidence/02-validate-sequential.log-5864-===============================
./evidence/02-validate-sequential.log:5865:== test: security-scan ==
./evidence/02-validate-sequential.log-5866-  workdir: /tmp/sec-scan-test.n9vJ35
./evidence/02-validate-sequential.log-5867-  PASS: bad fixture: scanner exits non-zero (1)
--
./evidence/02-validate-sequential.log-5901-  PASS: GH-64 active gate: the real repo tree is clean against the checked-in baseline
./evidence/02-validate-sequential.log-5902-
./evidence/02-validate-sequential.log:5903:security-scan: 35 pass, 0 fail
./evidence/02-validate-sequential.log-5904-
./evidence/02-validate-sequential.log-5905-===============================
--
./evidence/02-validate-sequential.log-6007-  PASS: sec-scan-001: category=bug
./evidence/02-validate-sequential.log-6008-  PASS: sec-scan-001: evidence starts with rule-2-bug
./evidence/02-validate-sequential.log:6009:  PASS: security-scan: source field preserved as security-scan (stays queryable per GP #7)
./evidence/02-validate-sequential.log-6010-  PASS: relay-exit6-001: category=bug
./evidence/02-validate-sequential.log-6011-  PASS: relay-exit6-001: evidence starts with rule-2-bug
--
./evidence/02-validate-sequential.log-6366-  + hq-rollup.sh
./evidence/02-validate-sequential.log-6367-  + transcript-audit.sh
./evidence/02-validate-sequential.log:6368:  + security-scan.sh
./evidence/02-validate-sequential.log-6369-  + sentinel-tier1.sh
./evidence/02-validate-sequential.log-6370-  + sentinel-network-guard.sh
--
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-40-truncate away; the visible symptom is only a misleading upstream hint.
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-41-
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md:42:1. `utils/git-sandbox-guard.sh` (new): a preflight primitive that probes `.git/config`
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-43-   writability and refuses tracking/branch-mutation operations up front with a named error,
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-44-   for harness scripts that switch branches (relay/marathon drivers).
--
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-63-
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-64-You are the BUILDER for this phase. Read the phase brief above and implement it.
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md:65:1. Implement the brief by creating/editing the artifact file(s): utils/git-sandbox-guard.sh,test/gh50-sandboxed-git-guard.sh,AGENTS.md,validate.sh
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-66-2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-67-3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge-bulkhead-core/bin/tick
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md:68:   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-bulkhead-core/bin/tick claim MARATHON-GH50-SANDBOXED-GIT-GUARD-TURN --agent codex --paths "marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md,utils/git-sandbox-guard.sh,test/gh50-sandboxed-git-guard.sh,AGENTS.md,validate.sh"
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-69-   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-bulkhead-core/bin/tick ping MARATHON-GH50-SANDBOXED-GIT-GUARD-TURN --agent codex
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-70-   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-bulkhead-core/bin/tick release MARATHON-GH50-SANDBOXED-GIT-GUARD-TURN --agent codex --to agy
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md:71:4. Edit ONLY these paths: marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md and utils/git-sandbox-guard.sh,test/gh50-sandboxed-git-guard.sh,AGENTS.md,validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-72-5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-73-   "handing off to agy — agy, take your turn." A turn that ends without that line
--
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-79-▶ TAKE YOUR TURN (agy — REVIEWER role)
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-80-
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md:81:You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/git-sandbox-guard.sh,test/gh50-sandboxed-git-guard.sh,AGENTS.md,validate.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-82-1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-83-2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-bulkhead-core/bin/tick release MARATHON-GH50-SANDBOXED-GIT-GUARD-TURN --agent agy --to codex
--
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-99-### Round 1 · Builder · codex
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-100-
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md:101:- Added `utils/git-sandbox-guard.sh`, an executable preflight/wrapper that resolves the repository's
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-102-  common config, probes both the config and `config.lock` write paths, and refuses with a GH-50-named
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-103-  error before executing the supplied branch command.
--
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-109-- No current `switch --track` / `branch -D` runtime call site was found in the permitted artifact set;
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-110-  no off-allowlist driver file was edited. The new `utils/*.sh` file requires commit trailer
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md:111:  `New-bash-exception: utils/git-sandbox-guard.sh — GH-50 preflight must wrap git branch commands before process launch`.
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-112-- Verification: `bash test/gh50-sandboxed-git-guard.sh` — 11 pass, 0 fail. Full `validate.sh`
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-113-  intentionally not run by this lane.
--
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-116-swept file: yes
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-117-
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md:118:The new `utils/git-sandbox-guard.sh` and `test/gh50-sandboxed-git-guard.sh` scripts look correct, pass locally, and properly refuse when the config is read-only. The addition to `AGENTS.md` is correctly placed and follows the brief's requirements. `New-bash-exception` is appropriately noted.
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-119-
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-120-However, since I must review the WHOLE of the touched files, I found pre-existing defects in `validate.sh` that were flagged by shellcheck. These are in scope and need to be fixed before we can approve this lane:
--
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-142-swept file: yes
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-143-
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md:144:The fixes applied to `validate.sh` successfully resolve the shellcheck issues (SC2166, SC2221, SC2222) while preserving the script's logic. I have confirmed that `test/gh50-sandboxed-git-guard.sh` passes successfully and `shellcheck -e SC1091 validate.sh` is now completely clean. There are no other defects found in the touched files (`validate.sh`, `utils/git-sandbox-guard.sh`, `test/gh50-sandboxed-git-guard.sh`, and `AGENTS.md`). I also double-checked `utils/git-sandbox-guard.sh` arg parsing: it correctly requires `--` for command evaluation in the catch-all `*)` block which correctly adheres to safe shell usage. 
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-145-
./marathon-system/gh2-50-168-bulkhead-core-remainder--gh50-sandboxed-git-guard/RELAY.md-146-**Verdict:** Approved
--
./CHANGELOG.md-739-- **GH-312: `xyz-sync update` / `xyz-vendor.sh` silently destroyed the target repo's live runtime state — fixed by preserving it across the vendor swap, with three more at-risk paths than the report identified.** `materialize_vendor()` builds a staged mirror of the harness and swaps it in over an unconditional `rm -rf "$VENDOR_DIR"`. The stage is mirrored purely from `$HARNESS_ROOT`, so everything the *target* accumulated at runtime was deleted unread — and since `ensure_gitignore` keeps `.xyz/` out of git, nothing under it was ever hashed into a git object, leaving **no reflog, stash, or `git fsck --lost-found` recovery**. It exited 0 and printed success. A real incident on 2026-07-27 destroyed a completed two-round Codex relay thread plus its full `.tick/` event log; the findings survived only because the Codex CLI transcripts happen to live in `$TMPDIR`, outside the harness. **The intake report's requested fix was incomplete:** it named `relay-system/`, `.tick/`, and `.relay-driver.lock`, but auditing what `.xyz/` actually accumulates (repo `.gitignore` + GH-75) turned up the completion-telemetry family — `XYZ.json` (the locked record array, 1.8 MB and actively written on the reporting machine), `XYZ.json.lock/` (its `mkdir` advisory lock), and `XYZ.heartbeat.json` — with **identical exposure**: none are in `VENDOR_DIRS`, so the stage never recreated them either. Implementing the report literally would have left the bug half-fixed; the shipped preserve list carries **six** paths, and a failed copy now `die`s *before* the destructive swap rather than proceeding. Preservation was chosen over a warning or a refusal because both still depend on an operator reading output at the right moment, and the docs frame `update` as deliberate (pinned + manual) but never as destructive. **Regression coverage was written first and observed failing** — new `test/gh312-vendor-preserves-state.sh` produced 6 failures against the pre-fix code and passes 14/14 post-fix — and it pins the *other* half of the contract too: VERSION must still restamp to live HEAD and `bin/tick` must survive, so a "fix" that preserved state by skipping the update cannot pass. It also covers the direct `xyz-vendor.sh` re-run over an existing `.xyz/`, which the capture flagged as an unverified open question and which had the same destructive swap (**answered: yes**). Docs: `xyz-sync.sh`'s header and `skills/relay-xyz/SKILL.md` now state what `update` does to runtime state and that a new `.xyz/` artifact must join the preserve list. Reviewed by **agy** through a driven relay (`--review-once`, `ALLOW_PATHS=""`): Approved with 4 `[Pass]` findings and no defects raised — disclosed as a clean but shallow signal, not independent corroboration. `skills/relay-automation/relay-pkg.tar.gz` rebuilt via `make-pkg.sh` (the fix touches `relay-automation/`, which drifts the vendored tarball); `relay-pkg-freshness.sh` 3/3 and full `./validate.sh` green (10 passed / 0 failed / 1 skipped). **Deliberately still open:** whether durable runtime state belongs under a disposable, gitignored `.xyz/` at all — the capture's own sharper question, listed in its `non_goals`, and **not** closed by this fix. → [GH-312-XYZ-SYNC-DESTROYS-STATE.md](PROJECT/3-COMPLETED/GH-312-XYZ-SYNC-DESTROYS-STATE.md) · [#312](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/312)
./CHANGELOG.md-740-- **GH-304: relay-drive turn-taker prompt + worktree seeding used a CWD-relative relay-file path — broke same-repo vendored `.xyz/` installs for Codex.** Scaffolding/driving a relay from CWD=`.xyz` (the relay-xyz skill's documented `cd "$HARNESS"`) with a CWD-relative `--relay-file` embedded that raw string in the turn-taker's prompt and used it for worktree seeding. Since a same-repo vendored `.xyz/` has no `.git` of its own, the turn-taker's worktree roots at the *outer* repo top-level, where `relay-system/…` doesn't exist (the file is at `.xyz/relay-system/…`) — a 100% failure for Codex, masked for agy (which absolutizes the path itself). Fix: `relay-drive.sh` and `utils/py/relay_drive.py` now **absolutize `$RELAY_FILE` before exporting it** to the turn-taker (mirrors the existing `--artifact-file` handling), so it resolves identically from any CWD; `rtl_turn_prompt` (`relay-turn-lib.sh`) derives the repo-root-relative EDIT path robustly (physical-path strip, matching `rtl_init`'s allowlist normalization) so the embedded path and the seeded path stay in lockstep at the true `.xyz/relay-system/…`. **Secondary:** when the relay file is gitignored (this repo gitignores parts of `relay-system/`), `rtl_enforce`'s empty-commit case now prints a distinct "relay file is gitignored, changes are NOT git-tracked (expected, not a stall)" message instead of the ambiguous "no tracked changes (token-only move?)" that a passing and a failing run printed byte-identically. Proof: new `test/gh304-vendored-relay-path.sh` (11/11) unit-tests the allowlist normalization, prompt path, worktree seeding, and both empty-commit messages; related relay/worktree tests green locally. → [#304](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/304)
./CHANGELOG.md:741:- **GH-295: PR #302 tier1 CI — two real gaps found and fixed.** `test/pi-turn.sh`'s fake `OPENROUTER_API_KEY` test fixtures ("test-key"/"test-key-not-real") were never added to `security-scan-baseline.txt`, tripping the GH-64 active gate (same pattern already baselined for `aider-turn.sh`/`deep-research.sh`). Separately, `skills/relay-automation/relay-pkg.tar.gz` had drifted from an earlier README edit on this branch and was never rebuilt, tripping `test/relay-pkg-freshness.sh`. Both fixed; `security-scan.sh`/`relay-pkg-freshness.sh` green locally.
./CHANGELOG.md-742-- **GH-300: swe-diagram search input no longer touches/overflows the font-picker when typing — two distinct bugs found and fixed, same symptom family.** **(1)** `.swe-search-input` uses `type="search"` but never reset `-webkit-appearance`, so WebKit's native searchfield cancel-button decoration could override the field's explicit 180px width once it had text — the renderer already ships its own custom `.swe-search-clear` button, making the native chrome pure downside. Fixed via `-webkit-appearance: none` + explicit `::-webkit-search-cancel-button`/`::-webkit-search-decoration` resets in `utils/swe-diagram/assets/template.html`. Not independently re-verified in Safari (no automation available in this environment) — a headless-Chrome regression check confirms no change there, since Chrome doesn't exhibit the underlying bug in the first place. **(2) Found on operator re-report** (the box still visibly touched the picker on the very first keystroke, no resize needed — but resizing afterward fixed it, the key clue): `positionPicker()` only ran on page load, font-picker change, and window resize — never on the search box's own `input` event — so when the custom clear button appeared (growing the right-anchored `.swe-search` row leftward), the picker never got told to move; a resize masked the bug by incidentally recomputing from the now-grown width. Fixed by having `renderer.js`'s search `input`/clear handlers dispatch a `swe-search-resize` event on the persistent `#diagram` node, which `template.html` listens for alongside its existing triggers. **Verified quantitatively, not just visually**: headless-Chrome bounding-rect measurement showed a healthy 8px gap before typing collapsing to a -22px overlap after typing (fix 1 alone), now a constant 8px with no resize needed — and since this is plain DOM sizing/event logic rather than a WebKit quirk, the Chrome verification here is directly conclusive. `test/swe-diagram.sh` 42/42 throughout; every `ARCHITECTURE/*.html` output rebuilt after each fix. → [GH-300-SWE-DIAGRAM-SEARCH-INPUT-OVERFLOW.md](PROJECT/3-COMPLETED/GH-300-SWE-DIAGRAM-SEARCH-INPUT-OVERFLOW.md) · [#300](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/300)
./CHANGELOG.md-743-
--
./CHANGELOG.md-753-- **GH-281 Sentinel Debug Flywheel — Tier-1 shipped end-to-end + full Tier-2 overlay landed (transparent code, inert by default).** Carved the risk-2 Tier-1 Stage-0 slice from the risk-4 umbrella, `swarm-preflight → ready`; marathon-built it (Codex builder + Agy reviewer), the deterministic gate caught a test-hygiene defect the review missed, then a 3-round `/relay-xyz` Codex adversarial review closed 2 blockers — a network-guard never wired over the real capture scripts, and `finding-new.sh` emitting invalid JSON on control bytes (a defect that lived in the issue's own verbatim source, patched upstream) — **Approved**, merged to `development` in [#285](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/285). Then, orchestrator-side, wired the six §1.3 `marathon-drive.sh` debug-capture hooks (opt-in `XYZ_DEBUG_LOG`, default OFF, byte-identical when off) with `test/sentinel-driver-hooks.sh`. On an operator design call, built the **full Tier-2 triage overlay** (`sentinel-overlay/`: reader → local-Gemma classify → draft PDDA doc → file issue → nightly batch → PR-emit → adversarial red-team → morning report) as **visible in-repo reference code** for transparency, with all call-home gated behind a **gitignored `runtime.env`** so a downstream clone is completely inert (no network/LLM/GitHub) until the operator opts in — enforced by a single `sentinel_active` gate, egress-only wrappers, a static guard, and `test/sentinel-overlay.sh` proving zero egress with no config. Agy `/relay-xyz` QA **Approved** both items. Full `validate.sh` green throughout. → [Tier-1](PROJECT/2-WORKING/GH-281-SENTINEL-TIER1-STAGE0.md) · [Tier-2](PROJECT/2-WORKING/GH-281-SENTINEL-TIER2-OVERLAY.md) · [#281](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/281)
./CHANGELOG.md-754-- **GH-275/GH-276: long-term residual-risk program reconciled and converted into an actionable six-phase checklist, with a separate weekly control loop.** After a requested 30-minute wait, re-read the live `development` branch, GitHub issue state, ROADMAP, CHANGELOG, and active project docs; rewrote [#275](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/275) to distinguish shipped controls from residual gaps, cap committed work at three proof-sized lanes, define inherent-vs-residual risk, preserve separated grading, and gate advanced autonomy behind containment/recovery evidence. Created [#276](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/276) as a dated-comment weekly reconciliation checklist, not a competing plan or auto-fire path. Added issue-first inbox captures and ROADMAP pointers. Final snapshot incorporates the concurrently landed GH-273 closeout (`111b552`): all five GH-273 phases shipped; #274 remains the truthful-retry residual gap. → [GH-275 capture](PROJECT/1-INBOX/GH-275-LONG-TERM-RISK.md) · [GH-276 capture](PROJECT/1-INBOX/GH-276-WEEKLY-RISK-RECONCILIATION.md)
./CHANGELOG.md:755:- **GH-273: Phase 4 SHIPPED and the whole plan is CLOSED — `--post-approve-cmd` lands in both `marathon-drive.sh` and `marathon_drive.py`, symmetric to the existing `--pre-advance-cmd`.** Fired via `swarm-preflight → marathon-drive` with `--phase-id gh273-phase4`. Default unset (zero behavior change for every existing caller); when set, runs exactly once, only after `marathon.phase.approved` is already logged and green telemetry already emitted — never gating the approval itself. A failing `--post-approve-cmd` does not retroactively un-approve the phase; it exits 9 and writes an `ESCALATION.md` with reason `post-approve-failed`. 14 new `test/marathon-drive.sh` cases (7 per runtime) cover help-text, omitted-flag parity, a passing hook running exactly once, and a failing hook's exit code + preserved approval + escalation reason — 126/126 full file. The relay itself timed out before an agy review turn (a large dual-runtime edit), but Codex's single committed turn was already correct and complete, verified by reading the diff directly rather than trusting the gate. The pre-advance gate then failed for two genuine reasons (not the Phases 0-3 flake): (1) a new `--help` check invoked the driver directly instead of through the file's `run_driver()` wrapper, missing the `MARATHON_ROOT=` marker `test/marathon-root-audit.sh` requires on every driver invocation — fixed by adding it; (2) the new `eval "$POST_APPROVE_CMD"` correctly tripped `test/security-scan.sh`, same class as the already-baselined `eval "$PRE_ADVANCE_CMD"` a few lines above — reviewed (same trust model, an operator-supplied CLI flag, not attacker input) and added the symmetric baseline entry. Full `validate.sh` green after both fixes. **All 5 phases of GH-273 are now shipped; doc moved to `3-COMPLETED`, issue closed.** A real harness bug found along the way (same-phase-id retry clobbers a phase's Approved record) was split out and filed separately as [#274](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/274) — not fired, tracked as its own follow-on. → [#273](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/273) · [GH-273-MARATHON-CLOSEOUT-AUTOMATION.md](PROJECT/3-COMPLETED/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md)
./CHANGELOG.md-756-- **GH-273: Phase 3 SHIPPED — `relay-automation/marathon-closeout.sh` extracts the deterministic post-marathon git ceremony into one script.** Fired via `swarm-preflight → marathon-drive` with `--phase-id gh273-phase3`. Given this phase can `git push`/create/merge a PR — materially higher stakes than Phases 0-2's prompt/config files — the contract required `--dry-run` as a first-class mode and mandated the test suite stub `git`/`gh` (never touch this repo's real remote or GitHub during the build/test turn); verified both directly before closing out, not just trusted the gate. `marathon-closeout.sh`: stage+commit+push → `gh pr create` → `gh pr checks` (red → exit 4, halt before merge) → `gh pr view --json mergeable` (not `MERGEABLE` → exit 4, halt) → `gh pr merge` → switch to `development` → `git pull --ff-only`; command failures normalize to exit 3, argument/precondition errors to exit 2. `test/marathon-closeout.sh` PATH-shadows `git`/`gh` with fake binaries inside a disposable `mktemp` scratch repo — 18/18 pass (dry-run inertness, happy path, red-checks halt, unmergeable halt, command-failure/usage exit codes, `bash -n` clean), confirmed standalone. Same flaky-gate pattern as Phases 0-2 (4 for 4 now); confirmed clean, closed out manually. → [#273](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/273) · [GH-273-MARATHON-CLOSEOUT-AUTOMATION.md](PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md)
./CHANGELOG.md-757-- **GH-273: Phase 2 SHIPPED — `.claude/loose-ends-sequence.md` gives this repo a real custom end sequence.** Fired via `swarm-preflight → marathon-drive` with `--phase-id gh273-phase2`. Contract was grounded in a direct read of `~/.claude/skills/loose-ends/SKILL.md` rather than inferred: the manifest mechanism already existed (project-local `.claude/loose-ends-sequence.md` takes precedence over the global one, `### *` heading, `- cmd` bullets, paths resolved relative to the manifest's own directory) — Phase 2 only needed to author the file. Codex got the path-resolution subtlety right unprompted: bullets are `../utils/pdda/pdda.sh run` and `../utils/roadmap-dashboard.sh`, correctly relative to `.claude/` (the manifest's directory), not repo root. The third bullet is a reminder that `PROJECT/2-WORKING` docs move to `3-COMPLETED` only once `marathon-cleanup` classifies them `VERIFIED-COMPLETE`, never on a bare status-word edit. Same flaky-gate pattern as Phases 0-1 (`test/xyz-harness-hooks.sh`'s pre-existing "relay green count" assertion — 3 for 3 now, unrelated to any of the three builds); confirmed clean each time, closed out manually. → [#273](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/273) · [GH-273-MARATHON-CLOSEOUT-AUTOMATION.md](PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md)
--
./CHANGELOG.md-933-
./CHANGELOG.md-934-### GH-161 harness observability — decision-point tracing into the existing transcript
./CHANGELOG.md:935:Built GH-161's Phase 1 shape (explored earlier the same day; [PROJECT/3-COMPLETED/GH-161-HARNESS-OBSERVABILITY.md](PROJECT/3-COMPLETED/GH-161-HARNESS-OBSERVABILITY.md)): `rtl_trace()` (opt-in via `RTL_TRACE=1`) and `rtl_log_always()` (mirrors an existing unconditional diagnostic, no new gating) in [relay-automation/relay-turn-lib.sh](relay-automation/relay-turn-lib.sh), instrumenting root resolution (`rtl_init`), allowlist match/reject (`rtl_check`), worktree seed/copy-back (`rtl_worktree_begin`/`rtl_worktree_end`), and the containment/token-handoff branches (`rtl_enforce`) — all written into the turn's own transcript (`CODEX_LOG`/`AGY_LOG`), never a new log file. Also closed GH-165's actual root gap: `CODEX_LOG`/`AGY_LOG` now default to a persistent path via the existing `rtl_transcript_root` resolver (`relay-system/logs/<date>/`, gitignored) instead of a PID-keyed tmp file that vanished with the process. `RTL_LOG` is exported in both `codex-turn.sh`/`agy-turn.sh` **before** `rtl_init` runs, and the agent-binary redirect switched from truncating (`>`) to appending (`>>`) so it no longer wipes the trace line `rtl_init` already wrote. The new end-to-end test (`test/relay-turn-trace.sh`) caught two real bugs before they shipped: a `set -e`-under-`test && action` idiom that silently killed an otherwise-successful turn whenever nothing needed sweeping, and the truncating-redirect data loss above — both fixed. Verification: `test/relay-turn-trace.sh` **20/20** (new, added to `validate.sh`); the full existing containment/shim regression set (`codex-turn.sh`, `agy-turn.sh`, `worktree-isolation.sh`, `shim-worktree.sh`, `claude-turn.sh`, `aider-turn.sh`, `archive-commit.sh`, `relay-artifact-file.sh`, `relay-dep-drift.sh`, `relay-turn-handoff.sh`, `relay-turn-timeout.sh`) all still green; `skills/relay-automation/relay-pkg.tar.gz` regenerated. `./validate.sh`'s remaining 4 failures (`archive-writers.sh`, `xyz-harness-hooks.sh`, `security-scan.sh`, `python:test_python_layer.py`) were independently reproduced against a clean `origin/main` baseline via `git stash` — pre-existing, unrelated to this change.
./CHANGELOG.md-936-### Ledger housekeeping: GH-165 closed, GH-159 doc authored, stale relay-to-issue line fixed
./CHANGELOG.md-937-Closed [#165](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/165) — its Definition-of-Done was fully met (see entry below); doc moved to `PROJECT/3-COMPLETED/GH-165-CODEX-TOKEN-OWNERSHIP.md`. Authored the missing local doc for [GH-159](PROJECT/1-INBOX/GH-159-HQ-REPO-RESOLVE-DEDUPE.md) (`hq_repo_resolve` reports ambiguous when the same registry path resolves twice — root-caused to a missing dedup-by-resolved-path step in `hq_xyz_lookup`, `utils/hq/hq-lib.sh:71-77`), captured 2026-07-06 via GH-158 but never doc'd until now. Added GH-159 as a third lane to [Marathon Plan E](PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07-E-BUILD.md), alongside GH-168 (aider-turn.sh gitignore fix) and GH-169 (acorn first-pass integration) — all three independent, parallel-safe build lanes. Also fixed a stale `ROADMAP.md` line for the relay-to-issue skill (still marked 🟡 with a dead link to a `2-WORKING` path that no longer exists, even though the doc shipped and moved to `3-COMPLETED` on 2026-07-05): that drift was causing `utils/marathon-plan.sh` to surface it as a ghost live Wave 1 item in the auto-generated `MARATHON-PLAN-2026-07-07.md`.
--
./CHANGELOG.md-1030-
./CHANGELOG.md-1031-### GH-112 Python port landed as opt-in (`XYZ_PYTHON=1`) — Bash stays the default
./CHANGELOG.md:1032:Rebuilt the GH-112 Python port (old PR #121, conflicting + `development`-targeted) as a clean additive branch off post-#135/#134 `main`. The payload: 13 Python modules under `utils/py/` (turn scripts, poll/consult/relay-loop, marathon/relay orchestrators, `rtl.py` FFI wrapper), `pytest.ini`, and `test/test_python_layer.py` — extracted file-level from the old branch, leaving its stray artifacts and `-legacy.sh` renames behind. **The toggle is inverted from PR #121:** all 11 ported entry scripts keep their canonical Bash bodies as the default and gain a uniform header shim — `XYZ_PYTHON=1` reroutes the entry point to the matching `utils/py/` module (same CLI contract + exit codes), unset/0 changes nothing. PR #121 had flipped 7 of the 11 to Python-by-default with **no** Bash fallback (only 4 had `XYZ_LEGACY_BASH`); now every script has the two-way switch and the battle-hardened Bash containment path is untouched. `relay-turn-lib.sh` remains the permanent Bash containment boundary per [decisions/2026-07-04-python-port-boundary.md](decisions/2026-07-04-python-port-boundary.md) — the Python modules shell into it via `rtl.py`. Proof: full `validate.sh` **100/100 green** in default mode; toggle routing verified for all 11 scripts in both modes (22/22); pytest **8/8**; live `XYZ_PYTHON=1 codex-turn.sh` honors the exit-code contract. Housekeeping: regenerated `relay-pkg.tar.gz` (poll.sh header changed) and baselined 2 pre-existing `test/hq-locator.sh` eval findings that were failing `security-scan.sh`'s GH-64 gate on `main`. Follow-up on [#112](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/112): the Python modules were written against pre-#134 shell behavior — port PR #134's reliability changes into `utils/py/` before ever promoting Python to default.
./CHANGELOG.md-1033-
./CHANGELOG.md-1034-### HQ resolution/dispatch hardening — 4 Codex-review fixes (GH-132)
--
./CHANGELOG.md-1056-
./CHANGELOG.md-1057-### Perplexity Sonar via OpenRouter shipped as the second deep-research backend (#129)
./CHANGELOG.md:1058:Built the backend GH-87's seam reserved, in an isolated worktree on branch `gh-129-perplexity-openrouter`. `relay-automation/deep-research.mjs` gains `--provider agy|openrouter` (default `agy` — the existing path is byte-identical, all 23 original assertions untouched) and a `runOpenRouter` backend: Node global `fetch` (stdlib only, no new deps) against `{OPENROUTER_BASE_URL:-https://openrouter.ai/api/v1}/chat/completions`, `Authorization: Bearer $OPENROUTER_API_KEY`, model `perplexity/sonar` (`DEEP_RESEARCH_OPENROUTER_MODEL` override), `--search-context-size` mapped to Perplexity's native `web_search_options.search_context_size`, `--temperature`/`--max-tokens` passed through, AbortController honoring `DEEP_RESEARCH_TIMEOUT_MS`. Citations normalize in preference order `message.annotations[].url_citation` → Perplexity `citations[]` passthrough → the existing bare-URL scan; typed fail-closed errors gain `missing_api_key` (never a silent cross-provider fallback). `test/deep-research.sh` grew a stub HTTP server injected via `OPENROUTER_BASE_URL`: **45/45** (22 new assertions covering request shape incl. auth header + `web_search_options`, all three citation paths, model override, HTTP 500 / non-JSON / empty / timeout). The stub's fake `test-key` literal is hand-baselined in `security-scan-baseline.txt` per the GH-64 convention; full `validate.sh` exit 0. **Applied GH-124's lesson before merge this time: one live smoke run against real OpenRouter→Perplexity Sonar returned in 4.5s with 15 real citations (titles intact), normalized correctly.** README row added documenting both backends. Write-set overlaps **#124** — its lane fires only after this merges. **Merged same-day via PR #130 (`79395ee`) after an independent headless agy relay review — VERDICT: PASS, zero findings ([thread](relay-system/2026-07-04/gh129-perplexity-openrouter-review.md), driven with `relay-drive.sh --review-once --artifact-file` on the branch diff, since driven turns run in a worktree of ROOT@HEAD where branch-only commits are invisible); #129 auto-closed, branch + worktree deleted, doc moved to `3-COMPLETED`.**
./CHANGELOG.md-1059-
./CHANGELOG.md-1060-### Perplexity-via-OpenRouter deep-research backend captured (issue-first intake, #129)
--
./CHANGELOG.md-1366-### Agy relay QA of the marathon queue drive — 1 Blocker + 3 Should + 2 Nit, all fixed
./CHANGELOG.md-1367-A `/relay-xyz` headless review with agy of the two highest-blast-radius pieces from the marathon
./CHANGELOG.md:1368:queue drive below (`relay-automation/hooks/security-scan.sh`'s baseline mechanism,
./CHANGELOG.md-1369-`utils/swarm-preflight.sh`'s branch/carve-out logic) — `relay-system/2026-07-01/marathon-critical-qa.md`,
./CHANGELOG.md-1370-3 rounds, closed **Approved**.
--
./CHANGELOG.md-1392-`relay-turn-lib.sh` precedent for exactly this trap.
./CHANGELOG.md-1393-
./CHANGELOG.md:1394:`test/security-scan.sh` 20→35 checks, `test/swarm-preflight.sh` 44→47 checks — every new check
./CHANGELOG.md-1395-proves a real exploit is closed or a real discrepancy resolved, not just re-asserting existing
./CHANGELOG.md-1396-behavior. `validate.sh` 77/77, `pdda.sh run` clean at every commit
--
./CHANGELOG.md-1406-**GH-69 SHIPPED, CLOSED** — marathon builds had no branch-cutting step; partial/failed work landed on whatever was checked out. Three-stage fix, always read-only until an operator confirms (GUIDING-PRINCIPLES.md §8 — never auto-cut): (1) `marathon-plan.sh` emits a deterministic `suggested_branch: marathon/<slug>-<date>` per active wave lane; (2) `swarm-preflight.sh` checks real branch existence via `git show-ref` and emits `branch_ready`/`skip_branch_prompt` (the latter: risk==1 + independent-zone artifacts, re-deriving marathon-plan's KERNEL_PATHS/SHIM_RE heuristic locally so the packet stays self-contained) into the packet (JSON + `packet.md` + text report); (3) the orchestrating-agent contract is documented inline in `swarm-preflight.sh`'s header and self-stated in every packet — a driving agent doesn't need to recompute it. `test/marathon-plan.sh` 34/34 (+3), `test/swarm-preflight.sh` 44/44 (+9). `c3cdef5`.
./CHANGELOG.md-1407-
./CHANGELOG.md:1408:**GH-64 active-gate follow-on SHIPPED** — the security scanner (shipped earlier, `a0cc84e`) correctly flagged 40 legitimate existing patterns repo-wide (reviewed operator-configured dispatcher `eval`s in `poll.sh`/`relay-drive.sh`/`marathon-drive.sh`/`improve-loop.sh`, doc-comment prose, its own test fixtures), which made it useless as a real blocking gate. Added a hand-maintained, checked-in baseline (`relay-automation/hooks/security-scan-baseline.txt`): exact `file\trule\tline-text` triples, matched by content not line number (survives unrelated file changes; a reformatted flagged line drops out and must be re-reviewed, deliberately not silent). A baselined finding is still PRINTED (labeled "baselined") — nothing hidden, per GUIDING-PRINCIPLES.md #8 — it just doesn't fail the scan. New `--no-baseline` (raw audit) and `--tsv` (machine-parseable rows for authoring baseline entries) flags. 45 findings reviewed and baselined (40 original + 5 from this change's own new test fixtures, caught by the gate before being added — a live demonstration it works). `test/security-scan.sh` grew 20→28 checks, including a "real repo against the checked-in baseline is clean" assertion that IS the blocking gate, already wired into `validate.sh`. `a66bf9a`.
./CHANGELOG.md-1409-
./CHANGELOG.md-1410-**Bet:** a content-keyed (not line-keyed) baseline stays correct as the codebase evolves without needing constant re-generation, and forces a conscious re-review only when a baselined line's actual content changes — the assumption is line-content stability is the right unit of "this exact risk was reviewed," not line position. Reversibility: Easy — the baseline file is just deleted/edited by hand, no kernel or schema dependency. Revisit if the baseline file grows large enough that content-drift false-negatives (a line changes trivially and the reviewer rubber-stamps re-adding it without real re-review) become a real failure mode.
--
./CHANGELOG.md-1445-Two independent additive lanes, built as parallel Sonnet subagents on disjoint paths, each verified by the orchestrator (Opus) before commit; `validate.sh` owned by the orchestrator to avoid a shared-file race.
./CHANGELOG.md-1446-- **Lane B — GH-66 (`ff2ea44`)**: `utils/transcript-audit.sh` — periodic, READ-ONLY audit over a transcript dir; structured report of `stale-ref` / `repeat-explore` / `unbounded-stall`; never mutates a transcript. `test/transcript-audit.sh` (7 checks incl. read-only checksum/mtime guarantee). Ran clean against the real 37-file corpus (7 unbounded-stalls).
./CHANGELOG.md:1447:- **Lane A — GH-64 (`a0cc84e`)**: `relay-automation/hooks/security-scan.sh` — self-contained, no-network fail-loud static scanner (eval-of-var, curl/wget|shell, AWS/PEM/GitHub/Slack secrets, credential literals); `test/security-scan.sh` (20 checks). **Deliberately scoped like GH-68's warn-only-first**: the test is wired into the gate; an active repo-wide BLOCKING scan is a follow-on (needs a suppression/baseline for legit `eval "$1"` in `poll.sh` + its own fixtures; pair with GH-61 CI). **Security note:** a full-tree scan confirmed NO real secret leak — all secret-pattern hits are the test's own fixtures + doc comments.
./CHANGELOG.md-1448-- Both new tests registered in `validate.sh`; full suite re-run green.
./CHANGELOG.md-1449-
--
./docs/ROADMAP-UPSTREAM-ARCHIVE.md-536-- **GH-66 · Session/transcript-log audit for stale-instruction drift** ✅ **SHIPPED 2026-07-01 (`ff2ea44`, marathon Wave 2 Lane B)** — `utils/transcript-audit.sh`: periodic, READ-ONLY audit over a transcript dir (default `AUDIT/relay-automation-transcripts/`). Emits a structured, greppable report of three drift classes — `stale-ref` (deprecated/`.bak`/missing repo paths), `repeat-explore` (same dir explored ≥ threshold across turns), `unbounded-stall` (transcript with no terminal exit/STATUS/DECISION marker). Findings are a report, not a gate; never writes/moves/deletes a transcript. `test/transcript-audit.sh` (7 checks incl. a read-only checksum/mtime guarantee) in `validate.sh`. Ran clean against the real 37-file corpus (7 unbounded-stalls). Non-goals honored: not a transcript store (GH-30), no auto-apply. → [GH-66-SESSION-LOG-AUDIT.md](PROJECT/3-COMPLETED/GH-66-SESSION-LOG-AUDIT.md) · [#66](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/66)
./docs/ROADMAP-UPSTREAM-ARCHIVE.md-537-
./docs/ROADMAP-UPSTREAM-ARCHIVE.md:538:- **GH-64 · Security-scanning guardrail in the review chain** ✅ **Tool + test SHIPPED 2026-07-01 (`a0cc84e`, marathon Wave 2 Lane A); ACTIVE BLOCKING GATE wired 2026-07-01** — `relay-automation/hooks/security-scan.sh`: self-contained, no-network static scanner for shell scripts; fail-loud (`SECURITY: <file>:<line> [rule]` to stderr, non-zero exit), never auto-fixes. Rules: eval-of-variable, `curl`/`wget`-piped-to-shell, AWS keys, PEM private-key headers, GitHub PATs, Slack tokens, literal credential assignments. **Active-gate follow-on (this session):** a hand-maintained, checked-in baseline (`relay-automation/hooks/security-scan-baseline.txt`, exact `file\trule\tline-text` triples, matched by content not line number) suppresses the known-legitimate findings (reviewed dispatcher `eval`s in `poll.sh`/`relay-drive.sh`/`marathon-drive.sh`/`improve-loop.sh`, doc-comment prose, the scanner's own test fixtures) WITHOUT hiding them — every baselined finding still prints (labeled `SECURITY (baselined)`), per GUIDING-PRINCIPLES.md #8; a genuinely new finding still fails loud. New `--no-baseline` (raw scan) and `--tsv` (machine-parseable rows for authoring baseline entries) flags. `test/security-scan.sh` now 28 checks including a real-repo-against-the-checked-in-baseline assertion — that assertion IS the blocking gate, already wired into `validate.sh` (no separate CI step needed). Confirmed NO real secret leak in any of the 45 baselined findings. → [GH-64-SECURITY-SCANNING-GUARDRAIL.md](PROJECT/3-COMPLETED/GH-64-SECURITY-SCANNING-GUARDRAIL.md) · [#64](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/64)
./docs/ROADMAP-UPSTREAM-ARCHIVE.md-539-
./docs/ROADMAP-UPSTREAM-ARCHIVE.md-540-- **GH-68 · Cross-agent dependency conflict detection** ✅ **Phase 1 SHIPPED 2026-07-01 (`94558c5`)** — warn-only, inject-only `dependency.drift` signal per [decision](decisions/2026-07-01-cross-agent-dep-conflict.md): new event verb (`src/events.js` + `tick drift`, best-effort so it can't fail a turn); post-commit detection in `relay-turn-lib.sh` when a landed turn changes the containment kernel / `src/project.js` / `src/events.js`; `rtl_drift_brief` (per-agent `.tick` watermark, capped) read by both shims into the next turn brief; `src/project.js` skips the verb in the fold (no phantom task). **Costly** kernel schema extension. Regression: `test/relay-dep-drift.sh` (12 checks); `validate.sh` 72/72 exit 0. **Phase 2** (blocking gate) is an explicit deferred follow-on — only if field data shows the warn-only posture misses a real conflict. → [GH-68-CROSS-AGENT-DEP-CONFLICT.md](PROJECT/3-COMPLETED/GH-68-CROSS-AGENT-DEP-CONFLICT.md) · [#68](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/68)
--
./test/consult.sh-122-
./test/consult.sh-123-# --- (7) AIDER advisor: answers via a stub, transcript captured (Aider↔OpenRouter lane) ----------
./test/consult.sh:124:# Non-secret key via a var (not a literal) so the security-scan credential rule's variable exclusion applies.
./test/consult.sh-125-FAKE_ORK="orkey-not-real"
./test/consult.sh-126-AIDER_STUB="$WORK/aider-stub"
--
./utils/signal-triage.sh-14-# │ rule-2  │ bug      │ deterministic failure of existing behaviour: validate.sh test FAIL,      │
./utils/signal-triage.sh-15-# │         │          │ canary/fixture rejection, relay containment revert (exit 6), or           │
./utils/signal-triage.sh:16:# │         │          │ security-scan failure (source: "security-scan" recorded — NOT a separate  │
./utils/signal-triage.sh-17-# │         │          │ bucket per GP #7)                                                         │
./utils/signal-triage.sh-18-# ├─────────┼──────────┼──────────────────────────────────────────────────────────────────────────┤
--
./utils/signal-triage.sh-35-#   --source <src>    Signal source. One of:
./utils/signal-triage.sh-36-#                       validate-fail       validate.sh test FAIL
./utils/signal-triage.sh:37:#                       security-scan       security scan finding
./utils/signal-triage.sh-38-#                       relay-exit6         relay containment revert (exit 6)
./utils/signal-triage.sh-39-#                       canary-reject       canary/fixture rejection
--
./utils/signal-triage.sh-150-  DEDUPE_FIELD=""
./utils/signal-triage.sh-151-
./utils/signal-triage.sh:152:elif [[ "$SIGNAL_SOURCE" == "security-scan" ]]; then
./utils/signal-triage.sh-153-  # Security findings fold into bug (NOT a separate bucket — GP #7)
./utils/signal-triage.sh-154-  CATEGORY="bug"
./utils/signal-triage.sh-155-  SEVERITY="high"
./utils/signal-triage.sh:156:  EVIDENCE="rule-2-bug / security-scan"
./utils/signal-triage.sh-157-  if [[ -n "$DETAIL" ]]; then EVIDENCE="${EVIDENCE}: ${DETAIL}"; fi
./utils/signal-triage.sh-158-  DEDUPE_FIELD=""
--
./utils/signal-triage.sh-204-else
./utils/signal-triage.sh-205-  echo "$SCRIPT_NAME: unknown --source value: '$SIGNAL_SOURCE'" >&2
./utils/signal-triage.sh:206:  echo "$SCRIPT_NAME: valid sources: validate-fail, security-scan, relay-exit6, canary-reject, watchdog-parked, pdda-sync, dependency-drift, manual, informational" >&2
./utils/signal-triage.sh-207-  exit 2
./utils/signal-triage.sh-208-fi
--
./utils/git-sandbox-guard.sh-2-set -euo pipefail
./utils/git-sandbox-guard.sh-3-
./utils/git-sandbox-guard.sh:4:# git-sandbox-guard.sh — GH-50: prove the repository config can be written before a
./utils/git-sandbox-guard.sh-5-# branch-changing command gets a chance to rewrite the index or working tree.
./utils/git-sandbox-guard.sh-6-
./utils/git-sandbox-guard.sh-7-usage() {
./utils/git-sandbox-guard.sh-8-  cat >&2 <<'USAGE'
./utils/git-sandbox-guard.sh:9:Usage: utils/git-sandbox-guard.sh [--repo <path>] [--operation <label>] [--] [command ...]
./utils/git-sandbox-guard.sh-10-
./utils/git-sandbox-guard.sh-11-Preflight only when no command is supplied. When a command is supplied, run it only
--
./utils/git-sandbox-guard.sh-15-
./utils/git-sandbox-guard.sh-16-refuse() {
./utils/git-sandbox-guard.sh:17:  echo "git-sandbox-guard: REFUSING — $*" >&2
./utils/git-sandbox-guard.sh-18-  exit 2
./utils/git-sandbox-guard.sh-19-}
--
./PROJECT/3-COMPLETED/GH-35-TEST-TIER-ROUTING.md-157-| `test/ci-workflow.sh` | green (exit 0) |
./PROJECT/3-COMPLETED/GH-35-TEST-TIER-ROUTING.md-158-| `bash test/gh308-frozen-twin-guard.sh --check --staged` | clean — no frozen twin touched, no new Bash under `utils/`/`relay-automation/` |
./PROJECT/3-COMPLETED/GH-35-TEST-TIER-ROUTING.md:159:| Full `./validate.sh` (tier 3) on this change | **GREEN 216/216** (2026-08-18, standalone clone `XYZ-forge-gh35`, 4-wide balanced, ~12 min wall) — first run was RED for real reasons this change then fixed (path-integrity: fictional example paths in tier assertions; GH-472: piped `grep -q` shapes; security-scan: un-baselined `ok()` eval in the new suite; roadmap-dashboard: stale committed artifact) plus one expected false alarm: the GH-1 identity bracket fired because the operator set the clone's git identity *mid-run* — verified bare/origin/HEAD untouched |
./PROJECT/3-COMPLETED/GH-35-TEST-TIER-ROUTING.md-160-| Live tier-2 run, real repo | `./validate.sh --subsystem swe-diagram` → green 2/2 in **1.5s** (registry resolution, 2-wide niced pool, identity bracket, honest summary) |
./PROJECT/3-COMPLETED/GH-35-TEST-TIER-ROUTING.md-161-| Measured push-latency + CPU deltas (issue success criterion) | width change proven via `--print-mode` (4 vs 8 on a 10-core host); wall-clock/CPU measurements on real pushes still owed here |
--
./PROJECT/3-COMPLETED/GH-45-WORKTREE-GATE-REFUSAL.md-66-|---|---|
./PROJECT/3-COMPLETED/GH-45-WORKTREE-GATE-REFUSAL.md-67-| `test/gh35-test-tiers.sh` §9 (GH-45) | 12/12 within the suite's 67/0 — worktree refused exit 2 before anything runs; message names core.bare / origin / remote-refs / development consequences and the override; override runs AND announces; **control: the same fixture's main checkout still runs silently**; `ci-local.sh` refuses from the worktree; absolute-path invocation with HERE in the worktree still refused |
./PROJECT/3-COMPLETED/GH-45-WORKTREE-GATE-REFUSAL.md:68:| Neighbor pins after the guard | `gh544-parallel-default` 29/0 · `gh4-ungated-clone-warning` 6/0 · `ci-workflow` green · `path-integrity` 2/0 · security-scan clean · mktemp-trap-guard clean |
./PROJECT/3-COMPLETED/GH-45-WORKTREE-GATE-REFUSAL.md-69-| Full `./validate.sh` on this change | **GREEN 216/216** (2026-08-18, clone `XYZ-forge-gh35`, 4-wide balanced) — run from the normal checkout, where the guard passes silently, exactly as the control asserts |
./PROJECT/3-COMPLETED/GH-45-WORKTREE-GATE-REFUSAL.md-70-
--
./PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/brief-gh50-sandboxed-git-guard.md-32-truncate away; the visible symptom is only a misleading upstream hint.
./PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/brief-gh50-sandboxed-git-guard.md-33-
./PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/brief-gh50-sandboxed-git-guard.md:34:1. `utils/git-sandbox-guard.sh` (new): a preflight primitive that probes `.git/config`
./PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/brief-gh50-sandboxed-git-guard.md-35-   writability and refuses tracking/branch-mutation operations up front with a named error,
./PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/brief-gh50-sandboxed-git-guard.md-36-   for harness scripts that switch branches (relay/marathon drivers).
--
./PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/MARATHON.yaml-21-
./PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/MARATHON.yaml-22-  - id: gh50-sandboxed-git-guard
./PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/MARATHON.yaml:23:    name: "GH-50: git-sandbox-guard preflight — refuse switch --track/branch -D before tree mutation when .git/config is unwritable"
./PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/MARATHON.yaml-24-    reviewer: agy
./PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/MARATHON.yaml-25-    brief: PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/brief-gh50-sandboxed-git-guard.md
./PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/MARATHON.yaml:26:    artifact: utils/git-sandbox-guard.sh,test/gh50-sandboxed-git-guard.sh,AGENTS.md,validate.sh
./PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/MARATHON.yaml-27-    depends_on: gh168-wave-reconcile-scope
./PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/MARATHON.yaml-28-    max_review_rounds: 3
--
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md-37-## Plan
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md-38-
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md:39:1. `utils/git-sandbox-guard.sh` (new): a preflight primitive that probes `.git/config`
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md-40-   writability and refuses tracking/branch-mutation operations up front with a named error,
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md-41-   for harness scripts that switch branches (relay/marathon drivers).
--
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md-58-  "target":        { "repo": ".", "ref": "development" },
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md-59-  "gate":          "bash validate.sh",
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md:60:  "fix_probes":    [ { "type": "path_absent", "path": "utils/git-sandbox-guard.sh" },
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md-61-                     { "type": "path_absent", "path": "test/gh50-sandboxed-git-guard.sh" } ],
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md:62:  "artifacts":     [ "utils/git-sandbox-guard.sh", "test/gh50-sandboxed-git-guard.sh", "AGENTS.md", "validate.sh" ],
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md:63:  "artifacts_new": [ "utils/git-sandbox-guard.sh", "test/gh50-sandboxed-git-guard.sh" ],
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md-64-  "remediation":   { "source": "self#plan", "criteria": "guarded branch ops refuse-or-succeed atomically when .git/config is unwritable; no tree mutation on refusal; gh50 suite green" },
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md:65:  "lanes":         { "agy_safe": [ "utils/git-sandbox-guard.sh", "test/gh50-sandboxed-git-guard.sh" ], "orchestrator_only": [ "AGENTS.md" ] }
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md-66-}
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md-67-```
--
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md-71-- A sandboxed `git switch --track` HALF-APPLIES: index and working tree move, the `.git/config`
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md-72-  write fails, HEAD stays behind — the tree silently holds another branch's content. Probe
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md:73:  `.git/config` writability BEFORE any branch mutation (`utils/git-sandbox-guard.sh`), not after.
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md-74-- The fatal line (`could not lock config file .git/config`) is easy to truncate away; never trim
./PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md-75-  git stderr on branch operations — the visible symptom without it is a misleading upstream hint.

2026-08-26T03:35:36.735902Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "rg -n -C 4 'git-sandbox-guard\\.sh' relay-automation utils --glob '*.sh' --glob '*.py' && rg -n -C 3 'security-scan\\.sh' validate.sh ci-local.sh githooks relay-automation utils --glob '*.sh' --glob '*.py' && nl -ba validate.sh | sed -n '1,180p' && nl -ba PROJECT/3-COMPLETED/GH-50-SANDBOXED-GIT-HALF-APPLY.md | sed -n '1,160p' && nl -ba PROJECT/2-WORKING/MARATHON-2026-08-24-GH2-50-168/brief-gh50-sandboxed-git-guard.md | sed -n '1,150p'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z
 succeeded in 0ms:
utils/git-sandbox-guard.sh-1-#!/usr/bin/env bash
utils/git-sandbox-guard.sh-2-set -euo pipefail
utils/git-sandbox-guard.sh-3-
utils/git-sandbox-guard.sh:4:# git-sandbox-guard.sh — GH-50: prove the repository config can be written before a
utils/git-sandbox-guard.sh-5-# branch-changing command gets a chance to rewrite the index or working tree.
utils/git-sandbox-guard.sh-6-
utils/git-sandbox-guard.sh-7-usage() {
utils/git-sandbox-guard.sh-8-  cat >&2 <<'USAGE'
utils/git-sandbox-guard.sh:9:Usage: utils/git-sandbox-guard.sh [--repo <path>] [--operation <label>] [--] [command ...]
utils/git-sandbox-guard.sh-10-
utils/git-sandbox-guard.sh-11-Preflight only when no command is supplied. When a command is supplied, run it only
utils/git-sandbox-guard.sh-12-after the repository's config and config-lock path both pass a real write probe.
utils/git-sandbox-guard.sh-13-USAGE
validate.sh-414-                                 #   exporter payload keys + baked chrome in both artifacts; the rollup
validate.sh-415-                                 #   embed itself lives in hq-rollup.sh cases A/F/G)
validate.sh-416-  "transcript-audit.sh"
validate.sh:417:  "security-scan.sh"
validate.sh-418-  "sentinel-tier1.sh"           # GH-281 (Tier-1 JSONL finding capture)
validate.sh-419-  "sentinel-network-guard.sh"   # GH-281 (bundled scripts stay zero-network)
validate.sh-420-  "sentinel-driver-hooks.sh"    # GH-281 (marathon-drive.sh Tier-1 hooks: default-off + on-mode append)
--
relay-automation/hooks/security-scan.sh-1-#!/usr/bin/env bash
relay-automation/hooks/security-scan.sh-2-#
relay-automation/hooks/security-scan.sh:3:# security-scan.sh — static security scanner for shell scripts (GH-64)
relay-automation/hooks/security-scan.sh-4-#
relay-automation/hooks/security-scan.sh-5-# Implements fail-loud detection per GUIDING-PRINCIPLES.md #8 (no masked failure):
relay-automation/hooks/security-scan.sh-6-# every finding is printed to stderr as SECURITY: <file>:<line> <reason>, and the
--
relay-automation/hooks/security-scan.sh-8-# silently suppresses.  No network access required.
relay-automation/hooks/security-scan.sh-9-#
relay-automation/hooks/security-scan.sh-10-# Usage:
relay-automation/hooks/security-scan.sh:11:#   bash relay-automation/hooks/security-scan.sh [--no-baseline] [--baseline FILE] [--tsv] [<path>...]
relay-automation/hooks/security-scan.sh-12-#
relay-automation/hooks/security-scan.sh-13-# --tsv prints each finding as `<file>\t<rule>\t<line text>` on stdout instead of the human-readable
relay-automation/hooks/security-scan.sh-14-# "SECURITY: ..." line — paste a row straight into the baseline file's tab-separated columns after
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
    15	
    16	# ── GH-45: REFUSE to run from a linked git worktree ─────────────────────────────────────────────
    17	# A linked worktree shares the parent clone's .git common directory — config, refs, and object
    18	# store alike. A suite that escapes its fixture (or resolves one to an empty string) therefore
    19	# reaches the PARENT clone, not a sandbox: the observed 2026-08-19 run set core.bare=true,
    20	# repointed origin at a deleted temp path, deleted every refs/remotes/origin/*, and overwrote
    21	# development with fixture commits (GH-564's class, firing for real). The detection is the same
    22	# --git-common-dir idiom the GH-448 driver-lock resolver uses: in the main checkout the absolute
    23	# git dir IS the common dir; in a linked worktree it is <common>/worktrees/<name> and differs.
    24	# Fail closed for every mode — tiers 1 and 2 run fixture-driven suites too. BOTH the invocation
    25	# CWD (where a suite's `git -C ""` escape lands) and HERE (whose clone the identity bracket
    26	# asserts) are checked, so invoking the script by absolute path from outside cannot slip past.
    27	_wt_refuses() {  # <dir>... -> exit 2 if any dir lives in a linked worktree
    28	  local d a c ca
    29	  for d in "$@"; do
    30	    a="$( cd "$d" 2>/dev/null && git rev-parse --absolute-git-dir 2>/dev/null )" || continue
    31	    c="$( cd "$d" 2>/dev/null && git rev-parse --git-common-dir 2>/dev/null )" || continue
    32	    [ -n "$a" ] && [ -n "$c" ] || continue
    33	    ca="$( cd "$d" 2>/dev/null && cd "$c" 2>/dev/null && pwd -P )" || continue
    34	    [ -n "$ca" ] || continue
    35	    if [ "$a" != "$ca" ]; then
    36	      cat >&2 <<WTREFUSE
    37	validate.sh: REFUSING — '$d' is a linked git worktree, which shares the parent clone's
    38	  .git (config, refs, objects). Suites that write to 'the repo' reach the PARENT, not a
    39	  fixture: an observed run set core.bare=true, repointed origin at a deleted temp path,
    40	  deleted every refs/remotes/origin/*, and overwrote development with fixture commits.
    41	  Run the gate from a normal clone. Override with XYZ_ALLOW_WORKTREE_GATE=1 only if you
    42	  accept that blast radius.
    43	WTREFUSE
    44	      exit 2
    45	    fi
    46	  done
    47	}
    48	if [ "${XYZ_ALLOW_WORKTREE_GATE:-0}" != "1" ]; then
    49	  _wt_refuses "$HERE" "${PWD:-.}"
    50	else
    51	  # Announced, never silent — a bypass that says nothing is indistinguishable from no guard.
    52	  echo "validate.sh: XYZ_ALLOW_WORKTREE_GATE=1 — running from a linked worktree at the operator's explicit request; the parent clone's .git is exposed (GH-45)." >&2
    53	fi
    54	
    55	TESTS=(
    56	  "projection-idempotent.sh"
    57	  "concurrent-claim.sh"
    58	  "chaos-stale-writer.sh"
    59	  "chaos-concurrent-pollers.sh"
    60	  "chaos-midturn-kill.sh"
    61	  "path-overlap.sh"
    62	  "scope-change.sh"
    63	  "tick-foreign-cwd.sh"
    64	  "handoff.sh"
    65	  "handoff-exclusive.sh"
    66	  "circuit-break.sh"
    67	  "terminality-seal.sh"          # GH-41 (terminal seal edge cases — cross-model review of PR #99)
    68	  "auto-sync.sh"
    69	  "analyze.sh"
    70	  "workstealing-verdict.sh"      # GH-4 (work-stealing via take + lane-count-independent verdict)
    71	  "verdict-edge.sh"              # GH-4 (verdict/collision edge cases — cross-model review of PR #101)
    72	  "claim-cap.sh"
    73	  "reap.sh"
    74	  "heartbeat.sh"
    75	  "cost.sh"
    76	  "take.sh"
    77	  "watchdog-liveness.sh"
    78	  "runner-loop.sh"
    79	  "poll-driver.sh"
    80	  "relay-loop.sh"
    81	  "poll-relay.sh"
    82	  "watchdog-relay.sh"
    83	  "codex-turn.sh"
    84	  "agy-turn.sh"
    85	  "pi-turn.sh"                   # GH-295 (Pi/pi.dev headless turn-taker: PI_MODEL safety + cost capture)
    86	  "relay-turn-trace.sh"          # GH-161 (rtl_trace/rtl_log_always/rtl_default_log instrumentation)
    87	  "aider-turn.sh"
    88	  "gh278-turn-timeout-parity.sh" # GH-278 (Aider Python/Bash/doc timeout default must stay aligned)
    89	  "gh308-frozen-twin-guard.sh"  # GH-308 (Python-authoritative twins: banner + committed-change guard)
    90	  "ate-run-variations.sh"       # GH-195 (ATE fuzzer git helpers: base-commit/disposable-guard/reset/detect-edit)
    91	  "model-alias.sh"              # GH-120 (OpenRouter model-alias fuzzy lookup)
    92	  "swe-diagram.sh"              # GH-146 (hub-ring layout ring-balance math + search/filter matching)
    93	  "claude-turn.sh"             # GH-58
    94	  "commandcode-turn.sh"        # GH-42 (Commandcode headless turn-taker)
    95	  "worktree-isolation.sh"
    96	  "shim-worktree.sh"
    97	  "marathon-yaml.sh"
    98	  "gh391-emit-marathon-yaml.sh" # GH-391 (ranked plan + packets -> runnable MARATHON.yaml; missing-packet control)
    99	  "marathon-drive.sh"
   100	  "gh284-runlog-heartbeat.sh"   # GH-284 (driver heartbeat + opt-in idempotent run log)
   101	  "gh115-round-cap.sh"
   102	  "gh307-gate-env-scrub.sh"      # GH-307 (pre-advance gate must not inherit run-identity tags)
   103	  "gh319-gate-path-with-space.sh" # GH-319 (default gate must not word-split a spaced repo path)
   104	  "gh320-twin-timeout-parity.sh" # GH-320 (Python twin turn-timeout defaults must match Bash + docs)
   105	  "gh322-unknown-arg-rejection.sh" # GH-322 (Python lane must reject unknown flags, not discard them)
   106	  "gh322-runlog-python-lane.sh"  # GH-322 (GH-284 P2 heartbeat + run log on the lane that actually runs)
   107	  "gh331-cost-summary.sh"        # GH-331/GH-308 (end-of-run tick-analyze cost summary on the default Python lane)
   108	  "gh308-poll-guards.sh"         # GH-308 (poll.py: --help/--mode/--turn-source/positional guards, GH-92 warning, watchdog default)
   109	  "gh308-swarm-gate-path.sh"     # GH-308 (swarm_preflight.py: uninstalled node/npm/python3 gate program → NOT-READY)
   110	  "gh343-gate-program-target-root.sh" # GH-343 (target-relative direct gate programs resolve from target_root)
   111	  "gh308-consult-guards.sh"      # GH-308 (consult.py: agy isolation-breach detector + codex ATTESTATION header)
   112	  "gh308-turn-shim-parity.sh"    # GH-308 (claude drift brief + turn-shim ROOT resolution + agy TICK_REPO_ROOT propagation)
   113	  "gh342-sentinel-debug-log-python.sh" # GH-342/GH-281 (Sentinel Tier-1 XYZ_DEBUG_LOG capture on the default Python lane)
   114	  "gh369-find-doc-root-resolution.sh"  # GH-369/GH-344 (find-doc.sh resolves PROJECT/** from the SWEPT repo; --root arg-parse guards)
   115	  "gh400-acceptance-fidelity.sh" # GH-400 (a capture doc's acceptance block must be the issue's, or declare each deviation)
   116	  "gh557-unknown-blocks-manifest.sh" # GH-557 (an `unknown` acceptance verdict blocks on a FROZEN MANIFEST member when the cause is structural — the issue states no criteria — and stays advisory everywhere else) — 16/0; control in test/baselines/GH-557-negative-control.md: 5 pass / 11 fail pre-fix, with the pin observed as `expected exit 5, got 0`. The three assertions that PASS pre-fix are the point: a detector that refused every acceptance-less issue would satisfy the pin and break ordinary lanes, and an outage must never block
   117	  "gh400-source-url.sh"          # GH-400 criterion 2 (a capture doc must cite its issue's URL) — 13/0 post-fix, observed 2/11 pre-fix
   118	  "gh419-gate-inventory.sh"      # GH-419 (generated decision-gate inventory; declared negative-control evidence)
   119	  "litmus-release.sh"            # Litmus 0.2.0 frozen-manifest audit. Suite mode fails ONLY on a false completion claim (a CLOSED manifest issue whose gate is missing/unregistered/undeclared); remaining work is INFO. The goalpost itself is `--release-gate` (red until done). Control: `--mutate-evidence` 9/0 — NOT run by this suite; run it by hand when touching audit_entry
   120	  "gh418-issue-state-frozen.sh"  # GH-418 (issue state is advisory; on-disk GH-308 FROZEN banner blocks writes)
   121	  "gh422-backfill-source-url.sh" # GH-422 (self-remediating message + bulk backfill) — 18/0; controls: pre-fix replay 15/3, conflict-guard mutation 16/2
   122	  "gh425-source-url-slug.sh" # GH-425 (source URL validates tracking repository + issue number; `related:` preserves foreign origin)
   123	  "gh410-containment-advisory.sh" # GH-410 (prose scan demoted to advisory; worktree_end stays the verdict) — 11/0; controls: pre-fix replay 7/4, containment-deleted mutation 9/2
   124	  "gh90-allowlist-directory.sh" # GH-90 (a DIRECTORY on ALLOW_PATHS was unmatchable by construction, so a valid lane surfaced as a containment violation) — 19/0; control: pre-fix replay 10/9. The nine that pass pre-fix are the point — C3/C5 are GH-59's own rules, which this fix had to leave intact, and C7 executes a real off-lane write, so the suite still goes red against a build with containment removed
   125	  "gh399-packet-acceptance-continuation.sh" # GH-399 (the packet's acceptance block is a lossless copy: continuations, scope, cap)
   126	  "gh417-turn-root-symlink-prefix.sh" # GH-417 (--show-toplevel is safe as resolve_turn_root's default: a Python turn with *_TURN_ROOT unset, from a repo behind a symlinked prefix, is not reverted) — 13/0; control: reverting GH-261's canonicalization brings exit 6 back, and the same reverted tree passes with a logical-form ROOT
   127	  "gh390-gate-guard.sh"          # GH-390/GH-382 (gate resource guard: wall/CPU/RSS caps, gate-killed escalation, off switch)
   128	  "gh457-gate-tiers.sh"         # GH-457 (the gate's caps come from a declared TIER; the default tier must exceed the worst observed real gate runtime) — 10/0; control: mutating the registry moves the resolved cap, restoring it moves back
   129	  "gh407-gate-ran-attribution.sh" # GH-407 (pre-advance-failed is reserved for a gate that RAN; every escalation records gate: not-run|green|red) — 7/0; control: pre-fix replay reproduces the mislabel inside the fixture
   130	  "gh390-timeout-attribution.sh" # GH-390 (exit-7 attribution: dialog vs runaway vs slow vs wedged)
   131	  "gh387-gate-not-first-executor.sh" # GH-387 (a timed-out turn's artifact is reviewed BEFORE any gate
   132	                                 #   executes it) — 9/0. The gate LOGS every invocation, because the
   133	                                 #   outcome alone cannot distinguish the fix: with a green gate the
   134	                                 #   phase completes either way. Pre-fix replay: restoring the probe
   135	                                 #   makes the gate run TWICE and the pin fails 7/2.
   136	                                 #   test/marathon.sh's GH-205 cases are the non-regression CONTROL,
   137	                                 #   not the pin — they pass with OR without the probe, which is
   138	                                 #   exactly why this file exists.
   139	  "gh492-idle-kill.sh"           # GH-492 (a blocked turn is killed on an IDLE threshold, not only at the
   140	                                 #   wall cap) — 16/0, covering both surfaces: agy-turn.py and consult.py.
   141	                                 #   The NEGATIVE CONTROLS are the point, because a trigger-happy bound is
   142	                                 #   worse than the hang it replaces — it kills reviewer turns, and a dead
   143	                                 #   reviewer turn takes a VERDICT with it. (1) a slow-but-progressing turn
   144	                                 #   must NOT be killed: measured 0.06s idle vs the blocked turn's 4.09s.
   145	                                 #   (2) consult scoping is pinned BOTH ways — a hung advisor reads 2.99s
   146	                                 #   idle scoped to its own pid and 0.14s under the shared parent, so the
   147	                                 #   case cannot pass on a build where scoping does nothing.
   148	                                 #   Behavioural mutation (not just a missing symbol): dropping worktree
   149	                                 #   progress from the idle signal makes the control fail, which is exactly
   150	                                 #   what a trigger-happy bound looks like.
   151	  "gh432-failed-turn-persist.sh" # GH-432 (a failed turn still reaches rtl_enforce: commit + token handoff; both routes) — 12/0 post-fix, control 5/4 pre-fix
   152	  "gh441-gate-env-contract.sh"   # GH-441 P2 (every driver export is classified scrub-or-pass; custom gates get the same clean env) — 13/0; controls: unhelped gate contaminated, orphaned helper fails loud
   153	  "gh218-synthetic-nested-driver-lock.sh" # GH-218 (synthetic suites must not contend for the harness clone's driver lock: static sweep rejects RELAY_DRIVER_LOCKED=0 on/above any relay_drive/marathon_drive invocation in test/synthetic; dynamic repro holds the real lock dir+live pid and runs gh101 green — the live marathon pre-advance incident shape) — 2/0; negative control: detector flags the pre-fix gh101 line 101
   154	  "gh217-gate-env-plan-outside.sh"    # GH-217 (MARATHON_ALLOW_PLAN_OUTSIDE_WORKING classified SCRUB in the gate_env registry + mirrored in the driver literal; test/marathon.sh unsets it defensively; the issue's literal repro — full marathon suite under the ambient leak — is green, GH-212 refusal specifically not vacuous) — 4/0
   155	  "gh448-driver-lock-resolver.sh" # GH-448 (shared driver-lock resolver: bash/python parity + linked-worktree LIVE, real worktree fixture; negative control: pre-fix 2-branch logic misses the lock)
   156	  "gh376-relay-drive-lock-parity.sh" # GH-376 (the DRIVER-side half of #448: relay-drive's own two twins
   157	                                 #   now resolve the lock through that shared resolver, so a relay driver
   158	                                 #   and a marathon driver actually exclude from a linked worktree — the
   159	                                 #   thing marathon-drive.sh:195-196 already claimed in prose) — 18/0.
   160	                                 #   Observable is "does it REFUSE against a lock held at marathon-drive's
   161	                                 #   path", run end-to-end through the real scripts against a real
   162	                                 #   `git worktree add`; the drivers never print the path and the EXIT
   163	                                 #   trap removes the lock, so no filesystem probe can see it.
   164	                                 #   Controls: pre-fix resolution replayed on BOTH lanes sails past the
   165	                                 #   held lock; normal-clone and vendored (no .git) cases unchanged;
   166	                                 #   source guards pin that the resolver is CALLED, never re-inlined.
   167	  "gh397-reviewer-turn-role.sh"  # GH-397 (reviewer scope derived from the tick token + role directive, not agent-maintained NEXT:) — 11/0; control: pre-fix red on the un-flipped-NEXT case
   168	  "gh401-dry-run-no-mutation.sh" # GH-401 (--dry-run writes nothing; render goes to stdout) — 4/0; control: pre-fix red on directory creation. Static half: marathon-root-audit.sh
   169	  "gh375-agy-auth-preflight.sh"  # GH-375 (agy whoami exits 0 without a TTY, so output decides) — 14/0; controls: 5 legitimate auth outputs containing "error" must NOT be rejected
   170	  "gh375-auth-timeout-verdict.sh" # GH-375 follow-up (a timed-out probe is reclassified ONLY on positive evidence of the TTY cause; silence and a login prompt stay fatal) — 11/0; control: pre-fix replay of BOTH callers blocks the TTY-diagnosed timeout, and each replay is compile-checked
   171	  "gh385-retry-token-satisfied.sh" # GH-385 (a phase completed on a --retry suffixed token is satisfied) + GH-491 (--retry on an already-satisfied lane says a plain re-fire would have been gate-only) — 19/0; controls: un-completed recorded token must still rebuild; GH-491 advisory must NOT fire when the recorded token is not done, and must not change --retry's behaviour
   172	  "gh408-tick-failure-visibility.sh" # GH-408 + GH-409 P1 (a failed `tick claim` is detectable by exit status AND readable in the output, at both discard sites) — 22/0; control recorded in test/baselines/GH-408-negative-control.md: 12 red pre-fix. Guards the two directions a naive fix breaks: an idempotent re-claim by the holder must stay exit 0, and a successful tick call must stay silent
   173	  "nightwatch-release.sh"        # Nightwatch 0.3.0 frozen-manifest goalpost. Suite mode fails ONLY on a false completion claim (a CLOSED manifest issue whose gate is missing/unregistered/uncontrolled) or a disagreement with RELEASES.md; remaining work is INFO. The goalpost itself is `--release-gate` (red until done, and it EXECUTES the lifecycle suites rather than auditing them). Control: `--mutate-evidence` 34/0 — NOT run by this suite; run it by hand when touching audit_manifest
   174	  "gh378-gate-requires-green-suite.sh" # GH-378 (pre-advance gate baseline allowance for non-green suites)
   175	  "gh379-claude-builder-diagnosis.sh" # GH-379 (Claude builder failure diagnostics surface in ESCALATION.md)
   176	  "gh380-claude-trust.sh"        # GH-380 (Claude builder warns when target workspace lacks Claude Code trust)
   177	  "gh382-marathon-memory-telemetry.sh" # GH-382 (marathon memory telemetry sampled at phase boundaries and end-of-run)
   178	  "gh491-gate-only-refire.sh"    # GH-491 (gate-only re-fire discoverability under --retry)
   179	  "gh551-resolver-refuses.sh"    # GH-551 (resolver refusal contract: raises instead of defaulting)
   180	  "meter-release.sh"             # Meter 0.6.0 PUBLIC-LAUNCH goalpost (RE-POINTED 2026-08-15; the metering manifest moved to Sundown). Suite mode fails ONLY on a false completion claim (a CLOSED manifest issue whose gate is missing/unregistered/uncontrolled) or a ledger disagreement; remaining work is INFO. The goalpost itself is `--release-gate` (red until the sanitized artifact exists AND a credential-free clone completes the documented happy path; the artifact is named by XYZ_LAUNCH_ARTIFACT). Membership is read from RELEASES.md's machine-readable `Manifest-Members:` field and compared in BOTH directions — the prose `Manifest:` paragraph names RETIRED members and must never be parsed, which is the defect that made the pre-2026-08-15 version report a false GOALPOST MET. Control: `--mutate-evidence` — NOT run by this suite; run it by hand when touching audit_artifact or the cross-check
     1	---
     2	title: "GH-50: sandboxed git --track / branch -D half-applies — working tree rewritten, .git/config write fails, HEAD left behind"
     3	status: Complete
     4	created: 2026-08-22
     5	updated: 2026-08-24
     6	owner: orchestrator (Claude Code)
     7	goal: make branch operations refuse-or-succeed atomically under a sandbox that blocks .git/config writes, so a half-applied switch can never overwrite uncommitted work
     8	gh_issue: 50
     9	source: https://github.com/HiQS-Suite/XYZ-forge/issues/50
    10	branch: gh-50/sandboxed-git-half-apply
    11	doc_type: bugfix
    12	effort: 1
    13	complexity: 1
    14	risk: 1
    15	---
    16	
    17	# GH-50 — sandboxed git switch half-applies and loses uncommitted work
    18	
    19	## Status
    20	
    21	| What was just completed | What's next |
    22	|---|---|
    23	| capture doc + preflight contract written (ready, exit 0); queued as Bulkhead wave 3 (2026-08-22, release 0.7.3 "Bulkhead", #179) | Operator fires the marathon lane per MARATHON-PLAN-2026-08-23.md; builder executes ## Plan, reviewer verifies ## Acceptance |
    24	
    25	
    26	Release 0.7.3 "Bulkhead" manifest member. Radar 2026-08-22: data-loss class.
    27	
    28	## Bug
    29	
    30	Inside a sandbox that blocks `.git/config` writes, `git switch --track` updates the index and
    31	working tree, then fails the config write and leaves HEAD behind — the tree holds another
    32	branch's content while HEAD points at the old branch. An uncommitted modification to
    33	`test/ballast-release.sh` was overwritten and lost this way. The fatal line
    34	(`error: could not lock config file .git/config: Operation not permitted`) is easy to truncate
    35	away; the visible symptom is only a misleading upstream hint.
    36	
    37	## Plan
    38	
    39	1. `utils/git-sandbox-guard.sh` (new): a preflight primitive that probes `.git/config`
    40	   writability and refuses tracking/branch-mutation operations up front with a named error,
    41	   for harness scripts that switch branches (relay/marathon drivers).
    42	2. Adopt the guard at the harness call sites that perform `switch --track` / `branch -D`.
    43	3. `test/gh50-sandboxed-git-guard.sh`: simulate a read-only `.git/config` and assert the guard
    44	   refuses before any tree mutation; register in validate.sh TESTS.
    45	4. AGENTS.md: one-paragraph note naming the failure shape (do not truncate git stderr on
    46	   branch operations).
    47	
    48	## Acceptance
    49	
    50	- [ ] With `.git/config` unwritable, a guarded `switch --track` refuses with a named error before any tree mutation.
    51	- [ ] The working tree is byte-identical to its pre-attempt state after the refusal.
    52	- [ ] `test/gh50-sandboxed-git-guard.sh` green and registered in validate.sh.
    53	
    54	## Swarm Preflight Contract
    55	
    56	```json
    57	{
    58	  "target":        { "repo": ".", "ref": "development" },
    59	  "gate":          "bash validate.sh",
    60	  "fix_probes":    [ { "type": "path_absent", "path": "utils/git-sandbox-guard.sh" },
    61	                     { "type": "path_absent", "path": "test/gh50-sandboxed-git-guard.sh" } ],
    62	  "artifacts":     [ "utils/git-sandbox-guard.sh", "test/gh50-sandboxed-git-guard.sh", "AGENTS.md", "validate.sh" ],
    63	  "artifacts_new": [ "utils/git-sandbox-guard.sh", "test/gh50-sandboxed-git-guard.sh" ],
    64	  "remediation":   { "source": "self#plan", "criteria": "guarded branch ops refuse-or-succeed atomically when .git/config is unwritable; no tree mutation on refusal; gh50 suite green" },
    65	  "lanes":         { "agy_safe": [ "utils/git-sandbox-guard.sh", "test/gh50-sandboxed-git-guard.sh" ], "orchestrator_only": [ "AGENTS.md" ] }
    66	}
    67	```
    68	
    69	## Lessons Learned (For Future Agents)
    70	
    71	- A sandboxed `git switch --track` HALF-APPLIES: index and working tree move, the `.git/config`
    72	  write fails, HEAD stays behind — the tree silently holds another branch's content. Probe
    73	  `.git/config` writability BEFORE any branch mutation (`utils/git-sandbox-guard.sh`), not after.
    74	- The fatal line (`could not lock config file .git/config`) is easy to truncate away; never trim
    75	  git stderr on branch operations — the visible symptom without it is a misleading upstream hint.
    76	- The suite simulates a read-only `.git/config` and asserts refusal happens before any tree
    77	  mutation (byte-identical tree after), which is the property that actually protects uncommitted work.
     1	---
     2	title: Lane brief — GH-50: guard sandboxed git branch mutations before they half-apply
     3	status: Active (2-WORKING)
     4	created: 2026-08-24
     5	updated: 2026-08-24
     6	owner: noel
     7	branch: development
     8	doc_type: project
     9	roadmap_exempt: true
    10	goal: >
    11	  Lane brief for marathon phase gh50-sandboxed-git-guard.
    12	---
    13	
    14	# Lane brief — GH-50: guard sandboxed git branch mutations before they half-apply
    15	
    16	## Status
    17	
    18	| What was just completed | What's next |
    19	|---|---|
    20	| Brief authored. | Phase execution. |
    21	
    22	Execution surface of record: `PROJECT/2-WORKING/GH-50-SANDBOXED-GIT-HALF-APPLY.md`
    23	(issue: https://github.com/HiQS-Suite/XYZ-forge/issues/50)
    24	
    25	## Task
    26	
    27	Inside a sandbox that blocks `.git/config` writes, `git switch --track` updates the index and
    28	working tree, then fails the config write and leaves HEAD behind — the tree holds another
    29	branch's content while HEAD points at the old branch (an uncommitted modification to
    30	`test/ballast-release.sh` was lost this way). The fatal line
    31	(`error: could not lock config file .git/config: Operation not permitted`) is easy to
    32	truncate away; the visible symptom is only a misleading upstream hint.
    33	
    34	1. `utils/git-sandbox-guard.sh` (new): a preflight primitive that probes `.git/config`
    35	   writability and refuses tracking/branch-mutation operations up front with a named error,
    36	   for harness scripts that switch branches (relay/marathon drivers).
    37	2. Adopt the guard at the harness call sites that perform `switch --track` / `branch -D`.
    38	3. `test/gh50-sandboxed-git-guard.sh` (new): simulate a read-only `.git/config` and assert the
    39	   guard refuses before any tree mutation; register in validate.sh TESTS.
    40	4. `AGENTS.md`: one-paragraph note naming the failure shape (do not truncate git stderr on
    41	   branch operations).
    42	
    43	## Definition of done
    44	
    45	- With `.git/config` unwritable, a guarded `switch --track` refuses with a named error before
    46	  any tree mutation.
    47	- The working tree is byte-identical to its pre-attempt state after the refusal.
    48	- `test/gh50-sandboxed-git-guard.sh` green and registered in validate.sh.
    49	- `bash validate.sh` green.

2026-08-26T03:35:43.641306Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
codex
The key distinction is clear: both tests infer “unwritable” from mode bits, while the production tools correctly test the capability of the process that actually runs them. Under root, those are different facts.
exec
/bin/zsh -lc "nl -ba .github/workflows/ci.yml | sed -n '76,96p' && nl -ba AGENTS.md | sed -n '148,162p' && rg -n 'git-sandbox-guard\\.sh' --glob '"'!utils/git-sandbox-guard.sh'"' --glob '"'!test/gh50-sandboxed-git-guard.sh'"' --glob '"'!AGENTS.md'"' --glob '"'!PROJECT/**'"' --glob '"'!CHANGELOG.md'"' --glob '"'!ROADMAP.md'"' --glob '"'!releases.sql'"' --glob '"'!marathon-system/**'"' --glob '"'!temp/**'"' --glob '"'!relay-system/**'"' . || true" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z
 succeeded in 0ms:
    76	# GH-544 deliberately removed `push:` and `pull_request:` while the source repository was private.
    77	# That bridge had one explicit end condition: the repository becomes public. HiQS-Suite/XYZ-forge
    78	# is public, so automatic triggers are restored here. The local pre-push gate remains useful as the
    79	# earliest signal; hosted CI restores independent attestation and the Linux portability canary.
    80	#
    81	# WHY: measured in #509/#528 — Aug 1-14 cost $21.99 gross / $10.00 billed, exhausting the 2,000
    82	# included minutes on Aug 11 and hitting the $10 spending limit on Aug 14, which blocked Actions
    83	# outright. Projection at that cadence was ~$47/mo gross. We do not pay that for an internal tool.
    84	#
    85	# THE BRIDGE HAS ENDED. The re-arm keeps the constraints the private-phase analysis established:
    86	#   1. `push:` and `pull_request:` cover main and development. The macOS job itself remains guarded
    87	#      to a push on main; pull requests receive only the Ubuntu portability canary.
    88	#   2. Expect a BATCH of accumulated Linux portability drift on the first green-field run. The local
    89	#      gate is macOS, so the platform we ship to stayed covered — the ubuntu canary did not, and drift
    90	#      has been accumulating unreported since this date. That backlog is the known, accepted cost of
    91	#      this decision, not a surprise.
    92	#   3. The GH-509 macOS boundary is again the promotion witness for an exact main commit.
    93	#
    94	# EVERYTHING BELOW IS DELIBERATELY PRESERVED — jobs, routing, and especially the GH-509 Phase 4 cost
    95	# analysis in the macOS job's header. That reasoning is what you will want when re-arming; deleting it
    96	# and rediscovering it on an invoice is the failure this comment exists to prevent.
   148	
   149	  To undo your own experiment, copy the file first (`cp f f.bak`) and restore from that. The
   150	  blast radius is **tracked** modifications; untracked files survive. `relay-automation/hooks/gh527-destructive-git-guard.sh`
   151	  snapshots the doomed tracked files into `.tick/orphan-backups/` before the command runs, so
   152	  this is recoverable rather than prevented — the snapshot is a net, not permission to swing.
   153	- **Preflight sandboxed branch mutations (GH-50).** A sandbox may let `git switch --track` rewrite
   154	  the index and working tree, then deny the `.git/config` lock and leave HEAD on the old branch.
   155	  Before a harness runs a tracking switch or destructive branch mutation such as `git branch -D`,
   156	  wrap the complete command with `utils/git-sandbox-guard.sh --repo <root> -- <git command>` so it
   157	  refuses before mutation when the config cannot be written. Never truncate git stderr for branch
   158	  operations: the decisive `could not lock config file` line can otherwise disappear behind an
   159	  unrelated upstream hint.
   160	- `ROUTER.md` owns startup order, canonical files, command rails, and the issue-first SOP.
   161	- `GUIDING-PRINCIPLES.md` owns the product/runtime priorities: local event-log coordination,
   162	  containment, skill-first relay work, durable fixes, and verified done.

2026-08-26T03:36:50.750769Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
codex
ANSWER: Pick **B, strengthened as a hybrid**: do not change production behavior for root; skip the mode-bit negative cases under EUID 0, preferably re-running those fixtures as an unprivileged user when the runner supports it. Root can genuinely write/read these files, so Option A would make correct root behavior look unsafe.

FINDINGS

- [Blocker] Option A corrupts both tools’ contracts. The git guard tests whether the *executing process* can append the config and create/remove `config.lock`; root can, and Git run as root can too. Treating `0444` as refusal would create a false block for root-run containers/CI. [utils/git-sandbox-guard.sh:66](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z/utils/git-sandbox-guard.sh:66) The scanner likewise intentionally reports only real `grep` errors (`>1`), not restrictive-looking mode bits; root successfully scanning `0000` is correct. [security-scan.sh:168](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z/relay-automation/hooks/security-scan.sh:168)

- [Should] Make the tests EUID-aware, not the production guards. The GH-50 suite’s `chmod a-w` assertion block is invalid under root. [gh50-sandboxed-git-guard.sh:55](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z/test/gh50-sandboxed-git-guard.sh:55) The scanner’s unreadable-file regression similarly relies on `chmod 000`. [security-scan.sh:235](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z/test/security-scan.sh:235) On root CI, run just these negative fixtures as a disposable unprivileged UID (after arranging fixture ownership/traversal); otherwise emit a named `SKIP (EUID=0: chmod cannot create unreadability)`. Keep the writable-control and all other security tests active.

- [Should] A plain skip loses the very regression coverage the tests were added for. The hybrid retains it on root Linux when privilege-dropping is available, while making the fallback limitation explicit. Skipping entire suites would be needless and would hide unrelated regressions.

- [Should] The permanent-red state is worse than either correction: the workflow deliberately turns any suite failure into advisory “drift,” so a known red baseline masks a new Linux failure. [ci.yml:446](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z/.github/workflows/ci.yml:446) The unrelated `agy`, worktree, and lock failures do not change this choice, but they must be separately fixed or explicitly skipped before “green again” is a truthful claim.

- [Should] The guard is not currently wired to a production call site in this checkout: repository search finds its implementation/test/docs, while the repo policy says harness branch mutations must wrap calls with it. [AGENTS.md:153](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z/AGENTS.md:153) That makes changing its root semantics especially unjustified; first adopt it at the intended driver call sites, then test its actual capability contract.

- [Pass] Keep Ubuntu advisory for now. The repository explicitly ships macOS, uses Ubuntu only for drift detection, and reserves macOS for promotion evidence. [ci.yml:210](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z/.github/workflows/ci.yml:210) A green advisory canary is useful; making it required would redefine unsupported-Linux drift as product breakage. Revisit “required” only when Linux is a supported target, not merely because this baseline is repaired.

RECOMMENDATION: Implement EUID-0-aware test handling with an unprivileged-fixture path plus explicit fallback SKIPs; leave both production guards capability-based and keep the Ubuntu job advisory until Linux support is an actual product commitment.
tokens used
90,827
ANSWER: Pick **B, strengthened as a hybrid**: do not change production behavior for root; skip the mode-bit negative cases under EUID 0, preferably re-running those fixtures as an unprivileged user when the runner supports it. Root can genuinely write/read these files, so Option A would make correct root behavior look unsafe.

FINDINGS

- [Blocker] Option A corrupts both tools’ contracts. The git guard tests whether the *executing process* can append the config and create/remove `config.lock`; root can, and Git run as root can too. Treating `0444` as refusal would create a false block for root-run containers/CI. [utils/git-sandbox-guard.sh:66](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z/utils/git-sandbox-guard.sh:66) The scanner likewise intentionally reports only real `grep` errors (`>1`), not restrictive-looking mode bits; root successfully scanning `0000` is correct. [security-scan.sh:168](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z/relay-automation/hooks/security-scan.sh:168)

- [Should] Make the tests EUID-aware, not the production guards. The GH-50 suite’s `chmod a-w` assertion block is invalid under root. [gh50-sandboxed-git-guard.sh:55](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z/test/gh50-sandboxed-git-guard.sh:55) The scanner’s unreadable-file regression similarly relies on `chmod 000`. [security-scan.sh:235](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z/test/security-scan.sh:235) On root CI, run just these negative fixtures as a disposable unprivileged UID (after arranging fixture ownership/traversal); otherwise emit a named `SKIP (EUID=0: chmod cannot create unreadability)`. Keep the writable-control and all other security tests active.

- [Should] A plain skip loses the very regression coverage the tests were added for. The hybrid retains it on root Linux when privilege-dropping is available, while making the fallback limitation explicit. Skipping entire suites would be needless and would hide unrelated regressions.

- [Should] The permanent-red state is worse than either correction: the workflow deliberately turns any suite failure into advisory “drift,” so a known red baseline masks a new Linux failure. [ci.yml:446](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z/.github/workflows/ci.yml:446) The unrelated `agy`, worktree, and lock failures do not change this choice, but they must be separately fixed or explicitly skipped before “green again” is a truthful claim.

- [Should] The guard is not currently wired to a production call site in this checkout: repository search finds its implementation/test/docs, while the repo policy says harness branch mutations must wrap calls with it. [AGENTS.md:153](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z/AGENTS.md:153) That makes changing its root semantics especially unjustified; first adopt it at the intended driver call sites, then test its actual capability contract.

- [Pass] Keep Ubuntu advisory for now. The repository explicitly ships macOS, uses Ubuntu only for drift detection, and reserves macOS for promotion evidence. [ci.yml:210](/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-50267-ew391e0z/.github/workflows/ci.yml:210) A green advisory canary is useful; making it required would redefine unsupported-Linux drift as product breakage. Revisit “required” only when Linux is a supported target, not merely because this baseline is repaired.

RECOMMENDATION: Implement EUID-0-aware test handling with an unprivileged-fixture path plus explicit fallback SKIPs; leave both production guards capability-based and keep the Ubuntu job advisory until Linux support is an actual product commitment.
