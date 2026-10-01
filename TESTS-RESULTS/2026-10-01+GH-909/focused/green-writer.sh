#!/usr/bin/env bash
set -euo pipefail
#
# append-xyz-completion.sh — GH-75: append ONE final-completion telemetry record to XYZ.json at the
# harness repo root, newest-first (mirrors CHANGELOG.md's convention).
#
# Called from the three harnesses at their proven terminal points (relay-drive.sh, marathon-drive.sh,
# marathon.sh). Each call is a locked, atomic read-modify-write-prepend so two sessions finishing in
# the same second neither corrupt XYZ.json nor lose a record:
#   - stable-inode advisory flock (GH-909) serializes the read-modify-write → no lost update.
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

# GH-909: a stable sidecar is never unlinked. Quiesce and retire all old mkdir-lock
# writers before upgrading/rolling back; mixed protocols do not share a safe lock domain.
# Preserve the 30s per-holder default and separate absolute queue cap.
lock_wait_s="${XYZ_LOCK_WAIT_S:-30}"
lock_total_max_s="${XYZ_LOCK_TOTAL_MAX_S:-$(( lock_wait_s * 4 ))}"

# The same Python process owns the lock throughout the atomic JSON transaction.
python3 - "$XYZ_JSON" "$harness" "$session_id" "$health" "$title" "$description" "$updated_at" "$lock_wait_s" "$lock_total_max_s" <<'PYEOF'
import sys, json, os, tempfile, fcntl, time, uuid, pathlib

xyz_path, harness, session_id, health, title, description, updated_at = sys.argv[1:8]
wait_s, total_s = map(float, sys.argv[8:10])
lock_path = xyz_path + ".lock"
try:
    # A legacy directory is refused, never reclaimed. Rollout requires quiescence.
    lock_fd = os.open(lock_path, os.O_RDWR | os.O_CREAT, 0o600)
except OSError as exc:
    sys.exit(f"append-xyz-completion: cannot open lock {lock_path}: {exc}")
started = time.monotonic()
deadline = started + wait_s
last_holder = b""
while True:
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        break
    except BlockingIOError:
        if os.environ.get("ROLE") == "W" and not (pathlib.Path(os.environ["BARRIER"])/"W-seen").exists():
            q=pathlib.Path(os.environ["BARRIER"]); (q/"W-seen").touch()
            while not (q/"W-go").exists(): time.sleep(.01)
        now = time.monotonic()
        holder = os.pread(lock_fd, 32, 0)
        if holder and holder != last_holder:
            last_holder = holder
            deadline = now + wait_s
        if now >= deadline or now - started >= total_s:
            print(f"append-xyz-completion: lock never acquired after {now-started:.1f}s "
                  f"(XYZ_LOCK_WAIT_S={wait_s:g} per holder, total cap {total_s:g}s): {lock_path}",
                  file=sys.stderr)
            sys.exit(75)
        time.sleep(0.1)
# Token changes denote queue progress. The descriptor remains locked until process
# exit (including crashes); do not delete the inode or close it before os.replace.
os.pwrite(lock_fd, uuid.uuid4().hex.encode(), 0)
os.ftruncate(lock_fd, 32)
import pathlib
if os.environ.get("ROLE") == "A":
    q=pathlib.Path(os.environ["BARRIER"]); (q/"A-held").touch()
    while not (q/"A-go").exists(): time.sleep(.01)

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

if os.environ.get("ROLE") == "B":
    q=pathlib.Path(os.environ["BARRIER"]); (q/"B-read").touch()
    while not (q/"B-go").exists(): time.sleep(.01)
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
