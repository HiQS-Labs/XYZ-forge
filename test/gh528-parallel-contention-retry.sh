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
# GH-15 extended this pin (2026-08-16). The retry existed but did not HONOR its contract under two
# conditions, both reproduced deterministically in the GH-15 investigation (Part 2 below):
#   (a) the serial re-run inherited the retry loop's stdin — which is the RESULTS file. A re-run
#       suite that merely read stdin swallowed every result line after it: a suite that always
#       fails was never re-run, never reported, and the run exited GREEN ("passed: 3 / 5" with the
#       always-failing suite silently uncounted — observed rc=0);
#   (b) a suite whose worker left no result line was uncounted everywhere.
# The fix gives every suite invocation stdin=/dev/null (the pool's own regime, via xargs), re-runs
# any suite missing from the results file, and refuses a verdict whose tally is short.
#
# gate-evidence: {"form":"mutation","observed":true,"result":"pre-fix revision: validate.sh with the serialized re-run block deleted (the state shipped in the first GH-528 build). pre-fix result: FAIL — the probe suite is reported as a failed suite and the run exits 1, which is exactly how gh322 surfaced. post-fix result: 9 pass / 0 fail; the probe is counted as passed and named in the contention warning. GH-15 control, same investigation: with Part 2's probes against the PRE-FIX retry, the always-failing victim is never reported and the probe run exits 0 — assertion (5) is red and fail-fast stops the file there, while Part 1 stays 4/4 green"}
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
# make_probe_validate <dest> <suite-name>... — one probe suite per extra argument.
make_probe_validate() {
  python3 - "$ROOT" "$@" <<'PY'
import re, sys
root, out, probes = sys.argv[1], sys.argv[2], sys.argv[3:]
src = open(root + '/validate.sh').read()
block = '\nTESTS=(\n' + ''.join('  "%s"\n' % p for p in probes) + ')\n'
new, n = re.subn(r'\nTESTS=\(.*?\n\)\n', block, src, count=1, flags=re.S)
assert n == 1, "TESTS array not found in validate.sh"
open(out, 'w').write(new)
PY
}
VP="$ROOT/.gh528-validate-probe-$$.sh"
make_probe_validate "$VP" "$PROBE_NAME"

# GH-15 Part 2 probes. SWALLOWER stands in for the observed hazard: a pooled failure whose serial
# re-run reads stdin — pre-fix that stdin was the RESULTS file, so the re-run swallowed every
# verdict recorded after it. VICTIM is the verdict it swallowed: a suite that ALWAYS fails, which a
# contract-honoring retry must re-run, report, and fail the run for.
export GH528_PROBE_FLAG="$WORK/probe.flag"
rm -f "$GH528_PROBE_FLAG" "$GH528_PROBE_FLAG.sw"
SWALLOWER_NAME="_gh15-swallower-$$.sh"
VICTIM_NAME="_gh15-victim-$$.sh"
cat > "$ROOT/test/$SWALLOWER_NAME" <<EOF
#!/usr/bin/env bash
if [ ! -e "$GH528_PROBE_FLAG.sw" ]; then : > "$GH528_PROBE_FLAG.sw"; exit 1; fi
cat > /dev/null   # re-run: drain whatever stdin we inherited (pre-fix: the results file)
exit 0
EOF
cat > "$ROOT/test/$VICTIM_NAME" <<'EOF'
#!/usr/bin/env bash
sleep 1
echo "victim: deterministic failure (GH-15 probe)"
exit 7
EOF
VP2="$ROOT/.gh15-validate-probe-$$.sh"
make_probe_validate "$VP2" "$SWALLOWER_NAME" "$VICTIM_NAME"

# _setup.sh:57 already owns an EXIT trap that removes $WORK and re-asserts the exit code under
# TEST_SOFT_FAIL. Replacing it would leak the workdir and break soft-fail's verdict, so this
# re-registers the SAME behaviour with the probe files added — it does not override it.
trap '_rc=$?; rm -f "$VP" "$VP2" "$ROOT/test/$PROBE_NAME" "$ROOT/test/$SWALLOWER_NAME" "$ROOT/test/$VICTIM_NAME"; rm -rf "$WORK"; if [ "${TEST_SOFT_FAIL:-0}" = "1" ] && [ "${FAIL:-0}" -gt 0 ]; then exit 1; fi; exit "$_rc"' EXIT

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

