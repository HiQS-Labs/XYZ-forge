#!/usr/bin/env bash
# loop-stop.sh — guaranteed-halt stop-condition evaluator for the Part C self-improvement loop (#50).
#
# Pillar 3 (stop condition): autonomy demands a provable halt. Given the loop's running state, decide
# CONTINUE or STOP<reason>. Compose four halt paths, checked in priority order:
#   1. target reached   — the metric hit its goal (best outcome)
#   2. iteration cap    — completed >= --max-iterations (the HARD guarantee: fires on every path)
#   3. budget exhausted — cumulative spend >= --max-total-budget (across ALL iterations, not per-turn)
#   4. plateau          — K consecutive no-improvement iterations
# --max-iterations is REQUIRED and must be a positive integer: it is the termination proof — even if
# every other signal never fires, the cap halts the loop. Budget/plateau/target are earlier exits.
#
# Usage:
#   loop-stop.sh --iteration <completed> --max-iterations <C>
#                [--spent <S> --max-total-budget <B>]
#                [--metric <M> --target <T> --goal max|min]
#                [--no-improve <K> --plateau <P>]
#
# Exit: 0 CONTINUE (prints "CONTINUE") · 10 STOP (prints "STOP <reason>") · 2 usage.
# Numeric args may be integers or decimals (compared with awk); counts are integers.

set -u
ITER="" MAXIT="" SPENT=0 MAXBUD=0 METRIC="" TARGET="" GOAL=max NOIMP=0 PLATEAU=0
while [ $# -gt 0 ]; do
  case "$1" in
    --iteration) ITER="${2:-}"; shift 2 ;;
    --max-iterations) MAXIT="${2:-}"; shift 2 ;;
    --spent) SPENT="${2:-0}"; shift 2 ;;
    --max-total-budget) MAXBUD="${2:-0}"; shift 2 ;;
    --metric) METRIC="${2:-}"; shift 2 ;;
    --target) TARGET="${2:-}"; shift 2 ;;
    --goal) GOAL="${2:-max}"; shift 2 ;;
    --no-improve) NOIMP="${2:-0}"; shift 2 ;;
    --plateau) PLATEAU="${2:-0}"; shift 2 ;;
    -h|--help) echo "usage: loop-stop.sh --iteration N --max-iterations C [--spent S --max-total-budget B] [--metric M --target T --goal max|min] [--no-improve K --plateau P]"; exit 0 ;;
    *) echo "loop-stop.sh: unexpected arg: $1" >&2; exit 2 ;;
  esac
done

is_int(){ printf '%s' "$1" | /usr/bin/grep -qE '^[0-9]+$'; }
is_num(){ printf '%s' "$1" | /usr/bin/grep -qE '^-?[0-9]+(\.[0-9]+)?$'; }
# numeric >= and <= via awk (handles decimals)
ge(){ awk -v a="$1" -v b="$2" 'BEGIN{exit !(a>=b)}'; }
le(){ awk -v a="$1" -v b="$2" 'BEGIN{exit !(a<=b)}'; }

is_int "$ITER"  || { echo "loop-stop.sh: --iteration must be a non-negative integer (got '$ITER')" >&2; exit 2; }
{ is_int "$MAXIT" && [ "$MAXIT" -ge 1 ]; } || { echo "loop-stop.sh: --max-iterations is REQUIRED and must be a positive integer (the halt guarantee) — got '$MAXIT'" >&2; exit 2; }
case "$GOAL" in max|min) ;; *) echo "loop-stop.sh: --goal must be max or min" >&2; exit 2 ;; esac

stop(){ echo "STOP $1"; exit 10; }

# 1. target reached
if [ -n "$TARGET" ] && [ -n "$METRIC" ]; then
  is_num "$TARGET" && is_num "$METRIC" || { echo "loop-stop.sh: --metric/--target must be numeric" >&2; exit 2; }
  if [ "$GOAL" = max ]; then ge "$METRIC" "$TARGET" && stop "target-reached (metric $METRIC >= target $TARGET)"
  else le "$METRIC" "$TARGET" && stop "target-reached (metric $METRIC <= target $TARGET)"; fi
fi

# 2. iteration cap — the hard guarantee
[ "$ITER" -ge "$MAXIT" ] && stop "iteration-cap ($ITER/$MAXIT iterations completed)"

# 3. cumulative budget
if is_num "$MAXBUD" && ! [ "$MAXBUD" = 0 ]; then
  is_num "$SPENT" || { echo "loop-stop.sh: --spent must be numeric" >&2; exit 2; }
  ge "$SPENT" "$MAXBUD" && stop "budget-exhausted (spent $SPENT >= budget $MAXBUD)"
fi

# 4. plateau
if is_int "$PLATEAU" && [ "$PLATEAU" -gt 0 ]; then
  is_int "$NOIMP" || { echo "loop-stop.sh: --no-improve must be an integer" >&2; exit 2; }
  [ "$NOIMP" -ge "$PLATEAU" ] && stop "plateau ($NOIMP consecutive no-improvement >= $PLATEAU)"
fi

echo "CONTINUE"
exit 0
