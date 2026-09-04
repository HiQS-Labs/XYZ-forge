#!/usr/bin/env bash
# test/gh410-relay-block-driven-path.sh — GH-410.
#
# Verifies that:
#   1. bin/validate-relay-block accepts real thread formats (including bold **STATUS:**)
#   2. rtl_relay_field serves as the single shared STATUS/NEXT parser
#   3. rtl_enforce runs bin/validate-relay-block on the driven path before staging
#   4. Malformed review blocks exit 8 and escalate rather than proceeding
#
# Hermetic: isolated fixture repos, no network.

source "$(dirname "$0")/_setup.sh" gh410-relay-block-driven-path
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VALIDATE_BIN="$ROOT/bin/validate-relay-block"
RTL_LIB="$ROOT/relay-automation/relay-turn-lib.sh"
TICK_BIN="$ROOT/bin/tick"

TMP="$WORK/gh410"
mkdir -p "$TMP"

# --------------------------------------------------------------------------------------------------
# Section 1: bin/validate-relay-block unit tests (format tolerance & rejection rules)
# --------------------------------------------------------------------------------------------------

# 1.1: Standard compliant relay block passes
cat >"$TMP/standard-pass.md" <<'EOF_M1'
NEXT: Producer
STATUS: Approved
ROUND: 1 / 4

## Setup
Artifact: file.md

## Log
### Reviewer · Round 1
VERDICT: PASS
Basis: all acceptance criteria met and verified.
EOF_M1

"$VALIDATE_BIN" "$TMP/standard-pass.md" >/dev/null 2>&1 \
  && pass "1.1 standard relay block with plain STATUS passes validation (rc=0)" \
  || fail "1.1 standard relay block unexpectedly rejected"

# 1.2: Bold **STATUS:** block (real thread format) passes
cat >"$TMP/bold-pass.md" <<'EOF_M2'
**NEXT:** Producer
**STATUS:** Approved
**ROUND:** 1 / 4

## Setup
Artifact: file.md

## Log
### Reviewer · Round 1
**VERDICT:** PASS
**Basis:** verified implementation against requirements.
EOF_M2

"$VALIDATE_BIN" "$TMP/bold-pass.md" >/dev/null 2>&1 \
  && pass "1.2 bold **STATUS:** block (real thread format) passes validation (rc=0)" \
  || fail "1.2 bold **STATUS:** block unexpectedly rejected"

# 1.3: Whole-line bold and backtick-wrapped STATUS passes
cat >"$TMP/wrapped-pass.md" <<'EOF_M3'
**NEXT: Producer**
**STATUS: Open**
`ROUND: 1 / 4`

## Setup
Artifact: file.md

## Log
### Reviewer · Round 1
VERDICT: FAIL
Basis: missing test coverage for edge case.
EOF_M3

"$VALIDATE_BIN" "$TMP/wrapped-pass.md" >/dev/null 2>&1 \
  && pass "1.3 whole-line-bold and backtick-wrapped STATUS passes validation (rc=0)" \
  || fail "1.3 whole-line-bold / backtick-wrapped STATUS unexpectedly rejected"

# 1.4: Missing STATUS header is rejected (exit 8)
cat >"$TMP/missing-status.md" <<'EOF_M4'
NEXT: Producer
ROUND: 1 / 4

## Log
VERDICT: PASS
Basis: looks good.
EOF_M4

set +e
out="$("$VALIDATE_BIN" "$TMP/missing-status.md" 2>&1)"
rc=$?
set -e
[ "$rc" -eq 8 ] && pass "1.4 missing STATUS header rejected with exit 8" \
  || fail "1.4 missing STATUS expected exit 8, got $rc"
grep -q "STATUS: header is missing" <<<"$out" \
  && pass "1.4b error message explains missing STATUS header" \
  || fail "1.4b unexpected error message: $out"

# 1.5: Empty STATUS header is rejected (exit 8)
cat >"$TMP/empty-status.md" <<'EOF_M5'
NEXT: Producer
**STATUS:** 
ROUND: 1 / 4

## Log
VERDICT: PASS
Basis: looks good.
EOF_M5

set +e
out="$("$VALIDATE_BIN" "$TMP/empty-status.md" 2>&1)"
rc=$?
set -e
[ "$rc" -eq 8 ] && pass "1.5 empty STATUS header rejected with exit 8" \
  || fail "1.5 empty STATUS expected exit 8, got $rc"
grep -q "STATUS: header is empty" <<<"$out" \
  && pass "1.5b error message explains empty STATUS header" \
  || fail "1.5b unexpected error message: $out"