# ── GH-15 Part 2: the retry must honor its contract even when a re-run suite reads stdin ──────────
# SWALLOWER fails in the pool and its serial re-run drains stdin; VICTIM always fails and its result
# line sits AFTER the swallower's. Pre-fix, the re-run's stdin was the results file, so the victim's
# line was swallowed: never re-run, never reported, and the probe run exited 0 (observed in the GH-15
# investigation: "passed: 3 / 5", rc=0, with the always-failing suite counted nowhere).
out2="$(bash "$VP2" --parallel 2 2>&1)"; rc2=$?

# (5) the swallowed-after verdict is STILL re-run alone and reported as a real failure
if printf '%s' "$out2" | grep -q "NO RESULT recorded in parallel: $VICTIM_NAME\|FAILED in parallel (rc=7): $VICTIM_NAME" \
   && printf '%s' "$out2" | grep -qE "^  - $VICTIM_NAME"; then
  pass "a failure recorded after a stdin-reading re-run is still re-run and reported (GH-15)"
else
  fail "GH-15: the retry lost a pooled failure whose predecessor's re-run read stdin — the results file is not a suite's stdin"
fi

# (6) the run's VERDICT follows the real failure: a suite that fails alone must fail the run
if [ "$rc2" -ne 0 ]; then
  pass "a surviving failure still fails the run (the retry cannot launder a real failure)"
else
  fail "GH-15: the probe run exited 0 with an always-failing suite — a green verdict on a failed suite"
fi

# (7) the stdin-reading suite itself is still judged by its ALONE verdict: counted as PASSED and
#     NAMED in the GH-528 contention warning — contention must never read as a failed run.
if printf '%s' "$out2" | grep -qE "^  \+ $SWALLOWER_NAME" \
   && printf '%s' "$out2" | grep -q "WARNING (GH-528)" \
   && printf '%s' "$out2" | grep -q "    $SWALLOWER_NAME"; then
  pass "the stdin-reading suite is counted by its alone verdict and named in the contention warning"
else
  fail "GH-15: a suite that passes alone was not counted as passed and named — contention must never read as failure"
fi

# (8) the evidence is complete: no INTERNAL ERROR, and both probes reached the summary — nothing lost
if printf '%s' "$out2" | grep -q "INTERNAL ERROR"; then
  fail "GH-15: the run reported incomplete evidence — the tally guard fired on a case it should handle"
elif printf '%s' "$out2" | grep -qE "^  \+ $SWALLOWER_NAME" && printf '%s' "$out2" | grep -qE "^  - $VICTIM_NAME"; then
  pass "every pooled suite is classified exactly once — the verdict rests on complete evidence"
else
  fail "GH-15: a probe suite never reached the summary — a result line was lost"
fi

# ── GH-15 Part 3: a suite whose worker dies WITHOUT writing a result line ─────────────────────────
# KILLER kills its worker shell on first execution, so vp_run_one never appends a result line.
# Pre-fix that suite was uncounted everywhere — neither re-run nor reported, a silent short tally.
# The completeness catch-up must give it the same treatment as a nonzero rc: re-run alone, classify.
KILLER_NAME="_gh15-killer-$$.sh"
cat > "$ROOT/test/$KILLER_NAME" <<EOF
#!/usr/bin/env bash
if [ ! -e "$GH528_PROBE_FLAG.kl" ]; then : > "$GH528_PROBE_FLAG.kl"; kill -9 \$PPID; fi
exit 0
EOF
rm -f "$GH528_PROBE_FLAG.kl"
VP3="$ROOT/.gh15-validate-probe3-$$.sh"
make_probe_validate "$VP3" "$KILLER_NAME"
trap '_rc=$?; rm -f "$VP" "$VP2" "$VP3" "$ROOT/test/$PROBE_NAME" "$ROOT/test/$SWALLOWER_NAME" "$ROOT/test/$VICTIM_NAME" "$ROOT/test/$KILLER_NAME"; rm -rf "$WORK"; if [ "${TEST_SOFT_FAIL:-0}" = "1" ] && [ "${FAIL:-0}" -gt 0 ]; then exit 1; fi; exit "$_rc"' EXIT
out3="$(bash "$VP3" --parallel 2 2>&1)"

# (9) the missing line is caught up: named loudly, re-run alone, and classified by the alone verdict
if printf '%s' "$out3" | grep -q "NO RESULT recorded in parallel: $KILLER_NAME" \
   && printf '%s' "$out3" | grep -qE "^  \+ $KILLER_NAME" \
   && ! printf '%s' "$out3" | grep -q "INTERNAL ERROR"; then
  pass "a suite with no result line is re-run alone and classified — never silently uncounted"
else
  fail "GH-15: a suite whose worker died without a result line was lost — the catch-up did not classify it"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
