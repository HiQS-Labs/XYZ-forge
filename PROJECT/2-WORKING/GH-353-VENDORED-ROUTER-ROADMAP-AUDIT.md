---
title: "GH-353 · Audit and prompt for target ROUTER.md ROADMAP.md frozen status during vendored updates"
status: active
created: 2026-08-31
updated: 2026-08-31
owner: agent
goal: "Add an audit script and LLM prompt workflow to detect stale ROADMAP.md instructions in target ROUTER.md files during vendored updates and prompt for user confirmation."
gh_issue: 353
effort: 2
complexity: 2
risk: 1
phases: 2
---

# GH-353 · Audit and prompt for target ROUTER.md ROADMAP.md frozen status during vendored updates

## Status

| What was just completed | What's next |
|---|---|
| Issue #353 filed, working doc created, task branch cut in fresh full clone | Implement audit script `relay-automation/xyz-router-audit.sh` and wire into `xyz-sync.sh` and `skills/vendor-stack/SKILL.md` |

## Context

Target repositories that vendor XYZ or adopt releases mode (`releases.db`) often retain older `ROUTER.md` files that list `ROADMAP.md` as the active roadmap ledger instead of noting that it is frozen/legacy in releases-mode repos and pointing to `ROADMAP-DASHBOARD.md`.

## Scope

### Phase 1: Router Audit Script & Sync Integration
- Create `relay-automation/xyz-router-audit.sh` (or Python helper) to inspect a target repository:
  - Detects whether the target repo is in releases mode (`releases.db` present or `ROADMAP_SOURCE=releases` in `.pdda-mode`).
  - Inspects `<target>/ROUTER.md`:
    - Checks if `ROUTER.md` directs agents to active `ROADMAP.md` (e.g. mentions editing `ROADMAP.md` or lacks frozen/legacy note).
    - Checks if `ROUTER.md` references `ROADMAP-DASHBOARD.md`.
  - Supports `--fix` (to apply the standard non-destructive update to the role split / startup sequence if confirmed) and report mode.
  - Integrate diagnostic check into `relay-automation/xyz-sync.sh check`.

### Phase 2: LLM Workflow & Skill Integration
- Update `skills/vendor-stack/SKILL.md`:
  - Add post-vendor check step to run `xyz-router-audit.sh`.
  - Explicitly instruct the LLM to prompt the user for confirmation when drift is detected before modifying the target repo's `ROUTER.md`.
- Automated test coverage in `test/gh353-vendored-router-audit.sh` registered in `validate.sh`.

## Acceptance Criteria

1. `relay-automation/xyz-router-audit.sh <target-repo>` reports `ROUTER_DRIFT` when a repo with `releases.db` has an active-`ROADMAP.md` `ROUTER.md`.
2. `relay-automation/xyz-router-audit.sh <target-repo> --fix` updates the role split and startup sequence in `<target-repo>/ROUTER.md` to declare `ROADMAP.md` frozen and introduce `ROADMAP-DASHBOARD.md`.
3. `xyz-sync.sh check` reports router drift alongside tick/commit drift.
4. `skills/vendor-stack/SKILL.md` documents the check-and-prompt workflow for LLMs.
5. All test suites pass cleanly.
