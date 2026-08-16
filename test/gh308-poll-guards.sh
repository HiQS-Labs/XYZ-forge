#!/usr/bin/env bash
# test/gh308-poll-guards.sh — GH-308 audit: poll.sh carried several guards/features that poll.py
# (the lane that actually runs since GH-264) did not, so they were silently dead on the default lane:
#   - --help (Bash-only; Python rejected it as an unknown flag)
#   - --mode value validation (invalid mode silently ran as xyz)
#   - --turn-source value whitelist (garbage silently treated as tick)
#   - --turn-source file requires --mode relay (silently ignored in xyz)
#   - stray positional args (silently skipped instead of rejected)
#   - the GH-92 residue WARNING (a stall-forever diagnostic that only printed in Bash)
#   - the --watchdog-cmd DEFAULT (Python left it "", so a run-watchdog decision dispatched NOTHING)
# Every case drives the DEFAULT (Python) lane and compares it to XYZ_PYTHON=0 (Bash) — the guards must
# behave identically. Model: test/gh289-target-root-build-turn.sh (dual-lane).
source "$(dirname "$0")/_setup.sh" gh308-poll-guards

POLL="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/poll.sh"

# Run a poll invocation on both lanes; assert identical rc AND identical last stderr/stdout line.
both_lanes_same() { # <desc> <expect-rc> <arg...>
  local desc="$1" want_rc="$2"; shift 2
  local py sh pyrc shrc
  py="$(bash "$POLL" "$@" 2>&1)"; pyrc=$?
  sh="$(XYZ_PYTHON=0 bash "$POLL" "$@" 2>&1)"; shrc=$?
  if [ "$pyrc" -eq "$want_rc" ] && [ "$shrc" -eq "$want_rc" ] && [ "$py" = "$sh" ]; then
    pass "poll [$desc]: both lanes rc=$want_rc, identical output"
  else
    fail "poll [$desc]: py(rc=$pyrc) sh(rc=$shrc) want=$want_rc; identical=$([ "$py" = "$sh" ] && echo yes || echo no)
    python: $(printf '%s' "$py" | tail -1)
    bash:   $(printf '%s' "$sh" | tail -1)"
  fi
}

# --help — Bash-only until the port; Python used to `die("Unknown flag: --help")` (rc 2).
both_lanes_same "--help exits 0 with usage" 0 --help

# invalid --mode — Python used to fall through to the xyz branch and idle (rc 0).
both_lanes_same "invalid --mode rejected" 2 --mode bogus --agent a --task T --dry-run

# invalid --turn-source — Python used to treat any non-'file' value as tick silently.
both_lanes_same "invalid --turn-source rejected" 2 --mode relay --agent me --turn-source garbage --relay-file /nope --dry-run

# --turn-source file requires --mode relay — Python had no such check.
both_lanes_same "turn-source file requires relay mode" 2 --mode xyz --agent a --turn-source file --task T --dry-run

# stray positional token — Python used `else: i+=1` (silently ignored); Bash `*) die unknown argument`.
both_lanes_same "stray positional rejected" 2 --mode xyz --agent a --task T --dry-run stray

# GH-92 residue WARNING: a nudge-cross-model whose parsed NEXT value still carries residue relay_field
# could not strip (`claude*reb`) must warn LOUD on both lanes (this silent gap stalled a live relay).
printf 'STATUS: Open\nNEXT: claude*reb\n' >"$A/gh92.md"
GH92_ARGS=(--mode relay --agent me --turn-source file --relay-file "$A/gh92.md" --dry-run)
py92="$(bash "$POLL" "${GH92_ARGS[@]}" 2>&1)"
sh92="$(XYZ_PYTHON=0 bash "$POLL" "${GH92_ARGS[@]}" 2>&1)"
if printf '%s' "$py92" | grep -qF 'WARNING (GH-92)' && [ "$py92" = "$sh92" ]; then
  pass "poll [GH-92 residue]: default lane warns, byte-identical to Bash"
else
  fail "poll [GH-92 residue]: default lane missing the GH-92 warning or diverged from Bash:
    python: $py92
    bash:   $sh92"
fi

# --watchdog-cmd DEFAULT: a run-watchdog decision with NO --watchdog-cmd must dispatch the repo's
# watchdog.sh. Python left the default "", so run_cmd("") no-op'd and the escalation path was dead.
# Drive a real (non-dry-run) run-watchdog and assert the default watchdog actually ran (its marker).
printf '{"parked_suspects":["FOO-1"]}\n' >"$A/analysis.json"
WD_ARGS=(--mode xyz --agent me --task T --analysis-file "$A/analysis.json" --watchdog-authority)
pywd="$(TICK_REPO_ROOT="$A" bash "$POLL" "${WD_ARGS[@]}" 2>&1)"
if printf '%s' "$pywd" | grep -q 'DECISION: run-watchdog' && printf '%s' "$pywd" | grep -q '^watchdog:'; then
  pass "poll [watchdog default]: run-watchdog dispatches the default watchdog.sh on the live lane"
else
  fail "poll [watchdog default]: run-watchdog dispatched nothing (default watchdog.sh not wired): $pywd"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
