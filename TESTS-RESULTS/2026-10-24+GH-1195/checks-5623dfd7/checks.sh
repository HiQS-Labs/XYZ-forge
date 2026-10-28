#!/usr/bin/env bash
# GH-1195 manual checks A (missing-DB red→green), B (resolver), smoke (distinguishable ledgers + override).
# Runs ONLY in two disposable clones. Usage: bash gh1195-checks.sh <A candidate clone> <B alternate clone> <out dir>
set -u
# Post-run correction (CodeRabbit on #1211, 2026-10-25): the smoke greps originally matched "#987654", which the
# planner never emits (it names GH-987654-SENTINEL.md). checks-driver.log is the ORIGINAL run with that bug;
# smoke-reevaluation.txt re-checked the retained artifacts. This copy is corrected so a rerun asserts the right text.
A="$1"; B="$2"; OUT="$3"; mkdir -p "$OUT"
BASE=80e67677
PASS=0; FAIL=0
pass() { echo "PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $*"; FAIL=$((FAIL+1)); }
export XYZ_HARNESS="$B"
export PYTHONDONTWRITEBYTECODE=1
echo "== A=$A @ $(git -C "$A" rev-parse --short HEAD) (fixed)   B=$B @ $(git -C "$B" rev-parse --short HEAD)   XYZ_HARNESS=B"

revert()  { git -C "$A" show "$BASE:utils/py/marathon_plan.py" > "$A/utils/py/marathon_plan.py"; }
restore() { git -C "$A" checkout -q -- utils/py/marathon_plan.py; }
run_plan() { # $1 = label ; extra env via caller ; prints rc
  local label="$1"; shift
  ( cd "$A" && env "$@" bash utils/marathon-plan.sh --dry-run --format json > "$OUT/$label.jsonl" 2> "$OUT/$label.err"; echo $? > "$OUT/$label.rc" )
  cat "$OUT/$label.rc"
}

echo "== check A: missing local DB"
b_before="$(git -C "$B" status --porcelain)"
mv "$A/releases.db" "$OUT/releases.db.hold"
revert
rc_red=$(run_plan checkA-reverted)
echo "reverted rc=$rc_red; stderr: $(head -c 160 "$OUT/checkA-reverted.err" | tr '\n' ' ')"
[ "$rc_red" != "3" ] && [ -s "$OUT/checkA-reverted.jsonl" ] && pass "reverted: ledger loaded from B (rc=$rc_red, nonempty report) with A's DB absent" || fail "reverted: expected a report from B (rc=$rc_red)"
restore
rc_green=$(run_plan checkA-fixed)
echo "fixed rc=$rc_green; stderr: $(head -c 160 "$OUT/checkA-fixed.err" | tr '\n' ' ')"
[ "$rc_green" = "3" ] && grep -q -i -F "releases.db" "$OUT/checkA-fixed.err" && pass "fixed: rc=3 cannot read A's missing releases.db (reads THIS clone)" || fail "fixed: expected rc=3 cannot-read (rc=$rc_green)"
mv "$OUT/releases.db.hold" "$A/releases.db"
b_after="$(git -C "$B" status --porcelain)"
[ "$b_before" = "$b_after" ] && pass "B tree byte-identical across check A" || fail "B tree changed: $b_after"
git -C "$A" diff --quiet -- utils/py/marathon_plan.py && pass "A restored to fixed code" || fail "A not restored"

echo "== check B: resolver probe (anchored vs unanchored; simulated vendored anchor)"
( cd "$A" && PYTHONPATH=utils/py python3 - <<'PY'
import os, tempfile
from unittest.mock import patch
import harness_paths as hp
anchor = os.path.abspath("utils/py/marathon_plan.py")
alt = os.environ["XYZ_HARNESS"]
print("unanchored_is_alternate =", hp.repo_root() == alt)
print("anchored_is_candidate   =", hp.repo_root(anchor_file=anchor) == os.getcwd())
assert hp.repo_root() == alt and hp.repo_root(anchor_file=anchor) == os.getcwd()
tmp = tempfile.mkdtemp()
vendored = os.path.join(tmp, "consumer/.xyz/utils/py/marathon_plan.py")
orig = os.path.isfile
with patch("harness_paths.os.path.isfile", side_effect=lambda p: p == vendored or orig(p)):
    c = hp.repo_root(anchor_file=vendored)
    print("vendored_is_consumer    =", c == os.path.join(tmp, "consumer"))
    assert c == os.path.join(tmp, "consumer")
print("resolver assertions passed (vendored file existence simulated only)")
PY
) > "$OUT/checkB-resolver.txt" 2>&1 && pass "resolver probe: $(tail -1 "$OUT/checkB-resolver.txt")" || { fail "resolver probe"; cat "$OUT/checkB-resolver.txt"; }

echo "== smoke: distinguishable ledgers (sentinel row only in B) + override precedence"
( cd "$B" && python3 utils/py/releases_app.py roadmap add --issue-num 987654 --issue-url https://github.com/HiQS-Labs/XYZ-forge/issues/987654 --title "GH-1195 smoke sentinel (disposable clone B only)" --created 2026-10-24 --doc-path PROJECT/1-INBOX/GH-987654-SENTINEL.md ) > "$OUT/smoke-sentinel-add.txt" 2>&1 || fail "sentinel add in B"
rc=$(run_plan smoke-fixed-unpinned); [ -s "$OUT/smoke-fixed-unpinned.jsonl" ] && ! grep -q -F "GH-987654-SENTINEL.md" "$OUT/smoke-fixed-unpinned.jsonl" && pass "main path: fixed, unpinned → report nonempty, sentinel ABSENT (read A) rc=$rc" || fail "main path: sentinel present or empty report (rc=$rc)"
revert
rc=$(run_plan smoke-reverted-unpinned); grep -q -F "GH-987654-SENTINEL.md" "$OUT/smoke-reverted-unpinned.jsonl" && pass "red control: reverted, unpinned → sentinel PRESENT (read B) rc=$rc" || fail "red control: sentinel absent on reverted code (rc=$rc)"
restore
rc=$(run_plan smoke-fixed-override "QUEUE_PLAN_ROOT=$B"); grep -q -F "GH-987654-SENTINEL.md" "$OUT/smoke-fixed-override.jsonl" && pass "adjacent path: fixed + QUEUE_PLAN_ROOT=B → sentinel PRESENT (override wins) rc=$rc" || fail "adjacent path: override not honoured (rc=$rc)"
git -C "$A" diff --quiet -- utils/py/marathon_plan.py && pass "A restored to fixed code (end)" || fail "A not restored (end)"

echo "== provenance"
: > "$OUT/provenance.jsonl"
for f in "$OUT"/*.jsonl "$OUT"/*.err "$OUT"/*.txt; do
  case "$f" in *provenance.jsonl) continue;; esac
  [ -f "$f" ] || continue
  rcf="${f%.*}.rc"; rc=""; [ -f "$rcf" ] && rc=$(cat "$rcf")
  printf '{"artifact":"%s","sha256":"%s","bytes":%s,"exit_code":"%s","candidate":"%s","alternate":"%s","date":"%s"}\n' \
    "$(basename "$f")" "$(shasum -a 256 "$f" | cut -d' ' -f1)" "$(wc -c < "$f" | tr -d ' ')" "$rc" "$(git -C "$A" rev-parse --short HEAD)" "$(git -C "$B" rev-parse --short HEAD)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUT/provenance.jsonl"
done
echo "== summary: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
