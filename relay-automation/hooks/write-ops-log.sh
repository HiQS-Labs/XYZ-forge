#!/usr/bin/env bash
#
# write-ops-log.sh - PreToolUse hook for logging destructive disk writes.
# Implements GH-275 Checkbox 1

[ "${XYZ_WRITE_OPS_LOG:-}" = "0" ] && exit 0

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0

printf '%s' "$payload" | python3 -c '
import sys, json, os, re, time, hashlib

# Defensively cap read to avoid memory bloat from massive heredocs
MAX_READ = 2 * 1024 * 1024
raw = sys.stdin.read(MAX_READ + 1)
if len(raw) > MAX_READ:
    sys.exit(0)

try:
    ev = json.loads(raw)
except Exception:
    sys.exit(0)

if not isinstance(ev, dict) or ev.get("tool_name") != "Bash":
    sys.exit(0)

ti = ev.get("tool_input"); cmd = ti.get("command", "") if isinstance(ti, dict) else ""
if not cmd or not isinstance(cmd, str):
    sys.exit(0)

SHAPES = [
    ("rm force", re.compile(r"(?:\b|/)rm\b\s+(?:.*?\s+)?(?:-[a-zA-Z]*f[a-zA-Z]*\b|--force\b)")),
    ("git worktree remove", re.compile(r"\bgit\b(?:[^-]*|.*-C\s+[^\s]+.*)\bworktree\b.*\bremove\b")),
    ("git worktree prune", re.compile(r"\bgit\b(?:[^-]*|.*-C\s+[^\s]+.*)\bworktree\b.*\bprune\b")),
    ("git branch delete", re.compile(r"\bgit\b.*\bbranch\b.*\s-(?:d|D|df|-delete)\b")),
    ("git reset --hard", re.compile(r"\bgit\b.*\breset\b.*--hard\b")),
    ("git checkout", re.compile(r"\bgit\b.*\bcheckout\b")),
    ("git restore", re.compile(r"\bgit\b.*\brestore\b")),
    ("git switch force", re.compile(r"\bgit\b.*\bswitch\b.*(-f\b|--force|--discard-changes)")),
    ("git stash", re.compile(r"\bgit\b\s+stash\b(?!\s+(list|show|apply|pop|branch))")),
    ("git clean", re.compile(r"\bgit\b.*\bclean\b.*(-[a-zA-Z]*f|--force)")),
    ("git update-ref delete", re.compile(r"\bgit\b.*\bupdate-ref\b.*\s-d\b")),
    ("xyz-sync delete", re.compile(r"\bxyz-sync\.sh\b.*\bdelete\b")),
]

shape = None
for seg in re.split(r"&&|\|\||;|\|", cmd):
    seg = seg.strip()
    if not seg:
        continue
    for name, rx in SHAPES:
        if rx.search(seg):
            shape = name
            break
    if shape:
        break

if not shape:
    sys.exit(0)

CMD_MAX = 4096
if len(cmd) > CMD_MAX:
    h = hashlib.sha256(cmd.encode("utf-8", "replace")).hexdigest()[:8]
    cmd = cmd[:CMD_MAX] + f"...[TRUNCATED:{h}]"

stamp = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
host = os.uname().nodename
session = os.environ.get("TERM_SESSION_ID", "")
cwd = ev.get("cwd") or os.getcwd()

record = {
    "timestamp": stamp,
    "host": host,
    "session": session,
    "cwd": cwd,
    "pattern": shape,
    "command": cmd,
    "stage": "pre"
}

log_path = os.environ.get("XYZ_WRITE_OPS_LOG", os.path.expanduser("~/.local/state/xyz/write-ops.jsonl"))

try:
    os.makedirs(os.path.dirname(log_path), exist_ok=True)
    # Atomic 0600 append
    fd = os.open(log_path, os.O_CREAT | os.O_WRONLY | os.O_APPEND, 0o600)
    with os.fdopen(fd, "a") as f:
        f.write(json.dumps(record) + "\n")
except Exception:
    pass

sys.exit(0)
'
