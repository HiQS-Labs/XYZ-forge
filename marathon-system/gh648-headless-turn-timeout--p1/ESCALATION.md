# ESCALATION — Marathon Phase p1

phase: p1
task: MARATHON-P1-TURN
relay-drive-exit: 6
reason: containment-violation (off-lane edit reverted by a turn-taker)
gate: not-run
relay-file: marathon-system/gh648-headless-turn-timeout--p1/RELAY.md

turn-log: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/relay-system/logs/2026-09-16/codex-turn-MARATHON-P1-TURN-25217.log

<details>
<summary>Last 40 lines of failing turn log</summary>

```text
- "'`utils/py/turn_diagnostics.py`: quiet CPU/files now classify as
  `timeout-idle-unknown`; removed the claim that this proves blockage. Kept
  `REASON_IDLE` as the compatible import name. No network probe: an established
  connection cannot prove request progress, and missing network tooling should
  not create a new dependency. All-zero process-count samples now classify as
  unclassified; nonzero command exits discard partial probe output.
- Added `termination_record(trigger)` and `emit_termination(trigger, stream)`.
  The versioned JSON line records explicit idle-kill / wall-cap / child-orphan /
  unknown, diagnostic reason/detail, root PID, sample count, and unchanged exit
  code 7. Unknown triggers normalize to unknown. Classification and sink failures
  do not fail the described turn. Callers must supply the observed termination
  boundary; this lane does not infer orphaning or wire callers (L3/L5 own adoption).
- `test/gh648-l1-turn-termination.sh`: hermetic in-memory fixtures, including
  quiet samples with stubbed established outbound connection, JSON round trips,
  probe exceptions/nonzero exits, broken log sink, and CPU/progress controls.
  Four source mutations run in memory and each fails the same contract assertion.
- `validate.sh`: registered the new suite.

Verification: the focused suite passed all contract checks and rejected all four
mutants; shell syntax checks passed for the new suite and validate.sh. Before the
edit, the quiet fixture reproduced the old no-progress overclaim. Captured output:
`.relay-scratch/gh648-l1-verification.log` (ephemeral harness scratch).
No full gate was run, per operator instruction; the harness owns that gate.
No git commands were run. Graph tools were unavailable; inspected source directly.
"""
p.write_text(s)
PY
TICK_REPO_ROOT="/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang" "/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick" release MARATHON-P1-TURN --agent codex --to agy' in /private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/rtl-wt.GEW0py
 succeeded in 0ms:
released: MARATHON-P1-TURN

codex
Implemented idle-unknown classification and structured termination records. Focused tests passed, including four mutation checks. Full gate left to the harness. Relay updated and token released.

handing off to agy — agy, take your turn.
tokens used
53,229
Implemented idle-unknown classification and structured termination records. Focused tests passed, including four mutation checks. Full gate left to the harness. Relay updated and token released.

handing off to agy — agy, take your turn.
```
</details>
