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

# --- GH-450 (Model-catalog Phase 1, relay QA r2 F2b): tier-4 post-correction guard ---
#
# The catalog's CI rule forbids two rows where one's squashed key is a substring of the other's
# canonical id — that is the shape under which tier 4 (squashed substring, EITHER direction)
# would capture an exact-ID query. What no data rule can see is a PIN CORRECTION: once
# `deepseek v4 pro` is repinned to `.../deepseek-v4-pro-2`, the OLD exact id
# `deepseek/deepseek-v4-pro` has left the data but still contains the row's squashed key, so a
# caller that hands it to the raw resolver is silently redirected to the new pin.
#
# Two assertions, deliberately: (1) pin what the RAW resolver does — it captures, and this test
# says so out loud rather than leaving it a surprise (resolve-model-alias.sh is untouched by
# GH-450 on purpose: no Bash-parses-JSON, no GH-551 adjacency); (2) the guard that makes it
# impossible in practice lives at utils/py/model_alias.py:resolve_model_slug, the ONE seam every
# shim resolves through — an exact-ID form (`provider/slug`) never reaches the fuzzy table.
CORRECTED_TABLE=$'deepseek v4 pro: deepseek/deepseek-v4-pro-2\n'
GUARD_TABLE_FILE="${TMPDIR:-/tmp}/model-alias-gh450-$$.yml"
printf '%s' "$CORRECTED_TABLE" > "$GUARD_TABLE_FILE"

raw_out="$(printf '%s' "$CORRECTED_TABLE" | MODEL_ALIASES_FILE=/dev/stdin bash "$R" "deepseek/deepseek-v4-pro" 2>/dev/null)"; raw_rc=$?
{ [ "$raw_rc" = 0 ] && [ "$raw_out" = "deepseek/deepseek-v4-pro-2" ]; } \
  && pass "tier-4 documented: the RAW resolver captures the old exact id after a repin ('deepseek/deepseek-v4-pro' -> $raw_out) — this is why the seam guard below exists" \
  || fail "raw tier-4 behavior changed: rc=$raw_rc out='$raw_out' (resolve-model-alias.sh must be untouched by GH-450; if this moved, re-read Model-catalog PROJECT.md Phase 1)"

seam_out="$(MODEL_ALIASES_FILE="$GUARD_TABLE_FILE" python3 -c "
import sys; sys.path.insert(0, '$HERE/../utils/py')
from model_alias import resolve_model_slug
print(resolve_model_slug('deepseek/deepseek-v4-pro', '$HERE/..'))" 2>/dev/null)"
[ "$seam_out" = "deepseek/deepseek-v4-pro" ] \
  && pass "tier-4 guard: the Python seam returns an exact id UNCHANGED even when a repinned row would capture it" \
  || fail "tier-4 guard: exact id 'deepseek/deepseek-v4-pro' was redirected to '$seam_out' at the seam"

# The guard must not have broken the seam's alias path: a colloquial name against the same
# corrected table still resolves to the NEW pin (the correction is the point of a correction).
seam_alias="$(MODEL_ALIASES_FILE="$GUARD_TABLE_FILE" python3 -c "
import sys; sys.path.insert(0, '$HERE/../utils/py')
from model_alias import resolve_model_slug
print(resolve_model_slug('DeepSeek V4 Pro', '$HERE/..'))" 2>/dev/null)"
[ "$seam_alias" = "deepseek/deepseek-v4-pro-2" ] \
  && pass "tier-4 guard: a colloquial name still resolves to the corrected pin through the seam" \
  || fail "seam alias path regressed: 'DeepSeek V4 Pro' -> '$seam_alias'"
rm -f "$GUARD_TABLE_FILE"

# --- GH-450 terminal-refusal control (Model-catalog consumer contract item 2) ---
#
# Lookup miss != refusal. A miss passes the value through UNRESOLVED to the shim's own validation
# (the gateway rejects an unknown model at dispatch — that is the terminal refusal, and it is
# never a default). This control is the named negative for that contract on the XYZ side, at both
# layers: the resolver says nothing on a miss (no output, exit 1 — never a fallback row), and the
# seam hands the input back byte-for-byte (never blank, never a substituted default). Mutating
# either — a catch-all row, a default on miss — turns this red; that is what it is for.
refusal_in="no-such-model-gh450-control"
refusal_raw="$(bash "$R" "$refusal_in" 2>/dev/null)"; refusal_rc=$?
{ [ "$refusal_rc" = 1 ] && [ -z "$refusal_raw" ]; } \
  && pass "terminal-refusal control: resolver miss is exit 1 with NO output (no default row can answer)" \
  || fail "terminal-refusal control: resolver answered a miss: rc=$refusal_rc out='$refusal_raw'"
refusal_seam="$(python3 -c "
import sys; sys.path.insert(0, '$HERE/../utils/py')
from model_alias import resolve_model_slug
print(resolve_model_slug('$refusal_in', '$HERE/..'))" 2>/dev/null)"
[ "$refusal_seam" = "$refusal_in" ] \
  && pass "terminal-refusal control: the seam passes an unknown name through unresolved (never a default, never blank) for the gateway to refuse" \
  || fail "terminal-refusal control: seam turned '$refusal_in' into '$refusal_seam'"

echo "  model-alias: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
