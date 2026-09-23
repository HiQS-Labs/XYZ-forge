---
gh_issue: 762
source: https://github.com/HiQS-Labs/XYZ-forge/issues/762
title: "Start marathon: route and prepare a verified marathon before firing"
status: In progress
created: 2026-09-23
updated: 2026-09-23
owner: Codex
doc_type: plan
complexity: 2
risk: 2
effort: 2
phases: 3
ratings_provisional: false
non_goals:
  - No runtime planner rewrite
  - No automatic dispatch
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/762
goal: >
  Route marathon preparation through one skill that reviews intake, contracts and plans, prepares
  collision-safe YAML, and proves preflight and dry-run before any dispatch.
---

## Key concepts

- One preparation entry point
- Reuse existing planner and marathon runner
- Keep explicit fire gate

# Start marathon: route and prepare a verified marathon before firing

## Table of contents

- [Phase 0 — Recon](#phase-0--recon)
- [Phase 1 — Route and prepare](#phase-1--route-and-prepare)
- [Phase 2 — Verify and review](#phase-2--verify-and-review)

## Status

| What was just completed | What's next |
|---|---|
| Skill refactor and focused hook/installer checks passed; Agy content review approved. The full gate was red on baseline failures reproduced on `development`. | Open a draft PR to `development`; resolve parked baseline gate issue #764 before merge readiness. |

## Idea

## Goal

Rename and expand the existing `marathon-triage` skill into a discoverable **start marathon** preparation workflow. A plain “marathon” request should route to this preparation flow when intent is ambiguous; explicit fire/execute requests must retain the executor and operator gate.

## Scope

1. Audit current routing and references, preserving legacy entry points where practical.
2. Primary path: reconcile intake and live issues; review active PDDA docs and preflight contracts; produce implementation plans with phase QA; independently review plans; compute disjoint lanes and waves; prepare the existing marathon YAML/plan artifacts; run preflight and dry-run without dispatch.
3. Secondary path: when another session already wrote the docs, verify their current issue/commit state, run a focused smoke check, preflight, and dry-run; repair concrete gaps.
4. Add bounded recovery through `workhorse` for diagnosis and `unstuck` for stalls. Respect lane attempt caps and never turn a deterministic blocker into a success claim.
5. Route unrelated findings to canonical parked intake (`PROJECT/1-INBOX` plus RELEASES roadmap row), avoiding a second `PARKED/` queue in this repo.

## Acceptance

- [ ] Skill name, description, installed entry point, and prompt nudge route “start marathon” and ambiguous “marathon” to preparation; explicit firing remains gated.
- [ ] Both primary and secondary paths have ordered outputs and checkable exit conditions.
- [ ] Plan QA, write-set collision review, YAML, preflight, and dry-run use current repo contracts without duplicating planner logic.
- [ ] Recovery is bounded and preserves the one-marathon-at-a-time and parked-lane policies.
- [ ] Existing callers and installed skill links have a migration or compatibility route.
- [ ] Independent Agy relay reviews the refactor; relevant repo checks pass.

Related: #443 (PRS/preflight and driver dry-run implementation), #522 (continuous admission), #316 (umbrella identity). This issue is skill routing and workflow only; it does not claim missing runtime commands already exist.

## Why

The current skill stops at candidate triage and does not prepare reviewed plans or full YAML dry-runs.

## Phase 0 — Recon

The current skill handles capture, ranking and per-candidate preflight but stops before plan QA,
YAML preparation and a full `marathon.sh --plan ... --dry-run`. `pre-marathon` currently duplicates
the dry-run step. Routing is anchored by `agents/openai.yaml`, the Claude installer, and
`relay-automation/hooks/skill-nudge.sh`. A bare “marathon” is not routed. `PROJECT/1-INBOX` plus the
RELEASES roadmap is the canonical parked intake here. `marathon_drive.py` and `marathon.sh` already
have dry-run support; no executor rewrite belongs in this issue. #443 retains the more complete PRS
freshness gate. The chosen change is Easy to reverse: rename the source skill, keep a legacy alias,
update routes and tests, and retain the explicit fire boundary.

QA: source paths and supported commands inspected; no new runtime schema introduced.

## Phase 1 — Route and prepare

1. Rename the source skill to `start-marathon` with a `marathon-triage` compatibility link; update
   installer, Codex metadata, nudge hook, and direct callers.
2. Define primary and secondary routes, a bounded recovery ladder, and canonical parking.
3. Add contract review, implementation plan QA, lane collision audit, YAML and full-plan dry-run to
   the preparation flow, reusing planner and runner contracts.

QA: `git diff --check`; inspect all references, explicit fire gate and installed alias behavior.

## Phase 2 — Verify and review

1. Run the nudge hook suite with new positive and negative route cases in a disposable full clone.
2. Run PDDA checks and full `validate.sh` in that disposable clone.
3. Run an Agy `relay-xyz` review of the changed skill and evidence; resolve findings, then open a
   PR against `development` with the exact gate result.

QA: `xyz-harness-hooks.sh` 66/66 and `gh678-installer-live-links.sh` passed in
disposable clones. Agy's final transcript says `STATUS: Approved`; the relay wrapper exited 4 after
`tick done` failed, parked as #763. Full `validate.sh` failed on `gh142`, `gh549`, `gh605` that also
fail on untouched `development`; `gh425` passed after installing missing `pytest` in the temporary
venv. The baseline gate follow-up is parked as #764. PR readiness remains pending.
