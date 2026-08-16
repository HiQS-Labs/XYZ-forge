#!/usr/bin/env bash
# improve-loop.sh test — the Part C champion/challenger hill-climb, end-to-end with a fake builder (#50).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
IL="$HERE/../relay-automation/improve-loop.sh"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: improve-loop =="
W="${TMPDIR:-/tmp}/improve-loop-test.$$"; rm -rf "$W"; mkdir -p "$W"
trap 'rm -rf "$W"' EXIT

# ---- Scenario A: hill-climb on a number; sequence drives accept/reject/rollback, plateau halts ------
A="$W/a"; mkdir -p "$A"; ART="$A/artifact"; CTR="$A/ctr"; SEQ="60 55 70 65 40"
echo 50 >"$ART"; echo 0 >"$CTR"
# fake builder: set artifact to the next sequence value (50 baseline -> 60,55,70,65,40)
BUILD='i=$(cat '"$CTR"'); i=$((i+1)); echo "$i" >'"$CTR"'; printf "%s\n" "$(echo '"$SEQ"' | cut -d" " -f"$i")" >'"$ART"
OUT="$(bash "$IL" --artifact "$ART" --measure-cmd "cat $ART" --oracle-cmd true --build-cmd "$BUILD" \
        --goal max --max-iterations 6 --plateau 2 --state-dir "$A/state" 2>&1)"; RC=$?
[ "$RC" = 0 ] && pass "scenario A ran to a halt (exit 0)" || fail "rc=$RC"
case "$OUT" in *"CHAMPION 70"*) pass "champion is the best seen (70)";; *) fail "expected CHAMPION 70: $OUT";; esac
[ "$(cat "$ART")" = 70 ] && pass "no-regress: artifact holds the champion (70), final rejected 40 rolled back" || fail "artifact=$(cat "$ART")"
case "$OUT" in *"HALT (plateau"*) pass "halted on plateau";; *) fail "expected plateau halt: $OUT";; esac
[ "$(/usr/bin/grep -c . "$A/state/provenance.jsonl")" = 6 ] && pass "provenance: baseline + 5 judgements = 6 records" || fail "provenance lines=$(/usr/bin/grep -c . "$A/state/provenance.jsonl")"

# ---- Scenario B: baseline fails the oracle -> refuse (exit 3) ---------------------------------------
B="$W/b"; mkdir -p "$B"; echo 50 >"$B/art"
bash "$IL" --artifact "$B/art" --measure-cmd "cat $B/art" --oracle-cmd false --build-cmd true \
     --max-iterations 3 --state-dir "$B/state" >/dev/null 2>&1; rc=$?
[ "$rc" = 3 ] && pass "baseline fails the oracle -> exit 3 (won't optimize a broken artifact)" || fail "expected 3 got $rc"

# ---- Scenario C: guaranteed halt via the iteration cap (no other stop) ------------------------------
C="$W/c"; mkdir -p "$C"; echo 0 >"$C/art"; CTR2="$C/ctr"; echo 0 >"$CTR2"
# a builder that always improves (monotone) -> only the cap can stop it
BUILD2='i=$(cat '"$CTR2"'); i=$((i+1)); echo "$i" >'"$CTR2"'; echo "$i" >'"$C/art"
OUT="$(bash "$IL" --artifact "$C/art" --measure-cmd "cat $C/art" --oracle-cmd true --build-cmd "$BUILD2" \
        --goal max --max-iterations 4 --state-dir "$C/state" 2>&1)"; rc=$?
{ [ "$rc" = 0 ] && case "$OUT" in *"HALT (iteration-cap"*) true;; *) false;; esac; } && pass "always-improving builder halts on the cap (4)" || fail "rc=$rc out=$OUT"
[ "$(bash "$HERE/../relay-automation/champion.sh" state "$C/state" --field iteration)" = 4 ] && pass "ran exactly max-iterations (4)" || fail "iteration count wrong"

# ---- Scenario D: held-out anti-gaming veto rejects a visible-gain/held-out-loss challenger ----------
D="$W/d"; mkdir -p "$D"; echo 50 >"$D/vis"; echo 80 >"$D/held"
# builder pushes the VISIBLE metric up (60) but the HELD-OUT metric down (70) -> gaming -> reject
BUILDD='echo 60 >'"$D/vis"'; echo 70 >'"$D/held"
OUT="$(bash "$IL" --artifact "$D/vis" --measure-cmd "cat $D/vis" --held-cmd "cat $D/held" \
        --oracle-cmd true --build-cmd "$BUILDD" --goal max --max-iterations 2 --state-dir "$D/state" 2>&1)"; rc=$?
{ case "$OUT" in *"CHAMPION 50"*) true;; *) false;; esac; } && pass "gaming challenger vetoed -> champion stays baseline (50)" || fail "expected CHAMPION 50: $OUT"
case "$OUT" in *"anti-gaming veto"*) pass "veto reason logged";; *) fail "expected veto note: $OUT";; esac
[ "$(cat "$D/vis")" = 50 ] && pass "gamed artifact rolled back (vis=50)" || fail "vis=$(cat "$D/vis")"

echo "  improve-loop: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
