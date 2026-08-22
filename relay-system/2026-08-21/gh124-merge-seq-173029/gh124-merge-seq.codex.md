Reading additional input from stdin...
2026-08-22T00:30:31.954871Z ERROR codex_models_manager::cache: failed to load models cache: missing field `base_instructions` at line 98 column 5
OpenAI Codex v0.144.6
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-54150-qde9l_3o
model: gpt-5.6-terra
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 01a026e0-59a2-7052-918a-38e4b3fcdb13
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Question: is this squash-merge + cleanup sequence the safest one, and what is it missing?

You are advising on a repository closeout in `HiQS-Suite/XYZ-forge` (this repo). Be concrete and
skeptical. Read the repo files you need (`.github/workflows/ci.yml`, `AGENTS.md`, `validate.sh`,
`ROUTER.md`) rather than reasoning from the summary alone.

## Goal the operator stated

One clean local checkout, a fully safe and updated remote `development` branch, and no leftover
worktrees or clone folders. "Measure twice, cut once."

## Established facts (verified, not assumed)

**Folders.** Exactly two locations track this remote: the main checkout at
`~/Documents/GH Repos/XYZ-forge` (clean, on `feat/gh124-closeout-automation`, in sync with origin,
no stash), and one linked worktree `…/scratchpad/pr128-wt` (clean, detached at `a18432ac`, which is
already an ancestor of the branch tip — it holds zero unique commits). No agent session is running
in either; the owning session for the worktree is stopped.

**Open PRs, both targeting `development`:**

- **#127** `docs/gh31-validate-timing` — touches `README.md` only (+5/-2). Ubuntu canary GREEN.
  Carries a `CHANGES_REQUESTED` review whose single blocking ask ("the timing note the quickstart
  comment forward-references does not exist") was satisfied by a later commit that adds exactly that
  note. The review is stale but has not been dismissed or re-approved.
- **#128** `feat/gh124-closeout-automation` — 28 files: `validate.sh`, `relay-automation/*.sh`,
  `utils/py/*.py`, `test/*`, `releases.db`/`releases.sql`, several docs. Ubuntu canary RED. Exactly
  one suite fails: `gh69-roadmap-shadow: 50 pass, 3 fail`. Issue GH-123 documents that same suite,
  the same count, and the same three assertions as pre-existing Linux-only drift already present on
  `development`. Locally on macOS that suite is 53 pass / 0 fail. No reviews at all.

**CI shape.** Triggers are `push: [main, development]` and `pull_request: [main, development]`. The
only macOS job (`boundary-macos`, "promotion boundary") is gated `if: github.event_name == 'push' &&
github.ref == 'refs/heads/main'` — so it never runs on a PR, and will NOT run when these merge into
`development`. The Ubuntu job is explicitly advisory ("never breakage"; the repo ships to macOS).
Consequence: the merge commits land on `development` with no macOS evidence unless it is produced
locally.

**Other state.** `development` is unprotected (no required checks). Repo allows squash, merge, and
rebase; `delete_branch_on_merge` is FALSE. `main` is 638 commits behind `development`. The two PRs'
file sets are disjoint (`README.md` vs. 28 other paths), so neither order creates a conflict.
`releases.db` is a binary/dump artifact with a documented merge-conflict resolver
(`utils/releases-merge-resolve.sh`).

## The proposed sequence

1. Squash-merge **#127** (docs-only, Ubuntu-green, review satisfied).
2. Run `./validate.sh --sequential` locally on macOS; squash-merge **#128** only if green.
3. `git checkout development && git pull` in the main checkout.
4. `git worktree remove` the `pr128-wt` worktree, then `git worktree prune`.
5. Delete only the two now-merged local branches. Leave everything else alone.

## What I want from you

1. **Is this the safest order?** If a different order is safer, say which and why — specifically,
   does gating the local macOS run on the *pre-merge* branch tip rather than on the *post-merge*
   `development` state leave a real gap, given the two PRs are disjoint?
2. **What is missing?** Name concrete omissions. Candidates I want you to accept or reject with
   reasoning, plus anything I have not listed:
   - Should the stale `CHANGES_REQUESTED` on #127 be formally dismissed or re-approved before
     merging, rather than merged around?
   - Should #128 get a recorded review/approval given it currently has none and is 28 files?
   - Should the merge of #128 note the known-red advisory canary and reference GH-123 explicitly, so
     the red is auditable rather than silently accepted?
   - Does squash-merging #128 lose anything that matters (10 commits including relay/agent2agent
     transcripts and review-response commits collapsing into one)?
   - `releases.db` / `releases.sql`: does merging a binary dump via squash risk a silent bad state,
     and should `releases roadmap sync` / the resolver be run or verified after?
   - After both merges, should anything be done about `main` being 638 commits behind, or is that
     correctly out of scope for a cleanup task?
   - Is there a post-merge verification step missing — e.g. re-running the gate on the merged
     `development`, or triggering `workflow_dispatch` to get a real hosted run?
3. **What would make this unsafe?** Name the specific failure mode that would make an operator
   regret running this sequence, and the cheapest check that would catch it beforehand.

Answer directly. Prioritize by real risk, and say plainly if a step is fine as-is — do not invent
work to look thorough.

hook: SessionStart
hook: SessionStart Completed
codex
I’ll inspect the repo’s actual rails and CI behavior, then give a risk-ranked closeout recommendation.
exec
/bin/zsh -lc "pwd && sed -n '1,240p' WORKTREE-SAFETY.md && sed -n '1,260p' ROUTER.md && sed -n '1,220p' GUIDING-PRINCIPLES.md && sed -n '1,260p' .github/workflows/ci.yml && sed -n '1,260p' validate.sh" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-54150-qde9l_3o
 succeeded in 0ms:
/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-54150-qde9l_3o
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
agent2agent); a push the classifier rates `tier=2` runs only those focused suites at the boundary,
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
name: CI

# ── READ THIS BEFORE CONCLUDING "CI IS GREEN" (GH-123, 2026-08-21) ──────────────────────────────
#
# Two things about this file have now been re-litigated more than once. Both are recorded here so
# the next person does not rediscover them from scratch.
#
# 1. THE AUTOMATIC TRIGGERS WERE DEAD FROM 2026-08-17 TO 2026-08-21 (GH-59). This is HISTORY, not a
#    live warning — they work now — but it is written down because it silently voided four days of
#    merges and will be misread later if it isn't.
#
#    From the 2026-08-17 re-arm until 17:09 UTC on 2026-08-21, the ENTIRE run history of this
#    repository was `workflow_dispatch` runs. PRs #116, #121 and #122 all merged with ZERO checks.
#    Then, with no change to this file's triggers, both automatic events began firing normally:
#    run 32506672733 (`pull_request`, branch `docs/gh123-ci-canary-codify`) and run 32506697196
#    (`push`, `development`), minutes apart.
#
#    WHY IT STARTED WORKING IS NOT ESTABLISHED. The only honest statement available from a normal
#    token is that it changed between 16:45 and 17:09 UTC on 2026-08-21. If a repository setting was
#    flipped in that window, say so on #59 — the answer is cheap to record now and expensive to
#    reconstruct later. The audit log needs `admin:org`.
#
#    Ruled out during the outage, with evidence, so nobody re-tests them: billing/spending limit (a
#    dispatch on the same branch ran fine — this was the leading theory and it was wrong), workflow
#    disabled (`state=active`), repo is a fork (it is not), Actions disabled (`enabled: true,
#    allowed_actions: all`), the base-branch filter (#116 targeted `development`, which is listed),
#    the workflow missing from the PR head (`d09bdb6` is an ancestor of every branch tested), and
#    fork-PR approval (zero runs ever sat in `action_required`, so nothing was being created).
#
#    A CONFLICTING PR STILL GETS NO RUN, AND THAT IS NORMAL GITHUB BEHAVIOUR — NOT A RELAPSE.
#    `pull_request` workflows are built against the merge ref (`refs/pull/N/merge`), which GitHub
#    does not create while a PR has conflicts, so a conflicted PR shows ZERO checks — visually
#    identical to the outage above. Measured directly on #126: no run for the 9 minutes it was
#    CONFLICTING, then a `pull_request` run within seconds of a rebase clearing it. It is also why
#    #116 got no checks. Before concluding the triggers have broken again, check
#    `gh pr view <n> --json mergeable` — if it says CONFLICTING, rebase and the run appears.
#
#    THE READING RULE THAT OUTLIVES ALL OF THIS: a clean `mergeStateStatus` means "no *failing
#    required* checks", which is also what it says when no checks exist at all. Confirm a run
#    actually exists before treating a green PR page as evidence — `gh pr view <n> --json
#    statusCheckRollup` names the jobs, and an empty array is the tell. To fire this workflow by
#    hand at any time:
#
#        gh workflow run ci.yml --ref <branch>
#        gh run watch <run-id>
#
# 2. AN ADVISORY JOB THAT DIES EARLY STILL REPORTS THE RUN GREEN. The ubuntu canary below is
#    advisory by design ("never breakage") and ends in a verdict step that always passes. That
#    means a FAILING canary is invisible at the run level. It happened: from the 2026-08-17 re-arm
#    until 2026-08-21, `utils/fuzzing/fuzz-loop.sh` had no shebang, shellcheck raised SC2148 at
#    severity=error, the FIRST step of the job exited 1, and every later step — the PDDA gate, the
#    frozen-twin guard, acorn-extract, Fast Gate, validate.sh — silently never ran, for four days,
#    under a green ✓. Fixed in #121 (e9b9b07).
#
#    The lesson is structural, not about that one file: when this job is red, open the JOB and look
#    for steps marked `-`. A short green run is the symptom to distrust. Steps here are ordered
#    cheapest-first, so an early failure hides the most.
#
#    Run 32504570094 (2026-08-21, against 02ce229) is the first end-to-end execution. Baseline:
#    shellcheck / bash+node syntax / settings JSON / PDDA gate / acorn-extract all PASS on Linux;
#    7 assertions across 5 suites fail. Tracked in GH-123 — read it before assuming any of them is
#    environment noise, and see the GH-232 note further down for why that assumption is expensive.
#
#    THIS IS STILL TRUE NOW THAT THE AUTOMATIC TRIGGERS WORK, and that is the point. Runs
#    32506672733 (`pull_request`) and 32506697196 (`push` on `development`) both concluded
#    **success** while this job concluded **failure** on the same 7 assertions. So the trap did not
#    end with the outage in note 1 — restoring the triggers restored a green checkmark on every PR
#    that is reporting a red canary underneath it. Until GH-123 is cleared, treat this job's own
#    conclusion as the signal and the run's conclusion as decoration.
#
# GH-216 cut `development` as the WIP branch that all work targets, but these
# triggers stayed pinned to `main` — so no PR into `development` ran CI at all.
# Both branches are gated here; add any future long-lived integration branch too.
# ── HOSTED CI RE-ARMED FOR THE PUBLIC REPOSITORY (XYZ-forge #16, 2026-08-17) ─────────────────────
#
# GH-544 deliberately removed `push:` and `pull_request:` while the source repository was private.
# That bridge had one explicit end condition: the repository becomes public. HiQS-Suite/XYZ-forge
# is public, so automatic triggers are restored here. The local pre-push gate remains useful as the
# earliest signal; hosted CI restores independent attestation and the Linux portability canary.
#
# WHY: measured in #509/#528 — Aug 1-14 cost $21.99 gross / $10.00 billed, exhausting the 2,000
# included minutes on Aug 11 and hitting the $10 spending limit on Aug 14, which blocked Actions
# outright. Projection at that cadence was ~$47/mo gross. We do not pay that for an internal tool.
#
# THE BRIDGE HAS ENDED. The re-arm keeps the constraints the private-phase analysis established:
#   1. `push:` and `pull_request:` cover main and development. The macOS job itself remains guarded
#      to a push on main; pull requests receive only the Ubuntu portability canary.
#   2. Expect a BATCH of accumulated Linux portability drift on the first green-field run. The local
#      gate is macOS, so the platform we ship to stayed covered — the ubuntu canary did not, and drift
#      has been accumulating unreported since this date. That backlog is the known, accepted cost of
#      this decision, not a surprise.
#   3. The GH-509 macOS boundary is again the promotion witness for an exact main commit.
#
# EVERYTHING BELOW IS DELIBERATELY PRESERVED — jobs, routing, and especially the GH-509 Phase 4 cost
# analysis in the macOS job's header. That reasoning is what you will want when re-arming; deleting it
# and rediscovering it on an invoice is the failure this comment exists to prevent.
on:
  push:
    branches: [main, development]
  pull_request:
    branches: [main, development]
  workflow_dispatch:

concurrency:
  # Cancel superseded runs within the same event lane. Keep manual integration runs
  # independent so a branch push cannot cancel an operator-requested full gate.
  group: ${{ github.workflow }}-${{ github.event_name }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  # GH-509 Phase 4 — THE PROMOTION BOUNDARY. This is the only job whose green means anything about
  # what we ship, because it is the only one running the platform we ship to.
  #
  # WHY IT IS RARE, AND MUST STAY RARE: hosted macOS runners bill at roughly 10x Linux. At the volume
  # this repo generates (37 pushes to `development` in one 24h sample) macOS-everywhere would cost
  # thousands a month. Do NOT add `pull_request` here.
  #
  # WHY `workflow_dispatch` WAS REMOVED (2026-08-13, measured — this was the original design and it
  # did not survive contact with the invoice). The theory was that a dispatch costs "well under a
  # dollar a handful of times a month". The org's actual August usage says otherwise: macOS 3-core
  # 75 minutes = **$4.65 net**, against Ubuntu's 2,740 minutes = $4.44 net. Seventy-five macOS minutes
  # cost more than 2,740 Linux minutes, because macOS bills ~10x AND draws no included-minute discount
  # on a private repo. Three dispatches on one branch in one day consumed roughly half a $10 monthly
  # budget. The gating was correct; what was missing was any brake on how often the deliberate trigger
  # gets pulled — and "deliberate" is not a rate limit when the same person can dispatch it while
  # iterating on the workflow itself.
  #
  # WHAT THIS COSTS US, STATED PLAINLY: the original argument for `workflow_dispatch` was real —
  # work lands on `development` and `main` sees almost nothing, so a main-only boundary arrives AFTER
  # the promotion decision rather than before it. That gap is now open. The substitute is the LOCAL
  # gate on the platform we ship to: `./validate.sh` (and, per GH-528, `--parallel N` for a ~3-minute
  # run) plus `utils/gate-record.sh`, which is self-reported and does NOT qualify a promotion. If a
  # pre-merge macOS witness is needed for a specific commit, re-enable this trigger deliberately,
  # spend the ~$1.25-1.50, and turn it back off — rather than leaving it armed by default.
  #
  # HONEST LIMIT ON "EXACT COMMIT" (retained; applies to any re-enabled dispatch): `workflow_dispatch`
  # targets a REF, not an arbitrary SHA — GitHub resolves the ref's current HEAD. So this job cannot
  # be pointed at an old commit; it qualifies whatever that ref points to when dispatched. The resolved
  # SHA is printed into the job summary for exactly this reason: the promotion rule compares against a
  # recorded SHA, not against "the run I remember starting".
  #
  # NO SKIP LIST, deliberately. It invokes the authoritative validator directly rather than scraping
  # `TESTS` out of it — the scrape can only see `.sh` entries, which is how the 20-test Python layer
  # (the AUTHORITATIVE implementation since GH-264) went unexercised in CI for months. A second list
  # is a second thing to keep honest; there is no second list here.
  boundary-macos:
    name: promotion boundary (macOS — the platform we ship to)
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: macos-latest
    # A bound, not an estimate. The suite runs ~13-15 min locally; at 10x billing an unbounded hang is
    # the expensive failure mode, so cap it rather than discover the cost afterwards.
    timeout-minutes: 45
    steps:
      - name: Check out repo
        uses: actions/checkout@v4
        with:
          # Same reason as the canary job: fixtures synthesize an "older" ancestor with
          # `git rev-list --max-parents=0 HEAD`, which a shallow clone silently defeats.
          fetch-depth: 0

      - name: Prepare git environment for fixture-driven tests
        run: |
          set -euo pipefail
          git config --global init.defaultBranch main
          git config --global user.email "ci@runner.invalid"
          git config --global user.name "CI Runner"

      - name: Install npm dependencies
        run: npm ci

      # The hosted runner's Python has no pytest, and validate.sh's python lane needs it — the
      # first boundary dispatch (run 31661285957) failed exactly here. Ironic and instructive:
      # GH-509's own headline defect was "the hosted route never ran the 20 python tests"; the
      # first time they ran on hosted macOS, the environment couldn't run them.
      - name: Install pytest for the python lane
        run: python3 -m pip install --quiet --break-system-packages pytest

      - name: Run the authoritative validator (no skips)
        env:
          # The one documented exclusion, and it is not a coverage skip: this test makes a real
          # billed API call to a live agent. It self-skips off-PATH anyway; the env var makes the
          # intent explicit rather than incidental.
          RELAY_SELF_SUFFICIENCY_SKIP: "1"
        # `--sequential` is PINNED here and must stay pinned. GH-544 made parallel the default for the
        # local gate, which is correct there — but this job is the promotion boundary, and the whole
        # point of it is that its green means something the local run's cannot. Promotion evidence
        # stays sequential (GH-528 Phase 2 has not been met), so the flag is explicit rather than
        # inherited: a future change to validate.sh's default must not be able to silently change what
        # this job attests. test/ci-workflow.sh asserts the flag is present.
        run: ./validate.sh --sequential

      - name: Promotion evidence
        if: always()
        run: |
          set -euo pipefail
          if [ "${{ job.status }}" = "success" ]; then
            line="MACOS-BOUNDARY: green ${GITHUB_SHA}"
            note="This commit is promotion-qualified (GH-509 §6). Cite this SHA, not this run."
          else
            line="MACOS-BOUNDARY: red ${GITHUB_SHA}"
            note="NOT promotable. Unlike the ubuntu canary, this ran on the platform we ship to — a failure here is a real defect for real users."
          fi
          echo "$line"
          echo "$note"
          { echo "### $line"; echo; echo "$note"; } >> "$GITHUB_STEP_SUMMARY"

  # GH-509 Phase 2 — this job is a PORTABILITY CANARY, not a gate.
  #
  # XYZ ships to macOS developers. Linux and Windows are on the roadmap and are not here yet, so a
  # failure on ubuntu is portability DRIFT, not breakage: it says "this would not work on the platform
  # we do not support yet." Every one of the three CI failures on 2026-08-12 was of exactly that shape
  # (agent CLIs absent from the runner), and treating them as breakage is what produced five hours of
  # unread red across eight commits — which is worse than no signal at all, because it trains everyone
  # to ignore the one channel that might have said something real.
  #
  # `continue-on-error: true` at JOB level lets the workflow run pass while this job's own conclusion
  # still records `failure`, so drift stays queryable through the jobs API without marking the commit
  # broken.
  #
  # HONEST LIMIT, stated because this file is exactly the kind of place GH-419 gets violated: the
  # workflow-contract test can assert this key is PRESENT. It cannot assert GitHub's runtime semantics.
  # The acceptance criterion in PROJECT/2-WORKING/GH-509-CI-MINUTE-BURN.md is therefore a witnessed
  # hosted run, not a green grep.
  #
  # Advisory does NOT mean ignorable, and making it non-blocking supplies no reason for anyone to read
  # it — that critique came from the agy review and it is correct. The mechanism that makes it read is
  # elsewhere: the canary's status is a line in the promotion output, consulted at the moment a human
  # is already deciding something. If two consecutive promotions ship with drift named and unresolved,
  # this job has proven it is not being actioned and should be deleted rather than kept as decoration.
  canary-ubuntu:
    name: portability canary (ubuntu — advisory, never breakage)
    runs-on: ubuntu-latest
    continue-on-error: true
    steps:
      - name: Check out repo
        uses: actions/checkout@v4
        with:
          # GH-232: several tests (e.g. xyz-vendor.sh's staleness check) use `git rev-list
          # --max-parents=0 HEAD` to synthesize an "older" ancestor commit for a fixture. The
          # default shallow clone (depth 1) makes the boundary commit look parentless, so it
          # resolves to the SAME commit as HEAD — silently defeating the fixture, not a real bug.
          fetch-depth: 0

      - name: Classify CI route
        id: route
        env:
          EVENT_NAME: ${{ github.event_name }}
          BASE_SHA: ${{ github.event.pull_request.base.sha }}
          BEFORE_SHA: ${{ github.event.before }}
        run: |
          set -euo pipefail

          # GH-509 Phase 3 — pushes classify from their pushed range, like PRs classify from a diff.
          base=""
          case "$EVENT_NAME" in
            pull_request) base="$BASE_SHA" ;;
            push)         base="$BEFORE_SHA" ;;
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

