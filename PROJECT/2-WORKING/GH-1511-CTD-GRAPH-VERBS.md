---
gh_issue: 1511
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1511
title: "connect-the-dots: search the code graph by capability verbs, not module names"
status: "Active (2-WORKING — PR #1513 ready; awaiting merge)"
created: 2026-11-17
updated: 2026-11-17
doc_type: feedback
owner: Claude
goal: Tell connect-the-dots to search the code graph by capability verbs and synonyms, with call tracing optional.
effort: 1
complexity: 1
risk: 1
phases: 1
ratings_provisional: false
---

# GH-1511 — connect-the-dots: search the code graph by capability verbs

Canonical discussion: [Issue #1511](https://github.com/HiQS-Labs/XYZ-forge/issues/1511).

## Status

| What was just completed | What's next |
|---|---|
| One line added to step 2, rung 2 of `skills/3-weekly/connect-the-dots/SKILL.md`, plus a CHANGELOG entry (PR #1513). | Merge PR #1513, then run the post-merge reconcile. |

## Why

In two flywheel outer-loop runs on 2026-11-17, searching the graph by capability verbs was the
step that first found the subsystems the maps never mention. Call tracing and structured queries
added detail but no new module, so they stay optional.

## Verification

- `utils/pdda/pdda.sh run`: no errors.
- Publisher suites in a disposable gate clone at `89c509c2c`: gh589-xyz-mini-sync 39/0,
  gh620-skills-army-mini-sync 28/0, gh589-skill-viewer 8/0.
- No new tests or registry entries (AGENTS.md *No new tests*).

## Lessons Learned (For Future Agents)

NO_ENTRY. The verb-search finding rests on one comparison of two runs.
