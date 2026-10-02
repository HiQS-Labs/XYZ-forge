---
gh_issue: 933
source: https://github.com/HiQS-Labs/XYZ-forge/issues/933
title: "Sharpen skills-army-hq drift and immediate read-through boundaries"
status: "In progress"
created: 2026-10-02
updated: 2026-10-02
doc_type: feedback
owner: Codex
goal: "Sharpen skills-army-hq SKILL.md drift checking and symlink read-through boundaries based on Codex Astra relay findings."
---

# Sharpen skills-army-hq drift and immediate read-through boundaries

## Status

| What was just completed | What's next |
|---|---|
| Relay-xyz turn with Codex Astra completed (findings R1 and R2). | Implement doc sharpenings in skills-army-hq/SKILL.md, verify, and open PR. |

## Background & Findings

During an automated `/relay-xyz` turn on `skills-army-hq` using Codex Astra (`gpt-6-astra`, medium reasoning effort), two high-confidence operational failure modes were identified in `skills/3-weekly/skills-army-hq/SKILL.md`:

1. **R1 — Distinguish working-tree equality from upstream freshness before re-vendoring:**
   The drift checker hashes local files against whatever branch is checked out at `--canonical`. It cannot determine whether that checkout is older, newer, or contains unmerged WIP. Clarify that `ok` indicates matching local content, not upstream freshness; inspect the source branch/version before following the re-vendor remedy.
2. **R2 — Clarify immediate symlink read-through boundary:**
   Updating an already-symlinked collection payload makes new bytes live to apps immediately through existing directory symlinks. `sync.py`'s subsequent drift refusal governs link reconciliation, not intake rollback. Review source before updating.

Scope: Pure documentation sharpening in `skills/3-weekly/skills-army-hq/SKILL.md`. Zero runtime code changes, zero new tests (GH-831 rail).
Reversibility: Easy.
