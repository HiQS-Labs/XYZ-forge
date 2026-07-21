#!/usr/bin/env bash
set -euo pipefail

# GH-112 opt-in Python mode: XYZ_PYTHON=1 reroutes this entry point to the Python port in
# utils/py/ (same CLI contract + exit codes). Default (unset/0) runs the canonical Bash
# implementation below — Bash stays the supported default until the port is promoted.
if [[ "${XYZ_PYTHON-1}" == "1" ]]; then
  # UPGRADE.md §4 Phase-2 hardening (GH-255): (2a) `-` not `:-` so an explicit empty XYZ_PYTHON reads
  # as not-1 → Bash (load-bearing once the default flips to 1); (2b) require python3 >=3.8 and fall
  # back to Bash with a warning if it's missing/too-old, so a bad interpreter degrades, not bricks.
  if command -v python3 >/dev/null 2>&1 \
     && python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null; then
    _xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    export XYZ_ROOT="$_xyz_root"
    export PYTHONPATH="$_xyz_root/utils/py${PYTHONPATH:+:$PYTHONPATH}"
    exec python3 "$_xyz_root/utils/py/relay_loop.py" "$@"
  else
    echo "xyz: XYZ_PYTHON=1 but python3 missing or < 3.8 — falling back to Bash" >&2
  fi
fi
#
# relay-loop.sh — GH-33 Phase 2/3 + GH-46 Phase 4 adaptive-cadence wrapper over poll.sh.
#
# poll.sh is a stateless one-shot decision oracle; this wrapper turns its
# DECISION + suggested DELAY (poll.sh --emit-delay) into adaptive cadence.
# The reschedule mechanism is intentionally PLUGGABLE so the cadence is NOT
# locked to Claude Code's /loop:
#
#   (default)     ONE tick: run poll.sh once (it dispatches as usual), then print
#                 "NEXT-POLL: <seconds>" and exit poll.sh's code (10 = stop). This
#                 is the unit a /loop dynamic-mode tick, a cron job, or any external
#                 scheduler calls — it reads NEXT-POLL and waits that long.
#
#   --sleep-loop  Self-pace in pure bash: tick, sleep the suggested DELAY, repeat
#                 until DECISION: stop / poll.sh exit 10 (or poll.sh's --deadline).
#                 No /loop, no Claude dependency — proves the cadence is portable.
#
#   --background  GH-33 Phase 3 + GH-46 Phase 4: one tick, but on DECISION:
#                 run-runner OR nudge-cross-model, launch the configured command
#                 DETACHED (background process) and return immediately, so the
#                 session is freed for the turn's duration and the scheduler
#                 re-invokes on the next tick (no blocking, no polling for
#                 harness-tracked work). A pidfile is the single-turn lock:
#                 while a turn runs, a tick prints "BG-RUNNING: pid=N" and does
#                 NOT dispatch a second (no double-dispatch). When the turn
#                 exits, the next tick clears the stale pidfile and acts on the
#                 fresh DECISION (reads STATUS:/token → hand-off or stop). If
#                 the cross-model command is unset or not reachable, the wrapper
#                 degrades to poll.sh's existing manual nudge. Containment is
#                 INHERITED: the backgrounded process is the SAME runner/shim
#                 boundary (relay-turn-lib.sh path-allowlist / commit-bypass
#                 guard / no-push / worktree isolation) — `&` changes only WHEN
#                 the parent returns, never the child's code path. See
#                 test/relay-loop.sh (parity) + the kernel's own containment
#                 tests (test/relay-target-root-newfile.sh).
#
# Everything not consumed below is passed straight through to poll.sh, so all of
# poll.sh's --mode/--agent/--relay-file/--deadline/... flags work unchanged.
#
# Exit codes: mirrors poll.sh — 0 acted/idle, 10 stop (relay closed/deadline), 2 usage.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLL="${POLL_BIN:-"$HERE/poll.sh"}"

