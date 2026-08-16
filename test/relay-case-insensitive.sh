#!/usr/bin/env bash
# test/relay-case-insensitive.sh — GH-17 (epic GH-16 Phase 1)
# On a case-insensitive filesystem (core.ignorecase=true), `git status` emits a tracked path in the
# case the index holds (e.g. RELAY-SYSTEM/…) while the harness allowlist holds the lowercase
# invocation arg (relay-system/…). rtl_in_allow's compare must treat these as equal there, or a
# reviewer's legitimate append to its own relay file is reverted with exit 6 and the work is lost.
# On a case-sensitive filesystem (core.ignorecase=false, e.g. Linux CI) the compare must stay
# byte-for-byte as before.
source "$(dirname "$0")/_setup.sh" relay-case-insensitive

LIB="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-turn-lib.sh"
source "$LIB"

unset RELAY_TARGET_ROOT 2>/dev/null || true

REL="relay-system/2026-06-24/thread.md"
MIXED="RELAY-SYSTEM/2026-06-24/thread.md"   # same path as git status would emit under a mixed-case index

# --- Case 1: case-insensitive filesystem (core.ignorecase=true) ---
git -C "$A" config core.ignorecase true
rtl_init "$A" "$A/$REL" ""
rtl_in_allow "$REL"   && pass "ignorecase: exact-case path matches allowlist" \
                      || fail "ignorecase: exact-case path rejected"
rtl_in_allow "$MIXED" && pass "ignorecase: mixed-case git-status path matches allowlist (no false revert)" \
                      || fail "ignorecase: mixed-case path rejected — THE BUG (reviewer turn would revert, exit 6)"

# --- Case 2: case-sensitive filesystem (core.ignorecase=false) — byte-for-byte unchanged ---
git -C "$A" config core.ignorecase false
rtl_init "$A" "$A/$REL" ""
rtl_in_allow "$REL" && pass "case-sensitive: exact-case path matches allowlist" \
                    || fail "case-sensitive: exact-case path rejected"
if rtl_in_allow "$MIXED"; then
  fail "case-sensitive: mixed-case path wrongly accepted (must stay case-sensitive on Linux)"
else
  pass "case-sensitive: mixed-case path correctly rejected (Linux byte-for-byte)"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
