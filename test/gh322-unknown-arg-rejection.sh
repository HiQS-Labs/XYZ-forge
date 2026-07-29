#!/usr/bin/env bash
# GH-322: an unrecognised flag must be REJECTED by the Python lane, not silently discarded.
#
# All three Python twins called `args, unknown = parser.parse_known_args()` and never read `unknown`.
# Because Python is the executing lane (GH-264), any flag the Python twin did not define was thrown
# away without a word. That is how GH-284 Phase 2's `--log-github` — implemented in the Bash twin
# only — became a no-op: the marathon ran, exited 0, reported success, and never posted a run log.
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
  if printf '%s\n' "$py_out" | grep -q '^Usage:'; then
    if [ "$(printf '%s\n' "$py_out" | tail -1)" = "$py_line" ]; then
      pass "$name: Python lane prints usage before the diagnostic, not after"
    else
      fail "$name: Python lane emitted the diagnostic before its usage line (missing stdout flush): $py_out"
    fi
  fi
done

# ── --log-github specifically: the flag that motivated the issue ─────────────────────────
# It exists in the Bash twin only. A bare "unknown argument" would be true but useless, so the
# Python lane names the workaround. Pin that it refuses AND says where the feature lives.
py_out="$(bash "$ROOT/relay-automation/marathon-drive.sh" --log-github 2>&1)"; py_rc=$?
[ "$py_rc" -ne 0 ] \
  && pass "--log-github is refused by the Python lane rather than silently ignored" \
  || fail "--log-github still accepted-and-ignored by the Python lane (exit 0)"
printf '%s' "$py_out" | grep -Fq "XYZ_PYTHON=0" \
  && pass "the refusal names the lane that actually implements it" \
  || fail "refusal must tell the operator how to get the feature: $py_out"
printf '%s' "$py_out" | grep -Fq "#322" \
  && pass "the refusal points at the tracking issue for the port" \
  || fail "refusal should reference issue #322: $py_out"

# ── --help must keep working ─────────────────────────────────────────────────────────────
# The rejection is deliberately checked AFTER --help, so a bad flag cannot make help unreachable.
help_out="$(bash "$ROOT/relay-automation/relay-drive.sh" --help 2>&1)"; help_rc=$?
[ "$help_rc" -eq 0 ] && pass "--help still exits 0 on the Python lane" \
  || fail "--help regressed (exit $help_rc): $help_out"

echo "  gh322-unknown-arg-rejection: $PASS pass, $FAIL fail"
exit 0
