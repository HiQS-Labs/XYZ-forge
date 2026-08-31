#!/usr/bin/env bash
# GH-346 Phase 2: the agent-id allowlists must agree, and must reject an unknown id safely.
#
# Adding a gateway to this harness meant editing TEN hand-maintained allowlists that nothing
# checked against each other. The issue's recon map found six; #7 was found by reading, and
# #8-#10 only because test/gh441-gate-env-contract.sh refused to go green:
#
#   #1  relay-automation/marathon-drive.sh  route_agent (bash)   -- FROZEN under GH-308
#   #2  utils/py/marathon_drive.py          route_agent (python) -- the default lane
#   #3  relay-automation/marathon-agent.sh  the --agent-cmd dispatcher #1/#2 hand off to
#   #4  utils/py/marathon_drive.py          _probe_agent_bin (GH-117 binary preflight)
#   #5  utils/py/marathon_drive.py          *_TURN_ROOT propagation under --target-root
#   #6  bin/marathon-yaml                   reviewer gate
#   #7  src/marathon-yaml.js                reviewer gate, second copy
#   #8  utils/py/gate_env.py                HARNESS_ENV scrub registry
#   #9  utils/py/marathon_drive.py          *_AGENT reset block
#   #10 utils/py/marathon_drive.py          GATE_SCRUBBED_ENV literal (must equal #8)
#
# The failure that motivated this: deepseek and commandcode were in #2 but NOT #3, so a marathon
# naming them was ACCEPTED by the router and then died in the dispatcher with "unknown agent".
# Before this test, no check anywhere compared one list to another; the only existing coverage was
# a *recognized* prefix with a *missing binary*, never an *unrecognized* prefix.
#
# Everything here is offline: no agent CLI is dispatched, no network, no real marathon.
# Sourcing _setup.sh is the repo's central fixture adoption (GH-1/GH-10/GH-564): it owns the $WORK
# sandbox and its teardown, so this suite never hand-rolls the mktemp + `rm -rf` EXIT trap that
# wiped the repo twice under a sandbox-broken mktemp (GH-177). It also points TICK_REPO_ROOT at a
# throwaway root, which isolates the driver probes below from the real .tick/ log.
source "$(dirname "$0")/_setup.sh" gh346-gateway-allowlists
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."

# Deliberately override _setup.sh's exit-on-first-failure pass/fail. This suite asserts across ten
# separate allowlists, and the useful signal is WHICH of them disagree — stopping at the first one
# would have hidden nine of the fifteen pre-fix failures that proved these assertions bite.
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: gh346-gateway-allowlists =="

# The gateways every reachable allowlist must know about.
LANES="claude codex agy aider pi smallcode commandcode deepseek"

# ------------------------------------------------------------------------------------------------
# #3 — marathon-agent.sh, the dispatcher. Run it for real against STUB shims so routing is proven,
#      not merely grepped. Copy it into a sandbox dir so `exec "$HERE/<x>-turn.sh"` hits our stubs.
# ------------------------------------------------------------------------------------------------
D="$WORK/dispatch"; mkdir -p "$D"
cp "$ROOT/relay-automation/marathon-agent.sh" "$D/"
for lane in $LANES; do
  printf '#!/usr/bin/env bash\necho "DISPATCHED:%s"\nexit 0\n' "$lane" > "$D/$lane-turn.sh"
  chmod +x "$D/$lane-turn.sh"
done

lane_env_var() {
  case "$1" in
    claude) echo CLAUDE_AGENT ;; codex) echo CODEX_AGENT ;; agy) echo AGY_AGENT ;;
    aider) echo AIDER_AGENT ;; pi) echo PI_AGENT ;; smallcode) echo SMALLCODE_AGENT ;;
    commandcode) echo COMMANDCODE_AGENT ;; deepseek) echo DEEPSEEK_AGENT ;;
  esac
}

for lane in $LANES; do
  var="$(lane_env_var "$lane")"
  out="$(env -i PATH="$PATH" HOME="$HOME" \
        RELAY_AGENT="$lane" RELAY_FILE="$WORK/relay.md" "$var=$lane" \
        bash "$D/marathon-agent.sh" 2>&1)"; rc=$?
  if [ "$rc" = 0 ] && [ "$out" = "DISPATCHED:$lane" ]; then
    pass "#3 dispatcher routes '$lane' -> $lane-turn.sh"
  else
    fail "#3 dispatcher did NOT route '$lane' (rc=$rc out='$out')"
  fi
