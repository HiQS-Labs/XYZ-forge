#!/usr/bin/env bash
# GH-411: `tick log` from a foreign CWD with TICK_REPO_ROOT unset must be refused
# for every event type EXCEPT `cost.*`.
#
# Prior to GH-411, MUTATING_GUARD_VERBS only covered claim/take/scope/release/break/done/ping/reap.
# `tick log task.created` or `tick log marathon.complete` from a foreign CWD silently vivified
# .tick/events in whatever directory resolved via git rev-parse / cwd fallback.
source "$(dirname "$0")/_setup.sh" gh411-tick-log-foreign-cwd

tick_a init >/dev/null

FOREIGN_GIT="$WORK/foreign-git"
mkdir -p "$FOREIGN_GIT"
git -C "$FOREIGN_GIT" init -q

FOREIGN_NONGIT="$WORK/foreign-nongit"
mkdir -p "$FOREIGN_NONGIT"

# ── RED 1: `tick log task.created` from an unpinned foreign git CWD is refused ─
out="$( cd "$FOREIGN_GIT" && env -u TICK_REPO_ROOT "$TICK" log task.created T1 --agent s --paths "x/**" 2>&1 )"; rc=$?
[ "$rc" -ne 0 ] \
  && pass "unpinned foreign-git tick log task.created refused (rc=$rc)" \
  || fail "unpinned foreign-git tick log task.created succeeded (rc=$rc): $out"
grep -q "no .tick/events" <<<"$out" \
  && pass "error names missing .tick/events" \
  || fail "error did not explain missing .tick/events: $out"
[ ! -d "$FOREIGN_GIT/.tick" ] \
  && pass "no .tick/ auto-created in foreign git repo by task.created" \
  || fail "task.created auto-created .tick/ in foreign git repo"

# ── RED 2: `tick log task.created` from an unpinned foreign non-git CWD is refused ─
out="$( cd "$FOREIGN_NONGIT" && env -u TICK_REPO_ROOT "$TICK" log task.created T2 --agent s --paths "x/**" 2>&1 )"; rc=$?
[ "$rc" -ne 0 ] \
  && pass "unpinned foreign-nongit tick log task.created refused (rc=$rc)" \
  || fail "unpinned foreign-nongit tick log task.created succeeded (rc=$rc): $out"
grep -q "no .tick/events" <<<"$out" \
  && pass "error names missing .tick/events for non-git cwd" \
  || fail "error did not explain missing .tick/events for non-git cwd: $out"
[ ! -d "$FOREIGN_NONGIT/.tick" ] \
  && pass "no .tick/ auto-created in foreign non-git dir by task.created" \
  || fail "task.created auto-created .tick/ in foreign non-git dir"

# ── RED 3: `tick log marathon.complete` from an unpinned foreign CWD is refused ─
out="$( cd "$FOREIGN_GIT" && env -u TICK_REPO_ROOT "$TICK" log marathon.complete M1 --agent s 2>&1 )"; rc=$?
[ "$rc" -ne 0 ] \
  && pass "unpinned foreign-git tick log marathon.complete refused (rc=$rc)" \
  || fail "unpinned foreign-git tick log marathon.complete succeeded (rc=$rc): $out"
grep -q "no .tick/events" <<<"$out" \
  && pass "marathon.complete error names missing .tick/events" \
  || fail "marathon.complete error did not explain missing .tick/events: $out"
[ ! -d "$FOREIGN_GIT/.tick" ] \
  && pass "no .tick/ auto-created in foreign git repo by marathon.complete" \
  || fail "marathon.complete auto-created .tick/ in foreign git repo"

# ── GREEN 1: `tick log cost.*` from an unpinned foreign CWD still succeeds ────
FOREIGN_COST="$WORK/foreign-cost"
mkdir -p "$FOREIGN_COST"
git -C "$FOREIGN_COST" init -q
out="$( cd "$FOREIGN_COST" && env -u TICK_REPO_ROOT "$TICK" log cost.tokens T3 --agent s --note "captured" 2>&1 )"; rc=$?
[ "$rc" -eq 0 ] \
  && pass "unpinned foreign tick log cost.tokens succeeds (rc=$rc)" \
  || fail "unpinned foreign tick log cost.tokens failed (rc=$rc): $out"

# ── GREEN 2: `tick cost` verb from an unpinned foreign CWD still succeeds ──────
out="$( cd "$FOREIGN_COST" && env -u TICK_REPO_ROOT "$TICK" cost T4 --agent s --human-minutes 5 2>&1 )"; rc=$?
[ "$rc" -eq 0 ] \
  && pass "unpinned foreign tick cost verb succeeds (rc=$rc)" \
  || fail "unpinned foreign tick cost verb failed (rc=$rc): $out"

# ── GREEN 3: pinned TICK_REPO_ROOT writes to the intended root only ───────────
out="$( cd "$FOREIGN_GIT" && TICK_REPO_ROOT="$A" "$TICK" log task.created T5 --agent s --paths "x/**" 2>&1 )"; rc=$?
[ "$rc" -eq 0 ] \
  && pass "pinned TICK_REPO_ROOT tick log task.created succeeds (rc=$rc)" \
  || fail "pinned TICK_REPO_ROOT tick log task.created failed (rc=$rc): $out"
[ ! -d "$FOREIGN_GIT/.tick" ] \
  && pass "foreign git repo still has no .tick/ after pinned log" \
  || fail "pinned log created .tick/ in foreign git repo"
[ -d "$A/.tick/events" ] \
  && pass "pinned log wrote to intended root $A" \
  || fail "pinned log did not write to intended root $A"

# ── GREEN 4: inferred root WITH .tick/events still succeeds and echoes resolved root ─
out="$( cd "$A" && env -u TICK_REPO_ROOT "$TICK" log task.created T6 --agent s --paths "y/**" 2>&1 )"; rc=$?
[ "$rc" -eq 0 ] \
  && pass "inferred root WITH .tick/ still logs task.created (rc=$rc)" \
  || fail "inferred root WITH .tick/ failed task.created (rc=$rc): $out"
grep -q "resolved repo root" <<<"$out" \
  && pass "resolved root echoed to stderr when inferred" \
  || fail "resolved root was not echoed to stderr: $out"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
