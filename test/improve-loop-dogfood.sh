#!/usr/bin/env bash
# improve-loop-dogfood.sh — Part C loop dogfood on a REAL bounded target (#50).
#
# Not an abstract number: optimize a real file toward FEWER lines (minimize) while a real ORACLE
# guarantees the required content survives — the builder may delete blank/comment lines but must keep
# both `KEEP:` lines, or the oracle fails and the change is rolled back. This exercises the whole loop
# (measure -> oracle -> champion judge -> rollback/halt -> provenance) on a realistic shrink task with
# a deterministic builder standing in for an agent (the production builder is marathon-drive plugged
# into --build-cmd; the loop is agnostic to which).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
IL="$HERE/../relay-automation/improve-loop.sh"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: improve-loop-dogfood =="
W="${TMPDIR:-/tmp}/il-dogfood.$$"; rm -rf "$W"; mkdir -p "$W"
trap 'rm -rf "$W"' EXIT

ART="$W/config.txt"
cat >"$ART" <<'EOF'
KEEP: required setting A
# removable comment 1

KEEP: required setting B
# removable comment 2

EOF
BASE_LINES="$(/usr/bin/grep -c '' "$ART")"   # 6 lines (2 KEEP + 2 comments + 2 blank)

# real oracle: BOTH required KEEP lines must remain (the builder can't "win" by deleting them)
ORACLE="[ \"\$(/usr/bin/grep -c '^KEEP:' '$ART')\" = 2 ]"
# real metric (minimize): line count
MEASURE="/usr/bin/grep -c '' '$ART'"
# deterministic builder: delete the FIRST blank-or-comment line (never a KEEP line)
cat >"$W/build.sh" <<EOF
awk 'BEGIN{d=0} { if(!d && (\$0=="" || \$0 ~ /^#/)){d=1; next} print }' '$ART' >'$ART.tmp' && mv '$ART.tmp' '$ART'
EOF

OUT="$(bash "$IL" --artifact "$ART" --measure-cmd "$MEASURE" --oracle-cmd "$ORACLE" \
        --build-cmd "bash $W/build.sh" --goal min --max-iterations 12 --plateau 2 \
        --state-dir "$W/state" 2>&1)"; RC=$?
echo "$OUT" | sed 's/^/    | /'

[ "$RC" = 0 ] && pass "dogfood ran to a halt (exit 0)" || fail "rc=$RC"
CHAMP="$(printf '%s\n' "$OUT" | /usr/bin/grep '^CHAMPION' | awk '{print $2}')"
{ [ -n "$CHAMP" ] && [ "$CHAMP" -lt "$BASE_LINES" ]; } && pass "champion shrank the file: $BASE_LINES -> $CHAMP lines" || fail "no shrink: base=$BASE_LINES champ=$CHAMP"
[ "$(/usr/bin/grep -c '^KEEP:' "$ART")" = 2 ] && pass "oracle held: both KEEP lines survive in the champion" || fail "KEEP lines lost: $(/usr/bin/grep -c '^KEEP:' "$ART")"
[ "$(/usr/bin/grep -c '' "$ART")" = "$CHAMP" ] && pass "the file on disk IS the champion ($CHAMP lines)" || fail "disk != champion"
# no-regress: champion never worse than baseline
[ "$CHAMP" -le "$BASE_LINES" ] && pass "no-regress: champion ($CHAMP) <= baseline ($BASE_LINES)" || fail "regressed"
# provenance captured every iteration
PROV="$W/state/provenance.jsonl"
{ [ -f "$PROV" ] && [ "$(/usr/bin/grep -c '"decision":"accept"' "$PROV")" -ge 1 ]; } && pass "provenance logged accepts (the shrink steps)" || fail "no accept provenance"
case "$OUT" in *"HALT (plateau"*) pass "halted on plateau once no removable lines remained";; *) fail "expected plateau halt";; esac

echo "  improve-loop-dogfood: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
