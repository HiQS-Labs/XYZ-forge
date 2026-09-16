---
title: "GH-645: merge-cleanup: ledger gate and reconcile fail in repos that vendor PRS tools under gitignored .xyz/"
status: Complete
created: 2026-09-16
updated: 2026-09-16
owner: operator (via /express)
gh_issue: 645
source: https://github.com/HiQS-Labs/XYZ-forge/issues/645
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): merge-cleanup: ledger gate and reconcile fail in repos that vendor PRS tools under gitignored .xyz/
---

# GH-645 — merge-cleanup: ledger gate and reconcile fail in repos that vendor PRS tools under gitignored .xyz/

## Status

| What was just completed | What's next |
|---|---|
| Fix qualified for /express; regression suite test/gh645-merge-cleanup-xyz-tools.sh registered (green asserted at landing, Step 7; receipt in TESTS-RESULTS/) | Reconcile promotes this doc when issue #645 closes |

## Acceptance Criteria

- [x] Regression suite test/gh645-merge-cleanup-xyz-tools.sh registered as the landing gate (Step 7 refuses to land unless it is green; the TESTS-RESULTS receipt records the run — express-suite, not the full pre-push gate).
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite, this doc, and the
  CHANGELOG entry moved as one motion; consult the .tick express-fired event for the
  run's receipts. Operator-supplied summary: merge-cleanup resolves vendored .xyz PRS tools via the primary and passes --force-local-reconcile only when advertised

## Post-hotfix QA (2026-09-16)

The Python lookup and advertised-flag tests pass, but conflict recovery retained a hardcoded
`clone/utils/releases-merge-resolve.sh` invocation. A consumer landing clone omits the
gitignored `.xyz/` tree. The added regression reaches this boundary and executes the selected
shell tool: the original hotfix refuses with exit 127; the follow-up resolves the primary's
vendored shell script and preserves `--root <landing clone>`. Surrounding ledger/Git operations
are mocked in this focused test; the existing Phase B suite exercises real ledger conflicts.

The follow-up is an obvious path fix using the existing resolver, so separate plan QA is
exempt under start-task's simple-change rule. Final independent Codex QA and the full local
gate remain required. Reversibility: Easy, confined to tool lookup and its regression.

Rating: 85/80/50/90, persisted through `roadmap rate`; a reproducible recovery blocker,
neutral appeal, small repair. Recent same-subsystem incidents include #623, #624, #629, and
#645 (September 2–16); these have different mechanisms, so a shared-root recurrence trend
is unknown. No operator override was present.

Evidence: `TESTS-RESULTS/2026-09-16+GH-645-qa/provenance.jsonl`.
Follow-up state: awaiting final QA and PR; the original express fix remains shipped.
