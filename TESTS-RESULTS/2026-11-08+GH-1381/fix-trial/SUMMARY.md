# GH1381 fix trial

Setup/repair mode 1B, pinned unmerged flywheel 7c382a594057d2992b9dace28569adfd6130db00. Agent-assisted, not unattended qualification.

- Baseline red and fixed green: all three merge strategies, actual helper command captured at mocked GitHub boundary; real linked fixture and sentinel retained. No remote merge/deletion test performed.
- Existing focused suite: 205 tests passed in 139.017s on fixed code.
- Independent native Codex plan/final code QA: Approved, no blocking findings.
- Full normal push gate: 544s, 21:55:10–22:04:17Z (process 546.838s), exit 0, e55e27f70f20f08504e9cea097e7242fac30037c. All 405 registered suites plus Python/identity checks passed. Post-run full-clone identity unchanged and clean. This is local push evidence, not promotion qualification.
- One builder attempt, one full gate. Routine corrections: baseline focused run launched before changed files were copied; rerun correctly. Existing test virtualenv selected after system Python lacked requests. No bypass, cap increase, new credentials or second runner.
- Technical outcome: merge no longer requests branch/worktree deletion; explicit inventory teardown remains separate. Missing-worktree completeness UNKNOWN. No merge, deployment, restoration, retirement or Phase B performed.

Workflow feedback: existing start-task and native review override carried repair to publication; supplied T3 isolation and explicit preservation instruction override clone/retirement defaults. Pinned flywheel served as routing/continuation guidance, not a new executor. One trial does not establish unattended reliability. Usage unknown. Next action: parent observes hosted checks and reviews on exact published head; merge remains separately authorized.
