#!/usr/bin/env bash
# GH-284 Phase 2: file-based driver liveness and opt-in, non-fatal GitHub run-log.
source "$(dirname "$0")/_setup.sh" gh284-runlog-heartbeat

# GH-441 — hermetic against an ambient driver, same reason as test/driver-lock.sh:11. This suite
# drives marathon-drive against its own throwaway repo ($A) and asserts on what THAT driver does.
# When validate.sh runs as a live marathon's --pre-advance-cmd it inherits RELAY_DRIVER_LOCKED=1
# (exported by marathon-drive.sh:245 so a nested driver doesn't deadlock on its parent's lock), and
# the drivers spawned below would then skip the heartbeat/run-log block entirely — the very logic
# under test — reporting the PARENT's state instead of their own. Measured on 2026-08-07: inherited
# → 15 pass / 5 fail; unset → clean. $A is isolated, so unsetting cannot collide with a real lock.
unset RELAY_DRIVER_LOCKED

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$ROOT/relay-automation/relay-turn-lib.sh"
DRIVER="$ROOT/relay-automation/marathon-drive.sh"
source "$LIB"

HB="$A/.tick/driver-heartbeat.json"
export RTL_DRIVER_HEARTBEAT_FILE="$HB"
mkdir -p "$A/.tick"

# A minimal-env child is the relevant sandbox boundary: it can read the JSON without ps access.
rtl_driver_heartbeat_write "$A" "$$" "2026-07-28T00:00:00Z" "gh284-plan" "p1" "MARATHON-GH284-TURN"
READER="$(env -i PATH="$PATH" python3 - "$HB" <<'PYEOF'
import json
import sys
with open(sys.argv[1]) as f:
    h = json.load(f)
required = {"pid", "started_utc", "updated_utc", "plan", "phase_id", "relay_task"}
print("ok" if required <= set(h) and h["pid"] > 0 else "bad")
PYEOF
)"
[ "$READER" = ok ] && pass "sandboxed reader sees the complete driver heartbeat" || fail "sandboxed heartbeat reader got: $READER"

STATE="$(rtl_driver_heartbeat_status "$A" 1 2>/dev/null || true)"
[ "$STATE" = running ] && pass "live driver heartbeat reports running" || fail "live heartbeat reported: $STATE"

# A stale write alone must not classify a still-live PID as stale.
python3 - "$HB" "$$" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f: h = json.load(f)
h["pid"] = int(sys.argv[2]); h["updated_utc"] = "2000-01-01T00:00:00Z"
with open(sys.argv[1], "w") as f: json.dump(h, f)
PYEOF
STATE="$(rtl_driver_heartbeat_status "$A" 1 2>/dev/null || true)"
[ "$STATE" = running ] && pass "stale heartbeat plus live PID remains running" || fail "live stale heartbeat reported: $STATE"

# Conversely, a dead PID alone is not labelled stale until the heartbeat is old too.
python3 - "$HB" <<'PYEOF'
import datetime as dt, json, sys
with open(sys.argv[1]) as f: h = json.load(f)
h["pid"] = 999999; h["updated_utc"] = dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z")
with open(sys.argv[1], "w") as f: json.dump(h, f)
PYEOF
STATE="$(rtl_driver_heartbeat_status "$A" 3600 2>/dev/null || true)"
[ "$STATE" = finished ] && pass "dead PID with fresh heartbeat is never reported running" || fail "dead fresh heartbeat reported: $STATE"
python3 - "$HB" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f: h = json.load(f)
h["updated_utc"] = "2000-01-01T00:00:00Z"
with open(sys.argv[1], "w") as f: json.dump(h, f)
PYEOF
STATE="$(rtl_driver_heartbeat_status "$A" 1 2>/dev/null || true)"
[ "$STATE" = stale ] && pass "staleness requires both an old heartbeat and absent PID" || fail "dead stale heartbeat reported: $STATE"
rtl_driver_heartbeat_clear "$A"
[ ! -e "$HB" ] && pass "heartbeat is removed on clean stop" || fail "heartbeat remained after clean stop"

