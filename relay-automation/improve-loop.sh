#!/usr/bin/env bash
# improve-loop.sh — the Part C champion/challenger hill-climb loop (#50).
#
# Composes the six primitives into the metric-driven optimization loop the LOOPS.md endgame describes:
#   oracle-guard.sh   pre-flight: the builder's write surface is disjoint from the oracle (un-gameable)
#   measure.sh        deterministic scalar metric (the thing we hill-climb)
#   heldout-check.sh  anti-gaming veto (visible gain + held-out loss = rejected)
#   champion.sh       accept-on-improve / rollback-on-regress / provenance
#   loop-stop.sh      guaranteed halt (target | cap | budget | plateau)
#   loop-cost.sh      honest per-iteration spend
#
# Each iteration: build a challenger (--build-cmd, pluggable — a real agent via marathon-drive, or any
# script that edits --artifact) -> oracle gate (--oracle-cmd) -> measure visible (+ held-out) ->
# anti-gaming veto -> champion judge. An ACCEPTED challenger becomes the champion (its --artifact kept
# + snapshotted); a REJECTED one is rolled back to the champion snapshot. A losing run therefore ships
# the champion, never a worse artifact (no-regress). Emits the champion metric + the provenance path.
#
# v1 optimizes a SINGLE tracked file (--artifact); snapshot/rollback is a file copy (no git commits).
# Usage:
#   improve-loop.sh --artifact F --measure-cmd CMD --oracle-cmd CMD --build-cmd CMD
#                   --max-iterations N [--goal max|min] [--state-dir D]
#                   [--target T] [--max-total-budget B] [--plateau K]
#                   [--held-cmd CMD] [--oracle-paths CSV] [--agent A] [--currency seconds|tokens]
# Exit: 0 ran to a halt (champion emitted) · 2 usage · 3 baseline failed the oracle · 4 pre-flight (oracle-guard) failed.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
MEASURE="$HERE/measure.sh"; ORACLEG="$HERE/oracle-guard.sh"; CHAMP="$HERE/champion.sh"
STOP="$HERE/loop-stop.sh"; HELD="$HERE/heldout-check.sh"; COST="$HERE/loop-cost.sh"

ARTIFACT="" MEASURE_CMD="" ORACLE_CMD="" BUILD_CMD="" HELD_CMD=""
GOAL=max MAXIT="" TARGET="" MAXBUD=0 PLATEAU=0 STATE_DIR="" ALLOW="" ORACLE_PATHS="" AGENT=loop CURRENCY=seconds
while [ $# -gt 0 ]; do
  case "$1" in
    --artifact) ARTIFACT="${2:-}"; shift 2 ;;
    --measure-cmd) MEASURE_CMD="${2:-}"; shift 2 ;;
    --oracle-cmd) ORACLE_CMD="${2:-}"; shift 2 ;;
    --build-cmd) BUILD_CMD="${2:-}"; shift 2 ;;
    --held-cmd) HELD_CMD="${2:-}"; shift 2 ;;
    --goal) GOAL="${2:-max}"; shift 2 ;;
    --max-iterations) MAXIT="${2:-}"; shift 2 ;;
    --target) TARGET="${2:-}"; shift 2 ;;
    --max-total-budget) MAXBUD="${2:-0}"; shift 2 ;;
    --plateau) PLATEAU="${2:-0}"; shift 2 ;;
    --state-dir) STATE_DIR="${2:-}"; shift 2 ;;
    --allow) ALLOW="${2:-}"; shift 2 ;;
    --oracle-paths) ORACLE_PATHS="${2:-}"; shift 2 ;;
    --agent) AGENT="${2:-loop}"; shift 2 ;;
    --currency) CURRENCY="${2:-seconds}"; shift 2 ;;
    -h|--help) /usr/bin/grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "improve-loop.sh: unexpected arg: $1" >&2; exit 2 ;;
  esac
done
for req in ARTIFACT MEASURE_CMD ORACLE_CMD BUILD_CMD MAXIT; do
  eval "v=\${$req}"; [ -n "$v" ] || { echo "improve-loop.sh: --$(echo "$req" | tr A-Z_ a-z- | sed 's/^-//') is required" >&2; exit 2; }
