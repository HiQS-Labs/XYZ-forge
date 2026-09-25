---
gh_issue: 762
source: https://github.com/HiQS-Labs/XYZ-forge/issues/762
title: "Start marathon: route and prepare a verified marathon before firing"
status: In progress
created: 2026-09-23
updated: 2026-09-24
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
| GH-796 F1–F6 remediation integrated through reconciled #795 at base `69367026`; B1 preserved generation 1152 and replayed only #762/#763. Earlier focused controls and bounded source review pass. | Obtain driver-attested independent final relay QA and run the final combined full local gate, then publish and update PR #765. |

## Idea

## Goal

Rename and expand the existing `marathon-triage` skill into a discoverable **start marathon** preparation workflow. A plain “marathon” request should route to this preparation flow when intent is ambiguous; explicit fire/execute requests must retain the executor and operator gate.

## Scope

1. Audit current routing and references, preserving legacy entry points where practical.
2. Primary path: reconcile intake and live issues; review active PDDA docs and preflight contracts; produce implementation plans with phase QA; independently review plans; compute disjoint lanes and waves; prepare the existing marathon YAML/plan artifacts; run preflight and dry-run without dispatch.
3. Secondary path: when another session already wrote the docs, verify their current issue/commit state, run a focused smoke check, preflight, and dry-run; repair concrete gaps.
4. Add bounded recovery through `workhorse` for diagnosis and `unstuck` for stalls. Respect lane attempt caps and never turn a deterministic blocker into a success claim.
5. Record incidental out-of-scope findings in root `PARKED/`; promote selected items through issue-first `PROJECT/1-INBOX` capture and RELEASES registration during triage.

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
`relay-automation/hooks/skill-nudge.sh`. A bare “marathon” is not routed. Root `PARKED/` is the
first home for incidental out-of-scope observations; `PROJECT/1-INBOX` and the RELEASES roadmap
are the formal intake after promotion. `marathon_drive.py` and `marathon.sh` already
have dry-run support; no executor rewrite belongs in this issue. #443 retains the more complete PRS
freshness gate. The chosen change is Easy to reverse: rename the source skill, keep a legacy alias,
update routes and tests, and retain the explicit fire boundary.

QA: source paths and supported commands inspected; no new runtime schema introduced.

### Recon Map — root PARKED intake

- **State and authority:** `PARKED/README.md` owns the incidental-observation format and promotion boundary. `ROUTER.md` owns startup and formal issue-first intake; `PROJECT/PDDA.md` owns the issue/capture/RELEASES contract after promotion. “Queue / parked intake” in RELEASES means formally captured deferred work, not the root folder.
- **Entry and writes:** agents following `AGENTS.md`, `workhorse`, `start-marathon`, and `unstuck` may add sourced root `PARKED/` notes for findings outside the active goal. The standup skill writes only its structured `- [key] ... — check: {...} — close:` records there. A current-goal blocker remains in the active plan.
- **Readers:** standup `collect.sh` lens 8 and `triage.py` scan root `PARKED/`. They recognize only records with the standup `— check:` marker; general Markdown notes and checklists stay human-triaged. No automatic issue, capture, or ledger row is created by parking.
- **Promotion and rollback:** triage may leave, drop, or promote a note. Promotion opens an issue first, creates its `PROJECT/1-INBOX/GH-*.md` capture and RELEASES row, then adds a `Promoted:` pointer to the root note. This doc-only routing is **Easy** to reverse; the standup filter is covered by a focused regression and red control. Previously filed #763/#764 stay in their formal homes and get root pointers rather than duplicate issues.
- **Blast radius and open edge:** the change touches routing text and the standup reader of the shared folder, not the marathon driver or RELEASES schema. Historical `PARKED/` entries and the frozen GH-77 contract remain valid. The existing formal intake of #763/#764 is retained.

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
Root PARKED routing and standup parser follow-up: `gh77-standup-triage.sh` passed 153/153 in a
disposable full clone. A red control using the prior broad parser marked a general checklist as
degraded; restoring the new parser returned lens 8 to `ok`. PDDA run had zero errors; RELEASES
integrity check had zero failures and nine existing warnings.

### GH-796 integration verification — 2026-09-24

At source `0e9c4b8859bc034bb6a15bdc635e97b8185b6d06`, the GH-784 gate, harness hooks, installer live links, standup triage (153/153), and GH-777 inventory ratchet all passed in a separate disposable full clone. PDDA aggregate returned zero errors and 37 warnings; pending marathon proof items remain unchecked. The clone remained clean with the expected HEAD, origin, and non-bare identity. Committed logs and per-command provenance are in `TESTS-RESULTS/2026-09-24+GH-796-PR765/integration-focused-0e9c4b88/`.

The earlier #764 baseline follow-up is completed on development and is not a current blocker. Earlier relay text without successful driver attestation is not reused as final approval. Final #795 integration, current-head independent relay QA, and the full local gate remain outstanding; this focused result does not establish merge readiness.
