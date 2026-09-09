#!/usr/bin/env bash
# runaway-guard.sh — ATE watchdog: per-invocation timeout + trap-safe group reaper (GH-478).
#
# On 2026-09-03 a gen4 adaptive-ate engine call hung for 2d21h at ~90–98% CPU because
# nothing capped it, reaped it, or reported it. This library is the suite-layer guard:
# every ATE engine invocation gets a wall-clock cap, and no tracked child's process
# group outlives the suite. Sourceable, like fixture-guard.sh:
#
#   . "$ROOT/test/lib/fixture-guard.sh"
#   . "$ROOT/test/lib/runaway-guard.sh"
#
# Process model: ALL group launching/killing is delegated to utils/py/proc_group.py —
# the ONE shared runner (GH-478 plan QA round 2), which also owns the two ATE python
# callers (run_variations.run_harness, fuzz_engine.execute). start_new_session makes
# the child a session leader with PGID == PID (the only portable way: macOS ships no
# setsid, and a non-interactive bash puts background jobs in the caller's group). The
# guard tracks PGIDs — NOT leader pids — because a session group stays a valid kill
# target after its leader exits (a leader that spawns a TERM-resistant grandchild and
# exits normally is exactly the survivor this guard exists to catch, and the EXIT
# reaper reaps it).
#
# Contract:
#   run_with_timeout <seconds> <cmd...>
#       Run <cmd> capped at <seconds> via proc_group.py. On expiry the group gets
#       TERM, a grace window, then KILL; the cap and the override variable are named
#       on stderr and 124 is returned. Otherwise the child's own exit code. The
#       group is tracked either way.
#   runaway_guard_track <pgid>
#       Register an already-running process group with the reaper.
#   runaway_guard_reap
#       Kill every tracked group with living members (TERM → KILL), announce each on
#       stderr, set RUNAWAY_GUARD_REAPED=1. Errexit-safe BY CONSTRUCTION — every
#       command guarded, always returns 0, never exits — so a `set -euo pipefail`
#       suite can call it without its trap aborting or its status changing.
#   runaway_guard_init [<owner-cleanup...>]
#       Install ONE composed EXIT trap: capture incoming $?, reap with errexit
#       contained, run the suite's own cleanup command if given, exit the suite's
#       original status — or exit 1 when the suite was green but the reaper had to
#       kill (a reaped child is a suite failure, never a silent cleanup). Refuses
#       (exit 1) when an EXIT trap already exists and was not composed here.
#
# Cap override: ATE_WATCHDOG_TIMEOUT (default 300). Unit-scale ATE engine calls take
# seconds; the GH-478 incident ran for days.

RUNAWAY_GUARD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNAWAY_GUARD_CHILDREN=()   # PGIDs (not pids): valid kill targets even leader-less
RUNAWAY_GUARD_REAPED=0
RUNAWAY_GUARD_OWNER=()
RUNAWAY_GUARD_GRACE_S="${RUNAWAY_GUARD_GRACE_S:-1}"

runaway_guard_track() {  # <pgid>
  [ -n "${1:-}" ] && RUNAWAY_GUARD_CHILDREN+=("$1")
  return 0
}

runaway_guard_reap() {  # kill tracked groups with living members; loud; never fails, never exits
  local pgid
  for pgid in ${RUNAWAY_GUARD_CHILDREN[@]+"${RUNAWAY_GUARD_CHILDREN[@]}"}; do
    [ -n "$pgid" ] || continue
    # Detection stays here (a cheap group probe); the KILLING is proc_group's
    # --kill-pgid seam — group killing exists exactly once (GH-478 round 3).
    if kill -0 -- "-$pgid" 2>/dev/null; then
      echo "runaway-guard: reaping surviving child group $pgid" >&2
      if ! python3 "$RUNAWAY_GUARD_ROOT/utils/py/proc_group.py" --kill-pgid "$pgid" \
             --grace "$RUNAWAY_GUARD_GRACE_S"; then
        echo "runaway-guard: group $pgid SURVIVED the kill seam — manual cleanup required" >&2
      fi
      RUNAWAY_GUARD_REAPED=1
    fi
  done
  RUNAWAY_GUARD_CHILDREN=()
  return 0
}

