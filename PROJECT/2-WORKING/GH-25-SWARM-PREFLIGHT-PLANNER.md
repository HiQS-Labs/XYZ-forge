---
title: Swarm preflight planner — one durable intake script for project docs or GH issue bundles
status: Active — Phase 1 ready
created: 2026-06-25
updated: 2026-06-25
owner: Noel (operator) · Codex (author)
branch: main
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
| **Phase 0 completed** — duplicate check run against `PROJECT/2-WORKING/`; no competing active doc found for this planner, and [#25](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/25) is now the signal stream for the work. | **Phase 1 — lock the single-script contract**: choose the one entrypoint, the normalized input/output shape, and the minimum machine-readable preflight contract before any implementation starts. |

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

- [ ] Create exactly one operator entrypoint: `utils/swarm-preflight.sh`.
- [ ] Keep the CLI surface narrow: one script with subcommands or modes, not multiple sibling utilities with overlapping responsibilities.
- [ ] Lock the supported input modes:
  - [ ] `--project-doc <PROJECT/2-WORKING/...md>`
  - [ ] `--gh-issue <N>` repeatable for an explicit issue bundle
  - [ ] `--target-root <repo>` for the repo the marathon would act on
- [ ] Make input modes explicit and mutually legible: the planner may accept either one project doc or an explicit GH bundle, but it must normalize both into the same intermediate shape.
- [ ] Define the minimum machine-readable contract the script will require from source material:
  - [ ] target repo / target branch or ref
  - [ ] validation gate command
  - [ ] known "fix still absent" probes
  - [ ] candidate artifact paths / lane scope hints
  - [ ] remediation-plan source (doc section, brief, or issue acceptance criteria)
- [ ] Fail loud when the contract is missing instead of guessing from arbitrary prose.

### QA checklist

- [ ] One sample project doc and one sample GH-issue bundle both normalize into the same JSON shape.
- [ ] The contract is small enough to fill without creating a second planning framework.
- [ ] The CLI help text makes it obvious which fields are deterministic requirements vs optional hints.

## Phase 2 — Normalize Inputs into One Run Shape

- [ ] Implement source resolution for `--project-doc`:
  - [ ] verify the doc exists
  - [ ] verify it is active or intentionally selected
  - [ ] extract the machine-readable preflight block
- [ ] Implement source resolution for `--gh-issue` bundles:
  - [ ] resolve each issue from GitHub
  - [ ] locate its in-repo `GH-*` capture or active-work doc
  - [ ] fail loud if an issue has no local capture, instead of inventing context from the thread (`GUIDING-PRINCIPLES.md` §11: issue = signal stream, `GH-*` capture = execution surface of record; §2: one canonical source, no thread/doc drift)
- [ ] Define the intermediate "run candidate" object the rest of the planner consumes.
- [ ] Record provenance in the normalized object: source doc(s), issue URL(s), commit/branch snapshot, and target repo root.
- [ ] Keep ROADMAP pointer-only; do not move execution detail back into `ROADMAP.md`.

### QA checklist

- [ ] A project-doc run and an issue-bundle run produce structurally identical normalized output.
- [ ] Missing local GH capture docs fail with a precise remediation message.
- [ ] The normalized object is sufficient for later phases without re-reading raw source text.

## Phase 3 — Freshness + Fix-Still-Required Checks

- [ ] Add deterministic branch-state checks:
  - [ ] current branch name
  - [ ] upstream branch/ref
  - [ ] `git fetch --prune` result
  - [ ] ahead/behind / detached / missing-upstream status
  - [ ] clean-vs-dirty working tree
- [ ] Add repo-presence checks for the target root: must exist, must be a git repo, must resolve to one top-level root.
- [ ] Implement "fix still required" probes from the contract:
  - [ ] grep/symbol absence checks
  - [ ] path existence checks
  - [ ] optional command probes
- [ ] Mark candidates as:
  - [ ] `ready`
  - [ ] `stale/already-landed`
  - [ ] `ambiguous`
  - [ ] `blocked/missing-target`
- [ ] Fail loud on ambiguous or already-landed targets; do not feed stale work into marathon.

### QA checklist

- [ ] A known already-fixed substrate is rejected deterministically.
- [ ] An out-of-date local branch is surfaced with exact ahead/behind state.
- [ ] Offline or fetch-failed cases are visible as a blocked preflight state, not silently ignored.

## Phase 4 — Remediation Readiness Gate

- [ ] Require a real remediation surface before a run can graduate:
  - [ ] project-doc phase/checklist exists, or
  - [ ] issue bundle includes actionable acceptance criteria plus a bound implementation seam
- [ ] Detect when a source lacks enough researched detail to run unattended.
- [ ] Require a runnable gate command before a run can be marked preflight-ready.
- [ ] Require a bounded artifact scope / `ALLOW_PATHS` candidate set.
- [ ] Emit one explicit next action when readiness fails:
  - [ ] research more
  - [ ] split the bundle
  - [ ] add fix probes
  - [ ] add gate command

### QA checklist

- [ ] A vague issue thread without a researched seam is rejected as not marathon-ready.
- [ ] A doc with a real phase plan, gate command, and artifact bounds passes this phase.
- [ ] Every failure path names one concrete remediation, not a generic "needs more planning".

## Phase 5 — Codebase Analysis + Lane Assignment

- [ ] Analyze the target repo for candidate lane seams from the bounded artifact set.
- [ ] Emit a deterministic lane plan with:
  - [ ] orchestrator-owned work
  - [ ] Codex lane
  - [ ] agy lane
  - [ ] sequential dependencies / coupled-lane warnings
- [ ] Encode the current lane policy honestly:
  - [ ] Codex is the default trusted code-writing reviewer/builder lane
  - [ ] agy is reviewer-first and builder-gated until GH-22 and the agy reliability matrix close
  - [ ] trust-critical kernel changes stay out of agy by default
- [ ] Detect non-splittable work and return "single-lane only" instead of forcing a fake parallel split.
- [ ] Detect overlapping or coupled paths and warn/fail before the marathon starts.

### QA checklist

- [ ] The lane output is machine-readable and names exact path scopes.
- [ ] A clearly coupled change is flagged before assignment.
- [ ] An agy-unsafe target is down-scoped to Codex/orchestrator instead of being assigned optimistically.

## Phase 6 — Emit the Marathon Run Packet

- [ ] Emit one run packet directory per preflight under a stable location (for example `relay-system/preflight/<date>/<slug>/`).
- [ ] Include:
  - [ ] normalized source JSON
  - [ ] freshness report
  - [ ] readiness verdict
  - [ ] lane plan JSON
  - [ ] generated marathon brief / packet summary
  - [ ] exact `marathon-drive.sh` invocation hints (`--target-root`, `--artifact`, `--pre-advance-cmd`, `--require-clean`)
- [ ] Support a dry-run mode that stops after packet generation.
- [ ] Keep the planner as the producer of the packet, not the executor of the marathon itself.

### QA checklist

- [ ] A successful preflight produces one self-contained packet directory.
- [ ] The packet is enough for the orchestrator to launch the run without re-deriving context.
- [ ] Dry-run does not mutate the target repo.

## Phase 7 — Regression Lock + Operator Docs

- [ ] Add tests for both input modes: one project doc, one GH-issue bundle.
- [ ] Add fixtures for each failure mode: stale branch, already-landed fix, missing gate, overlapping lanes, missing local GH capture.
- [ ] Add one README/operator section pointing the user at the planner without duplicating the full plan.
- [ ] Update the active doc, ROADMAP pointer, and CHANGELOG with the implementation result.
- [ ] Run `utils/pdda-run.sh` and the repo validation gates before claiming completion.

### QA checklist

- [ ] The suite covers at least one happy path and one failure path for each planner phase.
- [ ] Docs point to this planner as the canonical intake path instead of creating a second checklist.
- [ ] Final verification names the exact scripts/tests that passed, or states plainly if any were skipped.
