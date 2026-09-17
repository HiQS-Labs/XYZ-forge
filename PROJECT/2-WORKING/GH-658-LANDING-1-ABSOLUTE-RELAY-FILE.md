---
title: "GH-658: Containment allowlist stores the ABSOLUTE relay_file path — worktree-relative porcelain can never match it, so every instructed relay-file edit trips exit-6 (root cause of #654)"
status: Active
created: 2026-09-16
updated: 2026-09-16
owner: operator (via /express)
gh_issue: 658
source: https://github.com/HiQS-Labs/XYZ-forge/issues/658
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): Containment allowlist stores the ABSOLUTE relay_file path — worktree-relative porcelain can never match it, so every instructed relay-file edit trips exit-6 (root cause of #654)
roadmap_exempt: true
---

# GH-658 — Containment allowlist stores the ABSOLUTE relay_file path — worktree-relative porcelain can never match it, so every instructed relay-file edit trips exit-6 (root cause of #654)

## Status

| What was just completed | What's next |
|---|---|
| Fix qualified for /express; regression suite test/gh654-offlane-log.sh registered (green asserted at landing, Step 7; receipt in TESTS-RESULTS/) | Reconcile promotes this doc when issue #658 closes |

## Acceptance Criteria

- [x] Regression suite test/gh654-offlane-log.sh registered as the landing gate (Step 7 refuses to land unless it is green; the TESTS-RESULTS receipt records the run — express-suite, not the full pre-push gate).
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite, this doc, and the
  CHANGELOG entry moved as one motion; consult the .tick express-fired event for the
  run's receipts. Operator-supplied summary: Containment allowlist: normalize the Python shims' ABSOLUTE relay_file to root-relative before rtl_init and in the offlane mirror — the instructed relay-file edit can now match worktree-relative porcelain instead of deterministically tripping exit-6 (#654 root cause)
