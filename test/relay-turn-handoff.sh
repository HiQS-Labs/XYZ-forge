#!/usr/bin/env bash
set -euo pipefail
#
# relay-turn-handoff.sh — GH-67 regression: rtl_enforce must AUTHORITATIVELY hand off / close the
# tick turn-token after its file-scoped commit, so a headless worker that forgets to release/done
# (observed on both codex stalls and agy Approved turns) can no longer DEADLOCK the relay.
#
# Proves both branches of GH-67 Option A:
#   relay STATUS non-terminal  -> `tick release <task> --to <RELAY_PEER>`  (token open, handed to peer)
#   relay STATUS Approved/Closed -> `tick done <task>`                     (token done)
#
# Self-locating: resolves the harness from this file, mirrors production by co-locating bin/tick with
# .tick under TICK_REPO_ROOT (the harness clone), and never touches the real repo's event log.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS="$(cd "$HERE/.." && pwd)"
LIB="$HARNESS/relay-turn-lib.sh"
[[ -f "$LIB" ]] || LIB="$HARNESS/relay-automation/relay-turn-lib.sh"

pass=0; fail=0
ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

run_case() { # <name> <relay-status> <expect: release|done>
  local name="$1" status="$2" expect="$3"
  local dir; dir="$(mktemp -d "${TMPDIR:-/tmp}/relay-handoff.XXXXXX")"
  git -C "$dir" init -q
  git -C "$dir" config user.email t@example.com; git -C "$dir" config user.name test
  # Production shape: bin/tick + src co-located with .tick under TICK_REPO_ROOT.
  ln -s "$HARNESS/bin" "$dir/bin"; ln -s "$HARNESS/src" "$dir/src"
  export TICK_REPO_ROOT="$dir"
  local T="$dir/bin/tick"
  "$T" init >/dev/null 2>&1 || true

  local relay="relay-system/x/thread.md"
  mkdir -p "$dir/relay-system/x"
  printf '# thread\n\n**STATUS:** %s\n**NEXT:** agent-b\n\nbody\n' "$status" > "$dir/$relay"
  git -C "$dir" add -A >/dev/null 2>&1; git -C "$dir" commit -qm seed

  # Seed + claim the token as agent-a; agent-a edits on-lane but does NOT release (the GH-67 bug).
  "$T" log task.created RELAY-T --agent bootstrap >/dev/null
  "$T" claim RELAY-T --agent agent-a --paths "$relay" >/dev/null
  printf 'edit by agent-a\n' >> "$dir/$relay"

  ( cd "$dir"
    export RELAY_FILE="$relay" RELAY_PEER="agent-b"
    # shellcheck disable=SC1090
    source "$LIB"
    rtl_init "$dir" "$relay" ""
    rtl_before
    rtl_enforce RELAY-T agent-a /dev/null testtool
  ) >/dev/null 2>&1

  local info st ho
  info="$("$T" info RELAY-T 2>/dev/null || true)"
  st="$(printf '%s\n' "$info" | sed -n 's/^status:[[:space:]]*//p'     | head -n1)"
  ho="$(printf '%s\n' "$info" | sed -n 's/^handoff-to:[[:space:]]*//p' | head -n1)"
  if [[ "$expect" == "done" ]]; then
    ok "$name: relay STATUS=$status -> token done" "[[ '$st' == 'done' ]]"
  else
    ok "$name: relay STATUS=$status -> token open, handed to peer" "[[ '$st' == 'open' && '$ho' == 'agent-b' ]]"
  fi
  rm -rf "$dir"
}

echo "relay-turn-handoff (GH-67):"
run_case "non-terminal" "Open"     "release"
run_case "approved"     "Approved" "done"
echo "  relay-turn-handoff: $pass pass, $fail fail"
[[ "$fail" -eq 0 ]]
