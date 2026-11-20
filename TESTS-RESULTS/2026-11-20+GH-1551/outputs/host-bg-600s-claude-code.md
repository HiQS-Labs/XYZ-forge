# Host >600s Background Check — Claude Code (GH-1551, KS-07)

Records the operator-approved ("proceed", issue #1551 comment, 2026-11-20) >600s host check on a host without the 600s ceiling. Observed by the parent session; quoted verbatim from the parent's report.

> Host: Claude Code (Claude Sonnet 5.5) Bash run_in_background with timeout 900000 ms. Command: sleep 660 with start/end echoes. Observed: start 2026-11-20T21:03:35Z, end 2026-11-20T21:14:35Z, exit 0, completion notification delivered to the session (task id buwc0oaro). Contrast: Antigravity ACP native run_command killed a background command at exactly 600s (task-1226, recorded earlier in this folder).

## Reading

- Elapsed 660s (21:03:35Z to 21:14:35Z), i.e. 60s past the Antigravity 600s kill, ending with exit 0 and a host-delivered completion notification (no polling loop, no wrapper).
- Contrast evidence for the red arm: `native-bg-host-capability-probe.json` (task-1226, killed at exactly 600s).
- Scope (unchanged): this is a controlled mechanism check (U8). A real run-2 operation exceeding 10 minutes with its result consumed exactly once (U7) stays uncredited until run 2.
