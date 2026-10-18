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
| Plan QA r1 FAIL (R1 causal certainty, R2 caller scope/delay bound, R3 synchronized control) dispositioned in place | Codex plan QA r2 → implement → focused suites + manual race control → final QA → PR → merge on green CI |

## Observed failure (confirmed, not hypothesis)

Hosted run 39085003007 at 4a042b9f: `test/gh610-claude-subscription.sh::test_real_probe_and_consult_dispatch`, idle mode (`CONSULT_IDLE_S=1`), failed with this transcript:

> `PARTIAL — killed at idle threshold [timeout-unclassified] … [timeout-unclassified: live sampling never established a safe idle window for the network probe [cpu=0.00s/s, samples=3, worktree-progress=no]]`

## Root cause

- `TurnDiagnostics._sample()` (`utils/py/turn_diagnostics.py:383-422`) runs on the sampler thread. It appends the sample **first** (`:393`). It then runs `pgrep` (`_security_dialog_present`) and `_newest_mtime`. Only then, on the sample where `len(samples) >= IDLE_MIN_SAMPLES (3)`, `cpu_ratio < 0.15` and there is no progress, does it set `_network_probe_attempted = True` and call `_network_state` (`lsof`, up to a 5 s timeout, `:146-167`). The result lands in `_network_state_observed` only when `lsof` returns.
- `consult.wait_with_idle_bound` (`utils/py/consult.py:296-321`) polls every 2 s on the **main** thread. Once `idle_seconds()` answers, which needs 3 samples (`:468-488`), and the answer is ≥ the threshold, it calls `diag.classify()` immediately. `classify()` (`:490-551`) reads `_network_state_observed`, and `None` maps to "never established a safe idle window".
- **Reproduced (confirmed):** with the probe held in flight on the third sample, `classify()` returns exactly the reported detail, `[cpu=0.00s/s, samples=3, worktree-progress=no]` with "never established a safe idle window". It returns `timeout-idle-unknown` once the probe completes (Codex plan-QA r1 probe, on the real module).
- **Hosted attribution is plausible, not proven.** The same signature also follows an exception swallowed by `_loop()` (`:425-428`) before the probe on sample 3 (`attempted=False`; same r1 probe). The hosted log does not say which path ran. A loaded runner slowing `pgrep`/`lsof` makes the race more likely, but nothing here measures that.
- **What this fix covers:** only the in-flight race. An exception before the probe still leaves the observation absent and the label `timeout-unclassified`. That is the honest label for missing evidence, so the fix does not mask it, and a gh610 failure from that path remains possible and would be real signal.
- **Callers affected** (`classify()` reached while the sampler may still be inside a sample):
  - `consult.wait_with_idle_bound` (`consult.py:308`) and `review_xyz.py:429` classify **before** `stop()`, while the process can still be live.
  - The shims `agy-turn.py:601`, `claude-turn.py:251`, `codex-turn.py:128`, `commandcode-turn.py:114`, `deepseek-turn.py:323` and `muse-turn.py:312` classify after `stop()`. But `stop()` joins with only `timeout=2.0` (`turn_diagnostics.py:440-441`), so a sample still running its probe can race them as well.
  - A lock in `classify()` covers all of these without editing any caller.

## Fix (smallest)

- `TurnDiagnostics` gains `self._sample_lock = threading.Lock()`.
- `_sample()` holds the lock for its whole body, so a sample, including its one-shot probe, is atomic **with respect to `classify()`**. `idle_seconds()`, `cpu_ratio()` and direct `samples` reads stay unlocked. `cpu_ratio()` must stay lock-free because `_sample()` calls it under the lock and a plain `Lock` is not reentrant. The pre-existing gap between appending a sample and updating `_last_progress_t` (`:393-412`) stays visible to `idle_seconds()`. That is a stated limitation, not part of #1126.
- `classify()` acquires the same lock before reading state. A classifier called mid-sample waits for that sample to finish; a call between samples does not wait. The wait is **not** bounded by 5 s. One sample can include `ps` CPU sampling, the dialog `pgrep` checks, `_newest_mtime` (bounded by entry count, not wall time, `:288-327`), and, on the probe sample, `_network_state`'s own `ps` tree walk plus `lsof` (5 s timeout). The accepted cost is "one sample's duration", paid only on the kill or classify path.
- The classifier's decisions, thresholds and labels are unchanged (#1126: do not weaken it). `idle_seconds()` is unchanged.
- No change to `consult.py`, to the gh610 assertion, or to any test file.

Rejected alternatives:
- (a) Loosen gh610 to accept either label. That hides a real product race.
- (b) Make `idle_seconds()` return `None` while a probe is in flight. That delays the kill but couples the kill decision to probe timing; the lock keeps them independent.
- (c) Move the probe out of the sampler. That is larger and changes when the probe runs.

## Verification

- Manual race control, event-synchronized with no timing sleeps: `TESTS-RESULTS/2026-10-18+GH-1126/race-control.py.txt`, its `.log.txt`, and `provenance.jsonl` hashing both. It uses the real module and is run against both the **base** module (`git show e93214fe:utils/py/turn_diagnostics.py` into a temp dir) and the **candidate**.
  - Stub the CPU, dialog and mtime seams to idle values.
  - Stub `_network_state` to set `entered`, then block on `release` (bounded wait).
  - Run two samples, then run the third on thread S. Assert `entered` within a bound.
  - Start `classify()` on thread C.
  - **Base (red):** C finishes while the probe is still held, with label `timeout-unclassified` and the quoted "never established" detail.
  - **Candidate:** C has **not** finished while `release` is unset (bounded `join` returns with C alive). After `release.set()`, C finishes with `timeout-idle-unknown`.
  - All waits and joins are bounded, and every thread is asserted finished.
  - Case 2: no sample in flight, so `classify()` returns immediately (C finishes within a short bound).
  - Case 3 records, without asserting a fix, that the exception-before-probe path still yields `timeout-unclassified`. This is the honest-label limitation (R1).
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
