#!/usr/bin/env bash
# #129 — relay-drive: unset TICK_REPO_ROOT reported "token missing" (wrong cause) and the
# escalation exited 0 on the snapshot that reported the incident. Two halves:
#
#   1. SELF-RESOLUTION — when TICK_REPO_ROOT is unset, relay-drive resolves it the way the turn
#      shims root themselves (CWD's git toplevel, else the harness root) and exports it, so the
#      driver and the seeding shell cannot disagree by construction on a vendored-.xyz layout.
#   2. DIAGNOSTIC + EXIT — when the task is not found in the resolved tick log, the failure names
#      the root actually used and the event dir actually searched (instead of "token missing"),
#      and every escalation path exits 4 — never 0. The exit-0 half was observed on an older
#      vendored snapshot; the current tree must stay pinned at 4.
#
# Drives utils/py/relay_drive.py directly (the authoritative lane per GH-308). The harness clone
# is only READ here: tick state lives in per-case fixture repos under $WORK, and
# RELAY_DRIVER_LOCKED=1 keeps the driver off the clone's real driver lock.
#
# Usage: bash test/synthetic/gh129-relay-tick-root.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/../.." && pwd)"
TICK="$ROOT_DIR/bin/tick"
DRIVE_PY="$ROOT_DIR/utils/py/relay_drive.py"
PY="${PYTHON:-python3}"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh129-tick-root.XXXXXX")"
trap '[ -n "$WORK" ] && [ -d "$WORK" ] && rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); [ "${TEST_SOFT_FAIL:-0}" = "1" ] || { echo "gh129: $PASS passed, $FAIL failed"; exit 1; }; }

