---
gh_issue: 1376
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1376
title: "Add flywheel skill for adaptive Jog orchestration"
status: Active — PR #1378 ready; awaiting merge approval
created: 2026-11-08
updated: 2026-11-08
owner: parent orchestrator
doc_type: feedback
complexity: 2
risk: 1
effort: 2
phases: 1
branch: feat/XYZ-forge-gh1376-flywheel-skill-2026-11-08
ratings_provisional: false
non_goals:
  - No new runner, queue, scheduler, supervisor, executable, test suite, or gate.
  - No automatic marathon firing, PR merging, deployment, or direct edits to deployed skill copies.
related:
  - skills/2-daily/jog/SKILL.md
  - skills/1-hourly/relay-xyz/SKILL.md
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1328
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1358
goal: >
  Deliver a reviewed flywheel skill that routes real work through existing Jog and companion skills, carries the #1358 operating modes and standing repair ladder, and lands as a documentation-only PR against development.
---

## Key concepts

- One operator-facing route from readiness and pickup through execution, recovery, landing, and the next eligible item.
- Bounded autonomous repair is normal operation; only genuine authority, safety, spending, access, destructive-action, merge, or control-bypass boundaries escalate.
- Existing skills retain their commands, locks, limits, evidence, and ownership; flywheel supplies sequencing rather than another implementation.

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# Add flywheel skill for adaptive Jog orchestration

## Status

| What was just completed | What's next |
|---|---|
| PR #1378 base conflict resolved at `29f41026`; normal documentation push gate passed. Direct takeover review corrected ready-PR and marathon routing; see TESTS-RESULTS/2026-11-08+GH-1376/takeover-review.md. Earlier independent QA receipts cover their recorded revisions. Final correction publication/checks are separate. | Await the operator's per-PR merge decision. Do not merge or deploy automatically. |

## Idea

## Objective

Author a new `flywheel` skill from a fresh full clone cut from `origin/development`. It should give an operator one reliable entry point that chains the existing Jog and companion skills, applies the current #1358 rubrics, and keeps authorized work moving through routine failures.

This is an orchestration skill over existing workflows, not a new runner, queue, scheduler, supervisor, or gate.

## Policy to carry

Use the three rubrics and work modes currently defined in #1358:

- Rubric 1A: Formal Unattended Work.
- Rubric 1B: Setup and Repair Work.
- Rubric 2: Discriminating real-world test.
- Rubric 3: Decision value for cost.
- **Autonomous bounded repairs allowed and recorded; human assistance disclosed; no silent cap, permission, safety, or gate changes.**

Carry the standing authorization ladder: recover through a supported path; make the smallest authorized routine repair and verify it; keep independent eligible work moving; escalate only actual authority, safety, spending, access, destructive-action, merge, or control-bypass boundaries. Do not reopen routine authorization separately in each session.

The skill is the operational projection of these rules; link the canonical policy issues rather than copying their history or rehearsing unsupported outcomes.

## Existing skills to chain, subject to final recon

- `start-task` for issue governance, fresh full clones, surgical planning, and double-relay QA when a task needs that lifecycle.
- `jog` for serial pickup, admission, execution, recovery verbs, and receipt-backed landing.
- `relay-xyz` for locating the harness and performing independent plan/final review.
- `start-marathon` only for genuinely marathon-shaped work; preparation does not authorize firing.
- `handsfree` for bounded same-conversation continuation while external work finishes.
- `unstuck` for no-movement, repeated planning, passive waiting, or premature handoffs; re-drive the primary engine after the correction.
- `merge-cleanup` for approved landing/reconciliation and safe checkout retirement within its existing authority.
- `skills-army-hq` only when installation or deployment is explicitly requested; never edit deployed copies directly.

Keep this as a small decision/routing layer. Reuse each owned skill's commands, limits, locks, and evidence contracts rather than duplicating them.

## Acceptance