# --log-github is opt-in and a missing gh must never change the marathon's own exit code.
tick_a init >/dev/null
printf '.tick/\n' > "$A/.gitignore"
git -C "$A" add .gitignore && git -C "$A" commit -qm init
BRIEF="$WORK/GH-284-brief.md"; printf 'GH-284 heartbeat brief\n' > "$BRIEF"
STUB_RD="$WORK/relay-drive.sh"
printf '#!/usr/bin/env bash\nexit 3\n' > "$STUB_RD"; chmod +x "$STUB_RD"
STUB_CLAUDE="$WORK/claude"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_CLAUDE"; chmod +x "$STUB_CLAUDE"
STUB_AGY="$WORK/agy"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_AGY"; chmod +x "$STUB_AGY"

# The point of the trimmed PATH below is to make `gh` unavailable, NOT to strip the toolchain.
# A bare PATH=/usr/bin:/bin also loses `node` (it lives outside the system dirs on macOS/nvm-style
# installs), so the driver's internal node calls died with 127 and this test failed for a reason
# unrelated to what it asserts. Symlink just `node` into a dedicated dir and prepend that: `gh`
# stays absent (it is outside /usr/bin and /bin here), which is the condition under test.
NODE_ONLY="$WORK/node-only"; mkdir -p "$NODE_ONLY"
if NODE_BIN="$(command -v node 2>/dev/null)" && [ -n "$NODE_BIN" ]; then
  ln -sf "$NODE_BIN" "$NODE_ONLY/node"
fi

run_driver() {
  XYZ_PYTHON=0 MARATHON_COST_SUMMARY=0 MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$STUB_RD" \
    TICK_REPO_ROOT="$A" TICK_BIN="$TICK" CLAUDE_BIN="$STUB_CLAUDE" AGY_BIN="$STUB_AGY" \
    PATH="$NODE_ONLY:/usr/bin:/bin" bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
      --phase-id "$1" --relay-task "MARATHON-GH284-${1}" --builder claude --reviewer agy \
      --pre-advance-cmd true "${@:2}"
}

NO_LOG_OUT="$(run_driver no-log 2>&1)"; NO_LOG_RC=$?
WITH_LOG_OUT="$(run_driver with-log --log-github 2>&1)"; WITH_LOG_RC=$?
[ "$NO_LOG_RC" -eq 3 ] && [ "$WITH_LOG_RC" -eq 3 ] \
  && pass "--log-github with gh unavailable preserves the marathon exit code" \
  || fail "expected both runs to exit 3; no-log=$NO_LOG_RC with-log=$WITH_LOG_RC ($WITH_LOG_OUT)"
grep -q 'local telemetry only' <<<"$(printf '%s\n' "$WITH_LOG_OUT")" \
  && pass "missing gh degrades to local telemetry" \
  || fail "missing-gh degradation was not reported: $WITH_LOG_OUT"
[ ! -e "$A/.tick/driver-heartbeat.json" ] \
  && pass "driver exit clears its heartbeat file" \
  || fail "driver exit left a heartbeat file"
# GH-441: MARATHON_ROOT="$A" keeps this hermetic. This assertion reads HELP TEXT, but the driver's
# lock block (marathon-drive.sh:189) runs long before --help is parsed (:664), so without a root of
# its own it contends for the ambient repo's lock and prints the lock-contention notice instead of
# the help — failing here for a reason that has nothing to do with --log-github. That ordering is
# itself a defect (--help should never need the lock); it is filed separately, not worked around
# by weakening this assertion.
grep -q -- '--log-github' <<<"$(MARATHON_ROOT="$A" XYZ_PYTHON=0 bash "$DRIVER" --help)" \
  && pass "--log-github is exposed as an explicit opt-in" \
  || fail "--log-github missing from help"

