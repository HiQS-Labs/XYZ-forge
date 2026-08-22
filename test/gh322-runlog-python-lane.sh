#!/usr/bin/env bash
# GH-322: GH-284 Phase 2 (driver heartbeat + --log-github run log) on the lane that ACTUALLY RUNS.
#
# Phase 2 shipped both features in relay-automation/marathon-drive.sh only. That twin `exec`s
# utils/py/marathon_drive.py at its own line 18 — before it installs the EXIT trap that runs them —
# so with XYZ_PYTHON unset (the default since GH-264) neither the heartbeat nor the run log ever
# executed. The marathon ran, exited 0, reported success, and observed nothing.
#
# test/gh284-runlog-heartbeat.sh cannot catch this: every driver invocation in it is pinned to
# XYZ_PYTHON=0, so it exercises the fallback twin exclusively. This file is its counterpart and
# pins the DEFAULT lane — XYZ_PYTHON is deliberately never set below.
source "$(dirname "$0")/_setup.sh" gh322-runlog-python-lane

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DRIVER="$ROOT/relay-automation/marathon-drive.sh"
PY="$ROOT/utils/py/marathon_drive.py"
LIB="$ROOT/relay-automation/relay-turn-lib.sh"

# The default lane must be the one under test. If an ambient XYZ_PYTHON=0 leaked in from the runner,
# every assertion below would silently measure the Bash twin again — the exact blind spot this file
# exists to close.
unset XYZ_PYTHON

# --- 0. the flag exists on the Python lane at all --------------------------------------------
grep -q -- '--log-github' <<<"$(python3 "$PY" --help 2>/dev/null)" \
  && pass "--log-github is documented in the Python lane's help" \
  || fail "--log-github missing from the Python lane's help"
grep -q 'driver-heartbeat.json' "$PY" \
  && pass "the Python lane knows the driver-heartbeat path (Phase 2's other half)" \
  || fail "the Python lane has no driver heartbeat — GH-284 Phase 2 is still Bash-only"

# Unknown flags must STILL be rejected (#324 must not regress now that --log-github is real).
python3 "$PY" --not-a-real-flag >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && pass "an unrecognised flag still exits 2 on the Python lane" \
  || fail "unknown-flag rejection regressed: exit $rc"

