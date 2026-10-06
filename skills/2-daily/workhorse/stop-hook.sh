#!/usr/bin/env bash
# stop-hook.sh — Claude Code Stop hook for /workhorse (GH-911). Wired from SKILL.md frontmatter.
#
# Blocks the stop while this session's run checklist (<repo-root>/.workhorse/<session_id>.md) still has an
# open `- [ ]` line, so a direct /workhorse run keeps going until its queue is resolved. Everything else
# (no checklist, other session, bad input, missing python3/git) fails OPEN: exit 0, no output, stop allowed.
# The runtime documents an eight-consecutive-continuation cap, reset by tool calls; optional/deferred markers are not permission to abandon required scope. Do not change runtime controls.

command -v python3 >/dev/null 2>&1 || exit 0

# The heredoc below is python's stdin, so hand the hook's JSON input over in the environment.
WORKHORSE_HOOK_INPUT="$(cat)" python3 - <<'PY' || exit 0
import json, os, re, subprocess, sys

try:
    data = json.loads(os.environ.get("WORKHORSE_HOOK_INPUT", ""))
    sid = data.get("session_id")
    cwd = data.get("cwd")
except Exception:
    sys.exit(0)
if not isinstance(sid, str) or not re.fullmatch(r"[A-Za-z0-9_-]+", sid):
    sys.exit(0)

roots = []
if isinstance(cwd, str) and cwd:
    try:
        top = subprocess.run(["git", "-C", cwd, "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True, timeout=5).stdout.strip()
        if top:
            roots.append(top)
    except Exception:
        pass
if os.environ.get("CLAUDE_PROJECT_DIR"):
    roots.append(os.environ["CLAUDE_PROJECT_DIR"])

for root in roots:
    path = os.path.join(root, ".workhorse", sid + ".md")
    try:
        with open(path, encoding="utf-8") as fh:
            open_items = [l.strip() for l in fh if l.lstrip().startswith("- [ ]")]
    except Exception:
        continue
    if open_items:
        shown = "\n".join(open_items[:5]) + ("\n…" if len(open_items) > 5 else "")
        print(json.dumps({"decision": "block", "reason":
            "/workhorse run checklist %s still has %d open item(s):\n%s\n"
            "Continue with the next open item. Stop only for verified completion, explicit user pause/cancellation, "
            "or a concrete external blocker recorded as [!] with the exact blocker. "
            "[-] is for genuinely optional or explicitly user-deferred work only and does not reduce required scope." % (path, len(open_items), shown)}))
    sys.exit(0)
PY
exit 0
