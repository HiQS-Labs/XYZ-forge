#!/usr/bin/env bash
# GH-1195 final-QA R1: repeat check A with CONTENT DIGESTS of clone B (not porcelain text), plus a scoped
# mutation falsifier. Usage: bash gh1195-checkA-digest.sh <A> <B> <out dir>
set -u
A="$1"; B="$2"; OUT="$3"; mkdir -p "$OUT"; BASE=80e67677
PASS=0; FAIL=0; pass(){ echo "PASS: $*"; PASS=$((PASS+1)); }; fail(){ echo "FAIL: $*"; FAIL=$((FAIL+1)); }
export XYZ_HARNESS="$B" PYTHONDONTWRITEBYTECODE=1
digest_B() { # every tracked + untracked (non-ignored) file in B, content sha256, sorted; plus the ledger separately
  ( cd "$B" && git ls-files -co --exclude-standard | sort | while IFS= read -r f; do [ -f "$f" ] && shasum -a 256 "$f"; done )
}
echo "== A=$(git -C "$A" rev-parse --short HEAD) B=$(git -C "$B" rev-parse --short HEAD) XYZ_HARNESS=B"
digest_B > "$OUT/B-digest-before.txt"; n=$(wc -l < "$OUT/B-digest-before.txt" | tr -d ' ')
[ "$n" -gt 100 ] && pass "B digest extracted: $n files" || fail "B digest extraction empty/small ($n)"
mv "$A/releases.db" "$OUT/releases.db.hold"
git -C "$A" show "$BASE:utils/py/marathon_plan.py" > "$A/utils/py/marathon_plan.py"
( cd "$A" && bash utils/marathon-plan.sh --dry-run --format json > "$OUT/checkA-reverted.jsonl" 2> "$OUT/checkA-reverted.err"; echo $? > "$OUT/checkA-reverted.rc" )
rc=$(cat "$OUT/checkA-reverted.rc"); [ "$rc" != 3 ] && [ -s "$OUT/checkA-reverted.jsonl" ] && pass "reverted: read B (rc=$rc, $(wc -l < "$OUT/checkA-reverted.jsonl" | tr -d ' ') rows) with A's DB absent" || fail "reverted rc=$rc"
git -C "$A" checkout -q -- utils/py/marathon_plan.py
( cd "$A" && bash utils/marathon-plan.sh --dry-run --format json > "$OUT/checkA-fixed.jsonl" 2> "$OUT/checkA-fixed.err"; echo $? > "$OUT/checkA-fixed.rc" )
rc=$(cat "$OUT/checkA-fixed.rc"); [ "$rc" = 3 ] && grep -q -F "releases.db" "$OUT/checkA-fixed.err" && pass "fixed: rc=3 cannot read A's releases.db" || fail "fixed rc=$rc"
mv "$OUT/releases.db.hold" "$A/releases.db"
digest_B > "$OUT/B-digest-after.txt"
cmp -s "$OUT/B-digest-before.txt" "$OUT/B-digest-after.txt" && pass "B content digests identical before/after ($n files)" || { fail "B digests differ"; diff "$OUT/B-digest-before.txt" "$OUT/B-digest-after.txt" | head; }
echo "== falsifier: mutate one byte in a protected B file with unchanged porcelain text class"
printf '\n' >> "$B/releases.sql"
digest_B > "$OUT/B-digest-mutated.txt"
cmp -s "$OUT/B-digest-before.txt" "$OUT/B-digest-mutated.txt" && fail "falsifier: digest did NOT detect the mutation" || pass "falsifier: digest comparison detects a one-byte change in B/releases.sql"
( cd "$B" && git checkout -q -- releases.sql ) 2>/dev/null || true
digest_B > "$OUT/B-digest-restored.txt"
git -C "$A" diff --quiet -- utils/py/marathon_plan.py && pass "A restored to fixed code" || fail "A not restored"
: > "$OUT/provenance.jsonl"
for f in "$OUT"/*.jsonl "$OUT"/*.err "$OUT"/*.txt; do case "$f" in *provenance.jsonl) continue;; esac; [ -f "$f" ] || continue
  rcf="${f%.*}.rc"; rc=""; [ -f "$rcf" ] && rc=$(cat "$rcf")
  printf '{"artifact":"%s","sha256":"%s","bytes":%s,"exit_code":"%s","candidate":"%s","alternate":"%s","command":"bash utils/marathon-plan.sh --dry-run --format json (XYZ_HARNESS=B)","date":"%s"}\n' "$(basename "$f")" "$(shasum -a 256 "$f" | cut -d' ' -f1)" "$(wc -c < "$f" | tr -d ' ')" "$rc" "$(git -C "$A" rev-parse --short HEAD)" "$(git -C "$B" rev-parse --short HEAD)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUT/provenance.jsonl"; done
echo "== summary: $PASS pass, $FAIL fail"; [ "$FAIL" -eq 0 ]