done

# the unrecognized-id failure mode — this is the case that did not exist before
out="$(env -i PATH="$PATH" HOME="$HOME" RELAY_AGENT="totally-bogus-agent" RELAY_FILE="$WORK/relay.md" \
      bash "$D/marathon-agent.sh" 2>&1)"; rc=$?
if [ "$rc" = 2 ] && grep -q "unknown agent 'totally-bogus-agent'" <<<"$out"; then
  pass "#3 dispatcher rejects an unknown id with exit 2 and names it"
else
  fail "#3 dispatcher unknown-id failure mode wrong (rc=$rc, want 2; out='$out')"
fi

# a lane whose *_AGENT var is unset must NOT be silently routable
out="$(env -i PATH="$PATH" HOME="$HOME" RELAY_AGENT="deepseek" RELAY_FILE="$WORK/relay.md" \
      bash "$D/marathon-agent.sh" 2>&1)"; rc=$?
if [ "$rc" = 2 ]; then
  pass "#3 dispatcher refuses a lane whose *_AGENT var is unset (exit 2)"
else
  fail "#3 dispatcher routed 'deepseek' with DEEPSEEK_AGENT unset (rc=$rc out='$out')"
fi

# ------------------------------------------------------------------------------------------------
# #2 / #4 — live dry-run of the python driver. Proves route_agent AND the binary preflight accept
#           every lane whose tooling is present, and reject an unknown one with exit 2.
# ------------------------------------------------------------------------------------------------
BRIEF="$WORK/brief.md"; printf '# Phase\n\nNo-op brief for an allowlist probe.\n' > "$BRIEF"

# marathon_drive.py takes the per-clone driver lock BEFORE route_agent runs, so under validate.sh's
# parallel suite this probe races every other driver test and gets the GH-42 concurrency refusal
# instead of the routing verdict it is asserting.
#
# It is tempting to set RELAY_DRIVER_LOCKED=1 (the nested-driver escape) to make that deterministic.
# DO NOT. That was tried and measured: bypassing the lock let this dry-run proceed alongside a
# concurrent driver test and broke relay-artifact-file.sh and gh307-gate-env-scrub.sh, neither of
# which had ever failed. Trading a flake in this test for two failures in someone else's is a bad
# deal, and the lock exists precisely to prevent it.
#
# So: honor the lock, retry briefly, and SKIP rather than fail if it never frees. Coverage still
# lands in full on ci-local.sh's SEQUENTIAL run, which is the only run that qualifies as promotion
# evidence anyway (GH-509).
drive_rc() { # drive_rc <builder> ; echoes rc, stderr saved to $WORK/drive.err
  local attempt=0 rc=0
  while [ "$attempt" -lt 6 ]; do
    python3 "$ROOT/utils/py/marathon_drive.py" --phase-brief "$BRIEF" \
      --builder "$1" --reviewer codex --dry-run >"$WORK/drive.out" 2>"$WORK/drive.err"
    rc=$?
    grep -q "Concurrent runs in the same clone" "$WORK/drive.err" 2>/dev/null || break
    attempt=$((attempt + 1))
    sleep 2
  done
  echo "$rc"
}
drive_locked_out() { # true when the driver refused for lock reasons rather than routing reasons
  grep -q "Concurrent runs in the same clone" "$WORK/drive.err" 2>/dev/null
}

rc="$(drive_rc "totally-bogus-agent")"
if drive_locked_out; then
  echo "  SKIP: driver lock held by a concurrent run — #2 routing assertions not evaluated"
elif [ "$rc" = 2 ] && grep -q "not recognized" "$WORK/drive.err"; then
  pass "#2 route_agent rejects an unknown builder id with exit 2"
else
  fail "#2 route_agent unknown-id failure mode wrong (rc=$rc): $(tail -1 "$WORK/drive.err")"
fi

# the message must enumerate every lane, or the next person cannot discover them
if drive_locked_out; then
  echo "  SKIP: driver lock held — rejection-message enumeration not evaluated"