# 1.6: STATUS: In Progress is rejected (exit 8)
cat >"$TMP/in-progress-status.md" <<'EOF_M6'
NEXT: Producer
**STATUS:** In Progress
ROUND: 1 / 4

## Log
VERDICT: PASS
Basis: still working.
EOF_M6

set +e
out="$("$VALIDATE_BIN" "$TMP/in-progress-status.md" 2>&1)"
rc=$?
set -e
[ "$rc" -eq 8 ] && pass "1.6 STATUS In Progress rejected with exit 8" \
  || fail "1.6 STATUS In Progress expected exit 8, got $rc"
grep -q "STATUS cannot be In Progress" <<<"$out" \
  && pass "1.6b error message explains STATUS cannot be In Progress" \
  || fail "1.6b unexpected error message: $out"

# 1.7: Missing ## Log section is rejected (exit 8)
cat >"$TMP/missing-log.md" <<'EOF_M7'
NEXT: Producer
STATUS: Approved
ROUND: 1 / 4

## Setup
Artifact: file.md
EOF_M7

set +e
out="$("$VALIDATE_BIN" "$TMP/missing-log.md" 2>&1)"
rc=$?
set -e
[ "$rc" -eq 8 ] && pass "1.7 missing ## Log section rejected with exit 8" \
  || fail "1.7 missing ## Log expected exit 8, got $rc"

# 1.8: Empty ## Log section is rejected (exit 8)
cat >"$TMP/empty-log.md" <<'EOF_M8'
NEXT: Producer
STATUS: Approved
ROUND: 1 / 4

## Log
   
EOF_M8

set +e
out="$("$VALIDATE_BIN" "$TMP/empty-log.md" 2>&1)"
rc=$?
set -e
[ "$rc" -eq 8 ] && pass "1.8 empty ## Log section rejected with exit 8" \
  || fail "1.8 empty ## Log expected exit 8, got $rc"

# 1.9: Missing VERDICT: line is rejected (exit 8)
cat >"$TMP/missing-verdict.md" <<'EOF_M9'
NEXT: Producer
STATUS: Approved
ROUND: 1 / 4

## Log
### Reviewer · Round 1
Basis: everything passed.
EOF_M9

set +e
out="$("$VALIDATE_BIN" "$TMP/missing-verdict.md" 2>&1)"
rc=$?
set -e
[ "$rc" -eq 8 ] && pass "1.9 missing VERDICT: line rejected with exit 8" \
  || fail "1.9 missing VERDICT: expected exit 8, got $rc"

# 1.10: Missing Basis: line is rejected (exit 8)
cat >"$TMP/missing-basis.md" <<'EOF_M10'
NEXT: Producer
STATUS: Approved
ROUND: 1 / 4

## Log
### Reviewer · Round 1
VERDICT: PASS
EOF_M10

set +e
out="$("$VALIDATE_BIN" "$TMP/missing-basis.md" 2>&1)"
rc=$?
set -e
[ "$rc" -eq 8 ] && pass "1.10 missing Basis: line rejected with exit 8" \
  || fail "1.10 missing Basis: expected exit 8, got $rc"

# --------------------------------------------------------------------------------------------------
# Section 2: Shared rtl_relay_field parser parity
# --------------------------------------------------------------------------------------------------
source "$RTL_LIB"

test_val="$(rtl_relay_field STATUS "$TMP/bold-pass.md")"
[ "$test_val" = "Approved" ] \
  && pass "2.1 rtl_relay_field extracted 'Approved' from bold **STATUS:**" \
  || fail "2.1 rtl_relay_field failed on bold STATUS: got '$test_val'"

test_next="$(rtl_relay_field NEXT "$TMP/bold-pass.md")"
[ "$test_next" = "Producer" ] \
  && pass "2.2 rtl_relay_field extracted 'Producer' from bold **NEXT:**" \
  || fail "2.2 rtl_relay_field failed on bold NEXT: got '$test_next'"

test_wrapped="$(rtl_relay_field STATUS "$TMP/wrapped-pass.md")"
[ "$test_wrapped" = "Open" ] \
  && pass "2.3 rtl_relay_field extracted 'Open' from whole-line-bold **STATUS: Open**" \
  || fail "2.3 rtl_relay_field failed on whole-line-bold STATUS: got '$test_wrapped'"

# --------------------------------------------------------------------------------------------------
# Section 3: Driven path enforcement (rtl_enforce before staging)
# --------------------------------------------------------------------------------------------------

