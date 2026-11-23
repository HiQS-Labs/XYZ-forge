# GH-1356 Batch 2 — first delivered candidate (agent-assisted)

## Status

#1287 is independently approved and gate-green; PR publication follows. No merge or promotion. Other batch targets remain unexecuted. #1296 already has PR #1324; #1344 already has partial merged PR #1350. Do not replay their old queue rows blindly. #1295 remains a prerequisite before factory-generated packet dispatch.

## Outcome and evidence

Agy built the campaign-tooling fix at 99aa9e262; Codex independently approved in the native Marathon relay. Gate initially failed under Python 3.9, then all 21 tests passed under existing Python 3.13 via jog retry-gate, without rebuilding. Native portable approval/gate evidence is under the sibling GH-1287 jog directory. This directory retains failed run and retry logs plus manual replay provenance.

Manual replay reuses the existing Tracker on all 10,000 retained events. Baseline control has 2,302 usage signatures and no streak-threshold crossing; candidate has 23 usage signatures, batch stop at event 500 and streak threshold at 1,892. See replay.json and provenance.jsonl. No new test or gate machinery.

## Novel paths and limits

Actual path: primary proposal-row reuse and checkpoint; Jog admission; Agy isolated build; independent Codex review; red gate; resume and successful gate-only retry; portable receipt publication. No-row pickup was NOT exercised. No cap stall or relay-receipt-tail recovery was manufactured or exercised. This does not establish a new autonomous supervisor capability beyond Jog/Marathon.

Agent repairs: primary pin, acceptance block then explicit checkbox formatting deviations (2 admission rounds), dependency installation then interpreter correction (2 environment rounds), explicit retry reviewer flags. Publication needed a human authorization clarification; preserve original failed setup as orchestration failure, not a machinery verdict. Built-in recovery: trunk branch guard, worktree containment, durable resume and gate-only retry. No caps raised or acceptance weakened.

The retry result omitted base_branch and Jog parked without creating a PR; publish against development explicitly. No-row >=3 pickup, full batch execution, receipt-tail recovery, hosted checks and landing remain outstanding. No unattended qualification claim. #1358/#1359/#1360 are unstarted intake only.
