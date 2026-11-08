# Plan draft: #775 umbrella: broken or fragile releases_app call sites (10days, standup, marathon-triage, jog_run, pdda)

> draft; preflight and independent plan QA outstanding

- Request: `gh-775-c3cda8ebdc02` (tick `slot_033`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 50/50/50/70
- Capture doc: PROJECT/1-INBOX/GH-775-UMBRELLA-BROKEN-OR-FRAGILE.md (sha256 dfecb54170d4a0674441ec4a57ceadb9ddf9af0bc934315531e8bec400f201f4)
- Issue sha256: c3cda8ebdc02482d5a9d57f1c4290f82fd830043ab472fc52512e9413b29e52b (updated 2026-10-22T13:50:19Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-775-UMBRELLA-BROKEN-OR-FRAGILE.md:L61 (Phase 0 — Explore & scope)_

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.

_Source: PROJECT/1-INBOX/GH-775-UMBRELLA-BROKEN-OR-FRAGILE.md:L18 (frontmatter goal)_

TODO: one-paragraph statement of what "done" looks like for this idea.

_Source: codex-authored (codex-authored)_

Verify the current status of issue #775 and each reported releases_app call site before identifying remaining fixes.

_Source: codex-authored (codex-authored)_

Correct confirmed invalid commands and references, and resolve the vendored installation path for roadmap repoint.

_Source: codex-authored (codex-authored)_

Investigate whether jog schema initialization persists during dry runs and whether the PDDA list call uses the intended repository root.

## Acceptance criteria

_Source: issue#775:L12 (Acceptance)_

- Every box is checked, or struck through with a reason.
- Each fixed call site is exercised once in a test or a dry run.


🤖 Generated with [Claude Code](https://claude.com/claude-code)

_Source: PROJECT/1-INBOX/GH-775-UMBRELLA-BROKEN-OR-FRAGILE.md:L50 (Acceptance)_

- Every box is checked, or struck through with a reason.
- Each fixed call site is exercised once in a test or a dry run.


🤖 Generated with [Claude Code](https://claude.com/claude-code)

_Source: codex-authored (codex-authored)_

Every issue checklist item is addressed or struck through with a reason.

_Source: codex-authored (codex-authored)_

Each fixed call site is exercised in a test or dry run.

## Open questions

_Source: codex-authored (codex-authored)_

Which reported call sites have already been fixed or changed since the audit?

_Source: codex-authored (codex-authored)_

Does schema initialization persist outside perform_write, including during dry runs?

_Source: codex-authored (codex-authored)_

Does the PDDA list call always run from PDDA_REPO_ROOT?

## Write set

- `utils/py/releases_app.py` (issue#775:L1)
- `PROJECT/1-INBOX/GH-768-RELEASES-APP-AUDIT.md` (issue#775:L3)
- `skills/3-weekly/10days/SKILL.md` (issue#775:L5)
- `skills/1-hourly/standup/collect.sh` (issue#775:L6)
- `utils/py/jog_run.py` (issue#775:L8)
- `utils/pdda/pdda.sh` (issue#775:L10)

## Unresolved file names

- none

## Contract probes

- none
