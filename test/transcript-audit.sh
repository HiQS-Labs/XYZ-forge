#!/usr/bin/env bash
set -euo pipefail
# test/transcript-audit.sh — GH-66: hermetic tests for utils/transcript-audit.sh
#
# Tests:
#   1. stale-ref detection
#   2. repeat-explore detection
#   3. unbounded-stall detection
#   4. read-only guarantee (fixture bytes/mtimes unchanged after audit run)
#   5. non-existent dir exits 0 with clean report

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUDIT_SCRIPT="$(cd "$HERE/.." && pwd)/utils/transcript-audit.sh"

PASS=0
FAIL=0

pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }

echo "== test: transcript-audit =="

# ── build hermetic fixture dir ─────────────────────────────────────────────────
FIXTURE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/transcript-audit.XXXXXX")"
trap 'rm -rf "$FIXTURE_DIR"' EXIT

# Fixture 1: stale-ref — references a .bak file and a deprecated path
cat >"$FIXTURE_DIR/stale-ref-transcript.md" <<'EOF'
Turn 1
  Reading OLD_config.bak to understand the old layout.
  cat relay-automation/relay-loop.sh.OLD
  source ./utils/deprecated_helper.bak
  STATUS: Open
  DECISION: continue
EOF

# Fixture 2: repeat-explore — ls the same directory 4 times (above threshold of 3)
cat >"$FIXTURE_DIR/repeat-explore-transcript.md" <<'EOF'
Turn 1
  ls relay-system/2026-06-14/
  Did not find what I needed.
Turn 2
  ls relay-system/2026-06-14/
  Still looking.
Turn 3
  ls relay-system/2026-06-14/
  Still the same.
Turn 4
  ls relay-system/2026-06-14/
  Finally found it.
  STATUS: Open
  DECISION: proceed
EOF

# Fixture 3: unbounded-stall — no terminal marker at all
cat >"$FIXTURE_DIR/stalled-transcript.md" <<'EOF'
Turn 1
  I am exploring the codebase.
Turn 2
  ls relay-system/
  Reading some files...
Turn 3
  Still processing, no exit, no STATUS, no DECISION.
EOF

# ── capture checksums BEFORE audit run ────────────────────────────────────────
if command -v md5sum >/dev/null 2>&1; then
  CHECKSUM_BEFORE="$(md5sum "$FIXTURE_DIR"/*.md | sort)"
elif command -v md5 >/dev/null 2>&1; then
  # macOS
  CHECKSUM_BEFORE="$(for f in "$FIXTURE_DIR"/*.md; do md5 -r "$f"; done | sort)"
else
  CHECKSUM_BEFORE="$(ls -la "$FIXTURE_DIR"/*.md)"
fi

# Also capture mtimes (macOS stat -f %m, GNU stat -c %Y)
if stat -f '%m %N' "$FIXTURE_DIR"/*.md >/dev/null 2>&1; then
  MTIME_BEFORE="$(stat -f '%m %N' "$FIXTURE_DIR"/*.md | sort)"
else
  MTIME_BEFORE="$(stat -c '%Y %n' "$FIXTURE_DIR"/*.md | sort)"
fi

# ── run the audit against the fixture dir ─────────────────────────────────────
AUDIT_OUTPUT="$(bash "$AUDIT_SCRIPT" "$FIXTURE_DIR" 2>&1)"
AUDIT_RC=$?

echo "  audit output:"
echo "$AUDIT_OUTPUT" | sed 's/^/    /'

# ── Test 1: stale-ref finding ─────────────────────────────────────────────────
if grep -qF 'AUDIT stale-ref' <<<"$(echo "$AUDIT_OUTPUT")"; then
  pass "stale-ref: audit emitted stale-ref finding"
else
  fail "stale-ref: no 'AUDIT stale-ref' line found in output"
fi

# ── Test 2: repeat-explore finding ───────────────────────────────────────────
if grep -qE 'AUDIT repeat-explore .+ count=[0-9]+' <<<"$(echo "$AUDIT_OUTPUT")"; then
  pass "repeat-explore: audit emitted repeat-explore finding with count"
else
  fail "repeat-explore: no 'AUDIT repeat-explore ... count=N' line found in output"
fi

# ── Test 3: unbounded-stall finding ──────────────────────────────────────────
if grep -qF 'AUDIT unbounded-stall' <<<"$(echo "$AUDIT_OUTPUT")"; then
  pass "unbounded-stall: audit emitted unbounded-stall finding"
else
  fail "unbounded-stall: no 'AUDIT unbounded-stall' line found in output"
fi

# ── Test 4: read-only guarantee ───────────────────────────────────────────────
if command -v md5sum >/dev/null 2>&1; then
  CHECKSUM_AFTER="$(md5sum "$FIXTURE_DIR"/*.md | sort)"
elif command -v md5 >/dev/null 2>&1; then
  CHECKSUM_AFTER="$(for f in "$FIXTURE_DIR"/*.md; do md5 -r "$f"; done | sort)"
else
  CHECKSUM_AFTER="$(ls -la "$FIXTURE_DIR"/*.md)"
fi

if stat -f '%m %N' "$FIXTURE_DIR"/*.md >/dev/null 2>&1; then
  MTIME_AFTER="$(stat -f '%m %N' "$FIXTURE_DIR"/*.md | sort)"
else
  MTIME_AFTER="$(stat -c '%Y %n' "$FIXTURE_DIR"/*.md | sort)"
fi

if [[ "$CHECKSUM_BEFORE" == "$CHECKSUM_AFTER" ]] && [[ "$MTIME_BEFORE" == "$MTIME_AFTER" ]]; then
  pass "read-only: fixture checksums and mtimes unchanged after audit run"
else
  fail "read-only: fixture files were modified by the audit script (checksums or mtimes differ)"
fi

# ── Test 5: non-existent dir exits 0 ─────────────────────────────────────────
NONEXISTENT_DIR="$FIXTURE_DIR/does-not-exist-ever"
NODIR_OUTPUT="$(bash "$AUDIT_SCRIPT" "$NONEXISTENT_DIR" 2>&1)"
NODIR_RC=$?

if [[ "$NODIR_RC" -eq 0 ]]; then
  pass "non-existent-dir: exits 0"
else
  fail "non-existent-dir: expected exit 0, got $NODIR_RC"
fi

if grep -qE 'AUDIT (summary:|total )' <<<"$(echo "$NODIR_OUTPUT")"; then
  pass "non-existent-dir: clean structured report emitted (no crash, no error noise)"
else
  fail "non-existent-dir: expected a clean structured AUDIT line, got: $NODIR_OUTPUT"
fi

# ── also verify audit itself exited 0 on fixture run ─────────────────────────
if [[ "$AUDIT_RC" -eq 0 ]]; then
  pass "audit exit code: exits 0 (findings are a report, not a gate)"
else
  fail "audit exit code: expected 0, got $AUDIT_RC"
fi

# ── final summary ─────────────────────────────────────────────────────────────
echo ""
echo "transcript-audit: $PASS pass, $FAIL fail"

[[ "$FAIL" -eq 0 ]]
