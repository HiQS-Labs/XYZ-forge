#!/usr/bin/env bash
# GH-346 Phase 1: the model-alias resolver must be an enhancement, never a dependency.
#
# resolve-model-alias.sh is a FUZZY ALIAS TABLE, not a validator:
#   * a miss exits 1 and prints nothing (pinned by test/model-alias.sh)
#   * it has NO canonical-slug passthrough -- feeding it `deepseek/deepseek-v4-pro`, the exact slug
#     it resolves `deepseek v4 pro` TO, is itself a miss
#
# So any caller that replaces `os.environ.get("X_MODEL", "<literal>")` with a bare resolver call
# blanks out every already-canonical model id and breaks the turn. utils/py/model_alias.py exists
# to make that mistake unavailable. This test pins its contract and the fact that deepseek-turn.py
# still carries its literal floor.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: gh346-resolver-fallback =="

# --- 1. resolve_model_slug behavior across every failure mode -----------------------------------
out="$(python3 - "$ROOT" <<'PY'
import os, sys
root = sys.argv[1]
sys.path.insert(0, os.path.join(root, "utils", "py"))
from model_alias import resolve_model_slug as r

cases = [
    # label,                 input,                        expected
    ("alias hit resolves",   "GLM 5.2",                    "z-ai/glm-5.2"),
    ("fuzzy hit resolves",   "deepseek v4 pro",            "deepseek/deepseek-v4-pro"),
    # the load-bearing one: canonical in, canonical out, even though the table has no such row
    ("canonical passthru",   "deepseek/deepseek-v4-pro",   "deepseek/deepseek-v4-pro"),
    ("miss falls through",   "totally-unknown-model-xyz",  "totally-unknown-model-xyz"),
    ("empty stays empty",    "",                           ""),
]
for label, inp, want in cases:
    try:
        got = r(inp, root)
    except Exception as e:
        print(f"FAIL={label}: raised {e!r} (resolve_model_slug must never raise)")
        continue
    print(("PASS=" if got == want else "FAIL=") + f"{label}: {inp!r} -> {got!r} (want {want!r})")

# missing harness root: the script does not exist, must not raise, must return input
try:
    got = r("GLM 5.2", "/nonexistent-harness-root")
    print(("PASS=" if got == "GLM 5.2" else "FAIL=") + f"missing resolver script -> {got!r}")
except Exception as e:
    print(f"FAIL=missing resolver script: raised {e!r}")

# a zero timeout forces the timeout branch; must fall back, not raise
try:
    got = r("GLM 5.2", root, timeout_s=0.000001)
    print(("PASS=" if got == "GLM 5.2" else "FAIL=") + f"timeout falls back -> {got!r}")
except Exception as e:
    print(f"FAIL=timeout: raised {e!r}")
PY
)"
if [ -z "$out" ]; then
  fail "python harness produced no output"
else
  while IFS= read -r line; do
    case "$line" in
      PASS=*) pass "${line#PASS=}" ;;
      FAIL=*) fail "${line#FAIL=}" ;;
    esac
  done <<EOF
$out
EOF
fi

# --- 2. deepseek-turn.py must keep its literal floor --------------------------------------------
DS="$ROOT/utils/py/deepseek-turn.py"
if grep -q 'resolve_model_slug' "$DS"; then
  pass "deepseek-turn.py routes DEEPSEEK_MODEL through resolve_model_slug"
else
  fail "deepseek-turn.py no longer calls resolve_model_slug"
fi
if grep -q 'DEEPSEEK_MODEL", "deepseek/deepseek-v4-pro"' "$DS"; then
  pass "deepseek-turn.py keeps its literal fallback under the resolver"
else
  fail "deepseek-turn.py dropped its literal fallback — a resolver miss would blank the model"
fi

# --- 3. the pattern is shared, not re-derived ---------------------------------------------------
if grep -q 'from model_alias import resolve_model_slug' "$ROOT/utils/py/review_xyz.py"; then
  pass "review_xyz.py consumes the shared helper instead of its own copy"
else
  fail "review_xyz.py has drifted back to a private copy of the resolver pattern"
fi

# --- 4. the resolver's own miss contract is untouched (test/model-alias.sh:43-46) ----------------
R="$ROOT/relay-automation/resolve-model-alias.sh"
miss_out="$(bash "$R" "totally-unknown-model-xyz" 2>/dev/null)"; miss_rc=$?
if [ "$miss_rc" = 1 ] && [ -z "$miss_out" ]; then
  pass "resolve-model-alias.sh still exits 1 with no output on a miss (contract Phase 1 depends on)"
else
  fail "resolver miss contract changed: rc=$miss_rc out='$miss_out' — Phase 1's fallback assumes rc!=0"
fi

echo "  gh346-resolver-fallback: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
