# GH-1051 normal full publication gate

Tested/published head: baf31e728ef28bec8d6e9260245e8b17521e2c38; full non-shallow disposable clone. No test files/cases/parameters were added. Native final QA was Approved, own issue round 1/3; this is not Forge relay-driver/provider attestation.

Attempt 1: 408/409, full push refused after 1073s. gh648-l4-285-revalidate.sh reproduced PermissionError/EPERM when its fixture signalled its own process group, both pooled and the gate's serial recheck. The unchanged focused existing suite passed with sandbox escalation.

Attempt 2: unchanged normal gate and branch push with require_escalated; 409/409, exit 0, 1551s. gh648 now passed. Two pooled fixtures (gh251-validate-pytest-skip.sh and agent-chorus-bridge.sh) passed the runner's built-in serial rechecks, which the runner classifies as contention. Two retry-ladder suites, 174.271s. No bypass, gate weakening or source repair. Raw red and green results are retained. This is draft hotfix publication evidence, not stable/main promotion evidence.

Runner-envelope confirmed identity, tracked tree, worktrees and driver lock unchanged during validation. The after-publication config records git push -u's expected own-branch tracking update, after the bracketed gate; no permission or credential change.

Development advanced from 0085ceee to b9f07ea5 through externally landed receipt files only; all 116 changed paths are TESTS-RESULTS or relay-system, and Pages/runtime code is unchanged. This session performed no merge. Draft PR #1053 targets development. Main's current workflow remains unchanged until a separately authorized promotion; no live dispatch/deployment or environment change occurred.

A later commit carries only this evidence and plan status. Do not relabel this full run as a run on that later carrier; verify workflow/code continuity and exact hosted carrier-head checks separately.
