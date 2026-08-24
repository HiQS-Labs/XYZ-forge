#!/usr/bin/env bash
# GH-181: telemetry -> reproducer fidelity. Per the 2026-08-23 amendment (#174 Part H-era revision):
# the real GH-141 record is the TOKENIZATION fixture (its underlying defect was fixed by GH-156 —
# `agy-turn.sh --help` exits 0 on current development), and reproduction is proven on a synthetic
# still-live record. Pre-fix behavior: mis-tokenized unquoted command -> rc 127 vs expected 2
# (see test/baselines/GH-181-negative-control.md, soak evidence #177 §3.2).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh181-adapter-fidelity.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh181-repro-adapter-fidelity =="

# Synthetic still-live defect: exits 7 with a distinctive signature only under --trigger.
LIVE="$WORK/failing_tool.sh"
cat > "$LIVE" <<'SH'
#!/usr/bin/env bash
if [ "${1:-}" = "--trigger" ]; then
  echo "synthetic live defect signature" >&2
  exit 7
fi
echo "failing_tool: ok"
exit 0
SH
chmod +x "$LIVE"
require_fixture_file "$LIVE" "live-fixture"

# Wrong-cause twin: same rc 7, DIFFERENT stderr (rc coincidence without the signature).
TWIN="$WORK/twin7.sh"
printf '#!/usr/bin/env bash\necho "unrelated seven error" >&2\nexit 7\n' > "$TWIN"
chmod +x "$TWIN"
require_fixture_file "$TWIN" "twin-7"

# The real GH-141 failure record, verbatim shape (joined command string; the absolute path
# contains a space and points at a clone that no longer exists — both are the point).
GH141="$WORK/gh141-record.json"
cat > "$GH141" <<JSON
{"command": "bash /Users/noelsaw/Documents/GH Repos/xyz-post-ate-fuzz-improvement-testing/relay-automation/agy-turn.sh --help", "exit_code": 2, "stderr": "agy-turn: RELAY_AGENT required", "err_substring": "RELAY_AGENT required"}
JSON
require_fixture_file "$GH141" "gh141-record"

# 1. TOKENIZATION: the GH-141 record's spaced path survives parsing as ONE argv token,
#    rewritten repo-relative (the soak's rc-127 mis-tokenization is gone).
cat > "$WORK/check_token.py" <<PY
import sys, json
sys.path.insert(0, "$ROOT/utils/py")
from repro_builder import parse_failure_telemetry
rec = parse_failure_telemetry("$GH141", repo_root="$ROOT")
expected = ["bash", "relay-automation/agy-turn.sh", "--help"]
assert rec["command"] == expected, f"tokenization wrong: {rec['command']!r}"
print("TOKENIZE_OK")
PY
require_fixture_file "$WORK/check_token.py" "check-token"
rc=0; out="$(python3 "$WORK/check_token.py" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "TOKENIZE_OK" <<<"$out"; then
  pass "GH-141 spaced-path record tokenizes to repo-relative argv without splitting"
else
  fail "tokenization of spaced-path record broken (rc=$rc, out=$out)"
fi

# 2. Historical-defect refusal: the record's defect was fixed (GH-156) — build must refuse
#    rather than emit a reproducer that can never reproduce.
rc=0; out="$(python3 "$ROOT/utils/py/repro_builder.py" --mode build --telemetry "$GH141" --output "$WORK/no.sh" 2>&1)" || rc=$?
if [ "$rc" -eq 2 ] && grep -qi "failed to reproduce" <<<"$out"; then
  pass "build refuses historical records whose defect no longer reproduces"
else
  fail "historical record not refused (rc=$rc, out=$out)"
fi

# 3. LIVE E2E: a still-live record builds a reproducer that actually reproduces.
LIVE_REC="$WORK/live-record.json"
cat > "$LIVE_REC" <<JSON
{"cmd": ["bash", "$LIVE", "--trigger"], "exit_code": 7, "stderr": "synthetic live defect signature", "err_substring": "synthetic live defect signature"}
JSON
require_fixture_file "$LIVE_REC" "live-record"
REPRO="$WORK/repro.sh"
rc=0; out="$(python3 "$ROOT/utils/py/repro_builder.py" --mode build --telemetry "$LIVE_REC" --output "$REPRO" 2>&1)" || rc=$?
if [ "$rc" -ne 0 ] || [ ! -x "$REPRO" ]; then
  fail "build of live record failed (rc=$rc, out=$out)"
else
  pass "live record builds an executable reproducer"
fi
require_fixture_file "$REPRO" "repro"
rc=0; out="$(bash "$REPRO" 2>&1)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "PASS: Failure reproduced" <<<"$out"; then
  pass "live reproducer reproduces rc=7 + signature end-to-end"
else
  fail "live reproducer failed to reproduce (rc=$rc, out=$out)"
fi

# 4. WRONG-CAUSE REJECTION: rc coincidence without the signature must not count as reproduction.
WRONG="$WORK/wrong-cause.json"
cat > "$WRONG" <<JSON
{"cmd": ["bash", "$TWIN"], "exit_code": 7, "stderr": "unrelated seven error", "err_substring": "synthetic live defect signature"}
JSON
require_fixture_file "$WRONG" "wrong-cause-record"
rc=0; out="$(python3 "$ROOT/utils/py/repro_builder.py" --mode build --telemetry "$WRONG" --output "$WORK/no2.sh" 2>&1)" || rc=$?
if [ "$rc" -eq 2 ] && grep -qi "failed to reproduce" <<<"$out"; then
  pass "wrong-cause rc coincidence rejected by signature matching"
else
  fail "wrong-cause record not rejected (rc=$rc, out=$out)"
fi

# 5. Emitter contract: run_harness records cmd as a native list (grep pins the schema-1.1 half).
if grep -q '"cmd": cmd,' "$ROOT/utils/ate/scripts/run_variations.py"; then
  pass "run_variations emits cmd as a native list (schema 1.1 emitter half)"
else
  fail "emitter no longer records cmd as a list"
fi

echo "  gh181-repro-adapter-fidelity: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
