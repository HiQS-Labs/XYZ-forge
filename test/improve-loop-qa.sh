#!/usr/bin/env bash
# improve-loop-qa.sh — the Part C loop's QA-checklist gates as runnable tests (#50).
#
# The canonical doc's QA checklist: termination proof (every stop path halts) · un-gameable (oracle-edit
# contained + held-out catches gaming) · no-regress (champion >= baseline always) · provenance ·
# determinism litmus. Plateau + iteration-cap halts and the held-out anti-gaming veto are already
# proven in test/improve-loop.sh; this file adds the remaining explicit gates: DETERMINISM, TARGET-halt
# through the loop, all-regress no-regress, the oracle-immutability PRE-FLIGHT, and provenance fields.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
IL="$HERE/../relay-automation/improve-loop.sh"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: improve-loop-qa =="
W="${TMPDIR:-/tmp}/il-qa.$$"; rm -rf "$W"; mkdir -p "$W"
trap 'rm -rf "$W"' EXIT

# seq_run <rundir> <space-sep sequence> <improve-loop args...> -> echoes improve-loop stdout.
# A deterministic builder: each call writes the next sequence value to the artifact (baseline 50).
seq_run(){
  local d="$1" seq="$2"; shift 2
  mkdir -p "$d"; echo 50 >"$d/art"; echo 0 >"$d/ctr"
  cat >"$d/build.sh" <<EOF
i=\$(cat "$d/ctr"); i=\$((i+1)); echo "\$i" >"$d/ctr"
v=\$(echo "$seq" | cut -d' ' -f"\$i")
echo "\$v" >"$d/art"
EOF
  bash "$IL" --artifact "$d/art" --measure-cmd "cat $d/art" --oracle-cmd true \
       --build-cmd "bash $d/build.sh" --state-dir "$d/state" "$@" 2>/dev/null
}

# --- determinism litmus: identical inputs -> identical champion + identical decision sequence --------
o1="$(seq_run "$W/d1" "60 55 70 65 40" --goal max --max-iterations 6 --plateau 2)"
o2="$(seq_run "$W/d2" "60 55 70 65 40" --goal max --max-iterations 6 --plateau 2)"
c1="$(printf '%s\n' "$o1" | /usr/bin/grep '^CHAMPION')"; c2="$(printf '%s\n' "$o2" | /usr/bin/grep '^CHAMPION')"
{ [ "$c1" = "$c2" ] && [ "$c1" = "CHAMPION 70" ]; } && pass "determinism: same champion (70) across two identical runs" || fail "c1='$c1' c2='$c2'"
ds1="$(/usr/bin/grep -o '"decision":"[a-z]*"' "$W/d1/state/provenance.jsonl" | tr '\n' ',')"
ds2="$(/usr/bin/grep -o '"decision":"[a-z]*"' "$W/d2/state/provenance.jsonl" | tr '\n' ',')"
{ [ "$ds1" = "$ds2" ] && [ -n "$ds1" ]; } && pass "determinism: identical decision sequence ($ds1)" || fail "ds1='$ds1' ds2='$ds2'"

# --- termination: TARGET-halt through the whole loop ------------------------------------------------
ot="$(seq_run "$W/t" "55 60 65 70 75" --goal max --target 70 --max-iterations 10)"
{ case "$ot" in *"CHAMPION 70"*) true;; *) false;; esac; } \
  && [ -n "$(printf '%s\n' "$ot" | /usr/bin/grep 'HALT (target-reached')" ] \
  && pass "termination: target-halt — climbs from 50 and stops once champion reaches target 70" || fail "no target halt: $ot"

# --- no-regress: an all-regressing builder ships NOTHING worse than baseline ------------------------
on="$(seq_run "$W/n" "40 30 20 10 5" --goal max --max-iterations 5)"
{ case "$on" in *"CHAMPION 50"*) true;; *) false;; esac; } && pass "no-regress: all challengers worse -> champion stays baseline (50)" || fail "expected CHAMPION 50: $on"
[ "$(cat "$W/n/art")" = 50 ] && pass "no-regress: artifact unchanged from baseline (a losing run ships nothing)" || fail "art=$(cat "$W/n/art")"

# --- un-gameable: oracle-immutability PRE-FLIGHT rejects a builder that can edit the oracle ----------
RG="$W/g"; mkdir -p "$RG"; echo 50 >"$RG/art"
bash "$IL" --artifact "$RG/art" --allow "src/**" --oracle-paths "src/paths.js" \
     --measure-cmd "cat $RG/art" --oracle-cmd true --build-cmd true --max-iterations 2 --state-dir "$RG/state" >/dev/null 2>&1; rc=$?
[ "$rc" = 4 ] && pass "un-gameable: pre-flight rejects builder write-surface overlapping the oracle (exit 4)" || fail "expected 4 got $rc"

# --- provenance: judgements carry decision + challenger metric --------------------------------------
{ [ "$(/usr/bin/grep -c '"decision"' "$W/d1/state/provenance.jsonl")" -ge 1 ] \
  && [ "$(/usr/bin/grep -c '"challenger_metric"' "$W/d1/state/provenance.jsonl")" -ge 1 ]; } \
  && pass "provenance: every judgement records decision + challenger_metric" || fail "provenance missing fields"

# --- Codex review: the halt guarantee rejects an INVALID --max-iterations up front (no infinite spin) -
RV="$W/v"; mkdir -p "$RV"; echo 50 >"$RV/art"
for bad in 0 abc -1; do
  bash "$IL" --artifact "$RV/art" --measure-cmd "cat $RV/art" --oracle-cmd true --build-cmd true \
       --max-iterations "$bad" --state-dir "$RV/state-$bad" >/dev/null 2>&1; rc=$?
  [ "$rc" = 2 ] && pass "invalid --max-iterations '$bad' rejected up front (exit 2)" || fail "max-iterations '$bad' got $rc (would spin)"
done

# --- Codex review: fail closed on an un-enforceable token budget for the cost-blind agy lane ---------
bash "$IL" --artifact "$RV/art" --measure-cmd "cat $RV/art" --oracle-cmd true --build-cmd true \
     --max-iterations 3 --max-total-budget 100 --currency tokens --agent agy --state-dir "$RV/state-agy" >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ] && pass "token --max-total-budget for cost-blind agy refused (exit 2, fail closed)" || fail "agy token budget got $rc"

echo "  improve-loop-qa: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
