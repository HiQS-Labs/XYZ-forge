---
ratings_exempt: true
title: Swarm preflight planner — one durable intake script for project docs or GH issue bundles
status: Active — Phases 1–6 implemented; agy review pending
created: 2026-06-25
updated: 2026-06-25
owner: Noel (operator) · Codex (author)
branch: gh-25-swarm-preflight
gh_issue: 25
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/25
doc_type: tooling
goal: >
  Build one durable preflight planner entrypoint that turns either a project doc or an explicit
  bundle of GitHub issues into a marathon-ready run packet: candidate/freshness checks, "fix still
  required" validation, remediation-plan readiness, and deterministic Codex vs agy lane assignment.
related:
  - ROADMAP.md
  - PROJECT/PDDA.md
  - PROJECT/2-WORKING/GH-16-CROSS-REPO-SWARM.md
  - PROJECT/2-WORKING/MARATHON-DOGFOOD-2026-06-24-SLEUTH-NEARMISS-2LITE.md
  - relay-automation/marathon-drive.sh
  - relay-automation/relay-drive.sh
non_goals:
  - Replacing `relay-drive.sh`, `marathon-drive.sh`, or `tick` with a second control plane
  - Auto-clustering arbitrary GitHub issues into a bundle without an explicit operator selection
  - Promoting agy to an unrestricted builder lane before GH-22 and the agy reliability matrix close
---

# Swarm preflight planner