run_with_timeout() {  # <seconds> <cmd...> → child's rc, or 124 on a witnessed timeout
  local cap_s="$1"
  shift
  [ -n "$cap_s" ] && [ "$cap_s" -gt 0 ] 2>/dev/null || {
    echo "runaway-guard: run_with_timeout needs a positive <seconds>, got '$cap_s'" >&2
    return 2
  }
  # Fail closed on the tracking boundary (GH-478 rounds 3–4): the child is only
  # released once the pgid publication is proven AND acknowledged; otherwise
  # proc_group kills the group itself and this call refuses.
  local pgid_file
  pgid_file="$(mktemp "${TMPDIR:-/tmp}/runaway-guard-pgid.XXXXXX")" || {
    echo "runaway-guard: cannot create the pgid publication file — refusing to run untracked" >&2
    return 2
  }
  local ack_file="$pgid_file.ack"
  python3 "$RUNAWAY_GUARD_ROOT/utils/py/proc_group.py" \
    --timeout "$cap_s" --grace "$RUNAWAY_GUARD_GRACE_S" \
    --pgid-file "$pgid_file" --ack-file "$ack_file" -- "$@" &
  local wrapper=$!
  local i=0 pgid=""
  while [ "$i" -lt 50 ] && [ ! -s "$pgid_file" ]; do
    sleep 0.1
    i=$((i + 1))
  done
  pgid="$(cat "$pgid_file" 2>/dev/null)"
  case "$pgid" in
    ''|*[!0-9]*)
      # No proven pgid → never acknowledge: proc_group kills the child group itself.
      echo "runaway-guard: pgid publication failed for '$*' — refusing (proc_group will reap its own child)" >&2
      wait "$wrapper" 2>/dev/null
      rm -f "$pgid_file" "$ack_file"
      return 2
      ;;
  esac
  # Acknowledge and LEAVE the ack file for proc_group to consume — deleting it here
  # would race its 0.1s poll (create/delete faster than the poll interval).
  : > "$ack_file"
  rm -f "$pgid_file"
  runaway_guard_track "$pgid"
  wait "$wrapper"
  local rc=$?
  # Forget groups that are already gone so a later PGID reuse can never alias them.
  if ! kill -0 -- "-$pgid" 2>/dev/null; then
    _runaway_guard_forget "$pgid"
  fi
  if [ "$rc" -eq 124 ]; then
    echo "runaway-guard: cap of ${cap_s}s fired (override: ATE_WATCHDOG_TIMEOUT): $*" >&2
  fi
  return "$rc"
}

_runaway_guard_forget() {  # <pgid> — drop a proven-dead group from the tracking list
  local pgid="$1" kept=() cur
  for cur in ${RUNAWAY_GUARD_CHILDREN[@]+"${RUNAWAY_GUARD_CHILDREN[@]}"}; do
    [ "$cur" = "$pgid" ] || kept+=("$cur")
  done
  RUNAWAY_GUARD_CHILDREN=("${kept[@]:-}")
  return 0
}

_runaway_guard_exit_trap() {  # composed EXIT trap: reap + owner cleanup, status-preserving
  local rc=$?
  set +e
  runaway_guard_reap
  local reaped=$RUNAWAY_GUARD_REAPED
  [ "${#RUNAWAY_GUARD_OWNER[@]}" -gt 0 ] && "${RUNAWAY_GUARD_OWNER[@]}"
  if [ "$rc" -ne 0 ]; then
    exit "$rc"  # the suite's own failure stands, never masked by the reaper
  fi
  [ "$reaped" -eq 1 ] && exit 1
  exit 0
}

runaway_guard_init() {  # [<owner-cleanup...>] — install the composed EXIT trap
  if [ -n "$(trap -p EXIT)" ]; then
    echo "runaway-guard: REFUSING — the sourcing suite already owns the EXIT trap; pass the cleanup command to runaway_guard_init instead (GH-478)" >&2
    return 1
  fi
  RUNAWAY_GUARD_OWNER=("$@")
  trap _runaway_guard_exit_trap EXIT
}
