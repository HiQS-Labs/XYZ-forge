#!/usr/bin/env bash
# measure.sh — deterministic scalar metric capture for the Part C self-improvement loop (#50).
#
# The loop hill-climbs on ONE number emitted after each iteration. This is the pluggable metric
# primitive (sibling to --pre-advance-cmd): it runs a measure-cmd that prints a number and emits the
# validated scalar. "Same input -> same number" or the loop chases noise instead of climbing — so
# --check-deterministic runs the cmd twice and FAILS LOUDLY if the two readings differ.
#
# Floor-vs-exact honesty: a measure-cmd may mark its number as a lower bound by printing
# "<number> floor" (e.g. a partial/uninstrumented capture). The harness still emits the number but
# records floor=1, so the loop never treats a floor as an exact gain.
#
# Usage:
#   measure.sh [--check-deterministic] -c "<measure-cmd string>"
#   measure.sh [--check-deterministic] -- <measure-cmd> [args...]
#
# Contract: the measure-cmd prints the metric as the LAST non-empty stdout line, as a single numeric
# token (int or decimal, optional leading -), optionally followed by " floor". Preceding log lines are
# ignored. bash 3.2-portable (stock macOS).
#
# Exit: 0 (+ scalar on stdout; "floor" on stderr if a floor) · 2 usage · 3 measure-cmd failed
#       (non-zero exit) · 4 no single numeric metric on the last line · 5 non-deterministic (readings differ).

set -u
CHECK_DET=0
MODE="" CMD_STR=""
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --check-deterministic) CHECK_DET=1; shift ;;
    -c) MODE="string"; CMD_STR="${2:-}"; shift 2 ;;
    --) MODE="argv"; shift; ARGS=("$@"); break ;;
    -h|--help) echo "usage: measure.sh [--check-deterministic] {-c \"cmd\" | -- cmd args...}"; exit 0 ;;
    *) echo "measure.sh: unexpected arg: $1" >&2; exit 2 ;;
  esac
done
[ -n "$MODE" ] || { echo "usage: measure.sh [--check-deterministic] {-c \"cmd\" | -- cmd args...}" >&2; exit 2; }
if [ "$MODE" = "string" ]; then [ -n "$CMD_STR" ] || { echo "measure.sh: -c needs a command" >&2; exit 2; }
else [ "${#ARGS[@]}" -gt 0 ] || { echo "measure.sh: -- needs a command" >&2; exit 2; }; fi

# run the measure-cmd once -> sets RUN_OUT, RUN_RC
run_measure() {
  if [ "$MODE" = "string" ]; then RUN_OUT="$(bash -c "$CMD_STR" 2>/dev/null)"; RUN_RC=$?
  else RUN_OUT="$("${ARGS[@]}" 2>/dev/null)"; RUN_RC=$?; fi
}

# extract the scalar from RUN_OUT's last non-empty line -> sets SCALAR, FLOOR (0|1); returns 1 if no
# single numeric metric.
extract_scalar() {
  local last; last="$(printf '%s\n' "$RUN_OUT" | /usr/bin/grep -v '^[[:space:]]*$' | tail -1)"
  # strip surrounding whitespace
  last="$(printf '%s' "$last" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  FLOOR=0
  case "$last" in
    *' floor') FLOOR=1; last="${last% floor}" ;;
  esac
  printf '%s' "$last" | /usr/bin/grep -qE '^-?[0-9]+(\.[0-9]+)?$' || return 1
  SCALAR="$last"; return 0
}

run_measure
[ "$RUN_RC" -eq 0 ] || { echo "measure.sh: measure-cmd failed (exit $RUN_RC)" >&2; exit 3; }
extract_scalar || { echo "measure.sh: last stdout line is not a single numeric metric: '$(printf '%s\n' "$RUN_OUT" | tail -1)'" >&2; exit 4; }
FIRST="$SCALAR" FIRST_FLOOR="$FLOOR"

if [ "$CHECK_DET" -eq 1 ]; then
  run_measure
  [ "$RUN_RC" -eq 0 ] || { echo "measure.sh: measure-cmd failed on the determinism re-run (exit $RUN_RC)" >&2; exit 3; }
  extract_scalar || { echo "measure.sh: determinism re-run produced no single numeric metric" >&2; exit 4; }
  if [ "$SCALAR" != "$FIRST" ]; then
    echo "measure.sh: NON-DETERMINISTIC metric — '$FIRST' then '$SCALAR'. The loop must not hill-climb on noise." >&2
    exit 5
  fi
fi

[ "$FIRST_FLOOR" -eq 1 ] && echo "floor" >&2
printf '%s\n' "$FIRST"
