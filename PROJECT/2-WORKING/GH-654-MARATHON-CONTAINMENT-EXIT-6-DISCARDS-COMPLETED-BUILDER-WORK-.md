---
title: "GH-654: Marathon containment exit-6 discards completed builder work; rtl_worktree_end records no off-lane path list — blocks GH-648 phase p1 (2/2 codex turns)"
status: Active
created: 2026-09-16
updated: 2026-09-16
owner: operator (via /express)
gh_issue: 654
source: https://github.com/HiQS-Labs/XYZ-forge/issues/654
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): Marathon containment exit-6 discards completed builder work; rtl_worktree_end records no off-lane path list — blocks GH-648 phase p1 (2/2 codex turns)
---

# GH-654 — Marathon containment exit-6 discards completed builder work; rtl_worktree_end records no off-lane path list — blocks GH-648 phase p1 (2/2 codex turns)

## Status

| What was just completed | What's next |
|---|---|
| Fix qualified for /express; regression suite test/gh654-offlane-log.sh registered (green asserted at landing, Step 7; receipt in TESTS-RESULTS/) | Reconcile promotes this doc when issue #654 closes |

## Acceptance Criteria

- [x] Regression suite test/gh654-offlane-log.sh registered as the landing gate (Step 7 refuses to land unless it is green; the TESTS-RESULTS receipt records the run — express-suite, not the full pre-push gate).
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite, this doc, and the
  CHANGELOG entry moved as one motion; consult the .tick express-fired event for the
  run's receipts. Operator-supplied summary: rtl.worktree_end now names the off-lane candidates (and the allowlist) to stderr before the bash verdict destroys the worktree — GH-654's verdict-without-evidence gap, fixed Python-side
