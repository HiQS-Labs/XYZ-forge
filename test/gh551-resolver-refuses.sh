#!/usr/bin/env bash
# test/gh551-resolver-refuses.sh — GH-551 resolver refusal contract suite.
# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh551-resolver-refuses.sh; assertions verify: (1) contract comment is present in utils/py/rtl.py; (2) resolve_tick_bin raises RuntimeError on unresolvable binary (refusal observed) vs passes on valid binary; (3) resolve_tick_repo_root raises RuntimeError on missing root (refusal observed) vs passes on valid root; (4) resolve_turn_root raises RuntimeError on invalid explicit root (refusal observed) vs passes on valid root"}

source "$(dirname "$0")/_setup.sh" gh551-resolver-refuses

RTL_PY="$(cd "$(dirname "$0")/.." && pwd)/utils/py/rtl.py"

# --- (1) Acceptance criterion 1: Contract comment in utils/py/rtl.py ---
grep -q "A resolver that cannot determine its answer raises. It never returns a default." "$RTL_PY" \
  && pass "contract comment is present in utils/py/rtl.py" \
  || fail "contract comment missing from utils/py/rtl.py"

# --- (2) Acceptance criterion 2 & 3: resolve_tick_bin REFUSES on unresolvable binary ---
# Test 2a: Nonexistent TICK_BIN raises RuntimeError (observed REFUSAL)
out="$(PYTHONPATH="$(dirname "$RTL_PY")" python3 -c '
import os, sys, rtl
os.environ["TICK_BIN"] = "/nonexistent/path/to/tick"
try:
    rtl.resolve_tick_bin("/nonexistent/repo", "/nonexistent/xyz")
    print("UNEXPECTED_PASS")
except RuntimeError as e:
    print(f"REFUSAL_OBSERVED: {e}")
' 2>&1)"

printf '%s' "$out" | grep -q "REFUSAL_OBSERVED" \
  && pass "resolve_tick_bin: REFUSAL observed when tick binary is unresolvable" \
  || fail "resolve_tick_bin did not refuse unresolvable binary: $out"

# Control 2b: Valid executable binary returns cleanly without raising
mkdir -p "$WORK/bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$WORK/bin/tick"
chmod +x "$WORK/bin/tick"
out="$(PYTHONPATH="$(dirname "$RTL_PY")" python3 -c "
import os, sys, rtl
os.environ.pop('TICK_BIN', None)
res = rtl.resolve_tick_bin('$WORK', '$WORK')
print(f'RESOLVED: {res}')
" 2>&1)"

printf '%s' "$out" | grep -q "RESOLVED: $WORK/bin/tick" \
  && pass "control 2b: valid tick binary is resolved without error" \
  || fail "control 2b failed: $out"

# --- (3) Acceptance criterion 2 & 3: resolve_tick_repo_root REFUSES on missing root ---
# Test 3a: Nonexistent TICK_REPO_ROOT raises RuntimeError (observed REFUSAL)
out="$(PYTHONPATH="$(dirname "$RTL_PY")" python3 -c '
import os, sys, rtl
os.environ["TICK_REPO_ROOT"] = "/nonexistent/repo/root"
try:
    rtl.resolve_tick_repo_root("/nonexistent/fallback")
    print("UNEXPECTED_PASS")
except RuntimeError as e:
    print(f"REFUSAL_OBSERVED: {e}")
' 2>&1)"

printf '%s' "$out" | grep -q "REFUSAL_OBSERVED" \
  && pass "resolve_tick_repo_root: REFUSAL observed when repo root does not exist" \
  || fail "resolve_tick_repo_root did not refuse missing root: $out"

# Control 3b: Existing directory returns cleanly
out="$(PYTHONPATH="$(dirname "$RTL_PY")" python3 -c "
import os, sys, rtl
os.environ['TICK_REPO_ROOT'] = '$WORK'
res = rtl.resolve_tick_repo_root('$WORK')
print(f'RESOLVED: {res}')
" 2>&1)"

printf '%s' "$out" | grep -q "RESOLVED: $WORK" \
  && pass "control 3b: existing repo root is resolved without error" \
  || fail "control 3b failed: $out"

# --- (4) Acceptance criterion 2 & 3: resolve_turn_root REFUSES on invalid explicit root ---
# Test 4a: Nonexistent explicit root raises RuntimeError (observed REFUSAL)
out="$(PYTHONPATH="$(dirname "$RTL_PY")" python3 -c '
import os, sys, rtl
try:
    rtl.resolve_turn_root("/nonexistent/explicit/root", "/nonexistent/xyz")
    print("UNEXPECTED_PASS")
except RuntimeError as e:
    print(f"REFUSAL_OBSERVED: {e}")
' 2>&1)"

printf '%s' "$out" | grep -q "REFUSAL_OBSERVED" \
  && pass "resolve_turn_root: REFUSAL observed when explicit root does not exist" \
  || fail "resolve_turn_root did not refuse invalid explicit root: $out"

# Control 4b: Existing directory resolves cleanly
out="$(PYTHONPATH="$(dirname "$RTL_PY")" python3 -c "
import os, sys, rtl
res = rtl.resolve_turn_root('$WORK', '$WORK')
print(f'RESOLVED: {res}')
" 2>&1)"

printf '%s' "$out" | grep -q "RESOLVED: $WORK" \
  && pass "control 4b: existing explicit root is resolved without error" \
  || fail "control 4b failed: $out"

exit 0
