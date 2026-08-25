# Lane brief — GH-114: fully-headless agy invocation + idle-kill attribution

Execution surface of record: `PROJECT/2-WORKING/GH-114-HEADLESS-TTY-IDLE-HANG.md`
(issue: https://github.com/HiQS-Labs/XYZ-forge/issues/114)

## Task

`agy -p` under the turn shim periodically stalls with no worktree progress and ~0 CPU until
the 300s idle watchdog kills it (exit 7 `timeout-idle-no-progress`), logging
`bubbletea: could not open TTY: open /dev/tty: device not configured` — the TUI layer wants a
TTY that headless turns don't have, and blocks instead of failing fast.

1. `utils/py/agy-turn.py` (authoritative Python lane; the Bash twin is FROZEN per GH-308):
   force a fully headless invocation — no TTY probe path (env/flags per agy's CLI; stdin from
   /dev/null) so bubbletea never attempts /dev/tty; if the CLI still requires one, wrap with
   `script -q /dev/null` as the documented pty shim.
   NOTE (GH-221, landed 2026-08-24): the auth pre-flight now probes `agy models`; do not
   regress its verdict routing while touching the invocation path.
2. Idle-kill attribution: when the watchdog fires, capture the child's last stderr lines and
   open fds into the turn log so "blocked on TTY" vs "blocked on network" is stated, not
   guessed.
3. `test/gh114-headless-tty.sh` (new): run the turn wrapper with no controlling TTY and assert
   the agy invocation path never touches /dev/tty (stubbed agy asserting its stdio), and that
   a simulated stall produces the attribution block. Register in validate.sh TESTS.

## Definition of done

- A headless turn with no controlling TTY never logs the `bubbletea: could not open TTY` error.
- A watchdog idle-kill's log carries an attribution block naming the real blocker
  (TTY vs. network vs. lock).
- `test/gh114-headless-tty.sh` green and registered in validate.sh.
- `bash validate.sh` green.
