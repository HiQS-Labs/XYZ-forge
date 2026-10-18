---
gh_issue: 1060
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1060
title: "skills: add review-pr-xyz (claim-validated PR review) and rename review-code → review-code-xyz"
status: Complete
created: 2026-10-14
updated: 2026-10-18
owner: operator
goal: "PR review checks the PR's claims before its code, and the local and PR review skills each have one job."
doc_type: feature
related:
  - PROJECT/3-COMPLETED/GH-778-FEAT-REVIEW-CODE-AND-REVIEW-PR-GROUND-TRUTH-CODE-REVIEW-SKIL.md
effort: 2
complexity: 2
risk: 1
phases: 1
---

# GH-1060 — review-pr-xyz, and review-code becomes review-code-xyz

## Status

| What was just completed | What's next |
|---|---|
| Skill split implemented; affected suites green. | PR open against development; after merge, refresh deployed copies via Skills Army HQ and publish to XYZ-mini with `/push-downstream`. |

## Why

`review-code` reviewed both local diffs and GitHub PRs. PR review needs a step local review does
not: checking that the PR's claims are true before reviewing the code. A PR can implement its
description perfectly and still be wrong to merge, because the bug does not reproduce, the linked
issue asks for something else, or the change already landed.

## Decisions (operator, 2026-10-14)

- `review-pr-xyz` owns PR review. `review-code-xyz` keeps local diffs and drops `--pr`.
- `review-pr-xyz` is report-only: no workhorse/unstuck fix loop, never pushes, approves or merges.
- Clean rename, no alias stub. XYZ-mini drops `skills/review-code` on the next publish (managed entry).
- Keep the three names `review-xyz`, `review-code-xyz`, `review-pr-xyz`; each description says when to use which.

## What changed

- `skills/2-daily/review-code` → `skills/2-daily/review-code-xyz`; PR mode replaced by a handoff.
- New `skills/2-daily/review-pr-xyz/` (SKILL.md + install.sh). Phase 1 claim validation is new;
  Phases 2–4 reuse review-code-xyz's definitions by reference, not by copy.
- Repointed: Skills Index (plus the missing `daily-planner` row; count now matches disk),
  `utils/py/xyz_mini_sync.py` manifest, `mini/README.md`, `review-xyz` description.
- Suites: `gh778` and `gh798` repointed and their 2-daily count assertion now derives from disk
  (it was hard-coded and already red on development); `gh589` expects twelve published skills.
  No new suites (GH-831).

## Acceptance

- [x] `ls -d skills/*/review-code` is empty; both new skills have valid frontmatter.
- [x] No live reference to `skills/*/review-code/` or `name: review-code` remains (historical docs untouched).
- [x] `test/gh778-review-code-skill.sh`, `test/gh798-status-skill.sh`, `test/gh306-registry-bidirectional.sh`, `test/gh589-xyz-mini-sync.sh` pass.

## Operator-authorized assertion trim

Removed nine newly added prose/packaging assertions from gh778; retained rename and handoff repairs, obsolete-folder absence and existing checks. gh589 publication-output assertion and gh798 maintenance are unchanged. gh778 now25pass0fail; recreating the obsolete folder produces a witnessed failure. New skill packaging, routing, claim-first and report-only instructions were reviewed manually, with limitations recorded under TESTS-RESULTS/2026-10-14+GH-1060/assertion-trim/. No skill/runtime behavior changed.
