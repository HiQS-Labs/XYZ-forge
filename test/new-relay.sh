#!/usr/bin/env bash
# new-relay.sh — GH-31 Phase 4 (scaffolder) + Phase 3 (fence-safe embed). new-relay.sh emits a relay
# thread the harness can drive (NEXT:/STATUS:/TAKE YOUR TURN/Setup/Log), in two artifact modes:
#   - reference: Setup points at .relay-artifacts/<basename> (the read-only seed path, GH-31 Phase 2)
#   - --embed:   inline the artifact in a fence LONGER than any backtick run inside it (no fence collision)
source "$(dirname "$0")/_setup.sh" new-relay
NR="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/new-relay.sh"

# --- (1) reference mode: required fields present, artifact referenced at the seed path -------------
out1="$(bash "$NR" --title "Review My PR" --reviewer codex --artifact-file /tmp/some-pr.diff --print)"
printf '%s' "$out1" | grep -q '^NEXT: Reviewer$'      && pass "emits NEXT: Reviewer" || fail "missing NEXT (out: $out1)"
printf '%s' "$out1" | grep -q '^STATUS: Open$'        && pass "emits STATUS: Open" || fail "missing STATUS"
printf '%s' "$out1" | grep -q '▶ TAKE YOUR TURN'      && pass "emits the TAKE YOUR TURN block" || fail "missing turn block"
printf '%s' "$out1" | grep -q '.relay-artifacts/some-pr.diff' && pass "references the read-only seed path" || fail "missing seed-path reference"
printf '%s' "$out1" | grep -q 'Reviewer: codex'       && pass "names the reviewer" || fail "missing reviewer"
printf '%s' "$out1" | grep -q '## Log'                && pass "emits a Log section" || fail "missing Log"

# --- (2) slug derived from title; default out path under relay-system/<date>/ ----------------------
out_path="$(cd "$A" && bash "$NR" --title "Review My PR" --reviewer agy 2>/dev/null)"
case "$out_path" in
  relay-system/*/review-my-pr.md) pass "derives slug + dated default path" ;;
  *) fail "unexpected out path: $out_path" ;;
esac
[ -f "$A/$out_path" ] && pass "writes the thread file" || fail "thread file not written"

# --- (3) FENCE-SAFE embed: artifact contains a 3-backtick fence → outer fence must be >=4 ----------
ART="$WORK/nested.diff"
printf 'diff --git a/x b/x\n+```\n+inner fenced block\n+```\n' >"$ART"   # inner run = 3 backticks
out3="$(bash "$NR" --title "Nested" --reviewer codex --artifact-file "$ART" --embed --print)"
# the opening fence the scaffolder chose: first line that is ONLY backticks
fence_line="$(printf '%s\n' "$out3" | grep -E '^`+$' | head -1)"
flen="${#fence_line}"
[ "$flen" -ge 4 ] && pass "embed fence ($flen backticks) exceeds the inner 3-backtick run" || fail "fence too short ($flen) — collision risk"
printf '%s' "$out3" | grep -q 'inner fenced block' && pass "artifact body is embedded" || fail "artifact not embedded"
printf '%s' "$out3" | grep -q 'embedded below' && pass "Setup marks the artifact embedded" || fail "missing embedded marker"

# --- (4) a 5-backtick run inside → fence must be >=6 (fence_for scales) ----------------------------
ART2="$WORK/deep.txt"
printf 'text\n`````\ncode\n`````\n' >"$ART2"   # inner run = 5 backticks
out4="$(bash "$NR" --title "Deep" --reviewer agy --artifact-file "$ART2" --embed --print)"
fence_line4="$(printf '%s\n' "$out4" | grep -E '^`+$' | head -1)"
[ "${#fence_line4}" -ge 6 ] && pass "fence scales past a 5-backtick run (${#fence_line4} >= 6)" || fail "fence did not scale (${#fence_line4})"

# --- (5) usage guards --------------------------------------------------------------------------------
bash "$NR" --reviewer codex --print >/dev/null 2>&1 && fail "missing --title should error" || pass "errors without --title"
bash "$NR" --title T --reviewer codex --embed --print >/dev/null 2>&1 && fail "--embed without artifact should error" || pass "errors on --embed without --artifact-file"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