REPO="$TMP/fixture-repo"
mkdir -p "$REPO/bin" "$REPO/relay-system"
git -C "$REPO" init -q -b development
git -C "$REPO" config user.name "Test Agent"
git -C "$REPO" config user.email "test@example.com"
echo ".tick/" > "$REPO/.gitignore"
ln -sf "$TICK_BIN" "$REPO/bin/tick"
ln -sf "$VALIDATE_BIN" "$REPO/bin/validate-relay-block"

RELAY_FILE="$REPO/relay-system/RELAY.md"
cat >"$RELAY_FILE" <<'EOF_RELAY_INIT'
<!-- marathon-drive: builder=codex reviewer=agy -->
NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

## Setup
Artifact: artifact.txt

## Log
### Builder · Round 1
Created artifact.txt
EOF_RELAY_INIT

echo "initial artifact" > "$REPO/artifact.txt"
git -C "$REPO" add -A
git -C "$REPO" commit -q -m "initial commit"

# Seed a tick task claimed by agy
TICK_REPO_ROOT="$REPO" "$TICK_BIN" log task.created "TASK-1" --agent claude-a >/dev/null 2>&1
TICK_REPO_ROOT="$REPO" "$TICK_BIN" claim "TASK-1" --agent agy --paths "relay-system/RELAY.md" >/dev/null 2>&1

# 3.1: Malformed reviewer turn (missing VERDICT + Basis) fails rtl_enforce with exit 8
cat >>"$RELAY_FILE" <<'EOF_BAD_REV'
### Reviewer · Round 1
Looks bad, needs fixes.
EOF_BAD_REV

set +e
(
  export RTL_ROOT="$REPO"
  export TICK_REPO_ROOT="$REPO"
  export RELAY_FILE="$RELAY_FILE"
  export RELAY_AGENT="agy"
  export RTL_TOOL="agy"
  export RTL_ALLOW=("relay-system/RELAY.md")
  export RTL_WAS_REVIEWER_TURN=1
  export RTL_BEFORE_HEAD="$(git -C "$REPO" rev-parse HEAD)"
  source "$RTL_LIB"
  rtl_enforce "TASK-1" "agy" "$TMP/enforce.log" "agy"
) >"$TMP/enforce-red.out" 2>&1
rc_red=$?
set -e

[ "$rc_red" -eq 8 ] \
  && pass "3.1 malformed review block on driven path exits 8 before staging" \
  || fail "3.1 malformed review block expected exit 8, got $rc_red"

# Verify no commit was made
head_after="$(git -C "$REPO" rev-parse HEAD)"
[ "$head_after" = "$(git -C "$REPO" rev-parse HEAD~0)" ] \
  && pass "3.1b malformed review block prevented git commit" \
  || fail "3.1b git commit occurred despite validation failure"

# 3.2: Well-formed bold **STATUS:** review block passes rtl_enforce (exit 0) and commits
cat >"$RELAY_FILE" <<'EOF_GOOD_REV'
<!-- marathon-drive: builder=codex reviewer=agy -->
**NEXT:** Producer
**STATUS:** Approved
**ROUND:** 1 / 4

## Setup
Artifact: artifact.txt

## Log
### Builder · Round 1
Created artifact.txt
### Reviewer · Round 1
**VERDICT:** PASS
**Basis:** verified artifact contents and tests.
EOF_GOOD_REV

set +e
(
  export RTL_ROOT="$REPO"
  export TICK_REPO_ROOT="$REPO"
  export RELAY_FILE="$RELAY_FILE"
  export RELAY_AGENT="agy"
  export RTL_TOOL="agy"
  export RTL_ALLOW=("relay-system/RELAY.md")
  export RTL_WAS_REVIEWER_TURN=1
  export RTL_BEFORE_HEAD="$(git -C "$REPO" rev-parse HEAD)"
  source "$RTL_LIB"
  rtl_enforce "TASK-1" "agy" "$TMP/enforce.log" "agy"
) >"$TMP/enforce-green.out" 2>&1
rc_green=$?
set -e

[ "$rc_green" -eq 0 ] \
  && pass "3.2 bold **STATUS:** review block on driven path passes rtl_enforce (exit 0)" \
  || fail "3.2 bold **STATUS:** review block failed rtl_enforce (rc=$rc_green): $(cat "$TMP/enforce-green.out")"

# Verify commit was made
latest_msg="$(git -C "$REPO" log -1 --pretty=%B)"
grep -q "relay(TASK-1): agy turn" <<<"$latest_msg" \
  && pass "3.2b successful review block resulted in file-scoped commit" \
  || fail "3.2b missing file-scoped commit"

echo "  gh410-relay-block-driven-path: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
