---
gh_issue: 342
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/342
title: "GH-342 — the GH-281 Sentinel Tier-1 debug capture (XYZ_DEBUG_LOG) ported to the lane that actually runs"
status: "Shipped: all four hooks + both harvest spawns ported into utils/py/marathon_drive.py. New test/gh342-sentinel-debug-log-python.sh 29/0, observed 2/11 pre-fix. Cross-lane byte parity proven end-to-end. Bash twin untouched — no Frozen-twin-exception spent."
created: 2026-07-29
updated: 2026-07-29
owner: noel
doc_type: fix
complexity: 2
risk: 2
effort: 2
ratings_provisional: false
related:
  - "#308 — the twin-retirement epic; PR #338's audit found and deliberately deferred this one finding"
  - "#281 — Sentinel Tier 1, the feature itself (inert-by-default posture must be preserved)"
  - "#322 / #331 / #289 — the same class, all closed; GH-264's default flip un-fixed them without touching them"
  - "#348 — the sibling pattern in a test: an assertion that compares one lane to itself"
non_goals:
  - Editing relay-automation/marathon-drive.sh. GH-308 froze it; the fix goes in utils/py/. No Frozen-twin-exception is spent.
  - Changing the default. XYZ_DEBUG_LOG stays OFF unless explicitly set to 1 — the public-repo posture GH-281 shipped on.
  - "Normalising the stale-lock record's shorter shape. The Bash lane emits a 6-field record there and a 12-field one elsewhere; reproduced as-is, because fixing it on one lane only recreates exactly the drift this issue is about."
  - Adding network egress, telemetry, or a second output file. One local append-only JSONL, nothing else.
goal: >
  Make arming XYZ_DEBUG_LOG=1 actually capture on the default lane. Port xyz_debug_log_append, the
  three emit sites, the stale-lock inline record, and both harvest-findings.sh spawns from the frozen
  Bash twin into utils/py/marathon_drive.py — preserving the opt-in default-OFF gate, the JSONL field
  contract byte-for-byte, control-character normalisation, and the guarantee that a failed append can
  never change the driven run's exit code.
---

# GH-342 · Sentinel Tier-1 debug capture on the default Python lane

## Status
| What was just completed | What's next |
|---|---|
| Ported all six Bash sites into `utils/py/marathon_drive.py` at module scope. New `test/gh342-sentinel-debug-log-python.sh`: **29 pass / 0 fail** post-fix, **2 pass / 11 fail** pre-fix. Cross-lane byte parity asserted at both the record level (3 cases incl. adversarial input and a `--target-root` run) and **end-to-end** through a real default-lane driver run. Registered in `validate.sh`. | Review + merge. On merge this closes the last known item in the Bash-only class, and Quicksilver's second milestone issue. |

## Why this exists

`XYZ_DEBUG_LOG=1` was a no-op on every normal marathon run.

GH-281 shipped the Tier-1 capture into `relay-automation/marathon-drive.sh`. That file `exec`s
`utils/py/marathon_drive.py` near the top, and since GH-264 the Python twin is what executes when
`XYZ_PYTHON` is unset. So an operator arming the capture to investigate a bad marathon got an empty
`debug.log` and would reasonably conclude there was nothing to capture.

Verified on `f664dae`:

```
$ grep -c 'XYZ_DEBUG_LOG\|debug_log_append' utils/py/marathon_drive.py
0
```

**Why it hid for so long, precisely.** `test/sentinel-driver-hooks.sh` — GH-281's own acceptance test
— `sed`-extracts the helper functions out of the **Bash** file and sources them into a controlled
shell. It passes, and has always passed, while asserting a lane nobody runs. A feature that is off by
default and silently does nothing when switched on produces no signal in either state, and its test
was pointed at the wrong lane. That is the whole failure mode in one sentence.

## What was ported

Six sites in the Bash twin, all now present in the Python twin:

