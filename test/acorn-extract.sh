#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTRACTOR="$HERE/../src/acorn-extract.js"

TEST_NAME="acorn-extract"
PASS=0
FAIL=0

pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/acorn-extract-test.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

echo "== test: $TEST_NAME =="

# ---------------------------------------------------------------------------
# Test 1: Real file (happy path)
# ---------------------------------------------------------------------------
REAL_FILE="$HERE/../src/identity.js"

node "$EXTRACTOR" "$REAL_FILE" > "$WORK/real.json" || true

if grep -q "declarations" "$WORK/real.json" && grep -q "callSites" "$WORK/real.json"; then
  pass "real file extracted successfully"
else
  fail "real file extraction failed or missing fields: $(cat "$WORK/real.json")"
fi

# ---------------------------------------------------------------------------
# Test 2: Malformed snippet
# ---------------------------------------------------------------------------
MALFORMED="$WORK/bad.js"
echo "function foo( {" > "$MALFORMED"

RC=0
node "$EXTRACTOR" "$MALFORMED" > "$WORK/bad.json" || RC=$?

if [[ "$RC" -ne 0 ]]; then
  pass "malformed file exited with non-zero ($RC)"
else
  fail "malformed file should exit non-zero, got 0"
fi

if grep -q "Parse error" "$WORK/bad.json"; then
  pass "malformed file reported Parse error"
else
  fail "malformed file did not report parse error: $(cat "$WORK/bad.json")"
fi

echo ""
echo "acorn-extract: $PASS pass, $FAIL fail"
[[ "$FAIL" -eq 0 ]]
