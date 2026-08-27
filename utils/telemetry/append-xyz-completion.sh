#!/usr/bin/env bash
set -euo pipefail
#
# append-xyz-completion.sh — GH-75: append ONE final-completion telemetry record to XYZ.json at the
# harness repo root, newest-first (mirrors CHANGELOG.md's convention).
#
# Called from the three harnesses at their proven terminal points (relay-drive.sh, marathon-drive.sh,
# marathon.sh). Each call is a locked, atomic read-modify-write-prepend so two sessions finishing in
# the same second neither corrupt XYZ.json nor lose a record:
#   - advisory mkdir lock (GH-72 pattern) serializes the read-modify-write → no lost update.
#     A writer that cannot acquire the lock within XYZ_LOCK_WAIT_S exits 75; it never falls back to
#     an unlocked append, because that would turn lock starvation into a possible lost record.
#   - temp-file + os.replace() → the swap is atomic at the filesystem level; a writer killed mid-write
#     leaves the prior valid array intact (never a truncated/partial JSON file).
#
# Usage: append-xyz-completion.sh <harness> <sessionId> <health> <title> <description>
#   harness      relay | marathon | swarm
#   sessionId    relay thread slug, or marathon plan/run id
#   health       green | orange | red
#   title        short human-readable title
#   description  one-line summary
#
# XYZ.json ALWAYS lives at the harness repo root (the clone that ships relay-automation/), never a
# --target-root foreign repo — telemetry describes the harness's own session history. Overridable for
# tests: XYZ_JSON_PATH (full path) wins; else XYZ_ROOT/<root>/XYZ.json; else self-located repo root.

ROOT_DIR="${XYZ_ROOT:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"}"
XYZ_JSON="${XYZ_JSON_PATH:-"$ROOT_DIR/XYZ.json"}"

die() { printf 'append-xyz-completion: %s\n' "$*" >&2; exit 2; }

(($# == 5)) || die "usage: append-xyz-completion.sh <harness> <sessionId> <health> <title> <description>"
harness="$1"; session_id="$2"; health="$3"; title="$4"; description="$5"

case "$harness" in relay|marathon|swarm) ;; *) die "harness must be relay|marathon|swarm, got: $harness" ;; esac
case "$health"  in green|orange|red)     ;; *) die "health must be green|orange|red, got: $health" ;; esac

updated_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

mkdir -p "$(dirname "$XYZ_JSON")" 2>/dev/null || true

# ── advisory lock (GH-72 mkdir pattern) ─────────────────────────────────────
# Serialize the read-modify-write. Atomic replacement (below) prevents CORRUPTION; the lock prevents a
# LOST UPDATE (two writers both reading the same pre-append array, one clobbering the other's record).
lockdir="$XYZ_JSON.lock"
locked=0
release_lock() {
  [[ "$locked" -eq 1 ]] || return 0
  local owner; owner="$(cat "$lockdir/pid" 2>/dev/null || true)"
  # Only remove a lock we still own (pid names us, or is gone) — never a peer's after a reclaim.
  if [[ -z "$owner" || "$owner" == "$$" ]]; then rm -rf "$lockdir" 2>/dev/null || true; fi
  locked=0
}
trap release_lock EXIT INT TERM HUP

lock_wait_s="${XYZ_LOCK_WAIT_S:-30}"
# GH-123: XYZ_LOCK_WAIT_S bounds how long we wait for ONE holder to make way — not how long the
# whole queue may take to drain. A single wall-clock deadline conflates the two, and the two only
# look alike on an idle machine. With 16 concurrent appenders on a CPU-throttled shared runner
# each holder spawns python3 under the lock, the queue is long but MOVING, and every writer past
# the deadline exits 75 as though the lock were stuck — reporting starvation for a system that is
# working, just slowly. So the bound is re-armed each time the lock CHANGES HANDS (observable
# progress), and a separate absolute cap keeps a genuinely stuck lock failing loudly rather than
# waiting forever. Defaults are deliberately unchanged: test/xyz-completion.sh mirrors the 30s
# default and test/gh358-lock-instrumentation.sh asserts it verbatim.
lock_total_max_s="${XYZ_LOCK_TOTAL_MAX_S:-$(( lock_wait_s * 4 ))}"
lock_started=$(date +%s)
deadline=$(( lock_started + lock_wait_s ))
last_holder=""
empty_streak=0
while :; do
  if mkdir "$lockdir" 2>/dev/null; then
    printf '%s\n' "$$" > "$lockdir/pid" 2>/dev/null || true
    locked=1
    break
  fi
  now="$(date +%s)"
  if [[ "$now" -ge "$deadline" || $(( now - lock_started )) -ge "$lock_total_max_s" ]]; then
    # An unlocked append can preserve JSON syntax while losing another writer's record.  Keep this
    # distinct from a writer crash so the concurrent-write test can diagnose lock starvation.
    printf 'append-xyz-completion: lock never acquired after %ss (XYZ_LOCK_WAIT_S=%s per holder, total cap %ss): %s\n' \
      "$(( now - lock_started ))" "$lock_wait_s" "$lock_total_max_s" "$lockdir" >&2
    exit 75
  fi
  holder="$(cat "$lockdir/pid" 2>/dev/null || true)"
  if [[ -z "$holder" ]]; then
    # Empty pid = winner mkdir'd but hasn't written its pid yet (sub-ms) — NOT stale; wait. Only a pid
    # absent for ~2s straight is a genuinely orphaned mkdir (acquirer crashed) → reclaim (GH-72 TOCTOU).
    empty_streak=$((empty_streak + 1))
    if [[ "$empty_streak" -ge 20 ]]; then rm -rf "$lockdir" 2>/dev/null || true; empty_streak=0; fi
    sleep 0.1 2>/dev/null || sleep 1; continue
  fi
  empty_streak=0
  # The lock changed hands since the last look: the queue is draining, so re-arm the per-holder
  # bound. A stuck holder never trips this and still exits 75 at exactly XYZ_LOCK_WAIT_S.
  if [[ "$holder" != "$last_holder" ]]; then
    last_holder="$holder"
    deadline=$(( now + lock_wait_s ))
  fi
  if kill -0 "$holder" 2>/dev/null; then sleep 0.1 2>/dev/null || sleep 1; continue; fi
  rm -rf "$lockdir" 2>/dev/null || true   # dead holder — reclaim its stale lock
done

# ── locked, atomic read-modify-write-prepend ───────────────────────────────
python3 - "$XYZ_JSON" "$harness" "$session_id" "$health" "$title" "$description" "$updated_at" <<'PYEOF'
import sys, json, os, tempfile

xyz_path, harness, session_id, health, title, description, updated_at = sys.argv[1:8]

records = []
if os.path.exists(xyz_path):
    try:
        with open(xyz_path) as f:
            data = json.load(f)
        if isinstance(data, list):
            records = data
    except (ValueError, OSError):
        # Absent/corrupt/partial → start a fresh array rather than abort the session's telemetry.
        records = []

records.insert(0, {
    "harness": harness,
    "sessionId": session_id,
    "health": health,
    "title": title,
    "description": description,
    "updatedAt": updated_at,
})

d = os.path.dirname(xyz_path) or "."
fd, tmp = tempfile.mkstemp(dir=d, prefix=".xyz.", suffix=".tmp")
try:
    with os.fdopen(fd, "w") as f:
        json.dump(records, f, indent='\t')
        f.write('\n')
    os.replace(tmp, xyz_path)   # atomic on the same filesystem
except Exception:
    try:
        os.unlink(tmp)
    except OSError:
        pass
    raise
PYEOF

release_lock
trap - EXIT INT TERM HUP
