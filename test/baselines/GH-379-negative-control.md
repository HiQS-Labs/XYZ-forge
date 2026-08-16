# GH-379 — recorded negative control (#419)

Test:     `test/gh379-claude-builder-diagnosis.sh`
Baseline: `commit fb6544f77cba7230b42db621cfef3e16fa6fb9ca` — `utils/py/marathon_drive.py`
Date:     2026-08-15

## Defect Summary

Before GH-379, when a `--builder claude` turn failed due to budget exhaustion or turn limits, its failure details (`is_error`, `subtype`, `terminal_reason`, `total_cost_usd`) remained buried in the log file and were never copied into `ESCALATION.md`. Additionally, `CLAUDE_MAX_BUDGET` and `CLAUDE_MAX_TURNS` were undocumented in top-level docs and had stale comments in `claude-turn.sh`.

## Verification & Controls

`test/gh379-claude-builder-diagnosis.sh` verifies that:
1. When a builder turn records diagnostic error fields in its turn log, `ESCALATION.md` includes the additive `builder-diagnostic:` field with `subtype`, `terminal_reason`, etc.
2. **Negative Control:** When no diagnostic error exists in the turn log, no false `builder-diagnostic:` line is written to `ESCALATION.md`.
3. `CLAUDE_MAX_BUDGET` and `CLAUDE_MAX_TURNS` are documented in `README.md` and `relay-automation/MARATHON.example.yaml`.
4. `relay-automation/claude-turn.sh:46` header comment matches the code default of `0.50`.