# GH-567: validate a fixture path at the USE boundary — non-empty, inside $WORK, no "..", and
# actually a directory. A variable that was safe at mktemp time can be empty here.
require_fixture() {
  local p="${1:-}"
  case "$p" in
    ""|"$WORK"|"$WORK"..*|*..*) fail "invalid fixture path '$p' (empty, sandbox root, or contains ..)"; return 1 ;;
    "$WORK"/*) [ -d "$p" ] || { fail "fixture is not a directory: $p"; return 1; } ;;
    *) fail "fixture escaped the sandbox root $WORK: $p"; return 1 ;;
  esac
}

# mk_fixture <name> — a fresh git repo standing in for the repo a seeding shell would have used.
mk_fixture() {
  local d="$WORK/$1"
  git init -q "$d"
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  printf 'seed\n' >"$d/seed.txt"
  git -C "$d" add seed.txt >/dev/null
  git -C "$d" commit -q -m seed
  printf '%s' "$d"
}

# seed_token <repo> <task> — the SKILL.md seeding recipe: create, claim, release to the actor.
seed_token() {
  local repo="$1" task="$2"
  require_fixture "$repo" || return 1
  TICK_REPO_ROOT="$repo" "$TICK" log task.created "$task" --agent claude-a >/dev/null 2>&1
  TICK_REPO_ROOT="$repo" "$TICK" claim "$task" --agent claude-a --paths "$repo/RELAY-$task.md" >/dev/null 2>&1
  TICK_REPO_ROOT="$repo" "$TICK" release "$task" --agent claude-a --to aider >/dev/null 2>&1
}

# claim_token <repo> <task> — create + claim only: a LIVE claim under a terminal file status.
claim_token() {
  local repo="$1" task="$2"
  require_fixture "$repo" || return 1
  TICK_REPO_ROOT="$repo" "$TICK" log task.created "$task" --agent claude-a >/dev/null 2>&1
  TICK_REPO_ROOT="$repo" "$TICK" claim "$task" --agent claude-a --paths "$repo/RELAY-$task.md" >/dev/null 2>&1
}

mk_relay() { # <path> <status>
  printf 'STATUS: %s\n\n# Relay\n\n## Log\n' "$2" >"$1"
}

# run_drive <cwd> <relay-file> <task> <extra-args...> — capture rc + stderr.
run_drive() {
  local cwd="$1" rf="$2" task="$3"; shift 3
  ( cd "$cwd" && RELAY_DRIVER_LOCKED=1 XYZ_HARNESS_CONTEXT=gh129-test \
      "$PY" "$DRIVE_PY" --relay-file "$rf" --relay-task "$task" --dry-run "$@" ) \
      >"$WORK/last.out" 2>"$WORK/last.err"
  RC=$?
}

echo "=== 1. self-resolution: unset TICK_REPO_ROOT still finds the seeded token ==="
R1="$(mk_fixture r1)"; require_fixture "$R1" || exit 1
seed_token "$R1" RELAY-GH129-SELF
mk_relay "$R1/RELAY-GH129-SELF.md" Open
( unset TICK_REPO_ROOT; cd "$R1" && \
    RELAY_DRIVER_LOCKED=1 XYZ_HARNESS_CONTEXT=gh129-test \
    "$PY" "$DRIVE_PY" --relay-file "$R1/RELAY-GH129-SELF.md" \
    --relay-task RELAY-GH129-SELF --dry-run ) >"$WORK/c1.out" 2>"$WORK/c1.err"
rc1=$?
# The functional proof: the token lives ONLY in $R1's log, so finding the actor at all proves the
# driver resolved TICK_REPO_ROOT to the seeder's repo instead of silently defaulting elsewhere.
grep -q "WOULD drive turn for agent: aider" "$WORK/c1.out" \
  && pass "unset TICK_REPO_ROOT self-resolves; seeded token found (actor: aider)" \
  || fail "driver did not find the token seeded in $R1 (out: $(cat "$WORK/c1.out") err: $(cat "$WORK/c1.err"))"
grep -q "self-resolved" "$WORK/c1.err" \
  && pass "self-resolution announces the resolved root on stderr" \
  || fail "no self-resolution NOTE on stderr: $(cat "$WORK/c1.err")"
[ "$rc1" -eq 0 ] && pass "dry-run drive exits 0" || fail "dry-run drive rc=$rc1 (expected 0)"

echo "=== 2. explicit TICK_REPO_ROOT wins (no self-resolution note) ==="
R2="$(mk_fixture r2)"; require_fixture "$R2" || exit 1
seed_token "$R2" RELAY-GH129-EXPLICIT
mk_relay "$R2/RELAY-GH129-EXPLICIT.md" Open
( cd "$R2" && TICK_REPO_ROOT="$R2" RELAY_DRIVER_LOCKED=1 \
    XYZ_HARNESS_CONTEXT=gh129-test "$PY" "$DRIVE_PY" \
    --relay-file "$R2/RELAY-GH129-EXPLICIT.md" \
    --relay-task RELAY-GH129-EXPLICIT --dry-run ) >"$WORK/c2.out" 2>"$WORK/c2.err"
rc2=$?
if ! grep -q "self-resolved" "$WORK/c2.err"; then
  pass "explicit env suppresses the NOTE (not printed)"
else
  fail "self-resolution NOTE fired although TICK_REPO_ROOT was exported"
fi
grep -q "WOULD drive turn for agent: aider" "$WORK/c2.out" \
  && pass "explicit env path finds the token as before" \
  || fail "explicit TICK_REPO_ROOT no longer finds the token (regression)"
[ "$rc2" -eq 0 ] && pass "explicit-env dry-run exits 0" || fail "explicit-env dry-run rc=$rc2"

echo "=== 3. token not found: enriched diagnostic + exit 4 (never 0) ==="
R3="$(mk_fixture r3)"; require_fixture "$R3" || exit 1
mk_relay "$R3/RELAY-GH129-MISSING.md" Open
run_drive "$R3" "$R3/RELAY-GH129-MISSING.md" RELAY-GH129-MISSING
[ "$RC" -eq 4 ] && pass "token-not-found escalation exits 4 (never 0)" \
  || fail "token-not-found escalation rc=$RC (expected 4 — the #129 silent-success pin)"
grep -q "RELAY-GH129-MISSING not found in the resolved tick log" "$WORK/last.err" \
  && pass "diagnostic names the task as not found in the resolved tick log" \
  || fail "missing the not-found header: $(cat "$WORK/last.err")"
grep -q "TICK_REPO_ROOT:" "$WORK/last.err" \
  && pass "diagnostic reports the resolved TICK_REPO_ROOT" \
  || fail "diagnostic does not name TICK_REPO_ROOT"
grep -q "searched:.*\.tick/events" "$WORK/last.err" \
  && pass "diagnostic names the event dir actually searched" \
  || fail "diagnostic does not name the searched event dir"
grep -q 'find-harness.sh --env' "$WORK/last.err" \
  && pass "diagnostic hints the find-harness env eval" \
  || fail "diagnostic missing the find-harness.sh hint"

echo "=== 4. escalation exits: Escalated status and close mismatch both pin at 4 ==="
R4="$(mk_fixture r4)"; require_fixture "$R4" || exit 1
mkdir -p "$WORK/emptylog4"
mk_relay "$R4/RELAY-GH129-ESC.md" Escalated
( cd "$R4" && TICK_REPO_ROOT="$WORK/emptylog4" RELAY_DRIVER_LOCKED=1 \
    XYZ_HARNESS_CONTEXT=gh129-test "$PY" "$DRIVE_PY" \
    --relay-file "$R4/RELAY-GH129-ESC.md" --relay-task RELAY-GH129-ESC --dry-run ) \
    >/dev/null 2>"$WORK/c4.err"
rc4=$?
[ "$rc4" -eq 4 ] && pass "STATUS: Escalated exits 4" || fail "Escalated status rc=$rc4 (expected 4)"

R5="$(mk_fixture r5)"; require_fixture "$R5" || exit 1
claim_token "$R5" RELAY-GH129-MISMATCH   # live claim => actor present
mk_relay "$R5/RELAY-GH129-MISMATCH.md" Approved
( cd "$R5" && TICK_REPO_ROOT="$R5" RELAY_DRIVER_LOCKED=1 \
    XYZ_HARNESS_CONTEXT=gh129-test "$PY" "$DRIVE_PY" \
    --relay-file "$R5/RELAY-GH129-MISMATCH.md" --relay-task RELAY-GH129-MISMATCH --dry-run ) \
    >/dev/null 2>"$WORK/c5.err"
rc5=$?
[ "$rc5" -eq 4 ] && pass "terminal STATUS with live token (close mismatch) exits 4" \
  || fail "close mismatch rc=$rc5 (expected 4)"
grep -q "close mismatch" "$WORK/c5.err" && pass "close mismatch names itself" \
  || fail "close mismatch diagnostic missing: $(cat "$WORK/c5.err")"

echo "=== 5. #136: the lane-attempt gate counts attempts where the token lives ==="
# A non-dry-run drive with the env unset: the gate must append to the SELF-RESOLVED repo's
# .tick/attempts (the caller repo), not silently to the harness clone's — pre-#136 the two
# halves of the cap enforcement fragmented across two locations.
R6="$(mk_fixture r6)"; require_fixture "$R6" || exit 1
TASK6="RELAY-GH129-ATTEMPTS-$$"
mk_relay "$R6/$TASK6.md" Open
( unset TICK_REPO_ROOT; cd "$R6" && RELAY_DRIVER_LOCKED=1 XYZ_HARNESS_CONTEXT=gh129-test \
    "$PY" "$DRIVE_PY" --relay-file "$R6/$TASK6.md" --relay-task "$TASK6" \
    --agent-cmd /bin/true ) >/dev/null 2>"$WORK/c6.err"
rc6=$?
[ "$rc6" -eq 4 ] && pass "unseeded-token drive escalates exit 4 (gate ran first)" \
  || fail "attempts-scenario rc=$rc6 (expected 4)"
if [ -f "$R6/.tick/attempts/$TASK6" ]; then
  pass "attempt counted in the self-resolved repo's .tick/attempts (#136)"
else
  fail "attempts file not in $R6/.tick/attempts — the gate still counts elsewhere (#136)"
fi
if [ ! -f "$ROOT_DIR/.tick/attempts/$TASK6" ]; then
  pass "no attempt row leaked into the harness clone's .tick"
else
  fail "attempt leaked to the harness clone's .tick/attempts (pre-#136 behavior)"
fi

echo "gh129: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
