#!/usr/bin/env bash
# heldout-check.sh — held-out anti-gaming validation for the Part C loop (#50).
#
# The builder optimizes the VISIBLE metric (the one it can see). A held-out metric — measured by the
# loop, never exposed to or writable by the builder — catches overfitting/gaming: the signature is a
# visible-metric GAIN that arrives with a held-out-metric LOSS. The loop vetoes such an "improvement"
# even when the visible metric and the oracle both say accept, because the gain was bought by gaming
# the thing being measured, not by improving the artifact.
#
# Usage:
#   heldout-check.sh --visible-before V0 --visible-after V1 --held-before H0 --held-after H1
#                    [--goal max|min] [--held-goal max|min]   (--held-goal defaults to --goal)
# Exit: 0 OK (no gaming) · 9 GAMING (visible improved while held-out regressed) · 2 usage.

set -u
V0="" V1="" H0="" H1="" GOAL=max HGOAL=""
while [ $# -gt 0 ]; do
  case "$1" in
    --visible-before) V0="${2:-}"; shift 2 ;;
    --visible-after)  V1="${2:-}"; shift 2 ;;
    --held-before)    H0="${2:-}"; shift 2 ;;
    --held-after)     H1="${2:-}"; shift 2 ;;
    --goal)           GOAL="${2:-max}"; shift 2 ;;
    --held-goal)      HGOAL="${2:-}"; shift 2 ;;
    -h|--help) echo "usage: heldout-check.sh --visible-before V0 --visible-after V1 --held-before H0 --held-after H1 [--goal max|min] [--held-goal max|min]"; exit 0 ;;
    *) echo "heldout-check.sh: unexpected arg: $1" >&2; exit 2 ;;
  esac
done
HGOAL="${HGOAL:-$GOAL}"
is_num(){ printf '%s' "$1" | /usr/bin/grep -qE '^-?[0-9]+(\.[0-9]+)?$'; }
for v in "$V0" "$V1" "$H0" "$H1"; do is_num "$v" || { echo "heldout-check.sh: all four values are required and must be numeric" >&2; exit 2; }; done
case "$GOAL" in max|min) ;; *) echo "heldout-check.sh: --goal must be max|min" >&2; exit 2 ;; esac
case "$HGOAL" in max|min) ;; *) echo "heldout-check.sh: --held-goal must be max|min" >&2; exit 2 ;; esac

gt(){ awk -v a="$1" -v b="$2" 'BEGIN{exit !(a>b)}'; }
lt(){ awk -v a="$1" -v b="$2" 'BEGIN{exit !(a<b)}'; }
# improved/regressed relative to a goal direction
improved(){ if [ "$3" = max ]; then gt "$2" "$1"; else lt "$2" "$1"; fi; }   # before after goal
regressed(){ if [ "$3" = max ]; then lt "$2" "$1"; else gt "$2" "$1"; fi; }   # before after goal

if improved "$V0" "$V1" "$GOAL" && regressed "$H0" "$H1" "$HGOAL"; then
  echo "heldout-check: GAMING — visible improved ($V0 -> $V1, goal $GOAL) while held-out regressed ($H0 -> $H1, goal $HGOAL); vetoing the accept" >&2
  exit 9
fi
echo "heldout-check: OK — no visible-gain/held-out-loss gaming signature"
exit 0
