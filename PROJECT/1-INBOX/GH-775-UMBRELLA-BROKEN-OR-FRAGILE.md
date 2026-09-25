---
gh_issue: 775
source: https://github.com/HiQS-Labs/XYZ-forge/issues/775
title: "umbrella: broken or fragile releases_app call sites (10days, standup, marathon-triage, jog_run, pdda)"
status: Proposed (1-INBOX — not yet active)
created: 2026-09-23
owner: unassigned
doc_type: bugfix
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - TODO: what this explicitly is NOT (scope boundary).
related:
  - TODO: related files/docs, if any.
goal: >
  TODO: one-paragraph statement of what "done" looks like for this idea.
---

## Key concepts

- TODO: 2-4 bullets on what this idea concretely is and why it matters.

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# umbrella: broken or fragile releases_app call sites (10days, standup, marathon-triage, jog_run, pdda)

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `HiQS-Labs/XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Umbrella: broken or fragile calls to `releases_app.py` across the repo

Found by the #768 caller sweep (Appendix A1 of `PROJECT/1-INBOX/GH-768-RELEASES-APP-AUDIT.md`). Each item is small; batch them into one PR.

- [ ] `skills/3-weekly/10days/SKILL.md:206,231` calls `roadmap show <N>`, which does not exist. At :206 the failure is hidden by `2>/dev/null || true`.
- [ ] `skills/1-hourly/standup/collect.sh:971,1010` suggests `releases_app.py ship {v}`. `ship` requires `--gid` and takes no positional argument (`releases_app.py:6375-6379`).
- [ ] `skills/2-daily/marathon-triage/SKILL.md:283` cites `releases_app.py:4901` for `marathon add --tracking-issue`; the definition is now at `:6420`. Prefer a symbol reference over a line number.
- [ ] `utils/py/jog_run.py:1247` hardcodes the `utils/py/releases_app.py` path for `roadmap repoint`, so it breaks on vendored `.xyz/` installs. Use `resolve_tool` (already imported at :36).
- [ ] Verify: `jog_run.py:1612` (`--dry-run`) and `:1666` run `_ensure_jog_schema` (DDL plus `INSERT INTO schema_migrations`) outside `perform_write`. Confirm whether anything persists; this is related to #552.
- [ ] Verify: `utils/pdda/pdda.sh:847` runs `list` with no `--root` and no `cd`. Confirm the cwd always equals `PDDA_REPO_ROOT`, or pass `--root`.

## Acceptance
- Every box is checked, or struck through with a reason.
- Each fixed call site is exercised once in a test or a dry run.


🤖 Generated with [Claude Code](https://claude.com/claude-code)

## Why

TODO: why this matters now -- what prompted it, what breaks or slows without it.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.

## Merge evidence

- PR #776 merged 2026-09-24 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