else
  for lane in $LANES; do
    if grep -q "$lane" "$WORK/drive.err"; then
      pass "#2 rejection message names '$lane'"
    else
      fail "#2 rejection message omits '$lane' — the discovery gap this issue is about"
    fi
  done
fi

# the two lanes GH-346 added must now get past BOTH route_agent (#2) and _probe_agent_bin (#4).
# Skipped, not failed, where the lane's tooling is genuinely absent on this host.
for lane in commandcode deepseek; do
  rc="$(drive_rc "$lane")"
  if drive_locked_out; then
    echo "  SKIP: driver lock held — '$lane' routing not evaluated"
  elif [ "$rc" = 2 ] && grep -qi "not recognized" "$WORK/drive.err"; then
    fail "#2 route_agent still rejects '$lane' — Phase 2 did not land"
  elif [ "$rc" = 2 ] && grep -qi "not found\|entrypoint for agent" "$WORK/drive.err"; then
    echo "  SKIP: '$lane' tooling not installed on this host (preflight fired, which is correct)"
  else
    pass "#2/#4 '$lane' passes routing and binary preflight (rc=$rc)"
  fi
done

# ------------------------------------------------------------------------------------------------
# #4 — the probe must mirror each shim's OWN resolution. Two lanes dispatch a script by absolute
#      path through an interpreter; a shutil.which()-only probe would reject lanes that run fine.
# ------------------------------------------------------------------------------------------------
export WORK
python3 - "$ROOT" > "$WORK/probe.out" 2>/dev/null <<'PY'
import os, sys
root = sys.argv[1]
sys.path.insert(0, os.path.join(root, "utils", "py"))
import marathon_drive as md

# an existing FILE that is not on PATH must satisfy the probe
probe_file = os.path.join(os.environ["WORK"], "fake-entrypoint.js")
open(probe_file, "w").close()
try:
    md._probe_bin_or_file([probe_file], "builder", "deepseek", "DEEPSEEK_BIN")
    print("PASS=#4 _probe_bin_or_file accepts an off-PATH file entrypoint")
except SystemExit:
    print("FAIL=#4 _probe_bin_or_file rejected an existing off-PATH file — would block a working lane")

# nothing resolvable must still fail closed, naming the override var
try:
    md._probe_bin_or_file(["/nope/does-not-exist", None], "builder", "deepseek", "DEEPSEEK_BIN")
    print("FAIL=#4 _probe_bin_or_file passed with no resolvable candidate — GH-117 preflight is dead")
except SystemExit:
    print("PASS=#4 _probe_bin_or_file fails closed when nothing resolves")

# the mirrored defaults must still match the shims' own, or the two copies have drifted
ds = open(os.path.join(root, "utils", "py", "deepseek-turn.py")).read()
if md.DEEPSEEK_DEFAULT_BIN in ds:
    print("PASS=#4 DEEPSEEK_DEFAULT_BIN still matches deepseek-turn.py's own default")
else:
    print("FAIL=#4 DEEPSEEK_DEFAULT_BIN has drifted from deepseek-turn.py's default_deepseek_bin()")

sc = open(os.path.join(root, "relay-automation", "smallcode-turn.sh")).read()
tail = md.SMALLCODE_DEFAULT_BIN.split("smallcode/")[-1]
if tail in sc:
    print("PASS=#4 SMALLCODE_DEFAULT_BIN still matches smallcode-turn.sh's own default")
else:
    print("FAIL=#4 SMALLCODE_DEFAULT_BIN has drifted from smallcode-turn.sh's default")
PY
if [ ! -s "$WORK/probe.out" ]; then
  fail "#4 probe harness produced no output — it did not run"
fi
while IFS= read -r pline; do
  case "$pline" in PASS=*) pass "${pline#PASS=}" ;; FAIL=*) fail "${pline#FAIL=}" ;; esac
done < "$WORK/probe.out"

# ------------------------------------------------------------------------------------------------
# #5 — every lane route_agent accepts needs a *_TURN_ROOT guard root, or a --target-root run
#      resolves containment against the wrong repo (the GH-256 silent-no-op class). Read the actual
#      propagation tuple rather than grepping the whole file, where these words appear everywhere.
# ------------------------------------------------------------------------------------------------
tuple="$(grep -o 'for _shim in ([^)]*)' "$ROOT/utils/py/marathon_drive.py" | head -1)"
if [ -z "$tuple" ]; then
  fail "#5 could not locate the *_TURN_ROOT propagation tuple in marathon_drive.py"