> **In-repo capture of [issue #25](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/25), promoted to `PROJECT/2-WORKING/` on execution start.** The live issue is the discussion surface; this doc is the canonical active-work record, per `PROJECT/PDDA.md` → "GitHub issue intake".

## Status

| What was just completed | What's next |
|---|---|
| **Phases 1–6 implemented + Phase 7 regression lock** — `utils/swarm-preflight.sh` (one entrypoint, contract → normalize → freshness/fix-probes → readiness gate → Codex/agy lanes → packet) with `test/swarm-preflight.sh` (18 assertions) wired into `validate.sh`; full gate **47/47** green on branch `gh-25-swarm-preflight`. | **Agy relay review** of the final script via `relay-xyz`, then fold review outcome + merge. |

## Table of Contents

- [Why This Exists](#why-this-exists)
- [Bet / Blast Radius / Reversibility](#bet--blast-radius--reversibility)
- [Phase 0 — Intake + No-Duplicate Guard](#phase-0--intake--no-duplicate-guard)
- [Phase 1 — Contract the Single Entrypoint](#phase-1--contract-the-single-entrypoint)
- [Phase 2 — Normalize Inputs into One Run Shape](#phase-2--normalize-inputs-into-one-run-shape)
- [Phase 3 — Freshness + Fix-Still-Required Checks](#phase-3--freshness--fix-still-required-checks)
- [Phase 4 — Remediation Readiness Gate](#phase-4--remediation-readiness-gate)
- [Phase 5 — Codebase Analysis + Lane Assignment](#phase-5--codebase-analysis--lane-assignment)
- [Phase 6 — Emit the Marathon Run Packet](#phase-6--emit-the-marathon-run-packet)
- [Phase 7 — Regression Lock + Operator Docs](#phase-7--regression-lock--operator-docs)

## Why This Exists

The runtime now exists, but the intake is still manual. The Sleuth dogfood proved the missing layer is
not another harness loop; it is a repeatable front door that can answer, before a marathon fires:

1. What long-running candidate should we run?
2. Is the freshest target branch/repo state loaded?
3. Is the fix still required, or did a human already land it?
4. Is there already enough researched remediation detail to run unattended?
5. Which lane should go to Codex, which to agy, and which should stay orchestrator-only?

The durable answer is **one script entrypoint**, not a pile of operator rituals.

**Input modes, reconciled (`GUIDING-PRINCIPLES.md` §11 issue-first, §2 one-canonical-source).**
The GH-issue mode does not read raw issue threads. Per §11 the GitHub issue is the *signal
stream*; the `GH-<number>` / `PROJECT/**` capture doc is the *execution surface of record*. The
planner consumes capture docs in **both** modes — a project doc is one such surface, a GH bundle is
several — so both normalize to the same shape with no second planning framework. Requiring a local
capture is not a new ritual: issue-first → `GH-<number>` pointer doc → land is already mandatory for
every non-trivial change (§11), so the planner only refuses to let a run skip a step the harness
already requires. Reading the thread directly would split canonical context across thread and doc
(§2 drift) and risk feeding a stale thread into a marathon (the *Fresh* pillar of the quality bar).

## Bet / Blast Radius / Reversibility

**Bet:** the planner becomes durable only if we stop scraping free-form prose and require a small,
machine-readable preflight contract that both a project doc and an explicit GH-issue bundle can
normalize into the same run shape.

**Tradeoff:** this adds a little authoring discipline up front, but it removes repeated bespoke
preflight work and makes stale/already-fixed targets fail loud before a marathon burns time.

**Failure mode:** if the contract is too heavy, operators will bypass it and we will be back to
manual, one-off dogfood setup.

**Reversibility:** Easy. This is a new planner layer on top of the existing harness, not a `tick`
schema or relay-kernel mutation.

**Blast radius:** Small-to-medium. The planner touches docs, issue intake, and the handoff into
`marathon-drive.sh`, but it should reuse the current runtime instead of changing containment or event
semantics.

## Phase 0 — Intake + No-Duplicate Guard

- [x] Re-read the canonical workflow owners: `ROUTER.md`, `AGENTS.md`, `ROADMAP.md`, and `PROJECT/PDDA.md`.
- [x] Search `PROJECT/2-WORKING/` and `ROADMAP.md` for an existing active doc covering swarm preflight / lane planning.
- [x] Open a GitHub issue first so the work has a machine-queryable signal stream.
- [x] Promote the issue into one canonical `PROJECT/2-WORKING/GH-25-*.md` active-work doc instead of creating a parallel non-`GH-` plan.

### QA checklist

- [x] No competing `PROJECT/2-WORKING` doc was found for this same planner surface.
- [x] The active-work doc carries the issue number, source URL, and the full active-doc contract.
- [x] The work is tracked as issue-first, not as an orphan local plan.

## Phase 1 — Contract the Single Entrypoint

- [x] Create exactly one operator entrypoint: `utils/swarm-preflight.sh`.
- [x] Keep the CLI surface narrow: one script with subcommands or modes, not multiple sibling utilities with overlapping responsibilities.
- [x] Lock the supported input modes:
  - [x] `--project-doc <PROJECT/2-WORKING/...md>`
  - [x] `--gh-issue <N>` repeatable for an explicit issue bundle
  - [x] `--target-root <repo>` for the repo the marathon would act on
- [x] Make input modes explicit and mutually legible: the planner may accept either one project doc or an explicit GH bundle, but it must normalize both into the same intermediate shape.
- [x] Define the minimum machine-readable contract the script will require from source material:
  - [x] target repo / target branch or ref
  - [x] validation gate command
  - [x] known "fix still absent" probes
  - [x] candidate artifact paths / lane scope hints
  - [x] remediation-plan source (doc section, brief, or issue acceptance criteria)
- [x] Fail loud when the contract is missing instead of guessing from arbitrary prose.

### QA checklist

- [x] One sample project doc and one sample GH-issue bundle both normalize into the same JSON shape.
- [x] The contract is small enough to fill without creating a second planning framework.
- [x] The CLI help text makes it obvious which fields are deterministic requirements vs optional hints.

## Phase 2 — Normalize Inputs into One Run Shape

- [x] Implement source resolution for `--project-doc`:
  - [x] verify the doc exists
  - [x] verify it is active or intentionally selected
  - [x] extract the machine-readable preflight block
- [x] Implement source resolution for `--gh-issue` bundles:
  - [x] resolve each issue from GitHub
  - [x] locate its in-repo `GH-*` capture or active-work doc
  - [x] fail loud if an issue has no local capture, instead of inventing context from the thread (`GUIDING-PRINCIPLES.md` §11: issue = signal stream, `GH-*` capture = execution surface of record; §2: one canonical source, no thread/doc drift)
- [x] Define the intermediate "run candidate" object the rest of the planner consumes.
- [x] Record provenance in the normalized object: source doc(s), issue URL(s), commit/branch snapshot, and target repo root.
- [x] Keep ROADMAP pointer-only; do not move execution detail back into `ROADMAP.md`.

### QA checklist

- [x] A project-doc run and an issue-bundle run produce structurally identical normalized output.
- [x] Missing local GH capture docs fail with a precise remediation message.
- [x] The normalized object is sufficient for later phases without re-reading raw source text.

## Phase 3 — Freshness + Fix-Still-Required Checks

- [x] Add deterministic branch-state checks:
  - [x] current branch name
  - [x] upstream branch/ref
  - [x] `git fetch --prune` result
  - [x] ahead/behind / detached / missing-upstream status
  - [x] clean-vs-dirty working tree
- [x] Add repo-presence checks for the target root: must exist, must be a git repo, must resolve to one top-level root.
- [x] Implement "fix still required" probes from the contract:
  - [x] grep/symbol absence checks
  - [x] path existence checks
  - [x] optional command probes
- [x] Mark candidates as:
  - [x] `ready`
  - [x] `stale/already-landed`
  - [x] `ambiguous`
  - [x] `blocked/missing-target`
- [x] Fail loud on ambiguous or already-landed targets; do not feed stale work into marathon.

### QA checklist

- [x] A known already-fixed substrate is rejected deterministically.
- [x] An out-of-date local branch is surfaced with exact ahead/behind state.
- [x] Offline or fetch-failed cases are visible as a blocked preflight state, not silently ignored.

## Phase 4 — Remediation Readiness Gate

- [x] Require a real remediation surface before a run can graduate:
  - [x] project-doc phase/checklist exists, or
  - [x] issue bundle includes actionable acceptance criteria plus a bound implementation seam
- [x] Detect when a source lacks enough researched detail to run unattended.
- [x] Require a runnable gate command before a run can be marked preflight-ready.
- [x] Require a bounded artifact scope / `ALLOW_PATHS` candidate set.
- [x] Emit one explicit next action when readiness fails:
  - [x] research more
  - [x] split the bundle
  - [x] add fix probes
  - [x] add gate command

### QA checklist

- [x] A vague issue thread without a researched seam is rejected as not marathon-ready.
- [x] A doc with a real phase plan, gate command, and artifact bounds passes this phase.
- [x] Every failure path names one concrete remediation, not a generic "needs more planning".

## Phase 5 — Codebase Analysis + Lane Assignment

- [x] Analyze the target repo for candidate lane seams from the bounded artifact set.
- [x] Emit a deterministic lane plan with:
  - [x] orchestrator-owned work
  - [x] Codex lane
  - [x] agy lane
  - [x] sequential dependencies / coupled-lane warnings
- [x] Encode the current lane policy honestly:
  - [x] Codex is the default trusted code-writing reviewer/builder lane
  - [x] agy is reviewer-first and builder-gated until GH-22 and the agy reliability matrix close
  - [x] trust-critical kernel changes stay out of agy by default
- [x] Detect non-splittable work and return "single-lane only" instead of forcing a fake parallel split.
- [x] Detect overlapping or coupled paths and warn/fail before the marathon starts.

### QA checklist

- [x] The lane output is machine-readable and names exact path scopes.
- [x] A clearly coupled change is flagged before assignment.
- [x] An agy-unsafe target is down-scoped to Codex/orchestrator instead of being assigned optimistically.

## Phase 6 — Emit the Marathon Run Packet

- [x] Emit one run packet directory per preflight under a stable location (for example `relay-system/preflight/<date>/<slug>/`).
- [x] Include:
  - [x] normalized source JSON
  - [x] freshness report
  - [x] readiness verdict
  - [x] lane plan JSON
  - [x] generated marathon brief / packet summary
  - [x] exact `marathon-drive.sh` invocation hints (`--target-root`, `--artifact`, `--pre-advance-cmd`, `--require-clean`)
- [x] Support a dry-run mode that stops after packet generation.
- [x] Keep the planner as the producer of the packet, not the executor of the marathon itself.

### QA checklist

- [x] A successful preflight produces one self-contained packet directory.
- [x] The packet is enough for the orchestrator to launch the run without re-deriving context.
- [x] Dry-run does not mutate the target repo.

## Phase 7 — Regression Lock + Operator Docs

- [x] Add tests for both input modes: one project doc, one GH-issue bundle.
- [x] Add fixtures for each failure mode: stale branch, already-landed fix, missing gate, overlapping lanes, missing local GH capture.
- [x] Add one README/operator section pointing the user at the planner without duplicating the full plan.
- [x] Update the active doc, ROADMAP pointer, and CHANGELOG with the implementation result.
- [x] Run `utils/pdda-run.sh` and the repo validation gates before claiming completion.

### QA checklist

- [x] The suite covers at least one happy path and one failure path for each planner phase.
- [x] Docs point to this planner as the canonical intake path instead of creating a second checklist.
- [x] Final verification names the exact scripts/tests that passed, or states plainly if any were skipped.