# --- 1. parser contract, exercised as the REAL function ---------------------------------------
# Imported from the driver, not reimplemented: a test that re-derives the logic proves only that the
# test is self-consistent. Module import must not run main(), which is itself worth asserting.
MARKER='<!-- xyz-marathon-run-log:284:p1 -->'
parser_probe() { # <payload-json>
  MD_PAYLOAD="$1" MD_MARKER="$MARKER" MD_PATH="$PY" python3 - <<'PYEOF'
import importlib.util, os
spec = importlib.util.spec_from_file_location("md", os.environ["MD_PATH"])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
print(mod.runlog_find_comment_id(os.environ["MD_PAYLOAD"], os.environ["MD_MARKER"]))
PYEOF
}
got="$(parser_probe "[[{\"id\":111,\"body\":\"$MARKER x\"}]]" 2>&1)"
[ "$got" = "111" ] && pass "parser finds the marker in a single slurped page" \
  || fail "single-page lookup returned '$got', expected 111"
got="$(parser_probe "[[{\"id\":222,\"body\":\"unrelated\"}],[{\"id\":111,\"body\":\"$MARKER x\"}]]" 2>&1)"
[ "$got" = "111" ] && pass "parser finds the marker across MULTI-PAGE responses (no duplicate POST)" \
  || fail "multi-page lookup returned '$got', expected 111 — a miss here re-POSTs a duplicate marker"
got="$(parser_probe "[{\"id\":111,\"body\":\"$MARKER x\"}]" 2>&1)"
[ "$got" = "111" ] && pass "parser still handles a flat (non-slurp) array" \
  || fail "flat-array lookup returned '$got', expected 111"
got="$(parser_probe '[[]]' 2>&1)"
[ -z "$got" ] && pass "parser reports no match on an empty comment list (first run POSTs)" \
  || fail "empty list should yield no comment id, got '$got'"
got="$(parser_probe 'not json at all' 2>&1)"
[ -z "$got" ] && pass "parser degrades to no-match on unparseable input instead of raising" \
  || fail "malformed payload should yield no comment id, got '$got'"

# --- 2. fixtures for driving the real entry point ---------------------------------------------
tick_a init >/dev/null
printf '.tick/\n' > "$A/.gitignore"
git -C "$A" add .gitignore && git -C "$A" commit -qm init

BRIEF="$WORK/GH-322-brief.md"; printf 'GH-322 python-lane run-log brief\n' > "$BRIEF"
HB_FILE="$A/.tick/driver-heartbeat.json"
HB_PROBE="$WORK/heartbeat-mid-run.json"
export HB_FILE HB_PROBE

# The stub relay-drive runs as a child of the driver, mid-phase. That is the only moment the
# heartbeat is supposed to exist, so capture it there: asserting on the file after the run can only
# ever prove it was cleaned up, never that it was written.
STUB_RD="$WORK/relay-drive.sh"
cat > "$STUB_RD" <<'RDSTUB'
#!/usr/bin/env bash
if [ -n "${HB_PROBE:-}" ] && [ -f "${HB_FILE:-}" ]; then cp "$HB_FILE" "$HB_PROBE"; fi
exit 3
RDSTUB
chmod +x "$STUB_RD"
STUB_CLAUDE="$WORK/claude"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_CLAUDE"; chmod +x "$STUB_CLAUDE"
STUB_AGY="$WORK/agy"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_AGY"; chmod +x "$STUB_AGY"

# Trim PATH so `gh` is absent, without losing the toolchain the driver itself needs. A bare
# /usr/bin:/bin also drops `node` on nvm-style installs, which makes the driver die at 127 for a
# reason unrelated to what is under test (see the same note in gh284-runlog-heartbeat.sh).
NODE_ONLY="$WORK/node-only"; mkdir -p "$NODE_ONLY"
if NODE_BIN="$(command -v node 2>/dev/null)" && [ -n "$NODE_BIN" ]; then
  ln -sf "$NODE_BIN" "$NODE_ONLY/node"
fi

run_driver() { # <phase-id> [extra-args...]
  local phase="$1"; shift
  MARATHON_COST_SUMMARY=0 MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$STUB_RD" \
    TICK_REPO_ROOT="$A" TICK_BIN="$TICK" CLAUDE_BIN="$STUB_CLAUDE" AGY_BIN="$STUB_AGY" \
    PATH="${GH_ON_PATH:-}$NODE_ONLY:/usr/bin:/bin" bash "$DRIVER" --phases-dir "$A/phases" \
      --phase-brief "$BRIEF" --phase-id "$phase" --relay-task "MARATHON-GH322-${phase}" \
      --builder claude --reviewer agy --pre-advance-cmd true "$@"
}

# --- 3. degraded path: no gh at all ------------------------------------------------------------
NO_LOG_OUT="$(run_driver no-log 2>&1)"; NO_LOG_RC=$?
WITH_LOG_OUT="$(run_driver with-log --log-github 2>&1)"; WITH_LOG_RC=$?
[ "$NO_LOG_RC" -eq 3 ] && [ "$WITH_LOG_RC" -eq 3 ] \
  && pass "--log-github on the default lane preserves the marathon exit code" \
  || fail "expected both runs to exit 3; no-log=$NO_LOG_RC with-log=$WITH_LOG_RC ($WITH_LOG_OUT)"
grep -q 'local telemetry only' <<<"$(printf '%s\n' "$WITH_LOG_OUT")" \
  && pass "missing gh degrades to local telemetry on the default lane" \
  || fail "missing-gh degradation was not reported by the Python lane: $WITH_LOG_OUT"
grep -q 'local telemetry only' <<<"$(printf '%s\n' "$NO_LOG_OUT")" \
  && fail "a run WITHOUT --log-github reported run-log degradation — the feature is not opt-in" \
  || pass "a run without --log-github says nothing about the run log (opt-in preserved)"

# --- 4. the driver heartbeat is real, and is cleaned up ----------------------------------------
[ -f "$HB_PROBE" ] \
  && pass "the default lane writes a driver heartbeat while the phase is running" \
  || fail "no driver heartbeat existed mid-phase — Phase 2's liveness half is still missing"
if [ -f "$HB_PROBE" ]; then
  HB_KEYS="$(python3 - "$HB_PROBE" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    h = json.load(f)
required = {"pid", "started_utc", "updated_utc", "plan", "phase_id", "relay_task"}
print("ok" if required <= set(h) and int(h["pid"]) > 0 else "bad")
PYEOF
)"
  [ "$HB_KEYS" = ok ] && pass "the Python-written heartbeat carries every field the readers expect" \
    || fail "Python heartbeat record was incomplete: $HB_KEYS"

  # Cross-twin compatibility: the Bash READER must parse a Python-WRITTEN record. This is a
  # discriminating check — rtl_driver_heartbeat_status answers 'finished' both when a record is
  # genuinely finished AND when it fails to parse one, so only the 'stale' verdict (which requires
  # it to have read BOTH pid and updated_utc) proves the record was actually understood.
  STALE_COPY="$WORK/hb-stale.json"
  python3 - "$HB_PROBE" "$STALE_COPY" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    h = json.load(f)
h["pid"] = 999999
h["updated_utc"] = "2000-01-01T00:00:00Z"
with open(sys.argv[2], "w") as f:
    json.dump(h, f, sort_keys=True)
PYEOF
  # shellcheck source=../relay-automation/relay-turn-lib.sh
  ( source "$LIB"; RTL_DRIVER_HEARTBEAT_FILE="$STALE_COPY" rtl_driver_heartbeat_status "$A" 1 >"$WORK/state" 2>/dev/null ) || true
  STATE="$(cat "$WORK/state" 2>/dev/null || true)"
  [ "$STATE" = stale ] \
    && pass "the Bash reader parses a Python-written heartbeat (cross-twin record compatibility)" \
    || fail "Bash reader could not interpret the Python heartbeat: got '$STATE', expected 'stale'"
fi
[ ! -e "$HB_FILE" ] \
  && pass "driver exit clears its heartbeat file on the default lane" \
  || fail "the Python lane left a heartbeat file behind after exit"

# --- 5. authenticated happy path: it must actually POST ----------------------------------------
# The degraded assertions above would all pass against a lane that does nothing at all — "gh is
# missing" and "the feature is absent" are indistinguishable from outside. Stub gh and assert the
# real contract instead.
GH_STUB_DIR="$WORK/ghstub"; mkdir -p "$GH_STUB_DIR"
GH_CALLS="$WORK/gh-calls.log"; : > "$GH_CALLS"
MARKER_STORE="$WORK/marker-store"; : > "$MARKER_STORE"
GH_API_RC="$WORK/gh-api-rc"; printf '0\n' > "$GH_API_RC"
export GH_CALLS MARKER_STORE GH_API_RC
cat > "$GH_STUB_DIR/gh" <<'GHSTUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$GH_CALLS"
case "$1" in
  auth) exit 0 ;;
  repo) printf 'acme/widgets\n'; exit 0 ;;
  pr)   printf 'https://example.invalid/pr/1\n'; exit 0 ;;
  api)
    # GET (no --method): replay whatever body was previously posted, so the marker the driver
    # searches for is the REAL one it wrote. A placeholder body would never match and every run
    # would look like a first run — the test would then pass while idempotency was broken.
    if [[ "$*" != *"--method"* ]]; then
      if [[ -s "$MARKER_STORE" ]]; then
        python3 -c 'import json,os
