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
# FRESH dir on purpose. GREEN 1 above created .tick/events inside FOREIGN_COST, and the guard
# only refuses when .tick/events is ABSENT — so reusing that directory would make this assertion
# pass even if `cost` were wrongly guarded. Each exemption case needs a directory the guard has
# not already been satisfied in, or it proves nothing.
FOREIGN_COSTVERB="$WORK/foreign-costverb"
mkdir -p "$FOREIGN_COSTVERB"
git -C "$FOREIGN_COSTVERB" init -q
out="$( cd "$FOREIGN_COSTVERB" && env -u TICK_REPO_ROOT "$TICK" cost T4 --agent s --human-minutes 5 2>&1 )"; rc=$?
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

# ── GREEN 4: the `drift` VERB keeps its warn-only invariant ───────────────────
# GH-68 / decisions/2026-07-01-cross-agent-dep-conflict.md: `drift` is a separate VERB, not a log
# type, and is deliberately outside MUTATING_GUARD_VERBS so it can NEVER hard-fail a turn. It sits
# next to `cost`/`log` in the same comment at bin/tick:35, which is exactly why a later refactor
# generalising "guard everything that isn't cost.*" would silently capture it. Pinned here so that
# refactor fails loudly instead of quietly breaking the warn-only contract.
# FRESH dir, for the same reason as GREEN 2: the guard only fires where .tick/events is absent,
# so asserting this in a directory a prior case already seeded would pass under a refactor that
# DOES capture drift. Verified: with the exemption widened to `verb !== 'cost'`, this case fails
# here and passes in a seeded directory — the fresh dir is what makes the assertion falsifiable.
FOREIGN_DRIFT="$WORK/foreign-drift"
mkdir -p "$FOREIGN_DRIFT"
git -C "$FOREIGN_DRIFT" init -q
out="$( cd "$FOREIGN_DRIFT" && env -u TICK_REPO_ROOT "$TICK" drift src/shared.js --agent s --task T7 2>&1 )"; rc=$?
[ "$rc" -eq 0 ] \
  && pass "unpinned foreign tick drift verb still succeeds — warn-only invariant intact (rc=$rc)" \
  || fail "GH-68 REGRESSION: drift was guarded and hard-failed a turn (rc=$rc): $out"

# ── GREEN 5: `tick log` with NO event type is still a usage error, and writes nothing ─
# shouldGuard() short-circuits on a missing eventType, so this path is intentionally unguarded.
# That is safe only because the `log` case rejects it before appendEvent runs — assert the
# consequence (nothing written) rather than trusting the coupling.
FOREIGN_BARE="$WORK/foreign-bare"
mkdir -p "$FOREIGN_BARE"
git -C "$FOREIGN_BARE" init -q
out="$( cd "$FOREIGN_BARE" && env -u TICK_REPO_ROOT "$TICK" log 2>&1 )"; rc=$?
[ "$rc" -eq 2 ] \
  && pass "bare \`tick log\` is a usage error (rc=$rc)" \
  || fail "bare \`tick log\` did not exit 2 (rc=$rc): $out"
[ ! -d "$FOREIGN_BARE/.tick" ] \
  && pass "bare \`tick log\` created no .tick/ in a foreign cwd" \
  || fail "bare \`tick log\` auto-created .tick/ in a foreign cwd"

# ── GREEN 6: inferred root WITH .tick/events still succeeds and echoes resolved root ─
out="$( cd "$A" && env -u TICK_REPO_ROOT "$TICK" log task.created T6 --agent s --paths "y/**" 2>&1 )"; rc=$?
[ "$rc" -eq 0 ] \
  && pass "inferred root WITH .tick/ still logs task.created (rc=$rc)" \
  || fail "inferred root WITH .tick/ failed task.created (rc=$rc): $out"
grep -q "resolved repo root" <<<"$out" \
  && pass "resolved root echoed to stderr when inferred" \
  || fail "resolved root was not echoed to stderr: $out"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
