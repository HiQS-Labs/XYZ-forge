#!/usr/bin/env bash
# GH-1208 manual checks on the EXISTING gh280 fixture (GH-831: no new suite). Runs in a disposable clone.
# Usage: bash gh1208-checks.sh <disposable clone at the fix> <out dir>
# Variants of test/gh280-jog-marathon-adapter.sh are written to <clone>/temp/ (gitignored) and deleted with the clone:
#   GH1127  : stub `gh run list` answers [] (no hosted run) + a roadmap_items row for GH-901 so the fixture's own
#             wave_reconcile writes the SHIPPED (PR #42) badge into the ledger (the local evidence).
#   NEITHER : GH1127 plus the L5 wave_reconcile step removed → no hosted run and no SHIPPED row.
set -u
C="$1"; OUT="$2"; mkdir -p "$OUT"; BASE=80e67677
PASS=0; FAIL=0; pass(){ echo "PASS: $*"; PASS=$((PASS+1)); }; fail(){ echo "FAIL: $*"; FAIL=$((FAIL+1)); }
SUITE="$C/test/gh280-jog-marathon-adapter.sh"
export XYZ_WORK_CONNECTORS=0 RELAY_SELF_SUFFICIENCY_SKIP=1
# the login shell exports XYZ_HARNESS to the PRIMARY clone (~/.zshrc); marathon-drive then counts lane attempts in the
# primary's .tick/attempts (RELAY-TURN is capped there) → exit 8 at C1. Pin the harness to this disposable clone.
unset XYZ_HARNESS   # the passing baseline ran with it unset; a pinned value makes marathon-drive count lane attempts in $C/.tick/attempts across reruns (cap 2 → exit 8)
rm -rf "$C/.tick/attempts"   # disposable clone: clear counters left by earlier reruns
make_variant() { # <name> <neither:0|1>
  python3 - "$SUITE" "$C/test/gh1208-$1.sh" "$2" <<'PY'
import sys,re
src,dst,neither=sys.argv[1],sys.argv[2],sys.argv[3]=="1"
s=open(src).read()
# (1) no hosted run
old_run='''if [ "${1:-}" = run ] && [ "${2:-}" = list ]; then
  python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); print(json.dumps([{"databaseId":42,"headSha":p["headRefOid"],"status":"completed","conclusion":"success"}]))' "$GH_STUB_PR_VIEW_JSON"
  exit 0
fi'''
assert old_run in s, "run list stub not found"
# only the wave-reconcile workflow query goes empty; marathon-drive's GH-509 gate-evidence `run list` keeps its synthetic green run
s=s.replace(old_run,'if [ "${1:-}" = run ] && [ "${2:-}" = list ]; then\n  case " $* " in *" --workflow wave-reconcile.yml "*) echo "[]"; exit 0;; esac\n'
  '  python3 -c \'import json,sys; p=json.load(open(sys.argv[1])); print(json.dumps([{"databaseId":42,"headSha":p["headRefOid"],"status":"completed","conclusion":"success"}]))\' "$GH_STUB_PR_VIEW_JSON"\n  exit 0\nfi',1)
# (2) seed the GH-901 ledger row before L5's wave_reconcile so the reconciler writes the SHIPPED badge into releases.db
l5='python3 "$FR/utils/py/wave_reconcile.py" --root "$FR" --pr 42 --offline "$WORK/hosted-wave-manifest.json" --skip-pull --skip-branch-check --allow-dirty > "$WORK/hosted-wave.log" 2>&1'
assert s.count(l5)==1, "L5 wave_reconcile line not unique"
seed=('python3 "$FR/utils/py/releases_app.py" --root "$FR" roadmap add --issue-num 901 --issue-url "https://github.com/example/example/issues/901" '
      '--title "GH-901 fixture lane" --created 2026-08-28 --doc-path "PROJECT/2-WORKING/$CAPTURE_DOC_NAME" > "${GH1208_OUT:?}/seed-${GH1208_LABEL:?}.txt" 2>&1\n'
      'printf "ROADMAP_SOURCE=releases\\n" >> "$FR/.pdda-mode"   # releases-mode: roadmap sync is a no-op, as in XYZ-forge; the legacy MD sync refused with the seeded row\n'
      'git -C "$FR" add -A >/dev/null 2>&1; git -C "$FR" commit -qm "gh1208: seed roadmap row" >/dev/null 2>&1\n')
diag=('cp "$WORK/hosted-wave.log" "$GH1208_OUT/wave-$GH1208_LABEL.log" 2>/dev/null\n'
      'python3 "$FR/utils/py/releases_app.py" --root "$FR" roadmap list --json > "$GH1208_OUT/rows-$GH1208_LABEL.json" 2>&1\n'
      'sqlite3 "$FR/releases.db" "select id,slug from repos;" > "$GH1208_OUT/repos-$GH1208_LABEL.txt" 2>&1; git -C "$FR" remote get-url origin >> "$GH1208_OUT/repos-$GH1208_LABEL.txt"\n')
repl = seed + ('# GH-1208 NEITHER variant: no local reconcile either\n' if neither else l5 + "\n" + diag)
s=s.replace(l5,repl,1)
# (3) GH-1208: capture landing.json and assert the marker shape right after L5 (WORK is removed at exit)
ja='jassert "$FR/$LAND_BUNDLE_REL/landing.json" '
i=s.index(ja); j=s.index("\n",i)+1
cap=('cp "$FR/$LAND_BUNDLE_REL/landing.json" "${GH1208_OUT:?}/landing-${GH1208_LABEL:?}.json" 2>/dev/null\n'
     'python3 - "$FR/$LAND_BUNDLE_REL/landing.json" <<\'PY1208\'\nimport json,sys\n'
     'try:\n    d=json.load(open(sys.argv[1]))\nexcept Exception as e:\n    print("FAIL: GH1208 landing.json unreadable:",e); sys.exit(0)\n'
     'h=d.get("hosted_reconcile","MISSING"); l=d.get("local_reconcile","MISSING")\n'
     'print(("PASS" if h is None else "FAIL")+": GH1208 hosted_reconcile is null when no hosted run (got %r)"%(h,))\n'
     'print(("PASS" if isinstance(l,dict) and "roadmap_gid" in l else "FAIL")+": GH1208 local_reconcile names the ledger row (got %r)"%(l,))\nPY1208\n')
s=s[:j]+cap+s[j:]
open(dst,'w').write(s)
PY
}
run_variant() { # <name> <label>
  ( cd "$C" && GH1208_OUT="$OUT" GH1208_LABEL="$2" bash "test/gh1208-$1.sh" > "$OUT/$2.log" 2>&1; echo $? > "$OUT/$2.rc" )
  grep -E "^(PASS|FAIL): (L5|L6|L7|GH1208)" "$OUT/$2.log" | head -8 | sed "s/^/  [$2] /"
}
make_variant GH1127 0; make_variant NEITHER 1
echo "== A: reverted jog_run.py ($BASE) + GH1127 variant — expect L5 refused by the hosted requirement"
git -C "$C" show "$BASE:utils/py/jog_run.py" > "$C/utils/py/jog_run.py"
run_variant GH1127 reverted-gh1127
grep -q -F "hosted wave-reconcile is not green" "$OUT/reverted-gh1127.log" && pass "reverted: L5 jog land refuses on the hosted requirement (the live defect)" || fail "reverted: expected the hosted refusal"
git -C "$C" checkout -q -- utils/py/jog_run.py
echo "== B: fixed + GH1127 variant — expect L5 lands on local evidence, L6 replay idempotent"
run_variant GH1127 fixed-gh1127
grep -q -E "^PASS: L5 jog land completes cleanly" "$OUT/fixed-gh1127.log" && pass "fixed: L5 jog land completes with no hosted run (local SHIPPED row)" || fail "fixed: L5 did not complete"
grep -q -E "^PASS: L6 land replay is idempotent" "$OUT/fixed-gh1127.log" && pass "fixed: L6 replay idempotent" || fail "fixed: L6 replay"
grep -q -E "^PASS: GH1208 hosted_reconcile is null" "$OUT/fixed-gh1127.log" && grep -q -E "^PASS: GH1208 local_reconcile names" "$OUT/fixed-gh1127.log" && pass "fixed: landing.json has hosted_reconcile=null and a local_reconcile object" || fail "fixed: landing.json marker shape (see GH1208 lines in log)"
echo "== C: fixed + NEITHER variant — expect L5 refused with the combined message"
run_variant NEITHER fixed-neither
grep -q -F "no reconciliation evidence for PR #42" "$OUT/fixed-neither.log" && pass "fixed: neither evidence → refuses with the combined message" || fail "fixed: NEITHER did not refuse as specified"
grep -q -E "^PASS: L5 jog land completes cleanly" "$OUT/fixed-neither.log" && fail "fixed: NEITHER variant landed (must not)" || pass "fixed: NEITHER variant did not land"
git -C "$C" diff --quiet -- utils/py/jog_run.py && pass "clone back at fixed code" || fail "clone not restored"
: > "$OUT/provenance.jsonl"
for f in "$OUT"/*.log; do rcf="${f%.log}.rc"; printf '{"artifact":"%s","sha256":"%s","bytes":%s,"suite_exit":"%s","revision":"%s","date":"%s"}\n' "$(basename "$f")" "$(shasum -a 256 "$f" | cut -d' ' -f1)" "$(wc -c < "$f" | tr -d ' ')" "$(cat "$rcf" 2>/dev/null)" "$(git -C "$C" rev-parse --short HEAD)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUT/provenance.jsonl"; done
V="$C/test/gh1208"  # transient variant copies in the disposable clone, never in this tree
cp "$V-GH1127.sh" "$OUT/variant-GH1127.sh"; cp "$V-NEITHER.sh" "$OUT/variant-NEITHER.sh"; rm -f "$V-GH1127.sh" "$V-NEITHER.sh"
echo "== summary: $PASS pass, $FAIL fail"; [ "$FAIL" -eq 0 ]
