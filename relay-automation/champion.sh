#!/usr/bin/env bash
# champion.sh — champion/challenger state for the Part C self-improvement loop (#50).
#
# The hill-climb's accept/reject core + best-so-far memory. A challenger is ACCEPTED only when the
# oracle passes AND its metric strictly improves on the champion; otherwise it is REJECTED and the
# champion is kept (the loss is discarded). So a losing run ships the champion, never a worse artifact
# (no-regress). Every judgement appends a provenance record (decision, metric, cumulative spend).
#
# Verbs:
#   init  <state-dir> --metric <baseline> [--goal max|min]
#   judge <state-dir> --oracle-pass 0|1 --metric <M> [--spent <S>]   # exit 0 ACCEPT · 11 REJECT
#   state <state-dir> [--field metric|goal|iteration|spent|no-improve]
#
# State is small files under <state-dir>; provenance.jsonl is append-only. Decimals via awk; bash 3.2.

set -u
verb="${1:-}"; [ $# -gt 0 ] && shift
die(){ echo "champion.sh: $*" >&2; exit 2; }
gt(){ awk -v a="$1" -v b="$2" 'BEGIN{exit !(a>b)}'; }
lt(){ awk -v a="$1" -v b="$2" 'BEGIN{exit !(a<b)}'; }
fadd(){ awk -v a="$1" -v b="$2" 'BEGIN{printf "%s", a+b}'; }
is_num(){ printf '%s' "$1" | /usr/bin/grep -qE '^-?[0-9]+(\.[0-9]+)?$'; }

case "$verb" in
  init)
    DIR="${1:-}"; [ $# -gt 0 ] && shift
    METRIC="" GOAL=max
    while [ $# -gt 0 ]; do case "$1" in --metric) METRIC="${2:-}"; shift 2;; --goal) GOAL="${2:-max}"; shift 2;; *) die "init: bad arg $1";; esac; done
    [ -n "$DIR" ] || die "init needs <state-dir>"
    is_num "$METRIC" || die "init --metric must be numeric (the baseline, measured under the oracle)"
    case "$GOAL" in max|min) ;; *) die "--goal must be max|min";; esac
    mkdir -p "$DIR"
    echo "$METRIC" >"$DIR/champion_metric"; echo "$GOAL" >"$DIR/goal"
    echo 0 >"$DIR/iteration"; echo 0 >"$DIR/spent"; echo 0 >"$DIR/no_improve"
    printf '{"event":"baseline","metric":%s,"goal":"%s"}\n' "$METRIC" "$GOAL" >"$DIR/provenance.jsonl"
    echo "champion: baseline metric=$METRIC goal=$GOAL"
    ;;
  judge)
    DIR="${1:-}"; [ $# -gt 0 ] && shift
    OP="" M="" S=0
    while [ $# -gt 0 ]; do case "$1" in --oracle-pass) OP="${2:-}"; shift 2;; --metric) M="${2:-}"; shift 2;; --spent) S="${2:-0}"; shift 2;; *) die "judge: bad arg $1";; esac; done
    { [ -n "$DIR" ] && [ -f "$DIR/champion_metric" ]; } || die "judge needs an inited <state-dir>"
    case "$OP" in 0|1) ;; *) die "--oracle-pass must be 0 or 1";; esac
    is_num "$M" || die "--metric must be numeric"
    is_num "$S" || die "--spent must be numeric"
    CHAMP="$(cat "$DIR/champion_metric")"; GOAL="$(cat "$DIR/goal")"
    ITER="$(cat "$DIR/iteration")"; SPENT="$(cat "$DIR/spent")"; NI="$(cat "$DIR/no_improve")"
    ITER=$((ITER+1)); SPENT="$(fadd "$SPENT" "$S")"
    decision="reject"; reason=""
    if [ "$OP" = 0 ]; then
      reason="oracle-failed"; NI=$((NI+1))
    else
      improved=0
      if [ "$GOAL" = max ]; then gt "$M" "$CHAMP" && improved=1; else lt "$M" "$CHAMP" && improved=1; fi
      if [ "$improved" = 1 ]; then decision="accept"; reason="metric-improved"; CHAMP="$M"; NI=0
      else reason="no-improvement"; NI=$((NI+1)); fi
    fi
    echo "$CHAMP" >"$DIR/champion_metric"; echo "$ITER" >"$DIR/iteration"; echo "$SPENT" >"$DIR/spent"; echo "$NI" >"$DIR/no_improve"
    printf '{"iteration":%s,"decision":"%s","reason":"%s","challenger_metric":%s,"champion_metric":%s,"oracle_pass":%s,"spent_total":%s}\n' \
      "$ITER" "$decision" "$reason" "$M" "$CHAMP" "$OP" "$SPENT" >>"$DIR/provenance.jsonl"
    echo "champion: $decision ($reason) iteration=$ITER champion_metric=$CHAMP no_improve=$NI spent=$SPENT"
    [ "$decision" = accept ] && exit 0 || exit 11
    ;;
  state)
    DIR="${1:-}"; [ $# -gt 0 ] && shift
    FIELD=""
    while [ $# -gt 0 ]; do case "$1" in --field) FIELD="${2:-}"; shift 2;; *) die "state: bad arg $1";; esac; done
    { [ -n "$DIR" ] && [ -f "$DIR/champion_metric" ]; } || die "state needs an inited <state-dir>"
    case "$FIELD" in
      "")          echo "metric=$(cat "$DIR/champion_metric") goal=$(cat "$DIR/goal") iteration=$(cat "$DIR/iteration") spent=$(cat "$DIR/spent") no-improve=$(cat "$DIR/no_improve")" ;;
      metric)      cat "$DIR/champion_metric" ;;
      goal)        cat "$DIR/goal" ;;
      iteration)   cat "$DIR/iteration" ;;
      spent)       cat "$DIR/spent" ;;
      no-improve)  cat "$DIR/no_improve" ;;
      *) die "unknown --field: $FIELD" ;;
    esac
    ;;
  -h|--help) echo "usage: champion.sh init|judge|state <state-dir> ..."; exit 0 ;;
  "") echo "usage: champion.sh init|judge|state <state-dir> ..." >&2; exit 2 ;;
  *) die "unknown verb: $verb" ;;
esac