usage() {
  cat <<'EOF'
Usage: relay-automation/relay-loop.sh [--sleep-loop | --background] [--max-ticks N]
                                      [--min-delay S] [--bg-pidfile PATH]
                                      [--cross-model-cmd CMD] <poll.sh args...>

Adaptive-cadence wrapper over poll.sh (GH-33 Phase 2/3). Runs `poll.sh --emit-delay`
and turns its DECISION + DELAY into cadence.

  (default)      one tick; prints "NEXT-POLL: <seconds>"; exits poll.sh's code
                 (10 = stop). For a /loop dynamic tick, cron, or any scheduler.
  --sleep-loop   self-pace in pure bash (tick -> sleep DELAY -> repeat) until
                 DECISION: stop / exit 10. No /loop, no Claude dependency.
  --background   one tick; on DECISION: run-runner OR (when configured) a reachable
                 nudge-cross-model command, launch the turn DETACHED and return at
                 once (session freed; scheduler re-invokes next tick). A pidfile
                 prevents double-dispatch while a turn runs. Requires --relay-file
                 (default pidfile <relay-file>.bgpid) or an explicit --bg-pidfile.
                 Mutually exclusive with --sleep-loop. Unreachable or unset cross-
                 model commands degrade to poll.sh's manual nudge.
  --bg-pidfile P background-turn pidfile (default: <relay-file>.bgpid).
  --cross-model-cmd CMD
                 command to background-dispatch on DECISION: nudge-cross-model.
                 Wrapper-only; not forwarded to poll.sh.
  --max-ticks N  stop after N ticks (sleep-loop; 0 = unbounded). Runaway guard.
  --min-delay S  floor for the sleep (default 1s) so DELAY:0 never busy-spins; also
                 the re-check interval after a --background dispatch.

All other args pass straight through to poll.sh (--mode/--agent/--relay-file/...).
Env: POLL_BIN (poll.sh path), RELAY_LOOP_MIN_DELAY.
EOF
}

SLEEP_LOOP=0
BACKGROUND=0
BG_PIDFILE=""
MAX_TICKS=0                                   # 0 = unbounded (sleep-loop); runaway guard for tests/CI
MIN_DELAY="${RELAY_LOOP_MIN_DELAY:-1}"        # floor so DELAY:0 (act-now) never busy-spins
PASS_ARGS=()
RELAY_FILE_ARG=""                             # peeked (still forwarded) for the bg pidfile default
RUNNER_CMD_ARG=""                             # peeked (still forwarded) for the bg launch
CROSS_MODEL_CMD_ARG=""                        # wrapper-only cross-model background dispatch

while (($# > 0)); do
  case "$1" in
    --sleep-loop) SLEEP_LOOP=1; shift ;;
    --background) BACKGROUND=1; shift ;;
    --bg-pidfile) BG_PIDFILE="${2:-}"; shift 2 ;;
    --cross-model-cmd) CROSS_MODEL_CMD_ARG="${2:-}"; shift 2 ;;
    --max-ticks)  MAX_TICKS="${2:-0}"; shift 2 ;;
    --min-delay)  MIN_DELAY="${2:-1}"; shift 2 ;;
    --help|-h)    usage; exit 0 ;;
    # Peek a few poll.sh flags we also need here, but STILL forward them to poll.sh.
    --relay-file) RELAY_FILE_ARG="${2:-}"; PASS_ARGS+=("$1" "${2:-}"); shift 2 ;;
    --runner-cmd) RUNNER_CMD_ARG="${2:-}"; PASS_ARGS+=("$1" "${2:-}"); shift 2 ;;
    *)            PASS_ARGS+=("$1"); shift ;;
  esac
done

[[ -f "$POLL" ]] || { printf 'relay-loop: poll.sh not found at %s\n' "$POLL" >&2; exit 2; }

# Run one poll tick. Captures combined output (to parse DECISION/DELAY + echo for the
# operator), preserves poll.sh's exit code, and never aborts the wrapper on a non-zero
# (e.g. stop=10) under set -e. Sets globals DECISION + DELAY. Pass extra poll flags
# (e.g. --dry-run for the decision-only read the background path needs) as args.
# Note: ${ARR[@]+...} is the set -u-safe empty-array expansion (bash 3.2).
DECISION=""
DELAY=""
REASON=""
POLL_OUTPUT=""
run_poll() {
  local out rc
  local extra=("$@")
  if out="$("$POLL" --emit-delay ${extra[@]+"${extra[@]}"} ${PASS_ARGS[@]+"${PASS_ARGS[@]}"} 2>&1)"; then rc=0; else rc=$?; fi
  POLL_OUTPUT="$out"
  printf '%s\n' "$out"
  DELAY="$(printf '%s\n' "$out" | sed -n 's/^DELAY: \([0-9]*\).*/\1/p' | head -n 1)"
  DECISION="$(printf '%s\n' "$out" | sed -n 's/^DECISION: \([a-z-]*\).*/\1/p' | head -n 1)"
  REASON="$(printf '%s\n' "$out" | sed -n 's/^DECISION: [a-z-]* (\(.*\))$/\1/p' | head -n 1)"
  return "$rc"
}
tick() { run_poll; }                          # dispatch path (poll.sh acts): default + sleep-loop

