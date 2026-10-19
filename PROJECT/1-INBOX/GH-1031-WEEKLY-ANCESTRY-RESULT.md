---
gh_issue: 1031
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1031
title: "weekly: verify normal ancestry commit result before clearing its intent"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-12
owner: unassigned
doc_type: feedback
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - TODO: what this explicitly is NOT (scope boundary).
related:
  - TODO: related files/docs, if any.
goal: >
  TODO: one-paragraph statement of what "done" looks like for this idea.
---

## Key concepts

- TODO: 2-4 bullets on what this idea concretely is and why it matters.

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# weekly: verify normal ancestry commit result before clearing its intent

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **HiQS-Labs/XYZ-forge** → repo `HiQS-Labs/XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

The single operator-authorized corrective W7/S4 review for #1022 / draft PR #1024 returned **FAIL/Escalated4/4**, with S4's bounded preparation repair passing and a separate **Medium Should S5** in normal ancestry completion. No Critical/High finding was reported. The fresh full-scope sweep remains incomplete. This issue records the lower-severity disposition; it does not convert FAIL to Approved or authorize another review, new tests, dispatch or landing.

At code f18b051a98551b8da6c5adf5f8d3f87c99ab7a6a (reviewed head def75ab1febf3c57c91aeab3ae8ccf92a4ae6063), `planner_core.py::reconcile_weekly` validates the native ancestry merge's intended tree and clean state before committing, then accepts the returned HEAD and clears `pending_merge` without validating its full tree and ordered parent list. The interrupted-result recovery path already requires the exact ordered two parents and intended tree. Subsequent preparation binds its own starting parent, which cannot repair this earlier admission.

Actual isolated full-clone caller controls now reproduce both admissions:
- An installed fixture pre-commit hook added/staged README during the intentional ancestry commit. The caller completed later preparation and cleared ancestry intent while retaining that unaccounted content.
- A controlled commit-result adapter constructed a real three-parent Git commit with the intended tree, installed its HEAD, and cleared native merge metadata. The caller likewise completed and cleared intent. This measures result admission; it is not a claim that an ordinary Git hook automatically creates a third parent.

Both preserved predecessor HEAD/bytes; all outputs remained HELD/dispatch false. No live connector, primary checkout, planning-branch publication, actual Marathon/Jog or CI test was changed by these controls. The risk is an unintended local projection content/history result and a falsely cleared checkpoint. No production or irreversible user-data-loss event is claimed.

Evidence on this PR: `relay-system/2026-10-12/gh1022-phase9-final.codex.md` Round4 and `TESTS-RESULTS/2026-10-11+GH-1022/phase9-s5-hook-red.log`, `phase9-s5-parent-red.log`, and their provenance. Existing S4/ordinary result repairs remain independently qualified; this separate ancestry boundary remains unfixed.

Bounded follow-up acceptance (verification requirements, not permission to add tests):
- [ ] Reuse the existing interrupted-ancestry result check at normal completion against the captured immutable result SHA: exactly ordered `[previous, predecessor]` parents, intended full tree and clean state before advancing/clearing intent.
- [ ] Exact intended two-parent result advances; extra committed path/tree or third parent refuses and retains intent/HEAD/evidence. Keep preparation's distinct sole-parent contract.
- [ ] Verify normal, interrupted and retry paths using existing suites and isolated recorded manual controls. Every individual new CI test/case/parameter remains separately unapproved.
- [ ] Obtain genuine review authority before further implementation/review of the capped group; no Round5/reset is inferred. Preserve all prior FAIL/escalation history and disclose whole-scope/runtime limitations.

Provisional PRS assessment: priority60/severity60/appeal50/effort80, calc250, no override. Medium local checkpoint defect, high delivery relevance to #1022, neutral appeal and a bounded reuse of an existing check. Same-class admission findings are present within this review history; broader recent incident frequency is unknown.


## Why

TODO: why this matters now -- what prompted it, what breaks or slows without it.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
