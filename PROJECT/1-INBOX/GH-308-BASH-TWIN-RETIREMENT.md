---
title: Stop maintaining the Bash twins — make Python the single authoritative lane
status: Proposed (1-INBOX — not yet active)
created: 2026-07-26
owner: noel
gh_issue: 308
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/308
doc_type: project
complexity: 3
risk: 2
effort: 2
phases: 4
ratings_provisional: true
non_goals:
  - Not deleting the Bash twins in this project — they are frozen in place, not removed
  - Not a big-bang cutover, sweep, or migration; there is no deadline by which Bash must be gone
  - Not deleting relay-turn-lib.sh — it is a shared runtime dependency of the Python lane, not a twin
  - Not porting the 21 Bash-only scripts (explicitly unscheduled; see Phase 3)
  - Not pursuing consistency for its own sake — a mixed Bash + Python tree is an accepted end state
  - Not changing the XYZ_PYTHON default (already flipped to Python in GH-264, af7bb4d)
  - Not touching marathon-plan, which is carved out with Bash still authoritative (see Key concepts)
related:
  - "#278 — aider-turn timeout drift (py 300s / sh 600s / docs 900s) — OPEN, live parity drift"
  - "#296 — codex-turn.py never received the #263 fix that landed in Bash"
  - "#215 — consult.py missing Bash degraded-panel behavior"
  - "#223 — consult.py missing GH-178 A4 citation stamping"
  - "#174 — agy-turn.py never got the claim-before-launch fix"
  - "#148 — swarm_preflight.py inferred-path check lacked GH-137 sanitization"
  - "#261 — marathon-drive Bash/Python disjoint-failure union"
  - "#255 — Python cutover parity ledger (first full XYZ_PYTHON=1 validate.sh)"
  - "#112 — original Python port of the relay-automation harness"
goal: >
  Stop paying the double-maintenance tax immediately, without a migration project. Declare
  Python the single authoritative lane for the 11 entry points that have a real Python twin,
  freeze those Bash twins in place (banner + guard, not deletion), and collapse the dual-lane
  test matrix. Deletion is optional and opportunistic. A mixed Bash + Python tree is fine.
---

# GH-308 — Stop maintaining the Bash twins

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Key concepts

- **"Stop maintaining" is not "delete."** The entire recurring cost is the *pair-commit*: every fix
  written twice. That cost stops the moment one lane becomes authoritative — which requires no
  deletion, no migration, and is trivially reversible. Deletion is cosmetic and is deferred
  indefinitely.
- **A mixed tree is the accepted end state.** Frozen Bash files sitting next to live Python files
  are not a problem to be solved. This project buys working software and a lower tax, not elegance.
- **Three tiers, not two.** Of ~34 shell entry points, only **12** have a Python twin. The rest are
  Bash-only and were never duplication.
  - **Tier A — 11 true twins, in scope:** `agy-turn`, `aider-turn`, `claude-turn`, `codex-turn`,
    `pi-turn`, `poll`, `relay-loop`, `relay-drive`, `consult`, `marathon-drive`, `swarm-preflight`.
    Line counts track closely, all are dual-lane tested, Python already runs by default.
  - **Tier B — `marathon-plan`, carved OUT.** `utils/marathon-plan.sh` (1141 ln) vs
    `utils/py/marathon_plan.py` (406 ln) is not a port: Python delegates to a vendored
    `_marathon_plan_node.js` and its own header documents behavior it patches post-render (an older
    `docOf` that mis-picks a distractor doc; an omitted GH-86 section). Declaring Python
    authoritative here would promote known-worse behavior. **Bash stays authoritative for this pair
    and it keeps its current dual-maintained status** until someone chooses to close those gaps.
    That is the pragmatic answer, not the tidy one.
  - **Tier C — `relay-turn-lib.sh` is not a twin.** 1187 lines, 24 functions, all the containment
    safety logic (`rtl_enforce`, `rtl_check`, `rtl_worktree_begin/end`, allowlist). The **Python
    lane calls it at runtime** via `subprocess` (`marathon_drive.py:445`, `swarm_preflight.py:799`,
    `rtl.py:204`). Untouched here, and it will still be Bash when this project closes.
- **Stable = a frozen tag, not a maintained branch.** A maintained `stable` branch would relocate
  the double-maintenance tax rather than remove it, and would hide drift from any single checkout.
  Since nothing is being deleted, the tag is cheap insurance rather than a lifeline.
