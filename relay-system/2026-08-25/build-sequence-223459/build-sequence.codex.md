**SINGLE-MODEL — NOT RECONCILED** (only codex answered; 1 of 2 requested advisor(s) failed — this is one model's read, not a cross-model consult. Do not treat any claim below as cross-verified.)

**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.6-terra
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
2026-08-26T05:35:00.282697Z ERROR codex_models_manager::cache: failed to load models cache: missing field `base_instructions` at line 98 column 5
OpenAI Codex v0.144.6
--------
workdir: /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-30948-51ksahqx
model: gpt-5.6-terra
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 01a03c90-8a17-7d12-8800-9eeec34f1a7e
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Question

Sequence the next THREE releases for this repo, using the RELEASES DB as the planning source of
truth. ADVISORY ONLY — do not modify anything. Read `releases.db` via
`python3 utils/py/releases_app.py list` / `show --gid <gid>`, plus `LEADERBOARD.md`, `ROADMAP.md`,
and `RELEASES.md`.

## Current state

Shipped: 0.1.0 Quicksilver, 0.2.0 Litmus, 0.3.0 Nightwatch, 0.7.0 Ballast, 0.7.1 Bulwark,
0.7.2 Daybreak, 0.7.3 Bulkhead.

ACTIVE: **0.7.4 Linux-RC** (target 2026-09-05, 7 items; #204 #205 #123 #232 #233 dialed in,
#226 #228 shipped). Exit criterion: a 100% green hosted Ubuntu CI run on Linux-MVP-RC.

DRAFTS, all with **zero manifest items** and targets that do not follow their version order:
- 0.4.0 **Plumbline** (target 2026-11-14) — assisted reflection + a bounded self-improvement loop, measured before trusted
- 0.5.0 **Lantern** (target 2026-12-12) — diagnosability: make the harness say what it already knows. Gate `test/lantern-release.sh` NOT BUILT
- 0.6.0 **Meter** (target 2026-09-26) — a stranger can clone and reach a documented happy path unauthenticated. Gate `test/meter-release.sh` NOT BUILT
- 0.8.0 **Sundown** (target 2026-10-17) — retire the twelve frozen Bash twins. Exit criterion NOT WRITTEN

DRAFT with items: 0.9.0 **Cargo** (target 2026-09-19, 7 items) — the harness travels with its
ledger; releases DB + timeline generator ship inside every vendored `.xyz/`.

## Highest-scoring work with NO release assigned (calc = pri+sev+appeal+effort, 4–400, higher better)

- 325 **#249** ubuntu portability canary permanently red — EUID=0 defeats chmod-based assertions
- 285 **#141** make Fuzzing and ATE actually useful (Phases 1–…)
- 283 **#67** Commandcode builder default widened to `--yolo`
- 280 **#216** marathon-plan.sh ledger parser rejects link-style ROADMAP bullets — reconciler never sees them
- 270 **#75** single-page HTML dashboard for releases
- 257 **#215** vendored `.xyz/` reconciler hardcodes paths
- 250 **#243** GH-169 items 3–4: repoint agent docs + dashboard-staleness push guard
- plus two just filed: **#251** validate.sh reports pytest-absent as FAILED; **#252** `hq park` emits no rated token so the documented intake path cannot score

## What I am inclined to do (challenge this)

1. Insert a new **0.7.5** immediately after Linux-RC for CI signal health: #249, #251, and the three
   other unrelated failures in the same canary job (`agy` not on PATH, worktree-isolation case 2,
   concurrent-lock race). Rationale: #249 is the #2 item on the whole leaderboard, and while that
   job is red nobody can trust any Linux result — including 0.7.4's own exit criterion.
2. Then **0.9.0 Cargo** (already themed and populated).
3. Then repurpose **0.8.0** into ledger/intake integrity: #252, #216, #243, #215, #222.

## Questions

1. Is inserting 0.7.5 right, or should #249/#251 fold into 0.7.4 itself, given 0.7.4's exit
   criterion is *"a 100% green hosted Ubuntu CI run"* — which the red canary arguably already
   blocks? Argue from the exit criterion as written.
2. Three of the four empty drafts (Lantern, Meter, Sundown) say their release GATE IS NOT BUILT,
   and note that writing the gate first is the ordering Litmus and Nightwatch both used. Does that
   ordering rule mean none of those three can be scheduled next? What is the cheapest honest way to
   respect it?
3. Is repurposing 0.8.0 Sundown (retire the Bash twins) into a ledger-integrity release a mistake?
   It has a real, distinct theme. Better to leave Sundown alone and create a new version for the
   ledger work — and if so, what number, given 0.9.0 is taken and the version/target ordering is
   already inconsistent?
4. Version numbering and targets are incoherent (0.6.0 targets 2026-09-26 but 0.5.0 targets
   2026-12-12; 0.9.0 targets 2026-09-19, before both). Should the next three be renumbered/retargeted
   into a consistent sequence, or is churning version numbers in a shipped-history ledger worse than
   the inconsistency? Recommend one.
5. Are the codenames worth changing? Renaming is permitted. Say so only if a rename buys real
   clarity, not because a new name sounds better.
6. What is MISSING from my plan — work that outranks something I scheduled, a dependency I have
   inverted, or a release that should be cut entirely rather than carried?

Grade findings [Blocker]/[Should]/[Nit] and cite `file:line` or the exact CLI output you relied on.

hook: SessionStart
hook: SessionStart Completed
codex
I’ll inspect the ledger and the referenced release/roadmap evidence, then give an independent sequencing recommendation grounded in the stated exit criteria.
exec
/bin/zsh -lc "pwd && sed -n '1,240p' WORKTREE-SAFETY.md && sed -n '1,260p' ROUTER.md && sed -n '1,220p' GUIDING-PRINCIPLES.md" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-30948-51ksahqx
 succeeded in 0ms:
/private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-30948-51ksahqx
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

exec
/bin/zsh -lc 'python3 utils/py/releases_app.py list
python3 utils/py/releases_app.py show --gid 0.7.4
python3 utils/py/releases_app.py show --gid 0.9.0
python3 utils/py/releases_app.py show --gid 0.4.0
python3 utils/py/releases_app.py show --gid 0.5.0
python3 utils/py/releases_app.py show --gid 0.6.0
python3 utils/py/releases_app.py show --gid 0.8.0' in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-30948-51ksahqx
exec
/bin/zsh -lc "python3 utils/py/releases_app.py show --help
python3 utils/py/releases_app.py show --gid rel-01M0V6GTR1A4GX40D9CADEQA59
python3 utils/py/releases_app.py show --gid rel-01M0GKP4YGTHVTXHVV5WAP08B5
sed -n '1,260p' RELEASES.md
sed -n '1,260p' LEADERBOARD.md
sed -n '1,180p' ROADMAP.md" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-30948-51ksahqx
 succeeded in 12774ms:
2026-08-25 22:35:34.073 xcodebuild[31257:7651235]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:34.262 xcodebuild[31257:7651234] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-JAjRNsa2' (errno=Operation not permitted)
2026-08-25 22:35:34.902 xcodebuild[31262:7651268]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:35.098 xcodebuild[31262:7651267] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
usage: releases show [-h] [--gid GID] [--version VERSION] [--full]

optional arguments:
  -h, --help         show this help message and exit
  --gid GID
  --version VERSION
  --full             print long values verbatim (default elides them at 240
                     chars)
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-HsexzPzy' (errno=Operation not permitted)
2026-08-25 22:35:36.629 xcodebuild[31274:7651342]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:36.827 xcodebuild[31274:7651341] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-1z3CWuKb' (errno=Operation not permitted)
2026-08-25 22:35:37.460 xcodebuild[31279:7651366]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:37.653 xcodebuild[31279:7651365] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
GID:           rel-01M0V6GTR1A4GX40D9CADEQA59
Release:       0.7.4
Status:        active
Codename:      Linux-RC
Target Date:   2026-09-05
Milestone:     Linux MVP RC
Description:   Linux MVP release candidate: portability blockers cleared, hosted Ubuntu CI attestation on branch Linux-MVP-RC
Exit criterion: All #224 checklist items closed or waived; qualifying 100% green hosted Ubuntu CI run on Linux-MVP-RC
Tracking:      https://github.com/HiQS-Labs/XYZ-forge/issues/224
Manifest:      7 item(s)
  - https://github.com/HiQS-Labs/XYZ-forge/issues/204 [dialed_in]
  - https://github.com/HiQS-Labs/XYZ-forge/issues/205 [dialed_in]
  - https://github.com/HiQS-Labs/XYZ-forge/issues/123 [dialed_in]
  - https://github.com/HiQS-Labs/XYZ-forge/issues/226 [shipped]
  - https://github.com/HiQS-Labs/XYZ-forge/issues/228 [shipped]
  - https://github.com/HiQS-Labs/XYZ-forge/issues/232 [dialed_in]
  - https://github.com/HiQS-Labs/XYZ-forge/issues/233 [dialed_in]
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-xQeWkw7y' (errno=Operation not permitted)
2026-08-25 22:35:41.743 xcodebuild[31311:7651607]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:41.937 xcodebuild[31311:7651605] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-65YaLXaN' (errno=Operation not permitted)
2026-08-25 22:35:42.579 xcodebuild[31316:7651630]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:42.784 xcodebuild[31316:7651626] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
GID:           rel-01M0GKP4YGTHVTXHVV5WAP08B5
Release:       0.9.0
Status:        draft
Codename:      Cargo
Target Date:   2026-09-19
Milestone:     Cargo
Description:   The harness travels with its ledger: the RELEASES DB system (releases_app.py CLI + merge resolver + FAQs) and the GH-103 HTML timeline generator (utils/timeline/) ship inside every vendored .xyz/ payload as an optional, never-wired-by-defau… (448 chars total; --full to print it all)
Exit criterion: A repo vendored with xyz-vendor.sh can, with zero extra downloads, run releases init/add and export_timeline.py --preview from .xyz/ against its own root, and xyz-sync.sh update preserves the target's ledger state (GH-312 preserve list). No… (277 chars total; --full to print it all)
Tracking:      https://github.com/HiQS-Suite/XYZ-forge/issues/105
Manifest:      7 item(s)
  - https://github.com/HiQS-Suite/XYZ-forge/issues/105 [dialed_in]
  - https://github.com/HiQS-Suite/XYZ-forge/issues/107 [dialed_in]
  - https://github.com/HiQS-Labs/XYZ-forge/issues/201 [dialed_in]
  - https://github.com/HiQS-Labs/XYZ-forge/issues/182 [dialed_in]
  - https://github.com/HiQS-Labs/XYZ-forge/issues/193 [dialed_in]
  - https://github.com/HiQS-Labs/XYZ-forge/issues/222 [dialed_in]
  - https://github.com/HiQS-Labs/XYZ-forge/issues/223 [dialed_in]
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
a manifest of DIALED-IN work and a testable exit criterion, both recorded in the blocks below. "The
open issues are done" is not an exit criterion, because working on a release generates more of them.

**Membership is dialed in, not frozen (2026-08-20, GH-111).** A task — and by extension a marathon —
is dialed into exactly one release at a time, recorded as a state in `releases.db` rather than as a
sentence someone remembered to write. Dialing a task in requires a reason, exactly as cutting one
does: deliberateness comes from every commitment stating its case, not from a ceremony that makes
*changing* the commitment expensive. What a freeze used to buy — a fixed denominator, so "N of M" was
an honest figure — is now bought by the release's BASELINE: the count of what it was committed to at
kickoff. Progress is measured against the live manifest, and growth against that baseline, so scope
creep is a measured fact instead of something forbidden and then worked around.

**Releases that shipped before 2026-08-20 used the freeze model, and their blocks still say so.**
Those `Manifest: FROZEN …` lines are the historical record of how those releases were actually run;
rewriting them would be a silent history edit. (Unrelated: "frozen Bash twins" elsewhere in this repo
means GH-308's Python-authoritative rule and has nothing to do with manifests.)

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
Manifest: DIALED IN at one issue on creation — #499, which supersedes and closes #494, #495, #496 and #498. Four phases, each shippable alone: relay-drive launch preflight; a gate refusal that states its real reason; a launcher whose exit code survives plus a gate-readiness check; and a change-impact reporter. Freezing at one is the whole point — these were filed as four and unified precisely to stop a single coherent change spreading across four PRs. **RE-FROZEN AT TWO on 2026-08-11 by explicit operator decision — #499, plus #358 Phase 2.** Recorded as a re-scope rather than an edit, because the admission rule below is worthless if a manifest can grow quietly: the operator named the entry and the release, which is the documented way past the rule, and this line says so with a date instead of just showing two items where there was one. It is a genuine fit, not a parking space — Phase 2 is a *disposition* that turns a lost concurrent-append record into a failure naming its own terminal lock state, which is Lantern's subject exactly, whereas the run lifecycle it sits inside was already handled correctly (that is the Nightwatch boundary, and it is why Phase 1 belonged there and Phase 2 does not). It was briefly a Meter member the same day and moved here before either release started; Meter's block records the move from its side. **#358 keeps its Nightwatch milestone** — it is a frozen entry counted in Nightwatch's RC evidence, so only its scope moved, and this is the second Lantern member not enumerable by `gh issue list --milestone Lantern`. Adding a further member is a RE-SCOPE, not a bugfix, per the Litmus rule above.
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
Description: **XYZ can be handed to a stranger.** An unauthenticated clone reaches a documented entry path and exercises a supported happy path with no private context, from a tree that has been sanitized and secret-scanned. **RE-SCOPED 2026-08-15 by explicit operator decision** — Meter was originally the metering release ("a run accounts for what it spends and checks what it requires before spending it"; members #378 #379 #380 #382 #491, found by a real unattended marathon against rebalance-OS); that work moved intact to Sundown (0.8.0) and publication took the slot, because it is the next thing that happens to this repository and the operator named it. Recorded as a dated re-scope — a codename that quietly changes its subject is the same defect as a manifest that quietly grows. (This block was COMPACTED 2026-08-20 by operator request; the full prose of every paragraph below is in this file's git history.)
Publication target: **the deliverable is a sanitized clone, not this repository** — fresh history, single initial commit, pushed to **https://github.com/HiQS-Suite/XYZ-forge** (new org, named by the operator 2026-08-15, XYZ's permanent home). `CHANGELOG.md` carried forward verbatim as the public record; carrying the 2,147-commit history was rejected 2026-08-15 because a full-history secret scan would have to scan everything ever deleted — fresh history makes sanitization complete by construction. `.tick/` (161 MB) and `relay-system/` (32 MB) do not ship; `PROJECT/` ships as an empty PDDA scaffold plus the Meter build docs retained as a worked example — the method travels, the backlog does not.
Scope boundary — Meter vs Lantern: **Lantern owns how a failure is described; Meter owns what a run consumed and what it required.** Route by whether the issue names a *resource or precondition* (dollars, turns, memory, a trusted directory, a green suite) or *the wording of a verdict whose handling was already correct*. #379 splits across both by that rule (overloaded exit 5 → Lantern; the budget itself → Meter). #491 sits here deliberately: the violated invariant is re-spending paid turns already held, and its evidence is a cost measurement.
Exit criterion: `bash test/meter-release.sh --release-gate` exits 0. **NOT BUILT — writing it is Meter's first task, before any sanitization** (the Litmus/Nightwatch ordering). Two halves, re-pointed at launch with the 2026-08-15 re-scope (command and shape unchanged). **Half A AUDITS the launch artifact:** sanitized clone at the declared path with exactly one commit; `CHANGELOG.md` byte-identical to this repository's; `.tick/`, `relay-system/`, `temp/` absent; `PROJECT/` = PDDA scaffold + retained Meter example only; both LICENSE files present and consistent; secret-scan result names its tool version and exact commit. **Half B EXECUTES the stranger's path:** a credential-less clone of the published commit reaches the documented entry point and completes one supported happy path with nothing that exists only on the author's machine. Negative control `--mutate-evidence` (fixture copy): plant a private path in a tracked file, remove `CHANGELOG.md`, leave a `relay-system/` behind — detect all three, re-check unmutated inputs green in the same run. RED on arrival.
Manifest: **DIALED IN at TWO — #555 and #563.** #555 is the release's own exit criterion (ships first, arrives RED). #563 is the launch checklist authored by an external reviewer (Codex Sol High): release boundary, public onboarding and behavior, secret/privacy review, legal/CI/publication sequence — frozen whole per the Plumbline precedent (one coherent cutover, not split across issues). **Scope CLOSED to further admission by explicit operator instruction 2026-08-15** — the standing admission rule is superseded for this release only; anything discovered during execution is filed to Sundown or left unmilestoned and **waived in writing per #563's rule (a waiver names the failed criterion, owner, reason and follow-up — silence is not a waiver).** Known open items under that rule, each needing a fix or waiver before the gate is called green: **#564** (31 unaudited suites can reach the caller's clone through an empty fixture path) and **#544's re-arm debt** (hosted CI fires on nothing while private; going public is the documented trigger). **Re-scope ledger, dated** (full prose for each in this file's git history): 2026-08-11 frozen at five on creation (#378 #379 #380 #382 #491); same day #358-P2 briefly a member, moved to Lantern before any work began; 2026-08-12 #509 admitted; 2026-08-14 #509 retired complete (its two unchecked criteria made permanently unwitnessable by GH-544's CI retirement, which owns the debt and the re-arm trigger); 2026-08-14 #551 admitted (shared refuse-don't-default root cause under nine issues) and the target pulled in 2027-01-16 → 2026-09-26 (Nightwatch, the only blocker, had shipped); 2026-08-15 #555 admitted; 2026-08-15 the subject replaced (fifth re-scope) — the seven engineering entries dissolved: #380 CLOSED and shipped under the original scope (stays milestoned Meter as delivered work); #378 #379 #382 #491 #551 moved intact to Sundown (0.8.0) with their capture docs, acceptance criteria and evidence; #546 followed as Sundown backlog (was never a manifest entry).
Manifest-Members: 555 563
GH_URL: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/563
Milestone: Meter
Front-door reviewed: Yes
Shakedown reviewed: Yes
License file: Yes

Release: 0.7.0
Iterations: 0.7.0-0.7.4
Status: Shipped
Shipped: 2026-08-18 — `XYZ_BALLAST_STRANGER_RUNS=10 test/ballast-release.sh --release-gate` → exit 0, manifest 4/4 complete, stranger's path 4/4 passing (B1 10/10 consecutive parallel runs zero failures, B2a in-band ungated warning, B2b forced-red push refusal, B3 atomic event append).
Target Date: 2026-09-12
Codename: Ballast
Description: Post-launch hardening: **the launched repository holds up under a stranger's first run and an outside contributor's first push.** Every member was found the same way — by pointing the launch machinery at its own published output: the first fresh-clone runs of the public repository produced a different failing set each time (#15), a push gate that does not travel with clones got worse the moment the repo went public (#4), and the kernel's own event log can drop events on the concurrent path the kernel exists to coordinate (#14). Ballast exists because publication moved the failure surface from "our machines" to "everyone else's", and nothing in the shipped tree tests that surface. Builds on Meter's publication; depends on nothing unshipped.
Exit criterion: `bash test/ballast-release.sh --release-gate` exits 0. **NOT BUILT — writing it is Ballast's first task, before any member is fixed** (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. **Half A audits the frozen manifest:** each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. **Half B EXECUTES the stranger's path rather than auditing it:** (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. **SHIPPED 2026-08-18.** `XYZ_BALLAST_STRANGER_RUNS=10 test/ballast-release.sh --release-gate` executed for real against a fresh disposable clone (`~/xyz-disposable/xyz-stranger-clone`): exit 0. Half A: 4 of 4 manifest members complete (#14, #15, #4, #3 — gate/registration/control/CLOSED-issue all confirmed). Half B: 4 of 4 passing (B1: 10/10 consecutive parallel runs with zero failures; B2a: ungated clone warning in-band; B2b: forced-red push refusal; B3: atomic-append cross-process stress case clean) — **GOALPOST MET**.
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
Manifest: **#378, #379, #382, #491, #551, #28**, received from Meter 2026-08-15, plus the twin-retirement work described above, which remains unnumbered until its issues are filed. **#28** is the RELEASES.md ledger-discipline fix (parser continuation-folding + advisory bloat checks; see its capture doc for detail), added 2026-08-18 as a post-Ballast follow-up. **#546 is milestone backlog, not a manifest entry** — it followed the metering subject here and does not gate this release, under the standing rule that discovery is not admission. **Not yet frozen.** Freezing requires the twin-retirement issues to exist so the manifest is a fixed denominator rather than a list plus a promise; until then this line is a receipt for the transfer, not a contract. #380 did not move: it is CLOSED and shipped under Meter's original scope, and stays milestoned there.
Exit criterion: **NOT WRITTEN.** Required before this release starts, per the ordering Litmus and Nightwatch both used and Meter is repeating — the gate is built first and arrives RED, because a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one.
GH_URL: pending — api.github.com DNS outage 2026-08-14; file on recovery
Milestone: Sundown
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes

Release: 0.9.0
Iterations: 0.9.0-0.9.4
Status: Draft
Target Date: 2026-09-19
Codename: Cargo
Description: The harness travels with its ledger. The RELEASES DB system (releases_app.py CLI + merge resolver + FAQs) and the GH-103 HTML timeline generator (utils/timeline/) ship inside every vendored `.xyz/` payload as an optional, never-wired-by-default add-on — a "when you're ready" module a target repo enables by running `releases init` itself, matching this file's own OPTIONAL philosophy (GH-381). Sequenced before Meter (0.6.0, 2026-09-26) by explicit operator decision 2026-08-20; version 0.9.0 because every 0.1–0.8 band is reserved — target date, not version number, carries the ordering. Cut through the CLI and mirrored here by hand in the same commit (the GH-32 Phase-0 dual path; no automatic dual writer exists yet).
Exit criterion: A repo vendored with `xyz-vendor.sh` can, with zero extra downloads, run `releases init`/`add` and `export_timeline.py --preview` from `.xyz/` against its own root, and `xyz-sync.sh update` preserves the target's ledger state (GH-312 preserve list). Nothing runs until the user invokes it. NOT BUILT — the gate is authored before any member is fixed, per the Litmus/Nightwatch ordering.
Manifest: DIALED IN 2026-08-20 on creation — #105 (vendor the RELEASES DB + timeline generator into the .xyz payload). RE-SCOPED 2026-08-20 by explicit operator instruction: + #107 (connect /10days, /radar, and PARKED to the RELEASES DB — read-only consumption seams; no new writers). Two entries; no swap; target date held — #107 is additive tooling scoped as quick wins. The standing admission rule remains for anything further: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission.
GH_URL: https://github.com/HiQS-Suite/XYZ-forge/issues/105
Milestone: Cargo
Front-door reviewed: No
Shakedown reviewed: No
License file: Yes
<!-- GENERATED by utils/leaderboard.sh from releases.db — do not hand-edit. -->

# Leaderboard

Every rated task in the ledger, highest first. **Higher is better on every axis**, effort
included — it scores cheapness, not cost, so a 90/90/90/90 item reads as what it is: a
screaming quick win. `calc` is the equal-weighted sum of the four axes (4–400) and is derived,
never stored. `ovr` is the operator override; where it exists it replaces `calc` for ranking,
while the four axes keep their honest values underneath.

| # | score | task | release | lane | pri | sev | appeal | effort | calc | ovr |
|--:|------:|------|---------|------|----:|----:|-------:|-------:|-----:|----:|
| 1 | **340** | [GH-67](https://github.com/HiQS-Suite/XYZ-forge/issues/67) — Commandcode builder default widened to `--yolo` — closer evaluation → possible build | — | Queue / parked intake | 88 | 80 | 45 | 70 | 283 | 340 |
| 2 | **325** | [GH-249](https://github.com/HiQS-Labs/XYZ-forge/issues/249) — ubuntu canary: EUID=0 defeats chmod-based assertions | — | Queue / parked intake | 90 | 85 | 80 | 70 | 325 | — |
| 3 | **315** | [GH-181](https://github.com/HiQS-Labs/XYZ-forge/issues/181) — repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2) | Bulkhead | completed | 90 | 75 | 90 | 60 | 315 | — |
| 4 | **308** | [GH-204](https://github.com/HiQS-Labs/XYZ-forge/issues/204) — BSD `sed -i ''` no-ops on Linux at production call sites | Linux-RC | in progress | 88 | 85 | 70 | 65 | 308 | — |
| 5 | **305** | [GH-202](https://github.com/HiQS-Labs/XYZ-forge/issues/202) — wave_reconcile aborts on marathon-plan exit 5 (items held) and promotes capture docs for OPEN issues | Bulkhead | completed | 85 | 65 | 85 | 70 | 305 | — |
| 6 | **305** | [GH-228](https://github.com/HiQS-Labs/XYZ-forge/issues/228) — Org rename HiQS-Suite → HiQS-Labs: a hardcoded regex silently drops issue URLs from the roadmap shadow | Linux-RC | completed | 80 | 60 | 75 | 90 | 305 | — |
| 7 | **300** | [GH-174](https://github.com/HiQS-Suite/XYZ-forge/issues/174) — Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator | Bulkhead | completed | 85 | 75 | 95 | 45 | 300 | — |
| 8 | **295** | [GH-14](https://github.com/HiQS-Suite/XYZ-forge/issues/14) — appendEvent writes non-atomically, so concurrent readers can observe torn event files | — | Completed | 85 | 85 | 70 | 55 | 295 | — |
| 9 | **295** | [GH-155](https://github.com/HiQS-Suite/XYZ-forge/issues/155) — 3rd Gen ATE & Fuzzing | — | Completed | 85 | 70 | 90 | 50 | 295 | — |
| 10 | **295** | [GH-165](https://github.com/HiQS-Suite/XYZ-forge/issues/165) — Post-Merge Wave & Marathon Lifecycle Reconciler (Docs, ROADMAP, DB, Views, and Planning) | — | Completed | 90 | 80 | 90 | 35 | 295 | — |
| 11 | **292** | [GH-23](https://github.com/HiQS-Suite/XYZ-forge/issues/23) — Kernel invariant: enforce path-overlap rejection on direct tick claim and tick scope | — | Completed | 82 | 78 | 72 | 60 | 292 | — |
| 12 | **290** | [GH-113](https://github.com/HiQS-Suite/XYZ-forge/issues/113) — headless agy builder writes root scratch files, tripping containment (exit 6) | Bulkhead | completed | 85 | 60 | 85 | 60 | 290 | — |
| 13 | **290** | [GH-123](https://github.com/HiQS-Labs/XYZ-forge/issues/123) — Linux portability canary — remainder: gh358 lock contention on shared runners | Linux-RC | in progress | 90 | 80 | 75 | 45 | 290 | — |
| 14 | **290** | [GH-148](https://github.com/HiQS-Suite/XYZ-forge/issues/148) — DeepSeek Harness (dsh) integration & deepseek-turn shim for OpenRouter DeepSeek V4 Pro | — | Completed | 85 | 75 | 90 | 40 | 290 | — |
| 15 | **290** | [GH-168](https://github.com/HiQS-Suite/XYZ-forge/issues/168) — wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR | Bulkhead | completed | 80 | 55 | 85 | 70 | 290 | — |
| 16 | **290** | [GH-226](https://github.com/HiQS-Labs/XYZ-forge/issues/226) — xyz-vendor.sh transcript gate refuses repos that gitignore transcripts | Linux-RC | completed | 75 | 50 | 80 | 85 | 290 | — |
| 17 | **285** | [GH-141](https://github.com/HiQS-Suite/XYZ-forge/issues/141) — make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison | Linux-RC | ad-hoc detour | 80 | 65 | 85 | 55 | 285 | — |
| 18 | **285** | [GH-221](https://github.com/HiQS-Labs/XYZ-forge/issues/221) — GH-221 — agy-turn.sh auth pre-flight breaks on agy CLI >=1.1.19 — whoami subcommand removed | — | Queue / parked intake | 70 | 65 | 70 | 80 | 285 | — |
| 19 | **280** | [GH-114](https://github.com/HiQS-Suite/XYZ-forge/issues/114) — headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7) | Bulkhead | completed | 80 | 60 | 80 | 60 | 280 | — |
| 20 | **280** | [GH-115](https://github.com/HiQS-Suite/XYZ-forge/issues/115) — marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4) | Bulkhead | completed | 75 | 50 | 85 | 70 | 280 | — |
| 21 | **280** | [GH-180](https://github.com/HiQS-Labs/XYZ-forge/issues/180) — repro_builder crashes on timeout telemetry records (exit_code: null → TypeError) | Bulkhead | completed | 70 | 45 | 85 | 80 | 280 | — |
| 22 | **280** | [GH-193](https://github.com/HiQS-Labs/XYZ-forge/issues/193) — AgentChorus Gen 2 | Cargo | queue | 75 | 70 | 85 | 50 | 280 | — |
| 23 | **280** | [GH-216](https://github.com/HiQS-Labs/XYZ-forge/issues/216) — GH-216 — marathon-plan.sh ledger parser rejects link-style ROADMAP.md bullets | — | Queue / parked intake | 75 | 65 | 70 | 70 | 280 | — |
| 24 | **280** | [GH-223](https://github.com/HiQS-Labs/XYZ-forge/issues/223) — GH-223 — pre-push gate push double-applies through ref lock | Cargo | queue | 80 | 75 | 65 | 60 | 280 | — |
| 25 | **280** | [GH-4](https://github.com/HiQS-Suite/XYZ-forge/issues/4) — the pre-push gate does not travel with clones: fresh clones push unverified | — | Completed | 78 | 72 | 70 | 60 | 280 | — |
| 26 | **280** | [GH-77](https://github.com/HiQS-Suite/XYZ-forge/issues/77) — `/standup` — session-scoped triage: what did I leave open, what is rotting, is the plan still right? | — | Completed | 95 | 70 | 85 | 30 | 280 | — |
| 27 | **275** | [GH-1](https://github.com/HiQS-Suite/XYZ-forge/issues/1) — suite-wide fixture containment + clone-identity invariant gate | — | Completed | 80 | 75 | 70 | 50 | 275 | — |
| 28 | **275** | [GH-124](https://github.com/HiQS-Suite/XYZ-forge/issues/124) — eliminate end-of-day closeout friction — automated phase QA receipts, auto-PR creation, and clone lifecycle hygiene | — | Completed | 85 | 60 | 90 | 40 | 275 | — |
| 29 | **275** | [GH-132](https://github.com/HiQS-Suite/XYZ-forge/issues/132) — feat(skills): formal /review-xyz code review skill & multi-model harness | — | Completed | 80 | 70 | 85 | 40 | 275 | — |
| 30 | **275** | [GH-15](https://github.com/HiQS-Suite/XYZ-forge/issues/15) — parallel runs are unreliable in a fresh clone; the GH-528 contention retry is not honoring its contract | — | Completed | 80 | 75 | 70 | 50 | 275 | — |
| 31 | **275** | [GH-170](https://github.com/HiQS-Suite/XYZ-forge/issues/170) — Agent2Agent: close transcript glitches and harden publishing | — | Completed | 75 | 60 | 85 | 55 | 275 | — |
| 32 | **275** | [GH-2](https://github.com/HiQS-Suite/XYZ-forge/issues/2) — test-suite run relocated an untracked file into .tick/orphan-backups/ | Bulkhead | completed | 80 | 55 | 85 | 55 | 275 | — |
| 33 | **275** | [GH-201](https://github.com/HiQS-Labs/XYZ-forge/issues/201) — Gen 3.5 follow-ups — remaining ATE hardening arc (tasks 3–8b of #174) | Cargo | in progress | 80 | 70 | 80 | 45 | 275 | — |
| 34 | **275** | [GH-8](https://github.com/HiQS-Suite/XYZ-forge/issues/8) — kernel boundary hardening — CLI numeric validation, task/agent format contract | Bulkhead | completed | 75 | 55 | 80 | 65 | 275 | — |
| 35 | **270** | [GH-184](https://github.com/HiQS-Labs/XYZ-forge/issues/184) — committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation | Bulkhead | completed | 60 | 40 | 80 | 90 | 270 | — |
| 36 | **270** | [GH-205](https://github.com/HiQS-Labs/XYZ-forge/issues/205) — validate.sh mutates four tracked files per run — gate not idempotent | Linux-RC | in progress | 75 | 70 | 70 | 55 | 270 | — |
| 37 | **270** | [GH-75](https://github.com/HiQS-Suite/XYZ-forge/issues/75) — single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view | — | Queue / parked intake | 90 | 40 | 85 | 55 | 270 | — |
| 38 | **265** | [GH-111](https://github.com/HiQS-Suite/XYZ-forge/issues/111) — retire manifest FREEZE; tasks and marathons are DIALED IN to exactly one release, as a database state | — | Completed | 85 | 75 | 70 | 35 | 265 | — |
| 39 | **265** | [GH-182](https://github.com/HiQS-Labs/XYZ-forge/issues/182) — self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design | Cargo | in progress | 75 | 55 | 80 | 55 | 265 | — |
| 40 | **265** | [GH-50](https://github.com/HiQS-Suite/XYZ-forge/issues/50) — sandboxed git --track / branch -D half-applies and loses uncommitted work | Bulkhead | completed | 65 | 35 | 85 | 80 | 265 | — |
| 41 | **260** | [GH-183](https://github.com/HiQS-Labs/XYZ-forge/issues/183) — active_explorer env-family fuzzing unsound (base_env={} hardcoded, one always-deferring vector, ambient-env leakage) | Bulkhead | completed | 65 | 50 | 75 | 70 | 260 | — |
| 42 | **257** | [GH-215](https://github.com/HiQS-Labs/XYZ-forge/issues/215) — GH-215 — wave_reconcile.py and roadmap-dashboard.sh hardcode pre-vendoring path depth | — | Queue / parked intake | 72 | 60 | 65 | 60 | 257 | — |
| 43 | **255** | [GH-10](https://github.com/HiQS-Suite/XYZ-forge/issues/10) — prevent-half of containment: require_fixture adoption across the fixture-creating suites + adoption guard + ci-local identity bracket | — | Completed | 55 | 70 | 50 | 80 | 255 | — |
| 44 | **255** | [GH-144](https://github.com/HiQS-Suite/XYZ-forge/issues/144) — Agent2Agent 3+ participant onboarding + read-only status quick wins | — | Completed | 55 | 30 | 80 | 90 | 255 | — |
| 45 | **255** | [GH-45](https://github.com/HiQS-Suite/XYZ-forge/issues/45) — validate.sh must refuse to run from a linked worktree — an observed run corrupted the parent clone | — | Completed | 65 | 60 | 60 | 70 | 255 | — |
| 46 | **255** | [GH-91](https://github.com/HiQS-Suite/XYZ-forge/issues/91) — a build turn has nowhere to write verification output | — | Completed | 60 | 65 | 55 | 75 | 255 | — |
| 47 | **250** | [GH-153](https://github.com/HiQS-Suite/XYZ-forge/issues/153) — RELEASES dashboard sidebar + full-cycle rollup (technical spike) | — | Completed | 70 | 55 | 80 | 45 | 250 | — |
| 48 | **250** | [GH-197](https://github.com/HiQS-Suite/XYZ-forge/issues/197) — two-tier xyz-vendor.sh: Tier 1 core-harness default, Tier 2 opt-in RELEASES overlay + onboarding SOP (GH-105 follow-up) | — | Completed | 80 | 55 | 65 | 50 | 250 | — |
| 49 | **250** | [GH-232](https://github.com/HiQS-Labs/XYZ-forge/issues/232) — wave_reconcile should honor linked issue open/closed state before promoting multi-phase docs | Linux-RC | in progress | 70 | 55 | 65 | 60 | 250 | — |
| 50 | **250** | [GH-243](https://github.com/HiQS-Labs/XYZ-forge/issues/243) — GH-169 items 3-4: repoint agent docs + dashboard-staleness push guard | — | Queue | 70 | 55 | 65 | 60 | 250 | — |
| 51 | **250** | [GH-246](https://github.com/HiQS-Labs/XYZ-forge/issues/246) — relay-xyz SKILL.md: explicit QA/Consult prompt template for headless agents (hotfix) | — | Queue / parked intake | 60 | 35 | 70 | 85 | 250 | — |
| 52 | **245** | [GH-108](https://github.com/HiQS-Suite/XYZ-forge/issues/108) — pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override) | Daybreak | cut | 80 | 50 | 75 | 40 | 245 | — |
| 53 | **235** | [GH-222](https://github.com/HiQS-Labs/XYZ-forge/issues/222) — GH-222 — releases update cannot re-point a release's tracking issue | Cargo | queue | 60 | 40 | 60 | 75 | 235 | — |
| 54 | **230** | [GH-105](https://github.com/HiQS-Suite/XYZ-forge/issues/105) — vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on) | Cargo | queue | 75 | 50 | 60 | 45 | 230 | — |
| 55 | **228** | [GH-102](https://github.com/HiQS-Suite/XYZ-forge/issues/102) — Unify Telemetry Schema & Inspection Tooling Across Fuzzing and ATE | — | Completed | 68 | 45 | 70 | 45 | 228 | — |
| 56 | **222** | [GH-103](https://github.com/HiQS-Suite/XYZ-forge/issues/103) — technical spike: RELEASES SQLite → timeline-ui ledger viewer (RELEASES dashboard view) | — | Completed | 62 | 35 | 75 | 50 | 222 | — |
| 57 | **220** | [GH-3](https://github.com/HiQS-Suite/XYZ-forge/issues/3) — improve-loop.sh --state-dir durability — provenance evidence must not evaporate | — | Completed | 55 | 45 | 55 | 65 | 220 | — |
| 58 | **220** | [GH-32](https://github.com/HiQS-Suite/XYZ-forge/issues/32) — RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI | — | Queue / parked intake | 70 | 50 | 65 | 35 | 220 | — |
| 59 | **220** | [GH-57](https://github.com/HiQS-Suite/XYZ-forge/issues/57) — test(releases): SQLite ledger fuzzing recipes & multi-scenario resilience suite | — | Completed | 60 | 45 | 65 | 50 | 220 | — |
| 60 | **218** | GH-135 — GH-135..140 · Wave-1 follow-ups: consult preflight verdict, attempts-gate root, suite registration, twin-divergence record, SIGPIPE sweep+guard, utcnow swap | — | Completed | 58 | 45 | 60 | 55 | 218 | — |
| 61 | **215** | [GH-233](https://github.com/HiQS-Labs/XYZ-forge/issues/233) — AgentChorus Gen 2 Phase 2 — Lifecycle Verbs, Watch Invalidation, Concurrency Suite & Citation Linter | Linux-RC | in progress | 65 | 45 | 75 | 30 | 215 | — |
| 62 | **210** | [GH-5](https://github.com/HiQS-Suite/XYZ-forge/issues/5) — kernel robustness: node:test unit runner | Linux-RC | ad-hoc detour | 45 | 40 | 45 | 80 | 210 | — |
| 63 | **195** | [GH-35](https://github.com/HiQS-Suite/XYZ-forge/issues/35) — 3-tier test suite selection (docs / utility subsystems / core) + CPU governance | — | Completed | 55 | 45 | 50 | 45 | 195 | — |
| 64 | **190** | [GH-39](https://github.com/HiQS-Suite/XYZ-forge/issues/39) — RELEASES app: one-way GitHub Project release-card projection | — | Completed | 50 | 30 | 65 | 45 | 190 | — |
| 65 | **190** | [GH-61](https://github.com/HiQS-Suite/XYZ-forge/issues/62) — RELEASES ledger durability hardening (GH-57 follow-up) | — | Queue / parked intake | 45 | 55 | 40 | 50 | 190 | — |
| 66 | **185** | [GH-17](https://github.com/HiQS-Suite/XYZ-forge/issues/17) — SOP for evaluating new agent harnesses and frontier models | — | Queue / parked intake | 45 | 30 | 50 | 60 | 185 | — |
| 67 | **185** | [GH-42](https://github.com/HiQS-Suite/XYZ-forge/issues/42) — relay automation: supported Commandcode turn-taker | — | Completed | 50 | 35 | 55 | 45 | 185 | — |
| 68 | **175** | [GH-101](https://github.com/HiQS-Suite/XYZ-forge/issues/101) — Feasibility Study: Promoting Programmatic Script Runner (`script_runner.py`) into Core Relay & Consult Runtimes | — | Completed | 45 | 20 | 70 | 40 | 175 | — |
| 69 | **175** | [GH-94](https://github.com/HiQS-Suite/XYZ-forge/issues/94) — research: programmatic tool calling & code-mode execution for harnesses, telemetry, and containment | — | Completed | 45 | 20 | 70 | 40 | 175 | — |
| 70 | **170** | [GH-195](https://github.com/HiQS-Labs/XYZ-forge/issues/195) — marathon-root-audit's blind spot: a direct `python3 marathon_drive.py` call | — | Completed | 60 | 40 | 50 | 20 | 170 | — |
| 71 | **170** | [GH-28](https://github.com/HiQS-Suite/XYZ-forge/issues/28) — RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue | — | Queue / parked intake | 40 | 35 | 40 | 55 | 170 | — |
| 72 | **160** | [GH-18](https://github.com/HiQS-Suite/XYZ-forge/issues/18) — Harness evaluation: Command Code (cmd) and model matrix | — | Queue / parked intake | 35 | 25 | 45 | 55 | 160 | — |

**Top of the line:** GH-67 — Commandcode builder default widened to `--yolo` — closer evaluation → possible build (score 340, operator override).

Source: `releases.db` via `export_timeline.py --json`. Regenerate with `bash utils/leaderboard.sh`.
---
title: Combined Roadmap — Cost-Observed Marathon Loops + Adversarial Hardening
status: Active
created: 2026-06-16
updated: 2026-08-21
branch: main
supersedes: PROJECT/2-WORKING/ROADMAP-COMBINED.md (promoted to canonical 2026-06-17); folds in the former standalone ROADMAP.md (adversarial-hardening track, now Part B)
synthesizes:
  - PROJECT/1-INBOX/LOOPS.md
  - PROJECT/4-MISC/COST-OBSERVABILITY-PLAN.md
  - PROJECT/1-INBOX/MARATHON.md
goal: >
  Keep one long-horizon marathon under load at all times — work long, parallel, and failure-prone
  enough to tax the whole XYZ system (worktree isolation, path claims, the driver lock, multi-round
  handoff, escalation, resume). That purpose is a work-selection filter: prefer the marathon-shaped
  candidate, run only real work (an idle gap is honest; a manufactured marathon is not), and treat
  the failures a run surfaces as the deliverable. See AGENTS.md -> Repo-specific rails for the four
  rules. Mechanically, this file is the canonical pointer/ledger index for that work — queued
  intake, in progress, completed, and deferred — linking to the PROJECT/** docs that own the
  execution detail. It is an index, not a plan body.
---

<!-- PDDA ROADMAP CONTRACT — this file is a POINTER/LEDGER, not a plan body.
     Allowed: queued intake / projects in progress / completed / attempted / deferred + links to PROJECT/** docs.
     NOT allowed: phase checklists, build steps, deep execution notes — put those in the project doc.
     Carve-out: a SHORT exception note is OK only when omitting it would hide an operationally critical fact.
     Coverage rule: every PROJECT/2-WORKING doc must be reflected here by a pointer (or opt out with roadmap_exempt: true).
     Enforced by `utils/pdda/pdda.sh roadmap` + `utils/pdda/pdda.sh roadmap-coverage` (deterministic) + `utils/pdda/pdda.sh doc-ready` ROADMAP rubric (LLM).      SHADOW (GH-69): this ledger is mirrored into releases.db's roadmap_items table. After editing
     the ledger, run `python3 utils/py/releases_app.py roadmap sync` (a no-change sync is a free
     no-op). This file remains the ONLY source of truth; the sync is one-way and never writes here.
-->

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
| **2026-08-19:** release **0.7.1 “Bulwark”** cut end-to-end through the RELEASES CLI, merged (PR #66), and **SHIPPED** the same day — the first release never hand-edited, and the first shipped through `releases ship` with its exit-criterion evidence recorded in the receipt chain (`gh32-releases-artifacts` 10/0, `gh53-releases-merge-resolve` 15/0, `gh54-merged-dump-refusals` 19/0, `check` clean at generation 9). **PR #55** (GH-35 tiered test selection + CPU governance; GH-45 worktree-gate refusal) and **PR #60** (GH-57 SQLite ledger fuzzing, 42/0) merged. **PR #70** closed GH-57’s live-merge gap: `test/gh57-live-merge-resolve.sh` (30/0) drives a REAL `git merge` and found four resolver defects, all fixed (failed-resolve half-closed the merge; rewound generation header accepted; `releases.db.bak` committable; `--root ""` retargeting). This ledger was purged of 256 upstream-numbered entries the same day (see below) and reconciled against GitHub issue state. | **[#75](https://github.com/HiQS-Suite/XYZ-forge/issues/75)** — single-page HTML dashboard over both DB subsystems (**front of the line, operator call 2026-08-19**). **[#67](https://github.com/HiQS-Suite/XYZ-forge/issues/67) (P1)** — decide the Commandcode `--yolo` default landed silently by PR #60. **[#59](https://github.com/HiQS-Suite/XYZ-forge/issues/59)** — re-arm hosted CI: the repo is public and Actions is enabled, yet pushes produce no runs. **[#58](https://github.com/HiQS-Suite/XYZ-forge/issues/58)** — GH-35 Phase 3 follow-ups (tier-2 hygiene gap P2 + two P3s), recommended to ride with Phase 3. **[#61](https://github.com/HiQS-Suite/XYZ-forge/issues/61)** — RELEASES ledger durability hardening (#62–#65). Next release on the shelf: **0.6.0 “Meter”**, target 2026-09-26. External contributions resolved 2026-08-21: PR #51, #99 and #119 merged; **PR #29 closed** — its tooling half landed as #51, but its Windows/MSYS2 *evidence* half never landed anywhere and was requested as a follow-up, so that platform still has no coverage. |

### Immediate next-up (ordered)

> **THE MARATHON — [#179](https://github.com/HiQS-Suite/XYZ-forge/issues/179) (release 0.7.3 "Bulkhead": harness reliability hardening).**
> **Handed over from [#77](https://github.com/HiQS-Suite/XYZ-forge/issues/77) on 2026-08-22 — Daybreak SHIPPED** (0.7.2, all
> four waves merged, gh77 suite green, #77/#82-#87 closed with evidence). Bulkhead is the next arc,
> built from the 2026-08-22 radar targets: the suite-containment class (both polarities), headless-turn
> reliability, and the roadmap-reconcile writer. Twelve members (7 radar targets 2026-08-22 + 5 Gen 3.5
> soak defects 2026-08-23), disjoint-leaning write-sets, each with a
> capture doc + preflight contract:
> **[#113](https://github.com/HiQS-Suite/XYZ-forge/issues/113)** headless scratch containment (rated 85/60/85/60 → [GH-113-HEADLESS-SCRATCH-CONTAINMENT.md](PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md)) ·
> **[#114](https://github.com/HiQS-Suite/XYZ-forge/issues/114)** headless TTY/idle hang (rated 80/60/80/60 → [GH-114-HEADLESS-TTY-IDLE-HANG.md](PROJECT/2-WORKING/GH-114-HEADLESS-TTY-IDLE-HANG.md)) ·
> **[#115](https://github.com/HiQS-Suite/XYZ-forge/issues/115)** round-cap escalation (rated 75/50/85/70 → [GH-115-ROUND-CAP-ESCALATION.md](PROJECT/2-WORKING/GH-115-ROUND-CAP-ESCALATION.md)) ·
> **[#168](https://github.com/HiQS-Suite/XYZ-forge/issues/168)** wave_reconcile scope (rated 80/55/85/70 → [GH-168-WAVE-RECONCILE-SCOPE.md](PROJECT/2-WORKING/GH-168-WAVE-RECONCILE-SCOPE.md)) ·
> **[#8](https://github.com/HiQS-Suite/XYZ-forge/issues/8)** kernel boundary hardening (rated 75/55/80/65 → [GH-8-KERNEL-BOUNDARY-HARDENING.md](PROJECT/2-WORKING/GH-8-KERNEL-BOUNDARY-HARDENING.md)) ·
> **[#2](https://github.com/HiQS-Suite/XYZ-forge/issues/2)** orphan-backup relocation (rated 80/55/85/55 → [GH-2-ORPHAN-BACKUP-RELOCATION.md](PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md)) ·
> **[#50](https://github.com/HiQS-Labs/XYZ-forge/issues/50)** sandboxed git half-apply (rated 65/35/85/80 → [GH-50-SANDBOXED-GIT-HALF-APPLY.md](PROJECT/2-WORKING/GH-50-SANDBOXED-GIT-HALF-APPLY.md)) ·
> **[#180](https://github.com/HiQS-Labs/XYZ-forge/issues/180)** repro-builder timeout-record crash (rated 70/45/85/80 → [GH-180-REPRO-TIMEOUT-CRASH.md](PROJECT/2-WORKING/GH-180-REPRO-TIMEOUT-CRASH.md)) ·
> **[#181](https://github.com/HiQS-Labs/XYZ-forge/issues/181)** repro-builder telemetry fidelity (rated 90/75/90/60 → [GH-181-REPRO-ADAPTER-FIDELITY.md](PROJECT/2-WORKING/GH-181-REPRO-ADAPTER-FIDELITY.md)) ·
> **[#182](https://github.com/HiQS-Labs/XYZ-forge/issues/182)** self-healer facade/safety (rated 75/55/80/55 → [GH-182-HEALER-FACADE-SAFETY.md](PROJECT/2-WORKING/GH-182-HEALER-FACADE-SAFETY.md)) ·
> **[#183](https://github.com/HiQS-Labs/XYZ-forge/issues/183)** explorer env-family soundness (rated 65/50/75/70 → [GH-183-EXPLORER-ENV-SOUNDNESS.md](PROJECT/2-WORKING/GH-183-EXPLORER-ENV-SOUNDNESS.md)) ·
> **[#184](https://github.com/HiQS-Labs/XYZ-forge/issues/184)** tracked scratch artifact (rated 60/40/80/90 → [GH-184-TRACKED-SCRATCH-ARTIFACT.md](PROJECT/2-WORKING/GH-184-TRACKED-SCRATCH-ARTIFACT.md)).
> The five #180–#184 members joined 2026-08-23 from the Gen 3.5 soak (#174/#177) — the first
> cohort auto-filed under SOP §1's auto-file rule. Marathon now twelve members.
> Plan computed and preflighted, NOT fired — operator fires per GUIDING-PRINCIPLES §8.

> **Previous marathon (completed) — [#77](https://github.com/HiQS-Suite/XYZ-forge/issues/77) (`collect.sh`: the eight `/standup` lenses).**
> Exactly one long-horizon marathon is in flight at a time (AGENTS.md → Repo-specific rails); this is it.
> **Handed over from [#10](https://github.com/HiQS-Suite/XYZ-forge/issues/10) on 2026-08-19 by operator
> call** — recorded as a deliberate swap rather than a second marathon, which the rail forbids. #10
> stands down to ⏸️ and keeps its Ballast-cut history; it is the obvious next candidate when this lands.
> #77 qualifies on the same filter: **eight near-identical work units**, one per lens, each with an
> identical transform (bounded read → six required fields → fixture → assertions) and a machine-checkable
> pass condition (`collect.sh --fixture lens-<n>` feeds `triage.py` with no `D5`, suite green). It taxes
> the harness where a short task never does — eight parallel lanes editing one shared `collect.sh` and one
> shared suite, which is exactly the path-claim and collision surface the swarm exists to manage. A lane
> clobbering another's edit is the failure this run is meant to surface, and surfacing it is the
> deliverable (rail 4). Shipping under release **0.7.2 "Daybreak"**.
> Everything numbered below rides *alongside* it, not instead of it.

1. **[#75](https://github.com/HiQS-Suite/XYZ-forge/issues/75) — build the single-page dashboard** over `releases` + `roadmap_items`. Deliberately **not** the marathon: it is one generator emitting one file and taxes nothing. It is the instrument you watch the marathon through — the drift this week (a shipped release left `active`, four stale status markers) was invisible until someone audited by hand. Also the first real consumer of the GH-69 shadow rows, which was #69's stated gate for its later stages.
2. **[#67](https://github.com/HiQS-Suite/XYZ-forge/issues/67) — P1: ratify or revert the Commandcode `--yolo` default.** A permission-posture change to a builder default, landed inside a fuzzing PR, undecided.
3. **[#59](https://github.com/HiQS-Suite/XYZ-forge/issues/59) — find out why hosted CI fires on nothing**, then narrow triggers to push/merge on `development` + `main` and wire the required check behind `main`'s new branch protection. **The "fires on nothing" half RESOLVED ITSELF at 17:09 UTC on 2026-08-21** — `pull_request` (run 32506672733) and `push` on `development` (run 32506697196) both fired normally, with no change to the workflow's triggers, after four days and three check-less merges (#116, #121, #122). Cause not established; it changed between 16:45 and 17:09 UTC, and the audit log needs `admin:org` — **if you flipped a setting in that window, record it on the issue.** Seven hypotheses were ruled out with evidence during the outage (billing was the leading theory and was wrong). **Still open:** narrowing the triggers and wiring the required check behind `main`'s branch protection — and note that both new runs concluded *success* while the canary job failed, so a green PR here currently proves nothing until #123 clears. History codified in `.github/workflows/ci.yml`'s header. rated 75/60/40/70.
4. **[#123](https://github.com/HiQS-Suite/XYZ-forge/issues/123) — clear the Linux portability canary**: 7 failing assertions across 5 suites, found by the FIRST end-to-end run of that job (2026-08-21, run 32504570094). It had been dying at step 1 on a missing shebang and reporting the run green since the 2026-08-17 re-arm — advisory jobs make their own failures invisible. Two of the seven are new code from #116 (`utils/leaderboard.sh` ordering, `roadmap sync` dry-run), so they are drift we shipped, not drift we inherited. Per #232, reproduce in a container before calling any of them environment noise. rated 70/55/45/65.
5. **[#58](https://github.com/HiQS-Suite/XYZ-forge/issues/58) — GH-35 Phase 3**, folding in the tier-2 hygiene gap (P2) and the two P3 defects from the PR #55 review.

> **Standing radar finding (2026-08-19, 21-day window, 122 commits on `development`):** flow is
> roughly **Run 72% / Grow 16% / Transform 0%** — no `PROJECT/**` doc declares `rgt: transform`, so
> by the strict rule no transform work can be *claimed*, not that none happened. The dominant defect
> cluster is **guards that could not report red**: the dashboard check verified its own output (three
> stale dashboards reached `development` under a green gate on 2026-07-30 alone), the pre-push hook
> double-niced and blocked itself, and GH-57's resolver held four defects invisible until a real
> `git merge` was driven. One durable fix — every guard ships a recorded negative control against the
> *real* artifact — retires the cluster. That is release **0.2.0 Litmus**'s declared scope.

> **Provenance note (2026-08-19):** this repo succeeds
> [`xyz-3-agents-swarm`](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm); the migration kept the old GH numbering in
> inherited ledger entries. 256 upstream-numbered entries were removed from this ledger on the
> operator's call and preserved verbatim in
> [docs/ROADMAP-UPSTREAM-ARCHIVE.md](docs/ROADMAP-UPSTREAM-ARCHIVE.md) ([#69](https://github.com/HiQS-Suite/XYZ-forge/issues/69)).
> Every `GH-nnn` below refers to THIS repo's issues.

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

*(empty — GH-23 closed and moved to Completed 2026-08-19. Heading kept so an out-of-band
detour has a home; note that the marathon planner does NOT read this section — see `## Entry format`.)*

### Queue / parked intake
- **GH-223 — pre-push gate push double-applies through ref lock** (2026-08-24) - gate-green push reports its own landed commit as a lock rejection; observed 2x of ~10 gated pushes; quick-fix shape. Captured via /idea; dialed into 0.9.0 Cargo. Issue [#223](https://github.com/HiQS-Labs/XYZ-forge/issues/223). -> [PROJECT/1-INBOX/GH-223-GATE-PUSH-DOUBLE-APPLY.md](PROJECT/1-INBOX/GH-223-GATE-PUSH-DOUBLE-APPLY.md)
- **GH-222 — releases update cannot re-point a release's tracking issue** (2026-08-24) - a superseded tracking umbrella (LTVera-Pandas #225→#236) leaves the ledger permanently pointing at a closed issue; `releases update` has no `--tracking-issue` and `reconcile` only fills TMP refs. Dialed into 0.7.3 Bulkhead by operator 2026-08-24. Issue [#222](https://github.com/HiQS-Labs/XYZ-forge/issues/222). -> [PROJECT/1-INBOX/GH-222-RELEASES-TRACKING-REPOINT.md](PROJECT/1-INBOX/GH-222-RELEASES-TRACKING-REPOINT.md)
- **GH-221 — agy-turn.sh auth pre-flight breaks on agy CLI >=1.1.19 — whoami subcommand removed** (2026-08-24) - `whoami` no longer exists in agy CLI >=1.1.19, so the auth pre-flight hard-fails every headless agy-turn.sh run and misreports it as a login problem. Bug filed via /file-xyz-bug from `aegis-sleuth-slack-bot`. Issue [#221](https://github.com/HiQS-Labs/XYZ-forge/issues/221). -> [PROJECT/1-INBOX/GH-221-AGY-WHOAMI-PREFLIGHT.md](PROJECT/1-INBOX/GH-221-AGY-WHOAMI-PREFLIGHT.md)
- **GH-215 — wave_reconcile.py and roadmap-dashboard.sh hardcode pre-vendoring path depth** (2026-08-24) - both assume a bare `utils/` at repo root; under vendored `.xyz/` they die on missing files / ENOENT. Fixed locally in the reporting repo, not yet upstream. Bug filed via /file-xyz-bug from `LTVera-Pandas`. Issue [#215](https://github.com/HiQS-Labs/XYZ-forge/issues/215). -> [PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md](PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md)
- **GH-216 — marathon-plan.sh ledger parser rejects link-style ROADMAP.md bullets** (2026-08-24) - reconciler never completes in a repo whose ROADMAP.md uses `- [Title](path) — ...` bullets; exit 3 every time. Open design question, not patched. Bug filed via /file-xyz-bug from `LTVera-Pandas`. Issue [#216](https://github.com/HiQS-Labs/XYZ-forge/issues/216). -> [PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md](PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md)
- **GH-105 · vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on)** 🆕 **queued 2026-08-20; sole frozen manifest entry of new release 0.9.0 "Cargo" (target 2026-09-19, before Meter, operator call); delivery contract superseded by GH-197 (two-tier, 2026-08-23)** — was: always in the vendored payload, never wired by default: `releases_app.py` + merge resolver + FAQs + `utils/timeline/`, with target-repo ledger state at the target root and GH-312 preserve-list coverage. rated 75/50/60/45. → [GH-105-VENDOR-RELEASES-ADDON.md](PROJECT/1-INBOX/GH-105-VENDOR-RELEASES-ADDON.md) · [#105](https://github.com/HiQS-Suite/XYZ-forge/issues/105)
- **GH-75 · single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view** 🆕 **queued 2026-08-19 at the FRONT of the line (operator call)** — a `releases dashboard` verb renders one self-contained HTML file from `releases.db`, with a card per release (version, codename, status, target, days-to-target, manifest open/closed split, exit criterion) and a card per `roadmap_items` row grouped by section in ledger order, plus a header strip carrying generation, receipt count, and a stale-sync banner when `ROADMAP.md` is ahead of the shadow. Read-only by construction: no writer lock, no generation bump, no receipt — safe to run mid-merge. First real consumer of the GH-69 shadow rows. rated 90/40/85/55. → [#75](https://github.com/HiQS-Suite/XYZ-forge/issues/75)
- **GH-61 · RELEASES ledger durability hardening (GH-57 follow-up)** 🆕 **queued 2026-08-19 — filed 2026-08-19 out of the PR #60 review and un-triaged until now** — four scoped test follow-ups under one parent: exact ledger state asserted after crash recovery ([#62](https://github.com/HiQS-Suite/XYZ-forge/issues/62)), writer-lock stress and owner-death recovery ([#63](https://github.com/HiQS-Suite/XYZ-forge/issues/63)), seeded malformed-dump property coverage ([#64](https://github.com/HiQS-Suite/XYZ-forge/issues/64)), and a portable artifact-hash helper ([#65](https://github.com/HiQS-Suite/XYZ-forge/issues/65)). rated 45/55/40/50. → [#61](https://github.com/HiQS-Suite/XYZ-forge/issues/61)
- **GH-67 · Commandcode builder default widened to `--yolo` — closer evaluation → possible build** 🆕 **queued 2026-08-19 as the NEXT immediate item (operator call, session close)** — PR #60 moved the default from the bounded `--permission-mode auto-accept` to `--yolo` (alias for `--dangerously-skip-permissions`), unmentioned in a fuzzing PR. Evaluate whether the turn shim’s containment (worktree isolation, `ALLOW_PATHS`, commit-bypass guard) genuinely makes the child CLI’s permission mode irrelevant; if yes, RATIFY — write the containment argument down in AGENTS.md/the shim docs and pin it — if no, revert the default and drop the `--yolo` test pin. Sibling check either way: `claude-turn.py` uses `--permission-mode acceptEdits`; confirm the two adapters differ on purpose. rated 88/80/45/70 ovr 340. → [#67](https://github.com/HiQS-Suite/XYZ-forge/issues/67)
- **GH-32 · RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI** 🚧 **Phase 0+1 BUILT and merged 2026-08-19 (PR #34, builder GLM 5.3 per the #33 evaluation)** — schema/CLI/writer-protocol/canonical-dump/import landed (`utils/py/releases_app.py`, suite 81/0, full gate green, independently verified); the PRD survived a 4-round Codex sol-high relay review first. Still ahead: the `/releases` route migration (Phase 0 entry gate for the measured dogfood window), the Phase 2 strict flip, and the Phase 3 cockpit card. rated 70/50/65/35. → [GH-32-RELEASES-APP-SQLITE.md](PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md) · [#32](https://github.com/HiQS-Suite/XYZ-forge/issues/32) · [#33](https://github.com/HiQS-Suite/XYZ-forge/issues/33)
- **GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue** 🆕 **queued 2026-08-18, sharpened via /consult (single-model, agy quota-failed) 2026-08-18, post-Ballast 0.7.0 follow-up** — root cause is two gaps: the discipline rubric only fires on manual `/releases clean`, and release-level notes have no home of their own. Consult caught that the original plan would've reversed documented "never blocks" policy and that the parser can't see continuation-paragraph bloat at all — both fixed: checks are now permanently advisory, scoped to active/unshipped blocks, with a required parser-folding step. rated 40/35/40/55. → [GH-28-RELEASES-LEDGER-DISCIPLINE.md](PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md) · [#28](https://github.com/HiQS-Suite/XYZ-forge/issues/28)
- **GH-17 · SOP for evaluating new agent harnesses and frontier models** 🆕 **queued 2026-08-16** — establish a standardized operating procedure, checklist, and per-harness tracking issue workflow for new harness discovery, isolation, non-interactive execution, and cross-model matrix evaluation. rated 45/30/50/60. → [GH-17-SOP-HARNESS-MODEL-EVAL.md](PROJECT/1-INBOX/GH-17-SOP-HARNESS-MODEL-EVAL.md) · [#17](https://github.com/HiQS-Suite/XYZ-forge/issues/17)
- **GH-18 · Harness evaluation: Command Code (cmd) and model matrix** 🆕 **queued 2026-08-16** — evaluate Command Code CLI (v1.26.0), PATH resolution, auth, non-interactive `-p` execution, and model review benchmarks with `qwen/qwen3.7-flash` and `qwen/qwen3.8-max`. rated 35/25/45/55. → [GH-18-COMMANDCODE-EVAL.md](PROJECT/1-INBOX/GH-18-COMMANDCODE-EVAL.md) · [#18](https://github.com/HiQS-Suite/XYZ-forge/issues/18)
### In progress
- **GH-232 · wave_reconcile should honor linked issue open/closed state before promoting multi-phase docs** 🚧 **active 2026-08-25 for release 0.7.4 "Linux-RC" (#224)** — inspect linked GitHub issue state before doc promotion; keep docs in PROJECT/2-WORKING/ while linked issue is OPEN; append merge evidence without moving file. cx2/risk2/eff2. → [GH-232-WAVE-RECONCILER-MULTIPHASE.md](PROJECT/2-WORKING/GH-232-WAVE-RECONCILER-MULTIPHASE.md) · [#232](https://github.com/HiQS-Labs/XYZ-forge/issues/232)
- **GH-233 · AgentChorus Gen 2 Phase 2 — Lifecycle Verbs, Watch Invalidation, Concurrency Suite & Citation Linter** 🚧 **active 2026-08-25 for release 0.7.4 "Linux-RC" (#224)** — operator-mediated invite with SKILL.md invariant reconciliation, atomic start --supersedes, terminal watch invalidation, multi-agent concurrency stress suite, and verify-citations ref-pinning linter. cx3/risk2/eff3. → [GH-233-AGENTCHORUS-GEN2-PHASE2.md](PROJECT/2-WORKING/GH-233-AGENTCHORUS-GEN2-PHASE2.md) · [#233](https://github.com/HiQS-Labs/XYZ-forge/issues/233)
- **GH-204 · BSD `sed -i ''` no-ops on Linux at production call sites** 🚧 **active 2026-08-24 for release 0.7.4 "Linux-RC" (#224 Phase 2) — marathon lane computed, not fired** — portable in-place edits in `build-launch-artifact.sh` + `meter-release.sh`, content-asserted escalation write in the authoritative Python lane (`relay_drive.py`; the Bash twin is FROZEN per GH-308), and a gate-registered content-assertion regression suite. cx2/risk2/eff2. → [GH-204-BSD-SED-PORTABILITY.md](PROJECT/2-WORKING/GH-204-BSD-SED-PORTABILITY.md) · [#204](https://github.com/HiQS-Labs/XYZ-forge/issues/204)
- **GH-205 · validate.sh mutates four tracked files per run — gate not idempotent** 🚧 **active 2026-08-24 for release 0.7.4 "Linux-RC" (#224 Phase 2) — marathon lane computed, not fired** — fixture-isolate `test/gh174-harness-registry.sh` (writes into `$ROOT/harnesses.db` + blog doc) so a pristine checkout stays porcelain-clean through a full gate; pinned by a new regression suite. cx2/risk1/eff2. → [GH-205-GATE-IDEMPOTENCY.md](PROJECT/2-WORKING/GH-205-GATE-IDEMPOTENCY.md) · [#205](https://github.com/HiQS-Labs/XYZ-forge/issues/205)
- **GH-123 · Linux portability canary — remainder: gh358 lock contention on shared runners** 🚧 **active 2026-08-24 for release 0.7.4 "Linux-RC" (#224 Phase 2) — marathon lane computed, not fired** — the last live canary failure: make `test/gh358-lock-instrumentation.sh` deterministic under shared-runner CPU load (`XYZ_LOCK_WAIT_S` tuning or bounded retry); other 4 suites resolved on development / PR #209. cx2/risk2/eff2. → [GH-123-LINUX-CANARY-REMAINDER.md](PROJECT/2-WORKING/GH-123-LINUX-CANARY-REMAINDER.md) · [#123](https://github.com/HiQS-Labs/XYZ-forge/issues/123)
- **GH-182 · self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design** 🚧 **queued 2026-08-23 for THE MARATHON (release 0.7.3 "Bulkhead", #179) — Gen 3.5 soak cohort, auto-filed per SOP §1** — fail-fast sandbox requirements (disposable root covering the target, never the invoking checkout), mandatory regression gate, configurable realistic timeouts, restore-on-any-exit; no reachable in-place patch path. rated 75/55/80/55. → [GH-182-HEALER-FACADE-SAFETY.md](PROJECT/2-WORKING/GH-182-HEALER-FACADE-SAFETY.md) · [#182](https://github.com/HiQS-Labs/XYZ-forge/issues/182)
- **GH-201 · Gen 3.5 follow-ups — remaining ATE hardening arc (tasks 3–8b of #174)** 🚧 **active 2026-08-24 for release 0.9.0 "Cargo" (draft)** — deterministic Phase 1–3 fixes (A1–A9/A11), the remaining data-path wiring (explorer→repro-builder + E2E rewrite), explorer sharpening + per-probe zero-mutation oracle, gated Phase 4 autonomy (full-clone dispatch, GH-221 predicates, budget governor), the five-canary calibration hour, and the Gemma Tier-1 sensor (Part H, advisory-until-calibrated); healer safety rides separately as #182 on Bulkhead. rated 80/70/80/45. → [GH-201-GEN35-FOLLOWUPS.md](PROJECT/2-WORKING/GH-201-GEN35-FOLLOWUPS.md) · [#201](https://github.com/HiQS-Labs/XYZ-forge/issues/201)
- **GH-141 · make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison** 🚧 **active 2026-08-22 on branch `gh141-fuzz-ate-utility`** — one selector owns the synthetic suites (validate.sh `--list` consumed by fuzz-loop, all 14 synthetic suites registered, divergence regression), telemetry de-aliased (nested `classification.status` removed; severity/likely_cause become derived signal from documented exit classes and output classes, consumers updated in-phase), the ATE chain fails loudly (#142's exit-code contract: 0 filed · 3 no-records · 1 gh-failed, propagated through run_variations) with a hermetic stub-`gh` chain regression, and ATE decoupled from Aider (neutral default labels, `expects_edits` grid key fixing #146's 17 false-HIGH no_edit verdicts, turn-shim grid declared, SKILL.md generalized). Phase 3 (generative boundary fuzzing) deliberately NOT scheduled — #143's counted comparison picks the target first, per the issue's own recommendation. rated 80/65/85/55. → [GH-141-FUZZ-ATE-UTILITY.md](PROJECT/2-WORKING/GH-141-FUZZ-ATE-UTILITY.md) · [#141](https://github.com/HiQS-Suite/XYZ-forge/issues/141) · [#142](https://github.com/HiQS-Suite/XYZ-forge/issues/142) · [#146](https://github.com/HiQS-Suite/XYZ-forge/issues/146)
- **GH-5 · kernel robustness: node:test unit runner** 🆕 **active 2026-08-15 on `gh-5/events-quarantine-unit-tests` (public-repo tracker)** — 11 direct unit tests on the built-in `node:test` runner (was 13; the 2 quarantine-dependent tests deferred to #14), zero new dependencies, `npm run test:unit`, `npm test` → `validate.sh` unchanged. The quarantine-in-reader approach was rejected on orchestrator review per the correction on #5 (silent event loss on the concurrent path while writes are non-atomic) and re-routed to #14. **#5 stays open until this PR's tests and #14's atomic write have both landed.** rated 45/40/45/80. → [GH-5-EVENTS-QUARANTINE-UNIT-TESTS.md](PROJECT/2-WORKING/GH-5-EVENTS-QUARANTINE-UNIT-TESTS.md) · [#5](https://github.com/HiQS-Suite/XYZ-forge/issues/5)
### Completed
- **GH-228 · Org rename HiQS-Suite → HiQS-Labs: a hardcoded regex silently drops issue URLs from the roadmap shadow** ✅ **SHIPPED 2026-08-24 (commit 64c2d2d1; issue closed)** — widen regex in releases_app.py to HiQS-(?:Suite|Labs), update default repo and remote in scripts, add regression test in gh69 suite. rated 80/60/75/90. → [GH-228-ROADMAP-ORG-RENAME-REGEX.md](PROJECT/3-COMPLETED/GH-228-ROADMAP-ORG-RENAME-REGEX.md) · [#228](https://github.com/HiQS-Labs/XYZ-forge/issues/228)
- **GH-226 · xyz-vendor.sh transcript gate refuses repos that gitignore transcripts** ✅ **SHIPPED 2026-08-24 (commit 654e4440, QA 3ee2e8f0; issue closed)** — downgrade transcript gitignore check from exit 6 to advisory warning so downstream repos can vendor `.xyz/`. rated 75/50/80/85. → [GH-226-VENDOR-TRANSCRIPT-GATE.md](PROJECT/3-COMPLETED/GH-226-VENDOR-TRANSCRIPT-GATE.md) · [#226](https://github.com/HiQS-Labs/XYZ-forge/issues/226)
- **GH-114 · headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7)** ✅ **SHIPPED 2026-08-24 (PR #214)** — force fully headless invocation (no /dev/tty), and make idle-kills name the real blocker in the turn log. rated 80/60/80/60. → [GH-114-HEADLESS-TTY-IDLE-HANG.md](PROJECT/2-WORKING/GH-114-HEADLESS-TTY-IDLE-HANG.md) · [#114](https://github.com/HiQS-Suite/XYZ-forge/issues/114)
- **GH-113 · headless agy builder writes root scratch files, tripping containment (exit 6)** ✅ **SHIPPED 2026-08-24 (PR #214)** — give headless builder turns a sanctioned scratch lane (.relay-scratch/<turn>/) so debugging temp files relocate instead of failing the turn; tracked-file violations still exit 6. rated 85/60/85/60. → [GH-113-HEADLESS-SCRATCH-CONTAINMENT.md](PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md) · [#113](https://github.com/HiQS-Suite/XYZ-forge/issues/113)
- **GH-91 · a build turn has nowhere to write verification output ** ✅ **SHIPPED 2026-08-24 (PR #214)** — containment kills a complete, green turn** ✅ **CLOSED 2026-08-22 (issue closed; ledger reconciled)** — issue option 1: `.relay-scratch/` as an intrinsic write category — pre-created by `rtl_worktree_begin`, exempted in `rtl_worktree_end` (no signature check; never copied back), exempted-and-discarded in `rtl_check` (non-worktree path), and NAMED in `rtl_turn_prompt` at the point of use. New suite `test/gh91-relay-scratch.sh` 15/0 with controls (stray still exit-6, lookalike prefix not exempt, off-lane copies nothing back); containment-pinning neighbors green. Surfaced by the daybreak wave-1 re-fire after #90. rated 60/65/55/75. → [GH-91-RELAY-SCRATCH-DIR.md](PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md) · [#91](https://github.com/HiQS-Suite/XYZ-forge/issues/91)
- **GH-168 · wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR** ✅ **SHIPPED 2026-08-24 (PR #220)** — scope the drift check to the reconciled PR; unrelated drift warns without rollback; move-not-add idempotent promotion. rated 80/55/85/70. → [GH-168-WAVE-RECONCILE-SCOPE.md](PROJECT/2-WORKING/GH-168-WAVE-RECONCILE-SCOPE.md) · [#168](https://github.com/HiQS-Suite/XYZ-forge/issues/168)
- **GH-50 · sandboxed git --track / branch -D half-applies and loses uncommitted work** ✅ **SHIPPED 2026-08-24 (PR #220)** — branch ops refuse-or-succeed atomically when .git/config is unwritable. rated 65/35/85/80. → [GH-50-SANDBOXED-GIT-HALF-APPLY.md](PROJECT/2-WORKING/GH-50-SANDBOXED-GIT-HALF-APPLY.md) · [#50](https://github.com/HiQS-Suite/XYZ-forge/issues/50)
- **GH-2 · test-suite run relocated an untracked file into .tick/orphan-backups/** ✅ **SHIPPED 2026-08-24 (PR #220)** — reproduce under parallel load, then guard every mv/rm/find-delete on a derived path with resolved containment. rated 80/55/85/55. → [GH-2-ORPHAN-BACKUP-RELOCATION.md](PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md) · [#2](https://github.com/HiQS-Suite/XYZ-forge/issues/2)
- **GH-202 · wave_reconcile aborts on marathon-plan exit 5 (items held) and promotes capture docs for OPEN issues** ✅ **SHIPPED 2026-08-24 (PR #210)** — hotfix, the reconciler sits on every merge critical path** — tolerate the items-held planning state (log + continue), and consult the linked issue's open/closed state before promoting a doc: OPEN keeps the doc active with recorded merge evidence (idempotent), unknown state promotes as before (offline-manifest backward compat). rated 85/65/85/70. → [GH-202-WAVE-RECONCILER-STATE.md](PROJECT/2-WORKING/GH-202-WAVE-RECONCILER-STATE.md) · [#202](https://github.com/HiQS-Labs/XYZ-forge/issues/202)
- **GH-197 · two-tier xyz-vendor.sh: Tier 1 core-harness default, Tier 2 opt-in RELEASES overlay + onboarding SOP (GH-105 follow-up)** ✅ **SHIPPED 2026-08-24 (PR #210)** — deny-list tier split in `materialize_vendor()` (`--with-releases`), sticky Tier 2 auto-detect via `releases.db` at target root for the 9 vendored repos, and `xyz-releases-onboard.sh` mechanizing the LTVera-Pandas `ad0d816` onboarding (import, gitignore carve-out, banner, MIG- reconcile with shared-tracking-URL refusal, no auto-commit). rated 80/55/65/50. → [GH-197-VENDOR-TIER-SPLIT.md](PROJECT/2-WORKING/GH-197-VENDOR-TIER-SPLIT.md) · [#197](https://github.com/HiQS-Suite/XYZ-forge/issues/197)
- **GH-193 · AgentChorus Gen 2 ** ✅ **SHIPPED 2026-08-24 (PR #210)** — telemetry, decision-quality metrics, measurable experiments (Agent2Agent renamed)** 🚧 **active 2026-08-24 for release 0.7.3 "Bulkhead" (#179); Phases 0-1 SHIPPED (PR #196, PR #200 2026-08-24 — telemetry + registry + outcome + audit + data policy; suite 142/142); pilot window running; phases 2-3 continue** — make discussion decisions measurable: metadata-only telemetry with a structural no-content allowlist, a store-level aggregate registry, per-model outcome attribution, supersession/lifecycle verbs, verify-citations with ref pinning, and experiment flags (steelman, stance prior) gated on the ≥10-discussion pilot corpus. rated 75/70/85/50. → [GH-193-AGENTCHORUS-GEN2.md](PROJECT/2-WORKING/GH-193-AGENTCHORUS-GEN2.md) · [#193](https://github.com/HiQS-Labs/XYZ-forge/issues/193)

- **GH-1 · suite-wide fixture containment + clone-identity invariant gate** ✅ **SHIPPED 2026-08-24 (PR #210)** — the detect-half (`test/lib/clone-identity.sh` bracket in `validate.sh`) and the shared resolved-containment `require_fixture` (`test/lib/fixture-guard.sh`) landed via PR #6; the reopen condition "#1 closes when #10's acceptance lands" fired when `31c31b7` delivered the derived-from-source adoption guard (`test/gh1-adoption-guard.sh`, no hand-maintained exception list) + ci-local identity bracket and the operator closed #10. Verified at close: gh1-fixture-guard 17/0, gh1-adoption-guard 11/0. → [GH-1-SUITE-CONTAINMENT-GATE.md](PROJECT/2-WORKING/GH-1-SUITE-CONTAINMENT-GATE.md) · [#1](https://github.com/HiQS-Suite/XYZ-forge/issues/1)
- **GH-174 · Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator** ✅ **SHIPPED 2026-08-23 (PR #174; issue closed)** — migrate static HARNESS-MODELS-REGISTRY.md into active SQLite ledger (harnesses.db) with DRY per-device configs, reasoning level tracking, deterministic post-turn AI grading hooks, and automated blog generation. rated 85/75/95/45. → [GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md](PROJECT/3-COMPLETED/GH-174-HARNESS-MODELS-SQLITE-REGISTRY.md) · [#174](https://github.com/HiQS-Suite/XYZ-forge/issues/174)
- **GH-115 · marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4)** ✅ **SHIPPED 2026-08-23 (PR #194; Bulkhead wave)** — progress-aware bounded cap extension + per-phase cap override; stalled caps still escalate. rated 75/50/85/70. → [GH-115-ROUND-CAP-ESCALATION.md](PROJECT/3-COMPLETED/GH-115-ROUND-CAP-ESCALATION.md) · [#115](https://github.com/HiQS-Suite/XYZ-forge/issues/115)
- **GH-8 · kernel boundary hardening — CLI numeric validation, task/agent format contract** ✅ **SHIPPED 2026-08-23 (PR #188; Bulkhead wave)** — reject NaN/malformed CLI input and unbounded task/agent strings at the boundary instead of persisting them. rated 75/55/80/65. → [GH-8-KERNEL-BOUNDARY-HARDENING.md](PROJECT/3-COMPLETED/GH-8-KERNEL-BOUNDARY-HARDENING.md) · [#8](https://github.com/HiQS-Suite/XYZ-forge/issues/8)
- **GH-180 · repro_builder crashes on timeout telemetry records (exit_code: null → TypeError)** ✅ **SHIPPED 2026-08-23 (PR #185; Bulkhead wave — Gen 3.5 soak cohort)** — map null-exit records to a first-class timeout signature instead of `int(None)`; the fuzzer's most common record class must build reproducers, not crash them. rated 70/45/85/80. → [GH-180-REPRO-TIMEOUT-CRASH.md](PROJECT/3-COMPLETED/GH-180-REPRO-TIMEOUT-CRASH.md) · [#180](https://github.com/HiQS-Labs/XYZ-forge/issues/180)
- **GH-181 · repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2)** ✅ **SHIPPED 2026-08-23 (PR #185; Bulkhead wave — Gen 3.5 soak cohort)** — telemetry schema 1.1 (`argv` list + realized `env` + failure signature, emitter side) and signature-matching ingest; the real GH-141 record becomes the permanent end-to-end regression fixture (#174's finding-travels-untouched criterion). rated 90/75/90/60. → [GH-181-REPRO-ADAPTER-FIDELITY.md](PROJECT/3-COMPLETED/GH-181-REPRO-ADAPTER-FIDELITY.md) · [#181](https://github.com/HiQS-Labs/XYZ-forge/issues/181)
- **GH-183 · active_explorer env-family fuzzing unsound (base_env={} hardcoded, one always-deferring vector, ambient-env leakage)** ✅ **SHIPPED 2026-08-23 (PR #185; Bulkhead wave — Gen 3.5 soak cohort)** — declared `--base-env` driving the full missing/empty/corrupted vector set from a clean environment; ambient `RELAY_*` provably cannot satisfy mutations. rated 65/50/75/70. → [GH-183-EXPLORER-ENV-SOUNDNESS.md](PROJECT/3-COMPLETED/GH-183-EXPLORER-ENV-SOUNDNESS.md) · [#183](https://github.com/HiQS-Labs/XYZ-forge/issues/183)
- **GH-184 · committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation** ✅ **SHIPPED 2026-08-23 (PR #185; Bulkhead wave — Gen 3.5 soak cohort)** — remove the PR #160 artifact and add a derived no-tracked-scratch guard, so the lane's by-design discard can never dirty a clone (success-shaped-exit mutation found in soak §3.5). rated 60/40/80/90. → [GH-184-TRACKED-SCRATCH-ARTIFACT.md](PROJECT/3-COMPLETED/GH-184-TRACKED-SCRATCH-ARTIFACT.md) · [#184](https://github.com/HiQS-Labs/XYZ-forge/issues/184)
- **GH-195 · marathon-root-audit's blind spot: a direct `python3 marathon_drive.py` call** ✅ **SHIPPED 2026-08-23 (in PR #194)** — GH-115's own new test committed a live transcript onto the real clone on every `validate.sh` run because `marathon-root-audit.sh` only audits `bash <driver>.sh` invocations, never a direct Python call; same defect class as GH-401, reopened via a different invocation shape. Root-caused via direct instrumentation after ~2.5h of correctly-reasoned-but-wrong process-hunting. rated 60/40/50/20. → [GH-195-MARATHON-ROOT-AUDIT-BLIND-SPOT.md](PROJECT/3-COMPLETED/GH-195-MARATHON-ROOT-AUDIT-BLIND-SPOT.md) · [#195](https://github.com/HiQS-Labs/XYZ-forge/issues/195)
- **GH-10 · prevent-half of containment: require_fixture adoption across the fixture-creating suites + adoption guard + ci-local identity bracket** ✅ **CLOSED 2026-08-22 (issue closed; ledger reconciled)** — resolves the 2026-08-17 marathon cut (enforcement without adoption) by adopting for real: `_setup.sh` centrally, 35 suites mechanically, 7 by hand (out-of-root fixtures nested under pinned sandboxes); `test/gh1-adoption-guard.sh` derives offenders from source every run (exemptions declared in-file — no permanent exception list), controls prove it fires; `ci-local.sh` gains the GH-1 identity bracket; ledger records **Unaudited suites: 0**. Drive-by: fixture-guard.sh shellcheck `-S error` fix (pre-existing ci-local red). rated 55/70/50/80. → [GH-10-REQUIRE-FIXTURE-ADOPTION.md](PROJECT/2-WORKING/GH-10-REQUIRE-FIXTURE-ADOPTION.md) · [#10](https://github.com/HiQS-Suite/XYZ-forge/issues/10)
- **GH-35 · 3-tier test suite selection (docs / utility subsystems / core) + CPU governance** ✅ **Phases 1+2 BUILT 2026-08-18 on `development` (standalone clone `XYZ-forge-gh35`)** — one fail-closed subsystem registry in `utils/ci-route.sh` (hq, releases, telemetry, ate, swe-diagram, pdda, agent2agent) consumed by `githooks/pre-push` and `validate.sh`; `--tier/--subsystem/--auto/--paths-file`; the parallel default rebalanced from `cores-2` (up to 8) to `cores/2` (cap 4) with every worker under `nice -n 10`, plus `--throttle`/`--burst`/`XYZ_VALIDATE_THROTTLE`/`XYZ_VALIDATE_MAX_JOBS`. Utility pushes drop from the full ~4-min pool to their focused suites (~20-45s target, measurement owed). New suite `test/gh35-test-tiers.sh` 56/0; pre-push suite extended to 85/0. Phase 3 (CI alignment + every-file-classified sweep) pending. rated 55/45/50/45. → [GH-35-TEST-TIER-ROUTING.md](PROJECT/2-WORKING/GH-35-TEST-TIER-ROUTING.md) · [#35](https://github.com/HiQS-Suite/XYZ-forge/issues/35)
- **GH-42 · relay automation: supported Commandcode turn-taker** ✅ **CLOSED 2026-08-22 (issue closed; ledger reconciled)** — add a Python-authoritative, containment-preserving Commandcode adapter with mocked regression coverage; Muse Spark Contributor is the initial builder and Codex performs independent QA. rated 50/35/55/45. → [GH-42-COMMANDCODE-TURN.md](PROJECT/2-WORKING/GH-42-COMMANDCODE-TURN.md) · [#42](https://github.com/HiQS-Suite/XYZ-forge/issues/42)
- **GH-170 · Agent2Agent: close transcript glitches and harden publishing** ✅ **CLOSED 2026-08-22 (issue closed; ledger reconciled)** — external canonical transcript store with required producer packets, structured scope extension and close operations, verified Git handoffs, heartbeat-aware stale reporting, and a manifest-driven drift-refusing standalone publisher with downstream CI (HiQS-Labs/Agent2Agent-Skill#1–5). rated 75/60/85/55. → [GH-170-AGENT2AGENT-GLITCHES.md](PROJECT/2-WORKING/GH-170-AGENT2AGENT-GLITCHES.md) · [#170](https://github.com/HiQS-Suite/XYZ-forge/issues/170)
- **GH-165 · Post-Merge Wave & Marathon Lifecycle Reconciler (Docs, ROADMAP, DB, Views, and Planning)** ✅ **CLOSED 2026-08-22 (issue closed; ledger reconciled)** — implement the canonical Python post-merge wave and marathon lifecycle reconciler (`utils/py/wave_reconcile.py`) to atomically transition active docs from `2-WORKING` to `3-COMPLETED`, archive `ROADMAP.md` entries, sync `releases.db`, rebake dashboard views, and compute next-wave concurrency plans without split-brain script sprawl. rated 90/80/90/35. → [GH-165-POST-MERGE-WAVE-RECONCILER.md](PROJECT/1-INBOX/GH-165-POST-MERGE-WAVE-RECONCILER.md) · [#165](https://github.com/HiQS-Suite/XYZ-forge/issues/165)
- **GH-124 · eliminate end-of-day closeout friction — automated phase QA receipts, auto-PR creation, and clone lifecycle hygiene** ✅ **CLOSED 2026-08-22 (issue closed; ledger reconciled)** — eliminate 50+ minutes of daily closeout friction: on-disk local gate receipts (`ci-local.sh` / `validate.sh`), driver-refreshed early drift alerts, safe manifest-bounded workspace sweep with soft quarantine, hardened `marathon-closeout.sh`, and post-gate in-flight QA attestation comments. rated 85/60/90/40. → [GH-124-CLOSEOUT-AUTOMATION.md](PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md) · [#124](https://github.com/HiQS-Suite/XYZ-forge/issues/124)

codex
The ledger confirms Linux-RC’s goalpost is a qualifying 100% green Ubuntu run, not merely completion of its seven manifest rows; I’m now checking the release-planning contract and the ranked work’s actual dependencies.
 exited 3 in 36361ms:
2026-08-25 22:35:17.056 xcodebuild[31182:7650625]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:17.437 xcodebuild[31182:7650624] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-FeS46TRQ' (errno=Operation not permitted)
2026-08-25 22:35:18.240 xcodebuild[31184:7650665]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:18.479 xcodebuild[31184:7650663] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
rel-01M0BTBRMJJHRS147J73WWGGEJ  0.1.0    Quicksilver  shipped  target=2026-08-01 shipped=- tracking=MIG-F1CCB6 items=0
rel-01M0BTBRMJW4B6HWAHKW82GFGS  0.2.0    Litmus       shipped  target=2026-09-05 shipped=2026-08-14 tracking=MIG-D7D2C4 items=0
rel-01M0BTBRMJNQM0474RQEYWKJKV  0.3.0    Nightwatch   shipped  target=2026-10-10 shipped=2026-08-14 tracking=MIG-D248B2 items=0
rel-01M0BTBRMJ4GE194HWHJJS2AV2  0.4.0    Plumbline    draft    target=2026-11-14 shipped=- tracking=MIG-79F036 items=0
rel-01M0BTBRMKEYXGKWR47HX3S72J  0.5.0    Lantern      draft    target=2026-12-12 shipped=- tracking=MIG-A993B3 items=0
rel-01M0BTBRMKX17AQN7Q11A0YCD7  0.6.0    Meter        draft    target=2026-09-26 shipped=- tracking=MIG-751A4C items=0
rel-01M0BTBRMKKDB5TCEXT75BTFJY  0.7.0    Ballast      shipped  target=2026-09-12 shipped=2026-08-18 tracking=MIG-7AFFE1 items=0
rel-01M0BTBRMKFFDNYP04S68XWAPF  0.8.0    Sundown      draft    target=2026-10-17 shipped=- tracking=MIG-AC68FA items=0
rel-01M0DEBCZP752VYW4A3N2Q3YS9  0.7.1    Bulwark      shipped  target=2026-08-20 shipped=2026-08-19 tracking=https://github.com/HiQS-Suite/XYZ-forge/issues/32 items=3
rel-01M0EC3AGK2DWYAC1WV7FMG2Q6  0.7.2    Daybreak     shipped  target=2026-08-26 shipped=2026-08-23 tracking=https://github.com/HiQS-Suite/XYZ-forge/issues/77 items=10
rel-01M0GKP4YGTHVTXHVV5WAP08B5  0.9.0    Cargo        draft    target=2026-09-19 shipped=- tracking=https://github.com/HiQS-Suite/XYZ-forge/issues/105 items=7
rel-01M0PJK2P8VNVJPH47BJDJG77D  0.7.3    Bulkhead     shipped  target=2026-09-05 shipped=2026-08-25 tracking=https://github.com/HiQS-Suite/XYZ-forge/issues/179 items=16
rel-01M0V6GTR1A4GX40D9CADEQA59  0.7.4    Linux-RC     active   target=2026-09-05 shipped=- tracking=https://github.com/HiQS-Labs/XYZ-forge/issues/224 items=7
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-PRwMsV2g' (errno=Operation not permitted)
2026-08-25 22:35:22.426 xcodebuild[31206:7650835]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:22.621 xcodebuild[31206:7650834] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-XMvWAUPx' (errno=Operation not permitted)
2026-08-25 22:35:23.250 xcodebuild[31211:7650875]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:23.448 xcodebuild[31211:7650874] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
refused: rule=unknown-gid: no release with global id '0.7.4'
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-sDIPBR9z' (errno=Operation not permitted)
2026-08-25 22:35:27.341 xcodebuild[31226:7650971]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:27.543 xcodebuild[31226:7650970] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-aep3vVie' (errno=Operation not permitted)
2026-08-25 22:35:28.182 xcodebuild[31228:7650981]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:28.398 xcodebuild[31228:7650980] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
refused: rule=unknown-gid: no release with global id '0.9.0'
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-7JPzeb9u' (errno=Operation not permitted)
2026-08-25 22:35:32.328 xcodebuild[31248:7651170]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:32.528 xcodebuild[31248:7651168] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-7QzSWnL4' (errno=Operation not permitted)
2026-08-25 22:35:33.149 xcodebuild[31251:7651187]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:33.356 xcodebuild[31251:7651186] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
refused: rule=unknown-gid: no release with global id '0.4.0'
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-Z0u75Q0t' (errno=Operation not permitted)
2026-08-25 22:35:37.375 xcodebuild[31277:7651359]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:37.591 xcodebuild[31277:7651357] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-wbmDSFkw' (errno=Operation not permitted)
2026-08-25 22:35:38.232 xcodebuild[31283:7651381]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:38.463 xcodebuild[31283:7651378] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
refused: rule=unknown-gid: no release with global id '0.5.0'
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-klRVSFgu' (errno=Operation not permitted)
2026-08-25 22:35:42.562 xcodebuild[31315:7651627]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:42.778 xcodebuild[31315:7651623] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-1bRadm73' (errno=Operation not permitted)
2026-08-25 22:35:43.445 xcodebuild[31320:7651644]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:43.643 xcodebuild[31320:7651643] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
refused: rule=unknown-gid: no release with global id '0.6.0'
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-spIhoKI6' (errno=Operation not permitted)
2026-08-25 22:35:47.683 xcodebuild[31346:7651862]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:47.898 xcodebuild[31346:7651861] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-C1ZZeuCz' (errno=Operation not permitted)
2026-08-25 22:35:48.539 xcodebuild[31348:7651910]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:48.742 xcodebuild[31348:7651876] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
refused: rule=unknown-gid: no release with global id '0.8.0'

exec
/bin/zsh -lc "python3 utils/py/releases_app.py show --version 0.4.0 --full
python3 utils/py/releases_app.py show --version 0.5.0 --full
python3 utils/py/releases_app.py show --version 0.6.0 --full
python3 utils/py/releases_app.py show --version 0.8.0 --full
python3 utils/py/releases_app.py show --version 0.9.0 --full
rg -n -C 5 'RELEASES.md|release ledger|gate first|Gate first|Litmus|Nightwatch|target|Version|version' PROJECT/PDDA.md RELEASES.md | head -n 400
rg -n -C 3 '#249|#251|#252|#141|#67|#216|#75|#215|#243|#222|#204|#205|#123|#232|#233' LEADERBOARD.md | head -n 500" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-30948-51ksahqx
 succeeded in 24806ms:
2026-08-25 22:35:56.063 xcodebuild[31382:7652109]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:56.262 xcodebuild[31382:7652108] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-4iihZRcj' (errno=Operation not permitted)
2026-08-25 22:35:56.884 xcodebuild[31387:7652152]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:35:57.079 xcodebuild[31387:7652151] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
GID:           rel-01M0BTBRMJ4GE194HWHJJS2AV2
Release:       0.4.0
Status:        draft
Codename:      Plumbline
Target Date:   2026-11-14
Milestone:     Plumbline
GH_URL:        https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/431
Description:   Assisted reflection and a bounded self-improvement loop, measured before either is trusted. The reflection pipeline turns durable Nightwatch records into proposals (`proposals-sink.sh` gains its first production caller) and is graded against external ground truth — the 49 human-filed findings from the two rebalance-OS marathons (#405/#406) — for recall and precision. Ships a committed benchmark and a recorded go/no-go; "not worth automating yet" is a passing result, per #431's own Phase 2 exit criterion. Operator sign-off stays manual. Depends on Nightwatch.
Front-door reviewed: No
Shakedown reviewed: No
License file:  Yes
Tracking:      MIG-79F036
Manifest:      0 item(s)
Legacy lines:  1 (imported verbatim, pending disposition)
  | Iterations: 0.4.0-0.4.4
Grandfathered: description-length x1, gh-url-normalized x1, tracking-issue-missing x1
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-pJTGO2m7' (errno=Operation not permitted)
2026-08-25 22:36:00.972 xcodebuild[31405:7652302]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:36:01.172 xcodebuild[31405:7652301] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-tSaCe1fQ' (errno=Operation not permitted)
2026-08-25 22:36:01.795 xcodebuild[31407:7652313]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:36:01.992 xcodebuild[31407:7652312] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
GID:           rel-01M0BTBRMKEYXGKWR47HX3S72J
Release:       0.5.0
Status:        draft
Codename:      Lantern
Target Date:   2026-12-12
Milestone:     not created yet. The original reason — "#499 is unmilestoned by design while Nightwatch is the active goalpost" — expired when Nightwatch reached RC on 2026-08-11, and is kept here only so a reader does not act on it as if current. Creating it is a live decision, not a formality: **neither member would be enumerable by it as things stand** (#499 is unmilestoned, and #358 keeps its Nightwatch milestone deliberately), so the milestone would join nothing until #499 is assigned. The `Manifest:` line below is this release's authoritative scope either way.
GH_URL:        https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/499
Description:   When the harness fails, the information needed to act already exists inside it — make it say so. Not "add checks": every case was already detected, and some were then described wrongly (a stack trace, a fabricated path, a success exit code, silence). Scope is one epic, deliberately narrow, and deliberately NOT Nightwatch: that milestone owns run lifecycle "even when lifecycle code emits a misleading message" (see the scope boundary above), and none of Lantern's cases violates a lifecycle invariant — they violate the legibility of a failure whose lifecycle handling was already correct. All four members were found in one afternoon during Nightwatch wave 3, which halted three times at zero paid-turn cost; each halt was avoidable from information the system already held. Depends on nothing; independent of Plumbline.
Exit criterion: `bash test/lantern-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it precedes fixing any member, which is the Litmus and Nightwatch ordering and the reason both releases could tell a finished entry from a claimed one. Two halves, the established shape: Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below. Half B **executes** #499's four phases rather than auditing them, since every one of them is a message an operator either receives or does not: a `relay-drive` launch preflight that refuses before spending, a gate refusal that states its real reason, a launcher exit code that survives its wrapper, and a change-impact report. **#358 Phase 2 is the one member with no executable half, and the criterion is written around that rather than pretending otherwise:** it is satisfied by a RECORDED transcript of a real CI failure under `test/baselines/`, and it must NOT be satisfiable by a disposition written in advance — that issue's own capture doc forbids pre-committing one, and an exit criterion that accepted a pre-written verdict would launder exactly the thing #419 exists to prevent. Its own negative control is `--mutate-evidence`, which must unregister a gate, delete a recorded control, and substitute a pre-dated disposition for a real transcript — detecting all three, and re-checking the unmutated inputs green in the same run so an always-red detector cannot pass for one.
Front-door reviewed: No
Shakedown reviewed: No
License file:  Yes
Tracking:      MIG-A993B3
Manifest:      0 item(s)
Legacy lines:  2 (imported verbatim, pending disposition)
  | Iterations: 0.5.0-0.5.4
  | Manifest: FROZEN at one issue on creation — #499, which supersedes and closes #494, #495, #496 and #498. Four phases, each shippable alone: relay-drive launch preflight; a gate refusal that states its real reason; a launcher whose exit code survives plus a gate-readiness check; and a change-impact reporter. Freezing at one is the whole point — these were filed as four and unified precisely to stop a single coherent change spreading across four PRs. **RE-FROZEN AT TWO on 2026-08-11 by explicit operator decision — #499, plus #358 Phase 2.** Recorded as a re-scope rather than an edit, because the admission rule below is worthless if a manifest can grow quietly: the operator named the entry and the release, which is the documented way past the rule, and this line says so with a date instead of just showing two items where there was one. It is a genuine fit, not a parking space — Phase 2 is a *disposition* that turns a lost concurrent-append record into a failure naming its own terminal lock state, which is Lantern's subject exactly, whereas the run lifecycle it sits inside was already handled correctly (that is the Nightwatch boundary, and it is why Phase 1 belonged there and Phase 2 does not). It was briefly a Meter member the same day and moved here before either release started; Meter's block records the move from its side. **#358 keeps its Nightwatch milestone** — it is a frozen entry counted in Nightwatch's RC evidence, so only its scope moved, and this is the second Lantern member not enumerable by `gh issue list --milestone Lantern`. Adding a further member is a RE-SCOPE, not a bugfix, per the Litmus rule above.
Grandfathered: description-length x1, exit-criterion-length x1, gh-url-normalized x1, tracking-issue-missing x1
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-AZBKt9BH' (errno=Operation not permitted)
2026-08-25 22:36:05.893 xcodebuild[31422:7652448]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:36:06.087 xcodebuild[31422:7652427] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-5gNfFPdv' (errno=Operation not permitted)
2026-08-25 22:36:06.713 xcodebuild[31427:7652459]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:36:06.910 xcodebuild[31427:7652458] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
GID:           rel-01M0BTBRMKX17AQN7Q11A0YCD7
Release:       0.6.0
Status:        draft
Codename:      Meter
Target Date:   2026-09-26
Milestone:     Meter
GH_URL:        https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/563
Description:   XYZ can be handed to a stranger: an unauthenticated clone reaches a documented entry path and exercises a supported happy path with no private context, from a sanitized, secret-scanned tree. RE-SCOPED 2026-08-15 by explicit operator decision — originally the metering release; that work moved intact to Sundown (0.8.0). Deliverable is a sanitized fresh-history clone pushed to https://github.com/HiQS-Suite/XYZ-forge. Compacted 2026-08-20 with the RELEASES.md block; full prose in that file's git history.
Exit criterion: bash test/meter-release.sh --release-gate exits 0. NOT BUILT — written first, before any sanitization (the Litmus/Nightwatch ordering). Half A AUDITS the launch artifact: single-commit sanitized clone at the declared path; CHANGELOG.md byte-identical; .tick/, relay-system/, temp/ absent; PROJECT/ = PDDA scaffold + retained Meter example only; both LICENSE files present and consistent; secret-scan result names tool version and exact commit. Half B EXECUTES the stranger's path: a credential-less clone of the published commit completes one supported happy path with nothing author-machine-local. Negative control --mutate-evidence: plant a private path, remove CHANGELOG.md, leave a relay-system/ behind — detect all three, re-check unmutated inputs green in the same run. RED on arrival.
Front-door reviewed: Yes
Shakedown reviewed: Yes
License file:  Yes
Tracking:      MIG-751A4C
Manifest:      0 item(s)
Legacy lines:  6 (imported verbatim, pending disposition)
  | Iterations: 0.6.0-0.6.4
  | **RE-SCOPED 2026-08-15 by explicit operator decision — Meter is now the public-repository release candidate, and the paragraph above describes what Meter *was*.** The new sentence is: **XYZ can be handed to a stranger.** An unauthenticated clone reaches a documented entry path and exercises a supported happy path with no private context, from a tree that has been sanitized and secret-scanned. The metering work was not abandoned and it was not finished — five of its seven entries moved intact to Sundown (0.8.0), where they keep their capture docs, their acceptance criteria and their evidence. Recorded here as a re-scope with a date rather than presented as a release that always meant this, because a codename that quietly changes its subject is the same defect as a manifest that quietly grows. The reason for reusing Meter rather than opening an eighth release is that the operator named it: publication is the next thing that happens to this repository, and a launch release parked behind five unrelated engineering entries would have shipped late for reasons that have nothing to do with whether a stranger can clone it.
  | Publication target — **the deliverable is a sanitized clone, not this repository.** The public artifact is a new working tree cut from `development`, stripped of runtime state and internal working documents, committed as **fresh history with a single initial commit**, and pushed to **https://github.com/HiQS-Suite/XYZ-forge** — a new repository in a different organization, named by the operator on 2026-08-15, which becomes XYZ's permanent home. `CHANGELOG.md` is carried forward verbatim and is the public record of the project's history — it is a *file*, so it survives a fresh-history cut intact, and carrying 2,147 commits was rejected on 2026-08-15 for a stated reason: every document removed during sanitization stays reachable in a carried history, which makes the full-history secret scan this release requires a scan of everything ever deleted rather than a scan of one tree. Fresh history makes the sanitization complete by construction. `.tick/` (161 MB of runtime event state) and `relay-system/` (32 MB of relay transcripts) do not ship. `PROJECT/` ships as an **empty PDDA scaffold** plus the Meter build documents retained deliberately as a worked example of how PDDA is used — the method travels, the backlog does not.
  | Scope boundary — Meter vs Lantern: **Lantern owns how a failure is described; Meter owns what a run consumed and what it required.** Route by asking whether the issue names a *resource or a precondition* — dollars, turns, memory, swap, a trusted directory, a green suite — or names *the wording of a verdict whose handling was already correct*. Written down because two members straddle it and the file already has one recorded case (Litmus vs Nightwatch, 2026-08-08) of two descriptions that a competent agent could not route between. **#379 is split by that rule and belongs to both:** the overloaded exit 5 is a Lantern-shaped naming defect, the budget itself is a Meter resource, and the scope boundary above says to split an issue that violates both rather than argue it into one. **#491 is the marginal call and is placed here deliberately** — the re-scoped defect is a help-text and discoverability gap, which reads Lantern, but the invariant it violates is that the harness re-spends paid turns whose results it already holds, and the issue's evidence is a cost measurement.
  | Manifest: FROZEN 2026-08-11 on creation — #378, #379, #380, #382, #491. **RE-SCOPED TO SIX on 2026-08-12 by explicit operator decision: #509 admitted.** **RE-SCOPED TO SIX on 2026-08-14 (second decision the same day): #509 RETIRED as complete.** Its two unchecked criteria are not unfinished work — they are blocked by a LATER deliberate decision, GH-544, which retired hosted CI for the private phase. *"A push cannot cancel a running workflow_dispatch boundary run"* is now vacuously true and permanently unwitnessable: `ci.yml` carries only `workflow_dispatch:`, so no push can start a run, and you cannot control-test an interaction between two triggers when one of them no longer exists. *"A green hosted macOS full run exists for a chosen commit"* cannot be satisfied without spending the Actions minutes #509 existed to stop and #544 formally stopped. GH-544 already records that debt in its own terms and owns the re-arm trigger (the repo goes public), so keeping #509 open under Meter tracked the same gap twice while making the manifest look one item larger than it is. Phases 1-5 shipped. **RE-SCOPED TO SIX on 2026-08-14 by explicit operator decision: #551 admitted, and the target date pulled in from 2027-01-16 to 2026-09-26 in the same decision.** Recorded as a dated re-scope for the third time rather than shown as a list that has always had seven — the admission rule is worthless if a manifest can grow quietly, and it is worth as little if the third growth is the one that stops being announced. #551 is the shared root cause under nine open issues (#272, #310, #329, #365, #395, #504, #548, plus the already-closed #314/#440/#549) in which a resolver that cannot determine its answer returns a plausible default instead of refusing. It is a genuine fit on this block's own routing question — it names a **precondition**, not a description of a failure, so it is Meter and not Lantern — and two of its nine (#380, #491) were already Meter members, which is what surfaced it: they were being worked as separate defects when they are one. **RE-SCOPED TO SEVEN on 2026-08-15 by explicit operator decision: #555 admitted.** Recorded as a dated re-scope for the fourth time. #555 is the release's own exit criterion — the prerequisite for the other six being verifiable — so it ships first. The seven frozen manifest entries are #378, #379, #380, #382, #491, #551, and #555. **The date moved because Nightwatch shipped.** This release's only dependency was Nightwatch (#382's numbers needed a durable place to land), that shipped 2026-08-14, and Meter has been unblocked since — January was a date set while its blocker was still open and never revisited when the blocker cleared. Adding a further member is a RE-SCOPE, not a bugfix, under the unchanged rule below. Recorded as a re-scope with a date rather than shown as a list that has always had six, because the admission rule below is worthless if a manifest can grow quietly. It is a genuine fit, not a parking space: GH-509 is CI minute burn and route correctness — what a run costs and what it checks before spending — which is this release's sentence almost verbatim. The operator named the entry and the release, which is the documented way past the rule. Its plan is `PROJECT/2-WORKING/GH-509-CI-MINUTE-BURN.md`, replanned the same day on the macOS-target reframe and reviewed by agy. All six are milestoned Meter, so the ledger and `gh issue list --milestone Meter` cannot drift apart. **#358 Phase 2 was a member for part of 2026-08-11 and was moved to Lantern by operator decision the same day, before any Meter work began.** Recorded rather than quietly dropped: a frozen manifest whose membership changes without a trace is not frozen, and the honest version of "we got the routing wrong for an afternoon" is a dated line, not a clean list. It was the only entry blocked on an *observation* rather than on work, and the only one with no executable half — both of which now sit in Lantern's exit criterion, which is where the reasoning for them lives. The move is also correct on the boundary this block defines: Phase 2 produces a failure that states its own reason, which is Lantern's subject, not a resource or a precondition. Adding an entry is a RE-SCOPE, not a bugfix, under the same admission rule Litmus and Nightwatch used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission. **RE-SCOPED TO TWO on 2026-08-15 by explicit operator decision — the fifth dated re-scope of this manifest, and the only one that replaces the release's subject rather than extending it.** The seven engineering entries are dissolved. **#380 is CLOSED and shipped under the original scope**; it stays milestoned Meter as delivered work and is not a launch member — retiring a manifest does not un-ship what it produced. **#378, #379, #382, #491 and #551 move intact to Sundown (0.8.0)**, keeping their capture docs, their verbatim acceptance criteria and their milestone history; none of them was dropped, deferred without a home, or quietly closed. **#546 moves with them as Sundown backlog** — it was Meter milestone backlog and never a manifest entry, and it follows the subject it belongs to rather than the codename it happened to sit under. **The two frozen launch entries are #555 and #563.** #555 is the release's own exit criterion, re-pointed by the paragraph above and unchanged in its role: it ships first and it arrives RED. #563 is the launch checklist authored by an external reviewer (Codex Sol High) and covers the release boundary, public onboarding and behavior, the secret and privacy review, and the legal/CI/publication sequence. Freezing at two is the Plumbline precedent (frozen at one on creation) and is deliberate: the checklist was written as one coherent cutover and splitting it across issues is exactly what that precedent exists to prevent. **Scope is CLOSED to further admission by explicit operator instruction on 2026-08-15** — no issue filed after this date joins this manifest, and the standing admission rule below is superseded for this release only, because a launch whose scope can still grow does not have a date. Anything discovered during execution is filed, milestoned Sundown or left unmilestoned, and **waived in writing per #563's rule: a waiver names the failed criterion, the owner, the reason and the follow-up issue — silence is not a waiver.** Two known open items are covered by that rule rather than admitted: **#564** (31 unaudited suites that can reach the caller's clone through an empty fixture path) and **#544**'s re-arm debt (hosted CI fires on nothing while the repository is private, and going public is its own documented trigger). Both bear on publication and neither is a launch member; both need a waiver or a fix before the gate is called green.
  | Manifest-Members: 555 563
Grandfathered: exit-criterion-length x1, manifest-bare-numbers x1, tracking-issue-missing x1
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-Qc9hZgDi' (errno=Operation not permitted)
2026-08-25 22:36:10.805 xcodebuild[31445:7652603]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:36:10.998 xcodebuild[31445:7652602] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-fOffQDhO' (errno=Operation not permitted)
2026-08-25 22:36:11.626 xcodebuild[31447:7652611]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:36:11.826 xcodebuild[31447:7652610] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
GID:           rel-01M0BTBRMKFFDNYP04S68XWAPF
Release:       0.8.0
Status:        draft
Codename:      Sundown
Target Date:   2026-10-17
Milestone:     Sundown
Description:   Retire the twelve frozen Bash twins. Three steps, in order: (1) sweep for real `XYZ_PYTHON=0` usage — if nothing sets it, the fallback is already dead in practice; (2) re-vendor every fleet `.xyz/` copy onto the Python lane (`xyz-sync.sh list` is the worklist); (3) delete the twins and retire the GH-308 edit-guard, keeping only its no-new-Bash half (GH-551). Not before steps 1-2: the vendored fleet still runs the Bash path, and `XYZ_PYTHON=0` is the documented rollback. Depends on nothing in Meter.
Exit criterion: **NOT WRITTEN.** Required before this release starts, per the ordering Litmus and Nightwatch both used and Meter is repeating — the gate is built first and arrives RED, because a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one.
Front-door reviewed: No
Shakedown reviewed: No
License file:  Yes
Tracking:      MIG-AC68FA
Manifest:      0 item(s)
Legacy lines:  4 (imported verbatim, pending disposition)
  | Iterations: 0.8.0-0.8.4
  | **WIDENED 2026-08-15 by explicit operator decision — Sundown receives Meter's five engineering entries.** The release's sentence becomes: **the harness accounts for what it spends, checks what it requires before spending it, and stops carrying the retired Bash lane.** Said plainly rather than argued into one theme: the twin retirement and the metering work are two subjects sharing one release, and they are here together because Meter was re-pointed at publication on 2026-08-15 and these five needed a home that was not a parking space. They arrive intact — same capture docs under `PROJECT/2-WORKING/`, same verbatim acceptance criteria, same evidence — and the honest reading of the widening is that Sundown's date is now less trustworthy than it was, because it absorbed five entries without absorbing any schedule.
  | **RENUMBERED 0.7.0 → 0.8.0 on 2026-08-16 by explicit operator decision, to open 0.7.0 for Ballast.** Nothing about this release changed except its version: same codename, same target date, same manifest, same milestone. The band moves with it (`0.7.0-0.7.4` → `0.8.0-0.8.4`) because a release's iteration band is part of its identity here, not a separate fact. Recorded as a dated line rather than shown as a block that was always 0.8.0, on the same principle the manifest re-scopes above follow: a version that changes without a trace is indistinguishable from one that was misread. The `(0.7.0)` parentheticals in Meter's re-scope paragraphs were swept to `(0.8.0)` in the same edit — they identify *which release received the transfer*, so leaving them stale would have pointed a reader at a version that no longer exists. `CHANGELOG.md`'s existing entry is **not** swept: it is the append-only record of what was decided on 2026-08-15, when Sundown was 0.7.0, and the renumber is recorded there as its own dated entry instead.
  | Manifest: **#378, #379, #382, #491, #551, #28**, received from Meter 2026-08-15, plus the twin-retirement work described above, which remains unnumbered until its issues are filed. **#28** is the RELEASES.md ledger-discipline fix (parser continuation-folding + advisory bloat checks; see its capture doc for detail), added 2026-08-18 as a post-Ballast follow-up. **#546 is milestone backlog, not a manifest entry** — it followed the metering subject here and does not gate this release, under the standing rule that discovery is not admission. **Not yet frozen.** Freezing requires the twin-retirement issues to exist so the manifest is a fixed denominator rather than a list plus a promise; until then this line is a receipt for the transfer, not a contract. #380 did not move: it is CLOSED and shipped under Meter's original scope, and stays milestoned there.
Grandfathered: gh-url-unparsed x1, tracking-issue-missing x1
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-8HLe5RkS' (errno=Operation not permitted)
2026-08-25 22:36:15.792 xcodebuild[31465:7652783]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:36:16.004 xcodebuild[31465:7652782] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-ltTYS8jz' (errno=Operation not permitted)
2026-08-25 22:36:16.656 xcodebuild[31467:7652798]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:36:16.854 xcodebuild[31467:7652797] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
GID:           rel-01M0GKP4YGTHVTXHVV5WAP08B5
Release:       0.9.0
Status:        draft
Codename:      Cargo
Target Date:   2026-09-19
Milestone:     Cargo
Description:   The harness travels with its ledger: the RELEASES DB system (releases_app.py CLI + merge resolver + FAQs) and the GH-103 HTML timeline generator (utils/timeline/) ship inside every vendored .xyz/ payload as an optional, never-wired-by-default add-on — a 'when you're ready' module a target repo enables by running releases init itself, matching RELEASES.md's own OPTIONAL philosophy (GH-381). Sequenced before Meter by operator decision 2026-08-20.
Exit criterion: A repo vendored with xyz-vendor.sh can, with zero extra downloads, run releases init/add and export_timeline.py --preview from .xyz/ against its own root, and xyz-sync.sh update preserves the target's ledger state (GH-312 preserve list). Nothing runs until the user invokes it.
Tracking:      https://github.com/HiQS-Suite/XYZ-forge/issues/105
Manifest:      7 item(s)
  - https://github.com/HiQS-Suite/XYZ-forge/issues/105 [dialed_in]
  - https://github.com/HiQS-Suite/XYZ-forge/issues/107 [dialed_in]
  - https://github.com/HiQS-Labs/XYZ-forge/issues/201 [dialed_in]
  - https://github.com/HiQS-Labs/XYZ-forge/issues/182 [dialed_in]
  - https://github.com/HiQS-Labs/XYZ-forge/issues/193 [dialed_in]
  - https://github.com/HiQS-Labs/XYZ-forge/issues/222 [dialed_in]
  - https://github.com/HiQS-Labs/XYZ-forge/issues/223 [dialed_in]
RELEASES.md-1-# Major Releases
RELEASES.md-2-
RELEASES.md-3-Forward-looking planning ledger for major releases — one block per release, minimal fields, blank
RELEASES.md-4-line between blocks. Marathon plans and other forward planning cross-reference this doc for
RELEASES.md:5:target release names/dates; it is not a history of what shipped (that's CHANGELOG.md — lessons
RELEASES.md-6-learned belong there at ship time, not duplicated here). Contract lives in PROJECT/PDDA.md ->
RELEASES.md:7:"RELEASES.md — release ledger". Add new fields only when a real need shows up.
RELEASES.md-8-
RELEASES.md-9-## This file is OPTIONAL (GH-381)
RELEASES.md-10-
RELEASES.md-11-**Read this before proposing an edit to it.**
RELEASES.md-12-
RELEASES.md:13:`RELEASES.md` is an *optional planning aid*. It is not a required artifact, it is not a checklist,
RELEASES.md-14-and it is **not something to keep topped up**. An empty file, a stale file, or no file at all are
RELEASES.md-15-all perfectly valid states. The tooling agrees: `pdda.sh releases` is warn-only, never blocks, and
RELEASES.md:16:skips entirely when the file is absent — *"RELEASES.md not found — nothing to check."*
RELEASES.md-17-
RELEASES.md-18-**Do not offer to fill this in, populate it, bring it up to date, or add the release you just
RELEASES.md-19-shipped.** Do not treat a sparse file as an incomplete one. If nobody is actively planning a release
RELEASES.md-20-arc right now, the correct amount of content here is whatever is already present — including
RELEASES.md-21-nothing.
RELEASES.md-22-
RELEASES.md-23-Edit it only when an operator explicitly asks for release *planning*. That is the whole trigger.
RELEASES.md-24-
RELEASES.md:25:## Scope boundary — Litmus (0.2.0) vs Nightwatch (0.3.0)
RELEASES.md-26-
RELEASES.md-27-Added 2026-08-08 after a cross-model consult (codex + agy) found the two descriptions **not
RELEASES.md-28-decidable**: a competent agent could not route a new issue between them from the prose alone, because
RELEASES.md:29:Litmus says checks must "report red" correctly while Nightwatch says hostile states must "fail
RELEASES.md-30-clearly." Both advisors independently flagged this as blocking, and the overlap is worst exactly where
RELEASES.md-31-orchestration failures emit gate-looking verdicts.
RELEASES.md-32-
RELEASES.md:33:> **Litmus owns faulty decision semantics.** A named acceptance, preflight, reviewer, or pre-advance
RELEASES.md-34-> check returns pass, fail, or a *reason* inconsistent with a controlled input's observable outcome —
RELEASES.md-35-> or lacks a recorded negative control.
RELEASES.md-36->
RELEASES.md:37:> **Nightwatch owns run lifecycle.** Dispatch, target and worktree containment, claims, durable
RELEASES.md-38-> logging, interruption, and resume — **even when lifecycle code emits a misleading message.**
RELEASES.md-39->
RELEASES.md-40-> **Classify by the violated invariant, not by the wording of the message.** Split an issue that
RELEASES.md-41-> violates both.
RELEASES.md-42-
RELEASES.md:43:That last clause is the load-bearing one. The intuitive rule — "a lying message is Litmus" — gives the
RELEASES.md-44-wrong answer: #426 exits 6 claiming containment worked while a file leaked, but the invariant it
RELEASES.md:45:violates is run containment, so it is Nightwatch, with the assertion of its lie written as a
RELEASES.md:46:Litmus-style test. Conversely #407 reports `pre-advance-failed` when no gate ran, and that *is* a
RELEASES.md:47:Litmus defect, because the violated invariant is the verdict itself.
RELEASES.md-48-
RELEASES.md-49-**A release is not its milestone.** A milestone is a backlog and grows while you work; a release needs
RELEASES.md-50-a manifest of DIALED-IN work and a testable exit criterion, both recorded in the blocks below. "The
RELEASES.md-51-open issues are done" is not an exit criterion, because working on a release generates more of them.
RELEASES.md-52-
--
RELEASES.md-66-
RELEASES.md-67-## What belongs here, on the occasions it is used
RELEASES.md-68-
RELEASES.md-69-**Major and meaningful releases only. Not every release number.**
RELEASES.md-70-
RELEASES.md:71:A block earns its place by being worth *planning toward* — a named arc with a theme, a target date,
RELEASES.md-72-and a milestone. If the only thing you can write in `Description:` is a restatement of what changed,
RELEASES.md-73-it belongs in CHANGELOG.md and nowhere else.
RELEASES.md-74-
RELEASES.md-75-`Iterations:` reserves a band of patch numbers for a release. **Reserved, deliberately not
RELEASES.md:76:enumerated** — versions inside a band ship freely and are recorded in CHANGELOG.md only. They never
RELEASES.md-77-get a block here. The band is what makes "where does 0.2.3 go?" a question with a written answer
RELEASES.md-78-instead of one resolved by adding a row.
RELEASES.md-79-
RELEASES.md:80:**A version inside an existing band is already accounted for, so a new block for it is a
RELEASES.md-81-duplicate.** That is the admission rule, and it is the only one.
RELEASES.md-82-
RELEASES.md-83-Why this is written down rather than assumed: the failure mode is not a wrong entry, it is a file
RELEASES.md-84-that stays correct at every single step while turning into the wrong thing. Add `0.2.1` because it
RELEASES.md-85-shipped, add `0.2.2` for symmetry, and this becomes a **de-facto pre-CHANGELOG** — a second,
--
RELEASES.md-114-Iterations: 0.2.0-0.2.4
RELEASES.md-115-Status: Shipped
RELEASES.md-116-Shipped: 2026-08-14 — RC 2026-08-09 on `development` @ `263816c`, soak window 5 days, re-verified at ship on `86ba3bd5`: `bash test/litmus-release.sh --release-gate` → exit 0, 6/6 complete, 0 false completion claims. **The ship test was the release's own exit command, not an issue-state audit.** Convention settled 2026-08-14: an exit criterion that is MET *is* the definition of done; a release is not held open by issues it never named. Falsification check on the soak window found nothing — every issue filed 08-09 → 08-14 (#485, #491, #499, #503, #504, #509, #510, #514, #518, #520, #521, #522, #523, #525, #527, #528, #533, #534, #536, #539, #540, #542, #544) either shipped inside it or left the exit command green, and the command was re-run on a `development` containing all of those fixes.
RELEASES.md-117-Target Date: 2026-09-05
RELEASES.md-118-RC evidence: `bash test/litmus-release.sh --release-gate` → `GOALPOST MET — all 6 manifest entries complete` (6/6, 0 remaining, 0 false completion claims). Its own negative control, `--mutate-evidence`, was re-run on the same commit and reports `negative control OBSERVED in both directions (6 pass, 0 fail)` — it detects a stripped declaration, an unregistered gate (the #461 defect), and an invariant violated in either direction. Four of the six issues are CLOSED with per-criterion evidence (#407, #417, #457, #461). **Residual scope, resolved at ship (2026-08-14).** Both entries' gates are registered, green and control-observed — which is what this release's exit criterion measures — but each carried acceptance criteria that did not ship, and an unshipped criterion is not a reason to hold a met goalpost open. **#375 is CLOSED** (this block previously said it remained open; that was stale). **#390's residual is now [#546](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/546), milestoned Meter** — Layer 4's host free-memory floor and packet-driven per-phase overrides, deferred by the source itself at `utils/py/marathon_drive.py:1509` (verbatim: `# Layer 4 (host free-memory floor) and packet-driven per-phase overrides are Phase 2.`). Meter is the right home rather than a parking space: a host floor is a precondition checked before spending, #382 is already a Meter member and its capture doc documents this exact deferral, and #392 is the static counterpart to this runtime one. #546 is **milestone backlog, NOT admitted to Meter's frozen manifest** — it does not make Meter's exit command fail, so "discovery is not admission" applies. #375's shipped three-state `unverifiable` verdict still deliberately contradicts its criteria 1 and 5, because implementing them literally took `relay-self-sufficiency.sh` from 4/0 to 0/4 on a working machine; that is recorded on the issue and is a deliberate deviation, not an omission.
RELEASES.md:119:Codename: Litmus
RELEASES.md:120:Description: Make the checks capable of failing. Every gate in the Litmus manifest is shown to report red against a real defect, or is explicitly downgraded to advisory — a check never observed failing is not evidence (#419). Ordered first because it is the release that makes the next one measurable. It is also what the self-improvement chain (#431) is blocked on: a Reviewer is a gate, so #419 applies to it, and its qualification gate is currently un-runnable (#428) and has only ever been measured once (#429).
RELEASES.md-121-Exit criterion: `bash test/litmus-release.sh --release-gate` exits 0. Red today by design; turning it green is what "done" means. Its own negative control is `--mutate-evidence`, which must detect a stripped declaration and an unregistered gate. NOTE the honest limit, stated in that file: the audit proves registration, declaration shape and the absence of false completion claims. It does NOT prove a control was truly observed, because `gate_inventory.py` reads a declaration authored by the same person who wrote the gate. Recorded execution of each control is deliberately out of scope for this release.
RELEASES.md:122:Manifest: FROZEN 2026-08-08 — #375, #390, #407, #417, #457, #461. Six named decision gates, a fixed denominator rather than a percentage. "Every gate" was unshippable prose: `gate_inventory.py` reports 152 of 158 gates with no declared control, and retrofitting them is explicitly out of scope. Adding an entry is a RE-SCOPE, not a bugfix: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission — #457, #460 and #461 were all filed while executing Litmus, which is what an unfrozen boundary looks like.
RELEASES.md-123-GH_URL:
RELEASES.md:124:Milestone: Litmus
RELEASES.md-125-Front-door reviewed: No
RELEASES.md-126-Shakedown reviewed: No
RELEASES.md-127-License file: Yes
RELEASES.md-128-
RELEASES.md-129-Release: 0.3.0
RELEASES.md-130-Iterations: 0.3.0-0.3.4
RELEASES.md-131-Status: Shipped
RELEASES.md:132:Shipped: 2026-08-14 — RC 2026-08-11 on `development`, soak window 3 days, re-verified at ship on `86ba3bd5`: `bash test/nightwatch-release.sh --release-gate` → exit 0, **manifest 8/8 complete, lifecycle 5 passing / 0 failing / 0 NOT COVERED**. Half B *executes* the lifecycle cases rather than auditing them, so this is a run that killed real children and watched them recover — not a checklist. Falsification check on the soak window found nothing: the exit command was re-run on a `development` that already contains every fix landed 08-11 → 08-14, including GH-314 (the marathon transcript write-set), which is adjacent to this release's subject and was the one worth checking. The hostile-target write-set lifecycle case still passes via `gh514-write-set-trackable.sh`. Open non-manifest issues (#514, #467, #402, #392, #391, #386) do **not** hold this release open — the exit criterion never named them, and a milestone is a backlog, not a goalpost.
RELEASES.md-133-Target Date: 2026-10-10
RELEASES.md:134:RC evidence: `bash test/nightwatch-release.sh --release-gate` → `GOALPOST MET — all 8 manifest entries complete and every lifecycle case executes green` (manifest 8/8, lifecycle 5 passing / 0 failing / 0 NOT COVERED). Its own negative control, `--mutate-evidence`, reports 34/0 and `negative control OBSERVED in both directions`. Every manifest entry carries a recorded pre-fix control under `test/baselines/`, not an assertion that one happened. **Two entries are honest about their limits and are worth reading before signing off:** #358's Phase 2 is a *disposition* that needs a real CI failure carrying the new instrumentation, and its capture doc forbids pre-committing one — so Phase 1 shipped and Phase 2 is blocked on an observation, not on work; and #354's membership is Phase 1 only, which was delivered by #376/#448 rather than by this release, recorded as such rather than rebuilt. **#426's outcome inverted its own diagnosis:** a factorial control showed the leak survives with worktree isolation OFF, so teardown was exonerated and the real cause was the GH-375 auth pre-flight running with the caller's CWD, outside containment. **Twelve open Nightwatch-milestone issues remain and gate nothing**, per this block's own "a release is not its milestone" rule. **CI-VERIFIED 2026-08-12, and it was not before:** the goalpost was first met on macOS only, and two of the five lifecycle cases (#388, #514) were failing on every ubuntu CI run at the time the RC was recorded — their fixtures stubbed the builder but not the reviewer binary, so `marathon_drive.py`'s probe fail-fasted and the cases never executed the code they assert on. Fixed, and the gate now reports `GOALPOST MET` with `codex` absent from `PATH`, which is the CI condition reproduced locally rather than inferred. Recorded here because it is exactly the class of thing this release exists to catch: a green result that was green about the wrong environment. The general defect is #520; the control is `test/baselines/GH-520-negative-control.md`.
RELEASES.md:135:Post RC update: **#358 Phase 1 is in Nightwatch. Phase 2 is deferred to the Lantern build.** Operator decision, 2026-08-11, recorded here rather than left implicit in an issue thread. Phase 1 — the lock instrumentation — shipped and is counted in the RC evidence above; the manifest below is unchanged and this release does not wait on Phase 2. Phase 2 is the *disposition*, which needs a real CI failure carrying that instrumentation, and it belongs to Lantern because what it produces is a failure that states its own reason — Lantern's whole subject — not a lifecycle invariant. **#358 keeps its Nightwatch milestone**, because it is a frozen manifest entry counted in this block's evidence and re-milestoning it to tidy a join key would falsify a frozen boundary. Only the scope moved.
RELEASES.md:136:Codename: Nightwatch
RELEASES.md:137:Description: An unattended marathon against a real target repo survives, records, and recovers. Before dispatching work, it proves the target can accept the harness write-set and preserves the local-state contract, so hostile ignore rules or linked worktrees fail clearly rather than silently splitting, leaking, or losing the run. GH-354 Phase 1 is an early Nightwatch containment prerequisite: restore clone-wide driver exclusion for linked worktrees and prove all driver pairs fail closed. A run interrupted, killed at its cap, or panicking the host leaves a durable record and recovery path instead of a clean tree full of ungated commits. Depends on Litmus. The same durability work is what makes a reflection corpus trustworthy (#431): a run with no record is invisible to any later pass over it, and the loop's own evidence has never survived a reboot (#430).
RELEASES.md:138:Exit criterion: `bash test/nightwatch-release.sh --release-gate` exits 0. **BUILT 2026-08-11 and red by design**, exactly as Litmus's was; turning it green is what "done" means. It has two halves because a metadata audit cannot answer this release's question. Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), and has a RECORDED control under `test/baselines/`; it also cross-checks that this list and the `Manifest:` line below agree, since a boundary that disagrees with itself is not frozen. Half B **executes** the lifecycle cases rather than auditing them, delegating to the suites that already drive real children and kill them rather than growing a second driver fixture here. Status on 2026-08-11: **manifest 8/8 complete; lifecycle 5 passing, 0 NOT COVERED — GOALPOST MET.** The last gap was the hostile-target write-set case, closed by #514, which was filed while executing this release and deliberately NOT admitted to the manifest (discovery is not admission); it belongs to the lifecycle list because the exit criterion always named that case — what was missing was a suite driving it. That lane also corrected its own premise: the pre-fix tree does not dispatch a turn first, it dies at the render's `git add` with an unhandled `CalledProcessError` traceback, so the discriminating assertion is the absence of that traceback rather than the absence of a dispatch. Its own negative control is `--mutate-evidence` (34/0), which unregisters a gate and deletes a recorded control in a fixture copy, requires both to be detected, and re-checks the unmutated inputs green in the same run so an always-red detector cannot pass for one. Honest limit, inherited from Litmus: Half A reads a declaration and a filename and cannot know a recorded control was honestly recorded; Half B is what narrows that, and is why this criterion is a command that kills children rather than a checklist.
RELEASES.md:139:Manifest: FROZEN 2026-08-11 — #408, #409, #426, #388, #387, #384, #358, plus #354 Phase 1. Eight named entries, a fixed denominator rather than a percentage. The first six were moved out of Litmus on 2026-08-08 after a codex+agy consult; #387 and #384 are added at freeze time because the exit criterion above already names their cases — it requires a cap-killed child and a restarted recovery, and nothing else in the milestone supplies either. **The milestone is not the manifest.** Nightwatch's milestone holds 18 open issues; the twelve not listed here (#376, #378, #379, #380, #382, #386, #391, #392, #402, #467, #491, and anything filed during execution) are backlog worked inside the 0.3.0-0.3.4 band, and none of them gates the release. **AMENDED 2026-08-11:** five of those — #378, #379, #380, #382, #491 — were re-milestoned to Meter (0.6.0) at the operator's instruction, so they are no longer Nightwatch backlog at all. The manifest above is untouched and the RC evidence stands; what changed is only the non-gating remainder. #358 stays milestoned here because it is a frozen manifest entry whose Phase 1 shipped and is counted in the RC evidence above — only its *Phase 2* moved, and it moved to **Lantern**, not Meter (see the Post RC update line above). Adding an entry is a RE-SCOPE, not a bugfix, under the same admission rule Litmus used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission.
RELEASES.md-140-GH_URL:
RELEASES.md:141:Milestone: Nightwatch
RELEASES.md-142-Front-door reviewed: No
RELEASES.md-143-Shakedown reviewed: No
RELEASES.md-144-License file: Yes
RELEASES.md-145-
RELEASES.md-146-Release: 0.4.0
RELEASES.md-147-Iterations: 0.4.0-0.4.4
RELEASES.md-148-Status: Draft
RELEASES.md-149-Target Date: 2026-11-14
RELEASES.md-150-Codename: Plumbline
RELEASES.md:151:Description: Assisted reflection and a bounded self-improvement loop, measured before either is trusted. The reflection pipeline turns durable Nightwatch records into proposals (`proposals-sink.sh` gains its first production caller) and is graded against external ground truth — the 49 human-filed findings from the two rebalance-OS marathons (#405/#406) — for recall and precision. Ships a committed benchmark and a recorded go/no-go; "not worth automating yet" is a passing result, per #431's own Phase 2 exit criterion. Operator sign-off stays manual. Depends on Nightwatch.
RELEASES.md-152-GH_URL: [GH 431](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/431)
RELEASES.md-153-Milestone: Plumbline
RELEASES.md-154-Front-door reviewed: No
RELEASES.md-155-Shakedown reviewed: No
RELEASES.md-156-License file: Yes
--
RELEASES.md-158-Release: 0.5.0
RELEASES.md-159-Iterations: 0.5.0-0.5.4
RELEASES.md-160-Status: Draft
RELEASES.md-161-Target Date: 2026-12-12
RELEASES.md-162-Codename: Lantern
RELEASES.md:163:Description: When the harness fails, the information needed to act already exists inside it — make it say so. Not "add checks": every case was already detected, and some were then described wrongly (a stack trace, a fabricated path, a success exit code, silence). Scope is one epic, deliberately narrow, and deliberately NOT Nightwatch: that milestone owns run lifecycle "even when lifecycle code emits a misleading message" (see the scope boundary above), and none of Lantern's cases violates a lifecycle invariant — they violate the legibility of a failure whose lifecycle handling was already correct. All four members were found in one afternoon during Nightwatch wave 3, which halted three times at zero paid-turn cost; each halt was avoidable from information the system already held. Depends on nothing; independent of Plumbline.
RELEASES.md:164:Exit criterion: `bash test/lantern-release.sh --release-gate` exits 0. **NOT BUILT.** Writing it precedes fixing any member, which is the Litmus and Nightwatch ordering and the reason both releases could tell a finished entry from a claimed one. Two halves, the established shape: Half A audits the frozen manifest — each entry's gate EXISTS, is REGISTERED in `validate.sh`, has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest:` line below. Half B **executes** #499's four phases rather than auditing them, since every one of them is a message an operator either receives or does not: a `relay-drive` launch preflight that refuses before spending, a gate refusal that states its real reason, a launcher exit code that survives its wrapper, and a change-impact report. **#358 Phase 2 is the one member with no executable half, and the criterion is written around that rather than pretending otherwise:** it is satisfied by a RECORDED transcript of a real CI failure under `test/baselines/`, and it must NOT be satisfiable by a disposition written in advance — that issue's own capture doc forbids pre-committing one, and an exit criterion that accepted a pre-written verdict would launder exactly the thing #419 exists to prevent. Its own negative control is `--mutate-evidence`, which must unregister a gate, delete a recorded control, and substitute a pre-dated disposition for a real transcript — detecting all three, and re-checking the unmutated inputs green in the same run so an always-red detector cannot pass for one.
RELEASES.md:165:Manifest: DIALED IN at one issue on creation — #499, which supersedes and closes #494, #495, #496 and #498. Four phases, each shippable alone: relay-drive launch preflight; a gate refusal that states its real reason; a launcher whose exit code survives plus a gate-readiness check; and a change-impact reporter. Freezing at one is the whole point — these were filed as four and unified precisely to stop a single coherent change spreading across four PRs. **RE-FROZEN AT TWO on 2026-08-11 by explicit operator decision — #499, plus #358 Phase 2.** Recorded as a re-scope rather than an edit, because the admission rule below is worthless if a manifest can grow quietly: the operator named the entry and the release, which is the documented way past the rule, and this line says so with a date instead of just showing two items where there was one. It is a genuine fit, not a parking space — Phase 2 is a *disposition* that turns a lost concurrent-append record into a failure naming its own terminal lock state, which is Lantern's subject exactly, whereas the run lifecycle it sits inside was already handled correctly (that is the Nightwatch boundary, and it is why Phase 1 belonged there and Phase 2 does not). It was briefly a Meter member the same day and moved here before either release started; Meter's block records the move from its side. **#358 keeps its Nightwatch milestone** — it is a frozen entry counted in Nightwatch's RC evidence, so only its scope moved, and this is the second Lantern member not enumerable by `gh issue list --milestone Lantern`. Adding a further member is a RE-SCOPE, not a bugfix, per the Litmus rule above.
RELEASES.md-166-GH_URL: [GH 499](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/499)
RELEASES.md:167:Milestone: not created yet. The original reason — "#499 is unmilestoned by design while Nightwatch is the active goalpost" — expired when Nightwatch reached RC on 2026-08-11, and is kept here only so a reader does not act on it as if current. Creating it is a live decision, not a formality: **neither member would be enumerable by it as things stand** (#499 is unmilestoned, and #358 keeps its Nightwatch milestone deliberately), so the milestone would join nothing until #499 is assigned. The `Manifest:` line below is this release's authoritative scope either way.
RELEASES.md-168-Front-door reviewed: No
RELEASES.md-169-Shakedown reviewed: No
RELEASES.md-170-License file: Yes
RELEASES.md-171-
RELEASES.md-172-Release: 0.6.0
RELEASES.md-173-Iterations: 0.6.0-0.6.4
RELEASES.md-174-Status: Draft
RELEASES.md-175-Target Date: 2026-09-26
RELEASES.md-176-Codename: Meter
RELEASES.md-177-Description: **XYZ can be handed to a stranger.** An unauthenticated clone reaches a documented entry path and exercises a supported happy path with no private context, from a tree that has been sanitized and secret-scanned. **RE-SCOPED 2026-08-15 by explicit operator decision** — Meter was originally the metering release ("a run accounts for what it spends and checks what it requires before spending it"; members #378 #379 #380 #382 #491, found by a real unattended marathon against rebalance-OS); that work moved intact to Sundown (0.8.0) and publication took the slot, because it is the next thing that happens to this repository and the operator named it. Recorded as a dated re-scope — a codename that quietly changes its subject is the same defect as a manifest that quietly grows. (This block was COMPACTED 2026-08-20 by operator request; the full prose of every paragraph below is in this file's git history.)
RELEASES.md:178:Publication target: **the deliverable is a sanitized clone, not this repository** — fresh history, single initial commit, pushed to **https://github.com/HiQS-Suite/XYZ-forge** (new org, named by the operator 2026-08-15, XYZ's permanent home). `CHANGELOG.md` carried forward verbatim as the public record; carrying the 2,147-commit history was rejected 2026-08-15 because a full-history secret scan would have to scan everything ever deleted — fresh history makes sanitization complete by construction. `.tick/` (161 MB) and `relay-system/` (32 MB) do not ship; `PROJECT/` ships as an empty PDDA scaffold plus the Meter build docs retained as a worked example — the method travels, the backlog does not.
RELEASES.md-179-Scope boundary — Meter vs Lantern: **Lantern owns how a failure is described; Meter owns what a run consumed and what it required.** Route by whether the issue names a *resource or precondition* (dollars, turns, memory, a trusted directory, a green suite) or *the wording of a verdict whose handling was already correct*. #379 splits across both by that rule (overloaded exit 5 → Lantern; the budget itself → Meter). #491 sits here deliberately: the violated invariant is re-spending paid turns already held, and its evidence is a cost measurement.
RELEASES.md:180:Exit criterion: `bash test/meter-release.sh --release-gate` exits 0. **NOT BUILT — writing it is Meter's first task, before any sanitization** (the Litmus/Nightwatch ordering). Two halves, re-pointed at launch with the 2026-08-15 re-scope (command and shape unchanged). **Half A AUDITS the launch artifact:** sanitized clone at the declared path with exactly one commit; `CHANGELOG.md` byte-identical to this repository's; `.tick/`, `relay-system/`, `temp/` absent; `PROJECT/` = PDDA scaffold + retained Meter example only; both LICENSE files present and consistent; secret-scan result names its tool version and exact commit. **Half B EXECUTES the stranger's path:** a credential-less clone of the published commit reaches the documented entry point and completes one supported happy path with nothing that exists only on the author's machine. Negative control `--mutate-evidence` (fixture copy): plant a private path in a tracked file, remove `CHANGELOG.md`, leave a `relay-system/` behind — detect all three, re-check unmutated inputs green in the same run. RED on arrival.
RELEASES.md:181:Manifest: **DIALED IN at TWO — #555 and #563.** #555 is the release's own exit criterion (ships first, arrives RED). #563 is the launch checklist authored by an external reviewer (Codex Sol High): release boundary, public onboarding and behavior, secret/privacy review, legal/CI/publication sequence — frozen whole per the Plumbline precedent (one coherent cutover, not split across issues). **Scope CLOSED to further admission by explicit operator instruction 2026-08-15** — the standing admission rule is superseded for this release only; anything discovered during execution is filed to Sundown or left unmilestoned and **waived in writing per #563's rule (a waiver names the failed criterion, owner, reason and follow-up — silence is not a waiver).** Known open items under that rule, each needing a fix or waiver before the gate is called green: **#564** (31 unaudited suites can reach the caller's clone through an empty fixture path) and **#544's re-arm debt** (hosted CI fires on nothing while private; going public is the documented trigger). **Re-scope ledger, dated** (full prose for each in this file's git history): 2026-08-11 frozen at five on creation (#378 #379 #380 #382 #491); same day #358-P2 briefly a member, moved to Lantern before any work began; 2026-08-12 #509 admitted; 2026-08-14 #509 retired complete (its two unchecked criteria made permanently unwitnessable by GH-544's CI retirement, which owns the debt and the re-arm trigger); 2026-08-14 #551 admitted (shared refuse-don't-default root cause under nine issues) and the target pulled in 2027-01-16 → 2026-09-26 (Nightwatch, the only blocker, had shipped); 2026-08-15 #555 admitted; 2026-08-15 the subject replaced (fifth re-scope) — the seven engineering entries dissolved: #380 CLOSED and shipped under the original scope (stays milestoned Meter as delivered work); #378 #379 #382 #491 #551 moved intact to Sundown (0.8.0) with their capture docs, acceptance criteria and evidence; #546 followed as Sundown backlog (was never a manifest entry).
RELEASES.md-182-Manifest-Members: 555 563
RELEASES.md-183-GH_URL: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/563
RELEASES.md-184-Milestone: Meter
RELEASES.md-185-Front-door reviewed: Yes
RELEASES.md-186-Shakedown reviewed: Yes
--
RELEASES.md-191-Status: Shipped
RELEASES.md-192-Shipped: 2026-08-18 — `XYZ_BALLAST_STRANGER_RUNS=10 test/ballast-release.sh --release-gate` → exit 0, manifest 4/4 complete, stranger's path 4/4 passing (B1 10/10 consecutive parallel runs zero failures, B2a in-band ungated warning, B2b forced-red push refusal, B3 atomic event append).
RELEASES.md-193-Target Date: 2026-09-12
RELEASES.md-194-Codename: Ballast
RELEASES.md-195-Description: Post-launch hardening: **the launched repository holds up under a stranger's first run and an outside contributor's first push.** Every member was found the same way — by pointing the launch machinery at its own published output: the first fresh-clone runs of the public repository produced a different failing set each time (#15), a push gate that does not travel with clones got worse the moment the repo went public (#4), and the kernel's own event log can drop events on the concurrent path the kernel exists to coordinate (#14). Ballast exists because publication moved the failure surface from "our machines" to "everyone else's", and nothing in the shipped tree tests that surface. Builds on Meter's publication; depends on nothing unshipped.
RELEASES.md:196:Exit criterion: `bash test/ballast-release.sh --release-gate` exits 0. **NOT BUILT — writing it is Ballast's first task, before any member is fixed** (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. **Half A audits the frozen manifest:** each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. **Half B EXECUTES the stranger's path rather than auditing it:** (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. **SHIPPED 2026-08-18.** `XYZ_BALLAST_STRANGER_RUNS=10 test/ballast-release.sh --release-gate` executed for real against a fresh disposable clone (`~/xyz-disposable/xyz-stranger-clone`): exit 0. Half A: 4 of 4 manifest members complete (#14, #15, #4, #3 — gate/registration/control/CLOSED-issue all confirmed). Half B: 4 of 4 passing (B1: 10/10 consecutive parallel runs with zero failures; B2a: ungated clone warning in-band; B2b: forced-red push refusal; B3: atomic-append cross-process stress case clean) — **GOALPOST MET**.
RELEASES.md:197:Manifest: FROZEN 2026-08-16 on creation — #14, #15, #4, #10, #3. Five entries, a fixed denominator rather than a percentage. Same admission rule Litmus and Nightwatch used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission. **#14 and #15 SHIPPED 2026-08-17** (PR #21, PR #20; each closed with evidence — atomic-write negative control, 10/10 consecutive parallel fresh-clone runs). **#3 SHIPPED 2026-08-17**: the durable-default and path-printing halves were already landed pre-freeze (GH-430); the sole remaining gap, a recorded negative control, closed the same day (`test/baselines/GH-3-state-dir-negative-control.md`) — closed as landed, not re-scoped or swapped. **#10 CUT 2026-08-17, invoking its own pre-declared contingency**: a driven marathon attempt (builder agy, reviewer codex, round-cap 5) escalated after 5 rounds without landing — the suite count the fix would need to touch grew from the estimated ~31 to 73 with zero mechanically adopted, and the builder self-issued a scope waiver rather than flagging the blocker back to the orchestrator. This is exactly the scope-slip the freeze anticipated ("#10 is the designated cut if scope slips... #1's clone-identity bracket already covers the same ground *detectably* in the meantime"); cut per that pre-authorized contingency rather than re-fired. Issue #10 stays open, un-closed by this cut — the underlying containment gap remains real, just descoped from Ballast. Manifest reduced from 5 to 4 entries; this is a recorded re-scope, not a silent drop.
RELEASES.md-198-Manifest-Members: 14 15 4 3
RELEASES.md-199-Explicit non-goals, stated so they are not silently absorbed: #16 (hosted CI re-arm — tracked separately, explicitly NOT in scope, the local pre-push gate stays the only gate), #9 (tooling floor: eslint/prettier, src/ coverage, decompositions), #11 (Sundown twin retirement), #12 (tree diet), #13 (fold scaling — its body was corrected 2026-08-16: it claimed event append is already atomic temp+rename, which was never true; #14 owns making it so).
RELEASES.md-200-GH_URL:
RELEASES.md-201-Milestone: Ballast
RELEASES.md-202-Front-door reviewed: No
--
RELEASES.md-208-Status: Draft
RELEASES.md-209-Target Date: 2026-10-17
RELEASES.md-210-Codename: Sundown
RELEASES.md-211-Description: Retire the twelve frozen Bash twins. Three steps, in order: (1) sweep for real `XYZ_PYTHON=0` usage — if nothing sets it, the fallback is already dead in practice; (2) re-vendor every fleet `.xyz/` copy onto the Python lane (`xyz-sync.sh list` is the worklist); (3) delete the twins and retire the GH-308 edit-guard, keeping only its no-new-Bash half (GH-551). Not before steps 1-2: the vendored fleet still runs the Bash path, and `XYZ_PYTHON=0` is the documented rollback. Depends on nothing in Meter.
RELEASES.md-212-**WIDENED 2026-08-15 by explicit operator decision — Sundown receives Meter's five engineering entries.** The release's sentence becomes: **the harness accounts for what it spends, checks what it requires before spending it, and stops carrying the retired Bash lane.** Said plainly rather than argued into one theme: the twin retirement and the metering work are two subjects sharing one release, and they are here together because Meter was re-pointed at publication on 2026-08-15 and these five needed a home that was not a parking space. They arrive intact — same capture docs under `PROJECT/2-WORKING/`, same verbatim acceptance criteria, same evidence — and the honest reading of the widening is that Sundown's date is now less trustworthy than it was, because it absorbed five entries without absorbing any schedule.
RELEASES.md:213:**RENUMBERED 0.7.0 → 0.8.0 on 2026-08-16 by explicit operator decision, to open 0.7.0 for Ballast.** Nothing about this release changed except its version: same codename, same target date, same manifest, same milestone. The band moves with it (`0.7.0-0.7.4` → `0.8.0-0.8.4`) because a release's iteration band is part of its identity here, not a separate fact. Recorded as a dated line rather than shown as a block that was always 0.8.0, on the same principle the manifest re-scopes above follow: a version that changes without a trace is indistinguishable from one that was misread. The `(0.7.0)` parentheticals in Meter's re-scope paragraphs were swept to `(0.8.0)` in the same edit — they identify *which release received the transfer*, so leaving them stale would have pointed a reader at a version that no longer exists. `CHANGELOG.md`'s existing entry is **not** swept: it is the append-only record of what was decided on 2026-08-15, when Sundown was 0.7.0, and the renumber is recorded there as its own dated entry instead.
RELEASES.md:214:Manifest: **#378, #379, #382, #491, #551, #28**, received from Meter 2026-08-15, plus the twin-retirement work described above, which remains unnumbered until its issues are filed. **#28** is the RELEASES.md ledger-discipline fix (parser continuation-folding + advisory bloat checks; see its capture doc for detail), added 2026-08-18 as a post-Ballast follow-up. **#546 is milestone backlog, not a manifest entry** — it followed the metering subject here and does not gate this release, under the standing rule that discovery is not admission. **Not yet frozen.** Freezing requires the twin-retirement issues to exist so the manifest is a fixed denominator rather than a list plus a promise; until then this line is a receipt for the transfer, not a contract. #380 did not move: it is CLOSED and shipped under Meter's original scope, and stays milestoned there.
RELEASES.md:215:Exit criterion: **NOT WRITTEN.** Required before this release starts, per the ordering Litmus and Nightwatch both used and Meter is repeating — the gate is built first and arrives RED, because a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one.
RELEASES.md-216-GH_URL: pending — api.github.com DNS outage 2026-08-14; file on recovery
RELEASES.md-217-Milestone: Sundown
RELEASES.md-218-Front-door reviewed: No
RELEASES.md-219-Shakedown reviewed: No
RELEASES.md-220-License file: Yes
--
RELEASES.md-222-Release: 0.9.0
RELEASES.md-223-Iterations: 0.9.0-0.9.4
RELEASES.md-224-Status: Draft
RELEASES.md-225-Target Date: 2026-09-19
RELEASES.md-226-Codename: Cargo
RELEASES.md:227:Description: The harness travels with its ledger. The RELEASES DB system (releases_app.py CLI + merge resolver + FAQs) and the GH-103 HTML timeline generator (utils/timeline/) ship inside every vendored `.xyz/` payload as an optional, never-wired-by-default add-on — a "when you're ready" module a target repo enables by running `releases init` itself, matching this file's own OPTIONAL philosophy (GH-381). Sequenced before Meter (0.6.0, 2026-09-26) by explicit operator decision 2026-08-20; version 0.9.0 because every 0.1–0.8 band is reserved — target date, not version number, carries the ordering. Cut through the CLI and mirrored here by hand in the same commit (the GH-32 Phase-0 dual path; no automatic dual writer exists yet).
RELEASES.md:228:Exit criterion: A repo vendored with `xyz-vendor.sh` can, with zero extra downloads, run `releases init`/`add` and `export_timeline.py --preview` from `.xyz/` against its own root, and `xyz-sync.sh update` preserves the target's ledger state (GH-312 preserve list). Nothing runs until the user invokes it. NOT BUILT — the gate is authored before any member is fixed, per the Litmus/Nightwatch ordering.
RELEASES.md:229:Manifest: DIALED IN 2026-08-20 on creation — #105 (vendor the RELEASES DB + timeline generator into the .xyz payload). RE-SCOPED 2026-08-20 by explicit operator instruction: + #107 (connect /10days, /radar, and PARKED to the RELEASES DB — read-only consumption seams; no new writers). Two entries; no swap; target date held — #107 is additive tooling scoped as quick wins. The standing admission rule remains for anything further: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission.
RELEASES.md-230-GH_URL: https://github.com/HiQS-Suite/XYZ-forge/issues/105
RELEASES.md-231-Milestone: Cargo
RELEASES.md-232-Front-door reviewed: No
RELEASES.md-233-Shakedown reviewed: No
RELEASES.md-234-License file: Yes
--
PROJECT/PDDA.md-500-  search before being called dead — only a name absent *everywhere* is flagged. A `GH-<n>-*.md` name is
PROJECT/PDDA.md-501-  never flagged; those are illustrative instances of the issue-doc naming convention, not fixed
PROJECT/PDDA.md-502-  cross-references. `warn`, not `error`: prose extraction is inherently more heuristic than the
PROJECT/PDDA.md-503-  mechanical checks above, so a false flag should cost one ignorable line, not a blocked build (same
PROJECT/PDDA.md-504-  calibration as `pdda.sh stale`/`pdda.sh changelog`).
PROJECT/PDDA.md:505:  - **Three extraction patterns** (union, then deduplicated): the target of a markdown link; a code span
PROJECT/PDDA.md-506-    that contains nothing but the path; and **command-position paths** — a script token that opens a code
PROJECT/PDDA.md-507-    span or a scanned fence line. The third exists because a router's most load-bearing references are
PROJECT/PDDA.md-508-    the commands it tells an agent to run, and those carry arguments, so they close neither a link nor a
PROJECT/PDDA.md-509-    backtick span right after the suffix. A vendored harness script invoked with a `--help` flag inside a
PROJECT/PDDA.md-510-    code span, and a bare sync-tool invocation with its subcommand inside a scanned ` ```bash ` fence,
--
PROJECT/PDDA.md-512-    immediately after a backtick — is where a shell command's *program* sits; a script name appearing
PROJECT/PDDA.md-513-    later in a sentence is prose, and is not extracted. That is what keeps a documented invocation such
PROJECT/PDDA.md-514-    as `pdda.sh run` from being read as two separate references. A leading `./` is stripped, because in
PROJECT/PDDA.md-515-    command position it means "from the repo root I am standing in", not "relative to this doc".
PROJECT/PDDA.md-516-  - **Suffix widening was not free.** `.sh` references are the ones that differ most between the canonical
PROJECT/PDDA.md:517:    repo and a target, so the exemption manifest below had to grow with them — a fresh install went from
PROJECT/PDDA.md-518-    0 to 46 self-inflicted warns before it did. A ref to a script that exists only on the operator's
PROJECT/PDDA.md-519-    `PATH` (never in the repo) is a known, accepted false positive; it costs one advisory warn.
PROJECT/PDDA.md-520-  - **GH-15 shipped-doc exemption manifest:** `utils/pdda/PDDA-INSTALL.md` and `PROJECT/PDDA.md` ship
PROJECT/PDDA.md:521:    to every target install (`PDDA_GOV_SHIPPED_DOCS_DEFAULT`) but legitimately reference files
PROJECT/PDDA.md:522:    `install.sh` deliberately does not copy there — the target's own repo-authored startup docs
PROJECT/PDDA.md-523-    (`ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `README.md`, `CLAUDE.md`), canonical-only skill and
PROJECT/PDDA.md-524-    companion-doc paths (`.claude/skills/pdda/SKILL.md`, `.claude/skills/governance-audit/SKILL.md`,
PROJECT/PDDA.md-525-    `PROJECT/3-COMPLETED/PDDA-SYNC-TO-OTHER-REPOS.md`), and the pre-`utils/pdda/` legacy layout path
PROJECT/PDDA.md-526-    (`utils/PDDA-INSTALL.md`, named only in migration-note prose). A fresh `install.sh . --mode observe`
PROJECT/PDDA.md-527-    self-inflicted ~30 dead-reference/env-var warns from exactly this mismatch on its very first
PROJECT/PDDA.md-528-    `pdda.sh run`, drowning a new adopter's own repo drift in PDDA-on-PDDA noise. The dead-reference scan
PROJECT/PDDA.md-529-    skips a match against `PDDA_GOV_SHIPPED_DOC_REF_EXEMPTIONS_DEFAULT`, scoped strictly to the docs in
PROJECT/PDDA.md-530-    `PDDA_GOV_SHIPPED_DOCS_DEFAULT` — a repo-authored governance doc (e.g. this canonical repo's own `ROUTER.md`)
PROJECT/PDDA.md-531-    referencing one of these is still a real dead-reference bug and is never exempted. The manifest was
PROJECT/PDDA.md:532:    built from an actual dead-reference scan of a bare `install.sh` target, not retyped from an issue's
PROJECT/PDDA.md-533-    illustrative list — re-run that scan if the shipped-doc set or its prose changes materially.
PROJECT/PDDA.md-534-    **GH-17 (resolved separately from this manifest):** this file's own "CHANGELOG.md" section used to
PROJECT/PDDA.md-535-    dead-reference two specific filenames (a retired recap note, a compliance-observations file) that
PROJECT/PDDA.md-536-    turned out to be artifacts of the repo this contract doc was originally adapted from, never real
PROJECT/PDDA.md-537-    files in this standalone PDDA repo. Naming them here was a copy-paste leftover, not a real PDDA
PROJECT/PDDA.md-538-    requirement — genericized below rather than exempted, since a name that's dead *everywhere* is a
PROJECT/PDDA.md-539-    real accuracy bug (Principle #4), not an install-boundary false positive like the manifest above.
PROJECT/PDDA.md-540-  - **GH-23 P3 additions to the same manifest**, each read off a real scan of a bare
PROJECT/PDDA.md:541:    `--with-startup-docs` target (46 warns before, 0 after), in three groups:
PROJECT/PDDA.md:542:    canonical-only **tools** a target never receives (the installer itself; the sync engine, which
PROJECT/PDDA.md:543:    `pdda-sync-manifest.conf` excludes because targets are leaf nodes; `templates/`; `test/`);
PROJECT/PDDA.md-544-    **legacy flat-layout paths** (`utils/pdda.sh`, `utils/pdda-lib.sh`, …) that the install manifest names
PROJECT/PDDA.md-545-    *precisely because they must not exist* — it documents the layout `install.sh` migrates away from,
PROJECT/PDDA.md-546-    and their `.md` sibling was already exempt for this reason; and `config.sh`, which belongs to
PROJECT/PDDA.md-547-    git-pulse, a separate program.
PROJECT/PDDA.md-548-    **Known separate issue, not covered by this manifest:** this file's own CHANGELOG section
--
PROJECT/PDDA.md-556-  must be named somewhere in the index doc. Parsing the `case` statement is mechanical (zero prose
PROJECT/PDDA.md-557-  ambiguity), so this earns the same blocking severity as the structural checks — it is the concrete
PROJECT/PDDA.md-558-  enforcement of AGENTS.md #5 ("keep the installer surface in lockstep").
PROJECT/PDDA.md-559-- **env-var drift** (`warn`) — every `PDDA_*` token mentioned in a governance doc should actually be
PROJECT/PDDA.md-560-  read or set somewhere in a shipped script (`utils/pdda/*.sh` or the repo-root `install.sh`). `warn`,
PROJECT/PDDA.md:561:  not `error`: `utils/pdda/PDDA-INSTALL.md` ships to every target install but also documents
PROJECT/PDDA.md:562:  `utils/pdda/pdda-sync.sh` — a canonical-only tool never copied to targets (it isn't in the "Canonical
PROJECT/PDDA.md:563:  install set" above) — so a var like `PDDA_SYNC_BACKUPS` legitimately won't resolve in a target
PROJECT/PDDA.md-564-  install's own scripts. That's expected, not drift, confirmed by installing this check into a second
PROJECT/PDDA.md-565-  repo and seeing exactly that false positive fire — same calibration as dead-reference above.
PROJECT/PDDA.md-566-  - **GH-15:** the same exemption mechanism above covers this class of mismatch too —
PROJECT/PDDA.md-567-    `PDDA_GOV_SHIPPED_DOC_ENVVAR_EXEMPTIONS_DEFAULT` (`PDDA_REGISTRY`, `PDDA_GITPULSE_DIR`,
PROJECT/PDDA.md-568-    `PDDA_SYNC_MAX_SHRINK`) lists canonical-only-tool env vars that `PDDA-INSTALL.md`/`PROJECT/PDDA.md`
PROJECT/PDDA.md:569:    legitimately document but no target-installed script reads, scoped to the same `PDDA_GOV_SHIPPED_DOCS`
PROJECT/PDDA.md-570-    set so a repo-authored doc's phantom env var still fires.
PROJECT/PDDA.md-571-
PROJECT/PDDA.md-572-Expected exceptions:
PROJECT/PDDA.md-573-- fenced `console`/`text`/`transcript` blocks and blockquote lines are not scanned (same carve-out as
PROJECT/PDDA.md-574-  `pdda.sh hardcoded-paths`)
--
PROJECT/PDDA.md-584-first and then reads the same doc set for that fuzzier class of inconsistency.
PROJECT/PDDA.md-585-
PROJECT/PDDA.md-586-#### J. `pdda.sh releases`
PROJECT/PDDA.md-587-
PROJECT/PDDA.md-588-Purpose:
PROJECT/PDDA.md:589:- validate `RELEASES.md`, the single forward-looking release-planning ledger — deliberately light.
PROJECT/PDDA.md-590-  This replaced an earlier per-tag-doc lifecycle (`PROJECT/releases/RELEASE-<tag>.md` with a
PROJECT/PDDA.md-591-  Draft/RC/Published status, linked marathons, linked issues, and a GitHub release-tag cache) that
PROJECT/PDDA.md-592-  turned out to be too much data to keep current for an initial release. Fields and checks grow
PROJECT/PDDA.md:593:  only as a real need shows up — see "RELEASES.md — release ledger" below.
PROJECT/PDDA.md-594-
PROJECT/PDDA.md:595:Scope: every `Release:` block in `RELEASES.md`.
PROJECT/PDDA.md-596-
PROJECT/PDDA.md-597-Minimum behavior:
PROJECT/PDDA.md:598:- parse `RELEASES.md` into blocks (one per `Release:` line; see format below)
PROJECT/PDDA.md-599-- **release-value check**: `error` if a block's `Release:` value is empty (a malformed-doc guard,
PROJECT/PDDA.md-600-  not a readiness gate)
PROJECT/PDDA.md:601:- **target-date check** (optional field): `warn` if `Target Date` is set but is not a valid
PROJECT/PDDA.md-602-  `YYYY-MM-DD` calendar date
PROJECT/PDDA.md-603-- **overdue check**: `warn` if `Target Date` has passed and `Status` doesn't read exactly `Shipped`
PROJECT/PDDA.md-604-  (case-insensitive) — `Status: Shipped` is the sole "already shipped" signal; a populated `GH_URL`
PROJECT/PDDA.md-605-  alone does not silence this (it means a Release object exists, not that it shipped)
PROJECT/PDDA.md-606-- **QA-gate field check** (optional fields): `warn` if `Front-door reviewed`, `Shakedown reviewed`,
--
PROJECT/PDDA.md-608-  value is fine (not yet answered)
PROJECT/PDDA.md-609-- **iteration-band check** (optional field): `warn` if `Iterations` is set but isn't a well-formed
PROJECT/PDDA.md-610-  `<lo>-<hi>` band — both sides plain dotted-numeric, `lo` no greater than `hi`. Strict on purpose:
PROJECT/PDDA.md-611-  a band nobody can evaluate is worse than no band, because the duplicate check below silently
PROJECT/PDDA.md-612-  stops covering that release
PROJECT/PDDA.md:613:- **in-band duplicate check**: `warn` if a block's `Release:` version falls inside a *different*
PROJECT/PDDA.md:614:  block's reserved `Iterations` band. This is the admission rule made mechanical — a version inside
PROJECT/PDDA.md-615-  a band is already accounted for, so a block for it is by definition a duplicate. Only plain
PROJECT/PDDA.md:616:  dotted-numeric versions are tested; a prerelease or date-shaped version is left to human judgment
PROJECT/PDDA.md-617-  rather than guessed at
PROJECT/PDDA.md-618-- **never blocks, even in `full` mode** — this check does not gate its exit code at all, regardless
PROJECT/PDDA.md-619-  of findings. The one `error` above (empty `Release:` value) is a malformed-doc guard, surfaced
PROJECT/PDDA.md-620-  loudly so it isn't missed, but deliberately cannot fail a build
PROJECT/PDDA.md-621-
PROJECT/PDDA.md-622-gh-degrade: none. The check is purely file-driven (no GitHub calls), which is a deliberate
PROJECT/PDDA.md-623-simplification over the old per-tag-doc check's issue/tag cross-checks against `gh`.
PROJECT/PDDA.md-624-
PROJECT/PDDA.md:625:#### RELEASES.md — release ledger
PROJECT/PDDA.md-626-
PROJECT/PDDA.md:627:**`RELEASES.md` is an optional planning aid.** It is not a required artifact, not a checklist, and
PROJECT/PDDA.md-628-not something to keep topped up. An empty file, a stale file, or no file at all are all valid
PROJECT/PDDA.md:629:states — `pdda.sh releases` skips a missing file entirely ("RELEASES.md not found — nothing to
PROJECT/PDDA.md-630-check") and never blocks, even in `full` mode.
PROJECT/PDDA.md-631-
PROJECT/PDDA.md-632-**Do not proactively offer to fill it in, populate it, bring it current, or add a release that has
PROJECT/PDDA.md-633-already shipped. Do not treat a sparse file as an incomplete one.** Edit it only when an operator
PROJECT/PDDA.md-634-explicitly asks for release *planning*.
--
PROJECT/PDDA.md-640-same fact is the defect, and it arrives one helpful suggestion at a time. `CHANGELOG.md` is the
PROJECT/PDDA.md-641-history. This file is not.
PROJECT/PDDA.md-642-
PROJECT/PDDA.md-643-What it *is*: a first-class root file, like `ROADMAP.md`/`CHANGELOG.md` — a single forward-looking
PROJECT/PDDA.md-644-planning ledger for major releases, not a lifecycle bucket of per-tag docs. Marathon plans and other
PROJECT/PDDA.md:645:forward planning cross-reference it for target release names/dates.
PROJECT/PDDA.md-646-
PROJECT/PDDA.md-647-**The admission rule.** A block earns its place by being worth *planning toward* — a named arc with
PROJECT/PDDA.md:648:a theme, usually carrying a target date and a milestone. If the only thing that can go in
PROJECT/PDDA.md-649-`Description:` is a restatement of what changed, it belongs in `CHANGELOG.md` and nowhere else.
PROJECT/PDDA.md-650-Everything below the threshold goes in an `Iterations:` band (see the field docs) rather than getting
PROJECT/PDDA.md-651-its own block.
PROJECT/PDDA.md-652-
PROJECT/PDDA.md-653-The test is the theme, not the paperwork: `Target Date:` and `Milestone:` are optional fields and
--
PROJECT/PDDA.md-673-Shakedown reviewed:
PROJECT/PDDA.md-674-License file:
PROJECT/PDDA.md-675-```
PROJECT/PDDA.md-676-
PROJECT/PDDA.md-677-Fields:
PROJECT/PDDA.md:678:- `Release:` (required) — the version being planned
PROJECT/PDDA.md-679-- `Status:` (optional) — free-text, unvalidated by design (`Draft`, `Working`, `Shipped`, whatever
PROJECT/PDDA.md-680-  an operator finds useful). **`Status: Shipped` is the sole "already shipped" signal** — both
PROJECT/PDDA.md-681-  `pdda.sh releases`'s overdue nudge and `pdda.sh releases-current`'s "in progress" filter key off
PROJECT/PDDA.md-682-  it exclusively. This is a rough signal, not a gated lifecycle — no fixed vocabulary is enforced.
PROJECT/PDDA.md:683:- `Iterations:` (optional) — a **reserved band of version numbers**, written `<lo>-<hi>` (e.g.
PROJECT/PDDA.md:684:  `0.2.0-0.2.4`). Versions inside a band ship freely and are recorded in `CHANGELOG.md` only; they
PROJECT/PDDA.md-685-  **never get a block here**, and the band deliberately does not enumerate them. Absence of the
PROJECT/PDDA.md-686-  field means no band is reserved.
PROJECT/PDDA.md-687-
PROJECT/PDDA.md-688-  **The band's owner is the one exception.** A band is written on the block it belongs to, and that
PROJECT/PDDA.md-689-  block's own `Release:` is the band's `<lo>` — so the owner sits inside its own band and keeps its
PROJECT/PDDA.md:690:  block. Every *other* version in the range is covered by the band and gets none. `pdda.sh releases`
PROJECT/PDDA.md:691:  identifies the owner by line, not by version text, so a second block that merely repeats the
PROJECT/PDDA.md:692:  owner's version is still caught as the duplicate it is.
PROJECT/PDDA.md-693-
PROJECT/PDDA.md-694-  This is what gives the admission rule an answer instead of an argument. "Where does 0.2.3 go?"
PROJECT/PDDA.md-695-  resolved case-by-case is resolved by adding a row, every time; with a band it has a written
PROJECT/PDDA.md:696:  answer, and `pdda.sh releases` can check it — a version inside an existing band is already
PROJECT/PDDA.md-697-  accounted for, so a block for it is by definition a duplicate. That is testable in a way "is this
PROJECT/PDDA.md-698-  release meaningful?" never will be.
PROJECT/PDDA.md-699-
PROJECT/PDDA.md-700-  **When a band is exhausted** — `0.2.5` is needed and the band ends at `0.2.4` — **widen the band.
PROJECT/PDDA.md-701-  Do not start enumerating, and do not add a block.** Promote to the next release only when the work
PROJECT/PDDA.md:702:  genuinely became a new arc with its own theme, never merely because the numbers ran out; a version
PROJECT/PDDA.md-703-  number driven by an accounting artifact is the convention rotting rather than holding.
PROJECT/PDDA.md-704-
PROJECT/PDDA.md-705-  Rejected alternative, recorded so it isn't re-proposed: persisting `Iteration 1:` … `Iteration 5:`
PROJECT/PDDA.md-706-  labels per release. That is 20–25 named rows across a five-release horizon, each an invitation to
PROJECT/PDDA.md-707-  fill in what shipped — the same drift, arriving as structure instead of as appended blocks. One
--
PROJECT/PDDA.md-768-way to violate the optionality rule at the top of this section.
PROJECT/PDDA.md-769-
PROJECT/PDDA.md-770-#### `pdda.sh releases-current`
PROJECT/PDDA.md-771-
PROJECT/PDDA.md-772-Read-only roll-up (not part of `PDDA_DETERMINISTIC_CHECKS` — emits no findings, never gates): lists
PROJECT/PDDA.md:773:every `RELEASES.md` entry whose `Status` is empty or not exactly `Shipped`. A rough, non-authoritative
PROJECT/PDDA.md-774-answer to "what's currently in progress" — for a human, or for another repo's tooling (e.g. the XYZ
PROJECT/PDDA.md:775:sibling harness) to shell out to instead of re-implementing `RELEASES.md` parsing itself. Because
PROJECT/PDDA.md-776-`Status` is free-text, this is a best-effort filter, not a guarantee — an entry with a typo'd or
PROJECT/PDDA.md-777-unconventional `Status` value still shows up (safer default: never silently hide something that
PROJECT/PDDA.md-778-lacks an explicit `Shipped` signal).
PROJECT/PDDA.md-779-
PROJECT/PDDA.md-780-The four-tier shipping chain:
PROJECT/PDDA.md-781-
PROJECT/PDDA.md-782-```
PROJECT/PDDA.md-783-task/issue  (GH-*.md in 1-INBOX)
PROJECT/PDDA.md-784-  → project (2-WORKING active doc)
PROJECT/PDDA.md-785-    → marathon (marathon/MARATHON-*.yaml + PROJECT/2-WORKING/MARATHON-PLAN-*.md)
PROJECT/PDDA.md:786:      → release (RELEASES.md entry + GitHub Release)
PROJECT/PDDA.md-787-```
PROJECT/PDDA.md-788-
PROJECT/PDDA.md-789-### 2. LLM-assisted doc readiness review
PROJECT/PDDA.md-790-
PROJECT/PDDA.md-791-This catches the issues where structure exists but planning quality is weak.

exec
/bin/zsh -lc "nl -ba RELEASES.md | sed -n '190,235p'
nl -ba LEADERBOARD.md | sed -n '1,230p'
nl -ba ROADMAP.md | sed -n '1,160p'
for issue in 249 251 252 141 67 216 75 215 243 222; do rg -n -C 2 \"GH-"'${issue}([''^0-9]|$)|#${issue}([''^0-9]|$)" LEADERBOARD.md || true; done' in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-30948-51ksahqx
 succeeded in 0ms:
   190	Iterations: 0.7.0-0.7.4
   191	Status: Shipped
   192	Shipped: 2026-08-18 — `XYZ_BALLAST_STRANGER_RUNS=10 test/ballast-release.sh --release-gate` → exit 0, manifest 4/4 complete, stranger's path 4/4 passing (B1 10/10 consecutive parallel runs zero failures, B2a in-band ungated warning, B2b forced-red push refusal, B3 atomic event append).
   193	Target Date: 2026-09-12
   194	Codename: Ballast
   195	Description: Post-launch hardening: **the launched repository holds up under a stranger's first run and an outside contributor's first push.** Every member was found the same way — by pointing the launch machinery at its own published output: the first fresh-clone runs of the public repository produced a different failing set each time (#15), a push gate that does not travel with clones got worse the moment the repo went public (#4), and the kernel's own event log can drop events on the concurrent path the kernel exists to coordinate (#14). Ballast exists because publication moved the failure surface from "our machines" to "everyone else's", and nothing in the shipped tree tests that surface. Builds on Meter's publication; depends on nothing unshipped.
   196	Exit criterion: `bash test/ballast-release.sh --release-gate` exits 0. **NOT BUILT — writing it is Ballast's first task, before any member is fixed** (the Litmus/Nightwatch/Meter ordering; a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one). Two halves, the established shape. **Half A audits the frozen manifest:** each entry's gate EXISTS, is REGISTERED in `validate.sh` (a gate absent from TESTS is indistinguishable from one that passes — the #461 defect), has a RECORDED control under `test/baselines/`, and the list agrees with the `Manifest-Members:` line below in both directions. **Half B EXECUTES the stranger's path rather than auditing it:** (1) a fresh unauthenticated clone from the published commit runs the documented entry path ten consecutive times in parallel with zero failing runs — a contention warning is allowed only where it names the contended suite per #15's contract; (2) a fresh clone with no gate installed is surfaced as ungated, in-band, on the documented first-run path, naming the one-command install (#4) — and with the gate installed, a would-be-red push is refused (a push cannot be locally refused with no hook at all; that mechanical limit is stated here rather than papered over, and #4's fix makes the ungated state loud instead of invisible); (3) a writer killed mid-`appendEvent` loses no event, and no reader ever observes a partial `.jsonl` (#14). RED on arrival by design. Its own negative control is `--mutate-evidence`: in a fixture copy it must unregister a gate, delete a recorded control, and forge a passing stranger-run record; detect all three; and re-check the unmutated inputs green in the same run so an always-red detector cannot pass for one. **SHIPPED 2026-08-18.** `XYZ_BALLAST_STRANGER_RUNS=10 test/ballast-release.sh --release-gate` executed for real against a fresh disposable clone (`~/xyz-disposable/xyz-stranger-clone`): exit 0. Half A: 4 of 4 manifest members complete (#14, #15, #4, #3 — gate/registration/control/CLOSED-issue all confirmed). Half B: 4 of 4 passing (B1: 10/10 consecutive parallel runs with zero failures; B2a: ungated clone warning in-band; B2b: forced-red push refusal; B3: atomic-append cross-process stress case clean) — **GOALPOST MET**.
   197	Manifest: FROZEN 2026-08-16 on creation — #14, #15, #4, #10, #3. Five entries, a fixed denominator rather than a percentage. Same admission rule Litmus and Nightwatch used: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission. **#14 and #15 SHIPPED 2026-08-17** (PR #21, PR #20; each closed with evidence — atomic-write negative control, 10/10 consecutive parallel fresh-clone runs). **#3 SHIPPED 2026-08-17**: the durable-default and path-printing halves were already landed pre-freeze (GH-430); the sole remaining gap, a recorded negative control, closed the same day (`test/baselines/GH-3-state-dir-negative-control.md`) — closed as landed, not re-scoped or swapped. **#10 CUT 2026-08-17, invoking its own pre-declared contingency**: a driven marathon attempt (builder agy, reviewer codex, round-cap 5) escalated after 5 rounds without landing — the suite count the fix would need to touch grew from the estimated ~31 to 73 with zero mechanically adopted, and the builder self-issued a scope waiver rather than flagging the blocker back to the orchestrator. This is exactly the scope-slip the freeze anticipated ("#10 is the designated cut if scope slips... #1's clone-identity bracket already covers the same ground *detectably* in the meantime"); cut per that pre-authorized contingency rather than re-fired. Issue #10 stays open, un-closed by this cut — the underlying containment gap remains real, just descoped from Ballast. Manifest reduced from 5 to 4 entries; this is a recorded re-scope, not a silent drop.
   198	Manifest-Members: 14 15 4 3
   199	Explicit non-goals, stated so they are not silently absorbed: #16 (hosted CI re-arm — tracked separately, explicitly NOT in scope, the local pre-push gate stays the only gate), #9 (tooling floor: eslint/prettier, src/ coverage, decompositions), #11 (Sundown twin retirement), #12 (tree diet), #13 (fold scaling — its body was corrected 2026-08-16: it claimed event append is already atomic temp+rename, which was never true; #14 owns making it so).
   200	GH_URL:
   201	Milestone: Ballast
   202	Front-door reviewed: No
   203	Shakedown reviewed: No
   204	License file: Yes
   205	
   206	Release: 0.8.0
   207	Iterations: 0.8.0-0.8.4
   208	Status: Draft
   209	Target Date: 2026-10-17
   210	Codename: Sundown
   211	Description: Retire the twelve frozen Bash twins. Three steps, in order: (1) sweep for real `XYZ_PYTHON=0` usage — if nothing sets it, the fallback is already dead in practice; (2) re-vendor every fleet `.xyz/` copy onto the Python lane (`xyz-sync.sh list` is the worklist); (3) delete the twins and retire the GH-308 edit-guard, keeping only its no-new-Bash half (GH-551). Not before steps 1-2: the vendored fleet still runs the Bash path, and `XYZ_PYTHON=0` is the documented rollback. Depends on nothing in Meter.
   212	**WIDENED 2026-08-15 by explicit operator decision — Sundown receives Meter's five engineering entries.** The release's sentence becomes: **the harness accounts for what it spends, checks what it requires before spending it, and stops carrying the retired Bash lane.** Said plainly rather than argued into one theme: the twin retirement and the metering work are two subjects sharing one release, and they are here together because Meter was re-pointed at publication on 2026-08-15 and these five needed a home that was not a parking space. They arrive intact — same capture docs under `PROJECT/2-WORKING/`, same verbatim acceptance criteria, same evidence — and the honest reading of the widening is that Sundown's date is now less trustworthy than it was, because it absorbed five entries without absorbing any schedule.
   213	**RENUMBERED 0.7.0 → 0.8.0 on 2026-08-16 by explicit operator decision, to open 0.7.0 for Ballast.** Nothing about this release changed except its version: same codename, same target date, same manifest, same milestone. The band moves with it (`0.7.0-0.7.4` → `0.8.0-0.8.4`) because a release's iteration band is part of its identity here, not a separate fact. Recorded as a dated line rather than shown as a block that was always 0.8.0, on the same principle the manifest re-scopes above follow: a version that changes without a trace is indistinguishable from one that was misread. The `(0.7.0)` parentheticals in Meter's re-scope paragraphs were swept to `(0.8.0)` in the same edit — they identify *which release received the transfer*, so leaving them stale would have pointed a reader at a version that no longer exists. `CHANGELOG.md`'s existing entry is **not** swept: it is the append-only record of what was decided on 2026-08-15, when Sundown was 0.7.0, and the renumber is recorded there as its own dated entry instead.
   214	Manifest: **#378, #379, #382, #491, #551, #28**, received from Meter 2026-08-15, plus the twin-retirement work described above, which remains unnumbered until its issues are filed. **#28** is the RELEASES.md ledger-discipline fix (parser continuation-folding + advisory bloat checks; see its capture doc for detail), added 2026-08-18 as a post-Ballast follow-up. **#546 is milestone backlog, not a manifest entry** — it followed the metering subject here and does not gate this release, under the standing rule that discovery is not admission. **Not yet frozen.** Freezing requires the twin-retirement issues to exist so the manifest is a fixed denominator rather than a list plus a promise; until then this line is a receipt for the transfer, not a contract. #380 did not move: it is CLOSED and shipped under Meter's original scope, and stays milestoned there.
   215	Exit criterion: **NOT WRITTEN.** Required before this release starts, per the ordering Litmus and Nightwatch both used and Meter is repeating — the gate is built first and arrives RED, because a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one.
   216	GH_URL: pending — api.github.com DNS outage 2026-08-14; file on recovery
   217	Milestone: Sundown
   218	Front-door reviewed: No
   219	Shakedown reviewed: No
   220	License file: Yes
   221	
   222	Release: 0.9.0
   223	Iterations: 0.9.0-0.9.4
   224	Status: Draft
   225	Target Date: 2026-09-19
   226	Codename: Cargo
   227	Description: The harness travels with its ledger. The RELEASES DB system (releases_app.py CLI + merge resolver + FAQs) and the GH-103 HTML timeline generator (utils/timeline/) ship inside every vendored `.xyz/` payload as an optional, never-wired-by-default add-on — a "when you're ready" module a target repo enables by running `releases init` itself, matching this file's own OPTIONAL philosophy (GH-381). Sequenced before Meter (0.6.0, 2026-09-26) by explicit operator decision 2026-08-20; version 0.9.0 because every 0.1–0.8 band is reserved — target date, not version number, carries the ordering. Cut through the CLI and mirrored here by hand in the same commit (the GH-32 Phase-0 dual path; no automatic dual writer exists yet).
   228	Exit criterion: A repo vendored with `xyz-vendor.sh` can, with zero extra downloads, run `releases init`/`add` and `export_timeline.py --preview` from `.xyz/` against its own root, and `xyz-sync.sh update` preserves the target's ledger state (GH-312 preserve list). Nothing runs until the user invokes it. NOT BUILT — the gate is authored before any member is fixed, per the Litmus/Nightwatch ordering.
   229	Manifest: DIALED IN 2026-08-20 on creation — #105 (vendor the RELEASES DB + timeline generator into the .xyz payload). RE-SCOPED 2026-08-20 by explicit operator instruction: + #107 (connect /10days, /radar, and PARKED to the RELEASES DB — read-only consumption seams; no new writers). Two entries; no swap; target date held — #107 is additive tooling scoped as quick wins. The standing admission rule remains for anything further: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission.
   230	GH_URL: https://github.com/HiQS-Suite/XYZ-forge/issues/105
   231	Milestone: Cargo
   232	Front-door reviewed: No
   233	Shakedown reviewed: No
   234	License file: Yes
     1	<!-- GENERATED by utils/leaderboard.sh from releases.db — do not hand-edit. -->
     2	
     3	# Leaderboard
     4	
     5	Every rated task in the ledger, highest first. **Higher is better on every axis**, effort
     6	included — it scores cheapness, not cost, so a 90/90/90/90 item reads as what it is: a
     7	screaming quick win. `calc` is the equal-weighted sum of the four axes (4–400) and is derived,
     8	never stored. `ovr` is the operator override; where it exists it replaces `calc` for ranking,
     9	while the four axes keep their honest values underneath.
    10	
    11	| # | score | task | release | lane | pri | sev | appeal | effort | calc | ovr |
    12	|--:|------:|------|---------|------|----:|----:|-------:|-------:|-----:|----:|
    13	| 1 | **340** | [GH-67](https://github.com/HiQS-Suite/XYZ-forge/issues/67) — Commandcode builder default widened to `--yolo` — closer evaluation → possible build | — | Queue / parked intake | 88 | 80 | 45 | 70 | 283 | 340 |
    14	| 2 | **325** | [GH-249](https://github.com/HiQS-Labs/XYZ-forge/issues/249) — ubuntu canary: EUID=0 defeats chmod-based assertions | — | Queue / parked intake | 90 | 85 | 80 | 70 | 325 | — |
    15	| 3 | **315** | [GH-181](https://github.com/HiQS-Labs/XYZ-forge/issues/181) — repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2) | Bulkhead | completed | 90 | 75 | 90 | 60 | 315 | — |
    16	| 4 | **308** | [GH-204](https://github.com/HiQS-Labs/XYZ-forge/issues/204) — BSD `sed -i ''` no-ops on Linux at production call sites | Linux-RC | in progress | 88 | 85 | 70 | 65 | 308 | — |
    17	| 5 | **305** | [GH-202](https://github.com/HiQS-Labs/XYZ-forge/issues/202) — wave_reconcile aborts on marathon-plan exit 5 (items held) and promotes capture docs for OPEN issues | Bulkhead | completed | 85 | 65 | 85 | 70 | 305 | — |
    18	| 6 | **305** | [GH-228](https://github.com/HiQS-Labs/XYZ-forge/issues/228) — Org rename HiQS-Suite → HiQS-Labs: a hardcoded regex silently drops issue URLs from the roadmap shadow | Linux-RC | completed | 80 | 60 | 75 | 90 | 305 | — |
    19	| 7 | **300** | [GH-174](https://github.com/HiQS-Suite/XYZ-forge/issues/174) — Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator | Bulkhead | completed | 85 | 75 | 95 | 45 | 300 | — |
    20	| 8 | **295** | [GH-14](https://github.com/HiQS-Suite/XYZ-forge/issues/14) — appendEvent writes non-atomically, so concurrent readers can observe torn event files | — | Completed | 85 | 85 | 70 | 55 | 295 | — |
    21	| 9 | **295** | [GH-155](https://github.com/HiQS-Suite/XYZ-forge/issues/155) — 3rd Gen ATE & Fuzzing | — | Completed | 85 | 70 | 90 | 50 | 295 | — |
    22	| 10 | **295** | [GH-165](https://github.com/HiQS-Suite/XYZ-forge/issues/165) — Post-Merge Wave & Marathon Lifecycle Reconciler (Docs, ROADMAP, DB, Views, and Planning) | — | Completed | 90 | 80 | 90 | 35 | 295 | — |
    23	| 11 | **292** | [GH-23](https://github.com/HiQS-Suite/XYZ-forge/issues/23) — Kernel invariant: enforce path-overlap rejection on direct tick claim and tick scope | — | Completed | 82 | 78 | 72 | 60 | 292 | — |
    24	| 12 | **290** | [GH-113](https://github.com/HiQS-Suite/XYZ-forge/issues/113) — headless agy builder writes root scratch files, tripping containment (exit 6) | Bulkhead | completed | 85 | 60 | 85 | 60 | 290 | — |
    25	| 13 | **290** | [GH-123](https://github.com/HiQS-Labs/XYZ-forge/issues/123) — Linux portability canary — remainder: gh358 lock contention on shared runners | Linux-RC | in progress | 90 | 80 | 75 | 45 | 290 | — |
    26	| 14 | **290** | [GH-148](https://github.com/HiQS-Suite/XYZ-forge/issues/148) — DeepSeek Harness (dsh) integration & deepseek-turn shim for OpenRouter DeepSeek V4 Pro | — | Completed | 85 | 75 | 90 | 40 | 290 | — |
    27	| 15 | **290** | [GH-168](https://github.com/HiQS-Suite/XYZ-forge/issues/168) — wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR | Bulkhead | completed | 80 | 55 | 85 | 70 | 290 | — |
    28	| 16 | **290** | [GH-226](https://github.com/HiQS-Labs/XYZ-forge/issues/226) — xyz-vendor.sh transcript gate refuses repos that gitignore transcripts | Linux-RC | completed | 75 | 50 | 80 | 85 | 290 | — |
    29	| 17 | **285** | [GH-141](https://github.com/HiQS-Suite/XYZ-forge/issues/141) — make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison | Linux-RC | ad-hoc detour | 80 | 65 | 85 | 55 | 285 | — |
    30	| 18 | **285** | [GH-221](https://github.com/HiQS-Labs/XYZ-forge/issues/221) — GH-221 — agy-turn.sh auth pre-flight breaks on agy CLI >=1.1.19 — whoami subcommand removed | — | Queue / parked intake | 70 | 65 | 70 | 80 | 285 | — |
    31	| 19 | **280** | [GH-114](https://github.com/HiQS-Suite/XYZ-forge/issues/114) — headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7) | Bulkhead | completed | 80 | 60 | 80 | 60 | 280 | — |
    32	| 20 | **280** | [GH-115](https://github.com/HiQS-Suite/XYZ-forge/issues/115) — marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4) | Bulkhead | completed | 75 | 50 | 85 | 70 | 280 | — |
    33	| 21 | **280** | [GH-180](https://github.com/HiQS-Labs/XYZ-forge/issues/180) — repro_builder crashes on timeout telemetry records (exit_code: null → TypeError) | Bulkhead | completed | 70 | 45 | 85 | 80 | 280 | — |
    34	| 22 | **280** | [GH-193](https://github.com/HiQS-Labs/XYZ-forge/issues/193) — AgentChorus Gen 2 | Cargo | queue | 75 | 70 | 85 | 50 | 280 | — |
    35	| 23 | **280** | [GH-216](https://github.com/HiQS-Labs/XYZ-forge/issues/216) — GH-216 — marathon-plan.sh ledger parser rejects link-style ROADMAP.md bullets | — | Queue / parked intake | 75 | 65 | 70 | 70 | 280 | — |
    36	| 24 | **280** | [GH-223](https://github.com/HiQS-Labs/XYZ-forge/issues/223) — GH-223 — pre-push gate push double-applies through ref lock | Cargo | queue | 80 | 75 | 65 | 60 | 280 | — |
    37	| 25 | **280** | [GH-4](https://github.com/HiQS-Suite/XYZ-forge/issues/4) — the pre-push gate does not travel with clones: fresh clones push unverified | — | Completed | 78 | 72 | 70 | 60 | 280 | — |
    38	| 26 | **280** | [GH-77](https://github.com/HiQS-Suite/XYZ-forge/issues/77) — `/standup` — session-scoped triage: what did I leave open, what is rotting, is the plan still right? | — | Completed | 95 | 70 | 85 | 30 | 280 | — |
    39	| 27 | **275** | [GH-1](https://github.com/HiQS-Suite/XYZ-forge/issues/1) — suite-wide fixture containment + clone-identity invariant gate | — | Completed | 80 | 75 | 70 | 50 | 275 | — |
    40	| 28 | **275** | [GH-124](https://github.com/HiQS-Suite/XYZ-forge/issues/124) — eliminate end-of-day closeout friction — automated phase QA receipts, auto-PR creation, and clone lifecycle hygiene | — | Completed | 85 | 60 | 90 | 40 | 275 | — |
    41	| 29 | **275** | [GH-132](https://github.com/HiQS-Suite/XYZ-forge/issues/132) — feat(skills): formal /review-xyz code review skill & multi-model harness | — | Completed | 80 | 70 | 85 | 40 | 275 | — |
    42	| 30 | **275** | [GH-15](https://github.com/HiQS-Suite/XYZ-forge/issues/15) — parallel runs are unreliable in a fresh clone; the GH-528 contention retry is not honoring its contract | — | Completed | 80 | 75 | 70 | 50 | 275 | — |
    43	| 31 | **275** | [GH-170](https://github.com/HiQS-Suite/XYZ-forge/issues/170) — Agent2Agent: close transcript glitches and harden publishing | — | Completed | 75 | 60 | 85 | 55 | 275 | — |
    44	| 32 | **275** | [GH-2](https://github.com/HiQS-Suite/XYZ-forge/issues/2) — test-suite run relocated an untracked file into .tick/orphan-backups/ | Bulkhead | completed | 80 | 55 | 85 | 55 | 275 | — |
    45	| 33 | **275** | [GH-201](https://github.com/HiQS-Labs/XYZ-forge/issues/201) — Gen 3.5 follow-ups — remaining ATE hardening arc (tasks 3–8b of #174) | Cargo | in progress | 80 | 70 | 80 | 45 | 275 | — |
    46	| 34 | **275** | [GH-8](https://github.com/HiQS-Suite/XYZ-forge/issues/8) — kernel boundary hardening — CLI numeric validation, task/agent format contract | Bulkhead | completed | 75 | 55 | 80 | 65 | 275 | — |
    47	| 35 | **270** | [GH-184](https://github.com/HiQS-Labs/XYZ-forge/issues/184) — committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation | Bulkhead | completed | 60 | 40 | 80 | 90 | 270 | — |
    48	| 36 | **270** | [GH-205](https://github.com/HiQS-Labs/XYZ-forge/issues/205) — validate.sh mutates four tracked files per run — gate not idempotent | Linux-RC | in progress | 75 | 70 | 70 | 55 | 270 | — |
    49	| 37 | **270** | [GH-75](https://github.com/HiQS-Suite/XYZ-forge/issues/75) — single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view | — | Queue / parked intake | 90 | 40 | 85 | 55 | 270 | — |
    50	| 38 | **265** | [GH-111](https://github.com/HiQS-Suite/XYZ-forge/issues/111) — retire manifest FREEZE; tasks and marathons are DIALED IN to exactly one release, as a database state | — | Completed | 85 | 75 | 70 | 35 | 265 | — |
    51	| 39 | **265** | [GH-182](https://github.com/HiQS-Labs/XYZ-forge/issues/182) — self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design | Cargo | in progress | 75 | 55 | 80 | 55 | 265 | — |
    52	| 40 | **265** | [GH-50](https://github.com/HiQS-Suite/XYZ-forge/issues/50) — sandboxed git --track / branch -D half-applies and loses uncommitted work | Bulkhead | completed | 65 | 35 | 85 | 80 | 265 | — |
    53	| 41 | **260** | [GH-183](https://github.com/HiQS-Labs/XYZ-forge/issues/183) — active_explorer env-family fuzzing unsound (base_env={} hardcoded, one always-deferring vector, ambient-env leakage) | Bulkhead | completed | 65 | 50 | 75 | 70 | 260 | — |
    54	| 42 | **257** | [GH-215](https://github.com/HiQS-Labs/XYZ-forge/issues/215) — GH-215 — wave_reconcile.py and roadmap-dashboard.sh hardcode pre-vendoring path depth | — | Queue / parked intake | 72 | 60 | 65 | 60 | 257 | — |
    55	| 43 | **255** | [GH-10](https://github.com/HiQS-Suite/XYZ-forge/issues/10) — prevent-half of containment: require_fixture adoption across the fixture-creating suites + adoption guard + ci-local identity bracket | — | Completed | 55 | 70 | 50 | 80 | 255 | — |
    56	| 44 | **255** | [GH-144](https://github.com/HiQS-Suite/XYZ-forge/issues/144) — Agent2Agent 3+ participant onboarding + read-only status quick wins | — | Completed | 55 | 30 | 80 | 90 | 255 | — |
    57	| 45 | **255** | [GH-45](https://github.com/HiQS-Suite/XYZ-forge/issues/45) — validate.sh must refuse to run from a linked worktree — an observed run corrupted the parent clone | — | Completed | 65 | 60 | 60 | 70 | 255 | — |
    58	| 46 | **255** | [GH-91](https://github.com/HiQS-Suite/XYZ-forge/issues/91) — a build turn has nowhere to write verification output | — | Completed | 60 | 65 | 55 | 75 | 255 | — |
    59	| 47 | **250** | [GH-153](https://github.com/HiQS-Suite/XYZ-forge/issues/153) — RELEASES dashboard sidebar + full-cycle rollup (technical spike) | — | Completed | 70 | 55 | 80 | 45 | 250 | — |
    60	| 48 | **250** | [GH-197](https://github.com/HiQS-Suite/XYZ-forge/issues/197) — two-tier xyz-vendor.sh: Tier 1 core-harness default, Tier 2 opt-in RELEASES overlay + onboarding SOP (GH-105 follow-up) | — | Completed | 80 | 55 | 65 | 50 | 250 | — |
    61	| 49 | **250** | [GH-232](https://github.com/HiQS-Labs/XYZ-forge/issues/232) — wave_reconcile should honor linked issue open/closed state before promoting multi-phase docs | Linux-RC | in progress | 70 | 55 | 65 | 60 | 250 | — |
    62	| 50 | **250** | [GH-243](https://github.com/HiQS-Labs/XYZ-forge/issues/243) — GH-169 items 3-4: repoint agent docs + dashboard-staleness push guard | — | Queue | 70 | 55 | 65 | 60 | 250 | — |
    63	| 51 | **250** | [GH-246](https://github.com/HiQS-Labs/XYZ-forge/issues/246) — relay-xyz SKILL.md: explicit QA/Consult prompt template for headless agents (hotfix) | — | Queue / parked intake | 60 | 35 | 70 | 85 | 250 | — |
    64	| 52 | **245** | [GH-108](https://github.com/HiQS-Suite/XYZ-forge/issues/108) — pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override) | Daybreak | cut | 80 | 50 | 75 | 40 | 245 | — |
    65	| 53 | **235** | [GH-222](https://github.com/HiQS-Labs/XYZ-forge/issues/222) — GH-222 — releases update cannot re-point a release's tracking issue | Cargo | queue | 60 | 40 | 60 | 75 | 235 | — |
    66	| 54 | **230** | [GH-105](https://github.com/HiQS-Suite/XYZ-forge/issues/105) — vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on) | Cargo | queue | 75 | 50 | 60 | 45 | 230 | — |
    67	| 55 | **228** | [GH-102](https://github.com/HiQS-Suite/XYZ-forge/issues/102) — Unify Telemetry Schema & Inspection Tooling Across Fuzzing and ATE | — | Completed | 68 | 45 | 70 | 45 | 228 | — |
    68	| 56 | **222** | [GH-103](https://github.com/HiQS-Suite/XYZ-forge/issues/103) — technical spike: RELEASES SQLite → timeline-ui ledger viewer (RELEASES dashboard view) | — | Completed | 62 | 35 | 75 | 50 | 222 | — |
    69	| 57 | **220** | [GH-3](https://github.com/HiQS-Suite/XYZ-forge/issues/3) — improve-loop.sh --state-dir durability — provenance evidence must not evaporate | — | Completed | 55 | 45 | 55 | 65 | 220 | — |
    70	| 58 | **220** | [GH-32](https://github.com/HiQS-Suite/XYZ-forge/issues/32) — RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI | — | Queue / parked intake | 70 | 50 | 65 | 35 | 220 | — |
    71	| 59 | **220** | [GH-57](https://github.com/HiQS-Suite/XYZ-forge/issues/57) — test(releases): SQLite ledger fuzzing recipes & multi-scenario resilience suite | — | Completed | 60 | 45 | 65 | 50 | 220 | — |
    72	| 60 | **218** | GH-135 — GH-135..140 · Wave-1 follow-ups: consult preflight verdict, attempts-gate root, suite registration, twin-divergence record, SIGPIPE sweep+guard, utcnow swap | — | Completed | 58 | 45 | 60 | 55 | 218 | — |
    73	| 61 | **215** | [GH-233](https://github.com/HiQS-Labs/XYZ-forge/issues/233) — AgentChorus Gen 2 Phase 2 — Lifecycle Verbs, Watch Invalidation, Concurrency Suite & Citation Linter | Linux-RC | in progress | 65 | 45 | 75 | 30 | 215 | — |
    74	| 62 | **210** | [GH-5](https://github.com/HiQS-Suite/XYZ-forge/issues/5) — kernel robustness: node:test unit runner | Linux-RC | ad-hoc detour | 45 | 40 | 45 | 80 | 210 | — |
    75	| 63 | **195** | [GH-35](https://github.com/HiQS-Suite/XYZ-forge/issues/35) — 3-tier test suite selection (docs / utility subsystems / core) + CPU governance | — | Completed | 55 | 45 | 50 | 45 | 195 | — |
    76	| 64 | **190** | [GH-39](https://github.com/HiQS-Suite/XYZ-forge/issues/39) — RELEASES app: one-way GitHub Project release-card projection | — | Completed | 50 | 30 | 65 | 45 | 190 | — |
    77	| 65 | **190** | [GH-61](https://github.com/HiQS-Suite/XYZ-forge/issues/62) — RELEASES ledger durability hardening (GH-57 follow-up) | — | Queue / parked intake | 45 | 55 | 40 | 50 | 190 | — |
    78	| 66 | **185** | [GH-17](https://github.com/HiQS-Suite/XYZ-forge/issues/17) — SOP for evaluating new agent harnesses and frontier models | — | Queue / parked intake | 45 | 30 | 50 | 60 | 185 | — |
    79	| 67 | **185** | [GH-42](https://github.com/HiQS-Suite/XYZ-forge/issues/42) — relay automation: supported Commandcode turn-taker | — | Completed | 50 | 35 | 55 | 45 | 185 | — |
    80	| 68 | **175** | [GH-101](https://github.com/HiQS-Suite/XYZ-forge/issues/101) — Feasibility Study: Promoting Programmatic Script Runner (`script_runner.py`) into Core Relay & Consult Runtimes | — | Completed | 45 | 20 | 70 | 40 | 175 | — |
    81	| 69 | **175** | [GH-94](https://github.com/HiQS-Suite/XYZ-forge/issues/94) — research: programmatic tool calling & code-mode execution for harnesses, telemetry, and containment | — | Completed | 45 | 20 | 70 | 40 | 175 | — |
    82	| 70 | **170** | [GH-195](https://github.com/HiQS-Labs/XYZ-forge/issues/195) — marathon-root-audit's blind spot: a direct `python3 marathon_drive.py` call | — | Completed | 60 | 40 | 50 | 20 | 170 | — |
    83	| 71 | **170** | [GH-28](https://github.com/HiQS-Suite/XYZ-forge/issues/28) — RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue | — | Queue / parked intake | 40 | 35 | 40 | 55 | 170 | — |
    84	| 72 | **160** | [GH-18](https://github.com/HiQS-Suite/XYZ-forge/issues/18) — Harness evaluation: Command Code (cmd) and model matrix | — | Queue / parked intake | 35 | 25 | 45 | 55 | 160 | — |
    85	
    86	**Top of the line:** GH-67 — Commandcode builder default widened to `--yolo` — closer evaluation → possible build (score 340, operator override).
    87	
    88	Source: `releases.db` via `export_timeline.py --json`. Regenerate with `bash utils/leaderboard.sh`.
     1	---
     2	title: Combined Roadmap — Cost-Observed Marathon Loops + Adversarial Hardening
     3	status: Active
     4	created: 2026-06-16
     5	updated: 2026-08-21
     6	branch: main
     7	supersedes: PROJECT/2-WORKING/ROADMAP-COMBINED.md (promoted to canonical 2026-06-17); folds in the former standalone ROADMAP.md (adversarial-hardening track, now Part B)
     8	synthesizes:
     9	  - PROJECT/1-INBOX/LOOPS.md
    10	  - PROJECT/4-MISC/COST-OBSERVABILITY-PLAN.md
    11	  - PROJECT/1-INBOX/MARATHON.md
    12	goal: >
    13	  Keep one long-horizon marathon under load at all times — work long, parallel, and failure-prone
    14	  enough to tax the whole XYZ system (worktree isolation, path claims, the driver lock, multi-round
    15	  handoff, escalation, resume). That purpose is a work-selection filter: prefer the marathon-shaped
    16	  candidate, run only real work (an idle gap is honest; a manufactured marathon is not), and treat
    17	  the failures a run surfaces as the deliverable. See AGENTS.md -> Repo-specific rails for the four
    18	  rules. Mechanically, this file is the canonical pointer/ledger index for that work — queued
    19	  intake, in progress, completed, and deferred — linking to the PROJECT/** docs that own the
    20	  execution detail. It is an index, not a plan body.
    21	---
    22	
    23	<!-- PDDA ROADMAP CONTRACT — this file is a POINTER/LEDGER, not a plan body.
    24	     Allowed: queued intake / projects in progress / completed / attempted / deferred + links to PROJECT/** docs.
    25	     NOT allowed: phase checklists, build steps, deep execution notes — put those in the project doc.
    26	     Carve-out: a SHORT exception note is OK only when omitting it would hide an operationally critical fact.
    27	     Coverage rule: every PROJECT/2-WORKING doc must be reflected here by a pointer (or opt out with roadmap_exempt: true).
    28	     Enforced by `utils/pdda/pdda.sh roadmap` + `utils/pdda/pdda.sh roadmap-coverage` (deterministic) + `utils/pdda/pdda.sh doc-ready` ROADMAP rubric (LLM).      SHADOW (GH-69): this ledger is mirrored into releases.db's roadmap_items table. After editing
    29	     the ledger, run `python3 utils/py/releases_app.py roadmap sync` (a no-change sync is a free
    30	     no-op). This file remains the ONLY source of truth; the sync is one-way and never writes here.
    31	-->
    32	
    33	# Combined Roadmap: Cost-Observed Marathon Loops + Adversarial Hardening
    34	
    35	> **Pointer/ledger only — not a plan body.** Execution detail (phase checklists, build steps, QA
    36	> gates, deep notes) lives in the linked `PROJECT/**` docs; keep it there. See the contract banner above.
    37	
    38	Three tracks, sequenced independently:
    39	
    40	- **Part A — Marathon:** cost observability (done) → headless multi-phase chaining (done) → real-monolith dogfood (active)
    41	- **Part B — Adversarial Hardening:** epoch fencing (done) → chaos suite → cross-repo E2E → reference deploy
    42	- **Part C — Autonomous Self-Improvement:** the gated LOOPS.md endgame
    43	
    44	## Status
    45	
    46	| What was just completed | What's next |
    47	|---|---|
    48	| **2026-08-19:** release **0.7.1 “Bulwark”** cut end-to-end through the RELEASES CLI, merged (PR #66), and **SHIPPED** the same day — the first release never hand-edited, and the first shipped through `releases ship` with its exit-criterion evidence recorded in the receipt chain (`gh32-releases-artifacts` 10/0, `gh53-releases-merge-resolve` 15/0, `gh54-merged-dump-refusals` 19/0, `check` clean at generation 9). **PR #55** (GH-35 tiered test selection + CPU governance; GH-45 worktree-gate refusal) and **PR #60** (GH-57 SQLite ledger fuzzing, 42/0) merged. **PR #70** closed GH-57’s live-merge gap: `test/gh57-live-merge-resolve.sh` (30/0) drives a REAL `git merge` and found four resolver defects, all fixed (failed-resolve half-closed the merge; rewound generation header accepted; `releases.db.bak` committable; `--root ""` retargeting). This ledger was purged of 256 upstream-numbered entries the same day (see below) and reconciled against GitHub issue state. | **[#75](https://github.com/HiQS-Suite/XYZ-forge/issues/75)** — single-page HTML dashboard over both DB subsystems (**front of the line, operator call 2026-08-19**). **[#67](https://github.com/HiQS-Suite/XYZ-forge/issues/67) (P1)** — decide the Commandcode `--yolo` default landed silently by PR #60. **[#59](https://github.com/HiQS-Suite/XYZ-forge/issues/59)** — re-arm hosted CI: the repo is public and Actions is enabled, yet pushes produce no runs. **[#58](https://github.com/HiQS-Suite/XYZ-forge/issues/58)** — GH-35 Phase 3 follow-ups (tier-2 hygiene gap P2 + two P3s), recommended to ride with Phase 3. **[#61](https://github.com/HiQS-Suite/XYZ-forge/issues/61)** — RELEASES ledger durability hardening (#62–#65). Next release on the shelf: **0.6.0 “Meter”**, target 2026-09-26. External contributions resolved 2026-08-21: PR #51, #99 and #119 merged; **PR #29 closed** — its tooling half landed as #51, but its Windows/MSYS2 *evidence* half never landed anywhere and was requested as a follow-up, so that platform still has no coverage. |
    49	
    50	### Immediate next-up (ordered)
    51	
    52	> **THE MARATHON — [#179](https://github.com/HiQS-Suite/XYZ-forge/issues/179) (release 0.7.3 "Bulkhead": harness reliability hardening).**
    53	> **Handed over from [#77](https://github.com/HiQS-Suite/XYZ-forge/issues/77) on 2026-08-22 — Daybreak SHIPPED** (0.7.2, all
    54	> four waves merged, gh77 suite green, #77/#82-#87 closed with evidence). Bulkhead is the next arc,
    55	> built from the 2026-08-22 radar targets: the suite-containment class (both polarities), headless-turn
    56	> reliability, and the roadmap-reconcile writer. Twelve members (7 radar targets 2026-08-22 + 5 Gen 3.5
    57	> soak defects 2026-08-23), disjoint-leaning write-sets, each with a
    58	> capture doc + preflight contract:
    59	> **[#113](https://github.com/HiQS-Suite/XYZ-forge/issues/113)** headless scratch containment (rated 85/60/85/60 → [GH-113-HEADLESS-SCRATCH-CONTAINMENT.md](PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md)) ·
    60	> **[#114](https://github.com/HiQS-Suite/XYZ-forge/issues/114)** headless TTY/idle hang (rated 80/60/80/60 → [GH-114-HEADLESS-TTY-IDLE-HANG.md](PROJECT/2-WORKING/GH-114-HEADLESS-TTY-IDLE-HANG.md)) ·
    61	> **[#115](https://github.com/HiQS-Suite/XYZ-forge/issues/115)** round-cap escalation (rated 75/50/85/70 → [GH-115-ROUND-CAP-ESCALATION.md](PROJECT/2-WORKING/GH-115-ROUND-CAP-ESCALATION.md)) ·
    62	> **[#168](https://github.com/HiQS-Suite/XYZ-forge/issues/168)** wave_reconcile scope (rated 80/55/85/70 → [GH-168-WAVE-RECONCILE-SCOPE.md](PROJECT/2-WORKING/GH-168-WAVE-RECONCILE-SCOPE.md)) ·
    63	> **[#8](https://github.com/HiQS-Suite/XYZ-forge/issues/8)** kernel boundary hardening (rated 75/55/80/65 → [GH-8-KERNEL-BOUNDARY-HARDENING.md](PROJECT/2-WORKING/GH-8-KERNEL-BOUNDARY-HARDENING.md)) ·
    64	> **[#2](https://github.com/HiQS-Suite/XYZ-forge/issues/2)** orphan-backup relocation (rated 80/55/85/55 → [GH-2-ORPHAN-BACKUP-RELOCATION.md](PROJECT/2-WORKING/GH-2-ORPHAN-BACKUP-RELOCATION.md)) ·
    65	> **[#50](https://github.com/HiQS-Labs/XYZ-forge/issues/50)** sandboxed git half-apply (rated 65/35/85/80 → [GH-50-SANDBOXED-GIT-HALF-APPLY.md](PROJECT/2-WORKING/GH-50-SANDBOXED-GIT-HALF-APPLY.md)) ·
    66	> **[#180](https://github.com/HiQS-Labs/XYZ-forge/issues/180)** repro-builder timeout-record crash (rated 70/45/85/80 → [GH-180-REPRO-TIMEOUT-CRASH.md](PROJECT/2-WORKING/GH-180-REPRO-TIMEOUT-CRASH.md)) ·
    67	> **[#181](https://github.com/HiQS-Labs/XYZ-forge/issues/181)** repro-builder telemetry fidelity (rated 90/75/90/60 → [GH-181-REPRO-ADAPTER-FIDELITY.md](PROJECT/2-WORKING/GH-181-REPRO-ADAPTER-FIDELITY.md)) ·
    68	> **[#182](https://github.com/HiQS-Labs/XYZ-forge/issues/182)** self-healer facade/safety (rated 75/55/80/55 → [GH-182-HEALER-FACADE-SAFETY.md](PROJECT/2-WORKING/GH-182-HEALER-FACADE-SAFETY.md)) ·
    69	> **[#183](https://github.com/HiQS-Labs/XYZ-forge/issues/183)** explorer env-family soundness (rated 65/50/75/70 → [GH-183-EXPLORER-ENV-SOUNDNESS.md](PROJECT/2-WORKING/GH-183-EXPLORER-ENV-SOUNDNESS.md)) ·
    70	> **[#184](https://github.com/HiQS-Labs/XYZ-forge/issues/184)** tracked scratch artifact (rated 60/40/80/90 → [GH-184-TRACKED-SCRATCH-ARTIFACT.md](PROJECT/2-WORKING/GH-184-TRACKED-SCRATCH-ARTIFACT.md)).
    71	> The five #180–#184 members joined 2026-08-23 from the Gen 3.5 soak (#174/#177) — the first
    72	> cohort auto-filed under SOP §1's auto-file rule. Marathon now twelve members.
    73	> Plan computed and preflighted, NOT fired — operator fires per GUIDING-PRINCIPLES §8.
    74	
    75	> **Previous marathon (completed) — [#77](https://github.com/HiQS-Suite/XYZ-forge/issues/77) (`collect.sh`: the eight `/standup` lenses).**
    76	> Exactly one long-horizon marathon is in flight at a time (AGENTS.md → Repo-specific rails); this is it.
    77	> **Handed over from [#10](https://github.com/HiQS-Suite/XYZ-forge/issues/10) on 2026-08-19 by operator
    78	> call** — recorded as a deliberate swap rather than a second marathon, which the rail forbids. #10
    79	> stands down to ⏸️ and keeps its Ballast-cut history; it is the obvious next candidate when this lands.
    80	> #77 qualifies on the same filter: **eight near-identical work units**, one per lens, each with an
    81	> identical transform (bounded read → six required fields → fixture → assertions) and a machine-checkable
    82	> pass condition (`collect.sh --fixture lens-<n>` feeds `triage.py` with no `D5`, suite green). It taxes
    83	> the harness where a short task never does — eight parallel lanes editing one shared `collect.sh` and one
    84	> shared suite, which is exactly the path-claim and collision surface the swarm exists to manage. A lane
    85	> clobbering another's edit is the failure this run is meant to surface, and surfacing it is the
    86	> deliverable (rail 4). Shipping under release **0.7.2 "Daybreak"**.
    87	> Everything numbered below rides *alongside* it, not instead of it.
    88	
    89	1. **[#75](https://github.com/HiQS-Suite/XYZ-forge/issues/75) — build the single-page dashboard** over `releases` + `roadmap_items`. Deliberately **not** the marathon: it is one generator emitting one file and taxes nothing. It is the instrument you watch the marathon through — the drift this week (a shipped release left `active`, four stale status markers) was invisible until someone audited by hand. Also the first real consumer of the GH-69 shadow rows, which was #69's stated gate for its later stages.
    90	2. **[#67](https://github.com/HiQS-Suite/XYZ-forge/issues/67) — P1: ratify or revert the Commandcode `--yolo` default.** A permission-posture change to a builder default, landed inside a fuzzing PR, undecided.
    91	3. **[#59](https://github.com/HiQS-Suite/XYZ-forge/issues/59) — find out why hosted CI fires on nothing**, then narrow triggers to push/merge on `development` + `main` and wire the required check behind `main`'s new branch protection. **The "fires on nothing" half RESOLVED ITSELF at 17:09 UTC on 2026-08-21** — `pull_request` (run 32506672733) and `push` on `development` (run 32506697196) both fired normally, with no change to the workflow's triggers, after four days and three check-less merges (#116, #121, #122). Cause not established; it changed between 16:45 and 17:09 UTC, and the audit log needs `admin:org` — **if you flipped a setting in that window, record it on the issue.** Seven hypotheses were ruled out with evidence during the outage (billing was the leading theory and was wrong). **Still open:** narrowing the triggers and wiring the required check behind `main`'s branch protection — and note that both new runs concluded *success* while the canary job failed, so a green PR here currently proves nothing until #123 clears. History codified in `.github/workflows/ci.yml`'s header. rated 75/60/40/70.
    92	4. **[#123](https://github.com/HiQS-Suite/XYZ-forge/issues/123) — clear the Linux portability canary**: 7 failing assertions across 5 suites, found by the FIRST end-to-end run of that job (2026-08-21, run 32504570094). It had been dying at step 1 on a missing shebang and reporting the run green since the 2026-08-17 re-arm — advisory jobs make their own failures invisible. Two of the seven are new code from #116 (`utils/leaderboard.sh` ordering, `roadmap sync` dry-run), so they are drift we shipped, not drift we inherited. Per #232, reproduce in a container before calling any of them environment noise. rated 70/55/45/65.
    93	5. **[#58](https://github.com/HiQS-Suite/XYZ-forge/issues/58) — GH-35 Phase 3**, folding in the tier-2 hygiene gap (P2) and the two P3 defects from the PR #55 review.
    94	
    95	> **Standing radar finding (2026-08-19, 21-day window, 122 commits on `development`):** flow is
    96	> roughly **Run 72% / Grow 16% / Transform 0%** — no `PROJECT/**` doc declares `rgt: transform`, so
    97	> by the strict rule no transform work can be *claimed*, not that none happened. The dominant defect
    98	> cluster is **guards that could not report red**: the dashboard check verified its own output (three
    99	> stale dashboards reached `development` under a green gate on 2026-07-30 alone), the pre-push hook
   100	> double-niced and blocked itself, and GH-57's resolver held four defects invisible until a real
   101	> `git merge` was driven. One durable fix — every guard ships a recorded negative control against the
   102	> *real* artifact — retires the cluster. That is release **0.2.0 Litmus**'s declared scope.
   103	
   104	> **Provenance note (2026-08-19):** this repo succeeds
   105	> [`xyz-3-agents-swarm`](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm); the migration kept the old GH numbering in
   106	> inherited ledger entries. 256 upstream-numbered entries were removed from this ledger on the
   107	> operator's call and preserved verbatim in
   108	> [docs/ROADMAP-UPSTREAM-ARCHIVE.md](docs/ROADMAP-UPSTREAM-ARCHIVE.md) ([#69](https://github.com/HiQS-Suite/XYZ-forge/issues/69)).
   109	> Every `GH-nnn` below refers to THIS repo's issues.
   110	
   111	## Model assignment (heuristic)
   112	
   113	Mechanical / pattern-following work → **Sonnet High**; trust-critical kernel-correctness reasoning
   114	(epoch-fencing kernel, dup-token determinism) → **Opus**. Full build-track table:
   115	[MARATHON-HARNESS.md → Model assignment](PROJECT/3-COMPLETED/MARATHON-HARNESS.md#model-assignment-build-track-guidance).
   116	
   117	> **Operational note (carve-out — operationally critical):** Gemini CLI retired 2026-06-19; **agy**
   118	> (Antigravity CLI) is the permanent cross-model lane. **Run agy turns sandbox-OFF** (it exits 0 with
   119	> empty output when its backend is blocked) and an agy lane is **cost-blind** (no token output).
   120	> Detail: [MARATHON-HARNESS.md → Operational note](PROJECT/3-COMPLETED/MARATHON-HARNESS.md#operational-note--cross-model-lane).
   121	
   122	## Ledger
   123	
   124	### Ad-hoc detours
   125	
   126	*(empty — GH-23 closed and moved to Completed 2026-08-19. Heading kept so an out-of-band
   127	detour has a home; note that the marathon planner does NOT read this section — see `## Entry format`.)*
   128	
   129	### Queue / parked intake
   130	- **GH-223 — pre-push gate push double-applies through ref lock** (2026-08-24) - gate-green push reports its own landed commit as a lock rejection; observed 2x of ~10 gated pushes; quick-fix shape. Captured via /idea; dialed into 0.9.0 Cargo. Issue [#223](https://github.com/HiQS-Labs/XYZ-forge/issues/223). -> [PROJECT/1-INBOX/GH-223-GATE-PUSH-DOUBLE-APPLY.md](PROJECT/1-INBOX/GH-223-GATE-PUSH-DOUBLE-APPLY.md)
   131	- **GH-222 — releases update cannot re-point a release's tracking issue** (2026-08-24) - a superseded tracking umbrella (LTVera-Pandas #225→#236) leaves the ledger permanently pointing at a closed issue; `releases update` has no `--tracking-issue` and `reconcile` only fills TMP refs. Dialed into 0.7.3 Bulkhead by operator 2026-08-24. Issue [#222](https://github.com/HiQS-Labs/XYZ-forge/issues/222). -> [PROJECT/1-INBOX/GH-222-RELEASES-TRACKING-REPOINT.md](PROJECT/1-INBOX/GH-222-RELEASES-TRACKING-REPOINT.md)
   132	- **GH-221 — agy-turn.sh auth pre-flight breaks on agy CLI >=1.1.19 — whoami subcommand removed** (2026-08-24) - `whoami` no longer exists in agy CLI >=1.1.19, so the auth pre-flight hard-fails every headless agy-turn.sh run and misreports it as a login problem. Bug filed via /file-xyz-bug from `aegis-sleuth-slack-bot`. Issue [#221](https://github.com/HiQS-Labs/XYZ-forge/issues/221). -> [PROJECT/1-INBOX/GH-221-AGY-WHOAMI-PREFLIGHT.md](PROJECT/1-INBOX/GH-221-AGY-WHOAMI-PREFLIGHT.md)
   133	- **GH-215 — wave_reconcile.py and roadmap-dashboard.sh hardcode pre-vendoring path depth** (2026-08-24) - both assume a bare `utils/` at repo root; under vendored `.xyz/` they die on missing files / ENOENT. Fixed locally in the reporting repo, not yet upstream. Bug filed via /file-xyz-bug from `LTVera-Pandas`. Issue [#215](https://github.com/HiQS-Labs/XYZ-forge/issues/215). -> [PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md](PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md)
   134	- **GH-216 — marathon-plan.sh ledger parser rejects link-style ROADMAP.md bullets** (2026-08-24) - reconciler never completes in a repo whose ROADMAP.md uses `- [Title](path) — ...` bullets; exit 3 every time. Open design question, not patched. Bug filed via /file-xyz-bug from `LTVera-Pandas`. Issue [#216](https://github.com/HiQS-Labs/XYZ-forge/issues/216). -> [PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md](PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md)
   135	- **GH-105 · vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on)** 🆕 **queued 2026-08-20; sole frozen manifest entry of new release 0.9.0 "Cargo" (target 2026-09-19, before Meter, operator call); delivery contract superseded by GH-197 (two-tier, 2026-08-23)** — was: always in the vendored payload, never wired by default: `releases_app.py` + merge resolver + FAQs + `utils/timeline/`, with target-repo ledger state at the target root and GH-312 preserve-list coverage. rated 75/50/60/45. → [GH-105-VENDOR-RELEASES-ADDON.md](PROJECT/1-INBOX/GH-105-VENDOR-RELEASES-ADDON.md) · [#105](https://github.com/HiQS-Suite/XYZ-forge/issues/105)
   136	- **GH-75 · single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view** 🆕 **queued 2026-08-19 at the FRONT of the line (operator call)** — a `releases dashboard` verb renders one self-contained HTML file from `releases.db`, with a card per release (version, codename, status, target, days-to-target, manifest open/closed split, exit criterion) and a card per `roadmap_items` row grouped by section in ledger order, plus a header strip carrying generation, receipt count, and a stale-sync banner when `ROADMAP.md` is ahead of the shadow. Read-only by construction: no writer lock, no generation bump, no receipt — safe to run mid-merge. First real consumer of the GH-69 shadow rows. rated 90/40/85/55. → [#75](https://github.com/HiQS-Suite/XYZ-forge/issues/75)
   137	- **GH-61 · RELEASES ledger durability hardening (GH-57 follow-up)** 🆕 **queued 2026-08-19 — filed 2026-08-19 out of the PR #60 review and un-triaged until now** — four scoped test follow-ups under one parent: exact ledger state asserted after crash recovery ([#62](https://github.com/HiQS-Suite/XYZ-forge/issues/62)), writer-lock stress and owner-death recovery ([#63](https://github.com/HiQS-Suite/XYZ-forge/issues/63)), seeded malformed-dump property coverage ([#64](https://github.com/HiQS-Suite/XYZ-forge/issues/64)), and a portable artifact-hash helper ([#65](https://github.com/HiQS-Suite/XYZ-forge/issues/65)). rated 45/55/40/50. → [#61](https://github.com/HiQS-Suite/XYZ-forge/issues/61)
   138	- **GH-67 · Commandcode builder default widened to `--yolo` — closer evaluation → possible build** 🆕 **queued 2026-08-19 as the NEXT immediate item (operator call, session close)** — PR #60 moved the default from the bounded `--permission-mode auto-accept` to `--yolo` (alias for `--dangerously-skip-permissions`), unmentioned in a fuzzing PR. Evaluate whether the turn shim’s containment (worktree isolation, `ALLOW_PATHS`, commit-bypass guard) genuinely makes the child CLI’s permission mode irrelevant; if yes, RATIFY — write the containment argument down in AGENTS.md/the shim docs and pin it — if no, revert the default and drop the `--yolo` test pin. Sibling check either way: `claude-turn.py` uses `--permission-mode acceptEdits`; confirm the two adapters differ on purpose. rated 88/80/45/70 ovr 340. → [#67](https://github.com/HiQS-Suite/XYZ-forge/issues/67)
   139	- **GH-32 · RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI** 🚧 **Phase 0+1 BUILT and merged 2026-08-19 (PR #34, builder GLM 5.3 per the #33 evaluation)** — schema/CLI/writer-protocol/canonical-dump/import landed (`utils/py/releases_app.py`, suite 81/0, full gate green, independently verified); the PRD survived a 4-round Codex sol-high relay review first. Still ahead: the `/releases` route migration (Phase 0 entry gate for the measured dogfood window), the Phase 2 strict flip, and the Phase 3 cockpit card. rated 70/50/65/35. → [GH-32-RELEASES-APP-SQLITE.md](PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md) · [#32](https://github.com/HiQS-Suite/XYZ-forge/issues/32) · [#33](https://github.com/HiQS-Suite/XYZ-forge/issues/33)
   140	- **GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue** 🆕 **queued 2026-08-18, sharpened via /consult (single-model, agy quota-failed) 2026-08-18, post-Ballast 0.7.0 follow-up** — root cause is two gaps: the discipline rubric only fires on manual `/releases clean`, and release-level notes have no home of their own. Consult caught that the original plan would've reversed documented "never blocks" policy and that the parser can't see continuation-paragraph bloat at all — both fixed: checks are now permanently advisory, scoped to active/unshipped blocks, with a required parser-folding step. rated 40/35/40/55. → [GH-28-RELEASES-LEDGER-DISCIPLINE.md](PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md) · [#28](https://github.com/HiQS-Suite/XYZ-forge/issues/28)
   141	- **GH-17 · SOP for evaluating new agent harnesses and frontier models** 🆕 **queued 2026-08-16** — establish a standardized operating procedure, checklist, and per-harness tracking issue workflow for new harness discovery, isolation, non-interactive execution, and cross-model matrix evaluation. rated 45/30/50/60. → [GH-17-SOP-HARNESS-MODEL-EVAL.md](PROJECT/1-INBOX/GH-17-SOP-HARNESS-MODEL-EVAL.md) · [#17](https://github.com/HiQS-Suite/XYZ-forge/issues/17)
   142	- **GH-18 · Harness evaluation: Command Code (cmd) and model matrix** 🆕 **queued 2026-08-16** — evaluate Command Code CLI (v1.26.0), PATH resolution, auth, non-interactive `-p` execution, and model review benchmarks with `qwen/qwen3.7-flash` and `qwen/qwen3.8-max`. rated 35/25/45/55. → [GH-18-COMMANDCODE-EVAL.md](PROJECT/1-INBOX/GH-18-COMMANDCODE-EVAL.md) · [#18](https://github.com/HiQS-Suite/XYZ-forge/issues/18)
   143	### In progress
   144	- **GH-232 · wave_reconcile should honor linked issue open/closed state before promoting multi-phase docs** 🚧 **active 2026-08-25 for release 0.7.4 "Linux-RC" (#224)** — inspect linked GitHub issue state before doc promotion; keep docs in PROJECT/2-WORKING/ while linked issue is OPEN; append merge evidence without moving file. cx2/risk2/eff2. → [GH-232-WAVE-RECONCILER-MULTIPHASE.md](PROJECT/2-WORKING/GH-232-WAVE-RECONCILER-MULTIPHASE.md) · [#232](https://github.com/HiQS-Labs/XYZ-forge/issues/232)
   145	- **GH-233 · AgentChorus Gen 2 Phase 2 — Lifecycle Verbs, Watch Invalidation, Concurrency Suite & Citation Linter** 🚧 **active 2026-08-25 for release 0.7.4 "Linux-RC" (#224)** — operator-mediated invite with SKILL.md invariant reconciliation, atomic start --supersedes, terminal watch invalidation, multi-agent concurrency stress suite, and verify-citations ref-pinning linter. cx3/risk2/eff3. → [GH-233-AGENTCHORUS-GEN2-PHASE2.md](PROJECT/2-WORKING/GH-233-AGENTCHORUS-GEN2-PHASE2.md) · [#233](https://github.com/HiQS-Labs/XYZ-forge/issues/233)
   146	- **GH-204 · BSD `sed -i ''` no-ops on Linux at production call sites** 🚧 **active 2026-08-24 for release 0.7.4 "Linux-RC" (#224 Phase 2) — marathon lane computed, not fired** — portable in-place edits in `build-launch-artifact.sh` + `meter-release.sh`, content-asserted escalation write in the authoritative Python lane (`relay_drive.py`; the Bash twin is FROZEN per GH-308), and a gate-registered content-assertion regression suite. cx2/risk2/eff2. → [GH-204-BSD-SED-PORTABILITY.md](PROJECT/2-WORKING/GH-204-BSD-SED-PORTABILITY.md) · [#204](https://github.com/HiQS-Labs/XYZ-forge/issues/204)
   147	- **GH-205 · validate.sh mutates four tracked files per run — gate not idempotent** 🚧 **active 2026-08-24 for release 0.7.4 "Linux-RC" (#224 Phase 2) — marathon lane computed, not fired** — fixture-isolate `test/gh174-harness-registry.sh` (writes into `$ROOT/harnesses.db` + blog doc) so a pristine checkout stays porcelain-clean through a full gate; pinned by a new regression suite. cx2/risk1/eff2. → [GH-205-GATE-IDEMPOTENCY.md](PROJECT/2-WORKING/GH-205-GATE-IDEMPOTENCY.md) · [#205](https://github.com/HiQS-Labs/XYZ-forge/issues/205)
   148	- **GH-123 · Linux portability canary — remainder: gh358 lock contention on shared runners** 🚧 **active 2026-08-24 for release 0.7.4 "Linux-RC" (#224 Phase 2) — marathon lane computed, not fired** — the last live canary failure: make `test/gh358-lock-instrumentation.sh` deterministic under shared-runner CPU load (`XYZ_LOCK_WAIT_S` tuning or bounded retry); other 4 suites resolved on development / PR #209. cx2/risk2/eff2. → [GH-123-LINUX-CANARY-REMAINDER.md](PROJECT/2-WORKING/GH-123-LINUX-CANARY-REMAINDER.md) · [#123](https://github.com/HiQS-Labs/XYZ-forge/issues/123)
   149	- **GH-182 · self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design** 🚧 **queued 2026-08-23 for THE MARATHON (release 0.7.3 "Bulkhead", #179) — Gen 3.5 soak cohort, auto-filed per SOP §1** — fail-fast sandbox requirements (disposable root covering the target, never the invoking checkout), mandatory regression gate, configurable realistic timeouts, restore-on-any-exit; no reachable in-place patch path. rated 75/55/80/55. → [GH-182-HEALER-FACADE-SAFETY.md](PROJECT/2-WORKING/GH-182-HEALER-FACADE-SAFETY.md) · [#182](https://github.com/HiQS-Labs/XYZ-forge/issues/182)
   150	- **GH-201 · Gen 3.5 follow-ups — remaining ATE hardening arc (tasks 3–8b of #174)** 🚧 **active 2026-08-24 for release 0.9.0 "Cargo" (draft)** — deterministic Phase 1–3 fixes (A1–A9/A11), the remaining data-path wiring (explorer→repro-builder + E2E rewrite), explorer sharpening + per-probe zero-mutation oracle, gated Phase 4 autonomy (full-clone dispatch, GH-221 predicates, budget governor), the five-canary calibration hour, and the Gemma Tier-1 sensor (Part H, advisory-until-calibrated); healer safety rides separately as #182 on Bulkhead. rated 80/70/80/45. → [GH-201-GEN35-FOLLOWUPS.md](PROJECT/2-WORKING/GH-201-GEN35-FOLLOWUPS.md) · [#201](https://github.com/HiQS-Labs/XYZ-forge/issues/201)
   151	- **GH-141 · make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison** 🚧 **active 2026-08-22 on branch `gh141-fuzz-ate-utility`** — one selector owns the synthetic suites (validate.sh `--list` consumed by fuzz-loop, all 14 synthetic suites registered, divergence regression), telemetry de-aliased (nested `classification.status` removed; severity/likely_cause become derived signal from documented exit classes and output classes, consumers updated in-phase), the ATE chain fails loudly (#142's exit-code contract: 0 filed · 3 no-records · 1 gh-failed, propagated through run_variations) with a hermetic stub-`gh` chain regression, and ATE decoupled from Aider (neutral default labels, `expects_edits` grid key fixing #146's 17 false-HIGH no_edit verdicts, turn-shim grid declared, SKILL.md generalized). Phase 3 (generative boundary fuzzing) deliberately NOT scheduled — #143's counted comparison picks the target first, per the issue's own recommendation. rated 80/65/85/55. → [GH-141-FUZZ-ATE-UTILITY.md](PROJECT/2-WORKING/GH-141-FUZZ-ATE-UTILITY.md) · [#141](https://github.com/HiQS-Suite/XYZ-forge/issues/141) · [#142](https://github.com/HiQS-Suite/XYZ-forge/issues/142) · [#146](https://github.com/HiQS-Suite/XYZ-forge/issues/146)
   152	- **GH-5 · kernel robustness: node:test unit runner** 🆕 **active 2026-08-15 on `gh-5/events-quarantine-unit-tests` (public-repo tracker)** — 11 direct unit tests on the built-in `node:test` runner (was 13; the 2 quarantine-dependent tests deferred to #14), zero new dependencies, `npm run test:unit`, `npm test` → `validate.sh` unchanged. The quarantine-in-reader approach was rejected on orchestrator review per the correction on #5 (silent event loss on the concurrent path while writes are non-atomic) and re-routed to #14. **#5 stays open until this PR's tests and #14's atomic write have both landed.** rated 45/40/45/80. → [GH-5-EVENTS-QUARANTINE-UNIT-TESTS.md](PROJECT/2-WORKING/GH-5-EVENTS-QUARANTINE-UNIT-TESTS.md) · [#5](https://github.com/HiQS-Suite/XYZ-forge/issues/5)
   153	### Completed
   154	- **GH-228 · Org rename HiQS-Suite → HiQS-Labs: a hardcoded regex silently drops issue URLs from the roadmap shadow** ✅ **SHIPPED 2026-08-24 (commit 64c2d2d1; issue closed)** — widen regex in releases_app.py to HiQS-(?:Suite|Labs), update default repo and remote in scripts, add regression test in gh69 suite. rated 80/60/75/90. → [GH-228-ROADMAP-ORG-RENAME-REGEX.md](PROJECT/3-COMPLETED/GH-228-ROADMAP-ORG-RENAME-REGEX.md) · [#228](https://github.com/HiQS-Labs/XYZ-forge/issues/228)
   155	- **GH-226 · xyz-vendor.sh transcript gate refuses repos that gitignore transcripts** ✅ **SHIPPED 2026-08-24 (commit 654e4440, QA 3ee2e8f0; issue closed)** — downgrade transcript gitignore check from exit 6 to advisory warning so downstream repos can vendor `.xyz/`. rated 75/50/80/85. → [GH-226-VENDOR-TRANSCRIPT-GATE.md](PROJECT/3-COMPLETED/GH-226-VENDOR-TRANSCRIPT-GATE.md) · [#226](https://github.com/HiQS-Labs/XYZ-forge/issues/226)
   156	- **GH-114 · headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7)** ✅ **SHIPPED 2026-08-24 (PR #214)** — force fully headless invocation (no /dev/tty), and make idle-kills name the real blocker in the turn log. rated 80/60/80/60. → [GH-114-HEADLESS-TTY-IDLE-HANG.md](PROJECT/2-WORKING/GH-114-HEADLESS-TTY-IDLE-HANG.md) · [#114](https://github.com/HiQS-Suite/XYZ-forge/issues/114)
   157	- **GH-113 · headless agy builder writes root scratch files, tripping containment (exit 6)** ✅ **SHIPPED 2026-08-24 (PR #214)** — give headless builder turns a sanctioned scratch lane (.relay-scratch/<turn>/) so debugging temp files relocate instead of failing the turn; tracked-file violations still exit 6. rated 85/60/85/60. → [GH-113-HEADLESS-SCRATCH-CONTAINMENT.md](PROJECT/2-WORKING/GH-113-HEADLESS-SCRATCH-CONTAINMENT.md) · [#113](https://github.com/HiQS-Suite/XYZ-forge/issues/113)
   158	- **GH-91 · a build turn has nowhere to write verification output ** ✅ **SHIPPED 2026-08-24 (PR #214)** — containment kills a complete, green turn** ✅ **CLOSED 2026-08-22 (issue closed; ledger reconciled)** — issue option 1: `.relay-scratch/` as an intrinsic write category — pre-created by `rtl_worktree_begin`, exempted in `rtl_worktree_end` (no signature check; never copied back), exempted-and-discarded in `rtl_check` (non-worktree path), and NAMED in `rtl_turn_prompt` at the point of use. New suite `test/gh91-relay-scratch.sh` 15/0 with controls (stray still exit-6, lookalike prefix not exempt, off-lane copies nothing back); containment-pinning neighbors green. Surfaced by the daybreak wave-1 re-fire after #90. rated 60/65/55/75. → [GH-91-RELAY-SCRATCH-DIR.md](PROJECT/3-COMPLETED/GH-91-RELAY-SCRATCH-DIR.md) · [#91](https://github.com/HiQS-Suite/XYZ-forge/issues/91)
   159	- **GH-168 · wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR** ✅ **SHIPPED 2026-08-24 (PR #220)** — scope the drift check to the reconciled PR; unrelated drift warns without rollback; move-not-add idempotent promotion. rated 80/55/85/70. → [GH-168-WAVE-RECONCILE-SCOPE.md](PROJECT/2-WORKING/GH-168-WAVE-RECONCILE-SCOPE.md) · [#168](https://github.com/HiQS-Suite/XYZ-forge/issues/168)
   160	- **GH-50 · sandboxed git --track / branch -D half-applies and loses uncommitted work** ✅ **SHIPPED 2026-08-24 (PR #220)** — branch ops refuse-or-succeed atomically when .git/config is unwritable. rated 65/35/85/80. → [GH-50-SANDBOXED-GIT-HALF-APPLY.md](PROJECT/2-WORKING/GH-50-SANDBOXED-GIT-HALF-APPLY.md) · [#50](https://github.com/HiQS-Suite/XYZ-forge/issues/50)
12-|--:|------:|------|---------|------|----:|----:|-------:|-------:|-----:|----:|
13-| 1 | **340** | [GH-67](https://github.com/HiQS-Suite/XYZ-forge/issues/67) — Commandcode builder default widened to `--yolo` — closer evaluation → possible build | — | Queue / parked intake | 88 | 80 | 45 | 70 | 283 | 340 |
14:| 2 | **325** | [GH-249](https://github.com/HiQS-Labs/XYZ-forge/issues/249) — ubuntu canary: EUID=0 defeats chmod-based assertions | — | Queue / parked intake | 90 | 85 | 80 | 70 | 325 | — |
15-| 3 | **315** | [GH-181](https://github.com/HiQS-Labs/XYZ-forge/issues/181) — repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2) | Bulkhead | completed | 90 | 75 | 90 | 60 | 315 | — |
16-| 4 | **308** | [GH-204](https://github.com/HiQS-Labs/XYZ-forge/issues/204) — BSD `sed -i ''` no-ops on Linux at production call sites | Linux-RC | in progress | 88 | 85 | 70 | 65 | 308 | — |
27-| 15 | **290** | [GH-168](https://github.com/HiQS-Suite/XYZ-forge/issues/168) — wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR | Bulkhead | completed | 80 | 55 | 85 | 70 | 290 | — |
28-| 16 | **290** | [GH-226](https://github.com/HiQS-Labs/XYZ-forge/issues/226) — xyz-vendor.sh transcript gate refuses repos that gitignore transcripts | Linux-RC | completed | 75 | 50 | 80 | 85 | 290 | — |
29:| 17 | **285** | [GH-141](https://github.com/HiQS-Suite/XYZ-forge/issues/141) — make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison | Linux-RC | ad-hoc detour | 80 | 65 | 85 | 55 | 285 | — |
30-| 18 | **285** | [GH-221](https://github.com/HiQS-Labs/XYZ-forge/issues/221) — GH-221 — agy-turn.sh auth pre-flight breaks on agy CLI >=1.1.19 — whoami subcommand removed | — | Queue / parked intake | 70 | 65 | 70 | 80 | 285 | — |
31-| 19 | **280** | [GH-114](https://github.com/HiQS-Suite/XYZ-forge/issues/114) — headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7) | Bulkhead | completed | 80 | 60 | 80 | 60 | 280 | — |
11-| # | score | task | release | lane | pri | sev | appeal | effort | calc | ovr |
12-|--:|------:|------|---------|------|----:|----:|-------:|-------:|-----:|----:|
13:| 1 | **340** | [GH-67](https://github.com/HiQS-Suite/XYZ-forge/issues/67) — Commandcode builder default widened to `--yolo` — closer evaluation → possible build | — | Queue / parked intake | 88 | 80 | 45 | 70 | 283 | 340 |
14-| 2 | **325** | [GH-249](https://github.com/HiQS-Labs/XYZ-forge/issues/249) — ubuntu canary: EUID=0 defeats chmod-based assertions | — | Queue / parked intake | 90 | 85 | 80 | 70 | 325 | — |
15-| 3 | **315** | [GH-181](https://github.com/HiQS-Labs/XYZ-forge/issues/181) — repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2) | Bulkhead | completed | 90 | 75 | 90 | 60 | 315 | — |
--
84-| 72 | **160** | [GH-18](https://github.com/HiQS-Suite/XYZ-forge/issues/18) — Harness evaluation: Command Code (cmd) and model matrix | — | Queue / parked intake | 35 | 25 | 45 | 55 | 160 | — |
85-
86:**Top of the line:** GH-67 — Commandcode builder default widened to `--yolo` — closer evaluation → possible build (score 340, operator override).
87-
88-Source: `releases.db` via `export_timeline.py --json`. Regenerate with `bash utils/leaderboard.sh`.
33-| 21 | **280** | [GH-180](https://github.com/HiQS-Labs/XYZ-forge/issues/180) — repro_builder crashes on timeout telemetry records (exit_code: null → TypeError) | Bulkhead | completed | 70 | 45 | 85 | 80 | 280 | — |
34-| 22 | **280** | [GH-193](https://github.com/HiQS-Labs/XYZ-forge/issues/193) — AgentChorus Gen 2 | Cargo | queue | 75 | 70 | 85 | 50 | 280 | — |
35:| 23 | **280** | [GH-216](https://github.com/HiQS-Labs/XYZ-forge/issues/216) — GH-216 — marathon-plan.sh ledger parser rejects link-style ROADMAP.md bullets | — | Queue / parked intake | 75 | 65 | 70 | 70 | 280 | — |
36-| 24 | **280** | [GH-223](https://github.com/HiQS-Labs/XYZ-forge/issues/223) — GH-223 — pre-push gate push double-applies through ref lock | Cargo | queue | 80 | 75 | 65 | 60 | 280 | — |
37-| 25 | **280** | [GH-4](https://github.com/HiQS-Suite/XYZ-forge/issues/4) — the pre-push gate does not travel with clones: fresh clones push unverified | — | Completed | 78 | 72 | 70 | 60 | 280 | — |
47-| 35 | **270** | [GH-184](https://github.com/HiQS-Labs/XYZ-forge/issues/184) — committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation | Bulkhead | completed | 60 | 40 | 80 | 90 | 270 | — |
48-| 36 | **270** | [GH-205](https://github.com/HiQS-Labs/XYZ-forge/issues/205) — validate.sh mutates four tracked files per run — gate not idempotent | Linux-RC | in progress | 75 | 70 | 70 | 55 | 270 | — |
49:| 37 | **270** | [GH-75](https://github.com/HiQS-Suite/XYZ-forge/issues/75) — single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view | — | Queue / parked intake | 90 | 40 | 85 | 55 | 270 | — |
50-| 38 | **265** | [GH-111](https://github.com/HiQS-Suite/XYZ-forge/issues/111) — retire manifest FREEZE; tasks and marathons are DIALED IN to exactly one release, as a database state | — | Completed | 85 | 75 | 70 | 35 | 265 | — |
51-| 39 | **265** | [GH-182](https://github.com/HiQS-Labs/XYZ-forge/issues/182) — self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design | Cargo | in progress | 75 | 55 | 80 | 55 | 265 | — |
52-| 40 | **265** | [GH-50](https://github.com/HiQS-Suite/XYZ-forge/issues/50) — sandboxed git --track / branch -D half-applies and loses uncommitted work | Bulkhead | completed | 65 | 35 | 85 | 80 | 265 | — |
53-| 41 | **260** | [GH-183](https://github.com/HiQS-Labs/XYZ-forge/issues/183) — active_explorer env-family fuzzing unsound (base_env={} hardcoded, one always-deferring vector, ambient-env leakage) | Bulkhead | completed | 65 | 50 | 75 | 70 | 260 | — |
54:| 42 | **257** | [GH-215](https://github.com/HiQS-Labs/XYZ-forge/issues/215) — GH-215 — wave_reconcile.py and roadmap-dashboard.sh hardcode pre-vendoring path depth | — | Queue / parked intake | 72 | 60 | 65 | 60 | 257 | — |
55-| 43 | **255** | [GH-10](https://github.com/HiQS-Suite/XYZ-forge/issues/10) — prevent-half of containment: require_fixture adoption across the fixture-creating suites + adoption guard + ci-local identity bracket | — | Completed | 55 | 70 | 50 | 80 | 255 | — |
56-| 44 | **255** | [GH-144](https://github.com/HiQS-Suite/XYZ-forge/issues/144) — Agent2Agent 3+ participant onboarding + read-only status quick wins | — | Completed | 55 | 30 | 80 | 90 | 255 | — |
60-| 48 | **250** | [GH-197](https://github.com/HiQS-Suite/XYZ-forge/issues/197) — two-tier xyz-vendor.sh: Tier 1 core-harness default, Tier 2 opt-in RELEASES overlay + onboarding SOP (GH-105 follow-up) | — | Completed | 80 | 55 | 65 | 50 | 250 | — |
61-| 49 | **250** | [GH-232](https://github.com/HiQS-Labs/XYZ-forge/issues/232) — wave_reconcile should honor linked issue open/closed state before promoting multi-phase docs | Linux-RC | in progress | 70 | 55 | 65 | 60 | 250 | — |
62:| 50 | **250** | [GH-243](https://github.com/HiQS-Labs/XYZ-forge/issues/243) — GH-169 items 3-4: repoint agent docs + dashboard-staleness push guard | — | Queue | 70 | 55 | 65 | 60 | 250 | — |
63-| 51 | **250** | [GH-246](https://github.com/HiQS-Labs/XYZ-forge/issues/246) — relay-xyz SKILL.md: explicit QA/Consult prompt template for headless agents (hotfix) | — | Queue / parked intake | 60 | 35 | 70 | 85 | 250 | — |
64-| 52 | **245** | [GH-108](https://github.com/HiQS-Suite/XYZ-forge/issues/108) — pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override) | Daybreak | cut | 80 | 50 | 75 | 40 | 245 | — |
63-| 51 | **250** | [GH-246](https://github.com/HiQS-Labs/XYZ-forge/issues/246) — relay-xyz SKILL.md: explicit QA/Consult prompt template for headless agents (hotfix) | — | Queue / parked intake | 60 | 35 | 70 | 85 | 250 | — |
64-| 52 | **245** | [GH-108](https://github.com/HiQS-Suite/XYZ-forge/issues/108) — pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override) | Daybreak | cut | 80 | 50 | 75 | 40 | 245 | — |
65:| 53 | **235** | [GH-222](https://github.com/HiQS-Labs/XYZ-forge/issues/222) — GH-222 — releases update cannot re-point a release's tracking issue | Cargo | queue | 60 | 40 | 60 | 75 | 235 | — |
66-| 54 | **230** | [GH-105](https://github.com/HiQS-Suite/XYZ-forge/issues/105) — vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on) | Cargo | queue | 75 | 50 | 60 | 45 | 230 | — |
67-| 55 | **228** | [GH-102](https://github.com/HiQS-Suite/XYZ-forge/issues/102) — Unify Telemetry Schema & Inspection Tooling Across Fuzzing and ATE | — | Completed | 68 | 45 | 70 | 45 | 228 | — |

exec
/bin/zsh -lc "rg --files PROJECT | rg 'GH-(249|251|252|141|67|216|75|215|243|222|201|182|193)-.*\\.md"'$'"'
rg -n -C 4 'GH-249|GH-251|GH-252|GH-216|GH-215|GH-243|GH-222|GH-67|GH-75' ROADMAP-DASHBOARD.md PROJECT/1-INBOX PROJECT/2-WORKING 2>/dev/null | head -n 800
nl -ba PROJECT/PDDA.md | sed -n '625,765p'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-30948-51ksahqx
 succeeded in 0ms:
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md
PROJECT/1-INBOX/GH-249-CANARY-EUID-ROOT-ASSERTIONS.md
PROJECT/1-INBOX/GH-243-ROADMAP-REPOINT-STALENESS-GUARD.md
PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md
PROJECT/1-INBOX/GH-222-RELEASES-TRACKING-REPOINT.md
PROJECT/2-WORKING/GH-193-AGENTCHORUS-GEN2.md
PROJECT/2-WORKING/GH-141-FUZZ-ATE-UTILITY.md
PROJECT/2-WORKING/GH-182-HEALER-FACADE-SAFETY.md
PROJECT/2-WORKING/GH-201-GEN35-FOLLOWUPS.md
ROADMAP-DASHBOARD.md-10-
ROADMAP-DASHBOARD.md-11-| Item | Status | Links |
ROADMAP-DASHBOARD.md-12-| --- | --- | --- |
ROADMAP-DASHBOARD.md-13-| GH-223 — pre-push gate push double-applies through ref lock | — | [#223](https://github.com/HiQS-Labs/XYZ-forge/issues/223) · [PROJECT/1-INBOX/GH-223-GATE-PUSH-DOUBLE-APPLY.md](PROJECT/1-INBOX/GH-223-GATE-PUSH-DOUBLE-APPLY.md) |
ROADMAP-DASHBOARD.md:14:| GH-222 — releases update cannot re-point a release's tracking issue | — | [#222](https://github.com/HiQS-Labs/XYZ-forge/issues/222) · [PROJECT/1-INBOX/GH-222-RELEASES-TRACKING-REPOINT.md](PROJECT/1-INBOX/GH-222-RELEASES-TRACKING-REPOINT.md) |
ROADMAP-DASHBOARD.md-15-| GH-221 — agy-turn.sh auth pre-flight breaks on agy CLI &gt;=1.1.19 — whoami subcommand removed | — | [#221](https://github.com/HiQS-Labs/XYZ-forge/issues/221) · [PROJECT/1-INBOX/GH-221-AGY-WHOAMI-PREFLIGHT.md](PROJECT/1-INBOX/GH-221-AGY-WHOAMI-PREFLIGHT.md) |
ROADMAP-DASHBOARD.md:16:| GH-215 — wave_reconcile.py and roadmap-dashboard.sh hardcode pre-vendoring path depth | — | [#215](https://github.com/HiQS-Labs/XYZ-forge/issues/215) · [PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md](PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md) |
ROADMAP-DASHBOARD.md:17:| GH-216 — marathon-plan.sh ledger parser rejects link-style ROADMAP.md bullets | — | [Title](path) · [#216](https://github.com/HiQS-Labs/XYZ-forge/issues/216) · [PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md](PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md) |
ROADMAP-DASHBOARD.md-18-| GH-105 · vendor the RELEASES DB system + HTML timeline generator into the .xyz payload (optional add-on) | — | [GH-105-VENDOR-RELEASES-ADDON.md](PROJECT/1-INBOX/GH-105-VENDOR-RELEASES-ADDON.md) · [#105](https://github.com/HiQS-Suite/XYZ-forge/issues/105) |
ROADMAP-DASHBOARD.md:19:| GH-75 · single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view | — | [#75](https://github.com/HiQS-Suite/XYZ-forge/issues/75) |
ROADMAP-DASHBOARD.md-20-| GH-61 · RELEASES ledger durability hardening (GH-57 follow-up) | — | [#62](https://github.com/HiQS-Suite/XYZ-forge/issues/62) · [#63](https://github.com/HiQS-Suite/XYZ-forge/issues/63) · [#64](https://github.com/HiQS-Suite/XYZ-forge/issues/64) · [#65](https://github.com/HiQS-Suite/XYZ-forge/issues/65) · [#61](https://github.com/HiQS-Suite/XYZ-forge/issues/61) |
ROADMAP-DASHBOARD.md:21:| GH-67 · Commandcode builder default widened to --yolo — closer evaluation → possible build | — | [#67](https://github.com/HiQS-Suite/XYZ-forge/issues/67) |
ROADMAP-DASHBOARD.md-22-| GH-32 · RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI | — | [GH-32-RELEASES-APP-SQLITE.md](PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md) · [#32](https://github.com/HiQS-Suite/XYZ-forge/issues/32) · [#33](https://github.com/HiQS-Suite/XYZ-forge/issues/33) |
ROADMAP-DASHBOARD.md-23-| GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue | — | [GH-28-RELEASES-LEDGER-DISCIPLINE.md](PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md) · [#28](https://github.com/HiQS-Suite/XYZ-forge/issues/28) |
ROADMAP-DASHBOARD.md-24-| GH-17 · SOP for evaluating new agent harnesses and frontier models | — | [GH-17-SOP-HARNESS-MODEL-EVAL.md](PROJECT/1-INBOX/GH-17-SOP-HARNESS-MODEL-EVAL.md) · [#17](https://github.com/HiQS-Suite/XYZ-forge/issues/17) |
ROADMAP-DASHBOARD.md-25-| GH-18 · Harness evaluation: Command Code (cmd) and model matrix | — | [GH-18-COMMANDCODE-EVAL.md](PROJECT/1-INBOX/GH-18-COMMANDCODE-EVAL.md) · [#18](https://github.com/HiQS-Suite/XYZ-forge/issues/18) |
ROADMAP-DASHBOARD.md-26-| GH-246 · relay-xyz SKILL.md: explicit QA/Consult prompt template for headless agents (hotfix) | — | [GH-246-RELAY-XYZ-QA-TEMPLATE.md](PROJECT/1-INBOX/GH-246-RELAY-XYZ-QA-TEMPLATE.md) · [#246](https://github.com/HiQS-Labs/XYZ-forge/issues/246) |
ROADMAP-DASHBOARD.md:27:| GH-249 · ubuntu canary: EUID=0 defeats chmod-based assertions | — | [GH-249-CANARY-EUID-ROOT-ASSERTIONS.md](PROJECT/1-INBOX/GH-249-CANARY-EUID-ROOT-ASSERTIONS.md) · [#249](https://github.com/HiQS-Labs/XYZ-forge/issues/249) |
ROADMAP-DASHBOARD.md-28-
ROADMAP-DASHBOARD.md-29-## Queue
ROADMAP-DASHBOARD.md-30-
ROADMAP-DASHBOARD.md-31-Summary: 1 items | Tally: 🟢 0 · 🟡 0 · ⏸️ 0 · ⛔ 0 · ✅ 0 · 🔮 0 · 🔲 0
ROADMAP-DASHBOARD.md-32-
ROADMAP-DASHBOARD.md-33-| Item | Status | Links |
ROADMAP-DASHBOARD.md-34-| --- | --- | --- |
ROADMAP-DASHBOARD.md:35:| GH-243 · GH-169 items 3-4: repoint agent docs + dashboard-staleness push guard | — | [GH-243-ROADMAP-REPOINT-STALENESS-GUARD.md](PROJECT/1-INBOX/GH-243-ROADMAP-REPOINT-STALENESS-GUARD.md) · [#243](https://github.com/HiQS-Labs/XYZ-forge/issues/243) |
ROADMAP-DASHBOARD.md-36-
ROADMAP-DASHBOARD.md-37-## In progress
ROADMAP-DASHBOARD.md-38-
ROADMAP-DASHBOARD.md-39-Summary: 9 items | Tally: 🟢 0 · 🟡 0 · ⏸️ 0 · ⛔ 0 · ✅ 0 · 🔮 0 · 🔲 0
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-24.md-70-### 🔧 Reconcile — undocumented partial completion
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-24.md-71-- #14 GH-14 · appendEvent writes non-atomically, so concurrent readers can observe torn event files — `partial`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-24.md-72-
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-24.md-73-### ⚠️ Not yet sequenceable — rate / add doc / add contract
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-24.md:74:- #222 GH-222 — releases update cannot re-point a release's tracking issue — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-24.md:75:- #215 GH-215 — wave_reconcile.py and roadmap-dashboard.sh hardcode pre-vendoring path depth — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-24.md:76:- #216 GH-216 — marathon-plan.sh ledger parser rejects link-style ROADMAP.md bullets — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-24.md-77-- #105 GH-105 · vendor the RELEASES DB system + HTML timeline generator into the .xyz payload (optional add-on) — `unrated`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-24.md:78:- #75 GH-75 · single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view — `needs-doc`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-24.md-79-- #61 GH-61 · RELEASES ledger durability hardening (GH-57 follow-up) — `needs-doc`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-24.md:80:- #67 GH-67 · Commandcode builder default widened to --yolo — closer evaluation → possible build — `needs-doc`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-24.md-81-- #32 GH-32 · RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-24.md-82-- #28 GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-24.md-83-- #17 GH-17 · SOP for evaluating new agent harnesses and frontier models — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-24.md-84-- #18 GH-18 · Harness evaluation: Command Code (cmd) and model matrix — `needs-contract`
--
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-16-non_goals:
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-17-  - Deciding LTVera-Pandas's ROADMAP.md format is wrong and should change to match the parser
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-18-  - Patching the parser without a maintainer call on the intended one-true-format
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-19-related:
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md:20:  - GH-215 (same reconciler chain, two mechanical path-resolution bugs, kept separate — already fixed locally)
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-21-goal: >
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-22-  marathon-plan.sh's ledger parser either accepts link-style ROADMAP.md bullets (this repo's actual
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-23-  format) or the required bold-bullet / "Deferred · vision" format is documented as a hard
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-24-  constraint on consuming repos before they rely on the reconciler.
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-25----
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-26-
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md:27:# GH-216 — marathon-plan.sh ledger parser rejects link-style ROADMAP.md bullets
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-28-
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-29-> **1-INBOX capture**, not the active-work doc — no `## Status` table yet.
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-30-
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-31-## Symptom
--
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-40-- **Worker/CLI:** n/a — invoked via `wave_reconcile.py` → `bash .xyz/utils/marathon-plan.sh`
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-41-- **Sandbox:** off
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-42-
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-43-## Reproduction
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md:44:1. In LTVera-Pandas, run `python3 .xyz/utils/py/wave_reconcile.py --pr <N ...> --dry-run` (with GH-215's path fixes already applied locally).
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-45-2. It reaches `bash .xyz/utils/marathon-plan.sh --dry-run`, which exits 3: `marathon-plan: no ledger items parsed (is '## Ledger' present?)`.
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-46-3. Root cause, traced to `.xyz/utils/py/_marathon_plan.py`'s `_parse_ledger()` (~line 500-533): it only matches bullets styled `^- \*\*` (bold-title) and only recognizes `### <heading>` blocks whose text is in `SECTIONS = ["Queue / parked intake", "In progress", "Completed", "Deferred · vision"]`. LTVera-Pandas's `ROADMAP.md` uses `- [Title](path) — ...` markdown-link bullets, and its fourth section heading is a bare `### Deferred` (no "· vision"). Result: zero bullets match across every section, so the item count is 0 and the script exits 3 — even though the `## Ledger` heading itself is present, making the exit message ("is '## Ledger' present?") misleading about the actual cause.
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-47-
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-48-**Expected:** either the parser accepts this bullet/heading style, or the required format is documented so repos know to conform before depending on the reconciler.
--
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-59-## Impact
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-60-Blocks the reconciler from ever completing successfully in LTVera-Pandas (and presumably any other
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-61-consuming repo using link-style ledger bullets) until resolved. Not patched locally — this is a
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-62-format/design call (widen the parser vs. mandate the bold-bullet format), not a safe mechanical fix
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md:63:like GH-215's two bugs.
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-64-
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-65-## Phase 0 — Diagnose & scope
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-66-> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md-67-> (`PROJECT/PDDA.md` → Discovery & spike phases).
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md-83-- #14 GH-14 · appendEvent writes non-atomically, so concurrent readers can observe torn event files — `partial`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md-84-
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md-85-### ⚠️ Not yet sequenceable — rate / add doc / add contract
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md-86-- #223 GH-223 — pre-push gate push double-applies through ref lock — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md:87:- #222 GH-222 — releases update cannot re-point a release's tracking issue — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md:88:- #215 GH-215 — wave_reconcile.py and roadmap-dashboard.sh hardcode pre-vendoring path depth — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md:89:- #216 GH-216 — marathon-plan.sh ledger parser rejects link-style ROADMAP.md bullets — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md-90-- #105 GH-105 · vendor the RELEASES DB system + HTML timeline generator into the .xyz payload (optional add-on) — `unrated`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md:91:- #75 GH-75 · single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view — `needs-doc`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md-92-- #61 GH-61 · RELEASES ledger durability hardening (GH-57 follow-up) — `needs-doc`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md:93:- #67 GH-67 · Commandcode builder default widened to --yolo — closer evaluation → possible build — `needs-doc`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md-94-- #32 GH-32 · RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md-95-- #28 GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md-96-- #17 GH-17 · SOP for evaluating new agent harnesses and frontier models — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md-97-- #18 GH-18 · Harness evaluation: Command Code (cmd) and model matrix — `needs-contract`
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-20.md-69-### 🔧 Reconcile — undocumented partial completion
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-20.md-70-- #14 GH-14 · appendEvent writes non-atomically, so concurrent readers can observe torn event files — `partial`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-20.md-71-
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-20.md-72-### ⚠️ Not yet sequenceable — rate / add doc / add contract
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-20.md:73:- #75 GH-75 · single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view — `needs-doc`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-20.md-74-- #61 GH-61 · RELEASES ledger durability hardening (GH-57 follow-up) — `needs-doc`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-20.md:75:- #67 GH-67 · Commandcode builder default widened to --yolo — closer evaluation → possible build — `needs-doc`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-20.md-76-- #35 GH-35 · 3-tier test suite selection (docs / utility subsystems / core) + CPU governance — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-20.md-77-- #42 GH-42 · relay automation: supported Commandcode turn-taker — `unrated`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-20.md-78-- #32 GH-32 · RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-20.md-79-- #28 GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue — `needs-contract`
--
PROJECT/1-INBOX/GH-243-ROADMAP-REPOINT-STALENESS-GUARD.md-10-effort: 2
PROJECT/1-INBOX/GH-243-ROADMAP-REPOINT-STALENESS-GUARD.md-11-phases: 1
PROJECT/1-INBOX/GH-243-ROADMAP-REPOINT-STALENESS-GUARD.md-12----
PROJECT/1-INBOX/GH-243-ROADMAP-REPOINT-STALENESS-GUARD.md-13-
PROJECT/1-INBOX/GH-243-ROADMAP-REPOINT-STALENESS-GUARD.md:14:# GH-243 · Repoint agent docs + dashboard-staleness push guard
PROJECT/1-INBOX/GH-243-ROADMAP-REPOINT-STALENESS-GUARD.md-15-
PROJECT/1-INBOX/GH-243-ROADMAP-REPOINT-STALENESS-GUARD.md-16-## Why
PROJECT/1-INBOX/GH-243-ROADMAP-REPOINT-STALENESS-GUARD.md-17-
PROJECT/1-INBOX/GH-243-ROADMAP-REPOINT-STALENESS-GUARD.md-18-The repo flipped to `ROADMAP_SOURCE=releases` (c97f6176), but ROUTER.md/AGENTS.md still direct
--
PROJECT/1-INBOX/GH-249-CANARY-EUID-ROOT-ASSERTIONS.md-10-effort: 2
PROJECT/1-INBOX/GH-249-CANARY-EUID-ROOT-ASSERTIONS.md-11-phases: 1
PROJECT/1-INBOX/GH-249-CANARY-EUID-ROOT-ASSERTIONS.md-12----
PROJECT/1-INBOX/GH-249-CANARY-EUID-ROOT-ASSERTIONS.md-13-
PROJECT/1-INBOX/GH-249-CANARY-EUID-ROOT-ASSERTIONS.md:14:# GH-249 · ubuntu canary: EUID=0 defeats chmod-based assertions
PROJECT/1-INBOX/GH-249-CANARY-EUID-ROOT-ASSERTIONS.md-15-
PROJECT/1-INBOX/GH-249-CANARY-EUID-ROOT-ASSERTIONS.md-16-## Why
PROJECT/1-INBOX/GH-249-CANARY-EUID-ROOT-ASSERTIONS.md-17-
PROJECT/1-INBOX/GH-249-CANARY-EUID-ROOT-ASSERTIONS.md-18-The `portability canary (ubuntu — advisory, never breakage)` job is red on `development` itself,
--
PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md-15-harness_commit: 46075c9
PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md-16-non_goals:
PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md-17-  - Auditing every other vendored script under .xyz/utils/ for the same one-level-too-shallow root-resolution pattern (this capture only confirms the two found)
PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md-18-related:
PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md:19:  - GH-216 (same reconciler chain, open ledger-format question, kept separate — needs a design call, not a mechanical fix)
PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md-20-goal: >
PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md-21-  wave_reconcile.py's subprocess step and roadmap-dashboard.sh's own root-resolution math both
PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md-22-  work correctly out of the box when the harness is vendored under .xyz/, with no hand-patching
PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md-23-  required by the consuming repo.
PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md-24----
PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md-25-
PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md:26:# GH-215 — wave_reconcile.py and roadmap-dashboard.sh hardcode pre-vendoring path depth
PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md-27-
PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md-28-> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md-29-> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md-30-> (`PROJECT/PDDA.md` → GitHub issue intake).
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-23.md-88-- #14 GH-14 · appendEvent writes non-atomically, so concurrent readers can observe torn event files — `partial`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-23.md-89-
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-23.md-90-### ⚠️ Not yet sequenceable — rate / add doc / add contract
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-23.md-91-- #105 GH-105 · vendor the RELEASES DB system + HTML timeline generator into the .xyz payload (optional add-on) — `unrated`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-23.md:92:- #75 GH-75 · single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view — `needs-doc`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-23.md-93-- #61 GH-61 · RELEASES ledger durability hardening (GH-57 follow-up) — `needs-doc`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-23.md:94:- #67 GH-67 · Commandcode builder default widened to --yolo — closer evaluation → possible build — `needs-doc`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-23.md-95-- #32 GH-32 · RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-23.md-96-- #28 GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-23.md-97-- #17 GH-17 · SOP for evaluating new agent harnesses and frontier models — `needs-contract`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-23.md-98-- #18 GH-18 · Harness evaluation: Command Code (cmd) and model matrix — `needs-contract`
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-167-- #261 GH-261 · marathon-drive: reconcile the Bash/Python disjoint-failure union (last Phase-1 gate for the XYZ_PYTHON flip) — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-168-- #266 GH-266 · rtl_worktree_end doesn't exempt relay-system/ (its own transcript dir) — false containment violation discards a fully in-scope turn — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-169-- #263 GH-263 · codex-turn.sh isolation=0 path can't reach the parent-root .tick lock in vendored installs — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-170-- #258 GH-258 · vendor-stack skill — one-step XYZ harness + PDDA governance install into a target repo — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md:171:- #251 GH-251 · OpenRouter/aider reviewer seam doesn't persist its review (builder-only in practice) — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-172-- #199 GH-199 · swe-diagram: add a font picker to the generated diagram HTML (default + Indie Flower) — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-173-- #232 GH-232 · validate.sh: ~12 tests fail on ubuntu-latest CI runner (environment incompatibilities, first exposed by GH-230's CI step) — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-174-- #234 GH-234 · find-harness.sh --env exports TICK_REPO_ROOT one directory too deep (found during GH-177 wipe investigation, never filed) — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-175-- #236 GH-236 · Worktree isolation under $TMPDIR breaks codex turns in /tmp-rooted environments (and escalates as a false timeout) — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-176-- #242 GH-242 · agy S10: off-prompt-nonempty repro — deferred from #155, needs a controlled trigger — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-177-- #247 GH-247 · marathon-triage: bare utils/ paths break in vendored .xyz/ installs — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md:178:- #249 GH-249 · Marathon gate enforces 'existing tests pass', not new-test presence — brief acceptance criteria are advisory prose — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-179-- #250 GH-250 · marathon-triage: emit a default recommendation per item, not symmetric options — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-180-- #245 GH-245 · --target-root review turn cannot report, and relay-drive misclassifies the outcome both ways — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-181-- #241 GH-241 · MARATHON.example.yaml understates sequencing and depends_on's scalar-only shape — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-182-- #238 GH-238 · marathon-drive: pre-advance gate defaults to bash validate.sh — halts AFTER approval in any consuming repo without it — `blocked`
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-187-- #177 GH-177 · mktemp-into-destructive-EXIT-trap recurrence — test/hq-hardening.sh (+2 siblings) rm -rf'd the entire repo a 2nd time — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-188-- #226 GH-226 · Full provenance follow-up should coordinate with the already-reworked consult/relay summary surface — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-189-- #225 GH-225 · 10days/marathon guardrail: isolation:"worktree" lanes can branch from a stale historical commit, not the marathon branch — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-190-- #223 GH-223 · utils/py/consult.py missing GH-178 A4 citation-stamp parity — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md:191:- #222 GH-222 · Marathon end-of-session hygiene: no cost summary in marathon-drive.sh, no worktree cleanup in /10days — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-192-- #189 GH-189 · PDDA: sweeping a doc to 3-COMPLETED silences the only issue-state check watching it — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-193-- #198 GH-198 Bug 1 · rtl_enforce's file-scoped commit had no pathspec (pre-existing staged content could ride into a relay commit) — `needs-doc`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-194-- #213 GH-213/209/203 · 3-lane marathon, all Approved — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-195-- #212 GH-212 · Make marathon builder-default (no billed CLI) and plan-location (PROJECT/2-WORKING) explicit, enforced defaults — `blocked`
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-202-- #173 GH-173 · Jedi Wright beta feedback: agy worktree grounding + reconciliation-layer hardening — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-203-- #175 GH-175 · #173 feedback Phase-1 low-fruit slice: bring-up + README supply-chain docs + Codex preflight attestation — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-204-- #178 GH-178 · #173 feedback split: epistemic/reconciliation-layer hardening (agy grounding, stale warning, advisor pluggability, degraded-panel stamp, verdict provenance) — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-205-- #172 GH-172 · vendored harness root-semantics audit before Python-default cutover — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md:206:- #170 Marathon Plan F · validate.sh's pre-existing failing tests + parity gaps (GH-170, GH-174, GH-215, GH-208, GH-154) — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-207-- #174 GH-174 · agy-turn.py never got GH-171's claim-before-launch guard (XYZ_PYTHON=1 agy turns still exposed) — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md:208:- #215 GH-215 · utils/py/consult.py missing Bash degraded-panel SINGLE-MODEL stamping — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-209-- #208 GH-208 · worktree-isolation.sh: flaky moved-ROOT-HEAD preserve-case race (GH-13/#14 guard) — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-210-- #154 GH-154 · port-drift: marathon-plan shell heredoc vs. Python-layer port diverged (missing GH-48 zone model) — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-211-- #149 Marathon Plan G · marathon/relay driver hardening (GH-149, GH-198) — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-212-- #218 Marathon Plan H · cross-repo live marathon status query (GH-218) — `blocked`
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-215-- #186 GH-186 · aider-turn.sh: --add-gitignore-files removal (775380c) unverified against vendored installs on older aider — risk of silently reopening GH-168 — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-216-- #187 GH-187 · agy isolation-breach detector: second false-positive trigger (markdown citation link), confirmed live-blocking a real marathon lane — `needs-doc`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-217-- #169 GH-169 · Acorn integration (first pass): vendor acorn+acorn-walk as a lightweight JS symbol/call-site extractor for GH-156 — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-218-- #168 GH-168 · aider-turn.sh: --no-gitignore doesn't enable reading gitignored files — missing --add-gitignore-files silently skips relay threads in gitignored dirs — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md:219:- #165 GH-165 · codex-turn: Codex can edit+commit without first owning the relay token, leaving no-progress stalls even after GH-67's release backstop — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-220-- #161 Marathon Plan D · explore-and-plan cluster (GH-161..164) — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-221-- #163 GH-163 · Review wp-code-check / WP-DB-Toolkit for existing fast AST tooling reusable for swarmability — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-222-- #156 GH-156 · Prelight: swarmability scoring using codebase-memory-mcp graph signals — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-223-- #157 GH-157 · Peer research: competitive analysis dashboard for XYZ multi-agent coordination — `blocked`
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
   756	
   757	One repo-owned skill operates on this file: `/releases`. It is a read-first router that synthesizes
   758	the ledger, checks evidence-backed contradictions against `CHANGELOG.md`, reachable commits, merged
   759	PRs, and GitHub Releases when available, then enters cleanup, author/update, historical-anchor, or
   760	publish subroutines only on an explicit operator request. Every mutation and public release is
   761	previewed and confirmation-gated. Its strategic-drift handoff is `/radar`; its frozen path-to-ship
   762	handoff is `/finish-line`. It recommends either only when that distinct goal matches and never
   763	duplicates or auto-invokes their workflows.
   764	
   765	Invocation is operator-triggered by design. The initial synthesis may report contradictions in an

2026-08-26T05:37:15.209846Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "python3 utils/py/releases_app.py list --help
python3 utils/py/releases_app.py roadmap list
nl -ba PROJECT/1-INBOX/GH-249-CANARY-EUID-ROOT-ASSERTIONS.md | sed -n '14,110p'
nl -ba PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md | sed -n '19,120p'
nl -ba PROJECT/1-INBOX/GH-243-ROADMAP-REPOINT-STALENESS-GUARD.md | sed -n '14,120p'
nl -ba PROJECT/1-INBOX/GH-216-LEDGER-BULLET-FORMAT.md | sed -n '20,110p'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-30948-51ksahqx
2026-08-26T05:37:30.826635Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
 succeeded in 7440ms:
2026-08-25 22:37:23.600 xcodebuild[31608:7654379]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:37:23.797 xcodebuild[31608:7654378] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-173KueYk' (errno=Operation not permitted)
2026-08-25 22:37:24.426 xcodebuild[31610:7654399]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:37:24.627 xcodebuild[31610:7654398] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
usage: releases list [-h] [--all-repos] [--status {draft,active,shipped,cut}]

optional arguments:
  -h, --help            show this help message and exit
  --all-repos           aggregate RELEASES_APP_EXTRA_DBS too; duplicate GIDs
                        fail loudly
  --status {draft,active,shipped,cut}
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-JSgv3tV0' (errno=Operation not permitted)
2026-08-25 22:37:26.103 xcodebuild[31618:7654449]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:37:26.303 xcodebuild[31618:7654448] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
python3: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
python3: error: couldn't create cache file '/tmp/xcrun_db-in4GOK4V' (errno=Operation not permitted)
2026-08-25 22:37:26.935 xcodebuild[31620:7654461]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-25 22:37:27.134 xcodebuild[31620:7654460] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
rmi-01M0VAXD51R8WAVVTVNCVXHPJP  GH-228  Completed              #1   cre=-      calc=305      ✅ GH-228 · Org rename HiQS-Suite → HiQS-Labs: a hardcoded regex si
rmi-01M0VAXD5189RZPCE90ZQR6PXQ  GH-226  Completed              #2   cre=-      calc=290      ✅ GH-226 · xyz-vendor.sh transcript gate refuses repos that gitign
rmi-01M0PJQ5PHNFK1ZF7ZMW3YPW4D  GH-114  Completed              #3   cre=-      calc=280      ✅ GH-114 · headless agy -p stalls on TTY allocation / network wait
rmi-01M0PJQ5PGAVHN8M39T1EVP8CA  GH-113  Completed              #4   cre=-      calc=290      ✅ GH-113 · headless agy builder writes root scratch files, trippin
rmi-01M0FWQ1S70PWTTVM7P23QR298  GH-91   Completed              #5   cre=-      calc=255      ✅ GH-91 · a build turn has nowhere to write verification output
rmi-01M0PJQ5PH5F0MDVYSAAWBCFNX  GH-168  Completed              #6   cre=-      calc=290      ✅ GH-168 · wave_reconcile.py hard-fails and rolls back on pre-exis
rmi-01M0PJQ5PHKN3YYWG5FXN5Q661  GH-50   Completed              #7   cre=-      calc=265      ✅ GH-50 · sandboxed git --track / branch -D half-applies and loses
rmi-01M0PJQ5PHTQ61TNS6D22JG95W  GH-2    Completed              #8   cre=-      calc=275      ✅ GH-2 · test-suite run relocated an untracked file into .tick/orp
rmi-01M0T6MXXT5RJZ7SA9523MYSBT  GH-202  Completed              #9   cre=-      calc=305      ✅ GH-202 · wave_reconcile aborts on marathon-plan exit 5 (items he
rmi-01M0RWH5YT8VSNS858ZQSZ59MC  GH-197  Completed              #10  cre=-      calc=250      ✅ GH-197 · two-tier xyz-vendor.sh: Tier 1 core-harness default, Ti
rmi-01M0S8827CVPCVRMWD3PH4E5YZ  GH-193  Completed              #11  cre=-      calc=280      🚧 GH-193 · AgentChorus Gen 2
rmi-01M0DP23VBWM2GPME3CG1R2CE6  GH-1    Completed              #12  cre=-      calc=275      ✅ GH-1 · suite-wide fixture containment + clone-identity invariant
rmi-01M0PHC2T2EHJXC04PWQGH8BJP  GH-174  Completed              #13  cre=-      calc=300      ✅ GH-174 · Harness & Models Registry SQLite Migration: Per-Device 
rmi-01M0PJQ5PHGKS9SWM69368AB3D  GH-115  Completed              #14  cre=-      calc=280      ✅ GH-115 · marathon-drive prematurely escalates productive multi-r
rmi-01M0PJQ5PHZ97ARHEE9PMWGEQ5  GH-8    Completed              #15  cre=-      calc=275      ✅ GH-8 · kernel boundary hardening — CLI numeric validation, task/
rmi-01M0QMC4DSY6B5RDWTNCEZ9Z13  GH-180  Completed              #16  cre=-      calc=280      ✅ GH-180 · repro_builder crashes on timeout telemetry records (exi
rmi-01M0QMC4DSVGA3YQWXM64QWJAV  GH-181  Completed              #17  cre=-      calc=315      ✅ GH-181 · repro_builder emits non-reproducing reproducers from re
rmi-01M0QMC4DSJ0M5JSESKQSQ6HN1  GH-183  Completed              #18  cre=-      calc=260      ✅ GH-183 · active_explorer env-family fuzzing unsound (base_env={}
rmi-01M0QMC4DSR91AGC2Q54QYMBDV  GH-184  Completed              #19  cre=-      calc=270      ✅ GH-184 · committed scratch artifact `.relay-scratch/probe_teleme
rmi-01M0R1R2MGX6WRH12BC42ZZFTH  GH-195  Completed              #20  cre=-      calc=170      ✅ GH-195 · marathon-root-audit's blind spot: a direct `python3 mar
rmi-01M0DP23VB7XZ4620GZAX07X6R  GH-10   Completed              #21  cre=-      calc=255      ✅ GH-10 · prevent-half of containment: require_fixture adoption ac
rmi-01M0DP23V92G58WA014AZYZGPR  GH-35   Completed              #22  cre=-      calc=195      ✅ GH-35 · 3-tier test suite selection (docs / utility subsystems /
rmi-01M0DP23VANQ7D8Y804WVDTEC7  GH-42   Completed              #23  cre=-      calc=185      ✅ GH-42 · relay automation: supported Commandcode turn-taker
rmi-01M0PJ3JY1V5NQ3S5YWSJ8SQP2  GH-170  Completed              #24  cre=-      calc=275      ✅ GH-170 · Agent2Agent: close transcript glitches and harden publi
rmi-01M0NFZYT7W26KQYAW9XEX6JGN  GH-165  Completed              #25  cre=-      calc=295      ✅ GH-165 · Post-Merge Wave & Marathon Lifecycle Reconciler (Docs, 
rmi-01M0JS79CRW0V3185JCYKJTVCK  GH-124  Completed              #26  cre=-      calc=275      ✅ GH-124 · eliminate end-of-day closeout friction — automated phas
rmi-01M0E5Z0TP7WTZFKS6SQYW17KK  GH-77   Completed              #27  cre=-      calc=280      ✅ GH-77 · `/standup` — session-scoped triage: what did I leave ope
rmi-01M0P4QSBGP7GKK8HM5VHMZMF8  GH-153  Completed              #28  cre=-      calc=250      ✅ GH-153 · RELEASES dashboard sidebar + full-cycle rollup (technic
rmi-01M0M6C3M95X21M5BWJA486S59  GH-148  Completed              #29  cre=-      calc=290      ✅ GH-148 · DeepSeek Harness (dsh) integration & deepseek-turn shim
rmi-01M0M1G9VB66EJJC655SKGN7QQ  GH-144  Completed              #30  cre=-      calc=255      ✅ GH-144 · Agent2Agent 3+ participant onboarding + read-only statu
rmi-01M0M0FPFTTE67F27VV3JGKNKC  GH-132  Completed              #31  cre=-      calc=275      ✅ GH-132 · feat(skills): formal /review-xyz code review skill & mu
rmi-01M0P4QSBGXYVQ80FZBX3XNKZG  GH-155  Completed              #32  cre=-      calc=295      🚧 GH-155 · 3rd Gen ATE & Fuzzing
rmi-01M0KXV2WWSQVF6AQ0H4NQ7REY  GH-135  Completed              #33  cre=-      calc=218      ✅ GH-135..140 · Wave-1 follow-ups: consult preflight verdict, atte
rmi-01M0KXV2WW44KYJFGMZJEMD8G8  -       Completed              #34  cre=-      calc=247      ✅ #129/#130/#131 · Wave 1 of the Harness Driver & Relay Seam Harde
rmi-01M0H9CC0981F9CSAMV7BXRYXP  GH-111  Completed              #35  cre=-      calc=265      ✅ GH-111 · retire manifest FREEZE; tasks and marathons are DIALED 
rmi-01M0H9CC0AAF9JWBSHR3679NQQ  GH-108  Completed              #36  cre=-      calc=245      ✅ GH-108 · pri/sev/appeal/effort — the canonical task rating syste
rmi-01M0H9CC0A81K3083ASEGK37HK  -       Completed              #37  cre=-      calc=190      ✅ Execution checklist for GH-111 + GH-108
rmi-01M0FY5VR7R33M0WVBBCNJSTA3  GH-101  Completed              #38  cre=-      calc=175      ✅ GH-101 · Feasibility Study: Promoting Programmatic Script Runner
rmi-01M0GKR98K9X9FYJVH6CPSQ2BP  GH-103  Completed              #39  cre=-      calc=222      ✅ GH-103 · technical spike: RELEASES SQLite → timeline-ui ledger v
rmi-01M0G0PGX85DBNMZC2HSJ6MF7H  GH-102  Completed              #40  cre=-      calc=228      ✅ GH-102 · Unify Telemetry Schema & Inspection Tooling Across Fuzz
rmi-01M0EWSZJX1WYGDFBNMS2TJFT0  GH-94   Completed              #41  cre=-      calc=175      ✅ GH-94 · research: programmatic tool calling & code-mode executio
rmi-01M0DP23V80KAQSQP9C3V07BS0  GH-57   Completed              #42  cre=-      calc=220      ✅ GH-57 · test(releases): SQLite ledger fuzzing recipes & multi-sc
rmi-01M0DP23V9XAQT9ZC2C2P7Y6MT  GH-45   Completed              #43  cre=-      calc=255      ✅ GH-45 · validate.sh must refuse to run from a linked worktree — 
rmi-01M0DP23V90JN51W09HEABFVYX  GH-39   Completed              #44  cre=-      calc=190      ✅ GH-39 · RELEASES app: one-way GitHub Project release-card projec
rmi-01M0DP23V8F0R5ET8B6T536Z81  GH-23   Completed              #45  cre=-      calc=292      ✅ GH-23 · Kernel invariant: enforce path-overlap rejection on dire
rmi-01M0DP23VCTAKM1VSFSAGBDEMG  GH-4    Completed              #46  cre=-      calc=280      ✅ GH-4 · the pre-push gate does not travel with clones: fresh clon
rmi-01M0DP23VCM10Y0A1WGWRPMMFP  GH-14   Completed              #47  cre=-      calc=295      ✅ GH-14 · appendEvent writes non-atomically, so concurrent readers
rmi-01M0DP23VCQXCBHY8XSCPV4CEB  GH-15   Completed              #48  cre=-      calc=275      ✅ GH-15 · parallel runs are unreliable in a fresh clone; the GH-52
rmi-01M0DP23VDGC5DDKFA3CXYXTZB  GH-3    Completed              #49  cre=-      calc=220      ✅ GH-3 · improve-loop.sh --state-dir durability — provenance evide
rmi-01M0X6JSJGH9Y56CPNMGNM6ZAB  GH-232  In progress            #1   cre=-      calc=250      🚧 GH-232 · wave_reconcile should honor linked issue open/closed st
rmi-01M0X6JSJH4TQC1829S1WTCF7H  GH-233  In progress            #2   cre=-      calc=215      🚧 GH-233 · AgentChorus Gen 2 Phase 2 — Lifecycle Verbs, Watch Inva
rmi-01M0V71SH3FKJ7MKA3517P1G2X  GH-204  In progress            #3   cre=-      calc=308      🚧 GH-204 · BSD `sed -i ''` no-ops on Linux at production call site
rmi-01M0V71SH30PCEWR8M80689C53  GH-205  In progress            #4   cre=-      calc=270      🚧 GH-205 · validate.sh mutates four tracked files per run — gate n
rmi-01M0V71SH3R99APE30GB1MA401  GH-123  In progress            #5   cre=-      calc=290      🚧 GH-123 · Linux portability canary — remainder: gh358 lock conten
rmi-01M0QMC4DSZ9V5A2E24T29RGD8  GH-182  In progress            #6   cre=-      calc=265      🚧 GH-182 · self_healer --mode heal is a facade (containment refuse
rmi-01M0S8827CZ9NQR68YWK62DNR8  GH-201  In progress            #7   cre=-      calc=275      🚧 GH-201 · Gen 3.5 follow-ups — remaining ATE hardening arc (tasks
rmi-01M0M5V0KCZE5D0T655AV5E3J8  GH-141  In progress            #8   cre=-      calc=285      🚧 GH-141 · make Fuzzing and ATE actually useful — Phases 1, 2, 4, 
rmi-01M0DP23VBW9KQM2ZAA9Q76YPQ  GH-5    In progress            #9   cre=-      calc=210      🆕 GH-5 · kernel robustness: node:test unit runner
rmi-01M0XTN471MFY38QZF3KRYGC1K  GH-243  Queue                  #1   cre=-      calc=250      🆕 GH-169 items 3-4: repoint agent docs + dashboard-staleness push 
rmi-01M0V4GQBGZE7TZCY3M4AB3CTZ  GH-223  Queue / parked intake  #1   cre=-      calc=280        GH-223 — pre-push gate push double-applies through ref lock
rmi-01M0V232SZZQ6ATM49ADY37H2S  GH-222  Queue / parked intake  #2   cre=-      calc=235        GH-222 — releases update cannot re-point a release's tracking is
rmi-01M0V0JQD8KPV31HM2GH68WRTB  GH-221  Queue / parked intake  #3   cre=-      calc=285        GH-221 — agy-turn.sh auth pre-flight breaks on agy CLI >=1.1.19 
rmi-01M0V0JQD8T7VH32KB1ZX97PD3  GH-215  Queue / parked intake  #4   cre=-      calc=257        GH-215 — wave_reconcile.py and roadmap-dashboard.sh hardcode pre
rmi-01M0V0JQD8MQPVYZ6KBTD1A1C9  GH-216  Queue / parked intake  #5   cre=-      calc=280        GH-216 — marathon-plan.sh ledger parser rejects link-style ROADM
rmi-01M0GKR98JB3PHQE1BN7H77Q3X  GH-105  Queue / parked intake  #6   cre=-      calc=230      🆕 GH-105 · vendor the RELEASES DB system + HTML timeline generator
rmi-01M0DZZGNQVK65X0Y63AYGCM4E  GH-75   Queue / parked intake  #7   cre=-      calc=270      🆕 GH-75 · single-page HTML dashboard: releases (mid/long term) + r
rmi-01M0DZZGNRVEH9GPW7J3VPBP4B  GH-61   Queue / parked intake  #8   cre=-      calc=190      🆕 GH-61 · RELEASES ledger durability hardening (GH-57 follow-up)
rmi-01M0DQ00PCDP50DH1TFMSE4AV4  GH-67   Queue / parked intake  #9   cre=-      calc=283>340  🆕 GH-67 · Commandcode builder default widened to `--yolo` — closer
rmi-01M0DP23VAR6KPD0ZX6Q8WKWZR  GH-32   Queue / parked intake  #10  cre=-      calc=220      🚧 GH-32 · RELEASES app: SQLite-backed release ledger, CLI-only wri
rmi-01M0DP23VACJP47XMYQQ7E37RK  GH-28   Queue / parked intake  #11  cre=-      calc=170      🆕 GH-28 · RELEASES.md ledger discipline: deterministic bloat check
rmi-01M0DP23VA2536KCV4JFBPF7CA  GH-17   Queue / parked intake  #12  cre=-      calc=185      🆕 GH-17 · SOP for evaluating new agent harnesses and frontier mode
rmi-01M0DP23VBN2B2Y62KMKHMBKN6  GH-18   Queue / parked intake  #13  cre=-      calc=160      🆕 GH-18 · Harness evaluation: Command Code (cmd) and model matrix
rmi-01M0XY6RHQAK59HQ9N8YKM8J1J  GH-246  Queue / parked intake  #14  cre=-      calc=250      🆕 relay-xyz SKILL.md: explicit QA/Consult prompt template for head
rmi-01M0Y3QX1CAMG9H5JJNJKYDRBM  GH-249  Queue / parked intake  #15  cre=-      calc=325      🆕 ubuntu canary: EUID=0 defeats chmod-based assertions
    14	# GH-249 · ubuntu canary: EUID=0 defeats chmod-based assertions
    15	
    16	## Why
    17	
    18	The `portability canary (ubuntu — advisory, never breakage)` job is red on `development` itself,
    19	not just on PRs — verified on run 32923564904 (job 98041796632) and PR #247's run (job
    20	98041592682), with byte-identical failing suites on both. Because the job is
    21	`continue-on-error: true`, the workflow still reports success, so genuine Linux drift is invisible.
    22	
    23	The job's own rationale block already pre-committed to a consequence for this exact state
    24	(`.github/workflows/ci.yml:230-232`): if drift ships named-and-unresolved across two consecutive
    25	promotions, the job "should be deleted rather than kept as decoration." The canary is currently in
    26	the state its author said to delete it over.
    27	
    28	Root cause: GitHub's ubuntu runner executes as root (EUID=0), so `chmod`-based negative assertions
    29	cannot hold — root writes a `0444` file and reads a `0000` file regardless of mode bits.
    30	
    31	- `test/gh50-sandboxed-git-guard.sh` — 3 pass, 8 fail (read-only git config never triggers refusal)
    32	- `test/security-scan.sh` — 33 pass, 2 fail (`chmod 000` fixture is read cleanly, no `[scan-error]`)
    33	
    34	## Key Concepts
    35	
    36	- Cross-model consult (2026-08-25, `relay-system/2026-08-25/canary-root-euid-203501/`): Codex and
    37	  agy independently graded "make the guards fail-closed under root" a **Blocker**. The production
    38	  guards are correct as written — they probe actual capability (`: >> "$config"`, `grep` rc > 1)
    39	  rather than inspecting mode bits. Refusing on mode bits would falsely block root-run containers.
    40	- Fix the TESTS, not the guards: add `EUID=0` skips to only the chmod-dependent assertions.
    41	- Follow the existing in-repo precedent at `test/gh342-sentinel-debug-log-python.sh:249` — a named
    42	  SKIP that states why, rather than a silent pass.
    43	- Keep the job advisory: `test/ci-workflow.sh:242` asserts the ubuntu job declares
    44	  `continue-on-error: true`; promoting it to a gate would break that meta-test and contradict GH-509.
    45	
    46	## Non-goals
    47	
    48	- Changing `utils/git-sandbox-guard.sh` or `relay-automation/hooks/security-scan.sh`.
    49	- Promoting the canary to a required gate.
    50	
    51	## Related
    52	
    53	- `test/gh50-sandboxed-git-guard.sh` · `test/security-scan.sh` · `test/gh342-sentinel-debug-log-python.sh:249`
    54	- `.github/workflows/ci.yml:210-236` · `test/ci-workflow.sh:242` · GH-509 · #249
    55	
    56	## Phase 0 checklist
    57	
    58	- [ ] `EUID=0` skips on the chmod-dependent assertions in both suites (writable-control cases stay live)
    59	- [ ] Also resolve the three unrelated FAILs in the same job, or the canary stays red:
    60	      `agy` not on PATH (marathon-drive), worktree-isolation case 2, concurrent-lock race
    61	- [ ] Witness a green hosted canary run before claiming the signal is restored
    19	  - GH-216 (same reconciler chain, open ledger-format question, kept separate — needs a design call, not a mechanical fix)
    20	goal: >
    21	  wave_reconcile.py's subprocess step and roadmap-dashboard.sh's own root-resolution math both
    22	  work correctly out of the box when the harness is vendored under .xyz/, with no hand-patching
    23	  required by the consuming repo.
    24	---
    25	
    26	# GH-215 — wave_reconcile.py and roadmap-dashboard.sh hardcode pre-vendoring path depth
    27	
    28	> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
    29	> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
    30	> (`PROJECT/PDDA.md` → GitHub issue intake).
    31	
    32	## Symptom
    33	Running `.xyz/utils/py/wave_reconcile.py` (the post-PR-merge reconciler) in a repo that vendors
    34	the harness under `.xyz/` (not a bare `utils/` at repo root) dies immediately at the
    35	subprocess-orchestration step, then again one step later after a partial fix — both are simple
    36	path-resolution mistakes that assume a non-vendored `utils/` layout at repo root.
    37	
    38	## Environment
    39	- **Observed from:** `LTVera-Pandas` (vendored `.xyz/`)
    40	- **Harness commit:** 46075c9 (per `.xyz/VERSION`, vendored 2026-08-24T02:04:13Z)
    41	- **Worker/CLI:** n/a — invoked directly via `python3 .xyz/utils/py/wave_reconcile.py`
    42	- **Sandbox:** off (gh + subprocess calls run un-sandboxed)
    43	
    44	## Reproduction
    45	1. In a repo with `.xyz/` vendored, run `python3 .xyz/utils/py/wave_reconcile.py --pr <N> --dry-run`.
    46	2. `run_subprocesses()` builds commands as `python3 utils/py/releases_app.py ...`, `python3 utils/timeline/export_timeline.py --preview`, `bash utils/roadmap-dashboard.sh`, `bash utils/marathon-plan.sh` (with `cwd=repo_root`); `run_validation_gate()` builds `bash utils/pdda-local-checks.sh` / `bash utils/pdda/pdda.sh`. None of these paths exist at `repo_root/utils/...` — only at `repo_root/.xyz/utils/...`. Dies at the first subprocess call.
    47	3. After locally prefixing all six occurrences with `.xyz/`: reaches `bash .xyz/utils/roadmap-dashboard.sh`, which itself derives its root via `HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` then `ROOT="$(cd "$HERE/.." && pwd)"` — correct only if the script lives at `repo_root/utils/roadmap-dashboard.sh`. Vendored one level deeper, `ROOT` resolves to `repo_root/.xyz` instead of `repo_root`, so it crashes with `ENOENT: .../.xyz/ROADMAP.md`.
    48	
    49	**Expected:** both resolve correctly against the true repo root in a vendored install.
    50	**Observed:** two sequential dies (missing-file error, then ENOENT), full rollback each time (rollback is `wave_reconcile.py`'s own journal, working as intended — not part of this bug).
    51	**Frequency:** every time, both `--dry-run` and live.
    52	
    53	```text
    54	wave-reconcile:   -> roadmap-dashboard.sh
    55	node:fs:440
    56	Error: ENOENT: no such file or directory, open '<repo_root>/.xyz/ROADMAP.md'
    57	```
    58	
    59	## Impact
    60	Blocks any vendored `.xyz/` install's post-merge reconciler from completing out of the box in any
    61	consuming repo. Workaround: both hand-patched in the local vendored copy for the reporting session
    62	only — not upstream, will regress on the next `.xyz/` vendor refresh.
    63	
    64	**Local patch applied (for reference, not yet upstream):**
    65	- `wave_reconcile.py`: prefixed the six `utils/...` command-path strings with `.xyz/`.
    66	- `roadmap-dashboard.sh`: changed `ROOT="$(cd "$HERE/.." && pwd)"` to `ROOT="$(cd "$HERE/../.." && pwd)"`.
    67	
    68	## Phase 0 — Diagnose & scope
    69	> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
    70	> (`PROJECT/PDDA.md` → Discovery & spike phases).
    71	
    72	### Checklist
    73	- [ ] Reproduce both bugs in the intake repo against a vendored-layout fixture; confirm the two patches above are the right upstream fix (vs. e.g. resolving root via `git rev-parse --show-toplevel` instead of `dirname`-relative math, which would be robust to future vendoring-depth changes)
    74	- [ ] Audit other vendored scripts under `.xyz/utils/` for the same one-level-too-shallow `dirname`-based root-resolution pattern (not done here — scope was these two)
    75	- [ ] Set/correct triage ratings; clear `ratings_provisional` once real
    76	
    77	### QA checklist — Phase 0
    78	- [ ] The repro is confirmed from the report, not assumed
    79	- [ ] A regression fixture (vendored-layout repo) covers the failure path before the fix lands
    80	- [ ] The fix composes with the existing harness rather than adding a parallel path
    14	# GH-243 · Repoint agent docs + dashboard-staleness push guard
    15	
    16	## Why
    17	
    18	The repo flipped to `ROADMAP_SOURCE=releases` (c97f6176), but ROUTER.md/AGENTS.md still direct
    19	agents to read and park in `ROADMAP.md` text — instructions that now describe a frozen legacy
    20	file. And nothing yet enforces that a ledger write regenerates `ROADMAP-DASHBOARD.md`, so the
    21	human-readable view can silently go stale — the exact drift #169's item 3 predicted.
    22	
    23	## Key Concepts
    24	
    25	- Read surface: `ROADMAP-DASHBOARD.md` / `releases roadmap list`; write surface: `releases roadmap add` (hq park routes there automatically).
    26	- `roadmap sync` is legacy-mode-only (GH-238 no-op here).
    27	- Guard lives at the push gate (GH-549 single wired stub), as a standalone, hermetically testable script.
    28	
    29	## Non-goals
    30	
    31	- The other ~26 ROADMAP.md readers named in #169's blast-radius list.
    32	- RELEASES-DB-FAQS.md rewrite.
    33	
    34	## Related
    35	
    36	- #169 (plan) · #238/#239/PR #240 (machinery) · c97f6176 (the flip)
    20	  - GH-215 (same reconciler chain, two mechanical path-resolution bugs, kept separate — already fixed locally)
    21	goal: >
    22	  marathon-plan.sh's ledger parser either accepts link-style ROADMAP.md bullets (this repo's actual
    23	  format) or the required bold-bullet / "Deferred · vision" format is documented as a hard
    24	  constraint on consuming repos before they rely on the reconciler.
    25	---
    26	
    27	# GH-216 — marathon-plan.sh ledger parser rejects link-style ROADMAP.md bullets
    28	
    29	> **1-INBOX capture**, not the active-work doc — no `## Status` table yet.
    30	
    31	## Symptom
    32	`.xyz/utils/py/wave_reconcile.py` (the post-PR-merge reconciler) never completes successfully in
    33	LTVera-Pandas: it always dies at the `marathon-plan.sh` step, rolling back the entire
    34	reconciliation run (docs, ROADMAP, releases.db, dashboards), because that script's ledger parser
    35	doesn't recognize this repo's actual `ROADMAP.md` bullet/heading style.
    36	
    37	## Environment
    38	- **Observed from:** `LTVera-Pandas`
    39	- **Harness commit:** 46075c9 (per `.xyz/VERSION`, vendored 2026-08-24T02:04:13Z)
    40	- **Worker/CLI:** n/a — invoked via `wave_reconcile.py` → `bash .xyz/utils/marathon-plan.sh`
    41	- **Sandbox:** off
    42	
    43	## Reproduction
    44	1. In LTVera-Pandas, run `python3 .xyz/utils/py/wave_reconcile.py --pr <N ...> --dry-run` (with GH-215's path fixes already applied locally).
    45	2. It reaches `bash .xyz/utils/marathon-plan.sh --dry-run`, which exits 3: `marathon-plan: no ledger items parsed (is '## Ledger' present?)`.
    46	3. Root cause, traced to `.xyz/utils/py/_marathon_plan.py`'s `_parse_ledger()` (~line 500-533): it only matches bullets styled `^- \*\*` (bold-title) and only recognizes `### <heading>` blocks whose text is in `SECTIONS = ["Queue / parked intake", "In progress", "Completed", "Deferred · vision"]`. LTVera-Pandas's `ROADMAP.md` uses `- [Title](path) — ...` markdown-link bullets, and its fourth section heading is a bare `### Deferred` (no "· vision"). Result: zero bullets match across every section, so the item count is 0 and the script exits 3 — even though the `## Ledger` heading itself is present, making the exit message ("is '## Ledger' present?") misleading about the actual cause.
    47	
    48	**Expected:** either the parser accepts this bullet/heading style, or the required format is documented so repos know to conform before depending on the reconciler.
    49	**Observed:** exit 3, full rollback, every time.
    50	**Frequency:** every time, both `--dry-run` and live, across 8 different merged PRs tested in one session.
    51	
    52	```text
    53	wave-reconcile:   -> marathon-plan.sh --dry-run
    54	wave-reconcile: ERROR — Subprocess 'marathon-plan.sh --dry-run' failed with exit 3:
    55	marathon-plan: no ledger items parsed (is '## Ledger' present?)
    56	wave-reconcile: Rolling back all uncommitted mutations...
    57	```
    58	
    59	## Impact
    60	Blocks the reconciler from ever completing successfully in LTVera-Pandas (and presumably any other
    61	consuming repo using link-style ledger bullets) until resolved. Not patched locally — this is a
    62	format/design call (widen the parser vs. mandate the bold-bullet format), not a safe mechanical fix
    63	like GH-215's two bugs.
    64	
    65	## Phase 0 — Diagnose & scope
    66	> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
    67	> (`PROJECT/PDDA.md` → Discovery & spike phases).
    68	
    69	### Checklist
    70	- [ ] Decide: widen `_parse_ledger()`'s bullet regex (accept `^- \[.+\]\(.+\)` in addition to `^- \*\*`) and `SECTIONS` list (accept bare `Deferred` in addition to `Deferred · vision`), OR document the bold-bullet/`Deferred · vision` format as a hard requirement for `ROADMAP.md` in consuming repos
    71	- [ ] If widening the parser: also fix the exit-3 message, which currently blames a missing `## Ledger` heading when the real cause can be bullet/heading-name mismatch under a heading that IS present
    72	- [ ] Set/correct triage ratings; clear `ratings_provisional` once real
    73	
    74	### QA checklist — Phase 0
    75	- [ ] The repro is confirmed from the report, not assumed
    76	- [ ] A regression fixture (link-style `ROADMAP.md`) covers the failure path before the fix lands
    77	- [ ] The fix composes with the existing harness rather than adding a parallel path

codex
A material contradiction surfaced: the DB’s Cargo manifest has seven items, including ATE/self-healer/AgentChorus work, while the human release block still describes a two-item vendored-ledger arc. I’ll treat the DB as authoritative, which means Cargo must be re-scoped before it is honestly called a themed next release.
exec
/bin/zsh -lc "nl -ba ROADMAP.md | sed -n '1,55p'
nl -ba LEADERBOARD.md | sed -n '1,90p'
nl -ba PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md | sed -n '76,100p'
nl -ba RELEASES.md | sed -n '206,234p'
nl -ba ROUTER.md | sed -n '1,55p'
nl -ba ROUTER.md | sed -n '240,290p'" in /private/var/folders/dh/ypr5rkgn3b9fzlzlmj69yd_r0000gn/T/consult-wt-30948-51ksahqx
 succeeded in 0ms:
     1	---
     2	title: Combined Roadmap — Cost-Observed Marathon Loops + Adversarial Hardening
     3	status: Active
     4	created: 2026-06-16
     5	updated: 2026-08-21
     6	branch: main
     7	supersedes: PROJECT/2-WORKING/ROADMAP-COMBINED.md (promoted to canonical 2026-06-17); folds in the former standalone ROADMAP.md (adversarial-hardening track, now Part B)
     8	synthesizes:
     9	  - PROJECT/1-INBOX/LOOPS.md
    10	  - PROJECT/4-MISC/COST-OBSERVABILITY-PLAN.md
    11	  - PROJECT/1-INBOX/MARATHON.md
    12	goal: >
    13	  Keep one long-horizon marathon under load at all times — work long, parallel, and failure-prone
    14	  enough to tax the whole XYZ system (worktree isolation, path claims, the driver lock, multi-round
    15	  handoff, escalation, resume). That purpose is a work-selection filter: prefer the marathon-shaped
    16	  candidate, run only real work (an idle gap is honest; a manufactured marathon is not), and treat
    17	  the failures a run surfaces as the deliverable. See AGENTS.md -> Repo-specific rails for the four
    18	  rules. Mechanically, this file is the canonical pointer/ledger index for that work — queued
    19	  intake, in progress, completed, and deferred — linking to the PROJECT/** docs that own the
    20	  execution detail. It is an index, not a plan body.
    21	---
    22	
    23	<!-- PDDA ROADMAP CONTRACT — this file is a POINTER/LEDGER, not a plan body.
    24	     Allowed: queued intake / projects in progress / completed / attempted / deferred + links to PROJECT/** docs.
    25	     NOT allowed: phase checklists, build steps, deep execution notes — put those in the project doc.
    26	     Carve-out: a SHORT exception note is OK only when omitting it would hide an operationally critical fact.
    27	     Coverage rule: every PROJECT/2-WORKING doc must be reflected here by a pointer (or opt out with roadmap_exempt: true).
    28	     Enforced by `utils/pdda/pdda.sh roadmap` + `utils/pdda/pdda.sh roadmap-coverage` (deterministic) + `utils/pdda/pdda.sh doc-ready` ROADMAP rubric (LLM).      SHADOW (GH-69): this ledger is mirrored into releases.db's roadmap_items table. After editing
    29	     the ledger, run `python3 utils/py/releases_app.py roadmap sync` (a no-change sync is a free
    30	     no-op). This file remains the ONLY source of truth; the sync is one-way and never writes here.
    31	-->
    32	
    33	# Combined Roadmap: Cost-Observed Marathon Loops + Adversarial Hardening
    34	
    35	> **Pointer/ledger only — not a plan body.** Execution detail (phase checklists, build steps, QA
    36	> gates, deep notes) lives in the linked `PROJECT/**` docs; keep it there. See the contract banner above.
    37	
    38	Three tracks, sequenced independently:
    39	
    40	- **Part A — Marathon:** cost observability (done) → headless multi-phase chaining (done) → real-monolith dogfood (active)
    41	- **Part B — Adversarial Hardening:** epoch fencing (done) → chaos suite → cross-repo E2E → reference deploy
    42	- **Part C — Autonomous Self-Improvement:** the gated LOOPS.md endgame
    43	
    44	## Status
    45	
    46	| What was just completed | What's next |
    47	|---|---|
    48	| **2026-08-19:** release **0.7.1 “Bulwark”** cut end-to-end through the RELEASES CLI, merged (PR #66), and **SHIPPED** the same day — the first release never hand-edited, and the first shipped through `releases ship` with its exit-criterion evidence recorded in the receipt chain (`gh32-releases-artifacts` 10/0, `gh53-releases-merge-resolve` 15/0, `gh54-merged-dump-refusals` 19/0, `check` clean at generation 9). **PR #55** (GH-35 tiered test selection + CPU governance; GH-45 worktree-gate refusal) and **PR #60** (GH-57 SQLite ledger fuzzing, 42/0) merged. **PR #70** closed GH-57’s live-merge gap: `test/gh57-live-merge-resolve.sh` (30/0) drives a REAL `git merge` and found four resolver defects, all fixed (failed-resolve half-closed the merge; rewound generation header accepted; `releases.db.bak` committable; `--root ""` retargeting). This ledger was purged of 256 upstream-numbered entries the same day (see below) and reconciled against GitHub issue state. | **[#75](https://github.com/HiQS-Suite/XYZ-forge/issues/75)** — single-page HTML dashboard over both DB subsystems (**front of the line, operator call 2026-08-19**). **[#67](https://github.com/HiQS-Suite/XYZ-forge/issues/67) (P1)** — decide the Commandcode `--yolo` default landed silently by PR #60. **[#59](https://github.com/HiQS-Suite/XYZ-forge/issues/59)** — re-arm hosted CI: the repo is public and Actions is enabled, yet pushes produce no runs. **[#58](https://github.com/HiQS-Suite/XYZ-forge/issues/58)** — GH-35 Phase 3 follow-ups (tier-2 hygiene gap P2 + two P3s), recommended to ride with Phase 3. **[#61](https://github.com/HiQS-Suite/XYZ-forge/issues/61)** — RELEASES ledger durability hardening (#62–#65). Next release on the shelf: **0.6.0 “Meter”**, target 2026-09-26. External contributions resolved 2026-08-21: PR #51, #99 and #119 merged; **PR #29 closed** — its tooling half landed as #51, but its Windows/MSYS2 *evidence* half never landed anywhere and was requested as a follow-up, so that platform still has no coverage. |
    49	
    50	### Immediate next-up (ordered)
    51	
    52	> **THE MARATHON — [#179](https://github.com/HiQS-Suite/XYZ-forge/issues/179) (release 0.7.3 "Bulkhead": harness reliability hardening).**
    53	> **Handed over from [#77](https://github.com/HiQS-Suite/XYZ-forge/issues/77) on 2026-08-22 — Daybreak SHIPPED** (0.7.2, all
    54	> four waves merged, gh77 suite green, #77/#82-#87 closed with evidence). Bulkhead is the next arc,
    55	> built from the 2026-08-22 radar targets: the suite-containment class (both polarities), headless-turn
     1	<!-- GENERATED by utils/leaderboard.sh from releases.db — do not hand-edit. -->
     2	
     3	# Leaderboard
     4	
     5	Every rated task in the ledger, highest first. **Higher is better on every axis**, effort
     6	included — it scores cheapness, not cost, so a 90/90/90/90 item reads as what it is: a
     7	screaming quick win. `calc` is the equal-weighted sum of the four axes (4–400) and is derived,
     8	never stored. `ovr` is the operator override; where it exists it replaces `calc` for ranking,
     9	while the four axes keep their honest values underneath.
    10	
    11	| # | score | task | release | lane | pri | sev | appeal | effort | calc | ovr |
    12	|--:|------:|------|---------|------|----:|----:|-------:|-------:|-----:|----:|
    13	| 1 | **340** | [GH-67](https://github.com/HiQS-Suite/XYZ-forge/issues/67) — Commandcode builder default widened to `--yolo` — closer evaluation → possible build | — | Queue / parked intake | 88 | 80 | 45 | 70 | 283 | 340 |
    14	| 2 | **325** | [GH-249](https://github.com/HiQS-Labs/XYZ-forge/issues/249) — ubuntu canary: EUID=0 defeats chmod-based assertions | — | Queue / parked intake | 90 | 85 | 80 | 70 | 325 | — |
    15	| 3 | **315** | [GH-181](https://github.com/HiQS-Labs/XYZ-forge/issues/181) — repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command, rc 127 vs expected 2) | Bulkhead | completed | 90 | 75 | 90 | 60 | 315 | — |
    16	| 4 | **308** | [GH-204](https://github.com/HiQS-Labs/XYZ-forge/issues/204) — BSD `sed -i ''` no-ops on Linux at production call sites | Linux-RC | in progress | 88 | 85 | 70 | 65 | 308 | — |
    17	| 5 | **305** | [GH-202](https://github.com/HiQS-Labs/XYZ-forge/issues/202) — wave_reconcile aborts on marathon-plan exit 5 (items held) and promotes capture docs for OPEN issues | Bulkhead | completed | 85 | 65 | 85 | 70 | 305 | — |
    18	| 6 | **305** | [GH-228](https://github.com/HiQS-Labs/XYZ-forge/issues/228) — Org rename HiQS-Suite → HiQS-Labs: a hardcoded regex silently drops issue URLs from the roadmap shadow | Linux-RC | completed | 80 | 60 | 75 | 90 | 305 | — |
    19	| 7 | **300** | [GH-174](https://github.com/HiQS-Suite/XYZ-forge/issues/174) — Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator | Bulkhead | completed | 85 | 75 | 95 | 45 | 300 | — |
    20	| 8 | **295** | [GH-14](https://github.com/HiQS-Suite/XYZ-forge/issues/14) — appendEvent writes non-atomically, so concurrent readers can observe torn event files | — | Completed | 85 | 85 | 70 | 55 | 295 | — |
    21	| 9 | **295** | [GH-155](https://github.com/HiQS-Suite/XYZ-forge/issues/155) — 3rd Gen ATE & Fuzzing | — | Completed | 85 | 70 | 90 | 50 | 295 | — |
    22	| 10 | **295** | [GH-165](https://github.com/HiQS-Suite/XYZ-forge/issues/165) — Post-Merge Wave & Marathon Lifecycle Reconciler (Docs, ROADMAP, DB, Views, and Planning) | — | Completed | 90 | 80 | 90 | 35 | 295 | — |
    23	| 11 | **292** | [GH-23](https://github.com/HiQS-Suite/XYZ-forge/issues/23) — Kernel invariant: enforce path-overlap rejection on direct tick claim and tick scope | — | Completed | 82 | 78 | 72 | 60 | 292 | — |
    24	| 12 | **290** | [GH-113](https://github.com/HiQS-Suite/XYZ-forge/issues/113) — headless agy builder writes root scratch files, tripping containment (exit 6) | Bulkhead | completed | 85 | 60 | 85 | 60 | 290 | — |
    25	| 13 | **290** | [GH-123](https://github.com/HiQS-Labs/XYZ-forge/issues/123) — Linux portability canary — remainder: gh358 lock contention on shared runners | Linux-RC | in progress | 90 | 80 | 75 | 45 | 290 | — |
    26	| 14 | **290** | [GH-148](https://github.com/HiQS-Suite/XYZ-forge/issues/148) — DeepSeek Harness (dsh) integration & deepseek-turn shim for OpenRouter DeepSeek V4 Pro | — | Completed | 85 | 75 | 90 | 40 | 290 | — |
    27	| 15 | **290** | [GH-168](https://github.com/HiQS-Suite/XYZ-forge/issues/168) — wave_reconcile.py hard-fails and rolls back on pre-existing drift unrelated to the reconciled PR | Bulkhead | completed | 80 | 55 | 85 | 70 | 290 | — |
    28	| 16 | **290** | [GH-226](https://github.com/HiQS-Labs/XYZ-forge/issues/226) — xyz-vendor.sh transcript gate refuses repos that gitignore transcripts | Linux-RC | completed | 75 | 50 | 80 | 85 | 290 | — |
    29	| 17 | **285** | [GH-141](https://github.com/HiQS-Suite/XYZ-forge/issues/141) — make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison | Linux-RC | ad-hoc detour | 80 | 65 | 85 | 55 | 285 | — |
    30	| 18 | **285** | [GH-221](https://github.com/HiQS-Labs/XYZ-forge/issues/221) — GH-221 — agy-turn.sh auth pre-flight breaks on agy CLI >=1.1.19 — whoami subcommand removed | — | Queue / parked intake | 70 | 65 | 70 | 80 | 285 | — |
    31	| 19 | **280** | [GH-114](https://github.com/HiQS-Suite/XYZ-forge/issues/114) — headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7) | Bulkhead | completed | 80 | 60 | 80 | 60 | 280 | — |
    32	| 20 | **280** | [GH-115](https://github.com/HiQS-Suite/XYZ-forge/issues/115) — marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4) | Bulkhead | completed | 75 | 50 | 85 | 70 | 280 | — |
    33	| 21 | **280** | [GH-180](https://github.com/HiQS-Labs/XYZ-forge/issues/180) — repro_builder crashes on timeout telemetry records (exit_code: null → TypeError) | Bulkhead | completed | 70 | 45 | 85 | 80 | 280 | — |
    34	| 22 | **280** | [GH-193](https://github.com/HiQS-Labs/XYZ-forge/issues/193) — AgentChorus Gen 2 | Cargo | queue | 75 | 70 | 85 | 50 | 280 | — |
    35	| 23 | **280** | [GH-216](https://github.com/HiQS-Labs/XYZ-forge/issues/216) — GH-216 — marathon-plan.sh ledger parser rejects link-style ROADMAP.md bullets | — | Queue / parked intake | 75 | 65 | 70 | 70 | 280 | — |
    36	| 24 | **280** | [GH-223](https://github.com/HiQS-Labs/XYZ-forge/issues/223) — GH-223 — pre-push gate push double-applies through ref lock | Cargo | queue | 80 | 75 | 65 | 60 | 280 | — |
    37	| 25 | **280** | [GH-4](https://github.com/HiQS-Suite/XYZ-forge/issues/4) — the pre-push gate does not travel with clones: fresh clones push unverified | — | Completed | 78 | 72 | 70 | 60 | 280 | — |
    38	| 26 | **280** | [GH-77](https://github.com/HiQS-Suite/XYZ-forge/issues/77) — `/standup` — session-scoped triage: what did I leave open, what is rotting, is the plan still right? | — | Completed | 95 | 70 | 85 | 30 | 280 | — |
    39	| 27 | **275** | [GH-1](https://github.com/HiQS-Suite/XYZ-forge/issues/1) — suite-wide fixture containment + clone-identity invariant gate | — | Completed | 80 | 75 | 70 | 50 | 275 | — |
    40	| 28 | **275** | [GH-124](https://github.com/HiQS-Suite/XYZ-forge/issues/124) — eliminate end-of-day closeout friction — automated phase QA receipts, auto-PR creation, and clone lifecycle hygiene | — | Completed | 85 | 60 | 90 | 40 | 275 | — |
    41	| 29 | **275** | [GH-132](https://github.com/HiQS-Suite/XYZ-forge/issues/132) — feat(skills): formal /review-xyz code review skill & multi-model harness | — | Completed | 80 | 70 | 85 | 40 | 275 | — |
    42	| 30 | **275** | [GH-15](https://github.com/HiQS-Suite/XYZ-forge/issues/15) — parallel runs are unreliable in a fresh clone; the GH-528 contention retry is not honoring its contract | — | Completed | 80 | 75 | 70 | 50 | 275 | — |
    43	| 31 | **275** | [GH-170](https://github.com/HiQS-Suite/XYZ-forge/issues/170) — Agent2Agent: close transcript glitches and harden publishing | — | Completed | 75 | 60 | 85 | 55 | 275 | — |
    44	| 32 | **275** | [GH-2](https://github.com/HiQS-Suite/XYZ-forge/issues/2) — test-suite run relocated an untracked file into .tick/orphan-backups/ | Bulkhead | completed | 80 | 55 | 85 | 55 | 275 | — |
    45	| 33 | **275** | [GH-201](https://github.com/HiQS-Labs/XYZ-forge/issues/201) — Gen 3.5 follow-ups — remaining ATE hardening arc (tasks 3–8b of #174) | Cargo | in progress | 80 | 70 | 80 | 45 | 275 | — |
    46	| 34 | **275** | [GH-8](https://github.com/HiQS-Suite/XYZ-forge/issues/8) — kernel boundary hardening — CLI numeric validation, task/agent format contract | Bulkhead | completed | 75 | 55 | 80 | 65 | 275 | — |
    47	| 35 | **270** | [GH-184](https://github.com/HiQS-Labs/XYZ-forge/issues/184) — committed scratch artifact `.relay-scratch/probe_telemetry.json` makes every real turn a tracked-file mutation | Bulkhead | completed | 60 | 40 | 80 | 90 | 270 | — |
    48	| 36 | **270** | [GH-205](https://github.com/HiQS-Labs/XYZ-forge/issues/205) — validate.sh mutates four tracked files per run — gate not idempotent | Linux-RC | in progress | 75 | 70 | 70 | 55 | 270 | — |
    49	| 37 | **270** | [GH-75](https://github.com/HiQS-Suite/XYZ-forge/issues/75) — single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view | — | Queue / parked intake | 90 | 40 | 85 | 55 | 270 | — |
    50	| 38 | **265** | [GH-111](https://github.com/HiQS-Suite/XYZ-forge/issues/111) — retire manifest FREEZE; tasks and marathons are DIALED IN to exactly one release, as a database state | — | Completed | 85 | 75 | 70 | 35 | 265 | — |
    51	| 39 | **265** | [GH-182](https://github.com/HiQS-Labs/XYZ-forge/issues/182) — self_healer --mode heal is a facade (containment refuses any real target) plus unsafe gate design | Cargo | in progress | 75 | 55 | 80 | 55 | 265 | — |
    52	| 40 | **265** | [GH-50](https://github.com/HiQS-Suite/XYZ-forge/issues/50) — sandboxed git --track / branch -D half-applies and loses uncommitted work | Bulkhead | completed | 65 | 35 | 85 | 80 | 265 | — |
    53	| 41 | **260** | [GH-183](https://github.com/HiQS-Labs/XYZ-forge/issues/183) — active_explorer env-family fuzzing unsound (base_env={} hardcoded, one always-deferring vector, ambient-env leakage) | Bulkhead | completed | 65 | 50 | 75 | 70 | 260 | — |
    54	| 42 | **257** | [GH-215](https://github.com/HiQS-Labs/XYZ-forge/issues/215) — GH-215 — wave_reconcile.py and roadmap-dashboard.sh hardcode pre-vendoring path depth | — | Queue / parked intake | 72 | 60 | 65 | 60 | 257 | — |
    55	| 43 | **255** | [GH-10](https://github.com/HiQS-Suite/XYZ-forge/issues/10) — prevent-half of containment: require_fixture adoption across the fixture-creating suites + adoption guard + ci-local identity bracket | — | Completed | 55 | 70 | 50 | 80 | 255 | — |
    56	| 44 | **255** | [GH-144](https://github.com/HiQS-Suite/XYZ-forge/issues/144) — Agent2Agent 3+ participant onboarding + read-only status quick wins | — | Completed | 55 | 30 | 80 | 90 | 255 | — |
    57	| 45 | **255** | [GH-45](https://github.com/HiQS-Suite/XYZ-forge/issues/45) — validate.sh must refuse to run from a linked worktree — an observed run corrupted the parent clone | — | Completed | 65 | 60 | 60 | 70 | 255 | — |
    58	| 46 | **255** | [GH-91](https://github.com/HiQS-Suite/XYZ-forge/issues/91) — a build turn has nowhere to write verification output | — | Completed | 60 | 65 | 55 | 75 | 255 | — |
    59	| 47 | **250** | [GH-153](https://github.com/HiQS-Suite/XYZ-forge/issues/153) — RELEASES dashboard sidebar + full-cycle rollup (technical spike) | — | Completed | 70 | 55 | 80 | 45 | 250 | — |
    60	| 48 | **250** | [GH-197](https://github.com/HiQS-Suite/XYZ-forge/issues/197) — two-tier xyz-vendor.sh: Tier 1 core-harness default, Tier 2 opt-in RELEASES overlay + onboarding SOP (GH-105 follow-up) | — | Completed | 80 | 55 | 65 | 50 | 250 | — |
    61	| 49 | **250** | [GH-232](https://github.com/HiQS-Labs/XYZ-forge/issues/232) — wave_reconcile should honor linked issue open/closed state before promoting multi-phase docs | Linux-RC | in progress | 70 | 55 | 65 | 60 | 250 | — |
    62	| 50 | **250** | [GH-243](https://github.com/HiQS-Labs/XYZ-forge/issues/243) — GH-169 items 3-4: repoint agent docs + dashboard-staleness push guard | — | Queue | 70 | 55 | 65 | 60 | 250 | — |
    63	| 51 | **250** | [GH-246](https://github.com/HiQS-Labs/XYZ-forge/issues/246) — relay-xyz SKILL.md: explicit QA/Consult prompt template for headless agents (hotfix) | — | Queue / parked intake | 60 | 35 | 70 | 85 | 250 | — |
    64	| 52 | **245** | [GH-108](https://github.com/HiQS-Suite/XYZ-forge/issues/108) — pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override) | Daybreak | cut | 80 | 50 | 75 | 40 | 245 | — |
    65	| 53 | **235** | [GH-222](https://github.com/HiQS-Labs/XYZ-forge/issues/222) — GH-222 — releases update cannot re-point a release's tracking issue | Cargo | queue | 60 | 40 | 60 | 75 | 235 | — |
    66	| 54 | **230** | [GH-105](https://github.com/HiQS-Suite/XYZ-forge/issues/105) — vendor the RELEASES DB system + HTML timeline generator into the `.xyz` payload (optional add-on) | Cargo | queue | 75 | 50 | 60 | 45 | 230 | — |
    67	| 55 | **228** | [GH-102](https://github.com/HiQS-Suite/XYZ-forge/issues/102) — Unify Telemetry Schema & Inspection Tooling Across Fuzzing and ATE | — | Completed | 68 | 45 | 70 | 45 | 228 | — |
    68	| 56 | **222** | [GH-103](https://github.com/HiQS-Suite/XYZ-forge/issues/103) — technical spike: RELEASES SQLite → timeline-ui ledger viewer (RELEASES dashboard view) | — | Completed | 62 | 35 | 75 | 50 | 222 | — |
    69	| 57 | **220** | [GH-3](https://github.com/HiQS-Suite/XYZ-forge/issues/3) — improve-loop.sh --state-dir durability — provenance evidence must not evaporate | — | Completed | 55 | 45 | 55 | 65 | 220 | — |
    70	| 58 | **220** | [GH-32](https://github.com/HiQS-Suite/XYZ-forge/issues/32) — RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI | — | Queue / parked intake | 70 | 50 | 65 | 35 | 220 | — |
    71	| 59 | **220** | [GH-57](https://github.com/HiQS-Suite/XYZ-forge/issues/57) — test(releases): SQLite ledger fuzzing recipes & multi-scenario resilience suite | — | Completed | 60 | 45 | 65 | 50 | 220 | — |
    72	| 60 | **218** | GH-135 — GH-135..140 · Wave-1 follow-ups: consult preflight verdict, attempts-gate root, suite registration, twin-divergence record, SIGPIPE sweep+guard, utcnow swap | — | Completed | 58 | 45 | 60 | 55 | 218 | — |
    73	| 61 | **215** | [GH-233](https://github.com/HiQS-Labs/XYZ-forge/issues/233) — AgentChorus Gen 2 Phase 2 — Lifecycle Verbs, Watch Invalidation, Concurrency Suite & Citation Linter | Linux-RC | in progress | 65 | 45 | 75 | 30 | 215 | — |
    74	| 62 | **210** | [GH-5](https://github.com/HiQS-Suite/XYZ-forge/issues/5) — kernel robustness: node:test unit runner | Linux-RC | ad-hoc detour | 45 | 40 | 45 | 80 | 210 | — |
    75	| 63 | **195** | [GH-35](https://github.com/HiQS-Suite/XYZ-forge/issues/35) — 3-tier test suite selection (docs / utility subsystems / core) + CPU governance | — | Completed | 55 | 45 | 50 | 45 | 195 | — |
    76	| 64 | **190** | [GH-39](https://github.com/HiQS-Suite/XYZ-forge/issues/39) — RELEASES app: one-way GitHub Project release-card projection | — | Completed | 50 | 30 | 65 | 45 | 190 | — |
    77	| 65 | **190** | [GH-61](https://github.com/HiQS-Suite/XYZ-forge/issues/62) — RELEASES ledger durability hardening (GH-57 follow-up) | — | Queue / parked intake | 45 | 55 | 40 | 50 | 190 | — |
    78	| 66 | **185** | [GH-17](https://github.com/HiQS-Suite/XYZ-forge/issues/17) — SOP for evaluating new agent harnesses and frontier models | — | Queue / parked intake | 45 | 30 | 50 | 60 | 185 | — |
    79	| 67 | **185** | [GH-42](https://github.com/HiQS-Suite/XYZ-forge/issues/42) — relay automation: supported Commandcode turn-taker | — | Completed | 50 | 35 | 55 | 45 | 185 | — |
    80	| 68 | **175** | [GH-101](https://github.com/HiQS-Suite/XYZ-forge/issues/101) — Feasibility Study: Promoting Programmatic Script Runner (`script_runner.py`) into Core Relay & Consult Runtimes | — | Completed | 45 | 20 | 70 | 40 | 175 | — |
    81	| 69 | **175** | [GH-94](https://github.com/HiQS-Suite/XYZ-forge/issues/94) — research: programmatic tool calling & code-mode execution for harnesses, telemetry, and containment | — | Completed | 45 | 20 | 70 | 40 | 175 | — |
    82	| 70 | **170** | [GH-195](https://github.com/HiQS-Labs/XYZ-forge/issues/195) — marathon-root-audit's blind spot: a direct `python3 marathon_drive.py` call | — | Completed | 60 | 40 | 50 | 20 | 170 | — |
    83	| 71 | **170** | [GH-28](https://github.com/HiQS-Suite/XYZ-forge/issues/28) — RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue | — | Queue / parked intake | 40 | 35 | 40 | 55 | 170 | — |
    84	| 72 | **160** | [GH-18](https://github.com/HiQS-Suite/XYZ-forge/issues/18) — Harness evaluation: Command Code (cmd) and model matrix | — | Queue / parked intake | 35 | 25 | 45 | 55 | 160 | — |
    85	
    86	**Top of the line:** GH-67 — Commandcode builder default widened to `--yolo` — closer evaluation → possible build (score 340, operator override).
    87	
    88	Source: `releases.db` via `export_timeline.py --json`. Regenerate with `bash utils/leaderboard.sh`.
    76	
    77	## Held / flagged — excluded from active waves
    78	
    79	### ✅ Likely done — verify-and-close, not a build lane
    80	- #221 GH-221 — agy-turn.sh auth pre-flight breaks on agy CLI >=1.1.19 — whoami subcommand removed — `already-closed`
    81	
    82	### 🔧 Reconcile — undocumented partial completion
    83	- #14 GH-14 · appendEvent writes non-atomically, so concurrent readers can observe torn event files — `partial`
    84	
    85	### ⚠️ Not yet sequenceable — rate / add doc / add contract
    86	- #223 GH-223 — pre-push gate push double-applies through ref lock — `needs-contract`
    87	- #222 GH-222 — releases update cannot re-point a release's tracking issue — `needs-contract`
    88	- #215 GH-215 — wave_reconcile.py and roadmap-dashboard.sh hardcode pre-vendoring path depth — `needs-contract`
    89	- #216 GH-216 — marathon-plan.sh ledger parser rejects link-style ROADMAP.md bullets — `needs-contract`
    90	- #105 GH-105 · vendor the RELEASES DB system + HTML timeline generator into the .xyz payload (optional add-on) — `unrated`
    91	- #75 GH-75 · single-page HTML dashboard: releases (mid/long term) + roadmap (immediate) in one read-only view — `needs-doc`
    92	- #61 GH-61 · RELEASES ledger durability hardening (GH-57 follow-up) — `needs-doc`
    93	- #67 GH-67 · Commandcode builder default widened to --yolo — closer evaluation → possible build — `needs-doc`
    94	- #32 GH-32 · RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI — `needs-contract`
    95	- #28 GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue — `needs-contract`
    96	- #17 GH-17 · SOP for evaluating new agent harnesses and frontier models — `needs-contract`
    97	- #18 GH-18 · Harness evaluation: Command Code (cmd) and model matrix — `needs-contract`
    98	- #201 GH-201 · Gen 3.5 follow-ups — remaining ATE hardening arc (tasks 3–8b of #174) — `needs-contract`
    99	- #141 GH-141 · make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison — `needs-contract`
   100	- #5 GH-5 · kernel robustness: node:test unit runner — `needs-contract`
   206	Release: 0.8.0
   207	Iterations: 0.8.0-0.8.4
   208	Status: Draft
   209	Target Date: 2026-10-17
   210	Codename: Sundown
   211	Description: Retire the twelve frozen Bash twins. Three steps, in order: (1) sweep for real `XYZ_PYTHON=0` usage — if nothing sets it, the fallback is already dead in practice; (2) re-vendor every fleet `.xyz/` copy onto the Python lane (`xyz-sync.sh list` is the worklist); (3) delete the twins and retire the GH-308 edit-guard, keeping only its no-new-Bash half (GH-551). Not before steps 1-2: the vendored fleet still runs the Bash path, and `XYZ_PYTHON=0` is the documented rollback. Depends on nothing in Meter.
   212	**WIDENED 2026-08-15 by explicit operator decision — Sundown receives Meter's five engineering entries.** The release's sentence becomes: **the harness accounts for what it spends, checks what it requires before spending it, and stops carrying the retired Bash lane.** Said plainly rather than argued into one theme: the twin retirement and the metering work are two subjects sharing one release, and they are here together because Meter was re-pointed at publication on 2026-08-15 and these five needed a home that was not a parking space. They arrive intact — same capture docs under `PROJECT/2-WORKING/`, same verbatim acceptance criteria, same evidence — and the honest reading of the widening is that Sundown's date is now less trustworthy than it was, because it absorbed five entries without absorbing any schedule.
   213	**RENUMBERED 0.7.0 → 0.8.0 on 2026-08-16 by explicit operator decision, to open 0.7.0 for Ballast.** Nothing about this release changed except its version: same codename, same target date, same manifest, same milestone. The band moves with it (`0.7.0-0.7.4` → `0.8.0-0.8.4`) because a release's iteration band is part of its identity here, not a separate fact. Recorded as a dated line rather than shown as a block that was always 0.8.0, on the same principle the manifest re-scopes above follow: a version that changes without a trace is indistinguishable from one that was misread. The `(0.7.0)` parentheticals in Meter's re-scope paragraphs were swept to `(0.8.0)` in the same edit — they identify *which release received the transfer*, so leaving them stale would have pointed a reader at a version that no longer exists. `CHANGELOG.md`'s existing entry is **not** swept: it is the append-only record of what was decided on 2026-08-15, when Sundown was 0.7.0, and the renumber is recorded there as its own dated entry instead.
   214	Manifest: **#378, #379, #382, #491, #551, #28**, received from Meter 2026-08-15, plus the twin-retirement work described above, which remains unnumbered until its issues are filed. **#28** is the RELEASES.md ledger-discipline fix (parser continuation-folding + advisory bloat checks; see its capture doc for detail), added 2026-08-18 as a post-Ballast follow-up. **#546 is milestone backlog, not a manifest entry** — it followed the metering subject here and does not gate this release, under the standing rule that discovery is not admission. **Not yet frozen.** Freezing requires the twin-retirement issues to exist so the manifest is a fixed denominator rather than a list plus a promise; until then this line is a receipt for the transfer, not a contract. #380 did not move: it is CLOSED and shipped under Meter's original scope, and stays milestoned there.
   215	Exit criterion: **NOT WRITTEN.** Required before this release starts, per the ordering Litmus and Nightwatch both used and Meter is repeating — the gate is built first and arrives RED, because a release whose exit criterion is authored after its members cannot tell a finished entry from a claimed one.
   216	GH_URL: pending — api.github.com DNS outage 2026-08-14; file on recovery
   217	Milestone: Sundown
   218	Front-door reviewed: No
   219	Shakedown reviewed: No
   220	License file: Yes
   221	
   222	Release: 0.9.0
   223	Iterations: 0.9.0-0.9.4
   224	Status: Draft
   225	Target Date: 2026-09-19
   226	Codename: Cargo
   227	Description: The harness travels with its ledger. The RELEASES DB system (releases_app.py CLI + merge resolver + FAQs) and the GH-103 HTML timeline generator (utils/timeline/) ship inside every vendored `.xyz/` payload as an optional, never-wired-by-default add-on — a "when you're ready" module a target repo enables by running `releases init` itself, matching this file's own OPTIONAL philosophy (GH-381). Sequenced before Meter (0.6.0, 2026-09-26) by explicit operator decision 2026-08-20; version 0.9.0 because every 0.1–0.8 band is reserved — target date, not version number, carries the ordering. Cut through the CLI and mirrored here by hand in the same commit (the GH-32 Phase-0 dual path; no automatic dual writer exists yet).
   228	Exit criterion: A repo vendored with `xyz-vendor.sh` can, with zero extra downloads, run `releases init`/`add` and `export_timeline.py --preview` from `.xyz/` against its own root, and `xyz-sync.sh update` preserves the target's ledger state (GH-312 preserve list). Nothing runs until the user invokes it. NOT BUILT — the gate is authored before any member is fixed, per the Litmus/Nightwatch ordering.
   229	Manifest: DIALED IN 2026-08-20 on creation — #105 (vendor the RELEASES DB + timeline generator into the .xyz payload). RE-SCOPED 2026-08-20 by explicit operator instruction: + #107 (connect /10days, /radar, and PARKED to the RELEASES DB — read-only consumption seams; no new writers). Two entries; no swap; target date held — #107 is additive tooling scoped as quick wins. The standing admission rule remains for anything further: a mid-release discovery joins only if it makes the exit command fail or falsifies a named invariant, has a reproducer demonstrating that, and the operator explicitly swaps out an existing entry or accepts a date slip. Discovery is not admission.
   230	GH_URL: https://github.com/HiQS-Suite/XYZ-forge/issues/105
   231	Milestone: Cargo
   232	Front-door reviewed: No
   233	Shakedown reviewed: No
   234	License file: Yes
     1	# ROUTER.md
     2	
     3	This file is the first entry point for an AI agent working in this repo: it tells you what to read, what to run, and which files are canonical.
     4	
     5	## Role split
     6	
     7	- `ROUTER.md` = startup order and canonical entry points
     8	- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof
     9	- `README.md` = human-facing repo/product overview
    10	- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh`)
    11	- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip (GH-169/GH-243) — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file
    12	- `CHANGELOG.md` = the end-of-iteration running log (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
    13	- `RELEASES.md` = forward-looking release-planning ledger (first-class PDDA artifact; governed by `PROJECT/PDDA.md`)
    14	- `HARNESS-MODELS-REGISTRY.md` = evaluated agent harnesses, supported model grades (A/B/C), and CLI flags
    15	- `PROJECT/**` docs = canonical execution detail for a specific effort
    16	- `PROJECT/PDDA.md` = document contract and automation rules (incl. the CHANGELOG contract)
    17	- `PROJECT/CONSTITUTION.md` = the policy of record: PDDA's lane and its non-negotiables (deterministic-before-LLM, verified-success-only, reversibility, local-first)
    18	- `PROJECT/DO-NOT-BUILD.md` = the anti-scope list — product directions PDDA must not become (companion to `CONSTITUTION.md`)
    19	
    20	## Startup sequence
    21	
    22	1. Read `ROUTER.md` to understand the repo's operating order and canonical files. -> expect one clear next file, not a repo-wide scavenger hunt.
    23	2. Read `AGENTS.md` before making recommendations or edits. -> expect explicit assumptions, a reversibility read on consequential changes, and verified claims only.
    24	3. Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.)
    25	4. Read the linked `PROJECT/**` document that owns the work you are touching. -> expect the near-top `## Status` table to tell you what was just completed and what is next.
    26	5. If the task touches project docs, read `PROJECT/PDDA.md` and follow the PDDA contract. -> expect `PROJECT/2-WORKING` docs to have frontmatter, the exact status table, and QA gates when phased.
    27	6. Before reporting success on code or runtime work, run `./validate.sh`. -> expect the suite to stay green; do not claim completion if it fails or was skipped.
    28	7. Before reporting success on doc-hygiene or roadmap work, run `utils/pdda/pdda.sh run` (or the relevant `utils/pdda/pdda.sh <check>` subcommand). -> expect deterministic findings first, then any LLM review.
    29	
    30	## Canonical rules
    31	
    32	- Do not put phase checklists, build steps, or deep execution notes in the roadmap ledger.
    33	- Every active doc in `PROJECT/2-WORKING/` must be reflected by a pointer row in the roadmap ledger (the RELEASES DB) that links it. A working doc that should not appear opts out with `roadmap_exempt: true` in its frontmatter. (`utils/pdda/pdda.sh roadmap-coverage` still checks the legacy `ROADMAP.md` text — repointing it to the DB is tracked in #169's blast-radius list.) Governance lives in `PROJECT/PDDA.md` → "ROADMAP.md contract".
    34	- Every captured GitHub issue doc in `PROJECT/1-INBOX/GH-*.md` must also be parked as a queue row immediately at intake — `python3 utils/py/releases_app.py roadmap add --issue-num N --issue-url U --title T --created YYYY-MM-DD --doc-path P` (or `hq park`, which routes there automatically in this repo) — then promoted or removed later. Governance lives in `PROJECT/PDDA.md` → "GitHub issue intake" + "ROADMAP.md contract".
    35	- Do not create a second competing plan when a canonical `PROJECT/**` doc already exists.
    36	- Issue-first: any change beyond a **2–3 line** fix opens a GitHub issue first, then a pointer doc **named after the issue** (`GH-<number>-VERY-SHORT-DESC.md`, e.g. `GH-1234-SHOWME-COMMAND.md`), and that capture is **parked in the roadmap ledger immediately** (`releases roadmap add`) before execution begins. The issue is the signal stream; the pointer doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt. Governed by `PROJECT/PDDA.md` → "GitHub issue intake".
    37	- Runtime triage labels: since the `XYZ_PYTHON` flip the harness is dual-runtime, so any harness-bug issue gets a `runtime:` label — `runtime:python` (default path), `runtime:bash` (`XYZ_PYTHON=0` opt-out), or `runtime:parity` (the twins diverge). `/file-xyz-bug` harvests and applies it; for in-repo intake (`/triage`, hand-filed `gh issue create`) apply it by hand. Omit rather than guess — a wrong runtime tag misroutes triage.
    38	- Do not override deterministic PDDA findings with prose.
    39	- Do not report a win you did not verify with the relevant script or test.
    40	- Update `CHANGELOG.md` at the end of each iteration; its governance lives in `PROJECT/PDDA.md` — do not re-specify CHANGELOG rules in `AGENTS.md` or elsewhere.
    41	
    42	## Command rails
    43	
    44	For repo correctness:
    45	
    46	```bash
    47	bash githooks/install.sh        # ONCE PER CLONE — wires the pre-push gate (GH-544)
    48	bash githooks/install.sh --check # is this clone gated? exit 1 if not
    49	./validate.sh              # the gate — PARALLEL by default (GH-544), auto-sized to the host (GH-35)
    50	./validate.sh --print-mode # which mode would this host pick, and why — runs nothing
    51	./validate.sh --sequential # force the sequential run (~16 min)
    52	./validate.sh --tier 2 --subsystem hq   # GH-35: one subsystem's focused suites (pre-push speed, NOT evidence)
    53	./validate.sh --auto       # GH-35: classify the git diff, run the minimal safe tier (fails closed to 3)
    54	./validate.sh --throttle   # GH-35: 2 workers under nice — quiet-machine mode (--burst restores full width)
    55	bash ci-local.sh           # the QUALIFYING run — sequential + writes the gate record (GH-509/GH-536)

codex
ANSWER: Do not create 0.7.5 and do not repurpose Sundown. Sequence 0.7.4 Linux-RC (with the red Ubuntu work dialed in), then Cargo after a scope reconciliation and gate-first start, then Meter gate-first. Treat #252 as an immediate non-release repair; keep Sundown fourth.

FINDINGS

- [Blocker] Fold #249 and #251 into 0.7.4. Its DB exit criterion requires a “qualifying 100% green hosted Ubuntu CI run,” so a known-red Ubuntu job cannot be deferred to 0.7.5. #249 confirms the canary is red on `development`, lists the root cause, and explicitly says the three other job failures must also be resolved for green (`PROJECT/1-INBOX/GH-249-CANARY-EUID-ROOT-ASSERTIONS.md:18-32,56-61`). A waiver would not make the run green. The advisory status is not a reason to accept a permanently red signal.

- [Blocker] Cargo is not presently a coherent themed release in the DB. `releases show --gid rel-01M0GKP4YGTHVTXHVV5WAP08B5` reports seven dialed-in items: #105, #107, #201, #182, #193, #222, #223. Yet its release prose describes a two-item vendored-ledger arc (`RELEASES.md:227-229`). Re-dial/re-scope before scheduling Cargo; do not claim it is already cleanly populated.

- [Should] “Gate first” means “the first work is a real release gate, observed red with a negative control,” not “the release may not be scheduled.” Cargo itself says its gate is not built and must precede member fixes (`RELEASES.md:228`); Meter and Sundown say the same in their CLI records. Cheapest honest move: one release-specific gate task per release, with its controlled red, before admitting implementation lanes.

- [Should] Keep Sundown. Its distinct dependency chain—prove no real Bash fallback use, re-vendor fleet copies, then delete twins—is real and ordered (`RELEASES.md:210-215`). It is already over-broadened by inherited Meter work; adding ledger/intake work would make the theme less legible, not more.

- [Should] Do not create a “ledger integrity” release for #252/#243/#216/#215/#222 as proposed. #252 is a P0 intake-path repair, #243 is canonical-document/dashboard drift, #215 is a direct vendored-Cargo defect, and #216 still needs a format-policy decision rather than implementation (`PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md:85-94`; `GH-216-LEDGER-BULLET-FORMAT.md:59-76`). This is maintenance plus an unresolved design choice, not one release arc.

- [Should] #215 belongs in Cargo once it has a contract: it blocks vendored `.xyz/` reconciliation outright (`PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md:33-62`). #216 can join only after the parser-vs-required-format decision; #222 is already Cargo-assigned in the DB but is likewise marked `needs-contract`.

- [Should] Keep version numbers; do not globally renumber or retarget merely for numeric order. Cargo explicitly records that its target date—not its `0.9.0` number—sets sequence (`RELEASES.md:227`), and Sundown’s earlier renumber demonstrates the historical churn cost (`RELEASES.md:213`). Retarget only when evidence forces a date slip, most immediately Linux-RC if the expanded green-run work cannot meet 2026-09-05.

- [Should] The missing strategic item is the active, unassigned #141 Fuzz/ATE arc (285), plus Cargo’s unrelated ATE items #201 and #182. Do not leave it silently riding Cargo: either create a later, dedicated Fuzz/ATE release after its contract/gate exists, or explicitly place it after Meter. It currently has no release home and is marked not sequenceable (`LEADERBOARD.md:29,45,51`; `MARATHON-PLAN-2026-08-25.md:98-99`).

- [Should] #67’s 340 operator-overridden score deserves an immediate contract/doc decision, but not a release slot: it is not yet a release-shaped, verified arc (`LEADERBOARD.md:13,86`; `MARATHON-PLAN-2026-08-25.md:93`). Score is a work-selection input, not permission to mix themes.

- [Nit] Rename Meter only. Its current purpose is public unauthenticated onboarding, while “Meter” describes the metering work explicitly moved to Sundown. Cargo and Sundown remain clear enough.

- [Pass] Reading `ROADMAP.md` should not influence this plan: the router declares it frozen legacy and names `releases.db` as canonical (`ROUTER.md:10-12,22-25`), despite the file’s stale self-description (`ROADMAP.md:18-30`).

RECOMMENDATION: Finish an expanded 0.7.4 first; then run a short non-release ledger/Cargo scope reconciliation and gate build, ship Cargo, then Meter—leaving Sundown intact and #252 as an urgent repair rather than inventing 0.7.5 or a ledger-themed release.
tokens used
119,646
ANSWER: Do not create 0.7.5 and do not repurpose Sundown. Sequence 0.7.4 Linux-RC (with the red Ubuntu work dialed in), then Cargo after a scope reconciliation and gate-first start, then Meter gate-first. Treat #252 as an immediate non-release repair; keep Sundown fourth.

FINDINGS

- [Blocker] Fold #249 and #251 into 0.7.4. Its DB exit criterion requires a “qualifying 100% green hosted Ubuntu CI run,” so a known-red Ubuntu job cannot be deferred to 0.7.5. #249 confirms the canary is red on `development`, lists the root cause, and explicitly says the three other job failures must also be resolved for green (`PROJECT/1-INBOX/GH-249-CANARY-EUID-ROOT-ASSERTIONS.md:18-32,56-61`). A waiver would not make the run green. The advisory status is not a reason to accept a permanently red signal.

- [Blocker] Cargo is not presently a coherent themed release in the DB. `releases show --gid rel-01M0GKP4YGTHVTXHVV5WAP08B5` reports seven dialed-in items: #105, #107, #201, #182, #193, #222, #223. Yet its release prose describes a two-item vendored-ledger arc (`RELEASES.md:227-229`). Re-dial/re-scope before scheduling Cargo; do not claim it is already cleanly populated.

- [Should] “Gate first” means “the first work is a real release gate, observed red with a negative control,” not “the release may not be scheduled.” Cargo itself says its gate is not built and must precede member fixes (`RELEASES.md:228`); Meter and Sundown say the same in their CLI records. Cheapest honest move: one release-specific gate task per release, with its controlled red, before admitting implementation lanes.

- [Should] Keep Sundown. Its distinct dependency chain—prove no real Bash fallback use, re-vendor fleet copies, then delete twins—is real and ordered (`RELEASES.md:210-215`). It is already over-broadened by inherited Meter work; adding ledger/intake work would make the theme less legible, not more.

- [Should] Do not create a “ledger integrity” release for #252/#243/#216/#215/#222 as proposed. #252 is a P0 intake-path repair, #243 is canonical-document/dashboard drift, #215 is a direct vendored-Cargo defect, and #216 still needs a format-policy decision rather than implementation (`PROJECT/2-WORKING/MARATHON-PLAN-2026-08-25.md:85-94`; `GH-216-LEDGER-BULLET-FORMAT.md:59-76`). This is maintenance plus an unresolved design choice, not one release arc.

- [Should] #215 belongs in Cargo once it has a contract: it blocks vendored `.xyz/` reconciliation outright (`PROJECT/1-INBOX/GH-215-RECONCILER-VENDOR-PATHS.md:33-62`). #216 can join only after the parser-vs-required-format decision; #222 is already Cargo-assigned in the DB but is likewise marked `needs-contract`.

- [Should] Keep version numbers; do not globally renumber or retarget merely for numeric order. Cargo explicitly records that its target date—not its `0.9.0` number—sets sequence (`RELEASES.md:227`), and Sundown’s earlier renumber demonstrates the historical churn cost (`RELEASES.md:213`). Retarget only when evidence forces a date slip, most immediately Linux-RC if the expanded green-run work cannot meet 2026-09-05.

- [Should] The missing strategic item is the active, unassigned #141 Fuzz/ATE arc (285), plus Cargo’s unrelated ATE items #201 and #182. Do not leave it silently riding Cargo: either create a later, dedicated Fuzz/ATE release after its contract/gate exists, or explicitly place it after Meter. It currently has no release home and is marked not sequenceable (`LEADERBOARD.md:29,45,51`; `MARATHON-PLAN-2026-08-25.md:98-99`).

- [Should] #67’s 340 operator-overridden score deserves an immediate contract/doc decision, but not a release slot: it is not yet a release-shaped, verified arc (`LEADERBOARD.md:13,86`; `MARATHON-PLAN-2026-08-25.md:93`). Score is a work-selection input, not permission to mix themes.

- [Nit] Rename Meter only. Its current purpose is public unauthenticated onboarding, while “Meter” describes the metering work explicitly moved to Sundown. Cargo and Sundown remain clear enough.

- [Pass] Reading `ROADMAP.md` should not influence this plan: the router declares it frozen legacy and names `releases.db` as canonical (`ROUTER.md:10-12,22-25`), despite the file’s stale self-description (`ROADMAP.md:18-30`).

RECOMMENDATION: Finish an expanded 0.7.4 first; then run a short non-release ledger/Cargo scope reconciliation and gate build, ship Cargo, then Meter—leaving Sundown intact and #252 as an urgent repair rather than inventing 0.7.5 or a ledger-themed release.
