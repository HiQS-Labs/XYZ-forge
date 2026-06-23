#!/usr/bin/env bash
# GH-12: a coordination-mutation verb run from a FOREIGN CWD (no TICK_REPO_ROOT)
# must FAIL LOUDLY instead of silently no-op'ing against — or auto-creating — the
# wrong repo's .tick/. This is the foot-gun that stalled a live relay handoff: the
# Reporter's bare `tick release` from another repo's CWD resolved the wrong root
# via `git rev-parse`, so the lock token never moved and the poll loop deadlocked.
# Also asserts the SAFE paths still work: env-pinned (the recipe form), and an
# inferred root that DOES have .tick/ (operator in the harness clone).
source "$(dirname "$0")/_setup.sh" tick-foreign-cwd

tick_a init >/dev/null
tick_a claim TASK-1 --agent claude-a --paths "src/**" >/dev/null

# A foreign git repo with NO .tick/ — what a peer's other-repo CWD looks like.
FOREIGN="$WORK/foreign"; mkdir -p "$FOREIGN"; git -C "$FOREIGN" init -q

claimer_of(){ tick_a info "$1" 2>/dev/null | sed -n 's/^claimer:[[:space:]]*//p'; }

# (1) bare `release` from the foreign CWD: refuse loudly, leave the real lock alone.
out="$( cd "$FOREIGN" && env -u TICK_REPO_ROOT "$TICK" release TASK-1 --agent claude-a 2>&1 )"; rc=$?
[ "$rc" -ne 0 ] \
  && pass "foreign-CWD release exits non-zero (no silent success)" \
  || fail "release succeeded-as-noop from foreign CWD (rc=$rc): $out"
echo "$out" | grep -q "no .tick/events" \
  && pass "error names the missing .tick/events (actionable, not a bare 'task not found')" \
  || fail "error did not explain the wrong-CWD cause: $out"
[ "$(claimer_of TASK-1)" = "claude-a" ] \
  && pass "real lock untouched — TASK-1 still claimed by claude-a" \
  || fail "foreign-CWD release leaked into / altered real coordination state"

# (2) bare `claim` from the foreign CWD must NOT auto-create a stray .tick/ there
#     (the genuine silent-success-in-the-wrong-place case before this fix).
out="$( cd "$FOREIGN" && env -u TICK_REPO_ROOT "$TICK" claim TASK-2 --agent claude-a --paths "x/**" 2>&1 )"; rc=$?
[ "$rc" -ne 0 ] \
  && pass "foreign-CWD claim refused (non-zero)" \
  || fail "foreign-CWD claim succeeded (rc=$rc): $out"
[ ! -d "$FOREIGN/.tick" ] \
  && pass "no stray .tick/ auto-created in the foreign repo" \
  || fail "claim vivified a wrong-repo .tick/"

# (3) env-pinned (TICK_REPO_ROOT set) still works — no regression for the recipe form.
out="$(tick_a release TASK-1 --agent claude-a 2>&1)"; rc=$?
{ [ "$rc" -eq 0 ] && echo "$out" | grep -q "released: TASK-1"; } \
  && pass "env-pinned release still works (TICK_REPO_ROOT honored)" \
  || fail "env-pinned release regressed (rc=$rc): $out"

# (4) inferred root that DOES have .tick/ still works, and echoes the resolved
#     root to stderr (direction c — a wrong-repo target stays visible).
out="$( cd "$A" && env -u TICK_REPO_ROOT "$TICK" claim TASK-3 --agent claude-a --paths "y/**" 2>&1 )"; rc=$?
{ [ "$rc" -eq 0 ] && echo "$out" | grep -q "won:"; } \
  && pass "inferred root WITH .tick/ still claims (guard not over-eager)" \
  || fail "guard broke a legit inferred-root claim (rc=$rc): $out"
echo "$out" | grep -q "resolved repo root" \
  && pass "resolved root echoed to stderr when inferred (visibility)" \
  || fail "resolved-root echo missing from inferred-root call: $out"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