- **The guard is what makes it real.** A policy nobody enforces decays. A pre-commit/CI check that
  fails on edits to a frozen twin is what actually stops the pair-commit.

## Idea

> Phase out the Bash twins of Python-ported scripts: keep a "stable" version that has the Bash
> scripts, and on a branch cut from `development` start to stop maintaining the Bash scripts that
> have a Python twin. Practical, pragmatic, phased. We do not need to delete and phase out all Bash
> scripts immediately — get ROI from what we already have. A mish-mash of Bash + Python is fine as
> long as it works. Eventually replace the Bash-only scripts with Python where possible.

## Why

**Dual-lane maintenance is not just a cost — it is a recurring correctness bug class.**

Every substantive change currently lands twice. Measured over the last 90 days the churn is exactly
paired: `aider-turn` 4 Bash commits / 4 Python commits, `marathon_drive` 3 / 3. At the time of
capture the working tree has *both* `relay-automation/aider-turn.sh` and `utils/py/aider-turn.py`
modified.

The failure mode is that the lanes silently diverge, and because Python is the **default runtime**
since GH-264, a fix that lands only in Bash is a fix that does not run:

- **#296** — the canonical case: *"#263's fix genuinely landed in the Bash `codex-turn.sh` … but
  `utils/py/codex-turn.py` (the file that actually executes by default now) never received the
  #263/GH-36 fix at all."*
- **#215**, **#223** — `consult.py` missing Bash behaviors (degraded-panel, citation stamping).
- **#174** — `agy-turn.py` never got the claim-before-launch fix.
- **#148** — `swarm_preflight.py` lacked the GH-137 path sanitization Bash had.
- **#278** — **still open**: `aider-turn` per-turn timeout drift, py 300s / sh 600s / docs 900s.
  Three sources of truth, none agreeing. Its in-flight fix (`7d1a341`, landed while this capture was
  being written) is itself a live instance of the tax: the same 15 lines written twice, into
  `relay-automation/aider-turn.sh` **and** `utils/py/aider-turn.py`.

Naming one authoritative lane makes this class of bug impossible to reintroduce, and it does so in
about a day of work with no deletion risk. The dual-lane test matrix (~72 `XYZ_PYTHON=0/1`
invocations across 8 suites, 35 in `marathon-drive` alone) is the second recurring cost and is
retired by the same decision.

`TODO(operator)`: confirm no consumer outside the 6 vendored `.xyz/` copies pins `XYZ_PYTHON=0`.
Phase 1 assumes not — and because nothing is deleted, a wrong assumption degrades to "runs older
frozen code," not "breaks."

## Phase 0 — Explore & scope

> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

> **Re-scope note — 2026-07-26, recorded at capture time.** Phase 1 originally proposed closing
> **#278** as the first fix delivered under the new policy, and therefore as proof the policy works.
> That is no longer available: while this capture was being written, a marathon lane on
> `marathon/vendored-lane-hardening-2026-07-26` landed `7d1a341` for #278 **the old way** — the same
> 15 lines applied to both `relay-automation/aider-turn.sh` and `utils/py/aider-turn.py`. The issue
> is still open, but its fix is now dual-lane, so "close #278" would prove nothing about single-lane
> maintenance. Phase 1's #278 item is re-scoped accordingly (see below), and Phase 0 must pick a
> different first fix to serve as the policy's proof.

### Checklist
- [ ] Confirm the Tier A/B/C split against the tree at HEAD; correct the 12-pair list if it drifted
- [ ] Confirm the `marathon-plan` carve-out is still warranted (re-read the parity-shim header)
- [ ] Grep the fleet + operator dotfiles for any `XYZ_PYTHON=0` pin and note the blast radius
- [ ] Pick the enforcement mechanism for Phase 1's guard (pre-commit hook vs CI check vs both)
- [ ] **Re-scope #278 per the note above** — confirm the Python half of `7d1a341` is correct and
      authoritative, then decide whether the Bash half is reverted or simply frozen in place
- [ ] **Choose a different first fix** to deliver single-lane as the policy's proof, now that #278
      cannot serve that role
- [ ] Check whether any other in-flight lane is mid-way through a dual-lane fix that would collide
      with the Phase 1 freeze, and sequence around it