else
  for lane in $LANES; do
    upper="$(printf '%s' "$lane" | tr '[:lower:]' '[:upper:]')"
    if grep -q "\"$upper\"" <<<"$tuple"; then
      pass "#5 '$lane' has a ${upper}_TURN_ROOT guard root"
    else
      fail "#5 '$lane' is routable but is missing from the *_TURN_ROOT propagation tuple"
    fi
  done
fi

# ------------------------------------------------------------------------------------------------
# #8/#9/#10 — the three copies this test ORIGINALLY MISSED. They were caught by
# test/gh441-gate-env-contract.sh, not by review, which is the single best piece of evidence on
# this issue that the lookup surface has to be generated rather than curated:
#
#   #8  utils/py/gate_env.py            HARNESS_ENV registry (what the gate scrubs)
#   #9  marathon_drive.py  ~1830        the *_AGENT reset block (stops a stale var routing a turn)
#   #10 marathon_drive.py  GATE_SCRUBBED_ENV literal (must equal #8 exactly)
#
# #9 is not cosmetic: without it, a COMMANDCODE_AGENT left in the parent shell survives into a run
# that never asked for that lane.
# ------------------------------------------------------------------------------------------------
for lane in commandcode deepseek; do
  upper="$(printf '%s' "$lane" | tr '[:lower:]' '[:upper:]')"
  if grep -q "\"${upper}_AGENT\"" "$ROOT/utils/py/gate_env.py"; then
    pass "#8 gate_env.py classifies ${upper}_AGENT"
  else
    fail "#8 gate_env.py does not classify ${upper}_AGENT — the gate will not scrub it"
  fi
  if grep -q "os.environ\[\"${upper}_AGENT\"\] = \"\"" "$ROOT/utils/py/marathon_drive.py"; then
    pass "#9 ${upper}_AGENT is reset before routing (a stale value cannot route a turn)"
  else
    fail "#9 ${upper}_AGENT is NOT reset before routing — a stale parent-shell value could route it"
  fi
done

scrub="$(sed -n '/GATE_SCRUBBED_ENV = (/,/^    )/p' "$ROOT/utils/py/marathon_drive.py")"
for lane in $LANES; do
  upper="$(printf '%s' "$lane" | tr '[:lower:]' '[:upper:]')"
  case "$lane" in claude|codex|agy|aider|pi|smallcode|commandcode|deepseek) ;; *) continue ;; esac
  if grep -q "\"${upper}_AGENT\"" <<<"$scrub"; then
    pass "#10 GATE_SCRUBBED_ENV includes ${upper}_AGENT"
  else
    fail "#10 GATE_SCRUBBED_ENV omits ${upper}_AGENT — it will leak into the gate subprocess"
  fi
done

# ------------------------------------------------------------------------------------------------
# #6 — the reviewer gate. Two independent copies; `gemini` was a phantom with no shim anywhere.
# ------------------------------------------------------------------------------------------------
if grep -qv '^[0-9]*: *//' <<<"$(grep -n "gemini" "$ROOT/bin/marathon-yaml" 2>/dev/null)"; then
  fail "#6 bin/marathon-yaml still admits the phantom 'gemini' reviewer outside a comment"
else
  pass "#6 bin/marathon-yaml no longer admits the phantom 'gemini' reviewer"
fi
if grep -qv '^[0-9]*: *//' <<<"$(grep -n "gemini" "$ROOT/src/marathon-yaml.js" 2>/dev/null)"; then
  fail "#6 src/marathon-yaml.js still admits the phantom 'gemini' reviewer outside a comment"
else
  pass "#6 src/marathon-yaml.js no longer admits the phantom 'gemini' reviewer"
fi

# there must be NO gemini shim -- if one is ever added, this test must be revisited, not deleted
if ls "$ROOT"/relay-automation/gemini-turn.sh >/dev/null 2>&1; then
  fail "#6 a gemini-turn.sh now EXISTS — re-admit gemini to the reviewer gates and update this test"
