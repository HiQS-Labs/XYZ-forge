---
gh_issue: 1126
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1126
title: "Idle-kill classification can read the network probe before it finishes (gh610 idle-unknown vs timeout-unclassified)"
status: Active
created: 2026-10-18
updated: 2026-10-18
owner: claude
goal: "Make the idle-kill label deterministic by removing the sampler/classifier race, without weakening the classifier or the gh610 integration coverage"
doc_type: fix
effort: 1
complexity: 2
risk: 2
phases: 1
fix_probes:
  - "grep -q '_sample_lock' utils/py/turn_diagnostics.py"
---

# GH-1126 — idle-kill label race between the sampler thread and classify()

Branch `fix/XYZ-forge-gh1126-gh610-idle-label-2026-10-18` off `development@e93214fe`.

## Status

| What was just completed | What's next |
|---|---|
| Root cause traced from the failed hosted run's own transcript; plan written | Codex plan QA → implement → focused suites + manual race control → final QA → PR → merge on green CI |

## Observed failure (confirmed, not hypothesis)

Hosted run 39085003007 at 4a042b9f: `test/gh610-claude-subscription.sh::test_real_probe_and_consult_dispatch`, idle mode (`CONSULT_IDLE_S=1`), failed with this transcript:

> `PARTIAL — killed at idle threshold [timeout-unclassified] … [timeout-unclassified: live sampling never established a safe idle window for the network probe [cpu=0.00s/s, samples=3, worktree-progress=no]]`

## Root cause

- `TurnDiagnostics._sample()` (`utils/py/turn_diagnostics.py:383-422`) runs on the sampler thread. It appends the sample **first** (`:393`). It then runs `pgrep` (`_security_dialog_present`) and `_newest_mtime`. Only then, on the sample where `len(samples) >= IDLE_MIN_SAMPLES (3)`, `cpu_ratio < 0.15` and there is no progress, does it set `_network_probe_attempted = True` and call `_network_state` (`lsof`, up to a 5 s timeout, `:146-167`). The result lands in `_network_state_observed` only when `lsof` returns.
- `consult.wait_with_idle_bound` (`utils/py/consult.py:296-321`) polls every 2 s on the **main** thread. Once `idle_seconds()` answers, which needs 3 samples (`:468-488`), and the answer is ≥ the threshold, it calls `diag.classify()` immediately. `classify()` (`:490-551`) reads `_network_state_observed`, and `None` maps to "never established a safe idle window".
- The failing transcript matches the window between those two threads exactly:
  - `samples=3` (the probe-triggering sample has been appended);
  - `cpu=0.00` and `worktree-progress=no` (every probe precondition is true);
  - yet the observation is `None`, so the probe had not finished.
- A loaded hosted runner makes `pgrep`/`lsof` slower, which widens the window. That is why only the hosted run failed. One alternative is an exception swallowed by `_loop` (`:425-428`) on that sample. It also yields "probe not completed for sample 3", and the fix below covers that timing too, except the exception itself.
- **Scope:** every consult idle kill is affected, not just the test. A live idle advisor can be labelled `timeout-unclassified` when the evidence for `idle-unknown` or `idle-in-flight` was a few seconds from landing. The turn shims (`agy/claude/codex/commandcode/deepseek-turn.py`, `review_xyz.py`) call `classify()` only after `diag.stop()`. If `stop()` joins the thread, they are not affected; verify that during implementation.

## Fix (smallest)

- `TurnDiagnostics` gains `self._sample_lock = threading.Lock()`.
- `_sample()` holds the lock for its whole body, so a sample, including its one-shot probe, is atomic with respect to readers.
- `classify()` acquires the same lock before reading state. A classifier called mid-sample waits for that sample to finish, at most the `lsof` 5 s timeout plus `ps`/`pgrep`. A call between samples does not wait.
- The classifier's decisions, thresholds and labels are unchanged (#1126: do not weaken it). `idle_seconds()` is unchanged.
- No change to `consult.py`, to the gh610 assertion, or to any test file.

Rejected alternatives:
- (a) Loosen gh610 to accept either label. That hides a real product race.
- (b) Make `idle_seconds()` return `None` while a probe is in flight. That delays the kill but couples the kill decision to probe timing; the lock keeps them independent.
- (c) Move the probe out of the sampler. That is larger and changes when the probe runs.

## Verification

- Manual race control, `TESTS-RESULTS/2026-10-18+GH-1126/race-control.py.txt` with `.log.txt`, using the real module:
  - Stub `_network_state` with a seam that sleeps 1.5 s and returns `"none"`.
  - Stub the CPU, dialog and mtime seams to idle values.
  - Run `_sample()` three times, the third in a thread.
  - Call `classify()` 0.2 s into the third sample.
  - **Red control:** on the base commit's module, the label is `timeout-unclassified` with "never established".
  - **Fixed:** the label is `timeout-idle-unknown`, and `classify()` waited at least about 1.2 s.
  - A second case calls `classify()` with no sample in flight and checks it returns without waiting.
- Existing suites:
  - The classifier-label suites `test/gh390-timeout-attribution.sh`, `test/gh492-idle-kill.sh`, `test/gh648-l1-turn-termination.sh` and `test/gh648-l3-consult-cap.sh`.
  - `test/gh610-claude-subscription.sh`, run unsandboxed (real process tree, real `lsof`).
  - `test/gh648-l4-285-revalidate.sh`, for shim termination.
- **Acceptance:**
  - The race control is red on base and green on the fix.
  - All listed suites are green.
  - No new test file or case (GH-831).
  - Pre-push gate on the final commit (it routes full; it is core harness code).

## Non-goals

- The classifier thresholds, the probe implementation or its `lsof` failure semantics (an `lsof` warning still means unclassified).
- `consult.py`.
- The turn shims, unless verification shows `stop()` does not join.
- Any new test case. A deterministic in-suite race case would need the operator's per-case approval; offer it as a carry-over.

## Risk / rollback

- **Worst case:** a classifier called mid-sample blocks up to about 5 s on an `lsof` timeout. That only happens on the kill path, which is already terminating.
- **Rollback:** revert the single commit.
