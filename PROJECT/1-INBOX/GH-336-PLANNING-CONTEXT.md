---
gh_issue: 336
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/336
title: "Planning context: phase metadata signals before deterministic marathon contracts"
status: "Proposed (1-INBOX — not yet active)"
created: 2026-07-29
doc_type: feedback
related: GH-334
effort: 3
complexity: 3
risk: 3
phases: 2
goal: >
  Improve marathon planning with evidence-backed release alignment, delivery-arc, issue-theme, and
  sub-module churn context, while preserving current execution safety and avoiding premature process
  overhead.
---

# GH-336 · planning context

## Why now

The existing planner safely sequences individually valid issues, but it does not yet connect a run
to `RELEASES.md`/its GitHub milestone, summarize recently shipped direction, cluster related survivor
issues, or show evidence that one sub-module is receiving repeated local repairs. That can maximize
ticket throughput while obscuring release alignment and a likely refactor boundary.

GH-334 is the related release-scope adoption issue. This proposal consumes the existing
`RELEASES.md` and `utils/release-lanes.sh seed|rollup` foundation; it does not create a second release
ledger or a separate issue-membership cache.

## Bet, tradeoff, and blast radius

**Bet:** an advisory, receipt-backed planning overlay will expose better grouping and refactor choices
before the harness needs new execution controls.

**Tradeoff:** Phase 1 accepts bounded inference and requires operators to review it; Phase 2 is
allowed only if repeated real-run evidence proves a small deterministic contract would prevent a
material planning mistake.

**Failure mode:** analysis silently changes scheduling or `/10days` auto-fire behavior. Phase 1 must
prove it cannot affect inclusion, scoring, waves, allowlists, preflight verdicts, or firing.

**Reversibility:** Costly but reversible. Phase 1 is a generated, advisory overlay that can be
disabled without changing execution semantics. Phase 2 remains opt-in and must retain that escape
hatch. A clean-room rewrite is a one-way-door decision and always requires an explicit operator GO.

## Table of contents

- [Phase 1 — advisory planning context](#phase-1--advisory-planning-context)
- [Phase 2 — minimal deterministic contracts](#phase-2--minimal-deterministic-contracts)
- [Non-goals](#non-goals)

## Phase 1 — advisory planning context

Add a small, versioned context section to generated marathon plans and `/10days` output. It is a
read-only synthesis of existing sources, with receipts and a declared time window:

- **Release alignment:** selected release/codename, milestone, target date, and an in-scope /
  out-of-scope / unresolved snapshot. Do not infer milestone membership.
- **Delivery arc:** recent merged PR and commit receipts plus a clearly labelled inference about what
  direction they represent.
- **Issue themes:** clusters among only the candidate issues that survived reconciliation, including
  membership and confidence.
- **Churn signals:** repeated paths/sub-modules, time window, recurrence count, linked issues/PRs/
  commits, and a bounded recommendation (`watch`, `investigate`, or `consider bounded refactor`).

Churn signals are evidence, not diagnoses. A possible larger refactor or rewrite is a human decision
prompt only; it must never create or fire a lane automatically.

### Acceptance criteria

- Every generated claim identifies its evidence and analysis window; synthesis is labelled as
  inference rather than fact.
- Release context is optional and explicitly says `unresolved` when no release or milestone was
  selected.
- Enabling or disabling the context produces the identical candidate set, ordering, waves, contracts,
  and fire list.
- No event-log verbs, new service, persistent cache, or blocking gate is introduced.
- Focused regression coverage plus `./validate.sh` and `utils/pdda/pdda.sh run` are green.

## Phase 2 — minimal deterministic contracts

**Start condition:** at least three real planning runs must show that Phase 1 caught a material
release-scope, duplicate-work, or churn decision that otherwise would have been missed, and an
operator explicitly promotes this phase. Do not start it merely because a richer schema is possible.

If earned, implement only the smallest stable contract demonstrated by those runs:

- optional release/milestone selection input and compact, versioned planning-context shape;
- GitHub-milestone verification for release-aware selection, while existing per-issue Swarm Preflight
  contracts remain the sole execution authority;
- deterministic malformed/missing-context findings only for an explicitly requested release-aware
  run—ordinary marathon planning and `/10days` remain valid without them;
- a dedicated architecture/refactor capture doc and explicit operator GO before a churn signal may
  become a large-refactor or clean-room-rewrite candidate.

### Acceptance criteria

- Contract validation is scoped to the opt-in feature and has no impact on ordinary planning runs.
- GitHub milestones remain the sole release-to-issue-set join key.
- Existing issue-level artifact allowlists, collision rules, and preflight gates continue to govern
  execution unchanged.
- A refactor/rewrite recommendation records alternatives, rollback/migration strategy, and the
  operator decision; it cannot be auto-fired.
- Focused regression coverage plus `./validate.sh` and `utils/pdda/pdda.sh run` are green.

## Non-goals

- No automatic selection, creation, or firing of refactor or rewrite work.
- No mandatory taxonomy for every issue.
- No duplicate release ledger, hand-maintained membership list, broad event-kernel change, or service.
- No Phase 2 implementation without the stated evidence and explicit operator promotion.
