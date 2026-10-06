---
gh_issue: 985
source: https://github.com/HiQS-Labs/XYZ-forge/issues/985
title: Claude workhorse continuation optimization
status: inbox
created: 2026-10-06
updated: 2026-10-06
owner: Codex
goal: Optimize Claude continuation using the shared verified-outcome contract
---

# Claude workhorse continuation optimization

## Status

| What was just completed | What's next |
|---|---|
| Registered authorized stacked follow-up on PR #984 | Fable low-effort planning, independent plan QA, Agy build, Fable final QA, orchestrator approval |

## Intake

User requested a separate start-task building on PR #984's branch. Roles: Fable light/low planner; Agy builder; independent Fable reviewer; Codex orchestrator and final approver. Local Claude CLI 2.1.289 accepts `--model fable --effort low` and reports canonical model `claude-fable-5-1`. This is a local CLI child-agent route; Codex's collaboration model list does not expose Fable. No silent model substitution.

## Bounded recon

Stack base: `3c9bfa8ca452bfddd8ec19d4ac243e02372531bb`, PR #984, development integration base `8ec99b6066c997a00c40761c9efb9f9caaff8b8f` (verify full actual base before publication). Shared contract now explicitly applies to Claude and Codex. Skill frontmatter registers existing stop-hook.sh. The hook reads only this session's .workhorse checklist and emits block for open boxes; no semantic outcome evaluation. Its reason still advertises parking as an escape and its comment claims an eight-continuation harness cap. Those claims require recon against current runtime and the shared contract before changing behavior. Preserve malformed-input/no-checklist fail-open boundaries unless a concrete requirement warrants a supported change.

Prior-art recon: PR #966 implements read-only /xyz-status; #967 gates its follow-ups on interactive evidence and a keep decision. Do not duplicate or extend those pending features. No new gate machinery or test suite (GH-831). A mod is optional and only appropriate if existing mechanisms cannot meet the outcome; do not implement an automatic prompt loop, as-user prompts, global trust/config changes or permission approval.

Graph Verify tier: XYZ-forge generation 2026-09-01, workhorse files not_tracked and xyz-mod missing; direct full source reads used. No exhaustive graph completeness claim. Official sources: https://code.claude.com/docs/en/hooks, https://code.claude.com/docs/en/skills, https://code.claude.com/docs/en/plugins/mods/overview and /reference. Local version/types are authoritative for implementation.

## Rating rationale

Proposed pri 65 / sev 45 / appeal 50 / effort 85. User ordered immediate follow-up, shared boundary mismatch can encourage premature stopping, no demonstrated data loss. Appeal neutral. Small existing surface. Recurrence: original operator report plus GH-911 and GH-983 context; distinct incident trend unknown, no measured rate.

## Planning constraints

Fable should write a lean plan in the existing canonical document, with observed input, smallest viable bet, simpler alternative, rollback, no speculative gates/runners, acceptance and red control. One ordered execution list. Agy owns production files only after independent Approved plan QA and exact-row accepted-start. Reviewer writes only relay receipt. Separate full clone for mutation-heavy gates; committed provenance. A separate stacked PR must expose its dependency and incremental diff; no merge/deployment authorization.
