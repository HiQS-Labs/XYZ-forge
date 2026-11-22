---
title: relay-drive runs the configured reviewer gate itself; finding-continuity rule in the reviewer protocol
status: Active
created: 2026-11-14
updated: 2026-11-20
owner: Noel Saw
gh_issue: 1465
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1465
doc_type: bugfix
complexity: 2
risk: 2
effort: 1
phases: 1
ratings_provisional: true
reported_from: LTVera-Pandas
non_goals:
  - new config file, env framework, clone manager or scheduler
  - rerunning browser cases or anything outside the configured gate command
related:
  - BinoidCBD/LTVera-Pandas#981
  - "#1428"
goal: >
  With a reviewer gate command configured, an Approved is attested only after relay-drive itself ran
  that command to exit 0; the reviewer protocol states that an earlier finding stays open until new
  evidence closes it.
---

# GH-1465 — relay-drive runs the configured reviewer gate itself; finding-continuity rule

## Status

| What was just completed | What's next |
|---|---|
| Development after #1471 merged; current CodeRabbit process lifetime, command canonicalization and nested-gate findings reproduced and repaired with retained red/green controls | Full gate and independent final-head QA, then current-head CodeRabbit disposition and landing |

## Acceptance

- [x] With `MARATHON_REVIEWER_GATE_CMD` set, an Approved is attested only after relay-drive itself ran the command to exit 0.
- [x] The reviewer protocol states that an earlier finding stays open until new evidence closes it (rule text and mirrors).
- [x] The group-RSS guard applies to the driver-run gate (shared `proc_group.run_bounded`).

