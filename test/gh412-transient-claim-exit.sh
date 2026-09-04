#!/usr/bin/env bash
# GH-412: transient O_EXCL claim collision exits 75 (EX_TEMPFAIL), while durable losses exit 1.
source "$(dirname "$0")/_setup.sh" gh412-transient-claim-exit

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export TICK="$ROOT/bin/tick"

# Setup test repo
TDIR="$WORK/repo"
mkdir -p "$TDIR/.tick/events" "$TDIR/.tick/locks"
git -C "$TDIR" init -q

# Helper to create a task in the event log
make_task() {
  local task="$1"
  python3 -c "
import json, time
event = {'type': 'task.created', 'task': '$task', 'timestamp': int(time.time()*1000)}
with open('$TDIR/.tick/events/created-$task.jsonl', 'w') as f:
    f.write(json.dumps(event) + '\n')
"
}

# 1. Transient collision: when claim.lock already exists, tick claim exits 75
make_task "T1"
LOCKFILE="$TDIR/.tick/locks/claim.lock"
echo "12345" > "$LOCKFILE"

rc=0
out="$(TICK_REPO_ROOT="$TDIR" "$TICK" claim T1 --agent codex --paths "src/*" 2>&1)" || rc=$?
[ "$rc" -eq 75 ] && pass "held claim.lock causes tick claim to exit 75 (EX_TEMPFAIL)" \
                 || fail "held claim.lock expected exit 75, got $rc: $out"
case "$out" in
  *"another tick claim is in progress"*)
    pass "transient error message explains another claim is in progress"
    ;;
  *)
    fail "unexpected transient error message: $out"
    ;;
esac

# Clean up manual lock
rm -f "$LOCKFILE"

# 2. Idempotent claim by holder exits 0
rc=0
out="$(TICK_REPO_ROOT="$TDIR" "$TICK" claim T1 --agent codex --paths "src/*" 2>&1)" || rc=$?
[ "$rc" -eq 0 ] && pass "first claim succeeds with exit 0" \
                || fail "first claim expected exit 0, got $rc: $out"

rc=0
out="$(TICK_REPO_ROOT="$TDIR" "$TICK" claim T1 --agent codex --paths "src/*" 2>&1)" || rc=$?
[ "$rc" -eq 0 ] && pass "idempotent re-claim by same holder exits 0" \
                || fail "idempotent re-claim expected exit 0, got $rc: $out"

# 3. Durable loss: already claimed by another agent exits 1 (GH-408 contract preserved)
rc=0
out="$(TICK_REPO_ROOT="$TDIR" "$TICK" claim T1 --agent agy --paths "src/*" 2>&1)" || rc=$?
[ "$rc" -eq 1 ] && pass "durable loss (claimed by another) exits 1" \
                || fail "durable loss expected exit 1, got $rc: $out"

# 4. Durable loss: spent/terminal task exits 1
make_task "T2"
python3 -c "
import json, time
event = {'type': 'task.done', 'task': 'T2', 'agent': 'codex', 'timestamp': int(time.time()*1000)}
with open('$TDIR/.tick/events/done-T2.jsonl', 'w') as f:
    f.write(json.dumps(event) + '\n')
"
rc=0
out="$(TICK_REPO_ROOT="$TDIR" "$TICK" claim T2 --agent codex --paths "src/*" 2>&1)" || rc=$?
[ "$rc" -eq 1 ] && pass "durable loss (spent task) exits 1" \
                || fail "durable loss (spent task) expected exit 1, got $rc: $out"

# 5. Durable loss: cap reached exits 1
make_task "T3"
make_task "T4"
TICK_REPO_ROOT="$TDIR" "$TICK" claim T3 --agent agy --paths "a/*" >/dev/null 2>&1 || true
TICK_REPO_ROOT="$TDIR" "$TICK" claim T4 --agent agy --paths "b/*" >/dev/null 2>&1 || true
make_task "T5"
rc=0
out="$(TICK_REPO_ROOT="$TDIR" "$TICK" claim T5 --agent agy --paths "c/*" 2>&1)" || rc=$?
[ "$rc" -eq 1 ] && pass "durable loss (cap reached) exits 1" \
                || fail "durable loss (cap reached) expected exit 1, got $rc: $out"

# 6. Verify rtl.py claim retry behavior on exit 75 vs exit 1
python3 - "$ROOT" "$TDIR" <<'PY'
import sys, os, subprocess, time
root, tdir = sys.argv[1], sys.argv[2]
sys.path.insert(0, os.path.join(root, "utils", "py"))
import rtl

# Ensure claim_task_or_exit can resolve
lockfile = os.path.join(tdir, ".tick", "locks", "claim.lock")

# Test 1: transient lock released in background should succeed via retry
open(lockfile, "w").write("99999\n")
def release_lock():
    time.sleep(0.1)
    try:
        os.unlink(lockfile)
    except OSError:
        pass

import threading
t = threading.Thread(target=release_lock)
t.start()

start = time.time()
# Claim T6 which is available once lock is unlinked
event = {'type': 'task.created', 'task': 'T6', 'timestamp': int(time.time()*1000)}
import json
with open(os.path.join(tdir, '.tick', 'events', 'created-T6.jsonl'), 'w') as f:
    f.write(json.dumps(event) + '\n')

rtl.claim_task_or_exit(tdir, root, "RELAY.md", "src/*", "T6", "codex", "test-tool")
elapsed = time.time() - start
t.join()
assert elapsed >= 0.04, f"expected retry delay, got {elapsed}"
print("  PASS: rtl.py retried exit 75 and successfully claimed task")
PY

if [ "$?" -eq 0 ]; then
  pass "rtl.py retries exit 75"
else
  fail "rtl.py failed to retry exit 75"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