| Bash site | Python |
|---|---|
| `:173-174` opt-in defaults | `xyz_debug_log_enabled()` / `xyz_debug_log_file()` — read at call time, so a test can arm per-case |
| `:465-478` `_json_esc` + `xyz_debug_log_append` | module-scope `_json_esc` / `xyz_debug_log_append` |
| `:220-223` inline stale-lock record | `xyz_debug_log_stale_lock()`, emitted **before** the reclaim so the finding survives a failed reclaim |
| `:867-868` escalation | end of `escalate()`, carrying the relay-drive exit code |
| `:1103-1106` lane-park | inside `lane_attempt_gate` before `sys.exit(8)` — the Bash caller emits on `rc==8`, but the Python gate exits directly, so the record moves to where the exit is |
| `:849-853` / `:881-885` harvest spawns | `xyz_harvest_findings()`, called from `escalate()` and `save_transcript()` |

**Module scope, not nested in `main()`** — deliberately, following the GH-322
`runlog_find_comment_id` precedent. A helper reachable only through a full driven run is a helper
whose format contract is asserted by nothing, which is how the Bash record shape drifted from its
consumer in the first place.

## Two things reproduced rather than improved

1. **The stale-lock record is shorter than every other record** (6 fields; no `phase`/`task`/`file`/
   `line`/`probe`) and leaves `repo` unescaped. That is because in Bash the append helper is not yet
   defined that early in the file, so `:220` inlines a `printf`. It is worth fixing — on **both**
   lanes, on purpose, as its own change. Fixing it here, on one lane, would manufacture the exact
   divergence this issue exists to remove.
2. **`json.dumps` was not used.** It would escape correctly, but it is free to differ on separators
   and key order across versions. The two lanes must produce identical bytes, so the record is built
   with an explicit format string mirroring the Bash `printf`.

## Verification

`test/gh342-sentinel-debug-log-python.sh` — **29/0**, and observed **2/11 against pre-fix code**
(`git checkout -- utils/py/marathon_drive.py`, re-run, restore). The pre-fix run is the important
number: it proves the test can see the bug. Its two pre-fix passes are both honest — the dry-run
still exits 0, and the flag-off absence check passes trivially when nothing writes at all.

Every case drives the **default** lane (`XYZ_PYTHON` unset) or the Python module directly. A case
pinned to `XYZ_PYTHON=0` would have passed on day one, for the wrong reason.

What the suite covers, and what it does not:

- **Default-off** asserts the file's **absence**, not its emptiness — including `XYZ_DEBUG_LOG=yes`,
  since only the literal `1` arms it. A helper that creates an empty file has already touched the repo.
- **Cross-lane byte parity** at the record level, extracting and sourcing the real Bash helper, with
  only the timestamp normalised. Three cases, including tab/quote/backslash/newline/NUL/DEL input and
  a `--target-root` run.
- **End-to-end on the default lane** (case 7): a real `marathon-drive.sh --dry-run` over a stale
  driver lock appends the record; with the flag off it creates nothing; and case **7c** compares the
  two lanes end-to-end — that is the case that would have caught this on day one.
- **Robustness**: an unwritable `DEBUG_LOG_FILE` and a read-only log directory both raise nothing.
  The read-only case **skips loudly under root** rather than reporting a pass it did not earn (the
  GH-308 audit hit exactly this — a `gh`-absent case that silently tested the wrong thing).
- **Harvest gating**: not spawned with the flag off; spawned with the right argv when armed; a
  non-executable or missing script is skipped, not raised.
- **Not claimed end-to-end**: the escalation and lane-park hooks sit past the `--dry-run` exit and
  would need a full driven relay to reach. They are covered by an **AST assertion** that they are
  called from their real call sites (not merely defined) plus record-level parity. That is weaker than
  end-to-end and the test says so in place rather than implying coverage it lacks.

One defect was caught in the test itself before it shipped: the Python block's own PASS/FAIL tallies
were not folded into the file's counters, so a failure inside the heredoc would have printed in red
and still left the file reporting `0 fail`. The same green-signal shape this test exists to close.

## Follow-on, not in scope

The stale-lock record's inconsistent shape (above). Needs its own issue and touches the frozen Bash
twin, so it needs a decision about whether it qualifies as a safety defect under the GH-319 precedent
for spending a `Frozen-twin-exception`. It almost certainly does not — it is a shape wart, not a
safety hole.