## Symptom
In a host relay run (BinoidCBD/LTVera-Pandas#981) AI reviews turned a FAIL with open findings into a
PASS with no new evidence, and approved without running anything, relying on the builder's receipts.

## Operator rulings (pipeline owner, 2026-11-14)
- Keep "A `[Blocker]` must cite an observed failure" and add next to it, verbatim: "A finding from an
  earlier round stays open, and the verdict stays failing, until new evidence closes it."
- The driver runs the configured gate command itself and records the exit code, instead of trusting
  the reviewer's own `gate run: yes` line.

## Write-set
- `relay-automation/new-relay.sh` (canonical rule text) and its mirrors: `utils/py/marathon_drive.py`
  step 4c, `skills/1-hourly/relay/SKILL.md`, `skills/1-hourly/relay-xyz/SKILL.md`.
- `utils/py/proc_group.py` (`group_rss_mb`, optional `max_rss_mb` on `run_bounded`,
  `GATE_RSS_MB_DEFAULT = 8192`, `RSS_KILL_RC = 108`), shared with `utils/py/marathon_drive.py`
  (`_gate_group_rss_mb` delegates to `group_rss_mb`).
- `utils/py/relay_drive.py` `judge_terminal`: when `MARATHON_REVIEWER_GATE_CMD` is set, run it through
  `gate_env.gate_env()` and `proc_group.run_bounded(..., max_rss_mb=...)` (honoring
  `MARATHON_GATE_RSS_MB` and `MARATHON_GATE_GUARD=0`) in the target checkout; refuse on non-zero
  (`unverified-approval` after a builder-declared unverified block, else `gate-failed`).
  `utils/py/relay_attest.py` binds `driver-gate:` into the trailer.

## Verification
Manual red control and existing focused suites: `TESTS-RESULTS/2026-11-14+GH-1465/`. No new suite (GH-831).

### Run-2 CodeRabbit follow-up

`TESTS-RESULTS/2026-11-20+GH-1465/` retains the bounded reproducers and recon map.
The RSS watcher now follows surviving group members until communication completes,
and any in-flight TERM/KILL sequence finishes before return. The existing environment
registry and marathon mirror scrub the outer reviewer-gate command from gate children.
New attestation command metadata is JSON-quoted; legacy records keep their old format.
The driver checks the existing source-comparison contract before and after the gate,
allowing transcript-only commits and refusing source drift. Earlier Nit findings obey
the verbatim continuity rule; only newly raised Nits may accompany an Approved verdict.
The full gate passed on `6c3dc3aa2` in 935 seconds; independent final-head QA also passed.
Any subsequent review repair requires its own classified gate and independent QA; promotion remains separate.

### Bounded gate output capture (run-2 follow-up, 2026-11-21)

`6c3dc3aa2` kept `proc.communicate`, which bounds the wall clock across pipe-holding children but
buffers all gate output. `131a8a31d`/`08fee5d0f` swapped in a global tail reader and independent QA
found three defects (`/private/tmp/ks-sol-qa1467-08fee.md`): the post-exit `reader.join` had no
deadline so a surviving pipe holder escaped the wall timeout; the unconditional 64 KiB tail hid
differing output prefixes from `metamorphic_oracle.check_idempotence` (false pass); and a timeout
started a second reader pair and lost the first pair's diagnostics.

Replacement, in the one owner `utils/py/proc_group.py:run_bounded` (no second runner):
- One capture object per stream per invocation: a daemon reader thread using `os.read` on the binary
  pipe, appending as data arrives, shared through normal, timeout and exception paths; never a second
  reader pair. The reader owns its pipe: it closes the stream itself at EOF or error, so the owner never
  closes a descriptor a reader may still be blocked on (no fd reuse hazard).
- Reader failure: an `OSError` in a reader is recorded on its capture. After bounded cleanup the owner
  raises it (an in-flight exception, such as `Cancelled`, takes precedence and is preserved), so a
  truncated read can never return as a normal result that an oracle then compares.
- One wall deadline spans the launcher wait and every reader join. On expiry the whole group is
  TERM/KILLed, every join is bounded by `grace + 5`, and the captured text is returned. A reader that
  outlives that window (a descendant that escaped the group) is abandoned: its capture is frozen under the
  same lock that produces the returned snapshot (text, digest, truncated flag and completeness are taken
  atomically), later bytes are drained and discarded, and the result reports `capture_complete=False`.
- Default capture is the complete output, as before the tail work, so every ordinary caller
  (`fuzz_engine`, `wave_reconcile`, `metamorphic_oracle`, `harness`, ATE `run_variations`, `domain_oracles`,
  `claude_cli`, `jog_run`) keeps the full-output contract with the same decoding (locale encoding,
  universal newlines, `errors="replace"`). Bounded capture is opt-in via `capture_tail_bytes`, used only
  by the reviewer gate in `relay_drive.judge_terminal` (64 KiB). Both modes report a SHA-256 of the
  stream bytes observed, `truncated`, and `capture_complete`, so a comparison never depends on the tail.
  On timeout the excerpt is the captured tail (bounded) or the full text.
- RSS watcher: it is told to stop before cleanup and re-checks that flag before killing; its join is
  bounded by `grace + 5`, which still covers any legitimate in-flight TERM/KILL sequence (itself bounded by
  `grace`), so the existing "termination finishes before return" guarantee holds without an unbounded wait.
- Non-goals: no new suite (GH-831), no packaged-file change, no change to source-drift, attestation
  or protocol behavior. Rollback: revert the repair commit; `6c3dc3aa2` is the approved fallback.
- Verification (manual, recorded under `TESTS-RESULTS/2026-11-21+GH-1465/`, red on `08fee5d0f` and green on the repaired
  head, with `provenance.jsonl`): (1) `sh -c 'sleep 1.5 & exit 0'`, timeout .15/grace .05 returns
  `timed_out=True` in under 1.0 s, and a 6 s holder is dead on return; (2) the real
  `metamorphic_oracle.check_idempotence` on output with differing prefixes and an identical >64 KiB suffix
  reports `passed=False`; (3) both pre-timeout stdout and stderr sentinels survive cleanup; plus compatibility
  observations: complete default capture of two simultaneous 20k-line streams, multibyte output across read
  boundaries, newline translation, ordinary exit codes, tail-mode digest/truncation/timeout excerpt,
  reader-error propagation, cancellation mid-run leaving no live group, an escaped descendant that holds the pipes past `grace + 5` (bounded return, `capture_complete=False`, text and digest unchanged after later output), digests checked against independently computed SHA-256 of known bytes, and the RSS lifecycle controls
  (over-cap sample withheld until the launcher has exited; termination in flight) re-expressed with real processes because the
  capture no longer calls `communicate`.

## Limits
- Applies only when a gate command is configured; an unarmed relay is unchanged.
- In a marathon the focused gate now runs up to three times (reviewer, driver, pre-advance gate).
- The 900-second timeout path (exit 124) was not exercised; the driver-run gate uses wall-clock
  and group-RSS caps (no `ulimit -t` CPU cap, which stays on `run_pre_advance_gate`).

## Rating
- 2026-11-20: rated 55/60/50/55 (pri/sev/appeal/effort), recorded on the ledger row via `roadmap pickup`.
- Severity 60: a relay reviewer approved over open findings with no run, a false pass of the QA gate; recoverable, reach is relay users. Priority 55 is severity-led.
- Appeal 50 is neutral; effort 55 is moderate (one driver function, one shared helper, one protocol rule plus mirrors).
