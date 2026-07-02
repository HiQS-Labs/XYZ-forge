#!/usr/bin/env bash
# test/checkjs.sh — registered test for utils/checkjs.sh (GH-71 Phase 2)
#
# Verifies:
#   (a) The real src/ tree is clean today (node --check + JSDoc coverage both pass).
#   (b) A missing-JSDoc fixture is detected and flagged.
#   (c) A syntax-error fixture is detected and flagged.
#   (d) A clean fixture (documented export) produces no findings.
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKER="$HERE/../utils/checkjs.sh"

[ -f "$CHECKER" ] || { echo "  FAIL: checker not found: $CHECKER" >&2; exit 1; }
[ -x "$CHECKER" ] || { echo "  FAIL: checker not executable: $CHECKER" >&2; exit 1; }

TEST_NAME="checkjs"
PASS=0
FAIL=0

pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/checkjs-test.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

echo "== test: $TEST_NAME =="
echo "  workdir: $WORK"

# ---------------------------------------------------------------------------
# Test (a): the real src/ tree is clean today
# ---------------------------------------------------------------------------

if bash "$CHECKER" "$HERE/../src" >/dev/null 2>"$WORK/real-src.err"; then
  pass "real src/ tree: node --check + JSDoc coverage both pass"
else
  fail "real src/ tree should be clean: $(cat "$WORK/real-src.err")"
fi

# ---------------------------------------------------------------------------
# Test (b): missing-JSDoc fixture
# ---------------------------------------------------------------------------

BAD_DIR="$WORK/bad"
mkdir -p "$BAD_DIR"
cat > "$BAD_DIR/nodoc.js" <<'EOF'
'use strict';

function undocumented(x) {
  return x + 1;
}

module.exports = { undocumented };
EOF

RC=0
STDERR_BAD="$WORK/stderr-bad.txt"
bash "$CHECKER" "$BAD_DIR" >/dev/null 2>"$STDERR_BAD" || RC=$?

if [[ "$RC" -ne 0 ]]; then
  pass "missing-jsdoc fixture: checker exits non-zero ($RC)"
else
  fail "missing-jsdoc fixture: checker should exit non-zero, got 0"
fi

if grep -q "missing-jsdoc" "$STDERR_BAD" 2>/dev/null; then
  pass "missing-jsdoc fixture: flagged with the right label"
else
  fail "missing-jsdoc fixture: no [missing-jsdoc] finding on stderr"
fi

# ---------------------------------------------------------------------------
# Test (c): syntax-error fixture
# ---------------------------------------------------------------------------

BROKEN_DIR="$WORK/broken"
mkdir -p "$BROKEN_DIR"
cat > "$BROKEN_DIR/syntax.js" <<'EOF'
'use strict';

function broken( {
EOF

RC=0
STDERR_BROKEN="$WORK/stderr-broken.txt"
bash "$CHECKER" "$BROKEN_DIR" >/dev/null 2>"$STDERR_BROKEN" || RC=$?

if [[ "$RC" -ne 0 ]]; then
  pass "syntax-error fixture: checker exits non-zero ($RC)"
else
  fail "syntax-error fixture: checker should exit non-zero, got 0"
fi

if grep -q "node-check" "$STDERR_BROKEN" 2>/dev/null; then
  pass "syntax-error fixture: flagged with the right label"
else
  fail "syntax-error fixture: no [node-check] finding on stderr"
fi

# ---------------------------------------------------------------------------
# Test (d): clean fixture — documented export, no findings
# ---------------------------------------------------------------------------

CLEAN_DIR="$WORK/clean"
mkdir -p "$CLEAN_DIR"
cat > "$CLEAN_DIR/documented.js" <<'EOF'
'use strict';

/**
 * Adds one to x.
 * @param {number} x
 * @returns {number}
 */
function documented(x) {
  return x + 1;
}

module.exports = { documented };
EOF

RC=0
STDERR_CLEAN="$WORK/stderr-clean.txt"
bash "$CHECKER" "$CLEAN_DIR" >/dev/null 2>"$STDERR_CLEAN" || RC=$?

if [[ "$RC" -eq 0 ]]; then
  pass "clean fixture: checker exits 0"
else
  fail "clean fixture: checker should exit 0, got $RC: $(cat "$STDERR_CLEAN")"
fi

echo ""
echo "checkjs: $PASS pass, $FAIL fail"
[[ "$FAIL" -eq 0 ]]