- [ ] A new `flywheel/SKILL.md` is authored in the appropriate existing skill tier and added to the Skills Index.
- [ ] It contains the current rubric modes and standing repair/authorization rules in a concise operational form.
- [ ] It gives one ordered flow from readiness and pickup through execution, recovery, review, landing, and the next eligible item.
- [ ] It chains the named existing skills by trigger and responsibility, with no parallel queue, supervisor, runner, or write path.
- [ ] It distinguishes setup/repair from formal unattended work without prohibiting bounded autonomous repairs in either mode.
- [ ] It preserves per-PR merge approval and all existing caps, locks, containment, and authority boundaries.
- [ ] Plan QA and final independent Codex QA are recorded under `relay-system/`.
- [ ] The classified documentation gate passes, plus a consumer-entry-point smoke read for the new skill; no new test suite or registry entry.
- [ ] A reviewed PR targets `development`. Deployment is a separate explicit action after the source is ready.

## Non-goals

- No new executable, daemon, queue, scheduler, test suite, or gate machinery.
- No automatic marathon firing or PR merging.
- No dependency on draft PR #1024; its weekly-intake scope is separate.
- No direct edits to deployed skill collections or app symlinks.

## Rating proposal

PRS `pri/sev/appeal/effort`: **80/45/50/80**. Priority reflects the operator's explicit request and the observed stop-and-go cost in #1356/#1358; severity reflects recurring workflow friction rather than data loss; appeal is neutral 50; effort is high-cheapness because the expected deliverable is a documentation-only routing skill using existing machinery. Recurrence evidence is the concentrated 2026-11-07/08 orchestration and handoff failures in those issues; no broader trend is claimed.

Refs #1328 and #1358. Leaves both open for their existing execution scope.

## Why

The #1356/#1358 sessions showed that the individual tools can produce reviewed PRs while the operator still sees stop-and-go behavior between them. Existing skills already own intake, queueing, execution, review, recovery, landing and continuation. The missing operator-facing piece is one concise route that selects those skills, carries the agreed repair policy, and resumes the primary engine after a correction.

## Recon and current-state map

- **Base:** fresh full clone at `bb4e16871b230696dc82881f196fa313b755d920`, branch `feat/XYZ-forge-gh1376-flywheel-skill-2026-11-08`; canonical GitHub origin and per-clone hook verified. Refresh from `origin/development` before implementation and again before final publication.
- **No existing flywheel skill:** `skills/*/*/SKILL.md` has no flywheel entry. Prior-art recon found flywheel campaigns and policies but no open flywheel-skill PR. This request is therefore a new composition skill, not a duplicate of #1356/#1358 execution.
- **Existing execution owner:** `skills/2-daily/jog/SKILL.md` owns serial pickup, preflight, Marathon-backed execution, `resume` → `retry-gate` → `retry-build`, evidence and landing. Flywheel must not copy its CLI details beyond stable routing references.
- **Existing review owner:** `skills/1-hourly/relay-xyz/SKILL.md` owns harness location, independent review, containment and relay receipts. Flywheel invokes it rather than creating a review path.
- **Existing planning owner:** `start-task` handles governed issue/clone/plan/double-QA delivery; `start-marathon` prepares genuinely marathon-shaped arcs and does not fire them by default.
- **Existing continuation/recovery owners:** `handsfree` supplies bounded same-conversation wakes; `unstuck` interrupts no-movement behavior and re-drives the primary engine. Neither is a deployed scheduler or a replacement for Jog recovery.
- **Existing landing/deployment owners:** `merge-cleanup` owns authorized PR landing, reconciliation and safe retirement; `skills-army-hq` owns source-to-collection deployment only when explicitly requested.
- **Policy source:** #1358 currently defines Rubrics 1A/1B, 2 and 3 and the standing authorization ladder. Flywheel is an operational projection for runs that explicitly select this policy; it does not rewrite other campaigns' policies or #1328.
- **Dependencies:** draft #1024 is weekly intake, conflicted and explicitly not merge-authorized; it is not needed. The external #1316/#1318 landing task is not a flywheel dependency. Fetch their eventual integration updates normally and reread any referenced contract they change.
- **Skill tier:** `2-daily`, matching its role in queueing and driving work and its neighbor `jog`. The required Skills Index row lives in `ARCHITECTURE.md`.
- **Deployment status:** Skills Army HQ status/list could not start because the resolved collection root is absent on this device (`~/git-pulse-sync/Deployed Skills`). This does not block source authoring; no installation or deployment is attempted or claimed.

## Smallest viable bet

Add one concise `skills/2-daily/flywheel/SKILL.md` and its Skills Index row. The skill selects a work mode, applies the rubrics and standing authorization ladder, then routes to the existing skills in execution order.

