---
title: "GH-804: Review and simplify skill instruction tests introduced by GH-798"
status: Active
created: 2026-09-24
updated: 2026-09-24
owner: Antigravity
gh_issue: 804
source: https://github.com/HiQS-Labs/XYZ-forge/issues/804
doc_type: maintenance
complexity: 1
risk: 1
effort: 1
ratings_provisional: false
branch: feat/gh804-simplify-skill-tests
goal: >
  Review and simplify skill instruction tests in test/gh798-status-skill.sh while
  retaining critical installer safety, structure, and architecture validation.
---

# GH-804 — Review and simplify skill instruction tests introduced by GH-798

## Status

| What was just completed | What's next |
|---|---|
| Simplified test/gh798-status-skill.sh, validated zero ratchet regressions (gh139), and passed Codex relay QA | Review and landing of PR #806 to development |

## Context & Problem

GH-798 added the `status` skill and DRY audit in `review-code`, alongside a 127-line test suite `test/gh798-status-skill.sh`. GH-801 fixed 10 pipe-to-grep instances violating the repository ratchet.
Issue #804 reviews the instruction-wording assertions in `test/gh798-status-skill.sh` to remove brittle exact-phrase and multi-stage awk severity checks in prose docs while retaining essential safety coverage (installer link safety, frontmatter validation, architecture registration, and valid falsification controls).

## Acceptance Criteria

- [x] Inventory all assertions in `test/gh798-status-skill.sh` and classify failure modes.
- [x] Retain compact installer safety coverage (foreign live links refusal, dangling link replacement).
- [x] Retain structural & metadata validation (file existence, frontmatter name/description, ARCHITECTURE.md registration).
- [x] Consolidate brittle multi-line awk phrase and severity assertions on `review-code/SKILL.md` into direct, robust section/keyword checks.
- [x] Preserve meaningful negative controls (e.g. missing recital, missing core sections).
- [x] Verify test suite passes cleanly with zero ratchet regressions (`gh139`).

## Merge evidence

- PR: https://github.com/HiQS-Labs/XYZ-forge/pull/806
- Regression suites: `test/gh798-status-skill.sh` (21 pass, 0 fail), `test/gh139-pipe-grep-guard.sh` (3 pass, 0 fail).
- Pre-push gate: `validate.sh` (411 pass, 0 fail).

## Lessons Learned (For Future Agents)

- Markdown instruction documents should be verified for key structural sections and mandatory frontmatter rather than brittle line-by-line prose extraction. Filesystem/installer side effects remain the highest-value test targets.