# --- authenticated happy path (codex QA, Should #1) -------------------------------------------
# The cases above only prove the DEGRADED path. The whole value of the run log is idempotency on
# the authenticated path, and the two blockers codex found (unscoped repo, --paginate parsing)
# both lived there — invisible to a gh-unavailable test. Stub `gh` and assert the real contract:
# first run POSTs exactly one marker, a re-run PATCHes it, and a MULTI-PAGE comment response still
# PATCHes (the concatenated-array bug POSTed a duplicate precisely here).
GH_STUB_DIR="$WORK/ghstub"; mkdir -p "$GH_STUB_DIR"
GH_CALLS="$WORK/gh-calls.log"; : > "$GH_CALLS"
PAGES_MODE="$WORK/pages-mode"; printf 'single\n' > "$PAGES_MODE"
cat > "$GH_STUB_DIR/gh" <<'GHSTUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$GH_CALLS"
case "$1" in
  auth) exit 0 ;;
  repo) printf 'acme/widgets\n'; exit 0 ;;
  pr)   printf 'https://example.invalid/pr/1\n'; exit 0 ;;
  api)
    # GET (no --method): return whatever body was previously "posted", so the marker the driver
    # searches for is the REAL one it wrote — a placeholder body would never match and every run
    # would look like a first run.
    if [[ "$*" != *"--method"* ]]; then
      if [[ -s "$MARKER_STORE" ]]; then
        if [[ "$(cat "$PAGES_MODE")" == "multi" ]]; then
          # Mirror `gh api --paginate --slurp`: an ARRAY OF PAGES, not a flat list.
          MODE=multi python3 -c 'import json,os,sys
b=open(os.environ["MARKER_STORE"]).read()
print(json.dumps([[{"id":111,"body":b}],[{"id":222,"body":"unrelated"}]]))'
        else
          python3 -c 'import json,os
b=open(os.environ["MARKER_STORE"]).read()
print(json.dumps([[{"id":111,"body":b}]]))'
        fi
      else
        printf '[[]]\n'
      fi
      exit 0
    fi
    if [[ "$*" == *"--method POST"* ]]; then
      # Capture the real -f body=... payload so the stored comment contains the actual marker.
      prev=""; for arg in "$@"; do
        case "$arg" in body=*) printf '%s' "${arg#body=}" > "$MARKER_STORE" ;; esac
        prev="$arg"
      done
    fi
    exit 0 ;;
esac
exit 0
GHSTUB
chmod +x "$GH_STUB_DIR/gh"

MARKER_STORE="$WORK/marker-store"; : > "$MARKER_STORE"
export GH_CALLS MARKER_STORE PAGES_MODE
run_driver_gh() { # <phase-id> [extra-args...]
  XYZ_PYTHON=0 MARATHON_COST_SUMMARY=0 MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$STUB_RD" \
    TICK_REPO_ROOT="$A" TICK_BIN="$TICK" CLAUDE_BIN="$STUB_CLAUDE" AGY_BIN="$STUB_AGY" \
    PATH="$GH_STUB_DIR:$NODE_ONLY:/usr/bin:/bin" bash "$DRIVER" --phases-dir "$A/phases" \
      --phase-brief "$BRIEF" --phase-id "$1" --relay-task "MARATHON-GH284-${1}" \
      --builder claude --reviewer agy --pre-advance-cmd true --log-github >/dev/null 2>&1
}

run_driver_gh gh-log
posts=$(grep -c -- "--method POST" "$GH_CALLS" || true)
[ "$posts" = "1" ] && pass "authenticated first run POSTs exactly one marker comment" \
  || fail "expected exactly 1 POST on first run, got $posts"
FIRST_CALLS="$(cat "$GH_CALLS")"

# Blocker 1 regression: every gh call must target the RESOLVED repo, not the ambient CWD's.
if grep -q -- "--repo acme/widgets" <<<"$(printf '%s\n' "$FIRST_CALLS")" \
   || grep -q "repos/acme/widgets/" <<<"$(printf '%s\n' "$FIRST_CALLS")"; then
  pass "gh calls are scoped to the resolved repository"
else
  fail "gh calls were not repo-scoped: $FIRST_CALLS"
