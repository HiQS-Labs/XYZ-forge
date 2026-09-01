#!/usr/bin/env bash
# GH-120: OpenRouter model-alias fuzzy lookup — asserts the seeded aliases in
# relay-automation/openrouter-model-aliases.yml resolve via relay-automation/resolve-model-alias.sh,
# including fuzzy variants (reordered tokens, hyphen/space-insensitive concatenation).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
R="$HERE/../relay-automation/resolve-model-alias.sh"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: model-alias =="

check() {
  # check <label> <input> <expected-slug>
  label="$1"; input="$2"; expected="$3"
  got="$(bash "$R" "$input" 2>/dev/null)"; rc=$?
  { [ "$rc" = 0 ] && [ "$got" = "$expected" ]; } \
    && pass "$label: '$input' -> $got" \
    || fail "$label: '$input' -> rc=$rc got='$got' want='$expected'"
}

# --- exact seeded aliases resolve to their canonical slugs ---
check "exact glm-5.2"                "glm-5.2"                    "z-ai/glm-5.2"
check "exact nemotron ultra 3"        "nemotron ultra 3"           "nvidia/nemotron-3-ultra-550b-a55b"
check "exact nemotron ultra 3 free"   "nemotron ultra 3 free"      "nvidia/nemotron-3-ultra-550b-a55b:free"
check "exact qwen3 coder"             "qwen3 coder"                "qwen/qwen3-coder"
check "exact deepseek v4 pro"         "deepseek v4 pro"            "deepseek/deepseek-v4-pro"
check "exact grok 4.6"                "grok 4.6"                   "x-ai/grok-4.6"
check "exact stealth ox-alpha"        "stealth ox-alpha"           "stealth/ox-alpha"

# --- case/punctuation-insensitive normalization ---
check "case-insensitive GLM 5.2"      "GLM 5.2"                    "z-ai/glm-5.2"
check "punctuation-insensitive"       "GLM5.2"                     "z-ai/glm-5.2"

# --- fuzzy variants (required) ---
check "reordered tokens"              "Nemotron 3 Ultra"           "nvidia/nemotron-3-ultra-550b-a55b"
check "hyphenated concat"             "nemotron-ultra3"            "nvidia/nemotron-3-ultra-550b-a55b"

# --- free variant stays distinct under fuzzy matching (no collision with the base alias) ---
check "free variant, reordered"       "Nemotron 3 Ultra Free"      "nvidia/nemotron-3-ultra-550b-a55b:free"

# --- unknown input: no match, exit 1, no stdout ---
unknown_out="$(bash "$R" "totally-unknown-model-xyz" 2>/dev/null)"; unknown_rc=$?
{ [ "$unknown_rc" = 1 ] && [ -z "$unknown_out" ]; } \
  && pass "unknown model -> exit 1, no output" \
  || fail "unknown model -> rc=$unknown_rc out='$unknown_out'"

# --- usage guard: no argument -> exit 2 ---
bash "$R" >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ] && pass "no argument -> usage (exit 2)" || fail "expected 2 got $rc"

# --- GH-346 Phase 3: caller-supplied table via MODEL_ALIASES_FILE=/dev/stdin ---
#
# Why this mode exists. Phase 3 needs to match a colloquial name ("GLM5.3 Max") against the
# PROFILE names in device_config.json, not against the shipped OpenRouter table. QA round 2
# found the seam unspecified and predicted three divergent implementations: reimplement
# normalize/squash in Python, refactor this script into a sourceable library, or write a temp
# file. All three grow a SECOND matcher.
#
# The fix was one character -- the readability guard went -f to -r, so a pipe is an acceptable
# table. The four matching tiers stay the single implementation in the repo, and a Python
# caller reuses them by piping in `name: canonical` lines. These cases pin that mode so the
# guard cannot quietly regress to -f and silently break the Phase 3 caller.
STDIN_TABLE=$'glm 5.3 max: zai-org/glm-5.3\nqwen 3.8 max: qwen/qwen3.8-max\n'

stdin_check() {
  local label="$1" query="$2" want="$3" got rc
  got="$(printf '%s' "$STDIN_TABLE" | MODEL_ALIASES_FILE=/dev/stdin bash "$R" "$query" 2>/dev/null)"; rc=$?
  if [ "$rc" = 0 ] && [ "$got" = "$want" ]; then
    pass "$label ('$query' -> $want)"
  else
    fail "$label: '$query' -> rc=$rc out='$got' (wanted '$want')"
  fi
}

stdin_check "piped table: exact"            "glm 5.3 max"   "zai-org/glm-5.3"
stdin_check "piped table: punctuation"      "GLM5.3 Max"    "zai-org/glm-5.3"
stdin_check "piped table: reordered tokens" "max glm 5.3"   "zai-org/glm-5.3"
stdin_check "piped table: second entry"     "Qwen 3.8 Max"  "qwen/qwen3.8-max"

# A miss against a piped table must behave exactly like a miss against the shipped file:
# exit 1, no stdout. This is what lets tier 2 fall through to tier 3 instead of blocking.
stdin_miss_out="$(printf '%s' "$STDIN_TABLE" | MODEL_ALIASES_FILE=/dev/stdin bash "$R" "no such profile zzz" 2>/dev/null)"; stdin_miss_rc=$?
{ [ "$stdin_miss_rc" = 1 ] && [ -z "$stdin_miss_out" ]; } \
  && pass "piped table: miss -> exit 1, no output (tier 2 falls through)" \
  || fail "piped table miss -> rc=$stdin_miss_rc out='$stdin_miss_out'"

# The -r guard must still REJECT an unreadable path. Loosening -f to -r was meant to admit a
# pipe, not to admit a missing file as an empty table -- that would turn every lookup into a
# silent miss.
MODEL_ALIASES_FILE=/nonexistent/no-such-table.yml bash "$R" "glm 5.2" >/dev/null 2>&1; guard_rc=$?
[ "$guard_rc" = 2 ] \
  && pass "unreadable table still exits 2 (the -r guard did not become a no-op)" \
  || fail "unreadable table -> rc=$guard_rc (expected 2)"

# The default path is unchanged: no MODEL_ALIASES_FILE still reads the shipped table.
default_out="$(bash "$R" "glm 5.2" 2>/dev/null)"
[ "$default_out" = "z-ai/glm-5.2" ] \
  && pass "shipped table remains the default when MODEL_ALIASES_FILE is unset" \
  || fail "default table regressed: got '$default_out'"

echo "  model-alias: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
