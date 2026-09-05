#!/usr/bin/env bash
# GH-299 Gen 4 Phase 1: semantic domain invariant oracles — 4 positive + 4 negative controls.
#
# Every oracle is exercised twice through the real CLI: once on a command that honours the
# invariant (must PASS) and once on a command that violates it (must FAIL). A control that
# cannot fail is vacuous, so the negative half is the half that proves the oracle works.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh299-p1-oracles.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

ORACLES="$ROOT/utils/py/domain_oracles.py"
SCHEMA="$ROOT/utils/py/telemetry_schema.py"

echo "== test: gh-gen4-phase1-domain-oracles =="

# 0. Contract + module presence
[ -x "$ORACLES" ] && pass "utils/py/domain_oracles.py exists and is executable" || fail "domain_oracles.py missing/not executable"
[ -x "$SCHEMA" ]  && pass "utils/py/telemetry_schema.py exists and is executable" || fail "telemetry_schema.py missing/not executable"
if python3 "$SCHEMA" --mode suite 2>&1 | grep -q 'SUITE_RESULT=PASS'; then
  pass "telemetry_schema.py --mode suite passes"
else
  fail "telemetry_schema.py --mode suite failed"
fi
if python3 "$ORACLES" --mode suite 2>&1 | grep -q 'SUITE_RESULT=PASS'; then
  pass "domain_oracles.py --mode suite passes (embedded +/- controls)"
else
  fail "domain_oracles.py --mode suite failed"
fi

# Fixtures: a disposable "host" repo and a disjoint "work" clone — never the real repo.
HOST="$WORK/host"; SANDBOX="$WORK/work"
git init -q -b main "$HOST"
git -C "$HOST" config user.email t@t; git -C "$HOST" config user.name t
echo hello > "$HOST/a.txt"; git -C "$HOST" add .; git -C "$HOST" commit -q -m init
git clone -q "$HOST" "$SANDBOX"
require_fixture "$HOST" "host fixture"
require_fixture "$SANDBOX" "work fixture"
TELEM="$WORK/oracles.jsonl"

# 1. zero-state (+/-)
if python3 "$ORACLES" --mode zero-state --cmd "cat a.txt" --cwd "$SANDBOX" --telemetry-out "$TELEM" >/dev/null; then
  pass "zero-state (+): read-only command leaves the tree digest untouched"
else
  fail "zero-state (+): read-only command was flagged"
fi
if python3 "$ORACLES" --mode zero-state --cmd "sh -c 'echo dirty >> a.txt'" --cwd "$SANDBOX" --telemetry-out "$TELEM" >/dev/null 2>&1; then
  fail "zero-state (-): a writer was NOT detected"
else
  pass "zero-state (-): writer detected (tree digest changed)"
fi
git -C "$SANDBOX" checkout -q -- a.txt

# 2. host containment (+/-)
if python3 "$ORACLES" --mode containment --cmd "sh -c 'echo w > local.tmp'" --cwd "$SANDBOX" --host-root "$HOST" --telemetry-out "$TELEM" >/dev/null; then
  pass "containment (+): write inside the work root leaves the host untouched"
else
  fail "containment (+): sandbox-local write was flagged"
fi
if python3 "$ORACLES" --mode containment --cmd "sh -c 'git -C $HOST remote add rogue /dev/null'" --cwd "$SANDBOX" --host-root "$HOST" --telemetry-out "$TELEM" >/dev/null 2>&1; then
  fail "containment (-): host remote table change was NOT detected"
else
  pass "containment (-): host remote table change detected"
fi
git -C "$HOST" remote remove rogue 2>/dev/null || true
# refuse a vacuous configuration: work root inside host root
if python3 "$ORACLES" --mode containment --cmd "true" --cwd "$HOST" --host-root "$HOST" >/dev/null 2>&1; then
  fail "containment: accepted work root == host root (vacuous proof)"
else
  pass "containment: refuses a work root that is not disjoint from the host"
fi

# 3. idempotence (+/-)
RECEIPTS="$SANDBOX/receipts.jsonl"
if python3 "$ORACLES" --mode idempotence --cmd "sh -c 'grep -q done $RECEIPTS 2>/dev/null || echo {\"r\":\"done\"} >> $RECEIPTS'" --cwd "$SANDBOX" --receipts "$RECEIPTS" --telemetry-out "$TELEM" >/dev/null; then
  pass "idempotence (+): de-duplicating receipt writer is monotonic"