done
[ -f "$ARTIFACT" ] || { echo "improve-loop.sh: --artifact not found: $ARTIFACT" >&2; exit 2; }
# The halt guarantee: --max-iterations must be a positive integer HERE (not just non-empty) — otherwise
# loop-stop.sh would exit 2 every tick and the while-loop would spin forever (it's the backstop that
# fires when nothing else does). Validate at the orchestrator, fail closed.
printf '%s' "$MAXIT" | /usr/bin/grep -qE '^[0-9]+$' && [ "$MAXIT" -ge 1 ] \
  || { echo "improve-loop.sh: --max-iterations must be a positive integer (the halt guarantee) — got '$MAXIT'" >&2; exit 2; }
case "$GOAL" in max|min) ;; *) echo "improve-loop.sh: --goal must be max|min" >&2; exit 2 ;; esac
# Fail closed on an un-enforceable budget: token spend is uncounted for the cost-blind agy lane
# (loop-cost emits a floor), so a token budget could silently never fire. Refuse the combination.
if [ "$MAXBUD" != 0 ] && [ "$CURRENCY" = tokens ] && [ "$AGENT" = agy ]; then
  echo "improve-loop.sh: cannot enforce --max-total-budget in tokens for the cost-blind agy lane — use --currency seconds" >&2; exit 2
fi
ALLOW="${ALLOW:-$ARTIFACT}"
# GH-430: the loop's only audit trail (provenance.jsonl) must survive the run. A process-scoped
# ${TMPDIR:-/tmp} default evaporates the moment the process exits, so proof cited in an issue/PR/
# ROADMAP entry can never be checked later. Default into a TRACKED in-repo path instead — NOT under
# .tick/ (gitignored, so rtl_enforce gives it zero containment protection per GH-396) and NOT under
# any other gitignored directory. An explicit --state-dir still wins (parsed above, ~line 45).
STATE_DIR="${STATE_DIR:-$HERE/state/improve-loop.$$}"
mkdir -p "$STATE_DIR"
SNAP="$STATE_DIR/champion.artifact"

log(){ echo "improve-loop: $*"; }

# --- pre-flight: oracle-immutability (the builder must not be able to edit the oracle) ---------------
if [ -n "$ORACLE_PATHS" ]; then
  if ! bash "$ORACLEG" --allow "$ALLOW" --oracle "$ORACLE_PATHS" >/dev/null 2>&1; then
    echo "improve-loop: PRE-FLIGHT FAILED — builder write surface ($ALLOW) overlaps the oracle ($ORACLE_PATHS)" >&2
    bash "$ORACLEG" --allow "$ALLOW" --oracle "$ORACLE_PATHS" >&2 2>&1 || true
    exit 4
  fi
  log "pre-flight OK — builder write surface disjoint from the oracle"
fi

# --- baseline: the oracle MUST already pass; measure metric0 ----------------------------------------
log "measuring baseline (oracle must pass)…"
if ! eval "$ORACLE_CMD" >/dev/null 2>&1; then echo "improve-loop: baseline FAILS the oracle — refusing to optimize a broken artifact" >&2; exit 3; fi
BASE="$(bash "$MEASURE" -c "$MEASURE_CMD")" || { echo "improve-loop: baseline measure failed" >&2; exit 3; }
bash "$CHAMP" init "$STATE_DIR" --metric "$BASE" --goal "$GOAL" >/dev/null
cp "$ARTIFACT" "$SNAP"
HELD_CUR=""
if [ -n "$HELD_CMD" ]; then HELD_CUR="$(bash "$MEASURE" -c "$HELD_CMD")" || HELD_CUR=""; fi
log "baseline metric=$BASE goal=$GOAL${HELD_CUR:+ held=$HELD_CUR}"