b=open(os.environ["MARKER_STORE"]).read()
print(json.dumps([[{"id":111,"body":b}],[{"id":222,"body":"unrelated"}]]))'
      else
        printf '[[]]\n'
      fi
      exit 0
    fi
    if [[ "$*" == *"--method POST"* ]]; then
      for arg in "$@"; do
        case "$arg" in body=*) printf '%s' "${arg#body=}" > "$MARKER_STORE" ;; esac
      done
    fi
    exit "$(cat "$GH_API_RC")" ;;
esac
exit 0
GHSTUB
chmod +x "$GH_STUB_DIR/gh"

GH_ON_PATH="$GH_STUB_DIR:" run_driver gh-log --log-github >/dev/null 2>&1
posts=$(grep -c -- "--method POST" "$GH_CALLS" || true)
[ "$posts" = "1" ] \
  && pass "the DEFAULT lane POSTs exactly one run-log comment (#322's core defect)" \
  || fail "expected exactly 1 POST from the Python lane, got $posts — the run log is still inert"
FIRST_CALLS="$(cat "$GH_CALLS")"

if grep -q -- "--repo acme/widgets" <<<"$(printf '%s\n' "$FIRST_CALLS")" \
   || grep -q "repos/acme/widgets/" <<<"$(printf '%s\n' "$FIRST_CALLS")"; then
  pass "the Python lane scopes every gh call to the resolved repository"
else
  fail "gh calls were not repo-scoped: $FIRST_CALLS"
fi
grep -q -- "--paginate --slurp" <<<"$(printf '%s\n' "$FIRST_CALLS")" \
  && pass "comment lookup uses --slurp (one well-formed JSON document)" \
  || fail "comment lookup must use --paginate --slurp: $FIRST_CALLS"

