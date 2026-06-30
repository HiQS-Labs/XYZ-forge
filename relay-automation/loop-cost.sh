#!/usr/bin/env bash
# loop-cost.sh — honest per-iteration spend capture for the Part C loop (#50).
#
# The loop must SEE and CAP what it spends on itself, and be honest about whether that number is exact
# or a floor (a lower bound) — so "improvement-per-dollar" is never silently a floor. Closes the
# Codex/agy/Claude cost-capture gap by normalizing to a chosen currency and flagging honesty:
#   - --currency seconds : wall-clock is measurable for EVERY agent -> always EXACT (the safe default).
#   - --currency tokens  : exact for codex/claude/gemini (they emit token stats); the agy lane is
#                          cost-blind (no token output) -> token spend is a FLOOR (uncounted, emit 0).
#
# Emits the spend scalar on stdout; "exact" or "floor" on stderr (the measure.sh floor convention), so
# the loop records when its budget accounting is a lower bound.
#
# Usage:  loop-cost.sh --agent <codex|agy|claude|gemini> [--currency seconds|tokens]
#                      [--wall-clock-sec N] [--tokens N]
# Exit: 0 + scalar · 2 usage.

set -u
AGENT="" CURRENCY=seconds WALL="" TOKENS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --agent) AGENT="${2:-}"; shift 2 ;;
    --currency) CURRENCY="${2:-seconds}"; shift 2 ;;
    --wall-clock-sec) WALL="${2:-}"; shift 2 ;;
    --tokens) TOKENS="${2:-}"; shift 2 ;;
    -h|--help) echo "usage: loop-cost.sh --agent A [--currency seconds|tokens] [--wall-clock-sec N] [--tokens N]"; exit 0 ;;
    *) echo "loop-cost.sh: unexpected arg: $1" >&2; exit 2 ;;
  esac
done
is_num(){ printf '%s' "$1" | /usr/bin/grep -qE '^[0-9]+(\.[0-9]+)?$'; }
[ -n "$AGENT" ] || { echo "loop-cost.sh: --agent is required" >&2; exit 2; }
case "$CURRENCY" in seconds|tokens) ;; *) echo "loop-cost.sh: --currency must be seconds|tokens" >&2; exit 2 ;; esac

emit(){ echo "$2" >&2; printf '%s\n' "$1"; exit 0; }   # <scalar> <exact|floor>

if [ "$CURRENCY" = seconds ]; then
  is_num "$WALL" || { echo "loop-cost.sh: --currency seconds needs --wall-clock-sec <N>" >&2; exit 2; }
  emit "$WALL" exact      # wall-clock is measurable for every agent
fi

# currency = tokens
case "$AGENT" in
  agy)  # cost-blind: no token output. Token spend is uncounted -> a floor of 0.
    echo "loop-cost: agy is cost-blind (no token output) — token spend uncounted (floor 0); budget agy in --currency seconds" >&2
    emit 0 floor ;;
  *)
    is_num "$TOKENS" || { echo "loop-cost.sh: --currency tokens needs --tokens <N> for agent '$AGENT'" >&2; exit 2; }
    emit "$TOKENS" exact ;;
esac
