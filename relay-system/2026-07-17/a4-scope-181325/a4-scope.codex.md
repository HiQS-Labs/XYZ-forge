**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (codex's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)

> **ATTESTATION**
> Model: gpt-5.4
> Provider: openai
> Sandbox: read-only

Reading additional input from stdin...
OpenAI Codex v0.139.0
--------
workdir: /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-93345-6718
model: gpt-5.4
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019f72c9-0b79-73f2-b06c-7b84f7685058
--------
user
You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering the SAME question separately and a coordinator will reconcile both answers, so give your own honest, specific read — do not hedge toward a consensus you cannot see. Read any repo files the question references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — [Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy).

=== CONSULT QUESTION ===
# Consult: A4 provenance taxonomy — ship the 4-category taxonomy, or a 2-category v0 first?

## Context (read these files in the repo — they are present in your worktree)

- `PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md` — the full design proposal. Read it.
- `relay-automation/consult.sh` lines ~115-336 — the shipped A4 slice: it builds `FULL_PROMPT`
  in memory (never persisted to disk) and, after collecting advisor transcripts, stamps any answer
  that `rtl_has_uncited_claim()` flags with `NO FIRSTHAND VERIFICATION CITED`.
- `relay-automation/relay-turn-lib.sh` lines ~675-744 — `RTL_CLAIM_WORD_RE`, `RTL_CITATION_RE`,
  `rtl_has_uncited_claim()`, `rtl_check_uncited_findings()` — the shared claim/citation machinery.
- `GUIDING-PRINCIPLES.md` — the repo's quality bar. Principle 7 ("least code that clears the bar")
  and the Appendix "new relay path vs. reuse" tie-breaker are the most load-bearing here.

## The situation

The shipped A4 slice is a **binary** check: does a claim-bearing line have ANY citation-shaped string
(`file:line` or a quoted span) nearby? If not → stamp `NO FIRSTHAND VERIFICATION CITED`. Its structural
blind spot: it cannot tell an advisor that read `consult.sh:117` itself apart from one that merely
echoed a `file:line` string the operator PASTED INTO the prompt. Both look "cited."

The proposal closes that gap by persisting the operator's prompt text to a sidecar and diffing each
citation against it. It offers two scopes for a first implementation pass:

- **4-category (v1):** FIRSTHAND (cited, citation NOT in prompt) / ECHOED (cited, citation IS in
  prompt) / INFERENCE (uncited, not a prompt restatement) / UNSUPPORTED-ASSERTED (uncited, restates
  prompt). Plus per-advisor `PROVENANCE.txt` counts and a reconciliation-layer backstop.
- **2-category (v0):** just "citation traces to the prompt" (ECHOED) vs. "does not" (FIRSTHAND),
  computed ONLY on already-cited claims — one new substring test on top of the existing citation
  detection. Defers the INFERENCE/UNSUPPORTED-ASSERTED split and the reconciliation backstop.

## The single decision I need your independent read on

**For the FIRST implementation pass, should we ship the 4-category taxonomy or the 2-category v0
collapse?** Weigh specifically:

1. Under Principle 7 (least code that clears the bar) and the "new relay path vs. reuse" tie-breaker,
   which scope is right for a first cut?
2. Does the ECHOED-vs-FIRSTHAND distinction (v0) deliver most of A4's actual value on its own, or is
   the INFERENCE / UNSUPPORTED-ASSERTED split load-bearing enough that shipping without it is a
   half-measure that will need immediate rework?
3. Implementation risk: the new plumbing (persisting the prompt to a sidecar; whitespace-normalized
   substring matching of a citation string against prompt text) — what are the concrete false-positive
   / false-negative failure modes, and does the 4-category version add materially more risk than v0?
4. Is there a THIRD framing better than either — e.g. a different minimal cut, or a reason not to
   build this at all yet given the shipped binary check already exists?

## What a good answer looks like

A clear v0-vs-v1 call with your reasoning grounded in the actual code (cite file:line for any claim
about how the shipped mechanism behaves — do not assert behavior you did not read), an honest read on
whether v0 is a genuine durable slice or a band-aid, and the single highest-risk failure mode of
whichever scope you recommend.
hook: SessionStart
hook: SessionStart Completed
codex
I’m reading the repo’s canonical guidance first, then the cited implementation/proposal files so the call is grounded in the actual shipped A4 behavior rather than the proposal’s framing.
codex
I’ve got the graph tools. Next I’m checking whether this worktree is already indexed and pulling the specific proposal/runtime docs in parallel so I can tie the recommendation to both the code and the repo’s decision rules.
exec
/bin/zsh -lc "pwd && printf '\\n---\\n' && sed -n '1,220p' WORKTREE-SAFETY.md && printf '\\n---\\n' && sed -n '1,260p' ROUTER.md && printf '\\n---\\n' && sed -n '1,260p' GUIDING-PRINCIPLES.md" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-93345-6718
 succeeded in 0ms:
/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-93345-6718

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
utils/pdda/pdda.sh releases         # validate RELEASES.md, the release-planning ledger (warn-only nudge)
utils/pdda/pdda.sh releases-current # read-only roll-up: RELEASES.md entries whose Status isn't "Shipped"
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
mcp: codebase-memory-mcp/index_status started
mcp: codebase-memory-mcp/index_status (failed)
user cancelled MCP tool call
codex
I’ve got the repo’s decision rules. Now I’m reading the proposal and the exact A4 code paths with line numbers so the recommendation can distinguish what is already shipped from what the proposal would add.
exec
/bin/zsh -lc "nl -ba PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md | sed -n '1,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-93345-6718
 succeeded in 0ms:
     1	---
     2	gh_issue: 178
     3	source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/178
     4	title: "Proposal: full firsthand-vs-asserted provenance taxonomy (GH-178 A4's deferred fuller scope)"
     5	status: "PROPOSAL — not promoted to 2-WORKING, not yet filed as its own GitHub issue, nothing implemented or shipped. This document argues for filing a new issue (see 'Process recommendation') rather than reopening #178 or being folded silently into #226."
     6	created: 2026-07-17
     7	updated: 2026-07-17
     8	owner: noel
     9	doc_type: design-proposal
    10	complexity: 4
    11	risk: 2
    12	effort: 4
    13	phases: 0
    14	ratings_provisional: true
    15	roadmap_exempt: true
    16	related:
    17	  - PROJECT/2-WORKING/GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md
    18	  - PROJECT/1-INBOX/GH-226-PROVENANCE-SUMMARY-SURFACE-COORDINATION.md
    19	  - PROJECT/2-WORKING/GH-223-CONSULT-PY-CITATION-STAMP-PARITY.md
    20	  - PROJECT/1-INBOX/GH-211-CONSULT-RELAY-TLDR-SUMMARIES.md
    21	  - relay-automation/consult.sh
    22	  - relay-automation/relay-turn-lib.sh
    23	  - skills/consult/SKILL.md
    24	  - GUIDING-PRINCIPLES.md
    25	non_goals:
    26	  - Not an implementation — no code, tests, or skill edits are made by this document.
    27	  - Not a re-litigation or reopening of GH-178's shipped A2/A4 slice — that mechanism is treated as
    28	    correct-as-shipped and as the extension point, not as something to redo.
    29	  - Not vendoring, reproducing, or guessing the contents of the external `ra-to-xyz-transfer.md`
    30	    ("seven transfers" / advisor-echo / false-consensus / reconciler-laundering / prompt-drift /
    31	    model-version-drift catalog) — that document is unavailable to the author of this proposal (not
    32	    in this repo, confirmed absent). Terminology below that resembles that catalog's named failure
    33	    modes (e.g. "echoed") is this author's own mechanical guess at a checkable proxy, not a citation
    34	    of that catalog's actual definitions. See "External dependency gap" below.
    35	  - Not deciding GH-226's open question (whether fuller provenance and the GH-211 summary-surface
    36	    rework land as one coordinated pass or split by repo/surface) — this document assumes GH-226's
    37	    coordination question gets answered first and designs so either answer stays workable, but does
    38	    not answer it here.
    39	  - Not scoping relay-side (as opposed to consult-side) provenance — GH-178's A2/A4 slice and this
    40	    proposal are both `consult.sh`-scoped; whether the relay turn/review path needs the same
    41	    treatment is explicitly left to GH-226 or a later issue.
    42	goal: >
    43	  Propose the full firsthand-vs-asserted-vs-inference provenance taxonomy that GH-178's A4 item
    44	  originally asked for and that its shipped 2026-07-08 slice deliberately did not cover (see that
    45	  doc's A4 row and Non-goals section) — a mechanically-checkable distinction between a fact an
    46	  advisor verifiably read/searched for itself, a fact that only traces back to text the operator put
    47	  in the consult prompt, and an advisor's own unsupported inference — plus a bounded way to flag a
    48	  reconciled verdict as conditional when it rests entirely on the asserted-only category. Scoped as a
    49	  proposal to be evaluated, not a build to be merged.
    50	---
    51	
    52	# GH-178 A4 · full firsthand-vs-asserted provenance taxonomy — design proposal
    53	
    54	## Status
    55	
    56	| What was just completed | What's next |
    57	|---|---|
    58	| This proposal drafted 2026-07-17, in response to GH-178's explicit Non-goals hand-off ("A future issue can pick up the fuller distinction"). Nothing implemented. Not promoted to 2-WORKING. No GitHub issue filed for it. | Operator reviews this proposal, decides whether to file it as its own issue (recommended below, see "Process recommendation"), and whether to sequence it before or after GH-226's coordination question is resolved. |
    59	
    60	## Why this document exists
    61	
    62	GH-178's A4 item asked the Consult/Relay panel to distinguish facts an advisor verified firsthand
    63	from facts the operator merely asserted in the prompt, and to flag verdicts that rest entirely on
    64	asserted facts as conditional. What shipped 2026-07-08 (`relay-automation/consult.sh:310-336`,
    65	reusing `relay-turn-lib.sh`'s `rtl_has_uncited_claim()`) is narrower: a presence/absence check —
    66	does a claim-bearing line have *any* citation-shaped string (`file:line` or a quoted span) within a
    67	3-line window? If not, stamp `NO FIRSTHAND VERIFICATION CITED`. That is a real, mechanically sound
    68	check, and it is *not* what A4 asked for: it cannot tell the difference between an advisor that read
    69	`consult.sh:117` itself and one that is simply repeating back a `file:line` string the operator typed
    70	directly into the consult prompt. Both look identical to the shipped check — both have a citation
    71	nearby. This proposal is the design for closing that specific gap.
    72	
    73	---
    74	
    75	## 1. The distinction itself
    76	
    77	The shipped slice's blind spot is structural: **presence of a citation-shaped string is not evidence
    78	of independent discovery.** An operator can — and in practice does — paste file paths, line numbers,
    79	and exact quotes into a consult prompt as context. An advisor that repeats those back verbatim is not
    80	demonstrating firsthand verification; it is demonstrating that it can copy text. The mechanically
    81	checkable distinction this proposal proposes is therefore not "cited vs. uncited" (already shipped)
    82	but **"citation traceable only to the prompt" vs. "citation not present anywhere in the prompt."**
    83	
    84	Four categories, all computed per claim-bearing line (a "claim" is the same trigger the shipped
    85	mechanism already uses — a `[Pass]` tag or `RTL_CLAIM_WORD_RE` match in `relay-turn-lib.sh`):
    86	
    87	| Category | Definition | Mechanical test |
    88	|---|---|---|
    89	| **FIRSTHAND** | Claim has a nearby citation (existing `RTL_CITATION_RE` window match — `file:line` or quoted span), AND that exact citation string does **not** appear anywhere in the operator-supplied prompt text. | citation-window match = true; substring match against persisted `PROMPT_TEXT` = false. |
    90	| **ECHOED** | Claim has a nearby citation, but that exact citation string **does** appear (verbatim, whitespace-normalized) in the operator-supplied prompt text. The advisor is citing something it was handed, not something it found. | citation-window match = true; substring match against `PROMPT_TEXT` = true. |
    91	| **INFERENCE** | Claim has no nearby citation, AND the claim's own text is not a near-verbatim restatement of prompt text. This is the advisor's own reasoning/synthesis — not firsthand, not a prompt echo, and not automatically suspect; it is a distinct third thing the shipped binary check collapses into "uncited." | citation-window match = false; claim-line substring/fuzzy match against `PROMPT_TEXT` = false. |
    92	| **UNSUPPORTED-ASSERTED** | Claim has no nearby citation, AND the claim's own text closely matches prompt text (the advisor is restating what the operator told it as if it were an independent finding). This is the shipped mechanism's exact trigger case, sharpened: today's check would flag this identically to INFERENCE; this proposal splits them because they carry different epistemic weight. | citation-window match = false; claim-line substring/fuzzy match against `PROMPT_TEXT` = true. |
    93	
    94	Note what this taxonomy deliberately does **not** attempt: verifying that a present citation is
    95	*accurate* (that `consult.sh:117` really says what the advisor claims it says). That remains out of
    96	scope here, same as the shipped slice — see Non-goals and Section 4.
    97	
    98	This is the author's own mechanical proxy for the kind of distinction the (unavailable)
    99	`ra-to-xyz-transfer.md` catalog reportedly names "advisor echo" as one of five failure modes — see
   100	"External dependency gap" below for why that correspondence is a guess, not a citation.
   101	
   102	---
   103	
   104	## 2. Where in the pipeline this gets computed
   105	
   106	Extends the existing A2/A4 mechanism rather than forking a new one (per Principle 7 and the
   107	Appendix's "new relay path vs. reuse" tie-breaker). Concretely, in `relay-automation/consult.sh`:
   108	
   109	1. **New: persist the operator-supplied prompt text.** Today `consult.sh:117-126` builds
   110	   `FULL_PROMPT` (boilerplate `PREAMBLE` + operator's `PROMPT_TEXT`) as an in-memory bash variable
   111	   and passes it directly to each advisor CLI invocation — it is never written to `$RUN_DIR`. The
   112	   ECHOED/UNSUPPORTED-ASSERTED test above needs something to diff citations against, so `consult.sh`
   113	   would additionally write `$RUN_DIR/${LABEL}.PROMPT.txt` containing `PROMPT_TEXT` only (not
   114	   `PREAMBLE` — the boilerplate is not operator content and would create false ECHOED matches on the
   115	   preamble's own instructional language, e.g. its request that advisors "cite evidence"). This is a
   116	   small, additive, non-containment-relevant write inside the run's own `$RUN_DIR` — no new allowlist
   117	   or worktree-isolation surface.
   118	2. **New predicate in `relay-turn-lib.sh`, sibling to `rtl_has_uncited_claim()`.** Something like
   119	   `rtl_classify_claims(<transcript_file>, <prompt_file>)` that runs the same `awk` claim-detection
   120	   pass (reusing `RTL_CLAIM_WORD_RE`/`RTL_CITATION_RE` verbatim so the "what counts as a claim/
   121	   citation" definition stays in lockstep with B3 and the shipped A4 slice, per that file's own
   122	   comment at `relay-turn-lib.sh:653-656`) but additionally checks each citation/claim span against
   123	   the prompt file, and emits a count per category instead of a single boolean.
   124	3. **Reuse the exact stdout + prepended-transcript + sidecar mechanism**, extended, not replaced:
   125	   - The existing `NO FIRSTHAND VERIFICATION CITED` stamp keeps firing on exactly the cases it fires
   126	     on today (INFERENCE ∪ UNSUPPORTED-ASSERTED, i.e. "no nearby citation") — **no regression**, and
   127	     `test/consult.sh`'s existing assertions and GH-223's Python-parity port both stay valid as-is.
   128	   - A new, additive sidecar per answered advisor — `$RUN_DIR/${LABEL}.${model}.PROVENANCE.txt` —
   129	     carrying the per-category counts and, for any ECHOED claim specifically, the matched prompt
   130	     span, so a reader can see *which* citation was a prompt-echo without re-deriving it.
   131	   - A new stdout `warn` line only when ECHOED claims are found on an otherwise-"cited" transcript
   132	     (this is the actual new information: a transcript that looks clean under the shipped check but
   133	     is entirely prompt-echoed underneath it).
   134	4. **Nothing in step 1-3 touches a headless turn's write path, allowlist, or worktree isolation** —
   135	   this is read-only post-hoc analysis of already-produced transcripts plus one new read-only sidecar
   136	   file, the same containment posture the shipped A2/A4 mechanism already has.
   137	
   138	Why not compute this earlier (e.g., have the advisor self-report firsthand vs. asserted in its own
   139	output)? Because that would be model-compliance-dependent, not structural — exactly the failure mode
   140	GH-178's own A4 row calls out from its live example ("a confident, dated, self-hedged claim that was
   141	still wrong — the hedge alone didn't prevent the error"). The mechanism must stay a mechanical,
   142	outside-the-model check, consistent with why the shipped slice is a post-hoc stamp rather than a
   143	prompt instruction alone.
   144	
   145	---
   146	
   147	## 3. Flagging a verdict that rests entirely on asserted facts as conditional
   148	
   149	This is the part of A4 the shipped slice explicitly does not attempt, and it is genuinely harder than
   150	Sections 1-2, because it requires connecting a **downstream** claim (a line in the *reconciled*
   151	verdict — the synthesis an agent writes after reading all advisors' answers, per
   152	`skills/consult/SKILL.md`'s "Disagree → Agree → Reconciled call" structure) to the **upstream**
   153	per-advisor facts that back it. Sections 1-2 classify facts within a single advisor's transcript;
   154	this section is about tracing a conclusion that may synthesize several advisors' facts into one
   155	sentence.
   156	
   157	**Full dependency tracing (which exact verdict sentence depends on which exact upstream fact) is out
   158	of v1 scope** — see Section 4 for why. What this proposal designs instead is a **bounded mechanical
   159	backstop**, applying the same claim/citation-window technique one layer up:
   160	
   161	- The reconciliation/synthesis step is currently free-form prose written by whichever agent runs the
   162	  consult (per `skills/consult/SKILL.md`), not a deterministic script — GH-211 already reshaped this
   163	  layer's *format* (TLDR + sorted Blocking/Worth-doing/Skip categories) without touching its
   164	  semantics. Any verdict-provenance change must plug into that already-changed shape, not a stale
   165	  pre-GH-211 one (this is exactly the coordination gap GH-226 opened to own — see Section 7).
   166	- Proposed addition to `skills/consult/SKILL.md`'s reconciliation instructions: the reconciling agent
   167	  states, next to each "Reconciled call" claim, which advisor(s)' FIRSTHAND-category facts (from
   168	  Section 1-2's per-advisor sidecars) support it — a lightweight citation-of-citations, not a new
   169	  data structure.
   170	- A deterministic backstop mirroring `rtl_check_uncited_findings()`'s existing per-line downgrade:
   171	  scan the "Reconciled call" section text for a claim-word match (`RTL_CLAIM_WORD_RE`, the same
   172	  vocabulary already used) with **no FIRSTHAND-tagged reference nearby** (all upstream support was
   173	  ECHOED, INFERENCE, or UNSUPPORTED-ASSERTED, or absent) → mechanically append
   174	  `[CONDITIONAL — rests on asserted-only facts]`, same non-destructive prepend/append posture as the
   175	  shipped mechanism (never deletes or rewrites the agent's actual words).
   176	
   177	**Honest limitation of this backstop:** it checks whether the *reconciliation prose itself* cites a
   178	FIRSTHAND-tagged upstream fact nearby — it does not verify that the cited fact *actually entails* the
   179	verdict sentence (that would require semantic understanding, not string matching). It catches "the
   180	reconciling agent asserted a verdict and cited nothing/only-echoed facts near it," which is the same
   181	class of gap B3 and the shipped A4 slice already catch one layer down — extended upward, not a
   182	qualitatively new capability. True dependency tracing (Section 4's deferred item) would need either a
   183	structured per-claim ID scheme threaded through advisor output and the reconciliation text, or an
   184	LLM-graded verification step — both bigger asks, deliberately deferred.
   185	
   186	---
   187	
   188	## 4. Explicit scope boundaries — v1 vs. deferred
   189	
   190	Per Principle 7 ("least code that clears the bar — no premature abstraction"): a smaller
   191	mechanically-checkable slice that gets most of the value, not a big-bang taxonomy.
   192	
   193	**v1 (proposed for a future implementation pass):**
   194	- Persisting `PROMPT_TEXT` to a sidecar file per consult run (Section 2, step 1).
   195	- The 4-category per-claim classification (FIRSTHAND / ECHOED / INFERENCE / UNSUPPORTED-ASSERTED)
   196	  as a new predicate sibling to `rtl_has_uncited_claim()`, with the existing `NO FIRSTHAND
   197	  VERIFICATION CITED` stamp's trigger condition unchanged (no regression).
   198	- The new `PROVENANCE.txt` per-advisor sidecar with category counts.
   199	- The bounded reconciliation-layer backstop in Section 3, scoped only to `skills/consult/SKILL.md`'s
   200	  synthesis instructions plus one deterministic scan — not a new data structure or storage format.
   201	
   202	**Explicitly deferred, and why:**
   203	- **Citation accuracy verification** (does a present `file:line`/quote actually say what's claimed) —
   204	  same non-goal the shipped slice already carries; would need a real content-diffing engine against
   205	  the advisor's assigned worktree, a materially larger and riskier build (touches read access into
   206	  worktree state during post-hoc analysis, not just transcript text).
   207	- **True semantic dependency tracing** between a specific verdict sentence and a specific upstream
   208	  fact (Section 3) — would need either a structured per-claim ID contract threaded through every
   209	  advisor's output format (a larger, more invasive change to the consult output contract than
   210	  anything shipped so far) or an LLM-graded verification pass, which per Principle 12 would itself
   211	  need independent/separated grading, adding real cost. Flagged as a possible v2, not v1.
   212	- **The external failure-mode catalog** (advisor echo / false consensus / reconciler laundering /
   213	  prompt drift / model-version drift, and the "seven transfers") — still not vendored, still not
   214	  owned here, per GH-178's existing Non-goals. This proposal's ECHOED category is this author's own
   215	  guess at a mechanical proxy for one of those five named modes, not a reproduction of it.
   216	- **False-consensus detection** (two+ advisors agreeing, but for the same ECHOED/asserted reason
   217	  rather than independent verification) — a cross-advisor check, not a per-advisor one; likely also
   218	  inside the external catalog's scope; deferred to a later pass once/if that catalog is obtained.
   219	- **Relay-side provenance** (as opposed to consult-side) — GH-178's A2/A4 slice and this whole
   220	  proposal are `consult.sh`-scoped. Whether `relay-automation/`'s producer/reviewer turn loop needs
   221	  the same treatment is a real open question this document does not answer — see Section 7 and
   222	  GH-226.
   223	- **`utils/py/consult.py` parity** — GH-223 already tracks porting the *shipped* slice to Python; a
   224	  v1 implementation of this proposal would need its own follow-on parity item, not scoped here.
   225	
   226	---
   227	
   228	## 5. Self-graded checklist (GUIDING-PRINCIPLES.md Appendix)
   229	
   230	Run honestly, not defensively — including where this proposal falls short.
   231	
   232	| # | Heuristic | Verdict | Notes |
   233	|---|---|---|---|
   234	| 1 | Containment preserved? | **Pass** | Everything proposed is read-only post-hoc analysis of already-produced transcripts plus one new sidecar write inside `$RUN_DIR` (the consult run's own output directory). No new headless-turn write path, no allowlist change, no worktree-isolation change. |
   235	| 2 | Skill-first respected? | **Pass, with a caveat** | Section 3's reconciliation-layer change is explicitly scoped as a `skills/consult/SKILL.md` edit, not an improvised harness workaround. Caveat: this document does not itself make that edit — a future implementation pass must actually land it in the skill, not bolt it on elsewhere. |
   236	| 3 | Coordination through the event log? | **Pass (trivially)** | Nothing here reads or writes `.tick/` state; this is entirely transcript/prompt-text analysis. Not applicable rather than actively satisfied. |
   237	| 4 | Done verifiable? | **Fails today, by design** | This is a proposal, not an implementation — there is no runnable gate yet. A future implementation pass would need: new `test/consult.sh` assertions (mirroring the 5+2 already covering the shipped slice), a Python-parity assertion once ported, and `./validate.sh` green. Naming this honestly as "not yet verifiable" rather than claiming a false pass. |
   238	| 5 | Drift reduced, not created? | **Pass** | Explicitly extends `rtl_has_uncited_claim()`/`RTL_CLAIM_WORD_RE`/`RTL_CITATION_RE` and the stdout+transcript+sidecar stamp pattern rather than forking parallel definitions. Explicitly defers to GH-226 rather than reworking the operator-facing summary surface a second, uncoordinated time. |
   239	| 6 | Next action singular? | **Pass** | Section 7 gives one explicit recommendation (file a new issue, coordinated with #226) rather than presenting multiple options as equally valid. |
   240	| 7 | Operator control explicit? | **Pass** | The proposed `[CONDITIONAL — ...]` stamp is additive/non-destructive (append, never delete/rewrite), matching the shipped mechanism's posture. No auto-retry, no silent masking proposed anywhere. |
   241	| 8 | Four pillars (Attested/Relevant/Fresh/Structured)? | **Partial** | **Attested**: strong — every mechanism reference cites real current code (line ranges in `consult.sh`, `relay-turn-lib.sh`). **Fresh**: reflects the 2026-07-17 state of `consult.sh`/GH-226/GH-223, checked directly against the live files, not from memory. **Structured**: one shape (numbered sections matching the task's own ask). **Relevant is the honest miss**: a 4-category taxonomy plus a verdict-layer backstop is more moving parts than the "least code that clears the bar" principle prefers on first instinct; see the weakest-part callout below. |
   242	
   243	**Tie-breakers:** Containment vs. speed — not in tension here (nothing proposed trades containment for
   244	speed). New relay path vs. reuse — reuse, explicitly (Section 2). Ambitious vs. resumable — the v1/
   245	deferred split in Section 4 exists specifically so a future implementer can land v1 alone and stop; it
   246	does not require the deferred items to be resumable.
   247	
   248	**Reject/escalate conditions:** none triggered — no headless path lacking allowlist/isolation/
   249	commit-bypass guard is proposed; "not yet verifiable" is stated honestly rather than claimed as done;
   250	no relay-lane or event-log-kernel change is proposed without a decision record (none is proposed at
   251	all); no hardcoded paths or silent destructive ops.
   252	
   253	**Honest weakest point:** the 4-category split (FIRSTHAND/ECHOED/INFERENCE/UNSUPPORTED-ASSERTED) is
   254	more surface area than the 1-bit check that shipped, and Section 8's heuristic-4 failure is real, not
   255	cosmetic — there is no running code proving any of this actually holds up against a real prompt/
   256	transcript pair yet. A tighter v0 might collapse ECHOED and UNSUPPORTED-ASSERTED into one bucket
   257	("traces to the prompt") for a first cut, deferring the ECHOED/UNSUPPORTED-ASSERTED split (whether the
   258	prompt-echo carries a citation dressing or not) to a follow-up once the prompt-persistence plumbing
   259	and substring-match logic are proven out on real data. This proposal presents the 4-category version
   260	because the task asked for "the distinction itself" in full, but an implementer applying Principle 7

exec
/bin/zsh -lc "nl -ba relay-automation/consult.sh | sed -n '100,360p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-93345-6718
 succeeded in 0ms:
   100	fi
   101	
   102	git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
   103	  || { warn "consult requires a git repo (advisor isolation uses a throwaway worktree): $ROOT"; exit 3; }
   104	
   105	# GH-30 Phase 2: default the run parent to the transcript-root resolver (honors XYZ_ARCHIVE_ROOT).
   106	# An explicit --out (OUT already set) wins and skips the resolver entirely, so an invalid
   107	# XYZ_ARCHIVE_ROOT can never override a caller who named their own --out. Resolver hard-errors loudly.
   108	if [[ -z "$OUT" ]]; then
   109	  _ts_base="$(rtl_transcript_root "$ROOT")" || exit 1
   110	  OUT="$_ts_base/$(date +%F)"
   111	fi
   112	RUN_DIR="$OUT/${LABEL}-$(date +%H%M%S)"
   113	mkdir -p "$RUN_DIR"
   114	
   115	# Advisor preamble: independent, advisory, structured, cite evidence. Each is told a peer answers the
   116	# SAME question separately and a coordinator reconciles — so it gives its OWN read, not a guessed consensus.
   117	PREAMBLE="You are an INDEPENDENT advisor in a one-shot cross-model consult. Another model is answering \
   118	the SAME question separately and a coordinator will reconcile both answers, so give your own honest, \
   119	specific read — do not hedge toward a consensus you cannot see. Read any repo files the question \
   120	references (cite file:line). Respond with: (1) a short direct ANSWER; (2) graded FINDINGS — \
   121	[Blocker]/[Should]/[Nit]/[Pass] — where applicable; (3) a one-line RECOMMENDATION. You are ADVISORY \
   122	ONLY: output your analysis as text; do not rely on writing files (you are running in a throwaway copy)."
   123	FULL_PROMPT="$PREAMBLE
   124	
   125	=== CONSULT QUESTION ===
   126	$PROMPT_TEXT"
   127	
   128	# --- build the throwaway worktree = operator's CURRENT visible state, isolated --------------------
   129	# tracked WIP (staged+unstaged) WITHOUT touching the real tree; falls back to HEAD when clean.
   130	base="$(git -C "$ROOT" stash create 2>/dev/null || true)"; base="${base:-HEAD}"
   131	WT="${TMPDIR:-/tmp}/consult-wt-$$-${RANDOM}"
   132	cleanup() {
   133	  git -C "$ROOT" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"
   134	  git -C "$ROOT" worktree prune >/dev/null 2>&1 || true
   135	}
   136	trap cleanup EXIT
   137	git -C "$ROOT" worktree add --detach "$WT" "$base" >/dev/null 2>&1 \
   138	  || die "could not create isolation worktree (base $base)"
   139	# overlay untracked-not-ignored files so advisors see brand-new files (e.g. a skill being reviewed).
   140	while IFS= read -r -d '' f; do
   141	  mkdir -p "$WT/$(dirname "$f")"
   142	  cp -p "$ROOT/$f" "$WT/$f" 2>/dev/null || true
   143	done < <(git -C "$ROOT" ls-files --others --exclude-standard -z 2>/dev/null)
   144	
   145	# Run an advisor (CWD = throwaway worktree) under a wall-clock cap so a HUNG CLI degrades to a failure
   146	# (collected as [FAIL]) rather than stalling the whole consult. No dependency on coreutils `timeout`
   147	# (absent on stock macOS) — a sleep-then-kill watchdog. Output redirection handled here.
   148	_guarded_with_timeout() {  # <out> <secs> <cmd...>
   149	  local out="$1" secs="$2"; shift 2
   150	  local apid kpid rc=0
   151	  ( cd "$WT" && "$@" < /dev/null ) > "$out" 2>&1 &
   152	  apid=$!
   153	  ( sleep "$secs"; kill -9 "$apid" 2>/dev/null ) >/dev/null 2>&1 &
   154	  kpid=$!
   155	  wait "$apid" || rc=$?
   156	  # GH-109: kill the watchdog's `sleep` GRANDCHILD before the watchdog subshell itself. If we kill
   157	  # $kpid first, its still-running `sleep "$secs"` is orphaned (reparented to PID 1) and keeps
   158	  # sleeping to completion silently — harmless alone, but it accumulates on rapid/repeated consults.
   159	  # `pkill -P "$kpid"` (direct children of the watchdog subshell, macOS/BSD-compatible) reaps it first.
   160	  pkill -P "$kpid" 2>/dev/null || true
   161	  kill "$kpid" 2>/dev/null || true; wait "$kpid" 2>/dev/null || true
   162	  [[ "$rc" != 0 ]] && printf '\nconsult: advisor failed or exceeded the %ss cap\n' "$secs" >> "$out"
   163	  return "$rc"
   164	}
   165	_guarded() {  # <out> <cmd...>
   166	  local out="$1"; shift
   167	  _guarded_with_timeout "$out" "${CONSULT_TIMEOUT:-300}" "$@"
   168	}
   169	agy_auth_preflight() {  # <out> — writes the failure reason into <out> on skip
   170	  local out="$1" secs="${AGY_AUTH_TIMEOUT_S:-5}" tmp rc=0
   171	  tmp="${out}.auth"
   172	  _guarded_with_timeout "$tmp" "$secs" "$AGY_BIN" whoami || rc=$?
   173	  [[ "$rc" -eq 0 ]] && { rm -f "$tmp"; return 0; }
   174	  cat "$tmp" > "$out" 2>/dev/null || true
   175	  if [[ "$rc" -eq 7 ]]; then
   176	    printf '\nconsult: agy auth pre-flight timed out after %ss; likely expired auth opening an interactive login. Run `agy login` in a normal terminal, then retry.\n' "$secs" >> "$out"
   177	  else
   178	    printf '\nconsult: agy auth pre-flight failed (exit %s). Run `agy login` in a normal terminal, then retry.\n' "$rc" >> "$out"
   179	  fi
   180	  rm -f "$tmp"
   181	  return "$rc"
   182	}
   183	
   184	run_codex() {
   185	  local out="$1"; read -ra _f <<<"${CODEX_FLAGS:--s read-only}"
   186	  # Billing guard: strip OPENAI_API_KEY so a consult ALWAYS bills the ChatGPT-subscription login,
   187	  # never per-token API credits (CODEX_ALLOW_API_KEY=1 to opt back in). See codex-turn.sh.
   188	  local cenv=(env); [[ "${CODEX_ALLOW_API_KEY:-0}" == "1" ]] || cenv+=(-u OPENAI_API_KEY)
   189	  # ${_f[@]+...} guards an EMPTY flags array under `set -u` on bash 3.2 (macOS default).
   190	  _guarded "$out" "${cenv[@]}" "$CODEX_BIN" exec ${_f[@]+"${_f[@]}"} "$FULL_PROMPT" || return $?
   191	
   192	  local tmp="${out}.tmp"
   193	  local model="unknown" provider="unknown" sandbox="unknown"
   194	  if [[ -f "$out" ]]; then
   195	    model="$(grep -m1 '^model:' "$out" | sed 's/^model:[[:space:]]*//' || true)"
   196	    provider="$(grep -m1 '^provider:' "$out" | sed 's/^provider:[[:space:]]*//' || true)"
   197	    sandbox="$(grep -m1 '^sandbox:' "$out" | sed 's/^sandbox:[[:space:]]*//' || true)"
   198	    {
   199	      printf '> **ATTESTATION**\n> Model: %s\n> Provider: %s\n> Sandbox: %s\n\n' "${model:-unknown}" "${provider:-unknown}" "${sandbox:-unknown}"
   200	      cat "$out"
   201	    } > "$tmp" && mv "$tmp" "$out"
   202	  fi
   203	}
   204	run_agy() {
   205	  local out="$1" secs="${CONSULT_TIMEOUT:-300}"
   206	  agy_auth_preflight "$out" || return $?
   207	  _guarded "$out" "$AGY_BIN" --dangerously-skip-permissions --print-timeout "${secs}s" -p "$FULL_PROMPT"
   208	  local rc=$?
   209	  if [[ "$rc" -eq 0 && -s "$out" ]]; then
   210	    # GH-178 B1: Detect if agy escaped the isolation worktree ($WT) and read from the real repo root.
   211	    # GH-183/187: filter out false-positive shapes (tick-command narration, markdown file:// citations)
   212	    # before the $ROOT substring scan — same filtering as agy-turn.sh.
   213	    if grep -v -e '^\[trace\] ' -e 'TICK_REPO_ROOT=' -e 'file://' -e '](' "$out" 2>/dev/null | grep -qF "$ROOT" 2>/dev/null; then
   214	      printf '\nconsult: [FAIL] agy transcript cited the real repo root (%s) instead of the isolation worktree. This is a known agy isolation breach (grounding escaped $WT). Failing the turn to prevent a silent breach.\n' "$ROOT" >> "$out"
   215	      return 5
   216	    fi
   217	  fi
   218	  return "$rc"
   219	}
   220	run_gemini() {
   221	  local out="$1"
   222	  export GOOGLE_GENAI_USE_GCA="${GOOGLE_GENAI_USE_GCA:-true}"   # isolated: run_gemini is its own subshell
   223	  if [[ "${CONSULT_GEMINI_JSON:-0}" == "1" ]]; then
   224	    _guarded "$out" "$GEMINI_BIN" --yolo --skip-trust -o json -p "$FULL_PROMPT"
   225	  else
   226	    _guarded "$out" "$GEMINI_BIN" --yolo --skip-trust -p "$FULL_PROMPT"
   227	  fi
   228	}
   229	# Fail closed: Aider can exit 0 while printing an auth/config error transcript, or return only
   230	# reasoning tokens with empty visible content (GH-147 spike 0.1/0.4). Either is a failed advisor, not
   231	# a real answer — trusting the exit code alone false-greens the consult. Scoped to the aider lane.
   232	_aider_answer_ok() {  # <out> — nonzero if the transcript shows failure or has no visible answer
   233	  local out="$1"
   234	  if [[ ! -s "$out" ]] || ! grep -qE '[^[:space:]]' "$out"; then
   235	    printf '\nconsult: Aider returned no visible content (empty answer — likely reasoning-only or a silent failure).\n' >> "$out"
   236	    return 5
   237	  fi
   238	  if grep -qiE 'litellm\.[A-Za-z]*Error|AuthenticationError|Incorrect API key|invalid_api_key|Unable to list models|No API key was provided|NotFoundError|Traceback \(most recent call last\)' "$out"; then
   239	    printf '\nconsult: Aider transcript shows an auth/config failure — counted as FAILED (was exit 0).\n' >> "$out"
   240	    return 5
   241	  fi
   242	  return 0
   243	}
   244	run_aider() {
   245	  local out="$1" model
   246	  local -a auth=()
   247	  # Two seams share the Aider/OpenAI-compatible client (GH-147). If AIDER_OPENAI_API_BASE is set this
   248	  # is the LM Studio / OpenAI-compatible path; otherwise it's the OpenRouter default (byte-identical).
   249	  if [[ -n "${AIDER_OPENAI_API_BASE:-}" ]]; then
   250	    # LM Studio etc.: the client still requires a non-empty key even when the local server ignores it,
   251	    # so a dummy is fine for a keyless endpoint (spike 0.2). No OPENROUTER_API_KEY needed here.
   252	    model="${AIDER_MODEL:-openai/agents-a1}"
   253	    auth=(--openai-api-base "$AIDER_OPENAI_API_BASE" --openai-api-key "${AIDER_OPENAI_API_KEY:-dummy}")
   254	  else
   255	    # OpenRouter is pure API-key; a missing key would make Aider prompt interactively (deadlock under
   256	    # the cap). Skip fast with the remedy — this advisor is counted [FAIL], the others still answer.
   257	    if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
   258	      printf 'consult: OPENROUTER_API_KEY not set — Aider cannot reach OpenRouter (or set AIDER_OPENAI_API_BASE for an OpenAI-compatible/LM Studio endpoint). Export it, then retry.\n' > "$out"
   259	      return 5
   260	    fi
   261	    model="${AIDER_MODEL:-openrouter/anthropic/claude-3.5-sonnet}"
   262	  fi
   263	  # ADVISORY only: pass NO --file (Aider edits nothing) + --no-auto-commits; it answers to stdout, which
   264	  # is exactly what a consult captures.
   265	  _guarded "$out" "$AIDER_BIN" --model "$model" ${auth[@]+"${auth[@]}"} --message "$FULL_PROMPT" \
   266	    --yes-always --no-auto-commits --no-gitignore --no-check-update --no-analytics \
   267	    --no-show-model-warnings --no-stream --map-tokens 0 || return 5
   268	  _aider_answer_ok "$out"
   269	}
   270	
   271	# --- advisor registry (GH-178 A1) ------------------------------------------------------------------
   272	# name -> run-function, as parallel arrays (bash 3.2 / macOS has no `declare -A`; see
   273	# resolve-model-alias.sh for the same convention). Adding a 5th advisor is a DATA addition here — one
   274	# entry in each array plus its own run_<vendor>() — not a new case arm in the fan-out loop below. See
   275	# "Adding a new consult advisor" in relay-automation/README.md for the full recipe.
   276	ADV_NAMES=(codex agy gemini aider)
   277	ADV_RUNFNS=(run_codex run_agy run_gemini run_aider)
   278	
   279	# --- fan out in parallel (indexed arrays — macOS bash 3.2 has no `declare -A`) --------------------
   280	PIDS=(); PMODELS=(); POUTS=()
   281	IFS=',' read -ra _models <<<"$MODELS"
   282	for m in "${_models[@]}"; do
   283	  m="${m// /}"; [[ -n "$m" ]] || continue
   284	  fn=""; i=0
   285	  while ((i < ${#ADV_NAMES[@]})); do
   286	    [[ "${ADV_NAMES[$i]}" == "$m" ]] && { fn="${ADV_RUNFNS[$i]}"; break; }
   287	    i=$((i + 1))
   288	  done
   289	  if [[ -z "$fn" ]]; then warn "unknown model '$m' — skipping"; continue; fi
   290	  ext="md"; [[ "$m" == "gemini" && "${CONSULT_GEMINI_JSON:-0}" == "1" ]] && ext="json"
   291	  f="$RUN_DIR/${LABEL}.${m}.${ext}"
   292	  "$fn" "$f" & PIDS+=("$!"); PMODELS+=("$m"); POUTS+=("$f")
   293	done
   294	((${#PIDS[@]} > 0)) || die "no valid models to consult (got: $MODELS)"
   295	
   296	# --- collect results -----------------------------------------------------------------------------
   297	answered=0; failed=0; summary=""; i=0
   298	survivor_model=""; survivor_out=""; POK=()
   299	while ((i < ${#PIDS[@]})); do
   300	  pid="${PIDS[$i]}"; model="${PMODELS[$i]}"; out="${POUTS[$i]}"
   301	  if wait "$pid"; then
   302	    answered=$((answered + 1)); summary+=$'\n'"  [ok]   $model -> $out"
   303	    survivor_model="$model"; survivor_out="$out"; POK+=(1)
   304	  else
   305	    failed=$((failed + 1));   summary+=$'\n'"  [FAIL] $model -> $out (see transcript for error)"; POK+=(0)
   306	  fi
   307	  i=$((i + 1))
   308	done
   309	
   310	# GH-178 A4 (deliberately narrow slice — NOT the full firsthand-vs-asserted provenance taxonomy; see
   311	# PROJECT/2-WORKING/GH-178-EPISTEMIC-RECONCILIATION-HARDENING.md for what's future-scoped). Mechanically
   312	# stamp any ANSWERED advisor flagged by rtl_has_uncited_claim() (relay-turn-lib.sh, sourced above) —
   313	# shared with B3's per-line downgrade so both use one definition of "claim"/"citation" — with the same
   314	# stdout+prepended-transcript+sidecar mechanism as A2's SINGLE-MODEL stamp. Flags a transcript with
   315	# ZERO citations anywhere (the original A4 spec), OR one with SOME citation but at least one
   316	# [Pass]/verified/confirmed/etc-style claim with no citation nearby it (code-review follow-up on PR
   317	# #184: the original "any citation anywhere in the whole transcript" check let one incidental early
   318	# citation excuse several later uncited claims — see rtl_has_uncited_claim's doc comment). Does NOT
   319	# check whether a present citation is ACCURATE (no citation-verification engine); it only catches a
   320	# claim with no citation attempt near it.
   321	CITELESS_MODELS=(); i=0
   322	while ((i < ${#PIDS[@]})); do
   323	  if [[ "${POK[$i]}" == "1" ]]; then
   324	    model="${PMODELS[$i]}"; out="${POUTS[$i]}"
   325	    if rtl_has_uncited_claim "$out"; then
   326	      CITELESS_MODELS+=("$model")
   327	      nocite="**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional ($model's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)"
   328	      case "$out" in
   329	        *.json) : ;;  # don't corrupt structured output — the sidecar marker below still covers it
   330	        *) { printf '%s\n\n' "$nocite"; cat "$out"; } > "$out.stamped" && mv "$out.stamped" "$out" ;;
   331	      esac
   332	      printf '%s\n' "$nocite" > "$RUN_DIR/${LABEL}.${model}.NO-CITATION.txt"
   333	    fi
   334	  fi
   335	  i=$((i + 1))
   336	done
   337	
   338	# GH-178 A2: a panel that started with MORE THAN ONE requested advisor but ended with exactly one
   339	# survivor is not a reconciled cross-model result — no second read happened, so treating its verdict
   340	# as reconciled is exactly the failure mode this consult exists to avoid. Stamp it MECHANICALLY —
   341	# into the surviving transcript itself, plus a format-agnostic sidecar marker — so the caveat travels
   342	# with the data (a future read of relay-system/<date>/... days later still sees it) instead of living
   343	# only in this run's stdout, which an operator can simply not have watched. Deliberately does NOT
   344	# fire when only one model was ever requested (--models codex alone): that is an intentional
   345	# single-model query, not a degrade, and existing single-model callers must stay unstamped.
   346	DEGRADED=0
   347	if ((${#PIDS[@]} > 1 && answered == 1)); then
   348	  DEGRADED=1
   349	  stamp="**SINGLE-MODEL — NOT RECONCILED** (only $survivor_model answered; $failed of ${#PIDS[@]} requested advisor(s) failed — this is one model's read, not a cross-model consult. Do not treat any claim below as cross-verified.)"
   350	  case "$survivor_out" in
   351	    *.json) : ;;  # don't corrupt structured output — the sidecar marker below still covers it
   352	    *) { printf '%s\n\n' "$stamp"; cat "$survivor_out"; } > "$survivor_out.stamped" \
   353	         && mv "$survivor_out.stamped" "$survivor_out" ;;
   354	  esac
   355	  printf '%s\n' "$stamp" > "$RUN_DIR/DEGRADED-SINGLE-MODEL.txt"
   356	fi
   357	
   358	# --- best-effort cost capture (gemini json mode only; never fails the consult) --------------------
   359	if [[ "${CONSULT_GEMINI_JSON:-0}" == "1" ]]; then
   360	  gj="$RUN_DIR/${LABEL}.gemini.json"

exec
/bin/zsh -lc "nl -ba relay-automation/relay-turn-lib.sh | sed -n '660,760p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-93345-6718
 succeeded in 0ms:
   660	#                        it" bypass the backstop entirely (none of the 3 tokens present), undermining
   661	#                        the "mechanical, not prompt-compliance-dependent" premise for any vocabulary
   662	#                        outside that short list. The [Pass] TAG itself is deliberately NOT folded
   663	#                        into this variable — see the warning below.
   664	#   RTL_CITATION_RE    — a quoted span ("..."/`...`) or a file:line reference (name:NNN).
   665	# WARNING — do not add `\[Pass\]` (or any other backslash-escaped literal) to either of these
   666	# strings. Both are passed to awk via `-v` and matched as a DYNAMIC regex (`line ~ var`); macOS's
   667	# default /usr/bin/awk ("one true awk") string-unescapes a -v value before compiling it as a regex,
   668	# which silently turns the literal string \[Pass\] into the bracket EXPRESSION [Pass] — i.e. "any
   669	# single P, a, or s character" — matching almost every line instead of the literal tag. Caught in
   670	# review of this very follow-up (the widened-vocabulary tests below false-matched an unrelated
   671	# [Blocker] line and a bare "RECOMMENDATION: ship" line). Reproduce with:
   672	#   printf 'xyz\n' | awk -v re='\[Pass\]' '$0 ~ re {print "false match: " $0}'   # prints on macOS awk
   673	# The [Pass] tag check MUST stay an inline `/\[Pass\]/` literal in each awk SCRIPT below (not a -v
   674	# value) — inline /regex/ delimiters are compiled directly, bypassing the -v string-unescape step.
   675	RTL_CLAIM_WORD_RE='(^|[^A-Za-z])([Vv]erified|[Cc]onfirmed|LGTM|[Ll]ooks [Gg]ood|[Cc]hecks [Oo]ut|[Aa]ll [Gg]ood|[Ww]orks [Aa]s [Ee]xpected|[Nn]o issues( found)?)([^A-Za-z]|$)'
   676	RTL_CITATION_RE='"[^"]+"|`[^`]+`|[A-Za-z0-9_./-]+:[0-9]+'
   677	
   678	# GH-173 B3: mechanical uncited-"verified" check. new-relay.sh's own Reviewer template ("▶ TAKE YOUR
   679	# TURN" block) now ASKS for a citation on any [Pass]/"verified" finding, but a prompt instruction is
   680	# model compliance, not a guarantee — Jedi Wright's beta report hit exactly that gap (a "verified"
   681	# claim with no quote). This does NOT verify a citation is ACCURATE (out of scope, no real
   682	# citation-verification engine); it only catches the ABSENCE of one, mechanically, and downgrades the
   683	# claim in place so the caveat is structural rather than trusting the model followed the instruction.
   684	# A "citation" is a quoted span ("..."/`...`) or a file:line reference (name:NNN) within the next
   685	# RTL_CITATION_WINDOW (default 3) lines, INCLUDING the claim's own line (inline citations count).
   686	rtl_check_uncited_findings() {  # <relay_file_path> — rewrites the file in place
   687	  local f="$1" win="${RTL_CITATION_WINDOW:-3}" tmp
   688	  [[ -n "$f" && -f "$f" ]] || return 0
   689	  tmp="${f}.rtlcite.$$"
   690	  awk -v win="$win" -v word_re="$RTL_CLAIM_WORD_RE" -v cite_re="$RTL_CITATION_RE" '
   691	    { line[NR] = $0 }
   692	    END {
   693	      for (i = 1; i <= NR; i++) {
   694	        # already downgraded (prior pass) -> never re-flag. Required for idempotency: a prose "verified"
   695	        # claim is appended-to, not replaced, so the trigger word "verified" is still on the line.
   696	        if (line[i] ~ /\[Unverified — no citation\]/) { print line[i]; continue }
   697	        claim = (line[i] ~ /\[Pass\]/) || (line[i] ~ word_re)
   698	        if (!claim) { print line[i]; continue }
   699	        cited = 0
   700	        for (j = i; j <= NR && j <= i + win; j++) {
   701	          if (line[j] ~ cite_re) { cited = 1; break }
   702	        }
   703	        if (cited) { print line[i]; continue }
   704	        out = line[i]
   705	        if (out ~ /\[Pass\]/) { gsub(/\[Pass\]/, "[Unverified — no citation]", out) }
   706	        else { out = out "  [Unverified — no citation]" }
   707	        print out
   708	      }
   709	    }
   710	  ' "$f" > "$tmp" && mv "$tmp" "$f"
   711	}
   712	
   713	# GH-178 A4 follow-up (code review on PR #184): read-only predicate reused by consult.sh's advisor
   714	# citeless-stamp so B3 and A4 share one definition of "claim"/"citation" rather than two independent
   715	# implementations drifting apart. Flags <file> as having an uncited claim if EITHER (a) the file has
   716	# ZERO citations anywhere (the original A4 spec — "carries zero explicit citations anywhere"), OR
   717	# (b) at least one claim-bearing line's own RTL_CITATION_WINDOW has no citation nearby, even though
   718	# the file cites something elsewhere. (b) is the fix for the gap the code review flagged: the
   719	# original consult.sh check only asked "is there a citation ANYWHERE in the whole transcript" — one
   720	# incidental citation early in a long answer let several later uncited [Pass]/verified claims slip
   721	# through unflagged. Mirrors grep -q's convention: exit 0 (true) = flag it, exit 1 = adequately cited.
   722	# Missing/unreadable file fails safe (flagged), matching the old grep-based check's behavior on a
   723	# missing $out.
   724	rtl_has_uncited_claim() {  # <file>
   725	  local f="$1" win="${RTL_CITATION_WINDOW:-3}"
   726	  [[ -n "$f" && -f "$f" ]] || return 0
   727	  awk -v win="$win" -v word_re="$RTL_CLAIM_WORD_RE" -v cite_re="$RTL_CITATION_RE" '
   728	    { line[NR] = $0; if ($0 ~ cite_re) any_cite = 1 }
   729	    END {
   730	      flag = !any_cite
   731	      for (i = 1; i <= NR && !flag; i++) {
   732	        if (line[i] ~ /\[Unverified — no citation\]/) continue
   733	        claim = (line[i] ~ /\[Pass\]/) || (line[i] ~ word_re)
   734	        if (!claim) continue
   735	        cited = 0
   736	        for (j = i; j <= NR && j <= i + win; j++) {
   737	          if (line[j] ~ cite_re) { cited = 1; break }
   738	        }
   739	        if (!cited) flag = 1
   740	      }
   741	      exit (flag ? 0 : 1)
   742	    }
   743	  ' "$f"
   744	}
   745	
   746	rtl_enforce() {  # <task> <agent> <log> <tool>
   747	  local task="$1" agent="$2" log="$3"; RTL_TOOL="$4"
   748	  # (2) commit-bypass guard: the agent must NOT git. If HEAD moved, its edits are hidden from
   749	  # `git status` — undo the commit(s) and fail, so off-lane changes can't slip in committed.
   750	  if [[ "$(git -C "$RTL_ROOT" rev-parse HEAD 2>/dev/null || echo none)" != "$RTL_BEFORE_HEAD" ]]; then
   751	    if [[ "${RTL_WT_USED:-0}" == "1" ]]; then
   752	      # GH-13: this turn ran in a throwaway worktree, so the agent CANNOT have moved ROOT's HEAD — a
   753	      # moved ROOT HEAD is therefore a CONCURRENT PEER commit. Never reset it: a blind `reset --hard`
   754	      # here orphaned a peer agent's commit on 2026-06-23 (recovered via reflog). The agent's own writes
   755	      # were already contained by rtl_worktree_end (off-lane → exit 6; else allowlist copyback), so just
   756	      # preserve the peer commit and fall through to allowlist enforcement + a file-scoped commit ON TOP.
   757	      printf '%s-turn: ROOT HEAD moved during a worktree-isolated turn — a concurrent peer committed; preserving it (not resetting), committing this turn on top.\n' "$RTL_TOOL" >&2
   758	      rtl_log_always "rtl_enforce: HEAD_MOVED branch=peer-preserve (worktree-isolated; concurrent peer commit kept)"
   759	    else
   760	      # In-ROOT (direct/attended) turn: the agent ran in ROOT and may have committed off-lane changes.

codex
I have the core behavior pinned down from the live files. I’m doing one graph pass now so I can confirm the symbol-level entry points for the shared citation logic rather than relying only on raw file reads.
mcp: codebase-memory-mcp/index_repository started
mcp: codebase-memory-mcp/index_repository (failed)
user cancelled MCP tool call
codex
The graph indexer isn’t usable in this sandboxed consult, so I’m finishing from direct reads. I’m pulling the proposal’s later sections now to see whether its own “honest weakest point” already points to a smaller durable slice or just a temporary band-aid.
exec
/bin/zsh -lc "nl -ba PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md | sed -n '260,420p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-93345-6718
 succeeded in 0ms:
   260	because the task asked for "the distinction itself" in full, but an implementer applying Principle 7
   261	strictly should seriously consider shipping the 2-category collapse first.
   262	
   263	---
   264	
   265	## 6. External dependency gap — `ra-to-xyz-transfer.md`
   266	
   267	That document is not in this repo and was not available to write this proposal — confirmed absent,
   268	referenced-not-vendored per GH-178's own Non-goals. Before finalizing this taxonomy for
   269	implementation, it should be checked against that document for at least three things: (1) whether its
   270	"advisor echo" failure mode is defined more precisely or differently than this proposal's ECHOED
   271	category guesses at, in which case this taxonomy's terminology and mechanical test should be
   272	reconciled to match rather than drift into a second, competing definition of the same concept; (2)
   273	whether "false consensus," "reconciler laundering," "prompt drift," or "model-version drift" imply
   274	additional mechanical checks that belong in this same v1 slice rather than being deferred, if any of
   275	them turn out to be cheap; and (3) whether the "seven transfers" it defines include a transfer this
   276	taxonomy's Section 1 categories map onto directly, which would mean adopting that document's naming
   277	instead of this proposal's ad hoc one. Anyone implementing this should either obtain and read that
   278	document first, or explicitly accept (as GH-178's own Non-goals already does) proceeding without it
   279	and risk a later terminology/scope reconciliation pass.
   280	
   281	---
   282	
   283	## 7. Process recommendation
   284	
   285	**Recommendation: file this as its own new GitHub issue, explicitly linked to and coordinated with
   286	#226 — do not reopen #178, and do not fold it silently into #226 as buried scope.**
   287	
   288	Reasoning:
   289	
   290	- **Principle 11 (issue-first)** requires a GH issue before any non-trivial change lands, and this is
   291	  unambiguously non-trivial — new persisted state (a prompt sidecar), a new classification predicate,
   292	  a new sidecar format, and a `skills/consult/SKILL.md` edit. It is well past the "≤2-3 line fix"
   293	  exemption.
   294	- **Not #178**: that issue's own Status line already reads "all five #178 items now have a shipped
   295	  fix," and its Non-goals section explicitly says "A future issue can pick up the fuller distinction"
   296	  — #178 is written and closed-shaped as a finished record of what shipped 2026-07-08. Reopening it to
   297	  attach a materially different, larger, unshipped design would blur that historical record and
   298	  violate the same "one canonical source of truth, no drift" spirit (Principle 2) this proposal is
   299	  itself trying to serve — #178 should stay the record of what happened, not become the record of
   300	  what might happen next.
   301	- **Not silently folded into #226**: #226 is a *coordination* issue — its explicit job (see its
   302	  Definition of done) is to inventory the GH-211 summary-surface work and this taxonomy's future
   303	  home, and decide whether they land as one pass or split. Its own Non-goals says "Not implementing
   304	  the fuller provenance taxonomy in this capture doc" — meaning #226 has already declared this
   305	  document's content out of its own scope. Treating this proposal as done once #226 exists would
   306	  contradict #226's own stated boundary.
   307	- **A new, linked issue respects both**: it gives this design its own machine-queryable signal stream
   308	  (satisfying Principle 11) while explicit `related:` links (already in this doc's frontmatter) keep
   309	  #226's coordination question answerable — #226 can decide, once this issue exists, whether its
   310	  execution happens standalone or merges into whatever #226 spins off. That ordering also respects
   311	  GH-226's own Definition of done, which anticipates exactly this branch ("promote #226... or split
   312	  into narrower follow-up issue(s)").
   313	
   314	Concretely: open the new issue referencing this document, cross-link it from both #178 (as "the
   315	future issue" its Non-goals already promised) and #226 (as one of the "narrower follow-up issues" its
   316	Definition of done anticipates), and let #226's coordination question resolve before implementation
   317	starts — implementing this taxonomy's v1 before knowing whether the operator-facing surface is being
   318	reworked again by #226 risks exactly the double-edit GH-226 exists to prevent.

codex
I’ve confirmed the proposal itself already acknowledges a tighter first cut. I’m checking the current consult reconciliation instructions once so I can size how invasive the proposed backstop really is, instead of hand-waving about “just a skill edit.”
exec
/bin/zsh -lc "nl -ba skills/consult/SKILL.md | sed -n '1,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-93345-6718
 succeeded in 0ms:
     1	---
     2	name: consult
     3	description: One-shot cross-model CONSULT — fan the same question out to Codex and agy in parallel (repo-isolated, advisory), then reconcile their answers into one. Use when the user wants a "second opinion", to "ask Codex and agy", a "panel" or "cross-model" check, or an independent gut-check on a decision/design/doc before committing — and does NOT need an iterative build/review loop. NOT a relay: a relay is an iterative 1:1 Producer↔Reviewer loop that converges an artifact; a consult is a parallel 1-shot 1:N second opinion, reconciled once. Depends on the codex + agy CLIs and the relay-automation shims; runs in any repo that ships them at the repo root OR in a vendored `.xyz/` install (the skill resolves either).
     4	---
     5	
     6	# Consult
     7	
     8	**One question → N independent models in parallel → one reconciled answer.**
     9	
    10	A consult asks Codex and agy the *same* question at the same time, isolated from your real tree, and then a
    11	coordinator (Claude) reconciles their answers — surfacing where they **agree**, where they
    12	**disagree**, and giving a single reconciled **call**. It is the fast "ask the other brains before I
    13	commit" move: no copy-paste, no window-shuttling, one step.
    14	
    15	## Consult vs. relay — pick the right tool
    16	
    17	| | **consult** (this skill) | **relay** |
    18	|---|---|---|
    19	| shape | parallel fan-out, 1 question → N models | iterative loop, 2 agents |
    20	| rounds | exactly **one** | many, until `Approved` |
    21	| writes | **none** — advisory only | Producer edits the artifact |
    22	| output | reconciled answer + divergences | a converged artifact |
    23	| use for | a decision, a design gut-check, "is this doc sound?" | building/fixing an artifact under review |
    24	
    25	If after a consult you decide the work needs iteration, *start a relay* — the consult is the cheap
    26	first look, the relay is the build loop.
    27	
    28	## When to use
    29	
    30	- "Get a second opinion." "Ask Codex and agy." "What do the other models think?"
    31	- "Panel review" / "cross-model check" / "sanity-check this before I commit."
    32	- An independent gut-check on a plan, design, schema, or doc — where you want *divergent* reads, not
    33	  a single model's confident answer.
    34	
    35	Do **not** use it to build or fix an artifact iteratively — that's `relay`.
    36	
    37	## How it works
    38	
    39	`relay-automation/consult.sh` (path is relative to **this repo's root**, not your cwd) fans the question
    40	out to both advisors **in parallel** and writes each transcript to a per-run dir
    41	`relay-system/<today>/<label>-<HHMMSS>/`. The synthesis is **yours** — the script only gathers the raw
    42	opinions.
    43	
    44	**Locating the script — resolve it cwd-independently; never assume your cwd is the repo root.** A bare
    45	`consult.sh` or `relay-automation/consult.sh` only resolves when you happen to be sitting at the root,
    46	so invoke it through its repo-root anchor instead. Two homes are supported so consult works both in
    47	the `xyz-3-agents-swarm` checkout **and** in any repo that has a vendored `.xyz/` install: the
    48	top-level `relay-automation/` if present, otherwise the vendored `.xyz/relay-automation/`.
    49	
    50	```
    51	ROOT="$(git rev-parse --show-toplevel)"
    52	SCRIPT="$ROOT/relay-automation/consult.sh"
    53	[ -f "$SCRIPT" ] || SCRIPT="$ROOT/.xyz/relay-automation/consult.sh"
    54	# CONSULT_ROOT MUST be the repo root: consult.sh otherwise infers its root as the script's parent-of-
    55	# parent, which for the vendored copy is `.xyz/` (wrong). Setting it pins the consult to the real repo
    56	# and its `relay-system/` output. Harmless (a no-op) for the top-level copy.
    57	CONSULT_ROOT="$ROOT" "$SCRIPT" --prompt "…" --label …
    58	```
    59	
    60	`git rev-parse --show-toplevel` works from any subdirectory of the repo. If you are not inside a repo
    61	that has consult (no top-level `relay-automation/` and no `.xyz/`), either `cd` into the
    62	`xyz-3-agents-swarm` worktree, or vendor a `.xyz/` into the target repo first
    63	(`relay-automation/xyz-vendor.sh <repo>`). (Do **not** go hunting the disk for `consult.sh`; the
    64	anchor above always finds it.)
    65	
    66	**Provable no-mutation boundary (not best-effort).** Advisors run with their working directory set to a
    67	**throwaway git worktree** checked out from your *current* state — tracked WIP (via `git stash create`)
    68	plus untracked-non-ignored files copied in — so they see your working state (minus `.gitignore`d
    69	files), including a brand-new file under
    70	review. Anything an advisor writes lands in that disposable worktree and is destroyed with it; your
    71	real working tree is **never** the advisors' surface, so there is nothing to revert and ambient WIP
    72	cannot be clobbered. (Codex additionally runs `-s read-only`.) This replaced an earlier best-effort
    73	post-hoc revert that the skill's own first dogfood flagged as unsafe.
    74	
    75	```
    76	consult.sh --prompt-file Q.md            # question is the file's contents (may reference repo paths)
    77	consult.sh --prompt "Is X sound?"        # inline question
    78	  [--models codex,agy]                   # which advisors (default both)
    79	  [--out DIR]                            # parent dir (default relay-system/<today>/)
    80	  [--label SLUG]                         # run-subdir + transcript stem (default "consult")
    81	```
    82	
    83	Each run gets its own `<label>-<HHMMSS>/` subdir, so two consults the same day never overwrite each
    84	other. Behavior is covered by `test/consult.sh` in `validate.sh` (WIP preservation, no advisor leak,
    85	graceful degrade, non-git refusal).
    86	
    87	Exit `0` = at least one advisor answered; `5` = all failed; `3` = not a git repo (isolation needs
    88	one); `2` = usage. Per-model failures are reported, not fatal — if Codex's backend is down, Gemini's
    89	answer still comes back (**graceful degrade**, and the degrade is stated, never silent).
    90	
    91	## Steps (the coordinator's job)
    92	
    93	1. **Frame one sharp question.** Put it in a prompt file when it references repo paths (the advisors
    94	   read the files themselves). Be explicit about what "good" looks like, just like a relay's
    95	   Definition of Done.
    96	2. **Fan out:** run the script through its repo-root anchor (see "Locating the script" above — prefer
    97	   `$ROOT/relay-automation/consult.sh`, fall back to `$ROOT/.xyz/relay-automation/consult.sh`, and
    98	   always pass `CONSULT_ROOT="$ROOT"`) with the prompt + a `--label`. Both models run at once. Don't
    99	   invoke a bare `consult.sh`; it only resolves at the repo root.
   100	3. **Read both transcripts** in `relay-system/<today>/<label>-<HHMMSS>/<label>.codex.md` and `…agy.*`.
   101	4. **Reconcile — this is the load-bearing step.** Produce a synthesis with four parts, in this order:
   102	   - **TLDR** (new — one to two sentences, before anything else): the reconciled call and how confident
   103	     it is, so the operator can stop reading right there if that's all they need. e.g. *"Both models
   104	     agree the migration is safe — go ahead. Codex flagged one edge case worth a follow-up (see below)."*
   105	   - **Disagree** (it's the whole point of asking two models): every point the two differ on, with your
   106	     adjudication and *why*. Never in the TLDR — the TLDR previews the call, it doesn't bury the split.
   107	   - **Agree:** what both independently converged on (higher confidence because it's cross-model).
   108	   - **Sorted categories** (new — closes the synthesis, replaces a bare prose recommendation): bucket
   109	     every point either advisor raised — agreements and adjudicated disagreements alike — into exactly
   110	     one:
   111	     - **Blocking** — a real risk either advisor surfaced; must address before proceeding.
   112	     - **Worth doing, optional** — a real improvement; the operator's call.
   113	     - **Skip / out of scope** — noted and dismissed, named so it doesn't resurface.
   114	     Drop empty buckets. For a short, clean consult (both advisors agree, one or two minor notes),
   115	     skip the buckets and give the recommendation as plain prose instead — don't force structure on a
   116	     synthesis with nothing to sort.
   117	5. **Hand the synthesis back** to the operator. If it reveals the work needs iteration, offer to
   118	   start a `relay`.
   119	
   120	## The one rule that makes a consult worth running
   121	
   122	**Surface disagreement; never average it away.** The entire value of asking two models is the *delta*
   123	between them — the place one caught what the other missed. A synthesis that smooths two answers into
   124	one confident paragraph throws that away and is worse than asking one model, because it launders two
   125	guesses into false consensus. Lead with the disagreements, adjudicate them explicitly, and if you
   126	can't adjudicate one, say so and flag it for the human. (Same failure mode as a review that only
   127	hunts overclaims and misses silent drops: the easy direction satisfices.)
   128	
   129	## Honest caveats
   130	
   131	- **Two models, not ground truth.** Cross-model agreement raises confidence; it does not prove
   132	  correctness — both can share a blind spot or a wrong prior. Treat a unanimous answer as *strong
   133	  signal*, not proof, especially when correctness rides on runtime behavior neither model ran.
   134	- **Repo-isolated, not process-sandboxed.** Advisors run in a throwaway worktree and cannot reach
   135	  your real tree, so a consult never changes your code even if an advisor ignores the "advisory only"
   136	  instruction. Be precise about the boundary: this protects your *repository*, not the *host process*.
   137	  Codex additionally runs `-s read-only`; agy runs with `--dangerously-skip-permissions` and is
   138	  repo-isolated but not a sandboxed process (it can still reach the network / the host outside the
   139	  worktree). For a hard process boundary, run consult inside your own sandbox. If a fix is needed,
   140	  *you* (or a relay) apply it — the independent check stays independent.
   141	- **The worktree shows tracked + untracked state, not ignored files.** `.gitignore`d local context is
   142	  excluded from what advisors see; reference it inline in the question if it matters.
   143	- **Cost capture is not available for agy.** agy has no JSON/token output, so an agy lane is cost-blind
   144	  (a floor). Codex token parsing is also still deferred. Neither lane captures `tick cost` events in a consult.
   145	- **Needs the shims present, but is not tied to one repo.** Unlike `relay` (model-agnostic, file-only),
   146	  consult hard-depends on the `codex` + `agy` CLIs being installed and authed and on the
   147	  `relay-automation` shims. Those shims can live at the repo root **or** in a vendored `.xyz/` install,
   148	  so any repo carrying a `.xyz/` (see `relay-automation/xyz-vendor.sh`) can run consult standalone.
   149	
   150	## Gotcha: run consult OUTSIDE Claude Code's Bash sandbox
   151	
   152	If you launch `consult.sh` from a Claude Code session, **disable the Bash sandbox for that call**
   153	(`dangerouslyDisableSandbox: true`). **Both advisors fail under the sandbox:**
   154	- **Codex** — the sandbox blocks the macOS keychain (`no native root CA certificates found` / `No keychain is available`) and does not allowlist `chatgpt.com`.
   155	- **agy** — the sandbox blocks agy's backend network; `agy -p` exits 0 with **empty output** (the shim treats this as a hard failure, exit 5).
   156	
   157	The symptom is a two-sided `0 answered, 2 failed` degrade. Disabling the sandbox here is safe:
   158	consult's isolation comes from its **throwaway worktree** (and Codex's own `-s read-only`), not from
   159	the Bash sandbox, so nothing is weakened.
   160	
   161	## What success looks like
   162	
   163	The operator asks one question and gets back a single, honest, reconciled answer that **shows its
   164	seams** — what the two models agreed on, where they split, and which way the coordinator called it and
   165	why — in one step, with both raw transcripts on disk for audit.

codex
I’ve sized the current consult surface. One last pass through the tests will tell me whether v0 can ride the existing verification seam cleanly or whether v1 already implies immediate new coverage on multiple layers.
exec
/bin/zsh -lc "rg -n \"NO FIRSTHAND VERIFICATION CITED|rtl_has_uncited_claim|PROVENANCE|ECHOED|UNSUPPORTED-ASSERTED|INFERENCE\" test/consult.sh relay-automation -g '"'!**/*.pyc'"'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-93345-6718
 succeeded in 0ms:
test/consult.sh:192:# gets mechanically stamped NO FIRSTHAND VERIFICATION CITED — stdout, prepended-into-transcript, and a
test/consult.sh:204:printf '%s' "$out" | grep -q "NO FIRSTHAND VERIFICATION CITED for: codex" && pass "uncited answer warned on stdout" \
test/consult.sh:205:  || fail "stdout missing NO FIRSTHAND VERIFICATION CITED warning: $out"
test/consult.sh:207:grep -q "NO FIRSTHAND VERIFICATION CITED" "$ncfile" 2>/dev/null && pass "uncited answer stamped INTO the transcript" \
test/consult.sh:208:  || fail "transcript missing NO FIRSTHAND VERIFICATION CITED stamp: $ncfile"
test/consult.sh:226:printf '%s' "$out" | grep -q "NO FIRSTHAND VERIFICATION CITED" && fail "cited answer wrongly stamped: $out" \
test/consult.sh:229:grep -q "NO FIRSTHAND VERIFICATION CITED" "$cfile4" 2>/dev/null && fail "cited transcript wrongly stamped" \
test/consult.sh:247:printf '%s' "$out" | grep -q "NO FIRSTHAND VERIFICATION CITED for: codex" \
relay-automation/consult.sh:312:# stamp any ANSWERED advisor flagged by rtl_has_uncited_claim() (relay-turn-lib.sh, sourced above) —
relay-automation/consult.sh:318:# citation excuse several later uncited claims — see rtl_has_uncited_claim's doc comment). Does NOT
relay-automation/consult.sh:325:    if rtl_has_uncited_claim "$out"; then
relay-automation/consult.sh:327:      nocite="**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional ($model's answer carries an unsupported [Pass]/verified/confirmed-style claim with no quoted span or file:line citation nearby, despite the consult PREAMBLE asking advisors to cite evidence.)"
relay-automation/consult.sh:369:((${#CITELESS_MODELS[@]} > 0)) && warn "NO FIRSTHAND VERIFICATION CITED for: ${CITELESS_MODELS[*]} (stamped into transcript(s) + sidecar(s) in $RUN_DIR)"
relay-automation/relay-turn-lib.sh:655:# rtl_has_uncited_claim's read-only predicate (used by consult.sh's A4 stamp) — so the two stay in
relay-automation/relay-turn-lib.sh:724:rtl_has_uncited_claim() {  # <file>

exec
/bin/zsh -lc "nl -ba test/consult.sh | sed -n '180,260p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-93345-6718
 succeeded in 0ms:
   180	  bash "$CONSULT" --prompt "x" --out "$OUT" --label t --models aider 2>&1)"; rc=$?
   181	[ "$rc" -eq 5 ] && pass "aider exit-0 empty answer -> FAILED (all-fail exit 5)" || fail "empty answer: exit=$rc (expected 5) ($out)"
   182	
   183	# --- (11) LM Studio seam: AIDER_OPENAI_API_BASE runs WITHOUT OPENROUTER_API_KEY (GH-147) -------------
   184	rm -rf "$OUT"
   185	out="$(env -u OPENROUTER_API_KEY CONSULT_ROOT="$A" AIDER_BIN="$AIDER_STUB" \
   186	  AIDER_OPENAI_API_BASE="http://127.0.0.1:1234/v1" \
   187	  bash "$CONSULT" --prompt "review please" --out "$OUT" --label t --models aider 2>&1)"; rc=$?
   188	[ "$rc" -eq 0 ] && pass "LM Studio base URL answers with no OPENROUTER_API_KEY (exit 0)" || fail "lmstudio seam exit=$rc ($out)"
   189	printf '%s' "$out" | grep -q "1 answered, 0 failed" && pass "LM Studio-backed aider counted answered" || fail "lmstudio not counted: $out"
   190	
   191	# --- (12) GH-178 A4 (scoped slice): an advisor answer with ZERO file:line/quote citations anywhere ----
   192	# gets mechanically stamped NO FIRSTHAND VERIFICATION CITED — stdout, prepended-into-transcript, and a
   193	# per-advisor sidecar file. This is presence/absence only, not accuracy verification.
   194	NOCITE_STUB="$WORK/nocite-stub"
   195	cat >"$NOCITE_STUB" <<'EOF'
   196	#!/usr/bin/env bash
   197	printf 'ANSWER: this looks correct.\n[Pass] no issues found\nRECOMMENDATION: ship\n'
   198	EOF
   199	chmod +x "$NOCITE_STUB"
   200	rm -rf "$OUT"
   201	out="$(CONSULT_ROOT="$A" CODEX_BIN="$NOCITE_STUB" CODEX_FLAGS=" " \
   202	  bash "$CONSULT" --prompt "review please" --out "$OUT" --label t --models codex 2>&1)"; rc=$?
   203	[ "$rc" -eq 0 ] && pass "uncited-answer run still exits 0 (mechanical stamp only, not a failure)" || fail "uncited-answer exit=$rc"
   204	printf '%s' "$out" | grep -q "NO FIRSTHAND VERIFICATION CITED for: codex" && pass "uncited answer warned on stdout" \
   205	  || fail "stdout missing NO FIRSTHAND VERIFICATION CITED warning: $out"
   206	ncfile="$(ls "$OUT"/t-*/t.codex.md 2>/dev/null | head -1)"
   207	grep -q "NO FIRSTHAND VERIFICATION CITED" "$ncfile" 2>/dev/null && pass "uncited answer stamped INTO the transcript" \
   208	  || fail "transcript missing NO FIRSTHAND VERIFICATION CITED stamp: $ncfile"
   209	grep -q "ANSWER: this looks correct." "$ncfile" 2>/dev/null && pass "stamping preserved the real answer beneath it" \
   210	  || fail "stamping corrupted the transcript content: $ncfile"
   211	sidecar4="$(dirname "$ncfile")/t.codex.NO-CITATION.txt"
   212	[ -s "$sidecar4" ] && pass "per-advisor NO-CITATION sidecar file written" || fail "no sidecar marker at $sidecar4"
   213	
   214	# --- (13) GH-178 A4 non-regression: an advisor answer where EVERY claim is cited near itself (quote
   215	# or file:line) is NOT stamped. Each claim carries its OWN nearby citation (not just one citation
   216	# somewhere in the transcript) — see test (14) below for why that distinction matters post-follow-up.
   217	CITE_STUB="$WORK/cite-stub"
   218	cat >"$CITE_STUB" <<'EOF'
   219	#!/usr/bin/env bash
   220	printf 'ANSWER: confirmed by "return true always" at relay-automation/consult.sh:266.\n[Pass] verified — see relay-automation/consult.sh:266\nRECOMMENDATION: ship\n'
   221	EOF
   222	chmod +x "$CITE_STUB"
   223	rm -rf "$OUT"
   224	out="$(CONSULT_ROOT="$A" CODEX_BIN="$CITE_STUB" CODEX_FLAGS=" " \
   225	  bash "$CONSULT" --prompt "review please" --out "$OUT" --label t --models codex 2>&1)"; rc=$?
   226	printf '%s' "$out" | grep -q "NO FIRSTHAND VERIFICATION CITED" && fail "cited answer wrongly stamped: $out" \
   227	  || pass "cited answer (quote + file:line) is not stamped"
   228	cfile4="$(ls "$OUT"/t-*/t.codex.md 2>/dev/null | head -1)"
   229	grep -q "NO FIRSTHAND VERIFICATION CITED" "$cfile4" 2>/dev/null && fail "cited transcript wrongly stamped" \
   230	  || pass "cited transcript not stamped"
   231	[ -f "$(dirname "$cfile4")/t.codex.NO-CITATION.txt" ] && fail "sidecar wrongly written for a cited answer" \
   232	  || pass "no sidecar written for a cited answer"
   233	
   234	# --- (14) code-review follow-up on PR #184 (items 1 & 3): a SECOND, LATER claim with no citation
   235	# nearby it now gets flagged even though the transcript cites something earlier. The original A4
   236	# check only asked "is there a citation ANYWHERE in the whole transcript" — one early citation would
   237	# have excused this later uncited [Pass] claim. It now correctly does not.
   238	PARTIAL_CITE_STUB="$WORK/partial-cite-stub"
   239	cat >"$PARTIAL_CITE_STUB" <<'EOF'
   240	#!/usr/bin/env bash
   241	printf 'ANSWER: confirmed by "return true always" at relay-automation/consult.sh:266.\nLater: [Pass] this other part also looks fine\nRECOMMENDATION: ship\n'
   242	EOF
   243	chmod +x "$PARTIAL_CITE_STUB"
   244	rm -rf "$OUT"
   245	out="$(CONSULT_ROOT="$A" CODEX_BIN="$PARTIAL_CITE_STUB" CODEX_FLAGS=" " \
   246	  bash "$CONSULT" --prompt "review please" --out "$OUT" --label t --models codex 2>&1)"; rc=$?
   247	printf '%s' "$out" | grep -q "NO FIRSTHAND VERIFICATION CITED for: codex" \
   248	  && pass "a later uncited claim is flagged despite an earlier unrelated citation (per-claim, not whole-transcript)" \
   249	  || fail "later uncited claim NOT flagged despite an earlier citation excusing it: $out"
   250	pfile4="$(ls "$OUT"/t-*/t.codex.md 2>/dev/null | head -1)"
   251	grep -q "this other part also looks fine" "$pfile4" 2>/dev/null && pass "stamping preserved the real answer beneath it" \
   252	  || fail "stamping corrupted the transcript content: $pfile4"
   253	
   254	
   255	# --- (15) GH-215: XYZ_PYTHON=1 parity — the Python port must stamp SINGLE-MODEL — NOT RECONCILED
   256	# the same way Bash does. GH-172's prior audit found the tick-root/cost-routing fix landed in
   257	# utils/py/consult.py but the degraded-panel stamp (GH-178 A2) was never ported, so a Python-mode
   258	# consult run under a single-advisor-answered condition silently reported as if reconciled. This
   259	# forces XYZ_PYTHON=1 explicitly (independent of how the rest of this file is invoked) so the
   260	# regression is caught even under a plain `bash test/consult.sh` run.

codex
I have enough on the shipped mechanics. I’m grabbing exact line numbers for Principle 7 and the reuse tie-breaker so the scope call is anchored to the repo’s stated standard, not my preference.
exec
/bin/zsh -lc "nl -ba GUIDING-PRINCIPLES.md | sed -n '1,220p'" in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/consult-wt-93345-6718
 succeeded in 0ms:
     1	# Guiding Principles
     2	
     3	North star for **xyz-3-agents-swarm**, the multi-agent coordination harness behind the `tick` event-log kernel and `relay-automation/` relay stack. When a choice is unclear, the option that keeps agents synchronized, contained, and verifiable — without leaking or destroying work — wins. AGENTS.md is the behavioral playbook; ROUTER.md is the entry-point map; this is the *why*.
     4	
     5	## Purpose
     6	
     7	`tick` coordinates Claude Code, Codex, and agy (Antigravity CLI) on the same branch without collision: a shared local event log under `.tick/events/`, claims serialized by `O_EXCL` locks, and a `Marathon` harness that chains multi-phase build→review cycles from a `MARATHON.yaml`. The relay layer (`relay-automation/`) drives headless turns, isolates agent writes to worktrees, and enforces an allowlist so no headless agent destroys work it didn't intend to touch. The goal: a multi-agent swarm safe enough to run against a real external codebase and correct enough that its output is worth shipping.
     8	
     9	## The quality bar
    10	
    11	Every agent turn is a signal. A turn is high-quality only when it is all four:
    12	
    13	- **Attested** — carries its receipts: source, evidence, confidence. Never a bare verdict. A relay review names which claim is wrong and why; a build turn names the seam it touched.
    14	- **Relevant** — ranked, not dumped. Volume is not value. One real bug beats five nits and a phantom.
    15	- **Fresh** — current, not stale. A turn that reads a stale `STATE.md` or misses an epoch fence is wrong by construction.
    16	- **Structured** — one shape, clean for the operator to read and for downstream agents to feed on.
    17	
    18	Fail a pillar, and the turn, feature, or relay review isn't done.
    19	
    20	## How it's built
    21	
    22	1. **Coordination is local-transport only.** `.tick/events/` is the shared bus; claims resolve from there, not from a remote. No per-event push/fetch; no remote dependency at runtime. A coordination primitive that reaches out is a coordination primitive that can fail or leak.
    23	
    24	2. **One canonical event log; every surface is a projection.** `tick` accretes events; `STATE.md` is the current projection. Reads go through the projection; writes go through a `claim/take/scope/done` verb. Nothing canonical lives in two places where it can drift. An agent that hard-codes state outside `.tick/` is creating drift.
    25	
    26	3. **Containment is non-negotiable.** A headless turn must not: self-commit mid-turn, orphan a peer's concurrent commit, or write outside its allowlist. The allowlist, worktree isolation, and commit-bypass guard exist because a driven agent will do all three if unconstrained — not hypothetically, but as documented live incidents (GH-13, GH-14, GH-17). New relay paths must clear the containment bar before they ship.
    27	
    28	4. **Skill-first; never improvise the harness.** The `relay-xyz` skill owns the locator, sandbox rules, exit codes, and the safety boundary. A session that improvises those from `ls relay-automation/` silently skips the skill's safety layer. The `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) enforces this by blocking driver calls before the skill loads. Add capabilities to the skill; do not work around it.
    29	
    30	5. **Adversarially proven before commercially viable.** The harness exists to run against real codebases. Features in the adversarial-hardening track (epoch fencing, chaos suite, cross-repo E2E) must be verified to survive deliberate abuse — stale writers, zombie claims, macOS case-sensitivity, concurrent peer commits — not just the happy path. A feature that clears the happy path and skips chaos is half-done.
    31	
    32	6. **Build durable, not band-aid.** Durable means it removes the root cause and the next planned change builds on it — not a patch torn out when the obvious next feature lands. A band-aid is wasted work unless a demo strictly needs one, and a demo band-aid is tagged for removal so it isn't silently inherited.
    33	
    34	7. **Least code that clears the bar.** Node standard library only — no deps, no lockfile; the repo ships no root manifest. Prefer reusing or extending what exists; the smallest change that stays correct, contained, and durable wins. Net-new code is a cost to justify. Deleting code counts as progress.
    35	
    36	8. **Honest; the operator decides.** Surface what failed and why — never mask a stall as success or an escalation as a stall. A headless turn self-repairs within a bounded exit-code menu (`exit 3` stall, `exit 4` escalated-by-design, `exit 6` containment revert), then stops; it never loops forever or silently swallows an error. Destructive actions require explicit authorization.
    37	
    38	9. **Docs are resumable runtime state (PDDA).** Agent work is stoppable, resumable, and handed off from `PROJECT/**` alone — ROUTER points, project docs hold detail, CHANGELOG logs dated outcomes. ROADMAP.md is a pointer/ledger only; execution detail lives in the linked `PROJECT/**` doc. If reality and the docs disagree, the docs are the bug.
    39	
    40	10. **Done means verified.** "Done" is `validate.sh` green, the relevant PDDA checks passing, and any relay review returning `Approved` — not work that looks finished. An unverified success claim is itself a low-quality signal.
    41	
    42	11. **Issue-first; every non-trivial change has a signal stream.** Any change beyond a 2–3 line fix opens a GitHub issue first, then gets a `GH-<number>` in-repo pointer doc, then lands. The issue is the machine-queryable signal stream; the `PROJECT/**` doc is the execution surface of record. Genuinely trivial edits (≤2–3 line fixes, typos, path repoints, doc-only one-liners) are exempt.
    43	
    44	12. **Independent Verification (Separated Grading)** — The agent that produces a turn must not be the sole grader of its own quality. Verification must be performed by an independent deterministic check or a separate reviewing agent before the lock releases. Applies to: the relay's structural block validator (`bin/validate-relay-block` — Phase 1 of GH-21), consult-verify diversity (Phase 3), and any other post-generation quality gate.
    45	
    46	## Applying this
    47	
    48	Adding a feature or weighing a tradeoff, ask: *does this keep agents coordinated without collision, contained within their scope, and verifiable to an outside observer? And is "done" provable by running `validate.sh`?* If any answer is no, reconsider.
    49	
    50	---
    51	
    52	## Conventions
    53	
    54	### Strict-mode policy (bash `set -e`)
    55	
    56	Strict mode is **per-subsystem, not repo-wide** (GH-110 P3b). The split is deliberate:
    57	
    58	- **`relay-automation/` drivers and turn shims run `set -euo pipefail`.** They orchestrate risky,
    59	  multi-step, containment-sensitive turns where a silently-ignored failure can commit off-lane or
    60	  orphan a peer. Abort-on-error (`-e`) is the correct default there.
    61	- **`utils/` analysis tools (`pdda/*`, `marathon-plan.sh`, `swarm-preflight.sh`) run `set -uo pipefail`
    62	  or `set -u`, deliberately *without* `-e`.** These are long single-pass scripts whose normal control
    63	  flow includes many expected-nonzero probes (`git rev-parse`, `gh` lookups, `grep` misses). Under
    64	  `-e` a benign "no match" would abort the whole run, so they set `-u` (catch unset vars) + explicit
    65	  per-call error handling instead. This is an exemption, not an oversight.
    66	
    67	Every currently `-e`-exempt script carries a one-line `# strict-mode: -e exempt — …` header next to
    68	its `set -` line so the exemption is self-documenting. New scripts default to `set -euo pipefail`
    69	unless they fit the analysis-tool profile above, in which case they add the exemption header.
    70	
    71	### Marathon builder default & plan location (GH-212)
    72	
    73	Two vendored-harness defaults, made explicit so an agent given only the vendored bundle picks the
    74	right behavior without pattern-matching a downstream repo's prior drift:
    75	
    76	- **Builder default is `codex`, not a billed CLI.** `marathon.sh`/`marathon-drive.sh` (and the
    77	  `XYZ_PYTHON=1` port) default `--builder` to `codex` — build turns bill via the Codex/ChatGPT
    78	  subscription, not the Anthropic API (agy is the other cost-blind option). `--builder claude`
    79	  spawns a headless Claude Code CLI subprocess instead: a separate, per-call API-billed turn-taker.
    80	  Use it only as an explicit, cost-acknowledged choice — never assume it's free because an
    81	  interactive session is already running. `swarm-preflight.sh`'s suggested invocation and
    82	  `marathon.sh`'s own default now agree; don't let them drift apart again.
    83	- **A marathon's plan lives under `PROJECT/2-WORKING/`.** The `MARATHON.yaml` + its phase briefs
    84	  belong under `PROJECT/2-WORKING/<capture-doc>/` — never a standalone top-level folder (e.g.
    85	  `marathon-plans/<slug>/`). `marathon.sh --plan` enforces this: it refuses (exit 2) a plan that
    86	  resolves outside `PROJECT/2-WORKING/`, exempting only paths under the harness's own home
    87	  (`MARATHON_HOME` — shipped reference examples like `MARATHON.example.yaml`) or an explicit
    88	  `MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1` override for a genuinely non-default location.
    89	
    90	---
    91	
    92	## Appendix: AI Doc Review Heuristics
    93	
    94	When reviewing any repo doc (roadmap entries, plans, architecture notes, audits, task writeups), apply these. Priority: containment > coordination correctness > signal quality > implementation speed and operator friction.
    95	
    96	**Heuristics**
    97	
    98	1. **Containment preserved?** Any headless path that could self-commit, touch off-allowlist files, or orphan a peer commit without an explicit containment argument → reject or escalate.
    99	2. **Skill-first respected?** Any plan that bypasses `relay-xyz` or improvises the harness from scratch without the skill layer → reject. Add to the skill instead.
   100	3. **Coordination through the event log?** Reads/writes to shared state route through `tick` verbs; hard-coded state outside `.tick/` needs explicit justification.
   101	4. **Done verifiable?** Names runnable gates (`validate.sh`, specific tests, `utils/pdda/pdda.sh run`). None = low-quality signal.
   102	5. **Drift reduced, not created?** No duplicated docs, no execution detail in ROADMAP.md, no reinventing a path the event-log contract already documents.
   103	6. **Next action singular?** One explicit next step, not buried in prose; status cells non-empty.
   104	7. **Operator control explicit?** No silent retry, no auto-repair outside the bounded exit-code menu, no masked failure; destructive ops surface before executing.
   105	8. **Four pillars pass?** Each turn/output is Attested, Relevant, Fresh, Structured. Fail one → not done.
   106	
   107	**Tie-breakers**
   108	
   109	- **Containment vs speed:** choose containment; flag friction as a design question, not a shortcut.
   110	- **New relay path vs reuse:** extend the existing skill and harness over forking a parallel path; if the harness can't accommodate it, surface the gap.
   111	- **Ambitious vs resumable:** a shorter plan an agent can resume cold beats a comprehensive one that buries state in prose.
   112	
   113	**Reject or escalate when**
   114	
   115	- A headless path has no allowlist, no worktree isolation, and no commit-bypass guard — and the doc doesn't justify why.
   116	- "Done" has no runnable verification step.
   117	- Adding a new relay lane requires editing the event-log kernel or the `tick` verb schema without a decision record under `decisions/`.
   118	- Hardcoded absolute paths, silent destructive operations, or opaque epoch-fence assumptions.
   119	- ROADMAP.md would need execution detail to make the plan legible.

codex
**ANSWER**

Ship the **2-category v0 first**.

The real gap in the shipped A4 slice is narrow: today `consult.sh` builds `FULL_PROMPT` in memory only, then stamps answered advisors if `rtl_has_uncited_claim()` finds a claim-bearing line without a nearby quote or `file:line` citation; it cannot distinguish a citation the advisor independently found from one merely echoed from the operator prompt (`relay-automation/consult.sh:117`, `relay-automation/consult.sh:123`, `relay-automation/consult.sh:310`, `relay-automation/consult.sh:325`; `relay-automation/relay-turn-lib.sh:675-744`). Under Principle 7 and the reuse tie-breaker, the first cut should close exactly that blind spot and stop (`GUIDING-PRINCIPLES.md:34-35`, `GUIDING-PRINCIPLES.md:109-111`). The proposal itself points the same way in its “honest weakest point” section (`PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md:253-261`).

**FINDINGS**

- [Blocker] **Do not ship the 4-category taxonomy as the first pass.** The shipped mechanism already covers the uncited side mechanically; the missing capability is specifically “cited, but only because the prompt handed it the citation” (`PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md:62-71`, `:77-82`). A 4-category first pass bundles that narrow fix with two extra surfaces: uncited-claim-to-prompt matching and a reconciliation-layer backstop (`PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md:147-200`). That is more than “least code that clears the bar.”

- [Should] **v0 delivers most of A4’s value on its own.** Today, both future `INFERENCE` and `UNSUPPORTED-ASSERTED` cases already land in the same existing warning bucket: no nearby citation means stamp `NO FIRSTHAND VERIFICATION CITED` (`relay-automation/consult.sh:325-333`; `PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md:91-93`, `:125-127`). The novel risk not covered today is the “clean-looking but prompt-echoed citation” case. So `ECHOED` vs `FIRSTHAND` is the load-bearing addition; the uncited split is diagnostic refinement, not first-order protection.

- [Should] **The highest-risk failure mode of v0 is false `FIRSTHAND` from format drift.** The current citation detector is intentionally simple: quoted spans or `name:NNN` (`relay-automation/relay-turn-lib.sh:676`). If the prompt says “consult.sh lines 117-126” and the advisor answers with `relay-automation/consult.sh:117`, or converts a quoted span into a `file:line`, an exact or whitespace-normalized substring test can miss the echo and over-credit it as firsthand (`PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md:89-90`, `:109-123`). That is the main weakness to design around.

- [Should] **The 4-category version adds materially more risk than v0.** `ECHOED`/`FIRSTHAND` only needs prompt persistence plus citation-string comparison on already-cited claims. `INFERENCE`/`UNSUPPORTED-ASSERTED` requires comparing uncited natural-language claim text against prompt text, which is a fuzzier and noisier classifier. The proposed reconciliation backstop is another separate contract change because the current consult synthesis is still prose-structured, not claim-ID-structured (`skills/consult/SKILL.md:101-118`; `PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md:166-184`).

- [Nit] **Call v0 what it is.** Don’t market it as the “full provenance taxonomy.” Make it an additive “prompt-trace classifier for cited claims.” That keeps it durable: later 4-category work extends it instead of rewriting an over-claimed v1 (`PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md:253-261`).

- [Pass] **The existing seam is good for a small additive cut.** `consult.sh` already reuses shared claim/citation machinery from `relay-turn-lib.sh`, and tests already cover uncited, fully cited, and partially cited answers (`relay-automation/consult.sh:310-336`; `relay-automation/relay-turn-lib.sh:713-744`; `test/consult.sh:191-249`). v0 can ride that seam cleanly.

**RECOMMENDATION**

Ship a **2-category cited-claim provenance v0** now: persist `PROMPT_TEXT`, classify already-cited claims as `FIRSTHAND` or `ECHOED`, leave the current uncited stamp unchanged, and defer the uncited split plus reconciliation backstop to a later issue once the prompt-trace matcher has real transcript data.
tokens used
57,642
**ANSWER**

Ship the **2-category v0 first**.

The real gap in the shipped A4 slice is narrow: today `consult.sh` builds `FULL_PROMPT` in memory only, then stamps answered advisors if `rtl_has_uncited_claim()` finds a claim-bearing line without a nearby quote or `file:line` citation; it cannot distinguish a citation the advisor independently found from one merely echoed from the operator prompt (`relay-automation/consult.sh:117`, `relay-automation/consult.sh:123`, `relay-automation/consult.sh:310`, `relay-automation/consult.sh:325`; `relay-automation/relay-turn-lib.sh:675-744`). Under Principle 7 and the reuse tie-breaker, the first cut should close exactly that blind spot and stop (`GUIDING-PRINCIPLES.md:34-35`, `GUIDING-PRINCIPLES.md:109-111`). The proposal itself points the same way in its “honest weakest point” section (`PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md:253-261`).

**FINDINGS**

- [Blocker] **Do not ship the 4-category taxonomy as the first pass.** The shipped mechanism already covers the uncited side mechanically; the missing capability is specifically “cited, but only because the prompt handed it the citation” (`PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md:62-71`, `:77-82`). A 4-category first pass bundles that narrow fix with two extra surfaces: uncited-claim-to-prompt matching and a reconciliation-layer backstop (`PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md:147-200`). That is more than “least code that clears the bar.”

- [Should] **v0 delivers most of A4’s value on its own.** Today, both future `INFERENCE` and `UNSUPPORTED-ASSERTED` cases already land in the same existing warning bucket: no nearby citation means stamp `NO FIRSTHAND VERIFICATION CITED` (`relay-automation/consult.sh:325-333`; `PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md:91-93`, `:125-127`). The novel risk not covered today is the “clean-looking but prompt-echoed citation” case. So `ECHOED` vs `FIRSTHAND` is the load-bearing addition; the uncited split is diagnostic refinement, not first-order protection.

- [Should] **The highest-risk failure mode of v0 is false `FIRSTHAND` from format drift.** The current citation detector is intentionally simple: quoted spans or `name:NNN` (`relay-automation/relay-turn-lib.sh:676`). If the prompt says “consult.sh lines 117-126” and the advisor answers with `relay-automation/consult.sh:117`, or converts a quoted span into a `file:line`, an exact or whitespace-normalized substring test can miss the echo and over-credit it as firsthand (`PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md:89-90`, `:109-123`). That is the main weakness to design around.

- [Should] **The 4-category version adds materially more risk than v0.** `ECHOED`/`FIRSTHAND` only needs prompt persistence plus citation-string comparison on already-cited claims. `INFERENCE`/`UNSUPPORTED-ASSERTED` requires comparing uncited natural-language claim text against prompt text, which is a fuzzier and noisier classifier. The proposed reconciliation backstop is another separate contract change because the current consult synthesis is still prose-structured, not claim-ID-structured (`skills/consult/SKILL.md:101-118`; `PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md:166-184`).

- [Nit] **Call v0 what it is.** Don’t market it as the “full provenance taxonomy.” Make it an additive “prompt-trace classifier for cited claims.” That keeps it durable: later 4-category work extends it instead of rewriting an over-claimed v1 (`PROJECT/1-INBOX/GH-178-A4-PROVENANCE-TAXONOMY-PROPOSAL.md:253-261`).

- [Pass] **The existing seam is good for a small additive cut.** `consult.sh` already reuses shared claim/citation machinery from `relay-turn-lib.sh`, and tests already cover uncited, fully cited, and partially cited answers (`relay-automation/consult.sh:310-336`; `relay-automation/relay-turn-lib.sh:713-744`; `test/consult.sh:191-249`). v0 can ride that seam cleanly.

**RECOMMENDATION**

Ship a **2-category cited-claim provenance v0** now: persist `PROMPT_TEXT`, classify already-cited claims as `FIRSTHAND` or `ECHOED`, leave the current uncited stamp unchanged, and defer the uncited split plus reconciliation backstop to a later issue once the prompt-trace matcher has real transcript data.