BODY="$(cat "$MARKER_STORE")"
grep -q 'xyz-marathon-run-log:322:gh-log' <<<"$(printf '%s' "$BODY")" \
  && pass "run-log body carries the lane-scoped idempotency marker" \
  || fail "marker missing or wrong in the posted body: $BODY"
grep -q 'driver exit: `3`' <<<"$(printf '%s' "$BODY")" \
  && pass "run-log body records the driver's REAL exit code, not a placeholder" \
  || fail "driver exit not recorded correctly: $BODY"

# GH-333: the exit code is glossed, so a reader does not have to look up what 3 means.
grep -q 'driver exit: `3` (no-progress escalation)' <<<"$(printf '%s' "$BODY")" \
  && pass "the exit code carries its plain-language meaning" \
  || fail "exit code was not glossed: $BODY"
# ...and the constant field it replaced is gone. `driver still running` could only ever say
# "running": the exit hook asked before clearing the heartbeat, and the PID it tested belonged to the
# process doing the asking. A line that reads like a measurement but is a constant is worse than no
# line, so this asserts its ABSENCE — re-adding it must fail here.
grep -q 'driver still running' <<<"$(printf '%s' "$BODY")" \
  && fail "the constant 'driver still running' field is back — it can only ever say 'running': $BODY" \
  || pass "the always-'running' liveness field is gone from the run log"
# The heartbeat FILE is the real liveness deliverable and must be untouched by that removal — it is
# asserted live earlier in this file (mid-phase capture + cross-twin read).
grep -q 'driver_heartbeat_write' "$PY" \
  && pass "dropping the field did not remove the heartbeat writer itself" \
  || fail "the driver heartbeat writer went away with the field"
grep -q 'per-phase gate: \*\*not-run\*\*' <<<"$(printf '%s' "$BODY")" \
  && pass "run-log body reports the gate as not-run when the phase never reached it" \
  || fail "gate result not reported honestly: $BODY"

# --- 6. idempotency end-to-end on the default lane ---------------------------------------------
: > "$GH_CALLS"
GH_ON_PATH="$GH_STUB_DIR:" run_driver gh-log --log-github --force >/dev/null 2>&1
posts=$(grep -c -- "--method POST" "$GH_CALLS" || true)
patches=$(grep -c -- "--method PATCH" "$GH_CALLS" || true)
[ "$posts" = "0" ] && [ "$patches" = "1" ] \
  && pass "a re-run PATCHes the existing comment instead of POSTing a duplicate" \
  || fail "expected 0 POST / 1 PATCH on the second run, got $posts POST / $patches PATCH"

# --- 7. reporting can never change the driven run's result -------------------------------------
printf '1\n' > "$GH_API_RC"
: > "$GH_CALLS"
OUT="$(GH_ON_PATH="$GH_STUB_DIR:" run_driver gh-fail --log-github 2>&1)"; RC=$?
[ "$RC" -eq 3 ] \
  && pass "a FAILING gh write leaves the marathon exit code untouched" \
  || fail "gh failure changed the driven run's exit code to $RC"
grep -q 'local telemetry only' <<<"$(printf '%s\n' "$OUT")" \
  && pass "a failed run-log write is reported rather than swallowed" \
  || fail "failed gh write produced no diagnostic: $OUT"
printf '0\n' > "$GH_API_RC"

# --- 8. nothing is posted by a run that never drives a phase ------------------------------------
: > "$GH_CALLS"
# GH-401: --help never reaches the render, but it stays MARATHON_ROOT-scoped like every other driver
# invocation — the audit's rule is unconditional on purpose, so no future edit here inherits an
# unscoped call site by accident.
MARATHON_ROOT="$WORK/mroot-help" \
  GH_ON_PATH="$GH_STUB_DIR:" PATH="$GH_STUB_DIR:$NODE_ONLY:/usr/bin:/bin" \
  bash "$DRIVER" --help --log-github >/dev/null 2>&1
[ ! -s "$GH_CALLS" ] \
  && pass "--help --log-github posts nothing (the run log arms only once a phase is really driven)" \
  || fail "a --help run reached GitHub: $(cat "$GH_CALLS")"

: > "$GH_CALLS"
GH_ON_PATH="$GH_STUB_DIR:" run_driver "" --log-github >/dev/null 2>&1
[ ! -s "$GH_CALLS" ] \
  && pass "a usage failure posts nothing" \
  || fail "a failed-usage run reached GitHub: $(cat "$GH_CALLS")"

echo "  gh322-runlog-python-lane: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
