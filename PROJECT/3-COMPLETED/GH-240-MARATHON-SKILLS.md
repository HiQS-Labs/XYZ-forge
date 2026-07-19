---
gh_issue: 240
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/240
title: "Add PDDA-compatible marathon triage and cleanup skills"
status: Shipped 2026-07-18
created: 2026-07-18
updated: 2026-07-18
owner: noel
doc_type: enhancement
effort: 2
complexity: 2
risk: 2
phases: 2
goal: >
  Make marathon triage and cleanup repo-owned, reproducibly installed Claude skills that preserve
  PDDA's canonical document lifecycle and require verified evidence before archiving marathon work.
related:
  - skills/marathon-triage/SKILL.md
  - skills/marathon-cleanup/SKILL.md
  - PROJECT/PDDA.md
---

# GH-240 · PDDA-compatible marathon skills

## Status

| What was just completed | What's next |
|---|---|
| Restored `marathon-triage` as a repo-owned skill, added evidence-driven `marathon-cleanup`, installed both Claude symlinks, and passed skill, shell, PDDA, and full repo validation. | No further work in GH-240; use the skills on the next triage or cleanup request. |

## Table of contents

- [Phase 1 — Repo ownership and installation](#phase-1--repo-ownership-and-installation)
- [Phase 2 — Evidence-driven cleanup](#phase-2--evidence-driven-cleanup)
- [Acceptance criteria](#acceptance-criteria)

## Phase 1 — Repo ownership and installation

- Restore the existing machine-only `marathon-triage` instructions under `skills/marathon-triage/`.
- Add self-locating, idempotent installers for both marathon skills.
- Replace the machine-only Claude skill directory with a symlink to the repo-owned source.

### QA gate

- Both `~/.claude/skills/<name>` entries resolve to the matching repo skill directory.
- Re-running either installer is a no-op success.

## Phase 2 — Evidence-driven cleanup

- Inventory active marathon plans and marathon bundle directories.
- Resolve every task to its canonical PDDA document and reconcile local status, frontmatter,
  GitHub issue/PR state, commits, and `CHANGELOG.md` evidence.
- Require positive completion evidence and no contradictory signal for every task before proposing a
  move to `PROJECT/3-COMPLETED/`.
- Default to audit-only; require explicit operator confirmation before moving files or updating
  lifecycle ledgers.

### QA gate

- Ambiguous, blocked, partial, or conflicting tasks prevent the parent marathon from moving.
- Approved moves use `git mv`, update terminal frontmatter/status text, and synchronize ROADMAP and
  CHANGELOG without inventing completion claims.
- `utils/pdda/pdda.sh run` remains the final document-hygiene gate.

## Acceptance criteria

- [x] `marathon-triage` is repo-owned and remains plan-only/non-mutating.
- [x] `marathon-cleanup` applies a documented evidence hierarchy and all-tasks-complete rule.
- [x] Both Claude settings entries are symlinks to this clone.
- [x] Both skill folders pass the skill validator.
- [x] Relevant shell syntax, installer, and PDDA checks pass.

## Verification

- Official skill validator: both skills valid (run with ephemeral `PyYAML` because the host Python
  environment does not include the validator's dependency).
- `bash -n` and ShellCheck: both installers clean.
- Installer live proof: both symlinks created and both installers passed an idempotent second run.
- File-scoped PDDA frontmatter, status-table, and hardcoded-path checks: clean.
- `./validate.sh`: 115/115 passed, including `python:test_python_layer.py` 15/15.
- Repo-wide `utils/pdda/pdda.sh run`: GH-240 clean; aggregate remains blocked by pre-existing,
  unrelated untracked GH-238 and Marathon Plan J document failures.
