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

echo "  model-alias: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
