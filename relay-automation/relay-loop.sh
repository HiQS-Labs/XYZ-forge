#!/usr/bin/env bash
set -euo pipefail
#
# relay-loop.sh — GH-33 Phase 2: adaptive-cadence wrapper over poll.sh.
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
# Everything not consumed below is passed straight through to poll.sh, so all of
# poll.sh's --mode/--agent/--relay-file/--deadline/... flags work unchanged.
#
# Exit codes: mirrors poll.sh — 0 acted/idle, 10 stop (relay closed/deadline), 2 usage.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLL="${POLL_BIN:-"$HERE/poll.sh"}"

usage() {
  cat <<'EOF'
Usage: relay-automation/relay-loop.sh [--sleep-loop] [--max-ticks N] [--min-delay S] <poll.sh args...>

Adaptive-cadence wrapper over poll.sh (GH-33 Phase 2). Runs `poll.sh --emit-delay`
and turns its DECISION + DELAY into cadence.

  (default)      one tick; prints "NEXT-POLL: <seconds>"; exits poll.sh's code
                 (10 = stop). For a /loop dynamic tick, cron, or any scheduler.
  --sleep-loop   self-pace in pure bash (tick -> sleep DELAY -> repeat) until
                 DECISION: stop / exit 10. No /loop, no Claude dependency.
  --max-ticks N  stop after N ticks (sleep-loop; 0 = unbounded). Runaway guard.
  --min-delay S  floor for the sleep (default 1s) so DELAY:0 never busy-spins.

All other args pass straight through to poll.sh (--mode/--agent/--relay-file/...).
Env: POLL_BIN (poll.sh path), RELAY_LOOP_MIN_DELAY.
EOF
}

SLEEP_LOOP=0
MAX_TICKS=0                                   # 0 = unbounded (sleep-loop); runaway guard for tests/CI
MIN_DELAY="${RELAY_LOOP_MIN_DELAY:-1}"        # floor so DELAY:0 (act-now) never busy-spins
PASS_ARGS=()

while (($# > 0)); do
  case "$1" in
    --sleep-loop) SLEEP_LOOP=1; shift ;;
    --max-ticks)  MAX_TICKS="${2:-0}"; shift 2 ;;
    --min-delay)  MIN_DELAY="${2:-1}"; shift 2 ;;
    --help|-h)    usage; exit 0 ;;
    *)            PASS_ARGS+=("$1"); shift ;;
  esac
done

[[ -f "$POLL" ]] || { printf 'relay-loop: poll.sh not found at %s\n' "$POLL" >&2; exit 2; }

# Run one poll tick. Captures combined output (to parse DELAY + echo for the
# operator), preserves poll.sh's exit code, and never aborts the wrapper on a
# non-zero (e.g. stop=10) under set -e. Sets global DELAY.
# Note: ${PASS_ARGS[@]+...} is the set -u-safe empty-array expansion (bash 3.2).
DELAY=""
tick() {
  local out rc
  if out="$("$POLL" --emit-delay ${PASS_ARGS[@]+"${PASS_ARGS[@]}"} 2>&1)"; then rc=0; else rc=$?; fi
  printf '%s\n' "$out"
  DELAY="$(printf '%s\n' "$out" | sed -n 's/^DELAY: \([0-9]*\).*/\1/p' | head -n 1)"
  return "$rc"
}

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
