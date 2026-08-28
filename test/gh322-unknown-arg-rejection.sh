#!/usr/bin/env bash
# GH-322: an unrecognised flag must be REJECTED by the Python lane, not silently discarded.
#
# All three Python twins called `args, unknown = parser.parse_known_args()` and never read `unknown`.
# Because Python is the executing lane (GH-264), any flag the Python twin did not define was thrown
# away without a word. That is how GH-284 Phase 2's `--log-github` — implemented in the Bash twin
# only — became a no-op: the marathon ran, exited 0, reported success, and never posted a run log.
#
# `--log-github` itself is no longer an example of that: Phase 2 has since been ported into
# utils/py/marathon_drive.py (test/gh322-runlog-python-lane.sh), so the lane must now ACCEPT it. The
# general defect this file guards — an unknown flag vanishing without a word — is unchanged, and the
# --log-github block at the bottom was inverted to match.
#
# Every Bash twin has always had `*) die "unknown argument: $1"`. This pins that the Python lane now
# does the same thing, with the same message and the same exit code, for all three entry points.
#
# Same discipline as test/gh320-twin-timeout-parity.sh: compare the two LANES against each other
# rather than against a hardcoded expectation, so the test cannot drift away from either.
source "$(dirname "$0")/_setup.sh" gh322-unknown-arg-rejection
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

ENTRYPOINTS=(
  "relay-automation/marathon-drive.sh:marathon-drive"
  "relay-automation/relay-drive.sh:relay-drive"
  "utils/swarm-preflight.sh:swarm-preflight"
)
BOGUS="--gh322-definitely-not-a-real-flag"

for entry in "${ENTRYPOINTS[@]}"; do
  rel="${entry%%:*}"; name="${entry##*:}"
  script="$ROOT/$rel"
  [ -f "$script" ] || { fail "$name: $rel not found"; continue; }

  py_out="$(bash "$script" "$BOGUS" 2>&1)"; py_rc=$?
  sh_out="$(XYZ_PYTHON=0 bash "$script" "$BOGUS" 2>&1)"; sh_rc=$?

  # (1) the Python lane must refuse at all — the whole defect was that it did not.
  if [ "$py_rc" -ne 0 ]; then
    pass "$name: Python lane rejects an unknown flag (exit $py_rc)"
  else
    fail "$name: Python lane ACCEPTED $BOGUS and exited 0 — the flag was silently discarded"
  fi

  # (2) exit codes must agree, so a caller branching on the code behaves the same either way.
  if [ "$py_rc" -eq "$sh_rc" ]; then
    pass "$name: both lanes exit $py_rc on an unknown flag"
  else
    fail "$name: exit codes diverge — Python $py_rc, Bash $sh_rc"
  fi

  # (3) the message must name the offending flag, in both lanes.
  if printf '%s' "$py_out" | grep -Fq "unknown argument: $BOGUS"; then
    pass "$name: Python lane names the offending flag"
  else
    fail "$name: Python message does not name the flag: $py_out"
  fi
  if printf '%s' "$sh_out" | grep -Fq "unknown argument: $BOGUS"; then
    pass "$name: Bash lane names the offending flag"
  else
    fail "$name: Bash message does not name the flag: $sh_out"
  fi

  # (4) the DIAGNOSTIC LINE must be byte-identical between the lanes. This is what keeps them
  # honest — (1)-(3) would all still pass if one lane changed its prefix or wording.
  #
  # The line, not the whole output: swarm-preflight's Bash `*)` case prints its full usage block
  # while the Python twin's `--help` has always printed a one-liner. That divergence pre-dates
  # GH-322 and is a `--help` question, not an unknown-argument one — asserting whole-output
  # equality here would either fail for an unrelated reason or force the usage text to be
  # duplicated into Python, which is a second copy to drift.
  py_line="$(printf '%s\n' "$py_out" | grep -F 'unknown argument:' | head -1)"
  sh_line="$(printf '%s\n' "$sh_out" | grep -F 'unknown argument:' | head -1)"
  if [ -n "$py_line" ] && [ "$py_line" = "$sh_line" ]; then
    pass "$name: both lanes emit an identical diagnostic line"
  else
    fail "$name: diagnostic lines differ.
    python: $py_line
    bash:   $sh_line"
  fi

  # (5) ordering: when a lane prints usage alongside the diagnostic, the diagnostic must come LAST.
  # usage goes to stdout and die() to stderr, so without an explicit flush they interleave wrong
  # under 2>&1 and the error appears above the usage it is meant to follow.
  if grep -q '^Usage:' <<<"$(printf '%s\n' "$py_out")"; then
    if [ "$(printf '%s\n' "$py_out" | tail -1)" = "$py_line" ]; then
      pass "$name: Python lane prints usage before the diagnostic, not after"
    else
      fail "$name: Python lane emitted the diagnostic before its usage line (missing stdout flush): $py_out"
    fi
  fi
done

# ── --log-github specifically: the flag that motivated the issue ─────────────────────────
# This assertion has been INVERTED, deliberately. Until the port landed, --log-github existed in the
# Bash twin only, so the contract was "refuse loudly and name the workaround (XYZ_PYTHON=0)" — an
# interim state, not a destination. GH-284 Phase 2 is now implemented in the Python lane too, so the
# flag must be ACCEPTED there; a lane that still refused it would be the bug now. Behaviour under
# test here is only "the parser recognises it"; whether it posts is
# test/gh322-runlog-python-lane.sh's job.
py_out="$(MARATHON_ROOT="$WORK/mroot-parse" bash "$ROOT/relay-automation/marathon-drive.sh" --log-github 2>&1)"; py_rc=$?
printf '%s' "$py_out" | grep -Fq "unknown argument" \
  && fail "--log-github is still rejected as unknown by the Python lane — the port regressed: $py_out" \
  || pass "--log-github is a recognised flag on the Python lane (GH-284 P2 ported)"
printf '%s' "$py_out" | grep -Fq "XYZ_PYTHON=0" \
  && fail "the Python lane still advertises the XYZ_PYTHON=0 workaround for a feature it now implements: $py_out" \
  || pass "no stale 'use the Bash twin' workaround is advertised for --log-github"
# It must fail for a REAL reason (no --phase-brief), not for the flag — otherwise "accepted" could
# just mean argument parsing never ran at all.
[ "$py_rc" -eq 2 ] && printf '%s' "$py_out" | grep -Fq -- "--phase-brief" \
  && pass "--log-github alone falls through to the ordinary required-argument error" \
  || fail "expected the usual --phase-brief usage error (exit 2), got exit $py_rc: $py_out"

# ── --help must keep working ─────────────────────────────────────────────────────────────
# The rejection is deliberately checked AFTER --help, so a bad flag cannot make help unreachable.
help_out="$(MARATHON_ROOT="$WORK/mroot-parse" bash "$ROOT/relay-automation/relay-drive.sh" --help 2>&1)"; help_rc=$?
[ "$help_rc" -eq 0 ] && pass "--help still exits 0 on the Python lane" \
  || fail "--help regressed (exit $help_rc): $help_out"

echo "  gh322-unknown-arg-rejection: $PASS pass, $FAIL fail"
exit 0
