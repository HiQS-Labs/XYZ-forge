#!/usr/bin/env bash
# gh107-timeline-json-seam.sh
# Pins the --json seam for export_timeline.py
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPORTER="$HERE/../utils/timeline/export_timeline.py"

pass=0; fail=0
ok(){ if [ "$2" = "0" ]; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

echo "== test: gh107-timeline-json-seam =="
command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
command -v sqlite3 >/dev/null 2>&1 || { echo "sqlite3 required" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh107.XXXXXX")"
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
cleanup(){
  [ -n "${WORK:-}" ] && [ -d "$WORK" ] || return 0
  local resolved_work resolved_tmp
  resolved_work="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$WORK" 2>/dev/null)"
  resolved_tmp="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "${TMPDIR:-/tmp}" 2>/dev/null)"
  [ -n "$resolved_work" ] && [ -n "$resolved_tmp" ] || return 0
  case "$resolved_work" in
    "$resolved_tmp"/*) rm -rf "$WORK" ;;
    *) echo "REFUSING: $WORK resolves to $resolved_work outside TMPDIR ($resolved_tmp)" >&2; exit 2 ;;
  esac
}
trap cleanup EXIT

# We need a dummy DB to test with. We can copy the real one just like gh153.
DB="$WORK/releases.db"
cp "$HERE/../releases.db" "$DB"
# And RELEASES.md for drift tests
MD="$WORK/RELEASES.md"
cp "$HERE/../RELEASES.md" "$MD"

echo "-- testing --json seam --"
JSON_OUT="$WORK/out.json"
python3 "$EXPORTER" --db "$DB" --md "$MD" --json > "$JSON_OUT"
rc=$?
ok "--json exits 0" "$rc"

if python3 -c 'import json, sys; json.load(open(sys.argv[1]))' "$JSON_OUT" >/dev/null 2>&1; then
  ok "--json output is valid JSON" 0
else
  ok "JSON parse failed" 1
fi

echo "-- testing JSON parity with normal run --"
NORMAL_OUT_DIR="$WORK/normal_out"
python3 "$EXPORTER" --db "$DB" --md "$MD" --out "$NORMAL_OUT_DIR" >/dev/null 2>&1
NORMAL_JSON="$NORMAL_OUT_DIR/data.json"

if python3 -c '
import json, sys
def strip_meta(d):
    d.get("meta", {}).pop("generatedAtDisplay", None)
    d.get("cycle", {}).pop("generatedAt", None)
    return d
a = strip_meta(json.load(open(sys.argv[1])))
b = strip_meta(json.load(open(sys.argv[2])))
sys.exit(0 if a == b else 1)
' "$JSON_OUT" "$NORMAL_JSON"; then
  ok "--json payload matches normal data.json" 0
else
  ok "--json payload does NOT match normal data.json" 1
fi

echo "-- testing drift guard --"
# Drift guard behavior unchanged WITHOUT the flag
# We use a deterministically mismatched RELEASES.md fixture.
MISMATCHED_MD="$WORK/MISMATCHED_RELEASES.md"
cp "$MD" "$MISMATCHED_MD"
# Add a fake release to RELEASES.md to ensure drift is detected
cat << 'EOF' >> "$MISMATCHED_MD"

Release: 999.9.9
Status: Shipped
EOF

python3 "$EXPORTER" --db "$DB" --md "$MISMATCHED_MD" --check-drift > "$WORK/drift.txt" 2>&1
rc=$?
if [ "$rc" -eq 1 ]; then
  if grep -q "DRIFT" "$WORK/drift.txt"; then
    ok "drift guard correctly exits 1 and reports drift for mismatched file" 0
  else
    echo "Output was:"
    cat "$WORK/drift.txt"
    ok "drift guard exited 1 but did not mention 'DRIFT'" 1
  fi
else
  echo "Expected exit 1, got $rc. Output:"
  cat "$WORK/drift.txt"
  ok "drift guard failed to exit 1 for mismatched file" 1
fi



# Ensure --json doesn't write any files
python3 "$EXPORTER" --db "$DB" --md "$MD" --json --out "$WORK/timeline" > /dev/null
if [ -d "$WORK/timeline" ]; then
  ok "--json should bypass file writing, but output dir was created" 1
else
  ok "--json writes no files" 0
fi

echo "== gh107-timeline-json-seam: $pass passed, $fail failed =="
[ "$fail" -eq 0 ]
