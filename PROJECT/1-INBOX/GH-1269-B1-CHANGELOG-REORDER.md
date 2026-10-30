---
title: merge-cleanup B1 CHANGELOG repair reorders existing same-date sections
status: Proposed (1-INBOX — not yet active)
created: 2026-10-30
owner: noelsaw1
gh_issue: 1269
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1269
doc_type: bugfix
complexity: 2
risk: 3
effort: 2
phases: 1
ratings_provisional: true
reported_from: LTVera-Pandas
harness_commit: e305cbf3
non_goals:
  - Changing the GH-789 two-repair budget or the history-preservation refusal itself
  - Resolving genuinely divergent same-heading additions (those still hand off)
related:
  - GH-789 (bounded repairs and the additive changelog boundary)
goal: >
  A B1 additive CHANGELOG resolution prepends the PR's new dated sections and keeps the
  integration branch's existing history byte-for-byte, including the order of same-date
  sections, so a repair recorded `resolved` passes B1's own history check on the next attempt.
---

# GH-1269 — merge-cleanup B1 CHANGELOG repair reorders existing same-date sections

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Symptom

The B1 additive CHANGELOG resolution reorders the integration branch's existing same-date
sections and records the repair `resolved`. The next B1 attempt refuses that output ("changelog
preamble or existing history changed") and hands off, which uses up the PR's two-repair budget.

## Environment
- **Observed from:** `LTVera-Pandas` (vendored `.xyz/` at `017b1425`; `merge_cleanup.py` from the deployed Skills Army copy)
- **Harness commit:** `e305cbf3` (intake repo at report time)
- **Worker/CLI:** merge-cleanup (`merge_cleanup.py --execute`, B1 rung)
- **Runtime:** Python — matches the `runtime:python` issue label
- **Sandbox:** off

## Reproduction
1. LTVera PR #874 (one new 2026-10-30 section) conflicts with `development` `3c936bea`, whose `CHANGELOG.md` holds six 2026-10-29 sections added by three parallel PRs.
2. `merge_cleanup.py --primary <landing clone> --prs 870,874 --execute`: B1 attempt 1 on head `f57f2540` resolves and pushes merge commit `497ca1e8`, recorded `resolved`.
3. On the next run, B1 attempt 2 on head `497ca1e8` hands off.

**Expected:** `497ca1e8`'s CHANGELOG = the GH-818 section + development's history unchanged.
**Observed:** the six 2026-10-29 sections are reordered (development order 867-QA, 867, 866-typing, 866, 866-resumed, 776 → output order 776, 866, 867, 866-typing, 866-resumed, 867-QA); bodies intact. Attempt 2: `outcome: handoff`, `reason: CHANGELOG handoff: changelog preamble or existing history changed`.
**Frequency:** once so far; expected to be deterministic for multi-section same-date history.

```text
attempts[0]: rung=B1 head=f57f2540 outcome=resolved commit=497ca1e8
attempts[1]: rung=B1 head=497ca1e8 outcome=handoff reason="CHANGELOG handoff: changelog preamble or existing history changed"
conflict_files: CHANGELOG.md, RELEASES-PREVIEW.html, releases.db, releases.sql
```

## Impact
LTVera PR #874 needs an operator-approved third, CHANGELOG-only repair. Any batch landing with
several same-date CHANGELOG sections from parallel PRs is exposed. No data loss: bodies are kept
and the handoff stopped the reordered history from landing.

## Phase 0 — Diagnose & scope
> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [ ] Reproduce it in the intake repo (not just in the reporting repo)
- [ ] Locate the responsible script/path — name the concrete write-set (likely the additive-section merge under `skills/2-daily/merge-cleanup/scripts/`)
- [ ] Decide fix vs. guard-and-document; reuse an existing code path before adding one (`/ponytail`)
- [ ] Set/correct the triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [ ] The repro is confirmed from the report, not assumed
- [ ] An existing suite, or a recorded manual check, covers the failure path before the fix lands (no new test suites: `AGENTS.md` *No new tests*, GH-831)
- [ ] The fix composes with the existing harness rather than adding a parallel path
