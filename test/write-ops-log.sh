#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"

log_tmp="$(mktemp)"
export XYZ_WRITE_OPS_LOG="$log_tmp"
export HOME="$(mktemp -d)"
export XDG_CONFIG_HOME=""
export XYZ_REGISTRY="$HOME/.config/xyz/registry.tsv"

teardown() {
  rm -f "$log_tmp"
  rm -rf "$HOME"
}
trap teardown EXIT

run_hook() {
  local cmd="$1"
  local tool_name="${2:-Bash}"
  python3 -c "import sys, json; json.dump({'tool_name': '$tool_name', 'tool_input': {'command': '$cmd'}, 'cwd': '/tmp'}, sys.stdout)" | bash "$HERE/relay-automation/hooks/write-ops-log.sh"
}

assert_log() {
  local pattern="$1"
  grep -q "\"pattern\": \"$pattern\"" "$log_tmp" || { echo "Missing $pattern"; cat "$log_tmp"; exit 1; }
  > "$log_tmp"
}

assert_no_log() {
  if [ -s "$log_tmp" ]; then
    echo "Unexpected log:"
    cat "$log_tmp"
    exit 1
  fi
}

run_hook "rm -rf foo"
assert_log "rm force"

run_hook "rm -f file"
assert_log "rm force"

run_hook "git worktree remove --force foo"
assert_log "git worktree remove"

run_hook "git branch -D my-branch"
assert_log "git branch delete"

run_hook "git checkout -- file.txt"
assert_log "git checkout"

run_hook "ls -la"
assert_no_log

echo "not json" | bash "$HERE/relay-automation/hooks/write-ops-log.sh"
assert_no_log
echo '{"tool_name":"Bash","tool_input":"not-a-dict"}' | bash "$HERE/relay-automation/hooks/write-ops-log.sh"
assert_no_log

run_hook "rm -rf \"complex \\\" name\" \n && ls"
assert_log "rm force"

long_cmd="$(python3 -c 'print("rm -rf foo" + " " * 5000)')"
run_hook "$long_cmd"
grep -q "TRUNCATED" "$log_tmp" || { echo "Missing truncation"; cat "$log_tmp"; exit 1; }
> "$log_tmp"

perms="$(stat -f "%Mp%Lp" "$log_tmp" 2>/dev/null || stat -c "%a" "$log_tmp")"
case "$perms" in
  *600) ;;
  *) echo "Wrong perms $perms"; exit 1 ;;
esac

# xyz-sync
mkdir -p "$HOME/.config/xyz"
fake_install="$HOME/fake_install"
mkdir -p "$fake_install/.xyz"
echo -e "$fake_install/.xyz\t2026-01-01T00:00:00Z\t1.0\tabcdef\t$HERE" > "$HOME/.config/xyz/registry.tsv"
bash "$HERE/relay-automation/xyz-sync.sh" delete "$fake_install/.xyz" >/dev/null
assert_no_log
bash "$HERE/relay-automation/xyz-sync.sh" delete "$fake_install/.xyz" --yes >/dev/null
assert_log "xyz-sync delete"

# rtl_worktree_end
wt="$(mktemp -d)"
mkdir -p "$wt/.git" # Fake worktree so the worktree remove fails and hits fallback
source "$HERE/relay-automation/relay-turn-lib.sh" >/dev/null 2>&1 || true
declare -a RTL_ALLOW=("dummy")
RTL_WT_USED=0
RTL_ROOT="$wt" rtl_worktree_end "$wt" || true
assert_log "rm force"

# concurrent
> "$log_tmp"
concurrent() {
  for i in {1..10}; do
    xyz_write_ops_log_append "test pattern" "cmd $i" &
  done
  wait
}
if type xyz_write_ops_log_append >/dev/null 2>&1; then
  concurrent
  lines="$(wc -l < "$log_tmp" | tr -d ' ')"
  if [ "$lines" -ne 10 ]; then
    echo "Concurrent append failed, got $lines lines"
    exit 1
  fi
fi

echo "test/write-ops-log.sh passed"