# --- the hill-climb ---------------------------------------------------------------------------------
STOP_REASON=""; SPEND_FLOORED=0
while :; do
  IT="$(bash "$CHAMP" state "$STATE_DIR" --field iteration)"
  SP="$(bash "$CHAMP" state "$STATE_DIR" --field spent)"
  MC="$(bash "$CHAMP" state "$STATE_DIR" --field metric)"
  NI="$(bash "$CHAMP" state "$STATE_DIR" --field no-improve)"
  dec="$(bash "$STOP" --iteration "$IT" --max-iterations "$MAXIT" --spent "$SP" --max-total-budget "$MAXBUD" \
          --metric "$MC" ${TARGET:+--target "$TARGET"} --goal "$GOAL" --no-improve "$NI" --plateau "$PLATEAU")"; src=$?
  # Drive on the EXIT CODE, not string-parsing: 0 CONTINUE · 10 STOP · anything else is a stop-evaluator
  # error — abort (fail closed) rather than spin forever, which is the whole point of the halt guarantee.
  case "$src" in
    0) : ;;
    10) STOP_REASON="${dec#STOP }"; break ;;
    *) echo "improve-loop: stop-condition evaluator errored (exit $src): $dec — aborting" >&2; exit 2 ;;
  esac

  # build a challenger, timed (wall-clock = the universal exact cost)
  t0=$(date +%s)
  eval "$BUILD_CMD" >/dev/null 2>&1 || true
  t1=$(date +%s); elapsed=$((t1 - t0))
  # Keep loop-cost's exact|floor honesty flag (its last stderr line) instead of dropping it: a floored
  # spend is a LOWER bound, so cumulative budget accounting under-counts and --max-total-budget could
  # silently never fire. Track it and surface it in the halt line.
  SPENT_IT="$(bash "$COST" --agent "$AGENT" --currency "$CURRENCY" --wall-clock-sec "$elapsed" 2>"$STATE_DIR/.costerr")" || SPENT_IT="$elapsed"
  [ "$(tail -1 "$STATE_DIR/.costerr" 2>/dev/null)" = floor ] && SPEND_FLOORED=1

  # oracle gate
  op=1; eval "$ORACLE_CMD" >/dev/null 2>&1 || op=0
  M="$MC"
  if [ "$op" = 1 ]; then M="$(bash "$MEASURE" -c "$MEASURE_CMD" 2>/dev/null)" || { op=0; M="$MC"; }; fi

  # anti-gaming veto (only meaningful when the oracle passed and we have a held-out metric)
  reason_extra=""
  if [ "$op" = 1 ] && [ -n "$HELD_CMD" ]; then
    HA="$(bash "$MEASURE" -c "$HELD_CMD" 2>/dev/null)" || HA="$HELD_CUR"
    if [ -n "$HELD_CUR" ] && [ -n "$HA" ]; then
      if ! bash "$HELD" --visible-before "$MC" --visible-after "$M" --held-before "$HELD_CUR" --held-after "$HA" --goal "$GOAL" >/dev/null 2>&1; then
        op=0; reason_extra=" (held-out anti-gaming veto)"   # treat gaming as an oracle failure
      fi
    fi
  fi

  # judge: accept (exit 0) keeps the artifact + snapshot; reject (exit 11) rolls back to the champion
  if bash "$CHAMP" judge "$STATE_DIR" --oracle-pass "$op" --metric "$M" --spent "$SPENT_IT" >/dev/null; then
    cp "$ARTIFACT" "$SNAP"                                   # accepted -> new champion
    [ -n "$HELD_CMD" ] && HELD_CUR="${HA:-$HELD_CUR}"
    log "iter $((IT+1)): ACCEPT metric=$M spent=$SPENT_IT"
  else
    cp "$SNAP" "$ARTIFACT"                                   # rejected -> restore the champion
    log "iter $((IT+1)): reject (metric=$M, oracle_pass=$op)$reason_extra — rolled back to champion"
  fi
done

# --- halt: emit the champion ------------------------------------------------------------------------
cp "$SNAP" "$ARTIFACT"                                       # ensure the tree holds the champion
FINAL="$(bash "$CHAMP" state "$STATE_DIR" --field metric)"
ITERS="$(bash "$CHAMP" state "$STATE_DIR" --field iteration)"
SPENT="$(bash "$CHAMP" state "$STATE_DIR" --field spent)"
SPEND_NOTE=""; [ "$SPEND_FLOORED" = 1 ] && SPEND_NOTE=" (floor — a lower bound; some iterations had uncounted spend)"
log "HALT ($STOP_REASON) — champion metric=$FINAL after $ITERS iterations, spent=$SPENT$SPEND_NOTE"
log "provenance: $STATE_DIR/provenance.jsonl"
printf 'CHAMPION %s\n' "$FINAL"
exit 0