# ── GH-45: REFUSE to run from a linked git worktree ─────────────────────────────────────────────
# A linked worktree shares the parent clone's .git common directory — config, refs, and object
# store alike. A suite that escapes its fixture (or resolves one to an empty string) therefore
# reaches the PARENT clone, not a sandbox: the observed 2026-08-19 run set core.bare=true,
# repointed origin at a deleted temp path, deleted every refs/remotes/origin/*, and overwrote
# development with fixture commits (GH-564's class, firing for real). The detection is the same
# --git-common-dir idiom the GH-448 driver-lock resolver uses: in the main checkout the absolute
# git dir IS the common dir; in a linked worktree it is <common>/worktrees/<name> and differs.
# Fail closed for every mode — tiers 1 and 2 run fixture-driven suites too. BOTH the invocation
# CWD (where a suite's `git -C ""` escape lands) and HERE (whose clone the identity bracket
# asserts) are checked, so invoking the script by absolute path from outside cannot slip past.
_wt_refuses() {  # <dir>... -> exit 2 if any dir lives in a linked worktree
  local d a c ca
  for d in "$@"; do
    a="$( cd "$d" 2>/dev/null && git rev-parse --absolute-git-dir 2>/dev/null )" || continue
    c="$( cd "$d" 2>/dev/null && git rev-parse --git-common-dir 2>/dev/null )" || continue
    [ -n "$a" ] && [ -n "$c" ] || continue
    ca="$( cd "$d" 2>/dev/null && cd "$c" 2>/dev/null && pwd -P )" || continue
    [ -n "$ca" ] || continue
    if [ "$a" != "$ca" ]; then
      cat >&2 <<WTREFUSE
validate.sh: REFUSING — '$d' is a linked git worktree, which shares the parent clone's
  .git (config, refs, objects). Suites that write to 'the repo' reach the PARENT, not a
  fixture: an observed run set core.bare=true, repointed origin at a deleted temp path,
  deleted every refs/remotes/origin/*, and overwrote development with fixture commits.
  Run the gate from a normal clone. Override with XYZ_ALLOW_WORKTREE_GATE=1 only if you
  accept that blast radius.
WTREFUSE
      exit 2
    fi
  done
}
if [ "${XYZ_ALLOW_WORKTREE_GATE:-0}" != "1" ]; then
  _wt_refuses "$HERE" "${PWD:-.}"
else
  # Announced, never silent — a bypass that says nothing is indistinguishable from no guard.
  echo "validate.sh: XYZ_ALLOW_WORKTREE_GATE=1 — running from a linked worktree at the operator's explicit request; the parent clone's .git is exposed (GH-45)." >&2
fi

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
  "commandcode-turn.sh"        # GH-42 (Commandcode headless turn-taker)
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
  "gh90-allowlist-directory.sh" # GH-90 (a DIRECTORY on ALLOW_PATHS was unmatchable by construction, so a valid lane surfaced as a containment violation) — 19/0; control: pre-fix replay 10/9. The nine that pass pre-fix are the point — C3/C5 are GH-59's own rules, which this fix had to leave intact, and C7 executes a real off-lane write, so the suite still goes red against a build with containment removed
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
  "gh35-test-tiers.sh"                 # GH-35 (tiered test selection + CPU governance) — 56/0; pins the registry contract (every registered suite exists AND is in TESTS), the fail-closed tier boundaries, the balanced cores/2 default + --throttle/--burst/env levers, nice -n 10 on the workers, and the tier-1/tier-2 execution paths against fixture clones whose suites are stubs (real runner, real pool, real summary math)
  "gh1-fixture-guard.sh"               # GH-1 (shared require_fixture resolved-containment + clone-identity invariant gate; covers the GH-567 lexical-check residual)
  "gh1-adoption-guard.sh"             # GH-10 (every fixture-creating suite carries require_fixture adoption — derivation computed from source, exemptions declared in-file; controls prove the guard fires on an unguarded new suite, a stripped adoption, and a removed exemption marker)
  "gh314-transcript-writeset.sh"       # GH-314 (the write set is THREE paths: the transcript's git add was outside GH-514's preflight, so an ignored relay-system/ was discovered only after paid turns) — 5/0; control: dropping the transcript path spends 2 builder turns before the same refusal (test/baselines/GH-314-negative-control.md)
  "gh520-default-reviewer-stub.sh"     # GH-520 (test/_setup.sh gives every fixture a default CODEX_BIN, so a suite tests its subject rather than the reviewer probe) — 11/0; control: with gh402's own stub removed AND this default removed, gh402 fails with the probe's message verbatim (test/baselines/GH-520-default-stub-control.md)
  "gh527-destructive-git-guard.sh"     # GH-527 (a tree-overwriting git command snapshots the tracked files it destroys into .tick/orphan-backups/ first) — 26/0; controls: a no-op guard drops 9 assertions, and a blanket that fires on a CLEAN tree drops exactly the control assertion. Clean-tree silence is defended by TWO conditions, so it takes a combined mutation to falsify — recorded in test/baselines/GH-527-negative-control.md
  "marathon.sh"
  "marathon-closeout.sh"
  "gh484-phase-dir-default.sh"   # GH-484 (phase-output default is marathon-system/; --phases-dir still overrides; the dirty-tree exclusion tracks the CONFIGURED dir) — 10/0; controls: pre-fix red on both defaults and both containment cases, plus a stray-file control proving the clean check actually ran. Forces XYZ_PYTHON=0 so the Bash twin is really exercised
  "marathon-root-audit.sh"       # GH-209 (static audit: every test/marathon*.sh invocation is MARATHON_ROOT-scoped)
  "rtl-orphan-backup.sh"         # GH-141 (concurrent peer-edit race: revert unchanged, content recoverable)
  "gh91-relay-scratch.sh"          # GH-91 (sanctioned .relay-scratch/ for builder verification output: exempted in rtl_check + rtl_worktree_end, pre-created by begin, named in the turn prompt; never copied back, discarded under ROOT; controls pin that stray writes and lookalike prefixes still go off-lane) — 15/0, driven at the lib-function level, no builder binary needed
  "gh124-closeout.sh"            # GH-124 (closeout automation, on-disk gate receipts, workspace sweep GC, and early drift alert)
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
  "gh103-timeline-exporter.sh"   # GH-103/109/110/111/108: the READ-ONLY projection of releases.db
                                 #   onto the timeline viewer. The exporter had NO suite before this,
                                 #   which is how #109 survived — it asserted a marathon membership the
                                 #   data never claimed, latent until a non-marathon item joined a
                                 #   marathon release. Pins grouping by manifest_items.marathon_id,
                                 #   the dialed_in+shipped denominator, baseline/growth emission, the
                                 #   rating metrics + effectiveScore precedence, and the leaderboard's
                                 #   one-scorer property (script ranking == --json ordering).
  "gh32-releases-app.sh"         # GH-32 Phase 0+1 (SQLite RELEASES ledger CLI: schema/GID shape,
                                 #   writer-lock + journal protocol, canonical dump, receipt chain,
                                 #   import grandfathering, side-by-side gen) — 81/0; registered in the
                                 #   same commit as utils/py/releases_app.py per the lesson above. The
                                 #   four check-failure negative controls, the five crash boundaries,
                                 #   and the refused-writer-changes-nothing control are the point; the
                                 #   revert-and-replay transcript is test/baselines/GH-32-negative-control.md
  "gh32-releases-artifacts.sh"   # #52 (the COMMITTED releases.db/releases.sql pair actually agrees —
                                 #   gh32-releases-app.sh only proves the CLI works in fixtures). The
                                 #   documented merge procedure has a human step (`check --rebuild`);
                                 #   skip it and the committed DB disagrees with the dump silently,
                                 #   and the DB is what every reader trusts at runtime. Read-only and
                                 #   NEVER --rebuild: a gate that repairs destroys the evidence that a
                                 #   merge was mis-resolved. Runs against a COPY (plain `check` writes
                                 #   when an intent journal is live) and hashes the clone's artifacts
                                 #   before/after to prove it. 10/0; control in
                                 #   test/baselines/GH-52-negative-control.md
  "gh53-releases-merge-resolve.sh" # #53 (derived-artifact attributes + the one-command ledger merge
                                 #   resolution). Pins that releases.db stays -diff +

mcp: codebase-memory-mcp/index_status started
mcp: codebase-memory-mcp/index_status (failed)
user cancelled MCP tool call
mcp: codebase-memory-mcp/index_repository started
mcp: codebase-memory-mcp/index_repository (failed)
user cancelled MCP tool call
exec
/bin/zsh -lc "rg -n -C 3 '"'^(on:|  pull_request:|  push:|boundary-macos|canary-ubuntu|workflow_dispatch|--sequential)'"' .github/workflows/ci.yml; rg -n -C 4 'ci-local|qualif|sequential|linked git worktree|releases roadmap sync|releases-merge-resolve|worktree remove|worktree prune|development.*main|promotion' ROUTER.md AGENTS.md RELEASES-DB-FAQS.md validate.sh ci-local.sh; nl -ba .github/workflows/ci.yml | sed -n '1,180p'; nl -ba RELEASES-DB-FAQS.md | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-54150-qde9l_3o
 succeeded in 0ms:
94-# EVERYTHING BELOW IS DELIBERATELY PRESERVED — jobs, routing, and especially the GH-509 Phase 4 cost
95-# analysis in the macOS job's header. That reasoning is what you will want when re-arming; deleting it
96-# and rediscovering it on an invoice is the failure this comment exists to prevent.
97:on:
98:  push:
99-    branches: [main, development]
100:  pull_request:
101-    branches: [main, development]
102-  workflow_dispatch:
103-
ROUTER.md-18-
ROUTER.md-19-## Startup sequence
ROUTER.md-20-
ROUTER.md-21-1. Read `ROUTER.md` to understand the repo's operating order and canonical files. -> expect one clear next file, not a repo-wide scavenger hunt.
ROUTER.md:22:2. Read `AGENTS.md` before making recommendations or edits. -> expect explicit assumptions, a reversibility read on consequential changes, and verified claims only.
ROUTER.md-23-3. Read `ROADMAP.md` to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; `ROADMAP.md` is a pointer ledger, not a plan body.
ROUTER.md-24-4. Read the linked `PROJECT/**` document that owns the work you are touching. -> expect the near-top `## Status` table to tell you what was just completed and what is next.
ROUTER.md-25-5. If the task touches project docs, read `PROJECT/PDDA.md` and follow the PDDA contract. -> expect `PROJECT/2-WORKING` docs to have frontmatter, the exact status table, and QA gates when phased.
ROUTER.md-26-6. Before reporting success on code or runtime work, run `./validate.sh`. -> expect the suite to stay green; do not claim completion if it fails or was skipped.
--
ROUTER.md-46-bash githooks/install.sh        # ONCE PER CLONE — wires the pre-push gate (GH-544)
ROUTER.md-47-bash githooks/install.sh --check # is this clone gated? exit 1 if not
ROUTER.md-48-./validate.sh              # the gate — PARALLEL by default (GH-544), auto-sized to the host (GH-35)
ROUTER.md-49-./validate.sh --print-mode # which mode would this host pick, and why — runs nothing
ROUTER.md:50:./validate.sh --sequential # force the sequential run (~16 min)
ROUTER.md-51-./validate.sh --tier 2 --subsystem hq   # GH-35: one subsystem's focused suites (pre-push speed, NOT evidence)
ROUTER.md-52-./validate.sh --auto       # GH-35: classify the git diff, run the minimal safe tier (fails closed to 3)
ROUTER.md-53-./validate.sh --throttle   # GH-35: 2 workers under nice — quiet-machine mode (--burst restores full width)
ROUTER.md:54:bash ci-local.sh           # the QUALIFYING run — sequential + writes the gate record (GH-509/GH-536)
ROUTER.md-55-```
ROUTER.md-56-
ROUTER.md:57:**Both gate entry points refuse to run from a linked git worktree (GH-45)** — a worktree shares
ROUTER.md-58-the parent clone's `.git`, and an observed suite escape corrupted the parent (core.bare, origin,
ROUTER.md-59-remote refs, development). Run the gate from a normal clone; `XYZ_ALLOW_WORKTREE_GATE=1` is the
ROUTER.md-60-announced override for disposable runs.
ROUTER.md-61-
--
ROUTER.md-73-enough to wedge the editor; `--burst` buys the old full-core width back for unattended runs, and
ROUTER.md-74-`--throttle`/`--quiet-cpu` pins 2 workers. Ambient levers: `XYZ_VALIDATE_THROTTLE=1`,
ROUTER.md-75-`XYZ_VALIDATE_MAX_JOBS=N`, `XYZ_VALIDATE_PARALLEL` (flags > MAX_JOBS > THROTTLE > PARALLEL > host
ROUTER.md-76-detection; malformed values exit 2 naming the variable). Below 4 cores, or where `xargs -P` is
ROUTER.md:77:unsupported, the run **falls back to sequential and says so** — every run prints the mode it chose
ROUTER.md-78-and the reason, so a fallback is never silent.
ROUTER.md-79-
ROUTER.md-80-**GH-35 also added TIERED SELECTION on top, as a separate axis from width.** `utils/ci-route.sh`
ROUTER.md-81-owns one fail-closed subsystem registry (hq, releases, telemetry, ate, swe-diagram, pdda,
ROUTER.md-82-agent2agent); a push the classifier rates `tier=2` runs only those focused suites at the boundary,
ROUTER.md-83-`--tier 1` runs the docs gate, and everything else — unknown paths, test edits, kernel surfaces —
ROUTER.md-84-runs the full suite. `--auto` classifies a local diff the same way. Tiers 1 and 2 are pre-push
ROUTER.md:85:speed and are labelled NOT promotion evidence; only `ci-local.sh`'s sequential full run qualifies
ROUTER.md-86-(GH-509).
ROUTER.md-87-
ROUTER.md:88:**What still qualifies a claim is unchanged.** `./validate.sh` in either mode is a self-check;
ROUTER.md:89:`ci-local.sh` is the run that writes the evidence record, it does **not** call `validate.sh`, and it
ROUTER.md:90:stays sequential. The macOS promotion boundary in `ci.yml` pins `--sequential` explicitly for the same
ROUTER.md-91-reason. GH-528 Phase 2 (multi-width stress evidence) is still **owed** — the flip was an operator
ROUTER.md-92-decision taken with that evidence outstanding, mitigated by the announced fallback rather than
ROUTER.md-93-discharged. See `PROJECT/2-WORKING/GH-528-TEST-SUITE-RECALIBRATION.md`, #509 and #544.
ROUTER.md-94-
--
ROUTER.md-123-`releases.db` + `releases.sql` hold TWO mirrored subsystems, both operated through ONE CLI,
ROUTER.md-124-`utils/py/releases_app.py` (alias: the `/releases` skill). Read
ROUTER.md-125-[RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md) before merging either file — the SQLite binary is
ROUTER.md-126-derived; the SQL dump is what git actually merges, and a conflicted merge has a one-command
ROUTER.md:127:resolver (`utils/releases-merge-resolve.sh`).
ROUTER.md-128-
ROUTER.md-129-```bash
ROUTER.md-130-python3 utils/py/releases_app.py check          # trio consistency, receipt chain, crash recovery
ROUTER.md-131-python3 utils/py/releases_app.py next           # the next unshipped release, by target date
--
AGENTS.md-38-reader could not say "that assumption was wrong," you have not made the real bet legible yet.
AGENTS.md-39-
AGENTS.md-40-### 3. Use one reversibility scale
AGENTS.md-41-
AGENTS.md:42:Consequential changes get a read on the shared scale: **Easy / Costly / One-way door**, with one line
AGENTS.md-43-of why. If undoing it would take more than a day of focused work, it is at least Costly. Costly
AGENTS.md-44-changes need a rollback path. One-way doors need explicit confirmation before proceeding.
AGENTS.md-45-
AGENTS.md-46-### 4. Size the blast radius before changing shared surfaces
--
AGENTS.md-61-An uncommitted `provenance.jsonl` is not proof (GH-430). Any run cited as evidence in an issue, PR,
AGENTS.md-62-ROADMAP entry, or decision record must have its `provenance.jsonl` committed in the same PR — a path
AGENTS.md-63-you merely ran and can no longer show counts as no claim at all.
AGENTS.md-64-
AGENTS.md:65:### 7. Record only consequential bets
AGENTS.md-66-
AGENTS.md-67-If a change is Costly, One-way door, or assumption-heavy, record the bet in `CHANGELOG.md` per
AGENTS.md-68-`PROJECT/PDDA.md`. Below that threshold, skip the ritual.
AGENTS.md-69-
--
AGENTS.md-99-
AGENTS.md-100-- **The RELEASES DB is two subsystems behind one CLI** (`utils/py/releases_app.py`): the GH-32
AGENTS.md-101-  release ledger and the GH-69 ROADMAP shadow (`roadmap sync` mirrors `ROADMAP.md`'s ledger into
AGENTS.md-102-  `roadmap_items`, one-way and lossless). Never hand-edit `releases.sql` or `releases.db`; after
AGENTS.md:103:  editing `ROADMAP.md`'s ledger, run `releases roadmap sync`. Merge conflicts on the dump have a
AGENTS.md:104:  one-command resolver (`utils/releases-merge-resolve.sh`). The whole contract, including what a
AGENTS.md-105-  real merge conflict looks like: [RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md).
AGENTS.md-106-
AGENTS.md-107-- **The local gate runs at the push boundary; hosted CI independently attests public-repo changes
AGENTS.md-108-  (GH-544, XYZ-forge #16).** The private-phase bridge ended when this repository became public on
AGENTS.md-109-  2026-08-15. `.github/workflows/ci.yml` now covers `push`/`pull_request` on `main` and `development`;
AGENTS.md:110:  the macOS promotion boundary remains restricted to a push on `main`, while the Ubuntu job is an
AGENTS.md-111-  advisory portability canary. Local commits are ungated on purpose; pushes are still gated by
AGENTS.md-112-  `githooks/pre-push` so failures are caught before the remote round trip.
AGENTS.md-113-  - Wire a new clone once: `bash githooks/install.sh` (idempotent). It installs a dispatch stub into
AGENTS.md-114-    `.git/hooks/`, which covers **every branch and linked worktree** of that clone, including branches
--
AGENTS.md-117-    still per clone and does not travel** — a fresh clone or second machine has NO gate until this
AGENTS.md-118-    runs. Check with `bash githooks/install.sh --check`.
AGENTS.md-119-  - `./validate.sh` is **parallel by default** (~4–6 min at the GH-35 balanced width of cores/2 capped 4; `--burst`
AGENTS.md-120-  restores the old full-core width), auto-sized to the host, and announces a
AGENTS.md:121:    sequential fallback with its reason. `bash ci-local.sh` is still the qualifying run that writes
AGENTS.md:122:    the evidence record — it stays sequential and does not call `validate.sh`.
AGENTS.md-123-  - Bypasses are `git push --no-verify` and `XYZ_SKIP_PREPUSH=1`. Both announce themselves. Use them
AGENTS.md-124-    deliberately, not reflexively — they skip the local boundary even when hosted CI later runs.
AGENTS.md-125-  - **PR checks are meaningful again only after a hosted run actually appears for the commit.** A
AGENTS.md-126-    configured workflow is not evidence; query the run and cite its SHA.
--
AGENTS.md-215-
AGENTS.md-216-  **As the orchestrator, you are the final outer reviewer of any emitted artifact (e.g., an automated PR).**
AGENTS.md-217-  You must treat an automation's emission as an event requiring inspection, not as an automatic success.
AGENTS.md-218-  Before permitting an automated loop to proceed to its next iteration, you must query and verify the emitted PR:
AGENTS.md:219:  1. **Base Branch Sanity:** The PR targets the active WIP branch (`development`), not `main`.
AGENTS.md-220-  2. **Diff Size Sanity:** The diff size matches the logical scope of the fix (e.g. < 500 lines for targeted bugs).
AGENTS.md-221-  3. **Verification Status:** A test gate ran against the final committed state (either CI or a local `validate.sh` run).
AGENTS.md-222-  **Halt Condition:** If an emitted artifact fails any of these predicates, you must suspend the automation loop immediately.
AGENTS.md-223-- **HQ (multi-repo command center)** — for cross-repo tasking (resolve a project → land intake on its
--
AGENTS.md-292-    runs to a single green control run treated as proof, which is one sample from a nondeterministic
AGENTS.md-293-    process.
AGENTS.md-294-- **The local macOS run is the gate; hosted ubuntu is advisory (GH-509).** XYZ is a developer toolkit
AGENTS.md-295-  for **macOS**; Linux and Windows are on the roadmap and not here yet. So `./validate.sh` (or
AGENTS.md:296:  `./ci-local.sh`) on your Mac is the highest-fidelity evidence available — it is the shipping
AGENTS.md-297-  platform with the real toolchain — and it runs a **superset** of the hosted job, including
AGENTS.md-298-  `registry-lock-concurrency.sh`, which CI skips for a contended-Linux flake. The hosted `canary-ubuntu`
AGENTS.md-299-  job is `continue-on-error: true`: its red means *portability drift*, not breakage, and must not be
AGENTS.md-300-  reported as a broken commit. Two consequences that bite: **never defer a test run to CI** — CI is
AGENTS.md:301:  advisory and tests the wrong OS; and **a green local run is self-reported**, so it does not qualify a
AGENTS.md:302:  promotion. Promotion needs a hosted **macOS** run for that exact commit. When a claim really is about
AGENTS.md-303-  Linux, the canary is the right instrument and its red is authoritative.
AGENTS.md-304-- **Commit to the QUEUE; re-anchor, don't rabbit-hole (GH-45).** A wave's committed lane list *is* the
AGENTS.md-305-  active commitment — after each lane attempt, re-read it before acting further. A driven lane that
AGENTS.md-306-  fails **parks** after `LANE_MAX_ATTEMPTS` (default 2): the driver (`marathon-drive.sh` /
AGENTS.md-307-  `relay-drive.sh`) refuses to re-fire it (exit 8, no token), you capture the findings as an issue and
AGENTS.md-308-  stop. Re-firing a parked lane or going off-wave to deep-dive one item requires an explicit operator
AGENTS.md-309-  override (`--force`) or a replan note — never a quiet slide off the plan.
AGENTS.md-310-- **Do not create new git branches** automatically. Only create a new branch if explicitly requested by the user. **This governs interactive work only — it is NOT a licence to commit a marathon onto `development`.** The very next bullet is the carve-out: a marathon/relay-fired lane cuts its own `marathon/gh-<n>-*` branch and PRs back into `development`, and that per-lane branch IS the explicitly-requested case. Read 2026-08-15 as permission to skip the branch, which is how four Meter commits landed straight on `development` with no PR (GH-561). The guard now refuses that (`marathon_drive.py`'s branch guard protects `development`, not just `origin/HEAD`), because a rule an agent can talk itself past is not a rule.
AGENTS.md:311:- **`development` is the standing WIP branch — ALL work targets it, including marathon/relay-fired lanes (cut fresh from `main` 2026-07-17, [GH-216](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/216); policy widened 2026-07-17 to cover marathon lanes too, first applied to [PR #217](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/217)).** The prior `development` had drifted 295 commits behind `main` with no open PRs — retired to `development-archived-2026-07-04` rather than deleted outright. Both manual/exploratory work AND marathon-fired lanes (`marathon/gh-<n>-*` branches, GH-212 convention) now branch off `development` and PR back into it — `--plan`/`marathon.sh` still cuts its own short-lived per-lane branch, just off `development` instead of `main`. Periodically merge `development` → `main` once it's in a shippable state; don't let `main` sit behind `development` indefinitely. Watch for `development` drifting stale again the same way the old one did; re-cut from `main` if it does.
AGENTS.md-312-- **Anti-pattern: renaming a branch with an open PR via GitHub's branch-rename API
AGENTS.md-313-  (`POST /repos/{owner}/{repo}/branches/{branch}/rename`, or `gh api ... branches/<old>/rename`).**
AGENTS.md-314-  It does **not** rename in place — it deletes the old ref and recreates a new one, which GitHub
AGENTS.md-315-  treats as `head_ref_deleted` and **auto-closes the open PR** pointed at that branch (found
--
RELEASES-DB-FAQS.md-9-verified_against:
RELEASES-DB-FAQS.md-10-  - utils/py/releases_app.py
RELEASES-DB-FAQS.md-11-  - test/gh32-releases-app.sh
RELEASES-DB-FAQS.md-12-  - test/gh32-releases-artifacts.sh
RELEASES-DB-FAQS.md:13:  - test/gh53-releases-merge-resolve.sh
RELEASES-DB-FAQS.md-14-  - test/gh54-merged-dump-refusals.sh
RELEASES-DB-FAQS.md:15:  - utils/releases-merge-resolve.sh
RELEASES-DB-FAQS.md-16-  - releases.sql
RELEASES-DB-FAQS.md-17-  - .gitattributes
RELEASES-DB-FAQS.md-18-  - validate.sh
RELEASES-DB-FAQS.md-19-  - .git/hooks/
--
RELEASES-DB-FAQS.md-94-
RELEASES-DB-FAQS.md-95-Or, since 2026-08-19, one command that does all of it and refuses what it cannot settle:
RELEASES-DB-FAQS.md-96-
RELEASES-DB-FAQS.md-97-```bash
RELEASES-DB-FAQS.md:98:utils/releases-merge-resolve.sh
RELEASES-DB-FAQS.md-99-```
RELEASES-DB-FAQS.md-100-
RELEASES-DB-FAQS.md-101-### Do not use `merge=union` — and not for the reason you'd guess
RELEASES-DB-FAQS.md-102-
--
RELEASES-DB-FAQS.md-119-
RELEASES-DB-FAQS.md-120-So the earlier claim in this file — that the header "conflicts by construction on every concurrent
RELEASES-DB-FAQS.md-121-write" and that `check` catches it — was **wrong on both counts**, and is corrected here. The header
RELEASES-DB-FAQS.md-122-often does not conflict at all, and when it duplicates, nothing catches it until the rebuild throws.
RELEASES-DB-FAQS.md:123:`utils/releases-merge-resolve.sh` now refuses a multi-header dump up front, naming the fix. Tracked
RELEASES-DB-FAQS.md-124-as [#54](https://github.com/HiQS-Suite/XYZ-forge/issues/54).
RELEASES-DB-FAQS.md-125-
RELEASES-DB-FAQS.md-126-### The derived artifacts conflict on purpose
RELEASES-DB-FAQS.md-127-
--
RELEASES-DB-FAQS.md-131-defined in `.git/config` — which is not committed, so it would be absent on fresh clones (#4).
RELEASES-DB-FAQS.md-132-
RELEASES-DB-FAQS.md-133-More to the point, auto-resolving is the **wrong outcome**: it lets the merge complete while the DB
RELEASES-DB-FAQS.md-134-still holds only one side's rows, leaving the rebuild easy to forget. The conflict is what stops you
RELEASES-DB-FAQS.md:135:at the moment the decision has to be made. Resolution is `utils/releases-merge-resolve.sh`.
RELEASES-DB-FAQS.md-136-
RELEASES-DB-FAQS.md-137----
RELEASES-DB-FAQS.md-138-
RELEASES-DB-FAQS.md-139-## Q: What triggers the transforms before, during, and after a git operation?
--
RELEASES-DB-FAQS.md-195-   every commit.
RELEASES-DB-FAQS.md-196-4. **`--no-verify` bypasses it**, and this repo has a documented instance of that being used to get
RELEASES-DB-FAQS.md-197-   past a spuriously red gate.
RELEASES-DB-FAQS.md-198-
RELEASES-DB-FAQS.md:199:**Use CI + the gate instead.** `.github/workflows/ci.yml` runs `./validate.sh --sequential` on `push`
RELEASES-DB-FAQS.md-200-and `pull_request` for `main` and `development`. So [#52](https://github.com/HiQS-Suite/XYZ-forge/issues/52)
RELEASES-DB-FAQS.md-201-— wiring `releases check` into `validate.sh` — buys enforcement on four surfaces from one committed
RELEASES-DB-FAQS.md-202-change: every PR before merge, every push to `development` after merge, local `pre-push`, and any
RELEASES-DB-FAQS.md-203-local `validate.sh` run. It travels with the clone and catches divergence regardless of how the merge
--
RELEASES-DB-FAQS.md-225-| `dump-duplicate-setting` | a `settings` key appears twice — same cause; only shows when the generation values differ | keep the row that should win (for `generation`, the higher) |
RELEASES-DB-FAQS.md-226-| `dump-duplicate-gid` | one `global_id` in a table twice — **both branches edited the same record** | a real content conflict; decide which row wins. No union rule can settle this. |
RELEASES-DB-FAQS.md-227-| `dump-load` | backstop for damage not yet named above | read the message; the live DB is untouched |
RELEASES-DB-FAQS.md-228-
RELEASES-DB-FAQS.md:229:`utils/releases-merge-resolve.sh` checks the first of these up front, so the common case is caught
RELEASES-DB-FAQS.md-230-before a rebuild is even attempted.
RELEASES-DB-FAQS.md-231-
RELEASES-DB-FAQS.md-232-## Q: So what's missing?
RELEASES-DB-FAQS.md-233-
--
RELEASES-DB-FAQS.md-235-
RELEASES-DB-FAQS.md-236-| # | Gap | Consequence |
RELEASES-DB-FAQS.md-237-|---|---|---|
RELEASES-DB-FAQS.md-238-| [#52](https://github.com/HiQS-Suite/XYZ-forge/issues/52) — **closed** | Nothing ran `releases check` against the repo's real artifacts — `validate.sh` only exercised the CLI in fixtures | A mis-resolved merge shipped a DB that disagrees with the dump, silently. Now gated by `test/gh32-releases-artifacts.sh` (read-only, never `--rebuild`, runs against a copy so it cannot write to the clone it checks). |
RELEASES-DB-FAQS.md:239:| [#53](https://github.com/HiQS-Suite/XYZ-forge/issues/53) — **closed** | `releases.db` is a committed derived artifact that conflicts on every concurrent write | Now marked `-diff linguist-generated` and given a one-command resolution (`utils/releases-merge-resolve.sh`). The conflict itself is kept **on purpose** — see above. `RELEASES-PREVIEW.md` was a second such artifact and was **deleted** 2026-08-19 rather than managed. |
RELEASES-DB-FAQS.md-240-| [#54](https://github.com/HiQS-Suite/XYZ-forge/issues/54) — **closed** | A naive `merge=union` duplicates the single-row `settings` table, and `check --rebuild` died with an unhandled `IntegrityError` instead of refusing | `validate_merged_dump()` now names each case before anything is written (see below). No merge driver was added: the resolver plus these refusals cover it, and a driver would have to live in uncommitted `.git/config`. |
RELEASES-DB-FAQS.md-241-
RELEASES-DB-FAQS.md-242-**Do #52 first.** It makes a mis-resolved merge *visible*; the other two make merges *easier*. #52 is
RELEASES-DB-FAQS.md-243-worth having even if the merge tooling is never improved, because it catches the mistake regardless of
--
RELEASES-DB-FAQS.md-287-```
RELEASES-DB-FAQS.md-288-
RELEASES-DB-FAQS.md-289-`releases.sql` gets ordinary conflict markers and ends up carrying **both** sides' `-- generation:`
RELEASES-DB-FAQS.md-290-headers. `releases.db` is binary, so git leaves the *ours* copy in the working tree and marks the path
RELEASES-DB-FAQS.md:291:unmerged. That two-file shape is what `utils/releases-merge-resolve.sh` branches on.
RELEASES-DB-FAQS.md-292-
RELEASES-DB-FAQS.md-293-### Four things that were broken, and now are not
RELEASES-DB-FAQS.md-294-
RELEASES-DB-FAQS.md-295-| What | Was | Now |
--
RELEASES-DB-FAQS.md-305-git merge <branch>                      # conflicts releases.sql AND releases.db
RELEASES-DB-FAQS.md-306-# resolve releases.sql BY HAND: union both sides' rows, keep ONE settings block,
RELEASES-DB-FAQS.md-307-# and keep the HIGHEST '-- generation:' header
RELEASES-DB-FAQS.md-308-git add releases.sql
RELEASES-DB-FAQS.md:309:utils/releases-merge-resolve.sh         # takes either side of the .db, rebuilds, verifies, stages
RELEASES-DB-FAQS.md-310-git commit                              # the resolver deliberately does not commit for you
RELEASES-DB-FAQS.md-311-```
RELEASES-DB-FAQS.md-312-
RELEASES-DB-FAQS.md-313-The resolver refuses, without touching the live DB, if `releases.sql` is still unmerged, still
--
RELEASES-DB-FAQS.md-330-
RELEASES-DB-FAQS.md-331-| | releases (GH-32) | roadmap shadow (GH-69) |
RELEASES-DB-FAQS.md-332-|---|---|---|
RELEASES-DB-FAQS.md-333-| Human file | `RELEASES.md` (until the strict flip) | `ROADMAP.md` — **always**; the shadow never writes it |
RELEASES-DB-FAQS.md:334:| Write path | `releases add/update/ship/manifest` | `releases roadmap sync` (parse + mirror; `--dry-run` previews) |
RELEASES-DB-FAQS.md-335-| Keys | `rel-`/`mfi-`/… GIDs | `rmi-` GIDs, stable across edits; entries keyed by GH number |
RELEASES-DB-FAQS.md-336-| Captured | typed release fields | gh_number, title, section, position, status marker, cx/risk/eff, doc link, issue URL — **plus the entry text verbatim** (lossless) |
RELEASES-DB-FAQS.md-337-| Merge story | this whole document | identical — the rows ride the same dump, the same `check --rebuild`, the same resolver, and `validate_merged_dump`'s per-table GID sweep covers them generically |
RELEASES-DB-FAQS.md-338-
--
RELEASES-DB-FAQS.md-388-   Both need `check` (or a separate verb) to make a network call, which it has never done. That is
RELEASES-DB-FAQS.md-389-   a design decision, not a patch; #75 defers it by showing stored state *with its age*.
RELEASES-DB-FAQS.md-390-
RELEASES-DB-FAQS.md-391-Until those land, the honest habit after closing issues or merging a release PR is: `releases next`,
RELEASES-DB-FAQS.md:392:`releases show --version <v>`, `releases roadmap sync` — and read the output.
RELEASES-DB-FAQS.md-393-
RELEASES-DB-FAQS.md-394----
RELEASES-DB-FAQS.md-395-
RELEASES-DB-FAQS.md-396-## Q: What does it mean for a task to be DIALED IN? (GH-111)
--
RELEASES-DB-FAQS.md-513-$R manifest marathon --gid <rel> <issue> --marathon <mar>  # link an existing member
RELEASES-DB-FAQS.md-514-
RELEASES-DB-FAQS.md-515-bash utils/leaderboard.sh          # regenerate LEADERBOARD.md (idempotent; --check for drift)
RELEASES-DB-FAQS.md-516-
RELEASES-DB-FAQS.md:517:utils/releases-merge-resolve.sh   # finish a ledger merge: rebuild, verify, stage (never commits)
RELEASES-DB-FAQS.md-518-```
RELEASES-DB-FAQS.md-519-
RELEASES-DB-FAQS.md-520-A healthy repo prints:
RELEASES-DB-FAQS.md-521-
--
ci-local.sh-1-#!/usr/bin/env bash
ci-local.sh:2:# ci-local.sh — run the tier1 CI job on this machine, step for step.
ci-local.sh-3-#
ci-local.sh-4-# WHY THIS EXISTS: GitHub Actions is metered. Every push burned budget to learn things a laptop can
ci-local.sh-5-# tell you for free, and when the budget ran out `gh pr checks` started reporting `fail` in 2 seconds
ci-local.sh-6-# on every commit — not a test failure, but "the job was not started because recent account payments
--
ci-local.sh-32-# hosted macOS boundary job buys — a clean machine, and evidence not produced by the claimant.
ci-local.sh-33-# ─────────────────────────────────────────────────────────────────────────────────────────────────
ci-local.sh-34-#
ci-local.sh-35-# Usage:
ci-local.sh:36:#   ./ci-local.sh              # every step (~15-20 min; the suite dominates)
ci-local.sh:37:#   ./ci-local.sh --fast       # everything EXCEPT the full validate.sh suite (~1 min)
ci-local.sh:38:#   ./ci-local.sh --base REF   # also run the frozen-twin guard against REF (CI does this on PRs only)
ci-local.sh:39:#   ./ci-local.sh --probe      # GH-509: the UNCONFIGURED-MAC probe (see below)
ci-local.sh-40-#
ci-local.sh-41-# ── --probe: what a new adopter's machine actually looks like (GH-509 / GH-520) ──────────────────
ci-local.sh-42-# Runs with `codex`, `agy` and `aider` stripped from PATH, simulating a Mac where XYZ has just been
ci-local.sh-43-# installed and none of the agent CLIs are set up yet. That is a real audience, not a hypothetical:
--
ci-local.sh-54-# A successful full run writes `.gate-evidence/<sha>.txt`. That answers exactly one question — "has
ci-local.sh-55-# anyone run the whole suite against THIS commit?" — so an agent or operator can tell a verified HEAD
ci-local.sh-56-# from an unverified one without re-running 15 minutes of tests on a hunch.
ci-local.sh-57-#
ci-local.sh:58:# It is deliberately NOT promotion evidence. An earlier draft of the GH-509 plan let a local record
ci-local.sh:59:# qualify a commit for promotion; the agy review called that circular and was right — if a
ci-local.sh-60-# self-reported record satisfies the boundary, the boundary is optional and buys nothing. Promotion
ci-local.sh-61-# needs the hosted macOS run. This record is for the day-to-day question, not the release question.
ci-local.sh-62-#
ci-local.sh-63-# Refused from a dirty tree, and that refusal is the whole integrity story: a record keyed to a
--
ci-local.sh-67-
ci-local.sh-68-HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ci-local.sh-69-cd "$HERE" || exit 1
ci-local.sh-70-
ci-local.sh:71:# ── GH-45: REFUSE to run from a linked git worktree ─────────────────────────────────────────────
ci-local.sh-72-# Same guard, same reason, same override as validate.sh's (kept inline in both rather than a new
ci-local.sh-73-# shared .sh — GH-551; both copies are pinned by test/gh35-test-tiers.sh): this script runs the
ci-local.sh-74-# SAME suite validate.sh does, so running it from a worktree exposes the parent clone's shared
ci-local.sh-75-# .git to exactly the fixture-escape damage validate.sh refuses (2026-08-19 incident, GH-564).
--
ci-local.sh-79-  _wt_common_abs=""
ci-local.sh-80-  [ -n "$_wt_common" ] && _wt_common_abs="$(cd "$_wt_common" 2>/dev/null && pwd -P || true)"
ci-local.sh-81-  if [ -n "$_wt_abs_git" ] && [ -n "$_wt_common_abs" ] && [ "$_wt_abs_git" != "$_wt_common_abs" ]; then
ci-local.sh-82-    cat >&2 <<'WTREFUSE'
ci-local.sh:83:ci-local: REFUSING — this is a linked git worktree, which shares the parent clone's
ci-local.sh-84-  .git (config, refs, objects). The suite this script runs can reach the PARENT clone,
ci-local.sh-85-  not a fixture: an observed run set core.bare=true, repointed origin at a deleted temp
ci-local.sh-86-  path, deleted every refs/remotes/origin/*, and overwrote development with fixture
ci-local.sh:87:  commits. Run the qualifying gate from a normal clone. Override with
ci-local.sh-88-  XYZ_ALLOW_WORKTREE_GATE=1 only if you accept that blast radius.
ci-local.sh-89-WTREFUSE
ci-local.sh-90-    exit 2
ci-local.sh-91-  fi
ci-local.sh-92-else
ci-local.sh:93:  echo "ci-local: XYZ_ALLOW_WORKTREE_GATE=1 — running from a linked worktree at the operator's explicit request; the parent clone's .git is exposed (GH-45)." >&2
ci-local.sh-94-fi
ci-local.sh-95-unset _wt_abs_git _wt_common _wt_common_abs
ci-local.sh-96-
ci-local.sh-97-FAST=0
--
ci-local.sh-102-    --fast) FAST=1; shift ;;
ci-local.sh-103-    --probe) PROBE=1; shift ;;
ci-local.sh-104-    --base) BASE="${2:-}"; shift 2 ;;
ci-local.sh-105-    -h|--help) sed -n '1,60p' "$0"; exit 0 ;;
ci-local.sh:106:    *) echo "ci-local: unknown argument: $1" >&2; exit 2 ;;
ci-local.sh-107-  esac
ci-local.sh-108-done
ci-local.sh-109-
ci-local.sh-110-# GH-509/GH-520 — strip the agent CLIs from PATH for the probe. Done by rebuilding PATH without the
--
ci-local.sh-133-  # for, and the reason GH-520's control aborts on the same check.
ci-local.sh-134-  still=""
ci-local.sh-135-  for c in codex agy aider; do command -v "$c" >/dev/null 2>&1 && still="$still $c"; done
ci-local.sh-136-  if [ -n "$still" ]; then
ci-local.sh:137:    echo "ci-local --probe: ABORT — still on PATH:$still (the probe would be meaningless)" >&2
ci-local.sh-138-    exit 2
ci-local.sh-139-  fi
ci-local.sh-140-  printf '\033[33mmode: --probe (codex/agy/aider stripped from PATH — simulating a fresh Mac)\033[0m\n'
ci-local.sh-141-fi
--
ci-local.sh-143-PASSED=(); FAILED=()
ci-local.sh-144-
ci-local.sh-145-# GH-536: where the suite transcript and per-suite verdicts land, so gate-record.sh can hash the
ci-local.sh-146-# first and embed the second. Per-PID so two concurrent runs on one machine cannot cross-write.
ci-local.sh:147:GATE_SUITE_LOG="${TMPDIR:-/tmp}/ci-local-suite-$$.log"
ci-local.sh:148:GATE_VERDICTS="${TMPDIR:-/tmp}/ci-local-verdicts-$$.txt"
ci-local.sh-149-trap 'rm -f "$GATE_SUITE_LOG" "$GATE_VERDICTS"' EXIT
ci-local.sh-150-step() {  # <name> — everything after is the step body, run in a subshell
ci-local.sh-151-  local name="$1"; shift
ci-local.sh-152-  printf '\n\033[1m=== %s\033[0m\n' "$name"
--
ci-local.sh-300-  return $rc
ci-local.sh-301-}
ci-local.sh-302-
ci-local.sh-303-# ── run ──────────────────────────────────────────────────────────────────────────────────────────
ci-local.sh:304:printf '\033[1mci-local — mirroring .github/workflows/ci.yml tier1\033[0m\n'
ci-local.sh-305-printf 'repo: %s\n' "$HERE"
ci-local.sh-306-printf 'HEAD: %s\n' "$(git log --oneline -1 2>/dev/null)"
ci-local.sh-307-[ "$FAST" -eq 1 ] && printf '\033[33mmode: --fast (full validate.sh suite SKIPPED)\033[0m\n'
ci-local.sh-308-
--
ci-local.sh-317-else
ci-local.sh-318-  printf '\n\033[33mSKIP: frozen twin guard — CI runs it on pull_request only. Pass --base <ref> to run it.\033[0m\n'
ci-local.sh-319-fi
ci-local.sh-320-step "npm ci + acorn-extract"       npm_and_acorn
ci-local.sh:321:# GH-10/GH-1: the qualifying run writes the gate-evidence record, so it carries the same
ci-local.sh-322-# clone-identity bracket validate.sh has — captured BEFORE the suite runs and asserted after,
ci-local.sh-323-# so a suite that escapes its fixture and rewrites this clone's git identity (the GH-564
ci-local.sh-324-# incident) fails THIS run detectably instead of leaving an unattributable green record.
ci-local.sh-325-IDENTITY_SNAPSHOT=""
ci-local.sh-326-if [ "$FAST" -eq 0 ]; then
ci-local.sh:327:  IDENTITY_SNAPSHOT="$(mktemp "${TMPDIR:-/tmp}/ci-local-identity.XXXXXX")"
ci-local.sh-328-  if [ -n "$IDENTITY_SNAPSHOT" ] && bash "$HERE/test/lib/clone-identity.sh" capture "$IDENTITY_SNAPSHOT" "$HERE" 2>/dev/null; then
ci-local.sh-329-    :
ci-local.sh-330-  else
ci-local.sh:331:    echo "ci-local: could not capture clone identity — refusing to run the suite blind (GH-1)" >&2
ci-local.sh-332-    rm -f "$IDENTITY_SNAPSHOT"; IDENTITY_SNAPSHOT=""
ci-local.sh-333-    exit 1
ci-local.sh-334-  fi
ci-local.sh-335-  RELAY_SELF_SUFFICIENCY_SKIP=1 step "validate.sh suite" validate_suite
ci-local.sh-336-  step "clone-identity invariant (GH-1)" ci_local_identity_assert
ci-local.sh-337-fi
ci-local.sh-338-
ci-local.sh-339-# ── report ───────────────────────────────────────────────────────────────────────────────────────
ci-local.sh:340:printf '\n\033[1m─── ci-local summary ───\033[0m\n'
ci-local.sh-341-for s in "${PASSED[@]}"; do printf '  \033[32m+\033[0m %s\n' "$s"; done
ci-local.sh-342-if [ "${#FAILED[@]}" -gt 0 ]; then
ci-local.sh-343-  for s in "${FAILED[@]}"; do printf '  \033[31m-\033[0m %s\n' "$s"; done
ci-local.sh:344:  printf '\n\033[31mci-local: %d step(s) failed\033[0m\n' "${#FAILED[@]}"
ci-local.sh-345-  printf 'This ran on macOS — the platform XYZ ships to — so a failure here is a real defect for\n'
ci-local.sh-346-  printf 'real users. Do not wait for hosted CI to confirm it; the ubuntu job is advisory (GH-509).\n'
ci-local.sh-347-  exit 1
ci-local.sh-348-fi
ci-local.sh:349:printf '\n\033[32mci-local: all steps passed\033[0m\n'
ci-local.sh-350-printf 'Green on the shipping platform, with the full suite — including the one hosted ubuntu skips.\n'
ci-local.sh:351:printf 'NOT a promotion qualification: this run is self-reported. Promotion needs a hosted macOS run\n'
ci-local.sh-352-printf 'for this exact commit (GH-509 §6) — a clean machine, and evidence you did not produce.\n'
ci-local.sh-353-
ci-local.sh-354-# ── GH-509: record that THIS COMMIT was verified here ────────────────────────────────────────────
ci-local.sh-355-# Only a full run earns a record. A --fast or --probe run deliberately does not exercise the suite,
--
validate.sh-12-. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/relay-automation/gate-env.sh"
validate.sh-13-
validate.sh-14-HERE="$(cd "$(dirname "$0")" && pwd)"
validate.sh-15-
validate.sh:16:# ── GH-45: REFUSE to run from a linked git worktree ─────────────────────────────────────────────
validate.sh-17-# A linked worktree shares the parent clone's .git common directory — config, refs, and object
validate.sh-18-# store alike. A suite that escapes its fixture (or resolves one to an empty string) therefore
validate.sh-19-# reaches the PARENT clone, not a sandbox: the observed 2026-08-19 run set core.bare=true,
validate.sh-20-# repointed origin at a deleted temp path, deleted every refs/remotes/origin/*, and overwrote
--
validate.sh-33-    ca="$( cd "$d" 2>/dev/null && cd "$c" 2>/dev/null && pwd -P )" || continue
validate.sh-34-    [ -n "$ca" ] || continue
validate.sh-35-    if [ "$a" != "$ca" ]; then
validate.sh-36-      cat >&2 <<WTREFUSE
validate.sh:37:validate.sh: REFUSING — '$d' is a linked git worktree, which shares the parent clone's
validate.sh-38-  .git (config, refs, objects). Suites that write to 'the repo' reach the PARENT, not a
validate.sh-39-  fixture: an observed run set core.bare=true, repointed origin at a deleted temp path,
validate.sh-40-  deleted every refs/remotes/origin/*, and overwrote development with fixture commits.
validate.sh-41-  Run the gate from a normal clone. Override with XYZ_ALLOW_WORKTREE_GATE=1 only if you
--
validate.sh-199-  "improve-loop.sh"
validate.sh-200-  "improve-loop-qa.sh"
validate.sh-201-  "improve-loop-dogfood.sh"
validate.sh-202-  "gh430-state-dir-tracked-default.sh" # GH-430 (STATE_DIR default is a tracked in-repo path, not ${TMPDIR:-/tmp})
validate.sh:203:  "gh536-evidence-detail.sh"           # GH-536 (the gate-evidence record carries an output hash + per-suite verdicts, so a reader can tell a real run from a stamped one) — 19/0; pins that the NOT-promotion-evidence disclaimer STAYS: a self-computed hash is tamper-evident, not attested
validate.sh:204:  "gh544-parallel-default.sh"          # GH-544 (parallel is the default; every decline to it is ANNOUNCED with a reason) — 29/0; uses --print-mode so it cannot recurse into the gate it belongs to, and pins the two invariants nothing else pins: ci-local.sh never inherits the default, and ci.yml's macOS boundary passes --sequential explicitly
validate.sh-205-  "gh544-pre-push-gate.sh"             # GH-544 (the gate moved to the push boundary; hosted CI fires on nothing) — 78/0; drives githooks/pre-push against a STUB validate.sh so it cannot recurse, and stubs `gh` to pin the one state nothing else can produce: a PR with ZERO configured checks must not read as "checks failed"
validate.sh-206-  "gh35-test-tiers.sh"                 # GH-35 (tiered test selection + CPU governance) — 56/0; pins the registry contract (every registered suite exists AND is in TESTS), the fail-closed tier boundaries, the balanced cores/2 default + --throttle/--burst/env levers, nice -n 10 on the workers, and the tier-1/tier-2 execution paths against fixture clones whose suites are stubs (real runner, real pool, real summary math)
validate.sh-207-  "gh1-fixture-guard.sh"               # GH-1 (shared require_fixture resolved-containment + clone-identity invariant gate; covers the GH-567 lexical-check residual)
validate.sh-208-  "gh1-adoption-guard.sh"             # GH-10 (every fixture-creating suite carries require_fixture adoption — derivation computed from source, exemptions declared in-file; controls prove the guard fires on an unguarded new suite, a stripped adoption, and a removed exemption marker)
--
validate.sh-255-                                 #   merge was mis-resolved. Runs against a COPY (plain `check` writes
validate.sh-256-                                 #   when an intent journal is live) and hashes the clone's artifacts
validate.sh-257-                                 #   before/after to prove it. 10/0; control in
validate.sh-258-                                 #   test/baselines/GH-52-negative-control.md
validate.sh:259:  "gh53-releases-merge-resolve.sh" # #53 (derived-artifact attributes + the one-command ledger merge
validate.sh-260-                                 #   resolution). Pins that releases.db stays -diff +
validate.sh-261-                                 #   linguist-generated and keeps NO merge driver — measured:
validate.sh-262-                                 #   only a driver defined in .git/config auto-merges it, and
validate.sh-263-                                 #   auto-merging is the wrong outcome anyway (it lets a merge finish
--
validate.sh-281-                                 #   through `git merge --continue`, and four edge cases that were REAL defects on
validate.sh-282-                                 #   first run — a failed resolve left the merge half-closed, a rewound generation
validate.sh-283-                                 #   header was accepted silently, releases.db.bak was committable, and `--root ""`
validate.sh-284-                                 #   retargeted the resolver at the current repo. 27/0
validate.sh:285:  "gh69-roadmap-shadow.sh"        # GH-69 (ROADMAP.md shadow: `releases roadmap sync` mirrors the ledger into
validate.sh-286-                                 #   roadmap_items, GH-32 Phase-0 pattern) — 24/0; pins that the shadow never
validate.sh-287-                                 #   writes the markdown, a no-change sync is a NO-OP (no generation bump, no
validate.sh-288-                                 #   dump churn), GIDs are stable across edits, rows ride check --rebuild, and
validate.sh-289-                                 #   a duplicate GH key in the markdown is refused by name
--
validate.sh-399-# `./validate.sh` (no args) runs N-wide, where N is detected from the host. It runs the SAME
validate.sh-400-# TESTS array, with one exception: the suites that execute the REAL relay-automation/relay-drive.sh
validate.sh-401-# contend on this clone's .git/relay-driver.lock (GH-42 exclusion working as designed —
validate.sh-402-# "--target-root moves the build, not the lock", see test/gh331-cost-summary.sh), so those run
validate.sh:403:# sequentially in ONE lane while everything else pools.
validate.sh-404-#
validate.sh:405:# Spike numbers (GH-528, 2026-08-13, M-series macOS): sequential 950.3s → 8-wide 167.4s, byte-identical
validate.sh-406-# pass/fail set. Flipped to the default 2026-08-14 by operator decision (GH-544), because the local
validate.sh-407-# gate is now the ONLY gate during the private phase and a 16-minute one does not get run — it gets
validate.sh-408-# skipped, which is a worse outcome than a 3-minute one.
validate.sh-409-#
--
validate.sh-413-# under `nice -n 10` so interactive use keeps scheduling priority. `--burst` restores the old
validate.sh-414-# full-core width for unattended runs; `--throttle` goes further down to 2 workers. Tiers are
validate.sh-415-# orthogonal to width and never change WHICH tests run — only how many.
validate.sh-416-#
validate.sh:417:# WHAT DID NOT CHANGE, and must not: `ci-local.sh` does NOT call this script. It parses the TESTS
validate.sh:418:# array and runs each suite in its own sequential loop, and it is the path that writes the gate
validate.sh:419:# record. So "sequential is the only form that qualifies a claim" (GH-528 Phase 2, GH-509) is still
validate.sh:420:# true and is still what the record attests. Likewise the macOS promotion boundary in ci.yml pins
validate.sh:421:# `--sequential` explicitly, so a re-armed boundary cannot silently promote on parallel evidence.
validate.sh:422:# Tiers 1 and 2 are pre-push speed, NEVER promotion evidence (GH-35 / GH-509).
validate.sh-423-#
validate.sh-424-# THE FALLBACK IS ANNOUNCED, NEVER SILENT. A gate that quietly downgrades itself teaches you to trust
validate.sh-425-# a number that is not the one you are getting, so every run prints which mode it chose and why.
validate.sh-426-#
--
validate.sh-441-NICE_CMD="nice -n 10"   # GH-35: workers run as a scheduling HINT below interactive use
validate.sh-442-command -v nice >/dev/null 2>&1 || NICE_CMD=""
validate.sh-443-_usage() {
validate.sh-444-  cat >&2 <<'USAGE'
validate.sh:445:usage: ./validate.sh [--parallel N | --sequential | --print-mode]
validate.sh-446-       ./validate.sh [--tier 1|2|3] [--subsystem <name>] [--auto [base[.. head]]] [--paths-file <file>]
validate.sh-447-       ./validate.sh [--throttle|--quiet-cpu] [--burst]
validate.sh-448-
validate.sh-449-  concurrency   --parallel N | --max-parallel N   pin the worker count
validate.sh:450:                --sequential                      one suite at a time (the qualifying form)
validate.sh-451-                --throttle | --quiet-cpu          2 workers under nice — quiet-machine mode (GH-35)
validate.sh-452-                --burst                           full-core width, cores-2 capped 8 — unattended speed
validate.sh-453-  tiers (GH-35) --tier 1|2|3                      1 = docs gate · 2 = subsystem suites · 3 = full (default)
validate.sh-454-                --subsystem <name>                tier 2 for one subsystem (utils/ci-route.sh subsystems)
--
validate.sh-465-    --parallel|--max-parallel)
validate.sh-466-      [ $# -ge 2 ] || _err2 "$1 requires an integer >= 1"
validate.sh-467-      case "$2" in ''|*[!0-9]*) _err2 "$1 requires an integer >= 1" ;; esac
validate.sh-468-      [ "$2" -ge 1 ] || _err2 "$1 requires an integer >= 1"
validate.sh:469:      MODE_FLAGS=$((MODE_FLAGS + 1)); [ "$MODE_FLAGS" -le 1 ] || _err2 "conflicting concurrency flags — pick one of --parallel/--max-parallel/--sequential/--throttle/--burst"
validate.sh-470-      PARALLEL_JOBS="$2"; PARALLEL_WHY="explicit $1 $2"
validate.sh-471-      shift 2 ;;
validate.sh:472:    --sequential)
validate.sh:473:      MODE_FLAGS=$((MODE_FLAGS + 1)); [ "$MODE_FLAGS" -le 1 ] || _err2 "conflicting concurrency flags — pick one of --parallel/--max-parallel/--sequential/--throttle/--burst"
validate.sh:474:      FORCE_SEQUENTIAL=1; PARALLEL_WHY="explicit --sequential"
validate.sh-475-      shift ;;
validate.sh-476-    --throttle|--quiet-cpu)
validate.sh:477:      MODE_FLAGS=$((MODE_FLAGS + 1)); [ "$MODE_FLAGS" -le 1 ] || _err2 "conflicting concurrency flags — pick one of --parallel/--max-parallel/--sequential/--throttle/--burst"
validate.sh-478-      THROTTLE=1; PARALLEL_WHY="explicit $1"
validate.sh-479-      shift ;;
validate.sh-480-    --burst)
validate.sh:481:      MODE_FLAGS=$((MODE_FLAGS + 1)); [ "$MODE_FLAGS" -le 1 ] || _err2 "conflicting concurrency flags — pick one of --parallel/--max-parallel/--sequential/--throttle/--burst"
validate.sh-482-      BURST=1; PARALLEL_WHY="explicit --burst"
validate.sh-483-      shift ;;
validate.sh-484-    --tier)
validate.sh-485-      [ $# -ge 2 ] || _err2 "--tier requires 1, 2, or 3"
--
validate.sh-512-fi
validate.sh-513-
validate.sh-514-# ── GH-35: tier resolution — WHICH tests run, never HOW MANY AT ONCE ────────────────────────────
validate.sh-515-# Tiers select a test SET from the one registry in utils/ci-route.sh; width/nice select a
validate.sh:516:# resource policy. A tier below 3 is a pre-push convenience and is labelled NOT promotion
validate.sh:517:# evidence on every path (GH-509: only ci-local.sh's sequential full run writes a record).
validate.sh-518-T2_TESTS=""      # space-separated suite list for tier 2
validate.sh-519-T2_PDDA=0        # 1 when the classifier says docs were touched too
validate.sh-520-T2_PYTEST=0      # 1 when a *.py path is in play (test_python_layer.py covers utils/py)
validate.sh-521-T2_PATHS=""      # newline list of changed paths (static checks + pytest hint)
--
validate.sh-641-  esac
validate.sh-642-fi
validate.sh-643-
validate.sh-644-# Host detection. Each branch that declines parallelism states its reason, because "it ran
validate.sh:645:# sequentially" and "it ran sequentially BECAUSE this host has two cores" are different facts.
validate.sh-646-_detect_cores() {
validate.sh-647-  if command -v sysctl >/dev/null 2>&1 && sysctl -n hw.ncpu 2>/dev/null; then return 0; fi
validate.sh-648-  if command -v nproc >/dev/null 2>&1 && nproc 2>/dev/null; then return 0; fi
validate.sh-649-  if command -v getconf >/dev/null 2>&1 && getconf _NPROCESSORS_ONLN 2>/dev/null; then return 0; fi
--
validate.sh-652-_cores="$(_detect_cores 2>/dev/null | head -1)"
validate.sh-653-case "$_cores" in ''|*[!0-9]*) _cores=0 ;; esac
validate.sh-654-
validate.sh-655-# Capability first, whatever else was asked: without xargs -P there is no pool at all, and an
validate.sh:656:# explicit --parallel that silently degraded to sequential would be exactly the quiet
validate.sh-657-# substitution GH-544 exists to prevent.
validate.sh-658-if ! printf '' | xargs -P 2 -I{} true >/dev/null 2>&1; then
validate.sh-659-  # Not every xargs implements -P. Falling back is correct; failing here would make the gate
validate.sh:660:  # unrunnable on a host where the sequential path works perfectly well.
validate.sh-661-  FORCE_SEQUENTIAL=1
validate.sh-662-  if [ -n "$PARALLEL_WHY" ]; then PARALLEL_WHY="$PARALLEL_WHY — overridden: this host's xargs does not support -P"
validate.sh-663-  else PARALLEL_WHY="this host's xargs does not support -P"; fi
validate.sh-664-elif [ "$FORCE_SEQUENTIAL" -eq 0 ] && [ -z "$PARALLEL_JOBS" ]; then
--
validate.sh-704-  # for a gate run — both for test/gh544-parallel-default.sh (which must never execute the real
validate.sh-705-  # suite) and for a pre-push hook that wants to tell the operator what it is about to do.
validate.sh-706-  if [ -n "$PARALLEL_JOBS" ]; then
validate.sh-707-    echo "validate.sh: PARALLEL mode ${PARALLEL_JOBS}-wide — $PARALLEL_WHY"
validate.sh:708:    echo "  NOT promotion evidence: the qualifying gate is ci-local.sh's sequential run (GH-509)."
validate.sh-709-  fi
validate.sh-710-  if [ "$TIER" -lt 3 ]; then
validate.sh:711:    echo "validate.sh: tier $TIER — subsystem/docs selection is NEVER promotion evidence (GH-35/GH-509)."
validate.sh-712-  fi
validate.sh-713-  exit 0
validate.sh-714-fi
validate.sh-715-
--
validate.sh-720-if [ "$TIER" -eq 1 ]; then
validate.sh-721-  echo
validate.sh-722-  echo "==============================="
validate.sh-723-  echo "Tier 1 — docs & governance gate (GH-35)"
validate.sh:724:  echo "NOT promotion evidence: the qualifying gate is ci-local.sh's sequential full run (GH-509)."
validate.sh-725-  echo "==============================="
validate.sh-726-  _t1_rc=0
validate.sh-727-  if [ -x "$HERE/utils/pdda/pdda.sh" ]; then
validate.sh-728-    $NICE_CMD bash "$HERE/utils/pdda/pdda.sh" run || _t1_rc=1
--
validate.sh-750-if [ "$TIER" -eq 2 ]; then
validate.sh-751-  echo
validate.sh-752-  echo "==============================="
validate.sh-753-  echo "Tier 2 — subsystem gate (GH-35): $T2_TESTS"
validate.sh:754:  echo "NOT promotion evidence: the qualifying gate is ci-local.sh's sequential full run (GH-509)."
validate.sh-755-  echo "==============================="
validate.sh-756-  RUN_TESTS=()
validate.sh-757-  for t in $T2_TESTS; do
validate.sh-758-    [ -f "$HERE/test/$t" ] || { echo "validate.sh: tier-2 suite test/$t is missing — a gate that cannot run has not passed." >&2; exit 1; }
--
validate.sh-846-  vp_run_one() {  # <suite> — run one suite against its own log; append "rc suite" to the results file
validate.sh-847-    local t="$1" log rc
validate.sh-848-    log="$VALIDATE_LOG_DIR/$(printf '%s' "$t" | tr '/' '_').log"
validate.sh-849-    # GH-15: stdin is /dev/null on EVERY path. The pool's xargs already hands its workers
validate.sh:850:    # /dev/null, but this same function also runs the sequential driver-lock LANE, which would
validate.sh-851-    # otherwise inherit the caller's stdin (an operator's TTY in interactive use) — and any suite
validate.sh-852-    # that reads stdin would behave differently per lane, or hang on a terminal. One stdin regime
validate.sh-853-    # for every suite is what makes the pool/lane/serial-re-run verdicts comparable.
validate.sh-854-    # GH-35: $NICE_CMD (unquoted, a scheduling HINT) keeps workers below interactive priority.
--
validate.sh-860-
validate.sh-861-  # Both lists are derived FROM the run set (all of TESTS on tier 3, the classified subset on
validate.sh-862-  # tier 2), so the two paths run exactly the same set of suites. The lane is an intersection,
validate.sh-863-  # not the literal above: iterating $DRIVER_LOCK_LANE directly would run a lane suite even
validate.sh:864:  # when the run set does not contain it, so `--parallel` could execute suites the sequential
validate.sh-865-  # path skips — and the summary would count more results than TOTAL.
validate.sh-866-  POOL=()
validate.sh-867-  LANE=()
validate.sh-868-  for t in "${RUN_TESTS[@]}"; do
--
validate.sh-872-    esac
validate.sh-873-  done
validate.sh-874-
validate.sh-875-  echo "validate.sh: PARALLEL mode ${PARALLEL_JOBS}-wide — $PARALLEL_WHY"
validate.sh:876:  echo "  ${#POOL[@]} pooled suites + ${#LANE[@]} in the sequential driver-lock lane (GH-528)"
validate.sh:877:  echo "  NOT promotion evidence: the qualifying gate is ci-local.sh's sequential run (GH-509)."
validate.sh-878-  (
validate.sh-879-    for t in ${LANE[@]+"${LANE[@]}"}; do vp_run_one "$t"; done
validate.sh-880-  ) &
validate.sh-881-  LANE_PID=$!
--
validate.sh-889-  # This exists because the lane list above cannot be verified by reading it. A suite that merely
validate.sh-890-  # *touches* a driver contends, and its refusal surfaces as whatever assertion happened to be
validate.sh-891-  # downstream — for gh322 that was a parity mismatch naming two exit codes, which reads exactly like
validate.sh-892-  # a real product bug. Without this pass, an incomplete lane list makes `--parallel` report failures
validate.sh:893:  # that sequential does not have, which would destroy the one property the flag is supposed to have:
validate.sh:894:  # the same answer as the sequential gate, faster. A suite that fails here and passes alone is not
validate.sh-895-  # "flaky" and is not dismissed — it is named as contention on a shared resource (a lane-list gap)
validate.sh-896-  # to fix, and NEVER counted as a failed run (GH-15).
validate.sh-897-  #
validate.sh-898-  # GH-15: two ways this pass was observed NOT honoring that contract, both fixed here.
--
validate.sh-916-    echo "==============================="
validate.sh-917-    if bash "$HERE/test/$t" > "$log.serial" 2>&1 </dev/null; then
validate.sh-918-      PASSED+=("$t")
validate.sh-919-      CONTENDED+=("$t")
validate.sh:920:      echo "  ... PASSES when run alone. Counting it as passed (sequential is the source of truth)."
validate.sh-921-      echo "  ... This means a shared resource is contended — see the warning at the end of this run."
validate.sh-922-    else
validate.sh-923-      FAILED+=("$t")
validate.sh-924-      echo "  ... fails alone too. Real failure; last 40 lines of the SERIAL run:"
--
validate.sh-1025-if [ "$TIER" -eq 3 ]; then TOTAL=$((TOTAL + 1)); fi     # gamma-poison staleness probe
validate.sh-1026-[ "$TIER" -eq 2 ] && [ "$T2_PDDA" -eq 1 ] && TOTAL=$((TOTAL + 1))
validate.sh-1027-[ "$TIER" -eq 2 ] && [ -n "$T2_PATHS" ] && TOTAL=$((TOTAL + 1))
validate.sh-1028-if [ "$TIER" -eq 2 ]; then
validate.sh:1029:  echo "tier 2 run — ${#RUN_TESTS[@]} suite(s). NOT promotion evidence (GH-35/GH-509)."
validate.sh-1030-fi
validate.sh-1031-# GH-15: the verdict must rest on COMPLETE evidence — every suite plus the fixed probes, each
validate.sh-1032-# classified exactly once. A tally that does not add up is an internal error (a swallowed result
validate.sh-1033-# line, a suite classified twice); failing loud here is the difference between that defect being a
     1	name: CI
     2	
     3	# ── READ THIS BEFORE CONCLUDING "CI IS GREEN" (GH-123, 2026-08-21) ──────────────────────────────
     4	#
     5	# Two things about this file have now been re-litigated more than once. Both are recorded here so
     6	# the next person does not rediscover them from scratch.
     7	#
     8	# 1. THE AUTOMATIC TRIGGERS WERE DEAD FROM 2026-08-17 TO 2026-08-21 (GH-59). This is HISTORY, not a
     9	#    live warning — they work now — but it is written down because it silently voided four days of
    10	#    merges and will be misread later if it isn't.
    11	#
    12	#    From the 2026-08-17 re-arm until 17:09 UTC on 2026-08-21, the ENTIRE run history of this
    13	#    repository was `workflow_dispatch` runs. PRs #116, #121 and #122 all merged with ZERO checks.
    14	#    Then, with no change to this file's triggers, both automatic events began firing normally:
    15	#    run 32506672733 (`pull_request`, branch `docs/gh123-ci-canary-codify`) and run 32506697196
    16	#    (`push`, `development`), minutes apart.
    17	#
    18	#    WHY IT STARTED WORKING IS NOT ESTABLISHED. The only honest statement available from a normal
    19	#    token is that it changed between 16:45 and 17:09 UTC on 2026-08-21. If a repository setting was
    20	#    flipped in that window, say so on #59 — the answer is cheap to record now and expensive to
    21	#    reconstruct later. The audit log needs `admin:org`.
    22	#
    23	#    Ruled out during the outage, with evidence, so nobody re-tests them: billing/spending limit (a
    24	#    dispatch on the same branch ran fine — this was the leading theory and it was wrong), workflow
    25	#    disabled (`state=active`), repo is a fork (it is not), Actions disabled (`enabled: true,
    26	#    allowed_actions: all`), the base-branch filter (#116 targeted `development`, which is listed),
    27	#    the workflow missing from the PR head (`d09bdb6` is an ancestor of every branch tested), and
    28	#    fork-PR approval (zero runs ever sat in `action_required`, so nothing was being created).
    29	#
    30	#    A CONFLICTING PR STILL GETS NO RUN, AND THAT IS NORMAL GITHUB BEHAVIOUR — NOT A RELAPSE.
    31	#    `pull_request` workflows are built against the merge ref (`refs/pull/N/merge`), which GitHub
    32	#    does not create while a PR has conflicts, so a conflicted PR shows ZERO checks — visually
    33	#    identical to the outage above. Measured directly on #126: no run for the 9 minutes it was
    34	#    CONFLICTING, then a `pull_request` run within seconds of a rebase clearing it. It is also why
    35	#    #116 got no checks. Before concluding the triggers have broken again, check
    36	#    `gh pr view <n> --json mergeable` — if it says CONFLICTING, rebase and the run appears.
    37	#
    38	#    THE READING RULE THAT OUTLIVES ALL OF THIS: a clean `mergeStateStatus` means "no *failing
    39	#    required* checks", which is also what it says when no checks exist at all. Confirm a run
    40	#    actually exists before treating a green PR page as evidence — `gh pr view <n> --json
    41	#    statusCheckRollup` names the jobs, and an empty array is the tell. To fire this workflow by
    42	#    hand at any time:
    43	#
    44	#        gh workflow run ci.yml --ref <branch>
    45	#        gh run watch <run-id>
    46	#
    47	# 2. AN ADVISORY JOB THAT DIES EARLY STILL REPORTS THE RUN GREEN. The ubuntu canary below is
    48	#    advisory by design ("never breakage") and ends in a verdict step that always passes. That
    49	#    means a FAILING canary is invisible at the run level. It happened: from the 2026-08-17 re-arm
    50	#    until 2026-08-21, `utils/fuzzing/fuzz-loop.sh` had no shebang, shellcheck raised SC2148 at
    51	#    severity=error, the FIRST step of the job exited 1, and every later step — the PDDA gate, the
    52	#    frozen-twin guard, acorn-extract, Fast Gate, validate.sh — silently never ran, for four days,
    53	#    under a green ✓. Fixed in #121 (e9b9b07).
    54	#
    55	#    The lesson is structural, not about that one file: when this job is red, open the JOB and look
    56	#    for steps marked `-`. A short green run is the symptom to distrust. Steps here are ordered
    57	#    cheapest-first, so an early failure hides the most.
    58	#
    59	#    Run 32504570094 (2026-08-21, against 02ce229) is the first end-to-end execution. Baseline:
    60	#    shellcheck / bash+node syntax / settings JSON / PDDA gate / acorn-extract all PASS on Linux;
    61	#    7 assertions across 5 suites fail. Tracked in GH-123 — read it before assuming any of them is
    62	#    environment noise, and see the GH-232 note further down for why that assumption is expensive.
    63	#
    64	#    THIS IS STILL TRUE NOW THAT THE AUTOMATIC TRIGGERS WORK, and that is the point. Runs
    65	#    32506672733 (`pull_request`) and 32506697196 (`push` on `development`) both concluded
    66	#    **success** while this job concluded **failure** on the same 7 assertions. So the trap did not
    67	#    end with the outage in note 1 — restoring the triggers restored a green checkmark on every PR
    68	#    that is reporting a red canary underneath it. Until GH-123 is cleared, treat this job's own
    69	#    conclusion as the signal and the run's conclusion as decoration.
    70	#
    71	# GH-216 cut `development` as the WIP branch that all work targets, but these
    72	# triggers stayed pinned to `main` — so no PR into `development` ran CI at all.
    73	# Both branches are gated here; add any future long-lived integration branch too.
    74	# ── HOSTED CI RE-ARMED FOR THE PUBLIC REPOSITORY (XYZ-forge #16, 2026-08-17) ─────────────────────
    75	#
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
    97	on:
    98	  push:
    99	    branches: [main, development]
   100	  pull_request:
   101	    branches: [main, development]
   102	  workflow_dispatch:
   103	
   104	concurrency:
   105	  # Cancel superseded runs within the same event lane. Keep manual integration runs
   106	  # independent so a branch push cannot cancel an operator-requested full gate.
   107	  group: ${{ github.workflow }}-${{ github.event_name }}-${{ github.event.pull_request.number || github.ref }}
   108	  cancel-in-progress: true
   109	
   110	permissions:
   111	  contents: read
   112	
   113	jobs:
   114	  # GH-509 Phase 4 — THE PROMOTION BOUNDARY. This is the only job whose green means anything about
   115	  # what we ship, because it is the only one running the platform we ship to.
   116	  #
   117	  # WHY IT IS RARE, AND MUST STAY RARE: hosted macOS runners bill at roughly 10x Linux. At the volume
   118	  # this repo generates (37 pushes to `development` in one 24h sample) macOS-everywhere would cost
   119	  # thousands a month. Do NOT add `pull_request` here.
   120	  #
   121	  # WHY `workflow_dispatch` WAS REMOVED (2026-08-13, measured — this was the original design and it
   122	  # did not survive contact with the invoice). The theory was that a dispatch costs "well under a
   123	  # dollar a handful of times a month". The org's actual August usage says otherwise: macOS 3-core
   124	  # 75 minutes = **$4.65 net**, against Ubuntu's 2,740 minutes = $4.44 net. Seventy-five macOS minutes
   125	  # cost more than 2,740 Linux minutes, because macOS bills ~10x AND draws no included-minute discount
   126	  # on a private repo. Three dispatches on one branch in one day consumed roughly half a $10 monthly
   127	  # budget. The gating was correct; what was missing was any brake on how often the deliberate trigger
   128	  # gets pulled — and "deliberate" is not a rate limit when the same person can dispatch it while
   129	  # iterating on the workflow itself.
   130	  #
   131	  # WHAT THIS COSTS US, STATED PLAINLY: the original argument for `workflow_dispatch` was real —
   132	  # work lands on `development` and `main` sees almost nothing, so a main-only boundary arrives AFTER
   133	  # the promotion decision rather than before it. That gap is now open. The substitute is the LOCAL
   134	  # gate on the platform we ship to: `./validate.sh` (and, per GH-528, `--parallel N` for a ~3-minute
   135	  # run) plus `utils/gate-record.sh`, which is self-reported and does NOT qualify a promotion. If a
   136	  # pre-merge macOS witness is needed for a specific commit, re-enable this trigger deliberately,
   137	  # spend the ~$1.25-1.50, and turn it back off — rather than leaving it armed by default.
   138	  #
   139	  # HONEST LIMIT ON "EXACT COMMIT" (retained; applies to any re-enabled dispatch): `workflow_dispatch`
   140	  # targets a REF, not an arbitrary SHA — GitHub resolves the ref's current HEAD. So this job cannot
   141	  # be pointed at an old commit; it qualifies whatever that ref points to when dispatched. The resolved
   142	  # SHA is printed into the job summary for exactly this reason: the promotion rule compares against a
   143	  # recorded SHA, not against "the run I remember starting".
   144	  #
   145	  # NO SKIP LIST, deliberately. It invokes the authoritative validator directly rather than scraping
   146	  # `TESTS` out of it — the scrape can only see `.sh` entries, which is how the 20-test Python layer
   147	  # (the AUTHORITATIVE implementation since GH-264) went unexercised in CI for months. A second list
   148	  # is a second thing to keep honest; there is no second list here.
   149	  boundary-macos:
   150	    name: promotion boundary (macOS — the platform we ship to)
   151	    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
   152	    runs-on: macos-latest
   153	    # A bound, not an estimate. The suite runs ~13-15 min locally; at 10x billing an unbounded hang is
   154	    # the expensive failure mode, so cap it rather than discover the cost afterwards.
   155	    timeout-minutes: 45
   156	    steps:
   157	      - name: Check out repo
   158	        uses: actions/checkout@v4
   159	        with:
   160	          # Same reason as the canary job: fixtures synthesize an "older" ancestor with
   161	          # `git rev-list --max-parents=0 HEAD`, which a shallow clone silently defeats.
   162	          fetch-depth: 0
   163	
   164	      - name: Prepare git environment for fixture-driven tests
   165	        run: |
   166	          set -euo pipefail
   167	          git config --global init.defaultBranch main
   168	          git config --global user.email "ci@runner.invalid"
   169	          git config --global user.name "CI Runner"
   170	
   171	      - name: Install npm dependencies
   172	        run: npm ci
   173	
   174	      # The hosted runner's Python has no pytest, and validate.sh's python lane needs it — the
   175	      # first boundary dispatch (run 31661285957) failed exactly here. Ironic and instructive:
   176	      # GH-509's own headline defect was "the hosted route never ran the 20 python tests"; the
   177	      # first time they ran on hosted macOS, the environment couldn't run them.
   178	      - name: Install pytest for the python lane
   179	        run: python3 -m pip install --quiet --break-system-packages pytest
   180	
     1	---
     2	title: RELEASES DB FAQs — why a committed SQLite ledger still merges, and what triggers what
     3	status: Reference
     4	created: 2026-08-19
     5	updated: 2026-08-19
     6	owner: noelsaw
     7	doc_type: architecture
     8	summary: Answers the recurring questions about the GH-32 SQLite RELEASES ledger — why git can merge it without a SQLite-diffing library, which artifact is authoritative where, what fires each transform (and what does not), and how the git-boundary gaps (#52/#53/#54) were closed.
     9	verified_against:
    10	  - utils/py/releases_app.py
    11	  - test/gh32-releases-app.sh
    12	  - test/gh32-releases-artifacts.sh
    13	  - test/gh53-releases-merge-resolve.sh
    14	  - test/gh54-merged-dump-refusals.sh
    15	  - utils/releases-merge-resolve.sh
    16	  - releases.sql
    17	  - .gitattributes
    18	  - validate.sh
    19	  - .git/hooks/
    20	---
    21	
    22	# RELEASES DB FAQs
    23	
    24	Written 2026-08-19 after answering these from scratch. Everything below was checked against the code
    25	rather than taken from the PRD, and the citations are there so the next reader can re-check rather
    26	than re-derive. Where this file and
    27	[PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md](PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md) disagree,
    28	**the PRD wins** — that is the rule `releases_app.py` states about itself, and it applies here too.
    29	
    30	---
    31	
    32	## Q: Git can't merge binary SQLite files. Do we need `git-sqlite` or something like it to compute the transitions?
    33	
    34	**No.** The DB was never meant to be the merge artifact.
    35	
    36	The authority is split deliberately
    37	([releases_app.py:8-13](utils/py/releases_app.py#L8-L13)):
    38	
    39	| Artifact | Authoritative for |
    40	|---|---|
    41	| `releases.db` | reads and writes **at runtime** |
    42	| `releases.sql` | **git merge boundaries only** |
    43	
    44	Every CLI write regenerates the dump inside the same transaction as the DB write, so the two never
    45	drift outside a crash. At a merge you resolve the **text**, then rebuild the binary from it:
    46	`releases check --rebuild` does dump → DB atomically, keeping a `.bak` of the displaced DB.
    47	
    48	`--rebuild` is for **merge resolution only, never crash recovery.** Crash recovery is a different
    49	mechanism (see below) and conflating them will destroy evidence.
    50	
    51	## Q: Why does a plain text merge work? Concurrent inserts usually collide on primary keys.
    52	
    53	Because the schema was designed so they can't. The dump says so in its own header:
    54	
    55	```
    56	-- releases-app canonical dump (GH-32 grammar: GID-keyed rows, natural keys elsewhere,
    57	-- no integer PKs/FKs as values; rebuild renumbers deterministically)
    58	```
    59	
    60	Two properties do the work:
    61	
    62	1. **Rows are keyed by ULID global IDs**, not by a shared autoincrement counter. Two branches
    63	   inserting at the same moment generate non-colliding keys with no coordination.
    64	2. **No integer primary or foreign key ever appears as a value.** Relationships are carried by GID or
    65	   natural key, so nothing in the text refers to a rowid that rebuild is free to reassign.
    66	
    67	Together those make the union of two dumps a semantically valid merge — no renumbering, no diffing,
    68	no transaction replay. Rebuild assigns fresh integer rowids deterministically on the way in.
    69	
    70	That is exactly the property SQLite-diffing tools have to synthesize after the fact. Here it was
    71	designed in from the start, which is why this is a text-merge problem and not a database problem.
    72	
    73	## Q: What's the actual merge procedure?
    74	
    75	It is tested end-to-end in section J of
    76	[test/gh32-releases-app.sh:300-322](test/gh32-releases-app.sh#L300-L322) — two divergent clones each
    77	import a different 2-release ledger, the dumps are merged, and the test asserts all four releases
    78	survive with both import runs intact.
    79	
    80	The resolution step:
    81	
    82	```bash
    83	{ grep '^-- generation' "$A/releases.sql"
    84	  grep -vh '^-- generation' "$A/releases.sql" "$B/releases.sql" | awk '!seen[$0]++'
    85	} > merged.sql
    86	```
    87	
    88	Keep **one** generation header, union the remaining lines, dedupe. Then:
    89	
    90	```bash
    91	python3 utils/py/releases_app.py check --rebuild   # dump -> DB, atomic, .bak of the old DB
    92	python3 utils/py/releases_app.py check             # must print "check: clean"
    93	```
    94	
    95	Or, since 2026-08-19, one command that does all of it and refuses what it cannot settle:
    96	
    97	```bash
    98	utils/releases-merge-resolve.sh
    99	```
   100	
   101	### Do not use `merge=union` — and not for the reason you'd guess
   102	
   103	Git ships a built-in `union` merge driver that keeps both sides' lines. It looks like precisely the
   104	right tool. **Measured 2026-08-19 against real two-branch merges**, here is what it actually does:
   105	
   106	| Case | Result |
   107	|---|---|
   108	| both branches made the **same number** of writes | merges **cleanly**. One generation header, both sides' rows present, and the `settings` table **not** duplicated — 3 rows, the same as a single-side dump. Both sides emit byte-identical `-- generation: 2` and `settings` lines, so there is nothing to conflict and nothing to double. |
   109	| branches made **different numbers** of writes | **two** generation headers **and** a duplicated `settings` row (4 rows) — silently, with no conflict markers |
   110	
   111	Unequal write counts are the whole problem, and both symptoms share one cause: the two sides'
   112	generation values differ, so the lines carrying them are no longer identical. `check --rebuild` on
   113	such a dump used to die with an unhandled `sqlite3.IntegrityError: UNIQUE constraint failed:
   114	settings.key` — a raw Python traceback rather than a clean refusal. It failed closed (the DB was left
   115	untouched), but it failed ugly. `validate_merged_dump()` now names it instead.
   116	
   117	The equal-write case being genuinely clean is what makes this dangerous: union *looks* fine right up
   118	until the day two branches write a different number of times.
   119	
   120	So the earlier claim in this file — that the header "conflicts by construction on every concurrent
   121	write" and that `check` catches it — was **wrong on both counts**, and is corrected here. The header
   122	often does not conflict at all, and when it duplicates, nothing catches it until the rebuild throws.
   123	`utils/releases-merge-resolve.sh` now refuses a multi-header dump up front, naming the fix. Tracked
   124	as [#54](https://github.com/HiQS-Suite/XYZ-forge/issues/54).
   125	
   126	### The derived artifacts conflict on purpose
   127	
   128	`releases.db` conflicts on every concurrent ledger write. That is
   129	deliberate, and `.gitattributes` records the measurement behind it: `merge=ours` does nothing (`ours`
   130	is a merge *strategy*, not a built-in *driver*), and the only thing that auto-merges it is a driver
   131	defined in `.git/config` — which is not committed, so it would be absent on fresh clones (#4).
   132	
   133	More to the point, auto-resolving is the **wrong outcome**: it lets the merge complete while the DB
   134	still holds only one side's rows, leaving the rebuild easy to forget. The conflict is what stops you
   135	at the moment the decision has to be made. Resolution is `utils/releases-merge-resolve.sh`.
   136	
   137	---
   138	
   139	## Q: What triggers the transforms before, during, and after a git operation?
   140	
   141	**Git triggers nothing.** Every transform is fired by the CLI process. Git is entirely passive — it
   142	sees two files and merges them naively.
   143	
   144	Verified: the only installed hook is `pre-push`, and it contains zero references to releases. There is
   145	no `post-merge`, `post-checkout`, or `post-rewrite` hook. `.gitattributes` exists as of 2026-08-19 but
   146	defines **no merge driver** — it only marks `releases.db` as a derived file, deliberately (see above).
   147	
   148	| Transform | Triggered by | Automatic? |
   149	|---|---|---|
   150	| DB write + dump + generated view | a CLI write command | yes, same transaction |
   151	| Crash recovery from the intent journal | `releases check` | **no** — human runs it |
   152	| Merge resolution (dump → DB) | `releases check --rebuild` | **no** — human runs it |
   153	| Anything at all during `git merge` / `checkout` / `rebase` | — | **nothing fires** |
   154	
   155	### The write protocol
   156	
   157	[`perform_write()`](utils/py/releases_app.py#L780), triggered by a write command (`add`, `update`,
   158	`ship`, `manifest`, `marathon`, `import`, `reconcile`). One transaction, three phases:
   159	
   160	- **Before the DB commit** — write the intent journal: `txn_id`, the **next** generation number, and
   161	  the list of planned output files. It is written first precisely so a crash is recoverable; the
   162	  journal records what was *about* to happen.
   163	- **During** — `BEGIN IMMEDIATE` → mutate → stamp the new generation into `settings` → append an
   164	  `op_receipt` carrying the business-state digest before and after → `COMMIT`.
   165	- **After** — stage the dump and the generated view (each carrying that same generation),
   166	  atomic-rename them into place, clear the journal.
   167	
   168	The **generation number** is the thread tying the artifacts together: stamped into the DB and into
   169	each file's header, so `check` can distinguish a consistent set from a torn one. Five named crash
   170	boundaries are injectable via `RELEASES_APP_CRASH_AT` for testing.
   171	
   172	### Crash recovery is fail-closed
   173	
   174	[`recover_from_journal()`](utils/py/releases_app.py#L867) is called from exactly one place:
   175	`cmd_check` ([line 1969](utils/py/releases_app.py#L1969)).
   176	
   177	It is **not** automatic and **not** run on the next write. A live journal makes the next write
   178	**refuse** ([lines 796-799](utils/py/releases_app.py#L796-L799)) and tell you to run `check`. That is
   179	deliberate: the tool will not quietly write on top of an interrupted transaction.
   180	
   181	## Q: Should we add a git hook that runs before merging?
   182	
   183	**No.** Asked and answered 2026-08-19; the reasoning is recorded here so it doesn't get re-litigated.
   184	
   185	1. **A local hook cannot fire on the merge path this repo actually uses.** Merges here happen through
   186	   `gh pr merge` — server-side on GitHub. No local hook runs at all.
   187	2. **Hooks don't travel with clones.** `.git/hooks/` is not committed. That exact problem is already
   188	   tracked as [#4](https://github.com/HiQS-Suite/XYZ-forge/issues/4). A safety check that is silently
   189	   absent on a fresh clone is worse than no check, because people assume it is running. (Same caveat
   190	   applies to #54's merge driver, since `.git/config` isn't committed either.)
   191	3. **The obvious hook doesn't fire where the risk is.** `pre-merge-commit` is skipped exactly when the
   192	   merge conflicts — the only case that matters here. Per git's documentation, when the merge cannot
   193	   be carried out automatically that hook is not executed; you resolve and commit, and `pre-commit`
   194	   runs instead. Full coverage would need `post-merge` *and* `pre-commit`, and the latter fires on
   195	   every commit.
   196	4. **`--no-verify` bypasses it**, and this repo has a documented instance of that being used to get
   197	   past a spuriously red gate.
   198	
   199	**Use CI + the gate instead.** `.github/workflows/ci.yml` runs `./validate.sh --sequential` on `push`
   200	and `pull_request` for `main` and `development`. So [#52](https://github.com/HiQS-Suite/XYZ-forge/issues/52)
   201	— wiring `releases check` into `validate.sh` — buys enforcement on four surfaces from one committed
   202	change: every PR before merge, every push to `development` after merge, local `pre-push`, and any
   203	local `validate.sh` run. It travels with the clone and catches divergence regardless of how the merge
   204	happened.
   205	
   206	**Why this is less urgent than it sounds:** the server-side path already fails closed. If two branches
   207	both wrote to the ledger, GitHub hits the binary conflict on `releases.db` and **refuses to
   208	auto-merge** rather than producing a divergent state silently. The genuinely risky path is a human
   209	resolving locally and pushing — which `pre-push` and CI both cover.
   210	
   211	An advisory `post-merge` hook that prints "the ledger changed, run `releases check`" is cheap if you
   212	want a nudge, but it is a convenience, not a safety mechanism, and it still won't exist on a fresh
   213	clone.
   214	
   215	---
   216	
   217	## Q: What does the rebuild do if the merged dump is mangled?
   218	
   219	It refuses, by name, before writing anything. The live DB is never touched. Three rules, each
   220	matching damage a real text merge produces:

2026-08-22T00:30:55.271243Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "nl -ba AGENTS.md | sed -n '55,130p;250,312p'; nl -ba ROUTER.md | sed -n '42,92p;120,150p'; nl -ba WORKTREE-SAFETY.md | sed -n '1,42p;300,380p'; nl -ba .github/workflows/ci.yml | sed -n '145,260p'; nl -ba ci-local.sh | sed -n '1,160p'; rg -n -C 2 'releases_app|gh32-releases-artifacts|--sequential|TESTS=' validate.sh" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-54150-qde9l_3o
 succeeded in 0ms:
    55	
    56	### 6. Verified beats plausible
    57	
    58	Do not claim success without the relevant test, script, or observable proof. If verification was
    59	skipped or failed, say that plainly and include the result.
    60	
    61	An uncommitted `provenance.jsonl` is not proof (GH-430). Any run cited as evidence in an issue, PR,
    62	ROADMAP entry, or decision record must have its `provenance.jsonl` committed in the same PR — a path
    63	you merely ran and can no longer show counts as no claim at all.
    64	
    65	### 7. Record only consequential bets
    66	
    67	If a change is Costly, One-way door, or assumption-heavy, record the bet in `CHANGELOG.md` per
    68	`PROJECT/PDDA.md`. Below that threshold, skip the ritual.
    69	
    70	### 8. Stay quiet on trivial work
    71	
    72	Most edits are small and reversible. Do not manufacture ceremony for a rename, typo fix, or other
    73	local change.
    74	
    75	## Repo-specific rails
    76	
    77	- **This repo's purpose is to keep a long-horizon marathon under load — and that is a work-selection
    78	  filter, not a slogan.** The harness is only proven by work long enough, parallel enough, and
    79	  failure-prone enough to tax the whole system: worktree isolation, path claims, the driver lock,
    80	  multi-round handoff, escalation, and resume. Short, single-shot tasks land fine but prove nothing.
    81	  Four rules follow, and they are load-bearing:
    82	
    83	  1. **Exactly one long-horizon marathon is in flight at a time.** When one lands, choosing the next
    84	     is a real decision, not a default. It is named in `ROADMAP.md`'s **Immediate next-up** as the
    85	     marathon, so an agent arriving cold can tell which item is the load and which items are riding
    86	     alongside it.
    87	  2. **Prefer the marathon-shaped candidate.** *Marathon-shaped* means: decomposable into many items
    88	     with an identical transform, a per-item pass condition a machine can check, and a plausible way
    89	     to break the harness. GH-10 (73 unaudited suites, one mechanical adoption each) is the
    90	     archetype. Picking a non-marathon-shaped item over a marathon-shaped one of comparable value
    91	     needs a stated reason — write it in the ledger entry, not in a commit message.
    92	  3. **Only real work.** Never manufacture a marathon to keep the system busy, and never build a
    93	     synthetic workload that cannot damage anything — a run with no blast radius does not surface
    94	     the failures that matter. If nothing genuinely needed is marathon-shaped right now, **the
    95	     correct state is idle**. Say so plainly and do the smaller work; an idle gap is honest signal,
    96	     a fabricated marathon is noise that costs real tokens.
    97	  4. **The point is the failures.** A marathon that completes cleanly and teaches nothing is a
    98	     weaker result than one that escalates and names a defect. Report what broke; do not smooth it.
    99	
   100	- **The RELEASES DB is two subsystems behind one CLI** (`utils/py/releases_app.py`): the GH-32
   101	  release ledger and the GH-69 ROADMAP shadow (`roadmap sync` mirrors `ROADMAP.md`'s ledger into
   102	  `roadmap_items`, one-way and lossless). Never hand-edit `releases.sql` or `releases.db`; after
   103	  editing `ROADMAP.md`'s ledger, run `releases roadmap sync`. Merge conflicts on the dump have a
   104	  one-command resolver (`utils/releases-merge-resolve.sh`). The whole contract, including what a
   105	  real merge conflict looks like: [RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md).
   106	
   107	- **The local gate runs at the push boundary; hosted CI independently attests public-repo changes
   108	  (GH-544, XYZ-forge #16).** The private-phase bridge ended when this repository became public on
   109	  2026-08-15. `.github/workflows/ci.yml` now covers `push`/`pull_request` on `main` and `development`;
   110	  the macOS promotion boundary remains restricted to a push on `main`, while the Ubuntu job is an
   111	  advisory portability canary. Local commits are ungated on purpose; pushes are still gated by
   112	  `githooks/pre-push` so failures are caught before the remote round trip.
   113	  - Wire a new clone once: `bash githooks/install.sh` (idempotent). It installs a dispatch stub into
   114	    `.git/hooks/`, which covers **every branch and linked worktree** of that clone, including branches
   115	    with no `githooks/` directory (GH-549 — the first design wired `core.hooksPath` at the in-tree
   116	    directory, and git skips a hook path that does not resolve *in total silence*). **The wiring is
   117	    still per clone and does not travel** — a fresh clone or second machine has NO gate until this
   118	    runs. Check with `bash githooks/install.sh --check`.
   119	  - `./validate.sh` is **parallel by default** (~4–6 min at the GH-35 balanced width of cores/2 capped 4; `--burst`
   120	  restores the old full-core width), auto-sized to the host, and announces a
   121	    sequential fallback with its reason. `bash ci-local.sh` is still the qualifying run that writes
   122	    the evidence record — it stays sequential and does not call `validate.sh`.
   123	  - Bypasses are `git push --no-verify` and `XYZ_SKIP_PREPUSH=1`. Both announce themselves. Use them
   124	    deliberately, not reflexively — they skip the local boundary even when hosted CI later runs.
   125	  - **PR checks are meaningful again only after a hosted run actually appears for the commit.** A
   126	    configured workflow is not evidence; query the run and cite its SHA.
   127	
   128	- **Never use a git command that overwrites the working tree from a committed state to undo a
   129	  working-tree experiment.** In this clone other agents hold uncommitted work you cannot see.
   130	  Three spellings destroyed peer work three times in one session (GH-527) and the common factor
   250	  a fixture bare repo, a fixture `[user]` identity appended, and `refs/heads/development` reset onto
   251	  ~35 fixture commits. It also **defeated the push gate while corrupting it** — pushes failed with
   252	  `'/var/folders/…/bare.XXXXXX' does not appear to be a git repository` because the suite repointed
   253	  `origin` mid-hook.
   254	  - **The worktree precaution was taken and it FAILED.** Both bursts came from `./validate.sh` run in
   255	    linked worktrees cut off the primary clone, chosen specifically to isolate the risk. **Linked
   256	    worktrees share `.git/config` with the parent clone**, so an escape landing in a worktree's CWD
   257	    writes the parent's config. Reproduced deterministically: from a worktree CWD, `r=""; git -C "$r"
   258	    remote set-url origin "$b"` rewrote the *parent* clone's origin. Same structural fact the
   259	    driver-lock matrix documents from the other side (GH-42/GH-354/GH-448) — a linked worktree
   260	    resolves to the parent's `git-common-dir`, which is why it grants no second lane either.
   261	  - **State the boundary precisely, because the previous rail's version was too narrow.** The rail
   262	    above says worktree isolation does not protect against destructive *git operations*. That is
   263	    true and insufficient: a worktree isolates the **working tree only**. Everything reached through
   264	    `.git` — config, remotes, refs, objects, hooks — is shared with the parent clone, whether it is
   265	    touched deliberately or by an escaped fixture. Only a **separate full clone** isolates any of it.
   266	  - **Why it escapes at all:** `git -C ""` is documented to leave the working directory unchanged and
   267	    `cd ""` is a bash no-op, and these suites run without `set -e` — so one unguarded
   268	    `r="$(mktemp -d …)"` silently redirects every "fixture" operation onto the caller's clone. It
   269	    fires under **parallel** load (the failure mode of `mktemp`), which is why a serial re-run of the
   270	    same suite reproduces nothing and must not be read as an all-clear. GH-177 family.
   271	  - **Until #564's suite-wide invariant gate lands**, treat any clone you ran the suite in as
   272	    suspect: check `git config --get core.bare`, `git remote -v`, `git config --local --get user.email`,
   273	    and `git log --oneline -1` before trusting a push, a fetch, or a green run from it. A guarded
   274	    fixture helper (`require_fixture`: the path must exist AND live under `$WORK` — containment, not
   275	    a null check) is the pattern to copy; `test/gh544-pre-push-gate.sh` has it, 31 other suites do
   276	    not.
   277	  - **Validate a sandbox path at the USE boundary, not where it was created (GH-567).** An empty
   278	    variable does not fail — `git -C ""` uses the current directory, `cd ""` is a no-op,
   279	    `rm -rf "$VAR/"` becomes `/`, `find "$VAR" -delete` becomes `.`. So guard immediately before the
   280	    first dangerous use **in every function that receives the path**, not once at the `mktemp` that
   281	    derived it: a variable that was safe at line 10 can be empty at line 50, and a derivation-site
   282	    check never covers a path passed in from elsewhere. Assert non-empty, a **resolved** descendant
   283	    of the sandbox root, and the expected type — `require_fixture`'s current `case "$p" in "$WORK"/*)`
   284	    is lexical and still accepts `$WORK/../../<real repo>`, so harden it before copying it into the
   285	    other 31. `set -e` is not the containment proof; these suites deliberately run without it.
   286	  - **A clone whose identity changed under a run cannot attribute that run (GH-567).** If a suite
   287	    fails only under parallel load, compare `core.bare`, `git remote -v`, the local user identity and
   288	    `HEAD` against their pre-run values **before** blaming your diff. Unexpected drift invalidates
   289	    every result from that clone — re-clone, then run candidate and base at the same width. Identity
   290	    intact means it is your diff or ordinary flakiness: investigate normally. This is a trigger, not a
   291	    licence to write failures off as harness noise; the 2026-08-15 incident cost several full-suite
   292	    runs to a single green control run treated as proof, which is one sample from a nondeterministic
   293	    process.
   294	- **The local macOS run is the gate; hosted ubuntu is advisory (GH-509).** XYZ is a developer toolkit
   295	  for **macOS**; Linux and Windows are on the roadmap and not here yet. So `./validate.sh` (or
   296	  `./ci-local.sh`) on your Mac is the highest-fidelity evidence available — it is the shipping
   297	  platform with the real toolchain — and it runs a **superset** of the hosted job, including
   298	  `registry-lock-concurrency.sh`, which CI skips for a contended-Linux flake. The hosted `canary-ubuntu`
   299	  job is `continue-on-error: true`: its red means *portability drift*, not breakage, and must not be
   300	  reported as a broken commit. Two consequences that bite: **never defer a test run to CI** — CI is
   301	  advisory and tests the wrong OS; and **a green local run is self-reported**, so it does not qualify a
   302	  promotion. Promotion needs a hosted **macOS** run for that exact commit. When a claim really is about
   303	  Linux, the canary is the right instrument and its red is authoritative.
   304	- **Commit to the QUEUE; re-anchor, don't rabbit-hole (GH-45).** A wave's committed lane list *is* the
   305	  active commitment — after each lane attempt, re-read it before acting further. A driven lane that
   306	  fails **parks** after `LANE_MAX_ATTEMPTS` (default 2): the driver (`marathon-drive.sh` /
   307	  `relay-drive.sh`) refuses to re-fire it (exit 8, no token), you capture the findings as an issue and
   308	  stop. Re-firing a parked lane or going off-wave to deep-dive one item requires an explicit operator
   309	  override (`--force`) or a replan note — never a quiet slide off the plan.
   310	- **Do not create new git branches** automatically. Only create a new branch if explicitly requested by the user. **This governs interactive work only — it is NOT a licence to commit a marathon onto `development`.** The very next bullet is the carve-out: a marathon/relay-fired lane cuts its own `marathon/gh-<n>-*` branch and PRs back into `development`, and that per-lane branch IS the explicitly-requested case. Read 2026-08-15 as permission to skip the branch, which is how four Meter commits landed straight on `development` with no PR (GH-561). The guard now refuses that (`marathon_drive.py`'s branch guard protects `development`, not just `origin/HEAD`), because a rule an agent can talk itself past is not a rule.
   311	- **`development` is the standing WIP branch — ALL work targets it, including marathon/relay-fired lanes (cut fresh from `main` 2026-07-17, [GH-216](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/216); policy widened 2026-07-17 to cover marathon lanes too, first applied to [PR #217](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/217)).** The prior `development` had drifted 295 commits behind `main` with no open PRs — retired to `development-archived-2026-07-04` rather than deleted outright. Both manual/exploratory work AND marathon-fired lanes (`marathon/gh-<n>-*` branches, GH-212 convention) now branch off `development` and PR back into it — `--plan`/`marathon.sh` still cuts its own short-lived per-lane branch, just off `development` instead of `main`. Periodically merge `development` → `main` once it's in a shippable state; don't let `main` sit behind `development` indefinitely. Watch for `development` drifting stale again the same way the old one did; re-cut from `main` if it does.
   312	- **Anti-pattern: renaming a branch with an open PR via GitHub's branch-rename API
    42	
    43	For repo correctness:
    44	
    45	```bash
    46	bash githooks/install.sh        # ONCE PER CLONE — wires the pre-push gate (GH-544)
    47	bash githooks/install.sh --check # is this clone gated? exit 1 if not
    48	./validate.sh              # the gate — PARALLEL by default (GH-544), auto-sized to the host (GH-35)
    49	./validate.sh --print-mode # which mode would this host pick, and why — runs nothing
    50	./validate.sh --sequential # force the sequential run (~16 min)
    51	./validate.sh --tier 2 --subsystem hq   # GH-35: one subsystem's focused suites (pre-push speed, NOT evidence)
    52	./validate.sh --auto       # GH-35: classify the git diff, run the minimal safe tier (fails closed to 3)
    53	./validate.sh --throttle   # GH-35: 2 workers under nice — quiet-machine mode (--burst restores full width)
    54	bash ci-local.sh           # the QUALIFYING run — sequential + writes the gate record (GH-509/GH-536)
    55	```
    56	
    57	**Both gate entry points refuse to run from a linked git worktree (GH-45)** — a worktree shares
    58	the parent clone's `.git`, and an observed suite escape corrupted the parent (core.bare, origin,
    59	remote refs, development). Run the gate from a normal clone; `XYZ_ALLOW_WORKTREE_GATE=1` is the
    60	announced override for disposable runs.
    61	
    62	**Hosted CI fires on nothing while this repo is private (GH-544).** The gate runs locally at the push
    63	boundary instead, so `githooks/install.sh` is part of setting up a clone — the hook lives in
    64	`.git/hooks/`, which does not travel with a clone, and an uninstalled one pushes unverified. One
    65	install covers every branch and every linked worktree of that clone (GH-549). Bypass with
    66	`git push --no-verify` or `XYZ_SKIP_PREPUSH=1`; both announce themselves. Re-arm CI when the repo
    67	goes public (free there).
    68	
    69	**Parallel became the default on 2026-08-14 (GH-544)** because the local gate is the only gate during
    70	the private phase, and a 16-minute gate does not get run — it gets skipped, which is worse than a
    71	3-minute one. **GH-35 (2026-08-18) rebalanced the width to `cores/2` (floor 2, cap 4) and put every
    72	worker under `nice -n 10`** — the original `cores − 2` (up to 8) saturated developer machines badly
    73	enough to wedge the editor; `--burst` buys the old full-core width back for unattended runs, and
    74	`--throttle`/`--quiet-cpu` pins 2 workers. Ambient levers: `XYZ_VALIDATE_THROTTLE=1`,
    75	`XYZ_VALIDATE_MAX_JOBS=N`, `XYZ_VALIDATE_PARALLEL` (flags > MAX_JOBS > THROTTLE > PARALLEL > host
    76	detection; malformed values exit 2 naming the variable). Below 4 cores, or where `xargs -P` is
    77	unsupported, the run **falls back to sequential and says so** — every run prints the mode it chose
    78	and the reason, so a fallback is never silent.
    79	
    80	**GH-35 also added TIERED SELECTION on top, as a separate axis from width.** `utils/ci-route.sh`
    81	owns one fail-closed subsystem registry (hq, releases, telemetry, ate, swe-diagram, pdda,
    82	agent2agent); a push the classifier rates `tier=2` runs only those focused suites at the boundary,
    83	`--tier 1` runs the docs gate, and everything else — unknown paths, test edits, kernel surfaces —
    84	runs the full suite. `--auto` classifies a local diff the same way. Tiers 1 and 2 are pre-push
    85	speed and are labelled NOT promotion evidence; only `ci-local.sh`'s sequential full run qualifies
    86	(GH-509).
    87	
    88	**What still qualifies a claim is unchanged.** `./validate.sh` in either mode is a self-check;
    89	`ci-local.sh` is the run that writes the evidence record, it does **not** call `validate.sh`, and it
    90	stays sequential. The macOS promotion boundary in `ci.yml` pins `--sequential` explicitly for the same
    91	reason. GH-528 Phase 2 (multi-width stress evidence) is still **owed** — the flip was an operator
    92	decision taken with that evidence outstanding, mitigated by the announced fallback rather than
   120	
   121	## The RELEASES DB — two subsystems, one ledger (GH-32 / GH-69)
   122	
   123	`releases.db` + `releases.sql` hold TWO mirrored subsystems, both operated through ONE CLI,
   124	`utils/py/releases_app.py` (alias: the `/releases` skill). Read
   125	[RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md) before merging either file — the SQLite binary is
   126	derived; the SQL dump is what git actually merges, and a conflicted merge has a one-command
   127	resolver (`utils/releases-merge-resolve.sh`).
   128	
   129	```bash
   130	python3 utils/py/releases_app.py check          # trio consistency, receipt chain, crash recovery
   131	python3 utils/py/releases_app.py next           # the next unshipped release, by target date
   132	python3 utils/py/releases_app.py add|ship ...   # RELEASE writes — never hand-edit releases.sql
   133	python3 utils/py/releases_app.py roadmap sync   # GH-69: mirror ROADMAP.md's ledger into roadmap_items
   134	python3 utils/py/releases_app.py roadmap list   # read the shadow rows
   135	```
   136	
   137	**Subsystem 1 — releases** (GH-32, Phase 0 side-by-side): the release ledger. App-managed writes
   138	only; `RELEASES.md` is still the human file during the shadow phase.
   139	**Subsystem 2 — the ROADMAP shadow** (GH-69, same pattern): `ROADMAP.md` stays the ONLY thing
   140	anyone edits; `roadmap sync` mirrors its ledger into the DB, losslessly, one-way. After editing
   141	`ROADMAP.md`'s ledger, run the sync — a no-change sync is a free no-op. Pinned by
   142	`test/gh69-roadmap-shadow.sh`.
   143	
   144	## Routing hints
   145	
   146	- If the task is about current priorities or active work, start in `ROADMAP.md`, then follow the linked `PROJECT/**` doc.
   147	- If the task edits `ROADMAP.md`'s ledger, finish with `python3 utils/py/releases_app.py roadmap sync` (GH-69 shadow — see the RELEASES DB section above).
   148	- If the task touches `releases.db`, `releases.sql`, or a merge conflict on either, start in [RELEASES-DB-FAQS.md](RELEASES-DB-FAQS.md); writes go through the CLI, never a hand-edit.
   149	- If the task is about fresh GitHub intake or duplicate-prevention, start in `ROADMAP.md`'s queue, then follow the linked `PROJECT/1-INBOX/GH-*.md` capture doc.
   150	- If the task is about document quality, active-doc lifecycle, roadmap sprawl, or automation policy, start in `PROJECT/PDDA.md`.
     1	# Git Worktree Safety Guide for Agents
     2	
     3	Author: Noel Saw (@noelsaw1)  
     4	Licensed under: Apache 2.0  
     5	Copyright 2026 Neochrome, Inc.  
     6	
     7	> **Purpose:** Prevent destructive footguns when scripting with Git worktrees.  
     8	> **Scope:** Shell scripts, CI pipelines, and agent workflows that create, manage, or clean up worktrees.
     9	
    10	---
    11	
    12	## 1. The "rm -rf worktree path" trap
    13	
    14	**Anti-pattern:** Deleting a worktree by just removing its directory.
    15	
    16	```bash
    17	# WRONG — leaves stale metadata in .git/worktrees/
    18	rm -rf ../feature-branch
    19	
    20	# Also WRONG — git still thinks the worktree exists
    21	git worktree remove ../feature-branch  # fails: "not a working tree"
    22	```
    23	
    24	**Why it's dangerous:** Git maintains metadata in `.git/worktrees/<name>/` and in a `.git` file inside the worktree. If you `rm -rf` the directory, you get:
    25	- Orphaned metadata polluting your repo
    26	- The branch may still be checked out according to git, blocking operations
    27	- `.git/worktrees/<name>/index` can grow large and never gets cleaned
    28	
    29	**Correct approach:**
    30	```bash
    31	# Always use git worktree remove
    32	git worktree remove ../feature-branch
    33	
    34	# If the directory is already gone, let git reconcile its own metadata —
    35	# don't hand-delete .git/worktrees/<name> yourself:
    36	git worktree prune
    37	
    38	# If the worktree still exists but was moved/relinked and git can't find it,
    39	# `repair` (Git 2.29+) is the documented fix, not manual surgery on .git/worktrees/:
    40	git worktree repair ../feature-branch
    41	```
    42	Manual `rm -rf .git/worktrees/<name>` is a last resort for a clearly corrupt admin
   300	way from every worktree. Use unmistakable `-m` messages, and run `git stash list` in the worktree
   301	you're about to pop into (not the one you pushed from) to confirm which entry is `stash@{0}` before
   302	popping.
   303	
   304	---
   305	
   306	## 11. Selective `.git` corruption & skeleton loss (the GH-177 scenario)
   307	
   308	**What actually happened here (2026-07-07):** this repo's main `.git` directory lost `HEAD`,
   309	`objects/`, `refs/`, and `index`, while `hooks/`, `worktrees/`, and `config` survived intact. This
   310	is **not** the "someone ran `rm -rf .git`" scenario in §7 above — that deletes everything uniformly.
   311	This was a *partial* loss (consistent with a selective backup/restore gap), and none of the 10
   312	anti-patterns above describe it or would have helped diagnose it.
   313	
   314	**Detection — verify before trusting a repo:**
   315	```bash
   316	# A healthy repo has ALL of these. Any missing = don't trust git commands here yet.
   317	for f in HEAD objects refs config; do
   318	    [ -e ".git/$f" ] || echo "MISSING: .git/$f"
   319	done
   320	git fsck --no-progress 2>&1 | head -5   # first real integrity check once the above pass
   321	```
   322	Also check `.git/worktrees/*/gitdir` stubs for staleness — a stub with no valid path behind it (or
   323	just a bare `commondir` file and nothing else) is metadata cruft from the same class of incident,
   324	not a real linked worktree; `git worktree prune` clears it once the main repo is healthy again.
   325	
   326	**Recovery — in order, verifying before each destructive-looking step:**
   327	```bash
   328	# 1. git init is DOCUMENTED SAFE to re-run on an existing repo: it only fills in
   329	#    missing standard files (HEAD, objects/, refs/, description, info/exclude,
   330	#    sample hooks) and does NOT overwrite an existing config, hooks, or any
   331	#    working-tree file.
   332	git init
   333	
   334	# 2. Repopulate history from the remote — additive only, does not touch the
   335	#    working tree or local branch refs.
   336	git fetch origin
   337	
   338	# 3. Before pointing any local ref at origin, or touching the working tree,
   339	#    build an index from the candidate branch WITHOUT checkout (read-tree does
   340	#    not write to the working tree) and diff it against what's on disk:
   341	git read-tree origin/main
   342	git status   # compare — do NOT `checkout -f` / `reset --hard` / `clean` yet
   343	
   344	# 4. Only once you've confirmed the working tree matches (or you've decided
   345	#    what to do about genuine local divergence), point the branch ref at the
   346	#    remote — this only writes a ref, still doesn't touch the working tree:
   347	git update-ref refs/heads/main origin/main
   348	
   349	# 5. Restore any tracked files that are genuinely missing/corrupted on disk
   350	#    (confirmed absent or differing from origin, not local WIP) from the
   351	#    remote's tree — scoped to just those paths, not a blanket checkout:
   352	git checkout origin/main -- path/to/missing-file
   353	```
   354	The critical discipline: steps 1–3 are provably non-destructive to the working tree (`init` fills
   355	gaps only, `fetch` writes only to `.git/objects` and remote-tracking refs, `read-tree` populates the
   356	index without touching files). Do not reach for `checkout -f`, `reset --hard`, or `clean` until
   357	you've diffed and know exactly what you'd be overwriting — those commands assume the working tree is
   358	disposable, which after a partial-corruption incident it specifically is not.
   359	
   360	---
   361	
   362	## 12. Never run the full test gate from a linked worktree (the 2026-08-19 incident)
   363	
   364	**Anti-pattern:** treating a linked worktree as an isolated place to verify a branch.
   365	
   366	```bash
   367	git worktree add ../repo-feature -b feature origin/development
   368	cd ../repo-feature
   369	bash validate.sh          # WRONG — this can corrupt the PARENT clone
   370	```
   371	
   372	**Why it's dangerous:** a linked worktree **shares the parent's `.git` common directory** — config,
   373	refs, and object store alike (§5, §10). A suite that manipulates "the repo" rather than a fixture
   374	therefore reaches the *real* repository. Observed on 2026-08-19, from one `validate.sh` run in a
   375	worktree:
   376	
   377	- `core.bare` set to **true** on the parent clone, after which `git rev-parse --show-toplevel` fails
   378	  with `this operation must be run in a work tree` and `git worktree list` reports the main clone as
   379	  `(bare)`
   380	- `remote.origin.url` repointed to a fixture's temp bare repo, which was then deleted — leaving
   145	  # NO SKIP LIST, deliberately. It invokes the authoritative validator directly rather than scraping
   146	  # `TESTS` out of it — the scrape can only see `.sh` entries, which is how the 20-test Python layer
   147	  # (the AUTHORITATIVE implementation since GH-264) went unexercised in CI for months. A second list
   148	  # is a second thing to keep honest; there is no second list here.
   149	  boundary-macos:
   150	    name: promotion boundary (macOS — the platform we ship to)
   151	    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
   152	    runs-on: macos-latest
   153	    # A bound, not an estimate. The suite runs ~13-15 min locally; at 10x billing an unbounded hang is
   154	    # the expensive failure mode, so cap it rather than discover the cost afterwards.
   155	    timeout-minutes: 45
   156	    steps:
   157	      - name: Check out repo
   158	        uses: actions/checkout@v4
   159	        with:
   160	          # Same reason as the canary job: fixtures synthesize an "older" ancestor with
   161	          # `git rev-list --max-parents=0 HEAD`, which a shallow clone silently defeats.
   162	          fetch-depth: 0
   163	
   164	      - name: Prepare git environment for fixture-driven tests
   165	        run: |
   166	          set -euo pipefail
   167	          git config --global init.defaultBranch main
   168	          git config --global user.email "ci@runner.invalid"
   169	          git config --global user.name "CI Runner"
   170	
   171	      - name: Install npm dependencies
   172	        run: npm ci
   173	
   174	      # The hosted runner's Python has no pytest, and validate.sh's python lane needs it — the
   175	      # first boundary dispatch (run 31661285957) failed exactly here. Ironic and instructive:
   176	      # GH-509's own headline defect was "the hosted route never ran the 20 python tests"; the
   177	      # first time they ran on hosted macOS, the environment couldn't run them.
   178	      - name: Install pytest for the python lane
   179	        run: python3 -m pip install --quiet --break-system-packages pytest
   180	
   181	      - name: Run the authoritative validator (no skips)
   182	        env:
   183	          # The one documented exclusion, and it is not a coverage skip: this test makes a real
   184	          # billed API call to a live agent. It self-skips off-PATH anyway; the env var makes the
   185	          # intent explicit rather than incidental.
   186	          RELAY_SELF_SUFFICIENCY_SKIP: "1"
   187	        # `--sequential` is PINNED here and must stay pinned. GH-544 made parallel the default for the
   188	        # local gate, which is correct there — but this job is the promotion boundary, and the whole
   189	        # point of it is that its green means something the local run's cannot. Promotion evidence
   190	        # stays sequential (GH-528 Phase 2 has not been met), so the flag is explicit rather than
   191	        # inherited: a future change to validate.sh's default must not be able to silently change what
   192	        # this job attests. test/ci-workflow.sh asserts the flag is present.
   193	        run: ./validate.sh --sequential
   194	
   195	      - name: Promotion evidence
   196	        if: always()
   197	        run: |
   198	          set -euo pipefail
   199	          if [ "${{ job.status }}" = "success" ]; then
   200	            line="MACOS-BOUNDARY: green ${GITHUB_SHA}"
   201	            note="This commit is promotion-qualified (GH-509 §6). Cite this SHA, not this run."
   202	          else
   203	            line="MACOS-BOUNDARY: red ${GITHUB_SHA}"
   204	            note="NOT promotable. Unlike the ubuntu canary, this ran on the platform we ship to — a failure here is a real defect for real users."
   205	          fi
   206	          echo "$line"
   207	          echo "$note"
   208	          { echo "### $line"; echo; echo "$note"; } >> "$GITHUB_STEP_SUMMARY"
   209	
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
   235	    runs-on: ubuntu-latest
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
    71	# ── GH-45: REFUSE to run from a linked git worktree ─────────────────────────────────────────────
    72	# Same guard, same reason, same override as validate.sh's (kept inline in both rather than a new
    73	# shared .sh — GH-551; both copies are pinned by test/gh35-test-tiers.sh): this script runs the
    74	# SAME suite validate.sh does, so running it from a worktree exposes the parent clone's shared
    75	# .git to exactly the fixture-escape damage validate.sh refuses (2026-08-19 incident, GH-564).
    76	if [ "${XYZ_ALLOW_WORKTREE_GATE:-0}" != "1" ]; then
    77	  _wt_abs_git="$(git rev-parse --absolute-git-dir 2>/dev/null || true)"
    78	  _wt_common="$(git rev-parse --git-common-dir 2>/dev/null || true)"
    79	  _wt_common_abs=""
    80	  [ -n "$_wt_common" ] && _wt_common_abs="$(cd "$_wt_common" 2>/dev/null && pwd -P || true)"
    81	  if [ -n "$_wt_abs_git" ] && [ -n "$_wt_common_abs" ] && [ "$_wt_abs_git" != "$_wt_common_abs" ]; then
    82	    cat >&2 <<'WTREFUSE'
    83	ci-local: REFUSING — this is a linked git worktree, which shares the parent clone's
    84	  .git (config, refs, objects). The suite this script runs can reach the PARENT clone,
    85	  not a fixture: an observed run set core.bare=true, repointed origin at a deleted temp
    86	  path, deleted every refs/remotes/origin/*, and overwrote development with fixture
    87	  commits. Run the qualifying gate from a normal clone. Override with
    88	  XYZ_ALLOW_WORKTREE_GATE=1 only if you accept that blast radius.
    89	WTREFUSE
    90	    exit 2
    91	  fi
    92	else
    93	  echo "ci-local: XYZ_ALLOW_WORKTREE_GATE=1 — running from a linked worktree at the operator's explicit request; the parent clone's .git is exposed (GH-45)." >&2
    94	fi
    95	unset _wt_abs_git _wt_common _wt_common_abs
    96	
    97	FAST=0
    98	BASE=""
    99	PROBE=0
   100	while (($#)); do
   101	  case "$1" in
   102	    --fast) FAST=1; shift ;;
   103	    --probe) PROBE=1; shift ;;
   104	    --base) BASE="${2:-}"; shift 2 ;;
   105	    -h|--help) sed -n '1,60p' "$0"; exit 0 ;;
   106	    *) echo "ci-local: unknown argument: $1" >&2; exit 2 ;;
   107	  esac
   108	done
   109	
   110	# GH-509/GH-520 — strip the agent CLIs from PATH for the probe. Done by rebuilding PATH without the
   111	# directories that hold them, rather than by unsetting *_BIN vars: the failure being reproduced is a
   112	# binary that is not on PATH at all, and a shim that falls back to a PATH lookup would defeat a
   113	# variable-only approach.
   114	if [ "$PROBE" -eq 1 ]; then
   115	  probe_dirs=""
   116	  for c in codex agy aider; do
   117	    p="$(command -v "$c" 2>/dev/null || true)"
   118	    [ -n "$p" ] && probe_dirs="$probe_dirs $(dirname "$p")"
   119	  done
   120	  if [ -n "$probe_dirs" ]; then
   121	    new_path=""
   122	    while IFS= read -r d; do
   123	      [ -n "$d" ] || continue
   124	      skip=0
   125	      for pd in $probe_dirs; do [ "$d" = "$pd" ] && { skip=1; break; }; done
   126	      [ "$skip" -eq 1 ] && continue
   127	      new_path="${new_path:+$new_path:}$d"
   128	    done < <(printf '%s\n' "${PATH//:/$'\n'}")
   129	    PATH="$new_path"; export PATH
   130	  fi
   131	  # Assert the condition rather than assume it. A probe that silently ran with the binaries still
   132	  # present would report green and mean nothing — the exact shape of failure this repo keeps paying
   133	  # for, and the reason GH-520's control aborts on the same check.
   134	  still=""
   135	  for c in codex agy aider; do command -v "$c" >/dev/null 2>&1 && still="$still $c"; done
   136	  if [ -n "$still" ]; then
   137	    echo "ci-local --probe: ABORT — still on PATH:$still (the probe would be meaningless)" >&2
   138	    exit 2
   139	  fi
   140	  printf '\033[33mmode: --probe (codex/agy/aider stripped from PATH — simulating a fresh Mac)\033[0m\n'
   141	fi
   142	
   143	PASSED=(); FAILED=()
   144	
   145	# GH-536: where the suite transcript and per-suite verdicts land, so gate-record.sh can hash the
   146	# first and embed the second. Per-PID so two concurrent runs on one machine cannot cross-write.
   147	GATE_SUITE_LOG="${TMPDIR:-/tmp}/ci-local-suite-$$.log"
   148	GATE_VERDICTS="${TMPDIR:-/tmp}/ci-local-verdicts-$$.txt"
   149	trap 'rm -f "$GATE_SUITE_LOG" "$GATE_VERDICTS"' EXIT
   150	step() {  # <name> — everything after is the step body, run in a subshell
   151	  local name="$1"; shift
   152	  printf '\n\033[1m=== %s\033[0m\n' "$name"
   153	  if "$@"; then PASSED+=("$name"); else FAILED+=("$name"); printf '\033[31mFAILED: %s\033[0m\n' "$name" >&2; fi
   154	}
   155	
   156	# ── 1. prerequisites ─────────────────────────────────────────────────────────────────────────────
   157	# CI apt-installs shellcheck; locally it is the operator's to provide. Checked up front so the run
   158	# does not get 15 minutes in before discovering a missing binary.
   159	check_prereqs() {
   160	  local missing=0 c
53-fi
54-
55:TESTS=(
56-  "projection-idempotent.sh"
57-  "concurrent-claim.sh"
--
202-  "gh430-state-dir-tracked-default.sh" # GH-430 (STATE_DIR default is a tracked in-repo path, not ${TMPDIR:-/tmp})
203-  "gh536-evidence-detail.sh"           # GH-536 (the gate-evidence record carries an output hash + per-suite verdicts, so a reader can tell a real run from a stamped one) — 19/0; pins that the NOT-promotion-evidence disclaimer STAYS: a self-computed hash is tamper-evident, not attested
204:  "gh544-parallel-default.sh"          # GH-544 (parallel is the default; every decline to it is ANNOUNCED with a reason) — 29/0; uses --print-mode so it cannot recurse into the gate it belongs to, and pins the two invariants nothing else pins: ci-local.sh never inherits the default, and ci.yml's macOS boundary passes --sequential explicitly
205-  "gh544-pre-push-gate.sh"             # GH-544 (the gate moved to the push boundary; hosted CI fires on nothing) — 78/0; drives githooks/pre-push against a STUB validate.sh so it cannot recurse, and stubs `gh` to pin the one state nothing else can produce: a PR with ZERO configured checks must not read as "checks failed"
206-  "gh35-test-tiers.sh"                 # GH-35 (tiered test selection + CPU governance) — 56/0; pins the registry contract (every registered suite exists AND is in TESTS), the fail-closed tier boundaries, the balanced cores/2 default + --throttle/--burst/env levers, nice -n 10 on the workers, and the tier-1/tier-2 execution paths against fixture clones whose suites are stubs (real runner, real pool, real summary math)
--
243-                                 #   writer-lock + journal protocol, canonical dump, receipt chain,
244-                                 #   import grandfathering, side-by-side gen) — 81/0; registered in the
245:                                 #   same commit as utils/py/releases_app.py per the lesson above. The
246-                                 #   four check-failure negative controls, the five crash boundaries,
247-                                 #   and the refused-writer-changes-nothing control are the point; the
248-                                 #   revert-and-replay transcript is test/baselines/GH-32-negative-control.md
249:  "gh32-releases-artifacts.sh"   # #52 (the COMMITTED releases.db/releases.sql pair actually agrees —
250-                                 #   gh32-releases-app.sh only proves the CLI works in fixtures). The
251-                                 #   documented merge procedure has a human step (`check --rebuild`);
--
419-# record. So "sequential is the only form that qualifies a claim" (GH-528 Phase 2, GH-509) is still
420-# true and is still what the record attests. Likewise the macOS promotion boundary in ci.yml pins
421:# `--sequential` explicitly, so a re-armed boundary cannot silently promote on parallel evidence.
422-# Tiers 1 and 2 are pre-push speed, NEVER promotion evidence (GH-35 / GH-509).
423-#
--
443-_usage() {
444-  cat >&2 <<'USAGE'
445:usage: ./validate.sh [--parallel N | --sequential | --print-mode]
446-       ./validate.sh [--tier 1|2|3] [--subsystem <name>] [--auto [base[.. head]]] [--paths-file <file>]
447-       ./validate.sh [--throttle|--quiet-cpu] [--burst]
448-
449-  concurrency   --parallel N | --max-parallel N   pin the worker count
450:                --sequential                      one suite at a time (the qualifying form)
451-                --throttle | --quiet-cpu          2 workers under nice — quiet-machine mode (GH-35)
452-                --burst                           full-core width, cores-2 capped 8 — unattended speed
--
467-      case "$2" in ''|*[!0-9]*) _err2 "$1 requires an integer >= 1" ;; esac
468-      [ "$2" -ge 1 ] || _err2 "$1 requires an integer >= 1"
469:      MODE_FLAGS=$((MODE_FLAGS + 1)); [ "$MODE_FLAGS" -le 1 ] || _err2 "conflicting concurrency flags — pick one of --parallel/--max-parallel/--sequential/--throttle/--burst"
470-      PARALLEL_JOBS="$2"; PARALLEL_WHY="explicit $1 $2"
471-      shift 2 ;;
472:    --sequential)
473:      MODE_FLAGS=$((MODE_FLAGS + 1)); [ "$MODE_FLAGS" -le 1 ] || _err2 "conflicting concurrency flags — pick one of --parallel/--max-parallel/--sequential/--throttle/--burst"
474:      FORCE_SEQUENTIAL=1; PARALLEL_WHY="explicit --sequential"
475-      shift ;;
476-    --throttle|--quiet-cpu)
477:      MODE_FLAGS=$((MODE_FLAGS + 1)); [ "$MODE_FLAGS" -le 1 ] || _err2 "conflicting concurrency flags — pick one of --parallel/--max-parallel/--sequential/--throttle/--burst"
478-      THROTTLE=1; PARALLEL_WHY="explicit $1"
479-      shift ;;
480-    --burst)
481:      MODE_FLAGS=$((MODE_FLAGS + 1)); [ "$MODE_FLAGS" -le 1 ] || _err2 "conflicting concurrency flags — pick one of --parallel/--max-parallel/--sequential/--throttle/--burst"
482-      BURST=1; PARALLEL_WHY="explicit --burst"
483-      shift ;;
--
516-# resource policy. A tier below 3 is a pre-push convenience and is labelled NOT promotion
517-# evidence on every path (GH-509: only ci-local.sh's sequential full run writes a record).
518:T2_TESTS=""      # space-separated suite list for tier 2
519-T2_PDDA=0        # 1 when the classifier says docs were touched too
520-T2_PYTEST=0      # 1 when a *.py path is in play (test_python_layer.py covers utils/py)
--
537-  case "$t" in
538-    1) TIER=1 ;;
539:    2) TIER=2; T2_TESTS="${tests//,/ }" ;;
540-    *) TIER=3 ;;
541-  esac
--
601-
602-if [ -n "$SUBSYSTEM" ]; then
603:  T2_TESTS="$(bash "$HERE/utils/ci-route.sh" subsystems "$SUBSYSTEM" 2>/dev/null)" \
604-    || _err2 "unknown subsystem '$SUBSYSTEM' (utils/ci-route.sh subsystems lists them)"
605-  [ -n "$T2_TESTS" ] || _err2 "subsystem '$SUBSYSTEM' resolved to no suites — refusing a zero-test gate"
--
747-# identity bracket, same summary invariant — only the test SET changes (and it comes from the
748-# same registry the push hook uses, so the two cannot disagree about what "hq" covers).
749:RUN_TESTS=("${TESTS[@]}")
750-if [ "$TIER" -eq 2 ]; then
751-  echo
--
754-  echo "NOT promotion evidence: the qualifying gate is ci-local.sh's sequential full run (GH-509)."
755-  echo "==============================="
756:  RUN_TESTS=()
757-  for t in $T2_TESTS; do
758-    [ -f "$HERE/test/$t" ] || { echo "validate.sh: tier-2 suite test/$t is missing — a gate that cannot run has not passed." >&2; exit 1; }

2026-08-22T00:31:09.908346Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "nl -ba .github/workflows/ci.yml | sed -n '97,152p;180,240p;300,365p'; nl -ba validate.sh | sed -n '240,265p;405,425p;735,785p'; nl -ba WORKTREE-SAFETY.md | sed -n '300,390p'; nl -ba RELEASES-DB-FAQS.md | sed -n '32,49p;73,99p;126,153p;199,210p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-54150-qde9l_3o
 succeeded in 0ms:
    97	on:
    98	  push:
    99	    branches: [main, development]
   100	  pull_request:
   101	    branches: [main, development]
   102	  workflow_dispatch:
   103	
   104	concurrency:
   105	  # Cancel superseded runs within the same event lane. Keep manual integration runs
   106	  # independent so a branch push cannot cancel an operator-requested full gate.
   107	  group: ${{ github.workflow }}-${{ github.event_name }}-${{ github.event.pull_request.number || github.ref }}
   108	  cancel-in-progress: true
   109	
   110	permissions:
   111	  contents: read
   112	
   113	jobs:
   114	  # GH-509 Phase 4 — THE PROMOTION BOUNDARY. This is the only job whose green means anything about
   115	  # what we ship, because it is the only one running the platform we ship to.
   116	  #
   117	  # WHY IT IS RARE, AND MUST STAY RARE: hosted macOS runners bill at roughly 10x Linux. At the volume
   118	  # this repo generates (37 pushes to `development` in one 24h sample) macOS-everywhere would cost
   119	  # thousands a month. Do NOT add `pull_request` here.
   120	  #
   121	  # WHY `workflow_dispatch` WAS REMOVED (2026-08-13, measured — this was the original design and it
   122	  # did not survive contact with the invoice). The theory was that a dispatch costs "well under a
   123	  # dollar a handful of times a month". The org's actual August usage says otherwise: macOS 3-core
   124	  # 75 minutes = **$4.65 net**, against Ubuntu's 2,740 minutes = $4.44 net. Seventy-five macOS minutes
   125	  # cost more than 2,740 Linux minutes, because macOS bills ~10x AND draws no included-minute discount
   126	  # on a private repo. Three dispatches on one branch in one day consumed roughly half a $10 monthly
   127	  # budget. The gating was correct; what was missing was any brake on how often the deliberate trigger
   128	  # gets pulled — and "deliberate" is not a rate limit when the same person can dispatch it while
   129	  # iterating on the workflow itself.
   130	  #
   131	  # WHAT THIS COSTS US, STATED PLAINLY: the original argument for `workflow_dispatch` was real —
   132	  # work lands on `development` and `main` sees almost nothing, so a main-only boundary arrives AFTER
   133	  # the promotion decision rather than before it. That gap is now open. The substitute is the LOCAL
   134	  # gate on the platform we ship to: `./validate.sh` (and, per GH-528, `--parallel N` for a ~3-minute
   135	  # run) plus `utils/gate-record.sh`, which is self-reported and does NOT qualify a promotion. If a
   136	  # pre-merge macOS witness is needed for a specific commit, re-enable this trigger deliberately,
   137	  # spend the ~$1.25-1.50, and turn it back off — rather than leaving it armed by default.
   138	  #
   139	  # HONEST LIMIT ON "EXACT COMMIT" (retained; applies to any re-enabled dispatch): `workflow_dispatch`
   140	  # targets a REF, not an arbitrary SHA — GitHub resolves the ref's current HEAD. So this job cannot
   141	  # be pointed at an old commit; it qualifies whatever that ref points to when dispatched. The resolved
   142	  # SHA is printed into the job summary for exactly this reason: the promotion rule compares against a
   143	  # recorded SHA, not against "the run I remember starting".
   144	  #
   145	  # NO SKIP LIST, deliberately. It invokes the authoritative validator directly rather than scraping
   146	  # `TESTS` out of it — the scrape can only see `.sh` entries, which is how the 20-test Python layer
   147	  # (the AUTHORITATIVE implementation since GH-264) went unexercised in CI for months. A second list
   148	  # is a second thing to keep honest; there is no second list here.
   149	  boundary-macos:
   150	    name: promotion boundary (macOS — the platform we ship to)
   151	    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
   152	    runs-on: macos-latest
   180	
   181	      - name: Run the authoritative validator (no skips)
   182	        env:
   183	          # The one documented exclusion, and it is not a coverage skip: this test makes a real
   184	          # billed API call to a live agent. It self-skips off-PATH anyway; the env var makes the
   185	          # intent explicit rather than incidental.
   186	          RELAY_SELF_SUFFICIENCY_SKIP: "1"
   187	        # `--sequential` is PINNED here and must stay pinned. GH-544 made parallel the default for the
   188	        # local gate, which is correct there — but this job is the promotion boundary, and the whole
   189	        # point of it is that its green means something the local run's cannot. Promotion evidence
   190	        # stays sequential (GH-528 Phase 2 has not been met), so the flag is explicit rather than
   191	        # inherited: a future change to validate.sh's default must not be able to silently change what
   192	        # this job attests. test/ci-workflow.sh asserts the flag is present.
   193	        run: ./validate.sh --sequential
   194	
   195	      - name: Promotion evidence
   196	        if: always()
   197	        run: |
   198	          set -euo pipefail
   199	          if [ "${{ job.status }}" = "success" ]; then
   200	            line="MACOS-BOUNDARY: green ${GITHUB_SHA}"
   201	            note="This commit is promotion-qualified (GH-509 §6). Cite this SHA, not this run."
   202	          else
   203	            line="MACOS-BOUNDARY: red ${GITHUB_SHA}"
   204	            note="NOT promotable. Unlike the ubuntu canary, this ran on the platform we ship to — a failure here is a real defect for real users."
   205	          fi
   206	          echo "$line"
   207	          echo "$note"
   208	          { echo "### $line"; echo; echo "$note"; } >> "$GITHUB_STEP_SUMMARY"
   209	
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
   235	    runs-on: ubuntu-latest
   236	    continue-on-error: true
   237	    steps:
   238	      - name: Check out repo
   239	        uses: actions/checkout@v4
   240	        with:
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
   240	                                 #   rating metrics + effectiveScore precedence, and the leaderboard's
   241	                                 #   one-scorer property (script ranking == --json ordering).
   242	  "gh32-releases-app.sh"         # GH-32 Phase 0+1 (SQLite RELEASES ledger CLI: schema/GID shape,
   243	                                 #   writer-lock + journal protocol, canonical dump, receipt chain,
   244	                                 #   import grandfathering, side-by-side gen) — 81/0; registered in the
   245	                                 #   same commit as utils/py/releases_app.py per the lesson above. The
   246	                                 #   four check-failure negative controls, the five crash boundaries,
   247	                                 #   and the refused-writer-changes-nothing control are the point; the
   248	                                 #   revert-and-replay transcript is test/baselines/GH-32-negative-control.md
   249	  "gh32-releases-artifacts.sh"   # #52 (the COMMITTED releases.db/releases.sql pair actually agrees —
   250	                                 #   gh32-releases-app.sh only proves the CLI works in fixtures). The
   251	                                 #   documented merge procedure has a human step (`check --rebuild`);
   252	                                 #   skip it and the committed DB disagrees with the dump silently,
   253	                                 #   and the DB is what every reader trusts at runtime. Read-only and
   254	                                 #   NEVER --rebuild: a gate that repairs destroys the evidence that a
   255	                                 #   merge was mis-resolved. Runs against a COPY (plain `check` writes
   256	                                 #   when an intent journal is live) and hashes the clone's artifacts
   257	                                 #   before/after to prove it. 10/0; control in
   258	                                 #   test/baselines/GH-52-negative-control.md
   259	  "gh53-releases-merge-resolve.sh" # #53 (derived-artifact attributes + the one-command ledger merge
   260	                                 #   resolution). Pins that releases.db stays -diff +
   261	                                 #   linguist-generated and keeps NO merge driver — measured:
   262	                                 #   only a driver defined in .git/config auto-merges it, and
   263	                                 #   auto-merging is the wrong outcome anyway (it lets a merge finish
   264	                                 #   with a DB holding one side's rows). The refusals are the point:
   265	                                 #   a two-header dump (what a naive merge=union leaves) and a dump
   405	# Spike numbers (GH-528, 2026-08-13, M-series macOS): sequential 950.3s → 8-wide 167.4s, byte-identical
   406	# pass/fail set. Flipped to the default 2026-08-14 by operator decision (GH-544), because the local
   407	# gate is now the ONLY gate during the private phase and a 16-minute one does not get run — it gets
   408	# skipped, which is a worse outcome than a 3-minute one.
   409	#
   410	# GH-35 (2026-08-18) REBALANCED THE DEFAULT: cores−2 (up to 8 workers) saturated developer
   411	# machines badly enough to wedge the editor and spin fans for the whole gate. The default is now
   412	# cores/2 capped at 4 (floor 2) — half the machine, not all but two of it — and every worker runs
   413	# under `nice -n 10` so interactive use keeps scheduling priority. `--burst` restores the old
   414	# full-core width for unattended runs; `--throttle` goes further down to 2 workers. Tiers are
   415	# orthogonal to width and never change WHICH tests run — only how many.
   416	#
   417	# WHAT DID NOT CHANGE, and must not: `ci-local.sh` does NOT call this script. It parses the TESTS
   418	# array and runs each suite in its own sequential loop, and it is the path that writes the gate
   419	# record. So "sequential is the only form that qualifies a claim" (GH-528 Phase 2, GH-509) is still
   420	# true and is still what the record attests. Likewise the macOS promotion boundary in ci.yml pins
   421	# `--sequential` explicitly, so a re-armed boundary cannot silently promote on parallel evidence.
   422	# Tiers 1 and 2 are pre-push speed, NEVER promotion evidence (GH-35 / GH-509).
   423	#
   424	# THE FALLBACK IS ANNOUNCED, NEVER SILENT. A gate that quietly downgrades itself teaches you to trust
   425	# a number that is not the one you are getting, so every run prints which mode it chose and why.
   735	    $NICE_CMD bash "$HERE/utils/pdda-local-checks.sh" run || true
   736	  fi
   737	  if [ "$_t1_rc" -eq 0 ]; then
   738	    echo "tier 1: documentation gate GREEN"
   739	    exit 0
   740	  fi
   741	  echo "tier 1: documentation gate RED" >&2
   742	  exit 1
   743	fi
   744	
   745	# ── GH-35 tier 2: shrink the run set to the selected subsystem suites ───────────────────────────
   746	# Tier 2 is the SAME machinery on a smaller list: same pool, same driver-lock lane, same
   747	# identity bracket, same summary invariant — only the test SET changes (and it comes from the
   748	# same registry the push hook uses, so the two cannot disagree about what "hq" covers).
   749	RUN_TESTS=("${TESTS[@]}")
   750	if [ "$TIER" -eq 2 ]; then
   751	  echo
   752	  echo "==============================="
   753	  echo "Tier 2 — subsystem gate (GH-35): $T2_TESTS"
   754	  echo "NOT promotion evidence: the qualifying gate is ci-local.sh's sequential full run (GH-509)."
   755	  echo "==============================="
   756	  RUN_TESTS=()
   757	  for t in $T2_TESTS; do
   758	    [ -f "$HERE/test/$t" ] || { echo "validate.sh: tier-2 suite test/$t is missing — a gate that cannot run has not passed." >&2; exit 1; }
   759	    RUN_TESTS+=("$t")
   760	  done
   761	  [ "${#RUN_TESTS[@]}" -gt 0 ] || { echo "validate.sh: tier 2 resolved to zero suites — refusing a zero-test green." >&2; exit 1; }
   762	  if [ "$T2_PDDA" -eq 1 ]; then
   763	    echo
   764	    echo "==============================="
   765	    echo "Running tier-2 docs gate (docs paths in the change set)"
   766	    echo "==============================="
   767	    if [ -x "$HERE/utils/pdda/pdda.sh" ] && $NICE_CMD bash "$HERE/utils/pdda/pdda.sh" run; then
   768	      PASSED+=("tier2:pdda")
   769	    else
   770	      FAILED+=("tier2:pdda")
   771	    fi
   772	  fi
   773	  if [ -n "$T2_PATHS" ]; then
   774	    echo
   775	    echo "==============================="
   776	    echo "Running tier-2 static syntax checks on changed files"
   777	    echo "==============================="
   778	    _t2s_rc=0
   779	    while IFS= read -r _p; do
   780	      [ -n "$_p" ] || continue
   781	      # A deleted file rides a git-diff path list (PR #55 review, finding 2): there is
   782	      # nothing to syntax-check, and bash -n on a missing path would 127 the whole gate.
   783	      [ -f "$HERE/$_p" ] || { echo "  (gone — skipping $_p)"; continue; }
   784	      case "$_p" in
   785	        *.sh)
   300	way from every worktree. Use unmistakable `-m` messages, and run `git stash list` in the worktree
   301	you're about to pop into (not the one you pushed from) to confirm which entry is `stash@{0}` before
   302	popping.
   303	
   304	---
   305	
   306	## 11. Selective `.git` corruption & skeleton loss (the GH-177 scenario)
   307	
   308	**What actually happened here (2026-07-07):** this repo's main `.git` directory lost `HEAD`,
   309	`objects/`, `refs/`, and `index`, while `hooks/`, `worktrees/`, and `config` survived intact. This
   310	is **not** the "someone ran `rm -rf .git`" scenario in §7 above — that deletes everything uniformly.
   311	This was a *partial* loss (consistent with a selective backup/restore gap), and none of the 10
   312	anti-patterns above describe it or would have helped diagnose it.
   313	
   314	**Detection — verify before trusting a repo:**
   315	```bash
   316	# A healthy repo has ALL of these. Any missing = don't trust git commands here yet.
   317	for f in HEAD objects refs config; do
   318	    [ -e ".git/$f" ] || echo "MISSING: .git/$f"
   319	done
   320	git fsck --no-progress 2>&1 | head -5   # first real integrity check once the above pass
   321	```
   322	Also check `.git/worktrees/*/gitdir` stubs for staleness — a stub with no valid path behind it (or
   323	just a bare `commondir` file and nothing else) is metadata cruft from the same class of incident,
   324	not a real linked worktree; `git worktree prune` clears it once the main repo is healthy again.
   325	
   326	**Recovery — in order, verifying before each destructive-looking step:**
   327	```bash
   328	# 1. git init is DOCUMENTED SAFE to re-run on an existing repo: it only fills in
   329	#    missing standard files (HEAD, objects/, refs/, description, info/exclude,
   330	#    sample hooks) and does NOT overwrite an existing config, hooks, or any
   331	#    working-tree file.
   332	git init
   333	
   334	# 2. Repopulate history from the remote — additive only, does not touch the
   335	#    working tree or local branch refs.
   336	git fetch origin
   337	
   338	# 3. Before pointing any local ref at origin, or touching the working tree,
   339	#    build an index from the candidate branch WITHOUT checkout (read-tree does
   340	#    not write to the working tree) and diff it against what's on disk:
   341	git read-tree origin/main
   342	git status   # compare — do NOT `checkout -f` / `reset --hard` / `clean` yet
   343	
   344	# 4. Only once you've confirmed the working tree matches (or you've decided
   345	#    what to do about genuine local divergence), point the branch ref at the
   346	#    remote — this only writes a ref, still doesn't touch the working tree:
   347	git update-ref refs/heads/main origin/main
   348	
   349	# 5. Restore any tracked files that are genuinely missing/corrupted on disk
   350	#    (confirmed absent or differing from origin, not local WIP) from the
   351	#    remote's tree — scoped to just those paths, not a blanket checkout:
   352	git checkout origin/main -- path/to/missing-file
   353	```
   354	The critical discipline: steps 1–3 are provably non-destructive to the working tree (`init` fills
   355	gaps only, `fetch` writes only to `.git/objects` and remote-tracking refs, `read-tree` populates the
   356	index without touching files). Do not reach for `checkout -f`, `reset --hard`, or `clean` until
   357	you've diffed and know exactly what you'd be overwriting — those commands assume the working tree is
   358	disposable, which after a partial-corruption incident it specifically is not.
   359	
   360	---
   361	
   362	## 12. Never run the full test gate from a linked worktree (the 2026-08-19 incident)
   363	
   364	**Anti-pattern:** treating a linked worktree as an isolated place to verify a branch.
   365	
   366	```bash
   367	git worktree add ../repo-feature -b feature origin/development
   368	cd ../repo-feature
   369	bash validate.sh          # WRONG — this can corrupt the PARENT clone
   370	```
   371	
   372	**Why it's dangerous:** a linked worktree **shares the parent's `.git` common directory** — config,
   373	refs, and object store alike (§5, §10). A suite that manipulates "the repo" rather than a fixture
   374	therefore reaches the *real* repository. Observed on 2026-08-19, from one `validate.sh` run in a
   375	worktree:
   376	
   377	- `core.bare` set to **true** on the parent clone, after which `git rev-parse --show-toplevel` fails
   378	  with `this operation must be run in a work tree` and `git worktree list` reports the main clone as
   379	  `(bare)`
   380	- `remote.origin.url` repointed to a fixture's temp bare repo, which was then deleted — leaving
   381	  `origin` pointing at nothing, and every `gh` command failing with `none of the git remotes
   382	  configured for this repository point to a known GitHub host`
   383	- **all** `refs/remotes/origin/*` deleted
   384	- `development` overwritten with fixture commits (`merge feature`, `feature two`, `fake ra turn`);
   385	  local `main` overwritten with a fixture commit
   386	- ~72 fixture files strewn through the worktree (`art.md`, `relay-flip.md`, `GH-42-SAMPLE-THING.md`, …)
   387	
   388	No commits were lost — objects survived and the clone was repairable — but recovery required knowing
   389	exactly what to inspect. This is the failure mode GH-564 describes ("suites that can reach the
   390	caller's clone through an empty fixture path") arriving in practice.
    32	## Q: Git can't merge binary SQLite files. Do we need `git-sqlite` or something like it to compute the transitions?
    33	
    34	**No.** The DB was never meant to be the merge artifact.
    35	
    36	The authority is split deliberately
    37	([releases_app.py:8-13](utils/py/releases_app.py#L8-L13)):
    38	
    39	| Artifact | Authoritative for |
    40	|---|---|
    41	| `releases.db` | reads and writes **at runtime** |
    42	| `releases.sql` | **git merge boundaries only** |
    43	
    44	Every CLI write regenerates the dump inside the same transaction as the DB write, so the two never
    45	drift outside a crash. At a merge you resolve the **text**, then rebuild the binary from it:
    46	`releases check --rebuild` does dump → DB atomically, keeping a `.bak` of the displaced DB.
    47	
    48	`--rebuild` is for **merge resolution only, never crash recovery.** Crash recovery is a different
    49	mechanism (see below) and conflating them will destroy evidence.
    73	## Q: What's the actual merge procedure?
    74	
    75	It is tested end-to-end in section J of
    76	[test/gh32-releases-app.sh:300-322](test/gh32-releases-app.sh#L300-L322) — two divergent clones each
    77	import a different 2-release ledger, the dumps are merged, and the test asserts all four releases
    78	survive with both import runs intact.
    79	
    80	The resolution step:
    81	
    82	```bash
    83	{ grep '^-- generation' "$A/releases.sql"
    84	  grep -vh '^-- generation' "$A/releases.sql" "$B/releases.sql" | awk '!seen[$0]++'
    85	} > merged.sql
    86	```
    87	
    88	Keep **one** generation header, union the remaining lines, dedupe. Then:
    89	
    90	```bash
    91	python3 utils/py/releases_app.py check --rebuild   # dump -> DB, atomic, .bak of the old DB
    92	python3 utils/py/releases_app.py check             # must print "check: clean"
    93	```
    94	
    95	Or, since 2026-08-19, one command that does all of it and refuses what it cannot settle:
    96	
    97	```bash
    98	utils/releases-merge-resolve.sh
    99	```
   126	### The derived artifacts conflict on purpose
   127	
   128	`releases.db` conflicts on every concurrent ledger write. That is
   129	deliberate, and `.gitattributes` records the measurement behind it: `merge=ours` does nothing (`ours`
   130	is a merge *strategy*, not a built-in *driver*), and the only thing that auto-merges it is a driver
   131	defined in `.git/config` — which is not committed, so it would be absent on fresh clones (#4).
   132	
   133	More to the point, auto-resolving is the **wrong outcome**: it lets the merge complete while the DB
   134	still holds only one side's rows, leaving the rebuild easy to forget. The conflict is what stops you
   135	at the moment the decision has to be made. Resolution is `utils/releases-merge-resolve.sh`.
   136	
   137	---
   138	
   139	## Q: What triggers the transforms before, during, and after a git operation?
   140	
   141	**Git triggers nothing.** Every transform is fired by the CLI process. Git is entirely passive — it
   142	sees two files and merges them naively.
   143	
   144	Verified: the only installed hook is `pre-push`, and it contains zero references to releases. There is
   145	no `post-merge`, `post-checkout`, or `post-rewrite` hook. `.gitattributes` exists as of 2026-08-19 but
   146	defines **no merge driver** — it only marks `releases.db` as a derived file, deliberately (see above).
   147	
   148	| Transform | Triggered by | Automatic? |
   149	|---|---|---|
   150	| DB write + dump + generated view | a CLI write command | yes, same transaction |
   151	| Crash recovery from the intent journal | `releases check` | **no** — human runs it |
   152	| Merge resolution (dump → DB) | `releases check --rebuild` | **no** — human runs it |
   153	| Anything at all during `git merge` / `checkout` / `rebase` | — | **nothing fires** |
   199	**Use CI + the gate instead.** `.github/workflows/ci.yml` runs `./validate.sh --sequential` on `push`
   200	and `pull_request` for `main` and `development`. So [#52](https://github.com/HiQS-Suite/XYZ-forge/issues/52)
   201	— wiring `releases check` into `validate.sh` — buys enforcement on four surfaces from one committed
   202	change: every PR before merge, every push to `development` after merge, local `pre-push`, and any
   203	local `validate.sh` run. It travels with the clone and catches divergence regardless of how the merge
   204	happened.
   205	
   206	**Why this is less urgent than it sounds:** the server-side path already fails closed. If two branches
   207	both wrote to the ledger, GitHub hits the binary conflict on `releases.db` and **refuses to
   208	auto-merge** rather than producing a divergent state silently. The genuinely risky path is a human
   209	resolving locally and pushing — which `pre-push` and CI both cover.
   210	

2026-08-22T00:31:14.674426Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
exec
/bin/zsh -lc "git status --short --branch && git branch --show-current && git log --oneline --decorate -15 && git show --stat --oneline --summary HEAD && git log --oneline origin/development..HEAD && rg -n -C 2 'GH-124|GH-123|closeout|gate-evidence|agent2agent' CHANGELOG.md ROADMAP.md PROJECT README.md 2>/dev/null | head -240" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-54150-qde9l_3o
2026-08-22T00:31:34.543314Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
2026-08-22T00:31:36.243418Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
 succeeded in 15343ms:
2026-08-21 17:31:25.277 xcodebuild[71071:153416122]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:25.762 xcodebuild[71071:153416098] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-yU3b8t9P' (errno=Operation not permitted)
2026-08-21 17:31:26.727 xcodebuild[71641:153419444]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:27.061 xcodebuild[71641:153419367] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
## HEAD (no branch)
?? relay-system/2026-08-21/gh124-merge-seq-173029/
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-yEta5AzK' (errno=Operation not permitted)
2026-08-21 17:31:28.982 xcodebuild[72634:153424333]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:29.242 xcodebuild[72634:153424236] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-1H8ynE1i' (errno=Operation not permitted)
2026-08-21 17:31:29.877 xcodebuild[72896:153425792]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:30.080 xcodebuild[72896:153425732] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-ByRKyjnw' (errno=Operation not permitted)
2026-08-21 17:31:31.519 xcodebuild[73473:153427813]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:31.752 xcodebuild[73473:153427732] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-ds0uYAeM' (errno=Operation not permitted)
2026-08-21 17:31:32.374 xcodebuild[73821:153429342]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:32.593 xcodebuild[73821:153429244] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
b1611d01 (HEAD, origin/feat/gh124-closeout-automation, feat/gh124-closeout-automation) docs(registry): update stealth/ox-alpha evaluation with rebalanceOS v0.75.3 review (#120)
cbf43991 fix(test): harden oracle-guard and gh430-state-dir against isolated temp clone execution
1c1effa2 fix(marathon-drive): exempt harness-owned .xyz/ and .relay-scratch/ from require-clean dirty check
d62d4796 fix(validate): fix syntax fi in receipt check and physical root normalization in releases-skill test
1bc95246 fix(GH-124): address review feedback — trash quarantine aging, detached HEAD push check, receipt timing & closeout callers
a18432ac docs(registry): update stealth/ox-alpha entry with GH-124 multi-turn evaluation evidence
26180d7f docs(relay): record agent2agent #658731 and initial review thread for GH-124
38eb9c91 fix(workspace-manager): use directory timestamp prefix for trash reaper age calculation
2cd91fc2 relay(RELAY-GH124-CLOSEOUT-QA): aider turn (aider headless; no push)
65a340cd feat(harness): closeout automation, gate receipts, workspace GC & drift alert (GH-124)
e7586738 (origin/development, origin/HEAD, development) fix(GH-59): correct the CI header — triggers work; conflicts explain the silence (#126)
aeb1d965 docs(GH-59,GH-123): codify the two CI facts that keep getting rediscovered (#125)
ac1f9f3f Merge pull request #119 from arnoldadero/evidence/linux-bringup-marathon
02ce2292 docs(GH-108,GH-111): promote both plans to 3-COMPLETED and close out the checklist (#122)
c271be37 Merge pull request #116 from HiQS-Suite/feat/gh111-phase-a-dialed-in
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-cLNLPa9Y' (errno=Operation not permitted)
2026-08-21 17:31:34.107 xcodebuild[74677:153432637]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:34.500 xcodebuild[74677:153432560] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-FFtOh2Wb' (errno=Operation not permitted)
2026-08-21 17:31:35.503 xcodebuild[75461:153436039]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:35.808 xcodebuild[75461:153435972] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
b1611d01 docs(registry): update stealth/ox-alpha evaluation with rebalanceOS v0.75.3 review (#120)
 HARNESS-MODELS-REGISTRY.md | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-iSYlQiMA' (errno=Operation not permitted)
2026-08-21 17:31:37.458 xcodebuild[76576:153440909]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:37.663 xcodebuild[76576:153440863] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-7DcQTimN' (errno=Operation not permitted)
2026-08-21 17:31:38.347 xcodebuild[76822:153442328]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:38.612 xcodebuild[76822:153442278] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
b1611d01 docs(registry): update stealth/ox-alpha evaluation with rebalanceOS v0.75.3 review (#120)
cbf43991 fix(test): harden oracle-guard and gh430-state-dir against isolated temp clone execution
1c1effa2 fix(marathon-drive): exempt harness-owned .xyz/ and .relay-scratch/ from require-clean dirty check
d62d4796 fix(validate): fix syntax fi in receipt check and physical root normalization in releases-skill test
1bc95246 fix(GH-124): address review feedback — trash quarantine aging, detached HEAD push check, receipt timing & closeout callers
a18432ac docs(registry): update stealth/ox-alpha entry with GH-124 multi-turn evaluation evidence
26180d7f docs(relay): record agent2agent #658731 and initial review thread for GH-124
38eb9c91 fix(workspace-manager): use directory timestamp prefix for trash reaper age calculation
2cd91fc2 relay(RELAY-GH124-CLOSEOUT-QA): aider turn (aider headless; no push)
65a340cd feat(harness): closeout automation, gate receipts, workspace GC & drift alert (GH-124)
ROADMAP.md-111-- **GH-61 · RELEASES ledger durability hardening (GH-57 follow-up)** 🆕 **queued 2026-08-19 — filed 2026-08-19 out of the PR #60 review and un-triaged until now** — four scoped test follow-ups under one parent: exact ledger state asserted after crash recovery ([#62](https://github.com/HiQS-Suite/XYZ-forge/issues/62)), writer-lock stress and owner-death recovery ([#63](https://github.com/HiQS-Suite/XYZ-forge/issues/63)), seeded malformed-dump property coverage ([#64](https://github.com/HiQS-Suite/XYZ-forge/issues/64)), and a portable artifact-hash helper ([#65](https://github.com/HiQS-Suite/XYZ-forge/issues/65)). rated 45/55/40/50. → [#61](https://github.com/HiQS-Suite/XYZ-forge/issues/61)
ROADMAP.md-112-- **GH-67 · Commandcode builder default widened to `--yolo` — closer evaluation → possible build** 🆕 **queued 2026-08-19 as the NEXT immediate item (operator call, session close)** — PR #60 moved the default from the bounded `--permission-mode auto-accept` to `--yolo` (alias for `--dangerously-skip-permissions`), unmentioned in a fuzzing PR. Evaluate whether the turn shim’s containment (worktree isolation, `ALLOW_PATHS`, commit-bypass guard) genuinely makes the child CLI’s permission mode irrelevant; if yes, RATIFY — write the containment argument down in AGENTS.md/the shim docs and pin it — if no, revert the default and drop the `--yolo` test pin. Sibling check either way: `claude-turn.py` uses `--permission-mode acceptEdits`; confirm the two adapters differ on purpose. rated 88/80/45/70 ovr 340. → [#67](https://github.com/HiQS-Suite/XYZ-forge/issues/67)
ROADMAP.md:113:- **GH-35 · 3-tier test suite selection (docs / utility subsystems / core) + CPU governance** 🚧 **Phases 1+2 BUILT 2026-08-18 on `development` (standalone clone `XYZ-forge-gh35`)** — one fail-closed subsystem registry in `utils/ci-route.sh` (hq, releases, telemetry, ate, swe-diagram, pdda, agent2agent) consumed by `githooks/pre-push` and `validate.sh`; `--tier/--subsystem/--auto/--paths-file`; the parallel default rebalanced from `cores-2` (up to 8) to `cores/2` (cap 4) with every worker under `nice -n 10`, plus `--throttle`/`--burst`/`XYZ_VALIDATE_THROTTLE`/`XYZ_VALIDATE_MAX_JOBS`. Utility pushes drop from the full ~4-min pool to their focused suites (~20-45s target, measurement owed). New suite `test/gh35-test-tiers.sh` 56/0; pre-push suite extended to 85/0. Phase 3 (CI alignment + every-file-classified sweep) pending. rated 55/45/50/45. → [GH-35-TEST-TIER-ROUTING.md](PROJECT/2-WORKING/GH-35-TEST-TIER-ROUTING.md) · [#35](https://github.com/HiQS-Suite/XYZ-forge/issues/35)
ROADMAP.md-114-- **GH-42 · relay automation: supported Commandcode turn-taker** 🚧 **active 2026-08-18** — add a Python-authoritative, containment-preserving Commandcode adapter with mocked regression coverage; Muse Spark Contributor is the initial builder and Codex performs independent QA. rated 50/35/55/45. → [GH-42-COMMANDCODE-TURN.md](PROJECT/2-WORKING/GH-42-COMMANDCODE-TURN.md) · [#42](https://github.com/HiQS-Suite/XYZ-forge/issues/42)
ROADMAP.md-115-- **GH-32 · RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI** 🚧 **Phase 0+1 BUILT and merged 2026-08-19 (PR #34, builder GLM 5.3 per the #33 evaluation)** — schema/CLI/writer-protocol/canonical-dump/import landed (`utils/py/releases_app.py`, suite 81/0, full gate green, independently verified); the PRD survived a 4-round Codex sol-high relay review first. Still ahead: the `/releases` route migration (Phase 0 entry gate for the measured dogfood window), the Phase 2 strict flip, and the Phase 3 cockpit card. rated 70/50/65/35. → [GH-32-RELEASES-APP-SQLITE.md](PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md) · [#32](https://github.com/HiQS-Suite/XYZ-forge/issues/32) · [#33](https://github.com/HiQS-Suite/XYZ-forge/issues/33)
--
ROADMAP.md-119-### In progress
ROADMAP.md-120-
ROADMAP.md:121:- **GH-124 · eliminate end-of-day closeout friction — automated phase QA receipts, auto-PR creation, and clone lifecycle hygiene** 🚧 **active 2026-08-21** — eliminate 50+ minutes of daily closeout friction: on-disk local gate receipts (`ci-local.sh` / `validate.sh`), driver-refreshed early drift alerts, safe manifest-bounded workspace sweep with soft quarantine, hardened `marathon-closeout.sh`, and post-gate in-flight QA attestation comments. rated 85/60/90/40. → [GH-124-CLOSEOUT-AUTOMATION.md](PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md) · [#124](https://github.com/HiQS-Suite/XYZ-forge/issues/124)
ROADMAP.md-122-- **GH-77 · `/standup` — session-scoped triage: what did I leave open, what is rotting, is the plan still right?** 🚧 **THE MARATHON as of 2026-08-19 (handed over from GH-10 by operator call); triage.py + 29-assertion suite BUILT and merged (PR #78); `collect.sh` is the marathon's eight work units** — the instrument the operator reaches for constantly, and the answer to the confidence problem the 2026-08-19 audit exposed: a shipped release left `active` for a day, four ledger markers contradicting GitHub, five issues filed into no index — all discoverable in seconds, none discovered by anything. Session + local state only (no history sweep; `/radar` keeps that job), park-only write authority, both halves every run, tactical list hard-capped at 7 items and the strategic read at ~5 lines. Carries an interface catalogue for the RELEASES CLI, the ROADMAP entry schema, PDDA lifecycle, and the one-marathon rail, so every recommendation names the exact command that closes it. rated 95/70/85/30. → [GH-77-STANDUP-SESSION-TRIAGE.md](PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md) · [#77](https://github.com/HiQS-Suite/XYZ-forge/issues/77) · [GH-77-STANDUP-SESSION-TRIAGE.md](PROJECT/2-WORKING/GH-77-STANDUP-SESSION-TRIAGE.md)
ROADMAP.md-123-- **GH-5 · kernel robustness: node:test unit runner** 🆕 **active 2026-08-15 on `gh-5/events-quarantine-unit-tests` (public-repo tracker)** — 11 direct unit tests on the built-in `node:test` runner (was 13; the 2 quarantine-dependent tests deferred to #14), zero new dependencies, `npm run test:unit`, `npm test` → `validate.sh` unchanged. The quarantine-in-reader approach was rejected on orchestrator review per the correction on #5 (silent event loss on the concurrent path while writes are non-atomic) and re-routed to #14. **#5 stays open until this PR's tests and #14's atomic write have both landed.** rated 45/40/45/80. → [GH-5-EVENTS-QUARANTINE-UNIT-TESTS.md](PROJECT/2-WORKING/GH-5-EVENTS-QUARANTINE-UNIT-TESTS.md) · [#5](https://github.com/HiQS-Suite/XYZ-forge/issues/5)
--
README.md-62-  [PROJECT/4-MISC/AUTOMATED-RELAY.md](PROJECT/4-MISC/AUTOMATED-RELAY.md).
README.md-63-- **Connect live agent sessions by a short ID** — start a serialized discussion with two or more
README.md:64:  Claude, Codex, or other skill-aware sessions → see [Agent2Agent](#agent2agent--live-sessions-by-compact-id).
README.md-65-- **Here for the kernel** — how the `tick` coordination primitive works →
README.md-66-  read [What `tick` is](#what-tick-is), then the source in [bin/tick](bin/tick), [src/](src), [test/](test).
--
README.md-125-
README.md-126-```bash
README.md:127:bash skills/agent2agent/install.sh
README.md-128-```
README.md-129-
README.md:130:Then ask the first session to start a discussion, for example: *"Start XYZ agent2agent with four
README.md-131-agents to discuss: subject line here."* It seeds turn 1 as `agent1`, creates a collision-checked
README.md-132-six-digit ID under `relay-system/<date>/`, and prints a copy/paste invitation:
README.md-133-
README.md-134-```text
README.md:135:Join XYZ agent2agent #123456 as agent number two to discuss: "subject line here"
README.md-136-```
README.md-137-
--
README.md-141-the original roster. Two operating levels are available: read-only `watch` polls every 150 seconds
README.md-142-by default, while `drive` is an explicit, bounded opt-in that invokes an approved turn command only
README.md:143:when that participant owns `NEXT:`. See [the agent2agent skill](skills/agent2agent/SKILL.md) for the
README.md-144-deterministic `start`/`join`/`watch`/`drive`/`send`/`close` contract.
README.md-145-
--
README.md-270-
README.md-271-1. Create a working branch in your XYZ clone.
README.md:272:2. In the XYZ repo, ask Claude Code to: *"install the /relay-xyz, /consult, and /agent2agent skills for me
README.md-273-   system-wide."*
README.md-274-3. In any target project (on its own fresh branch), you can now:
--
README.md-417-
README.md-418-- `relay-automation/` — scripts and operator docs for poll-driven relays, watchdogs, headless turn-takers, and consult.
README.md:419:- `skills/` — packaged skill surfaces, including `agent2agent`, `relay-xyz`, `relay-automation`, `xyz`, consult helpers, and
README.md-420-  [`ponytail`](skills/ponytail/SKILL.md) (the `/ponytail` lens definition cited throughout
README.md-421-  `PROJECT/` docs and PDDA's `/idea` Phase 0 — see legacy source issue #180).
--
README.md-431-- `skills/file-xyz-bug/` — file a harness bug from **any other repo** into this repo's `PROJECT/1-INBOX/`
README.md-432-  (GH issue + capture doc + ROADMAP park), without touching the repo you're standing in.
README.md:433:- `skills/agent2agent/` — compact six-digit rendezvous for serialized discussions among two or more
README.md-434-  live sessions; reuses dated relay files and supports Claude Code plus Codex skill installation.
README.md-435-- `relay-system/` — relay transcripts, reviews, and dogfood runs.
--
CHANGELOG.md-213-  AND `tier=2` AND runnable suites) to its focused suites in seconds instead of the full pool.
CHANGELOG.md-214-  One fail-closed registry in `utils/ci-route.sh` (hq, releases, telemetry, ate, swe-diagram,
CHANGELOG.md:215:  pdda, agent2agent — per the issue's subsystem matrix) is consumed by the hook, the runner, and
CHANGELOG.md-216-  (Phase 3, pending) CI; unknown paths, test edits, deleted tests, and kernel surfaces always
CHANGELOG.md-217-  escalate to the full gate, and a subsystem whose suites are missing on disk escalates rather
--
CHANGELOG.md-228-  Tier 1/2 are pre-push speed only and say so — `ci-local.sh` remains the sequential
CHANGELOG.md-229-  full-suite qualifying run (GH-509).
CHANGELOG.md:230:- **`utils/pdda/**` and `skills/agent2agent` code moved from blanket-full to their Tier-2
CHANGELOG.md-231-  subsystems** (per the issue's matrix): their focused suites run instead of the whole pool at
CHANGELOG.md-232-  the push boundary. Hosted CI routing is unchanged until Phase 3.
--
CHANGELOG.md-376-  migration and reinstall the former alias set. Focused proof: `test/releases-skill.sh` **26/26**,
CHANGELOG.md-377-  skill validator green, `pdda.sh releases` 0/0, and targeted PDDA structure checks green. GitHub
CHANGELOG.md:378:  issue creation was deferred by DNS failure under explicit operator override and remains a closeout
CHANGELOG.md-379-  requirement. → [RELEASES-SKILL-CONSOLIDATION.md](PROJECT/2-WORKING/RELEASES-SKILL-CONSOLIDATION.md)
CHANGELOG.md-380-
CHANGELOG.md-381-### Fixed
CHANGELOG.md-382-- **The `releases-skill` gate is unregistered until its file lands — `development`'s suite was red in every clone but one.** The registration reached `development` while the gate file it names did not, so `validate.sh` exited 127 for everyone whose working tree did not happen to hold the author's uncommitted copy — and green for the one session that could not see the breakage. That is #461's defect in mirror image: there, a gate that exists but is unregistered is invisible; here, a registration with no gate is a permanent red that says nothing about the code, and since GH-544 put the suite on the push boundary it was refusing every push from every session. **The test is not at fault and was not deleted** — it passes **26/0** in the tree where its inputs exist. It needs the whole consolidation (the plural skill directory, removal of the legacy singular one, and the router / PDDA-contract routing updates), which is in flight and uncommitted elsewhere; landing that change re-enables the line in the same commit. Deliberately not completed here: pulling ~7 files of another session's uncommitted work across — including its own CHANGELOG prose — to satisfy a one-line registration would be a much larger intervention than the breakage warrants. Suite goes from 3 failures to 1. **RESOLVED the same day** — the consolidation landed and the line was re-registered in the commit that brought the gate file with it, which is exactly the condition recorded here. Kept rather than deleted because a ~2h window in which the shared branch refused every session's push is a real event, and the rule it produced is worth stating once: **register a gate and its file together, or neither.** → [#461](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/461)
CHANGELOG.md:383:- **GH-561: the marathon branch guard was protecting the one branch marathons never touch, and the 2026-08-15 Meter run landed four commits straight on `development` with no branch and no PR.** `refuse_trunk_commit` (GH-402) keyed on `origin/HEAD`, which here resolves to `origin/main`, so `development` read as an ordinary feature branch and the guard returned without firing — while `marathon-closeout.sh:18` has hardcoded `BASE_BRANCH="development"` all along. **The two halves of one ceremony disagreed about what `development` is**: closeout treats it as the branch you PR *into*, the guard treated it as one you may commit *on*, and AGENTS.md is with closeout. The harm the guard's own message names — turns commit continuously, so a run that lands on a shared branch can only be un-landed by rewriting history someone else may have pulled — applies to `development` exactly as to `main`. **The remedy changed too, and this is the consequential half:** GH-402 shipped a hard refusal, and the refusal was right about the harm and wrong about the response, because the operator's only correct next action was always the same `checkout -b` and an unattended marathon has nobody there to take it. The guard now **cuts the lane branch and continues** (`SP_SUGGESTED_BRANCH`, else `marathon/<phase>-<date>`; an existing branch is switched to so a re-fire resumes its own work rather than stranding each attempt), and a green phase calls `marathon-closeout.sh --open-only --no-commit` so a finished lane leaves an open PR into `development`. **`--no-commit` is new and load-bearing** — closeout's default `git add -A` swept 20 unrelated files into a lane PR once already (2026-08-10), and an automated caller must not re-arm that. GH-402's invariant is unchanged and now measured directly rather than inferred from a refusal: the shared branch receives nothing. **Bet:** redirecting beats refusing because the refusal had exactly one correct response; if auto-cut ever produces a branch the operator did not want, the cost is a stray branch, not lost work. **Failure signal:** a lane branch that carries no commits, or a PR opened against the wrong base. **Rollback:** `MARATHON_INTEGRATION_BRANCH=` restores GH-402 scope; a failed auto-cut already falls back to the original hard refusal. **Contributing cause recorded rather than smoothed over:** the run cited AGENTS.md's "do not create new git branches automatically" as its justification, ignoring the marathon carve-out in the very next bullet — that bullet is amended, but the guard is what actually stops it, same lesson as GH-551. `test/gh402-branch-enforcement.sh` **20/0** (was 13, and cases 1/2/6 were rewritten from refusal semantics to redirect semantics), `test/marathon-closeout.sh` **25/0**. → [#561](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/561) · [#402](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/402)
CHANGELOG.md-384-- **GH-557: an acceptance verdict of `unknown` no longer reads as `ready` on a frozen manifest entry.** `check_acceptance_fidelity` blocked only on `diverged`, so `unknown` fell through to `ready (exit 0)`. Caught live against Meter manifest member **#382** with `gh` authenticated and the network healthy: `inlined-acc : 6 criterion(a)`, `acceptance : unknown — issue #382 has no '## Acceptance' section`, `verdict : ready (exit 0)`. Six criteria in the capture doc, none on the issue, lane dispatchable — which is exactly the GH-400 failure arriving through GH-400's own pass-through case, since neither builder nor reviewer ever sees the issue. **One status was hiding two situations that need opposite handling**, and that collapse cost a real diagnosis: during the 2026-08-14 DNS outage every Meter packet read `unknown` and it was attributed to DNS; when DNS was restored the same entries still read `unknown` for the second reason entirely, and nothing in the output distinguished them. A `cause` field now separates **`fetch-failed`** (transient — advisory on *every* path, including manifest members, because an outage is not a contract violation and making it one would have halted the whole repo on 2026-08-14) from **`no-issue-section`** (structural — the issue states no criteria, so no retry will ever verify the doc's list). **Only the structural cause blocks, and only on a frozen manifest member**: everywhere else it stays advisory, because refusing every acceptance-less issue would be a hard stop on ordinary exploratory and externally-reported work. Membership is read from each `test/*-release.sh` goalpost's `MANIFEST=(...)` array — already cross-checked against `RELEASES.md` by the goalpost itself — and **not** by parsing `RELEASES.md`'s `Manifest:` prose, which names #509 (retired), #358 Phase 2 (moved to Lantern) and #551's nine root-cause siblings; a regex over that line would have read every one as a member and blocked unrelated lanes, a worse failure than the one being fixed. The packet's provenance line for the structural case also stops telling the reader to "read the issue before building" — there is nothing there to read, which is the whole problem. **16/0**, hermetic; control in `test/baselines/GH-557-negative-control.md` is **5 pass / 11 fail** pre-fix with the pin observed as `expected exit 5, got 0` — and the three assertions that *pass* pre-fix are the load-bearing ones, since a detector that simply refused every acceptance-less issue would satisfy the pin and fail all three. **Deliberately not admitted to Meter**, which stays frozen at seven: it was found while re-running that manifest, which is provenance, not membership. → [GH-557-UNKNOWN-BLOCKS-MANIFEST.md](PROJECT/2-WORKING/GH-557-UNKNOWN-BLOCKS-MANIFEST.md) · [#557](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/557) · [#400](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/400) · [#419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419)
CHANGELOG.md-385-
--
CHANGELOG.md-412-
CHANGELOG.md-413-- **The push gate was silently skipped on any branch without `githooks/` — the entrypoint moves out of the working tree (GH-549).** Found by dogfooding #544's own fix: pushing `chore/ship-litmus-nightwatch` (cut from `development` before the hook landed) produced **no gate output at all**. `core.hooksPath` is **repo-scoped, not branch-scoped**, so on a checkout with no `githooks/` directory git resolves no hook file and runs nothing — and git emits no warning for a hooks path that does not resolve. That push happened to be verified by hand, but the mechanism failed silently, which is the exact property #544 exists to eliminate. **The trap is structural: the hook is the thing that does not run**, so no code inside `githooks/pre-push` can detect its own absence, and any fix living in the failing component is not a fix. `install.sh` now writes a **dispatch stub into the clone's `.git/hooks/`** — git metadata, therefore branch-independent, and shared by every linked worktree — which execs the in-tree hook when present, falls back to running `validate.sh` directly (announced) on branches that predate it, and **refuses the push** when neither exists. The stub is a delegator, not a copy: all real logic stays reviewable in-tree and the two cannot drift. A cross-model consult (codex + agy) converged on this independently, and both rejected a check inside `validate.sh`/`ci-local.sh` for the same reason — it only runs when you already chose to run it, so it can never observe the push where git found no hook. **Their one disagreement was settled by measurement rather than argument:** codex objected that `.git/hooks` is wrong for linked worktrees; `git rev-parse --git-path hooks` from a worktree in fact returns the *parent clone's* hooks dir, so the custom directory that objection motivated buys nothing. codex's other correction was load-bearing and is adopted — `core.hooksPath` must be explicitly **unset**, or the stale value keeps overriding the stub. **The suite caught a bug in its own fix:** the first implementation resolved the stub's destination with `git rev-parse --git-path hooks`, which *obeys* `core.hooksPath` — so mid-migration it resolved to the in-tree `githooks/` and the installer targeted the very hook it delegates to; resolution moved to `--git-common-dir`. `gh544-pre-push-gate` goes 38/0 → **63/0**, now driven by a **real `git push`** to a local bare remote: every prior case invoked the hook directly, which is precisely what this defect was invisible to, since the hook's logic was never wrong — git never dispatched to it. The negative control reproduces the pre-fix wiring pushing ungated and silent. **The residual gap is stated, not solved:** a clone that never ran `install.sh` is still ungated and `--no-verify` still works; neither is fixable client-side. → [GH-549-PREPUSH-BRANCH-INDEPENDENT.md](PROJECT/2-WORKING/GH-549-PREPUSH-BRANCH-INDEPENDENT.md) · [#549](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/549)
CHANGELOG.md:414:- **Hosted CI is retired for the private phase; the gate now runs at the push boundary (GH-544).** Operator decision, and it is about **where the bill lands, not the tests** — #528 already settled that question in the opposite direction (zero redundant suites, wait-time hypothesis falsified), so coverage is unchanged. Aug 1-14 cost $21.99 gross / $10.00 billed, exhausted the 2,000 included minutes on Aug 11 and hit the spending limit on Aug 14, blocking Actions outright. `githooks/pre-push` runs `./validate.sh` before any push and `githooks/install.sh` wires it via `core.hooksPath`; `.github/workflows/ci.yml` loses `push:`/`pull_request:` while keeping every job and the GH-509 Phase 4 cost analysis verbatim for re-arm. **`validate.sh` is now PARALLEL by default** — 4:06 wall clock 8-wide vs ~16 min sequential — with host detection (cores−2, capped at 8) and a fallback to sequential that is **always announced with its reason**, because a gate that quietly downgrades itself teaches you to trust a number you did not get. **The fast form is the whole design, not a shortcut:** a 16-minute pre-push hook does not produce 16 minutes of testing, it produces `--no-verify` as a reflex. **Two invariants pinned because the flip would otherwise have broken them silently:** `ci-local.sh` (which writes the evidence record) never calls `validate.sh` and stays sequential, and `ci.yml`'s macOS boundary now pins `--sequential` explicitly rather than inheriting a default. **A Codex QA pass found three Blockers, all real, all fixed — and one was in this lane's own test methodology:** the `marathon-closeout.sh` no-checks fix was **dead code under `set -euo pipefail`** (a failing `var="$(cmd)"` exits before `_checks_rc=$?`), and the suite reported **35/0 against that broken code** because the harness `eval`'d the block without `set -e`. The harness now runs it under the production shell options and a control pins the regression at 9 failures. The other two: `test/ci-workflow.sh` still *required* the removed triggers (the gate was genuinely red, so the hook would have blocked its own push — the assertions are now inverted, with the originals preserved verbatim for re-arm), and the hook/test/baseline were untracked while `validate.sh` referenced them. **The debt is recorded, not argued away:** GH-509's promotion boundary is knowingly set aside, so no independent attestation exists during the private phase, and the ubuntu canary's absence means Linux drift accumulates unreported until re-arm. **Re-arm trigger: the repo goes public** — Actions is free and unmetered there, so the cost basis expires by construction. → [GH-544-LOCAL-GATE-BEFORE-PUSH.md](PROJECT/2-WORKING/GH-544-LOCAL-GATE-BEFORE-PUSH.md) · [#544](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/544)
CHANGELOG.md-415-
CHANGELOG.md-416-### Added
CHANGELOG.md:417:- **The gate-evidence record can now tell a real run from a stamped one (GH-536).** It was six lines whose only claim about the run was `result: green` — a bare assertion about output that no longer exists by the time anyone reads the record. `utils/gate-record.sh` gained optional `--suite-log` and `--verdicts`; `ci-local.sh` captures both in the same run and passes them through, so the record carries an `output-sha256` of the transcript, its byte count, and a per-suite pass/FAIL/skip list. **`PIPESTATUS[0]` is load-bearing** in that capture: `bash test/$t | tee -a` makes `$?` tee's status, so a failing suite would have been recorded as passing. **The issue's trust-level argument is rejected, and the suite pins the rejection:** #536 proposed that an automated pipeline hashing its own results earns a softer `NOT-promotion-evidence` disclaimer. It does not — a hash computed on your own machine over output you produced is **tamper-evident, not attested**, and someone can stub a suite and hash the doctored result just as easily. That is precisely the circularity GH-509's agy review rejected, so the disclaimer is unchanged and a test fails if a future edit drops it. **Three of the issue's four premises were also wrong and are recorded rather than quietly worked around:** `ci-local.sh` already existed (added `d4d2a39f`, two days before the issue was filed), already refused on a dirty tree, already ran the suite, and already could not reach the record after a failure — it `exit 1`s first. Only requirements 3 and 5 were real. → [GH-536-EVIDENCE-DETAIL.md](PROJECT/2-WORKING/GH-536-EVIDENCE-DETAIL.md) · [#536](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/536)
CHANGELOG.md-418-- **A tree-overwriting git command now leaves what it destroys recoverable (GH-527).** Three times in one session an agent used a git *history* command to undo a *working-tree* experiment: a tree-wide `git stash` that took four other sessions' files and timed out before its `pop`; a `git checkout -- <path>` that restored HEAD rather than the pre-edit state and ate ~60 lines of new tests; a `git reset --hard origin/development` that took four sessions' tracked modifications plus `.claude/settings.json`, which never came back. **The shape is snapshot-then-allow, not refuse-when-dirty** — `relay-automation/hooks/gh527-destructive-git-guard.sh` copies the doomed **tracked** files into `.tick/orphan-backups/` and always exits 0. That is the shape this repo already chose for the same problem (`rtl_check` does exactly this before reverting an off-allowlist edit, GH-141); refusing instead would fire on every legitimate solo cleanup and train an override reflex, and it could not satisfy the issue's own acceptance criterion requiring *demonstrated* recovery. Tracked-only is not an oversight: the issue **reproduced** the blast radius in a fixture — tracked modifications die, untracked files survive — so snapshotting untracked files would be noise hiding the signal. **The `AGENTS.md` rail is the explanation, not the fix:** the issue falsified a doc-rail-only proposal against the session's own ledger — every mechanical guard (frozen-twin, `path-integrity.sh`, the GH-472 SIGPIPE detector) caught the author; neither written warning did. 26/0, registered, recovery demonstrated end-to-end. **Control worth reading:** clean-tree silence is defended by *two* independent conditions, so two separate single-line mutations both stayed green and it took a combined mutation to produce exactly one red — recorded in `test/baselines/GH-527-negative-control.md` rather than presented as a clean first try. → [GH-527-DESTRUCTIVE-GIT-GUARD.md](PROJECT/2-WORKING/GH-527-DESTRUCTIVE-GIT-GUARD.md) · [#527](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/527)
CHANGELOG.md-419-
--
CHANGELOG.md-442-
CHANGELOG.md-443-### Changed
CHANGELOG.md:444:- **The macOS promotion boundary lost its `workflow_dispatch` trigger, because the estimate that armed it was wrong by an order of magnitude in the direction that costs money.** Phase 4 shipped `boundary-macos` gated on `push` to `main` **or** `workflow_dispatch`, arguing the job was affordable *because it was deliberate* — "well under a dollar a handful of times a month". The org's actual August usage says otherwise: **macOS 3-core, 75 minutes, $4.65 net — against Ubuntu's 2,740 minutes at $4.44 net.** Seventy-five macOS minutes cost more than 2,740 Linux minutes, because the runner bills ~10× **and** draws no included-minute discount on a private repo; a full boundary run is **≈$1.25–1.50**, and three dispatches on one branch in one day consumed roughly half a $10 monthly budget. **The gating was never the defect — the missing piece was any brake on how often the deliberate trigger gets pulled**, and "deliberate" is not a rate limit when the same operator can dispatch it repeatedly while iterating on the workflow itself. **The cost of the change is recorded rather than glossed:** Phase 4's argument for the manual trigger was *correct* — work lands on `development`, `main` sees almost nothing, so a main-only boundary arrives **after** the promotion decision instead of before it — so the pre-merge macOS witness is now **unserved**, and the promotion rule ("no commit is promoted without a green hosted macOS result for that exact commit") is left **stated as written and currently unsatisfiable before a merge**, rather than quietly rewritten to something the surviving triggers can meet, because a rule edited to match what we can afford would hide the regression instead of showing it. **The coupled filter moved with the trigger, or it would have re-created the exact false green it was built to stop:** `utils/gate-status.sh` mirrors the boundary's `if:` to decide which hosted runs contain a macOS job, and a dispatch run now contains **none** — so a filter still accepting `workflow_dispatch` would report an ubuntu-only run as boundary evidence, the same defect as the original draft arriving from the opposite direction. Both assertions were rewritten to read the **specific deciding line** (the filter's `if ev ==`, the job's own `if:` extracted from its block) rather than the file, because `workflow_dispatch` remains a legitimate workflow-level trigger for the ubuntu full route and both files discuss it in prose — a whole-file `grep -q` would pass against a re-armed boundary on the strength of a comment, becoming decoration exactly when it was needed. **Witnessed in four directions with one failure per mutation** (both reverted → 2 fails; each reverted alone → exactly its own 1 fail; both fixed → 17/0), which required re-running the control under `TEST_SOFT_FAIL=1` after the first attempt exited at the first failure and left the second assertion unwitnessed — `test/baselines/GH-509-phase5-negative-control.md`. `ci-workflow` 40/0, `ci-route` 23/0, `gh509-gate-evidence` 17/0. Honest limit stated in the doc and the baseline: these assert what the workflow **declares**; proving GitHub no longer schedules a macOS job on dispatch would take a hosted dispatch, which is the spend being removed — the observable substitute is the invoice. → [GH-509-CI-MINUTE-BURN.md](PROJECT/2-WORKING/GH-509-CI-MINUTE-BURN.md) · [#509](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/509)
CHANGELOG.md-445-- **The command rail now names both gate forms, because a faster gate nobody knows about does not get run — and the reason it exists is on the invoice.** `ROUTER.md` previously listed `./validate.sh` alone; it now lists the sequential run as the canonical gate (**the only one that qualifies a claim**) alongside `./validate.sh --parallel 8` as the experimental fast self-check, with the ordering and the labels doing the work — an operator who reads only the first line still gets the correct default. The motivation is measured, not asserted: the org's actual August usage (`gh api orgs/.../settings/billing/usage`; the per-run billable-timing API reports 0min here and is unusable) is **$9.09 net of a $10 budget — Ubuntu 2,740 min at $4.44 net after the 2,000 included minutes, plus macOS 3-core 75 min at $4.65 net with no discount at all.** **75 macOS minutes cost as much as 2,740 Linux minutes**, so each `boundary-macos` dispatch is ≈$1.25–1.50 and the job's `workflow_dispatch`-or-push-to-`main` gating is doing real work — but nothing brakes repeated dispatches, and three landed on `feat/gh509-ci-macos-strategy` on 2026-08-13 alone. The Linux side is over quota on *volume*: every push to `development` and every PR into `development`/`main` starts a run (route-tiered, so not every run is the full gate), while a feature-branch push with no open PR costs $0. That is what makes the local gate's 946s → 184s the cost-relevant number rather than merely a convenience: the local run is the substitute for a hosted one, and it is now cheap enough to be used that way. Recorded on #509, which owns CI spend; #528 owns only the runner. → [#528](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/528) · [#509](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/509)
CHANGELOG.md-446-
--
CHANGELOG.md-448-
CHANGELOG.md-449-### Added
CHANGELOG.md:450:- **Local evidence became a thing the machine can read, not a claim in a chat message.** Three pieces. `utils/gate-record.sh` writes `.gate-evidence/<sha>.txt` after a full green and **refuses on a dirty tree** — a record keyed to a commit while uncommitted edits sit in the tree attests to a state that was never tested, which is worse than no record because it reads as evidence; untracked files count, since that is the common case (a new test beside the code it covers). It was **extracted from `ci-local.sh` specifically so the refusal is testable**: inlined, the only way to exercise it was a ~15-minute suite run, so it would have shipped asserted-by-comment — the exact thing this repo keeps paying for. `ci-local.sh --probe` strips `codex`/`agy`/`aider` from PATH to simulate a fresh Mac where XYZ was just installed, which is #380's actual audience and the class that produced all three of #520's failures; it **aborts if the binaries survive the strip**, because a probe that silently ran with them present reports green and means nothing. `utils/gate-status.sh` is the reading surface — local record, hosted macOS boundary with **distance**, and the canary line — because with no branch protection available CI here is a detector, and a correct detector nobody reads buys nothing. **Two real bugs surfaced by the new tests and recorded rather than quietly fixed:** the status tool's first filter matched any successful push/dispatch and therefore reported a push to `development` — an ubuntu canary run that never touches macOS — as **boundary evidence**, meaning the tool built to prevent false promotion evidence was manufacturing it; the filter now mirrors the boundary job's own `if:` and a test pins them together. And `git rev-parse HEAD` prints the literal string `HEAD` on stdout in a repo with no commits, so both scripts would have written `.gate-evidence/HEAD.txt` — now `--verify`. The record states **on its own face** that it is not promotion evidence, and a test fails if that line is removed, because the file is what a future reader will find and reason from. `test/gh509-gate-evidence.sh` 17/0, registered in `validate.sh` (191/191). → [#509](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/509)
CHANGELOG.md-451-- **Pushes to `development` are classified instead of blanket-full — the 72% of the bill GH-509 identified and then exempted.** Measured over 60 runs in ~24h: **37 pushes to `development`, every one on the full route, ~396 of ~551 billed minutes.** Phase 1 routed pull requests and cut their average from ~16 min to 6.1 — it worked, on the other 28%. `utils/ci-route.sh` now classifies `push` from its pushed range exactly as it classifies a PR from its diff; `workflow_dispatch` and `schedule` stay unconditionally full, because a manual dispatch is someone asking for the whole gate and answering with a routed subset answers a different question. **Three ways a range can be unusable all fail closed** — an all-zeros `before` on a new branch, an unreachable `before` after a force-push, and no range concept at all — each by handing the classifier an empty path list, reusing the zero-path branch that already had its own test rather than inventing a second fail-closed rule needing its own proof. **The rename loophole is closed, and the fix is a flag, not logic:** with git's default rename detection `--name-only` prints only a rename's *destination*, so a renamed regression test read as an ordinary changed file that still exists and never reached `ci-route.sh`'s fail-closed branch — while that branch's own comment claims to cover "deleted/renamed". Deletion reached it; rename never did. The collection command now passes `--no-renames`. **The control drives a real `git mv` through the workflow's own command** rather than asserting on the classifier, because the classifier was never wrong — it behaves correctly for whatever paths it is handed, and the defect was in which paths it was handed. Both directions are pinned: a renamed test selects full, and the same file merely *edited* does not, so the rule is not a blanket that would pass the rename case for the wrong reason. A first assertion records the premise itself (`plain --name-only reports ONE path for a rename`) so a future git change makes the guard say its premise is stale instead of silently becoming decoration. `ci-route` 15 → 23, `ci-workflow` 37 → 40, every new guard witnessed red (`test/baselines/GH-509-phase3-negative-control.md`). One pre-existing assertion was **updated rather than deleted** — it pinned the literal `utils/ci-route.sh pull_request`, which legitimately changed to `"$EVENT_NAME"`; the invariant it protects (routing is delegated to the tested classifier, never reimplemented inline in YAML where it would have no test) is unchanged and still asserted. → [#509](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/509)
CHANGELOG.md-452-- **A macOS promotion boundary — the first CI job whose green says anything about what XYZ actually ships.** `boundary-macos` runs on `macos-latest` and invokes `RELAY_SELF_SUFFICIENCY_SKIP=1 ./validate.sh` **directly, with no skip list**. That single choice closes the defect where the hosted "full" route scraped `TESTS` out of `validate.sh` with a `.sh`-only expression and therefore could never see `test/test_python_layer.py` — **20 tests over the authoritative implementation since GH-264, which had never run in CI at all**. There is no second list to keep honest, and an assertion fails if one appears. **Triggers are `push` to `main` plus `workflow_dispatch`, and never `pull_request`** — hosted macOS bills roughly 10× Linux, so putting it on routine traffic would restore the original spend at ten times the rate, which is the failure GH-509 exists to prevent; the boundary is affordable *because* it is rare. `workflow_dispatch` is the trigger that will actually get used: work lands on `development` and `main` sees almost nothing, so a main-only boundary would always arrive *after* the promotion decision rather than before it. **A precision limit is encoded in the job rather than discovered later** — `workflow_dispatch` targets a *ref*, not an arbitrary commit, so the job qualifies whatever that ref points at when dispatched; it therefore prints `MACOS-BOUNDARY: green|red <sha>` into the job summary, because the promotion rule compares against a recorded commit, not a remembered run. Bounded at 45 minutes, since an unbounded hang on a 10× runner is the failure discovered on an invoice. `test/ci-workflow.sh` 30 → 37, with **four mutations producing exactly one failure each** and restoring clean — one-failure-each being the property that separates a precise assertion from a blunt one (`test/baselines/GH-509-phase4-negative-control.md`). Still open and deliberately not claimed: no hosted macOS run has happened yet, and the entire promotion rule rests on that witness. → [#509](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/509)
CHANGELOG.md:453:- **Agent2Agent documents Doorbell mode — `watch` as a wake mechanism, not a poll, for bridging two live interactive sessions hands-free.** On a host that re-invokes the session when a background command exits (Claude Code's background Bash tasks), each seat launches `watch --timeout 0` as a background task after its one pasted join; the session sleeps until it owns `NEXT:`, wakes with the exit, composes its turn with the session's full accumulated context, sends, and re-arms in the same turn. This is docs-only — no helper change; `watch` already blocks, never writes, and never locks, which is exactly what makes it usable as a doorbell. The section makes re-arming part of the send step rather than optional hygiene, because an un-re-armed doorbell downgrades the seat to manual with no error, indistinguishable from the other participant still thinking. Seats degrade independently: doorbell, foreground `watch`, `drive`, and manual turns coexist in one roster. Where `drive` runs a fresh headless command per turn under one-hour/six-turn caps, doorbell turns are answered by the ongoing live session, so no subprocess caps apply — ownership enforcement in `send`/`close` is unchanged and remains the only write path. Hardened by a 3-round driven agy relay review (`relay-system/2026-08-12/agent2agent-doorbell-agy-review.md`, Approved r3 with every claim re-verified against the script): a `take-turn` join routes straight to send-and-re-arm, dead-watch recovery keys on the missing `DECISION:` line rather than exit code (a timeout also exits non-zero but still prints its `DECISION`), no re-arm after `close`, and `watch`-granted turns are admitted to the send gate, which had been `join`-only. **Contributor feedback on PR #524 then converted re-arming from documented discipline into tool-enforced protocol**: a `watch` that exits `take-turn` now also prints a `REARM:` line — the exact, self-contained relaunch argv (absolute script path + `--root`, shell-quoted for paths with spaces) — so the waking session has the command in front of it at the moment it needs it instead of recalling a doc; a `closed` or `timeout` exit deliberately prints none, so a dead discussion cannot invite a reflex re-arm. `test/agent2agent.sh` asserts both directions (REARM present and self-contained on take-turn, absent on closed), observed **2 red** against the pre-fix source. → [#510](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/510)
CHANGELOG.md-454-
CHANGELOG.md-455-### Changed
--
CHANGELOG.md-467-### Added
CHANGELOG.md-468-- **Agent2Agent now has two explicit operating levels: byte-preserving `watch` and bounded, opt-in `drive`.** `watch` polls the durable discussion at a 150-second default cadence and exits only for ownership, closure, timeout, or interruption; it creates no locks and executes nothing. `drive` requires an operator-approved argv command after `--`, holds one crash-releasing participant/discussion lane, supplies a compact turn prompt on stdin, and requires an observable advance and handoff after the command returns. Time and turn caps default to one hour and six turns. Focused coverage includes delayed ownership, non-turn timeout, contention, command failure, no-advance refusal, interruption, closure, and 3+ routing. → [#510](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/510)
CHANGELOG.md:469:- **Agent2Agent turns the original two-window file relay into a compact, model-neutral rendezvous for two or more live sessions.** A first session seeds turn 1 and receives the pasteable prompt `Join XYZ agent2agent #123456 as agent number two to discuss: "subject line here"`; every later handoff prints the same shape for whichever roster member owns `NEXT:`. The additive `skills/agent2agent/` surface supplies `start`, read-only `join`, turn-checked `send`, and terminal `close` operations, using collision-checked six-digit IDs, exclusive per-discussion locks, and atomic writes under the existing `relay-system/<date>/` archive. The current file-driven poller consumes `agent1`/`agent2`/`agentN` without modification, so Tick's event schema, relay containment, and the Producer/Reviewer workflow stay untouched. `test/agent2agent.sh` covers exact invitations, 3+ routing, collisions, ambiguous/missing discovery, read-only joins, byte-preserving refusals, close behavior, spaced paths, poll interoperability, and dual Claude/Codex installation. → [#497](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/497)
CHANGELOG.md-470-- **GH-384's crash-recovery tool shipped without the one fixture its own litmus test demanded, so it was unproven in exactly the way that issue warns about.** `marathon-recover.sh` landed in Nightwatch wave 3 and nothing in `validate.sh` exercised it — while the capture doc had written, in advance, "**existence is not detection**: `marathon-detail.sh` already prints `STATUS:`/`NEXT:` lines and recent tick events, so a script that does the same thing under a new name satisfies nothing here." `test/gh384-crash-recovery.sh` builds the fixture that doc specifies: **two phases in ONE repo and one run** — one Approved with a `marathon.phase.approved` event, one still Open with a landed `relay(MARATHON-UNGATED-TURN): …` commit and no event — and requires their output to differ. The report is **sliced per phase** before matching, because a whole-output `grep UNGATED` passes equally well for a tool that flags every phase, which is the false-positive direction the issue names as a fail "even if the tool runs". Both directions are pinned: the ungated phase must carry `UNGATED COMMIT` + `UNVERIFIED` naming its actual commit, and the gated phase must **not**. An inverse control removes the approval event and requires the same phase's verdict to flip, proving it reads the event log rather than the phase name or the `STATUS:` line. Read-only is **tested, not trusted** — HEAD, `git status` and the full file tree are compared before and after, asserted first, because a tool that mutates the repo it is diagnosing after a crash is worse than no tool. Lock reporting is covered in both states that matter (a dead pid must read STALE, a live one LIVE). **The negative control is a mutation pair rather than a pre-fix replay**, because the tool already existed and the missing thing was the test: detection removed → 2 red, verdict decoupled from the approval event → 1 red, restored → 19/0 (`test/baselines/GH-384-negative-control.md`). One assertion of mine was wrong rather than the code — a case-sensitive grep for "ungated commit" failed against a README that documents all three required elements; it now checks the substance (name the tool, explain the finding, give the remedy, cover the stale lock). → [#384](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/384)
CHANGELOG.md-471-
--
CHANGELOG.md-498-
CHANGELOG.md-499-### Fixed
CHANGELOG.md:500:- **`marathon-closeout.sh` commits the whole dirty working tree, not the lane's write-set.** The Nightwatch closeout swept **20 unrelated files / 10,397 insertions** into the lane's PR — four foreign `PROJECT/1-INBOX` capture docs, two stale pre-GH-484-rename `phases/` run outputs, and fourteen `relay-system/` consult transcripts belonging to the GH-484 and GH-448 lanes. The driver had printed `WARNING: workspace is not clean` naming those exact eight paths **one line earlier** and then committed them anyway: the warning and the commit disagree, and the commit wins. Reverted on the branch with `git rm --cached` so every file stays on disk in its prior untracked state; verified 20/20 in both directions with `comm`, touching no `gh358` or `marathon-system/` path. The closeout defect itself is on the triage list, not yet filed, per the standing no-new-issues gate.
CHANGELOG.md-501-
CHANGELOG.md-502-## 2026-08-09
--
CHANGELOG.md-672-- **GH-280: Aider+Qwen reliability investigation concluded — root cause found and fix confirmed.** A live GH-268 Wave-1 exercise against the real production repo and the real `qwen3.8-max-preview` endpoint caught the first real failure transcript of the whole investigation: Aider auto-selects `whole` edit format for unlisted/custom model ids, but Qwen emits standard unified diffs regardless, which Aider silently discards as "no tracked changes" — the actual explanation for the historical ~86% aider-qwen failure rate, not general model unreliability. Re-running with `AIDER_FLAGS="--edit-format diff"` forced took the same task from 0/3 real edits to a 90%-complete, correct implementation landing in round 1, confirming the fix. Getting to this transcript required first closing a real observability gap: `aider-turn.sh` (and, since `XYZ_PYTHON` defaults on, the actually-executing `utils/py/aider-turn.py` and `utils/py/agy-turn.py`) were never using the GH-161 persistent-log helper, so every prior investigation round genuinely could not have captured a failure log — fixed in [#288](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/288)/[#290](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/290). Also found and fixed along the way, independent of Qwen: a fully-retired OpenRouter default model id (`openrouter/anthropic/claude-3.5-sonnet`) that silently broke any plain `aider`/`consult` call omitting both `AIDER_MODEL` and `AIDER_OPENAI_API_BASE` — [#291](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/291), no separate issue filed. **Recommendation:** codex+agy remains the default builder pairing; Aider+Qwen is usable as a fallback with `--edit-format diff` and a generous timeout set explicitly. A separate, genuinely new gap was surfaced by the same session and filed on its own: `swarm-preflight.sh`'s suggested marathon invocations never default to `RELAY_WORKTREE_ISOLATION=1` — [#294](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/294) (filed, not yet fired). → [GH-280 findings](PROJECT/1-INBOX/GH-280-AIDER-QWEN-VS-SONNET-INVESTIGATION.md) · [marathon plan](PROJECT/2-WORKING/MARATHON-PLAN-2026-07-23-GH279-GH280-AIDER-QWEN-FOLLOWUP.md) · [#280](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/280)
CHANGELOG.md-673-- **GH-281 Sentinel Debug Flywheel — Tier-1 shipped end-to-end + full Tier-2 overlay landed (transparent code, inert by default).** Carved the risk-2 Tier-1 Stage-0 slice from the risk-4 umbrella, `swarm-preflight → ready`; marathon-built it (Codex builder + Agy reviewer), the deterministic gate caught a test-hygiene defect the review missed, then a 3-round `/relay-xyz` Codex adversarial review closed 2 blockers — a network-guard never wired over the real capture scripts, and `finding-new.sh` emitting invalid JSON on control bytes (a defect that lived in the issue's own verbatim source, patched upstream) — **Approved**, merged to `development` in [#285](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/285). Then, orchestrator-side, wired the six §1.3 `marathon-drive.sh` debug-capture hooks (opt-in `XYZ_DEBUG_LOG`, default OFF, byte-identical when off) with `test/sentinel-driver-hooks.sh`. On an operator design call, built the **full Tier-2 triage overlay** (`sentinel-overlay/`: reader → local-Gemma classify → draft PDDA doc → file issue → nightly batch → PR-emit → adversarial red-team → morning report) as **visible in-repo reference code** for transparency, with all call-home gated behind a **gitignored `runtime.env`** so a downstream clone is completely inert (no network/LLM/GitHub) until the operator opts in — enforced by a single `sentinel_active` gate, egress-only wrappers, a static guard, and `test/sentinel-overlay.sh` proving zero egress with no config. Agy `/relay-xyz` QA **Approved** both items. Full `validate.sh` green throughout. → [Tier-1](PROJECT/2-WORKING/GH-281-SENTINEL-TIER1-STAGE0.md) · [Tier-2](PROJECT/2-WORKING/GH-281-SENTINEL-TIER2-OVERLAY.md) · [#281](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/281)
CHANGELOG.md:674:- **GH-275/GH-276: long-term residual-risk program reconciled and converted into an actionable six-phase checklist, with a separate weekly control loop.** After a requested 30-minute wait, re-read the live `development` branch, GitHub issue state, ROADMAP, CHANGELOG, and active project docs; rewrote [#275](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/275) to distinguish shipped controls from residual gaps, cap committed work at three proof-sized lanes, define inherent-vs-residual risk, preserve separated grading, and gate advanced autonomy behind containment/recovery evidence. Created [#276](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/276) as a dated-comment weekly reconciliation checklist, not a competing plan or auto-fire path. Added issue-first inbox captures and ROADMAP pointers. Final snapshot incorporates the concurrently landed GH-273 closeout (`111b552`): all five GH-273 phases shipped; #274 remains the truthful-retry residual gap. → [GH-275 capture](PROJECT/1-INBOX/GH-275-LONG-TERM-RISK.md) · [GH-276 capture](PROJECT/1-INBOX/GH-276-WEEKLY-RISK-RECONCILIATION.md)
CHANGELOG.md-675-- **GH-273: Phase 4 SHIPPED and the whole plan is CLOSED — `--post-approve-cmd` lands in both `marathon-drive.sh` and `marathon_drive.py`, symmetric to the existing `--pre-advance-cmd`.** Fired via `swarm-preflight → marathon-drive` with `--phase-id gh273-phase4`. Default unset (zero behavior change for every existing caller); when set, runs exactly once, only after `marathon.phase.approved` is already logged and green telemetry already emitted — never gating the approval itself. A failing `--post-approve-cmd` does not retroactively un-approve the phase; it exits 9 and writes an `ESCALATION.md` with reason `post-approve-failed`. 14 new `test/marathon-drive.sh` cases (7 per runtime) cover help-text, omitted-flag parity, a passing hook running exactly once, and a failing hook's exit code + preserved approval + escalation reason — 126/126 full file. The relay itself timed out before an agy review turn (a large dual-runtime edit), but Codex's single committed turn was already correct and complete, verified by reading the diff directly rather than trusting the gate. The pre-advance gate then failed for two genuine reasons (not the Phases 0-3 flake): (1) a new `--help` check invoked the driver directly instead of through the file's `run_driver()` wrapper, missing the `MARATHON_ROOT=` marker `test/marathon-root-audit.sh` requires on every driver invocation — fixed by adding it; (2) the new `eval "$POST_APPROVE_CMD"` correctly tripped `test/security-scan.sh`, same class as the already-baselined `eval "$PRE_ADVANCE_CMD"` a few lines above — reviewed (same trust model, an operator-supplied CLI flag, not attacker input) and added the symmetric baseline entry. Full `validate.sh` green after both fixes. **All 5 phases of GH-273 are now shipped; doc moved to `3-COMPLETED`, issue closed.** A real harness bug found along the way (same-phase-id retry clobbers a phase's Approved record) was split out and filed separately as [#274](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/274) — not fired, tracked as its own follow-on. → [#273](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/273) · [GH-273-MARATHON-CLOSEOUT-AUTOMATION.md](PROJECT/3-COMPLETED/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md)
CHANGELOG.md:676:- **GH-273: Phase 3 SHIPPED — `relay-automation/marathon-closeout.sh` extracts the deterministic post-marathon git ceremony into one script.** Fired via `swarm-preflight → marathon-drive` with `--phase-id gh273-phase3`. Given this phase can `git push`/create/merge a PR — materially higher stakes than Phases 0-2's prompt/config files — the contract required `--dry-run` as a first-class mode and mandated the test suite stub `git`/`gh` (never touch this repo's real remote or GitHub during the build/test turn); verified both directly before closing out, not just trusted the gate. `marathon-closeout.sh`: stage+commit+push → `gh pr create` → `gh pr checks` (red → exit 4, halt before merge) → `gh pr view --json mergeable` (not `MERGEABLE` → exit 4, halt) → `gh pr merge` → switch to `development` → `git pull --ff-only`; command failures normalize to exit 3, argument/precondition errors to exit 2. `test/marathon-closeout.sh` PATH-shadows `git`/`gh` with fake binaries inside a disposable `mktemp` scratch repo — 18/18 pass (dry-run inertness, happy path, red-checks halt, unmergeable halt, command-failure/usage exit codes, `bash -n` clean), confirmed standalone. Same flaky-gate pattern as Phases 0-2 (4 for 4 now); confirmed clean, closed out manually. → [#273](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/273) · [GH-273-MARATHON-CLOSEOUT-AUTOMATION.md](PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md)
CHANGELOG.md-677-- **GH-273: Phase 2 SHIPPED — `.claude/loose-ends-sequence.md` gives this repo a real custom end sequence.** Fired via `swarm-preflight → marathon-drive` with `--phase-id gh273-phase2`. Contract was grounded in a direct read of `~/.claude/skills/loose-ends/SKILL.md` rather than inferred: the manifest mechanism already existed (project-local `.claude/loose-ends-sequence.md` takes precedence over the global one, `### *` heading, `- cmd` bullets, paths resolved relative to the manifest's own directory) — Phase 2 only needed to author the file. Codex got the path-resolution subtlety right unprompted: bullets are `../utils/pdda/pdda.sh run` and `../utils/roadmap-dashboard.sh`, correctly relative to `.claude/` (the manifest's directory), not repo root. The third bullet is a reminder that `PROJECT/2-WORKING` docs move to `3-COMPLETED` only once `marathon-cleanup` classifies them `VERIFIED-COMPLETE`, never on a bare status-word edit. Same flaky-gate pattern as Phases 0-1 (`test/xyz-harness-hooks.sh`'s pre-existing "relay green count" assertion — 3 for 3 now, unrelated to any of the three builds); confirmed clean each time, closed out manually. → [#273](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/273) · [GH-273-MARATHON-CLOSEOUT-AUTOMATION.md](PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md)
CHANGELOG.md-678-- **GH-273: Phase 1 SHIPPED — `/pre-marathon` and `/post-marathon` slash commands are live.** Fired via `swarm-preflight → marathon-drive` with `--phase-id gh273-phase1` (a distinct id per fire, applying the GH-274 workaround learned from Phase 0's collision). `.claude/commands/pre-marathon.md` delegates to the `marathon-triage` skill for reconciliation/ranking/waves (does not reimplement it), additionally sweeps `PROJECT/2-WORKING` and `phases/*/` for stale phase dirs and orphaned `ESCALATION.md` files, dry-runs every ready plan, and requires explicit operator confirmation before firing — preserving `marathon-triage`'s no-fire boundary. `.claude/commands/post-marathon.md` sequences commit+push (incl. manual edits) → PR → merge if green → pull/switch to `development` → close resolved issues → move docs to `3-COMPLETED` → `utils/pdda/pdda.sh run` → `/loose-ends`. Same flaky pre-advance gate false-failure as Phase 0 (`test/xyz-harness-hooks.sh`'s pre-existing "relay green count" assertion, untouched by this build); confirmed clean on an isolated re-run (61/61) and a full `validate.sh` re-run (exit 0); closed out manually rather than risk a third `marathon-drive` invocation against the now-`done` token. → [#273](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/273) · [GH-273-MARATHON-CLOSEOUT-AUTOMATION.md](PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md)
--
CHANGELOG.md-680-- **GH-273: Phase 0 SHIPPED — the `UserPromptSubmit` skill-nudge hook is live.** Fired via `swarm-preflight → marathon-drive` (Codex builder, agy reviewer, Approved after 2 turns): `relay-automation/hooks/skill-nudge.sh` (89 lines, follows the `xyz-vendor-reminder.sh` fail-open/opt-out-env/exit-0-always contract) matches only the marathon-lifecycle keyword table from the plan doc — "add ... to marathon"/"fire the marathon"/"preflight sweep/all"/"dry-run each plan" → nudges `marathon-triage`; "commit and push" + ("close issues"/"move to 3-completed"/"PDDA sweep") in the same prompt → nudges `loose-ends` + `marathon-cleanup`. Unrelated prompts stay silent. Wired into this repo's `.claude/settings.json` alongside the existing `PreToolUse`/`SessionStart` hooks. 14 new cases in `test/xyz-harness-hooks.sh`, all passing. **Process note, worth recording:** the `bash validate.sh` pre-advance gate initially reported FAILED, but the actual red was a pre-existing flaky assertion in the same test file ("relay green count", last touched by the unrelated GH-232 fix) — none of the 14 new nudge assertions failed. Confirmed flaky, not regressive: the test file alone re-ran 61/61 clean, and a full `validate.sh` re-run immediately after was exit 0 with nothing failing. Re-invoking `marathon-drive` to retry the gate then hit a real harness limitation — the `MARATHON-P1-TURN` tick token was already `status: done` from the successful first run, so it couldn't be reopened; the retry re-rendered `phases/p1/RELAY.md` back to a fresh `STATUS: Open` template and failed immediately after (exit 1), discarding the accurate Approved record. Recovered by `git revert`ing that render commit (restoring the true Approved state) and closing the phase out manually rather than re-driving a third time — the code was already correct and committed; only the harness's own bookkeeping needed the fix. Full detail: `phases/p1/ESCALATION.md` § Resolution. → [#273](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/273) · [GH-273-MARATHON-CLOSEOUT-AUTOMATION.md](PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md)
CHANGELOG.md-681-- **GH-273: Phase 0 added — a `UserPromptSubmit` skill-nudge hook, folded into the plan doc so the design is documented and searchable before it's built.** Operator raised: could a hook remind them that skills like `marathon-triage`/`loose-ends`/`marathon-cleanup` already exist, so they stop hand-typing the ceremony those skills already automate? Confirmed the mechanism is already live in this repo's own `.claude/settings.json` (2 `PreToolUse` guards + a `SessionStart` reminder, `relay-automation/hooks/xyz-vendor-reminder.sh`) and picked `UserPromptSubmit` over another `SessionStart` entry — a per-prompt nudge matches the *specific* thing being typed, where a once-per-session reminder goes stale after the first screen. New Phase 0 in `GH-273-MARATHON-CLOSEOUT-AUTOMATION.md`: `relay-automation/hooks/skill-nudge.sh`, following the `xyz-vendor-reminder.sh` fail-open/opt-out-env/exit-0-always contract, matched against a narrow marathon-lifecycle keyword table (documented in the doc, not just the script) so it stays silent on unrelated prompts. Preflight contract redrafted to target Phase 0 (was Phase 1); frontmatter `phases: 4→5`, `effort: 4→5`. → [#273](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/273) · [GH-273-MARATHON-CLOSEOUT-AUTOMATION.md](PROJECT/1-INBOX/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md)
CHANGELOG.md:682:- **GH-273: marathon pre-flight/post-flight ceremony automation — planned, not yet built.** A Fable 5 web app's analysis of ~583 logged Claude Code prompts (`PROJECT/1-INBOX/LESS-TYPING.md`, source: `0. Claude Prompts.md`) found two heavily repeated manual sequences: pre-marathon (capture → add to plan → preflight sweep → cleanup → dry-run → fire, ~25 occurrences) and post-marathon (commit/push → PR → merge → pull/switch → close issues → move docs → PDDA sweep → Slack, ~45 combined). Verified against the raw corpus (78 commit+push mentions, 12+ "add to marathon" phrasings, 8 "move to 3-COMPLETED", 6 "close issue", 5 "PDDA sweep" across 583 entries) — the repetition is real. **Cross-checked against existing tooling before accepting the recommendation as-is:** the pre-marathon half largely overlaps `skills/marathon-triage/SKILL.md` (which already reconciles/ranks/preflights, and deliberately refuses to fire), so `/pre-marathon` will wrap it rather than reimplement it; the post-marathon half is a genuine gap — `marathon-cleanup` is archive-only and `loose-ends` is generic, neither does the PR→merge→close-issues chain. 4-phase plan drafted: `/pre-marathon` + `/post-marathon` slash commands → per-repo `loose-ends-sequence.md` manifest → `marathon-closeout.sh` extraction → symmetric `--post-approve-cmd` harness flag (mirrors `marathon_drive.py`'s existing `--pre-advance-cmd`). Filed, captured, ledgered, and folded into today's marathon queue (Wave 1, `MARATHON-PLAN-2026-07-22.md`) — no phase fired yet. → [#273](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/273) · [GH-273-MARATHON-CLOSEOUT-AUTOMATION.md](PROJECT/1-INBOX/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md)
CHANGELOG.md-683-
CHANGELOG.md-684-### Changed
--
CHANGELOG.md-921-
CHANGELOG.md-922-### PDDA housekeeping: 2-WORKING sweep + close #48
CHANGELOG.md:923:Closed **#48** (marathon-plan zone model generalized — landed via PR #125; operator gave the closure go-ahead). Applied PDDA housekeeping to `PROJECT/2-WORKING/`: moved **16** completed items to `3-COMPLETED/` — the eight closed-issue capture docs (**GH-106, GH-107, GH-108, GH-116, GH-117, GH-124, GH-132, GH-48**) and eight spent/superseded planning artifacts (**MARATHON-PLAN 07-01, 07-02, 07-03, 07-03-A-SERIAL, 07-03-B-PARALLEL, 07-04-C-RELIABILITY, 07-05**, and **PR-REVIEW-QUEUE-2026-07-02**). Repointed every moved-doc link in [ROADMAP.md](ROADMAP.md)/[CHANGELOG.md](CHANGELOG.md) `2-WORKING → 3-COMPLETED` and regenerated the dashboard; PDDA run **all checks passed** (0 errors). 2-WORKING now holds only genuinely-active items: **GH-138** (open), the `briefs/gh-61` brief (open), `ADVERSARIAL-HARDENING.md` (Active track, idle), `RELAY-TO-ISSUE-SKILL.md` (shipped, pending a live `gh` end-to-end test), and the `blank.md` PDDA placeholder. PDDA flagged the last two as 5-day-stale with a suggested park to `4-MISC` — left for an operator call rather than auto-parking an Active/shipped-pending doc.
CHANGELOG.md-924-
CHANGELOG.md-925-### GH-137 swarm-preflight containment fix (marathon lane) + ledger drift reconciliation
--
CHANGELOG.md-976-
CHANGELOG.md-977-### Perplexity Sonar via OpenRouter shipped as the second deep-research backend (#129)
CHANGELOG.md:978:Built the backend GH-87's seam reserved, in an isolated worktree on branch `gh-129-perplexity-openrouter`. `relay-automation/deep-research.mjs` gains `--provider agy|openrouter` (default `agy` — the existing path is byte-identical, all 23 original assertions untouched) and a `runOpenRouter` backend: Node global `fetch` (stdlib only, no new deps) against `{OPENROUTER_BASE_URL:-https://openrouter.ai/api/v1}/chat/completions`, `Authorization: Bearer $OPENROUTER_API_KEY`, model `perplexity/sonar` (`DEEP_RESEARCH_OPENROUTER_MODEL` override), `--search-context-size` mapped to Perplexity's native `web_search_options.search_context_size`, `--temperature`/`--max-tokens` passed through, AbortController honoring `DEEP_RESEARCH_TIMEOUT_MS`. Citations normalize in preference order `message.annotations[].url_citation` → Perplexity `citations[]` passthrough → the existing bare-URL scan; typed fail-closed errors gain `missing_api_key` (never a silent cross-provider fallback). `test/deep-research.sh` grew a stub HTTP server injected via `OPENROUTER_BASE_URL`: **45/45** (22 new assertions covering request shape incl. auth header + `web_search_options`, all three citation paths, model override, HTTP 500 / non-JSON / empty / timeout). The stub's fake `test-key` literal is hand-baselined in `security-scan-baseline.txt` per the GH-64 convention; full `validate.sh` exit 0. **Applied GH-124's lesson before merge this time: one live smoke run against real OpenRouter→Perplexity Sonar returned in 4.5s with 15 real citations (titles intact), normalized correctly.** README row added documenting both backends. Write-set overlaps **#124** — its lane fires only after this merges. **Merged same-day via PR #130 (`79395ee`) after an independent headless agy relay review — VERDICT: PASS, zero findings ([thread](relay-system/2026-07-04/gh129-perplexity-openrouter-review.md), driven with `relay-drive.sh --review-once --artifact-file` on the branch diff, since driven turns run in a worktree of ROOT@HEAD where branch-only commits are invisible); #129 auto-closed, branch + worktree deleted, doc moved to `3-COMPLETED`.**
CHANGELOG.md-979-
CHANGELOG.md-980-### Perplexity-via-OpenRouter deep-research backend captured (issue-first intake, #129)
--
CHANGELOG.md-1744-
CHANGELOG.md-1745-### Issue-first SOP — GitHub issues are now the default front door for substantive work
CHANGELOG.md:1746:Made it canonical that every project plan and every non-trivial bug/fix opens a **GitHub issue first**, then gets a `GH-<number>` in-repo pointer doc — the issue is the machine-queryable signal stream, the `PROJECT/**` doc stays the execution surface of record. This is a policy *flip*, not new machinery: [PDDA.md → "GitHub issue intake"](PROJECT/PDDA.md) already owned the format/lifecycle; the change is from "when an issue should be tracked" (optional intake) to issue-first SOP. Floor is a concrete, countable test (operator-set): **any change beyond a 2–3 line code fix** opens an issue; **exempt** = ≤2–3 line fixes, typos, path repoints, doc-only one-liners, formatting, which commit directly. The local plan doc is **always named after its issue** with a very short slug — `GH-<number>-VERY-SHORT-DESC.md` (e.g. `GH-1234-SHOWME-COMMAND.md`). Applies to new efforts going forward; in-flight docs are not backfilled. Encoded in [ROUTER.md](ROUTER.md) (canonical rule + routing hint) and [PROJECT/PDDA.md](PROJECT/PDDA.md).
CHANGELOG.md-1747-
CHANGELOG.md-1748-### marathon-drive.sh — cross-model BUILDER routing (agy/codex builders, not just Claude)
--
PROJECT/PDDA.md-250-
PROJECT/PDDA.md-251-- **Filename:** `GH-<number>-VERY-SHORT-DESCRIPTION.md` — the local plan doc is always named after
PROJECT/PDDA.md:252:  its GitHub issue (e.g. `GH-1234-SHOWME-COMMAND.md`, `GH-11-CROSS-REPO-TARGETING.md`). Keep the
PROJECT/PDDA.md-253-  description to ~2–4 words; the issue number is the real key, the slug is just a human hint.
PROJECT/PDDA.md-254-  SCREAMING-KEBAB to match the other inbox docs; no zero-padding — mirror the GitHub issue number.
--
PROJECT/3-COMPLETED/GH-101-FEASIBILITY-STUDY-SCRIPT-RUNNER.md-24-| What was just completed | What's next |
PROJECT/3-COMPLETED/GH-101-FEASIBILITY-STUDY-SCRIPT-RUNNER.md-25-|---|---|
PROJECT/3-COMPLETED/GH-101-FEASIBILITY-STUDY-SCRIPT-RUNNER.md:26:| **Qualification Ladder Complete (2026-08-20):** Tests 1, 2, and 3 passed and verified. Programmatic tool mode promoted to Production-Ready (A-Grade) across `consult.py` and `relay_drive.py` with full fail-closed sandboxing, throwaway worktree isolation, and committed test receipts. | Final verification gate & issue closeout. |
PROJECT/3-COMPLETED/GH-101-FEASIBILITY-STUDY-SCRIPT-RUNNER.md-27-
PROJECT/3-COMPLETED/GH-101-FEASIBILITY-STUDY-SCRIPT-RUNNER.md-28-## Phased Qualification Gate Checklist (Canonical Definition of Done)
--
PROJECT/3-COMPLETED/GH-101-FEASIBILITY-STUDY-SCRIPT-RUNNER.md-56-- **Parent Research Track:** [GH-94](../../PROJECT/3-COMPLETED/GH-94-PROGRAMMATIC-TOOL-CALLING.md) · [#94](https://github.com/HiQS-Suite/XYZ-forge/issues/94) · [PR #100](https://github.com/HiQS-Suite/XYZ-forge/pull/100)
PROJECT/3-COMPLETED/GH-101-FEASIBILITY-STUDY-SCRIPT-RUNNER.md-57-- **Unified Telemetry Contract:** [GH-102](../../PROJECT/3-COMPLETED/GH-102-UNIFIED-TELEMETRY-TOOLING.md) · [#102](https://github.com/HiQS-Suite/XYZ-forge/issues/102)
PROJECT/3-COMPLETED/GH-101-FEASIBILITY-STUDY-SCRIPT-RUNNER.md:58:- **Discussion Sync:** [Relay #709506](../../relay-system/2026-08-20/709506-agent2agent-gh-102-telemetry-architecture-gh-101-test-2-consult-dogf.md)
--
PROJECT/2-WORKING/GH-35-TEST-TIER-ROUTING.md-81-
PROJECT/2-WORKING/GH-35-TEST-TIER-ROUTING.md-82-1. **The registry** (`utils/ci-route.sh`): the issue's 7 subsystems (hq, releases, telemetry,
PROJECT/2-WORKING/GH-35-TEST-TIER-ROUTING.md:83:   ate, swe-diagram, pdda, agent2agent) as one declarative mapping — paths in `subsystem_of()`,
PROJECT/2-WORKING/GH-35-TEST-TIER-ROUTING.md-84-   suites in `SUBSYSTEM_TESTS_<name>` — emitting `tier=`, `tier2_subsystems=`, `tier2_tests=`,
PROJECT/2-WORKING/GH-35-TEST-TIER-ROUTING.md-85-   `tier_reason=` alongside the existing GH-509 route keys. `utils/ci-route.sh subsystems [name]`
--
PROJECT/2-WORKING/GH-35-TEST-TIER-ROUTING.md-125-   routing contract's own evidence never weakens its own gate. CI behavior is unchanged; only
PROJECT/2-WORKING/GH-35-TEST-TIER-ROUTING.md-126-   the local push boundary got narrower.
PROJECT/2-WORKING/GH-35-TEST-TIER-ROUTING.md:127:2. **`utils/pdda/**` moved from blanket-full to the pdda subsystem, and `skills/agent2agent`
PROJECT/2-WORKING/GH-35-TEST-TIER-ROUTING.md:128:   code moved to the agent2agent subsystem** — both per the issue's Tier-2 matrix, changing the
PROJECT/2-WORKING/GH-35-TEST-TIER-ROUTING.md-129-   pre-GH-35 posture pinned in `test/ci-route.sh` (expectation updated in the same commit, with
PROJECT/2-WORKING/GH-35-TEST-TIER-ROUTING.md-130-   the reason in a comment). Consequence to reconcile in Phase 3: a hosted PR touching only
--
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-2-gh_issue: 124
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-3-source: https://github.com/HiQS-Suite/XYZ-forge/issues/124
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:4:title: "feat(harness): eliminate end-of-day closeout friction — automated phase QA receipts, auto-PR creation, and clone lifecycle hygiene"
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-5-status: Active (2-WORKING as of 2026-08-21)
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-6-created: 2026-08-21
--
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-10-rating: "pri/sev/appeal/effort 85/60/90/40 · calc 275"
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-11-goal: >
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:12:  Eliminate 50+ minutes of daily end-of-day closeout friction across marathon and ad-hoc sessions:
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-13-  add machine-checkable local gate receipts, driver-refreshed early drift alerts, safe manifest-bounded
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-14-  workspace garbage collection with soft quarantine, hardened one-shot PR creation, and post-gate
--
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-16----
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-17-
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:18:# GH-124: End-of-Day Closeout Automation & Lifecycle Hygiene (Plan)
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-19-
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-20-## Status
--
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-28-## Canonical Implementation Specification (Finalized & Hardened Plan)
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-29-
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:30:This document establishes the **authoritative, production-grade implementation specification and safety contracts** for eliminating end-of-day closeout friction, incorporating all feedback from the `openrouter/stealth/ox-alpha` relay review, Agent2Agent session [#658731](https://github.com/HiQS-Suite/XYZ-forge/issues/124#issuecomment-5373503236), and Fable 5's architectural verification.
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-31-
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-32----
--
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-41-4. **On-Disk Local Gate Receipt Contract:** `ci-local.sh` and `validate.sh` write a machine-checkable receipt artifact to `.xyz/receipts/<SHA>.json` upon green exit. Auto-PR consumes this deterministic local file before opening PRs.
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-42-5. **Registered Workspace Lifecycle:** `rtl_worktree_begin` and clone creation tools write entries into `.xyz/workspaces.json`. Sweep bounds itself to this manifest and safely cross-checks `git worktree list --porcelain`.
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:43:6. **Single Source of Truth (No Duplicate Twins):** Reject creating `utils/py/closeout.py`; harden the existing `relay-automation/marathon-closeout.sh` path directly.
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-44-7. **Preserve Shared Tooling Schemas:** Issue titles are immutable across the automation lifecycle (no title mutations). QA attestation is emitted via post-gate structured issue comments with machine-checkable test receipts.
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-45-
--
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-51-graph TD
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-52-    P0[Phase 0: Local Gate Receipt Contract<br/>ci-local.sh & validate.sh write .xyz/receipts/SHA.json] --> P1[Phase 1: Early Rebase Drift Alert<br/>Driver fetch at phase boundary + rtl_before read-only check]
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:53:    P0 --> P3[Phase 3: Harden marathon-closeout.sh<br/>Purge git add -A + consume local receipt + lock --base]
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-54-    P2[Phase 2: Workspace Sweep & Lifecycle Manifest<br/>rtl_worktree_begin registration + all-branch ancestor check + .xyz/trash/ reaper]
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-55-    P0 --> P4[Phase 4: Driver-Owned QA Receipts<br/>Post-gate issue comments from local receipt]
--
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-74-    }
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-75-    ```
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:76:- **Durability:** Committed into evidence or preserved under `.xyz/` so downstream consumers (`marathon-closeout.sh`, issue commenter) read an authoritative local proof of qualification.
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-77-
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-78----
--
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-120-
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-121-### Phase 3: One-Shot PR Scaffold (`QW2` — Hardened Existing Path)
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:122:- **Location:** `relay-automation/marathon-closeout.sh` (invoked via `marathon_drive.py --open-only --no-commit`)
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:123:- **Reject Duplicate Twin:** No `utils/py/closeout.py`.
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-124-- **Hardening Enhancements:**
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md:125:  1. **Purge `git add -A`:** Remove indiscriminate `git add -A` sweep in `marathon-closeout.sh` that sweeps unintended untracked files.
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-126-  2. **Hard-Lock Base:** Strictly enforce `--base development` by default with validation against `main`.
PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md-127-  3. **Deterministic Local Receipt Check:** Asserts that `.xyz/receipts/<HEAD_SHA>.json` exists, is valid JSON, and has `exit_code: 0` before executing `gh pr create`.
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-82-
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-83-### ⚠️ Not yet sequenceable — rate / add doc / add contract
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md:84:- #536 GH-536 · the gate-evidence record was a bare result: green — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-85-- #539 GH-539 · a gitignored 2-minute skill-sync job resurrects deleted SKILL.md files — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-86-- #527 GH-527 · a destructive git command has no guard, and a doc rail demonstrably will not fix it — `blocked`
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-99-- #510 GH-510 · Agent2Agent watch/drive operating levels — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-100-- #509 GH-509 · tier CI to stop per-push Actions minute burn — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md:101:- #497 GH-497 · agent2agent compact multi-session rendezvous — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-102-- #480 GH-480 · XYZ Cockpit — read-only VS Code view for Marathons, Releases, Worktrees — `blocked`
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-103-- #451 GH-451 · Marathon: support Pi builders on the Python-default path — `blocked`
--
PROJECT/2-WORKING/MARATHON-PLAN-2026-08-16.md-162-- #292 GH-292 · A linked worktree cannot discover the main checkout's vendored .xyz harness — `blocked`

exec
/bin/zsh -lc "git diff --stat origin/development...HEAD; git diff --name-status origin/development...HEAD; git log --format='%h %s' origin/development..HEAD; git diff --numstat origin/development...HEAD -- releases.db releases.sql ROADMAP.md CHANGELOG.md; git diff --unified=1 origin/development...HEAD -- ROADMAP.md | sed -n '1,220p'; git diff --unified=1 origin/development...HEAD -- CHANGELOG.md | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-54150-qde9l_3o
2026-08-22T00:31:54.195066Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
2026-08-22T00:31:56.515838Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `base_instructions` at line 98 column 5
 succeeded in 16319ms:
2026-08-21 17:31:44.486 xcodebuild[80719:153457968]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:44.706 xcodebuild[80719:153457819] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-SK2ZPzBL' (errno=Operation not permitted)
2026-08-21 17:31:45.328 xcodebuild[81180:153459831]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:45.545 xcodebuild[81180:153459684] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
 HARNESS-MODELS-REGISTRY.md                         |    2 +-
 LEADERBOARD.html                                   |    4 +
 LEADERBOARD.md                                     |   29 +-
 PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md    |  143 ++
 RELEASES-PREVIEW.html                              |    4 +
 ROADMAP-DASHBOARD.md                               |    3 +-
 ROADMAP.md                                         |    1 +
 relay-automation/marathon-closeout.sh              |   49 +-
 relay-automation/marathon.sh                       |    2 +-
 relay-automation/oracle-guard.sh                   |    2 +-
 relay-automation/relay-turn-lib.sh                 |   15 +
 ...out-plan-adjudicate-four-safety-contract-ref.md |  154 ++
 .../2026-08-21/gh124-closeout-auto-pr-review.md    | 1606 ++++++++++++++++++++
 .../2026-08-21/gh124-closeout-implementation-qa.md | 1399 +++++++++++++++++
 releases.db                                        |  Bin 294912 -> 294912 bytes
 releases.sql                                       |   11 +-
 skills/relay-automation/relay-pkg.tar.gz           |  Bin 108889 -> 109046 bytes
 test/gh124-closeout.sh                             |    6 +
 test/gh430-state-dir-tracked-default.sh            |   12 +-
 test/marathon-closeout.sh                          |   26 +-
 test/marathon-drive.sh                             |    4 +-
 test/releases-skill.sh                             |    2 +-
 test/synthetic/gh124-closeout-suite.sh             |  185 +++
 utils/gate-record.sh                               |    3 +
 utils/py/gate_receipt.py                           |  134 ++
 utils/py/marathon_drive.py                         |   81 +-
 utils/py/workspace_manager.py                      |  337 ++++
 validate.sh                                        |    8 +
 28 files changed, 4170 insertions(+), 52 deletions(-)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-Fj4STuwd' (errno=Operation not permitted)
2026-08-21 17:31:47.050 xcodebuild[81813:153462830]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:47.278 xcodebuild[81813:153462655] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-6Cq8c6Lx' (errno=Operation not permitted)
2026-08-21 17:31:47.919 xcodebuild[82397:153465000]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:48.119 xcodebuild[82397:153464903] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
M	HARNESS-MODELS-REGISTRY.md
M	LEADERBOARD.html
M	LEADERBOARD.md
A	PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md
M	RELEASES-PREVIEW.html
M	ROADMAP-DASHBOARD.md
M	ROADMAP.md
M	relay-automation/marathon-closeout.sh
M	relay-automation/marathon.sh
M	relay-automation/oracle-guard.sh
M	relay-automation/relay-turn-lib.sh
A	relay-system/2026-08-21/658731-agent2agent-gh-124-closeout-plan-adjudicate-four-safety-contract-ref.md
A	relay-system/2026-08-21/gh124-closeout-auto-pr-review.md
A	relay-system/2026-08-21/gh124-closeout-implementation-qa.md
M	releases.db
M	releases.sql
M	skills/relay-automation/relay-pkg.tar.gz
A	test/gh124-closeout.sh
M	test/gh430-state-dir-tracked-default.sh
M	test/marathon-closeout.sh
M	test/marathon-drive.sh
M	test/releases-skill.sh
A	test/synthetic/gh124-closeout-suite.sh
M	utils/gate-record.sh
A	utils/py/gate_receipt.py
M	utils/py/marathon_drive.py
A	utils/py/workspace_manager.py
M	validate.sh
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-U5o5fGEK' (errno=Operation not permitted)
2026-08-21 17:31:49.702 xcodebuild[83416:153468860]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:49.931 xcodebuild[83416:153468696] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-al7lIJXH' (errno=Operation not permitted)
2026-08-21 17:31:50.600 xcodebuild[83820:153470727]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:50.811 xcodebuild[83820:153470604] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
b1611d01 docs(registry): update stealth/ox-alpha evaluation with rebalanceOS v0.75.3 review (#120)
cbf43991 fix(test): harden oracle-guard and gh430-state-dir against isolated temp clone execution
1c1effa2 fix(marathon-drive): exempt harness-owned .xyz/ and .relay-scratch/ from require-clean dirty check
d62d4796 fix(validate): fix syntax fi in receipt check and physical root normalization in releases-skill test
1bc95246 fix(GH-124): address review feedback — trash quarantine aging, detached HEAD push check, receipt timing & closeout callers
a18432ac docs(registry): update stealth/ox-alpha entry with GH-124 multi-turn evaluation evidence
26180d7f docs(relay): record agent2agent #658731 and initial review thread for GH-124
38eb9c91 fix(workspace-manager): use directory timestamp prefix for trash reaper age calculation
2cd91fc2 relay(RELAY-GH124-CLOSEOUT-QA): aider turn (aider headless; no push)
65a340cd feat(harness): closeout automation, gate receipts, workspace GC & drift alert (GH-124)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-7chXX3MT' (errno=Operation not permitted)
2026-08-21 17:31:52.295 xcodebuild[84641:153474315]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:52.512 xcodebuild[84641:153474290] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-WAhBYFvJ' (errno=Operation not permitted)
2026-08-21 17:31:53.212 xcodebuild[84926:153475594]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:53.457 xcodebuild[84926:153475496] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
1	0	ROADMAP.md
-	-	releases.db
7	4	releases.sql
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-NDFeZVRO' (errno=Operation not permitted)
2026-08-21 17:31:55.015 xcodebuild[86084:153479348]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:55.228 xcodebuild[86084:153479243] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-je6c1THc' (errno=Operation not permitted)
2026-08-21 17:31:56.023 xcodebuild[87036:153482034]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:56.305 xcodebuild[87036:153481863] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
diff --git a/ROADMAP.md b/ROADMAP.md
index 2a9a7dc2..eace0f6f 100644
--- a/ROADMAP.md
+++ b/ROADMAP.md
@@ -120,2 +120,3 @@ detour has a home; note that the marathon planner does NOT read this section —
 
+- **GH-124 · eliminate end-of-day closeout friction — automated phase QA receipts, auto-PR creation, and clone lifecycle hygiene** 🚧 **active 2026-08-21** — eliminate 50+ minutes of daily closeout friction: on-disk local gate receipts (`ci-local.sh` / `validate.sh`), driver-refreshed early drift alerts, safe manifest-bounded workspace sweep with soft quarantine, hardened `marathon-closeout.sh`, and post-gate in-flight QA attestation comments. rated 85/60/90/40. → [GH-124-CLOSEOUT-AUTOMATION.md](PROJECT/2-WORKING/GH-124-CLOSEOUT-AUTOMATION.md) · [#124](https://github.com/HiQS-Suite/XYZ-forge/issues/124)
 - **GH-77 · `/standup` — session-scoped triage: what did I leave open, what is rotting, is the plan still right?** 🚧 **THE MARATHON as of 2026-08-19 (handed over from GH-10 by operator call); triage.py + 29-assertion suite BUILT and merged (PR #78); `collect.sh` is the marathon's eight work units** — the instrument the operator reaches for constantly, and the answer to the confidence problem the 2026-08-19 audit exposed: a shipped release left `active` for a day, four ledger markers contradicting GitHub, five issues filed into no index — all discoverable in seconds, none discovered by anything. Session + local state only (no history sweep; `/radar` keeps that job), park-only write authority, both halves every run, tactical list hard-capped at 7 items and the strategic read at ~5 lines. Carries an interface catalogue for the RELEASES CLI, the ROADMAP entry schema, PDDA lifecycle, and the one-marathon rail, so every recommendation names the exact command that closes it. rated 95/70/85/30. → [GH-77-STANDUP-SESSION-TRIAGE.md](PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md) · [#77](https://github.com/HiQS-Suite/XYZ-forge/issues/77) · [GH-77-STANDUP-SESSION-TRIAGE.md](PROJECT/2-WORKING/GH-77-STANDUP-SESSION-TRIAGE.md)
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-siQKtTrO' (errno=Operation not permitted)
2026-08-21 17:31:58.016 xcodebuild[90257:153488402]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:58.253 xcodebuild[90257:153488276] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.
git: warning: confstr() failed with code 5: couldn't get path of DARWIN_USER_TEMP_DIR; using /tmp instead
git: error: couldn't create cache file '/tmp/xcrun_db-hFmBJqQr' (errno=Operation not permitted)
2026-08-21 17:31:58.948 xcodebuild[91599:153491346]  DVTFilePathFSEvents: Failed to start fs event stream.
2026-08-21 17:31:59.255 xcodebuild[91599:153491216] [MT] DVTDeveloperPaths: Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error". Using NSCachesDirectory instead.


consult: advisor was IDLE for >=90s (no CPU, no transcript growth) and was killed before the 298s wall cap [timeout-slow-but-progressing: the agent was writing files but did not finish — genuinely slow; raising the turn budget is the appropriate response. [cpu=0.03s/s, samples=59, worktree-progress=yes]]. This is an EXTERNAL condition consult detected and contained, not one it prevented.

consult: advisor failed or exceeded the 300s cap
