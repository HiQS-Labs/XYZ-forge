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
| Three Markdown skills updated; Claude Code Fable high-effort relay Approved after two rounds. | Retain reviewed local branch for operator handoff; installation and publication are not performed. |

Create one Markdown-only skill using the operator-reviewed draft. Activate at the first blocker, ask about unclear core/user-facing importance, permit low-risk deferral with PRS-rated intake, and propose removals rather than silently weakening requirements. Reassess after two investigation attempts yield no new evidence.

Add recommendations for whack-a-mole and radar, with reciprocal pointers in those skills. Preserve their evidence and approval boundaries; prevent recursive automatic audits.

Scope is three SKILL.md files, no runtime code, scripts, new tests, or installation. Use Claude Code Fable at high effort through relay-xyz for independent QA.

PRS rationale (2026-10-02): rated 65/40/50/80 — current operator priority; investigation waste without an observed security/integrity incident; neutral appeal; bounded Markdown work. Recurrence counts unmeasured. No override.

## QA outcome

Claude Code `claude-fable-5-1`, high effort, reviewed the full three skill files. Round 1 identified a priority conflict with whack-a-mole; the pointer now explicitly preserves a current sanity-check Defer/Dismiss assessment over recurrence-only top-tier assignment. Three clarifications were also applied. Round 2 Approved the content at `33cba144a005b293bfe1d616efb76416ae750020` (relay exit 0).

Receipt: `relay-system/2026-10-02/gh927-sanity-check.fable.md`; structured provenance under `TESTS-RESULTS/2026-10-02+GH-927/`. Scenario walkthroughs are static QA, not runtime behavioral tests. New skill and whack-a-mole pass metadata validation; Radar's unchanged 1336-character description exceeds the validator's 1024-character limit.
