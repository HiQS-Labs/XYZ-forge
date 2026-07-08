#!/usr/bin/env bash
# test/relay-uncited-findings.sh — GH-173 B3: mechanically prove rtl_check_uncited_findings() catches
# an uncited [Pass]/"verified" Reviewer claim and downgrades it in place, while leaving a genuinely
# cited finding (quote or file:line, within the window) untouched — and that the downgrade itself is
# NOT re-flagged on a later pass (the word "verified" is a substring of "Unverified").
source "$(dirname "$0")/_setup.sh" relay-uncited-findings

LIB="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-turn-lib.sh"
# shellcheck source=relay-automation/relay-turn-lib.sh
source "$LIB"

F="$A/findings.md"

# --- 1. uncited [Pass] -> downgraded ----------------------------------------------------------------
cat >"$F" <<'EOF'
## Log
- [Pass] the retry logic looks correct
- [Blocker] missing null check in handler
EOF
rtl_check_uncited_findings "$F"
grep -q '\[Unverified — no citation\] the retry logic looks correct' "$F" \
  && pass "uncited [Pass] downgraded to [Unverified — no citation]" \
  || fail "uncited [Pass] NOT downgraded: $(cat "$F")"
grep -q '^\- \[Blocker\] missing null check' "$F" \
  && pass "unrelated [Blocker] line left untouched" \
  || fail "[Blocker] line was mutated: $(cat "$F")"

# --- 2. [Pass] with an inline quoted citation -> untouched ------------------------------------------
cat >"$F" <<'EOF'
## Log
- [Pass] retry is bounded, see "for i in range(MAX_RETRIES)"
EOF
rtl_check_uncited_findings "$F"
grep -q '^\- \[Pass\] retry is bounded' "$F" \
  && pass "[Pass] with an inline quote left untouched" \
  || fail "cited [Pass] was wrongly downgraded: $(cat "$F")"

# --- 3. [Pass] with a file:line citation on the NEXT line (within window) -> untouched ---------------
cat >"$F" <<'EOF'
## Log
- [Pass] input is validated before use
  see relay-automation/consult.sh:266
EOF
rtl_check_uncited_findings "$F"
grep -q '^\- \[Pass\] input is validated' "$F" \
  && pass "[Pass] with a file:line citation on the next line left untouched" \
  || fail "file:line-cited [Pass] was wrongly downgraded: $(cat "$F")"

# --- 4. bare prose "verified" with no citation -> flagged --------------------------------------------
cat >"$F" <<'EOF'
## Log
ANSWER: I verified the change works as described.
EOF
rtl_check_uncited_findings "$F"
grep -q 'I verified the change works as described.  \[Unverified — no citation\]' "$F" \
  && pass "uncited prose 'verified' claim flagged" \
  || fail "uncited prose 'verified' claim NOT flagged: $(cat "$F")"

# --- 5. idempotency: a downgraded line is not re-flagged on a second pass ----------------------------
cp "$F" "$F.before"
rtl_check_uncited_findings "$F"
diff -q "$F.before" "$F" >/dev/null 2>&1 \
  && pass "second pass over an already-downgraded line is a no-op (idempotent)" \
  || fail "second pass mutated an already-downgraded line: $(cat "$F")"

# --- 6. rtl_init captures RTL_WAS_REVIEWER_TURN before NEXT can flip ----------------------------------
RELAY_R="$A/relay-reviewer.md"
printf 'NEXT: Reviewer\nSTATUS: Open\n' >"$RELAY_R"
rtl_init "$A" "$RELAY_R" ""
[ "${RTL_WAS_REVIEWER_TURN:-0}" = "1" ] && pass "rtl_init sets RTL_WAS_REVIEWER_TURN=1 on a Reviewer turn" \
  || fail "RTL_WAS_REVIEWER_TURN not set on a Reviewer turn"

RELAY_P="$A/relay-producer.md"
printf 'NEXT: Producer\nSTATUS: Open\n' >"$RELAY_P"
rtl_init "$A" "$RELAY_P" ""
[ "${RTL_WAS_REVIEWER_TURN:-0}" = "0" ] && pass "rtl_init sets RTL_WAS_REVIEWER_TURN=0 on a Producer turn" \
  || fail "RTL_WAS_REVIEWER_TURN wrongly set on a Producer turn"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
