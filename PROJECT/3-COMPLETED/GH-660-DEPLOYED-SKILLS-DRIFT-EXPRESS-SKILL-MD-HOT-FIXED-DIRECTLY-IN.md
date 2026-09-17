---
title: "GH-660: Deployed-skills drift: express SKILL.md hot-fixed directly in the vendored collection (git-pulse-sync) instead of re-vendoring from canonical skills/express — deployed copy missing GH-592 resume recipe"
status: Complete
created: 2026-09-16
updated: 2026-09-16
owner: operator (via /express)
gh_issue: 660
source: https://github.com/HiQS-Labs/XYZ-forge/issues/660
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): Deployed-skills drift: express SKILL.md hot-fixed directly in the vendored collection (git-pulse-sync) instead of re-vendoring from canonical skills/express — deployed copy missing GH-592 resume recipe
---

# GH-660 — Deployed-skills drift: express SKILL.md hot-fixed directly in the vendored collection (git-pulse-sync) instead of re-vendoring from canonical skills/express — deployed copy missing GH-592 resume recipe

## Status

| What was just completed | What's next |
|---|---|
| Fix qualified for /express; regression suite test/gh660-skill-drift.sh registered (green asserted at landing, Step 7; receipt in TESTS-RESULTS/) | Reconcile promotes this doc when issue #660 closes |

## Acceptance Criteria

- [x] Regression suite test/gh660-skill-drift.sh registered as the landing gate (Step 7 refuses to land unless it is green; the TESTS-RESULTS receipt records the run — express-suite, not the full pre-push gate).
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite, this doc, and the
  CHANGELOG entry moved as one motion; consult the .tick express-fired event for the
  run's receipts. Operator-supplied summary: GH-660 drift guard: skill_drift_check.py compares a vendored collection's SKILL.md files against canonical skills/ and names every divergence (drifted/ok/unrecognized, --json) so vendors get re-vendored instead of hand-patched; suite covers drift/clean/extra/mutation paths
