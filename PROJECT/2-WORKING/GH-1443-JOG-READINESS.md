---
title: Close proven Jog preparation automation gaps
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1443
status: Active
created: 2026-11-12
updated: 2026-11-12
owner: Codex
goal: Make target-aware Jog dry-run expose real admission failures before spending a builder turn
risk: 2
phases: 1
---

# GH1443 — Jog readiness automation

## Status
| What was just completed | What's next |
|---|---|
| Three spikes;24 manual controls; focused261/261; final relay Approved; normal full408/408 | Follow-up PR and exact-head hosted checks; awaiting landing, not deployed |

## Scope
Follow-up to source-instruction PR1442; it remains unmerged. Current development already owns the runtime checks being reused, so no unmerged code dependency or implicit merge/install. User authorizes up to three technical spikes and start-task execution with workhorse. No factory dispatch or product changes.

## Initial recon
`jog_run_main` target-aware dry-run validates execution target, prints `_dry_run_preflight` strings, but returns0 regardless of their errors. It skips real executor validation and checkpoint initialization entirely. `validate_marathon_executor` already owns role/binary checks and makes no capacity request. `JogCheckpoint` owns clone/origin and publication checks; its begin/finish mutate state, so must not be called by dry-run. Promotion `contract_probes_from_doc`/`lint_probe` already own syntax acceptance but are absent from dry-run. Environment gates are arbitrary target commands; automatic execution/install in readiness would duplicate qualification and may touch services.

## Three spikes
1. Readiness parity: controlled current entry-point cases for failed per-item preflight, invalid publication root and unsupported promotion command; witness current0 and identify shared read-only owners.
2. Environment: inspect real LTVera1014 incompatible dependency pins and explicit interpreter controls; determine what can safely be known without running arbitrary gates. Do not invent a package solver or wrapper.
3. Roles: compare missing/same/unsupported reviewer dry-run with existing real route validator, capture no-write checks; capacity/auth remain distinct from binary/route validation.

## Proposed minimal implementation (subject to spikes/review)
1. Keep bare queue preview compatibility. In explicit target-aware dry-run reuse real executor validation before reporting readiness; emit that live provider capacity and gate environment remain unverified, without calling models.
2. Return a numeric per-item outcome from existing preflight helper and aggregate nonzero into a nonzero dry-run exit; preserve useful output for each item. Reuse promotion probe extraction/lint for inbox docs before preflight. No repeated probe execution.
3. When checkpoint root is explicitly supplied, reuse/refactor existing read-only publication checks and validate existing option/root constraints before preview. Never call checkpoint begin/finish, fetch/push for publication, write journal, pin globals, acquire lock/lease or reset counters. Leave current live recovery semantics intact.
4. Update existing Jog skill CLI explanation only. Manual controls plus existing gh280 adapter/jog suites in separate disposable clone; final existing classifier chooses qualification. No new suite/registry/gate runner.

## Bet and rollback
Easy local-branch reversal: existing runtime function changes only, no persistent schema/state migration. Blast radius is target-aware dry-run readiness/exit semantics; bare list/preview and actual dispatch must retain behavior. A green dry-run will still not certify credit capacity, incompatible dependencies, deadline monitoring or five useful deliveries. Rollback is revert this PR; no data conversion. The simpler docs-only option already exists in1442 but leaves known machine-detectable failures reporting0. A new prepare command/setup engine would duplicate owners and is rejected.

## Acceptance
- [x] At most3 spikes with concrete red controls and explicit implement/defer decisions.
- [x] Invalid target-aware role/checkpoint/probe/preflight is nonzero, while valid nonempty preparation passes.
- [x] No queue/DB/journal/lock/lease changes or provider calls in checks; bare preview stays compatible.
- [x] Main/adjacent actual-entry smoke, existing focused coverage, independent plan/final QA, classified final qualification.

## Ratings
2026-11-12 provisional65/55/50/65. Consequence: false-ready preparation wastes admission/build opportunities; no newly established loss/corruption. Same-class examples include LTVera1014 and earlier1386 promotion-shape/provider stops; no complete14-vs14-day incidence count, trend unknown. Appeal neutral; estimated focused implementation. Preserve historical run caps.

## Spike/advisory refinements
Three spikes complete; see TESTS-RESULTS/2026-11-12+GH-1443/SPIKES.md. Share exactly live legacy-first promotion selection (any valid legacy probe wins; contract fallback only if none). Helper returns status and summary, and actual CLI explicitly exits2 on any selected nonzero including4/already-landed, missing helper or identity mismatch. Keep static publication checks at existing finish position in live mode; do not move them into begin. Target-aware dry-run reports remote freshness/recovery eligibility unknown. No Jog-state writes, not a claim that preflight probes/fetch are side-effect-free. Consult single available neutral advisor supports this scoped direction; blind disposition committed separately, not cross-model consensus.

## Remaining prerequisite coverage
| Prerequisite | Current owner and this delivery |
|---|---|
| Queue selection and per-item contract/preflight | Existing Jog/Swarm; this PR propagates failures instead of discarding status |
| Explicit reviewer route and executable | Existing Marathon admission; reused in target-aware dry-run |
| Promotion command shape | Existing promotion selector; reused without executing probes twice |
| Publication clone/options | Existing checkpoint constructor/static checks; reused without begin/finish |
| Gate interpreter/dependencies/services | Existing caller gate/env contract; not automatically installed or exercised here |
| Live reviewer credits/auth/capacity | Requires a real authorized provider request; not implied by executable presence |
| Fresh published primary and pending recovery | Existing live checkpoint/admission; static dry-run explicitly leaves freshness/recovery unknown |
| Ownership, time budgets and automatic useful progression | Existing orchestration/flywheel/Jog run; requires actual run evidence, not this preparation patch |

## Milestone rubric
Outcome:13 invalid CLI preparations formerly returned0; shared checks now refuse them.
Critical path: prevents spending admission/build opportunities on machine-detectable preparation errors.
Ownership/evidence: reversible clone implementation, three bounded spikes, independent plan/final review, manual red/green, existing focused suites and normal classified publication. No unattended qualification claim.
