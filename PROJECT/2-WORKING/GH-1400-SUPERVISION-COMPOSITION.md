---
gh_issue: 1400
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1400
title: Economical flywheel composition
status: In progress
created: 2026-11-09
updated: 2026-11-09
owner: Codex
goal: Reduce downstream supervision by composing existing owners without new machinery.
doc_type: project
effort: 2
complexity: 2
risk: 2
phases: 2
---

# GH-1400 — Economical flywheel composition

## Status

| What was just completed | What's next |
|---|---|
| Independent plan QA Approved; owned-row accepted-start recorded; bounded flywheel instruction change drafted. | Manual instruction smoke and final Codex QA. |

## Quad Concepts

- Repeated landing nudges → one approved pinned batch owned by merge-cleanup.
- Idle polling → exact-result native continuation when supported.
- Accounting reconstruction → retain owner receipts and disclose the GH-1399 enforcement gap.
- Upstream ambiguity → preparation signal revalidated at actual pickup.

## Table of contents

- [Phase 1 — Recon and plan](#phase-1--recon-and-plan)
- [Phase 2 — Delivery and verification](#phase-2--delivery-and-verification)

## Phase 1 — Recon and plan

Observed problem: GH-1400 proposes reducing the supervision tax seen in GH-1386.
The existing runtime already pins batch selection, rejects stale heads, bounds repairs
and records landing outcomes. Flywheel currently links these owners but does not explain
how to hand off an entire approved batch or choose an event-driven continuation.

Recon: [map](recon-gh1400-supervision-composition.md). No graph tool is installed;
lanes A/B/C/D were read in this agent's context. Parent accepted this disjoint scope.

Outcome sought: fewer redundant supervisor turns while retaining actual approvals,
head identity, bounded recovery and honest remaining work.

Smallest viable bet: extend only `skills/2-daily/flywheel/SKILL.md` with a compact
composition contract and update its existing steps to use it. Reversibility: Easy;
revert the instruction patch. No persisted schema/runtime contract changes.

Alternative rejected: a new runner, scheduler or accounting guard duplicates existing
owners or takes GH-1399's scope. Existing links alone omit the concrete handoff,
wait identity and partial-result handling that this change supplies.

Blast: current radius is flywheel callers, merge-cleanup batch records, native wake
facilities and Jog pickup. Added radius is instruction-following sessions using the
new handoff. A mistaken claim of blanket merge approval or enforced accounting could
cause unauthorized landing or false confidence, so both are explicitly excluded.

### Requirements and boundaries

| Requirement | Delivery | Held dependency / limitation |
|---|---|---|
| Batch landing without stepwise nudges | One exact approved pinned allowlist; existing driver owns sequence/reconcile/outcomes | No merge is authorized by this task; changed heads need renewed eligibility/review. |
| Event-driven continuation | Prefer native PR watcher or delegate completion; bounded same-chat timers only where supported | No runtime-specific tools installed or scheduler armed. |
| Fail-closed accounting | Reuse existing durable owner records; expose missing accounting before work | GH-1399 remains OPEN; this change does not implement push/gate enforcement. |
| Upstream conveyor composition | Readiness is preparation signal; execution owner explicitly selects/revalidates | GH-1401 is independent; no new label consumer or automatic admission. |

### Rating rationale — 2026-11-09

PRS read-back: rated 75/60/50/80, no operator override. Priority reflects requested
factory throughput work; severity reflects repeated supervision cost rather than
proven data loss. Appeal stays neutral 50. Cheapness 80 reflects an instruction-only
change on existing owners, not the cost of the entire arc.
Recurrence windows: 2026-10-27..2026-11-09 versus 2026-10-13..2026-10-26.
GitHub title/body `flywheel` search returned 20 versus 1 updated issues; these are
search hits, NOT independent incidents or a velocity claim. Concrete recent examples
GH-1386 and GH-1399 report manual progression/accounting reconstruction; older coverage
is incomplete, so trend is unknown. Prior-art exact-seam search found only GH-1400,
no merged fix candidate; existing GH-1376 source supplies the base to extend.

### Ordered implementation and acceptance

1. Commit plan/map and obtain Codex plan QA → require Approved before implementation.
2. Record accepted-start through the exact owned PRS row; extend flywheel's existing flow → no new runner, runtime, tests or gates.
3. Read consumer entry and exercise main/adjacent instruction scenarios → approved two-PR batch delegates once; pending changed-head or missing-accounting paths stay held and never silently advance.
4. Classify final paths, run existing applicable gate and independent final Codex QA → retain provenance and Approved review; publish PR against development, leaving arc dependencies open.

Phase 1 QA: map findings integrated above; independent Codex plan review Approved in `relay-system/2026-11-09/gh1400-plan.codex.md` (driver exit 0).

## Phase 2 — Delivery and verification

Non-goals: implementing GH-1399, creating conveyor, modifying merge-cleanup/runtime,
landing real PRs, deployment, changing policy/caps, new suites or gate machinery.
Verification uses existing route and manual instruction checks with provenance under
`TESTS-RESULTS/2026-11-09+GH-1400/`. No speculative frameworks, fuzzers or synthetic runners.
No new decision gate is introduced; refusal scenarios check the instruction's meaning.
Dogfood/conformance follow-ups are bounded here as main/adjacent instruction reads;
the broader real-work qualification remains owned by GH-1386 and the full arc remains
open pending its dependencies. This is a small instruction extension, not a large refactor.

Phase 2 QA: textual main/adjacent instruction smoke PASS; docs gate at 37119562c returned 0 (659 inherited warnings), identity unchanged; final relay pending. No runtime/cost-saving qualification claimed.

## Lessons Learned (For Future Agents)

NO_ENTRY pending observed evidence; instruction review alone cannot establish a throughput gain.
