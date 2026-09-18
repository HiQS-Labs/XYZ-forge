---
title: "GH-693: Lessons Learned: make the capture-doc section optional (highly recommended), not a promotion gate"
status: Complete
created: 2026-09-18
updated: 2026-09-18
owner: operator (via /express)
gh_issue: 693
source: https://github.com/HiQS-Labs/XYZ-forge/issues/693
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): Lessons Learned: make the capture-doc section optional (highly recommended), not a promotion gate
---

# GH-693 — Lessons Learned: make the capture-doc section optional (highly recommended), not a promotion gate

## Status

| What was just completed | What's next |
|---|---|
| Fix qualified for /express; regression suite test/gh693-lessons-learned-advisory.sh registered (green asserted at landing, Step 7; receipt in TESTS-RESULTS/) | Reconcile promotes this doc when issue #693 closes |

## Acceptance Criteria

- [x] Regression suite test/gh693-lessons-learned-advisory.sh registered as the landing gate (Step 7 refuses to land unless it is green; the TESTS-RESULTS receipt records the run — express-suite, not the full pre-push gate).
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## What changed

Operator decision (#691 trigger): `## Lessons Learned (For Future Agents)` is **highly recommended,
never a promotion gate**. `utils/py/wave_reconcile.py` keeps the one detector
(`validate_lessons_learned`) and routes it through one emitter (`warn_lessons_learned`,
`WARN_MARKER`) at the three former refusal points — explicit landing (`die` exit 5 since GH-165),
`--pre-merge` doc contract (exit 5 since GH-496), and the catch-up skip-and-report (GH-684).
Frontmatter schema stays mandatory. Plan (with the dated requirement history and blast radius) and
agy's PASS review: `relay-system/2026-09-18/gh693-plan.md`, `gh693-plan-qa.md`.

Blast radius: the next hosted run promotes GH-505/509/609/642 with WARN lines and #691 closes
itself; `--pre-merge` has no production caller; 14 vendored `.xyz/` copies keep the strict reconciler
until `xyz-sync.sh update`; reversibility Easy (one revert; docs promoted meanwhile stay promoted).

## Lessons Learned (For Future Agents)

- A reflection field the reconciler cannot evaluate must not be a lifecycle gate: from GH-165 to
  GH-693 it red-lit hosted runs and, after GH-684, re-reported the same four docs on every run.
  Warn loudly, promote anyway — the express scaffold and the WARN in every log keep the habit alive.
- The plan's enforcement inventory missed a third test surface (`test/gh421-auto-wave-reconcile.sh`,
  GH-684's in-process pins) and the reviewer graded the inventory complete anyway. `rg` the *tests*
  for the exit code and marker, not only the source for the function name.
- GH-684's skip-and-report shape (`SKIP_MARKER`, `skipped_issues`, hosted reporter parsing) is kept
  but now has no trigger; the next real backlog-doc defect class should re-arm it rather than add a
  parallel path. A lessons-less doc is now in the reconciler's ownership set, so its own planner
  drift is attributable (exit 6), no longer "pre-existing unrelated".
- Landed via the /express fast lane (GH-267) with operator-tunable bounds
  (`--max-files 12 --max-insertions 500 --allow-multi-subsystem`: 11 files / 420 insertions, most of
  it the plan thread and the suite); no hard refusal surface touched.
