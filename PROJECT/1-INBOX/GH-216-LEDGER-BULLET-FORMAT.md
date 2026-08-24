---
title: marathon-plan.sh ledger parser rejects link-style ROADMAP.md bullets
status: Proposed (1-INBOX — not yet active)
created: 2026-08-24
owner: noel
gh_issue: 216
source: https://github.com/HiQS-Labs/XYZ-forge/issues/216
doc_type: bugfix
complexity: 2
risk: 4
effort: 2
phases: 1
ratings_provisional: true
reported_from: LTVera-Pandas
harness_commit: 46075c9
non_goals:
  - Deciding LTVera-Pandas's ROADMAP.md format is wrong and should change to match the parser
  - Patching the parser without a maintainer call on the intended one-true-format
related:
  - GH-215 (same reconciler chain, two mechanical path-resolution bugs, kept separate — already fixed locally)
goal: >
  marathon-plan.sh's ledger parser either accepts link-style ROADMAP.md bullets (this repo's actual
  format) or the required bold-bullet / "Deferred · vision" format is documented as a hard
  constraint on consuming repos before they rely on the reconciler.
---

# GH-216 — marathon-plan.sh ledger parser rejects link-style ROADMAP.md bullets

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet.

## Symptom
`.xyz/utils/py/wave_reconcile.py` (the post-PR-merge reconciler) never completes successfully in
LTVera-Pandas: it always dies at the `marathon-plan.sh` step, rolling back the entire
reconciliation run (docs, ROADMAP, releases.db, dashboards), because that script's ledger parser
doesn't recognize this repo's actual `ROADMAP.md` bullet/heading style.

## Environment
- **Observed from:** `LTVera-Pandas`
- **Harness commit:** 46075c9 (per `.xyz/VERSION`, vendored 2026-08-24T02:04:13Z)
- **Worker/CLI:** n/a — invoked via `wave_reconcile.py` → `bash .xyz/utils/marathon-plan.sh`
- **Sandbox:** off

## Reproduction
1. In LTVera-Pandas, run `python3 .xyz/utils/py/wave_reconcile.py --pr <N ...> --dry-run` (with GH-215's path fixes already applied locally).
2. It reaches `bash .xyz/utils/marathon-plan.sh --dry-run`, which exits 3: `marathon-plan: no ledger items parsed (is '## Ledger' present?)`.
3. Root cause, traced to `.xyz/utils/py/_marathon_plan.py`'s `_parse_ledger()` (~line 500-533): it only matches bullets styled `^- \*\*` (bold-title) and only recognizes `### <heading>` blocks whose text is in `SECTIONS = ["Queue / parked intake", "In progress", "Completed", "Deferred · vision"]`. LTVera-Pandas's `ROADMAP.md` uses `- [Title](path) — ...` markdown-link bullets, and its fourth section heading is a bare `### Deferred` (no "· vision"). Result: zero bullets match across every section, so the item count is 0 and the script exits 3 — even though the `## Ledger` heading itself is present, making the exit message ("is '## Ledger' present?") misleading about the actual cause.

**Expected:** either the parser accepts this bullet/heading style, or the required format is documented so repos know to conform before depending on the reconciler.
**Observed:** exit 3, full rollback, every time.
**Frequency:** every time, both `--dry-run` and live, across 8 different merged PRs tested in one session.

```text
wave-reconcile:   -> marathon-plan.sh --dry-run
wave-reconcile: ERROR — Subprocess 'marathon-plan.sh --dry-run' failed with exit 3:
marathon-plan: no ledger items parsed (is '## Ledger' present?)
wave-reconcile: Rolling back all uncommitted mutations...
```

## Impact
Blocks the reconciler from ever completing successfully in LTVera-Pandas (and presumably any other
consuming repo using link-style ledger bullets) until resolved. Not patched locally — this is a
format/design call (widen the parser vs. mandate the bold-bullet format), not a safe mechanical fix
like GH-215's two bugs.

## Phase 0 — Diagnose & scope
> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [ ] Decide: widen `_parse_ledger()`'s bullet regex (accept `^- \[.+\]\(.+\)` in addition to `^- \*\*`) and `SECTIONS` list (accept bare `Deferred` in addition to `Deferred · vision`), OR document the bold-bullet/`Deferred · vision` format as a hard requirement for `ROADMAP.md` in consuming repos
- [ ] If widening the parser: also fix the exit-3 message, which currently blames a missing `## Ledger` heading when the real cause can be bullet/heading-name mismatch under a heading that IS present
- [ ] Set/correct triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [ ] The repro is confirmed from the report, not assumed
- [ ] A regression fixture (link-style `ROADMAP.md`) covers the failure path before the fix lands
- [ ] The fix composes with the existing harness rather than adding a parallel path