**Assumption:** a single explicit composition and continuation contract will reduce repeated planning and premature handoffs without changing runtime code. **Failure mode:** duplicating detailed CLI/policy text would drift or contradict the owned skills. The mitigation is stable links and decision rules, not copied implementation detail.

**Reversibility: Easy.** Remove the skill file and index row to roll back. No runtime, schema, deployed collection, credential, or remote-service change is in scope.

**Alternative considered:** add a flywheel section to `jog`. Rejected because the requested unit spans intake, Jog, Marathon, review, continuation, landing and deployment; Jog cannot own those other skills' contracts. `start-task` likewise cannot own recurring queue execution. A thin top-level skill is the smallest shape that covers the whole route.

## Non-goals

- No new executable, queue, scheduler, supervisor, daemon, test suite, gate, or second state writer.
- No automatic marathon firing, PR merging, deployment, or expanded permissions.
- No implication that `handsfree` supplies a durable scheduler, or that a skill alone proves unattended reliability.
- No repetition of the full #1356/#1358 run history or detailed command reference already owned by other skills.

## Ordered implementation and verification

1. **Author the skill.** Create `skills/2-daily/flywheel/SKILL.md` with frontmatter, explicit triggers/non-triggers, the two work modes, three rubrics, the exact repair sentence, the four-rung standing authorization ladder, and one ordered operating flow. Route to `start-task` → `jog` (or `start-marathon` only for qualifying arcs) → `relay-xyz` verification → authorized `merge-cleanup` landing → next eligible item, with `handsfree` and `unstuck` as continuation/interrupt routes. -> Expect a consumer read to identify the next owner for readiness, execution, recovery, review, landing and deployment without inventing commands.
2. **Register the source.** Add one `flywheel` row to `ARCHITECTURE.md` → Skills Index → `2-daily`. -> Expect the relative link to resolve and the row to describe routing rather than a new engine.
3. **Smoke the consumer path.** Read the finished skill from `skills/2-daily/flywheel/SKILL.md`, follow each named skill link, and check the exact repair sentence and all four ladder rungs are present and non-empty. Record the read and any corrections under `TESTS-RESULTS/2026-11-08+GH-1376/` with `provenance.jsonl`. This is a manual documentation check, not a new suite or gate.
4. **Run the classified final gate.** Use `utils/ci-route.sh` on the actual changed paths, including the project doc, skill, index and receipts. The expected route is documentation/PDDA; run the resulting existing gate in the required isolated full-clone arrangement and verify repository identity before/after. -> Expect zero deterministic errors. No full runtime suite for a docs-only route and no new tests.
5. **Final independent review and publication.** Run Codex final QA through `relay-xyz` against the committed skill, plan, acceptance map and smoke/gate evidence; adjudicate findings within the existing three-round cap. Push through the installed pre-push hook, open a PR against `development`, verify its base/head/scope/checks, and post the start-task closeout on #1376. -> Expect a reviewed ready PR or a precise remaining blocker. Deployment stays separate.

## Acceptance falsification

The plan fails if the new file is absent, its frontmatter or index link is invalid, any required rubric/ladder segment is empty, a referenced owner cannot be resolved, the flow requires a new queue/runner/scheduler, bounded supervisor/config repairs remain prohibited, merge/deployment authority is silently expanded, or the classified gate/final independent QA does not pass. These are direct content and consumer checks; no decorative new gate is added.

## Plan-review questions

1. Does the proposed skill fill a real gap that `jog` or `start-task` cannot carry without mixing ownership?
2. Does the flow preserve each existing skill's authority, locks, caps, recovery order, merge boundary and evidence contract?
3. Does it carry the current #1358 modes and standing authorization ladder without reintroducing a no-repair freeze or a per-session authorization debate?
4. Is the scope limited to the minimum documentation files and existing manual/classified verification, with no new tests or machinery?
5. Are any required companion skills, non-goals, dependencies, rollback considerations or consumer smoke checks missing?


## Scope addendum — operator-requested GP/AGENTS text

After the hosted-green flywheel delivery, the operator explicitly requested inclusion in the same PR of a short `GUIDING-PRINCIPLES.md` section on adaptive work and continuous handoff, plus an `AGENTS.md` pointer to it. The operational rubrics and ladder remain only in the flywheel skill; no code or full-rubric duplicate is added. The operator will override approval for this text-only extension.
