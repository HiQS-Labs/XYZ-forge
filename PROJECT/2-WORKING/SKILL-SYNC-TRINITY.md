---
title: Skill Sync Trinity
status: Active
created: 2026-07-17
updated: 2026-07-17
owner: noel
doc_type: project
effort: 2
complexity: 2
risk: 1
phases: 3
related:
  - skills/skill-sync-trinity/PROJECT.md
  - skills/skill-sync-trinity/SKILL.md
  - skills/skill-sync-trinity/scripts/export_frontier_skill_inventory.py
  - skills/skill-sync-trinity/scripts/render_working_doc.py
  - skills/skill-sync-trinity/scripts/sync_trinity.py
  - skills/skill-sync-trinity/scripts/validate_trinity.py
non_goals:
  - Not publishing or installing the skill into external skill registries.
  - Not auto-editing ROADMAP.md or opening GitHub issues as part of local scaffolding.
  - Not turning this into a generic package manager for repo-local skills.
goal: >
  Build the repo-local skill-sync-trinity scaffold so a repo can keep one canonical PDDA working
  doc, one lean SKILL.md, and deterministic Python helper scripts aligned without duplicating plan
  state across surfaces.
roadmap_exempt: true
---

# Skill Sync Trinity

## Status

| What was just completed | What's next |
|---|---|
| Added an optional frontier-environment inventory export path to the skill: `SKILL.md` now says it only runs on explicit user request, and a deterministic helper writes Claude/Codex/Gemini skill-file inventories into repo-local `temp/`. | Forward-test the new inventory helper on the next explicit user request and decide later whether this pattern belongs in future generic skill scaffolds. |

## Table of contents

- [Phase 1 - Working doc contract](#phase-1---working-doc-contract)
- [Phase 2 - Skill contract](#phase-2---skill-contract)
- [Phase 3 - Deterministic helpers](#phase-3---deterministic-helpers)
- [Validation](#validation)

## Context

This folder started with only an empty `skills/skill-sync-trinity/PROJECT.md`. The active-work
surface belongs in `PROJECT/2-WORKING/` on PDDA rails, while the skill folder should hold only the
runtime-facing assets the skill needs: a concise `SKILL.md`, a local pointer back to the active doc,
and deterministic helper scripts.

The "trinity" here is explicit:

1. the canonical working doc under `PROJECT/2-WORKING/`
2. the repo-local `SKILL.md`
3. the deterministic Python helpers under `scripts/`

## Phase 1 - Working doc contract

### Checklist

- [x] Promote the active plan into `PROJECT/2-WORKING/SKILL-SYNC-TRINITY.md`.
- [x] Add PDDA frontmatter, the exact two-column status table, and a table of contents.
- [x] Mark the doc `roadmap_exempt: true` so this local skill scaffold does not create ROADMAP drift.
- [x] Keep `skills/skill-sync-trinity/PROJECT.md` as a pointer, not a second competing plan.

### QA checklist - Phase 1

- [x] Required frontmatter fields are present.
- [x] The status header uses the exact PDDA column names.
- [x] The local `PROJECT.md` points back to this canonical working doc.

## Phase 2 - Skill contract

### Checklist

- [x] Add `skills/skill-sync-trinity/SKILL.md` with clear trigger text and scope boundaries.
- [x] Make the workflow explicitly keep the working doc, `SKILL.md`, and Python helpers aligned.
- [x] Point the skill at bundled scripts instead of embedding long procedural detail in the skill body.

### QA checklist - Phase 2

- [x] `SKILL.md` has required frontmatter (`name`, `description`).
- [x] The body stays concise and routes deterministic work into scripts.
- [x] The skill explains when not to use it.

## Phase 3 - Deterministic helpers

### Checklist

- [x] Add a renderer that emits a PDDA-compliant working doc for a target skill.
- [x] Add a sync helper that can scaffold the local pointer and a starter `SKILL.md`.
- [x] Add a validator that checks the three-way scaffold for drift.
- [x] Add an explicit, on-demand inventory exporter for installed skill files across the three frontier environments, writing into repo-local `temp/`.

### QA checklist - Phase 3

- [x] All helper scripts parse and compile with `python3 -m py_compile`.
- [x] The validator checks both the local skill folder and the working doc contract.
- [x] The helpers use repo-relative paths in their generated content.
- [x] The inventory exporter reports missing environment roots truthfully instead of inventing installs, and it writes output only when explicitly invoked.

## Validation

- `python3 -m py_compile skills/skill-sync-trinity/scripts/*.py`
- `python3 skills/skill-sync-trinity/scripts/validate_trinity.py --skill-dir skills/skill-sync-trinity --working-doc PROJECT/2-WORKING/SKILL-SYNC-TRINITY.md`
- `python3 skills/skill-sync-trinity/scripts/export_frontier_skill_inventory.py --output-dir "$(mktemp -d)/frontier-skill-inventory"`
- `utils/pdda/pdda.sh frontmatter`
- `utils/pdda/pdda.sh status-table`
- `utils/pdda/pdda.sh roadmap-coverage`