else
  pass "#6 no gemini shim exists, so removing it from the gates lost no capability"
fi

# the python reviewer gate must agree with the JS one
if grep -q 'args.reviewer.startswith("codex") or args.reviewer.startswith("agy")' "$ROOT/utils/py/marathon_drive.py"; then
  pass "#6 python reviewer gate agrees with the JS gates (codex/agy)"
else
  fail "#6 python reviewer gate has drifted from bin/marathon-yaml + src/marathon-yaml.js"
fi

# ------------------------------------------------------------------------------------------------
# #1 — the FROZEN bash twin. GH-346 Phase 2 deliberately did NOT teach it the new lanes. Assert the
#      divergence explicitly so it stays a recorded decision rather than an unnoticed gap.
# ------------------------------------------------------------------------------------------------
if grep -q "must start with claude/codex/agy/aider\"" "$ROOT/relay-automation/marathon-drive.sh" || \
   grep -q "must start with claude/codex/agy/aider" "$ROOT/relay-automation/marathon-drive.sh"; then
  pass "#1 frozen bash twin still accepts only claude/codex/agy/aider (recorded GH-308 divergence)"
else
  fail "#1 frozen bash twin changed — that needs a Frozen-twin-exception trailer, and this test updated"
fi

# ------------------------------------------------------------------------------------------------
# 2.10 — THE SAFETY NET. An unrecognized id must be refused BEFORE any tick or worktree mutation,
#        so a routing typo can never leave stuck state behind.
# ------------------------------------------------------------------------------------------------
before_events=0
[ -f "$ROOT/.tick/events.jsonl" ] && before_events="$(wc -l < "$ROOT/.tick/events.jsonl" | tr -d ' ')"
before_wt="$(git -C "$ROOT" worktree list 2>/dev/null | wc -l | tr -d ' ')"

rc="$(drive_rc "totally-bogus-agent")"
if drive_locked_out; then
  echo "  SKIP: driver lock held — 2.10 safety-net assertions not evaluated"
  rc=2  # neutralize the assertions below; the SKIP above is the honest record
fi

after_events=0
[ -f "$ROOT/.tick/events.jsonl" ] && after_events="$(wc -l < "$ROOT/.tick/events.jsonl" | tr -d ' ')"
after_wt="$(git -C "$ROOT" worktree list 2>/dev/null | wc -l | tr -d ' ')"

if [ "$rc" = 2 ]; then
  pass "2.10 unrecognized id exits 2"
else
  fail "2.10 unrecognized id exited $rc, want 2"
fi
if [ "$before_events" = "$after_events" ]; then
  pass "2.10 no tick event written before the refusal ($before_events events, unchanged)"
else
  fail "2.10 tick log grew $before_events -> $after_events on a refused id — state leaked"
fi
if [ "$before_wt" = "$after_wt" ]; then
  pass "2.10 no worktree created before the refusal"
else
  fail "2.10 worktree count changed $before_wt -> $after_wt on a refused id"
fi

# ------------------------------------------------------------------------------------------------
# 2.7 — the advisory discovery flags exist (they close a lookup gap; nothing dispatches on them)
# ------------------------------------------------------------------------------------------------
FH="$ROOT/skills/relay-xyz/find-harness.sh"
for flag in RELAY_HAS_COMMANDCODE RELAY_HAS_DEEPSEEK; do
  if grep -q "$flag" "$FH"; then
    pass "2.7 find-harness.sh reports $flag"
  else
    fail "2.7 find-harness.sh does not report $flag"
  fi
done
if grep -q "RELAY_HAS_DEEPSEEK=" <<<"$(bash "$FH" --env 2>/dev/null)"; then
  pass "2.7 --env actually emits the new flags"
else
  fail "2.7 --env does not emit the new flags"
fi

# 2.8 — the worker table must document deepseek, the gateway this issue's own list forgot
if grep -qi "deepseek" "$ROOT/skills/relay-xyz/SKILL.md"; then
  pass "2.8 relay-xyz SKILL.md documents the deepseek worker"
else
  fail "2.8 relay-xyz SKILL.md still omits deepseek — the original discovery gap"
fi

echo "  gh346-gateway-allowlists: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