else
  fail "idempotence (+): de-duplicating writer was flagged"
fi
rm -f "$RECEIPTS"
if python3 "$ORACLES" --mode idempotence --cmd "sh -c 'echo {\"r\":\"again\"} >> $RECEIPTS'" --cwd "$SANDBOX" --receipts "$RECEIPTS" --telemetry-out "$TELEM" >/dev/null 2>&1; then
  fail "idempotence (-): duplicate receipts were NOT detected"
else
  pass "idempotence (-): duplicate receipts detected"
fi
rm -f "$RECEIPTS"

# 4. crash & stale-lock recovery (+/-)
LOCK="$SANDBOX/state.lock"; LOG="$SANDBOX/events.jsonl"; READY="$SANDBOX/ready"
cat > "$WORK/holder.py" <<EOF
import os, json, time
os.mkdir("$LOCK"); open("$LOCK/pid", "w").write(str(os.getpid()))
for i in range(3): open("$LOG", "a").write(json.dumps({"i": i}) + "\n")
open("$READY", "w").write("1")
time.sleep(30)
EOF
cat > "$WORK/recover_good.py" <<EOF
import os, sys, shutil
pid = int(open("$LOCK/pid").read())
try:
    os.kill(pid, 0); sys.exit(3)          # holder still alive: refuse
except OSError:
    shutil.rmtree("$LOCK")                # stale: reclaim
EOF
cat > "$WORK/recover_naive.py" <<EOF
import os, sys
sys.exit(0 if not os.path.isdir("$LOCK") else 5)   # never breaks a stale lock
EOF
if python3 "$ORACLES" --mode crash-recovery --hold-cmd "python3 $WORK/holder.py" --recover-cmd "python3 $WORK/recover_good.py" --ready-file "$READY" --cwd "$SANDBOX" --jsonl "$LOG" --telemetry-out "$TELEM" >/dev/null; then
  pass "crash-recovery (+): stale lock reclaimed after SIGKILL, JSONL line-valid"
else
  fail "crash-recovery (+): recovery after SIGKILL was flagged"
fi
rm -rf "$LOCK" "$LOG" "$READY"
if python3 "$ORACLES" --mode crash-recovery --hold-cmd "python3 $WORK/holder.py" --recover-cmd "python3 $WORK/recover_naive.py" --ready-file "$READY" --cwd "$SANDBOX" --jsonl "$LOG" --telemetry-out "$TELEM" >/dev/null 2>&1; then
  fail "crash-recovery (-): naive acquirer blocked by stale lock was NOT detected"
else
  pass "crash-recovery (-): naive acquirer blocked by stale lock detected"
fi
rm -rf "$LOCK" "$LOG" "$READY"

# 5. Telemetry contract: every oracle emitted one line-valid TelemetryEvent (phase=oracle)
if python3 "$SCHEMA" --mode validate --path "$TELEM" >/dev/null; then
  pass "telemetry JSONL is line-level valid"
else
  fail "telemetry JSONL has torn/invalid lines"
fi
n="$(grep -c '"phase":"oracle"' "$TELEM" || true)"
if [ "$n" -eq 8 ]; then
  pass "8 oracle telemetry rows emitted (4 oracles × +/-)"
else
  fail "expected 8 oracle telemetry rows, got $n"
fi
if grep -q '"tier_1_verdict":"fail"' "$TELEM" && grep -q '"tier_1_verdict":"pass"' "$TELEM"; then
  pass "telemetry carries both pass and fail tier-1 verdicts"
else
  fail "telemetry verdicts missing"
fi

# 6. Real-repo zero-state check on a read-only harness command (the target Gen 4 protects)
if python3 "$ORACLES" --mode zero-state --cmd "bash validate.sh --print-mode" --cwd "$ROOT" --timeout 120 >/dev/null 2>&1; then
  pass "zero-state: validate.sh --print-mode is read-only against this clone"
else
  fail "zero-state: validate.sh --print-mode mutated the clone or leaked a handle"
fi

echo "== gh-gen4-phase1-domain-oracles: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
