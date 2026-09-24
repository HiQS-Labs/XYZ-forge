---
issue: 246
source: https://github.com/HiQS-Labs/XYZ-forge/issues/246
title: "Refine relay-xyz skill documentation to include explicit QA/Consult prompt template for headless agents"
created: 2026-08-25
updated: 2026-09-22
type: feedback
status: Complete
complexity: 1
risk: 1
effort: 1
phases: 1
---

# GH-246 · relay-xyz QA/Consult prompt template

## Why

Agents scaffolding a relay thread by hand (no `/relay` available) write open-ended "QA this
codebase" prompts, and headless reviewers (Codex/agy/Qwen) then fail the turn, loop
conversationally, or return uncited verdicts. Observed live 2026-08-25: the gh238-qa-pr240
relay succeeded precisely because its thread carried numbered, adjudicable questions with a
citation requirement.

## Key Concepts

- SKILL.md gains a "QA / Consult Template Formatting" section: goal + files to read, numbered
  concrete questions, required output shape (file:line citations), and the `▶ TAKE YOUR TURN`
  automation block, with the canonical NEXT/STATUS header.
- Docs-only hotfix, pushed directly to development.

## Non-goals

- Changing `/relay` or `new-relay.sh` scaffolding behavior.

## Related

- skills/relay-xyz/SKILL.md · relay-automation/new-relay.sh · #246

## Merge evidence

- Commit `3e72ab1ee4540ce8a9fa64dfcfdf6992be7f50a4` landed 2026-08-26 — QA / Consult prompt template in relay-xyz SKILL.md.