- [ ] Name the concrete write-set per phase (needed before this can be a marathon lane)
- [ ] Set/correct the triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [ ] The scope is grounded in real code/history, not a hypothetical
- [ ] Composes with existing commands rather than adding a parallel path
- [ ] A human checkpoint remains before anything fires

## Phase 1 — Declare Python authoritative and freeze the twins

**This phase is the entire ROI.** Nothing is deleted; the pair-commit tax stops here.

### Checklist
- [ ] Cut an annotated tag on `development` at the last fully dual-maintained commit
      (e.g. `bash-final-2026-07-26`) and push it — cheap insurance, frozen, never merged into
- [ ] Cut the working branch from `development` (not `main`)
- [ ] Add a short **FROZEN** banner to the top of each of the 11 Tier-A Bash twins: Python is
      authoritative, do not edit, pointer to this issue and to the Python file
- [ ] Add the enforcement guard: fail (or loudly warn) when a commit touches a frozen twin
- [ ] **#278 — re-scoped (see the Phase 0 note).** Its fix landed dual-lane in `7d1a341` before this
      project starts, so closing it no longer proves the policy. Instead: verify the Python half is
      authoritative and correct, freeze or revert the Bash half, and reconcile the 900s doc value
- [ ] Deliver the Phase 0-chosen first fix **single-lane** as the policy's actual proof
- [ ] Record the policy in `AGENTS.md` + `UPGRADE.md`: fixes land in Python only; the Bash twins are
      historical reference; `marathon-plan` is the documented exception
- [ ] Leave `marathon-plan` and all Bash-only scripts untouched

### QA checklist — Phase 1
- [ ] Editing a frozen twin is actually blocked/flagged — demonstrated with a throwaway commit
- [ ] At least one real fix has shipped **single-lane** under the new policy — the proof is a
      delivered change, not the policy text
- [ ] #278's Python half is verified authoritative; its Bash half is frozen or reverted, not left
      as a second maintained copy
- [ ] The `marathon-plan` exception is written down where a future maintainer will hit it
- [ ] Nothing was deleted; `git status` shows only banners, docs, the guard, and the #278 fix
- [ ] Rollback is a one-line banner removal — confirm no step is hard to undo

## Phase 2 — Collapse the dual-lane test matrix

The second recurring cost. Safe to do once Phase 1's policy holds, and it speeds up every future run.

### Checklist
- [ ] Drop the `XYZ_PYTHON=0` arm from the 8 dual-lane suites; keep the Python arm as the suite
- [ ] Keep the Bash arm **runnable on demand** (an opt-in env flag), just not part of the default run
- [ ] Preserve `marathon-plan`'s dual-lane coverage — it is still dual-maintained
- [ ] Record the before/after suite wall-clock in this doc as the measured win

### QA checklist — Phase 2
- [ ] The suite is green on a clean clone with the collapsed matrix
- [ ] The retained on-demand Bash arm still passes when explicitly invoked
- [ ] `marathon-plan` coverage was not collapsed by accident
- [ ] The measured time saving is recorded, not estimated

## Phase 3 — Opportunistic cleanup (unscheduled, no sweep)

Deliberately open-ended. There is **no deadline and no sweep**; this phase may stay open indefinitely
or be closed unfinished without loss. Its only purpose is to say what is allowed when someone is
already in the area.

### Checklist
- [ ] Delete a frozen Bash twin only when already working in that file's area **and** its Python
      counterpart has been exercised in anger — never as a batch
- [ ] Re-vendor the 6 `.xyz/` copies on the normal cadence, not as a special event (they are already
      at differing drift levels: `aider-turn.py` is 11.4K at root, 10.5K in `rebalance-OS`, 7.0K in
      `cactus`) — coordinate with open **#304**
- [ ] Port a Bash-only script to Python only where churn justifies it; Bash stays where Bash is the
      right tool (thin git/launchd/`xyz-sync` wrappers)
- [ ] **`relay-turn-lib.sh` requires its own issue and is out of scope here** — 1187 lines of
      containment-safety logic that the Python lane shells into; porting it moves the safety boundary
- [ ] If `marathon-plan`'s node-engine gaps are ever closed, fold that pair into the Phase 1 policy

### QA checklist — Phase 3
- [ ] No bulk deletion happened — each removal was incidental to other work
- [ ] Nothing here blocked a release or became a maintenance obligation of its own
- [ ] `relay-turn-lib.sh` is untouched unless its own issue is open and approved
- [ ] Leaving this phase permanently open is explicitly acceptable and recorded as such
