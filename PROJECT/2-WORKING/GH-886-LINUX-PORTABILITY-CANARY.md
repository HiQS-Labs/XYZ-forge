---
gh_issue: 886
source: https://github.com/HiQS-Labs/XYZ-forge/issues/886
title: "Linux portability canary: 3 advisory failures (gh425, gh478, gh153)"
status: active
created: 2026-09-28
updated: 2026-09-29
owner: XYZ Forge maintainers
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 1
non_goals:
  - Do not add new suites, registry entries, runners, or gate machinery
  - Do not change the macOS qualification boundary
related:
  - #822 first report
  - #854 stabilization window
  - #853 suite isolation
goal: >
  Land the three existing staging fixes through #854 Landing 2, then verify the Ubuntu canary and macOS qualification on development.
---

## Key concepts

- gh153 exporter JSON exceeded Linux single-argument size
- gh478 inherited EXIT trap blocks runaway-guard initialization
- gh425 canary lacked pytest dependencies

# Linux portability canary: 3 advisory failures (gh425, gh478, gh153)

## Status

| What was just completed | What's next |
|---|---|
| The three fixes are on `staging/stabilize-2026-10`; Ubuntu canary runs [36489248106](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36489248106) and [36643711275](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36643711275) each passed 411/411 with zero re-runs, including `gh153`, `gh478`, and `gh425`. | Carry the fixes through #854 Landing 2; on `development`, verify the next Ubuntu canary has no untracked failure and macOS qualification stays green, then close #886. |

## Idea

Fix the three tracked Ubuntu canary failures in their existing suites and dependency setup; confirm every registered canary suite passes on staging, while macOS qualification stays green.

## Why

The advisory Ubuntu canary stayed at 407/410 across two commits. The three failures were tracked in #822 and #886 and are already fixed on the staging branch; the remaining work is the Landing 2 merge and post-landing confirmation.

## Staging fixes and evidence

- `gh153-releases-sidebar-rollup.sh`: pass exporter JSON through a file so Linux's per-argument limit does not prevent the check from running.
- `gh478-runaway-guard.sh`: clear the inherited EXIT trap before initializing the guard in subshell cases.
- `canary-ubuntu` in `.github/workflows/ci.yml`: install Python test dependencies so `gh425-gate-provenance-pr.sh` can exercise its qualification path. The operator approved this workflow edit under #854 on 2026-09-28.

Before the fixes, the advisory canary reported 407/410 on `development` after #880 ([run 36452578120](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36452578120)). On staging after the fixes, the three named suites returned `rc=0`; runs 36489248106 and 36643711275 each reported 411/411 and zero re-runs. The #854 handoff owns the landing sequence and the final QA receipts. The canary is advisory; macOS remains the shipping qualification boundary.

## QA gate

- [x] On staging, the three suites and full Ubuntu canary pass without a re-run rescue (runs 36489248106 and 36643711275).
- [ ] After Landing 2, the next `development` canary has no untracked failure in these suites, and macOS qualification remains green.
- [ ] Close #886 only after the post-landing result is linked on the issue.

## Lessons Learned (For Future Agents)

An advisory canary still needs named failures and a follow-up. These three were visible in #822 before #886 supplied one owner and a verifiable exit condition.
