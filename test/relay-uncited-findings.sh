#!/usr/bin/env bash
# test/relay-uncited-findings.sh — GH-173 B3: mechanically prove rtl_check_uncited_findings() catches
# an uncited [Pass]/"verified" Reviewer claim and downgrades it in place, while leaving a genuinely
# cited finding (quote or file:line, within the window) untouched — and that the downgrade itself is
# NOT re-flagged on a later pass (the word "verified" is a substring of "Unverified"). Also covers the
# code-review follow-up on PR #184: the widened RTL_CLAIM_WORD_RE trigger vocabulary (item 2), the
# shared rtl_has_uncited_claim() read-only predicate consult.sh's A4 stamp now reuses (items 1 & 3),
# and a regression guard (test 10) for the awk -v \[Pass\] corruption that follow-up briefly
# introduced and a subsequent review pass caught.
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
# Anchored at BOTH ends (not a prefix-only grep) — a prefix match would still "pass" if the line got
# an [Unverified — no citation] suffix appended, which is exactly the regression a code-review
# follow-up caught here: passing \[Pass\] through `awk -v` (rather than as an inline /regex/ literal)
# silently corrupts it into a [Pass] BRACKET EXPRESSION under macOS's default awk, matching almost
# any line containing a P/a/s character — including this one ("handler" has an 'a'). A prefix-only
# check would not have caught that; see RTL_CLAIM_WORD_RE's warning comment in relay-turn-lib.sh.
grep -qx '\- \[Blocker\] missing null check in handler' "$F" \
  && pass "unrelated [Blocker] line left byte-for-byte untouched" \
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

# --- 7. code-review follow-up (item 2): widened trigger vocabulary catches an uncited claim that uses
# none of the original 3 words ([Pass]/verified/confirmed) --------------------------------------------
cat >"$F" <<'EOF'
## Log
- [Should] consider renaming this variable
- Overall this looks good, no issues found, LGTM
EOF
rtl_check_uncited_findings "$F"
grep -q 'Overall this looks good, no issues found, LGTM  \[Unverified — no citation\]' "$F" \
  && pass "widened trigger vocabulary (looks good / no issues / LGTM) flags an uncited prose claim" \
  || fail "widened trigger vocabulary NOT flagged: $(cat "$F")"
grep -q '^\- \[Should\] consider renaming' "$F" \
  && pass "unrelated [Should] line left untouched by the widened vocabulary" \
  || fail "[Should] line was mutated: $(cat "$F")"

# --- 8. same widened-vocabulary claim, but cited -> left untouched (non-regression) --------------------
cat >"$F" <<'EOF'
## Log
- This checks out, see relay-automation/consult.sh:266
EOF
rtl_check_uncited_findings "$F"
grep -q '^\- This checks out, see relay-automation/consult.sh:266$' "$F" \
  && pass "widened-vocabulary claim with a file:line citation left untouched" \
  || fail "cited widened-vocabulary claim was wrongly downgraded: $(cat "$F")"

# --- 9. code-review follow-up (items 1 & 3): rtl_has_uncited_claim() — the read-only predicate
# consult.sh's A4 stamp now shares with B3 — flags a transcript with an uncited claim even when SOME
# unrelated citation exists elsewhere in the same file (the gap the review flagged: the old consult.sh
# check only asked "any citation anywhere", so one incidental early citation excused later uncited
# claims). It also still flags a transcript with zero citations anywhere (the original A4 spec), and
# does NOT flag a transcript where every claim is cited near itself. ------------------------------------
PARTIAL="$A/partial-cite.md"
cat >"$PARTIAL" <<'EOF'
ANSWER: confirmed by "return true always" at relay-automation/consult.sh:266.
Later: [Pass] this other part also looks fine
RECOMMENDATION: ship
EOF
rtl_has_uncited_claim "$PARTIAL" \
  && pass "rtl_has_uncited_claim flags a later uncited claim despite an earlier unrelated citation" \
  || fail "rtl_has_uncited_claim missed a later uncited claim: $(cat "$PARTIAL")"

NOCITE="$A/no-cite.md"
cat >"$NOCITE" <<'EOF'
ANSWER: this looks correct.
[Pass] no issues found
RECOMMENDATION: ship
EOF
rtl_has_uncited_claim "$NOCITE" \
  && pass "rtl_has_uncited_claim flags a transcript with zero citations anywhere" \
  || fail "rtl_has_uncited_claim missed a fully-uncited transcript: $(cat "$NOCITE")"

FULLYCITED="$A/fully-cited.md"
cat >"$FULLYCITED" <<'EOF'
ANSWER: confirmed by "return true always" at relay-automation/consult.sh:266.
[Pass] verified — see relay-automation/consult.sh:266
RECOMMENDATION: ship
EOF
rtl_has_uncited_claim "$FULLYCITED" \
  && fail "rtl_has_uncited_claim wrongly flagged a transcript where every claim is cited near itself: $(cat "$FULLYCITED")" \
  || pass "rtl_has_uncited_claim does not flag a transcript where every claim is cited near itself"

# --- 10. regression guard: the [Pass] tag check must never be passed through `awk -v` -------------------
# macOS's default /usr/bin/awk ("one true awk") string-unescapes a -v value before compiling it as a
# dynamic regex, so a -v-passed \[Pass\] silently becomes the bracket EXPRESSION [Pass] — "any single
# P, a, or s character" — instead of the literal tag, matching almost every line. A widened-vocabulary
# follow-up on PR #184 introduced exactly this regression (caught in the SAME review pass, before it
# reached main); this test pins the fix by feeding a line with plenty of P/a/s characters and NONE of
# the real trigger words/tags, and asserting it is left completely untouched.
cat >"$F" <<'EOF'
## Log
- A plain sentence with the letters P, a, and s scattered around it, and no real claim at all
EOF
rtl_check_uncited_findings "$F"
grep -qx '\- A plain sentence with the letters P, a, and s scattered around it, and no real claim at all' "$F" \
  && pass "a P/a/s-heavy non-claim line is left byte-for-byte untouched (no awk -v [Pass] corruption)" \
  || fail "P/a/s-heavy line was wrongly flagged — the awk -v \\[Pass\\] corruption regressed: $(cat "$F")"

# Same corruption class, exercised through rtl_has_uncited_claim(). A citation is included elsewhere
# in the file (any_cite=1) specifically to rule OUT "zero citations anywhere" (the function's other,
# intentional flag condition) as the reason it would flag this file — isolating the assertion to the
# P/a/s corruption specifically.
PASCORRUPT="$A/pas-corruption.md"
cat >"$PASCORRUPT" <<'EOF'
## Log
- A plain sentence with the letters P, a, and s scattered around it, and no real claim at all
- Actually cited elsewhere: see relay-automation/consult.sh:266
EOF
rtl_has_uncited_claim "$PASCORRUPT" \
  && fail "rtl_has_uncited_claim wrongly flagged a P/a/s-heavy non-claim line — the awk -v corruption regressed: $(cat "$PASCORRUPT")" \
  || pass "rtl_has_uncited_claim does not flag a P/a/s-heavy non-claim line (no awk -v [Pass] corruption)"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