# ── --background (GH-33 Phase 3): detached turn dispatch with a single-turn lock ──
bg_alive() {                                   # 0 = a backgrounded turn is still running
  [[ -f "$BG_PIDFILE" ]] || return 1
  local p; p="$(cat "$BG_PIDFILE" 2>/dev/null || true)"
  [[ -n "$p" ]] || return 1
  kill -0 "$p" 2>/dev/null
}
bg_launch() {                                  # launch the runner detached; record its pid
  local cmd="$1" log="${BG_PIDFILE}.log"
  # Mirror poll.sh run_cmd: a bare executable path runs directly (space-safe); a
  # command STRING falls back to bash -c. nohup + redirect so the turn outlives the
  # tick process (the session is freed; the scheduler re-invokes on the next tick).
  if [[ -x "$cmd" ]]; then
    nohup "$cmd" >"$log" 2>&1 &
  else
    nohup bash -c "$cmd" >"$log" 2>&1 &
  fi
  printf '%s\n' "$!" > "$BG_PIDFILE"
  disown 2>/dev/null || true
}
cmd_is_reachable() {                           # wrapper-only check for the Phase 4 shim command
  local cmd="$1" first=""
  [[ -n "$cmd" ]] || return 1
  [[ -x "$cmd" ]] && return 0
  IFS=' ' read -r first _ <<<"$cmd"
  [[ -n "$first" ]] || return 1
  command -v "$first" >/dev/null 2>&1
}
print_manual_nudge() {
  local cross_agent="cross-model"
  if [[ "$REASON" =~ ^turn\ belongs\ to\ non-Claude\ agent\ \'(.+)\'$ ]]; then
    cross_agent="${BASH_REMATCH[1]}"
  fi
  printf 'poll: %s turn detected — manual nudge required: "take your turn on %s"\n' \
    "$cross_agent" "${RELAY_FILE_ARG:-<relay-file>}" >&2
}

if ((BACKGROUND)); then
  ((SLEEP_LOOP)) && { printf 'relay-loop: --background is for the one-tick /loop model, not --sleep-loop\n' >&2; exit 2; }
  BG_PIDFILE="${BG_PIDFILE:-${RELAY_FILE_ARG:+${RELAY_FILE_ARG}.bgpid}}"
  [[ -n "$BG_PIDFILE" ]] || { printf 'relay-loop: --background needs --relay-file or --bg-pidfile\n' >&2; exit 2; }
  RUNNER_CMD_ARG="${RUNNER_CMD_ARG:-"$HERE/runner.sh"}"

  # 1) Decision WITHOUT dispatching — poll.sh stays a pure oracle (--dry-run).
  rc=0; run_poll --dry-run || rc=$?

  # 2) A turn already running? Hold — never dispatch a second (no double-dispatch).
  if bg_alive; then
    printf 'BG-RUNNING: pid=%s\n' "$(cat "$BG_PIDFILE")"
    printf 'NEXT-POLL: %s\n' "$MIN_DELAY"      # re-check for completion soon
    exit 0
  fi
  # Stale pidfile (turn finished) → clear it, then act on the fresh decision.
  [[ -f "$BG_PIDFILE" ]] && rm -f "$BG_PIDFILE"

  case "$DECISION" in
    run-runner)
      bg_launch "$RUNNER_CMD_ARG"
      printf 'BG-DISPATCH: pid=%s\n' "$(cat "$BG_PIDFILE")"
      printf 'NEXT-POLL: %s\n' "$MIN_DELAY"    # come back to detect completion
      exit 0 ;;
    nudge-cross-model)
      if cmd_is_reachable "$CROSS_MODEL_CMD_ARG"; then
        bg_launch "$CROSS_MODEL_CMD_ARG"
        printf 'BG-DISPATCH: pid=%s\n' "$(cat "$BG_PIDFILE")"
        printf 'NEXT-POLL: %s\n' "$MIN_DELAY"
      else
        print_manual_nudge
        printf 'NEXT-POLL: %s\n' "${DELAY:-$MIN_DELAY}"
      fi
      exit 0 ;;
    stop)
      printf 'NEXT-POLL: 0\n'; exit 10 ;;
    *)  # idle / run-watchdog → report, no background dispatch
      printf 'NEXT-POLL: %s\n' "${DELAY:-$MIN_DELAY}"; exit "$rc" ;;
  esac
fi

if ((SLEEP_LOOP)); then
  ticks=0
  while :; do
    rc=0; tick || rc=$?
    (( rc == 10 )) && exit 10                 # stop: relay terminal or deadline reached
    ticks=$((ticks + 1))
    (( MAX_TICKS > 0 && ticks >= MAX_TICKS )) && exit "$rc"
    d="${DELAY:-$MIN_DELAY}"
    (( d < MIN_DELAY )) && d="$MIN_DELAY"      # floor (also covers DELAY:0 act-now)
    sleep "$d"
  done
fi

# default: one tick, surface the suggested next-poll delay for an external scheduler.
rc=0; tick || rc=$?
printf 'NEXT-POLL: %s\n' "${DELAY:-$MIN_DELAY}"
exit "$rc"
