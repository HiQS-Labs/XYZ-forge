#!/usr/bin/env bash
# Synthetic Test: GH-94 Worktree Containment & Sandbox Invariants
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
RUNNER="$ROOT/utils/py/script_runner.py"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh94-containment-test.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# Create a fixture repo inside $WORK
FIXTURE="$WORK/fixture-repo"
mkdir -p "$FIXTURE"
(
  cd "$FIXTURE" && git init -q && git config user.name "Test" && git config user.email "test@example.com"
  echo "init" > file.txt && git add file.txt && git commit -q -m "initial commit"
)

# 1. Path Boundary Resolution: Test validate_path_containment via Python
python3 -c "
import sys
from pathlib import Path
sys.path.insert(0, '$ROOT')
from utils.py.script_runner import validate_path_containment

work_dir = Path('$WORK')
# Valid paths
assert validate_path_containment('sub/file.txt', work_dir)[0] == True
assert validate_path_containment(work_dir / 'file.txt', work_dir)[0] == True

# Invalid paths (escapes)
assert validate_path_containment('../escape.txt', work_dir)[0] == False
assert validate_path_containment('/etc/passwd', work_dir)[0] == False

# Symlink escape test
symlink_escape = work_dir / 'sym_escape'
try:
    symlink_escape.symlink_to('/tmp')
    assert validate_path_containment(symlink_escape / 'test.txt', work_dir)[0] == False
except OSError:
    pass # In case symlink creation is restricted
" || {
  echo "FAIL: Path containment validation assertions failed"
  exit 1
}

# 2. Host Clone Invariance: Snapshot git sentinels of host repo
HOST_BARE="$(git -C "$ROOT" config --get core.bare || true)"
HOST_ORIGIN="$(git -C "$ROOT" config --get remote.origin.url || true)"
HOST_HEAD="$(git -C "$ROOT" rev-parse HEAD || true)"

# Execute hostile script in isolated fixture
python3 "$RUNNER" --workdir "$FIXTURE" --lang bash --code '
# Hostile attempts: try to mess with git configs
git config core.bare true 2>/dev/null || true
git remote set-url origin "/tmp/fake.git" 2>/dev/null || true
' >/dev/null 2>&1

# Assert host repo sentinels did NOT drift
CURRENT_BARE="$(git -C "$ROOT" config --get core.bare || true)"
CURRENT_ORIGIN="$(git -C "$ROOT" config --get remote.origin.url || true)"
CURRENT_HEAD="$(git -C "$ROOT" rev-parse HEAD || true)"

if [ "$HOST_BARE" != "$CURRENT_BARE" ]; then
  echo "FAIL: Host core.bare drifted: $HOST_BARE -> $CURRENT_BARE"
  exit 1
fi

if [ "$HOST_ORIGIN" != "$CURRENT_ORIGIN" ]; then
  echo "FAIL: Host remote.origin.url drifted: $HOST_ORIGIN -> $CURRENT_ORIGIN"
  exit 1
fi

if [ "$HOST_HEAD" != "$CURRENT_HEAD" ]; then
  echo "FAIL: Host HEAD drifted: $HOST_HEAD -> $CURRENT_HEAD"
  exit 1
fi

# 3. Containment Root Rejection Gate
out=$(python3 "$RUNNER" --workdir "$WORK/.." --containment-root "$WORK" --code "print('ESCAPE')" --json 2>&1 || true)
grep -q '"status": "error"' <<<"$(echo "$out")" || {
  echo "FAIL: Expected runner to reject workdir outside containment root. Got: $out"
  exit 1
}

# 4. Untracked Sentinel Protection
SENTINEL="$WORK/untracked-sentinel.txt"
echo "SECRET_PAYLOAD" > "$SENTINEL"

# Run a python script that tries to overwrite surrounding files outside containment
out=$(python3 "$RUNNER" --workdir "$FIXTURE" --containment-root "$FIXTURE" --file "$SENTINEL" --json 2>&1 || true)
grep -q '"status": "error"' <<<"$(echo "$out")" || {
  echo "FAIL: Expected runner to reject execution of script outside containment-root. Got: $out"
  exit 1
}

# Verify sentinel content remained intact
grep -q "SECRET_PAYLOAD" "$SENTINEL" || {
  echo "FAIL: Sentinel file was corrupted: $(cat "$SENTINEL")"
  exit 1
}

# 5. Runtime Code Execution Filesystem Containment
OUTSIDE_CANARY="$WORK/outside-canary.txt"
echo "SAFE_CANARY" > "$OUTSIDE_CANARY"

# Execute a hostile in-script write trying to escape $FIXTURE to write into $OUTSIDE_CANARY
out=$(python3 "$RUNNER" --workdir "$FIXTURE" --containment-root "$FIXTURE" \
  --code "open('$OUTSIDE_CANARY', 'w').write('PWNED')" --json 2>&1 || true)

# Assert that outside canary file was NOT mutated
grep -q "SAFE_CANARY" "$OUTSIDE_CANARY" || {
  echo "FAIL: Runtime script escaped containment and mutated outside file: $(cat "$OUTSIDE_CANARY")"
  exit 1
}

# 6. Fail-Closed Verification when Sandbox Backend is Missing
out=$(python3 -c "
import sys
sys.path.insert(0, '$ROOT')
from utils.py.script_runner import run_script_safely

# Simulate missing sandbox engine by mocking shutil.which
import shutil
shutil.which = lambda cmd: None

res = run_script_safely(
    code_or_file=\"print('UNCONTAINED')\",
    containment_root=\"$WORK\",
    work_dir=\"$WORK\",
)
assert res['status'] == 'error', f'Expected status error, got {res}'
assert res['exit_code'] == 2, f'Expected exit code 2, got {res}'
assert 'OS sandbox backend unavailable' in res['stderr'], f'Expected fail-closed error message, got {res}'
print('FAIL_CLOSED_VERIFIED')
" 2>&1 || true)

grep -q "FAIL_CLOSED_VERIFIED" <<<"$(echo "$out")" || {
  echo "FAIL: Expected runner to fail closed when sandbox backend is missing. Got: $out"
  exit 1
}

echo "PASS: gh94-containment-invariants"
exit 0