fi
grep -q -- "--paginate --slurp" <<<"$(printf '%s\n' "$FIRST_CALLS")" \
  && pass "comment lookup uses --slurp (single well-formed JSON document)" \
  || fail "comment lookup must use --paginate --slurp: $FIRST_CALLS"

# Blocker 2 regression, tested where the bug actually lived — the PARSER. Driving the whole
# marathon three times to observe POST-then-PATCH proved unreliable: the second and third fires hit
# the driver's own satisfied-lane / attempt-cap logic, so the assertions were measuring lane state
# rather than comment idempotency. Extract the marker-matching program from the driver and feed it
# both payload shapes directly. This is the precise contract: a MULTI-PAGE response must still
# resolve the existing comment id, which is exactly what the concatenated-array bug broke.
PARSER="$WORK/marker-parser.py"
sed -n "/runlog_marker_py <<'PYEOF'/,/^PYEOF\$/p" \
  "$ROOT/relay-automation/marathon-drive.sh" | sed '1d;$d' > "$PARSER"
[ -s "$PARSER" ] && pass "marker parser extracted from the driver (not a reimplementation)" \
  || fail "could not extract the marker parser from marathon-drive.sh"

# The parser LOGIC being right is not enough — the first version of this fix was logically correct
# and still broken, because the driver invoked it as `python3 - "$marker" <<'PYEOF'`: a heredoc and
# a pipe both claim stdin, so python got the comments JSON prepended to its own source and died
# with a SyntaxError. `comment_id` was therefore always empty and the run log always POSTed a
# duplicate — the exact bug the --slurp fix above exists to prevent. This suite MISSED it because
# it ran the parser from a file, which is not how the driver runs it. Pin the invocation shape too.
INVOKE="$(grep -n 'python3' "$ROOT/relay-automation/marathon-drive.sh" | grep -F "$(printf '%s' 'runlog_marker_py')" || true)"
printf '%s' "$INVOKE" | grep -Fq 'python3 -c' \
  && pass "driver passes the parser via python3 -c, leaving stdin free for the comments JSON" \
  || fail "driver no longer invokes the marker parser with python3 -c: $INVOKE"
grep -Eq 'python3 +- +"\$marker"' "$ROOT/relay-automation/marathon-drive.sh" \
  && fail "driver reintroduced 'python3 - \"\$marker\" <<HEREDOC' — the heredoc overrides the pipe (SC2259) and the comments JSON never reaches python" \
  || pass "driver does not feed the parser on stdin while also piping data into it"

MARKER='<!-- xyz-marathon-run-log:284:gh-log -->'
SINGLE_PAGE="[[{\"id\":111,\"body\":\"$MARKER x\"}]]"
MULTI_PAGE="[[{\"id\":222,\"body\":\"unrelated\"}],[{\"id\":111,\"body\":\"$MARKER x\"}]]"
FLAT_PAGE="[{\"id\":111,\"body\":\"$MARKER x\"}]"

# Invoke exactly as the driver does — program via `-c` from a variable, data on stdin — so a
# regression in the INVOCATION fails here, not only a regression in the parser body.
PARSER_SRC="$(cat "$PARSER")"
run_parser() { printf '%s' "$1" | python3 -c "$PARSER_SRC" "$MARKER"; }

got="$(run_parser "$SINGLE_PAGE")"
[ "$got" = "111" ] && pass "parser finds the marker in a single-page response" \
  || fail "single-page lookup returned '$got', expected 111"

got="$(run_parser "$MULTI_PAGE")"
[ "$got" = "111" ] && pass "parser finds the marker across MULTI-PAGE responses (no duplicate POST)" \
  || fail "multi-page lookup returned '$got', expected 111 — a miss here re-POSTs a duplicate marker"

got="$(run_parser "$FLAT_PAGE")"
[ "$got" = "111" ] && pass "parser still handles a flat (non-slurp) array" \
  || fail "flat-array lookup returned '$got', expected 111"

got="$(run_parser '[[]]')"
[ -z "$got" ] && pass "parser reports no match on an empty comment list (first run POSTs)" \
  || fail "empty list should yield no comment id, got '$got'"

echo "  gh284-runlog-heartbeat: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
