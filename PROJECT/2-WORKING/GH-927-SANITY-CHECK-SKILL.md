---
gh_issue: 927
source: https://github.com/HiQS-Labs/XYZ-forge/issues/927
title: "Sanity-check blocker value and sibling routing"
status: "In progress"
created: 2026-10-02
updated: 2026-10-02
doc_type: feedback
owner: Codex
goal: "Assess blocker necessity before expensive repair; route recurring and systemic findings to existing skills."
---

# Sanity-check skill

## Status

| What was just completed | What's next |
|---|---|
| Five Markdown skills updated; Fable, GLM and targeted Sol QA Approved. | Publish ready PR against development; await review/merge. No installation. |

Create one Markdown-only skill using the operator-reviewed draft. Activate at the first blocker, ask about unclear core/user-facing importance, permit low-risk deferral with PRS-rated intake, and propose removals rather than silently weakening requirements. Reassess after two investigation attempts yield no new evidence.

Add recommendations for whack-a-mole and radar, with reciprocal pointers in those skills. Preserve their evidence and approval boundaries; prevent recursive automatic audits.

Scope is five SKILL.md files, no runtime code, scripts, new tests, or installation. Independent QA uses Claude Code Fable high and Command Code GLM 5.3 max through relay-xyz, followed by Sol high on the later CI-linkage delta only.

PRS rationale (2026-10-02): rated 65/40/50/80 — current operator priority; investigation waste without an observed security/integrity incident; neutral appeal; bounded Markdown work. Recurrence counts unmeasured. No override.

## QA outcome

Claude Code `claude-fable-5-1`, high effort, reviewed the full three skill files. Round 1 identified a priority conflict with whack-a-mole; the pointer now explicitly preserves a current sanity-check Defer/Dismiss assessment over recurrence-only top-tier assignment. Three clarifications were also applied. Round 2 Approved the content at `33cba144a005b293bfe1d616efb76416ae750020` (relay exit 0).

Receipt: `relay-system/2026-10-02/gh927-sanity-check.fable.md`; structured provenance under `TESTS-RESULTS/2026-10-02+GH-927/`. Scenario walkthroughs are static QA, not runtime behavioral tests. New skill and whack-a-mole pass metadata validation; Radar's unchanged 1336-character description exceeds the validator's 1024-character limit.

Harness verification and limitations: `TESTS-RESULTS/2026-10-02+GH-927/SUMMARY.md`. The initial Small-tier run is retained as failed; its three environment-sensitive failures passed targeted clean-environment reruns.

## Additional GLM QA

Operator-requested Command Code / GLM 5.3 / max effort relay Approved in one round, exit 0. No required changes; optional cluster-scope wording nit retained for operator consideration. Full receipt: `relay-system/2026-10-02/gh927-sanity-check.glm.md`. At that review, skill files were unchanged from the approved Fable content.

## CI linkage addition and publication

Added reciprocal links between sanity-check and ci-debug / ci-optimize. Independent `gpt-6.1-sol` high-effort subagent Approved the 38-line linkage delta at `d2f9038d5e981de15e69e244a0aa2598e70792d0`, with no findings or nits. Review was limited to links, triggers, evidence reuse, recursion, and authority boundaries. Receipt: `relay-system/2026-10-02/gh927-ci-linkages.sol.md`.

All nine relative skill links resolve; four changed skills pass metadata validation and Radar retains its documented baseline failure. The branch classifies as documentation-only. Publication is authorized; this remains in progress until landing is verified. Reversibility: Easy — Markdown instructions and pointers can be reverted without runtime or data migration.
