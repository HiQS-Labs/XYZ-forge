# Host >600s Background Check — Claude Code (GH-1551, KS-07)

Records the operator-approved ("proceed", issue #1551 comment, 2026-11-20) >600s host check on a host without the 600s ceiling, run by the kickstart run-2 child session (Claude Sonnet 5.5) on Claude Code.

## Exact invocation (Bash tool call, verbatim arguments)

```
command:           s=$(date -u +%FT%TZ); echo "start $s"; sleep 660; echo "end $(date -u +%FT%TZ) exit=0"
description:       KS-07 check: 660s host-native background command
run_in_background: true
timeout:           900000
```

## Native on-disk output receipt (`host-bg-600s-claude-code-task-output.txt`, copied byte for byte from the harness task output file `buwc0oaro.output`)

```
start 2026-11-20T21:03:35Z
end 2026-11-20T21:14:35Z exit=0

[exited with code 0]
```

## Completion notification delivered to the session (verbatim text of the harness event)

```
<task-id>buwc0oaro</task-id>
<status>completed</status>
<summary>Background command "KS-07 check: 660s host-native background command" completed (exit code 0)</summary>
```

The event was injected into the session by the host after the command exited, with no polling loop and no wrapper; the child ended its turn waiting on it. Limits: the notification text above is transcribed from the session transcript (the host does not export events to disk), the output file is the native on-disk receipt, and this is one observation on one host.

## Reading

- Elapsed 660s (21:03:35Z to 21:14:35Z), 60s past the Antigravity 600s kill, ending with exit 0 and a host-delivered completion notification.
- Contrast (red arm): `native-bg-host-capability-probe.json` (task-1226, killed at exactly 600s on Antigravity ACP).
- Scope: a controlled mechanism check (U8). A real run-2 operation exceeding 10 minutes with its result consumed exactly once (U7) stays uncredited until run 2.
