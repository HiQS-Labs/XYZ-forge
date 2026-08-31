---
title: RELEASES-PREVIEW draft cards render before active cards
status: Proposed (1-INBOX — not yet active)
created: 2026-08-25
owner: noel
gh_issue: 254
source: https://github.com/HiQS-Labs/XYZ-forge/issues/254
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
reported_from: aegis-sleuth-slack-bot
harness_commit: b051cab4
non_goals:
  - Reordering shipped/cut history (the left rail is correct)
  - Any change to auto-scroll behavior
goal: >
  Within the open bucket of the RELEASES-PREVIEW rail, active releases sort
  before draft releases; drafts go to the back of the line. Deterministic
  regardless of DB insertion order.
---

# GH-254 — RELEASES-PREVIEW draft cards render before active cards

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Symptom
Draft release cards render before active cards in RELEASES-PREVIEW.html; drafts should move to the back of the line.

## Environment
- **Observed from:** `aegis-sleuth-slack-bot` (vendored `.xyz/`)
- **Harness commit:** `b051cab4`
- **Worker/CLI:** n/a (baked HTML exporter)
- **Runtime:** Python — `utils/timeline/export_timeline.py` (label `runtime:python` absent in this repo at filing time; not created per skill guardrail)
- **Sandbox:** off

## Reproduction
1. Ledger with two draft releases (no target date, no version, low DB ids) and several active releases (also no target date).
2. Run `utils/timeline/export_timeline.py --preview RELEASES-PREVIEW.html`.

**Expected:** active cards first in the open bucket, drafts last.
**Observed:** drafts render ahead of actives — the sort key `(1, target or "9999-12-31"), version or ""` never consults `status` inside the open bucket, so tied rows keep DB insertion order (stable sort).
**Frequency:** every time (deterministic).

```text
rows.sort(key=lambda r: (
    (0, r[5] or r[4] or "") if r[3] in ("shipped", "cut") else (1, r[4] or "9999-12-31"),
    r[1] or "",
))
```

## Impact
Display order only; not blocking. Active work is not the first open card a reader sees. Workaround: none needed (cosmetic).

## Phase 0 — Diagnose & scope
> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [ ] Reproduce it in the intake repo (not just in the reporting repo)
- [ ] Locate the responsible script/path — name the concrete write-set (`utils/timeline/export_timeline.py` sort key)
- [ ] Decide fix vs. guard-and-document; reuse an existing code path before adding one (`/ponytail`)
- [ ] Set/correct the triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [ ] The repro is confirmed from the report, not assumed
- [ ] A regression test covers the failure path before the fix lands
- [ ] The fix composes with the existing harness rather than adding a parallel path
