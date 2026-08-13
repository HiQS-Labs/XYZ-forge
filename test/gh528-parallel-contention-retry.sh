#!/usr/bin/env bash
# test/gh528-parallel-contention-retry.sh — GH-528: `validate.sh --parallel N` must not report a
# failure the sequential gate does not have.
#
# THE DEFECT THIS PINS, observed 2026-08-13. The parallel mode serializes the suites that execute the
# real relay-drive.sh into one lane, because they contend on this clone's .git/relay-driver.lock
# (GH-42). That lane list is hand-maintained, and it was WRONG on first reuse:
# gh322-unknown-arg-rejection.sh never drives anything — it passes a bogus flag and asserts both
# twins exit 2 — but relay-drive.sh takes the lock BEFORE it parses arguments, so under contention
# the Bash twin exits 1 (lock refusal) while the Python twin exits 2. The suite then reported
# "exit codes diverge — Python 2, Bash 1": a plausible, on-topic, completely false parity failure.
# Invoking a driver AT ALL is what makes a suite contend, not invoking it to do work, so the list
# cannot be validated by reading it — and the failure is a RACE, so it does not reproduce reliably
# enough to be caught by re-running.
#
# The mechanism under test is therefore the safety net, not the list: any suite that fails in the
# pool is re-run ALONE, with the lane finished and the lock free, before the failure is believed.
# Fails alone too -> real failure. Passes alone -> counted passed (sequential is the source of
# truth) and NAMED in a warning, so an incomplete lane list is loud instead of silent.
#
# gate-evidence: {"form":"mutation","observed":true,"result":"pre-fix revision: validate.sh with the serialized re-run block deleted (the state shipped in the first GH-528 build). pre-fix result: FAIL — the probe suite is reported as a failed suite and the run exits 1, which is exactly how gh322 surfaced. post-fix result: 4 pass / 0 fail; the probe is counted as passed and named in the contention warning"}
source "$(dirname "$0")/_setup.sh" gh528-parallel-contention-retry

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# A probe suite with the exact shape of a contention failure: red the first time, green the second.
# It stands in for the race deliberately — driving a REAL lock collision would need a live driver and
# would still be timing-dependent, which is the property that let the defect through in the first place.
PROBE="$WORK/probe-suite.sh"
cat > "$PROBE" <<'EOF'
#!/usr/bin/env bash
FLAG="${GH528_PROBE_FLAG:?}"
[ -e "$FLAG" ] && { echo "probe: second run"; exit 0; }
: > "$FLAG"
echo "probe: first run"
exit 1
EOF
chmod +x "$PROBE"

# The probe must be reachable as test/<name>.sh, since that is how validate.sh resolves a suite.
PROBE_NAME="_gh528-probe-$$.sh"
cp "$PROBE" "$ROOT/test/$PROBE_NAME"

# A copy of validate.sh with ONLY the TESTS array swapped: every line of the parallel implementation
# is preserved, so this exercises the shipped code rather than a re-implementation of it.
VP="$ROOT/.gh528-validate-probe-$$.sh"
python3 - "$VP" "$PROBE_NAME" <<'PY'
import re, sys
out, probe = sys.argv[1], sys.argv[2]
src = open('validate.sh').read()
new, n = re.subn(r'\nTESTS=\(.*?\n\)\n', '\nTESTS=(\n  %s\n)\n' % probe, src, count=1, flags=re.S)
assert n == 1, "TESTS array not found in validate.sh"
open(out, 'w').write(new)
PY

# _setup.sh:57 already owns an EXIT trap that removes $WORK and re-asserts the exit code under
# TEST_SOFT_FAIL. Replacing it would leak the workdir and break soft-fail's verdict, so this
# re-registers the SAME behaviour with the probe files added — it does not override it.
trap '_rc=$?; rm -f "$VP" "$ROOT/test/$PROBE_NAME"; rm -rf "$WORK"; if [ "${TEST_SOFT_FAIL:-0}" = "1" ] && [ "${FAIL:-0}" -gt 0 ]; then exit 1; fi; exit "$_rc"' EXIT

export GH528_PROBE_FLAG="$WORK/probe.flag"
rm -f "$GH528_PROBE_FLAG"
out="$(bash "$VP" --parallel 4 2>&1)"

# (1) the failure is re-run alone rather than believed on the strength of one contended attempt
if printf '%s' "$out" | grep -q "re-running it alone"; then
  pass "a parallel failure is re-run serially before it is believed"
else
  fail "GH-528: a pooled failure was reported without a serial re-run — a lock refusal would read as a real failure"
fi

# (2) surviving the re-run means it counts as PASSED: sequential is the source of truth, and the
#     whole promise of --parallel is that it returns the same answer as sequential.
if printf '%s' "$out" | grep -qE "^  \+ $PROBE_NAME"; then
  pass "a suite that passes alone is counted as passed, matching the sequential verdict"
else
  fail "GH-528: a suite that passes when run alone was still reported as failed — --parallel disagrees with sequential"
fi

# (3) it must NOT be silently absorbed: the point of failing under concurrency is that the lane list
#     is incomplete, and that has to reach a human or it never gets fixed.
if printf '%s' "$out" | grep -q "WARNING (GH-528)" && printf '%s' "$out" | grep -q "$PROBE_NAME"; then
  pass "the contended suite is named in a warning (an incomplete lane list cannot fail silently)"
else
  fail "GH-528: no warning named the contended suite — the lane-list gap would go unnoticed"
fi

# (4) the lane is an INTERSECTION with TESTS, not the literal list. Iterating the literal ran lane
#     suites that TESTS did not contain, so --parallel executed suites the sequential path skipped
#     and the summary counted more results than TOTAL ("passed: 16 / 3", observed 2026-08-13).
if printf '%s' "$out" | grep -qE "0 in the sequential driver-lock lane"; then
  pass "the lock lane is derived from TESTS, so both paths run the same set of suites"
else
  fail "GH-528: the lane ran suites absent from TESTS — --parallel and sequential disagree on WHAT runs"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
